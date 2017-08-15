--------------------------------------------------------
--  DDL for Package Body ACT_DOC_TRANSACTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_DOC_TRANSACTION" 
is
  type AmountsRecType is record(
    DebitLC   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type    := 0
  , CreditLC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type    := 0
  , DebitFC   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type    := 0
  , CreditFC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type    := 0
  , DebitEUR  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type   := 0
  , CreditEUR ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type   := 0
  );

  type EchangeRateRecType is record(
    ExchangeRate ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type   := 0
  , BasePrice    ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type      := 0
  );

-----------------------------
  procedure DocImputations(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type, aType number)   -- 0: Toutes, 1: Financières, 2: Analytiques
  is
    type CumulBySubSetCursorTyp is ref cursor;

    CumulBySubSetCursor CumulBySubSetCursorTyp;
    CumulBySubSet       tblCumulRecTyp;
    tblCumul            tblCumulTyp;
    i                   binary_integer         := 0;
  begin
    tblCumul.delete;

    -- Types de cumuls et états journaux par sous-ensemble
    if aType = 0 then   --  Imputations financières et analytiques
      open CumulBySubSetCursor for
        select   SCA.C_TYPE_CUMUL
               , SCA.C_SUB_SET
               , ETA.C_ETAT_JOURNAL
            from ACT_ETAT_JOURNAL ETA
               , ACJ_SUB_SET_CAT SCA
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACT_DOCUMENT DOC
           where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
             and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
             and ETA.C_SUB_SET = SCA.C_SUB_SET
        union
        select   SCA.C_TYPE_CUMUL
               , SCA.C_SUB_SET
               , ETA.C_ETAT_JOURNAL
            from ACT_ETAT_JOURNAL ETA
               , ACJ_SUB_SET_CAT SCA
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACT_DOCUMENT DOC
           where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
             and DOC.ACT_ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
             and ETA.C_SUB_SET = SCA.C_SUB_SET
        order by C_SUB_SET desc;
    elsif aType = 1 then   --  Imputations financières
      open CumulBySubSetCursor for
        select   SCA.C_TYPE_CUMUL
               , SCA.C_SUB_SET
               , ETA.C_ETAT_JOURNAL
            from ACT_ETAT_JOURNAL ETA
               , ACJ_SUB_SET_CAT SCA
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACT_DOCUMENT DOC
           where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
             and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
             and ETA.C_SUB_SET = SCA.C_SUB_SET
        order by C_SUB_SET desc;
    elsif aType = 2 then   --  Imputations analytiques
      open CumulBySubSetCursor for
        select   SCA.C_TYPE_CUMUL
               , SCA.C_SUB_SET
               , ETA.C_ETAT_JOURNAL
            from ACT_ETAT_JOURNAL ETA
               , ACJ_SUB_SET_CAT SCA
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACT_DOCUMENT DOC
           where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
             and DOC.ACT_ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
             and ETA.C_SUB_SET = SCA.C_SUB_SET
        order by C_SUB_SET desc;
    end if;

    fetch CumulBySubSetCursor
     into CumulBySubSet;

    while CumulBySubSetCursor%found loop
      i                           := i + 1;
      tblCumul(i).C_TYPE_CUMUL    := CumulBySubSet.C_TYPE_CUMUL;
      tblCumul(i).C_SUB_SET       := CumulBySubSet.C_SUB_SET;
      tblCumul(i).C_ETAT_JOURNAL  := CumulBySubSet.C_ETAT_JOURNAL;

      fetch CumulBySubSetCursor
       into CumulBySubSet;
    end loop;

    close CumulBySubSetCursor;

    WriteDocImputations(aACT_DOCUMENT_ID, tblCumul);
  end DocImputations;

-----------------------------
  procedure JobImputations(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type, aType number)   -- 0: Toutes, 1: Financières, 2: Analytiques
  is
    cursor UpdateCumuls(Job_id number)
    is
      select ACT_DOCUMENT.ACT_DOCUMENT_ID
        from ACT_DOCUMENT
       where ACT_JOB_ID = Job_id;

    UpdateCumuls_tuple UpdateCumuls%rowtype;
  begin
    --Mise à jour du status du document pour les cumuls
    open UpdateCumuls(aACT_JOB_ID);

    fetch UpdateCumuls
     into UpdateCumuls_tuple;

    while UpdateCumuls%found loop
      ACT_DOC_TRANSACTION.DocImputations(UpdateCumuls_tuple.ACT_DOCUMENT_ID, aType);

      fetch UpdateCumuls
       into UpdateCumuls_tuple;
    end loop;

    close UpdateCumuls;
  end JobImputations;

-----------------------------
  procedure WriteDocImputations(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type, atblCumul tblCumulTyp)
  is
    -- Imputations financières d'un document donné
    cursor DocumentImputations(
      aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type
    , aC_SUB_SET       ACS_SUB_SET.C_SUB_SET%type
    )
    is
      select   IMP.ACS_FINANCIAL_ACCOUNT_ID
             , decode(aC_SUB_SET, 'ACC', null, IMP.ACS_AUXILIARY_ACCOUNT_ID) ACS_AUXILIARY_ACCOUNT_ID
             , IMP.ACS_PERIOD_ID
             , decode(aC_SUB_SET
                    , 'ACC', sum(IMP.IMF_AMOUNT_LC_D)
                    , decode(CAT.C_TYPE_CATALOGUE
                           , '9', decode(sign(sum(IMP.IMF_AMOUNT_LC_D - IMP.IMF_AMOUNT_LC_C) )
                                       , 1, sum(IMP.IMF_AMOUNT_LC_D - IMP.IMF_AMOUNT_LC_C)
                                       , 0
                                        )
                           , sum(IMP.IMF_AMOUNT_LC_D)
                            )
                     ) IMF_AMOUNT_LC_D
             , decode(aC_SUB_SET
                    , 'ACC', sum(IMP.IMF_AMOUNT_LC_C)
                    , decode(CAT.C_TYPE_CATALOGUE
                           , '9', decode(sign(sum(IMP.IMF_AMOUNT_LC_D - IMP.IMF_AMOUNT_LC_C) )
                                       , 1, 0
                                       , abs(sum(IMP.IMF_AMOUNT_LC_D - IMP.IMF_AMOUNT_LC_C) )
                                        )
                           , sum(IMP.IMF_AMOUNT_LC_C)
                            )
                     ) IMF_AMOUNT_LC_C
             , decode(aC_SUB_SET
                    , 'ACC', sum(IMP.IMF_AMOUNT_FC_D)
                    , decode(CAT.C_TYPE_CATALOGUE
                           , '9', decode(sign(sum(IMP.IMF_AMOUNT_FC_D - IMP.IMF_AMOUNT_FC_C) )
                                       , 1, sum(IMP.IMF_AMOUNT_FC_D - IMP.IMF_AMOUNT_FC_C)
                                       , 0
                                        )
                           , sum(IMP.IMF_AMOUNT_FC_D)
                            )
                     ) IMF_AMOUNT_FC_D
             , decode(aC_SUB_SET
                    , 'ACC', sum(IMP.IMF_AMOUNT_FC_C)
                    , decode(CAT.C_TYPE_CATALOGUE
                           , '9', decode(sign(sum(IMP.IMF_AMOUNT_FC_D - IMP.IMF_AMOUNT_FC_C) )
                                       , 1, 0
                                       , abs(sum(IMP.IMF_AMOUNT_FC_D - IMP.IMF_AMOUNT_FC_C) )
                                        )
                           , sum(IMP.IMF_AMOUNT_FC_C)
                            )
                     ) IMF_AMOUNT_FC_C
             , decode(aC_SUB_SET
                    , 'ACC', sum(IMP.IMF_AMOUNT_EUR_D)
                    , decode(CAT.C_TYPE_CATALOGUE
                           , '9', decode(sign(sum(IMP.IMF_AMOUNT_EUR_D - IMP.IMF_AMOUNT_EUR_C) )
                                       , 1, sum(IMP.IMF_AMOUNT_EUR_D - IMP.IMF_AMOUNT_EUR_C)
                                       , 0
                                        )
                           , sum(IMP.IMF_AMOUNT_EUR_D)
                            )
                     ) IMF_AMOUNT_EUR_D
             , decode(aC_SUB_SET
                    , 'ACC', sum(IMP.IMF_AMOUNT_EUR_C)
                    , decode(CAT.C_TYPE_CATALOGUE
                           , '9', decode(sign(sum(IMP.IMF_AMOUNT_EUR_D - IMP.IMF_AMOUNT_EUR_C) )
                                       , 1, 0
                                       , abs(sum(IMP.IMF_AMOUNT_EUR_D - IMP.IMF_AMOUNT_EUR_C) )
                                        )
                           , sum(IMP.IMF_AMOUNT_EUR_C)
                            )
                     ) IMF_AMOUNT_EUR_C
             , IMP.ACS_FINANCIAL_CURRENCY_ID
             , FIN.FIN_COLLECTIVE
             , FIN.C_BALANCE_SHEET_PROFIT_LOSS
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , CAT.C_TYPE_PERIOD
          from ACJ_CATALOGUE_DOCUMENT CAT
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_DOCUMENT DOC
         where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and ACT_DOC_TRANSACTION.CompareSubSet(IMP.ACS_AUXILIARY_ACCOUNT_ID, aC_SUB_SET) = aC_SUB_SET
      group by IMP.ACS_FINANCIAL_ACCOUNT_ID
             , CAT.C_TYPE_CATALOGUE
             , decode(aC_SUB_SET, 'ACC', null, IMP.ACS_AUXILIARY_ACCOUNT_ID)
             , IMP.ACS_PERIOD_ID
             , IMP.ACS_FINANCIAL_CURRENCY_ID
             , FIN.FIN_COLLECTIVE
             , FIN.C_BALANCE_SHEET_PROFIT_LOSS
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , CAT.C_TYPE_PERIOD
      order by FIN.FIN_COLLECTIVE
             , IMP.ACS_PERIOD_ID
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , decode(aC_SUB_SET, 'ACC', null, IMP.ACS_AUXILIARY_ACCOUNT_ID)
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID;

    /**
    * Imputations analytiques d'un document donné
    * Réception des montants de l'imputation analytique et des cumuls de la distribution PJ par imputation.
    * par difflrence des deux montant , on peut savoir si la répartition est totale ou partielle sur les PJ
    **/
    cursor DocumentMgmImputations(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   IMP.ACS_FINANCIAL_ACCOUNT_ID
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , MGI.ACT_MGM_IMPUTATION_ID
             , MGI.ACT_FINANCIAL_IMPUTATION_ID
             , MGI.ACT_DOCUMENT_ID
             , MGI.ACS_FINANCIAL_CURRENCY_ID
             , MGI.ACS_ACS_FINANCIAL_CURRENCY_ID
             , MGI.ACS_PERIOD_ID
             , MGI.ACS_CPN_ACCOUNT_ID
             , MGI.ACS_CDA_ACCOUNT_ID
             , MGI.ACS_PF_ACCOUNT_ID
             , PJ.ACS_PJ_ACCOUNT_ID
             , MGI.ACS_QTY_UNIT_ID
             , MGI.DOC_RECORD_ID
             , (nvl(MGI.IMM_AMOUNT_LC_D, 0) - nvl(MGM.MGM_AMOUNT_LC_D, 0) ) DIFLCD
             , (nvl(MGI.IMM_AMOUNT_LC_C, 0) - nvl(MGM.MGM_AMOUNT_LC_C, 0) ) DIFLCC
             , (nvl(MGI.IMM_AMOUNT_FC_D, 0) - nvl(MGM.MGM_AMOUNT_FC_D, 0) ) DIFFCD
             , (nvl(MGI.IMM_AMOUNT_FC_C, 0) - nvl(MGM.MGM_AMOUNT_FC_C, 0) ) DIFFCC
             , (nvl(MGI.IMM_AMOUNT_EUR_D, 0) - nvl(MGM.MGM_AMOUNT_EUR_D, 0) ) DIFEURD
             , (nvl(MGI.IMM_AMOUNT_EUR_C, 0) - nvl(MGM.MGM_AMOUNT_EUR_C, 0) ) DIFEURC
             , (nvl(MGI.IMM_QUANTITY_D, 0) - nvl(MGM.MGM_QUANTITY_D, 0) ) DIFQTYD
             , (nvl(MGI.IMM_QUANTITY_C, 0) - nvl(MGM.MGM_QUANTITY_C, 0) ) DIFQTYC
             , MGI.IMM_AMOUNT_LC_D
             , MGI.IMM_AMOUNT_LC_C
             , MGI.IMM_AMOUNT_FC_D
             , MGI.IMM_AMOUNT_FC_C
             , MGI.IMM_AMOUNT_EUR_D
             , MGI.IMM_AMOUNT_EUR_C
             , MGI.IMM_QUANTITY_D
             , MGI.IMM_QUANTITY_C
             , PJ.MGM_AMOUNT_LC_D
             , PJ.MGM_AMOUNT_FC_D
             , PJ.MGM_AMOUNT_EUR_D
             , PJ.MGM_AMOUNT_LC_C
             , PJ.MGM_AMOUNT_FC_C
             , PJ.MGM_AMOUNT_EUR_C
             , PJ.MGM_QUANTITY_D
             , PJ.MGM_QUANTITY_C
          from ACT_FINANCIAL_IMPUTATION IMP
             , ACT_MGM_IMPUTATION MGI
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
                   where IMM.ACT_MGM_IMPUTATION_ID = MGD.ACT_MGM_IMPUTATION_ID
                     and IMM.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
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
                   where IMM.ACT_MGM_IMPUTATION_ID = MGD.ACT_MGM_IMPUTATION_ID
                     and IMM.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                group by MGD.ACT_MGM_IMPUTATION_ID) MGM
         where MGI.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and MGI.ACT_MGM_IMPUTATION_ID = PJ.ACT_MGM_IMPUTATION_ID(+)
           and MGI.ACT_MGM_IMPUTATION_ID = MGM.ACT_MGM_IMPUTATION_ID(+)
           and MGI.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID(+)
      order by MGI.ACS_CPN_ACCOUNT_ID
             , MGI.ACS_CDA_ACCOUNT_ID
             , MGI.ACS_PF_ACCOUNT_ID
             , PJ.ACS_PJ_ACCOUNT_ID
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , MGI.ACS_PERIOD_ID;

    DocImputations    DocumentImputations%rowtype;
    DocMgmImputations DocumentMgmImputations%rowtype;
    ProfitLoss        ACS_FINANCIAL_ACCOUNT.C_BALANCE_SHEET_PROFIT_LOSS%type;
    DivisionAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    AuxSubSet         ACS_SUB_SET.C_SUB_SET%type;
    DocOk             ACT_DOCUMENT_STATUS.DOC_OK%type;
    DocumentId        ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    UserIni           PCS.PC_USER.USE_INI%type;
    sign              number(1);
    i                 binary_integer;
  -----
  begin
    begin
      select DOC.ACT_DOCUMENT_ID
        into DocumentId
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and not(CAT.C_TYPE_CATALOGUE in('7', '8') );
    exception
      when others then
        DocumentId  := 0;
    end;

    -- Le document existe
    if DocumentId > 0 then
      select max(DOC_OK)
        into DocOk
        from ACT_DOCUMENT_STATUS
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      if DocOk is not null then
        if DocOk = 1 then
          sign  := -1;
        else
          sign  := 1;
        end if;

        UserIni  := PCS.PC_I_LIB_SESSION.GetUserIni2;

        -- Types de cumul à traiter, par sous-ensemble, en fonction de l'état journal correspondant
        for i in 1 .. atblCumul.count loop
          -- Imputations financières
          if     atblCumul(i).C_SUB_SET in('ACC', 'REC', 'PAY')
             and atblCumul(i).C_ETAT_JOURNAL <> 'BRO' then
            open DocumentImputations(aACT_DOCUMENT_ID, atblCumul(i).C_SUB_SET);

            fetch DocumentImputations
             into DocImputations;

            while DocumentImputations%found loop
              ACT_EVOLUTION.FinPeriodsWrite(atblCumul(i).C_SUB_SET
                                          , atblCumul(i).C_TYPE_CUMUL
                                          , DocImputations.ACS_FINANCIAL_ACCOUNT_ID
                                          , DocImputations.ACS_AUXILIARY_ACCOUNT_ID
                                          , DocImputations.ACS_PERIOD_ID
                                          , nvl(DocImputations.IMF_AMOUNT_LC_D, 0) * sign
                                          , nvl(DocImputations.IMF_AMOUNT_LC_C, 0) * sign
                                          , nvl(DocImputations.IMF_AMOUNT_FC_D, 0) * sign
                                          , nvl(DocImputations.IMF_AMOUNT_FC_C, 0) * sign
                                          , nvl(DocImputations.IMF_AMOUNT_EUR_D, 0) * sign
                                          , nvl(DocImputations.IMF_AMOUNT_EUR_C, 0) * sign
                                          , DocImputations.ACS_FINANCIAL_CURRENCY_ID
                                          , DocImputations.FIN_COLLECTIVE
                                          , DocImputations.C_BALANCE_SHEET_PROFIT_LOSS
                                          , DocImputations.ACS_DIVISION_ACCOUNT_ID
                                          , DocImputations.C_TYPE_PERIOD
                                          , UserIni
                                           );

              fetch DocumentImputations
               into DocImputations;
            end loop;

            close DocumentImputations;
          -- Imputations analytiques
          elsif     atblCumul(i).C_SUB_SET = 'CPN'
                and atblCumul(i).C_ETAT_JOURNAL <> 'BRO' then
            open DocumentMgmImputations(aACT_DOCUMENT_ID);

            fetch DocumentMgmImputations
             into DocMgmImputations;

            while DocumentMgmImputations%found loop
              /* écritures sans distribution PJ */
              if DocMgmImputations.ACS_PJ_ACCOUNT_ID is null then
                ACT_MGM_TOTAL_BY_PERIOD.MgmPeriodsWrite(atblCumul(i).C_TYPE_CUMUL
                                                      , DocMgmImputations.ACS_PERIOD_ID
                                                      , DocMgmImputations.ACS_FINANCIAL_CURRENCY_ID
                                                      , DocMgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , DocMgmImputations.ACS_CPN_ACCOUNT_ID
                                                      , DocMgmImputations.ACS_CDA_ACCOUNT_ID
                                                      , DocMgmImputations.ACS_PF_ACCOUNT_ID
                                                      , DocMgmImputations.ACS_QTY_UNIT_ID
                                                      , null
                                                      , DocMgmImputations.ACS_FINANCIAL_ACCOUNT_ID
                                                      , DocMgmImputations.ACS_DIVISION_ACCOUNT_ID
                                                      , DocMgmImputations.DOC_RECORD_ID
                                                      , DocMgmImputations.IMM_AMOUNT_LC_D * sign
                                                      , DocMgmImputations.IMM_AMOUNT_LC_C * sign
                                                      , DocMgmImputations.IMM_AMOUNT_FC_D * sign
                                                      , DocMgmImputations.IMM_AMOUNT_FC_C * sign
                                                      , DocMgmImputations.IMM_AMOUNT_EUR_D * sign
                                                      , DocMgmImputations.IMM_AMOUNT_EUR_C * sign
                                                      , DocMgmImputations.IMM_QUANTITY_D * sign
                                                      , DocMgmImputations.IMM_QUANTITY_C * sign
                                                       );
              else
                /* écritures avec distribution PJ totale */
                if     (DocMgmImputations.DIFLCD = 0)
                   and (DocMgmImputations.DIFLCC = 0)
                   and (DocMgmImputations.DIFFCD = 0)
                   and (DocMgmImputations.DIFFCC = 0)
                   and (DocMgmImputations.DIFEURD = 0)
                   and (DocMgmImputations.DIFEURC = 0)
                   and (DocMgmImputations.DIFQTYD = 0)
                   and (DocMgmImputations.DIFQTYC = 0) then
                  ACT_MGM_TOTAL_BY_PERIOD.MgmPeriodsWrite(atblCumul(i).C_TYPE_CUMUL
                                                        , DocMgmImputations.ACS_PERIOD_ID
                                                        , DocMgmImputations.ACS_FINANCIAL_CURRENCY_ID
                                                        , DocMgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                        , DocMgmImputations.ACS_CPN_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_CDA_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_PF_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_QTY_UNIT_ID
                                                        , DocMgmImputations.ACS_PJ_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_FINANCIAL_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_DIVISION_ACCOUNT_ID
                                                        , DocMgmImputations.DOC_RECORD_ID
                                                        , DocMgmImputations.MGM_AMOUNT_LC_D * sign
                                                        , DocMgmImputations.MGM_AMOUNT_LC_C * sign
                                                        , DocMgmImputations.MGM_AMOUNT_FC_D * sign
                                                        , DocMgmImputations.MGM_AMOUNT_FC_C * sign
                                                        , DocMgmImputations.MGM_AMOUNT_EUR_D * sign
                                                        , DocMgmImputations.MGM_AMOUNT_EUR_C * sign
                                                        , DocMgmImputations.MGM_QUANTITY_D * sign
                                                        , DocMgmImputations.MGM_QUANTITY_C * sign
                                                         );
                else     /* écritures avec distribution PJ partielle */
                       /* Une première écriture avec les montants PJ et compte PJ */
                  ACT_MGM_TOTAL_BY_PERIOD.MgmPeriodsWrite(atblCumul(i).C_TYPE_CUMUL
                                                        , DocMgmImputations.ACS_PERIOD_ID
                                                        , DocMgmImputations.ACS_FINANCIAL_CURRENCY_ID
                                                        , DocMgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                        , DocMgmImputations.ACS_CPN_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_CDA_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_PF_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_QTY_UNIT_ID
                                                        , DocMgmImputations.ACS_PJ_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_FINANCIAL_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_DIVISION_ACCOUNT_ID
                                                        , DocMgmImputations.DOC_RECORD_ID
                                                        , DocMgmImputations.MGM_AMOUNT_LC_D * sign
                                                        , DocMgmImputations.MGM_AMOUNT_LC_C * sign
                                                        , DocMgmImputations.MGM_AMOUNT_FC_D * sign
                                                        , DocMgmImputations.MGM_AMOUNT_FC_C * sign
                                                        , DocMgmImputations.MGM_AMOUNT_EUR_D * sign
                                                        , DocMgmImputations.MGM_AMOUNT_EUR_C * sign
                                                        , DocMgmImputations.MGM_QUANTITY_D * sign
                                                        , DocMgmImputations.MGM_QUANTITY_C * sign
                                                         );
                  /* Une deuxième écriture avec les montants de différence et sans compte PJ */
                  ACT_MGM_TOTAL_BY_PERIOD.MgmPeriodsWrite(atblCumul(i).C_TYPE_CUMUL
                                                        , DocMgmImputations.ACS_PERIOD_ID
                                                        , DocMgmImputations.ACS_FINANCIAL_CURRENCY_ID
                                                        , DocMgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                        , DocMgmImputations.ACS_CPN_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_CDA_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_PF_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_QTY_UNIT_ID
                                                        , null
                                                        , DocMgmImputations.ACS_FINANCIAL_ACCOUNT_ID
                                                        , DocMgmImputations.ACS_DIVISION_ACCOUNT_ID
                                                        , DocMgmImputations.DOC_RECORD_ID
                                                        , DocMgmImputations.DIFLCD * sign
                                                        , DocMgmImputations.DIFLCC * sign
                                                        , DocMgmImputations.DIFFCD * sign
                                                        , DocMgmImputations.DIFFCC * sign
                                                        , DocMgmImputations.DIFEURD * sign
                                                        , DocMgmImputations.DIFEURC * sign
                                                        , DocMgmImputations.DIFQTYD * sign
                                                        , DocMgmImputations.DIFQTYC * sign
                                                         );
                end if;
              end if;

              fetch DocumentMgmImputations
               into DocMgmImputations;
            end loop;

            close DocumentMgmImputations;
          end if;
        end loop;

        -- Mise à jour statut document (traité O/N)
        if DocOk = 1 then
          update ACT_DOCUMENT_STATUS
             set DOC_OK = 0
           where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;
        else
          update ACT_DOCUMENT_STATUS
             set DOC_OK = 1
           where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;
        end if;
      else
        insert into ACT_DOCUMENT_STATUS
                    (ACT_DOCUMENT_STATUS_ID
                   , ACT_DOCUMENT_ID
                   , DOC_OK
                    )
             values (INIT_ID_SEQ.nextval
                   , aACT_DOCUMENT_ID
                   , 0
                    );
      end if;
    end if;
  end WriteDocImputations;

----------------------
  function CompareSubSet(aACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type, aC_SUB_SET ACS_SUB_SET.C_SUB_SET%type)
    return ACS_SUB_SET.C_SUB_SET%type
  is
    SubSet ACS_SUB_SET.C_SUB_SET%type;
  begin
    if aC_SUB_SET = 'ACC' then
      SubSet  := 'ACC';
    else
      -- Détermine le type de sous-ensemble du compte auxiliaire (REC/PAY)
      SubSet  := ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID);
    end if;

    return SubSet;
  end CompareSubSet;

----------------------
  procedure CopyDocument(
    aACT_DOCUMENT_ID                  ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACT_JOB_ID                       ACT_DOCUMENT.ACT_JOB_ID%type
  , pFinYearId                        ACT_DOCUMENT.ACS_FINANCIAL_YEAR_ID%type
  , pPeriodId                         ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type
  , aACJ_CATALOGUE_DOCUMENT_ID        ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aDOC_DOCUMENT_DATE                ACT_DOCUMENT.DOC_DOCUMENT_DATE%type
  , aIMF_TRANSACTION_DATE             ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE                   ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aCopy                             number
  , pCopyBVRRef                       number default 0
  , aExchangeRateCode                 number
  , DocumentId                 in out ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  )
  is
    ------
    cursor DocumentCursor
    is
      select *
        from ACT_DOCUMENT
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    ------
    cursor PartImputationCursor
    is
      select *
        from ACT_PART_IMPUTATION
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    Document         DocumentCursor%rowtype;
    PartImputation   PartImputationCursor%rowtype;
    PartImputationId ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    FinImputationId  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vPeriodId        ACS_PERIOD.ACS_PERIOD_ID%type;
    UserIni          PCS.PC_USER.USE_INI%type;
    OldDocNumber     ACT_DOCUMENT.DOC_NUMBER%type;
    NewDocNumber     ACT_DOCUMENT.DOC_NUMBER%type;
    FinJournal       ACT_DOCUMENT.ACT_JOURNAL_ID%type;
    MgmJournal       ACT_DOCUMENT.ACT_ACT_JOURNAL_ID%type;
    CatalogId        ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    TypePeriod       ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type;
    vCopyBVRRef      number;
    PartnerDoc       boolean;
    tblFinImputation tblFinImputationTyp;
    vDateRef         ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
    vReeval          number;

    --------
    function PartDocument(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
      return boolean
    is
      result boolean                                           default false;
      id     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    begin
      select max(ACT_PART_IMPUTATION_ID)
        into id
        from ACT_PART_IMPUTATION
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      result  :=(id is not null);
      return result;
    end PartDocument;

    --------
    function GetFinImputationId(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
      return ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
    is
      i      binary_integer;
      Ok     boolean;
      result ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type   default null;
    begin
      if aACT_FINANCIAL_IMPUTATION_ID is not null then
        Ok  := false;
        i   := tblFinImputation.first;

        while not Ok
         and i is not null loop
          if tblFinImputation(i).ACT_FIN_OLD_ID = aACT_FINANCIAL_IMPUTATION_ID then
            Ok      := true;
            result  := tblFinImputation(i).ACT_FIN_NEW_ID;
          else
            i  := tblFinImputation.next(i);
          end if;
        end loop;
      end if;

      return result;
    end GetFinImputationId;

    ---------
    procedure InsertVatImputations(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type, aCopy number)
    is
      type tblDetTaxRecTyp is record(
        ACT_DET_TAX_OLD_ID ACT_DET_TAX.ACT_DET_TAX_ID%type
      , ACT_DET_TAX_NEW_ID ACT_DET_TAX.ACT_DET_TAX_ID%type
      );

      type tblDetTaxTyp is table of tblDetTaxRecTyp
        index by binary_integer;

      i              binary_integer                                              default 0;
      j              binary_integer                                              default 0;
      Ok             boolean;
      tblDetTax      tblDetTaxTyp;

      cursor VatImputationsCursor
      is
        select   VAT.*
            from ACT_DET_TAX VAT
               , ACT_FINANCIAL_IMPUTATION IMP
           where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and IMP.ACT_FINANCIAL_IMPUTATION_ID = VAT.ACT_FINANCIAL_IMPUTATION_ID
        order by VAT.ACT_DET_TAX_ID asc
               , VAT.ACT2_DET_TAX_ID desc;

      VatImputations VatImputationsCursor%rowtype;
      Id1            ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
      Id2            ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
      Id3            ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
      IdDed1         ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
      IdDed2         ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
      IdDetTax       ACT_DET_TAX.ACT_DET_TAX_ID%type;
    begin
      open VatImputationsCursor;

      fetch VatImputationsCursor
       into VatImputations;

      while VatImputationsCursor%found loop
        Id1     := GetFinImputationId(VatImputations.ACT_FINANCIAL_IMPUTATION_ID);
        Id2     := GetFinImputationId(VatImputations.ACT_ACT_FINANCIAL_IMPUTATION);
        Id3     := GetFinImputationId(VatImputations.ACT2_ACT_FINANCIAL_IMPUTATION);
        IdDed1  := GetFinImputationId(VatImputations.ACT_DED1_FINANCIAL_IMP_ID);
        IdDed2  := GetFinImputationId(VatImputations.ACT_DED2_FINANCIAL_IMP_ID);

        select init_id_seq.nextval
          into IdDetTax
          from dual;

        if VatImputations.TAX_INCLUDED_EXCLUDED = 'S' then
          tblDetTax(i).ACT_DET_TAX_OLD_ID  := VatImputations.ACT_DET_TAX_ID;
          tblDetTax(i).ACT_DET_TAX_NEW_ID  := IdDetTax;
          i                                := i + 1;
        end if;

        if VatImputations.ACT2_DET_TAX_ID is not null then
          Ok  := false;
          j   := tblDetTax.first;

          while not Ok
           and j is not null loop
            if tblDetTax(j).ACT_DET_TAX_OLD_ID = VatImputations.ACT2_DET_TAX_ID then
              Ok                              := true;
              VatImputations.ACT2_DET_TAX_ID  := tblDetTax(j).ACT_DET_TAX_NEW_ID;
            else
              j  := tblDetTax.next(j);
            end if;
          end loop;
        end if;

        insert into ACT_DET_TAX
                    (ACT_DET_TAX_ID
                   , ACT_FINANCIAL_IMPUTATION_ID
                   , TAX_EXCHANGE_RATE
                   , TAX_INCLUDED_EXCLUDED
                   , TAX_LIABLED_AMOUNT
                   , TAX_LIABLED_RATE
                   , TAX_RATE
                   , TAX_VAT_AMOUNT_FC
                   , TAX_VAT_AMOUNT_LC
                   , TAX_VAT_AMOUNT_EUR
                   , ACS_SUB_SET_ID
                   , ACS_ACCOUNT_ID2
                   , ACT_ACT_FINANCIAL_IMPUTATION
                   , ACT2_ACT_FINANCIAL_IMPUTATION
                   , TAX_REDUCTION
                   , DET_BASE_PRICE
                   , ACT2_DET_TAX_ID
                   , A_DATECRE
                   , A_IDCRE
                   , A_CONFIRM
                   , TAX_TOT_VAT_AMOUNT_FC
                   , TAX_TOT_VAT_AMOUNT_LC
                   , TAX_TOT_VAT_AMOUNT_EUR
                   , ACT_DED1_FINANCIAL_IMP_ID
                   , ACT_DED2_FINANCIAL_IMP_ID
                   , TAX_DEDUCTIBLE_RATE
                   , TAX_TMP_VAT_ENCASHMENT
                    )
             values (IdDetTax
                   , Id1
                   , VatImputations.TAX_EXCHANGE_RATE
                   , VatImputations.TAX_INCLUDED_EXCLUDED
                   , decode(aCopy, 1, VatImputations.TAX_LIABLED_AMOUNT, -VatImputations.TAX_LIABLED_AMOUNT)
                   , VatImputations.TAX_LIABLED_RATE
                   , VatImputations.TAX_RATE
                   , decode(aCopy, 1, VatImputations.TAX_VAT_AMOUNT_FC, -VatImputations.TAX_VAT_AMOUNT_FC)
                   , decode(aCopy, 1, VatImputations.TAX_VAT_AMOUNT_LC, -VatImputations.TAX_VAT_AMOUNT_LC)
                   , decode(aCopy, 1, VatImputations.TAX_VAT_AMOUNT_EUR, -VatImputations.TAX_VAT_AMOUNT_EUR)
                   , VatImputations.ACS_SUB_SET_ID
                   , VatImputations.ACS_ACCOUNT_ID2
                   , Id2
                   , Id3
                   , VatImputations.TAX_REDUCTION
                   , VatImputations.DET_BASE_PRICE
                   , VatImputations.ACT2_DET_TAX_ID
                   , sysdate
                   , UserIni
                   , VatImputations.A_CONFIRM
                   , decode(aCopy, 1, VatImputations.TAX_TOT_VAT_AMOUNT_FC, -VatImputations.TAX_TOT_VAT_AMOUNT_FC)
                   , decode(aCopy, 1, VatImputations.TAX_TOT_VAT_AMOUNT_LC, -VatImputations.TAX_TOT_VAT_AMOUNT_LC)
                   , decode(aCopy, 1, VatImputations.TAX_TOT_VAT_AMOUNT_EUR, -VatImputations.TAX_TOT_VAT_AMOUNT_EUR)
                   , IdDed1
                   , IdDed2
                   , VatImputations.TAX_DEDUCTIBLE_RATE
                   , VatImputations.TAX_TMP_VAT_ENCASHMENT
                    );

        fetch VatImputationsCursor
         into VatImputations;
      end loop;

      close VatImputationsCursor;
    end InsertVatImputations;

    ---------
    procedure InsertMgmImputations(
      aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
    , aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
    , aACJ_CATALOGUE_DOCUMENT_ID   ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
    , aCopy                        number
    )
    is
      cursor MgmImputationsCursor
      is
        select *
          from ACT_MGM_IMPUTATION
         where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and (    (    aACT_FINANCIAL_IMPUTATION_ID is not null
                     and ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID
                    )
                or     aACT_FINANCIAL_IMPUTATION_ID is null
                   and ACT_FINANCIAL_IMPUTATION_ID is null
               );

      cursor MgmDistributionCursor(aACT_MGM_IMPUTATION_ID ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type)
      is
        select *
          from ACT_MGM_DISTRIBUTION
         where ACT_MGM_IMPUTATION_ID = aACT_MGM_IMPUTATION_ID;

      MgmImputations        MgmImputationsCursor%rowtype;
      MgmDistribution       MgmDistributionCursor%rowtype;
      MgmImputationId       ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
      MgmDistributionId     ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type;
      vMgmTransactionDate   ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type;
      vMgmValueDate         ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type;
      InfoImputationValues  ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
      InfoImputationManaged ACT_IMP_MANAGEMENT.InfoImputationRecType;
    begin
      -- Imputations analytiques
      open MgmImputationsCursor;

      fetch MgmImputationsCursor
       into MgmImputations;

      -- Recherche des info. complémentaire gérées
      if MgmImputationsCursor%found then
        InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(aACJ_CATALOGUE_DOCUMENT_ID);
      end if;

      while MgmImputationsCursor%found loop
        /*Initialisation période pour calcul délais*/
        if     (pPeriodId <> 0)
           and (not pPeriodId is null) then
          vPeriodId  := pPeriodId;
        else
          vPeriodId  := null;
        end if;

        vMgmTransactionDate  := aIMF_TRANSACTION_DATE;
        vMgmValueDate        := aIMF_VALUE_DATE;

        /*Date de transaction non renseignée...*/
        if vMgmTransactionDate is null then
          /*Calcul délai selon date transaction imputation...*/
          vMgmTransactionDate  := AddDateDelay(MgmImputations.IMM_TRANSACTION_DATE, pkgDateInterval, pkgDelayCode);
          /*Contrôle validité date transaction selon exercice et / ou période*/
          vMgmTransactionDate  := ValidateDate(vMgmTransactionDate, pFinYearId, vPeriodId);
        end if;

        /*Date valeur non renseigné*/
        if vMgmValueDate is null then
          /*Calcul délai selon date valeur de l'imputation */
          vMgmValueDate  := AddDateDelay(MgmImputations.IMM_VALUE_DATE, pkgDateInterval, pkgDelayCode);
            /*Contrôle validité date valeur selon exercice et / ou période*/
--            vMgmValueDate := ValidateDate(vMgmValueDate,pFinYearId,vPeriodId);
        end if;

        /*Initialisation période selon date transaction calculée*/
        if vPeriodId is null then
          vPeriodId  := ACS_FUNCTION.GetPeriodID(vMgmTransactionDate, TypePeriod);
        end if;

        select init_id_seq.nextval
          into MgmImputationId
          from dual;

        insert into ACT_MGM_IMPUTATION
                    (ACT_MGM_IMPUTATION_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , ACS_PERIOD_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACT_DOCUMENT_ID
                   , ACT_FINANCIAL_IMPUTATION_ID
                   , IMM_TYPE
                   , IMM_GENRE
                   , IMM_PRIMARY
                   , IMM_DESCRIPTION
                   , IMM_AMOUNT_LC_D
                   , IMM_AMOUNT_LC_C
                   , IMM_AMOUNT_FC_D
                   , IMM_AMOUNT_FC_C
                   , IMM_AMOUNT_EUR_D
                   , IMM_AMOUNT_EUR_C
                   , IMM_EXCHANGE_RATE
                   , IMM_BASE_PRICE
                   , IMM_VALUE_DATE
                   , IMM_TRANSACTION_DATE
                   , ACS_QTY_UNIT_ID
                   , IMM_QUANTITY_D
                   , IMM_QUANTITY_C
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (MgmImputationId
                   , MgmImputations.ACS_FINANCIAL_CURRENCY_ID
                   , MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                   , vPeriodId
                   , MgmImputations.ACS_CPN_ACCOUNT_ID
                   , MgmImputations.ACS_CDA_ACCOUNT_ID
                   , MgmImputations.ACS_PF_ACCOUNT_ID
                   , DocumentId
                   , FinImputationId
                   , MgmImputations.IMM_TYPE
                   , MgmImputations.IMM_GENRE
                   , MgmImputations.IMM_PRIMARY
                   , replace(MgmImputations.IMM_DESCRIPTION, OldDocNumber, NewDocNumber)
                   , decode(aCopy
                          , 1, MgmImputations.IMM_AMOUNT_LC_D
                          , 2, MgmImputations.IMM_AMOUNT_LC_C
                          , 3, -MgmImputations.IMM_AMOUNT_LC_D
                           )
                   , decode(aCopy
                          , 1, MgmImputations.IMM_AMOUNT_LC_C
                          , 2, MgmImputations.IMM_AMOUNT_LC_D
                          , 3, -MgmImputations.IMM_AMOUNT_LC_C
                           )
                   , decode(aCopy
                          , 1, MgmImputations.IMM_AMOUNT_FC_D
                          , 2, MgmImputations.IMM_AMOUNT_FC_C
                          , 3, -MgmImputations.IMM_AMOUNT_FC_D
                           )
                   , decode(aCopy
                          , 1, MgmImputations.IMM_AMOUNT_FC_C
                          , 2, MgmImputations.IMM_AMOUNT_FC_D
                          , 3, -MgmImputations.IMM_AMOUNT_FC_C
                           )
                   , decode(aCopy
                          , 1, MgmImputations.IMM_AMOUNT_EUR_D
                          , 2, MgmImputations.IMM_AMOUNT_EUR_C
                          , 3, -MgmImputations.IMM_AMOUNT_EUR_D
                           )
                   , decode(aCopy
                          , 1, MgmImputations.IMM_AMOUNT_EUR_C
                          , 2, MgmImputations.IMM_AMOUNT_EUR_D
                          , 3, -MgmImputations.IMM_AMOUNT_EUR_C
                           )
                   , MgmImputations.IMM_EXCHANGE_RATE
                   , MgmImputations.IMM_BASE_PRICE
                   , vMgmValueDate
                   , vMgmTransactionDate
                   , MgmImputations.ACS_QTY_UNIT_ID
                   , decode(aCopy
                          , 1, MgmImputations.IMM_QUANTITY_D
                          , 2, MgmImputations.IMM_QUANTITY_C
                          , 3, -MgmImputations.IMM_QUANTITY_D
                           )
                   , decode(aCopy
                          , 1, MgmImputations.IMM_QUANTITY_C
                          , 2, MgmImputations.IMM_QUANTITY_D
                          , 3, -MgmImputations.IMM_QUANTITY_C
                           )
                   , sysdate
                   , UserIni
                    );

        if InfoImputationManaged.managed then
          ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMM(MgmImputations.ACT_MGM_IMPUTATION_ID, InfoImputationValues);

          if MgmImputations.IMM_PRIMARY = 1 then
            ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMM(MgmImputationId
                                                        , InfoImputationValues
                                                        , InfoImputationManaged.primary
                                                         );
          else
            ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMM(MgmImputationId
                                                        , InfoImputationValues
                                                        , InfoImputationManaged.Secondary
                                                         );
          end if;
        end if;

        open MgmDistributionCursor(MgmImputations.ACT_MGM_IMPUTATION_ID);

        fetch MgmDistributionCursor
         into MgmDistribution;

        while MgmDistributionCursor%found loop
          select init_id_seq.nextval
            into MgmDistributionId
            from dual;

          insert into ACT_MGM_DISTRIBUTION
                      (ACT_MGM_DISTRIBUTION_ID
                     , ACT_MGM_IMPUTATION_ID
                     , ACS_PJ_ACCOUNT_ID
                     , ACS_SUB_SET_ID
                     , MGM_DESCRIPTION
                     , MGM_AMOUNT_LC_D
                     , MGM_AMOUNT_LC_C
                     , MGM_AMOUNT_FC_D
                     , MGM_AMOUNT_FC_C
                     , MGM_AMOUNT_EUR_D
                     , MGM_AMOUNT_EUR_C
                     , MGM_QUANTITY_D
                     , MGM_QUANTITY_C
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (MgmDistributionId
                     , MgmImputationId
                     , MgmDistribution.ACS_PJ_ACCOUNT_ID
                     , MgmDistribution.ACS_SUB_SET_ID
                     , replace(MgmDistribution.MGM_DESCRIPTION, OldDocNumber, NewDocNumber)
                     , decode(aCopy
                            , 1, MgmDistribution.MGM_AMOUNT_LC_D
                            , 2, MgmDistribution.MGM_AMOUNT_LC_C
                            , 3, -MgmDistribution.MGM_AMOUNT_LC_D
                             )
                     , decode(aCopy
                            , 1, MgmDistribution.MGM_AMOUNT_LC_C
                            , 2, MgmDistribution.MGM_AMOUNT_LC_D
                            , 3, -MgmDistribution.MGM_AMOUNT_LC_C
                             )
                     , decode(aCopy
                            , 1, MgmDistribution.MGM_AMOUNT_FC_D
                            , 2, MgmDistribution.MGM_AMOUNT_FC_C
                            , 3, -MgmDistribution.MGM_AMOUNT_FC_D
                             )
                     , decode(aCopy
                            , 1, MgmDistribution.MGM_AMOUNT_FC_C
                            , 2, MgmDistribution.MGM_AMOUNT_FC_D
                            , 3, -MgmDistribution.MGM_AMOUNT_FC_C
                             )
                     , decode(aCopy
                            , 1, MgmDistribution.MGM_AMOUNT_EUR_D
                            , 2, MgmDistribution.MGM_AMOUNT_EUR_C
                            , 3, -MgmDistribution.MGM_AMOUNT_EUR_D
                             )
                     , decode(aCopy
                            , 1, MgmDistribution.MGM_AMOUNT_EUR_C
                            , 2, MgmDistribution.MGM_AMOUNT_EUR_D
                            , 3, -MgmDistribution.MGM_AMOUNT_EUR_C
                             )
                     , decode(aCopy
                            , 1, MgmDistribution.MGM_QUANTITY_D
                            , 2, MgmDistribution.MGM_QUANTITY_C
                            , 3, -MgmDistribution.MGM_QUANTITY_D
                             )
                     , decode(aCopy
                            , 1, MgmDistribution.MGM_QUANTITY_C
                            , 2, MgmDistribution.MGM_QUANTITY_D
                            , 3, -MgmDistribution.MGM_QUANTITY_C
                             )
                     , sysdate
                     , UserIni
                      );

          if InfoImputationManaged.managed then
            ACT_IMP_MANAGEMENT.GetInfoImputationValuesMGM(MgmDistribution.ACT_MGM_DISTRIBUTION_ID
                                                        , InfoImputationValues);

            if MgmImputations.IMM_PRIMARY = 1 then
              ACT_IMP_MANAGEMENT.SetInfoImputationValuesMGM(MgmDistributionId
                                                          , InfoImputationValues
                                                          , InfoImputationManaged.primary
                                                           );
            else
              ACT_IMP_MANAGEMENT.SetInfoImputationValuesMGM(MgmDistributionId
                                                          , InfoImputationValues
                                                          , InfoImputationManaged.Secondary
                                                           );
            end if;
          end if;

          fetch MgmDistributionCursor
           into MgmDistribution;
        end loop;

        close MgmDistributionCursor;

        fetch MgmImputationsCursor
         into MgmImputations;
      end loop;

      close MgmImputationsCursor;
    end InsertMgmImputations;

    ---------
    function InsertImputations(
      aACT_DOCUMENT_ID           ACT_DOCUMENT.ACT_DOCUMENT_ID%type
    , aACT_PART_IMPUTATION_ID    ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
    , aACJ_CATALOGUE_DOCUMENT_ID ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
    , aCopy                      number
    )
      return ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
    is
      cursor FinImputationsCursor
      is
        select   IMP.*
               , DIS.ACT_FINANCIAL_DISTRIBUTION_ID
               , DIS.FIN_DESCRIPTION
               , DIS.FIN_AMOUNT_LC_D
               , DIS.FIN_AMOUNT_FC_D
               , DIS.ACS_SUB_SET_ID
               , DIS.FIN_AMOUNT_LC_C
               , DIS.FIN_AMOUNT_FC_C
               , DIS.ACS_DIVISION_ACCOUNT_ID
               , DIS.FIN_AMOUNT_EUR_D
               , DIS.FIN_AMOUNT_EUR_C
            from ACT_FINANCIAL_DISTRIBUTION DIS
               , ACT_FINANCIAL_IMPUTATION IMP
           where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and (    (    aACT_PART_IMPUTATION_ID is not null
                       and IMP.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID)
                  or     aACT_PART_IMPUTATION_ID is null
                     and (   IMP.ACT_PART_IMPUTATION_ID is null
                          or IMP.ACT_PART_IMPUTATION_ID = 0)
                 )
             and IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
        order by IMP.ACT_FINANCIAL_IMPUTATION_ID;

      FinImputations        FinImputationsCursor%rowtype;
      i                     binary_integer                                       default 0;
      vFinTransactionDate   ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
      vFinValueDate         ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
      vExpiryRefDate        ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
      InfoImputationValues  ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
      InfoImputationManaged ACT_IMP_MANAGEMENT.InfoImputationRecType;
    begin
      -- Imputations financières
      tblFinImputation.delete;

      open FinImputationsCursor;

      fetch FinImputationsCursor
       into FinImputations;

      -- Recherche des info. complémentaire gérées
      if FinImputationsCursor%found then
        InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(aACJ_CATALOGUE_DOCUMENT_ID);
      end if;

      while FinImputationsCursor%found loop
        /*Initialisation période pour calcul délais*/
        if     (pPeriodId <> 0)
           and (not pPeriodId is null) then
          vPeriodId  := pPeriodId;
        else
          vPeriodId  := null;
        end if;

        vFinTransactionDate                 := aIMF_TRANSACTION_DATE;
        vFinValueDate                       := aIMF_VALUE_DATE;

        /*Date de transaction non renseignée...*/
        if vFinTransactionDate is null then
          /*Calcul délai selon date transaction imputation...*/
          vFinTransactionDate  := AddDateDelay(FinImputations.IMF_TRANSACTION_DATE, pkgDateInterval, pkgDelayCode);
          /*Contrôle validité date transaction selon exercice et / ou période*/
          vFinTransactionDate  := ValidateDate(vFinTransactionDate, pFinYearId, vPeriodId);
        end if;

        /*Date valeur non renseigné*/
        if vFinValueDate is null then
          /*Calcul délai selon date valeur de l'imputation */
          vFinValueDate  := AddDateDelay(FinImputations.IMF_VALUE_DATE, pkgDateInterval, pkgDelayCode);
            /*Contrôle validité date valeur selon exercice et / ou période*/
--            vFinValueDate := ValidateDate(vFinValueDate,pFinYearId,vPeriodId);
        end if;

        if     (not aACT_PART_IMPUTATION_ID is null)
           and (aACT_PART_IMPUTATION_ID <> 0)
           and (FinImputations.IMF_PRIMARY = 1) then
          vExpiryRefDate  := vFinValueDate;
        end if;

        /*Initialisation période selon date transaction calculée*/
        if vPeriodId is null then
          vPeriodId  := ACS_FUNCTION.GetPeriodID(vFinTransactionDate, TypePeriod);
        end if;

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
                   , IMF_AMOUNT_FC_D
                   , IMF_AMOUNT_FC_C
                   , IMF_AMOUNT_EUR_D
                   , IMF_AMOUNT_EUR_C
                   , IMF_EXCHANGE_RATE
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
                   , ACT_PART_IMPUTATION_ID
                   , IMF_COMPARE_DATE
                   , IMF_CONTROL_DATE
                   , IMF_COMPARE_TEXT
                   , IMF_CONTROL_TEXT
                   , IMF_COMPARE_USE_INI
                   , IMF_CONTROL_USE_INI
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (FinImputationId
                   , vPeriodId
                   , DocumentId
                   , FinImputations.ACS_FINANCIAL_ACCOUNT_ID
                   , FinImputations.IMF_TYPE
                   , FinImputations.IMF_PRIMARY
                   , replace(FinImputations.IMF_DESCRIPTION, OldDocNumber, NewDocNumber)
                   , decode(aCopy
                          , 1, FinImputations.IMF_AMOUNT_LC_D
                          , 2, FinImputations.IMF_AMOUNT_LC_C
                          , 3, -FinImputations.IMF_AMOUNT_LC_D
                           )
                   , decode(aCopy
                          , 1, FinImputations.IMF_AMOUNT_LC_C
                          , 2, FinImputations.IMF_AMOUNT_LC_D
                          , 3, -FinImputations.IMF_AMOUNT_LC_C
                           )
                   , decode(aCopy
                          , 1, FinImputations.IMF_AMOUNT_FC_D
                          , 2, FinImputations.IMF_AMOUNT_FC_C
                          , 3, -FinImputations.IMF_AMOUNT_FC_D
                           )
                   , decode(aCopy
                          , 1, FinImputations.IMF_AMOUNT_FC_C
                          , 2, FinImputations.IMF_AMOUNT_FC_D
                          , 3, -FinImputations.IMF_AMOUNT_FC_C
                           )
                   , decode(aCopy
                          , 1, FinImputations.IMF_AMOUNT_EUR_D
                          , 2, FinImputations.IMF_AMOUNT_EUR_C
                          , 3, -FinImputations.IMF_AMOUNT_EUR_D
                           )
                   , decode(aCopy
                          , 1, FinImputations.IMF_AMOUNT_EUR_C
                          , 2, FinImputations.IMF_AMOUNT_EUR_D
                          , 3, -FinImputations.IMF_AMOUNT_EUR_C
                           )
                   , FinImputations.IMF_EXCHANGE_RATE
                   , vFinValueDate
                   , FinImputations.ACS_TAX_CODE_ID
                   , vFinTransactionDate
                   , FinImputations.ACS_AUXILIARY_ACCOUNT_ID
                   , null   --  FinImputations.ACT_DET_PAYMENT_ID,
                   , FinImputations.IMF_GENRE
                   , FinImputations.IMF_BASE_PRICE
                   , FinImputations.ACS_FINANCIAL_CURRENCY_ID
                   , FinImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                   , FinImputations.C_GENRE_TRANSACTION
                   , PartImputationId
                   , null   --  FinImputations.IMF_COMPARE_DATE,
                   , null   --  FinImputations.IMF_CONTROL_DATE,
                   , null   --  FinImputations.IMF_COMPARE_TEXT,
                   , null   --  FinImputations.IMF_CONTROL_TEXT,
                   , null   --  FinImputations.IMF_COMPARE_USE_INI,
                   , null   --  FinImputations.IMF_CONTROL_USE_INI,
                   , sysdate
                   , UserIni
                    );

        if InfoImputationManaged.managed then
          ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMF(FinImputations.ACT_FINANCIAL_IMPUTATION_ID
                                                      , InfoImputationValues
                                                       );

          if FinImputations.IMF_PRIMARY = 1 then
            ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(FinImputationId
                                                        , InfoImputationValues
                                                        , InfoImputationManaged.primary
                                                         );
          else
            ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(FinImputationId
                                                        , InfoImputationValues
                                                        , InfoImputationManaged.Secondary
                                                         );
          end if;
        end if;

        -- Distribution - Divisions
        if FinImputations.ACT_FINANCIAL_DISTRIBUTION_ID is not null then
          insert into ACT_FINANCIAL_DISTRIBUTION
                      (ACT_FINANCIAL_DISTRIBUTION_ID
                     , ACT_FINANCIAL_IMPUTATION_ID
                     , FIN_DESCRIPTION
                     , FIN_AMOUNT_LC_D
                     , FIN_AMOUNT_LC_C
                     , FIN_AMOUNT_FC_D
                     , FIN_AMOUNT_FC_C
                     , FIN_AMOUNT_EUR_D
                     , FIN_AMOUNT_EUR_C
                     , ACS_SUB_SET_ID
                     , ACS_DIVISION_ACCOUNT_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (init_id_seq.nextval
                     , FinImputationId
                     , replace(FinImputations.FIN_DESCRIPTION, OldDocNumber, NewDocNumber)
                     , decode(aCopy
                            , 1, FinImputations.FIN_AMOUNT_LC_D
                            , 2, FinImputations.FIN_AMOUNT_LC_C
                            , 3, -FinImputations.FIN_AMOUNT_LC_D
                             )
                     , decode(aCopy
                            , 1, FinImputations.FIN_AMOUNT_LC_C
                            , 2, FinImputations.FIN_AMOUNT_LC_D
                            , 3, -FinImputations.FIN_AMOUNT_LC_C
                             )
                     , decode(aCopy
                            , 1, FinImputations.FIN_AMOUNT_FC_D
                            , 2, FinImputations.FIN_AMOUNT_FC_C
                            , 3, -FinImputations.FIN_AMOUNT_FC_D
                             )
                     , decode(aCopy
                            , 1, FinImputations.FIN_AMOUNT_FC_C
                            , 2, FinImputations.FIN_AMOUNT_FC_D
                            , 3, -FinImputations.FIN_AMOUNT_FC_C
                             )
                     , decode(aCopy
                            , 1, FinImputations.FIN_AMOUNT_EUR_D
                            , 2, FinImputations.FIN_AMOUNT_EUR_C
                            , 3, -FinImputations.FIN_AMOUNT_EUR_D
                             )
                     , decode(aCopy
                            , 1, FinImputations.FIN_AMOUNT_EUR_C
                            , 2, FinImputations.FIN_AMOUNT_EUR_D
                            , 3, -FinImputations.FIN_AMOUNT_EUR_C
                             )
                     , FinImputations.ACS_SUB_SET_ID
                     , FinImputations.ACS_DIVISION_ACCOUNT_ID
                     , sysdate
                     , UserIni
                      );
        end if;

        -- Imputations analytiques
        InsertMgmImputations(aACT_DOCUMENT_ID
                           , FinImputations.ACT_FINANCIAL_IMPUTATION_ID
                           , aACJ_CATALOGUE_DOCUMENT_ID
                           , aCopy
                            );
        i                                   := i + 1;
        tblFinImputation(i).ACT_FIN_OLD_ID  := FinImputations.ACT_FINANCIAL_IMPUTATION_ID;
        tblFinImputation(i).ACT_FIN_NEW_ID  := FinImputationId;

        fetch FinImputationsCursor
         into FinImputations;
      end loop;

      close FinImputationsCursor;

      InsertVatImputations(aACT_DOCUMENT_ID, aCopy);
      return vExpiryRefDate;
    end InsertImputations;

    ---------
    procedure InsertExpirys(
      aACT_PART_IMPUTATION ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
    , pDateRef             ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
    )
    is
      RefBVR  ACT_EXPIRY.EXP_REF_BVR%type;
      BVRCode ACT_EXPIRY.EXP_BVR_CODE%type;
    begin
      --Copie des références et ligne de code BVR des échéances si reprise = 1
      if vCopyBVRRef = 1 then
        begin
          select EXP_REF_BVR
               , EXP_BVR_CODE
            into RefBVR
               , BVRCode
            from ACT_EXPIRY
           where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION
             and EXP_REF_BVR is not null
             and rownum = 1;
        exception
          when no_data_found then
            RefBVR   := null;
            BVRCode  := null;
        end;
      else
        -- Mise à jour N° référence BVR et Ligne de codage BVR selon méthode définie dans la transaction courante
        -- Uniquement si une méthode de paiement est définie sur la transaction courante !
        RefBVR   := null;
        BVRCode  := null;
      end if;

      ACT_EXPIRY_MANAGEMENT.GenerateExpiriesACT(PartImputationId, null, RefBVR, BVRCode);
    end InsertExpirys;

    --------
    function GetTypePeriod(aACJ_CATALOGUE_DOCUMENT_ID ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type)
      return ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type
    is
      result ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type;
    begin
      begin
        select C_TYPE_PERIOD
          into result
          from ACJ_CATALOGUE_DOCUMENT
         where ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID;
      exception
        when others then
          result  := null;
      end;

      return result;
    end GetTypePeriod;
  -----
  -----
  begin
    PartnerDoc  := PartDocument(aACT_DOCUMENT_ID);

    if not(    PartnerDoc
           and aCopy = 0) then   -- On n'extourne pas les documents partenaires !!!
      UserIni       := PCS.PC_I_LIB_SESSION.GetUserIni2;

      -- En-tête document
      open DocumentCursor;

      fetch DocumentCursor
       into Document;

      if     aACJ_CATALOGUE_DOCUMENT_ID is not null
         and aACJ_CATALOGUE_DOCUMENT_ID > 0 then
        CatalogId  := aACJ_CATALOGUE_DOCUMENT_ID;
      else
        CatalogId  := Document.ACJ_CATALOGUE_DOCUMENT_ID;
      end if;

      --Reprise des références bvr uniquement pour les documents créanciers
      vCopyBVRRef   := pCopyBVRRef;

      begin
        select decode(C_SUB_SET, 'PAY', 1, 0) * pCopyBVRRef
          into vCopyBVRRef
          from ACJ_SUB_SET_CAT
         where C_SUB_SET = 'PAY'
           and ACJ_CATALOGUE_DOCUMENT_ID = CatalogId;
      exception
        when others then
          vCopyBVRRef  := 0;
      end;

      TypePeriod    := GetTypePeriod(CatalogId);

      if aACT_JOB_ID <> Document.ACT_JOB_ID then
        if Document.ACT_JOURNAL_ID is not null then
          select max(JOU.ACT_JOURNAL_ID)
            into FinJournal
            from ACS_ACCOUNTING ACC
               , ACT_JOURNAL JOU
           where ACT_JOB_ID = aACT_JOB_ID
             and JOU.ACS_ACCOUNTING_ID = ACC.ACS_ACCOUNTING_ID
             and ACC.C_TYPE_ACCOUNTING = 'FIN';
        else
          FinJournal  := null;
        end if;

        if Document.ACT_ACT_JOURNAL_ID is not null then
          select max(JOU.ACT_JOURNAL_ID)
            into MgmJournal
            from ACS_ACCOUNTING ACC
               , ACT_JOURNAL JOU
           where ACT_JOB_ID = aACT_JOB_ID
             and JOU.ACS_ACCOUNTING_ID = ACC.ACS_ACCOUNTING_ID
             and ACC.C_TYPE_ACCOUNTING = 'MAN';
        else
          MgmJournal  := null;
        end if;
      else
        FinJournal  := Document.ACT_JOURNAL_ID;
        MgmJournal  := Document.ACT_ACT_JOURNAL_ID;
      end if;

      OldDocNumber  := Document.DOC_NUMBER;
      -- Numérotation document
      ACT_FUNCTIONS.GetDocNumber(CatalogId, pFinYearId, NewDocNumber);

      select init_id_seq.nextval
        into DocumentId
        from dual;

      insert into ACT_DOCUMENT
                  (ACT_DOCUMENT_ID
                 , ACT_JOB_ID
                 , PC_USER_ID
                 , DOC_NUMBER
                 , DOC_TOTAL_AMOUNT_DC
                 , DOC_DOCUMENT_DATE
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACJ_CATALOGUE_DOCUMENT_ID
                 , ACT_JOURNAL_ID
                 , ACT_ACT_JOURNAL_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , DOC_CHARGES_LC
                 , ACS_FINANCIAL_YEAR_ID
                 , DOC_COMMENT
                 , DOC_CCP_TAX
                 , DOC_ORDER_NO
                 , DOC_EFFECTIVE_DATE
                 , DOC_EXECUTIVE_DATE
                 , DOC_ESTABL_DATE
                 , DOC_DOCUMENT_ID
                 , COM_NAME_DOC
                 , COM_NAME_ACT
                 , C_STATUS_DOCUMENT
                 , COM_OLE_ID
                 , DIC_DOC_SOURCE_ID
                 , DIC_DOC_DESTINATION_ID
                 , ACS_FIN_ACC_S_PAYMENT_ID
                 , DOC_TOTAL_AMOUNT_EUR
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (DocumentId
                 , aACT_JOB_ID
                 , Document.PC_USER_ID
                 , NewDocNumber   -- Document.DOC_NUMBER,
                 , Document.DOC_TOTAL_AMOUNT_DC
                 , aDOC_DOCUMENT_DATE
                 , Document.ACS_FINANCIAL_CURRENCY_ID
                 , CatalogId
                 , FinJournal
                 , MgmJournal
                 , Document.ACS_FINANCIAL_ACCOUNT_ID
                 , Document.DOC_CHARGES_LC
                 , pFinYearId   -- Document.ACS_FINANCIAL_YEAR_ID,
                 , Document.DOC_COMMENT
                 , Document.DOC_CCP_TAX
                 , Document.DOC_ORDER_NO
                 , Document.DOC_EFFECTIVE_DATE
                 , Document.DOC_EXECUTIVE_DATE
                 , Document.DOC_ESTABL_DATE
                 , Document.DOC_DOCUMENT_ID
                 , Document.COM_NAME_DOC
                 , Document.COM_NAME_ACT
                 , decode(aCopy, 0, 'EXT', Document.C_STATUS_DOCUMENT)
                 , Document.COM_OLE_ID
                 , Document.DIC_DOC_SOURCE_ID
                 , Document.DIC_DOC_DESTINATION_ID
                 , Document.ACS_FIN_ACC_S_PAYMENT_ID
                 , Document.DOC_TOTAL_AMOUNT_EUR
                 , sysdate
                 , UserIni
                  );

      close DocumentCursor;

      if PartnerDoc then
        -- Imputations partenaires
        open PartImputationCursor;

        fetch PartImputationCursor
         into PartImputation;

        while PartImputationCursor%found loop
          select init_id_seq.nextval
            into PartImputationId
            from dual;

          insert into ACT_PART_IMPUTATION
                      (ACT_DOCUMENT_ID
                     , ACT_PART_IMPUTATION_ID
                     , PAR_DOCUMENT
                     , PAR_BLOCKED_DOCUMENT
                     , PAC_CUSTOM_PARTNER_ID
                     , PAC_PAYMENT_CONDITION_ID
                     , PAC_SUPPLIER_PARTNER_ID
                     , PAC_FINANCIAL_REFERENCE_ID
                     , ACS_FINANCIAL_CURRENCY_ID
                     , ACS_ACS_FINANCIAL_CURRENCY_ID
                     , PAR_PAIED_LC
                     , PAR_CHARGES_LC
                     , PAR_PAIED_FC
                     , PAR_CHARGES_FC
                     , PAR_EXCHANGE_RATE
                     , PAR_BASE_PRICE
                     , PAC_ADDRESS_ID
                     , PAR_REMIND_DATE
                     , PAR_REMIND_PRINTDATE
                     , DIC_PRIORITY_PAYMENT_ID
                     , DIC_CENTER_PAYMENT_ID
                     , DIC_LEVEL_PRIORITY_ID
                     , PAC_COMMUNICATION_ID
                     , ACT_COVER_INFORMATION_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (DocumentId
                     , PartImputationId
                     , PartImputation.PAR_DOCUMENT
                     , PartImputation.PAR_BLOCKED_DOCUMENT
                     , PartImputation.PAC_CUSTOM_PARTNER_ID
                     , PartImputation.PAC_PAYMENT_CONDITION_ID
                     , PartImputation.PAC_SUPPLIER_PARTNER_ID
                     , PartImputation.PAC_FINANCIAL_REFERENCE_ID
                     , PartImputation.ACS_FINANCIAL_CURRENCY_ID
                     , PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , PartImputation.PAR_PAIED_LC
                     , PartImputation.PAR_CHARGES_LC
                     , PartImputation.PAR_PAIED_FC
                     , PartImputation.PAR_CHARGES_FC
                     , PartImputation.PAR_EXCHANGE_RATE
                     , PartImputation.PAR_BASE_PRICE
                     , PartImputation.PAC_ADDRESS_ID
                     , PartImputation.PAR_REMIND_DATE
                     , PartImputation.PAR_REMIND_PRINTDATE
                     , PartImputation.DIC_PRIORITY_PAYMENT_ID
                     , PartImputation.DIC_CENTER_PAYMENT_ID
                     , PartImputation.DIC_LEVEL_PRIORITY_ID
                     , PartImputation.PAC_COMMUNICATION_ID
                     , null   -- PartImputation.ACT_COVER_INFORMATION_ID,
                     , sysdate
                     , UserIni
                      );

          vDateRef  := InsertImputations(aACT_DOCUMENT_ID, PartImputation.ACT_PART_IMPUTATION_ID, CatalogId, aCopy);
          InsertExpirys(PartImputation.ACT_PART_IMPUTATION_ID, vDateRef);

          fetch PartImputationCursor
           into PartImputation;
        end loop;

        close PartImputationCursor;
      else
        vDateRef  := InsertImputations(aACT_DOCUMENT_ID, null, CatalogId, aCopy);
      end if;

      -- Si document analytique sans imputations financières
      InsertMgmImputations(aACT_DOCUMENT_ID, null, CatalogId, aCopy);

      -- Recherche si document de réévalutation -> pas de màj des cours
      select decode(min(ACJ_EVENT.C_TYPE_EVENT), '8', 1, 0)
        into vReeval
        from ACT_JOB
           , ACJ_EVENT
       where ACT_JOB.ACT_JOB_ID = Document.ACT_JOB_ID
         and ACT_JOB.ACJ_JOB_TYPE_ID = ACJ_EVENT.ACJ_JOB_TYPE_ID
         and ACJ_EVENT.C_TYPE_EVENT = '8';

      if vReeval = 0 then
        -- Màj du cours de change (et des montants MB ou ME) du document
        UpdateDocExchangeRate(DocumentId, aExchangeRateCode);
      end if;

      -- Màj id du document extourné dans l'extourne
      if aCopy > 1 then
        update ACT_DOCUMENT
           set ACT_DOCUMENT_EXT_ID = aACT_DOCUMENT_ID
         where ACT_DOCUMENT_ID = DocumentId;
      end if;

      insert into ACT_DOCUMENT_STATUS
                  (ACT_DOCUMENT_STATUS_ID
                 , ACT_DOCUMENT_ID
                 , DOC_OK
                  )
           values (init_id_seq.nextval
                 , DocumentId
                 , 0
                  );

      -- Calcul des cumuls du document créé
      ACT_DOC_TRANSACTION.DocImputations(DocumentId, 0);
    end if;
  end CopyDocument;

-----------------
  procedure CopyJob(
    aACT_JOB_ID                   ACT_JOB.ACT_JOB_ID%type
  , aACS_FINANCIAL_YEAR_ID        ACT_JOB.ACS_FINANCIAL_YEAR_ID%type
  , aACS_PERIOD_ID                ACT_JOB.ACS_PERIOD_ID%type
  , aDOC_DOCUMENT_DATE            ACT_DOCUMENT.DOC_DOCUMENT_DATE%type
  , aIMF_TRANSACTION_DATE         ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE               ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aJOB_DESCRIPTION              ACT_JOB.JOB_DESCRIPTION%type
  , aCopy                         number   -- Copie ou Extourne
  , pCopyBVRRef                   number default 0   --1: Reprise des références bvr des document avec échéances
  , pInterval                     number
  , pDelayCode                    number
  , aExchangeRateCode             number
  , JobId                  in out ACT_JOB.ACT_JOB_ID%type
  )
  is
    ------
    cursor DocumentToCopyCursor(aCopy number)
    is
      select ACT_DOCUMENT_ID
           , DOC_DOCUMENT_DATE
        from ACJ_JOB_TYPE_S_CATALOGUE JCA
           , ACT_JOB JOB
           , ACT_DOCUMENT DOC
       where DOC.ACT_JOB_ID = aACT_JOB_ID
         and DOC.ACT_JOB_ID = JOB.ACT_JOB_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = JCA.ACJ_CATALOGUE_DOCUMENT_ID
         and JOB.ACJ_JOB_TYPE_ID = JCA.ACJ_JOB_TYPE_ID
         and decode(aCopy, 1, JCA.JCA_COPY_POSSIBLE, JCA.JCA_EXT_POSSIBLE) = 1
         and (    (aCopy = 1)
              or (     (aCopy > 1)
                  and (not exists(select 0
                                    from ACT_DOCUMENT
                                   where DOC.ACT_DOCUMENT_ID = ACT_DOCUMENT_EXT_ID) ) ) );

    DocumentToCopy DocumentToCopyCursor%rowtype;
    DocumentId     ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    UserIni        PCS.PC_USER.USE_INI%type;
    UserId         PCS.PC_USER.PC_USER_ID%type;
    PeriodId       ACT_JOB.ACS_PERIOD_ID%type;
    vTargetDocDate ACT_DOCUMENT.DOC_DOCUMENT_DATE%type;

    ---------
    procedure CreateJob
    is
      cursor JobCursor
      is
        select *
          from ACT_JOB
         where ACT_JOB_ID = aACT_JOB_ID;

      Job JobCursor%rowtype;

      procedure CreateJournal(aFinancial boolean)
      is
        type JournalCursorTyp is ref cursor;

        cursor FinancialJournalCursor
        is
          select JOU.*
               , ETA.C_SUB_SET
               , ETA.C_ETAT_JOURNAL
            from ACT_ETAT_JOURNAL ETA
               , ACT_JOURNAL JOU;

        JournalCursor JournalCursorTyp;
        Journal       FinancialJournalCursor%rowtype;
        JournalId     ACT_JOURNAL.ACT_JOURNAL_ID%type;
        JouNumber     ACT_JOURNAL.JOU_NUMBER%type;
        AccountingId  ACS_ACCOUNTING.ACS_ACCOUNTING_ID%type;
      begin
        if aFinancial then
          -- Journal financier
          open JournalCursor for
            select JOU.*
                 , ETA.C_SUB_SET
                 , ETA.C_ETAT_JOURNAL
              from ACT_ETAT_JOURNAL ETA
                 , ACT_JOURNAL JOU
             where ACT_JOB_ID = aACT_JOB_ID
               and JOU.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
               and ETA.C_SUB_SET in('ACC', 'PAY', 'REC');

          -- recherche ACS_ACCOUNTING
          select max(ACS_ACCOUNTING_ID)
            into AccountingId
            from ACS_ACCOUNTING
           where C_TYPE_ACCOUNTING = 'FIN';
        else
          -- Journal analytique
          open JournalCursor for
            select JOU.*
                 , ETA.C_SUB_SET
                 , ETA.C_ETAT_JOURNAL
              from ACT_ETAT_JOURNAL ETA
                 , ACT_JOURNAL JOU
             where ACT_JOB_ID = aACT_JOB_ID
               and JOU.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
               and ETA.C_SUB_SET = 'CPN';

          -- recherche ACS_ACCOUNTING
          select max(ACS_ACCOUNTING_ID)
            into AccountingId
            from ACS_ACCOUNTING
           where C_TYPE_ACCOUNTING = 'MAN';
        end if;

        fetch JournalCursor
         into Journal;

        if JournalCursor%found then
          -- recherche du prochain numéro de journal
          select nvl(max(JOU_NUMBER), 0) + 1
            into JouNumber
            from ACT_JOURNAL
           where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
             and ACS_ACCOUNTING_ID = AccountingId;

          -- Création Journal
          select init_id_seq.nextval
            into JournalId
            from dual;

          insert into ACT_JOURNAL
                      (ACT_JOURNAL_ID
                     , PC_USER_ID
                     , JOU_DESCRIPTION
                     , ACS_ACCOUNTING_ID
                     , C_TYPE_JOURNAL
                     , ACT_JOB_ID
                     , JOU_NUMBER
                     , ACS_FINANCIAL_YEAR_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (JournalId
                     , UserId
                     , aJOB_DESCRIPTION   -- Journal.JOU_DESCRIPTION,
                     , Journal.ACS_ACCOUNTING_ID
                     , Journal.C_TYPE_JOURNAL
                     , JobId
                     , JouNumber
                     , aACS_FINANCIAL_YEAR_ID
                     , sysdate
                     , UserIni
                      );

          while JournalCursor%found loop
            -- Création Etats Journal
            insert into ACT_ETAT_JOURNAL
                        (ACT_ETAT_JOURNAL_ID
                       , ACT_JOURNAL_ID
                       , C_ETAT_JOURNAL
                       , C_SUB_SET
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , JournalId
                       , 'PROV'   -- Journal.C_ETAT_JOURNAL,
                       , Journal.C_SUB_SET
                       , sysdate
                       , UserIni
                        );

            fetch JournalCursor
             into Journal;
          end loop;
        end if;

        close JournalCursor;
      end CreateJournal;
    -----
    begin
      open JobCursor;

      fetch JobCursor
       into Job;

      if JobCursor%found then
        -- Création Travail
        select init_id_seq.nextval
          into JobId
          from dual;

        insert into ACT_JOB
                    (ACT_JOB_ID
                   , PC_USER_ID
                   , C_JOB_STATE
                   , JOB_DESCRIPTION
                   , ACJ_JOB_TYPE_ID
                   , PC_PC_USER_ID
                   , ACS_FINANCIAL_YEAR_ID
                   , JOB_ACI_CONTROL_DATE
                   , ACS_PERIOD_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (JobId
                   , UserId
                   , 'PEND'   -- Job.C_JOB_STATE,
                   , aJOB_DESCRIPTION
                   , Job.ACJ_JOB_TYPE_ID
                   , null   -- PC_PC_USER_ID
                   , aACS_FINANCIAL_YEAR_ID
                   , Job.JOB_ACI_CONTROL_DATE
                   , PeriodId
                   , sysdate
                   , UserIni
                    );

        CreateJournal(true);
        CreateJournal(false);

        -- création des événements
        insert into ACT_ETAT_EVENT
                    (ACT_ETAT_EVENT_ID
                   , ACT_JOB_ID
                   , C_TYPE_EVENT
                   , C_STATUS_EVENT
                   , ETA_SEQUENCE
                   , ETA_INSTRUCTION
                   , A_DATECRE
                   , A_IDCRE
                    )
          select init_id_seq.nextval
               , JobId
               , C_TYPE_EVENT
               , C_STATUS_EVENT
               , ETA_SEQUENCE
               , ETA_INSTRUCTION
               , sysdate
               , UserIni
            from ACT_ETAT_EVENT
           where ACT_JOB_ID = aACT_JOB_ID;
      end if;

      close JobCursor;
    end CreateJob;
  -----
  begin
    JobId  := null;

    open DocumentToCopyCursor(aCopy);

    fetch DocumentToCopyCursor
     into DocumentToCopy;

    if DocumentToCopyCursor%found then
      UserId   := PCS.PC_I_LIB_SESSION.GetUserId2;
      UserIni  := PCS.PC_I_LIB_SESSION.GetUserIni2;

      if aACS_PERIOD_ID > 0 then
        PeriodId  := aACS_PERIOD_ID;
      else
        PeriodId  := null;
      end if;

      CreateJob;

      if JobId is not null then
        /*Initialisation des varaibles globales Délai et Code délai*/
        pkgDateInterval  := pInterval;
        pkgDelayCode     := pDelayCode;

        while DocumentToCopyCursor%found loop
          /*Date de document initialisé par défaut avec le paramètre renseigné*/
          vTargetDocDate  := aDOC_DOCUMENT_DATE;

          /*Date document non renseigné....*/
          if (vTargetDocDate is null) then
            /*Appliquer le calcul délai avec la date document courant*/
            vTargetDocDate  := AddDateDelay(DocumentToCopy.DOC_DOCUMENT_DATE, pkgDateInterval, pkgDelayCode);
            /*Contrôle de la date dans l'exercice et / ou dans la période */
--            vTargetDocDate := ValidateDate(vTargetDocDate,aACS_FINANCIAL_YEAR_ID,PeriodId);
          end if;

          CopyDocument(DocumentToCopy.ACT_DOCUMENT_ID
                     , JobId
                     , aACS_FINANCIAL_YEAR_ID
                     , PeriodId
                     , null
                     , vTargetDocDate
                     , aIMF_TRANSACTION_DATE
                     , aIMF_VALUE_DATE
                     , aCopy
                     , pCopyBVRRef
                     , aExchangeRateCode
                     , DocumentId
                      );

          fetch DocumentToCopyCursor
           into DocumentToCopy;
        end loop;

        --Mise à jour du nombre de documents pour le travail
        update ACT_JOB
           set JOB_DOCUMENTS = (select count(*)
                                  from ACT_DOCUMENT
                                 where ACT_JOB_ID = JobId)
         where ACT_JOB_ID = JobId;
      end if;
    end if;

    close DocumentToCopyCursor;
  end CopyJob;

--------------------------
  procedure UpdateMgmAmounts(
    aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aIMF_AMOUNT_LC_D             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aIMF_AMOUNT_LC_C             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_AMOUNT_FC_D             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aIMF_AMOUNT_FC_C             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aIMF_AMOUNT_EUR_D            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aIMF_AMOUNT_EUR_C            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  )
  is
    -- Imputations analytiques d'une imputation financières, triées par montants
    cursor MgmImputationsCursor(
      aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
    , aTotalAmountLC               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
    , aTotalAmountFC               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
    )
    is
      select   MGI.ACT_MGM_IMPUTATION_ID
             , MGI.ACS_FINANCIAL_CURRENCY_ID
             , MGI.ACS_ACS_FINANCIAL_CURRENCY_ID
             , MGI.IMM_AMOUNT_LC_D
             , MGI.IMM_AMOUNT_LC_C
             , MGI.IMM_AMOUNT_FC_D
             , MGI.IMM_AMOUNT_FC_C
             , MGI.IMM_AMOUNT_EUR_D
             , MGI.IMM_AMOUNT_EUR_C
             , MGI.IMM_TRANSACTION_DATE
             , round( (IMM_AMOUNT_LC_D - IMM_AMOUNT_LC_C) / aTotalAmountLC, 6) PROP_LC
             , round( (IMM_AMOUNT_FC_D - IMM_AMOUNT_FC_C) / aTotalAmountFC, 6) PROP_FC
--             MGI.IMM_QUANTITY_D,
--             MGI.IMM_QUANTITY_C,
      from     ACT_MGM_IMPUTATION MGI
         where MGI.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID
      order by abs(MGI.IMM_AMOUNT_LC_D + MGI.IMM_AMOUNT_LC_C);

    MgmImputations  MgmImputationsCursor%rowtype;
    OldAmountLC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    OldAmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    OldAmountEUR    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    AmountLC_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountLC_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    AmountFC_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountFC_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    AmountEUR_D     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    AmountEUR_C     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    ExchangeRate    ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePrice       ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    TotAmountLC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type       default 0;
    TotAmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type       default 0;
    TotAmountEUR    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type      default 0;
    LastId          ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type       default 0;
    TransactionDate ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type;
    CurrId          ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    FCurrId         ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;

    ---------
    procedure UpdateMgmDistributionAmounts(
      aACT_MGM_IMPUTATION_ID      ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type
    , aIMM_TRANSACTION_DATE       ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type
    , aACS_FINANCIAL_CURRENCY_ID  ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
    , a_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
    , aIMF_AMOUNT_LC_D            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
    , aIMF_AMOUNT_LC_C            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
    , aIMF_AMOUNT_FC_D            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
    , aIMF_AMOUNT_FC_C            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
    , aIMF_AMOUNT_EUR_D           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
    , aIMF_AMOUNT_EUR_C           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
    )
    is
      -- Distributions analytiques d'une imputation analytique, triées par montants
      cursor MgmDistributionCursor(
        aACT_MGM_IMPUTATION_ID ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type
      , aTotalAmountLC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
      , aTotalAmountFC         ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
      )
      is
        select   MGD.ACT_MGM_DISTRIBUTION_ID
               , MGD.MGM_AMOUNT_LC_D
               , MGD.MGM_AMOUNT_LC_C
               , MGD.MGM_AMOUNT_FC_D
               , MGD.MGM_AMOUNT_FC_C
               , MGD.MGM_AMOUNT_EUR_D
               , MGD.MGM_AMOUNT_EUR_C
               , abs(round( (MGM_AMOUNT_LC_D - MGM_AMOUNT_LC_C) / aTotalAmountLC, 6) ) PROP_LC
               , abs(round( (MGM_AMOUNT_FC_D - MGM_AMOUNT_FC_C) / aTotalAmountFC, 6) ) PROP_FC
--               MGD.MGM_QUANTITY_D,
--               MGD.MGM_QUANTITY_C
        from     ACT_MGM_DISTRIBUTION MGD
           where MGD.ACT_MGM_IMPUTATION_ID = aACT_MGM_IMPUTATION_ID
        order by abs(MGD.MGM_AMOUNT_LC_D + MGD.MGM_AMOUNT_LC_C);

      MgmDistribution MgmDistributionCursor%rowtype;
      OldAmountLC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
      OldAmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
      OldAmountEUR    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
      AmountLC_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
      AmountLC_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
      AmountFC_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
      AmountFC_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
      AmountEUR_D     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
      AmountEUR_C     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
      ExchangeRate    ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
      BasePrice       ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
      TotAmountLC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type       default 0;
      TotAmountFC     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type       default 0;
      TotAmountEUR    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type      default 0;
      LastId          ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type   default 0;
    -----
    begin
      select nvl(sum(DIS.MGM_AMOUNT_LC_D - DIS.MGM_AMOUNT_LC_C), 0)
           , nvl(sum(DIS.MGM_AMOUNT_FC_D - DIS.MGM_AMOUNT_FC_C), 0)
           , nvl(sum(DIS.MGM_AMOUNT_EUR_D - DIS.MGM_AMOUNT_EUR_C), 0)
        into OldAmountLC
           , OldAmountFC
           , OldAmountEUR
        from ACT_MGM_DISTRIBUTION DIS
       where DIS.ACT_MGM_IMPUTATION_ID = aACT_MGM_IMPUTATION_ID;

      if OldAmountLC <> 0 then
        -- Permet d'éviter la division par 0 au fetch du curseur MgmDistributionCursor !
        if OldAmountFC = 0 then
          OldAmountFC  := 1;
        end if;

        open MgmDistributionCursor(aACT_MGM_IMPUTATION_ID, OldAmountLC, OldAmountFC);

        fetch MgmDistributionCursor
         into MgmDistribution;

        while MgmDistributionCursor%found loop
          if aACS_FINANCIAL_CURRENCY_ID <> a_ACS_FINANCIAL_CURRENCY_ID then
            ACT_DOC_TRANSACTION.ProportionalAmounts(aIMF_AMOUNT_LC_D
                                                  , aIMF_AMOUNT_LC_C
                                                  , aIMF_AMOUNT_FC_D
                                                  , aIMF_AMOUNT_FC_C
                                                  , aACS_FINANCIAL_CURRENCY_ID
                                                  , a_ACS_FINANCIAL_CURRENCY_ID
                                                  , aIMM_TRANSACTION_DATE
                                                  , MgmDistribution.PROP_FC
                                                  , AmountLC_D
                                                  , AmountLC_C
                                                  , AmountFC_D
                                                  , AmountFC_C
                                                  , AmountEUR_D
                                                  , AmountEUR_C
                                                  , ExchangeRate
                                                  , BasePrice
                                                   );
          else
            ACT_DOC_TRANSACTION.ProportionalAmounts(aIMF_AMOUNT_LC_D
                                                  , aIMF_AMOUNT_LC_C
                                                  , aIMF_AMOUNT_FC_D
                                                  , aIMF_AMOUNT_FC_C
                                                  , aACS_FINANCIAL_CURRENCY_ID
                                                  , a_ACS_FINANCIAL_CURRENCY_ID
                                                  , aIMM_TRANSACTION_DATE
                                                  , MgmDistribution.PROP_LC
                                                  , AmountLC_D
                                                  , AmountLC_C
                                                  , AmountFC_D
                                                  , AmountFC_C
                                                  , AmountEUR_D
                                                  , AmountEUR_C
                                                  , ExchangeRate
                                                  , BasePrice
                                                   );
          end if;

          TotAmountLC   := TotAmountLC + AmountLC_D - AmountLC_C;
          TotAmountFC   := TotAmountFC + AmountFC_D - AmountFC_C;
          TotAmountEUR  := TotAmountEUR + AmountEUR_D - AmountEUR_C;

          -- Mise à jour distributions analytiques
          update ACT_MGM_DISTRIBUTION
             set MGM_AMOUNT_LC_D = AmountLC_D
               , MGM_AMOUNT_LC_C = AmountLC_C
               , MGM_AMOUNT_FC_D = AmountFC_D
               , MGM_AMOUNT_FC_C = AmountFC_C
               , MGM_AMOUNT_EUR_D = AmountEUR_D
               , MGM_AMOUNT_EUR_C = AmountEUR_C
           where ACT_MGM_DISTRIBUTION_ID = MgmDistribution.ACT_MGM_DISTRIBUTION_ID;

          LastId        := MgmDistribution.ACT_MGM_DISTRIBUTION_ID;

          fetch MgmDistributionCursor
           into MgmDistribution;
        end loop;

        close MgmDistributionCursor;

        -- Ajout de l'éventuelle différence sur l'imputation de plus grand montant
        if     (    (TotAmountLC <> aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C)
                or (TotAmountFC <> aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C)
                or (TotAmountEUR <> aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C)
               )
           and LastId > 0 then
          update ACT_MGM_DISTRIBUTION
             set MGM_AMOUNT_LC_D =
                   MGM_AMOUNT_LC_D -
                   decode(sign(MGM_AMOUNT_LC_D - MGM_AMOUNT_LC_C)
                        , 1, TotAmountLC -(aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C)
                        , 0
                         )
               , MGM_AMOUNT_LC_C =
                   MGM_AMOUNT_LC_C +
                   decode(sign(MGM_AMOUNT_LC_D - MGM_AMOUNT_LC_C)
                        , -1, TotAmountLC -(aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C)
                        , 0
                         )
               , MGM_AMOUNT_FC_D =
                   MGM_AMOUNT_FC_D -
                   decode(sign(MGM_AMOUNT_FC_D - MGM_AMOUNT_FC_C)
                        , 1, TotAmountFC -(aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C)
                        , 0
                         )
               , MGM_AMOUNT_FC_C =
                   MGM_AMOUNT_FC_C +
                   decode(sign(MGM_AMOUNT_FC_D - MGM_AMOUNT_FC_C)
                        , -1, TotAmountFC -(aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C)
                        , 0
                         )
               , MGM_AMOUNT_EUR_D =
                   MGM_AMOUNT_EUR_D -
                   decode(sign(MGM_AMOUNT_EUR_D - MGM_AMOUNT_EUR_C)
                        , 1, TotAmountEUR -(aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C)
                        , 0
                         )
               , MGM_AMOUNT_EUR_C =
                   MGM_AMOUNT_EUR_C +
                   decode(sign(MGM_AMOUNT_EUR_D - MGM_AMOUNT_EUR_C)
                        , -1, TotAmountEUR -(aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C)
                        , 0
                         )
           where ACT_MGM_DISTRIBUTION_ID = LastId;
        end if;
      end if;
    end UpdateMgmDistributionAmounts;   -- UpdateMgmDistributionAmounts
  -----
  -----
  begin
    select nvl(sum(MGI.IMM_AMOUNT_LC_D - MGI.IMM_AMOUNT_LC_C), 0)
         , nvl(sum(MGI.IMM_AMOUNT_FC_D - MGI.IMM_AMOUNT_FC_C), 0)
         , nvl(sum(MGI.IMM_AMOUNT_EUR_D - MGI.IMM_AMOUNT_EUR_C), 0)
      into OldAmountLC
         , OldAmountFC
         , OldAmountEUR
      from ACT_MGM_IMPUTATION MGI
     where MGI.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

    if OldAmountLC <> 0 then
      -- Permet d'éviter la division par 0 au fetch du curseur MgmImputationsCursor !
      if OldAmountFC = 0 then
        OldAmountFC  := 1;
      end if;

      open MgmImputationsCursor(aACT_FINANCIAL_IMPUTATION_ID, OldAmountLC, OldAmountFC);

      fetch MgmImputationsCursor
       into MgmImputations;

      while MgmImputationsCursor%found loop
        if MgmImputations.ACS_FINANCIAL_CURRENCY_ID <> MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID then
          ACT_DOC_TRANSACTION.ProportionalAmounts(aIMF_AMOUNT_LC_D
                                                , aIMF_AMOUNT_LC_C
                                                , aIMF_AMOUNT_FC_D
                                                , aIMF_AMOUNT_FC_C
                                                , MgmImputations.ACS_FINANCIAL_CURRENCY_ID
                                                , MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                , MgmImputations.IMM_TRANSACTION_DATE
                                                , MgmImputations.PROP_FC
                                                , AmountLC_D
                                                , AmountLC_C
                                                , AmountFC_D
                                                , AmountFC_C
                                                , AmountEUR_D
                                                , AmountEUR_C
                                                , ExchangeRate
                                                , BasePrice
                                                 );
        else
          ACT_DOC_TRANSACTION.ProportionalAmounts(aIMF_AMOUNT_LC_D
                                                , aIMF_AMOUNT_LC_C
                                                , aIMF_AMOUNT_FC_D
                                                , aIMF_AMOUNT_FC_C
                                                , MgmImputations.ACS_FINANCIAL_CURRENCY_ID
                                                , MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                , MgmImputations.IMM_TRANSACTION_DATE
                                                , MgmImputations.PROP_LC
                                                , AmountLC_D
                                                , AmountLC_C
                                                , AmountFC_D
                                                , AmountFC_C
                                                , AmountEUR_D
                                                , AmountEUR_C
                                                , ExchangeRate
                                                , BasePrice
                                                 );
        end if;

        TotAmountLC      := TotAmountLC + AmountLC_D - AmountLC_C;
        TotAmountFC      := TotAmountFC + AmountFC_D - AmountFC_C;
        TotAmountEUR     := TotAmountEUR + AmountEUR_D - AmountEUR_C;

        -- Mise à jour imputations analytiques
        update ACT_MGM_IMPUTATION
           set IMM_AMOUNT_LC_D = AmountLC_D
             , IMM_AMOUNT_LC_C = AmountLC_C
             , IMM_AMOUNT_FC_D = AmountFC_D
             , IMM_AMOUNT_FC_C = AmountFC_C
             , IMM_AMOUNT_EUR_D = AmountEUR_D
             , IMM_AMOUNT_EUR_C = AmountEUR_C
             , IMM_EXCHANGE_RATE = ExchangeRate
             , IMM_BASE_PRICE = BasePrice
         where ACT_MGM_IMPUTATION_ID = MgmImputations.ACT_MGM_IMPUTATION_ID;

        LastId           := MgmImputations.ACT_MGM_IMPUTATION_ID;
        TransactionDate  := MgmImputations.IMM_TRANSACTION_DATE;
        FCurrId          := MgmImputations.ACS_FINANCIAL_CURRENCY_ID;
        CurrId           := MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID;
        -- Mise à jour distributions analytiques sur la base du montant de l'imputation analytique correspondante
        UpdateMgmDistributionAmounts(MgmImputations.ACT_MGM_IMPUTATION_ID
                                   , MgmImputations.IMM_TRANSACTION_DATE
                                   , MgmImputations.ACS_FINANCIAL_CURRENCY_ID
                                   , MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                   , AmountLC_D
                                   , AmountLC_C
                                   , AmountFC_D
                                   , AmountFC_C
                                   , AmountEUR_D
                                   , AmountEUR_C
                                    );

        fetch MgmImputationsCursor
         into MgmImputations;
      end loop;

      close MgmImputationsCursor;

      -- Ajout de l'éventuelle différence sur l'imputation de plus grand montant
      if     (    (TotAmountLC <> aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C)
              or (TotAmountFC <> aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C)
              or (TotAmountEUR <> aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C)
             )
         and LastId > 0 then
        update ACT_MGM_IMPUTATION
           set IMM_AMOUNT_LC_D =
                 IMM_AMOUNT_LC_D -
                 decode(sign(IMM_AMOUNT_LC_D - IMM_AMOUNT_LC_C)
                      , 1, TotAmountLC -(aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C)
                      , 0
                       )
             , IMM_AMOUNT_LC_C =
                 IMM_AMOUNT_LC_C +
                 decode(sign(IMM_AMOUNT_LC_D - IMM_AMOUNT_LC_C)
                      , -1, TotAmountLC -(aIMF_AMOUNT_LC_D - aIMF_AMOUNT_LC_C)
                      , 0
                       )
             , IMM_AMOUNT_FC_D =
                 IMM_AMOUNT_FC_D -
                 decode(sign(IMM_AMOUNT_FC_D - IMM_AMOUNT_FC_C)
                      , 1, TotAmountFC -(aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C)
                      , 0
                       )
             , IMM_AMOUNT_FC_C =
                 IMM_AMOUNT_FC_C +
                 decode(sign(IMM_AMOUNT_FC_D - IMM_AMOUNT_FC_C)
                      , -1, TotAmountFC -(aIMF_AMOUNT_FC_D - aIMF_AMOUNT_FC_C)
                      , 0
                       )
             , IMM_AMOUNT_EUR_D =
                 IMM_AMOUNT_EUR_D -
                 decode(sign(IMM_AMOUNT_EUR_D - IMM_AMOUNT_EUR_C)
                      , 1, TotAmountEUR -(aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C)
                      , 0
                       )
             , IMM_AMOUNT_EUR_C =
                 IMM_AMOUNT_EUR_C +
                 decode(sign(IMM_AMOUNT_EUR_D - IMM_AMOUNT_EUR_C)
                      , -1, TotAmountEUR -(aIMF_AMOUNT_EUR_D - aIMF_AMOUNT_EUR_C)
                      , 0
                       )
         where ACT_MGM_IMPUTATION_ID = LastId;

        -- Montant à imputer sur les distributions liées
        select IMM_AMOUNT_LC_D
             , IMM_AMOUNT_LC_C
             , IMM_AMOUNT_FC_D
             , IMM_AMOUNT_FC_C
             , IMM_AMOUNT_EUR_D
             , IMM_AMOUNT_EUR_C
          into AmountLC_D
             , AmountLC_C
             , AmountFC_D
             , AmountFC_C
             , AmountEUR_D
             , AmountEUR_C
          from ACT_MGM_IMPUTATION
         where ACT_MGM_IMPUTATION_ID = LastId;

        -- Mise à jour distributions analytiques sur la base du montant de l'imputation analytique correspondante
        UpdateMgmDistributionAmounts(LastId
                                   , TransactionDate
                                   , FCurrId
                                   , CurrId
                                   , AmountLC_D
                                   , AmountLC_C
                                   , AmountFC_D
                                   , AmountFC_C
                                   , AmountEUR_D
                                   , AmountEUR_C
                                    );
      end if;
    end if;
  end UpdateMgmAmounts;

--------------------------
  procedure UpdateDocAmounts(
    aACT_DOCUMENT_ID     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDOC_TOTAL_AMOUNT_DC ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type
  )
  is
    OldFCCurrencyId  ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    OldLCCurrencyId  ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    OldAmountLC      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    OldAmountFC      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    OldAmountEUR     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    OldAmount        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    LocalCurrencyId  ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    AmountLC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountLC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    AmountFC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountFC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    AmountEUR_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    AmountEUR_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    ExchangeRate     ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePrice        ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    PrimaryAmountLC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    PrimaryAmountFC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    PrimaryAmountEUR ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    Proportion       number(15, 6);

    ---------
    ---------
    procedure UpdateImputationsAmounts
    is
      -- Imputations financières (avec distribution) d'un document donné
      cursor FinImputationsCursor
      is
        select IMP.ACT_FINANCIAL_IMPUTATION_ID
             , IMP.IMF_PRIMARY
             , IMP.IMF_AMOUNT_LC_D
             , IMP.IMF_AMOUNT_LC_C
             , IMP.IMF_AMOUNT_FC_D
             , IMP.IMF_AMOUNT_FC_C
             , IMP.ACS_FINANCIAL_CURRENCY_ID
             , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
             , IMP.IMF_TRANSACTION_DATE
             , DIS.ACT_FINANCIAL_DISTRIBUTION_ID
             , DIS.FIN_AMOUNT_LC_D
             , DIS.FIN_AMOUNT_LC_C
             , DIS.FIN_AMOUNT_FC_D
             , DIS.FIN_AMOUNT_FC_C
             , TAX.ACT_DET_TAX_ID
             , TAX.TAX_VAT_AMOUNT_LC
             , TAX.TAX_VAT_AMOUNT_FC
             , TAX.TAX_VAT_AMOUNT_EUR
             , TAX.TAX_LIABLED_AMOUNT
          from ACT_DET_TAX TAX
             , ACT_FINANCIAL_DISTRIBUTION DIS
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
           and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT_FINANCIAL_IMPUTATION_ID(+);

/*    -- Imputations analytiques (avec distribution) d'un document donné
      cursor MgmImputationsCursor is
        select MGI.ACT_MGM_IMPUTATION_ID,
               MGI.IMM_PRIMARY,
               MGI.ACS_FINANCIAL_CURRENCY_ID,
               MGI.ACS_ACS_FINANCIAL_CURRENCY_ID,
               MGI.IMM_AMOUNT_LC_D,
               MGI.IMM_AMOUNT_LC_C,
               MGI.IMM_AMOUNT_FC_D,
               MGI.IMM_AMOUNT_FC_C,
               MGI.IMM_AMOUNT_EUR_D,
               MGI.IMM_AMOUNT_EUR_C,
               MGI.IMM_TRANSACTION_DATE,
--             MGI.IMM_QUANTITY_D,
--             MGI.IMM_QUANTITY_C,
               MGD.ACT_MGM_DISTRIBUTION_ID,
               MGD.MGM_AMOUNT_LC_D,
               MGD.MGM_AMOUNT_FC_D,
               MGD.MGM_AMOUNT_EUR_D,
               MGD.MGM_AMOUNT_LC_C,
               MGD.MGM_AMOUNT_FC_C,
               MGD.MGM_AMOUNT_EUR_C,
               MGD.MGM_QUANTITY_D,
               MGD.MGM_QUANTITY_C
          from
               ACT_MGM_DISTRIBUTION     MGD,
               ACT_MGM_IMPUTATION       MGI
          where MGI.ACT_DOCUMENT_ID             = aACT_DOCUMENT_ID
            and MGI.ACT_MGM_IMPUTATION_ID       = MGD.ACT_MGM_IMPUTATION_ID (+)
          order by MGI.ACT_FINANCIAL_IMPUTATION_ID;

      MgmImputations   MgmImputationsCursor%rowtype;
*/
      FinImputations   FinImputationsCursor%rowtype;
      MgmImputationId  ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
      TotAmountLC      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
      TotAmountFC      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
      TotAmountEUR     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type              default 0;
      HighestAmount    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
      HighestAmountId  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type   default 0;
      HighestAmountId2 ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type   default 0;
      SignHighest      number(1);
    -----
    begin
      open FinImputationsCursor;

      fetch FinImputationsCursor
       into FinImputations;

      while FinImputationsCursor%found loop
        AmountLC_D   := 0;
        AmountLC_C   := 0;
        AmountFC_D   := 0;
        AmountFC_C   := 0;
        AmountEUR_D  := 0;
        AmountEUR_C  := 0;

        -- Imputation primaire - Le montant total est imputé, après conversion si monnaie étrangère
        if FinImputations.IMF_PRIMARY = 1 then
          if FinImputations.ACS_FINANCIAL_CURRENCY_ID <> FinImputations.ACS_ACS_FINANCIAL_CURRENCY_ID then
            if sign(FinImputations.IMF_AMOUNT_FC_D) = 0 then
              AmountFC_C  := aDOC_TOTAL_AMOUNT_DC;
              ACT_DOC_TRANSACTION.ConvertAmounts(AmountFC_C
                                               , FinImputations.ACS_FINANCIAL_CURRENCY_ID
                                               , FinImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                               , FinImputations.IMF_TRANSACTION_DATE
                                               , 1   -- aRound
                                               , 1   -- aRateType
                                               , ExchangeRate
                                               , BasePrice
                                               , AmountEUR_C
                                               , AmountLC_C
                                                );
            else
              AmountFC_D  := aDOC_TOTAL_AMOUNT_DC;
              ACT_DOC_TRANSACTION.ConvertAmounts(AmountFC_D
                                               , FinImputations.ACS_FINANCIAL_CURRENCY_ID
                                               , FinImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                               , FinImputations.IMF_TRANSACTION_DATE
                                               , 1   -- aRound
                                               , 1   -- aRateType
                                               , ExchangeRate
                                               , BasePrice
                                               , AmountEUR_D
                                               , AmountLC_D
                                                );
            end if;
          else
            if sign(FinImputations.IMF_AMOUNT_LC_D) = 0 then
              AmountLC_C  := aDOC_TOTAL_AMOUNT_DC;
            else
              AmountLC_D  := aDOC_TOTAL_AMOUNT_DC;
            end if;
          end if;

          PrimaryAmountLC   := (AmountLC_D - AmountLC_C) * -1;
          PrimaryAmountFC   := (AmountFC_D - AmountFC_C) * -1;
          PrimaryAmountEUR  := (AmountEUR_D - AmountEUR_C) * -1;
        else   -- Calcul proportionnel des montants
          ACT_DOC_TRANSACTION.ProportionalAmounts(FinImputations.IMF_AMOUNT_LC_D
                                                , FinImputations.IMF_AMOUNT_LC_C
                                                , FinImputations.IMF_AMOUNT_FC_D
                                                , FinImputations.IMF_AMOUNT_FC_C
                                                , FinImputations.ACS_FINANCIAL_CURRENCY_ID
                                                , FinImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                , FinImputations.IMF_TRANSACTION_DATE
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
          TotAmountLC   := TotAmountLC + AmountLC_D - AmountLC_C;
          TotAmountFC   := TotAmountFC + AmountFC_D - AmountFC_C;
          TotAmountEUR  := TotAmountEUR + AmountEUR_D - AmountEUR_C;

          if abs(AmountLC_D - AmountLC_C) > HighestAmount then
            HighestAmount     := abs(AmountLC_D - AmountLC_C);
            HighestAmountId   := FinImputations.ACT_FINANCIAL_IMPUTATION_ID;
            HighestAmountId2  := FinImputations.ACT_FINANCIAL_DISTRIBUTION_ID;
            SignHighest       := sign(AmountLC_D - AmountLC_C);
          end if;
        end if;

        -- Mise à jour imputations financières
        update ACT_FINANCIAL_IMPUTATION
           set IMF_AMOUNT_LC_D = AmountLC_D
             , IMF_AMOUNT_LC_C = AmountLC_C
             , IMF_AMOUNT_FC_D = AmountFC_D
             , IMF_AMOUNT_FC_C = AmountFC_C
             , IMF_AMOUNT_EUR_D = AmountEUR_D
             , IMF_AMOUNT_EUR_C = AmountEUR_C
             , IMF_EXCHANGE_RATE = ExchangeRate
             , IMF_BASE_PRICE = BasePrice
         where ACT_FINANCIAL_IMPUTATION_ID = FinImputations.ACT_FINANCIAL_IMPUTATION_ID;

        -- Mise à jour distributions (division)
        if FinImputations.ACT_FINANCIAL_DISTRIBUTION_ID is not null then
          update ACT_FINANCIAL_DISTRIBUTION
             set FIN_AMOUNT_LC_D = AmountLC_D
               , FIN_AMOUNT_LC_C = AmountLC_C
               , FIN_AMOUNT_FC_D = AmountFC_D
               , FIN_AMOUNT_FC_C = AmountFC_C
               , FIN_AMOUNT_EUR_D = AmountEUR_D
               , FIN_AMOUNT_EUR_C = AmountEUR_C
           where ACT_FINANCIAL_DISTRIBUTION_ID = FinImputations.ACT_FINANCIAL_DISTRIBUTION_ID;
        end if;

        -- Mise à jour imputations analytiques sur la base du montant de l'imputation financière correspondante
        UpdateMgmAmounts(FinImputations.ACT_FINANCIAL_IMPUTATION_ID
                       , AmountLC_D
                       , AmountLC_C
                       , AmountFC_D
                       , AmountFC_C
                       , AmountEUR_D
                       , AmountEUR_C
                        );

        -- Mise à jour imputations taxes (TVA)
        if FinImputations.ACT_DET_TAX_ID is not null then
          ACT_DOC_TRANSACTION.ProportionalAmounts(FinImputations.TAX_VAT_AMOUNT_LC
                                                , 0
                                                , FinImputations.TAX_VAT_AMOUNT_FC
                                                , FinImputations.TAX_LIABLED_AMOUNT
                                                , FinImputations.ACS_FINANCIAL_CURRENCY_ID
                                                , FinImputations.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                , FinImputations.IMF_TRANSACTION_DATE
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

          update ACT_DET_TAX
             set TAX_VAT_AMOUNT_LC = AmountLC_D
               , TAX_VAT_AMOUNT_FC = AmountFC_D
               , TAX_VAT_AMOUNT_EUR = AmountEUR_D
               , TAX_LIABLED_AMOUNT = AmountFC_C
           where ACT_DET_TAX_ID = FinImputations.ACT_DET_TAX_ID;
        end if;

        fetch FinImputationsCursor
         into FinImputations;
      end loop;

      close FinImputationsCursor;

      -- Ajout de l'éventuelle différence sur l'imputation de plus grand montant
      if    TotAmountLC <> PrimaryAmountLC
         or TotAmountFC <> PrimaryAmountFC
         or TotAmountEUR <> PrimaryAmountEUR then
        -- Mise à jour imputations financières
        update ACT_FINANCIAL_IMPUTATION
           set IMF_AMOUNT_LC_D = IMF_AMOUNT_LC_D - decode(SignHighest, 1, TotAmountLC - PrimaryAmountLC, 0)
             , IMF_AMOUNT_LC_C = IMF_AMOUNT_LC_C + decode(SignHighest, -1, TotAmountLC - PrimaryAmountLC, 0)
             , IMF_AMOUNT_FC_D = IMF_AMOUNT_FC_D - decode(SignHighest, 1, TotAmountFC - PrimaryAmountFC, 0)
             , IMF_AMOUNT_FC_C = IMF_AMOUNT_FC_C + decode(SignHighest, -1, TotAmountFC - PrimaryAmountFC, 0)
             , IMF_AMOUNT_EUR_D = IMF_AMOUNT_EUR_D - decode(SignHighest, 1, TotAmountEUR - PrimaryAmountEUR, 0)
             , IMF_AMOUNT_EUR_C = IMF_AMOUNT_EUR_C + decode(SignHighest, -1, TotAmountEUR - PrimaryAmountEUR, 0)
         where ACT_FINANCIAL_IMPUTATION_ID = HighestAmountId;

        -- Mise à jour distributions (division)
        if HighestAmountId2 is not null then
          update ACT_FINANCIAL_DISTRIBUTION
             set FIN_AMOUNT_LC_D = FIN_AMOUNT_LC_D - decode(SignHighest, 1, TotAmountLC - PrimaryAmountLC, 0)
               , FIN_AMOUNT_LC_C = FIN_AMOUNT_LC_C + decode(SignHighest, -1, TotAmountLC - PrimaryAmountLC, 0)
               , FIN_AMOUNT_FC_D = FIN_AMOUNT_FC_D - decode(SignHighest, 1, TotAmountFC - PrimaryAmountFC, 0)
               , FIN_AMOUNT_FC_C = FIN_AMOUNT_FC_C + decode(SignHighest, -1, TotAmountFC - PrimaryAmountFC, 0)
               , FIN_AMOUNT_EUR_D = FIN_AMOUNT_EUR_D - decode(SignHighest, 1, TotAmountEUR - PrimaryAmountEUR, 0)
               , FIN_AMOUNT_EUR_C = FIN_AMOUNT_EUR_C + decode(SignHighest, -1, TotAmountEUR - PrimaryAmountEUR, 0)
           where ACT_FINANCIAL_DISTRIBUTION_ID = HighestAmountId2;
        end if;

        -- Montants à imputer sur les imputations analytiques liées à l'imputation financière
        select IMF_AMOUNT_LC_D
             , IMF_AMOUNT_LC_C
             , IMF_AMOUNT_FC_D
             , IMF_AMOUNT_FC_C
             , IMF_AMOUNT_EUR_D
             , IMF_AMOUNT_EUR_C
          into AmountLC_D
             , AmountLC_C
             , AmountFC_D
             , AmountFC_C
             , AmountEUR_D
             , AmountEUR_C
          from ACT_FINANCIAL_IMPUTATION
         where ACT_FINANCIAL_IMPUTATION_ID = HighestAmountId;

        -- Mise à jour imputations analytiques sur la base du montant de l'imputation financière correspondante
        UpdateMgmAmounts(HighestAmountId, AmountLC_D, AmountLC_C, AmountFC_D, AmountFC_C, AmountEUR_D, AmountEUR_C);
      end if;
/*    -- Mise à jour imputations analytiques sans lien avec une imputation financière
      open MgmImputationsCursor;

      fetch MgmImputationsCursor into MgmImputations;

      while MgmImputationsCursor%found loop

        if MgmImputationId is null or (MgmImputationId <> MgmImputations.ACT_MGM_IMPUTATION_ID) then

          MgmImputationId := MgmImputations.ACT_MGM_IMPUTATION_ID;

          ProportionalAmounts(MgmImputations.IMM_PRIMARY = 1,
                              MgmImputations.IMM_AMOUNT_LC_D,           MgmImputations.IMM_AMOUNT_LC_C,
                              MgmImputations.IMM_AMOUNT_FC_D,           MgmImputations.IMM_AMOUNT_FC_C,
                              MgmImputations.ACS_FINANCIAL_CURRENCY_ID, MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID,
                              MgmImputations.IMM_TRANSACTION_DATE,      Proportion,
                              AmountLC_D,                               AmountLC_C,
                              AmountFC_D,                               AmountFC_C,
                              AmountEUR_D,                              AmountEUR_C,
                              ExchangeRate,                             BasePrice);

          -- Mise à jour imputations analytiques
          update ACT_MGM_IMPUTATION
            set IMM_AMOUNT_LC_D   = AmountLC_D,
                IMM_AMOUNT_LC_C   = AmountLC_C,
                IMM_AMOUNT_FC_D   = AmountFC_D,
                IMM_AMOUNT_FC_C   = AmountFC_C,
                IMM_AMOUNT_EUR_D  = AmountEUR_D,
                IMM_AMOUNT_EUR_C  = AmountEUR_C,
                IMM_EXCHANGE_RATE = ExchangeRate,
                IMM_BASE_PRICE    = BasePrice
            where ACT_MGM_IMPUTATION_ID = MgmImputations.ACT_MGM_IMPUTATION_ID;

        end if;

        if MgmImputations.ACT_MGM_DISTRIBUTION_ID is not null then

          ProportionalAmounts(False,
                              MgmImputations.MGM_AMOUNT_LC_D,           MgmImputations.MGM_AMOUNT_LC_C,
                              MgmImputations.MGM_AMOUNT_FC_D,           MgmImputations.MGM_AMOUNT_FC_C,
                              MgmImputations.ACS_FINANCIAL_CURRENCY_ID, MgmImputations.ACS_ACS_FINANCIAL_CURRENCY_ID,
                              MgmImputations.IMM_TRANSACTION_DATE,      Proportion,
                              AmountLC_D,                               AmountLC_C,
                              AmountFC_D,                               AmountFC_C,
                              AmountEUR_D,                              AmountEUR_C,
                              ExchangeRate,                             BasePrice);

          -- Mise à jour distributions analytiques (projets)
          update ACT_MGM_DISTRIBUTION
            set MGM_AMOUNT_LC_D   = AmountLC_D,
                MGM_AMOUNT_LC_C   = AmountLC_C,
                MGM_AMOUNT_FC_D   = AmountFC_D,
                MGM_AMOUNT_FC_C   = AmountFC_C,
                MGM_AMOUNT_EUR_D  = AmountEUR_D,
                MGM_AMOUNT_EUR_C  = AmountEUR_C
            where ACT_MGM_DISTRIBUTION_ID = MgmImputations.ACT_MGM_DISTRIBUTION_ID;

        end if;

        fetch MgmImputationsCursor into MgmImputations;

      end loop;

      close MgmImputationsCursor;
*/
    end UpdateImputationsAmounts;

    --------
    function ExpiriesExist
      return boolean
    is
      id ACT_EXPIRY.ACT_EXPIRY_ID%type;
      Ok boolean                         default false;
    begin
      begin
        select min(ACT_EXPIRY_ID)
          into id
          from ACT_EXPIRY
         where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

        Ok  := id is not null;
      exception
        when others then
          Ok  := false;
      end;

      return Ok;
    end ExpiriesExist;
  -----
  -----
  begin
    LocalCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;

    begin
      select   IMP.ACS_FINANCIAL_CURRENCY_ID
             , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
             , abs(nvl(sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 0) )
             , abs(nvl(sum(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), 0) )
             , abs(nvl(sum(IMF_AMOUNT_EUR_D - IMF_AMOUNT_EUR_C), 0) )
          into OldFCCurrencyId
             , OldLCCurrencyId
             , OldAmountLC
             , OldAmountFC
             , OldAmountEUR
          from ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and IMP.IMF_PRIMARY + 0 = 0
      group by IMP.ACS_FINANCIAL_CURRENCY_ID
             , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID;

      if OldLCCurrencyId <> OldFCCurrencyId then
        OldAmount  := OldAmountFC;
      else
        OldAmount  := OldAmountLC;
      end if;
    exception
      when others then
        OldAmount  := null;
    end;

    if     OldAmount is not null
       and OldAmount <> aDOC_TOTAL_AMOUNT_DC then
      begin
        Proportion  := aDOC_TOTAL_AMOUNT_DC / OldAmount;
      exception
        when zero_divide then
          Proportion  := 0;
      end;

      -- Retrait des cumuls du document
      ACT_DOC_TRANSACTION.DocImputations(aACT_DOCUMENT_ID, 0);
      -- Mise à jour montants imputations financières analytiques et taxes (TVA)
      UpdateImputationsAmounts;

      -- Mise à jour montant global document
      update ACT_DOCUMENT
         set DOC_TOTAL_AMOUNT_DC = aDOC_TOTAL_AMOUNT_DC
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      if ExpiriesExist then
        -- Elimination échéances existantes avant de les regénérer sur la base des nouveaux montants
        delete from ACT_EXPIRY
              where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

        ExpiriesGeneration(aACT_DOCUMENT_ID);
      end if;

      -- Recalcul des cumuls du document
      ACT_DOC_TRANSACTION.DocImputations(aACT_DOCUMENT_ID, 0);
    end if;
  end UpdateDocAmounts;

-- Génération des échéances - Sur la base de l'imputation financière primaire existante
----------------------------
  procedure ExpiriesGeneration(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
  is
    PartImputationId ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
  begin
    select min(ACT_PART_IMPUTATION_ID)
      into PartImputationId
      from ACT_PART_IMPUTATION
     where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    ACT_EXPIRY_MANAGEMENT.GenerateExpiriesACT(PartImputationId);
  end ExpiriesGeneration;

-- Calcul de la date d'échéance
----------------------
  function CalcExpiryDay(
    aDate          ACT_EXPIRY.EXP_CALCULATED%type
  , aC_CALC_METHOD PAC_CONDITION_DETAIL.C_CALC_METHOD%type
  , aCDE_DAY       PAC_CONDITION_DETAIL.CDE_DAY%type
  , aCDE_END_MONTH PAC_CONDITION_DETAIL.CDE_END_MONTH%type
  )
    return ACT_EXPIRY.EXP_CALCULATED%type
  is
    result ACT_EXPIRY.EXP_CALCULATED%type;
  begin
    -- Calcul de la date d'échéance
    if aC_CALC_METHOD = 'NORM' then   -- normale
      result  := aDate + aCDE_DAY;
    elsif aC_CALC_METHOD = 'MONTH' then   -- fin de mois
      result  := last_day(aDate + aCDE_DAY);
    elsif aC_CALC_METHOD = 'DAY' then   -- fin de mois le XX
      -- Correction si on arrive en fin mois
      if aCDE_END_MONTH > to_number(to_char(aDate + aCDE_DAY, 'DD') ) then
        result  := last_day(aDate + aCDE_DAY);
      else
        result  := last_day(add_months(aDate + aCDE_DAY, -1) ) + aCDE_END_MONTH;
      end if;
    else
      result  := aDate;
    end if;

    return result;
  end CalcExpiryDay;

------------------------
  procedure ConvertAmounts(
    aAmount        in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aFromFinCurrId in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aToFinCurrId   in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aDate          in     date
  , aRound         in     number default 1
  , aRateType      in     number default 1
  , aExchangeRate  in out ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aBasePrice     in out ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmountEUR     in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmountConvert in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  )
  is
    RateExchangeEUR ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePriceEUR    ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    FinCurrId       ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    Flag            number(1);
    BaseChange      number(1)                                                 default 0;
    EuroChange      number(1)                                                 default 0;
    LocalCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  -----
  begin
    aExchangeRate   := 0;
    aBasePrice      := 0;
    aAmountEUR      := 0;
    aAmountConvert  := 0;

    if aFromFinCurrId <> aToFinCurrId then
      LocalCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;

      if aFromFinCurrId = LocalCurrencyId then
        FinCurrId  := aToFinCurrId;
      else
        FinCurrId  := aFromFinCurrId;
      end if;

      Flag             :=
        ACS_FUNCTION.ExtractRateEUR(FinCurrId
                                  , aRateType
                                  , aDate
                                  , aExchangeRate
                                  , aBasePrice
                                  , BaseChange
                                  , RateExchangeEUR
                                  , BasePriceEUR
                                  , EuroChange
                                   );

      -- Si le cours est en monnaie étrangère, alors il faut le convertir en monnaie base
      if     BaseChange = 0
         and aExchangeRate <> 0 then
        aExchangeRate  :=( (aBasePrice * aBasePrice) / aExchangeRate);
      end if;

      ACS_FUNCTION.ConvertAmount(aAmount
                               , aFromFinCurrId
                               , aToFinCurrId
                               , aDate
                               , aExchangeRate
                               , aBasePrice
                               , aRound
                               , aAmountEUR
                               , aAmountConvert
                                );
    end if;
  end ConvertAmounts;

-----------------------------
  procedure ProportionalAmounts(
    aIMF_AMOUNT_LC_D            in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aIMF_AMOUNT_LC_C            in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_AMOUNT_FC_D            in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aIMF_AMOUNT_FC_C            in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aACS_FINANCIAL_CURRENCY_ID  in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , a_ACS_FINANCIAL_CURRENCY_ID in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aIMF_TRANSACTION_DATE       in     ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aProportion                 in     number
  , aAmountLC_D                 in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmountLC_C                 in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aAmountFC_D                 in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmountFC_C                 in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aAmountEUR_D                in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmountEUR_C                in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aExchangeRate               in out ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aBasePrice                  in out ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  )
  is
    Flag            number(1);
    BaseChange      number(1)                                         default 0;
    RateExchangeEUR ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePriceEUR    ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    EuroChange      number(1)                                         default 0;
  begin
    aAmountLC_D    := 0;
    aAmountLC_C    := 0;
    aAmountFC_D    := 0;
    aAmountFC_C    := 0;
    aAmountEUR_D   := 0;
    aAmountEUR_C   := 0;
    aExchangeRate  := 0;
    aBasePrice     := 0;

    if aACS_FINANCIAL_CURRENCY_ID <> a_ACS_FINANCIAL_CURRENCY_ID then
      aAmountFC_D  := aIMF_AMOUNT_FC_D * aProportion;
      aAmountFC_C  := aIMF_AMOUNT_FC_C * aProportion;
      ACT_DOC_TRANSACTION.ConvertAmounts(aAmountFC_D
                                       , aACS_FINANCIAL_CURRENCY_ID
                                       , a_ACS_FINANCIAL_CURRENCY_ID
                                       , aIMF_TRANSACTION_DATE
                                       , 1   -- aRound
                                       , 1   -- aRateType
                                       , aExchangeRate
                                       , aBasePrice
                                       , aAmountEUR_D
                                       , aAmountLC_D
                                        );
      ACT_DOC_TRANSACTION.ConvertAmounts(aAmountFC_C
                                       , aACS_FINANCIAL_CURRENCY_ID
                                       , a_ACS_FINANCIAL_CURRENCY_ID
                                       , aIMF_TRANSACTION_DATE
                                       , 1   -- aRound
                                       , 1   -- aRateType
                                       , aExchangeRate
                                       , aBasePrice
                                       , aAmountEUR_C
                                       , aAmountLC_C
                                        );
    else
      aAmountLC_D  := ACS_FUNCTION.RoundAmount(aIMF_AMOUNT_LC_D * aProportion, aACS_FINANCIAL_CURRENCY_ID);
      aAmountLC_C  := ACS_FUNCTION.RoundAmount(aIMF_AMOUNT_LC_C * aProportion, aACS_FINANCIAL_CURRENCY_ID);
    end if;
  end ProportionalAmounts;

  /**
  * Description
  *    Retour de la date donnée augmenté d'un délai
  **/
  function AddDateDelay(pDate date, pDateInterval number, pDateCode number)
    return date
  is
    vCalculatedDay   date;
    vCalculatedWeek  date;
    vCalculatedMonth date;
    vCalculatedYear  date;
  begin
    begin
      select (pDate + pDateInterval)
           , (pDate +(pDateInterval * 7) )
           , add_months(pDate, pDateInterval)
           , add_months(pDate, pDateInterval * 12)
--             to_date(to_char(pDate,'DD.') || to_char(pdate,'MM.') || (To_char(pdate,'YYYY') + pDateInterval),'DD.MM.YYYY')
      into   vCalculatedDay
           , vCalculatedWeek
           , vCalculatedMonth
           , vCalculatedYear
        from dual;

      if pDateCode = 0 then   --Jours
        return vCalculatedDay;
      elsif pDateCode = 1 then   --Semaine
        return vCalculatedWeek;
      elsif pDateCode = 2 then   --Mois
        return vCalculatedMonth;
      elsif pDateCode = 3 then   --Année
        return vCalculatedYear;
      end if;
    exception
      when others then
        return pDate;
    end;
  end AddDateDelay;

  /**
  * Description
  *    Contrôle la validité de la date donnée dans l'exercice et la période
  **/
  function ValidateDate(
    pDate            date
  , pFinancialYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pPeriodId        ACS_PERIOD.ACS_PERIOD_ID%type
  )
    return date
  is
    vValidDate  date;
    vFEndDate   ACS_FINANCIAL_YEAR.FYE_END_DATE%type;
    vFStartDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
    vPEndDate   ACS_PERIOD.PER_END_DATE%type;
    vPStartDate ACS_PERIOD.PER_START_DATE%type;
  begin
    /*Si la période est renseignée  - Date de référence si celle-ci est comprise dans la période donnée
                                    - Date début période si date référence antérieure à début période
                                    - Date fin période si date référence postérieure à fin période
      sinon                         - Date de référence si celle-ci est comprise dans l'exercice donné
                                    - Date début exercice si date référence antérieure à début exercice
                                    - Date fin pexercice si date référence postérieure à fin exercice
    */
    begin
      /*Réception date début / fin Exercice / Période*/
      select FYE.FYE_END_DATE
           , FYE.FYE_START_DATE
           , PER.PER_END_DATE
           , PER.PER_START_DATE
        into vFEndDate
           , vFStartDate
           , vPEndDate
           , vPStartDate
        from ACS_FINANCIAL_YEAR FYE
           , ACS_PERIOD PER
       where FYE.ACS_FINANCIAL_YEAR_ID = pFinancialYearId
         and PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
         and PER.ACS_PERIOD_ID = decode(pPeriodId, null, PER.ACS_PERIOD_ID, pPeriodId)
         and PER.C_STATE_PERIOD = 'ACT'
         and PER.C_TYPE_PERIOD = '2'
         and rownum = 1;

      if pPeriodId is null then
        if (pDate > vFEndDate) then
          return vFEndDate;
        elsif(pDate < vFStartDate) then
          return vFStartDate;
        else
          return pDate;
        end if;
      else
        if (pDate > vPEndDate) then
          return vPEndDate;
        elsif(pDate < vPStartDate) then
          return vPStartDate;
        else
          return pDate;
        end if;
      end if;
    exception
      when no_data_found then
        return pDate;
    end;
   /*  Incompatibilité Oracle 8xxx

   select  decode(decode(pPeriodId ,
                         null,(case
                                 when (pDate > FYE.FYE_END_DATE)   then '+F'
                                 when (pDate < FYE.FYE_START_DATE) then '-F'
                               end),
                        (case
                           when (pDate > PER.PER_END_DATE)   then '+P'
                           when (pDate < PER.PER_START_DATE) then '-P'
                         end)
                        ),
                  '+F',FYE.FYE_END_DATE,
                  '-F',FYE.FYE_START_DATE,
                  '+P',PER.PER_END_DATE,
                  '-P',PER.PER_START_DATE,
                  pDate) VALIDDATE into vValidDate
   from   ACS_FINANCIAL_YEAR FYE,
          ACS_PERIOD PER
   where FYE.ACS_FINANCIAL_YEAR_ID = pFinancialYearId
     and PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
     and PER.ACS_PERIOD_ID         = decode(pPeriodId,
                                            null, PER.ACS_PERIOD_ID,
                                            pPeriodId)
     and PER.C_STATE_PERIOD        = 'ACT'
     and PER.C_TYPE_PERIOD         = '2'
     and rownum = 1;
   return vValidDate;
  */
  end ValidateDate;

------------------------
  procedure CheckImputations(
    aACT_DOCUMENT_ID in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aCheckFinancial  in     boolean
  , aCheckManagement in     boolean
  , aErrorDocument   in out ErrorDocumentRecType
  )
  is
    reccount   integer;
    parity     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    DefCurrId  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    cpn_choice number(1);
    cat_ext    number(1);
    ln_RiskMgt ACJ_CATALOGUE_DOCUMENT.CAT_CURR_RISK_MGT%type;
    lv_CatType ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
    lv_CoverType ACT_DOCUMENT.C_CURR_RATE_COVER_TYPE%type;

  begin
    if aCheckFinancial then
      -- Contrôle débit-crédit sur imputations financières
      select count(IMP.ACT_FINANCIAL_IMPUTATION_ID)
           , sum(IMP.IMF_AMOUNT_LC_D) - sum(IMP.IMF_AMOUNT_LC_C)
        into reccount
           , parity
        from ACT_FINANCIAL_IMPUTATION IMP
       where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      if reccount = 0 then
        aErrorDocument.NoFinImput  := true;
      else
        aErrorDocument.ParityFin  := parity != 0;
      end if;
    elsif     (not aCheckFinancial)
          and aCheckManagement then
      -- Contrôle débit-crédit sur imputations analytiques
      select count(MGM.ACT_MGM_IMPUTATION_ID)
           , sum(MGM.IMM_AMOUNT_LC_D) - sum(MGM.IMM_AMOUNT_LC_C)
        into reccount
           , parity
        from ACT_MGM_IMPUTATION MGM
       where MGM.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      if reccount = 0 then
        aErrorDocument.NoManImput  := true;
      else
        aErrorDocument.ParityMan  :=(parity != 0);
      end if;
    end if;

    if aCheckFinancial then
      -- Contrôle si écriture avec compte fin. nécessitant une monnaie étrangère
      DefCurrId                  := ACS_FUNCTION.GetLocalCurrencyID;

      begin
        select min(ACS_FINANCIAL_ACCOUNT_ID)
          into aErrorDocument.id
          from (select   ACCCUR2.ACS_FINANCIAL_ACCOUNT_ID
                    from ACS_FIN_ACCOUNT_S_FIN_CURR ACCCUR2
                       , (select distinct IMP.ACS_FINANCIAL_ACCOUNT_ID
                                     from ACS_FIN_ACCOUNT_S_FIN_CURR ACCCUR
                                        , ACT_FINANCIAL_IMPUTATION IMP
                                    where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                                      and ACCCUR.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                                      and ACCCUR.ACS_FINANCIAL_CURRENCY_ID != IMP.ACS_FINANCIAL_CURRENCY_ID
                                      and ACCCUR.FSC_DEFAULT = 1
                                      and ACCCUR.ACS_FINANCIAL_CURRENCY_ID != DefCurrId) ACCDEFFC
                   where ACCCUR2.ACS_FINANCIAL_ACCOUNT_ID = ACCDEFFC.ACS_FINANCIAL_ACCOUNT_ID
                     and ACCCUR2.ACS_FINANCIAL_CURRENCY_ID != DefCurrId
                group by ACCCUR2.ACS_FINANCIAL_ACCOUNT_ID
                  having count(*) = 1);
      exception
        when no_data_found then
          aErrorDocument.id  := null;
      end;

      aErrorDocument.FinAccCurr  := aErrorDocument.id is not null;

      if aErrorDocument.FinAccCurr then
        return;
      end if;
    end if;

    if aCheckFinancial then
      -- Contrôle sur le compte de portefeuille si pas une transaction d'extourne:
      --  - Couverture sur l'écriture primaire
      --  - Décharge (ACT_COVER_DISCHARGED) pour les contres-écritures

      -- Recherche si cat. extourne
      select nvl(CAT.CAT_EXT_TRANSACTION, 0)
        into cat_ext
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;

      if cat_ext = 0 then
        begin
          select IMP.ACT_FINANCIAL_IMPUTATION_ID
               , IMP.IMF_PRIMARY
            into aErrorDocument.id
               , aErrorDocument.primary
            from ACT_DOCUMENT DOC
               , ACS_FINANCIAL_ACCOUNT FIN
               , ACT_FINANCIAL_IMPUTATION IMP
           where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and DOC.ACT_COVER_INFORMATION_ID is null
             and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and IMP.IMF_PRIMARY = 1
             and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
             and FIN.FIN_PORTFOLIO = 1
             and rownum = 1;
        exception
          when no_data_found then
            aErrorDocument.id       := null;
            aErrorDocument.primary  := null;
        end;

        aErrorDocument.PortfolioCover  := aErrorDocument.id is not null;

        if not aErrorDocument.PortfolioCover then
          begin
            select IMP.ACT_FINANCIAL_IMPUTATION_ID
                 , IMP.IMF_PRIMARY
              into aErrorDocument.id
                 , aErrorDocument.primary
              from ACS_FINANCIAL_ACCOUNT FIN
                 , ACT_FINANCIAL_IMPUTATION IMP
             where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
               and IMP.IMF_PRIMARY = 0
               and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and FIN.FIN_PORTFOLIO = 1
               and not exists(select ACT_FINANCIAL_IMPUTATION_ID
                                from ACT_COVER_DISCHARGED
                               where ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID)
               and rownum = 1;
          exception
            when no_data_found then
              aErrorDocument.id       := null;
              aErrorDocument.primary  := null;
          end;

          aErrorDocument.PortfolioCover  := aErrorDocument.id is not null;
        end if;

        if aErrorDocument.PortfolioCover then
          return;
        end if;
      end if;
    end if;

    if aCheckFinancial then
      -- Contrôle si document sans detail paiement et sans échéance
      select count(*)
        into reccount
        from ACT_DET_PAYMENT DET
       where DET.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      if reccount = 0 then
        select count(*)
          into reccount
          from ACT_EXPIRY exp
         where exp.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

        aErrorDocument.NoDetPayExp  :=(reccount = 0);
      end if;
    end if;

    if aCheckFinancial then
      -- Contrôle si ACS_AUXILIARY_ACCOUNT_ID rempli sans ACT_PART_IMPUTATION_ID
      begin
        select IMP.ACT_FINANCIAL_IMPUTATION_ID
             , IMP.IMF_PRIMARY
          into aErrorDocument.id
             , aErrorDocument.primary
          from ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACT_PART_IMPUTATION_ID is null
           and rownum = 1;
      exception
        when no_data_found then
          aErrorDocument.id       := null;
          aErrorDocument.primary  := null;
      end;

      aErrorDocument.MissPartImp  := aErrorDocument.id is not null;

      if not aErrorDocument.MissPartImp then
        -- Contrôle si compte auxiliaire correspond au compte aux. du partenaire
        begin
          select IMP.ACT_FINANCIAL_IMPUTATION_ID
               , IMP.IMF_PRIMARY
            into aErrorDocument.id
               , aErrorDocument.primary
            from ACT_FINANCIAL_IMPUTATION IMP
           where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and IMP.ACT_PART_IMPUTATION_ID is not null
             and IMP.ACS_AUXILIARY_ACCOUNT_ID != nvl(IMP.IMF_ACS_AUX_ACCOUNT_CUST_ID, IMP.IMF_ACS_AUX_ACCOUNT_SUPP_ID)
             and rownum = 1;
        exception
          when no_data_found then
            aErrorDocument.id       := null;
            aErrorDocument.primary  := null;
        end;

        aErrorDocument.WrongAuxAcc  := aErrorDocument.id is not null;
      end if;

      -- Contrôle si présence d'un ACS_AUXILIARY_ACCOUNT_ID sur un compte non collectif ou inverse
      begin
        select IMP.ACT_FINANCIAL_IMPUTATION_ID
             , IMP.IMF_PRIMARY
          into aErrorDocument.id
             , aErrorDocument.primary
          from ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and (    (    FIN.FIN_COLLECTIVE = 1
                     and IMP.ACS_AUXILIARY_ACCOUNT_ID is null)
                or (    FIN.FIN_COLLECTIVE = 0
                    and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null)
               )
           and rownum = 1;
      exception
        when no_data_found then
          aErrorDocument.id       := null;
          aErrorDocument.primary  := null;
      end;

      aErrorDocument.AuxAccColl   := aErrorDocument.id is not null;
    end if;

    if     (not aErrorDocument.NoFinImput)
       and aCheckFinancial
       and aCheckManagement then
      -- Contrôle si les imputations financière avec un compte demandant de l'analytique ont bien une imputation analytique liée.
      -- On ne tient pas compte du flag si on uniquement un sous-ensemble CPN pour le catalogue.
      select count(*)
        into reccount
        from ACJ_SUB_SET_CAT SCAT
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and SCAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
         and SCAT.C_SUB_SET = 'CPN';

      if reccount > 0 then
        select count(*)
          into reccount
          from ACJ_SUB_SET_CAT SCAT
             , ACT_DOCUMENT DOC
         where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and SCAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;
      end if;

      if reccount > 1 then
        begin
          select IMP.ACT_FINANCIAL_IMPUTATION_ID
               , IMP.IMF_PRIMARY
            into aErrorDocument.id
               , aErrorDocument.primary
            from ACT_FINANCIAL_IMPUTATION IMP
           where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and not exists(select MGM.ACT_MGM_IMPUTATION_ID
                              from ACT_MGM_IMPUTATION MGM
                             where MGM.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID)
             and (select FIN.ACS_CPN_ACCOUNT_ID
                    from ACS_FINANCIAL_ACCOUNT FIN
                   where FIN.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) is not null
             and rownum = 1;
        exception
          when no_data_found then
            aErrorDocument.id       := null;
            aErrorDocument.primary  := null;
        end;

        aErrorDocument.MissManImput  := aErrorDocument.id is not null;

        if aErrorDocument.MissManImput then
          return;
        end if;
      end if;
    end if;

    if     (not aErrorDocument.NoFinImput)
       and (not aErrorDocument.NoManImput)
       and aCheckFinancial
       and aCheckManagement then
      -- Contrôle si le compte CPN correspond bien à celui défini sur le compte financier dans le cas ou le 'Choix CPN autorisé' n'est pas activé.
      -- On ne tient pas compte du flag si on uniquement un sous-ensemble CPN pour le catalogue.
      select nvl(min(SCAT.SUB_CPN_CHOICE), 1)
        into cpn_choice
        from ACJ_SUB_SET_CAT SCAT
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and SCAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
         and SCAT.C_SUB_SET = 'CPN';

      if cpn_choice = 0 then
        select count(*)
          into reccount
          from ACJ_SUB_SET_CAT SCAT
             , ACT_DOCUMENT DOC
         where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and SCAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;

        if reccount = 1 then
          cpn_choice  := 1;
        end if;
      end if;

      if cpn_choice = 0 then
        begin
          select IMP.ACT_FINANCIAL_IMPUTATION_ID
               , IMP.IMF_PRIMARY
            into aErrorDocument.id
               , aErrorDocument.primary
            from ACT_MGM_IMPUTATION MGM
               , ACT_FINANCIAL_IMPUTATION IMP
           where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
             and MGM.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID
             and MGM.ACS_CPN_ACCOUNT_ID != (select FIN.ACS_CPN_ACCOUNT_ID
                                              from ACS_FINANCIAL_ACCOUNT FIN
                                             where FIN.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID)
             and rownum = 1;
        exception
          when no_data_found then
            aErrorDocument.id       := null;
            aErrorDocument.primary  := null;
        end;

        aErrorDocument.WrongCpnAcc  := aErrorDocument.id is not null;
      end if;
    end if;

    if     (not aErrorDocument.NoFinImput)
       and (not aErrorDocument.NoManImput)
       and (not aErrorDocument.WrongCpnAcc)
       and aCheckFinancial
       and aCheckManagement then
      -- Contrôle total imputations analytiques pour une imputation financière = montant imputation financière
      begin
        select IMP.ACT_FINANCIAL_IMPUTATION_ID
             , IMP.IMF_PRIMARY
          into aErrorDocument.id
             , aErrorDocument.primary
          from ACT_FINANCIAL_IMPUTATION IMP
             , (select   ACT_FINANCIAL_IMPUTATION_ID
                       , sum(MGM.IMM_AMOUNT_LC_D) - sum(IMM_AMOUNT_LC_C) TOT_IMPUTATION
                    from ACT_MGM_IMPUTATION MGM
                   where MGM.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                group by ACT_FINANCIAL_IMPUTATION_ID) TOT_MGM_IMPUTATION
         where TOT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID
           and TOT_MGM_IMPUTATION.TOT_IMPUTATION !=(IMP.IMF_AMOUNT_LC_D - IMP.IMF_AMOUNT_LC_C)
           and rownum = 1;
      exception
        when no_data_found then
          aErrorDocument.id       := null;
          aErrorDocument.primary  := null;
      end;

      aErrorDocument.TotFin_Man  := aErrorDocument.id is not null;
    end if;

    if     (not aErrorDocument.NoManImput)
       and (not aErrorDocument.TotFin_Man)
       and (not aErrorDocument.WrongCpnAcc)
       and aCheckManagement then
      -- Contrôle total imputations projets pour une imputation analytique = montant imputation analytique
      begin
        select MGM.ACT_MGM_IMPUTATION_ID
             , MGM.IMM_PRIMARY
          into aErrorDocument.id
             , aErrorDocument.primary
          from ACT_MGM_IMPUTATION MGM
             , (select   DIST.ACT_MGM_IMPUTATION_ID
                       , sum(DIST.MGM_AMOUNT_LC_D) - sum(DIST.MGM_AMOUNT_LC_C) TOT_DISTRIBUTION
                    from ACT_MGM_DISTRIBUTION DIST
                       , ACT_MGM_IMPUTATION MGM2
                   where DIST.ACT_MGM_IMPUTATION_ID = MGM2.ACT_MGM_IMPUTATION_ID
                     and MGM2.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                group by DIST.ACT_MGM_IMPUTATION_ID) TOT_DIST
         where TOT_DIST.ACT_MGM_IMPUTATION_ID = MGM.ACT_MGM_IMPUTATION_ID
           and TOT_DIST.TOT_DISTRIBUTION !=(MGM.IMM_AMOUNT_LC_D - MGM.IMM_AMOUNT_LC_C)
           and rownum = 1;
      exception
        when no_data_found then
          aErrorDocument.id       := null;
          aErrorDocument.primary  := null;
      end;

      aErrorDocument.TotMan_Pro  := aErrorDocument.id is not null;
    end if;

    --Vérificataions pour le hedging
    if PCS.PC_CONFIG.GetConfig('COM_CURRENCY_RISK_MANAGE') ='1' then
      --Récupérer les informations du document et catalogue
      select CAT.CAT_CURR_RISK_MGT
           , CAT.C_TYPE_CATALOGUE
           , DOC.C_CURR_RATE_COVER_TYPE
        into ln_RiskMgt,
             lv_CatType,
             lv_CoverType
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;
       --Selon Analyse : Si TC document <> '0' alors toutes les imputations doivent avoir le même dossier d'affaire

       --Document Facture / Avance / NC  gère  les taux de couverture
       if (ln_RiskMgt = 1) and (lv_CatType in ('2', '5' , '6' )) and (lv_CoverType <> '00')  then
         if aCheckFinancial then
         begin
           select IMP.ACT_FINANCIAL_IMPUTATION_ID
                , IMP.IMF_PRIMARY
             into aErrorDocument.id
                , aErrorDocument.primary
             from ACT_FINANCIAL_IMPUTATION IMP
            where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
              and IMP.IMF_PRIMARY <> 1
              and IMP.DOC_RECORD_ID <>
                               (select DOC_RECORD_ID
                                  from ACT_FINANCIAL_IMPUTATION FIN
                                 where FIN.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                                   and (FIN.ACS_FINANCIAL_CURRENCY_ID <> FIN.ACS_ACS_FINANCIAL_CURRENCY_ID)
                                   and FIN.IMF_PRIMARY = 1)
           and rownum = 1;

           exception
             when no_data_found then
              aErrorDocument.id       := null;
              aErrorDocument.primary  := null;
           end;
           aErrorDocument.GalFinProjectMissing  := aErrorDocument.id is not null;
         end if;

         if aCheckManagement then
         begin
           select MGM.ACT_MGM_IMPUTATION_ID
                , MGM.IMM_PRIMARY
             into aErrorDocument.id
                , aErrorDocument.primary
             from ACT_MGM_IMPUTATION MGM
            where MGM.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
              and MGM.DOC_RECORD_ID <>
                               (select DOC_RECORD_ID
                                  from ACT_FINANCIAL_IMPUTATION FIN
                                 where FIN.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                                   and (FIN.ACS_FINANCIAL_CURRENCY_ID <> FIN.ACS_ACS_FINANCIAL_CURRENCY_ID)
                                   and FIN.IMF_PRIMARY = 1)
           and rownum = 1;

           exception
             when no_data_found then
              aErrorDocument.id       := null;
              aErrorDocument.primary  := null;
           end;
           aErrorDocument.GalMgmProjectMissing  := aErrorDocument.id is not null;
         end if;
       end if;
    end if;
  end CheckImputations;

------------------------
  procedure CheckInfoImputations(
    aACT_DOCUMENT_ID in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aCheckFinancial  in     boolean
  , aCheckManagement in     boolean
  , aErrorDocument   in out ErrorDocumentRecType
  )
  is
    cursor csrFinImp(DocId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   ACT_FINANCIAL_IMPUTATION_ID
             , IMF_PRIMARY
          from ACT_FINANCIAL_IMPUTATION
         where ACT_DOCUMENT_ID = DocId
      order by ACT_FINANCIAL_IMPUTATION_ID;

    cursor csrMgmImp(DocId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   ACT_MGM_IMPUTATION_ID
             , IMM_PRIMARY
          from ACT_MGM_IMPUTATION
         where ACT_DOCUMENT_ID = DocId
      order by ACT_MGM_IMPUTATION_ID;

    cursor csrMgmDist(DocId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   DIST.ACT_MGM_DISTRIBUTION_ID
             , IMP.IMM_PRIMARY
          from ACT_MGM_DISTRIBUTION DIST
             , ACT_MGM_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = DocId
           and DIST.ACT_MGM_IMPUTATION_ID = IMP.ACT_MGM_IMPUTATION_ID
      order by DIST.ACT_MGM_DISTRIBUTION_ID;

    catalogue_document_id ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    managed_infos         ACT_IMP_MANAGEMENT.InfoImputationRecType;
    info_imp_values       ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    error_info_imp        integer;
  begin
    select ACJ_CATALOGUE_DOCUMENT_ID
      into catalogue_document_id
      from ACT_DOCUMENT
     where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    managed_infos  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);

    if managed_infos.managed then
      if aCheckFinancial then
        for tplFinImp in csrFinImp(aACT_DOCUMENT_ID) loop
          ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMF(tplFinImp.act_financial_imputation_id, info_imp_values);

          if tplFinImp.imf_primary = 0 then
            error_info_imp  := ACT_IMP_MANAGEMENT.CheckManagedValues(info_imp_values, managed_infos.Secondary);
          else
            error_info_imp  := ACT_IMP_MANAGEMENT.CheckManagedValues(info_imp_values, managed_infos.primary);
          end if;

          if error_info_imp != 0 then
            aErrorDocument.InfoImpFin  := true;
            aErrorDocument.id          := tplFinImp.act_financial_imputation_id;
            aErrorDocument.primary     := tplFinImp.imf_primary;
            exit;
          end if;
        end loop;
      end if;

      if aCheckManagement then
        if error_info_imp = 0 then
          for tplMgmImp in csrMgmImp(aACT_DOCUMENT_ID) loop
            ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMM(tplMgmImp.act_mgm_imputation_id, info_imp_values);

            if tplMgmImp.imm_primary = 0 then
              error_info_imp  := ACT_IMP_MANAGEMENT.CheckManagedValues(info_imp_values, managed_infos.Secondary);
            else
              error_info_imp  := ACT_IMP_MANAGEMENT.CheckManagedValues(info_imp_values, managed_infos.primary);
            end if;

            if error_info_imp != 0 then
              aErrorDocument.InfoImpMan  := true;
              aErrorDocument.id          := tplMgmImp.act_mgm_imputation_id;
              aErrorDocument.primary     := tplMgmImp.imm_primary;
              exit;
            end if;
          end loop;
        end if;

        if error_info_imp = 0 then
          for tplMgmDist in csrMgmDist(aACT_DOCUMENT_ID) loop
            ACT_IMP_MANAGEMENT.GetInfoImputationValuesMGM(tplMgmDist.act_mgm_distribution_id, info_imp_values);

            if tplMgmDist.imm_primary = 0 then
              error_info_imp  := ACT_IMP_MANAGEMENT.CheckManagedValues(info_imp_values, managed_infos.Secondary);
            else
              error_info_imp  := ACT_IMP_MANAGEMENT.CheckManagedValues(info_imp_values, managed_infos.primary);
            end if;

            if error_info_imp != 0 then
              aErrorDocument.InfoImpPro  := true;
              aErrorDocument.id          := tplMgmDist.act_mgm_distribution_id;
              aErrorDocument.primary     := tplMgmDist.imm_primary;
              exit;
            end if;
          end loop;
        end if;
      end if;
    end if;
  end CheckInfoImputations;

------------------------
  procedure CheckMANImputPermission(
    aACT_DOCUMENT_ID in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aErrorDocument   in out ErrorDocumentRecType
  )
  is
    cursor csrMgmImp(DocId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACT_MGM_DISTRIBUTION.ACS_PJ_ACCOUNT_ID
             , IMM_PRIMARY
             , ACS_QTY_UNIT_ID
             , IMM_TRANSACTION_DATE
          from ACT_MGM_DISTRIBUTION
             , ACT_MGM_IMPUTATION
         where ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID = DocId
           and ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID = ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID(+)
      order by ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID;

    CDAPermission number(1);
    PFPermission  number(1);
    PJPermission  number(1);
    lastMgmImpId  ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type   := 0;
    reccount      integer;
  begin
    for tplMgmImp in csrMgmImp(aACT_DOCUMENT_ID) loop
      -- Contrôle des comptes sur ACT_MGM_IMPUTATION
      if lastMgmImpId != tplMgmImp.ACS_CPN_ACCOUNT_ID then
        ACT_CREATION_SBVR.GetMANImputationPermission(tplMgmImp.ACS_CPN_ACCOUNT_ID
                                                   , CDAPermission
                                                   , PFPermission
                                                   , PJPermission
                                                    );
        lastMgmImpId  := tplMgmImp.ACS_CPN_ACCOUNT_ID;

        if    (     (tplMgmImp.ACS_PF_ACCOUNT_ID is not null)
               and (tplMgmImp.ACS_CDA_ACCOUNT_ID is not null)
               and (PFPermission = 2)
               and (CDAPermission = 2)
              )
           or (     (tplMgmImp.ACS_PF_ACCOUNT_ID is not null)
               and (PFPermission = 3) )
           or (     (tplMgmImp.ACS_CDA_ACCOUNT_ID is not null)
               and (CDAPermission = 3) )
           or (     (tplMgmImp.ACS_PF_ACCOUNT_ID is null)
               and (PFPermission = 1) )
           or (     (tplMgmImp.ACS_CDA_ACCOUNT_ID is null)
               and (CDAPermission = 1) )
           or (     (tplMgmImp.ACS_PF_ACCOUNT_ID is null)
               and (tplMgmImp.ACS_CDA_ACCOUNT_ID is null) ) then
          aErrorDocument.CpnPerm  := true;
          aErrorDocument.id       := tplMgmImp.act_mgm_imputation_id;
          aErrorDocument.primary  := tplMgmImp.imm_primary;
          exit;
        end if;
      end if;

      -- Contrôle si unité quantitative obligatoire
      if tplMgmImp.ACS_QTY_UNIT_ID is null then
        select count(*)
          into reccount
          from ACS_QTY_S_CPN_ACOUNT QTC
         where QTC.ACS_CPN_ACCOUNT_ID = tplMgmImp.ACS_CPN_ACCOUNT_ID
           and tplMgmImp.IMM_TRANSACTION_DATE between nvl(QTC.QTA_FROM, tplMgmImp.IMM_TRANSACTION_DATE)
                                                  and nvl(QTC.QTA_TO, tplMgmImp.IMM_TRANSACTION_DATE)
           and QTC.C_AUTHORIZATION_TYPE = '1';

        if reccount > 0 then
          aErrorDocument.MissQtyUnit  := true;
          aErrorDocument.id           := tplMgmImp.act_mgm_imputation_id;
          aErrorDocument.primary      := tplMgmImp.imm_primary;
          exit;
        end if;
      end if;

      -- Contrôle du compte projet
      if    (     (tplMgmImp.ACS_PJ_ACCOUNT_ID is not null)
             and (PJPermission = 3) )
         or (     (tplMgmImp.ACS_PJ_ACCOUNT_ID is null)
             and (PJPermission = 1) ) then
        aErrorDocument.CpnPerm  := true;
        aErrorDocument.id       := tplMgmImp.act_mgm_imputation_id;
        aErrorDocument.primary  := tplMgmImp.imm_primary;
        exit;
      end if;
    end loop;
  end CheckMANImputPermission;

------------------------
  procedure CheckAccounts(
    aACT_DOCUMENT_ID in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aCheckFinancial  in     boolean
  , aCheckManagement in     boolean
  , aErrorDocument   in out ErrorDocumentRecType
  )
  is
    cursor csrFinImp(DocId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   IMP.*
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , (select DIS.ACT_FINANCIAL_DISTRIBUTION_ID
                  from ACT_FINANCIAL_DISTRIBUTION DIS
                 where DIS.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) ACT_FINANCIAL_DISTRIBUTION_ID
             , nvl(ACC1.ACC_BLOCKED, 0) ACC_BLOCKED
             , ACC1.ACC_VALID_SINCE
             , ACC1.ACC_VALID_TO
          from ACS_ACCOUNT ACC1
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = DocId
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC1.ACS_ACCOUNT_ID
      order by IMP.ACT_FINANCIAL_IMPUTATION_ID;

    cursor csrMgmImp(DocId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   ACT_MGM_IMPUTATION.*
             , ACT_MGM_DISTRIBUTION.ACS_PJ_ACCOUNT_ID
             , ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID
             , nvl(ACC1.ACC_BLOCKED, 0) ACC_BLOCKED1
             , ACC1.ACC_VALID_SINCE ACC_VALID_SINCE1
             , ACC1.ACC_VALID_TO ACC_VALID_TO1
             , nvl(ACC2.ACC_BLOCKED, 0) ACC_BLOCKED2
             , ACC2.ACC_VALID_SINCE ACC_VALID_SINCE2
             , ACC2.ACC_VALID_TO ACC_VALID_TO2
             , nvl(ACC3.ACC_BLOCKED, 0) ACC_BLOCKED3
             , ACC3.ACC_VALID_SINCE ACC_VALID_SINCE3
             , ACC3.ACC_VALID_TO ACC_VALID_TO3
             , nvl(ACC4.ACC_BLOCKED, 0) ACC_BLOCKED4
             , ACC4.ACC_VALID_SINCE ACC_VALID_SINCE4
             , ACC4.ACC_VALID_TO ACC_VALID_TO4
          from ACS_ACCOUNT ACC4
             , ACS_ACCOUNT ACC3
             , ACS_ACCOUNT ACC2
             , ACS_ACCOUNT ACC1
             , ACT_MGM_DISTRIBUTION
             , ACT_MGM_IMPUTATION
         where ACT_DOCUMENT_ID = DocId
           and ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID(+) = ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
           and ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID = ACC1.ACS_ACCOUNT_ID
           and ACT_MGM_IMPUTATION.ACS_CDA_ACCOUNT_ID = ACC2.ACS_ACCOUNT_ID(+)
           and ACT_MGM_IMPUTATION.ACS_PF_ACCOUNT_ID = ACC3.ACS_ACCOUNT_ID(+)
           and ACT_MGM_DISTRIBUTION.ACS_PJ_ACCOUNT_ID = ACC4.ACS_ACCOUNT_ID(+)
      order by ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID;

    cursor csrMgmDist(DocId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
             , ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID
             , ACT_MGM_IMPUTATION.IMM_PRIMARY
             , ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE
             , ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , nvl(ACC1.ACC_BLOCKED, 0) ACC_BLOCKED
             , ACC1.ACC_VALID_SINCE
             , ACC1.ACC_VALID_TO
          from ACS_ACCOUNT ACC1
             , ACT_MGM_DISTRIBUTION
             , ACT_MGM_IMPUTATION
         where ACT_DOCUMENT_ID = DocId
           and ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID = ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
           and ACT_MGM_DISTRIBUTION.ACS_PJ_ACCOUNT_ID = ACC1.ACS_ACCOUNT_ID
      order by ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID;

    reccount integer;
  begin
    if aCheckFinancial then
      for tplFinImp in csrFinImp(aACT_DOCUMENT_ID) loop
        -- Contrôle des comptes financier
        if    tplFinImp.ACC_BLOCKED = 1
           or (    tplFinImp.ACC_VALID_SINCE is not null
               and tplFinImp.IMF_TRANSACTION_DATE < tplFinImp.ACC_VALID_SINCE)
           or (    tplFinImp.ACC_VALID_TO is not null
               and tplFinImp.IMF_TRANSACTION_DATE > tplFinImp.ACC_VALID_TO) then
          aErrorDocument.FinAcc   := true;
          aErrorDocument.id       := tplFinImp.act_financial_imputation_id;
          aErrorDocument.primary  := tplFinImp.imf_primary;
          exit;
        end if;

        -- Contrôle des comptes division
        if     (tplFinImp.ACS_DIVISION_ACCOUNT_ID is not null)
           and ACS_FUNCTION.IsDivisionAuthorized(tplFinImp.ACS_DIVISION_ACCOUNT_ID
                                               , PCS.PC_I_LIB_SESSION.GetUserId2
                                               , tplFinImp.IMF_TRANSACTION_DATE
                                                ) = 0 then
          aErrorDocument.DivAcc   := true;
          aErrorDocument.id       := tplFinImp.act_financial_distribution_id;
          aErrorDocument.primary  := tplFinImp.imf_primary;
          exit;
        end if;
      end loop;
    end if;

    if     aCheckManagement
       and aErrorDocument.id is null then
      for tplMgmImp in csrMgmImp(aACT_DOCUMENT_ID) loop
        -- Contrôle compte CPN
        if tplMgmImp.ACS_CPN_ACCOUNT_ID is not null then
          if    tplMgmImp.ACC_BLOCKED1 = 1
             or (    tplMgmImp.ACC_VALID_SINCE1 is not null
                 and tplMgmImp.IMM_TRANSACTION_DATE < tplMgmImp.ACC_VALID_SINCE1
                )
             or (    tplMgmImp.ACC_VALID_TO1 is not null
                 and tplMgmImp.IMM_TRANSACTION_DATE > tplMgmImp.ACC_VALID_TO1) then
            aErrorDocument.CpnAcc   := true;
            aErrorDocument.id       := tplMgmImp.act_mgm_imputation_id;
            aErrorDocument.primary  := tplMgmImp.imm_primary;
            exit;
          end if;
        end if;

        -- Contrôle compte CDA
        if tplMgmImp.ACS_CDA_ACCOUNT_ID is not null then
          if    tplMgmImp.ACC_BLOCKED2 = 1
             or (    tplMgmImp.ACC_VALID_SINCE2 is not null
                 and tplMgmImp.IMM_TRANSACTION_DATE < tplMgmImp.ACC_VALID_SINCE2
                )
             or (    tplMgmImp.ACC_VALID_TO2 is not null
                 and tplMgmImp.IMM_TRANSACTION_DATE > tplMgmImp.ACC_VALID_TO2) then
            aErrorDocument.CdaAcc   := true;
            aErrorDocument.id       := tplMgmImp.act_mgm_imputation_id;
            aErrorDocument.primary  := tplMgmImp.imm_primary;
            exit;
          else
            select count(*)
              into reccount
              from acs_mgm_interaction
             where acs_cpn_account_id = tplMgmImp.ACS_CPN_ACCOUNT_ID
               and acs_cda_account_id is not null
               and tplMgmImp.IMM_TRANSACTION_DATE between nvl(MGM_VALID_SINCE, tplMgmImp.IMM_TRANSACTION_DATE)
                                                      and nvl(MGM_VALID_TO, tplMgmImp.IMM_TRANSACTION_DATE);

            if reccount > 0 then
              select count(*)
                into reccount
                from acs_mgm_interaction
               where acs_cpn_account_id = tplMgmImp.ACS_CPN_ACCOUNT_ID
                 and acs_cda_account_id = tplMgmImp.ACS_CDA_ACCOUNT_ID
                 and tplMgmImp.IMM_TRANSACTION_DATE between nvl(MGM_VALID_SINCE, tplMgmImp.IMM_TRANSACTION_DATE)
                                                        and nvl(MGM_VALID_TO, tplMgmImp.IMM_TRANSACTION_DATE);

              if reccount = 0 then
                aErrorDocument.CdaAcc   := true;
                aErrorDocument.id       := tplMgmImp.act_mgm_imputation_id;
                aErrorDocument.primary  := tplMgmImp.imm_primary;
                exit;
              end if;
            end if;
          end if;
        end if;

        -- Contrôle compte PF
        if tplMgmImp.ACS_PF_ACCOUNT_ID is not null then
          if    tplMgmImp.ACC_BLOCKED3 = 1
             or (    tplMgmImp.ACC_VALID_SINCE3 is not null
                 and tplMgmImp.IMM_TRANSACTION_DATE < tplMgmImp.ACC_VALID_SINCE3
                )
             or (    tplMgmImp.ACC_VALID_TO3 is not null
                 and tplMgmImp.IMM_TRANSACTION_DATE > tplMgmImp.ACC_VALID_TO3) then
            aErrorDocument.PfAcc    := true;
            aErrorDocument.id       := tplMgmImp.act_mgm_imputation_id;
            aErrorDocument.primary  := tplMgmImp.imm_primary;
            exit;
          else
            select count(*)
              into reccount
              from acs_mgm_interaction
             where acs_cpn_account_id = tplMgmImp.ACS_CPN_ACCOUNT_ID
               and acs_pf_account_id is not null
               and tplMgmImp.IMM_TRANSACTION_DATE between nvl(MGM_VALID_SINCE, tplMgmImp.IMM_TRANSACTION_DATE)
                                                      and nvl(MGM_VALID_TO, tplMgmImp.IMM_TRANSACTION_DATE);

            if reccount > 0 then
              select count(*)
                into reccount
                from acs_mgm_interaction
               where acs_cpn_account_id = tplMgmImp.ACS_CPN_ACCOUNT_ID
                 and acs_pf_account_id = tplMgmImp.ACS_PF_ACCOUNT_ID
                 and tplMgmImp.IMM_TRANSACTION_DATE between nvl(MGM_VALID_SINCE, tplMgmImp.IMM_TRANSACTION_DATE)
                                                        and nvl(MGM_VALID_TO, tplMgmImp.IMM_TRANSACTION_DATE);

              if reccount = 0 then
                aErrorDocument.PfAcc    := true;
                aErrorDocument.id       := tplMgmImp.act_mgm_imputation_id;
                aErrorDocument.primary  := tplMgmImp.imm_primary;
                exit;
              end if;
            end if;
          end if;
        end if;
      end loop;
    end if;

    -- Contrôle des comptes projets
    if     aCheckManagement
       and aErrorDocument.id is null then
      for tplMgmDist in csrMgmDist(aACT_DOCUMENT_ID) loop
        if tplMgmDist.ACS_PJ_ACCOUNT_ID is not null then
          if    tplMgmDist.ACC_BLOCKED = 1
             or (    tplMgmDist.ACC_VALID_SINCE is not null
                 and tplMgmDist.IMM_TRANSACTION_DATE < tplMgmDist.ACC_VALID_SINCE
                )
             or (    tplMgmDist.ACC_VALID_TO is not null
                 and tplMgmDist.IMM_TRANSACTION_DATE > tplMgmDist.ACC_VALID_TO) then
            aErrorDocument.PjAcc    := true;
            aErrorDocument.id       := tplMgmDist.act_mgm_distribution_id;
            aErrorDocument.primary  := tplMgmDist.imm_primary;
            exit;
          else
            select count(*)
              into reccount
              from acs_mgm_interaction
             where acs_cpn_account_id = tplMgmDist.ACS_CPN_ACCOUNT_ID
               and acs_pj_account_id is not null
               and tplMgmDist.IMM_TRANSACTION_DATE between nvl(MGM_VALID_SINCE, tplMgmDist.IMM_TRANSACTION_DATE)
                                                       and nvl(MGM_VALID_TO, tplMgmDist.IMM_TRANSACTION_DATE);

            if reccount > 0 then
              select count(*)
                into reccount
                from acs_mgm_interaction
               where acs_cpn_account_id = tplMgmDist.ACS_CPN_ACCOUNT_ID
                 and acs_pj_account_id = tplMgmDist.ACS_PJ_ACCOUNT_ID
                 and tplMgmDist.IMM_TRANSACTION_DATE between nvl(MGM_VALID_SINCE, tplMgmDist.IMM_TRANSACTION_DATE)
                                                         and nvl(MGM_VALID_TO, tplMgmDist.IMM_TRANSACTION_DATE);

              if reccount = 0 then
                aErrorDocument.PjAcc    := true;
                aErrorDocument.id       := tplMgmDist.act_mgm_distribution_id;
                aErrorDocument.primary  := tplMgmDist.imm_primary;
                exit;
              end if;
            end if;
          end if;
        end if;
      end loop;
    end if;
  end CheckAccounts;

------------------------
  procedure CheckPartner(
    aACT_DOCUMENT_ID in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aErrorDocument   in out ErrorDocumentRecType
  )
  is
  begin
    begin
      select act_part_imputation.act_part_imputation_id
        into aErrorDocument.id
        from act_part_imputation
       where act_part_imputation.act_document_id = aACT_DOCUMENT_ID
         and act_part_imputation.pac_custom_partner_id is not null
         and act_part_imputation.pac_supplier_partner_id is not null
         and rownum = 1;
    exception
      when no_data_found then
        aErrorDocument.id  := null;
    end;

    aErrorDocument.BothPart     := aErrorDocument.id is not null;

    begin
      select par.act_part_imputation_id
           , (select per.per_key1
                from pac_person per
               where per.pac_person_id = nvl(par.pac_custom_partner_id, par.pac_supplier_partner_id)) per_key1
        into aErrorDocument.id
           , aErrorDocument.BlockedPerKey
        from pac_supplier_partner sup
           , pac_custom_partner cus
           , act_part_imputation par
       where par.act_document_id = aACT_DOCUMENT_ID
         and cus.pac_custom_partner_id(+) = par.pac_custom_partner_id
         and sup.pac_supplier_partner_id(+) = par.pac_supplier_partner_id
         and (   sup.c_partner_status = 0
              or cus.c_partner_status = 0)
         and rownum = 1;
    exception
      when no_data_found then
        aErrorDocument.id  := null;
    end;

    aErrorDocument.PartBlocked  := aErrorDocument.id is not null;
  end CheckPartner;

------------------------
  procedure CheckExpiries(
    aACT_DOCUMENT_ID in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aErrorDocument   in out ErrorDocumentRecType
  )
  is
    PartImputationId ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    errors           integer;
  begin
    begin
      select act_part_imputation.act_part_imputation_id
        into PartImputationId
        from act_part_imputation
           , acj_catalogue_document
           , act_document
       where act_document.act_document_id = aACT_DOCUMENT_ID
         and act_part_imputation.act_document_id = act_document.act_document_id
         and acj_catalogue_document.acj_catalogue_document_id = act_document.acj_catalogue_document_id
         and acj_catalogue_document.c_type_catalogue in('2', '5', '6')
         and rownum = 1;
    exception
      when no_data_found then
        PartImputationId  := null;
    end;

    if PartImputationId is not null then
      ACT_EXPIRY_MANAGEMENT.ControlExpiriesACT(PartImputationId, errors, aErrorDocument.id);
    else
      aErrorDocument.id  := null;
      errors             := 0;
    end if;

    aErrorDocument.Expiry  := errors > 0;
  end CheckExpiries;

------------------------
  procedure CheckReversal(
    aACT_DOCUMENT_ID in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aErrorDocument   in out ErrorDocumentRecType
  )
  is
    vMatchingTolerance ACJ_CATALOGUE_DOCUMENT.C_MATCHING_TOLERANCE%type;
    PartImputationId   ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    errors             integer;
  begin
    aErrorDocument.id            := null;
    aErrorDocument.primary       := null;
    aErrorDocument.ReversalDate  := false;

    select CAT.C_MATCHING_TOLERANCE
      into vMatchingTolerance
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_DOCUMENT DOC
     where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
       and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;

    for tpl_Reversal in (select PER1.PER_START_DATE PER_START_DATE1
                              , PER2.PER_START_DATE PER_START_DATE2
                              , IMP1.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE1
                              , IMP2.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE2
                              , YEA1.FYE_START_DATE FYE_START_DATE1
                              , YEA2.FYE_START_DATE FYE_START_DATE2
                              , IMP1.ACT_FINANCIAL_IMPUTATION_ID
                              , IMP1.IMF_PRIMARY
                           from ACS_FINANCIAL_YEAR YEA1
                              , ACS_PERIOD PER1
                              , ACT_FINANCIAL_IMPUTATION IMP1
                              , ACS_FINANCIAL_YEAR YEA2
                              , ACS_PERIOD PER2
                              , ACT_FINANCIAL_IMPUTATION IMP2
                              , ACT_DET_PAYMENT DET
                          where DET.ACT2_DET_PAYMENT_ID = IMP2.ACT_DET_PAYMENT_ID
                            and IMP2.ACS_PERIOD_ID = PER2.ACS_PERIOD_ID
                            and IMP2.IMF_ACS_FINANCIAL_YEAR_ID = YEA2.ACS_FINANCIAL_YEAR_ID
                            and DET.ACT_DET_PAYMENT_ID = IMP1.ACT_DET_PAYMENT_ID
                            and IMP1.ACS_PERIOD_ID = PER1.ACS_PERIOD_ID
                            and IMP1.IMF_ACS_FINANCIAL_YEAR_ID = YEA1.ACS_FINANCIAL_YEAR_ID
                            and IMP1.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                            and DET.ACT2_DET_PAYMENT_ID is not null) loop
      if    (     (vMatchingTolerance = '01')
             and (tpl_Reversal.IMF_TRANSACTION_DATE1 < tpl_Reversal.FYE_START_DATE2) )
         or (     (vMatchingTolerance = '02')
             and (tpl_Reversal.IMF_TRANSACTION_DATE1 < tpl_Reversal.PER_START_DATE2) )
         or (     (vMatchingTolerance = '03')
             and (tpl_Reversal.IMF_TRANSACTION_DATE1 < tpl_Reversal.IMF_TRANSACTION_DATE2) ) then
        aErrorDocument.id            := tpl_Reversal.ACT_FINANCIAL_IMPUTATION_ID;
        aErrorDocument.primary       := tpl_Reversal.IMF_PRIMARY;
        aErrorDocument.ReversalDate  := true;
        exit;
      end if;
    end loop;
  end CheckReversal;

------------------------
  procedure CheckDocument(
    aACT_DOCUMENT_ID in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aCheckFinancial  in     boolean
  , aCheckManagement in     boolean
  , aErrorDocument   in out ErrorDocumentRecType
  )
  is
  begin
    CheckImputations(aACT_DOCUMENT_ID, aCheckFinancial, aCheckManagement, aErrorDocument);

    if aErrorDocument.id is null then
      CheckInfoImputations(aACT_DOCUMENT_ID
                         ,     aCheckFinancial
                           and (not aErrorDocument.NoFinImput)
                         ,     aCheckManagement
                           and (not aErrorDocument.NoManImput)
                         , aErrorDocument
                          );
    end if;

    if     aErrorDocument.id is null
       and (    aCheckFinancial
            and (not aErrorDocument.NoFinImput) ) then
      CheckExpiries(aACT_DOCUMENT_ID, aErrorDocument);
    end if;

    if     aErrorDocument.id is null
       and (    aCheckFinancial
            and (not aErrorDocument.NoFinImput) ) then
      CheckReversal(aACT_DOCUMENT_ID, aErrorDocument);
    end if;

    if aErrorDocument.id is null then
      CheckAccounts(aACT_DOCUMENT_ID
                  ,     aCheckFinancial
                    and (not aErrorDocument.NoFinImput)
                  ,     aCheckManagement
                    and (not aErrorDocument.NoManImput)
                  , aErrorDocument
                   );
    end if;

    if     aCheckManagement
       and aErrorDocument.id is null
       and (not aErrorDocument.NoManImput) then
      CheckMANImputPermission(aACT_DOCUMENT_ID, aErrorDocument);
    end if;

    if aErrorDocument.id is null then
      CheckPartner(aACT_DOCUMENT_ID, aErrorDocument);
    end if;
  end CheckDocument;

  ------------------------
/*
  select doc_number
        ,act_document_id
        ,decode(substr(doccheck,1,1), '1',  'ERROR', 'OK') "Exist fin. imp."
        ,decode(substr(doccheck,2,1), '1',  'ERROR', 'OK') "Exist man. imp."
        ,decode(substr(doccheck,3,1), '1',  'ERROR', 'OK') "Fin. imp. parity"
        ,decode(substr(doccheck,4,1), '1',  'ERROR', 'OK') "Man. imp. parity"
        ,decode(substr(doccheck,5,1), '1',  'ERROR', 'OK') "Tot imp man <> imp fin (prim)"
        ,decode(substr(doccheck,6,1), '1',  'ERROR', 'OK') "Tot imp man <> imp fin (sec)"
        ,decode(substr(doccheck,7,1), '1',  'ERROR', 'OK') "Tot imp proj <> imp man (prim)"
        ,decode(substr(doccheck,8,1), '1',  'ERROR', 'OK') "Tot imp proj <> imp man (sec)"
        ,decode(substr(doccheck,9,1), '1',  'ERROR', 'OK') "FC missing for fin. acc."
        ,decode(substr(doccheck,11,1), '1',  'ERROR', 'OK') "Info imp fin (prim)"
        ,decode(substr(doccheck,12,1), '1',  'ERROR', 'OK') "Info imp fin (sec)"
        ,decode(substr(doccheck,13,1), '1',  'ERROR', 'OK') "Info imp man (prim)"
        ,decode(substr(doccheck,14,1), '1',  'ERROR', 'OK') "Info imp man (sec)"
        ,decode(substr(doccheck,15,1), '1',  'ERROR', 'OK') "Info imp proj (prim)"
        ,decode(substr(doccheck,16,1), '1',  'ERROR', 'OK') "Info imp proj (sec)"
        ,doccheck
    from (select act_document_id
                ,doc_number
                ,ACT_DOC_TRANSACTION.CheckDocument(act_document_id
                                                  ,nvl( (select min(CAT1.ACJ_CATALOGUE_DOCUMENT_ID)
                                                           from ACJ_SUB_SET_CAT CAT1
                                                          where CAT1.ACJ_CATALOGUE_DOCUMENT_ID = doc.ACJ_CATALOGUE_DOCUMENT_ID
                                                            and CAT1.C_SUB_SET = 'ACC'), 0)
                                                  ,nvl( (select min(CAT1.ACJ_CATALOGUE_DOCUMENT_ID)
                                                           from ACJ_SUB_SET_CAT CAT1
                                                          where CAT1.ACJ_CATALOGUE_DOCUMENT_ID = doc.ACJ_CATALOGUE_DOCUMENT_ID
                                                            and CAT1.C_SUB_SET = 'CPN'), 0)
                                                  ) doccheck
            from act_document doc)
   where doccheck is not null
*/
  procedure CheckDocument(
    aACT_DOCUMENT_ID in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aCheckFinancial  in     integer
  , aCheckManagement in     integer
  , aErrors          out    varchar2
  , aErrorID         out    ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aErrorPrimary    out    ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY%type
  , aBlockedPerKey   out    PAC_PERSON.PER_KEY1%type
  )
  is
    ErrorDocument ErrorDocumentRecType;

    procedure appendResult(aResult in out varchar2, aFlag in boolean)
    is
    begin
      if aFlag then
        aResult  := aResult || '1';
      else
        aResult  := aResult || '0';
      end if;
    end appendResult;
  begin
    CheckDocument(aACT_DOCUMENT_ID, aCheckFinancial != 0, aCheckManagement != 0, ErrorDocument);
    aErrors        := '';
    appendResult(aErrors, ErrorDocument.NoFinImput); --[1]
    appendResult(aErrors, ErrorDocument.NoManImput); --[2]
    appendResult(aErrors, ErrorDocument.ParityFin);--[3]
    appendResult(aErrors, ErrorDocument.ParityMan);--[4]
    appendResult(aErrors, ErrorDocument.TotFin_Man
                  and (ErrorDocument.primary = 1) );--[5]
    appendResult(aErrors, ErrorDocument.TotFin_Man
                  and (ErrorDocument.primary = 0) );--[6]
    appendResult(aErrors, ErrorDocument.TotMan_Pro
                  and (ErrorDocument.primary = 1) );--[7]
    appendResult(aErrors, ErrorDocument.TotMan_Pro
                  and (ErrorDocument.primary = 0) );--[8]
    appendResult(aErrors, ErrorDocument.FinAccCurr); --[9]
    appendResult(aErrors, ErrorDocument.NoDetPayExp);--[10]
    appendResult(aErrors, ErrorDocument.InfoImpFin
                  and (ErrorDocument.primary = 1) ); --[11]
    appendResult(aErrors, ErrorDocument.InfoImpFin
                  and (ErrorDocument.primary = 0) );--[12]
    appendResult(aErrors, ErrorDocument.InfoImpMan
                  and (ErrorDocument.primary = 1) );--[13]
    appendResult(aErrors, ErrorDocument.InfoImpMan
                  and (ErrorDocument.primary = 0) );--[14]
    appendResult(aErrors, ErrorDocument.InfoImpPro
                  and (ErrorDocument.primary = 1) );--[15]
    appendResult(aErrors, ErrorDocument.InfoImpPro
                  and (ErrorDocument.primary = 0) );--[16]
    appendResult(aErrors, ErrorDocument.CpnPerm
                  and (ErrorDocument.primary = 1) );--[17]
    appendResult(aErrors, ErrorDocument.CpnPerm
                  and (ErrorDocument.primary = 0) );--[18]
    appendResult(aErrors, ErrorDocument.FinAcc
                  and (ErrorDocument.primary = 1) );--[19]
    appendResult(aErrors, ErrorDocument.FinAcc
                  and (ErrorDocument.primary = 0) );--[20]
    appendResult(aErrors, ErrorDocument.DivAcc
                  and (ErrorDocument.primary = 1) );--[21]
    appendResult(aErrors, ErrorDocument.DivAcc
                  and (ErrorDocument.primary = 0) );--[22]
    appendResult(aErrors, ErrorDocument.CpnAcc
                  and (ErrorDocument.primary = 1) );--[23]
    appendResult(aErrors, ErrorDocument.CpnAcc
                  and (ErrorDocument.primary = 0) );--[24]
    appendResult(aErrors, ErrorDocument.CdaAcc
                  and (ErrorDocument.primary = 1) );--[25]
    appendResult(aErrors, ErrorDocument.CdaAcc
                  and (ErrorDocument.primary = 0) );--[26]
    appendResult(aErrors, ErrorDocument.PfAcc
                  and (ErrorDocument.primary = 1) );--[27]
    appendResult(aErrors, ErrorDocument.PfAcc
                  and (ErrorDocument.primary = 0) );--[28]
    appendResult(aErrors, ErrorDocument.PjAcc
                  and (ErrorDocument.primary = 1) );--[29]
    appendResult(aErrors, ErrorDocument.PjAcc
                  and (ErrorDocument.primary = 0) );--[30]
    appendResult(aErrors, ErrorDocument.PartBlocked);--[31]
    appendResult(aErrors, ErrorDocument.MissPartImp);--[32]
    appendResult(aErrors, ErrorDocument.WrongAuxAcc);--[33]
    appendResult(aErrors, ErrorDocument.BothPart);--[34]
    appendResult(aErrors, ErrorDocument.Expiry);--[35]
    appendResult(aErrors, ErrorDocument.AuxAccColl); --[36]
    appendResult(aErrors, ErrorDocument.WrongCpnAcc
                  and (ErrorDocument.primary = 1) );--[37]
    appendResult(aErrors, ErrorDocument.WrongCpnAcc
                  and (ErrorDocument.primary = 0) );--[38]
    appendResult(aErrors, ErrorDocument.ReversalDate);--[39]
    appendResult(aErrors, ErrorDocument.PortfolioCover
                  and (ErrorDocument.primary = 1) );--[40]
    appendResult(aErrors, ErrorDocument.PortfolioCover
                  and (ErrorDocument.primary = 0) );--[41]
    appendResult(aErrors, ErrorDocument.MissManImput
                  and (ErrorDocument.primary = 1) );--[42]
    appendResult(aErrors, ErrorDocument.MissManImput
                  and (ErrorDocument.primary = 0) );--[43]
    appendResult(aErrors, ErrorDocument.MissQtyUnit
                  and (ErrorDocument.primary = 1) );--[44]
    appendResult(aErrors, ErrorDocument.MissQtyUnit
                  and (ErrorDocument.primary = 0) );--[45]
    appendResult(aErrors, ErrorDocument.GalFinProjectMissing);--[46]
    appendResult(aErrors, ErrorDocument.GalMgmProjectMissing);--[47]

    -- Si aucune erreur, retour null
    if to_number(aErrors) = 0 then
      aErrors  := null;
    end if;

    aErrorID       := ErrorDocument.id;
    aErrorPrimary  := ErrorDocument.primary;
    aBlockedPerKey := ErrorDocument.blockedPerKey;
  end CheckDocument;

------------------------
  function CheckDocument(
    aACT_DOCUMENT_ID in ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aCheckFinancial  in integer
  , aCheckManagement in integer
  )
    return varchar2
  is
    ErrorID      ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    ErrorPrimary ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY%type;
    errors       varchar2(60);
    blockedPerKey PAC_PERSON.PER_KEY1%type;
  begin
    CheckDocument(aACT_DOCUMENT_ID, aCheckFinancial, aCheckManagement, errors, ErrorID, ErrorPrimary, blockedPerKey);
    return errors;
  end CheckDocument;

------------------------
  procedure DeleteImputation(
    aACT_FINANCIAL_IMPUTATION_ID   in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aACT_DET_TAX_ID                in ACT_DET_TAX.ACT_DET_TAX_ID%type default null
  , aACT_ACT_FINANCIAL_IMPUTATION  in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type default null
  , aACT2_ACT_FINANCIAL_IMPUTATION in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type default null
  )
  is
    DetTaxId        ACT_DET_TAX.ACT_DET_TAX_ID%type                             := aACT_DET_TAX_ID;
    ActActFinImpId  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type   := aACT_ACT_FINANCIAL_IMPUTATION;
    Act2ActFinImpId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type   := aACT2_ACT_FINANCIAL_IMPUTATION;
  begin
    if    aACT_DET_TAX_ID is null
       or aACT_ACT_FINANCIAL_IMPUTATION is null
       or aACT2_ACT_FINANCIAL_IMPUTATION is null then
      select nvl(aACT_DET_TAX_ID, ACT_DET_TAX_ID)
           , nvl(aACT_ACT_FINANCIAL_IMPUTATION, ACT_ACT_FINANCIAL_IMPUTATION)
           , nvl(aACT2_ACT_FINANCIAL_IMPUTATION, ACT2_ACT_FINANCIAL_IMPUTATION)
        into DetTaxId
           , ActActFinImpId
           , Act2ActFinImpId
        from ACT_DET_TAX
       where ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;
    end if;

    delete from ACT_FINANCIAL_IMPUTATION
          where ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

    if     ActActFinImpId is not null
       and ActActFinImpId != 0 then
      delete from ACT_FINANCIAL_IMPUTATION
            where ACT_FINANCIAL_IMPUTATION_ID = ActActFinImpId;
    end if;

    if     Act2ActFinImpId is not null
       and Act2ActFinImpId != 0 then
      delete from ACT_FINANCIAL_IMPUTATION
            where ACT_FINANCIAL_IMPUTATION_ID = Act2ActFinImpId;
    end if;

    if     DetTaxId is not null
       and DetTaxId != 0 then
      delete from ACT_FINANCIAL_IMPUTATION
            where ACT_FINANCIAL_IMPUTATION_ID in(select ACT_FINANCIAL_IMPUTATION_ID
                                                   from ACT_DET_TAX
                                                  where ACT2_DET_TAX_ID = DetTaxId);
    end if;
  end DeleteImputation;

------------------------
  procedure DeleteZeroImputations(aACT_DOCUMENT_ID in ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
  is
    cursor csrZeroFinImputs(DocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select IMP.ACT_FINANCIAL_IMPUTATION_ID
           , nvl(TAX.ACT_DET_TAX_ID, 0) ACT_DET_TAX_ID
           , nvl(TAX.ACT_ACT_FINANCIAL_IMPUTATION, 0) ACT_ACT_FINANCIAL_IMPUTATION
           , nvl(TAX.ACT2_ACT_FINANCIAL_IMPUTATION, 0) ACT2_ACT_FINANCIAL_IMPUTATION
        from ACT_DET_TAX TAX
           , ACT_FINANCIAL_IMPUTATION IMP
       where IMP.ACT_DOCUMENT_ID = DocumentId
         and TAX.ACT_FINANCIAL_IMPUTATION_ID(+) = IMP.ACT_FINANCIAL_IMPUTATION_ID
         and TAX.ACT2_DET_TAX_ID is null
         and IMP.IMF_PRIMARY = 0
         and IMP.IMF_TYPE != 'VAT'
         and IMP.IMF_AMOUNT_LC_D = 0
         and IMP.IMF_AMOUNT_LC_C = 0;
  begin
    for tplZeroFinImputs in csrZeroFinImputs(aACT_DOCUMENT_ID) loop
      DeleteImputation(tplZeroFinImputs.ACT_FINANCIAL_IMPUTATION_ID
                     , tplZeroFinImputs.ACT_DET_TAX_ID
                     , tplZeroFinImputs.ACT_ACT_FINANCIAL_IMPUTATION
                     , tplZeroFinImputs.ACT2_ACT_FINANCIAL_IMPUTATION
                      );
    end loop;
  end DeleteZeroImputations;

------------------------
  function Compare(aValue1 number, aValue2 number)
    return boolean
  is
  begin
    if     aValue1 is null
       and aValue2 is null then
      return true;
    else
      return(aValue1 = aValue2);
    end if;
  end Compare;

  function Compare(aValue1 varchar2, aValue2 varchar2)
    return boolean
  is
  begin
    if     aValue1 is null
       and aValue2 is null then
      return true;
    else
      return(aValue1 = aValue2);
    end if;
  end Compare;

  function Compare(aValue1 date, aValue2 date)
    return boolean
  is
  begin
    if     aValue1 is null
       and aValue2 is null then
      return true;
    else
      return(aValue1 = aValue2);
    end if;
  end Compare;

------------------------
  procedure GroupDocuments(aACT_JOB_ID in ACT_JOB.ACT_JOB_ID%type)
  is
    cursor csr_doc_fin_imputation(job_id number, catalogue_id number)
    is
      select   nvl(IMF_AMOUNT_LC_D, 0) IMF_AMOUNT_LC_D
             , nvl(IMF_AMOUNT_LC_C, 0) IMF_AMOUNT_LC_C
             , nvl(IMF_AMOUNT_FC_D, 0) IMF_AMOUNT_FC_D
             , nvl(IMF_AMOUNT_FC_C, 0) IMF_AMOUNT_FC_C
             , nvl(IMF_AMOUNT_EUR_D, 0) IMF_AMOUNT_EUR_D
             , nvl(IMF_AMOUNT_EUR_C, 0) IMF_AMOUNT_EUR_C
             , nvl(FIN_AMOUNT_LC_D, 0) FIN_AMOUNT_LC_D
             , nvl(FIN_AMOUNT_LC_C, 0) FIN_AMOUNT_LC_C
             , nvl(FIN_AMOUNT_FC_D, 0) FIN_AMOUNT_FC_D
             , nvl(FIN_AMOUNT_FC_C, 0) FIN_AMOUNT_FC_C
             , nvl(FIN_AMOUNT_EUR_D, 0) FIN_AMOUNT_EUR_D
             , nvl(FIN_AMOUNT_EUR_C, 0) FIN_AMOUNT_EUR_C
             , nvl(IMM_AMOUNT_LC_D, 0) IMM_AMOUNT_LC_D
             , nvl(IMM_AMOUNT_LC_C, 0) IMM_AMOUNT_LC_C
             , nvl(IMM_AMOUNT_FC_D, 0) IMM_AMOUNT_FC_D
             , nvl(IMM_AMOUNT_FC_C, 0) IMM_AMOUNT_FC_C
             , nvl(IMM_AMOUNT_EUR_D, 0) IMM_AMOUNT_EUR_D
             , nvl(IMM_AMOUNT_EUR_C, 0) IMM_AMOUNT_EUR_C
             , nvl(IMM_QUANTITY_D, 0) IMM_QUANTITY_D
             , nvl(IMM_QUANTITY_C, 0) IMM_QUANTITY_C
             , nvl(MGM_AMOUNT_LC_D, 0) MGM_AMOUNT_LC_D
             , nvl(MGM_AMOUNT_LC_C, 0) MGM_AMOUNT_LC_C
             , nvl(MGM_AMOUNT_FC_D, 0) MGM_AMOUNT_FC_D
             , nvl(MGM_AMOUNT_FC_C, 0) MGM_AMOUNT_FC_C
             , nvl(MGM_AMOUNT_EUR_D, 0) MGM_AMOUNT_EUR_D
             , nvl(MGM_AMOUNT_EUR_C, 0) MGM_AMOUNT_EUR_C
             , nvl(MGM_QUANTITY_D, 0) MGM_QUANTITY_D
             , nvl(MGM_QUANTITY_C, 0) MGM_QUANTITY_C
             , ACT_DOCUMENT.DOC_NUMBER
             , ACT_DOCUMENT.ACT_DOCUMENT_ID
             , ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID DOC_FINANCIAL_CURRENCY_ID
             , ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
             , IMF_TYPE
             , IMF_GENRE
             , nvl(IMF_EXCHANGE_RATE, 0) IMF_EXCHANGE_RATE
             , nvl(IMF_BASE_PRICE, 0) IMF_BASE_PRICE
             , IMF_VALUE_DATE
             , IMF_TRANSACTION_DATE
             , ACT_FINANCIAL_DISTRIBUTION.ACS_DIVISION_ACCOUNT_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID
             , C_GENRE_TRANSACTION
             , IMF_NUMBER
             , IMF_NUMBER2
             , IMF_NUMBER3
             , IMF_NUMBER4
             , IMF_NUMBER5
             , IMF_TEXT1
             , IMF_TEXT2
             , IMF_TEXT3
             , IMF_TEXT4
             , IMF_TEXT5
             , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE1_ID
             , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE2_ID
             , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE3_ID
             , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE4_ID
             , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE5_ID
             , ACT_FINANCIAL_IMPUTATION.GCO_GOOD_ID
             , ACT_FINANCIAL_IMPUTATION.DOC_RECORD_ID
             , ACT_FINANCIAL_IMPUTATION.HRM_PERSON_ID
             , ACT_FINANCIAL_IMPUTATION.PAC_PERSON_ID
             , ACT_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID
             , ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP
             , IMM_TYPE
             , IMM_GENRE
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , nvl(IMM_EXCHANGE_RATE, 0) IMM_EXCHANGE_RATE
             , nvl(IMM_BASE_PRICE, 0) IMM_BASE_PRICE
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
             , ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMM_FINANCIAL_CURRENCY_ID
             , ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMM_IMM_FINANCIAL_CURRENCY_ID
             , ACT_MGM_IMPUTATION.ACS_PERIOD_ID IMM_PERIOD_ID
             , IMM_NUMBER
             , IMM_NUMBER2
             , IMM_NUMBER3
             , IMM_NUMBER4
             , IMM_NUMBER5
             , IMM_TEXT1
             , IMM_TEXT2
             , IMM_TEXT3
             , IMM_TEXT4
             , IMM_TEXT5
             , ACT_MGM_IMPUTATION.DIC_IMP_FREE1_ID IMM_DIC_IMP_FREE1_ID
             , ACT_MGM_IMPUTATION.DIC_IMP_FREE2_ID IMM_DIC_IMP_FREE2_ID
             , ACT_MGM_IMPUTATION.DIC_IMP_FREE3_ID IMM_DIC_IMP_FREE3_ID
             , ACT_MGM_IMPUTATION.DIC_IMP_FREE4_ID IMM_DIC_IMP_FREE4_ID
             , ACT_MGM_IMPUTATION.DIC_IMP_FREE5_ID IMM_DIC_IMP_FREE5_ID
             , ACT_MGM_IMPUTATION.GCO_GOOD_ID IMM_GCO_GOOD_ID
             , ACT_MGM_IMPUTATION.DOC_RECORD_ID IMM_DOC_RECORD_ID
             , ACT_MGM_IMPUTATION.HRM_PERSON_ID IMM_HRM_PERSON_ID
             , ACT_MGM_IMPUTATION.PAC_PERSON_ID IMM_PAC_PERSON_ID
             , ACT_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID IMM_FAM_FIXED_ASSETS_ID
             , ACT_MGM_IMPUTATION.C_FAM_TRANSACTION_TYP IMM_C_FAM_TRANSACTION_TYP
             , ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID
             , ACS_PJ_ACCOUNT_ID
             , MGM_NUMBER
             , MGM_NUMBER2
             , MGM_NUMBER3
             , MGM_NUMBER4
             , MGM_NUMBER5
             , MGM_TEXT1
             , MGM_TEXT2
             , MGM_TEXT3
             , MGM_TEXT4
             , MGM_TEXT5
          from ACT_MGM_DISTRIBUTION
             , ACT_MGM_IMPUTATION
             , ACT_FINANCIAL_DISTRIBUTION
             , ACT_FINANCIAL_IMPUTATION
             , ACT_DOCUMENT
         where ACT_DOCUMENT.ACT_JOB_ID = job_id
           and ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = catalogue_id
           and ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = ACT_DOCUMENT.ACT_DOCUMENT_ID
           and ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY = 1
           and ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_IMPUTATION_ID(+) =
                                                                    ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
           and ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID(+) = ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
           and ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID(+) = ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
           and ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID not in(
                                                                    select   ACT_FINANCIAL_IMPUTATION_ID
                                                                        from ACT_MGM_IMPUTATION
                                                                       where ACT_DOCUMENT_ID =
                                                                                            ACT_DOCUMENT.ACT_DOCUMENT_ID
                                                                    group by ACT_FINANCIAL_IMPUTATION_ID
                                                                      having count(*) > 1)
      order by ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID
             , IMF_TYPE
             , IMF_GENRE
             , IMF_EXCHANGE_RATE
             , IMF_BASE_PRICE
             , IMF_VALUE_DATE
             , IMF_TRANSACTION_DATE
             , ACT_FINANCIAL_DISTRIBUTION.ACS_DIVISION_ACCOUNT_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID
             , ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID
             , C_GENRE_TRANSACTION
             , IMF_NUMBER
             , IMF_NUMBER2
             , IMF_NUMBER3
             , IMF_NUMBER4
             , IMF_NUMBER5
             , IMF_TEXT1
             , IMF_TEXT2
             , IMF_TEXT3
             , IMF_TEXT4
             , IMF_TEXT5
             , DIC_IMP_FREE1_ID
             , DIC_IMP_FREE2_ID
             , DIC_IMP_FREE3_ID
             , DIC_IMP_FREE4_ID
             , DIC_IMP_FREE5_ID
             , GCO_GOOD_ID
             , DOC_RECORD_ID
             , HRM_PERSON_ID
             , PAC_PERSON_ID
             , FAM_FIXED_ASSETS_ID
             , C_FAM_TRANSACTION_TYP
             , IMM_TYPE
             , IMM_GENRE
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , IMM_EXCHANGE_RATE
             , IMM_BASE_PRICE
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , IMM_FINANCIAL_CURRENCY_ID
             , IMM_IMM_FINANCIAL_CURRENCY_ID
             , IMM_PERIOD_ID
             , IMM_NUMBER
             , IMM_NUMBER2
             , IMM_NUMBER3
             , IMM_NUMBER4
             , IMM_NUMBER5
             , IMM_TEXT1
             , IMM_TEXT2
             , IMM_TEXT3
             , IMM_TEXT4
             , IMM_TEXT5
             , IMM_DIC_IMP_FREE1_ID
             , IMM_DIC_IMP_FREE2_ID
             , IMM_DIC_IMP_FREE3_ID
             , IMM_DIC_IMP_FREE4_ID
             , IMM_DIC_IMP_FREE5_ID
             , IMM_GCO_GOOD_ID
             , IMM_DOC_RECORD_ID
             , IMM_HRM_PERSON_ID
             , IMM_PAC_PERSON_ID
             , IMM_FAM_FIXED_ASSETS_ID
             , IMM_C_FAM_TRANSACTION_TYP
             , ACS_PJ_ACCOUNT_ID
             , MGM_NUMBER
             , MGM_NUMBER2
             , MGM_NUMBER3
             , MGM_NUMBER4
             , MGM_NUMBER5
             , MGM_TEXT1
             , MGM_TEXT2
             , MGM_TEXT3
             , MGM_TEXT4
             , MGM_TEXT5
             , DOC_NUMBER
             , ACT_DOCUMENT.ACT_DOCUMENT_ID
             , ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
             , ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID;

    tpl_doc_fin_imputation      csr_doc_fin_imputation%rowtype;
    tpl_last_doc_fin_imputation csr_doc_fin_imputation%rowtype;
    imp_count                   integer;
    amount_lc_d                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    amount_lc_c                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    amount_fc_d                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    amount_fc_c                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    amount_eur_d                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    amount_eur_c                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    doc_amount                  ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    doc_amount_eur              ACT_DOCUMENT.DOC_TOTAL_AMOUNT_EUR%type;
    main_document_id            ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    vGroupedHistory             xmltype;

    procedure GetPartImpXmlInfo(pGroupedHistory in out xmltype, pACT_DOCUMENT_ID in ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
    begin
      -- Pour les documents de type 3,4 ,paiement manuel ou automatique
      -- Ajouter à aGroupedHistory les informations pour le document aACT_DOCUMENT_ID
      select   XMLConcat
                 (pGroupedHistory
                , XMLAgg
                    (XMLElement
                             (ACT_DOCUMENT_ID
                            , XMLElement(ACT_DOCUMENT_ID, DOC.ACT_DOCUMENT_ID)
                            , XMLElement(DOC_NUMBER, DOC.DOC_NUMBER)
                            , XMLElement(DOC_DOCUMENT_DATE, DOC.DOC_DOCUMENT_DATE)
                            , XMLElement(DOC_TOTAL_AMOUNT_DC, DOC.DOC_TOTAL_AMOUNT_DC)
                            , case
                                when DOC.DOC_DOCUMENT_ID is not null then XMLElement(DOC_DOCUMENT_ID
                                                                                   , DOC.DOC_DOCUMENT_ID
                                                                                    )
                              end
                            , case
                                when DOC.DMT_NUMBER is not null then XMLElement(DMT_NUMBER, DOC.DMT_NUMBER)
                              end
                            , XMLElement(CURRENCY, DOC.CURRENCY)
                            , XMLElement(ALL_IMPUTATIONS
                                       , XMLAgg(XMLElement(ACT_PART_IMPUTATION
                                                         , XMLElement(ACT_PART_IMPUTATION_ID
                                                                    , DOC.ACT_PART_IMPUTATION_ID)
                                                         , case
                                                             when DOC.PER_NAME is null then null
                                                             else XMLElement(PER_NAME, DOC.PER_NAME)
                                                           end
                                                         , case
                                                             when DOC.PAR_DOCUMENT is null then null
                                                             else XMLElement(PAR_DOCUMENT, DOC.PAR_DOCUMENT)
                                                           end
                                                          ) order by DOC.PAR_DOCUMENT
                                               )
                                        )
                             ) order by DOC.DOC_NUMBER
                    )
                 )
          into pGroupedHistory
          from (select   DOC.ACT_DOCUMENT_ID
                       , DOC.DOC_NUMBER
                       , to_char(DOC.DOC_DOCUMENT_DATE, 'DD.MM.YYYY') DOC_DOCUMENT_DATE
                       , DOC.DOC_TOTAL_AMOUNT_DC
                       , DOC.DOC_DOCUMENT_ID
                       , (select DMT_NUMBER
                            from DOC_DOCUMENT
                           where DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID) DMT_NUMBER
                       , (select CURRENCY
                            from PCS.PC_CURR
                           where PC_CURR_ID = (select PC_CURR_ID
                                                 from ACS_FINANCIAL_CURRENCY
                                                where ACS_FINANCIAL_CURRENCY_ID = DOC.ACS_FINANCIAL_CURRENCY_ID) )
                                                                                                               CURRENCY
                       , PAR.ACT_PART_IMPUTATION_ID
                       , (select PER_NAME
                            from PAC_PERSON PER
                           where PER.PAC_PERSON_ID = nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) )
                                                                                                               PER_NAME
                       , PAR.PAR_DOCUMENT
                    from ACT_PART_IMPUTATION PAR
                       , ACT_DOCUMENT DOC
                   where DOC.ACT_DOCUMENT_ID = pACT_DOCUMENT_ID
                     and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                group by DOC.ACT_DOCUMENT_ID
                       , DOC.DOC_NUMBER
                       , DOC.DOC_DOCUMENT_DATE
                       , DOC.ACS_FINANCIAL_CURRENCY_ID
                       , DOC.DOC_TOTAL_AMOUNT_DC
                       , DOC.DOC_DOCUMENT_ID
                       , PAR.ACT_PART_IMPUTATION_ID
                       , PAR.PAC_CUSTOM_PARTNER_ID
                       , PAR.PAC_SUPPLIER_PARTNER_ID
                       , PAR.PAR_DOCUMENT) DOC
      group by DOC.ACT_PART_IMPUTATION_ID
             , DOC.ACT_DOCUMENT_ID
             , DOC.DOC_NUMBER
             , DOC.DOC_DOCUMENT_DATE
             , DOC.DOC_TOTAL_AMOUNT_DC
             , DOC.DOC_DOCUMENT_ID
             , DOC.DMT_NUMBER
             , DOC.CURRENCY;
    end GetPartImpXmlInfo;
  begin
    -- recherche des différents catalogues
    vGroupedHistory  := null;

    for tpl_catalogue in (select distinct cat.ACJ_CATALOGUE_DOCUMENT_ID
                                        , cat.C_TYPE_CATALOGUE
                                     from ACJ_CATALOGUE_DOCUMENT cat
                                        , ACT_DOCUMENT doc
                                    where cat.ACJ_CATALOGUE_DOCUMENT_ID = doc.ACJ_CATALOGUE_DOCUMENT_ID
                                      and doc.ACT_JOB_ID = aACT_JOB_ID
                                      and cat.C_TYPE_CATALOGUE in('1', '3', '4')
                                 order by cat.C_TYPE_CATALOGUE
                                        , cat.ACJ_CATALOGUE_DOCUMENT_ID) loop
      if tpl_catalogue.C_TYPE_CATALOGUE = '1' then
        -- recherche du document et de l'écriture primaire principale
        select min(doc.ACT_DOCUMENT_ID)
          into main_document_id
          from ACT_DOCUMENT doc
         where doc.ACT_JOB_ID = aACT_JOB_ID
           and doc.ACJ_CATALOGUE_DOCUMENT_ID = tpl_catalogue.ACJ_CATALOGUE_DOCUMENT_ID
           and doc.DOC_NUMBER =
                 (select min(DOC_NUMBER)
                    from ACT_DOCUMENT
                   where ACT_JOB_ID = aACT_JOB_ID
                     and ACJ_CATALOGUE_DOCUMENT_ID = tpl_catalogue.ACJ_CATALOGUE_DOCUMENT_ID);

        -- si pas de document possédant un numéro
        if main_document_id is null then
          select min(doc.ACT_DOCUMENT_ID)
            into main_document_id
            from ACT_DOCUMENT doc
           where doc.ACT_JOB_ID = aACT_JOB_ID
             and doc.ACJ_CATALOGUE_DOCUMENT_ID = tpl_catalogue.ACJ_CATALOGUE_DOCUMENT_ID;
        end if;

        -- Conserver l'historique des documents regroupés (écriture financière)
        -- concaténer le résultat avec les autres documents déjà regroupés
        select XMLConcat
                      (vGroupedHistory
                     , XMLAgg(XMLElement(ACT_DOCUMENT_ID
                                       , XMLElement(ACT_DOCUMENT_ID, DOC.ACT_DOCUMENT_ID)
                                       , XMLElement(DOC_NUMBER, DOC.DOC_NUMBER)
                                       , XMLElement(DOC_DOCUMENT_DATE, DOC.DOC_DOCUMENT_DATE)
                                       , XMLElement(CURRENCY, DOC.CURRENCY)
                                       , XMLElement(DOC_TOTAL_AMOUNT_DC, DOC.DOC_TOTAL_AMOUNT_DC)
                                       , case
                                           when DOC.DOC_DOCUMENT_ID is not null then XMLElement(DOC_DOCUMENT_ID
                                                                                              , DOC.DOC_DOCUMENT_ID
                                                                                               )
                                         end
                                       , case
                                           when DOC.DMT_NUMBER is not null then XMLElement(DMT_NUMBER, DOC.DMT_NUMBER)
                                         end
                                        )
                             )
                      )
          into vGroupedHistory
          from (select   DOC.ACT_DOCUMENT_ID
                       , DOC.DOC_NUMBER
                       , to_char(DOC.DOC_DOCUMENT_DATE, 'DD.MM.YYYY') DOC_DOCUMENT_DATE
                       , (select CURRENCY
                            from PCS.PC_CURR
                           where PC_CURR_ID = (select PC_CURR_ID
                                                 from ACS_FINANCIAL_CURRENCY
                                                where ACS_FINANCIAL_CURRENCY_ID = DOC.ACS_FINANCIAL_CURRENCY_ID) )
                                                                                                               CURRENCY
                       , DOC.DOC_TOTAL_AMOUNT_DC
                       , DOC.DOC_DOCUMENT_ID
                       , (select DMT_NUMBER
                            from DOC_DOCUMENT
                           where DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID) DMT_NUMBER
                    from ACT_DOCUMENT DOC
                   where DOC.ACT_JOB_ID = aACT_JOB_ID
                     and DOC.ACJ_CATALOGUE_DOCUMENT_ID = tpl_catalogue.ACJ_CATALOGUE_DOCUMENT_ID
                order by DOC.DOC_NUMBER) DOC;

        --Mise à jour des infos XML de regroupement
        if vGroupedHistory is not null then
          --Ne remplir que s'il existe quelque chose
          select XMLElement(DOC_GRPDOCS_JOB, vGroupedHistory)
            into vGroupedHistory
            from dual;

          update ACT_DOCUMENT
             set DOC_XML_INFO = pc_jutils.get_XMLPrologDefault || chr(10) || vGroupedHistory.GetClobVal()
           where ACT_DOCUMENT_ID = main_document_id;
        end if;

        for tpl_document in (select DOC.ACT_DOCUMENT_ID
                                  , DOC.DOC_NUMBER
                                  , DOC.DOC_DOCUMENT_DATE
                                  , DOC.DOC_TOTAL_AMOUNT_DC
                                  , (select CURRENCY
                                       from PCS.PC_CURR
                                      where PC_CURR_ID =
                                                       (select ACS_FINANCIAL_CURRENCY_ID
                                                          from ACS_FINANCIAL_CURRENCY
                                                         where ACS_FINANCIAL_CURRENCY_ID = DOC.ACS_FINANCIAL_CURRENCY_ID) )
                                                                                                               CURRENCY
                               from ACT_DOCUMENT DOC
                              where DOC.ACT_JOB_ID = aACT_JOB_ID
                                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = tpl_catalogue.ACJ_CATALOGUE_DOCUMENT_ID
                                and DOC.ACT_DOCUMENT_ID != main_document_id) loop
          -- déplacement imputations financières
          update ACT_FINANCIAL_IMPUTATION
             set ACT_DOCUMENT_ID = main_document_id
               , IMF_PRIMARY = 0
           where ACT_DOCUMENT_ID = tpl_document.ACT_DOCUMENT_ID;

          -- déplacement imputations analytiques
          update ACT_MGM_IMPUTATION
             set ACT_DOCUMENT_ID = main_document_id
               , IMM_PRIMARY = 0
           where ACT_DOCUMENT_ID = tpl_document.ACT_DOCUMENT_ID;

          -- effacement de l'en-tête de l'ancien document (numéro libre géré par trigger)
          delete from ACT_DOCUMENT
                where ACT_DOCUMENT_ID = tpl_document.ACT_DOCUMENT_ID;
        end loop;
      else
        open csr_doc_fin_imputation(aACT_JOB_ID, tpl_catalogue.ACJ_CATALOGUE_DOCUMENT_ID);

        fetch csr_doc_fin_imputation
         into tpl_doc_fin_imputation;

        tpl_last_doc_fin_imputation  := null;
        imp_count                    := 1;

        while csr_doc_fin_imputation%found
          or imp_count > 1 loop
          if     csr_doc_fin_imputation%found
             and Compare(tpl_doc_fin_imputation.DOC_FINANCIAL_CURRENCY_ID
                       , tpl_last_doc_fin_imputation.DOC_FINANCIAL_CURRENCY_ID
                        )
             and Compare(tpl_doc_fin_imputation.IMF_TYPE, tpl_last_doc_fin_imputation.IMF_TYPE)
             and Compare(tpl_doc_fin_imputation.IMF_GENRE, tpl_last_doc_fin_imputation.IMF_GENRE)
             and Compare(tpl_doc_fin_imputation.IMF_EXCHANGE_RATE, tpl_last_doc_fin_imputation.IMF_EXCHANGE_RATE)
             and Compare(tpl_doc_fin_imputation.IMF_BASE_PRICE, tpl_last_doc_fin_imputation.IMF_BASE_PRICE)
             and Compare(tpl_doc_fin_imputation.IMF_TRANSACTION_DATE, tpl_last_doc_fin_imputation.IMF_TRANSACTION_DATE)
             and Compare(tpl_doc_fin_imputation.IMF_VALUE_DATE, tpl_last_doc_fin_imputation.IMF_VALUE_DATE)
             and Compare(tpl_doc_fin_imputation.ACS_DIVISION_ACCOUNT_ID
                       , tpl_last_doc_fin_imputation.ACS_DIVISION_ACCOUNT_ID
                        )
             and Compare(tpl_doc_fin_imputation.ACS_FINANCIAL_CURRENCY_ID
                       , tpl_last_doc_fin_imputation.ACS_FINANCIAL_CURRENCY_ID
                        )
             and Compare(tpl_doc_fin_imputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                       , tpl_last_doc_fin_imputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                        )
             and Compare(tpl_doc_fin_imputation.ACS_FINANCIAL_ACCOUNT_ID
                       , tpl_last_doc_fin_imputation.ACS_FINANCIAL_ACCOUNT_ID
                        )
             and Compare(tpl_doc_fin_imputation.ACS_AUXILIARY_ACCOUNT_ID
                       , tpl_last_doc_fin_imputation.ACS_AUXILIARY_ACCOUNT_ID
                        )
             and Compare(tpl_doc_fin_imputation.ACS_PERIOD_ID, tpl_last_doc_fin_imputation.ACS_PERIOD_ID)
             and Compare(tpl_doc_fin_imputation.C_GENRE_TRANSACTION, tpl_last_doc_fin_imputation.C_GENRE_TRANSACTION)
             and Compare(tpl_doc_fin_imputation.IMF_NUMBER, tpl_last_doc_fin_imputation.IMF_NUMBER)
             and Compare(tpl_doc_fin_imputation.IMF_NUMBER2, tpl_last_doc_fin_imputation.IMF_NUMBER2)
             and Compare(tpl_doc_fin_imputation.IMF_NUMBER3, tpl_last_doc_fin_imputation.IMF_NUMBER3)
             and Compare(tpl_doc_fin_imputation.IMF_NUMBER4, tpl_last_doc_fin_imputation.IMF_NUMBER4)
             and Compare(tpl_doc_fin_imputation.IMF_NUMBER5, tpl_last_doc_fin_imputation.IMF_NUMBER5)
             and Compare(tpl_doc_fin_imputation.IMF_TEXT1, tpl_last_doc_fin_imputation.IMF_TEXT1)
             and Compare(tpl_doc_fin_imputation.IMF_TEXT2, tpl_last_doc_fin_imputation.IMF_TEXT2)
             and Compare(tpl_doc_fin_imputation.IMF_TEXT3, tpl_last_doc_fin_imputation.IMF_TEXT3)
             and Compare(tpl_doc_fin_imputation.IMF_TEXT4, tpl_last_doc_fin_imputation.IMF_TEXT4)
             and Compare(tpl_doc_fin_imputation.IMF_TEXT5, tpl_last_doc_fin_imputation.IMF_TEXT5)
             and Compare(tpl_doc_fin_imputation.DIC_IMP_FREE1_ID, tpl_last_doc_fin_imputation.DIC_IMP_FREE1_ID)
             and Compare(tpl_doc_fin_imputation.DIC_IMP_FREE2_ID, tpl_last_doc_fin_imputation.DIC_IMP_FREE2_ID)
             and Compare(tpl_doc_fin_imputation.DIC_IMP_FREE3_ID, tpl_last_doc_fin_imputation.DIC_IMP_FREE3_ID)
             and Compare(tpl_doc_fin_imputation.DIC_IMP_FREE4_ID, tpl_last_doc_fin_imputation.DIC_IMP_FREE4_ID)
             and Compare(tpl_doc_fin_imputation.DIC_IMP_FREE5_ID, tpl_last_doc_fin_imputation.DIC_IMP_FREE5_ID)
             and Compare(tpl_doc_fin_imputation.GCO_GOOD_ID, tpl_last_doc_fin_imputation.GCO_GOOD_ID)
             and Compare(tpl_doc_fin_imputation.DOC_RECORD_ID, tpl_last_doc_fin_imputation.DOC_RECORD_ID)
             and Compare(tpl_doc_fin_imputation.HRM_PERSON_ID, tpl_last_doc_fin_imputation.HRM_PERSON_ID)
             and Compare(tpl_doc_fin_imputation.PAC_PERSON_ID, tpl_last_doc_fin_imputation.PAC_PERSON_ID)
             and Compare(tpl_doc_fin_imputation.FAM_FIXED_ASSETS_ID, tpl_last_doc_fin_imputation.FAM_FIXED_ASSETS_ID)
             and Compare(tpl_doc_fin_imputation.C_FAM_TRANSACTION_TYP
                       , tpl_last_doc_fin_imputation.C_FAM_TRANSACTION_TYP)
             and Compare(tpl_doc_fin_imputation.ACS_CPN_ACCOUNT_ID, tpl_last_doc_fin_imputation.ACS_CPN_ACCOUNT_ID)
             and Compare(tpl_doc_fin_imputation.ACS_PF_ACCOUNT_ID, tpl_last_doc_fin_imputation.ACS_PF_ACCOUNT_ID)
             and Compare(tpl_doc_fin_imputation.ACS_CDA_ACCOUNT_ID, tpl_last_doc_fin_imputation.ACS_CDA_ACCOUNT_ID)
             and Compare(tpl_doc_fin_imputation.ACS_QTY_UNIT_ID, tpl_last_doc_fin_imputation.ACS_QTY_UNIT_ID)
             and Compare(tpl_doc_fin_imputation.IMM_TYPE, tpl_last_doc_fin_imputation.IMM_TYPE)
             and Compare(tpl_doc_fin_imputation.IMM_GENRE, tpl_last_doc_fin_imputation.IMM_GENRE)
             and Compare(tpl_doc_fin_imputation.IMM_EXCHANGE_RATE, tpl_last_doc_fin_imputation.IMM_EXCHANGE_RATE)
             and Compare(tpl_doc_fin_imputation.IMM_BASE_PRICE, tpl_last_doc_fin_imputation.IMM_BASE_PRICE)
             and Compare(tpl_doc_fin_imputation.IMM_TRANSACTION_DATE, tpl_last_doc_fin_imputation.IMM_TRANSACTION_DATE)
             and Compare(tpl_doc_fin_imputation.IMM_VALUE_DATE, tpl_last_doc_fin_imputation.IMM_VALUE_DATE)
             and Compare(tpl_doc_fin_imputation.IMM_FINANCIAL_CURRENCY_ID
                       , tpl_last_doc_fin_imputation.IMM_FINANCIAL_CURRENCY_ID
                        )
             and Compare(tpl_doc_fin_imputation.IMM_IMM_FINANCIAL_CURRENCY_ID
                       , tpl_last_doc_fin_imputation.IMM_IMM_FINANCIAL_CURRENCY_ID
                        )
             and Compare(tpl_doc_fin_imputation.IMM_PERIOD_ID, tpl_last_doc_fin_imputation.IMM_PERIOD_ID)
             and Compare(tpl_doc_fin_imputation.IMM_NUMBER, tpl_last_doc_fin_imputation.IMM_NUMBER)
             and Compare(tpl_doc_fin_imputation.IMM_NUMBER2, tpl_last_doc_fin_imputation.IMM_NUMBER2)
             and Compare(tpl_doc_fin_imputation.IMM_NUMBER3, tpl_last_doc_fin_imputation.IMM_NUMBER3)
             and Compare(tpl_doc_fin_imputation.IMM_NUMBER4, tpl_last_doc_fin_imputation.IMM_NUMBER4)
             and Compare(tpl_doc_fin_imputation.IMM_NUMBER5, tpl_last_doc_fin_imputation.IMM_NUMBER5)
             and Compare(tpl_doc_fin_imputation.IMM_TEXT1, tpl_last_doc_fin_imputation.IMM_TEXT1)
             and Compare(tpl_doc_fin_imputation.IMM_TEXT2, tpl_last_doc_fin_imputation.IMM_TEXT2)
             and Compare(tpl_doc_fin_imputation.IMM_TEXT3, tpl_last_doc_fin_imputation.IMM_TEXT3)
             and Compare(tpl_doc_fin_imputation.IMM_TEXT4, tpl_last_doc_fin_imputation.IMM_TEXT4)
             and Compare(tpl_doc_fin_imputation.IMM_TEXT5, tpl_last_doc_fin_imputation.IMM_TEXT5)
             and Compare(tpl_doc_fin_imputation.IMM_DIC_IMP_FREE1_ID, tpl_last_doc_fin_imputation.IMM_DIC_IMP_FREE1_ID)
             and Compare(tpl_doc_fin_imputation.IMM_DIC_IMP_FREE2_ID, tpl_last_doc_fin_imputation.IMM_DIC_IMP_FREE2_ID)
             and Compare(tpl_doc_fin_imputation.IMM_DIC_IMP_FREE3_ID, tpl_last_doc_fin_imputation.IMM_DIC_IMP_FREE3_ID)
             and Compare(tpl_doc_fin_imputation.IMM_DIC_IMP_FREE4_ID, tpl_last_doc_fin_imputation.IMM_DIC_IMP_FREE4_ID)
             and Compare(tpl_doc_fin_imputation.IMM_DIC_IMP_FREE5_ID, tpl_last_doc_fin_imputation.IMM_DIC_IMP_FREE5_ID)
             and Compare(tpl_doc_fin_imputation.IMM_GCO_GOOD_ID, tpl_last_doc_fin_imputation.IMM_GCO_GOOD_ID)
             and Compare(tpl_doc_fin_imputation.IMM_DOC_RECORD_ID, tpl_last_doc_fin_imputation.IMM_DOC_RECORD_ID)
             and Compare(tpl_doc_fin_imputation.IMM_HRM_PERSON_ID, tpl_last_doc_fin_imputation.IMM_HRM_PERSON_ID)
             and Compare(tpl_doc_fin_imputation.IMM_PAC_PERSON_ID, tpl_last_doc_fin_imputation.IMM_PAC_PERSON_ID)
             and Compare(tpl_doc_fin_imputation.IMM_FAM_FIXED_ASSETS_ID
                       , tpl_last_doc_fin_imputation.IMM_FAM_FIXED_ASSETS_ID
                        )
             and Compare(tpl_doc_fin_imputation.IMM_C_FAM_TRANSACTION_TYP
                       , tpl_last_doc_fin_imputation.IMM_C_FAM_TRANSACTION_TYP
                        )
             and Compare(tpl_doc_fin_imputation.ACS_PJ_ACCOUNT_ID, tpl_last_doc_fin_imputation.ACS_PJ_ACCOUNT_ID)
             and Compare(tpl_doc_fin_imputation.MGM_NUMBER, tpl_last_doc_fin_imputation.MGM_NUMBER)
             and Compare(tpl_doc_fin_imputation.MGM_NUMBER2, tpl_last_doc_fin_imputation.MGM_NUMBER2)
             and Compare(tpl_doc_fin_imputation.MGM_NUMBER3, tpl_last_doc_fin_imputation.MGM_NUMBER3)
             and Compare(tpl_doc_fin_imputation.MGM_NUMBER4, tpl_last_doc_fin_imputation.MGM_NUMBER4)
             and Compare(tpl_doc_fin_imputation.MGM_NUMBER5, tpl_last_doc_fin_imputation.MGM_NUMBER5)
             and Compare(tpl_doc_fin_imputation.MGM_TEXT1, tpl_last_doc_fin_imputation.MGM_TEXT1)
             and Compare(tpl_doc_fin_imputation.MGM_TEXT2, tpl_last_doc_fin_imputation.MGM_TEXT2)
             and Compare(tpl_doc_fin_imputation.MGM_TEXT3, tpl_last_doc_fin_imputation.MGM_TEXT3)
             and Compare(tpl_doc_fin_imputation.MGM_TEXT4, tpl_last_doc_fin_imputation.MGM_TEXT4)
             and Compare(tpl_doc_fin_imputation.MGM_TEXT5, tpl_last_doc_fin_imputation.MGM_TEXT5) then
            -- cumul des montants
            tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_D   :=
                                   tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_D + tpl_doc_fin_imputation.IMF_AMOUNT_LC_D;
            tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_C   :=
                                   tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_C + tpl_doc_fin_imputation.IMF_AMOUNT_LC_C;
            tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_D   :=
                                   tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_D + tpl_doc_fin_imputation.IMF_AMOUNT_FC_D;
            tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_C   :=
                                   tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_C + tpl_doc_fin_imputation.IMF_AMOUNT_FC_C;
            tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_D  :=
                                 tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_D + tpl_doc_fin_imputation.IMF_AMOUNT_EUR_D;
            tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_C  :=
                                 tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_C + tpl_doc_fin_imputation.IMF_AMOUNT_EUR_C;
            tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_D   :=
                                   tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_D + tpl_doc_fin_imputation.FIN_AMOUNT_LC_D;
            tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_C   :=
                                   tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_C + tpl_doc_fin_imputation.FIN_AMOUNT_LC_C;
            tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_D   :=
                                   tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_D + tpl_doc_fin_imputation.FIN_AMOUNT_FC_D;
            tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_C   :=
                                   tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_C + tpl_doc_fin_imputation.FIN_AMOUNT_FC_C;
            tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_D  :=
                                 tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_D + tpl_doc_fin_imputation.FIN_AMOUNT_EUR_D;
            tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_C  :=
                                 tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_C + tpl_doc_fin_imputation.FIN_AMOUNT_EUR_C;
            tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_D   :=
                                   tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_D + tpl_doc_fin_imputation.IMM_AMOUNT_LC_D;
            tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_C   :=
                                   tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_C + tpl_doc_fin_imputation.IMM_AMOUNT_LC_C;
            tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_D   :=
                                   tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_D + tpl_doc_fin_imputation.IMM_AMOUNT_FC_D;
            tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_C   :=
                                   tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_C + tpl_doc_fin_imputation.IMM_AMOUNT_FC_C;
            tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_D  :=
                                 tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_D + tpl_doc_fin_imputation.IMM_AMOUNT_EUR_D;
            tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_C  :=
                                 tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_C + tpl_doc_fin_imputation.IMM_AMOUNT_EUR_C;
            tpl_last_doc_fin_imputation.IMM_QUANTITY_D    :=
                                     tpl_last_doc_fin_imputation.IMM_QUANTITY_D + tpl_doc_fin_imputation.IMM_QUANTITY_D;
            tpl_last_doc_fin_imputation.IMM_QUANTITY_C    :=
                                     tpl_last_doc_fin_imputation.IMM_QUANTITY_C + tpl_doc_fin_imputation.IMM_QUANTITY_C;
            tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_D   :=
                                   tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_D + tpl_doc_fin_imputation.MGM_AMOUNT_LC_D;
            tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_C   :=
                                   tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_C + tpl_doc_fin_imputation.MGM_AMOUNT_LC_C;
            tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_D   :=
                                   tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_D + tpl_doc_fin_imputation.MGM_AMOUNT_FC_D;
            tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_C   :=
                                   tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_C + tpl_doc_fin_imputation.MGM_AMOUNT_FC_C;
            tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_D  :=
                                 tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_D + tpl_doc_fin_imputation.MGM_AMOUNT_EUR_D;
            tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_C  :=
                                 tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_C + tpl_doc_fin_imputation.MGM_AMOUNT_EUR_C;
            tpl_last_doc_fin_imputation.MGM_QUANTITY_D    :=
                                     tpl_last_doc_fin_imputation.MGM_QUANTITY_D + tpl_doc_fin_imputation.MGM_QUANTITY_D;
            tpl_last_doc_fin_imputation.MGM_QUANTITY_C    :=
                                     tpl_last_doc_fin_imputation.MGM_QUANTITY_C + tpl_doc_fin_imputation.MGM_QUANTITY_C;
            imp_count                                     := imp_count + 1;
            -- Garder l'historique de regroupement
            -- concaténer le résultat avec les autres documents déjà regroupés
            GetPartImpXmlInfo(vGroupedHistory, tpl_doc_fin_imputation.ACT_DOCUMENT_ID);

            --Effacement de l'imputation primaire
            delete from ACT_FINANCIAL_IMPUTATION
                  where ACT_FINANCIAL_IMPUTATION_ID = tpl_doc_fin_imputation.ACT_FINANCIAL_IMPUTATION_ID;

            -- déplacement imputations financières
            update ACT_FINANCIAL_IMPUTATION
               set ACT_DOCUMENT_ID = tpl_last_doc_fin_imputation.ACT_DOCUMENT_ID
             where ACT_DOCUMENT_ID = tpl_doc_fin_imputation.ACT_DOCUMENT_ID;

            -- déplacement imputations analytiques
            update ACT_MGM_IMPUTATION
               set ACT_DOCUMENT_ID = tpl_last_doc_fin_imputation.ACT_DOCUMENT_ID
             where ACT_DOCUMENT_ID = tpl_doc_fin_imputation.ACT_DOCUMENT_ID;

            -- déplacement imputations partenaire
            update ACT_PART_IMPUTATION
               set ACT_DOCUMENT_ID = tpl_last_doc_fin_imputation.ACT_DOCUMENT_ID
             where ACT_DOCUMENT_ID = tpl_doc_fin_imputation.ACT_DOCUMENT_ID;

            -- déplacement détails paiements
            update ACT_DET_PAYMENT
               set ACT_DOCUMENT_ID = tpl_last_doc_fin_imputation.ACT_DOCUMENT_ID
             where ACT_DOCUMENT_ID = tpl_doc_fin_imputation.ACT_DOCUMENT_ID;

            -- déplacement échéances
            update ACT_EXPIRY
               set ACT_DOCUMENT_ID = tpl_last_doc_fin_imputation.ACT_DOCUMENT_ID
             where ACT_DOCUMENT_ID = tpl_doc_fin_imputation.ACT_DOCUMENT_ID;

            -- effacement de l'en-tête de l'ancien document (numéro libre géré par trigger)
            delete from ACT_DOCUMENT
                  where ACT_DOCUMENT_ID = tpl_doc_fin_imputation.ACT_DOCUMENT_ID;
          else
            --Màj de l'écriture financière + distribution
            if imp_count > 1 then
              -- Recherche si les montants sont débit ou crédit
              select decode(sign(tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_D -
                                 tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_C
                                )
                          , 1, tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_D - tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_C
                          , 0
                           )
                into amount_lc_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_D -
                                 tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_D -
                                    tpl_last_doc_fin_imputation.IMF_AMOUNT_LC_C
                                   )
                          , 0
                           )
                into amount_lc_c
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_D -
                                 tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_C
                                )
                          , 1, tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_D - tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_C
                          , 0
                           )
                into amount_fc_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_D -
                                 tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_D -
                                    tpl_last_doc_fin_imputation.IMF_AMOUNT_FC_C
                                   )
                          , 0
                           )
                into amount_fc_c
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_D -
                                 tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_C
                                )
                          , 1, tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_D
                             - tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_C
                          , 0
                           )
                into amount_eur_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_D -
                                 tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_D -
                                    tpl_last_doc_fin_imputation.IMF_AMOUNT_EUR_C
                                   )
                          , 0
                           )
                into amount_eur_c
                from dual;

              -- màj de l'écriture financière
              update ACT_FINANCIAL_IMPUTATION
                 set IMF_AMOUNT_LC_D = amount_lc_d
                   , IMF_AMOUNT_LC_C = amount_lc_c
                   , IMF_AMOUNT_FC_D = amount_fc_d
                   , IMF_AMOUNT_FC_C = amount_fc_c
                   , IMF_AMOUNT_EUR_D = amount_eur_d
                   , IMF_AMOUNT_EUR_C = amount_eur_c
               where ACT_FINANCIAL_IMPUTATION_ID = tpl_last_doc_fin_imputation.ACT_FINANCIAL_IMPUTATION_ID;

              -- Màj montant document
              if tpl_last_doc_fin_imputation.DOC_FINANCIAL_CURRENCY_ID =
                                                               tpl_last_doc_fin_imputation.ACS_ACS_FINANCIAL_CURRENCY_ID then
                if amount_lc_d != 0 then
                  doc_amount      := amount_lc_d;
                  doc_amount_eur  := amount_eur_d;
                else
                  doc_amount      := amount_lc_c;
                  doc_amount_eur  := amount_eur_c;
                end if;
              elsif tpl_last_doc_fin_imputation.DOC_FINANCIAL_CURRENCY_ID =
                                                                   tpl_last_doc_fin_imputation.ACS_FINANCIAL_CURRENCY_ID then
                if amount_lc_d != 0 then
                  doc_amount      := amount_fc_d;
                  doc_amount_eur  := amount_eur_d;
                else
                  doc_amount      := amount_fc_c;
                  doc_amount_eur  := amount_eur_c;
                end if;
              end if;

              --Mise à jour des infos XML de regroupement
              if vGroupedHistory is not null then
                --Ne remplir que s'il existe quelque chose
                select XMLElement(DOC_GRPDOCS_JOB, vGroupedHistory)
                  into vGroupedHistory
                  from dual;

                update ACT_DOCUMENT
                   set DOC_XML_INFO = pc_jutils.get_XMLPrologDefault || chr(10) || vGroupedHistory.GetClobVal()
                 where ACT_DOCUMENT_ID = tpl_last_doc_fin_imputation.ACT_DOCUMENT_ID;
              end if;

              update ACT_DOCUMENT
                 set DOC_TOTAL_AMOUNT_DC = doc_amount
                   , DOC_TOTAL_AMOUNT_EUR = doc_amount_eur
               where ACT_DOCUMENT_ID = tpl_last_doc_fin_imputation.ACT_DOCUMENT_ID;

              -- Recherche si les montants sont débit ou crédit
              select decode(sign(tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_D -
                                 tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_C
                                )
                          , 1, tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_D - tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_C
                          , 0
                           )
                into amount_lc_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_D -
                                 tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_D -
                                    tpl_last_doc_fin_imputation.FIN_AMOUNT_LC_C
                                   )
                          , 0
                           )
                into amount_lc_c
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_D -
                                 tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_C
                                )
                          , 1, tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_D - tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_C
                          , 0
                           )
                into amount_fc_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_D -
                                 tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_D -
                                    tpl_last_doc_fin_imputation.FIN_AMOUNT_FC_C
                                   )
                          , 0
                           )
                into amount_fc_c
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_D -
                                 tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_C
                                )
                          , 1, tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_D
                             - tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_C
                          , 0
                           )
                into amount_eur_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_D -
                                 tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_D -
                                    tpl_last_doc_fin_imputation.FIN_AMOUNT_EUR_C
                                   )
                          , 0
                           )
                into amount_eur_c
                from dual;

              -- màj de la distribution
              update ACT_FINANCIAL_DISTRIBUTION
                 set FIN_AMOUNT_LC_D = amount_lc_d
                   , FIN_AMOUNT_LC_C = amount_lc_c
                   , FIN_AMOUNT_FC_D = amount_fc_d
                   , FIN_AMOUNT_FC_C = amount_fc_c
                   , FIN_AMOUNT_EUR_D = amount_eur_d
                   , FIN_AMOUNT_EUR_C = amount_eur_c
               where ACT_FINANCIAL_IMPUTATION_ID = tpl_last_doc_fin_imputation.ACT_FINANCIAL_IMPUTATION_ID;

              -- Recherche si les montants sont débit ou crédit
              select decode(sign(tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_D -
                                 tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_C
                                )
                          , 1, tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_D - tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_C
                          , 0
                           )
                into amount_lc_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_D -
                                 tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_D -
                                    tpl_last_doc_fin_imputation.IMM_AMOUNT_LC_C
                                   )
                          , 0
                           )
                into amount_lc_c
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_D -
                                 tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_C
                                )
                          , 1, tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_D - tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_C
                          , 0
                           )
                into amount_fc_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_D -
                                 tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_D -
                                    tpl_last_doc_fin_imputation.IMM_AMOUNT_FC_C
                                   )
                          , 0
                           )
                into amount_fc_c
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_D -
                                 tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_C
                                )
                          , 1, tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_D
                             - tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_C
                          , 0
                           )
                into amount_eur_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_D -
                                 tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_D -
                                    tpl_last_doc_fin_imputation.IMM_AMOUNT_EUR_C
                                   )
                          , 0
                           )
                into amount_eur_c
                from dual;

              -- màj de l'écriture analytique
              update ACT_MGM_IMPUTATION
                 set IMM_AMOUNT_LC_D = amount_lc_d
                   , IMM_AMOUNT_LC_C = amount_lc_c
                   , IMM_AMOUNT_FC_D = amount_fc_d
                   , IMM_AMOUNT_FC_C = amount_fc_c
                   , IMM_AMOUNT_EUR_D = amount_eur_d
                   , IMM_AMOUNT_EUR_C = amount_eur_c
                   , IMM_QUANTITY_D = tpl_last_doc_fin_imputation.IMM_QUANTITY_D
                   , IMM_QUANTITY_C = tpl_last_doc_fin_imputation.IMM_QUANTITY_C
               where ACT_MGM_IMPUTATION_ID = tpl_last_doc_fin_imputation.ACT_MGM_IMPUTATION_ID;

              -- Recherche si les montants sont débit ou crédit
              select decode(sign(tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_D -
                                 tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_C
                                )
                          , 1, tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_D - tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_C
                          , 0
                           )
                into amount_lc_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_D -
                                 tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_D -
                                    tpl_last_doc_fin_imputation.MGM_AMOUNT_LC_C
                                   )
                          , 0
                           )
                into amount_lc_c
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_D -
                                 tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_C
                                )
                          , 1, tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_D - tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_C
                          , 0
                           )
                into amount_fc_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_D -
                                 tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_D -
                                    tpl_last_doc_fin_imputation.MGM_AMOUNT_FC_C
                                   )
                          , 0
                           )
                into amount_fc_c
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_D -
                                 tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_C
                                )
                          , 1, tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_D
                             - tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_C
                          , 0
                           )
                into amount_eur_d
                from dual;

              select decode(sign(tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_D -
                                 tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_C
                                )
                          , -1, abs(tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_D -
                                    tpl_last_doc_fin_imputation.MGM_AMOUNT_EUR_C
                                   )
                          , 0
                           )
                into amount_eur_c
                from dual;

              -- màj de l'écriture analytique
              update ACT_MGM_DISTRIBUTION
                 set MGM_AMOUNT_LC_D = amount_lc_d
                   , MGM_AMOUNT_LC_C = amount_lc_c
                   , MGM_AMOUNT_FC_D = amount_fc_d
                   , MGM_AMOUNT_FC_C = amount_fc_c
                   , MGM_AMOUNT_EUR_D = amount_eur_d
                   , MGM_AMOUNT_EUR_C = amount_eur_c
                   , MGM_QUANTITY_D = tpl_last_doc_fin_imputation.MGM_QUANTITY_D
                   , MGM_QUANTITY_C = tpl_last_doc_fin_imputation.MGM_QUANTITY_C
               where ACT_MGM_DISTRIBUTION_ID = tpl_last_doc_fin_imputation.ACT_MGM_DISTRIBUTION_ID;
            else   -- premier document du curseur, le garder dans l'XML
              GetPartImpXmlInfo(vGroupedHistory, tpl_doc_fin_imputation.ACT_DOCUMENT_ID);
            end if;

            tpl_last_doc_fin_imputation  := tpl_doc_fin_imputation;
            imp_count                    := 1;
          end if;

          fetch csr_doc_fin_imputation
           into tpl_doc_fin_imputation;
        end loop;

        close csr_doc_fin_imputation;
      end if;
    end loop;

    --Mise à jour du nombre de documents pour le travail
    update ACT_JOB
       set JOB_DOCUMENTS = (select count(1)
                              from ACT_DOCUMENT
                             where ACT_JOB_ID = aACT_JOB_ID)
     where ACT_JOB_ID = aACT_JOB_ID;
  end GroupDocuments;

  procedure GroupImputations(aACT_JOB_ID in ACT_JOB.ACT_JOB_ID%type)
  is
    cursor csr_fin_imputation(document_id number, main_prim_imp_id number)
    is
      select   *
          from (select nvl(IMF_AMOUNT_LC_D, 0) IMF_AMOUNT_LC_D
                     , nvl(IMF_AMOUNT_LC_C, 0) IMF_AMOUNT_LC_C
                     , nvl(IMF_AMOUNT_FC_D, 0) IMF_AMOUNT_FC_D
                     , nvl(IMF_AMOUNT_FC_C, 0) IMF_AMOUNT_FC_C
                     , nvl(IMF_AMOUNT_EUR_D, 0) IMF_AMOUNT_EUR_D
                     , nvl(IMF_AMOUNT_EUR_C, 0) IMF_AMOUNT_EUR_C
                     , nvl(TAX_LIABLED_AMOUNT, 0) TAX_LIABLED_AMOUNT
                     , nvl(TAX_VAT_AMOUNT_FC, 0) TAX_VAT_AMOUNT_FC
                     , nvl(TAX_VAT_AMOUNT_LC, 0) TAX_VAT_AMOUNT_LC
                     , nvl(TAX_VAT_AMOUNT_EUR, 0) TAX_VAT_AMOUNT_EUR
                     , nvl(TAX_TOT_VAT_AMOUNT_FC, 0) TAX_TOT_VAT_AMOUNT_FC
                     , nvl(TAX_TOT_VAT_AMOUNT_LC, 0) TAX_TOT_VAT_AMOUNT_LC
                     , nvl(TAX_TOT_VAT_AMOUNT_EUR, 0) TAX_TOT_VAT_AMOUNT_EUR
                     , nvl(FIN_AMOUNT_LC_D, 0) FIN_AMOUNT_LC_D
                     , nvl(FIN_AMOUNT_LC_C, 0) FIN_AMOUNT_LC_C
                     , nvl(FIN_AMOUNT_FC_D, 0) FIN_AMOUNT_FC_D
                     , nvl(FIN_AMOUNT_FC_C, 0) FIN_AMOUNT_FC_C
                     , nvl(FIN_AMOUNT_EUR_D, 0) FIN_AMOUNT_EUR_D
                     , nvl(FIN_AMOUNT_EUR_C, 0) FIN_AMOUNT_EUR_C
                     , nvl(IMM_AMOUNT_LC_D, 0) IMM_AMOUNT_LC_D
                     , nvl(IMM_AMOUNT_LC_C, 0) IMM_AMOUNT_LC_C
                     , nvl(IMM_AMOUNT_FC_D, 0) IMM_AMOUNT_FC_D
                     , nvl(IMM_AMOUNT_FC_C, 0) IMM_AMOUNT_FC_C
                     , nvl(IMM_AMOUNT_EUR_D, 0) IMM_AMOUNT_EUR_D
                     , nvl(IMM_AMOUNT_EUR_C, 0) IMM_AMOUNT_EUR_C
                     , nvl(IMM_QUANTITY_D, 0) IMM_QUANTITY_D
                     , nvl(IMM_QUANTITY_C, 0) IMM_QUANTITY_C
                     , nvl(MGM_AMOUNT_LC_D, 0) MGM_AMOUNT_LC_D
                     , nvl(MGM_AMOUNT_LC_C, 0) MGM_AMOUNT_LC_C
                     , nvl(MGM_AMOUNT_FC_D, 0) MGM_AMOUNT_FC_D
                     , nvl(MGM_AMOUNT_FC_C, 0) MGM_AMOUNT_FC_C
                     , nvl(MGM_AMOUNT_EUR_D, 0) MGM_AMOUNT_EUR_D
                     , nvl(MGM_AMOUNT_EUR_C, 0) MGM_AMOUNT_EUR_C
                     , nvl(MGM_QUANTITY_D, 0) MGM_QUANTITY_D
                     , nvl(MGM_QUANTITY_C, 0) MGM_QUANTITY_C
                     , ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
                     , ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_DISTRIBUTION_ID
                     , ACT_DET_TAX.ACT_DET_TAX_ID
                     , ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
                     , ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID
                     , IMF_TYPE
                     , IMF_GENRE
                     , nvl(IMF_EXCHANGE_RATE, 0) IMF_EXCHANGE_RATE
                     , nvl(IMF_BASE_PRICE, 0) IMF_BASE_PRICE
                     , IMF_VALUE_DATE
                     , IMF_TRANSACTION_DATE
                     , nvl(TAX_EXCHANGE_RATE, 0) TAX_EXCHANGE_RATE
                     , nvl(DET_BASE_PRICE, 0) DET_BASE_PRICE
                     , TAX_INCLUDED_EXCLUDED
                     , TAX_LIABLED_RATE
                     , TAX_RATE
                     , TAX_REDUCTION
                     , TAX_DEDUCTIBLE_RATE
                     , ACS_DIVISION_ACCOUNT_ID
                     , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
                     , ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_AUXILIARY_ACCOUNT_ID
                     , ACS_TAX_CODE_ID
                     , ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID
                     , C_GENRE_TRANSACTION
                     , IMF_NUMBER
                     , IMF_NUMBER2
                     , IMF_NUMBER3
                     , IMF_NUMBER4
                     , IMF_NUMBER5
                     , IMF_TEXT1
                     , IMF_TEXT2
                     , IMF_TEXT3
                     , IMF_TEXT4
                     , IMF_TEXT5
                     , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE1_ID
                     , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE2_ID
                     , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE3_ID
                     , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE4_ID
                     , ACT_FINANCIAL_IMPUTATION.DIC_IMP_FREE5_ID
                     , ACT_FINANCIAL_IMPUTATION.GCO_GOOD_ID
                     , ACT_FINANCIAL_IMPUTATION.DOC_RECORD_ID
                     , ACT_FINANCIAL_IMPUTATION.HRM_PERSON_ID
                     , ACT_FINANCIAL_IMPUTATION.PAC_PERSON_ID
                     , ACT_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID
                     , ACT_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP
                     , ACT_DET_TAX.ACT_ACT_FINANCIAL_IMPUTATION
                     , IMM_TYPE
                     , IMM_GENRE
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_QTY_UNIT_ID
                     , nvl(IMM_EXCHANGE_RATE, 0) IMM_EXCHANGE_RATE
                     , nvl(IMM_BASE_PRICE, 0) IMM_BASE_PRICE
                     , IMM_VALUE_DATE
                     , IMM_TRANSACTION_DATE
                     , ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMM_FINANCIAL_CURRENCY_ID
                     , ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMM_IMM_FINANCIAL_CURRENCY_ID
                     , ACT_MGM_IMPUTATION.ACS_PERIOD_ID IMM_PERIOD_ID
                     , IMM_NUMBER
                     , IMM_NUMBER2
                     , IMM_NUMBER3
                     , IMM_NUMBER4
                     , IMM_NUMBER5
                     , IMM_TEXT1
                     , IMM_TEXT2
                     , IMM_TEXT3
                     , IMM_TEXT4
                     , IMM_TEXT5
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE1_ID IMM_DIC_IMP_FREE1_ID
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE2_ID IMM_DIC_IMP_FREE2_ID
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE3_ID IMM_DIC_IMP_FREE3_ID
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE4_ID IMM_DIC_IMP_FREE4_ID
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE5_ID IMM_DIC_IMP_FREE5_ID
                     , ACT_MGM_IMPUTATION.GCO_GOOD_ID IMM_GCO_GOOD_ID
                     , ACT_MGM_IMPUTATION.DOC_RECORD_ID IMM_DOC_RECORD_ID
                     , ACT_MGM_IMPUTATION.HRM_PERSON_ID IMM_HRM_PERSON_ID
                     , ACT_MGM_IMPUTATION.PAC_PERSON_ID IMM_PAC_PERSON_ID
                     , ACT_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID IMM_FAM_FIXED_ASSETS_ID
                     , ACT_MGM_IMPUTATION.C_FAM_TRANSACTION_TYP IMM_C_FAM_TRANSACTION_TYP
                     , ACS_PJ_ACCOUNT_ID
                     , MGM_NUMBER
                     , MGM_NUMBER2
                     , MGM_NUMBER3
                     , MGM_NUMBER4
                     , MGM_NUMBER5
                     , MGM_TEXT1
                     , MGM_TEXT2
                     , MGM_TEXT3
                     , MGM_TEXT4
                     , MGM_TEXT5
                  from ACT_MGM_DISTRIBUTION
                     , ACT_MGM_IMPUTATION
                     , ACT_DET_TAX
                     , ACT_FINANCIAL_DISTRIBUTION
                     , ACT_FINANCIAL_IMPUTATION
                 where ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = document_id
                   and ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID != main_prim_imp_id
                   and ACT_FINANCIAL_IMPUTATION.IMF_TYPE != 'VAT'
                   and ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_IMPUTATION_ID(+) =
                                                                    ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
                   and ACT_DET_TAX.ACT_FINANCIAL_IMPUTATION_ID(+) = ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
                   and (   ACT_DET_TAX.ACT_FINANCIAL_IMPUTATION_ID is null
                        or (    ACT_DET_TAX.ACT2_DET_TAX_ID is null
                            and ACT_DET_TAX.TAX_INCLUDED_EXCLUDED = 'E')
                       )
                   and ACT_DET_TAX.ACT_DED1_FINANCIAL_IMP_ID is null
                   and not exists(
                         select 0
                           from ACT_DET_TAX TAX2
                          where TAX2.ACT_DED1_FINANCIAL_IMP_ID = ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
                             or TAX2.ACT_DED2_FINANCIAL_IMP_ID = ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID)
                   and ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID(+) =
                                                                    ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
                   and ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID(+) = ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
                   and ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID not in(select   ACT_FINANCIAL_IMPUTATION_ID
                                                                                       from ACT_MGM_IMPUTATION
                                                                                      where ACT_DOCUMENT_ID =
                                                                                                             document_id
                                                                                   group by ACT_FINANCIAL_IMPUTATION_ID
                                                                                     having count(*) > 1)
                union
                select 0 IMF_AMOUNT_LC_D
                     , 0 IMF_AMOUNT_LC_C
                     , 0 IMF_AMOUNT_FC_D
                     , 0 IMF_AMOUNT_FC_C
                     , 0 IMF_AMOUNT_EUR_D
                     , 0 IMF_AMOUNT_EUR_C
                     , 0 TAX_LIABLED_AMOUNT
                     , 0 TAX_VAT_AMOUNT_FC
                     , 0 TAX_VAT_AMOUNT_LC
                     , 0 TAX_VAT_AMOUNT_EUR
                     , 0 TAX_TOT_VAT_AMOUNT_FC
                     , 0 TAX_TOT_VAT_AMOUNT_LC
                     , 0 TAX_TOT_VAT_AMOUNT_EUR
                     , 0 FIN_AMOUNT_LC_D
                     , 0 FIN_AMOUNT_LC_C
                     , 0 FIN_AMOUNT_FC_D
                     , 0 FIN_AMOUNT_FC_C
                     , 0 FIN_AMOUNT_EUR_D
                     , 0 FIN_AMOUNT_EUR_C
                     , nvl(IMM_AMOUNT_LC_D, 0) IMM_AMOUNT_LC_D
                     , nvl(IMM_AMOUNT_LC_C, 0) IMM_AMOUNT_LC_C
                     , nvl(IMM_AMOUNT_FC_D, 0) IMM_AMOUNT_FC_D
                     , nvl(IMM_AMOUNT_FC_C, 0) IMM_AMOUNT_FC_C
                     , nvl(IMM_AMOUNT_EUR_D, 0) IMM_AMOUNT_EUR_D
                     , nvl(IMM_AMOUNT_EUR_C, 0) IMM_AMOUNT_EUR_C
                     , nvl(IMM_QUANTITY_D, 0) IMM_QUANTITY_D
                     , nvl(IMM_QUANTITY_C, 0) IMM_QUANTITY_C
                     , nvl(MGM_AMOUNT_LC_D, 0) MGM_AMOUNT_LC_D
                     , nvl(MGM_AMOUNT_LC_C, 0) MGM_AMOUNT_LC_C
                     , nvl(MGM_AMOUNT_FC_D, 0) MGM_AMOUNT_FC_D
                     , nvl(MGM_AMOUNT_FC_C, 0) MGM_AMOUNT_FC_C
                     , nvl(MGM_AMOUNT_EUR_D, 0) MGM_AMOUNT_EUR_D
                     , nvl(MGM_AMOUNT_EUR_C, 0) MGM_AMOUNT_EUR_C
                     , nvl(MGM_QUANTITY_D, 0) MGM_QUANTITY_D
                     , nvl(MGM_QUANTITY_C, 0) MGM_QUANTITY_C
                     , null ACT_FINANCIAL_IMPUTATION_ID
                     , null ACT_FINANCIAL_DISTRIBUTION_ID
                     , null ACT_DET_TAX_ID
                     , ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
                     , ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID
                     , null IMF_TYPE
                     , null IMF_GENRE
                     , null IMF_EXCHANGE_RATE
                     , null IMF_BASE_PRICE
                     , null IMF_VALUE_DATE
                     , null IMF_TRANSACTION_DATE
                     , null TAX_EXCHANGE_RATE
                     , null DET_BASE_PRICE
                     , null TAX_INCLUDED_EXCLUDED
                     , null TAX_LIABLED_RATE
                     , null TAX_RATE
                     , null TAX_REDUCTION
                     , null TAX_DEDUCTIBLE_RATE
                     , null ACS_DIVISION_ACCOUNT_ID
                     , null ACS_FINANCIAL_CURRENCY_ID
                     , null ACS_ACS_FINANCIAL_CURRENCY_ID
                     , null ACS_FINANCIAL_ACCOUNT_ID
                     , null ACS_AUXILIARY_ACCOUNT_ID
                     , null ACS_TAX_CODE_ID
                     , null ACS_PERIOD_ID
                     , null C_GENRE_TRANSACTION
                     , null IMF_NUMBER
                     , null IMF_NUMBER2
                     , null IMF_NUMBER3
                     , null IMF_NUMBER4
                     , null IMF_NUMBER5
                     , null IMF_TEXT1
                     , null IMF_TEXT2
                     , null IMF_TEXT3
                     , null IMF_TEXT4
                     , null IMF_TEXT5
                     , null DIC_IMP_FREE1_ID
                     , null DIC_IMP_FREE2_ID
                     , null DIC_IMP_FREE3_ID
                     , null DIC_IMP_FREE4_ID
                     , null DIC_IMP_FREE5_ID
                     , null GCO_GOOD_ID
                     , null DOC_RECORD_ID
                     , null HRM_PERSON_ID
                     , null PAC_PERSON_ID
                     , null FAM_FIXED_ASSETS_ID
                     , null C_FAM_TRANSACTION_TYP
                     , null ACT_ACT_FINANCIAL_IMPUTATION
                     , IMM_TYPE
                     , IMM_GENRE
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_QTY_UNIT_ID
                     , nvl(IMM_EXCHANGE_RATE, 0) IMM_EXCHANGE_RATE
                     , nvl(IMM_BASE_PRICE, 0) IMM_BASE_PRICE
                     , IMM_VALUE_DATE
                     , IMM_TRANSACTION_DATE
                     , ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMM_FINANCIAL_CURRENCY_ID
                     , ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMM_IMM_FINANCIAL_CURRENCY_ID
                     , ACT_MGM_IMPUTATION.ACS_PERIOD_ID IMM_PERIOD_ID
                     , IMM_NUMBER
                     , IMM_NUMBER2
                     , IMM_NUMBER3
                     , IMM_NUMBER4
                     , IMM_NUMBER5
                     , IMM_TEXT1
                     , IMM_TEXT2
                     , IMM_TEXT3
                     , IMM_TEXT4
                     , IMM_TEXT5
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE1_ID IMM_DIC_IMP_FREE1_ID
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE2_ID IMM_DIC_IMP_FREE2_ID
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE3_ID IMM_DIC_IMP_FREE3_ID
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE4_ID IMM_DIC_IMP_FREE4_ID
                     , ACT_MGM_IMPUTATION.DIC_IMP_FREE5_ID IMM_DIC_IMP_FREE5_ID
                     , ACT_MGM_IMPUTATION.GCO_GOOD_ID IMM_GCO_GOOD_ID
                     , ACT_MGM_IMPUTATION.DOC_RECORD_ID IMM_DOC_RECORD_ID
                     , ACT_MGM_IMPUTATION.HRM_PERSON_ID IMM_HRM_PERSON_ID
                     , ACT_MGM_IMPUTATION.PAC_PERSON_ID IMM_PAC_PERSON_ID
                     , ACT_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID IMM_FAM_FIXED_ASSETS_ID
                     , ACT_MGM_IMPUTATION.C_FAM_TRANSACTION_TYP IMM_C_FAM_TRANSACTION_TYP
                     , ACS_PJ_ACCOUNT_ID
                     , MGM_NUMBER
                     , MGM_NUMBER2
                     , MGM_NUMBER3
                     , MGM_NUMBER4
                     , MGM_NUMBER5
                     , MGM_TEXT1
                     , MGM_TEXT2
                     , MGM_TEXT3
                     , MGM_TEXT4
                     , MGM_TEXT5
                  from ACT_MGM_DISTRIBUTION
                     , ACT_MGM_IMPUTATION
                 where ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID = document_id
                   and ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID is null
                   and ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID != main_prim_imp_id
                   and ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID(+) = ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID
                   and ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID not in(
                         select   ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID
                             from ACT_MGM_DISTRIBUTION
                                , ACT_MGM_IMPUTATION
                            where ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID = document_id
                              and ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID = ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID
                         group by ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID
                           having count(*) > 1) )
      order by IMF_TYPE
             , IMF_GENRE
             , IMF_EXCHANGE_RATE
             , IMF_BASE_PRICE
             , IMF_VALUE_DATE
             , IMF_TRANSACTION_DATE
             , TAX_EXCHANGE_RATE
             , DET_BASE_PRICE
             , TAX_INCLUDED_EXCLUDED
             , TAX_LIABLED_RATE
             , TAX_RATE
             , TAX_REDUCTION
             , TAX_DEDUCTIBLE_RATE
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_AUXILIARY_ACCOUNT_ID
             , ACS_TAX_CODE_ID
             , ACS_PERIOD_ID
             , C_GENRE_TRANSACTION
             , IMF_NUMBER
             , IMF_NUMBER2
             , IMF_NUMBER3
             , IMF_NUMBER4
             , IMF_NUMBER5
             , IMF_TEXT1
             , IMF_TEXT2
             , IMF_TEXT3
             , IMF_TEXT4
             , IMF_TEXT5
             , DIC_IMP_FREE1_ID
             , DIC_IMP_FREE2_ID
             , DIC_IMP_FREE3_ID
             , DIC_IMP_FREE4_ID
             , DIC_IMP_FREE5_ID
             , GCO_GOOD_ID
             , DOC_RECORD_ID
             , HRM_PERSON_ID
             , PAC_PERSON_ID
             , FAM_FIXED_ASSETS_ID
             , C_FAM_TRANSACTION_TYP
             , IMM_TYPE
             , IMM_GENRE
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , IMM_EXCHANGE_RATE
             , IMM_BASE_PRICE
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , IMM_FINANCIAL_CURRENCY_ID
             , IMM_IMM_FINANCIAL_CURRENCY_ID
             , IMM_PERIOD_ID
             , IMM_NUMBER
             , IMM_NUMBER2
             , IMM_NUMBER3
             , IMM_NUMBER4
             , IMM_NUMBER5
             , IMM_TEXT1
             , IMM_TEXT2
             , IMM_TEXT3
             , IMM_TEXT4
             , IMM_TEXT5
             , IMM_DIC_IMP_FREE1_ID
             , IMM_DIC_IMP_FREE2_ID
             , IMM_DIC_IMP_FREE3_ID
             , IMM_DIC_IMP_FREE4_ID
             , IMM_DIC_IMP_FREE5_ID
             , IMM_GCO_GOOD_ID
             , IMM_DOC_RECORD_ID
             , IMM_HRM_PERSON_ID
             , IMM_PAC_PERSON_ID
             , IMM_FAM_FIXED_ASSETS_ID
             , IMM_C_FAM_TRANSACTION_TYP
             , ACS_PJ_ACCOUNT_ID
             , MGM_NUMBER
             , MGM_NUMBER2
             , MGM_NUMBER3
             , MGM_NUMBER4
             , MGM_NUMBER5
             , MGM_TEXT1
             , MGM_TEXT2
             , MGM_TEXT3
             , MGM_TEXT4
             , MGM_TEXT5
             , ACT_ACT_FINANCIAL_IMPUTATION nulls last
             , ACT_FINANCIAL_IMPUTATION_ID
             , ACT_MGM_IMPUTATION_ID
             , ACT_MGM_DISTRIBUTION_ID;

    tpl_fin_imputation      csr_fin_imputation%rowtype;
    tpl_last_fin_imputation csr_fin_imputation%rowtype;
    imp_count               integer;
    man_only                boolean;
    main_prim_imp_id        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
--    chk_multi ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    amount_lc_d             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    amount_lc_c             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    amount_fc_d             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    amount_fc_c             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    amount_eur_d            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    amount_eur_c            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
  begin
    -- recherche des différents documents
    for tpl_document in (select   cat.ACJ_CATALOGUE_DOCUMENT_ID
                                , doc.ACT_DOCUMENT_ID
                             from ACJ_CATALOGUE_DOCUMENT cat
                                , ACT_DOCUMENT doc
                            where cat.ACJ_CATALOGUE_DOCUMENT_ID = doc.ACJ_CATALOGUE_DOCUMENT_ID
                              and doc.ACT_JOB_ID = aACT_JOB_ID
                              and cat.C_TYPE_CATALOGUE = '1'
                         order by cat.ACJ_CATALOGUE_DOCUMENT_ID) loop
 /*
      -- contrôle si lien finance -> analytique est bien 1 -> 1
      select min(ACT_FINANCIAL_IMPUTATION_ID)
        into chk_multi
        from (select   ACT_FINANCIAL_IMPUTATION_ID
                  from ACT_MGM_IMPUTATION
                where ACT_DOCUMENT_ID = tpl_document.ACT_DOCUMENT_ID
              group by ACT_FINANCIAL_IMPUTATION_ID
                having count(*) > 1);
      if chk_multi is null then
        select min(ACT_MGM_IMPUTATION_ID)
          into chk_multi
          from (select   ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID
                    from ACT_MGM_DISTRIBUTION
                      , ACT_MGM_IMPUTATION
                  where ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID = tpl_document.ACT_DOCUMENT_ID
                    and ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID = ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID
                group by ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID
                  having count(*) > 1);
      end if;
*/
--      if chk_multi is null then
      select max(ACT_FINANCIAL_IMPUTATION_ID)
        into main_prim_imp_id
        from ACT_FINANCIAL_IMPUTATION imp
       where imp.ACT_DOCUMENT_ID = tpl_document.ACT_DOCUMENT_ID;

      man_only                 :=(main_prim_imp_id is null);

      if not man_only then
        -- recherche du document et de l'écriture primaire principale
        select max(imp.ACT_FINANCIAL_IMPUTATION_ID)
          into main_prim_imp_id
          from ACT_FINANCIAL_IMPUTATION imp
         where imp.ACT_DOCUMENT_ID = tpl_document.ACT_DOCUMENT_ID
           and imp.IMF_PRIMARY = 1;
      else
        -- recherche du document et de l'écriture primaire principale
        select max(imp.ACT_MGM_IMPUTATION_ID)
          into main_prim_imp_id
          from ACT_MGM_IMPUTATION imp
         where imp.ACT_DOCUMENT_ID = tpl_document.ACT_DOCUMENT_ID
           and imp.IMM_PRIMARY = 1;
      end if;

      -- imputations financières
      open csr_fin_imputation(tpl_document.ACT_DOCUMENT_ID, main_prim_imp_id);

      fetch csr_fin_imputation
       into tpl_fin_imputation;

      tpl_last_fin_imputation  := null;
      imp_count                := 1;

      while csr_fin_imputation%found
        or imp_count > 1 loop
        if     csr_fin_imputation%found
           and Compare(tpl_fin_imputation.IMF_TYPE, tpl_last_fin_imputation.IMF_TYPE)
           and Compare(tpl_fin_imputation.IMF_GENRE, tpl_last_fin_imputation.IMF_GENRE)
           and Compare(tpl_fin_imputation.IMF_EXCHANGE_RATE, tpl_last_fin_imputation.IMF_EXCHANGE_RATE)
           and Compare(tpl_fin_imputation.IMF_BASE_PRICE, tpl_last_fin_imputation.IMF_BASE_PRICE)
           and Compare(tpl_fin_imputation.IMF_TRANSACTION_DATE, tpl_last_fin_imputation.IMF_TRANSACTION_DATE)
           and Compare(tpl_fin_imputation.IMF_VALUE_DATE, tpl_last_fin_imputation.IMF_VALUE_DATE)
           and Compare(tpl_fin_imputation.TAX_EXCHANGE_RATE, tpl_last_fin_imputation.TAX_EXCHANGE_RATE)
           and Compare(tpl_fin_imputation.DET_BASE_PRICE, tpl_last_fin_imputation.DET_BASE_PRICE)
           and Compare(tpl_fin_imputation.TAX_INCLUDED_EXCLUDED, tpl_last_fin_imputation.TAX_INCLUDED_EXCLUDED)
           and Compare(tpl_fin_imputation.TAX_LIABLED_RATE, tpl_last_fin_imputation.TAX_LIABLED_RATE)
           and Compare(tpl_fin_imputation.TAX_REDUCTION, tpl_last_fin_imputation.TAX_REDUCTION)
           and Compare(tpl_fin_imputation.TAX_DEDUCTIBLE_RATE, tpl_last_fin_imputation.TAX_DEDUCTIBLE_RATE)
           and Compare(tpl_fin_imputation.ACS_DIVISION_ACCOUNT_ID, tpl_last_fin_imputation.ACS_DIVISION_ACCOUNT_ID)
           and Compare(tpl_fin_imputation.ACS_FINANCIAL_CURRENCY_ID, tpl_last_fin_imputation.ACS_FINANCIAL_CURRENCY_ID)
           and Compare(tpl_fin_imputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , tpl_last_fin_imputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                      )
           and Compare(tpl_fin_imputation.ACS_FINANCIAL_ACCOUNT_ID, tpl_last_fin_imputation.ACS_FINANCIAL_ACCOUNT_ID)
           and Compare(tpl_fin_imputation.ACS_AUXILIARY_ACCOUNT_ID, tpl_last_fin_imputation.ACS_AUXILIARY_ACCOUNT_ID)
           and Compare(tpl_fin_imputation.ACS_TAX_CODE_ID, tpl_last_fin_imputation.ACS_TAX_CODE_ID)
           and Compare(tpl_fin_imputation.ACS_PERIOD_ID, tpl_last_fin_imputation.ACS_PERIOD_ID)
           and Compare(tpl_fin_imputation.C_GENRE_TRANSACTION, tpl_last_fin_imputation.C_GENRE_TRANSACTION)
           and Compare(tpl_fin_imputation.IMF_NUMBER, tpl_last_fin_imputation.IMF_NUMBER)
           and Compare(tpl_fin_imputation.IMF_NUMBER2, tpl_last_fin_imputation.IMF_NUMBER2)
           and Compare(tpl_fin_imputation.IMF_NUMBER3, tpl_last_fin_imputation.IMF_NUMBER3)
           and Compare(tpl_fin_imputation.IMF_NUMBER4, tpl_last_fin_imputation.IMF_NUMBER4)
           and Compare(tpl_fin_imputation.IMF_NUMBER5, tpl_last_fin_imputation.IMF_NUMBER5)
           and Compare(tpl_fin_imputation.IMF_TEXT1, tpl_last_fin_imputation.IMF_TEXT1)
           and Compare(tpl_fin_imputation.IMF_TEXT2, tpl_last_fin_imputation.IMF_TEXT2)
           and Compare(tpl_fin_imputation.IMF_TEXT3, tpl_last_fin_imputation.IMF_TEXT3)
           and Compare(tpl_fin_imputation.IMF_TEXT4, tpl_last_fin_imputation.IMF_TEXT4)
           and Compare(tpl_fin_imputation.IMF_TEXT5, tpl_last_fin_imputation.IMF_TEXT5)
           and Compare(tpl_fin_imputation.DIC_IMP_FREE1_ID, tpl_last_fin_imputation.DIC_IMP_FREE1_ID)
           and Compare(tpl_fin_imputation.DIC_IMP_FREE2_ID, tpl_last_fin_imputation.DIC_IMP_FREE2_ID)
           and Compare(tpl_fin_imputation.DIC_IMP_FREE3_ID, tpl_last_fin_imputation.DIC_IMP_FREE3_ID)
           and Compare(tpl_fin_imputation.DIC_IMP_FREE4_ID, tpl_last_fin_imputation.DIC_IMP_FREE4_ID)
           and Compare(tpl_fin_imputation.DIC_IMP_FREE5_ID, tpl_last_fin_imputation.DIC_IMP_FREE5_ID)
           and Compare(tpl_fin_imputation.GCO_GOOD_ID, tpl_last_fin_imputation.GCO_GOOD_ID)
           and Compare(tpl_fin_imputation.DOC_RECORD_ID, tpl_last_fin_imputation.DOC_RECORD_ID)
           and Compare(tpl_fin_imputation.HRM_PERSON_ID, tpl_last_fin_imputation.HRM_PERSON_ID)
           and Compare(tpl_fin_imputation.PAC_PERSON_ID, tpl_last_fin_imputation.PAC_PERSON_ID)
           and Compare(tpl_fin_imputation.FAM_FIXED_ASSETS_ID, tpl_last_fin_imputation.FAM_FIXED_ASSETS_ID)
           and Compare(tpl_fin_imputation.C_FAM_TRANSACTION_TYP, tpl_last_fin_imputation.C_FAM_TRANSACTION_TYP)
           and Compare(tpl_fin_imputation.ACS_CPN_ACCOUNT_ID, tpl_last_fin_imputation.ACS_CPN_ACCOUNT_ID)
           and Compare(tpl_fin_imputation.ACS_PF_ACCOUNT_ID, tpl_last_fin_imputation.ACS_PF_ACCOUNT_ID)
           and Compare(tpl_fin_imputation.ACS_CDA_ACCOUNT_ID, tpl_last_fin_imputation.ACS_CDA_ACCOUNT_ID)
           and Compare(tpl_fin_imputation.ACS_QTY_UNIT_ID, tpl_last_fin_imputation.ACS_QTY_UNIT_ID)
           and Compare(tpl_fin_imputation.IMM_TYPE, tpl_last_fin_imputation.IMM_TYPE)
           and Compare(tpl_fin_imputation.IMM_GENRE, tpl_last_fin_imputation.IMM_GENRE)
           and Compare(tpl_fin_imputation.IMM_EXCHANGE_RATE, tpl_last_fin_imputation.IMM_EXCHANGE_RATE)
           and Compare(tpl_fin_imputation.IMM_BASE_PRICE, tpl_last_fin_imputation.IMM_BASE_PRICE)
           and Compare(tpl_fin_imputation.IMM_TRANSACTION_DATE, tpl_last_fin_imputation.IMM_TRANSACTION_DATE)
           and Compare(tpl_fin_imputation.IMM_VALUE_DATE, tpl_last_fin_imputation.IMM_VALUE_DATE)
           and Compare(tpl_fin_imputation.IMM_FINANCIAL_CURRENCY_ID, tpl_last_fin_imputation.IMM_FINANCIAL_CURRENCY_ID)
           and Compare(tpl_fin_imputation.IMM_IMM_FINANCIAL_CURRENCY_ID
                     , tpl_last_fin_imputation.IMM_IMM_FINANCIAL_CURRENCY_ID
                      )
           and Compare(tpl_fin_imputation.IMM_PERIOD_ID, tpl_last_fin_imputation.IMM_PERIOD_ID)
           and Compare(tpl_fin_imputation.IMM_NUMBER, tpl_last_fin_imputation.IMM_NUMBER)
           and Compare(tpl_fin_imputation.IMM_NUMBER2, tpl_last_fin_imputation.IMM_NUMBER2)
           and Compare(tpl_fin_imputation.IMM_NUMBER3, tpl_last_fin_imputation.IMM_NUMBER3)
           and Compare(tpl_fin_imputation.IMM_NUMBER4, tpl_last_fin_imputation.IMM_NUMBER4)
           and Compare(tpl_fin_imputation.IMM_NUMBER5, tpl_last_fin_imputation.IMM_NUMBER5)
           and Compare(tpl_fin_imputation.IMM_TEXT1, tpl_last_fin_imputation.IMM_TEXT1)
           and Compare(tpl_fin_imputation.IMM_TEXT2, tpl_last_fin_imputation.IMM_TEXT2)
           and Compare(tpl_fin_imputation.IMM_TEXT3, tpl_last_fin_imputation.IMM_TEXT3)
           and Compare(tpl_fin_imputation.IMM_TEXT4, tpl_last_fin_imputation.IMM_TEXT4)
           and Compare(tpl_fin_imputation.IMM_TEXT5, tpl_last_fin_imputation.IMM_TEXT5)
           and Compare(tpl_fin_imputation.IMM_DIC_IMP_FREE1_ID, tpl_last_fin_imputation.IMM_DIC_IMP_FREE1_ID)
           and Compare(tpl_fin_imputation.IMM_DIC_IMP_FREE2_ID, tpl_last_fin_imputation.IMM_DIC_IMP_FREE2_ID)
           and Compare(tpl_fin_imputation.IMM_DIC_IMP_FREE3_ID, tpl_last_fin_imputation.IMM_DIC_IMP_FREE3_ID)
           and Compare(tpl_fin_imputation.IMM_DIC_IMP_FREE4_ID, tpl_last_fin_imputation.IMM_DIC_IMP_FREE4_ID)
           and Compare(tpl_fin_imputation.IMM_DIC_IMP_FREE5_ID, tpl_last_fin_imputation.IMM_DIC_IMP_FREE5_ID)
           and Compare(tpl_fin_imputation.IMM_GCO_GOOD_ID, tpl_last_fin_imputation.IMM_GCO_GOOD_ID)
           and Compare(tpl_fin_imputation.IMM_DOC_RECORD_ID, tpl_last_fin_imputation.IMM_DOC_RECORD_ID)
           and Compare(tpl_fin_imputation.IMM_HRM_PERSON_ID, tpl_last_fin_imputation.IMM_HRM_PERSON_ID)
           and Compare(tpl_fin_imputation.IMM_PAC_PERSON_ID, tpl_last_fin_imputation.IMM_PAC_PERSON_ID)
           and Compare(tpl_fin_imputation.IMM_FAM_FIXED_ASSETS_ID, tpl_last_fin_imputation.IMM_FAM_FIXED_ASSETS_ID)
           and Compare(tpl_fin_imputation.IMM_C_FAM_TRANSACTION_TYP, tpl_last_fin_imputation.IMM_C_FAM_TRANSACTION_TYP)
           and Compare(tpl_fin_imputation.ACS_PJ_ACCOUNT_ID, tpl_last_fin_imputation.ACS_PJ_ACCOUNT_ID)
           and Compare(tpl_fin_imputation.MGM_NUMBER, tpl_last_fin_imputation.MGM_NUMBER)
           and Compare(tpl_fin_imputation.MGM_NUMBER2, tpl_last_fin_imputation.MGM_NUMBER2)
           and Compare(tpl_fin_imputation.MGM_NUMBER3, tpl_last_fin_imputation.MGM_NUMBER3)
           and Compare(tpl_fin_imputation.MGM_NUMBER4, tpl_last_fin_imputation.MGM_NUMBER4)
           and Compare(tpl_fin_imputation.MGM_NUMBER5, tpl_last_fin_imputation.MGM_NUMBER5)
           and Compare(tpl_fin_imputation.MGM_TEXT1, tpl_last_fin_imputation.MGM_TEXT1)
           and Compare(tpl_fin_imputation.MGM_TEXT2, tpl_last_fin_imputation.MGM_TEXT2)
           and Compare(tpl_fin_imputation.MGM_TEXT3, tpl_last_fin_imputation.MGM_TEXT3)
           and Compare(tpl_fin_imputation.MGM_TEXT4, tpl_last_fin_imputation.MGM_TEXT4)
           and Compare(tpl_fin_imputation.MGM_TEXT5, tpl_last_fin_imputation.MGM_TEXT5) then
          -- cumul des montants
          if not man_only then
            tpl_last_fin_imputation.IMF_AMOUNT_LC_D         :=
                                           tpl_last_fin_imputation.IMF_AMOUNT_LC_D + tpl_fin_imputation.IMF_AMOUNT_LC_D;
            tpl_last_fin_imputation.IMF_AMOUNT_LC_C         :=
                                           tpl_last_fin_imputation.IMF_AMOUNT_LC_C + tpl_fin_imputation.IMF_AMOUNT_LC_C;
            tpl_last_fin_imputation.IMF_AMOUNT_FC_D         :=
                                           tpl_last_fin_imputation.IMF_AMOUNT_FC_D + tpl_fin_imputation.IMF_AMOUNT_FC_D;
            tpl_last_fin_imputation.IMF_AMOUNT_FC_C         :=
                                           tpl_last_fin_imputation.IMF_AMOUNT_FC_C + tpl_fin_imputation.IMF_AMOUNT_FC_C;
            tpl_last_fin_imputation.IMF_AMOUNT_EUR_D        :=
                                         tpl_last_fin_imputation.IMF_AMOUNT_EUR_D + tpl_fin_imputation.IMF_AMOUNT_EUR_D;
            tpl_last_fin_imputation.IMF_AMOUNT_EUR_C        :=
                                         tpl_last_fin_imputation.IMF_AMOUNT_EUR_C + tpl_fin_imputation.IMF_AMOUNT_EUR_C;
            tpl_last_fin_imputation.FIN_AMOUNT_LC_D         :=
                                           tpl_last_fin_imputation.FIN_AMOUNT_LC_D + tpl_fin_imputation.FIN_AMOUNT_LC_D;
            tpl_last_fin_imputation.FIN_AMOUNT_LC_C         :=
                                           tpl_last_fin_imputation.FIN_AMOUNT_LC_C + tpl_fin_imputation.FIN_AMOUNT_LC_C;
            tpl_last_fin_imputation.FIN_AMOUNT_FC_D         :=
                                           tpl_last_fin_imputation.FIN_AMOUNT_FC_D + tpl_fin_imputation.FIN_AMOUNT_FC_D;
            tpl_last_fin_imputation.FIN_AMOUNT_FC_C         :=
                                           tpl_last_fin_imputation.FIN_AMOUNT_FC_C + tpl_fin_imputation.FIN_AMOUNT_FC_C;
            tpl_last_fin_imputation.FIN_AMOUNT_EUR_D        :=
                                         tpl_last_fin_imputation.FIN_AMOUNT_EUR_D + tpl_fin_imputation.FIN_AMOUNT_EUR_D;
            tpl_last_fin_imputation.FIN_AMOUNT_EUR_C        :=
                                         tpl_last_fin_imputation.FIN_AMOUNT_EUR_C + tpl_fin_imputation.FIN_AMOUNT_EUR_C;
            tpl_last_fin_imputation.TAX_VAT_AMOUNT_FC       :=
                                       tpl_last_fin_imputation.TAX_VAT_AMOUNT_FC + tpl_fin_imputation.TAX_VAT_AMOUNT_FC;
            tpl_last_fin_imputation.TAX_VAT_AMOUNT_LC       :=
                                       tpl_last_fin_imputation.TAX_VAT_AMOUNT_LC + tpl_fin_imputation.TAX_VAT_AMOUNT_LC;
            tpl_last_fin_imputation.TAX_VAT_AMOUNT_EUR      :=
                                     tpl_last_fin_imputation.TAX_VAT_AMOUNT_EUR + tpl_fin_imputation.TAX_VAT_AMOUNT_EUR;
            tpl_last_fin_imputation.TAX_TOT_VAT_AMOUNT_LC   :=
                               tpl_last_fin_imputation.TAX_TOT_VAT_AMOUNT_LC + tpl_fin_imputation.TAX_TOT_VAT_AMOUNT_LC;
            tpl_last_fin_imputation.TAX_TOT_VAT_AMOUNT_FC   :=
                               tpl_last_fin_imputation.TAX_TOT_VAT_AMOUNT_FC + tpl_fin_imputation.TAX_TOT_VAT_AMOUNT_FC;
            tpl_last_fin_imputation.TAX_TOT_VAT_AMOUNT_EUR  :=
                             tpl_last_fin_imputation.TAX_TOT_VAT_AMOUNT_EUR + tpl_fin_imputation.TAX_TOT_VAT_AMOUNT_EUR;
            tpl_last_fin_imputation.TAX_LIABLED_AMOUNT      :=
                                     tpl_last_fin_imputation.TAX_LIABLED_AMOUNT + tpl_fin_imputation.TAX_LIABLED_AMOUNT;
          end if;

          tpl_last_fin_imputation.IMM_AMOUNT_LC_D   :=
                                            tpl_last_fin_imputation.IMM_AMOUNT_LC_D + tpl_fin_imputation.IMM_AMOUNT_LC_D;
          tpl_last_fin_imputation.IMM_AMOUNT_LC_C   :=
                                            tpl_last_fin_imputation.IMM_AMOUNT_LC_C + tpl_fin_imputation.IMM_AMOUNT_LC_C;
          tpl_last_fin_imputation.IMM_AMOUNT_FC_D   :=
                                            tpl_last_fin_imputation.IMM_AMOUNT_FC_D + tpl_fin_imputation.IMM_AMOUNT_FC_D;
          tpl_last_fin_imputation.IMM_AMOUNT_FC_C   :=
                                            tpl_last_fin_imputation.IMM_AMOUNT_FC_C + tpl_fin_imputation.IMM_AMOUNT_FC_C;
          tpl_last_fin_imputation.IMM_AMOUNT_EUR_D  :=
                                          tpl_last_fin_imputation.IMM_AMOUNT_EUR_D + tpl_fin_imputation.IMM_AMOUNT_EUR_D;
          tpl_last_fin_imputation.IMM_AMOUNT_EUR_C  :=
                                          tpl_last_fin_imputation.IMM_AMOUNT_EUR_C + tpl_fin_imputation.IMM_AMOUNT_EUR_C;
          tpl_last_fin_imputation.IMM_QUANTITY_D    :=
                                              tpl_last_fin_imputation.IMM_QUANTITY_D + tpl_fin_imputation.IMM_QUANTITY_D;
          tpl_last_fin_imputation.IMM_QUANTITY_C    :=
                                              tpl_last_fin_imputation.IMM_QUANTITY_C + tpl_fin_imputation.IMM_QUANTITY_C;
          tpl_last_fin_imputation.MGM_AMOUNT_LC_D   :=
                                            tpl_last_fin_imputation.MGM_AMOUNT_LC_D + tpl_fin_imputation.MGM_AMOUNT_LC_D;
          tpl_last_fin_imputation.MGM_AMOUNT_LC_C   :=
                                            tpl_last_fin_imputation.MGM_AMOUNT_LC_C + tpl_fin_imputation.MGM_AMOUNT_LC_C;
          tpl_last_fin_imputation.MGM_AMOUNT_FC_D   :=
                                            tpl_last_fin_imputation.MGM_AMOUNT_FC_D + tpl_fin_imputation.MGM_AMOUNT_FC_D;
          tpl_last_fin_imputation.MGM_AMOUNT_FC_C   :=
                                            tpl_last_fin_imputation.MGM_AMOUNT_FC_C + tpl_fin_imputation.MGM_AMOUNT_FC_C;
          tpl_last_fin_imputation.MGM_AMOUNT_EUR_D  :=
                                          tpl_last_fin_imputation.MGM_AMOUNT_EUR_D + tpl_fin_imputation.MGM_AMOUNT_EUR_D;
          tpl_last_fin_imputation.MGM_AMOUNT_EUR_C  :=
                                          tpl_last_fin_imputation.MGM_AMOUNT_EUR_C + tpl_fin_imputation.MGM_AMOUNT_EUR_C;
          tpl_last_fin_imputation.MGM_QUANTITY_D    :=
                                              tpl_last_fin_imputation.MGM_QUANTITY_D + tpl_fin_imputation.MGM_QUANTITY_D;
          tpl_last_fin_imputation.MGM_QUANTITY_C    :=
                                              tpl_last_fin_imputation.MGM_QUANTITY_C + tpl_fin_imputation.MGM_QUANTITY_C;
          imp_count                                 := imp_count + 1;

          if not man_only then
            -- effacement écriture TVA
            if tpl_fin_imputation.ACT_ACT_FINANCIAL_IMPUTATION is not null then
              delete from ACT_FINANCIAL_IMPUTATION
                    where ACT_FINANCIAL_IMPUTATION_ID = tpl_fin_imputation.ACT_ACT_FINANCIAL_IMPUTATION;
            end if;

            delete from ACT_FINANCIAL_IMPUTATION
                  where ACT_FINANCIAL_IMPUTATION_ID = tpl_fin_imputation.ACT_FINANCIAL_IMPUTATION_ID;
          else
            delete from ACT_MGM_IMPUTATION
                  where ACT_MGM_IMPUTATION_ID = tpl_fin_imputation.ACT_MGM_IMPUTATION_ID;
          end if;
        else
          --Màj de l'écriture financière + distribution + det_tax + imputations TVA ('E')
          if imp_count > 1 then
            if not man_only then
              -- Recherche si les montants sont débit ou crédit
              select decode(sign(tpl_last_fin_imputation.IMF_AMOUNT_LC_D - tpl_last_fin_imputation.IMF_AMOUNT_LC_C)
                          , 1, tpl_last_fin_imputation.IMF_AMOUNT_LC_D - tpl_last_fin_imputation.IMF_AMOUNT_LC_C
                          , 0
                           )
                into amount_lc_d
                from dual;

              select decode(sign(tpl_last_fin_imputation.IMF_AMOUNT_LC_D - tpl_last_fin_imputation.IMF_AMOUNT_LC_C)
                          , -1, abs(tpl_last_fin_imputation.IMF_AMOUNT_LC_D - tpl_last_fin_imputation.IMF_AMOUNT_LC_C)
                          , 0
                           )
                into amount_lc_c
                from dual;

              select decode(sign(tpl_last_fin_imputation.IMF_AMOUNT_FC_D - tpl_last_fin_imputation.IMF_AMOUNT_FC_C)
                          , 1, tpl_last_fin_imputation.IMF_AMOUNT_FC_D - tpl_last_fin_imputation.IMF_AMOUNT_FC_C
                          , 0
                           )
                into amount_fc_d
                from dual;

              select decode(sign(tpl_last_fin_imputation.IMF_AMOUNT_FC_D - tpl_last_fin_imputation.IMF_AMOUNT_FC_C)
                          , -1, abs(tpl_last_fin_imputation.IMF_AMOUNT_FC_D - tpl_last_fin_imputation.IMF_AMOUNT_FC_C)
                          , 0
                           )
                into amount_fc_c
                from dual;

              select decode(sign(tpl_last_fin_imputation.IMF_AMOUNT_EUR_D - tpl_last_fin_imputation.IMF_AMOUNT_EUR_C)
                          , 1, tpl_last_fin_imputation.IMF_AMOUNT_EUR_D - tpl_last_fin_imputation.IMF_AMOUNT_EUR_C
                          , 0
                           )
                into amount_eur_d
                from dual;

              select decode(sign(tpl_last_fin_imputation.IMF_AMOUNT_EUR_D - tpl_last_fin_imputation.IMF_AMOUNT_EUR_C)
                          , -1, abs(tpl_last_fin_imputation.IMF_AMOUNT_EUR_D - tpl_last_fin_imputation.IMF_AMOUNT_EUR_C)
                          , 0
                           )
                into amount_eur_c
                from dual;

              -- màj de l'écriture financière
              update ACT_FINANCIAL_IMPUTATION
                 set IMF_AMOUNT_LC_D = amount_lc_d
                   , IMF_AMOUNT_LC_C = amount_lc_c
                   , IMF_AMOUNT_FC_D = amount_fc_d
                   , IMF_AMOUNT_FC_C = amount_fc_c
                   , IMF_AMOUNT_EUR_D = amount_eur_d
                   , IMF_AMOUNT_EUR_C = amount_eur_c
               where ACT_FINANCIAL_IMPUTATION_ID = tpl_last_fin_imputation.ACT_FINANCIAL_IMPUTATION_ID;

              -- Recherche si les montants sont débit ou crédit
              select decode(sign(tpl_last_fin_imputation.FIN_AMOUNT_LC_D - tpl_last_fin_imputation.FIN_AMOUNT_LC_C)
                          , 1, tpl_last_fin_imputation.FIN_AMOUNT_LC_D - tpl_last_fin_imputation.FIN_AMOUNT_LC_C
                          , 0
                           )
                into amount_lc_d
                from dual;

              select decode(sign(tpl_last_fin_imputation.FIN_AMOUNT_LC_D - tpl_last_fin_imputation.FIN_AMOUNT_LC_C)
                          , -1, abs(tpl_last_fin_imputation.FIN_AMOUNT_LC_D - tpl_last_fin_imputation.FIN_AMOUNT_LC_C)
                          , 0
                           )
                into amount_lc_c
                from dual;

              select decode(sign(tpl_last_fin_imputation.FIN_AMOUNT_FC_D - tpl_last_fin_imputation.FIN_AMOUNT_FC_C)
                          , 1, tpl_last_fin_imputation.FIN_AMOUNT_FC_D - tpl_last_fin_imputation.FIN_AMOUNT_FC_C
                          , 0
                           )
                into amount_fc_d
                from dual;

              select decode(sign(tpl_last_fin_imputation.FIN_AMOUNT_FC_D - tpl_last_fin_imputation.FIN_AMOUNT_FC_C)
                          , -1, abs(tpl_last_fin_imputation.FIN_AMOUNT_FC_D - tpl_last_fin_imputation.FIN_AMOUNT_FC_C)
                          , 0
                           )
                into amount_fc_c
                from dual;

              select decode(sign(tpl_last_fin_imputation.FIN_AMOUNT_EUR_D - tpl_last_fin_imputation.FIN_AMOUNT_EUR_C)
                          , 1, tpl_last_fin_imputation.FIN_AMOUNT_EUR_D - tpl_last_fin_imputation.FIN_AMOUNT_EUR_C
                          , 0
                           )
                into amount_eur_d
                from dual;

              select decode(sign(tpl_last_fin_imputation.FIN_AMOUNT_EUR_D - tpl_last_fin_imputation.FIN_AMOUNT_EUR_C)
                          , -1, abs(tpl_last_fin_imputation.FIN_AMOUNT_EUR_D - tpl_last_fin_imputation.FIN_AMOUNT_EUR_C)
                          , 0
                           )
                into amount_eur_c
                from dual;

              -- màj de la distribution
              update ACT_FINANCIAL_DISTRIBUTION
                 set FIN_AMOUNT_LC_D = amount_lc_d
                   , FIN_AMOUNT_LC_C = amount_lc_c
                   , FIN_AMOUNT_FC_D = amount_fc_d
                   , FIN_AMOUNT_FC_C = amount_fc_c
                   , FIN_AMOUNT_EUR_D = amount_eur_d
                   , FIN_AMOUNT_EUR_C = amount_eur_c
               where ACT_FINANCIAL_IMPUTATION_ID = tpl_last_fin_imputation.ACT_FINANCIAL_IMPUTATION_ID;

              if tpl_last_fin_imputation.ACT_DET_TAX_ID is not null then
                -- màj du det_tax
                update ACT_DET_TAX
                   set TAX_VAT_AMOUNT_LC = tpl_last_fin_imputation.TAX_VAT_AMOUNT_LC
                     , TAX_VAT_AMOUNT_FC = tpl_last_fin_imputation.TAX_VAT_AMOUNT_FC
                     , TAX_VAT_AMOUNT_EUR = tpl_last_fin_imputation.TAX_VAT_AMOUNT_EUR
                     , TAX_TOT_VAT_AMOUNT_LC = tpl_last_fin_imputation.TAX_TOT_VAT_AMOUNT_LC
                     , TAX_TOT_VAT_AMOUNT_FC = tpl_last_fin_imputation.TAX_TOT_VAT_AMOUNT_FC
                     , TAX_TOT_VAT_AMOUNT_EUR = tpl_last_fin_imputation.TAX_TOT_VAT_AMOUNT_EUR
                     , TAX_LIABLED_AMOUNT = tpl_last_fin_imputation.TAX_LIABLED_AMOUNT
                 where ACT_DET_TAX_ID = tpl_last_fin_imputation.ACT_DET_TAX_ID;

                if tpl_last_fin_imputation.ACT_ACT_FINANCIAL_IMPUTATION is not null then
                  -- Recherche si les montants sont débit ou crédit
                  select decode(sign(tpl_last_fin_imputation.TAX_VAT_AMOUNT_LC)
                              , 1, tpl_last_fin_imputation.TAX_VAT_AMOUNT_LC
                              , 0
                               )
                    into amount_lc_d
                    from dual;

                  select decode(sign(tpl_last_fin_imputation.TAX_VAT_AMOUNT_LC)
                              , -1, -tpl_last_fin_imputation.TAX_VAT_AMOUNT_LC
                              , 0
                               )
                    into amount_lc_c
                    from dual;

                  select decode(sign(tpl_last_fin_imputation.TAX_VAT_AMOUNT_FC)
                              , 1, tpl_last_fin_imputation.TAX_VAT_AMOUNT_FC
                              , 0
                               )
                    into amount_fc_d
                    from dual;

                  select decode(sign(tpl_last_fin_imputation.TAX_VAT_AMOUNT_FC)
                              , -1, -tpl_last_fin_imputation.TAX_VAT_AMOUNT_FC
                              , 0
                               )
                    into amount_fc_c
                    from dual;

                  select decode(sign(tpl_last_fin_imputation.TAX_VAT_AMOUNT_EUR)
                              , 1, tpl_last_fin_imputation.TAX_VAT_AMOUNT_EUR
                              , 0
                               )
                    into amount_eur_d
                    from dual;

                  select decode(sign(tpl_last_fin_imputation.TAX_VAT_AMOUNT_EUR)
                              , -1, -tpl_last_fin_imputation.TAX_VAT_AMOUNT_EUR
                              , 0
                               )
                    into amount_eur_c
                    from dual;

                  -- màj de l'écriture financière
                  update ACT_FINANCIAL_IMPUTATION
                     set IMF_AMOUNT_LC_D = amount_lc_d
                       , IMF_AMOUNT_LC_C = amount_lc_c
                       , IMF_AMOUNT_FC_D = amount_fc_d
                       , IMF_AMOUNT_FC_C = amount_fc_c
                       , IMF_AMOUNT_EUR_D = amount_eur_d
                       , IMF_AMOUNT_EUR_C = amount_eur_c
                   where ACT_FINANCIAL_IMPUTATION_ID = tpl_last_fin_imputation.ACT_ACT_FINANCIAL_IMPUTATION;

                  -- màj de la distribution
                  update ACT_FINANCIAL_DISTRIBUTION
                     set FIN_AMOUNT_LC_D = amount_lc_d
                       , FIN_AMOUNT_LC_C = amount_lc_c
                       , FIN_AMOUNT_FC_D = amount_fc_d
                       , FIN_AMOUNT_FC_C = amount_fc_c
                       , FIN_AMOUNT_EUR_D = amount_eur_d
                       , FIN_AMOUNT_EUR_C = amount_eur_c
                   where ACT_FINANCIAL_IMPUTATION_ID = tpl_last_fin_imputation.ACT_ACT_FINANCIAL_IMPUTATION;
                end if;
              end if;
            end if;

            -- Recherche si les montants sont débit ou crédit
            select decode(sign(tpl_last_fin_imputation.IMM_AMOUNT_LC_D - tpl_last_fin_imputation.IMM_AMOUNT_LC_C)
                        , 1, tpl_last_fin_imputation.IMM_AMOUNT_LC_D - tpl_last_fin_imputation.IMM_AMOUNT_LC_C
                        , 0
                         )
              into amount_lc_d
              from dual;

            select decode(sign(tpl_last_fin_imputation.IMM_AMOUNT_LC_D - tpl_last_fin_imputation.IMM_AMOUNT_LC_C)
                        , -1, abs(tpl_last_fin_imputation.IMM_AMOUNT_LC_D - tpl_last_fin_imputation.IMM_AMOUNT_LC_C)
                        , 0
                         )
              into amount_lc_c
              from dual;

            select decode(sign(tpl_last_fin_imputation.IMM_AMOUNT_FC_D - tpl_last_fin_imputation.IMM_AMOUNT_FC_C)
                        , 1, tpl_last_fin_imputation.IMM_AMOUNT_FC_D - tpl_last_fin_imputation.IMM_AMOUNT_FC_C
                        , 0
                         )
              into amount_fc_d
              from dual;

            select decode(sign(tpl_last_fin_imputation.IMM_AMOUNT_FC_D - tpl_last_fin_imputation.IMM_AMOUNT_FC_C)
                        , -1, abs(tpl_last_fin_imputation.IMM_AMOUNT_FC_D - tpl_last_fin_imputation.IMM_AMOUNT_FC_C)
                        , 0
                         )
              into amount_fc_c
              from dual;

            select decode(sign(tpl_last_fin_imputation.IMM_AMOUNT_EUR_D - tpl_last_fin_imputation.IMM_AMOUNT_EUR_C)
                        , 1, tpl_last_fin_imputation.IMM_AMOUNT_EUR_D - tpl_last_fin_imputation.IMM_AMOUNT_EUR_C
                        , 0
                         )
              into amount_eur_d
              from dual;

            select decode(sign(tpl_last_fin_imputation.IMM_AMOUNT_EUR_D - tpl_last_fin_imputation.IMM_AMOUNT_EUR_C)
                        , -1, abs(tpl_last_fin_imputation.IMM_AMOUNT_EUR_D - tpl_last_fin_imputation.IMM_AMOUNT_EUR_C)
                        , 0
                         )
              into amount_eur_c
              from dual;

            -- màj de l'écriture analytique
            update ACT_MGM_IMPUTATION
               set IMM_AMOUNT_LC_D = amount_lc_d
                 , IMM_AMOUNT_LC_C = amount_lc_c
                 , IMM_AMOUNT_FC_D = amount_fc_d
                 , IMM_AMOUNT_FC_C = amount_fc_c
                 , IMM_AMOUNT_EUR_D = amount_eur_d
                 , IMM_AMOUNT_EUR_C = amount_eur_c
                 , IMM_QUANTITY_D = tpl_last_fin_imputation.IMM_QUANTITY_D
                 , IMM_QUANTITY_C = tpl_last_fin_imputation.IMM_QUANTITY_C
             where ACT_MGM_IMPUTATION_ID = tpl_last_fin_imputation.ACT_MGM_IMPUTATION_ID;

            -- Recherche si les montants sont débit ou crédit
            select decode(sign(tpl_last_fin_imputation.MGM_AMOUNT_LC_D - tpl_last_fin_imputation.MGM_AMOUNT_LC_C)
                        , 1, tpl_last_fin_imputation.MGM_AMOUNT_LC_D - tpl_last_fin_imputation.MGM_AMOUNT_LC_C
                        , 0
                         )
              into amount_lc_d
              from dual;

            select decode(sign(tpl_last_fin_imputation.MGM_AMOUNT_LC_D - tpl_last_fin_imputation.MGM_AMOUNT_LC_C)
                        , -1, abs(tpl_last_fin_imputation.MGM_AMOUNT_LC_D - tpl_last_fin_imputation.MGM_AMOUNT_LC_C)
                        , 0
                         )
              into amount_lc_c
              from dual;

            select decode(sign(tpl_last_fin_imputation.MGM_AMOUNT_FC_D - tpl_last_fin_imputation.MGM_AMOUNT_FC_C)
                        , 1, tpl_last_fin_imputation.MGM_AMOUNT_FC_D - tpl_last_fin_imputation.MGM_AMOUNT_FC_C
                        , 0
                         )
              into amount_fc_d
              from dual;

            select decode(sign(tpl_last_fin_imputation.MGM_AMOUNT_FC_D - tpl_last_fin_imputation.MGM_AMOUNT_FC_C)
                        , -1, abs(tpl_last_fin_imputation.MGM_AMOUNT_FC_D - tpl_last_fin_imputation.MGM_AMOUNT_FC_C)
                        , 0
                         )
              into amount_fc_c
              from dual;

            select decode(sign(tpl_last_fin_imputation.MGM_AMOUNT_EUR_D - tpl_last_fin_imputation.MGM_AMOUNT_EUR_C)
                        , 1, tpl_last_fin_imputation.MGM_AMOUNT_EUR_D - tpl_last_fin_imputation.MGM_AMOUNT_EUR_C
                        , 0
                         )
              into amount_eur_d
              from dual;

            select decode(sign(tpl_last_fin_imputation.MGM_AMOUNT_EUR_D - tpl_last_fin_imputation.MGM_AMOUNT_EUR_C)
                        , -1, abs(tpl_last_fin_imputation.MGM_AMOUNT_EUR_D - tpl_last_fin_imputation.MGM_AMOUNT_EUR_C)
                        , 0
                         )
              into amount_eur_c
              from dual;

            -- màj de l'écriture analytique
            update ACT_MGM_DISTRIBUTION
               set MGM_AMOUNT_LC_D = amount_lc_d
                 , MGM_AMOUNT_LC_C = amount_lc_c
                 , MGM_AMOUNT_FC_D = amount_fc_d
                 , MGM_AMOUNT_FC_C = amount_fc_c
                 , MGM_AMOUNT_EUR_D = amount_eur_d
                 , MGM_AMOUNT_EUR_C = amount_eur_c
                 , MGM_QUANTITY_D = tpl_last_fin_imputation.MGM_QUANTITY_D
                 , MGM_QUANTITY_C = tpl_last_fin_imputation.MGM_QUANTITY_C
             where ACT_MGM_DISTRIBUTION_ID = tpl_last_fin_imputation.ACT_MGM_DISTRIBUTION_ID;
          end if;

          tpl_last_fin_imputation  := tpl_fin_imputation;
          imp_count                := 1;
        end if;

        fetch csr_fin_imputation
         into tpl_fin_imputation;
      end loop;

      close csr_fin_imputation;
--      end if;
    end loop;
  end GroupImputations;

  procedure UpdateExpSelExchangeRate(
    aACT_ETAT_EVENT_ID ACT_ETAT_EVENT.ACT_ETAT_EVENT_ID%type
  , aEXCHANGE_RATE     ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aBASE_PRICE        ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aOnlyRecLevel      ACT_EXPIRY_SELECTION.A_RECLEVEL%type default null
  , aDate              date default null
  , aDiffOnPaied       number default 0
  , aHedging           number default 0
    )
  is
    cursor ExpSelection(
      EtatEventId  ACT_ETAT_EVENT.ACT_ETAT_EVENT_ID%type
    , OnlyRecLevel ACT_EXPIRY_SELECTION.A_RECLEVEL%type
    )
    is
      select   (select C_CURR_RATE_COVER_TYPE
                  from ACT_DOCUMENT
                 where ACT_DOCUMENT_ID = (select ACT_DOCUMENT_ID
                                            from ACT_EXPIRY
                                           where ACT_EXPIRY_ID = SEL.ACT_EXPIRY_ID) ) C_CURR_RATE_COVER_TYPE
             , SEL.*
          from ACT_EXPIRY_SELECTION SEL
         where SEL.ACT_ETAT_EVENT_ID = EtatEventId
           and SEL.ACS_FINANCIAL_CURRENCY_ID != ACS_FUNCTION.GetLocalCurrencyId
           and (   OnlyRecLevel is null
                or (SEL.A_RECLEVEL = OnlyRecLevel) )
      order by SEL.ACT_ETAT_EVENT_ID;

    PaiedLC        ACT_EXPIRY_SELECTION.DET_PAIED_LC%type;
    DiscountLC     ACT_EXPIRY_SELECTION.DET_DISCOUNT_LC%type;
    DeductionLC    ACT_EXPIRY_SELECTION.DET_DEDUCTION_LC%type;
    DiffExchangeLC ACT_EXPIRY_SELECTION.DET_DIFF_EXCHANGE%type;
    DiffRound      ACT_EXPIRY_SELECTION.DET_DIFF_EXCHANGE%type;
    AmountLC       ACT_EXPIRY_SELECTION.DET_PAIED_LC%type;
    AmountEUR      ACT_EXPIRY_SELECTION.DET_PAIED_FC%type;
    AmountConvert  ACT_EXPIRY_SELECTION.DET_PAIED_LC%type;
    vDate          date;
    ln_RateToApply ACT_EXPIRY_SELECTION.EXS_EXCHANGE_RATE%type;

  begin
    for tpl_ExpSelection in ExpSelection(aACT_ETAT_EVENT_ID, aOnlyRecLevel) loop
      -- Utilisation date en param ou date de EXS_DOCUMENT
      if aDate is not null then
        vDate  := aDate;
      else
        vDate  := to_date(tpl_ExpSelection.EXS_DOCUMENT, 'yyyymmdd');
      end if;

      ln_RateToApply := aEXCHANGE_RATE;
      --Document en auto-couverture....Le cours de la devise a appliquer est le même que celui de l'échéance payé
      if (aHedging = 1) and (tpl_ExpSelection.C_CURR_RATE_COVER_TYPE = '01') then
        ln_RateToApply := tpl_ExpSelection.EXS_EXCHANGE_RATE;
      end if;


      -- Conversion montant payé
      ACS_FUNCTION.ConvertAmount(tpl_ExpSelection.DET_PAIED_FC
                               , tpl_ExpSelection.ACS_FINANCIAL_CURRENCY_ID
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , vDate
                               , ln_RateToApply
                               , aBASE_PRICE
                               , 1
                               , AmountEUR
                               , AmountConvert
                                );
      PaiedLC         := AmountConvert;
      -- Conversion montant deduction
      ACS_FUNCTION.ConvertAmount(tpl_ExpSelection.DET_DEDUCTION_FC
                               , tpl_ExpSelection.ACS_FINANCIAL_CURRENCY_ID
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , vDate
                               , ln_RateToApply
                               , aBASE_PRICE
                               , 1
                               , AmountEUR
                               , AmountConvert
                                );
      DeductionLC     := AmountConvert;
      -- Conversion montant escompte
      ACS_FUNCTION.ConvertAmount(tpl_ExpSelection.DET_DISCOUNT_FC
                               , tpl_ExpSelection.ACS_FINANCIAL_CURRENCY_ID
                               , ACS_FUNCTION.GetLocalCurrencyId
                               , vDate
                               , ln_RateToApply
                               , aBASE_PRICE
                               , 1
                               , AmountEUR
                               , AmountConvert
                                );
      DiscountLC      := AmountConvert;

      AmountLC        :=
        tpl_ExpSelection.DET_PAIED_LC +
        tpl_ExpSelection.DET_DISCOUNT_LC +
        tpl_ExpSelection.DET_DEDUCTION_LC +
        tpl_ExpSelection.DET_DIFF_EXCHANGE;

      if aDiffOnPaied = 1 then
        -- Conversion montant payé
        ACS_FUNCTION.ConvertAmount(tpl_ExpSelection.DET_PAIED_FC + tpl_ExpSelection.DET_DEDUCTION_FC + tpl_ExpSelection.DET_DISCOUNT_FC
                                 , tpl_ExpSelection.ACS_FINANCIAL_CURRENCY_ID
                                 , ACS_FUNCTION.GetLocalCurrencyId
                                 , vDate
                                 , ln_RateToApply
                                 , aBASE_PRICE
                                 , 1
                                 , AmountEUR
                                 , AmountConvert
                                  );
        DiffRound       := AmountConvert;

        -- Difference du à l'arrondi
        DiffRound := (PaiedLC + DiscountLC + DeductionLC) - DiffRound;

        PaiedLC := PaiedLC - DiffRound;
      end if;

      -- Assignation de la diff. de change (avec év. la diff. d'arrondie)
      DiffExchangeLC  := AmountLC - PaiedLC - DeductionLC - DiscountLC;

      -- Màj table ACT_EXPIRY_SELECTION
      update ACT_EXPIRY_SELECTION
         set DET_PAIED_LC = PaiedLC
           , DET_DEDUCTION_LC = DeductionLC
           , DET_DISCOUNT_LC = DiscountLC
           , DET_DIFF_EXCHANGE = nvl(DiffExchangeLC, 0)
           , EXS_EXCHANGE_RATE = ln_RateToApply
           , EXS_BASE_PRICE = aBASE_PRICE
       where ACT_EXPIRY_SELECTION_ID = tpl_ExpSelection.ACT_EXPIRY_SELECTION_ID;
    end loop;
  end UpdateExpSelExchangeRate;

  /**
  * Description
  *    Protection ou déprotection du document dans une transaction autonome
  */
  procedure DocumentProtect(
    aACT_DOCUMENT_ID     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aProtect             number
  , aSessionID           varchar2
  , aUserID              number
  , aShowError           number
  , aUpdated         out number
  )
  is
    pragma autonomous_transaction;
    vDocumentId ACT_DOCUMENT_STATUS.ACT_DOCUMENT_ID%type;
    vSessionId  ACT_DOCUMENT_STATUS.DOC_LOCK_SESSION_ID%type;

    procedure CheckAndCreateDocStatus
    is
    begin
      select min(ACT_DOCUMENT_ID)
        into vDocumentId
        from ACT_DOCUMENT_STATUS
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      if vDocumentId is null then
        insert into ACT_DOCUMENT_STATUS
                (ACT_DOCUMENT_STATUS_ID
               , ACT_DOCUMENT_ID
               , DOC_OK
                )
         values (INIT_ID_SEQ.nextval
               , aACT_DOCUMENT_ID
               , 1
                );
      end if;

    end CheckAndCreateDocStatus;
  begin
    CheckAndCreateDocStatus;
    if aProtect != 0 then
      -- teste si le document n'est pas déjà protégé par quelqu'un d'autre
      select ACT_DOCUMENT_ID
        into vDocumentId
        from ACT_DOCUMENT_STATUS
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and (   DOC_LOCK_SESSION_ID = aSessionId
              or DOC_LOCK_SESSION_ID is null);

      /* Màj du flag de protection du document */
      update ACT_DOCUMENT_STATUS
         set DOC_LOCK_SESSION_ID = aSessionID
           , PC_PC_USER_ID = aUserID
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      aUpdated  := 1;
    else
      -- teste si le document n'est pas déjà protégé par quelqu'un d'autre
      select ACT_DOCUMENT_ID
           , DOC_LOCK_SESSION_ID
        into vDocumentId
           , vSessionId
        from ACT_DOCUMENT_STATUS
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      if    vSessionId = aSessionId
         or vSessionId is null then
        aUpdated  := 1;
      elsif     aSessionId is null
            and COM_FUNCTIONS.Is_Session_Alive(vSessionId) = 0 then
        aUpdated  := 1;
      else
        if aShowError = 1 then
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                             ('PCS - Vous essayez de déprotéger un document qui a été protégé par un autre utilisateur.')
            );
        else
          aUpdated  := 0;
        end if;
      end if;

      if aUpdated = 1 then
        /* Màj du flag de protection du document */
        update ACT_DOCUMENT_STATUS
           set DOC_LOCK_SESSION_ID = null
             , PC_PC_USER_ID = null
         where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;
      end if;
    end if;

    commit;   /* Car on utilise une transaction autonome */
  exception
    when no_data_found then
      if aShowError = 1 then
        if aProtect = 1 then
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                            ('PCS - Vous essayez de protéger un document qui est déjà protégé par un autre utilisateur.')
            );
        else
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                             ('PCS - Vous essayez de déprotéger un document qui a été protégé par un autre utilisateur.')
            );
        end if;
      else
        aUpdated  := 0;
      end if;
  end DocumentProtect;

  /**
  * Description
  *    Protection ou déprotection du document dans une transaction autonome
  */
  procedure DocumentProtectAutonomous(
    aACT_DOCUMENT_ID     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aProtect             number
  , aSessionID           varchar2
  , aUserID              number
  , aShowError           number
  , aUpdated         out number
  )
  is
    pragma autonomous_transaction;
  begin
    DocumentProtect(aACT_DOCUMENT_ID, aProtect, aSessionID, aUserID, aShowError, aUpdated);
    commit;   /* Car on utilise une transaction autonome */
  end DocumentProtectAutonomous;

  /**
  * Description
  *    Protection ou déprotection du document dans une transaction autonome
  *      avec contrôle si protection par document ou travail
  */
  procedure DocumentProtectACT(
    aACT_DOCUMENT_ID           ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aProtect                   number
  , aSessionID                 varchar2
  , aUserID                    number
  , aShowError                 number
  , aUpdated               out number
  , aAutonomousTransaction     number default 1
  )
  is
    vMultiUser number(1);
  begin
    --Recherche si travail multi-user
    select nvl(min(EVE_MULTI_USERS), 0)
      into vMultiUser
      from ACJ_EVENT EVE
         , ACT_JOB JOB
         , ACT_DOCUMENT DOC
     where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
       and JOB.ACT_JOB_ID = DOC.ACT_JOB_ID
       and EVE.ACJ_JOB_TYPE_ID = JOB.ACJ_JOB_TYPE_ID
       and EVE.C_TYPE_EVENT = '1';

    --Si travail multi-user on protège le document, sinon on fait rien
    if vMultiUser = 1 then
      if aAutonomousTransaction = 0 then
        DocumentProtect(aACT_DOCUMENT_ID, aProtect, aSessionID, aUserID, aShowError, aUpdated);
      else
        DocumentProtectAutonomous(aACT_DOCUMENT_ID, aProtect, aSessionID, aUserID, aShowError, aUpdated);
      end if;
    else
      aUpdated  := 2;
    end if;
  end DocumentProtectACT;

  /**
  * Description
  *    Protection ou déprotection du job
  */
  procedure JobProtect(
    aACT_JOB_ID     ACT_JOB.ACT_JOB_ID%type
  , aProtect        number
  , aSessionID      varchar2
  , aUserID         number
  , aShowError      number
  , aUpdated    out number
  )
  is
    vJobId     ACT_JOB.ACT_JOB_ID%type;
    vSessionId ACT_JOB.JOB_LOCK_SESSION_ID%type;
  begin
    if aProtect != 0 then
      -- teste si le job n'est pas déjà protégé par quelqu'un d'autre
      select ACT_JOB_ID
        into vJobId
        from ACT_JOB
       where ACT_JOB_ID = aACT_JOB_ID
         and (   JOB_LOCK_SESSION_ID = aSessionId
              or JOB_LOCK_SESSION_ID is null);

      /* Màj du flag de protection du job */
      update ACT_JOB
         set JOB_LOCK_SESSION_ID = aSessionID
           , PC_PC_USER_ID = aUserID
       where ACT_JOB_ID = aACT_JOB_ID;

      aUpdated  := 1;
    else
      -- teste si le job n'est pas déjà protégé par quelqu'un d'autre
      select ACT_JOB_ID
           , JOB_LOCK_SESSION_ID
        into vJobId
           , vSessionId
        from ACT_JOB
       where ACT_JOB_ID = aACT_JOB_ID;

      if    vSessionId = aSessionId
         or vSessionId is null then
        aUpdated  := 1;
      elsif     aSessionId is null
            and COM_FUNCTIONS.Is_Session_Alive(vSessionId) = 0 then
        aUpdated  := 1;
      else
        if aShowError = 1 then
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                              ('PCS - Vous essayez de déprotéger un travail qui a été protégé par un autre utilisateur.')
            );
        else
          aUpdated  := 0;
        end if;
      end if;

      if aUpdated = 1 then
        /* Màj du flag de protection du job */
        update ACT_JOB
           set JOB_LOCK_SESSION_ID = null
             , PC_PC_USER_ID = null
         where ACT_JOB_ID = aACT_JOB_ID;
      end if;
    end if;
  exception
    when no_data_found then
      if aShowError = 1 then
        if aProtect = 1 then
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                             ('PCS - Vous essayez de protéger un travail qui est déjà protégé par un autre utilisateur.')
            );
        else
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                              ('PCS - Vous essayez de déprotéger un travail qui a été protégé par un autre utilisateur.')
            );
        end if;
      else
        aUpdated  := 0;
      end if;
  end JobProtect;

  /**
  * Description
  *    Protection ou déprotection du job dans une transaction autonome
  */
  procedure JobProtectAutonomous(
    aACT_JOB_ID     ACT_JOB.ACT_JOB_ID%type
  , aProtect        number
  , aSessionID      varchar2
  , aUserID         number
  , aShowError      number
  , aUpdated    out number
  )
  is
    pragma autonomous_transaction;
  begin
    JobProtect(aACT_JOB_ID, aProtect, aSessionID, aUserID, aShowError, aUpdated);
    commit;   /* Car on utilise une transaction autonome */
  end JobProtectAutonomous;

  /**
  * Description
  *    Protection ou déprotection du job dans une transaction autonome
  *      avec contrôle si protection par document ou travail
  */
  procedure JobProtectACT(
    aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type
  , aProtect                   number
  , aSessionID                 varchar2
  , aUserID                    number
  , aShowError                 number
  , aUpdated               out number
  , aAutonomousTransaction     number default 1
  )
  is
    vMultiUser number(1);
  begin
    --Recherche si travail multi-user
    select nvl(min(EVE_MULTI_USERS), 0)
      into vMultiUser
      from ACJ_EVENT EVE
         , ACT_JOB JOB
     where JOB.ACT_JOB_ID = aACT_JOB_ID
       and EVE.ACJ_JOB_TYPE_ID = JOB.ACJ_JOB_TYPE_ID
       and EVE.C_TYPE_EVENT = '1';

    --Si travail multi-user on protège le document, sinon on fait rien
    if vMultiUser = 0 then
      if aAutonomousTransaction = 0 then
        JobProtect(aACT_JOB_ID, aProtect, aSessionID, aUserID, aShowError, aUpdated);
      else
        JobProtectAutonomous(aACT_JOB_ID, aProtect, aSessionID, aUserID, aShowError, aUpdated);
      end if;
    else
      aUpdated  := 2;
    end if;
  end JobProtectACT;

  /**
  * Description
  *   Recherche si il existe des monnaie étrangère dans le document
  */
  function HasForeignCurrency(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return boolean
  is
    vCount integer;
  begin
    --Recherche si écriture fin.
    select count(*)
      into vCount
      from ACT_FINANCIAL_IMPUTATION IMP
     where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    if vCount > 0 then
      --Contrôle des monnaies des imputations fin.
      select count(*)
        into vCount
        from ACT_FINANCIAL_IMPUTATION IMP
       where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and IMP.ACS_FINANCIAL_CURRENCY_ID <> IMP.ACS_ACS_FINANCIAL_CURRENCY_ID;
    else
      --Contrôle des monnaies des imputations anal.
      select count(*)
        into vCount
        from ACT_MGM_IMPUTATION IMP
       where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and IMP.ACS_FINANCIAL_CURRENCY_ID <> IMP.ACS_ACS_FINANCIAL_CURRENCY_ID;
    end if;

    return vCount > 0;
  end HasForeignCurrency;

  /**
  * Description
  *    Retourne la date de réf. pour le recalcul des cours de change en fonction du code aDateReference.
  */
  function GetRefDate(aDateReference integer, aDocumentDate date, aTransactionDate date, aValueDate date)
    return date
  is
  begin
    if aDateReference = 1 then
      return aDocumentDate;
    elsif aDateReference = 2 then
      return aTransactionDate;
    elsif aDateReference = 3 then
      return aValueDate;
    else
      return null;
    end if;
  end GetRefDate;

  --forward declaration
  procedure UpdateImpExchangeRate(
    aACT_FINANCIAL_IMPUTATION_ID        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aBaseCurrencyId                     ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDocDate                            date
  , aDateReference                      integer
  , aAmounts                            AmountsRecType
  , aExchangeRate                       EchangeRateRecType
  , aResultAmounts               in out AmountsRecType
  );

  /**
  * Description
  *    Màj cours de change et montants selon date de ref. et monnaies
  */
  procedure UpdateAmounts(
    aAmounts                       in out AmountsRecType
  , aExchangeRate                  in out EchangeRateRecType
  , aBaseCurrencyId                       ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_FINANCIAL_CURRENCY_ID            ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID        ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aDateRef                              date
  , aRateType                             integer default 1
  , aRound                                integer default 1
  )
  is
    vAmounts AmountsRecType;
  begin
    if aDateRef is not null then
      --On as une monnaie étrangère
      if aACS_FINANCIAL_CURRENCY_ID != aACS_ACS_FINANCIAL_CURRENCY_ID then
        vAmounts  := aAmounts;

        --Monnaie étrangère = monnaie du document -> recalcule monnaie de base
        if aACS_FINANCIAL_CURRENCY_ID = aBaseCurrencyId then
          ConvertAmounts(vAmounts.DebitFC
                       , aACS_FINANCIAL_CURRENCY_ID
                       , aACS_ACS_FINANCIAL_CURRENCY_ID
                       , aDateRef
                       , aRound
                       , aRateType
                       , aExchangeRate.ExchangeRate
                       , aExchangeRate.BasePrice
                       , vAmounts.DebitEUR
                       , vAmounts.DebitLC
                        );
          ConvertAmounts(vAmounts.CreditFC
                       , aACS_FINANCIAL_CURRENCY_ID
                       , aACS_ACS_FINANCIAL_CURRENCY_ID
                       , aDateRef
                       , aRound
                       , aRateType
                       , aExchangeRate.ExchangeRate
                       , aExchangeRate.BasePrice
                       , vAmounts.CreditEUR
                       , vAmounts.CreditLC
                        );
        else
          ConvertAmounts(vAmounts.DebitLC
                       , aACS_ACS_FINANCIAL_CURRENCY_ID
                       , aACS_FINANCIAL_CURRENCY_ID
                       , aDateRef
                       , aRound
                       , aRateType
                       , aExchangeRate.ExchangeRate
                       , aExchangeRate.BasePrice
                       , vAmounts.DebitEUR
                       , vAmounts.DebitFC
                        );
          ConvertAmounts(vAmounts.CreditLC
                       , aACS_ACS_FINANCIAL_CURRENCY_ID
                       , aACS_FINANCIAL_CURRENCY_ID
                       , aDateRef
                       , aRound
                       , aRateType
                       , aExchangeRate.ExchangeRate
                       , aExchangeRate.BasePrice
                       , vAmounts.CreditEUR
                       , vAmounts.CreditFC
                        );
        end if;

        aAmounts  := vAmounts;
      end if;
    end if;
  end UpdateAmounts;

  /**
  * Description
  *   Initialisation des montant d'un record AmountsRecType en fonction du sens et du signe
  *   d'une imputation de référence mais en gardant les montants du record.
  */
  procedure InitImpAmounts(
    aFinImpId          ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aNewAmounts in out AmountsRecType
  )
  is
    vRefAmounts AmountsRecType;
  begin
    select nvl(IMP.IMF_AMOUNT_LC_D, 0)
         , nvl(IMP.IMF_AMOUNT_LC_C, 0)
         , nvl(IMP.IMF_AMOUNT_FC_D, 0)
         , nvl(IMP.IMF_AMOUNT_FC_C, 0)
         , nvl(IMP.IMF_AMOUNT_EUR_D, 0)
         , nvl(IMP.IMF_AMOUNT_EUR_C, 0)
      into vRefAmounts
      from ACT_FINANCIAL_IMPUTATION IMP
     where IMP.ACT_FINANCIAL_IMPUTATION_ID = aFinImpId;

    if vRefAmounts.DebitLC != 0 then
      aNewAmounts.DebitLC    := abs(aNewAmounts.DebitLC) * sign(vRefAmounts.DebitLC);
      aNewAmounts.DebitFC    := abs(aNewAmounts.DebitFC) * sign(vRefAmounts.DebitFC);
      aNewAmounts.DebitEUR   := abs(aNewAmounts.DebitEUR) * sign(vRefAmounts.DebitEUR);
      aNewAmounts.CreditLC   := 0;
      aNewAmounts.CreditFC   := 0;
      aNewAmounts.CreditEUR  := 0;
    else
      aNewAmounts.CreditLC   := abs(aNewAmounts.DebitLC) * sign(vRefAmounts.CreditLC);
      aNewAmounts.CreditFC   := abs(aNewAmounts.DebitFC) * sign(vRefAmounts.CreditFC);
      aNewAmounts.CreditEUR  := abs(aNewAmounts.DebitEUR) * sign(vRefAmounts.CreditEUR);
      aNewAmounts.DebitLC    := 0;
      aNewAmounts.DebitFC    := 0;
      aNewAmounts.DebitEUR   := 0;
    end if;
  end InitImpAmounts;

  /**
  * Description
  *   Modification du cours de change des imputations TVA.
  *   Màj des cours et recalcule des montants.
  */
  procedure UpdateTaxExchangeRate(
    aACT_FINANCIAL_IMPUTATION_ID        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aBaseCurrencyId                     ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDocDate                            date
  , aDateReference                      integer
  , aTaxAmounts                         AmountsRecType
  , aTaxTotAmounts                      AmountsRecType
  , aExchangeRate                in out EchangeRateRecType
  )
  is
    vFinImp1        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vFinImp2        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vAutoTaxFinImp1 ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vAutoTaxFinImp2 ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vDedFinImp1     ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vDedFinImp2     ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vResultAmounts  AmountsRecType;
    vFinImp         AmountsRecType;
  begin
    select TAX.ACT_ACT_FINANCIAL_IMPUTATION
         , TAX.ACT2_ACT_FINANCIAL_IMPUTATION
         , TAX.ACT_DED1_FINANCIAL_IMP_ID
         , TAX.ACT_DED2_FINANCIAL_IMP_ID
         , (select min(ACT_FINANCIAL_IMPUTATION_ID)
              from ACT_DET_TAX
             where ACT2_DET_TAX_ID = TAX.ACT_DET_TAX_ID)
         , (select max(ACT_FINANCIAL_IMPUTATION_ID)
              from ACT_DET_TAX
             where ACT2_DET_TAX_ID = TAX.ACT_DET_TAX_ID)
      into vFinImp1
         , vFinImp2
         , vDedFinImp1
         , vDedFinImp2
         , vAutoTaxFinImp1
         , vAutoTaxFinImp2
      from ACT_DET_TAX TAX
     where TAX.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

    if vFinImp1 is not null then
      vFinImp  := aTaxAmounts;
      InitImpAmounts(vFinImp1, vFinImp);
      UpdateImpExchangeRate(vFinImp1, aBaseCurrencyId, aDocDate, aDateReference, vFinImp, aExchangeRate
                          , vResultAmounts);
    end if;

    if vFinImp2 is not null then
      vFinImp  := aTaxAmounts;
      InitImpAmounts(vFinImp2, vFinImp);
      UpdateImpExchangeRate(vFinImp2, aBaseCurrencyId, aDocDate, aDateReference, vFinImp, aExchangeRate
                          , vResultAmounts);
    end if;

    if vDedFinImp1 is not null then
      vFinImp           := aTaxTotAmounts;
      vFinImp.DebitLC   := vFinImp.DebitLC - aTaxAmounts.DebitLC;
      vFinImp.DebitFC   := vFinImp.DebitFC - aTaxAmounts.DebitFC;
      vFinImp.DebitEUR  := vFinImp.DebitEUR - aTaxAmounts.DebitEUR;
      InitImpAmounts(vDedFinImp1, vFinImp);
      UpdateImpExchangeRate(vDedFinImp1
                          , aBaseCurrencyId
                          , aDocDate
                          , aDateReference
                          , vFinImp
                          , aExchangeRate
                          , vResultAmounts
                           );
    end if;

    if vDedFinImp2 is not null then
      vFinImp           := aTaxTotAmounts;
      vFinImp.DebitLC   := vFinImp.DebitLC - aTaxAmounts.DebitLC;
      vFinImp.DebitFC   := vFinImp.DebitFC - aTaxAmounts.DebitFC;
      vFinImp.DebitEUR  := vFinImp.DebitEUR - aTaxAmounts.DebitEUR;
      InitImpAmounts(vDedFinImp2, vFinImp);
      UpdateImpExchangeRate(vDedFinImp2
                          , aBaseCurrencyId
                          , aDocDate
                          , aDateReference
                          , vFinImp
                          , aExchangeRate
                          , vResultAmounts
                           );
    end if;

    if vAutoTaxFinImp1 is not null then
      vFinImp  := aTaxAmounts;
      InitImpAmounts(vAutoTaxFinImp1, vFinImp);
      UpdateImpExchangeRate(vAutoTaxFinImp1
                          , aBaseCurrencyId
                          , aDocDate
                          , aDateReference
                          , vFinImp
                          , aExchangeRate
                          , vResultAmounts
                           );
    end if;

    if vAutoTaxFinImp2 is not null then
      vFinImp  := aTaxAmounts;
      InitImpAmounts(vAutoTaxFinImp2, vFinImp);
      UpdateImpExchangeRate(vAutoTaxFinImp2
                          , aBaseCurrencyId
                          , aDocDate
                          , aDateReference
                          , vFinImp
                          , aExchangeRate
                          , vResultAmounts
                           );
    end if;
  end UpdateTaxExchangeRate;

  /**
  * Description
  *   Ajoute les montants d'un record AmountsRecType à un autre.
  */
  procedure AddAmounts(aAmounts in out AmountsRecType, aAmountsToAdd AmountsRecType)
  is
  begin
    aAmounts.DebitLC    := aAmounts.DebitLC + aAmountsToAdd.DebitLC;
    aAmounts.CreditLC   := aAmounts.CreditLC + aAmountsToAdd.CreditLC;
    aAmounts.DebitFC    := aAmounts.DebitFC + aAmountsToAdd.DebitFC;
    aAmounts.CreditFC   := aAmounts.CreditFC + aAmountsToAdd.CreditFC;
    aAmounts.DebitEUR   := aAmounts.DebitEUR + aAmountsToAdd.DebitEUR;
    aAmounts.CreditEUR  := aAmounts.CreditEUR + aAmountsToAdd.CreditEUR;
  end AddAmounts;

  /**
  * Description
  *   Soustrait les montants d'un record AmountsRecType à un autre.
  */
  procedure SubAmounts(aAmounts in out AmountsRecType, aAmountsToSub AmountsRecType)
  is
  begin
    aAmounts.DebitLC    := aAmounts.DebitLC - aAmountsToSub.DebitLC;
    aAmounts.CreditLC   := aAmounts.CreditLC - aAmountsToSub.CreditLC;
    aAmounts.DebitFC    := aAmounts.DebitFC - aAmountsToSub.DebitFC;
    aAmounts.CreditFC   := aAmounts.CreditFC - aAmountsToSub.CreditFC;
    aAmounts.DebitEUR   := aAmounts.DebitEUR - aAmountsToSub.DebitEUR;
    aAmounts.CreditEUR  := aAmounts.CreditEUR - aAmountsToSub.CreditEUR;
  end SubAmounts;

  /**
  * Description
  *   Modification du cours de change d'une imputation fin et de tout ce qui lui est rattaché.
  *   Màj des cours et recalcule des montants.
  */
  procedure UpdateImpExchangeRate(
    aACT_FINANCIAL_IMPUTATION_ID        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aBaseCurrencyId                     ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDocDate                            date
  , aDateReference                      integer
  , aAmounts                            AmountsRecType
  , aExchangeRate                       EchangeRateRecType
  , aResultAmounts               in out AmountsRecType
  )
  is
    cursor FinImp(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
    is
      select IMP.*
           , (select sign(count(*) )
                from ACT_MGM_IMPUTATION
               where ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) MGM
           , (select sign(count(*) )
                from ACT_FINANCIAL_DISTRIBUTION
               where ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) DIST
           , (select sign(count(*) )
                from ACT_DET_TAX
               where ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) TAX
           , (select sign(count(*) )
                from ACT_DET_TAX
               where ACT2_DET_TAX_ID is not null
                 and ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) AUTOTAX
        from ACT_FINANCIAL_IMPUTATION IMP
       where IMP.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

    cursor MgmImp(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
    is
      select   MGM.*
             , (select sign(count(*) )
                  from ACT_MGM_DISTRIBUTION
                 where ACT_MGM_IMPUTATION_ID = MGM.ACT_MGM_IMPUTATION_ID) DIST
          from ACT_MGM_IMPUTATION MGM
         where MGM.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID
      order by MGM.ACT_MGM_IMPUTATION_ID;

    cursor MgmDist(aACT_MGM_IMPUTATION_ID ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type)
    is
      select   DIST.*
          from ACT_MGM_DISTRIBUTION DIST
         where DIST.ACT_MGM_IMPUTATION_ID = aACT_MGM_IMPUTATION_ID
      order by DIST.ACT_MGM_DISTRIBUTION_ID;

    cursor FinTax(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
    is
      select TAX.*
        from ACT_DET_TAX TAX
       where TAX.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

    tplFinImp         FinImp%rowtype;
    tplFinTax         FinTax%rowtype;
    vMgmImpSum        AmountsRecType;
    vMgmDistSum       AmountsRecType;
    vFinImpPrim       AmountsRecType;
    vFinImpExRatePrim EchangeRateRecType;
    vFinImp           AmountsRecType;
    vFinImpExRate     EchangeRateRecType;
    vTaxLiabled       AmountsRecType;
    vTaxLiabledExRate EchangeRateRecType;
    vTaxImp           AmountsRecType;
    vTaxImpExRate     EchangeRateRecType;
    vTaxTotImp        AmountsRecType;
    vTaxTotImpExRate  EchangeRateRecType;
    vMgmImp           AmountsRecType;
    vMgmImpExRate     EchangeRateRecType;
    vMgmDist          AmountsRecType;
    vMgmDistExRate    EchangeRateRecType;
    vTaxLiabledAmount ACT_DET_TAX.TAX_LIABLED_AMOUNT%type;
    vCountMGM         integer;
    vCountPROJ        integer;
  begin
    --Chargement de l'imputation
    open FinImp(aACT_FINANCIAL_IMPUTATION_ID);

    fetch FinImp
     into tplFinImp;

    close FinImp;

    if aAmounts.DebitLC is null then
      vFinImp.DebitLC             := tplFinImp.IMF_AMOUNT_LC_D;
      vFinImp.CreditLC            := tplFinImp.IMF_AMOUNT_LC_C;
      vFinImp.DebitFC             := tplFinImp.IMF_AMOUNT_FC_D;
      vFinImp.CreditFC            := tplFinImp.IMF_AMOUNT_FC_C;
      vFinImp.DebitEUR            := tplFinImp.IMF_AMOUNT_EUR_D;
      vFinImp.CreditEUR           := tplFinImp.IMF_AMOUNT_EUR_C;
      vFinImpExRate.ExchangeRate  := tplFinImp.IMF_EXCHANGE_RATE;
      vFinImpExRate.BasePrice     := tplFinImp.IMF_BASE_PRICE;
      UpdateAmounts(vFinImp
                  , vFinImpExRate
                  , aBaseCurrencyId
                  , tplFinImp.ACS_FINANCIAL_CURRENCY_ID
                  , tplFinImp.ACS_ACS_FINANCIAL_CURRENCY_ID
                  , GetRefDate(aDateReference, aDocDate, tplFinImp.IMF_TRANSACTION_DATE, tplFinImp.IMF_VALUE_DATE)
                   );
    else
      vFinImp        := aAmounts;
      vFinImpExRate  := aExchangeRate;
    end if;

    --Màj imputation financière
    update ACT_FINANCIAL_IMPUTATION
       set IMF_AMOUNT_EUR_C = vFinImp.CreditEUR
         , IMF_AMOUNT_EUR_D = vFinImp.DebitEUR
         , IMF_AMOUNT_FC_C = vFinImp.CreditFC
         , IMF_AMOUNT_FC_D = vFinImp.DebitFC
         , IMF_AMOUNT_LC_C = vFinImp.CreditLC
         , IMF_AMOUNT_LC_D = vFinImp.DebitLC
         , IMF_BASE_PRICE = vFinImpExRate.BasePrice
         , IMF_EXCHANGE_RATE = vFinImpExRate.ExchangeRate
     where ACT_FINANCIAL_IMPUTATION_ID = tplFinImp.ACT_FINANCIAL_IMPUTATION_ID;

    --Màj distribution financière
    if tplFinImp.DIST = 1 then
      update ACT_FINANCIAL_DISTRIBUTION
         set FIN_AMOUNT_EUR_C = vFinImp.CreditEUR
           , FIN_AMOUNT_EUR_D = vFinImp.DebitEUR
           , FIN_AMOUNT_FC_C = vFinImp.CreditFC
           , FIN_AMOUNT_FC_D = vFinImp.DebitFC
           , FIN_AMOUNT_LC_C = vFinImp.CreditLC
           , FIN_AMOUNT_LC_D = vFinImp.DebitLC
       where ACT_FINANCIAL_IMPUTATION_ID = tplFinImp.ACT_FINANCIAL_IMPUTATION_ID;
    end if;

    --Màj détail taxe
    if tplFinImp.TAX = 1 then
      open FinTax(tplFinImp.ACT_FINANCIAL_IMPUTATION_ID);

      fetch FinTax
       into tplFinTax;

      close FinTax;

      if tplFinTax.TAX_LIABLED_RATE != 100 then
        vTaxLiabled.DebitLC             := tplFinTax.TAX_LIABLED_AMOUNT;
        vTaxLiabledExRate.ExchangeRate  := tplFinTax.TAX_EXCHANGE_RATE;
        vTaxLiabledExRate.BasePrice     := tplFinTax.DET_BASE_PRICE;
        UpdateAmounts(vTaxLiabled
                    , vTaxLiabledExRate
                    , aBaseCurrencyId
                    , tplFinImp.ACS_FINANCIAL_CURRENCY_ID
                    , tplFinImp.ACS_ACS_FINANCIAL_CURRENCY_ID
                    , GetRefDate(aDateReference, aDocDate, tplFinImp.IMF_TRANSACTION_DATE, tplFinImp.IMF_VALUE_DATE)
                     );
        vTaxLiabledAmount               := vTaxLiabled.DebitLC;
      else
        vTaxLiabledAmount  := abs(vFinImp.DebitLC + vFinImp.CreditLC) * sign(tplFinTax.TAX_LIABLED_AMOUNT);
      end if;

      vTaxImp.DebitLC             := tplFinTax.TAX_VAT_AMOUNT_LC;
      vTaxImp.DebitFC             := tplFinTax.TAX_VAT_AMOUNT_FC;
      vTaxImp.DebitEUR            := tplFinTax.TAX_VAT_AMOUNT_EUR;
      vTaxImpExRate.ExchangeRate  := tplFinTax.TAX_EXCHANGE_RATE;
      vTaxImpExRate.BasePrice     := tplFinTax.DET_BASE_PRICE;
      UpdateAmounts(vTaxImp
                  , vTaxImpExRate
                  , aBaseCurrencyId
                  , tplFinImp.ACS_FINANCIAL_CURRENCY_ID
                  , tplFinImp.ACS_ACS_FINANCIAL_CURRENCY_ID
                  , GetRefDate(aDateReference, aDocDate, tplFinImp.IMF_TRANSACTION_DATE, tplFinImp.IMF_VALUE_DATE)
                  , 6
                   );

      if tplFinTax.TAX_VAT_AMOUNT_LC != tplFinTax.TAX_TOT_VAT_AMOUNT_LC then
        vTaxTotImp.DebitLC             := tplFinTax.TAX_TOT_VAT_AMOUNT_LC;
        vTaxTotImp.DebitFC             := tplFinTax.TAX_TOT_VAT_AMOUNT_FC;
        vTaxTotImp.DebitEUR            := tplFinTax.TAX_TOT_VAT_AMOUNT_EUR;
        vTaxTotImpExRate.ExchangeRate  := tplFinTax.TAX_EXCHANGE_RATE;
        vTaxTotImpExRate.BasePrice     := tplFinTax.DET_BASE_PRICE;
        UpdateAmounts(vTaxTotImp
                    , vTaxTotImpExRate
                    , aBaseCurrencyId
                    , tplFinImp.ACS_FINANCIAL_CURRENCY_ID
                    , tplFinImp.ACS_ACS_FINANCIAL_CURRENCY_ID
                    , GetRefDate(aDateReference, aDocDate, tplFinImp.IMF_TRANSACTION_DATE, tplFinImp.IMF_VALUE_DATE)
                    , 6
                     );
      end if;

      update ACT_DET_TAX
         set DET_BASE_PRICE = vTaxImpExRate.BasePrice
           , TAX_EXCHANGE_RATE = vTaxImpExRate.ExchangeRate
           , TAX_LIABLED_AMOUNT = vTaxLiabledAmount
           , TAX_TOT_VAT_AMOUNT_EUR = vTaxTotImp.DebitEUR
           , TAX_TOT_VAT_AMOUNT_FC = vTaxTotImp.DebitFC
           , TAX_TOT_VAT_AMOUNT_LC = vTaxTotImp.DebitLC
           , TAX_VAT_AMOUNT_EUR = vTaxImp.DebitEUR
           , TAX_VAT_AMOUNT_FC = vTaxImp.DebitFC
           , TAX_VAT_AMOUNT_LC = vTaxImp.DebitLC
       where ACT_DET_TAX_ID = tplFinTax.ACT_DET_TAX_ID;

      --Màj imputations TVA
      UpdateTaxExchangeRate(tplFinImp.ACT_FINANCIAL_IMPUTATION_ID
                          , aBaseCurrencyId
                          , aDocDate
                          , aDateReference
                          , vTaxImp
                          , vTaxTotImp
                          , vTaxImpExRate
                           );
    end if;

    --Màj imputation analytique
    if tplFinImp.MGM = 1 then
      --Somme des imputations
      select count(*)
        into vCountMGM
        from ACT_MGM_IMPUTATION MGM
       where MGM.ACT_FINANCIAL_IMPUTATION_ID = tplFinImp.ACT_FINANCIAL_IMPUTATION_ID;

      for tplMgmImp in MgmImp(tplFinImp.ACT_FINANCIAL_IMPUTATION_ID) loop
        vMgmImpExRate.ExchangeRate  := tplMgmImp.IMM_EXCHANGE_RATE;
        vMgmImpExRate.BasePrice     := tplMgmImp.IMM_BASE_PRICE;

        if vCountMGM > 1 then
          vMgmImp.DebitLC    := tplMgmImp.IMM_AMOUNT_LC_D;
          vMgmImp.CreditLC   := tplMgmImp.IMM_AMOUNT_LC_C;
          vMgmImp.DebitFC    := tplMgmImp.IMM_AMOUNT_FC_D;
          vMgmImp.CreditFC   := tplMgmImp.IMM_AMOUNT_FC_C;
          vMgmImp.DebitEUR   := tplMgmImp.IMM_AMOUNT_EUR_D;
          vMgmImp.CreditEUR  := tplMgmImp.IMM_AMOUNT_EUR_C;
          UpdateAmounts(vMgmImp
                      , vMgmImpExRate
                      , aBaseCurrencyId
                      , tplMgmImp.ACS_FINANCIAL_CURRENCY_ID
                      , tplMgmImp.ACS_ACS_FINANCIAL_CURRENCY_ID
                      , GetRefDate(aDateReference, aDocDate, tplMgmImp.IMM_TRANSACTION_DATE, tplMgmImp.IMM_VALUE_DATE)
                       );
          AddAmounts(vMgmImpSum, vMgmImp);
        else
          vMgmImp  := vFinImp;
          SubAmounts(vMgmImp, vMgmImpSum);
        end if;

        update ACT_MGM_IMPUTATION
           set IMM_AMOUNT_EUR_C = vMgmImp.CreditEUR
             , IMM_AMOUNT_EUR_D = vMgmImp.DebitEUR
             , IMM_AMOUNT_FC_C = vMgmImp.CreditFC
             , IMM_AMOUNT_FC_D = vMgmImp.DebitFC
             , IMM_AMOUNT_LC_C = vMgmImp.CreditLC
             , IMM_AMOUNT_LC_D = vMgmImp.DebitLC
             , IMM_BASE_PRICE = vMgmImpExRate.BasePrice
             , IMM_EXCHANGE_RATE = vMgmImpExRate.ExchangeRate
         where ACT_MGM_IMPUTATION_ID = tplMgmImp.ACT_MGM_IMPUTATION_ID;

        --Màj distribution analytique
        if tplMgmImp.DIST = 1 then
          --Somme des imputations
          select count(*)
            into vCountPROJ
            from ACT_MGM_DISTRIBUTION DIST
           where DIST.ACT_MGM_IMPUTATION_ID = tplMgmImp.ACT_MGM_IMPUTATION_ID;

          for tplMgmDist in MgmDist(tplMgmImp.ACT_MGM_IMPUTATION_ID) loop
            vMgmDistExRate.ExchangeRate  := tplMgmImp.IMM_EXCHANGE_RATE;
            vMgmDistExRate.BasePrice     := tplMgmImp.IMM_BASE_PRICE;

            if vCountPROJ > 1 then
              vMgmDist.DebitLC    := tplMgmDist.MGM_AMOUNT_LC_D;
              vMgmDist.CreditLC   := tplMgmDist.MGM_AMOUNT_LC_C;
              vMgmDist.DebitFC    := tplMgmDist.MGM_AMOUNT_FC_D;
              vMgmDist.CreditFC   := tplMgmDist.MGM_AMOUNT_FC_C;
              vMgmDist.DebitEUR   := tplMgmDist.MGM_AMOUNT_EUR_D;
              vMgmDist.CreditEUR  := tplMgmDist.MGM_AMOUNT_EUR_C;
              UpdateAmounts(vMgmDist
                          , vMgmDistExRate
                          , aBaseCurrencyId
                          , tplMgmImp.ACS_FINANCIAL_CURRENCY_ID
                          , tplMgmImp.ACS_ACS_FINANCIAL_CURRENCY_ID
                          , GetRefDate(aDateReference
                                     , aDocDate
                                     , tplMgmImp.IMM_TRANSACTION_DATE
                                     , tplMgmImp.IMM_VALUE_DATE
                                      )
                           );
              AddAmounts(vMgmDistSum, vMgmDist);
            else
              vMgmDist  := vMgmImp;
              SubAmounts(vMgmDist, vMgmDistSum);
            end if;

            update ACT_MGM_DISTRIBUTION
               set MGM_AMOUNT_EUR_C = vMgmDist.CreditEUR
                 , MGM_AMOUNT_EUR_D = vMgmDist.DebitEUR
                 , MGM_AMOUNT_FC_C = vMgmDist.CreditFC
                 , MGM_AMOUNT_FC_D = vMgmDist.DebitFC
                 , MGM_AMOUNT_LC_C = vMgmDist.CreditLC
                 , MGM_AMOUNT_LC_D = vMgmDist.DebitLC
             where ACT_MGM_DISTRIBUTION_ID = tplMgmDist.ACT_MGM_DISTRIBUTION_ID;

            vCountPROJ                   := vCountPROJ - 1;
          end loop;
        end if;

        vCountMGM                   := vCountMGM - 1;
      end loop;
    end if;

    aResultAmounts  := vFinImp;
  end UpdateImpExchangeRate;

  /**
  * Description
  *   Modification du cours de change des imputation anal. et des projets d'un documents.
  *   Màj des cours et recalcule des montants.
  */
  procedure UpdateMgmExchangeRate(
    aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aBaseCurrencyId  ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDocDate         date
  , aDateReference   integer
  )
  is
    cursor MgmImp(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   MGM.*
             , (select sign(count(*) )
                  from ACT_MGM_DISTRIBUTION
                 where ACT_MGM_IMPUTATION_ID = MGM.ACT_MGM_IMPUTATION_ID) DIST
          from ACT_MGM_IMPUTATION MGM
         where MGM.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and MGM.ACT_FINANCIAL_IMPUTATION_ID is null
      order by MGM.ACT_MGM_IMPUTATION_ID;

    cursor MgmDist(aACT_MGM_IMPUTATION_ID ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type)
    is
      select   DIST.*
          from ACT_MGM_DISTRIBUTION DIST
         where DIST.ACT_MGM_IMPUTATION_ID = aACT_MGM_IMPUTATION_ID
      order by DIST.ACT_MGM_DISTRIBUTION_ID;

    vMgmImp        AmountsRecType;
    vMgmImpExRate  EchangeRateRecType;
    vMgmDist       AmountsRecType;
    vMgmDistExRate EchangeRateRecType;
    vMgmDistSum    AmountsRecType;
    vCountPROJ     integer;
  begin
    for tplMgmImp in MgmImp(aACT_DOCUMENT_ID) loop
      vMgmImpExRate.ExchangeRate  := tplMgmImp.IMM_EXCHANGE_RATE;
      vMgmImpExRate.BasePrice     := tplMgmImp.IMM_BASE_PRICE;
      vMgmImp.DebitLC             := tplMgmImp.IMM_AMOUNT_LC_D;
      vMgmImp.CreditLC            := tplMgmImp.IMM_AMOUNT_LC_C;
      vMgmImp.DebitFC             := tplMgmImp.IMM_AMOUNT_FC_D;
      vMgmImp.CreditFC            := tplMgmImp.IMM_AMOUNT_FC_C;
      vMgmImp.DebitEUR            := tplMgmImp.IMM_AMOUNT_EUR_D;
      vMgmImp.CreditEUR           := tplMgmImp.IMM_AMOUNT_EUR_C;
      UpdateAmounts(vMgmImp
                  , vMgmImpExRate
                  , aBaseCurrencyId
                  , tplMgmImp.ACS_FINANCIAL_CURRENCY_ID
                  , tplMgmImp.ACS_ACS_FINANCIAL_CURRENCY_ID
                  , GetRefDate(aDateReference, aDocDate, tplMgmImp.IMM_TRANSACTION_DATE, tplMgmImp.IMM_VALUE_DATE)
                   );

      update ACT_MGM_IMPUTATION
         set IMM_AMOUNT_EUR_C = vMgmImp.CreditEUR
           , IMM_AMOUNT_EUR_D = vMgmImp.DebitEUR
           , IMM_AMOUNT_FC_C = vMgmImp.CreditFC
           , IMM_AMOUNT_FC_D = vMgmImp.DebitFC
           , IMM_AMOUNT_LC_C = vMgmImp.CreditLC
           , IMM_AMOUNT_LC_D = vMgmImp.DebitLC
           , IMM_BASE_PRICE = vMgmImpExRate.BasePrice
           , IMM_EXCHANGE_RATE = vMgmImpExRate.ExchangeRate
       where ACT_MGM_IMPUTATION_ID = tplMgmImp.ACT_MGM_IMPUTATION_ID;

      --Màj distribution analytique
      if tplMgmImp.DIST = 1 then
        --Somme des imputations
        select count(*)
          into vCountPROJ
          from ACT_MGM_DISTRIBUTION DIST
         where DIST.ACT_MGM_IMPUTATION_ID = tplMgmImp.ACT_MGM_IMPUTATION_ID;

        for tplMgmDist in MgmDist(tplMgmImp.ACT_MGM_IMPUTATION_ID) loop
          vMgmDistExRate.ExchangeRate  := tplMgmImp.IMM_EXCHANGE_RATE;
          vMgmDistExRate.BasePrice     := tplMgmImp.IMM_BASE_PRICE;

          if vCountPROJ > 1 then
            vMgmDist.DebitLC    := tplMgmDist.MGM_AMOUNT_LC_D;
            vMgmDist.CreditLC   := tplMgmDist.MGM_AMOUNT_LC_C;
            vMgmDist.DebitFC    := tplMgmDist.MGM_AMOUNT_FC_D;
            vMgmDist.CreditFC   := tplMgmDist.MGM_AMOUNT_FC_C;
            vMgmDist.DebitEUR   := tplMgmDist.MGM_AMOUNT_EUR_D;
            vMgmDist.CreditEUR  := tplMgmDist.MGM_AMOUNT_EUR_C;
            UpdateAmounts(vMgmDist
                        , vMgmDistExRate
                        , aBaseCurrencyId
                        , tplMgmImp.ACS_FINANCIAL_CURRENCY_ID
                        , tplMgmImp.ACS_ACS_FINANCIAL_CURRENCY_ID
                        , GetRefDate(aDateReference, aDocDate, tplMgmImp.IMM_TRANSACTION_DATE, tplMgmImp.IMM_VALUE_DATE)
                         );
            AddAmounts(vMgmDistSum, vMgmDist);
          else
            vMgmDist  := vMgmImp;
            SubAmounts(vMgmDist, vMgmDistSum);
          end if;

          update ACT_MGM_DISTRIBUTION
             set MGM_AMOUNT_EUR_C = vMgmDist.CreditEUR
               , MGM_AMOUNT_EUR_D = vMgmDist.DebitEUR
               , MGM_AMOUNT_FC_C = vMgmDist.CreditFC
               , MGM_AMOUNT_FC_D = vMgmDist.DebitFC
               , MGM_AMOUNT_LC_C = vMgmDist.CreditLC
               , MGM_AMOUNT_LC_D = vMgmDist.DebitLC
           where ACT_MGM_DISTRIBUTION_ID = tplMgmDist.ACT_MGM_DISTRIBUTION_ID;

          vCountPROJ                   := vCountPROJ - 1;
        end loop;
      end if;
    end loop;
  end UpdateMgmExchangeRate;

  /**
  * Description
  *   Modification du cours de change d'un document.
  *   Màj des cours et recalcule des montants.
  */
  procedure UpdateDocExchangeRate(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type, aDateReference integer)
  is
    cursor FinImp(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   IMP.*
             , (select sign(count(*) )
                  from ACT_MGM_IMPUTATION
                 where ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) MGM
             , (select sign(count(*) )
                  from ACT_FINANCIAL_DISTRIBUTION
                 where ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) DIST
             , (select sign(count(*) )
                  from ACT_DET_TAX
                 where ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) TAX
             , (select sign(count(*) )
                  from ACT_DET_TAX
                 where ACT2_DET_TAX_ID is not null
                   and ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) AUTOTAX
          from ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and IMP.IMF_TYPE <> 'VAT'
           and IMP.IMF_PRIMARY = 0
           and not exists(select 0
                            from ACT_DET_TAX
                           where ACT2_DET_TAX_ID = (select ACT_DET_TAX_ID
                                                      from ACT_DET_TAX
                                                     where ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID) )
      order by IMP.ACT_FINANCIAL_IMPUTATION_ID;

    vtplFinImpPrim          ACT_FINANCIAL_IMPUTATION%rowtype;
    vtplDoc                 ACT_DOCUMENT%rowtype;
    vFinImpPrim             AmountsRecType;
    vFinImpExRatePrim       EchangeRateRecType;
    vACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    vResultAmounts          AmountsRecType;
    vTotAmounts             AmountsRecType;
    vMgmOnly                boolean;
  begin
    if     (aDateReference > 0)
       and HasForeignCurrency(aACT_DOCUMENT_ID) then

      --Info document
      select DOC.*
        into vtplDoc
        from ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      --Recalcule imputation primaire
      begin
        select *
          into vtplFinImpPrim
          from ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and IMP.IMF_PRIMARY = 1;

        vMgmOnly  := false;
      exception
        when no_data_found then
          vMgmOnly  := true;
      end;

      if vMgmOnly then
        --Màj analytique seulement
        UpdateMgmExchangeRate(aACT_DOCUMENT_ID
                            , vtplDoc.ACS_FINANCIAL_CURRENCY_ID
                            , vtplDoc.DOC_DOCUMENT_DATE
                            , aDateReference
                             );
      else
        --Màj imputation financière
        UpdateImpExchangeRate(vtplFinImpPrim.ACT_FINANCIAL_IMPUTATION_ID
                            , vtplDoc.ACS_FINANCIAL_CURRENCY_ID
                            , vtplDoc.DOC_DOCUMENT_DATE
                            , aDateReference
                            , null
                            , null
                            , vFinImpPrim
                             );

        for vtplFinImp in FinImp(aACT_DOCUMENT_ID) loop
          UpdateImpExchangeRate(vtplFinImp.ACT_FINANCIAL_IMPUTATION_ID
                              , vtplDoc.ACS_FINANCIAL_CURRENCY_ID
                              , vtplDoc.DOC_DOCUMENT_DATE
                              , aDateReference
                              , null
                              , null
                              , vResultAmounts
                               );
        end loop;

        --Partenaire des échéances
        select min(ACT_PART_IMPUTATION_ID)
          into vACT_PART_IMPUTATION_ID
          from ACT_EXPIRY
         where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

        if vACT_PART_IMPUTATION_ID is not null then
          --Màj des échéances
          ACT_EXPIRY_MANAGEMENT.GenerateUpdatedExpiriesACT(vACT_PART_IMPUTATION_ID, 1, 0, 0, 0, 0);
        end if;
      end if;
    end if;
  end UpdateDocExchangeRate;
end ACT_DOC_TRANSACTION;
