--------------------------------------------------------
--  DDL for Package Body GAL_LIB_CURRENCY_RISK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_LIB_CURRENCY_RISK" 
is
  /**
  * function CanDeleteCurrRisk
  * Description
  *   Indique si l'on peut effacer une ou toutes les couvertures d'une affaire
  */
  function CanDeleteCurrRisk(
    iCurrRiskVirtualID in GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type default null
  , iProjectID         in GAL_PROJECT.GAL_PROJECT_ID%type default null
  )
    return number
  is
    cursor lcrCurrRisk(cCurrRiskVirtualID in GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type, cProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
    is
      select GAL_CURRENCY_RISK_VIRTUAL_ID
           , nvl(GCV_PCENT, 0) as GCV_PCENT
           , nvl(GCV_AMOUNT, 0) as GCV_AMOUNT
           , nvl(GCV_BALANCE, 0) as GCV_BALANCE
        from GAL_CURRENCY_RISK_VIRTUAL
       where GAL_CURRENCY_RISK_VIRTUAL_ID = nvl(cCurrRiskVirtualID, GAL_CURRENCY_RISK_VIRTUAL_ID)
         and GAL_PROJECT_ID = nvl(cProjectID, GAL_PROJECT_ID);

    ltplCurrRisk lcrCurrRisk%rowtype;
    lnCanDelete  number(1)             := 1;
    lnDocsCount  integer;
  begin
    if    (iCurrRiskVirtualID is not null)
       or (iProjectID is not null) then
      -- Curseur sur les couvertures virtuelles de l'affaire
      open lcrCurrRisk(iCurrRiskVirtualID, iProjectID);

      fetch lcrCurrRisk
       into ltplCurrRisk;

      while(lcrCurrRisk%found)
       and (lnCanDelete = 1) loop
        -- Solde de la couverture <> montant
        if     (ltplCurrRisk.GCV_PCENT = 0)
           and (ltplCurrRisk.GCV_AMOUNT <> ltplCurrRisk.GCV_BALANCE) then
          -- Couverture utilisée -> Effacement interdit
          lnCanDelete  := 0;
        else
          -- Vérifier si des documents sont liés à la tranche que l'on va effacer
          select count(*)
            into lnDocsCount
            from DOC_DOCUMENT
           where GAL_CURRENCY_RISK_VIRTUAL_ID = ltplCurrRisk.GAL_CURRENCY_RISK_VIRTUAL_ID;

          -- Couverture utilisée -> Effacement interdit
          if lnDocsCount > 0 then
            lnCanDelete  := 0;
          end if;
        end if;

        fetch lcrCurrRisk
         into ltplCurrRisk;
      end loop;

      close lcrCurrRisk;
    end if;

    return lnCanDelete;
  end CanDeleteCurrRisk;

  /**
  * function ExistsLinkedLogisticDocs
  * Description
  *   Indique s'il existe des documents logistique liés à l'affaire et dont le cours de change est forcé (sur le gabarit)
  */
  function ExistsLinkedLogisticDocs(iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
    return number
  is
    cursor lcrRcoList
    is
      select distinct column_value as DOC_RECORD_ID
                 from table(GAL_LIB_PROJECT.GetRecordList(iProjectID) );

    ltplRcoList lcrRcoList%rowtype;
    lnResult    integer              := 0;
  begin
    open lcrRcoList;

    fetch lcrRcoList
     into ltplRcoList;

    while(lcrRcoList%found)
     and (lnResult = 0) loop
      -- Contrôle l'existance de documents liés à l'affaire et dont le cours est forcé
      select nvl(max(1), 0) as DOC_EXISTS
        into lnResult
        from dual
       where exists(
               select DMT.DOC_DOCUMENT_ID
                 from DOC_GAUGE_STRUCTURED GAS
                    , DOC_DOCUMENT DMT
                    , DOC_POSITION POS
                where POS.DOC_RECORD_ID = ltplRcoList.DOC_RECORD_ID
                  and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                  and DMT.C_DOCUMENT_STATUS <> '05'   -- document pas annulé
                  and DMT.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyID
                  and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
                  and GAS.GAS_CURR_RATE_FORCED = 1
               union
               select DMT.DOC_DOCUMENT_ID
                 from DOC_GAUGE_STRUCTURED GAS
                    , DOC_DOCUMENT DMT
                    , DOC_POSITION_IMPUTATION POS
                where POS.DOC_RECORD_ID = ltplRcoList.DOC_RECORD_ID
                  and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                  and DMT.C_DOCUMENT_STATUS <> '05'   -- document pas annulé
                  and DMT.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyID
                  and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
                  and GAS.GAS_CURR_RATE_FORCED = 1);

      fetch lcrRcoList
       into ltplRcoList;
    end loop;

    close lcrRcoList;

    return lnResult;
  end ExistsLinkedLogisticDocs;

  /**
  * function ExistsLinkedFinancialDocs
  * Description
  *   Indique s'il existe des documents finance liés à l'affaire
  */
  function ExistsLinkedFinancialDocs(iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
    return number
  is
    cursor lcrRcoList
    is
      select distinct column_value as DOC_RECORD_ID
                 from table(GAL_LIB_PROJECT.GetRecordList(iProjectID) );

    ltplRcoList lcrRcoList%rowtype;
    lnResult    integer              := 0;
  begin
    open lcrRcoList;

    fetch lcrRcoList
     into ltplRcoList;

    while(lcrRcoList%found)
     and (lnResult = 0) loop
      -- Contrôle l'existance de documents liés à l'affaire et dont le cours est forcé
      select nvl(max(1), 0) as DOC_EXISTS
        into lnResult
        from dual
       where exists(
                select FIM.DOC_RECORD_ID
                  from ACT_FINANCIAL_IMPUTATION FIM
                 where FIM.DOC_RECORD_ID = ltplRcoList.DOC_RECORD_ID
                   and FIM.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyID
                   and FIM.IMF_PRIMARY = 1);

      fetch lcrRcoList
       into ltplRcoList;
    end loop;

    close lcrRcoList;

    return lnResult;
  end ExistsLinkedFinancialDocs;
end GAL_LIB_CURRENCY_RISK;
