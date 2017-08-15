--------------------------------------------------------
--  DDL for Package Body DOC_DELAY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DELAY_FUNCTIONS" 
is
  gcDOC_DELAY_WEEKSTART  constant varchar2(2) := to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') );
  gcPAC_USE_PAC_SCHEDULE constant varchar2(2) := nvl(PCS.PC_CONFIG.GetConfig('PAC_USE_PAC_SCHEDULE'), '0');

  /**
  * Description
  *    Renvoi un varchar2 avec un format de date sp�cial
  */
  function GetFormatedDate(aDate date, aType DOC_GAUGE_POSITION.C_GAUGE_SHOW_DELAY%type)
    return varchar2
  is
    Result_Varchar2 varchar2(12);
  begin
    if aType = 2 then   -- Date en semaines
      Result_Varchar2  := DateToWeek(aDate);
    elsif aType = 3 then   -- Date en mois
      select to_char(aDate, 'MM.YYYY')
        into Result_Varchar2
        from dual;
    else
      select to_char(aDate, 'DD.MM.YYYY')
        into Result_Varchar2
        from dual;
    end if;

    return Result_Varchar2;
  end GetFormatedDate;

  /**
  * Description
  *   Converti une date en format semaine YYYY.WW
  */
  function DateToWeek(aDate date)
    return varchar2
  is
    Result_Varchar2 varchar2(12);
    nYear           number;
    nWeek           number;
  begin
    if aDate is not null then
      DateToWeekNumber(aDate, gcDOC_DELAY_WEEKSTART, nYear, nWeek);

      select to_char(nYear) || '.' || lpad(to_char(nWeek), 2, '0')
        into Result_Varchar2
        from dual;

      return Result_Varchar2;
    else
      return null;
    end if;
  end DateToWeek;

  /**
  * Description
  *   Renvoi une date en fonction de la semaine X
  */
  function WeekToDate(aWeek varchar2, aDay number)
    return date
  is
    Result_Date date;
    nWeek       number;
    nYear       number;
    nDay        number;
  begin
    -- Recherche la config qui indique quel est le 1er jour de la semaine
    select to_number(substr(aWeek, 1, 4) ) THE_YEAR
         , to_number(substr(aWeek, 6, 2) ) THE_WEEK
      into nYear
         , nWeek
      from dual;

    nDay         := 8 + aDay - gcDOC_DELAY_WEEKSTART;

    if nDay > 7 then
      nDay  := nDay - 7;
    end if;

    Result_Date  := WeekNumberToDate(nYear, nWeek, nDay, gcDOC_DELAY_WEEKSTART);
    return Result_Date;
  end WeekToDate;

  /**
  * Description
  *   Cette fonction retourne un n� de semaine en fonction d'une date et du num�ro
  *   du jour correspondant au premier jour de la semaine 1=dimanche ... 7 = samedi
  */
  procedure DateToWeekNumber(aDate date, aWeekStart number, outYear out number, outWeek out number)
  is
    nDays           number;
    nFirstDayOfYear number;
    nDay            number;
    nMonth          number;
    nYear           number;
    nLastDay        number;
    nTest           number;
  begin
    -- Decode en Jours, Mois et ann�es la date re�ue en param�tre
    select substr(to_char(aDate, 'DD.MM.YYYY'), 1, 2) THE_DAY
         , substr(to_char(aDate, 'DD.MM.YYYY'), 4, 2) THE_MONTH
         , substr(to_char(aDate, 'DD.MM.YYYY'), 7, 4) THE_YEAR
      into nDay
         , nMonth
         , nYear
      from dual;

    outYear          := nYear;
    -- Calcul du N� du jour de l'ann�e (1-365 / 1-366 (bisextile) )
    nDays            := to_number(to_char(aDate, 'DDD') );
    -- Calcul du n� du jour du premier janvier relativement �
    -- la semaine d�fini par WeekStart (1=dimanche .. 7=samedi)
    nFirstDayofYear  := GetYearFirstDayNumber(outYear, aWeekStart);

    if (nFirstDayofYear <= 4) then
      /* Si le premier janvier fait parti des 4 premier jours de la semaine
          on ajoute au N� du jour de l'ann�e (iDays) les jours de la semaine
          qui appartiennent � l'ann�e pr�c�dente */
      nDays  := nDays +(nFirstDayofYear - 1);
    else
      /* Si le premier janvier correspond au 5,6 ou 7 �me jour de la semaine
          ces jours font partie de la derni�re semaine de l'ann�e pr�c�dente
          et sont soustrait au n� du jour de l'ann�e (iDays) */
      nDays  := nDays -(8 - nFirstDayofYear);
    end if;

    if nDays <= 0 then
      /* le param�tre aDate correspond au d�but du mois de janvier et fait
          partie de la derni�re semaine de l'ann�e pr�c�dente (voir soustraction ci-dessus) */
      DateToWeekNumber(EncodeDate(31, 12, nYear - 1), aWeekStart, outYear, outWeek);
    else
      -- On divise le nombre de jour iDays par 7 -> nombre de semaine
      outWeek  := trunc(nDays / 7);
      -- Si le modulo est sup�rieur � 0, on ajoute 1 au nombre de semaine aWeek}
      nTest    := mod(nDays, 7);

      if nTest > 0 then
        outWeek  := outWeek + 1;
      end if;

      /* Si le nombre de semaine = 53, on contr�le que le semaine
          ne correspond pas effectivement � la premi�re semaine de l'ann�e suivante
          en fonction du N� du jour relatif au 31 d�cembre */
      if (outWeek = 53) then
        -- Dernier jour de l'ann�e -> premier jour de l'ann�e suivante moins 1
        nLastDay  := GetYearFirstDayNumber(outYear + 1, aWeekStart) - 1;

        if     (nLastDay < 4)
           and (nLastDay > 0) then
          outWeek  := 1;
          outYear  := nYear + 1;
        end if;
      end if;
    end if;
  end DateToWeekNumber;

  /**
  * function DateToWeekNumber
  * Description
  *    Cette fonction retourne un n� de semaine en fonction d'une date et du num�ro
  *    du jour correspondant au premier jour de la semaine 1=dimanche ... 7 = samedi
  */
  function DateToWeekNumber(aDate date, aWeekStart number)
    return varchar2
  is
    vYear number(4);
    vWeek number(2);
  begin
    DateToWeekNumber(aDate, aWeekStart, vYear, vWeek);
    return vYear || '.' || lpad(to_char(vWeek), 2, '0');
  end DateToWeekNumber;

  /**
  * Description
  *    Retourne le num�ro de la semaine standard PCS de la date transmise en param�tre.
  *    Tiens compte du premier jour de la semaine d�fini dans la configuration
  *    DOC_DELAY_WEEKSTART.
   */
  function getWeekNumberFromDate(iDate in date)
    return number
  as
    lnWeekNumber number;
    lnYearNumber number;
  begin
    /* R�cup�ration du num�ro de la semaine */
    DateToWeekNumber(aDate => iDate, aWeekStart => gcDOC_DELAY_WEEKSTART, outYear => lnYearNumber, outWeek => lnWeekNumber);
    return lnWeekNumber;
  end getWeekNumberFromDate;

  /**
  * Description
  *    Converti une semaine (2001.16) en format date sur un jour d�fini par la var aDay
  */
  function WeekNumberToDate(aYear number, aWeek number, aDay number, aWeekStart number)
    return date
  is
    nFirstDayofYear        number;
    datFirstDayOfFirstWeek date;
    datFirstDayOfWeek      date;
    Result_Date            date;
  begin
    -- Calcul du n� du jour du premier janvier relativement �
    -- la semaine d�fini par WeekStart (1=dimanche .. 7=samedi)
    nFirstDayofYear    := GetYearFirstDayNumber(aYear, aWeekStart);

    if (nFirstDayofYear <= 4) then
      /* Si le premier janvier fait parti des 4 premier jours de la semaine
          on soustrait au premier janvier les jours de la semaine
          qui appartiennent � l'ann�e pr�c�dente pour obtenir la date du premier
          jour de la premiere semaine de l'ann�e */
      datFirstDayOfFirstWeek  := EncodeDate(01, 01, aYear) +( (nFirstDayofYear - 1) * -1);
    else
      /* Si le premier janvier correspond au 5,6 ou 7 �me jour de la semaine
          ces jours font partie de la derni�re semaine de l'ann�e pr�c�dente
          et sont ajout� au premier janvier pour obtenir la date du premier jour
          de la premi�re semaine de l'ann�e */
      datFirstDayOfFirstWeek  := EncodeDate(01, 01, aYear) +(8 - nFirstDayofYear);
    end if;

    -- Calcul de la date du premier jour de la semaine aWeek, on soustrait 1 de aWeek,
    -- la date du premier jour de la semaine 1 correspond � la valeur de dFirstdayofFirstWeek
    datFirstDayOfWeek  := datFirstDayOfFirstWeek +(7 *(aWeek - 1) );
    -- Calcul de la date qui correspond au num�ro du jour de la semaine aDay}
    Result_Date        := datFirstDayOfWeek +(aDay - 1);
    return Result_Date;
  end WeekNumberToDate;

  /**
  * function WeekNumberToDate
  * Description
  *    Converti une semaine (2001.16) en format date sur un jour d�fini par la var aDay
  */
  function WeekNumberToDate(aWeek varchar2, aDay number, aWeekStart number)
    return date
  is
    vWeek number(2);
    vYear number(4);
  begin
    if aWeek is not null then
      vYear  := substr(aWeek, 1, 4);
      vWeek  := substr(aWeek, 6, 2);
      return WeekNumberToDate(vYear, vWeek, aDay, aWeekStart);
    else
      return null;
    end if;
  exception
    when others then
      return null;
  end WeekNumberToDate;

  /*
  * Description
  *    Recherche du n� du jour du 1er janvier relatif au d�but de semaine d�fini par WeekStart
  *    si WeekStart = 2 (Lundi) et que le premier janvier est un mardi, alors la fonction retourne 2
  *    si WeekStart = 6 (vendredi) et que le premier janvier est un mardi alors la fonction retourne 5
  */
  function GetYearFirstDayNumber(aYear number, aWeekStart number)
    return number
  is
    nBase         number;
    Result_Number number;
  begin
    /*Recherche N� du premier jour de l'ann�e le calcul se base sur une semaine
      qui commence le dimanche  DIMANCHE = 1 ... SAMEDI = 7 */
    select decode(rtrim(to_char(to_date('01.01.' || to_char(aYear), 'DD.MM.YYYY'), 'DAY', 'NLS_DATE_LANGUAGE = AMERICAN') )
                , 'SUNDAY', 1
                , 'MONDAY', 2
                , 'TUESDAY', 3
                , 'WEDNESDAY', 4
                , 'THURSDAY', 5
                , 'FRIDAY', 6
                , 'SATURDAY', 7
                 )
      into nBase
      from dual;

    -- Recherche le n� du jour en tenant compte de WeekStart
    Result_Number  := 8 +(nBase - aWeekStart);

    if Result_Number > 7 then
      Result_Number  := Result_Number - 7;
    end if;

    return Result_Number;
  end GetYearFirstDayNumber;

  /**
  * Description
  *    Concatene les variables jour, mois et ann�e pour obtenir une date
  */
  function EncodeDate(aDay number, aMonth number, aYear number)
    return date
  is
    Result_Date date;
  begin
    select to_date(to_char(aDay) || '.' || to_char(aMonth) || '.' || to_char(aYear), 'DD.MM.YYYY')
      into Result_Date
      from dual;

    return Result_Date;
  end EncodeDate;

  /**
  * Indique si la date pass�e est un jour ouvrable selon les calendriers
  */
  function IsOpenDay(aDate date, aThirdID PAC_THIRD.PAC_THIRD_ID%type, aAdminDomain number default 1)
    return number
  is
    vThirdScheduleID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vFilter          varchar(30);
    vFilterID        PAC_THIRD.PAC_THIRD_ID%type;
  begin
    if gcPAC_USE_PAC_SCHEDULE = '1' then
      PAC_I_LIB_SCHEDULE.GetLogisticThirdSchedule(iThirdID       => aThirdID
                                                , iAdminDomain   => aAdminDomain
                                                , oScheduleID    => vThirdScheduleID
                                                , oFilter        => vFilter
                                                , oFilterID      => vFilterID
                                                 );
      return PAC_I_LIB_SCHEDULE.IsOpenDay(iScheduleID => vThirdScheduleID, iDate => aDate, iFilter => vFilter, iFilterID => vFilterID);
    else
      return PAC_CALENDAR_FUNCTIONS.IsOpenDay(aDate, aThirdId, aAdminDomain);
    end if;
  end IsOpenDay;

  /**
  * Converti une date en format mois PCS -> 2002.06
  */
  function DateToMonth(aDate date)
    return varchar2
  is
    month varchar2(7);
  begin
    month  := to_char(aDate, 'YYYY') || '.' || to_char(aDate, 'MM');
    return month;
  end DateToMonth;

  /**
  * Retrouve une date depuis un format mois PCS
  */
  function MonthToDate(
    aMonthDate          varchar2
  , aPosDelay           number
  , aThirdID            PAC_THIRD.PAC_THIRD_ID%type default null
  , aAdminDomain        number default 1
  , SearchThirdCalendar number default 1
  , aCheckOpenDay       number default 1
  )
    return date
  is
    nMonth        number;
    nYear         number;
    nLastDayMonth number;
    aDateTmp      date;
    ResultDate    date;
  begin
    -- Retrouve le mois de la date mois pass�e en param
    nMonth         := to_number(substr(aMonthDate, 6, 2) );
    nYear          := to_number(substr(aMonthDate, 1, 4) );
    nLastDayMonth  := to_number(to_char(last_day(to_date('01' || '.' || to_char(nMonth) || '.' || to_char(nYear), 'DD.MM.YYYY') ), 'DD') );

    if nLastDayMonth < aPosDelay then
      ResultDate  := to_date(to_char(nLastDayMonth) || '.' || to_char(nMonth) || '.' || to_char(nYear), 'DD.MM.YYYY');
    else
      ResultDate  := to_date(to_char(aPosDelay) || '.' || to_char(nMonth) || '.' || to_char(nYear), 'DD.MM.YYYY');
    end if;

    -- V�rifie que le jour soit ouvrable selon le calendrier du fournisseur
    if     (aCheckOpenDay = 1)
       and (IsOpenDay(ResultDate, aThirdID, aAdminDomain) = 0) then
      -- Recherche le prochain jour ouvrable en avant
      ResultDate  :=
        GetShiftOpenDate(aDate                  => ResultDate
                       , aCalcDays              => 0
                       , aAdminDomain           => aAdminDomain
                       , aThirdID               => aThirdID
                       , aForward               => 1
                       , aSearchThirdCalendar   => SearchThirdCalendar
                        );

      -- V�rifie que la date qui a �t� trouv�e ce trouve dans le m�me mois
      if nMonth <> to_number(to_char(ResultDate, 'MM') ) then
        -- Recherche le pr�c�dent jour ouvrable
        ResultDate  :=
          GetShiftOpenDate(aDate                  => ResultDate
                         , aCalcDays              => 1
                         , aAdminDomain           => aAdminDomain
                         , aThirdID               => aThirdID
                         , aForward               => 0
                         , aSearchThirdCalendar   => SearchThirdCalendar
                          );
      end if;
    end if;

    return ResultDate;
  end MonthToDate;

  /**
  * Description : Donne le nombre de jours ouvrables entre deux dates
  *               en fonction du calendrier du tiers ou calendrier par d�faut selon le cas
  */
  function OpenDaysBetween(
    aFromDate            date
  , aToDate              date
  , aAdminDomain         number
  , aThirdID             PAC_THIRD.PAC_THIRD_ID%type
  , aSearchThirdCalendar number default 1
  , aCalendarTypeId      number default null
  )
    return number
  is
    vScheduleID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vFilter     varchar(30);
    vFilterID   PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    -- Nouvelle Gestion des calendriers (PAC_SCHEDULE)
    if gcPAC_USE_PAC_SCHEDULE = '1' then
      -- Calendrier du tiers
      if aSearchThirdCalendar = 1 then
        PAC_I_LIB_SCHEDULE.GetLogisticThirdSchedule(iThirdID       => aThirdID
                                                  , iAdminDomain   => aAdminDomain
                                                  , oScheduleID    => vScheduleID
                                                  , oFilter        => vFilter
                                                  , oFilterID      => vFilterID
                                                   );
      end if;

      -- Calcul de la date
      return PAC_I_LIB_SCHEDULE.GetOpenDaysBetween(iScheduleID   => vScheduleID
                                                 , iDateFrom     => aFromDate
                                                 , iDateTo       => aToDate
                                                 , iFilter       => vFilter
                                                 , iFilterID     => vFilterID
                                                  );
    else
      return PAC_CALENDAR_FUNCTIONS.OpenDaysBetween(aFromDate, aToDate, aAdminDomain, aThirdId, aSearchThirdCalendar, aCalendarTypeId);
    end if;
  end OpenDaysBetween;

  /**
  * function GetShiftOpenDate
  * Description
  *    Incr�mente ou d�cremente une date avec un d�calage donn�
  *    en fonction des jours ouvrables de l'horaire demand� selon la config
  *    PAC_USE_PAC_SCHEDULE qui a �t� cr�e pour le passage des anciens
  *    calendriers (PAC_CALENDAR) au nouveaux (PAC_SCHEDULE)
  */
  function GetShiftOpenDate(
    aDate                in date
  , aCalcDays            in integer default 1
  , aCfgUsePacSchedule   in varchar2 default null
  , aAdminDomain         in DOC_GAUGE.C_ADMIN_DOMAIN%type default null
  , aThirdID             in PAC_THIRD.PAC_THIRD_ID%type default null
  , aForward             in integer default 1
  , aSearchThirdCalendar in integer default 1
  , aScheduleID          in PAC_SCHEDULE.PAC_SCHEDULE_ID%type default null
  , aScheduleFilter      in varchar default null
  , aScheduleFilterID    in PAC_THIRD.PAC_THIRD_ID%type default null
  )
    return date
  is
    vScheduleID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vFilter     varchar(30);
    vFilterID   PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    -- Nouvelle Gestion des calendriers (PAC_SCHEDULE)
    if nvl(aCfgUsePacSchedule, gcPAC_USE_PAC_SCHEDULE) = '1' then
      vScheduleID  := aScheduleID;
      vFilter      := aScheduleFilter;
      vFilterID    := aScheduleFilterID;

      -- Si demand� l'utilisation du calendrier du tiers et que celui-ci
      -- n'est pas renseign�, effectuer la recherche
      if     (aSearchThirdCalendar = 1)
         and (aScheduleID is null) then
        -- Calendrier du tiers
        PAC_I_LIB_SCHEDULE.GetLogisticThirdSchedule(iThirdID       => aThirdID
                                                  , iAdminDomain   => aAdminDomain
                                                  , oScheduleID    => vScheduleID
                                                  , oFilter        => vFilter
                                                  , oFilterID      => vFilterID
                                                   );
      end if;

      -- Calcul de la date
      return PAC_I_LIB_SCHEDULE.GetShiftOpenDate(iScheduleID   => vScheduleID
                                               , iDateFrom     => aDate
                                               , iCalcDays     => aCalcDays
                                               , iForward      => aForward
                                               , iFilter       => vFilter
                                               , iFilterID     => vFilterID
                                                );
    else
      -- Ancienne Gestion des calendriers (PAC_CALENDAR)
      return PAC_CALENDAR_FUNCTIONS.DecalageDate(aFromDate              => aDate
                                               , aDecalage              => aCalcDays
                                               , aAdminDomain           => aAdminDomain
                                               , aThirdID               => aThirdId
                                               , aForward               => aForward
                                               , aSearchThirdCalendar   => aSearchThirdCalendar
                                                );
    end if;
  end GetShiftOpenDate;
end DOC_DELAY_FUNCTIONS;
