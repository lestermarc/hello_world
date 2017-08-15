--------------------------------------------------------
--  DDL for Package Body PAC_CALENDAR_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_CALENDAR_FUNCTIONS" 
is
  /**
  * Description
  *    recherche du calendrier par défaut
  */
  function findDefaultCalendar
    return PAC_CALENDAR_TYPE.PAC_CALENDAR_TYPE_ID%type
  is
    CalendarID PAC_CALENDAR_TYPE.PAC_CALENDAR_TYPE_ID%type;
  begin
    select PAC_CALENDAR_TYPE_ID
      into CalendarId
      from PAC_CALENDAR_TYPE
     where CAL_DEFAULT = 1;

    return CalendarId;
  exception
    when no_data_found then
      raise_application_error(-20900, PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de calendrier par défaut!') );
    when too_many_rows then
      raise_application_error(-20900, PCS.PC_FUNCTIONS.TranslateWord('Plusieurs calendriers par défaut sont définis!') );
  end findDefaultCalendar;

  /**
  * Description
  *    recherche du calendrier orientée logistique
  */
  function findLogisticCalendar(aThirdID PAC_THIRD.PAC_THIRD_ID%type, aAdminDomain number default 1)
    return PAC_CALENDAR_TYPE.PAC_CALENDAR_TYPE_ID%type
  is
    -- Sélection du calendrier du fournisseur
    cursor crSupplierCalendar(cSupplierID PAC_THIRD.PAC_THIRD_ID%type)
    is
      select max(PAC_CALENDAR_TYPE_ID) PAC_CALENDAR_TYPE_ID
        from PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER_ID = cSupplierID;

    -- Sélection du calendrier du client
    cursor crCustomerCalendar(cCustomerID PAC_THIRD.PAC_THIRD_ID%type)
    is
      select max(PAC_CALENDAR_TYPE_ID) PAC_CALENDAR_TYPE_ID
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = cCustomerID;

    CalendarID PAC_CALENDAR_TYPE.PAC_CALENDAR_TYPE_ID%type;
  begin
    if aAdminDomain in(1, 5) then   -- Domaine Achat,Fabrication -> Recherche du calendrier du Fournisseur
      -- Recherche de l'ID du calendrier du fournisseur
      open crSupplierCalendar(aThirdID);

      fetch crSupplierCalendar
       into CalendarID;

      close crSupplierCalendar;
    elsif aAdminDomain = 2 then   -- Domaine Vente -> Recherche du calendrier du Client
      -- Recherche de l'ID du calendrier du client
      open crCustomerCalendar(aThirdID);

      fetch crCustomerCalendar
       into CalendarID;

      close crCustomerCalendar;
    else   -- Autre Domaine -> Recherche du calendrier du Client et ensuite Fournisseur si pas trouvé
      -- Recherche de l'ID du calendrier du client
      open crCustomerCalendar(aThirdID);

      fetch crCustomerCalendar
       into CalendarID;

      close crCustomerCalendar;

      -- Recherche le calendrier du founisseur si pas trouvé pour le client
      if CalendarID is null then
        -- Recherche de l'ID du calendrier du fournisseur
        open crSupplierCalendar(aThirdID);

        fetch crSupplierCalendar
         into CalendarID;

        close crSupplierCalendar;
      end if;
    end if;

    -- Recherche de l'ID du calendrier par défaut si pas trouvé au niveau du tiers
    if CalendarID is null then
      CalendarID  := FindDefaultCalendar;
    end if;

    return CalendarID;
  end findLogisticCalendar;

  /**
  * Indique si la date passée est un jour ouvrable selon les calendriers
  */
  function IsOpenDay(aDate date, aThirdID PAC_THIRD.PAC_THIRD_ID%type, aAdminDomain number default 1)
    return number
  is
    CalendarID PAC_CALENDAR_TYPE.PAC_CALENDAR_TYPE_ID%type;
    OpenDay    number;
  begin
    CalendarID  := findLogisticCalendar(aThirdId, aAdminDomain);

    -- SQL indiquant si c'est un jour ouvrable
    select nvl(max(PCD.CAL_OPENDAY), 0)
      into OpenDay
      from PAC_CALENDAR_DAYS PCD
         , PAC_CALENDAR PC
     where PCD.PAC_CALENDAR_ID = PC.PAC_CALENDAR_ID
       and PC.PAC_CALENDAR_TYPE_ID = CalendarID
       and PCD.CAL_DATE = trunc(aDate);

    return OpenDay;
  end IsOpenDay;

  /**
  * Description : Incrémente ou décremente une date avec un décalage donné
  *               en fonction du calendrier du tiers ou calendrier par défaut selon le cas
  */
  function DecalageDate(
    aFromDate            date
  , aDecalage            number
  , aAdminDomain         number
  , aThirdID             PAC_THIRD.PAC_THIRD_ID%type
  , aForward             number
  , aSearchThirdCalendar number default 1
  , aCalendarTypeId      number default null
  )
    return date
  is
    result     date;
    CalendarID PAC_CALENDAR.PAC_CALENDAR_ID%type;
    dayNumber  PAC_CALENDAR_DAYS.CAL_DAY_NUMBER%type;
    decalage   number(12);
  begin
    result      := aFromDate;
    CalendarID  := null;

    -- NGV - 30.03.2005 Effectuer le traiment même s'il n'y a pas de décalage, pour tenir compte des jours ouvrables
    if aCalendarTypeId is null then
      -- Recherche du calendrier du tiers
      if aSearchThirdCalendar = 1 then
        CalendarId  := findLogisticCalendar(aThirdId, aAdminDomain);
      else   -- Calendrier par défaut
        CalendarId  := findDefaultCalendar;
      end if;
    else
      CalendarId  := aCalendarTypeId;
    end if;

    -- Effectuer le décalage que si l'on a un calendrier
    if (CalendarID is not null) then
      select nvl(aDecalage, 0) * decode(aForward, 1, 1, 0, -1)
        into decalage
        from dual;

      result  := DecalageDate(aFromDate, decalage, CalendarId, aForward);
    end if;

    return result;
  end DecalageDate;

  /**
  * Description : Incrémente ou décremente une date avec un décalage donné
  *               en fonction du calendrier du tiers ou calendrier par défaut selon le cas
  */
  function DecalageDate(aFromDate date, aDecalage number, aCalendarTypeId number, aForward number default 1)
    return date
  is
    result    date;
    dayNumber PAC_CALENDAR_DAYS.CAL_DAY_NUMBER%type;
  begin
    -- Cas spécial Si recherche de date en arrière et que le décalage est à zéro
    if     (aDecalage = 0)
       and (aForward = 0) then
      -- EX : jour passé en param 30.01.2005 (Dimanche)
      -- Numérotation des jours :
      --   302  -  27.01.2005  (Jeudi)
      --   303  -  28.01.2005  (Vendredi)
      --   303  -  29.01.2005  (Samedi)
      --   303  -  30.01.2005  (Dimanche)
      --   304  -  31.01.2005  (Lundi)
      -- La date à renvoyer c'est : 28.01.2005
      -- recherche du numéro du jour de référence
      select CAL_DAY_NUMBER
        into dayNumber
        from PAC_CALENDAR_DAYS A1
           , PAC_CALENDAR B1
       where A1.PAC_CALENDAR_ID = B1.PAC_CALENDAR_ID
         and B1.PAC_CALENDAR_TYPE_ID = aCalendarTypeId
         and A1.CAL_DATE = trunc(aFromDate);
    else
      -- recherche du numéro du jour de référence
      select CAL_DAY_NUMBER + decode(CAL_OPENDAY, 0, 1, 0)
        into dayNumber
        from PAC_CALENDAR_DAYS A1
           , PAC_CALENDAR B1
       where A1.PAC_CALENDAR_ID = B1.PAC_CALENDAR_ID
         and B1.PAC_CALENDAR_TYPE_ID = aCalendarTypeId
         and A1.CAL_DATE = trunc(aFromDate);
    end if;

    select CAL_DATE
      into result
      from PAC_CALENDAR_DAYS A
         , PAC_CALENDAR B
     where A.PAC_CALENDAR_ID = B.PAC_CALENDAR_ID
       and B.PAC_CALENDAR_TYPE_ID = aCalendarTypeId
       and A.CAL_DAY_NUMBER = dayNumber + nvl(aDecalage, 0)
       and A.CAL_OPENDAY = 1;

    return result;
  exception
    when no_data_found then
      raise_application_error(-20900, PCS.PC_FUNCTIONS.TranslateWord('La date est hors calendrier!') );
  end DecalageDate;

  /**
  * Description : Donne le nombre de jours ouvrables entre deux dates
  *               en fonction du calendrier du tiers ou calendrier par défaut selon le cas
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
    result     number;
    CalendarID PAC_CALENDAR.PAC_CALENDAR_ID%type;
  begin
    result  := 0;

    if aCalendarTypeId is null then
      -- Recherche du calendrier du tiers
      if aSearchThirdCalendar = 1 then
        CalendarId  := findLogisticCalendar(aThirdId, aAdminDomain);
      else   -- Calendrier par défaut
        CalendarId  := findDefaultCalendar;
      end if;
    else
      CalendarId  := aCalendarTypeId;
    end if;

    -- Effectuer le décalage que si l'on a un calendrier
    if (CalendarID is not null) then
      result  := openDaysBetween(aFromDate, aToDate, CalendarId);
    end if;

    return result;
  end OpenDaysBetween;

  /**
  * Description : Donne le nombre de jours ouvrables entre deux dates
  *               en fonction du calendrier du tiers ou calendrier par défaut selon le cas
  */
  function OpenDaysBetween(aFromDate date, aToDate date, aCalendarTypeId number)
    return number
  is
    result        number;
    dayNumberFrom PAC_CALENDAR_DAYS.CAL_DAY_NUMBER%type;
    dayNumberTo   PAC_CALENDAR_DAYS.CAL_DAY_NUMBER%type;
  begin
    result  := 0;

    begin
      -- recherche du numéro du premier jour (ajoute 1 si on est pas sur un jour ouvrable)
      select PCD.CAL_DAY_NUMBER + decode(CAL_OPENDAY, 0, 1, 0)
        into dayNumberFrom
        from PAC_CALENDAR_DAYS PCD
           , PAC_CALENDAR CAL
       where PCD.PAC_CALENDAR_ID = CAL.PAC_CALENDAR_ID
         and PAC_CALENDAR_TYPE_ID = aCalendarTypeId
         and PCD.CAL_DATE = trunc(aFromDate);

      -- recherche du numéro du dernier jour (ajoute 1 si on est pas sur un jour ouvrable)
      select PCD.CAL_DAY_NUMBER + decode(CAL_OPENDAY, 0, 1, 0)
        into dayNumberTo
        from PAC_CALENDAR_DAYS PCD
           , PAC_CALENDAR CAL
       where PCD.PAC_CALENDAR_ID = CAL.PAC_CALENDAR_ID
         and PAC_CALENDAR_TYPE_ID = aCalendarTypeId
         and PCD.CAL_DATE = trunc(aToDate);
    exception
      -- Erreur car un des jours recherché ne se trouve pas dans le calendrier
      when no_data_found then
        raise_application_error(-20900
                              , PCS.PC_FUNCTIONS.TranslateWord('Une des deux dates est en dehors du calendrier!')
                               );
    end;

    return(dayNumberTo - dayNumberFrom);
  end OpenDaysBetween;

  /**
  * procedure CalculateDayNumber
  * Description
  *   numérote les jours en fonction des jours ouvrables
  * @created fp 18.10.2004
  * @lastUpdate
  * @public
  * @param aPacCalendarTypeId : id du calendrier à numéroter (si vide -> tous)
  */
  procedure CalculateDayNumber(aPacCalendarTypeId in PAC_CALENDAR_TYPE.PAC_CALENDAR_TYPE_ID%type default null)
  is
    --curseur sur tous les types de calendriers
    cursor crCalendarTypes
    is
      select PAC_CALENDAR_TYPE_ID
        from PAC_CALENDAR_TYPE;

    -- curseur sur tous les jours d'un calendrier
    cursor crCalendarDays(cCalendarTypeId PAC_CALENDAR_TYPE.PAC_CALENDAR_TYPE_ID%type)
    is
      select   PAC_CALENDAR_DAYS_ID
             , CAL_OPENDAY
          from PAC_CALENDAR_DAYS A
             , PAC_CALENDAR B
         where B.PAC_CALENDAR_TYPE_ID = cCalendarTypeId
           and A.PAC_CALENDAR_ID = B.PAC_CALENDAR_ID
      order by CAL_DATE;

    i PAC_CALENDAR_DAYS.CAL_DAY_NUMBER%type;
  begin
    -- Si on apas défini de calendrier, on les mets tous à jour
    if aPacCalendarTypeId is null then
      for tplCalendarType in crCalendarTypes loop
        CalculateDayNumber(tplCalendarType.PAC_CALENDAR_TYPE_ID);
      end loop;
    else
      i  := 0;

      -- numérotation de tous les jours dans le calendrier
      for tplCalendarDays in crCalendarDays(aPacCalendarTypeId) loop
        update    PAC_CALENDAR_DAYS
              set CAL_DAY_NUMBER = i + tplCalendarDays.CAL_OPENDAY
            where PAC_CALENDAR_DAYS_ID = tplCalendarDays.PAC_CALENDAR_DAYS_ID
        returning CAL_DAY_NUMBER
             into i;
      end loop;
    end if;
  end CalculateDayNumber;
end PAC_CALENDAR_FUNCTIONS;
