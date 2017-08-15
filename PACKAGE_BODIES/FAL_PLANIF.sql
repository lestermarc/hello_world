--------------------------------------------------------
--  DDL for Package Body FAL_PLANIF
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PLANIF" 
is
  /**
  * function GetScheduleId
  * Description
  *    Recherche dans la table des calendriers chargés l'Id du calendrier correspondant à l'atelier ou au sous-traitant.
  *    L'Id du calendrier peut être identique à un Id d'atelier (FAL_FACTORY_FLOOR_ID), de sous-traitant, (PAC_SUPPLIER_PARTNER_ID)
  *    ou de calendrier (PAC_SCHEDULE_ID). Voir la procédure LoadAllResourcesSchedules.
  *    Si non trouvé, on recherche le calendrier de la ressource et on l'ajoute à la table FScheduleLoaded.
  * @created CLG
  * @lastUpdate
  * @public
  * @param iFalFactoryFloorId    : Id d'atelier
  * @param iPacSupplierPartnerId : Id de sous-traitant
  * @return : Id de calendrier de la table FTabSchedulePeriodAsc ou FTabSchedulePeriodDesc
  */
  function GetScheduleId(iFalFactoryFloorId in number, iPacSupplierPartnerId in number)
    return number
  is
    lnScheduleId number;
  begin
    if FScheduleLoaded.count > 0 then
      for i in FScheduleLoaded.first .. FScheduleLoaded.last loop
        if FScheduleLoaded(i).RESSOURCE_ID = nvl(iFalFactoryFloorId, iPacSupplierPartnerId) then
          return FScheduleLoaded(i).SCHEDULE_ID;
        end if;
      end loop;
    end if;

    -- Ressource non trouvée, on va chercher son calendrier et l'ajouter au tableau des calendriers chargés
    FScheduleLoaded.extend;

    if iFalFactoryFloorId is not null then
      lnScheduleId                                        := FAL_SCHEDULE_FUNCTIONS.GetFloorCalendar(iFalFactoryFloorId);
      FScheduleLoaded(FScheduleLoaded.last).RESSOURCE_ID  := iFalFactoryFloorId;
    else
      lnScheduleId                                        := FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendar(iPacSupplierPartnerId);
      FScheduleLoaded(FScheduleLoaded.last).RESSOURCE_ID  := iPacSupplierPartnerId;
    end if;

    FScheduleLoaded(FScheduleLoaded.last).SCHEDULE_ID  := lnScheduleId;
    return lnScheduleId;
  end GetScheduleId;

  /**
  * function GetCalendarIndex
  * Description
  *    Recherche l'index dans la table FTabSchedulePeriodAsc ou FTabSchedulePeriodDesc des exceptions calendrier
  *    correspondant à l'atelier ou au sous-traitant.
  * @created CLG
  * @lastUpdate
  * @public
  * @param iFalFactoryFloorId    : Id d'atelier
  * @param iPacSupplierPartnerId : Id de sous-traitant
  * @param iForward              : Recherche en avant (dans FTabSchedulePeriodAsc) ou arrière (dans FTabSchedulePeriodDesc)
  * @return : Id de calendrier de la table FTabSchedulePeriodAsc ou FTabSchedulePeriodDesc
  */
  function GetCalendarIndex(iFalFactoryFloorId in number, iPacSupplierPartnerId in number, iForward in boolean)
    return integer
  is
    lnScheduleId number;
  begin
    if     iFalFactoryFloorId is null
       and iPacSupplierPartnerId is null then
      return -1;
    end if;

    lnScheduleId  := GetScheduleId(iFalFactoryFloorId, iPacSupplierPartnerId);

    if iForward then
      if FTabSchedulePeriodAsc.count > 0 then
        for i in FTabSchedulePeriodAsc.first .. FTabSchedulePeriodAsc.last loop
          if FTabSchedulePeriodAsc(i).SCHEDULE_ID = lnScheduleId then
            return i;
          end if;
        end loop;
      end if;
    else
      if FTabSchedulePeriodDesc.count > 0 then
        for i in FTabSchedulePeriodDesc.first .. FTabSchedulePeriodDesc.last loop
          if FTabSchedulePeriodDesc(i).SCHEDULE_ID = lnScheduleId then
            return i;
          end if;
        end loop;
      end if;
    end if;

    return -1;
  end GetCalendarIndex;

  /**
  *  procedure GetValuesCalendar
  *  Description
  *    - Si on est pas dans une période active ou que aTypePeriod = ctNextPeriod,
  *    on recherche le début de la période active. Sinon (aDay se trouve dans une période
  *    active et aTypePeriod = ctActivePeriod) aDay ne change pas.
  *    - La procédure retourne de plus la capacité en minute restant sur la période.
  *
  * @created ECA
  * @lastUpdate age 24.07.2013
  * @private
  * @param   FalFactoryFloorId : Atelier
  * @param   PacSupplierPartnerId : fournisseur
  * @param   aTypePeriod : Période active ou prochaine
  * @param   aDay : Renvoie la date
  * @param   CapacityMinute : et la capacité restante en minute
  * @param   aForward : Recherche sur liste de périodes avant ou arrière
  * @param   aPeriodStartDate : Date début de la période courante
  * @param   aPeriodEndDate : Date Fin de la période courante
  */
  procedure GetValuesCalendar(
    aFalFactoryFloorId    in     number default null
  , aPacSupplierPartnerId in     number default null
  , aTypePeriod           in     integer
  , aDay                  in out date
  , aCapacityMinute       in out number
  , aForward              in     boolean default true
  , aPeriodStartDate      in out date
  , aPeriodEndDate        in out date
  )
  is
    aDate               date;
    aPeriodFounded      boolean;
    aPeriodBeginDate    date;
    aPeriodEndingDate   date;
    LocTypePeriod       integer;
    blnExceptionFounded boolean;
    lnScheduleId        number;
    liFirstIdx          integer;
    liSchIdx            integer;
  begin
    aDate           := aDay;
    aPeriodFounded  := false;
    LocTypePeriod   := aTypePeriod;
    liFirstIdx      := GetCalendarIndex(aFalFactoryFloorId, aPacSupplierPartnerId, aForward);

    if liFirstIdx = -1 then
      return;
    end if;

    if aForward then
      lnScheduleId  := FTabSchedulePeriodAsc(liFirstIdx).SCHEDULE_ID;

      loop
        blnExceptionFounded  := false;
        liSchIdx             := liFirstIdx;

        -- Condition de sortie : Tous les horaires de la ressource ont été parcourus ou l'horaire recherché a été trouvé
        while(not aPeriodFounded)
         and (liSchIdx <= FTabSchedulePeriodAsc.last)
         and (lnScheduleId = FTabSchedulePeriodAsc(liSchIdx).SCHEDULE_ID) loop
          -- Exception sur le jour recherché
          if     FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE is not null
             and trunc(FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE) = trunc(aDate) then
            aPeriodBeginDate     := trunc(FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE) + FTabSchedulePeriodAsc(liSchIdx).aSCP_OPEN_TIME;
            aPeriodEndingDate    := trunc(FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE) + FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME;
            blnExceptionFounded  := true;

            if FTabSchedulePeriodAsc(liSchIdx).aSCP_NONWORKING_DAY <> 1 then
              -- Si recherche période active
              if     LocTypePeriod = ctActivePeriod
                 and aPeriodBeginDate <= aDate
                 and aDate <= aPeriodEndingDate then
                aPeriodFounded    := true;
                aPeriodBeginDate  := aDate;
                aCapacityMinute   := round( (aPeriodEndingDate - aPeriodBeginDate) * 1440, 0);
              -- Si recherche prochaine période
              elsif     LocTypePeriod = ctNextPeriod
                    and aPeriodBeginDate > aDate then
                aPeriodFounded   := true;
                aCapacityMinute  := round( (aPeriodEndingDate - aPeriodBeginDate) * 1440, 0);
              end if;
            else
              exit;
            end if;
          -- Jour recherché
          elsif     not blnExceptionFounded
                and FTabSchedulePeriodAsc(liSchIdx).aC_DAY_OF_WEEK is not null
                and FTabSchedulePeriodAsc(liSchIdx).aC_DAY_OF_WEEK = to_char(aDate, 'DY') then
            aPeriodBeginDate   := trunc(aDate) + FTabSchedulePeriodAsc(liSchIdx).aSCP_OPEN_TIME;
            aPeriodEndingDate  := trunc(aDate) + FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME;

            if FTabSchedulePeriodAsc(liSchIdx).aSCP_NONWORKING_DAY <> 1 then
              -- Si recherche période active
              if     LocTypePeriod = ctActivePeriod
                 and aPeriodBeginDate <= round(aDay, 'mi')
                 and round(aDay, 'mi') <= aPeriodEndingDate then
                aPeriodFounded    := true;
                aPeriodBeginDate  := aDate;
                aCapacityMinute   := round( (aPeriodEndingDate - aPeriodBeginDate) * 1440, 0);
              -- Si recherche prochaine période
              elsif     LocTypePeriod = ctNextPeriod
                    and aPeriodBeginDate > round(aDay, 'mi') then
                aPeriodFounded   := true;
                aCapacityMinute  := round( (aPeriodEndingDate - aPeriodBeginDate) * 1440, 0);
              end if;
            else
              exit;
            end if;
          end if;

          liSchIdx  := liSchIdx + 1;
        end loop;

        if aPeriodFounded then
          aDay              := aPeriodbeginDate;
          aPeriodStartDate  := aPeriodbeginDate;
          aPeriodEndDate    := aPeriodEndingDate;
          exit;
        else
          -- Si on cherchait la période active et que l'on ne l'a pas trouvé, on recherche la prochaine période pour la date.
          if aTypePeriod = ctActivePeriod then
            if LocTypePeriod = ctActivePeriod then
              LocTypePeriod  := ctNextPeriod;
            else
              aDate  := trunc(aDate) + 1;
            end if;
          -- Sinon on incrémente la date
          else
            aDate  := trunc(aDate) + 1;
          end if;
        end if;
      end loop;
    -- Recherche arrière
    else
      lnScheduleId  := FTabSchedulePeriodDesc(liFirstIdx).SCHEDULE_ID;

      loop
        blnExceptionFounded  := false;
        liSchIdx             := liFirstIdx;

        -- Condition de sortie : Tous les horaires de la ressource ont été parcourus ou l'horaire recherché a été trouvé
        while(not aPeriodFounded)
         and (liSchIdx <= FTabSchedulePeriodDesc.last)
         and (lnScheduleId = FTabSchedulePeriodDesc(liSchIdx).SCHEDULE_ID) loop
          -- Exception sur le jour recherché
          if     FTabSchedulePeriodDesc(liSchIdx).aSCP_DATE is not null
             and trunc(FTabSchedulePeriodDesc(liSchIdx).aSCP_DATE) = trunc(aDate) then
            aPeriodBeginDate     := trunc(FTabSchedulePeriodDesc(liSchIdx).aSCP_DATE) + FTabSchedulePeriodDesc(liSchIdx).aSCP_OPEN_TIME;
            aPeriodEndingDate    := trunc(FTabSchedulePeriodDesc(liSchIdx).aSCP_DATE) + FTabSchedulePeriodDesc(liSchIdx).aSCP_CLOSE_TIME;
            blnExceptionFounded  := true;

            if FTabSchedulePeriodDesc(liSchIdx).aSCP_NONWORKING_DAY <> 1 then
              -- Si recherche période active
              if     LocTypePeriod = ctActivePeriod
                 and aPeriodBeginDate <= aDate
                 and aDate <= aPeriodEndingDate then
                aPeriodFounded     := true;
                aPeriodEndingDate  := aDate;
                aCapacityMinute    := round( (aPeriodEndingDate - aPeriodBeginDate) * 1440, 0);
              -- Si recherche prochaine période
              elsif     LocTypePeriod = ctNextPeriod
                    and aPeriodEndingDate < aDate then
                aPeriodFounded   := true;
                aCapacityMinute  := round( (aPeriodEndingDate - aPeriodBeginDate) * 1440, 0);
              end if;
            else
              exit;
            end if;
          -- Jour recherché
          elsif     not blnExceptionFounded
                and FTabSchedulePeriodDesc(liSchIdx).aC_DAY_OF_WEEK is not null
                and FTabSchedulePeriodDesc(liSchIdx).aC_DAY_OF_WEEK = to_char(aDate, 'DY') then
            aPeriodBeginDate   := trunc(aDate) + FTabSchedulePeriodDesc(liSchIdx).aSCP_OPEN_TIME;
            aPeriodEndingDate  := trunc(aDate) + FTabSchedulePeriodDesc(liSchIdx).aSCP_CLOSE_TIME;

            if FTabSchedulePeriodDesc(liSchIdx).aSCP_NONWORKING_DAY <> 1 then
              -- Si recherche période active
              if     LocTypePeriod = ctActivePeriod
                 and aPeriodBeginDate <= round(aDay, 'mi')
                 and round(aDay, 'mi') <= aPeriodEndingDate then
                aPeriodFounded     := true;
                aPeriodEndingDate  := aDate;
                aCapacityMinute    := round( (aPeriodEndingDate - aPeriodBeginDate) * 1440, 0);
              -- Si recherche prochaine période
              elsif     LocTypePeriod = ctNextPeriod
                    and aPeriodEndingDate < round(aDay, 'mi') then
                aPeriodFounded   := true;
                aCapacityMinute  := round( (aPeriodEndingDate - aPeriodBeginDate) * 1440, 0);
              end if;
            else
              exit;
            end if;
          end if;

          liSchIdx  := liSchIdx + 1;
        end loop;

        if aPeriodFounded then
          aDay              := aPeriodEndingDate;
          aPeriodStartDate  := aPeriodbeginDate;
          aPeriodEndDate    := aPeriodEndingDate;
          exit;
        else
          -- Si on cherchait la période active et que l'on ne l'a pas trouvé, on recherche la période précédente pour la date.
          if aTypePeriod = ctActivePeriod then
            if LocTypePeriod = ctActivePeriod then
              LocTypePeriod  := ctNextPeriod;
            else
              aDate  := trunc(aDate) - 1 / 1440;
            end if;
          -- Sinon on décrémente la date
          else
            aDate  := trunc(aDate) - 1 / 1440;
          end if;
        end if;
      end loop;
    end if;
  end GetValuesCalendar;

  /**
  *  function IsOpenDay
  *  Description
  *    Indique si le jour passé en paramètre est ouvert ou pas.
  *    Si aucun atelier/fournisseur n'est transmis, on considère que le jour est ouvré.
  * @created ECA
  * @lastUpdate
  * @private
  * @param   FalFactoryFloorId : Atelier
  * @param   PacSupplierPartnerId : fournisseur
  * @param   aDate : Date
  * @return  0 / 1
  */
  function IsOpenDay(aFalFactoryFloorId number, aPacSupplierPartnerId number, aDate in date)
    return integer
  is
    lnScheduleId number;
    liSchIdx     integer;
  begin
    liSchIdx      := GetCalendarIndex(aFalFactoryFloorId, aPacSupplierPartnerId, true);

    if liSchIdx = -1 then
      return 1;
    end if;

    lnScheduleId  := FTabSchedulePeriodAsc(liSchIdx).SCHEDULE_ID;

    while(liSchIdx <= FTabSchedulePeriodAsc.last)
     and (lnScheduleId = FTabSchedulePeriodAsc(liSchIdx).SCHEDULE_ID) loop
      -- Recherche sur les dates
      if trunc(FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE) = trunc(aDate) then
        -- Une date non ouvrée à été trouvé sur la date recherchée (les exceptions sont toujours en premier).
        if FTabSchedulePeriodAsc(liSchIdx).aSCP_NONWORKING_DAY = 1 then
          return 0;
        -- Une date ouvrée à été trouvé sur la date recherchée (les exceptions sont toujours en premier).
        else
          return 1;
        end if;
      end if;

      -- Recherche sur les jours
      if FTabSchedulePeriodAsc(liSchIdx).aC_DAY_OF_WEEK = to_char(aDate, 'DY') then
        if FTabSchedulePeriodAsc(liSchIdx).aSCP_NONWORKING_DAY = 1 then
          -- Un jour non ouvré à été trouvé sur le jour recherché.
          return 0;
        else
          -- Un jour ouvré à été trouvé sur le jour recherché.
          return 1;
        end if;
      end if;

      liSchIdx  := liSchIdx + 1;
    end loop;

    return 1;
  end IsOpenDay;

  /**
  *  function GetDateRemainCapacity
  *  Description
  *    Renvoie la capacité restante en minute de la date a Date , pour une ressource, à partir d'une date donnée.
  * @created ECA
  * @lastUpdate age 24.07.2013
  * @private
  * @param   FalFactoryFloorId : Atelier
  * @param   PacSupplierPartnerId : fournisseur
  * @param   aDate : jour
  */
  function GetDateRemainCapacity(aFalFactoryFloorId number, aPacSupplierPartnerId number, aDate in date)
    return number
  is
    aDateCapacityInMinutes number;
    blnExceptionFounded    boolean;
    lnScheduleId           number;
    liSchIdx               integer;
  begin
    blnExceptionFounded     := false;
    aDateCapacityInMinutes  := 0;
    liSchIdx                := GetCalendarIndex(aFalFactoryFloorId, aPacSupplierPartnerId, true);

    if liSchIdx = -1 then
      return 0;
    end if;

    lnScheduleId            := FTabSchedulePeriodAsc(liSchIdx).SCHEDULE_ID;

    while(liSchIdx <= FTabSchedulePeriodAsc.last)
     and (lnScheduleId = FTabSchedulePeriodAsc(liSchIdx).SCHEDULE_ID) loop
      -- Une exception à été trouvée pour la date recherchée
      if     FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE is not null
         and trunc(FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE) = trunc(aDate) then
        blnExceptionFounded  := true;

        -- La période ferme au dela de la date de la recherche.
        if trunc(FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE) + FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME > aDate then
          if FTabSchedulePeriodAsc(liSchIdx).aSCP_NONWORKING_DAY <> 1 then
            -- la date est au sein de la période
            if trunc(FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE) + FTabSchedulePeriodAsc(liSchIdx).aSCP_OPEN_TIME < aDate then
              aDateCapacityInMinutes  :=
                aDateCapacityInMinutes +
                round( (trunc(FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE) + FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME - aDate) * 1440, 0);
            -- La période est après la date
            else
              aDateCapacityInMinutes  :=
                    aDateCapacityInMinutes + round( (FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME - FTabSchedulePeriodAsc(liSchIdx).aSCP_OPEN_TIME) * 1440
                                                 , 0);
            end if;
          else
            return 0;
          end if;
        end if;
      -- Aucune exception trouvée, recherche sur les jours.
      elsif     not blnExceptionFounded
            and FTabSchedulePeriodAsc(liSchIdx).aC_DAY_OF_WEEK is not null
            and FTabSchedulePeriodAsc(liSchIdx).aC_DAY_OF_WEEK = to_char(aDate, 'DY')
            and trunc(aDate) + FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME > aDate then
        if FTabSchedulePeriodAsc(liSchIdx).aSCP_NONWORKING_DAY <> 1 then
          -- la date est au sein de la période
          if trunc(aDate) + FTabSchedulePeriodAsc(liSchIdx).aSCP_OPEN_TIME < aDate then
            aDateCapacityInMinutes  := aDateCapacityInMinutes + round( (trunc(aDate) + FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME - aDate) * 1440, 0);
          -- La période est après la date
          else
            aDateCapacityInMinutes  :=
                    aDateCapacityInMinutes + round( (FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME - FTabSchedulePeriodAsc(liSchIdx).aSCP_OPEN_TIME) * 1440
                                                 , 0);
          end if;
        else
          return 0;
        end if;
      end if;

      liSchIdx  := liSchIdx + 1;
    end loop;

    return aDateCapacityInMinutes;
  end GetDateRemainCapacity;

  /**
  *  function GetDateTotalCapacity
  *  Description
  *    Renvoie la capacité totale en minute d'une date donnée, pour une ressource.
  *
  * @created ECA
  * @lastUpdate age 24.07.2013
  * @private
  * @param   FalFactoryFloorId : Atelier
  * @param   PacSupplierPartnerId : fournisseur
  * @param   aDay : Renvoie la date
  * @param   CapacityMinute : et la capacité restante en minute
  */
  function GetDateTotalCapacity(aFalFactoryFloorId number, aPacSupplierPartnerId number, aDate in date)
    return number
  is
    aDateCapacityInMinutes number;
    blnExceptionFounded    boolean;
    lnScheduleId           number;
    liSchIdx               integer;
  begin
    blnExceptionFounded     := false;
    aDateCapacityInMinutes  := 0;
    liSchIdx                := GetCalendarIndex(aFalFactoryFloorId, aPacSupplierPartnerId, true);

    if liSchIdx = -1 then
      return 0;
    end if;

    lnScheduleId            := FTabSchedulePeriodAsc(liSchIdx).SCHEDULE_ID;

    while(liSchIdx <= FTabSchedulePeriodAsc.last)
     and (lnScheduleId = FTabSchedulePeriodAsc(liSchIdx).SCHEDULE_ID) loop
      -- Une exception à été trouvée pour la date recherchée
      if     FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE is not null
         and trunc(FTabSchedulePeriodAsc(liSchIdx).aSCP_DATE) = trunc(aDate) then
        blnExceptionFounded  := true;

        if FTabSchedulePeriodAsc(liSchIdx).aSCP_NONWORKING_DAY <> 1 then
          aDateCapacityInMinutes  :=
                    aDateCapacityInMinutes + round( (FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME - FTabSchedulePeriodAsc(liSchIdx).aSCP_OPEN_TIME) * 1440
                                                 , 0);
        else
          return 0;
        end if;
      -- Aucune exception trouvée, recherche sur les jours.
      elsif     not blnExceptionFounded
            and FTabSchedulePeriodAsc(liSchIdx).aC_DAY_OF_WEEK is not null
            and FTabSchedulePeriodAsc(liSchIdx).aC_DAY_OF_WEEK = to_char(aDate, 'DY') then
        if FTabSchedulePeriodAsc(liSchIdx).aSCP_NONWORKING_DAY <> 1 then
          aDateCapacityInMinutes  :=
                    aDateCapacityInMinutes + round( (FTabSchedulePeriodAsc(liSchIdx).aSCP_CLOSE_TIME - FTabSchedulePeriodAsc(liSchIdx).aSCP_OPEN_TIME) * 1440
                                                 , 0);
        else
          return 0;
        end if;
      end if;

      liSchIdx  := liSchIdx + 1;
    end loop;

    return aDateCapacityInMinutes;
  end GetDateTotalCapacity;

  /**
  * Procedure LoadAllResourcesSchedules
  * Description : Chargement en mémoire des horaires pour toutes les ressources qui contiennent des exceptions et pour les calendriers existants.
  *               On ne tient compte que des exceptions postérieures à la date du jour.
  *               La procédure remplit les tables FTabSchedulePeriodAsc et FTabSchedulePeriodDesc en listant les exceptions calendriers dans un ordre
  *               particulier (les exceptions jours en premier, ...) et en les groupant par calendrier.
  *               Un calendrier pour chaque ressource (FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID) est créé, ainsi qu'un calendrier pour chaque
  *               calendrier PAC_SCHEDULE_ID.
  *               La table FScheduleLoaded liste les calendriers chargés. Elle contient L'Id de la ressource et l'Id calendrier associé (celui-ci est le
  *               même que l'id de la ressource pour les ressources ayant des exceptions). Les ressources n'ayant pas d'exception seront ensuite liées
  *               à un PAC_SCHEDULE_ID (voir procédure GetScheduleId).
  * @created CLG
  * @lastUpdate
  * @Public
  */
  procedure LoadAllResourcesSchedules
  is
    lvSql varchar2(32000);
  begin
    if FScheduleLoaded is not null then
      return;
    end if;

    lvSql  :=
      ' select   * ' ||

      -- Exception DATE des calendriers standard
      '         from (select distinct SCP.C_DAY_OF_WEEK ' ||
      '                             , SCP.SCP_OPEN_TIME ' ||
      '                             , SCP.SCP_CLOSE_TIME ' ||
      '                             , SCP.SCP_DATE ' ||
      '                             , SCP.SCP_NONWORKING_DAY ' ||
      '                             , SCP.PAC_SCHEDULE_ID ' ||
      '                          from PAC_SCHEDULE_PERIOD SCP ' ||
      '                         where SCP.C_DAY_OF_WEEK is null ' ||
      '                           and SCP.SCP_DATE is not null ' ||
      '                           and trunc(SCP_DATE) >= trunc(sysdate) ' ||
      '                           and SCP.PAC_CUSTOM_PARTNER_ID is null ' ||
      '                           and SCP.HRM_PERSON_ID is null ' ||
      '                           and SCP.PAC_DEPARTMENT_ID is null ' ||
      '                           and SCP.FAL_FACTORY_FLOOR_ID is null ' ||
      '                           and SCP.PAC_SUPPLIER_PARTNER_ID is null ' ||
      '               union ' ||

      -- Exception JOUR des calendriers standard
      '               select distinct SCP.C_DAY_OF_WEEK ' ||
      '                             , SCP.SCP_OPEN_TIME ' ||
      '                             , SCP.SCP_CLOSE_TIME ' ||
      '                             , SCP.SCP_DATE ' ||
      '                             , SCP.SCP_NONWORKING_DAY ' ||
      '                             , SCP.PAC_SCHEDULE_ID ' ||
      '                          from PAC_SCHEDULE_PERIOD SCP ' ||
      '                         where SCP.C_DAY_OF_WEEK is not null ' ||
      '                           and SCP.SCP_DATE is null ' ||
      '                           and SCP.PAC_CUSTOM_PARTNER_ID is null ' ||
      '                           and SCP.HRM_PERSON_ID is null ' ||
      '                           and SCP.PAC_DEPARTMENT_ID is null ' ||
      '                           and SCP.FAL_FACTORY_FLOOR_ID is null ' ||
      '                           and SCP.PAC_SUPPLIER_PARTNER_ID is null ' ||
      '               union ' ||

      -- Exception DATE des calendriers FOURNISSEUR
      '               select distinct SCP.C_DAY_OF_WEEK ' ||
      '                             , SCP.SCP_OPEN_TIME ' ||
      '                             , SCP.SCP_CLOSE_TIME ' ||
      '                             , SCP.SCP_DATE ' ||
      '                             , SCP.SCP_NONWORKING_DAY ' ||
      '                             , RES.PAC_SUPPLIER_PARTNER_ID ' ||
      '                          from PAC_SCHEDULE_PERIOD SCP ' ||
      '                             , (select distinct SCH.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                              , nvl(SUP.PAC_SCHEDULE_ID, PAC_I_LIB_SCHEDULE.GetDefaultSchedule) SUP_SCHEDULE_ID ' ||
      '                                           from PAC_SCHEDULE_PERIOD SCH ' ||
      '                                              , PAC_SUPPLIER_PARTNER SUP ' ||
      '                                          where SCH.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                            and (   SCH.SCP_DATE is null ' ||
      '                                                 or trunc(SCH.SCP_DATE) >= trunc(sysdate) ) ' ||
      '                                            and SCH.PAC_SCHEDULE_ID = nvl(SUP.PAC_SCHEDULE_ID, PAC_I_LIB_SCHEDULE.GetDefaultSchedule) ) RES ' ||
      '                         where SCP.C_DAY_OF_WEEK is null ' ||
      '                           and SCP.SCP_DATE is not null ' ||
      '                           and trunc(SCP_DATE) >= trunc(sysdate) ' ||
      '                           and SCP.PAC_CUSTOM_PARTNER_ID is null ' ||
      '                           and SCP.HRM_PERSON_ID is null ' ||
      '                           and SCP.PAC_DEPARTMENT_ID is null ' ||
      '                           and SCP.FAL_FACTORY_FLOOR_ID is null ' ||
      '                           and RES.SUP_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                           and (    (    exists( ' ||
      '                                           select 1 ' ||
      '                                             from PAC_SCHEDULE_PERIOD SCP2 ' ||
      '                                            where SCP2.SCP_DATE is not null ' ||
      '                                              and SCP2.PAC_SUPPLIER_PARTNER_ID = RES.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                              and SCP2.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                                              and trunc(SCP2.SCP_DATE) = trunc(SCP.SCP_DATE) ) ' ||
      '                                     and SCP.PAC_SUPPLIER_PARTNER_ID = RES.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                    ) ' ||
      '                                or (    not exists( ' ||
      '                                          select 1 ' ||
      '                                            from PAC_SCHEDULE_PERIOD SCP2 ' ||
      '                                           where SCP2.SCP_DATE is not null ' ||
      '                                             and SCP2.PAC_SUPPLIER_PARTNER_ID = RES.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                             and SCP2.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                                             and trunc(SCP2.SCP_DATE) = trunc(SCP.SCP_DATE) ) ' ||
      '                                    and SCP.PAC_SUPPLIER_PARTNER_ID is null ' ||
      '                                   ) ' ||
      '                               ) ' ||
      '               union ' ||

      -- Exception JOUR des calendriers FOURNISSEUR
      '               select distinct SCP.C_DAY_OF_WEEK ' ||
      '                             , SCP.SCP_OPEN_TIME ' ||
      '                             , SCP.SCP_CLOSE_TIME ' ||
      '                             , SCP.SCP_DATE ' ||
      '                             , SCP.SCP_NONWORKING_DAY ' ||
      '                             , RES.PAC_SUPPLIER_PARTNER_ID ' ||
      '                          from PAC_SCHEDULE_PERIOD SCP ' ||
      '                             , (select distinct SCH.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                              , nvl(SUP.PAC_SCHEDULE_ID, PAC_I_LIB_SCHEDULE.GetDefaultSchedule) SUP_SCHEDULE_ID ' ||
      '                                           from PAC_SCHEDULE_PERIOD SCH ' ||
      '                                              , PAC_SUPPLIER_PARTNER SUP ' ||
      '                                          where SCH.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                            and (   SCH.SCP_DATE is null ' ||
      '                                                 or trunc(SCH.SCP_DATE) >= trunc(sysdate) ) ' ||
      '                                            and SCH.PAC_SCHEDULE_ID = nvl(SUP.PAC_SCHEDULE_ID, PAC_I_LIB_SCHEDULE.GetDefaultSchedule) ) RES ' ||
      '                         where SCP.C_DAY_OF_WEEK is not null ' ||
      '                           and SCP.SCP_DATE is null ' ||
      '                           and SCP.PAC_CUSTOM_PARTNER_ID is null ' ||
      '                           and SCP.HRM_PERSON_ID is null ' ||
      '                           and SCP.PAC_DEPARTMENT_ID is null ' ||
      '                           and SCP.FAL_FACTORY_FLOOR_ID is null ' ||
      '                           and RES.SUP_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                           and (    (    exists( ' ||
      '                                           select 1 ' ||
      '                                             from PAC_SCHEDULE_PERIOD SCP2 ' ||
      '                                            where SCP2.C_DAY_OF_WEEK is not null ' ||
      '                                              and SCP2.PAC_SUPPLIER_PARTNER_ID = RES.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                              and SCP2.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                                              and SCP2.C_DAY_OF_WEEK = SCP.C_DAY_OF_WEEK) ' ||
      '                                     and SCP.PAC_SUPPLIER_PARTNER_ID = RES.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                    ) ' ||
      '                                or (    not exists( ' ||
      '                                          select 1 ' ||
      '                                            from PAC_SCHEDULE_PERIOD SCP2 ' ||
      '                                           where SCP2.C_DAY_OF_WEEK is not null ' ||
      '                                             and SCP2.PAC_SUPPLIER_PARTNER_ID = RES.PAC_SUPPLIER_PARTNER_ID ' ||
      '                                             and SCP2.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                                             and SCP2.C_DAY_OF_WEEK = SCP.C_DAY_OF_WEEK) ' ||
      '                                    and SCP.PAC_SUPPLIER_PARTNER_ID is null ' ||
      '                                   ) ' ||
      '                               ) ' ||
      '               union ' ||

      -- Exception DATE des calendriers ATELIER
      '               select distinct SCP.C_DAY_OF_WEEK ' ||
      '                             , SCP.SCP_OPEN_TIME ' ||
      '                             , SCP.SCP_CLOSE_TIME ' ||
      '                             , SCP.SCP_DATE ' ||
      '                             , SCP.SCP_NONWORKING_DAY ' ||
      '                             , RES.FAL_FACTORY_FLOOR_ID ' ||
      '                          from PAC_SCHEDULE_PERIOD SCP ' ||
      '                             , (select distinct SCH.FAL_FACTORY_FLOOR_ID ' ||
      '                                              , nvl(SUP.PAC_SCHEDULE_ID, PAC_I_LIB_SCHEDULE.GetDefaultSchedule) SUP_SCHEDULE_ID ' ||
      '                                           from PAC_SCHEDULE_PERIOD SCH ' ||
      '                                              , FAL_FACTORY_FLOOR SUP ' ||
      '                                          where SCH.FAL_FACTORY_FLOOR_ID = SUP.FAL_FACTORY_FLOOR_ID ' ||
      '                                            and (   SCH.SCP_DATE is null ' ||
      '                                                 or trunc(SCH.SCP_DATE) >= trunc(sysdate) ) ' ||
      '                                            and SCH.PAC_SCHEDULE_ID = nvl(SUP.PAC_SCHEDULE_ID, PAC_I_LIB_SCHEDULE.GetDefaultSchedule) ) RES ' ||
      '                         where SCP.C_DAY_OF_WEEK is null ' ||
      '                           and SCP.SCP_DATE is not null ' ||
      '                           and trunc(SCP_DATE) >= trunc(sysdate) ' ||
      '                           and SCP.PAC_CUSTOM_PARTNER_ID is null ' ||
      '                           and SCP.HRM_PERSON_ID is null ' ||
      '                           and SCP.PAC_DEPARTMENT_ID is null ' ||
      '                           and SCP.PAC_SUPPLIER_PARTNER_ID is null ' ||
      '                           and RES.SUP_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                           and (    (    exists( ' ||
      '                                           select 1 ' ||
      '                                             from PAC_SCHEDULE_PERIOD SCP2 ' ||
      '                                            where SCP2.SCP_DATE is not null ' ||
      '                                              and SCP2.FAL_FACTORY_FLOOR_ID = RES.FAL_FACTORY_FLOOR_ID ' ||
      '                                              and SCP2.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                                              and trunc(SCP2.SCP_DATE) = trunc(SCP.SCP_DATE) ) ' ||
      '                                     and SCP.FAL_FACTORY_FLOOR_ID = RES.FAL_FACTORY_FLOOR_ID ' ||
      '                                    ) ' ||
      '                                or (    not exists( ' ||
      '                                          select 1 ' ||
      '                                            from PAC_SCHEDULE_PERIOD SCP2 ' ||
      '                                           where SCP2.SCP_DATE is not null ' ||
      '                                             and SCP2.FAL_FACTORY_FLOOR_ID = RES.FAL_FACTORY_FLOOR_ID ' ||
      '                                             and SCP2.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                                             and trunc(SCP2.SCP_DATE) = trunc(SCP.SCP_DATE) ) ' ||
      '                                    and SCP.FAL_FACTORY_FLOOR_ID is null ' ||
      '                                   ) ' ||
      '                               ) ' ||
      '               union ' ||

      -- Exception JOUR des calendriers ATELIER
      '               select distinct SCP.C_DAY_OF_WEEK ' ||
      '                             , SCP.SCP_OPEN_TIME ' ||
      '                             , SCP.SCP_CLOSE_TIME ' ||
      '                             , SCP.SCP_DATE ' ||
      '                             , SCP.SCP_NONWORKING_DAY ' ||
      '                             , RES.FAL_FACTORY_FLOOR_ID ' ||
      '                          from PAC_SCHEDULE_PERIOD SCP ' ||
      '                             , (select distinct SCH.FAL_FACTORY_FLOOR_ID ' ||
      '                                              , nvl(SUP.PAC_SCHEDULE_ID, PAC_I_LIB_SCHEDULE.GetDefaultSchedule) SUP_SCHEDULE_ID ' ||
      '                                           from PAC_SCHEDULE_PERIOD SCH ' ||
      '                                              , FAL_FACTORY_FLOOR SUP ' ||
      '                                          where SCH.FAL_FACTORY_FLOOR_ID = SUP.FAL_FACTORY_FLOOR_ID ' ||
      '                                            and (   SCH.SCP_DATE is null ' ||
      '                                                 or trunc(SCH.SCP_DATE) >= trunc(sysdate) ) ' ||
      '                                            and SCH.PAC_SCHEDULE_ID = nvl(SUP.PAC_SCHEDULE_ID, PAC_I_LIB_SCHEDULE.GetDefaultSchedule) ) RES ' ||
      '                         where SCP.C_DAY_OF_WEEK is not null ' ||
      '                           and SCP.SCP_DATE is null ' ||
      '                           and SCP.PAC_CUSTOM_PARTNER_ID is null ' ||
      '                           and SCP.HRM_PERSON_ID is null ' ||
      '                           and SCP.PAC_DEPARTMENT_ID is null ' ||
      '                           and SCP.PAC_SUPPLIER_PARTNER_ID is null ' ||
      '                           and RES.SUP_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                           and (    (    exists( ' ||
      '                                           select 1 ' ||
      '                                             from PAC_SCHEDULE_PERIOD SCP2 ' ||
      '                                            where SCP2.C_DAY_OF_WEEK is not null ' ||
      '                                              and SCP2.FAL_FACTORY_FLOOR_ID = RES.FAL_FACTORY_FLOOR_ID ' ||
      '                                              and SCP2.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                                              and SCP2.C_DAY_OF_WEEK = SCP.C_DAY_OF_WEEK) ' ||
      '                                     and SCP.FAL_FACTORY_FLOOR_ID = RES.FAL_FACTORY_FLOOR_ID ' ||
      '                                    ) ' ||
      '                                or (    not exists( ' ||
      '                                          select 1 ' ||
      '                                            from PAC_SCHEDULE_PERIOD SCP2 ' ||
      '                                           where SCP2.C_DAY_OF_WEEK is not null ' ||
      '                                             and SCP2.FAL_FACTORY_FLOOR_ID = RES.FAL_FACTORY_FLOOR_ID ' ||
      '                                             and SCP2.PAC_SCHEDULE_ID = SCP.PAC_SCHEDULE_ID ' ||
      '                                             and SCP2.C_DAY_OF_WEEK = SCP.C_DAY_OF_WEEK) ' ||
      '                                    and SCP.FAL_FACTORY_FLOOR_ID is null ' ||
      '                                   ) ' ||
      '                               ) ) ALL_PERIODS ';

    execute immediate lvSql ||
                      ' order by PAC_SCHEDULE_ID ' ||
                      '        , SCP_DATE ' ||
                      '        , (case ' ||
                      '            when C_DAY_OF_WEEK = ''MON'' then ''1_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''TUE'' then ''2_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''WED'' then ''3_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''THU'' then ''4_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''FRI'' then ''5_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''SAT'' then ''6_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''SUN'' then ''7_'' || C_DAY_OF_WEEK ' ||
                      '            else '''' ' ||
                      '          end ' ||
                      '          ) ' ||
                      '        , SCP_OPEN_TIME '
    bulk collect into FTabSchedulePeriodAsc;

    execute immediate lvSql ||
                      ' order by PAC_SCHEDULE_ID ' ||
                      '       , (case ' ||
                      '            when C_DAY_OF_WEEK = ''MON'' then ''1_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''TUE'' then ''2_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''WED'' then ''3_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''THU'' then ''4_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''FRI'' then ''5_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''SAT'' then ''6_'' || C_DAY_OF_WEEK ' ||
                      '            when C_DAY_OF_WEEK = ''SUN'' then ''7_'' || C_DAY_OF_WEEK ' ||
                      '            else '''' ' ||
                      '          end ' ||
                      '         ) DESC' ||
                      '       , SCP_DATE DESC ' ||
                      '       , SCP_CLOSE_TIME DESC '
    bulk collect into FTabSchedulePeriodDesc;

    /* PAC_SCHEDULE_ID doit à tout prix être identique ici à FAL_FACTORY_FLOOR_ID ou PAC_SUPPLIER_PARTNER_ID vu que ce sont des ressources avec exceptions.
       Les ressources n'ayant pas d'exception seront ensuite liées à un PAC_SCHEDULE_ID (voir procédure GetScheduleId) */
    select distinct nvl(FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID)
                  , nvl(FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID) PAC_SCHEDULE_ID
    bulk collect into FScheduleLoaded
               from PAC_SCHEDULE_PERIOD
              where (    (    PAC_SUPPLIER_PARTNER_ID is not null
                          and FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendar(PAC_SUPPLIER_PARTNER_ID) = PAC_SCHEDULE_ID)
                     or (    FAL_FACTORY_FLOOR_ID is not null
                         and FAL_SCHEDULE_FUNCTIONS.GetFloorCalendar(FAL_FACTORY_FLOOR_ID) = PAC_SCHEDULE_ID)
                    )
                and (   SCP_DATE is null
                     or trunc(SCP_DATE) >= trunc(sysdate) );
  end LoadAllResourcesSchedules;

  /**
  * Procedure StorePlanifOrigin
  * Description : Historisation au niveau du lot des évènements de planification
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_ID         : Lot
  * @param   aC_EVEN_TYPE        : Evt à l'origine de la replanification
  * @param   aLOT_PLAN_BEGIN_DTE : Date début planification
  * @param   aLOT_PLAN_END_DTE   : Date fin planification
  */
  procedure StorePlanifOrigin(
    aFAL_LOT_ID         FAL_LOT.FAL_LOT_ID%type
  , aC_EVEN_TYPE        FAL_HISTO_LOT.C_EVEN_TYPE%type
  , aLOT_PLAN_BEGIN_DTE FAL_LOT.LOT_PLAN_BEGIN_DTE%type
  , aLOT_PLAN_END_DTE   FAL_LOT.LOT_PLAN_END_DTE%type
  )
  is
  begin
    -- Insertion de l'historique
    insert into FAL_HISTO_LOT
                (FAL_HISTO_LOT_ID   -- Id Historique
               , FAL_LOT5_ID   -- Id Lot
               , HIS_REFCOMPL   -- Référence complète du lot
               , C_EVEN_TYPE   -- Le type d'évenement
               , HIS_PLAN_BEGIN_DTE   -- Date Planifiée Début
               , HIS_PLAN_END_DTE   -- Date Planifiée fin
               , HIS_INPROD_QTE   -- Qte en Fabrication 6
               , A_DATECRE   -- Date de création
               , A_IDCRE   -- Id Création
                )
      select GetNewId
           , FAL_LOT_ID
           , LOT_REFCOMPL
           , aC_EVEN_TYPE
           , nvl(aLOT_PLAN_BEGIN_DTE, LOT_PLAN_BEGIN_DTE)
           , nvl(aLOT_PLAN_END_DTE, LOT_PLAN_END_DTE)
           , LOT_INPROD_QTY
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from FAL_LOT
       where FAL_LOT_ID = aFAL_LOT_ID;
  exception
    when others then
      raise_application_error(-20001, 'Impossible de créer l''historique de planification du lot!');
  end StorePlanifOrigin;

  -- Renvoi de quel Id il s'agit : Lot, Proposition ou Gamme
  function CheckLotId(aLotId number)
    return integer
  as
  begin
    --> lot
    for ltplTest in (select FAL_LOT_ID
                       from FAL_LOT
                      where FAL_LOT_ID = alotId) loop
      return ctIdLot;
    end loop;

    --  proposition de lot
    for ltplTest in (select FAL_LOT_PROP_ID
                       from FAL_LOT_PROP
                      where FAL_LOT_PROP_ID = alotId) loop
      return ctIdProp;
    end loop;

    -- gamme opératoire
    for ltplTest in (select FAL_SCHEDULE_PLAN_ID
                       from FAL_SCHEDULE_PLAN
                      where FAL_SCHEDULE_PLAN_ID = alotId) loop
      return ctIdGamme;
    end loop;

    -- tâche affaire
    for ltplTest in (select GAL_TASK_ID
                       from GAL_TASK
                      where GAL_TASK_ID = alotId) loop
      return ctIdGalTask;
    end loop;

    return -1;
  end CheckLotId;

  -- Affectation de la date, de l'heure et des minutes à un champ
  function AffectDayHourMinut(J date, H number, M number)
    return date
  is
    ValDate date;
    H1      number;
    M1      number;
  begin
    if H >= 24 then
      H1  := 23;
      M1  := 59;
    else
      H1  := H;
      M1  := M;
    end if;

    select to_date(to_char(J, 'DD/MM/YYYY') || ' ' || to_char(H1) || ':' || to_char(M1), 'DD/MM/YYYY HH24:MI')
      into ValDate
      from dual;

    return ValDate;
  end AffectDayHourMinut;

-- Commande SQL pour la mise à jour de la date début planifiée du lot
-- ou de la proposition
  procedure MAJ_DateDebutPlanifLot(aLotId number, aTypeEntryToPlan integer, aNewBeginDate date)
  is
  begin
    if aTypeEntryToPlan = ctIdLot then
      update FAL_LOT
         set LOT_PLAN_BEGIN_DTE = decode(aNewBeginDate, null, LOT_PLAN_END_DTE, aNewBeginDate)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_ID = aLotId;
    elsif aTypeEntryToPlan = ctIdProp then
      update FAL_LOT_PROP
         set LOT_PLAN_BEGIN_DTE = decode(aNewBeginDate, null, LOT_PLAN_END_DTE, aNewBeginDate)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_PROP_ID = aLotId;
    end if;
  end MAJ_DateDebutPlanifLot;

-- Commande SQL pour la mise à jour de la date fin planifiée du lot
  procedure MAJ_DateFinPlanifLot(aLotId number, aTypeEntryToPlan integer, aNewEndDate date)
  as
    d date;
  begin
    if aTypeEntryToPlan = ctIdLot then
      update FAL_LOT
         set LOT_PLAN_END_DTE = decode(aNewEndDate, null, LOT_PLAN_BEGIN_DTE, aNewEndDate)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_ID = aLotId;
    elsif aTypeEntryToPlan = ctIdProp then
      update FAL_LOT_PROP
         set LOT_PLAN_END_DTE = decode(aNewEndDate, null, LOT_PLAN_BEGIN_DTE, aNewEndDate)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_PROP_ID = aLotId;
    end if;
  end MAJ_DateFinPlanifLot;

-- Commande SQL pour la mise à jour du temps de travail du lot
  procedure MAJ_TempsTravailLot(aLotId number, aTypeEntryToPlan integer, PrmTIME number)
  as
  begin
    if aTypeEntryToPlan = ctIdLot then
      update FAL_LOT
         set LOT_PLAN_LEAD_TIME = PrmTIME
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_ID = aLotId;
    elsif aTypeEntryToPlan = ctIdProp then
      update FAL_LOT_PROP
         set LOT_PLAN_LEAD_TIME = PrmTIME
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_PROP_ID = aLotId;
    end if;
  end MAJ_TempsTravailLot;

-- Commande SQL pour la mise à jour de la date début planifiée de la tâche
  procedure MAJ_DateDebutPlanifTache(aTaskId number, aTypeEntryToPlan integer, aDate date)
  as
  begin
    if aTypeEntryToPlan = ctIdLot then
      update FAL_TASK_LINK
         set TAL_BEGIN_PLAN_DATE = aDate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = aTaskId;
    elsif aTypeEntryToPlan = ctIdProp then
      update FAL_TASK_LINK_PROP
         set TAL_BEGIN_PLAN_DATE = aDate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_TASK_LINK_PROP_ID = aTaskId;
    elsif aTypeEntryToPlan = ctIdGalTask then
      update GAL_TASK_LINK
         set TAL_BEGIN_PLAN_DATE = aDate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where GAL_TASK_LINK_ID = aTaskId;
    end if;
  end MAJ_DateDebutPlanifTache;

-- Commande SQL pour la mise à jour de la date fin planifiée de la tâche
-- aUpdateCSTDelay : code de mise à jour du délai des commandes de sous traitance lors de la planification
  procedure MAJ_DateFinPlanifTache(aTaskId number, aTypeEntryToPlan integer, aDate date, aUpdateCSTDelay integer)
  as
  begin
    if aTypeEntryToPlan = ctIdLot then
      update FAL_TASK_LINK
         set TAL_END_PLAN_DATE = aDate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = aTaskId;
    elsif aTypeEntryToPlan = ctIdProp then
      update FAL_TASK_LINK_PROP
         set TAL_END_PLAN_DATE = aDate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_TASK_LINK_PROP_ID = aTaskId;
    elsif aTypeEntryToPlan = ctIdGalTask then
      update GAL_TASK_LINK
         set TAL_END_PLAN_DATE = aDate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where GAL_TASK_LINK_ID = aTaskId;
    end if;

    if aUpdateCSTDelay = 1 then
      DOC_PRC_SUBCONTRACTO.UpdateCSTDelay(iFalOperId => aTaskId);
    end if;
  end MAJ_DateFinPlanifTache;

-- Commande SQL pour la mise à jour du temps de travail de la tâche
  procedure MAJ_TempsTravailTache(aTaskId number, aTypeEntryToPlan integer, PrmTIME number)
  as
  begin
    if aTypeEntryToPlan = ctIdLot then
      update FAL_TASK_LINK
         set TAL_TASK_MANUF_TIME = PrmTIME
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = aTaskId;
    elsif aTypeEntryToPlan = ctIdProp then
      update FAL_TASK_LINK_PROP
         set TAL_TASK_MANUF_TIME = PrmTIME
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_TASK_LINK_PROP_ID = aTaskId;
    end if;
  end MAJ_TempsTravailTache;

------------ Début Planif Capacité FINIE ------------------
  -- Récupération du nombre de ressource de l'atelier
  function GetRessourceNumber(PrmFAL_FACTORY_FLOOR_ID number)
    return integer
  is
    valFAC_RESOURCE_NUMBER integer;
  begin
    valFAC_RESOURCE_NUMBER  := null;

    select FAC_RESOURCE_NUMBER
      into valFAC_RESOURCE_NUMBER
      from FAL_FACTORY_FLOOR
     where FAL_FACTORY_FLOOR_ID = PrmFAL_FACTORY_FLOOR_ID;

    if valFAC_RESOURCE_NUMBER is not null then
      return valFAC_RESOURCE_NUMBER;
    else
      -- Valeur par défaut
      return 1;
    end if;
  -- Valeur par défaut
  exception
    when no_data_found then
      return 1;
  end GetRessourceNumber;

  -- Détermination du nombre de jours de différence
  function InterDuration(aBeginDate date, aEndDate date, aFloorID number, aPartnerID number, aTypeCal integer, aFloorCapacity number)
    return number
  is
    result            number;
    WorkBegDate       date;
    WorkEndDate       date;
    aTime             number;
    aFilter           varchar2(30);
    aFilterID         number;
    aCalendarID       number;
    aBeginPeriod      date;
    aEndPeriod        date;
    aResourceNumber   number;
    aResourceCapacity number;
    aResourceCapQty   number;
  begin
    result       := 0;
    WorkBegDate  := aBeginDate;
    WorkEndDate  := aEndDate;

    if nvl(aFloorID, 0) <> 0 then
      aFilter      := 'FACTORY_FLOOR';
      aFilterID    := aFloorID;
      aCalendarID  := FAL_SCHEDULE_FUNCTIONS.GetFloorCalendar(aFloorId);
    else
      aFilter      := 'SUPPLIER';
      aFilterID    := aPartnerID;
      aCalendarID  := FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendar(aPartnerId);
    end if;

    -- Parcours du calendrier
    while WorkBegDate < WorkEndDate loop
      -- Recherche de la prochaine période ouverte
      PAC_I_LIB_SCHEDULE.GetNextWorkingPeriod(aBeginPeriod
                                            , aEndPeriod
                                            , aResourceNumber
                                            , aResourceCapacity
                                            , aResourceCapQty
                                            , WorkBegDate
                                            , aCalendarID
                                            , 1   -- Sens de recherche forward
                                            , aFilter
                                            , aFilterID
                                             );

      -- Si début période nulle ou supérieur à date fin calcul
      if    aBeginPeriod is null
         or aBeginPeriod >= WorkEndDate then
        result  := 0;
        exit;
      -- Sinon ajout de la capa. pour la période.
      else
        result  := result + (least(aEndPeriod, WorkEndDate) - greatest(aBeginPeriod, WorkBegDate) ) * 24;

        -- On arrête le parcours du calendrier si l'on a dépassé la date fin calcul
        if aEndPeriod > WorkEndDate then
          exit;
        end if;
      end if;

      WorkBegDate  := aEndPeriod;
    end loop;

    return result;
  end InterDuration;

  /***
  * fonction SearchEndDateOP
  * Description :
  *   Recherche de la date fin d'une OP par rapport à une date et des opérations en chevauchement
  *
  * @param   aFloorID             Atelier
  * @param   aDuration            Durée
  * @param   aBeginDate           Date début
  * @param   TypeCal              Calendrier
  * @param   FloorCapacity        Capacité de l'atelier.
  * @param   TalNumUnitsAllocated Nbre de ressource allouées.
  */
  function SearchEndDateOP(
    aFloorID             number
  , aDuration            number
  , aBeginDate           date
  , TypeCal              integer
  , FloorCapacity        number
  , TalNumUnitsAllocated FAL_TASK_LINK.TAL_NUM_UNITS_ALLOCATED%type
  )
    return date
  is
    -- Parcours des opérations avant la date début de la planif
    cursor GetOpBeforeStartDate(aStartDate in date)
    is
      select   TAL_LOT.TAL_BEGIN_PLAN_DATE as BeginDate
             , TAL_LOT.TAL_END_PLAN_DATE as EndDate
             , nvl(TAL_LOT.TAL_TASK_MANUF_TIME, 0) as duration
          from FAL_LOT LOT
             , FAL_TASK_LINK TAL_LOT
         where LOT.C_LOT_STATUS in('1', '2')
           and LOT.C_SCHEDULE_PLANNING <> '1'
           and TAL_LOT.FAL_LOT_ID = LOT.FAL_LOT_ID
           and TAL_LOT.FAL_FACTORY_FLOOR_ID = aFloorID
           and nvl(TAL_LOT.TAL_DUE_QTY, 0) > 0
           and TAL_LOT.TAL_BEGIN_PLAN_DATE is not null
           and TAL_LOT.TAL_END_PLAN_DATE is not null
           and TAL_LOT.TAL_BEGIN_PLAN_DATE < aStartDate
      union all
      select   TAL_PROP.TAL_BEGIN_PLAN_DATE as BeginDate
             , TAL_PROP.TAL_END_PLAN_DATE as EndDate
             , nvl(TAL_PROP.TAL_TASK_MANUF_TIME, 0) as duration
          from FAL_LOT_PROP PROP
             , FAL_TASK_LINK_PROP TAL_PROP
         where PROP.C_SCHEDULE_PLANNING <> '1'
           and TAL_PROP.FAL_LOT_PROP_ID = PROP.FAL_LOT_PROP_ID
           and TAL_PROP.FAL_FACTORY_FLOOR_ID = aFloorID
           and nvl(TAL_PROP.TAL_DUE_QTY, 0) > 0
           and TAL_PROP.TAL_BEGIN_PLAN_DATE is not null
           and TAL_PROP.TAL_END_PLAN_DATE is not null
           and TAL_PROP.TAL_BEGIN_PLAN_DATE < aStartDate
      order by 1
             , 2
             , 3;

    -- Parcours des opérations après la date début de la planif
    cursor GetOPAfterStartDate(aDate in date)
    is
      select   TAL_LOT.TAL_BEGIN_PLAN_DATE as BeginDate
             , TAL_LOT.TAL_END_PLAN_DATE as EndDate
             , TAL_LOT.TAL_TASK_MANUF_TIME as duration
          from FAL_LOT LOT
             , FAL_TASK_LINK TAL_LOT
         where LOT.C_LOT_STATUS in('1', '2')
           and LOT.C_SCHEDULE_PLANNING <> '1'
           and TAL_LOT.FAL_LOT_ID = LOT.FAL_LOT_ID
           and TAL_LOT.FAL_FACTORY_FLOOR_ID = aFloorID
           and nvl(TAL_LOT.TAL_DUE_QTY, 0) > 0
           and TAL_LOT.TAL_BEGIN_PLAN_DATE is not null
           and TAL_LOT.TAL_END_PLAN_DATE is not null
           and TAL_LOT.TAL_BEGIN_PLAN_DATE >= aDate
      union all
      select   TAL_PROP.TAL_BEGIN_PLAN_DATE as BeginDate
             , TAL_PROP.TAL_END_PLAN_DATE as EndDate
             , TAL_PROP.TAL_TASK_MANUF_TIME as duration
          from FAL_LOT_PROP PROP
             , FAL_TASK_LINK_PROP TAL_PROP
         where PROP.C_SCHEDULE_PLANNING <> '1'
           and TAL_PROP.FAL_LOT_PROP_ID = PROP.FAL_LOT_PROP_ID
           and TAL_PROP.FAL_FACTORY_FLOOR_ID = aFloorID
           and nvl(TAL_PROP.TAL_DUE_QTY, 0) > 0
           and TAL_PROP.TAL_BEGIN_PLAN_DATE is not null
           and TAL_PROP.TAL_END_PLAN_DATE is not null
           and TAL_PROP.TAL_BEGIN_PLAN_DATE >= aDate
      order by 1
             , 2
             , 3;

    vOP                  GetOPAfterStartDate%rowtype;
    CurOpBeforeStartDate GetOPBeforeStartDate%rowtype;
    SumSoldeWLot         number;
    SumSoldeWProp        number;
    SystemDate           date;
    DateW                date;
    DurationW            number;
    DurationOP           number;
    result               date;
    Diff                 number;
    RessourceNumber      integer;
    -- var pour recherche via les nouveaux calendrier
    aBeginperiod         date;
    aEndPeriod           date;
    aRessourceCapacity   number;
    aResourceCapQty      number;
    aCurrentOpDuration   number;
    aLoadDate            date;
    DurationInMinutes    number;
    aPeriodStartDate     date;
    aPeriodEndDate       date;
  begin
    result           := null;
    DurationOP       := aDuration;
    SystemDate       := trunc(sysdate);
    RessourceNumber  := GetRessourceNumber(aFloorID);
    -- Récupération de la date départ de la planification = Date début de la première période de la date
    -- du jour.
    GetValuesCalendar(aFalFactoryFloorId   => aFloorID
                    , aTypePeriod          => ctActivePeriod
                    , aDay                 => SystemDate
                    , aCapacityMinute      => aRessourceCapacity
                    , aPeriodStartDate     => aPeriodStartDate
                    , aPeriodEndDate       => aPeriodEndDate
                     );
    DateW            := SystemDate;
    aBeginPeriod     := SystemDate;
    DurationW        := 0;

    -- Parcours et répartition des opérations de lot et de proposition
    -- dont la date début est antérieure à la date de départ du calcul.
    -- Elles sont planifiée "bout à bout".
    for CurOpBeforeStartDate in GetOPBeforeStartDate(aBeginDate) loop
      -- Calcul de la durée de l'opération (en minutes), a partir de sa date début
      -- avant replanification.
      DurationInMinutes  := GetDurationInMinutes(aFloorId, null, CurOpBeforeStartDate.duration, CurOpBeforeStartDate.BeginDate);

      -- Planification à partir de la date début possible.
      if nvl(DurationInMinutes, 0) <> 0 then
        loop
          -- Si la tâche tient dans la période en cours
          if DurationInMinutes <= aRessourceCapacity then
            DateW      := DateW +(DurationInMinutes / 1440);
            DurationW  := DurationW + DurationInMinutes / RessourceNumber;
            exit;
          -- D > C = la tâche ne tient pas dans la période
          else
            DurationInMinutes  := DurationInMinutes - aRessourceCapacity;
            DateW              := DateW +(aRessourceCapacity / 1440) -(1 / 1440);
            DurationW          := DurationW + aRessourceCapacity / RessourceNumber;

            if DurationInMinutes <= 0 then
              exit;
            end if;

            -- Changement de période
            GetValuesCalendar(aFalFactoryFloorId   => aFloorID
                            , aTypePeriod          => ctNextPeriod
                            , aDay                 => DateW
                            , aCapacityMinute      => aRessourceCapacity
                            , aPeriodStartDate     => aPeriodStartDate
                            , aPeriodEndDate       => aPeriodEndDate
                             );
          end if;
        end loop;
      end if;
    end loop;

    if aBeginDate > DateW then
      DateW      := aBeginDate;
      DurationW  := GetDurationInMinutes(FAL_SCHEDULE_FUNCTIONS.GetFloorCalendar(aFloorId), aFloorId, null, SystemDate, aBeginDate);
    end if;

    GetValuesCalendar(aFalFactoryFloorId   => aFloorID
                    , aTypePeriod          => ctActivePeriod
                    , aDay                 => DateW
                    , aCapacityMinute      => aRessourceCapacity
                    , aPeriodStartDate     => aPeriodStartDate
                    , aPeriodEndDate       => aPeriodEndDate
                     );
    -- Parcours et répartition des opérations de lot et de proposition
    -- dont la date début est antérieure à la date de départ du calcul.
    -- Elles sont planifiée "bout à bout".
    -- Convertion Heures minutes
    DurationOp       := DurationOp * 60;

    for CurOpAfterStartDate in GetOPAfterStartDate(aBeginDate) loop
      -- Calcul de la durée de l'opération (en minutes), a partir de sa date début
      -- avant replanification.
      DurationInMinutes  := GetDurationInMinutes(aFloorId, null, CurOpAfterStartDate.duration, CurOpAfterStartDate.BeginDate);

      if nvl(DurationInMinutes, 0) <> 0 then
        -- Si l'op débute après la DateW, on place tout ou partie de l'opération en cours de planification
        if CurOpAfterStartDate.BeginDate > DateW then
          Diff  := GetDurationInMinutes(FAL_SCHEDULE_FUNCTIONS.GetFloorCalendar(aFloorId), aFloorId, null, DateW, CurOpAfterStartDate.BeginDate);

          -- Diminution de la durée de l'op
          if DurationOp > Diff then
            DurationOP  := DurationOP - Diff;
            DateW       := CurOpAfterStartDate.EndDate;
            DurationW   := DurationW + (Diff + DurationInMinutes) / RessourceNumber;
          else
            exit;
          end if;
        -- Sinon, on la replanifie à partir de DateW
        else
          -- Planification à partir de la date début possible.
          loop
            -- Si la tâche tient dans la période en cours
            if DurationInMinutes <= aRessourceCapacity then
              DateW      := DateW +(DurationInMinutes / 1440);
              DurationW  := DurationW + DurationInMinutes / RessourceNumber;
              exit;
            -- D > C = la tâche ne tient pas dans la période
            else
              DurationInMinutes  := DurationInMinutes - aRessourceCapacity;
              DateW              := DateW +(aRessourceCapacity / 1440) -(1 / 1440);
              DurationW          := DurationW + aRessourceCapacity / RessourceNumber;
              -- Changement de période
              GetValuesCalendar(aFalFactoryFloorId   => aFloorID
                              , aTypePeriod          => ctNextPeriod
                              , aDay                 => DateW
                              , aCapacityMinute      => aRessourceCapacity
                              , aPeriodStartDate     => aPeriodStartDate
                              , aPeriodEndDate       => aPeriodEndDate
                               );
            end if;
          end loop;
        end if;
      end if;
    end loop;

    -- S'il reste une durée à planifier sur l'op en cours de planification, on la planifie
    if DurationOp > 0 then
      GetValuesCalendar(aFalFactoryFloorId   => aFloorID
                      , aTypePeriod          => ctActivePeriod
                      , aDay                 => DateW
                      , aCapacityMinute      => aRessourceCapacity
                      , aPeriodStartDate     => aPeriodStartDate
                      , aPeriodEndDate       => aPeriodEndDate
                       );

      loop
        -- Si la tâche tient dans la période en cours
        if DurationOp <= aRessourceCapacity then
          DateW      := DateW +(DurationOp / 1440);
          DurationW  := DurationW + DurationOp / TalNumUnitsAllocated;
          exit;
        -- D > C = la tâche ne tient pas dans la période
        else
          DurationOp  := greatest(0, DurationOp - aRessourceCapacity);
          DateW       := DateW +(aRessourceCapacity / 1440) -(1 / 1440);
          DurationW   := DurationW + aRessourceCapacity / TalNumUnitsAllocated;

          if DurationOp = 0 then
            exit;
          end if;

          -- Changement de période
          GetValuesCalendar(aFalFactoryFloorId   => aFloorID
                          , aTypePeriod          => ctNextPeriod
                          , aDay                 => DateW
                          , aCapacityMinute      => aRessourceCapacity
                          , aPeriodStartDate     => aPeriodStartDate
                          , aPeriodEndDate       => aPeriodEndDate
                           );
        end if;
      end loop;
    end if;

    DateW            := systemDate;
    -- Détermination de la date fin par rapport à la date début et la durée totale
    GetValuesCalendar(aFalFactoryFloorId   => aFloorID
                    , aTypePeriod          => ctActivePeriod
                    , aDay                 => DateW
                    , aCapacityMinute      => aRessourceCapacity
                    , aPeriodStartDate     => aPeriodStartDate
                    , aPeriodEndDate       => aPeriodEndDate
                     );

    if nvl(DurationW, 0) <> 0 then
      loop
        -- Si la tâche tient dans la période en cours
        if DurationW <= aRessourceCapacity then
          DateW      := DateW +(DurationW / 1440);
          DurationW  := 0;
          exit;
        -- D > C = la tâche ne tient pas dans la période
        else
          DurationW  := greatest(0, DurationW - aRessourceCapacity);
          DateW      := DateW +(aRessourceCapacity / 1440) -(1 / 1440);

          if DurationW = 0 then
            exit;
          end if;

          -- Changement de période
          GetValuesCalendar(aFalFactoryFloorId   => aFloorID
                          , aTypePeriod          => ctNextPeriod
                          , aDay                 => DateW
                          , aCapacityMinute      => aRessourceCapacity
                          , aPeriodStartDate     => aPeriodStartDate
                          , aPeriodEndDate       => aPeriodEndDate
                           );
        end if;
      end loop;
    end if;

    return nvl(DateW, aBeginDate);
  end SearchEndDateOP;

  /**
  *  Fonction GetDurationInMinutes
  *  Description : Recherche de la capacité en minute en fonction des périodes
  *                calendaires à partir de la durée en jour.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   FalFactoryFloorId : Atelier
  * @param   PacSupplierPartnerId : Fournisseur
  * @param   DurationInDay : Durée en jours
  * @param   StartDate : Date début du calcul
  * @param   aForward : Sens de recherche.
  */
  function GetDurationInMinutes(FalFactoryFloorId number, PacSupplierPartnerId number, DurationInDay number, StartDate date, aForward boolean default true)
    return number
  is
    aWorkDurationInDay       number;
    aCurrentDate             date;
    aDayRemainCapacityMinute number;
    aDayTotalCapacityMinute  number;
    aDurationInMinutes       number;
  begin
    if DurationInDay = 0 then
      return 0;
    end if;

    LoadAllResourcesSchedules;
    aWorkDurationInDay  := DurationInDay;
    aCurrentDate        := StartDate;
    aDurationInMinutes  := 0;

    -- Recherche en avant
    if aForward then
      -- Si le jour est ouvert
      if IsOpenDay(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate) = 1 then
        -- Capacité restante du jour à partir de aCurrentDate
        aDayRemainCapacityMinute  := GetDateRemainCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);
        -- Capacité totale de la journée.
        aDayTotalCapacityMinute   := GetDateTotalCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);

        -- Durée en jours restante à répartir
        if aDayTotalCapacityMinute <> 0 then
          -- Si la durée restante du jour est supérieur à la durée à répartir
          if (aDayRemainCapacityMinute / aDayTotalCapacityMinute) > aWorkDurationInday then
            return trunc(aWorkDurationInday * aDayTotalCapacityMinute);
          else
            aWorkDurationInday  := aWorkDurationInday -(aDayRemainCapacityMinute / aDayTotalCapacityMinute);
          end if;
        end if;

        aDurationInMinutes        := aDayRemainCapacityMinute;
      end if;

      --1er jour suivant
      aCurrentDate  := trunc(aCurrentDate) + 1;

      -- Parcours des jours suivants
      loop
        exit when aWorkDurationInday = 0;

        -- Le jour est ouvert
        if IsOpenDay(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate) = 1 then
          -- Capacité totale du jour
          aDayTotalCapacityMinute  := GetDateTotalCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);

          -- Il reste plus d'un jour a répartir
          if aWorkDurationInday > 1 then
            aDurationInMinutes  := aDurationInMinutes + aDayTotalCapacityMinute;
            aWorkDurationInday  := aWorkDurationInday - 1;
          -- Durée a répartir < 1 jour.
          else
            aDurationInMinutes  := aDurationInMinutes + aWorkDurationInDay * aDayTotalCapacityMinute;
            aWorkDurationInDay  := 0;
          end if;
        end if;

        aCurrentDate  := aCurrentDate + 1;
      end loop;
    -- Recherche en arrière
    else
      -- Si le jour est ouvert
      if IsOpenDay(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate) = 1 then
        -- Capacité restante du jour à partir de aCurrentDate
        aDayRemainCapacityMinute  := GetDateRemainCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);
        -- Capacité totale de la journée.
        aDayTotalCapacityMinute   := GetDateTotalCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);

        -- Durée en jours restante à répartir
        if aDayTotalCapacityMinute <> 0 then
          -- Si la durée restante du jour est supérieur à la durée à répartir
          if ( (aDayTotalCapacityMinute - aDayRemainCapacityMinute) / aDayTotalCapacityMinute) > aWorkDurationInday then
            return trunc(aWorkDurationInday * aDayTotalCapacityMinute);
          else
            aWorkDurationInday  := aWorkDurationInday -( (aDayTotalCapacityMinute - aDayRemainCapacityMinute) / aDayTotalCapacityMinute);
          end if;
        end if;

        aDurationInMinutes        :=(aDayTotalCapacityMinute - aDayRemainCapacityMinute);
      end if;

      --1er jour précédent
      aCurrentDate  := trunc(aCurrentDate) - 1;

      -- Parcours des jours suivants
      loop
        exit when aWorkDurationInday = 0;

        -- Le jour est ouvert
        if IsOpenDay(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate) = 1 then
          -- Capacité totale du jour
          aDayTotalCapacityMinute  := GetDateTotalCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);

          -- Il reste plus d'un jour a répartir
          if aWorkDurationInday > 1 then
            aDurationInMinutes  := aDurationInMinutes + aDayTotalCapacityMinute;
            aWorkDurationInday  := aWorkDurationInday - 1;
          -- Durée a répartir < 1 jour.
          else
            aDurationInMinutes  := aDurationInMinutes + aWorkDurationInDay * aDayTotalCapacityMinute;
            aWorkDurationInDay  := 0;
          end if;
        end if;

        aCurrentDate  := aCurrentDate - 1;
      end loop;
      aDurationInMinutes  := ceil(aDurationInMinutes);
    end if;

    return trunc(aDurationInMinutes);
  end GetDurationInMinutes;

  /**
  *  Fonction GetDurationInMinutes
  *  Description : Recherche de la capacité en minute à partir des dates début
  *                et fin
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aScheduleID : Calendrier
  * @param   aFalFactoryFloorId : Atelier
  * @param   aPacSupplierPartnerId : Fournisseur
  * @param   aStartDate : Date début du calcul
  * @param   aEndDate : Date fin du calcul
  * @param   aForward : Sens de recherche.
  */
  function GetDurationInMinutes(aScheduleID number, aFalFactoryFloorId number, aPacSupplierPartnerId number, aStartDate date, aEndDate date)
    return number
  is
    aFilter     varchar2(30);
    aFilterId   number;
    aTimeInHour number;
  begin
    -- Filtre à appliquer pour la recherche dans les calendriers
    if aFalFactoryFloorId is not null then
      aFilter    := 'FACTORY_FLOOR';
      aFilterId  := aFalFactoryFloorId;
    elsif aPacSupplierPartnerId is not null then
      aFilter    := 'SUPPLIER';
      aFilterId  := aPacSupplierPartnerId;
    else
      aFilter    := '';
      aFilterId  := null;
    end if;

    -- Recherche capacité en minutes entre deux dates
    PAC_I_LIB_SCHEDULE.CalcOpenTimeBetween(oTime         => aTimeInHour
                                         , iScheduleID   => aScheduleID
                                         , iDate_1       => aStartDate
                                         , iDate_2       => aEndDate
                                         , iFilter       => aFilter
                                         , iFilterID     => aFilterId
                                          );
    -- Résultat en minutes
    return aTimeInHour * 60;
  end GetDurationInMinutes;

  /**
  *  fonction GetDurationInDay
  *  Description
  *    Calcul de la durée en jour à partir des dates début et fin. On tient compte
  *    des jours ouvrés et des fractions de jours (sur 24h) sur la première et la
  *    dernière journée. Si la date de fin est inférieure à la date de début, la valeur
  *    retournée sera négative.
  */
  function GetDurationInDay(FalFactoryFloorId number, PacSupplierPartnerId number, BeginDate date, EndDate date)
    return FAL_TASK_LINK.TAL_TASK_MANUF_TIME%type
  is
    aCurrentDate              date;
    aDayRemainCapacityMinute  number;
    aDayTotalCapacityMinute   number;
    aDurationInDay            number;
    aDayRemainCapacityMinute2 number;
    lBeginDate                date    := BeginDate;
    lEndDate                  date    := EndDate;
    lFactor                   integer := 1;
  begin
    if EndDate < BeginDate then
      lBeginDate  := EndDate;
      lEndDate    := BeginDate;
      lFactor     := -1;
    end if;

    LoadAllResourcesSchedules;
    aCurrentDate    := lBeginDate;
    aDurationInDay  := 0;

    -- Si le jour est ouvert, Calcul de la fraction de jour du premier jour
    if IsOpenDay(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate) = 1 then
      -- Capacité restante du jour à partir de aCurrentDate
      aDayRemainCapacityMinute  := GetDateRemainCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);
      -- Capacité totale de la journée.
      aDayTotalCapacityMinute   := GetDateTotalCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);

      if aDayTotalCapacityMinute <> 0 then
        -- Si la date fin pour le calcul est avant la date fin de la journée.
        if trunc(lBeginDate) + 1 > lEndDate then
          aDayRemainCapacityMinute2  := GetDateRemainCapacity(FalFactoryFloorId, PacSupplierPartnerId, lEndDate);
          aDurationInDay             := (aDayRemainCapacityMinute - aDayRemainCapacityMinute2) / aDayTotalCapacityMinute;
        else
          aDurationInDay  := aDayRemainCapacityMinute / aDayTotalCapacityMinute;
        end if;
      end if;
    end if;

    aCurrentDate    := trunc(aCurrentDate) + 1;

    -- Parcours des jours suivants
    loop
      exit when aCurrentDate > lEndDate;

      -- Le jour est ouvert
      if IsOpenDay(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate) = 1 then
        -- Il reste moins d'un jour a répartir.
        if trunc(aCurrentDate) + 1 > lEndDate then
          -- Capacité restante du jour à partir de aCurrentDate
          aDayRemainCapacityMinute   := GetDateRemainCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);
          -- Capacité totale de la journée.
          aDayTotalCapacityMinute    := GetDateTotalCapacity(FalFactoryFloorId, PacSupplierPartnerId, aCurrentDate);
          -- Capacité restante du jour à partir de la date fin du calcul
          aDayRemainCapacityMinute2  := GetDateRemainCapacity(FalFactoryFloorId, PacSupplierPartnerId, lEndDate);
          -- Si la capacité minute de la journée ouvrée est à 0 (sic), la capacité restante du jour à partir de aCurrentDate l'est forcément.
          if aDayTotalCapacityMinute > 0 then
            aDurationInDay             := aDurationInDay + (aDayRemainCapacityMinute - aDayRemainCapacityMinute2) / aDayTotalCapacityMinute;
          end if;
        -- Il reste plus d'un jour a répartir.
        else
          aDurationInDay  := aDurationInDay + 1;
        end if;
      end if;

      aCurrentDate  := aCurrentDate + 1;
    end loop;

    return aDurationInDay * lFactor;
  end GetDurationInDay;

  /**
  *  fonction GetDurationInDay
  *  Description
  *    Calcul de la durée en jours/fraction de jours partir de la date
  *    début. Avec un durée en minutes à placer = aDurationInMin.
  *
  * @param   aFalFactoryFloorId : Atelier
  * @param   aPacSupplierPartnerId : Fournisseur
  * @param   aBeginDate : Date début
  * @param   aDurationInMin : Durée en minutes
  * @param   aForward : Sens de recherche
  */
  function GetDurationInDay(aFalFactoryFloorId number, aPacSupplierPartnerId number, aBeginDate date, aDurationInMin number, aForward integer)
    return number
  is
    aWorkDate          date;
    aWorkDurationInMin number;
    CapacityMinute     number;
    aPeriodStartDate   date;
    aPeriodEndDate     date;
  begin
    LoadAllResourcesSchedules;
    aWorkDate           := aBeginDate;
    aWorkDurationInMin  := aDurationInMin;

    -- Sens Forward
    if aForward = 1 then
      -- Recherche période active.
      GetValuesCalendar(aFalFactoryFloorId      => aFalFactoryFloorId
                      , aPacSupplierPartnerId   => aPacSupplierPartnerId
                      , aTypePeriod             => ctActivePeriod
                      , aDay                    => aWorkDate
                      , aCapacityMinute         => CapacityMinute
                      , aPeriodStartDate        => aPeriodStartDate
                      , aPeriodEndDate          => aPeriodEndDate
                       );
      -- Date et Durée restante
      aWorkDate           := aWorkDate + least(CapacityMinute, aWorkDurationInMin) / 1440;
      aWorkDurationInMin  := greatest(0, aWorkDurationInMin - CapacityMinute);

      -- Si plus de durée restante
      if aWorkDurationInMin = 0 then
        return aWorkDate - aBeginDate;
      -- Sinon parcours des périodes suivantes
      else
        loop
          exit when aWorkDurationInMin = 0
                or aWorkDate is null;
          -- Recherche période active.
          GetValuesCalendar(aFalFactoryFloorId      => aFalFactoryFloorId
                          , aPacSupplierPartnerId   => aPacSupplierPartnerId
                          , aTypePeriod             => ctNextPeriod
                          , aDay                    => aWorkDate
                          , aCapacityMinute         => CapacityMinute
                          , aPeriodStartDate        => aPeriodStartDate
                          , aPeriodEndDate          => aPeriodEndDate
                           );
          -- Date et Durée restante
          aWorkDate           := aWorkDate + least(CapacityMinute, aWorkDurationInMin) / 1440;
          aWorkDurationInMin  := greatest(0, aWorkDurationInMin - CapacityMinute);
        end loop;

        -- convertion en nombre de jours ouvrés sur le calendrier.
        return aWorkDate - aBeginDate;
      end if;
    -- Sens Backward
    else
      -- Recherche période active.
      GetValuesCalendar(aFalFactoryFloorId      => aFalFactoryFloorId
                      , aPacSupplierPartnerId   => aPacSupplierPartnerId
                      , aTypePeriod             => ctActivePeriod
                      , aDay                    => aWorkDate
                      , aCapacityMinute         => CapacityMinute
                      , aForward                => false
                      , aPeriodStartDate        => aPeriodStartDate
                      , aPeriodEndDate          => aPeriodEndDate
                       );
      -- Date et Durée restante
      aWorkDate           := aWorkDate - least(CapacityMinute, aWorkDurationInMin) / 1440;
      aWorkDurationInMin  := greatest(0, aWorkDurationInMin - CapacityMinute);

      -- Si plus de durée restante
      if aWorkDurationInMin = 0 then
        return aBeginDate - aWorkDate;
      -- Sinon parcours des périodes suivantes
      else
        loop
          exit when aWorkDurationInMin = 0
                or aWorkDate is null;
          -- Recherche période active.
          GetValuesCalendar(aFalFactoryFloorId      => aFalFactoryFloorId
                          , aPacSupplierPartnerId   => aPacSupplierPartnerId
                          , aTypePeriod             => ctNextPeriod
                          , aDay                    => aWorkDate
                          , aCapacityMinute         => CapacityMinute
                          , aForward                => false
                          , aPeriodStartDate        => aPeriodStartDate
                          , aPeriodEndDate          => aPeriodEndDate
                           );
          -- Date et Durée restante
          aWorkDate           := aWorkDate - least(CapacityMinute, aWorkDurationInMin) / 1440;
          aWorkDurationInMin  := greatest(0, aWorkDurationInMin - CapacityMinute);
        end loop;

        -- convertion en nombre de jours ouvrés sur le calendrier.
        return aBeginDate - aWorkDate;
      end if;
    end if;
  end GetDurationInDay;

  /**
  *  fonction GetDurationInOpenDay
  *  Description
  *    Calcul de la durée en jours/fraction de JOURS OUVRES a partir de la date début
  *    Avec un durée en minutes à placer = aDurationInMin sur le calendrier
  *
  * @param   aScheduleID : Calendrier
  * @param   aFalFactoryFloorId : Atelier
  * @param   aPacSupplierPartnerId : Fournisseur
  * @param   aBeginDate : Date début
  * @param   aDurationInMin : Durée en minutes
  * @param   aForward : Sens de recherche
  */
  function GetDurationInOpenDay(aFalFactoryFloorId number, aPacSupplierPartnerId number, aBeginDate date, aDurationInMin number, aForward integer)
    return number
  is
    aFilter            varchar2(30);
    aFilterId          number;
    aWorkDate          date;
    aWorkDurationInMin number;
    CapacityMinute     number;
    aPeriodStartDate   date;
    aPeriodEndDate     date;
  begin
    LoadAllResourcesSchedules;
    aWorkDate           := aBeginDate;
    aWorkDurationInMin  := aDurationInMin;

    -- Sens Forward
    if aForward = 1 then
      -- Recherche période active.
      GetValuesCalendar(aFalFactoryFloorId      => aFalFactoryFloorId
                      , aPacSupplierPartnerId   => aPacSupplierPartnerId
                      , aTypePeriod             => ctActivePeriod
                      , aDay                    => aWorkDate
                      , aCapacityMinute         => CapacityMinute
                      , aPeriodStartDate        => aPeriodStartDate
                      , aPeriodEndDate          => aPeriodEndDate
                       );
      -- Date et Durée restante
      aWorkDate           := aWorkDate + least(CapacityMinute, aWorkDurationInMin) / 1440;
      aWorkDurationInMin  := greatest(0, aWorkDurationInMin - CapacityMinute);

      -- Parcours des périodes suivantes, si durée restante à répartir
      if aWorkDurationInMin > 0 then
        loop
          exit when aWorkDurationInMin = 0
                or aWorkDate is null;
          -- Recherche période active.
          GetValuesCalendar(aFalFactoryFloorId      => aFalFactoryFloorId
                          , aPacSupplierPartnerId   => aPacSupplierPartnerId
                          , aTypePeriod             => ctNextPeriod
                          , aDay                    => aWorkDate
                          , aCapacityMinute         => CapacityMinute
                          , aPeriodStartDate        => aPeriodStartDate
                          , aPeriodEndDate          => aPeriodEndDate
                           );
          -- Date et Durée restante
          aWorkDate           := aWorkDate + least(CapacityMinute, aWorkDurationInMin) / 1440;
          aWorkDurationInMin  := greatest(0, aWorkDurationInMin - CapacityMinute);
        end loop;
      end if;

      -- A partir de la date début et fin,  calcul du nombre de jours ouvrés
      return GetDurationInDay(aFalFactoryFloorId, aPacSupplierPartnerId, aBeginDate, aWorkDate);
    -- Sens Backward
    else
      -- Recherche période active.
      GetValuesCalendar(aFalFactoryFloorId      => aFalFactoryFloorId
                      , aPacSupplierPartnerId   => aPacSupplierPartnerId
                      , aTypePeriod             => ctActivePeriod
                      , aDay                    => aWorkDate
                      , aCapacityMinute         => CapacityMinute
                      , aForward                => false
                      , aPeriodStartDate        => aPeriodStartDate
                      , aPeriodEndDate          => aPeriodEndDate
                       );
      -- Date et Durée restante
      aWorkDate           := aWorkDate - least(CapacityMinute, aWorkDurationInMin) / 1440;
      aWorkDurationInMin  := greatest(0, aWorkDurationInMin - CapacityMinute);

      -- Parcours des périodes suivantes, si durée restante à répartir
      if aWorkDurationInMin > 0 then
        loop
          exit when aWorkDurationInMin = 0
                or aWorkDate is null;
          -- Recherche période active.
          GetValuesCalendar(aFalFactoryFloorId      => aFalFactoryFloorId
                          , aPacSupplierPartnerId   => aPacSupplierPartnerId
                          , aTypePeriod             => ctNextPeriod
                          , aDay                    => aWorkDate
                          , aCapacityMinute         => CapacityMinute
                          , aForward                => false
                          , aPeriodStartDate        => aPeriodStartDate
                          , aPeriodEndDate          => aPeriodEndDate
                           );
          -- Date et Durée restante
          aWorkDate           := aWorkDate - least(CapacityMinute, aWorkDurationInMin) / 1440;
          aWorkDurationInMin  := greatest(0, aWorkDurationInMin - CapacityMinute);
        end loop;
      end if;

      -- A partir de la date début et fin,  calcul du nombre de jours ouvrés
      return GetDurationInDay(aFalFactoryFloorId, aPacSupplierPartnerId, aWorkDate, aBeginDate);
    end if;
  end GetDurationInOpenDay;

  /**
  * procédure PlanOperation
  * Description : Planification d'une opération de lot, proposition ou gamme
  *
  * @created CLG
  * @lastUpdate
  * @public
  */
  procedure PlanOperation(
    aTypeEntryToPlan            integer
  , UpdateOpFields              integer
  , aTaskId                     number
  , CTaskType                   FAL_TASK_LINK.C_TASK_TYPE%type
  , FalFactoryFloorId           number
  , ScsDelay                    FAL_TASK_LINK.SCS_DELAY%type
  , CRelationType               FAL_TASK_LINK.C_RELATION_TYPE%type
  , PacSupplierPartnerId        number
  , TalNumUnitsAllocated        FAL_TASK_LINK.TAL_NUM_UNITS_ALLOCATED%type
  , TalDueQty                   FAL_TASK_LINK.TAL_DUE_QTY%type
  , ScsPlanProp                 FAL_TASK_LINK.SCS_PLAN_PROP%type
  , TalPlanRate                 FAL_TASK_LINK.TAL_PLAN_RATE%type
  , ScsPlanRate                 FAL_TASK_LINK.SCS_PLAN_RATE%type
  , TalTskAdBalance             FAL_TASK_LINK.TAL_TSK_AD_BALANCE%type
  , TalTskWBalance              FAL_TASK_LINK.TAL_TSK_W_BALANCE%type
  , ScsTransfertTime            FAL_TASK_LINK.SCS_TRANSFERT_TIME%type
  , ScsOpenTimeMachine          number
  , aAllInInfiniteCap           number
  , aIsParallel                 boolean
  , TimeUnit                    integer
  , JDEB                 in out date
  , JFIN                 in out date
  , HDEB                 in out number
  , MDEB                 in out number
  , HFIN                 in out number
  , MFIN                 in out number
  , REPT                 in out number
  , LotDuration          in out number
  , ioLastTaskEndDate    in out date
  , aUpdateCSTDelay             integer
  )
  is
    nCapacityMinute    number;   -- Anciennement C
    Retard             number;
    J                  date;
    D                  number;
    SoldeTravailMinute number;
    J1                 date;
    InfiniteFloor      number;
    DurationInMinutes  number;
    DurationInDay      number;
    aScheduleID        number;
    aPeriodStartDate   date;
    aPeriodEndDate     date;
  begin
    -- Si le nombre d'unité affectée ou la quantité solde est égal à 0, on met à jour l'opération avec la dernière date fin et on sort
    if    (TalNumUnitsAllocated = 0)
       or (TalDueQty = 0) then
      -- Affectation de la durée de la tâche
      if     (UpdateOpFields = 1)
         and (PCS.PC_CONFIG.GetBooleanConfig('FAL_PLAN_UPDATE_FINISH_OPE') ) then
        MAJ_DateDebutPlanifTache(aTaskId, aTypeEntryToPlan, ioLastTaskEndDate);
        MAJ_TempsTravailTache(aTaskId, aTypeEntryToPlan, 0);
        MAJ_DateFinPlanifTache(aTaskId, aTypeEntryToPlan, ioLastTaskEndDate, aUpdateCSTDelay);
      end if;

      return;
    end if;

    -- Calcul de la durée de l'OP.
    JDEB    := to_date(to_char(JDEB, 'DD.MM.YYYY ') || lpad(HDEB, 2, '0') || ':' || lpad(MDEB, 2, '0'), 'DD.MM.YYYY HH24:MI');
    JFIN    := to_date(to_char(JFIN, 'DD.MM.YYYY ') || lpad(HFIN, 2, '0') || ':' || lpad(MFIN, 2, '0'), 'DD.MM.YYYY HH24:MI');
    -- Récupération du retard
    Retard  := nvl(ScsDelay, 0) * TimeUnit;

    if CRelationType = '1' then
      -- Opération de type "SUCCESSEUR"
      GetValuesCalendar(aFalFactoryFloorId      => FalFactoryFloorId
                      , aPacSupplierPartnerId   => PacSupplierPartnerId
                      , aTypePeriod             => ctActivePeriod
                      , aDay                    => JFIN
                      , aCapacityMinute         => nCapacityMinute
                      , aPeriodStartDate        => aPeriodStartDate
                      , aPeriodEndDate          => aPeriodEndDate
                       );
      JDEB  := JFIN;
    elsif CRelationType = '3' then
      -- Opération de type "SUCCESSEUR lien solide"
      -- On part de la date fin de l'opération précédente
      GetValuesCalendar(aFalFactoryFloorId      => FalFactoryFloorId
                      , aPacSupplierPartnerId   => PacSupplierPartnerId
                      , aTypePeriod             => ctActivePeriod
                      , aDay                    => ioLastTaskEndDate
                      , aCapacityMinute         => nCapacityMinute
                      , aPeriodStartDate        => aPeriodStartDate
                      , aPeriodEndDate          => aPeriodEndDate
                       );
      JDEB  := ioLastTaskEndDate;
    else
      -- Opération de type "PARALLELE" (CRelationType = '2', '4' ou '5')
      GetValuesCalendar(aFalFactoryFloorId      => FalFactoryFloorId
                      , aPacSupplierPartnerId   => PacSupplierPartnerId
                      , aTypePeriod             => ctActivePeriod
                      , aDay                    => JDEB
                      , aCapacityMinute         => nCapacityMinute
                      , aPeriodStartDate        => aPeriodStartDate
                      , aPeriodEndDate          => aPeriodEndDate
                       );

      while(Retard > nCapacityMinute) loop
        Retard  := Retard - nCapacityMinute;
        GetValuesCalendar(aFalFactoryFloorId      => FalFactoryFloorId
                        , aPacSupplierPartnerId   => PacSupplierPartnerId
                        , aTypePeriod             => ctNextPeriod
                        , aDay                    => JDEB
                        , aCapacityMinute         => nCapacityMinute
                        , aPeriodStartDate        => aPeriodStartDate
                        , aPeriodEndDate          => aPeriodEndDate
                         );
      end loop;

      JDEB  := JDEB +(Retard / 1440);
      GetValuesCalendar(aFalFactoryFloorId      => FalFactoryFloorId
                      , aPacSupplierPartnerId   => PacSupplierPartnerId
                      , aTypePeriod             => ctActivePeriod
                      , aDay                    => JDEB
                      , aCapacityMinute         => nCapacityMinute
                      , aPeriodStartDate        => aPeriodStartDate
                      , aPeriodEndDate          => aPeriodEndDate
                       );
    end if;

    J       := JDEB;

    -- Détermination si on fait une planif à capacité infinie ou non
    if aAllInInfiniteCap = 1 then
      InfiniteFloor  := 1;
    else
      begin
        select nvl(FAC_INFINITE_FLOOR, 1)
          into InfiniteFloor
          from FAL_FACTORY_FLOOR
         where FAL_FACTORY_FLOOR_ID = FalFactoryFloorId;
      exception
        when no_data_found then
          InfiniteFloor  := 1;
      end;
    end if;

    if InfiniteFloor = 1 then
      -- Planification à Capacité INFINIE

      -- Affectation de la date début de la tâche
      if UpdateOpFields = 1 then
        -- Si la date début de l'opération = date fin de la période en cours,
        -- alors la date début de l'opération = date début de la prochaine période.
        if J = aPeriodEndDate then
          GetValuesCalendar(aFalFactoryFloorId      => FalFactoryFloorId
                          , aPacSupplierPartnerId   => PacSupplierPartnerId
                          , aTypePeriod             => ctNextPeriod
                          , aDay                    => J
                          , aCapacityMinute         => nCapacityMinute
                          , aPeriodStartDate        => aPeriodStartDate
                          , aPeriodEndDate          => aPeriodEndDate
                           );
        end if;

        MAJ_DateDebutPlanifTache(aTaskId, aTypeEntryToPlan, AffectDayHourMinut(trunc(J), to_char(J, 'HH24'), to_char(J, 'MI') ) );
      end if;

      -- Calcul de la durée
      DurationInDay       :=
        FAL_LIB_TASK_LINK.getDaysDuration(iSCS_PLAN_PROP             => ScsPlanProp
                                        , iTAL_PLAN_RATE             => TalPlanRate
                                        , iTAL_NUM_UNITS_ALLOCATED   => TalNumUnitsAllocated
                                        , iSCS_PLAN_RATE             => ScsPlanRate
                                         );
      DurationInMinutes   := GetDurationInMinutes(FalFactoryFloorId, PacSupplierPartnerId, DurationInDay, J);
      SoldeTravailMinute  :=
        FAL_LIB_TASK_LINK.getMinutesWorkBalance(iC_TASK_TYPE               => CTaskType
                                              , iTAL_TSK_AD_BALANCE        => TalTskAdBalance
                                              , iTAL_TSK_W_BALANCE         => TalTskWBalance
                                              , iTAL_NUM_UNITS_ALLOCATED   => TalNumUnitsAllocated
                                              , iSCS_TRANSFERT_TIME        => ScsTransfertTime
                                              , iSCS_OPEN_TIME_MACHINE     => ScsOpenTimeMachine
                                              , iFAC_DAY_CAPACITY          => FAL_TOOLS.GetDayCapacity(FalFactoryFloorId)
                                               );
      D                   := greatest(DurationInMinutes, SoldeTravailMinute);

      if (D = 0) then
        -- Affectation de la durée de la tâche
        if UpdateOpFields = 1 then
          MAJ_TempsTravailTache(aTaskId, aTypeEntryToPlan, 0);
          ioLastTaskEndDate  := AffectDayHourMinut(trunc(J), to_char(J, 'HH24'), to_char(J, 'MI') );
          MAJ_DateFinPlanifTache(aTaskId, aTypeEntryToPlan, ioLastTaskEndDate, aUpdateCSTDelay);
        end if;
      else
        loop
          if D <= nCapacityMinute then   -- Si la tâche tient dans la journée en cours
            J1  := J +(D / 1440);

            if UpdateOpFields = 1 then
              ioLastTaskEndDate  := AffectDayHourMinut(trunc(J1), to_char(J1, 'HH24'), to_char(J1, 'MI') );
              MAJ_DateFinPlanifTache(aTaskId, aTypeEntryToPlan, ioLastTaskEndDate, aUpdateCSTDelay);
            end if;

            if aIsParallel then
              if J1 > JFIN then
                -- Si J1 (la date de fin de l'opération en cours) est plus grand que JFIN
                -- (la plus grande date fin des opérations parallèle), on réinitialise JFIN avec J1
                -- JFIN Sert ensuite à déterminer la date début de la prochaine opération "successeur"
                JFIN  := J1;
                REPT  := D;
              end if;
            else
              -- Opération de type "SUCCESSEUR"
              JFIN  := J1;
              REPT  := D;
            end if;

            exit;
          else   -- D > nCapacityMinute = la tâche ne tient pas dans la période
            D  := D - nCapacityMinute;
            -- Changement de période
            GetValuesCalendar(aFalFactoryFloorId      => FalFactoryFloorId
                            , aPacSupplierPartnerId   => PacSupplierPartnerId
                            , aTypePeriod             => ctNextPeriod
                            , aDay                    => J
                            , aCapacityMinute         => nCapacityMinute
                            , aPeriodStartDate        => aPeriodStartDate
                            , aPeriodEndDate          => aPeriodEndDate
                             );
          end if;
        end loop;

        -- Calcul final durée tâche et durée lot.
        DurationInDay  := GetDurationInDay(FalFactoryFloorId, PacSupplierPartnerId, JDEB, J1);

        if UpdateOpFields = 1 then
          MAJ_TempsTravailTache(aTaskId, aTypeEntryToPlan, DurationInDay);
        end if;

        LotDuration    := LotDuration + DurationInDay;
      end if;
    else
      -- Calcul de la durée
      DurationInDay       :=
        FAL_LIB_TASK_LINK.getDaysDuration(iSCS_PLAN_PROP             => ScsPlanProp
                                        , iTAL_PLAN_RATE             => TalPlanRate
                                        , iTAL_NUM_UNITS_ALLOCATED   => TalNumUnitsAllocated
                                        , iSCS_PLAN_RATE             => ScsPlanRate
                                         );
      DurationInMinutes   := GetDurationInMinutes(FalFactoryFloorId, null, DurationInDay, J);
      -- Calcul du travail
      SoldeTravailMinute  :=( (nvl(TalTskAdBalance, 0) + nvl(TalTskWBalance, 0) / TalNumUnitsAllocated + nvl(ScsTransfertTime, 0) ) * TimeUnit);
      D                   := greatest(DurationInMinutes, SoldeTravailMinute) / 60;
      -- Planification à Capacité FINIE
      JFIN                :=
        SearchEndDateOP(FalFactoryFloorId
                      , D
                      , J
                      , FAL_SCHEDULE_FUNCTIONS.GetRessourceCalendar(FalFactoryFloorId, PacSupplierPartnerId, PacSupplierPartnerId, null, null, null)
                      , 0
                      , TalNumUnitsAllocated
                       );
      LotDuration         := LotDuration + GetDurationInDay(FalFactoryFloorId, null, J, JFIN);
    end if;

    HDEB    := to_char(JDEB, 'HH24');
    MDEB    := to_char(JDEB, 'MI');
    JDEB    := trunc(JDEB);
    HFIN    := to_char(JFIN, 'HH24');
    MFIN    := to_char(JFIN, 'MI');
    JFIN    := trunc(JFIN);
  end PlanOperation;

  function Get_Operation_Query(TypeEntryToPlan integer)
    return varchar2
  is
  begin
    if TypeEntryToPlan = ctIdLot then
      return ' select FAL_FACTORY_FLOOR_ID ' ||
             ' , PAC_SUPPLIER_PARTNER_ID ' ||
             ' , C_TASK_TYPE ' ||
             ' , NVL(TAL_NUM_UNITS_ALLOCATED, 1) NUM_UNITS_ALLOCATED ' ||
             ' , SCS_PLAN_PROP ' ||
             ' , TAL_PLAN_RATE ' ||
             ' , SCS_PLAN_RATE ' ||
             ' , TAL_TSK_AD_BALANCE ' ||
             ' , TAL_TSK_W_BALANCE ' ||
             ' , SCS_TRANSFERT_TIME ' ||
             ' , C_RELATION_TYPE ' ||
             ' , nvl(SCS_DELAY, 0) DELAY ' ||
             ' , nvl(TAL_DUE_QTY, 0) + greatest(nvl(TAL_SUBCONTRACT_QTY, 0), 0) TAL_DUE_QTY ' ||
             ' , 0 DELAY_ADDED ' ||
             ' from FAL_TASK_LINK ftl ' ||
             ' where FAL_LOT_ID = :aLotPropOrGammeId ' ||
             '   and nvl(TAL_DUE_QTY, 0) + greatest(nvl(TAL_SUBCONTRACT_QTY, 0), 0) > 0 ';
    elsif TypeEntryToPlan = ctIdProp then
      return ' select FAL_FACTORY_FLOOR_ID ' ||
             ' , PAC_SUPPLIER_PARTNER_ID ' ||
             ' , C_TASK_TYPE ' ||
             ' , NVL(TAL_NUM_UNITS_ALLOCATED, 1) NUM_UNITS_ALLOCATED ' ||
             ' , SCS_PLAN_PROP ' ||
             ' , TAL_PLAN_RATE ' ||
             ' , SCS_PLAN_RATE ' ||
             ' , TAL_TSK_AD_BALANCE ' ||
             ' , TAL_TSK_W_BALANCE ' ||
             ' , SCS_TRANSFERT_TIME ' ||
             ' , C_RELATION_TYPE ' ||
             ' , nvl(SCS_DELAY, 0) DELAY ' ||
             ' , nvl(TAL_DUE_QTY, 0) TAL_DUE_QTY ' ||
             ' , 0 DELAY_ADDED ' ||
             ' from FAL_TASK_LINK_PROP FTLP' ||
             ' where FAL_LOT_PROP_ID = :aLotPropOrGammeId ';
    elsif TypeEntryToPlan = ctIdGamme then
      return ' select FAL_FACTORY_FLOOR_ID ' ||
             ' , PAC_SUPPLIER_PARTNER_ID ' ||
             ' , C_TASK_TYPE ' ||
             ' , nvl(SCS_NUM_FLOOR, 1)  NUM_UNITS_ALLOCATED ' ||
             ' , SCS_PLAN_PROP ' ||
             ' , ( (:DUE_QTY / SCS_QTY_REF_WORK) * SCS_PLAN_RATE) CADENCEMENT ' ||
             ' , SCS_PLAN_RATE ' ||
             ' , decode(nvl(SCS_QTY_FIX_ADJUSTING, 0) ' ||
             '        , 0, SCS_ADJUSTING_TIME ' ||
             '        , (FAL_TOOLS.RoundSuccInt(:DUE_QTY / SCS_QTY_FIX_ADJUSTING) ) * SCS_ADJUSTING_TIME ' ||
             '         ) TSK_AD_BALANCE ' ||
             ' , ( (:DUE_QTY / SCS_QTY_REF_WORK) * SCS_WORK_TIME) TSK_W_BALANCE ' ||
             ' , SCS_TRANSFERT_TIME ' ||
             ' , C_RELATION_TYPE ' ||
             ' , nvl(SCS_DELAY, 0) DELAY ' ||
             ' , nvl(:TAL_DUE_QTY, 0) TAL_DUE_QTY ' ||
             ' , 0 DELAY_ADDED ' ||
             '  from FAL_LIST_STEP_LINK FLSP' ||
             ' where FAL_SCHEDULE_PLAN_ID = :aLotPropOrGammeId ';
    elsif TypeEntryToPlan = ctIdGalTask then
      return ' select FAL_FACTORY_FLOOR_ID ' ||
             ' , PAC_SUPPLIER_PARTNER_ID ' ||   -- Pas de sous-traitant
             ' , C_TASK_TYPE ' ||   -- toujours opération interne
             ' , NVL(TAL_NUM_UNITS_ALLOCATED, 1) NUM_UNITS_ALLOCATED ' ||
             ' , 0 SCS_PLAN_PROP ' ||   -- toujours en durée fixe
             ' , 1 TAL_PLAN_RATE ' ||   -- Cadencement
             ' , SCS_PLAN_RATE ' ||
             ' , 0 TAL_TSK_AD_BALANCE ' ||
             ' , TAL_TSK_BALANCE ' ||
             ' , SCS_TRANSFERT_TIME ' ||
             ' , C_RELATION_TYPE ' ||
             ' , nvl(SCS_DELAY, 0) DELAY ' ||
             ' , 1 TAL_DUE_QTY ' ||
             ' , 0 DELAY_ADDED ' ||
             ' from GAL_TASK_LINK GTL' ||
             ' where GAL_TASK_ID = :aLotPropOrGammeId ';
    end if;
  end Get_Operation_Query;

  -- Planification arrière. Recherche de la date début.
  function SearchBeginDate(
    aLotPropOrGammeId             number
  , UpdateBatchFields             integer
  , aDatePlanification            date
  , aQty                          number
  , TypeEntryToPlan               integer
  , TimeUnit                      integer
  , aSearchFromEndOfDay           integer
  , aSearchBackwardFromTaskLinkId number
  )
    return date
  is
    /*Curseur définissant la structure de la table de sélection des opérations */
    cursor crOperations
    is
      select FAL_FACTORY_FLOOR_ID
           , PAC_SUPPLIER_PARTNER_ID
           , C_TASK_TYPE
           , TAL_NUM_UNITS_ALLOCATED
           , SCS_PLAN_PROP
           , TAL_PLAN_RATE
           , SCS_PLAN_RATE
           , TAL_TSK_AD_BALANCE
           , TAL_TSK_W_BALANCE
           , SCS_TRANSFERT_TIME
           , C_RELATION_TYPE
           , SCS_DELAY
           , TAL_DUE_QTY
           , 0 DELAY_ADDED
        from FAL_TASK_LINK;

    /*Structure table de réception des enregistrements */
    type TTabOperations is table of crOperations%rowtype
      index by binary_integer;

    lvSqlQuery              varchar2(4000);
    lTabOperations          TTabOperations;
    LastSuccessorBeginDate  date;
    aBeginDate              date;
    nWorkshopCapacity       number;   -- Anciennement C
    lnDurationToPlan        number;
    DurationInDay           number;
    DurationInMinutes       number;
    SoldeTravailMinute      number;
    lbPreviousOpIsParallel  boolean;
    LastParallelBegindate   date;
    SumOfBatchDuration      number;
    aPeriodStartDate        date;
    aPeriodEndDate          date;
    dLastLinkedOpeBeginDate date;
    lnDelay                 number;
    lDatePlanification      date;
  begin
    lvSqlQuery              := Get_Operation_Query(TypeEntryToPlan);

    if     (TypeEntryToPlan = ctIdLot)
       and (aSearchBackwardFromTaskLinkId is not null) then
      lvSqlQuery  :=
        lvSqlQuery ||
        ' AND SCS_STEP_NUMBER <= ' ||
        '(SELECT SCS_STEP_NUMBER FROM FAL_TASK_LINK WHERE FAL_SCHEDULE_STEP_ID = ' ||
        aSearchBackwardFromTaskLinkId ||
        ')';
    end if;

    lvSqlQuery              := lvSqlQuery || ' order by SCS_STEP_NUMBER ';

    if TypeEntryToPlan = ctIdGamme then
      execute immediate lvSqlQuery
      bulk collect into lTabOperations
                  using aQty, aQty, aQty, aQty, aLotPropOrGammeId;
    else
      execute immediate lvSqlQuery
      bulk collect into lTabOperations
                  using aLotPropOrGammeId;
    end if;

    -- Initialisation des différentes variables on part de la fin de la journée, ou da la date
    -- exacte si besoin
    if (aSearchBackwardFromTaskLinkId is null) then
      lDatePlanification  := aDatePlanification;
    else
      select TAL_END_PLAN_DATE
        into lDatePlanification
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = aSearchBackwardFromTaskLinkId;
    end if;

    if aSearchFromEndOfDay = 1 then
      LastSuccessorBeginDate   := trunc(lDatePlanification) + 1 -(1 / 1440);
      LastParallelBeginDate    := trunc(lDatePlanification) + 1 -(1 / 1440);
      dLastLinkedOpeBeginDate  := trunc(lDatePlanification) + 1 -(1 / 1440);
      aBeginDate               := trunc(lDatePlanification) + 1 -(1 / 1440);
    else
      LastSuccessorBeginDate   := lDatePlanification;
      LastParallelBeginDate    := lDatePlanification;
      dLastLinkedOpeBeginDate  := lDatePlanification;
      aBeginDate               := lDatePlanification;
    end if;

    lbPreviousOpIsParallel  := false;
    SumOfBatchDuration      := 0;
    lnDelay                 := 0;

    if lTabOperations.count > 0 then
      /* parcours en avant des opérations pour cumuler les retard des opérations parallèles pour les prendre en compte ensuite sur la planif arrière */
      for i in lTabOperations.first .. lTabOperations.last loop
        if     lTabOperations(i).C_RELATION_TYPE in('2', '4', '5')
           and lbPreviousOpIsParallel then
          lnDelay  := lnDelay + lTabOperations(i).SCS_DELAY;
        else
          lnDelay  := lTabOperations(i).SCS_DELAY;
        end if;

        lTabOperations(i).DELAY_ADDED  := lnDelay;
        lbPreviousOpIsParallel         :=(lTabOperations(i).C_RELATION_TYPE in('2', '4', '5') );
      end loop;

      lbPreviousOpIsParallel  := false;

      /* parcours en arrière des opérations pour rechercher la date début par rapport à la date fin */
      for i in reverse lTabOperations.first .. lTabOperations.last loop
        -- Si Op précédente est parallèle
        if lbPreviousOpIsParallel then
          aBeginDate  := greatest(LastSuccessorBegindate, dLastLinkedOpeBeginDate);
        else
          aBeginDate  := LastParallelBeginDate;
        end if;

        LastSuccessorBegindate  := aBeginDate;
        lnDelay                 := lTabOperations(i).DELAY_ADDED * TimeUnit;
        -- Recherche de la première période active en arrière de la Date fin Plannification demandée
        GetValuesCalendar(aFalFactoryFloorId      => lTabOperations(i).FAL_FACTORY_FLOOR_ID
                        , aPacSupplierPartnerId   => lTabOperations(i).PAC_SUPPLIER_PARTNER_ID
                        , aTypePeriod             => ctActivePeriod
                        , aDay                    => aBeginDate
                        , aCapacityMinute         => nWorkshopCapacity
                        , aForward                => false
                        , aPeriodStartDate        => aPeriodStartDate
                        , aPeriodEndDate          => aPeriodEndDate
                         );

        -- Contrôle que le nombre d'unité affectée n'est pas égale à 0.
        if    (lTabOperations(i).TAL_NUM_UNITS_ALLOCATED = 0)
           or (lTabOperations(i).TAL_DUE_QTY = 0) then
          lnDurationToPlan  := 0;
        else
          if lTabOperations(i).SCS_PLAN_PROP = 1 then
            DurationInDay  :=
                     (nvl(lTabOperations(i).TAL_PLAN_RATE, 0) * to_number(PCS.PC_CONFIG.GetConfig('PPS_RATE_DAY') ) )
                     / lTabOperations(i).TAL_NUM_UNITS_ALLOCATED;
          else
            DurationInDay  := nvl(lTabOperations(i).SCS_PLAN_RATE, 0) * to_number(PCS.PC_CONFIG.GetConfig('PPS_RATE_DAY') );
          end if;

          if lTabOperations(i).C_TASK_TYPE = 2 then
            -- Opération externe
            SoldeTravailMinute  := 0;
          else
            -- Opération interne : Détermination du solde travail minute
            SoldeTravailMinute  :=
              FAL_LIB_TASK_LINK.getMinutesWorkBalance(iC_TASK_TYPE               => lTabOperations(i).C_TASK_TYPE
                                                    , iTAL_TSK_AD_BALANCE        => lTabOperations(i).TAL_TSK_AD_BALANCE
                                                    , iTAL_TSK_W_BALANCE         => lTabOperations(i).TAL_TSK_W_BALANCE
                                                    , iTAL_NUM_UNITS_ALLOCATED   => lTabOperations(i).TAL_NUM_UNITS_ALLOCATED
                                                    , iSCS_TRANSFERT_TIME        => lTabOperations(i).SCS_TRANSFERT_TIME
                                                     ) +
              lnDelay;
          end if;

          DurationInMinutes   :=
              GetDurationInMinutes(lTabOperations(i).FAL_FACTORY_FLOOR_ID, lTabOperations(i).PAC_SUPPLIER_PARTNER_ID, DurationInDay, aBeginDate, false)
              + lnDelay;
          -- La durée de la tâche est le plus grand des deux
          lnDurationToPlan    := greatest(DurationInMinutes, SoldeTravailMinute);
          SumOfBatchDuration  := SumOfBatchDuration + lnDurationToPlan;
        end if;

        if lnDurationToPlan > 0 then
          loop
            if lnDurationToPlan <= nWorkshopCapacity then   -- Si la tâche tient dans la journée en cours
              aBeginDate  := aBeginDate -(lnDurationToPlan / 1440);
              exit;
            else   -- lnDurationToPlan > nWorkshopCapacity = la tâche ne tient pas dans la période
              -- Changement de période
              lnDurationToPlan  := lnDurationToPlan - nWorkshopCapacity;
              GetValuesCalendar(aFalFactoryFloorId      => lTabOperations(i).FAL_FACTORY_FLOOR_ID
                              , aPacSupplierPartnerId   => lTabOperations(i).PAC_SUPPLIER_PARTNER_ID
                              , aTypePeriod             => ctNextPeriod
                              , aDay                    => aBeginDate
                              , aCapacityMinute         => nWorkshopCapacity
                              , aForward                => false
                              , aPeriodStartDate        => aPeriodStartDate
                              , aPeriodEndDate          => aPeriodEndDate
                               );
            end if;
          end loop;
        end if;

        LastParallelBeginDate   := least(LastParallelBeginDate, aBegindate);

        -- Si op parallèle
        if lTabOperations(i).C_RELATION_TYPE in('2', '4', '5') then
          lbPreviousOpIsParallel  := true;
        else
          lbPreviousOpIsParallel  := false;

          if lTabOperations(i).C_RELATION_TYPE <> '3' then
            dLastLinkedOpeBeginDate  := LastParallelBeginDate;
          end if;
        end if;
      end loop;
    end if;

    aBeginDate              := LastParallelBeginDate;

    if SumOfBatchDuration <> 0 then
      GetValuesCalendar(aFalFactoryFloorId      => lTabOperations(lTabOperations.first).FAL_FACTORY_FLOOR_ID
                      , aPacSupplierPartnerId   => lTabOperations(lTabOperations.first).PAC_SUPPLIER_PARTNER_ID
                      , aTypePeriod             => ctActivePeriod
                      , aDay                    => aBeginDate
                      , aCapacityMinute         => nWorkshopCapacity
                      , aForward                => false
                      , aPeriodStartDate        => aPeriodStartDate
                      , aPeriodEndDate          => aPeriodEndDate
                       );
    end if;

    aBeginDate              := AffectDayHourMinut(trunc(aBeginDate), to_char(aBeginDate, 'HH24'), to_char(aBeginDate, 'MI') );

    if UpdateBatchFields = 1 then
      MAJ_DateDebutPlanifLot(aLotPropOrGammeId, TypeEntryToPlan, aBeginDate);
    end if;

    return aBeginDate;
  end SearchBeginDate;

  -- Planif selon opération
  procedure PlanningByOperation(
    aLotPropOrGammeId                    number
  , UpdateBatchFields                    integer
  , aDatePlanification                   date
  , PlanificationType                    integer
  , aQty                                 number
  , aAllInInfiniteCap                    number
  , FLotBeginDate                 in out date
  , FLotEndDate                   in out date
  , FLotDuration                  in out number
  , aFAL_TASK_LINK_ID                    number
  , aSearchFromEndOfDay                  integer
  , aUpdateCSTDelay                      integer
  , aSearchBackwardFromTaskLinkId        number
  , aSupplierPartnerId                   number default null
  )
  is
    cursor Cur_Ope_Lot(aLotPropOrGammeId number)
    is
      select   FAL_SCHEDULE_STEP_ID
             , FAL_FACTORY_FLOOR_ID
             , nvl(aSupplierPartnerId, PAC_SUPPLIER_PARTNER_ID) PAC_SUPPLIER_PARTNER_ID
             , C_TASK_TYPE
             , nvl(TAL_NUM_UNITS_ALLOCATED, 1) TAL_NUM_UNITS_ALLOCATED
             , SCS_PLAN_PROP
             , TAL_PLAN_RATE
             , SCS_PLAN_RATE
             , TAL_TSK_AD_BALANCE
             , TAL_TSK_W_BALANCE
             , SCS_TRANSFERT_TIME
             , C_RELATION_TYPE
             , SCS_DELAY
             , nvl(TAL_DUE_QTY, 0) + greatest(nvl(TAL_SUBCONTRACT_QTY, 0), 0) TAL_DUE_QTY
             , SCS_OPEN_TIME_MACHINE
          from FAL_TASK_LINK
         where FAL_LOT_ID = aLotPropOrGammeId
           and (   nvl(aFAL_TASK_LINK_ID, 0) = 0
                or FAL_SCHEDULE_STEP_ID = aFAL_TASK_LINK_ID)
      order by SCS_STEP_NUMBER asc;

    cursor Cur_Ope_Prop(aLotPropOrGammeId number)
    is
      select   FAL_TASK_LINK_PROP_ID
             , FAL_FACTORY_FLOOR_ID
             , nvl(aSupplierPartnerId, PAC_SUPPLIER_PARTNER_ID) PAC_SUPPLIER_PARTNER_ID
             , C_TASK_TYPE
             , nvl(TAL_NUM_UNITS_ALLOCATED, 1) TAL_NUM_UNITS_ALLOCATED
             , SCS_PLAN_PROP
             , TAL_PLAN_RATE
             , SCS_PLAN_RATE
             , TAL_TSK_AD_BALANCE
             , TAL_TSK_W_BALANCE
             , SCS_TRANSFERT_TIME
             , C_RELATION_TYPE
             , SCS_DELAY
             , nvl(TAL_DUE_QTY, 0) TAL_DUE_QTY
             , SCS_OPEN_TIME_MACHINE
          from FAL_TASK_LINK_PROP
         where FAL_LOT_PROP_ID = aLotPropOrGammeId
           and (   nvl(aFAL_TASK_LINK_ID, 0) = 0
                or FAL_TASK_LINK_PROP_ID = aFAL_TASK_LINK_ID)
      order by SCS_STEP_NUMBER asc;

    cursor Cur_Ope_Gamme(aGammeID number, aQty number)
    is
      select   FAL_SCHEDULE_STEP_ID
             , FAL_FACTORY_FLOOR_ID
             , nvl(aSupplierPartnerId, PAC_SUPPLIER_PARTNER_ID) PAC_SUPPLIER_PARTNER_ID
             , C_TASK_TYPE
             , nvl(SCS_NUM_FLOOR, 1) SCS_NUM_FLOOR   -- Nbre ressources affectées
             , SCS_PLAN_PROP
             , ( (aQty / SCS_QTY_REF_WORK) * SCS_PLAN_RATE) CADENCEMENT   -- Cadencement
             , SCS_PLAN_RATE
             , decode(nvl(SCS_QTY_FIX_ADJUSTING, 0), 0, SCS_ADJUSTING_TIME,(FAL_TOOLS.RoundSuccInt(aQty / SCS_QTY_FIX_ADJUSTING) ) * SCS_ADJUSTING_TIME)
                                                                                                                                                 TSK_AD_BALANCE   -- SoldeReglage
             , ( (aQty / SCS_QTY_REF_WORK) * SCS_WORK_TIME) TSK_W_BALANCE   -- SoldeTravail
             , SCS_TRANSFERT_TIME
             , C_RELATION_TYPE
             , SCS_DELAY
             , SCS_OPEN_TIME_MACHINE
          from FAL_LIST_STEP_LINK
         where FAL_SCHEDULE_PLAN_ID = aGammeID
           and (   nvl(aFAL_TASK_LINK_ID, 0) = 0
                or FAL_SCHEDULE_STEP_ID = aFAL_TASK_LINK_ID)
      order by SCS_STEP_NUMBER asc;

    cursor Cur_Ope_GalTask(aGalTaskID number)
    is
      select   GAL_TASK_LINK_ID
             , FAL_FACTORY_FLOOR_ID
             , (case
                  when C_TASK_TYPE = '1' then nvl(TAL_NUM_UNITS_ALLOCATED, 1)
                  else 1
                end) TAL_NUM_UNITS_ALLOCATED
             , SCS_PLAN_RATE
             , TAL_TSK_BALANCE
             , SCS_TRANSFERT_TIME
             , C_RELATION_TYPE
             , SCS_DELAY
             , C_TASK_TYPE
             , nvl(aSupplierPartnerId, PAC_SUPPLIER_PARTNER_ID) PAC_SUPPLIER_PARTNER_ID
          from GAL_TASK_LINK
         where GAL_TASK_ID = aGalTaskID
           and (   nvl(aFAL_TASK_LINK_ID, 0) = 0
                or GAL_TASK_LINK_ID = aFAL_TASK_LINK_ID)
      order by SCS_STEP_NUMBER asc;

    JDEB             date;
    HDEB             number;
    MDEB             number;
    JFIN             date;
    HFIN             number;
    MFIN             number;
    REPT             number;
    IsFirstOperation boolean;
    TypeEntryToPlan  integer;
    TimeUnit         integer;
    aLoadDate        date;
    dLastTaskEndDate date;
    bIsParallel      boolean;
  begin
    LoadAllResourcesSchedules;

    -- Récupération de l'unité de temps
    if (PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT') = 'M') then
      TimeUnit  := 1;
    else
      TimeUnit  := 60;
    end if;

    -- Recherche du type d'élément à planifier, lot, proposition, gamme ou tâche affaire
    TypeEntryToPlan   := CheckLotId(aLotPropOrGammeId);

    -- Recherche et positionnement de la date début du lot selon la liste de tâches
    if    (PlanificationType = ctDateFin)
       or aSearchBackwardFromTaskLinkId is not null then
      FLotBeginDate  :=
        SearchBeginDate(aLotPropOrGammeId
                      , UpdateBatchFields
                      , aDatePlanification
                      , aQty
                      , TypeEntryToPlan
                      , TimeUnit
                      , aSearchFromEndOfDay
                      , aSearchBackwardFromTaskLinkId
                       );
    -- Détermination de la date de planification de référence
    elsif(PlanificationType = ctDateDebut) then
      FLotBeginDate  := aDatePlanification;
    end if;

    if aAllInInfiniteCap = 0 then
      -- Recherche de la date début du chargement en mémoire des capacités de la ressource concernée
      begin
        select min(BeginDate)
          into aLoadDate
          from (select trunc(nvl(min(TAL_LOT.TAL_BEGIN_PLAN_DATE), sysdate) - 1) as BeginDate
                  from FAL_LOT LOT
                     , FAL_TASK_LINK TAL_LOT
                 where LOT.C_LOT_STATUS in('1', '2')
                   and LOT.C_SCHEDULE_PLANNING <> '1'
                   and TAL_LOT.FAL_LOT_ID = LOT.FAL_LOT_ID
                   and (   TAL_LOT.FAL_FACTORY_FLOOR_ID in(select FAL_FACTORY_FLOOR_ID
                                                             from FAL_LIST_STEP_LINK
                                                            where FAL_SCHEDULE_PLAN_ID = aLotPropOrGammeId)
                        or TAL_LOT.PAC_SUPPLIER_PARTNER_ID in(select PAC_SUPPLIER_PARTNER_ID
                                                                from FAL_LIST_STEP_LINK
                                                               where FAL_SCHEDULE_PLAN_ID = aLotPropOrGammeId)
                       )
                   and nvl(TAL_LOT.TAL_DUE_QTY, 0) + greatest(nvl(TAL_LOT.TAL_SUBCONTRACT_QTY, 0), 0) > 0
                   and TAL_LOT.TAL_BEGIN_PLAN_DATE is not null
                   and TAL_LOT.TAL_END_PLAN_DATE is not null
                   and TAL_LOT.TAL_BEGIN_PLAN_DATE < FLotBeginDate
                union all
                select trunc(nvl(min(TAL_PROP.TAL_BEGIN_PLAN_DATE), sysdate) - 1) as BeginDate
                  from FAL_LOT_PROP PROP
                     , FAL_TASK_LINK_PROP TAL_PROP
                 where PROP.C_SCHEDULE_PLANNING <> '1'
                   and TAL_PROP.FAL_LOT_PROP_ID = PROP.FAL_LOT_PROP_ID
                   and (   TAL_PROP.FAL_FACTORY_FLOOR_ID in(select FAL_FACTORY_FLOOR_ID
                                                              from FAL_LIST_STEP_LINK
                                                             where FAL_SCHEDULE_PLAN_ID = aLotPropOrGammeId)
                        or TAL_PROP.PAC_SUPPLIER_PARTNER_ID in(select PAC_SUPPLIER_PARTNER_ID
                                                                 from FAL_LIST_STEP_LINK
                                                                where FAL_SCHEDULE_PLAN_ID = aLotPropOrGammeId)
                       )
                   and nvl(TAL_DUE_QTY, 0) > 0
                   and TAL_PROP.TAL_BEGIN_PLAN_DATE is not null
                   and TAL_PROP.TAL_END_PLAN_DATE is not null
                   and TAL_PROP.TAL_BEGIN_PLAN_DATE < FLotBeginDate);
      exception
        when others then
          aLoadDate  := sysdate - 1;
      end;
    else
      aLoadDate  := trunc(least(sysdate, FLotBeginDate) );
    end if;

    -- Initialisation des différentes variables
    JDEB              := AffectDayHourMinut(FLotBeginDate, 0, 0);
    JFIN              := AffectDayHourMinut(FLotBeginDate, 0, 0);
    HDEB              := to_char(FLotBeginDate, 'HH24');
    MDEB              := to_char(FLotBeginDate, 'MI');
    HFIN              := to_char(FLotBeginDate, 'HH24');
    MFIN              := to_char(FLotBeginDate, 'MI');
    REPT              := (HDEB * 60) + MDEB;
    -- Indicateur du nombre de jours ouvrés travaillés
    FLotDuration      := 0;
    IsFirstOperation  := true;
    dLastTaskEndDate  := JFIN;
    bIsParallel       := false;

    if TypeEntryToPlan = ctIdLot then
      for CurOperation in Cur_Ope_Lot(aLotPropOrGammeId) loop
        -- Parallèle si type 2 ou 4 (syncho début-début) ou si 3 (lien solide) rattaché à une opération parallèle
        bIsParallel  :=    CurOperation.C_RELATION_TYPE in('2', '4', '5')
                        or (    bIsParallel
                            and CurOperation.C_RELATION_TYPE = '3');
        PlanOperation(ctIdLot
                    , UpdateBatchFields
                    , CurOperation.FAL_SCHEDULE_STEP_ID
                    , CurOperation.C_TASK_TYPE
                    , CurOperation.FAL_FACTORY_FLOOR_ID
                    , CurOperation.SCS_DELAY
                    , CurOperation.C_RELATION_TYPE
                    , CurOperation.PAC_SUPPLIER_PARTNER_ID
                    , CurOperation.TAL_NUM_UNITS_ALLOCATED
                    , CurOperation.TAL_DUE_QTY
                    , CurOperation.SCS_PLAN_PROP
                    , CurOperation.TAL_PLAN_RATE
                    , CurOperation.SCS_PLAN_RATE
                    , CurOperation.TAL_TSK_AD_BALANCE
                    , CurOperation.TAL_TSK_W_BALANCE
                    , CurOperation.SCS_TRANSFERT_TIME
                    , CurOperation.SCS_OPEN_TIME_MACHINE
                    , aAllInInfiniteCap
                    , bIsParallel
                    , TimeUnit
                    , JDEB   -- in out
                    , JFIN   -- in out
                    , HDEB   -- in out
                    , MDEB   -- in out
                    , HFIN   -- in out
                    , MFIN   -- in out
                    , REPT   -- in out
                    , FLotDuration   -- in out
                    , dLastTaskEndDate
                    , aUpdateCSTDelay
                     );

        if IsFirstOperation then
          FLotBeginDate     := AffectDayHourMinut(JDEB, HDEB, MDEB);
          IsFirstOperation  := false;
        end if;
      end loop;
    elsif TypeEntryToPlan = ctIdProp then
      for CurOperation in Cur_Ope_Prop(aLotPropOrGammeId) loop
        -- Parallèle si type 2 ou 4 (syncho début-début) ou si 3 (lien solide) rattaché à une opération parallèle
        bIsParallel  :=    CurOperation.C_RELATION_TYPE in('2', '4', '5')
                        or (    bIsParallel
                            and CurOperation.C_RELATION_TYPE = '3');
        PlanOperation(ctIdProp
                    , UpdateBatchFields
                    , CurOperation.FAL_TASK_LINK_PROP_ID
                    , CurOperation.C_TASK_TYPE
                    , CurOperation.FAL_FACTORY_FLOOR_ID
                    , CurOperation.SCS_DELAY
                    , CurOperation.C_RELATION_TYPE
                    , CurOperation.PAC_SUPPLIER_PARTNER_ID
                    , CurOperation.TAL_NUM_UNITS_ALLOCATED
                    , CurOperation.TAL_DUE_QTY
                    , CurOperation.SCS_PLAN_PROP
                    , CurOperation.TAL_PLAN_RATE
                    , CurOperation.SCS_PLAN_RATE
                    , CurOperation.TAL_TSK_AD_BALANCE
                    , CurOperation.TAL_TSK_W_BALANCE
                    , CurOperation.SCS_TRANSFERT_TIME
                    , CurOperation.SCS_OPEN_TIME_MACHINE
                    , aAllInInfiniteCap
                    , bIsParallel
                    , TimeUnit
                    , JDEB   -- in out
                    , JFIN   -- in out
                    , HDEB   -- in out
                    , MDEB   -- in out
                    , HFIN   -- in out
                    , MFIN   -- in out
                    , REPT   -- in out
                    , FLotDuration   -- in out
                    , dLastTaskEndDate
                    , aUpdateCSTDelay
                     );

        if IsFirstOperation then
          FLotBeginDate     := AffectDayHourMinut(JDEB, HDEB, MDEB);
          IsFirstOperation  := false;
        end if;
      end loop;
    elsif TypeEntryToPlan = ctIdGamme then
      for CurOperation in Cur_Ope_Gamme(aLotPropOrGammeId, aQty) loop
        -- Parallèle si type 2 ou 4 (syncho début-début) ou si 3 (lien solide) rattaché à une opération parallèle
        bIsParallel  :=    CurOperation.C_RELATION_TYPE in('2', '4', '5')
                        or (    bIsParallel
                            and CurOperation.C_RELATION_TYPE = '3');
        PlanOperation(ctIdGamme
                    , UpdateBatchFields
                    , CurOperation.FAL_SCHEDULE_STEP_ID
                    , CurOperation.C_TASK_TYPE
                    , CurOperation.FAL_FACTORY_FLOOR_ID
                    , CurOperation.SCS_DELAY
                    , CurOperation.C_RELATION_TYPE
                    , CurOperation.PAC_SUPPLIER_PARTNER_ID
                    , CurOperation.SCS_NUM_FLOOR
                    , aQty
                    , CurOperation.SCS_PLAN_PROP
                    , CurOperation.CADENCEMENT
                    , CurOperation.SCS_PLAN_RATE
                    , CurOperation.TSK_AD_BALANCE
                    , CurOperation.TSK_W_BALANCE
                    , CurOperation.SCS_TRANSFERT_TIME
                    , CurOperation.SCS_OPEN_TIME_MACHINE
                    , aAllInInfiniteCap
                    , bIsParallel
                    , TimeUnit
                    , JDEB   -- in out
                    , JFIN   -- in out
                    , HDEB   -- in out
                    , MDEB   -- in out
                    , HFIN   -- in out
                    , MFIN   -- in out
                    , REPT   -- in out
                    , FLotDuration   -- in out
                    , dLastTaskEndDate
                    , aUpdateCSTDelay
                     );

        if IsFirstOperation then
          FLotBeginDate     := AffectDayHourMinut(JDEB, HDEB, MDEB);
          IsFirstOperation  := false;
        end if;
      end loop;
    elsif TypeEntryToPlan = ctIdGalTask then
      for CurOperation in Cur_Ope_GalTask(aLotPropOrGammeId) loop
        -- Parallèle si type 2 ou 4 (syncho début-début) ou si 3 (lien solide) rattaché à une opération parallèle
        bIsParallel  :=    CurOperation.C_RELATION_TYPE in('2', '4', '5')
                        or (    bIsParallel
                            and CurOperation.C_RELATION_TYPE = '3');
        PlanOperation(ctIdGalTask
                    , UpdateBatchFields
                    , CurOperation.GAL_TASK_LINK_ID
                    , CurOperation.C_TASK_TYPE
                    , CurOperation.FAL_FACTORY_FLOOR_ID
                    , CurOperation.SCS_DELAY
                    , CurOperation.C_RELATION_TYPE
                    , CurOperation.PAC_SUPPLIER_PARTNER_ID
                    , CurOperation.TAL_NUM_UNITS_ALLOCATED
                    , 1   -- TAL_DUE_QTY
                    , 0   -- SCS_PLAN_PROP toujours en durée fixe
                    , 1   -- TAL_PLAN_RATE -- Cadencement
                    , CurOperation.SCS_PLAN_RATE
                    , 0   -- TAL_TSK_AD_BALANCE
                    , CurOperation.TAL_TSK_BALANCE
                    , CurOperation.SCS_TRANSFERT_TIME
                    , 0   -- SCS_OPEN_TIME_MACHINE
                    , aAllInInfiniteCap
                    , bIsParallel
                    , TimeUnit
                    , JDEB   -- in out
                    , JFIN   -- in out
                    , HDEB   -- in out
                    , MDEB   -- in out
                    , HFIN   -- in out
                    , MFIN   -- in out
                    , REPT   -- in out
                    , FLotDuration   -- in out
                    , dLastTaskEndDate
                    , aUpdateCSTDelay
                     );

        if IsFirstOperation then
          FLotBeginDate     := AffectDayHourMinut(JDEB, HDEB, MDEB);
          IsFirstOperation  := false;
        end if;
      end loop;
    end if;

    FLotEndDate       := AffectDayHourMinut(JFIN, HFIN, MFIN);

    -- Mise à jour des champs calculés
    if UpdateBatchFields = 1 then
      -- Change la date planifiée début du lot
      MAJ_DateDebutPlanifLot(aLotPropOrGammeId, TypeEntryToPlan, FLotBeginDate);
      -- Change la date planifiée fin du lot
      MAJ_DateFinPlanifLot(aLotPropOrGammeId, TypeEntryToPlan, FLotEndDate);
      -- Change la durée planifiée fin du lot
      MAJ_TempsTravailLot(aLotPropOrGammeId, TypeEntryToPlan, FLotDuration);
    end if;
  end PlanningByOperation;

  -- Planif selon opération, en tenant compte d'une capacité moyenne.
  procedure PlanningOpWithAvgCapacity(aLotPropOrGammeId number, aQty number, FLotDuration in out number, aStartDate in date, aEndDate in date)
  is
    cursor Cur_Ope_Gamme(aGammeID number, aQty number)
    is
      select   FAL_SCHEDULE_STEP_ID
             , FAL_FACTORY_FLOOR_ID
             , PAC_SUPPLIER_PARTNER_ID
             , C_TASK_TYPE
             , SCS_NUM_FLOOR
             , SCS_PLAN_PROP
             , ( (aQty / SCS_QTY_REF_WORK) * SCS_PLAN_RATE) CADENCEMENT
             , SCS_PLAN_RATE
             , decode(nvl(SCS_QTY_FIX_ADJUSTING, 0), 0, SCS_ADJUSTING_TIME,(FAL_TOOLS.RoundSuccInt(aQty / SCS_QTY_FIX_ADJUSTING) ) * SCS_ADJUSTING_TIME)
                                                                                                                                                 TSK_AD_BALANCE
             , ( (aQty / SCS_QTY_REF_WORK) * SCS_WORK_TIME) TSK_W_BALANCE
             , SCS_TRANSFERT_TIME
             , C_RELATION_TYPE
             , SCS_DELAY
             , nvl( (select NEXT_OP1.C_RELATION_TYPE
                       from FAL_LIST_STEP_LINK NEXT_OP1
                      where NEXT_OP1.FAL_SCHEDULE_PLAN_ID = aGammeID
                        and NEXT_OP1.SCS_STEP_NUMBER = (select min(NEXT_OP2.SCS_STEP_NUMBER)
                                                          from FAL_LIST_STEP_LINK NEXT_OP2
                                                         where NEXT_OP2.FAL_SCHEDULE_PLAN_ID = aGammeID
                                                           and NEXT_OP2.SCS_STEP_NUMBER > LSL.SCS_STEP_NUMBER) )
                 , '1'
                  ) NEXT_OP_REL_TYPE
          from FAL_LIST_STEP_LINK LSL
         where FAL_SCHEDULE_PLAN_ID = aGammeID
      order by SCS_STEP_NUMBER asc;

    TimeUnit            integer;
    aResourceCapacity   number;
    aResourceOpenTime   number;
    aResourceOpenDays   number;
    aFilter             varchar2(30);
    aFilterID           number;
    aCalendarID         number;
    DurationInDays      number;
    WorkBalanceInDays   number;
    MaxParallelDuration number;
  begin
    -- Récupération de l'unité de temps
    if (PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT') = 'M') then
      TimeUnit  := 1;
    else
      TimeUnit  := 60;
    end if;

    -- Indicateur du nombre de jours ouvrés travaillés
    FLotDuration         := 0;
    MaxParallelDuration  := 0;

    -- Parcours des opérations.
    for CurOperation in Cur_Ope_Gamme(aLotPropOrGammeId, aQty) loop
      aResourceCapacity  := 0;
      aResourceOpenTime  := 0;
      aResourceOpenDays  := 0;

      -- Calcul de la capacité de la ressource
      if CurOperation.Fal_factory_floor_id is not null then
        aFilter      := 'FACTORY_FLOOR';
        aFilterID    := CurOperation.Fal_factory_floor_id;
        aCalendarID  := FAL_SCHEDULE_FUNCTIONS.GetFloorCalendar(CurOperation.Fal_factory_floor_id);
      else
        aFilter      := 'SUPPLIER';
        aFilterID    := CurOperation.pac_supplier_partner_id;
        aCalendarID  := FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendar(CurOperation.pac_supplier_partner_id);
      end if;

      PAC_I_LIB_SCHEDULE.CalcOpenTimeBetween(aResourceOpenTime, aCalendarID, aStartDate, aEndDate, aFilter, aFilterID);
      aResourceOpenDays  := PAC_I_LIB_SCHEDULE.GetOpenDaysBetween(aCalendarID, aStartDate, aEndDate, aFilter, aFilterID);

      if nvl(aResourceOpenDays, 0) <> 0 then
        aResourceCapacity  := (aResourceOpenTime * 60) / aResourceOpenDays;
      else
        aResourceCapacity  := 0;
      end if;

      -- Si capacité non nulle, calcul de la durée de l'op
      if aResourceCapacity <> 0 then
        DurationInDays     := 0;
        WorkBalanceInDays  := 0;

        -- Calcul de la durée de l'op courante en nombre de jours ouvrés
        if    (nvl(CurOperation.SCS_NUM_FLOOR, 0) = 0)
           or (nvl(aQty, 0) = 0) then
          DurationInDays  := 0;
        else
          -- Durée tâche.
          if CurOperation.Scs_Plan_Prop = 1 then
            DurationInDays  :=( (nvl(CurOperation.cadencement, 0) * to_number(PCS.PC_CONFIG.GetConfig('PPS_RATE_DAY') ) ) / nvl(CurOperation.SCS_NUM_FLOOR, 1) );
          else
            DurationInDays  := nvl(CurOperation.scs_plan_rate, 0) * to_number(PCS.PC_CONFIG.GetConfig('PPS_RATE_DAY') );
          end if;

          -- Travail tâche.
          if CurOperation.C_Task_Type = '2' then
            WorkBalanceInDays  := 0;
          else
            WorkBalanceInDays  :=
              ( (nvl(CurOperation.TSK_AD_BALANCE, 0) +
                 nvl(CurOperation.Tsk_W_Balance, 0) / nvl(CurOperation.SCS_NUM_FLOOR, 1) +
                 nvl(CurOperation.Scs_Transfert_Time, 0)
                ) *
               TimeUnit
              ) /
              aResourceCapacity;
          end if;

          -- Durée en jours ouvrés.
          DurationInDays  := greatest(DurationInDays, WorkBalanceInDays);
          -- Ajout du retard
          DurationInDays  := DurationInDays +(nvl(CurOperation.SCS_DELAY, 0) / 60);
        end if;
      end if;

      -- Si Op Sucesseur et suivante parallele ou op parallele
      if    CurOperation.C_RELATION_TYPE in('2', '4', '5')
         or CurOperation.NEXT_OP_REL_TYPE in('2', '4', '5') then
        MaxParallelDuration  := greatest(MaxParallelDuration, DurationInDays);
      else
        MaxParallelDuration  := 0;
      end if;

      -- Si opération successeur et op suivante sucesseur
      if     CurOperation.C_RELATION_TYPE in('1', '3')
         and CurOperation.NEXT_OP_REL_TYPE in('1', '3') then
        FLotDuration  := FLotDuration + DurationInDays;
      elsif     CurOperation.C_RELATION_TYPE in('2', '4', '5')
            and CurOperation.NEXT_OP_REL_TYPE in('1', '3') then
        FLotDuration  := FLotDuration + MaxParallelDuration;
      end if;
    end loop;
  end PlanningOpWithAvgCapacity;

  -- Contrôle de validité sur les informations en entrées avant le lancement des processus
  procedure ControleValiditeInfos(
    CSchedulePlanning  FAL_LOT.C_SCHEDULE_PLANNING%type
  , GcoGoodId          number
  , LotPlanBeginDate   FAL_LOT.LOT_PLAN_BEGIN_DTE%type
  , LotPlanEndDate     FAL_LOT.LOT_PLAN_END_DTE%type
  , aDatePlanification date
  , aPlanificationType integer
  )
  is
  begin
    if to_number(CSchedulePlanning) = 1 then
      -- Contrôle sur le GCO_GOOD_ID
      if GcoGoodId is null then
        -- Planification impossible, le produit est inconnu.
        raise_application_error(-20014, 'PCS - GCO_GOOD_ID must be not null');
      end if;
    end if;

    if aDatePlanification is null then
      -- Selon le type de planification (date début ou date fin)
      if aPlanificationType = ctDateDebut then
        -- Contrôle sur la date début
        if LotPlanBeginDate is null then
          -- Planification impossible, la date début est inconnue.
          raise_application_error(-20015, 'PCS - Begin Date must be not null');
        end if;
      else
        -- Contrôle sur la date fin
        if LotPlanEndDate is null then
          -- Planification impossible, la date fin est inconnue.
          raise_application_error(-20016, 'PCS - End Date must be not null');
        end if;
      end if;
    end if;
  end ControleValiditeInfos;

  -- Processus de planification selon produit
  procedure PlanningByProduct(
    aLotPropOrGammeId            number
  , aPlanificationType           integer
  , aDatePlanification           date
  , aGCO_GOOD_ID                 number
  , aDIC_FAB_CONDITION_ID        FAL_LOT.DIC_FAB_CONDITION_ID%type
  , aLOT_TOTAL_QTY               FAL_LOT.LOT_TOTAL_QTY%type
  , aLOT_TOLERANCE               FAL_LOT.LOT_TOLERANCE%type
  , FLotBeginDate         in out date
  , FLotEndDate           in out date
  , FLotDuration          in out number
  , UpdateBatchFields            integer
  )
  is
    cursor Cur_Compl_Data_Manufacture
    is
      select CMA_FIX_DELAY
           , nvl(CMA_MANUFACTURING_DELAY, 0) CMA_MANUFACTURING_DELAY
           , CMA_LOT_QUANTITY
        from GCO_COMPL_DATA_MANUFACTURE
       where GCO_GOOD_ID = aGCO_GOOD_ID
         and (    (    aDIC_FAB_CONDITION_ID is null
                   and CMA_DEFAULT = 1)
              or (DIC_FAB_CONDITION_ID = aDIC_FAB_CONDITION_ID) );

    X                         number;
    ValLOT_PLAN_LEAD_TIME     FAL_LOT.LOT_PLAN_LEAD_TIME%type;
    aDate                     date;
    CurCompl_Data_Manufacture Cur_Compl_Data_Manufacture%rowtype;
    TypeEntryToPlan           integer;
  begin
    TypeEntryToPlan  := CheckLotId(aLotPropOrGammeId);

    open Cur_Compl_Data_Manufacture;

    fetch Cur_Compl_Data_Manufacture
     into CurCompl_Data_Manufacture;

    if Cur_Compl_Data_Manufacture%found then
      -- Récupération Produit -> Donnée complémentaire de fabrication -> Proposition standard
      X  := nvl(CurCompl_Data_Manufacture.CMA_LOT_QUANTITY, 1);

      if CurCompl_Data_Manufacture.CMA_FIX_DELAY = 1 then
        ValLOT_PLAN_LEAD_TIME  := CurCompl_Data_Manufacture.CMA_MANUFACTURING_DELAY + nvl(aLOT_TOLERANCE, 0);
      else
        ValLOT_PLAN_LEAD_TIME  :=( ( (aLOT_TOTAL_QTY / X) * CurCompl_Data_Manufacture.CMA_MANUFACTURING_DELAY) + nvl(aLOT_TOLERANCE, 0) );
      end if;
    else
      ValLOT_PLAN_LEAD_TIME  := 0;
    end if;

    close Cur_Compl_Data_Manufacture;

    -- Change la durée planifiée fin du lot
    if UpdateBatchFields = 1 then
      MAJ_TempsTravailLot(aLotPropOrGammeId, TypeEntryToPlan, ValLOT_PLAN_LEAD_TIME);
    end if;

    FLotDuration     := ValLOT_PLAN_LEAD_TIME;
    -- Initialisation de la durée à parcourir
    X                := ValLOT_PLAN_LEAD_TIME;
    -- initialisation de la date de référence de la planif
    aDate            := aDatePlanification;

    -- Recherche du prochain jour ouvré en partant de aDate
    loop
      if PAC_I_LIB_SCHEDULE.IsOpenDay(null, aDate) = 1 then
        exit;
      end if;

      if aPlanificationType = 1 then
        aDate  := aDate + 1;
      else
        aDate  := aDate - 1;
      end if;
    end loop;

    -- Mise à jour de la date début ou fin selon le type de planification
    if aPlanificationType = 1 then
      if UpdateBatchFields = 1 then
        MAJ_DateDebutPlanifLot(aLotPropOrGammeId, TypeEntryToPlan, trunc(aDate) );
      end if;

      FLotBeginDate  := trunc(aDate);
    else
      if UpdateBatchFields = 1 then
        MAJ_DateFinPlanifLot(aLotPropOrGammeId, TypeEntryToPlan, trunc(aDate) );
      end if;

      FLotEndDate  := trunc(aDate);
    end if;

    -- Parcours selon la durée
    loop
      if PAC_I_LIB_SCHEDULE.IsOpenDay(null, aDate) = 1 then
        X  := X - 1;
      end if;

      exit when(X <= 0);

      if aPlanificationType = 1 then
        aDate  := aDate + 1;
      else
        aDate  := aDate - 1;
      end if;
    end loop;

    -- Selon le type de planification (date début ou date fin)
    if aPlanificationType = 1 then
      if UpdateBatchFields = 1 then
        MAJ_DateFinPlanifLot(aLotPropOrGammeId, TypeEntryToPlan, trunc(aDate) );
      end if;

      FLotendDate  := trunc(aDate);
    else
      if UpdateBatchFields = 1 then
        MAJ_DateDebutPlanifLot(aLotPropOrGammeId, TypeEntryToPlan, trunc(aDate) );
      end if;

      FLotbeginDate  := trunc(aDate);
    end if;
  end PlanningByProduct;

  /**
  * procédure GeneralPlanning
  * Description : Procédure générale de planification (calcul des dates)
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLotPropOrGammeId : ID de lot, proposition, tâche affaire ou gamme
  * @param   aGcoGoodId : produit
  * @param   aDicFabConditionId : Condition de fabrication
  * @param   aBeginDate : Date début lot
  * @param   aEndDate : Date fin lot
  * @param   aCSchedulePlanning : Mode de planif (produit ou op.)
  * @param   aLotTolerance : Marge
  * @param   UpdateBatchFields : MAJ des champs dates
  * @param   aDatePlanification : Date origine du calcul de planification
  * @param   PlanificationType : Planif avant ou arrière
  * @param   aQty : Qté à plannifier
  * @param   aAllInInfiniteCap : Tous les ateliers en capa infinie
  * @param  aUpdateCSTDelay : code de mise à jour du délai des commandes de sous traitance lors de la planification
  * @return  FLotBeginDate : Date début lot, ou prop...etc
  * @return  FLotEndDate : Date fin lot, ou prop...etc
  * @return  FLotDuration : Durée lot, ou prop...etc   (en Jours)
  * @param   aSearchBackwardFromTaskLinkId : utilisé uniquement si  PlanificationType = ctDateFin
  *          Défini l'opération à partir de laquelle se fait la recalculation arriere
  */
  procedure GeneralPlanning(
    aLotPropOrGammeId                    number
  , aGcoGoodId                           number
  , aDicFabConditionId                   FAL_LOT.DIC_FAB_CONDITION_ID%type
  , aBeginDate                           FAL_LOT.LOT_PLAN_BEGIN_DTE%type
  , aEndDate                             FAL_LOT.LOT_PLAN_END_DTE%type
  , aCSchedulePlanning                   FAL_LOT.C_SCHEDULE_PLANNING%type
  , aLotTolerance                        number
  , UpdatebatchFields                    integer
  , aDatePlanification                   date
  , PlanificationType                    integer
  , aQty                                 number
  , aAllInInfiniteCap                    number
  , FLotBeginDate                 in out date
  , FLotEndDate                   in out date
  , FLotDuration                  in out number
  , aSearchFromEndOfDay                  integer default 1
  , aUpdateCSTDelay                      integer default 0
  , aSearchBackwardFromTaskLinkId in     number default null
  )
  is
    aDateToPlan date;
  begin
    if aDatePlanification is not null then
      aDateToPlan  := aDatePlanification;
    else
      if (PlanificationType = ctDateDebut) then
        aDateToPlan  := aBeginDate;
      else
        aDateToPlan  := aEndDate;
      end if;
    end if;

    if aCSchedulePlanning = '1' then
      -- Planification selon produit
      PlanningByProduct(aLotPropOrGammeId
                      , PlanificationType
                      , aDateToPlan
                      , aGcoGoodId
                      , aDicFabConditionId
                      , aQty
                      , aLotTolerance
                      , FLotBeginDate
                      , FLotEndDate
                      , FLotDuration
                      , UpdateBatchFields
                       );
    else
      -- Planification selon liste de tâches
      PlanningByOperation(aLotPropOrGammeId               => aLotPropOrGammeId
                        , UpdateBatchFields               => UpdateBatchFields
                        , aDatePlanification              => aDateToPlan
                        , PlanificationType               => PlanificationType
                        , aQty                            => aQty
                        , aAllInInfiniteCap               => aAllInInfiniteCap
                        , FLotBeginDate                   => FLotBeginDate
                        , FLotEndDate                     => FLotEndDate
                        , FLotDuration                    => FLotDuration
                        , aFAL_TASK_LINK_ID               => null
                        , aSearchFromEndOfDay             => aSearchFromEndOfDay
                        , aUpdateCSTDelay                 => aUpdateCSTDelay
                        , aSearchBackwardFromTaskLinkId   => aSearchBackwardFromTaskLinkId
                         );
    end if;
  end GeneralPlanning;

  /**
  * procédure BatchPlanning
  * Description : Planification d'un lot de fabrication
  *
  * @created CLG
  * @lastUpdate
  * @public
  */
  procedure BatchPlanning(
    PrmFAL_LOT_ID                        number
  , DatePlanification                    date
  , SelonDateDebut                       integer
  , MAJReqLiensComposantsLot             integer
  , MAJ_Reseaux_Requise                  integer
  , UpdateBatchFields                    integer
  , aLotTolerance                        number
  , FLotBeginDate                 in out date
  , FLotEndDate                   in out date
  , FLotDuration                  in out number
  , aC_EVEN_TYPE                         FAL_HISTO_LOT.C_EVEN_TYPE%type default '21'
  , aDoHistorisationPlanif               integer default 1
  , aSearchFromEndOfDay                  integer default 1
  , aUpdateCSTDelay                      integer
  , aSearchBackwardFromTaskLinkId        number default null
  )
  is
    cursor Cur_Fal_Lot(PrmFAL_LOT_ID number)
    is
      select C_SCHEDULE_PLANNING
           , GCO_GOOD_ID
           , DIC_FAB_CONDITION_ID
           , LOT_PLAN_BEGIN_DTE
           , LOT_PLAN_END_DTE
           , LOT_TOTAL_QTY
        from FAL_LOT
       where FAL_LOT_ID = PrmFAL_LOT_ID;

    CurFalLot Cur_Fal_Lot%rowtype;
  begin
    open Cur_Fal_Lot(PrmFAL_LOT_ID);

    fetch Cur_Fal_Lot
     into CurFalLot;

    close Cur_Fal_Lot;

    -- Contrôle de validité sur les informations en entrées avant le lancement des processus
    ControleValiditeInfos(CurFalLot.C_SCHEDULE_PLANNING
                        , CurFalLot.GCO_GOOD_ID
                        , CurFalLot.LOT_PLAN_BEGIN_DTE
                        , CurFalLot.LOT_PLAN_END_DTE
                        , DatePlanification
                        , SelonDateDebut
                         );
    GeneralPlanning(aLotPropOrGammeId               => PrmFAL_LOT_ID
                  , aGcoGoodId                      => CurFalLot.GCO_GOOD_ID
                  , aDicFabConditionId              => CurFalLot.DIC_FAB_CONDITION_ID
                  , aBeginDate                      => CurFalLot.LOT_PLAN_BEGIN_DTE
                  , aEndDate                        => CurFalLot.LOT_PLAN_END_DTE
                  , aCSchedulePlanning              => CurFalLot.C_SCHEDULE_PLANNING
                  , aLotTolerance                   => aLotTolerance
                  , UpdateBatchFields               => nvl(UpdateBatchFields, 0)
                  , aDatePlanification              => DatePlanification
                  , PlanificationType               => SelonDateDebut
                  , aQty                            => CurFalLot.LOT_TOTAL_QTY
                  , aAllInInfiniteCap               => 1   -- Planification en capacité infinie
                  , FLotBeginDate                   => FLotBeginDate
                  , FLotEndDate                     => FLotEndDate
                  , FLotDuration                    => FLotDuration
                  , aSearchFromEndOfDay             => aSearchFromEndOfDay
                  , aUpdateCSTDelay                 => aUpdateCSTDelay
                  , aSearchBackwardFromTaskLinkId   => aSearchBackwardFromTaskLinkId
                   );

    -- Si la MAJ_LiensComposantsLot est requise alors
    if MAJReqLiensComposantsLot = 1 then
      MAJ_LiensComposantsLot(PrmFAL_LOT_ID, FLotEndDate);
    end if;

    -- Mise à jour Histo lot si necessaire
    if aDoHistorisationPlanif = 1 then
      FAL_PLANIF.StorePlanifOrigin(PrmFAL_LOT_ID, aC_EVEN_TYPE, FLotBeginDate, FLotEndDate);
    end if;

    -- Mise à jour des réseaux si nécéssaire
    if MAJ_Reseaux_Requise = 1 then
      FAL_NETWORK.MiseAJourReseaux(PrmFAL_LOT_ID, FAL_NETWORK.ncPlannificationLot, '');
    end if;
  end BatchPlanning;

  /**
  * procédure Planification_Lot
  * Description : Planification d'un lot de fabrication avec MAJ des champs
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_LOT_ID : Lot de fabrication
  * @param   DatePlanification : Date de départ de la planification
  * @param   SelonDateDebut : Planif date début ou date fin
  * @param   MAJReqLiensComposantsLot : MAJ des composants.
  * @param   MAJ_Reseaux_Requise : MAJ des réseaux
  * @param   aC_EVEN_TYPE : Type d'évenement qui exécute la procédure
  * @param   aDoHistorisationPlanif : Historisation de la planif.
  * @param   aSearchFromEndOfDay : En planification arrière, on part de la date, hh, mi
  *            exacte de la dernière op ou de la fin de la journée.
  * @param aUpdateCSTDelay : code de mise à jour du délai des commandes de sous traitance lors de la planification
  * @param   aSearchBackwardFromTaskLinkId : utilisé uniquement si  PlanificationType = ctDateFin
  *          Défini l'opération à partir de laquelle se fait la recalculation arriere
  */
  procedure Planification_Lot(
    PrmFAL_LOT_ID                 number
  , DatePlanification             date
  , SelonDateDebut                integer
  , MAJReqLiensComposantsLot      integer
  , MAJ_Reseaux_Requise           integer
  , aC_EVEN_TYPE                  FAL_HISTO_LOT.C_EVEN_TYPE%type default '21'
  , aDoHistorisationPlanif        integer default 1
  , aSearchFromEndOfDay           integer default 1
  , aUpdateCSTDelay               integer default 0
  , aSearchBackwardFromTaskLinkId number default null
  )
  is
    FLotBeginDate date   := null;
    FLotEndDate   date   := null;
    FLotDuration  number := null;
  begin
    -- Appel de la planification standard
    BatchPlanning(PrmFAL_LOT_ID                   => PrmFAL_LOT_ID
                , DatePlanification               => DatePlanification
                , SelonDateDebut                  => SelonDateDebut
                , MAJReqLiensComposantsLot        => MAJReqLiensComposantsLot
                , MAJ_Reseaux_Requise             => MAJ_Reseaux_Requise
                , UpdateBatchFields               => 1   -- UpdateBatchFields
                , aLotTolerance                   => null   -- aLotTolerance
                , FLotBeginDate                   => FLotBeginDate
                , FLotEndDate                     => FLotEndDate
                , FLotDuration                    => FLotDuration
                , aC_EVEN_TYPE                    => aC_EVEN_TYPE
                , aDoHistorisationPlanif          => aDoHistorisationPlanif
                , aSearchFromEndOfDay             => aSearchFromEndOfDay
                , aUpdateCSTDelay                 => aUpdateCSTDelay
                , aSearchBackwardFromTaskLinkId   => aSearchBackwardFromTaskLinkId
                 );
  end Planification_Lot;

  /**
  * procédure Planification_Lot_Prop
  * Description : Planification d'une proposition de fabrication ou de sous-traitance avec MAJ des champs
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_LOT_PROP_ID : Proposition de fabrication
  * @param   DatePlanification : Date de départ de la planification
  * @param   SelonDateDebut : Planif date début ou date fin
  * @param   MAJReqLiensComposantsLot : MAJ des composants.
  * @param   MAJ_Reseaux_Requise : MAJ des réseaux
  */
  procedure Planification_Lot_Prop(
    PrmFAL_LOT_PROP_ID        number
  , DatePlanification         date
  , SelonDateDebut            integer
  , MAJReqLiensComposantsProp integer
  , MAJ_Reseaux_Requise       integer
  , aUpdateCSTDelay           integer default 0
  )
  is
    cursor Cur_Fal_Lot_Prop
    is
      select C_SCHEDULE_PLANNING
           , GCO_GOOD_ID
           , LOT_PLAN_BEGIN_DTE
           , LOT_PLAN_END_DTE
           , DIC_FAB_CONDITION_ID
           , LOT_TOTAL_QTY
           , C_FAB_TYPE
        from FAL_LOT_PROP
       where FAL_LOT_PROP_ID = PrmFAL_LOT_PROP_ID;

    CurFalLotProp Cur_Fal_Lot_Prop%rowtype;
    FLotBeginDate date                       := null;
    FLotEndDate   date                       := null;
    FLotDuration  number                     := null;
  begin
    open Cur_Fal_Lot_Prop;

    fetch Cur_Fal_Lot_Prop
     into CurFalLotProp;

    close Cur_Fal_Lot_Prop;

    if (CurFalLotProp.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract) then
      -- Update subcontracting batch proposition (POAST) according to subcontracting delay
      if SelonDateDebut = 1 then
        FAL_PRC_SUBCONTRACTP.UpdateBatchPropDelay(iFalLotPropId   => PrmFAL_LOT_PROP_ID
                                                , iStartDate      => DatePlanification
                                                , iGcoGoodId      => CurFalLotProp.GCO_GOOD_ID
                                                , iQuantity       => CurFalLotProp.LOT_TOTAL_QTY
                                                 );
      else
        FAL_PRC_SUBCONTRACTP.UpdateBatchPropDelay(iFalLotPropId   => PrmFAL_LOT_PROP_ID
                                                , iEndDate        => DatePlanification
                                                , iGcoGoodId      => CurFalLotProp.GCO_GOOD_ID
                                                , iQuantity       => CurFalLotProp.LOT_TOTAL_QTY
                                                 );
      end if;
    else
      -- Contrôle de validité sur les informations en entrées avant le lancement des processus
      ControleValiditeInfos(CurFalLotProp.C_SCHEDULE_PLANNING
                          , CurFalLotProp.GCO_GOOD_ID
                          , CurFalLotProp.LOT_PLAN_BEGIN_DTE
                          , CurFalLotProp.LOT_PLAN_END_DTE
                          , DatePlanification
                          , SelonDateDebut
                           );
      GeneralPlanning(aLotPropOrGammeId     => PrmFAL_LOT_PROP_ID
                    , aGcoGoodId            => CurFalLotProp.GCO_GOOD_ID
                    , aDicFabConditionId    => CurFalLotProp.DIC_FAB_CONDITION_ID
                    , aBeginDate            => CurFalLotProp.LOT_PLAN_BEGIN_DTE
                    , aEndDate              => CurFalLotProp.LOT_PLAN_END_DTE
                    , aCSchedulePlanning    => CurFalLotProp.C_SCHEDULE_PLANNING
                    , aLotTolerance         => null   -- aLotTolerance
                    , UpdateBatchFields     => 1   -- UpdateBatchFields
                    , aDatePlanification    => DatePlanification
                    , PlanificationType     => SelonDateDebut
                    , aQty                  => CurFalLotProp.LOT_TOTAL_QTY
                    , aAllInInfiniteCap     => 1   -- Planification en capacité infinie
                    , FLotBeginDate         => FLotBeginDate
                    , FLotEndDate           => FLotEndDate
                    , FLotDuration          => FLotDuration
                    , aSearchFromEndOfDay   => 1
                    , aUpdateCSTDelay       => aUpdateCSTDelay
                     );
    end if;

    -- Si la MAJ_LiensComposantsLot est requise alors
    if MAJReqLiensComposantsProp = 1 then
      MAJ_LiensComposantsProp(PrmFAL_LOT_PROP_ID, FLotEndDate);
    end if;

    -- Si La mise à jour des réseaux est requise
    if MAJ_Reseaux_Requise = 1 then
      FAL_NETWORK.MiseAJourReseaux(PrmFAL_LOT_PROP_ID, FAL_NETWORK.ncPlanificationLotProp, '');
    end if;
  end Planification_Lot_Prop;

  procedure PlanningProposition(
    aFalLotPropId          FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  , aPlanningDate          FAL_LOT_PROP.LOT_PLAN_BEGIN_DTE%type default null
  , aPlanningType          integer default ctDateDebut
  , aUpdateProp            integer default 1
  , aBeginDate      in out FAL_LOT_PROP.LOT_PLAN_BEGIN_DTE%type
  , aEndDate        in out FAL_LOT_PROP.LOT_PLAN_BEGIN_DTE%type
  , aDuration       in out FAL_LOT_PROP.LOT_PLAN_LEAD_TIME%type
  , aUpdateCSTDelay        integer default 0
  )
  is
    cursor crFalLotProp
    is
      select C_SCHEDULE_PLANNING
           , GCO_GOOD_ID
           , LOT_PLAN_BEGIN_DTE
           , LOT_PLAN_END_DTE
           , DIC_FAB_CONDITION_ID
           , LOT_TOTAL_QTY
        from FAL_LOT_PROP
       where FAL_LOT_PROP_ID = aFalLotPropId;

    PlanningDate FAL_LOT_PROP.LOT_PLAN_BEGIN_DTE%type;
  begin
    for tplFalLotProp in crFalLotProp loop
      if aPlanningType = ctDateDebut then
        PlanningDate  := nvl(aPlanningDate, tplFalLotProp.LOT_PLAN_BEGIN_DTE);
      else
        PlanningDate  := nvl(aPlanningDate, tplFalLotProp.LOT_PLAN_END_DTE);
      end if;

      -- Contrôle de validité sur les informations en entrées avant le lancement des processus
      ControleValiditeInfos(tplFalLotProp.C_SCHEDULE_PLANNING
                          , tplFalLotProp.GCO_GOOD_ID
                          , tplFalLotProp.LOT_PLAN_BEGIN_DTE
                          , tplFalLotProp.LOT_PLAN_END_DTE
                          , PlanningDate
                          , aPlanningType
                           );
      GeneralPlanning(aLotPropOrGammeId    => aFalLotPropId
                    , aGcoGoodId           => tplFalLotProp.GCO_GOOD_ID
                    , aDicFabConditionId   => tplFalLotProp.DIC_FAB_CONDITION_ID
                    , aBeginDate           => tplFalLotProp.LOT_PLAN_BEGIN_DTE
                    , aEndDate             => tplFalLotProp.LOT_PLAN_END_DTE
                    , aCSchedulePlanning   => tplFalLotProp.C_SCHEDULE_PLANNING
                    , aLotTolerance        => null
                    , UpdateBatchFields    => aUpdateProp
                    , aDatePlanification   => PlanningDate
                    , PlanificationType    => aPlanningType
                    , aQty                 => tplFalLotProp.LOT_TOTAL_QTY
                    , aAllInInfiniteCap    => 1
                    , FLotBeginDate        => aBeginDate
                    , FLotEndDate          => aEndDate
                    , FLotDuration         => aDuration
                    , aUpdateCSTDelay      => aUpdateCSTDelay
                     );

      -- Mise à jour des liens composants
      if aUpdateProp = 1 then
        MAJ_LiensComposantsProp(aFalLotPropId, aEndDate);
      end if;
    end loop;
  end PlanningProposition;

  /**
  * procédure Planif_Lot_Create
  * Description : Planification d'un lot de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_LOT_ID : Lot de fabrication
  * @param   PrmLOT_TOLERANCE : Marge
  * @param   DatePlanification : Date de départ de la planification
  * @param   SelonDateDebut : Planif date début ou date fin
  * @param   MAJReqLiensComposantsLot : MAJ des composants.
  * @param   MAJ_Reseaux_Requise : MAJ des réseaux
  * @return  LotbeginDate : Date début lot
  * @return  LotEndDate : date fin lot
  * @return  LotDuration : Durée (en Jours)
  * @param   aDoHistorisationPlanif : Doit-on historiser la planif.
  * @param   UpdateFields : Indique si on fait ou non la mise à jour des champs (dates sur lot et opération)
   * @param aUpdateCSTDelay : code de mise à jour du délai des commandes de sous traitance lors de la planification
  */
  procedure Planif_Lot_Create(
    PrmFAL_LOT_ID                number
  , PrmLOT_TOLERANCE             number
  , DatePlanification            date
  , SelonDateDebut               integer
  , MAJReqLiensComposantsLot     integer
  , MAJ_Reseaux_Requise          integer
  , LotBeginDate             out date
  , LotEndDate               out date
  , LotDuration              out number
  , aDoHistorisationPlanif       integer default 1
  , UpdateFields                 integer default 1
  , aUpdateCSTDelay              integer default 0
  )
  is
    FLotBeginDate date   := null;
    FLotEndDate   date   := null;
    FLotDuration  number := null;
  begin
    -- Appel de la planification standard mais la MAJ du lot est désactivée
    BatchPlanning(PrmFAL_LOT_ID              => PrmFAL_LOT_ID
                , DatePlanification          => DatePlanification
                , SelonDateDebut             => SelonDateDebut
                , MAJReqLiensComposantsLot   => MAJReqLiensComposantsLot
                , MAJ_Reseaux_Requise        => MAJ_Reseaux_Requise
                , UpdateBatchFields          => UpdateFields
                , aLotTolerance              => PrmLOT_TOLERANCE
                , FLotBeginDate              => FLotBeginDate
                , FLotEndDate                => FLotEndDate
                , FLotDuration               => FLotDuration
                , aC_EVEN_TYPE               => '21'
                , aDoHistorisationPlanif     => aDoHistorisationPlanif   -- Planification de type PCS
                , aSearchFromEndOfDay        => 1
                , aUpdateCSTDelay            => aUpdateCSTDelay
                 );
    -- Retourne les valeurs
    LotBeginDate  := FLotBeginDate;
    LotEndDate    := FLotEndDate;
    LotDuration   := FLotDuration;
  end Planif_Lot_Create;

  /**
  * procédure PlanGalTask
  * Description : Planification d'une tâche affaire.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGalTaskId : Tache affaire
  * @param   aBeginDate : Date début
  * @param   aEndDate : Date fin
  * @param   UpdateBatchFields : MAJ des champs?
  * @param   aDatePlanification : Date d'origine de la planification
  * @param   PlanificationType : Avant ou arrière
  * @return  FLotBeginDate : date début calculée
  * @return  FLotEndDate : date fin calculée
  * @return  FLotDuration : durée calculée
  */
  procedure PlanGalTask(
    aGalTaskId                number
  , aBeginDate                FAL_LOT.LOT_PLAN_BEGIN_DTE%type
  , aEndDate                  FAL_LOT.LOT_PLAN_END_DTE%type
  , UpdateBatchFields         integer
  , aDatePlanification        date
  , PlanificationType         integer
  , FLotBeginDate      in out date
  , FLotEndDate        in out date
  , FLotDuration       in out number
  , aUpdateCSTDelay           integer default 0
  )
  is
  begin
    GeneralPlanning(aLotPropOrGammeId    => aGalTaskId
                  , aGcoGoodId           => null
                  , aDicFabConditionId   => null
                  , aBeginDate           => aBeginDate
                  , aEndDate             => aEndDate
                  , aCSchedulePlanning   => 2
                  , aLotTolerance        => null
                  , UpdateBatchFields    => nvl(UpdateBatchFields, 0)
                  , aDatePlanification   => aDatePlanification
                  , PlanificationType    => PlanificationType
                  , aQty                 => 1
                  , aAllInInfiniteCap    => 1
                  , FLotBeginDate        => FLotBeginDate
                  , FLotEndDate          => FLotEndDate
                  , FLotDuration         => FLotDuration
                  , aUpdateCSTDelay      => aUpdateCSTDelay
                   );
  end PlanGalTask;

  /**
  * procédure GetCalendarDateFromInterval
  * Description : Retour d'une date décallée, avec date fin maximum admissible
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   Decalage : Décalage
  * @param   PrmStartDate : Date début calcul
  * @param   EndDate : Date fin maximum
  * @return  ResultDate : Date calculée
  */
  procedure GetCalendarDateFromInterval(Decalage GCO_COMPL_DATA_MANUFACTURE.CMA_LOT_QUANTITY%type, PrmStartDate date, EndDate date, ResultDate in out date)
  is
    StartDate date;
  begin
    StartDate   := AffectDayHourMinut(PrmStartDate, 0, 0);
    ResultDate  := StartDate;
    ResultDate  := FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(null, null, null, null, null, FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar, StartDate, Decalage);

    if ResultDate > EndDate then
      ResultDate  := EndDate;
    end if;
  end GetCalendarDateFromInterval;

  /**
  * procédure MAJ_LiensComposantsLot
  * Description : Mise à jour des dates besoins des composants de lot
  *   de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iFalLotId : Lot de fabrication
  * @param   iEndDate  : Date fin
  */
  procedure MAJ_LiensComposantsLot(iFalLotId in number, iEndDate in date)
  is
    cursor crComponents
    is
      select LOT.FAL_SCHEDULE_PLAN_ID
           , LOT.C_SCHEDULE_PLANNING
           , LOT.LOT_PLAN_BEGIN_DTE
           , COMP.FAL_LOT_MATERIAL_LINK_ID
           , COMP.LOM_INTERVAL
           , COMP.LOM_TASK_SEQ
           , (select TAL_BEGIN_PLAN_DATE
                from FAL_TASK_LINK
               where FAL_LOT_ID = COMP.FAL_LOT_ID
                 and SCS_STEP_NUMBER = COMP.LOM_TASK_SEQ) TAL_BEGIN_PLAN_DATE
        from FAL_LOT_MATERIAL_LINK COMP
           , FAL_LOT LOT
       where COMP.FAL_LOT_ID = LOT.FAL_LOT_ID
         and COMP.FAL_LOT_ID = iFalLotId;

    DateBesoin date;
  begin
    for tplComponents in crComponents loop
      -- Planification selon Produit ou gamme absente
      if    (tplComponents.C_SCHEDULE_PLANNING = '1')
         or tplComponents.FAL_SCHEDULE_PLAN_ID is null then
        if tplComponents.LOM_INTERVAL is null then
          DateBesoin  := tplComponents.LOT_PLAN_BEGIN_DTE;
        else
          GetCalendarDateFromInterval(tplComponents.LOM_INTERVAL, tplComponents.LOT_PLAN_BEGIN_DTE, iEndDate, DateBesoin);
        end if;
      -- Planification selon Opérations et gamme présente
      else
        if tplComponents.LOM_TASK_SEQ is null then
          DateBesoin  := tplComponents.LOT_PLAN_BEGIN_DTE;
        else
          -- La SequenceOperation est bien renseignée
          -- Récupérer la date de début de planification de la tâche associée
          DateBesoin  := tplComponents.TAL_BEGIN_PLAN_DATE;

          if DateBesoin is null then
            DateBesoin  := tplComponents.LOT_PLAN_BEGIN_DTE;
          end if;
        end if;
      end if;

      update FAL_LOT_MATERIAL_LINK
         set LOM_NEED_DATE = DateBesoin
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_MATERIAL_LINK_ID = tplComponents.FAL_LOT_MATERIAL_LINK_ID;
    end loop;
  end MAJ_LiensComposantsLot;

  /**
  * procédure MAJ_LiensComposantsProp
  * Description : Mise à jour des dates besoins des composants de propositions
  *   de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iFalLotPropId : Id de la proposition
  * @param   iEndDate      : Date fin
  */
  procedure MAJ_LiensComposantsProp(iFalLotPropId in number, iEndDate in date)
  is
    cursor crProp
    is
      select PROP.FAL_SCHEDULE_PLAN_ID
           , PROP.C_SCHEDULE_PLANNING
           , PROP.LOT_PLAN_BEGIN_DTE
           , COMP.FAL_LOT_MAT_LINK_PROP_ID
           , COMP.LOM_INTERVAL
           , COMP.LOM_TASK_SEQ
           , (select TAL_BEGIN_PLAN_DATE
                from FAL_TASK_LINK_PROP
               where FAL_LOT_PROP_ID = COMP.FAL_LOT_PROP_ID
                 and SCS_STEP_NUMBER = COMP.LOM_TASK_SEQ) TAL_BEGIN_PLAN_DATE
        from FAL_LOT_PROP PROP
           , FAL_LOT_MAT_LINK_PROP COMP
       where PROP.FAL_LOT_PROP_ID = COMP.FAL_LOT_PROP_ID
         and COMP.FAL_LOT_PROP_ID = iFalLotPropId;

    DateBesoin date;
  begin
    -- Parcours selon la durée
    for tplProp in crProp loop
      -- Plannification selon Produit ou gamme absente
      if    (tplProp.C_SCHEDULE_PLANNING = '1')
         or (tplProp.FAL_SCHEDULE_PLAN_ID is null) then
        if tplProp.LOM_INTERVAL is null then
          DateBesoin  := tplProp.LOT_PLAN_BEGIN_DTE;
        else
          GetCalendarDateFromInterval(tplProp.LOM_INTERVAL, tplProp.LOT_PLAN_BEGIN_DTE, iEndDate, DateBesoin);
        end if;
      -- Plannification selon Opérations et gamme présente
      else
        if tplProp.LOM_TASK_SEQ is null then
          DateBesoin  := tplProp.LOT_PLAN_BEGIN_DTE;
        else
          -- La SequenceOperation est bien renseignée ...
          -- Récupérer la date de début de plannification de la tâche associée ...
          DateBesoin  := tplProp.TAL_BEGIN_PLAN_DATE;

          if DateBesoin is null then
            DateBesoin  := tplProp.LOT_PLAN_BEGIN_DTE;
          end if;
        end if;
      end if;

      update FAL_LOT_MAT_LINK_PROP
         set LOM_NEED_DATE = DateBesoin
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_MAT_LINK_PROP_ID = tplProp.FAL_LOT_MAT_LINK_PROP_ID;
    end loop;
  end MAJ_LiensComposantsProp;

  /**
  * Procedure PlanOneOperation
  * Description : procédure de planification d'une opération via les nouveaux calendriers
  *               sans mise à jour des champs
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLotPropOrGammeId : ID Lot, proposition ou gamme
  * @param   aTaskId : ID Tâche à planifier
  * @param   aSupplierPartnerID : ID fournisseur
  * @param   aAllInInfiniteCap
  * @param   aDatePlanification : Date de début du calcul
  * @param   aForward : Sens de la planif
  * @param   aQty : Qté à planifier
  * @param   aTalBeginPlanDate
  * @param   aTalBeginEndDate
  * @param   aTalDuration
  * @param aUpdateCSTDelay : code de mise à jour du délai des commandes de sous traitance lors de la planification
  */
  procedure PlanOneOperation(
    aLotPropOrGammeId  in     number
  , aTaskId            in     number
  , aSupplierPartnerID in     number
  , aAllInInfiniteCap  in     integer
  , aDatePlanification in     date
  , aForward           in     integer
  , aQty               in     number
  , aTalBeginPlanDate  in out date
  , aTalEndPlanDate    in out date
  , aTalDuration       in out number
  , aUpdateCSTDelay    in     integer default 0
  )
  is
  begin
    PlanningByOperation(aLotPropOrGammeId               => aLotPropOrGammeId
                      , UpdateBatchFields               => 0   -- UpdateBatchFields
                      , aDatePlanification              => aDatePlanification
                      , PlanificationType               => aForward
                      , aQty                            => aQty
                      , aAllInInfiniteCap               => aAllInInfiniteCap
                      , FLotBeginDate                   => aTalBeginPlanDate
                      , FLotEndDate                     => aTalEndPlanDate
                      , FLotDuration                    => aTalDuration
                      , aFAL_TASK_LINK_ID               => aTaskID
                      , aSearchFromEndOfDay             => 1
                      , aUpdateCSTDelay                 => aUpdateCSTDelay
                      , aSearchBackwardFromTaskLinkId   => null
                       );
  end PlanOneOperation;

  /**
  * Fonction GetPrevManufacturingDuration
  * Description : Calcul de la Durée prévisionnelle de fabrication pour un produit
  *               et une quantité donnée.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGCO_GOOD_ID : Produit
  * @param   aTotalQty : Qté totale à fabriquer (incluant les éventuels rebuts de fabrication)
  * @param   aStartDate : Date début analyse (Si nulle, Date du jour - 15 jours)
  * @param   aEndDate : Date fin analyse (Si nulle, Date du jour + 15 jours)
  * @Return  Durée de fabrication prévisionnelle en jours, fraction de jours ouvrés, retards sur op parallèles inclus.
  */
  function GetPrevManufacturingDuration(aGCO_GOOD_ID in number, aTotalQty in number, aStartDate in date default null, aEndDate in date default null)
    return number
  is
    nFAL_SCHEDULE_PLAN_ID    number;
    vDIC_FAB_CONDITION_ID    varchar2(10);
    vC_SCHEDULE_PLANNING     varchar2(10);
    nCMA_FIX_DELAY           number;
    nCMA_MANUFACTURING_DELAY number;
    nCMA_LOT_QUANTITY        number;
    dLotBeginDate            date;
    dLotEndDate              date;
    nLotDuration             number;
  begin
    nLotDuration              := 0;
    nFAL_SCHEDULE_PLAN_ID     := null;
    vDIC_FAB_CONDITION_ID     := '';
    vC_SCHEDULE_PLANNING      := '';
    nCMA_FIX_DELAY            := 0;
    nCMA_MANUFACTURING_DELAY  := 0;
    nCMA_LOT_QUANTITY         := 0;

    if nvl(aTotalQty, 0) <> 0 then
      -- Recherche des données du calcul
      begin
        select CMA.FAL_SCHEDULE_PLAN_ID
             , CMA.DIC_FAB_CONDITION_ID
             , CMA.CMA_FIX_DELAY
             , nvl(CMA.CMA_MANUFACTURING_DELAY, 0) CMA_MANUFACTURING_DELAY
             , nvl(CMA.CMA_LOT_QUANTITY, 1)
             , nvl(SPL.C_SCHEDULE_PLANNING, '1')
          into nFAL_SCHEDULE_PLAN_ID
             , vDIC_FAB_CONDITION_ID
             , nCMA_FIX_DELAY
             , nCMA_MANUFACTURING_DELAY
             , nCMA_LOT_QUANTITY
             , vC_SCHEDULE_PLANNING
          from GCO_COMPL_DATA_MANUFACTURE CMA
             , FAL_SCHEDULE_PLAN SPL
         where CMA.GCO_GOOD_ID = aGCO_GOOD_ID
           and CMA.CMA_DEFAULT = 1
           and CMA.FAL_SCHEDULE_PLAN_ID = SPL.FAL_SCHEDULE_PLAN_ID(+);
      exception
        when no_data_found then
          return 0;
      end;

      -- Calcul de durée si mode de planification selon produit
      if vC_SCHEDULE_PLANNING = '1' then
        if nCMA_FIX_DELAY = 1 then
          nLotDuration  := nCMA_MANUFACTURING_DELAY;
        else
          nLotDuration  := (aTotalQty / nCMA_LOT_QUANTITY) * nCMA_MANUFACTURING_DELAY;
        end if;
      -- Calcul de durée si mode de planification selon Liste de tâche, détaillées ou non
      else
        PlanningOpWithAvgCapacity(aLotPropOrGammeId   => nFAL_SCHEDULE_PLAN_ID
                                , aQty                => aTotalQty
                                , FLotDuration        => nLotDuration
                                , aStartDate          => nvl(aStartDate, sysdate - 15)
                                , aEndDate            => nvl(aEndDate, sysdate + 15)
                                 );
      end if;
    end if;

    return nLotDuration;
  end GetPrevManufacturingDuration;

  /**
  * Procedure GetRealManufacturingDuration
  * Description : Calcul de la Quantité Moyenne réelle approvisionnée, et de la
  *               durée moyenne d'approvisionnement.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aGCO_GOOD_ID : Produit
  * @param   aStartDate : Date début calcul
  * @Param   aEndDate : Date fin calcul
  * @Return  aAvgSupplyQty : Qté moyenne d'appro
  * @Return  aAvgSupplyDuration : Qté moyenne d'appro
  */
  procedure GetRealManufacturingDuration(
    aGCO_GOOD_ID       in     number
  , aStartDate         in     date
  , aEndDate           in     date
  , aAvgSupplyQty      in out number
  , aAvgSupplyDuration in out number
  )
  is
  begin
    select (Batches_qty.lot_released_qty + Batches_hist_qty.lot_released_qty) /(Batch_Number.NumberOfBatch + Batchhist_Number.NumberOfBatch) Avg_Real_Qty
         , (Batches_qty.lot_real_lead_time + Batches_hist_qty.lot_real_lead_time) /(Batch_Number.NumberOfBatch + Batchhist_Number.NumberOfBatch)
                                                                                                                                              Avg_Real_Duration
      into aAvgSupplyQty
         , aAvgSupplyDuration
      from (select sum(lot.lot_released_qty) lot_released_qty
                 , sum(lot.lot_real_lead_time) lot_real_lead_time
              from fal_lot lot
             where lot.c_lot_status in('3', '5', '6')
               and lot.lot_full_rel_dte between aStartDate and aEndDate
               and lot.gco_good_id = agco_good_id) Batches_qty
         , (select sum(loth.lot_released_qty) lot_released_qty
                 , sum(loth.lot_real_lead_time) lot_real_lead_time
              from fal_lot_hist loth
             where loth.c_lot_status in('3', '5', '6')
               and loth.lot_full_rel_dte between aStartDate and aEndDate
               and loth.gco_good_id = agco_good_id) Batches_Hist_qty
         , (select count(*) NumberOfBatch
              from fal_lot lot
             where lot.c_lot_status in('3', '5', '6')
               and lot.lot_full_rel_dte between aStartDate and aEndDate
               and lot.gco_good_id = agco_good_id) batch_Number
         , (select count(*) NumberOfBatch
              from fal_lot_hist loth
             where loth.c_lot_status in('3', '5', '6')
               and loth.lot_full_rel_dte between aStartDate and aEndDate
               and loth.gco_good_id = agco_good_id) BatchHist_Number;
  exception
    when others then
      begin
        aAvgSupplyQty       := 0;
        aAvgSupplyDuration  := 0;
      end;
  end GetRealManufacturingDuration;

  /**
  * procédure PlanificationLotSubcontractP
  * Description : Planification d'un lot de sous traitance d'achat avec MAJ des champs
  */
  procedure PlanificationLotSubcontractP(
    iLotID        in FAL_LOT.FAL_LOT_ID%type
  , iLotBeginDate in date
  , iLotEndDate   in date
  , iSupplierId   in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  )
  is
    lnLOT_PLAN_LEAD_TIME FAL_LOT.LOT_PLAN_LEAD_TIME%type;
    lnFAL_TASK_LINK_ID   FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    -- Change la date planifiée début du lot
    MAJ_DateDebutPlanifLot(aLotId => iLotID, aTypeEntryToPlan => FAL_PLANIF.ctIdLot, aNewBeginDate => iLotBeginDate);
    -- Change la date planifiée fin du lot
    MAJ_DateFinPlanifLot(aLotId => iLotID, aTypeEntryToPlan => FAL_PLANIF.ctIdLot, aNewEndDate => iLotEndDate);
    -- Change la durée planifiée fin du lot
    lnLOT_PLAN_LEAD_TIME  :=
      DOC_DELAY_FUNCTIONS.OpenDaysBetween(aFromDate      => iLotBeginDate
                                        , aToDate        => iLotEndDate
                                        , aAdminDomain   => DOC_LIB_SUBCONTRACTP.cAdminDomainSubContract
                                        , aThirdID       => iSupplierId
                                         );
    MAJ_TempsTravailLot(aLotId => iLotID, aTypeEntryToPlan => FAL_PLANIF.ctIdLot, PrmTIME => lnLOT_PLAN_LEAD_TIME);

    -- Recherche l'unique opération d'une lot de sous-traitance d'achat
    select max(TAS.FAL_SCHEDULE_STEP_ID)
      into lnFAL_TASK_LINK_ID
      from FAL_TASK_LINK TAS
     where TAS.FAL_LOT_ID = iLotID;

    -- Change la date planifiée début de l'opération
    MAJ_DateDebutPlanifTache(aTaskId => lnFAL_TASK_LINK_ID, aTypeEntryToPlan => FAL_PLANIF.ctIdLot, aDate => iLotBeginDate);
    -- Change la date planifiée fin de l'opération
    MAJ_DateFinPlanifTache(aTaskId => lnFAL_TASK_LINK_ID, aTypeEntryToPlan => FAL_PLANIF.ctIdLot, aDate => iLotEndDate, aUpdateCSTDelay => 0);
    -- Change la durée planifiée fin de l'opération
    MAJ_TempsTravailTache(aTaskId => lnFAL_TASK_LINK_ID, aTypeEntryToPlan => FAL_PLANIF.ctIdLot, PrmTIME => lnLOT_PLAN_LEAD_TIME);
    -- Mise à jour de la date besoin des composants
    MAJ_LiensComposantsLot(iLotID, iLotBeginDate);
  end PlanificationLotSubcontractP;

  /**
  * procédure PlanBatches
  * Description : Planification en série de lots de fabrication
  */
  procedure PlanBatches(iPlanDateRef in date, iPlanType in integer, iUpdateCstDelay in integer default 0)
  is
    ldPlanDate date;
    liPlanType integer;
  begin
    for tplBatch in (select FAL_LOT_ID
                          , LT1_PREFERED_DATE
                          , LT1_PREFERED_END_DATE
                          , LT1_LOT_PLAN_BEGIN_DTE
                          , LT1_LOT_PLAN_END_DTE
                       from FAL_LOT1
                      where LT1_ORACLE_SESSION = DBMS_SESSION.unique_session_id
                        and LT1_SELECT = 1) loop
      /* Initialisation de la date et du type de planification */
      if tplBatch.LT1_PREFERED_DATE is not null then
        ldPlanDate  := tplBatch.LT1_PREFERED_DATE;
        liPlanType  := ctDateDebut;
      elsif tplBatch.LT1_PREFERED_END_DATE is not null then
        ldPlanDate  := tplBatch.LT1_PREFERED_END_DATE;
        liPlanType  := ctDateFin;
      else
        ldPlanDate  := iPlanDateRef;
        liPlanType  := iPlanType;

        if ldPlanDate is null then
          if liPlanType = ctDateDebut then
            ldPlanDate  := tplBatch.LT1_LOT_PLAN_BEGIN_DTE;
          else
            ldPlanDate  := tplBatch.LT1_LOT_PLAN_END_DTE;
          end if;
        end if;
      end if;

      Planification_Lot(PrmFAL_LOT_ID              => tplBatch.FAL_LOT_ID
                      , DatePlanification          => ldPlanDate
                      , SelonDateDebut             => liPlanType
                      , MAJReqLiensComposantsLot   => 1
                      , MAJ_Reseaux_Requise        => 1
                      , aUpdateCSTDelay            => iUpdateCstDelay
                       );
    end loop;
  end;

  /**
  * Description
  *    Recherche la date de fin d'un OF (d'une proposition d'OF) en fonction d'une date
  *    de fin (modifiée) d'un opération.
  */
  function searchBatchEndDate(
    iNewTaskEndDate in FAL_TASK_LINK.TAL_END_PLAN_DATE%type
  , iTaskSeq        in FAL_TASK_LINK.SCS_STEP_NUMBER%type
  , iBatchOrPropId  in FAL_LOT.FAL_LOT_ID%type
  )
    return date
  as
    lbPreviousOpIsParallel boolean := false;
    lnTalDuration          number  := 0;
    ldMaxEndDate           date    := iNewTaskEndDate;
    ldWorkDate             date    := iNewTaskEndDate;
    ldTalBeginPlanDate     date;
    ldTalEndPlanDate       date;
    ldLastOpStartDate      date;
  begin
    -- Parcours des OP dans l'ordre ascendant (on recherche la date fin du lot, pour replanifier ensuite arrière)
    for ltplTasks in (select   TAL_BEGIN_PLAN_DATE
                             , FAL_SCHEDULE_STEP_ID
                             , TAL_DUE_QTY
                             , C_RELATION_TYPE
                             , SCS_STEP_NUMBER
                             , PAC_SUPPLIER_PARTNER_ID
                          from FAL_TASK_LINK
                         where FAL_LOT_ID = iBatchOrPropId
                           and SCS_STEP_NUMBER > iTaskSeq
                      union
                      select   TAL_BEGIN_PLAN_DATE
                             , FAL_TASK_LINK_PROP_ID FAL_SCHEDULE_STEP_ID
                             , TAL_DUE_QTY
                             , C_RELATION_TYPE
                             , SCS_STEP_NUMBER
                             , PAC_SUPPLIER_PARTNER_ID
                          from FAL_TASK_LINK_PROP
                         where FAL_LOT_PROP_ID = iBatchOrPropId
                           and SCS_STEP_NUMBER > iTaskSeq
                      order by SCS_STEP_NUMBER asc) loop
      ldTalBeginPlanDate      := ltplTasks.TAL_BEGIN_PLAN_DATE;
      ldTalEndPlanDate        := ltplTasks.TAL_BEGIN_PLAN_DATE;

      -- Si opération parallèle
      if ltplTasks.C_RELATION_TYPE in('2', '4') then
        ldWorkDate  := nvl(ldLastOpStartDate, ldWorkDate);
      -- Si Op Successeur et op précédente parallèle
      elsif lbPreviousOpIsParallel then
        ldWorkDate  := ldMaxEndDate;
      end if;

      ldLastOPStartDate       := ldWorkDate;
      FAL_PLANIF.planOneOperation(iBatchOrPropId
                                , ltplTasks.FAL_SCHEDULE_STEP_ID
                                , ltplTasks.PAC_SUPPLIER_PARTNER_ID
                                , 1
                                , ldWorkDate
                                , 1
                                , ltplTasks.TAL_DUE_QTY
                                , ldTalBeginPlanDate
                                , ldTalEndPlanDate
                                , lnTalDuration
                                 );
      ldWorkDate              := ldTalEndPlanDate;
      ldMaxEndDate            := greatest(ldMaxEndDate, ldTalEndPlanDate);
      lbPreviousOpIsParallel  := ltplTasks.C_RELATION_TYPE in('2', '4', '5');
    end loop;

    return ldWorkDate;
  end searchBatchEndDate;
end FAL_PLANIF;
