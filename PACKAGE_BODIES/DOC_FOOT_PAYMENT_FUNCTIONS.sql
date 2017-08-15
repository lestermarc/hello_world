--------------------------------------------------------
--  DDL for Package Body DOC_FOOT_PAYMENT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_FOOT_PAYMENT_FUNCTIONS" 
is
  /**
  * Description
  *   Recherche le cours de change et le cours par rapport utilisé par la transaction de payment courante
  */
  function GetExchangeRate(
    APaymentCurrencyID    in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ADocumentID           in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , AExchangeRate         out    DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ABasePrice            out    DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , APaymentExchangeRate  out    DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , APaymentBasePrice     out    DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , ADocumentCurrencyID   out    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ADocumentExchangeRate out    DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ADocumentBasePrice    out    DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  )
    return boolean
  is
    baseFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    dmtDateDocument         DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    numBaseChange           number;
    numRateExchangeEUR      number;
    numEuroChange           number;
    numRateExchangeEURMB    number;
    numEuroChangeMB         number;
    result                  boolean;
  begin
    -- Recherche la monnaie de base
    baseFinancialCurrencyID  := ACS_FUNCTION.GetLocalCurrencyID;
    result                   := true;

    -- Recherche les informations du document concernant le cours du document.
    select DMT.ACS_FINANCIAL_CURRENCY_ID
         , DMT.DMT_RATE_OF_EXCHANGE
         , DMT.DMT_BASE_PRICE
         , DMT.DMT_DATE_DOCUMENT
      into ADocumentCurrencyID
         , ADocumentExchangeRate
         , ADocumentBasePrice
         , dmtDateDocument
      from DOC_DOCUMENT DMT
     where DMT.DOC_DOCUMENT_ID = ADocumentID;

    if     (ADocumentCurrencyID = baseFinancialCurrencyID)
       and (APaymentCurrencyID = baseFinancialCurrencyID) then
      ----
      -- Cas 1 : Monnaie du document = monnaie de base = monnaie d'encaissement
      --
      AExchangeRate         := 1;
      ABasePrice            := 1;
      APaymentExchangeRate  := 1;
      APaymentBasePrice     := 1;
    elsif     (ADocumentCurrencyID = baseFinancialCurrencyID)
          and (APaymentCurrencyID <> baseFinancialCurrencyID) then
      ----
      -- Cas 2 : Monnaie du document = Monnaie de base <> Monnaie d'encaissement
      --
      -- Recherche du cours et de l'unité de base de l'encaissement par rapport à la monnaie de base
      if (ACS_FUNCTION.GetRateOfExchangeEUR(APaymentCurrencyID
                                          , 1
                                          , dmtDateDocument
                                          , AExchangeRate
                                          , ABasePrice
                                          , numBaseChange
                                          , numRateExchangeEUR
                                          , numEuroChange
                                          , numRateExchangeEURMB
                                          , numEuroChangeMB
                                          , 1
                                           ) = 0
         ) then
        result  := false;
      end if;

      -- Si le cours est E/b, alors il faut inverser le cours
      if (numBaseChange = 0) then
        AExchangeRate  :=( (ABasePrice * ABasePrice) / AExchangeRate);
      end if;

      APaymentExchangeRate  := AExchangeRate;
      APaymentBasePrice     := ABasePrice;
    elsif     (ADocumentCurrencyID <> baseFinancialCurrencyID)
          and (APaymentCurrencyID = baseFinancialCurrencyID) then
      ----
      -- Cas 3 : Monnaie du document <> Monnaie de base = Monnaie d'encaissement
      --
      -- Utilise le cours du document.
      AExchangeRate         := ADocumentExchangeRate;
      ABasePrice            := ADocumentBasePrice;
      APaymentExchangeRate  := ADocumentExchangeRate;
      APaymentBasePrice     := ADocumentBasePrice;
    elsif     (ADocumentCurrencyID <> baseFinancialCurrencyID)
          and (APaymentCurrencyID <> baseFinancialCurrencyID)
          and (ADocumentCurrencyID = APaymentCurrencyID) then
      ----
      -- Cas 4 : Monnaie du document = Monnaie d'encaissement <> Monnaie de base
      --
      -- Utilise le cours du document.
      AExchangeRate         := ADocumentExchangeRate;
      ABasePrice            := ADocumentBasePrice;
      APaymentExchangeRate  := ADocumentExchangeRate;
      APaymentBasePrice     := ADocumentBasePrice;
    else   -- ( ADocumentCurrencyID <> APaymentCurrencyID ) and ( ADocumentCurrencyID <> baseFinancialCurrencyID )
      ----
      -- Cas 5 : Monnaie du document <> Monnaie d'encaissement <> Monnaie de base
      --
      -- Recherche du cours et de l'unité de base de l'encaissement par rapport à la monnaie de base
      if (ACS_FUNCTION.GetRateOfExchangeEUR(APaymentCurrencyID
                                          , 1
                                          , dmtDateDocument
                                          , APaymentExchangeRate
                                          , APaymentBasePrice
                                          , numBaseChange
                                          , numRateExchangeEUR
                                          , numEuroChange
                                          , numRateExchangeEURMB
                                          , numEuroChangeMB
                                          , 1
                                           ) = 0
         ) then
        result  := false;
      end if;

      if result then
        AExchangeRate  := (APaymentExchangeRate / APaymentBasePrice) /(ADocumentExchangeRate / ADocumentBasePrice);
        ABasePrice     := 1;
      end if;
    end if;

    return result;
  end GetExchangeRate;

  /**
  * Description
  *   Méthode de recherche du cours entre la monnaie d'encaissement et la monnaie du document.
  */
  function GetPaymentRate(
    APaymentCurrencyID  in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ADocumentCurrencyID in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , AExchangeRate       in DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ABasePrice          in DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  )
    return number
  is
    baseFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    result                  number;
  begin
    -- Recherche la monnaie de base
    baseFinancialCurrencyID  := ACS_FUNCTION.GetLocalCurrencyID;

    if     (ADocumentCurrencyID = baseFinancialCurrencyID)
       and (APaymentCurrencyID = baseFinancialCurrencyID) then
      -- Monnaie du document = monnaie de base = monnaie d'encaissement
      result  := 1;
    elsif     (ADocumentCurrencyID = baseFinancialCurrencyID)
          and (APaymentCurrencyID <> baseFinancialCurrencyID) then
      -- Monnaie du document = Monnaie de base <> Monnaie d'encaissement
      result  := ABasePrice / AExchangeRate;
    elsif     (ADocumentCurrencyID <> baseFinancialCurrencyID)
          and (APaymentCurrencyID = baseFinancialCurrencyID) then
      -- Monnaie du document <> Monnaie de base = Monnaie d'encaissement
      result  := AExchangeRate / ABasePrice;
    elsif     (ADocumentCurrencyID <> baseFinancialCurrencyID)
          and (APaymentCurrencyID <> baseFinancialCurrencyID)
          and (ADocumentCurrencyID = APaymentCurrencyID) then
      -- Monnaie du document = Monnaie d'encaissement <> Monnaie de base
      result  := 1;
    else   -- ( ADocumentCurrencyID <> APaymentCurrencyID ) and ( ADocumentCurrencyID <> baseFinancialCurrencyID )
      -- Monnaie du document <> Monnaie d'encaissement <> Monnaie de base
      -- Cas non autorisé
      result  := 0;
    end if;

    return result;
  end GetPaymentRate;

  /**
  * Description
  *   Méthode de recherche du montant du document en monnaie de document
  *   Retourne le montant total du document. Recherche la plus petit échéance de la première tranche.
  */
  function GetDocumentAmount(ADocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    result number;
  begin
    result  := 0;

    begin
      select PAD1.PAD_NET_DATE_AMOUNT
        into result
        from (select   PAD.PAD_NET_DATE_AMOUNT
                  from DOC_PAYMENT_DATE PAD
                 where PAD.DOC_FOOT_ID = ADocumentID
              order by PAD.PAD_BAND_NUMBER
                     , PAD.PAD_PAYMENT_DATE
                     , PAD.PAD_DISCOUNT_AMOUNT desc) PAD1
       where rownum = 1;
    exception
      when no_data_found then
        null;
    end;

    return result;
  end GetDocumentAmount;

  /**
  * Description
  *   Méthode de recherche du montant du document encore à encaisser
  *   Retourne le montant à encaisser en monnaie du document en se basant sur les échéances et les payments déjà effectués
  */
  function GetReceivedAmountMD(ADocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, AFootPaymentID in DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type)
    return number
  is
    numPaymentDateAmount number;
    fopReceivedAmountMD  DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type;
  begin
    -- Retourne le montant total du document. Recherche la plus petit échéance de la première tranche.
    numPaymentDateAmount  := GetDocumentAmount(ADocumentID);

    select nvl(sum(FOP.FOP_RECEIVED_AMOUNT_MD), 0) - nvl(sum(FOP.FOP_RETURNED_AMOUNT_MD), 0)
      into fopReceivedAmountMD
      from DOC_FOOT_PAYMENT FOP
     where FOP.DOC_FOOT_ID = ADocumentID;

    --and FOP.DOC_FOOT_PAYMENT_ID <> AFootPaymentID;
    return numPaymentDateAmount - fopReceivedAmountMD;
  end GetReceivedAmountMD;

  /**
  * Description
  *   Méthode de recherche du montant solde à encaisser. Ne plus utiliser car elle ne tient pas compte
  *   des montants d'escompte et de déduction.
  *   Retourne le montant à encaisser en monnaie du paiement en se basant sur
  *   les échéances et les paiements précédant le paiement AFootPaymentID ou sur
  *   tous les paiements si AFootPaymentID est null ou égal à 0.
  */
  function GetPaidBalancedAmount(
    ADocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , APaymentRate   in number
  , AFootPaymentID in DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type default 0
  , APaidAmount    in DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type default 0
  )
    return number
  is
    numPaymentDateAmount number;
    fopPaidAmountMD      DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type;
  begin
    -- Retourne le montant total du document. Recherche la plus petit échéance de la première tranche.
    numPaymentDateAmount  := GetDocumentAmount(ADocumentID);

    if nvl(AFootPaymentID, 0) <> 0 then
      select nvl(sum(FOP.FOP_PAID_AMOUNT_MD), 0)
        into fopPaidAmountMD
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID
         and FOP.DOC_FOOT_PAYMENT_ID < AFootPaymentID;
    else
      select nvl(sum(FOP.FOP_PAID_AMOUNT_MD), 0)
        into fopPaidAmountMD
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID;
    end if;

    --and FOP.DOC_FOOT_PAYMENT_ID <> AFootPaymentID;
    return ( (numPaymentDateAmount - fopPaidAmountMD) * APaymentRate) - APaidAmount;
  end GetPaidBalancedAmount;

  /**
  * Description
  *   Méthode de recherche du montant solde à encaisser en monnaie du document. Ne plus utiliser car elle ne tient pas compte
  *   des montants d'escompte et de déduction.
  *   Retourne le montant à encaisser en monnaie du document en se basant sur
  *   les échéances et les paiements précédant le paiement AFootPaymentID ou sur
  *   tous les paiements si AFootPaymentID est null ou égal à 0.
  */
  function GetPaidBalancedAmountMD(
    ADocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , AFootPaymentID in DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type default 0
  , APaidAmountMD  in DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type default 0
  )
    return number
  is
    numPaymentDateAmount number;
    fopPaidAmountMD      DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type;
  begin
    -- Retourne le montant total du document. Recherche la plus petit échéance de la première tranche.
    numPaymentDateAmount  := GetDocumentAmount(ADocumentID);

    if nvl(AFootPaymentID, 0) <> 0 then
      select nvl(sum(FOP.FOP_PAID_AMOUNT_MD), 0)
        into fopPaidAmountMD
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID
         and FOP.DOC_FOOT_PAYMENT_ID < AFootPaymentID;
    else
      select nvl(sum(FOP.FOP_PAID_AMOUNT_MD), 0)
        into fopPaidAmountMD
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID;
    end if;

    --and FOP.DOC_FOOT_PAYMENT_ID <> AFootPaymentID;
    return numPaymentDateAmount - fopPaidAmountMD - APaidAmountMD;
  end GetPaidBalancedAmountMD;

  /**
  * Description
  *   Méthode de modification du montant à encaisser (reçu) Ne plus utiliser car elle ne tient pas compte
  *   des montants d'escompte et de déduction.
  */
  procedure OnReceivedAmountModification(
    AReceivedAmount       in     DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type
  , AFootPaymentID        in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , APaymentCurrencyID    in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ADocumentID           in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , AExchangeRate         in     DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ABasePrice            in     DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , AReceivedAmountMD     out    DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type
  , AReceivedAmountMB     out    DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type
  , APaidAmount           out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , APaidAmountMD         out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type
  , APaidAmountMB         out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , AReturnedAmount       out    DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , AReturnedAmountMD     out    DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type
  , AReturnedAmountMB     out    DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type
  , APaidBalancedAmount   out    DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type
  , APaidBalancedAmountMD out    DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type
  , APaidBalancedAmountMB out    DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type
  )
  is
    dmtFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    dmtRateOfExchange      DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice           DOC_DOCUMENT.DMT_BASE_PRICE%type;
    numDocumentAmount      number;
    numPaymentAmount       number;
    numPaymentRate         number;
  begin
    -- Recherche les informations du document concernant le cours du document.
    select DMT.ACS_FINANCIAL_CURRENCY_ID
         , DMT.DMT_RATE_OF_EXCHANGE
         , DMT.DMT_BASE_PRICE
      into dmtFinancialCurrencyID
         , dmtRateOfExchange
         , dmtBasePrice
      from DOC_DOCUMENT DMT
     where DMT.DOC_DOCUMENT_ID = ADocumentID;

    -- Recherche du cours entre la monnaie d'encaissement et la monnaie du document (cours de calcul)
    numPaymentRate         := GetPaymentRate(APaymentCurrencyID, dmtFinancialCurrencyID, AExchangeRate, ABasePrice);
    -- Recherche le montant total du document qui reste à encaisser. Recherche la plus petit échéance de la
    -- première tranche.
    numDocumentAmount      := GetReceivedAmountMD(ADocumentID, AFootPaymentID);
    -- Convertit le montant total du document en monnaie d'encaissement.
    numPaymentAmount       := numDocumentAmount * numPaymentRate;
    -- Montant encaissé en monnaie du document.
    AReceivedAmountMD      := AReceivedAmount / numPaymentRate;
    -- Montant encaissé en monnaie de base.
    AReceivedAmountMB      := AReceivedAmountMD * dmtRateOfExchange / dmtBasePrice;

    -- Montant à payé en monnaie d'encaissement.
    if (AReceivedAmount > numPaymentAmount) then
      -- Le montant encaissé est supérieur au montant à payer.
      APaidAmount  := numPaymentAmount;
    else
      -- Le montant encaissé est inférieur ou égal au montant à payer. Encaissement partiel.
      APaidAmount  := AReceivedAmount;
    end if;

    -- Montant à payé en monnaie du document.
    if (AReceivedAmountMD > numDocumentAmount) then
      -- Le montant encaissé est supérieur au montant à payer.
      APaidAmountMD  := numDocumentAmount;
    else
      -- Le montant encaissé est inférieur ou égal au montant à payer. Encaissement partiel.
      APaidAmountMD  := AReceivedAmountMD;
    end if;

    -- Montant à payé en monnaie de base.
    APaidAmountMB          := APaidAmountMD * dmtRateOfExchange / dmtBasePrice;

    -- Montant rendu en monnaie d'encaissement.
    if (AReceivedAmount > APaidAmount) then
      AReturnedAmount  := AReceivedAmount - APaidAmount;
    else
      AReturnedAmount  := 0;
    end if;

    -- Montant rendu en monnaie du document.
    if (AReceivedAmountMD > APaidAmountMD) then
      AReturnedAmountMD  := AReceivedAmountMD - APaidAmountMD;
    else
      AReturnedAmountMD  := 0;
    end if;

    -- Montant rendu en monnaie de base.
    if (AReceivedAmountMB > APaidAmountMB) then
      AReturnedAmountMB  := AReceivedAmountMB - APaidAmountMB;
    else
      AReturnedAmountMB  := 0;
    end if;

    -- Montant restant à payé en monnaie d'encaissement.
    APaidBalancedAmount    := GetPaidBalancedAmount(ADocumentID, numPaymentRate, AFootPaymentID, APaidAmount);
    -- Montant restant à payé en monnaie du document.
    APaidBalancedAmountMD  := GetPaidBalancedAmountMD(ADocumentID, AFootPaymentID, APaidAmountMD);
    -- Montant restant à payé en monnaie de base.
    APaidBalancedAmountMB  := APaidBalancedAmountMD * dmtRateOfExchange / dmtBasePrice;
  end OnReceivedAmountModification;

  /**
   * Description
   *   Generation d'au moins une transaction de payment direct par document
   */
  procedure GenerateFootPayment(AFootID in DOC_FOOT.DOC_FOOT_ID%type)
  is
    cursor crPayments(AFootID in DOC_FOOT.DOC_FOOT_ID%type)
    is
      select   FOP.DOC_FOOT_PAYMENT_ID
             , FOP.ACS_FINANCIAL_CURRENCY_ID
             , FOP.FOP_EXCHANGE_RATE
             , FOP.FOP_BASE_PRICE
             , FOP.FOP_PAID_AMOUNT
             , FOP.FOP_PAID_AMOUNT_MD
             , FOP.FOP_PAID_AMOUNT_MB
             , FOP.FOP_RECEIVED_AMOUNT
             , FOP.FOP_RETURNED_AMOUNT
             , FOP.FOP_PAID_BALANCED_AMOUNT
             , FOP.FOP_DISCOUNT_AMOUNT
             , FOP.FOP_DISCOUNT_AMOUNT_MD
             , FOP.FOP_DISCOUNT_AMOUNT_MB
             , FOP.FOP_DEDUCTION_AMOUNT
             , FOP.FOP_DEDUCTION_AMOUNT_MD
             , FOP.FOP_DEDUCTION_AMOUNT_MB
          from DOC_FOOT_PAYMENT FOP
         where FOP.DOC_FOOT_ID = aFootID
      order by FOP.DOC_FOOT_PAYMENT_ID;

    numPaymentID                 number;
    gasJobTypeCatPmtID           DOC_GAUGE_STRUCTURED.ACJ_JOB_TYPE_S_CAT_PMT_ID%type;
    gasCashMultipleTransaction   DOC_GAUGE_STRUCTURED.GAS_CASH_MULTIPLE_TRANSACTION%type;
    vPcoDirectPay                PAC_PAYMENT_CONDITION.C_DIRECT_PAY%type;
    dmtFinancialCurrencyID       ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    dmtRateOfExchange            DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice                 DOC_DOCUMENT.DMT_BASE_PRICE%type;
    fopExchangeRate              DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type                   default 1;
    fopBasePrice                 DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type                      default 1;
    fopPaidAmount                DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type;
    fopPaidAmountMD              DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type;
    fopPaidAmountMB              DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type;
    fopReceivedAmount            DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type;
    fopReceivedAmountMD          DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type;
    fopReceivedAmountMB          DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type;
    fopReturnedAmount            DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type;
    fopReturnedAmountMD          DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type;
    fopReturnedAmountMB          DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type;
    fopPaidBalancedAmount        DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type;
    fopPaidBalancedAmountMD      DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    fopPaidBalancedAmountMB      DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type;
    fopDiscountAmount            DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type;
    fopDiscountAmountMD          DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type;
    fopDiscountAmountMB          DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type;
    fopDeductionAmount           DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type;
    fopDeductionAmountMD         DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type;
    fopDeductionAmountMB         DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type;
    vLastFopPaidBalancedAmountMD DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    numAmountPaymentDate         number;
    numRate                      number;
    numExchangeRate              DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type                   default 1;
    numBasePrice                 DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type                      default 1;
    numDocumentRate              number;
    numPaymentRate               number;
    numPaymentDocumentRate       number;
    blnDeleteAll                 boolean;
    blnUpdateBalance             boolean;
    docFootPaymentID             DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type;
    docFootID                    DOC_FOOT.DOC_FOOT_ID%type;
  begin
    blnDeleteAll  := false;

    select count(FOP.DOC_FOOT_PAYMENT_ID)
      into numPaymentID
      from DOC_FOOT_PAYMENT FOP
     where FOP.DOC_FOOT_ID = aFootID;

    select GAS.ACJ_JOB_TYPE_S_CAT_PMT_ID
         , nvl(GAS.GAS_CASH_MULTIPLE_TRANSACTION, 0) GAS_CASH_MULTIPLE_TRANSACTION
         , nvl(PCO.C_DIRECT_PAY, '0')
      into gasJobTypeCatPmtID
         , gasCashMultipleTransaction
         , vPcoDirectPay
      from DOC_DOCUMENT DMT
         , DOC_GAUGE_STRUCTURED GAS
         , PAC_PAYMENT_CONDITION PCO
     where DMT.DOC_DOCUMENT_ID = AFootID
       and GAS.DOC_GAUGE_ID(+) = DMT.DOC_GAUGE_ID
       and PCO.PAC_PAYMENT_CONDITION_ID(+) = DMT.PAC_PAYMENT_CONDITION_ID;

    if (numPaymentID > 0) then
      -- Vérifie que la condition de paiement autorise toujours le paiement direct. Dans le cas contraire,
      -- on supprime toutes les transactions existantes.
      if     (gasCashMultipleTransaction = 1)
         and (vPcoDirectPay = '0') then
        -- Demande de suppression de tous les paiements
        blnDeleteAll  := true;
      else
        blnUpdateBalance  := false;

        select FOP1.FOP_PAID_BALANCED_AMOUNT_MD
          into vLastFopPaidBalancedAmountMD
          from DOC_FOOT_PAYMENT FOP1
         where FOP1.DOC_FOOT_ID = aFootID
           and FOP1.DOC_FOOT_PAYMENT_ID = (select max(FOP2.DOC_FOOT_PAYMENT_ID)
                                             from DOC_FOOT_PAYMENT FOP2
                                            where FOP2.DOC_FOOT_ID = aFootID);

        -- Récupère le montant restant à payé en monnaie du document.
        GetBalanceAmountMD(AFootID, fopPaidBalancedAmountMD);

        -- Si le montant du document a changé,
        if fopPaidBalancedAmountMD <> vLastFopPaidBalancedAmountMD then
          -- on force la mise à jour du solde des paiements
          blnUpdateBalance  := true;
        end if;

        for tplPayment in crPayments(aFootID) loop
          -- Recherche du taux de change par rapport à la date du document
          if GetExchangeRate(tplPayment.ACS_FINANCIAL_CURRENCY_ID
                           , AFootID
                           , numExchangeRate
                           , numBasePrice
                           , fopExchangeRate
                           , fopBasePrice
                           , dmtFinancialCurrencyID
                           , dmtRateOfExchange
                           , dmtBasePrice
                            ) then
            -- Détermine le cours entre la monnaie d'encaissement et la monnaie de base
            numPaymentRate          := fopExchangeRate / fopBasePrice;
            -- Détermine le cours entre la monnaie de document et la monnaie de base
            numDocumentRate         := dmtRateOfExchange / dmtBasePrice;
            -- Détermine le cours entre la monnaie d'encaissement et la monnaie de document
            numPaymentDocumentRate  := numExchangeRate / numBasePrice;

            -- Si le taux de change est différent de celui du paiement
            if (0 <> greatest(abs(tplPayment.FOP_EXCHANGE_RATE - fopExchangeRate), abs(tplPayment.FOP_BASE_PRICE - fopBasePrice) ) ) then
              -- Met à jour les montants en monnaie de document, monnaie de base et monnaie d'encaissement suite à une modification du cours.
              UpdatePaymentCurrency(dmtFinancialCurrencyID, tplPayment.DOC_FOOT_PAYMENT_ID, AFootID);
            elsif blnUpdateBalance then
              ----
              -- Met à jour le solde du paiement dans toutes les monnaies en tenant compte des montants d'escompte et de
              -- déduction.
              --
              UpdateBalance(tplPayment.DOC_FOOT_PAYMENT_ID
                          , AFootID
                          , tplPayment.ACS_FINANCIAL_CURRENCY_ID
                          , dmtFinancialCurrencyID
                          , numPaymentRate
                          , numDocumentRate
                          , numPaymentDocumentRate
                          , tplPayment.FOP_PAID_AMOUNT
                          , tplPayment.FOP_PAID_AMOUNT_MD
                          , tplPayment.FOP_PAID_AMOUNT_MB
                          , tplPayment.FOP_DISCOUNT_AMOUNT
                          , tplPayment.FOP_DISCOUNT_AMOUNT_MD
                          , tplPayment.FOP_DISCOUNT_AMOUNT_MB
                          , tplPayment.FOP_DEDUCTION_AMOUNT
                          , tplPayment.FOP_DEDUCTION_AMOUNT_MD
                          , tplPayment.FOP_DEDUCTION_AMOUNT_MB
                           );
            end if;
          end if;
        end loop;

        -- On supprime les paiements dont le solde est devenu négatif
        delete      DOC_FOOT_PAYMENT
              where DOC_FOOT_ID = aFootID
                and FOP_PAID_BALANCED_AMOUNT < 0;

        -- Recherche du montant du document restant à encaisser en monnaie du document
        GetBalanceAmountMD(AFootID, fopPaidBalancedAmountMD);

        -- Si le montant est négatif, cela signifie que le montant du document a changé et qu'il est inférieur au
        -- montant déjà encaissé.
        if (fopPaidBalancedAmountMD < 0) then
          -- Demande de suppression de tous les paiements
          blnDeleteAll  := true;
          -- Demande la création du paiement par défaut
          numPaymentID  := 0;
        end if;
      end if;

      if blnDeleteAll then
        -- Supprime toutes les transactions de paiement avec solde négatif
        delete      DOC_FOOT_PAYMENT
              where DOC_FOOT_ID = aFootID;
      end if;
    end if;

    -- Aucune transaction n'existe ou que les dernières ont été supprimées,
    -- il faut créer la transaction par défaut
    if (numPaymentID = 0) then
      if     gasJobTypeCatPmtID is not null
         and (gasCashMultipleTransaction = 1)
         and (vPcoDirectPay in('2', '3') ) then
        docFootID  := AFootID;
        -- Création d'une transaction d'encaissement
        InitDataPaymentCreation(docFootPaymentID
                              , docFootID
                              , dmtFinancialCurrencyID
                              , fopExchangeRate
                              , fopBasePrice
                              , gasJobTypeCatPmtID
                              , fopReceivedAmount
                              , fopReceivedAmountMD
                              , fopReceivedAmountMB
                              , fopPaidAmount
                              , fopPaidAmountMD
                              , fopPaidAmountMB
                              , fopReturnedAmount
                              , fopReturnedAmountMD
                              , fopReturnedAmountMB
                              , fopPaidBalancedAmount
                              , fopPaidBalancedAmountMD
                              , fopPaidBalancedAmountMB
                              , fopDiscountAmount
                              , fopDiscountAmountMD
                              , fopDiscountAmountMB
                              , fopDeductionAmount
                              , fopDeductionAmountMD
                              , fopDeductionAmountMB
                               );

        -- Création de la transaction de payment comptant par défaut
        insert into DOC_FOOT_PAYMENT
                    (DOC_FOOT_PAYMENT_ID
                   , DOC_FOOT_ID
                   , ACJ_JOB_TYPE_S_CATALOGUE_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , FOP_EXCHANGE_RATE
                   , FOP_BASE_PRICE
                   , FOP_PAID_AMOUNT
                   , FOP_PAID_AMOUNT_MD
                   , FOP_PAID_AMOUNT_MB
                   , FOP_RECEIVED_AMOUNT
                   , FOP_RECEIVED_AMOUNT_MD
                   , FOP_RECEIVED_AMOUNT_MB
                   , FOP_RETURNED_AMOUNT
                   , FOP_RETURNED_AMOUNT_MD
                   , FOP_RETURNED_AMOUNT_MB
                   , FOP_PAID_BALANCED_AMOUNT
                   , FOP_PAID_BALANCED_AMOUNT_MD
                   , FOP_PAID_BALANCED_AMOUNT_MB
                   , FOP_DISCOUNT_AMOUNT
                   , FOP_DISCOUNT_AMOUNT_MD
                   , FOP_DISCOUNT_AMOUNT_MB
                   , FOP_DEDUCTION_AMOUNT
                   , FOP_DEDUCTION_AMOUNT_MD
                   , FOP_DEDUCTION_AMOUNT_MB
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval   -- DOC_FOOT_PAYMENT_ID
                   , AFootID   -- DOC_FOOT_ID
                   , gasJobTypeCatPmtID   -- ACJ_JOB_TYPE_S_CATALOGUE_ID
                   , dmtFinancialCurrencyID   -- ACS_FINANCIAL_CURRENCY_ID
                   , fopExchangeRate   -- FOP_EXCHANGE_RATE
                   , fopBasePrice   -- FOP_BASE_PRICE
                   , fopPaidAmount   -- DOC_FOOT_FOP_PAID_AMOUNT
                   , fopPaidAmountMD   -- FOP_PAID_AMOUNT_MD
                   , fopPaidAmountMB   -- FOP_PAID_AMOUNT_MB
                   , fopReceivedAmount   -- FOP_RECEIVED_AMOUNT
                   , fopReceivedAmountMD   -- FOP_RECEIVED_AMOUNT_MD
                   , fopReceivedAmountMB   -- FOP_RECEIVED_AMOUNT_MB
                   , fopReturnedAmount   -- FOP_RETURNED_AMOUNT
                   , fopReturnedAmountMD   -- FOP_RETURNED_AMOUNT_MD
                   , fopReturnedAmountMB   -- FOP_RETURNED_AMOUNT_MB
                   , fopPaidBalancedAmount   -- FOP_PAID_BALANCED_AMOUNT
                   , fopPaidBalancedAmountMD   -- FOP_PAID_BALANCED_AMOUNT_MD
                   , fopPaidBalancedAmountMB   -- FOP_PAID_BALANCED_AMOUNT_MB
                   , fopDiscountAmount   -- FOP_DISCOUNT_AMOUNT
                   , fopDiscountAmountMD   -- FOP_DISCOUNT_AMOUNT_MD
                   , fopDiscountAmountMB   -- FOP_DISCOUNT_AMOUNT_MB
                   , fopDeductionAmount   -- FOP_DEDUCTION_AMOUNT
                   , fopDeductionAmountMD   -- FOP_DEDUCTION_AMOUNT_MD
                   , fopDeductionAmountMB   -- FOP_DEDUCTION_AMOUNT_MB
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    );
      end if;
    end if;
  end GenerateFootPayment;

  /**
   * procedure UpdatePayment
   * Description
   *   Met à jour les montants en monnaie de document et monnaie de base, ainsi
   *   que le solde et les montants en monnaie d'encaissement si aUpdateBalance
   *   est à True.
   */
  procedure UpdatePayment(
    aFootId                 DOC_FOOT_PAYMENT.DOC_FOOT_ID%type
  , aFootPaymentId          DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , aDmtFinancialCurrencyID DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDmtExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , aDmtBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , aFopFinancialCurrencyID DOC_FOOT_PAYMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aFopExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , aFopBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , aFopPaidAmount          DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , aFopReceivedAmount      DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type
  , aFopReturnedAmount      DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , aFopPaidBalancedAmount  DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type
  , aUpdateBalance          boolean
  )
  is
    vFopPaidAmount           DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type;
    vFopPaidAmountMD         DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type;
    vFopPaidAmountMB         DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type;
--    vFopReceivedAmount       DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type;
    vFopReceivedAmountMD     DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type;
    vFopReceivedAmountMB     DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type;
    vFopReturnedAmount       DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type;
    vFopReturnedAmountMD     DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type;
    vFopReturnedAmountMB     DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type;
    vFopPaidBalancedAmount   DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type;
    vFopPaidBalancedAmountMD DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    vFopPaidBalancedAmountMB DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type;
    vPaymentRate             number;
  begin
    -- Recherche du cours entre la monnaie d'encaissement et la monnaie du document (cours de calcul)
    vPaymentRate        := GetPaymentRate(aFopFinancialCurrencyID, aDmtFinancialCurrencyID, aFopExchangeRate, aFopBasePrice);
    vFopPaidAmount      := aFopPaidAmount;
    vFopReturnedAmount  := aFopReturnedAmount;

    -- Mise à jour du solde
    if aUpdateBalance then
      -- Montant restant à payer en monnaie d'encaissement.
      vFopPaidBalancedAmount  := GetPaidBalancedAmount(aFootId, vPaymentRate, aFootPaymentId, vFopPaidAmount);

      -- S'il existe un montant rendu alors que le solde n'est pas à 0,
      if     (vFopPaidBalancedAmount > 0)
         and (vFopReturnedAmount > 0) then
        -- le montant rendu est utilisé pour payer le solde
        if vFopPaidBalancedAmount > vFopReturnedAmount then
          vFopPaidAmount          := vFopPaidAmount + vFopReturnedAmount;
          vFopPaidBalancedAmount  := vFopPaidBalancedAmount - vFopReturnedAmount;
          vFopReturnedAmount      := 0;
        else
          vFopPaidAmount          := vFopPaidAmount + vFopPaidBalancedAmount;
          vFopReturnedAmount      := vFopReturnedAmount - vFopPaidBalancedAmount;
          vFopPaidBalancedAmount  := 0;
        end if;
      end if;
    else
      -- Montant restant à payer en monnaie d'encaissement.
      vFopPaidBalancedAmount  := aFopPaidBalancedAmount;
    end if;

    -- Si on a pas de montant solde, on ne modifie rien
    if (vFopPaidBalancedAmount > 0) then
      -- Montant à payer en monnaie du document.
      vFopPaidAmountMD          := vFopPaidAmount / vPaymentRate;
      -- Montant à payer en monnaie de base.
      vFopPaidAmountMB          := vFopPaidAmountMD * aDmtExchangeRate / aDmtBasePrice;
      -- Montant encaissé en monnaie du document.
      vFopReceivedAmountMD      := aFopReceivedAmount / vPaymentRate;
      -- Montant encaissé en monnaie de base.
      vFopReceivedAmountMB      := vFopReceivedAmountMD * aDmtExchangeRate / aDmtBasePrice;

      -- Montant rendu en monnaie du document.
      if (vFopReceivedAmountMD > vFopPaidAmountMD) then
        vFopReturnedAmountMD  := vFopReceivedAmountMD - vFopPaidAmountMD;
      else
        vFopReturnedAmountMD  := 0;
      end if;

      -- Montant rendu en monnaie de base.
      if (vFopReceivedAmountMB > vFopPaidAmountMB) then
        vFopReturnedAmountMB  := vFopReceivedAmountMB - vFopPaidAmountMB;
      else
        vFopReturnedAmountMB  := 0;
      end if;

      -- Montant restant à payer en monnaie du document.
      if aUpdateBalance then
        vFopPaidBalancedAmountMD  := GetPaidBalancedAmountMD(aFootId, aFootPaymentId, vFopPaidAmountMD);
      else
        vFopPaidBalancedAmountMD  := vFopPaidBalancedAmount / vPaymentRate;
      end if;

      -- Montant restant à payer en monnaie de base.
      vFopPaidBalancedAmountMB  := vFopPaidBalancedAmountMD * aDmtExchangeRate / aDmtBasePrice;
    end if;

    update DOC_FOOT_PAYMENT
       set FOP_EXCHANGE_RATE = aFopExchangeRate
         , FOP_BASE_PRICE = aFopBasePrice
         , FOP_PAID_AMOUNT = nvl(vFopPaidAmount, FOP_PAID_AMOUNT)
         , FOP_PAID_AMOUNT_MD = nvl(vFopPaidAmountMD, FOP_PAID_AMOUNT_MD)
         , FOP_PAID_AMOUNT_MB = nvl(vFopPaidAmountMB, FOP_PAID_AMOUNT_MB)
         , FOP_RECEIVED_AMOUNT_MD = nvl(vFopReceivedAmountMD, FOP_RECEIVED_AMOUNT_MD)
         , FOP_RECEIVED_AMOUNT_MB = nvl(vFopReceivedAmountMB, FOP_RECEIVED_AMOUNT_MB)
         , FOP_RETURNED_AMOUNT = nvl(vFopReturnedAmount, FOP_RETURNED_AMOUNT)
         , FOP_RETURNED_AMOUNT_MD = nvl(vFopReturnedAmountMD, FOP_RETURNED_AMOUNT_MD)
         , FOP_RETURNED_AMOUNT_MB = nvl(vFopReturnedAmountMB, FOP_RETURNED_AMOUNT_MB)
         , FOP_PAID_BALANCED_AMOUNT = nvl(vFopPaidBalancedAmount, FOP_PAID_BALANCED_AMOUNT)
         , FOP_PAID_BALANCED_AMOUNT_MD = nvl(vFopPaidBalancedAmountMD, FOP_PAID_BALANCED_AMOUNT_MD)
         , FOP_PAID_BALANCED_AMOUNT_MB = nvl(vFopPaidBalancedAmountMB, FOP_PAID_BALANCED_AMOUNT_MB)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_FOOT_PAYMENT_ID = aFootPaymentId;
  end UpdatePayment;

  /**
   * procedure UpdateBalance
   * Description
   *   Met à jour le solde du paiement dans toutes les monnaies.
   */
  procedure UpdateBalance(
    aFootId                 DOC_FOOT_PAYMENT.DOC_FOOT_ID%type
  , aFootPaymentId          DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , aDmtFinancialCurrencyID DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDmtExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , aDmtBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , aFopFinancialCurrencyID DOC_FOOT_PAYMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aFopExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , aFopBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , aFopPaidAmount          DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  )
  is
    vFopPaidBalancedAmount   DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type;
    vFopPaidBalancedAmountMD DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    vFopPaidBalancedAmountMB DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type;
    vPaymentRate             number;
  begin
    -- Recherche du cours entre la monnaie d'encaissement et la monnaie du document (cours de calcul)
    vPaymentRate              := GetPaymentRate(aFopFinancialCurrencyID, aDmtFinancialCurrencyID, aFopExchangeRate, aFopBasePrice);
    -- Montant restant à payer en monnaie d'encaissement.
    vFopPaidBalancedAmount    := GetPaidBalancedAmount(aFootId, vPaymentRate, aFootPaymentId, aFopPaidAmount);
    -- Montant restant à payer en monnaie du document.
    vFopPaidBalancedAmountMD  := GetPaidBalancedAmountMD(aFootId, aFootPaymentId, aFopPaidAmount / vPaymentRate);
    -- Montant restant à payer en monnaie de base.
    vFopPaidBalancedAmountMB  := vFopPaidBalancedAmountMD * aDmtExchangeRate / aDmtBasePrice;

    update DOC_FOOT_PAYMENT
       set FOP_PAID_BALANCED_AMOUNT = vFopPaidBalancedAmount
         , FOP_PAID_BALANCED_AMOUNT_MD = vFopPaidBalancedAmountMD
         , FOP_PAID_BALANCED_AMOUNT_MB = vFopPaidBalancedAmountMB
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_FOOT_PAYMENT_ID = aFootPaymentId;
  end UpdateBalance;

  /**
  * procedure CtrlFootPayment
  * Description
  *   Contrôle de l'encaissement selon le code "Encaissement direct"
  *      de la condition de paiement du document
  */
  procedure CtrlFootPayment(aFootID in DOC_FOOT.DOC_FOOT_ID%type, aDirectPay in PAC_PAYMENT_CONDITION.C_DIRECT_PAY%type, aErrorCode out varchar2)
  is
    vFOP_PAID_AMOUNT_MB DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type;
    vPAD_DATE_AMOUNT_B  DOC_PAYMENT_DATE.PAD_DATE_AMOUNT_B%type;
  begin
    aErrorCode  := null;

    -- 0 - Non autorisé
    -- 1 - Autorisé (partiel/total)
    -- 2 - Obligatoire (partiel/total)
    -- 3 - Obligatoire (total)

    -- Une transaction d'encaissement au moins doit être saisie
    if aDirectPay in('2', '3') then
      -- Code d'erreur 126 à la confirmation : Encaissement - transaction manquante
      select case
               when count(FOP.DOC_FOOT_PAYMENT_ID) = 0 then '126'
               else null
             end
        into aErrorCode
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = aFootID;
    end if;

    -- 3 - Obligatoire (total)
    -- La somme des transactions d'encaissement doit correspondre au total à encaisser.
    if     (aErrorCode is null)
       and (aDirectPay = '3') then
      --
      -- Rechercher le montant total du document. Recherche la plus petit échéance de la première tranche.
      begin
        select PAD1.PAD_DATE_AMOUNT_B
          into vPAD_DATE_AMOUNT_B
          from (select   PAD.PAD_DATE_AMOUNT_B
                    from DOC_PAYMENT_DATE PAD
                   where PAD.DOC_FOOT_ID = aFootID
                order by PAD.PAD_BAND_NUMBER
                       , PAD.PAD_PAYMENT_DATE
                       , PAD.PAD_DISCOUNT_AMOUNT desc) PAD1
         where rownum = 1;
      exception
        when no_data_found then
          vPAD_DATE_AMOUNT_B  := 0;
      end;

      -- Encaissement - montant total payé + montant total escompte + montant total déduction
      select nvl(sum(nvl(FOP.FOP_PAID_AMOUNT_MB, 0) + nvl(FOP.FOP_DISCOUNT_AMOUNT_MB, 0) + nvl(FOP.FOP_DEDUCTION_AMOUNT_MB, 0) ), 0)
        into vFOP_PAID_AMOUNT_MB
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = aFootID;

      -- Code d'erreur 127 à la confirmation : Encaissement - somme des transactions incorrecte
      if vPAD_DATE_AMOUNT_B <> vFOP_PAID_AMOUNT_MB then
        aErrorCode  := '127';
      end if;
    end if;
  end CtrlFootPayment;

  /**
  * function CtrlFootPayment
  * Description
  *   Contrôle de l'encaissement selon le code "Encaissement direct"
  *      de la condition de paiement du document
  */
  function CtrlFootPayment(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar2
  is
    vErrorCode    varchar2(10);
    vC_DIRECT_PAY PAC_PAYMENT_CONDITION.C_DIRECT_PAY%type;
  begin
    -- Rechercher la valeur du code "Encaissement direct" de la condition de
    -- paiement du document courant
    select nvl(PCO.C_DIRECT_PAY, '0') C_DIRECT_PAY
      into vC_DIRECT_PAY
      from DOC_DOCUMENT DMT
         , PAC_PAYMENT_CONDITION PCO
     where DMT.DOC_DOCUMENT_ID = aDocumentID
       and DMT.PAC_PAYMENT_CONDITION_ID = PCO.PAC_PAYMENT_CONDITION_ID(+);

    CtrlFootPayment(aFootID => aDocumentID, aDirectPay => vC_DIRECT_PAY, aErrorCode => vErrorCode);
    return vErrorCode;
  end CtrlFootPayment;

  /**
  * procedure GetDocumentAmounts
  * Description
  *   Méthode de recherche des montants échu du document en monnaie du docment. Recherche la plus petit échéance de
  *   la première tranche.
  */
  procedure GetDocumentAmounts(
    ADocumentID         in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , APaymentAmountMD    out    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT%type
  , ANetPaymentAmountMD out    DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT%type
  , APaymentAmountMB    out    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT_B%type
  , ANetPaymentAmountMB out    DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT_B%type
  )
  is
  begin
    begin
      select PAD1.PAD_DATE_AMOUNT
           , PAD1.PAD_NET_DATE_AMOUNT
           , PAD1.PAD_DATE_AMOUNT_B
           , PAD1.PAD_NET_DATE_AMOUNT_B
        into APaymentAmountMD
           , ANetPaymentAmountMD
           , APaymentAmountMB
           , ANetPaymentAmountMB
        from (select   PAD.PAD_DATE_AMOUNT
                     , PAD.PAD_NET_DATE_AMOUNT
                     , PAD.PAD_DATE_AMOUNT_B
                     , PAD.PAD_NET_DATE_AMOUNT_B
                  from DOC_PAYMENT_DATE PAD
                 where PAD.DOC_FOOT_ID = ADocumentID
              order by PAD.PAD_BAND_NUMBER
                     , PAD.PAD_PAYMENT_DATE
                     , PAD.PAD_DISCOUNT_AMOUNT desc) PAD1
       where rownum = 1;
    exception
      when no_data_found then
        APaymentAmountMD     := null;
        ANetPaymentAmountMD  := null;
        APaymentAmountMB     := null;
        ANetPaymentAmountMB  := null;
    end;
  end GetDocumentAmounts;

  /**
  * Description
  *   Méthode de recherche des montants déjà payé en monnaie d'encaissement. Tiens compte des éventuelles escomptes et
  *   déductions. Retourne le montant déjà payé en monnaie d'encaissement en se basant sur les paiements précédant, le
  *   paiement AFootPaymentID ou sur tous les paiements si AFootPaymentID est null ou égal à 0.
  */
  procedure GetTotalPaidAmount(
    ADocumentID      in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , ATotalPaidAmount out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , APaymentRate     in     DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type default 1
  , AFootPaymentID   in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type default 0
  , APaidAmount      in     DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type default 0
  , ADiscountAmount  in     DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type default 0
  , ADeductionAmount in     DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type default 0
  )
  is
    fopPaidAmountMB DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type;
  begin
    -- J'utilise la somme des montants en monnaie de base pour obtenir le montant déjà payé. Pour ensuite
    -- le convertir en monnaie d'encaissement.
    if nvl(AFootPaymentID, 0) <> 0 then
      select nvl(sum(nvl(FOP.FOP_PAID_AMOUNT_MB, 0) + nvl(FOP.FOP_DISCOUNT_AMOUNT_MB, 0) + nvl(FOP.FOP_DEDUCTION_AMOUNT_MB, 0) ), 0)
        into fopPaidAmountMB
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID
         and FOP.DOC_FOOT_PAYMENT_ID < AFootPaymentID;
    else
      select nvl(sum(nvl(FOP.FOP_PAID_AMOUNT_MB, 0) + nvl(FOP.FOP_DISCOUNT_AMOUNT_MB, 0) + nvl(FOP.FOP_DEDUCTION_AMOUNT_MB, 0) ), 0)
        into fopPaidAmountMB
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID;
    end if;

    ATotalPaidAmount  := (fopPaidAmountMB / APaymentRate) +(APaidAmount + ADiscountAmount + ADeductionAmount);
  end GetTotalPaidAmount;

  /**
  * Description
  *   Méthode de recherche des montants déjà payé en monnaie document. Tiens compte des éventuelles escomptes et
  *   déductions. Retourne le montant déjà payé en monnaie document en se basant sur les paiements précédant, le paiement
  *   AFootPaymentID ou sur tous les paiements si AFootPaymentID est null ou égal à 0.
  */
  procedure GetTotalPaidAmountMD(
    ADocumentID        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , ATotalPaidAmountMD out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type
  , AFootPaymentID     in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type default 0
  , APaidAmountMD      in     DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type default 0
  , ADiscountAmountMD  in     DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type default 0
  , ADeductionAmountMD in     DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type default 0
  )
  is
    fopPaidAmountMD DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type;
  begin
    if nvl(AFootPaymentID, 0) <> 0 then
      select nvl(sum(nvl(FOP.FOP_PAID_AMOUNT_MD, 0) + nvl(FOP.FOP_DISCOUNT_AMOUNT_MD, 0) + nvl(FOP.FOP_DEDUCTION_AMOUNT_MD, 0) ), 0)
        into fopPaidAmountMD
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID
         and FOP.DOC_FOOT_PAYMENT_ID < AFootPaymentID;
    else
      select nvl(sum(nvl(FOP.FOP_PAID_AMOUNT_MD, 0) + nvl(FOP.FOP_DISCOUNT_AMOUNT_MD, 0) + nvl(FOP.FOP_DEDUCTION_AMOUNT_MD, 0) ), 0)
        into fopPaidAmountMD
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID;
    end if;

    ATotalPaidAmountMD  := fopPaidAmountMD +(APaidAmountMD + ADiscountAmountMD + ADeductionAmountMD);
  end GetTotalPaidAmountMD;

  /**
  * Description
  *   Méthode de recherche des montants déjà payé en monnaie de base. Tiens compte des éventuelles escomptes et
  *   déductions. Retourne le montant déjà payé en monnaie de base en se basant sur les paiements précédant le paiement
  *   AFootPaymentID ou sur tous les paiements si AFootPaymentID est null ou égal à 0.
  */
  procedure GetTotalPaidAmountMB(
    ADocumentID        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , ATotalPaidAmountMB out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , AFootPaymentID     in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type default 0
  , APaidAmountMB      in     DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type default 0
  , ADiscountAmountMB  in     DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type default 0
  , ADeductionAmountMB in     DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type default 0
  )
  is
    fopPaidAmountMB DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type;
  begin
    if nvl(AFootPaymentID, 0) <> 0 then
      select nvl(sum(nvl(FOP.FOP_PAID_AMOUNT_MB, 0) + nvl(FOP.FOP_DISCOUNT_AMOUNT_MB, 0) + nvl(FOP.FOP_DEDUCTION_AMOUNT_MB, 0) ), 0)
        into fopPaidAmountMB
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID
         and FOP.DOC_FOOT_PAYMENT_ID < AFootPaymentID;
    else
      select nvl(sum(nvl(FOP.FOP_PAID_AMOUNT_MB, 0) + nvl(FOP.FOP_DISCOUNT_AMOUNT_MB, 0) + nvl(FOP.FOP_DEDUCTION_AMOUNT_MB, 0) ), 0)
        into fopPaidAmountMB
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID;
    end if;

    ATotalPaidAmountMB  := fopPaidAmountMB +(APaidAmountMB + ADiscountAmountMB + ADeductionAmountMB);
  end GetTotalPaidAmountMB;

  /**
  * Description
  *   Méthode de recherche des montants déduction en monnaie de base. Retourne le montant déduction en monnaie de
  *   base en se basant sur les paiements précédant le paiement AFootPaymentID ou sur tous les paiements si
  *   AFootPaymentID est null ou égal à 0.
  */
  procedure GetTotalDeductionAmountMB(
    ADocumentID             in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , ATotalDeductionAmountMB out    DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type
  , AFootPaymentID          in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type default 0
  , ADeductionAmountMB      in     DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type default 0
  )
  is
    fopDeductionAmountMB DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type;
  begin
    if nvl(AFootPaymentID, 0) <> 0 then
      select nvl(sum(nvl(FOP.FOP_DEDUCTION_AMOUNT_MB, 0) ), 0)
        into fopDeductionAmountMB
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID
         and FOP.DOC_FOOT_PAYMENT_ID < AFootPaymentID;
    else
      select nvl(sum(nvl(FOP.FOP_DEDUCTION_AMOUNT_MB, 0) ), 0)
        into fopDeductionAmountMB
        from DOC_FOOT_PAYMENT FOP
       where FOP.DOC_FOOT_ID = ADocumentID;
    end if;

    ATotalDeductionAmountMB  := fopDeductionAmountMB + ADeductionAmountMB;
  end GetTotalDeductionAmountMB;

  /**
  * Description
  *   Méthode de recherche du montant solde à encaisser en monnaie d'encaissement.
  *   Retourne le montant à encaisser en monnaie d'encaissement en se basant sur les montants
  *   de l'échéances en monnaie de base convertit en monnaie d'encaissement et les paiements précédant le paiement
  *   AFootPaymentID ou sur tous les paiements si AFootPaymentID est null ou égal à 0.
  */
  procedure GetBalanceAmount(
    ADocumentID      in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , ABalanceAmount   out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , APaymentRate     in     DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type default 1
  , AFootPaymentID   in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type default 0
  , APaidAmount      in     DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type default 0
  , ADiscountAmount  in     DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type default 0
  , ADeductionAmount in     DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type default 0
  )
  is
    totalPaidAmount           DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type;
    docPaymentDateAmountMD    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT%type;
    docPaymentDateNetAmountMD DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT%type;
    docPaymentDateAmountMB    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT_B%type;
    docPaymentDateNetAmountMB DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT_B%type;
  begin
    -- Recherche des montants échu du document en monnaie de base. Recherche la plus petit échéance de
    -- la première tranche.
    GetDocumentAmounts(ADocumentID, docPaymentDateAmountMD, docPaymentDateNetAmountMD, docPaymentDateAmountMB, docPaymentDateNetAmountMB);

    if docPaymentDateAmountMB is not null then
      -- Recherche des montants déjà payé en monnaie d'encaissement. Tiens compte des éventuelles escomptes et déductions.
      GetTotalPaidAmount(ADocumentID, totalPaidAmount, APaymentRate, AFootPaymentID, APaidAmount, ADiscountAmount, ADeductionAmount);
      ----
      -- Détermine le montant solde avec le calcul suivant :
      --
      -- MB           : Monnaie de base
      -- non spécifié : Monnaie d'encaissement
      --
      -- Montant solde = (Montant échu MB / Cours d'encaissement) - Montant déjà payé
      --
      ABalanceAmount  := (docPaymentDateAmountMB / APaymentRate) - totalPaidAmount;
    else
      ABalanceAmount  := null;
    end if;
  end GetBalanceAmount;

  /**
  * Description
  *   Méthode de recherche du montant solde à encaisser en monnaie du document.
  *   Retourne le montant à encaisser en monnaie du document en se basant sur
  *   les échéances et les paiements précédant le paiement AFootPaymentID ou sur
  *   tous les paiements si AFootPaymentID est null ou égal à 0.
  */
  procedure GetBalanceAmountMD(
    ADocumentID        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , ABalanceAmountMD   out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type
  , AFootPaymentID     in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type default 0
  , APaidAmountMD      in     DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type default 0
  , ADiscountAmountMD  in     DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type default 0
  , ADeductionAmountMD in     DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type default 0
  )
  is
    totalPaidAmountMD         DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type;
    docPaymentDateAmountMD    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT%type;
    docPaymentDateNetAmountMD DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT%type;
    docPaymentDateAmountMB    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT_B%type;
    docPaymentDateNetAmountMB DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT_B%type;
  begin
    -- Recherche des montants échu du document en monnaie du docment. Recherche la plus petit échéance de
    -- la première tranche.
    GetDocumentAmounts(ADocumentID, docPaymentDateAmountMD, docPaymentDateNetAmountMD, docPaymentDateAmountMB, docPaymentDateNetAmountMB);

    if docPaymentDateAmountMD is not null then
      -- Recherche des montants déjà payé en monnaie du document. Tiens compte des éventuelles escomptes et déductions.
      GetTotalPaidAmountMD(ADocumentID, totalPaidAmountMD, AFootPaymentID, APaidAmountMD, ADiscountAmountMD, ADeductionAmountMD);
      ----
      -- Détermine le montant solde avec le calcul suivant :
      --
      -- MD : Monnaie document
      --
      -- Montant solde MD = Montant échu MD - Montant déjà payé MD
      --
      ABalanceAmountMD  := docPaymentDateAmountMD - totalPaidAmountMD;
    else
      ABalanceAmountMD  := null;
    end if;
  end GetBalanceAmountMD;

  /**
  * Description
  *   Méthode de recherche du montant solde à encaisser en monnaie de base.
  *   Retourne le montant à encaisser en monnaie de base en se basant sur
  *   les échéances et les paiements précédant le paiement AFootPaymentID ou sur
  *   tous les paiements si AFootPaymentID est null ou égal à 0.
  */
  procedure GetBalanceAmountMB(
    ADocumentID        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , ABalanceAmountMB   out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , AFootPaymentID     in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type default 0
  , APaidAmountMB      in     DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type default 0
  , ADiscountAmountMB  in     DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type default 0
  , ADeductionAmountMB in     DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type default 0
  )
  is
    totalPaidAmountMB         DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type;
    docPaymentDateAmountMD    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT%type;
    docPaymentDateNetAmountMD DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT%type;
    docPaymentDateAmountMB    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT_B%type;
    docPaymentDateNetAmountMB DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT_B%type;
  begin
    -- Recherche des montants échu du document en monnaie de base. Recherche la plus petit échéance de
    -- la première tranche.
    GetDocumentAmounts(ADocumentID, docPaymentDateAmountMD, docPaymentDateNetAmountMD, docPaymentDateAmountMB, docPaymentDateNetAmountMB);

    if docPaymentDateAmountMB is not null then
      -- Recherche des montants déjà payé en monnaie de base document. Tiens compte des éventuelles escomptes et déductions.
      GetTotalPaidAmountMB(ADocumentID, totalPaidAmountMB, AFootPaymentID, APaidAmountMB, ADiscountAmountMB, ADeductionAmountMB);
      ----
      -- Détermine le montant solde avec le calcul suivant :
      --
      -- MB : Monnaie de base
      --
      -- Montant solde MB = Montant échu MB - Montant déjà payé MB
      --
      ABalanceAmountMB  := docPaymentDateAmountMB - totalPaidAmountMB;
    else
      ABalanceAmountMB  := null;
    end if;
  end GetBalanceAmountMB;

  /**
  * Description
  *   Méthode de modification du montant à encaisser (reçu) en tenant compte des montants d'escompte et de déduction
  */
  procedure OnReceivedAmountModification(
    AReceivedAmount       in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type
  , AFootPaymentID        in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , APaymentCurrencyID    in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ADocumentID           in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , AExchangeRate         in out DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ABasePrice            in out DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , AReceivedAmountMD     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type
  , AReceivedAmountMB     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type
  , APaidAmount           out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , APaidAmountMD         out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type
  , APaidAmountMB         out    DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , AReturnedAmount       out    DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , AReturnedAmountMD     out    DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type
  , AReturnedAmountMB     out    DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type
  , APaidBalancedAmount   out    DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type
  , APaidBalancedAmountMD out    DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type
  , APaidBalancedAmountMB out    DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type
  , ADiscountAmount       in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type
  , ADiscountAmountMD     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type
  , ADiscountAmountMB     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type
  , ADeductionAmount      in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type
  , ADeductionAmountMD    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type
  , ADeductionAmountMB    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type
  )
  is
    dmtFinancialCurrencyID  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    calcExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    calcBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    fopExchangeRate         DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    fopBasePrice            DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    dmtRateOfExchange       DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice            DOC_DOCUMENT.DMT_BASE_PRICE%type;
    fopPaidBalancedAmount   DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type;
    fopPaidBalancedAmountMD DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    fopPaidBalancedAmountMB DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type;
    numDocumentRate         number;
    numPaymentRate          number;
    numPaymentDocumentRate  number;
    lReceivedNetAmountMD    number;
    lReceivedNetAmountMB    number;
  begin
    -- Recherche les cours utilisés.
    if GetExchangeRate(APaymentCurrencyID
                     , ADocumentID
                     , calcExchangeRate
                     , calcBasePrice
                     , fopExchangeRate
                     , fopBasePrice
                     , dmtFinancialCurrencyID
                     , dmtRateOfExchange
                     , dmtBasePrice
                      ) then
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de base
      numPaymentRate          := fopExchangeRate / fopBasePrice;
      -- Détermine le cours entre la monnaie de document et la monnaie de base
      numDocumentRate         := dmtRateOfExchange / dmtBasePrice;
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de document
      numPaymentDocumentRate  := calcExchangeRate / calcBasePrice;

      ----
      -- Détermine les montants reçus dans les autres monnaies que la monnaie d'encaissement. Une valeur nulle indique
      -- une demande de recalcul.
      --
      if AReceivedAmount = 0 then
        AReceivedAmount  := null;
      end if;

      if AReceivedAmountMD = 0 then
        AReceivedAmountMD  := null;
      end if;

      if AReceivedAmountMB = 0 then
        AReceivedAmountMB  := null;
      end if;

      if aReceivedAmount = GetDocumentAmount(ADocumentID) then
        GetDocumentAmounts(ADocumentID, AReceivedAmountMD, lReceivedNetAmountMD, AReceivedAmountMB, lReceivedNetAmountMB);
      else
        GetConvertedAmounts(APaymentCurrencyID
                          , dmtFinancialCurrencyID
                          , null
                          , numPaymentRate
                          , numDocumentRate
                          , numPaymentDocumentRate
                          , AReceivedAmount
                          , AReceivedAmountMD
                          , AReceivedAmountMB
                           );
      end if;

      ----
      -- Détermine les montants d'escompte et de déduction dans les autres monnaies que la monnaie d'encaissement.
      -- Une valeur nulle indique une demande de recalcul.
      --
      GetConvertedAmounts(APaymentCurrencyID
                        , dmtFinancialCurrencyID
                        , null
                        , numPaymentRate
                        , numDocumentRate
                        , numPaymentDocumentRate
                        , ADiscountAmount
                        , ADiscountAmountMD
                        , ADiscountAmountMB
                         );
      GetConvertedAmounts(APaymentCurrencyID
                        , dmtFinancialCurrencyID
                        , null
                        , numPaymentRate
                        , numDocumentRate
                        , numPaymentDocumentRate
                        , ADeductionAmount
                        , ADeductionAmountMD
                        , ADeductionAmountMB
                         );
      ----
      -- Détermine les montants restant a payer dans les différentes monnaies en excluant le montant
      -- payé sur l'encaissement courant. Le montant payé sur l'encaissement en cours de saisie est
      -- calculé plus bas.
      --
      -- Montant restant à payé en monnaie du document.
      GetBalanceAmountMD(ADocumentID   -- Document courant
                       , fopPaidBalancedAmountMD   -- Montant solde obtenu en monnaie du document
                       , AFootPaymentID   -- Encaissement en cours de saisie
                       , 0   -- Montant payé sur l'encaissement en cours de saisie (à déterminer plus tard)
                       , ADiscountAmountMD
                       , ADeductionAmountMD
                        );
      -- Montant restant à payé en monnaie de base.
      GetBalanceAmountMB(ADocumentID   -- Document courant
                       , fopPaidBalancedAmountMB   -- Montant solde obtenu en monnaie de base
                       , AFootPaymentID   -- Encaissement en cours de saisie
                       , 0   -- Montant payé sur l'encaissement en cours de saisie (à déterminer plus tard)
                       , ADiscountAmountMB
                       , ADeductionAmountMB
                        );
      -- Montant restant à payé en monnaie d'encaissement. Il doit toujours se calculer à partir
      -- des montants en monnaie de base ou en monnaie de document.
      --
      fopPaidBalancedAmount   := null;   -- Indique une demande de recalcul.
      GetConvertedAmounts(APaymentCurrencyID
                        , dmtFinancialCurrencyID
                        , null
                        , numPaymentRate
                        , numDocumentRate
                        , numPaymentDocumentRate
                        , fopPaidBalancedAmount
                        , fopPaidBalancedAmountMD
                        , fopPaidBalancedAmountMB
                         );

      -- Montant à payé en monnaie d'encaissement.
      if (AReceivedAmount > fopPaidBalancedAmount) then
        -- Le montant encaissé est supérieur au montant à payer.
        APaidAmount  := fopPaidBalancedAmount;
      else
        -- Le montant encaissé est inférieur ou égal au montant à payer. Encaissement partiel.
        APaidAmount  := AReceivedAmount;
      end if;

      -- Montant à payé en monnaie du document.
      if (AReceivedAmountMD > fopPaidBalancedAmountMD) then
        -- Le montant encaissé est supérieur au montant à payer.
        APaidAmountMD  := fopPaidBalancedAmountMD;
      else
        -- Le montant encaissé est inférieur ou égal au montant à payer. Encaissement partiel.
        APaidAmountMD  := AReceivedAmountMD;
      end if;

      -- Montant à payé en monnaie de base.
      if (AReceivedAmountMB > fopPaidBalancedAmountMB) then
        -- Le montant encaissé est supérieur au montant à payer.
        APaidAmountMB  := fopPaidBalancedAmountMB;
      else
        -- Le montant encaissé est inférieur ou égal au montant à payer. Encaissement partiel.
        APaidAmountMB  := AReceivedAmountMB;
      end if;

      -- Montant rendu en monnaie d'encaissement.
      if (AReceivedAmount > APaidAmount) then
        AReturnedAmount  := AReceivedAmount - APaidAmount;
      else
        AReturnedAmount  := 0;
      end if;

      -- Montant rendu en monnaie du document.
      if (AReceivedAmountMD > APaidAmountMD) then
        AReturnedAmountMD  := AReceivedAmountMD - APaidAmountMD;
      else
        AReturnedAmountMD  := 0;
      end if;

      -- Montant rendu en monnaie de base.
      if (AReceivedAmountMB > APaidAmountMB) then
        AReturnedAmountMB  := AReceivedAmountMB - APaidAmountMB;
      else
        AReturnedAmountMB  := 0;
      end if;

      -- Montant restant à payer en monnaie d'encaissement.
      APaidBalancedAmount     := fopPaidBalancedAmount - APaidAmount;
      -- Montant restant à payer en monnaie du document.
      APaidBalancedAmountMD   := fopPaidBalancedAmountMD - APaidAmountMD;
      -- Montant restant à payer en monnaie de base.
      APaidBalancedAmountMB   := fopPaidBalancedAmountMB - APaidAmountMB;
    end if;
  end OnReceivedAmountModification;

  /**
  * Description
  *   Méthode de modification de la monnaie d'encaissement
  */
  procedure OnPaymentCurrencyModification(
    APaymentCurrencyID    in out ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , AFootPaymentID        in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , ADocumentID           in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , AExchangeRate         in out DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ABasePrice            in out DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , AReceivedAmount       in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type
  , AReceivedAmountMD     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type
  , AReceivedAmountMB     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type
  , APaidAmount           in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , APaidAmountMD         in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type
  , APaidAmountMB         in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , AReturnedAmount       in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , AReturnedAmountMD     in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type
  , AReturnedAmountMB     in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type
  , APaidBalancedAmount   in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type
  , APaidBalancedAmountMD in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type
  , APaidBalancedAmountMB in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type
  , ADiscountAmount       in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type
  , ADiscountAmountMD     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type
  , ADiscountAmountMB     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type
  , ADeductionAmount      in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type
  , ADeductionAmountMD    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type
  , ADeductionAmountMB    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type
  )
  is
    dmtFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    calcExchangeRate       DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    calcBasePrice          DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    dmtRateOfExchange      DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice           DOC_DOCUMENT.DMT_BASE_PRICE%type;
  begin
    -- Recherche le cours entre la monnaie d'encaissement et la monnaie de base.
    if GetExchangeRate(APaymentCurrencyID
                     , ADocumentID
                     , calcExchangeRate
                     , calcBasePrice
                     , AExchangeRate
                     , ABasePrice
                     , dmtFinancialCurrencyID
                     , dmtRateOfExchange
                     , dmtBasePrice
                      ) then
      -- Demande le recalcul de tous les montants en monnaie d'encaissement sur la base des montants des autres monnaies.
      AReceivedAmount   := null;
      ADiscountAmount   := null;
      ADeductionAmount  := null;
      -- Modification du montant à encaisser (reçu)
      OnReceivedAmountModification(AReceivedAmount
                                 , AFootPaymentID
                                 , APaymentCurrencyID
                                 , ADocumentID
                                 , AExchangeRate
                                 , ABasePrice
                                 , AReceivedAmountMD
                                 , AReceivedAmountMB
                                 , APaidAmount
                                 , APaidAmountMD
                                 , APaidAmountMB
                                 , AReturnedAmount
                                 , AReturnedAmountMD
                                 , AReturnedAmountMB
                                 , APaidBalancedAmount
                                 , APaidBalancedAmountMD
                                 , APaidBalancedAmountMB
                                 , ADiscountAmount
                                 , ADiscountAmountMD
                                 , ADiscountAmountMB
                                 , ADeductionAmount
                                 , ADeductionAmountMD
                                 , ADeductionAmountMB
                                  );
    end if;
  end OnPaymentCurrencyModification;

  /**
  * Description
  *   Recherche les montants d'escompte de la première tranche de l'échéance.
  */
  procedure GetDiscountAmount(
    ADocumentID        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , APaymentCurrencyID in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ADiscountAmount    out    DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type
  , ADiscountAmountMD  out    DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type
  , ADiscountAmountMB  out    DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type
  )
  is
    dmtFinancialCurrencyID  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    calcExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    calcBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    fopExchangeRate         DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    fopBasePrice            DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    dmtRateOfExchange       DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice            DOC_DOCUMENT.DMT_BASE_PRICE%type;
    numDocumentRate         number;
    numPaymentRate          number;
    numPaymentDocumentRate  number;
    baseFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    ADiscountAmount    := null;
    ADiscountAmountMD  := null;
    ADiscountAmountMB  := null;

    -- Recherche les cours utilisés.
    if GetExchangeRate(APaymentCurrencyID
                     , ADocumentID
                     , calcExchangeRate
                     , calcBasePrice
                     , fopExchangeRate
                     , fopBasePrice
                     , dmtFinancialCurrencyID
                     , dmtRateOfExchange
                     , dmtBasePrice
                      ) then
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de base
      numPaymentRate           := fopExchangeRate / fopBasePrice;
      -- Détermine le cours entre la monnaie de document et la monnaie de base
      numDocumentRate          := dmtRateOfExchange / dmtBasePrice;
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de document
      numPaymentDocumentRate   := calcExchangeRate / calcBasePrice;
      -- Recherche la monnaie de base
      baseFinancialCurrencyID  := ACS_FUNCTION.GetLocalCurrencyID;

      begin
        select PAD1.PAD_DISCOUNT_AMOUNT
             , PAD1.PAD_DISCOUNT_AMOUNT_B
          into ADiscountAmountMD
             , ADiscountAmountMB
          from (select   PAD.PAD_DISCOUNT_AMOUNT
                       , PAD.PAD_DISCOUNT_AMOUNT_B
                    from DOC_PAYMENT_DATE PAD
                   where PAD.DOC_FOOT_ID = ADocumentID
                order by PAD.PAD_BAND_NUMBER
                       , PAD.PAD_PAYMENT_DATE
                       , PAD.PAD_DISCOUNT_AMOUNT desc) PAD1
         where rownum = 1;

        -- Détermine les montants escompte en fonction des différents cours.
        GetConvertedAmounts(APaymentCurrencyID
                          , dmtFinancialCurrencyID
                          , baseFinancialCurrencyID
                          , numPaymentRate
                          , numDocumentRate
                          , numPaymentDocumentRate
                          , ADiscountAmount
                          , ADiscountAmountMD
                          , ADiscountAmountMB
                           );
      exception
        when no_data_found then
          ADiscountAmount    := 0;
          ADiscountAmountMD  := 0;
          ADiscountAmountMB  := 0;
      end;
    end if;
  end GetDiscountAmount;

  /**
  * Description
  *   Calcul les montants dans les trois différentes monnaies en fonction des cours et d'un montant de départ spécifié.
  *   une valeur nulle sur un montant signifie sont recalcul.
  */
  procedure GetConvertedAmounts(
    APaymentCurrencyID   in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ADocumentCurrencyID  in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ABaseCurrencyID      in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , APaymentRate         in     DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ADocumentRate        in     DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , APaymentDocumentRate in     DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , AAmount              in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type
  , AAmountMD            in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type
  , AAmountMB            in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type
  )
  is
    baseFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- Recherche la monnaie de base
    baseFinancialCurrencyID  := nvl(ABaseCurrencyID, ACS_FUNCTION.GetLocalCurrencyID);

    -- Détermine les montants escompte en fonction des différents cours.
    if     (ADocumentCurrencyID = baseFinancialCurrencyID)
       and (APaymentCurrencyID = baseFinancialCurrencyID) then
--       and (APaymentRate = ADocumentRate)
--       and (APaymentRate = APaymentDocumentRate) then
      ----
      -- Cas 1 : Monnaie du document  = monnaie de base   = monnaie d'encaissement et
      ---        Cours d'encaissement = Cours du document = Cours entre encaissement et document
      --
      if     AAmount is null
         and AAmountMD is null
         and AAmountMB is null then
        -- 000
        AAmount    := 0;
        AAmountMB  := 0;
        AAmountMD  := 0;
      elsif     AAmount is null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 001
        AAmount    := AAmountMB;
        AAmountMD  := AAmountMB;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 010
        AAmount    := AAmountMD;
        AAmountMB  := AAmountMD;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is not null then
        -- 011
        AAmount  := AAmountMB;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is null then
        -- 100
        AAmountMB  := AAmount;
        AAmountMD  := AAmount;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 101
        AAmountMD  := AAmountMB;
      elsif     AAmount is not null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 110
        AAmountMB  := AAmountMD;
      else
        -- 111
        null;
      end if;
    elsif     (ADocumentCurrencyID = baseFinancialCurrencyID)
          and (APaymentCurrencyID <> baseFinancialCurrencyID) then
      ----
      -- Cas 2 : Monnaie du document = Monnaie de base <> Monnaie d'encaissement
      --
      if     AAmount is null
         and AAmountMD is null
         and AAmountMB is null then
        -- 000
        AAmount    := 0;
        AAmountMB  := 0;
        AAmountMD  := 0;
      elsif     AAmount is null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 001
        AAmount    := AAmountMB * APaymentRate;
        AAmountMD  := AAmountMB;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 010
        AAmount    := AAmountMD * APaymentRate;
        AAmountMB  := AAmountMD;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is not null then
        -- 011
        -- Dans ce cas, la priorité est au montant en monnaie de base
        AAmount  := AAmountMB / APaymentRate;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is null then
        -- 100
        AAmountMB  := AAmount * APaymentRate;
        AAmountMD  := AAmountMB;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 101
        AAmountMD  := AAmountMB;
      elsif     AAmount is not null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 110
        AAmountMB  := AAmountMD;
      else
        -- 111
        null;
      end if;
    elsif     (ADocumentCurrencyID <> baseFinancialCurrencyID)
          and (APaymentCurrencyID = baseFinancialCurrencyID) then
      ----
      -- Cas 3 : Monnaie du document <> Monnaie de base = Monnaie d'encaissement
      --
      if     AAmount is null
         and AAmountMD is null
         and AAmountMB is null then
        -- 000
        AAmount    := 0;
        AAmountMB  := 0;
        AAmountMD  := 0;
      elsif     AAmount is null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 001
        AAmount    := AAmountMB;
        AAmountMD  := AAmountMB / ADocumentRate;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 010
        AAmount    := AAmountMD / APaymentDocumentRate;
        AAmountMB  := AAmountMD * ADocumentRate;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is not null then
        -- 011
        -- Dans ce cas, la priorité est au montant en monnaie de base
        AAmount  := AAmountMB;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is null then
        -- 100
        AAmountMB  := AAmount;
        AAmountMD  := AAmount * APaymentDocumentRate;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 101
        AAmountMD  := AAmountMB / ADocumentRate;
      elsif     AAmount is not null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 110
        -- Dans ce cas, la priorité est au montant en monnaie d'encaissement
        AAmountMB  := AAmount;
      else
        -- 111
        null;
      end if;
    elsif     (ADocumentCurrencyID <> baseFinancialCurrencyID)
          and (APaymentCurrencyID <> baseFinancialCurrencyID)
          and (ADocumentCurrencyID = APaymentCurrencyID) then
      ----
      -- Cas 4 : Monnaie du document = Monnaie d'encaissement <> Monnaie de base
      --
      if     AAmount is null
         and AAmountMD is null
         and AAmountMB is null then
        -- 000
        AAmount    := 0;
        AAmountMB  := 0;
        AAmountMD  := 0;
      elsif     AAmount is null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 001
        AAmount    := AAmountMB / APaymentRate;
        AAmountMD  := AAmountMB / ADocumentRate;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 010
        AAmount    := AAmountMD;
        AAmountMB  := AAmountMD * ADocumentRate;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is not null then
        -- 011
        AAmount  := AAmountMD;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is null then
        -- 100
        AAmountMB  := AAmount * APaymentRate;
        AAmountMD  := AAmount;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 101
        -- Dans ce cas, la priorité est au montant en monnaie d'encaissement
        AAmountMD  := AAmount;
      elsif     AAmount is not null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 110
        AAmountMB  := AAmount * APaymentRate;
      else
        -- 111
        null;
      end if;
    else   -- ( ADocumentCurrencyID <> APaymentCurrencyID ) and ( ADocumentCurrencyID <> baseFinancialCurrencyID )
      ----
      -- Cas 5 : Monnaie du document <> Monnaie d'encaissement <> Monnaie de base
      --
      if     AAmount is null
         and AAmountMD is null
         and AAmountMB is null then
        -- 000
        AAmount    := 0;
        AAmountMB  := 0;
        AAmountMD  := 0;
      elsif     AAmount is null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 001
        AAmount    := AAmountMB / APaymentRate;
        AAmountMD  := AAmountMB / ADocumentRate;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 010
        AAmount    := AAmountMD / APaymentDocumentRate;
        AAmountMB  := AAmountMD * ADocumentRate;
      elsif     AAmount is null
            and AAmountMD is not null
            and AAmountMB is not null then
        -- 011
        -- Dans ce cas, la priorité est au montant en monnaie de base
        AAmount  := AAmountMB / APaymentRate;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is null then
        -- 100
        AAmountMB  := AAmount * APaymentRate;
        AAmountMD  := AAmount * APaymentDocumentRate;
      elsif     AAmount is not null
            and AAmountMD is null
            and AAmountMB is not null then
        -- 101
        AAmountMD  := AAmount * APaymentDocumentRate;
      elsif     AAmount is not null
            and AAmountMD is not null
            and AAmountMB is null then
        -- 110
        AAmountMB  := AAmount * APaymentRate;
      else
        -- 111
        null;
      end if;
    end if;
  end GetConvertedAmounts;

  /**
  * Description
  *   Méthode d'initialisation des données à la création d'une transaction d'encaissement
  */
  procedure InitDataPaymentCreation(
    AFootPaymentID        in out DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , ADocumentID           in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , APaymentCurrencyID    in out ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , AExchangeRate         in out DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ABasePrice            in out DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , AJobTypeCatID         in out DOC_GAUGE_STRUCTURED.ACJ_JOB_TYPE_S_CAT_PMT_ID%type
  , AReceivedAmount       in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type
  , AReceivedAmountMD     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type
  , AReceivedAmountMB     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type
  , APaidAmount           in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , APaidAmountMD         in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type
  , APaidAmountMB         in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , AReturnedAmount       in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , AReturnedAmountMD     in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type
  , AReturnedAmountMB     in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type
  , APaidBalancedAmount   in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type
  , APaidBalancedAmountMD in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type
  , APaidBalancedAmountMB in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type
  , ADiscountAmount       in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type
  , ADiscountAmountMD     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type
  , ADiscountAmountMB     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type
  , ADeductionAmount      in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type
  , ADeductionAmountMD    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type
  , ADeductionAmountMB    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type
  , AReceivedAmountUsed   in     boolean default false
  )
  is
    docFootPaymentID        DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type;
    isFirstPayment          boolean;
    fopPaidBalancedAmount   DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type;
    fopPaidBalancedAmountMD DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    fopPaidBalancedAmountMB DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type;
    dmtFinancialCurrencyID  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    calcExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    calcBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    fopExchangeRate         DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    fopBasePrice            DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    dmtRateOfExchange       DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice            DOC_DOCUMENT.DMT_BASE_PRICE%type;
    numDocumentRate         number;
    numPaymentRate          number;
    numPaymentDocumentRate  number;
    baseFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    if AFootPaymentID is null then
      select INIT_ID_SEQ.nextval
        into AFootPaymentID
        from dual;
    end if;

    -- Détermine si le document courant possède déjà au moins une transaction de paiement. Récupère également les
    -- montants soldes du dernier paiement.
    begin
      select FOP1.FOP_PAID_BALANCED_AMOUNT
           , FOP1.FOP_PAID_BALANCED_AMOUNT_MD
           , FOP1.FOP_PAID_BALANCED_AMOUNT_MB
           , FOP1.DOC_FOOT_PAYMENT_ID
        into fopPaidBalancedAmount
           , fopPaidBalancedAmountMD
           , fopPaidBalancedAmountMB
           , docFootPaymentID
        from (select   FOP.FOP_PAID_BALANCED_AMOUNT
                     , FOP.FOP_PAID_BALANCED_AMOUNT_MD
                     , FOP.FOP_PAID_BALANCED_AMOUNT_MB
                     , FOP.DOC_FOOT_PAYMENT_ID
                  from DOC_FOOT_PAYMENT FOP
                 where FOP.DOC_FOOT_ID = ADocumentID
              order by FOP.DOC_FOOT_PAYMENT_ID desc) FOP1
       where rownum = 1;

      isFirstPayment  := false;
    exception
      when no_data_found then
        isFirstPayment           := true;
        fopPaidBalancedAmount    := null;
        fopPaidBalancedAmountMD  := null;
        fopPaidBalancedAmountMB  := null;
    end;

    -- Détermine la monnaie du paiement
    if nvl(APaymentCurrencyID, 0) = 0 then
      select DMT.ACS_FINANCIAL_CURRENCY_ID
        into APaymentCurrencyID
        from DOC_DOCUMENT DMT
       where DMT.DOC_DOCUMENT_ID = ADocumentID;
    end if;

    -- Recherche les cours utilisés.
    if GetExchangeRate(APaymentCurrencyID
                     , ADocumentID
                     , calcExchangeRate
                     , calcBasePrice
                     , AExchangeRate
                     , ABasePrice
                     , dmtFinancialCurrencyID
                     , dmtRateOfExchange
                     , dmtBasePrice
                      ) then
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de base
      numPaymentRate           := fopExchangeRate / fopBasePrice;
      -- Détermine le cours entre la monnaie de document et la monnaie de base
      numDocumentRate          := dmtRateOfExchange / dmtBasePrice;
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de document
      numPaymentDocumentRate   := calcExchangeRate / calcBasePrice;
      -- Recherche la monnaie de base
      baseFinancialCurrencyID  := ACS_FUNCTION.GetLocalCurrencyID;
      ADiscountAmount          := 0;
      ADiscountAmountMD        := 0;
      ADiscountAmountMB        := 0;
      ADeductionAmount         := 0;
      ADeductionAmountMD       := 0;
      ADeductionAmountMB       := 0;

      -- Ne reprend pas le montant à encaisser transmit
      if not AReceivedAmountUsed then
        AReceivedAmount    := null;   -- fopPaidBalancedAmount;
        AReceivedAmountMD  := fopPaidBalancedAmountMD;
        AReceivedAmountMB  := fopPaidBalancedAmountMB;
      end if;

      if isFirstPayment then
        -- Initialise le catalogue de paiement et la monnaie du paiement en fonction, respectivement, du
        -- catalogue de vente au comptant du gabarit et de la monnaie du document. Cette initialisation
        -- ne doit se faire que sur le premier paiement.
        if nvl(AJobTypeCatID, 0) = 0 then
          select GAS.ACJ_JOB_TYPE_S_CAT_PMT_ID
            into AJobTypeCatID
            from DOC_DOCUMENT DMT
               , DOC_GAUGE_STRUCTURED GAS
           where DMT.DOC_DOCUMENT_ID = ADocumentID
             and GAS.DOC_GAUGE_ID(+) = DMT.DOC_GAUGE_ID;
        end if;

        -- Recherche les montants d'escompte exprimé en fonction de la monnaie d'encaissement. Cette initialisation
        -- ne doit se faire que sur le premier paiement.
        GetDiscountAmount(ADocumentID, APaymentCurrencyID, ADiscountAmount, ADiscountAmountMD, ADiscountAmountMB);
      end if;

      -- Recherche les montants reçu. Il s'initialise toujours avec le solde restant à encaisser.
      -- Pour la création de la première transaction d'encaissement, le solde restant à encaisser est définit par la
      -- différence entre le montant échu de l'échéance et la somme des montants déjà payé sur les autres
      -- transaction d'encaissement. Par contre pour les suivantes, le solde est repris de la transaction précédente,
      -- en admettant que ce solde soit mise à jour dans le cas d'une modification du montant total du document.
      if     isFirstPayment
         and not AReceivedAmountUsed then
        GetBalanceAmount(ADocumentID, AReceivedAmount, numPaymentRate, null, 0, ADiscountAmount, 0);
        GetBalanceAmountMB(ADocumentID, AReceivedAmountMB, null, 0, ADiscountAmountMB, 0);
        GetBalanceAmountMD(ADocumentID, AReceivedAmountMD, null, 0, ADiscountAmountMD, 0);
      end if;
    end if;

    -- Déclenchement des mise à jour liées au montant à encaisser (reçu)
    OnReceivedAmountModification(AReceivedAmount
                               , null
                               , APaymentCurrencyID
                               , ADocumentID
                               , AExchangeRate
                               , ABasePrice
                               , AReceivedAmountMD
                               , AReceivedAmountMB
                               , APaidAmount
                               , APaidAmountMD
                               , APaidAmountMB
                               , AReturnedAmount
                               , AReturnedAmountMD
                               , AReturnedAmountMB
                               , APaidBalancedAmount
                               , APaidBalancedAmountMD
                               , APaidBalancedAmountMB
                               , ADiscountAmount
                               , ADiscountAmountMD
                               , ADiscountAmountMB
                               , ADeductionAmount
                               , ADeductionAmountMD
                               , ADeductionAmountMB
                                );
  end InitDataPaymentCreation;

  /**
  * Description
  *   Méthode de contrôle du montant de déduction sur la base du montant de déduction maximum toléré définit sur
  *   le sous-ensemble du tiers.
  */
  procedure CheckDeductionAmounts(
    ADocumentID        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , AFootPaymentID     in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , ADeductionAmountMB in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type
  )
  is
    maxDeductionAmountMB      DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type;
    totalDeductionAmountMB    DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type;
    docPaymentDateAmountMD    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT%type;
    docPaymentDateNetAmountMD DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT%type;
    docPaymentDateAmountMB    DOC_PAYMENT_DATE.PAD_DATE_AMOUNT_B%type;
    docPaymentDateNetAmountMB DOC_PAYMENT_DATE.PAD_NET_DATE_AMOUNT_B%type;
  begin
    -- Recherche des montants échu du document en monnaie de base. Recherche la plus petit échéance de
    -- la première tranche.
    GetDocumentAmounts(ADocumentID, docPaymentDateAmountMD, docPaymentDateNetAmountMD, docPaymentDateAmountMB, docPaymentDateNetAmountMB);

    if docPaymentDateAmountMB is not null then
      -- Récupère le montant max déductible.
      begin
        select ACT_CREATION_SBVR.MaxDeductionPossible(DMT.PAC_THIRD_ID, null, docPaymentDateAmountMB)
          into maxDeductionAmountMB
          from DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = ADocumentID;
      exception
        when no_data_found then
          null;
      end;

      -- Détermine la somme des montants déduction excepté l'encaissement courant.
      GetTotalDeductionAmountMB(ADocumentID, totalDeductionAmountMB, AFootPaymentID, ADeductionAmountMB);

      ----
      -- Détermine le montant déduction
      --
      -- Si la somme des montants déduction est supérieur au montant max déductible, on modifie le montant déduction
      -- du paiement par le calcul suivant :
      --
      --   Remarque : tous les montants doivent être exprimé en monnaie de base
      --
      --   Somme montant déduction = Somme de tous les montants déductions de tous les paiements excepté le paiement
      --                             courant.
      --
      --   Si (Montant max - Somme montant déduction) > 0
      --     Montant déduction = Montant max - Somme montant déduction
      --   Sinon
      --     Montant déduction = 0
      --
      if (totalDeductionAmountMB > maxDeductionAmountMB) then
        if (maxDeductionAmountMB -(totalDeductionAmountMB - ADeductionAmountMB) ) > 0 then
          ADeductionAmountMB  := maxDeductionAmountMB -(totalDeductionAmountMB - ADeductionAmountMB);
        else
          ADeductionAmountMB  := 0;
        end if;
      end if;
    else
      ADeductionAmountMB  := null;
    end if;
  end CheckDeductionAmounts;

  /**
  * Description
  *   Méthode de modification du montant déduction. Conversion du montant déduction en monnaie de base pour
  *   vérification de la tolérence et ensuite de nouveau conversion de l'éventel nouveau montant déduction
  *   de la monnaie de base en monnaie d'encaissement et en monnaie du document.
  */
  procedure OnDeductionAmountModification(
    ADeductionAmount      in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type
  , AFootPaymentID        in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , ADocumentID           in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , APaymentCurrencyID    in out ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , AExchangeRate         in out DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ABasePrice            in out DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , AReceivedAmount       in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type
  , AReceivedAmountMD     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type
  , AReceivedAmountMB     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type
  , APaidAmount           in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , APaidAmountMD         in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type
  , APaidAmountMB         in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , AReturnedAmount       in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , AReturnedAmountMD     in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type
  , AReturnedAmountMB     in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type
  , APaidBalancedAmount   in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type
  , APaidBalancedAmountMD in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type
  , APaidBalancedAmountMB in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type
  , ADiscountAmount       in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type
  , ADiscountAmountMD     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type
  , ADiscountAmountMB     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type
  , ADeductionAmountMD    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type
  , ADeductionAmountMB    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type
  )
  is
    dmtFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    calcExchangeRate       DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    calcBasePrice          DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    fopExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    fopBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    dmtRateOfExchange      DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice           DOC_DOCUMENT.DMT_BASE_PRICE%type;
    fopDeductionAmount     DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type;
    fopDeductionAmountMD   DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type;
    fopDeductionAmountMB   DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type;
    numDocumentRate        number;
    numPaymentRate         number;
    numPaymentDocumentRate number;
  begin
    -- Recherche le cours entre la monnaie d'encaissement et la monnaie de base.
    if GetExchangeRate(APaymentCurrencyID
                     , ADocumentID
                     , calcExchangeRate
                     , calcBasePrice
                     , fopExchangeRate
                     , fopBasePrice
                     , dmtFinancialCurrencyID
                     , dmtRateOfExchange
                     , dmtBasePrice
                      ) then
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de base
      numPaymentRate          := fopExchangeRate / fopBasePrice;
      -- Détermine le cours entre la monnaie de document et la monnaie de base
      numDocumentRate         := dmtRateOfExchange / dmtBasePrice;
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de document
      numPaymentDocumentRate  := calcExchangeRate / calcBasePrice;
      -- Convertit le nouveau montant de déduction en monnaie de base et en monnaie de document. C'est indispensable
      -- pour la vérification du montant de déduction maximum toléré (il est exprimer en monnaie de base).
      fopDeductionAmount      := ADeductionAmount;   -- Montant de référence
      fopDeductionAmountMD    := null;   -- Indique une demande de calcul en monnaie du document.
      fopDeductionAmountMB    := null;   -- Indique une demande de calcul en monnaie de base.
      -- Détermine le nouveau montants déduction en fonction des différents cours.
      GetConvertedAmounts(APaymentCurrencyID
                        , dmtFinancialCurrencyID
                        , null
                        , numPaymentRate
                        , numDocumentRate
                        , numPaymentDocumentRate
                        , fopDeductionAmount
                        , fopDeductionAmountMD
                        , fopDeductionAmountMB
                         );
      -- J'initialise déjà le nouveau montant déduction en monnaie de base pour vérifier si il a été modifié lors
      -- du control de tolérance.
      ADeductionAmountMB      := fopDeductionAmountMB;
      -- Vérification du montant de déduction sur la base du montant de déduction maximum toléré définit sur
      -- le sous-ensemble du tiers.
      CheckDeductionAmounts(ADocumentID, AFootPaymentID, fopDeductionAmountMB);

      -- Si le montant déduction en monnaie de base a changé, il faut recalculé les montants déduction dans les autres
      -- monnaies
      if fopDeductionAmountMB <> ADeductionAmountMB then
        -- Recalcul les montants de déduction avec pour référence, le montant en monnaie de base.
        fopDeductionAmount    := null;   -- Indique une demande de calcul en monnaie d'encaissement
        fopDeductionAmountMD  := null;   -- Indique une demande de calcul en monnaie du document.
        -- Détermine le nouveau montants déduction en fonction des différents cours.
        GetConvertedAmounts(APaymentCurrencyID
                          , dmtFinancialCurrencyID
                          , null
                          , numPaymentRate
                          , numDocumentRate
                          , numPaymentDocumentRate
                          , fopDeductionAmount
                          , fopDeductionAmountMD
                          , fopDeductionAmountMB
                           );
      end if;

      ADeductionAmount        := fopDeductionAmount;
      ADeductionAmountMD      := fopDeductionAmountMD;
      ADeductionAmountMB      := fopDeductionAmountMB;
      -- Déclence les traitements de mise à jour du montant à encaisser (reçu) qui traite également les modifications
      -- des montants escompte et déduction.
      OnReceivedAmountModification(AReceivedAmount
                                 , AFootPaymentID
                                 , APaymentCurrencyID
                                 , ADocumentID
                                 , AExchangeRate
                                 , ABasePrice
                                 , AReceivedAmountMD
                                 , AReceivedAmountMB
                                 , APaidAmount
                                 , APaidAmountMD
                                 , APaidAmountMB
                                 , AReturnedAmount
                                 , AReturnedAmountMD
                                 , AReturnedAmountMB
                                 , APaidBalancedAmount
                                 , APaidBalancedAmountMD
                                 , APaidBalancedAmountMB
                                 , ADiscountAmount
                                 , ADiscountAmountMD
                                 , ADiscountAmountMB
                                 , ADeductionAmount
                                 , ADeductionAmountMD
                                 , ADeductionAmountMB
                                  );
    end if;
  end OnDeductionAmountModification;

  /**
  * Description
  *   Méthode de modification du montant rendu.
  */
  procedure OnReturnedAmountModification(
    ANewReturnedAmount    in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , AFootPaymentID        in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , ADocumentID           in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , APaymentCurrencyID    in out ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , AExchangeRate         in out DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ABasePrice            in out DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type
  , AReceivedAmount       in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type
  , AReceivedAmountMD     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type
  , AReceivedAmountMB     in out DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type
  , APaidAmount           in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , APaidAmountMD         in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type
  , APaidAmountMB         in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , AReturnedAmount       in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , AReturnedAmountMD     in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type
  , AReturnedAmountMB     in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type
  , APaidBalancedAmount   in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type
  , APaidBalancedAmountMD in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type
  , APaidBalancedAmountMB in out DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type
  , ADiscountAmount       in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type
  , ADiscountAmountMD     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type
  , ADiscountAmountMB     in out DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type
  , ADeductionAmount      in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type
  , ADeductionAmountMD    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type
  , ADeductionAmountMB    in out DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type
  )
  is
    dmtFinancialCurrencyID  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    calcExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    calcBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    fopExchangeRate         DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    fopBasePrice            DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    dmtRateOfExchange       DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice            DOC_DOCUMENT.DMT_BASE_PRICE%type;
    fopReturnedAmount       DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type;
    fopReturnedAmountMD     DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type;
    fopReturnedAmountMB     DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type;
    fopPaidBalancedAmount   DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type;
    fopPaidBalancedAmountMD DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    fopPaidBalancedAmountMB DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type;
    numDocumentRate         number;
    numPaymentRate          number;
    numPaymentDocumentRate  number;
    deltaReturned           DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type;
  begin
    -- Recherche le cours entre la monnaie d'encaissement et la monnaie de base.
    if GetExchangeRate(APaymentCurrencyID
                     , ADocumentID
                     , calcExchangeRate
                     , calcBasePrice
                     , fopExchangeRate
                     , fopBasePrice
                     , dmtFinancialCurrencyID
                     , dmtRateOfExchange
                     , dmtBasePrice
                      ) then
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de base
      numPaymentRate          := fopExchangeRate / fopBasePrice;
      -- Détermine le cours entre la monnaie de document et la monnaie de base
      numDocumentRate         := dmtRateOfExchange / dmtBasePrice;
      -- Détermine le cours entre la monnaie d'encaissement et la monnaie de document
      numPaymentDocumentRate  := calcExchangeRate / calcBasePrice;
      -- Détermine l'écart de modification du montant rendu.
      deltaReturned           := ANewReturnedAmount - AReturnedAmount;
      -- Convertit le nouveau montant rendu en monnaie de base et en monnaie de document.
      fopReturnedAmount       := ANewReturnedAmount;   -- Montant de référence
      fopReturnedAmountMD     := null;   -- Indique une demande de calcul en monnaie du document.
      fopReturnedAmountMB     := null;   -- Indique une demande de calcul en monnaie de base.
      -- Détermine le nouveau montant rendu en fonction des différents cours.
      GetConvertedAmounts(APaymentCurrencyID
                        , dmtFinancialCurrencyID
                        , null
                        , numPaymentRate
                        , numDocumentRate
                        , numPaymentDocumentRate
                        , fopReturnedAmount
                        , fopReturnedAmountMD
                        , fopReturnedAmountMB
                         );
      ANewReturnedAmount      := fopReturnedAmount;
      AReturnedAmountMD       := fopReturnedAmountMD;
      AReturnedAmountMB       := fopReturnedAmountMB;
      ----
      -- Recalcul les montants payés en fonction des nouveaux montants rendu selon la règle suivante :
      --
      -- Montant payé = Montant reçu - Montant rendu
      --
      -- Montant payé en monnaie d'encaissement.
      APaidAmount             := AReceivedAmount - ANewReturnedAmount;
      -- Montant rendu en monnaie du document.
      APaidAmountMD           := AReceivedAmountMD - AReturnedAmountMD;
      -- Montant rendu en monnaie de base.
      APaidAmountMB           := AReceivedAmountMB - AReturnedAmountMB;

      ----
      -- Mise à jour du montant de déduction
      --
      -- Exemple :                Seq Payé   Rendu Escompte Deduction Solde
      --
      -- Recu 120.- par le client 1   100.-  20.-  0.-        0.-     0.-
      --                          2   102.-  18.-  0.-       -2.-     0.-
      --                          3    98.-  22.-  0.-        0.-     2.-
      --                          4   100.-  20.-  0.-        0.-     0.-
      --                          5   110.-  10.-  0.-      -10.-     0.-
      --                          5    90.-  30.-  0.-        0.-    10.-

      --
      if     (deltaReturned < 0)
         and (APaidBalancedAmount = 0) then
        ----
        -- Diminution du montant rendu avec aucun solde. Le différence est totalement ajouté en déduction.
        --
        ADeductionAmount  := ADeductionAmount + deltaReturned;
      elsif     (deltaReturned < 0)
            and (APaidBalancedAmount > 0) then
        ----
        -- Diminution du montant rendu avec solde. Le différence moins le solde est passée ajouter en déduction.
        --
        ADeductionAmount  := ADeductionAmount + deltaReturned + APaidBalancedAmount;
      elsif     (deltaReturned > 0)
            and (ADeductionAmount < 0)
            and (APaidBalancedAmount = 0) then
        ----
        -- Augmentation du montant rendu avec un montant de déduction négatif et pas de solde. Dans ce cas,
        -- on va ajouter la différence au montant de déduction mais jusqu'a une déduction à 0. Le reste est passé en
        -- quantité solde.
        --
        if (ADeductionAmount + deltaReturned > 0) then
          ADeductionAmount  := 0;
        else
          ADeductionAmount  := ADeductionAmount + deltaReturned;
        end if;
      end if;

      ADeductionAmountMD      := null;
      ADeductionAmountMB      := null;
      GetConvertedAmounts(APaymentCurrencyID
                        , dmtFinancialCurrencyID
                        , null
                        , numPaymentRate
                        , numDocumentRate
                        , numPaymentDocumentRate
                        , ADeductionAmount
                        , ADeductionAmountMD
                        , ADeductionAmountMB
                         );
      ----
      -- Détermine les montants restant a payer dans les différentes monnaies en excluant le montant
      -- payé sur l'encaissement courant.
      --
      -- Montant restant à payé en monnaie du document.
      GetBalanceAmountMD(ADocumentID   -- Document courant
                       , fopPaidBalancedAmountMD   -- Montant solde obtenu en monnaie du document
                       , AFootPaymentID   -- Encaissement en cours de saisie
                       , 0   -- Montant payé sur l'encaissement en cours de saisie (à déterminer plus tard)
                       , ADiscountAmountMD
                       , ADeductionAmountMD
                        );
      -- Montant restant à payé en monnaie de base.
      GetBalanceAmountMB(ADocumentID   -- Document courant
                       , fopPaidBalancedAmountMB   -- Montant solde obtenu en monnaie de base
                       , AFootPaymentID   -- Encaissement en cours de saisie
                       , 0   -- Montant payé sur l'encaissement en cours de saisie (à déterminer plus tard)
                       , ADiscountAmountMB
                       , ADeductionAmountMB
                        );
      -- Montant restant à payé en monnaie d'encaissement. Il doit toujours se calculer à partir
      -- des montants en monnaie de base ou en monnaie de document.
      --
      fopPaidBalancedAmount   := null;   -- Indique une demande de recalcul.
      GetConvertedAmounts(APaymentCurrencyID
                        , dmtFinancialCurrencyID
                        , null
                        , numPaymentRate
                        , numDocumentRate
                        , numPaymentDocumentRate
                        , fopPaidBalancedAmount
                        , fopPaidBalancedAmountMD
                        , fopPaidBalancedAmountMB
                         );
      -- Montant restant à payer en monnaie d'encaissement.
      APaidBalancedAmount     := fopPaidBalancedAmount - APaidAmount;
      -- Montant restant à payer en monnaie du document.
      APaidBalancedAmountMD   := fopPaidBalancedAmountMD - APaidAmountMD;
      -- Montant restant à payer en monnaie de base.
      APaidBalancedAmountMB   := fopPaidBalancedAmountMB - APaidAmountMB;
    end if;
  end OnReturnedAmountModification;

  /**
   * procedure UpdateBalance
   * Description
   *   Met à jour le solde du paiement dans toutes les monnaies en tenant compte des montants d'escompte et de
   *   déduction.
   */
  procedure UpdateBalance(
    AFootPaymentID       in DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , ADocumentID          in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , APaymentCurrencyID   in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ADocumentCurrencyID  in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , APaymentRate         in DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , ADocumentRate        in DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , APaymentDocumentRate in DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type
  , APaidAmount          in DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , APaidAmountMD        in DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type
  , APaidAmountMB        in DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type
  , ADiscountAmount      in DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type
  , ADiscountAmountMD    in DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type
  , ADiscountAmountMB    in DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type
  , ADeductionAmount     in DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type
  , ADeductionAmountMD   in DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type
  , ADeductionAmountMB   in DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type
  )
  is
    fopPaidBalancedAmount   DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type;
    fopPaidBalancedAmountMD DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    fopPaidBalancedAmountMB DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type;
  begin
    -- Détermine les montants restant a payer dans les différentes monnaies en excluant le montant
    -- payé sur l'encaissement courant.
    --
    -- Montant restant à payé en monnaie du document.
    GetBalanceAmountMD(ADocumentID   -- Document courant
                     , fopPaidBalancedAmountMD   -- Montant solde obtenu en monnaie du document
                     , AFootPaymentID   -- Encaissement en cours de saisie
                     , 0   -- Montant payé sur l'encaissement en cours de saisie (à déterminer plus tard)
                     , ADiscountAmountMD
                     , ADeductionAmountMD
                      );
    -- Montant restant à payé en monnaie de base.
    GetBalanceAmountMB(ADocumentID   -- Document courant
                     , fopPaidBalancedAmountMB   -- Montant solde obtenu en monnaie de base
                     , AFootPaymentID   -- Encaissement en cours de saisie
                     , 0   -- Montant payé sur l'encaissement en cours de saisie (à déterminer plus tard)
                     , ADiscountAmountMB
                     , ADeductionAmountMB
                      );
    ----
    -- Montant restant à payé en monnaie d'encaissement. Il doit toujours se calculer à partir
    -- des montants en monnaie de base ou en monnaie de document.
    --
    fopPaidBalancedAmount    := null;   -- Indique une demande de recalcul.
    GetConvertedAmounts(APaymentCurrencyID
                      , ADocumentCurrencyID
                      , null
                      , APaymentRate
                      , ADocumentRate
                      , APaymentDocumentRate
                      , fopPaidBalancedAmount
                      , fopPaidBalancedAmountMD
                      , fopPaidBalancedAmountMB
                       );
    -- Montant restant à payer en monnaie d'encaissement.
    fopPaidBalancedAmount    := fopPaidBalancedAmount - APaidAmount;
    -- Montant restant à payer en monnaie du document.
    fopPaidBalancedAmountMD  := fopPaidBalancedAmountMD - APaidAmountMD;
    -- Montant restant à payer en monnaie de base.
    fopPaidBalancedAmountMB  := fopPaidBalancedAmountMB - APaidAmountMB;

    update DOC_FOOT_PAYMENT
       set FOP_PAID_BALANCED_AMOUNT = fopPaidBalancedAmount
         , FOP_PAID_BALANCED_AMOUNT_MD = fopPaidBalancedAmountMD
         , FOP_PAID_BALANCED_AMOUNT_MB = fopPaidBalancedAmountMB
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_FOOT_PAYMENT_ID = AFootPaymentID;
  end UpdateBalance;

  /**
   * procedure UpdatePaymentCurrency
   * Description
   *   Met à jour les montants en monnaie de document, monnaie de base et monnaie d'encaissement suite à une modification du cours.
   */
  procedure UpdatePaymentCurrency(
    APaymentCurrencyID in out ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , AFootPaymentID     in     DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , ADocumentID        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  )
  is
    dmtFinancialCurrencyID  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    calcExchangeRate        DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type;
    calcBasePrice           DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type;
    dmtRateOfExchange       DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice            DOC_DOCUMENT.DMT_BASE_PRICE%type;
    fopExchangeRate         DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type                 default 1;
    fopBasePrice            DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type                    default 1;
    fopPaidAmount           DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type;
    fopPaidAmountMD         DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type;
    fopPaidAmountMB         DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type;
    fopReceivedAmount       DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type;
    fopReceivedAmountMD     DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type;
    fopReceivedAmountMB     DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type;
    fopReturnedAmount       DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type;
    fopReturnedAmountMD     DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type;
    fopReturnedAmountMB     DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type;
    fopPaidBalancedAmount   DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type;
    fopPaidBalancedAmountMD DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    fopPaidBalancedAmountMB DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type;
    fopDiscountAmount       DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type;
    fopDiscountAmountMD     DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type;
    fopDiscountAmountMB     DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type;
    fopDeductionAmount      DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type;
    fopDeductionAmountMD    DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type;
    fopDeductionAmountMB    DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type;
  begin
    select FOP_EXCHANGE_RATE
         , FOP_BASE_PRICE
         , FOP_PAID_AMOUNT
         , FOP_PAID_AMOUNT_MD
         , FOP_PAID_AMOUNT_MB
         , FOP_RECEIVED_AMOUNT
         , FOP_RECEIVED_AMOUNT_MD
         , FOP_RECEIVED_AMOUNT_MB
         , FOP_RETURNED_AMOUNT
         , FOP_RETURNED_AMOUNT_MD
         , FOP_RETURNED_AMOUNT_MB
         , FOP_DISCOUNT_AMOUNT
         , FOP_DISCOUNT_AMOUNT_MD
         , FOP_DISCOUNT_AMOUNT_MB
         , FOP_DEDUCTION_AMOUNT
         , FOP_DEDUCTION_AMOUNT_MD
         , FOP_DEDUCTION_AMOUNT_MB
         , FOP_PAID_BALANCED_AMOUNT
         , FOP_PAID_BALANCED_AMOUNT_MD
         , FOP_PAID_BALANCED_AMOUNT_MB
      into fopExchangeRate   -- FOP_EXCHANGE_RATE
         , fopBasePrice   -- FOP_BASE_PRICE
         , fopPaidAmount   -- FOP_PAID_AMOUNT
         , fopPaidAmountMD   -- FOP_PAID_AMOUNT_MD
         , fopPaidAmountMB   -- FOP_PAID_AMOUNT_MB
         , fopReceivedAmount   -- FOP_RECEIVED_AMOUNT
         , fopReceivedAmountMD   -- FOP_RECEIVED_AMOUNT_MD
         , fopReceivedAmountMB   -- FOP_RECEIVED_AMOUNT_MB
         , fopReturnedAmount   -- FOP_RETURNED_AMOUNT
         , fopReturnedAmountMD   -- FOP_RETURNED_AMOUNT_MD
         , fopReturnedAmountMB   -- FOP_RETURNED_AMOUNT_MB
         , fopDiscountAmount   -- FOP_DISCOUNT_AMOUNT
         , fopDiscountAmountMD   -- FOP_DISCOUNT_AMOUNT_MD
         , fopDiscountAmountMB   -- FOP_DISCOUNT_AMOUNT_MB
         , fopDeductionAmount   -- FOP_DEDUCTION_AMOUNT
         , fopDeductionAmountMD   -- FOP_DEDUCTION_AMOUNT_MD
         , fopDeductionAmountMB   -- FOP_DEDUCTION_AMOUNT_MB
         , fopPaidBalancedAmount   -- FOP_PAID_BALANCED_AMOUNT
         , fopPaidBalancedAmountMD   -- FOP_PAID_BALANCED_AMOUNT_MD
         , fopPaidBalancedAmountMB   -- FOP_PAID_BALANCED_AMOUNT_MB
      from DOC_FOOT_PAYMENT
     where DOC_FOOT_PAYMENT_ID = aFootPaymentId;

    -- Recherche le cours entre la monnaie d'encaissement et la monnaie de base.
    if GetExchangeRate(APaymentCurrencyID
                     , ADocumentID
                     , calcExchangeRate
                     , calcBasePrice
                     , fopExchangeRate
                     , fopBasePrice
                     , dmtFinancialCurrencyID
                     , dmtRateOfExchange
                     , dmtBasePrice
                      ) then
      -- Demande le recalcul de tous les montants en monnaie de base et en monnaie de document sur la base des montants
      -- en monnaie d'encaissement.
      fopReceivedAmountMD   := null;
      fopReceivedAmountMB   := null;
      fopDiscountAmountMD   := null;
      fopDiscountAmountMB   := null;
      fopDeductionAmountMD  := null;
      fopDeductionAmountMB  := null;
      fopReturnedAmountMD   := null;
      fopReturnedAmountMB   := null;
      -- Modification du montant à encaisser (reçu)
      OnReceivedAmountModification(fopReceivedAmount
                                 , AFootPaymentID
                                 , APaymentCurrencyID
                                 , ADocumentID
                                 , fopExchangeRate
                                 , fopBasePrice
                                 , fopReceivedAmountMD
                                 , fopReceivedAmountMB
                                 , fopPaidAmount
                                 , fopPaidAmountMD
                                 , fopPaidAmountMB
                                 , fopReturnedAmount
                                 , fopReturnedAmountMD
                                 , fopReturnedAmountMB
                                 , fopPaidBalancedAmount
                                 , fopPaidBalancedAmountMD
                                 , fopPaidBalancedAmountMB
                                 , fopDiscountAmount
                                 , fopDiscountAmountMD
                                 , fopDiscountAmountMB
                                 , fopDeductionAmount
                                 , fopDeductionAmountMD
                                 , fopDeductionAmountMB
                                  );
    end if;

    update DOC_FOOT_PAYMENT
       set FOP_EXCHANGE_RATE = fopExchangeRate
         , FOP_BASE_PRICE = fopBasePrice
         , FOP_PAID_AMOUNT = nvl(fopPaidAmount, FOP_PAID_AMOUNT)
         , FOP_PAID_AMOUNT_MD = nvl(fopPaidAmountMD, FOP_PAID_AMOUNT_MD)
         , FOP_PAID_AMOUNT_MB = nvl(fopPaidAmountMB, FOP_PAID_AMOUNT_MB)
         , FOP_RECEIVED_AMOUNT = nvl(fopReceivedAmount, FOP_RECEIVED_AMOUNT)
         , FOP_RECEIVED_AMOUNT_MD = nvl(fopReceivedAmountMD, FOP_RECEIVED_AMOUNT_MD)
         , FOP_RECEIVED_AMOUNT_MB = nvl(fopReceivedAmountMB, FOP_RECEIVED_AMOUNT_MB)
         , FOP_RETURNED_AMOUNT = nvl(fopReturnedAmount, FOP_RETURNED_AMOUNT)
         , FOP_RETURNED_AMOUNT_MD = nvl(fopReturnedAmountMD, FOP_RETURNED_AMOUNT_MD)
         , FOP_RETURNED_AMOUNT_MB = nvl(fopReturnedAmountMB, FOP_RETURNED_AMOUNT_MB)
         , FOP_DISCOUNT_AMOUNT = nvl(fopDiscountAmount, FOP_DISCOUNT_AMOUNT)
         , FOP_DISCOUNT_AMOUNT_MD = nvl(fopDiscountAmountMD, FOP_DISCOUNT_AMOUNT_MD)
         , FOP_DISCOUNT_AMOUNT_MB = nvl(fopDiscountAmountMB, FOP_DISCOUNT_AMOUNT_MB)
         , FOP_DEDUCTION_AMOUNT = nvl(fopDeductionAmount, FOP_DEDUCTION_AMOUNT)
         , FOP_DEDUCTION_AMOUNT_MD = nvl(fopDeductionAmountMD, FOP_DEDUCTION_AMOUNT_MD)
         , FOP_DEDUCTION_AMOUNT_MB = nvl(fopDeductionAmountMB, FOP_DEDUCTION_AMOUNT_MB)
         , FOP_PAID_BALANCED_AMOUNT = nvl(fopPaidBalancedAmount, FOP_PAID_BALANCED_AMOUNT)
         , FOP_PAID_BALANCED_AMOUNT_MD = nvl(fopPaidBalancedAmountMD, FOP_PAID_BALANCED_AMOUNT_MD)
         , FOP_PAID_BALANCED_AMOUNT_MB = nvl(fopPaidBalancedAmountMB, FOP_PAID_BALANCED_AMOUNT_MB)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_FOOT_PAYMENT_ID = aFootPaymentId;
  end UpdatePaymentCurrency;
end DOC_FOOT_PAYMENT_FUNCTIONS;
