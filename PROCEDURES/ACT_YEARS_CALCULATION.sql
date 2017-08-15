--------------------------------------------------------
--  DDL for Procedure ACT_YEARS_CALCULATION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "ACT_YEARS_CALCULATION" (aType in number default 0)
/**
* Description
*   Recalulation des totaux par type
* @author BL
* @lastUpdate
* @version DEVELOP
* @public
* @param aType  :  0: Toutes, 1: Financières, 2: Analytiques
*/
is
  -- curseur de recherche des exercices comptables
  cursor YearsCursor is
    select ACS_FINANCIAL_YEAR_ID
      from ACS_FINANCIAL_YEAR
      where C_STATE_FINANCIAL_YEAR in ('CLO', 'ACT')
      order by FYE_NO_EXERCICE asc;

  YearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;

-----
begin

  open YearsCursor;
  fetch YearsCursor into YearId;

  while YearsCursor%found loop

    if aType in (0, 1) then
      ACT_TOTAL_CALCULATION.YearCalculation(YearId);
      commit;
    end if;

    if aType in (0, 2) then
      ACT_TOTAL_CALCULATION.MgmYearCalculation(YearId);
      commit;
    end if;

    fetch YearsCursor into YearId;

  end loop;

  close YearsCursor;

end ACT_YEARS_CALCULATION;
