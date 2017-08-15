--------------------------------------------------------
--  DDL for Package Body ACT_MGM_TOTAL_BY_PERIOD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_MGM_TOTAL_BY_PERIOD" 
is
  /**
  * Description
  *   Mise à jour ACT_MGM_IMPUTATION
  *   Le Cpte financier est récupéré grâce à ACT_FINANCIAL_IMPUTATION_ID
  */
  procedure MgmTotalImputation(
    aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aACS_PERIOD_ID               ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_CPN_ACCOUNT_ID          ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type
  , aACS_CDA_ACCOUNT_ID          ACT_MGM_IMPUTATION.ACS_CDA_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT_ID           ACT_MGM_IMPUTATION.ACS_PF_ACCOUNT_ID%type
  , aACS_QTY_UNIT_ID             ACT_MGM_IMPUTATION.ACS_QTY_UNIT_ID%type
  , aACS_PJ_ACCOUNT_ID           ACT_MGM_DISTRIBUTION.ACS_PJ_ACCOUNT_ID%type
  , aDOC_RECORD_ID               ACT_MGM_IMPUTATION.DOC_RECORD_ID%type
  , aIMM_AMOUNT_LC_D             ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type
  , aIMM_AMOUNT_LC_C             ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type
  , aIMM_AMOUNT_FC_D             ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type
  , aIMM_AMOUNT_FC_C             ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type
  , aIMM_AMOUNT_EUR_D            ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type
  , aIMM_AMOUNT_EUR_C            ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type
  , aIMM_QUANTITY_D              ACT_MGM_IMPUTATION.IMM_QUANTITY_D%type
  , aIMM_QUANTITY_C              ACT_MGM_IMPUTATION.IMM_QUANTITY_C%type
  , aManyImputations             number
  )
  is
    EtatJournal        ACT_ETAT_JOURNAL.C_ETAT_JOURNAL%type;
    TypeCumul          ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type;
    MethodCumul        ACJ_SUB_SET_CAT.C_METHOD_CUMUL%type;
    SubSetMethodCumul  ACJ_SUB_SET_CAT.C_METHOD_CUMUL%type;
    FinancialAccountId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    DivisionAccountId  ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    ForeignCurrency    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    TypeCatalogue      ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;

    -- Ramène le type de cumul pour un document et le sous-ensemble CPN -> PRI/SEC/SIM
    -- En fait Transaction du document et Type de sous-ensemble du compte
    cursor TypeCumulCursor(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select SCA.C_TYPE_CUMUL
           , SCA.C_METHOD_CUMUL
        from ACJ_SUB_SET_CAT SCA
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
       where SCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and SCA.C_SUB_SET = 'CPN'
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    -- Ramène l'état du journal pour un document et un Type de sous-ensemble donné -> BRO/PROV/DEF
    -- Ne fonctionne pas du fait que ACT_ACT_JOURNAL_ID n'est pas à jour !!!
    cursor EtatJournalCursor(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select ETA.C_ETAT_JOURNAL
        from ACT_DOCUMENT DOC
           , ACT_ETAT_JOURNAL ETA
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DOC.ACT_ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
         and ETA.C_SUB_SET = 'CPN';
  begin
    select C_TYPE_CATALOGUE
      into TypeCatalogue
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_DOCUMENT DOC
     where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID;

    /** Le document n'est pas de type "Report" **/
    if TypeCatalogue <> '7' then
      -- Recherche Type cumul
      open TypeCumulCursor(aACT_DOCUMENT_ID);

      fetch TypeCumulCursor
       into TypeCumul
          , SubSetMethodCumul;

      close TypeCumulCursor;

      if aManyImputations <> 0 then   -- Passage du journal de BRO à PROV/DEF (ou l'inverse)
        MethodCumul  := 'DIR';
      else
        -- Ne fonctionne pas du fait que ACT_ACT_JOURNAL_ID n'est pas à jour !!!
        -- Retourne systématiquement null
        open EtatJournalCursor(aACT_DOCUMENT_ID);

        fetch EtatJournalCursor
         into EtatJournal;

        close EtatJournalCursor;

        -- On récupère la méthode de cumul définie pour le sous-ensemble CPN pour la transaction courante
        -- Attention ! Si la méthode de cumul a été changée !
        if EtatJournal is null then
          MethodCumul  := SubSetMethodCumul;
        else
          if EtatJournal = 'BRO' then
            MethodCumul  := 'DEF';
          else
            MethodCumul  := 'DIR';
          end if;
        end if;
      end if;

      if     MethodCumul = 'DIR'
         and (not TypeCumul is null) then
        -- Recherche ID Compte financier
        begin
          select ACS_FINANCIAL_ACCOUNT_ID, IMF_ACS_DIVISION_ACCOUNT_ID
            into FinancialAccountId, DivisionAccountId
            from ACT_FINANCIAL_IMPUTATION
           where ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;
        exception
          when no_data_found then
            FinancialAccountId  := null;
            DivisionAccountId   := null;
        end;

        MgmPeriodsWrite(TypeCumul
                      , aACS_PERIOD_ID
                      , aACS_FINANCIAL_CURRENCY_ID
                      , aF_ACS_FINANCIAL_CURRENCY_ID
                      , aACS_CPN_ACCOUNT_ID
                      , aACS_CDA_ACCOUNT_ID
                      , aACS_PF_ACCOUNT_ID
                      , aACS_QTY_UNIT_ID
                      , aACS_PJ_ACCOUNT_ID
                      , FinancialAccountId
                      , DivisionAccountId
                      , aDOC_RECORD_ID
                      , aManyImputations * aIMM_AMOUNT_LC_D
                      , aManyImputations * aIMM_AMOUNT_LC_C
                      , aManyImputations * aIMM_AMOUNT_FC_D
                      , aManyImputations * aIMM_AMOUNT_FC_C
                      , aManyImputations * aIMM_AMOUNT_EUR_D
                      , aManyImputations * aIMM_AMOUNT_EUR_C
                      , aManyImputations * aIMM_QUANTITY_D
                      , aManyImputations * aIMM_QUANTITY_C
                       );
      end if;
    end if;
  end MgmTotalImputation;

  /**
  * Description
  *   Vérification gestion cumul (O/N) -> en fct du CPN et CDA/PF/PJ
  *   Vérification monnaie FC autorisée (O/N), sinon LC
  *   Gestion des reports sur les exercices actifs suivants, si Cpte fin. Bilan ou Projet Ok
  */
  procedure MgmPeriodsWrite(
    aC_TYPE_CUMUL                ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , aACS_PERIOD_ID               ACT_MGM_TOT_BY_PERIOD.ACS_PERIOD_ID%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_TOT_BY_PERIOD.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_CPN_ACCOUNT_ID          ACT_MGM_TOT_BY_PERIOD.ACS_CPN_ACCOUNT_ID%type
  , aACS_CDA_ACCOUNT_ID          ACT_MGM_TOT_BY_PERIOD.ACS_CDA_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT_ID           ACT_MGM_TOT_BY_PERIOD.ACS_PF_ACCOUNT_ID%type
  , aACS_QTY_UNIT_ID             ACT_MGM_TOT_BY_PERIOD.ACS_QTY_UNIT_ID%type
  , aACS_PJ_ACCOUNT_ID           ACT_MGM_TOT_BY_PERIOD.ACS_PJ_ACCOUNT_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID    ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID     ACT_MGM_TOT_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
  , aDOC_RECORD_ID               ACT_MGM_TOT_BY_PERIOD.DOC_RECORD_ID%type
  , aIMM_AMOUNT_LC_D             ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type
  , aIMM_AMOUNT_LC_C             ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_LC%type
  , aIMM_AMOUNT_FC_D             ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_FC%type
  , aIMM_AMOUNT_FC_C             ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_FC%type
  , aIMM_AMOUNT_EUR_D            ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_EUR%type
  , aIMM_AMOUNT_EUR_C            ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_EUR%type
  , aIMM_QUANTITY_D              ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_D%type
  , aIMM_QUANTITY_C              ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_C%type
  )
  is
    -- Vérifie la validité des monnaies pour les comptes de type CPN
    cursor CPNCurrencyCursor(
      aACS_CPN_ACCOUNT_ID        ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
    , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
    )
    is
      select ACS_FINANCIAL_CURRENCY_ID
        from ACS_CPN_ACCOUNT_CURRENCY
       where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
         and ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;

    -- Recherche des périodes de report des exercices suivants actifs
    cursor CURSOR_NEXT_PERIOD(YEAR_EXERCICE number)
    is
      select ACS_PERIOD_ID
        from ACS_FINANCIAL_YEAR Y
           , ACS_PERIOD P
       where Y.ACS_FINANCIAL_YEAR_ID = P.ACS_FINANCIAL_YEAR_ID
         and Y.C_STATE_FINANCIAL_YEAR = 'ACT'
         and Y.FYE_NO_EXERCICE > YEAR_EXERCICE
         and P.C_TYPE_PERIOD = '1';

    BaseCurrencyId    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    ForeignCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    NoExercice        ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;
    NextPeriodId      ACS_PERIOD.ACS_PERIOD_ID%type;
    CumulOk           number(1);
    lbPJReportMgt     number(1);
    ln_CpnReportMgt  number(1) default 0;
  begin
    if aACS_PERIOD_ID is not null then
      CumulOk  := CumulManagement(aACS_CPN_ACCOUNT_ID, aACS_CDA_ACCOUNT_ID, aACS_PF_ACCOUNT_ID, aACS_PJ_ACCOUNT_ID);

      if (CumulOk = 1) then
        -- Teste si la monnaie est autorisée pour le CPN
        if aACS_FINANCIAL_CURRENCY_ID <> aF_ACS_FINANCIAL_CURRENCY_ID then
          BaseCurrencyId  := ACS_FUNCTION.GetLocalCurrencyID;

          open CPNCurrencyCursor(aACS_CPN_ACCOUNT_ID, aACS_FINANCIAL_CURRENCY_ID);

          fetch CPNCurrencyCursor
           into ForeignCurrencyId;

          close CPNCurrencyCursor;

          if ForeignCurrencyId is null then
            ForeignCurrencyId  := BaseCurrencyId;
          end if;
        else
          ForeignCurrencyId  := aACS_FINANCIAL_CURRENCY_ID;
        end if;

        MgmTotalWrite(aC_TYPE_CUMUL
                    , aACS_PERIOD_ID
                    , ForeignCurrencyId
                    , aF_ACS_FINANCIAL_CURRENCY_ID
                    , aACS_CPN_ACCOUNT_ID
                    , aACS_CDA_ACCOUNT_ID
                    , aACS_PF_ACCOUNT_ID
                    , aACS_QTY_UNIT_ID
                    , aACS_PJ_ACCOUNT_ID
                    , aACS_FINANCIAL_ACCOUNT_ID
                    , aACS_DIVISION_ACCOUNT_ID
                    , aDOC_RECORD_ID
                    , aIMM_AMOUNT_LC_D
                    , aIMM_AMOUNT_LC_C
                    , aIMM_AMOUNT_FC_D
                    , aIMM_AMOUNT_FC_C
                    , aIMM_AMOUNT_EUR_D
                    , aIMM_AMOUNT_EUR_C
                    , aIMM_QUANTITY_D
                    , aIMM_QUANTITY_C
                     );

        -- Cumul sur les exercices suivants...
        -- ...Le compte PJ gère les cumuls...
        -- ...Le compte CPN est lié à un compte financier de type Bilan...
        -- ...Le dossier est renseigné...
        lbPJReportMgt := ReportManagement(aACS_FINANCIAL_ACCOUNT_ID, aACS_PJ_ACCOUNT_ID);
        ln_CpnReportMgt := CpnReportManagement(aACS_CPN_ACCOUNT_ID);
        if ( (lbPJReportMgt = 1) or ( aDOC_RECORD_ID is not null) or (ln_CpnReportMgt = 1))
           and ACT_EVOLUTION.ReportManagementOfTypeCumul(aC_TYPE_CUMUL) = 1 then

          -- Recherche de l'exercice comptable courant
          select FYE_NO_EXERCICE
            into NoExercice
            from ACS_FINANCIAL_YEAR YEA
               , ACS_PERIOD PER
           where YEA.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
             and PER.ACS_PERIOD_ID = aACS_PERIOD_ID;

          open CURSOR_NEXT_PERIOD(NoExercice);

          fetch CURSOR_NEXT_PERIOD
           into NextPeriodId;

          while CURSOR_NEXT_PERIOD%found loop
            MgmTotalWrite(aC_TYPE_CUMUL
                        , NextPeriodId
                        , ForeignCurrencyId
                        , aF_ACS_FINANCIAL_CURRENCY_ID
                        , aACS_CPN_ACCOUNT_ID
                        , case
                            when ln_CpnReportMgt = 1 then aACS_CDA_ACCOUNT_ID
                            else null
                          end
                        , case
                            when ln_CpnReportMgt = 1 then aACS_PF_ACCOUNT_ID
                            else null
                          end
                        , aACS_QTY_UNIT_ID
                        , case
                            when lbPJReportMgt = 1 then aACS_PJ_ACCOUNT_ID
                            else null
                          end
                        , aACS_FINANCIAL_ACCOUNT_ID
                        , aACS_DIVISION_ACCOUNT_ID
                        , aDOC_RECORD_ID
                        , aIMM_AMOUNT_LC_D
                        , aIMM_AMOUNT_LC_C
                        , aIMM_AMOUNT_FC_D
                        , aIMM_AMOUNT_FC_C
                        , aIMM_AMOUNT_EUR_D
                        , aIMM_AMOUNT_EUR_C
                        , aIMM_QUANTITY_D
                        , aIMM_QUANTITY_C
                        , ln_CpnReportMgt
                         );
            fetch CURSOR_NEXT_PERIOD
             into NextPeriodId;
          end loop;

          close CURSOR_NEXT_PERIOD;
        end if;
      end if;
    end if;
  end MgmPeriodsWrite;

  /**
  * Description
  *   Vérification gestion cumul (O/N) -> en fct du CPN et CDA/PF/PJ
  */
  function CumulManagement(
    aACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , aACS_CDA_ACCOUNT_ID ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT_ID  ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  , aACS_PJ_ACCOUNT_ID  ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  )
    return number
  is
    -- Vérifie Tenue cumul pour un compte donné
    cursor TotalCursor(aACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
    is
      select SUB.SSE_TOTAL
        from ACS_SUB_SET SUB
           , ACS_ACCOUNT ACC
       where ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
         and ACC.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID;

    TotalManagement ACS_SUB_SET.SSE_TOTAL%type;
    AccountId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    ReturnValue     number(1)                         default 0;
  begin
    open TotalCursor(aACS_CPN_ACCOUNT_ID);

    fetch TotalCursor
     into TotalManagement;

    close TotalCursor;

    if TotalManagement = 1 then
      if aACS_CDA_ACCOUNT_ID is not null then
        AccountId  := aACS_CDA_ACCOUNT_ID;
      elsif aACS_PF_ACCOUNT_ID is not null then
        AccountId  := aACS_PF_ACCOUNT_ID;
      elsif aACS_PJ_ACCOUNT_ID is not null then
        AccountId  := aACS_PJ_ACCOUNT_ID;
      end if;

      open TotalCursor(AccountId);

      fetch TotalCursor
       into TotalManagement;

      close TotalCursor;

      if (TotalManagement = 1)
      then
        ReturnValue  := 1;
      end if;
    end if;

    return ReturnValue;
  end CumulManagement;

  /**
  * Description
  *   Gestion des reports (O/N) sur les exercices actifs suivants, en fct Cpte fin. Bilan et Projet
  */
  function ReportManagement(
    aACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_PJ_ACCOUNT_ID        ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type
  )
    return number
  is
    BilanPP     ACS_FINANCIAL_ACCOUNT.C_BALANCE_SHEET_PROFIT_LOSS%type;
    MgmTransfer ACS_PJ_ACCOUNT.MGM_TRANSFER%type;
    ReturnValue number(1)                                                default 0;
  begin
    -- Recherche compte bilan ou PP
    select max(C_BALANCE_SHEET_PROFIT_LOSS)
      into BilanPP
      from ACS_FINANCIAL_ACCOUNT
     where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    if BilanPP = 'B' then
      ReturnValue  := 1;
    else
      -- Vérifie Report (O/N) pour un projet donné
      select max(MGM_TRANSFER)
        into MgmTransfer
        from ACS_PJ_ACCOUNT
       where ACS_PJ_ACCOUNT_ID = aACS_PJ_ACCOUNT_ID;

      if MgmTransfer = 1 then
        ReturnValue  := 1;
      end if;
    end if;

    return ReturnValue;
  end ReportManagement;

  function CpnReportManagement(in_CpnAccountId ACS_FINANCIAL_ACCOUNT.ACS_CPN_ACCOUNT_ID%type)
    return number
  is
    lv_BilanPP     ACS_FINANCIAL_ACCOUNT.C_BALANCE_SHEET_PROFIT_LOSS%type;
    MgmTransfer ACS_PJ_ACCOUNT.MGM_TRANSFER%type;
    ReturnValue number(1) default 0;
  begin
    -- Recherche si le compte financier lié au cpn donné
    -- est un compte de bilan
    select min(C_BALANCE_SHEET_PROFIT_LOSS)
    into lv_BilanPP
    from ACS_FINANCIAL_ACCOUNT
    where ACS_CPN_ACCOUNT_ID = in_CpnAccountId;

    if lv_BilanPP = 'B' then
      return 1;
    else
      return 0;
    end if;
  end CpnReportManagement;

  /**
  * Description
  *    Ajout ou Mise à jour table ACT_MGM_TOT_BY_PERIOD
  */
  procedure MgmTotalWrite(
    aC_TYPE_CUMUL                ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , aACS_PERIOD_ID               ACT_MGM_TOT_BY_PERIOD.ACS_PERIOD_ID%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_TOT_BY_PERIOD.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_CPN_ACCOUNT_ID          ACT_MGM_TOT_BY_PERIOD.ACS_CPN_ACCOUNT_ID%type
  , aACS_CDA_ACCOUNT_ID          ACT_MGM_TOT_BY_PERIOD.ACS_CDA_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT_ID           ACT_MGM_TOT_BY_PERIOD.ACS_PF_ACCOUNT_ID%type
  , aACS_QTY_UNIT_ID             ACT_MGM_TOT_BY_PERIOD.ACS_QTY_UNIT_ID%type
  , aACS_PJ_ACCOUNT_ID           ACT_MGM_TOT_BY_PERIOD.ACS_PJ_ACCOUNT_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID    ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID     ACT_MGM_TOT_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
  , aDOC_RECORD_ID               ACT_MGM_TOT_BY_PERIOD.DOC_RECORD_ID%type
  , aMTO_DEBIT_LC                ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type
  , aMTO_CREDIT_LC               ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_LC%type
  , aMTO_DEBIT_FC                ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_FC%type
  , aMTO_CREDIT_FC               ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_FC%type
  , aMTO_DEBIT_EUR               ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_EUR%type
  , aMTO_CREDIT_EUR              ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_EUR%type
  , aMTO_QUANTITY_D              ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_D%type
  , aMTO_QUANTITY_C              ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_C%type
  , iCpnReportMgt                in number default 0
  )
  is
  begin
    ACT_MGT_MGM_TOT_BY_PERIOD.MgmTotalWrite(aC_TYPE_CUMUL
                                          , aACS_PERIOD_ID
                                          , aACS_FINANCIAL_CURRENCY_ID
                                          , aF_ACS_FINANCIAL_CURRENCY_ID
                                          , aACS_CPN_ACCOUNT_ID
                                          , aACS_CDA_ACCOUNT_ID
                                          , aACS_PF_ACCOUNT_ID
                                          , aACS_QTY_UNIT_ID
                                          , aACS_PJ_ACCOUNT_ID
                                          , aACS_FINANCIAL_ACCOUNT_ID
                                          , aACS_DIVISION_ACCOUNT_ID
                                          , aDOC_RECORD_ID
                                          , aMTO_DEBIT_LC
                                          , aMTO_CREDIT_LC
                                          , aMTO_DEBIT_FC
                                          , aMTO_CREDIT_FC
                                          , aMTO_DEBIT_EUR
                                          , aMTO_CREDIT_EUR
                                          , aMTO_QUANTITY_D
                                          , aMTO_QUANTITY_C
                                          , iCpnReportMgt
                                         );
  end MgmTotalWrite;

  /**
  * Description
  *   Mise à jour différée de toutes les imputations d'un journal analytique
  *   Passage de C_ETAT_JOURNAL de BRO à PROV/DEF ou vice versa
  */
  procedure MgmImputationWrite(
    aACT_JOURNAL_ID  ACT_ETAT_JOURNAL.ACT_JOURNAL_ID%type
  , aC_ETAT_JOURNAL1 ACT_ETAT_JOURNAL.C_ETAT_JOURNAL%type
  , aC_ETAT_JOURNAL2 ACT_ETAT_JOURNAL.C_ETAT_JOURNAL%type
  )
  is
    cursor JournalImputationCursor(aACT_JOURNAL_ID ACT_ETAT_JOURNAL.ACT_JOURNAL_ID%type)
    is
      select   MGI.ACT_MGM_IMPUTATION_ID
             , MGI.ACT_FINANCIAL_IMPUTATION_ID
             , MGI.ACT_DOCUMENT_ID
             , MGI.ACS_FINANCIAL_CURRENCY_ID
             , MGI.ACS_ACS_FINANCIAL_CURRENCY_ID
             , MGI.ACS_PERIOD_ID
             , MGI.ACS_CPN_ACCOUNT_ID
             , MGI.ACS_CDA_ACCOUNT_ID
             , MGI.ACS_PF_ACCOUNT_ID
             , PJ.ACS_PJ_ACCOUNT_ID
             , MGI.DOC_RECORD_ID
             , MGI.ACS_QTY_UNIT_ID
             , MGI.IMM_AMOUNT_LC_D
             , MGI.IMM_AMOUNT_LC_C
             , MGI.IMM_AMOUNT_FC_D
             , MGI.IMM_AMOUNT_FC_C
             , MGI.IMM_AMOUNT_EUR_D
             , MGI.IMM_AMOUNT_EUR_C
             , MGI.IMM_QUANTITY_D
             , MGI.IMM_QUANTITY_C
             , (nvl(MGI.IMM_AMOUNT_LC_D, 0) - nvl(MGM.MGM_AMOUNT_LC_D, 0) ) DIFLCD
             , (nvl(MGI.IMM_AMOUNT_LC_C, 0) - nvl(MGM.MGM_AMOUNT_LC_C, 0) ) DIFLCC
             , (nvl(MGI.IMM_AMOUNT_FC_D, 0) - nvl(MGM.MGM_AMOUNT_FC_D, 0) ) DIFFCD
             , (nvl(MGI.IMM_AMOUNT_FC_C, 0) - nvl(MGM.MGM_AMOUNT_FC_C, 0) ) DIFFCC
             , (nvl(MGI.IMM_AMOUNT_EUR_D, 0) - nvl(MGM.MGM_AMOUNT_EUR_D, 0) ) DIFEURD
             , (nvl(MGI.IMM_AMOUNT_EUR_C, 0) - nvl(MGM.MGM_AMOUNT_EUR_C, 0) ) DIFEURC
             , (nvl(MGI.IMM_QUANTITY_D, 0) - nvl(MGM.MGM_QUANTITY_D, 0) ) DIFQTYD
             , (nvl(MGI.IMM_QUANTITY_C, 0) - nvl(MGM.MGM_QUANTITY_C, 0) ) DIFQTYC
             , PJ.MGM_AMOUNT_LC_D
             , PJ.MGM_AMOUNT_FC_D
             , PJ.MGM_AMOUNT_EUR_D
             , PJ.MGM_AMOUNT_LC_C
             , PJ.MGM_AMOUNT_FC_C
             , PJ.MGM_AMOUNT_EUR_C
             , PJ.MGM_QUANTITY_D
             , PJ.MGM_QUANTITY_C
          from ACT_MGM_IMPUTATION MGI
             , ACT_DOCUMENT DOC
             , (select   MGD.ACT_MGM_IMPUTATION_ID
                       , MGD.ACS_PJ_ACCOUNT_ID
                       , sum(nvl(MGD.MGM_AMOUNT_LC_D, 0) ) MGM_AMOUNT_LC_D
                       , sum(nvl(MGD.MGM_AMOUNT_FC_D, 0) ) MGM_AMOUNT_FC_D
                       , sum(nvl(MGD.MGM_AMOUNT_EUR_D, 0) ) MGM_AMOUNT_EUR_D
                       , sum(nvl(MGD.MGM_AMOUNT_LC_C, 0) ) MGM_AMOUNT_LC_C
                       , sum(nvl(MGD.MGM_AMOUNT_FC_C, 0) ) MGM_AMOUNT_FC_C
                       , sum(nvl(MGD.MGM_AMOUNT_EUR_C, 0) ) MGM_AMOUNT_EUR_C
                       , sum(nvl(MGD.MGM_QUANTITY_D, 0) ) MGM_QUANTITY_D
                       , sum(nvl(MGD.MGM_QUANTITY_C, 0) ) MGM_QUANTITY_C
                    from ACT_MGM_DISTRIBUTION MGD
                       , ACT_MGM_IMPUTATION IMM
                       , ACT_DOCUMENT ADO
                   where ADO.ACT_ACT_JOURNAL_ID = aACT_JOURNAL_ID
                     and ADO.ACT_DOCUMENT_ID = IMM.ACT_DOCUMENT_ID
                     and IMM.ACT_MGM_IMPUTATION_ID = MGD.ACT_MGM_IMPUTATION_ID
                group by MGD.ACT_MGM_IMPUTATION_ID
                       , MGD.ACS_PJ_ACCOUNT_ID) PJ
             , (select   MGD.ACT_MGM_IMPUTATION_ID
                       , sum(nvl(MGD.MGM_AMOUNT_LC_D, 0) ) MGM_AMOUNT_LC_D
                       , sum(nvl(MGD.MGM_AMOUNT_FC_D, 0) ) MGM_AMOUNT_FC_D
                       , sum(nvl(MGD.MGM_AMOUNT_EUR_D, 0) ) MGM_AMOUNT_EUR_D
                       , sum(nvl(MGD.MGM_AMOUNT_LC_C, 0) ) MGM_AMOUNT_LC_C
                       , sum(nvl(MGD.MGM_AMOUNT_FC_C, 0) ) MGM_AMOUNT_FC_C
                       , sum(nvl(MGD.MGM_AMOUNT_EUR_C, 0) ) MGM_AMOUNT_EUR_C
                       , sum(nvl(MGD.MGM_QUANTITY_D, 0) ) MGM_QUANTITY_D
                       , sum(nvl(MGD.MGM_QUANTITY_C, 0) ) MGM_QUANTITY_C
                    from ACT_MGM_DISTRIBUTION MGD
                       , ACT_MGM_IMPUTATION IMM
                       , ACT_DOCUMENT ADO
                   where ADO.ACT_ACT_JOURNAL_ID = aACT_JOURNAL_ID
                     and ADO.ACT_DOCUMENT_ID = IMM.ACT_DOCUMENT_ID
                     and IMM.ACT_MGM_IMPUTATION_ID = MGD.ACT_MGM_IMPUTATION_ID
                group by MGD.ACT_MGM_IMPUTATION_ID) MGM
         where DOC.ACT_ACT_JOURNAL_ID = aACT_JOURNAL_ID
           and DOC.ACT_DOCUMENT_ID = MGI.ACT_DOCUMENT_ID
           and MGI.ACT_MGM_IMPUTATION_ID = MGM.ACT_MGM_IMPUTATION_ID(+)
           and MGI.ACT_MGM_IMPUTATION_ID = PJ.ACT_MGM_IMPUTATION_ID(+)
      order by MGI.ACT_FINANCIAL_IMPUTATION_ID;

    imputation_distribution JournalImputationCursor%rowtype;
    MgmImputationId         ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    vSign                   integer;
  begin
    vSign  := 0;

    /** Execution et parcours du curseur des imputations du journal donné **/
    open JournalImputationCursor(aACT_JOURNAL_ID);

    fetch JournalImputationCursor
     into IMPUTATION_DISTRIBUTION;

    while JournalImputationCursor%found loop
      /** Passage de BRO à PROV ou DEF  => Ajout des montants **/
      if     aC_ETAT_JOURNAL1 = 'BRO'
         and (   aC_ETAT_JOURNAL2 = 'PROV'
              or aC_ETAT_JOURNAL2 = 'DEF') then
        vSign  := 1;
      /** Passage de PROV ou DEF  à BRO => Enlève les montants **/
      elsif     (   aC_ETAT_JOURNAL1 = 'PROV'
                 or aC_ETAT_JOURNAL1 = 'DEF')
            and aC_ETAT_JOURNAL2 = 'BRO' then
        vSign  := -1;
      end if;

      if vSign <> 0 then
        if    MgmImputationId is null
           or (MgmImputationId <> imputation_distribution.ACT_MGM_IMPUTATION_ID) then
          MgmImputationId  := imputation_distribution.ACT_MGM_IMPUTATION_ID;

          /* écritures sans distribution PJ */
          if imputation_distribution.ACS_PJ_ACCOUNT_ID is null then
            MgmTotalImputation(imputation_distribution.ACT_DOCUMENT_ID
                             , imputation_distribution.ACT_FINANCIAL_IMPUTATION_ID
                             , imputation_distribution.ACS_PERIOD_ID
                             , imputation_distribution.ACS_FINANCIAL_CURRENCY_ID
                             , imputation_distribution.ACS_ACS_FINANCIAL_CURRENCY_ID
                             , imputation_distribution.ACS_CPN_ACCOUNT_ID
                             , imputation_distribution.ACS_CDA_ACCOUNT_ID
                             , imputation_distribution.ACS_PF_ACCOUNT_ID
                             , imputation_distribution.ACS_QTY_UNIT_ID
                             , null
                             , imputation_distribution.DOC_RECORD_ID
                             , imputation_distribution.IMM_AMOUNT_LC_D
                             , imputation_distribution.IMM_AMOUNT_LC_C
                             , imputation_distribution.IMM_AMOUNT_FC_D
                             , imputation_distribution.IMM_AMOUNT_FC_C
                             , imputation_distribution.IMM_AMOUNT_EUR_D
                             , imputation_distribution.IMM_AMOUNT_EUR_C
                             , imputation_distribution.IMM_QUANTITY_D
                             , imputation_distribution.IMM_QUANTITY_C
                             , vSign
                              );
          else
            /* écritures avec distribution PJ totale */
            if     (imputation_distribution.DIFLCD = 0)
               and (imputation_distribution.DIFLCC = 0)
               and (imputation_distribution.DIFFCD = 0)
               and (imputation_distribution.DIFFCC = 0)
               and (imputation_distribution.DIFEURD = 0)
               and (imputation_distribution.DIFEURC = 0)
               and (imputation_distribution.DIFQTYD = 0)
               and (imputation_distribution.DIFQTYC = 0) then
              MgmTotalImputation(imputation_distribution.ACT_DOCUMENT_ID
                               , imputation_distribution.ACT_FINANCIAL_IMPUTATION_ID
                               , imputation_distribution.ACS_PERIOD_ID
                               , imputation_distribution.ACS_FINANCIAL_CURRENCY_ID
                               , imputation_distribution.ACS_ACS_FINANCIAL_CURRENCY_ID
                               , imputation_distribution.ACS_CPN_ACCOUNT_ID
                               , imputation_distribution.ACS_CDA_ACCOUNT_ID
                               , imputation_distribution.ACS_PF_ACCOUNT_ID
                               , imputation_distribution.ACS_QTY_UNIT_ID
                               , imputation_distribution.ACS_PJ_ACCOUNT_ID
                               , imputation_distribution.DOC_RECORD_ID
                               , imputation_distribution.MGM_AMOUNT_LC_D
                               , imputation_distribution.MGM_AMOUNT_LC_C
                               , imputation_distribution.MGM_AMOUNT_FC_D
                               , imputation_distribution.MGM_AMOUNT_FC_C
                               , imputation_distribution.MGM_AMOUNT_EUR_D
                               , imputation_distribution.MGM_AMOUNT_EUR_C
                               , imputation_distribution.MGM_QUANTITY_D
                               , imputation_distribution.MGM_QUANTITY_C
                               , vSign
                                );
            else     /* écritures avec distribution PJ partielle */
                   /* Une première écriture avec les montants PJ et compte PJ */
              MgmTotalImputation(imputation_distribution.ACT_DOCUMENT_ID
                               , imputation_distribution.ACT_FINANCIAL_IMPUTATION_ID
                               , imputation_distribution.ACS_PERIOD_ID
                               , imputation_distribution.ACS_FINANCIAL_CURRENCY_ID
                               , imputation_distribution.ACS_ACS_FINANCIAL_CURRENCY_ID
                               , imputation_distribution.ACS_CPN_ACCOUNT_ID
                               , imputation_distribution.ACS_CDA_ACCOUNT_ID
                               , imputation_distribution.ACS_PF_ACCOUNT_ID
                               , imputation_distribution.ACS_QTY_UNIT_ID
                               , imputation_distribution.ACS_PJ_ACCOUNT_ID
                               , imputation_distribution.DOC_RECORD_ID
                               , imputation_distribution.MGM_AMOUNT_LC_D
                               , imputation_distribution.MGM_AMOUNT_LC_C
                               , imputation_distribution.MGM_AMOUNT_FC_D
                               , imputation_distribution.MGM_AMOUNT_FC_C
                               , imputation_distribution.MGM_AMOUNT_EUR_D
                               , imputation_distribution.MGM_AMOUNT_EUR_C
                               , imputation_distribution.MGM_QUANTITY_D
                               , imputation_distribution.MGM_QUANTITY_C
                               , vSign
                                );
              /* Une deuxième écriture avec les montants de différence et sans compte PJ */
              MgmTotalImputation(imputation_distribution.ACT_DOCUMENT_ID
                               , imputation_distribution.ACT_FINANCIAL_IMPUTATION_ID
                               , imputation_distribution.ACS_PERIOD_ID
                               , imputation_distribution.ACS_FINANCIAL_CURRENCY_ID
                               , imputation_distribution.ACS_ACS_FINANCIAL_CURRENCY_ID
                               , imputation_distribution.ACS_CPN_ACCOUNT_ID
                               , imputation_distribution.ACS_CDA_ACCOUNT_ID
                               , imputation_distribution.ACS_PF_ACCOUNT_ID
                               , imputation_distribution.ACS_QTY_UNIT_ID
                               , null
                               , imputation_distribution.DOC_RECORD_ID
                               , imputation_distribution.DIFLCD
                               , imputation_distribution.DIFLCC
                               , imputation_distribution.DIFFCD
                               , imputation_distribution.DIFFCC
                               , imputation_distribution.DIFEURD
                               , imputation_distribution.DIFEURC
                               , imputation_distribution.DIFQTYD
                               , imputation_distribution.DIFQTYC
                               , vSign
                                );
            end if;
          end if;
        end if;
      end if;

      fetch JournalImputationCursor
       into IMPUTATION_DISTRIBUTION;
    end loop;

    close JournalImputationCursor;
  end MgmImputationWrite;

  /**
  * Description
  *    Report des cumuls analytiques sur l'exercice suivant (Ouverture exercice)
  */
  procedure MgmReportManagement(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
    -- cumul des montants pour l'exercice comptable précédent
    cursor LastYearMgmTotalCursor(
      aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
    , aC_TYPE_CUMUL          ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
    )
    is
      select   sum(MTO_DEBIT_LC - MTO_CREDIT_LC) DEBIT_CREDIT_LC
             , sum(MTO_DEBIT_FC - MTO_CREDIT_FC) DEBIT_CREDIT_FC
             , sum(MTO_DEBIT_EUR - MTO_CREDIT_EUR) DEBIT_CREDIT_EUR
             , sum(MTO_QUANTITY_D - MTO_QUANTITY_C) QUANTITY_D_C
             , TOT.ACS_CPN_ACCOUNT_ID CPN_ACCOUNT_ID
--             , TOT.ACS_CDA_ACCOUNT_ID CDA_ACCOUNT_ID
--             , TOT.ACS_PF_ACCOUNT_ID PF_ACCOUNT_ID
             , TOT.ACS_PJ_ACCOUNT_ID PJ_ACCOUNT_ID
             , TOT.ACS_QTY_UNIT_ID QTY_UNIT_ID
             , TOT.ACS_FINANCIAL_ACCOUNT_ID FINANCIAL_ACCOUNT_ID
             , TOT.ACS_DIVISION_ACCOUNT_ID DIVISION_ACCOUNT_ID
             , TOT.DOC_RECORD_ID RECORD_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID F_FINANCIAL_CURRENCY_ID
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID L_FINANCIAL_CURRENCY_ID
          from ACT_MGM_TOT_BY_PERIOD TOT
             , ACS_PERIOD PER
         where PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
           and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
      group by TOT.ACS_CPN_ACCOUNT_ID
--             , TOT.ACS_CDA_ACCOUNT_ID
--             , TOT.ACS_PF_ACCOUNT_ID
             , TOT.ACS_PJ_ACCOUNT_ID
             , TOT.ACS_QTY_UNIT_ID
             , TOT.ACS_FINANCIAL_ACCOUNT_ID
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , TOT.DOC_RECORD_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
             , TOT.C_TYPE_CUMUL;

    -- curseur de recherche des années précédentes
    cursor LAST_YEAR_CURSOR(CURRENT_YEAR_ID number)
    is
      select   B.ACS_FINANCIAL_YEAR_ID
          from ACS_FINANCIAL_YEAR A
             , ACS_FINANCIAL_YEAR B
         where A.ACS_FINANCIAL_YEAR_ID = CURRENT_YEAR_ID
           and B.FYE_NO_EXERCICE < A.FYE_NO_EXERCICE
      order by B.FYE_NO_EXERCICE desc;

    -- Types de cumuls analytiques définis dans toutes les transactions de report
    cursor CumulOfMgmReportTransaction
    is
      select distinct C_TYPE_CUMUL
                 from ACJ_SUB_SET_CAT SCA
                    , ACJ_CATALOGUE_DOCUMENT CAT
                where CAT.C_TYPE_CATALOGUE = '7'
                  and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                  and SCA.C_SUB_SET = 'CPN';

    LastYearId       ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    PeriodId         ACS_PERIOD.ACS_PERIOD_ID%type;
    UserIni          PCS.PC_USER.USE_INI%type;
    LastYearMgmTotal LastYearMgmTotalCursor%rowtype;
    TYPE_CUMUL       ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type;
    lRecordId        ACT_MGM_TOT_BY_PERIOD.ACT_MGM_TOT_BY_PERIOD_ID%type;
    lAmountLCD       ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type;
    lAmountLCC       ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type;
    lAmountFCD       ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_FC%type;
    lAmountFCC       ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_FC%type;
    lAmountEUD       ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_EUR%type;
    lAmountEUC       ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_EUR%type;
    lAmountQTD       ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_D%type;
    lAmountQTC       ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_D%type;
    lbPJReportMgt    number(1);
  -----
  begin
    UserIni  := PCS.PC_I_LIB_SESSION.GetUserIni2;

    --recherche id de l'exercice précédent
    open LAST_YEAR_CURSOR(aACS_FINANCIAL_YEAR_ID);

    fetch LAST_YEAR_CURSOR
     into LastYearId;

    close LAST_YEAR_CURSOR;

    -- Recherche de la période de report de l'exercice courant
    select ACS_PERIOD_ID
      into PeriodId
      from ACS_PERIOD
     where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
       and C_TYPE_PERIOD = '1';

    open CumulOfMgmReportTransaction;

    fetch CumulOfMgmReportTransaction
     into TYPE_CUMUL;

    while CumulOfMgmReportTransaction%found loop
      -- Recherche des cumuls de l'exercice precedent
      open LastYearMgmTotalCursor(LastYearId, TYPE_CUMUL);

      fetch LastYearMgmTotalCursor
       into LastYearMgmTotal;

      while LastYearMgmTotalCursor%found loop
        if    (LastYearMgmTotal.DEBIT_CREDIT_LC <> 0)
           or (LastYearMgmTotal.DEBIT_CREDIT_FC <> 0) then
          lbPJReportMgt := ReportManagement(LastYearMgmTotal.FINANCIAL_ACCOUNT_ID, LastYearMgmTotal.PJ_ACCOUNT_ID);
          if (lbPJReportMgt = 1) or (LastYearMgmTotal.RECORD_ID is not null)
          then
            lAmountLCD := 0.0;
            lAmountLCC := 0.0;
            lAmountFCD := 0.0;
            lAmountFCC := 0.0;
            lAmountEUD := 0.0;
            lAmountEUC := 0.0;
            lAmountQTD := 0.0;
            lAmountQTC := 0.0;
            lRecordId  := 0.0;

            if sign(LastYearMgmTotal.DEBIT_CREDIT_LC) = 1 then lAmountLCD := LastYearMgmTotal.DEBIT_CREDIT_LC;
              else lAmountLCC := abs(LastYearMgmTotal.DEBIT_CREDIT_LC) ; end if;

            if sign(LastYearMgmTotal.DEBIT_CREDIT_FC) = 1 then lAmountFCD := LastYearMgmTotal.DEBIT_CREDIT_FC;
              else lAmountFCC := abs(LastYearMgmTotal.DEBIT_CREDIT_FC); end if;

            if sign(LastYearMgmTotal.DEBIT_CREDIT_EUR) = 1 then lAmountEUD := LastYearMgmTotal.DEBIT_CREDIT_EUR;
              else lAmountEUC := abs(LastYearMgmTotal.DEBIT_CREDIT_EUR); end if;

            if sign(LastYearMgmTotal.QUANTITY_D_C) = 1 then lAmountQTD := LastYearMgmTotal.QUANTITY_D_C;
              else lAmountQTC := abs(LastYearMgmTotal.QUANTITY_D_C); end if;

            ACT_PRC_MGM_TOT_BY_PERIOD.CreateMgmTotPosition(lRecordId
                                                         , PeriodId
                                                         , LastYearMgmTotal.FINANCIAL_ACCOUNT_ID
                                                         , LastYearMgmTotal.DIVISION_ACCOUNT_ID
                                                         , LastYearMgmTotal.CPN_ACCOUNT_ID
                                                         , null --LastYearMgmTotal.CDA_ACCOUNT_ID
                                                         , null --LastYearMgmTotal.PF_ACCOUNT_ID
                                                         , case
                                                             when lbPJReportMgt = 1 then LastYearMgmTotal.PJ_ACCOUNT_ID
                                                             else null
                                                           end
                                                         , null --LastYearMgmTotal.QTY_UNIT_ID
                                                         , LastYearMgmTotal.RECORD_ID
                                                         , nvl(lAmountLCD,0)
                                                         , nvl(lAmountLCC,0)
                                                         , nvl(lAmountFCD,0)
                                                         , nvl(lAmountFCC,0)
                                                         , nvl(lAmountEUD,0)
                                                         , nvl(lAmountEUC,0)
                                                         , nvl(lAmountQTD,0)
                                                         , nvl(lAmountQTC,0)
                                                         , LastYearMgmTotal.F_FINANCIAL_CURRENCY_ID
                                                         , LastYearMgmTotal.L_FINANCIAL_CURRENCY_ID
                                                         , TYPE_CUMUL
                                                        );

          end if;
        end if;

        fetch LastYearMgmTotalCursor
         into LastYearMgmTotal;
      end loop;

      close LastYearMgmTotalCursor;

      fetch CumulOfMgmReportTransaction
       into TYPE_CUMUL;
    end loop;

    close CumulOfMgmReportTransaction;
  end MgmReportManagement;
end ACT_MGM_TOTAL_BY_PERIOD;
