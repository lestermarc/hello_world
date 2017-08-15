--------------------------------------------------------
--  DDL for Package Body PAC_LIB_SCHEDULE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_LIB_SCHEDULE" 
is
  /**
  * procedure InitScheduleFilter
  * Description
  *    Initialise la variable de retour avec l'id du filtre passé en param
  */
  procedure InitScheduleFilter(iFilter in varchar2, iFilterID in number, oScheduleFilter out TScheduleFilter)
  is
  begin
    oScheduleFilter.FILTER_TYPE              := null;
    oScheduleFilter.FILTER_ID                := null;
    oScheduleFilter.PAC_CUSTOM_PARTNER_ID    := null;
    oScheduleFilter.PAC_SUPPLIER_PARTNER_ID  := null;
    oScheduleFilter.PAC_DEPARTMENT_ID        := null;
    oScheduleFilter.FAL_FACTORY_FLOOR_ID     := null;
    oScheduleFilter.HRM_PERSON_ID            := null;
    oScheduleFilter.HRM_DIVISION_ID          := null;

    if     (iFilter is not null)
       and (iFilterID is not null) then
      oScheduleFilter.FILTER_TYPE  := upper(iFilter);
      oScheduleFilter.FILTER_ID    := iFilterID;

      if oScheduleFilter.FILTER_TYPE = 'CUSTOMER' then
        oScheduleFilter.PAC_CUSTOM_PARTNER_ID  := iFilterID;
      elsif oScheduleFilter.FILTER_TYPE = 'SUPPLIER' then
        oScheduleFilter.PAC_SUPPLIER_PARTNER_ID  := iFilterID;
      elsif oScheduleFilter.FILTER_TYPE = 'FACTORY_FLOOR' then
        oScheduleFilter.FAL_FACTORY_FLOOR_ID  := iFilterID;
      elsif oScheduleFilter.FILTER_TYPE = 'PAC_DEPARTMENT' then
        oScheduleFilter.PAC_DEPARTMENT_ID  := iFilterID;
      elsif oScheduleFilter.FILTER_TYPE = 'HRM_PERSON' then
        oScheduleFilter.HRM_PERSON_ID  := iFilterID;
      elsif oScheduleFilter.FILTER_TYPE = 'HRM_DIVISION' then
        oScheduleFilter.HRM_DIVISION_ID  := iFilterID;
      else
        oScheduleFilter.FILTER_TYPE  := null;
        oScheduleFilter.FILTER_ID    := null;
      end if;
    end if;
  end InitScheduleFilter;

  /**
  *  procedure PrepareInterrogation
  *  Description
  *    Insertion des données dans la table PAC_SCHEDULE_INTERROGATION pour l'affichage d'un horaire.
  *    Cette table a été crée avec une structure spécifique pour les besoins d'un composant agenda
  */
  procedure PrepareInterrogation(
    iScheduleID    in PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iDateFrom      in date
  , iDateTo        in date
  , iStartTime     in varchar2 default null
  , iEndTime       in varchar2 default null
  , iFilter        in varchar2 default null
  , iFilterID      in number default null
  , iInterroNumber in PAC_SCHEDULE_INTERRO.SCI_INTERRO_NUMBER%type default null
  )
  is
    lCode           integer;
    lStartTime      PAC_SCHEDULE_PERIOD.SCP_OPEN_TIME%type         default 0.0;
    lEndTime        PAC_SCHEDULE_PERIOD.SCP_CLOSE_TIME%type        default 0.0;
    lInterroNumber  PAC_SCHEDULE_INTERRO.SCI_INTERRO_NUMBER%type;
    lDateFrom       date;
    lDateTo         date;
    lScheduleFilter PAC_LIB_SCHEDULE.TScheduleFilter;
  begin
    delete from PAC_SCHEDULE_INTERRO;

    lDateFrom  := trunc(iDateFrom);
    lDateTo    := trunc(iDateTo);

    -- Numéro pour l'identification d'une interrogation
    select nvl(iInterroNumber, INIT_ID_SEQ.nextval)
      into lInterroNumber
      from dual;

    -- Heure de départ de la période
    if iStartTime is not null then
      select to_date(iStartTime, 'HH24:MI') - to_date('00:00', 'HH24:MI')
        into lStartTime
        from dual;
    end if;

    -- Heure de fin de la période
    if iEndTime is not null then
      select to_date(iEndTime, 'HH24:MI') - to_date('00:00', 'HH24:MI')
        into lEndTime
        from dual;
    end if;

    -- Initialise la variable de retour avec l'id du filtre passé en param
    PAC_I_LIB_SCHEDULE.InitScheduleFilter(iFilter => iFilter, iFilterID => iFilterID, oScheduleFilter => lScheduleFilter);

    -- Interrogation horaire client, fournisseur, département, atelier ou personne
    if (lScheduleFilter.FILTER_ID is not null) then
      insert into PAC_SCHEDULE_INTERRO
                  (PAC_SCHEDULE_INTERRO_ID
                 , SCI_INTERRO_NUMBER
                 , PAC_SCHEDULE_PERIOD_ID
                 , PAC_SCHEDULE_ID
                 , DIC_SCH_PERIOD_1_ID
                 , DIC_SCH_PERIOD_2_ID
                 , C_DAY_OF_WEEK
                 , SCP_OPEN_TIME
                 , SCP_CLOSE_TIME
                 , SCI_START_TIME
                 , SCI_END_TIME
                 , SCP_DATE
                 , SCP_NONWORKING_DAY
                 , SCP_COMMENT
                 , SCP_RESOURCE_NUMBER
                 , SCP_RESOURCE_CAPACITY
                 , SCP_RESOURCE_CAP_IN_QTY
                 , SCP_PIECES_HOUR_CAP
                 , PAC_CUSTOM_PARTNER_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , PER_NAME
                 , PAC_DEPARTMENT_ID
                 , DEP_KEY
                 , FAL_FACTORY_FLOOR_ID
                 , FAC_REFERENCE
                 , HRM_PERSON_ID
                 , PER_FULLNAME
                 , HRM_DIVISION_ID
                 , DIV_DESCR
                 , A_IDCRE
                 , A_IDMOD
                 , A_DATECRE
                 , A_DATEMOD
                  )
        select INIT_ID_SEQ.nextval
             , lInterroNumber
             , MAIN.PAC_SCHEDULE_PERIOD_ID
             , MAIN.PAC_SCHEDULE_ID
             , MAIN.DIC_SCH_PERIOD_1_ID
             , MAIN.DIC_SCH_PERIOD_2_ID
             , MAIN.C_DAY_OF_WEEK
             , MAIN.SCP_OPEN_TIME
             , MAIN.SCP_CLOSE_TIME
             , INTERRO.START_TIME
             , INTERRO.END_TIME
             , INTERRO.DAY_DATE
             , MAIN.SCP_NONWORKING_DAY
             , MAIN.SCP_COMMENT
             , MAIN.SCP_RESOURCE_NUMBER
             , MAIN.SCP_RESOURCE_CAPACITY
             , MAIN.SCP_RESOURCE_CAP_IN_QTY
             , MAIN.SCP_PIECES_HOUR_CAP
             , MAIN.PAC_CUSTOM_PARTNER_ID
             , MAIN.PAC_SUPPLIER_PARTNER_ID
             , PER.PER_NAME
             , MAIN.PAC_DEPARTMENT_ID
             , decode(MAIN.PAC_DEPARTMENT_ID, null, null, DEP.DEP_KEY)
             , MAIN.FAL_FACTORY_FLOOR_ID
             , decode(MAIN.FAL_FACTORY_FLOOR_ID, null, null, FAC.FAC_REFERENCE)
             , MAIN.HRM_PERSON_ID
             , decode(MAIN.HRM_PERSON_ID, null, null, HRM.PER_FULLNAME)
             , MAIN.HRM_DIVISION_ID
             , decode(MAIN.HRM_DIVISION_ID, null, null, DIV.DIV_DESCR)
             , MAIN.A_IDCRE
             , MAIN.A_IDMOD
             , MAIN.A_DATECRE
             , MAIN.A_DATEMOD
          from PAC_SCHEDULE_PERIOD MAIN
             , (select max(PER.PER_NAME) PER_NAME
                  from PAC_PERSON PER
                     , (select max(PAC_PERSON_ID) PAC_PERSON_ID
                          from PAC_DEPARTMENT
                         where PAC_DEPARTMENT_ID = lScheduleFilter.PAC_DEPARTMENT_ID) DEP
                 where PER.PAC_PERSON_ID = nvl(DEP.PAC_PERSON_ID, nvl(lScheduleFilter.PAC_CUSTOM_PARTNER_ID, lScheduleFilter.PAC_SUPPLIER_PARTNER_ID) ) ) PER
             , (select max(DEP.DEP_KEY) DEP_KEY
                  from PAC_DEPARTMENT DEP
                 where PAC_DEPARTMENT_ID = lScheduleFilter.PAC_DEPARTMENT_ID) DEP
             , (select max(FAC_REFERENCE) FAC_REFERENCE
                  from FAL_FACTORY_FLOOR
                 where FAL_FACTORY_FLOOR_ID = lScheduleFilter.FAL_FACTORY_FLOOR_ID) FAC
             , (select max(PER_FULLNAME) PER_FULLNAME
                  from HRM_PERSON
                 where HRM_PERSON_ID = lScheduleFilter.HRM_PERSON_ID) HRM
             , (select max(DIV_DESCR) DIV_DESCR
                  from HRM_DIVISION
                 where HRM_DIVISION_ID = lScheduleFilter.HRM_DIVISION_ID) DIV
             , (
-- Liste des dates qui sont uniquement liées au filtre
                select DAYS.DAY_DATE
                     , DAYS.DAY_DATE + nvl(SCP.SCP_OPEN_TIME, lStartTime) START_TIME
                     , DAYS.DAY_DATE + nvl(SCP.SCP_CLOSE_TIME, lEndTime) END_TIME
                     , SCP.PAC_SCHEDULE_PERIOD_ID
                  from PAC_SCHEDULE_PERIOD SCP
                     , (select   trunc(lDateFrom - 1) + no DAY_DATE
                            from PCS.PC_NUMBER
                           where no <= (lDateTo - lDateFrom) + 1
                        order by no) DAYS
                 where SCP.PAC_SCHEDULE_ID = iScheduleID
                   and DAYS.DAY_DATE = SCP.SCP_DATE
                   and nvl(SCP.PAC_CUSTOM_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_CUSTOM_PARTNER_ID, -1)
                   and nvl(SCP.PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_SUPPLIER_PARTNER_ID, -1)
                   and nvl(SCP.PAC_DEPARTMENT_ID, -1) = nvl(lScheduleFilter.PAC_DEPARTMENT_ID, -1)
                   and nvl(SCP.FAL_FACTORY_FLOOR_ID, -1) = nvl(lScheduleFilter.FAL_FACTORY_FLOOR_ID, -1)
                   and nvl(SCP.HRM_PERSON_ID, -1) = nvl(lScheduleFilter.HRM_PERSON_ID, -1)
                   and nvl(SCP.HRM_DIVISION_ID, -1) = nvl(lScheduleFilter.HRM_DIVISION_ID, -1)
-- Liste des dates qui ne sont pas liées au filtre
                union
                select DAYS.DAY_DATE
                     , DAYS.DAY_DATE + nvl(SCP.SCP_OPEN_TIME, lStartTime) START_TIME
                     , DAYS.DAY_DATE + nvl(SCP.SCP_CLOSE_TIME, lEndTime) END_TIME
                     , SCP.PAC_SCHEDULE_PERIOD_ID
                  from PAC_SCHEDULE_PERIOD SCP
                     , (select   trunc(lDateFrom - 1) + no DAY_DATE
                            from PCS.PC_NUMBER
                           where no <= (lDateTo - lDateFrom) + 1
                        order by no) DAYS
                 where SCP.PAC_SCHEDULE_ID = iScheduleID
                   and DAYS.DAY_DATE = SCP.SCP_DATE
                   and SCP.PAC_CUSTOM_PARTNER_ID is null
                   and SCP.PAC_SUPPLIER_PARTNER_ID is null
                   and SCP.PAC_DEPARTMENT_ID is null
                   and SCP.FAL_FACTORY_FLOOR_ID is null
                   and SCP.HRM_PERSON_ID is null
                   and SCP.HRM_DIVISION_ID is null
                   and not exists(
                         select SCP_DATE
                           from PAC_SCHEDULE_PERIOD
                          where PAC_SCHEDULE_ID = iScheduleID
                            and SCP_DATE = DAYS.DAY_DATE
                            and nvl(PAC_CUSTOM_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_CUSTOM_PARTNER_ID, -1)
                            and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_SUPPLIER_PARTNER_ID, -1)
                            and nvl(PAC_DEPARTMENT_ID, -1) = nvl(lScheduleFilter.PAC_DEPARTMENT_ID, -1)
                            and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lScheduleFilter.FAL_FACTORY_FLOOR_ID, -1)
                            and nvl(HRM_PERSON_ID, -1) = nvl(lScheduleFilter.HRM_PERSON_ID, -1)
                            and nvl(HRM_DIVISION_ID, -1) = nvl(lScheduleFilter.HRM_DIVISION_ID, -1) )
-- Liste des jours qui sont uniquement liés au filtre
                union
                select DAYS.DAY_DATE
                     , DAYS.DAY_DATE + nvl(SCP.SCP_OPEN_TIME, lStartTime) START_TIME
                     , DAYS.DAY_DATE + nvl(SCP.SCP_CLOSE_TIME, lEndTime) END_TIME
                     , SCP.PAC_SCHEDULE_PERIOD_ID
                  from PAC_SCHEDULE_PERIOD SCP
                     , (select   trunc(lDateFrom - 1) + no DAY_DATE
                            from PCS.PC_NUMBER
                           where no <= (lDateTo - lDateFrom) + 1
                        order by no) DAYS
                 where SCP.PAC_SCHEDULE_ID = iScheduleID
                   and nvl(SCP.PAC_CUSTOM_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_CUSTOM_PARTNER_ID, -1)
                   and nvl(SCP.PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_SUPPLIER_PARTNER_ID, -1)
                   and nvl(SCP.PAC_DEPARTMENT_ID, -1) = nvl(lScheduleFilter.PAC_DEPARTMENT_ID, -1)
                   and nvl(SCP.FAL_FACTORY_FLOOR_ID, -1) = nvl(lScheduleFilter.FAL_FACTORY_FLOOR_ID, -1)
                   and nvl(SCP.HRM_PERSON_ID, -1) = nvl(lScheduleFilter.HRM_PERSON_ID, -1)
                   and nvl(SCP.HRM_DIVISION_ID, -1) = nvl(lScheduleFilter.HRM_DIVISION_ID, -1)
                   and to_char(DAYS.DAY_DATE, 'DY') = SCP.C_DAY_OF_WEEK
                   and not exists(
                         select SCP_DATE
                           from PAC_SCHEDULE_PERIOD
                          where PAC_SCHEDULE_ID = iScheduleID
                            and SCP_DATE = DAYS.DAY_DATE
                            and nvl(PAC_CUSTOM_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_CUSTOM_PARTNER_ID, -1)
                            and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_SUPPLIER_PARTNER_ID, -1)
                            and nvl(PAC_DEPARTMENT_ID, -1) = nvl(lScheduleFilter.PAC_DEPARTMENT_ID, -1)
                            and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lScheduleFilter.FAL_FACTORY_FLOOR_ID, -1)
                            and nvl(HRM_PERSON_ID, -1) = nvl(lScheduleFilter.HRM_PERSON_ID, -1)
                            and nvl(HRM_DIVISION_ID, -1) = nvl(lScheduleFilter.HRM_DIVISION_ID, -1) )
                   and not exists(
                         select SCP_DATE
                           from PAC_SCHEDULE_PERIOD
                          where PAC_SCHEDULE_ID = iScheduleID
                            and SCP_DATE = DAYS.DAY_DATE
                            and PAC_CUSTOM_PARTNER_ID is null
                            and PAC_SUPPLIER_PARTNER_ID is null
                            and PAC_DEPARTMENT_ID is null
                            and FAL_FACTORY_FLOOR_ID is null
                            and HRM_PERSON_ID is null
                            and HRM_DIVISION_ID is null)
-- Liste des jours qui ne sont pas liés au filtre
                union
                select DAYS.DAY_DATE
                     , DAYS.DAY_DATE + nvl(SCP.SCP_OPEN_TIME, lStartTime) START_TIME
                     , DAYS.DAY_DATE + nvl(SCP.SCP_CLOSE_TIME, lEndTime) END_TIME
                     , SCP.PAC_SCHEDULE_PERIOD_ID
                  from PAC_SCHEDULE_PERIOD SCP
                     , (select   trunc(lDateFrom - 1) + no DAY_DATE
                            from PCS.PC_NUMBER
                           where no <= (lDateTo - lDateFrom) + 1
                        order by no) DAYS
                 where SCP.PAC_SCHEDULE_ID = iScheduleID
                   and SCP.PAC_CUSTOM_PARTNER_ID is null
                   and SCP.PAC_SUPPLIER_PARTNER_ID is null
                   and SCP.PAC_DEPARTMENT_ID is null
                   and SCP.FAL_FACTORY_FLOOR_ID is null
                   and SCP.HRM_PERSON_ID is null
                   and SCP.HRM_DIVISION_ID is null
                   and to_char(DAYS.DAY_DATE, 'DY') = SCP.C_DAY_OF_WEEK
                   and not exists(
                         select SCP_DATE
                           from PAC_SCHEDULE_PERIOD
                          where PAC_SCHEDULE_ID = iScheduleID
                            and SCP_DATE = DAYS.DAY_DATE
                            and nvl(PAC_CUSTOM_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_CUSTOM_PARTNER_ID, -1)
                            and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_SUPPLIER_PARTNER_ID, -1)
                            and nvl(PAC_DEPARTMENT_ID, -1) = nvl(lScheduleFilter.PAC_DEPARTMENT_ID, -1)
                            and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lScheduleFilter.FAL_FACTORY_FLOOR_ID, -1)
                            and nvl(HRM_PERSON_ID, -1) = nvl(lScheduleFilter.HRM_PERSON_ID, -1)
                            and nvl(HRM_DIVISION_ID, -1) = nvl(lScheduleFilter.HRM_DIVISION_ID, -1) )
                   and not exists(
                         select SCP_DATE
                           from PAC_SCHEDULE_PERIOD
                          where PAC_SCHEDULE_ID = iScheduleID
                            and SCP_DATE = DAYS.DAY_DATE
                            and PAC_CUSTOM_PARTNER_ID is null
                            and PAC_SUPPLIER_PARTNER_ID is null
                            and PAC_DEPARTMENT_ID is null
                            and FAL_FACTORY_FLOOR_ID is null
                            and HRM_PERSON_ID is null
                            and HRM_DIVISION_ID is null)
                   and not exists(
                         select SCP_DATE
                           from PAC_SCHEDULE_PERIOD
                          where PAC_SCHEDULE_ID = iScheduleID
                            and C_DAY_OF_WEEK = SCP.C_DAY_OF_WEEK
                            and nvl(PAC_CUSTOM_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_CUSTOM_PARTNER_ID, -1)
                            and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_SUPPLIER_PARTNER_ID, -1)
                            and nvl(PAC_DEPARTMENT_ID, -1) = nvl(lScheduleFilter.PAC_DEPARTMENT_ID, -1)
                            and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lScheduleFilter.FAL_FACTORY_FLOOR_ID, -1)
                            and nvl(HRM_PERSON_ID, -1) = nvl(lScheduleFilter.HRM_PERSON_ID, -1)
                            and nvl(HRM_DIVISION_ID, -1) = nvl(lScheduleFilter.HRM_DIVISION_ID, -1) ) ) INTERRO
         where MAIN.PAC_SCHEDULE_PERIOD_ID = INTERRO.PAC_SCHEDULE_PERIOD_ID;
    -- Interrogation horaire standard (PAS DE client, fournisseur, atelier ou personne )
    else
      insert into PAC_SCHEDULE_INTERRO
                  (PAC_SCHEDULE_INTERRO_ID
                 , SCI_INTERRO_NUMBER
                 , PAC_SCHEDULE_PERIOD_ID
                 , PAC_SCHEDULE_ID
                 , DIC_SCH_PERIOD_1_ID
                 , DIC_SCH_PERIOD_2_ID
                 , C_DAY_OF_WEEK
                 , SCP_OPEN_TIME
                 , SCP_CLOSE_TIME
                 , SCI_START_TIME
                 , SCI_END_TIME
                 , SCP_DATE
                 , SCP_NONWORKING_DAY
                 , SCP_COMMENT
                 , SCP_RESOURCE_NUMBER
                 , SCP_RESOURCE_CAPACITY
                 , SCP_RESOURCE_CAP_IN_QTY
                 , SCP_PIECES_HOUR_CAP
                 , PAC_CUSTOM_PARTNER_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , PER_NAME
                 , PAC_DEPARTMENT_ID
                 , DEP_KEY
                 , FAL_FACTORY_FLOOR_ID
                 , FAC_REFERENCE
                 , HRM_PERSON_ID
                 , PER_FULLNAME
                 , HRM_DIVISION_ID
                 , DIV_DESCR
                 , A_IDCRE
                 , A_IDMOD
                 , A_DATECRE
                 , A_DATEMOD
                  )
        select INIT_ID_SEQ.nextval
             , lInterroNumber
             , MAIN.PAC_SCHEDULE_PERIOD_ID
             , MAIN.PAC_SCHEDULE_ID
             , MAIN.DIC_SCH_PERIOD_1_ID
             , MAIN.DIC_SCH_PERIOD_2_ID
             , MAIN.C_DAY_OF_WEEK
             , MAIN.SCP_OPEN_TIME
             , MAIN.SCP_CLOSE_TIME
             , INTERRO.START_TIME
             , INTERRO.END_TIME
             , INTERRO.DAY_DATE
             , MAIN.SCP_NONWORKING_DAY
             , MAIN.SCP_COMMENT
             , MAIN.SCP_RESOURCE_NUMBER
             , MAIN.SCP_RESOURCE_CAPACITY
             , MAIN.SCP_RESOURCE_CAP_IN_QTY
             , MAIN.SCP_PIECES_HOUR_CAP
             , null PAC_CUSTOM_PARTNER_ID
             , null PAC_SUPPLIER_PARTNER_ID
             , null PER_NAME
             , null PAC_DEPARTMENT_ID
             , null DEP_KEY
             , null FAL_FACTORY_FLOOR_ID
             , null FAC_REFERENCE
             , null HRM_PERSON_ID
             , null PER_FULLNAME
             , null HRM_DIVISION_ID
             , null DIV_DESCR
             , MAIN.A_IDCRE
             , MAIN.A_IDMOD
             , MAIN.A_DATECRE
             , MAIN.A_DATEMOD
          from PAC_SCHEDULE_PERIOD MAIN
             , (select DAYS.DAY_DATE
                     , DAYS.DAY_DATE + nvl(SCP.SCP_OPEN_TIME, lStartTime) START_TIME
                     , DAYS.DAY_DATE + nvl(SCP.SCP_CLOSE_TIME, lEndTime) END_TIME
                     , SCP.PAC_SCHEDULE_PERIOD_ID
                  from PAC_SCHEDULE_PERIOD SCP
                     , (select   trunc(lDateFrom - 1) + no DAY_DATE
                            from PCS.PC_NUMBER
                           where no <= (lDateTo - lDateFrom) + 1
                        order by no) DAYS
                 where SCP.PAC_SCHEDULE_ID = iScheduleID
                   and DAYS.DAY_DATE = SCP.SCP_DATE
                   and SCP.PAC_CUSTOM_PARTNER_ID is null
                   and SCP.PAC_SUPPLIER_PARTNER_ID is null
                   and SCP.PAC_DEPARTMENT_ID is null
                   and SCP.FAL_FACTORY_FLOOR_ID is null
                   and SCP.HRM_PERSON_ID is null
                   and SCP.HRM_DIVISION_ID is null
                union
                select DAYS.DAY_DATE
                     , DAYS.DAY_DATE + nvl(SCP.SCP_OPEN_TIME, lStartTime) START_TIME
                     , DAYS.DAY_DATE + nvl(SCP.SCP_CLOSE_TIME, lEndTime) END_TIME
                     , SCP.PAC_SCHEDULE_PERIOD_ID
                  from PAC_SCHEDULE_PERIOD SCP
                     , (select   trunc(lDateFrom - 1) + no DAY_DATE
                            from PCS.PC_NUMBER
                           where no <= (lDateTo - lDateFrom) + 1
                        order by no) DAYS
                 where SCP.PAC_SCHEDULE_ID = iScheduleID
                   and SCP.PAC_CUSTOM_PARTNER_ID is null
                   and SCP.PAC_SUPPLIER_PARTNER_ID is null
                   and SCP.PAC_DEPARTMENT_ID is null
                   and SCP.FAL_FACTORY_FLOOR_ID is null
                   and SCP.HRM_PERSON_ID is null
                   and SCP.HRM_DIVISION_ID is null
                   and to_char(DAYS.DAY_DATE, 'DY') = SCP.C_DAY_OF_WEEK
                   and not exists(
                         select SCP_DATE
                           from PAC_SCHEDULE_PERIOD
                          where PAC_SCHEDULE_ID = iScheduleID
                            and SCP_DATE = DAYS.DAY_DATE
                            and PAC_CUSTOM_PARTNER_ID is null
                            and PAC_SUPPLIER_PARTNER_ID is null
                            and PAC_DEPARTMENT_ID is null
                            and FAL_FACTORY_FLOOR_ID is null
                            and HRM_PERSON_ID is null
                            and HRM_DIVISION_ID is null) ) INTERRO
         where MAIN.PAC_SCHEDULE_PERIOD_ID = INTERRO.PAC_SCHEDULE_PERIOD_ID;
    end if;
  end PrepareInterrogation;

  /**
  *  procedure CheckSchedulePeriod
  *  Description
  *    Vérification que la période passée en paramêtre ne soit pas en conflit avec une autre période
  */
  procedure CheckSchedulePeriod(
    iPeriodID      in     PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  , iScheduleID    in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iDate          in     PAC_SCHEDULE_PERIOD.SCP_DATE%type
  , iDayOfWeek     in     PAC_SCHEDULE_PERIOD.C_DAY_OF_WEEK%type
  , iNonWorkingDay in     PAC_SCHEDULE_PERIOD.SCP_NONWORKING_DAY%type
  , iStartTime     in     PAC_SCHEDULE_PERIOD.SCP_OPEN_TIME%type
  , iEndTime       in     PAC_SCHEDULE_PERIOD.SCP_CLOSE_TIME%type
  , iFilter        in     varchar2
  , iFilterID      in     number
  , oErrorPeriodID out    PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  )
  is
    lDate           date;
    lScheduleFilter PAC_LIB_SCHEDULE.TScheduleFilter;
  begin
    lDate  := trunc(iDate);
    -- Initialise la variable de retour avec l'id du filtre passé en param
    PAC_I_LIB_SCHEDULE.InitScheduleFilter(iFilter => iFilter, iFilterID => iFilterID, oScheduleFilter => lScheduleFilter);

    if iNonWorkingDay = 1 then
      select max(PAC_SCHEDULE_PERIOD_ID)
        into oErrorPeriodID
        from PAC_SCHEDULE_PERIOD
       where PAC_SCHEDULE_ID = iScheduleID
         and PAC_SCHEDULE_PERIOD_ID <> nvl(iPeriodID, 0)
         and (    (SCP_DATE = lDate)
              or (    lDate is null
                  and SCP_DATE is null) )
         and nvl(C_DAY_OF_WEEK, 'NULL') = nvl(iDayOfWeek, 'NULL')
         and nvl(PAC_CUSTOM_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_CUSTOM_PARTNER_ID, -1)
         and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_SUPPLIER_PARTNER_ID, -1)
         and nvl(PAC_DEPARTMENT_ID, -1) = nvl(lScheduleFilter.PAC_DEPARTMENT_ID, -1)
         and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lScheduleFilter.FAL_FACTORY_FLOOR_ID, -1)
         and nvl(HRM_PERSON_ID, -1) = nvl(lScheduleFilter.HRM_PERSON_ID, -1)
         and nvl(HRM_DIVISION_ID, -1) = nvl(lScheduleFilter.HRM_DIVISION_ID, -1);
    else
      select max(PAC_SCHEDULE_PERIOD_ID)
        into oErrorPeriodID
        from PAC_SCHEDULE_PERIOD
       where PAC_SCHEDULE_ID = iScheduleID
         and PAC_SCHEDULE_PERIOD_ID <> nvl(iPeriodID, 0)
         and (    (SCP_DATE = lDate)
              or (    lDate is null
                  and SCP_DATE is null) )
         and nvl(C_DAY_OF_WEEK, 'NULL') = nvl(iDayOfWeek, 'NULL')
         and nvl(PAC_CUSTOM_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_CUSTOM_PARTNER_ID, -1)
         and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lScheduleFilter.PAC_SUPPLIER_PARTNER_ID, -1)
         and nvl(PAC_DEPARTMENT_ID, -1) = nvl(lScheduleFilter.PAC_DEPARTMENT_ID, -1)
         and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lScheduleFilter.FAL_FACTORY_FLOOR_ID, -1)
         and nvl(HRM_PERSON_ID, -1) = nvl(lScheduleFilter.HRM_PERSON_ID, -1)
         and nvl(HRM_DIVISION_ID, -1) = nvl(lScheduleFilter.HRM_DIVISION_ID, -1)
         and (    (     (SCP_OPEN_TIME >= iStartTime)
                   and (SCP_OPEN_TIME < iEndTime) )
              or (     (SCP_CLOSE_TIME > iStartTime)
                  and (SCP_CLOSE_TIME <= iEndTime) )
              or (     (iStartTime >= SCP_OPEN_TIME)
                  and (iStartTime < SCP_CLOSE_TIME) )
              or (     (iEndTime > SCP_OPEN_TIME)
                  and (iEndTime <= SCP_CLOSE_TIME) )
             );
    end if;
  end CheckSchedulePeriod;

  /**
  *  function GetOpenDaysBetween
  *  Description
  *    Calcule le nb de jours ouvrables entre 2 dates (ID de l'horaire passé en param)
  */
  function GetOpenDaysBetween(
    iScheduleID in PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iDateFrom   in date
  , iDateTo     in date
  , iFilter     in varchar2 default null
  , iFilterID   in number default null
  , iRoundUp    in number default 0
  )
    return integer
  is
    lScheduleID    PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    lnDays         integer;
    lCustomerID    PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type       default null;
    lSupplierID    PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type   default null;
    lDepartmentID  PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type               default null;
    lFactFloorID   FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type         default null;
    lHRMPersonID   HRM_PERSON.HRM_PERSON_ID%type                       default null;
    lHRMDivisionID HRM_DIVISION.HRM_DIVISION_ID%type                   default null;
    lDateFrom      date;
    lDateTo        date;
    lFactor        integer;
  begin
    -- Inverser les dates si pas cohérent
    if iDateFrom > iDateTo then
      lDateFrom  := trunc(iDateTo);
      lDateTo    := trunc(iDateFrom);
      lFactor    := -1;
    else
      lDateFrom  := trunc(iDateFrom);
      lDateTo    := trunc(iDateTo);
      lFactor    := 1;
    end if;

    -- Recherche l'ID de l'horaire par défaut si ID pas passé en param
    if iScheduleID is null then
      select max(PAC_SCHEDULE_ID)
        into lScheduleID
        from PAC_SCHEDULE
       where SCE_DEFAULT = 1;
    else
      lScheduleID  := iScheduleID;
    end if;

    -- Filtre Client/Fournisseur/Département/Atelier/PersonneHRM sur les périodes de l'horaire
    if iFilter = 'CUSTOMER' then
      lCustomerID  := iFilterID;
    elsif iFilter = 'SUPPLIER' then
      lSupplierID  := iFilterID;
    elsif iFilter = 'DEPARTMENT' then
      lDepartmentID  := iFilterID;
    elsif iFilter = 'FACTORY_FLOOR' then
      lFactFloorID  := iFilterID;
    elsif iFilter = 'HRM_PERSON' then
      lHRMPersonID  := iFilterID;
    elsif iFilter = 'HRM_DIVISION' then
      lHRMDivisionID  := iFilterID;
    end if;

    select count(*)
      into lnDays
      from (
            -- Liste des dates
            select SCP.SCP_DATE DAY_DATE
                 , decode(SCP.SCP_NONWORKING_DAY, 0, 1, 0) WORK_DAY
              from PAC_SCHEDULE_PERIOD SCP
             where SCP.PAC_SCHEDULE_ID = lScheduleID
               and SCP.SCP_DATE between lDateFrom and lDateTo
               and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
               and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
               and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
               and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
               and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
               and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1)
            union
            -- Liste des jours
            select distinct DAYS.DAY_DATE
                          , decode(SCP.SCP_NONWORKING_DAY, 0, 1, 0) WORK_DAY
                       from PAC_SCHEDULE_PERIOD SCP
                          , (select   trunc(lDateFrom - 1) + no DAY_DATE
                                 from PCS.PC_NUMBER
                                where no <= (lDateTo - lDateFrom) + 1
                             order by no) DAYS
                      where SCP.PAC_SCHEDULE_ID = lScheduleID
                        and SCP.C_DAY_OF_WEEK is not null
                        and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
                        and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
                        and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
                        and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
                        and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
                        and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1)
                        and to_char(DAYS.DAY_DATE, 'DY') = SCP.C_DAY_OF_WEEK
                        and DAYS.DAY_DATE not in(
                              select distinct SCP.SCP_DATE
                                         from PAC_SCHEDULE_PERIOD SCP
                                        where SCP.PAC_SCHEDULE_ID = lScheduleID
                                          and SCP.SCP_DATE between lDateFrom and lDateTo
                                          and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
                                          and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
                                          and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
                                          and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
                                          and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
                                          and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1) ) )
     where WORK_DAY = 1;

    -- Renvoyer une valeur négative si les dates ont été passées inversées
    if iRoundUp = 0 then
      return lnDays * lFactor;
    else
      return ACS_FUNCTION.PcsRound(ACS_FUNCTION.PcsRound(lnDays * lFactor, 3, 0.01), 4, 1);
    end if;
  exception
    when no_data_found then
      return -1;
  end GetOpenDaysBetween;

  /**
  * function IsOpenDay
  * Description
  *   Indique si la date passée est un jour ouvrable selon les horaires
  */
  function IsOpenDay(iScheduleID in PAC_SCHEDULE.PAC_SCHEDULE_ID%type, iDate in date, iFilter in varchar2 default null, iFilterID in number default null)
    return integer
  is
    lScheduleID    PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    lnOpenDay      integer;
    lCustomerID    PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type       default null;
    lSupplierID    PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type   default null;
    lDepartmentID  PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type               default null;
    lFactFloorID   FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type         default null;
    lHRMPersonID   HRM_PERSON.HRM_PERSON_ID%type                       default null;
    lHRMDivisionID HRM_DIVISION.HRM_DIVISION_ID%type                   default null;
  begin
    -- Recherche l'ID de l'horaire par défaut si ID pas passé en param
    if iScheduleID is null then
      lScheduleID  := GetDefaultSchedule;
    else
      lScheduleID  := iScheduleID;
    end if;

    -- Filtre Client/Fournisseur/Atelier/PersonneHRM sur les périodes de l'horaire
    if iFilter = 'CUSTOMER' then
      lCustomerID  := iFilterID;
    elsif iFilter = 'SUPPLIER' then
      lSupplierID  := iFilterID;
    elsif iFilter = 'DEPARTMENT' then
      lDepartmentID  := iFilterID;
    elsif iFilter = 'FACTORY_FLOOR' then
      lFactFloorID  := iFilterID;
    elsif iFilter = 'HRM_PERSON' then
      lHRMPersonID  := iFilterID;
    elsif iFilter = 'HRM_DIVISION' then
      lHRMDivisionID  := iFilterID;
    end if;

    select WORK_DAY
      into lnOpenDay
      from (
            -- Liste des dates
            select decode(SCP.SCP_NONWORKING_DAY, 0, 1, 0) WORK_DAY
              from PAC_SCHEDULE_PERIOD SCP
             where SCP.PAC_SCHEDULE_ID = lScheduleID
               and SCP.SCP_DATE = trunc(iDate)
               and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
               and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
               and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
               and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
               and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
               and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1)
            union
            -- Liste des jours
            select distinct decode(SCP.SCP_NONWORKING_DAY, 0, 1, 0) WORK_DAY
                       from PAC_SCHEDULE_PERIOD SCP
                      where SCP.PAC_SCHEDULE_ID = lScheduleID
                        and SCP.C_DAY_OF_WEEK is not null
                        and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
                        and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
                        and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
                        and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
                        and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
                        and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1)
                        and to_char(iDate, 'DY') = SCP.C_DAY_OF_WEEK
                        and not exists(
                              select distinct SCP.SCP_DATE
                                         from PAC_SCHEDULE_PERIOD SCP
                                        where SCP.PAC_SCHEDULE_ID = lScheduleID
                                          and SCP.SCP_DATE = trunc(iDate)
                                          and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
                                          and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
                                          and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
                                          and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
                                          and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
                                          and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1) ) );

    return lnOpenDay;
  exception
    when no_data_found then
      return -1;
  end IsOpenDay;

  /**
  * function GetDefaultSchedule
  * Description
  *    Recherche l'horaire par défaut
  */
  function GetDefaultSchedule
    return number
  is
    lScheduleID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    select max(PAC_SCHEDULE_ID)
      into lScheduleID
      from PAC_SCHEDULE
     where SCE_DEFAULT = 1;

    return lScheduleID;
  end GetDefaultSchedule;

  /**
  * procedure GetLogisticThirdSchedule
  * Description
  *    Recherche l'horaire du tiers (méthode pour la logistique)
  */
  procedure GetLogisticThirdSchedule(
    iThirdID     in     PAC_THIRD.PAC_THIRD_ID%type
  , iAdminDomain in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , oScheduleId  out    PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , oFilter      out    varchar2
  , oFilterID    out    number
  )
  is
    lCustomerScheduleID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    lSupplierScheduleID PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    if iThirdID is not null then
      -- Calendrier du tiers
      select max(SUP.PAC_SCHEDULE_ID)
           , max(CUS.PAC_SCHEDULE_ID)
        into lSupplierScheduleID
           , lCustomerScheduleID
        from PAC_THIRD THI
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where THI.PAC_THIRD_ID = iThirdID
         and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
         and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+);

      -- Domaine Achat ou sous-traitance
      if iAdminDomain in('1', '5') then
        oScheduleId  := lSupplierScheduleID;
        oFilter      := 'SUPPLIER';
        oFilterID    := iThirdID;
      -- Domaine Vente ou SAV
      elsif iAdminDomain in('2', '7') then
        oScheduleId  := lCustomerScheduleID;
        oFilter      := 'CUSTOMER';
        oFilterID    := iThirdID;
      -- Autre domaine
      else
        if lCustomerScheduleID is not null then
          oScheduleId  := lCustomerScheduleID;
          oFilter      := 'CUSTOMER';
          oFilterID    := iThirdID;
        elsif lSupplierScheduleID is not null then
          oScheduleId  := lSupplierScheduleID;
          oFilter      := 'SUPPLIER';
          oFilterID    := iThirdID;
        end if;
      end if;
    end if;
  end GetLogisticThirdSchedule;

  /**
  * function GetShiftOpenDate
  * Description
  *    Incrémente ou décremente une date avec un décalage donné
  *    en fonction des jours ouvrables de l'horaire demandé selon les params des filtres
  */
  function GetShiftOpenDate(
    iScheduleID in PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iDateFrom   in date
  , iCalcDays   in integer default 0
  , iForward    in integer default 1
  , iFilter     in varchar2 default null
  , iFilterID   in number default null
  )
    return date
  is
    lScheduleID    PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    lReturnDate    date;
    lnOpenWeekDays number(20);
    lnCloseDates   number(20);
    lnScheduleDays number(20);
    lnCalcDays     number(20);
    lnFactor       integer;
    lDateFrom      date;
    lDateTo        date;
    lCustomerID    PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type       default null;
    lSupplierID    PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type   default null;
    lDepartmentID  PAC_DEPARTMENT.PAC_DEPARTMENT_ID%type               default null;
    lFactFloorID   FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type         default null;
    lHRMPersonID   HRM_PERSON.HRM_PERSON_ID%type                       default null;
    lHRMDivisionID HRM_DIVISION.HRM_DIVISION_ID%type                   default null;
  begin
    lReturnDate  := trunc(iDateFrom);

    -- Recherche l'ID de l'horaire par défaut si ID pas passé en param
    if iScheduleID is null then
      lScheduleID  := GetDefaultSchedule;
    else
      lScheduleID  := iScheduleID;
    end if;

    lnCalcDays   := abs(nvl(iCalcDays, 0) );

    -- Filtre Client/Fournisseur/Atelier/PersonneHRM sur les périodes de l'horaire
    if iFilter = 'CUSTOMER' then
      lCustomerID  := iFilterID;
    elsif iFilter = 'SUPPLIER' then
      lSupplierID  := iFilterID;
    elsif iFilter = 'DEPARTMENT' then
      lDepartmentID  := iFilterID;
    elsif iFilter = 'FACTORY_FLOOR' then
      lFactFloorID  := iFilterID;
    elsif iFilter = 'HRM_PERSON' then
      lHRMPersonID  := iFilterID;
    elsif iFilter = 'HRM_DIVISION' then
      lHRMDivisionID  := iFilterID;
    end if;

    -- Rechercher le nb de jours ouvrés par semaine
    select 7 - count(*)
      into lnOpenWeekDays
      from PAC_SCHEDULE_PERIOD
     where PAC_SCHEDULE_ID = lScheduleID
       and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
       and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
       and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
       and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
       and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
       and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1)
       and SCP_NONWORKING_DAY = 1
       and C_DAY_OF_WEEK is not null;

    -- Rechercher le nb de jours fermés (avec date) après/avant la date demandée
    if iForward = 1 then
      select count(*)
        into lnCloseDates
        from PAC_SCHEDULE_PERIOD
       where PAC_SCHEDULE_ID = lScheduleID
         and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
         and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
         and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
         and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
         and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
         and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1)
         and SCP_NONWORKING_DAY = 1
         and SCP_DATE is not null
         and SCP_DATE >= trunc(iDateFrom);

      -- Recherche le nbr de jours pour la construction du calendrier pour avoir le nbr de jours ouvrables
      -- nécessaires pour calculer le décalage
      if lnCalcDays = 0 then
        lnScheduleDays  := lnOpenWeekDays + ceil(lnCloseDates /(lnOpenWeekDays / 7) ) + 7;
      else
        lnScheduleDays  := ceil(lnCalcDays /(lnOpenWeekDays / 7) ) + ceil(lnCloseDates /(lnOpenWeekDays / 7) ) + 7;
      end if;

      lDateFrom  := iDateFrom;
      lDateTo    := iDateFrom + lnScheduleDays;
      lnFactor   := 1;
    else
      select count(*)
        into lnCloseDates
        from PAC_SCHEDULE_PERIOD
       where PAC_SCHEDULE_ID = lScheduleID
         and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
         and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
         and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
         and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
         and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
         and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1)
         and SCP_NONWORKING_DAY = 1
         and SCP_DATE is not null
         and SCP_DATE <= trunc(iDateFrom);

      -- Recherche le nbr de jours pour la construction du calendrier pour avoir le nbr de jours ouvrables
      -- nécessaires pour calculer le décalage
      if lnCalcDays = 0 then
        lnScheduleDays  := lnOpenWeekDays + ceil(lnCloseDates /(lnOpenWeekDays / 7) ) + 7;
      else
        lnScheduleDays  := ceil(lnCalcDays /(lnOpenWeekDays / 7) ) + ceil(lnCloseDates /(lnOpenWeekDays / 7) ) + 7;
      end if;

      lDateFrom  := iDateFrom - lnScheduleDays;
      lDateTo    := iDateFrom;
      lnFactor   := -1;
    end if;

    -- Calcul de la date
    select DAY_DATE
      into lReturnDate
      from (select DAY_DATE
                 , rownum DAY_NUMBER
              from (select   DAY_DATE
                        from (
                              -- Liste des dates
                              select SCP.SCP_DATE DAY_DATE
                                   , decode(SCP.SCP_NONWORKING_DAY, 0, 1, 0) WORK_DAY
                                from PAC_SCHEDULE_PERIOD SCP
                               where SCP.PAC_SCHEDULE_ID = lScheduleID
                                 and SCP.SCP_DATE between lDateFrom and lDateTo
                                 and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
                                 and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
                                 and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
                                 and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
                                 and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
                                 and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1)
                              union
                              -- Liste des jours
                              select distinct DAYS.DAY_DATE
                                            , decode(SCP.SCP_NONWORKING_DAY, 0, 1, 0) WORK_DAY
                                         from PAC_SCHEDULE_PERIOD SCP
                                            , (select   trunc(iDateFrom +(-1 * lnFactor) ) +(no * lnFactor) DAY_DATE
                                                   from PCS.PC_NUMBER
                                                  where no <= lnScheduleDays
                                               order by no) DAYS
                                        where SCP.PAC_SCHEDULE_ID = lScheduleID
                                          and SCP.C_DAY_OF_WEEK is not null
                                          and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
                                          and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
                                          and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
                                          and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
                                          and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
                                          and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1)
                                          and to_char(DAYS.DAY_DATE, 'DY') = SCP.C_DAY_OF_WEEK
                                          and DAYS.DAY_DATE not in(
                                                select distinct SCP.SCP_DATE
                                                           from PAC_SCHEDULE_PERIOD SCP
                                                          where SCP.PAC_SCHEDULE_ID = lScheduleID
                                                            and SCP.SCP_DATE between lDateFrom and lDateTo
                                                            and nvl(PAC_CUSTOM_PARTNER_ID, nvl(lCustomerID, -1) ) = nvl(lCustomerID, -1)
                                                            and nvl(PAC_SUPPLIER_PARTNER_ID, nvl(lSupplierID, -1) ) = nvl(lSupplierID, -1)
                                                            and nvl(PAC_DEPARTMENT_ID, nvl(lDepartmentID, -1) ) = nvl(lDepartmentID, -1)
                                                            and nvl(FAL_FACTORY_FLOOR_ID, nvl(lFactFloorID, -1) ) = nvl(lFactFloorID, -1)
                                                            and nvl(HRM_PERSON_ID, nvl(lHRMPersonID, -1) ) = nvl(lHRMPersonID, -1)
                                                            and nvl(HRM_DIVISION_ID, nvl(lHRMDivisionID, -1) ) = nvl(lHRMDivisionID, -1) ) )
                       where WORK_DAY = 1
                    order by decode(iForward, 1, DAY_DATE, null) asc
                           , decode(iForward, 0, DAY_DATE, null) desc) )
     where DAY_NUMBER = iCalcDays + 1;

    return lReturnDate;
  exception
    when no_data_found then
      return null;
  end GetShiftOpenDate;

  /**
  * procedure CalcOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  */
  procedure CalcOpenTimeBetween(
    oTime       out    number
  , iScheduleID in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iDate_1     in     date
  , iDate_2     in     date
  , iFilter     in     varchar2 default null
  , iFilterID   in     number default null
  )
  is
  begin
    CalcOpenTimeBetween(oTime           => oTime
                      , iScheduleID_1   => iScheduleID
                      , iScheduleID_2   => iScheduleID
                      , iDate_1         => iDate_1
                      , iDate_2         => iDate_2
                      , iFilter_1       => iFilter
                      , iFilterID_1     => iFilterID
                      , iFilter_2       => iFilter
                      , iFilterID_2     => iFilterID
                       );
  end CalcOpenTimeBetween;

  /**
  * procedure CalcOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  */
  procedure CalcOpenTimeBetween(
    oTime             out    number
  , oResourceCapacity out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , oResourceCapQty   out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , iScheduleID       in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iDate_1           in     date
  , iDate_2           in     date
  , iFilter           in     varchar2 default null
  , iFilterID         in     number default null
  )
  is
  begin
    CalcOpenTimeBetween(oTime               => oTime
                      , oResourceCapacity   => oResourceCapacity
                      , oResourceCapQty     => oResourceCapQty
                      , iScheduleID_1       => iScheduleID
                      , iScheduleID_2       => iScheduleID
                      , iDate_1             => iDate_1
                      , iDate_2             => iDate_2
                      , iFilter_1           => iFilter
                      , iFilterID_1         => iFilterID
                      , iFilter_2           => iFilter
                      , iFilterID_2         => iFilterID
                       );
  end CalcOpenTimeBetween;

  /**
  * procedure CalcOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  */
  procedure CalcOpenTimeBetween(
    oTime         out    number
  , iScheduleID_1 in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iScheduleID_2 in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iDate_1       in     date
  , iDate_2       in     date
  , iFilter_1     in     varchar2 default null
  , iFilterID_1   in     number default null
  , iFilter_2     in     varchar2 default null
  , iFilterID_2   in     number default null
  )
  is
    lResourceCapacity PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type;
    lResourceCapQty   PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type;
  begin
    CalcOpenTimeBetween(oTime               => oTime
                      , oResourceCapacity   => lResourceCapacity
                      , oResourceCapQty     => lResourceCapQty
                      , iScheduleID_1       => iScheduleID_1
                      , iScheduleID_2       => iScheduleID_2
                      , iDate_1             => iDate_1
                      , iDate_2             => iDate_2
                      , iFilter_1           => iFilter_1
                      , iFilterID_1         => iFilterID_1
                      , iFilter_2           => iFilter_2
                      , iFilterID_2         => iFilterID_2
                       );
  end CalcOpenTimeBetween;

  /**
  * procedure CalcOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  */
  procedure CalcOpenTimeBetween(
    oTime             out    number
  , oResourceCapacity out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , oResourceCapQty   out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , iScheduleID_1     in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iScheduleID_2     in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , iDate_1           in     date
  , iDate_2           in     date
  , iFilter_1         in     varchar2 default null
  , iFilterID_1       in     number default null
  , iFilter_2         in     varchar2 default null
  , iFilterID_2       in     number default null
  )
  is
    type tSchedulePeriod is record(
      SCI_START_TIME      date
    , SCI_END_TIME        date
    , SCP_RESOURCE_NUMBER PAC_SCHEDULE_INTERRO.SCP_RESOURCE_NUMBER%type
    , SCP_PIECES_HOUR_CAP PAC_SCHEDULE_INTERRO.SCP_PIECES_HOUR_CAP%type
    );

    type ttSchedulePeriod is table of tSchedulePeriod;

    lttSchedule1    ttSchedulePeriod;
    lttSchedule2    ttSchedulePeriod;
    lCpt1           integer;
    lCpt2           integer;
    lDate1          date;
    lInterronumber1 PAC_SCHEDULE_INTERRO.SCI_INTERRO_NUMBER%type;
    lDate2          date;
    lInterronumber2 PAC_SCHEDULE_INTERRO.SCI_INTERRO_NUMBER%type;
  begin
    oTime              := 0;
    oResourceCapacity  := 0;
    oResourceCapQty    := 0;
    -- Enlever les secondes
    lDate1             := to_date(to_char(iDate_1, 'DD.MM.YYYY HH24:MI'), 'DD.MM.YYYY HH24:MI');
    lDate2             := to_date(to_char(iDate_2, 'DD.MM.YYYY HH24:MI'), 'DD.MM.YYYY HH24:MI');

    -- Numéro d'intérrogation
    select INIT_ID_SEQ.nextval
      into lInterronumber1
      from dual;

    -- Insertion des données dans la table PAC_SCHEDULE_INTERROGATION pour l'affichage d'un horaire.
    PrepareInterrogation(iScheduleID      => iScheduleID_1
                       , iDateFrom        => lDate1
                       , iDateTo          => lDate2
                       , iFilter          => iFilter_1
                       , iFilterID        => iFilterID_1
                       , iInterroNumber   => lInterronumber1
                        );

    -- Récuperer les périodes ouvertes de l'horaire
    select   greatest(SCI_START_TIME, lDate1)
           , least(SCI_END_TIME, lDate2)
           , SCP_RESOURCE_NUMBER
           , SCP_PIECES_HOUR_CAP
    bulk collect into lttSchedule1
        from PAC_SCHEDULE_INTERRO
       where SCI_INTERRO_NUMBER = lInterronumber1
         and SCP_NONWORKING_DAY = 0
         and SCI_END_TIME > lDate1
         and SCI_START_TIME < lDate2
    order by SCI_START_TIME;

    -- Effacer les données de la table d'interro
    delete from PAC_SCHEDULE_INTERRO
          where SCI_INTERRO_NUMBER = lInterronumber1;

    -- Si les données du 2eme horaire sont les memes que celles du 1er
    -- ne pas effectuer la construction de l'interro, utiliser l'interro de l'horaire 1
    if     (iScheduleID_1 = iScheduleID_2)
       and (nvl(iFilter_1, 'NULL') = nvl(iFilter_2, 'NULL') )
       and (nvl(iFilterID_1, -1) = nvl(iFilterID_2, -1) ) then
      lInterronumber2  := lInterronumber1;
      lttSchedule2     := lttSchedule1;
    else
      -- Numéro d'intérrogation
      select INIT_ID_SEQ.nextval
        into lInterronumber2
        from dual;

      -- Insertion des données dans la table PAC_SCHEDULE_INTERROGATION pour l'affichage d'un horaire.
      PrepareInterrogation(iScheduleID      => iScheduleID_2
                         , iDateFrom        => lDate1
                         , iDateTo          => lDate2
                         , iFilter          => iFilter_2
                         , iFilterID        => iFilterID_2
                         , iInterroNumber   => lInterronumber2
                          );

      -- Récuperer les périodes ouvertes de l'horaire
      select   greatest(SCI_START_TIME, lDate1)
             , least(SCI_END_TIME, lDate2)
             , SCP_RESOURCE_NUMBER
             , SCP_PIECES_HOUR_CAP
      bulk collect into lttSchedule2
          from PAC_SCHEDULE_INTERRO
         where SCI_INTERRO_NUMBER = lInterronumber2
           and SCP_NONWORKING_DAY = 0
           and SCI_END_TIME > lDate1
           and SCI_START_TIME < lDate2
      order by SCI_START_TIME;

      -- Effacer les données de la table d'interro
      delete from PAC_SCHEDULE_INTERRO
            where SCI_INTERRO_NUMBER = lInterronumber2;
    end if;

    -- Balayer les périodes du 1er horaire et effectuer la comparaison des heures d'ouverture avec le 2eme horaire
    if     (lttSchedule1.count > 0)
       and (lttSchedule2.count > 0) then
      declare
        lnDays                 integer;
        tmpTime                number(20, 5)                                      default 0;
        tmpTotalTime           number(20, 5)                                      default 0;
        boolCalcResources      boolean                                            default false;
        tmpFAC_RESOURCE_NUMBER FAL_FACTORY_FLOOR.FAC_RESOURCE_NUMBER%type;
        tmpFAC_PIECES_HOUR_CAP FAL_FACTORY_FLOOR.FAC_PIECES_HOUR_CAP%type;
        lResourceCapacity      PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type;
        lResourceCapQty        PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type;
        lFactfloorid1          FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type        := null;
      begin
        -- Init de l'id de l'atelier du filtre 1 (s'il s'agit d'un atelier)
        if     (upper(iFilter_1) = 'FACTORY_FLOOR')
           and (iFilterID_1 is not null) then
          lFactfloorid1  := iFilterID_1;
        end if;

        -- Vérifier si les capacités de l'atelier doivent être calculées
        if     (lFactfloorid1 is not null)
           and (    (iFilterID_1 = iFilterID_2)
                or (iFilterID_2 is null) ) then
          boolCalcResources  := true;

          select FAC_RESOURCE_NUMBER
               , FAC_PIECES_HOUR_CAP
            into tmpFAC_RESOURCE_NUMBER
               , tmpFAC_PIECES_HOUR_CAP
            from FAL_FACTORY_FLOOR
           where FAL_FACTORY_FLOOR_ID = lFactfloorid1;
        end if;

        for lCpt1 in lttSchedule1.first .. lttSchedule1.last loop
          for lCpt2 in lttSchedule2.first .. lttSchedule2.last loop
            if    (     (lttSchedule1(lCpt1).SCI_START_TIME >= lttSchedule2(lCpt2).SCI_START_TIME)
                   and (lttSchedule1(lCpt1).SCI_START_TIME < lttSchedule2(lCpt2).SCI_END_TIME)
                  )
               or (     (lttSchedule1(lCpt1).SCI_END_TIME > lttSchedule2(lCpt2).SCI_START_TIME)
                   and (lttSchedule1(lCpt1).SCI_END_TIME <= lttSchedule2(lCpt2).SCI_END_TIME)
                  )
               or (     (lttSchedule2(lCpt2).SCI_START_TIME > lttSchedule1(lCpt1).SCI_START_TIME)
                   and (lttSchedule2(lCpt2).SCI_START_TIME <= lttSchedule1(lCpt1).SCI_END_TIME)
                  )
               or (     (lttSchedule2(lCpt2).SCI_END_TIME > lttSchedule1(lCpt1).SCI_START_TIME)
                   and (lttSchedule2(lCpt2).SCI_END_TIME <= lttSchedule1(lCpt1).SCI_END_TIME)
                  ) then
              -- Adition des heures d'ouvertures simultanées des 2 horaires
              select least(lttSchedule1(lCpt1).SCI_END_TIME, lttSchedule2(lCpt2).SCI_END_TIME) -
                     greatest(lttSchedule1(lCpt1).SCI_START_TIME, lttSchedule2(lCpt2).SCI_START_TIME)
                into tmpTime
                from dual;

              tmpTotalTime  := tmpTotalTime + tmpTime;

              -- Calcul de la somme des capacités (Heures/Période) et (Qté/Période)
              if boolCalcResources then
                -- Le nbr de ressources est défini dans la période
                if lttSchedule1(lCpt1).SCP_RESOURCE_NUMBER is not null then
                  lResourceCapacity  := lttSchedule1(lCpt1).SCP_RESOURCE_NUMBER * round(tmpTime * 24, 2);
                  lResourceCapQty    := lResourceCapacity * lttSchedule1(lCpt1).SCP_PIECES_HOUR_CAP;
                else   -- Utiliser le nbr de ressources renseigné dans les données de l'atelier
                  lResourceCapacity  := tmpFAC_RESOURCE_NUMBER * round(tmpTime * 24, 2);
                  lResourceCapQty    := lResourceCapacity * tmpFAC_PIECES_HOUR_CAP;
                end if;

                oResourceCapacity  := oResourceCapacity + lResourceCapacity;
                oResourceCapQty    := oResourceCapQty + lResourceCapQty;
              end if;
            end if;
          end loop;
        end loop;

        -- Convertir le tmpTotalTime de type date en  numérique correspondant heures minutes au format 16.25 (ex pour 16H15)

        -- Nbr de jours
        lnDays  := floor(tmpTotalTime);

        select round( (tmpTotalTime - lnDays) * 24, 2) +(lnDays * 24)
          into oTime
          from dual;
      end;
    end if;
  exception
    when no_data_found then
      oTime              := -1;
      oResourceCapacity  := -1;
      oResourceCapQty    := -1;
  end CalcOpenTimeBetween;

  /**
  * procedure GetNextWorkingPeriod
  * Description
  *    Renvoi la prochaine/précedente/courante période ouverte selon une date/heure passée en param
  *      Si la date heure passée en param est dans une période active, on renvoi celle-ci
  *      Sinon on renvoi la prochaine/précedente période active selon le parametre iForward
  */
  procedure GetNextWorkingPeriod(
    oStartPeriod      out    date
  , oEndPeriod        out    date
  , oResourceNumber   out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_NUMBER%type
  , oResourceCapacity out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , oResourceCapQty   out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , iDateFrom         in     date
  , iScheduleID       in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type default null
  , iForward          in     integer default 1
  , iFilter           in     varchar2 default null
  , iFilterID         in     number default null
  )
  is
    lScheduleID    PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    lReturnDate    date;
    lnOpenWeekDays integer;
    lnCloseDates   integer;
    lnScheduleDays integer;
    lnCalcDays     integer;
    lSupplierID    PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type   default null;
    lFactFloorID   FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type         default null;
  begin
    -- Recherche l'ID de l'horaire par défaut si ID pas passé en param
    if iScheduleID is null then
      lScheduleID  := GetDefaultSchedule;
    else
      lScheduleID  := iScheduleID;
    end if;

    -- Aucun filtre sur les périodes de l'horaire
    if    (iFilter is null)
       or (iFilterID is null) then
      -- Rechercher le nb de jours ouvrés par semaine
      select 7 - count(*)
        into lnOpenWeekDays
        from PAC_SCHEDULE_PERIOD
       where PAC_SCHEDULE_ID = lScheduleID
         and PAC_CUSTOM_PARTNER_ID is null
         and PAC_SUPPLIER_PARTNER_ID is null
         and PAC_DEPARTMENT_ID is null
         and FAL_FACTORY_FLOOR_ID is null
         and HRM_PERSON_ID is null
         and HRM_DIVISION_ID is null
         and SCP_NONWORKING_DAY = 1
         and C_DAY_OF_WEEK is not null;

      -- Rechercher le nb de jours fermés (avec date) après la date demandée
      if iForward = 1 then
        select count(*)
          into lnCloseDates
          from PAC_SCHEDULE_PERIOD
         where PAC_SCHEDULE_ID = lScheduleID
           and PAC_CUSTOM_PARTNER_ID is null
           and PAC_SUPPLIER_PARTNER_ID is null
           and PAC_DEPARTMENT_ID is null
           and FAL_FACTORY_FLOOR_ID is null
           and HRM_PERSON_ID is null
           and HRM_DIVISION_ID is null
           and SCP_NONWORKING_DAY = 1
           and SCP_DATE is not null
           and SCP_DATE >= trunc(iDateFrom);
      else
        select count(*)
          into lnCloseDates
          from PAC_SCHEDULE_PERIOD
         where PAC_SCHEDULE_ID = lScheduleID
           and PAC_CUSTOM_PARTNER_ID is null
           and PAC_SUPPLIER_PARTNER_ID is null
           and PAC_DEPARTMENT_ID is null
           and FAL_FACTORY_FLOOR_ID is null
           and HRM_PERSON_ID is null
           and HRM_DIVISION_ID is null
           and SCP_NONWORKING_DAY = 1
           and SCP_DATE is not null
           and SCP_DATE <= trunc(iDateFrom);
      end if;

      -- Recherche le nbr de jours pour la construction du calendrier pour avoir le nbr de jours ouvrables
      -- nécessaires pour trouver la prochaine période
      lnScheduleDays  := (ceil(1 / lnOpenWeekDays) * 7) + lnCloseDates;

      -- Calcul de la date
      -- Explication sur la sous-requete "DAYS"
      --  trunc(iDateFrom) + (no * decode(iForward, 1, 1, -1) ) + decode(lnCalcDays, 0, decode(iForward, 1, -1, 1), 0) DAY_DATE
      --    (no * decode(iForward, 1, 1, -1) = créer des dates en avant ou en arrière selon le parametre iForward
      --    la partie après le + sert à intégrer la date passée en param si le nbr de jours à calculer = 0
      select START_PERIOD
           , END_PERIOD
           , SCP_RESOURCE_NUMBER
           , SCP_RESOURCE_CAPACITY
           , SCP_RESOURCE_CAP_IN_QTY
        into oStartPeriod
           , oEndPeriod
           , oResourceNumber
           , oResourceCapacity
           , oResourceCapQty
        from (select   INTERRO.PAC_SCHEDULE_PERIOD_ID
                     , INTERRO.DAY_DATE
                     , INTERRO.START_PERIOD
                     , INTERRO.END_PERIOD
                     , MAIN.SCP_RESOURCE_NUMBER
                     , MAIN.SCP_RESOURCE_CAPACITY
                     , MAIN.SCP_RESOURCE_CAP_IN_QTY
                  from PAC_SCHEDULE_PERIOD MAIN
                     , (select DAYS.DAY_DATE
                             , SCP.PAC_SCHEDULE_PERIOD_ID
                             , DAYS.DAY_DATE + SCP.SCP_OPEN_TIME START_PERIOD
                             , DAYS.DAY_DATE + SCP.SCP_CLOSE_TIME END_PERIOD
                          from PAC_SCHEDULE_PERIOD SCP
                             , (select   trunc(iDateFrom) +( (no - 1) * decode(iForward, 1, 1, -1) ) DAY_DATE
                                    from PCS.PC_NUMBER
                                   where no <= lnScheduleDays
                                order by no) DAYS
                         where SCP.PAC_SCHEDULE_ID = lScheduleID
                           and DAYS.DAY_DATE = SCP.SCP_DATE
                           and SCP.PAC_CUSTOM_PARTNER_ID is null
                           and SCP.PAC_SUPPLIER_PARTNER_ID is null
                           and SCP.PAC_DEPARTMENT_ID is null
                           and SCP.FAL_FACTORY_FLOOR_ID is null
                           and SCP.HRM_PERSON_ID is null
                           and SCP.HRM_DIVISION_ID is null
                        union
                        select DAYS.DAY_DATE
                             , SCP.PAC_SCHEDULE_PERIOD_ID
                             , DAYS.DAY_DATE + SCP.SCP_OPEN_TIME START_PERIOD
                             , DAYS.DAY_DATE + SCP.SCP_CLOSE_TIME END_PERIOD
                          from PAC_SCHEDULE_PERIOD SCP
                             , (select   trunc(iDateFrom) +( (no - 1) * decode(iForward, 1, 1, -1) ) DAY_DATE
                                    from PCS.PC_NUMBER
                                   where no <= lnScheduleDays
                                order by no) DAYS
                         where SCP.PAC_SCHEDULE_ID = lScheduleID
                           and SCP.PAC_CUSTOM_PARTNER_ID is null
                           and SCP.PAC_SUPPLIER_PARTNER_ID is null
                           and SCP.PAC_DEPARTMENT_ID is null
                           and SCP.FAL_FACTORY_FLOOR_ID is null
                           and SCP.HRM_PERSON_ID is null
                           and SCP.HRM_DIVISION_ID is null
                           and to_char(DAYS.DAY_DATE, 'DY') = SCP.C_DAY_OF_WEEK
                           and not exists(
                                 select SCP_DATE
                                   from PAC_SCHEDULE_PERIOD
                                  where PAC_SCHEDULE_ID = lScheduleID
                                    and SCP_DATE = DAYS.DAY_DATE
                                    and PAC_CUSTOM_PARTNER_ID is null
                                    and PAC_SUPPLIER_PARTNER_ID is null
                                    and PAC_DEPARTMENT_ID is null
                                    and FAL_FACTORY_FLOOR_ID is null
                                    and HRM_PERSON_ID is null
                                    and HRM_DIVISION_ID is null) ) INTERRO
                 where MAIN.PAC_SCHEDULE_PERIOD_ID = INTERRO.PAC_SCHEDULE_PERIOD_ID
                   and MAIN.SCP_NONWORKING_DAY = 0
              order by decode(iForward, 1, INTERRO.END_PERIOD, null) asc
                     , decode(iForward, 0, INTERRO.END_PERIOD, null) desc)
       where (    (    iForward = 1
                   and END_PERIOD > iDateFrom)
              or (    iForward = 0
                  and START_PERIOD < iDateFrom) )
         and rownum = 1;
    else
      -- Filtre Fournisseur/Atelier sur les périodes de l'horaire
      if iFilter = 'SUPPLIER' then
        lSupplierID  := iFilterID;
      elsif iFilter = 'FACTORY_FLOOR' then
        lFactFloorID  := iFilterID;
      else
        raise_application_error(-20005, 'Filtre invalide dans l''appel de la méthode "GetNextWorkingPeriod" !');
      end if;

      -- Rechercher le nb de jours ouvrés par semaine
      select 7 - NO_FILTER_DAYS.CLOSED_WEEK_DAYS - FILTER_DAYS.CLOSED_WEEK_DAYS
        into lnOpenWeekDays
        from (select count(*) CLOSED_WEEK_DAYS
                from PAC_SCHEDULE_PERIOD
               where PAC_SCHEDULE_ID = lScheduleID
                 and C_DAY_OF_WEEK is not null
                 and SCP_NONWORKING_DAY = 1
                 and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                 and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                 and PAC_CUSTOM_PARTNER_ID is null
                 and PAC_DEPARTMENT_ID is null
                 and HRM_PERSON_ID is null
                 and HRM_DIVISION_ID is null) FILTER_DAYS
           , (select count(*) CLOSED_WEEK_DAYS
                from PAC_SCHEDULE_PERIOD
               where PAC_SCHEDULE_ID = lScheduleID
                 and PAC_CUSTOM_PARTNER_ID is null
                 and PAC_SUPPLIER_PARTNER_ID is null
                 and PAC_DEPARTMENT_ID is null
                 and FAL_FACTORY_FLOOR_ID is null
                 and HRM_PERSON_ID is null
                 and HRM_DIVISION_ID is null
                 and SCP_NONWORKING_DAY = 1
                 and C_DAY_OF_WEEK is not null
                 and not exists(
                       select PAC_SCHEDULE_PERIOD_ID
                         from PAC_SCHEDULE_PERIOD
                        where PAC_SCHEDULE_ID = lScheduleID
                          and C_DAY_OF_WEEK is not null
                          and SCP_NONWORKING_DAY = 1
                          and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                          and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                          and PAC_CUSTOM_PARTNER_ID is null
                          and PAC_DEPARTMENT_ID is null
                          and HRM_PERSON_ID is null
                          and HRM_DIVISION_ID is null) ) NO_FILTER_DAYS;

      -- Rechercher le nb de jours fermés (avec date) après/avant la date demandée
      if iForward = 1 then
        select NO_FILTER_DAYS.CLOSED_DAYS + FILTER_DAYS.CLOSED_DAYS
          into lnCloseDates
          from (select count(*) CLOSED_DAYS
                  from PAC_SCHEDULE_PERIOD
                 where PAC_SCHEDULE_ID = lScheduleID
                   and SCP_DATE is not null
                   and SCP_DATE >= trunc(iDateFrom)
                   and SCP_NONWORKING_DAY = 1
                   and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                   and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                   and PAC_CUSTOM_PARTNER_ID is null
                   and PAC_DEPARTMENT_ID is null
                   and HRM_PERSON_ID is null
                   and HRM_DIVISION_ID is null) FILTER_DAYS
             , (select count(*) CLOSED_DAYS
                  from PAC_SCHEDULE_PERIOD
                 where PAC_SCHEDULE_ID = lScheduleID
                   and SCP_DATE is not null
                   and SCP_DATE >= trunc(iDateFrom)
                   and SCP_NONWORKING_DAY = 1
                   and PAC_CUSTOM_PARTNER_ID is null
                   and PAC_SUPPLIER_PARTNER_ID is null
                   and PAC_DEPARTMENT_ID is null
                   and FAL_FACTORY_FLOOR_ID is null
                   and HRM_PERSON_ID is null
                   and HRM_DIVISION_ID is null
                   and not exists(
                         select PAC_SCHEDULE_PERIOD_ID
                           from PAC_SCHEDULE_PERIOD
                          where PAC_SCHEDULE_ID = lScheduleID
                            and SCP_DATE is not null
                            and SCP_DATE >= trunc(iDateFrom)
                            and SCP_NONWORKING_DAY = 1
                            and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                            and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                            and PAC_CUSTOM_PARTNER_ID is null
                            and PAC_DEPARTMENT_ID is null
                            and HRM_PERSON_ID is null
                            and HRM_DIVISION_ID is null) ) no_FILTER_DAYS;
      else
        select NO_FILTER_DAYS.CLOSED_DAYS + FILTER_DAYS.CLOSED_DAYS
          into lnCloseDates
          from (select count(*) CLOSED_DAYS
                  from PAC_SCHEDULE_PERIOD
                 where PAC_SCHEDULE_ID = lScheduleID
                   and SCP_DATE is not null
                   and SCP_DATE <= trunc(iDateFrom)
                   and SCP_NONWORKING_DAY = 1
                   and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                   and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                   and PAC_CUSTOM_PARTNER_ID is null
                   and PAC_DEPARTMENT_ID is null
                   and HRM_PERSON_ID is null
                   and HRM_DIVISION_ID is null) FILTER_DAYS
             , (select count(*) CLOSED_DAYS
                  from PAC_SCHEDULE_PERIOD
                 where PAC_SCHEDULE_ID = lScheduleID
                   and SCP_DATE is not null
                   and SCP_DATE >= trunc(iDateFrom)
                   and SCP_NONWORKING_DAY = 1
                   and PAC_CUSTOM_PARTNER_ID is null
                   and PAC_SUPPLIER_PARTNER_ID is null
                   and PAC_DEPARTMENT_ID is null
                   and FAL_FACTORY_FLOOR_ID is null
                   and HRM_PERSON_ID is null
                   and HRM_DIVISION_ID is null
                   and not exists(
                         select PAC_SCHEDULE_PERIOD_ID
                           from PAC_SCHEDULE_PERIOD
                          where PAC_SCHEDULE_ID = lScheduleID
                            and SCP_DATE is not null
                            and SCP_DATE <= trunc(iDateFrom)
                            and SCP_NONWORKING_DAY = 1
                            and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                            and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                            and PAC_CUSTOM_PARTNER_ID is null
                            and PAC_DEPARTMENT_ID is null
                            and HRM_PERSON_ID is null
                            and HRM_DIVISION_ID is null) ) no_FILTER_DAYS;
      end if;

      -- Recherche le nbr de jours pour la construction du calendrier pour avoir le nbr de jours ouvrables
      -- nécessaires pour calculer le décalage
      lnScheduleDays  := (ceil(1 / lnOpenWeekDays) * 7) + lnCloseDates;

      -- Calcul de la date
      -- Explication sur la sous-requete "DAYS"
      --  trunc(iDateFrom) + (no * decode(iForward, 1, 1, -1) ) + decode(lnCalcDays, 0, decode(iForward, 1, -1, 1), 0) DAY_DATE
      --    (no * decode(iForward, 1, 1, -1) = créer des dates en avant ou en arrière selon le parametre iForward
      --    la partie après le + sert à intégrer la date passée en param si le nbr de jours à calculer = 0
      select START_PERIOD
           , END_PERIOD
           , SCP_RESOURCE_NUMBER
           , SCP_RESOURCE_CAPACITY
           , SCP_RESOURCE_CAP_IN_QTY
        into oStartPeriod
           , oEndPeriod
           , oResourceNumber
           , oResourceCapacity
           , oResourceCapQty
        from (select   INTERRO.PAC_SCHEDULE_PERIOD_ID
                     , INTERRO.DAY_DATE
                     , INTERRO.START_PERIOD
                     , INTERRO.END_PERIOD
                     , MAIN.SCP_RESOURCE_NUMBER
                     , MAIN.SCP_RESOURCE_CAPACITY
                     , MAIN.SCP_RESOURCE_CAP_IN_QTY
                  from PAC_SCHEDULE_PERIOD MAIN
                     , (
                        -- Liste des dates qui sont uniquement liées au filtre
                        select DAYS.DAY_DATE
                             , SCP.PAC_SCHEDULE_PERIOD_ID
                             , DAYS.DAY_DATE + SCP.SCP_OPEN_TIME START_PERIOD
                             , DAYS.DAY_DATE + SCP.SCP_CLOSE_TIME END_PERIOD
                          from PAC_SCHEDULE_PERIOD SCP
                             , (select   trunc(iDateFrom) +( (no - 1) * decode(iForward, 1, 1, -1) ) DAY_DATE
                                    from PCS.PC_NUMBER
                                   where no <= lnScheduleDays
                                order by no) DAYS
                         where SCP.PAC_SCHEDULE_ID = lScheduleID
                           and DAYS.DAY_DATE = SCP.SCP_DATE
                           and nvl(SCP.PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                           and nvl(SCP.FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                           and SCP.PAC_CUSTOM_PARTNER_ID is null
                           and SCP.PAC_DEPARTMENT_ID is null
                           and SCP.HRM_PERSON_ID is null
                           and SCP.HRM_DIVISION_ID is null
                        -- Liste des dates qui ne sont pas liées au filtre
                        union
                        select DAYS.DAY_DATE
                             , SCP.PAC_SCHEDULE_PERIOD_ID
                             , DAYS.DAY_DATE + SCP.SCP_OPEN_TIME START_PERIOD
                             , DAYS.DAY_DATE + SCP.SCP_CLOSE_TIME END_PERIOD
                          from PAC_SCHEDULE_PERIOD SCP
                             , (select   trunc(iDateFrom) +( (no - 1) * decode(iForward, 1, 1, -1) ) DAY_DATE
                                    from PCS.PC_NUMBER
                                   where no <= lnScheduleDays
                                order by no) DAYS
                         where SCP.PAC_SCHEDULE_ID = lScheduleID
                           and DAYS.DAY_DATE = SCP.SCP_DATE
                           and SCP.PAC_CUSTOM_PARTNER_ID is null
                           and SCP.PAC_SUPPLIER_PARTNER_ID is null
                           and SCP.PAC_DEPARTMENT_ID is null
                           and SCP.FAL_FACTORY_FLOOR_ID is null
                           and SCP.HRM_PERSON_ID is null
                           and SCP.HRM_DIVISION_ID is null
                           and not exists(
                                 select SCP_DATE
                                   from PAC_SCHEDULE_PERIOD
                                  where PAC_SCHEDULE_ID = lScheduleID
                                    and SCP_DATE = DAYS.DAY_DATE
                                    and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                                    and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                                    and PAC_CUSTOM_PARTNER_ID is null
                                    and PAC_DEPARTMENT_ID is null
                                    and HRM_PERSON_ID is null
                                    and HRM_DIVISION_ID is null)
                        -- Liste des jours qui sont uniquement liés au filtre
                        union
                        select DAYS.DAY_DATE
                             , SCP.PAC_SCHEDULE_PERIOD_ID
                             , DAYS.DAY_DATE + SCP.SCP_OPEN_TIME START_PERIOD
                             , DAYS.DAY_DATE + SCP.SCP_CLOSE_TIME END_PERIOD
                          from PAC_SCHEDULE_PERIOD SCP
                             , (select   trunc(iDateFrom) +( (no - 1) * decode(iForward, 1, 1, -1) ) DAY_DATE
                                    from PCS.PC_NUMBER
                                   where no <= lnScheduleDays
                                order by no) DAYS
                         where SCP.PAC_SCHEDULE_ID = lScheduleID
                           and nvl(SCP.PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                           and nvl(SCP.FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                           and SCP.PAC_CUSTOM_PARTNER_ID is null
                           and SCP.PAC_DEPARTMENT_ID is null
                           and SCP.HRM_PERSON_ID is null
                           and SCP.HRM_DIVISION_ID is null
                           and to_char(DAYS.DAY_DATE, 'DY') = SCP.C_DAY_OF_WEEK
                           and not exists(
                                 select SCP_DATE
                                   from PAC_SCHEDULE_PERIOD
                                  where PAC_SCHEDULE_ID = lScheduleID
                                    and SCP_DATE = DAYS.DAY_DATE
                                    and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                                    and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                                    and PAC_CUSTOM_PARTNER_ID is null
                                    and PAC_DEPARTMENT_ID is null
                                    and HRM_PERSON_ID is null
                                    and HRM_DIVISION_ID is null)
                           and not exists(
                                 select SCP_DATE
                                   from PAC_SCHEDULE_PERIOD
                                  where PAC_SCHEDULE_ID = lScheduleID
                                    and SCP_DATE = DAYS.DAY_DATE
                                    and PAC_CUSTOM_PARTNER_ID is null
                                    and PAC_SUPPLIER_PARTNER_ID is null
                                    and PAC_DEPARTMENT_ID is null
                                    and FAL_FACTORY_FLOOR_ID is null
                                    and HRM_PERSON_ID is null
                                    and HRM_DIVISION_ID is null)
                        -- Liste des jours qui ne sont pas liés au filtre
                        union
                        select DAYS.DAY_DATE
                             , SCP.PAC_SCHEDULE_PERIOD_ID
                             , DAYS.DAY_DATE + SCP.SCP_OPEN_TIME START_PERIOD
                             , DAYS.DAY_DATE + SCP.SCP_CLOSE_TIME END_PERIOD
                          from PAC_SCHEDULE_PERIOD SCP
                             , (select   trunc(iDateFrom) +( (no - 1) * decode(iForward, 1, 1, -1) ) DAY_DATE
                                    from PCS.PC_NUMBER
                                   where no <= lnScheduleDays
                                order by no) DAYS
                         where SCP.PAC_SCHEDULE_ID = lScheduleID
                           and SCP.PAC_CUSTOM_PARTNER_ID is null
                           and SCP.PAC_SUPPLIER_PARTNER_ID is null
                           and SCP.PAC_DEPARTMENT_ID is null
                           and SCP.FAL_FACTORY_FLOOR_ID is null
                           and SCP.HRM_PERSON_ID is null
                           and SCP.HRM_DIVISION_ID is null
                           and to_char(DAYS.DAY_DATE, 'DY') = SCP.C_DAY_OF_WEEK
                           and not exists(
                                 select SCP_DATE
                                   from PAC_SCHEDULE_PERIOD
                                  where PAC_SCHEDULE_ID = lScheduleID
                                    and SCP_DATE = DAYS.DAY_DATE
                                    and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                                    and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                                    and PAC_CUSTOM_PARTNER_ID is null
                                    and PAC_DEPARTMENT_ID is null
                                    and HRM_PERSON_ID is null
                                    and HRM_DIVISION_ID is null)
                           and not exists(
                                 select SCP_DATE
                                   from PAC_SCHEDULE_PERIOD
                                  where PAC_SCHEDULE_ID = lScheduleID
                                    and SCP_DATE = DAYS.DAY_DATE
                                    and PAC_CUSTOM_PARTNER_ID is null
                                    and PAC_SUPPLIER_PARTNER_ID is null
                                    and PAC_DEPARTMENT_ID is null
                                    and FAL_FACTORY_FLOOR_ID is null
                                    and HRM_PERSON_ID is null
                                    and HRM_DIVISION_ID is null)
                           and not exists(
                                 select SCP_DATE
                                   from PAC_SCHEDULE_PERIOD
                                  where PAC_SCHEDULE_ID = lScheduleID
                                    and C_DAY_OF_WEEK = SCP.C_DAY_OF_WEEK
                                    and nvl(PAC_SUPPLIER_PARTNER_ID, -1) = nvl(lSupplierID, -1)
                                    and nvl(FAL_FACTORY_FLOOR_ID, -1) = nvl(lFactFloorID, -1)
                                    and PAC_CUSTOM_PARTNER_ID is null
                                    and PAC_DEPARTMENT_ID is null
                                    and HRM_PERSON_ID is null
                                    and HRM_DIVISION_ID is null) ) INTERRO
                 where MAIN.PAC_SCHEDULE_PERIOD_ID = INTERRO.PAC_SCHEDULE_PERIOD_ID
                   and MAIN.SCP_NONWORKING_DAY = 0
              order by decode(iForward, 1, INTERRO.END_PERIOD, null) asc
                     , decode(iForward, 0, INTERRO.END_PERIOD, null) desc)
       where (    (    iForward = 1
                   and END_PERIOD > iDateFrom)
              or (    iForward = 0
                  and START_PERIOD < iDateFrom) )
         and rownum = 1;

      -- Un atelier a été passé comme filtre, mais la prochaine/precedente période trouvée n'a pas les infos des ressources
      if     (lFactFloorID is not null)
         and (oResourceNumber is null) then
        begin
          select FAC_RESOURCE_NUMBER
               , FAC_RESOURCE_NUMBER * round( (oEndPeriod - oStartPeriod) * 24, 2)
               , FAC_RESOURCE_NUMBER * round( (oEndPeriod - oStartPeriod) * 24, 2) * FAC_PIECES_HOUR_CAP
            into oResourceNumber
               , oResourceCapacity
               , oResourceCapQty
            from FAL_FACTORY_FLOOR
           where FAL_FACTORY_FLOOR_ID = lFactFloorID;
        exception
          when no_data_found then
            oResourceNumber    := 0;
            oResourceCapacity  := 0;
            oResourceCapQty    := 0;
        end;
      end if;
    end if;
  exception
    when no_data_found then
      oStartPeriod       := null;
      oEndPeriod         := null;
      oResourceNumber    := -1;
      oResourceCapacity  := -1;
      oResourceCapQty    := -1;
  end GetNextWorkingPeriod;

  /**
  * function GetOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  *    avec une transaction autonome pour que cette fonction puisse être utilisée dans un SELECT
  */
  function GetOpenTimeBetween(
    iDate_1       in date
  , iDate_2       in date
  , iScheduleID_1 in PAC_SCHEDULE.PAC_SCHEDULE_ID%type default null
  , iScheduleID_2 in PAC_SCHEDULE.PAC_SCHEDULE_ID%type default null
  , iFilter_1     in varchar2 default null
  , iFilterID_1   in number default null
  , iFilter_2     in varchar2 default null
  , iFilterID_2   in number default null
  )
    return number
  is
    pragma autonomous_transaction;
    lScheduleID_1     PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    lScheduleID_2     PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    lTime             number(20, 5);
    lResourceCapacity PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type;
    lResourceCapQty   PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type;
  begin
    -- Vérifier si l'ID de l'horaire 1 a été passé
    if iScheduleID_1 is not null then
      lScheduleID_1  := iScheduleID_1;
    else
      lScheduleID_1  := GetDefaultSchedule;
    end if;

    -- Init de l'ID de l'horaire 2
    lScheduleID_2  := nvl(iScheduleID_2, lScheduleID_1);
    -- Effectuer le calcul de l'intervale entre les deux dates
    CalcOpenTimeBetween(oTime               => lTime
                      , oResourceCapacity   => lResourceCapacity
                      , oResourceCapQty     => lResourceCapQty
                      , iScheduleID_1       => lScheduleID_1
                      , iScheduleID_2       => lScheduleID_2
                      , iDate_1             => iDate_1
                      , iDate_2             => iDate_2
                      , iFilter_1           => iFilter_1
                      , iFilterID_1         => iFilterID_1
                      , iFilter_2           => iFilter_2
                      , iFilterID_2         => iFilterID_2
                       );
    commit;
    return lTime;
  end GetOpenTimeBetween;

  /**
  *  function DisplayPeriodText
  *  Description
  *    Création du texte à afficher pour une période en concatenant divers champs
  */
  function DisplayPeriodText(iInterroID in PAC_SCHEDULE_INTERRO.PAC_SCHEDULE_INTERRO_ID%type)
    return varchar2
  is
    lComment varchar2(4000);
  begin
    select decode(SCP.SCP_NONWORKING_DAY, 1, PCS.PC_FUNCTIONS.TranslateWord('Jour non ouvré') || co.cLineBreak, null) ||
           decode(SCP.PAC_CUSTOM_PARTNER_ID, null, null, PCS.PC_FUNCTIONS.TranslateWord('Client') || ' : ' || SCI.PER_NAME || co.cLineBreak) ||
           decode(SCP.PAC_SUPPLIER_PARTNER_ID, null, null, PCS.PC_FUNCTIONS.TranslateWord('Fournisseur') || ' : ' || SCI.PER_NAME || co.cLineBreak) ||
           decode(SCP.PAC_DEPARTMENT_ID
                , null, null
                , PCS.PC_FUNCTIONS.TranslateWord('Département') ||
                  ' : ' ||
                  SCI.DEP_KEY ||
                  co.cLineBreak ||
                  PCS.PC_FUNCTIONS.TranslateWord('Personne') ||
                  ' : ' ||
                  SCI.PER_NAME ||
                  co.cLineBreak
                 ) ||
           decode(SCP.FAL_FACTORY_FLOOR_ID
                , null, null
                , PCS.PC_FUNCTIONS.TranslateWord('Atelier') ||
                  ' : ' ||
                  SCI.FAC_REFERENCE ||
                  co.cLineBreak ||
                  PCS.PC_FUNCTIONS.TranslateWord('Nbr ressources') ||
                  ' : ' ||
                  SCP.SCP_RESOURCE_NUMBER ||
                  co.cLineBreak ||
                  PCS.PC_FUNCTIONS.TranslateWord('Capacité') ||
                  co.cLineBreak ||
                  PCS.PC_FUNCTIONS.TranslateWord('Heures / Période') ||
                  ' : ' ||
                  SCP.SCP_RESOURCE_CAPACITY ||
                  co.cLineBreak ||
                  PCS.PC_FUNCTIONS.TranslateWord('Qté / Période') ||
                  ' : ' ||
                  SCP.SCP_RESOURCE_CAP_IN_QTY ||
                  co.cLineBreak
                 ) ||
           decode(SCI.HRM_PERSON_ID, null, null, PCS.PC_FUNCTIONS.TranslateWord('Personne') || ' : ' || SCI.PER_FULLNAME || co.cLineBreak) ||
           decode(SCI.HRM_DIVISION_ID, null, null, PCS.PC_FUNCTIONS.TranslateWord('Département') || ' : ' || SCI.DIV_DESCR || co.cLineBreak) ||
           decode(SCI.DIC_SCH_PERIOD_1_ID, null, null, DIT_1.DIT_DESCR || co.cLineBreak) ||
           decode(SCI.DIC_SCH_PERIOD_2_ID, null, null, DIT_2.DIT_DESCR || co.cLineBreak) ||
           SCP.SCP_COMMENT DISPLAY_TEXT
      into lComment
      from PAC_SCHEDULE_PERIOD SCP
         , PAC_SCHEDULE_INTERRO SCI
         , DICO_DESCRIPTION DIT_1
         , DICO_DESCRIPTION DIT_2
     where SCI.PAC_SCHEDULE_INTERRO_ID = iInterroID
       and SCI.PAC_SCHEDULE_PERIOD_ID = SCP.PAC_SCHEDULE_PERIOD_ID
       and SCI.DIC_SCH_PERIOD_1_ID = DIT_1.DIT_CODE(+)
       and DIT_1.DIT_TABLE(+) = 'DIC_SCH_PERIOD_1'
       and DIT_1.PC_LANG_ID(+) = pcs.PC_I_LIB_SESSION.GetUserLangId
       and SCI.DIC_SCH_PERIOD_2_ID = DIT_2.DIT_CODE(+)
       and DIT_2.DIT_TABLE(+) = 'DIC_SCH_PERIOD_2'
       and DIT_2.PC_LANG_ID(+) = pcs.PC_I_LIB_SESSION.GetUserLangId;

    return lComment;
  exception
    when no_data_found then
      return null;
  end DisplayPeriodText;

  /**
  * Description
  *    Retourne la date + le décalage ou le prochain jour ouvrable si date + décalage
  *    tombe sur un jour non ouvré.
  */
  function getGivenMoreDaysNextOpenDate(
    idDate       in date
  , inDecalage   in number
  , inScheduleID in PAC_SCHEDULE.PAC_SCHEDULE_ID%type default null
  , ivFilter     in varchar2 default null
  , inFilterID   in number default null
  )
    return date
  as
    lnDate date;
  begin
    lnDate  := idDate + inDecalage;

    while PAC_LIB_SCHEDULE.IsOpenDay(iScheduleID => inScheduleID, iDate => lnDate, iFilter => ivFilter, iFilterID => inFilterID) <> 1 loop
      lnDate  := getGivenMoreDaysNextOpenDate(idDate => lnDate, inDecalage => 1, inScheduleID => inScheduleID, ivFilter => ivFilter, inFilterID => inFilterID);
    end loop;

    return lnDate;
  end getGivenMoreDaysNextOpenDate;
end PAC_LIB_SCHEDULE;
