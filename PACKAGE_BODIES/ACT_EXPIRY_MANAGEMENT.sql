--------------------------------------------------------
--  DDL for Package Body ACT_EXPIRY_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_EXPIRY_MANAGEMENT" 
is
  function IsExpiryOpenedAt(aACT_EXPIRY_ID number, aDate date)
    return number
  is
    TotalPaymentLC     number(20, 3)  default 0;
    TotalPaymentFC     number(20, 3)  default 0;
    TotalExpiryLC      number(20, 3)  default 0;
    TotalExpiryFC      number(20, 3)  default 0;
    DatePayment        date;
    ExpCurrency_id     ACT_PART_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    ExpBaseCurrency_id ACT_PART_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    ACT_FUNCTIONS.TotalPaymentAt(aACT_EXPIRY_ID, aDate, TotalPaymentLC, TotalPaymentFC);

    select max(exp.EXP_AMOUNT_LC)
         , max(exp.EXP_AMOUNT_FC)
         , max(PART.ACS_FINANCIAL_CURRENCY_ID)
         , max(PART.ACS_ACS_FINANCIAL_CURRENCY_ID)
      into TotalExpiryLC
         , TotalExpiryFC
         , ExpCurrency_id
         , ExpBaseCurrency_id
      from ACT_EXPIRY exp
         , ACT_PART_IMPUTATION PART
     where exp.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and PART.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID;

    if     (TotalPaymentLC = TotalExpiryLC)
       and (    (ExpCurrency_id = ExpBaseCurrency_id)
            or (TotalPaymentFC = TotalExpiryFC) ) then
      return 0;
    else
      return 1;
    end if;

  end IsExpiryOpenedAt;
--
  function IsExpiryOpened(aACT_EXPIRY_ID number)
    return number
  is
    TotalPaymentLC     number(20, 3)  default 0;
    TotalPaymentFC     number(20, 3)  default 0;
    TotalExpiryLC      number(20, 3)  default 0;
    TotalExpiryFC      number(20, 3)  default 0;
    DatePayment        date;
    ExpCurrency_id     ACT_PART_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    ExpBaseCurrency_id ACT_PART_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type;

  begin
    TOTAL_PAYMENT_FC(aACT_EXPIRY_ID, TotalPaymentLC, TotalPaymentFC);

    select max(exp.EXP_AMOUNT_LC)
         , max(exp.EXP_AMOUNT_FC)
         , max(PART.ACS_FINANCIAL_CURRENCY_ID)
         , max(PART.ACS_ACS_FINANCIAL_CURRENCY_ID)
      into TotalExpiryLC
         , TotalExpiryFC
         , ExpCurrency_id
         , ExpBaseCurrency_id
      from ACT_EXPIRY exp
         , ACT_PART_IMPUTATION PART
     where exp.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and PART.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID;

    if     (TotalPaymentLC = TotalExpiryLC)
       and (    (ExpCurrency_id = ExpBaseCurrency_id)
            or (TotalPaymentFC = TotalExpiryFC) ) then
      return 0;
    else
      return 1;
    end if;

  end IsExpiryOpened;
--
  procedure UPDATE_DOC_EXPIRY(Document_Id number)
  is
    cursor DET_PAYMENT(Document_Id number)
    is
      select   ACT_EXPIRY_ID
          from ACT_DET_PAYMENT
         where ACT_DOCUMENT_ID = Document_Id
      group by ACT_EXPIRY_ID;
  begin
    if IS_PAYMENT(Document_Id) = 1 then
      for tplDET_PAYMENT in DET_PAYMENT(Document_Id) loop
        UPDATE_EXPIRY(tplDET_PAYMENT.ACT_EXPIRY_ID);
      end loop;
    end if;
  end UPDATE_DOC_EXPIRY;

--
  function IS_PAYMENT(Document_Id number)
    return number
  is
    TypeTransaction ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
  begin
    select min(C_TYPE_CATALOGUE)
      into TypeTransaction
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_DOCUMENT DOC
     where CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
       and ACT_DOCUMENT_ID = Document_Id;

    if    TypeTransaction = '3'
       or TypeTransaction = '4'
       or TypeTransaction = '9' then
      return 1;
    else
      return 0;
    end if;
  end IS_PAYMENT;

--
  procedure TOTAL_PAYMENT_FC(Expiry_Id number, AmountLC out number, AmountFC out number)
  is
  begin
    select sum(nvl(DET_PAIED_LC, 0) + nvl(DET_DISCOUNT_LC, 0) + nvl(DET_DEDUCTION_LC, 0) + nvl(DET_DIFF_EXCHANGE, 0) )
         , sum(nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0) )
      into AmountLC
         , AmountFC
      from ACT_DET_PAYMENT
     where ACT_EXPIRY_ID = Expiry_Id;

    if AmountLC is null then
      AmountLC  := 0;
    end if;

    if AmountFC is null then
      AmountFC  := 0;
    end if;
  end TOTAL_PAYMENT_FC;

--
  function TOTAL_PAYMENT(Expiry_Id number)
    return number
  is
    TotalPayment ACT_DET_PAYMENT.DET_PAIED_LC%type;
  begin
    select sum(nvl(DET_PAIED_LC, 0) + nvl(DET_DISCOUNT_LC, 0) + nvl(DET_DEDUCTION_LC, 0) + nvl(DET_DIFF_EXCHANGE, 0) )
      into TotalPayment
      from ACT_DET_PAYMENT
     where ACT_EXPIRY_ID = Expiry_Id;

    if TotalPayment is null then
      TotalPayment  := 0;
    end if;

    return TotalPayment;
  end TOTAL_PAYMENT;

--
  procedure UPDATE_EXPIRY(Expiry_Id number)
  is
    TotalPaymentLC     number(20, 3)  default 0;
    TotalPaymentFC     number(20, 3)  default 0;
    TotalExpiryLC      number(20, 3)  default 0;
    TotalExpiryFC      number(20, 3)  default 0;
    DatePayment        date;
    ExpCurrency_id     ACT_PART_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    ExpBaseCurrency_id ACT_PART_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    TOTAL_PAYMENT_FC(Expiry_Id, TotalPaymentLC, TotalPaymentFC);

    select max(exp.EXP_AMOUNT_LC)
         , max(exp.EXP_AMOUNT_FC)
         , max(PART.ACS_FINANCIAL_CURRENCY_ID)
         , max(PART.ACS_ACS_FINANCIAL_CURRENCY_ID)
      into TotalExpiryLC
         , TotalExpiryFC
         , ExpCurrency_id
         , ExpBaseCurrency_id
      from ACT_EXPIRY exp
         , ACT_PART_IMPUTATION PART
     where exp.ACT_EXPIRY_ID = Expiry_Id
       and PART.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID;

    if     (TotalPaymentLC = TotalExpiryLC)
       and (    (ExpCurrency_id = ExpBaseCurrency_id)
            or (TotalPaymentFC = TotalExpiryFC) ) then
      select max(IMF_TRANSACTION_DATE)
        into DatePayment
        from ACT_DET_PAYMENT PAY
           , ACT_FINANCIAL_IMPUTATION FIN
       where PAY.ACT_DET_PAYMENT_ID = FIN.ACT_DET_PAYMENT_ID
         and PAY.ACT_EXPIRY_ID = Expiry_Id;

      update ACT_EXPIRY
         set C_STATUS_EXPIRY = '1'
           , EXP_DATE_PMT_TOT = DatePayment
       where ACT_EXPIRY_ID = Expiry_Id;
    else
      update ACT_EXPIRY
         set C_STATUS_EXPIRY = '0'
           , EXP_DATE_PMT_TOT = null
       where ACT_EXPIRY_ID = Expiry_Id;
    end if;
  end UPDATE_EXPIRY;

  procedure UPDATE_JOB_EXPIRY(Job_Id number)
  is
    cursor ActDocument(JobId number)
    is
      select ACT_DOCUMENT.ACT_DOCUMENT_ID
        from ACT_DOCUMENT
       where ACT_JOB_ID = JobId;
  begin
    for tplActDocument in ActDocument(Job_Id) loop
      UPDATE_DOC_EXPIRY(tplActDocument.ACT_DOCUMENT_ID);
    end loop;
  end UPDATE_JOB_EXPIRY;

  /**
  * Description
  *    Calcul des dates d'échéances d'une facture en fonction des paramètres
  *    de la condition de paiement
  */
  procedure CalcDatesOfExpiry(
    aReferenceDate  in     date
  , aDay            in     number
  , aMonth          in     number
  , aCalcMethod     in     varchar2
  , aTimeUnit       in     varchar2
  , aDateCalculated out    date
  , aDateAdapted    out    date
  )
  is
    expiryDate date;
  begin
    expiryDate       := aReferenceDate;

    if aCalcMethod = 'EMNDAY' then   -- Fin de mois, reporté au .. Suivant
      expiryDate  := last_day(expiryDate);
    end if;

    -- unité de temps en mois
    if aTimeUnit = '1' then
      expiryDate  := add_months(expiryDate, aDay);
    else
      -- unité de temps en jours
      expiryDate  := expiryDate + aDay;
    end if;

    if aCalcMethod = 'MONTH' then   -- fin de mois
      expiryDate  := last_day(expiryDate);
    elsif    (aCalcMethod = 'DAY')
          or   -- fin de mois le XX
             (aCalcMethod = 'NDAY')
          or   -- échéance au prochain XX
             (aCalcMethod = 'EMNDAY') then   -- Fin de mois, reporté au .. Suivant
      -- passage au mois suivant pour méthode 'NDAY'
      if     (    (aCalcMethod = 'NDAY')
              or (aCalcMethod = 'EMNDAY') )
         and (aMonth <= to_number(to_char(expiryDate, 'DD') ) ) then
        expiryDate  := add_months(expiryDate, 1);
      end if;

      -- correction si on arrive en fin mois
      if aMonth > to_number(to_char(last_day(expiryDate), 'DD') ) then
        expiryDate  := last_day(expiryDate);
      else
        expiryDate  := last_day(add_months(expiryDate, -1) ) + aMonth;
      end if;
    end if;

    aDateCalculated  := expiryDate;
    aDateAdapted     := expiryDate;
  end CalcDatesOfExpiry;

  function GetFinAccPaymentId(
    aACJ_CATALOGUE_DOCUMENT_ID in ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aPAC_CUSTOM_PARTNER_ID     in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type default null
  )
    return ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  is
    result ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type   := null;
  begin
    --Recherche de la réf. fin. sur le partenaire (Client)
    if aPAC_CUSTOM_PARTNER_ID is not null then
      select max(ACS_FIN_ACC_S_PAYMENT_ID)
        into result
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID;
    end if;

    --Recherche de la réf. fin. sur le catalogue
    if result is null then
      select max(ACS_FIN_ACC_S_PAYMENT_ID)
        into result
        from ACJ_CATALOGUE_DOCUMENT
       where ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID;
    end if;

    return result;
  end GetFinAccPaymentId;

  procedure GetInfoExpiries(
    aInfoExpiries             in out TInfoExpiriesRecType
  , aPAC_PAYMENT_CONDITION_ID in     PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type
  )
  is
    cursor ConditionDetailCursor(aPAC_PAYMENT_CONDITION_ID PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type)
    is
      select   CDE_ACCOUNT
             , C_CALC_METHOD
             , CDE_DAY
             , nvl(CDE_DISCOUNT_RATE, 0) CDE_DISCOUNT_RATE
             , CDE_END_MONTH
             , CDE_PART
             , C_TIME_UNIT
          from PAC_CONDITION_DETAIL
         where PAC_PAYMENT_CONDITION_ID = aPAC_PAYMENT_CONDITION_ID
      order by CDE_PART
             , decode(C_TIME_UNIT, 1, CDE_DAY * 30, CDE_DAY)
             , nvl(CDE_DISCOUNT_RATE, 0) desc;

    Pos integer := 1;
  begin
    if     (aPAC_PAYMENT_CONDITION_ID is not null)
       and (aPAC_PAYMENT_CONDITION_ID != 0) then
      for ConditionDetail_tuple in ConditionDetailCursor(aPAC_PAYMENT_CONDITION_ID) loop
        aInfoExpiries.Expiries(Pos)  := ConditionDetail_tuple;

        if aInfoExpiries.Expiries(Pos).DiscountRate = 0 then
          aInfoExpiries.Proportion  := aInfoExpiries.Proportion + aInfoExpiries.Expiries(Pos).account;
        end if;

        Pos                          := Pos + 1;
      end loop;
    else
      aInfoExpiries.Expiries(Pos).DeltaUnits    := 0;
      aInfoExpiries.Expiries(Pos).PartNum       := 1;
      aInfoExpiries.Expiries(Pos).account       := 1;
      aInfoExpiries.Expiries(Pos).DiscountRate  := 0;
      aInfoExpiries.Expiries(Pos).CalcMethod    := 'NORM';
      aInfoExpiries.Expiries(Pos).MonthDay      := 1;
      aInfoExpiries.Expiries(Pos).TimeUnit      := '0';
      aInfoExpiries.Proportion                  := aInfoExpiries.Proportion + aInfoExpiries.Expiries(Pos).account;
    end if;

    --Nbre de tranche
    aInfoExpiries.Part  := aInfoExpiries.Expiries(aInfoExpiries.Expiries.last).PartNum;
  end GetInfoExpiries;

  procedure CalculateExpiries(
    aInfoExpiries              in     TInfoExpiriesRecType
  , atblCalculateExpiries      in out TtblCalculateExpiriesType
  , aTotAmount_LC              in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aTotAmount_FC              in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aTotAmount_EUR             in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aReferenceDate             in     ACT_EXPIRY.EXP_CALCULATED%type
  , aACS_FINANCIAL_CURRENCY_ID in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aRoundType                 in     number default 1
  )   -- 1 Arrondi finance, 2 arrondi logistique)
  is
    TotPayed_LC       number                                                  := 0;
    TotPayed_FC       number                                                  := 0;
    TotPayed_EUR      number                                                  := 0;
    Pos               integer;
    PosCalc           integer                                                 := 1;
    BaseFinCurrId     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    DateInterestValue ACT_EXPIRY.EXP_INTEREST_VALUE%type;
  begin
    if aInfoExpiries.Expiries.count > 0 then
      BaseFinCurrId  := ACS_FUNCTION.GetLocalCurrencyID;
    end if;

    for Pos in 1 .. aInfoExpiries.Expiries.count loop
      atblCalculateExpiries(PosCalc).FinCurrId  := aACS_FINANCIAL_CURRENCY_ID;

      --Si pas d'escompte -> Calcul au net
      if aInfoExpiries.Expiries(Pos).DiscountRate = 0 then
        atblCalculateExpiries(PosCalc).CalcNet  := 1;
      else
        atblCalculateExpiries(PosCalc).CalcNet  := 0;
      end if;

      if aInfoExpiries.Part = aInfoExpiries.Expiries(Pos).PartNum then
        --{calcul du montant de l'escompte}
        atblCalculateExpiries(PosCalc).Discount_LC   :=
          ACS_FUNCTION.RoundAmount( ( (aTotAmount_LC - TotPayed_LC) * aInfoExpiries.Expiries(Pos).DiscountRate) / 100
                                 , BaseFinCurrId
                                 , aRoundType
                                  );
        atblCalculateExpiries(PosCalc).Discount_FC   :=
          ACS_FUNCTION.RoundAmount( ( (aTotAmount_FC - TotPayed_FC) * aInfoExpiries.Expiries(Pos).DiscountRate) / 100
                                 , aACS_FINANCIAL_CURRENCY_ID
                                 , aRoundType
                                  );
        atblCalculateExpiries(PosCalc).Discount_EUR  :=
          ACS_FUNCTION.RoundNear( ( (aTotAmount_EUR - TotPayed_EUR) * aInfoExpiries.Expiries(Pos).DiscountRate) / 100
                               , 0.001);
        --{calcul du mont échu}
        atblCalculateExpiries(PosCalc).Amount_LC     :=
                                               (aTotAmount_LC - TotPayed_LC)
                                               - atblCalculateExpiries(PosCalc).Discount_LC;
        atblCalculateExpiries(PosCalc).Amount_FC     :=
                                               (aTotAmount_FC - TotPayed_FC)
                                               - atblCalculateExpiries(PosCalc).Discount_FC;
        atblCalculateExpiries(PosCalc).Amount_EUR    :=
                                            (aTotAmount_EUR - TotPayed_EUR)
                                            - atblCalculateExpiries(PosCalc).Discount_EUR;
      else
        --{calcul du mont échu}
        atblCalculateExpiries(PosCalc).Amount_LC     :=
          ACS_FUNCTION.RoundAmount( (aTotAmount_LC * aInfoExpiries.Expiries(Pos).account / aInfoExpiries.Proportion)
                                 , BaseFinCurrId
                                 , aRoundType
                                  );
        atblCalculateExpiries(PosCalc).Amount_FC     :=
          ACS_FUNCTION.RoundAmount( (aTotAmount_FC * aInfoExpiries.Expiries(Pos).account / aInfoExpiries.Proportion)
                                 , aACS_FINANCIAL_CURRENCY_ID
                                 , aRoundType
                                  );
        atblCalculateExpiries(PosCalc).Amount_EUR    :=
          ACS_FUNCTION.RoundNear( (aTotAmount_EUR * aInfoExpiries.Expiries(Pos).account / aInfoExpiries.Proportion)
                               , 0.001
                                );
        --{calcul du montant de l'escompte}
        atblCalculateExpiries(PosCalc).Discount_LC   :=
          ACS_FUNCTION.RoundAmount( (atblCalculateExpiries(PosCalc).Amount_LC * aInfoExpiries.Expiries(Pos).DiscountRate
                                    ) /
                                   100
                                 , BaseFinCurrId
                                 , aRoundType
                                  );
        atblCalculateExpiries(PosCalc).Discount_FC   :=
          ACS_FUNCTION.RoundAmount( (atblCalculateExpiries(PosCalc).Amount_FC * aInfoExpiries.Expiries(Pos).DiscountRate
                                    ) /
                                   100
                                 , aACS_FINANCIAL_CURRENCY_ID
                                 , aRoundType
                                  );
        atblCalculateExpiries(PosCalc).Discount_EUR  :=
          ACS_FUNCTION.RoundNear( (atblCalculateExpiries(PosCalc).Amount_EUR * aInfoExpiries.Expiries(Pos).DiscountRate
                                  ) /
                                 100
                               , 0.001
                                );
        --{Màj du mont échu}
        atblCalculateExpiries(PosCalc).Amount_LC     :=
                                   atblCalculateExpiries(PosCalc).Amount_LC - atblCalculateExpiries(PosCalc).Discount_LC;
        atblCalculateExpiries(PosCalc).Amount_FC     :=
                                   atblCalculateExpiries(PosCalc).Amount_FC - atblCalculateExpiries(PosCalc).Discount_FC;
        atblCalculateExpiries(PosCalc).Amount_EUR    :=
                                 atblCalculateExpiries(PosCalc).Amount_EUR - atblCalculateExpiries(PosCalc).Discount_EUR;

        --Màj des totaux pour dernière tranche
        if atblCalculateExpiries(PosCalc).CalcNet = 1 then
          TotPayed_LC   := TotPayed_LC + atblCalculateExpiries(PosCalc).Amount_LC;
          TotPayed_FC   := TotPayed_FC + atblCalculateExpiries(PosCalc).Amount_FC;
          TotPayed_EUR  := TotPayed_EUR + atblCalculateExpiries(PosCalc).Amount_EUR;
        end if;
      end if;

      --Si Discount = 0 pour une tranche autre que net -> on supprime cette tranche
      if    atblCalculateExpiries(PosCalc).CalcNet = 1
         or atblCalculateExpiries(PosCalc).Discount_LC != 0 then
        atblCalculateExpiries(PosCalc).Percent  := aInfoExpiries.Expiries(Pos).account;
        atblCalculateExpiries(PosCalc).Slice    := aInfoExpiries.Expiries(Pos).PartNum;
        --Calcul des dates de l'échéance
        CalcDatesOfExpiry(aReferenceDate
                        , aInfoExpiries.Expiries(Pos).DeltaUnits
                        , aInfoExpiries.Expiries(Pos).MonthDay
                        , aInfoExpiries.Expiries(Pos).CalcMethod
                        , aInfoExpiries.Expiries(Pos).TimeUnit
                        , atblCalculateExpiries(PosCalc).DateCalculated
                        , atblCalculateExpiries(PosCalc).DateAdapted
                         );

        -- Màj de la date valeur interet
        if atblCalculateExpiries(PosCalc).CalcNet = 1 then
          if atblCalculateExpiries(PosCalc).Slice = 1 then
            --Sauvegarde de la première date calculé de la 1ere échéance nette pour mettre dans la date valeur interet
            DateInterestValue  := atblCalculateExpiries(PosCalc).DateCalculated;
          end if;

          atblCalculateExpiries(PosCalc).DateInterestValue  := DateInterestValue;
        end if;

        --Si calcul au net et montant = 0 -> passage de l'échéance directement à l'état 'payée'
        if     (atblCalculateExpiries(PosCalc).CalcNet = 1)
           and (atblCalculateExpiries(PosCalc).Amount_LC = 0)
           and (atblCalculateExpiries(PosCalc).Amount_FC = 0) then
          atblCalculateExpiries(PosCalc).Status  := '1';
        else
          atblCalculateExpiries(PosCalc).Status  := '0';
        end if;

        --Tranche suivante
        PosCalc                                 := PosCalc + 1;
      else
        --Suppression de la tranche
        atblCalculateExpiries.delete(PosCalc);
      end if;
    end loop;
  end CalculateExpiries;

  procedure UpdateBVRCalculateExpiries(
    atblCalculateExpiries     in out TtblCalculateExpiriesType
  , aACS_FIN_ACC_S_PAYMENT_ID in     ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , aPAC_CUSTOM_PARTNER_ID    in     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aDocumentRefId            in     ACS_USED_REFERENCE.URE_DOCUMENT%type
  , aUpdateBVR                in     boolean default false
  , aBVRRef                   in     ACT_EXPIRY.EXP_REF_BVR%type default null
  , aBVRCode                  in     ACT_EXPIRY.EXP_BVR_CODE%type default null
  , aUpdateMissingOnly        in     boolean default false
  , aRemoveDuplicateBVRRef    in     boolean default false
  )
  is
    Pos           integer;
    GetBVR        boolean                                  := false;
    BVRWithAmount boolean                                  := false;
    LastSlice     ACT_EXPIRY.EXP_SLICE%type                := 0;
    TypeSupport   ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type;

    -----------------------
    --Recherche de la méthode de génération sur le partenaire
    function GetBVRGenerationMethod(aPAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
      return PAC_CUSTOM_PARTNER.C_BVR_GENERATION_METHOD%type
    is
      result PAC_CUSTOM_PARTNER.C_BVR_GENERATION_METHOD%type;
    begin
      begin
        select C_BVR_GENERATION_METHOD
          into result
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID;
      exception
        when no_data_found then
          result  := null;
      end;

      return result;
    end;
    -----------------------
    procedure RemoveDuplicateBVRRef
    is
      Pos                   integer;
      Pos2                  integer;
      BVRRef                ACT_EXPIRY.EXP_REF_BVR%type;
    begin
      for Pos in 1 .. atblCalculateExpiries.count - 1 loop
        Pos2  := Pos + 1;
        BVRRef := atblCalculateExpiries(Pos).BVRRef;

        loop
          exit when (Pos2 > atblCalculateExpiries.count);

          if (atblCalculateExpiries(Pos).Slice != atblCalculateExpiries(Pos2).Slice) and
              (BVRRef = atblCalculateExpiries(Pos2).BVRRef) then
            if atblCalculateExpiries(Pos).id > atblCalculateExpiries(Pos2).id then
              atblCalculateExpiries(Pos).BVRRef := null;
            else
              atblCalculateExpiries(Pos2).BVRRef := null;
            end if;
          end if;

          Pos2  := Pos2 + 1;
        end loop;
      end loop;
    end;
    -----------------------
  begin
    --Si c'est un client (REC)
    if aPAC_CUSTOM_PARTNER_ID is not null then
      begin
        --Recherche du type de support
        select ACS_PAYMENT_METHOD.C_TYPE_SUPPORT
          into TypeSupport
          from ACS_FIN_ACC_S_PAYMENT
             , ACS_PAYMENT_METHOD
         where ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID = aACS_FIN_ACC_S_PAYMENT_ID
           and ACS_FIN_ACC_S_PAYMENT.ACS_PAYMENT_METHOD_ID = ACS_PAYMENT_METHOD.ACS_PAYMENT_METHOD_ID;
      exception
        when no_data_found then
          TypeSupport  := null;
      end;

      if TypeSupport in('33', '34', '35', '50', '51', '56') then
        GetBVR         := true;
        BVRWithAmount  := GetBVRGenerationMethod(aPAC_CUSTOM_PARTNER_ID) in('', '03');
      end if;
    end if;

    for Pos in 1 .. atblCalculateExpiries.count loop

      --En cas de suppression de la réf., il faut mettre null
      atblCalculateExpiries(Pos).FinAccPaymentId  := aACS_FIN_ACC_S_PAYMENT_ID;

      -- Mise à jour N° référence BVR et Ligne de codage BVR selon méthode définie dans la transaction courante
      -- Uniquement si une méthode de paiement est définie sur la transaction courante !
      if GetBVR then   --Si génération BVR (REC)
        -- Suppression des réf. BVR dupliqué d'une échéance à l'autre
        if aRemoveDuplicateBVRRef then
          RemoveDuplicateBVRRef;
        end if;

        --Calcule de la réf. BVR (une par tranche)
        if atblCalculateExpiries(Pos).Slice is not null then
          if atblCalculateExpiries(Pos).Slice != LastSlice then
            -- Nouvelle échéance -> nouvelle réf. BVR
            LastSlice  := atblCalculateExpiries(Pos).Slice;

            if    (not aUpdateMissingOnly)
               or (atblCalculateExpiries(Pos).BVRRef is null) then
              ACS_FUNCTION.Set_BVR_Ref(aACS_FIN_ACC_S_PAYMENT_ID, '2', aDocumentRefId, atblCalculateExpiries(Pos).BVRRef);
            end if;
          else
            -- Même échéance, tranche différente -> même réf. BVR
            if    (not aUpdateMissingOnly)
               or (atblCalculateExpiries(Pos).BVRRef is null) then
              atblCalculateExpiries(Pos).BVRRef  := atblCalculateExpiries(Pos - 1).BVRRef;
            end if;
          end if;

          --Calcule de la ligne de codage
          if BVRWithAmount then
            -- Avec montant
            atblCalculateExpiries(Pos).BVRCode  :=
              ACS_FUNCTION.Get_BVR_Coding_Line(aACS_FIN_ACC_S_PAYMENT_ID
                                             , atblCalculateExpiries(Pos).BVRRef
                                             , atblCalculateExpiries(Pos).Amount_LC
                                             , ACS_FUNCTION.GetLocalCurrencyId
                                             , atblCalculateExpiries(Pos).Amount_FC
                                             , atblCalculateExpiries(Pos).FinCurrId
                                              );
          else
            atblCalculateExpiries(Pos).BVRCode  :=
              ACS_FUNCTION.Get_BVR_Coding_Line(aACS_FIN_ACC_S_PAYMENT_ID
                                             , atblCalculateExpiries(Pos).BVRRef
                                             , 0
                                             , ACS_FUNCTION.GetLocalCurrencyId
                                             , 0
                                             , atblCalculateExpiries(Pos).FinCurrId
                                              );
          end if;
        end if;
      elsif aPAC_CUSTOM_PARTNER_ID is not null then
        atblCalculateExpiries(Pos).BVRRef   := null;
        atblCalculateExpiries(Pos).BVRCode  := null;
      else
        --Si référence type BVR (PAY)
        if aUpdateBVR then
          if not aUpdateMissingOnly then
            atblCalculateExpiries(Pos).BVRRef   := aBVRRef;
            atblCalculateExpiries(Pos).BVRCode  := aBVRCode;
          end if;
        else
          atblCalculateExpiries(Pos).BVRRef   := null;
          atblCalculateExpiries(Pos).BVRCode  := null;
        end if;
      end if;
    end loop;
  end UpdateBVRCalculateExpiries;

  function CheckCalculateExpiries(
    atblCalculateExpiries in TtblCalculateExpiriesType
  , aInfoExpiries         in TInfoExpiriesRecType
  )
    return boolean
  is
    Pos integer;
  begin
    --Comparaison des données des échéances avec ceux de la cond. de paiement
    if atblCalculateExpiries.count = aInfoExpiries.Expiries.count then
      for Pos in 1 .. atblCalculateExpiries.count loop
        --Si difference dans la numérotation des tranches -> False
        if atblCalculateExpiries(Pos).Slice != aInfoExpiries.Expiries(Pos).PartNum then
          return false;
        end if;
      end loop;
    else   --Si difference dans le nombre de tranche -> False
      return false;
    end if;

    --OK
    return true;
  end CheckCalculateExpiries;

  function UpdateCalculateExpiries(
    atblCurrentCalculateExpiries in     TtblCalculateExpiriesType
  , aChangedInfoExpiries         in     TChangedInfoExpiriesRecType
  , atblUpdatedCalculateExpiries in out TtblCalculateExpiriesType
  )
    return boolean
  is
    Pos                  integer;
    Checked              boolean;
    vKeepBVRRef          boolean;
    vTypeSup1            ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type;
    vTypeSup2            ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type;
    vRefComp1            ACS_PAYMENT_METHOD.C_REFERENCE_COMPOSITION%type;
    vRefComp2            ACS_PAYMENT_METHOD.C_REFERENCE_COMPOSITION%type;
    vBankSBVR1           ACS_PAYMENT_METHOD.PME_BANK_SBVR%type;
    vBankSBVR2           ACS_PAYMENT_METHOD.PME_BANK_SBVR%type;
    InfoExpiries         TInfoExpiriesRecType;
    tblCalculateExpiries TtblCalculateExpiriesType;
  begin
    --Recherche des info. sur la condition de paiement
    GetInfoExpiries(InfoExpiries, aChangedInfoExpiries.PAC_PAYMENT_CONDITION_ID);
    --Comparaison des données des échéances avec ceux de la cond. de paiement
    Checked      := not CheckCalculateExpiries(atblCurrentCalculateExpiries, InfoExpiries);

    if aChangedInfoExpiries.PaymentCondition then
      --Si diff. dans les tranches
      if Checked then
        return false;
      end if;

      --Assignation ancienne valeur pour récup. ID
      tblCalculateExpiries          := atblCurrentCalculateExpiries;
      --Calcule des échéances
      CalculateExpiries(InfoExpiries
                      , tblCalculateExpiries
                      , aChangedInfoExpiries.TotAmount_LC
                      , aChangedInfoExpiries.TotAmount_FC
                      , aChangedInfoExpiries.TotAmount_EUR
                      , aChangedInfoExpiries.ReferenceDate
                      , aChangedInfoExpiries.ACS_FINANCIAL_CURRENCY_ID
                      , aChangedInfoExpiries.RoundType
                       );
      atblUpdatedCalculateExpiries  := tblCalculateExpiries;
    else
      atblUpdatedCalculateExpiries  := atblCurrentCalculateExpiries;

      if    aChangedInfoExpiries.Amount
         or aChangedInfoExpiries.date then
        --Si diff. dans les tranches
        if Checked then
          return false;
        end if;

        --Calcule des échéances
        CalculateExpiries(InfoExpiries
                        , tblCalculateExpiries
                        , aChangedInfoExpiries.TotAmount_LC
                        , aChangedInfoExpiries.TotAmount_FC
                        , aChangedInfoExpiries.TotAmount_EUR
                        , aChangedInfoExpiries.ReferenceDate
                        , aChangedInfoExpiries.ACS_FINANCIAL_CURRENCY_ID
                        , aChangedInfoExpiries.RoundType
                         );

        --Si diff. entre le nbre de tranches actuel et celle de la condition de paiement (tranche supprimé si discount = 0)
        if not CheckCalculateExpiries(tblCalculateExpiries, InfoExpiries) then
          return false;
        end if;

        --Màj montant et/ou dates
        for Pos in 1 .. atblUpdatedCalculateExpiries.count loop
          if aChangedInfoExpiries.Amount then
            atblUpdatedCalculateExpiries(Pos).Amount_LC     := tblCalculateExpiries(Pos).Amount_LC;
            atblUpdatedCalculateExpiries(Pos).Amount_FC     := tblCalculateExpiries(Pos).Amount_FC;
            atblUpdatedCalculateExpiries(Pos).Amount_EUR    := tblCalculateExpiries(Pos).Amount_EUR;
            atblUpdatedCalculateExpiries(Pos).Discount_LC   := tblCalculateExpiries(Pos).Discount_LC;
            atblUpdatedCalculateExpiries(Pos).Discount_FC   := tblCalculateExpiries(Pos).Discount_FC;
            atblUpdatedCalculateExpiries(Pos).Discount_EUR  := tblCalculateExpiries(Pos).Discount_EUR;
            atblUpdatedCalculateExpiries(Pos).Status        := tblCalculateExpiries(Pos).Status;
          end if;

          if aChangedInfoExpiries.date then
            atblUpdatedCalculateExpiries(Pos).DateAdapted        := tblCalculateExpiries(Pos).DateAdapted;
            atblUpdatedCalculateExpiries(Pos).DateCalculated     := tblCalculateExpiries(Pos).DateCalculated;
            atblUpdatedCalculateExpiries(Pos).DateInterestValue  := tblCalculateExpiries(Pos).DateInterestValue;
          end if;
        end loop;
      end if;
    end if;

    vKeepBVRRef  := false;

    --Contrôle si recalcule de la réf. BVR lors du changement de méthode de paiement
    if aChangedInfoExpiries.FinAccPayment then
      begin
        --Recherche du type de support et compostion réf BVR de l'ancienne méthode selon 1ère échéance
        select ACS_PAYMENT_METHOD.C_TYPE_SUPPORT
             , ACS_PAYMENT_METHOD.C_REFERENCE_COMPOSITION
             , ACS_PAYMENT_METHOD.PME_BANK_SBVR
          into vTypeSup1
             , vRefComp1
             , vBankSBVR1
          from ACS_FIN_ACC_S_PAYMENT
             , ACS_PAYMENT_METHOD
         where ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID = atblCurrentCalculateExpiries(1).FinAccPaymentId
           and ACS_FIN_ACC_S_PAYMENT.ACS_PAYMENT_METHOD_ID = ACS_PAYMENT_METHOD.ACS_PAYMENT_METHOD_ID;
      exception
        when no_data_found then
          vTypeSup1   := null;
          vRefComp1   := null;
          vBankSBVR1  := null;
      end;

      begin
        --Recherche du type de support et compostion réf BVR de la nouvelle méthode
        select ACS_PAYMENT_METHOD.C_TYPE_SUPPORT
             , ACS_PAYMENT_METHOD.C_REFERENCE_COMPOSITION
             , ACS_PAYMENT_METHOD.PME_BANK_SBVR
          into vTypeSup2
             , vRefComp2
             , vBankSBVR2
          from ACS_FIN_ACC_S_PAYMENT
             , ACS_PAYMENT_METHOD
         where ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID = aChangedInfoExpiries.ACS_FIN_ACC_S_PAYMENT_ID
           and ACS_FIN_ACC_S_PAYMENT.ACS_PAYMENT_METHOD_ID = ACS_PAYMENT_METHOD.ACS_PAYMENT_METHOD_ID;
      exception
        when no_data_found then
          vTypeSup2   := null;
          vRefComp2   := null;
          vBankSBVR2  := null;
      end;

      if nvl(vBankSBVR1, 0) = nvl(vBankSBVR2, 0) then
        if     vTypeSup1 in('35', '50', '51', '56')
           and vTypeSup2 in('35', '50', '51', '56') then
          if nvl(vRefComp1, 0) = nvl(vRefComp2, 0) then
            vKeepBVRRef  := true;
          end if;
        elsif vTypeSup1 = vTypeSup2 then
          vKeepBVRRef  := true;
        end if;
      end if;
    end if;

    if    aChangedInfoExpiries.PaymentCondition
       or aChangedInfoExpiries.BVRReference
       or aChangedInfoExpiries.FinAccPayment then
      --Recalcule des réf. BVR
      UpdateBVRCalculateExpiries(atblUpdatedCalculateExpiries
                               , aChangedInfoExpiries.ACS_FIN_ACC_S_PAYMENT_ID
                               , aChangedInfoExpiries.PAC_CUSTOM_PARTNER_ID
                               , aChangedInfoExpiries.DocumentRefId
                               , aChangedInfoExpiries.BVRUpdate
                               , aChangedInfoExpiries.BVRRef
                               , aChangedInfoExpiries.BVRCode
                               , vKeepBVRRef
                                );
    elsif aChangedInfoExpiries.Amount then
      --Màj uniquement réf. manquante et recalcule de la ligne de codage si avec montant
      UpdateBVRCalculateExpiries(atblUpdatedCalculateExpiries
                               , aChangedInfoExpiries.ACS_FIN_ACC_S_PAYMENT_ID
                               , aChangedInfoExpiries.PAC_CUSTOM_PARTNER_ID
                               , aChangedInfoExpiries.DocumentRefId
                               , aChangedInfoExpiries.BVRUpdate
                               , aChangedInfoExpiries.BVRRef
                               , aChangedInfoExpiries.BVRCode
                               , true
                                );
    end if;

    return true;
  end UpdateCalculateExpiries;

  function UpdateExpCalcNet(atblCalculateExpiries in out TtblCalculateExpiriesType)
    return boolean
  is
    slice  ACT_EXPIRY.EXP_SLICE%type;
    net    boolean                     := false;
    result boolean                     := false;
  begin
    --Si pas d'échéance -> on quitte
    if atblCalculateExpiries.count = 0 then
      return result;
    end if;

    --1ère tranche
    slice  := atblCalculateExpiries(atblCalculateExpiries.last).Slice;

    for Pos in reverse 1 .. atblCalculateExpiries.count loop
      --Changement de tranche
      if slice != atblCalculateExpiries(Pos).Slice then
        net    := false;
        slice  := atblCalculateExpiries(Pos).Slice;
      end if;

      if     not net
         and atblCalculateExpiries(Pos).Discount_LC = 0 then
        if atblCalculateExpiries(Pos).CalcNet != 1 then
          atblCalculateExpiries(Pos).CalcNet  := 1;
          result                              := true;
        end if;

        net  := true;
      elsif atblCalculateExpiries(Pos).CalcNet != 0 then
        atblCalculateExpiries(Pos).CalcNet  := 0;
        result                              := true;
      end if;
    end loop;

    return result;
  end UpdateExpCalcNet;

  function UpdateInterestValue(atblCalculateExpiries in out TtblCalculateExpiriesType)
    return boolean
  is
    slice             ACT_EXPIRY.EXP_SLICE%type;
    net               boolean                              := false;
    result            boolean                              := false;
    DateInterestValue ACT_EXPIRY.EXP_INTEREST_VALUE%type;
  begin
    for Pos in 1 .. atblCalculateExpiries.count loop
      -- Màj de la date valeur interet
      if atblCalculateExpiries(Pos).CalcNet = 1 then
        if atblCalculateExpiries(Pos).Slice = 1 then
          --Sauvegarde de la première date calculé de la 1ere échéance nette pour mettre dans la date valeur interet
          DateInterestValue  := atblCalculateExpiries(Pos).DateCalculated;
        end if;

        if atblCalculateExpiries(Pos).DateInterestValue is null then
          atblCalculateExpiries(Pos).DateInterestValue  := DateInterestValue;
          result                                        := true;
        end if;
      elsif atblCalculateExpiries(Pos).DateInterestValue is not null then
        atblCalculateExpiries(Pos).DateInterestValue  := null;
        result                                        := true;
      end if;
    end loop;

    return result;
  end UpdateInterestValue;

  -- 0 -> Pas de modifications, $01 -> Modifications, $02 -> Modification de ACS_FIN_ACC_S_PAYMENT_ID
  function CorrectExpiries(
    atblCalculateExpiries     in out TtblCalculateExpiriesType
  , aACS_FIN_ACC_S_PAYMENT_ID in     ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , aPAC_CUSTOM_PARTNER_ID    in     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aDocumentRefId            in     ACS_USED_REFERENCE.URE_DOCUMENT%type
  , aBVRRef                   in     ACT_EXPIRY.EXP_REF_BVR%type default null
  , aBVRCode                  in     ACT_EXPIRY.EXP_BVR_CODE%type default null
  )
    return integer
  is
    result integer := 0;
  begin
    --Si pas d'échéance -> on quitte
    if atblCalculateExpiries.count = 0 then
      return result;
    end if;

    --Màj flag 'tranche net'
    if UpdateExpCalcNet(atblCalculateExpiries) then
      result  := 1;
    end if;

    -- Màj date valeur intérêts
    if UpdateInterestValue(atblCalculateExpiries) then
      result  := 1;
    end if;

    result  := 1;
    -- Màj réf. BVR
    UpdateBVRCalculateExpiries(atblCalculateExpiries
                             , aACS_FIN_ACC_S_PAYMENT_ID
                             , aPAC_CUSTOM_PARTNER_ID
                             , aDocumentRefId
                             , false
                             , aBVRRef
                             , aBVRCode
                             , true
                             , true
                              );

    for Pos in 1 .. atblCalculateExpiries.count loop
      --Si calcul au net et montant = 0 -> passage de l'échéance directement à l'état 'payée'
      if     (atblCalculateExpiries(Pos).CalcNet = 1)
         and (atblCalculateExpiries(Pos).Amount_LC = 0)
         and (atblCalculateExpiries(Pos).Amount_FC = 0) then
        if atblCalculateExpiries(Pos).Status != '1' then
          atblCalculateExpiries(Pos).Status  := '1';
          result                             := PCS.PC_BITMAN.bit_or(result, 1);
        end if;
      else
        if atblCalculateExpiries(Pos).Status != '0' then
          atblCalculateExpiries(Pos).Status  := '0';
          result                             := PCS.PC_BITMAN.bit_or(result, 1);
        end if;
      end if;

      -- Montants null à 0
      if atblCalculateExpiries(Pos).Amount_LC is null then
        atblCalculateExpiries(Pos).Amount_LC  := 0;
      end if;

      if atblCalculateExpiries(Pos).Amount_FC is null then
        atblCalculateExpiries(Pos).Amount_FC  := 0;
      end if;

      if atblCalculateExpiries(Pos).Amount_EUR is null then
        atblCalculateExpiries(Pos).Amount_EUR  := 0;
      end if;

      if atblCalculateExpiries(Pos).Discount_LC is null then
        atblCalculateExpiries(Pos).Discount_LC  := 0;
      end if;

      if atblCalculateExpiries(Pos).Discount_FC is null then
        atblCalculateExpiries(Pos).Discount_FC  := 0;
      end if;

      if atblCalculateExpiries(Pos).Discount_FC is null then
        atblCalculateExpiries(Pos).Discount_FC  := 0;
      end if;

      --Màj ACS_FIN_ACC_S_PAYMENT_ID
      if nvl(atblCalculateExpiries(Pos).FinAccPaymentId, 0) != nvl(aACS_FIN_ACC_S_PAYMENT_ID, 0) then
        atblCalculateExpiries(Pos).FinAccPaymentId  := aACS_FIN_ACC_S_PAYMENT_ID;
        result                                      := PCS.PC_BITMAN.bit_or(result, 2);   --3 recalcule BVR
      end if;
    end loop;

    return result;
  end CorrectExpiries;

  procedure ControlExpiries(
    atblCalculateExpiries in     TtblCalculateExpiriesType
  , aTotAmount_LC         in     ACT_EXPIRY.EXP_AMOUNT_LC%type
  , aTotAmount_FC         in     ACT_EXPIRY.EXP_AMOUNT_FC%type
  , aErrorExpiries        in out TErrorExpiriesRecType
  )
  is
    LastSign           integer                          := 0;
    LastSlice          ACT_EXPIRY.EXP_SLICE%type        := 0;
    LastDateAdapted    ACT_EXPIRY.EXP_ADAPTED%type;
    LastDateCalculated ACT_EXPIRY.EXP_CALCULATED%type;
    LastAmount_LC      ACT_EXPIRY.EXP_AMOUNT_LC%type    := 0;
    LastAmount_FC      ACT_EXPIRY.EXP_AMOUNT_FC%type    := 0;
    TotAmount_LC       ACT_EXPIRY.EXP_AMOUNT_LC%type    := 0;
    TotAmount_FC       ACT_EXPIRY.EXP_AMOUNT_FC%type    := 0;
    net                boolean                          := false;
    Pos2               integer;
  begin
    for Pos in 1 .. atblCalculateExpiries.count loop

      if LastSign != 0 then
        if (Sign(atblCalculateExpiries(Pos).Amount_LC) != 0) and
            (Sign(atblCalculateExpiries(Pos).Amount_LC) != LastSign) then
          --Erreur signe
          aErrorExpiries.DiffSign := True;
          aErrorExpiries.id := atblCalculateExpiries(Pos).ID;
        end if;
      else
        LastSign := Sign(atblCalculateExpiries(Pos).Amount_LC);
      end if;

      if    (abs(atblCalculateExpiries(Pos).Amount_LC) - abs(atblCalculateExpiries(Pos).Discount_LC) < 0)
         or (abs(atblCalculateExpiries(Pos).Amount_FC) - abs(atblCalculateExpiries(Pos).Discount_FC) < 0) then
        --Erreur escompte plus grand que montant
        aErrorExpiries.DiscountGreater  := true;
        aErrorExpiries.id               := atblCalculateExpiries(Pos).id;
      end if;

      if Pos > 1 then
        LastAmount_LC       := atblCalculateExpiries(Pos - 1).Amount_LC + atblCalculateExpiries(Pos - 1).Discount_LC;
        LastAmount_FC       := atblCalculateExpiries(Pos - 1).Amount_FC + atblCalculateExpiries(Pos - 1).Discount_FC;
        LastDateAdapted     := atblCalculateExpiries(Pos - 1).DateAdapted;
        LastDateCalculated  := atblCalculateExpiries(Pos - 1).DateCalculated;
        LastSlice           := atblCalculateExpiries(Pos - 1).Slice;

        if     (atblCalculateExpiries(Pos).Slice = LastSlice)
           and (    (atblCalculateExpiries(Pos).Amount_LC + atblCalculateExpiries(Pos).Discount_LC) != LastAmount_LC
                or (atblCalculateExpiries(Pos).Amount_FC + atblCalculateExpiries(Pos).Discount_FC) != LastAmount_FC
               ) then
          --Erreur montant tranche
          aErrorExpiries.SliceNotEqual  := true;
          aErrorExpiries.id             := atblCalculateExpiries(Pos).id;
        end if;

        if    (atblCalculateExpiries(Pos).DateAdapted < LastDateAdapted)
           or (atblCalculateExpiries(Pos).DateCalculated < LastDateCalculated) then
          --Erreur date échéance
          aErrorExpiries.date  := true;
          aErrorExpiries.id    := atblCalculateExpiries(Pos).id;
        end if;

        if    (atblCalculateExpiries(Pos).Slice < LastSlice)
           or (atblCalculateExpiries(Pos).Slice >(LastSlice + 1) ) then
          --Erreur numérotation tranche
          aErrorExpiries.SliceNumber  := true;
          aErrorExpiries.id           := atblCalculateExpiries(Pos).id;
        end if;

        --Si changement de tranche
        if (atblCalculateExpiries(Pos).Slice != LastSlice) then
          if not net then
            --Erreur pas d'échéance nette
            aErrorExpiries.NoCalcNet  := true;
            aErrorExpiries.id         := atblCalculateExpiries(Pos - 1).id;
          else
            net  := false;
          end if;
        end if;

        --Si dernière tranche
        if     not net
           and (    Pos = atblCalculateExpiries.count
                and atblCalculateExpiries(Pos).CalcNet = 0) then
          --Erreur pas d'échéance nette
          aErrorExpiries.NoCalcNet  := true;
          aErrorExpiries.id         := atblCalculateExpiries(Pos).id;
        end if;
      end if;

      if atblCalculateExpiries(Pos).CalcNet = 1 then
        TotAmount_LC  := TotAmount_LC + atblCalculateExpiries(Pos).Amount_LC;
        TotAmount_FC  := TotAmount_FC + atblCalculateExpiries(Pos).Amount_FC;
        net           := true;
      end if;

      --Si on a une erreur -> on quitte
      if aErrorExpiries.id is not null then
        return;
      end if;
    end loop;

    if atblCalculateExpiries.count = 0 then
      --Pas d'échéance
      aErrorExpiries.NoExpiry  := true;
    end if;

    if    (TotAmount_LC != aTotAmount_LC)
       or (TotAmount_LC != aTotAmount_LC) then
      --Erreur montant total des tranches
      aErrorExpiries.TotAmount  := true;
    end if;

    for Pos in 1 .. atblCalculateExpiries.count - 1 loop
      Pos2  := Pos + 1;

      loop
        exit when(aErrorExpiries.DupSlice)
              or (Pos2 > atblCalculateExpiries.count)
              or (atblCalculateExpiries(Pos).Slice != atblCalculateExpiries(Pos2).Slice);

        if     (atblCalculateExpiries(Pos).Amount_LC = atblCalculateExpiries(Pos2).Amount_LC)
           and (atblCalculateExpiries(Pos).Amount_FC = atblCalculateExpiries(Pos2).Amount_FC)
           and (atblCalculateExpiries(Pos).Discount_LC = atblCalculateExpiries(Pos2).Discount_LC)
           and (atblCalculateExpiries(Pos).Discount_FC = atblCalculateExpiries(Pos2).Discount_FC)
           and (    (atblCalculateExpiries(Pos).BVRRef = atblCalculateExpiries(Pos2).BVRRef)
                or (    atblCalculateExpiries(Pos).BVRRef is null
                    and atblCalculateExpiries(Pos2).BVRRef is null)
               )
           and (    (atblCalculateExpiries(Pos).BVRCode = atblCalculateExpiries(Pos2).BVRCode)
                or (    atblCalculateExpiries(Pos).BVRCode is null
                    and atblCalculateExpiries(Pos2).BVRCode is null)
               )
           and (    (atblCalculateExpiries(Pos).FinAccPaymentId = atblCalculateExpiries(Pos2).FinAccPaymentId)
                or (    atblCalculateExpiries(Pos).FinAccPaymentId is null
                    and atblCalculateExpiries(Pos2).FinAccPaymentId is null
                   )
               ) then
          --Erreur 2 même tranche
          aErrorExpiries.DupSlice  := true;
          aErrorExpiries.id        := atblCalculateExpiries(Pos).id;
        end if;

        Pos2  := Pos2 + 1;
      end loop;
    end loop;
  end ControlExpiries;

  function ConvertControlExpiriesRecToBit(aErrorExpiries in TErrorExpiriesRecType)
    return integer
  is
    result integer := 0;
  begin
    if aErrorExpiries.NoExpiry then
      result  := result + 2 ** 0;
    end if;

    if aErrorExpiries.DiscountGreater then
      result  := result + 2 ** 1;
    end if;

    if aErrorExpiries.SliceNotEqual then
      result  := result + 2 ** 2;
    end if;

    if aErrorExpiries.date then
      result  := result + 2 ** 3;
    end if;

    if aErrorExpiries.SliceNumber then
      result  := result + 2 ** 4;
    end if;

    if aErrorExpiries.TotAmount then
      result  := result + 2 ** 5;
    end if;

    if aErrorExpiries.NoCalcNet then
      result  := result + 2 ** 6;
    end if;

    if aErrorExpiries.DupSlice then
      result  := result + 2 ** 7;
    end if;

    if aErrorExpiries.DiffSign then
      result  := result + 2 ** 8;
    end if;

    return result;
  end ConvertControlExpiriesRecToBit;

/* ACT *****************************************************************/
  procedure InsertExpiriesACT(
    atblCalculateExpiries   in TtblCalculateExpiriesType
  , aACT_DOCUMENT_ID        in ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACT_PART_IMPUTATION_ID in ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aUpdate                 in boolean default false
  )
  is
  begin
    for Pos in 1 .. atblCalculateExpiries.count loop
      if aUpdate then
        --Màj des échéances
        update ACT_EXPIRY
           set EXP_ADAPTED = atblCalculateExpiries(Pos).DateAdapted
             , EXP_CALCULATED = atblCalculateExpiries(Pos).DateCalculated
             , EXP_INTEREST_VALUE = atblCalculateExpiries(Pos).DateInterestValue
             , EXP_AMOUNT_LC = atblCalculateExpiries(Pos).Amount_LC
             , EXP_AMOUNT_FC = atblCalculateExpiries(Pos).Amount_FC
             , EXP_AMOUNT_EUR = atblCalculateExpiries(Pos).Amount_EUR
             , EXP_DISCOUNT_LC = atblCalculateExpiries(Pos).Discount_LC
             , EXP_DISCOUNT_FC = atblCalculateExpiries(Pos).Discount_FC
             , EXP_DISCOUNT_EUR = atblCalculateExpiries(Pos).Discount_EUR
             , EXP_SLICE = atblCalculateExpiries(Pos).Slice
             , EXP_POURCENT = atblCalculateExpiries(Pos).Percent
             , EXP_CALC_NET = atblCalculateExpiries(Pos).CalcNet
             , C_STATUS_EXPIRY = atblCalculateExpiries(Pos).Status
             , EXP_DATE_PMT_TOT = decode(atblCalculateExpiries(Pos).Status, '1', trunc(sysdate), null)
             , EXP_BVR_CODE = atblCalculateExpiries(Pos).BVRCode
             , EXP_REF_BVR = atblCalculateExpiries(Pos).BVRRef
             , ACS_FIN_ACC_S_PAYMENT_ID = atblCalculateExpiries(Pos).FinAccPaymentId
             , EXP_AMOUNT_PROV_LC = 0
             , EXP_AMOUNT_PROV_FC = 0
             , EXP_AMOUNT_PROV_EUR = 0
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where ACT_EXPIRY_ID = atblCalculateExpiries(Pos).id;
      else
        --Création des échéances
        insert into ACT_EXPIRY
                    (ACT_EXPIRY_ID
                   , ACT_DOCUMENT_ID
                   , ACT_PART_IMPUTATION_ID
                   , EXP_ADAPTED
                   , EXP_CALCULATED
                   , EXP_INTEREST_VALUE
                   , EXP_AMOUNT_LC
                   , EXP_AMOUNT_FC
                   , EXP_AMOUNT_EUR
                   , EXP_DISCOUNT_LC
                   , EXP_DISCOUNT_FC
                   , EXP_DISCOUNT_EUR
                   , EXP_SLICE
                   , EXP_POURCENT
                   , EXP_CALC_NET
                   , C_STATUS_EXPIRY
                   , EXP_DATE_PMT_TOT
                   , EXP_BVR_CODE
                   , EXP_REF_BVR
                   , ACS_FIN_ACC_S_PAYMENT_ID
                   , EXP_AMOUNT_PROV_LC
                   , EXP_AMOUNT_PROV_FC
                   , EXP_AMOUNT_PROV_EUR
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval
                   , aACT_DOCUMENT_ID
                   , aACT_PART_IMPUTATION_ID
                   , atblCalculateExpiries(Pos).DateAdapted
                   , atblCalculateExpiries(Pos).DateCalculated
                   , atblCalculateExpiries(Pos).DateInterestValue
                   , atblCalculateExpiries(Pos).Amount_LC
                   , atblCalculateExpiries(Pos).Amount_FC
                   , atblCalculateExpiries(Pos).Amount_EUR
                   , atblCalculateExpiries(Pos).Discount_LC
                   , atblCalculateExpiries(Pos).Discount_FC
                   , atblCalculateExpiries(Pos).Discount_EUR
                   , atblCalculateExpiries(Pos).Slice
                   , atblCalculateExpiries(Pos).Percent
                   , atblCalculateExpiries(Pos).CalcNet
                   , atblCalculateExpiries(Pos).Status
                   , decode(atblCalculateExpiries(Pos).Status, '1', trunc(sysdate), null)
                   , atblCalculateExpiries(Pos).BVRCode
                   , atblCalculateExpiries(Pos).BVRRef
                   , atblCalculateExpiries(Pos).FinAccPaymentId
                   , 0
                   ,   -- EXP_AMOUNT_PROV_LC,
                     0
                   ,   -- EXP_AMOUNT_PROV_FC,
                     0
                   ,   -- EXP_AMOUNT_PROV_EUR
                     sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;
    end loop;
  end InsertExpiriesACT;

  procedure GetCurrentCalculateExpiriesACT(
    atblCalculateExpiries   in out TtblCalculateExpiriesType
  , aACT_PART_IMPUTATION_ID in     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  )
  is
    cursor ExpiriesCursor(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type)
    is
      select   exp.EXP_AMOUNT_EUR
             , exp.EXP_AMOUNT_FC
             , exp.EXP_AMOUNT_LC
             , exp.EXP_CALC_NET
             , exp.EXP_ADAPTED
             , exp.EXP_CALCULATED
             , exp.EXP_INTEREST_VALUE
             , exp.EXP_DISCOUNT_EUR
             , exp.EXP_DISCOUNT_FC
             , exp.EXP_DISCOUNT_LC
             , exp.EXP_POURCENT
             , exp.EXP_SLICE
             , exp.EXP_REF_BVR
             , exp.EXP_BVR_CODE
             , exp.C_STATUS_EXPIRY
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , PART.ACS_FINANCIAL_CURRENCY_ID
             , exp.ACT_EXPIRY_ID
          from ACT_EXPIRY exp
             , ACT_PART_IMPUTATION PART
         where PART.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and exp.ACT_PART_IMPUTATION_ID = PART.ACT_PART_IMPUTATION_ID
      order by EXP_SLICE
             , EXP_ADAPTED;

    Pos integer := 1;
  begin
    for ExpiriesCursor_tuple in ExpiriesCursor(aACT_PART_IMPUTATION_ID) loop
      atblCalculateExpiries(Pos)  := ExpiriesCursor_tuple;
      Pos                         := Pos + 1;
    end loop;
  end GetCurrentCalculateExpiriesACT;

  procedure RemovePayedExpiriesACT(
    atblCalculateExpiries in out TtblCalculateExpiriesType
  , aPartialPayment       in     boolean default true
  )
  is
    Pos                   integer;
    Pos2                  integer;
    vLastSlice            integer;
    vtblCalculateExpiries TtblCalculateExpiriesType;

    function DropSlice(aACT_EXPIRY_ID ACT_EXPIRY.ACT_EXPIRY_ID%type)
      return boolean
    is
      vPayment  ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type;
      vExpiryId ACT_EXPIRY.ACT_EXPIRY_ID%type;
      vStatus   ACT_EXPIRY.C_STATUS_EXPIRY%type;
    begin
      select max(EXP2.ACT_EXPIRY_ID)
           , max(EXP2.C_STATUS_EXPIRY)
        into vExpiryId
           , vStatus
        from ACT_EXPIRY EXP1
           , ACT_EXPIRY EXP2
       where EXP1.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and EXP2.ACT_PART_IMPUTATION_ID = EXP1.ACT_PART_IMPUTATION_ID
         and EXP2.EXP_SLICE = EXP1.EXP_SLICE
         and EXP2.EXP_CALC_NET = 1;

      if vExpiryId is null then
        return false;
      elsif vStatus = 1 then
        return true;
      elsif aPartialPayment then
        select min(act_det_payment_id)
          into vPayment
          from act_det_payment
         where act_expiry_id = vExpiryId;

        if vPayment is not null then
          return true;
        end if;
      end if;

      return false;
    end DropSlice;
  begin
    vLastSlice             := 0;

    for Pos in 1 .. atblCalculateExpiries.count loop
      if atblCalculateExpiries(Pos).Slice != vLastSlice then
        --Test si on doit supprimer cette tranche (déjà payée)
        if not DropSlice(atblCalculateExpiries(Pos).id) then
          for Pos2 in 1 .. atblCalculateExpiries.count loop
            if atblCalculateExpiries(Pos2).Slice = atblCalculateExpiries(Pos).Slice then
              vtblCalculateExpiries(nvl(vtblCalculateExpiries.last, 0) + 1) := atblCalculateExpiries(Pos2);
            end if;
          end loop;
        end if;

        vLastSlice  := atblCalculateExpiries(Pos).Slice;
      end if;
    end loop;

    atblCalculateExpiries  := vtblCalculateExpiries;
  end RemovePayedExpiriesACT;

  procedure GenerateExpiriesACT(
    aACT_PART_IMPUTATION_ID    in ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aACS_FIN_ACC_S_PAYMENT_ID  in ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type default null
  , aBVRRef                    in ACT_EXPIRY.EXP_REF_BVR%type default null
  , aBVRCode                   in ACT_EXPIRY.EXP_BVR_CODE%type default null
  , aPAC_PAYMENT_CONDITION_ID  in PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type default null
  , aAmountLC                  in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type default null
  , aAmountFC                  in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type default null
  , aAmountEUR                 in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type default null
  , aReferenceDate             in ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type default null
  , aACS_FINANCIAL_CURRENCY_ID in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type default null
  )
  is
    DocumentId           ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    CustomerId           ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID%type;
    PaymentConditionId   PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
    AmountLC             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountFC             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountEUR            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    ValueDate            ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
    CatalogId            ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    FinAccSPaymentId     ACJ_CATALOGUE_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID%type;
    FinCurrId            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    TypeRef              PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type;
    InfoExpiries         TInfoExpiriesRecType;
    tblCalculateExpiries TtblCalculateExpiriesType;
  begin
    begin
      select DOC.ACT_DOCUMENT_ID
           , PAR.PAC_PAYMENT_CONDITION_ID
           , PAR.PAC_CUSTOM_PARTNER_ID
           , CAT.ACJ_CATALOGUE_DOCUMENT_ID
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_LC_C, 0) - nvl(IMP.IMF_AMOUNT_LC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_FC_C, 0) - nvl(IMP.IMF_AMOUNT_FC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0)
                  , nvl(IMP.IMF_AMOUNT_EUR_C, 0) - nvl(IMP.IMF_AMOUNT_EUR_D, 0)
                   )
           , IMP.IMF_VALUE_DATE
           , nvl(IMP.ACS_FINANCIAL_CURRENCY_ID, PAR.ACS_FINANCIAL_CURRENCY_ID)
           , ref.C_TYPE_REFERENCE
        into DocumentId
           , PaymentConditionId
           , CustomerId
           , CatalogId
           , AmountLC
           , AmountFC
           , AmountEUR
           , ValueDate
           , FinCurrId
           , TypeRef
        from ACT_FINANCIAL_IMPUTATION IMP
           , PAC_FINANCIAL_REFERENCE ref
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
       where PAR.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and PAR.PAC_FINANCIAL_REFERENCE_ID = ref.PAC_FINANCIAL_REFERENCE_ID(+)
         and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID(+)
         and IMP.IMF_PRIMARY(+) = 1;
    exception
      when no_data_found then
        PaymentConditionId  := null;
      when too_many_rows then
        PaymentConditionId  := null;
    end;

    if aAmountLC is not null then
      AmountLC  := aAmountLC;
    end if;

    if aAmountFC is not null then
      AmountFC  := aAmountFC;
    end if;

    if aAmountEUR is not null then
      AmountEUR  := aAmountEUR;
    end if;

    if aPAC_PAYMENT_CONDITION_ID is not null then
      PaymentConditionId  := aPAC_PAYMENT_CONDITION_ID;
    end if;

    if aReferenceDate is not null then
      ValueDate  := aReferenceDate;
    end if;

    if aACS_FINANCIAL_CURRENCY_ID is not null then
      FinCurrId  := aACS_FINANCIAL_CURRENCY_ID;
    end if;

    --Si montant = 0 -> création d'une seul échéance (cond. paiement = null)
    if AmountLC != 0 then
      GetInfoExpiries(InfoExpiries, PaymentConditionId);
    else
      GetInfoExpiries(InfoExpiries, null);
    end if;

    CalculateExpiries(InfoExpiries, tblCalculateExpiries, AmountLC, AmountFC, AmountEUR, ValueDate, FinCurrId, 2);

    if CustomerId is not null then
      if aACS_FIN_ACC_S_PAYMENT_ID is null then
        FinAccSPaymentId  := GetFinAccPaymentId(CatalogId, CustomerId);
      else
        FinAccSPaymentId  := aACS_FIN_ACC_S_PAYMENT_ID;
      end if;
    else
      FinAccSPaymentId  := aACS_FIN_ACC_S_PAYMENT_ID;
    end if;

    UpdateBVRCalculateExpiries(tblCalculateExpiries
                             , FinAccSPaymentId
                             , CustomerId
                             , to_char(DocumentId)
                             , (TypeRef = '3')
                             , aBVRRef
                             , aBVRCode
                              );
    InsertExpiriesACT(tblCalculateExpiries, DocumentId, aACT_PART_IMPUTATION_ID);
  end GenerateExpiriesACT;

  procedure GenerateUpdatedExpiriesACT(
    aACT_PART_IMPUTATION_ID   in ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aUpdateAmount             in integer
  , aUpdateDate               in integer
  , aUpdatePayCond            in integer
  , aUpdateFinAccPay          in integer
  , aUpdateBVRRef             in integer
  , aACS_FIN_ACC_S_PAYMENT_ID in ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type default null
  , aBVRRef                   in ACT_EXPIRY.EXP_REF_BVR%type default null
  , aBVRCode                  in ACT_EXPIRY.EXP_BVR_CODE%type default null
  )
  is
    DocumentId                  ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    CustomerId                  ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID%type;
    PaymentConditionId          PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
    AmountLC                    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountFC                    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountEUR                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    ValueDate                   ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
    CatalogId                   ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    FinAccSPaymentId            ACJ_CATALOGUE_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID%type;
    FinCurrId                   ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    TypeRef                     PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type;
    tblCurrentCalculateExpiries TtblCalculateExpiriesType;
    ChangedInfoExpiries         TChangedInfoExpiriesRecType;
    tblUpdatedCalculateExpiries TtblCalculateExpiriesType;
  begin
    begin
      select DOC.ACT_DOCUMENT_ID
           , PAR.PAC_PAYMENT_CONDITION_ID
           , PAR.PAC_CUSTOM_PARTNER_ID
           , CAT.ACJ_CATALOGUE_DOCUMENT_ID
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_LC_C, 0) - nvl(IMP.IMF_AMOUNT_LC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_FC_C, 0) - nvl(IMP.IMF_AMOUNT_FC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0)
                  , nvl(IMP.IMF_AMOUNT_EUR_C, 0) - nvl(IMP.IMF_AMOUNT_EUR_D, 0)
                   )
           , IMP.IMF_VALUE_DATE
           , nvl(IMP.ACS_FINANCIAL_CURRENCY_ID, PAR.ACS_FINANCIAL_CURRENCY_ID)
           , ref.C_TYPE_REFERENCE
        into DocumentId
           , PaymentConditionId
           , CustomerId
           , CatalogId
           , AmountLC
           , AmountFC
           , AmountEUR
           , ValueDate
           , FinCurrId
           , TypeRef
        from ACT_FINANCIAL_IMPUTATION IMP
           , PAC_FINANCIAL_REFERENCE ref
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
       where PAR.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and PAR.PAC_FINANCIAL_REFERENCE_ID = ref.PAC_FINANCIAL_REFERENCE_ID(+)
         and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID(+)
         and IMP.IMF_PRIMARY(+) = 1;
    exception
      when no_data_found then
        PaymentConditionId  := null;
      when too_many_rows then
        PaymentConditionId  := null;
    end;

    GetCurrentCalculateExpiriesACT(tblCurrentCalculateExpiries, aACT_PART_IMPUTATION_ID);
    ChangedInfoExpiries.PaymentCondition           := aUpdatePayCond != 0;
    ChangedInfoExpiries.Amount                     := aUpdateAmount != 0;
    ChangedInfoExpiries.date                       := aUpdateDate != 0;
    ChangedInfoExpiries.FinAccPayment              := aUpdateFinAccPay != 0;
    ChangedInfoExpiries.BVRReference               := aUpdateBVRRef != 0;
    ChangedInfoExpiries.BVRUpdate                  := TypeRef = '3';
    ChangedInfoExpiries.PAC_PAYMENT_CONDITION_ID   := PaymentConditionId;
    ChangedInfoExpiries.TotAmount_LC               := AmountLC;
    ChangedInfoExpiries.TotAmount_FC               := AmountFC;
    ChangedInfoExpiries.TotAmount_EUR              := AmountEUR;
    ChangedInfoExpiries.ReferenceDate              := ValueDate;
    ChangedInfoExpiries.ACS_FINANCIAL_CURRENCY_ID  := FinCurrId;
    ChangedInfoExpiries.RoundType                  := 2;
    ChangedInfoExpiries.ACS_FIN_ACC_S_PAYMENT_ID   := aACS_FIN_ACC_S_PAYMENT_ID;
    ChangedInfoExpiries.PAC_CUSTOM_PARTNER_ID      := CustomerId;
    ChangedInfoExpiries.DocumentRefId              := to_char(DocumentId);
    ChangedInfoExpiries.BVRRef                     := aBVRRef;
    ChangedInfoExpiries.BVRCode                    := aBVRCode;

    if not UpdateCalculateExpiries(tblCurrentCalculateExpiries, ChangedInfoExpiries, tblUpdatedCalculateExpiries) then
      delete from ACT_EXPIRY
            where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;

      GenerateExpiriesACT(aACT_PART_IMPUTATION_ID, aACS_FIN_ACC_S_PAYMENT_ID, aBVRRef, aBVRCode);
    else
      InsertExpiriesACT(tblUpdatedCalculateExpiries, null, null, true);
    end if;
  end GenerateUpdatedExpiriesACT;

  procedure ControlExpiriesACT(
    aACT_PART_IMPUTATION_ID in     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aErrorExpiries          in out TErrorExpiriesRecType
  )
  is
    AmountLC             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountFC             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountEUR            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    tblCalculateExpiries TtblCalculateExpiriesType;
    ErrorExpiries        TErrorExpiriesRecType;
  begin
    begin
      select decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_LC_C, 0) - nvl(IMP.IMF_AMOUNT_LC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_FC_C, 0) - nvl(IMP.IMF_AMOUNT_FC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0)
                  , nvl(IMP.IMF_AMOUNT_EUR_C, 0) - nvl(IMP.IMF_AMOUNT_EUR_D, 0)
                   )
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_FINANCIAL_IMPUTATION IMP
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
       where PAR.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID(+)
         and IMP.IMF_PRIMARY(+) = 1;
    exception
      when no_data_found then
        return;
      when too_many_rows then
        return;
    end;

    GetCurrentCalculateExpiriesACT(tblCalculateExpiries, aACT_PART_IMPUTATION_ID);
    ControlExpiries(tblCalculateExpiries, AmountLC, AmountFC, aErrorExpiries);
  end ControlExpiriesACT;

  procedure ControlExpiriesACT(
    aACT_PART_IMPUTATION_ID in     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aErrors                 out    integer
  , aErrorID                out    ACT_EXPIRY.ACT_EXPIRY_ID%type
  )
  is
    ErrorExpiries TErrorExpiriesRecType;
  begin
    ControlExpiriesACT(aACT_PART_IMPUTATION_ID, ErrorExpiries);
    aErrors   := ConvertControlExpiriesRecToBit(ErrorExpiries);
    aErrorID  := ErrorExpiries.id;
  end ControlExpiriesACT;

  function ControlExpiriesACT(aACT_PART_IMPUTATION_ID in ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type)
    return integer
  is
    errors  integer;
    ErrorID ACT_EXPIRY.ACT_EXPIRY_ID%type;
  begin
    ControlExpiriesACT(aACT_PART_IMPUTATION_ID, errors, ErrorID);
    return errors;
  end ControlExpiriesACT;

  procedure CorrectExpiriesACT(
    aACT_PART_IMPUTATION_ID   in ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aACS_FIN_ACC_S_PAYMENT_ID in ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type default null
  , aBVRRef                   in ACT_EXPIRY.EXP_REF_BVR%type default null
  , aBVRCode                  in ACT_EXPIRY.EXP_BVR_CODE%type default null
  , aExcludePayed             in integer default 0
  )
  is
    DocumentId           ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    CustomerId           ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID%type;
    PaymentConditionId   PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
    tblCalculateExpiries TtblCalculateExpiriesType;
    flagupdate           integer;
  begin
    begin
      select DOC.ACT_DOCUMENT_ID
           , PAR.PAC_PAYMENT_CONDITION_ID
           , PAR.PAC_CUSTOM_PARTNER_ID
        into DocumentId
           , PaymentConditionId
           , CustomerId
        from ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
       where PAR.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID;
    exception
      when no_data_found then
        PaymentConditionId  := null;
      when too_many_rows then
        PaymentConditionId  := null;
    end;

    GetCurrentCalculateExpiriesACT(tblCalculateExpiries, aACT_PART_IMPUTATION_ID);

    if aExcludePayed != 0 then
      RemovePayedExpiriesACT(tblCalculateExpiries);
    end if;

    flagupdate  :=
      CorrectExpiries(tblCalculateExpiries
                    , aACS_FIN_ACC_S_PAYMENT_ID
                    , CustomerId
                    , to_char(DocumentId)
                    , aBVRRef
                    , aBVRCode
                     );

    if flagupdate > 0 then
      InsertExpiriesACT(tblCalculateExpiries, null, null, true);

      if     (aExcludePayed != 0)
         and (flagupdate > 1) then
        --Regénération des réf. BVR (seulement si pas aExcludePayed)
        GenerateUpdatedExpiriesACT(aACT_PART_IMPUTATION_ID, 0, 0, 0, 1, 0, aACS_FIN_ACC_S_PAYMENT_ID, aBVRRef
                                 , aBVRCode);
      end if;
    end if;
  end CorrectExpiriesACT;

  procedure UpdateExpCalcNetACT(aACT_PART_IMPUTATION_ID in ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type)
  is
    tblCalculateExpiries TtblCalculateExpiriesType;
  begin
    GetCurrentCalculateExpiriesACT(tblCalculateExpiries, aACT_PART_IMPUTATION_ID);

    if UpdateExpCalcNet(tblCalculateExpiries) then
      InsertExpiriesACT(tblCalculateExpiries, null, null, true);
    end if;
  end UpdateExpCalcNetACT;

/***************************************************************** ACT */

  /* ACI *****************************************************************/
  procedure InsertExpiriesACI(
    atblCalculateExpiries   in TtblCalculateExpiriesType
  , aACI_PART_IMPUTATION_ID in ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  , aUpdate                 in boolean default false
  )
  is
  begin
    for Pos in 1 .. atblCalculateExpiries.count loop
      if aUpdate then
        --Màj des échéances
        update ACI_EXPIRY
           set EXP_ADAPTED = atblCalculateExpiries(Pos).DateAdapted
             , EXP_CALCULATED = atblCalculateExpiries(Pos).DateCalculated
             , EXP_AMOUNT_LC = atblCalculateExpiries(Pos).Amount_LC
             , EXP_AMOUNT_FC = atblCalculateExpiries(Pos).Amount_FC
             , EXP_AMOUNT_EUR = atblCalculateExpiries(Pos).Amount_EUR
             , EXP_DISCOUNT_LC = atblCalculateExpiries(Pos).Discount_LC
             , EXP_DISCOUNT_FC = atblCalculateExpiries(Pos).Discount_FC
             , EXP_DISCOUNT_EUR = atblCalculateExpiries(Pos).Discount_EUR
             , EXP_SLICE = atblCalculateExpiries(Pos).Slice
             , EXP_POURCENT = atblCalculateExpiries(Pos).Percent
             , EXP_CALC_NET = atblCalculateExpiries(Pos).CalcNet
             , C_STATUS_EXPIRY = atblCalculateExpiries(Pos).Status
             , EXP_DATE_PMT_TOT = decode(atblCalculateExpiries(Pos).Status, '1', trunc(sysdate), null)
             , EXP_BVR_CODE = atblCalculateExpiries(Pos).BVRCode
             , EXP_REF_BVR = atblCalculateExpiries(Pos).BVRRef
             , ACS_FIN_ACC_S_PAYMENT_ID = atblCalculateExpiries(Pos).FinAccPaymentId
             , EXP_AMOUNT_PROV_LC = 0
             , EXP_AMOUNT_PROV_FC = 0
             , EXP_AMOUNT_PROV_EUR = 0
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where ACI_EXPIRY_ID = atblCalculateExpiries(Pos).id;
      else
        --Création des échéances
        insert into ACI_EXPIRY
                    (ACI_EXPIRY_ID
                   , ACI_PART_IMPUTATION_ID
                   , EXP_ADAPTED
                   , EXP_CALCULATED
                   , EXP_AMOUNT_LC
                   , EXP_AMOUNT_FC
                   , EXP_AMOUNT_EUR
                   , EXP_DISCOUNT_LC
                   , EXP_DISCOUNT_FC
                   , EXP_DISCOUNT_EUR
                   , EXP_SLICE
                   , EXP_POURCENT
                   , EXP_CALC_NET
                   , C_STATUS_EXPIRY
                   , EXP_DATE_PMT_TOT
                   , EXP_BVR_CODE
                   , EXP_REF_BVR
                   , ACS_FIN_ACC_S_PAYMENT_ID
                   , EXP_AMOUNT_PROV_LC
                   , EXP_AMOUNT_PROV_FC
                   , EXP_AMOUNT_PROV_EUR
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (ACI_ID_SEQ.nextval
                   , aACI_PART_IMPUTATION_ID
                   , atblCalculateExpiries(Pos).DateAdapted
                   , atblCalculateExpiries(Pos).DateCalculated
                   , atblCalculateExpiries(Pos).Amount_LC
                   , atblCalculateExpiries(Pos).Amount_FC
                   , atblCalculateExpiries(Pos).Amount_EUR
                   , atblCalculateExpiries(Pos).Discount_LC
                   , atblCalculateExpiries(Pos).Discount_FC
                   , atblCalculateExpiries(Pos).Discount_EUR
                   , atblCalculateExpiries(Pos).Slice
                   , atblCalculateExpiries(Pos).Percent
                   , atblCalculateExpiries(Pos).CalcNet
                   , atblCalculateExpiries(Pos).Status
                   , decode(atblCalculateExpiries(Pos).Status, '1', trunc(sysdate), null)
                   , atblCalculateExpiries(Pos).BVRCode
                   , atblCalculateExpiries(Pos).BVRRef
                   , atblCalculateExpiries(Pos).FinAccPaymentId
                   , 0
                   ,   -- EXP_AMOUNT_PROV_LC,
                     0
                   ,   -- EXP_AMOUNT_PROV_FC,
                     0
                   ,   -- EXP_AMOUNT_PROV_EUR
                     sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;
    end loop;
  end InsertExpiriesACI;

  procedure GetCurrentCalculateExpiriesACI(
    ptblCalculateExpiries   in out TtblCalculateExpiriesType
  , pACI_PART_IMPUTATION_ID in     ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  )
  is
    cursor ExpiriesCursor(pACI_PART_IMPUTATION_ID ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type)
    is
      select   exp.EXP_AMOUNT_EUR
             , exp.EXP_AMOUNT_FC
             , exp.EXP_AMOUNT_LC
             , exp.EXP_CALC_NET
             , exp.EXP_ADAPTED
             , exp.EXP_CALCULATED
             , to_date(null)
             ,   --EXP_INTEREST_VALUE
               exp.EXP_DISCOUNT_EUR
             , exp.EXP_DISCOUNT_FC
             , exp.EXP_DISCOUNT_LC
             , exp.EXP_POURCENT
             , exp.EXP_SLICE
             , exp.EXP_REF_BVR
             , exp.EXP_BVR_CODE
             , exp.C_STATUS_EXPIRY
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , PART.ACS_FINANCIAL_CURRENCY_ID
             , exp.ACI_EXPIRY_ID
          from ACI_EXPIRY exp
             , ACI_PART_IMPUTATION PART
         where PART.ACI_PART_IMPUTATION_ID = pACI_PART_IMPUTATION_ID
           and exp.ACI_PART_IMPUTATION_ID = PART.ACI_PART_IMPUTATION_ID
      order by EXP_SLICE
             , EXP_ADAPTED;

    Pos integer := 1;
  begin
    for ExpiriesCursor_tuple in ExpiriesCursor(pACI_PART_IMPUTATION_ID) loop
      ptblCalculateExpiries(Pos)  := ExpiriesCursor_tuple;
      Pos                         := Pos + 1;
    end loop;
  end GetCurrentCalculateExpiriesACI;

  procedure GenerateExpiriesACI(
    aACI_PART_IMPUTATION_ID in ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  , aBVRRef                 in ACT_EXPIRY.EXP_REF_BVR%type default null
  , aBVRCode                in ACT_EXPIRY.EXP_BVR_CODE%type default null
  , aFinAccPaymentID        in ACI_EXPIRY.ACS_FIN_ACC_S_PAYMENT_ID%type default null
  )
  is
    DocumentId           ACI_DOCUMENT.ACT_DOCUMENT_ID%type;
    CustomerId           ACI_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID%type;
    PaymentConditionId   PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
    AmountLC             ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountFC             ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountEUR            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    ValueDate            ACI_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
    CatalogId            ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    FinCurrId            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    InfoExpiries         TInfoExpiriesRecType;
    tblCalculateExpiries TtblCalculateExpiriesType;
  begin
    begin
      select DOC.ACI_DOCUMENT_ID
           , PAR.PAC_PAYMENT_CONDITION_ID
           , PAR.PAC_CUSTOM_PARTNER_ID
           , CAT.ACJ_CATALOGUE_DOCUMENT_ID
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_LC_C, 0) - nvl(IMP.IMF_AMOUNT_LC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_FC_C, 0) - nvl(IMP.IMF_AMOUNT_FC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0)
                  , nvl(IMP.IMF_AMOUNT_EUR_C, 0) - nvl(IMP.IMF_AMOUNT_EUR_D, 0)
                   )
           , nvl(IMP.IMF_VALUE_DATE, nvl(IMP.IMF_TRANSACTION_DATE, DOC.DOC_DOCUMENT_DATE) )
           , IMP.ACS_FINANCIAL_CURRENCY_ID
        into DocumentId
           , PaymentConditionId
           , CustomerId
           , CatalogId
           , AmountLC
           , AmountFC
           , AmountEUR
           , ValueDate
           , FinCurrId
        from ACI_FINANCIAL_IMPUTATION IMP
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACJ_JOB_TYPE_S_CATALOGUE JOBCAT
           , ACI_PART_IMPUTATION PAR
           , ACI_DOCUMENT DOC
       where PAR.ACI_PART_IMPUTATION_ID = aACI_PART_IMPUTATION_ID
         and DOC.ACI_DOCUMENT_ID = PAR.ACI_DOCUMENT_ID
         and DOC.ACJ_JOB_TYPE_S_CATALOGUE_ID = JOBCAT.ACJ_JOB_TYPE_S_CATALOGUE_ID
         and JOBCAT.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and DOC.ACI_DOCUMENT_ID = IMP.ACI_DOCUMENT_ID
         and IMP.IMF_PRIMARY + 0 = 1;
    exception
      when no_data_found then
        PaymentConditionId  := null;
      when too_many_rows then
        PaymentConditionId  := null;
    end;

    GetInfoExpiries(InfoExpiries, PaymentConditionId);
    CalculateExpiries(InfoExpiries, tblCalculateExpiries, AmountLC, AmountFC, AmountEUR, ValueDate, FinCurrId, 2);

    --FinAccSPaymentId  := GetFinAccPaymentId(CatalogId, CustomerId);
    if aFinAccPaymentID is not null then
      UpdateBVRCalculateExpiries(tblCalculateExpiries, aFinAccPaymentID, CustomerId, to_char(DocumentId) );
    end if;

    InsertExpiriesACI(tblCalculateExpiries, aACI_PART_IMPUTATION_ID);
  end GenerateExpiriesACI;

  procedure GenerateUpdatedExpiriesACI(
    pACI_PART_IMPUTATION_ID   in ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  , pUpdateAmount             in integer
  , pUpdateDate               in integer
  , pUpdatePayCond            in integer
  , pUpdateFinAccPay          in integer
  , pUpdateBVRRef             in integer
  , pACS_FIN_ACC_S_PAYMENT_ID in ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type default null
  , pBVRRef                   in ACI_EXPIRY.EXP_REF_BVR%type default null
  , pBVRCode                  in ACI_EXPIRY.EXP_BVR_CODE%type default null
  )
  is
    DocumentId                  ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    CustomerId                  ACI_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID%type;
    PaymentConditionId          PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
    AmountLC                    ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountFC                    ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountEUR                   ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    ValueDate                   ACI_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
    CatalogId                   ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    FinAccSPaymentId            ACJ_CATALOGUE_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID%type;
    FinCurrId                   ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    TypeRef                     PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type;
    tblCurrentCalculateExpiries TtblCalculateExpiriesType;
    ChangedInfoExpiries         TChangedInfoExpiriesRecType;
    tblUpdatedCalculateExpiries TtblCalculateExpiriesType;
  begin
    begin
      select DOC.ACI_DOCUMENT_ID
           , PAR.PAC_PAYMENT_CONDITION_ID
           , PAR.PAC_CUSTOM_PARTNER_ID
           , CAT.ACJ_CATALOGUE_DOCUMENT_ID
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_LC_C, 0) - nvl(IMP.IMF_AMOUNT_LC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0)
                  , nvl(IMP.IMF_AMOUNT_FC_C, 0) - nvl(IMP.IMF_AMOUNT_FC_D, 0)
                   )
           , decode(PAR.PAC_SUPPLIER_PARTNER_ID
                  , null, nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0)
                  , nvl(IMP.IMF_AMOUNT_EUR_C, 0) - nvl(IMP.IMF_AMOUNT_EUR_D, 0)
                   )
           , IMP.IMF_VALUE_DATE
           , nvl(IMP.ACS_FINANCIAL_CURRENCY_ID, PAR.ACS_FINANCIAL_CURRENCY_ID)
           , ref.C_TYPE_REFERENCE
        into DocumentId
           , PaymentConditionId
           , CustomerId
           , CatalogId
           , AmountLC
           , AmountFC
           , AmountEUR
           , ValueDate
           , FinCurrId
           , TypeRef
        from ACI_FINANCIAL_IMPUTATION IMP
           , PAC_FINANCIAL_REFERENCE ref
           , ACJ_JOB_TYPE_S_CATALOGUE TYP
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACI_DOCUMENT DOC
           , ACI_PART_IMPUTATION PAR
       where PAR.ACI_PART_IMPUTATION_ID = pACI_PART_IMPUTATION_ID
         and DOC.ACI_DOCUMENT_ID = PAR.ACI_DOCUMENT_ID
         and DOC.ACJ_JOB_TYPE_S_CATALOGUE_ID = TYP.ACJ_JOB_TYPE_S_CATALOGUE_ID
         and TYP.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and PAR.PAC_FINANCIAL_REFERENCE_ID = ref.PAC_FINANCIAL_REFERENCE_ID(+)
         and DOC.ACI_DOCUMENT_ID = IMP.ACI_DOCUMENT_ID(+)
         and IMP.IMF_PRIMARY(+) = 1;
    exception
      when no_data_found then
        PaymentConditionId  := null;
      when too_many_rows then
        PaymentConditionId  := null;
    end;

    GetCurrentCalculateExpiriesACI(tblCurrentCalculateExpiries, pACI_PART_IMPUTATION_ID);
    ChangedInfoExpiries.PaymentCondition           := pUpdatePayCond != 0;
    ChangedInfoExpiries.Amount                     := pUpdateAmount != 0;
    ChangedInfoExpiries.date                       := pUpdateDate != 0;
    ChangedInfoExpiries.FinAccPayment              := pUpdateFinAccPay != 0;
    ChangedInfoExpiries.BVRReference               := pUpdateBVRRef != 0;
    ChangedInfoExpiries.BVRUpdate                  := TypeRef = '3';
    ChangedInfoExpiries.PAC_PAYMENT_CONDITION_ID   := PaymentConditionId;
    ChangedInfoExpiries.TotAmount_LC               := AmountLC;
    ChangedInfoExpiries.TotAmount_FC               := AmountFC;
    ChangedInfoExpiries.TotAmount_EUR              := AmountEUR;
    ChangedInfoExpiries.ReferenceDate              := ValueDate;
    ChangedInfoExpiries.ACS_FINANCIAL_CURRENCY_ID  := FinCurrId;
    ChangedInfoExpiries.RoundType                  := 2;
    ChangedInfoExpiries.ACS_FIN_ACC_S_PAYMENT_ID   := pACS_FIN_ACC_S_PAYMENT_ID;
    ChangedInfoExpiries.PAC_CUSTOM_PARTNER_ID      := CustomerId;
    ChangedInfoExpiries.DocumentRefId              := to_char(DocumentId);
    ChangedInfoExpiries.BVRRef                     := pBVRRef;
    ChangedInfoExpiries.BVRCode                    := pBVRCode;

    if not UpdateCalculateExpiries(tblCurrentCalculateExpiries, ChangedInfoExpiries, tblUpdatedCalculateExpiries) then
      delete from ACI_EXPIRY
            where ACI_PART_IMPUTATION_ID = pACI_PART_IMPUTATION_ID;

      GenerateExpiriesACI(pACI_PART_IMPUTATION_ID, pBVRRef, pBVRCode);
    else
      InsertExpiriesACI(tblUpdatedCalculateExpiries, null, true);
    end if;
  end GenerateUpdatedExpiriesACI;
/***************************************************************** ACI */
end ACT_EXPIRY_MANAGEMENT;
