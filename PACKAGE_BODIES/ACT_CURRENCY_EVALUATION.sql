--------------------------------------------------------
--  DDL for Package Body ACT_CURRENCY_EVALUATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_CURRENCY_EVALUATION" 
is

  -------------------------------
  procedure SetAnalyse_Parameters(aDate            varchar2,
                                  aACC_NUMBER_From varchar2,
                                  aACC_NUMBER_To   varchar2,
                                  aBRO             varchar2,
                                  aRateType        varchar2)
  is
  begin
    ACT_FUNCTIONS.ANALYSE_DATE       := to_date(aDate, 'yyyymmdd');
    ACT_FUNCTIONS.ANALYSE_AUXILIARY1 := aACC_NUMBER_From;
    ACT_FUNCTIONS.ANALYSE_AUXILIARY2 := aACC_NUMBER_To;
    if aBRO = '1' then
      ACT_FUNCTIONS.BRO := 1;
    else
      ACT_FUNCTIONS.BRO := 0;
    end if;
    begin
      RATE_TYPE := to_number(aRateType);
    exception
      when INVALID_NUMBER then
        RATE_TYPE := 1;  -- Cours du jour
    end;
  end SetAnalyse_Parameters;

  --------------------
  function GetRateType return number
  is
  begin
    return RATE_TYPE;
  end GetRateType;

  ----------------------
  function ExistDivision return number
  is
    SubSetId ACS_SUB_SET.ACS_SUB_SET_ID%type;
    Result   number default 0;
  begin
    begin
      select min(ACS_SUB_SET_ID) into SubSetId
        from ACS_SUB_SET
        where C_TYPE_SUB_SET = 'DIVI';
      if SubSetId is not null then
        Result := 1;
      end if;
    exception
      when OTHERS then
        Result := 0;
    end;
    return Result;
  end ExistDivision;

  ------------------------
  function GetDateOfPeriod(aACS_PERIOD_ID ACS_PERIOD.ACS_PERIOD_ID%type,
                           aBegin         boolean) return date
  is
    BeginDate date;
    EndDate   date;
  begin
    begin
      select trunc(PER_START_DATE),
             trunc(PER_END_DATE) into BeginDate, EndDate
        from ACS_PERIOD
        where ACS_PERIOD_ID = aACS_PERIOD_ID;
    exception
      when OTHERS then
        BeginDate := null;
        EndDate   := null;
    end;
    if aBegin then
      return BeginDate;
    else
      return EndDate;
    end if;
  end GetDateOfPeriod;

  ---------------------------------
  function UpdateACT_EVAL_SELECTION(aACT_JOB_ID               ACT_JOB.ACT_JOB_ID%type,
                                    aACS_EVALUATION_METHOD_ID ACS_EVALUATION_METHOD.ACS_EVALUATION_METHOD_ID%type) return boolean
  is

    cursor EvalSelectionModelCursor is
      select
             MAC.ACS_FINANCIAL_ACCOUNT_ID,
             MAC.ACS_FINANCIAL_CURRENCY_ID,
             MAC.ACS_FIN_ACC_ID,
             MAC.ACS_FIN_GAIN_ID,
             MAC.ACS_FIN_LOSS_ID,
             MAC.ACS_DIVISION_ACCOUNT_ID,
             MAC.ACS_DIV_ACC_ID,
             MAC.ACS_DIV_GAIN_ID,
             MAC.ACS_CPN_GAIN_ID,
             MAC.ACS_DIV_LOSS_ID,
             MAC.ACS_CPN_LOSS_ID,
             MAC.ACS_CDA_GAIN_ID,
             MAC.ACS_CDA_LOSS_ID,
             MAC.ACS_PF_GAIN_ID,
             MAC.ACS_PF_LOSS_ID,
             MAC.ACS_PJ_GAIN_ID,
             MAC.ACS_PJ_LOSS_ID,
             MAC.ACS_PF_LOSS_DEBT_ID,
             MAC.ACS_PF_GAIN_DEBT_ID,
             MAC.ACS_PJ_LOSS_DEBT_ID,
             MAC.ACS_PJ_GAIN_DEBT_ID,
             MAC.ACS_CDA_LOSS_DEBT_ID,
             MAC.ACS_CDA_GAIN_DEBT_ID,
             MAC.ACS_CPN_LOSS_DEBT_ID,
             MAC.ACS_CPN_GAIN_DEBT_ID,
             MAC.ACS_DIV_LOSS_DEBT_ID,
             MAC.ACS_DIV_GAIN_DEBT_ID,
             MAC.ACS_ACC_LOSS_DEBT_ID,
             MAC.ACS_ACC_GAIN_DEBT_ID
        from
             ACS_EVALUATION_ACCOUNT MAC;

    type EvalSelectionCursorTyp is ref cursor;

    EvalSelectionCursor EvalSelectionCursorTyp;
    EvalSelection       EvalSelectionModelCursor%rowtype;

    Id            ACT_EVAL_SELECTION.ACT_EVAL_SELECTION_ID%type;
    Result        boolean default true;
  -----
  begin

    delete from ACT_EVAL_SELECTION
      where ACT_JOB_ID = aACT_JOB_ID;

    begin

      if ACT_CURRENCY_EVALUATION.ExistDivision = 1 then

        -- Gestion des divisions
        open EvalSelectionCursor for
          select
                 MAC.ACS_FINANCIAL_ACCOUNT_ID,
                 MAC.ACS_FINANCIAL_CURRENCY_ID,
                 MAC.ACS_FIN_ACC_ID,
                 MAC.ACS_FIN_GAIN_ID,
                 MAC.ACS_FIN_LOSS_ID,
                 MAC.ACS_DIVISION_ACCOUNT_ID,
                 MAC.ACS_DIV_ACC_ID,
                 NVL(MAC.ACS_DIV_GAIN_ID, ACS_FUNCTION.GETDIVISIONOFACCOUNT(MAC.ACS_FIN_GAIN_ID, NULL, SYSDATE)),
                 NVL(MAC.ACS_CPN_GAIN_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_FIN_GAIN_ID)),
                 NVL(MAC.ACS_DIV_LOSS_ID, ACS_FUNCTION.GETDIVISIONOFACCOUNT(MAC.ACS_FIN_LOSS_ID, NULL, SYSDATE)),
                 NVL(MAC.ACS_CPN_LOSS_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_FIN_LOSS_ID)),
                 MAC.ACS_CDA_GAIN_ID,
                 MAC.ACS_CDA_LOSS_ID,
                 MAC.ACS_PF_GAIN_ID,
                 MAC.ACS_PF_LOSS_ID,
                 MAC.ACS_PJ_GAIN_ID,
                 MAC.ACS_PJ_LOSS_ID,
                 MAC.ACS_PF_LOSS_DEBT_ID,
                 MAC.ACS_PF_GAIN_DEBT_ID,
                 MAC.ACS_PJ_LOSS_DEBT_ID,
                 MAC.ACS_PJ_GAIN_DEBT_ID,
                 MAC.ACS_CDA_LOSS_DEBT_ID,
                 MAC.ACS_CDA_GAIN_DEBT_ID,
                 NVL(MAC.ACS_CPN_LOSS_DEBT_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_ACC_LOSS_DEBT_ID)),
                 NVL(MAC.ACS_CPN_GAIN_DEBT_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_ACC_GAIN_DEBT_ID)),
                 NVL(MAC.ACS_DIV_LOSS_DEBT_ID, ACS_FUNCTION.GETDIVISIONOFACCOUNT(MAC.ACS_ACC_LOSS_DEBT_ID, NULL, SYSDATE)),
                 NVL(MAC.ACS_DIV_GAIN_DEBT_ID, ACS_FUNCTION.GETDIVISIONOFACCOUNT(MAC.ACS_ACC_GAIN_DEBT_ID, NULL, SYSDATE)),
                 MAC.ACS_ACC_LOSS_DEBT_ID,
                 MAC.ACS_ACC_GAIN_DEBT_ID
            from
                 ACS_EVALUATION_ACCOUNT MAC
            where
                  MAC.ACS_EVALUATION_METHOD_ID = aACS_EVALUATION_METHOD_ID
              and MAC.ACS_DIVISION_ACCOUNT_ID is not null
          union
          select
                 MAC.ACS_FINANCIAL_ACCOUNT_ID,
                 MAC.ACS_FINANCIAL_CURRENCY_ID,
                 MAC.ACS_FIN_ACC_ID,
                 MAC.ACS_FIN_GAIN_ID,
                 MAC.ACS_FIN_LOSS_ID,
                 DIV.ACS_DIVISION_ACCOUNT_ID,
                 MAC.ACS_DIV_ACC_ID,
                 NVL(MAC.ACS_DIV_GAIN_ID, ACS_FUNCTION.GETDIVISIONOFACCOUNT(MAC.ACS_FIN_GAIN_ID, NULL, SYSDATE)),
                 NVL(MAC.ACS_CPN_GAIN_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_FIN_GAIN_ID)),
                 NVL(MAC.ACS_DIV_LOSS_ID, ACS_FUNCTION.GETDIVISIONOFACCOUNT(MAC.ACS_FIN_LOSS_ID, NULL, SYSDATE)),
                 NVL(MAC.ACS_CPN_LOSS_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_FIN_LOSS_ID)),
                 MAC.ACS_CDA_GAIN_ID,
                 MAC.ACS_CDA_LOSS_ID,
                 MAC.ACS_PF_GAIN_ID,
                 MAC.ACS_PF_LOSS_ID,
                 MAC.ACS_PJ_GAIN_ID,
                 MAC.ACS_PJ_LOSS_ID,
                 MAC.ACS_PF_LOSS_DEBT_ID,
                 MAC.ACS_PF_GAIN_DEBT_ID,
                 MAC.ACS_PJ_LOSS_DEBT_ID,
                 MAC.ACS_PJ_GAIN_DEBT_ID,
                 MAC.ACS_CDA_LOSS_DEBT_ID,
                 MAC.ACS_CDA_GAIN_DEBT_ID,
                 NVL(MAC.ACS_CPN_LOSS_DEBT_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_ACC_LOSS_DEBT_ID)),
                 NVL(MAC.ACS_CPN_GAIN_DEBT_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_ACC_GAIN_DEBT_ID)),
                 NVL(MAC.ACS_DIV_LOSS_DEBT_ID, ACS_FUNCTION.GETDIVISIONOFACCOUNT(MAC.ACS_ACC_LOSS_DEBT_ID, NULL, SYSDATE)),
                 NVL(MAC.ACS_DIV_GAIN_DEBT_ID, ACS_FUNCTION.GETDIVISIONOFACCOUNT(MAC.ACS_ACC_GAIN_DEBT_ID, NULL, SYSDATE)),
                 MAC.ACS_ACC_LOSS_DEBT_ID,
                 MAC.ACS_ACC_GAIN_DEBT_ID
            from
                 ACS_DIVISION_ACCOUNT   DIV,
                 ACS_EVALUATION_ACCOUNT MAC
            where
                  MAC.ACS_EVALUATION_METHOD_ID = aACS_EVALUATION_METHOD_ID
              and MAC.ACS_DIVISION_ACCOUNT_ID is null;

      else

        -- Sans Gestion des divisions
        open EvalSelectionCursor for
          select
                 MAC.ACS_FINANCIAL_ACCOUNT_ID,
                 MAC.ACS_FINANCIAL_CURRENCY_ID,
                 MAC.ACS_FIN_ACC_ID,
                 MAC.ACS_FIN_GAIN_ID,
                 MAC.ACS_FIN_LOSS_ID,
                 MAC.ACS_DIVISION_ACCOUNT_ID,
                 MAC.ACS_DIV_ACC_ID,
                 MAC.ACS_DIV_GAIN_ID,
                 NVL(MAC.ACS_CPN_GAIN_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_FIN_GAIN_ID)),
                 MAC.ACS_DIV_LOSS_ID,
                 NVL(MAC.ACS_CPN_LOSS_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_FIN_LOSS_ID)),
                 MAC.ACS_CDA_GAIN_ID,
                 MAC.ACS_CDA_LOSS_ID,
                 MAC.ACS_PF_GAIN_ID,
                 MAC.ACS_PF_LOSS_ID,
                 MAC.ACS_PJ_GAIN_ID,
                 MAC.ACS_PJ_LOSS_ID,
                 MAC.ACS_PF_LOSS_DEBT_ID,
                 MAC.ACS_PF_GAIN_DEBT_ID,
                 MAC.ACS_PJ_LOSS_DEBT_ID,
                 MAC.ACS_PJ_GAIN_DEBT_ID,
                 MAC.ACS_CDA_LOSS_DEBT_ID,
                 MAC.ACS_CDA_GAIN_DEBT_ID,
                 NVL(MAC.ACS_CPN_LOSS_DEBT_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_ACC_LOSS_DEBT_ID)),
                 NVL(MAC.ACS_CPN_GAIN_DEBT_ID, ACS_FUNCTION.GETCPNOFFINACC(MAC.ACS_ACC_GAIN_DEBT_ID)),
                 MAC.ACS_DIV_LOSS_DEBT_ID,
                 MAC.ACS_DIV_GAIN_DEBT_ID,
                 MAC.ACS_ACC_LOSS_DEBT_ID,
                 MAC.ACS_ACC_GAIN_DEBT_ID
            from
                 ACS_EVALUATION_ACCOUNT MAC
            where
                  MAC.ACS_EVALUATION_METHOD_ID = aACS_EVALUATION_METHOD_ID;
      end if;

      fetch EvalSelectionCursor into EvalSelection;

      while EvalSelectionCursor%found loop

        select init_id_seq.nextval into Id from dual;

        insert into ACT_EVAL_SELECTION
         (ACT_EVAL_SELECTION_ID,
          ACT_JOB_ID,
          ACS_FINANCIAL_ACCOUNT_ID,
          ACS_FINANCIAL_CURRENCY_ID,
          ACS_FIN_ACC_ID,
          ACS_FIN_GAIN_ID,
          ACS_FIN_LOSS_ID,
          ACS_DIVISION_ACCOUNT_ID,
          ACS_DIV_ACC_ID,
          ACS_DIV_GAIN_ID,
          ACS_CPN_GAIN_ID,
          ACS_DIV_LOSS_ID,
          ACS_CPN_LOSS_ID,
          ACS_CDA_GAIN_ID,
          ACS_CDA_LOSS_ID,
          ACS_PF_GAIN_ID,
          ACS_PF_LOSS_ID,
          ACS_PJ_GAIN_ID,
          ACS_PJ_LOSS_ID,
          ACS_PF_LOSS_DEBT_ID,
          ACS_PF_GAIN_DEBT_ID,
          ACS_PJ_LOSS_DEBT_ID,
          ACS_PJ_GAIN_DEBT_ID,
          ACS_CDA_LOSS_DEBT_ID,
          ACS_CDA_GAIN_DEBT_ID,
          ACS_CPN_LOSS_DEBT_ID,
          ACS_CPN_GAIN_DEBT_ID,
          ACS_DIV_LOSS_DEBT_ID,
          ACS_DIV_GAIN_DEBT_ID,
          ACS_ACC_LOSS_DEBT_ID,
          ACS_ACC_GAIN_DEBT_ID)
        values
         (Id,
          aACT_JOB_ID,
          EvalSelection.ACS_FINANCIAL_ACCOUNT_ID,
          EvalSelection.ACS_FINANCIAL_CURRENCY_ID,
          EvalSelection.ACS_FIN_ACC_ID,
          EvalSelection.ACS_FIN_GAIN_ID,
          EvalSelection.ACS_FIN_LOSS_ID,
          EvalSelection.ACS_DIVISION_ACCOUNT_ID,
          EvalSelection.ACS_DIV_ACC_ID,
          EvalSelection.ACS_DIV_GAIN_ID,
          EvalSelection.ACS_CPN_GAIN_ID,
          EvalSelection.ACS_DIV_LOSS_ID,
          EvalSelection.ACS_CPN_LOSS_ID,
          EvalSelection.ACS_CDA_GAIN_ID,
          EvalSelection.ACS_CDA_LOSS_ID,
          EvalSelection.ACS_PF_GAIN_ID,
          EvalSelection.ACS_PF_LOSS_ID,
          EvalSelection.ACS_PJ_GAIN_ID,
          EvalSelection.ACS_PJ_LOSS_ID,
          EvalSelection.ACS_PF_LOSS_DEBT_ID,
          EvalSelection.ACS_PF_GAIN_DEBT_ID,
          EvalSelection.ACS_PJ_LOSS_DEBT_ID,
          EvalSelection.ACS_PJ_GAIN_DEBT_ID,
          EvalSelection.ACS_CDA_LOSS_DEBT_ID,
          EvalSelection.ACS_CDA_GAIN_DEBT_ID,
          EvalSelection.ACS_CPN_LOSS_DEBT_ID,
          EvalSelection.ACS_CPN_GAIN_DEBT_ID,
          EvalSelection.ACS_DIV_LOSS_DEBT_ID,
          EvalSelection.ACS_DIV_GAIN_DEBT_ID,
          EvalSelection.ACS_ACC_LOSS_DEBT_ID,
          EvalSelection.ACS_ACC_GAIN_DEBT_ID);

        fetch EvalSelectionCursor into EvalSelection;

      end loop;

      close EvalSelectionCursor;

    exception
      when OTHERS then
        Result := false;
    end;

    return Result;

  end UpdateACT_EVAL_SELECTION;

  --------------------------------
  function UpdateACT_EVAL_CURRENCY(aACT_JOB_ID               ACT_JOB.ACT_JOB_ID%type,
                                   aACS_EVALUATION_METHOD_ID ACS_EVALUATION_METHOD.ACS_EVALUATION_METHOD_ID%type,
                                   aACS_PERIOD_ID            ACS_PERIOD.ACS_PERIOD_ID%type) return boolean
  is
    ------
    cursor FinancialCurrencyCursor(aACS_EVALUATION_METHOD_ID ACS_EVALUATION_METHOD.ACS_EVALUATION_METHOD_ID%type,
                                   aEndPeriodDate            date)
    is
      select distinct EAC.ACS_FINANCIAL_CURRENCY_ID,
                      CUR.C_PRICE_METHOD
        from
             ACS_FINANCIAL_CURRENCY CUR,
             ACS_EVALUATION_ACCOUNT EAC
        where ACS_EVALUATION_METHOD_ID      = aACS_EVALUATION_METHOD_ID
          and EAC.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
          and not exists (select ACS_FINANCIAL_CURRENCY_ID
                            from ACS_FINANCIAL_CURRENCY
                            where ACS_FINANCIAL_CURRENCY_ID = EAC.ACS_FINANCIAL_CURRENCY_ID
                              and FIN_EURO_FROM            <= aEndPeriodDate)
      union
      select ACS_FINANCIAL_CURRENCY_ID,
             FCUR.C_PRICE_METHOD
        from
             ACS_FINANCIAL_CURRENCY FCUR,
             PCS.PC_CURR            CUR
        where
              CUR.CURRENCY   = 'EUR'
          and CUR.PC_CURR_ID = FCUR.PC_CURR_ID
          and exists (select EAC.ACS_FINANCIAL_CURRENCY_ID
                        from ACS_FINANCIAL_CURRENCY FCUR2,
                             ACS_EVALUATION_ACCOUNT EAC
                        where ACS_EVALUATION_METHOD_ID      = aACS_EVALUATION_METHOD_ID
                          and EAC.ACS_FINANCIAL_CURRENCY_ID = FCUR2.ACS_FINANCIAL_CURRENCY_ID
                          and FIN_EURO_FROM                <= aEndPeriodDate);

    FinancialCurrency       FinancialCurrencyCursor%rowtype;

    DaylyPrice              ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type;
    InvoicePrice            ACS_PRICE_CURRENCY.PCU_INVOICE_PRICE%type;
    ValuationPrice          ACS_PRICE_CURRENCY.PCU_VALUATION_PRICE%type;
    InventoryPrice          ACS_PRICE_CURRENCY.PCU_INVENTORY_PRICE%type;
    ClosingPrice            ACS_PRICE_CURRENCY.PCU_CLOSING_PRICE%type;
    BasePrice               ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type;
    PriceMethod             ACS_FINANCIAL_CURRENCY.C_PRICE_METHOD%type;

    Ok                      boolean default true;
    Result                  boolean default true;
    EndPeriodDate           date;

    --------
    function GetCurrencyPrices(aACS_FINANCIAL_CURRENCY_ID in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
                               aC_PRICE_METHOD            in     ACS_FINANCIAL_CURRENCY.C_PRICE_METHOD%type,
                               aEndPeriodDate             in     date,
                               aPCU_DAYLY_PRICE           in out ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type,
                               aPCU_INVOICE_PRICE         in out ACS_PRICE_CURRENCY.PCU_INVOICE_PRICE%type,
                               aPCU_VALUATION_PRICE       in out ACS_PRICE_CURRENCY.PCU_VALUATION_PRICE%type,
                               aPCU_INVENTORY_PRICE       in out ACS_PRICE_CURRENCY.PCU_INVENTORY_PRICE%type,
                               aPCU_CLOSING_PRICE         in out ACS_PRICE_CURRENCY.PCU_CLOSING_PRICE%type,
                               aPCU_BASE_PRICE            in out ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type) return boolean
    is
      Result boolean default true;
    begin

      aPCU_DAYLY_PRICE     := null;
      aPCU_INVOICE_PRICE   := null;
      aPCU_VALUATION_PRICE := null;
      aPCU_INVENTORY_PRICE := null;
      aPCU_CLOSING_PRICE   := null;
      aPCU_BASE_PRICE      := null;

      begin

        if aC_PRICE_METHOD = '1' then

          select
                 PCU_DAYLY_PRICE,
                 PCU_INVOICE_PRICE,
                 PCU_VALUATION_PRICE,
                 PCU_INVENTORY_PRICE,
                 PCU_CLOSING_PRICE,
                 PCU_BASE_PRICE into aPCU_DAYLY_PRICE,     aPCU_INVOICE_PRICE, aPCU_VALUATION_PRICE,
                                     aPCU_INVENTORY_PRICE, aPCU_CLOSING_PRICE, aPCU_BASE_PRICE
            from
                 ACS_PRICE_CURRENCY PRI,
                (select ACS_BETWEEN_CURR_ID,
                        max(PCU_START_VALIDITY) PCU_START_VALIDITY
                   from ACS_PRICE_CURRENCY
                   where ACS_BETWEEN_CURR_ID = aACS_FINANCIAL_CURRENCY_ID
                     and PCU_START_VALIDITY <= aEndPeriodDate
                 group by ACS_BETWEEN_CURR_ID) PRI2
            where
                  PRI.ACS_BETWEEN_CURR_ID = PRI2.ACS_BETWEEN_CURR_ID
              and PRI.PCU_START_VALIDITY  = PRI2.PCU_START_VALIDITY;

        else

          select
                 PCU_BASE_PRICE / decode(PCU_DAYLY_PRICE,     0, 1, PCU_DAYLY_PRICE)     PCU_DAYLY_PRICE,
                 PCU_BASE_PRICE / decode(PCU_INVOICE_PRICE,   0, 1, PCU_INVOICE_PRICE)   PCU_INVOICE_PRICE,
                 PCU_BASE_PRICE / decode(PCU_VALUATION_PRICE, 0, 1, PCU_VALUATION_PRICE) PCU_VALUATION_PRICE,
                 PCU_BASE_PRICE / decode(PCU_INVENTORY_PRICE, 0, 1, PCU_INVENTORY_PRICE) PCU_INVENTORY_PRICE,
                 PCU_BASE_PRICE / decode(PCU_CLOSING_PRICE,   0, 1, PCU_CLOSING_PRICE)   PCU_CLOSING_PRICE,
                 PCU_BASE_PRICE into aPCU_DAYLY_PRICE,     aPCU_INVOICE_PRICE, aPCU_VALUATION_PRICE,
                                     aPCU_INVENTORY_PRICE, aPCU_CLOSING_PRICE, aPCU_BASE_PRICE
            from
                 ACS_PRICE_CURRENCY PRI,
                (select ACS_AND_CURR_ID,
                        max(PCU_START_VALIDITY) PCU_START_VALIDITY
                   from ACS_PRICE_CURRENCY
                   where ACS_AND_CURR_ID = aACS_FINANCIAL_CURRENCY_ID
                     and PCU_START_VALIDITY <= aEndPeriodDate
                 group by ACS_AND_CURR_ID) PRI2
            where
                  PRI.ACS_AND_CURR_ID     = PRI2.ACS_AND_CURR_ID
              and PRI.PCU_START_VALIDITY  = PRI2.PCU_START_VALIDITY;

        end if;

      exception

        when NO_DATA_FOUND then
        begin

          if aC_PRICE_METHOD = '1' then

            select
                   PCU_BASE_PRICE / decode(PCU_DAYLY_PRICE,     0, 1, PCU_DAYLY_PRICE)     PCU_DAYLY_PRICE,
                   PCU_BASE_PRICE / decode(PCU_INVOICE_PRICE,   0, 1, PCU_INVOICE_PRICE)   PCU_INVOICE_PRICE,
                   PCU_BASE_PRICE / decode(PCU_VALUATION_PRICE, 0, 1, PCU_VALUATION_PRICE) PCU_VALUATION_PRICE,
                   PCU_BASE_PRICE / decode(PCU_INVENTORY_PRICE, 0, 1, PCU_INVENTORY_PRICE) PCU_INVENTORY_PRICE,
                   PCU_BASE_PRICE / decode(PCU_CLOSING_PRICE,   0, 1, PCU_CLOSING_PRICE)   PCU_CLOSING_PRICE,
                   PCU_BASE_PRICE into aPCU_DAYLY_PRICE,     aPCU_INVOICE_PRICE, aPCU_VALUATION_PRICE,
                                       aPCU_INVENTORY_PRICE, aPCU_CLOSING_PRICE, aPCU_BASE_PRICE
              from
                   ACS_PRICE_CURRENCY PRI,
                  (select ACS_AND_CURR_ID,
                          max(PCU_START_VALIDITY) PCU_START_VALIDITY
                     from ACS_PRICE_CURRENCY
                     where ACS_AND_CURR_ID = aACS_FINANCIAL_CURRENCY_ID
                       and PCU_START_VALIDITY <= aEndPeriodDate
                   group by ACS_AND_CURR_ID) PRI2
              where
                    PRI.ACS_AND_CURR_ID     = PRI2.ACS_AND_CURR_ID
                and PRI.PCU_START_VALIDITY  = PRI2.PCU_START_VALIDITY;

          else

            select
                   PCU_DAYLY_PRICE,
                   PCU_INVOICE_PRICE,
                   PCU_VALUATION_PRICE,
                   PCU_INVENTORY_PRICE,
                   PCU_CLOSING_PRICE,
                   PCU_BASE_PRICE into aPCU_DAYLY_PRICE,     aPCU_INVOICE_PRICE, aPCU_VALUATION_PRICE,
                                       aPCU_INVENTORY_PRICE, aPCU_CLOSING_PRICE, aPCU_BASE_PRICE
              from
                   ACS_PRICE_CURRENCY PRI,
                  (select ACS_BETWEEN_CURR_ID,
                          max(PCU_START_VALIDITY) PCU_START_VALIDITY
                     from ACS_PRICE_CURRENCY
                     where ACS_BETWEEN_CURR_ID = aACS_FINANCIAL_CURRENCY_ID
                       and PCU_START_VALIDITY <= aEndPeriodDate
                   group by ACS_BETWEEN_CURR_ID) PRI2
              where
                    PRI.ACS_BETWEEN_CURR_ID = PRI2.ACS_BETWEEN_CURR_ID
                and PRI.PCU_START_VALIDITY  = PRI2.PCU_START_VALIDITY;

          end if;

        exception
          when OTHERS then
            Result := False;

        end;

      end;

      return Result;

    end;

  -----
  begin

    EndPeriodDate := ACT_CURRENCY_EVALUATION.GetDateOfPeriod(aACS_PERIOD_ID, false);

    delete from ACT_EVAL_CURRENCY
      where ACT_JOB_ID = aACT_JOB_ID;

    begin

      open FinancialCurrencyCursor(aACS_EVALUATION_METHOD_ID, EndPeriodDate);
      fetch FinancialCurrencyCursor into FinancialCurrency;

      while FinancialCurrencyCursor%found loop

        Ok := GetCurrencyPrices(FinancialCurrency.ACS_FINANCIAL_CURRENCY_ID, FinancialCurrency.C_PRICE_METHOD, EndPeriodDate,
                                DaylyPrice, InvoicePrice, ValuationPrice, InventoryPrice, ClosingPrice, BasePrice);

        if Ok then

          insert into ACT_EVAL_CURRENCY
           (ACT_JOB_ID,
            ACS_FINANCIAL_CURRENCY_ID,
            PCU_DAYLY_PRICE,
            PCU_INVOICE_PRICE,
            PCU_VALUATION_PRICE,
            PCU_INVENTORY_PRICE,
            PCU_CLOSING_PRICE,
            PCU_BASE_PRICE)
          values
           (aACT_JOB_ID,
            FinancialCurrency.ACS_FINANCIAL_CURRENCY_ID,
            DaylyPrice,
            InvoicePrice,
            ValuationPrice,
            InventoryPrice,
            ClosingPrice,
            BasePrice);

        end if;

        fetch FinancialCurrencyCursor into FinancialCurrency;

      end loop;

      close FinancialCurrencyCursor;

    exception
      when OTHERS then
        Result := false;
    end;

    return Result;
  end UpdateACT_EVAL_CURRENCY;

  ----------------------------
  procedure CurrencyEvaluation(aACT_JOB_ID      ACT_JOB.ACT_JOB_ID%type)
/*                             atblCurrency     tblCurrencyTyp,
                               atblExchangeRate tblExchangeRateTyp,
                               atblBasePrice    tblBasePriceTyp) */
  is
    ------
    cursor EvalParamCursor(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) is
      select PAR.ACS_EVALUATION_METHOD_ID,
             ACS_PERIOD_ID,
             DOC_DOCUMENT_DATE,
             IMF_TRANSACTION_DATE,
             IMF_VALUE_DATE,
             IMF_DESCRIPTION,
             C_ROUND_TYPE,
             FIN_ROUNDED_AMOUNT,
             C_EVALUATION_METHOD,
			 MET.C_RATE_TYP
        from
		     ACS_EVALUATION_METHOD MET,
			 ACT_EVAL_PARAM        PAR
        where PAR.ACT_JOB_ID               = aACT_JOB_ID
          and PAR.ACS_EVALUATION_METHOD_ID = MET.ACS_EVALUATION_METHOD_ID;

    ------
    cursor EvalSelectionCursor(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) is
      select
             ACT_EVAL_SELECTION_ID,
             ACS_FINANCIAL_ACCOUNT_ID,
             ACS_FINANCIAL_CURRENCY_ID,
             ACS_DIVISION_ACCOUNT_ID
        from
             ACT_EVAL_SELECTION
        where
              ACT_JOB_ID = aACT_JOB_ID;

    ------
    cursor EvaluationMethodCursor(aACS_EVALUATION_METHOD_ID ACS_EVALUATION_METHOD.ACS_EVALUATION_METHOD_ID%type) is
      select
             C_EVALUATION_METHOD,
             C_TYPE_CUMUL
        from
             ACS_EVALUATION_CUMUL  CUM,
             ACS_EVALUATION_METHOD MET
        where
              MET.ACS_EVALUATION_METHOD_ID = aACS_EVALUATION_METHOD_ID
          and MET.ACS_EVALUATION_METHOD_ID = CUM.ACS_EVALUATION_METHOD_ID;

    EvalSelection    EvalSelectionCursor%rowtype;
    EvaluationMethod EvaluationMethodCursor%rowtype;
    EvalParam        EvalParamCursor%rowtype;

    OldAmountLC      ACT_EVALUATION.EVA_BEF_AMOUNT_LC%type;
    OldAmountFC      ACT_EVALUATION.EVA_BEF_AMOUNT_FC%type;
    AmountLC         ACT_EVALUATION.EVA_AMOUNT_LC%type;
    GainAmount       ACT_EVALUATION.EVA_AMOUNT_LC%type;
    LossAmount       ACT_EVALUATION.EVA_AMOUNT_LC%type;
    AmountEUR        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    CtrlDate         ACT_EVALUATION.EVA_CTRL_DATE%type;
    NewRate          ACT_EVALUATION.EVA_EXCHANGE_RATE%type;
    BasePrice        ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type;
    EuroRate         ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;

    ---------
    procedure GetNewRate(aACT_JOB_ID                in ACT_JOB.ACT_JOB_ID%type,
                         aACS_FINANCIAL_CURRENCY_ID in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
                         aDate                      in date,
                         aC_RATE_TYP                in ACS_EVALUATION_METHOD.C_RATE_TYP%type,
/*                       atblCurrency               in tblCurrencyTyp,
                         atblExchangeRate           in tblExchangeRateTyp,
                         atblBasePrice              in tblBasePriceTyp,  */
                         aNewRate                   in out ACT_EVALUATION.EVA_EXCHANGE_RATE%type,
                         aBasePrice                 in out ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type,
                         aEuroRate                  in out ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type)
    is
    begin
      aNewRate   := 0;
      aBasePrice := 0;
      aEuroRate  := 0;

      begin

        -- Monnaie EURO IN
        if ACS_FUNCTION.IsFinCurrInEuro(aACS_FINANCIAL_CURRENCY_ID, aDate) = 1 then

          select decode(aC_RATE_TYP, '1', PCU_DAYLY_PRICE,
                                     '2', PCU_INVOICE_PRICE,
                                     '3', PCU_VALUATION_PRICE,
                                     '4', PCU_INVENTORY_PRICE,
                                     '5', PCU_CLOSING_PRICE,
                                          0),
                 PCU_BASE_PRICE into aNewRate, aBasePrice
            from
                 PCS.PC_CURR            CUR,
                 ACS_FINANCIAL_CURRENCY FCUR,
                 ACT_EVAL_CURRENCY      ECU
            where ACT_JOB_ID                    = aACT_JOB_ID
              and ECU.ACS_FINANCIAL_CURRENCY_ID = FCUR.ACS_FINANCIAL_CURRENCY_ID
              and FCUR.PC_CURR_ID               = CUR.PC_CURR_ID
              and CUR.CURRENCY                  = 'EUR';

          select FIN_EURO_RATE into aEuroRate
            from ACS_FINANCIAL_CURRENCY
            where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;

        else

          select decode(aC_RATE_TYP, '1', PCU_DAYLY_PRICE,
                                     '2', PCU_INVOICE_PRICE,
                                     '3', PCU_VALUATION_PRICE,
                                     '4', PCU_INVENTORY_PRICE,
                                     '5', PCU_CLOSING_PRICE,
                                          0),
                 PCU_BASE_PRICE into aNewRate, aBasePrice
            from ACT_EVAL_CURRENCY
            where ACT_JOB_ID                = aACT_JOB_ID
              and ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;

        end if;

      exception
        when OTHERS then
          aNewRate   := 0;
          aBasePrice := 0;
          aEuroRate  := 0;

      end;

    end GetNewRate;

    --------
    function RoundAmount(aAmount             ACT_EVALUATION.EVA_AMOUNT_LC%type,
                         aC_ROUND_TYPE       ACS_FINANCIAL_CURRENCY.C_ROUND_TYPE%type,
                         aFIN_ROUNDED_AMOUNT ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type) return ACT_EVALUATION.EVA_AMOUNT_LC%type
    is
    begin
      if    aC_ROUND_TYPE = '0' then return aAmount;                                                     -- Pas d'arrondi
      elsif aC_ROUND_TYPE = '1' then return ACS_FUNCTION.RoundNear(aAmount, 0.05,                 0);    -- Arrondi commercial
      elsif aC_ROUND_TYPE = '2' then return ACS_FUNCTION.RoundNear(aAmount, aFIN_ROUNDED_AMOUNT, -1);    -- Arrondi inférieur
      elsif aC_ROUND_TYPE = '3' then return ACS_FUNCTION.RoundNear(aAmount, aFIN_ROUNDED_AMOUNT,  0);    -- Arrondi au plus près
      elsif aC_ROUND_TYPE = '4' then return ACS_FUNCTION.RoundNear(aAmount, aFIN_ROUNDED_AMOUNT,  1);    -- Arrondi supérieur
      else                           return aAmount;
      end if;
    end RoundAmount;

  -----
  begin
    --  raise_application_error(-20000, atblCurrency.count);

    open EvalParamCursor(aACT_JOB_ID);
    fetch EvalParamCursor into EvalParam;

    if EvalParamCursor%found then

      CtrlDate := ACT_CURRENCY_EVALUATION.GetDateOfPeriod(EvalParam.ACS_PERIOD_ID, false);

      -- Elimination éventuelle réévaluation existante
      delete from ACT_EVALUATION
        where ACT_EVAL_SELECTION_ID in (select ACT_EVAL_SELECTION_ID
                                          from ACT_EVAL_SELECTION
                                          where ACT_JOB_ID = aACT_JOB_ID);

      -- Comptes / Monnaies / Divisions à réévaluer
      open EvalSelectionCursor(aACT_JOB_ID);
      fetch EvalSelectionCursor into EvalSelection;

      while EvalSelectionCursor%found loop

        -- Cumuls à réévaluer
        open EvaluationMethodCursor(EvalParam.ACS_EVALUATION_METHOD_ID);
        fetch EvaluationMethodCursor into EvaluationMethod;

        OldAmountLC := 0;
        OldAmountFC := 0;

        while EvaluationMethodCursor%found loop

          if EvalParam.C_EVALUATION_METHOD = '2' then
            OldAmountLC := OldAmountLC + ACS_FUNCTION.PeriodSoldeAmountExpiries(EvalSelection.ACS_FINANCIAL_ACCOUNT_ID,
                                                                        EvalSelection.ACS_DIVISION_ACCOUNT_ID,
                                                                        EvalParam.ACS_PERIOD_ID,
                                                                        EvaluationMethod.C_TYPE_CUMUL,
                                                                        1,
                                                                        EvalSelection.ACS_FINANCIAL_CURRENCY_ID);

            OldAmountFC := OldAmountFC + ACS_FUNCTION.PeriodSoldeAmountExpiries(EvalSelection.ACS_FINANCIAL_ACCOUNT_ID,
                                                                        EvalSelection.ACS_DIVISION_ACCOUNT_ID,
                                                                        EvalParam.ACS_PERIOD_ID,
                                                                        EvaluationMethod.C_TYPE_CUMUL,
                                                                        0,
                                                                        EvalSelection.ACS_FINANCIAL_CURRENCY_ID);
          else

            OldAmountLC := OldAmountLC + ACS_FUNCTION.PeriodSoldeAmount(EvalSelection.ACS_FINANCIAL_ACCOUNT_ID,
                                                                        EvalSelection.ACS_DIVISION_ACCOUNT_ID,
                                                                        EvalParam.ACS_PERIOD_ID,
                                                                        EvaluationMethod.C_TYPE_CUMUL,
                                                                        1,
                                                                        EvalSelection.ACS_FINANCIAL_CURRENCY_ID);

            OldAmountFC := OldAmountFC + ACS_FUNCTION.PeriodSoldeAmount(EvalSelection.ACS_FINANCIAL_ACCOUNT_ID,
                                                                        EvalSelection.ACS_DIVISION_ACCOUNT_ID,
                                                                        EvalParam.ACS_PERIOD_ID,
                                                                        EvaluationMethod.C_TYPE_CUMUL,
                                                                        0,
                                                                        EvalSelection.ACS_FINANCIAL_CURRENCY_ID);
          end if;
          fetch EvaluationMethodCursor into EvaluationMethod;

        end loop;

        close EvaluationMethodCursor;

        if (OldAmountLC <> 0) or (OldAmountFC <> 0) then

          GetNewRate(aACT_JOB_ID, EvalSelection.ACS_FINANCIAL_CURRENCY_ID, CtrlDate, EvalParam.C_RATE_TYP, NewRate, BasePrice, EuroRate);

          begin
            if EuroRate <> 0 then
              AmountLC := OldAmountFC / EuroRate * NewRate / BasePrice;
            else
              AmountLC := OldAmountFC * NewRate / BasePrice;
            end if;
          exception
            when ZERO_DIVIDE then
              AmountLC := 0;
          end;

          AmountLC := RoundAmount(AmountLC, EvalParam.C_ROUND_TYPE, EvalParam.FIN_ROUNDED_AMOUNT);

          if (sign(abs(AmountLC) - abs(OldAmountLC)) = 1) or
             ((sign(OldAmountFC) in (1,0) and sign(OldAmountLC) = -1) or    --Solde compte ME positif ou 0 et solde compte MB négatif
              (sign(OldAmountFC) = -1 and sign(OldAmountLC) = 1)            --Solde compte ME négatif et solde compte MB positif
             ) then
            GainAmount := abs(AmountLC - OldAmountLC);
            LossAmount := 0;
          else
            LossAmount := abs(AmountLC - OldAmountLC);
            GainAmount := 0;
          end if;

          insert into ACT_EVALUATION
           (ACT_EVAL_SELECTION_ID,
            EVA_CTRL_DATE,
            EVA_BEF_AMOUNT_LC,
            EVA_BEF_AMOUNT_FC,
            EVA_AMOUNT_LC,
            EVA_GAIN_AMOUNT,
            EVA_LOSS_AMOUNT,
            EVA_EXCHANGE_RATE,
            EVA_BASE_PRICE)
          values
           (EvalSelection.ACT_EVAL_SELECTION_ID,
            CtrlDate,
            OldAmountLC,
            OldAmountFC,
            AmountLC,
            GainAmount,
            LossAmount,
            NewRate,
            BasePrice);

        end if;

        fetch EvalSelectionCursor into EvalSelection;

      end loop;

      close EvalSelectionCursor;

    end if;

    close EvalParamCursor;

  end CurrencyEvaluation;

  ------------------------
  procedure CreateDocument(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type)
  is
    ------
    cursor EvaluationsCursor is
      select
             PAR.ACS_PERIOD_ID,
             PAR.DOC_DOCUMENT_DATE,
             PAR.IMF_TRANSACTION_DATE,
             PAR.IMF_VALUE_DATE,
             PAR.IMF_DESCRIPTION,
             SEL.ACS_FINANCIAL_ACCOUNT_ID,
             SEL.ACS_FINANCIAL_CURRENCY_ID,
             SEL.ACS_DIVISION_ACCOUNT_ID,
             SEL.ACS_FIN_GAIN_ID,
             SEL.ACS_FIN_LOSS_ID,
             SEL.ACS_DIV_GAIN_ID,
             SEL.ACS_DIV_LOSS_ID,
             SEL.ACS_CPN_GAIN_ID,
             SEL.ACS_CPN_LOSS_ID,
             SEL.ACS_CDA_GAIN_ID,
             SEL.ACS_CDA_LOSS_ID,
             SEL.ACS_PF_GAIN_ID,
             SEL.ACS_PF_LOSS_ID,
             SEL.ACS_PJ_GAIN_ID,
             SEL.ACS_PJ_LOSS_ID,
             SEL.ACS_ACC_GAIN_DEBT_ID,
             SEL.ACS_ACC_LOSS_DEBT_ID,
             SEL.ACS_DIV_GAIN_DEBT_ID,
             SEL.ACS_DIV_LOSS_DEBT_ID,
             SEL.ACS_CPN_GAIN_DEBT_ID,
             SEL.ACS_CPN_LOSS_DEBT_ID,
             SEL.ACS_CDA_GAIN_DEBT_ID,
             SEL.ACS_CDA_LOSS_DEBT_ID,
             SEL.ACS_PF_GAIN_DEBT_ID,
             SEL.ACS_PF_LOSS_DEBT_ID,
             SEL.ACS_PJ_GAIN_DEBT_ID,
             SEL.ACS_PJ_LOSS_DEBT_ID,
             EVA.EVA_CTRL_DATE,
             EVA.EVA_BEF_AMOUNT_LC,
             EVA.EVA_BEF_AMOUNT_FC,
             EVA.EVA_AMOUNT_LC,
             EVA.EVA_GAIN_AMOUNT,
             EVA.EVA_LOSS_AMOUNT,
             EVA.EVA_EXCHANGE_RATE,
             EVA.EVA_BASE_PRICE
        from
             ACT_EVALUATION     EVA,
             ACT_EVAL_SELECTION SEL,
             ACT_EVAL_PARAM     PAR;

    GenerationMethod ACS_EVALUATION_METHOD.C_DOC_GENERATION%type;
    CatalogId        ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    FinJournalId     ACT_JOURNAL.ACT_JOURNAL_ID%type;
    MgmJournalId     ACT_JOURNAL.ACT_JOURNAL_ID%type;
    --------
    function GetGenerationMethod(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) return ACS_EVALUATION_METHOD.C_DOC_GENERATION%type
    is
      Method ACS_EVALUATION_METHOD.C_DOC_GENERATION%type;
    -----
    begin
      begin
        select
               MET.C_DOC_GENERATION into Method
          from
               ACS_EVALUATION_METHOD MET,
               ACT_EVAL_PARAM        PAR
          where
                PAR.ACT_JOB_ID               = aACT_JOB_ID
            and PAR.ACS_EVALUATION_METHOD_ID = MET.ACS_EVALUATION_METHOD_ID;
      exception
        when OTHERS then
          Method := '';
      end;
      return Method;
    end GetGenerationMethod;

    --------
    function GetCatalogId(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) return ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
    is
      CatalogId ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    -----
    begin
      begin
        select JSC.ACJ_CATALOGUE_DOCUMENT_ID into CatalogId
          from
               ACJ_JOB_TYPE_S_CATALOGUE JSC,
               ACT_JOB                  JOB
          where
                JOB.ACT_JOB_ID      = aACT_JOB_ID
            and JOB.ACJ_JOB_TYPE_ID = JSC.ACJ_JOB_TYPE_ID
            and JSC.JCA_DEFAULT     = 1
            and Rownum = 1;
      exception
        when OTHERS then
          CatalogId := 0;
      end;
      return CatalogId;
    end GetCatalogId;

    --------
    function GetJournalId(aACT_JOB_ID        ACT_JOB.ACT_JOB_ID%type,
                          aC_TYPE_ACCOUNTING ACS_ACCOUNTING.C_TYPE_ACCOUNTING%type) return ACT_JOURNAL.ACT_JOURNAL_ID%type
    is
      JournalId ACT_JOURNAL.ACT_JOURNAL_ID%type;
    -----
    begin
      begin
        select ACT_JOURNAL_ID into JournalId
          from
               ACS_ACCOUNTING ACC,
               ACT_JOURNAL    JOU
          where
                ACT_JOB_ID            = aACT_JOB_ID
            and JOU.ACS_ACCOUNTING_ID = ACC.ACS_ACCOUNTING_ID
            and C_TYPE_ACCOUNTING     = aC_TYPE_ACCOUNTING;
      exception
        when OTHERS then
          JournalId := null;
      end;
      return JournalId;
    end GetJournalId;

    --------
    function CreateDoc(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                       aACJ_CATALOGUE_DOCUMENT_ID ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                       aACT_JOURNAL_ID            ACT_DOCUMENT.ACT_JOURNAL_ID%type,
                       aACT_ACT_JOURNAL_ID        ACT_DOCUMENT.ACT_JOURNAL_ID%type,
                       aEvaluations               EvaluationsCursor%rowtype) return ACT_DOCUMENT.ACT_DOCUMENT_ID%type
    is
      DocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
      DocNumber  ACT_DOCUMENT.DOC_NUMBER%type;
      YearId     ACT_DOCUMENT.ACS_FINANCIAL_YEAR_ID%type;
    -----
    begin

      YearId := ACS_FUNCTION.GetFinancialYearId(aEvaluations.IMF_TRANSACTION_DATE);
      ACT_FUNCTIONS.GetDocNumber(aACJ_CATALOGUE_DOCUMENT_ID, YearId, DocNumber);

      select init_id_seq.nextval into DocumentId from dual;

      begin
        insert into ACT_DOCUMENT
         (ACT_DOCUMENT_ID,
          ACT_JOB_ID,
          PC_USER_ID,
          DOC_NUMBER,
          DOC_TOTAL_AMOUNT_DC,
          DOC_DOCUMENT_DATE,
          ACS_FINANCIAL_CURRENCY_ID,
          ACJ_CATALOGUE_DOCUMENT_ID,
          ACT_JOURNAL_ID,
          ACT_ACT_JOURNAL_ID,
          ACS_FINANCIAL_YEAR_ID,
          C_STATUS_DOCUMENT,
          DOC_TOTAL_AMOUNT_EUR,
          A_DATECRE,
          A_IDCRE)
        values
         (DocumentId,
          aACT_JOB_ID,
          UserId,
          DocNumber,
          0,
          aEvaluations.DOC_DOCUMENT_DATE,
          LocalCurrencyId,
          aACJ_CATALOGUE_DOCUMENT_ID,
          aACT_JOURNAL_ID,
          aACT_ACT_JOURNAL_ID,
          YearId,
          'PROV',
          0,
          sysdate,
          UserIni);

        insert into ACT_DOCUMENT_STATUS
          (ACT_DOCUMENT_STATUS_ID,
           ACT_DOCUMENT_ID,
           DOC_OK)
        values
          (init_id_seq.nextval,
           DocumentId,
           0);

      exception
        when OTHERS then
          DocumentId := null;
      end;

      return DocumentId;

    end CreateDoc;

    ---------
    procedure CreateImputations(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type,
                                aEvaluations     EvaluationsCursor%rowtype)
    is
      ImputationId           ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
      DistributionId         ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_DISTRIBUTION_ID%type;
      MgmImputationId        ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
      SubSetId               ACS_ACCOUNT.ACS_SUB_SET_ID%type;
      AmountLC_D             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
      AmountLC_C             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
      CPNAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      CDAAccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      PFAccountId            ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      PJAccountId            ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      ACCId                  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      DIVId                  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      CPNId                  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      CDAId                  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      PFId                   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      PJId                   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
      --------
      function GetC_BALANCE_SHEET_PROFIT_LOSS(aACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type)
        return ACS_FINANCIAL_ACCOUNT.C_BALANCE_SHEET_PROFIT_LOSS%type
      is
        BalanceSheetProfitLoss ACS_FINANCIAL_ACCOUNT.C_BALANCE_SHEET_PROFIT_LOSS%type;
      -----
      begin
        begin
          select C_BALANCE_SHEET_PROFIT_LOSS into BalanceSheetProfitLoss
            from ACS_FINANCIAL_ACCOUNT
            where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;
        exception
          when OTHERS then
            BalanceSheetProfitLoss := null;
        end;
        return BalanceSheetProfitLoss;
      end GetC_BALANCE_SHEET_PROFIT_LOSS;

      --------
      function GetACS_SUB_SET_ID(aACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type) return ACS_ACCOUNT.ACS_SUB_SET_ID%type
      is
        SubSetId ACS_ACCOUNT.ACS_SUB_SET_ID%type;
      -----
      begin
        begin
          select ACS_SUB_SET_ID into SubSetId
          from ACS_ACCOUNT
            where ACS_ACCOUNT_ID = aACS_ACCOUNT_ID;
        exception
          when OTHERS then
            SubSetId := null;
        end;
        return SubSetId;
      end GetACS_SUB_SET_ID;

      --------
      function GetACS_CPN_ACCOUNT_ID(aACS_FINANCIAL_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type) return ACS_FINANCIAL_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
      is
        CPNAccountId ACS_FINANCIAL_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
      -----
      begin
        begin
          select ACS_CPN_ACCOUNT_ID into CPNAccountId
            from ACS_FINANCIAL_ACCOUNT
            where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;
        exception
          when OTHERS then
            CPNAccountId := null;
        end;
        return CPNAccountId;
      end GetACS_CPN_ACCOUNT_ID;

      ---------
      procedure GetMgmAccounts(aACS_CPN_ACCOUNT_ID   in     ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                               aIMF_TRANSACTION_DATE in     ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
                               aACS_CDA_ACCOUNT_ID   in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                               aACS_PF_ACCOUNT_ID    in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                               aACS_PJ_ACCOUNT_ID    in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
      is
        C_CDA     ACS_CPN_ACCOUNT.C_CDA_IMPUTATION%type;
        C_PF      ACS_CPN_ACCOUNT.C_PF_IMPUTATION%type;
        C_PJ      ACS_CPN_ACCOUNT.C_PJ_IMPUTATION%type;
        CDA_PF_Ok boolean;
        function DefaultAccount(aACS_CPN_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                                aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
                                aTypAccount           number) return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
        is
          AccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
        begin
          begin
            if aTypAccount = 1 then  -- CDA
              select ACS_CDA_ACCOUNT_ID into AccountId
                from ACS_MGM_INTERACTION
                where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
                  and MGM_DEFAULT        = 1
                  and ((MGM_VALID_SINCE is null and MGM_VALID_TO is null)                     or
                       (MGM_VALID_SINCE is null and aIMF_TRANSACTION_DATE <= MGM_VALID_TO)    or
                       (MGM_VALID_TO    is null and aIMF_TRANSACTION_DATE >= MGM_VALID_SINCE) or
                       (aIMF_TRANSACTION_DATE between MGM_VALID_SINCE and MGM_VALID_TO))
                  and ACS_CDA_ACCOUNT_ID is not null;
            elsif aTypAccount = 2 then  -- PF
              select ACS_PF_ACCOUNT_ID into AccountId
                from ACS_MGM_INTERACTION
                where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
                  and MGM_DEFAULT        = 1
                  and ((MGM_VALID_SINCE is null and MGM_VALID_TO is null)                     or
                       (MGM_VALID_SINCE is null and aIMF_TRANSACTION_DATE <= MGM_VALID_TO)    or
                       (MGM_VALID_TO    is null and aIMF_TRANSACTION_DATE >= MGM_VALID_SINCE) or
                       (aIMF_TRANSACTION_DATE between MGM_VALID_SINCE and MGM_VALID_TO))
                  and ACS_PF_ACCOUNT_ID is not null;
            elsif aTypAccount = 2 then  -- PJ
              select ACS_PJ_ACCOUNT_ID into AccountId
                from ACS_MGM_INTERACTION
                where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
                  and MGM_DEFAULT        = 1
                  and ((MGM_VALID_SINCE is null and MGM_VALID_TO is null)                     or
                       (MGM_VALID_SINCE is null and aIMF_TRANSACTION_DATE <= MGM_VALID_TO)    or
                       (MGM_VALID_TO    is null and aIMF_TRANSACTION_DATE >= MGM_VALID_SINCE) or
                       (aIMF_TRANSACTION_DATE between MGM_VALID_SINCE and MGM_VALID_TO))
                  and ACS_PJ_ACCOUNT_ID is not null;
            end if;
          exception
            when OTHERS then
              AccountId := null;
          end;
          if AccountId is null then
            begin
              if    aTypAccount = 1 then  -- CDA
                select ACS_ACCOUNT_ID into AccountId
                  from ACS_ACCOUNT ACC,
                       ACS_SUB_SET SUB
                  where SUB.C_SUB_SET = 'CDA'
                    and SUB.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                    and ACC.ACC_NUMBER = (select min(ACC_NUMBER)
                                            from ACS_ACCOUNT ACC,
                                                 ACS_SUB_SET SUB
                                            where SUB.C_SUB_SET = 'CDA'
                                              and SUB.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID);
              elsif aTypAccount = 2 then  -- PF
                select ACS_ACCOUNT_ID into AccountId
                  from ACS_ACCOUNT ACC,
                       ACS_SUB_SET SUB
                  where SUB.C_SUB_SET = 'COS'
                    and SUB.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                    and ACC.ACC_NUMBER = (select min(ACC_NUMBER)
                                            from ACS_ACCOUNT ACC,
                                                 ACS_SUB_SET SUB
                                            where SUB.C_SUB_SET = 'COS'
                                              and SUB.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID);
              elsif aTypAccount = 3 then  -- PJ
                select ACS_ACCOUNT_ID into AccountId
                  from ACS_ACCOUNT ACC,
                       ACS_SUB_SET SUB
                  where SUB.C_SUB_SET = 'PRO'
                    and SUB.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                    and ACC.ACC_NUMBER = (select min(ACC_NUMBER)
                                            from ACS_ACCOUNT ACC,
                                                 ACS_SUB_SET SUB
                                            where SUB.C_SUB_SET = 'PRO'
                                              and SUB.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID);
              end if;
            exception
              when OTHERS then
                AccountId := null;
            end;
          end if;
          return AccountId;
        end;
      ----
      begin
        if aACS_CPN_ACCOUNT_ID is not null then

          select C_CDA_IMPUTATION,
                 C_PF_IMPUTATION,
                 C_PJ_IMPUTATION into C_CDA, C_PF, C_PJ
            from ACS_CPN_ACCOUNT
            where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID;

          CDA_PF_Ok := false;

          if C_CDA = '1' then
            if aACS_CDA_ACCOUNT_ID is null then
              aACS_CDA_ACCOUNT_ID := DefaultAccount(aACS_CPN_ACCOUNT_ID, aIMF_TRANSACTION_DATE, 1);
              if aACS_CDA_ACCOUNT_ID is not null then
                CDA_PF_Ok          := true;
              end if;
            else
              CDA_PF_Ok := true;
            end if;
          elsif C_CDA = '3' then
            aACS_CDA_ACCOUNT_ID := null;
          end if;

          if C_PF = '1' then
            if aACS_PF_ACCOUNT_ID is null then
              aACS_PF_ACCOUNT_ID := DefaultAccount(aACS_CPN_ACCOUNT_ID, aIMF_TRANSACTION_DATE, 2);
              if aACS_PF_ACCOUNT_ID is not null then
                CDA_PF_Ok           := true;
              end if;
            else
              CDA_PF_Ok := true;
            end if;
          elsif C_PF = '3' then
            aACS_PF_ACCOUNT_ID := null;
          end if;

          if not CDA_PF_Ok and C_CDA = '2' then
            if aACS_CDA_ACCOUNT_ID is null then
              aACS_CDA_ACCOUNT_ID := DefaultAccount(aACS_CPN_ACCOUNT_ID, aIMF_TRANSACTION_DATE, 1);
              if aACS_CDA_ACCOUNT_ID is not null then
                aACS_PF_ACCOUNT_ID := null;
                CDA_PF_Ok          := true;
              end if;
            else
              CDA_PF_Ok := true;
            end if;
          end if;

          if not CDA_PF_Ok and C_PF = '2' then
            if aACS_PF_ACCOUNT_ID is null then
              aACS_PF_ACCOUNT_ID := DefaultAccount(aACS_CPN_ACCOUNT_ID, aIMF_TRANSACTION_DATE, 2);
              if aACS_PF_ACCOUNT_ID is not null then
                aACS_CDA_ACCOUNT_ID := null;
                CDA_PF_Ok           := true;
              end if;
            else
              CDA_PF_Ok := true;
            end if;
          end if;

          if CDA_PF_Ok and (C_PJ = '1') then
            if aACS_PJ_ACCOUNT_ID is null then
              aACS_PJ_ACCOUNT_ID := DefaultAccount(aACS_CPN_ACCOUNT_ID, aIMF_TRANSACTION_DATE, 3);
            end if;
          elsif CDA_PF_Ok and (C_PJ = '3') then
            aACS_PJ_ACCOUNT_ID := null;
          end if;

          if not CDA_PF_Ok then
            aACS_PF_ACCOUNT_ID := null;
            aACS_CDA_ACCOUNT_ID := null;
            aACS_PJ_ACCOUNT_ID := null;
          end if;

        end if;

      end GetMgmAccounts;

      ---------
      procedure InitAmounts(aEvaluations in     EvaluationsCursor%rowtype,
                            aAmount_D    in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type,
                            aAmount_C    in out ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type,
                            aACCId       in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                            aDIVId       in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                            aCPNId       in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                            aCDAId       in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                            aPFId        in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                            aPJId        in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
      is
        BalanceSheetProfitLoss ACS_FINANCIAL_ACCOUNT.C_BALANCE_SHEET_PROFIT_LOSS%type;
      -----
      begin
        aAmount_D := 0;
        aAmount_C := 0;
        aACCId    := null;
        aDIVId    := null;
        aCPNId    := null;
        aCDAId    := null;
        aPFId     := null;
        aPJId     := null;

        BalanceSheetProfitLoss := GetC_BALANCE_SHEET_PROFIT_LOSS(aEvaluations.ACS_FINANCIAL_ACCOUNT_ID);

        if   (sign(abs(aEvaluations.EVA_AMOUNT_LC) - abs(aEvaluations.EVA_BEF_AMOUNT_LC)) = 1)
          or ((sign(aEvaluations.EVA_BEF_AMOUNT_FC) in (1,0) and sign(aEvaluations.EVA_BEF_AMOUNT_LC) = -1) or    --Solde compte ME positif ou 0 et solde compte MB négatif
              (sign(aEvaluations.EVA_BEF_AMOUNT_FC) = -1 and sign(aEvaluations.EVA_BEF_AMOUNT_LC) = 1)            --Solde compte ME négatif et solde compte MB positif
             ) then
          -- Augmentation montant MB
          if   (BalanceSheetProfitLoss = 'B' and sign(aEvaluations.EVA_BEF_AMOUNT_FC) in (0, 1))
            or (BalanceSheetProfitLoss = 'P' and sign(aEvaluations.EVA_BEF_AMOUNT_FC) = -1) then
            -- (Compte Bilan et Solde ME au débit) ou (Compte PP et Solde ME au crédit)
            -- Augmentation de créance
            if BalanceSheetProfitLoss = 'B' then
              aAmount_D := abs(aEvaluations.EVA_AMOUNT_LC - aEvaluations.EVA_BEF_AMOUNT_LC);
            else
              aAmount_C := abs(aEvaluations.EVA_AMOUNT_LC - aEvaluations.EVA_BEF_AMOUNT_LC);
            end if;
            aACCId := aEvaluations.ACS_FIN_GAIN_ID;
            aDIVId := aEvaluations.ACS_DIV_GAIN_ID;
            aCPNId := aEvaluations.ACS_CPN_GAIN_ID;
            aCDAId := aEvaluations.ACS_CDA_GAIN_ID;
            aPFId  := aEvaluations.ACS_PF_GAIN_ID;
            aPJId  := aEvaluations.ACS_PJ_GAIN_ID;
          else
            -- Augmentation de dette
            if BalanceSheetProfitLoss = 'B' then
              aAmount_C := abs(aEvaluations.EVA_AMOUNT_LC - aEvaluations.EVA_BEF_AMOUNT_LC);
            else
              aAmount_D := abs(aEvaluations.EVA_AMOUNT_LC - aEvaluations.EVA_BEF_AMOUNT_LC);
            end if;
            aACCId := aEvaluations.ACS_ACC_GAIN_DEBT_ID;
            aDIVId := aEvaluations.ACS_DIV_GAIN_DEBT_ID;
            aCPNId := aEvaluations.ACS_CPN_GAIN_DEBT_ID;
            aCDAId := aEvaluations.ACS_CDA_GAIN_DEBT_ID;
            aPFId  := aEvaluations.ACS_PF_GAIN_DEBT_ID;
            aPJId  := aEvaluations.ACS_PJ_GAIN_DEBT_ID;
          end if;
        else
          -- Diminution montant MB
          if   (BalanceSheetProfitLoss = 'B' and sign(aEvaluations.EVA_BEF_AMOUNT_FC) in (0, 1))
            or (BalanceSheetProfitLoss = 'P' and sign(aEvaluations.EVA_BEF_AMOUNT_FC) = -1) then
            -- (Compte Bilan et Solde ME au débit) ou (Compte PP et Solde ME au crédit)
            -- Diminution de créance
            if BalanceSheetProfitLoss = 'B' then
              aAmount_C := abs(aEvaluations.EVA_AMOUNT_LC - aEvaluations.EVA_BEF_AMOUNT_LC);
            else
              aAmount_D := abs(aEvaluations.EVA_AMOUNT_LC - aEvaluations.EVA_BEF_AMOUNT_LC);
            end if;
            aACCId := aEvaluations.ACS_FIN_LOSS_ID;
            aDIVId := aEvaluations.ACS_DIV_LOSS_ID;
            aCPNId := aEvaluations.ACS_CPN_LOSS_ID;
            aCDAId := aEvaluations.ACS_CDA_LOSS_ID;
            aPFId  := aEvaluations.ACS_PF_LOSS_ID;
            aPJId  := aEvaluations.ACS_PJ_LOSS_ID;
          else
            -- Diminution de dette
            if BalanceSheetProfitLoss = 'B' then
              aAmount_D := abs(aEvaluations.EVA_AMOUNT_LC - aEvaluations.EVA_BEF_AMOUNT_LC);
            else
              aAmount_C := abs(aEvaluations.EVA_AMOUNT_LC - aEvaluations.EVA_BEF_AMOUNT_LC);
            end if;
            aACCId := aEvaluations.ACS_ACC_LOSS_DEBT_ID;
            aDIVId := aEvaluations.ACS_DIV_LOSS_DEBT_ID;
            aCPNId := aEvaluations.ACS_CPN_LOSS_DEBT_ID;
            aCDAId := aEvaluations.ACS_CDA_LOSS_DEBT_ID;
            aPFId  := aEvaluations.ACS_PF_LOSS_DEBT_ID;
            aPJId  := aEvaluations.ACS_PJ_LOSS_DEBT_ID;
          end if;
        end if;

      end InitAmounts;

    -----
    begin

--    if aEvaluations.EVA_AMOUNT_LC <> 0 then

        InitAmounts(aEvaluations, AmountLC_D, AmountLC_C, ACCId, DIVId, CPNId, CDAId, PFId, PJId);

        -- Imputations financières
        select init_id_seq.nextval into ImputationId from dual;

        insert into ACT_FINANCIAL_IMPUTATION
         (ACT_FINANCIAL_IMPUTATION_ID,
          ACT_DOCUMENT_ID,
          ACS_PERIOD_ID,
          ACS_FINANCIAL_CURRENCY_ID,
          ACS_ACS_FINANCIAL_CURRENCY_ID,
          ACS_FINANCIAL_ACCOUNT_ID,
          IMF_PRIMARY,
          IMF_DESCRIPTION,
          IMF_VALUE_DATE,
          IMF_TRANSACTION_DATE,
          IMF_AMOUNT_LC_D,
          IMF_AMOUNT_LC_C,
          IMF_AMOUNT_FC_D,
          IMF_AMOUNT_FC_C,
          IMF_AMOUNT_EUR_D,
          IMF_AMOUNT_EUR_C,
          IMF_TYPE,
          IMF_BASE_PRICE,
          IMF_EXCHANGE_RATE,
          C_GENRE_TRANSACTION,
          A_DATECRE,
          A_IDCRE)
        values
         (ImputationId,
          aACT_DOCUMENT_ID,
          aEvaluations.ACS_PERIOD_ID,
          aEvaluations.ACS_FINANCIAL_CURRENCY_ID,
          LocalCurrencyId,
          aEvaluations.ACS_FINANCIAL_ACCOUNT_ID,
          0,  -- IMF_PRIMARY
          aEvaluations.IMF_DESCRIPTION,
          aEvaluations.IMF_VALUE_DATE,
          aEvaluations.IMF_TRANSACTION_DATE,
          AmountLC_D,
          AmountLC_C,
          0,  -- IMF_AMOUNT_FC_D
          0,  -- IMF_AMOUNT_FC_C
          0,  -- IMF_AMOUNT_EUR_D
          0,  -- IMF_AMOUNT_EUR_C
          'MAN',
          0,  -- IMF_BASE_PRICE
          0,  -- IMF_EXCHANGE_RATE
          '8',  -- C_GENRE_TRANSACTION
          sysdate,
          UserIni);

        -- Distributions financières
        if aEvaluations.ACS_DIVISION_ACCOUNT_ID is not null then

          SubSetId := GetACS_SUB_SET_ID(aEvaluations.ACS_DIVISION_ACCOUNT_ID);
          select init_id_seq.nextval into DistributionId from dual;

          insert into ACT_FINANCIAL_DISTRIBUTION
           (ACT_FINANCIAL_DISTRIBUTION_ID,
            ACT_FINANCIAL_IMPUTATION_ID,
            ACS_DIVISION_ACCOUNT_ID,
            ACS_SUB_SET_ID,
            FIN_DESCRIPTION,
            FIN_AMOUNT_LC_D,
            FIN_AMOUNT_LC_C,
            FIN_AMOUNT_FC_D,
            FIN_AMOUNT_FC_C,
            FIN_AMOUNT_EUR_D,
            FIN_AMOUNT_EUR_C,
            A_DATECRE,
            A_IDCRE)
          values
           (DistributionId,
            ImputationId,
            aEvaluations.ACS_DIVISION_ACCOUNT_ID,
            SubSetId,
            aEvaluations.IMF_DESCRIPTION,
            AmountLC_D,
            AmountLC_C,
            0, -- FIN_AMOUNT_FC_D,
            0, -- FIN_AMOUNT_FC_C,
            0, -- FIN_AMOUNT_EUR_D,
            0, -- FIN_AMOUNT_EUR_C
            sysdate,
            UserIni);

        end if;

        -- Imputations analytiques
        CPNAccountId := GetACS_CPN_ACCOUNT_ID(aEvaluations.ACS_FINANCIAL_ACCOUNT_ID);

        CDAAccountId := null;
        PFAccountId  := null;
        PJAccountId  := null;
        GetMgmAccounts(CPNAccountId, aEvaluations.IMF_TRANSACTION_DATE, CDAAccountId, PFAccountId, PJAccountId);

        if CPNAccountId is not null and (CDAAccountId is not null or PFAccountId is not null) then

          select init_id_seq.nextval into MgmImputationId from dual;

          insert into ACT_MGM_IMPUTATION
           (ACT_MGM_IMPUTATION_ID,
            ACT_FINANCIAL_IMPUTATION_ID,
            ACT_DOCUMENT_ID,
            ACS_PERIOD_ID,
            ACS_FINANCIAL_CURRENCY_ID,
            ACS_ACS_FINANCIAL_CURRENCY_ID,
            ACS_CPN_ACCOUNT_ID,
            ACS_CDA_ACCOUNT_ID,
            ACS_PF_ACCOUNT_ID,
            IMM_VALUE_DATE,
            IMM_TRANSACTION_DATE,
            IMM_DESCRIPTION,
            IMM_AMOUNT_LC_D,
            IMM_AMOUNT_LC_C,
            IMM_AMOUNT_FC_D,
            IMM_AMOUNT_FC_C,
            IMM_AMOUNT_EUR_D,
            IMM_AMOUNT_EUR_C,
            IMM_EXCHANGE_RATE,
            IMM_BASE_PRICE,
            IMM_PRIMARY,
            IMM_TYPE,
            IMM_GENRE,
            A_DATECRE,
            A_IDCRE)
          values
           (MgmImputationId,
            ImputationId,
            aACT_DOCUMENT_ID,
            aEvaluations.ACS_PERIOD_ID,
            aEvaluations.ACS_FINANCIAL_CURRENCY_ID,
            LocalCurrencyId,
            CPNAccountId,
            CDAAccountId,
            PFAccountId,
            aEvaluations.IMF_VALUE_DATE,
            aEvaluations.IMF_TRANSACTION_DATE,
            aEvaluations.IMF_DESCRIPTION,
            AmountLC_D,
            AmountLC_C,
            0, -- IMM_AMOUNT_FC_D,
            0, -- IMM_AMOUNT_FC_C,
            0, -- IMM_AMOUNT_EUR_D,
            0, -- IMM_AMOUNT_EUR_C,
            0, -- IMM_EXCHANGE_RATE,
            0, -- IMM_BASE_PRICE,
            0, -- IMM_PRIMARY,
            'MAN',
            'STD',
            sysdate,
            UserIni);

          -- Distributions analytiques
          if PJAccountId is not null then

            SubSetId := GetACS_SUB_SET_ID(PJAccountId);

            insert into ACT_MGM_DISTRIBUTION
             (ACT_MGM_DISTRIBUTION_ID,
              ACT_MGM_IMPUTATION_ID,
              ACS_PJ_ACCOUNT_ID,
              ACS_SUB_SET_ID,
              MGM_DESCRIPTION,
              MGM_AMOUNT_LC_D,
              MGM_AMOUNT_LC_C,
              MGM_AMOUNT_FC_D,
              MGM_AMOUNT_FC_C,
              MGM_AMOUNT_EUR_D,
              MGM_AMOUNT_EUR_C,
              A_DATECRE,
              A_IDCRE)
            values
             (init_id_seq.nextval,
              MgmImputationId,
              PJAccountId,
              SubSetId,
              aEvaluations.IMF_DESCRIPTION,
              AmountLC_D,
              AmountLC_C,
              0, -- MGM_AMOUNT_FC_D,
              0, -- MGM_AMOUNT_FC_C,
              0, -- MGM_AMOUNT_EUR_D,
              0, -- MGM_AMOUNT_EUR_C,
              sysdate,
              UserIni);

          end if;

        end if;

        -- Contre écriture

        -- Imputations financières
        select init_id_seq.nextval into ImputationId from dual;

        insert into ACT_FINANCIAL_IMPUTATION
         (ACT_FINANCIAL_IMPUTATION_ID,
          ACT_DOCUMENT_ID,
          ACS_PERIOD_ID,
          ACS_FINANCIAL_CURRENCY_ID,
          ACS_ACS_FINANCIAL_CURRENCY_ID,
          ACS_FINANCIAL_ACCOUNT_ID,
          IMF_PRIMARY,
          IMF_DESCRIPTION,
          IMF_VALUE_DATE,
          IMF_TRANSACTION_DATE,
          IMF_AMOUNT_LC_D,
          IMF_AMOUNT_LC_C,
          IMF_AMOUNT_FC_D,
          IMF_AMOUNT_FC_C,
          IMF_AMOUNT_EUR_D,
          IMF_AMOUNT_EUR_C,
          IMF_TYPE,
          IMF_BASE_PRICE,
          IMF_EXCHANGE_RATE,
          C_GENRE_TRANSACTION,
          A_DATECRE,
          A_IDCRE)
        values
         (ImputationId,
          aACT_DOCUMENT_ID,
          aEvaluations.ACS_PERIOD_ID,
          aEvaluations.ACS_FINANCIAL_CURRENCY_ID,
          LocalCurrencyId,
          ACCId,
          0,  -- IMF_PRIMARY
          aEvaluations.IMF_DESCRIPTION,
          aEvaluations.IMF_VALUE_DATE,
          aEvaluations.IMF_TRANSACTION_DATE,
          AmountLC_C,
          AmountLC_D,
          0,  -- IMF_AMOUNT_FC_D
          0,  -- IMF_AMOUNT_FC_C
          0,  -- IMF_AMOUNT_EUR_D
          0,  -- IMF_AMOUNT_EUR_C
          'MAN',
          0,  -- IMF_BASE_PRICE
          0,  -- IMF_EXCHANGE_RATE
          '8',  -- C_GENRE_TRANSACTION
          sysdate,
          UserIni);

        -- Distributions financières
        if nvl(DIVId, aEvaluations.ACS_DIVISION_ACCOUNT_ID) is not null then

          SubSetId := GetACS_SUB_SET_ID(nvl(DIVId, aEvaluations.ACS_DIVISION_ACCOUNT_ID));
          select init_id_seq.nextval into DistributionId from dual;

          insert into ACT_FINANCIAL_DISTRIBUTION
           (ACT_FINANCIAL_DISTRIBUTION_ID,
            ACT_FINANCIAL_IMPUTATION_ID,
            ACS_DIVISION_ACCOUNT_ID,
            ACS_SUB_SET_ID,
            FIN_DESCRIPTION,
            FIN_AMOUNT_LC_D,
            FIN_AMOUNT_LC_C,
            FIN_AMOUNT_FC_D,
            FIN_AMOUNT_FC_C,
            FIN_AMOUNT_EUR_D,
            FIN_AMOUNT_EUR_C,
            A_DATECRE,
            A_IDCRE)
          values
           (DistributionId,
            ImputationId,
            nvl(DIVId, aEvaluations.ACS_DIVISION_ACCOUNT_ID),
            SubSetId,
            aEvaluations.IMF_DESCRIPTION,
            AmountLC_C,
            AmountLC_D,
            0, -- FIN_AMOUNT_FC_D,
            0, -- FIN_AMOUNT_FC_C,
            0, -- FIN_AMOUNT_EUR_D,
            0, -- FIN_AMOUNT_EUR_C
            sysdate,
            UserIni);

        end if;

        GetMgmAccounts(CPNId, aEvaluations.IMF_TRANSACTION_DATE, CDAId, PFId, PJId);

        -- Imputations analytiques
        if CPNId is not null and (CDAId is not null or PFId is not null) then

          select init_id_seq.nextval into MgmImputationId from dual;

          insert into ACT_MGM_IMPUTATION
           (ACT_MGM_IMPUTATION_ID,
            ACT_FINANCIAL_IMPUTATION_ID,
            ACT_DOCUMENT_ID,
            ACS_PERIOD_ID,
            ACS_FINANCIAL_CURRENCY_ID,
            ACS_ACS_FINANCIAL_CURRENCY_ID,
            ACS_CPN_ACCOUNT_ID,
            ACS_CDA_ACCOUNT_ID,
            ACS_PF_ACCOUNT_ID,
            IMM_VALUE_DATE,
            IMM_TRANSACTION_DATE,
            IMM_DESCRIPTION,
            IMM_AMOUNT_LC_D,
            IMM_AMOUNT_LC_C,
            IMM_AMOUNT_FC_D,
            IMM_AMOUNT_FC_C,
            IMM_AMOUNT_EUR_D,
            IMM_AMOUNT_EUR_C,
            IMM_EXCHANGE_RATE,
            IMM_BASE_PRICE,
            IMM_PRIMARY,
            IMM_TYPE,
            IMM_GENRE,
            A_DATECRE,
            A_IDCRE)
          values
           (MgmImputationId,
            ImputationId,
            aACT_DOCUMENT_ID,
            aEvaluations.ACS_PERIOD_ID,
            aEvaluations.ACS_FINANCIAL_CURRENCY_ID,
            LocalCurrencyId,
            CPNId,
            CDAId,
            PFId,
            aEvaluations.IMF_VALUE_DATE,
            aEvaluations.IMF_TRANSACTION_DATE,
            aEvaluations.IMF_DESCRIPTION,
            AmountLC_C,
            AmountLC_D,
            0, -- IMM_AMOUNT_FC_D,
            0, -- IMM_AMOUNT_FC_C,
            0, -- IMM_AMOUNT_EUR_D,
            0, -- IMM_AMOUNT_EUR_C,
            0, -- IMM_EXCHANGE_RATE,
            0, -- IMM_BASE_PRICE,
            0, -- IMM_PRIMARY,
            'MAN',
            'STD',
            sysdate,
            UserIni);

          -- Distributions analytiques
          if PJId is not null then

            SubSetId := GetACS_SUB_SET_ID(PJId);

            insert into ACT_MGM_DISTRIBUTION
             (ACT_MGM_DISTRIBUTION_ID,
              ACT_MGM_IMPUTATION_ID,
              ACS_PJ_ACCOUNT_ID,
              ACS_SUB_SET_ID,
              MGM_DESCRIPTION,
              MGM_AMOUNT_LC_D,
              MGM_AMOUNT_LC_C,
              MGM_AMOUNT_FC_D,
              MGM_AMOUNT_FC_C,
              MGM_AMOUNT_EUR_D,
              MGM_AMOUNT_EUR_C,
              A_DATECRE,
              A_IDCRE)
            values
             (init_id_seq.nextval,
              MgmImputationId,
              PJId,
              SubSetId,
              aEvaluations.IMF_DESCRIPTION,
              AmountLC_C,
              AmountLC_D,
              0, -- MGM_AMOUNT_FC_D,
              0, -- MGM_AMOUNT_FC_C,
              0, -- MGM_AMOUNT_EUR_D,
              0, -- MGM_AMOUNT_EUR_C,
              sysdate,
              UserIni);

          end if;

        end if;

--    end if;

    end CreateImputations;

    ---------
    procedure CtrlDocument(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      Id ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
      vAmountDoc ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
      vAmountEur ACT_DOCUMENT.DOC_TOTAL_AMOUNT_EUR%type;
    -----
    begin
      begin
        select ACT_DOCUMENT_ID into Id
          from ACT_FINANCIAL_IMPUTATION
          where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;
      exception
        when NO_DATA_FOUND then
          Id := null;
        when TOO_MANY_ROWS then
          Id := 1;
      end;

      if Id is not null then
        update ACT_FINANCIAL_IMPUTATION
          set IMF_PRIMARY = 1
          where ACT_FINANCIAL_IMPUTATION_ID = (select min(ACT_FINANCIAL_IMPUTATION_ID)
                                                 from ACT_FINANCIAL_IMPUTATION
                                                 where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID);

        /*Réception des montants de l'imputation primaire du document*/
        select abs(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), abs(IMF_AMOUNT_EUR_D - IMF_AMOUNT_EUR_C)
        into   vAmountDoc, vAmountEur
        from ACT_FINANCIAL_IMPUTATION
        where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
          and IMF_PRIMARY + 0 = 1;
        /*Mise à jour du montant document*/
        update ACT_DOCUMENT
        set DOC_TOTAL_AMOUNT_DC   = vAmountDoc
           ,DOC_TOTAL_AMOUNT_EUR  = vAmountEur
        where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

      else
        delete from ACT_DOCUMENT
          where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;
      end if;
    end CtrlDocument;

    ---------
    procedure GenerateAccountDocument(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                                      aACJ_CATALOGUE_DOCUMENT_ID ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                                      aACT_JOURNAL_ID            ACT_DOCUMENT.ACT_JOURNAL_ID%type,
                                      aACT_ACT_JOURNAL_ID        ACT_DOCUMENT.ACT_JOURNAL_ID%type)
    is
      ------ C_DOC_GENERATION = '1' - Un document par compte
      cursor DocumentAccountCursor(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) is
        select distinct nvl(ACS_FIN_ACC_ID, ACS_FINANCIAL_ACCOUNT_ID)
          from ACT_EVAL_SELECTION
          where ACT_JOB_ID = aACT_JOB_ID;

      cursor EvaluationAccountCursor(aACT_JOB_ID               ACT_JOB.ACT_JOB_ID%type,
                                     aACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type) is
        select
               PAR.ACS_PERIOD_ID,
               PAR.DOC_DOCUMENT_DATE,
               PAR.IMF_TRANSACTION_DATE,
               PAR.IMF_VALUE_DATE,
               PAR.IMF_DESCRIPTION,
               nvl(SEL.ACS_FIN_ACC_ID, SEL.ACS_FINANCIAL_ACCOUNT_ID) ACS_FINANCIAL_ACCOUNT_ID,
               SEL.ACS_FINANCIAL_CURRENCY_ID,
               nvl(SEL.ACS_DIV_ACC_ID, SEL.ACS_DIVISION_ACCOUNT_ID) ACS_DIVISION_ACCOUNT_ID,
               SEL.ACS_FIN_GAIN_ID,
               SEL.ACS_FIN_LOSS_ID,
               SEL.ACS_DIV_GAIN_ID,
               SEL.ACS_DIV_LOSS_ID,
               SEL.ACS_CPN_GAIN_ID,
               SEL.ACS_CPN_LOSS_ID,
               SEL.ACS_CDA_GAIN_ID,
               SEL.ACS_CDA_LOSS_ID,
               SEL.ACS_PF_GAIN_ID,
               SEL.ACS_PF_LOSS_ID,
               SEL.ACS_PJ_GAIN_ID,
               SEL.ACS_PJ_LOSS_ID,
               SEL.ACS_ACC_GAIN_DEBT_ID,
               SEL.ACS_ACC_LOSS_DEBT_ID,
               SEL.ACS_DIV_GAIN_DEBT_ID,
               SEL.ACS_DIV_LOSS_DEBT_ID,
               SEL.ACS_CPN_GAIN_DEBT_ID,
               SEL.ACS_CPN_LOSS_DEBT_ID,
               SEL.ACS_CDA_GAIN_DEBT_ID,
               SEL.ACS_CDA_LOSS_DEBT_ID,
               SEL.ACS_PF_GAIN_DEBT_ID,
               SEL.ACS_PF_LOSS_DEBT_ID,
               SEL.ACS_PJ_GAIN_DEBT_ID,
               SEL.ACS_PJ_LOSS_DEBT_ID,
               EVA.EVA_CTRL_DATE,
               EVA.EVA_BEF_AMOUNT_LC,
               EVA.EVA_BEF_AMOUNT_FC,
               EVA.EVA_AMOUNT_LC,
               EVA.EVA_GAIN_AMOUNT,
               EVA.EVA_LOSS_AMOUNT,
               EVA.EVA_EXCHANGE_RATE,
               EVA.EVA_BASE_PRICE
          from
               ACT_EVALUATION        EVA,
               ACT_EVAL_SELECTION    SEL,
               ACT_EVAL_PARAM        PAR
          where
                PAR.ACT_JOB_ID                                = aACT_JOB_ID
            and PAR.ACT_JOB_ID                                = SEL.ACT_JOB_ID
            and SEL.ACT_EVAL_SELECTION_ID                     = EVA.ACT_EVAL_SELECTION_ID
            and nvl(ACS_FIN_ACC_ID, ACS_FINANCIAL_ACCOUNT_ID) = aACS_FINANCIAL_ACCOUNT_ID;

      EvaluationAccount EvaluationsCursor%rowtype;

      DocumentId        ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
      AccountId         ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;

    -----
    begin
      open DocumentAccountCursor(aACT_JOB_ID);
      fetch DocumentAccountCursor into AccountId;

      while DocumentAccountCursor%found loop

        open EvaluationAccountCursor(aACT_JOB_ID, AccountId);
        fetch EvaluationAccountCursor into EvaluationAccount;

        if EvaluationAccountCursor%found then

          DocumentId := CreateDoc(aACT_JOB_ID, aACJ_CATALOGUE_DOCUMENT_ID, aACT_JOURNAL_ID, aACT_ACT_JOURNAL_ID, EvaluationAccount);

          while EvaluationAccountCursor%found loop

            CreateImputations(DocumentId, EvaluationAccount);
            fetch EvaluationAccountCursor into EvaluationAccount;

          end loop;

          CtrlDocument(DocumentId);

        end if;

        close EvaluationAccountCursor;

        fetch DocumentAccountCursor into AccountId;

      end loop;

      close DocumentAccountCursor;

    end GenerateAccountDocument;

    ---------
    procedure GenerateAccCurrencyDocument(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                                          aACJ_CATALOGUE_DOCUMENT_ID ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                                          aACT_JOURNAL_ID            ACT_DOCUMENT.ACT_JOURNAL_ID%type,
                                          aACT_ACT_JOURNAL_ID        ACT_DOCUMENT.ACT_JOURNAL_ID%type)
    is
      ------ C_DOC_GENERATION = '2' - Un document par compte et par monnaie
      cursor DocumentAccCurrencyCursor(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) is
        select distinct nvl(ACS_FIN_ACC_ID, ACS_FINANCIAL_ACCOUNT_ID),
                        ACS_FINANCIAL_CURRENCY_ID
          from ACT_EVAL_SELECTION
          where ACT_JOB_ID = aACT_JOB_ID;

      ------
      cursor EvaluationAccCurrencyCursor(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                                         aACS_FINANCIAL_ACCOUNT_ID  ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type,
                                         aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type) is
        select
               PAR.ACS_PERIOD_ID,
               PAR.DOC_DOCUMENT_DATE,
               PAR.IMF_TRANSACTION_DATE,
               PAR.IMF_VALUE_DATE,
               PAR.IMF_DESCRIPTION,
               nvl(SEL.ACS_FIN_ACC_ID, SEL.ACS_FINANCIAL_ACCOUNT_ID) ACS_FINANCIAL_ACCOUNT_ID,
               SEL.ACS_FINANCIAL_CURRENCY_ID,
               nvl(SEL.ACS_DIV_ACC_ID, SEL.ACS_DIVISION_ACCOUNT_ID) ACS_DIVISION_ACCOUNT_ID,
               SEL.ACS_FIN_GAIN_ID,
               SEL.ACS_FIN_LOSS_ID,
               SEL.ACS_DIV_GAIN_ID,
               SEL.ACS_DIV_LOSS_ID,
               SEL.ACS_CPN_GAIN_ID,
               SEL.ACS_CPN_LOSS_ID,
               SEL.ACS_CDA_GAIN_ID,
               SEL.ACS_CDA_LOSS_ID,
               SEL.ACS_PF_GAIN_ID,
               SEL.ACS_PF_LOSS_ID,
               SEL.ACS_PJ_GAIN_ID,
               SEL.ACS_PJ_LOSS_ID,
               SEL.ACS_ACC_GAIN_DEBT_ID,
               SEL.ACS_ACC_LOSS_DEBT_ID,
               SEL.ACS_DIV_GAIN_DEBT_ID,
               SEL.ACS_DIV_LOSS_DEBT_ID,
               SEL.ACS_CPN_GAIN_DEBT_ID,
               SEL.ACS_CPN_LOSS_DEBT_ID,
               SEL.ACS_CDA_GAIN_DEBT_ID,
               SEL.ACS_CDA_LOSS_DEBT_ID,
               SEL.ACS_PF_GAIN_DEBT_ID,
               SEL.ACS_PF_LOSS_DEBT_ID,
               SEL.ACS_PJ_GAIN_DEBT_ID,
               SEL.ACS_PJ_LOSS_DEBT_ID,
               EVA.EVA_CTRL_DATE,
               EVA.EVA_BEF_AMOUNT_LC,
               EVA.EVA_BEF_AMOUNT_FC,
               EVA.EVA_AMOUNT_LC,
               EVA.EVA_GAIN_AMOUNT,
               EVA.EVA_LOSS_AMOUNT,
               EVA.EVA_EXCHANGE_RATE,
               EVA.EVA_BASE_PRICE
          from
               ACS_ACCOUNT           ACC2,
               ACS_ACCOUNT           ACC1,
               ACT_EVALUATION        EVA,
               ACT_EVAL_SELECTION    SEL,
               ACT_EVAL_PARAM        PAR
          where
                PAR.ACT_JOB_ID                                = aACT_JOB_ID
            and PAR.ACT_JOB_ID                                = SEL.ACT_JOB_ID
            and SEL.ACT_EVAL_SELECTION_ID                     = EVA.ACT_EVAL_SELECTION_ID
            and nvl(ACS_FIN_ACC_ID, ACS_FINANCIAL_ACCOUNT_ID) = aACS_FINANCIAL_ACCOUNT_ID
            and SEL.ACS_FINANCIAL_CURRENCY_ID                 = aACS_FINANCIAL_CURRENCY_ID
            and SEL.ACS_FIN_ACC_ID                            = ACC1.ACS_ACCOUNT_ID (+)
            and SEL.ACS_FINANCIAL_ACCOUNT_ID                  = ACC2.ACS_ACCOUNT_ID (+)
          order by nvl(ACC1.ACC_NUMBER, ACC2.ACC_NUMBER);

      EvaluationAccCurrency EvaluationsCursor%rowtype;

      DocumentId            ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
      AccountId             ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
      CurrencyId            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;

    -----
    begin
      open DocumentAccCurrencyCursor(aACT_JOB_ID);
      fetch DocumentAccCurrencyCursor into AccountId, CurrencyId;

      while DocumentAccCurrencyCursor%found loop

        open EvaluationAccCurrencyCursor(aACT_JOB_ID, AccountId, CurrencyId);
        fetch EvaluationAccCurrencyCursor into EvaluationAccCurrency;

        if EvaluationAccCurrencyCursor%found then

          DocumentId := CreateDoc(aACT_JOB_ID, aACJ_CATALOGUE_DOCUMENT_ID, aACT_JOURNAL_ID, aACT_ACT_JOURNAL_ID, EvaluationAccCurrency);

          while EvaluationAccCurrencyCursor%found loop

            CreateImputations(DocumentId, EvaluationAccCurrency);
            fetch EvaluationAccCurrencyCursor into EvaluationAccCurrency;

          end loop;

          CtrlDocument(DocumentId);

        end if;

        close EvaluationAccCurrencyCursor;

        fetch DocumentAccCurrencyCursor into AccountId, CurrencyId;

      end loop;

      close DocumentAccCurrencyCursor;
    end GenerateAccCurrencyDocument;

    ---------
    procedure GenerateCurrencyDocument(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                                       aACJ_CATALOGUE_DOCUMENT_ID ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                                       aACT_JOURNAL_ID            ACT_DOCUMENT.ACT_JOURNAL_ID%type,
                                       aACT_ACT_JOURNAL_ID        ACT_DOCUMENT.ACT_JOURNAL_ID%type)
    is
      ------ C_DOC_GENERATION = '3' - Un document par monnaie
      cursor DocumentCurrencyCursor(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) is
        select distinct ACS_FINANCIAL_CURRENCY_ID
          from ACT_EVAL_SELECTION
          where ACT_JOB_ID = aACT_JOB_ID;

      ------
      cursor EvaluationCurrencyCursor(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                                      aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type) is
        select
               PAR.ACS_PERIOD_ID,
               PAR.DOC_DOCUMENT_DATE,
               PAR.IMF_TRANSACTION_DATE,
               PAR.IMF_VALUE_DATE,
               PAR.IMF_DESCRIPTION,
               nvl(SEL.ACS_FIN_ACC_ID, SEL.ACS_FINANCIAL_ACCOUNT_ID) ACS_FINANCIAL_ACCOUNT_ID,
               SEL.ACS_FINANCIAL_CURRENCY_ID,
               nvl(SEL.ACS_DIV_ACC_ID, SEL.ACS_DIVISION_ACCOUNT_ID) ACS_DIVISION_ACCOUNT_ID,
               SEL.ACS_FIN_GAIN_ID,
               SEL.ACS_FIN_LOSS_ID,
               SEL.ACS_DIV_GAIN_ID,
               SEL.ACS_DIV_LOSS_ID,
               SEL.ACS_CPN_GAIN_ID,
               SEL.ACS_CPN_LOSS_ID,
               SEL.ACS_CDA_GAIN_ID,
               SEL.ACS_CDA_LOSS_ID,
               SEL.ACS_PF_GAIN_ID,
               SEL.ACS_PF_LOSS_ID,
               SEL.ACS_PJ_GAIN_ID,
               SEL.ACS_PJ_LOSS_ID,
               SEL.ACS_ACC_GAIN_DEBT_ID,
               SEL.ACS_ACC_LOSS_DEBT_ID,
               SEL.ACS_DIV_GAIN_DEBT_ID,
               SEL.ACS_DIV_LOSS_DEBT_ID,
               SEL.ACS_CPN_GAIN_DEBT_ID,
               SEL.ACS_CPN_LOSS_DEBT_ID,
               SEL.ACS_CDA_GAIN_DEBT_ID,
               SEL.ACS_CDA_LOSS_DEBT_ID,
               SEL.ACS_PF_GAIN_DEBT_ID,
               SEL.ACS_PF_LOSS_DEBT_ID,
               SEL.ACS_PJ_GAIN_DEBT_ID,
               SEL.ACS_PJ_LOSS_DEBT_ID,
               EVA.EVA_CTRL_DATE,
               EVA.EVA_BEF_AMOUNT_LC,
               EVA.EVA_BEF_AMOUNT_FC,
               EVA.EVA_AMOUNT_LC,
               EVA.EVA_GAIN_AMOUNT,
               EVA.EVA_LOSS_AMOUNT,
               EVA.EVA_EXCHANGE_RATE,
               EVA.EVA_BASE_PRICE
          from
               ACS_ACCOUNT           ACC2,
               ACS_ACCOUNT           ACC1,
               ACT_EVALUATION        EVA,
               ACT_EVAL_SELECTION    SEL,
               ACT_EVAL_PARAM        PAR
          where
                PAR.ACT_JOB_ID                = aACT_JOB_ID
            and PAR.ACT_JOB_ID                = SEL.ACT_JOB_ID
            and SEL.ACT_EVAL_SELECTION_ID     = EVA.ACT_EVAL_SELECTION_ID
            and SEL.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
            and SEL.ACS_FIN_ACC_ID            = ACC1.ACS_ACCOUNT_ID (+)
            and SEL.ACS_FINANCIAL_ACCOUNT_ID  = ACC2.ACS_ACCOUNT_ID (+)
          order by nvl(ACC1.ACC_NUMBER, ACC2.ACC_NUMBER);

      EvaluationCurrency EvaluationsCursor%rowtype;

      DocumentId         ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
      CurrencyId         ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;

    -----
    begin
      open DocumentCurrencyCursor(aACT_JOB_ID);
      fetch DocumentCurrencyCursor into CurrencyId;

      while DocumentCurrencyCursor%found loop

        open EvaluationCurrencyCursor(aACT_JOB_ID, CurrencyId);
        fetch EvaluationCurrencyCursor into EvaluationCurrency;

        if EvaluationCurrencyCursor%found then

          DocumentId := CreateDoc(aACT_JOB_ID, aACJ_CATALOGUE_DOCUMENT_ID, aACT_JOURNAL_ID, aACT_ACT_JOURNAL_ID, EvaluationCurrency);

          while EvaluationCurrencyCursor%found loop

            CreateImputations(DocumentId, EvaluationCurrency);
            fetch EvaluationCurrencyCursor into EvaluationCurrency;

          end loop;

          CtrlDocument(DocumentId);

        end if;

        close EvaluationCurrencyCursor;

        fetch DocumentCurrencyCursor into CurrencyId;

      end loop;

      close DocumentCurrencyCursor;
    end GenerateCurrencyDocument;

    ---------
    procedure GenerateDocument(aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type,
                               aACJ_CATALOGUE_DOCUMENT_ID ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                               aACT_JOURNAL_ID            ACT_DOCUMENT.ACT_JOURNAL_ID%type,
                               aACT_ACT_JOURNAL_ID        ACT_DOCUMENT.ACT_JOURNAL_ID%type)
    is
      ------
      cursor EvaluationAllCursor(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type) is
        select
               PAR.ACS_PERIOD_ID,
               PAR.DOC_DOCUMENT_DATE,
               PAR.IMF_TRANSACTION_DATE,
               PAR.IMF_VALUE_DATE,
               PAR.IMF_DESCRIPTION,
               nvl(SEL.ACS_FIN_ACC_ID, SEL.ACS_FINANCIAL_ACCOUNT_ID) ACS_FINANCIAL_ACCOUNT_ID,
               SEL.ACS_FINANCIAL_CURRENCY_ID,
               nvl(SEL.ACS_DIV_ACC_ID, SEL.ACS_DIVISION_ACCOUNT_ID) ACS_DIVISION_ACCOUNT_ID,
               SEL.ACS_FIN_GAIN_ID,
               SEL.ACS_FIN_LOSS_ID,
               SEL.ACS_DIV_GAIN_ID,
               SEL.ACS_DIV_LOSS_ID,
               SEL.ACS_CPN_GAIN_ID,
               SEL.ACS_CPN_LOSS_ID,
               SEL.ACS_CDA_GAIN_ID,
               SEL.ACS_CDA_LOSS_ID,
               SEL.ACS_PF_GAIN_ID,
               SEL.ACS_PF_LOSS_ID,
               SEL.ACS_PJ_GAIN_ID,
               SEL.ACS_PJ_LOSS_ID,
               SEL.ACS_ACC_GAIN_DEBT_ID,
               SEL.ACS_ACC_LOSS_DEBT_ID,
               SEL.ACS_DIV_GAIN_DEBT_ID,
               SEL.ACS_DIV_LOSS_DEBT_ID,
               SEL.ACS_CPN_GAIN_DEBT_ID,
               SEL.ACS_CPN_LOSS_DEBT_ID,
               SEL.ACS_CDA_GAIN_DEBT_ID,
               SEL.ACS_CDA_LOSS_DEBT_ID,
               SEL.ACS_PF_GAIN_DEBT_ID,
               SEL.ACS_PF_LOSS_DEBT_ID,
               SEL.ACS_PJ_GAIN_DEBT_ID,
               SEL.ACS_PJ_LOSS_DEBT_ID,
               EVA.EVA_CTRL_DATE,
               EVA.EVA_BEF_AMOUNT_LC,
               EVA.EVA_BEF_AMOUNT_FC,
               EVA.EVA_AMOUNT_LC,
               EVA.EVA_GAIN_AMOUNT,
               EVA.EVA_LOSS_AMOUNT,
               EVA.EVA_EXCHANGE_RATE,
               EVA.EVA_BASE_PRICE
          from
               ACS_ACCOUNT           ACC2,
               ACS_ACCOUNT           ACC1,
               ACT_EVALUATION        EVA,
               ACT_EVAL_SELECTION    SEL,
               ACT_EVAL_PARAM        PAR
          where
                PAR.ACT_JOB_ID               = aACT_JOB_ID
            and PAR.ACT_JOB_ID               = SEL.ACT_JOB_ID
            and SEL.ACT_EVAL_SELECTION_ID    = EVA.ACT_EVAL_SELECTION_ID
            and SEL.ACS_FIN_ACC_ID           = ACC1.ACS_ACCOUNT_ID (+)
            and SEL.ACS_FINANCIAL_ACCOUNT_ID = ACC2.ACS_ACCOUNT_ID (+)
          order by nvl(ACC1.ACC_NUMBER, ACC2.ACC_NUMBER);

      EvaluationAll EvaluationsCursor%rowtype;

      DocumentId    ACT_DOCUMENT.ACT_DOCUMENT_ID%type;

    -----
    begin
      open EvaluationAllCursor(aACT_JOB_ID);
      fetch EvaluationAllCursor into EvaluationAll;

      if EvaluationAllCursor%found then

        DocumentId := CreateDoc(aACT_JOB_ID, aACJ_CATALOGUE_DOCUMENT_ID, aACT_JOURNAL_ID, aACT_ACT_JOURNAL_ID, EvaluationAll);

        while EvaluationAllCursor%found loop

          CreateImputations(DocumentId, EvaluationAll);
          fetch EvaluationAllCursor into EvaluationAll;

        end loop;

        CtrlDocument(DocumentId);

      end if;

      close EvaluationAllCursor;
    end GenerateDocument;

  -----
  -----
  begin

    CatalogId := GetCatalogId(aACT_JOB_ID);

    if CatalogId > 0 then

      FinJournalId     := GetJournalId(aACT_JOB_ID, 'FIN');
      MgmJournalId     := GetJournalId(aACT_JOB_ID, 'MAN');
      GenerationMethod := GetGenerationMethod(aACT_JOB_ID);

      if    GenerationMethod = '1' then  -- Un document par compte
        GenerateAccountDocument(aACT_JOB_ID, CatalogId, FinJournalId, MgmJournalId);
      elsif GenerationMethod = '2' then  -- Un document par compte et par monnaie
        GenerateAccCurrencyDocument(aACT_JOB_ID, CatalogId, FinJournalId, MgmJournalId);
      elsif GenerationMethod = '3' then  -- Un document par monnaie
        GenerateCurrencyDocument(aACT_JOB_ID, CatalogId, FinJournalId, MgmJournalId);
      elsif GenerationMethod = '4' then  -- Un document par réévaluation
        GenerateDocument(aACT_JOB_ID, CatalogId, FinJournalId, MgmJournalId);
      else
        null;
      end if;

    end if;

  end CreateDocument;

  -------------------------
  function GetConvertAmount(aAmount        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type,
                            aFromFinCurrId ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                            aToFinCurrId   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                            aDate          date,
                            aRateType      number default 1) return ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
                            -- aRateType : Type de cours -> 1 : Cours du jour
                            --                              2 : Cours d'évaluation
                            --                              3 : Cours d'inventaire
                            --                              4 : Cours de bouclement
                            --                              5 : Cours de facturation
  is
    aRound         number(1);
    BaseChange     number(1);
    aExchangeRate  ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    aBasePrice     ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    aAmountEUR     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    aAmountConvert ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
  -----
  begin

    aRound         := 1;
    BaseChange     := 0;
    aExchangeRate  := 0;
    aBasePrice     := 0;
    aAmountEUR     := 0;
    aAmountConvert := 0;

    ACT_DOC_TRANSACTION.ConvertAmounts(aAmount, aFromFinCurrId, aToFinCurrId, aDate, aRound, aRateType, aExchangeRate, aBasePrice, aAmountEUR, aAmountConvert);

    return aAmountConvert;

  end GetConvertAmount;

-- Initialisation des variables pour la session
-----
begin
  UserIni         := PCS.PC_I_LIB_SESSION.GetUserIni;
  UserId          := PCS.PC_I_LIB_SESSION.GetUserId;
  LocalCurrencyId := ACS_FUNCTION.GetLocalCurrencyId;
end ACT_CURRENCY_EVALUATION;
