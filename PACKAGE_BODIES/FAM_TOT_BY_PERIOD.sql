--------------------------------------------------------
--  DDL for Package Body FAM_TOT_BY_PERIOD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAM_TOT_BY_PERIOD" 
is
  function GetDocumentTransactionTyp(aFAM_DOCUMENT_ID in FAM_DOCUMENT.FAM_DOCUMENT_ID%type)
    return FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type
  is
    vResult FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type;
  begin
    begin
      select CAT.C_FAM_TRANSACTION_TYP
        into vResult
        from FAM_CATALOGUE CAT
           , FAM_DOCUMENT DOC
       where DOC.FAM_DOCUMENT_ID = aFAM_DOCUMENT_ID
         and DOC.FAM_CATALOGUE_ID = CAT.FAM_CATALOGUE_ID;
    exception
      when ex.TABLE_MUTATING then
        select CAT.C_FAM_TRANSACTION_TYP
          into vResult
          from FAM_CATALOGUE CAT
         where CAT.FAM_CATALOGUE_ID = FAM_TOT_BY_PERIOD.gCatalogIdOfDeletedDocument;
    end;

    return vResult;
  end GetDocumentTransactionTyp;

  procedure WriteFamTotalByPeriod(
    aFAM_FIXED_ASSETS_ID        FAM_TOTAL_BY_PERIOD.FAM_FIXED_ASSETS_ID%type
  , aFAM_FIXED_ASSETS_CATEG_ID  FAM_TOTAL_BY_PERIOD.FAM_FIXED_ASSETS_CATEG_ID%type
  , aFAM_MANAGED_VALUE_ID       FAM_TOTAL_BY_PERIOD.FAM_MANAGED_VALUE_ID%type
  , aACS_PERIOD_ID              FAM_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , aLACS_FINANCIAL_CURRENCY_ID FAM_TOTAL_BY_PERIOD.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aC_FAM_TRANSACTION_TYP      FAM_TOTAL_BY_PERIOD.C_FAM_TRANSACTION_TYP%type
  , aFTO_DEBIT_LC               FAM_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type
  , aFTO_CREDIT_LC              FAM_TOTAL_BY_PERIOD.FTO_CREDIT_LC%type
  )
  is
    id FAM_TOTAL_BY_PERIOD.FAM_TOTAL_BY_PERIOD_ID%type;
  -----
  begin
    if     aFAM_FIXED_ASSETS_ID is not null
       and aFAM_MANAGED_VALUE_ID is not null
       and aACS_PERIOD_ID is not null
       and aLACS_FINANCIAL_CURRENCY_ID is not null
       and aC_FAM_TRANSACTION_TYP is not null then
      begin
        select FAM_TOTAL_BY_PERIOD_ID
          into id
          from FAM_TOTAL_BY_PERIOD
         where FAM_FIXED_ASSETS_ID = aFAM_FIXED_ASSETS_ID
           and FAM_MANAGED_VALUE_ID = aFAM_MANAGED_VALUE_ID
           and ACS_PERIOD_ID = aACS_PERIOD_ID
           and ACS_ACS_FINANCIAL_CURRENCY_ID = aLACS_FINANCIAL_CURRENCY_ID
           and C_FAM_TRANSACTION_TYP = aC_FAM_TRANSACTION_TYP;
      exception
        when no_data_found then
          id  := 0;
      end;

      if id > 0 then
        update FAM_TOTAL_BY_PERIOD
           set FTO_DEBIT_LC =
                 decode(sign(FTO_DEBIT_LC - FTO_CREDIT_LC + nvl(aFTO_DEBIT_LC, 0) - nvl(aFTO_CREDIT_LC, 0) )
                      , 1, FTO_DEBIT_LC - FTO_CREDIT_LC + nvl(aFTO_DEBIT_LC, 0) - nvl(aFTO_CREDIT_LC, 0)
                      , 0
                       )
             , FTO_CREDIT_LC =
                 decode(sign(FTO_CREDIT_LC - FTO_DEBIT_LC + nvl(aFTO_CREDIT_LC, 0) - nvl(aFTO_DEBIT_LC, 0) )
                      , 1, FTO_CREDIT_LC - FTO_DEBIT_LC + nvl(aFTO_CREDIT_LC, 0) - nvl(aFTO_DEBIT_LC, 0)
                      , 0
                       )
             , A_DATEMOD = sysdate
             , A_IDMOD = gUserIni
         where FAM_TOTAL_BY_PERIOD_ID = id;
      else
        select INIT_ID_SEQ.nextval
          into id
          from dual;

        insert into FAM_TOTAL_BY_PERIOD
                    (FAM_TOTAL_BY_PERIOD_ID
                   , FAM_FIXED_ASSETS_ID
                   , FAM_MANAGED_VALUE_ID
                   , FAM_FIXED_ASSETS_CATEG_ID
                   , ACS_PERIOD_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , C_FAM_TRANSACTION_TYP
                   , FTO_DEBIT_LC
                   , FTO_CREDIT_LC
                   , FTO_DEBIT_FC
                   , FTO_CREDIT_FC
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (id
                   , aFAM_FIXED_ASSETS_ID
                   , aFAM_MANAGED_VALUE_ID
                   , aFAM_FIXED_ASSETS_CATEG_ID
                   , aACS_PERIOD_ID
                   , aLACS_FINANCIAL_CURRENCY_ID
                   , aLACS_FINANCIAL_CURRENCY_ID
                   , aC_FAM_TRANSACTION_TYP
                   , nvl(aFTO_DEBIT_LC, 0)
                   , nvl(aFTO_CREDIT_LC, 0)
                   , 0
                   , 0
                   , sysdate
                   , gUserIni
                    );
      end if;
    end if;
  end WriteFamTotalByPeriod;

---------------------------------
  procedure UpdateACT_TotalByPeriod(
    aFAM_DOCUMENT_ID             FAM_DOCUMENT.FAM_DOCUMENT_ID%type
  , aFAM_FIXED_ASSETS1_ID        FAM_ACT_TOTAL_BY_PERIOD.FAM_FIXED_ASSETS_ID%type
  , aFAM_FIXED_ASSETS2_ID        FAM_ACT_TOTAL_BY_PERIOD.FAM_FIXED_ASSETS_ID%type
  , aACS_PERIOD1_ID              FAM_ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , aACS_PERIOD2_ID              FAM_ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , aACS_FINANCIAL_CURRENCY1_ID  FAM_ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_FINANCIAL_CURRENCY2_ID  FAM_ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type
  , aC_FAM_IMPUTATION1_TYP       FAM_ACT_TOTAL_BY_PERIOD.C_FAM_IMPUTATION_TYP%type
  , aC_FAM_IMPUTATION2_TYP       FAM_ACT_TOTAL_BY_PERIOD.C_FAM_IMPUTATION_TYP%type
  , aACS_FINANCIAL_ACCOUNT1_ID   FAM_ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_FINANCIAL_ACCOUNT2_ID   FAM_ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT1_ID    FAM_ACT_TOTAL_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT2_ID    FAM_ACT_TOTAL_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
  , aACS_CPN_ACCOUNT1_ID         FAM_ACT_TOTAL_BY_PERIOD.ACS_CPN_ACCOUNT_ID%type
  , aACS_CPN_ACCOUNT2_ID         FAM_ACT_TOTAL_BY_PERIOD.ACS_CPN_ACCOUNT_ID%type
  , aACS_CDA_ACCOUNT1_ID         FAM_ACT_TOTAL_BY_PERIOD.ACS_CDA_ACCOUNT_ID%type
  , aACS_CDA_ACCOUNT2_ID         FAM_ACT_TOTAL_BY_PERIOD.ACS_CDA_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT1_ID          FAM_ACT_TOTAL_BY_PERIOD.ACS_PF_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT2_ID          FAM_ACT_TOTAL_BY_PERIOD.ACS_PF_ACCOUNT_ID%type
  , aACS_PJ_ACCOUNT1_ID          FAM_ACT_TOTAL_BY_PERIOD.ACS_PJ_ACCOUNT_ID%type
  , aACS_PJ_ACCOUNT2_ID          FAM_ACT_TOTAL_BY_PERIOD.ACS_PJ_ACCOUNT_ID%type
  , aFTO_DEBIT1_LC               FAM_ACT_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type
  , aFTO_DEBIT2_LC               FAM_ACT_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type
  , aFTO_CREDIT1_LC              FAM_ACT_TOTAL_BY_PERIOD.FTO_CREDIT_LC%type
  , aFTO_CREDIT2_LC              FAM_ACT_TOTAL_BY_PERIOD.FTO_CREDIT_LC%type
  )
  is
    FamTransaction FAM_CATALOGUE.C_FAM_TRANSACTION_TYP%type;
  -----
  begin
    begin
      select CAT.C_FAM_TRANSACTION_TYP
        into FamTransaction
        from FAM_CATALOGUE CAT
           , FAM_DOCUMENT DOC
       where DOC.FAM_DOCUMENT_ID = aFAM_DOCUMENT_ID
         and DOC.FAM_CATALOGUE_ID = CAT.FAM_CATALOGUE_ID;
    exception
      when ex.TABLE_MUTATING then
        select CAT.C_FAM_TRANSACTION_TYP
          into FamTransaction
          from FAM_CATALOGUE CAT
         where CAT.FAM_CATALOGUE_ID = FAM_TOT_BY_PERIOD.gCatalogIdOfDeletedDocument;
    end;

    FAM_TOT_BY_PERIOD.WriteFamActTotalByPeriod(aFAM_FIXED_ASSETS1_ID
                                             , aACS_PERIOD1_ID
                                             , aACS_FINANCIAL_CURRENCY1_ID
                                             , FamTransaction
                                             , aC_FAM_IMPUTATION1_TYP
                                             , aACS_FINANCIAL_ACCOUNT1_ID
                                             , aACS_DIVISION_ACCOUNT1_ID
                                             , aACS_CPN_ACCOUNT1_ID
                                             , aACS_CDA_ACCOUNT1_ID
                                             , aACS_PF_ACCOUNT1_ID
                                             , aACS_PJ_ACCOUNT1_ID
                                             , -aFTO_DEBIT1_LC
                                             , -aFTO_CREDIT1_LC
                                              );
    FAM_TOT_BY_PERIOD.WriteFamActTotalByPeriod(aFAM_FIXED_ASSETS2_ID
                                             , aACS_PERIOD2_ID
                                             , aACS_FINANCIAL_CURRENCY2_ID
                                             , FamTransaction
                                             , aC_FAM_IMPUTATION2_TYP
                                             , aACS_FINANCIAL_ACCOUNT2_ID
                                             , aACS_DIVISION_ACCOUNT2_ID
                                             , aACS_CPN_ACCOUNT2_ID
                                             , aACS_CDA_ACCOUNT2_ID
                                             , aACS_PF_ACCOUNT2_ID
                                             , aACS_PJ_ACCOUNT2_ID
                                             , aFTO_DEBIT2_LC
                                             , aFTO_CREDIT2_LC
                                              );
  end UpdateACT_TotalByPeriod;

--------------------------------
  procedure WriteFamActTotalByPeriod(
    aFAM_FIXED_ASSETS_ID        in FAM_ACT_TOTAL_BY_PERIOD.FAM_FIXED_ASSETS_ID%type
  , aACS_PERIOD_ID              in FAM_ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , aLACS_FINANCIAL_CURRENCY_ID in FAM_ACT_TOTAL_BY_PERIOD.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aC_FAM_TRANSACTION_TYP      in FAM_ACT_TOTAL_BY_PERIOD.C_FAM_TRANSACTION_TYP%type
  , aC_FAM_IMPUTATION_TYP       in FAM_ACT_TOTAL_BY_PERIOD.C_FAM_IMPUTATION_TYP%type
  , aACS_FINANCIAL_ACCOUNT_ID   in FAM_ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID    in FAM_ACT_TOTAL_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
  , aACS_CPN_ACCOUNT_ID         in FAM_ACT_TOTAL_BY_PERIOD.ACS_CPN_ACCOUNT_ID%type
  , aACS_CDA_ACCOUNT_ID         in FAM_ACT_TOTAL_BY_PERIOD.ACS_CDA_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT_ID          in FAM_ACT_TOTAL_BY_PERIOD.ACS_PF_ACCOUNT_ID%type
  , aACS_PJ_ACCOUNT_ID          in FAM_ACT_TOTAL_BY_PERIOD.ACS_PJ_ACCOUNT_ID%type
  , aFTO_DEBIT_LC               in FAM_ACT_TOTAL_BY_PERIOD.FTO_DEBIT_LC%type
  , aFTO_CREDIT_LC              in FAM_ACT_TOTAL_BY_PERIOD.FTO_CREDIT_LC%type
  )
  is
    vFamTotalByPeriodId FAM_ACT_TOTAL_BY_PERIOD.FAM_ACT_TOTAL_BY_PERIOD_ID%type;
  begin
    if     aFAM_FIXED_ASSETS_ID is not null
       and aACS_PERIOD_ID is not null
       and aLACS_FINANCIAL_CURRENCY_ID is not null
       and aC_FAM_TRANSACTION_TYP is not null
       and aC_FAM_IMPUTATION_TYP is not null then
      select nvl(max(FAM_ACT_TOTAL_BY_PERIOD_ID), 0)
        into vFamTotalByPeriodId
        from FAM_ACT_TOTAL_BY_PERIOD
       where FAM_FIXED_ASSETS_ID = aFAM_FIXED_ASSETS_ID
         and ACS_PERIOD_ID = aACS_PERIOD_ID
         and ACS_ACS_FINANCIAL_CURRENCY_ID = aLACS_FINANCIAL_CURRENCY_ID
         and C_FAM_TRANSACTION_TYP = aC_FAM_TRANSACTION_TYP
         and C_FAM_IMPUTATION_TYP = aC_FAM_IMPUTATION_TYP
         and (    (    aACS_FINANCIAL_ACCOUNT_ID is null
                   and ACS_FINANCIAL_ACCOUNT_ID is null)
              or (    aACS_FINANCIAL_ACCOUNT_ID is not null
                  and ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID)
             )
         and (    (    aACS_DIVISION_ACCOUNT_ID is null
                   and ACS_DIVISION_ACCOUNT_ID is null)
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
             )
         and (    (    aACS_CPN_ACCOUNT_ID is null
                   and ACS_CPN_ACCOUNT_ID is null)
              or (    aACS_CPN_ACCOUNT_ID is not null
                  and ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID)
             )
         and (    (    aACS_CDA_ACCOUNT_ID is null
                   and ACS_CDA_ACCOUNT_ID is null)
              or (    aACS_CDA_ACCOUNT_ID is not null
                  and ACS_CDA_ACCOUNT_ID = aACS_CDA_ACCOUNT_ID)
             )
         and (    (    aACS_PF_ACCOUNT_ID is null
                   and ACS_PF_ACCOUNT_ID is null)
              or (    aACS_PF_ACCOUNT_ID is not null
                  and ACS_PF_ACCOUNT_ID = aACS_PF_ACCOUNT_ID)
             )
         and (    (    aACS_PJ_ACCOUNT_ID is null
                   and ACS_PJ_ACCOUNT_ID is null)
              or (    aACS_PJ_ACCOUNT_ID is not null
                  and ACS_PJ_ACCOUNT_ID = aACS_PJ_ACCOUNT_ID)
             );

      if vFamTotalByPeriodId > 0 then
        update FAM_ACT_TOTAL_BY_PERIOD
           set FTO_DEBIT_LC =
                 decode(sign(FTO_DEBIT_LC - FTO_CREDIT_LC + nvl(aFTO_DEBIT_LC, 0) - nvl(aFTO_CREDIT_LC, 0) )
                      , 1, FTO_DEBIT_LC - FTO_CREDIT_LC + nvl(aFTO_DEBIT_LC, 0) - nvl(aFTO_CREDIT_LC, 0)
                      , 0
                       )
             , FTO_CREDIT_LC =
                 decode(sign(FTO_CREDIT_LC - FTO_DEBIT_LC + nvl(aFTO_CREDIT_LC, 0) - nvl(aFTO_DEBIT_LC, 0) )
                      , 1, FTO_CREDIT_LC - FTO_DEBIT_LC + nvl(aFTO_CREDIT_LC, 0) - nvl(aFTO_DEBIT_LC, 0)
                      , 0
                       )
             , A_DATEMOD = sysdate
             , A_IDMOD = gUserIni
         where FAM_ACT_TOTAL_BY_PERIOD_ID = vFamTotalByPeriodId;
      else
        select INIT_ID_SEQ.nextval
          into vFamTotalByPeriodId
          from dual;

        insert into FAM_ACT_TOTAL_BY_PERIOD
                    (FAM_ACT_TOTAL_BY_PERIOD_ID
                   , FAM_FIXED_ASSETS_ID
                   , ACS_PERIOD_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , C_FAM_TRANSACTION_TYP
                   , C_FAM_IMPUTATION_TYP
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACS_PJ_ACCOUNT_ID
                   , FTO_DEBIT_LC
                   , FTO_CREDIT_LC
                   , FTO_DEBIT_FC
                   , FTO_CREDIT_FC
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (vFamTotalByPeriodId
                   , aFAM_FIXED_ASSETS_ID
                   , aACS_PERIOD_ID
                   , aLACS_FINANCIAL_CURRENCY_ID
                   , aLACS_FINANCIAL_CURRENCY_ID
                   , aC_FAM_TRANSACTION_TYP
                   , aC_FAM_IMPUTATION_TYP
                   , aACS_FINANCIAL_ACCOUNT_ID
                   , aACS_DIVISION_ACCOUNT_ID
                   , aACS_CPN_ACCOUNT_ID
                   , aACS_CDA_ACCOUNT_ID
                   , aACS_PF_ACCOUNT_ID
                   , aACS_PJ_ACCOUNT_ID
                   , nvl(aFTO_DEBIT_LC, 0)
                   , nvl(aFTO_CREDIT_LC, 0)
                   , 0
                   , 0
                   , sysdate
                   , gUserIni
                    );
      end if;
    end if;
  end WriteFamActTotalByPeriod;

------------------------
  procedure DocImputations(aFAM_DOCUMENT_ID FAM_DOCUMENT.FAM_DOCUMENT_ID%type)
  is
    ------
    cursor crValImputations(aImpDocumentId FAM_DOCUMENT.FAM_DOCUMENT_ID%type)
    is
      select IMP.C_FAM_TRANSACTION_TYP C_FAM_TRANSACTION_TYP
           , IMP.FAM_FIXED_ASSETS_CATEG_ID
           , null F_FINANCIAL_CURRENCY1_ID
           , null L_FINANCIAL_CURRENCY1_ID
           , null ACS_PERIOD1_ID
           , null FAM_FIXED_ASSETS1_ID
           , null FIM_AMOUNT_LC1_D
           , null FIM_AMOUNT_LC1_C
           , null FAM_MANAGED_VALUE1_ID
           , IMP.ACS_FINANCIAL_CURRENCY_ID F_FINANCIAL_CURRENCY2_ID
           , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID L_FINANCIAL_CURRENCY2_ID
           , IMP.ACS_PERIOD_ID ACS_PERIOD2_ID
           , IMP.FAM_FIXED_ASSETS_ID FAM_FIXED_ASSETS2_ID
           , IMP.FIM_AMOUNT_LC_D FIM_AMOUNT_LC2_D
           , IMP.FIM_AMOUNT_LC_C FIM_AMOUNT_LC2_C
           , VAL.FAM_MANAGED_VALUE_ID FAM_MANAGED_VALUE2_ID
           , VAL.FAM_VAL_IMPUTATION_ID
        from FAM_VAL_IMPUTATION VAL
           , FAM_IMPUTATION IMP
       where IMP.FAM_DOCUMENT_ID = aImpDocumentId
         and IMP.FAM_IMPUTATION_ID = VAL.FAM_IMPUTATION_ID;

    ------
    cursor crActImputations(aImpDocumentId FAM_DOCUMENT.FAM_DOCUMENT_ID%type)
    is
      select null FAM_FIXED_ASSETS1_ID
           , null ACS_PERIOD1_ID
           , null F_FINANCIAL_CURRENCY1_ID
           , null L_FINANCIAL_CURRENCY1_ID
           , null ACS_FINANCIAL_ACCOUNT1_ID
           , null ACS_DIVISION_ACCOUNT1_ID
           , null ACS_CPN_ACCOUNT1_ID
           , null ACS_CDA_ACCOUNT1_ID
           , null ACS_PF_ACCOUNT1_ID
           , null ACS_PJ_ACCOUNT1_ID
           , null C_FAM_IMPUTATION1_TYP
           , null FIM_AMOUNT_LC1_D
           , null FIM_AMOUNT_LC1_C
           , null FIM_AMOUNT_FC1_D
           , null FIM_AMOUNT_FC1_C
           , IMP.FAM_FIXED_ASSETS_ID FAM_FIXED_ASSETS2_ID
           , IMP.ACS_PERIOD_ID ACS_PERIOD2_ID
           , IMP.ACS_FINANCIAL_CURRENCY_ID F_FINANCIAL_CURRENCY2_ID
           , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID L_FINANCIAL_CURRENCY2_ID
           , ACT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT2_ID
           , ACT.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT2_ID
           , ACT.ACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT2_ID
           , ACT.ACS_CDA_ACCOUNT_ID ACS_CDA_ACCOUNT2_ID
           , ACT.ACS_PF_ACCOUNT_ID ACS_PF_ACCOUNT2_ID
           , ACT.ACS_PJ_ACCOUNT_ID ACS_PJ_ACCOUNT2_ID
           , ACT.C_FAM_IMPUTATION_TYP C_FAM_IMPUTATION2_TYP
           , ACT.FIM_AMOUNT_LC_D FIM_AMOUNT_LC2_D
           , ACT.FIM_AMOUNT_LC_C FIM_AMOUNT_LC2_C
           , ACT.FIM_AMOUNT_FC_D FIM_AMOUNT_FC2_D
           , ACT.FIM_AMOUNT_FC_C FIM_AMOUNT_FC2_C
        from FAM_ACT_IMPUTATION ACT
           , FAM_IMPUTATION IMP
       where IMP.FAM_DOCUMENT_ID = aFAM_DOCUMENT_ID
         and IMP.FAM_IMPUTATION_ID = ACT.FAM_IMPUTATION_ID;

    tplValImputations crValImputations%rowtype;
    tplActImputations crActImputations%rowtype;
  begin
    -- Imputations immobilisations
    open crValImputations(aFAM_DOCUMENT_ID);

    fetch crValImputations
     into tplValImputations;

    while crValImputations%found loop
      FAM_TOT_BY_PERIOD.WriteFamTotalByPeriod(tplValImputations.FAM_FIXED_ASSETS1_ID
                                            , tplValImputations.FAM_FIXED_ASSETS_CATEG_ID
                                            , tplValImputations.FAM_MANAGED_VALUE1_ID
                                            , tplValImputations.ACS_PERIOD1_ID
                                            , tplValImputations.L_FINANCIAL_CURRENCY1_ID
                                            , tplValImputations.C_FAM_TRANSACTION_TYP
                                            , -tplValImputations.FIM_AMOUNT_LC1_D
                                            , -tplValImputations.FIM_AMOUNT_LC1_C
                                             );
      FAM_TOT_BY_PERIOD.WriteFamTotalByPeriod(tplValImputations.FAM_FIXED_ASSETS2_ID
                                            , tplValImputations.FAM_FIXED_ASSETS_CATEG_ID
                                            , tplValImputations.FAM_MANAGED_VALUE2_ID
                                            , tplValImputations.ACS_PERIOD2_ID
                                            , tplValImputations.L_FINANCIAL_CURRENCY2_ID
                                            , tplValImputations.C_FAM_TRANSACTION_TYP
                                            , tplValImputations.FIM_AMOUNT_LC2_D
                                            , tplValImputations.FIM_AMOUNT_LC2_C
                                             );

      fetch crValImputations
       into tplValImputations;
    end loop;

    close crValImputations;

    -- Imputations immobilisations comptes financiers
    open crActImputations(aFAM_DOCUMENT_ID);

    fetch crActImputations
     into tplActImputations;

    while crActImputations%found loop
      FAM_TOT_BY_PERIOD.UpdateACT_TotalByPeriod(aFAM_DOCUMENT_ID
                                              , tplActImputations.FAM_FIXED_ASSETS1_ID
                                              , tplActImputations.FAM_FIXED_ASSETS2_ID
                                              , tplActImputations.ACS_PERIOD1_ID
                                              , tplActImputations.ACS_PERIOD2_ID
                                              , tplActImputations.L_FINANCIAL_CURRENCY1_ID
                                              , tplActImputations.L_FINANCIAL_CURRENCY2_ID
                                              , tplActImputations.C_FAM_IMPUTATION1_TYP
                                              , tplActImputations.C_FAM_IMPUTATION2_TYP
                                              , tplActImputations.ACS_FINANCIAL_ACCOUNT1_ID
                                              , tplActImputations.ACS_FINANCIAL_ACCOUNT2_ID
                                              , tplActImputations.ACS_DIVISION_ACCOUNT1_ID
                                              , tplActImputations.ACS_DIVISION_ACCOUNT2_ID
                                              , tplActImputations.ACS_CPN_ACCOUNT1_ID
                                              , tplActImputations.ACS_CPN_ACCOUNT2_ID
                                              , tplActImputations.ACS_CDA_ACCOUNT1_ID
                                              , tplActImputations.ACS_CDA_ACCOUNT2_ID
                                              , tplActImputations.ACS_PF_ACCOUNT1_ID
                                              , tplActImputations.ACS_PF_ACCOUNT2_ID
                                              , tplActImputations.ACS_PJ_ACCOUNT1_ID
                                              , tplActImputations.ACS_PJ_ACCOUNT2_ID
                                              , tplActImputations.FIM_AMOUNT_LC1_D
                                              , tplActImputations.FIM_AMOUNT_LC2_D
                                              , tplActImputations.FIM_AMOUNT_LC1_C
                                              , tplActImputations.FIM_AMOUNT_LC2_C
                                               );

      fetch crActImputations
       into tplActImputations;
    end loop;

    close crActImputations;
  end DocImputations;

-------------------------
  procedure YearCalculation(aACS_FINANCIAL_YEAR_ID in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
    function DeleteTotalByPeriod(aFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
      return boolean
    is
      vResult boolean default true;
    begin
      -- Deleting current year records
      begin
        -- Fixed assets totals
        delete from FAM_TOTAL_BY_PERIOD
              where ACS_PERIOD_ID in(select ACS_PERIOD_ID
                                       from ACS_PERIOD
                                      where ACS_FINANCIAL_YEAR_ID = aFinancialYearId);

        -- Fixed assets financial accounts totals
        delete from FAM_ACT_TOTAL_BY_PERIOD
              where ACS_PERIOD_ID in(select ACS_PERIOD_ID
                                       from ACS_PERIOD
                                      where ACS_FINANCIAL_YEAR_ID = aFinancialYearId);
      exception
        when others then
          vResult  := false;
      end;

      return vResult;
    end DeleteTotalByPeriod;

    procedure DocCalculation(aFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    is
      vDocumentId FAM_DOCUMENT.FAM_DOCUMENT_ID%type;

      cursor YearDocumentsCursor(aYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
      is
        select DOC.FAM_DOCUMENT_ID
          from FAM_DOCUMENT DOC
             , FAM_JOURNAL JOU
             , ACS_FINANCIAL_YEAR FYE
         where FYE.ACS_FINANCIAL_YEAR_ID = aYearId
           and FYE.C_STATE_FINANCIAL_YEAR <> 'PLA'
           and JOU.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
           and JOU.FAM_JOURNAL_ID = DOC.FAM_JOURNAL_ID;
    begin
      open YearDocumentsCursor(aFinancialYearId);

      fetch YearDocumentsCursor
       into vDocumentId;

      while YearDocumentsCursor%found loop
        FAM_TOT_BY_PERIOD.DocImputations(vDocumentId);

        fetch YearDocumentsCursor
         into vDocumentId;
      end loop;

      close YearDocumentsCursor;
    end DocCalculation;
  begin
    if DeleteTotalByPeriod(aACS_FINANCIAL_YEAR_ID) then
      DocCalculation(aACS_FINANCIAL_YEAR_ID);
    end if;
  end YearCalculation;
-- =============================================================================
-- Initialisation des variables pour la session
-- =============================================================================
begin
  gUserIni  := PCS.PC_I_LIB_SESSION.GetUserIni;
end FAM_TOT_BY_PERIOD;
