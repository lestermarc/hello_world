--------------------------------------------------------
--  DDL for Package Body ACT_MGT_DEFERRAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_MGT_DEFERRAL" 
is
  gn_ExistDivision ACS_SUB_SET.ACS_SUB_SET_ID%type;   --Indique la gestion des divisions dans le mandat
  gn_Analytical    number(1);   --Indique l'imputation analytique

  /**
  * Description
  *    Cette procedure va insérer dans la table temporaire ACT_DEFERRAL_SELECTION les imputations de lissage à extraire.
  */
  procedure ExtractImputation(
    in_ActJobID      in ACT_JOB.ACT_JOB_ID%type
  , in_AccNumberFrom in ACS_ACCOUNT.ACC_NUMBER%type
  , in_AccNumberTo   in ACS_ACCOUNT.ACC_NUMBER%type
  , id_DateFrom      in date
  , id_DateTo        in date
  , iv_DivisionID    in varchar2
  )
  is
    lvConfDeferImpDateFrom     varchar2(10)                    := regexp_substr(upper(PCS.PC_CONFIG.GetConfig('ACT_DEFERRAL_IMP_DATES') ), '[^;]+', 1, 1);
    lvConfDeferImpDateTo       varchar2(10)                    := regexp_substr(upper(PCS.PC_CONFIG.GetConfig('ACT_DEFERRAL_IMP_DATES') ), '[^;]+', 1, 2);

    cursor curDeferralExtraction(
      iAccNumberFrom ACS_ACCOUNT.ACC_NUMBER%type
    , iAccNumberTo   ACS_ACCOUNT.ACC_NUMBER%type
    , iActJobID      ACT_JOB.ACT_JOB_ID%type
    , iDateFrom      date
    , iDateTo        date
    , iDivisionID    varchar2
    )
    is
      select IMP.ACT_DOCUMENT_ID
           , IMP.ACT_FINANCIAL_IMPUTATION_ID
           , IMP.ACS_FINANCIAL_ACCOUNT_ID
           , case
               when(    (     (ACT_FUNCTIONS.IsDocumentIntegrationType(IMP.ACT_DOCUMENT_ID) = 1)
                         and (     (     (IMP.DEFER_DATE_FROM is not null)
                                    and (IMP.DEFER_DATE_TO is not null) )
                              and (ACS_PERIOD_FCT.CheckActivePeriodBetweenDates(IMP.DEFER_DATE_FROM, least(FYE.FYE_END_DATE, IMP.DEFER_DATE_TO) ) = 1)
                             )
                        )
                    or (     (ACT_FUNCTIONS.IsDocumentIntegrationType(IMP.ACT_DOCUMENT_ID) = 0)
                        and (IMP.IMF_DEFERRABLE = 1)
                        and (     (     (IMP.DEFER_DATE_FROM is not null)
                                   and (IMP.DEFER_DATE_TO is not null) )
                             and (ACS_PERIOD_FCT.CheckActivePeriodBetweenDates(IMP.DEFER_DATE_FROM, least(FYE.FYE_END_DATE, IMP.DEFER_DATE_TO) ) = 1)
                            )
                       )
                   ) then 1
               else 0
             end ADS_SELECT
           , case
               when(     (IMP.DEFER_DATE_FROM is not null)
                    and (IMP.DEFER_DATE_TO is not null) ) then ACS_PERIOD_FCT.CheckActivePeriodBetweenDates(IMP.DEFER_DATE_FROM
                                                                                                          , least(FYE.FYE_END_DATE, IMP.DEFER_DATE_TO)
                                                                                                           )
               else 0
             end ADS_READ_WRITE
        from (select case lvConfDeferImpDateFrom
                       when 'IMF_DATE1' then IMP.IMF_DATE1
                       when 'IMF_DATE2' then IMP.IMF_DATE2
                       when 'IMF_DATE3' then IMP.IMF_DATE3
                       when 'IMF_DATE4' then IMP.IMF_DATE4
                       when 'IMF_DATE5' then IMP.IMF_DATE5
                     end DEFER_DATE_FROM
                   , case lvConfDeferImpDateTo
                       when 'IMF_DATE1' then IMP.IMF_DATE1
                       when 'IMF_DATE2' then IMP.IMF_DATE2
                       when 'IMF_DATE3' then IMP.IMF_DATE3
                       when 'IMF_DATE4' then IMP.IMF_DATE4
                       when 'IMF_DATE5' then IMP.IMF_DATE5
                     end DEFER_DATE_TO
                   , IMP.IMF_DEFERRABLE
                   , IMP.IMF_TRANSACTION_DATE
                   , IMP.ACS_PERIOD_ID
                   , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   , IMP.ACT_DOCUMENT_ID
                   , IMP.ACT_FINANCIAL_IMPUTATION_ID
                   , IMP.ACS_FINANCIAL_ACCOUNT_ID
                   , IMP.ACT_LETTERING_ID
                   , IMP.IMF_AMOUNT_LC_D
                   , IMP.IMF_AMOUNT_LC_C
                from ACT_FINANCIAL_IMPUTATION IMP
               where IMP.IMF_DEFERRABLE = 1
              union
              select case lvConfDeferImpDateFrom
                       when 'IMF_DATE1' then IMP.IMF_DATE1
                       when 'IMF_DATE2' then IMP.IMF_DATE2
                       when 'IMF_DATE3' then IMP.IMF_DATE3
                       when 'IMF_DATE4' then IMP.IMF_DATE4
                       when 'IMF_DATE5' then IMP.IMF_DATE5
                     end DEFER_DATE_FROM
                   , case lvConfDeferImpDateTo
                       when 'IMF_DATE1' then IMP.IMF_DATE1
                       when 'IMF_DATE2' then IMP.IMF_DATE2
                       when 'IMF_DATE3' then IMP.IMF_DATE3
                       when 'IMF_DATE4' then IMP.IMF_DATE4
                       when 'IMF_DATE5' then IMP.IMF_DATE5
                     end DEFER_DATE_TO
                   , IMP.IMF_DEFERRABLE
                   , IMP.IMF_TRANSACTION_DATE
                   , IMP.ACS_PERIOD_ID
                   , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   , IMP.ACT_DOCUMENT_ID
                   , IMP.ACT_FINANCIAL_IMPUTATION_ID
                   , IMP.ACS_FINANCIAL_ACCOUNT_ID
                   , IMP.ACT_LETTERING_ID
                   , IMP.IMF_AMOUNT_LC_D
                   , IMP.IMF_AMOUNT_LC_C
                from ACT_FINANCIAL_IMPUTATION IMP
                   , ACS_FINANCIAL_ACCOUNT FIN
               where FIN.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                 and (    FIN.C_DEFER_AUTHORIZ_TYPE = '1'
                      and IMP.IMF_DEFERRABLE = 0) ) IMP
           , ACT_DOCUMENT DOC
           , ACS_FINANCIAL_ACCOUNT FIN
           , ACS_ACCOUNT ACC
           , ACT_JOB JOB
           , ACS_FINANCIAL_YEAR FYE
       where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and FIN.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
         and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and JOB.ACT_JOB_ID = DOC.ACT_JOB_ID
         and FYE.ACS_FINANCIAL_YEAR_ID = JOB.ACS_FINANCIAL_YEAR_ID
         and IMP.ACT_LETTERING_ID is null
         and nvl( (select case
                            when V.TAX_LIABLED_RATE = 100 then HT_LC
                          end
                     from V_ACT_DET_TAX V
                    where V.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID),(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ) ) != 0
         and not exists(select DEF.ACT_FINANCIAL_IMPUTATION_ID
                          from ACT_DEFERRAL_SELECTION DEF
                         where IMP.ACT_FINANCIAL_IMPUTATION_ID = DEF.ACT_FINANCIAL_IMPUTATION_ID)
         and (    (     (     (iDateFrom is not null)
                         and (iDateTo is not null) )
                   and (     (IMP.IMF_TRANSACTION_DATE >= iDateFrom)
                        and (IMP.IMF_TRANSACTION_DATE <= iDateTo) ) )
              or (     (     (iDateFrom is null)
                        and (iDateTo is null) )
                  and (JOB.ACS_FINANCIAL_YEAR_ID = (select JOB.ACS_FINANCIAL_YEAR_ID
                                                      from ACT_JOB JOB
                                                     where JOB.ACT_JOB_ID = iActJobID) ) )
             )
         and (   iDivisionID = '#'
              or (instr(',' || iDivisionID || ',', to_char(',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') ) > 0) )
         and ACC.ACC_NUMBER >= iAccNumberFrom
         and ACC.ACC_NUMBER <= iAccNumberTo
         and (    (     (     (IMP.DEFER_DATE_FROM is not null)
                         and (IMP.DEFER_DATE_TO is not null) )
                   and (ACS_PERIOD_FCT.GetPeriodByDate(IMP.DEFER_DATE_FROM, 2) <> ACS_PERIOD_FCT.GetPeriodByDate(IMP.DEFER_DATE_TO, 2) )
                   and ACS_FUNCTION.GetFinancialYearNo(IMP.DEFER_DATE_FROM) >= ACS_FUNCTION.GetFinancialYearNo(IMP.IMF_TRANSACTION_DATE)
                   and ACS_FUNCTION.GetFinancialYearNo(IMP.DEFER_DATE_TO) >= ACS_FUNCTION.GetFinancialYearNo(IMP.IMF_TRANSACTION_DATE)
                  )
              or (    (IMP.DEFER_DATE_FROM is null)
                  or (IMP.DEFER_DATE_TO is null) )
             )
      -- Ajout des imputations lissée partiellement de la période comptable précédant l'exercice courant.
      union all
      select IMP.ACT_DOCUMENT_ID
           , IMP.ACT_FINANCIAL_IMPUTATION_ID
           , IMP.ACS_FINANCIAL_ACCOUNT_ID
           , case
               when IMP.HAS_INACTIVE_PERIODS = 0 then 1
               else 0
             end ADS_SELECT
           , case
               when IMP.HAS_INACTIVE_PERIODS = 0 then 1
               else 0
             end ADS_READ_WRITE
        from (select distinct IMP.ACT_DOCUMENT_ID
                            , IMP.ACT_FINANCIAL_IMPUTATION_ID
                            , IMP.ACS_FINANCIAL_ACCOUNT_ID
                            , (select sign(count(*) )
                                 from ACS_PERIOD PER
                                where PER.PER_START_DATE > (select FYE.FYE_END_DATE
                                                              from ACS_FINANCIAL_YEAR FYE
                                                             where ACS_FINANCIAL_YEAR_ID = JOB.ACS_FINANCIAL_YEAR_ID)
                                  and PER.PER_END_DATE <=
                                        case lvConfDeferImpDateTo
                                          when 'IMF_DATE1' then IMP.IMF_DATE1
                                          when 'IMF_DATE2' then IMP.IMF_DATE2
                                          when 'IMF_DATE3' then IMP.IMF_DATE3
                                          when 'IMF_DATE4' then IMP.IMF_DATE4
                                          when 'IMF_DATE5' then IMP.IMF_DATE5
                                        end
                                  and PER.C_STATE_PERIOD <> 'ACT') HAS_INACTIVE_PERIODS
                         from ACT_DEFERRAL_IMPUTATION DEF
                            , ACT_FINANCIAL_IMPUTATION IMP
                            , ACT_JOB JOB
                            , ACT_DOCUMENT DOC
                        where DEF.act_financial_imputation_id = IMP.act_financial_imputation_id(+)
                          and DEF.C_ACT_DEFER_INCOMPLETE = '01'
                          and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                          and JOB.ACT_JOB_ID = DOC.ACT_JOB_ID
                          and nvl( (select case
                                             when V.TAX_LIABLED_RATE = 100 then HT_LC
                                           end
                                      from V_ACT_DET_TAX V
                                     where V.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID)
                                , (nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) )
                                 ) != 0
                          and not exists(select DEF.ACT_FINANCIAL_IMPUTATION_ID
                                           from ACT_DEFERRAL_SELECTION DEF
                                          where IMP.ACT_FINANCIAL_IMPUTATION_ID = DEF.ACT_FINANCIAL_IMPUTATION_ID)
                          and JOB.ACS_FINANCIAL_YEAR_ID = (select ACS_FINANCIAL_YEAR_FCT.GetPreviousFinancialYearID(JOB.ACS_FINANCIAL_YEAR_ID)
                                                             from ACT_JOB JOB
                                                            where JOB.ACT_JOB_ID = iActJobID) ) IMP;

    curDeferralExtractionTuple curDeferralExtraction%rowtype;
  begin
    ACT_PRC_DEFERRAL.ClearSelection(in_ActJobID);

    open curDeferralExtraction(in_AccNumberFrom, in_AccNumberTo, in_ActJobID, id_DateFrom, id_DateTo, iv_DivisionID);

    fetch curDeferralExtraction
     into curDeferralExtractionTuple;

    while curDeferralExtraction%found loop
      ACT_PRC_DEFERRAL.CreateSelection(in_ActJobID
                                     , curDeferralExtractionTuple.ACT_DOCUMENT_ID
                                     , curDeferralExtractionTuple.ACT_FINANCIAL_IMPUTATION_ID
                                     , curDeferralExtractionTuple.ACS_FINANCIAL_ACCOUNT_ID
                                     , curDeferralExtractionTuple.ADS_SELECT
                                     , curDeferralExtractionTuple.ADS_READ_WRITE
                                      );

      fetch curDeferralExtraction
       into curDeferralExtractionTuple;
    end loop;

    close curDeferralExtraction;
  end ExtractImputation;

  function IsInActivePeriod(id_Date in ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type)
    return boolean
  is
    lv_CStatePeriod ACS_PERIOD.C_STATE_PERIOD%type;
  begin
    select nvl(max(PER.C_STATE_PERIOD), 'CLO')
      into lv_CStatePeriod
      from ACS_PERIOD PER
     where id_Date between PER.PER_START_DATE and PER.PER_END_DATE
       and PER.C_TYPE_PERIOD = '2';

    return lv_CStatePeriod = 'ACT';
  end IsInActivePeriod;

  procedure GenerateMgmImputation(
    in_ActDocumentId      in     ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type
  , in_ActFinImputationId in     ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , in_AcsPeriodId        in     ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , in_AcsCpnAccountId    in     ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type
  , in_AcsCdaAccountId    in     ACT_MGM_IMPUTATION.ACS_CDA_ACCOUNT_ID%type
  , in_AcsPfAccountId     in     ACT_MGM_IMPUTATION.ACS_PF_ACCOUNT_ID%type
  , in_DocRecordId        in     ACT_MGM_IMPUTATION.DOC_RECORD_ID%type
  , iv_ImmDescription     in     ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type
  , in_ImmAmountLC        in     ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type
  , id_ImmTransactionDate in     ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type
  , on_ActMgmImputationId out    ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type
  )
  is
    ln_ActMgmImputationId ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
  begin
    ACT_PRC_ANALYTICAL_IMPUTATION.CreateDeferMgmImputation(in_ActDocumentId
                                                         , in_ActFinImputationId
                                                         , in_AcsPeriodId
                                                         , in_AcsCpnAccountId
                                                         , in_AcsCdaAccountId
                                                         , in_AcsPfAccountId
                                                         , in_DocRecordId
                                                         , iv_ImmDescription
                                                         , in_ImmAmountLC
                                                         , id_ImmTransactionDate
                                                         , ln_ActMgmImputationId
                                                          );
    on_ActMgmImputationId  := ln_ActMgmImputationId;
  end GenerateMgmImputation;

  procedure GenerateFinImputation(
    in_ActFinImputationId    in     ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , in_ActDocumentId         in     ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
  , in_ActDeferLetteringId   in     ACT_FINANCIAL_IMPUTATION.ACT_LETTERING_ID%type
  , in_AcsPeriodId           in     ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type
  , in_AcsFinancialAccountId in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type
  , in_AcsDivisionAccountId  in     ACT_FINANCIAL_IMPUTATION.IMF_ACS_DIVISION_ACCOUNT_ID%type
  , in_DocRecordId           in     ACT_FINANCIAL_IMPUTATION.DOC_RECORD_ID%type
  , in_ImfPrimary            in     ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY%type
  , iv_ImfDescription        in     ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , in_ImfAmountLC           in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , id_ImfTransactionDate    in     ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , ion_ActFinImputationId   in out ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  )
  is
  begin
    --Creation des imputations financières
    ACT_PRC_FINANCIAL_IMPUTATION.CreateDeferFinImputation(in_ActDocumentId
                                                        , in_ActDeferLetteringId
                                                        , in_AcsPeriodId
                                                        , in_AcsFinancialAccountId
                                                        , in_AcsDivisionAccountId
                                                        , in_DocRecordId
                                                        , in_ImfPrimary
                                                        , iv_ImfDescription
                                                        , in_ImfAmountLC
                                                        , id_ImfTransactionDate
                                                        , ion_ActFinImputationId
                                                         );
    --Créatio d'une position pour lier l'imputation finanière d'origine avec celle lissée
    ACT_PRC_DEFERRAL.CreateImputation(in_ActFinImputationId, ion_ActFinImputationId);

    --Création des distributions financières si divisions gérées
    if gn_ExistDivision > 0 then
      for tplDistribution in (select ACS_SUB_SET_ID
                                   , ACS_DIVISION_ACCOUNT_ID
                                from ACT_FINANCIAL_DISTRIBUTION
                               where ACT_FINANCIAL_IMPUTATION_ID = in_ActFinImputationId) loop
        ACT_PRC_FINANCIAL_IMPUTATION.CreateDeferFinDistribution(ion_ActFinImputationId
                                                              , iv_ImfDescription
                                                              , tplDistribution.ACS_SUB_SET_ID
                                                              , tplDistribution.ACS_DIVISION_ACCOUNT_ID
                                                              , in_ImfAmountLC
                                                               );
      end loop;
    end if;
  end GenerateFinImputation;

  procedure UpdateDeferFinImpAmount(
    ln_ActDeferPrimaryId in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , ln_PrimaryAmount     in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  )
  is
  begin
    ACT_PRC_FINANCIAL_IMPUTATION.UpdateDeferFinImpAmount(ln_ActDeferPrimaryId, ln_PrimaryAmount);

    if gn_ExistDivision > 0 then
      ACT_PRC_FINANCIAL_IMPUTATION.UpdateDeferFinDistribAmount(ln_ActDeferPrimaryId, ln_PrimaryAmount);
    end if;
  end UpdateDeferFinImpAmount;

  procedure GenerateJournal(
    in_ActJobId               in     ACT_DOCUMENT.ACT_JOB_ID%type
  , in_AcjCatalogueDocumentId in     ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , in_AcsFinancialYearId     in     ACT_DOCUMENT.ACS_FINANCIAL_YEAR_ID%type
  , on_ActJournalId           out    ACT_JOURNAL.ACT_JOURNAL_ID%type
  , on_ActActJournalId        out    ACT_JOURNAL.ACT_JOURNAL_ID%type
  )
  is
    ln_ActJournalId      ACT_JOURNAL.ACT_JOURNAL_ID%type;
    ln_ActJournalStateId ACT_ETAT_JOURNAL.ACT_ETAT_JOURNAL_ID%type;
    lv_JouNumber         ACT_JOURNAL.JOU_NUMBER%type;
    lv_JouDescription    ACT_JOURNAL.JOU_DESCRIPTION%type;
  begin
    on_ActJournalId     := null;
    on_ActActJournalId  := null;

    /*Création des journaux du travail*/
    for tplJournal in (select decode(ACJ_SUB_SET_CAT.C_METHOD_CUMUL, 'DIR', 'PROV', 'BRO') C_ETAT_JOURNAL
                            , ACJ_SUB_SET_CAT.C_SUB_SET
                            , ACS_ACCOUNTING.ACS_ACCOUNTING_ID
                            , ACS_ACCOUNTING.C_TYPE_ACCOUNTING
                         from ACJ_SUB_SET_CAT
                            , ACS_SUB_SET
                            , ACS_ACCOUNTING
                        where ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID = in_AcjCatalogueDocumentId
                          and ACS_SUB_SET.C_SUB_SET = ACJ_SUB_SET_CAT.C_SUB_SET
                          and ACS_ACCOUNTING.ACS_ACCOUNTING_ID = ACS_SUB_SET.ACS_ACCOUNTING_ID) loop
      if     (gn_Analytical = 0)
         and (tplJournal.C_SUB_SET = 'CPN') then
        gn_Analytical  := 1;
      end if;

      --Vérifier que le travail n'a pas déjà un journal correspondant au type de comptabilité
      select nvl(max(ACT_JOURNAL_ID), 0)
        into ln_ActJournalId
        from ACT_JOURNAL
       where ACT_JOB_ID = in_ActJobId
         and ACS_ACCOUNTING_ID = tplJournal.ACS_ACCOUNTING_ID;

      if ln_ActJournalId = 0 then
        --Réception numéro de journal
        select nvl(max(JOU_NUMBER), 0)
          into lv_JouNumber
          from ACT_JOURNAL
         where ACS_FINANCIAL_YEAR_ID = in_AcsFinancialYearId
           and ACS_ACCOUNTING_ID = tplJournal.ACS_ACCOUNTING_ID;

        --Réception description du travail
        select JOB_DESCRIPTION
          into lv_JouDescription
          from ACT_JOB
         where ACT_JOB_ID = in_ActJobId;

        ACT_PRC_DOCUMENT.CreateJournal(in_ActJobId, tplJournal.ACS_ACCOUNTING_ID, in_AcsFinancialYearId, lv_JouDescription, lv_JouNumber + 1, ln_ActJournalId);
      end if;

      --Réception  de l'état du journal du type de comptabilité courant
      select nvl(max(ACT_ETAT_JOURNAL_ID), 0)
        into ln_ActJournalStateId
        from ACT_ETAT_JOURNAL
       where ACT_JOURNAL_ID = ln_ActJournalId
         and C_SUB_SET = tplJournal.C_SUB_SET;

      --Pas d'état --> Création
      if ln_ActJournalStateId = 0 then
        ACT_PRC_DOCUMENT.CreateJournalState(ln_ActJournalId, tplJournal.C_SUB_SET, tplJournal.C_ETAT_JOURNAL);
      end if;

      --Initialisation des varaibles de retour
      if tplJournal.C_TYPE_ACCOUNTING = 'FIN' then
        on_ActJournalId  := ln_ActJournalId;
      elsif tplJournal.C_TYPE_ACCOUNTING = 'MAN' then
        on_ActActJournalId  := ln_ActJournalId;
      end if;
    end loop;
  end GenerateJournal;

  /**
  * Description
  *    Génération des document comptable de lissage
  */
  procedure GenerateDocuments(in_ActJobId in ACT_DOCUMENT.ACT_JOB_ID%type)
  is
    ln_ActDeferDocId          ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    lv_DocNumber              ACT_DOCUMENT.DOC_NUMBER%type;
    ln_ActDeferFinImpId       ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    ln_ActDeferMgmImpId       ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    ln_ActReversalImpId       ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    ln_ActDeferPrimaryId      ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    ln_ActDeferLetteringId    ACT_LETTERING.ACT_LETTERING_ID%type;
    ln_AcjCatalogueDocumentId ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    ln_ActJournalId           ACT_JOURNAL.ACT_JOURNAL_ID%type;
    ln_ActActJournalId        ACT_JOURNAL.ACT_JOURNAL_ID%type;
    lv_ConfDeferDate1         varchar2(10)                           := regexp_substr(upper(PCS.PC_CONFIG.GetConfig('ACT_DEFERRAL_IMP_DATES') ), '[^;]+', 1, 1);
    lv_ConfDeferDate2         varchar2(10)                           := regexp_substr(upper(PCS.PC_CONFIG.GetConfig('ACT_DEFERRAL_IMP_DATES') ), '[^;]+', 1, 2);
    ln_CurrentAccountId       ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
    ld_CurrentTransactionDate ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
    ld_CurrentDate1           ACT_FINANCIAL_IMPUTATION.IMF_DATE1%type;
    ld_CurrentDate2           ACT_FINANCIAL_IMPUTATION.IMF_DATE1%type;
    lv_FinImpDeferLabel       ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    lv_FinImpReversalLabel    ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    ln_AcsFinancialYearId     ACT_DOCUMENT.ACS_FINANCIAL_YEAR_ID%type;
    ln_DocTotalAmount         ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    ln_PrimaryAmount          ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    ln_ReversalAmount         ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    ln_ReversalDate           ACT_FINANCIAL_IMPUTATION.IMF_DATE1%type;
    ln_AmountToDefer          ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    ln_DeferAmount            ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    ln_ClosedPeriodAmount     ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    ln_TotalDeferDays         number(3);
    lb_DeferIncomplete        boolean;
    lb_FirstPeriod            boolean;
  begin
    lv_FinImpDeferLabel     := PCS.PC_FUNCTIONS.TranslateWord('Lissage facture ');
    lv_FinImpReversalLabel  := PCS.PC_FUNCTIONS.TranslateWord('Extourne facture ');

    select CAT.ACJ_CATALOGUE_DOCUMENT_ID
         , JOB.ACS_FINANCIAL_YEAR_ID
      into ln_AcjCatalogueDocumentId
         , ln_AcsFinancialYearId
      from ACJ_JOB_TYPE_S_CATALOGUE CAT
         , ACT_JOB JOB
     where JOB.ACT_JOB_ID = in_ActJobId
       and CAT.ACJ_JOB_TYPE_ID = JOB.ACJ_JOB_TYPE_ID
       and CAT.JCA_AVAILABLE = 1
       and rownum = 1;

    if ln_AcjCatalogueDocumentId > 0 then
      ln_ActDeferDocId           := 0;
      ln_CurrentAccountId        := 0;
      ld_CurrentTransactionDate  := null;
      ld_CurrentDate1            := null;
      ld_CurrentDate2            := null;
      ln_DocTotalAmount          := 0;
      ln_ActDeferPrimaryId       := null;
      --Génération des journaux
      GenerateJournal(in_ActJobId, ln_AcjCatalogueDocumentId, ln_AcsFinancialYearId, ln_ActJournalId, ln_ActActJournalId);

      --Parcours des imputations sélectionnées
      for tplSelectedImputations in (select   DOC.DOC_NUMBER
                                            , IMF.ACT_DOCUMENT_ID
                                            , IMF.ACT_FINANCIAL_IMPUTATION_ID
                                            , IMF.IMF_DESCRIPTION
                                            , IMF.ACS_FINANCIAL_ACCOUNT_ID
                                            , IMF.IMF_ACS_DIVISION_ACCOUNT_ID
                                            , IMF.DOC_RECORD_ID
                                            , IMF.ACT_LETTERING_ID
                                            , nvl( (select case
                                                             when V.TAX_LIABLED_RATE = 100 then HT_LC
                                                           end
                                                      from V_ACT_DET_TAX V
                                                     where V.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID)
                                                , nvl(IMF.IMF_AMOUNT_LC_D, 0) - nvl(IMF.IMF_AMOUNT_LC_C, 0)
                                                 ) IMF_AMOUNT_LC
                                            , IMF.IMF_TRANSACTION_DATE
                                            , (select ACS_DEFER_ACC_ID
                                                 from ACS_FINANCIAL_ACCOUNT
                                                where ACS_FINANCIAL_ACCOUNT_ID = SEL.ACS_FINANCIAL_ACCOUNT_ID) ACS_DEFER_ACC_ID
                                            , (select ACS_DEFER_TRA_ACC_ID
                                                 from ACS_FINANCIAL_ACCOUNT
                                                where ACS_FINANCIAL_ACCOUNT_ID = SEL.ACS_FINANCIAL_ACCOUNT_ID) ACS_DEFER_TRA_ACC_ID
                                            , case lv_ConfDeferDate1
                                                when 'IMF_DATE1' then IMF.IMF_DATE1
                                                when 'IMF_DATE2' then IMF.IMF_DATE2
                                                when 'IMF_DATE3' then IMF.IMF_DATE3
                                                when 'IMF_DATE4' then IMF.IMF_DATE4
                                                when 'IMF_DATE5' then IMF.IMF_DATE5
                                              end IMF_DATE_1
                                            , case lv_ConfDeferDate2
                                                when 'IMF_DATE1' then IMF.IMF_DATE1
                                                when 'IMF_DATE2' then IMF.IMF_DATE2
                                                when 'IMF_DATE3' then IMF.IMF_DATE3
                                                when 'IMF_DATE4' then IMF.IMF_DATE4
                                                when 'IMF_DATE5' then IMF.IMF_DATE5
                                              end IMF_DATE_2
                                            , nvl(MGM.ACT_MGM_IMPUTATION_ID, 0) ACT_MGM_IMPUTATION_ID
                                            , MGM.ACS_CPN_ACCOUNT_ID
                                            , MGM.ACS_CDA_ACCOUNT_ID
                                            , MGM.ACS_PF_ACCOUNT_ID
                                            , MGM.DOC_RECORD_ID MGM_DOC_RECORD_ID
                                            ,   --Montant imp. financière * proportion montant analytique
                                              nvl( (select case
                                                             when V.TAX_LIABLED_RATE = 100 then HT_LC
                                                           end
                                                      from V_ACT_DET_TAX V
                                                     where V.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID)
                                                , nvl(IMF.IMF_AMOUNT_LC_D, 0) - nvl(IMF.IMF_AMOUNT_LC_C, 0)
                                                 ) *
                                              (nvl(MGM.IMM_AMOUNT_LC_D, 0) - nvl(MGM.IMM_AMOUNT_LC_C, 0) ) /
                                              (nvl(IMF.IMF_AMOUNT_LC_D, 0) - nvl(IMF.IMF_AMOUNT_LC_C, 0)
                                              ) IMM_AMOUNT_LC
                                            , nvl(DIS.ACT_MGM_DISTRIBUTION_ID, 0) ACT_MGM_DISTRIBUTION_ID
                                            , DIS.ACS_SUB_SET_ID
                                            , DIS.ACS_PJ_ACCOUNT_ID
                                            , nvl( (select case
                                                             when V.TAX_LIABLED_RATE = 100 then HT_LC
                                                           end
                                                      from V_ACT_DET_TAX V
                                                     where V.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID)
                                                , nvl(IMF.IMF_AMOUNT_LC_D, 0) - nvl(IMF.IMF_AMOUNT_LC_C, 0)
                                                 ) *
                                              (nvl(DIS.mgm_AMOUNT_LC_D, 0) - nvl(DIS.mgm_AMOUNT_LC_C, 0) ) /
                                              (nvl(IMF.IMF_AMOUNT_LC_D, 0) - nvl(IMF.IMF_AMOUNT_LC_C, 0)
                                              ) PJ_AMOUNT_LC
                                            , (select sign(count(*) )
                                                 from ACT_DEFERRAL_IMPUTATION DEF
                                                where DEF.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID) HAS_DEFERED_IMP
                                         from ACT_DEFERRAL_SELECTION SEL
                                            , ACT_FINANCIAL_IMPUTATION IMF
                                            , ACT_MGM_IMPUTATION MGM
                                            , ACT_MGM_DISTRIBUTION DIS
                                            , ACT_DOCUMENT DOC
                                        where SEL.ADS_SELECT = 1
                                          and SEL.ACT_JOB_ID = in_ActJobId
                                          and (   SEL.ACT_JOB_ID = in_ActJobId
                                               or (select sign(count(*) )
                                                     from ACT_DEFERRAL_IMPUTATION DEF
                                                    where DEF.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID) = 1)
                                          and IMF.ACT_FINANCIAL_IMPUTATION_ID = SEL.ACT_FINANCIAL_IMPUTATION_ID
                                          and MGM.ACT_FINANCIAL_IMPUTATION_ID(+) = IMF.ACT_FINANCIAL_IMPUTATION_ID
                                          and DIS.ACT_MGM_IMPUTATION_ID(+) = MGM.ACT_MGM_IMPUTATION_ID
                                          and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
                                     order by SEL.ACS_FINANCIAL_ACCOUNT_ID
                                            , IMF.IMF_TRANSACTION_DATE
                                            , IMF_DATE_1
                                            , IMF_DATE_2) loop
        lb_DeferIncomplete  := false;

        if tplSelectedImputations.ACT_MGM_DISTRIBUTION_ID <> 0 then
          ln_AmountToDefer  := tplSelectedImputations.PJ_AMOUNT_LC;
        else
          if tplSelectedImputations.ACT_MGM_IMPUTATION_ID <> 0 then
            ln_AmountToDefer  := tplSelectedImputations.IMM_AMOUNT_LC;
          else
            ln_AmountToDefer  := tplSelectedImputations.IMF_AMOUNT_LC;
          end if;
        end if;

        --Un document par compte / Date de transaction / dates de lissage
        if    (ln_CurrentAccountId <> tplSelectedImputations.ACS_FINANCIAL_ACCOUNT_ID)
           or (ld_CurrentTransactionDate <> tplSelectedImputations.IMF_TRANSACTION_DATE)
           or (ld_CurrentDate1 <> tplSelectedImputations.IMF_DATE_1)
           or (ld_CurrentDate2 <> tplSelectedImputations.IMF_DATE_2) then
          ln_CurrentAccountId        := tplSelectedImputations.ACS_FINANCIAL_ACCOUNT_ID;
          ld_CurrentTransactionDate  := tplSelectedImputations.IMF_TRANSACTION_DATE;
          ld_CurrentDate1            := tplSelectedImputations.IMF_DATE_1;
          ld_CurrentDate2            := tplSelectedImputations.IMF_DATE_2;

          if not ln_ActDeferDocId is null then
            --Mise à jour du montant document sur la base du montant de l'imputation primaire
            ACT_PRC_DOCUMENT.UpdateDocument(ln_ActDeferDocId, ln_DocTotalAmount);
            --Mise à jour des cumuls
            ACT_DOC_TRANSACTION.DocImputations(ln_ActDeferDocId, 0);
            ln_DocTotalAmount     := 0;
            ln_ActDeferDocId      := 0;
            ln_ActDeferPrimaryId  := null;
            ln_PrimaryAmount      := 0;
          end if;

          --Création de l'en-tête du document de lissage
          ACT_PRC_DOCUMENT.CreateDocument(in_ActJobId
                                        , ln_ActJournalId
                                        , ln_ActActJournalId
                                        , ln_AcjCatalogueDocumentId
                                        , ln_AcsFinancialYearId
                                        , ln_ActDeferDocId
                                        , lv_DocNumber
                                         );

          if ln_ActDeferDocId > 0 then
            --Position du statut document
            ACT_PRC_DOCUMENT.CreateDocStatus(ln_ActDeferDocId);

            -- récupère le lettrage du 1er excercice pour le document des périodes lissées sur le 2ème excercice
            if tplSelectedImputations.ACT_LETTERING_ID is not null then
              ln_ActDeferLetteringId  := tplSelectedImputations.ACT_LETTERING_ID;
            else
              -- Sinon création d'une position de lettrage pour identification postérieur des imputations liés à l'imputation d'origine
              ACT_PRC_DEFERRAL.CreateLettering(substr(lv_DocNumber, 1, 30), ln_ActDeferLetteringId);
            end if;
          end if;

          lb_FirstPeriod             := true;
        end if;

        --Création des imputations de lissage
        if ln_ActDeferDocId > 0 then
          --Réserver un id inférieur aux id des imputations de lissage pour l'imputation d'extourne
          --Permet un order by dans l'interface
          ln_ActReversalImpId    := INIT_ID_SEQ.nextval;
          ln_TotalDeferDays      := 0;

          --Premier parcours pour réceptionner le nombre de jour total
          for tplPeriods in (select sum(PER_DAYS) over(partition by SUM_PARTITION order by PER_START_DATE) DAYS
                               from (select   'PARTITION' SUM_PARTITION
                                            , decode(to_char(tplSelectedImputations.IMF_DATE_1, 'DD')
                                                   , to_char(PER.PER_START_DATE, 'DD'), 0
                                                   , 30 - to_number(to_char(tplSelectedImputations.IMF_DATE_1, 'DD') ) + 1
                                                    ) PER_DAYS
                                            , PER.PER_START_DATE
                                         from ACS_PERIOD PER
                                        where tplSelectedImputations.IMF_DATE_1 between PER.PER_START_DATE and PER.PER_END_DATE
                                          and PER.C_TYPE_PERIOD = '2'
                                     union all
                                     select   'PARTITION' SUM_PARTITION
                                            , 30 PER_DAYS
                                            , PER.PER_START_DATE
                                         from ACS_PERIOD PER
                                        where PER.PER_START_DATE >= tplSelectedImputations.IMF_DATE_1
                                          and PER.PER_END_DATE <= tplSelectedImputations.IMF_DATE_2
                                          and PER.C_TYPE_PERIOD = '2'
                                     union all
                                     select   'PARTITION' SUM_PARTITION
                                            , decode(to_char(tplSelectedImputations.IMF_DATE_2, 'DD')
                                                   , to_char(PER.PER_END_DATE, 'DD'), 0
                                                   , (tplSelectedImputations.IMF_DATE_2 - PER.PER_START_DATE + 1)
                                                    ) PER_DAYS
                                            , PER.PER_START_DATE
                                         from ACS_PERIOD PER
                                        where tplSelectedImputations.IMF_DATE_2 between PER.PER_START_DATE and PER.PER_END_DATE
                                          and PER.C_TYPE_PERIOD = '2'
                                     order by PER_START_DATE) P) loop
            if tplPeriods.DAYS <> 0 then
              ln_TotalDeferDays  := tplPeriods.DAYS;
            end if;
          end loop;

          ln_DeferAmount         := 0;
          ln_ClosedPeriodAmount  := 0;
          ln_ReversalAmount      := 0;
          ln_ReversalDate        := null;

          if IsInActivePeriod(tplSelectedImputations.IMF_TRANSACTION_DATE) then
            ln_ReversalDate  := tplSelectedImputations.IMF_TRANSACTION_DATE;
          end if;

          --1. Sélection de la période englobant la date de lissage début
          --2. Sélection des périodes entières situées entre les deux dates de lissage
          --3. Sélection de la période englabant la date de fin de lissage
          --Chaque groupe est identifié par
          --    "Per_type" -> -1 indique les périodes antérieures à la date de transaction ( également celle qui l'englobe),
          --              1 indique les périodes entières postlrieures à la date de transaction
          --                    ==> Servira à lisser sur la première période de lissage la somme des montants de ces périodes
          --    "Per_Active" -> 1 indique la période active,
          --              0 la période bouclée
          --              ==> Lisser le montant prorata de la période
          --    "Transaction_period" indique la période où se situe la date de transaction.
          --    " Last_period" indique la dernière période de lissage ...Celle qui va recevoir les diff. d'arrondi.
          -- Les montants sont calculés selon le nombre de jours total , le nbr. de jours de la période
          --    ([30] pour les périodes pleines, [30-jour de la date début + 1] pour la période de la date de début et
          --       [jour de la date de fin - début période + 1] pour la périodes de date de fin
          for tplPeriods in (select   case
                                        when tplSelectedImputations.IMF_TRANSACTION_DATE between PER_START_DATE and PER_END_DATE then '1'
                                        when PER_START_DATE <= tplSelectedImputations.IMF_TRANSACTION_DATE then '-1'
                                        when PER_END_DATE <= tplSelectedImputations.IMF_TRANSACTION_DATE then '-1'
                                        else '1'
                                      end PER_TYPE
                                    , case
                                        when PER.C_STATE_PERIOD = 'ACT' then '1'
                                        else '0'
                                      end PER_ACTIVE
                                    , case
                                        when tplSelectedImputations.IMF_TRANSACTION_DATE between PER_START_DATE and PER_END_DATE then '1'
                                        else '0'
                                      end TRANSACTION_PERIOD
                                    , case
                                        when tplSelectedImputations.IMF_DATE_2 between PER_START_DATE and PER_END_DATE then '1'
                                        else '0'
                                      end LAST_PERIOD
                                    , decode(to_char(tplSelectedImputations.IMF_DATE_1, 'DD')
                                           , to_char(PER.PER_START_DATE, 'DD'), 0
                                           , 30 - to_number(to_char(tplSelectedImputations.IMF_DATE_1, 'DD') ) + 1
                                            ) PER_DAYS
                                    , decode(to_char(tplSelectedImputations.IMF_DATE_1, 'DD')
                                           , to_char(PER.PER_START_DATE, 'DD'), 0
                                           , 30 - to_number(to_char(tplSelectedImputations.IMF_DATE_1, 'DD') ) + 1
                                            ) *
                                      ln_AmountToDefer /
                                      ln_TotalDeferDays DEFER_AMOUNT
                                    , PER.PER_END_DATE
                                    , PER.PER_START_DATE
                                    , PER.ACS_PERIOD_ID
                                    , '( ' || PER.PER_NO_PERIOD || '-' || (select FYE_NO_EXERCICE
                                                                             from ACS_FINANCIAL_YEAR
                                                                            where ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID) || ' )' PER_NO_PERIOD
                                 from ACS_PERIOD PER
                                where tplSelectedImputations.IMF_DATE_1 between PER.PER_START_DATE and PER.PER_END_DATE
                                  and PER.C_TYPE_PERIOD = '2'
                             union all
                             select   case
                                        when tplSelectedImputations.IMF_TRANSACTION_DATE between PER_START_DATE and PER_END_DATE then '1'
                                        when PER_START_DATE <= tplSelectedImputations.IMF_TRANSACTION_DATE then '-1'
                                        when PER_END_DATE <= tplSelectedImputations.IMF_TRANSACTION_DATE then '-1'
                                        else '1'
                                      end PER_TYPE
                                    , case
                                        when PER.C_STATE_PERIOD = 'ACT' then '1'
                                        else '0'
                                      end PER_ACTIVE
                                    , case
                                        when tplSelectedImputations.IMF_TRANSACTION_DATE between PER_START_DATE and PER_END_DATE then '1'
                                        else '0'
                                      end TRANSACTION_PERIOD
                                    , case
                                        when tplSelectedImputations.IMF_DATE_2 between PER_START_DATE and PER_END_DATE then '1'
                                        else '0'
                                      end LAST_PERIOD
                                    , 30 PER_DAYS
                                    , 30 * ln_AmountToDefer / ln_TotalDeferDays DEFER_AMOUNT
                                    , PER.PER_END_DATE
                                    , PER.PER_START_DATE
                                    , PER.ACS_PERIOD_ID
                                    , '( ' || PER.PER_NO_PERIOD || '-' || (select FYE_NO_EXERCICE
                                                                             from ACS_FINANCIAL_YEAR
                                                                            where ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID) || ' )' PER_NO_PERIOD
                                 from ACS_PERIOD PER
                                where PER.PER_START_DATE >= tplSelectedImputations.IMF_DATE_1
                                  and PER.PER_END_DATE <= tplSelectedImputations.IMF_DATE_2
                                  and PER.C_TYPE_PERIOD = '2'
                             union all
                             select   case
                                        when tplSelectedImputations.IMF_TRANSACTION_DATE between PER_START_DATE and PER_END_DATE then '1'
                                        when PER_START_DATE <= tplSelectedImputations.IMF_TRANSACTION_DATE then '-1'
                                        when PER_END_DATE <= tplSelectedImputations.IMF_TRANSACTION_DATE then '-1'
                                        else '1'
                                      end PER_TYPE
                                    , case
                                        when PER.C_STATE_PERIOD = 'ACT' then '1'
                                        else '0'
                                      end PER_ACTIVE
                                    , case
                                        when tplSelectedImputations.IMF_TRANSACTION_DATE between PER_START_DATE and PER_END_DATE then '1'
                                        else '0'
                                      end TRANSACTION_PERIOD
                                    , case
                                        when tplSelectedImputations.IMF_DATE_2 between PER_START_DATE and PER_END_DATE then '1'
                                        else '0'
                                      end LAST_PERIOD
                                    , decode(to_char(tplSelectedImputations.IMF_DATE_2, 'DD')
                                           , to_char(PER.PER_END_DATE, 'DD'), 0
                                           , (tplSelectedImputations.IMF_DATE_2 - PER.PER_START_DATE + 1)
                                            ) PER_DAYS
                                    , decode(to_char(tplSelectedImputations.IMF_DATE_2, 'DD')
                                           , to_char(PER.PER_END_DATE, 'DD'), 0
                                           , (tplSelectedImputations.IMF_DATE_2 - PER.PER_START_DATE + 1)
                                            ) *
                                      ln_AmountToDefer /
                                      ln_TotalDeferDays DEFER_AMOUNT
                                    , PER.PER_END_DATE
                                    , PER.PER_START_DATE
                                    , PER.ACS_PERIOD_ID
                                    , '( ' || PER.PER_NO_PERIOD || '-' || (select FYE_NO_EXERCICE
                                                                             from ACS_FINANCIAL_YEAR
                                                                            where ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID) || ' )' PER_NO_PERIOD
                                 from ACS_PERIOD PER
                                where tplSelectedImputations.IMF_DATE_2 between PER.PER_START_DATE and PER.PER_END_DATE
                                  and PER.C_TYPE_PERIOD = '2'
                             order by PER_TYPE
                                    , PER_END_DATE) loop
            --Somme les montants pour les périodes précédant la première période active de l'intervalle de lissage
            -- ou pour les périodes précédant la période de la date de transaction
            if     (ACS_FINANCIAL_YEAR_FCT.GetFinYearIdByDate(tplPeriods.PER_START_DATE) = ln_AcsFinancialYearId)
               and (    (tplPeriods.PER_ACTIVE = 0)
                    or (tplPeriods.PER_TYPE = -1) ) then
              ln_ClosedPeriodAmount  := ln_ClosedPeriodAmount + tplPeriods.DEFER_AMOUNT;
            else
              ln_DeferAmount         := ln_ClosedPeriodAmount + tplPeriods.DEFER_AMOUNT;
              ln_ClosedPeriodAmount  := 0;
            end if;

            --Génération des imputations
            --si premières périodes bouclées mvt de lissage sur la première période active avec le cumul des périodes précédents
            --sinon pour la période "régulière" de lissage = > montant au prorata
            if    (ACS_FINANCIAL_YEAR_FCT.GetFinYearIdByDate(tplPeriods.PER_START_DATE) != ln_AcsFinancialYearId)
               or (     (tplPeriods.PER_TYPE = 1)
                   and (tplPeriods.PER_ACTIVE = 1)
                   and (tplPeriods.PER_DAYS > 0) ) then
              if ln_ReversalDate is null then
                if tplPeriods.TRANSACTION_PERIOD = 1 then
                  ln_ReversalDate  := tplSelectedImputations.IMF_TRANSACTION_DATE;
                else
                  ln_ReversalDate  := tplPeriods.PER_START_DATE;
                end if;
              end if;

              --Différence d'arrondi sur la dernière période de lissage
              if (tplPeriods.LAST_PERIOD = 1) then
                ln_DeferAmount  := ln_AmountToDefer - ln_ReversalAmount;
              end if;

              ln_ReversalAmount  := ln_ReversalAmount + ln_DeferAmount;

              -- Crée les imputations seulement pour l'exercice courant
              if ACS_FINANCIAL_YEAR_FCT.GetFinYearIdByDate(tplPeriods.PER_START_DATE) = ln_AcsFinancialYearId then
                --
                --Imputation de lissage sur le compte transitoire
                --
                ln_ActDeferFinImpId  := null;
                GenerateFinImputation(tplSelectedImputations.ACT_FINANCIAL_IMPUTATION_ID
                                    , ln_ActDeferDocId
                                    , ln_ActDeferLetteringId
                                    , tplPeriods.ACS_PERIOD_ID
                                    , tplSelectedImputations.ACS_DEFER_TRA_ACC_ID
                                    , tplSelectedImputations.IMF_ACS_DIVISION_ACCOUNT_ID
                                    , tplSelectedImputations.DOC_RECORD_ID
                                    , case
                                        when(    tplSelectedImputations.HAS_DEFERED_IMP = 1
                                             and lb_FirstPeriod) then 1
                                        else 0
                                      end
                                    , lv_FinImpDeferLabel || ' ' || tplSelectedImputations.DOC_NUMBER || ' ' || tplPeriods.PER_NO_PERIOD
                                    , -ln_DeferAmount
                                    , tplPeriods.PER_END_DATE
                                    , ln_ActDeferFinImpId
                                     );
                --
                --Imputation de lissage sur le compte différé
                --
                ln_ActDeferFinImpId  := null;
                GenerateFinImputation(tplSelectedImputations.ACT_FINANCIAL_IMPUTATION_ID
                                    , ln_ActDeferDocId
                                    , ln_ActDeferLetteringId
                                    , tplPeriods.ACS_PERIOD_ID
                                    , tplSelectedImputations.ACS_DEFER_ACC_ID
                                    , tplSelectedImputations.IMF_ACS_DIVISION_ACCOUNT_ID
                                    , tplSelectedImputations.DOC_RECORD_ID
                                    , 0
                                    , lv_FinImpDeferLabel || ' ' || tplSelectedImputations.DOC_NUMBER || ' ' || tplPeriods.PER_NO_PERIOD
                                    , ln_DeferAmount
                                    , tplPeriods.PER_END_DATE
                                    , ln_ActDeferFinImpId
                                     );

                -- pour les imputations lissées sur le 2ème exercice, on met à jour le montant du document avec la
                -- première imputation.
                if     tplSelectedImputations.HAS_DEFERED_IMP = 1
                   and lb_FirstPeriod then
                  ln_DocTotalAmount  := -ln_DeferAmount;
                end if;

                lb_FirstPeriod       := false;

                if (gn_Analytical = 1) then
                  if (tplSelectedImputations.ACT_MGM_IMPUTATION_ID <> 0) then
                    GenerateMgmImputation(ln_ActDeferDocId
                                        , ln_ActDeferFinImpId
                                        , tplPeriods.ACS_PERIOD_ID
                                        , ACS_FUNCTION.GetCpnOfFinAcc(tplSelectedImputations.ACS_DEFER_ACC_ID)
                                        , tplSelectedImputations.ACS_CDA_ACCOUNT_ID
                                        , tplSelectedImputations.ACS_PF_ACCOUNT_ID
                                        , tplSelectedImputations.MGM_DOC_RECORD_ID
                                        , lv_FinImpDeferLabel || ' ' || tplSelectedImputations.DOC_NUMBER || ' ' || tplPeriods.PER_NO_PERIOD
                                        , ln_DeferAmount
                                        , tplPeriods.PER_END_DATE
                                        , ln_ActDeferMgmImpId
                                         );

                    if tplSelectedImputations.ACT_MGM_DISTRIBUTION_ID <> 0 then
                      ACT_PRC_ANALYTICAL_IMPUTATION.CreateDeferMgmDistribution(ln_ActDeferMgmImpId
                                                                             , lv_FinImpDeferLabel ||
                                                                               ' ' ||
                                                                               tplSelectedImputations.DOC_NUMBER ||
                                                                               ' ' ||
                                                                               tplPeriods.PER_NO_PERIOD
                                                                             , tplSelectedImputations.ACS_SUB_SET_ID
                                                                             , tplSelectedImputations.ACS_PJ_ACCOUNT_ID
                                                                             , ln_DeferAmount
                                                                              );
                    end if;
                  end if;
                end if;
              else
                lb_DeferIncomplete  := true;
              end if;
            end if;
          end loop;

          --Périodes d'extourne du mvt du document à lisser
          --retourne qu'un seul enregistrement malgré le loop utilisé pour simplification du code
          for tplPeriods in (select   PER.PER_START_DATE
                                    , PER.PER_END_DATE
                                    , PER.ACS_PERIOD_ID
                                    , '( ' || PER.PER_NO_PERIOD || '-' || (select FYE_NO_EXERCICE
                                                                             from ACS_FINANCIAL_YEAR
                                                                            where ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID) || ' )' PER_NO_PERIOD
                                 from ACS_PERIOD PER
                                where PER.C_TYPE_PERIOD = '2'
                                  and ln_ReversalDate between PER.PER_START_DATE and PER.PER_END_DATE
                             order by PER.PER_NO_PERIOD) loop
            -- Si l'imputation d'origine était sur l'exercice précédant
            if tplSelectedImputations.HAS_DEFERED_IMP = 1 then
              ACT_PRC_DEFERRAL.UpdateDeferFinImpIncStatus(tplSelectedImputations.ACT_FINANCIAL_IMPUTATION_ID, null, '00');
            else
              --
              --Imputation d'extourne (Primaire) sur le compte transitoire
              --
              ln_PrimaryAmount   := ln_PrimaryAmount + ln_ReversalAmount;

              if ln_ActDeferPrimaryId is null then
                GenerateFinImputation(tplSelectedImputations.ACT_FINANCIAL_IMPUTATION_ID
                                    , ln_ActDeferDocId
                                    , ln_ActDeferLetteringId
                                    , tplPeriods.ACS_PERIOD_ID
                                    , tplSelectedImputations.ACS_DEFER_TRA_ACC_ID
                                    , tplSelectedImputations.IMF_ACS_DIVISION_ACCOUNT_ID
                                    , tplSelectedImputations.DOC_RECORD_ID
                                    , 1
                                    , lv_FinImpReversalLabel || ' ' || tplSelectedImputations.DOC_NUMBER
                                    , ln_ReversalAmount
                                    , ln_ReversalDate
                                    , ln_ActDeferPrimaryId
                                     );
              else
                UpdateDeferFinImpAmount(ln_ActDeferPrimaryId, ln_PrimaryAmount);
              end if;

              ln_DocTotalAmount  := ln_DocTotalAmount + abs(ln_ReversalAmount);
              --
              --Imputation d'extourne sur le compte différé
              --
              GenerateFinImputation(tplSelectedImputations.ACT_FINANCIAL_IMPUTATION_ID
                                  , ln_ActDeferDocId
                                  , ln_ActDeferLetteringId
                                  , tplPeriodS.ACS_PERIOD_ID
                                  , tplSelectedImputations.ACS_DEFER_ACC_ID
                                  , tplSelectedImputations.IMF_ACS_DIVISION_ACCOUNT_ID
                                  , tplSelectedImputations.DOC_RECORD_ID
                                  , 0
                                  , lv_FinImpReversalLabel || ' ' || tplSelectedImputations.DOC_NUMBER
                                  , -ln_ReversalAmount
                                  , ln_ReversalDate
                                  , ln_ActReversalImpId
                                   );

              -- Définit sur l'imputation primaire si le lissage sera complet ou partiellement
              if lb_DeferIncomplete then
                ACT_PRC_DEFERRAL.UpdateDeferFinImpIncStatus(tplSelectedImputations.ACT_FINANCIAL_IMPUTATION_ID, ln_ActReversalImpId, '01');
              end if;

              if gn_Analytical = 1 then
                if (tplSelectedImputations.ACT_MGM_IMPUTATION_ID <> 0) then
                  --
                  --Imputation analytique liée à celle d'extourne sur le compte différé
                  --
                  GenerateMgmImputation(ln_ActDeferDocId
                                      , ln_ActReversalImpId
                                      , tplPeriods.ACS_PERIOD_ID
                                      , ACS_FUNCTION.GetCpnOfFinAcc(tplSelectedImputations.ACS_DEFER_ACC_ID)
                                      , tplSelectedImputations.ACS_CDA_ACCOUNT_ID
                                      , tplSelectedImputations.ACS_PF_ACCOUNT_ID
                                      , tplSelectedImputations.MGM_DOC_RECORD_ID
                                      , lv_FinImpReversalLabel || ' ' || tplSelectedImputations.DOC_NUMBER || ' ' || tplPeriods.PER_NO_PERIOD
                                      , -ln_ReversalAmount
                                      , ln_ReversalDate
                                      , ln_ActDeferMgmImpId
                                       );

                  if tplSelectedImputations.ACT_MGM_DISTRIBUTION_ID <> 0 then
                    --
                    --Distribution analytique
                    --
                    ACT_PRC_ANALYTICAL_IMPUTATION.CreateDeferMgmDistribution(ln_ActDeferMgmImpId
                                                                           , lv_FinImpDeferLabel ||
                                                                             ' ' ||
                                                                             tplSelectedImputations.DOC_NUMBER ||
                                                                             ' ' ||
                                                                             tplPeriods.PER_NO_PERIOD
                                                                           , tplSelectedImputations.ACS_SUB_SET_ID
                                                                           , tplSelectedImputations.ACS_PJ_ACCOUNT_ID
                                                                           , -ln_ReversalAmount
                                                                            );
                  end if;
                end if;
              end if;
            end if;
          end loop;
        end if;

        --Renseigner l'imputation d'origine avec le lettrage créé précédemment
        ACT_PRC_FINANCIAL_IMPUTATION.UpdateDeferFinImpLink(tplSelectedImputations.ACT_FINANCIAL_IMPUTATION_ID, ln_ActDeferLetteringId);
      end loop;

      --Tenir compte des calculs du dernier document généré
      if not ln_ActDeferDocId is null then
        ACT_PRC_DOCUMENT.UpdateDocument(ln_ActDeferDocId, ln_DocTotalAmount);
        --Mise à jour des cumuls
        ACT_DOC_TRANSACTION.DocImputations(ln_ActDeferDocId, 0);
      end if;

      ACT_PRC_DEFERRAL.ClearSelection(in_ActJobId);
    end if;
  end GenerateDocuments;

  procedure UndoImputation(in_ActDeferDocId in ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
  is
    ln_ActLetteringId ACT_FINANCIAL_IMPUTATION.ACT_LETTERING_ID%type;
    lb_NextYearImp    boolean                                          := false;
  begin
    for tplDocImputations in (select IMP.ACT_FINANCIAL_IMPUTATION_ID
                                   , IMP.ACT_LETTERING_ID
                                   , (select sign(count(*) )
                                        from ACT_FINANCIAL_IMPUTATION IMP_S
                                           , ACT_DOCUMENT DOC_S
                                           , ACT_JOB JOB_S
                                       where IMP_S.ACT_FINANCIAL_IMPUTATION_ID = DEF.ACT_FINANCIAL_IMPUTATION_ID
                                         and IMP_S.ACT_DOCUMENT_ID = DOC_S.ACT_DOCUMENT_ID
                                         and JOB_S.ACT_JOB_ID = DOC_S.ACT_JOB_ID
                                         and JOB_S.ACS_FINANCIAL_YEAR_ID <> JOB.ACS_FINANCIAL_YEAR_ID) IS_NEXT_YEAR_IMP
                                from ACT_DOCUMENT DOC
                                   , ACT_JOB JOB
                                   , ACT_FINANCIAL_IMPUTATION IMP
                                   , ACT_DEFERRAL_IMPUTATION DEF
                               where DOC.ACT_DOCUMENT_ID = in_ActDeferDocId
                                 and JOB.ACT_JOB_ID = DOC.ACT_JOB_ID
                                 and IMP.ACT_DOCUMENT_ID(+) = DOC.ACT_DOCUMENT_ID
                                 and DEF.ACT_DEFER_FIN_IMP_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) loop
      ACT_PRC_DEFERRAL.ClearImputation(tplDocImputations.ACT_FINANCIAL_IMPUTATION_ID);

      if ln_ActLetteringId is null then
        ln_ActLetteringId  := tplDocImputations.ACT_LETTERING_ID;
      end if;

      -- Détermine si on supprime sur le 2ème exercice
      lb_NextYearImp  :=    lb_NextYearImp
                         or tplDocImputations.IS_NEXT_YEAR_IMP = 1;
    end loop;

    -- Supprime le lettrage uniquement lors de la suppression du 1er exercice
    if not lb_NextYearImp then
      for tplDocImputations in (select ACT_FINANCIAL_IMPUTATION_ID
                                  from ACT_FINANCIAL_IMPUTATION
                                 where ACT_LETTERING_ID = ln_ActLetteringId) loop
        --Couper le lien de l'imputation d'origine avec le lettrage du document lissé
        ACT_PRC_FINANCIAL_IMPUTATION.UpdateDeferFinImpLink(tplDocImputations.ACT_FINANCIAL_IMPUTATION_ID, null);
      end loop;

      -- Supprimer letteringid
      ACT_PRC_DEFERRAL.ClearLettering(ln_ActLetteringId);
    end if;
  end UndoImputation;
begin
  gn_Analytical  := 0;

  begin
    select ACS_SUB_SET_ID
      into gn_ExistDivision
      from ACS_SUB_SET
     where C_TYPE_SUB_SET = 'DIVI';
  exception
    when no_data_found then
      gn_ExistDivision  := 0;
  end;
end ACT_MGT_DEFERRAL;
