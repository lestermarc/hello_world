--------------------------------------------------------
--  DDL for Package Body STM_LIB_EXERCISE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_LIB_EXERCISE" 
is

  /**
  * Description :
  *      retourne l'id de l'exercice actif
  */
  function GetActiveExercise
    return STM_EXERCISE.STM_EXERCISE_ID%type
  is
    lResult STM_EXERCISE.STM_EXERCISE_ID%type;
  begin
    select STM_EXERCISE_ID
      into lResult
      from STM_EXERCISE
     where C_EXERCISE_STATUS = '02';

    return lResult;
  exception
    when no_data_found then
      raise_application_error(-20000, 'PCS -  No active stock exercise!');
    when too_many_rows then
      raise_application_error(-20000, 'PCS -  More than one active stock exercise!');
  end getActiveExercise;

  /**
  * Description
  *   retourne l'id de l'exercice actif
  */
  function GetExerciseId(iDate in date, iIgnoreStatus in number default 0)
    return STM_EXERCISE.STM_EXERCISE_ID%type
  is
    lResult STM_EXERCISE.STM_EXERCISE_ID%type;
  begin
    select STM_EXERCISE_ID
      into lResult
      from STM_EXERCISE
     where (C_EXERCISE_STATUS in ('02','03') or EXE_OPENING = 1 or iIgnoreStatus = 1)
       and trunc(iDate) between trunc(EXE_STARTING_EXERCISE) and trunc(EXE_ENDING_EXERCISE);

    return lResult;
  exception
    when no_data_found then
      return GetActiveExercise;
    when too_many_rows then
      ra('PCS -  Ingegrity violated with exercises dates');
  end GetExerciseId;

  /**
  * Description
  *   retourne l'id de la période correspondant à la date donnée
  */
  function GetPeriodId(iDate in date)
    return STM_PERIOD.STM_PERIOD_ID%type
  is
    lResult STM_PERIOD.STM_PERIOD_ID%type;
  begin
    select STM_PERIOD_ID
      into lResult
      from STM_PERIOD
     where trunc(iDate) between trunc(PER_STARTING_PERIOD) and trunc(PER_ENDING_PERIOD);
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end GetPeriodId;


  /**
  * Description
  *   Give a date in active periode, if possible the given date if it in the active period.
  *   If the given date is earlier than the active period date then return the start
  *   date of the period. If the given date is greater return the ending date.
  */
  function GetActiveDate(iDate in date)
    return date
  is
    lResult   date;
    lPerFrom  date;
    lPerTo    date;
  begin
    begin
      -- if date is in the active period, return it
      select iDate
        into lResult
        from STM_PERIOD PER
       where iDate between PER.PER_STARTING_PERIOD and PER.PER_ENDING_PERIOD
         and PER.C_PERIOD_STATUS = '02';
    exception
      when no_data_found then
        begin
          -- test si l'exercice est en cours d'ouverture
          -- dans ce cas là, on autorise la date
          select iDate
            into lResult
            from STM_EXERCISE
           where iDate between EXE_STARTING_EXERCISE and EXE_ENDING_EXERCISE
             and EXE_OPENING = 1;
          exception
            when no_data_found then
              begin

              -- recherche les dates min et max des périodes actives
              select min(PER_STARTING_PERIOD)
                   , max(PER_ENDING_PERIOD)
                into lPerFrom
                   , lPerTo
                from STM_PERIOD
               where STM_PERIOD.STM_EXERCISE_ID = getActiveExercise
                 and C_PERIOD_STATUS = '02';

              -- si la date est plu petite que la date de la plus petite période active, alors on force
              -- à la date de début de la plus petite période, sinon date de fin de la plus grande période
              if lPerFrom is null then
                lResult  := null;
              elsif iDate < lPerFrom then
                lResult  := lPerFrom;
              else
                lResult  := lPerTo;
              end if;
            exception
              -- si pas d'exercice actif on retourne null
              when no_data_found then
                lResult  := null;
            end;
        end;
    end;

    return lResult;
  end GetActiveDate;

end STM_LIB_EXERCISE;
