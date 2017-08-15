--------------------------------------------------------
--  DDL for Package Body ACT_PROCESS_PAYMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_PROCESS_PAYMENT" 
is
---------------------
  procedure InitAmounts(
    aOriginD      in     boolean
  , aNC           in     boolean
  , aAmountLC     in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmountFC     in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmountEUR    in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmount_LC_D  in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C  in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aAmount_FC_D  in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_FC_C  in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aAmount_EUR_D in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmount_EUR_C in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aSignImp      in     number default 0
  , aSignExp      in     number default 0
  )
  is
    FSign number;
  begin
    aAmount_LC_D   := 0;
    aAmount_LC_C   := 0;
    aAmount_FC_D   := 0;
    aAmount_FC_C   := 0;
    aAmount_EUR_D  := 0;
    aAmount_EUR_C  := 0;

    if aSignImp = 0 then
      if aOriginD then
        -- Imputation d'origine au débit => Crédit
        if aNC then
          aAmount_LC_C   := -aAmountLC;
          aAmount_FC_C   := -aAmountFC;
          aAmount_EUR_C  := -aAmountEUR;
        else
          aAmount_LC_C   := aAmountLC;
          aAmount_FC_C   := aAmountFC;
          aAmount_EUR_C  := aAmountEUR;
        end if;
      else
        -- Imputation d'origine au crédit => Débit
        if aNC then
          aAmount_LC_D   := -aAmountLC;
          aAmount_FC_D   := -aAmountFC;
          aAmount_EUR_D  := -aAmountEUR;
        else
          aAmount_LC_D   := aAmountLC;
          aAmount_FC_D   := aAmountFC;
          aAmount_EUR_D  := aAmountEUR;
        end if;
      end if;
    else
      FSign  := aSignImp;

      if     (aSignExp != 0)
         and (aSignExp != sign(aAmountLC) ) then
        FSign  := FSign * -1;
      end if;

      if aOriginD then
        -- Imputation d'origine au débit => Crédit
        aAmount_LC_C   := abs(aAmountLC) * FSign;
        aAmount_FC_C   := abs(aAmountFC) * FSign;
        aAmount_EUR_C  := abs(aAmountEUR) * FSign;
      else
        -- Imputation d'origine au crédit => Débit
        aAmount_LC_D   := abs(aAmountLC) * FSign;
        aAmount_FC_D   := abs(aAmountFC) * FSign;
        aAmount_EUR_D  := abs(aAmountEUR) * FSign;
      end if;
    end if;
  end InitAmounts;

-------------------------------
  procedure InitDiffChangeAmounts(
    aCust            in     boolean
  , aOriginD         in     boolean
  , aNC              in     boolean
  , aAmountLC        in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_D     in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C     in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aCollAmount_LC_D in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aCollAmount_LC_C in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  )
  is
  begin
    aAmount_LC_D      := 0;
    aAmount_LC_C      := 0;
    aCollAmount_LC_D  := 0;
    aCollAmount_LC_C  := 0;

    if aCust then   -- Clients
      if aOriginD then
--        if not aNC then
        if aAmountLC > 0 then   -- R3
          aAmount_LC_D      := aAmountLC;
          aCollAmount_LC_C  := aAmountLC;
        else   -- R4
          aAmount_LC_C      := -aAmountLC;
          aCollAmount_LC_D  := -aAmountLC;
        end if;
--        end if;
      else
--        if aNC then
        if aAmountLC > 0 then   -- R5
          aAmount_LC_D      := aAmountLC;
          aCollAmount_LC_C  := aAmountLC;
        else   -- R6
          aAmount_LC_C      := -aAmountLC;
          aCollAmount_LC_D  := -aAmountLC;
        end if;
--        end if;
      end if;
    else   -- Créanciers
      if aOriginD then
--        if aNC then
        if aAmountLC > 0 then   -- R9
          aAmount_LC_C      := aAmountLC;
          aCollAmount_LC_D  := aAmountLC;
        else   -- R10
          aAmount_LC_D      := -aAmountLC;
          aCollAmount_LC_C  := -aAmountLC;
        end if;
--        end if;
      else
--        if not aNC then
        if aAmountLC > 0 then   -- R15
          aAmount_LC_C      := aAmountLC;
          aCollAmount_LC_D  := aAmountLC;
        else   -- R16
          aAmount_LC_D      := -aAmountLC;
          aCollAmount_LC_C  := -aAmountLC;
        end if;
--        end if;
      end if;
    end if;
  end InitDiffChangeAmounts;

----------------------------
  function GetChargesAccountId(aACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type)
    return ACS_SUB_SET.ACS_CHARGES_ACCOUNT_ID%type
  is
    ChargesAccountId ACS_SUB_SET.ACS_CHARGES_ACCOUNT_ID%type;
  begin
    select ACS_CHARGES_ACCOUNT_ID
      into ChargesAccountId
      from ACS_SUB_SET SUB
         , ACS_ACCOUNT ACC
     where ACC.ACS_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
       and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID;

    if ChargesAccountId is null then
      raise_application_error(-20000, 'PCS - CHARGES AMOUNT - ACCOUNT UNDEFINED');
    end if;

    return ChargesAccountId;
  end GetChargesAccountId;

-------------------------------
  function GetDiffExchangeAccount(
    aCust                      number
  , aDET_DIFF_EXCHANGE         ACT_DET_PAYMENT.DET_DIFF_EXCHANGE%type
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  )
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    AccountId         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CustGainAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CustLossAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SuppGainAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SuppLossAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if PCS.PC_CONFIG.GetConfig('ACS_EFF_DIFF_DEFAULT') = 1 then
      --Comptes définis en Résultat financier
      AccountId := GetDiffExcFinancialAcc(aCust, aDET_DIFF_EXCHANGE, aACS_FINANCIAL_CURRENCY_ID);
      ln_UseDiffFinAccount := 1;
    else
      --Comptes définis en Résultat d'exploitation (Default)
      AccountId := GetDiffExcOperatingAcc(aCust, aDET_DIFF_EXCHANGE, aACS_FINANCIAL_CURRENCY_ID);
      ln_UseDiffFinAccount := 0;
    end if;
    return AccountId;
  end GetDiffExchangeAccount;

  function GetDiffExcOperatingAcc(
    aCust                      number
  , aDET_DIFF_EXCHANGE         ACT_DET_PAYMENT.DET_DIFF_EXCHANGE%type
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  )
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    AccountId         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CustGainAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CustLossAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SuppGainAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SuppLossAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    select ACS_GAIN_EXCH_EFFECT_ID
         , ACS_PAY_EFF_GAIN_ID
         , ACS_LOSS_EXCH_EFFECT_ID
         , ACS_PAY_EFF_LOSS_ID
      into CustGainAccountId
         , SuppGainAccountId
         , CustLossAccountId
         , SuppLossAccountId
      from ACS_FINANCIAL_CURRENCY
     where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;

    if aCust = 1 then
      if aDET_DIFF_EXCHANGE < 0 then
        AccountId  := CustGainAccountId;
      else
        AccountId  := CustLossAccountId;
      end if;
    else
      if aDET_DIFF_EXCHANGE < 0 then
        AccountId  := SuppLossAccountId;
      else
        AccountId  := SuppGainAccountId;
      end if;
    end if;

    if AccountId is null then
      raise_application_error(-20000, 'PCS - DIFFERENCE EXCHANGE AMOUNT - ACCOUNT UNDEFINED');
    end if;

    return AccountId;
  end GetDiffExcOperatingAcc;

  -- Retourne le compte de diff de change --Résultat financier--
  function GetDiffExcFinancialAcc(
    aCust                      number
  , aDET_DIFF_EXCHANGE         ACT_DET_PAYMENT.DET_DIFF_EXCHANGE%type
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  )
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    AccountId         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CustGainAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CustLossAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SuppGainAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SuppLossAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    select ACS_GAIN_EXCH_EFFECT_F_ID
         , ACS_PAY_EFF_GAIN_F_ID
         , ACS_LOSS_EXCH_EFFECT_F_ID
         , ACS_PAY_EFF_LOSS_F_ID
      into CustGainAccountId
         , SuppGainAccountId
         , CustLossAccountId
         , SuppLossAccountId
      from ACS_FINANCIAL_CURRENCY
     where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;

    if aCust = 1 then
      if aDET_DIFF_EXCHANGE < 0 then
        AccountId  := CustGainAccountId;
      else
        AccountId  := CustLossAccountId;
      end if;
    else
      if aDET_DIFF_EXCHANGE < 0 then
        AccountId  := SuppLossAccountId;
      else
        AccountId  := SuppGainAccountId;
      end if;
    end if;

    if AccountId is null then
      raise_application_error(-20000, 'PCS - DIFFERENCE EXCHANGE AMOUNT - ACCOUNT UNDEFINED');
    end if;

    return AccountId;
  end GetDiffExcFinancialAcc;

---------------------------------------
  procedure CreateMANImputForDiffExchange(
    aCust                          number
  , aACS_FINANCIAL_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID     ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_PERIOD_ID                 ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , aACT_DOCUMENT_ID               ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID   ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aIMM_TYPE                      ACT_MGM_IMPUTATION.IMM_TYPE%type
  , aIMM_GENRE                     ACT_MGM_IMPUTATION.IMM_GENRE%type
  , aIMM_DESCRIPTION               ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type
  , aIMM_PRIMARY                   ACT_MGM_IMPUTATION.IMM_PRIMARY%type
  , aIMM_AMOUNT_LC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type
  , aIMM_AMOUNT_LC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type
  , aIMM_EXCHANGE_RATE             ACT_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type
  , aIMM_BASE_PRICE                ACT_MGM_IMPUTATION.IMM_BASE_PRICE%type
  , aIMM_AMOUNT_FC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type
  , aIMM_AMOUNT_FC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type
  , aIMM_AMOUNT_EUR_D              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type
  , aIMM_AMOUNT_EUR_C              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type
  , aIMM_VALUE_DATE                ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type
  , aIMM_TRANSACTION_DATE          ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type
  , aACS_AUXILIARY_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aA_IDCRE                       ACT_MGM_IMPUTATION.A_IDCRE%type
  )
  is
    CpnAccountId       ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    QtyAccountId       ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    tblMgmImputations  ACT_CREATION_SBVR.tblMgmImputationsTyp;
    tblMgmDistribution ACT_CREATION_SBVR.tblMgmDistributionTyp;
  -----
  begin
    CpnAccountId  := ACT_CREATION_SBVR.GetCPNAccOfFINAcc(aACS_FINANCIAL_ACCOUNT_ID);

    if CpnAccountId is not null then
      -- aType : -- 4: Diff de change - client
                 -- 5: Diff de change + client
                 -- 6: Diff de change - Fournisseur
                 -- 7: Diff de change + Fournisseur
      if aCust = 1 then   -- Débiteurs
        if aIMM_AMOUNT_LC_C <> 0 then
          ACT_CREATION_SBVR.GetMgmAccounts(CpnAccountId
                                         , null
                                         , aACS_FINANCIAL_CURRENCY_ID
                                         , null
                                         , QtyAccountId
                                         , tblMgmImputations
                                         , tblMgmDistribution
                                         , 5
                                          );   -- Gain
        else
          ACT_CREATION_SBVR.GetMgmAccounts(CpnAccountId
                                         , null
                                         , aACS_FINANCIAL_CURRENCY_ID
                                         , null
                                         , QtyAccountId
                                         , tblMgmImputations
                                         , tblMgmDistribution
                                         , 4
                                          );   -- Perte
        end if;
      else   -- Fournisseurs
        if aIMM_AMOUNT_LC_C <> 0 then
          ACT_CREATION_SBVR.GetMgmAccounts(CpnAccountId
                                         , null
                                         , aACS_FINANCIAL_CURRENCY_ID
                                         , null
                                         , QtyAccountId
                                         , tblMgmImputations
                                         , tblMgmDistribution
                                         , 7
                                          );   -- Gain
        else
          ACT_CREATION_SBVR.GetMgmAccounts(CpnAccountId
                                         , null
                                         , aACS_FINANCIAL_CURRENCY_ID
                                         , null
                                         , QtyAccountId
                                         , tblMgmImputations
                                         , tblMgmDistribution
                                         , 6
                                          );   -- Perte
        end if;
      end if;

      ACT_CREATION_SBVR.CreateMANImputations(aACS_FINANCIAL_ACCOUNT_ID
                                           , CpnAccountId
                                           , QtyAccountId
                                           , tblMgmImputations
                                           , tblMgmDistribution
                                           , aACS_FINANCIAL_CURRENCY_ID
                                           , aACS_ACS_FINANCIAL_CURRENCY_ID
                                           , aACS_PERIOD_ID
                                           , aACT_DOCUMENT_ID
                                           , aACT_FINANCIAL_IMPUTATION_ID
                                           , aIMM_TYPE
                                           , aIMM_GENRE
                                           , aIMM_DESCRIPTION
                                           , aIMM_PRIMARY
                                           , aIMM_AMOUNT_LC_D
                                           , aIMM_AMOUNT_LC_C
                                           , aIMM_EXCHANGE_RATE
                                           , aIMM_BASE_PRICE
                                           , aIMM_AMOUNT_FC_D
                                           , aIMM_AMOUNT_FC_C
                                           , aIMM_AMOUNT_EUR_D
                                           , aIMM_AMOUNT_EUR_C
                                           , aIMM_VALUE_DATE
                                           , aIMM_TRANSACTION_DATE
                                           , aA_IDCRE
                                            );
    end if;
  end CreateMANImputForDiffExchange;

  procedure CreateMANImput_F(
    aCust                          number
  , aACS_FINANCIAL_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID     ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_PERIOD_ID                 ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , aACT_DOCUMENT_ID               ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID   ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aIMM_TYPE                      ACT_MGM_IMPUTATION.IMM_TYPE%type
  , aIMM_GENRE                     ACT_MGM_IMPUTATION.IMM_GENRE%type
  , aIMM_DESCRIPTION               ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type
  , aIMM_PRIMARY                   ACT_MGM_IMPUTATION.IMM_PRIMARY%type
  , aIMM_AMOUNT_LC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type
  , aIMM_AMOUNT_LC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type
  , aIMM_EXCHANGE_RATE             ACT_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type
  , aIMM_BASE_PRICE                ACT_MGM_IMPUTATION.IMM_BASE_PRICE%type
  , aIMM_AMOUNT_FC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type
  , aIMM_AMOUNT_FC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type
  , aIMM_AMOUNT_EUR_D              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type
  , aIMM_AMOUNT_EUR_C              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type
  , aIMM_VALUE_DATE                ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type
  , aIMM_TRANSACTION_DATE          ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type
  , aACS_AUXILIARY_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aA_IDCRE                       ACT_MGM_IMPUTATION.A_IDCRE%type
  )
  is
    CpnAccountId       ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    QtyAccountId       ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    tblMgmImputations  ACT_CREATION_SBVR.tblMgmImputationsTyp;
    tblMgmDistribution ACT_CREATION_SBVR.tblMgmDistributionTyp;
  -----
  begin
    CpnAccountId  := ACT_CREATION_SBVR.GetCPNAccOfFINAcc(aACS_FINANCIAL_ACCOUNT_ID);

    if CpnAccountId is not null then
      -- aType : -- 4: Diff de change - client
                 -- 5: Diff de change + client
                 -- 6: Diff de change - Fournisseur
                 -- 7: Diff de change + Fournisseur
      if aCust = 1 then   -- Débiteurs
        if aIMM_AMOUNT_LC_C <> 0 then
          ACT_CREATION_SBVR.GetMgmAccounts_F(CpnAccountId
                                         , aACS_FINANCIAL_CURRENCY_ID
                                         , QtyAccountId
                                         , tblMgmImputations
                                         , tblMgmDistribution
                                         , 5
                                          );   -- Gain
        else
          ACT_CREATION_SBVR.GetMgmAccounts_F(CpnAccountId
                                         , aACS_FINANCIAL_CURRENCY_ID
                                         , QtyAccountId
                                         , tblMgmImputations
                                         , tblMgmDistribution
                                         , 4
                                          );   -- Perte
        end if;
      else   -- Fournisseurs
        if aIMM_AMOUNT_LC_C <> 0 then
          ACT_CREATION_SBVR.GetMgmAccounts_F(CpnAccountId
                                         , aACS_FINANCIAL_CURRENCY_ID
                                         , QtyAccountId
                                         , tblMgmImputations
                                         , tblMgmDistribution
                                         , 7
                                          );   -- Gain
        else
          ACT_CREATION_SBVR.GetMgmAccounts_F(CpnAccountId
                                         , aACS_FINANCIAL_CURRENCY_ID
                                         , QtyAccountId
                                         , tblMgmImputations
                                         , tblMgmDistribution
                                         , 6
                                          );   -- Perte
        end if;
      end if;

      ACT_CREATION_SBVR.CreateMANImputations(aACS_FINANCIAL_ACCOUNT_ID
                                           , CpnAccountId
                                           , QtyAccountId
                                           , tblMgmImputations
                                           , tblMgmDistribution
                                           , aACS_FINANCIAL_CURRENCY_ID
                                           , aACS_ACS_FINANCIAL_CURRENCY_ID
                                           , aACS_PERIOD_ID
                                           , aACT_DOCUMENT_ID
                                           , aACT_FINANCIAL_IMPUTATION_ID
                                           , aIMM_TYPE
                                           , aIMM_GENRE
                                           , aIMM_DESCRIPTION
                                           , aIMM_PRIMARY
                                           , aIMM_AMOUNT_LC_D
                                           , aIMM_AMOUNT_LC_C
                                           , aIMM_EXCHANGE_RATE
                                           , aIMM_BASE_PRICE
                                           , aIMM_AMOUNT_FC_D
                                           , aIMM_AMOUNT_FC_C
                                           , aIMM_AMOUNT_EUR_D
                                           , aIMM_AMOUNT_EUR_C
                                           , aIMM_VALUE_DATE
                                           , aIMM_TRANSACTION_DATE
                                           , aA_IDCRE
                                            );
    end if;
  end CreateMANImput_F;
--------------------------------
  function DiffExchangeImputations(
    aCust                        number
  , aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACT_DOCUMENT_ID2            ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID               ACS_PERIOD.ACS_PERIOD_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACT_DET_PAYMENT_ID          ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_EXCHANGE_RATE           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aCollAmount_LC_D             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aCollAmount_LC_C             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aA_IDCRE                     ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aACT_PART_IMPUTATION_ID      ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  )
    return ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  is
    FinImputationId  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinImputationId2 ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinAccountId     ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputationId
      from dual;

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
               , IMF_AMOUNT_FC_D
               , IMF_AMOUNT_FC_C
               , IMF_AMOUNT_EUR_D
               , IMF_AMOUNT_EUR_C
               , IMF_VALUE_DATE
               , ACS_TAX_CODE_ID
               , IMF_TRANSACTION_DATE
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACT_DET_PAYMENT_ID
               , IMF_GENRE
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputationId
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , aACS_FINANCIAL_ACCOUNT_ID
               , 'MAN'
               , 0
               , aDescription
               , aAmount_LC_D
               , aAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , 0
               ,   -- aAmount_FC_D,
                 0
               ,   -- aAmount_FC_C,
                 0
               ,   -- aAmount_EUR_D,
                 0
               ,   -- aAmount_EUR_C,
                 aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , null
               , aACT_DET_PAYMENT_ID
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , aF_ACS_FINANCIAL_CURRENCY_ID
               , 4
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    ACT_CREATION_SBVR.UpdateInfoImpIMF(FinImputationId);
    --L'axe dossier ne doit pas être imputé sur les imputations de diff. de change.
    --remise à zéro par imputation...et non pas directement dans le type infoImpImf car
    -- il se peut qu'une autre imputation ( qui n'est pas une diff. de change ) utilise le dossier
    if (ln_ResetHedgeRecord = 1) then
      ACT_CREATION_SBVR.ResetImfDocRecordId(FinImputationId);
    end if;

    ACT_CREATION_SBVR.CREATE_FIN_DISTRI_BVR(FinImputationId
                                          , aDescription
                                          , aAmount_LC_D
                                          , aAmount_LC_C
                                          , 0
                                          ,   -- aAmount_FC_D,
                                            0
                                          ,   -- aAmount_FC_C,
                                            0
                                          ,   -- aAmount_EUR_D,
                                            0
                                          ,   -- aAmount_EUR_C,
                                            aACS_FINANCIAL_ACCOUNT_ID
                                          , aACS_AUXILIARY_ACCOUNT_ID
                                          ,   -- aACS_AUXILIARY_ACCOUNT_ID,
                                            aACT_DOCUMENT_ID2
                                          ,   -- aACT_DOCUMENT_ID2,
                                            aA_IDCRE
                                          , aIMF_TRANSACTION_DATE
                                          , 1
                                           );

    if ACT_CREATION_SBVR.ExistMAN <> 0 then
      if ln_UseDiffFinAccount = 0 then
        CreateMANImputForDiffExchange(aCust
                                    , aACS_FINANCIAL_ACCOUNT_ID
                                    , aACS_FINANCIAL_CURRENCY_ID
                                    , aF_ACS_FINANCIAL_CURRENCY_ID
                                    , aACS_PERIOD_ID
                                    , aACT_DOCUMENT_ID
                                    , FinImputationId
                                    , 'MAN'
                                    , 'STD'
                                    , aDescription
                                    , 0
                                    , aAmount_LC_D
                                    , aAmount_LC_C
                                    , aIMF_EXCHANGE_RATE
                                    , aIMF_BASE_PRICE
                                    , 0
                                    ,   -- aAmount_FC_D,
                                      0
                                    ,   -- aAmount_FC_C,
                                      0
                                    ,   -- aAmount_EUR_D,
                                      0
                                    ,   -- aAmount_EUR_C,
                                      aIMF_TRANSACTION_DATE
                                    , aIMF_VALUE_DATE
                                    , aACS_AUXILIARY_ACCOUNT_ID
                                    , aA_IDCRE
                                     );
      elsif ln_UseDiffFinAccount = 1 then
        CreateMANImput_F(aCust
                        , aACS_FINANCIAL_ACCOUNT_ID
                        , aACS_FINANCIAL_CURRENCY_ID
                        , aF_ACS_FINANCIAL_CURRENCY_ID
                        , aACS_PERIOD_ID
                        , aACT_DOCUMENT_ID
                        , FinImputationId
                        , 'MAN'
                        , 'STD'
                        , aDescription
                        , 0
                        , aAmount_LC_D
                        , aAmount_LC_C
                        , aIMF_EXCHANGE_RATE
                        , aIMF_BASE_PRICE
                        , 0
                        ,   -- aAmount_FC_D,
                          0
                        ,   -- aAmount_FC_C,
                          0
                        ,   -- aAmount_EUR_D,
                          0
                        ,   -- aAmount_EUR_C,
                          aIMF_TRANSACTION_DATE
                        , aIMF_VALUE_DATE
                        , aACS_AUXILIARY_ACCOUNT_ID
                        , aA_IDCRE
                         );
      end if;
    end if;

    FinAccountId  := ACT_CREATION_SBVR.GetFinAccount_id(aACS_AUXILIARY_ACCOUNT_ID, aACT_DOCUMENT_ID2);

    select init_id_seq.nextval
      into FinImputationId2
      from dual;

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
               , IMF_AMOUNT_FC_D
               , IMF_AMOUNT_FC_C
               , IMF_AMOUNT_EUR_D
               , IMF_AMOUNT_EUR_C
               , IMF_VALUE_DATE
               , ACS_TAX_CODE_ID
               , IMF_TRANSACTION_DATE
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACT_DET_PAYMENT_ID
               , IMF_GENRE
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputationId2
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , FinAccountId
               , 'MAN'
               ,   -- 'AUX'
                 0
               , aDescription
               , aCollAmount_LC_D
               , aCollAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , 0
               ,   -- Amount_FC_D,
                 0
               ,   -- Amount_FC_C,
                 0
               ,   -- Amount_EUR_D,
                 0
               ,   -- Amount_EUR_C,
                 aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , aACS_AUXILIARY_ACCOUNT_ID
               , aACT_DET_PAYMENT_ID
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , aF_ACS_FINANCIAL_CURRENCY_ID
               , 4
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    ACT_CREATION_SBVR.UpdateInfoImpIMF(FinImputationId2);

    --L'axe dossier ne doit pas être imputé sur les imputations de diff. de change.
    --remise à zéro par imputation...et non pas directement dans le type infoImpImf car
    -- il se peut qu'une autre imputation ( qui n'est pas une diff. de change ) utilise le dossier
    if (ln_ResetHedgeRecord = 1) then
      ACT_CREATION_SBVR.ResetImfDocRecordId(FinImputationId);
    end if;

    ACT_CREATION_SBVR.CREATE_FIN_DISTRI_BVR(FinImputationId2
                                          , aDescription
                                          , aCollAmount_LC_D
                                          , aCollAmount_LC_C
                                          , 0
                                          ,   -- Amount_FC_D,
                                            0
                                          ,   -- Amount_FC_C,
                                            0
                                          ,   -- Amount_EUR_D,
                                            0
                                          ,   -- Amount_EUR_C,
                                            FinAccountId
                                          , aACS_AUXILIARY_ACCOUNT_ID
                                          , aACT_DOCUMENT_ID2
                                          , aA_IDCRE
                                          , aIMF_TRANSACTION_DATE
                                          , 1
                                           );
    return FinImputationId;
  end DiffExchangeImputations;

---------------------------
  function ChargesImputation(
    aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID               ACS_PERIOD.ACS_PERIOD_ID%type
  , aACT_DET_PAYMENT_ID          ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_EXCHANGE_RATE           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_FC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aAmount_EUR_D                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmount_EUR_C                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_FIN_ACC_S_PAYMENT_ID    ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aA_IDCRE                     ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aACT_PART_IMPUTATION_ID      ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aOriginDocumentId            ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  )
    return ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  is
    FinImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinAccountId    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputationId
      from dual;

    FinAccountId  := GetChargesAccountId(aACS_AUXILIARY_ACCOUNT_ID);

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
               , IMF_AMOUNT_FC_D
               , IMF_AMOUNT_FC_C
               , IMF_AMOUNT_EUR_D
               , IMF_AMOUNT_EUR_C
               , IMF_VALUE_DATE
               , ACS_TAX_CODE_ID
               , IMF_TRANSACTION_DATE
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACT_DET_PAYMENT_ID
               , IMF_GENRE
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputationId
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , FinAccountId
               , 'MAN'
               , 0
               , aDescription
               , aAmount_LC_D
               , aAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , aAmount_FC_D
               , aAmount_FC_C
               , aAmount_EUR_D
               , aAmount_EUR_C
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , null
               , aACT_DET_PAYMENT_ID
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , AF_ACS_FINANCIAL_CURRENCY_ID
               , 6
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    ACT_CREATION_SBVR.UpdateInfoImpIMF(FinImputationId);
    ACT_CREATION_SBVR.CREATE_FIN_DISTRI_BVR(FinImputationId
                                          , aDescription
                                          , aAmount_LC_D
                                          , aAmount_LC_C
                                          , aAmount_FC_D
                                          , aAmount_FC_C
                                          , aAmount_EUR_D
                                          , aAmount_EUR_C
                                          , FinAccountId
                                          , aACS_AUXILIARY_ACCOUNT_ID
                                          ,   -- aACS_AUXILIARY_ACCOUNT_ID,
                                            aOriginDocumentId
                                          ,   -- aACT_DOCUMENT_ID2,
                                            aA_IDCRE
                                          , aIMF_TRANSACTION_DATE
                                          , 1
                                           );

    if ACT_CREATION_SBVR.ExistMAN <> 0 then
      ACT_CREATION_SBVR.CreateMANImputForCharges(FinAccountId
                                               , aACS_FINANCIAL_CURRENCY_ID
                                               , aF_ACS_FINANCIAL_CURRENCY_ID
                                               , aACS_PERIOD_ID
                                               , aACT_DOCUMENT_ID
                                               , FinImputationId
                                               , 'MAN'
                                               , 'STD'
                                               , aDescription
                                               , 0
                                               , aAmount_LC_D
                                               , aAmount_LC_C
                                               , aIMF_EXCHANGE_RATE
                                               , aIMF_BASE_PRICE
                                               , aAmount_FC_D
                                               , aAmount_FC_C
                                               , aAmount_EUR_D
                                               , aAmount_EUR_C
                                               , aIMF_TRANSACTION_DATE
                                               , aIMF_VALUE_DATE
                                               , aACS_AUXILIARY_ACCOUNT_ID
                                               , aOriginDocumentId
                                               , aA_IDCRE
                                                );
    end if;

    return FinImputationId;
  end ChargesImputation;

-----------------------------
  procedure DiffRoundImputation(
    aCust                        number
  , aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACT_DOCUMENT_ID2            ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID               ACS_PERIOD.ACS_PERIOD_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACT_DET_PAYMENT_ID          ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_EXCHANGE_RATE           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_FC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aAmount_EUR_D                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmount_EUR_C                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aA_IDCRE                     ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aACT_PART_IMPUTATION_ID      ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  )
  is
    FinImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputationId
      from dual;

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
               , IMF_AMOUNT_FC_D
               , IMF_AMOUNT_FC_C
               , IMF_AMOUNT_EUR_D
               , IMF_AMOUNT_EUR_C
               , IMF_VALUE_DATE
               , ACS_TAX_CODE_ID
               , IMF_TRANSACTION_DATE
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACT_DET_PAYMENT_ID
               , IMF_GENRE
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputationId
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , aACS_FINANCIAL_ACCOUNT_ID
               , 'MAN'
               , 0
               , aDescription
               , aAmount_LC_D
               , aAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , aAmount_FC_D
               , aAmount_FC_C
               , aAmount_EUR_D
               , aAmount_EUR_C
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , null
               , aACT_DET_PAYMENT_ID
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , aF_ACS_FINANCIAL_CURRENCY_ID
               , 7
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    ACT_CREATION_SBVR.CREATE_FIN_DISTRI_BVR(FinImputationId
                                          , aDescription
                                          , aAmount_LC_D
                                          , aAmount_LC_C
                                          , aAmount_FC_D
                                          , aAmount_FC_C
                                          , aAmount_EUR_D
                                          , aAmount_EUR_C
                                          , aACS_FINANCIAL_ACCOUNT_ID
                                          , aACS_AUXILIARY_ACCOUNT_ID
                                          ,   -- aACS_AUXILIARY_ACCOUNT_ID,
                                            aACT_DOCUMENT_ID2
                                          ,   -- aACT_DOCUMENT_ID2,
                                            aA_IDCRE
                                          , aIMF_TRANSACTION_DATE
                                          , 1
                                           );

    if ACT_CREATION_SBVR.ExistMAN <> 0 then
      CreateMANImputForDiffExchange(aCust
                                  , aACS_FINANCIAL_ACCOUNT_ID
                                  , aACS_FINANCIAL_CURRENCY_ID
                                  , aF_ACS_FINANCIAL_CURRENCY_ID
                                  , aACS_PERIOD_ID
                                  , aACT_DOCUMENT_ID
                                  , FinImputationId
                                  , 'MAN'
                                  , 'STD'
                                  , aDescription
                                  , 0
                                  , aAmount_LC_D
                                  , aAmount_LC_C
                                  , aIMF_EXCHANGE_RATE
                                  , aIMF_BASE_PRICE
                                  , aAmount_FC_D
                                  , aAmount_FC_C
                                  , aAmount_EUR_D
                                  , aAmount_EUR_C
                                  , aIMF_TRANSACTION_DATE
                                  , aIMF_VALUE_DATE
                                  , aACS_AUXILIARY_ACCOUNT_ID
                                  , aA_IDCRE
                                   );
    end if;
  end DiffRoundImputation;

------------------
  function DiffRound(
    aCust            number
  , aIMF_AMOUNT_LC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aIMF_AMOUNT_LC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_AMOUNT_FC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aIMF_AMOUNT_FC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aTotalPaied_LC   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aTotalPaied_FC   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  )
    return ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  is
    DiffAmount ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type   := 0;
  begin
    if aCust = 1 then
      if     ( (aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C) <> 0)
         and (aTotalPaied_FC =(aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C) ) then
        if aTotalPaied_LC <>(aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C) then
          DiffAmount  := aTotalPaied_LC -(aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C);
        end if;
      end if;
    else
      if     (aIMF_AMOUNT_LC_C - aIMF_AMOUNT_LC_D) <> 0
         and (aTotalPaied_FC =(aIMF_AMOUNT_FC_C - aIMF_AMOUNT_FC_D) ) then
        if aTotalPaied_LC <>(aIMF_AMOUNT_LC_C - aIMF_AMOUNT_LC_D) then
          DiffAmount  := aTotalPaied_LC -(aIMF_AMOUNT_LC_C - aIMF_AMOUNT_LC_D);
        end if;
      end if;
    end if;

    return DiffAmount;
  end DiffRound;

------------------------
  procedure ProcessPayment(
    aACT_DOCUMENT_ID               ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID                 ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type
  , aIMF_TRANSACTION_DATE          ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE                ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aACS_FINANCIAL_CURRENCY_ID     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aIMF_AMOUNT_LC_D               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aIMF_AMOUNT_LC_C               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_AMOUNT_FC_D               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aIMF_AMOUNT_FC_C               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aIMF_DESCRIPTION               ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  )
  is
    cursor DetPaymentCursor(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   DET.*
             , PAR.PAC_CUSTOM_PARTNER_ID
             , PAR.PAC_SUPPLIER_PARTNER_ID
             , nvl(PAR.PAR_EXCHANGE_RATE, 0) PAR_EXCHANGE_RATE
             , nvl(PAR.PAR_BASE_PRICE, 0) PAR_BASE_PRICE
             , nvl(PAR.PAR_CHARGES_LC, 0) PAR_CHARGES_LC
             , nvl(PAR.PAR_CHARGES_FC, 0) PAR_CHARGES_FC
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
          from ACT_PART_IMPUTATION PAR
             , ACT_DET_PAYMENT DET
         where DET.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and DET.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
      order by DET.ACT_PART_IMPUTATION_ID asc;

    cursor PartImputCursor(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   PAR.ACT_PART_IMPUTATION_ID
             , PAR.PAC_CUSTOM_PARTNER_ID
             , PAR.PAC_SUPPLIER_PARTNER_ID
             , nvl(PAR.PAR_EXCHANGE_RATE, 0) PAR_EXCHANGE_RATE
             , nvl(PAR.PAR_BASE_PRICE, 0) PAR_BASE_PRICE
             , nvl(PAR.PAR_CHARGES_LC, 0) PAR_CHARGES_LC
             , nvl(PAR.PAR_CHARGES_FC, 0) PAR_CHARGES_FC
             , nvl(PAR.PAR_PAIED_CHARGES_LC, 0) PAR_PAIED_CHARGES_LC
             , nvl(PAR.PAR_PAIED_CHARGES_FC, 0) PAR_PAIED_CHARGES_FC
             , nvl(PAR.PAR_PAIED_INTEREST_LC, 0) PAR_PAIED_INTEREST_LC
             , nvl(PAR.PAR_PAIED_INTEREST_FC, 0) PAR_PAIED_INTEREST_FC
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
          from ACT_PART_IMPUTATION PAR
         where PAR.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
      order by PAR.ACT_PART_IMPUTATION_ID asc;

    -- Recherche des infos sur le document à payer
    cursor ExpiryDocumentCursor(aACT_EXPIRY_ID ACT_EXPIRY.ACT_EXPIRY_ID%type)
    is
      select DOC.*
           , CAT.C_TYPE_CATALOGUE
           , exp.ACT_PART_IMPUTATION_ID
           , sign(exp.EXP_AMOUNT_LC) SignExp
           , IMF.IMF_EXCHANGE_RATE
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_EXPIRY exp
           , ACT_FINANCIAL_IMPUTATION IMF
       where exp.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and exp.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and IMF.IMF_PRIMARY = 1
         and rownum = 1;

    DetPaymentTuple               DetPaymentCursor%rowtype;
    PartImputTuple                PartImputCursor%rowtype;
    ExpiryDocumentTuple           ExpiryDocumentCursor%rowtype;
    DetPaymentTupleDiffRound      DetPaymentCursor%rowtype;
    DocumentTuple                 ACT_DOCUMENT%rowtype;
--    PrimaryImputationTuple     ACT_FINANCIAL_IMPUTATION%rowtype;
    CustomPartnerTuple            PAC_CUSTOM_PARTNER%rowtype;
    SupplierPartnerTuple          PAC_SUPPLIER_PARTNER%rowtype;
    Cust                          number;
    AuxAccountId                  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    FinAccountId                  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    FinImputationId               ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    CatExtVAT                     ACJ_CATALOGUE_DOCUMENT.CAT_EXT_VAT%type;
    CatExtVATDiscount             ACJ_CATALOGUE_DOCUMENT.CAT_EXT_VAT_DISCOUNT%type;
    UserIni                       PCS.PC_USER.USE_INI%type;
    PaymentDescription            ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    ChargesDescription            ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    DiscountDescription           ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    DeductionDescription          ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    DiffExchangeDescription       ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    DiffRoundDescription          ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatChargesDescription         ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatDiscountDescription        ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatDeductionDescription       ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatDiffExchangeDescription    ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatEncashmentDescription      ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatReminderChargesDescription ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    ReminderChargesDescription    ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    ReminderInterestDescription   ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    TotDiscountLC                 ACT_DET_PAYMENT.DET_DISCOUNT_LC%type;
    TotDiscountFC                 ACT_DET_PAYMENT.DET_DISCOUNT_FC%type;
    TotDiscountEUR                ACT_DET_PAYMENT.DET_DISCOUNT_EUR%type;
    TotDeductionLC                ACT_DET_PAYMENT.DET_DEDUCTION_LC%type;
    TotDeductionFC                ACT_DET_PAYMENT.DET_DEDUCTION_FC%type;
    TotDeductionEUR               ACT_DET_PAYMENT.DET_DEDUCTION_EUR%type;
    TotalPaied_LC                 ACT_DET_PAYMENT.DET_PAIED_LC%type;
    TotalPaied_FC                 ACT_DET_PAYMENT.DET_PAIED_FC%type;
    Amount_LC_D                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    Amount_LC_C                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    Amount_FC_D                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    Amount_FC_C                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    Amount_EUR_D                  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    Amount_EUR_C                  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    CollAmount_LC_D               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    CollAmount_LC_C               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    AmountLC                      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountFC                      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountEUR                     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    CatDescription                ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type;
    OriginD                       boolean;
    NC                            boolean;
    NegativeDeduction             boolean;
    SignImp                       number;
    LastPartImputationId          ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    tblCalcVATEncashment          ACT_VAT_MANAGEMENT.tblCalcVATEncashmentType;
    Flag                          boolean                                                     := true;
    BaseInfoRec                   ACT_VAT_MANAGEMENT.BaseInfoRecType;
    InfoVATRec                    ACT_VAT_MANAGEMENT.InfoVATRecType;
    CalcVATRec                    ACT_VAT_MANAGEMENT.CalcVATRecType;
    const_BaseInfoRec             ACT_VAT_MANAGEMENT.BaseInfoRecType;
    const_InfoVATRec              ACT_VAT_MANAGEMENT.InfoVATRecType;
    const_CalcVATRec              ACT_VAT_MANAGEMENT.CalcVATRecType;
    ChargeFinAccountId            ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    ChargeVATAccId                ACS_TAX_CODE.ACS_TAX_CODE_ID%type                           := null;
    vReminderPartImputationId     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    vReminderCategId              PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type;
    vReminderChargesTaxCodeId     ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    vReminderDocNumber            ACT_DOCUMENT.DOC_NUMBER%type;
    vReminderChargesLC            ACT_PART_IMPUTATION.PAR_CHARGES_LC%type;
    vReminderInterestLC           ACT_PART_IMPUTATION.PAR_INTEREST_LC%type;
    vReminderChargesFC            ACT_PART_IMPUTATION.PAR_CHARGES_FC%type;
    vReminderInterestFC           ACT_PART_IMPUTATION.PAR_INTEREST_FC%type;
    vExistsReminder               integer;
    ln_RateToApply                ACT_EXPIRY_SELECTION.EXS_EXCHANGE_RATE%type;
  -----
  begin
    UserIni                     := PCS.PC_I_LIB_SESSION.GetUserIni;
    CatExtVAT                   := ACT_CREATION_SBVR.ExtVatOnDeduction(aACT_DOCUMENT_ID, CatExtVATDiscount);

    -- Recherche des infos sur le document
    select *
      into DocumentTuple
      from ACT_DOCUMENT
     where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;


    if    aIMF_DESCRIPTION is null
       or aIMF_DESCRIPTION = '' then
      CatDescription  := ACT_FUNCTIONS.GetCatalogDescription(DocumentTuple.ACJ_CATALOGUE_DOCUMENT_ID);
    else
      CatDescription  := aIMF_DESCRIPTION;
    end if;

    PaymentDescription          := CatDescription;
    ChargesDescription          :=
                  ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('frais'), 100);
    DiscountDescription         :=
               ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('escompte'), 100);
    DeductionDescription        :=
              ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('déduction'), 100);
    DiffExchangeDescription     :=
        ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('diff. de change'), 100);
    DiffRoundDescription        :=
       ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('diff. d''arrondi'), 100);
    VatChargesDescription       :=
            ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('frais / TVA'), 100);
    VatDiscountDescription      :=
       ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA sur escompte'), 100);
    VatDeductionDescription     :=
      ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA sur déduction'), 100);
    VatDiffExchangeDescription  :=
      ACT_FUNCTIONS.FormatDescription(CatDescription
                                    , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA sur diff. de cours')
                                    , 100
                                     );
    VatEncashmentDescription    :=
      ACT_FUNCTIONS.FormatDescription(CatDescription
                                    , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA / contres prestations reçues')
                                    , 100
                                     );
/*
    -- Effacement imputations antérieures
    delete from ACT_FINANCIAL_IMPUTATION
      where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;
*/

    --Recherche info. compl. géré
    ACT_CREATION_SBVR.InitPayInfoImputation(aACT_DOCUMENT_ID);
    -- recherche si catalogue gére analytique
    ACT_CREATION_SBVR.ExistMAN  := ACT_CREATION_SBVR.IsManDocument(aACT_DOCUMENT_ID);

    -- récupération des données compl.
    ACT_CREATION_SBVR.GetInfoImputationPrimary(aACT_DOCUMENT_ID);

--    ACT_CREATION_SBVR.TypeOfPeriod := ACT_CREATION_SBVR.GetPeriodTypeOfCat(DocumentTuple.ACJ_CATALOGUE_DOCUMENT_ID);
    TotalPaied_LC               := 0;
    TotalPaied_FC               := 0;
    LastPartImputationId        := 0;

    -- Création imputation sur le compte de frais
    open PartImputCursor(aACT_DOCUMENT_ID);

    fetch PartImputCursor
     into PartImputTuple;

    while PartImputCursor%found loop
      -- Paiement débiteur
      if PartImputTuple.PAC_CUSTOM_PARTNER_ID is not null then
        Cust  := 1;
      else
        Cust  := 0;
      end if;

      if Cust = 1 then
        select *
          into CustomPartnerTuple
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = PartImputTuple.PAC_CUSTOM_PARTNER_ID;

        AuxAccountId  := CustomPartnerTuple.ACS_AUXILIARY_ACCOUNT_ID;
      else   -- Paiement créancier
        select *
          into SupplierPartnerTuple
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = PartImputTuple.PAC_SUPPLIER_PARTNER_ID;

        AuxAccountId  := SupplierPartnerTuple.ACS_AUXILIARY_ACCOUNT_ID;
      end if;

      -- Création imputation sur le compte de frais
      if (    PartImputTuple.PAR_CHARGES_LC is not null
          and PartImputTuple.PAR_CHARGES_LC <> 0) then
        InitAmounts(sign(PartImputTuple.PAR_CHARGES_LC) = -1
                  , sign(PartImputTuple.PAR_CHARGES_LC) = -1
                  , PartImputTuple.PAR_CHARGES_LC
                  , PartImputTuple.PAR_CHARGES_FC
                  , 0
                  , Amount_LC_D
                  , Amount_LC_C
                  , Amount_FC_D
                  , Amount_FC_C
                  , Amount_EUR_D
                  , Amount_EUR_C
                   );

        if PartImputTuple.PAR_CHARGES_FC <> 0 then
          BaseInfoRec.ExchangeRate  :=
            ACS_FUNCTION.CalcRateOfExchangeEUR(PartImputTuple.PAR_CHARGES_LC
                                             , PartImputTuple.PAR_CHARGES_FC
                                             , PartImputTuple.ACS_FINANCIAL_CURRENCY_ID
                                             , aIMF_TRANSACTION_DATE
                                             , PartImputTuple.PAR_BASE_PRICE
                                              );
          BaseInfoRec.BasePrice     := PartImputTuple.PAR_BASE_PRICE;
        else
          BaseInfoRec.ExchangeRate  := 0;
          BaseInfoRec.BasePrice     := 0;
        end if;

        ChargeFinAccountId  := GetChargesAccountId(AuxAccountId);

        if ACT_VAT_MANAGEMENT.GetFinVATPossible(ChargeFinAccountId) = 1 then
          -- Suppression de la recherche du code 'par défaut'. Celui-ci est cherché dans GetInitVAT
          --ChargeVATAccId := ACT_VAT_MANAGEMENT.GetFinDefaultVAT(ChargeFinAccountId);
          ChargeVATAccId  := null;

          if ChargeVATAccId is null then
            ChargeVATAccId  :=
              ACT_VAT_MANAGEMENT.GetInitVAT(ChargeFinAccountId
                                          , DocumentTuple.ACJ_CATALOGUE_DOCUMENT_ID
                                          , PartImputTuple.PAC_SUPPLIER_PARTNER_ID
                                          , PartImputTuple.PAC_CUSTOM_PARTNER_ID
                                           );
          end if;

          if ChargeVATAccId is not null then
            BaseInfoRec.TaxCodeId        := ChargeVATAccId;
            BaseInfoRec.PeriodId         := aACS_PERIOD_ID;
            BaseInfoRec.DocumentId       := aACT_DOCUMENT_ID;
            BaseInfoRec.primary          := 0;
            BaseInfoRec.AmountD_LC       := Amount_LC_D;
            BaseInfoRec.AmountC_LC       := Amount_LC_C;
            BaseInfoRec.AmountD_FC       := Amount_FC_D;
            BaseInfoRec.AmountC_FC       := Amount_FC_C;
            BaseInfoRec.AmountD_EUR      := Amount_EUR_D;
            BaseInfoRec.AmountC_EUR      := Amount_EUR_C;
            BaseInfoRec.ValueDate        := aIMF_VALUE_DATE;
            BaseInfoRec.TransactionDate  := aIMF_TRANSACTION_DATE;
            BaseInfoRec.FinCurrId_FC     := PartImputTuple.ACS_FINANCIAL_CURRENCY_ID;
            BaseInfoRec.FinCurrId_LC     := PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID;
            BaseInfoRec.PartImputId      := PartImputTuple.ACT_PART_IMPUTATION_ID;
            CalcVATRec.Encashment        := 0;
            ACT_CREATION_SBVR.CalcVAT(BaseInfoRec, InfoVATRec, CalcVATRec, null, 0);
            Amount_LC_D                  := BaseInfoRec.AmountD_LC;
            Amount_LC_C                  := BaseInfoRec.AmountC_LC;
            Amount_FC_D                  := BaseInfoRec.AmountD_FC;
            Amount_FC_C                  := BaseInfoRec.AmountC_FC;
            Amount_EUR_D                 := BaseInfoRec.AmountD_EUR;
            Amount_EUR_C                 := BaseInfoRec.AmountC_EUR;
          end if;
        end if;

        FinImputationId     :=
          ChargesImputation(aACT_DOCUMENT_ID
                          , aACS_PERIOD_ID
                          , null
                          , aIMF_TRANSACTION_DATE
                          , aIMF_VALUE_DATE
                          , chargesDescription
                          , Amount_LC_D
                          , Amount_LC_C
                          , BaseInfoRec.ExchangeRate
                          , BaseInfoRec.BasePrice
                          , Amount_FC_D
                          , Amount_FC_C
                          , Amount_EUR_D
                          , Amount_EUR_C
                          , PartImputTuple.ACS_FINANCIAL_CURRENCY_ID
                          , PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                          , DocumentTuple.ACS_FIN_ACC_S_PAYMENT_ID
                          , DocumentTuple.ACS_FINANCIAL_ACCOUNT_ID
                          , AuxAccountId
                          , UserIni
                          , PartImputTuple.ACT_PART_IMPUTATION_ID
                          , null
                           );

        if ChargeVATAccId is not null then
          ACT_CREATION_SBVR.CREATE_VAT_SBVR(FinImputationId
                                          , ChargeVATAccId
                                          , 0
                                          , InfoVATRec.PreaAccId
                                          , 100
                                          , VatChargesDescription
                                          , DocumentTuple.DOC_NUMBER
                                          , null
                                          , AuxAccountId
                                          , UserIni
                                          , BaseInfoRec
                                          , InfoVATRec
                                          , CalcVATRec
                                           );

          -- Cumul montant payé
          if Cust = 1 then
            TotalPaied_LC  := TotalPaied_LC - sign(PartImputTuple.PAR_CHARGES_LC) * abs(Amount_LC_D + Amount_LC_C);
            TotalPaied_FC  := TotalPaied_FC - sign(PartImputTuple.PAR_CHARGES_FC) * abs(Amount_FC_D + Amount_FC_C);
          else
            TotalPaied_LC  := TotalPaied_LC + sign(PartImputTuple.PAR_CHARGES_LC) * abs(Amount_LC_D + Amount_LC_C);
            TotalPaied_FC  := TotalPaied_FC + sign(PartImputTuple.PAR_CHARGES_FC) * abs(Amount_FC_D + Amount_FC_C);
          end if;
        else
          -- Cumul montant payé
          if Cust = 1 then
            TotalPaied_LC  := TotalPaied_LC - PartImputTuple.PAR_CHARGES_LC;
            TotalPaied_FC  := TotalPaied_FC - PartImputTuple.PAR_CHARGES_FC;
          else
            TotalPaied_LC  := TotalPaied_LC + PartImputTuple.PAR_CHARGES_LC;
            TotalPaied_FC  := TotalPaied_FC + PartImputTuple.PAR_CHARGES_FC;
          end if;
        end if;
      end if;

      if    (    PartImputTuple.PAR_PAIED_CHARGES_LC is not null
             and PartImputTuple.PAR_PAIED_CHARGES_LC <> 0)
         or (    PartImputTuple.PAR_PAIED_CHARGES_FC is not null
             and PartImputTuple.PAR_PAIED_CHARGES_FC <> 0) then
        --Création frais de relance
        select nvl(min(PART1.PAR_CHARGES_LC), 0)
             , nvl(min(PART1.PAR_INTEREST_LC), 0)
             , nvl(min(PART1.PAR_CHARGES_FC), 0)
             , nvl(min(PART1.PAR_INTEREST_FC), 0)
             , min(ACT_REMINDER.ACT_PART_IMPUTATION_ID)
             , min(ACT_REMINDER.PAC_REMAINDER_CATEGORY_ID)
             , min(ACT_REMINDER.ACS_TAX_CODE_ID)
             , min(DOC1.DOC_NUMBER)
             , min(ACT_REMINDER.ACT_REMINDER_ID)
          into vReminderChargesLC
             , vReminderInterestLC
             , vReminderChargesFC
             , vReminderInterestFC
             , vReminderPartImputationId
             , vReminderCategId
             , vReminderChargesTaxCodeId
             , vReminderDocNumber
             , vExistsReminder
          from ACT_DOCUMENT DOC1
             , ACT_PART_IMPUTATION PART1
             , ACT_REMINDER
             , ACT_DET_PAYMENT DET
         where DET.ACT_PART_IMPUTATION_ID = PartImputTuple.ACT_PART_IMPUTATION_ID
           and ACT_REMINDER.ACT_REMINDER_ID = DET.DET_ACT_REMINDER_ID
           and PART1.ACT_PART_IMPUTATION_ID = ACT_REMINDER.ACT_PART_IMPUTATION_ID
           and DOC1.ACT_DOCUMENT_ID = PART1.ACT_DOCUMENT_ID;

        --Création frais relance
        ReminderChargesDescription     :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('frais de relance')
                                        , 100
                                         );
        VatReminderChargesDescription  :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA / frais de relance')
                                        , 100
                                         );
        ACT_CREATION_SBVR.CREATE_REMINDER_CHARGES_SBVR(aACT_DOCUMENT_ID
                                                     , aACS_PERIOD_ID
                                                     , aIMF_TRANSACTION_DATE
                                                     , aIMF_VALUE_DATE
                                                     , ACT_FUNCTIONS.FormatDescription(ReminderChargesDescription
                                                                                     , ' / ' || vReminderDocNumber
                                                                                     , 100
                                                                                      )
                                                     , VatReminderChargesDescription
                                                     , vReminderDocNumber
                                                     , PartImputTuple.PAR_PAIED_CHARGES_LC   --vReminderChargesLC
                                                     , PartImputTuple.PAR_EXCHANGE_RATE
                                                     , PartImputTuple.PAR_BASE_PRICE
                                                     , PartImputTuple.PAR_PAIED_CHARGES_FC   --vReminderChargesFC
                                                     , 0   -- IMF_AMOUNT_EUR_D
                                                     , PartImputTuple.ACS_FINANCIAL_CURRENCY_ID
                                                     , PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                     , AuxAccountId
                                                     , UserIni
                                                     , PartImputTuple.ACT_PART_IMPUTATION_ID
                                                     , vReminderCategId
                                                     , vReminderChargesTaxCodeId
                                                      );

        -- Cumul montant payé
        if Cust = 1 then
          TotalPaied_LC  := TotalPaied_LC - PartImputTuple.PAR_PAIED_CHARGES_LC;
          TotalPaied_FC  := TotalPaied_FC - PartImputTuple.PAR_PAIED_CHARGES_FC;
        else
          TotalPaied_LC  := TotalPaied_LC + PartImputTuple.PAR_PAIED_CHARGES_LC;
          TotalPaied_FC  := TotalPaied_FC + PartImputTuple.PAR_PAIED_CHARGES_FC;
        end if;
      end if;

      if    (    PartImputTuple.PAR_PAIED_INTEREST_LC is not null
             and PartImputTuple.PAR_PAIED_INTEREST_LC <> 0)
         or (    PartImputTuple.PAR_PAIED_INTEREST_FC is not null
             and PartImputTuple.PAR_PAIED_INTEREST_FC <> 0) then
        --Création intéret moratoire relance
        ReminderInterestDescription  :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('intérêts moratoires')
                                        , 100
                                         );
        ACT_CREATION_SBVR.CREATE_REMINDER_INTEREST_SBVR(aACT_DOCUMENT_ID
                                                      , aACS_PERIOD_ID
                                                      , aIMF_TRANSACTION_DATE
                                                      , aIMF_VALUE_DATE
                                                      , ACT_FUNCTIONS.FormatDescription(ReminderInterestDescription
                                                                                      , ' / ' || vReminderDocNumber
                                                                                      , 100
                                                                                       )
                                                      , PartImputTuple.PAR_PAIED_INTEREST_LC   --vReminderInterestLC
                                                      , PartImputTuple.PAR_EXCHANGE_RATE
                                                      , PartImputTuple.PAR_BASE_PRICE
                                                      , PartImputTuple.PAR_PAIED_INTEREST_FC   --vReminderInterestFC
                                                      , 0   -- IMF_AMOUNT_EUR_D
                                                      , PartImputTuple.ACS_FINANCIAL_CURRENCY_ID
                                                      , PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , AuxAccountId
                                                      , UserIni
                                                      , PartImputTuple.ACT_PART_IMPUTATION_ID
                                                      , vReminderCategId
                                                       );

        -- Cumul montant payé
        if Cust = 1 then
          TotalPaied_LC  := TotalPaied_LC - PartImputTuple.PAR_PAIED_INTEREST_LC;
          TotalPaied_FC  := TotalPaied_FC - PartImputTuple.PAR_PAIED_INTEREST_FC;
        else
          TotalPaied_LC  := TotalPaied_LC + PartImputTuple.PAR_PAIED_INTEREST_LC;
          TotalPaied_FC  := TotalPaied_FC + PartImputTuple.PAR_PAIED_INTEREST_FC;
        end if;

        --Màj statut relance
        ACT_CREATION_SBVR.UpdateStatusReminders(vReminderPartImputationId);
      end if;

      fetch PartImputCursor
       into PartImputTuple;
    end loop;

    close PartImputCursor;

    -- Ouverture du curseur sur les détails paiements / imputations partenaires
    open DetPaymentCursor(aACT_DOCUMENT_ID);

    fetch DetPaymentCursor
     into DetPaymentTuple;

    while DetPaymentCursor%found loop
      -- Paiement débiteur
      if DetPaymentTuple.PAC_CUSTOM_PARTNER_ID is not null then
        Cust  := 1;
      else
        Cust  := 0;
      end if;

      if Cust = 1 then
        select *
          into CustomPartnerTuple
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = DetPaymentTuple.PAC_CUSTOM_PARTNER_ID;

        AuxAccountId  := CustomPartnerTuple.ACS_AUXILIARY_ACCOUNT_ID;
      -- Paiement créancier
      else
        select *
          into SupplierPartnerTuple
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = DetPaymentTuple.PAC_SUPPLIER_PARTNER_ID;

        AuxAccountId  := SupplierPartnerTuple.ACS_AUXILIARY_ACCOUNT_ID;
      end if;

      -- Recherche des infos sur le document à payer
      open ExpiryDocumentCursor(DetPaymentTuple.ACT_EXPIRY_ID);

      fetch ExpiryDocumentCursor
       into ExpiryDocumentTuple;

      --Traitement des taux de couverture
      ln_ResetHedgeRecord := 0;
      ln_UseDiffFinAccount := 0;
      ln_Hedging   := ACT_FUNCTIONS.HedgeManagement(ExpiryDocumentTuple.ACJ_CATALOGUE_DOCUMENT_ID);
      -- Les types de couverture 2- Hedge, 3- Hors couverture cours fixe, 4-Hors couverture taux spot
      --ne doivent pas être imputés sur l'axe dossier pour les diff. de change
      --pour les document de paiement manuel (c_type_catalogue = 3) et paiement auto (c_type_catalogue = 4)
      if (ln_Hedging = 1) and ExpiryDocumentTuple.C_CURR_RATE_COVER_TYPE in ('02','03','04') and
        (ACT_FUNCTIONS.GetCatalogueType(DocumentTuple.ACJ_CATALOGUE_DOCUMENT_ID) in ('3','4')) then
        ln_ResetHedgeRecord := 1;
      end if;

      NC               :=(ExpiryDocumentTuple.C_TYPE_CATALOGUE in('5', '6') );   -- Note de crédit (O/N)
      OriginD          := OriginImputationD(ExpiryDocumentTuple.ACT_PART_IMPUTATION_ID, AuxAccountId, Cust, SignImp);

      if ExpiryDocumentTuple.C_TYPE_CATALOGUE in('3', '4') then   -- Cas d'un paiement non lettré (paiement d'avance)
--        if DetPaymentTuple.DET_PAIED_LC  + DetPaymentTuple.DET_DISCOUNT_LC  + DetPaymentTuple.DET_DEDUCTION_LC < 0 then
        NC  := true;
--        end if;
      end if;

      --Reprise des info compl. de la facture
      ACT_CREATION_SBVR.GetInfoImputationExpiry(DetPaymentTuple.ACT_EXPIRY_ID);
      -- Définition des montants
      InitAmounts(OriginD
                , NC
                , (DetPaymentTuple.DET_PAIED_LC + DetPaymentTuple.DET_DISCOUNT_LC + DetPaymentTuple.DET_DEDUCTION_LC)
                , (DetPaymentTuple.DET_PAIED_FC + DetPaymentTuple.DET_DISCOUNT_FC + DetPaymentTuple.DET_DEDUCTION_FC)
                , (DetPaymentTuple.DET_PAIED_EUR + DetPaymentTuple.DET_DISCOUNT_EUR + DetPaymentTuple.DET_DEDUCTION_EUR
                  )
                , Amount_LC_D
                , Amount_LC_C
                , Amount_FC_D
                , Amount_FC_C
                , Amount_EUR_D
                , Amount_EUR_C
                , SignImp
                , ExpiryDocumentTuple.SignExp
                 );

      ln_RateToApply :=  DetPaymentTuple.PAR_EXCHANGE_RATE;
      if (ln_Hedging = 1) and (ExpiryDocumentTuple.C_CURR_RATE_COVER_TYPE = '01') then
        ln_RateToApply := ExpiryDocumentTuple.IMF_EXCHANGE_RATE;
      end if;


      -- Création imputation sur le compte collectif
      ACT_CREATION_SBVR.CREATE_FIN_IMP_PAY_SBVR(aACT_DOCUMENT_ID
                                              ,   --Doc paiement
                                                ExpiryDocumentTuple.ACT_DOCUMENT_ID
                                              ,   --Doc facture
                                                ExpiryDocumentTuple.ACT_PART_IMPUTATION_ID
                                              ,   --Part imp facture
                                                aACS_PERIOD_ID
                                              , AuxAccountId
                                              , DetPaymentTuple.ACT_DET_PAYMENT_ID
                                              , aIMF_TRANSACTION_DATE
                                              , aIMF_VALUE_DATE
                                              , ACT_FUNCTIONS.FormatDescription(PaymentDescription
                                                                              , ' / ' || ExpiryDocumentTuple.DOC_NUMBER
                                                                              , 100
                                                                               )
                                              , Amount_LC_D
                                              , Amount_LC_C
                                              , ln_RateToApply
                                              , DetPaymentTuple.PAR_BASE_PRICE
                                              , Amount_FC_D
                                              , Amount_FC_C
                                              , Amount_EUR_D
                                              , Amount_EUR_C
                                              , DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID
                                              , DetPaymentTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                              , UserIni
                                              , DetPaymentTuple.ACT_PART_IMPUTATION_ID
                                               );

/*
      if DetPaymentTuple.DET_CHARGES_LC is not null and DetPaymentTuple.DET_CHARGES_LC <> 0 then

        -- Définition des montants
        -- Imputations à passer au débit, tant pour les clients que pour les fournisseurs
        InitAmounts(false, false,
                    DetPaymentTuple.DET_CHARGES_LC, DetPaymentTuple.DET_CHARGES_FC, DetPaymentTuple.DET_CHARGES_EUR,
                    Amount_LC_D, Amount_LC_C, Amount_FC_D, Amount_FC_C, Amount_EUR_D, Amount_EUR_C);

        ChargesImputation(aACT_DOCUMENT_ID,
                          aACS_PERIOD_ID,
                          DetPaymentTuple.ACT_DET_PAYMENT_ID,
                          aIMF_TRANSACTION_DATE,
                          ACT_FUNCTIONS.FormatDescription(chargesDescription, ' / ' || ExpiryDocumentTuple.DOC_NUMBER, 100),
                          Amount_LC_D,
                          Amount_LC_C,
                          DetPaymentTuple.PAR_EXCHANGE_RATE,
                          DetPaymentTuple.PAR_BASE_PRICE,
                          Amount_FC_D,
                          Amount_FC_C,
                          Amount_EUR_D,
                          Amount_EUR_C,
                          DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID,
                          DetPaymentTuple.ACS_ACS_FINANCIAL_CURRENCY_ID,
                          DocumentTuple.ACS_FIN_ACC_S_PAYMENT_ID,
                          DocumentTuple.ACS_FINANCIAL_ACCOUNT_ID,
                          AuxAccountId,
                          UserIni,
                          DetPaymentTuple.ACT_PART_IMPUTATION_ID,
                          ExpiryDocumentTuple.ACT_DOCUMENT_ID);

        -- Cumul montant payé
        if Cust = 1 then
            TotalPaied_LC := TotalPaied_LC - DetPaymentTuple.DET_CHARGES_LC;
            TotalPaied_FC := TotalPaied_FC - DetPaymentTuple.DET_CHARGES_FC;
        else
            TotalPaied_LC := TotalPaied_LC + DetPaymentTuple.DET_CHARGES_LC;
            TotalPaied_FC := TotalPaied_FC + DetPaymentTuple.DET_CHARGES_FC;
        end if;


      end if;
*/    -- Cumul montant payé
      if Cust = 1 then
        TotalPaied_LC  := TotalPaied_LC + DetPaymentTuple.DET_PAIED_LC;
        TotalPaied_FC  := TotalPaied_FC + DetPaymentTuple.DET_PAIED_FC;
      else
        TotalPaied_LC  := TotalPaied_LC + DetPaymentTuple.DET_PAIED_LC;
        TotalPaied_FC  := TotalPaied_FC + DetPaymentTuple.DET_PAIED_FC;
      end if;

      -- Imputations déduction / escompte / Différence de change - TVA
      --Calcul proportion TVA
      ACT_CREATION_SBVR.tblCalcVat.delete;

      if    (    DetPaymentTuple.DET_DEDUCTION_LC <> 0
             and CatExtVAT = 1)
         or (    DetPaymentTuple.DET_DISCOUNT_LC <> 0
             and CatExtVATDiscount = 1) then
        ACT_CREATION_SBVR.CalcVatOnDeduction(DetPaymentTuple.ACT_EXPIRY_ID, aACT_DOCUMENT_ID);
      else
        ACT_CREATION_SBVR.tblCalcVat(1).ACS_TAX_CODE_ID           := 0;
        ACT_CREATION_SBVR.tblCalcVat(1).TAX_RATE                  := 0;
        ACT_CREATION_SBVR.tblCalcVat(1).ACS_FINANCIAL_ACCOUNT_ID  := 0;
        ACT_CREATION_SBVR.tblCalcVat(1).PROPORTION                := 100;
      end if;

      TotDiscountLC    := 0;
      TotDiscountFC    := 0;
      TotDiscountEUR   := 0;
      TotDeductionLC   := 0;
      TotDeductionFC   := 0;
      TotDeductionEUR  := 0;

--    DBMS_OUTPUT.Put_line('Discount : ' || to_char(TotDiscountLC));
      for i in 1 .. ACT_CREATION_SBVR.tblCalcVat.count loop
        -- Imputation escompte et Correction TVA
        if DetPaymentTuple.DET_DISCOUNT_LC <> 0 then
          if i = ACT_CREATION_SBVR.tblcalcVat.count then
            AmountLC   := DetPaymentTuple.DET_DISCOUNT_LC - TotDiscountLC;
            AmountFC   := DetPaymentTuple.DET_DISCOUNT_FC - TotDiscountFC;
            AmountEUR  := DetPaymentTuple.DET_DISCOUNT_FC - TotDiscountFC;
          else
            AmountLC   := DetPaymentTuple.DET_DISCOUNT_LC * ACT_CREATION_SBVR.tblcalcVat(i).PROPORTION / 100;
            AmountFC   := DetPaymentTuple.DET_DISCOUNT_FC * ACT_CREATION_SBVR.tblcalcVat(i).PROPORTION / 100;
            AmountEUR  := DetPaymentTuple.DET_DISCOUNT_EUR * ACT_CREATION_SBVR.tblcalcVat(i).PROPORTION / 100;
          end if;

          -- Définition des montants
          InitAmounts(not OriginD
                    , NC
                    , AmountLC
                    , AmountFC
                    , AmountEUR
                    , Amount_LC_D
                    , Amount_LC_C
                    , Amount_FC_D
                    , Amount_FC_C
                    , Amount_EUR_D
                    , Amount_EUR_C
                    , SignImp
                    , ExpiryDocumentTuple.SignExp
                     );

          if round(AmountLC, 2) <> 0 then
            BaseInfoRec      := const_BaseInfoRec;
            InfoVATRec       := const_InfoVATRec;
            CalcVATRec       := const_CalcVATRec;

            if     (CatExtVATDiscount = 1)
               and (ACT_CREATION_SBVR.tblcalcVat(i).ACS_TAX_CODE_ID <> 0) then
              BaseInfoRec.TaxCodeId        := ACT_CREATION_SBVR.tblcalcVat(i).ACS_TAX_CODE_ID;
              BaseInfoRec.PeriodId         := aACS_PERIOD_ID;
              BaseInfoRec.DocumentId       := aACT_DOCUMENT_ID;
              BaseInfoRec.primary          := 0;
              BaseInfoRec.AmountD_LC       := Amount_LC_D;
              BaseInfoRec.AmountC_LC       := Amount_LC_C;
              BaseInfoRec.AmountD_FC       := Amount_FC_D;
              BaseInfoRec.AmountC_FC       := Amount_FC_C;
              BaseInfoRec.AmountD_EUR      := Amount_EUR_D;
              BaseInfoRec.AmountC_EUR      := Amount_EUR_C;
              BaseInfoRec.ExchangeRate     := DetPaymentTuple.PAR_EXCHANGE_RATE;
              BaseInfoRec.BasePrice        := DetPaymentTuple.PAR_BASE_PRICE;
              BaseInfoRec.ValueDate        := aIMF_VALUE_DATE;
              BaseInfoRec.TransactionDate  := aIMF_TRANSACTION_DATE;
              BaseInfoRec.FinCurrId_FC     := DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID;
              BaseInfoRec.FinCurrId_LC     := DetPaymentTuple.ACS_ACS_FINANCIAL_CURRENCY_ID;
              BaseInfoRec.PartImputId      := DetPaymentTuple.ACT_PART_IMPUTATION_ID;
              CalcVATRec.Encashment        := ACT_CREATION_SBVR.tblcalcVat(i).TAX_TMP_VAT_ENCASHMENT;
              ACT_CREATION_SBVR.CalcVAT(BaseInfoRec
                                      , InfoVATRec
                                      , CalcVATRec
                                      , ExpiryDocumentTuple.ACT_DOCUMENT_ID
                                      , ACT_CREATION_SBVR.tblcalcVat(i).TAX_RATE
                                      , ACT_CREATION_SBVR.tblcalcVat(i).TAX_EXCHANGE_RATE
                                      , ACT_CREATION_SBVR.tblcalcVat(i).DET_BASE_PRICE
                                       );
              Amount_LC_D                  := BaseInfoRec.AmountD_LC;
              Amount_LC_C                  := BaseInfoRec.AmountC_LC;
              Amount_FC_D                  := BaseInfoRec.AmountD_FC;
              Amount_FC_C                  := BaseInfoRec.AmountC_FC;
              Amount_EUR_D                 := BaseInfoRec.AmountD_EUR;
              Amount_EUR_C                 := BaseInfoRec.AmountC_EUR;
            end if;

            FinImputationId  :=
              ACT_CREATION_SBVR.CREATE_FIN_IMP_DISCOUNT_SBVR
                                                      (aACT_DOCUMENT_ID
                                                     , ExpiryDocumentTuple.ACT_DOCUMENT_ID
                                                     , aACS_PERIOD_ID
                                                     , AuxAccountId
                                                     , DetPaymentTuple.ACT_DET_PAYMENT_ID
                                                     , aIMF_TRANSACTION_DATE
                                                     , aIMF_VALUE_DATE
                                                     , ACT_FUNCTIONS.FormatDescription(DiscountDescription
                                                                                     , ' / ' ||
                                                                                       ExpiryDocumentTuple.DOC_NUMBER
                                                                                     , 100
                                                                                      )
                                                     , Amount_LC_D
                                                     , Amount_LC_C
                                                     , DetPaymentTuple.PAR_EXCHANGE_RATE
                                                     , DetPaymentTuple.PAR_BASE_PRICE
                                                     , Amount_FC_D
                                                     , Amount_FC_C
                                                     , Amount_EUR_D
                                                     , Amount_EUR_C
                                                     , DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID
                                                     , DetPaymentTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                     , UserIni
                                                     , DetPaymentTuple.ACT_PART_IMPUTATION_ID
                                                      );
            TotDiscountLC    := TotDiscountLC + AmountLC;
            TotDiscountFC    := TotDiscountFC + AmountFC;
            TotDiscountEUR   := TotDiscountEUR + AmountEUR;

            if     CatExtVATDiscount = 1
               and ACT_CREATION_SBVR.tblcalcVat(i).ACS_TAX_CODE_ID > 0 then
              ACT_CREATION_SBVR.CREATE_VAT_SBVR(FinImputationId
                                              , ACT_CREATION_SBVR.tblcalcVat(i).ACS_TAX_CODE_ID
                                              , ACT_CREATION_SBVR.tblcalcVat(i).TAX_RATE
                                              , ACT_CREATION_SBVR.tblcalcVat(i).ACS_FINANCIAL_ACCOUNT_ID
                                              , ACT_CREATION_SBVR.tblcalcVat(i).PROPORTION
                                              , VatDiscountDescription
                                              , DocumentTuple.DOC_NUMBER
                                              , ExpiryDocumentTuple.ACT_DOCUMENT_ID
                                              , AuxAccountId
                                              , UserIni
                                              , BaseInfoRec
                                              , InfoVATRec
                                              , CalcVATRec
                                               );
            end if;
          end if;
        end if;

        -- Imputation déduction et Correction TVA
        if DetPaymentTuple.DET_DEDUCTION_LC <> 0 then
          if i = ACT_CREATION_SBVR.tblcalcVat.count then
            AmountLC   := DetPaymentTuple.DET_DEDUCTION_LC - TotDeductionLC;
            AmountFC   := DetPaymentTuple.DET_DEDUCTION_FC - TotDeductionFC;
            AmountEUR  := DetPaymentTuple.DET_DEDUCTION_EUR - TotDeductionEUR;
          else
            AmountLC   := DetPaymentTuple.DET_DEDUCTION_LC * ACT_CREATION_SBVR.tblcalcVat(i).PROPORTION / 100;
            AmountFC   := DetPaymentTuple.DET_DEDUCTION_FC * ACT_CREATION_SBVR.tblcalcVat(i).PROPORTION / 100;
            AmountEUR  := DetPaymentTuple.DET_DEDUCTION_EUR * ACT_CREATION_SBVR.tblcalcVat(i).PROPORTION / 100;
          end if;

          -- Définition des montants
          if    (    AmountLC < 0
                 and DetPaymentTuple.DET_PAIED_LC + DetPaymentTuple.DET_DISCOUNT_LC + DetPaymentTuple.DET_DEDUCTION_LC >
                                                                                                                       0
                )
             or (    AmountLC > 0
                 and DetPaymentTuple.DET_PAIED_LC + DetPaymentTuple.DET_DISCOUNT_LC + DetPaymentTuple.DET_DEDUCTION_LC <
                                                                                                                       0
                ) then
            -- Facture surpayée !!!
            NegativeDeduction  := true;
            InitAmounts(OriginD
                      , NC
                      , AmountLC
                      , AmountFC
                      , AmountEUR
                      , Amount_LC_D
                      , Amount_LC_C
                      , Amount_FC_D
                      , Amount_FC_C
                      , Amount_EUR_D
                      , Amount_EUR_C
                      , -SignImp
                      , ExpiryDocumentTuple.SignExp
                       );
          else
            NegativeDeduction  := false;
            InitAmounts(not OriginD
                      , NC
                      , AmountLC
                      , AmountFC
                      , AmountEUR
                      , Amount_LC_D
                      , Amount_LC_C
                      , Amount_FC_D
                      , Amount_FC_C
                      , Amount_EUR_D
                      , Amount_EUR_C
                      , SignImp
                      , ExpiryDocumentTuple.SignExp
                       );
          end if;

          -- Si NC alors inversion de la recherche des comptes déduction
          if NC then
            NegativeDeduction  := not NegativeDeduction;
          end if;

          if round(AmountLC, 2) <> 0 then
            BaseInfoRec      := const_BaseInfoRec;
            InfoVATRec       := const_InfoVATRec;
            CalcVATRec       := const_CalcVATRec;

            if     (CatExtVAT = 1)
               and (ACT_CREATION_SBVR.tblcalcVat(i).ACS_TAX_CODE_ID <> 0) then
              BaseInfoRec.TaxCodeId        := ACT_CREATION_SBVR.tblcalcVat(i).ACS_TAX_CODE_ID;
              BaseInfoRec.PeriodId         := aACS_PERIOD_ID;
              BaseInfoRec.DocumentId       := aACT_DOCUMENT_ID;
              BaseInfoRec.primary          := 0;
              BaseInfoRec.AmountD_LC       := Amount_LC_D;
              BaseInfoRec.AmountC_LC       := Amount_LC_C;
              BaseInfoRec.AmountD_FC       := Amount_FC_D;
              BaseInfoRec.AmountC_FC       := Amount_FC_C;
              BaseInfoRec.AmountD_EUR      := Amount_EUR_D;
              BaseInfoRec.AmountC_EUR      := Amount_EUR_C;
              BaseInfoRec.ExchangeRate     := DetPaymentTuple.PAR_EXCHANGE_RATE;
              BaseInfoRec.BasePrice        := DetPaymentTuple.PAR_BASE_PRICE;
              BaseInfoRec.ValueDate        := aIMF_VALUE_DATE;
              BaseInfoRec.TransactionDate  := aIMF_TRANSACTION_DATE;
              BaseInfoRec.FinCurrId_FC     := DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID;
              BaseInfoRec.FinCurrId_LC     := DetPaymentTuple.ACS_ACS_FINANCIAL_CURRENCY_ID;
              BaseInfoRec.PartImputId      := DetPaymentTuple.ACT_PART_IMPUTATION_ID;
              CalcVATRec.Encashment        := ACT_CREATION_SBVR.tblcalcVat(i).TAX_TMP_VAT_ENCASHMENT;
              ACT_CREATION_SBVR.CalcVAT(BaseInfoRec
                                      , InfoVATRec
                                      , CalcVATRec
                                      , ExpiryDocumentTuple.ACT_DOCUMENT_ID
                                      , ACT_CREATION_SBVR.tblcalcVat(i).TAX_RATE
                                      , ACT_CREATION_SBVR.tblcalcVat(i).TAX_EXCHANGE_RATE
                                      , ACT_CREATION_SBVR.tblcalcVat(i).DET_BASE_PRICE
                                       );
              Amount_LC_D                  := BaseInfoRec.AmountD_LC;
              Amount_LC_C                  := BaseInfoRec.AmountC_LC;
              Amount_FC_D                  := BaseInfoRec.AmountD_FC;
              Amount_FC_C                  := BaseInfoRec.AmountC_FC;
              Amount_EUR_D                 := BaseInfoRec.AmountD_EUR;
              Amount_EUR_C                 := BaseInfoRec.AmountC_EUR;
            end if;

            FinImputationId  :=
              ACT_CREATION_SBVR.CREATE_FIN_IMP_DEDUCTION_SBVR
                                                      (aACT_DOCUMENT_ID
                                                     , ExpiryDocumentTuple.ACT_DOCUMENT_ID
                                                     , aACS_PERIOD_ID
                                                     , AuxAccountId
                                                     , DetPaymentTuple.ACT_DET_PAYMENT_ID
                                                     , aIMF_TRANSACTION_DATE
                                                     , aIMF_VALUE_DATE
                                                     , ACT_FUNCTIONS.FormatDescription(DeductionDescription
                                                                                     , ' / ' ||
                                                                                       ExpiryDocumentTuple.DOC_NUMBER
                                                                                     , 100
                                                                                      )
                                                     , Amount_LC_D
                                                     , Amount_LC_C
                                                     , DetPaymentTuple.PAR_EXCHANGE_RATE
                                                     , DetPaymentTuple.PAR_BASE_PRICE
                                                     , Amount_FC_D
                                                     , Amount_FC_C
                                                     , Amount_EUR_D
                                                     , Amount_EUR_C
                                                     , DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID
                                                     , DetPaymentTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                     , UserIni
                                                     , DetPaymentTuple.ACT_PART_IMPUTATION_ID
                                                     , NegativeDeduction
                                                      );
            TotDeductionLC   := TotDeductionLC + AmountLC;
            TotDeductionFC   := TotDeductionFC + AmountFC;
            TotDeductionEUR  := TotDeductionEUR + AmountEUR;

            if     CatExtVAT = 1
               and ACT_CREATION_SBVR.tblcalcVat(i).ACS_TAX_CODE_ID > 0 then
              ACT_CREATION_SBVR.CREATE_VAT_SBVR(FinImputationId
                                              , ACT_CREATION_SBVR.tblcalcVat(i).ACS_TAX_CODE_ID
                                              , ACT_CREATION_SBVR.tblcalcVat(i).TAX_RATE
                                              , ACT_CREATION_SBVR.tblcalcVat(i).ACS_FINANCIAL_ACCOUNT_ID
                                              , ACT_CREATION_SBVR.tblcalcVat(i).PROPORTION
                                              , VatDeductionDescription
                                              , DocumentTuple.DOC_NUMBER
                                              , ExpiryDocumentTuple.ACT_DOCUMENT_ID
                                              , AuxAccountId
                                              , UserIni
                                              , BaseInfoRec
                                              , InfoVATRec
                                              , CalcVATRec
                                               );
            end if;
          end if;
        end if;
      end loop;

      --Création écriture reprise TVA provisoire
      if (upper(PCS.PC_CONFIG.GetConfig('ACT_TAX_VAT_ENCASHMENT') ) = 'TRUE') then
        if ACT_VAT_MANAGEMENT.DelayedEncashmentVAT(aACT_DOCUMENT_ID) = 0 then
          tblCalcVATEncashment.delete;
          Flag  :=
                Flag
            and ACT_VAT_MANAGEMENT.CalcEncashmentVAT(DetPaymentTuple.ACT_EXPIRY_ID
                                                   , DetPaymentTuple.DET_PAIED_LC +
                                                     DetPaymentTuple.DET_DISCOUNT_LC +
                                                     DetPaymentTuple.DET_DEDUCTION_LC +
                                                     DetPaymentTuple.DET_DIFF_EXCHANGE
                                                   , DetPaymentTuple.DET_PAIED_FC +
                                                     DetPaymentTuple.DET_DISCOUNT_FC +
                                                     DetPaymentTuple.DET_DEDUCTION_FC
                                                   , tblCalcVATEncashment
                                                    );
          Flag  :=
                Flag
            and ACT_VAT_MANAGEMENT.InsertEncashmentVAT
                                                      (aACT_DOCUMENT_ID
                                                     , aACS_PERIOD_ID
                                                     , null
                                                     , DetPaymentTuple.ACT_DET_PAYMENT_ID
                                                     , aIMF_TRANSACTION_DATE
                                                     , aIMF_VALUE_DATE
                                                     , ACT_FUNCTIONS.FormatDescription(VatEncashmentDescription
                                                                                     , ' / ' ||
                                                                                       ExpiryDocumentTuple.DOC_NUMBER
                                                                                     , 100
                                                                                      )
                                                     , DetPaymentTuple.ACT_PART_IMPUTATION_ID
                                                     , tblCalcVATEncashment
                                                     , ACT_CREATION_SBVR.GetInfoImp
                                                      );

        end if;
      end if;

      -- Imputations différence de change et Correction TVA
      if     DetPaymentTuple.DET_DIFF_EXCHANGE is not null
         and DetPaymentTuple.DET_DIFF_EXCHANGE <> 0 then
        -- Définition des montants
        InitDiffChangeAmounts( (Cust = 1)
                            , OriginD
                            , NC
                            , DetPaymentTuple.DET_DIFF_EXCHANGE
                            , Amount_LC_D
                            , Amount_LC_C
                            , CollAmount_LC_D
                            , CollAmount_LC_C
                             );
        --Application règle Hedge-4310
        --La constation de perte et gain de change se comptabilise en résultat financier
        --Pour les documents géré
        --    Hors couverture cours fixe (03)
        --    Hors couverture cours spot (04)
        --    Sans (00)
        if (ln_Hedging = 1) and (ExpiryDocumentTuple.C_CURR_RATE_COVER_TYPE = '02') then
          FinAccountId  :=
                GetDiffExcOperatingAcc(Cust, DetPaymentTuple.DET_DIFF_EXCHANGE, DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID);
        else
          FinAccountId  := GetDiffExchangeAccount(Cust, DetPaymentTuple.DET_DIFF_EXCHANGE, DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID);
        end if;

        if    (round(Amount_LC_D, 2) <> 0)
           or (round(Amount_LC_C, 2) <> 0) then
          FinImputationId  :=
            DiffExchangeImputations(Cust
                                  , aACT_DOCUMENT_ID
                                  , ExpiryDocumentTuple.ACT_DOCUMENT_ID
                                  , aACS_PERIOD_ID
                                  , FinAccountId
                                  , AuxAccountId
                                  , DetPaymentTuple.ACT_DET_PAYMENT_ID
                                  , aIMF_TRANSACTION_DATE
                                  , aIMF_VALUE_DATE
                                  , ACT_FUNCTIONS.FormatDescription(DiffExchangeDescription
                                                                  , ' / ' || ExpiryDocumentTuple.DOC_NUMBER
                                                                  , 100
                                                                   )
                                  , Amount_LC_D
                                  , Amount_LC_C
                                  , 0
                                  ,   -- DetPaymentTuple.PAR_EXCHANGE_RATE,
                                    0
                                  ,   -- DetPaymentTuple.PAR_BASE_PRICE,
                                    CollAmount_LC_D
                                  , CollAmount_LC_C
                                  ,
                                    -- PrimaryImputationTuple.ACS_FINANCIAL_CURRENCY_ID,
                                    DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID
                                  , DetPaymentTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                  , UserIni
                                  , DetPaymentTuple.ACT_PART_IMPUTATION_ID
                                   );
        end if;
      end if;

      -- Ecriture de différence d'arrondi
      -- Uniquement pour les documents NON hedge : Ceux-ci ont le montant de
      --l'imputation primaire initialisé par la somme des contre-parties.
      if (aACS_FINANCIAL_CURRENCY_ID <> aACS_ACS_FINANCIAL_CURRENCY_ID) and (ln_Hedging = 0)then
        AmountLC  :=
          DiffRound(Cust
                  , aIMF_AMOUNT_LC_D
                  , aIMF_AMOUNT_LC_C
                  , aIMF_AMOUNT_FC_D
                  , aIMF_AMOUNT_FC_C
                  , TotalPaied_LC
                  , TotalPaied_FC
                   );

        if AmountLC <> 0 then
          -- Définition des montants
          InitAmounts(not OriginD
                    , NC
                    , AmountLC
                    , 0
                    , 0
                    , Amount_LC_D
                    , Amount_LC_C
                    , Amount_FC_D
                    , Amount_FC_C
                    , Amount_EUR_D
                    , Amount_EUR_C
                    , SignImp
                    , ExpiryDocumentTuple.SignExp
                     );
          FinAccountId  := GetDiffExchangeAccount(Cust, AmountLC, DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID);
          DiffRoundImputation(Cust
                            , aACT_DOCUMENT_ID
                            , ExpiryDocumentTuple.ACT_DOCUMENT_ID
                            , aACS_PERIOD_ID
                            , FinAccountId
                            , AuxAccountId
                            , null
                            ,   -- DetPaymentTuple.ACT_DET_PAYMENT_ID,
                              aIMF_TRANSACTION_DATE
                            , aIMF_VALUE_DATE
                            , ACT_FUNCTIONS.FormatDescription(DiffRoundDescription
                                                            , ' / ' || ExpiryDocumentTuple.DOC_NUMBER
                                                            , 100
                                                             )
                            , Amount_LC_D
                            , Amount_LC_C
                            , 0
                            ,   -- DetPaymentTuple.PAR_EXCHANGE_RATE,
                              0
                            ,   -- DetPaymentTuple.PAR_BASE_PRICE,
                              Amount_FC_D
                            , Amount_FC_C
                            , Amount_EUR_D
                            , Amount_EUR_C
                            , DetPaymentTuple.ACS_FINANCIAL_CURRENCY_ID
                            , DetPaymentTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                            , UserIni
                            , DetPaymentTuple.ACT_PART_IMPUTATION_ID
                             );
        end if;
      end if;

      close ExpiryDocumentCursor;

      fetch DetPaymentCursor
       into DetPaymentTuple;
    end loop;

    close DetPaymentCursor;
  end ProcessPayment;

--------------------------
  function OriginImputationD(
    aACT_PART_IMPUTATION_ID          ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aCust                            number
  , aSign                     in out number
  )
    return boolean
  is
    result  boolean;
    AmountD ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountC ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
  begin
    begin
      select nvl(IMF_AMOUNT_LC_D, 0)
           , nvl(IMF_AMOUNT_LC_C, 0)
        into AmountD
           , AmountC
        from ACS_FINANCIAL_ACCOUNT FIN
           , ACT_FINANCIAL_IMPUTATION IMP
       where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and FIN.FIN_COLLECTIVE = 1
         and IMP.ACT_DET_PAYMENT_ID is null
         and rownum = 1;

      if AmountD=0 and AmountC=0 then
        -- Montant de la facture = 0
        result  :=(aCust = 1);
        aSign := 0;
      else
        result  := AmountD <> 0;

        if result then
          aSign  := sign(AmountD);
        else
          aSign  := sign(AmountC);
        end if;
      end if;
    exception
      when no_data_found then
        result  :=(aCust = 1);
        aSign   := 1;
      when others then
        result  := false;
        aSign   := 1;
    end;

    return result;
  end OriginImputationD;

--------------------------
  procedure CreateChargesImputation(
    aACT_DOCUMENT_ID                  ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aPAR_CHARGES_LC            in out ACT_PART_IMPUTATION.PAR_CHARGES_LC%type
  , aPAR_CHARGES_FC            in out ACT_PART_IMPUTATION.PAR_CHARGES_FC%type
  , aACS_FINANCIAL_CURRENCY_ID        ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_PERIOD_ID                    ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type
  , aIMF_TRANSACTION_DATE             ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE                   ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aIMF_DESCRIPTION                  ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  )
  is
    cursor PartImputCursor(
      aACT_DOCUMENT_ID           ACT_DOCUMENT.ACT_DOCUMENT_ID%type
    , aACS_FINANCIAL_CURRENCY_ID ACT_PART_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
    )
    is
      select   PAR.ACT_PART_IMPUTATION_ID
             , PAR.PAC_CUSTOM_PARTNER_ID
             , PAR.PAC_SUPPLIER_PARTNER_ID
             , nvl(PAR.PAR_EXCHANGE_RATE, 0) PAR_EXCHANGE_RATE
             , nvl(PAR.PAR_BASE_PRICE, 0) PAR_BASE_PRICE
             , nvl(PAR.PAR_CHARGES_LC, 0) PAR_CHARGES_LC
             , nvl(PAR.PAR_CHARGES_FC, 0) PAR_CHARGES_FC
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
          from ACT_PART_IMPUTATION PAR
         where PAR.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and PAR.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
      order by PAR.ACT_PART_IMPUTATION_ID asc;

    PartImputTuple     PartImputCursor%rowtype;
    DocumentTuple      ACT_DOCUMENT%rowtype;
    Amount_LC_D        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    Amount_LC_C        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    Amount_FC_D        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    Amount_FC_C        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    Amount_EUR_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    Amount_EUR_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    ChargesDescription ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    CatDescription     ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type;
    AuxAccountId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    FinImputationId    ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
  begin
    -- Recherche des infos sur le document
    select *
      into DocumentTuple
      from ACT_DOCUMENT
     where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    if    aIMF_DESCRIPTION is null
       or aIMF_DESCRIPTION = '' then
      CatDescription  := ACT_FUNCTIONS.GetCatalogDescription(DocumentTuple.ACJ_CATALOGUE_DOCUMENT_ID);
    else
      CatDescription  := aIMF_DESCRIPTION;
    end if;

    ChargesDescription  := CatDescription || ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('frais');

    -- Ouverture du curseur sur les détails paiements / imputations partenaires
    open PartImputCursor(aACT_DOCUMENT_ID, aACS_FINANCIAL_CURRENCY_ID);

    fetch PartImputCursor
     into PartImputTuple;

    if not PartImputCursor%found then
      close PartImputCursor;

      open PartImputCursor(aACT_DOCUMENT_ID, ACS_FUNCTION.GetLocalCurrencyID);

      fetch PartImputCursor
       into PartImputTuple;
    end if;

    if PartImputCursor%found then
      -- recherche si catalogue gére analytique
      ACT_CREATION_SBVR.ExistMAN  := ACT_CREATION_SBVR.IsManDocument(aACT_DOCUMENT_ID);

      if PartImputTuple.PAC_CUSTOM_PARTNER_ID is not null then
        select ACS_AUXILIARY_ACCOUNT_ID
          into AuxAccountId
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = PartImputTuple.PAC_CUSTOM_PARTNER_ID;
      else
        select ACS_AUXILIARY_ACCOUNT_ID
          into AuxAccountId
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = PartImputTuple.PAC_SUPPLIER_PARTNER_ID;
      end if;

      -- Création imputation sur le compte de frais
      InitAmounts(sign(aPAR_CHARGES_LC) = -1
                , sign(aPAR_CHARGES_LC) = -1
                , aPAR_CHARGES_LC
                , aPAR_CHARGES_FC
                , 0
                , Amount_LC_D
                , Amount_LC_C
                , Amount_FC_D
                , Amount_FC_C
                , Amount_EUR_D
                , Amount_EUR_C
                 );

      if     (aPAR_CHARGES_FC <> 0)
         and (PartImputTuple.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID) then
        FinImputationId  :=
          ChargesImputation(aACT_DOCUMENT_ID
                          , aACS_PERIOD_ID
                          , null
                          , aIMF_TRANSACTION_DATE
                          , aIMF_VALUE_DATE
                          , chargesDescription
                          , Amount_LC_D
                          , Amount_LC_C
                          , PartImputTuple.PAR_EXCHANGE_RATE
                          , PartImputTuple.PAR_BASE_PRICE
                          , Amount_FC_D
                          , Amount_FC_C
                          , Amount_EUR_D
                          , Amount_EUR_C
                          , PartImputTuple.ACS_FINANCIAL_CURRENCY_ID
                          , PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                          , DocumentTuple.ACS_FIN_ACC_S_PAYMENT_ID
                          , DocumentTuple.ACS_FINANCIAL_ACCOUNT_ID
                          , AuxAccountId
                          , PCS.PC_I_LIB_SESSION.GetUserIni
                          , PartImputTuple.ACT_PART_IMPUTATION_ID
                          , null
                           );
      else
        aPAR_CHARGES_FC  := 0;
        FinImputationId  :=
          ChargesImputation(aACT_DOCUMENT_ID
                          , aACS_PERIOD_ID
                          , null
                          , aIMF_TRANSACTION_DATE
                          , aIMF_VALUE_DATE
                          , chargesDescription
                          , Amount_LC_D
                          , Amount_LC_C
                          , 0
                          , 0
                          , Amount_FC_D
                          , Amount_FC_C
                          , Amount_EUR_D
                          , Amount_EUR_C
                          , PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                          , PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                          , DocumentTuple.ACS_FIN_ACC_S_PAYMENT_ID
                          , DocumentTuple.ACS_FINANCIAL_ACCOUNT_ID
                          , AuxAccountId
                          , PCS.PC_I_LIB_SESSION.GetUserIni
                          , PartImputTuple.ACT_PART_IMPUTATION_ID
                          , null
                           );
      end if;

      --Màj des montants frais du part_imputation
      update ACT_PART_IMPUTATION
         set PAR_CHARGES_LC = aPAR_CHARGES_LC
           , PAR_CHARGES_FC = aPAR_CHARGES_FC
       where ACT_PART_IMPUTATION_ID = PartImputTuple.ACT_PART_IMPUTATION_ID;
    end if;

    close PartImputCursor;
  end CreateChargesImputation;

--------------------------
  procedure CreateChargesImputations(
    aACT_DOCUMENT_ID      ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID        ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type
  , aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE       ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aIMF_DESCRIPTION      ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  )
  is
    cursor PartImputCursor(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   PAR.ACT_PART_IMPUTATION_ID
             , PAR.PAC_CUSTOM_PARTNER_ID
             , PAR.PAC_SUPPLIER_PARTNER_ID
             , nvl(PAR.PAR_EXCHANGE_RATE, 0) PAR_EXCHANGE_RATE
             , nvl(PAR.PAR_BASE_PRICE, 0) PAR_BASE_PRICE
             , nvl(PAR.PAR_CHARGES_LC, 0) PAR_CHARGES_LC
             , nvl(PAR.PAR_CHARGES_FC, 0) PAR_CHARGES_FC
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
          from ACT_PART_IMPUTATION PAR
         where PAR.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and nvl(PAR.PAR_CHARGES_LC, 0) != 0
      order by PAR.ACT_PART_IMPUTATION_ID asc;

    DocumentTuple      ACT_DOCUMENT%rowtype;
    Amount_LC_D        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    Amount_LC_C        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    Amount_FC_D        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    Amount_FC_C        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    Amount_EUR_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    Amount_EUR_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    ChargesDescription ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    CatDescription     ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type;
    AuxAccountId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    FinImputationId    ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
  begin
    -- Recherche des infos sur le document
    select *
      into DocumentTuple
      from ACT_DOCUMENT
     where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    if    aIMF_DESCRIPTION is null
       or aIMF_DESCRIPTION = '' then
      CatDescription  := ACT_FUNCTIONS.GetCatalogDescription(DocumentTuple.ACJ_CATALOGUE_DOCUMENT_ID);
    else
      CatDescription  := aIMF_DESCRIPTION;
    end if;

    ChargesDescription          := CatDescription || ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('frais');
    -- recherche si catalogue gére analytique
    ACT_CREATION_SBVR.ExistMAN  := ACT_CREATION_SBVR.IsManDocument(aACT_DOCUMENT_ID);

    for PartImputTuple in PartImputCursor(aACT_DOCUMENT_ID) loop
      if PartImputTuple.PAC_CUSTOM_PARTNER_ID is not null then
        select ACS_AUXILIARY_ACCOUNT_ID
          into AuxAccountId
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = PartImputTuple.PAC_CUSTOM_PARTNER_ID;
      else
        select ACS_AUXILIARY_ACCOUNT_ID
          into AuxAccountId
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = PartImputTuple.PAC_SUPPLIER_PARTNER_ID;
      end if;

      -- Création imputation sur le compte de frais
      InitAmounts(false
                , false
                , PartImputTuple.PAR_CHARGES_LC
                , PartImputTuple.PAR_CHARGES_FC
                , 0
                , Amount_LC_D
                , Amount_LC_C
                , Amount_FC_D
                , Amount_FC_C
                , Amount_EUR_D
                , Amount_EUR_C
                 );

      if     (PartImputTuple.PAR_CHARGES_LC <> 0)
         and (PartImputTuple.ACS_FINANCIAL_CURRENCY_ID <> PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID) then
        FinImputationId  :=
          ChargesImputation(aACT_DOCUMENT_ID
                          , aACS_PERIOD_ID
                          , null
                          , aIMF_TRANSACTION_DATE
                          , aIMF_VALUE_DATE
                          , chargesDescription
                          , Amount_LC_D
                          , Amount_LC_C
                          , PartImputTuple.PAR_EXCHANGE_RATE
                          , PartImputTuple.PAR_BASE_PRICE
                          , Amount_FC_D
                          , Amount_FC_C
                          , Amount_EUR_D
                          , Amount_EUR_C
                          , PartImputTuple.ACS_FINANCIAL_CURRENCY_ID
                          , PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                          , DocumentTuple.ACS_FIN_ACC_S_PAYMENT_ID
                          , DocumentTuple.ACS_FINANCIAL_ACCOUNT_ID
                          , AuxAccountId
                          , PCS.PC_I_LIB_SESSION.GetUserIni
                          , PartImputTuple.ACT_PART_IMPUTATION_ID
                          , null
                           );
      else
        FinImputationId  :=
          ChargesImputation(aACT_DOCUMENT_ID
                          , aACS_PERIOD_ID
                          , null
                          , aIMF_TRANSACTION_DATE
                          , aIMF_VALUE_DATE
                          , chargesDescription
                          , Amount_LC_D
                          , Amount_LC_C
                          , 0
                          , 0
                          , Amount_FC_D
                          , Amount_FC_C
                          , Amount_EUR_D
                          , Amount_EUR_C
                          , PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                          , PartImputTuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                          , DocumentTuple.ACS_FIN_ACC_S_PAYMENT_ID
                          , DocumentTuple.ACS_FINANCIAL_ACCOUNT_ID
                          , AuxAccountId
                          , PCS.PC_I_LIB_SESSION.GetUserIni
                          , PartImputTuple.ACT_PART_IMPUTATION_ID
                          , null
                           );
      end if;
    end loop;
  end CreateChargesImputations;

  procedure CreateAdvance(
    aACT_PART_IMPUTATION_ID    ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aACS_PERIOD_ID             ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type
  , aPAR_ADVANCE_LC         in ACT_PART_IMPUTATION.PAR_CHARGES_LC%type
  , aPAR_ADVANCE_FC         in ACT_PART_IMPUTATION.PAR_CHARGES_FC%type
  , aPAR_ADVANCE_DATE       in date
  , aValueDate              in ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aTransactionDate        in ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aDescription            in ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aInfoImputationValues   in ACT_IMP_MANAGEMENT.InfoImputationValuesRecType
  )
  is
    tpl_PartImputation ACT_PART_IMPUTATION%rowtype;
    vIdAccountAv       ACS_AUXILIARY_ACCOUNT.ACS_PREP_COLL_ID%type;
    vIdAccountAux      ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
    vFinImputationId   ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vDivAccId          ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vSign              number(1);
    vAmountConverted   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    vAmountEuro        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vIMF_AMOUNT_FC_C   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               := 0;
    vIMF_AMOUNT_FC_D   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               := 0;
    vIMF_AMOUNT_LC_C   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type               := 0;
    vIMF_AMOUNT_LC_D   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               := 0;
    vIMF_AMOUNT_EUR_C  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type              := 0;
    vIMF_AMOUNT_EUR_D  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type              := 0;
  begin
    select PART.*
      into tpl_PartImputation
      from ACT_PART_IMPUTATION PART
     where PART.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;

    --Mise à zéro des champs du cour de change
    if tpl_PartImputation.PAR_EXCHANGE_RATE is null then
      tpl_PartImputation.PAR_EXCHANGE_RATE  := 0;
    end if;

    if tpl_PartImputation.PAR_BASE_PRICE is null then
      tpl_PartImputation.PAR_BASE_PRICE  := 0;
    end if;

    --Ajout de l'échéance
    if tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID = tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID then
      ACT_EXPIRY_MANAGEMENT.GenerateExpiriesACT(aACT_PART_IMPUTATION_ID
                                              , null
                                              , null
                                              , null
                                              , 0
                                              , -aPAR_ADVANCE_LC
                                              , 0
                                              , 0
                                              , aPAR_ADVANCE_DATE
                                              , null
                                               );
      vSign  := sign(aPAR_ADVANCE_LC);
    else
      ACS_FUNCTION.ConvertAmount(aPAR_ADVANCE_FC
                               , tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID
                               , tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                               , aTransactionDate
                               , tpl_PartImputation.PAR_EXCHANGE_RATE
                               , tpl_PartImputation.PAR_BASE_PRICE
                               , 1
                               , vAmountEuro
                               , vAmountConverted
                                );
      ACT_EXPIRY_MANAGEMENT.GenerateExpiriesACT(aACT_PART_IMPUTATION_ID
                                              , null
                                              , null
                                              , null
                                              , 0
                                              , -aPAR_ADVANCE_LC
                                              , -aPAR_ADVANCE_FC
                                              , -vAmountEuro
                                              , aPAR_ADVANCE_DATE
                                              , null
                                               );
      vSign  := sign(aPAR_ADVANCE_FC);
    end if;

    if vSign = 0 then
      vSign  := 1;
    end if;

    if tpl_PartImputation.PAC_CUSTOM_PARTNER_ID is not null then
      select ACS_AUXILIARY_ACCOUNT.ACS_PREP_COLL_ID
           , ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID
        into vIdAccountAv
           , vIdAccountAux
        from ACS_AUXILIARY_ACCOUNT
           , PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID = tpl_PartImputation.PAC_CUSTOM_PARTNER_ID
         and ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID = PAC_CUSTOM_PARTNER.ACS_AUXILIARY_ACCOUNT_ID;
    else
      select ACS_AUXILIARY_ACCOUNT.ACS_PREP_COLL_ID
           , ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID
        into vIdAccountAv
           , vIdAccountAux
        from ACS_AUXILIARY_ACCOUNT
           , PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID = tpl_PartImputation.PAC_SUPPLIER_PARTNER_ID
         and ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID = PAC_SUPPLIER_PARTNER.ACS_AUXILIARY_ACCOUNT_ID;
    end if;

    if    (     (tpl_PartImputation.PAC_CUSTOM_PARTNER_ID is not null)
           and (vSign > 0) )
       or (     (tpl_PartImputation.PAC_SUPPLIER_PARTNER_ID is not null)
           and (vSign < 0) ) then
      if tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID = tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID then
        vIMF_AMOUNT_LC_C  := aPAR_ADVANCE_LC * vSign;
        vIMF_AMOUNT_LC_D  := 0;
      else
        ACS_FUNCTION.ConvertAmount(aPAR_ADVANCE_FC
                                 , tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID
                                 , tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                                 , aTransactionDate
                                 , tpl_PartImputation.PAR_EXCHANGE_RATE
                                 , tpl_PartImputation.PAR_BASE_PRICE
                                 , 1
                                 , vAmountEuro
                                 , vAmountConverted
                                  );
        vIMF_AMOUNT_FC_C   := aPAR_ADVANCE_FC * vSign;
        vIMF_AMOUNT_LC_C   := aPAR_ADVANCE_LC * vSign;
        vIMF_AMOUNT_EUR_C  := vAmountEuro;
      end if;
    else
      if tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID = tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID then
        vIMF_AMOUNT_LC_D  := aPAR_ADVANCE_LC * vSign;
        vIMF_AMOUNT_LC_C  := 0;
      else
        ACS_FUNCTION.ConvertAmount(aPAR_ADVANCE_LC
                                 , tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                                 , tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID
                                 , aTransactionDate
                                 , tpl_PartImputation.PAR_EXCHANGE_RATE
                                 , tpl_PartImputation.PAR_BASE_PRICE
                                 , 1
                                 , vAmountEuro
                                 , vAmountConverted
                                  );
        vIMF_AMOUNT_FC_D   := aPAR_ADVANCE_FC * vSign;
        vIMF_AMOUNT_LC_D   := aPAR_ADVANCE_LC * vSign;
        vIMF_AMOUNT_EUR_D  := vAmountEuro;
      end if;
    end if;

    select init_id_seq.nextval
      into vFinImputationId
      from dual;

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
               , IMF_AMOUNT_FC_D
               , IMF_AMOUNT_FC_C
               , IMF_AMOUNT_EUR_D
               , IMF_AMOUNT_EUR_C
               , IMF_VALUE_DATE
               , ACS_TAX_CODE_ID
               , IMF_TRANSACTION_DATE
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACT_DET_PAYMENT_ID
               , IMF_GENRE
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (vFinImputationId
               , aACS_PERIOD_ID
               , tpl_PartImputation.ACT_DOCUMENT_ID
               , vIdAccountAv
               , 'MAN'
               , 0
               , ACT_FUNCTIONS.FormatDescription(aDescription
                                               , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('montant non lettré')
                                               , 100
                                                )
               , vIMF_AMOUNT_LC_D
               , vIMF_AMOUNT_LC_C
               , tpl_PartImputation.PAR_EXCHANGE_RATE
               , vIMF_AMOUNT_FC_D
               , vIMF_AMOUNT_FC_C
               , vIMF_AMOUNT_EUR_D
               , vIMF_AMOUNT_EUR_C
               , aValueDate
               , null
               , aTransactionDate
               , vIdAccountAux
               , null
               , 'STD'
               , tpl_PartImputation.PAR_BASE_PRICE
               , tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID
               , tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID
               , '1'
               , sysdate
               , PCS.PC_I_LIB_SESSION.GETUSERINI
               , aACT_PART_IMPUTATION_ID
                );

    -- màj des info complémentaires
    if aInfoImputationValues.GroupType is not null then
      ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(vFinImputationId, aInfoImputationValues);
    end if;

    if ACS_FUNCTION.ExistDIVI = 1 then
      select min(ACS_DIVISION_ACCOUNT_ID)
        into vDivAccId
        from ACS_AUXILIARY_ACCOUNT
       where ACS_AUXILIARY_ACCOUNT_ID = vIdAccountAux;

      vDivAccId  :=
          ACS_FUNCTION.GetDivisionOfAccount(vIdAccountAv, vDivAccId, aTransactionDate, PCS.PC_I_LIB_SESSION.GETUSERID, 1);

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
                 , vDivAccId
                 , ACS_FUNCTION.GetSubSetIdByAccount(vDivAccId)
                 , init_id_seq.nextval
                 , vFinImputationId
                 , vIMF_AMOUNT_EUR_C
                 , vIMF_AMOUNT_EUR_D
                 , vIMF_AMOUNT_FC_C
                 , vIMF_AMOUNT_FC_D
                 , vIMF_AMOUNT_LC_C
                 , vIMF_AMOUNT_LC_D
                 , ACT_FUNCTIONS.FormatDescription(aDescription
                                                 , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('montant non lettré')
                                                 , 100
                                                  )
                  );
    end if;
  end CreateAdvance;

  procedure CreateAdvance(
    aACT_PART_IMPUTATION_ID    ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aACS_PERIOD_ID             ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type
  , aPAR_ADVANCE_LC         in ACT_PART_IMPUTATION.PAR_CHARGES_LC%type
  , aPAR_ADVANCE_FC         in ACT_PART_IMPUTATION.PAR_CHARGES_FC%type
  , aPAR_ADVANCE_DATE       in date
  , aValueDate              in ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aTransactionDate        in ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aDescription            in ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  )
  is
    vCatalogueId           ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    vPrimaryImpId          ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vInfoImputationValues  ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    vInfoImputationManaged ACT_IMP_MANAGEMENT.InfoImputationRecType;
  begin
    -- recherche des info. compl. sur l'écriture primaire
    begin
      select DOC.ACJ_CATALOGUE_DOCUMENT_ID
           , IMP.ACT_FINANCIAL_IMPUTATION_ID
        into vCatalogueId
           , vPrimaryImpId
        from ACT_FINANCIAL_IMPUTATION IMP
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PART
       where PART.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and DOC.ACT_DOCUMENT_ID = PART.ACT_DOCUMENT_ID
         and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and IMP.IMF_PRIMARY = 1;
    exception
      when no_data_found then
        vCatalogueId  := null;
    end;

    if vCatalogueId is not null then
      vInfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(vCatalogueId);

      if vInfoImputationManaged.managed then
        -- récupération des données compl.
        ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMF(vPrimaryImpId, vInfoImputationValues);
        -- Màj (null) des champs non gérés
        ACT_IMP_MANAGEMENT.UpdateManagedValues(vInfoImputationValues, vInfoImputationManaged.Secondary);
      end if;
    end if;

    -- Execution création avance avec les info. compl.
    CreateAdvance(aACT_PART_IMPUTATION_ID
                , aACS_PERIOD_ID
                , aPAR_ADVANCE_LC
                , aPAR_ADVANCE_FC
                , aPAR_ADVANCE_DATE
                , aValueDate
                , aTransactionDate
                , aDescription
                , vInfoImputationValues
                 );
  end CreateAdvance;
begin
  -- Initialisation des variables
  ln_Hedging  := 0;  --False par défaut
  ln_ResetHedgeRecord := 0;--False par défaut
  ln_UseDiffFinAccount:= 0;--False par défaut
end ACT_PROCESS_PAYMENT;
