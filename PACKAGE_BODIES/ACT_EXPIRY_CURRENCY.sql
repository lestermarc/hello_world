--------------------------------------------------------
--  DDL for Package Body ACT_EXPIRY_CURRENCY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_EXPIRY_CURRENCY" 
is

  -----------------------------
  function UpdateExpiryCurrency(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type,
                                aTargetCurrencyId       ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type) return boolean
  is
    DocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    Ok         boolean   default false;
    Cust       number(1) default 0;
    --------
    function ExpiryCtrl(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type,
                        aTargetCurrencyId       ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type) return boolean
    is
      SourceCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
      Ok               boolean default false;
    -----
    begin
      begin
        select PAR.ACS_FINANCIAL_CURRENCY_ID into SourceCurrencyId
          from
               ACS_FINANCIAL_YEAR     YEA,
               ACJ_CATALOGUE_DOCUMENT CAT,
               ACT_DOCUMENT           DOC,
               ACT_PART_IMPUTATION    PAR
          where
                PAR.ACT_PART_IMPUTATION_ID    = aACT_PART_IMPUTATION_ID
            and PAR.ACT_DOCUMENT_ID           = DOC.ACT_DOCUMENT_ID
            and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
            and CAT.C_TYPE_CATALOGUE in ('2', '5', '6')
            and DOC.ACS_FINANCIAL_YEAR_ID     = YEA.ACS_FINANCIAL_YEAR_ID
            and YEA.C_STATE_FINANCIAL_YEAR    <> 'CLO'
            -- Statut échéance <> '1' (ouvert)
            and not exists (select ACT_EXPIRY_ID
                              from ACT_EXPIRY EXP
                              where EXP.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                                and EXP.EXP_CALC_NET = 1
                                and EXP.C_STATUS_EXPIRY = '1')
            -- Le document ne doit pas posséder de lettrage
            and not exists (select ACT_DET_PAYMENT_ID
                              from ACT_DET_PAYMENT PAY,
                                   ACT_EXPIRY      EXP
                              where EXP.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                                and EXP.EXP_CALC_NET = 1
                                and EXP.ACT_EXPIRY_ID = PAY.ACT_EXPIRY_ID)
            and exists (select ACS_FINANCIAL_CURRENCY_ID
                          from ACS_FINANCIAL_CURRENCY
                          where ACS_FINANCIAL_CURRENCY_ID = aTargetCurrencyId)
            -- Toutes les imputations financières doivent avoir le même identifiant de monnaie étrangère que l'imputation partenaire
            and not exists (select ACT_PART_IMPUTATION_ID
                              from ACT_FINANCIAL_IMPUTATION IMP
                              where IMP.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                                and IMP.ACS_FINANCIAL_CURRENCY_ID <> PAR.ACS_FINANCIAL_CURRENCY_ID);
--        Ok := (SourceCurrencyId <> aTargetCurrencyId) and (SourceCurrencyId  <> LocalCurrencyId)
--                                                      and (aTargetCurrencyId <> LocalCurrencyId);
        Ok := (SourceCurrencyId <> aTargetCurrencyId) and (SourceCurrencyId  <> LocalCurrencyId);
      exception
        when OTHERS then
          Ok := false;
      end;
      return Ok;
    end ExpiryCtrl;

    --------
    function GetDocumentId(aACT_PART_IMPUTATION_ID in     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type,
                           aCust                   in out number) return ACT_DOCUMENT.ACT_DOCUMENT_ID%type
    is
      Id ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    -----
    begin
      begin
        select ACT_DOCUMENT_ID,
               decode(PAC_CUSTOM_PARTNER_ID, null, 0, 1) into Id, aCust
          from ACT_PART_IMPUTATION
          where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;
      exception
        when OTHERS then
          Id := null;
      end;
      return Id;
    end GetDocumentId;

    --------
    function UpdateFCAmounts(aACT_DOCUMENT_ID  ACT_DOCUMENT.ACT_DOCUMENT_ID%type,
                             aTargetCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
                             aCust             number) return boolean
    is
      Ok                  boolean default false;
      PrimaryImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
      DistributionId      ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_DISTRIBUTION_ID%type;
      TaxId               ACT_DET_TAX.ACT_DET_TAX_ID%type;
      AmountLC            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
      BaseCurrencyId      ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type;
      OldAmountFC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
      TransactionDate     ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
      OldCurrency         PCS.PC_CURR.CURRENCY%type;
      ExchangeRate        ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
      BasePrice           ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
      AmountEUR           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
      NewAmountFC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
      OldTaxAmountLC      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
      TaxAmountFC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
      --------
      procedure UpdateExpiriesFCAmount(aACT_DOCUMENT_ID      ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type,
                                       aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
                                       aSourceCurrencyId     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                                       aTargetCurrencyId     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                                       aAmountFC             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type)
      is
        -- Echéances "nettes" d'un document donné, triées par tranches
        cursor NetExpiriesCursor(aACT_DOCUMENT_ID ACT_EXPIRY.ACT_DOCUMENT_ID%type)
        is
          select
                 EXP.ACT_EXPIRY_ID,
                 EXP.EXP_SLICE,
                 EXP.EXP_AMOUNT_LC,
                 case
                   when EXP.EXP_PAC_CUSTOM_PARTNER_ID is null then 0
                   else 1
                 end CUST
            from
                 ACT_EXPIRY          EXP
            where EXP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
              and EXP_CALC_NET        = 1
            order by EXP_SLICE;

        NetExpiries  NetExpiriesCursor%rowtype;

        NewAmountFC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
        NewAmountEUR ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
        ExchangeRate ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
        BasePrice    ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
        TotAmountFC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type default 0;
        AmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type default 0;
        LastId       ACT_EXPIRY.ACT_EXPIRY_ID%type                 default 0;
        LastSlice    ACT_EXPIRY.EXP_SLICE%type                     default 0;
        Cust         boolean;

        -------
        procedure UpdateDiscountExpiries(aACT_DOCUMENT_ID      ACT_EXPIRY.ACT_DOCUMENT_ID%type,
                                         aEXP_SLICE            ACT_EXPIRY.EXP_SLICE%type,
                                         aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
                                         aSourceCurrencyId     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                                         aTargetCurrencyId     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                                         aAmountFC             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type)
        is
          -- Echéances "escomptes" d'un document donné, triées par tranches
          cursor DiscountExpiriesCursor(aACT_DOCUMENT_ID ACT_EXPIRY.ACT_DOCUMENT_ID%type,
                                        aEXP_SLICE       ACT_EXPIRY.EXP_SLICE%type)
          is
            select
                   EXP.ACT_EXPIRY_ID,
                   EXP.EXP_AMOUNT_LC,
                   EXP.EXP_DISCOUNT_LC
              from
                   ACT_EXPIRY EXP
              where EXP.ACT_DOCUMENT_ID        = aACT_DOCUMENT_ID
                and EXP_SLICE                  = aEXP_SLICE
                and EXP_CALC_NET               = 0;

          DiscountExpiries DiscountExpiriesCursor%rowtype;

          NewAmountFC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
          NewDiscountAmountFC ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
          NewAmountEUR        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
          ExchangeRate        ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
          BasePrice           ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
          TotAmountFC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type default 0;
        ---
        begin

          open DiscountExpiriesCursor(aACT_DOCUMENT_ID, aEXP_SLICE);

          fetch DiscountExpiriesCursor into DiscountExpiries;

          while DiscountExpiriesCursor%found loop

            ACT_DOC_TRANSACTION.ConvertAmounts(DiscountExpiries.EXP_AMOUNT_LC, aSourceCurrencyId,
                                               aTargetCurrencyId,              aIMF_TRANSACTION_DATE,
                                               1, -- aRound
                                               1, -- aRateType
                                               ExchangeRate,
                                               BasePrice,
                                               NewAmountEUR,
                                               NewAmountFC);

            ACT_DOC_TRANSACTION.ConvertAmounts(DiscountExpiries.EXP_DISCOUNT_LC, aSourceCurrencyId,
                                               aTargetCurrencyId,                aIMF_TRANSACTION_DATE,
                                               1, -- aRound
                                               1, -- aRateType
                                               ExchangeRate,
                                               BasePrice,
                                               NewAmountEUR,
                                               NewDiscountAmountFC);

            TotAmountFC := NewAmountFC + NewDiscountAmountFC;

            -- Mise à jour échéance "escompte"
            update ACT_EXPIRY
              set EXP_AMOUNT_FC   = NewAmountFC + aAMountFC - TotAmountFC,
                  EXP_DISCOUNT_FC = NewDiscountAmountFC,
                  A_RECSTATUS     = 3
              where ACT_EXPIRY_ID = DiscountExpiries.ACT_EXPIRY_ID;

            fetch DiscountExpiriesCursor into DiscountExpiries;

          end loop;

          close DiscountExpiriesCursor;

        end UpdateDiscountExpiries;
      ----
      begin

        open NetExpiriesCursor(aACT_DOCUMENT_ID);

        fetch NetExpiriesCursor into NetExpiries;

        while NetExpiriesCursor%found loop

          ACT_DOC_TRANSACTION.ConvertAmounts(NetExpiries.EXP_AMOUNT_LC, aSourceCurrencyId,
                                             aTargetCurrencyId,         aIMF_TRANSACTION_DATE,
                                             1, -- aRound
                                             1, -- aRateType
                                             ExchangeRate,
                                             BasePrice,
                                             NewAmountEUR,
                                             NewAmountFC);

          TotAmountFC := TotAmountFC + NewAmountFC;

          -- Mise à jour des échéances nettes
          update ACT_EXPIRY
            set EXP_AMOUNT_FC   = NewAmountFC,
                A_RECSTATUS     = 3
            where ACT_EXPIRY_ID = NetExpiries.ACT_EXPIRY_ID;

          LastId    := NetExpiries.ACT_EXPIRY_ID;
          LastSlice := NetExpiries.EXP_SLICE;
          Cust      := (NetExpiries.CUST = 1);

          -- Mise à jour des échéances avec escompte
          UpdateDiscountExpiries(aACT_DOCUMENT_ID, NetExpiries.EXP_SLICE, aIMF_TRANSACTION_DATE, aSourceCurrencyId, aTargetCurrencyId, NewAmountFC);

          fetch NetExpiriesCursor into NetExpiries;

        end loop;

        close NetExpiriesCursor;

        if Cust then
          AmountFC := aAmountFC * -1;
        else
          AmountFC := aAmountFC;
        end if;

        -- Ajout de l'éventuelle différence sur la dernière échéance nette
        if TotAmountFC <> AmountFC and LastId > 0 then

          update ACT_EXPIRY
            set EXP_AMOUNT_FC = EXP_AMOUNT_FC - TotAmountFC - AMountFC
            where ACT_EXPIRY_ID = LastId;

          select EXP_AMOUNT_FC into AmountFC
            from ACT_EXPIRY
            where ACT_EXPIRY_ID = LastId;

          -- Mise à jour des échéances avec escompte
          UpdateDiscountExpiries(aACT_DOCUMENT_ID, LastSlice, aIMF_TRANSACTION_DATE, aSourceCurrencyId, aTargetCurrencyId, AmountFC);

        end if;

      end UpdateExpiriesFCAmount;

      --------
      procedure UpdateFCMgmImputations(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                                       aTargetCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
                                       aAmountFC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type)
      is
        -- Imputations analytiques d'une imputation financières, triées par montants
        cursor MgmImputationsCursor(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
        is
          select
                 MGI.ACT_MGM_IMPUTATION_ID,
                 MGI.ACS_ACS_FINANCIAL_CURRENCY_ID,
                 nvl(MGI.IMM_AMOUNT_LC_D, 0) - nvl(MGI.IMM_AMOUNT_LC_C, 0) IMM_AMOUNT_LC_D,
                 MGI.IMM_TRANSACTION_DATE
            from
                 ACT_MGM_IMPUTATION MGI
            where
                  MGI.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID
            order by
                     abs(MGI.IMM_AMOUNT_LC_D - MGI.IMM_AMOUNT_LC_C);

        MgmImputations  MgmImputationsCursor%rowtype;

        NewAmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
        ExchangeRate    ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
        BasePrice       ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
        TotAmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type  default 0;
        AmountEUR       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type default 0;
        LastId          ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type  default 0;
        -------
        procedure UpdateFCMgmDistribution(aACT_MGM_IMPUTATION_ID ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type,
                                          aIMM_TRANSACTION_DATE  ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type,
                                          aSourceCurrencyId      ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                                          aTargetCurrencyId      ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                                          aAmountFC              ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type)
        is
          -- Distributions analytiques d'une imputation analytique, triées par montants
          cursor MgmDistributionCursor(aACT_MGM_IMPUTATION_ID ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type)
          is
            select
                   MGD.ACT_MGM_DISTRIBUTION_ID,
                   nvl(MGD.MGM_AMOUNT_LC_D, 0) - nvl(MGD.MGM_AMOUNT_LC_C, 0) MGM_AMOUNT_LC_D
              from
                   ACT_MGM_DISTRIBUTION MGD
              where
                    MGD.ACT_MGM_IMPUTATION_ID = aACT_MGM_IMPUTATION_ID
              order by
                       abs(MGD.MGM_AMOUNT_LC_D - MGD.MGM_AMOUNT_LC_C);

          MgmDistribution MgmDistributionCursor%rowtype;

          NewAmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
          NewAmountEUR    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
          ExchangeRate    ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
          BasePrice       ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
          TotAmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type  default 0;
          LastId          ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type  default 0;

        -----
        begin

          open MgmDistributionCursor(aACT_MGM_IMPUTATION_ID);

          fetch MgmDistributionCursor into MgmDistribution;

          while MgmDistributionCursor%found loop

            ACT_DOC_TRANSACTION.ConvertAmounts(MgmDistribution.MGM_AMOUNT_LC_D, aSourceCurrencyId,
                                               aTargetCurrencyId,               aIMM_TRANSACTION_DATE,
                                               1, -- aRound
                                               1, -- aRateType
                                               ExchangeRate,
                                               BasePrice,
                                               NewAmountEUR,
                                               NewAmountFC);

            TotAmountFC := TotAmountFC + NewAmountFC;

            -- Mise à jour distributions analytiques
            update ACT_MGM_DISTRIBUTION
              set MGM_AMOUNT_FC_D           = decode(sign(NewAmountFC),  1,     NewAmountFC,  0),
                  MGM_AMOUNT_FC_C           = decode(sign(NewAmountFC), -1, abs(NewAmountFC), 0),
                  A_RECSTATUS               = 3
              where ACT_MGM_DISTRIBUTION_ID = MgmDistribution.ACT_MGM_DISTRIBUTION_ID;

            LastId := MgmDistribution.ACT_MGM_DISTRIBUTION_ID;

            fetch MgmDistributionCursor into MgmDistribution;

          end loop;

          close MgmDistributionCursor;

          -- Ajout de l'éventuelle différence sur l'imputation de plus grand montant
          if TotAmountFC <> aAmountFC and LastId > 0 then

            update ACT_MGM_DISTRIBUTION
              set MGM_AMOUNT_FC_D = MGM_AMOUNT_FC_D - decode(sign(MGM_AMOUNT_FC_D - MGM_AMOUNT_FC_C),  1, TotAmountFC - aAMountFC, 0),
                  MGM_AMOUNT_FC_C = MGM_AMOUNT_FC_C + decode(sign(MGM_AMOUNT_FC_D - MGM_AMOUNT_FC_C), -1, TotAmountFC - aAmountFC, 0)
              where ACT_MGM_DISTRIBUTION_ID = LastId;

          end if;

        end UpdateFCMgmDistribution;
      ----
      begin

        open MgmImputationsCursor(aACT_FINANCIAL_IMPUTATION_ID);

        fetch MgmImputationsCursor into MgmImputations;

        while MgmImputationsCursor%found loop

          ACT_DOC_TRANSACTION.ConvertAmounts(MgmImputations.IMM_AMOUNT_LC_D, MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID,
                                             aTargetCurrencyId,              MgmImputations.IMM_TRANSACTION_DATE,
                                             1, -- aRound
                                             1, -- aRateType
                                             ExchangeRate,
                                             BasePrice,
                                             AmountEUR,
                                             NewAmountFC);

          TotAmountFC := TotAmountFC + NewAmountFC;

          -- Mise à jour imputations analytiques
          update ACT_MGM_IMPUTATION
            set IMM_AMOUNT_FC_D           = decode(sign(NewAmountFC),  1,     NewAmountFC,  0),
                IMM_AMOUNT_FC_C           = decode(sign(NewAmountFC), -1, abs(NewAmountFC), 0),
                ACS_FINANCIAL_CURRENCY_ID = aTargetCurrencyId,
                IMM_EXCHANGE_RATE         = ExchangeRate,
                IMM_BASE_PRICE            = BasePrice,
                A_RECSTATUS               = 3
            where ACT_MGM_IMPUTATION_ID = MgmImputations.ACT_MGM_IMPUTATION_ID;

          LastId          := MgmImputations.ACT_MGM_IMPUTATION_ID;
          TransactionDate := MgmImputations.IMM_TRANSACTION_DATE;
          BaseCurrencyId  := MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID;

          -- Mise à jour distributions analytiques sur la base du montant de l'imputation analytique correspondante
          UpdateFCMgmDistribution(MgmImputations.ACT_MGM_IMPUTATION_ID,
                                  MgmImputations.IMM_TRANSACTION_DATE,
                                  MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID,
                                  aTargetCurrencyId,
                                  NewAmountFC);

          fetch MgmImputationsCursor into MgmImputations;

        end loop;

        close MgmImputationsCursor;

        -- Ajout de l'éventuelle différence sur l'imputation de plus grand montant
        if TotAmountFC <> aAmountFC and LastId > 0 then

          update ACT_MGM_IMPUTATION
            set IMM_AMOUNT_FC_D = IMM_AMOUNT_FC_D - decode(sign(IMM_AMOUNT_FC_D - IMM_AMOUNT_FC_C),  1, TotAmountFC - aAMountFC, 0),
                IMM_AMOUNT_FC_C = IMM_AMOUNT_FC_C + decode(sign(IMM_AMOUNT_FC_D - IMM_AMOUNT_FC_C), -1, TotAmountFC - aAmountFC, 0)
            where ACT_MGM_IMPUTATION_ID = LastId;

          -- Montant à imputer sur les distributions liées
          select nvl(IMM_AMOUNT_LC_D, 0) - nvl(IMM_AMOUNT_LC_C, 0) into NewAmountFC
            from ACT_MGM_IMPUTATION
            where ACT_MGM_IMPUTATION_ID = LastId;

          -- Mise à jour distributions analytiques sur la base du montant de l'imputation analytique correspondante
          UpdateFCMgmDistribution(LastId,         TransactionDate,
                                  BaseCurrencyId, aTargetCurrencyId,
                                  NewAmountFC);
        end if;

      end UpdateFCMgmImputations;

      --------
      procedure UpdateFCImputations(aACT_DOCUMENT_ID  ACT_DOCUMENT.ACT_DOCUMENT_ID%type,
                                    aTargetCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
                                    aAmountFC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type)
      is
        -- Imputations financières (avec distribution) d'un document donné
        cursor FinImputationsCursor is
          select
                 IMP.ACT_FINANCIAL_IMPUTATION_ID,
                 (select DIS.ACT_FINANCIAL_DISTRIBUTION_ID from ACT_FINANCIAL_DISTRIBUTION DIS where IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID) ACT_FINANCIAL_DISTRIBUTION_ID,
                 TAX.ACT_DET_TAX_ID,
                 IMP.ACS_ACS_FINANCIAL_CURRENCY_ID,
                 nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) IMF_AMOUNT_LC_D,
                 IMP.IMF_TRANSACTION_DATE,
                 TAX.TAX_VAT_AMOUNT_LC
            from ACT_DET_TAX                TAX,
                 ACT_FINANCIAL_IMPUTATION   IMP
            where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
              and IMP.IMF_PRIMARY                 = 0
              and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT_FINANCIAL_IMPUTATION_ID (+);

        FinImputations   FinImputationsCursor%rowtype;

        ExchangeRate     ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
        BasePrice        ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
        AmountEUR        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
        NewAmountFC      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
        TaxAmountFC      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;

        TotAmountFC      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type default 0;
        HighestAmount    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type default 0;
        HighestAmountId  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type default 0;
        HighestAmountId2 ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type default 0;
        SignHighest      number(1);
      ----
      begin

        open FinImputationsCursor;
        fetch FinImputationsCursor into FinImputations;

        while FinImputationsCursor%found loop

          ACT_DOC_TRANSACTION.ConvertAmounts(FinImputations.IMF_AMOUNT_LC_D, FinImputations.ACS_ACS_FINANCIAL_CURRENCY_ID,
                                             aTargetCurrencyId,              FinImputations.IMF_TRANSACTION_DATE,
                                             1, -- aRound
                                             1, -- aRateType
                                             ExchangeRate,
                                             BasePrice,
                                             AmountEUR,
                                             NewAmountFC);

          TotAmountFC  := TotAmountFC  + NewAmountFC;
          if abs(NewAmountFC) > HighestAmount then
            HighestAmount    := abs(NewAmountFC);
            HighestAmountId  := FinImputations.ACT_FINANCIAL_IMPUTATION_ID;
            HighestAmountId2 := FinImputations.ACT_FINANCIAL_DISTRIBUTION_ID;
            SignHighest      := sign(NewAmountFC);
          end if;

          -- Mise à jour imputations financières
          update ACT_FINANCIAL_IMPUTATION
            set IMF_AMOUNT_FC_D           = decode(sign(NewAmountFC),  1,     NewAmountFC,  0),
                IMF_AMOUNT_FC_C           = decode(sign(NewAmountFC), -1, abs(NewAmountFC), 0),
                ACS_FINANCIAL_CURRENCY_ID = aTargetCurrencyId,
                IMF_EXCHANGE_RATE         = ExchangeRate,
                IMF_BASE_PRICE            = BasePrice,
                A_RECSTATUS               = 3
            where ACT_FINANCIAL_IMPUTATION_ID = FinImputations.ACT_FINANCIAL_IMPUTATION_ID;
          -- Mise à jour distributions (division)
          if FinImputations.ACT_FINANCIAL_DISTRIBUTION_ID is not null then
            update ACT_FINANCIAL_DISTRIBUTION
              set FIN_AMOUNT_FC_D = decode(sign(NewAmountFC),  1,     NewAmountFC,  0),
                  FIN_AMOUNT_FC_C = decode(sign(NewAmountFC), -1, abs(NewAmountFC), 0),
                  A_RECSTATUS     = 3
              where ACT_FINANCIAL_DISTRIBUTION_ID = FinImputations.ACT_FINANCIAL_DISTRIBUTION_ID;
          end if;
          -- Mise à jour imputations taxes (TVA)
          if FinImputations.ACT_DET_TAX_ID is not null then
            ACT_DOC_TRANSACTION.ConvertAmounts(FinImputations.TAX_VAT_AMOUNT_LC, FinImputations.ACS_ACS_FINANCIAL_CURRENCY_ID,
                                               aTargetCurrencyId,                FinImputations.IMF_TRANSACTION_DATE,
                                               1, -- aRound
                                               1, -- aRateType
                                               ExchangeRate,
                                               BasePrice,
                                               AmountEUR,
                                               TaxAmountFC);
            update ACT_DET_TAX
              set TAX_VAT_AMOUNT_FC = TaxAmountFC,
                  TAX_EXCHANGE_RATE = ExchangeRate,
                  DET_BASE_PRICE    = BasePrice,
                  A_RECSTATUS       = 3
              where ACT_DET_TAX_ID = FinImputations.ACT_DET_TAX_ID;
          end if;

          -- Mise à jour imputations analytiques sur la base du montant de l'imputation financière correspondante
          UpdateFCMgmImputations(FinImputations.ACT_FINANCIAL_IMPUTATION_ID, aTargetCurrencyId, NewAmountFC);

          fetch FinImputationsCursor into FinImputations;

        end loop;

        close FinImputationsCursor;

        -- Ajout de l'éventuelle différence sur l'imputation de plus grand montant
        if TotAmountFC <> aAmountFC * -1 then

          -- Mise à jour imputations financières
          update ACT_FINANCIAL_IMPUTATION
            set IMF_AMOUNT_FC_D  = IMF_AMOUNT_FC_D  - decode(SignHighest,  1, TotAmountFC  - aAmountFC * -1,  0),
                IMF_AMOUNT_FC_C  = IMF_AMOUNT_FC_C  + decode(SignHighest, -1, TotAmountFC  - aAmountFC * -1,  0)
            where ACT_FINANCIAL_IMPUTATION_ID = HighestAmountId;

          -- Mise à jour distributions (division)
          if HighestAmountId2 is not null then

            update ACT_FINANCIAL_DISTRIBUTION
              set FIN_AMOUNT_FC_D   = FIN_AMOUNT_FC_D  - decode(SignHighest,  1, TotAmountFC  - aAmountFC * -1,  0),
                  FIN_AMOUNT_FC_C   = FIN_AMOUNT_FC_C  + decode(SignHighest, -1, TotAmountFC  - aAmountFC * -1,  0)
              where ACT_FINANCIAL_DISTRIBUTION_ID = HighestAmountId2;

          end if;

          -- Et la TVA, elle compte pour du beurre fondu ???
          -- Et la TVA, elle compte pour du beurre fondu ???
          -- Et la TVA, elle compte pour du beurre fondu ???

          -- Montants à imputer sur les imputations analytiques liées à l'imputation financière
          select nvl(IMF_AMOUNT_FC_D, 0) - nvl(IMF_AMOUNT_FC_C, 0) into NewAmountFC
            from ACT_FINANCIAL_IMPUTATION
            where ACT_FINANCIAL_IMPUTATION_ID = HighestAmountId;

          -- Mise à jour imputations analytiques sur la base du montant de l'imputation financière correspondante
          UpdateFCMgmImputations(HighestAmountId, aTargetCurrencyId, NewAmountFC);

        end if;

      end UpdateFCImputations;
    -----
    begin
      begin
        -- Imputation primaire
        select
               IMP.ACT_FINANCIAL_IMPUTATION_ID,
               DIS.ACT_FINANCIAL_DISTRIBUTION_ID,
               TAX.ACT_DET_TAX_ID,
               IMP.ACS_ACS_FINANCIAL_CURRENCY_ID,
               nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0),
               nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0),
               TAX.TAX_VAT_AMOUNT_LC,
               IMP.IMF_TRANSACTION_DATE,
               CUR.CURRENCY into PrimaryImputationId,
                                 DistributionId,
                                 TaxId,
                                 BaseCurrencyId,
                                 AmountLC,
                                 OldAmountFC,
                                 OldTaxAmountLC,
                                 TransactionDate,
                                 OldCurrency
          from
               PCS.PC_CURR                CUR,
               ACS_FINANCIAL_CURRENCY     FCUR,
               ACT_DET_TAX                TAX,
               ACT_FINANCIAL_DISTRIBUTION DIS,
               ACT_FINANCIAL_IMPUTATION   IMP
          where
                IMP.ACT_DOCUMENT_ID             = aACT_DOCUMENT_ID
            and IMP.IMF_PRIMARY                 = 1
            and IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID (+)
            and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT_FINANCIAL_IMPUTATION_ID (+)
            and IMP.ACS_FINANCIAL_CURRENCY_ID   = FCUR.ACS_FINANCIAL_CURRENCY_ID
            and FCUR.PC_CURR_ID                 = CUR.PC_CURR_ID
          for update of IMP.IMF_AMOUNT_LC_D,
                        DIS.FIN_AMOUNT_LC_D,
                        TAX.TAX_VAT_AMOUNT_FC;
        Ok := true;
      exception
        when OTHERS then
          Ok := false;
      end;
      if Ok then
        -- Mise à jour imputation primaire
        ACT_DOC_TRANSACTION.ConvertAmounts(AmountLC, BaseCurrencyId,
                                                     aTargetCurrencyId,
                                                     TransactionDate,
                                                     1, -- aRound
                                                     1, -- aRateType
                                                     ExchangeRate,
                                                     BasePrice,
                                                     AmountEUR,
                                                     NewAmountFC);

        update ACT_FINANCIAL_IMPUTATION
          set IMF_AMOUNT_FC_D           = decode(sign(NewAmountFC),  1,     NewAmountFC,  0),
              IMF_AMOUNT_FC_C           = decode(sign(NewAmountFC), -1, abs(NewAmountFC), 0),
              ACS_FINANCIAL_CURRENCY_ID = aTargetCurrencyId,
              IMF_EXCHANGE_RATE         = ExchangeRate,
              IMF_BASE_PRICE            = BasePrice,
              A_RECSTATUS               = 3
          where ACT_FINANCIAL_IMPUTATION_ID = PrimaryImputationId;
        if DistributionId is not null then
          update ACT_FINANCIAL_DISTRIBUTION
            set FIN_AMOUNT_FC_D = decode(sign(NewAmountFC),  1,     NewAmountFC,  0),
                FIN_AMOUNT_FC_C = decode(sign(NewAmountFC), -1, abs(NewAmountFC), 0),
                 A_RECSTATUS    = 3
            where ACT_FINANCIAL_DISTRIBUTION_ID = DistributionId;
        end if;
        if TaxId is not null then
          ACT_DOC_TRANSACTION.ConvertAmounts(OldTaxAmountLC, BaseCurrencyId,
                                                             aTargetCurrencyId,
                                                             TransactionDate,
                                                             1, -- aRound
                                                             1, -- aRateType
                                                             ExchangeRate,
                                                             BasePrice,
                                                             AmountEUR,
                                                             TaxAmountFC);
          update ACT_DET_TAX
            set TAX_VAT_AMOUNT_FC = TaxAmountFC,
                A_RECSTATUS       = 3
            where ACT_DET_TAX_ID = TaxId;
        end if;
        -- Mise à jour Echéances
        UpdateExpiriesFCAmount(aACT_DOCUMENT_ID, TransactionDate, BaseCurrencyId, aTargetCurrencyId, NewAmountFC);
        -- Mise à jour Contres-écritures
        UpdateFCImputations(aACT_DOCUMENT_ID, aTargetCurrencyId, NewAmountFC);
        -- Mise à jour imputation analytique imputation primaire
        UpdateFCMgmImputations(PrimaryImputationId, aTargetCurrencyId, NewAmountFC);


        update ACT_DOCUMENT
          set ACS_FINANCIAL_CURRENCY_ID = aTargetCurrencyId,
              DOC_TOTAL_AMOUNT_DC       = decode(aCust, 1, 1, -1) * DECODE(aTargetCurrencyId,BaseCurrencyId,AmountLC,NewAmountFC),
              DOC_COMMENT               = decode(DOC_COMMENT, null, OldCurrency || ' ' || to_char(decode(aCust, 1, OldAmountFC, OldAmountFC * -1), '999,999.99'), substr(DOC_COMMENT || ' ' || OldCurrency || ' ' || to_char(decode(aCust, 1, OldAmountFC, OldAmountFC * -1), '999,999.99'), 1, 100)),
              A_RECSTATUS               = 3
          where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

        update ACT_PART_IMPUTATION
          set ACS_FINANCIAL_CURRENCY_ID = aTargetCurrencyId,
              A_RECSTATUS               = 3
          where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      end if;
      return Ok;
    end UpdateFCAmounts;

  -----
  begin

    Ok := ExpiryCtrl(aACT_PART_IMPUTATION_ID, aTargetCurrencyId);

    if Ok then

      DocumentId := GetDocumentId(aACT_PART_IMPUTATION_ID, Cust);
      -- Recalcul cumuls document : Retrait des cumuls
      ACT_DOC_TRANSACTION.DocImputations(DocumentId, 0);

      Ok := UpdateFCAmounts(DocumentId, aTargetCurrencyId, Cust);

      -- Recalcul cumuls document
      ACT_DOC_TRANSACTION.DocImputations(DocumentId, 0);

    end if;

    return Ok;

  end UpdateExpiryCurrency;

-- Initialisation des variables pour la session
-----
begin
  UserIni         := PCS.PC_I_LIB_SESSION.GetUserIni;
  UserId          := PCS.PC_I_LIB_SESSION.GetUserId;
  LocalCurrencyId := ACS_FUNCTION.GetLocalCurrencyId;
end ACT_EXPIRY_CURRENCY;
