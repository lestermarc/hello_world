--------------------------------------------------------
--  DDL for Package Body ACT_EVOLUTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_EVOLUTION" 
is

  /**
  * Gestion des cumuls report (O/N) en fonction des transactions de report
  **/
  function ReportManagementOfTypeCumul(aC_TYPE_CUMUL ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type) return number
  is

    TypeCumul ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type;

  begin

    select max(C_TYPE_CUMUL) into TypeCumul
      from ACJ_SUB_SET_CAT        SCA,
           ACJ_CATALOGUE_DOCUMENT CAT
      where CAT.C_TYPE_CATALOGUE          = '7'
        and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
        and SCA.C_TYPE_CUMUL              = aC_TYPE_CUMUL;

    if TypeCumul = aC_TYPE_CUMUL then
      return 1;
    else
      return 0;
    end if;

  end ReportManagementOfTypeCumul;

  /**
  * Description
  *    Mise à jour de la table ACT_TOTAL_BY_PERIOD d'après les imputations déjà créées
  *    lors du passage de l'etat d'un journal de Brouillard à Provisoire
  */
  procedure ACT_WRITE_JOURNAL_IMPUTATIONS(JOURNAL_ID ACT_JOURNAL.ACT_JOURNAL_ID%type,
                                          SUB_SET    ACT_ETAT_JOURNAL.C_SUB_SET%type)
  is
    TypeCumul   ACJ_SUB_SET_CAT.C_TYPE_CUMUL%TYPE;
    TypeJournal ACT_JOURNAL.C_TYPE_JOURNAL%type;

    -- Curseur sur les imputations à entrer dans la table de totalisation
    cursor FIN_IMP_CURSOR(JournalId ACT_JOURNAL.ACT_JOURNAL_ID%type) is
      select
             IMP.ACS_FINANCIAL_ACCOUNT_ID,
             IMP.ACS_AUXILIARY_ACCOUNT_ID,
             IMP.ACS_PERIOD_ID,
             IMP.IMF_AMOUNT_LC_D,
             IMP.IMF_AMOUNT_LC_C,
             IMP.IMF_AMOUNT_FC_D,
             IMP.IMF_AMOUNT_FC_C,
             IMP.IMF_AMOUNT_EUR_D,
             IMP.IMF_AMOUNT_EUR_C,
             IMP.ACS_FINANCIAL_CURRENCY_ID,
             IMP.ACT_DOCUMENT_ID,
             FIN.FIN_COLLECTIVE,
             FIN.C_BALANCE_SHEET_PROFIT_LOSS,
             IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID,
             CAT.C_TYPE_PERIOD
        from
             ACJ_CATALOGUE_DOCUMENT     CAT,
             ACS_FINANCIAL_ACCOUNT      FIN,
             ACT_FINANCIAL_IMPUTATION   IMP,
             ACT_DOCUMENT               DOC
        where
              DOC.ACT_JOURNAL_ID              = JournalId
          and DOC.ACT_DOCUMENT_ID             = IMP.ACT_DOCUMENT_ID
          and IMP.ACS_FINANCIAL_ACCOUNT_ID    = FIN.ACS_FINANCIAL_ACCOUNT_ID
          and DOC.ACJ_CATALOGUE_DOCUMENT_ID   = CAT.ACJ_CATALOGUE_DOCUMENT_ID;

    -- Ramène le(s) type(s) cumul à gérer pour le sous-ensemble courant !!!
    cursor SUB_SET_CURSOR(DocumentId number, cSUB_SET varchar) IS
      select JSC.C_TYPE_CUMUL
        from ACJ_SUB_SET_CAT        JSC,
             ACJ_CATALOGUE_DOCUMENT CAT,
             ACT_DOCUMENT           DOC
        where DOC.ACT_DOCUMENT_ID           = DocumentId
          and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
          and CAT.ACJ_CATALOGUE_DOCUMENT_ID = JSC.ACJ_CATALOGUE_DOCUMENT_ID
          and JSC.C_SUB_SET                 = cSUB_SET;

    FinancialImputations FIN_IMP_CURSOR%rowtype;
    UserIni              PCS.PC_USER.USE_INI%type;

  -----
  begin

    -- recherche du type de journal
    select C_TYPE_JOURNAL into TypeJournal
      from ACT_JOURNAL
      where ACT_JOURNAL_ID = JOURNAL_ID;

    if TypeJournal <> 'OPB' then

      UserIni := PCS.PC_I_LIB_SESSION.GetUserIni2;

      -- mise à jour des imputations pour l'état finance
      open FIN_IMP_CURSOR(JOURNAL_ID);
      fetch FIN_IMP_CURSOR into FinancialImputations;

      while FIN_IMP_CURSOR%FOUND loop

        open SUB_SET_CURSOR(FinancialImputations.ACT_DOCUMENT_ID, Sub_Set);
        fetch SUB_SET_CURSOR into TypeCumul;

        while SUB_SET_CURSOR%FOUND loop

          FinPeriodsWrite(Sub_Set,
                          TypeCumul,
                          FinancialImputations.ACS_FINANCIAL_ACCOUNT_ID,
                          FinancialImputations.ACS_AUXILIARY_ACCOUNT_ID,
                          FinancialImputations.ACS_PERIOD_ID,
                          FinancialImputations.IMF_AMOUNT_LC_D,
                          FinancialImputations.IMF_AMOUNT_LC_C,
                          FinancialImputations.IMF_AMOUNT_FC_D,
                          FinancialImputations.IMF_AMOUNT_FC_C,
                          FinancialImputations.IMF_AMOUNT_EUR_D,
                          FinancialImputations.IMF_AMOUNT_EUR_C,
                          FinancialImputations.ACS_FINANCIAL_CURRENCY_ID,
                          FinancialImputations.FIN_COLLECTIVE,
                          FinancialImputations.C_BALANCE_SHEET_PROFIT_LOSS,
                          FinancialImputations.ACS_DIVISION_ACCOUNT_ID,
                          FinancialImputations.C_TYPE_PERIOD,
                          UserIni);

          fetch SUB_SET_CURSOR into TypeCumul;

        end loop;

        close SUB_SET_CURSOR;
        fetch FIN_IMP_CURSOR into FinancialImputations;

      end loop;

    end if;

  end ACT_WRITE_JOURNAL_IMPUTATIONS;

  -------------------------
  procedure FinPeriodsWrite(aC_SUB_SET                   ACS_SUB_SET.C_SUB_SET%type,
                            aC_TYPE_CUMUL                ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type,
                            aACS_FINANCIAL_ACCOUNT_ID    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type,
                            aACS_AUXILIARY_ACCOUNT_ID    ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID%type,
                            aACS_PERIOD_ID               ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type,
                            aIMF_AMOUNT_LC_D             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type,
                            aIMF_AMOUNT_LC_C             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type,
                            aIMF_AMOUNT_FC_D             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type,
                            aIMF_AMOUNT_FC_C             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type,
                            aIMF_AMOUNT_EUR_D            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type,
                            aIMF_AMOUNT_EUR_C            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type,
                            aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                            aFIN_COLLECTIVE              ACS_FINANCIAL_ACCOUNT.FIN_COLLECTIVE%type,
                            aC_BALANCE_SHEET_PROFIT_LOSS ACS_FINANCIAL_ACCOUNT.C_BALANCE_SHEET_PROFIT_LOSS%type,
                            aACS_DIVISION_ACCOUNT_ID     ACT_TOTAL_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type,
                            aC_TYPE_PERIOD               ACT_TOTAL_BY_PERIOD.C_TYPE_PERIOD%type,
                            aUserIni                     PCS.PC_USER.USE_INI%type)
  is

    BaseCurrencyId      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    AuxiliaryAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    NoExercice          ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;
    NextPeriodId        ACS_PERIOD.ACS_PERIOD_ID%type;
    --------

    -- Recherche des périodes de report des exercices suivants actifs
    cursor CURSOR_NEXT_PERIOD(YEAR_EXERCICE number) is
      select ACS_PERIOD_ID
      from ACS_FINANCIAL_YEAR Y, ACS_PERIOD P
      where Y.ACS_FINANCIAL_YEAR_ID = P.ACS_FINANCIAL_YEAR_ID
        and Y.C_STATE_FINANCIAL_YEAR = 'ACT'
        and Y.FYE_NO_EXERCICE > YEAR_EXERCICE
        and P.C_TYPE_PERIOD = '1';
    --------


    function OkForCumul return boolean
    is
      Result     boolean := False;
      AccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      SseTotal   ACS_SUB_SET.SSE_TOTAL%type;
    begin
      if aC_SUB_SET = 'ACC' then
        AccountId          := aACS_FINANCIAL_ACCOUNT_ID;
        AuxiliaryAccountId := null;
      else
        AccountId          := aACS_AUXILIARY_ACCOUNT_ID;
        AuxiliaryAccountId := aACS_AUXILIARY_ACCOUNT_ID;
      end if;
      Result := AccountId is not null;
      if Result then
        -- Vérification tenue cumul au niveau du sous-ensemble
        select SSE_TOTAL into SseTotal
          from ACS_SUB_SET SUB,
               ACS_ACCOUNT ACC
          where ACC.ACS_ACCOUNT_ID = AccountId
            and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID;
        Result := (SseTotal = 1);
        if Result and aC_SUB_SET = 'ACC' then
          -- Le report n'est autorisé que pour les comptes de bilan
          Result := not (aC_TYPE_PERIOD = '1' and aC_BALANCE_SHEET_PROFIT_LOSS <> 'B');
        elsif Result then
          -- Dans le cas d'un compte auxiliaire, vérification compte financier collectif
          Result := (aFIN_COLLECTIVE = 1);
        end if;
      end if;
      return Result;
    end;

  -----
  begin

    if OkForCumul then

      BaseCurrencyId := ACS_FUNCTION.GetLocalCurrencyID;

      -- Mise à jour de la période courante
      FinTotalWrite(aACS_PERIOD_ID,
                    aIMF_AMOUNT_LC_D,
                    aIMF_AMOUNT_LC_C,
                    aIMF_AMOUNT_FC_D,
                    aIMF_AMOUNT_FC_C,
                    aIMF_AMOUNT_EUR_D,
                    aIMF_AMOUNT_EUR_C,
                    aACS_FINANCIAL_ACCOUNT_ID,
                    AuxiliaryAccountId,
                    aACS_DIVISION_ACCOUNT_ID,
                    BaseCurrencyId,
                    aACS_FINANCIAL_CURRENCY_ID,
                    aC_TYPE_PERIOD,
                    aC_TYPE_CUMUL,
                    aUserIni);

      -- Cumul sur les exercices suivants
      if aC_BALANCE_SHEET_PROFIT_LOSS = 'B' and ReportManagementOfTypeCumul(aC_TYPE_CUMUL) = 1 then

        -- Recherche de l'exercice comptable courant
        select FYE_NO_EXERCICE into NoExercice
        from ACS_FINANCIAL_YEAR YEA,
             ACS_PERIOD         PER
        where PER.ACS_PERIOD_ID         = aACS_PERIOD_ID
          and PER.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID;

        open CURSOR_NEXT_PERIOD(NoExercice);
        fetch CURSOR_NEXT_PERIOD into NextPeriodId;

        while CURSOR_NEXT_PERIOD%found loop

          -- Mise a jour du San des exercices suivants
          FinTotalWrite(NextPeriodId,
                        aIMF_AMOUNT_LC_D,
                        aIMF_AMOUNT_LC_C,
                        aIMF_AMOUNT_FC_D,
                        aIMF_AMOUNT_FC_C,
                        aIMF_AMOUNT_EUR_D,
                        aIMF_AMOUNT_EUR_C,
                        aACS_FINANCIAL_ACCOUNT_ID,
                        AuxiliaryAccountId,
                        aACS_DIVISION_ACCOUNT_ID,
                        BaseCurrencyId,
                        aACS_FINANCIAL_CURRENCY_ID,
                        '1',
                        aC_TYPE_CUMUL,
                        aUserIni);

          fetch CURSOR_NEXT_PERIOD into NextPeriodId;

        end loop;

        close CURSOR_NEXT_PERIOD;

      end if;

    end if;

  end FinPeriodsWrite;

  -----------------------
  procedure FinTotalWrite(aACS_PERIOD_ID             ACT_TOTAL_BY_PERIOD.C_TYPE_PERIOD%type,
                          aIMF_AMOUNT_LC_D           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type,
                          aIMF_AMOUNT_LC_C           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type,
                          aIMF_AMOUNT_FC_D           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type,
                          aIMF_AMOUNT_FC_C           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type,
                          aIMF_AMOUNT_EUR_D          ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type,
                          aIMF_AMOUNT_EUR_C          ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type,
                          aACS_FINANCIAL_ACCOUNT_ID  ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type,
                          aACS_AUXILIARY_ACCOUNT_ID  ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID%type,
                          aACS_DIVISION_ACCOUNT_ID   ACT_TOTAL_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type,
                          aBaseCurrencyId            ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                          aACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                          aC_TYPE_PERIOD             ACT_TOTAL_BY_PERIOD.C_TYPE_PERIOD%type,
                          aC_TYPE_CUMUL              ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type,
                          aUserIni                   PCS.PC_USER.USE_INI%type)
  is

    cursor CURSOR_FIN_CURRENCY(FINANCIAL_ACCOUNT_ID number, FOREIGN_CURRENCY_ID number) is
      select ACS_FINANCIAL_ACCOUNT_ID
      from ACS_FIN_ACCOUNT_S_FIN_CURR
      where ACS_FINANCIAL_ACCOUNT_ID  = FINANCIAL_ACCOUNT_ID
        and ACS_FINANCIAL_CURRENCY_ID = FOREIGN_CURRENCY_ID
      union
      select ACS_FINANCIAL_ACCOUNT_ID
      from ACS_FINANCIAL_ACCOUNT
      where ACS_FINANCIAL_ACCOUNT_ID = FINANCIAL_ACCOUNT_ID
        and FIN_COLLECTIVE           = 1;
/*
    cursor CURSOR_AUX_CURRENCY(AUXILIARY_ACCOUNT_ID number, FOREIGN_CURRENCY_ID number) is
      select ACS_AUXILIARY_ACCOUNT_ID
      from ACS_AUX_ACCOUNT_S_FIN_CURR
      where ACS_AUXILIARY_ACCOUNT_ID=AUXILIARY_ACCOUNT_ID
        and ACS_FINANCIAL_CURRENCY_ID=FOREIGN_CURRENCY_ID;
*/
    AccountId         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    ForeignCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    TotalByPeriodId   ACT_TOTAL_BY_PERIOD.ACT_TOTAL_BY_PERIOD_ID%type;

    Amount_LC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    Amount_LC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    Amount_FC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    Amount_FC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    Amount_EUR_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    Amount_EUR_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;

    --------
    procedure GetTotalByPeriodId(
      aWithDivision     in     boolean
    , aTotalByPeriodId  out    ACT_TOTAL_BY_PERIOD.ACT_TOTAL_BY_PERIOD_ID%type
    , aIMF_AMOUNT_LC_D  in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
    , aIMF_AMOUNT_LC_C  in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
    , aIMF_AMOUNT_FC_D  in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
    , aIMF_AMOUNT_FC_C  in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
    , aIMF_AMOUNT_EUR_D in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
    , aIMF_AMOUNT_EUR_C in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
    )
    is
    begin
      if aWithDivision then
        if aACS_AUXILIARY_ACCOUNT_ID is null then
          select max(ACT_TOTAL_BY_PERIOD_ID)
            into aTotalByPeriodId
            from ACT_TOTAL_BY_PERIOD
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
             and ACS_AUXILIARY_ACCOUNT_ID is null
             and ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID
             and ACS_PERIOD_ID = aACS_PERIOD_ID
             and C_TYPE_PERIOD = aC_TYPE_PERIOD
             and C_TYPE_CUMUL = aC_TYPE_CUMUL
             and ACS_ACS_FINANCIAL_CURRENCY_ID = ForeignCurrencyId;
        else
          select max(ACT_TOTAL_BY_PERIOD_ID)
            into aTotalByPeriodId
            from ACT_TOTAL_BY_PERIOD
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
             and ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
             and ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID
             and ACS_PERIOD_ID = aACS_PERIOD_ID
             and C_TYPE_PERIOD = aC_TYPE_PERIOD
             and C_TYPE_CUMUL = aC_TYPE_CUMUL
             and ACS_ACS_FINANCIAL_CURRENCY_ID = ForeignCurrencyId;
        end if;
      else
        if aACS_AUXILIARY_ACCOUNT_ID is null then
          select max(ACT_TOTAL_BY_PERIOD_ID)
            into aTotalByPeriodId
            from ACT_TOTAL_BY_PERIOD
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
             and ACS_AUXILIARY_ACCOUNT_ID is null
             and ACS_DIVISION_ACCOUNT_ID is null
             and ACS_PERIOD_ID = aACS_PERIOD_ID
             and C_TYPE_PERIOD = aC_TYPE_PERIOD
             and C_TYPE_CUMUL = aC_TYPE_CUMUL
             and ACS_ACS_FINANCIAL_CURRENCY_ID = ForeignCurrencyId;
        else
          select max(ACT_TOTAL_BY_PERIOD_ID)
            into aTotalByPeriodId
            from ACT_TOTAL_BY_PERIOD
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
             and ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
             and ACS_DIVISION_ACCOUNT_ID is null
             and ACS_PERIOD_ID = aACS_PERIOD_ID
             and C_TYPE_PERIOD = aC_TYPE_PERIOD
             and C_TYPE_CUMUL = aC_TYPE_CUMUL
             and ACS_ACS_FINANCIAL_CURRENCY_ID = ForeignCurrencyId;
        end if;
      end if;

      if not aTotalByPeriodId is null then
        select     decode(aC_TYPE_PERIOD
                        , '1', decode(sign(TOT_DEBIT_LC - TOT_CREDIT_LC + aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C)
                                    , 1, TOT_DEBIT_LC - TOT_CREDIT_LC + aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C
                                    , 0
                                     )
                        , aIMF_AMOUNT_LC_D
                         )
                 , decode(aC_TYPE_PERIOD
                        , '1', decode(sign(TOT_DEBIT_LC - TOT_CREDIT_LC + aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C)
                                    , -1, abs(TOT_DEBIT_LC - TOT_CREDIT_LC + aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C)
                                    , 0
                                     )
                        , aIMF_AMOUNT_LC_C
                         )
                 , decode(aC_TYPE_PERIOD
                        , '1', decode(sign(TOT_DEBIT_FC - TOT_CREDIT_FC + aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C)
                                    , 1, TOT_DEBIT_FC - TOT_CREDIT_FC + aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C
                                    , 0
                                     )
                        , aIMF_AMOUNT_FC_D
                         )
                 , decode(aC_TYPE_PERIOD
                        , '1', decode(sign(TOT_DEBIT_FC - TOT_CREDIT_FC + aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C)
                                    , -1, abs(TOT_DEBIT_FC - TOT_CREDIT_FC + aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C)
                                    , 0
                                     )
                        , aIMF_AMOUNT_FC_C
                         )
                 , decode(aC_TYPE_PERIOD
                        , '1', decode(sign(TOT_DEBIT_EUR - TOT_CREDIT_EUR + aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C)
                                    , 1, TOT_DEBIT_EUR - TOT_CREDIT_EUR + aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C
                                    , 0
                                     )
                        , aIMF_AMOUNT_EUR_D
                         )
                 , decode(aC_TYPE_PERIOD
                        , '1', decode(sign(TOT_DEBIT_EUR - TOT_CREDIT_EUR + aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C)
                                    , -1, abs(TOT_DEBIT_EUR - TOT_CREDIT_EUR + aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C)
                                    , 0
                                     )
                        , aIMF_AMOUNT_EUR_C
                         )
              into aIMF_AMOUNT_LC_D
                 , aIMF_AMOUNT_LC_C
                 , aIMF_AMOUNT_FC_D
                 , aIMF_AMOUNT_FC_C
                 , aIMF_AMOUNT_EUR_D
                 , aIMF_AMOUNT_EUR_C
              from ACT_TOTAL_BY_PERIOD
             where ACT_TOTAL_BY_PERIOD_ID = aTotalByPeriodId
        for update;
      else
        if aC_TYPE_PERIOD = '1' then
          if (aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C > 0) then
            aIMF_AMOUNT_LC_D  :=(aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C);
            aIMF_AMOUNT_LC_C  := 0;
          else
            aIMF_AMOUNT_LC_C  := abs(aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C);
            aIMF_AMOUNT_LC_D  := 0;
          end if;

          if (aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C > 0) then
            aIMF_AMOUNT_FC_D  :=(aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C);
            aIMF_AMOUNT_FC_C  := 0;
          else
            aIMF_AMOUNT_FC_C  := abs(aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C);
            aIMF_AMOUNT_FC_D  := 0;
          end if;

          if (aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C > 0) then
            aIMF_AMOUNT_EUR_D  :=(aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C);
            aIMF_AMOUNT_EUR_C  := 0;
          else
            aIMF_AMOUNT_EUR_C  := abs(aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C);
            aIMF_AMOUNT_EUR_D  := 0;
          end if;
        end if;
      end if;
    end;
  -----
  begin

    -- Vérification des monnaies autorisées pour les comptes financiers
    if aBaseCurrencyId <> aACS_FINANCIAL_CURRENCY_ID and aACS_AUXILIARY_ACCOUNT_ID is null then

      open CURSOR_FIN_CURRENCY(aACS_FINANCIAL_ACCOUNT_ID, aACS_FINANCIAL_CURRENCY_ID);
      fetch CURSOR_FIN_CURRENCY into AccountId;
      close CURSOR_FIN_CURRENCY;

      if AccountId is null then
        ForeignCurrencyId := aBaseCurrencyId;
      else
        ForeignCurrencyId := aACS_FINANCIAL_CURRENCY_ID;
      end if;

    else

      ForeignCurrencyId := aACS_FINANCIAL_CURRENCY_ID;

    end if;

    Amount_LC_D  := aIMF_AMOUNT_LC_D;
    Amount_LC_C  := aIMF_AMOUNT_LC_C;
    Amount_FC_D  := aIMF_AMOUNT_FC_D;
    Amount_FC_C  := aIMF_AMOUNT_FC_C;
    Amount_EUR_D := aIMF_AMOUNT_EUR_D;
    Amount_EUR_C := aIMF_AMOUNT_EUR_C;

    -- recherche s'il existe déjà une position dans la table ACT_TOTAL_BY_PERIOD
    GetTotalByPeriodId(false, TotalByPeriodId, Amount_LC_D,  Amount_LC_C,
                                               Amount_FC_D,  Amount_FC_C,
                                               Amount_EUR_D, Amount_EUR_C);

    WriteTotalByPeriod(TotalByPeriodId,
                       aACS_PERIOD_ID,
                       Amount_LC_D,
                       Amount_LC_C,
                       Amount_FC_D,
                       Amount_FC_C,
                       Amount_EUR_D,
                       Amount_EUR_C,
                       aACS_FINANCIAL_ACCOUNT_ID,
                       aACS_AUXILIARY_ACCOUNT_ID,
                       null,
                       aBaseCurrencyId,
                       ForeignCurrencyId,
                       aC_TYPE_PERIOD,
                       aC_TYPE_CUMUL,
                       aUserIni);

    if aACS_DIVISION_ACCOUNT_ID is not null then

      Amount_LC_D  := aIMF_AMOUNT_LC_D;
      Amount_LC_C  := aIMF_AMOUNT_LC_C;
      Amount_FC_D  := aIMF_AMOUNT_FC_D;
      Amount_FC_C  := aIMF_AMOUNT_FC_C;
      Amount_EUR_D := aIMF_AMOUNT_EUR_D;
      Amount_EUR_C := aIMF_AMOUNT_EUR_C;

      -- recherche s'il existe déjà une position dans la table ACT_TOTAL_BY_PERIOD
      GetTotalByPeriodId(true, TotalByPeriodId, Amount_LC_D,  Amount_LC_C,
                                                Amount_FC_D,  Amount_FC_C,
                                                Amount_EUR_D, Amount_EUR_C);

      WriteTotalByPeriod(TotalByPeriodId,
                         aACS_PERIOD_ID,
                         Amount_LC_D,
                         Amount_LC_C,
                         Amount_FC_D,
                         Amount_FC_C,
                         Amount_EUR_D,
                         Amount_EUR_C,
                         aACS_FINANCIAL_ACCOUNT_ID,
                         aACS_AUXILIARY_ACCOUNT_ID,
                         aACS_DIVISION_ACCOUNT_ID,
                         aBaseCurrencyId,
                         ForeignCurrencyId,
                         aC_TYPE_PERIOD,
                         aC_TYPE_CUMUL,
                         aUserIni);

    end if;

  end FinTotalWrite;

  ----------------------------
  procedure WriteTotalByPeriod(aACT_TOTAL_BY_PERIOD_ID   ACT_TOTAL_BY_PERIOD.ACT_TOTAL_BY_PERIOD_ID%type,
                               aACS_PERIOD_ID            ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type,
                               aTOT_DEBIT_LC             ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type,
                               aTOT_CREDIT_LC            ACT_TOTAL_BY_PERIOD.TOT_CREDIT_LC%type,
                               aTOT_DEBIT_FC             ACT_TOTAL_BY_PERIOD.TOT_DEBIT_FC%type,
                               aTOT_CREDIT_FC            ACT_TOTAL_BY_PERIOD.TOT_CREDIT_FC%type,
                               aTOT_DEBIT_EUR            ACT_TOTAL_BY_PERIOD.TOT_DEBIT_EUR%type,
                               aTOT_CREDIT_EUR           ACT_TOTAL_BY_PERIOD.TOT_CREDIT_EUR%type,
                               aACS_FINANCIAL_ACCOUNT_ID ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type,
                               aACS_AUXILIARY_ACCOUNT_ID ACT_TOTAL_BY_PERIOD.ACS_AUXILIARY_ACCOUNT_ID%type,
                               aACS_DIVISION_ACCOUNT_ID  ACT_TOTAL_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type,
                               aBaseCurrencyId           ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type,
                               aForeignCurrencyId        ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type,
                               aC_TYPE_PERIOD            ACT_TOTAL_BY_PERIOD.C_TYPE_PERIOD%type,
                               aC_TYPE_CUMUL             ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type,
                               aUserIni                  PCS.PC_USER.USE_INI%type)
  is
  begin
    if aACT_TOTAL_BY_PERIOD_ID is null then
      -- il n'y a pas de position, on doit la créer
      insert into ACT_TOTAL_BY_PERIOD(
        ACT_TOTAL_BY_PERIOD_ID,
        ACS_PERIOD_ID,
        TOT_DEBIT_LC,
        TOT_CREDIT_LC,
        TOT_DEBIT_FC,
        TOT_CREDIT_FC,
        TOT_DEBIT_EUR,
        TOT_CREDIT_EUR,
        ACS_FINANCIAL_ACCOUNT_ID,
        ACS_AUXILIARY_ACCOUNT_ID,
        ACS_DIVISION_ACCOUNT_ID,
        ACS_FINANCIAL_CURRENCY_ID,
        ACS_ACS_FINANCIAL_CURRENCY_ID,
        C_TYPE_PERIOD,
        C_TYPE_CUMUL,
        A_DATECRE,
        A_IDCRE)
      values(
        init_id_seq.nextval,
        aACS_PERIOD_ID,
        nvl(aTOT_DEBIT_LC,   0),
        nvl(aTOT_CREDIT_LC,  0),
        nvl(decode(aBaseCurrencyId, aForeignCurrencyId, 0, aTOT_DEBIT_FC),  0),
        nvl(decode(aBaseCurrencyId, aForeignCurrencyId, 0, aTOT_CREDIT_FC), 0),
        nvl(aTOT_DEBIT_EUR,  0),
        nvl(aTOT_CREDIT_EUR, 0),
        aACS_FINANCIAL_ACCOUNT_ID,
        aACS_AUXILIARY_ACCOUNT_ID,
        aACS_DIVISION_ACCOUNT_ID,
        aBaseCurrencyId,
        aForeignCurrencyId,
        aC_TYPE_PERIOD,
        aC_TYPE_CUMUL,
        sysdate,
        aUserIni);
    else
      -- Il existe une position, on fait une mise à jour de la position
      if aC_TYPE_PERIOD = '1' then
        -- Période de report
        update ACT_TOTAL_BY_PERIOD
          set TOT_DEBIT_LC   = nvl(aTOT_DEBIT_LC,   0),
              TOT_CREDIT_LC  = nvl(aTOT_CREDIT_LC,  0),
              TOT_DEBIT_FC   = nvl(decode(aBaseCurrencyId, aForeignCurrencyId, 0, aTOT_DEBIT_FC),  0),
              TOT_CREDIT_FC  = nvl(decode(aBaseCurrencyId, aForeignCurrencyId, 0, aTOT_CREDIT_FC), 0),
              TOT_DEBIT_EUR  = nvl(aTOT_DEBIT_EUR,  0),
              TOT_CREDIT_EUR = nvl(aTOT_CREDIT_EUR, 0),
              A_DATEMOD      = sysdate,
              A_IDMOD        = aUserIni
          where ACT_TOTAL_BY_PERIOD_ID = aACT_TOTAL_BY_PERIOD_ID;
      else
        update ACT_TOTAL_BY_PERIOD
          set TOT_DEBIT_LC   = TOT_DEBIT_LC   + nvl(aTOT_DEBIT_LC,   0),
              TOT_CREDIT_LC  = TOT_CREDIT_LC  + nvl(aTOT_CREDIT_LC,  0),
              TOT_DEBIT_FC   = TOT_DEBIT_FC   + nvl(decode(aBaseCurrencyId, aForeignCurrencyId, 0, aTOT_DEBIT_FC),  0),
              TOT_CREDIT_FC  = TOT_CREDIT_FC  + nvl(decode(aBaseCurrencyId, aForeignCurrencyId, 0, aTOT_CREDIT_FC), 0),
              TOT_DEBIT_EUR  = TOT_DEBIT_EUR  + nvl(aTOT_DEBIT_EUR,  0),
              TOT_CREDIT_EUR = TOT_CREDIT_EUR + nvl(aTOT_CREDIT_EUR, 0),
              A_DATEMOD      = sysdate,
              A_IDMOD        = aUserIni
          where ACT_TOTAL_BY_PERIOD_ID = aACT_TOTAL_BY_PERIOD_ID;
      end if;
    end if;
  end WriteTotalByPeriod;

end ACT_EVOLUTION;
