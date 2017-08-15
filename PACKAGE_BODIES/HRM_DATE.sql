--------------------------------------------------------
--  DDL for Package Body HRM_DATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_DATE" 
/**
 * Package de gestion des dates pour les calculs des salaires.
 *
 * @version 1.0
 * @date 10.1999
 * @author jsomers
 * @author spfister
 * @author ireber
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
as
  -- Internal variable to hold actual budget date
  gd_budget_date   date;
  -- Internal variable to activate Calcul of ACDays
  gn_calc_ac_days  binary_integer default 1;
  -- Internal variable to activate RetroCalcul
  gb_calc_is_retro boolean        default false;

  -- Private cursors to select begin and end dates for the active calculation period
  cursor gcur_period
  is
    select PER_BEGIN
         , PER_END
      from HRM_PERIOD
     where PER_ACT = 1;

  cursor gcur_next_inout_in_date(id in hrm_person.hrm_person_id%type, gDate in date)
  is
    select   INO_IN - 1
        from HRM_IN_OUT
       where HRM_EMPLOYEE_ID = id
         and INO_IN > gDate
         and C_IN_OUT_CATEGORY = '3'
    order by INO_IN;

  cursor gcur_empl_inout(id in hrm_person.hrm_person_id%type, endPeriod in date)
  is
    select INO_IN
         , INO_OUT
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = id
       and INO_IN <= endPeriod
       and C_IN_OUT_CATEGORY = '3';

  procedure Set_BudgetYear(vBudgetYear in hrm_budget_version.hbu_year%type)
  is
  begin
    gd_budget_date  := null;

    if (vBudgetYear is not null) then
      gd_budget_date  := to_date('31.12.' || to_char(vBudgetYear), 'dd-mm-yyyy');
    end if;
  exception
    when others then
      null;
  end;

  procedure Set_CalcACDays(vCalcACDays in integer)
  is
  begin
    gn_calc_ac_days  := vCalcACDays;
  end;

  function Get_CalcRetro
    return integer
  is
  begin
    return case
      when gb_calc_is_retro then 1
      else 0
    end;
  end;

  procedure Set_CalcRetro(vCalcRetro in integer)
  is
  begin
    gb_calc_is_retro  := vCalcRetro != 0;
  end;

  function Get_BudgetYear
    return date
  is
  begin
    return gd_budget_date;
  end;

  function Get_IsBudgetInit
    return integer
  is
  begin
    return case
      when(gd_budget_date is not null) then 1
      else 0
    end;
  end;

  function get_LastPayDate(Empid in hrm_person.hrm_person_id%type)
    return date
  is
    ld_result date;
  begin
    if (gd_budget_date is not null) then
      return null;
    end if;

    -- we look for last pay and store it into tmpDate Then we return it
    -- exception sends back null
    select emp_last_pay_date
      into ld_result
      from hrm_person
     where hrm_person_id = Empid;

    return ld_result;
  exception
    when no_data_found then
      return null;
  end;

  function get_LastPayDateAC(Empid in hrm_person.hrm_person_id%type)
    return date
  is
    ld_result date;
  begin
    if (gd_budget_date is not null) then
      return null;
    end if;

    if (gn_calc_ac_days != 1) then
      return hrm_date.ActivePeriod;
    end if;

    -- we look for last pay and store it into tmpDate Then we return it
    -- exception sends back null
    select emp_last_pay_date_AC
      into ld_result
      from hrm_person
     where hrm_person_id = Empid;

    return ld_result;
  exception
    when no_data_found then
      return null;
  end;

-- Cette fonction est utilisée pour le calcul des répartitions 13ème v_hrm_break_prop_13M
-- pour ne prendre en compte que les mois qui ont provisionnés le paiement.
-- Dans le cas ou l'employé a travaillé Janv et Févr, le 13 13ème est ventilé sur les répartitions
-- Janv et Fév. L'employé revient en novembre, en décembre, le 13ème sera ventilé sur répartition Nov, Déc.
  function get_BeginOfInOutInYear(EmpId in hrm_person.hrm_person_id%type)
    return date
  is
    ld_begin_year date;
    ld_result     date;
  begin
    select max(INO_IN)
      into ld_result
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = EmpId
       and C_IN_OUT_STATUS = 'ACT'
       and C_IN_OUT_CATEGORY = '3';

    ld_begin_year  := hrm_date.BeginOfYear;
    return case
      when(ld_result >= ld_begin_year) then ld_result
      when(ld_result < ld_begin_year) then ld_begin_year
      else null
    end;
  exception
    when no_data_found then
      return null;
  end;

  function Days_Between(initDate in date, eDate in date)
    return integer
  is
    ld_last_day date;
    ln_months   binary_integer;
    x           binary_integer;
    y           binary_integer;
    l_md        binary_integer;
    l_me        binary_integer;
    l_jd        binary_integer;
    l_je        binary_integer;
    l_ad        binary_integer;
    l_ae        binary_integer;
  begin
    l_ad  := to_number(to_char(eDate, 'yyyy') );
    l_ae  := to_number(to_char(initDate, 'yyyy') );
    l_md  := to_number(to_char(eDate, 'mm') );
    l_me  := to_number(to_char(initDate, 'mm') );
    l_jd  := to_number(to_char(eDate, 'dd') );
    l_je  := to_number(to_char(initDate, 'dd') );
    l_jd  := case
              when     l_md = 2
                   and l_jd >= 28 then 30
              else least(30, l_jd)
            end;
    l_je  := case
              when     l_me = 2
                   and l_je >= 28 then 30
              else least(30, l_je)
            end;
    return (l_ad - l_ae) * 360 + (l_md - l_me) * 30 + l_jd - l_je + 1;
  end;

  function Days_BetweenFR(initDate in date, eDate in date)
    return integer
  is
    ld_last_day date;
    ln_months   binary_integer;
    InitDay     binary_integer;
    ln_result   binary_integer;
  begin
    ld_last_day  := nvl(eDate, last_day(sysdate) );
    -- compute months number
    ln_months    := months_between(trunc(ld_last_day, 'MM'), trunc(initDate, 'MM') );

    if (ln_months != 0) then
      ln_result  := (ln_months - 1) * 30;
      -- Add Days of InitDate
      InitDay    := to_char(InitDate, 'DD');

      if (InitDay != 1) then
        ln_result  := ln_result + to_char(last_day(InitDate), 'DD') - InitDay + 1;
      else
        ln_result  := ln_result + 30;
      end if;

      -- Add Days of ld_last_day
      if (ld_last_day < last_day(ld_last_day) ) then
        ln_result  := ln_result + to_char(ld_last_day, 'DD');
      else
        ln_result  := ln_result + 30;
      end if;
    else
      -- Same Month
      ln_result  := to_char(ld_last_day, 'DD') - to_char(InitDate, 'DD') + 1;

      if not(ln_result < to_char(last_day(ld_last_day), 'DD') ) then
        ln_result  := 30;
      end if;
    end if;

    return ln_result;
  end;

  function Days_SinceBPeriod(EmpId in hrm_person.hrm_person_id%type, period in date)
    return integer
  is
  begin
    return hrm_date.AC_Days_SinceLastPay(EmpId);
  end;

  function NDays_SinceBPeriod(EmpId in hrm_person.hrm_person_id%type, period in date)
    return integer
  is
  begin
    return hrm_date.Days_SinceLastPay(EmpId);
  end;

  function Days_SinceBYear(EmpId in hrm_person.hrm_person_id%type, period in date)
    return integer
  is
  begin
    return hrm_date.AC_Days_SinceBeginOfYear(EmpId);
  end;

  function NDays_SinceBYear(EmpId in hrm_person.hrm_person_id%type, period in date)
    return integer
  is
  begin
    return hrm_date.Days_SinceBeginOfYear(EmpId);
  end;

  function AC_Days_SinceLastPay(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    -- we initialize result as we'll use it as return value. Normaly the period
    -- should be the last day of the active period.
    ln_result   binary_integer := 0;
    begindate   date;
    endDate     date;
    beginPeriod date;
    endPeriod   date;
    lastPayDate date;
  begin
    -- we test Empid before all and raise an exception if 0 (default)
    if (EmpId is null) then
      return 0;
    end if;

    -- let's get the last pay date for that employee whose number equals Empid
    lastPayDate  := hrm_date.get_LastPayDateAC(Empid);

    if (not gb_calc_is_retro) then
      -- Searches begin and end dates for active Period
      hrm_date.PeriodDates(beginPeriod, endPeriod);
    else
      -- AlreadyDone
      if (trunc(lastPayDate, 'YY') = hrm_date.BeginOfYear) then
        return 0;
      end if;

      endPeriod    := hrm_date.BeginOfYear - 1;   -- 31.12 Last Year
      beginPeriod  := trunc(endPeriod, 'MM');   -- 01.12 Last Year
    end if;

    -- if last pay date the period is in the same period as the active period
    -- for that employee whe raise an exception and send back 0
    if (lastPayDate in(beginPeriod, endPeriod) ) then
      return 0;
    end if;

    for tplInOut in gcur_empl_inout(EmpId, endPeriod) loop
      -- we initialize the begin date with the firt day of the month given by the active period
      beginDate  := beginPeriod;

      -- if employe has been arleady paid in the current year and if last pay date is in a different
      -- month than the period then  begin period should be lastPyDate + 1
      if (months_between(beginDate, lastPayDate) > 1.0) then
        -- we test if last pay date is current year if it's not we change it to current year
        beginDate  := case
                       when(trunc(lastPayDate, 'YY') != trunc(beginPeriod, 'YY') ) then trunc(beginPeriod, 'YY')
                       else trunc(last_day(lastPayDate) + 1, 'MM')
                     end;
      end if;

      -- if employee has not been paid we put the begin of the year as begin fate
      if (lastPayDate is null) then
        beginDate  := trunc(beginPeriod, 'YY');
      end if;

      -- if the date out of the employee is greater than begin date or if it si null, wich means
      -- that he has not yet leaved then end Date is the last day of the period
      if (   tplInOut.ino_out >= beginDate
          or tplInOut.ino_out is null) then
        -- if employee's starting date is greater than begin of period then begin date
        -- becommes starting date
        if (tplInOut.ino_in > beginDate) then
          beginDate  := tplInOut.ino_in;
        end if;

        -- if employee's end date is smaller than last day of period then end date
        -- becommes employee's end date
        endDate    := endPeriod;

        if (tplInOut.ino_out < endDate) then
          endDate  := tplInOut.ino_out;
        end if;

        -- we add the days between begin and end date into result
        ln_result  := ln_result + hrm_date.days_between(beginDate, endDate);
      end if;
    end loop;

    return ln_result;
  end;

  function AC_Days_SinceLastPayFR(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    -- we initialize result as we'll use it as return value. Normaly the period
    -- should be the last day of the active period.
    ln_result   binary_integer := 0;
    begindate   date;
    endDate     date;
    beginPeriod date;
    endPeriod   date;
    lastPayDate date;
  begin
    -- we test Empid before all and raise an exception if 0 (default)
    if (EmpId is null) then
      return 0;
    end if;

    -- let's get the last pay date for that employee whose number equals Empid
    lastPayDate  := hrm_date.get_LastPayDateAC(Empid);

    if (not gb_calc_is_retro) then
      -- Searches begin and end dates for active Period
      hrm_date.PeriodDates(beginPeriod, endPeriod);
    else
      -- AlreadyDone
      if (trunc(lastPayDate, 'YY') = hrm_date.BeginOfYear) then
        return 0;
      end if;

      endPeriod    := hrm_date.BeginOfYear - 1;   -- 31.12 Last Year
      beginPeriod  := trunc(endPeriod, 'MM');   -- 01.12 Last Year
    end if;

    -- if last pay date the period is in the same period as the active period
    -- for that employee whe raise an exception and send back 0
    if (lastPayDate in(beginPeriod, endPeriod) ) then
      return 0;
    end if;

    for tplInOut in gcur_empl_inout(EmpId, endPeriod) loop
      -- we initialize the begin date with the firt day of the month given by the active period
      beginDate  := beginPeriod;

      -- if employe has been arleady paid in the current year and if last pay date is in a different
      -- month than the period then  begin period should be lastPyDate + 1
      if (months_between(beginDate, lastPayDate) > 1.0) then
        -- we test if last pay date is current year if it's not we change it to current year
        beginDate  := case
                       when(trunc(lastPayDate, 'YY') != trunc(beginPeriod, 'YY') ) then trunc(beginPeriod, 'YY')
                       else trunc(last_day(lastPayDate) + 1, 'MM')
                     end;
      end if;

      -- if employee has not been paid we put the begin of the year as begin fate
      if (lastPayDate is null) then
        beginDate  := trunc(beginPeriod, 'YY');
      end if;

      -- if the date out of the employee is greater than begin date or if it si null, wich means
      -- that he has not yet leaved then end Date is the last day of the period
      if (   tplInOut.ino_out >= beginDate
          or tplInOut.ino_out is null) then
        -- if employee's starting date is greater than begin of period then begin date
        -- becommes starting date
        if (tplInOut.ino_in > beginDate) then
          beginDate  := tplInOut.ino_in;
        end if;

        -- if employee's end date is smaller than last day of period then end date
        -- becommes employee's end date
        endDate    := endPeriod;

        if (tplInOut.ino_out < endDate) then
          endDate  := tplInOut.ino_out;
        end if;

        -- we add the days between begin and end date into result
        ln_result  := ln_result + hrm_date.Days_BetweenFR(beginDate, endDate);
      end if;
    end loop;

    return ln_result;
  end;

  function Days_SinceLastPay(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    -- we initialize result as we'll use it as return value. Normaly the period
    -- should be the last day of the active period.
    ln_result   binary_integer := 0;
    begindate   date;
    endDate     date;
    lastPayDate date;
    beginPeriod date;
    endPeriod   date;
  begin
    -- we test EmpId before all and raise an exception if 0 (default)
    if (EmpId is null) then
      return 0;
    end if;

    -- let's get the last pay date for that employee whose number equals Empid
    lastPayDate  := hrm_date.get_LastPayDate(Empid);
    -- Searches begin and end dates for active Period
    hrm_date.PeriodDates(beginPeriod, endPeriod);

    for tplInOut in gcur_empl_inout(EmpId, endPeriod) loop
      -- we initialize the begin date with the firt day of the month given by the period
      beginDate  := beginPeriod;

      if (months_between(beginDate, lastPayDate) > 1.0) then
        -- we test if last pay date is current year if it's not we change it to current year
        beginDate  := case
                       when(trunc(lastPayDate, 'YY') != trunc(beginPeriod, 'YY') ) then trunc(beginPeriod, 'YY')
                       else trunc(lastPayDate, 'MM')
                     end;
      end if;

      -- if employee has'nt been yet paid we put the begin of the year as begin date
      if (lastPayDate is null) then
        beginDate  := trunc(beginPeriod, 'YY');
      end if;

      -- if the date out of the employee is greater than begin date or if it si nuul, wich means
      -- that he has not yet leaved then end Date is the last day of the period
      if (   tplInOut.ino_out >= beginDate
          or tplInOut.ino_out is null) then
        -- if employee's starting date is greater than begin of period then begin date
        -- becommes starting date
        if (tplInOut.ino_in > beginDate) then
          beginDate  := tplInOut.ino_in;
        end if;

        -- if employee's end date is smaller than last day of period then end date
        -- becommes employee's end date
        endDate    := endPeriod;

        if (tplInOut.ino_out < endDate) then
          endDate  := tplInOut.ino_out;
        end if;

        -- we add the days between begin and end date into result
        ln_result  := ln_result + endDate - beginDate + 1;
      end if;
    end loop;

    return ln_result;
  end;

  function AC_Days_SinceBeginOfYear(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result   binary_integer := 0;
    begindate   date;
    endDate     date;
    beginPeriod date;
    endPeriod   date;
  begin
    if (EmpId is null) then
      return 0;
    end if;

    if (not gb_calc_is_retro) then
      beginPeriod  := hrm_Date.BeginOfYear;
      endPeriod    := hrm_date.ActivePeriodEndDate;
    else
      endPeriod    := hrm_date.BeginOfYear - 1;   -- 31.12 Last Year
      beginPeriod  := trunc(endPeriod, 'YY');   -- 01.01 Last Year
    end if;

    for tplInOut in gcur_empl_inout(EmpId, endPeriod) loop
      beginDate  := beginPeriod;

      -- if the date out of the employee is greater than begin date or if it si nuul, wich means
      -- that he has not yet leaved then end Date is the last day of the period
      if (   tplInOut.ino_out >= beginDate
          or tplInOut.ino_out is null) then
        -- if employee's starting date is greater than begin of period then begin date
        -- becommes starting date
        if (tplInOut.ino_in > beginDate) then
          beginDate  := tplInOut.ino_in;
        end if;

        -- if employee's end date is smaller than last day of period then end date
        -- becommes employee's end date
        endDate    := endPeriod;

        if (tplInOut.ino_out < endDate) then
          endDate  := tplInOut.ino_out;
        end if;

        -- we add the days between begin and end date into result
        ln_result  := ln_result + hrm_date.days_between(beginDate, endDate);
      end if;
    end loop;

    return least(greatest(ln_result, 0), 360);
  end;

  function AC_Days_SinceBeginOfYearFR(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result   binary_integer := 0;
    begindate   date;
    endDate     date;
    beginPeriod date;
    endPeriod   date;
  begin
    if (EmpId is null) then
      return 0;
    end if;

    if (not gb_calc_is_retro) then
      beginPeriod  := hrm_Date.BeginOfYear;
      endPeriod    := hrm_date.ActivePeriodEndDate;
    else
      endPeriod    := hrm_date.BeginOfYear - 1;   -- 31.12 Last Year
      beginPeriod  := trunc(endPeriod, 'YY');   -- 01.01 Last Year
    end if;

    for tplInOut in gcur_empl_inout(EmpId, endPeriod) loop
      beginDate  := beginPeriod;

      -- if the date out of the employee is greater than begin date or if it si null, wich means
      -- that he has not yet leaved then end Date is the last day of the period
      if (   tplInOut.ino_out >= beginDate
          or tplInOut.ino_out is null) then
        -- if employee's starting date is greater than begin of period then begin date
        -- becommes starting date
        if (tplInOut.ino_in > beginDate) then
          beginDate  := tplInOut.ino_in;
        end if;

        -- if employee's end date is smaller than last day of period then end date
        -- becommes employee's end date
        endDate    := endPeriod;

        if (tplInOut.ino_out < endDate) then
          endDate  := tplInOut.ino_out;
        end if;

        -- we add the days between begin and end date into result
        ln_result  := ln_result + hrm_date.Days_BetweenFR(beginDate, endDate);
      end if;
    end loop;

    return least(greatest(ln_result, 0), 360);
  end;

  function Days_SinceBeginOfYear(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result   binary_integer := 0;
    beginDate   date;
    endDate     date;
    beginPeriod date;
    endPeriod   date;
  begin
    if (EmpId is null) then
      return 0;
    end if;

    if (not gb_calc_is_retro) then
      beginPeriod  := hrm_Date.BeginOfYear;
      endPeriod    := hrm_date.ActivePeriodEndDate;
    else
      endPeriod    := hrm_date.BeginOfYear - 1;   -- 31.12 Last Year
      beginPeriod  := trunc(endPeriod, 'YY');   -- 01.01 Last Year
    end if;

    for tplInOut in gcur_empl_inout(EmpId, endPeriod) loop
      beginDate  := beginPeriod;

      -- if the date out of the employee is greater than begin date or if it si nuul, wich means
      -- that he has not yet leaved then end Date is the last day of the period
      if (   tplInOut.ino_out >= beginDate
          or tplInOut.ino_out is null) then
        -- if employee's starting date is greater than begin of period then begin date
        -- becommes starting date
        if (tplInOut.ino_in > beginDate) then
          beginDate  := tplInOut.ino_in;
        end if;

        -- if employee's end date is smaller than last day of period then end date
        -- becommes employee's end date
        endDate    := endPeriod;

        if (tplInOut.ino_out < endDate) then
          endDate  := tplInOut.ino_out;
        end if;

        -- we add the days between begin and end date into result
        ln_result  := ln_result + endDate - beginDate + 1;
      end if;
    end loop;

    return greatest(ln_result, 0);
  end;

  function BeginOfYear
    return date deterministic
  is
  begin
    return trunc(hrm_date.ActivePeriod, 'YY');
  end;

  function EndOfYear
    return date deterministic
  is
  begin
    return trunc(add_months(hrm_date.ActivePeriod, 12), 'YY') - 1;
  end;

  function ActivePeriod
    return date deterministic
  is
    ld_result date;
    ld_tmp    date;
  begin
    hrm_date.PeriodDates(ld_result, ld_tmp);
    return ld_result;
  end;

  function ActivePeriodEndDate
    return date deterministic
  is
    ld_result date;
    ld_tmp    date;
  begin
    hrm_date.PeriodDates(ld_tmp, ld_result);
    return ld_result;
  end;

  procedure PeriodDates(beginPeriod out nocopy date, endPeriod out nocopy date)
  is
  begin
    if (gd_budget_date is null) then
      open gcur_period;

      fetch gcur_period
       into beginPeriod
          , endPeriod;

      close gcur_period;
    else
      beginPeriod  := trunc(gd_budget_date, 'YY');
      endPeriod    := gd_budget_date;
    end if;
  end;

  function ValidForActivePeriod(dateFrom in date, DateTo in date)
    return integer deterministic
  is
  begin
    return case
      when     (dateFrom <= hrm_date.ActivePeriodEndDate)
           and (dateTo >= hrm_date.ActivePeriod) then 1
      else 0
    end;
  end;

  function ValidForActivePeriod2(givenDate in date)
    return integer deterministic
  is
  begin
    return case
      when(givenDate is null) then 0
      when(givenDate between hrm_date.ActivePeriod and hrm_date.ActivePeriodEndDate) then 1
      else 0
    end;
  end;

  function ValidForNextPeriod(givenDate in date)
    return integer deterministic
  is
    nextPeriod date;
  begin
    nextPeriod  := hrm_date.ActivePeriodEndDate + 1;
    return case
      when(givenDate is null) then 0
      when(givenDate between nextPeriod and last_day(nextPeriod) ) then 1
      else 0
    end;
  end;

  function LastYearOut(Empid in hrm_person.hrm_person_id%type)
    return date
  is
    ld_begin_year date;
    ld_result     date;
  begin
    ld_begin_year  := trunc(add_months(hrm_date.ActivePeriod, -12), 'YY');

    select max(INO_OUT)
      into ld_result
      from (select INO_OUT
                 , trunc(INO_OUT, 'YY') INO_OUT_IN_YEAR
              from HRM_IN_OUT
             where HRM_EMPLOYEE_ID = Empid
               and C_IN_OUT_CATEGORY = '3')
     where INO_OUT_IN_YEAR = ld_begin_year;

    return ld_result;
  exception
    when others then
      return null;
  end;

  function NextInOutInDate(givenDate in date, EmpId in hrm_person.hrm_person_id%type)
    return date
    RESULT_CACHE RELIES_ON (HRM_IN_OUT)
  is
    ld_result date;
  begin
    open gcur_next_inout_in_date(Empid, givenDate);

    fetch gcur_next_inout_in_date
     into ld_result;

    if (gcur_next_inout_in_date%notfound) then
      ld_result  := hrm_date.EndOfYear;
    end if;

    close gcur_next_inout_in_date;

    return ld_result;
  end;

  function HasInOutInActivePeriod(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result integer;
  begin
    select sign(count(*))
      into ln_result
      from HRM_IN_OUT
     where     HRM_EMPLOYEE_ID = EmpId
           and C_IN_OUT_STATUS = 'ACT'
           and INO_IN <= hrm_date.ActivePeriodEndDate
           and (   INO_OUT is null
                or INO_OUT >= hrm_date.ActivePeriod)
           and C_IN_OUT_CATEGORY = '3';
    return ln_result;
  end;

  function IsEmployeePayable(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from HRM_PERSON p
     where HRM_PERSON_ID = EmpId
       and EMP_CALCULATION != 0
       and exists(
             select 1
               from HRM_IN_OUT
              where HRM_EMPLOYEE_ID = P.HRM_PERSON_ID
                and C_IN_OUT_STATUS = 'ACT'
                and INO_IN <= hrm_date.ActivePeriodEndDate
                and (   INO_OUT is null
                     or INO_OUT >= hrm_date.BeginOfYear)
                and C_IN_OUT_CATEGORY = '3');

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end;

  function PensionMonths(EmpId in hrm_person.hrm_person_id%type, vBirthdate in date, vSex in varchar2)
    return integer
  is
    Months      binary_integer := 0;
    b           binary_integer;
    e           binary_integer := 0;
    begindate   date;
    endDate     date;
    pensionDate date;
    startDate   date;
    beginPeriod date;
    endPeriod   date;
    lastPayDate date;
  begin
    if (EmpId is null) then
      return 0;
    end if;

    lastPayDate  := hrm_date.get_LastPayDateAC(Empid);

    if (not gb_calc_is_retro) then
      -- Searches begin and end dates for active Period
      hrm_date.PeriodDates(beginPeriod, endPeriod);
    else
      -- AlreadyDone
      if (trunc(lastPayDate, 'YY') = hrm_date.BeginOfYear) then
        return 0;
      end if;

      -- Dernière periode travaillée
      endPeriod    := hrm_date.LastYearOut(EmpId);
      beginPeriod  := trunc(endPeriod, 'MM');
    end if;

    -- if last pay date of the period is in the same period of the active period
    -- for that employee whe raise an exception and return 0 (zero)
    if (lastPayDate in(beginPeriod, endPeriod) ) then
      return 0;
    end if;

    -- we start calculating
    pensionDate  := hrm_date.PensionDate(vBirthDate, vSex);

    if (pensionDate > endPeriod) then
      return 0;
    end if;

    -- if pensionDate is prior beginning of year we take 1st day of the year as begin date
    -- otherwise we take pension date as begin of year
    startDate    := greatest(pensionDate, hrm_date.BeginOfYear);

    -- if last pay date is greater than pension date we take last pay date as start date
    if (lastPayDate > startDate) then
      startDate  := lastPayDate + 1;
    end if;

    for tplInOut in gcur_empl_inout(EmpId, endPeriod) loop
      beginDate  := startDate;

      -- if the date out of the employee is greater than begin date or if  null, wich means
      -- that he has not yet leaved, end Date will be the last day of the period
      if (   tplInOut.ino_out >= beginDate
          or tplInOut.ino_out is null) then
        -- if employee's starting date is greater than begin of period then begin date
        -- becommes starting date
        if (tplInOut.ino_in > beginDate) then
          beginDate  := tplInOut.ino_in;
        end if;

        -- if employee's end date is smaller than last day of period then end date
        -- becommes employee's end date
        endDate  := endPeriod;

        if (tplInOut.ino_out < endDate) then
          endDate  := tplInOut.ino_out;
        end if;

        b        := to_number(to_char(beginDate, 'MM') );

        -- if last end date is equal to new begin date we add a month
        if (e = b) then
          b  := b + 1;
        end if;

        e        := to_number(to_char(endDate, 'MM') );

        -- we test if end date is superior or equal to calculated begin
        -- orthewise we go to next record
        if (e >= b) then
          -- we add the number of months between begin and end date
          Months  := Months +(e - b) + 1;
        end if;
      end if;
    end loop;

    return Months;
  end;

  function YearPensionMonths(EmpId in hrm_person.hrm_person_id%type, vBirthdate in date, vSex in varchar2)
    return integer
  is
    Months      binary_integer := 0;
    b           binary_integer;
    e           binary_integer := 0;
    begindate   date;
    endDate     date;
    pensionDate date;
    startDate   date;
    beginPeriod date;
    endPeriod   date;
    lastPayDate date;
  begin
    if (EmpId is null) then
      return 0;
    end if;

    lastPayDate  := hrm_date.BeginOfYear;

    if (not gb_calc_is_retro) then
      -- Searches begin and end dates for active Period
      hrm_date.PeriodDates(beginPeriod, endPeriod);
    else
      -- AlreadyDone
      if (trunc(lastPayDate, 'YY') = trunc(add_months(hrm_date.ActivePeriod, -12), 'YY') ) then
        return 0;
      end if;

      -- Dernière periode travaillée
      endPeriod    := hrm_date.LastYearOut(EmpId);
      beginPeriod  := trunc(endPeriod, 'MM');
    end if;

    -- if last pay date of the period is in the same period of the active period
    -- for that employee whe raise an exception and return 0 (zero)
    if (lastPayDate in(beginPeriod, endPeriod) ) then
      return 0;
    end if;

    -- we start calculating
    pensionDate  := hrm_date.PensionDate(vBirthDate, vSex);

    if (pensionDate > endPeriod) then
      return 0;
    end if;

    -- if pensionDate is prior beginning of year we take 1st day of the year as begin date
    -- otherwise we take pension date as begin of year
    startDate    := greatest(pensionDate, hrm_date.BeginOfYear);

    -- if last pay date is greater than pension date we take last pay date as start date
    if (lastPayDate > startDate) then
      startDate  := lastPayDate + 1;
    end if;

    for tplInOut in gcur_empl_inout(EmpId, endPeriod) loop
      beginDate  := startDate;

      -- if the date out of the employee is greater than begin date or if  null, wich means
      -- that he has not yet leaved, end Date will be the last day of the period
      if (   tplInOut.ino_out >= beginDate
          or tplInOut.ino_out is null) then
        -- if employee's starting date is greater than begin of period then begin date
        -- becommes starting date
        if (tplInOut.ino_in > beginDate) then
          beginDate  := tplInOut.ino_in;
        end if;

        -- if employee's end date is smaller than last day of period then end date
        -- becommes employee's end date
        endDate  := endPeriod;

        if (tplInOut.ino_out < endDate) then
          endDate  := tplInOut.ino_out;
        end if;

        b        := to_number(to_char(beginDate, 'MM') );

        -- if last end date is equal to new begin date we add a month
        if (e = b) then
          b  := b + 1;
        end if;

        e        := to_number(to_char(endDate, 'MM') );

        -- we test if end date is superior or equal to calculated begin
        -- orthewise we go to next record
        if (e >= b) then
          -- we add the number of months between begin and end date
          Months  := Months +(e - b) + 1;
        end if;
      end if;
    end loop;

    return Months;
  end;

  function PlanDateToText(vPlanDate in date)
    return varchar2
  is
    nPlanInputType binary_integer;
    ln_month       binary_integer;
  begin
    if (vPlanDate is null) then
      return null;
    end if;

    -- Recherche de la valeur de la config
    nPlanInputType  := to_number(pcs.pc_config.getconfig('HRM_TRAINING_PLAN_INPUT') );
    -- Recherche du texte correspondant à la date
    ln_month        := to_number(to_char(vPlanDate, 'MM') );
    return case nPlanInputType
      when 1 then case trunc( (ln_month - 1) / 6)
                   when 0 then pcs.pc_public.TranslateWord('Janv. - Juin')
                   when 1 then pcs.pc_public.TranslateWord('Juil. - Déc.')
                 end
      when 2 then case trunc( (ln_month - 1) / 3)
                   when 0 then pcs.pc_public.TranslateWord('Janv. - Mars')
                   when 1 then pcs.pc_public.TranslateWord('Avril - Juin')
                   when 2 then pcs.pc_public.TranslateWord('Juil. - Sept.')
                   when 3 then pcs.pc_public.TranslateWord('Oct. - Déc.')
                 end
      when 3 then case ln_month
                   when 1 then pcs.pc_public.TranslateWord('Janvier')
                   when 2 then pcs.pc_public.TranslateWord('Février')
                   when 3 then pcs.pc_public.TranslateWord('Mars')
                   when 4 then pcs.pc_public.TranslateWord('Avril')
                   when 5 then pcs.pc_public.TranslateWord('Mai')
                   when 6 then pcs.pc_public.TranslateWord('Juin')
                   when 7 then pcs.pc_public.TranslateWord('Juillet')
                   when 8 then pcs.pc_public.TranslateWord('Août')
                   when 9 then pcs.pc_public.TranslateWord('Septembre')
                   when 10 then pcs.pc_public.TranslateWord('Octobre')
                   when 11 then pcs.pc_public.TranslateWord('Novembre')
                   when 12 then pcs.pc_public.TranslateWord('Décembre')
                 end
    end;
  end;

  function ValidForSession(vPlanDate in date, vSessionDate in date)
    return integer
  is
    nPlanInputType binary_integer;
    ln_first_month binary_integer;
    ln_last_month  binary_integer;
  begin
    if (   vPlanDate is null
        or vSessionDate is null) then
      return 0;
    end if;

    -- Vérification que les années correspondent
    if (trunc(vPlanDate, 'YY') != trunc(vSessionDate, 'YY') ) then
      return 0;
    end if;

    -- Recherche de la valeur de la config
    nPlanInputType  := to_number(pcs.pc_config.GetConfig('HRM_TRAINING_PLAN_INPUT') );
    -- Calcul le 1er et le dernier mois de la période de planification
    ln_first_month  := to_number(to_char(vPlanDate, 'MM') );

    case nPlanInputType
      when 1 then
        -- 1..6 => 1; 7..12 => 7
        ln_first_month  := trunc( (ln_first_month - 1) / 6) * 6 + 1;
        ln_last_month   := ln_first_month + 5;
      when 2 then
        -- 1..3 => 1; 4..6 => 4; 7..9 => 7; 10..12 => 10
        ln_first_month  := trunc( (ln_first_month - 1) / 3) * 3 + 1;
        ln_last_month   := ln_first_month + 2;
      when 3 then
        -- ln_first_month is correct
        ln_last_month  := ln_first_month;
      else
        ln_first_month  := 1;
        ln_last_month   := 12;
    end case;

    -- Vérifie que la session corresponde à la date de planfication
    return case
      when(to_number(to_char(vSessionDate, 'MM') ) between ln_first_month and ln_last_month) then 1
      else 0
    end;
  end;

  function PensionAge(vBirthdate in date, vSex in varchar2)
    return integer
  is
    ln_year binary_integer;
  begin
    if    (vSex is null)
       or (upper(vSex) not in('F', 'M') ) then
      raise_application_error(-20110, 'Code sexe incorrect ("F","M")');
      return 0;
    end if;

    if (upper(vSex) = 'F') then
      -- Calcul de l'âge de la retraite pour les femmes
      ln_year  := to_number(to_char(vBirthDate, 'YYYY') );
      return case
        when(ln_year <= 1938) then 62
        when(ln_year between 1939 and 1941) then 63
        else 64   -- >= 1942
      end;
    end if;

    -- Age de la retraite pour les hommes
    return 65;
  exception
    when others then
      raise_application_error(-20112, 'Erreur de calcul de l''âge de la retraite');
      return 0;
  end;

  function PensionDate(vBirthdate in date, vSex in varchar2)
    return date
  is
  begin
    return last_day(add_months(vBirthDate, hrm_date.PensionAge(vBirthDate, vSex) * 12) ) + 1;
  exception
    when others then
      raise_application_error(-20114, 'Erreur de calcul de l''âge de la retraite');
      return null;
  end;

/**
* Date de fin de la période d'assujettissement effective
*/
  function p_nextintaxdate(id_givenDate in date, in_employee_id in hrm_person.hrm_person_id%type)
    return date deterministic
  is
    ld_nexttax date;

    cursor lcur_next_inout_in_date
    is
      select   emt_from - 1
          from hrm_employee_taxsource
         where hrm_person_id = in_employee_id
           and emt_from > id_givenDate
      order by emt_from asc;
  begin
    open lcur_next_inout_in_date;

    fetch lcur_next_inout_in_date
     into ld_nexttax;

    if (lcur_next_inout_in_date%notfound) then
      ld_nexttax  := hrm_date.EndOfYear;
    end if;

    close lcur_next_inout_in_date;

    return ld_nexttax;
  end p_nextintaxdate;

  function EndEmpTaxDate(id_from in date, id_to in date, in_employee_id in hrm_person.hrm_person_id%type)
    return date deterministic
  is
    ld_result date;
    lv_out    hrm_employee_taxsource.c_hrm_tax_out%type;
  begin
   /* Recherche du type de sortie lié à la période d'assujettissement pour déterminer le traitement des décomptes post-sortie */
    select max(c_hrm_tax_out)
      into lv_out
      from hrm_employee_taxsource
     where hrm_person_id = in_employee_id
       and (   emt_from between id_from and nvl(id_to, hrm_elm.endofperiod)
            or nvl(emt_to, hrm_elm.endofperiod) between id_from and nvl(id_to, hrm_elm.endofperiod)
           );

    return hrm_taxsource.reference_period_end(in_employee_id, id_from, id_to, lv_out);
  end EndEmpTaxDate;
end HRM_DATE;
