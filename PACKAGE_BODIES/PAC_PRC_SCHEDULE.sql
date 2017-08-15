--------------------------------------------------------
--  DDL for Package Body PAC_PRC_SCHEDULE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_PRC_SCHEDULE" 
is
  /**
  *  procedure InsertSchedulePeriod
  *  Description
  *    Création d'une période pour un horaire
  */
  procedure InsertSchedulePeriod(
    iScheduleID       in     PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_ID%type
  , iDate             in     PAC_SCHEDULE_PERIOD.SCP_DATE%type
  , iDayOfWeek        in     PAC_SCHEDULE_PERIOD.C_DAY_OF_WEEK%type
  , iNonWorkingDay    in     PAC_SCHEDULE_PERIOD.SCP_NONWORKING_DAY%type
  , iStartTime        in     varchar2
  , iEndTime          in     varchar2
  , iComment          in     PAC_SCHEDULE_PERIOD.SCP_COMMENT%type
  , iFilter           in     varchar2
  , iFilterID         in     number
  , iResourceNumber   in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_NUMBER%type
  , iResourceCapacity in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , iResourceCapQty   in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , iPiecesHourCap    in     PAC_SCHEDULE_PERIOD.SCP_PIECES_HOUR_CAP%type
  , iDicSchPeriod1    in     PAC_SCHEDULE_PERIOD.DIC_SCH_PERIOD_1_ID%type
  , iDicSchPeriod2    in     PAC_SCHEDULE_PERIOD.DIC_SCH_PERIOD_2_ID%type
  , oErrorPeriodID    out    PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  )
  is
    lStartTime      PAC_SCHEDULE_PERIOD.SCP_OPEN_TIME%type    default 0.0;
    lEndTime        PAC_SCHEDULE_PERIOD.SCP_CLOSE_TIME%type   default 0.0;
    lDate           date;
    lScheduleFilter PAC_LIB_SCHEDULE.TScheduleFilter;
  begin
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

    select decode(iDayOfWeek, null, trunc(iDate), null)
      into lDate
      from dual;

    -- Vérifier si la période que l'on va créer ne chevauche pas une période existante selon les règles suivantes
    -- Deux tranches horaires ne peuvent pas se chevaucher pour un même jour de semaine, une même date, un même
    -- client, fournisseur, atelier ou personne
    PAC_I_LIB_SCHEDULE.CheckSchedulePeriod(iPeriodID        => null
                                         , iScheduleID      => iScheduleID
                                         , iDate            => lDate
                                         , iDayOfWeek       => iDayOfWeek
                                         , iNonWorkingDay   => iNonWorkingDay
                                         , iStartTime       => lStartTime
                                         , iEndTime         => lEndTime
                                         , iFilter          => iFilter
                                         , iFilterID        => iFilterID
                                         , oErrorPeriodID   => oErrorPeriodID
                                          );

    if oErrorPeriodID is null then
      -- Initialise la variable de retour avec l'id du filtre passé en param
      PAC_I_LIB_SCHEDULE.InitScheduleFilter(iFilter => iFilter, iFilterID => iFilterID, oScheduleFilter => lScheduleFilter);

      insert into PAC_SCHEDULE_PERIOD
                  (PAC_SCHEDULE_PERIOD_ID
                 , PAC_SCHEDULE_ID
                 , C_DAY_OF_WEEK
                 , SCP_DATE
                 , SCP_NONWORKING_DAY
                 , SCP_OPEN_TIME
                 , SCP_CLOSE_TIME
                 , SCP_COMMENT
                 , PAC_CUSTOM_PARTNER_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , PAC_DEPARTMENT_ID
                 , FAL_FACTORY_FLOOR_ID
                 , HRM_PERSON_ID
                 , HRM_DIVISION_ID
                 , SCP_RESOURCE_NUMBER
                 , SCP_RESOURCE_CAPACITY
                 , SCP_RESOURCE_CAP_IN_QTY
                 , SCP_PIECES_HOUR_CAP
                 , DIC_SCH_PERIOD_1_ID
                 , DIC_SCH_PERIOD_2_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , iScheduleID
             , iDayOfWeek
             , lDate
             , iNonWorkingDay
             , decode(iNonWorkingDay, 0, lStartTime, null)
             , decode(iNonWorkingDay, 0, lEndTime, null)
             , iComment
             , lScheduleFilter.PAC_CUSTOM_PARTNER_ID
             , lScheduleFilter.PAC_SUPPLIER_PARTNER_ID
             , lScheduleFilter.PAC_DEPARTMENT_ID
             , lScheduleFilter.FAL_FACTORY_FLOOR_ID
             , lScheduleFilter.HRM_PERSON_ID
             , lScheduleFilter.HRM_DIVISION_ID
             , decode(lScheduleFilter.FAL_FACTORY_FLOOR_ID, null, null, iResourceNumber)
             , decode(lScheduleFilter.FAL_FACTORY_FLOOR_ID, null, null, iResourceCapacity)
             , decode(lScheduleFilter.FAL_FACTORY_FLOOR_ID, null, null, iResourceCapQty)
             , decode(lScheduleFilter.FAL_FACTORY_FLOOR_ID, null, null, iPiecesHourCap)
             , iDicSchPeriod1
             , iDicSchPeriod2
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from dual;
    end if;
  end InsertSchedulePeriod;

  /**
  *  procedure UpdateSchedulePeriod
  *  Description
  *    Mise à jour d'une période d'un horaire
  */
  procedure UpdateSchedulePeriod(
    iPeriodID         in     PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  , iDate             in     PAC_SCHEDULE_PERIOD.SCP_DATE%type
  , iDayOfWeek        in     PAC_SCHEDULE_PERIOD.C_DAY_OF_WEEK%type
  , iNonWorkingDay    in     PAC_SCHEDULE_PERIOD.SCP_NONWORKING_DAY%type
  , iStartTime        in     varchar2
  , iEndTime          in     varchar2
  , iComment          in     PAC_SCHEDULE_PERIOD.SCP_COMMENT%type
  , iFilter           in     varchar2
  , iFilterID         in     number
  , iResourceNumber   in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_NUMBER%type
  , iResourceCapacity in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , iResourceCapQty   in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , iPiecesHourCap    in     PAC_SCHEDULE_PERIOD.SCP_PIECES_HOUR_CAP%type
  , iDicSchPeriod1    in     PAC_SCHEDULE_PERIOD.DIC_SCH_PERIOD_1_ID%type
  , iDicSchPeriod2    in     PAC_SCHEDULE_PERIOD.DIC_SCH_PERIOD_2_ID%type
  , oErrorPeriodID    out    PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  )
  is
    lScheduleID     PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    lStartTime      PAC_SCHEDULE_PERIOD.SCP_OPEN_TIME%type;
    lEndTime        PAC_SCHEDULE_PERIOD.SCP_CLOSE_TIME%type;
    lDate           date;
    lScheduleFilter PAC_LIB_SCHEDULE.TScheduleFilter;
  begin
    select round(to_date(iStartTime, 'HH24:MI') - to_date('00:00', 'HH24:MI'), 5)
         , round(to_date(iEndTime, 'HH24:MI') - to_date('00:00', 'HH24:MI'), 5)
         , PAC_SCHEDULE_ID
         , decode(iDayOfWeek, null, trunc(iDate), null)
      into lStartTime
         , lEndTime
         , lScheduleID
         , lDate
      from PAC_SCHEDULE_PERIOD
     where PAC_SCHEDULE_PERIOD_ID = iPeriodID;

    -- Vérifier si la période que l'on va modifier ne chevauche pas une période existante selon les règles suivantes
    -- Deux tranches horaires ne peuvent pas se chevaucher pour un même jour de semaine, une même date, un même
    -- client, fournisseur, atelier ou personne
    PAC_I_LIB_SCHEDULE.CheckSchedulePeriod(iPeriodID        => iPeriodID
                                         , iScheduleID      => lScheduleID
                                         , iDate            => lDate
                                         , iDayOfWeek       => iDayOfWeek
                                         , iNonWorkingDay   => iNonWorkingDay
                                         , iStartTime       => lStartTime
                                         , iEndTime         => lEndTime
                                         , iFilter          => iFilter
                                         , iFilterID        => iFilterID
                                         , oErrorPeriodID   => oErrorPeriodID
                                          );

    if oErrorPeriodID is null then
      -- Initialise la variable de retour avec l'id du filtre passé en param
      PAC_I_LIB_SCHEDULE.InitScheduleFilter(iFilter => iFilter, iFilterID => iFilterID, oScheduleFilter => lScheduleFilter);

      update PAC_SCHEDULE_PERIOD
         set SCP_DATE = lDate
           , C_DAY_OF_WEEK = iDayOfWeek
           , SCP_NONWORKING_DAY = iNonWorkingDay
           , SCP_OPEN_TIME = decode(iNonWorkingDay, 1, null, lStartTime)
           , SCP_CLOSE_TIME = decode(iNonWorkingDay, 1, null, lEndTime)
           , SCP_COMMENT = iComment
           , PAC_CUSTOM_PARTNER_ID = lScheduleFilter.PAC_CUSTOM_PARTNER_ID
           , PAC_SUPPLIER_PARTNER_ID = lScheduleFilter.PAC_SUPPLIER_PARTNER_ID
           , PAC_DEPARTMENT_ID = lScheduleFilter.PAC_DEPARTMENT_ID
           , FAL_FACTORY_FLOOR_ID = lScheduleFilter.FAL_FACTORY_FLOOR_ID
           , HRM_PERSON_ID = lScheduleFilter.HRM_PERSON_ID
           , HRM_DIVISION_ID = lScheduleFilter.HRM_DIVISION_ID
           , SCP_RESOURCE_NUMBER = decode(lScheduleFilter.FAL_FACTORY_FLOOR_ID, null, null, iResourceNumber)
           , SCP_RESOURCE_CAPACITY = decode(lScheduleFilter.FAL_FACTORY_FLOOR_ID, null, null, iResourceCapacity)
           , SCP_RESOURCE_CAP_IN_QTY = decode(lScheduleFilter.FAL_FACTORY_FLOOR_ID, null, null, iResourceCapQty)
           , SCP_PIECES_HOUR_CAP = decode(lScheduleFilter.FAL_FACTORY_FLOOR_ID, null, null, iPiecesHourCap)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , DIC_SCH_PERIOD_1_ID = iDicSchPeriod1
           , DIC_SCH_PERIOD_2_ID = iDicSchPeriod2
       where PAC_SCHEDULE_PERIOD_ID = iPeriodID;
    end if;
  end;
end PAC_PRC_SCHEDULE;
