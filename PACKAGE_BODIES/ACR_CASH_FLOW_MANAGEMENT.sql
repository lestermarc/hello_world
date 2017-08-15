--------------------------------------------------------
--  DDL for Package Body ACR_CASH_FLOW_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_CASH_FLOW_MANAGEMENT" 
is
  procedure CreateCashFlowFootPosition( iCashFlowAnalysisId in ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
                                      , iType               in ACR_CASH_FLOW_IMPUTATION.C_CASH_FLOW_IMP_TYP%type
                                      , iWeek               in ACR_CASH_FLOW_FOOT.CFT_WEEK%type
                                      , iLiqAmount          in ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                                      , iVariationTotal     in ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                                      , iVariationAmount    in ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                                      , iCreditUseAmount    in ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                                      , iCreditLimit        in ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                                      , iCreditDefSur       in ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                                      )


  is
  begin
    insert into ACR_CASH_FLOW_FOOT(
        ACR_CASH_FLOW_ANALYSIS_ID
      , C_CASH_FLOW_IMP_TYP
      , CFT_WEEK
      , CFT_LIQUIDITY_AMOUNT
      , CFT_VARIATION_TOTAL
      , CFT_LIQ_VARIATION_AMOUNT
      , CFT_CREDIT_USE_AMOUNT
      , CFT_CREDIT_LIMIT
      , CFT_CREDIT_DEFICITSURPLUS)
    values(iCashFlowAnalysisId
         , iType
         , iWeek
         , iLiqAmount
         , iVariationTotal
         , iVariationAmount
         , iCreditUseAmount
         , iCreditLimit
         , iCreditDefSur
           );
  end CreateCashFlowFootPosition;


  /**
  * Description Create foot table rows based on ACR_CASH_FLOW_IMPUTATION records;
  **/
  procedure CreateFootTableRows(iCashFlowAnalysisId in ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
                              , iAnalysisStartDate  in ACS_PERIOD.PER_START_DATE%type
                              , iAnalysisEndDate    in ACS_PERIOD.PER_END_DATE%type
                              , iEffAmounts         in ACR_CASH_FLOW_ANALYSIS.CFA_EFF_AMOUNTS%type
                              , iPlaAmounts         in ACR_CASH_FLOW_ANALYSIS.CFA_PLA_AMOUNTS%type
  )
  is
    /*Défini la structure en semaine de la période d'analyse */
    cursor lcurAnalysisPeriodWeeks(iStartDate  in ACS_PERIOD.PER_START_DATE%type
                                 , iEndDate    in ACS_PERIOD.PER_END_DATE%type)
    is
      select substr(to_week(iStartDate), 1, 5) || '00' WEEK
        from dual
      union all
      select to_week(PYW_BEGIN_WEEK)
        from PCS.PC_YEAR_WEEK WEEKS
      where PYW_BEGIN_WEEK between iStartDate and iEndDate
      union all
      select substr(to_week(iEndDate), 1, 5) || '99'
        from dual;


    lAnalysisPeriod     lcurAnalysisPeriodWeeks%rowtype;
    lLiquidityAmount    ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type; --Solde des comptes de liquidités
    lCreditLimit        ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type; --Limite de crédit
    lLiqVariationAmount ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type; --Variations de liquidités courante
    lPreviousVarTotal   ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type; --Variations de liquidités précédente
    lVariationTotal     ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type; --Cumul des variations
    lCreditUseAmount    ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type; --Utilisation de crédit
    lCreditDefSur       ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type; --Excédent/insuffisance de crédit
    lCurrentType        ACR_CASH_FLOW_IMPUTATION.C_CASH_FLOW_IMP_TYP%type;
    procedure GetWeekImpAmounts(iCashFlowAnalysisId in ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
                              , iStartDate          in ACS_PERIOD.PER_START_DATE%type
                              , iEndDate            in ACS_PERIOD.PER_END_DATE%type
                              , iWeek               in ACR_CASH_FLOW_FOOT.CFT_WEEK%type
                              , iType               in ACR_CASH_FLOW_IMPUTATION.C_CASH_FLOW_IMP_TYP%type
                              , iLiqAmount          in out  ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                              , iVariationTotal     in out ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                              , iPreviousVarTotal   in ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                              , iVariationAmount    in out ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                              , iCreditUseAmount    in out ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                              , iCreditLimit        in out ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                              , iCreditDefSur       in out ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
                              )
    is
      /*Récupère le montants d'imputation de l'analyse */
      cursor lcurAnalysisImputation(iAnalysisId in ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type )
      is
        select CFI.C_CASH_FLOW_IMP_TYP
             , decode(CFI.C_CASH_FLOW_IMP_TYP
                    , 'LIR', 'LIQ'
                    , 'PLR', 'PLA'
                    , 'PLB', 'PLA'
                    , 'PRB', 'PLA'
                    , 'POD', 'PLA'
                    , 'POR', 'PLA'
                    , 'SAL', 'PLA'
                    , 'PER', 'PLA'
                    , 'PED', 'PLA'
                    , CFI.C_CASH_FLOW_IMP_TYP
                     ) C_IMP_TYP
             , sum(CFI.CFI_AMOUNT_LC_D - CFI.CFI_AMOUNT_LC_C) *
                decode(CFI.C_CASH_FLOW_IMP_TYP, 'LIQ', 1, 'LIR', 1, 'LIM', 1, 'POD', 1, 'POR', 1, 'PED', 1, 'PER', 1, -1) IMP_AMOUNT
             , TO_WEEK(CFI.CFI_DATE) WEEK
             , CFI.CFI_DATE
          from ACR_CASH_FLOW_IMPUTATION CFI
        where CFI.ACR_CASH_FLOW_ANALYSIS_ID = iAnalysisId
        group by  CFI.C_CASH_FLOW_IMP_TYP
               , CFI.CFI_DATE
        order by  CFI.C_CASH_FLOW_IMP_TYP
               , CFI.CFI_DATE;
      lAnalysisImp        lcurAnalysisImputation%rowtype;
    begin
      open lcurAnalysisImputation(iCashFlowAnalysisId);

      fetch lcurAnalysisImputation
      into lAnalysisImp;

      while lcurAnalysisImputation%found
      loop
        if(
          (lAnalysisImp.WEEK = iWeek) or
          ((lAnalysisImp.CFI_DATE < iStartDate) and (substr(iWeek,length(iWeek)-1, 2) = '00')) or
          ((lAnalysisImp.CFI_DATE > iEndDate)   and (substr(iWeek,length(iWeek)-1, 2) = '99'))
          )
         then

           if lAnalysisImp.C_CASH_FLOW_IMP_TYP = 'LIM' then
             iCreditLimit := iCreditLimit + lAnalysisImp.IMP_AMOUNT;
           end if;
           if lAnalysisImp.C_IMP_TYP = 'LIQ' then
             iLiqAmount := iLiqAmount +  lAnalysisImp.IMP_AMOUNT;
           end if;

           if iType =  'EFF' then
             if lAnalysisImp.C_CASH_FLOW_IMP_TYP = 'LIQ' then
               iVariationAmount := lAnalysisImp.IMP_AMOUNT;
             end if;
           elsif iType =  'PLA' then
             if lAnalysisImp.C_CASH_FLOW_IMP_TYP = 'PLA' then
               iVariationAmount :=iVariationAmount + lAnalysisImp.IMP_AMOUNT;
             end if;
             if lAnalysisImp.C_IMP_TYP in ('PLA') then
               iVariationTotal := iVariationTotal + lAnalysisImp.IMP_AMOUNT;
             end if;
           end if;
        end if;
        fetch lcurAnalysisImputation
        into lAnalysisImp;
      end loop;
      close lcurAnalysisImputation;

      if iType =  'PLA' then
        iCreditUseAmount  := lLiquidityAmount + lPreviousVarTotal;
        iCreditDefSur     := iCreditUseAmount + iCreditLimit;
      end if;
    end GetWeekImpAmounts;
begin
    /* Suppression des enregistrements existants de la même analyse */
    delete from ACR_CASH_FLOW_FOOT
    where ACR_CASH_FLOW_ANALYSIS_ID = iCashFlowAnalysisId;
    /* Parcours des semaines de la période                    */
    /*    Parcours des imputations                            */
    /*      Semaine période analyse = semaine imputation      */
    /*        Calcul des montants                             */
    /*        Ajout d'une position de pied                    */
    /*Initialisation variables */
    lLiquidityAmount    := 0.0;
    lCreditLimit        := 0.0;
    lLiqVariationAmount := 0.0;
    lPreviousVarTotal   := 0.0;
    lVariationTotal     := 0.0;
    lCreditUseAmount    := 0.0;
    lCreditDefSur       := 0.0;
    if iEffAmounts = 1 then
      lCurrentType        := 'EFF';
      open lcurAnalysisPeriodWeeks(iAnalysisStartDate , iAnalysisEndDate);
      fetch   lcurAnalysisPeriodWeeks into lAnalysisPeriod;
      while lcurAnalysisPeriodWeeks%found
      loop
        GetWeekImpAmounts(iCashFlowAnalysisId
                        , iAnalysisStartDate
                        , iAnalysisEndDate
                        , lAnalysisPeriod.WEEK
                        , lCurrentType
                        , lLiquidityAmount
                        , lVariationTotal
                        , lPreviousVarTotal
                        , lLiqVariationAmount
                        , lCreditUseAmount
                        , lCreditLimit
                        , lCreditDefSur
                        );
        CreateCashFlowFootPosition( iCashFlowAnalysisId
                                  , lCurrentType
                                  , lAnalysisPeriod.WEEK
                                  , lLiquidityAmount
                                  , lPreviousVarTotal
                                  , lLiqVariationAmount
                                  , lCreditUseAmount
                                  , lCreditLimit
                                  , lCreditDefSur);
        lLiqVariationAmount := 0.0;
        lPreviousVarTotal   := lVariationTotal;
        fetch   lcurAnalysisPeriodWeeks into lAnalysisPeriod;
      end loop;
      close  lcurAnalysisPeriodWeeks ;
    end if;

    lLiquidityAmount    := 0.0;
    lCreditLimit        := 0.0;
    lLiqVariationAmount := 0.0;
    lPreviousVarTotal   := 0.0;
    lVariationTotal     := 0.0;
    lCreditUseAmount    := 0.0;
    lCreditDefSur       := 0.0;
    if iPlaAmounts = 1 then
      lCurrentType        := 'PLA';
      open lcurAnalysisPeriodWeeks(iAnalysisStartDate , iAnalysisEndDate);
      fetch   lcurAnalysisPeriodWeeks into lAnalysisPeriod;
      while lcurAnalysisPeriodWeeks%found
      loop
        GetWeekImpAmounts(iCashFlowAnalysisId
                        , iAnalysisStartDate
                        , iAnalysisEndDate
                        , lAnalysisPeriod.WEEK
                        , lCurrentType
                        , lLiquidityAmount
                        , lVariationTotal
                        , lPreviousVarTotal
                        , lLiqVariationAmount
                        , lCreditUseAmount
                        , lCreditLimit
                        , lCreditDefSur
                        );
        CreateCashFlowFootPosition( iCashFlowAnalysisId
                                  , lCurrentType
                                  , lAnalysisPeriod.WEEK
                                  , lLiquidityAmount
                                  , lPreviousVarTotal
                                  , lLiqVariationAmount
                                  , lCreditUseAmount
                                  , lCreditLimit
                                  , lCreditDefSur);
        lLiqVariationAmount := 0.0;
        lPreviousVarTotal   := lVariationTotal;
        fetch lcurAnalysisPeriodWeeks into lAnalysisPeriod;
      end loop;
      close  lcurAnalysisPeriodWeeks ;
    end if;
  end CreateFootTableRows;
-------------------------------
  function GetSubSetDateWeighting(
    aACR_CASH_FLOW_ANALYSIS_ID ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
  , aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  )
    return ACR_CF_DATE_WEIGHTING%rowtype
  is
    Weighting ACR_CF_DATE_WEIGHTING%rowtype;
  begin
    begin
      select CFW.*
        into Weighting
        from ACR_CF_DATE_WEIGHTING CFW
           , ACS_ACCOUNT ACC
       where ACC.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID
         and ACC.ACS_SUB_SET_ID = CFW.ACS_SUB_SET_ID
         and CFW.ACR_CASH_FLOW_ANALYSIS_ID = aACR_CASH_FLOW_ANALYSIS_ID;
    exception
      when others then
        Weighting.CFW_WEIGHTING  := 0;
    end;

    return Weighting;
  end GetSubSetDateWeighting;

-------------------------
  function GetFactorPartner(
    aPAC_THIRD_ID            PAC_PERSON.PAC_PERSON_ID%type
  , aCUST                    number
  , aC_WEIGHTING_DATE_METHOD ACR_CF_DATE_WEIGHTING.C_WEIGHTING_DATE_METHOD%type
  )
    return PAC_CUSTOM_PARTNER.CUS_PAYMENT_FACTOR%type
  is
    vFactor PAC_CUSTOM_PARTNER.CUS_PAYMENT_FACTOR%type default 0;
  begin
    if aCUST = 1 then
      select decode(aC_WEIGHTING_DATE_METHOD
                  , '02', nvl(max(CUS.CUS_PAYMENT_FACTOR), 0)
                  , '03', nvl(max(CUS.CUS_ADAPTED_FACTOR), 0)
                  , ''
                   )
        into vFactor
        from PAC_CUSTOM_PARTNER CUS
       where PAC_CUSTOM_PARTNER_ID = aPAC_THIRD_ID;
    else
      select decode(aC_WEIGHTING_DATE_METHOD
                  , '02', nvl(max(SUP.CRE_PAYMENT_FACTOR), 0)
                  , '03', nvl(max(SUP.CRE_ADAPTED_FACTOR), 0)
                  , ''
                   )
        into vFactor
        from PAC_SUPPLIER_PARTNER SUP
       where PAC_SUPPLIER_PARTNER_ID = aPAC_THIRD_ID;
    end if;

    return vFactor;
  end GetFactorPartner;

--------------------------------
  procedure NewAnalysisImputations(aACR_CASH_FLOW_ANALYSIS_ID ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type)
  is
    lv_GalCashGroupOrderProc constant varchar2(255)  := PCS.PC_CONFIG.GetConfig('GAL_CASH_GROUP_ORDER_PROC');
    DateFrom         ACS_PERIOD.PER_START_DATE%type;
    DateTo           ACS_PERIOD.PER_END_DATE%type;
    AmountLC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountLC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    AmountFC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountFC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    AmountEUR_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    AmountEUR_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    ExchangeRate     ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePrice        ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    CashFlowAnalysis ACR_CASH_FLOW_ANALYSIS%rowtype;

    ---------
    procedure InsertExpiriesImputation(
      aACR_CASH_FLOW_ANALYSIS_ID ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
    , aCFA_PLA_ALL_DATES         ACR_CASH_FLOW_ANALYSIS.CFA_PLA_ALL_DATES%type
    , aDateFrom                  ACS_PERIOD.PER_START_DATE%type
    , aDateTo                    ACS_PERIOD.PER_END_DATE%type
    , aCFA_DATE                  ACR_CASH_FLOW_ANALYSIS.CFA_DATE%type
    )
    is
      TotAmountLC              ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
      TotAmountFC              ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;

      cursor ExpiriesCursor(aCFA_DATE ACR_CASH_FLOW_ANALYSIS.CFA_DATE%type)
      is
        select EXP.ACT_DOCUMENT_ID
             , EXP.ACT_PART_IMPUTATION_ID
             , EXP.ACT_EXPIRY_ID
             , EXP.EXP_ADAPTED
             , case
                 when EXP.EXP_PAC_SUPPLIER_PARTNER_ID is null then EXP.EXP_AMOUNT_LC
                 else EXP.EXP_AMOUNT_LC * -1
               end EXP_AMOUNT_LC
             , case
                 when EXP.EXP_PAC_SUPPLIER_PARTNER_ID is null then EXP.EXP_AMOUNT_FC
                 else EXP.EXP_AMOUNT_FC * -1
               end EXP_AMOUNT_FC
             , EXP.EXP_POURCENT
             , case
                 when EXP.EXP_PAC_SUPPLIER_PARTNER_ID is null then ACT_FUNCTIONS.TotalPaymentAt(EXP.ACT_EXPIRY_ID
                                                                                              , aCFA_DATE
                                                                                              , 1
                                                                                               )
                 else ACT_FUNCTIONS.TotalPaymentAt(EXP.ACT_EXPIRY_ID, aCFA_DATE, 1) * -1
               end DET_PAIED_LC
             , case
                 when EXP.EXP_PAC_SUPPLIER_PARTNER_ID is null then ACT_FUNCTIONS.TotalPaymentAt(EXP.ACT_EXPIRY_ID
                                                                                              , aCFA_DATE
                                                                                              , 0
                                                                                               )
                 else ACT_FUNCTIONS.TotalPaymentAt(EXP.ACT_EXPIRY_ID, aCFA_DATE, 0) * -1
               end DET_PAIED_FC
             , IMP.IMF_VALUE_DATE
             , IMP.ACS_AUXILIARY_ACCOUNT_ID
             , case
                 when EXP.EXP_PAC_SUPPLIER_PARTNER_ID is null then 1
                 else 0
               end CUST
             , (select CAT.C_TYPE_CATALOGUE
                  from ACJ_CATALOGUE_DOCUMENT CAT
                 where CAT.ACJ_CATALOGUE_DOCUMENT_ID = (select DOC.ACJ_CATALOGUE_DOCUMENT_ID
                                                          from ACT_DOCUMENT DOC
                                                         where DOC.ACT_DOCUMENT_ID = EXP.ACT_DOCUMENT_ID) )
                                                                                                       C_TYPE_CATALOGUE
             , (select nvl(PAR.PAR_BLOCKED_DOCUMENT, 0)
                  from ACT_PART_IMPUTATION PAR
                 where PAR.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID) PAR_BLOCKED_DOCUMENT
             , nvl(EXP.EXP_PAC_SUPPLIER_PARTNER_ID, EXP.EXP_PAC_CUSTOM_PARTNER_ID) PAC_THIRD_ID
             , (select ACS_SUB_SET_ID
                  from ACS_ACCOUNT
                 where ACS_ACCOUNT_ID = IMP.ACS_AUXILIARY_ACCOUNT_ID) ACS_SUB_SET_ID
          from ACT_EXPIRY EXP
             , ACT_FINANCIAL_IMPUTATION IMP
         where trunc(IMP.IMF_TRANSACTION_DATE) <= trunc(aCFA_DATE)
           and to_number(EXP.C_STATUS_EXPIRY) + 0 <> 9
           and IMP.ACT_PART_IMPUTATION_ID = EXP.ACT_PART_IMPUTATION_ID
           and EXP.EXP_CALC_NET = 1
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null;

      ----
      type FinImputationsCursorTyp is ref cursor;

      ------
      cursor FinImputationsOfDocumentCursor
      is
        select IMP.ACS_FINANCIAL_ACCOUNT_ID
             , IMP.IMF_AMOUNT_LC_D
             , IMP.IMF_AMOUNT_LC_C
             , IMP.IMF_AMOUNT_FC_D
             , IMP.IMF_AMOUNT_FC_C
             , IMP.ACS_FINANCIAL_CURRENCY_ID
             , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , SCA.C_TYPE_CUMUL
             , ETA.C_ETAT_JOURNAL
             , IMP.ACT_DOCUMENT_ID
             , IMP.PAC_PERSON_ID
             , IMP.ACT_FINANCIAL_IMPUTATION_ID
             , 0 DOC_RECORD_ID
          from ACT_ETAT_JOURNAL ETA
             , ACJ_SUB_SET_CAT SCA
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_DOCUMENT DOC;

      Expiries                 ExpiriesCursor%rowtype;
      FinImputationsCursor     FinImputationsCursorTyp;
      FinImputationsOfDocument FinImputationsOfDocumentCursor%rowtype;
      Proportion               number(15, 6);
      SignLast                 signtype;
      RestOfExpiryLC           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
      RestOfExpiryFC           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
      CashFlowImputationId     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;
      TransactionDate          ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type;
      CashFlowImpTyp           ACR_CASH_FLOW_IMPUTATION.C_CASH_FLOW_IMP_TYP%type;

      --------
      function TotalDocExpiries(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
        return ACT_EXPIRY.EXP_AMOUNT_LC%type
      is
        Amount ACT_EXPIRY.EXP_AMOUNT_LC%type;
      begin
        select nvl(sum(EXP_AMOUNT_LC), 0)
          into Amount
          from ACT_EXPIRY
         where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and EXP_CALC_NET = 1;

        return Amount;
      end TotalDocExpiries;

      --------
      function GetWeightingDate(
        aACR_CASH_FLOW_ANALYSIS_ID ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
      , aExpiries                  ExpiriesCursor%rowtype
      )
        return ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type
      is
        Factor    PAC_CUSTOM_PARTNER.CUS_PAYMENT_FACTOR%type    default 0;
        result    ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type;
        Weighting ACR_CF_DATE_WEIGHTING%rowtype;
      ----
      begin
        Weighting  := GetSubSetDateWeighting(aACR_CASH_FLOW_ANALYSIS_ID, aExpiries.ACS_AUXILIARY_ACCOUNT_ID);

        if Weighting.CFW_WEIGHTING = 1 then
          -- Nouveau calcul
          if Weighting.C_WEIGHTING_DATE_METHOD = '01' then
            -- Calcul du coefficient de paiement d'un partenaire
            if aExpiries.CUST = 1 then
              Factor  :=
                ACR_CASH_FLOW_MANAGEMENT.PartnerPaymentFactor(aExpiries.PAC_THIRD_ID
                                                            , 'C'
                                                            , Weighting.CFW_DAYS_NUMBER
                                                            , Weighting.CFW_INVOICE_AMOUNT
                                                             );

              if Weighting.CFW_CODE_UPDATE = 1 then
                update PAC_CUSTOM_PARTNER
                   set CUS_PAYMENT_FACTOR = Factor
                     , CUS_PAYMENT_FACTOR_DATE = trunc(sysdate)
                 where PAC_CUSTOM_PARTNER_ID = aExpiries.PAC_THIRD_ID;
              end if;
            else
              Factor  :=
                ACR_CASH_FLOW_MANAGEMENT.PartnerPaymentFactor(aExpiries.PAC_THIRD_ID
                                                            , 'S'
                                                            , Weighting.CFW_DAYS_NUMBER
                                                            , Weighting.CFW_INVOICE_AMOUNT
                                                             );

              if Weighting.CFW_CODE_UPDATE = 1 then
                update PAC_SUPPLIER_PARTNER
                   set CRE_PAYMENT_FACTOR = Factor
                     , CRE_PAYMENT_FACTOR_DATE = trunc(sysdate)
                 where PAC_SUPPLIER_PARTNER_ID = aExpiries.PAC_THIRD_ID;
              end if;
            end if;
          else
            Factor  := GetFactorPartner(aExpiries.PAC_THIRD_ID, aExpiries.CUST, Weighting.C_WEIGHTING_DATE_METHOD);
          end if;
        end if;

        if Factor <> 0 then
          if round( (aExpiries.EXP_ADAPTED - aExpiries.IMF_VALUE_DATE) * Factor) >=
                                                               to_number(to_date('31.12.2999', 'dd.mm.yyyy') - aExpiries.IMF_VALUE_DATE) then
            result  := to_date('31.12.2999', 'dd.mm.yyyy');
          else
            result  := aExpiries.IMF_VALUE_DATE + round( (aExpiries.EXP_ADAPTED - aExpiries.IMF_VALUE_DATE) * Factor);
          end if;
        else
          result  := aExpiries.EXP_ADAPTED;
        end if;

        return result;
      end GetWeightingDate;

      --------
      function GetCashFlowImpTyp(
        aTransactionDate ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type
      , aDateFrom        ACS_PERIOD.PER_START_DATE%type
      , aDateTo          ACS_PERIOD.PER_END_DATE%type
      , aExpiries        ExpiriesCursor%rowtype
      )
        return ACR_CASH_FLOW_IMPUTATION.C_CASH_FLOW_IMP_TYP%type
      is
        CashFlowImpTyp ACR_CASH_FLOW_IMPUTATION.C_CASH_FLOW_IMP_TYP%type;
        Blocked        ACT_PART_IMPUTATION.PAR_BLOCKED_DOCUMENT%type;
      begin
        Blocked  := aExpiries.PAR_BLOCKED_DOCUMENT;

        if     Blocked = 0
           and aExpiries.CUST = 0 then
          select min(CRE_BLOCKED)
            into Blocked
            from PAC_SUPPLIER_PARTNER
           where ACS_AUXILIARY_ACCOUNT_ID = aExpiries.ACS_AUXILIARY_ACCOUNT_ID;
        end if;

        if trunc(aTransactionDate) between trunc(aDateFrom) and trunc(aDateTo) then
          if Blocked = 1 then
            CashFlowImpTyp  := 'PLB';
          else
            CashFlowImpTyp  := 'PLA';
          end if;
        else
          if Blocked = 1 then
            CashFlowImpTyp  := 'PRB';
          else
            CashFlowImpTyp  := 'PLR';
          end if;
        end if;

        return CashFlowImpTyp;
      end GetCashFlowImpTyp;
    -----
    begin
      -- Le traitement s'appuie sur les postes ouverts : C_TYPE_CATALOGUE <> '8' (relances)
      -- La variable package 'BRO' est utilisée par les fonctions TotalPayment(...) et TotalPaymentAt(...)
      ACT_FUNCTIONS.SetBRO(1);

      open ExpiriesCursor(aCFA_DATE);

      fetch ExpiriesCursor
       into Expiries;

      while ExpiriesCursor%found loop
        RestOfExpiryLC  := Expiries.EXP_AMOUNT_LC - Expiries.DET_PAIED_LC;
        RestOfExpiryFC  := Expiries.EXP_AMOUNT_FC - Expiries.DET_PAIED_FC;

        if    (RestOfExpiryLC <> 0)
           or (RestOfExpiryFC <> 0) then
          if Expiries.C_TYPE_CATALOGUE in('2', '5', '6') then
            -- Facture, NC
            -- Date échéance + éventuelle pondération (selon facteur tiers sur les 360 derniers jours)
            TransactionDate  := GetWeightingDate(aACR_CASH_FLOW_ANALYSIS_ID, Expiries);
          else
            -- C_TYPE_CATALOGUE in ('3', '4') -> paiement manuel ou automatique --> non lettré
            -- Date échéance --> jamais pondérée, échu immédiatement
            TransactionDate  := Expiries.EXP_ADAPTED;
          end if;

          if     (    (aCFA_PLA_ALL_DATES = 1)
                  or (trunc(TransactionDate) between trunc(aDateFrom) and trunc(aDateTo) ) )
             and ACS_FUNCTION.GetPeriodID(trunc(TransactionDate), '2') is not null then
            CashFlowImpTyp  := GetCashFlowImpTyp(TransactionDate, aDateFrom, aDateTo, Expiries);

            begin
              Proportion  := abs(RestOfExpiryLC / TotalDocExpiries(Expiries.ACT_DOCUMENT_ID) );
            exception
              when zero_divide then
                Proportion  := 0;
            end;

            if Expiries.C_TYPE_CATALOGUE in('2', '5', '6') then
              -- Facture, NC
              -- Comptes financiers des contres écritures du document poste ouvert
              open FinImputationsCursor
               for
                 select IMP.ACS_FINANCIAL_ACCOUNT_ID
                      , IMP.IMF_AMOUNT_LC_D
                      , IMP.IMF_AMOUNT_LC_C
                      , IMP.IMF_AMOUNT_FC_D
                      , IMP.IMF_AMOUNT_FC_C
                      , IMP.ACS_FINANCIAL_CURRENCY_ID
                      , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                      , IMP.IMF_VALUE_DATE
                      , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                      , SCA.C_TYPE_CUMUL
                      , ETA.C_ETAT_JOURNAL
                      , IMP.ACT_DOCUMENT_ID
                      , IMP.PAC_PERSON_ID
                      , IMP.ACT_FINANCIAL_IMPUTATION_ID
                      , decode(DetailedAnalysis,
                               1, decode(ExistCpn,
                                         1, ACR_CASH_FLOW_MANAGEMENT.GetMgmImputationRecordId(IMP.ACT_FINANCIAL_IMPUTATION_ID),
                                         IMP.DOC_RECORD_ID),
                               null) DOC_RECORD_ID
                   from ACT_ETAT_JOURNAL ETA
                      , ACJ_SUB_SET_CAT SCA
                      , ACT_FINANCIAL_IMPUTATION IMP
                      , ACT_DOCUMENT DOC
                  where DOC.ACT_DOCUMENT_ID = Expiries.ACT_DOCUMENT_ID
                    and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                    and IMP.IMF_PRIMARY = 0
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                    and SCA.C_SUB_SET = 'ACC'
                    and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
                    and ETA.C_SUB_SET = 'ACC';
            else
              -- C_TYPE_CATALOGUE in ('3', '4') -> paiement manuel ou automatique --> non lettré
              -- Compte financier (compte collectif) du document poste ouvert
              open FinImputationsCursor
               for
                 select IMP.ACS_FINANCIAL_ACCOUNT_ID
                      , IMP.IMF_AMOUNT_LC_D
                      , IMP.IMF_AMOUNT_LC_C
                      , IMP.IMF_AMOUNT_FC_D
                      , IMP.IMF_AMOUNT_FC_C
                      , IMP.ACS_FINANCIAL_CURRENCY_ID
                      , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                      , IMP.IMF_VALUE_DATE
                      , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                      , SCA.C_TYPE_CUMUL
                      , ETA.C_ETAT_JOURNAL
                      , IMP.ACT_DOCUMENT_ID
                      , IMP.PAC_PERSON_ID
                      , IMP.ACT_FINANCIAL_IMPUTATION_ID
                      , decode(DetailedAnalysis,
                               1, decode(ExistCpn,
                                         1, ACR_CASH_FLOW_MANAGEMENT.GetMgmImputationRecordId(IMP.ACT_FINANCIAL_IMPUTATION_ID),
                                         IMP.DOC_RECORD_ID),
                               null) DOC_RECORD_ID
                   from ACT_ETAT_JOURNAL ETA
                      , ACJ_SUB_SET_CAT SCA
                      , ACS_FINANCIAL_ACCOUNT ACC
                      , ACT_FINANCIAL_IMPUTATION IMP
                      , ACT_DOCUMENT DOC
                  where DOC.ACT_DOCUMENT_ID = Expiries.ACT_DOCUMENT_ID
                    and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                    and IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_FINANCIAL_ACCOUNT_ID
                    and ACC.FIN_COLLECTIVE = 1
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                    and SCA.C_SUB_SET = 'ACC'
                    and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
                    and ETA.C_SUB_SET = 'ACC';
            end if;

            fetch FinImputationsCursor
             into FinImputationsOfDocument;

            TotAmountLC     := 0;
            TotAmountFC     := 0;

            while FinImputationsCursor%found loop
              -- Montants proportionnels (montant d'origine - pmt/lettrage partiel)
              ACT_DOC_TRANSACTION.ProportionalAmounts(FinImputationsOfDocument.IMF_AMOUNT_LC_D
                                                    , FinImputationsOfDocument.IMF_AMOUNT_LC_C
                                                    , FinImputationsOfDocument.IMF_AMOUNT_FC_D
                                                    , FinImputationsOfDocument.IMF_AMOUNT_FC_C
                                                    , FinImputationsOfDocument.ACS_FINANCIAL_CURRENCY_ID
                                                    , FinImputationsOfDocument.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                    , FinImputationsOfDocument.IMF_VALUE_DATE
                                                    , Proportion
                                                    , AmountLC_D
                                                    , AmountLC_C
                                                    , AmountFC_D
                                                    , AmountFC_C
                                                    , AmountEUR_D
                                                    , AmountEUR_C
                                                    , ExchangeRate
                                                    , BasePrice
                                                     );
              TotAmountLC           := TotAmountLC + AmountLC_C - AmountLC_D;
              TotAmountFC           := TotAmountFC + AmountFC_C - AmountFC_D;
              SignLast              := sign(AmountLC_C - AmountLC_D);

              if SignLast = 0 then
                SignLast  := 1;
              end if;

              CashFlowImputationId  :=
                AddAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                                     , FinImputationsOfDocument.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                                     , FinImputationsOfDocument.ACS_DIVISION_ACCOUNT_ID   --Compte division
                                     , FinImputationsOfDocument.C_TYPE_CUMUL   --Type de cumul
                                     , FinImputationsOfDocument.C_ETAT_JOURNAL   --Etat journal
                                     , CashFlowImpTyp   --Type mouvement trésorerie
                                     , AmountLC_D   --Montant LCD
                                     , AmountLC_C   --Montant LCC
                                     , AmountFC_D   --Montant FCD
                                     , AmountFC_C   --Montant FCC
                                     , FinImputationsOfDocument.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                                     , FinImputationsOfDocument.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                                     , TransactionDate   --Date mouvement
                                     , Expiries.ACS_SUB_SET_ID   --Sous-ensemble
                                     , null   --Gabarit document structuré
                                     , FinImputationsOfDocument.ACT_DOCUMENT_ID   --Document comptable
                                     , null   --Document logistique
                                     , FinImputationsOfDocument.PAC_PERSON_ID   --Partenaire
                                     , FinImputationsOfDocument.DOC_RECORD_ID
                                     , null   --Mandat document logistique
                                      );

              fetch FinImputationsCursor
               into FinImputationsOfDocument;
            end loop;

            close FinImputationsCursor;

            -- Ajout de l'éventuelle différence sur la dernière imputation générée
            if    (TotAmountLC <> RestOfExpiryLC)
               or (TotAmountFC <> RestOfExpiryFC) then
              -- Mise à jour imputations financières
              update ACR_CASH_FLOW_IMPUTATION_DET
                 set CFI_AMOUNT_LC_D = CFI_AMOUNT_LC_D + decode(SignLast, -1, TotAmountLC - RestOfExpiryLC, 0)
                   , CFI_AMOUNT_LC_C = CFI_AMOUNT_LC_C - decode(SignLast, 1, TotAmountLC - RestOfExpiryLC, 0)
                   , CFI_AMOUNT_FC_D = CFI_AMOUNT_FC_D + decode(SignLast, -1, TotAmountFC - RestOfExpiryFC, 0)
                   , CFI_AMOUNT_FC_C = CFI_AMOUNT_FC_C - decode(SignLast, 1, TotAmountFC - RestOfExpiryFC, 0)
               where ACR_CASH_FLOW_IMPUTATION_ID = CashFlowImputationId;
            end if;
          end if;
        end if;

        fetch ExpiriesCursor
         into Expiries;
      end loop;

      close ExpiriesCursor;
    end InsertExpiriesImputation;

    ---------
    procedure InsertPaiedImputation(
      aACR_CASH_FLOW_ANALYSIS_ID ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
    , aDateFrom                  ACS_PERIOD.PER_START_DATE%type
    , aDateTo                    ACS_PERIOD.PER_END_DATE%type
    )
    is
      -- Récupère les détails paiements de tous types des documents
      -- 3,4,9 (Paiement, paiement automatique, lettrage) pour les imputations de
      -- type "Montant sans spécifications (C_GENRE_TRANSACTION = '1' )" et "Diff de change (C_GENRE_TRANSACTION = '4')"
      -- Ces dernières sont pris pour balancer les diff. de change prises en compte dans le curseur des imputation sur
      -- comptes non collectif et non liquidité crImputationsNotCollectiv
      cursor crAllTypePaymentDetails(aDateFrom ACS_PERIOD.PER_START_DATE%type, aDateTo ACS_PERIOD.PER_END_DATE%type)
      is
        select   IMF.ACT_FINANCIAL_IMPUTATION_ID
               , IMF.IMF_AMOUNT_LC_D
               , IMF.IMF_AMOUNT_LC_C
               , IMF.IMF_AMOUNT_FC_D
               , IMF.IMF_AMOUNT_FC_C
               , IMF.ACS_FINANCIAL_CURRENCY_ID
               , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
               , IMF.ACS_FINANCIAL_ACCOUNT_ID
               , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
               , IMF.ACT_DET_PAYMENT_ID
               , IMF.IMF_VALUE_DATE
               , IMF.C_GENRE_TRANSACTION
               , ACS_FUNCTION.GetSubSetIdByAccount(IMF.ACS_AUXILIARY_ACCOUNT_ID) ACS_SUB_SET_ID
               , IMF.ACT_DOCUMENT_ID
               , IMF.PAC_PERSON_ID
               , SCA.C_TYPE_CUMUL
               , ETA.C_ETAT_JOURNAL
               , CAO.C_TYPE_CATALOGUE
               , DOO.ACT_DOCUMENT_ID ORIGIN_DOC_ID
               , decode(DetailedAnalysis,
                        1, decode(ExistCpn,
                                  1, ACR_CASH_FLOW_MANAGEMENT.GetMgmImputationRecordId(IMF.ACT_FINANCIAL_IMPUTATION_ID),
                                  IMF.DOC_RECORD_ID),
                        null) DOC_RECORD_ID
            from ACJ_CATALOGUE_DOCUMENT CAO
               , ACT_DOCUMENT DOO
               , ACT_EXPIRY EXP
               , ACT_DET_PAYMENT DET
               , ACT_ETAT_JOURNAL ETA
               , ACJ_SUB_SET_CAT SCA
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACT_DOCUMENT DOC
               , ACS_FINANCIAL_ACCOUNT FIN
               , ACT_FINANCIAL_IMPUTATION IMF
           where trunc(IMF.IMF_VALUE_DATE) between trunc(aDateFrom) and trunc(aDateTo)
             and IMF.C_GENRE_TRANSACTION in('1', '4')
             and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.C_TYPE_CATALOGUE in('3', '4', '9')
             and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
             and FIN.FIN_COLLECTIVE = 1
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
             and SCA.C_SUB_SET = 'ACC'
             and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
             and ETA.C_SUB_SET = 'ACC'
             and IMF.ACT_DET_PAYMENT_ID = DET.ACT_DET_PAYMENT_ID
             and DET.ACT_EXPIRY_ID = EXP.ACT_EXPIRY_ID
             and EXP.ACT_DOCUMENT_ID = DOO.ACT_DOCUMENT_ID
             and DOO.ACJ_CATALOGUE_DOCUMENT_ID = CAO.ACJ_CATALOGUE_DOCUMENT_ID
             and CAO.C_TYPE_CATALOGUE in('2', '3', '4', '5', '6')
             and decode( (select FIN.FIN_LIQUIDITY
                            from ACS_ACCOUNT ACC
                               , ACS_FINANCIAL_ACCOUNT FIN
                               , ACT_FINANCIAL_IMPUTATION IMF
                           where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                             and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                             and IMF.IMF_PRIMARY = 1
                             and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID)
                      , null, 1
                      , (select FIN.FIN_LIQUIDITY
                           from ACS_ACCOUNT ACC
                              , ACS_FINANCIAL_ACCOUNT FIN
                              , ACT_FINANCIAL_IMPUTATION IMF
                          where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                            and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                            and IMF.IMF_PRIMARY = 1
                            and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID)
                       ) = 1
        order by IMF.IMF_VALUE_DATE desc;

      -- Curseur des imputations créant des non lettrés (si le non lettré naît d'un document d'imputation primaire non liquidité, cette imputation primaire
      -- sera récupéré par le 3ème curseur, donc opération blanche d'un point de vue cash-flow
      cursor crImputationsPO(aDateFrom ACS_PERIOD.PER_START_DATE%type, aDateTo ACS_PERIOD.PER_END_DATE%type)
      is
        select   IMF.ACT_FINANCIAL_IMPUTATION_ID
               , IMF.IMF_AMOUNT_LC_D
               , IMF.IMF_AMOUNT_LC_C
               , IMF.IMF_AMOUNT_FC_D
               , IMF.IMF_AMOUNT_FC_C
               , IMF.ACS_FINANCIAL_CURRENCY_ID
               , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
               , IMF.ACS_FINANCIAL_ACCOUNT_ID
               , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
               , IMF.ACT_DET_PAYMENT_ID
               , IMF.IMF_VALUE_DATE
               , IMF.C_GENRE_TRANSACTION
               , ACS_FUNCTION.GetSubSetIdByAccount(IMF.ACS_AUXILIARY_ACCOUNT_ID) ACS_SUB_SET_ID
               , IMF.ACT_DOCUMENT_ID
               , IMF.PAC_PERSON_ID
               , SCA.C_TYPE_CUMUL
               , ETA.C_ETAT_JOURNAL
               , decode(DetailedAnalysis,
                        1, decode(ExistCpn,
                                  1, ACR_CASH_FLOW_MANAGEMENT.GetMgmImputationRecordId(IMF.ACT_FINANCIAL_IMPUTATION_ID),
                                  IMF.DOC_RECORD_ID),
                        null) DOC_RECORD_ID
            from ACJ_CATALOGUE_DOCUMENT CAT
               , ACT_ETAT_JOURNAL ETA
               , ACJ_SUB_SET_CAT SCA
               , ACT_DOCUMENT DOC
               , ACS_FINANCIAL_ACCOUNT FIN
               , ACT_FINANCIAL_IMPUTATION IMF
           where trunc(IMF.IMF_VALUE_DATE) between trunc(aDateFrom) and trunc(aDateTo)
             and IMF.C_GENRE_TRANSACTION = '1'
             and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.C_TYPE_CATALOGUE in('3', '4', '9')
             and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
             and FIN.FIN_COLLECTIVE = 1
             and IMF.ACT_DET_PAYMENT_ID is null
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
             and SCA.C_SUB_SET = 'ACC'
             and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
             and ETA.C_SUB_SET = 'ACC'
             and decode( (select FIN.FIN_LIQUIDITY
                            from ACS_ACCOUNT ACC
                               , ACS_FINANCIAL_ACCOUNT FIN
                               , ACT_FINANCIAL_IMPUTATION IMF
                           where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                             and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                             and IMF.IMF_PRIMARY = 1
                             and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID)
                      , null, 1
                      , (select FIN.FIN_LIQUIDITY
                           from ACS_ACCOUNT ACC
                              , ACS_FINANCIAL_ACCOUNT FIN
                              , ACT_FINANCIAL_IMPUTATION IMF
                          where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                            and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                            and IMF.IMF_PRIMARY = 1
                            and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID)
                       ) = 1
        order by IMF.IMF_VALUE_DATE desc;

      -- Curseur des imputations sur comptes non collectifs et non liquidité
      cursor crImputationsNotCollectiv(
        aDateFrom ACS_PERIOD.PER_START_DATE%type
      , aDateTo   ACS_PERIOD.PER_END_DATE%type
      )
      is
        select   IMF.ACT_FINANCIAL_IMPUTATION_ID
               , IMF.IMF_AMOUNT_LC_D
               , IMF.IMF_AMOUNT_LC_C
               , IMF.IMF_AMOUNT_FC_D
               , IMF.IMF_AMOUNT_FC_C
               , IMF.ACS_FINANCIAL_CURRENCY_ID
               , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
               , IMF.ACS_FINANCIAL_ACCOUNT_ID
               , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
               , IMF.ACT_DET_PAYMENT_ID
               , IMF.IMF_VALUE_DATE
               , IMF.C_GENRE_TRANSACTION
               , ACS_FUNCTION.GetSubSetIdByAccount(IMF.ACS_AUXILIARY_ACCOUNT_ID) ACS_SUB_SET_ID
               , IMF.ACT_DOCUMENT_ID
               , IMF.PAC_PERSON_ID
               , SCA.C_TYPE_CUMUL
               , ETA.C_ETAT_JOURNAL
               , decode(DetailedAnalysis,
                        1, decode(ExistCpn,
                                  1, ACR_CASH_FLOW_MANAGEMENT.GetMgmImputationRecordId(IMF.ACT_FINANCIAL_IMPUTATION_ID),
                                  IMF.DOC_RECORD_ID),
                        null) DOC_RECORD_ID
            from ACJ_CATALOGUE_DOCUMENT CAT
               , ACT_ETAT_JOURNAL ETA
               , ACJ_SUB_SET_CAT SCA
               , ACT_DOCUMENT DOC
               , ACS_FINANCIAL_ACCOUNT FIN
               , ACT_FINANCIAL_IMPUTATION IMF
           where trunc(IMF.IMF_VALUE_DATE) between trunc(aDateFrom) and trunc(aDateTo)
             and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.C_TYPE_CATALOGUE in('3', '4', '9')
             and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
             and FIN.FIN_COLLECTIVE <> 1
             and FIN.FIN_LIQUIDITY <> 1
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
             and SCA.C_SUB_SET = 'ACC'
             and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
             and ETA.C_SUB_SET = 'ACC'
             and decode( (select FIN.FIN_LIQUIDITY
                            from ACS_ACCOUNT ACC
                               , ACS_FINANCIAL_ACCOUNT FIN
                               , ACT_FINANCIAL_IMPUTATION IMF
                           where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                             and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                             and IMF.IMF_PRIMARY = 1
                             and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID)
                      , null, 1
                      , (select FIN.FIN_LIQUIDITY
                           from ACS_ACCOUNT ACC
                              , ACS_FINANCIAL_ACCOUNT FIN
                              , ACT_FINANCIAL_IMPUTATION IMF
                          where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                            and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                            and IMF.IMF_PRIMARY = 1
                            and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID)
                       ) = 1
        order by IMF.IMF_VALUE_DATE desc;

      --Recherche des données par document. Utilisé dans ce contexte pour les document
      --d'origine des imputations traités
      cursor crDocImputationByDocument(aActDocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
      is
        select   IMF.ACT_FINANCIAL_IMPUTATION_ID
               , IMF.ACS_FINANCIAL_ACCOUNT_ID
               , IMF.IMF_AMOUNT_LC_D
               , IMF.IMF_AMOUNT_LC_C
               , IMF.IMF_AMOUNT_FC_D
               , IMF.IMF_AMOUNT_FC_C
               , IMF.ACS_FINANCIAL_CURRENCY_ID
               , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
               , IMF.IMF_VALUE_DATE
               , ACS_FUNCTION.GetSubSetIdByAccount(IMF.ACS_AUXILIARY_ACCOUNT_ID) ACS_SUB_SET_ID
               , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
               , SCA.C_TYPE_CUMUL
               , ETA.C_ETAT_JOURNAL
               , IMF.ACT_DOCUMENT_ID
               , IMF.PAC_PERSON_ID
               , decode(DetailedAnalysis,
                        1, decode(ExistCpn,
                                  1, ACR_CASH_FLOW_MANAGEMENT.GetMgmImputationRecordId(IMF.ACT_FINANCIAL_IMPUTATION_ID),
                                  IMF.DOC_RECORD_ID),
                        null) DOC_RECORD_ID
            from ACT_ETAT_JOURNAL ETA
               , ACJ_SUB_SET_CAT SCA
               , V_ACT_FIN_IMP_CASH_FLOW IMF
               , ACT_DOCUMENT DOC
           where IMF.ACT_DOCUMENT_ID = aActDocumentId
             and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
             and IMF.IMF_PRIMARY = 0
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
             and SCA.C_SUB_SET = 'ACC'
             and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
             and ETA.C_SUB_SET = 'ACC'
        order by IMF.ACT_FINANCIAL_IMPUTATION_ID;

      tplAllTypePaymentDetails      crAllTypePaymentDetails%rowtype;
      tplImputationsPO              crImputationsPO%rowtype;
      tplImputationsNotCollectiv    crImputationsNotCollectiv%rowtype;
      tplDocImputationByDocument    crDocImputationByDocument%rowtype;
      vCashFlowImputationId         ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;
      vOriginDocImputationSumLC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;   /* Somme des imputations du document d'origine de l'imputation courante*/
      vOriginDocImputationSumFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;   /* Somme des imputations du document d'origine de l'imputation courante*/
      vOriginProportionalAmountLC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;   /* Montant proportionnel cadré sur imputation origine MB */
      vOriginProportionalAmountLC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;   /* Montant proportionnel cadré sur imputation origine MB */
      vOriginProportionalAmountFC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;   /* Montant proportionnel cadré sur imputation origine  ME */
      vOriginProportionalAmountFC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;   /* Montant proportionnel cadré sur imputation origine  ME */
      vOriginDocLastImputationsId   ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;   /* Id dernière imputation du document origine de l'imputation courante*/
      vOriginImpPropAmountLC        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;   /* cumul des montants proportionnels des imputations du document origine */
      vOriginImpPropAmountFC        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;   /* cumul des montants proportionnels des imputations du document origine */
      vOriginDocImputProport_LC     number(15, 6);   /* Proportion (montant imputation courante / montant total document origine)*/
      vOriginDocImputProport_FC     number(15, 6);   /* Proportion (montant imputation courante / montant total document origine)*/

      function Get_DocImputationSum(aActDocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type, aInLocalCurrency number)
        return ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
      is
        vAmount ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
      begin
        select case
                 when aInLocalCurrency = 0 then nvl(sum(IMP.IMF_AMOUNT_FC_D - IMP.IMF_AMOUNT_FC_C), 0)
                 when aInLocalCurrency = 1 then nvl(sum(IMP.IMF_AMOUNT_LC_D - IMP.IMF_AMOUNT_LC_C), 0)
                 else 0
               end case
          into vAmount
          from ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = aActDocumentId
           and IMP.IMF_PRIMARY = 0;

        return vAmount;
      end Get_DocImputationSum;

      function GetOriginDocLastImputationsId(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
        return ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
      is
        vOriginLastImpId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
      begin
        select nvl(max(ACT_FINANCIAL_IMPUTATION_ID), 0)
          into vOriginLastImpId
          from ACT_ETAT_JOURNAL ETA
             , ACJ_SUB_SET_CAT SCA
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_DOCUMENT DOC
         where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
           and IMP.IMF_PRIMARY = 0
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
           and SCA.C_SUB_SET = 'ACC'
           and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
           and ETA.C_SUB_SET = 'ACC';

        return vOriginLastImpId;
      end GetOriginDocLastImputationsId;
    begin
      open crAllTypePaymentDetails(aDateFrom, aDateTo);

      fetch crAllTypePaymentDetails
       into tplAllTypePaymentDetails;

      while crAllTypePaymentDetails%found loop
        -- Paiement Manuel / Automatique
        if tplAllTypePaymentDetails.C_TYPE_CATALOGUE in('3', '4') then
          vCashFlowImputationId  :=
            AddAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                                 , tplAllTypePaymentDetails.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                                 , tplAllTypePaymentDetails.ACS_DIVISION_ACCOUNT_ID   --Compte division
                                 , tplAllTypePaymentDetails.C_TYPE_CUMUL   --Type de cumul
                                 , tplAllTypePaymentDetails.C_ETAT_JOURNAL   --Etat journal
                                 , 'EFF'   --Type mouvement trésorerie
                                 , tplAllTypePaymentDetails.IMF_AMOUNT_LC_D   --Montant LCD
                                 , tplAllTypePaymentDetails.IMF_AMOUNT_LC_C   --Montant LCC
                                 , tplAllTypePaymentDetails.IMF_AMOUNT_FC_D   --Montant FCD
                                 , tplAllTypePaymentDetails.IMF_AMOUNT_FC_C   --Montant FCC
                                 , tplAllTypePaymentDetails.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                                 , tplAllTypePaymentDetails.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                                 , tplAllTypePaymentDetails.IMF_VALUE_DATE   --Date mouvement
                                 , tplAllTypePaymentDetails.ACS_SUB_SET_ID   --Sous-ensemble
                                 , null   --Gabarit document structuré
                                 , tplAllTypePaymentDetails.ACT_DOCUMENT_ID   --Document comptable
                                 , null   --Document logistique
                                 , tplAllTypePaymentDetails.PAC_PERSON_ID   --Partenaire
                                 , tplAllTypePaymentDetails.DOC_RECORD_ID  --Dossier
                                 , null   --Mandat document logistique
                                  );
        -- Facture, crédit, note de crédit
        elsif tplAllTypePaymentDetails.C_TYPE_CATALOGUE in('2', '5', '6') then
          --Recadrés proportionnellement dans les comptes des documents d'origines
          --Initialisation du montant total du document origine
          vOriginDocImputationSumLC    := Get_DocImputationSum(tplAllTypePaymentDetails.ORIGIN_DOC_ID, 1);
          vOriginDocImputationSumFC    := Get_DocImputationSum(tplAllTypePaymentDetails.ORIGIN_DOC_ID, 0);
          --Initialisation proportion de l'imputation traitée
          vOriginDocImputProport_LC    := 0;
          vOriginDocImputProport_FC    := 0;

          if vOriginDocImputationSumLC <> 0 then
            vOriginDocImputProport_LC  :=
              (tplAllTypePaymentDetails.IMF_AMOUNT_LC_D - tplAllTypePaymentDetails.IMF_AMOUNT_LC_C
              ) /
              vOriginDocImputationSumLC;
          end if;

          if vOriginDocImputationSumFC <> 0 then
            vOriginDocImputProport_FC  :=
              (tplAllTypePaymentDetails.IMF_AMOUNT_FC_D - tplAllTypePaymentDetails.IMF_AMOUNT_FC_C
              ) /
              vOriginDocImputationSumFC;
          end if;

          --Initialisation des variables de cumul
          vOriginImpPropAmountLC       := 0;
          vOriginImpPropAmountFC       := 0;
          /*Recherche de la dernière imputation du document d'origine */
          vOriginDocLastImputationsId  := GetOriginDocLastImputationsId(tplAllTypePaymentDetails.ORIGIN_DOC_ID);

          open crDocImputationByDocument(tplAllTypePaymentDetails.ORIGIN_DOC_ID);

          fetch crDocImputationByDocument
           into tplDocImputationByDocument;

          while crDocImputationByDocument%found loop
            vOriginProportionalAmountLC_D  := 0;
            vOriginProportionalAmountLC_C  := 0;
            vOriginProportionalAmountFC_D  := 0;
            vOriginProportionalAmountFC_C  := 0;

            --Calcul des proportions pour les imputations...Dernière imputation -> Calcul par différence
            if tplDocImputationByDocument.ACT_FINANCIAL_IMPUTATION_ID <> vOriginDocLastImputationsId then
              ACT_DOC_TRANSACTION.ProportionalAmounts(tplDocImputationByDocument.IMF_AMOUNT_LC_D
                                                    , tplDocImputationByDocument.IMF_AMOUNT_LC_C
                                                    , tplDocImputationByDocument.IMF_AMOUNT_FC_D
                                                    , tplDocImputationByDocument.IMF_AMOUNT_FC_C
                                                    , tplDocImputationByDocument.ACS_FINANCIAL_CURRENCY_ID
                                                    , tplDocImputationByDocument.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                    , tplDocImputationByDocument.IMF_VALUE_DATE
                                                    , vOriginDocImputProport_LC
                                                    , AmountLC_D
                                                    , AmountLC_C
                                                    , AmountFC_D
                                                    , AmountFC_C
                                                    , AmountEUR_D
                                                    , AmountEUR_C
                                                    , ExchangeRate
                                                    , BasePrice
                                                     );
              vOriginImpPropAmountLC         := vOriginImpPropAmountLC + AmountLC_D - AmountLC_C;
              vOriginProportionalAmountLC_D  := AmountLC_D;
              vOriginProportionalAmountLC_C  := AmountLC_C;
              ACT_DOC_TRANSACTION.ProportionalAmounts(tplDocImputationByDocument.IMF_AMOUNT_LC_D
                                                    , tplDocImputationByDocument.IMF_AMOUNT_LC_C
                                                    , tplDocImputationByDocument.IMF_AMOUNT_FC_D
                                                    , tplDocImputationByDocument.IMF_AMOUNT_FC_C
                                                    , tplDocImputationByDocument.ACS_FINANCIAL_CURRENCY_ID
                                                    , tplDocImputationByDocument.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                    , tplDocImputationByDocument.IMF_VALUE_DATE
                                                    , vOriginDocImputProport_FC
                                                    , AmountLC_D
                                                    , AmountLC_C
                                                    , AmountFC_D
                                                    , AmountFC_C
                                                    , AmountEUR_D
                                                    , AmountEUR_C
                                                    , ExchangeRate
                                                    , BasePrice
                                                     );
              vOriginImpPropAmountFC         := vOriginImpPropAmountFC + AmountFC_D - AmountFC_C;
              vOriginProportionalAmountFC_D  := AmountFC_D;
              vOriginProportionalAmountFC_C  := AmountFC_C;
            else
              /* Dernière position origine => Calcul par différence */
              if (tplAllTypePaymentDetails.IMF_AMOUNT_LC_D - tplAllTypePaymentDetails.IMF_AMOUNT_LC_C) -
                 vOriginImpPropAmountLC > 0 then
                vOriginProportionalAmountLC_D  :=
                  (tplAllTypePaymentDetails.IMF_AMOUNT_LC_D - tplAllTypePaymentDetails.IMF_AMOUNT_LC_C
                  ) -
                  vOriginImpPropAmountLC;
              else
                vOriginProportionalAmountLC_C  :=
                  abs(tplAllTypePaymentDetails.IMF_AMOUNT_LC_D -
                      tplAllTypePaymentDetails.IMF_AMOUNT_LC_C -
                      vOriginImpPropAmountLC
                     );
              end if;

              if (tplAllTypePaymentDetails.IMF_AMOUNT_FC_D - tplAllTypePaymentDetails.IMF_AMOUNT_FC_C) -
                 vOriginImpPropAmountFC > 0 then
                vOriginProportionalAmountFC_D  :=
                  (tplAllTypePaymentDetails.IMF_AMOUNT_FC_D - tplAllTypePaymentDetails.IMF_AMOUNT_FC_C
                  ) -
                  vOriginImpPropAmountFC;
              else
                vOriginProportionalAmountFC_C  :=
                  abs(tplAllTypePaymentDetails.IMF_AMOUNT_FC_D -
                      tplAllTypePaymentDetails.IMF_AMOUNT_FC_C -
                      vOriginImpPropAmountFC
                     );
              end if;
            end if;

            vCashFlowImputationId          :=
              AddAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                                   , tplDocImputationByDocument.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                                   , tplDocImputationByDocument.ACS_DIVISION_ACCOUNT_ID   --Compte division
                                   , tplAllTypePaymentDetails.C_TYPE_CUMUL   --Type de cumul
                                   , tplAllTypePaymentDetails.C_ETAT_JOURNAL   --Etat journal
                                   , 'EFF'   --Type mouvement trésorerie
                                   , vOriginProportionalAmountLC_D   --Montant LCD
                                   , vOriginProportionalAmountLC_C   --Montant LCC
                                   , vOriginProportionalAmountFC_D   --Montant FCD
                                   , vOriginProportionalAmountFC_C   --Montant FCC
                                   , tplAllTypePaymentDetails.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                                   , tplAllTypePaymentDetails.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                                   , tplAllTypePaymentDetails.IMF_VALUE_DATE   --Date mouvement
                                   , tplAllTypePaymentDetails.ACS_SUB_SET_ID   --Sous-ensemble
                                   , null   --Gabarit document structuré
                                   , tplAllTypePaymentDetails.ACT_DOCUMENT_ID   --Document comptable
                                   , null   --Document logistique
                                   , tplAllTypePaymentDetails.PAC_PERSON_ID   --Partenaire
                                   , tplDocImputationByDocument.DOC_RECORD_ID  --Dossier
                                   , null   --Mandat document logistique
                                    );

            fetch crDocImputationByDocument
             into tplDocImputationByDocument;
          end loop;

          close crDocImputationByDocument;
        end if;

        fetch crAllTypePaymentDetails
         into tplAllTypePaymentDetails;
      end loop;

      close crAllTypePaymentDetails;

      -- Traitement des imputations créant des PO...
      -- Les mouvements sont repris tel quel, imputés sur les comptes et à la date de
      -- l'imputation
      open crImputationsPO(aDateFrom, aDateTo);

      fetch crImputationsPO
       into tplImputationsPO;

      while crImputationsPO%found loop
        vCashFlowImputationId  :=
          AddAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                               , tplImputationsPO.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                               , tplImputationsPO.ACS_DIVISION_ACCOUNT_ID   --Compte division
                               , tplImputationsPO.C_TYPE_CUMUL   --Type de cumul
                               , tplImputationsPO.C_ETAT_JOURNAL   --Etat journal
                               , 'EFF'   --Type mouvement trésorerie
                               , tplImputationsPO.IMF_AMOUNT_LC_D   --Montant LCD
                               , tplImputationsPO.IMF_AMOUNT_LC_C   --Montant LCC
                               , tplImputationsPO.IMF_AMOUNT_FC_D   --Montant FCD
                               , tplImputationsPO.IMF_AMOUNT_FC_C   --Montant FCC
                               , tplImputationsPO.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                               , tplImputationsPO.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                               , tplImputationsPO.IMF_VALUE_DATE   --Date mouvement
                               , tplImputationsPO.ACS_SUB_SET_ID   --Sous-ensemble
                               , null   --Gabarit document structuré
                               , tplImputationsPO.ACT_DOCUMENT_ID   --Document comptable
                               , null   --Document logistique
                               , tplImputationsPO.PAC_PERSON_ID   --Partenaire
                               , tplImputationsPO.DOC_RECORD_ID   --Dossier
                               , null   --Mandat document logistique
                                );

        fetch crImputationsPO
         into tplImputationsPO;
      end loop;

      close crImputationsPO;

      -- Traitement des imputations créant des PO...
      -- Les mouvements sont repris tel quel, imputé sur les comptes et à la date de
      -- l'imputation
      open crImputationsNotCollectiv(aDateFrom, aDateTo);

      fetch crImputationsNotCollectiv
       into tplImputationsNotCollectiv;

      while crImputationsNotCollectiv%found loop
        vCashFlowImputationId  :=
          AddAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                               , tplImputationsNotCollectiv.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                               , tplImputationsNotCollectiv.ACS_DIVISION_ACCOUNT_ID   --Compte division
                               , tplImputationsNotCollectiv.C_TYPE_CUMUL   --Type de cumul
                               , tplImputationsNotCollectiv.C_ETAT_JOURNAL   --Etat journal
                               , 'EFF'   --Type mouvement trésorerie
                               , tplImputationsNotCollectiv.IMF_AMOUNT_LC_D   --Montant LCD
                               , tplImputationsNotCollectiv.IMF_AMOUNT_LC_C   --Montant LCC
                               , tplImputationsNotCollectiv.IMF_AMOUNT_FC_D   --Montant FCD
                               , tplImputationsNotCollectiv.IMF_AMOUNT_FC_C   --Montant FCC
                               , tplImputationsNotCollectiv.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                               , tplImputationsNotCollectiv.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                               , tplImputationsNotCollectiv.IMF_VALUE_DATE   --Date mouvement
                               , tplImputationsNotCollectiv.ACS_SUB_SET_ID   --Sous-ensemble
                               , null   --Gabarit document structuré
                               , tplImputationsNotCollectiv.ACT_DOCUMENT_ID   --Document comptable
                               , null   --Document logistique
                               , tplImputationsNotCollectiv.PAC_PERSON_ID   --Partenaire
                               , tplImputationsNotCollectiv.DOC_RECORD_ID  --Dossier
                               , null   --Mandat document logistique
                                );

        fetch crImputationsNotCollectiv
         into tplImputationsNotCollectiv;
      end loop;

      close crImputationsNotCollectiv;
    end InsertPaiedImputation;

    ---------
    procedure InsertLiqAccountImputations(
      aACR_CASH_FLOW_ANALYSIS_ID ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
    , aACS_PERIOD_FROM_ID        ACR_CASH_FLOW_ANALYSIS.ACS_PERIOD_FROM_ID%type
    , aDateFrom                  ACS_PERIOD.PER_START_DATE%type
    , aDateTo                    ACS_PERIOD.PER_END_DATE%type
    )
    is
      ------
      cursor LiqAccountImputationsCursor(
        aDateFrom ACS_PERIOD.PER_START_DATE%type
      , aDateTo   ACS_PERIOD.PER_END_DATE%type
      )
      is
        select IMP.ACS_FINANCIAL_ACCOUNT_ID
             , IMP.IMF_AMOUNT_LC_D
             , IMP.IMF_AMOUNT_LC_C
             , IMP.IMF_AMOUNT_FC_D
             , IMP.IMF_AMOUNT_FC_C
             , IMP.ACS_FINANCIAL_CURRENCY_ID
             , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
             , IMP.IMF_VALUE_DATE
             , IMP.ACS_PERIOD_ID
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , SCA.C_TYPE_CUMUL
             , ETA.C_ETAT_JOURNAL
             , IMP.ACT_DOCUMENT_ID
             , IMP.PAC_PERSON_ID
             , IMP.ACT_FINANCIAL_IMPUTATION_ID
             , decode(DetailedAnalysis,
                      1, decode(ExistCpn,
                                1, ACR_CASH_FLOW_MANAGEMENT.GetMgmImputationRecordId(IMP.ACT_FINANCIAL_IMPUTATION_ID),
                                IMP.DOC_RECORD_ID),
                      null) DOC_RECORD_ID
          from ACT_ETAT_JOURNAL ETA
             , ACJ_SUB_SET_CAT SCA
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
         where trunc(IMF_VALUE_DATE) between trunc(aDateFrom) and trunc(aDateTo)
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.FIN_LIQUIDITY = 1
           and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '7'   -- Report
           and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
           and SCA.C_SUB_SET = 'ACC'
           and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
           and ETA.C_SUB_SET = 'ACC';

      ------
      cursor LiqAccountReportAmountsCursor(
        aACS_FINANCIAL_YEAR_ID ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
      , aPER_NO_PERIOD         ACS_PERIOD.PER_NO_PERIOD%type
      )
      is
        select   TOT.ACS_FINANCIAL_ACCOUNT_ID
               , TOT.ACS_DIVISION_ACCOUNT_ID
               , TOT.ACS_FINANCIAL_CURRENCY_ID
               , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
               , TOT.C_TYPE_CUMUL
               , sum(nvl(TOT_DEBIT_LC, 0) - nvl(TOT_CREDIT_LC, 0) ) TOT_DEBIT_LC
               , sum(nvl(TOT_DEBIT_FC, 0) - nvl(TOT_CREDIT_FC, 0) ) TOT_DEBIT_FC
               , sum(nvl(TOT_DEBIT_EUR, 0) - nvl(TOT_CREDIT_EUR, 0) ) TOT_DEBIT_EUR
            from ACS_PERIOD PER
               , ACT_TOTAL_BY_PERIOD TOT
               , ACS_FINANCIAL_ACCOUNT FIN
           where FIN.FIN_LIQUIDITY = 1
             and FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
             and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
             and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
             and PER.PER_NO_PERIOD < aPER_NO_PERIOD
             and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
             and (    (ACS_DIVISION_ACCOUNT_ID is not null)
                  or (    ACS_DIVISION_ACCOUNT_ID is null
                      and ACR_FUNCTIONS.ExistDivision = 0)
                 )
        group by TOT.ACS_FINANCIAL_ACCOUNT_ID
               , TOT.ACS_DIVISION_ACCOUNT_ID
               , TOT.ACS_FINANCIAL_CURRENCY_ID
               , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
               , TOT.C_TYPE_CUMUL;

      ------
      cursor LiqAccountCreditLimitCursor(aDateFrom ACS_PERIOD.PER_START_DATE%type)
      is
        select FIN.ACS_FINANCIAL_ACCOUNT_ID
             , ACS_FUNCTION.GetDivisionOfAccount(FIN.ACS_FINANCIAL_ACCOUNT_ID, null, aDateFrom) ACS_DIVISION_ACCOUNT_ID
             , nvl(FIN.FIN_CREDIT_LIMIT, 0) FIN_CREDIT_LIMIT
             , case when FIN.FIN_EXPIRATION_LIMIT is null then 0 else 1 end HAS_LIMIT
             , trunc(FIN.FIN_EXPIRATION_LIMIT) + 1 FIN_EXPIRATION_LIMIT
          from ACS_FINANCIAL_ACCOUNT FIN
         where FIN.FIN_LIQUIDITY = 1
           and nvl(FIN.FIN_CREDIT_LIMIT, 0) <> 0
           and (   trunc(FIN.FIN_EXPIRATION_LIMIT) >= trunc(aDateFrom)
                or FIN.FIN_EXPIRATION_LIMIT is null);

      LiqAccountImputations   LiqAccountImputationsCursor%rowtype;
      LiqAccountReportAmounts LiqAccountReportAmountsCursor%rowtype;
      LiqAccountCreditLimit   LiqAccountCreditLimitCursor%rowtype;
      CashFlowImputationId    ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;
      YearId                  ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type;
      NoPeriod                ACS_PERIOD.PER_NO_PERIOD%type;
      Amount_LC_D             ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type;
      Amount_LC_C             ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_C%type;
      Amount_FC_D             ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_FC_D%type;
      Amount_FC_C             ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_FC_C%type;
      JustBeforeDate          ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type;
      JustBeforePeriodId      ACS_PERIOD.ACS_PERIOD_ID%type;
      -----
      ExistDivision           number(1);
    begin
      -- Mouvements des comptes liquidités pour la période sélectionnée
      open LiqAccountImputationsCursor(aDateFrom, aDateTo);

      fetch LiqAccountImputationsCursor
       into LiqAccountImputations;

      while LiqAccountImputationsCursor%found loop
        CashFlowImputationId  :=
          AddAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                               , LiqAccountImputations.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                               , LiqAccountImputations.ACS_DIVISION_ACCOUNT_ID   --Compte division
                               , LiqAccountImputations.C_TYPE_CUMUL   --Type de cumul
                               , LiqAccountImputations.C_ETAT_JOURNAL   --Etat journal
                               , 'LIQ'   --Type mouvement trésorerie
                               , LiqAccountImputations.IMF_AMOUNT_LC_D   --Montant LCD
                               , LiqAccountImputations.IMF_AMOUNT_LC_C   --Montant LCC
                               , LiqAccountImputations.IMF_AMOUNT_FC_D   --Montant FCD
                               , LiqAccountImputations.IMF_AMOUNT_FC_C   --Montant FCC
                               , LiqAccountImputations.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                               , LiqAccountImputations.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                               , LiqAccountImputations.IMF_VALUE_DATE   --Date mouvement
                               , null   --Sous-ensemble
                               , null   --Gabarit document structuré
                               , LiqAccountImputations.ACT_DOCUMENT_ID   --Document comptable
                               , null   --Document logistique
                               , LiqAccountImputations.PAC_PERSON_ID   --Partenaire
                               , LiqAccountImputations.DOC_RECORD_ID  --Dossier
                               , null   --Mandat document logistique
                                );
        commit;

        fetch LiqAccountImputationsCursor
         into LiqAccountImputations;
      end loop;

      close LiqAccountImputationsCursor;

      -- Recherche Id de l'exercice et n° période de la période de début d'analyse
      select ACS_FINANCIAL_YEAR_ID
           , PER_NO_PERIOD
        into YearId
           , NoPeriod
        from ACS_PERIOD
       where ACS_PERIOD_ID = aACS_PERIOD_FROM_ID;

      JustBeforePeriodId            := ACS_FUNCTION.GetPeriodID(trunc(aDateFrom - 1), '2');

      if JustBeforePeriodId is null then
        JustBeforeDate  := aDateFrom;
      else
        JustBeforeDate  := aDateFrom - 1;
      end if;

      --Initialisation de la variable du package ACR_FUNCTIONS
      select decode(min(ACS_SUB_SET_ID), null, 0, 1)
        into ExistDivision
        from ACS_SUB_SET
       where C_TYPE_SUB_SET = 'DIVI';

      ACR_FUNCTIONS.EXIST_DIVISION  := ExistDivision;

      -- Cumul des mouvements des comptes liquidités pour les périodes précédent la période de début d'analyse
      open LiqAccountReportAmountsCursor(YearId, NoPeriod);

      fetch LiqAccountReportAmountsCursor
       into LiqAccountReportAmounts;

      while LiqAccountReportAmountsCursor%found loop
        if sign(LiqAccountReportAmounts.TOT_DEBIT_LC) = -1 then
          Amount_LC_D  := 0;
          Amount_LC_C  := abs(LiqAccountReportAmounts.TOT_DEBIT_LC);
          Amount_FC_D  := 0;
          Amount_FC_C  := abs(LiqAccountReportAmounts.TOT_DEBIT_FC);
        else
          Amount_LC_D  := LiqAccountReportAmounts.TOT_DEBIT_LC;
          Amount_LC_C  := 0;
          Amount_FC_D  := LiqAccountReportAmounts.TOT_DEBIT_FC;
          Amount_FC_C  := 0;
        end if;

        CashFlowImputationId  :=
          AddAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                               , LiqAccountReportAmounts.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                               , LiqAccountReportAmounts.ACS_DIVISION_ACCOUNT_ID   --Compte division
                               , LiqAccountReportAmounts.C_TYPE_CUMUL   --Type de cumul
                               , 'DEF'   --Etat journal
                               , 'LIR'   --Type mouvement trésorerie
                               , Amount_LC_D   --Montant LCD
                               , Amount_LC_C   --Montant LCC
                               , Amount_FC_D   --Montant FCD
                               , Amount_FC_C   --Montant FCC
                               , LiqAccountReportAmounts.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                               , LiqAccountReportAmounts.ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                               , JustBeforeDate   --Date mouvement
                               , null   --Sous-ensemble
                               , null   --Gabarit document structuré
                               , null   --Document comptable
                               , null   --Document logistique
                               , null   --Partenaire
                               , null   --Dossier
                               , null   --Mandat document logistique
                                );

        fetch LiqAccountReportAmountsCursor
         into LiqAccountReportAmounts;
      end loop;

      close LiqAccountReportAmountsCursor;

      -- Limite de crédit des comptes liquidités à la date de début d'analyse
      open LiqAccountCreditLimitCursor(aDateFrom);

      fetch LiqAccountCreditLimitCursor
       into LiqAccountCreditLimit;

      while LiqAccountCreditLimitCursor%found loop
        CashFlowImputationId  :=
          AddAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                               , LiqAccountCreditLimit.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                               , LiqAccountCreditLimit.ACS_DIVISION_ACCOUNT_ID   --Compte division
                               , 'EXT'   --Type de cumul
                               , 'DEF'   --Etat journal
                               , 'LIM'   --Type mouvement trésorerie
                               , LiqAccountCreditLimit.FIN_CREDIT_LIMIT   --Montant LCD
                               , 0   --Montant LCC
                               , 0   --Montant FCD
                               , 0   --Montant FCC
                               , LocalCurrencyId   --Monnaie étrangère
                               , LocalCurrencyId   --Monnaie de base
                               , JustBeforeDate   --Date mouvement
                               , null   --Sous-ensemble
                               , null   --Gabarit document structuré
                               , null   --Document comptable
                               , null   --Document logistique
                               , null   --Partenaire
                               , null   --Dossier
                               , null   --Mandat document logistique
                                );
        -- Si la limite de crédit expire avant la date de fin d'analyse, on insère une limite de crédit avec le même montant
        -- mais en négatif à partir de la date d'expiration pour annuler celle-ci.
        if (LiqAccountCreditLimit.HAS_LIMIT = 1) and (LiqAccountCreditLimit.FIN_EXPIRATION_LIMIT <= trunc(aDateTo)) then
          CashFlowImputationId  :=
            AddAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                                 , LiqAccountCreditLimit.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                                 , LiqAccountCreditLimit.ACS_DIVISION_ACCOUNT_ID   --Compte division
                                 , 'EXT'   --Type de cumul
                                 , 'DEF'   --Etat journal
                                 , 'LIM'   --Type mouvement trésorerie
                                 , LiqAccountCreditLimit.FIN_CREDIT_LIMIT * -1  --Montant LCD inversé
                                 , 0   --Montant LCC
                                 , 0   --Montant FCD
                                 , 0   --Montant FCC
                                 , LocalCurrencyId   --Monnaie étrangère
                                 , LocalCurrencyId   --Monnaie de base
                                 , LiqAccountCreditLimit.FIN_EXPIRATION_LIMIT  --Date mouvement
                                 , null   --Sous-ensemble
                                 , null   --Gabarit document structuré
                                 , null   --Document comptable
                                 , null   --Document logistique
                                 , null   --Partenaire
                                 , null   --Dossier
                                 , null   --Mandat document logistique
                                  );
        end if;

        fetch LiqAccountCreditLimitCursor
         into LiqAccountCreditLimit;
      end loop;

      close LiqAccountCreditLimitCursor;
    end InsertLiqAccountImputations;
  --------
  begin
    select *
      into CashFlowAnalysis
      from ACR_CASH_FLOW_ANALYSIS
     where ACR_CASH_FLOW_ANALYSIS_ID = aACR_CASH_FLOW_ANALYSIS_ID;

    DetailedAnalysis  := CashFlowAnalysis.CFA_DETAILED_METHOD;
    ExistCpn          := ACS_FUNCTION.ExistCSubSet('CPN');
    DateFrom          := ACT_CURRENCY_EVALUATION.GetDateOfPeriod(CashFlowAnalysis.ACS_PERIOD_FROM_ID, true);
    DateTo            := ACT_CURRENCY_EVALUATION.GetDateOfPeriod(CashFlowAnalysis.ACS_PERIOD_TO_ID, false);

    if CashFlowAnalysis.CFA_EFF_AMOUNTS = 1 then
      InsertManuelImputations(aACR_CASH_FLOW_ANALYSIS_ID, DateFrom, DateTo);
      -- Paiements effectués - C_TYPE_CATALOGUE in ('3', '4', '9')
      -- Compte collectif -> Imputations document d'origine : C_CASH_FLOW_IMP_TYP = 'EPC', 'ELC'
      -- Compte non collectif : C_CASH_FLOW_IMP_TYP = 'EPN', 'ELN'  + TVA: C_CASH_FLOW_IMP_TYP = 'EPV', 'ELV'
      InsertPaiedImputation(aACR_CASH_FLOW_ANALYSIS_ID, DateFrom, DateTo);
    end if;

    if CashFlowAnalysis.CFA_PLA_AMOUNTS = 1 then
      -- Imputations planifiées (le mouvement de fonds n'a pas encore eu lieu --> planification trésorerie)
      -- Le traitement s'appuie sur les postes ouverts !
      -- C_CASH_FLOW_IMP_TYP = 'PLA'
      -- C_TYPE_CATALOGUE in = ('2', '5', '6')
      InsertExpiriesImputation(aACR_CASH_FLOW_ANALYSIS_ID
                             , CashFlowAnalysis.CFA_PLA_ALL_DATES
                             , DateFrom
                             , DateTo
                             , CashFlowAnalysis.CFA_DATE
                              );
    end if;

    /**
    * Les types LIM, LIQ et LIR  (imputations pour comptes de liquidités)
    * doivent être, dans tous les cas, générées
    * Imputations      : C_CASH_FLOW_IMP_TYP = 'LIQ'
    * Report           : C_CASH_FLOW_IMP_TYP = 'LIR'
    * Limite de crédit : C_CASH_FLOW_IMP_TYP = 'LIM'
    * Imputations sur Comptes de liquidités - C_TYPE_CATALOGUE sans limitations
    **/
    InsertLiqAccountImputations(aACR_CASH_FLOW_ANALYSIS_ID, CashFlowAnalysis.ACS_PERIOD_FROM_ID, DateFrom, DateTo);

    /* Données budgetisé */
    if CashFlowAnalysis.CFA_BUD_AMOUNTS = 1 then
      InsertBudgetImputations(aACR_CASH_FLOW_ANALYSIS_ID, DateFrom, DateTo);
    end if;

    /* Données logistiques */
    if CashFlowAnalysis.CFA_DOC_AMOUNTS = 1 then
      InsertDOCImputations(aACR_CASH_FLOW_ANALYSIS_ID, CashFlowAnalysis.CFA_POR_ALL_DATES, DateFrom, DateTo);
    end if;

    /* Données salaires */
    if CashFlowAnalysis.CFA_SAL_AMOUNTS = 1 then
      InsertHRMImputations(aACR_CASH_FLOW_ANALYSIS_ID);
    end if;

    /* Données dossiers affaire */
    if CashFlowAnalysis.CFA_REC_AMOUNTS = 1 then
      InsertCGImputations(aACR_CASH_FLOW_ANALYSIS_ID, DateFrom, DateTo);
      InsertANImputations(aACR_CASH_FLOW_ANALYSIS_ID, DateFrom, DateTo);
    end if;

    GroupAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID);

    /* Traitement particulier et individualisé des données pour les dossiers d'affaires */
    if CashFlowAnalysis.CFA_REC_AMOUNTS = 1 then
      -- Exécution de la procédure spécifiées par la config.
      --    gal_functions.Grp_Order_Project_In_ACR_Cash (aACR_CASH_FLOW_ANALYSIS_ID);
      execute immediate 'begin ' || lv_GalCashGroupOrderProc || '(:aACR_CASH_FLOW_ANALYSIS_ID); end;'
        using aACR_CASH_FLOW_ANALYSIS_ID;
    end if;

    CreateFootTableRows(aACR_CASH_FLOW_ANALYSIS_ID, DateFrom, DateTo, CashFlowAnalysis.CFA_EFF_AMOUNTS, CashFlowAnalysis.CFA_PLA_AMOUNTS);
  end NewAnalysisImputations;

  /**
  * Description Création / modification d'un mvt de trésorerie basé sur les
  *             montants des imputations CG avec dossiers d'affaire
  **/
  procedure InsertCGImputations(
    pCashFlowAnalysisId ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
  , pStartDate          ACS_PERIOD.PER_START_DATE%type
  , pEndDate            ACS_PERIOD.PER_END_DATE%type
  )
  is
    cursor FinancialImputationCursor(pStartDate ACS_PERIOD.PER_START_DATE%type, pEndDate ACS_PERIOD.PER_END_DATE%type)
    is
      /**
      *  Imputations financières avec dossier d'affaire dont la CPN du compte
      *  est définie comme "Dépense" ou "Recette"
      **/
      select   IMF.ACS_FINANCIAL_ACCOUNT_ID
             , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
             , IMF.IMF_ACS_DIVISION_ACCOUNT_ID
             , IMF.ACS_FINANCIAL_CURRENCY_ID
             , PER.PER_END_DATE
             , sum(nvl(IMF.IMF_AMOUNT_LC_D, 0) - nvl(IMF.IMF_AMOUNT_LC_C, 0) ) AMOUNT_L_D_C
             , sum(nvl(IMF.IMF_AMOUNT_FC_D, 0) - nvl(IMF.IMF_AMOUNT_FC_C, 0) ) AMOUNT_F_D_C
             , IMF.ACS_PERIOD_ID
             , IMF.DOC_RECORD_ID
             , IMF.ACT_DOCUMENT_ID
             , SCA.C_TYPE_CUMUL
             , ETA.C_ETAT_JOURNAL
      from ACT_FINANCIAL_IMPUTATION IMF
           , ACS_PERIOD PER
           , ACT_ETAT_JOURNAL ETA
           , ACJ_SUB_SET_CAT SCA
           , ACT_DOCUMENT DOC
           , ACJ_CATALOGUE_DOCUMENT CAT
      where
        -- Périodes correspondantes à celle de l'analyse
            trunc(PER.PER_START_DATE) >= trunc(pStartDate)
        and trunc(PER.PER_END_DATE) <= trunc(pEndDate)
        and IMF.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
        --Document de l'imputation financière est une écriture CG / AN
        and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
        and CAT.C_TYPE_CATALOGUE = '1'
        and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
        -- Type de cumul
        and SCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
        and SCA.C_SUB_SET = 'ACC'
        --Etat journal du document
        and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
        and ETA.C_SUB_SET = 'ACC'
        --Dossier d'affaire
        and exists (select 1
                           from DOC_RECORD REC
                           where  REC.DOC_RECORD_ID = IMF.DOC_RECORD_ID
                                and REC.C_RCO_TYPE IN  ('01','02','03','04','05','07','08','09'))
        --Compte CPN du compte financier de l'imputation est "Dépense" ou "Recette"
        and exists (select 1
                           from ACS_FINANCIAL_ACCOUNT FIN
                                , ACS_CPN_ACCOUNT CPN
                           where FIN.ACS_FINANCIAL_ACCOUNT_ID =IMF.ACS_FINANCIAL_ACCOUNT_ID
                              and CPN.ACS_CPN_ACCOUNT_ID = FIN.ACS_CPN_ACCOUNT_ID
                              and CPN.C_EXPENSE_RECEIPT IN ('1', '2'))
        -- Le document comptable ne contient pas d'écritures sur un compte de bilan coché Liquidité
        and not exists (select 1
                           from ACS_FINANCIAL_ACCOUNT FINACC
                                , ACT_FINANCIAL_IMPUTATION FINIMP
                           where FINIMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                              and FINACC.ACS_FINANCIAL_ACCOUNT_ID = FINIMP.ACS_FINANCIAL_ACCOUNT_ID
                              and FINACC.FIN_LIQUIDITY = 1
                              and FINACC.C_BALANCE_SHEET_PROFIT_LOSS = 'B')
      group by IMF.ACS_FINANCIAL_ACCOUNT_ID
             ,IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
             ,IMF.IMF_ACS_DIVISION_ACCOUNT_ID
             ,IMF.ACS_FINANCIAL_CURRENCY_ID
             ,PER.PER_END_DATE
             ,IMF.ACS_PERIOD_ID
             ,IMF.DOC_RECORD_ID
             ,IMF.ACT_DOCUMENT_ID
             ,SCA.C_TYPE_CUMUL
             ,ETA.C_ETAT_JOURNAL;

    vFinancialImputations FinancialImputationCursor%rowtype;
    vCashFlowImpId     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;
    vAmountLCD         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    vAmountLCC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    vAmountFCD         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    vAmountFCC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
  begin
    /**
    * Création d'un mouvement de trésorerie pour chaque enregistrement du curseur
    * le montant solde budgétisé positif resp. négatif étant mis au débit resp. crédit du mouvement
    **/
    open FinancialImputationCursor(pStartDate, pEndDate);
    fetch FinancialImputationCursor

     into vFinancialImputations;

    while FinancialImputationCursor%found loop
      if vFinancialImputations.AMOUNT_L_D_C > 0 then
        vAmountLCD  := vFinancialImputations.AMOUNT_L_D_C;
        vAmountLCC  := 0;
      else
        vAmountLCD  := 0;
        vAmountLCC  := vFinancialImputations.AMOUNT_L_D_C * -1;
      end if;

      if vFinancialImputations.AMOUNT_F_D_C > 0 then
        vAmountFCD  := vFinancialImputations.AMOUNT_F_D_C;
        vAmountFCC  := 0;
      else
        vAmountFCD  := 0;
        vAmountFCC  := vFinancialImputations.AMOUNT_F_D_C * -1;
      end if;

      vCashFlowImpId  :=
        AddAnalysisImputation(pCashFlowAnalysisId   --Analyse trésorerie parente
                             , vFinancialImputations.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                             , vFinancialImputations.IMF_ACS_DIVISION_ACCOUNT_ID   --Compte division
                             , vFinancialImputations.C_TYPE_CUMUL   --Type de cumul
                             , vFinancialImputations.C_ETAT_JOURNAL   --Etat journal
                             , 'CG'   --Type mouvement trésorerie
                             , vAmountLCD   --Montant LCD
                             , vAmountLCC   --Montant LCC
                             , vAmountFCD  --Montant FCD
                             , vAmountFCC  --Montant FCC
                             , vFinancialImputations.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                             , vFinancialImputations.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                             , vFinancialImputations.PER_END_DATE   --Date mouvement
                             , null   --Sous-ensemble
                             , null   --Gabarit document structuré
                             , vFinancialImputations.ACT_DOCUMENT_ID --Document comptable
                             , null   --Document logistique
                             , null   --Partenaire
                             , vFinancialImputations.DOC_RECORD_ID   --Dossier
                             , null   --Mandat document logistique
                              );
      commit;

      fetch FinancialImputationCursor
       into vFinancialImputations;
    end loop;

    close FinancialImputationCursor;
  end InsertCGImputations;

  /**
  * Description Création / modification d'un mvt de trésorerie basé sur les
  *             montants des imputations AN avec dossiers d'affaire
  **/
  procedure InsertANImputations(
    pCashFlowAnalysisId ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
  , pStartDate          ACS_PERIOD.PER_START_DATE%type
  , pEndDate            ACS_PERIOD.PER_END_DATE%type
  )
  is
    cursor AnlyticalImputationCursor(pStartDate ACS_PERIOD.PER_START_DATE%type, pEndDate ACS_PERIOD.PER_END_DATE%type)
    is
      /**
      *  Imputations analytiques avec dossier d'affaire dont la CPN du compte
      *  est définie comme "Dépense" ou "Recette"
      **/
      select IMM.ACS_CPN_ACCOUNT_ID
           , IMM.ACS_FINANCIAL_CURRENCY_ID
           , IMM.ACS_ACS_FINANCIAL_CURRENCY_ID
           , PER.PER_END_DATE
           , sum(nvl(IMM.IMM_AMOUNT_LC_D, 0) - nvl(IMM.IMM_AMOUNT_LC_C, 0) ) AMOUNT_L_D_C
           , sum(nvl(IMM.IMM_AMOUNT_FC_D, 0) - nvl(IMM.IMM_AMOUNT_FC_C, 0) ) AMOUNT_F_D_C
           , IMM.ACS_PERIOD_ID
           , IMM.DOC_RECORD_ID
           , IMM.ACT_DOCUMENT_ID
           , SCA.C_TYPE_CUMUL
           , ETA.C_ETAT_JOURNAL
      from ACT_MGM_IMPUTATION IMM
         , ACS_PERIOD PER
         , ACS_CPN_ACCOUNT CPN
         , ACT_DOCUMENT DOC
         , ACT_ETAT_JOURNAL ETA
         , ACJ_SUB_SET_CAT SCA
      where
          -- Périodes correspondantes à celle de l'analyse
             trunc(PER.PER_START_DATE) >= trunc(pStartDate)
         and trunc(PER.PER_END_DATE) <= trunc(pEndDate)
         and IMM.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and DOC.ACT_DOCUMENT_ID = IMM.ACT_DOCUMENT_ID
         and SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
        --Etat journal analytique du document
        and DOC.ACT_ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
        and ETA.C_SUB_SET = 'CPN'
         --Dossier d'affaire
         and exists  (select 1
                           from DOC_RECORD REC
                           where  REC.DOC_RECORD_ID = IMM.DOC_RECORD_ID
                                and REC.C_RCO_TYPE IN  ('01','02','03','04','05','07','08','09'))
          --Document de l'imputation financière est une écriture AN et le catalogue document
         -- n’a qu’un seul sous-ensemble de type CPN
          and exists (select 1
                           from  ACJ_CATALOGUE_DOCUMENT CAT
                                 , ACJ_SUB_SET_CAT SUB
                          where CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                              and CAT.C_TYPE_CATALOGUE = '1'
                              and SUB.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                              having  decode(count(*), sum(decode(C_SUB_SET,'CPN',1,0)),1,0)  = 1
                              )
         --Compte CPN de l'imputation est "Dépense" ou "Recette"
         and CPN.ACS_CPN_ACCOUNT_ID = IMM.ACS_CPN_ACCOUNT_ID
         and CPN.C_EXPENSE_RECEIPT IN ('1', '2')
       group by  IMM.ACS_CPN_ACCOUNT_ID
              , IMM.ACS_FINANCIAL_CURRENCY_ID
              , IMM.ACS_ACS_FINANCIAL_CURRENCY_ID
              , IMM.ACT_DOCUMENT_ID
              , PER.PER_END_DATE
              , IMM.ACS_PERIOD_ID
              , IMM.DOC_RECORD_ID
              , SCA.C_TYPE_CUMUL
              , ETA.C_ETAT_JOURNAL;

    AnalyticalImputation AnlyticalImputationCursor%rowtype;
    vCashFlowImpId    ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;
    vAmountLCD         ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type;
    vAmountLCC         ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type;
    vAmountFCD         ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type;
    vAmountFCC         ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type;
  begin
    /**
    * Création d'un mouvement de trésorerie pour chaque enregistrement du curseur
    * le montant solde budgétisé positif resp. négatif étant mis au débit resp. crédit du mouvement
    **/
    open AnlyticalImputationCursor(pStartDate, pEndDate);

    fetch AnlyticalImputationCursor
     into AnalyticalImputation;

    while AnlyticalImputationCursor%found loop
      if AnalyticalImputation.AMOUNT_L_D_C > 0 then
        vAmountLCD  := AnalyticalImputation.AMOUNT_L_D_C;
        vAmountLCC  := 0;
      else
        vAmountLCD  := 0;
        vAmountLCC  := AnalyticalImputation.AMOUNT_L_D_C * -1;
      end if;

     if AnalyticalImputation.AMOUNT_F_D_C > 0 then
        vAmountFCD  := AnalyticalImputation.AMOUNT_F_D_C;
        vAmountFCC  := 0;
      else
        vAmountFCD  := 0;
        vAmountFCC  := AnalyticalImputation.AMOUNT_F_D_C * -1;
      end if;

      vCashFlowImpId  :=
        AddAnalysisImputation(pCashFlowAnalysisId   --Analyse trésorerie parente
                             , AnalyticalImputation.ACS_CPN_ACCOUNT_ID  --Compte ANALYTIQUE
                             , null   --Compte division
                             , AnalyticalImputation.C_TYPE_CUMUL   --Type de cumul
                             , AnalyticalImputation.C_ETAT_JOURNAL   --Etat journal
                             , 'AN'   --Type mouvement trésorerie
                             , vAmountLCD   --Montant LCD
                             , vAmountLCC   --Montant LCC
                             , vAmountFCD   --Montant FCD
                             , vAmountFCC   --Montant FCC
                             , AnalyticalImputation.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                             , AnalyticalImputation.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                             , AnalyticalImputation.PER_END_DATE   --Date mouvement
                             , null   --Sous-ensemble
                             , null   --Gabarit document structuré
                             , AnalyticalImputation.ACT_DOCUMENT_ID   --Document comptable
                             , null   --Document logistique
                             , null   --Partenaire
                             , AnalyticalImputation.DOC_RECORD_ID   --Dossier
                             , null   --Mandat document logistique
                              );
      commit;

      fetch AnlyticalImputationCursor
       into AnalyticalImputation;
    end loop;

    close AnlyticalImputationCursor;
  end InsertANImputations;

  /**
  * Description Création / modification d'un mvt de trésorerie  basé sur les
  *             mouvement financiers manuels
  **/
  procedure InsertManuelImputations(
    pCashFlowAnalysisId ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
  , pStartDate          ACS_PERIOD.PER_START_DATE%type
  , pEndDate            ACS_PERIOD.PER_END_DATE%type
  )
  is
    cursor ManuelImputationsCursor(pStartDate ACS_PERIOD.PER_START_DATE%type, pEndDate ACS_PERIOD.PER_END_DATE%type)
    is
      /**
      *  Imputations financières
      *       dont les dates correcpondent à l'intervalle donné
      *       pour les documents dont le catalogue est de type de transaction  "Ecriture financière / analytique"  (C_TYPE_CATALOGUE = '1')
      *               et possèdant au moins une imputations dont le compte financier est de type "Liquidité"
      *       dont le compte financier n'est pas de type "Liquidité"
      *               ==> Evite de prendre en compte les imputations de transfert de compte liquidité à compte liquidité
      *  Document de l'imputation
      *  Division de l'éventuelle distribution liée à l'imputation
      *  Type de cumul du sous-ensemble financier lié au catalogue document
      *  Etat journal du journal financier contenant le document
      *  Sous-ensemble du compte auxiliaire de l'imputation
      **/
      select IMP.ACS_FINANCIAL_ACCOUNT_ID
           , IMP.IMF_AMOUNT_LC_D
           , IMP.IMF_AMOUNT_LC_C
           , IMP.IMF_AMOUNT_FC_D
           , IMP.IMF_AMOUNT_FC_C
           , IMP.ACS_FINANCIAL_CURRENCY_ID
           , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
           , IMP.IMF_VALUE_DATE
           , IMP.ACS_PERIOD_ID
           , IMP.ACT_DOCUMENT_ID
           , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
           , SCA.C_TYPE_CUMUL
           , ETA.C_ETAT_JOURNAL
           , ACS_FUNCTION.GetSubSetIdByAccount(IMP.ACS_AUXILIARY_ACCOUNT_ID) ACS_SUB_SET_ID
           , decode(DetailedAnalysis,
                    1, decode(ExistCpn,
                              1, ACR_CASH_FLOW_MANAGEMENT.GetMgmImputationRecordId(IMP.ACT_FINANCIAL_IMPUTATION_ID),
                              IMP.DOC_RECORD_ID),
                    null) DOC_RECORD_ID
        from ACT_ETAT_JOURNAL ETA
           , ACJ_SUB_SET_CAT SCA
           , ACS_FINANCIAL_ACCOUNT ACC
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , V_ACT_FIN_IMP_CASH_FLOW IMP
       where trunc(IMF_VALUE_DATE) between trunc(pStartDate) and trunc(pEndDate)
         and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_TYPE_CATALOGUE = '1'
         and exists(
               select 1
                 from ACS_FINANCIAL_ACCOUNT ACC2
                    , ACT_FINANCIAL_IMPUTATION IMP2
                where IMP2.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                  and IMP2.ACS_FINANCIAL_ACCOUNT_ID = ACC2.ACS_FINANCIAL_ACCOUNT_ID
                  and ACC2.FIN_LIQUIDITY = 1)
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_FINANCIAL_ACCOUNT_ID
         and ACC.FIN_LIQUIDITY = 0
         and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
         and SCA.C_SUB_SET = 'ACC'
         and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
         and ETA.C_SUB_SET = 'ACC';

    vManuelImputations ManuelImputationsCursor%rowtype;   --Réceptionne les données du curseur
    vCashFlowImpId     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;   --Réceptionne l'id la position nouvellement créée
  begin
    /**
    * Création d'un mouvement de trésorerie pour chaque enregistrement du curseur
    **/
    open ManuelImputationsCursor(pStartDate, pEndDate);

    fetch ManuelImputationsCursor
     into vManuelImputations;

    while ManuelImputationsCursor%found loop
      vCashFlowImpId  :=
        AddAnalysisImputation(pCashFlowAnalysisId   --Analyse trésorerie parente
                             , vManuelImputations.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                             , vManuelImputations.ACS_DIVISION_ACCOUNT_ID   --Compte division
                             , vManuelImputations.C_TYPE_CUMUL   --Type de cumul
                             , vManuelImputations.C_ETAT_JOURNAL   --Etat journal
                             , 'EFF'   --Type mouvement trésorerie
                             , vManuelImputations.IMF_AMOUNT_LC_D   --Montant LCD
                             , vManuelImputations.IMF_AMOUNT_LC_C   --Montant LCC
                             , vManuelImputations.IMF_AMOUNT_FC_D   --Montant FCD
                             , vManuelImputations.IMF_AMOUNT_FC_C   --Montant FCC
                             , vManuelImputations.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                             , vManuelImputations.ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                             , vManuelImputations.IMF_VALUE_DATE   --Date mouvement
                             , vManuelImputations.ACS_SUB_SET_ID   --Sous-ensemble
                             , null   --Gabarit document structuré
                             , vManuelImputations.ACT_DOCUMENT_ID   --Document comptable
                             , null   --Document logistique
                             , null   --Partenaire
                             , vManuelImputations.DOC_RECORD_ID  --Dossier
                             , null   --Mandat document logistique
                              );
      commit;

      fetch ManuelImputationsCursor
       into vManuelImputations;
    end loop;

    close ManuelImputationsCursor;
  end InsertManuelImputations;

  /**
  * Description Création / modification d'un mvt de trésorerie basé sur les
  *             montants budgétisés
  **/
  procedure InsertBudgetImputations(
    pCashFlowAnalysisId ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
  , pStartDate          ACS_PERIOD.PER_START_DATE%type
  , pEndDate            ACS_PERIOD.PER_END_DATE%type
  )
  is
    cursor BudgetImputationsCursor(pStartDate ACS_PERIOD.PER_START_DATE%type, pEndDate ACS_PERIOD.PER_END_DATE%type)
    is
      /**
      *  Recherche des valeurs des périodes budgétisé comprises dans l'intervalle
      *  donné, des budgets fixes des versions trésorerie touchant un compte financier de type liquidité
      **/
      select   GLO.ACS_FINANCIAL_ACCOUNT_ID
             , GLO.ACS_DIVISION_ACCOUNT_ID
             , GLO.ACS_FINANCIAL_CURRENCY_ID
             , PER.PER_END_DATE
             , sum(nvl(PAM.PER_AMOUNT_D, 0) - nvl(PAM.PER_AMOUNT_C, 0) ) AMOUNT_D_C
             , PAM.ACS_PERIOD_ID
          from ACS_FINANCIAL_CURRENCY FCUR
             , ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
             , ACB_PERIOD_AMOUNT PAM
             , ACS_PERIOD PER
         where trunc(PER.PER_START_DATE) >= trunc(pStartDate)
           and trunc(PER.PER_END_DATE) <= trunc(pEndDate)
           and PER.ACS_PERIOD_ID = PAM.ACS_PERIOD_ID
           and PAM.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
           and GLO.C_BUDGET_KIND = '1'
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and VER.VER_CASH_FLOW = 1
           and GLO.ACS_FINANCIAL_CURRENCY_ID = FCUR.ACS_FINANCIAL_CURRENCY_ID
           and FCUR.FIN_LOCAL_CURRENCY = 1
      group by GLO.ACS_FINANCIAL_ACCOUNT_ID
             , GLO.ACS_DIVISION_ACCOUNT_ID
             , GLO.ACS_FINANCIAL_CURRENCY_ID
             , PER.PER_END_DATE
             , PAM.ACS_PERIOD_ID;

    vBudgetImputations BudgetImputationsCursor%rowtype;
    vCashFlowImpId     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;
    vAmountLCD         ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type;
    vAmountLCC         ACB_GLOBAL_BUDGET.GLO_AMOUNT_C%type;
  begin
    /**
    * Création d'un mouvement de trésorerie pour chaque enregistrement du curseur
    * le montant solde budgétisé positif resp. négatif étant mis au débit resp. crédit du mouvement
    **/
    open BudgetImputationsCursor(pStartDate, pEndDate);

    fetch BudgetImputationsCursor
     into vBudgetImputations;

    while BudgetImputationsCursor%found loop
      if vBudgetImputations.AMOUNT_D_C > 0 then
        vAmountLCD  := vBudgetImputations.AMOUNT_D_C;
        vAmountLCC  := 0;
      else
        vAmountLCD  := 0;
        vAmountLCC  := vBudgetImputations.AMOUNT_D_C * -1;
      end if;

      vCashFlowImpId  :=
        AddAnalysisImputation(pCashFlowAnalysisId   --Analyse trésorerie parente
                             , vBudgetImputations.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                             , vBudgetImputations.ACS_DIVISION_ACCOUNT_ID   --Compte division
                             , null   --Type de cumul
                             , null   --Etat journal
                             , 'BUD'   --Type mouvement trésorerie
                             , vAmountLCD   --Montant LCD
                             , vAmountLCC   --Montant LCC
                             , 0   --Montant FCD
                             , 0   --Montant FCC
                             , vBudgetImputations.ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                             , vBudgetImputations.ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
                             , vBudgetImputations.PER_END_DATE   --Date mouvement
                             , null   --Sous-ensemble
                             , null   --Gabarit document structuré
                             , null   --Document comptable
                             , null   --Document logistique
                             , null   --Partenaire
                             , null   --Dossier
                             , null   --Mandat document logistique
                              );
      commit;

      fetch BudgetImputationsCursor
       into vBudgetImputations;
    end loop;

    close BudgetImputationsCursor;
  end InsertBudgetImputations;

  /**
  * Description Création / modification d'un mvt de trésorerie basé sur les
  *             montants salaires
  **/
  procedure InsertHRMImputations(pCashFlowAnalysisId ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type)
  is
    cursor HRMImputationsCursor(pCashFlowAnalysisId ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type)
    is
      select TOT.ACS_ACCOUNT_ID
           , TOT.ACS_DIVISION_ACCOUNT_ID
           , TOT.AMOUNT_LC_D / decode(NB.NB_PERIOD, 0, 1, NB.NB_PERIOD) AMOUNT_LC_D
           , TOT.AMOUNT_LC_C / decode(NB.NB_PERIOD, 0, 1, NB.NB_PERIOD) AMOUNT_LC_C
        from (select   V.ACS_ACCOUNT_ID
                     , V.ACS_DIVISION_ACCOUNT_ID
                     , sum(V.AMOUNT_LC_D) AMOUNT_LC_D
                     , sum(V.AMOUNT_LC_C) AMOUNT_LC_C
                  from V_ACR_CASH_FLOW_HRM V
                 where V.HRM_PERIOD_ID in(
                                      select DED.HRM_PERIOD_ID
                                        from ACR_DEDUCTED_PERIOD DED
                                       where DED.ACR_CASH_FLOW_ANALYSIS_ID = pCashFlowAnalysisId
                                         and DED.DEP_SELECTED = 1)
              group by V.ACS_ACCOUNT_ID
                     , V.ACS_DIVISION_ACCOUNT_ID) TOT
           , (select count(HRM_PERIOD_ID) NB_PERIOD
                from ACR_DEDUCTED_PERIOD DED
               where DED.ACR_CASH_FLOW_ANALYSIS_ID = pCashFlowAnalysisId
                 and DED.DEP_SELECTED = 1) NB;

    cursor AnalysisPeriodCursor(aACR_CASH_FLOW_ANALYSIS_ID ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type)
    is
      select ANP.ACS_PERIOD_ID
           , ANP.ANP_DATE
        from ACR_ANALYSIS_PERIOD ANP
       where ANP.ACR_CASH_FLOW_ANALYSIS_ID = aACR_CASH_FLOW_ANALYSIS_ID
         and ANP.ANP_DATE is not null;

    vHRMImputations HRMImputationsCursor%rowtype;   --Réceptionne les données du curseur
    vAnalysisPeriod AnalysisPeriodCursor%rowtype;   --Réceptionne les données du curseur
    vCashFlowImpId  ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;   --Réceptionne l'id la position nouvellement créée
  begin
    open HRMImputationsCursor(pCashFlowAnalysisId);

    fetch HRMImputationsCursor
     into vHRMImputations;

    while HRMImputationsCursor%found loop
      open AnalysisPeriodCursor(pCashFlowAnalysisId);

      fetch AnalysisPeriodCursor
       into vAnalysisPeriod;

      while AnalysisPeriodCursor%found loop
        vCashFlowImpId  :=
          AddAnalysisImputation(pCashFlowAnalysisId   --Analyse trésorerie parente
                               , vHRMImputations.ACS_ACCOUNT_ID   --Compte financier
                               , vHRMImputations.ACS_DIVISION_ACCOUNT_ID   --Compte division
                               , null   --Type de cumul
                               , null   --Etat journal
                               , 'SAL'   --Type mouvement trésorerie
                               , vHRMImputations.AMOUNT_LC_D   --Montant LCD
                               , vHRMImputations.AMOUNT_LC_C   --Montant LCC
                               , 0   --Montant FCD
                               , 0   --Montant FCC
                               , LocalCurrencyId   --Monnaie étrangère
                               , LocalCurrencyId   --Monnaie de base
                               , vAnalysisPeriod.ANP_DATE   --Date mouvement
                               , null   --Sous-ensemble
                               , null   --Gabarit document structuré
                               , null   --Document comptable
                               , null   --Document logistique
                               , null   --Partenaire
                               , null   --Dossier
                               , null   --Mandat document logistique
                                );
        commit;

        fetch AnalysisPeriodCursor
         into vAnalysisPeriod;
      end loop;

      close AnalysisPeriodCursor;

      fetch HRMImputationsCursor
       into vHRMImputations;
    end loop;

    close HRMImputationsCursor;
  end InsertHRMImputations;

  procedure InsertDOCImputations(
    pCashFlowAnalysisId ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
  , pAllDates           ACR_CASH_FLOW_ANALYSIS.CFA_POR_ALL_DATES%type
  , pStartDate          ACS_PERIOD.PER_START_DATE%type
  , pEndDate            ACS_PERIOD.PER_END_DATE%type
  )
  is
    type TLogDocuments is table of V_ACR_CASH_FLOW_DOC%rowtype
      index by binary_integer;

    /* Recherche des sociétés sélectionées */
    cursor crSelectedCompanies(pAnalysisId ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type)
    is
      select COM.COM_NAME
        from ACR_CASH_COMP_SELECTED SEL
           , PCS.PC_COMP COM
       where SEL.ACR_CASH_FLOW_ANALYSIS_ID = pAnalysisId
         and SEl.CCS_DOC_SELECTED = 1
         and COM.PC_COMP_ID = SEL.PC_COMP_ID;

    /**
    * Réception des données détail de la conditions de paiement donnée
    **/
    cursor PaymentConditionCursor(pPaymentConditionId PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type)
    is
      select DET.C_TIME_UNIT
           , DET.CDE_ACCOUNT
           , DET.CDE_DAY
           , DET.CDE_PART
           , TOT.TOT_ACCOUNT
        from (select sum(CDE_ACCOUNT) TOT_ACCOUNT
                from PAC_CONDITION_DETAIL DET
               where PAC_PAYMENT_CONDITION_ID = pPaymentConditionId
                 and DET.CDE_DISCOUNT_RATE = 0) TOT
           , PAC_CONDITION_DETAIL DET
       where DET.PAC_PAYMENT_CONDITION_ID = pPaymentConditionId
         and DET.CDE_DISCOUNT_RATE = 0;

    vPaymentCondition  PaymentConditionCursor%rowtype;   --Réceptionne les données du curseur
    vCashFlowImpId     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;   --Réceptionne l'id la position nouvellement créée
    vTransactionDate   ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type;
    vCashFlowImpTyp    ACR_CASH_FLOW_IMPUTATION.C_CASH_FLOW_IMP_TYP%type;
    vAmountLCD         ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type;
    vAmountLCC         ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_C%type;
    vAmountFCD         ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_FC_D%type;
    vAmountFCC         ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_FC_C%type;
    vFinAccId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivAccId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vTaxFinAccId       ACR_CASH_FLOW_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
    vRecordId          DOC_RECORD.DOC_RECORD_ID%type;
    vGaugeId           DOC_GAUGE.DOC_GAUGE_ID%type;
    vThirdId           PAC_THIRD.PAC_THIRD_ID%type;
    vPeriodId          ACS_PERIOD.ACS_PERIOD_ID%type;
    vSubSetId          ACR_CASH_FLOW_IMPUTATION.ACS_SUB_SET_ID%type;
    vFCurrId           PCS.PC_CURR.PC_CURR_ID%type;
    vLCurrId           PCS.PC_CURR.PC_CURR_ID%type;
    vCashFlowCompName  PCS.PC_COMP.COM_NAME%type                                   := PCS.PC_I_LIB_SESSION.GetComName;   -- mandat de la trésorerie
    vCashFlowCompOwner PCS.PC_SCRIP.SCRDBOWNER%type;   -- propriétaire société de la trésorerie
    vSelectedCompOwner PCS.PC_SCRIP.SCRDBOWNER%type;   -- propriétaire société sélectionnée
    vSQLCode           varchar2(500);
    vLogDocuments      TLogDocuments;
    vQuantity          DOC_POSITION.POS_BALANCE_QUANTITY%type;
    vRatio             DOC_POSITION_IMPUTATION.POI_RATIO%type;

    function GetImputationDate(
      pAnalysisId       ACR_CASH_FLOW_ANALYSIS.ACR_CASH_FLOW_ANALYSIS_ID%type
    , pThirdId          PAC_PERSON.PAC_PERSON_ID%type
    , pDate             ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type
    , pCustom           number
    , pPaymentCondition PaymentConditionCursor%rowtype
    )
      return ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type
    is
      vResult                ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type;
      vACR_CF_DATE_WEIGHTING ACR_CF_DATE_WEIGHTING%rowtype;   --Réceptione les données de la table de pondération de dates
      vAuxAccId              ACS_ACCOUNT.ACS_ACCOUNT_ID%type;   --Réceptionne le compte auxiliaire du partenaire
      vDaysNumber            number                                     default 0;   --Réceptionne le nombre de jours selon unité
      vFactor                PAC_CUSTOM_PARTNER.CUS_PAYMENT_FACTOR%type default 0;   --Réceptionne le  coefficient de paiement
    ---
    begin
      /**
      * Le nombre de jour = le nombre d'unité pour l'unité en jour
      *                   = le nombre d'unité * 30 jours pour l'unité en mois
      **/
      if pPaymentCondition.C_TIME_UNIT = '0' then
        vDaysNumber  := pPaymentCondition.CDE_DAY;
      elsif pPaymentCondition.C_TIME_UNIT = '1' then
        vDaysNumber  := pPaymentCondition.CDE_DAY * 30;
      end if;

      /**
      * Réception du compte auxiliaire (Client / fournisseur) du tiers selon signe (-1 Domaine des Achats --> Fournisseur)
      **/
      if pCustom = 1 then
        vAuxAccId  := ACS_FUNCTION.GetAuxiliaryAccountId(pThirdId, 1);
      else
        vAuxAccId  := ACS_FUNCTION.GetAuxiliaryAccountId(pThirdId, 0);
      end if;

      /**
      * Réception des données des pondérations de dates de l'analyse courante
      * pour le sous-ensemble du compte auxiliaire donné et traitement uniquement si la pondération est activée pour
      * ce sous-ensemble...Calcul ou reprise de la valeur existante selon le code "Pondération  Date"  du coefficient de paiement
      **/
      vACR_CF_DATE_WEIGHTING  := GetSubSetDateWeighting(pAnalysisId, vAuxAccId);

      if vACR_CF_DATE_WEIGHTING.CFW_WEIGHTING = 1 then
        if vACR_CF_DATE_WEIGHTING.C_WEIGHTING_DATE_METHOD = '01' then
          if pCustom = 1 then
            vFactor  :=
              ACR_CASH_FLOW_MANAGEMENT.PartnerPaymentFactor
                                           (pThirdId   --Partenaire
                                          , 'C'   --Customer / Supplier
                                          , vACR_CF_DATE_WEIGHTING.CFW_DAYS_NUMBER   --Nombre de jours pris en compte
                                          , vACR_CF_DATE_WEIGHTING.CFW_INVOICE_AMOUNT   --Prise en compte montant document
                                           );
          else
            vFactor  :=
              ACR_CASH_FLOW_MANAGEMENT.PartnerPaymentFactor
                                           (pThirdId   --Partenaire
                                          , 'S'   --Customer / Supplier
                                          , vACR_CF_DATE_WEIGHTING.CFW_DAYS_NUMBER   --Nombre de jours pris en compte
                                          , vACR_CF_DATE_WEIGHTING.CFW_INVOICE_AMOUNT   --Prise en compte montant document
                                           );
          end if;
        else
          vFactor  :=
            GetFactorPartner(pThirdId,   --Partenaire
                             pCustom,   --Customer/Supplier
                             vACR_CF_DATE_WEIGHTING.C_WEIGHTING_DATE_METHOD);   --Code pour retour coefficient adapté (03) ou précédemment calculé (02)
        end if;
      end if;

      /**
      * Valeur de retour pondéré par le coefficient
      **/
      if vFactor <> 0 then
        vResult  := pDate + round(vDaysNumber * vFactor);
      else
        vResult  := pDate + vDaysNumber;
      end if;

      return vResult;
    end GetImputationDate;
  begin
    /**
    * Parcours des sociétés sélectionnées
    **/
    for vSelectedCompany in crSelectedCompanies(pCashFlowAnalysisId) loop
    declare
      vOldCompId PCS.PC_COMP.PC_COMP_ID%type;
      vTempCompId PCS.PC_COMP.PC_COMP_ID%type;
    begin
      /**
      * Recherche du propriétaire des tables et du Link de la société courante
      * si celle-ci différente du mandat de la trésorerie
      **/
      vSelectedCompOwner  := null;
      vCashFlowCompOwner  := null;

      -- stack old company value
      vOldCompId := PCS.PC_I_LIB_SESSION.getCompanyId;

      if vSelectedCompany.COM_NAME <> vCashFlowCompNAme then
        select PC_SCRIP.SCRDBOWNER, PC_COMP.PC_COMP_ID
          into vSelectedCompOwner,vTempCompId
          from PCS.PC_SCRIP
             , PCS.PC_COMP
         where PC_COMP.COM_NAME = vSelectedCompany.COM_NAME
           and PC_SCRIP.PC_SCRIP_ID = PC_COMP.PC_SCRIP_ID;

        vSelectedCompOwner  := vSelectedCompOwner || '.';
        vCashFlowCompOwner  := PCS.PC_I_LIB_SESSION.GetCompanyOwner || '.';
        -- set new active company, upto use the good configurations values
        PCS.PC_I_LIB_SESSION.SetCompanyId(vTempCompId);
      end if;

      /**
      *Commande SQL de calcul des simulations échéanciers
      **/
      vSQLCode            := 'BEGIN [SEL_COMPANY_OWNER]DOC_INVOICE_EXPIRY_FUNCTIONS.SimulateCashAtDate(:SelComName, :CashFlowCompName ,:CashFlowAnalysisId, :ref_date); END;';
      vSQLCode            := replace(vSQLCode, '[SEL_COMPANY_OWNER]', vSelectedCompOwner);

      execute immediate vSQLCode
                  using vSelectedCompany.COM_NAME, vCashFlowCompName, pCashFlowAnalysisId, pEndDate;

      /**
      *Commande SQL sur la vue des documents
      **/
      vSQLCode            :=
        'select V.* ' ||
        chr(13) ||
        'from [SEL_COMPANY_OWNER]V_ACR_CASH_FLOW_DOC V   ' ||
        chr(13) ||
        '   , [CASH_FLOW_OWNER]ACR_CASH_GAS_SELECTED SEL ' ||
        chr(13) ||
        '   , [CASH_FLOW_OWNER]DOC_GAUGE GAU             ' ||
        chr(13) ||
        'where SEL.ACR_CASH_FLOW_ANALYSIS_ID = [ACR_CASH_FLOW_ANALYSIS_ID] ' ||
        chr(13) ||
        '  and SEL.CGS_SELECTED = 1 ' ||
        chr(13) ||
        '  and GAU.DOC_GAUGE_ID = SEL.DOC_GAUGE_ID  ' ||
        chr(13) ||
        '  and V.GAU_DESCRIBE  = GAU.GAU_DESCRIBE ' ||
        chr(13) ||
        '  and V.COM_NAME_ACI = ''[CASH_FLOW_COMPANY]'' ';
      /**
      *Remplacement des macros
      **/
      vSQLCode            := replace(vSQLCode, '[SEL_COMPANY_OWNER]', vSelectedCompOwner);
      vSQLCode            := replace(vSQLCode, '[CASH_FLOW_OWNER]', vCashFlowCompOwner);
      vSQLCode            := replace(vSQLCode, '[ACR_CASH_FLOW_ANALYSIS_ID]', pCashFlowAnalysisId);
      vSQLCode            := replace(vSQLCode, '[CASH_FLOW_COMPANY]', vCashFlowCompName);

      /**
      *Exécution de la commande et réception des données dans la structure définie
      **/
      execute immediate vSQLCode
      bulk collect into vLogDocuments;

      -- reset current company as active company
      PCS.PC_I_LIB_SESSION.SetCompanyId(vOldCompId);

      if vLogDocuments.count > 0 then
        for vDocCounter in vLogDocuments.first .. vLogDocuments.last loop
          if vSelectedCompany.COM_NAME <> vCashFlowCompName then
            /**
            * Vérifier que la monnaie de base de la société traitée existe bien dans la société de la trésorerie
            * Vérifier que la monnaie du document existe bien dans la société de la trésorerie
            **/
            select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
            into vLCurrId
            from ACS_FINANCIAL_CURRENCY FIN
               , PCS.PC_CURR LCUR
            where LCUR.CURRENCY = vLogDocuments(vDocCounter).CompCurrencyName
	            and FIN.PC_CURR_ID = LCUR.PC_CURR_ID;

            select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
              into vFCurrId
            from ACS_FINANCIAL_CURRENCY FIN
               , PCS.PC_CURR FCUR
             where FCUR.CURRENCY = vLogDocuments(vDocCounter).DocCurrencyName
  	            and FIN.PC_CURR_ID = FCUR.PC_CURR_ID;

            select max(FIN.ACS_FINANCIAL_ACCOUNT_ID)
              into vFinAccId
              from ACS_ACCOUNT ACC_FIN
                 , ACS_FINANCIAL_ACCOUNT FIN
             where ACC_FIN.ACC_NUMBER = vLogDocuments(vDocCounter).ACC_NUMBER_FIN
               and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC_FIN.ACS_ACCOUNT_ID;

            select max(DIV.ACS_DIVISION_ACCOUNT_ID)
              into vDivAccId
              from ACS_ACCOUNT ACC_DIV
                 , ACS_DIVISION_ACCOUNT DIV
             where ACC_DIV.ACC_NUMBER = vLogDocuments(vDocCounter).ACC_NUMBER_DIV
               and DIV.ACS_DIVISION_ACCOUNT_ID = ACC_DIV.ACS_ACCOUNT_ID;

            select max(DOC_RECORD_ID)
              into vRecordId
              from DOC_RECORD
             where RCO_TITLE = vLogDocuments(vDocCounter).RCO_TITLE;

            select max(GAS.DOC_GAUGE_ID)
              into vGaugeId
              from DOC_GAUGE GAU
                 , DOC_GAUGE_STRUCTURED GAS
             where GAU.GAU_DESCRIBE = vLogDocuments(vDocCounter).GAU_DESCRIBE
               and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

            select max(THI.PAC_THIRD_ID)
              into vThirdId
              from PAC_THIRD THI
                 , PAC_PERSON PER
             where PER.PER_KEY1 = vLogDocuments(vDocCounter).PER_KEY1
               and THI.PAC_THIRD_ID = PER.PAC_PERSON_ID;

            if vThirdId is null then
              select max(THI.PAC_THIRD_ID)
                into vThirdId
                from PAC_THIRD THI
                   , PAC_PERSON PER
               where PER.PER_KEY2 = vLogDocuments(vDocCounter).PER_KEY2
                 and THI.PAC_THIRD_ID = PER.PAC_PERSON_ID;
            end if;
          else
            vLCurrId   := vLogDocuments(vDocCounter).CompCurrencyId;
            vFCurrId   := vLogDocuments(vDocCounter).DocCurrencyId;
            vFinAccId  := vLogDocuments(vDocCounter).ACS_FINANCIAL_ACCOUNT_ID;
            vRecordId  := vLogDocuments(vDocCounter).DOC_RECORD_ID;
            vGaugeId   := vLogDocuments(vDocCounter).DOC_GAUGE_ID;
            vThirdId   := vLogDocuments(vDocCounter).PAC_THIRD_ID;
          end if;

          /**
          * La monnaie de la société traitée et la monnaie du document de cette société sont également gérées
          * dans la société de la tréso...=> une des deux monnaies doit égaleent être la monnaie de base de la société de tréso
          **/
          if     (     (not vLCurrId is null)
                  and (not vFCurrId is null) )
             and (    (vLCurrId = LocalCurrencyId)
                  or (vFCurrId = LocalCurrencyId) ) then
            open PaymentConditionCursor(vLogDocuments(vDocCounter).PAC_PAYMENT_CONDITION_ID);

            fetch PaymentConditionCursor
             into vPaymentCondition;

            while PaymentConditionCursor%found loop
              vTransactionDate  :=
                GetImputationDate(pCashFlowAnalysisId
                                , vThirdId
                                , vLogDocuments(vDocCounter).FINAL_DELAY_VALUE
                                , vLogDocuments(vDocCounter).sign
                                , vPaymentCondition
                                 );
              vPeriodId         := ACS_FUNCTION.GetPeriodID(trunc(vTransactionDate), '2');

              /**
              * Création des position de trésorerie pour les périodes de gestion existantes
              * avec la date de transaction comprise dans l'intervalle donné ou date indifférente si outes les dates demandées
              **/
              if     (    (pAllDates = 1)
                      or (trunc(vTransactionDate) between trunc(pStartDate) and trunc(pEndDate) ) )
                 and vPeriodId is not null then
                vTaxFinAccId    := null;

                select max(TAX.ACS_PREA_ACCOUNT_ID)
                  into vTaxFinAccId
                  from ACS_ACCOUNT ACC_TAX
                     , ACS_TAX_CODE TAX
                 where ACC_TAX.ACC_NUMBER = vLogDocuments(vDocCounter).ACC_NUMBER_TAX
                   and TAX.ACS_TAX_CODE_ID = ACC_TAX.ACS_ACCOUNT_ID;

                vSubSetId       := null;

                if vLogDocuments(vDocCounter).C_SUB_SET = 'REC' then
                  select max(ACC.ACS_SUB_SET_ID)
                    into vSubSetId
                    from ACS_ACCOUNT ACC
                       , PAC_CUSTOM_PARTNER CUS
                   where CUS.PAC_CUSTOM_PARTNER_ID = vThirdId
                     and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID;
                elsif vLogDocuments(vDocCounter).C_SUB_SET = 'PAY' then
                  select max(ACC.ACS_SUB_SET_ID)
                    into vSubSetId
                    from ACS_ACCOUNT ACC
                       , PAC_SUPPLIER_PARTNER SUP
                   where SUP.PAC_SUPPLIER_PARTNER_ID = vThirdId
                     and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID;
                end if;

                if vFinAccId is not null then
                  vDivAccId  := ACS_FUNCTION.GetDivisionOfAccount(vFinAccId, vDivAccId, vTransactionDate);
                else
                  vDivAccId  := null;
                end if;

                if trunc(vTransactionDate) between trunc(pStartDate) and trunc(pEndDate) then
                  if vLogDocuments(vDocCounter).DOC_SOURCE = 'S' then
                    vCashFlowImpTyp  := 'PED';
                    vQuantity        := vLogDocuments(vDocCounter).QUANTITY;
                  else
                    vCashFlowImpTyp  := 'POD';
                    vQuantity        := vLogDocuments(vDocCounter).QUANTITY;
                  end if;
                else
                  if vLogDocuments(vDocCounter).DOC_SOURCE = 'S' then
                    vCashFlowImpTyp  := 'PER';
                    vQuantity        := vLogDocuments(vDocCounter).QUANTITY;
                  else
                    vCashFlowImpTyp  := 'POR';
                    vQuantity        := vLogDocuments(vDocCounter).QUANTITY;
                  end if;
                end if;

                /**
                * Calcul des montants en arrondi logistique (2)
                **/
                if (vLogDocuments(vDocCounter).SUM_RATIO = 0) then
                  -- Si la somme des ratio = 0 on as une division par 0, on met la totalité du montant sur les positions avec un montant <> 0.
                  -- Résout le cas (erroné, REEL) ou on as toutes les positions avec un ratio à 0 mais qu'une des positions à un montant <> 0.
                  if (nvl(vLogDocuments(vDocCounter).POI_AMOUNT, 0) <> 0) then
                    vRatio := 1;
                  else
                    vRatio := 0;
                  end if;
                else
                  vRatio := (vLogDocuments(vDocCounter).POI_RATIO / vLogDocuments(vDocCounter).SUM_RATIO);
                end if;

                vAmountLCC      := 0;
                vAmountLCD      :=
                  ACS_FUNCTION.RoundAmount(vQuantity *
                                           vLogDocuments(vDocCounter).POS_NET_UNIT_VALUE_LC *
                                           vLogDocuments(vDocCounter).sign *
                                           (vPaymentCondition.CDE_ACCOUNT / vPaymentCondition.TOT_ACCOUNT
                                           ) *
                                           vRatio
                                         , vLCurrId
                                         , 2
                                          );
                vAmountFCC      := 0;
                vAmountFCD      :=
                  ACS_FUNCTION.RoundAmount(vQuantity *
                                           vLogDocuments(vDocCounter).POS_NET_UNIT_VALUE_FC *
                                           vLogDocuments(vDocCounter).sign *
                                           (vPaymentCondition.CDE_ACCOUNT / vPaymentCondition.TOT_ACCOUNT
                                           ) *
                                           vRatio
                                         , vFCurrId
                                         , 2
                                          );

                if vLCurrId = LocalCurrencyId then
                  if vAmountLCD < 0 then
                    vAmountLCC  := abs(vAmountLCD);
                    vAmountLCD  := 0;
                  end if;

                  if (vAmountFCD < 0) then
                    vAmountFCC  := abs(vAmountFCD);
                    vAmountFCD  := 0;
                  end if;
                elsif vFCurrId = LocalCurrencyId then
                  if vAmountLCD < 0 then
                    vAmountFCC  := abs(vAmountLCD);
                    vAmountFCD  := 0;
                  else
                    vAmountFCC  := 0;
                    vAmountFCD  := abs(vAmountLCD);
                  end if;

                  if vAmountFCD < 0 then
                    vAmountLCC  := abs(vAmountFCD);
                    vAmountLCD  := 0;
                  else
                    vAmountLCC  := 0;
                    vAmountLCD  := abs(vAmountFCD);
                  end if;
                end if;

                vCashFlowImpId  :=
                  AddAnalysisImputation(pCashFlowAnalysisId   --Analyse trésorerie parente
                                       , vFinAccId   --Compte financier
                                       , vDivAccId   --Compte division
                                       , null   --Type de cumul
                                       , null   --Etat journal
                                       , vCashFlowImpTyp   --Type mouvement trésorerie
                                       , vAmountLCD   --Montant LCD
                                       , vAmountLCC   --Montant LCC
                                       , vAmountFCD   --Montant FCD
                                       , vAmountFCC   --Montant FCC
                                       , vFCurrId   --Monnaie étrangère
                                       , vLCurrId   --Monnaie de base
                                       , vTransactionDate   --Date mouvement
                                       , vSubSetId   --Sous-ensemble
                                       , vGaugeId   --Gabarit document structuré
                                       , null   --Document comptable
                                       , vLogDocuments(vDocCounter).DOC_DOCUMENT_ID   --Document logistique
                                       , vThirdId   --Partenaire
                                       , vRecordId   --Dossier
                                       , vLogDocuments(vDocCounter).COM_NAME_DOC   --Mandat document logistique
                                        );

                /**
                * Différence entre valeur unitaire nette ht et valeur unitaire nette ttc
                * implique un montant TVA --> Création d'une imputation TVA
                **/
                if vLogDocuments(vDocCounter).POS_NET_UNIT_VALUE_LC <>
                                                                   vLogDocuments(vDocCounter).POS_NET_UNIT_VALUE_INCL_LC then
                  if vTaxFinAccId is not null then
                    vDivAccId  := ACS_FUNCTION.GetDivisionOfAccount(vTaxFinAccId, null, vTransactionDate);
                  else
                    vDivAccId  := null;
                  end if;

                  /**
                  * Calcul des montants en arrondi logistique (2)
                  **/
                  vAmountLCC      := 0;
                  vAmountLCD      :=
                    ACS_FUNCTION.RoundAmount(vQuantity *
                                             (vLogDocuments(vDocCounter).POS_NET_UNIT_VALUE_INCL_LC -
                                              vLogDocuments(vDocCounter).POS_NET_UNIT_VALUE_LC
                                             ) *
                                             vLogDocuments(vDocCounter).sign *
                                             (vPaymentCondition.CDE_ACCOUNT / vPaymentCondition.TOT_ACCOUNT
                                             ) *
                                             vRatio
                                           , vLCurrId
                                           , 2
                                            );
                  vAmountFCC      := 0;
                  vAmountFCD      :=
                    ACS_FUNCTION.RoundAmount(vQuantity *
                                             (vLogDocuments(vDocCounter).POS_NET_UNIT_VALUE_INCL_FC -
                                              vLogDocuments(vDocCounter).POS_NET_UNIT_VALUE_FC
                                             ) *
                                             vLogDocuments(vDocCounter).sign *
                                             (vPaymentCondition.CDE_ACCOUNT / vPaymentCondition.TOT_ACCOUNT
                                             ) *
                                             vRatio
                                           , vFCurrId
                                           , 2
                                            );

                  if vLCurrId = LocalCurrencyId then
                    if vAmountLCD < 0 then
                      vAmountLCC  := abs(vAmountLCD);
                      vAmountLCD  := 0;
                    end if;

                    if (vAmountFCD < 0) then
                      vAmountFCC  := abs(vAmountFCD);
                      vAmountFCD  := 0;
                    end if;
                  elsif vFCurrId = LocalCurrencyId then
                    if vAmountLCD < 0 then
                      vAmountFCC  := abs(vAmountLCD);
                      vAmountFCD  := 0;
                    else
                      vAmountFCC  := 0;
                      vAmountFCD  := abs(vAmountLCD);
                    end if;

                    if vAmountFCD < 0 then
                      vAmountLCC  := abs(vAmountFCD);
                      vAmountLCD  := 0;
                    else
                      vAmountLCC  := 0;
                      vAmountLCD  := abs(vAmountFCD);
                    end if;
                  end if;

                  vCashFlowImpId  :=
                    AddAnalysisImputation(pCashFlowAnalysisId   --Analyse trésorerie parente
                                         , vTaxFinAccId   --Compte financier
                                         , vDivAccId   --Compte division
                                         , null   --Type de cumul
                                         , null   --Etat journal
                                         , vCashFlowImpTyp   --Type mouvement trésorerie
                                         , vAmountLCD   --Montant LCD
                                         , vAmountLCC   --Montant LCC
                                         , vAmountFCD   --Montant FCD
                                         , vAmountFCC   --Montant FCC
                                         , vFCurrId   --Monnaie étrangère
                                         , vLCurrId   --Monnaie de base
                                         , vTransactionDate   --Date mouvement
                                         , vSubSetId   --Sous-ensemble
                                         , vGaugeId   --Gabarit document structuré
                                         , null   --Document comptable
                                         , vLogDocuments(vDocCounter).DOC_DOCUMENT_ID   --Document logistique
                                         , vThirdId   --Partenaire
                                         , vRecordId   --Dossier
                                         , vLogDocuments(vDocCounter).COM_NAME_DOC   --Mandat document logistique
                                          );
                end if;

                commit;
              end if;

              fetch PaymentConditionCursor
               into vPaymentCondition;
            end loop;

            close PaymentConditionCursor;
          end if;
        end loop;
      end if;
    end;
    end loop;
  end InsertDOCImputations;

  function AddAnalysisImputation(
    aACR_CASH_FLOW_ANALYSIS_ID ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID  ACR_CASH_FLOW_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID   ACR_CASH_FLOW_IMPUTATION.ACS_DIVISION_ACCOUNT_ID%type
  , aC_TYPE_CUMUL              ACR_CASH_FLOW_IMPUTATION.C_TYPE_CUMUL%type
  , aC_ETAT_JOURNAL            ACR_CASH_FLOW_IMPUTATION.C_ETAT_JOURNAL%type
  , aC_CASH_FLOW_IMP_TYP       ACR_CASH_FLOW_IMPUTATION.C_CASH_FLOW_IMP_TYP%type
  , aCFI_AMOUNT_LC_D           ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_D%type
  , aCFI_AMOUNT_LC_C           ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_LC_C%type
  , aCFI_AMOUNT_FC_D           ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_FC_D%type
  , aCFI_AMOUNT_FC_C           ACR_CASH_FLOW_IMPUTATION.CFI_AMOUNT_FC_C%type
  , aFC_FINANCIAL_CURRENCY_ID  ACR_CASH_FLOW_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aLC_FINANCIAL_CURRENCY_ID  ACR_CASH_FLOW_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aCFI_DATE                  ACR_CASH_FLOW_IMPUTATION.CFI_DATE%type
  , aACS_SUB_SET_ID            ACR_CASH_FLOW_IMPUTATION.ACS_SUB_SET_ID%type
  , aDOC_GAUGE_ID              ACR_CASH_FLOW_IMPUTATION.DOC_GAUGE_ID%type
  , aACT_DOCUMENT_ID           ACR_CASH_FLOW_IMPUTATION.ACT_DOCUMENT_ID%type
  , aDOC_DOCUMENT_ID           ACR_CASH_FLOW_IMPUTATION.DOC_DOCUMENT_ID%type
  , aPAC_PERSON_ID             ACR_CASH_FLOW_IMPUTATION.PAC_PERSON_ID%type
  , aDOC_RECORD_ID             ACR_CASH_FLOW_IMPUTATION.DOC_RECORD_ID%type
  , aComNameDoc                ACR_CASH_FLOW_IMPUTATION.COM_NAME_DOC%type
  )
    return ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type
  is
    vCashFlowImpId ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_IMPUTATION_ID%type;   --Réceptionne l'id la position nouvellement créée
    vNewRecord     boolean                                                     default false;   --Indique si nouvel enregistrement ou déjà existant
  begin
    select INIT_ID_SEQ.NEXTVAL into vCashFlowImpId from dual;

      insert into ACR_CASH_FLOW_IMPUTATION_DET
                  (ACR_CASH_FLOW_IMPUTATION_ID
                 , ACR_CASH_FLOW_ANALYSIS_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , C_TYPE_CUMUL
                 , C_ETAT_JOURNAL
                 , C_CASH_FLOW_IMP_TYP
                 , CFI_AMOUNT_LC_D
                 , CFI_AMOUNT_LC_C
                 , CFI_AMOUNT_FC_D
                 , CFI_AMOUNT_FC_C
                 , CFI_DATE
                 , ACS_PERIOD_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , ACS_SUB_SET_ID
                 , DOC_GAUGE_ID
                 , ACT_DOCUMENT_ID
                 , DOC_DOCUMENT_ID
                 , PAC_PERSON_ID
                 , DOC_RECORD_ID
                 , COM_NAME_DOC
                  )
           values (vCashFlowImpId   --Id position
                 , aACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
                 , aACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                 , aACS_DIVISION_ACCOUNT_ID   --Compte division
                 , aC_TYPE_CUMUL   --Type de cumul
                 , aC_ETAT_JOURNAL   --Etat journal
                 , aC_CASH_FLOW_IMP_TYP   --Type mouvement trésorerie
                 , NVL(aCFI_AMOUNT_LC_D,0)   --Montant LCD
                 , NVL(aCFI_AMOUNT_LC_C,0)   --Montant LCC
                 , NVL(aCFI_AMOUNT_FC_D,0)   --Montant FCD
                 , NVL(aCFI_AMOUNT_FC_C,0)   --Montant FCC
                 , trunc(aCFI_DATE)   --Date mouvement
                 , ACS_FUNCTION.GetPeriodID(trunc(aCFI_DATE), '2')   --Période du mouvement
                 , aFC_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
                 , nvl(aLC_FINANCIAL_CURRENCY_ID, LocalCurrencyId)   --Monnaie de base
                 , aACS_SUB_SET_ID    --Sous-ensemble
                 , aDOC_GAUGE_ID      --Gabarit document structuré
                 , decode(DetailedAnalysis, 1, aACT_DOCUMENT_ID, null)   --Document comptable
                 , decode(DetailedAnalysis, 1, aDOC_DOCUMENT_ID, null)   --Document logistique
                 , decode(DetailedAnalysis, 1, aPAC_PERSON_ID, null)   --Partenaire
                 , aDOC_RECORD_ID     --Dossier
                 , aComNameDoc
                  );
    commit;
    return vCashFlowImpId;
  end AddAnalysisImputation;


  /**
  * Description Group cash flow imputations according unique key fields
  **/
  procedure GroupAnalysisImputation(aACR_CASH_FLOW_ANALYSIS_ID ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type)
  is
  begin
    insert into ACR_CASH_FLOW_IMPUTATION
                (ACR_CASH_FLOW_IMPUTATION_ID
               , ACR_CASH_FLOW_ANALYSIS_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , C_TYPE_CUMUL
               , C_ETAT_JOURNAL
               , C_CASH_FLOW_IMP_TYP
               , CFI_AMOUNT_LC_D
               , CFI_AMOUNT_LC_C
               , CFI_AMOUNT_FC_D
               , CFI_AMOUNT_FC_C
               , CFI_DATE
               , ACS_PERIOD_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , ACS_SUB_SET_ID
               , DOC_GAUGE_ID
               , ACT_DOCUMENT_ID
               , DOC_DOCUMENT_ID
               , PAC_PERSON_ID
               , DOC_RECORD_ID
               , COM_NAME_DOC
               , A_DATECRE
               , A_IDCRE
                )
      select   max(ACR_CASH_FLOW_IMPUTATION_ID)
             , ACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
             , ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
             , ACS_DIVISION_ACCOUNT_ID   --Compte division
             , C_TYPE_CUMUL   --Type de cumul
             , C_ETAT_JOURNAL   --Etat journal
             , C_CASH_FLOW_IMP_TYP   --Type mouvement trésorerie
             , sum(CFI_AMOUNT_LC_D)   --Montant LCD
             , sum(CFI_AMOUNT_LC_C)   --Montant LCC
             , sum(CFI_AMOUNT_FC_D)   --Montant FCD
             , sum(CFI_AMOUNT_FC_C)   --Montant FCC
             , CFI_DATE   --Date mouvement
             , ACS_PERIOD_ID   --Période du mouvement
             , ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
             , ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
             , ACS_SUB_SET_ID   --Sous-ensemble
             , DOC_GAUGE_ID   --Gabarit document structuré
             , ACT_DOCUMENT_ID  --Document comptable
             , DOC_DOCUMENT_ID  --Document logistique
             , PAC_PERSON_ID    --Partenaire
             , DOC_RECORD_ID    --Dossier
             , COM_NAME_DOC
             , max(sysdate)
             , max(UserIni)
          from ACR_CASH_FLOW_IMPUTATION_DET
         where ACR_CASH_FLOW_ANALYSIS_ID = aACR_CASH_FLOW_ANALYSIS_ID
      group by ACR_CASH_FLOW_ANALYSIS_ID   --Analyse trésorerie parente
             , ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
             , ACS_DIVISION_ACCOUNT_ID   --Compte division
             , ACS_FINANCIAL_CURRENCY_ID   --Monnaie étrangère
             , ACS_ACS_FINANCIAL_CURRENCY_ID   --Monnaie de base
             , CFI_DATE   --Date mouvement
             , ACS_PERIOD_ID   --Période du mouvement
             , ACS_SUB_SET_ID   --Sous-ensemble
             , DOC_GAUGE_ID   --Gabarit document structuré
             , ACT_DOCUMENT_ID   --Document comptable
             , DOC_DOCUMENT_ID   --Document logistique
             , PAC_PERSON_ID   --Partenaire
             , DOC_RECORD_ID   --Dossier
             , COM_NAME_DOC
             , C_TYPE_CUMUL   --Type de cumul
             , C_ETAT_JOURNAL   --Etat journal
             , C_CASH_FLOW_IMP_TYP   --Type mouvement trésorerie
             ;

    delete from ACR_CASH_FLOW_IMPUTATION_DET
          where ACR_CASH_FLOW_ANALYSIS_ID = aACR_CASH_FLOW_ANALYSIS_ID;
  end GroupAnalysisImputation;

  /**
  * Description  Ajout des pondérations pour la nouvelle analyse donnée
  **/
  procedure AddAnalysisSubSet(
    pCashFlowAnalysisId in     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
  , pResult             out    number
  )
  is
  begin
    begin
      /**
      * Tous les sous-ensembles auxiliaires
      **/
      insert into ACR_CF_DATE_WEIGHTING
                  (ACR_CF_DATE_WEIGHTING_ID
                 , ACR_CASH_FLOW_ANALYSIS_ID
                 , ACS_SUB_SET_ID
                 , CFW_WEIGHTING
                  )
        select INIT_ID_SEQ.nextval
             , pCashFlowAnalysisId
             , ACS_SUB_SET_ID
             , 0
          from ACS_SUB_SET
         where C_TYPE_SUB_SET = 'AUX';

      pResult  := 1;
    exception
      when others then
        pResult  := 0;
    end;
  end AddAnalysisSubSet;

  /**
  * Description  Ajout des gabarits pour la nouvelle analyse donnée
  **/
  procedure AddAnalysisGauge(
    pCashFlowAnalysisId in     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
  , pResult             out    number
  )
  is
  begin
    begin
      /**
      * Gabarits des domaines achat et ventes, qui ne sont pas en préparation
      * Les gabarit par défaut son séléectionnés par défaut (CGS_SELECTED = 1)
      **/
      insert into ACR_CASH_GAS_SELECTED
                  (ACR_CASH_GAS_SELECTED_ID
                 , ACR_CASH_FLOW_ANALYSIS_ID
                 , DOC_GAUGE_ID
                 , CGS_SELECTED
                  )
        select INIT_ID_SEQ.nextval
             , pCashFlowAnalysisId
             , GAS.DOC_GAUGE_ID
             , decode(DEF.DOC_GAUGE_ID, null, 0, 1)
          from ACR_CASH_GAS_DEFAULT DEF
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE GAU
         where GAU.C_ADMIN_DOMAIN in('1', '2')
           and GAU.C_GAUGE_STATUS <> '1'
           and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
           and GAU.DOC_GAUGE_ID = DEF.DOC_GAUGE_ID(+);

      pResult  := 1;
    exception
      when others then
        pResult  := 0;
    end;
  end AddAnalysisGauge;

  /**
  * Description  Ajout des périodes décomptées
  **/
  procedure AddDeductedPeriod(
    pCashFlowAnalysisId in     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
  , pResult             out    number
  )
  is
  begin
    begin
      /**
      * Toutes les périodes HRM
      **/
      insert into ACR_DEDUCTED_PERIOD
                  (ACR_DEDUCTED_PERIOD_ID
                 , ACR_CASH_FLOW_ANALYSIS_ID
                 , HRM_PERIOD_ID
                 , DEP_SELECTED
                  )
        select INIT_ID_SEQ.nextval
             , pCashFlowAnalysisId
             , HRM_PERIOD_ID
             , 0
          from HRM_PERIOD;

      pResult  := 1;
    exception
      when others then
        pResult  := 0;
    end;
  end AddDeductedPeriod;

  /**
  * Description Ajout des sociétés sélectionnées liées à l'analyse donnée
  **/
  procedure AddAnalysisComp(
    pCashFlowAnalysisId in     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
  , pResult             out    number
  )
  is
  begin
    begin
      --Ajout de la société active en tous les cas
      insert into ACR_CASH_COMP_SELECTED
                  (ACR_CASH_COMP_SELECTED_ID
                 , PC_COMP_ID
                 , ACR_CASH_FLOW_ANALYSIS_ID
                 , CCS_DOC_SELECTED
                  )
        select INIT_ID_SEQ.nextval
             , COM.PC_COMP_ID
             , pCashFlowAnalysisId
             , case
                 when COM.PC_COMP_ID = pcs.PC_I_LIB_SESSION.GetCompanyId then 1
                 else case
                 when CCD.PC_COMP_ID is null then 0
                 else 1
               end
               end
          from ACR_CASH_COMP_DEFAULT CCD
             , PCS.PC_COMP COM
         where COM.PC_COMP_ID = CCD.PC_COMP_ID(+);

      pResult  := 1;
    exception
      when others then
        pResult  := 0;
    end;
  end AddAnalysisComp;

  /**
  * Description  Calcule, pour un partenaire donné, le coefficient de variation entre le délai de paiement accordé et le règlement effectif
  */
  function PartnerPaymentFactor(
    aPAC_THIRD_ID PAC_THIRD.PAC_THIRD_ID%type
  , aPartnerType  varchar2
  , aDays         number
  , aFactorType   number
  )
    return PAC_CUSTOM_PARTNER.CUS_PAYMENT_FACTOR%type
  is
    Factor PAC_CUSTOM_PARTNER.CUS_PAYMENT_FACTOR%type ;
-----
  begin
    begin
      if aPartnerType = 'C' then   -- Partenaire client
        if aFactorType = 1 then   -- Prise en compte des montants des document (échéance)
          if aDays > 0 then
            select nvl(sum( (EXP.EXP_DATE_PMT_TOT - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC) /
                       case nvl(sum( (EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC), 0)
                         when 0 then 1
                         else sum( (EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC)
                       end
                     , 0
                      )
              into Factor
              from ACT_EXPIRY EXP
                 , ACT_FINANCIAL_IMPUTATION IMP
                 , ACJ_CATALOGUE_DOCUMENT CAT
                 , ACT_DOCUMENT DOC
             where EXP.EXP_PAC_CUSTOM_PARTNER_ID = aPAC_THIRD_ID
               and EXP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
               and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and IMP.IMF_PRIMARY = 1
               and trunc(IMF_VALUE_DATE) between trunc(sysdate - aDays) and trunc(sysdate)
               and EXP.EXP_CALC_NET = 1
               and to_number(EXP.C_STATUS_EXPIRY) = 1
               and EXP.EXP_AMOUNT_LC > 0
               and CAT.C_TYPE_CATALOGUE in('2');
          else
            select nvl(sum( (EXP.EXP_DATE_PMT_TOT - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC) /
                       case nvl(sum( (EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC), 0)
                         when 0 then 1
                         else sum( (EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC)
                       end
                     , 0
                      )
              into Factor
              from ACT_EXPIRY EXP
                 , ACT_FINANCIAL_IMPUTATION IMP
                 , ACJ_CATALOGUE_DOCUMENT CAT
                 , ACT_DOCUMENT DOC
             where EXP.EXP_PAC_CUSTOM_PARTNER_ID = aPAC_THIRD_ID
               and EXP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
               and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and IMP.IMF_PRIMARY = 1
               and EXP.EXP_CALC_NET = 1
               and to_number(EXP.C_STATUS_EXPIRY) = 1
               and EXP.EXP_AMOUNT_LC > 0
               and CAT.C_TYPE_CATALOGUE in('2');
          end if;
        else
          -- Non prise en compte des montant des document (échéance)
          if aDays > 0 then
            select nvl(sum(EXP.EXP_DATE_PMT_TOT - IMP.IMF_VALUE_DATE) /
                       case nvl(sum(EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE), 0)
                         when 0 then 1
                         else sum(EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE)
                       end
                     , 0
                      )
              into Factor
              from ACT_EXPIRY EXP
                 , ACT_FINANCIAL_IMPUTATION IMP
                 , ACJ_CATALOGUE_DOCUMENT CAT
                 , ACT_DOCUMENT DOC
             where EXP.EXP_PAC_CUSTOM_PARTNER_ID = aPAC_THIRD_ID
               and EXP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
               and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and IMP.IMF_PRIMARY = 1
               and trunc(IMF_VALUE_DATE) between trunc(sysdate - aDays) and trunc(sysdate)
               and EXP.EXP_CALC_NET = 1
               and to_number(EXP.C_STATUS_EXPIRY) = 1
               and EXP.EXP_AMOUNT_LC > 0
               and CAT.C_TYPE_CATALOGUE in('2');
          else
            select nvl(sum(EXP.EXP_DATE_PMT_TOT - IMP.IMF_VALUE_DATE) /
                       case nvl(sum(EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE), 0)
                         when 0 then 1
                         else sum(EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE)
                       end
                     , 0
                      )
              into Factor
              from ACT_EXPIRY EXP
                 , ACT_FINANCIAL_IMPUTATION IMP
                 , ACJ_CATALOGUE_DOCUMENT CAT
                 , ACT_DOCUMENT DOC
             where EXP.EXP_PAC_CUSTOM_PARTNER_ID = aPAC_THIRD_ID
               and EXP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
               and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and IMP.IMF_PRIMARY = 1
               and EXP.EXP_CALC_NET = 1
               and to_number(EXP.C_STATUS_EXPIRY) = 1
               and EXP.EXP_AMOUNT_LC > 0
               and CAT.C_TYPE_CATALOGUE in('2');
          end if;
        end if;
      else
        -- Partenaire fournisseur
        if aFactorType = 1 then
          -- Prise en compte des montant des document (échéance)
          if aDays > 0 then
            select nvl(sum( (EXP.EXP_DATE_PMT_TOT - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC) /
                       case nvl(sum( (EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC), 0)
                         when 0 then 1
                         else sum( (EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC)
                       end
                     , 0
                      )
              into Factor
              from ACT_EXPIRY EXP
                 , ACT_FINANCIAL_IMPUTATION IMP
                 , ACJ_CATALOGUE_DOCUMENT CAT
                 , ACT_DOCUMENT DOC
             where EXP.EXP_PAC_SUPPLIER_PARTNER_ID = aPAC_THIRD_ID
               and EXP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
               and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and IMP.IMF_PRIMARY = 1
               and trunc(IMF_VALUE_DATE) between trunc(sysdate - aDays) and trunc(sysdate)
               and EXP.EXP_CALC_NET = 1
               and to_number(EXP.C_STATUS_EXPIRY) = 1
               and EXP.EXP_AMOUNT_LC > 0
               and CAT.C_TYPE_CATALOGUE in('2');
          else
            select nvl(sum( (EXP.EXP_DATE_PMT_TOT - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC) /
                       case nvl(sum( (EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC), 0)
                         when 0 then 1
                         else sum( (EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE) * EXP_AMOUNT_LC)
                       end
                     , 0
                      )
              into Factor
              from ACT_EXPIRY EXP
                 , ACT_FINANCIAL_IMPUTATION IMP
                 , ACJ_CATALOGUE_DOCUMENT CAT
                 , ACT_DOCUMENT DOC
             where EXP.EXP_PAC_SUPPLIER_PARTNER_ID = aPAC_THIRD_ID
               and EXP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
               and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and IMP.IMF_PRIMARY = 1
               and EXP.EXP_CALC_NET = 1
               and to_number(EXP.C_STATUS_EXPIRY) = 1
               and EXP.EXP_AMOUNT_LC > 0
               and CAT.C_TYPE_CATALOGUE in('2');
          end if;
        else
          -- Non prise en compte des montant des document (échéance)
          if aDays > 0 then
            select nvl(sum(EXP.EXP_DATE_PMT_TOT - IMP.IMF_VALUE_DATE) /
                       case nvl(sum(EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE), 0)
                         when 0 then 1
                         else sum(EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE)
                       end
                     , 0
                      )
              into Factor
              from ACT_EXPIRY EXP
                 , ACT_FINANCIAL_IMPUTATION IMP
                 , ACJ_CATALOGUE_DOCUMENT CAT
                 , ACT_DOCUMENT DOC
             where EXP.EXP_PAC_SUPPLIER_PARTNER_ID = aPAC_THIRD_ID
               and EXP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
               and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and IMP.IMF_PRIMARY = 1
               and trunc(IMF_VALUE_DATE) between trunc(sysdate - aDays) and trunc(sysdate)
               and EXP.EXP_CALC_NET = 1
               and to_number(EXP.C_STATUS_EXPIRY) = 1
               and EXP.EXP_AMOUNT_LC > 0
               and CAT.C_TYPE_CATALOGUE in('2');
          else
            select nvl(sum(EXP.EXP_DATE_PMT_TOT - IMP.IMF_VALUE_DATE) /
                       case nvl(sum(EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE), 0)
                         when 0 then 1
                         else sum(EXP.EXP_ADAPTED - IMP.IMF_VALUE_DATE)
                       end
                     , 0
                      )
              into Factor
              from ACT_EXPIRY EXP
                 , ACT_FINANCIAL_IMPUTATION IMP
                 , ACJ_CATALOGUE_DOCUMENT CAT
                 , ACT_DOCUMENT DOC
             where EXP.EXP_PAC_SUPPLIER_PARTNER_ID = aPAC_THIRD_ID
               and EXP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
               and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and IMP.IMF_PRIMARY = 1
               and EXP.EXP_CALC_NET = 1
               and to_number(EXP.C_STATUS_EXPIRY) = 1
               and EXP.EXP_AMOUNT_LC > 0
               and CAT.C_TYPE_CATALOGUE in('2');
          end if;
        end if;
      end if;
    exception
      when others then
        Factor  := 0;
    end;

    return round(Factor, 2);
  end PartnerPaymentFactor;

---------------------------

  ---------------------------
  procedure AddAnalysisPeriod(
    aACR_CASH_FLOW_ANALYSIS_ID in     ACR_CASH_FLOW_IMPUTATION.ACR_CASH_FLOW_ANALYSIS_ID%type
  , aACS_PERIOD_ID1            in     ACS_PERIOD.ACS_PERIOD_ID%type
  , aACS_PERIOD_ID2            in     ACS_PERIOD.ACS_PERIOD_ID%type
  , aResult                    out    number
  )
  is
  begin
    begin
      --Suppression des périodes d'analyses existantes
      delete from ACR_ANALYSIS_PERIOD
            where ACR_CASH_FLOW_ANALYSIS_ID = aACR_CASH_FLOW_ANALYSIS_ID;

      --Ajout des nouvelles périodes d'analyse
      insert into ACR_ANALYSIS_PERIOD
                  (ACR_ANALYSIS_PERIOD_ID
                 , ACR_CASH_FLOW_ANALYSIS_ID
                 , ANP_DATE
                 , ACS_PERIOD_ID
                  )
        select INIT_ID_SEQ.nextval
             , aACR_CASH_FLOW_ANALYSIS_ID
             , nvl(DAT.CHD_DATE, PER.PER_END_DATE)
             , PER.ACS_PERIOD_ID
          from (select DAT.CHD_DATE
                     , PER.ACS_PERIOD_ID
                  from ACR_CASH_HRM_DATE DAT
                     , ACS_PERIOD PER
                 where trunc(DAT.CHD_DATE) between trunc(PER.PER_START_DATE) and trunc(PER.PER_END_DATE) ) DAT
             , ACS_PERIOD PER
         where PER.ACS_PERIOD_ID in(
                 select ACS_PERIOD_ID
                   from ACS_PERIOD
                  where trunc(PER.PER_START_DATE) >= (select trunc(PER_START_DATE)
                                                        from ACS_PERIOD
                                                       where ACS_PERIOD_ID = aACS_PERIOD_ID1)
                    and trunc(PER.PER_END_DATE) <= (select trunc(PER_END_DATE)
                                                      from ACS_PERIOD
                                                     where ACS_PERIOD_ID = aACS_PERIOD_ID2) )
           and PER.ACS_PERIOD_ID = DAT.ACS_PERIOD_ID(+)
           and PER.C_TYPE_PERIOD = '2';

      aResult  := 1;
    exception
      when others then
        aResult  := 0;
    end;
  end AddAnalysisPeriod;


  /**
  * Description Return record linked to the given imputation
  **/
  function GetMgmImputationRecordId(aFinImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
    return ACT_MGM_IMPUTATION.DOC_RECORD_ID%type
  is
    cursor crMgmImputationCursor(aFinImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
    is
      select   DOC_RECORD_ID
          from ACT_MGM_IMPUTATION
         where ACT_FINANCIAL_IMPUTATION_ID = aFinImputationId
      order by IMM_AMOUNT_LC_D desc;

    MgmImputationsOfDocument crMgmImputationCursor%rowtype;
    vResult                  ACT_MGM_IMPUTATION.DOC_RECORD_ID%type;
  begin
    vResult  := null;

    open crMgmImputationCursor(aFinImputationId);

    fetch crMgmImputationCursor
     into MgmImputationsOfDocument;

    if crMgmImputationCursor%found then
      vResult  := MgmImputationsOfDocument.DOC_RECORD_ID;
    end if;

    close crMgmImputationCursor;

    return vResult;
  end GetMgmImputationRecordId;


-- Initialisation des variables pour la session
-----
begin
  UserIni          := PCS.PC_I_LIB_SESSION.GetUserIni;
  LocalCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
end ACR_CASH_FLOW_MANAGEMENT;
