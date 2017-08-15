--------------------------------------------------------
--  DDL for Package Body DOC_PRC_FOOT_PAYMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_FOOT_PAYMENT" 
is
  /**
  * procedure createFootPayment
  * Description
  *   Méthode permettant d'ajouter une transaction de payement direct à un document.
  */
  procedure createFootPayment(
    iFootID              in     DOC_FOOT.DOC_FOOT_ID%type
  , iJobTypeCatID        in     ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID%type
  , iFinancialCurrencyID in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , iReceivedAmount      in     DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type
  , ioPaidAmount         in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , ioReturnedAmount     in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , oFootPaymentID       out    DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  )
  is
    ltDocFootPayment              FWK_I_TYP_DEFINITION.t_crud_def;

    cursor curPayments(iFootID in DOC_FOOT.DOC_FOOT_ID%type)
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
         where FOP.DOC_FOOT_ID = iFootID
      order by FOP.DOC_FOOT_PAYMENT_ID;

    lnCountPayment                number;
    lnGasJobTypeCatPmtID          DOC_GAUGE_STRUCTURED.ACJ_JOB_TYPE_S_CAT_PMT_ID%type;
    lnGasCashMultipleTransaction  DOC_GAUGE_STRUCTURED.GAS_CASH_MULTIPLE_TRANSACTION%type;
    lvPcoDirectPay                PAC_PAYMENT_CONDITION.C_DIRECT_PAY%type;
    lnDmtFinancialCurrencyID      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lnDmtRateOfExchange           DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    lnDmtBasePrice                DOC_DOCUMENT.DMT_BASE_PRICE%type;
    lnFopExchangeRate             DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type                     default 1;
    lnFopBasePrice                DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type                        default 1;
    lnFopPaidAmount               DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type;
    lnFopPaidAmountMD             DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MD%type;
    lnFopPaidAmountMB             DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT_MB%type;
    lnFopReceivedAmount           DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type;
    lnFopReceivedAmountMD         DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MD%type;
    lnFopReceivedAmountMB         DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT_MB%type;
    lnFopReturnedAmount           DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type;
    lnFopReturnedAmountMD         DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MD%type;
    lnFopReturnedAmountMB         DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT_MB%type;
    lnFopPaidBalancedAmount       DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT%type;
    lnFopPaidBalancedAmountMD     DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    lnFopPaidBalancedAmountMB     DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MB%type;
    lnFopDiscountAmount           DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT%type;
    lnFopDiscountAmountMD         DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MD%type;
    lnFopDiscountAmountMB         DOC_FOOT_PAYMENT.FOP_DISCOUNT_AMOUNT_MB%type;
    lnFopDeductionAmount          DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT%type;
    lnFopDeductionAmountMD        DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MD%type;
    lnFopDeductionAmountMB        DOC_FOOT_PAYMENT.FOP_DEDUCTION_AMOUNT_MB%type;
    lvLastFopPaidBalancedAmountMD DOC_FOOT_PAYMENT.FOP_PAID_BALANCED_AMOUNT_MD%type;
    lnAmountPaymentDate           number;
    lnRate                        number;
    lnExchangeRate                DOC_FOOT_PAYMENT.FOP_EXCHANGE_RATE%type                     default 1;
    lnBasePrice                   DOC_FOOT_PAYMENT.FOP_BASE_PRICE%type                        default 1;
    lnDocumentRate                number;
    lnPaymentRate                 number;
    lnPaymentDocumentRate         number;
    lbDeleteAll                   boolean;
    lbUpdateBalance               boolean;
    lnFootPaymentID               DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type;
    lnJobTypeCatID                ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID%type;
    lnFootID                      DOC_FOOT.DOC_FOOT_ID%type;
    lnFinancialCurrencyID         ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    lbDeleteAll            := false;
    lnFootID               := iFootID;

    select count(FOP.DOC_FOOT_PAYMENT_ID)
      into lnCountPayment
      from DOC_FOOT_PAYMENT FOP
     where FOP.DOC_FOOT_ID = lnFootID;

    select GAS.ACJ_JOB_TYPE_S_CAT_PMT_ID
         , nvl(GAS.GAS_CASH_MULTIPLE_TRANSACTION, 0) GAS_CASH_MULTIPLE_TRANSACTION
         , nvl(PCO.C_DIRECT_PAY, '0')
      into lnGasJobTypeCatPmtID
         , lnGasCashMultipleTransaction
         , lvPcoDirectPay
      from DOC_DOCUMENT DMT
         , DOC_GAUGE_STRUCTURED GAS
         , PAC_PAYMENT_CONDITION PCO
     where DMT.DOC_DOCUMENT_ID = lnFootID
       and GAS.DOC_GAUGE_ID(+) = DMT.DOC_GAUGE_ID
       and PCO.PAC_PAYMENT_CONDITION_ID(+) = DMT.PAC_PAYMENT_CONDITION_ID;

    -- Reprend l'éventuel mode de paiement transmit.
    if iJobTypeCatID is null then
      lnJobTypeCatID  := lnGasJobTypeCatPmtID;
    else
      lnJobTypeCatID  := iJobTypeCatID;
    end if;

    lnFinancialCurrencyID  := iFinancialCurrencyID;
    lnFopReceivedAmount    := iReceivedAmount;

    if (lnCountPayment > 0) then
      -- Vérifie que la condition de paiement autorise toujours le paiement direct. Dans le cas contraire,
      -- on supprime toutes les transactions existantes.
      if     (lnGasCashMultipleTransaction = 1)
         and (lvPcoDirectPay = '0') then
        -- Demande de suppression de tous les paiements
        lbDeleteAll  := true;
      else
        lbUpdateBalance  := false;

        select FOP1.FOP_PAID_BALANCED_AMOUNT_MD
          into lvLastFopPaidBalancedAmountMD
          from DOC_FOOT_PAYMENT FOP1
         where FOP1.DOC_FOOT_ID = lnFootID
           and FOP1.DOC_FOOT_PAYMENT_ID = (select max(FOP2.DOC_FOOT_PAYMENT_ID)
                                             from DOC_FOOT_PAYMENT FOP2
                                            where FOP2.DOC_FOOT_ID = lnFootID);

        -- Récupère le montant restant à payé en monnaie du document.
        DOC_FOOT_PAYMENT_FUNCTIONS.GetBalanceAmountMD(lnFootID, lnFopPaidBalancedAmountMD);

        -- Si le montant du document a changé,
        if lnFopPaidBalancedAmountMD <> lvLastFopPaidBalancedAmountMD then
          -- on force la mise à jour du solde des paiements
          lbUpdateBalance  := true;
        end if;

        for tplPayment in curPayments(lnFootID) loop
          -- Recherche du taux de change par rapport à la date du document
          if DOC_FOOT_PAYMENT_FUNCTIONS.GetExchangeRate(tplPayment.ACS_FINANCIAL_CURRENCY_ID
                                                      , lnFootID
                                                      , lnExchangeRate
                                                      , lnBasePrice
                                                      , lnFopExchangeRate
                                                      , lnFopBasePrice
                                                      , lnDmtFinancialCurrencyID
                                                      , lnDmtRateOfExchange
                                                      , lnDmtBasePrice
                                                       ) then
            -- Détermine le cours entre la monnaie d'encaissement et la monnaie de base
            lnPaymentRate          := lnFopExchangeRate / lnFopBasePrice;
            -- Détermine le cours entre la monnaie de document et la monnaie de base
            lnDocumentRate         := lnDmtRateOfExchange / lnDmtBasePrice;
            -- Détermine le cours entre la monnaie d'encaissement et la monnaie de document
            lnPaymentDocumentRate  := lnExchangeRate / lnBasePrice;

            -- Si le taux de change est différent de celui du paiement
            if (0 <> greatest(abs(tplPayment.FOP_EXCHANGE_RATE - lnFopExchangeRate), abs(tplPayment.FOP_BASE_PRICE - lnFopBasePrice) ) ) then
              -- Met à jour les montants en monnaie de document, monnaie de base et monnaie d'encaissement suite à une modification du cours.
              DOC_FOOT_PAYMENT_FUNCTIONS.UpdatePaymentCurrency(lnDmtFinancialCurrencyID, tplPayment.DOC_FOOT_PAYMENT_ID, lnFootID);
            elsif lbUpdateBalance then
              ----
              -- Met à jour le solde du paiement dans toutes les monnaies en tenant compte des montants d'escompte et de
              -- déduction.
              --
              DOC_FOOT_PAYMENT_FUNCTIONS.UpdateBalance(tplPayment.DOC_FOOT_PAYMENT_ID
                                                     , lnFootID
                                                     , tplPayment.ACS_FINANCIAL_CURRENCY_ID
                                                     , lnDmtFinancialCurrencyID
                                                     , lnPaymentRate
                                                     , lnDocumentRate
                                                     , lnPaymentDocumentRate
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
              where DOC_FOOT_ID = lnFootID
                and FOP_PAID_BALANCED_AMOUNT < 0;

        -- Recherche du montant du document restant à encaisser en monnaie du document
        DOC_FOOT_PAYMENT_FUNCTIONS.GetBalanceAmountMD(lnFootID, lnFopPaidBalancedAmountMD);

        -- Si le montant est négatif, cela signifie que le montant du document a changé et qu'il est inférieur au
        -- montant déjà encaissé.
        if (lnFopPaidBalancedAmountMD < 0) then
          -- Demande de suppression de tous les paiements
          lbDeleteAll     := true;
          -- Demande la création du paiement par défaut
          lnCountPayment  := 0;
        end if;
      end if;

      if lbDeleteAll then
        -- Supprime toutes les transactions de paiement avec solde négatif
        delete      DOC_FOOT_PAYMENT
              where DOC_FOOT_ID = lnFootID;
      end if;
    end if;

    -- Création de la transaction d'encaissement si le montant reçu est supérieur à 0 et que les conditions d'encaissement direct sont
    -- respectés.
    if (nvl(lnFopReceivedAmount, 0) > 0) then
      if     lnJobTypeCatID is not null
         and (lnGasCashMultipleTransaction = 1)
         and (lvPcoDirectPay <> '0') then   -- Encaissement direct autorisé
        -- Initialise les données d'une nouvelle transaction d'encaissement
        DOC_FOOT_PAYMENT_FUNCTIONS.InitDataPaymentCreation(oFootPaymentID
                                                         , lnFootID
                                                         , lnFinancialCurrencyID
                                                         , lnFopExchangeRate
                                                         , lnFopBasePrice
                                                         , lnJobTypeCatID
                                                         , lnFopReceivedAmount
                                                         , lnFopReceivedAmountMD
                                                         , lnFopReceivedAmountMB
                                                         , lnFopPaidAmount
                                                         , lnFopPaidAmountMD
                                                         , lnFopPaidAmountMB
                                                         , lnFopReturnedAmount
                                                         , lnFopReturnedAmountMD
                                                         , lnFopReturnedAmountMB
                                                         , lnFopPaidBalancedAmount
                                                         , lnFopPaidBalancedAmountMD
                                                         , lnFopPaidBalancedAmountMB
                                                         , lnFopDiscountAmount
                                                         , lnFopDiscountAmountMD
                                                         , lnFopDiscountAmountMB
                                                         , lnFopDeductionAmount
                                                         , lnFopDeductionAmountMD
                                                         , lnFopDeductionAmountMB
                                                         , true
                                                          );
        -- Création de la transaction de paiment comptant
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocFootPayment, ltDocFootPayment, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'DOC_FOOT_PAYMENT_ID', oFootPaymentID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'DOC_FOOT_ID', lnFootID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'ACJ_JOB_TYPE_S_CATALOGUE_ID', lnJobTypeCatID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'ACS_FINANCIAL_CURRENCY_ID', lnFinancialCurrencyID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_EXCHANGE_RATE', lnFopExchangeRate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_BASE_PRICE', lnFopBasePrice);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_PAID_AMOUNT', lnFopPaidAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_PAID_AMOUNT_MD', lnFopPaidAmountMD);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_PAID_AMOUNT_MB', lnFopPaidAmountMB);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_RECEIVED_AMOUNT', lnFopReceivedAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_RECEIVED_AMOUNT_MD', lnFopReceivedAmountMD);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_RECEIVED_AMOUNT_MB', lnFopReceivedAmountMB);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_RETURNED_AMOUNT', lnFopReturnedAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_RETURNED_AMOUNT_MD', lnFopReturnedAmountMD);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_RETURNED_AMOUNT_MB', lnFopReturnedAmountMB);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_PAID_BALANCED_AMOUNT', lnFopPaidBalancedAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_PAID_BALANCED_AMOUNT_MD', lnFopPaidBalancedAmountMD);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_PAID_BALANCED_AMOUNT_MB', lnFopPaidBalancedAmountMB);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_DISCOUNT_AMOUNT', lnFopDiscountAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_DISCOUNT_AMOUNT_MD', lnFopDiscountAmountMD);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_DISCOUNT_AMOUNT_MB', lnFopDiscountAmountMB);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_DEDUCTION_AMOUNT', lnFopDeductionAmount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_DEDUCTION_AMOUNT_MD', lnFopDeductionAmountMD);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'FOP_DEDUCTION_AMOUNT_MB', lnFopDeductionAmountMB);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'A_DATECRE', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.InsertEntity(ltDocFootPayment);
        FWK_I_MGT_ENTITY.Release(ltDocFootPayment);
        -- Récupère les montants retourné et payé en monnaie de la transaction de payement.
        ioPaidAmount      := lnFopPaidAmount;
        ioReturnedAmount  := lnFopReturnedAmount;
      end if;
    end if;
  end createFootPayment;
end DOC_PRC_FOOT_PAYMENT;
