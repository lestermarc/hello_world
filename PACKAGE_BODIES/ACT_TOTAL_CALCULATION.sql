--------------------------------------------------------
--  DDL for Package Body ACT_TOTAL_CALCULATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_TOTAL_CALCULATION" 
is

  /*
  * Recalcul des cumuls financiers (ACT_TOTAL_BY_PERIOD)
  */
  procedure YearCalculation(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
  begin

    DeleteTotalByPeriod(aACS_FINANCIAL_YEAR_ID);
    GenerateReport(aACS_FINANCIAL_YEAR_ID, 'FIN');
    DocCalculation(aACS_FINANCIAL_YEAR_ID, 1);

  end YearCalculation;

  /*
  * Recalcul des cumuls analytiques (ACT_MGM_TOT_BY_PERIOD)
  */
  procedure MgmYearCalculation(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
    vManAccounting  ACS_ACCOUNTING.ACS_ACCOUNTING_ID%type;
  begin
    --Réception Id comptabilité analytique
    select nvl(max(ACS_ACCOUNTING_ID),0) into  vManAccounting
    from ACS_ACCOUNTING
    where C_TYPE_ACCOUNTING ='MAN';
    --Traitement si comptabilité analytique existe
    if vManAccounting <> 0 then
      DeleteMgmTotalByPeriod(aACS_FINANCIAL_YEAR_ID);
      GenerateReport(aACS_FINANCIAL_YEAR_ID, 'MAN');
      DocCalculation(aACS_FINANCIAL_YEAR_ID, 2);
    end if;
  end MgmYearCalculation;


  /**
  * Description
  *   Effacement de tous les cumuls financiers de l'exercice à traiter et des reports suivants
  */
  procedure DeleteTotalByPeriod(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
  begin

    select FYE_NO_EXERCICE into looFYE_NO_EXERCICE
      from ACS_FINANCIAL_YEAR
      where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID;

    -- Elimination de tous les records traitant de l'exercice courant
    delete from ACT_TOTAL_BY_PERIOD
      where ACS_PERIOD_ID in (select ACS_PERIOD_ID
                                from ACS_PERIOD
                                where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                              );

    -- Elimination de tous les records traitant la période de report des exercices suivants
    delete from ACT_TOTAL_BY_PERIOD
      where ACS_PERIOD_ID in (select ACS_PERIOD_ID
                                from ACS_PERIOD          PER,
                                     ACS_FINANCIAL_YEAR  YEA
                                where YEA.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                                  and YEA.C_STATE_FINANCIAL_YEAR <> 'CLO'
                                  and PER.C_TYPE_PERIOD = '1'
                                  and YEA.FYE_NO_EXERCICE > looFYE_NO_EXERCICE
                              );
  end DeleteTotalByPeriod;

  /**
  * Description
  *   Effacement de tous les cumuls analytiques de l'exercice à traiter et des reports suivants
  */
  procedure DeleteMgmTotalByPeriod(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
  begin

    select FYE_NO_EXERCICE into looFYE_NO_EXERCICE
      from ACS_FINANCIAL_YEAR
      where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID;

    -- Elimination de tous les records traitant de l'exercice courant
    delete from ACT_MGM_TOT_BY_PERIOD
      where ACS_PERIOD_ID in (select ACS_PERIOD_ID
                                from ACS_PERIOD
                                where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                              );

    -- Elimination de tous les records traitant la période de report des exercices suivants
    delete from ACT_MGM_TOT_BY_PERIOD
      where ACS_PERIOD_ID in (select ACS_PERIOD_ID
                                from ACS_PERIOD         PER,
                                     ACS_FINANCIAL_YEAR YEA
                                where YEA.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                                  and PER.C_TYPE_PERIOD = '1'
                                  and YEA.C_STATE_FINANCIAL_YEAR <> 'CLO'
                                  and YEA.FYE_NO_EXERCICE > looFYE_NO_EXERCICE
                              );
  end DeleteMgmTotalByPeriod;


  /**
  * Description
  *   Regénération des reports pour tous les exercices suivant l'exercice à traite
  */
  procedure GenerateReport(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type,
                           aC_TYPE_ACCOUNTING     ACS_ACCOUNTING.C_TYPE_ACCOUNTING%type)
  is

    -- curseur de recherche des exercices actifs suivants
    cursor ActiveYear(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type) is
      select B.ACS_FINANCIAL_YEAR_ID
      from ACS_FINANCIAL_YEAR A,
           ACS_FINANCIAL_YEAR B
      where A.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
        and B.C_STATE_FINANCIAL_YEAR = 'ACT'
        and B.FYE_NO_EXERCICE > A.FYE_NO_EXERCICE
        order by B.FYE_NO_EXERCICE asc;

    NextYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;

  begin
    -- Calcul du report de l'exercice courant
    -- Sur la base des imputations de l'année précédente
    if aC_TYPE_ACCOUNTING = 'FIN' then
      ACT_REPORT_MANAGEMENT(aACS_FINANCIAL_YEAR_ID);
    else
      ACT_MGM_TOTAL_BY_PERIOD.MgmReportManagement(aACS_FINANCIAL_YEAR_ID);
    end if;

    open ActiveYear(aACS_FINANCIAL_YEAR_ID);
    fetch ActiveYear into NextYearId;

    while ActiveYear%found loop

      if aC_TYPE_ACCOUNTING = 'FIN' then
        ACT_REPORT_MANAGEMENT(NextYearId);
      elsif aC_TYPE_ACCOUNTING = 'MAN' then
        ACT_MGM_TOTAL_BY_PERIOD.MgmReportManagement(NextYearId);
      end if;

      fetch ActiveYear into NextYearId;

    end loop;

  end GenerateReport;

  /**
  * Description
  *   Création des montants de report pour les comptes bilan
  */
  procedure ACT_REPORT_MANAGEMENT(FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
    LAST_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%TYPE; -- id de la derniere periode
    PERIOD_ID    ACS_PERIOD.ACS_PERIOD_ID%TYPE;
    TYPE_CUMUL   ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%TYPE;

    -- cumul des montants de l'annee précédente
    cursor LastYearCumulCursor(YearId        ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type,
                               aC_TYPE_CUMUL ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type) is
      select sum(TOT_DEBIT_LC-TOT_CREDIT_LC)    DEBIT_CREDIT_LC,
             sum(TOT_DEBIT_FC-TOT_CREDIT_FC)    DEBIT_CREDIT_FC,
             sum(TOT_DEBIT_EUR-TOT_CREDIT_EUR)  DEBIT_CREDIT_EUR,
             TOT.ACS_FINANCIAL_ACCOUNT_ID       FINANCIAL_ACCOUNT_ID,
             TOT.ACS_DIVISION_ACCOUNT_ID        DIVISION_ACCOUNT_ID,
             TOT.ACS_AUXILIARY_ACCOUNT_ID       AUXILIARY_ACCOUNT_ID,
             TOT.ACS_FINANCIAL_CURRENCY_ID      FINANCIAL_CURRENCY_ID,
             TOT.ACS_ACS_FINANCIAL_CURRENCY_ID  FINANCIAL_CURRENCY_ID2
        from ACT_TOTAL_BY_PERIOD   TOT,
             ACS_PERIOD            PER,
             ACS_FINANCIAL_ACCOUNT FIN
        where PER.ACS_FINANCIAL_YEAR_ID       = YearId
          and TOT.ACS_PERIOD_ID               = PER.ACS_PERIOD_ID
          and TOT.ACS_FINANCIAL_ACCOUNT_ID    = FIN.ACS_FINANCIAL_ACCOUNT_ID
          and FIN.C_BALANCE_SHEET_PROFIT_LOSS = 'B'
          and TOT.C_TYPE_CUMUL                = aC_TYPE_CUMUL
        group by TOT.ACS_FINANCIAL_ACCOUNT_ID,
                 TOT.ACS_DIVISION_ACCOUNT_ID,
                 TOT.ACS_AUXILIARY_ACCOUNT_ID,
                 TOT.ACS_FINANCIAL_CURRENCY_ID,
                 TOT.ACS_ACS_FINANCIAL_CURRENCY_ID,
                 TOT.C_TYPE_CUMUL;

    -- Types de cumuls financiers définis dans toutes les transactions de report
    cursor CumulOfReportTransaction is
      select distinct C_TYPE_CUMUL
        from ACJ_SUB_SET_CAT        SCA,
             ACJ_CATALOGUE_DOCUMENT CAT
        where CAT.C_TYPE_CATALOGUE          = '7'
          and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
          and SCA.C_SUB_SET in ('ACC', 'REC', 'PAY');

    LastYearCumul LastYearCumulCursor%rowtype;
    UserIni       PCS.PC_USER.USE_INI%type;

  begin

    UserIni := PCS.PC_I_LIB_SESSION.GetUserIni;

    --recherche id de l'exercice précédent
    open LAST_YEAR_CURSOR(FINANCIAL_YEAR_ID);
    fetch LAST_YEAR_CURSOR into LAST_YEAR_ID;
    close LAST_YEAR_CURSOR;

    -- Recherche de la période de report de l'exercice courant
    select ACS_PERIOD_ID into PERIOD_ID
    from ACS_PERIOD
    where ACS_FINANCIAL_YEAR_ID = FINANCIAL_YEAR_ID
      and C_TYPE_PERIOD = '1';

    open CumulOfReportTransaction;
    fetch CumulOfReportTransaction into TYPE_CUMUL;

    while CumulOfReportTransaction%found loop

      -- Recherche des cumuls de l'exercice précédent
      open LastYearCumulCursor(LAST_YEAR_ID, TYPE_CUMUL);
      fetch LastYearCumulCursor into LastYearCumul;

      while LastYearCumulCursor%found loop

        if (LastYearCumul.DEBIT_CREDIT_LC <> 0) or (LastYearCumul.DEBIT_CREDIT_FC <> 0) then

          if LastYearCumul.DEBIT_CREDIT_LC > 0 then

            insert into ACT_TOTAL_BY_PERIOD
              (ACT_TOTAL_BY_PERIOD_ID,
               ACS_PERIOD_ID,
               TOT_DEBIT_LC,
               TOT_DEBIT_FC,
               TOT_DEBIT_EUR,
               TOT_CREDIT_LC,
               TOT_CREDIT_FC,
               TOT_CREDIT_EUR,
               ACS_FINANCIAL_ACCOUNT_ID,
               ACS_DIVISION_ACCOUNT_ID,
               ACS_AUXILIARY_ACCOUNT_ID,
               ACS_FINANCIAL_CURRENCY_ID,
               ACS_ACS_FINANCIAL_CURRENCY_ID,
               C_TYPE_PERIOD,
               C_TYPE_CUMUL,
               A_DATECRE,
               A_IDCRE)

            values
              (INIT_ID_SEQ.NEXTVAL,
               PERIOD_ID,
               LastYearCumul.DEBIT_CREDIT_LC,
               LastYearCumul.DEBIT_CREDIT_FC,
               LastYearCumul.DEBIT_CREDIT_EUR,
               0,
               0,
               0,
               LastYearCumul.FINANCIAL_ACCOUNT_ID,
               LastYearCumul.DIVISION_ACCOUNT_ID,
               LastYearCumul.AUXILIARY_ACCOUNT_ID,
               LastYearCumul.FINANCIAL_CURRENCY_ID,
               LastYearCumul.FINANCIAL_CURRENCY_ID2,
               '1',
               TYPE_CUMUL,
               SYSDATE,
               UserIni);

          else

            insert into ACT_TOTAL_BY_PERIOD
              (ACT_TOTAL_BY_PERIOD_ID,
               ACS_PERIOD_ID,
               TOT_DEBIT_LC,
               TOT_DEBIT_FC,
               TOT_DEBIT_EUR,
               TOT_CREDIT_LC,
               TOT_CREDIT_FC,
               TOT_CREDIT_EUR,
               ACS_FINANCIAL_ACCOUNT_ID,
               ACS_DIVISION_ACCOUNT_ID,
               ACS_AUXILIARY_ACCOUNT_ID,
               ACS_FINANCIAL_CURRENCY_ID,
               ACS_ACS_FINANCIAL_CURRENCY_ID,
               C_TYPE_PERIOD,
               C_TYPE_CUMUL,
               A_DATECRE,
               A_IDCRE)

            values
              (INIT_ID_SEQ.NEXTVAL,
               PERIOD_ID,
               0,
               0,
               0,
               - LastYearCumul.DEBIT_CREDIT_LC,
               - LastYearCumul.DEBIT_CREDIT_FC,
               - LastYearCumul.DEBIT_CREDIT_EUR,
               LastYearCumul.FINANCIAL_ACCOUNT_ID,
               LastYearCumul.DIVISION_ACCOUNT_ID,
               LastYearCumul.AUXILIARY_ACCOUNT_ID,
               LastYearCumul.FINANCIAL_CURRENCY_ID,
               LastYearCumul.FINANCIAL_CURRENCY_ID2,
               '1',
               TYPE_CUMUL,
               SYSDATE,
               UserIni);

          end if;

        end if;

        fetch LastYearCumulCursor into LastYearCumul;

      end loop;

      close LastYearCumulCursor;

      fetch CumulOfReportTransaction into TYPE_CUMUL;

    end loop;

    close CumulOfReportTransaction;

  end ACT_REPORT_MANAGEMENT;


  /**
  * Description
  *   Génération des documents de report financiers et analytiques
  */
  procedure CreateReportDocuments(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                                  aACS_FINANCIAL_ACCOUNT_ID  ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type,
                                  aIMF_DESCRIPTION           ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type)
  is

    CurrencyId       ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    YearId           ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    YearToCloseId    ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    JournalId        ACT_JOURNAL.ACT_JOURNAL_ID%type;
    PeriodId         ACS_PERIOD.ACS_PERIOD_ID%type;
    DivisionSubSetId ACS_SUB_SET.ACS_SUB_SET_ID%type;
    UserIni          PCS.PC_USER.USE_INI%type;
    BeginDate        date;

    TypeCumul        ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type;
    CatalogId        ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;

    ------ Id de l'année et Id journal pour le travail courant
    cursor YearAndJournalOfJob(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type,
                               aC_TYPE_ACCOUNTING ACS_ACCOUNTING.C_TYPE_ACCOUNTING%type) is
      select JOB.ACS_FINANCIAL_YEAR_ID,
             JOU.ACT_JOURNAL_ID
        from ACT_JOB        JOB,
             ACT_JOURNAL    JOU,
             ACS_ACCOUNTING ACC
        where JOB.ACT_JOB_ID        = aACT_JOB_ID
          and JOB.ACT_JOB_ID        = JOU.ACT_JOB_ID
          and JOU.ACS_ACCOUNTING_ID = ACC.ACS_ACCOUNTING_ID
          and ACC.C_TYPE_ACCOUNTING = aC_TYPE_ACCOUNTING;

    -- Types de cumuls financiers définis dans toutes les transactions de report du modèle de travail courant
    cursor CumulOfReportTransaction(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) is
      select distinct
           C_TYPE_CUMUL,
           CAT.ACJ_CATALOGUE_DOCUMENT_ID
      from
           ACJ_SUB_SET_CAT          SCA,
           ACJ_CATALOGUE_DOCUMENT   CAT,
           ACJ_JOB_TYPE_S_CATALOGUE JSC,
           ACT_JOB                  JOB
      where
            JOB.ACT_JOB_ID                = aACT_JOB_ID
        and JOB.ACJ_JOB_TYPE_ID           = JSC.ACJ_JOB_TYPE_ID
        and JSC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
        and CAT.C_TYPE_CATALOGUE          = '7'
        and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
        and SCA.C_SUB_SET in ('ACC', 'REC', 'PAY');

    -- Types de cumuls analytiques définis dans toutes les transactions de report du modèle de travail courant
    cursor CumulOfMgmReportTransaction(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) is
      select distinct
           C_TYPE_CUMUL,
           CAT.ACJ_CATALOGUE_DOCUMENT_ID
      from
           ACJ_SUB_SET_CAT          SCA,
           ACJ_CATALOGUE_DOCUMENT   CAT,
           ACJ_JOB_TYPE_S_CATALOGUE JSC,
           ACT_JOB                  JOB
      where
            JOB.ACT_JOB_ID                = aACT_JOB_ID
        and JOB.ACJ_JOB_TYPE_ID           = JSC.ACJ_JOB_TYPE_ID
        and JSC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
        and CAT.C_TYPE_CATALOGUE          = '7'
        and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
        and SCA.C_SUB_SET = 'CPN';

  -----
  begin

    ------ Id de la monnaie de base
    CurrencyId := ACS_FUNCTION.GetLocalCurrencyID;
    if CurrencyId is null then
      raise_application_error(-20000,'PCS - NO LOCAL CURRENCY DEFINED');
    end if;

    open YearAndJournalOfJob(aACT_JOB_ID, 'FIN');
    fetch YearAndJournalOfJob into YearId, JournalId;
    close YearAndJournalOfJob;

    -- Recherche date de début d'exercice
    begin
      select FYE_START_DATE into BeginDate
       from ACS_FINANCIAL_YEAR
       where ACS_FINANCIAL_YEAR_ID = YearId;
    exception
      when NO_DATA_FOUND then
        raise_application_error(-20000,'PCS - AUCUN JOURNAL');
    end;

    -- Recherche période d'ouverture
    select max(ACS_PERIOD_ID) into PeriodId
      from ACS_PERIOD
      where ACS_FINANCIAL_YEAR_ID = YearId
        and C_TYPE_PERIOD         = '1';

    -- Recherche Id de l'exercice précédent
    open LAST_YEAR_CURSOR(YearId);
    fetch LAST_YEAR_CURSOR into YearToCloseId;
    close LAST_YEAR_CURSOR;

    -- Recherche si on gère les comptes division (départements)
    select max(ACS_SUB_SET_ID) into DivisionSubSetId
      from ACS_SUB_SET
      where C_TYPE_SUB_SET = 'DIVI';

    -- Initiales utilisateur courant
    UserIni := PCS.PC_I_LIB_SESSION.GetUserIni;

    open CumulOfReportTransaction(aACT_JOB_ID);
    fetch CumulOfReportTransaction into TypeCumul, CatalogId;

    -- Création des documents de report financiers (EXT/INT)
    while CumulOfReportTransaction%found loop

      CreateReportDocument(aACT_JOB_ID,
                           CatalogId,
                           aACS_FINANCIAL_ACCOUNT_ID,
                           aIMF_DESCRIPTION,
                           CurrencyId,
                           YearId,
                           JournalId,
                           BeginDate,
                           PeriodId,
                           YearToCloseId,
                           DivisionSubSetId,
                           UserIni,
                           TypeCumul);

      fetch CumulOfReportTransaction into TypeCumul, CatalogId;

    end loop;

    close CumulOfReportTransaction;

    open YearAndJournalOfJob(aACT_JOB_ID, 'MAN');
    fetch YearAndJournalOfJob into YearId, JournalId;
    close YearAndJournalOfJob;

    if JournalId is not null then

      open CumulOfMgmReportTransaction(aACT_JOB_ID);
      fetch CumulOfMgmReportTransaction into TypeCumul, CatalogId;

      -- Création des documents de report analytiques (PRI/SEC/SIM)
      while CumulOfMgmReportTransaction%found loop

        CreateMgmReportDocument(aACT_JOB_ID,
                                CatalogId,
                                aIMF_DESCRIPTION,
                                CurrencyId,
                                YearId,
                                JournalId,
                                BeginDate,
                                PeriodId,
                                YearToCloseId,
                                UserIni,
                                TypeCumul);

        fetch CumulOfMgmReportTransaction into TypeCumul, CatalogId;

      end loop;

      close CumulOfMgmReportTransaction;

    end if;

    update ACS_PERIOD
      set C_STATE_PERIOD = 'CLO'
      where ACS_FINANCIAL_YEAR_ID = YearToCloseId;

    update ACS_FINANCIAL_YEAR
      set C_STATE_FINANCIAL_YEAR = 'CLO'
      where ACS_FINANCIAL_YEAR_ID = YearToCloseId;
  end CreateReportDocuments;

  ------------------------------
  procedure CreateReportDocument(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                                 aACJ_CATALOGUE_DOCUMENT_ID ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                                 aACS_FINANCIAL_ACCOUNT_ID  ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type,
                                 aIMF_DESCRIPTION           ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type,
                                 aCurrencyId                ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
                                 aYearId                    ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type,
                                 aJournalId                 ACT_JOURNAL.ACT_JOURNAL_ID%type,
                                 aBeginDate                 date,
                                 aPeriodId                  ACS_PERIOD.ACS_PERIOD_ID%type,
                                 aYearToCloseId             ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type,
                                 aDivisionSubSetId          ACS_SUB_SET.ACS_SUB_SET_ID%type,
                                 aUserIni                   PCS.PC_USER.USE_INI%type,
                                 aTypeCumul                 ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type)
  is

    DocumentId            ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    FinancialImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    DivisionAccountId     ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;

    TotLc                 ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    TotEur                ACT_TOTAL_BY_PERIOD.TOT_DEBIT_EUR%type;

    cursor LastYearImputationCursor(YearId number, TypeCumul varchar2, WithDivision number) is
      select sum(TOT_DEBIT_LC-TOT_CREDIT_LC)   TOT_LC,
             sum(TOT_DEBIT_FC-TOT_CREDIT_FC)   TOT_FC,
             sum(TOT_DEBIT_EUR-TOT_CREDIT_EUR) TOT_EUR,
             TOT.ACS_FINANCIAL_ACCOUNT_ID,
             TOT.ACS_AUXILIARY_ACCOUNT_ID,
             TOT.ACS_DIVISION_ACCOUNT_ID,
             TOT.ACS_FINANCIAL_CURRENCY_ID,
             TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
        from ACT_TOTAL_BY_PERIOD   TOT,
             ACS_PERIOD            PER,
             ACS_FINANCIAL_ACCOUNT FIN
        where PER.ACS_FINANCIAL_YEAR_ID       = YearId
          and TOT.ACS_PERIOD_ID               = PER.ACS_PERIOD_ID
          and TOT.C_TYPE_CUMUL                = TypeCumul
          and FIN.ACS_FINANCIAL_ACCOUNT_ID    = TOT.ACS_FINANCIAL_ACCOUNT_ID
          and FIN.C_BALANCE_SHEET_PROFIT_LOSS = 'B'
          and ((FIN.FIN_COLLECTIVE = 1 and ACS_AUXILIARY_ACCOUNT_ID is not NULL) or FIN.FIN_COLLECTIVE = 0)
          and ((WithDivision is NULL and ACS_DIVISION_ACCOUNT_ID is NULL) or (WithDivision is not null and ACS_DIVISION_ACCOUNT_ID is not null))
        group by TOT.ACS_FINANCIAL_ACCOUNT_ID,
                 TOT.ACS_AUXILIARY_ACCOUNT_ID,
                 TOT.ACS_DIVISION_ACCOUNT_ID,
                 TOT.ACS_FINANCIAL_CURRENCY_ID,
                 TOT.ACS_ACS_FINANCIAL_CURRENCY_ID;

    LastYearImputation LastYearImputationCursor%rowtype;

  begin

    -- Imputations financière ACT_FINANCIAL_IMPUTATION -> Ecritures secondaires
    open LastYearImputationCursor(aYearToCloseId, aTypeCumul, aDivisionSubSetId);
    fetch LastYearImputationCursor into LastYearImputation;

    if LastYearImputationCursor%found then

      select INIT_ID_SEQ.NEXTVAL into DocumentId
        from dual;

      -- Document - ACT_DOCUMENT
      insert into ACT_DOCUMENT
        (ACT_DOCUMENT_ID,
         ACT_JOB_ID,
         PC_USER_ID,
         DOC_NUMBER,
         DOC_TOTAL_AMOUNT_DC,
         DOC_TOTAL_AMOUNT_EUR,
         DOC_DOCUMENT_DATE,
         ACS_FINANCIAL_CURRENCY_ID,
         ACJ_CATALOGUE_DOCUMENT_ID,
         ACT_JOURNAL_ID,
         ACT_ACT_JOURNAL_ID,
         ACS_FINANCIAL_ACCOUNT_ID,
         DOC_ACCOUNT_ID,
         DOC_CHARGES_LC,
         ACS_FINANCIAL_YEAR_ID,
         DOC_COMMENT,
         DOC_CCP_TAX,
         DOC_ORDER_NO,
         DOC_EFFECTIVE_DATE,
         DOC_EXECUTIVE_DATE,
         DOC_ESTABL_DATE,
         C_STATUS_DOCUMENT,
         COM_OLE_ID,
         DIC_DOC_SOURCE_ID,
         DIC_DOC_DESTINATION_ID,
         ACS_FIN_ACC_S_PAYMENT_ID,
         A_CONFIRM,
         A_DATECRE,
         A_DATEMOD,
         A_IDCRE,
         A_IDMOD,
         A_RECSTATUS,
         A_RECLEVEL
        )
      values
        (DocumentId,
         aACT_JOB_ID,
         null,
         null,
         null,
         null,
         aBeginDate,
         aCurrencyId,
         aACJ_CATALOGUE_DOCUMENT_ID,
         aJournalId,
         null,
         null,
         null,
         null,
         aYearId,
         null,
         null,
         null,
         null,
         null,
         null,
         'PROV',
         null,
         null,
         null,
         null,
         null,
         sysdate,
         null,
         aUserIni,
         null,
         null,
         null
        );

      ACT_CLAIMS_MANAGEMENT.SetDocNumber(aACT_JOB_ID);

      TotLc  := 0;
      TotEur := 0;

      while LastYearImputationCursor%found loop

        if (LastYearImputation.TOT_LC <> 0) or (LastYearImputation.TOT_FC <> 0) then

          select INIT_ID_SEQ.NEXTVAL into FinancialImputationId
            from dual;

          if LastYearImputation.TOT_LC > 0 then

            insert into ACT_FINANCIAL_IMPUTATION
              (ACT_FINANCIAL_IMPUTATION_ID,
               ACS_PERIOD_ID,
               ACT_DOCUMENT_ID,
               ACS_FINANCIAL_ACCOUNT_ID,
               IMF_TYPE,
               IMF_PRIMARY,
               IMF_DESCRIPTION,
               IMF_AMOUNT_LC_D,
               IMF_AMOUNT_LC_C,
               IMF_EXCHANGE_RATE,
               IMF_AMOUNT_FC_D,
               IMF_AMOUNT_FC_C,
               IMF_AMOUNT_EUR_D,
               IMF_AMOUNT_EUR_C,
               IMF_VALUE_DATE,
               ACS_TAX_CODE_ID,
               IMF_TRANSACTION_DATE,
               ACS_AUXILIARY_ACCOUNT_ID,
               ACT_DET_PAYMENT_ID,
               IMF_GENRE,
               IMF_BASE_PRICE,
               ACS_FINANCIAL_CURRENCY_ID,
               ACS_ACS_FINANCIAL_CURRENCY_ID,
               C_GENRE_TRANSACTION,
               IMF_NUMBER,
               A_CONFIRM,
               A_DATECRE,
               A_DATEMOD,
               A_IDCRE,
               A_IDMOD,
               A_RECLEVEL,
               A_RECSTATUS,
               ACT_PART_IMPUTATION_ID
              )
            values
              (FinancialImputationId,
               aPeriodId,
               DocumentId,
               LastYearImputation.ACS_FINANCIAL_ACCOUNT_ID,
               'MAN', -- IMF_TYPE,
               0,     -- IMF_PRIMARY
               aIMF_DESCRIPTION,
               LastYearImputation.TOT_LC, -- IMF_AMOUNT_LC_D,
               0, -- IMF_AMOUNT_LC_C,
               0, -- IMF_EXCHANGE_RATE,
               LastYearImputation.TOT_FC, -- IMF_AMOUNT_FC_D,
               0, -- IMF_AMOUNT_FC_C,
               LastYearImputation.TOT_EUR, -- IMF_AMOUNT_EUR_D,
               0, -- IMF_AMOUNT_EUR_C,
               aBeginDate, --IMF_VALUE_DATE,
               null, --ACS_TAX_CODE_ID,
               aBeginDate, --IMF_TRANSACTION_DATE,
               LastYearImputation.ACS_AUXILIARY_ACCOUNT_ID,
               null, --ACT_DET_PAYMENT_ID,
               'STD', -- IMF_GENRE,
               0, -- IMF_BASE_PRICE,
               LastYearImputation.ACS_ACS_FINANCIAL_CURRENCY_ID, -- ACS_FINANCIAL_CURRENCY_ID,
               LastYearImputation.ACS_FINANCIAL_CURRENCY_ID,     -- ACS_ACS_FINANCIAL_CURRENCY_ID
               '1',  -- C_GENRE_TRANSACTION,
               null, -- IMF_NUMBER,
               null,
               sysdate,
               null,
               aUserIni,
               null,
               null,
               null,
               null -- ACT_PART_IMPUTATION_ID
              );

            if LastYearImputation.ACS_DIVISION_ACCOUNT_ID is not null then

              insert into ACT_FINANCIAL_DISTRIBUTION
                (ACT_FINANCIAL_DISTRIBUTION_ID,
                 ACT_FINANCIAL_IMPUTATION_ID,
                 FIN_DESCRIPTION,
                 FIN_AMOUNT_LC_D,
                 FIN_AMOUNT_FC_D,
                 FIN_AMOUNT_EUR_D,
                 ACS_SUB_SET_ID,
                 FIN_AMOUNT_LC_C,
                 FIN_AMOUNT_FC_C,
                 FIN_AMOUNT_EUR_C,
                 ACS_DIVISION_ACCOUNT_ID,
                 A_CONFIRM,
                 A_DATECRE,
                 A_DATEMOD,
                 A_IDCRE,
                 A_IDMOD,
                 A_RECLEVEL,
                 A_RECSTATUS)
              values
                (INIT_ID_SEQ.NEXTVAL,
                 FinancialImputationId,
                 aIMF_DESCRIPTION,
                 LastYearImputation.TOT_LC,  -- FIN_AMOUNT_LC_D
                 LastYearImputation.TOT_FC,  -- FIN_AMOUNT_FC_D
                 LastYearImputation.TOT_EUR, -- FIN_AMOUNT_EUR_D
                 aDivisionSubSetId,
                 0, -- FIN_AMOUNT_LC_C,
                 0, -- FIN_AMOUNT_FC_C,
                 0, -- FIN_AMOUNT_EUR_C,
                 LastYearImputation.ACS_DIVISION_ACCOUNT_ID,
                 null,
                 sysdate,
                 null,
                 aUserIni,
                 null,
                 null,
                 null);

            end if;

          else

            insert into ACT_FINANCIAL_IMPUTATION
              (ACT_FINANCIAL_IMPUTATION_ID,
               ACS_PERIOD_ID,
               ACT_DOCUMENT_ID,
               ACS_FINANCIAL_ACCOUNT_ID,
               IMF_TYPE,
               IMF_PRIMARY,
               IMF_DESCRIPTION,
               IMF_AMOUNT_LC_D,
               IMF_AMOUNT_LC_C,
               IMF_EXCHANGE_RATE,
               IMF_AMOUNT_FC_D,
               IMF_AMOUNT_FC_C,
               IMF_AMOUNT_EUR_D,
               IMF_AMOUNT_EUR_C,
               IMF_VALUE_DATE,
               ACS_TAX_CODE_ID,
               IMF_TRANSACTION_DATE,
               ACS_AUXILIARY_ACCOUNT_ID,
               ACT_DET_PAYMENT_ID,
               IMF_GENRE,
               IMF_BASE_PRICE,
               ACS_FINANCIAL_CURRENCY_ID,
               ACS_ACS_FINANCIAL_CURRENCY_ID,
               C_GENRE_TRANSACTION,
               IMF_NUMBER,
               A_CONFIRM,
               A_DATECRE,
               A_DATEMOD,
               A_IDCRE,
               A_IDMOD,
               A_RECLEVEL,
               A_RECSTATUS,
               ACT_PART_IMPUTATION_ID
              )
            values
              (FinancialImputationId,
               aPeriodId,
               DocumentId,
               LastYearImputation.ACS_FINANCIAL_ACCOUNT_ID,
               'MAN', -- IMF_TYPE,
               0,    -- IMF_PRIMARY
               aIMF_DESCRIPTION,
               0, -- IMF_AMOUNT_LC_D,
               - LastYearImputation.TOT_LC,  -- IMF_AMOUNT_LC_C,
               0, -- IMF_EXCHANGE_RATE,
               0, -- IMF_AMOUNT_FC_D,
               - LastYearImputation.TOT_FC,  -- IMF_AMOUNT_FC_C,
               0, -- IMF_AMOUNT_EUR_D,
               - LastYearImputation.TOT_EUR, -- IMF_AMOUNT_EUR_C,
               aBeginDate, --IMF_VALUE_DATE,
               null, --ACS_TAX_CODE_ID,
               aBeginDate, --IMF_TRANSACTION_DATE,
               LastYearImputation.ACS_AUXILIARY_ACCOUNT_ID,
               null, --ACT_DET_PAYMENT_ID,
               'STD', -- IMF_GENRE,
               0, -- IMF_BASE_PRICE,
               LastYearImputation.ACS_ACS_FINANCIAL_CURRENCY_ID, -- ACS_FINANCIAL_CURRENCY_ID,
               LastYearImputation.ACS_FINANCIAL_CURRENCY_ID,     -- ACS_ACS_FINANCIAL_CURRENCY_ID
               '1', -- C_GENRE_TRANSACTION,
               null, -- IMF_NUMBER,
               null,
               sysdate,
               null,
               aUserIni,
               null,
               null,
               null,
               null -- ACT_PART_IMPUTATION_ID
              );

            if LastYearImputation.ACS_DIVISION_ACCOUNT_ID is not null then

              insert into ACT_FINANCIAL_DISTRIBUTION
                (ACT_FINANCIAL_DISTRIBUTION_ID,
                 ACT_FINANCIAL_IMPUTATION_ID,
                 FIN_DESCRIPTION,
                 FIN_AMOUNT_LC_D,
                 FIN_AMOUNT_FC_D,
                 FIN_AMOUNT_EUR_D,
                 ACS_SUB_SET_ID,
                 FIN_AMOUNT_LC_C,
                 FIN_AMOUNT_FC_C,
                 FIN_AMOUNT_EUR_C,
                 ACS_DIVISION_ACCOUNT_ID,
                 A_CONFIRM,
                 A_DATECRE,
                 A_DATEMOD,
                 A_IDCRE,
                 A_IDMOD,
                 A_RECLEVEL,
                 A_RECSTATUS)
              values
                (INIT_ID_SEQ.NEXTVAL,
                 FinancialImputationId,
                 aIMF_DESCRIPTION,
                 0, -- FIN_AMOUNT_LC_D
                 0, -- FIN_AMOUNT_FC_D
                 0, -- FIN_AMOUNT_EUR_D
                 aDivisionSubSetId,
                 - LastYearImputation.TOT_LC,  -- FIN_AMOUNT_LC_C,
                 - LastYearImputation.TOT_FC,  -- FIN_AMOUNT_FC_C,
                 - LastYearImputation.TOT_EUR, -- FIN_AMOUNT_EUR_C,
                 LastYearImputation.ACS_DIVISION_ACCOUNT_ID,
                 null,
                 sysdate,
                 null,
                 aUserIni,
                 null,
                 null,
                 null);

            end if;

          end if;

          TotLc  := TotLc  + LastYearImputation.TOT_LC;
          TotEur := TotEur + LastYearImputation.TOT_EUR;

        end if;

        fetch LastYearImputationCursor into LastYearImputation;

      end loop;

      -- Imputations financière ACT_FINANCIAL_IMPUTATION -> Ecriture primaire
      select INIT_ID_SEQ.NEXTVAL into FinancialImputationId
        from dual;

      if TotLc > 0 then

        insert into ACT_FINANCIAL_IMPUTATION
          (ACT_FINANCIAL_IMPUTATION_ID,
           ACS_PERIOD_ID,
           ACT_DOCUMENT_ID,
           ACS_FINANCIAL_ACCOUNT_ID,
           IMF_TYPE,
           IMF_PRIMARY,
           IMF_DESCRIPTION,
           IMF_AMOUNT_LC_D,
           IMF_AMOUNT_LC_C,
           IMF_EXCHANGE_RATE,
           IMF_AMOUNT_FC_D,
           IMF_AMOUNT_FC_C,
           IMF_AMOUNT_EUR_D,
           IMF_AMOUNT_EUR_C,
           IMF_VALUE_DATE,
           ACS_TAX_CODE_ID,
           IMF_TRANSACTION_DATE,
           ACS_AUXILIARY_ACCOUNT_ID,
           ACT_DET_PAYMENT_ID,
           IMF_GENRE,
           IMF_BASE_PRICE,
           ACS_FINANCIAL_CURRENCY_ID,
           ACS_ACS_FINANCIAL_CURRENCY_ID,
           C_GENRE_TRANSACTION,
           IMF_NUMBER,
           A_CONFIRM,
           A_DATECRE,
           A_DATEMOD,
           A_IDCRE,
           A_IDMOD,
           A_RECLEVEL,
           A_RECSTATUS,
           ACT_PART_IMPUTATION_ID
          )
        values
          (FinancialImputationId,
           aPeriodId,
           DocumentId,
           aACS_FINANCIAL_ACCOUNT_ID,
           'MAN', -- IMF_TYPE,
           1,    -- IMF_PRIMARY
           aIMF_DESCRIPTION,
           0,  -- IMF_AMOUNT_LC_D,
           TotLc, -- IMF_AMOUNT_LC_C,
           0,  -- IMF_EXCHANGE_RATE,
           0,  -- IMF_AMOUNT_FC_D,
           0, -- IMF_AMOUNT_FC_C,
           0, -- IMF_AMOUNT_EUR_D,
           0, -- IMF_AMOUNT_EUR_C,
           aBeginDate, --IMF_VALUE_DATE,
           null, --ACS_TAX_CODE_ID,
           aBeginDate, --IMF_TRANSACTION_DATE,
           null, -- ACS_AUXILIARY_ACCOUNT_ID,
           null, --ACT_DET_PAYMENT_ID,
           'STD', -- IMF_GENRE,
           0, -- IMF_BASE_PRICE,
           aCurrencyId, -- ACS_FINANCIAL_CURRENCY_ID,
           aCurrencyId, -- ACS_ACS_FINANCIAL_CURRENCY_ID
           '1', -- C_GENRE_TRANSACTION,
           null, -- IMF_NUMBER,
           null,
           sysdate,
           null,
           aUserIni,
           null,
           null,
           null,
           null -- ACT_PART_IMPUTATION_ID
          );

        if aDivisionSubSetId is not null then

          DivisionAccountId := ACS_FUNCTION.GetDefaultDivision;
          if DivisionAccountId is null then
            raise_application_error(-20000,'PCS - NO DEFAULT DIVISION DEFINED');
          end if;

          insert into ACT_FINANCIAL_DISTRIBUTION
            (ACT_FINANCIAL_DISTRIBUTION_ID,
             ACT_FINANCIAL_IMPUTATION_ID,
             FIN_DESCRIPTION,
             FIN_AMOUNT_LC_D,
             FIN_AMOUNT_FC_D,
             FIN_AMOUNT_EUR_D,
             ACS_SUB_SET_ID,
             FIN_AMOUNT_LC_C,
             FIN_AMOUNT_FC_C,
             FIN_AMOUNT_EUR_C,
             ACS_DIVISION_ACCOUNT_ID,
             A_CONFIRM,
             A_DATECRE,
             A_DATEMOD,
             A_IDCRE,
             A_IDMOD,
             A_RECLEVEL,
             A_RECSTATUS)
          values
            (INIT_ID_SEQ.NEXTVAL,
             FinancialImputationId,
             aIMF_DESCRIPTION,
             0, -- FIN_AMOUNT_LC_D
             0, -- FIN_AMOUNT_FC_D
             0, -- FIN_AMOUNT_EUR_D
             aDivisionSubSetId,
             TotLc,  -- FIN_AMOUNT_LC_C,
             0, -- FIN_AMOUNT_FC_C,
             0, -- FIN_AMOUNT_EUR_C,
             DivisionAccountId,
             null,
             sysdate,
             null,
             aUserIni,
             null,
             null,
             null);

        end if;

      else

        insert into ACT_FINANCIAL_IMPUTATION
          (ACT_FINANCIAL_IMPUTATION_ID,
           ACS_PERIOD_ID,
           ACT_DOCUMENT_ID,
           ACS_FINANCIAL_ACCOUNT_ID,
           IMF_TYPE,
           IMF_PRIMARY,
           IMF_DESCRIPTION,
           IMF_AMOUNT_LC_D,
           IMF_AMOUNT_LC_C,
           IMF_EXCHANGE_RATE,
           IMF_AMOUNT_FC_D,
           IMF_AMOUNT_FC_C,
           IMF_AMOUNT_EUR_D,
           IMF_AMOUNT_EUR_C,
           IMF_VALUE_DATE,
           ACS_TAX_CODE_ID,
           IMF_TRANSACTION_DATE,
           ACS_AUXILIARY_ACCOUNT_ID,
           ACT_DET_PAYMENT_ID,
           IMF_GENRE,
           IMF_BASE_PRICE,
           ACS_FINANCIAL_CURRENCY_ID,
           ACS_ACS_FINANCIAL_CURRENCY_ID,
           C_GENRE_TRANSACTION,
           IMF_NUMBER,
           A_CONFIRM,
           A_DATECRE,
           A_DATEMOD,
           A_IDCRE,
           A_IDMOD,
           A_RECLEVEL,
           A_RECSTATUS,
           ACT_PART_IMPUTATION_ID
          )
        values
          (FinancialImputationId,
           aPeriodId,
           DocumentId,
           aACS_FINANCIAL_ACCOUNT_ID,
           'MAN', -- IMF_TYPE,
           1,    -- IMF_PRIMARY
           aIMF_DESCRIPTION,
           - TotLc, -- IMF_AMOUNT_LC_D,
           0,    -- IMF_AMOUNT_LC_C,
           0,    -- IMF_EXCHANGE_RATE,
           0, -- IMF_AMOUNT_FC_D,
           0, -- IMF_AMOUNT_FC_C,
           0, -- IMF_AMOUNT_EUR_D,
           0, -- IMF_AMOUNT_EUR_C,
           aBeginDate, --IMF_VALUE_DATE,
           null, --ACS_TAX_CODE_ID,
           aBeginDate, --IMF_TRANSACTION_DATE,
           null, -- ACS_AUXILIARY_ACCOUNT_ID,
           null, --ACT_DET_PAYMENT_ID,
           'STD', -- IMF_GENRE,
           0, -- IMF_BASE_PRICE,
           aCurrencyId, -- ACS_FINANCIAL_CURRENCY_ID,
           aCurrencyId, -- ACS_ACS_FINANCIAL_CURRENCY_ID
           '1', -- C_GENRE_TRANSACTION,
           null, -- IMF_NUMBER,
           null,
           sysdate,
           null,
           aUserIni,
           null,
           null,
           null,
           null -- ACT_PART_IMPUTATION_ID
          );

        if aDivisionSubSetId is not null then

          DivisionAccountId := ACS_FUNCTION.GetDefaultDivision;
          if DivisionAccountId is null then
            raise_application_error(-20000,'PCS - NO DEFAULT DIVISION DEFINED');
          end if;

          insert into ACT_FINANCIAL_DISTRIBUTION
            (ACT_FINANCIAL_DISTRIBUTION_ID,
             ACT_FINANCIAL_IMPUTATION_ID,
             FIN_DESCRIPTION,
             FIN_AMOUNT_LC_D,
             FIN_AMOUNT_FC_D,
             FIN_AMOUNT_EUR_D,
             ACS_SUB_SET_ID,
             FIN_AMOUNT_LC_C,
             FIN_AMOUNT_FC_C,
             FIN_AMOUNT_EUR_C,
             ACS_DIVISION_ACCOUNT_ID,
             A_CONFIRM,
             A_DATECRE,
             A_DATEMOD,
             A_IDCRE,
             A_IDMOD,
             A_RECLEVEL,
             A_RECSTATUS)
          values
            (INIT_ID_SEQ.NEXTVAL,
             FinancialImputationId,
             aIMF_DESCRIPTION,
             - TotLc,  -- FIN_AMOUNT_LC_D
             0,  -- FIN_AMOUNT_FC_D
             0,  -- FIN_AMOUNT_EUR_D
             aDivisionSubSetId,
             0, -- FIN_AMOUNT_LC_C,
             0, -- FIN_AMOUNT_FC_C,
             0, -- FIN_AMOUNT_EUR_C,
             DivisionAccountId,
             null,
             sysdate,
             null,
             aUserIni,
             null,
             null,
             null);

        end if;

      end if;

      update ACT_DOCUMENT
        set DOC_TOTAL_AMOUNT_DC  = TotLc,
            DOC_TOTAL_AMOUNT_EUR = TotEur
        where ACT_DOCUMENT_ID = DocumentId;

    end if;

    close LastYearImputationCursor;

  end CreateReportDocument;

  ---------------------------------
  procedure CreateMgmReportDocument(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                                    aACJ_CATALOGUE_DOCUMENT_ID ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                                    aIMM_DESCRIPTION           ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type,
                                    aCurrencyId                ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
                                    aYearId                    ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type,
                                    aJournalId                 ACT_JOURNAL.ACT_JOURNAL_ID%type,
                                    aBeginDate                 date,
                                    aPeriodId                  ACS_PERIOD.ACS_PERIOD_ID%type,
                                    aYearToCloseId             ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type,
                                    aUserIni                   PCS.PC_USER.USE_INI%type,
                                    aTypeCumul                 ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type)
  is

    -- cumul des montants pour l'exercice comptable précédent
    cursor LastYearMgmImputationCursor(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type,
                                       aC_TYPE_CUMUL          ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type) is
      select sum(MTO_DEBIT_LC-MTO_CREDIT_LC)    DEBIT_CREDIT_LC,
             sum(MTO_DEBIT_FC-MTO_CREDIT_FC)    DEBIT_CREDIT_FC,
             sum(MTO_DEBIT_EUR-MTO_CREDIT_EUR)  DEBIT_CREDIT_EUR,
             sum(MTO_QUANTITY_D-MTO_QUANTITY_C) QUANTITY_D_C,
             TOT.ACS_CPN_ACCOUNT_ID             CPN_ACCOUNT_ID,
             TOT.ACS_CDA_ACCOUNT_ID             CDA_ACCOUNT_ID,
             TOT.ACS_PF_ACCOUNT_ID              PF_ACCOUNT_ID,
             TOT.ACS_PJ_ACCOUNT_ID              PJ_ACCOUNT_ID,
             TOT.ACS_QTY_UNIT_ID                QTY_UNIT_ID,
             TOT.DOC_RECORD_ID                  DOC_RECORD_ID,
             TOT.ACS_FINANCIAL_ACCOUNT_ID       FINANCIAL_ACCOUNT_ID,
             TOT.ACS_DIVISION_ACCOUNT_ID        DIVISION_ACCOUNT_ID ,
             TOT.ACS_FINANCIAL_CURRENCY_ID      FINANCIAL_CURRENCY_ID,
             TOT.ACS_ACS_FINANCIAL_CURRENCY_ID  F_FINANCIAL_CURRENCY_ID,
             TOT.C_TYPE_CUMUL                   TYPE_CUMUL
        from ACT_MGM_TOT_BY_PERIOD TOT,
             ACS_PERIOD            PER
        where PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
          and TOT.ACS_PERIOD_ID         = PER.ACS_PERIOD_ID
          and TOT.C_TYPE_CUMUL          = aC_TYPE_CUMUL
          and ( ( ACT_MGM_TOTAL_BY_PERIOD.ReportManagement(TOT.ACS_FINANCIAL_ACCOUNT_ID, TOT.ACS_PJ_ACCOUNT_ID) = 1)
          or (ACT_MGM_TOTAL_BY_PERIOD.CpnReportManagement(TOT.ACS_CPN_ACCOUNT_ID) = 1))
        group by TOT.ACS_CPN_ACCOUNT_ID,
                 TOT.ACS_CDA_ACCOUNT_ID,
                 TOT.ACS_PF_ACCOUNT_ID,
                 TOT.ACS_PJ_ACCOUNT_ID,
                 TOT.ACS_QTY_UNIT_ID,
                 TOT.DOC_RECORD_ID,
                 TOT.ACS_FINANCIAL_ACCOUNT_ID,
                 TOT.ACS_DIVISION_ACCOUNT_ID,
                 TOT.ACS_FINANCIAL_CURRENCY_ID,
                 TOT.ACS_ACS_FINANCIAL_CURRENCY_ID,
                 TOT.C_TYPE_CUMUL;


    DocumentId            ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    MgmImputationId       ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    SubSetId              ACS_SUB_SET.ACS_SUB_SET_ID%type;

    TotLc                 ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    TotEur                ACT_TOTAL_BY_PERIOD.TOT_DEBIT_EUR%type;

    LastYearMgmImputation LastYearMgmImputationCursor%rowtype;

  begin

    -- Imputations analytiques ACT_MGM_IMPUTATION  - ACT_MGM_DISTRIBUTION
    open LastYearMgmImputationCursor(aYearToCloseId, aTypeCumul);
    fetch LastYearMgmImputationCursor into LastYearMgmImputation;

    if LastYearMgmImputationCursor%found then

      select INIT_ID_SEQ.NEXTVAL into DocumentId
        from dual;

      -- Document - ACT_DOCUMENT
      insert into ACT_DOCUMENT
        (ACT_DOCUMENT_ID,
         ACT_JOB_ID,
         PC_USER_ID,
         DOC_NUMBER,
         DOC_TOTAL_AMOUNT_DC,
         DOC_TOTAL_AMOUNT_EUR,
         DOC_DOCUMENT_DATE,
         ACS_FINANCIAL_CURRENCY_ID,
         ACJ_CATALOGUE_DOCUMENT_ID,
         ACT_JOURNAL_ID,
         ACT_ACT_JOURNAL_ID,
         ACS_FINANCIAL_ACCOUNT_ID,
         DOC_ACCOUNT_ID,
         DOC_CHARGES_LC,
         ACS_FINANCIAL_YEAR_ID,
         DOC_COMMENT,
         DOC_CCP_TAX,
         DOC_ORDER_NO,
         DOC_EFFECTIVE_DATE,
         DOC_EXECUTIVE_DATE,
         DOC_ESTABL_DATE,
         C_STATUS_DOCUMENT,
         COM_OLE_ID,
         DIC_DOC_SOURCE_ID,
         DIC_DOC_DESTINATION_ID,
         ACS_FIN_ACC_S_PAYMENT_ID,
         A_CONFIRM,
         A_DATECRE,
         A_DATEMOD,
         A_IDCRE,
         A_IDMOD,
         A_RECSTATUS,
         A_RECLEVEL
        )
      values
        (DocumentId,
         aACT_JOB_ID,
         null,
         null,
         null,
         null,
         aBeginDate,
         aCurrencyId,
         aACJ_CATALOGUE_DOCUMENT_ID,
         null,
         aJournalId,
         null,
         null,
         null,
         aYearId,
         null,
         null,
         null,
         null,
         null,
         null,
         'PROV',
         null,
         null,
         null,
         null,
         null,
         sysdate,
         null,
         aUserIni,
         null,
         null,
         null
        );

      ACT_CLAIMS_MANAGEMENT.SetDocNumber(aACT_JOB_ID);

      TotLc  := 0;
      TotEur := 0;

      while LastYearMgmImputationCursor%found loop

        if ((LastYearMgmImputation.DEBIT_CREDIT_LC <> 0) or (LastYearMgmImputation.DEBIT_CREDIT_FC <> 0)) then
          select INIT_ID_SEQ.NEXTVAL into MgmImputationId
            from dual;

          select max(ACS_SUB_SET_ID) into SubSetId
            from ACS_ACCOUNT
            where ACS_ACCOUNT_ID = LastYearMgmImputation.PJ_ACCOUNT_ID;

          if LastYearMgmImputation.DEBIT_CREDIT_LC > 0 then

            insert into ACT_MGM_IMPUTATION
              (ACT_MGM_IMPUTATION_ID,
               ACS_FINANCIAL_CURRENCY_ID,
               ACS_ACS_FINANCIAL_CURRENCY_ID,
               ACS_PERIOD_ID,
               ACS_CPN_ACCOUNT_ID,
               ACS_CDA_ACCOUNT_ID,
               ACS_PF_ACCOUNT_ID,
               ACT_DOCUMENT_ID,
               ACT_FINANCIAL_IMPUTATION_ID,
               IMM_TYPE,
               IMM_GENRE,
               IMM_PRIMARY,
               IMM_DESCRIPTION,
               IMM_AMOUNT_LC_D,
               IMM_AMOUNT_LC_C,
               IMM_EXCHANGE_RATE,
               IMM_BASE_PRICE,
               IMM_AMOUNT_FC_D,
               IMM_AMOUNT_FC_C,
               IMM_VALUE_DATE,
               IMM_TRANSACTION_DATE,
               ACS_QTY_UNIT_ID,
               DOC_RECORD_ID,
               IMM_QUANTITY_D,
               IMM_QUANTITY_C,
               IMM_AMOUNT_EUR_D,
               IMM_AMOUNT_EUR_C,
               A_DATECRE,
               A_IDCRE)
            values
              (MgmImputationId,
               LastYearMgmImputation.F_FINANCIAL_CURRENCY_ID,
               LastYearMgmImputation.FINANCIAL_CURRENCY_ID,
               aPeriodId,
               LastYearMgmImputation.CPN_ACCOUNT_ID,
               LastYearMgmImputation.CDA_ACCOUNT_ID,
               LastYearMgmImputation.PF_ACCOUNT_ID,
               DocumentId,
               null,             -- ACT_FINANCIAL_IMPUTATION_ID
               'MAN',            -- IMM_TYPE
               'STD',            -- IMM_GENRE
               0,                -- IMM_PRIMARY
               aIMM_DESCRIPTION, -- IMM_DESCRIPTION
               LastYearMgmImputation.DEBIT_CREDIT_LC,
               0,                -- IMM_AMOUNT_LC_C
               0,                -- IMM_EXCHANGE_RATE
               0,                -- IMM_BASE_PRICE
               LastYearMgmImputation.DEBIT_CREDIT_FC,
               0,                -- IMM_AMOUNT_FC_C
               aBeginDate,
               aBeginDate,
               LastYearMgmImputation.QTY_UNIT_ID,
               LastYearMgmImputation.DOC_RECORD_ID,
               LastYearMgmImputation.QUANTITY_D_C,
               0,                -- IMM_QUANTITY_C
               LastYearMgmImputation.DEBIT_CREDIT_EUR,
               0,                --IMM_AMOUNT_EUR_C
               sysdate,
               aUserIni);

            if not LastYearMgmImputation.PJ_ACCOUNT_ID is null then
              insert into ACT_MGM_DISTRIBUTION
                (ACT_MGM_DISTRIBUTION_ID,
                 ACT_MGM_IMPUTATION_ID,
                 ACS_PJ_ACCOUNT_ID,
                 ACS_SUB_SET_ID,
                 MGM_DESCRIPTION,
                 MGM_AMOUNT_LC_D,
                 MGM_AMOUNT_FC_D,
                 MGM_AMOUNT_LC_C,
                 MGM_AMOUNT_FC_C,
                 MGM_QUANTITY_D,
                 MGM_QUANTITY_C,
                 MGM_AMOUNT_EUR_D,
                 MGM_AMOUNT_EUR_C,
                 A_DATECRE,
                 A_IDCRE)
              values
                (INIT_ID_SEQ.NEXTVAL,
                 MgmImputationId,
                 LastYearMgmImputation.PJ_ACCOUNT_ID,
                 SubSetId,
                 aIMM_DESCRIPTION,
                 LastYearMgmImputation.DEBIT_CREDIT_LC,
                 LastYearMgmImputation.DEBIT_CREDIT_FC,
                 0,   -- MGM_AMOUNT_LC_C
                 0,   -- MGM_AMOUNT_FC_C
                 LastYearMgmImputation.QUANTITY_D_C,
                 0,   -- MGM_QUANTITY_C
                 LastYearMgmImputation.DEBIT_CREDIT_EUR,
                 0,   -- MGM_AMOUNT_EUR_C
                 sysdate,
                 aUserIni);
            end if;
          else
            insert into ACT_MGM_IMPUTATION
              (ACT_MGM_IMPUTATION_ID,
               ACS_FINANCIAL_CURRENCY_ID,
               ACS_ACS_FINANCIAL_CURRENCY_ID,
               ACS_PERIOD_ID,
               ACS_CPN_ACCOUNT_ID,
               ACS_CDA_ACCOUNT_ID,
               ACS_PF_ACCOUNT_ID,
               ACT_DOCUMENT_ID,
               ACT_FINANCIAL_IMPUTATION_ID,
               IMM_TYPE,
               IMM_GENRE,
               IMM_PRIMARY,
               IMM_DESCRIPTION,
               IMM_AMOUNT_LC_D,
               IMM_AMOUNT_LC_C,
               IMM_EXCHANGE_RATE,
               IMM_BASE_PRICE,
               IMM_AMOUNT_FC_D,
               IMM_AMOUNT_FC_C,
               IMM_VALUE_DATE,
               IMM_TRANSACTION_DATE,
               ACS_QTY_UNIT_ID,
               DOC_RECORD_ID,
               IMM_QUANTITY_D,
               IMM_QUANTITY_C,
               IMM_AMOUNT_EUR_D,
               IMM_AMOUNT_EUR_C,
               A_DATECRE,
               A_IDCRE)
            values
              (MgmImputationId,
               LastYearMgmImputation.F_FINANCIAL_CURRENCY_ID,
               LastYearMgmImputation.FINANCIAL_CURRENCY_ID,
               aPeriodId,
               LastYearMgmImputation.CPN_ACCOUNT_ID,
               LastYearMgmImputation.CDA_ACCOUNT_ID,
               LastYearMgmImputation.PF_ACCOUNT_ID,
               DocumentId,
               null,             -- ACT_FINANCIAL_IMPUTATION_ID
               'MAN',            -- IMM_TYPE
               'STD',            -- IMM_GENRE
               0,                -- IMM_PRIMARY
               aIMM_DESCRIPTION, -- IMM_DESCRIPTION
               0,                -- IMM_AMOUNT_LC_D
               - LastYearMgmImputation.DEBIT_CREDIT_LC,
               0,                -- IMM_EXCHANGE_RATE
               0,                -- IMM_BASE_PRICE
               0,                -- IMM_AMOUNT_FC_D
               - LastYearMgmImputation.DEBIT_CREDIT_FC,
               aBeginDate,
               aBeginDate,
               LastYearMgmImputation.QTY_UNIT_ID,
               LastYearMgmImputation.DOC_RECORD_ID,
               0,                -- IMM_QUANTITY_D
               - LastYearMgmImputation.QUANTITY_D_C,
               0,                --IMM_AMOUNT_EUR_D
               - LastYearMgmImputation.DEBIT_CREDIT_EUR,
               sysdate,
               aUserIni);

            if not LastYearMgmImputation.PJ_ACCOUNT_ID is null then
              insert into ACT_MGM_DISTRIBUTION
                (ACT_MGM_DISTRIBUTION_ID,
                 ACT_MGM_IMPUTATION_ID,
                 ACS_PJ_ACCOUNT_ID,
                 ACS_SUB_SET_ID,
                 MGM_DESCRIPTION,
                 MGM_AMOUNT_LC_D,
                 MGM_AMOUNT_FC_D,
                 MGM_AMOUNT_LC_C,
                 MGM_AMOUNT_FC_C,
                 MGM_QUANTITY_D,
                 MGM_QUANTITY_C,
                 MGM_AMOUNT_EUR_D,
                 MGM_AMOUNT_EUR_C,
                 A_DATECRE,
                 A_IDCRE)
              values
                (INIT_ID_SEQ.NEXTVAL,
                 MgmImputationId,
                 LastYearMgmImputation.PJ_ACCOUNT_ID,
                 SubSetId,
                 aIMM_DESCRIPTION,
                 0,   -- MGM_AMOUNT_LC_D
                 0,   -- MGM_AMOUNT_FC_D
                 - LastYearMgmImputation.DEBIT_CREDIT_LC,
                 - LastYearMgmImputation.DEBIT_CREDIT_FC,
                 0,   -- MGM_QUANTITY_D
                 - LastYearMgmImputation.QUANTITY_D_C,
                 0,   -- MGM_AMOUNT_EUR_D
                 - LastYearMgmImputation.DEBIT_CREDIT_EUR,
                 sysdate,
                 aUserIni);
             end if;
          end if;

          TotLc  := TotLc  + LastYearMgmImputation.DEBIT_CREDIT_LC;
          TotEur := TotEur + LastYearMgmImputation.DEBIT_CREDIT_EUR;

        end if;

        fetch LastYearMgmImputationCursor into LastYearMgmImputation;

      end loop;

      update ACT_DOCUMENT
        set DOC_TOTAL_AMOUNT_DC  = TotLc,
            DOC_TOTAL_AMOUNT_EUR = TotEur
        where ACT_DOCUMENT_ID = DocumentId;

    end if;

    close LastYearMgmImputationCursor;

  end CreateMgmReportDocument;

  ------------------------
  procedure DocCalculation(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type,
                           aType                  number)  -- 0: Toutes, 1: Financières, 2: Analytiques
  is
    cursor YearDocumentsCursor(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    is
      select ACT_DOCUMENT_ID
      from ACT_DOCUMENT DOC,
           ACT_JOB      JOB
      where JOB.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
        and JOB.ACT_JOB_ID            = DOC.ACT_JOB_ID;

    DocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type;

  begin

    open YearDocumentsCursor(aACS_FINANCIAL_YEAR_ID);
    fetch YearDocumentsCursor into DocumentId;

    while YearDocumentsCursor%found loop

      update ACT_DOCUMENT_STATUS
        set DOC_OK = 0
        where ACT_DOCUMENT_ID = DocumentId;

      ACT_DOC_TRANSACTION.DocImputations(DocumentId, aType);

      fetch YearDocumentsCursor into DocumentId;

    end loop;

    close YearDocumentsCursor;

  end DocCalculation;

end ACT_TOTAL_CALCULATION;
