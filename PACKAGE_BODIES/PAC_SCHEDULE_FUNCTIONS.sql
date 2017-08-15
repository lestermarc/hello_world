--------------------------------------------------------
--  DDL for Package Body PAC_SCHEDULE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_SCHEDULE_FUNCTIONS" 
is
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
  begin
    PAC_LIB_SCHEDULE.PrepareInterrogation(iScheduleID      => iScheduleID
                                        , iDateFrom        => iDateFrom
                                        , iDateTo          => iDateTo
                                        , iStartTime       => iStartTime
                                        , iEndTime         => iEndTime
                                        , iFilter          => iFilter
                                        , iFilterID        => iFilterID
                                        , iInterroNumber   => iInterroNumber
                                         );
  end PrepareInterrogation;

  /**
  *  procedure InsertSchedulePeriod
  *  Description
  *    Création d'une période pour un horaire
  */
  procedure InsertSchedulePeriod(
    aScheduleID       in     PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_ID%type
  , aDate             in     PAC_SCHEDULE_PERIOD.SCP_DATE%type
  , aDayOfWeek        in     PAC_SCHEDULE_PERIOD.C_DAY_OF_WEEK%type
  , aNonWorkingDay    in     PAC_SCHEDULE_PERIOD.SCP_NONWORKING_DAY%type
  , aStartTime        in     varchar2
  , aEndTime          in     varchar2
  , aComment          in     PAC_SCHEDULE_PERIOD.SCP_COMMENT%type
  , iFilter           in     varchar2
  , iFilterID         in     number
  , aResourceNumber   in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_NUMBER%type
  , aResourceCapacity in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , aResourceCapQty   in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , aPiecesHourCap    in     PAC_SCHEDULE_PERIOD.SCP_PIECES_HOUR_CAP%type
  , aDicSchPeriod1    in     PAC_SCHEDULE_PERIOD.DIC_SCH_PERIOD_1_ID%type
  , aDicSchPeriod2    in     PAC_SCHEDULE_PERIOD.DIC_SCH_PERIOD_2_ID%type
  , aErrorPeriodID    out    PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  )
  is
  begin
    PAC_PRC_SCHEDULE.InsertSchedulePeriod(iScheduleID         => aScheduleID
                                        , iDate               => aDate
                                        , iDayOfWeek          => aDayOfWeek
                                        , iNonWorkingDay      => aNonWorkingDay
                                        , iStartTime          => aStartTime
                                        , iEndTime            => aEndTime
                                        , iComment            => aComment
                                        , iFilter             => iFilter
                                        , iFilterID           => iFilterID
                                        , iResourceNumber     => aResourceNumber
                                        , iResourceCapacity   => aResourceCapacity
                                        , iResourceCapQty     => aResourceCapQty
                                        , iPiecesHourCap      => aPiecesHourCap
                                        , iDicSchPeriod1      => aDicSchPeriod1
                                        , iDicSchPeriod2      => aDicSchPeriod2
                                        , oErrorPeriodID      => aErrorPeriodID
                                         );
  end InsertSchedulePeriod;

  /**
  *  procedure UpdateSchedulePeriod
  *  Description
  *    Création d'une période d'un horaire
  */
  procedure UpdateSchedulePeriod(
    aPeriodID         in     PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  , aDate             in     PAC_SCHEDULE_PERIOD.SCP_DATE%type
  , aDayOfWeek        in     PAC_SCHEDULE_PERIOD.C_DAY_OF_WEEK%type
  , aNonWorkingDay    in     PAC_SCHEDULE_PERIOD.SCP_NONWORKING_DAY%type
  , aStartTime        in     varchar2
  , aEndTime          in     varchar2
  , aComment          in     PAC_SCHEDULE_PERIOD.SCP_COMMENT%type
  , iFilter           in     varchar2
  , iFilterID         in     number
  , aResourceNumber   in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_NUMBER%type
  , aResourceCapacity in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , aResourceCapQty   in     PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , aPiecesHourCap    in     PAC_SCHEDULE_PERIOD.SCP_PIECES_HOUR_CAP%type
  , aDicSchPeriod1    in     PAC_SCHEDULE_PERIOD.DIC_SCH_PERIOD_1_ID%type
  , aDicSchPeriod2    in     PAC_SCHEDULE_PERIOD.DIC_SCH_PERIOD_2_ID%type
  , aErrorPeriodID    out    PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  )
  is
  begin
    PAC_PRC_SCHEDULE.UpdateSchedulePeriod(iPeriodID           => aPeriodID
                                        , iDate               => aDate
                                        , iDayOfWeek          => aDayOfWeek
                                        , iNonWorkingDay      => aNonWorkingDay
                                        , iStartTime          => aStartTime
                                        , iEndTime            => aEndTime
                                        , iComment            => aComment
                                        , iFilter             => iFilter
                                        , iFilterID           => iFilterID
                                        , iResourceNumber     => aResourceNumber
                                        , iResourceCapacity   => aResourceCapacity
                                        , iResourceCapQty     => aResourceCapQty
                                        , iPiecesHourCap      => aPiecesHourCap
                                        , iDicSchPeriod1      => aDicSchPeriod1
                                        , iDicSchPeriod2      => aDicSchPeriod2
                                        , oErrorPeriodID      => aErrorPeriodID
                                         );
  end;

  /**
  *  procedure CheckSchedulePeriod
  *  Description
  *    Vérification que la période passée en paramêtre ne soit pas en conflit avec une autre période
  */
  procedure CheckSchedulePeriod(
    aPeriodID      in     PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  , aScheduleID    in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aDate          in     PAC_SCHEDULE_PERIOD.SCP_DATE%type
  , aDayOfWeek     in     PAC_SCHEDULE_PERIOD.C_DAY_OF_WEEK%type
  , aNonWorkingDay in     PAC_SCHEDULE_PERIOD.SCP_NONWORKING_DAY%type
  , aStartTime     in     PAC_SCHEDULE_PERIOD.SCP_OPEN_TIME%type
  , aEndTime       in     PAC_SCHEDULE_PERIOD.SCP_CLOSE_TIME%type
  , iFilter        in     varchar2
  , iFilterID      in     number
  , aErrorPeriodID out    PAC_SCHEDULE_PERIOD.PAC_SCHEDULE_PERIOD_ID%type
  )
  is
  begin
    PAC_LIB_SCHEDULE.CheckSchedulePeriod(iPeriodID        => aPeriodID
                                       , iScheduleID      => aScheduleID
                                       , iDate            => aDate
                                       , iDayOfWeek       => aDayOfWeek
                                       , iNonWorkingDay   => aNonWorkingDay
                                       , iStartTime       => aStartTime
                                       , iEndTime         => aEndTime
                                       , iFilter          => iFilter
                                       , iFilterID        => iFilterID
                                       , oErrorPeriodID   => aErrorPeriodID
                                        );
  end CheckSchedulePeriod;

  /**
  *  function GetOpenDaysBetween
  *  Description
  *    Calcule le nb de jours ouvrables entre 2 dates (ID de l'horaire passé en param)
  */
  function GetOpenDaysBetween(
    aScheduleID in PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aDateFrom   in date
  , aDateTo     in date
  , aFilter     in varchar2 default null
  , aFilterID   in number default null
  )
    return integer
  is
  begin
    return PAC_LIB_SCHEDULE.GetOpenDaysBetween(iScheduleID   => aScheduleID
                                             , iDateFrom     => aDateFrom
                                             , iDateTo       => aDateTo
                                             , iFilter       => aFilter
                                             , iFilterID     => aFilterID
                                              );
  end GetOpenDaysBetween;

  /**
  * function IsOpenDay
  * Description
  *   Indique si la date passée est un jour ouvrable selon les horaires
  */
  function IsOpenDay(aScheduleID in PAC_SCHEDULE.PAC_SCHEDULE_ID%type, aDate in date, aFilter in varchar2 default null, aFilterID in number default null)
    return integer
  is
  begin
    return PAC_LIB_SCHEDULE.IsOpenDay(iScheduleID => aScheduleID, iDate => aDate, iFilter => aFilter, iFilterID => aFilterID);
  end IsOpenDay;

  /**
  * function GetDefaultSchedule
  * Description
  *    Recherche l'horaire par défaut
  */
  function GetDefaultSchedule
    return number
  is
  begin
    return PAC_LIB_SCHEDULE.GetDefaultSchedule;
  end GetDefaultSchedule;

  /**
  * procedure GetLogisticThirdSchedule
  * Description
  *    Recherche l'horaire du tiers (méthode pour la logistique)
  */
  procedure GetLogisticThirdSchedule(
    aThirdID     in     PAC_THIRD.PAC_THIRD_ID%type
  , aAdminDomain in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aScheduleID  out    PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aFilter      out    varchar2
  , aFilterID    out    number
  )
  is
  begin
    PAC_LIB_SCHEDULE.GetLogisticThirdSchedule(iThirdID       => aThirdID
                                            , iAdminDomain   => aAdminDomain
                                            , oScheduleID    => aScheduleID
                                            , oFilter        => aFilter
                                            , oFilterID      => aFilterID
                                             );
  end GetLogisticThirdSchedule;

  /**
  * function GetShiftOpenDate
  * Description
  *    Incrémente ou décremente une date avec un décalage donné
  *    en fonction des jours ouvrables de l'horaire demandé selon les params des filtres
  */
  function GetShiftOpenDate(
    aScheduleID in PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aDateFrom   in date
  , aCalcDays   in integer default 0
  , aForward    in integer default 1
  , aFilter     in varchar2 default null
  , aFilterID   in number default null
  )
    return date
  is
  begin
    return PAC_LIB_SCHEDULE.GetShiftOpenDate(iScheduleID   => aScheduleID
                                           , iDateFrom     => aDateFrom
                                           , iCalcDays     => aCalcDays
                                           , iForward      => aForward
                                           , iFilter       => aFilter
                                           , iFilterID     => aFilterID
                                            );
  end GetShiftOpenDate;

  /**
  * procedure CalcOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  */
  procedure CalcOpenTimeBetween(
    aTime       out    number
  , aScheduleID in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aDate_1     in     date
  , aDate_2     in     date
  , aFilter     in     varchar2 default null
  , aFilterID   in     number default null
  )
  is
  begin
    PAC_LIB_SCHEDULE.CalcOpenTimeBetween(oTime         => aTime
                                       , iScheduleID   => aScheduleID
                                       , iDate_1       => aDate_1
                                       , iDate_2       => aDate_2
                                       , iFilter       => aFilter
                                       , iFilterID     => aFilterID
                                        );
  end CalcOpenTimeBetween;

  /**
  * procedure CalcOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  */
  procedure CalcOpenTimeBetween(
    aTime             out    number
  , aResourceCapacity out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , aResourceCapQty   out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , aScheduleID       in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aDate_1           in     date
  , aDate_2           in     date
  , aFilter           in     varchar2 default null
  , aFilterID         in     number default null
  )
  is
  begin
    PAC_LIB_SCHEDULE.CalcOpenTimeBetween(oTime               => aTime
                                       , oResourceCapacity   => aResourceCapacity
                                       , oResourceCapQty     => aResourceCapQty
                                       , iScheduleID         => aScheduleID
                                       , iDate_1             => aDate_1
                                       , iDate_2             => aDate_2
                                       , iFilter             => aFilter
                                       , iFilterID           => aFilterID
                                        );
  end CalcOpenTimeBetween;

  /**
  * procedure CalcOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  */
  procedure CalcOpenTimeBetween(
    aTime         out    number
  , aScheduleID_1 in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aScheduleID_2 in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aDate_1       in     date
  , aDate_2       in     date
  , aFilter_1     in     varchar2 default null
  , aFilterID_1   in     number default null
  , aFilter_2     in     varchar2 default null
  , aFilterID_2   in     number default null
  )
  is
  begin
    PAC_LIB_SCHEDULE.CalcOpenTimeBetween(oTime           => aTime
                                       , iScheduleID_1   => aScheduleID_1
                                       , iScheduleID_2   => aScheduleID_2
                                       , iDate_1         => aDate_1
                                       , iDate_2         => aDate_2
                                       , iFilter_1       => aFilter_1
                                       , iFilterID_1     => aFilterID_1
                                       , iFilter_2       => aFilter_2
                                       , iFilterID_2     => aFilterID_2
                                        );
  end CalcOpenTimeBetween;

  /**
  * procedure CalcOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  */
  procedure CalcOpenTimeBetween(
    aTime             out    number
  , aResourceCapacity out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , aResourceCapQty   out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , aScheduleID_1     in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aScheduleID_2     in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type
  , aDate_1           in     date
  , aDate_2           in     date
  , aFilter_1         in     varchar2 default null
  , aFilterID_1       in     number default null
  , aFilter_2         in     varchar2 default null
  , aFilterID_2       in     number default null
  )
  is
  begin
    PAC_LIB_SCHEDULE.CalcOpenTimeBetween(oTime               => aTime
                                       , oResourceCapacity   => aResourceCapacity
                                       , oResourceCapQty     => aResourceCapQty
                                       , iScheduleID_1       => aScheduleID_1
                                       , iScheduleID_2       => aScheduleID_2
                                       , iDate_1             => aDate_1
                                       , iDate_2             => aDate_2
                                       , iFilter_1           => aFilter_1
                                       , iFilterID_1         => aFilterID_1
                                       , iFilter_2           => aFilter_2
                                       , iFilterID_2         => aFilterID_2
                                        );
  end CalcOpenTimeBetween;

  /**
  * procedure GetNextWorkingPeriod
  * Description
  *    Renvoi la prochaine/précedente/courante période ouverte selon une date/heure passée en param
  *      Si la date heure passée en param est dans une période active, on renvoi celle-ci
  *      Sinon on renvoi la prochaine/précedente période active selon le parametre aForward
  */
  procedure GetNextWorkingPeriod(
    aStartPeriod      out    date
  , aEndPeriod        out    date
  , aResourceNumber   out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_NUMBER%type
  , aResourceCapacity out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type
  , aResourceCapQty   out    PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type
  , aDateFrom         in     date
  , aScheduleID       in     PAC_SCHEDULE.PAC_SCHEDULE_ID%type default null
  , aForward          in     integer default 1
  , aFilter           in     varchar2 default null
  , aFilterID         in     number default null
  )
  is
  begin
    PAC_LIB_SCHEDULE.GetNextWorkingPeriod(oStartPeriod        => aStartPeriod
                                        , oEndPeriod          => aEndPeriod
                                        , oResourceNumber     => aResourceNumber
                                        , oResourceCapacity   => aResourceCapacity
                                        , oResourceCapQty     => aResourceCapQty
                                        , iDateFrom           => aDateFrom
                                        , iScheduleID         => aScheduleID
                                        , iForward            => aForward
                                        , iFilter             => aFilter
                                        , iFilterID           => aFilterID
                                         );
  end GetNextWorkingPeriod;

  /**
  * function GetOpenTimeBetween
  * Description
  *    Calcul du temps ouvert entre 2 date/heure/min (ex: 22.09.2005 08:30 à 23.09.2005 16:00) de 2 horaires
  *    avec une transaction autonome pour que cette fonction puisse être utilisée dans un SELECT
  */
  function GetOpenTimeBetween(
    aDate_1       in date
  , aDate_2       in date
  , aScheduleID_1 in PAC_SCHEDULE.PAC_SCHEDULE_ID%type default null
  , aScheduleID_2 in PAC_SCHEDULE.PAC_SCHEDULE_ID%type default null
  , aFilter_1     in varchar2 default null
  , aFilterID_1   in number default null
  , aFilter_2     in varchar2 default null
  , aFilterID_2   in number default null
  )
    return number
  is
  begin
    return PAC_LIB_SCHEDULE.GetOpenTimeBetween(iDate_1         => aDate_1
                                             , iDate_2         => aDate_2
                                             , iScheduleID_1   => aScheduleID_1
                                             , iScheduleID_2   => aScheduleID_2
                                             , iFilter_1       => aFilter_1
                                             , iFilterID_1     => aFilterID_1
                                             , iFilter_2       => aFilter_2
                                             , iFilterID_2     => aFilterID_2
                                              );
  end GetOpenTimeBetween;

  /**
  *  function DisplayPeriodText
  *  Description
  *    Création du texte à afficher pour une période en concatenant divers champs
  */
  function DisplayPeriodText(aInterroID in PAC_SCHEDULE_INTERRO.PAC_SCHEDULE_INTERRO_ID%type)
    return varchar2
  is
  begin
    return PAC_LIB_SCHEDULE.DisplayPeriodText(iInterroID => aInterroID);
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
  begin
    return PAC_LIB_SCHEDULE.getGivenMoreDaysNextOpenDate(idDate         => idDate
                                                       , inDecalage     => inDecalage
                                                       , inScheduleID   => inScheduleID
                                                       , ivFilter       => ivFilter
                                                       , inFilterID     => inFilterID
                                                        );
  end getGivenMoreDaysNextOpenDate;
end PAC_SCHEDULE_FUNCTIONS;
