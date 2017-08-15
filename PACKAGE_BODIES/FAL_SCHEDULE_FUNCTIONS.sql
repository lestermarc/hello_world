--------------------------------------------------------
--  DDL for Package Body FAL_SCHEDULE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_SCHEDULE_FUNCTIONS" 
is
  /**
  * procedure SetValue
  * Description : Fonction utilitaire pour delphi passage de variables par paramètres.
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure SetValue(aFromValue in number, aToValue in out number)
  is
  begin
    aToValue  := aFromValue;
  end SetValue;

  /**
  * function GetDayOfWeek
  * Description : indique si la date passée en param correspond au jour de la semaine MON,TUE...etc
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aDate : Date
  * @param   aDayOfWeek : Jour de la semaine
  */
  function GetDayOfWeek(aDate date, aDayOfWeek varchar2)
    return integer
  is
    aDateToCompare date;
  begin
    select next_day(aDate - 1, aDayOfWeek)
      into aDateToCompare
      from dual;

    if trunc(aDateToCompare) = trunc(aDate) then
      return 1;
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end GetDayOfWeek;

  /**
  * Function GetTime
  * Description : Fonction qui renvoie la fraction de jour passée en paramètre en Temps format : HH24:MI.
  * @created ECA
  * @lastUpdate
  * @private
  * @param aDayFrac : Fraction de jour
  */
  function GetTime(aDayFrac number)
    return varchar2
  is
    nMinutes number;
    nHours   number;
  begin
    nMinutes  := round( ( (aDayFrac * 24) - trunc(aDayFrac * 24) ) * 60);
    nHours    := trunc(aDayFrac * 24);

    -- Max => 23:59 .
    if nHours > 23 then
      return '23:59';
    end if;

    if nMinutes < 60 then
      return lpad(to_char(nHours), 2, '0') || ':' || lpad(to_char(trunc(nMinutes) ), 2, '0');
    else
      if (nHours + 1) > 23 then
        return '23:59';
      else
        return lpad(to_char(nHours) + 1, 2, '0') || ':' || '00';
      end if;
    end if;
  end GetTime;

  /**
  * Function GetHourCapacity
  * Description : Fonction qui renvoie la capacité d'une période.
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aStartTime : heure début
  * @param   aEndTime : heure fin
  * @param   aRessourceNumber : Nombre de ressources
  */
  function GetHourCapacity(aStartTime varchar2, aEndTime varchar2, aResourceNumber number)
    return number
  is
    tmpStartTime PAC_SCHEDULE_PERIOD.SCP_OPEN_TIME%type    default 0.0;
    tmpEndTime   PAC_SCHEDULE_PERIOD.SCP_CLOSE_TIME%type   default 0.0;
  begin
    -- Heure de départ de la période
    if aStartTime is not null then
      select to_date(aStartTime, 'HH24:MI') - to_date('00:00', 'HH24:MI')
        into tmpStartTime
        from dual;
    end if;

    -- Heure de fin de la période
    if aEndTime is not null then
      select to_date(aEndTime, 'HH24:MI') - to_date('00:00', 'HH24:MI')
        into tmpEndTime
        from dual;
    end if;

    return round( (tmpEndTime - tmpStartTime) * 24 * aResourceNumber, 2);
  end GetHourCapacity;

  /**
  * Function GetQtyCapacity
  * Description : Fonction qui renvoie la capacité d'une période en quantité
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aStartTime : heure début
  * @param   aEndTime : Heure fin
  * @param   aRessourceNumber : Nbre de ressources
  * @param   aPiecesByHourCapacity : Capacité en pièces par heure
  */
  function GetQtyCapacity(aStartTime varchar2, aEndTime varchar2, aResourceNumber number, aPiecesByHourCapacity number)
    return number
  is
  begin
    return aPiecesByHourCapacity * GetHourCapacity(aStartTime, aEndTime, aResourceNumber);
  end GetQtyCapacity;

  /**
  * procedure GetCalendarFilter
  * Description : Fonction utilitaire utilisée pour récupération du filtre et de son ID.
  *               (Utilisation des fonctions PAC_SCHEDULE_FUNCTION)
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aFAL_FACTORY_FLOOR_ID : Atelier
  * @param   aPAC_SUPPLIER_PARTNER_ID : Fournisseur
  * @param   aPAC_CUSTOM_PARTNER_ID : Client
  * @param   aPAC_DEPARTMENT_ID : Département
  * @param   aHRM_PERSON_ID : Personne
  * @return  aFilter : Filtre
  * @return  aFilterID : ID Filtre
  */
  procedure GetCalendarFilter(
    aFAL_FACTORY_FLOOR_ID    in     FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in     PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID   in     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_DEPARTMENT_ID       in     PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type
  , aHRM_PERSON_ID           in     HRM_PERSON.HRM_PERSON_ID%type
  , aFilter                  in out varchar2
  , aFilterID                in out number
  )
  is
  begin
    if nvl(aFAL_FACTORY_FLOOR_ID, 0) <> 0 then
      aFilterID  := aFAL_FACTORY_FLOOR_ID;
      aFilter    := 'FACTORY_FLOOR';
    elsif nvl(aPAC_SUPPLIER_PARTNER_ID, 0) <> 0 then
      aFilterID  := aPAC_SUPPLIER_PARTNER_ID;
      aFilter    := 'SUPPLIER';
    elsif nvl(aPAC_CUSTOM_PARTNER_ID, 0) <> 0 then
      aFilterID  := aPAC_CUSTOM_PARTNER_ID;
      aFilter    := 'CUSTOMER';
    elsif nvl(aPAC_DEPARTMENT_ID, 0) <> 0 then
      aFilterID  := aPAC_DEPARTMENT_ID;
      aFilter    := 'DEPARTMENT';
    elsif nvl(aHRM_PERSON_ID, 0) <> 0 then
      aFilterID  := aHRM_PERSON_ID;
      aFilter    := 'HRM_PERSON';
    else
      aFilterID  := null;
      aFilter    := null;
    end if;
  end GetCalendarFilter;

  /**
  * function GetDefaultCalendar
  * Description : Fonction qui renvoie l'ID du calendrier par défaut
  * @created ECA
  * @lastUpdate
  * @public
  */
  function GetDefaultCalendar
    return number
  is
    aResult number;
  begin
    select PAC_SCHEDULE_ID
      into aResult
      from PAC_SCHEDULE
     where SCE_DEFAULT = 1;

    return aResult;
  exception
    when no_data_found then
      raise_application_error(-20101, 'PCS - Default calendar type not found');
  end GetDefaultCalendar;

  procedure GetDefaultCalendar(result in out number)
  is
  begin
    result  := GetDefaultCalendar;
  end GetDefaultCalendar;

  /**
  * Description :
  *    Retourne la description du calendrier par défaur
  */
  function GetDefaultCalendarDescr
    return varchar2
  is
  begin
    return FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('PAC_SCHEDULE', 'SCE_DESCR', GetDefaultCalendar);
  end GetDefaultCalendarDescr;

  procedure GetDefaultCalendarDescr(result in out varchar2)
  is
  begin
    result  := GetDefaultCalendarDescr;
  end GetDefaultCalendarDescr;

  /**
  * Description :
  *    Renvoie le calendrier de la ressource, et le calendrier par défaut sinon (anciens calendriers ou nouveaux).
  */
  function GetFloorCalendar(aFAL_FACTORY_FLOOR_ID in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type)
    return number
  is
    aCalendarID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    select PAC_SCHEDULE_ID
      into aCalendarID
      from FAL_FACTORY_FLOOR
     where FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID;

    if nvl(aCalendarID, 0) = 0 then
      aCalendarID  := GetDefaultCalendar;
    end if;

    return aCalendarID;
  exception
    when no_data_found then
      return GetDefaultCalendar;
  end GetFloorCalendar;

  procedure GetFloorCalendar(aFAL_FACTORY_FLOOR_ID in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type, result in out number)
  is
  begin
    result  := GetFloorCalendar(aFAL_FACTORY_FLOOR_ID);
  end GetFloorCalendar;

  /**
  * Description :
  *    Renvoie le calendrier du fournisseur si existant, sinon le calendrier par défaut
  */
  function GetSupplierCalendar(aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type)
    return number
  is
    aCalendarID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    select PAC_SCHEDULE_ID
      into aCalendarID
      from PAC_SUPPLIER_PARTNER
     where PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID;

    if nvl(aCalendarID, 0) = 0 then
      aCalendarID  := GetDefaultCalendar;
    end if;

    return aCalendarID;
  exception
    when no_data_found then
      return GetDefaultCalendar;
  end GetSupplierCalendar;

  procedure GetSupplierCalendar(aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type, result in out number)
  is
  begin
    result  := GetSupplierCalendar(aPAC_SUPPLIER_PARTNER_ID);
  end GetSupplierCalendar;

  /**
  * Description :
  *    Renvoie la description du calendrier de la ressource, et celle du calendrier par défaut sinon
  */
  function GetFloorCalendarDescr(aFAL_FACTORY_FLOOR_ID in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type)
    return varchar2
  is
  begin
    return nvl(FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('PAC_SCHEDULE', 'SCE_DESCR', GetFloorCalendar(aFAL_FACTORY_FLOOR_ID) ), GetDefaultCalendarDescr);
  end GetFloorCalendarDescr;

  /**
  * Description :
  *    Renvoie la description du calendrier du Fournisseur, et du calendrier par défaut sinon (anciens calendriers pour le moment).
  */
  function GetSupplierCalendarDescr(aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type)
    return varchar2
  is
  begin
    return nvl(FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('PAC_SCHEDULE', 'SCE_DESCR', GetSupplierCalendar(aPAC_SUPPLIER_PARTNER_ID) ), GetDefaultCalendarDescr);
  end GetSupplierCalendarDescr;

  procedure GetSupplierCalendarDescr(aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type, result in out varchar2)
  is
  begin
    result  := GetSupplierCalendarDescr(aPAC_SUPPLIER_PARTNER_ID);
  end GetSupplierCalendarDescr;

  /**
  * Description :
  *    Renvoie le calendrier du Client, et le calendrier par défaut sinon.
  */
  function GetCustomerCalendar(aPAC_CUSTOM_PARTNER_ID in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
    return number
  is
    aCalendarID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    select PAC_SCHEDULE_ID
      into aCalendarID
      from PAC_CUSTOM_PARTNER
     where PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID;

    if nvl(aCalendarID, 0) = 0 then
      aCalendarID  := GetDefaultCalendar;
    end if;

    return aCalendarID;
  exception
    when no_data_found then
      return GetDefaultCalendar;
  end GetCustomerCalendar;

  procedure GetCustomerCalendar(aPAC_CUSTOM_PARTNER_ID in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type, result in out number)
  is
  begin
    result  := GetCustomerCalendar(aPAC_CUSTOM_PARTNER_ID);
  end GetCustomerCalendar;

  /**
  * Description :
  *    Renvoie le calendrier du Département, et le calendrier par défaut sinon (anciens calendriers pour le moment).
  */
  function GetDepartmentCalendar(aPAC_DEPARTMENT_ID in PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type)
    return number
  is
    aCalendarID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    select PAC_SCHEDULE_ID
      into aCalendarID
      from PAC_DEPARTMENT
     where PAC_DEPARTMENT_ID = aPAC_DEPARTMENT_ID;

    if nvl(aCalendarID, 0) = 0 then
      aCalendarID  := GetDefaultCalendar;
    end if;
  exception
    when no_data_found then
      aCalendarID  := GetDefaultCalendar;
  end GetDepartmentCalendar;

  procedure GetDepartmentCalendar(aPAC_DEPARTMENT_ID in PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type, result in out number)
  is
  begin
    result  := GetDepartmentCalendar(aPAC_DEPARTMENT_ID);
  end GetDepartmentCalendar;

  /**
  * Description :
  *    Renvoie le calendrier de la person HRM, et le calendrier par défaut sinon.
  */
  function GetPersonCalendar(aHRM_PERSON_ID in HRM_PERSON.HRM_PERSON_ID%type)
    return number
  is
  begin
    -- Pas de gestion des calendriers au niveau des personnes ==> Calendrier par défaut de la société
    return GetDefaultCalendar;
  end GetPersonCalendar;

  procedure GetPersonCalendar(aHRM_PERSON_ID in HRM_PERSON.HRM_PERSON_ID%type, result in out number)
  is
  begin
    result  := GetPersonCalendar(aHRM_PERSON_ID);
  end GetPersonCalendar;

  /**
  * Description :
  *   Renvoie le calendrier de la Ressource, et le calendrier par défaut sinon (anciens calendriers pour le moment).
  */
  function GetRessourceCalendar(
    aFAL_FACTORY_FLOOR_ID    in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID   in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_DEPARTMENT_ID       in PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type
  , aHRM_PERSON_ID           in HRM_PERSON.HRM_PERSON_ID%type
  , aCalendarID              in number
  )
    return number
  is
    aParticularCalendar number;
  begin
    aParticularCalendar  := 0;

    if nvl(aFAL_FACTORY_FLOOR_ID, 0) <> 0 then
      return GetFloorCalendar(aFAL_FACTORY_FLOOR_ID);
    elsif nvl(aPAC_SUPPLIER_PARTNER_ID, 0) <> 0 then
      return GetSupplierCalendar(aPAC_SUPPLIER_PARTNER_ID);
    elsif nvl(aPAC_CUSTOM_PARTNER_ID, 0) <> 0 then
      return GetCustomerCalendar(aPAC_CUSTOM_PARTNER_ID);
    elsif nvl(aPAC_DEPARTMENT_ID, 0) <> 0 then
      return GetDepartmentCalendar(aPAC_DEPARTMENT_ID);
    elsif nvl(aHRM_PERSON_ID, 0) <> 0 then
      return GetPersonCalendar(aHRM_PERSON_ID);
    elsif nvl(aCalendarID, 0) <> 0 then
      begin
        select PAC_SCHEDULE_ID
          into aParticularCalendar
          from PAC_SCHEDULE
         where PAC_SCHEDULE_ID = aCalendarID;
      exception
        when no_data_found then
          return GetDefaultCalendar;
      end;

      return aParticularCalendar;
    else
      return GetDefaultCalendar;
    end if;
  end GetRessourceCalendar;

  procedure GetRessourceCalendar(
    aFAL_FACTORY_FLOOR_ID    in     FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in     PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID   in     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_DEPARTMENT_ID       in     PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type
  , aHRM_PERSON_ID           in     HRM_PERSON.HRM_PERSON_ID%type
  , aCalendarID              in     number
  , result                   in out number
  )
  is
  begin
    result  := GetRessourceCalendar(aFAL_FACTORY_FLOOR_ID, aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID, aPAC_DEPARTMENT_ID, aHRM_PERSON_ID, aCalendarID);
  end GetRessourceCalendar;

  /**
  * Description :
  *    Renvoie la date aDate décallée du décalage achat du produit aGCO_GOOD_ID
  */
  function GetShiftedDate(aDate date, aGCO_GOOD_ID gco_good.GCO_GOOD_ID%type)
    return date
  is
    aShift       integer;
    aShiftedDate date;
  begin
    -- Recherche du décalage achat du produit
    select nvl(CPU_SHIFT, 0)
      into aShift
      from GCO_COMPL_DATA_PURCHASE
     where GCO_GOOD_ID = aGCO_GOOD_ID
       and CPU_DEFAULT_SUPPLIER = 1;

    -- Calcul de la date décalée
    aShiftedDate  := trunc(GetDecalage(null, null, null, null, null, FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar, trunc(aDate), aShift, 1));
    return aShiftedDate;
  exception
    when others then
      return aDate;
  end GetShiftedDate;

  /**
  * Function GetDuration
  * Description : Retourne le nombre de jours ouvrés entre les date début et fin en fonction du calendrier utilisé
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_FACTORY_FLOOR_ID      : Atelier dont on cherche le calendrier
  * @param   aPAC_SUPPLIER_PARTNER_ID   : Fournisseur dont on cherche le calendrier
  * @param   aPAC_CUSTOM_PARTNER_ID     : Client
  * @param   aPAC_DEPARTMENT_ID         : Département
  * @param   aHRM_PERSON_ID             : Personne
  * @param   typecalendar               : Calendrier Particulier sur lequel on souhaite faire le calcul
  * @param   abegindate                 : Date début calcul
  * @param   aenddate                   : Date fin calcul
  */
  function GetDuration(
    aFAL_FACTORY_FLOOR_ID    in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID   in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_DEPARTMENT_ID       in PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type
  , aHRM_PERSON_ID           in HRM_PERSON.HRM_PERSON_ID%type
  , aCalendarID              in number
  , aBeginDate               in FAL_TASK_LINK.TAL_BEGIN_PLAN_DATE%type
  , aEndDate                 in FAL_TASK_LINK.TAL_BEGIN_PLAN_DATE%type
  )
    return number
  is
    aDuration     number;
    tmpCalendarID number;
    aFilter       varchar2(30);
    aFilterID     number;
  begin
    -- recherche du calendrier de la ressource
    tmpCalendarID  :=
                 GetRessourceCalendar(aFAL_FACTORY_FLOOR_ID, aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID, aPAC_DEPARTMENT_ID, aHRM_PERSON_ID, aCalendarID);
    -- Recherche du filtre à appliquer sur les horaires
    GetCalendarFilter(aFAL_FACTORY_FLOOR_ID, aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID, aPAC_DEPARTMENT_ID, aHRM_PERSON_ID, aFilter, aFilterID);
    -- Calcul du nombre de jours ouvré entre les deux dates
    aDuration      := PAC_I_LIB_SCHEDULE.GetOpenDaysBetween(tmpCalendarID, aBeginDate, aEndDate, aFilter, aFilterID);
    return aDuration;
  end GetDuration;

  procedure GetDuration(
    aFAL_FACTORY_FLOOR_ID    in     FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in     PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID   in     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_DEPARTMENT_ID       in     PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type
  , aHRM_PERSON_ID           in     HRM_PERSON.HRM_PERSON_ID%type
  , aCalendarID              in     number
  , aBeginDate               in     FAL_TASK_LINK.TAL_BEGIN_PLAN_DATE%type
  , aEndDate                 in     FAL_TASK_LINK.TAL_BEGIN_PLAN_DATE%type
  , result                   in out number
  )
  is
  begin
    result  :=
      GetDuration(aFAL_FACTORY_FLOOR_ID
                , aPAC_SUPPLIER_PARTNER_ID
                , aPAC_CUSTOM_PARTNER_ID
                , aPAC_DEPARTMENT_ID
                , aHRM_PERSON_ID
                , aCalendarID
                , aBeginDate
                , aEndDate
                 );
  end GetDuration;

  /**
  * Description :
  *    Calcul du décalage avant sur date à partir du calendrier de l'atelier, du fournisseur,
  *    ou du calendrier passé en paramètre, en planification avant
  */
  function GetDecalageForwardDate(
    aFAL_FACTORY_FLOOR_ID    in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID   in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_DEPARTMENT_ID       in PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type
  , aHRM_PERSON_ID           in HRM_PERSON.HRM_PERSON_ID%type
  , aCalendarID              in number
  , aFromDate                in date
  , aDecalage                in integer
  )
    return date
  is
  begin
    return GetDecalage(aFAL_FACTORY_FLOOR_ID
                     , aPAC_SUPPLIER_PARTNER_ID
                     , aPAC_CUSTOM_PARTNER_ID
                     , aPAC_DEPARTMENT_ID
                     , aHRM_PERSON_ID
                     , aCalendarID
                     , aFromDate
                     , aDecalage
                     , 1
                      );
  end GetDecalageForwardDate;

  procedure GetDecalageForwardDate(
    aFAL_FACTORY_FLOOR_ID    in     FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in     PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID   in     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_DEPARTMENT_ID       in     PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type
  , aHRM_PERSON_ID           in     HRM_PERSON.HRM_PERSON_ID%type
  , aCalendarID              in     number
  , aFromDate                in     date
  , aDecalage                in     integer
  , result                   in out date
  )
  is
  begin
    result  :=
      GetDecalage(aFAL_FACTORY_FLOOR_ID
                , aPAC_SUPPLIER_PARTNER_ID
                , aPAC_CUSTOM_PARTNER_ID
                , aPAC_DEPARTMENT_ID
                , aHRM_PERSON_ID
                , aCalendarID
                , aFromDate
                , aDecalage
                , 1
                 );
  end GetDecalageForwardDate;

  /**
  * Description :
  *   Calcul du décalage arrière sur date à partir du calendrier de l'atelier, du fournisseur,
  *   ou du calendrier passé en paramètre, en planification arrière.
  */
  function GetDecalageBackwardDate(
    aFAL_FACTORY_FLOOR_ID    in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type default null
  , aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type default null
  , aPAC_CUSTOM_PARTNER_ID   in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type default null
  , aPAC_DEPARTMENT_ID       in PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type default null
  , aHRM_PERSON_ID           in HRM_PERSON.HRM_PERSON_ID%type default null
  , aCalendarID              in number
  , aFromDate                in date
  , aDecalage                in integer
  )
    return date
  is
  begin
    return GetDecalage(aFAL_FACTORY_FLOOR_ID
                     , aPAC_SUPPLIER_PARTNER_ID
                     , aPAC_CUSTOM_PARTNER_ID
                     , aPAC_DEPARTMENT_ID
                     , aHRM_PERSON_ID
                     , aCalendarID
                     , aFromDate
                     , aDecalage
                     , 0
                      );
  end GetDecalageBackwardDate;

  procedure GetDecalageBackwardDate(
    aFAL_FACTORY_FLOOR_ID    in     FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type default null
  , aPAC_SUPPLIER_PARTNER_ID in     PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type default null
  , aPAC_CUSTOM_PARTNER_ID   in     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type default null
  , aPAC_DEPARTMENT_ID       in     PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type default null
  , aHRM_PERSON_ID           in     HRM_PERSON.HRM_PERSON_ID%type default null
  , aCalendarID              in     number
  , aFromDate                in     date
  , aDecalage                in     integer
  , result                   in out date
  )
  is
  begin
    result  :=
      GetDecalage(aFAL_FACTORY_FLOOR_ID
                , aPAC_SUPPLIER_PARTNER_ID
                , aPAC_CUSTOM_PARTNER_ID
                , aPAC_DEPARTMENT_ID
                , aHRM_PERSON_ID
                , aCalendarID
                , aFromDate
                , aDecalage
                , 0
                 );
  end GetDecalageBackwardDate;

  /**
  * Description :
  *    Appel du calcul du décalage avant ou arrière en fonction du paramètre aForward
  */
  function GetDecalage(
    aFAL_FACTORY_FLOOR_ID    in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type default null
  , aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type default null
  , aPAC_CUSTOM_PARTNER_ID   in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type default null
  , aPAC_DEPARTMENT_ID       in PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type default null
  , aHRM_PERSON_ID           in HRM_PERSON.HRM_PERSON_ID%type default null
  , aCalendarID              in number default null
  , aFromDate                in date
  , aDecalage                in integer
  , aForward                 in integer default 1
  )
    return date
  is
    result      date;
    lCalendarId number;
    aFilter     varchar2(30);
    aFilterID   number;
  begin
    result       := to_date(to_char(aFromDate, 'DD/MM/YYYY'), 'DD/MM/YYYY');
    -- recherche du calendrier de la ressource.
    lCalendarId  :=
                 GetRessourceCalendar(aFAL_FACTORY_FLOOR_ID, aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID, aPAC_DEPARTMENT_ID, aHRM_PERSON_ID, aCalendarId);
    -- Recherche du filtre à appliquer aux horaires
    GetCalendarFilter(aFAL_FACTORY_FLOOR_ID, aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID, aPAC_DEPARTMENT_ID, aHRM_PERSON_ID, aFilter, aFilterID);
    result       := PAC_I_LIB_SCHEDULE.GetShiftOpenDate(lCalendarId, aFromDate, aDecalage, aForward, aFilter, aFilterID);
    return result;
  end GetDecalage;

    /**
  * Function UpdateCapacityAndResource
  * Description : Mise à jour de la capacité et du nombre de ressources d'une élément,
  *               atelier, client...etc
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_FACTORY_FLOOR_ID : Atelier
  * @param   aPAC_CUSTOM_PARTNER_ID : Client
  * @param   aPAC_SUPPLIER_PARTNER_ID : Fournisseur
  * @param   aPAC_DEPARTMENT_ID : département
  * @param   aHRM_PERSON_ID : personne
  * @param   aDate : Date
  * @param   aCalendarID : ID calendrier
  * @param   aNewCapacityHour : Capacité en heure
  * @param   aNewCapacityQty : Capacité en quantité
  * @param   aNewResourceNumber : Nombre de ressources de l'élément.
  * @param   blnUpdateResource : Mise à jour de la ressource.
  */
  procedure UpdateCapacityAndResource(
    aFAL_FACTORY_FLOOR_ID    in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , aPAC_CUSTOM_PARTNER_ID   in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_DEPARTMENT_ID       in PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type
  , aHRM_PERSON_ID           in HRM_PERSON.HRM_PERSON_ID%type
  , aDate                    in date
  , aCalendarID              in number
  , aNewCapacityHour         in number
  , aNewCapacityQty          in number
  , aNewResourceNumber       in number
  , blnupdateresource        in integer
  )
  is
    cursor crGetPeriodToCopy
    is
      -- Jours pour calendrier standard
      select   C_DAY_OF_WEEK
             , SCP_OPEN_TIME
             , SCP_CLOSE_TIME
             , SCP_DATE
             , SCP_NONWORKING_DAY
             , SCP_RESOURCE_NUMBER
             , SCP_RESOURCE_CAPACITY
             , SCP_RESOURCE_CAP_IN_QTY
             , SCP_WORKING_TIME
             , SCP_PIECES_HOUR_CAP
             , 1 as ORDER_FIELD
          from PAC_SCHEDULE SCE
             , PAC_SCHEDULE_PERIOD SCP
         where SCE.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID
           and SCP_DATE is null
           and SCP.FAL_FACTORY_FLOOR_ID is null
           and SCP.PAC_CUSTOM_PARTNER_ID is null
           and SCP.PAC_SUPPLIER_PARTNER_ID is null
           and SCP.PAC_DEPARTMENT_ID is null
           and SCP.HRM_PERSON_ID is null
           and SCP.PAC_SCHEDULE_ID = aCalendarID
           and FAL_SCHEDULE_FUNCTIONS.GetDayOfWeek(aDate, C_DAY_OF_WEEK) = 1
           and nvl(SCP.SCP_NONWORKING_DAY, 0) <> 1
      union all
      -- Jours pour la ressource
      select   C_DAY_OF_WEEK
             , SCP_OPEN_TIME
             , SCP_CLOSE_TIME
             , SCP_DATE
             , SCP_NONWORKING_DAY
             , SCP_RESOURCE_NUMBER
             , SCP_RESOURCE_CAPACITY
             , SCP_RESOURCE_CAP_IN_QTY
             , SCP_WORKING_TIME
             , SCP_PIECES_HOUR_CAP
             , 2 as ORDER_FIELD
          from PAC_SCHEDULE SCE
             , PAC_SCHEDULE_PERIOD SCP
         where SCE.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID
           and (   nvl(aFAL_FACTORY_FLOOR_ID, 0) = 0
                or FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID)
           and (   nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0
                or PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID)
           and (   nvl(aPAC_SUPPLIER_PARTNER_ID, 0) = 0
                or PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID)
           and (   nvl(aPAC_DEPARTMENT_ID, 0) = 0
                or PAC_DEPARTMENT_ID = aPAC_DEPARTMENT_ID)
           and (   nvl(aHRM_PERSON_ID, 0) = 0
                or HRM_PERSON_ID = aHRM_PERSON_ID)
           and SCP_DATE is null
           and SCP.PAC_SCHEDULE_ID = aCalendarID
           and FAL_SCHEDULE_FUNCTIONS.GetDayOfWeek(aDate, C_DAY_OF_WEEK) = 1
           and nvl(SCP.SCP_NONWORKING_DAY, 0) <> 1
      union all
      -- date calendrier standard
      select   C_DAY_OF_WEEK
             , SCP_OPEN_TIME
             , SCP_CLOSE_TIME
             , SCP_DATE
             , SCP_NONWORKING_DAY
             , SCP_RESOURCE_NUMBER
             , SCP_RESOURCE_CAPACITY
             , SCP_RESOURCE_CAP_IN_QTY
             , SCP_WORKING_TIME
             , SCP_PIECES_HOUR_CAP
             , 3 as ORDER_FIELD
          from PAC_SCHEDULE SCE
             , PAC_SCHEDULE_PERIOD SCP
         where SCE.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID
           and SCP_DATE is not null
           and trunc(SCP_DATE) = trunc(aDate)
           and SCP.FAL_FACTORY_FLOOR_ID is null
           and SCP.PAC_CUSTOM_PARTNER_ID is null
           and SCP.PAC_SUPPLIER_PARTNER_ID is null
           and SCP.PAC_DEPARTMENT_ID is null
           and SCP.HRM_PERSON_ID is null
           and SCP.PAC_SCHEDULE_ID = aCalendarID
           and nvl(SCP.SCP_NONWORKING_DAY, 0) <> 1
      order by ORDER_FIELD desc;

    cursor crAdjustPeriodsIncrease
    is
      select   C_DAY_OF_WEEK
             , PAC_SCHEDULE_PERIOD_id
             , FAL_FACTORY_FLOOR_ID
             , PAC_SUPPLIER_PARTNER_ID
             , PAC_CUSTOM_PARTNER_ID
             , PAC_DEPARTMENT_ID
             , HRM_PERSON_ID
             , SCP_OPEN_TIME
             , SCP_CLOSE_TIME
             , SCP_DATE
             , SCP_NONWORKING_DAY
             , SCP_RESOURCE_NUMBER
             , SCP_RESOURCE_CAPACITY
             , SCP_RESOURCE_CAP_IN_QTY
             , SCP_COMMENT
             , DIC_SCH_PERIOD_1_ID
             , DIC_SCH_PERIOD_2_ID
             , SCP_WORKING_TIME
             , SCP_PIECES_HOUR_CAP
             , 3 as ORDER_FIELD
          from PAC_SCHEDULE SCE
             , PAC_SCHEDULE_PERIOD SCP
         where SCE.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID
           and SCP_DATE is not null
           and trunc(SCP_DATE) = trunc(aDate)
           and (   nvl(aFAL_FACTORY_FLOOR_ID, 0) = 0
                or FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID)
           and (   nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0
                or PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID)
           and (   nvl(aPAC_SUPPLIER_PARTNER_ID, 0) = 0
                or PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID)
           and (   nvl(aPAC_DEPARTMENT_ID, 0) = 0
                or PAC_DEPARTMENT_ID = aPAC_DEPARTMENT_ID)
           and (   nvl(aHRM_PERSON_ID, 0) = 0
                or HRM_PERSON_ID = aHRM_PERSON_ID)
           and SCP.PAC_SCHEDULE_ID = aCalendarID
      order by SCP_OPEN_TIME desc;

    cursor crAdjustPeriodsDecrease
    is
      select   C_DAY_OF_WEEK
             , PAC_SCHEDULE_PERIOD_id
             , FAL_FACTORY_FLOOR_ID
             , PAC_SUPPLIER_PARTNER_ID
             , PAC_CUSTOM_PARTNER_ID
             , PAC_DEPARTMENT_ID
             , HRM_PERSON_ID
             , SCP_OPEN_TIME
             , SCP_CLOSE_TIME
             , SCP_DATE
             , SCP_NONWORKING_DAY
             , SCP_RESOURCE_NUMBER
             , SCP_RESOURCE_CAPACITY
             , SCP_RESOURCE_CAP_IN_QTY
             , SCP_COMMENT
             , DIC_SCH_PERIOD_1_ID
             , DIC_SCH_PERIOD_2_ID
             , SCP_WORKING_TIME
             , SCP_PIECES_HOUR_CAP
             , 3 as ORDER_FIELD
          from PAC_SCHEDULE SCE
             , PAC_SCHEDULE_PERIOD SCP
         where SCE.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID
           and SCP_DATE is not null
           and trunc(SCP_DATE) = trunc(aDate)
           and (   nvl(aFAL_FACTORY_FLOOR_ID, 0) = 0
                or FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID)
           and (   nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0
                or PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID)
           and (   nvl(aPAC_SUPPLIER_PARTNER_ID, 0) = 0
                or PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID)
           and (   nvl(aPAC_DEPARTMENT_ID, 0) = 0
                or PAC_DEPARTMENT_ID = aPAC_DEPARTMENT_ID)
           and (   nvl(aHRM_PERSON_ID, 0) = 0
                or HRM_PERSON_ID = aHRM_PERSON_ID)
           and SCP.PAC_SCHEDULE_ID = aCalendarID
      order by SCP_OPEN_TIME asc;

    tplGetPeriodToCopy       crGetPeriodToCopy%rowtype;
    tplAdjustPeriodsIncrease crAdjustPeriodsIncrease%rowtype;
    tplAdjustPeriodsDecrease crAdjustPeriodsDecrease%rowtype;
    nbExistingPeriods        integer;
    aStartTime               varchar2(5);
    aEndTime                 varchar2(5);
    aErrorPeriodID           number;
    CopiedPeriodOrder        integer;
    nCapacityRemainder       number;
    nFreeCapacity            number;
    nLastPeriodStartTime     number;
    blnLastDayPeriod         boolean;
    nTotalDayRessources      number;
    blnDoAdjustement         boolean;
    aPeriodCapacity          number;
    aQtyCapacity             number;
    aFilter                  varchar2(30);
    aFilterID                number;
    cstMaxDayCapacity        number;
  begin
    blnDoAdjustement   := true;
    cstMaxDayCapacity  := 0.99931;   -- Correspond à 23:59.

    -- Vérification des paramètres d'entrée
    if     nvl(aFAL_FACTORY_FLOOR_ID, 0) = 0
       and nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0
       and nvl(aPAC_SUPPLIER_PARTNER_ID, 0) = 0
       and nvl(aPAC_DEPARTMENT_ID, 0) = 0
       and nvl(aHRM_PERSON_ID, 0) = 0 then
      raise_application_error(-20100, PCS.PC_PUBLIC.TranslateWord('Ressource non identifiée!') );
    elsif aDate is null then
      raise_application_error(-20100, PCS.PC_PUBLIC.TranslateWord('Date non précisée pour la mise à jour du calendrier!') );
    elsif aNewCapacityHour > 24 then
      raise_application_error(-20100, PCS.PC_PUBLIC.TranslateWord('La capacité jour doit être inférieure à 24 heures!') );
    elsif aNewCapacityHour <= 0 then
      raise_application_error(-20100, PCS.PC_PUBLIC.TranslateWord('La capacité jour doit être supérieure 0!') );
    else
      -- Existe-t'il une période pour le ressources/Dates/Calendrier donnés
      begin
        select nvl(count(PAC_SCHEDULE_PERIOD_id), 0)
          into nbExistingPeriods
          from PAC_SCHEDULE_PERIOD
         where PAC_SCHEDULE_ID = aCalendarID
           and (   nvl(aFAL_FACTORY_FLOOR_ID, 0) = 0
                or FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID)
           and (   nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0
                or PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID)
           and (   nvl(aPAC_SUPPLIER_PARTNER_ID, 0) = 0
                or PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID)
           and (   nvl(aPAC_DEPARTMENT_ID, 0) = 0
                or PAC_DEPARTMENT_ID = aPAC_DEPARTMENT_ID)
           and (   nvl(aHRM_PERSON_ID, 0) = 0
                or HRM_PERSON_ID = aHRM_PERSON_ID)
           and SCP_DATE is not null
           and trunc(SCP_DATE) = trunc(aDate);
      exception
        when others then
          nbExistingPeriods  := 0;
      end;

      GetCalendarFilter(aFAL_FACTORY_FLOOR_ID, aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID, aPAC_DEPARTMENT_ID, aHRM_PERSON_ID, aFilter, aFilterID);

      -- Si oui s'agit'il d'un jour fermé.
      if nbExistingPeriods > 0 then
        -- Si jour fermé suppression de la période correspondante
        if PAC_I_LIB_SCHEDULE.IsOpenDay(aCalendarID, trunc(aDate), aFilter, aFilterID) = 0 then
          delete      PAC_SCHEDULE_PERIOD
                where PAC_SCHEDULE_ID = aCalendarID
                  and (   nvl(aFAL_FACTORY_FLOOR_ID, 0) = 0
                       or FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID)
                  and (   nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0
                       or PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID)
                  and (   nvl(aPAC_SUPPLIER_PARTNER_ID, 0) = 0
                       or PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID)
                  and (   nvl(aPAC_DEPARTMENT_ID, 0) = 0
                       or PAC_DEPARTMENT_ID = aPAC_DEPARTMENT_ID)
                  and (   nvl(aHRM_PERSON_ID, 0) = 0
                       or HRM_PERSON_ID = aHRM_PERSON_ID)
                  and SCP_DATE is not null
                  and trunc(SCP_DATE) = trunc(aDate);

          nbExistingPeriods  := 0;
        end if;
      end if;

      -- Si non.
      if nbExistingPeriods = 0 then
        open crGetPeriodToCopy;

        fetch crGetPeriodToCopy
         into tplGetPeriodToCopy;

        -- Si pas de période à copier
        if crGetPeriodToCopy%notfound then
          blnDoAdjustement  := false;
          -- Date début.
          aStartTime        := GetTime( (24 - aNewCapacityHour) / 48);
          -- Calcul date fin
          aEndTime          := GetTime( (24 + aNewCapacityHour) / 48);
          -- Calcul capacité heures
          aPeriodCapacity   := GetHourCapacity(aStartTime, aEndTime, aNewResourceNumber);
          -- Calcul de la capacité en quantité
          aQtyCapacity      := GetQtyCapacity(aStartTime, aEndTime, aNewResourceNumber, aNewCapacityQty);

          begin
            PAC_I_PRC_SCHEDULE.InsertSchedulePeriod(iScheduleID         => aCalendarID
                                                  , iDate               => aDate
                                                  , iDayOfWeek          => ''
                                                  , iNonWorkingDay      => 0
                                                  , iStartTime          => aStartTime
                                                  , iEndTime            => aEndTime
                                                  , iComment            => PCS.PC_PUBLIC.TranslateWord('Créé par l''analyse des charges')
                                                  , iFilter             => aFilter
                                                  , iFilterID           => aFilterID
                                                  , iResourceNumber     => aNewResourceNumber
                                                  , iResourceCapacity   => aPeriodCapacity
                                                  , iResourceCapQty     => aQtyCapacity
                                                  , iPiecesHourCap      => aNewCapacityQty
                                                  , iDicSchPeriod1      => null
                                                  , iDicSchPeriod2      => null
                                                  , oErrorPeriodID      => aErrorPeriodID
                                                   );
          exception
            when others then
              begin
                close crGetPeriodToCopy;

                raise;
              end;
          end;

          close crGetPeriodToCopy;
        -- Il existe des périodes à copier
        else
          -- Alors on copie les périodes du jour le plus adequate c-a-d Date Calendrier standard, ou jour calendrier/atelier ou jour calendrier standard.
          while crGetPeriodToCopy%found loop
            CopiedPeriodOrder  := tplGetPeriodToCopy.ORDER_FIELD;
            --Date début.
            aStartTime         := GetTime(tplGetPeriodToCopy.SCP_OPEN_TIME);
            -- Date fin
            aEndTime           := GetTime(tplGetPeriodToCopy.SCP_CLOSE_TIME);
            -- Calcul capacité heures
            aPeriodCapacity    := GetHourCapacity(aStartTime, aEndTime, tplGetPeriodToCopy.SCP_RESOURCE_NUMBER);
            -- Calcul capacité quantité
            aQtyCapacity       := GetqtyCapacity(aStartTime, aEndTime, tplGetPeriodToCopy.SCP_RESOURCE_NUMBER, tplGetPeriodToCopy.SCP_PIECES_HOUR_CAP);

            begin
              PAC_I_PRC_SCHEDULE.InsertSchedulePeriod(iScheduleID         => aCalendarID
                                                    , iDate               => aDate
                                                    , iDayOfWeek          => ''
                                                    , iNonWorkingDay      => 0
                                                    , iStartTime          => aStartTime
                                                    , iEndTime            => aEndTime
                                                    , iComment            => PCS.PC_PUBLIC.TranslateWord('Créé/Modifié par l''analyse des charges')
                                                    , iFilter             => aFilter
                                                    , iFilterID           => aFilterID
                                                    , iResourceNumber     => tplGetPeriodToCopy.SCP_RESOURCE_NUMBER
                                                    , iResourceCapacity   => aPeriodCapacity
                                                    , iResourceCapQty     => aQtyCapacity
                                                    , iPiecesHourCap      => tplGetPeriodToCopy.SCP_PIECES_HOUR_CAP
                                                    , iDicSchPeriod1      => null
                                                    , iDicSchPeriod2      => null
                                                    , oErrorPeriodID      => aErrorPeriodID
                                                     );
            exception
              when others then
                begin
                  close crGetPeriodToCopy;

                  raise;
                end;
            end;

            -- Période suivante.
            fetch crGetPeriodToCopy
             into tplGetPeriodToCopy;

            -- Sortie de la boucle au changement de type de jour
            if CopiedPeriodOrder <> tplGetPeriodToCopy.ORDER_FIELD then
              exit;
            end if;
          end loop;

          close crGetPeriodToCopy;
        end if;
      end if;   -- Fin copie ou création des périodes de base

      -- Si un ajustement des péridoes a date doit être fait.
      if blnDoAdjustement = true then
        -- Récupération du nouveau nombre de période.
        select count(PAC_SCHEDULE_PERIOD_id)
             , sum(SCP_WORKING_TIME)
          into nbExistingPeriods
             , nTotalDayRessources
          from PAC_SCHEDULE_PERIOD
         where PAC_SCHEDULE_ID = aCalendarID
           and (   nvl(aFAL_FACTORY_FLOOR_ID, 0) = 0
                or FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID)
           and (   nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0
                or PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID)
           and (   nvl(aPAC_SUPPLIER_PARTNER_ID, 0) = 0
                or PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID)
           and (   nvl(aPAC_DEPARTMENT_ID, 0) = 0
                or PAC_DEPARTMENT_ID = aPAC_DEPARTMENT_ID)
           and (   nvl(aHRM_PERSON_ID, 0) = 0
                or HRM_PERSON_ID = aHRM_PERSON_ID)
           and SCP_DATE is not null
           and trunc(SCP_DATE) = trunc(aDate);

        blnLastDayPeriod    := true;
        nCapacityRemainder  := (aNewCapacityHour - nTotalDayRessources) / 24;

        -- Augmentation de capacité.
        if nCapacityRemainder > 0 then
          open crAdjustPeriodsIncrease;

          fetch crAdjustPeriodsIncrease
           into tplAdjustPeriodsIncrease;

          loop
            if crAdjustPeriodsIncrease%found then
              nbExistingPeriods  := nbExistingPeriods - 1;

              -- Augmentation de la dernière période en direction de la fin de la journée, ou date début de la prochaine période.
              if     blnLastDayPeriod = true
                 and nbExistingPeriods > 0 then
                nFreeCapacity  := cstMaxDayCapacity - tplAdjustPeriodsIncrease.SCP_CLOSE_TIME;
              elsif     blnLastDayPeriod = true
                    and nbExistingPeriods = 0 then
                nFreeCapacity  := cstMaxDayCapacity -(tplAdjustPeriodsIncrease.SCP_CLOSE_TIME - tplAdjustPeriodsIncrease.SCP_OPEN_TIME);
              elsif     blnLastDayPeriod = false
                    and nbExistingPeriods > 0 then
                nFreeCapacity  := tplAdjustPeriodsIncrease.SCP_CLOSE_TIME - nLastPeriodStartTime;
              elsif     blnLastDayPeriod = false
                    and nbExistingPeriods = 0 then
                nFreeCapacity  := tplAdjustPeriodsIncrease.SCP_OPEN_TIME;
              end if;

              -- On peut combler complétement
              if nFreeCapacity >= nCapacityRemainder then
                if nbExistingPeriods > 0 then
                  -- Formatage de la date début
                  aStartTime  := GetTime(tplAdjustPeriodsIncrease.SCP_OPEN_TIME);
                  -- Calcul de la nouvelle date de fin
                  aEndTime    := GetTime(tplAdjustPeriodsIncrease.SCP_CLOSE_TIME + nCapacityRemainder);
                else
                  if blnLastDayPeriod = false then
                    -- Calcul dates début et fin
                    if nLastPeriodStartTime - tplAdjustPeriodsIncrease.SCP_CLOSE_TIME > nCapacityRemainder then
                      aStartTime  := GetTime(tplAdjustPeriodsIncrease.SCP_OPEN_TIME);
                      aEndTime    := GetTime(tplAdjustPeriodsIncrease.SCP_CLOSE_TIME + nCapacityRemainder);
                    else
                      aStartTime  :=
                        GetTime(tplAdjustPeriodsIncrease.SCP_OPEN_TIME
                                -(nCapacityRemainder -(nLastPeriodStartTime - tplAdjustPeriodsIncrease.SCP_CLOSE_TIME) ) );
                      aEndTime    := GetTime(nLastPeriodStartTime);
                    end if;
                  else
                    -- Calcul dates début et fin
                    if cstMaxDayCapacity - tplAdjustPeriodsIncrease.SCP_CLOSE_TIME > nCapacityRemainder then
                      aStartTime  := GetTime(tplAdjustPeriodsIncrease.SCP_OPEN_TIME);
                      aEndTime    := GetTime(tplAdjustPeriodsIncrease.SCP_CLOSE_TIME + nCapacityRemainder);
                    else
                      aStartTime  :=
                         GetTime(tplAdjustPeriodsIncrease.SCP_OPEN_TIME -(nCapacityRemainder -(cstMaxDayCapacity - tplAdjustPeriodsIncrease.SCP_CLOSE_TIME) ) );
                      aEndTime    := GetTime(cstMaxDayCapacity);
                    end if;
                  end if;
                end if;

                -- Calcul de la capacité
                aPeriodCapacity     := GetHourCapacity(aStartTime, aEndTime, aNewResourceNumber);
                -- Calcul de la capacité en qté
                aQtyCapacity        := GetQtyCapacity(aStartTime, aEndTime, aNewResourceNumber, aNewCapacityQty);

                declare
                  lFilter   varchar2(30);
                  lFilterID number(12);
                begin
                  GetCalendarFilter(tplAdjustPeriodsIncrease.FAL_FACTORY_FLOOR_ID
                                  , tplAdjustPeriodsIncrease.PAC_SUPPLIER_PARTNER_ID
                                  , tplAdjustPeriodsIncrease.PAC_CUSTOM_PARTNER_ID
                                  , tplAdjustPeriodsIncrease.PAC_DEPARTMENT_ID
                                  , tplAdjustPeriodsIncrease.HRM_PERSON_ID
                                  , lFilter
                                  , lFilterID
                                   );
                  PAC_I_PRC_SCHEDULE.UpdateSchedulePeriod(iPeriodID           => tplAdjustPeriodsIncrease.PAC_SCHEDULE_PERIOD_id
                                                        , iDate               => tplAdjustPeriodsIncrease.SCP_DATE
                                                        , iDayOfWeek          => tplAdjustPeriodsIncrease.C_DAY_OF_WEEK
                                                        , iNonWorkingDay      => 0
                                                        , iStartTime          => aStartTime
                                                        , iEndTime            => aEndTime
                                                        , iComment            => tplAdjustPeriodsIncrease.SCP_COMMENT
                                                        , iFilter             => lFilter
                                                        , iFilterID           => lFilterID
                                                        , iResourceNumber     => aNewResourceNumber
                                                        , iResourceCapacity   => aPeriodCapacity
                                                        , iResourceCapQty     => aQtyCapacity
                                                        , iPiecesHourCap      => aNewCapacityQty
                                                        , iDicSchPeriod1      => tplAdjustPeriodsIncrease.DIC_SCH_PERIOD_1_ID
                                                        , iDicSchPeriod2      => tplAdjustPeriodsIncrease.DIC_SCH_PERIOD_2_ID
                                                        , oErrorPeriodID      => aErrorPeriodID
                                                         );
                exception
                  when others then
                    begin
                      close crAdjustPeriodsIncrease;

                      raise;
                    end;
                end;

                nCapacityRemainder  := 0;
              -- On Comble Partiellement
              else
                -- Si pas derniere période
                if nbExistingPeriods > 0 then
                  -->  Formatage de la date de Début
                  aStartTime  := GetTime(tplAdjustPeriodsIncrease.SCP_OPEN_TIME);
                  -->  Calcul de la nouvelle date de fin.
                  aEndTime    := GetTime(tplAdjustPeriodsIncrease.SCP_CLOSE_TIME + nFreeCapacity);
                -- Si Derniere période
                elsif nbExistingPeriods > 0 then
                  --> Calcul de la nouvelle date de début.
                  aStartTime  := GetTime(tplAdjustPeriodsIncrease.SCP_OPEN_TIME - nFreeCapacity);
                  --> Formatage de la date fin
                  aEndTime    := GetTime(tplAdjustPeriodsIncrease.SCP_CLOSE_TIME);
                end if;

                --> Calcul de la capacité heures
                aPeriodCapacity       := GetHourCapacity(aStartTime, aEndTime, aNewResourceNumber);
                --> Calcul de la capacité quantité
                aQtyCapacity          := GetQtyCapacity(aStartTime, aEndTime, aNewResourceNumber, aNewCapacityQty);

                declare
                  lFilter   varchar2(30);
                  lFilterID number(12);
                begin
                  GetCalendarFilter(tplAdjustPeriodsIncrease.FAL_FACTORY_FLOOR_ID
                                  , tplAdjustPeriodsIncrease.PAC_SUPPLIER_PARTNER_ID
                                  , tplAdjustPeriodsIncrease.PAC_CUSTOM_PARTNER_ID
                                  , tplAdjustPeriodsIncrease.PAC_DEPARTMENT_ID
                                  , tplAdjustPeriodsIncrease.HRM_PERSON_ID
                                  , lFilter
                                  , lFilterID
                                   );
                  PAC_I_PRC_SCHEDULE.UpdateSchedulePeriod(iPeriodID           => tplAdjustPeriodsIncrease.PAC_SCHEDULE_PERIOD_id
                                                        , iDate               => tplAdjustPeriodsIncrease.SCP_DATE
                                                        , iDayOfWeek          => tplAdjustPeriodsIncrease.C_DAY_OF_WEEK
                                                        , iNonWorkingDay      => 0
                                                        , iStartTime          => aStartTime
                                                        , iEndTime            => aEndTime
                                                        , iComment            => tplAdjustPeriodsIncrease.SCP_COMMENT
                                                        , iFilter             => lFilter
                                                        , iFilterID           => lFilterID
                                                        , iResourceNumber     => aNewResourceNumber
                                                        , iResourceCapacity   => aPeriodCapacity
                                                        , iResourceCapQty     => aQtyCapacity
                                                        , iPiecesHourCap      => aNewCapacityQty
                                                        , iDicSchPeriod1      => tplAdjustPeriodsIncrease.DIC_SCH_PERIOD_1_ID
                                                        , iDicSchPeriod2      => tplAdjustPeriodsIncrease.DIC_SCH_PERIOD_2_ID
                                                        , oErrorPeriodID      => aErrorPeriodID
                                                         );
                exception
                  when others then
                    begin
                      close crAdjustPeriodsIncrease;

                      raise;
                    end;
                end;

                nLastPeriodStartTime  := tplAdjustPeriodsIncrease.SCP_OPEN_TIME;

                if nbExistingPeriods > 0 then
                  nCapacityRemainder  := nCapacityRemainder - nFreeCapacity;
                else
                  nCapacityRemainder  := 0;
                end if;
              end if;   -- Fin on comble partiellement

              if nCapacityRemainder <= 0 then
                exit;
              end if;
            else
              exit;
            end if;

            fetch crAdjustPeriodsIncrease
             into tplAdjustPeriodsIncrease;

            blnLastDayPeriod  := false;
          end loop;

          close crAdjustPeriodsIncrease;
        -- Diminution de capacité.
        elsif nCapacityRemainder < 0 then
          nCapacityRemainder  := aNewCapacityHour / 24;

          open crAdjustPeriodsDecrease;

          fetch crAdjustPeriodsDecrease
           into tplAdjustPeriodsDecrease;

          loop
            if crAdjustPeriodsDecrease%found then
              -- Si ResteCapaSouhaitée = 0 Suppression de la période
              if nCapacityRemainder = 0 then
                delete from PAC_SCHEDULE_PERIOD
                      where PAC_SCHEDULE_PERIOD_id = tplAdjustPeriodsDecrease.PAC_SCHEDULE_PERIOD_id;
              -- Sinon si resteCapaSouhiatée < Durée de la période, adaptation de celle-ci
              elsif tplAdjustPeriodsDecrease.SCP_RESOURCE_CAPACITY / 24 > nCapacityRemainder then
                --> Calcul de la nouvelle date de début.
                aStartTime          := GetTime(tplAdjustPeriodsDecrease.SCP_OPEN_TIME);
                --> Formatage de la date fin
                aEndTime            := GetTime(tplAdjustPeriodsDecrease.SCP_OPEN_TIME + nCapacityRemainder);
                --> Calcul de la capacité heures
                aPeriodCapacity     := GetHourCapacity(aStartTime, aEndTime, aNewResourceNumber);
                --> Calcul de la capacité quantité
                aQtyCapacity        := GetQtyCapacity(aStartTime, aEndTime, aNewResourceNumber, aNewCapacityQty);

                declare
                  lFilter   varchar2(30);
                  lFilterID number(12);
                begin
                  GetCalendarFilter(tplAdjustPeriodsIncrease.FAL_FACTORY_FLOOR_ID
                                  , tplAdjustPeriodsIncrease.PAC_SUPPLIER_PARTNER_ID
                                  , tplAdjustPeriodsIncrease.PAC_CUSTOM_PARTNER_ID
                                  , tplAdjustPeriodsIncrease.PAC_DEPARTMENT_ID
                                  , tplAdjustPeriodsIncrease.HRM_PERSON_ID
                                  , lFilter
                                  , lFilterID
                                   );
                  PAC_I_PRC_SCHEDULE.UpdateSchedulePeriod(iPeriodID           => tplAdjustPeriodsDecrease.PAC_SCHEDULE_PERIOD_id
                                                        , iDate               => tplAdjustPeriodsDecrease.SCP_DATE
                                                        , iDayOfWeek          => tplAdjustPeriodsDecrease.C_DAY_OF_WEEK
                                                        , iNonWorkingDay      => 0
                                                        , iStartTime          => aStartTime
                                                        , iEndTime            => aEndTime
                                                        , iComment            => tplAdjustPeriodsDecrease.SCP_COMMENT
                                                        , iFilter             => lFilter
                                                        , iFilterID           => lFilterID
                                                        , iResourceNumber     => aNewResourceNumber
                                                        , iResourceCapacity   => aPeriodCapacity
                                                        , iResourceCapQty     => aQtyCapacity
                                                        , iPiecesHourCap      => aNewCapacityQty
                                                        , iDicSchPeriod1      => tplAdjustPeriodsDecrease.DIC_SCH_PERIOD_1_ID
                                                        , iDicSchPeriod2      => tplAdjustPeriodsDecrease.DIC_SCH_PERIOD_2_ID
                                                        , oErrorPeriodID      => aErrorPeriodID
                                                         );
                exception
                  when others then
                    begin
                      close crAdjustPeriodsDecrease;

                      raise;
                    end;
                end;

                nCapacityRemainder  := 0;
              -- Sinon, période suivante.
              else
                nCapacityRemainder  := nCapacityRemainder - tplAdjustPeriodsDecrease.SCP_RESOURCE_CAPACITY / 24;
              end if;
            else
              exit;
            end if;

            fetch crAdjustPeriodsDecrease
             into tplAdjustPeriodsDecrease;
          end loop;

          close crAdjustPeriodsDecrease;
        end if;   -- Fin diminution de capacité
      end if;   -- Fin Ajustement durée périodes

      -- Mise à jour des compteurs de capacité heures et périodes sur toutes les périodes du jour,
      -- et pas seulement celles qui ont été modifiée
      for tplAdjustPeriodsIncrease in crAdjustPeriodsIncrease loop
        -- Date Début
        aStartTime       := GetTime(tplAdjustPeriodsIncrease.SCP_OPEN_TIME);
        -- Date Fin
        aEndTime         := GetTime(tplAdjustPeriodsIncrease.SCP_CLOSE_TIME);
        -- Capacité en heure
        aPeriodCapacity  := GetHourCapacity(aStartTime, aEndTime, aNewResourceNumber);
        -- Capacité en quantité
        aQtyCapacity     := GetQtyCapacity(aStartTime, aEndTime, aNewResourceNumber, aNewCapacityQty);

        declare
          lFilter   varchar2(30);
          lFilterID number(12);
        begin
          GetCalendarFilter(tplAdjustPeriodsIncrease.FAL_FACTORY_FLOOR_ID
                          , tplAdjustPeriodsIncrease.PAC_SUPPLIER_PARTNER_ID
                          , tplAdjustPeriodsIncrease.PAC_CUSTOM_PARTNER_ID
                          , tplAdjustPeriodsIncrease.PAC_DEPARTMENT_ID
                          , tplAdjustPeriodsIncrease.HRM_PERSON_ID
                          , lFilter
                          , lFilterID
                           );
          --
          PAC_I_PRC_SCHEDULE.UpdateSchedulePeriod(iPeriodID           => tplAdjustPeriodsIncrease.PAC_SCHEDULE_PERIOD_ID
                                                , iDate               => tplAdjustPeriodsIncrease.SCP_DATE
                                                , iDayOfWeek          => tplAdjustPeriodsIncrease.C_DAY_OF_WEEK
                                                , iNonWorkingDay      => 0
                                                , iStartTime          => aStartTime
                                                , iEndTime            => aEndTime
                                                , iComment            => tplAdjustPeriodsIncrease.SCP_COMMENT
                                                , iFilter             => lFilter
                                                , iFilterID           => lFilterID
                                                , iResourceNumber     => aNewResourceNumber
                                                , iResourceCapacity   => aPeriodCapacity
                                                , iResourceCapQty     => aQtyCapacity
                                                , iPiecesHourCap      => aNewCapacityQty
                                                , iDicSchPeriod1      => tplAdjustPeriodsIncrease.DIC_SCH_PERIOD_1_ID
                                                , iDicSchPeriod2      => tplAdjustPeriodsIncrease.DIC_SCH_PERIOD_2_ID
                                                , oErrorPeriodID      => aErrorPeriodID
                                                 );
        end;
      end loop;
    end if;   -- Fin vérification des paramètres d'entrée
  end UpdateCapacityAndResource;
end FAL_SCHEDULE_FUNCTIONS;
