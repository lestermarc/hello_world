--------------------------------------------------------
--  DDL for Package Body ACR_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_FUNCTIONS" 
is
  /**
  * Description
  *   assignation de la variable globale EXIST_DIVISION
  */
  procedure SetExistDivision(aEXIST_DIVISION signtype)
  is
  begin
    ACR_FUNCTIONS.EXIST_DIVISION  := aEXIST_DIVISION;
  end SetExistDivision;

-----------------------
  procedure SetCurrencyId(aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type)
  is
  begin
    CURRENCY_ID  := aACS_FINANCIAL_CURRENCY_ID;
  end SetCurrencyId;

-----------------------
  function GetCurrencyId
    return ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  is
  begin
    return CURRENCY_ID;
  end GetCurrencyId;

-----------------------
  procedure SetFinancialId(aACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type, first number)
  is
  begin
    if first = 1 then
      FINANCIAL_ID1  := aACS_FINANCIAL_ACCOUNT_ID;
    else
      FINANCIAL_ID2  := aACS_FINANCIAL_ACCOUNT_ID;
    end if;
  end SetFinancialId;

-----------------------
  function GetFinancialId(first number)
    return ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  is
  begin
    if first = 1 then
      return FINANCIAL_ID1;
    else
      return FINANCIAL_ID2;
    end if;
  end GetFinancialId;

-----------------------
  procedure SetC_TYPE_CUMUL1(aC_TYPE_CUMUL ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type)
  is
  begin
    C_TYPE_CUMUL1  := aC_TYPE_CUMUL;
  end SetC_TYPE_CUMUL1;

----------------------
  function GetC_TYPE_CUMUL1
    return ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  is
  begin
    return C_TYPE_CUMUL1;
  end GetC_TYPE_CUMUL1;

-----------------------
  procedure SetC_TYPE_CUMUL2(aC_TYPE_CUMUL ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type)
  is
  begin
    C_TYPE_CUMUL2  := aC_TYPE_CUMUL;
  end SetC_TYPE_CUMUL2;

----------------------
  function GetC_TYPE_CUMUL2
    return ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  is
  begin
    return C_TYPE_CUMUL2;
  end GetC_TYPE_CUMUL2;

-----------------------
  procedure SetDivisionId(aACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type)
  is
  begin
    DIVISION_ID  := aACS_DIVISION_ACCOUNT_ID;
  end SetDivisionId;

----------------------
  function GetDivisionId
    return ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  is
  begin
    return DIVISION_ID;
  end GetDivisionId;

-----------------------
  procedure SetAccountId(aACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
  is
  begin
    ACCOUNT_ID  := aACS_ACCOUNT_ID;
  end SetAccountId;

----------------------
  function GetAccountId
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
  begin
    return ACCOUNT_ID;
  end GetAccountId;

----------------------------
  procedure SetFinancialYearId(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
  begin
    YEAR_ID  := aACS_FINANCIAL_YEAR_ID;
  end SetFinancialYearId;

---------------------------
  function GetFinancialYearId
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
  begin
    return YEAR_ID;
  end GetFinancialYearId;

---------------------
  function GetFinYearId
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
  begin
    return to_number(FIN_YEAR_ID);
  end GetFinYearId;

---------------------
  function GetAccNumber(aFirst number)
    return varchar2
  is
  begin
    if aFirst = 1 then
      return ACC_NUMBER1;
    else
      return ACC_NUMBER2;
    end if;
  end GetAccNumber;

---------------------
  function GetRcoTitle(pFirst number)
    return varchar2
  is
  begin
    if pFirst = 1 then
      return RCO_TITLE1;
    else
      return RCO_TITLE2;
    end if;
  end GetRcoTitle;

---------------------------------
  function GetFinancialImputationId(
    aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  )
    return ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  is
    ImfPrimary             ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY%type;
    ImfType                ACT_FINANCIAL_IMPUTATION.IMF_TYPE%type;
    DocumentId             ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type;
    vFinancialImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vRowCount              number                                                      := 0;
    IncludedExcluded       ACT_DET_TAX.TAX_INCLUDED_EXCLUDED%type;

    cursor FINANCIAL_IMPUTATION_CURSOR(
      aACT_DOCUMENT_ID ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
    , aIMF_PRIMARY     ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY%type
    )
    is
      -- Recherche du montant maximum. ROW_COUNT >1 signifie qu'il y a plusieurs comptes financiers d'où 'ORDER BY ROW_COUNT' desc
      select   ACT_FINANCIAL_IMPUTATION_ID
             , rownum ROW_COUNT
--              , ACS_FINANCIAL_ACCOUNT_ID
--              , AMOUNT
      from     (select IMP1.AMOUNT
                     , max(IMP1.AMOUNT) over(partition by ACS_FINANCIAL_ACCOUNT_ID) as MAX_AMOUNT
                     , IMP1.ACT_FINANCIAL_IMPUTATION_ID
                     , IMP1.ACS_FINANCIAL_ACCOUNT_ID
                  from (select   sum(abs(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ) ) AMOUNT
                               , IMP.ACT_FINANCIAL_IMPUTATION_ID
                               , IMP.ACS_FINANCIAL_ACCOUNT_ID
                            from ACT_FINANCIAL_IMPUTATION IMP
                               , ACT_DET_TAX TAX
                               , ACT_DET_TAX TAX2
                           where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                             and IMF_PRIMARY = aIMF_PRIMARY
                             and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT_ACT_FINANCIAL_IMPUTATION(+)
                             and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX2.ACT2_ACT_FINANCIAL_IMPUTATION(+)
                             and (   TAX.TAX_INCLUDED_EXCLUDED is null
                                  or TAX.TAX_INCLUDED_EXCLUDED <> 'I')
                             and (   TAX2.TAX_INCLUDED_EXCLUDED is null
                                  or TAX2.TAX_INCLUDED_EXCLUDED <> 'I')
                             and IMP.IMF_TYPE <> 'VAT'
                             and not exists(
                                   select 1
                                     from ACT_DET_TAX TAX
                                    where TAX.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID
                                      and TAX.ACT2_DET_TAX_ID is not null)
                        group by IMP.ACT_FINANCIAL_IMPUTATION_ID
                               , IMP.ACS_FINANCIAL_ACCOUNT_ID) IMP1)
         where MAX_AMOUNT = AMOUNT
      order by ROW_COUNT desc;

    cursor FINANCIAL_IMPUTATION_CURSOR2(
      aACT_DOCUMENT_ID             ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
    , aIMF_PRIMARY                 ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY%type
    , aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
    )
    is
      select   ACT_FINANCIAL_IMPUTATION_ID
             , rownum ROW_COUNT
--              , ACS_FINANCIAL_ACCOUNT_ID
--              , AMOUNT
      from     (select IMP1.AMOUNT
                     , max(IMP1.AMOUNT) over(partition by ACS_FINANCIAL_ACCOUNT_ID) as MAX_AMOUNT
                     , IMP1.ACT_FINANCIAL_IMPUTATION_ID
                     , IMP1.ACS_FINANCIAL_ACCOUNT_ID
                  from (select   sum(abs(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ) ) AMOUNT
                               , IMP.ACT_FINANCIAL_IMPUTATION_ID
                               , IMP.ACS_FINANCIAL_ACCOUNT_ID
                            from ACT_FINANCIAL_IMPUTATION IMP
                               , ACT_DET_TAX TAX
                               , ACT_DET_TAX TAX2
                           where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                             and IMF_PRIMARY = aIMF_PRIMARY
                             and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT_ACT_FINANCIAL_IMPUTATION(+)
                             and IMP.ACT_FINANCIAL_IMPUTATION_ID = TAX2.ACT2_ACT_FINANCIAL_IMPUTATION(+)
                             and (   TAX.TAX_INCLUDED_EXCLUDED is null
                                  or TAX.TAX_INCLUDED_EXCLUDED <> 'I')
                             and (   TAX2.TAX_INCLUDED_EXCLUDED is null
                                  or TAX2.TAX_INCLUDED_EXCLUDED <> 'I')
                             and IMP.ACT_FINANCIAL_IMPUTATION_ID <> aACT_FINANCIAL_IMPUTATION_ID
                             and IMP.IMF_TYPE <> 'VAT'
                             and not exists(
                                   select 1
                                     from ACT_DET_TAX TAX
                                    where TAX.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID
                                      and TAX.ACT2_DET_TAX_ID is not null)
                        group by IMP.ACT_FINANCIAL_IMPUTATION_ID
                               , IMP.ACS_FINANCIAL_ACCOUNT_ID) IMP1)
         where MAX_AMOUNT = AMOUNT
      order by ROW_COUNT desc;
  begin
    select IMF_PRIMARY
         , IMF_TYPE
         , ACT_DOCUMENT_ID
      into ImfPrimary
         , ImfType
         , DocumentId
      from ACT_FINANCIAL_IMPUTATION
     where ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

    if ImfPrimary = 1 then
      open FINANCIAL_IMPUTATION_CURSOR(DocumentId, 0);

      fetch FINANCIAL_IMPUTATION_CURSOR
       into vFinancialImputationId
          , vRowCount;

      close FINANCIAL_IMPUTATION_CURSOR;

      if vRowCount <> 1 then
        return null;
      else
        return vFinancialImputationId;
      end if;
    else   -- ImfPrimary = 0
      if ImfType = 'VAT' then
        begin
          select ACT2_ACT_FINANCIAL_IMPUTATION
               ,   -- Saisie TTC si TAX_INCLUDED_EXCLUDED = 'I'
                 TAX_INCLUDED_EXCLUDED
            into vFinancialImputationId
               , IncludedExcluded
            from ACT_DET_TAX
           where ACT_ACT_FINANCIAL_IMPUTATION = aACT_FINANCIAL_IMPUTATION_ID;
        exception
          when no_data_found then
            select ACT_ACT_FINANCIAL_IMPUTATION
              into vFinancialImputationId
              from ACT_DET_TAX
             where ACT2_ACT_FINANCIAL_IMPUTATION = aACT_FINANCIAL_IMPUTATION_ID;
          when too_many_rows then
            vFinancialImputationId  := null;
        end;

        if IncludedExcluded = 'E' then   -- Saisie HT
          select min(ACT_FINANCIAL_IMPUTATION_ID)
            into vFinancialImputationId
            from ACT_FINANCIAL_IMPUTATION
           where ACT_DOCUMENT_ID = DocumentId
             and IMF_PRIMARY = 1;
        end if;
      else   -- ImfType <> 'VAT'
        begin
          select min(ACT_FINANCIAL_IMPUTATION_ID)
            into vFinancialImputationId
            from ACT_FINANCIAL_IMPUTATION
           where ACT_DOCUMENT_ID = DocumentId
             and IMF_PRIMARY = 1;
        exception
          when no_data_found then
            open FINANCIAL_IMPUTATION_CURSOR2(DocumentId, 0, aACT_FINANCIAL_IMPUTATION_ID);   -- Recherche une et une seule

            fetch FINANCIAL_IMPUTATION_CURSOR2
             into vFinancialImputationId
                , vRowCount;

            close FINANCIAL_IMPUTATION_CURSOR2;

            if vRowCount <> 1 then
              return null;
            else
              return vFinancialImputationId;
            end if;
        end;
      end if;
    end if;

    return vFinancialImputationId;
  end GetFinancialImputationId;

------------------------
  function MeanCreditInDay(
    aACS_ACCOUNT_ID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
-- cette  fonction ne prend pas compte de la période de bouclement
  is
    result       ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
  begin
    if ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID) = 'REC' then
      select case
               when(sum(TURNOVER_PER) <> 0)
               and ( (sum(REPORT_PER) + sum(ALL_PERIODS) ) <> 0) then abs(360 /
                                                                          (sum(TURNOVER_PER) /
                                                                           ( (sum(REPORT_PER) * 2 + sum(ALL_PERIODS) * 2
                                                                             ) /
                                                                            (2)
                                                                           )
                                                                          )
                                                                         )
               else 0
             end
        into result
        from (select   case
                         when PER.C_TYPE_PERIOD = 2 then nvl(sum(TOT_DEBIT_LC), 0)
                         else 0
                       end TURNOVER_PER --TOTAL DES DEBITS DES PERIODES DE GESTION (CA)
                     , case
                         when PER.C_TYPE_PERIOD = 1 then 0.5 * nvl(sum(TOT_DEBIT_LC - TOT_CREDIT_LC), 0)
                         else 0
                       end REPORT_PER --periode report
                     , case
                         when PER.C_TYPE_PERIOD < 3 then 0.5 * nvl(sum(TOT_DEBIT_LC - TOT_CREDIT_LC), 0)
                         else 0
                       end ALL_PERIODS
                  from ACT_TOTAL_BY_PERIOD TOT
                     , ACS_PERIOD PER
                 where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                   and TOT.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID
                   and PER.C_TYPE_PERIOD < 3
              group by PER.C_TYPE_PERIOD);
    else   --SubSet = 'PAY'
      select case
               when(sum(TURNOVER_PER) <> 0)
               and ( (sum(REPORT_PER) + sum(ALL_PERIODS) ) <> 0) then abs(360 /
                                                                          (sum(TURNOVER_PER) /
                                                                           ( (sum(REPORT_PER) * 2 + sum(ALL_PERIODS) * 2
                                                                             ) /
                                                                            (2)
                                                                           )
                                                                          )
                                                                         )
               else 0
             end
        into result
        from (select   case
                         when PER.C_TYPE_PERIOD = 2 then nvl(sum(TOT_CREDIT_LC), 0)
                         else 0
                       end TURNOVER_PER --TOTAL DES DEBITS DES PERIODES DE GESTION (CA)
                     , case
                         when PER.C_TYPE_PERIOD = 1 then 0.5 * nvl(sum(TOT_CREDIT_LC - TOT_DEBIT_LC), 0)
                         else 0
                       end REPORT_PER --periode report
                     , case
                         when PER.C_TYPE_PERIOD < 3 then 0.5 * nvl(sum(TOT_CREDIT_LC - TOT_DEBIT_LC), 0)
                         else 0
                       end ALL_PERIODS
                  from ACT_TOTAL_BY_PERIOD TOT
                     , ACS_PERIOD PER
                 where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                   and TOT.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID
                   and PER.C_TYPE_PERIOD < 3
              group by PER.C_TYPE_PERIOD);
    end if;

    return result;
  end MeanCreditInDay;

  function MeanCreditInDayTableTemp(
    aCSubSet               ACS_SUB_SET.C_SUB_SET%type
  , aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
-- cette  fonction ne prend pas compte de la période de bouclement
  is
    result       ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
  begin
    if aCSubSet = 'REC' then
      select case
               when(sum(TURNOVER_PER) <> 0)
               and ( (sum(REPORT_PER) + sum(ALL_PERIODS) ) <> 0) then abs(360 /
                                                                          (sum(TURNOVER_PER) /
                                                                           ( (sum(REPORT_PER) * 2 + sum(ALL_PERIODS) * 2
                                                                             ) /
                                                                            (2)
                                                                           )
                                                                          )
                                                                         )
               else 0
             end
        into result
        from (select   case
                         when PER.C_TYPE_PERIOD = 2 then nvl(sum(TOT_DEBIT_LC), 0)
                         else 0
                       end TURNOVER_PER --TOTAL DES DEBITS DES PERIODES DE GESTION (CA)
                     , case
                         when PER.C_TYPE_PERIOD = 1 then 0.5 * nvl(sum(TOT_DEBIT_LC - TOT_CREDIT_LC), 0)
                         else 0
                       end REPORT_PER --periode report
                     , case
                         when PER.C_TYPE_PERIOD < 3 then 0.5 * nvl(sum(TOT_DEBIT_LC - TOT_CREDIT_LC), 0)
                         else 0
                       end ALL_PERIODS
                  from ACT_TOTAL_BY_PERIOD TOT
                     , ACS_PERIOD PER
                     , COM_LIST_ID_TEMP TMP
                 where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                   and TOT.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_AUXILIARY_ACCOUNT_ID = TMP.LID_FREE_NUMBER_1
                   and PER.C_TYPE_PERIOD < 3
              group by PER.C_TYPE_PERIOD);
    else   --SubSet = 'PAY'
      select case
               when(sum(TURNOVER_PER) <> 0)
               and ( (sum(REPORT_PER) + sum(ALL_PERIODS) ) <> 0) then abs(360 /
                                                                          (sum(TURNOVER_PER) /
                                                                           ( (sum(REPORT_PER) * 2 + sum(ALL_PERIODS) * 2
                                                                             ) /
                                                                            (2)
                                                                           )
                                                                          )
                                                                         )
               else 0
             end
        into result
        from (select   case
                         when PER.C_TYPE_PERIOD = 2 then nvl(sum(TOT_CREDIT_LC), 0)
                         else 0
                       end TURNOVER_PER --TOTAL DES DEBITS DES PERIODES DE GESTION (CA)
                     , case
                         when PER.C_TYPE_PERIOD = 1 then 0.5 * nvl(sum(TOT_CREDIT_LC - TOT_DEBIT_LC), 0)
                         else 0
                       end REPORT_PER --periode report
                     , case
                         when PER.C_TYPE_PERIOD < 3 then 0.5 * nvl(sum(TOT_CREDIT_LC - TOT_DEBIT_LC), 0)
                         else 0
                       end ALL_PERIODS
                  from ACT_TOTAL_BY_PERIOD TOT
                     , ACS_PERIOD PER
                     , COM_LIST_ID_TEMP TMP
                 where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                   and TOT.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_AUXILIARY_ACCOUNT_ID = TMP.LID_FREE_NUMBER_1
                   and PER.C_TYPE_PERIOD < 3
              group by PER.C_TYPE_PERIOD);
    end if;

    return result;
  end MeanCreditInDayTableTemp;

--------------------------------
  function MeanCreditInDayBySubSet(
    aACS_SUB_SET_ID        ACS_SUB_SET.ACS_SUB_SET_ID%type
  , aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
-- cette  fonction ne prend pas compte de la période de bouclement
  is
    result ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
  begin
    if ACS_FUNCTION.GetSubSetOfSubSet(aACS_SUB_SET_ID) = 'REC' then
      select case
               when(sum(TURNOVER_PER) <> 0)
               and ( (sum(REPORT_PER) + sum(ALL_PERIODS) ) <> 0) then abs(360 /
                                                                          (sum(TURNOVER_PER) /
                                                                           ( (sum(REPORT_PER) * 2 + sum(ALL_PERIODS) * 2
                                                                             ) /
                                                                            (2)
                                                                           )
                                                                          )
                                                                         )
               else 0
             end
        into result
        from (select   case
                         when PER.C_TYPE_PERIOD = 2 then nvl(sum(TOT_DEBIT_LC), 0)
                         else 0
                       end TURNOVER_PER --TOTAL DES DEBITS DES PERIODES DE GESTION (CA)
                     , case
                         when PER.C_TYPE_PERIOD = 1 then 0.5 * nvl(sum(TOT_DEBIT_LC - TOT_CREDIT_LC), 0)
                         else 0
                       end REPORT_PER --periode report
                     , case
                         when PER.C_TYPE_PERIOD < 3 then 0.5 * nvl(sum(TOT_DEBIT_LC - TOT_CREDIT_LC), 0)
                         else 0
                       end ALL_PERIODS
                  from ACS_ACCOUNT ACC
                     , ACT_TOTAL_BY_PERIOD TOT
                     , ACS_PERIOD PER
                 where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                   and TOT.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                   and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID
                   and PER.C_TYPE_PERIOD < 3
              group by PER.C_TYPE_PERIOD);
    else   --SubSet = 'PAY'
      select case
               when(sum(TURNOVER_PER) <> 0)
               and ( (sum(REPORT_PER) + sum(ALL_PERIODS) ) <> 0) then abs(360 /
                                                                          (sum(TURNOVER_PER) /
                                                                           ( (sum(REPORT_PER) * 2 + sum(ALL_PERIODS) * 2
                                                                             ) /
                                                                            (2)
                                                                           )
                                                                          )
                                                                         )
               else 0
             end
        into result
        from (select   case
                         when PER.C_TYPE_PERIOD = 2 then nvl(sum(TOT_CREDIT_LC), 0)
                         else 0
                       end TURNOVER_PER --TOTAL DES DEBITS DES PERIODES DE GESTION (CA)
                     , case
                         when PER.C_TYPE_PERIOD = 1 then 0.5 * nvl(sum(TOT_CREDIT_LC - TOT_DEBIT_LC), 0)
                         else 0
                       end REPORT_PER --periode report
                     , case
                         when PER.C_TYPE_PERIOD < 3 then 0.5 * nvl(sum(TOT_CREDIT_LC - TOT_DEBIT_LC), 0)
                         else 0
                       end ALL_PERIODS
                  from ACS_ACCOUNT ACC
                     , ACT_TOTAL_BY_PERIOD TOT
                     , ACS_PERIOD PER
                 where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                   and TOT.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                   and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID
                   and PER.C_TYPE_PERIOD < 3
              group by PER.C_TYPE_PERIOD);
    end if;

    return result;
  end MeanCreditInDayBySubSet;

---------------------------------
  function AveragePeriod4Payment(aACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
    return number
-- renvoie le délais de paiement en jours par compte auxiliaire
  is
    result number;
  begin
    select round(avg(decode(exp.EXP_DATE_PMT_TOT - FIN.IMF_VALUE_DATE
                          , 0, 1
                          , exp.EXP_DATE_PMT_TOT - FIN.IMF_VALUE_DATE
                           )
                    )
                ) AVERAGE_PERIOD_4_PAYMENT
      into result
      from (select exp.ACT_DOCUMENT_ID
                 , exp.EXP_DATE_PMT_TOT
              from ACT_EXPIRY exp
             where exp.EXP_CALC_NET = 1
               and exp.C_STATUS_EXPIRY = '1') exp
         , (select FIN.ACT_DOCUMENT_ID
                 , FIN.IMF_VALUE_DATE
              from ACT_FINANCIAL_IMPUTATION FIN
             where FIN.IMF_PRIMARY = 1
               and FIN.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID) FIN
     where FIN.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID;

    return result;
  end AveragePeriod4Payment;

---------------------
  function AveragePaymentByExercice(
    aACS_ACCOUNT_ID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
    return number
-- renvoie le délais de paiement en jours par exercice et compte auxiliaire
  is
    result number;
  begin
    select round(avg(decode(exp.EXP_DATE_PMT_TOT - FIN.IMF_VALUE_DATE
                          , 0, 1
                          , exp.EXP_DATE_PMT_TOT - FIN.IMF_VALUE_DATE
                           )
                    )
                ) AVERAGE_PERIOD_4_PAYMENT
      into result
      from (select exp.ACT_DOCUMENT_ID
                 , exp.EXP_DATE_PMT_TOT
              from ACT_EXPIRY exp
             where exp.EXP_CALC_NET = 1
               and exp.C_STATUS_EXPIRY = '1') exp
         , (select FIN.ACT_DOCUMENT_ID
                 , FIN.IMF_VALUE_DATE
              from ACT_FINANCIAL_IMPUTATION FIN
             where FIN.IMF_ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
               and FIN.IMF_PRIMARY = 1
               and FIN.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID) FIN
     where FIN.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID;

    return result;
  end AveragePaymentByExercice;

  function AveragePaymentBySubSet(
    aACS_SUB_SET_ID        ACS_SUB_SET.ACS_SUB_SET_ID%type
  , aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
    return number
-- renvoie le délais de paiement en jours par exercice et sous-ensemble auxiliaire
  is
    result number;
  begin
    select round(avg(decode(exp.EXP_DATE_PMT_TOT - FIN.IMF_VALUE_DATE
                          , 0, 1
                          , exp.EXP_DATE_PMT_TOT - FIN.IMF_VALUE_DATE
                           )
                    )
                ) AVERAGE_PERIOD_4_PAYMENT
      into result
      from (select exp.ACT_DOCUMENT_ID
                 , exp.EXP_DATE_PMT_TOT
              from ACT_EXPIRY exp
             where exp.EXP_CALC_NET = 1
               and exp.C_STATUS_EXPIRY = '1') exp
         , (select FIN.ACT_DOCUMENT_ID
                 , FIN.IMF_VALUE_DATE
              from ACS_ACCOUNT ACC
                 , ACT_FINANCIAL_IMPUTATION FIN
             where FIN.IMF_ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
               and FIN.IMF_PRIMARY = 1
               and ACC.ACS_ACCOUNT_ID = FIN.ACS_AUXILIARY_ACCOUNT_ID
               and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID) FIN
     where FIN.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID;


    return result;
  end AveragePaymentBySubSet;

  function AveragePaymentByExTableTemp(
    aC_SUB_SET             ACS_SUB_SET.C_SUB_SET%type
  , aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
    return number
-- renvoie le délais de paiement en jours par exercice et compte auxiliaire
  is
    result number;
  begin
    select round(avg(decode(exp.EXP_DATE_PMT_TOT - FIN.IMF_VALUE_DATE
                          , 0, 1
                          , exp.EXP_DATE_PMT_TOT - FIN.IMF_VALUE_DATE
                           )
                    )
                ) AVERAGE_PERIOD_4_PAYMENT
      into result
      from (select exp.ACT_DOCUMENT_ID
                 , exp.EXP_DATE_PMT_TOT
              from ACT_EXPIRY exp
             where exp.EXP_CALC_NET = 1
               and exp.C_STATUS_EXPIRY = '1') exp
         , (select FIN.ACT_DOCUMENT_ID
                 , FIN.IMF_VALUE_DATE
              from COM_LIST_ID_TEMP TMP
                 , ACT_FINANCIAL_IMPUTATION FIN
             where FIN.IMF_ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
               and FIN.IMF_PRIMARY = 1
               and TMP.LID_FREE_NUMBER_1 = FIN.ACS_AUXILIARY_ACCOUNT_ID) FIN
     where FIN.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID;

    return result;
  end AveragePaymentByExTableTemp;

  function GetJOU_NUMBER(aFirst number)
    return number
  is
  begin
    if aFirst = 1 then
      if JOU_NUMBER1 <> ' ' then
        return to_number(JOU_NUMBER1);
      end if;
    else
      if JOU_NUMBER2 <> ' ' then
        return to_number(JOU_NUMBER2);
      end if;
    end if;
    return null;
  end GetJOU_NUMBER;

----------------------
  function GetStatReminderDate(
    aACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , aTypeOfDate               number
  , aTypeOfThird              number
  )
    return date
--aTypeOfDate  number 1 : plus haut atteint
--         ,          2 : plus haut actuel
--                    3 : dernier

  --aTypeOfThird number 1 : Client (customer)
--         ,          2 : Fournisseur (Supplier)
  is
    result date;
  begin
    if     (aTypeOfDate = 1)
       and (aTypeOfThird = 1) then   --cust
      select max(DOC.DOC_DOCUMENT_DATE)
        into result
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_REMINDER rem
           , ACT_PART_IMPUTATION PAR
           , PAC_CUSTOM_PARTNER CUST
       where CUST.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and CUST.PAC_CUSTOM_PARTNER_ID = PAR.PAC_CUSTOM_PARTNER_ID
         and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
         and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_REMINDER_METHOD <> '01';
    elsif     (aTypeOfDate = 1)
          and (aTypeOfThird = 2) then   --sup
      select max(DOC.DOC_DOCUMENT_DATE)
        into result
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_REMINDER rem
           , ACT_PART_IMPUTATION PAR
           , PAC_SUPPLIER_PARTNER SUPP
       where SUPP.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and SUPP.PAC_SUPPLIER_PARTNER_ID = PAR.PAC_SUPPLIER_PARTNER_ID
         and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
         and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_REMINDER_METHOD <> '01';
    elsif     (aTypeOfDate = 2)
          and (aTypeOfThird = 1) then   --cust
      select max(DOC.DOC_DOCUMENT_DATE)
        into result
        from ACT_EXPIRY exp
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_REMINDER rem
           , ACT_PART_IMPUTATION PAR
           , PAC_CUSTOM_PARTNER CUST
       where CUST.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and CUST.PAC_CUSTOM_PARTNER_ID = PAR.PAC_CUSTOM_PARTNER_ID
         and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
         and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_REMINDER_METHOD <> '01'
         and rem.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
         and exp.C_STATUS_EXPIRY = 0;
    elsif     (aTypeOfDate = 2)
          and (aTypeOfThird = 2) then   --supp
      select max(DOC.DOC_DOCUMENT_DATE)
        into result
        from ACT_EXPIRY exp
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_REMINDER rem
           , ACT_PART_IMPUTATION PAR
           , PAC_SUPPLIER_PARTNER SUPP
       where SUPP.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and SUPP.PAC_SUPPLIER_PARTNER_ID = PAR.PAC_SUPPLIER_PARTNER_ID
         and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
         and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_REMINDER_METHOD <> '01'
         and rem.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
         and exp.C_STATUS_EXPIRY = 0;
    elsif aTypeOfDate = 3 then
      select max(AUX_LAST_REMINDER)
        into result
        from ACS_AUXILIARY_ACCOUNT
       where ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID;
    end if;

    return trunc(result);
  end GetStatReminderDate;

------------------------
  function GetStatReminderLevel(
    aACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , aTypeOfLevel              number
  , aTypeOfThird              number
  )
    return number
--aTypeOfLevel number 1 : plus haut atteint
--        ,           2 : plus haut actuel
--                    3 : dernier

  --TaypeOfThird number 1 : Client (customer)
--         ,          2 : Fournisseur (Supplier)
  is
    result number;
  begin
    if     (aTypeOfLevel = 1)
       and (aTypeOfThird = 1) then   --cust
      select nvl(max(rem.REM_NUMBER), 0) REM_NUMBER
        into result
        from ACT_REMINDER rem
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
           , PAC_CUSTOM_PARTNER CUST
       where CUST.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and CUST.PAC_CUSTOM_PARTNER_ID = PAR.PAC_CUSTOM_PARTNER_ID
         and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_REMINDER_METHOD <> '01'
         and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID;
    elsif     (aTypeOfLevel = 1)
          and (aTypeOfThird = 2) then   --supp
      select nvl(max(rem.REM_NUMBER), 0) REM_NUMBER
        into result
        from ACT_REMINDER rem
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
           , PAC_SUPPLIER_PARTNER SUPP
       where SUPP.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and SUPP.PAC_SUPPLIER_PARTNER_ID = PAR.PAC_SUPPLIER_PARTNER_ID
         and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_REMINDER_METHOD <> '01'
         and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID;
    elsif     (aTypeOfLevel = 2)
          and (aTypeOfThird = 1) then   --cust
      select nvl(max(rem.REM_NUMBER), 0) REM_NUMBER
        into result
        from ACT_EXPIRY exp
           , ACT_REMINDER rem
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
           , PAC_CUSTOM_PARTNER CUST
       where CUST.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and CUST.PAC_CUSTOM_PARTNER_ID = PAR.PAC_CUSTOM_PARTNER_ID
         and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_REMINDER_METHOD <> '01'
         and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
         and rem.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
         and exp.C_STATUS_EXPIRY = 0;
    elsif     (aTypeOfLevel = 2)
          and (aTypeOfThird = 2) then   --supp
      select nvl(max(rem.REM_NUMBER), 0) REM_NUMBER
        into result
        from ACT_EXPIRY exp
           , ACT_REMINDER rem
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
           , PAC_SUPPLIER_PARTNER SUPP
       where SUPP.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and SUPP.PAC_SUPPLIER_PARTNER_ID = PAR.PAC_SUPPLIER_PARTNER_ID
         and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_REMINDER_METHOD <> '01'
         and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
         and rem.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
         and exp.C_STATUS_EXPIRY = 0;
    elsif aTypeOfLevel = 3 then
      select nvl(AUX_REMINDER_LEVEL, 0)
        into result
        from ACS_AUXILIARY_ACCOUNT
       where ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID;
    end if;

    return result;
  end GetStatReminderLevel;

---------------------
  function GetCumulDate
    return date
  is
  begin
    return CUMUL_DATE;
  end GetCumulDate;

-------------------------
  function GetCumulDateFrom
    return date
  is
  begin
    return CUMUL_DATE_FROM;
  end GetCumulDateFrom;

----------------------
  function ExistDivision
    return number
  is
  begin
    return EXIST_DIVISION;
  end ExistDivision;

  /**
  * Description  Recherche du montant reporté, rapproché ou non, d'un compte, d'une division et d'un exercice comptable donnés
  *   !!! Préférer l'utilisation de GetReportAmountCompared() !!!
  */
  function CompareReportAmount(
    aACS_FINANCIAL_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_YEAR_ID         ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aCompared                      number
  , aACS_ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type default 0
  )
    return ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  is
    Amount ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
  -----
  begin
    begin
      if aCompared = 1 then
        -- Mouvements rapprochés
        select nvl(sum(nvl(IMF_AMOUNT_LC_D, 0) - nvl(IMF_AMOUNT_LC_C, 0) ), 0)
          into Amount
          from ACT_JOURNAL JOU
             , (select IMF.IMF_AMOUNT_LC_D
                     , IMF.IMF_AMOUNT_LC_C
                     , IMF.ACS_FINANCIAL_ACCOUNT_ID
                     , DOC.ACT_JOURNAL_ID
                     , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                     , IMF.IMF_COMPARE_DATE
                     , IMF.IMF_TRANSACTION_DATE
                  from ACT_FINANCIAL_IMPUTATION IMF
                     , ACT_DOCUMENT DOC
                 where DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID) IMP
         where IMP.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
           and IMP.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
           and nvl(JOU.C_TYPE_JOURNAL, 'OPB') <> 'OPB'
           and (    (    aACS_DIVISION_ACCOUNT_ID is not null
                     and IMP.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
                or aACS_DIVISION_ACCOUNT_ID is null
               )
           and IMP.IMF_COMPARE_DATE is not null
           and IMP.IMF_TRANSACTION_DATE < (select FYE_START_DATE
                                             from ACS_FINANCIAL_YEAR
                                            where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID);
      elsif aCompared = 2 then
        -- Mouvements rapprochés  ME
        select nvl(sum(nvl(IMF_AMOUNT_FC_D, 0) - nvl(IMF_AMOUNT_FC_C, 0) ), 0)
          into Amount
          from ACT_JOURNAL JOU
             , (select IMF.IMF_AMOUNT_FC_D
                     , IMF.IMF_AMOUNT_FC_C
                     , IMF.ACS_FINANCIAL_ACCOUNT_ID
                     , DOC.ACT_JOURNAL_ID
                     , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                     , IMF.IMF_COMPARE_DATE
                     , IMF.IMF_TRANSACTION_DATE
                  from ACT_FINANCIAL_IMPUTATION IMF
                     , ACT_DOCUMENT DOC
                 where IMF.ACS_FINANCIAL_CURRENCY_ID = aACS_ACS_FINANCIAL_CURRENCY_ID
                   and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID) IMP
         where IMP.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
           and IMP.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
           and nvl(JOU.C_TYPE_JOURNAL, 'OPB') <> 'OPB'
           and (    (    aACS_DIVISION_ACCOUNT_ID is not null
                     and IMP.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
                or aACS_DIVISION_ACCOUNT_ID is null
               )
           and IMP.IMF_COMPARE_DATE is not null
           and IMP.IMF_TRANSACTION_DATE < (select FYE_START_DATE
                                             from ACS_FINANCIAL_YEAR
                                            where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID);
      else
        -- Mouvements non rapprochés MB
        select nvl(sum(nvl(IMF_AMOUNT_LC_D, 0) - nvl(IMF_AMOUNT_LC_C, 0) ), 0)
          into Amount
          from ACT_JOURNAL JOU
             , (select IMF.IMF_AMOUNT_LC_D
                     , IMF.IMF_AMOUNT_LC_C
                     , IMF.ACS_FINANCIAL_ACCOUNT_ID
                     , DOC.ACT_JOURNAL_ID
                     , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                     , IMF.IMF_COMPARE_DATE
                     , IMF.IMF_TRANSACTION_DATE
                  from ACT_FINANCIAL_IMPUTATION IMF
                     , ACT_DOCUMENT DOC
                 where DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID) IMP
         where IMP.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
           and IMP.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
           and nvl(JOU.C_TYPE_JOURNAL, 'OPB') <> 'OPB'
           and (    (    aACS_DIVISION_ACCOUNT_ID is not null
                     and IMP.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
                or aACS_DIVISION_ACCOUNT_ID is null
               )
           and IMP.IMF_COMPARE_DATE is null
           and IMP.IMF_TRANSACTION_DATE < (select FYE_START_DATE
                                             from ACS_FINANCIAL_YEAR
                                            where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID);
      end if;
    exception
      when others then
        Amount  := 0;
    end;

    return Amount;
  end CompareReportAmount;

  /**
  * Description  Recherche du montant reporté, rapproché ou non, d'un compte, d'une division et à une date donnée
  */
  function GetReportAmountCompared(
    aACS_FINANCIAL_ACCOUNT_ID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aDate                      date
  , aCompared                  number
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type default null
  )
    return ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  is
    Amount_LC ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    Amount_FC ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
  -----
  begin
    select nvl(sum(nvl(IMF_AMOUNT_LC_D, 0) - nvl(IMF_AMOUNT_LC_C, 0) ), 0)
         , nvl(sum(nvl(IMF_AMOUNT_FC_D, 0) - nvl(IMF_AMOUNT_FC_C, 0) ), 0)
      into Amount_LC
         , Amount_FC
      from ACT_FINANCIAL_IMPUTATION IMF
         , ACT_JOURNAL JOU
         , ACT_DOCUMENT DOC
     where (    (    aACS_FINANCIAL_CURRENCY_ID is not null
                 and IMF.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID)
            or aACS_FINANCIAL_CURRENCY_ID is null
           )
       and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
       and IMF.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
       and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
       and JOU.C_TYPE_JOURNAL != 'OPB'
       and (    (    aACS_DIVISION_ACCOUNT_ID is not null
                 and IMF.IMF_ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
            or aACS_DIVISION_ACCOUNT_ID is null
           )
       and (    (    aCompared = 0
                 and IMF.IMF_COMPARE_DATE is null)
            or (    aCompared != 0
                and IMF.IMF_COMPARE_DATE is not null) )
       and IMF.IMF_TRANSACTION_DATE <= trunc(aDate);

    if aACS_FINANCIAL_CURRENCY_ID is null then
      return Amount_LC;
    else
      return Amount_FC;
    end if;
  end GetReportAmountCompared;

  /**
  * Description  Recherche du montant reporté, rapproché ou non, d'un compte, d'une division et au début d'un exercice comptable donnés
  */
  function GetReportAmountCompared(
    aACS_FINANCIAL_ACCOUNT_ID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_YEAR_ID     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aCompared                  number
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type default null
  )
    return ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  is
    startDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
  begin
    select FYE_START_DATE - 1
      into startDate
      from ACS_FINANCIAL_YEAR
     where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID;

    return GetReportAmountCompared(aACS_FINANCIAL_ACCOUNT_ID
                                 , aACS_DIVISION_ACCOUNT_ID
                                 , startDate
                                 , aCompared
                                 , aACS_FINANCIAL_CURRENCY_ID
                                  );
  end GetReportAmountCompared;

  /**
  * Description  Recherche du montant reporté, lettré ou non, d'un compte, d'une division et à une date donnée
  */
  function GetReportAmountLettered(
    aACS_FINANCIAL_ACCOUNT_ID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aDate                      date
  , aLettered                  number
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type default null
  )
    return ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  is
    Amount_LC ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    Amount_FC ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
  -----
  begin
    if aLettered = 0 then
      select nvl(sum(nvl(IMF_AMOUNT_LC_D, 0) - nvl(IMF_AMOUNT_LC_C, 0) ), 0) - nvl(sum(LDE_AMOUNT.LDE_AMOUNT_LC), 0)
           , nvl(sum(nvl(IMF_AMOUNT_FC_D, 0) - nvl(IMF_AMOUNT_FC_C, 0) ), 0) - nvl(sum(LDE_AMOUNT.LDE_AMOUNT_FC), 0)
        into Amount_LC
           , Amount_FC
        from (select   nvl(sum(nvl(LDE_AMOUNT_LC_D, 0) - nvl(LDE_AMOUNT_LC_C, 0) ), 0) LDE_AMOUNT_LC
                     , nvl(sum(nvl(LDE_AMOUNT_FC_D, 0) - nvl(LDE_AMOUNT_FC_C, 0) ), 0) LDE_AMOUNT_FC
                     , IMF.ACT_FINANCIAL_IMPUTATION_ID
                  from ACT_FINANCIAL_IMPUTATION IMF
                     , ACT_LETTERING_DETAIL LET
                     , ACT_DOCUMENT DOC
                     , ACT_JOURNAL JOU
                 where (    (    aACS_FINANCIAL_CURRENCY_ID is not null
                             and IMF.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
                            )
                        or aACS_FINANCIAL_CURRENCY_ID is null
                       )
                   and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
                   and LET.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID
                   and IMF.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
                   and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                   and JOU.C_TYPE_JOURNAL != 'OPB'
                   and (    (    aACS_DIVISION_ACCOUNT_ID is not null
                             and IMF.IMF_ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID
                            )
                        or aACS_DIVISION_ACCOUNT_ID is null
                       )
                   and IMF.IMF_TRANSACTION_DATE <= trunc(aDate)
              group by IMF.ACT_FINANCIAL_IMPUTATION_ID) LDE_AMOUNT
           , ACT_FINANCIAL_IMPUTATION IMF
           , ACT_JOURNAL JOU
           , ACT_DOCUMENT DOC
       where (    (    aACS_FINANCIAL_CURRENCY_ID is not null
                   and IMF.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
                  )
              or aACS_FINANCIAL_CURRENCY_ID is null
             )
         and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
         and LDE_AMOUNT.ACT_FINANCIAL_IMPUTATION_ID(+) = IMF.ACT_FINANCIAL_IMPUTATION_ID
         and IMF.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and JOU.C_TYPE_JOURNAL != 'OPB'
         and (    (    aACS_DIVISION_ACCOUNT_ID is not null
                   and IMF.IMF_ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
              or aACS_DIVISION_ACCOUNT_ID is null
             )
         and IMF.IMF_TRANSACTION_DATE <= trunc(aDate);
    else
      select nvl(sum(nvl(LDE_AMOUNT_LC_D, 0) - nvl(LDE_AMOUNT_LC_C, 0) ), 0)
           , nvl(sum(nvl(LDE_AMOUNT_FC_D, 0) - nvl(LDE_AMOUNT_FC_C, 0) ), 0)
        into Amount_LC
           , Amount_FC
        from ACT_FINANCIAL_IMPUTATION IMF
           , ACT_LETTERING_DETAIL LET
           , ACT_JOURNAL JOU
           , ACT_DOCUMENT DOC
       where (    (    aACS_FINANCIAL_CURRENCY_ID is not null
                   and IMF.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
                  )
              or aACS_FINANCIAL_CURRENCY_ID is null
             )
         and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
         and LET.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID
         and IMF.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and JOU.C_TYPE_JOURNAL != 'OPB'
         and (    (    aACS_DIVISION_ACCOUNT_ID is not null
                   and IMF.IMF_ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
              or aACS_DIVISION_ACCOUNT_ID is null
             )
         and IMF.IMF_TRANSACTION_DATE <= trunc(aDate);
    end if;

    if aACS_FINANCIAL_CURRENCY_ID is null then
      return Amount_LC;
    else
      return Amount_FC;
    end if;
  end GetReportAmountLettered;

  /**
  * Description  Recherche du montant reporté, lettré ou non, d'un compte, d'une division et au début d'un exercice comptable donnés
  */
  function GetReportAmountLettered(
    aACS_FINANCIAL_ACCOUNT_ID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_YEAR_ID     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aLettered                  number
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type default null
  )
    return ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  is
    startDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
  begin
    select FYE_START_DATE - 1
      into startDate
      from ACS_FINANCIAL_YEAR
     where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID;

    return GetReportAmountLettered(aACS_FINANCIAL_ACCOUNT_ID
                                 , aACS_DIVISION_ACCOUNT_ID
                                 , startDate
                                 , aLettered
                                 , aACS_FINANCIAL_CURRENCY_ID
                                  );
  end GetReportAmountLettered;

/*********************************************************************************************************************/
 /**
 * Description
 *   Calcul du montant total lettré en MB
 */
  function Total_Lettering_Amount_Imput(
    pFinancialImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , pDebitCreditCode       varchar2
  , pLetteringDate         ACT_LETTERING.LET_DATE%type
  )
    return ACT_LETTERING_DETAIL.LDE_AMOUNT_LC_D%type
  is
    result ACT_LETTERING_DETAIL.LDE_AMOUNT_LC_D%type;
  begin
    begin
      select decode(upper(pDebitCreditCode)
                  ,   /*Somme du champ correspondant au code passé en param...*/
                    'D', nvl(sum(LDE_AMOUNT_LC_D), 0)
                  , 'C', nvl(sum(LDE_AMOUNT_LC_C), 0)
                  , 0
                   )
        into result
        from ACT_LETTERING_DETAIL DET
       where DET.ACT_FINANCIAL_IMPUTATION_ID = pFinancialImputationId   /*...pour l'imputation financière donnée...*/
         and exists(
               select 1
                 from ACT_LETTERING LET
                where LET.LET_DATE <=
                        decode
                              (pLetteringDate
                             ,   /*...pour les lettrages dont les dates sont antérieures à la date donnée*/
                               null, LET.LET_DATE
                             ,   /* ou tous les lettrages si la date est null*/
                               pLetteringDate
                              )
                  and DET.ACT_LETTERING_ID = LET.ACT_LETTERING_ID);
    exception
      when others then
        result  := 0;
    end;

    return result;
  end Total_Lettering_Amount_Imput;

/*********************************************************************************************************************/

  /**
  * function IsDocumentMatching
  * Description
  *  Retourne 1 si le document passé en paramètre répond aux critères d'une opération blanche soit:
  *    -Document de type 9, lettrage
  *    -Un seul compte financier est mouvementé, (toutes les imputations ont le même compte)
  *    -une seule division si gérée est mouvementée (toutes les imputations ont la même division)
  * @param pACT_DOCUMENT_ID document comptable
  * @return 1 si c'est une opération blanche, 0 le cas contraire
  */
  function IsDocumentMatching(pACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type)
    return number
  is
    vResult number(1);
  begin
    vResult  := 0;

    select decode(max(C_TYPE_CATALOGUE), '9', 1, 0)
      into vResult
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_PART_IMPUTATION PAR
         , ACT_DOCUMENT DOC
     where PAR.ACT_PART_IMPUTATION_ID = pACT_PART_IMPUTATION_ID
       and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID;

    if vResult = 1 then
      select decode(count(*), 1, 1, 0)
        into vResult
        from (select distinct IMP.ACS_FINANCIAL_ACCOUNT_ID
                            , nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0)
                         from ACS_FINANCIAL_ACCOUNT FIN
                            , ACT_FINANCIAL_IMPUTATION IMP
                        where IMP.ACT_PART_IMPUTATION_ID = pACT_PART_IMPUTATION_ID
                          and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                          and FIN.FIN_COLLECTIVE = 1);
    end if;

    if vResult = 1 then
      select decode(sum(nvl(imp.imf_amount_lc_d, 0) ), sum(nvl(imp.imf_amount_lc_c, 0) ), 1, 0)
        into vResult
        from ACS_FINANCIAL_ACCOUNT FIN
           , ACT_FINANCIAL_IMPUTATION IMP
       where IMP.ACT_PART_IMPUTATION_ID = pACT_PART_IMPUTATION_ID
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and FIN.FIN_COLLECTIVE = 1;
    end if;

    return vResult;
  end IsDocumentMatching;

/*********************************************************************************************************************/
 /**
 * function GetTurnoverAmount
 * Description
 *   Calcul du chiffre d'affaire
 */
  function GetTurnoverAmount(
    pAuxiliaryAccountId ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , pFinYearId          ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pStartNoPeriod      ACS_PERIOD.PER_NO_PERIOD%type
  , pEndNoPeriod        ACS_PERIOD.PER_NO_PERIOD%type
  , pFinCurrencyId      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , pClassificationId   CLASSIFICATION.CLASSIFICATION_ID%type
  , pCTypeCumuls        varchar2
  , pCTypeCat           varchar2
  )
    return number
  is
    cntSeparator constant varchar2(1)  := ';';
    vCTypeCumuls          varchar2(50) := pCTypeCumuls;
    vCTypeCat             varchar2(50) := pCTypeCat;
    vCTypCumul1           varchar2(3);
    vCTypCumul2           varchar2(3);
    vCTypCumul3           varchar2(3);
    vCTypCumul4           varchar2(3);
    vCTypCat1             varchar2(2);
    vCTypCat2             varchar2(2);
    vCTypCat3             varchar2(2);
    vCTypCat4             varchar2(2);
    vCTypCat5             varchar2(2);
    vCTypCat6             varchar2(2);

    --pList doit commencer et finir par pSeparator
    function extractvalue(pList varchar2, pSeparator varchar2, pOccurence number)
      return varchar2
    is
      vFirstOccurence number;
      vSecOccurence   number;
    begin
      vFirstOccurence  := instr(pList, pSeparator, 1, pOccurence);
      vSecOccurence    := instr(pList, pSeparator, 1, pOccurence + 1);

      if     (vFirstOccurence > 0)
         and (vSecOccurence > vFirstOccurence) then
        return substr(pList, vFirstOccurence + 1, vSecOccurence - vFirstOccurence - 1);
      else
        return null;
      end if;
    end;
  begin
    --Forcer le format de pCTypeCumul et de pCTypCat selon ';VAL1;VAL2;VALN;'. Commence et finit par ';'
    if instr(vCTypeCumuls, cntSeparator, 1, 1) > 1 then
      vCTypeCumuls  := cntSeparator || vCTypeCumuls;
    end if;

    if instr(vCTypeCumuls, cntSeparator, -1) <> length(vCTypeCumuls) then
      vCTypeCumuls  := vCTypeCumuls || cntSeparator;
    end if;

    if instr(vCTypeCat, cntSeparator, 1, 1) > 1 then
      vCTypeCat  := cntSeparator || vCTypeCat;
    end if;

    if instr(vCTypeCat, cntSeparator, -1) <> length(vCTypeCat) then
      vCTypeCat  := vCTypeCat || cntSeparator;
    end if;

    vCTypCumul1  := nvl(upper(extractvalue(vCTypeCumuls, cntSeparator, 1) ), '');
    vCTypCumul2  := nvl(upper(extractvalue(vCTypeCumuls, cntSeparator, 2) ), '');
    vCTypCumul3  := nvl(upper(extractvalue(vCTypeCumuls, cntSeparator, 3) ), '');
    vCTypCumul4  := nvl(upper(extractvalue(vCTypeCumuls, cntSeparator, 4) ), '');
    vCTypCat1    := nvl(extractvalue(vCTypeCat, cntSeparator, 1), '');
    vCTypCat2    := nvl(extractvalue(vCTypeCat, cntSeparator, 2), '');
    vCTypCat3    := nvl(extractvalue(vCTypeCat, cntSeparator, 3), '');
    vCTypCat4    := nvl(extractvalue(vCTypeCat, cntSeparator, 4), '');
    vCTypCat5    := nvl(extractvalue(vCTypeCat, cntSeparator, 5), '');
    vCTypCat6    := nvl(extractvalue(vCTypeCat, cntSeparator, 6), '');
    return GetTurnoverAmount(pAuxiliaryAccountId
                           , pFinYearId
                           , pStartNoPeriod
                           , pEndNoPeriod
                           , pFinCurrencyId
                           , pClassificationId
                           , vCTypCumul1
                           , vCTypCumul2
                           , vCTypCumul3
                           , vCTypCumul4
                           , vCTypCat1
                           , vCTypCat2
                           , vCTypCat3
                           , vCTypCat4
                           , vCTypCat5
                           , vCTypCat6
                           , 0
                           , 0
                            );
  end GetTurnoverAmount;

/*********************************************************************************************************************/
 /**
 * function GetTurnoverAmount
 * Description
 *   Calcul du chiffre d'affaire
 */
  function GetTurnoverAmount(
    pAuxiliaryAccountId ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , pFinYearId          ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pStartNoPeriod      ACS_PERIOD.PER_NO_PERIOD%type
  , pEndNoPeriod        ACS_PERIOD.PER_NO_PERIOD%type
  , pFinCurrencyId      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , pClassificationId   CLASSIFICATION.CLASSIFICATION_ID%type
  , pCTypCumul1         ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  , pCTypCumul2         ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  , pCTypCumul3         ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  , pCTypCumul4         ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  , pCTypCat2           ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat3           ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat4           ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat5           ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat6           ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat9           ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pAcsDivAccountId    ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type default 0
  , pRightsMgm          number default 0
  )
    return number
  is
    vResult    number                                                  := 0;
    vCustCoeff number(1);   -- * -1 si débiteur => montant positif
    vIsMB      number(1);
    vFinCurId  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    if nvl(pClassificationId, 0) = 0 then
      return 0;
    end if;

    begin
      select decode(SUB.C_SUB_SET, 'REC', -1, 'PAY', 1, 0)
        into vCustCoeff   -- -1 pour client, 1 pour fournisseur
        from ACS_ACCOUNT ACC
           , ACS_SUB_SET SUB
       where ACC.ACS_ACCOUNT_ID = pAuxiliaryAccountId
         and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID;
    exception
      when no_data_found then
        vCustCoeff  := 0;
    end;

    if (vCustCoeff <> 0) then
      vFinCurId  := pFinCurrencyId;

      if vFinCurId = 0 then
        vFinCurId  := ACS_FUNCTION.GetLocalCurrencyId;
        vIsMB      := 1;
      else
        select decode(ACS_FUNCTION.GetLocalCurrencyId, vFinCurId, 1, 0)
          into vIsMB   -- 1 pour la monnaie de base, 0 pour ME
          from dual;
      end if;

      -- Pour des questions de performances, limiter au strict minimum l'appel à la fonction DECODE
      if pRightsMgm > 0 then   --Avec gestion des droits par utilisateur
        if vCustCoeff = -1 then   --client (*-1 sur les montants)
          select case
                   when vIsMB > 0 then nvl(sum(nvl(V.IMF_AMOUNT_LC_D, 0) - nvl(V.IMF_AMOUNT_LC_C, 0) ), 0) * -1
                   else nvl(sum(nvl(V.IMF_AMOUNT_FC_D, 0) - nvl(V.IMF_AMOUNT_FC_C, 0) ), 0) * -1
                 end AMOUNT
            into vResult
            from V_ACT_FINANCIAL_IMPUTATION V
           where V.IMF_ACS_AUX_ACCOUNT_CUST_ID = pAuxiliaryAccountId
             and V.ACS_FINANCIAL_YEAR_ID = pFinYearId
             and V.PER_NO_PERIOD >= pStartNoPeriod
             and V.PER_NO_PERIOD <= pEndNoPeriod
             and nvl(V.ACS_DIVISION_ACCOUNT_ID, 0) in(
                              select COLUMN_VALUE
                                from table(ACS_FUNCTION.TableDivisionsAuthorized(PCS.PC_I_LIB_SESSION.GETUSERID, sysdate) ) )
             and nvl(V.ACS_DIVISION_ACCOUNT_ID, 0) =
                                        decode(pAcsDivAccountId
                                             , 0, nvl(V.ACS_DIVISION_ACCOUNT_ID, 0)
                                             , pAcsDivAccountId
                                              )
             and V.ACS_FINANCIAL_ACCOUNT_ID in(select nvl(classif_leaf_id, 0)
                                                 from classif_flat
                                                where classification_id = pClassificationId
                                                  and pc_lang_id = PCS.PC_I_LIB_SESSION.GetUserLangId)
             and V.C_TYPE_CATALOGUE in(pCTypCat2, pCTypCat3, pCTypCat4, pCTypCat5, pCTypCat6, pCTypCat9)
             and decode(vIsMB, 1, V.ACS_ACS_FINANCIAL_CURRENCY_ID, V.ACS_FINANCIAL_CURRENCY_ID) = vFinCurId
             and V.C_TYPE_CUMUL_REC in(pCTypCumul1, pCTypCumul2, pCTypCumul3, pCTypCumul4);
        elsif vCustCoeff = 1 then   --fournisseur
          select case
                   when vIsMB > 0 then nvl(sum(nvl(V.IMF_AMOUNT_LC_D, 0) - nvl(V.IMF_AMOUNT_LC_C, 0) ), 0)
                   else nvl(sum(nvl(V.IMF_AMOUNT_FC_D, 0) - nvl(V.IMF_AMOUNT_FC_C, 0) ), 0)
                 end AMOUNT
            into vResult
            from V_ACT_FINANCIAL_IMPUTATION V
           where V.IMF_ACS_AUX_ACCOUNT_SUPP_ID = pAuxiliaryAccountId
             and V.ACS_FINANCIAL_YEAR_ID = pFinYearId
             and V.PER_NO_PERIOD >= pStartNoPeriod
             and V.PER_NO_PERIOD <= pEndNoPeriod
             and nvl(V.ACS_DIVISION_ACCOUNT_ID, 0) in(
                              select COLUMN_VALUE
                                from table(ACS_FUNCTION.TableDivisionsAuthorized(PCS.PC_I_LIB_SESSION.GETUSERID, sysdate) ) )
             and nvl(V.ACS_DIVISION_ACCOUNT_ID, 0) =
                                        decode(pAcsDivAccountId
                                             , 0, nvl(V.ACS_DIVISION_ACCOUNT_ID, 0)
                                             , pAcsDivAccountId
                                              )
             and V.ACS_FINANCIAL_ACCOUNT_ID in(select nvl(classif_leaf_id, 0)
                                                 from classif_flat
                                                where classification_id = pClassificationId
                                                  and pc_lang_id = PCS.PC_I_LIB_SESSION.GetUserLangId)
             and V.C_TYPE_CATALOGUE in(pCTypCat2, pCTypCat3, pCTypCat4, pCTypCat5, pCTypCat6, pCTypCat9)
             and decode(vIsMB, 1, V.ACS_ACS_FINANCIAL_CURRENCY_ID, V.ACS_FINANCIAL_CURRENCY_ID) = vFinCurId
             and V.C_TYPE_CUMUL_PAY in(pCTypCumul1, pCTypCumul2, pCTypCumul3, pCTypCumul4);
        end if;
      else
        if vCustCoeff = -1 then   --client (*-1 sur les montants)
          select case
                   when vIsMB > 0 then nvl(sum(nvl(V.IMF_AMOUNT_LC_D, 0) - nvl(V.IMF_AMOUNT_LC_C, 0) ), 0) * -1
                   else nvl(sum(nvl(V.IMF_AMOUNT_FC_D, 0) - nvl(V.IMF_AMOUNT_FC_C, 0) ), 0) * -1
                 end AMOUNT
            into vResult
            from V_ACT_FINANCIAL_IMPUTATION V
           where V.IMF_ACS_AUX_ACCOUNT_CUST_ID = pAuxiliaryAccountId
             and V.ACS_FINANCIAL_YEAR_ID = pFinYearId
             and V.PER_NO_PERIOD >= pStartNoPeriod
             and V.PER_NO_PERIOD <= pEndNoPeriod
             and nvl(V.ACS_DIVISION_ACCOUNT_ID, 0) =
                                        decode(pAcsDivAccountId
                                             , 0, nvl(V.ACS_DIVISION_ACCOUNT_ID, 0)
                                             , pAcsDivAccountId
                                              )
             and V.ACS_FINANCIAL_ACCOUNT_ID in(select nvl(classif_leaf_id, 0)
                                                 from classif_flat
                                                where classification_id = pClassificationId
                                                  and pc_lang_id = PCS.PC_I_LIB_SESSION.GetUserLangId)
             and V.C_TYPE_CATALOGUE in(pCTypCat2, pCTypCat3, pCTypCat4, pCTypCat5, pCTypCat6, pCTypCat9)
             and decode(vIsMB, 1, V.ACS_ACS_FINANCIAL_CURRENCY_ID, V.ACS_FINANCIAL_CURRENCY_ID) = vFinCurId
             and V.C_TYPE_CUMUL_REC in(pCTypCumul1, pCTypCumul2, pCTypCumul3, pCTypCumul4);
        elsif vCustCoeff = 1 then   --fournisseur
          select case
                   when vIsMB > 0 then nvl(sum(nvl(V.IMF_AMOUNT_LC_D, 0) - nvl(V.IMF_AMOUNT_LC_C, 0) ), 0)
                   else nvl(sum(nvl(V.IMF_AMOUNT_FC_D, 0) - nvl(V.IMF_AMOUNT_FC_C, 0) ), 0)
                 end AMOUNT
            into vResult
            from V_ACT_FINANCIAL_IMPUTATION V
           where V.IMF_ACS_AUX_ACCOUNT_SUPP_ID = pAuxiliaryAccountId
             and V.ACS_FINANCIAL_YEAR_ID = pFinYearId
             and V.PER_NO_PERIOD >= pStartNoPeriod
             and V.PER_NO_PERIOD <= pEndNoPeriod
             and nvl(V.ACS_DIVISION_ACCOUNT_ID, 0) =
                                        decode(pAcsDivAccountId
                                             , 0, nvl(V.ACS_DIVISION_ACCOUNT_ID, 0)
                                             , pAcsDivAccountId
                                              )
             and V.ACS_FINANCIAL_ACCOUNT_ID in(select nvl(classif_leaf_id, 0)
                                                 from classif_flat
                                                where classification_id = pClassificationId
                                                  and pc_lang_id = PCS.PC_I_LIB_SESSION.GetUserLangId)
             and V.C_TYPE_CATALOGUE in(pCTypCat2, pCTypCat3, pCTypCat4, pCTypCat5, pCTypCat6, pCTypCat9)
             and decode(vIsMB, 1, V.ACS_ACS_FINANCIAL_CURRENCY_ID, V.ACS_FINANCIAL_CURRENCY_ID) = vFinCurId
             and V.C_TYPE_CUMUL_PAY in(pCTypCumul1, pCTypCumul2, pCTypCumul3, pCTypCumul4);
        end if;
      end if;
    end if;

    return vResult;
  end GetTurnoverAmount;

  /**
  * function GetTurnoverAmountTableTemp
  * Description
  *   Calcul du chiffre d'affaire
  */
  function GetTurnoverAmountTableTemp(
    pCSubSet          ACS_SUB_SET.C_SUB_SET%type
  , pFinYearId        ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pStartNoPeriod    ACS_PERIOD.PER_NO_PERIOD%type
  , pEndNoPeriod      ACS_PERIOD.PER_NO_PERIOD%type
  , pAcsDivAccountId  ACT_FINANCIAL_IMPUTATION.IMF_ACS_DIVISION_ACCOUNT_ID%type
  , pFinCurrencyId    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , pClassificationId CLASSIFICATION.CLASSIFICATION_ID%type
  , pCTypCumul1       ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  , pCTypCumul2       ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  , pCTypCumul3       ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  , pCTypCumul4       ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  , pCTypCat2         ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat3         ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat4         ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat5         ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat6         ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pCTypCat9         ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , pRightsMgm        number
  )
    return number
  is
    vResult    number                                                  := 0;
    vCustCoeff signtype;   -- * -1 si débiteur => montant positif
    vIsMB      signtype;
    vFinCurId  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    if nvl(pClassificationId, 0) = 0 then
      return 0;
    end if;

    begin
      select decode(pCSubSet, 'REC', -1, 'PAY', 1, 0)
        into vCustCoeff   -- -1 pour client, 1 pour fournisseur
        from dual;
    exception
      when no_data_found then
        vCustCoeff  := 0;
    end;

    if (vCustCoeff <> 0) then
      vFinCurId  := pFinCurrencyId;

      if vFinCurId = 0 then
        vFinCurId  := ACS_FUNCTION.GetLocalCurrencyId;
        vIsMB      := 1;
      else
        select decode(ACS_FUNCTION.GetLocalCurrencyId, vFinCurId, 1, 0)
          into vIsMB   -- 1 pour la monnaie de base, 0 pour ME
          from dual;
      end if;

      -- Pour des questions de performances, limiter au strict minimum l'appel à la fonction DECODE
      -- ET ne pas passer par la vue V_ACT_FINANCIAL_IMPUTATION, les indexes étant court-circuités
      if pRightsMgm > 0 then
        if vCustCoeff = -1 then   --client (*-1 sur les montants)
          select case
                   when vIsMB > 0 then nvl(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ), 0) * -1
                   else nvl(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ), 0) * -1
                 end AMOUNT
            into vResult
            from ACT_FINANCIAL_IMPUTATION IMP
               , COM_LIST_ID_TEMP TMP
               , CLASSIF_FLAT FLA
               , ACS_PERIOD PER
               , ACT_DOCUMENT DOC
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACJ_SUB_SET_CAT SUB
           where IMP.IMF_ACS_AUX_ACCOUNT_CUST_ID = TMP.LID_FREE_NUMBER_1
             and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
             and TMP.LID_CODE = 'MAIN_ID'
             and nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0) in(
                              select COLUMN_VALUE
                                from table(ACS_FUNCTION.TableDivisionsAuthorized(PCS.PC_I_LIB_SESSION.GETUSERID, sysdate) ) )
             and nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0) =
                                  decode(pAcsDivAccountId
                                       , 0, nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0)
                                       , pAcsDivAccountId
                                        )
             and PER.ACS_FINANCIAL_YEAR_ID = pFinYearId
             and IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
             and PER.PER_NO_PERIOD >= pStartNoPeriod
             and PER.PER_NO_PERIOD <= pEndNoPeriod
             and IMP.ACS_FINANCIAL_ACCOUNT_ID = FLA.CLASSIF_LEAF_ID
             and FLA.CLASSIF_LEAF_ID is not null
             and FLA.CLASSIFICATION_ID = pClassificationId
             and FLA.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
             and CAT.C_TYPE_CATALOGUE in(pCTypCat2, pCTypCat3, pCTypCat4, pCTypCat5, pCTypCat6, pCTypCat9)
             and decode(vIsMB, 1, IMP.ACS_ACS_FINANCIAL_CURRENCY_ID, IMP.ACS_FINANCIAL_CURRENCY_ID) = vFinCurId
             and SUB.C_SUB_SET = 'REC'
             and SUB.C_TYPE_CUMUL in(pCTypCumul1, pCTypCumul2, pCTypCumul3, pCTypCumul4);
        elsif vCustCoeff = 1 then   --fournisseur
          select case
                   when vIsMB > 0 then nvl(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ), 0)
                   else nvl(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ), 0)
                 end AMOUNT
            into vResult
            from ACT_FINANCIAL_IMPUTATION IMP
               , COM_LIST_ID_TEMP TMP
               , CLASSIF_FLAT FLA
               , ACS_PERIOD PER
               , ACT_DOCUMENT DOC
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACJ_SUB_SET_CAT SUB
           where IMP.IMF_ACS_AUX_ACCOUNT_SUPP_ID = TMP.LID_FREE_NUMBER_1
             and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
             and TMP.LID_CODE = 'MAIN_ID'
             and nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0) in(
                              select COLUMN_VALUE
                                from table(ACS_FUNCTION.TableDivisionsAuthorized(PCS.PC_I_LIB_SESSION.GETUSERID, sysdate) ) )
             and nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0) =
                                  decode(pAcsDivAccountId
                                       , 0, nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0)
                                       , pAcsDivAccountId
                                        )
             and PER.ACS_FINANCIAL_YEAR_ID = pFinYearId
             and IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
             and PER.PER_NO_PERIOD >= pStartNoPeriod
             and PER.PER_NO_PERIOD <= pEndNoPeriod
             and IMP.ACS_FINANCIAL_ACCOUNT_ID = FLA.CLASSIF_LEAF_ID
             and FLA.CLASSIF_LEAF_ID is not null
             and FLA.CLASSIFICATION_ID = pClassificationId
             and FLA.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
             and CAT.C_TYPE_CATALOGUE in(pCTypCat2, pCTypCat3, pCTypCat4, pCTypCat5, pCTypCat6, pCTypCat9)
             and decode(vIsMB, 1, IMP.ACS_ACS_FINANCIAL_CURRENCY_ID, IMP.ACS_FINANCIAL_CURRENCY_ID) = vFinCurId
             and SUB.C_SUB_SET = 'PAY'
             and SUB.C_TYPE_CUMUL in(pCTypCumul1, pCTypCumul2, pCTypCumul3, pCTypCumul4);
        end if;
      else   -- Sans gestion des droits par utilisateur
        if vCustCoeff = -1 then   --client (*-1 sur les montants)
          select case
                   when vIsMB > 0 then nvl(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ), 0) * -1
                   else nvl(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ), 0) * -1
                 end AMOUNT
            into vResult
            from ACT_FINANCIAL_IMPUTATION IMP
               , COM_LIST_ID_TEMP TMP
               , CLASSIF_FLAT FLA
               , ACS_PERIOD PER
               , ACT_DOCUMENT DOC
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACJ_SUB_SET_CAT SUB
           where IMP.IMF_ACS_AUX_ACCOUNT_CUST_ID = TMP.LID_FREE_NUMBER_1
             and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
             and TMP.LID_CODE = 'MAIN_ID'
             and nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0) =
                                  decode(pAcsDivAccountId
                                       , 0, nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0)
                                       , pAcsDivAccountId
                                        )
             and PER.ACS_FINANCIAL_YEAR_ID = pFinYearId
             and IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
             and PER.PER_NO_PERIOD >= pStartNoPeriod
             and PER.PER_NO_PERIOD <= pEndNoPeriod
             and IMP.ACS_FINANCIAL_ACCOUNT_ID = FLA.CLASSIF_LEAF_ID
             and FLA.CLASSIF_LEAF_ID is not null
             and FLA.CLASSIFICATION_ID = pClassificationId
             and FLA.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
             and CAT.C_TYPE_CATALOGUE in(pCTypCat2, pCTypCat3, pCTypCat4, pCTypCat5, pCTypCat6, pCTypCat9)
             and decode(vIsMB, 1, IMP.ACS_ACS_FINANCIAL_CURRENCY_ID, IMP.ACS_FINANCIAL_CURRENCY_ID) = vFinCurId
             and SUB.C_SUB_SET = 'REC'
             and SUB.C_TYPE_CUMUL in(pCTypCumul1, pCTypCumul2, pCTypCumul3, pCTypCumul4);
        elsif vCustCoeff = 1 then   --fournisseur
          select case
                   when vIsMB > 0 then nvl(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ), 0)
                   else nvl(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ), 0)
                 end AMOUNT
            into vResult
            from ACT_FINANCIAL_IMPUTATION IMP
               , COM_LIST_ID_TEMP TMP
               , CLASSIF_FLAT FLA
               , ACS_PERIOD PER
               , ACT_DOCUMENT DOC
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACJ_SUB_SET_CAT SUB
           where IMP.IMF_ACS_AUX_ACCOUNT_SUPP_ID = TMP.LID_FREE_NUMBER_1
             and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
             and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
             and TMP.LID_CODE = 'MAIN_ID'
             and nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0) =
                                  decode(pAcsDivAccountId
                                       , 0, nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0)
                                       , pAcsDivAccountId
                                        )
             and PER.ACS_FINANCIAL_YEAR_ID = pFinYearId
             and IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
             and PER.PER_NO_PERIOD >= pStartNoPeriod
             and PER.PER_NO_PERIOD <= pEndNoPeriod
             and IMP.ACS_FINANCIAL_ACCOUNT_ID = FLA.CLASSIF_LEAF_ID
             and FLA.CLASSIF_LEAF_ID is not null
             and FLA.CLASSIFICATION_ID = pClassificationId
             and FLA.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
             and CAT.C_TYPE_CATALOGUE in(pCTypCat2, pCTypCat3, pCTypCat4, pCTypCat5, pCTypCat6, pCTypCat9)
             and decode(vIsMB, 1, IMP.ACS_ACS_FINANCIAL_CURRENCY_ID, IMP.ACS_FINANCIAL_CURRENCY_ID) = vFinCurId
             and SUB.C_SUB_SET = 'PAY'
             and SUB.C_TYPE_CUMUL in(pCTypCumul1, pCTypCumul2, pCTypCumul3, pCTypCumul4);
        end if;
      end if;
    end if;

    return vResult;
  end GetTurnoverAmountTableTemp;

  /**
  * function GetChildrenLinkedDocRecord
  * Description
  *  Retourne les enfants du dossier pPARENT_DOC_RECORD_ID jusqu'au niveau pLEVEL (0 = parent seul, 1 = 1er enfant, ...)
  *  Exemple d'utilisation dans une commande SQL:
  *  select rco.*
  *  from  table(ACR_FUNCTIONS.GetChildrenLinkedDocRecord(:p_PARENT_DOC_RECORD_ID, :pLEVEL)) ChildrenDoc,
  *        doc_record rco
  *  where
  *        ChildrenDoc.column_VALUE = rco.doc_record_id
  **/
  function GetChildrenLinkedDocRecord(pPARENT_DOC_RECORD_ID DOC_RECORD_LINK.DOC_RECORD_FATHER_ID%type, pLevel number)
    return ID_TABLE_TYPE
  is
    vResult      ID_TABLE_TYPE;
    vProjects    ID_TABLE_TYPE;
    vDocRecordID DOC_RECORD_LINK.DOC_RECORD_FATHER_ID%type;
    vCRcoType    DOC_RECORD.C_RCO_TYPE%type;
    vLevel       number;
  begin
    --Niveau 1 = Parent  => Pour connaitre le niveau voulu, il faut ajouter 1 à pLEVEL
    --Ex: pLevel = 0 => Retourne le parent
    -- max 20 niveaux
    vLevel        := pLevel;

    if vLevel > 20 then
      vLevel  := 20;
    end if;

    vDocRecordID  := pPARENT_DOC_RECORD_ID;

    select nvl(max(RCO.C_RCO_TYPE), '00')
      into vCRcoType
      from DOC_RECORD RCO
     where RCO.DOC_RECORD_ID = vDocRecordID;

    if vCRcoType = '09' then   --C_RCO_TYPE = '09'
      select COLUMN_VALUE ALL_IDS
      bulk collect into vProjects
        from table(GAL_FUNCTIONS.GetProjectOrderRecord(vDocRecordID) );

      select ALL_IDS
      bulk collect into vResult
        from (select     DOC_RECORD_SON_ID ALL_IDS
                    from DOC_RECORD_LINK LIN
                   where level <= vLevel
                     and exists(
                           select 1
                             from DOC_RECORD_CATEGORY_LINK CAT
                            where CAT.C_RCO_LINK_TYPE = '1'
                              and LIN.DOC_RECORD_CATEGORY_LINK_ID = CAT.DOC_RECORD_CATEGORY_LINK_ID)
              start with DOC_RECORD_FATHER_ID in(select COLUMN_VALUE
                                                   from table(vProjects) )
              connect by DOC_RECORD_FATHER_ID = prior DOC_RECORD_SON_ID);
      vResult := vResult multiset union distinct vProjects;
    else
      select ALL_IDS
      bulk collect into vResult
        from (select distinct (DOC_RECORD_SON_ID) ALL_IDS
                         from DOC_RECORD_LINK LIN
                        where level <= vLevel
                          and exists(
                                select 1
                                  from DOC_RECORD_CATEGORY_LINK CAT
                                 where CAT.C_RCO_LINK_TYPE = '1'
                                   and LIN.DOC_RECORD_CATEGORY_LINK_ID = CAT.DOC_RECORD_CATEGORY_LINK_ID)
                   start with DOC_RECORD_FATHER_ID = vDocRecordID
                   connect by DOC_RECORD_FATHER_ID = prior DOC_RECORD_SON_ID);
    end if;

    vResult := vResult multiset union distinct ID_TABLE_TYPE(vDocRecordID);
    return vResult;
  end GetChildrenLinkedDocRecord;

  /**
  * function GetChildrenLinkedDocRecordList
  * Description
  *  Retourne les enfants des dossiers mis dans la table temporaire jusqu'au niveau pLEVEL (0 = parent seul, 1 = 1er enfant, ...)
  *  Exemple d'utilisation dans une commande SQL:
  *  select rco.*
  *  from  table(ACR_FUNCTIONS.GetChildrenLinkedDocRecordList(:pLEVEL)) ChildrenDoc,
  *        doc_record rco
  *  where
  *        ChildrenDoc.column_VALUE = rco.doc_record_id
  **/
  function GetChildrenLinkedDocRecordList(pLevel number)
    return ID_TABLE_TYPE
  is
    vTblDocRecordID  ID_TABLE_TYPE;
    vResult          ID_TABLE_TYPE;
    vProjects        ID_TABLE_TYPE;
    vTemp            ID_TABLE_TYPE;
    vTblDocProjectID ID_TABLE_TYPE;
    vDocRecordID     DOC_RECORD_LINK.DOC_RECORD_FATHER_ID%type;
    vLevel           number;
  begin
    vResult          := ID_TABLE_TYPE(0);
    vTblDocRecordID  := ID_TABLE_TYPE();

    if ACR_FUNCTIONS.FillInTbl(vTblDocRecordID) then
      --Niveau 1 = Parent  => Pour connaitre le niveau voulu, il faut ajouter 1 … pLEVEL
      --Ex: pLevel = 0 => Retourne le parent

      -- max 20 niveaux
      vLevel  := pLevel;

      if vLevel > 20 then
        vLevel  := 20;
      end if;

      begin
        select COLUMN_VALUE
        bulk collect into vTblDocProjectID
          from table(vTblDocRecordID) TMP
             , DOC_RECORD RCO
         where RCO.DOC_RECORD_ID = TMP.COLUMN_VALUE
           and RCO.C_RCO_TYPE = '09';
      exception
        when no_data_found then
          vTblDocProjectID  := ID_TABLE_TYPE();
      end;

      -- Supprimer les dossiers de type 09 déjà traités ci-dessus;
      vTblDocRecordID := vTblDocRecordID multiset except vTblDocProjectID;

      -- Recherche des affaires liées ('09')
      if vTblDocProjectID.exists(1) then
        select COLUMN_VALUE ALL_IDS
        bulk collect into vProjects
          from table(GAL_FUNCTIONS.GetProjectOrderRecord(0, vTblDocProjectID) );

        select ALL_IDS
        bulk collect into vResult
          from (select     DOC_RECORD_SON_ID ALL_IDS
                      from DOC_RECORD_LINK LIN
                     where level <= vLevel
                       and exists(
                             select 1
                               from DOC_RECORD_CATEGORY_LINK CAT
                              where CAT.C_RCO_LINK_TYPE = '1'
                                and LIN.DOC_RECORD_CATEGORY_LINK_ID = CAT.DOC_RECORD_CATEGORY_LINK_ID)
                start with DOC_RECORD_FATHER_ID in(select COLUMN_VALUE
                                                     from table(vProjects) )
                connect by DOC_RECORD_FATHER_ID = prior DOC_RECORD_SON_ID);
        vResult := vResult multiset union distinct vProjects;
      end if;

      --Recherche des dossiers liés pour tous les autres types de dossiers
      if vTblDocRecordID.exists(1) then
        select ALL_IDS
        bulk collect into vTemp
          from (select     DOC_RECORD_SON_ID ALL_IDS
                      from DOC_RECORD_LINK LIN
                     where level <= vLevel
                       and exists(
                             select 1
                               from DOC_RECORD_CATEGORY_LINK CAT
                              where CAT.C_RCO_LINK_TYPE = '1'
                                and LIN.DOC_RECORD_CATEGORY_LINK_ID = CAT.DOC_RECORD_CATEGORY_LINK_ID)
                start with DOC_RECORD_FATHER_ID in(select COLUMN_VALUE
                                                     from table(vTblDocRecordID) )
                connect by DOC_RECORD_FATHER_ID = prior DOC_RECORD_SON_ID);
        vResult := vResult multiset union distinct (vTemp multiset union distinct vTblDocRecordID);
      end if;
    end if;

    return vResult;
  end GetChildrenLinkedDocRecordList;

  /**
  * function GetSubAccounts
  * Description
  *  Retourne les sous-comptes du compte pPARENT_ACS_ACCOUNT_ID jusqu'au niveau pLEVEL (0 = parent seul, 1 = 1er enfant, ...)
  *  Exemple d'utilisation dans une commande SQL:
  *  select ACC.*
  *  from  table(ACR_FUNCTIONS.GetSubAccounts(:p_PARENT_ACS_ACCOUNT_ID, :pLEVEL)) SubAccounts,
  *        acs_account acc
  *  where
  *        SubAccounts.column_VALUE = acc.acs_account_id
  **/
  function GetSubAccounts(pPARENT_ACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type, pLevel number)
    return ID_TABLE_TYPE
  is
    vResult ID_TABLE_TYPE;
    vLevel  number;
  begin
    --Niveau 1 = Parent  => Pour connaitre le niveau voulu, il faut ajouter 1 à pLEVEL
    --Ex: pLevel = 0 => Retourne le parent
    -- max 10 niveaux
    vLevel  := pLevel + 1;

    if vLevel > 11 then
      vLevel  := 11;
    end if;

    select ALL_IDS
    bulk collect into vResult
      from (select     ACS_ACCOUNT_ID ALL_IDS
                  from ACS_ACCOUNT ACC
                 where level <= vLevel
            start with ACS_ACCOUNT_ID = pPARENT_ACS_ACCOUNT_ID
            connect by ACS_SUB_ACCOUNT_ID = prior ACS_ACCOUNT_ID);

    return vResult;
  end GetSubAccounts;

  /**
  * function GetSubAccountsList
  * Description
  *  Retourne les enfants des comptes présents dans COM_LIST_ID_TEMP jusqu'au niveau pLEVEL (0 = parent seul, 1 = 1er enfant, ...)
  * @lastUpdate
  * @public
  * @param pLEVEL                  niveau max recherché: 0 = le compte parent autrement le niveau indiqué ( 1 = premier enfant)
  * @return ID_TABLE_TYPE = liste des ids recherchés
  **/
  function GetSubAccountsList(pLEVEL number)
    return ID_TABLE_TYPE
  is
    vResult ID_TABLE_TYPE;
    vLevel  number;
  begin
    --Niveau 1 = Parent  => Pour connaitre le niveau voulu, il faut ajouter 1 à pLEVEL
    --Ex: pLevel = 0 => Retourne le parent
    -- max 10 niveaux
    vLevel  := pLevel + 1;

    if vLevel > 11 then
      vLevel  := 11;
    end if;

    select distinct ALL_IDS
    bulk collect into vResult
               from (select     ACS_ACCOUNT_ID ALL_IDS
                           from ACS_ACCOUNT ACC
                          where level <= vLevel
                     start with ACS_ACCOUNT_ID in(select LID_FREE_NUMBER_1 ACS_ACCOUNT_ID
                                                    from COM_LIST_ID_TEMP)
                     connect by ACS_SUB_ACCOUNT_ID = prior ACS_ACCOUNT_ID);

    return vResult;
  end GetSubAccountsList;

  /**
  * function FillInTbl
  * Description
  *   Remplit un tableau à partir d'une table temporaire. Celle-ci doit avoir été remplie auparavant bien sûr !!!
  */
  function FillInTbl(pTblID in out ID_TABLE_TYPE)
    return boolean
  is
  begin
    if pTblID is not null then
      select to_number(LID_FREE_NUMBER_1) DOC_RECORD_ID
      bulk collect into pTblID
        from COM_LIST_ID_TEMP
       where LID_FREE_NUMBER_1 is not null
         and LID_CODE = 'MAIN_ID';   --VOIRE UNIT DELPHI ACR_cntReporting
    end if;

    return pTblID.exists(1);
  end FillInTbl;

  procedure SumExpenseReceiptDetails(aHeaderId ACR_MGM_RCO_FINANCING_HD.ACR_MGM_RCO_FINANCING_HD_ID%type)
  is
    cursor crDetailSum
    is
      select   ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , DOC_RECORD_ID
             , DOC_RECORD_FATHER_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACR_MGM_RCO_FINANCING_HD_ID
             , sum(IMM_AMOUNT_LC_D) IMM_AMOUNT_LC_D
             , sum(IMM_AMOUNT_LC_C) IMM_AMOUNT_LC_C
             , sum(IMM_AMOUNT_FC_D) IMM_AMOUNT_FC_D
             , sum(IMM_AMOUNT_FC_C) IMM_AMOUNT_FC_C
             , sum(IMM_QUANTITY_D) IMM_QUANTITY_D
             , sum(IMM_QUANTITY_C) IMM_QUANTITY_C
             , to_char(IMM_VALUE_DATE, 'YYYY.MM') PERIOD
          from ACR_MGM_RCO_FINANCING_DET
         where ACR_MGM_RCO_FINANCING_HD_ID = aHeaderId
      group by ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , DOC_RECORD_ID
             , DOC_RECORD_FATHER_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACR_MGM_RCO_FINANCING_HD_ID
             , to_char(IMM_VALUE_DATE, 'YYYY.MM');

    tplDetailSum crDetailSum%rowtype;
  begin
    open crDetailSum;

    fetch crDetailSum
     into tplDetailSum;

    while crDetailSum%found loop
      insert into ACR_MGM_RCO_FINANCING_SUM
                  (ACR_MGM_RCO_FINANCING_SUM_ID
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , DOC_RECORD_ID
                 , DOC_RECORD_FATHER_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , ACR_MGM_RCO_FINANCING_HD_ID
                 , IMM_AMOUNT_LC_D
                 , IMM_AMOUNT_LC_C
                 , IMM_AMOUNT_FC_D
                 , IMM_AMOUNT_FC_C
                 , IMM_QUANTITY_D
                 , IMM_QUANTITY_C
                 , IMM_PERIOD
                  )
           values (INIT_ID_SEQ.nextval
                 , tplDetailSum.ACS_CDA_ACCOUNT_ID
                 , tplDetailSum.ACS_CPN_ACCOUNT_ID
                 , tplDetailSum.DOC_RECORD_ID
                 , tplDetailSum.DOC_RECORD_FATHER_ID
                 , tplDetailSum.ACS_FINANCIAL_CURRENCY_ID
                 , tplDetailSum.ACS_ACS_FINANCIAL_CURRENCY_ID
                 , tplDetailSum.ACR_MGM_RCO_FINANCING_HD_ID
                 , tplDetailSum.IMM_AMOUNT_LC_D
                 , tplDetailSum.IMM_AMOUNT_LC_C
                 , tplDetailSum.IMM_AMOUNT_FC_D
                 , tplDetailSum.IMM_AMOUNT_FC_C
                 , tplDetailSum.IMM_QUANTITY_D
                 , tplDetailSum.IMM_QUANTITY_C
                 , tplDetailSum.PERIOD
                  );

      fetch crDetailSum
       into tplDetailSum;
    end loop;
  end SumExpenseReceiptDetails;

  procedure GenerateExpenseReceiptDetails(
    aRecordId DOC_RECORD.DOC_RECORD_ID%type
  , aHeaderId ACR_MGM_RCO_FINANCING_HD.ACR_MGM_RCO_FINANCING_HD_ID%type
  )
  is
    cursor crCollDocuments(pHeaderId ACR_MGM_RCO_FINANCING_HD.ACR_MGM_RCO_FINANCING_HD_ID%type)
    is
      select DOO.ACT_DOCUMENT_ID ORIGIN_DOC_ID
           , IMF.ACT_FINANCIAL_IMPUTATION_ID
           , IMF.IMF_VALUE_DATE
           , IMF.IMF_TRANSACTION_DATE
           , IMF.ACS_PERIOD_ID
           , IMF.IMF_AMOUNT_LC_D - IMF.IMF_AMOUNT_LC_C IMF_AMOUNT_LC_D
           , IMF.IMF_AMOUNT_FC_D - IMF.IMF_AMOUNT_FC_C IMF_AMOUNT_FC_D
           , IMF.IMF_EXCHANGE_RATE
           , IMF.IMF_BASE_PRICE
        from ACT_DOCUMENT DOC
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_FINANCIAL_IMPUTATION IMF
           , ACS_FINANCIAL_ACCOUNT FIN
           , ACT_DET_PAYMENT DET
           , ACT_EXPIRY exp
           , ACJ_CATALOGUE_DOCUMENT CAO
           , ACT_DOCUMENT DOO
       where DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID   -- Doc. analysés de type paiements/lettrage
         and CAT.C_TYPE_CATALOGUE in('3', '4', '9')   -- (3,4,9) et catalogue prend en compte les "Dépenses/Recettes"
         and CAT.CAT_EXPENSE_RECEIPT = 1
         --Ecritures sans spécification (1) et Diff.de change(4)...
         and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
         and IMF.C_GENRE_TRANSACTION in('1', '4')
         --sur des comptes collectifs
         and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and FIN.FIN_COLLECTIVE = 1
         --dont le document d'origine est de type 2,3,4,5,6
         and IMF.ACT_DET_PAYMENT_ID = DET.ACT_DET_PAYMENT_ID
         and DET.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
         and exp.ACT_DOCUMENT_ID = DOO.ACT_DOCUMENT_ID
         and DOO.ACJ_CATALOGUE_DOCUMENT_ID = CAO.ACJ_CATALOGUE_DOCUMENT_ID
         and CAO.C_TYPE_CATALOGUE in('2', '5', '6')
         and CAO.CAT_EXPENSE_RECEIPT = 1
         --et dont au moins une imputation gère un dossier de calcul
         --et ayant un CPN qui gère les dépenses recettes
         and exists(
               select 1
                 from ACT_MGM_IMPUTATION IMM
                    , ACR_MGM_RCO_FINANCING_RCO RCO
                    , ACS_CPN_ACCOUNT CPN
                where DOO.ACT_DOCUMENT_ID = IMM.ACT_DOCUMENT_ID
                  and RCO.ACR_MGM_RCO_FINANCING_HD_ID = pHeaderId
                  and IMM.DOC_RECORD_ID = RCO.DOC_RECORD_ID
                  and IMM.ACS_CPN_ACCOUNT_ID = CPN.ACS_CPN_ACCOUNT_ID
                  and CPN.C_EXPENSE_RECEIPT <> '0');

    --Recherche des données par document. Utilisé dans ce contexte pour les document
    --d'origine des imputations traités
    cursor crDocImputation(
      aActDocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type
    , aDetHeaderId   ACR_MGM_RCO_FINANCING_HD.ACR_MGM_RCO_FINANCING_HD_ID%type
    )
    is
      select   aDetHeaderId ACR_MGM_RCO_FINANCING_HD_ID
             , CPN.C_EXPENSE_RECEIPT
             , IMM.ACT_MGM_IMPUTATION_ID
             , IMM.ACS_PERIOD_ID
             , IMM.ACS_FINANCIAL_CURRENCY_ID
             , IMM.ACS_QTY_UNIT_ID
             , IMM.ACS_PF_ACCOUNT_ID
             , IMM.ACS_CDA_ACCOUNT_ID
             , IMM.ACS_CPN_ACCOUNT_ID
             , IMM.ACS_ACS_FINANCIAL_CURRENCY_ID
             , IMM.DOC_RECORD_ID
             , nvl(decode(DRL.DOC_RECORD_FATHER_ID, aRecordId, IMM.DOC_RECORD_ID, DRL.DOC_RECORD_FATHER_ID)
                 , IMM.DOC_RECORD_ID
                  ) DOC_RECORD_FATHER_ID
             , IMM.IMM_TYPE
             , IMM.IMM_GENRE
             , IMM.IMM_PRIMARY
             , IMM.IMM_DESCRIPTION
             , IMM.IMM_AMOUNT_LC_D
             , IMM.IMM_AMOUNT_LC_C
             , IMM.IMM_EXCHANGE_RATE
             , IMM.IMM_BASE_PRICE
             , IMM.IMM_AMOUNT_FC_D
             , IMM.IMM_AMOUNT_FC_C
             , IMM.IMM_VALUE_DATE
             , IMM.IMM_TRANSACTION_DATE
             , IMM.IMM_QUANTITY_D
             , IMM.IMM_QUANTITY_C
             , IMM.IMM_NUMBER
             , IMM.IMM_NUMBER2
             , IMM.IMM_NUMBER3
             , IMM.IMM_NUMBER4
             , IMM.IMM_NUMBER5
             , IMM.IMM_TEXT1
             , IMM.IMM_TEXT2
             , IMM.IMM_TEXT3
             , IMM.IMM_TEXT4
             , IMM.IMM_TEXT5
          from ACT_MGM_IMPUTATION IMM
             , (select distinct FAT.DOC_RECORD_SON_ID
                              , FAT.DOC_RECORD_FATHER_ID
                              , RCO.DOC_RECORD_ID
                           from DOC_RECORD RCO
                              , DOC_RECORD_LINK FAT
                          where RCO.C_RCO_TYPE <> '09'
                            and FAT.DOC_RECORD_FATHER_ID = RCO.DOC_RECORD_ID) DRL
             , ACS_CPN_ACCOUNT CPN
         where IMM.ACT_DOCUMENT_ID = aActDocumentId
           and DRL.DOC_RECORD_SON_ID(+) = IMM.DOC_RECORD_ID
           and CPN.ACS_CPN_ACCOUNT_ID = IMM.ACS_CPN_ACCOUNT_ID
      order by IMM.ACT_MGM_IMPUTATION_ID;

    tplCollDocuments              crCollDocuments%rowtype;
    tplDocImputation              crDocImputation%rowtype;
    vOriginDocLastImputationsId   ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;   /* Id dernière imputation du document origine de l'imputation courante*/
    vOriginDocImputationSumLC     ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type;   /* Somme des imputations du document d'origine de l'imputation courante*/
    vOriginDocImputationSumFC     ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type;   /* Somme des imputations du document d'origine de l'imputation courante*/
    vOriginDocImputationSumQTY    ACT_MGM_IMPUTATION.IMM_QUANTITY_C%type;   /* Somme des quantités du document d'origine de l'imputation courante*/
    vOriginDocImputProport_LC     number(15, 6);   /* Proportion (montant imputation courante / montant total document origine)*/
    vOriginDocImputProport_FC     number(15, 6);   /* Proportion (montant imputation courante / montant total document origine)*/
    vOriginDocImputProport_QTY    number(15, 6);   /* Proportion (montant imputation courante / montant total document origine)*/
    vOriginProportionalAmountLC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;   /* Montant proportionnel cadré sur imputation origine MB */
    vOriginProportionalAmountLC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;   /* Montant proportionnel cadré sur imputation origine MB */
    vOriginProportionalAmountFC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;   /* Montant proportionnel cadré sur imputation origine  ME */
    vOriginProportionalAmountFC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;   /* Montant proportionnel cadré sur imputation origine  ME */
    vOriginProportionalQty_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;   /* Quantité proportionnelle cadrée sur quantité origine */
    vOriginProportionalQty_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;   /* Quantité proportionnelle cadrée sur quantité origine */
    AmountLC_D                    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    AmountLC_C                    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    AmountFC_D                    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    AmountFC_C                    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    AmountEUR_D                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    AmountEUR_C                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    ExchangeRate                  ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePrice                     ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;

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

    function IsListedRecord(
      aDocRecordId DOC_RECORD.DOC_RECORD_ID%type
    , aHeaderId    ACR_MGM_RCO_FINANCING_HD.ACR_MGM_RCO_FINANCING_HD_ID%type
    )
      return boolean
    is
      vRecordId DOC_RECORD.DOC_RECORD_ID%type;
    begin
      select nvl(max(DOC_RECORD_ID), 0)
        into vRecordId
        from ACR_MGM_RCO_FINANCING_RCO RCO
       where RCO.DOC_RECORD_ID = aDocRecordId
         and RCO.ACR_MGM_RCO_FINANCING_HD_ID = aHeaderId;

      return(vRecordId <> 0);
    end IsListedRecord;
  begin
    --Document type 1 : Toutes les imputations de ce type sont prises en compte.
    insert into ACR_MGM_RCO_FINANCING_DET
                (ACR_MGM_RCO_FINANCING_DET_ID
               , ACR_MGM_RCO_FINANCING_HD_ID
               , ACS_PERIOD_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_QTY_UNIT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , DOC_RECORD_ID
               , DOC_RECORD_FATHER_ID
               , ACT_MGM_IMPUTATION_ID
               , IMM_TYPE
               , IMM_GENRE
               , IMM_PRIMARY
               , IMM_DESCRIPTION
               , IMM_AMOUNT_LC_D
               , IMM_AMOUNT_LC_C
               , IMM_EXCHANGE_RATE
               , IMM_BASE_PRICE
               , IMM_AMOUNT_FC_D
               , IMM_AMOUNT_FC_C
               , IMM_VALUE_DATE
               , IMM_TRANSACTION_DATE
               , IMM_QUANTITY_D
               , IMM_QUANTITY_C
               , IMM_NUMBER1
               , IMM_NUMBER2
               , IMM_NUMBER3
               , IMM_NUMBER4
               , IMM_NUMBER5
               , IMM_TEXT1
               , IMM_TEXT2
               , IMM_TEXT3
               , IMM_TEXT4
               , IMM_TEXT5
                )
      select INIT_ID_SEQ.nextval
           , aHeaderId
           , IMM.ACS_PERIOD_ID
           , IMM.ACS_FINANCIAL_CURRENCY_ID
           , IMM.ACS_QTY_UNIT_ID
           , IMM.ACS_PF_ACCOUNT_ID
           , IMM.ACS_CDA_ACCOUNT_ID
           , IMM.ACS_CPN_ACCOUNT_ID
           , IMM.ACS_ACS_FINANCIAL_CURRENCY_ID
           , IMM.DOC_RECORD_ID
           , nvl(decode(DRL.DOC_RECORD_FATHER_ID, aRecordId, IMM.DOC_RECORD_ID, DRL.DOC_RECORD_FATHER_ID)
               , IMM.DOC_RECORD_ID
                )
           , IMM.ACT_MGM_IMPUTATION_ID
           , IMM.IMM_TYPE
           , IMM.IMM_GENRE
           , IMM.IMM_PRIMARY
           , IMM.IMM_DESCRIPTION
           , IMM.IMM_AMOUNT_LC_D
           , IMM.IMM_AMOUNT_LC_C
           , IMM.IMM_EXCHANGE_RATE
           , IMM.IMM_BASE_PRICE
           , IMM.IMM_AMOUNT_FC_D
           , IMM.IMM_AMOUNT_FC_C
           , IMM.IMM_VALUE_DATE
           , IMM.IMM_TRANSACTION_DATE
           , nvl(IMM.IMM_QUANTITY_D, 0)
           , nvl(IMM.IMM_QUANTITY_C, 0)
           , IMM.IMM_NUMBER
           , IMM.IMM_NUMBER2
           , IMM.IMM_NUMBER3
           , IMM.IMM_NUMBER4
           , IMM.IMM_NUMBER5
           , IMM.IMM_TEXT1
           , IMM.IMM_TEXT2
           , IMM.IMM_TEXT3
           , IMM.IMM_TEXT4
           , IMM.IMM_TEXT5
        from ACT_MGM_IMPUTATION IMM
           , (select distinct FAT.DOC_RECORD_SON_ID
                            , FAT.DOC_RECORD_FATHER_ID
                            , RCO.DOC_RECORD_ID
                         from DOC_RECORD RCO
                            , DOC_RECORD_LINK FAT
                        where RCO.C_RCO_TYPE <> '09'
                          and FAT.DOC_RECORD_FATHER_ID = RCO.DOC_RECORD_ID) DRL
           , ACR_MGM_RCO_FINANCING_RCO RCO
       where IMM.DOC_RECORD_ID = RCO.DOC_RECORD_ID
         and RCO.ACR_MGM_RCO_FINANCING_HD_ID = aHeaderId
         and DRL.DOC_RECORD_SON_ID(+) = IMM.DOC_RECORD_ID
         --Prise en compte Dépenses ou Recettes au niveau du CPN
         and exists(select 1
                      from ACS_CPN_ACCOUNT CPN
                     where IMM.ACS_CPN_ACCOUNT_ID = CPN.ACS_CPN_ACCOUNT_ID
                       and CPN.C_EXPENSE_RECEIPT <> '0')
         --Documents de type 1 et catalogue doit prendre en compte les "Dépenses/Recettes"
         and exists(
               select 1
                 from ACT_DOCUMENT DOC
                    , ACJ_CATALOGUE_DOCUMENT CAT
                where IMM.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                  and CAT.C_TYPE_CATALOGUE = 1
                  and CAT.CAT_EXPENSE_RECEIPT = 1);

    --Document paeiement / lettrage (3,4,9) non collectifs : Toutes les imputations de ce type sont prises en compte.
    insert into ACR_MGM_RCO_FINANCING_DET
                (ACR_MGM_RCO_FINANCING_DET_ID
               , ACR_MGM_RCO_FINANCING_HD_ID
               , ACS_PERIOD_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_QTY_UNIT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , DOC_RECORD_ID
               , DOC_RECORD_FATHER_ID
               , ACT_MGM_IMPUTATION_ID
               , IMM_TYPE
               , IMM_GENRE
               , IMM_PRIMARY
               , IMM_DESCRIPTION
               , IMM_AMOUNT_LC_D
               , IMM_AMOUNT_LC_C
               , IMM_EXCHANGE_RATE
               , IMM_BASE_PRICE
               , IMM_AMOUNT_FC_D
               , IMM_AMOUNT_FC_C
               , IMM_VALUE_DATE
               , IMM_TRANSACTION_DATE
               , IMM_QUANTITY_D
               , IMM_QUANTITY_C
               , IMM_NUMBER1
               , IMM_NUMBER2
               , IMM_NUMBER3
               , IMM_NUMBER4
               , IMM_NUMBER5
               , IMM_TEXT1
               , IMM_TEXT2
               , IMM_TEXT3
               , IMM_TEXT4
               , IMM_TEXT5
                )
      select INIT_ID_SEQ.nextval
           , aHeaderId
           , IMM.ACS_PERIOD_ID
           , IMM.ACS_FINANCIAL_CURRENCY_ID
           , IMM.ACS_QTY_UNIT_ID
           , IMM.ACS_PF_ACCOUNT_ID
           , IMM.ACS_CDA_ACCOUNT_ID
           , IMM.ACS_CPN_ACCOUNT_ID
           , IMM.ACS_ACS_FINANCIAL_CURRENCY_ID
           , IMM.DOC_RECORD_ID
           , nvl(decode(DRL.DOC_RECORD_FATHER_ID, aRecordId, IMM.DOC_RECORD_ID, DRL.DOC_RECORD_FATHER_ID)
               , IMM.DOC_RECORD_ID
                )
           , IMM.ACT_MGM_IMPUTATION_ID
           , IMM.IMM_TYPE
           , IMM.IMM_GENRE
           , IMM.IMM_PRIMARY
           , IMM.IMM_DESCRIPTION
           , IMM.IMM_AMOUNT_LC_D
           , IMM.IMM_AMOUNT_LC_C
           , IMM.IMM_EXCHANGE_RATE
           , IMM.IMM_BASE_PRICE
           , IMM.IMM_AMOUNT_FC_D
           , IMM.IMM_AMOUNT_FC_C
           , IMM.IMM_VALUE_DATE
           , IMM.IMM_TRANSACTION_DATE
           , nvl(IMM.IMM_QUANTITY_D, 0)
           , nvl(IMM.IMM_QUANTITY_C, 0)
           , IMM.IMM_NUMBER
           , IMM.IMM_NUMBER2
           , IMM.IMM_NUMBER3
           , IMM.IMM_NUMBER4
           , IMM.IMM_NUMBER5
           , IMM.IMM_TEXT1
           , IMM.IMM_TEXT2
           , IMM.IMM_TEXT3
           , IMM.IMM_TEXT4
           , IMM.IMM_TEXT5
        from ACT_MGM_IMPUTATION IMM
           , (select distinct FAT.DOC_RECORD_SON_ID
                            , FAT.DOC_RECORD_FATHER_ID
                            , RCO.DOC_RECORD_ID
                         from DOC_RECORD RCO
                            , DOC_RECORD_LINK FAT
                        where RCO.C_RCO_TYPE <> '09'
                          and FAT.DOC_RECORD_FATHER_ID = RCO.DOC_RECORD_ID) DRL
           , ACR_MGM_RCO_FINANCING_RCO RCO
       where IMM.DOC_RECORD_ID = RCO.DOC_RECORD_ID
         and RCO.ACR_MGM_RCO_FINANCING_HD_ID = aHeaderId
         and DRL.DOC_RECORD_SON_ID(+) = IMM.DOC_RECORD_ID
         --Prise en compte Dépenses ou Recettes au niveau du CPN
         and exists(select 1
                      from ACS_CPN_ACCOUNT CPN
                     where IMM.ACS_CPN_ACCOUNT_ID = CPN.ACS_CPN_ACCOUNT_ID
                       and CPN.C_EXPENSE_RECEIPT <> '0')
         --Compte financier non collectif
         and exists(
               select 1
                 from ACT_FINANCIAL_IMPUTATION IMF
                    , ACS_FINANCIAL_ACCOUNT FIN
                where IMM.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID
                  and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                  and FIN.FIN_COLLECTIVE <> 1)
         --Documents de type 1 et catalogue doit prendre en compte les "Dépenses/Recettes"
         and exists(
               select 1
                 from ACT_DOCUMENT DOC
                    , ACJ_CATALOGUE_DOCUMENT CAT
                where IMM.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                  and CAT.C_TYPE_CATALOGUE in('3', '4', '9')
                  and CAT.CAT_EXPENSE_RECEIPT = 1);

    --Document paeiement / lettrage (3,4,9) collectifs dont le document origine est de type (2,5,6)  Facture, Note de crédit
    open crCollDocuments(aHeaderId);

    fetch crCollDocuments
     into tplCollDocuments;

    while crCollDocuments%found loop
      --Recadrés proportionnellement dans les comptes des documents d'origines
      --Initialisation du montant total du document origine
      vOriginDocImputationSumLC  := Get_DocImputationSum(tplCollDocuments.ORIGIN_DOC_ID, 1);
      vOriginDocImputationSumFC  := Get_DocImputationSum(tplCollDocuments.ORIGIN_DOC_ID, 0);
      --Initialisation proportion de l'imputation traitée
      vOriginDocImputProport_LC  := 0;
      vOriginDocImputProport_FC  := 0;

      if vOriginDocImputationSumLC <> 0 then
        vOriginDocImputProport_LC  := tplCollDocuments.IMF_AMOUNT_LC_D / vOriginDocImputationSumLC;
      end if;

      if vOriginDocImputationSumFC <> 0 then
        vOriginDocImputProport_FC  := tplCollDocuments.IMF_AMOUNT_FC_D / vOriginDocImputationSumFC;
      end if;

      open crDocImputation(tplCollDocuments.ORIGIN_DOC_ID, aHeaderId);

      fetch crDocImputation
       into tplDocImputation;

      while crDocImputation%found loop
        if     (tplDocImputation.C_EXPENSE_RECEIPT <> '0')
           and (IsListedRecord(tplDocImputation.DOC_RECORD_ID, aHeaderId) ) then
          vOriginProportionalAmountLC_D  := 0;
          vOriginProportionalAmountLC_C  := 0;
          vOriginProportionalAmountFC_D  := 0;
          vOriginProportionalAmountFC_C  := 0;
          ACT_DOC_TRANSACTION.ProportionalAmounts(tplDocImputation.IMM_AMOUNT_LC_D
                                                , tplDocImputation.IMM_AMOUNT_LC_C
                                                , tplDocImputation.IMM_AMOUNT_FC_D
                                                , tplDocImputation.IMM_AMOUNT_FC_C
                                                , tplDocImputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                , tplDocImputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                , tplDocImputation.IMM_VALUE_DATE
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
          vOriginProportionalAmountLC_D  := AmountLC_D;
          vOriginProportionalAmountLC_C  := AmountLC_C;
          ACT_DOC_TRANSACTION.ProportionalAmounts(tplDocImputation.IMM_AMOUNT_LC_D
                                                , tplDocImputation.IMM_AMOUNT_LC_C
                                                , tplDocImputation.IMM_AMOUNT_FC_D
                                                , tplDocImputation.IMM_AMOUNT_FC_C
                                                , tplDocImputation.ACS_FINANCIAL_CURRENCY_ID
                                                , tplDocImputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                , tplDocImputation.IMM_VALUE_DATE
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
          vOriginProportionalAmountFC_D  := AmountFC_D;
          vOriginProportionalAmountFC_C  := AmountFC_C;
          vOriginProportionalQty_D       := nvl(tplDocImputation.IMM_QUANTITY_D, 0);
          vOriginProportionalQty_C       := nvl(tplDocImputation.IMM_QUANTITY_C, 0);

          if tplDocImputation.IMM_AMOUNT_LC_D <> 0 then
            vOriginProportionalQty_D  :=
                    tplDocImputation.IMM_QUANTITY_D
                    *(vOriginProportionalAmountLC_D / tplDocImputation.IMM_AMOUNT_LC_D);
          end if;

          if tplDocImputation.IMM_AMOUNT_LC_C <> 0 then
            vOriginProportionalQty_C  :=
                    tplDocImputation.IMM_QUANTITY_C
                    *(vOriginProportionalAmountLC_C / tplDocImputation.IMM_AMOUNT_LC_C);
          end if;

          insert into ACR_MGM_RCO_FINANCING_DET
                      (ACR_MGM_RCO_FINANCING_DET_ID
                     , ACR_MGM_RCO_FINANCING_HD_ID
                     , ACS_PERIOD_ID
                     , ACS_FINANCIAL_CURRENCY_ID
                     , ACS_QTY_UNIT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_ACS_FINANCIAL_CURRENCY_ID
                     , DOC_RECORD_ID
                     , DOC_RECORD_FATHER_ID
                     , ACT_MGM_IMPUTATION_ID
                     , IMM_TYPE
                     , IMM_GENRE
                     , IMM_PRIMARY
                     , IMM_DESCRIPTION
                     , IMM_AMOUNT_LC_D
                     , IMM_AMOUNT_LC_C
                     , IMM_EXCHANGE_RATE
                     , IMM_BASE_PRICE
                     , IMM_AMOUNT_FC_D
                     , IMM_AMOUNT_FC_C
                     , IMM_VALUE_DATE
                     , IMM_TRANSACTION_DATE
                     , IMM_QUANTITY_D
                     , IMM_QUANTITY_C
                     , IMM_NUMBER1
                     , IMM_NUMBER2
                     , IMM_NUMBER3
                     , IMM_NUMBER4
                     , IMM_NUMBER5
                     , IMM_TEXT1
                     , IMM_TEXT2
                     , IMM_TEXT3
                     , IMM_TEXT4
                     , IMM_TEXT5
                      )
               values (INIT_ID_SEQ.nextval
                     , tplDocImputation.ACR_MGM_RCO_FINANCING_HD_ID
                     , tplCollDocuments.ACS_PERIOD_ID
                     , tplDocImputation.ACS_FINANCIAL_CURRENCY_ID
                     , tplDocImputation.ACS_QTY_UNIT_ID
                     , tplDocImputation.ACS_PF_ACCOUNT_ID
                     , tplDocImputation.ACS_CDA_ACCOUNT_ID
                     , tplDocImputation.ACS_CPN_ACCOUNT_ID
                     , tplDocImputation.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , tplDocImputation.DOC_RECORD_ID
                     , tplDocImputation.DOC_RECORD_FATHER_ID
                     , tplDocImputation.ACT_MGM_IMPUTATION_ID
                     , tplDocImputation.IMM_TYPE
                     , tplDocImputation.IMM_GENRE
                     , tplDocImputation.IMM_PRIMARY
                     , tplDocImputation.IMM_DESCRIPTION
                     , vOriginProportionalAmountLC_D
                     , vOriginProportionalAmountLC_C
                     , tplCollDocuments.IMF_EXCHANGE_RATE
                     , tplCollDocuments.IMF_BASE_PRICE
                     , vOriginProportionalAmountFC_D
                     , vOriginProportionalAmountFC_C
                     , tplCollDocuments.IMF_VALUE_DATE
                     , tplCollDocuments.IMF_TRANSACTION_DATE
                     , vOriginProportionalQty_D
                     , vOriginProportionalQty_C
                     , tplDocImputation.IMM_NUMBER
                     , tplDocImputation.IMM_NUMBER2
                     , tplDocImputation.IMM_NUMBER3
                     , tplDocImputation.IMM_NUMBER4
                     , tplDocImputation.IMM_NUMBER5
                     , tplDocImputation.IMM_TEXT1
                     , tplDocImputation.IMM_TEXT2
                     , tplDocImputation.IMM_TEXT3
                     , tplDocImputation.IMM_TEXT4
                     , tplDocImputation.IMM_TEXT5
                      );
        end if;

        fetch crDocImputation
         into tplDocImputation;
      end loop;

      close crDocImputation;

      fetch crCollDocuments
       into tplCollDocuments;
    end loop;
  end GenerateExpenseReceiptDetails;

--------------------------------------------------------------------------------
  procedure GetAllTreatmentRecord(
    aRecordId DOC_RECORD.DOC_RECORD_ID%type
  , aHeaderId ACR_MGM_RCO_FINANCING_HD.ACR_MGM_RCO_FINANCING_HD_ID%type
  )
  is
  begin
    insert into ACR_MGM_RCO_FINANCING_RCO
                (ACR_MGM_RCO_FINANCING_RCO_ID
               , ACR_MGM_RCO_FINANCING_HD_ID
               , DOC_RECORD_ID
                )
      select INIT_ID_SEQ.nextval
           , aHeaderId
           , CHILDRENDOC.COLUMN_VALUE
        from table(ACR_FUNCTIONS.GetChildrenLinkedDocRecord(aRecordId, 20) ) ChildrenDoc;
  end GetAllTreatmentRecord;

--------------------------------------------------------------------------------
  function GenerateExpenseReceiptHeader(aRecordId DOC_RECORD.DOC_RECORD_ID%type)
    return ACR_MGM_RCO_FINANCING_HD.ACR_MGM_RCO_FINANCING_HD_ID%type
  is
    vHeaderId ACR_MGM_RCO_FINANCING_HD.ACR_MGM_RCO_FINANCING_HD_ID%type;
  begin
    --Génération nouvel id en tête
    select INIT_ID_SEQ.nextval
      into vHeaderId
      from dual;

    --Création de l'en-tête de calcul
    insert into ACR_MGM_RCO_FINANCING_HD
                (ACR_MGM_RCO_FINANCING_HD_ID
               , DOC_RECORD_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (vHeaderId
               , aRecordId
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    return vHeaderId;
  end GenerateExpenseReceiptHeader;

--------------------------------------------------------------------------------
  procedure ACR_MGM_RCO_FINANCING(aDocRecordId DOC_RECORD.DOC_RECORD_ID%type)
  is
    vFinancingHeaderId ACR_MGM_RCO_FINANCING_HD.ACR_MGM_RCO_FINANCING_HD_ID%type;
  begin
    --Suppression des calculs précédents
    delete from ACR_MGM_RCO_FINANCING_HD
          where DOC_RECORD_ID = aDocRecordId;

    --Génération en-tête de calcul
    vFinancingHeaderId  := GenerateExpenseReceiptHeader(aDocRecordId);
    --Récupération des dossiers pris en compte dans le calcul dans la table y dédiée
    GetAllTreatmentRecord(aDocRecordId, vFinancingHeaderId);
    --Génération détails de calcul
    GenerateExpenseReceiptDetails(aDocRecordId, vFinancingHeaderId);
    --Génération des positions de cumul des détails
    SumExpenseReceiptDetails(vFinancingHeaderId);
  end ACR_MGM_RCO_FINANCING;

  /**
  * Description
  *   Contrôle les mouvements en vue de leur rapprochement
  */
  procedure AutoCompare(
    pAcsAccountId       in ACS_ACCOUNT.ACS_ACCOUNT_ID%type   --Compte financier
  , pAcsFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type   --Exercice financier
  , pAcsCurrencyId      in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type   --Monnaie
  , pCSubSet            in ACS_SUB_SET.C_SUB_SET%type   --Sous-ensemble
  )
  is
    --curseur pour la structure d'un couple
    cursor crCoupleInfo
    is
      select 0 ACT_FINANCIAL_IMPUTATION_ID
           , 0 ACT_FIN_STAT_MOVEMENT_ID
           , sysdate IMF_VALUE_DATE
           , 0 IMF_AMOUNT_LC_D
           , 0 IMF_AMOUNT_LC_C
        from dual;

    --Table de réception des écritures
    type TCoupleInfo is table of crCoupleInfo%rowtype;

    --Réception de tous les mouvements
    vMovement     TCoupleInfo                   := TCoupleInfo();
    --Réception de tous les relevés de compte
    vAccStatement TCoupleInfo                   := TCoupleInfo();
    --Réception des couples
    vCouple       TCoupleInfo                   := TCoupleInfo();
    vAccNumber    ACS_ACCOUNT.ACC_NUMBER%type;
    vSql          varchar2(32000);
    vFound        boolean;

    /*fonction de suppression des macros dans une commande SQL
    */
    function FormatSql(pSql PCS.PC_SQLST.SQLSTMNT%type)
      return PCS.PC_SQLST.SQLSTMNT%type
    is
      vStart number;
      vEnd   number;
      vSql   clob;
    begin
      vSql    := replace(pSql, '[' || 'COMPANY_OWNER]', PCS.PC_I_LIB_SESSION.GetCompanyOwner);
      vSql    := replace(pSql, '[' || 'CO]', PCS.PC_I_LIB_SESSION.GetCompanyOwner);
      vSql    := replace(vSql, '[' || 'PCS_OWNER]', 'PCS');
      --Recherche d'un crochet '[' qui représente le début d'une macro et supprimer jusqu'à la fin de la commande
      vStart  := instr(pSql, '[');

      if vStart > 0 then
        return substr(vSql, 1, vStart - 1);
      else
        return vSql;
      end if;
    end;
  begin
    /*Créer des couples entre une écriture des mouvements et une écriture des relevés de compte
    La règle pour former un couple: même montant à la même date valeur.
    Chaque écriture appartenant à un couple est sortie des éléments à traiter (une écriture ne peut pas apparaître dans deux couples)
    Puis phase de contrôle: chaque écriture restante doit être contrôlée avec TOUS les couples.
    Si un ou plusieurs couple(s) correspond(ent) à l'écriture orpheline, il faut supprimer (tous) le(s) couple(s) correspondants à cette ligne orpheline.
    En fait le couple n'est pas important. La condition est que pour une écriture de mouvement corresponde un relevé de compte (même montant et même date valeur)
    et qu'il ne reste pas de ligne "orpheline" (ni mouvement, ni relevé) correspondant à un couple.
    Chaque couple trouvé sera inséré dans la table temporaire COM_LIST_ID_TEMP
    */
    -- Initialisation de la vue utilisée par la commande SQL du grid des mouvements
    select ACC_NUMBER
      into vAccNumber
      from ACS_ACCOUNT
     where ACS_ACCOUNT_ID = pAcsAccountId;

    SETV_ACT_IMPUTATION(vAccNumber, vAccNumber, pAcsFinancialYearId);
    --Table mémoire des mouvements selon commande sql du grid
    vSql  :=
      FormatSql(PCS.PC_LIB_SQL.GetSql('ACT_FINANCIAL_IMPUTATION'
                                    , 'QRY_NOTCOMPARED'
                                    , 'ASSIST0'
                                    , pcs.PC_I_LIB_SESSION.GetObjectId
                                    , 'ANSI SQL'
                                    , false
                                     )
               );
    vMovement.delete;

    execute immediate replace
                        (replace
                           ('select ACT_FINANCIAL_IMPUTATION_ID, 0 ACT_FIN_STAT_MOVEMENT_ID, trunc(IMF_VALUE_DATE) IMF_VALUE_DATE, IMF_AMOUNT_LC_D, IMF_AMOUNT_LC_C from (' ||
                            vSql ||
                            ')'
                          , ':C_SUB_SET'
                          , '''' || pCSubSet || ''''
                           )
                       , ':ACS_FINANCIAL_CURRENCY_ID'
                       , pAcsCurrencyId
                        )
    bulk collect into vMovement;

    --Table mémoire des relevés de compte selon commande sql du grid
    vSql  :=
      FormatSql(PCS.PC_LIB_SQL.GetSql('ACT_FIN_STAT_MOVEMENT'
                                    , 'QRY_COMPARED'
                                    , 'ASSIST01'
                                    , pcs.PC_I_LIB_SESSION.GetObjectId
                                    , 'ANSI SQL'
                                    , false
                                     )
               );
    vAccStatement.delete;

    execute immediate 'select 0 ACT_FINANCIAL_IMPUTATION_ID, ACT_FIN_STAT_MOVEMENT_ID, trunc(IMF_VALUE_DATE) IMF_VALUE_DATE, IMF_AMOUNT_LC_D, IMF_AMOUNT_LC_C from (' ||
                      vSql ||
                      ')'
    bulk collect into vAccStatement
                using in pAcsAccountId, pAcsCurrencyId, pAcsCurrencyId, pAcsCurrencyId;

    -- S'arrêter ici si pas de mouvement ou pas de relevé de compte
    if    (vMovement.count = 0)
       or (vAccStatement.count = 0) then
      raise_application_error(-20400, '');   --Pas de rapprochement possible
    end if;

    -- Pour chaque ligne des mouvements, rechercher une ligne de relevé de compte avec le même montant à la même date valeur
    <<Movements>>
    for vCptMov in vMovement.first .. vMovement.last loop

      <<AccountStatement>>
      for vCptStat in vAccStatement.first .. vAccStatement.last loop
        --Ligne strictement identique signifie :
        -- date valeur + (montant débit haut = montant crédit bas et
        --                montant crédit haut = montant débit bas)
        if     vAccStatement.exists(vCptStat)
           and vMovement(vCptMov).IMF_VALUE_DATE = vAccStatement(vCptStat).IMF_VALUE_DATE
           and vMovement(vCptMov).IMF_AMOUNT_LC_C = vAccStatement(vCptStat).IMF_AMOUNT_LC_D
           and vMovement(vCptMov).IMF_AMOUNT_LC_D = vAccStatement(vCptStat).IMF_AMOUNT_LC_C then
          vCouple.extend;
          vCouple(vCouple.last).ACT_FIN_STAT_MOVEMENT_ID     := vAccStatement(vCptStat).ACT_FIN_STAT_MOVEMENT_ID;
          vCouple(vCouple.last).ACT_FINANCIAL_IMPUTATION_ID  := vMovement(vCptMov).ACT_FINANCIAL_IMPUTATION_ID;
          vCouple(vCouple.last).IMF_VALUE_DATE               := vMovement(vCptMov).IMF_VALUE_DATE;
          vCouple(vCouple.last).IMF_AMOUNT_LC_D              := vMovement(vCptMov).IMF_AMOUNT_LC_D;
          vCouple(vCouple.last).IMF_AMOUNT_LC_C              := vMovement(vCptMov).IMF_AMOUNT_LC_C;
          vAccStatement.delete(vCptStat);
          vMovement.delete(vCptMov);
          exit AccountStatement;
        end if;
      end loop AccountStatement;
    end loop Movements;

    --Contrôler toute la table Couple
    if vMovement.count > 0 then

      --Contrôler que les lignes orphelines des mouvements ne correspondent pas à un couple
      <<Movements>>
      for vCptMov in vMovement.first .. vMovement.last loop
        vFound  := false;

        if     vMovement.exists(vCptMov)
           and vCouple.count > 0 then
          for vCptCouple in vCouple.first .. vCouple.last loop
            if     vCouple.exists(vCptCouple)
               and vMovement(vCptMov).IMF_VALUE_DATE = vCouple(vCptCouple).IMF_VALUE_DATE
               and vMovement(vCptMov).IMF_AMOUNT_LC_D = vCouple(vCptCouple).IMF_AMOUNT_LC_D
               and vMovement(vCptMov).IMF_AMOUNT_LC_C = vCouple(vCptCouple).IMF_AMOUNT_LC_C then
              vCouple.delete(vCptCouple);
              vFound  := true;
            end if;
          end loop;
        end if;

        if not vFound then
          vMovement.delete(vCptMov);   -- Supprimer la ligne si elle ne correspond pas à un couple existant
        end if;
      end loop Movements;
    end if;

    if vAccStatement.count > 0 then

      --Contrôler que les lignes orphelines des relevés de compte ne correspondent pas à un couple
      --Attention montant Débit du relevé de compte = montant crédit du couple
      <<AccountStatement>>
      for vCptStat in vAccStatement.first .. vAccStatement.last loop
        if     vAccStatement.exists(vCptStat)
           and vCouple.count > 0 then
          for vCptCouple in vCouple.first .. vCouple.last loop
            if     vCouple.exists(vCptCouple)
               and vAccStatement(vCptStat).IMF_VALUE_DATE = vCouple(vCptCouple).IMF_VALUE_DATE
               and vAccStatement(vCptStat).IMF_AMOUNT_LC_C = vCouple(vCptCouple).IMF_AMOUNT_LC_D
               and vAccStatement(vCptStat).IMF_AMOUNT_LC_D = vCouple(vCptCouple).IMF_AMOUNT_LC_C then
              vCouple.delete(vCptCouple);
              vFound  := true;
            end if;
          end loop;
        end if;

        if not vFound then
          vAccStatement.delete(vCptStat);   -- Supprimer la ligne si elle ne correspond pas à un couple existant
        end if;
      end loop Movements;
    end if;

    -- ajouter les couples trouvés dans COM_LIST_ID_TEMP
    if vCouple.count > 0 then
      delete from COM_LIST_ID_TEMP;

      for vCptCpl in vCouple.first .. vCouple.last loop
        if vCouple.exists(vCptCpl) then
          insert into COM_LIST_ID_TEMP
                      (COM_LIST_ID_TEMP_ID
                     , LID_FREE_NUMBER_1
                     , LID_FREE_NUMBER_2
                      )
               values (vCptCpl
                     , vCouple(vCptCpl).ACT_FINANCIAL_IMPUTATION_ID
                     , vCouple(vCptCpl).ACT_FIN_STAT_MOVEMENT_ID
                      );
        end if;
      end loop;
    end if;

    if vCouple.count = 0 then
      raise_application_error(-20400, '');   --Pas de rapprochement possible
    end if;
  end AutoCompare;
end ACR_FUNCTIONS;
