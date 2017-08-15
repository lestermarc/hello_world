--------------------------------------------------------
--  DDL for Package Body FAL_DYNAMICNETWORK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_DYNAMICNETWORK" 
is
  /**
  * procedure PrepareDynNetSimulation
  * Description : Préparation de la simlation
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure PrepareDynNetSimulation
  is
    aDefaultCalendarType TTypeID;
  begin
    -- Effacer la table FLN_DELAY
    delete from FAL_DELAY;

    -- Préparation de la table FAL_NETWORK_LINK
    update FAL_NETWORK_LINK
       set A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , FLN_NEED_DELAY = FLN_SUPPLY_DELAY
         , FLN_MARGIN = 0
     where FLN_NEED_DELAY is null
       and FLN_SUPPLY_DELAY is not null;

    update FAL_NETWORK_LINK
       set A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , FLN_SUPPLY_DELAY = FLN_NEED_DELAY
         , FLN_MARGIN = 0
     where FLN_NEED_DELAY is not null
       and FLN_SUPPLY_DELAY is null;

    -- Recopier les dates dans la simulation
    -- (retirer les heures, minues, secondes)
    update FAL_NETWORK_LINK
       set A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , FLN_NEED_DELAY_SIM = trunc(FLN_NEED_DELAY)
         , FLN_SUPPLY_DELAY_SIM = trunc(FLN_SUPPLY_DELAY);

    -- Calcul de la marge réelle (tient compte des jours ouvrables)

    -- Cas N° 1 : Les 2 dates sont égales (Marge à 0)
    update FAL_NETWORK_LINK
       set A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , FLN_REAL_MARGIN = 0
     where FLN_NEED_DELAY_SIM = FLN_SUPPLY_DELAY_SIM;

    -- Récupérer le type de calendrier par défaut
    aDefaultCalendarType  := FAL_SCHEDULE_FUNCTIONS.getdefaultcalendar;

    -- Cas N° 2 : Le delai du besoin est strictement supérieur au delai appro (Marge > 0)
    update FAL_NETWORK_LINK
       set A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , FLN_REAL_MARGIN = FAL_SCHEDULE_FUNCTIONS.GetDuration(null, null, null, null, null, aDefaultCalendarType, FLN_SUPPLY_DELAY_SIM, FLN_NEED_DELAY_SIM)
     where FLN_NEED_DELAY_SIM > FLN_SUPPLY_DELAY_SIM;

    -- Cas N° 3 : Le delai appro est strictement supérieur au delai du besoin (Marge < 0)
    update FAL_NETWORK_LINK
       set A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , FLN_REAL_MARGIN =
                           -1 * FAL_SCHEDULE_FUNCTIONS.GetDuration(null, null, null, null, null, aDefaultCalendarType, FLN_NEED_DELAY_SIM, FLN_SUPPLY_DELAY_SIM)
     where FLN_NEED_DELAY_SIM < FLN_SUPPLY_DELAY_SIM;

    -- Recopier la marge réelle qui vient d être calculée dans la marge simulée (qui EST réelle)
    update FAL_NETWORK_LINK
       set A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , FLN_MARGIN_SIMULATED = FLN_REAL_MARGIN;
  end;

  -- Retourner un delta entre 2 numéros de semaines YYYYWW
  function GetWeekDelta(aWeekFrom varchar2, aWeekTo varchar2)
    return integer
  is
    aYearFrom      integer;
    aYearTo        integer;
    aLocalWeekFrom integer;
    aLocalWeekTo   integer;
    result         integer;
  begin
    result  := 0;

    if aWeekFrom <> aWeekTo then
      aYearFrom       := to_number(substr(aWeekFrom, 1, 4) );
      aYearTo         := to_number(substr(aWeekTo, 1, 4) );
      aLocalWeekFrom  := to_number(substr(aWeekFrom, 5, 2) );
      aLocalWeekTo    := to_number(substr(aWeekTo, 5, 2) );
      result          := (aYearTo * 52) -(aYearFrom * 52) + aLocalWeekTo - aLocalWeekFrom;
    end if;

    return result;
  end;

  -- Retourner le nombre de jours ouvrables entre 2 dates données
  function GetDateDelta(aDateFrom TTypeDate, aDateTo TTypeDate, aTypeCalendarID TTypeID)
    return integer
  is
    aLocalDateFrom TTypeDate;
    aLocalDateTo   TTypeDate;
    aTypeCalID     TTypeID;
    NumberOfDay    integer;
    FROMDATE       TTypeDate;
    TODATE         TTypeDate;
  begin
    aLocalDateFrom  := trunc(aDateFrom);
    aLocalDateTo    := trunc(aDateTo);
    NumberOfDay     := 0;

    if aLocalDateFrom <> aLocalDateTo then
      -- Si le type de calendrier est non renseigné, prendre le type calendrier par défaut ..
      if nvl(aTypeCalendarID, 0) = 0 then
        aTypeCalID  := FAL_SCHEDULE_FUNCTIONS.getdefaultcalendar;
      else
        aTypeCalID  := aTypeCalendarID;
      end if;

      if aLocalDateFrom < aLocalDateTo then
        FROMDATE  := aLocalDateFrom;
        TODATE    := aLocalDateTo;
      else
        FROMDATE  := aLocalDateTo;
        TODATE    := aLocalDateFrom;
      end if;

      NumberOfDay  := FAL_SCHEDULE_FUNCTIONS.GetDuration(null, null, null, null, null, aTypeCalID, FROMDATE, TODATE);

      if aLocalDateFrom > aLocalDateTo then
        NumberOfDay  := -1 * NumberOfDay;
      else
        NumberOfDay  := NumberOfDay;
      end if;
    end if;

    return NumberOfDay;
  end;

  -- Retourner la date décalée du nombre de jours passé en paramètre
  function GetShiftedDate(aDateFrom TTypeDate, aDateShift integer, aTypeCalendarID TTypeID)
    return TTypeDate
  is
    aLocalDateFrom TTypeDate;
    aTypeCalID     TTypeID;
  begin
    aLocalDateFrom  := trunc(aDateFrom);

    -- Si le type de calendrier est non renseigné, prendre le type calendrier par défaut ..
    if nvl(aTypeCalendarID, 0) = 0 then
      aTypeCalID  := FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar;
    else
      aTypeCalID  := aTypeCalendarID;
    end if;

    if aDateShift > 0 then
      return FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(null, null, null, null, null, aTypeCalID, aLocalDateFrom, aDateShift);
    elsif aDateShift < 0 then
      return FAL_SCHEDULE_FUNCTIONS.GetDecalageBackwardDate(null, null, null, null, null, aTypeCalID, aLocalDateFrom, -aDateShift);
    else
      return aLocalDateFrom;
    end if;
  end GetShiftedDate;

  -- Retourner la date de fin pour l appro donnée ...
  function GetSupplyEndDate(aSupplyID TTypeID)
    return TTypeDate
  is
    result TTypeDate;
  begin
    select FAN_END_PLAN
      into result
      from FAL_NETWORK_SUPPLY
     where FAL_NETWORK_SUPPLY_ID = aSupplyID;

    return trunc(result);
  exception
    when no_data_found then
      return null;
  end;

  -- Retourner la date d'appro simulé de FAL_DELAY pour l'appro donnée ...
  function GetSupplySimulatedDelay(aSupplyID TTypeID)
    return TTypeDate
  is
    result TTypeDate;
  begin
    select FAD_SUPPLY_DELAY_SIM
      into result
      from FAL_DELAY
     where FAL_NETWORK_SUPPLY_ID = aSupplyID;

    return trunc(result);
  exception
    when no_data_found then
      return null;
  end;

  -- UpdateMargin : Mettre à jour les dates simulées. Re-calculer la marge réelle simulée
  procedure UpdateMargin(aDefaultCalendarTypeID TTypeID, aLinkID TTypeID, aSupplyDelay TTypeDate, aNeedDelay TTypeDate)
  is
  begin
    -- Cas N° 1 : Les 2 dates sont identiques ...
    if trunc(aNeedDelay) = trunc(aSupplyDelay) then
      update FAL_NETWORK_LINK
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , FLN_NEED_DELAY_SIM = aNeedDelay
           , FLN_SUPPLY_DELAY_SIM = aSupplyDelay
           , FLN_MARGIN_SIMULATED = 0
       where FAL_NETWORK_LINK_ID = aLinkID;
    -- Cas N° 2 : la marge est positive ...
    elsif aNeedDelay > aSupplyDelay then
      update FAL_NETWORK_LINK
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , FLN_NEED_DELAY_SIM = aNeedDelay
           , FLN_SUPPLY_DELAY_SIM = aSupplyDelay
           , FLN_MARGIN_SIMULATED = FAL_SCHEDULE_FUNCTIONS.GetDuration(null, null, null, null, null, aDefaultCalendarTypeID, aSupplyDelay, aNeedDelay)
       where FAL_NETWORK_LINK_ID = aLinkID;
    -- Cas N° 3 : la marge est négative ...
    elsif aNeedDelay < aSupplyDelay then
      update FAL_NETWORK_LINK
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , FLN_NEED_DELAY_SIM = aNeedDelay
           , FLN_SUPPLY_DELAY_SIM = aSupplyDelay
           , FLN_MARGIN_SIMULATED = -1 * FAL_SCHEDULE_FUNCTIONS.GetDuration(null, null, null, null, null, aDefaultCalendarTypeID, aNeedDelay, aSupplyDelay)
       where FAL_NETWORK_LINK_ID = aLinkID;
    end if;
  end;

  -- CreateDelayRecordForNeed : Mettre à jour FAL_DELAY pour un besoin avec retard
  procedure CreateDelayRecordForNeed(aDefaultCalendarTypeID TTypeID, aLinkID TTypeID)
  is
    cursor GetBesoinInfosRecord(aRecordNeedID TTypeID)
    is
      select FNN.STM_STOCK_ID
           , FNN.GCO_GOOD_ID
           , FNN.DOC_RECORD_ID
           , FNN.PAC_THIRD_ID
           , FNN.FAN_DESCRIPTION
           , PDE.DIC_DELAY_UPDATE_TYPE_ID
        from FAL_NETWORK_NEED FNN
           , DOC_POSITION_DETAIL PDE
       where FNN.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID(+)
         and FAL_NETWORK_NEED_ID = aRecordNeedID;

    -- Enregistrement de la table
    aBesoinInfosRecord      GetBesoinInfosRecord%rowtype;
    aRecordNeedID           TTypeID;
    aRecordNeedDelay        TTypeDate;
    aRecordNeedDelaySim     TTypeDate;
    aRecordNeedDelayWeek    varchar2(6);
    aRecordNeedDelaySimWeek varchar2(6);
    aCreateRecord           boolean;
    aDeleteRecord           boolean;
    aDelayID                TTypeID;
    DateTemp                TTypeDate;
    aDateDelta              integer;
    aWeekDelta              integer;
  begin
    aRecordNeedID  := 0;
    aCreateRecord  := false;
    aDeleteRecord  := false;
    aDelayID       := 0;

    -- Récupérer le record pointé par aLinkID ...
    begin
      select FAL_NETWORK_NEED_ID
           , FLN_NEED_DELAY
           , FLN_NEED_DELAY_SIM
        into aRecordNeedID
           , aRecordNeedDelay
           , aRecordNeedDelaySim
        from FAL_NETWORK_LINK
       where FAL_NETWORK_LINK_ID = aLinkID;

      if aRecordNeedID is not null then
        aRecordNeedDelayWeek     := to_char(aRecordNeedDelay, 'YYYYWW');
        aRecordNeedDelaySimWeek  := to_char(aRecordNeedDelaySim, 'YYYYWW');
      end if;
    exception
      when no_data_found then
        aRecordNeedID  := null;
    end;

    -- Si non trouvé, sortir ...
    if aRecordNeedID is not null then
      -- Vérifier si ce besoin existe déjà dans la table FAL_DELAY ...
      begin
        select FAL_DELAY_ID
             , FAD_NEED_DELAY_SIM
          into aDelayID
             , DateTemp
          from FAL_DELAY
         where FAL_NETWORK_NEED_ID = aRecordNeedID;

        aDeleteRecord  := true;

        if trunc(DateTemp) <= aRecordNeedDelay then
          aCreateRecord  := true;
        end if;
      exception
        when no_data_found then
          aCreateRecord  := true;
      end;

      -- Vérifier s il faut créer le record ...
      if aCreateRecord then
        -- Supression du record si nécéssaire ...
        if     aDeleteRecord
           and (nvl(aDelayID, 0) <> 0) then
          delete from FAL_DELAY
                where FAL_DELAY_ID = aDelayID;
        end if;

        -- Création du record ...
        open GetBesoinInfosRecord(aRecordNeedID);

        fetch GetBesoinInfosRecord
         into aBesoinInfosRecord;

        -- S assurer qu il y ai un enregistrement ...
        while GetBesoinInfosRecord%found loop
          aDateDelta  := GetDateDelta(aRecordNeedDelay, aRecordNeedDelaySim, aDefaultCalendarTypeID);
          aWeekDelta  := GetWeekDelta(aRecordNeedDelayWeek, aRecordNeedDelaySimWeek);

          insert into FAL_DELAY
                      (FAL_DELAY_ID
                     , FAL_NETWORK_NEED_ID
                     , FAL_NETWORK_SUPPLY_ID
                     , STM_STOCK_ID
                     , GCO_GOOD_ID
                     , DOC_RECORD_ID
                     , PAC_THIRD_ID
                     , FAD_GAP_DAY
                     , FAD_GAP_WEEK
                     , FAD_DESCRIPTION
                     , FAD_UPDATE
                     , FAD_UPDATE_REAL
                     , FAD_NEED
                     , FAD_SUPPLY_DELAY
                     , FAD_NEED_DELAY
                     , FAD_SUPPLY_DELAY_WEEK
                     , FAD_NEED_DELAY_WEEK
                     , FAD_SUPPLY_DELAY_SIM_WEEK
                     , FAD_NEED_DELAY_SIM_WEEK
                     , FAD_SUPPLY_DELAY_SIM
                     , FAD_NEED_DELAY_SIM
                     , DIC_DELAY_UPDATE_TYPE2_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (GetNewId
                     , aRecordNeedID
                     , null
                     , aBesoinInfosRecord.STM_STOCK_ID
                     , aBesoinInfosRecord.GCO_GOOD_ID
                     , aBesoinInfosRecord.DOC_RECORD_ID
                     , aBesoinInfosRecord.PAC_THIRD_ID
                     , aDateDelta
                     , aWeekDelta
                     , aBesoinInfosRecord.FAN_DESCRIPTION
                     , 0
                     , 0
                     , 1
                     , null
                     , aRecordNeedDelay
                     , null
                     , aRecordNeedDelayWeek
                     , null
                     , aRecordNeedDelaySimWeek
                     , null
                     , aRecordNeedDelaySim
                     , aBesoinInfosRecord.DIC_DELAY_UPDATE_TYPE_ID
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          fetch GetBesoinInfosRecord
           into aBesoinInfosRecord;
        end loop;

        -- Fermeture du curseur
        close GetBesoinInfosRecord;
      end if;
    end if;
  end;

  -- CreateDelayRecordForSupply : Mettre à jour FAL_DELAY pour un appro avec retard
  procedure CreateDelayRecordForSupply(aDefaultCalendarTypeID TTypeID, aSupplyID TTypeID, aSupplyDelaySim TTypeDate)
  is
    cursor GetApproInfosRecord(bSupplyID TTypeID)
    is
      select STM_STOCK_ID
           , GCO_GOOD_ID
           , DOC_RECORD_ID
           , PAC_THIRD_ID
           , FAN_DESCRIPTION
        from FAL_NETWORK_SUPPLY
       where FAL_NETWORK_SUPPLY_ID = bSupplyID;

    -- Enregistrement de la table
    aApproInfosRecord   GetApproInfosRecord%rowtype;
    aSupplyDelay        TTypeDate;
    aSupplyDelayWeek    varchar2(6);
    aSupplyDelaySimWeek varchar2(6);
    aDateDelta          integer;
    aWeekDelta          integer;
  begin
    aSupplyDelay         := GetSupplyEndDate(aSupplyID);
    aSupplyDelayWeek     := to_char(aSupplyDelay, 'YYYYWW');
    aSupplyDelaySimWeek  := to_char(aSupplyDelaySim, 'YYYYWW');

    -- Supression du record ...
    delete from FAL_DELAY
          where FAL_NETWORK_SUPPLY_ID = aSupplyID;

    -- Création du record ...
    open GetApproInfosRecord(aSupplyID);

    fetch GetApproInfosRecord
     into aApproInfosRecord;

    -- S assurer qu il y ai un enregistrement ...
    while GetApproInfosRecord%found loop
      aDateDelta  := GetDateDelta(aSupplyDelay, aSupplyDelaySim, aDefaultCalendarTypeID);
      aWeekDelta  := GetWeekDelta(aSupplyDelayWeek, aSupplyDelaySimWeek);

      insert into FAL_DELAY
                  (FAL_DELAY_ID
                 , FAL_NETWORK_NEED_ID
                 , FAL_NETWORK_SUPPLY_ID
                 , STM_STOCK_ID
                 , GCO_GOOD_ID
                 , DOC_RECORD_ID
                 , PAC_THIRD_ID
                 , FAD_GAP_DAY
                 , FAD_GAP_WEEK
                 , FAD_DESCRIPTION
                 , FAD_UPDATE
                 , FAD_UPDATE_REAL
                 , FAD_NEED
                 , FAD_SUPPLY_DELAY
                 , FAD_NEED_DELAY
                 , FAD_SUPPLY_DELAY_WEEK
                 , FAD_NEED_DELAY_WEEK
                 , FAD_SUPPLY_DELAY_SIM_WEEK
                 , FAD_NEED_DELAY_SIM_WEEK
                 , FAD_SUPPLY_DELAY_SIM
                 , FAD_NEED_DELAY_SIM
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , null
                 , aSupplyID
                 , aApproInfosRecord.STM_STOCK_ID
                 , aApproInfosRecord.GCO_GOOD_ID
                 , aApproInfosRecord.DOC_RECORD_ID
                 , aApproInfosRecord.PAC_THIRD_ID
                 , aDateDelta
                 , aWeekDelta
                 , aApproInfosRecord.FAN_DESCRIPTION
                 , 0
                 , 0
                 , 0
                 , aSupplyDelay
                 , null
                 , aSupplyDelayWeek
                 , null
                 , aSupplyDelaySimWeek
                 , null
                 , aSupplyDelaySim
                 , null
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      fetch GetApproInfosRecord
       into aApproInfosRecord;
    end loop;

    -- Fermeture du curseur
    close GetApproInfosRecord;
  end;

  /**
  * procedure GrapheEvent_ReseauDynamique2
  * Description : Simulation des retards
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure GrapheEvent_ReseauDynamique2(
    aDefaultCalendarTypeID in TTypeID
  , aLinkID                in TTypeID
  , aNeedID                in TTypeID
  , aSupplyDelay           in TTypeDate
  , aMargin                in TTypeID
  )
  is
    cursor crRequirementsFromSameNeedId
    is
      select FAL_NETWORK_LINK_ID
           , FLN_SUPPLY_DELAY_SIM
        from FAL_NETWORK_LINK
       where FAL_NETWORK_NEED_ID = aNeedID
         and FAL_NETWORK_LINK_ID <> aLinkID;

    cursor crNeedBatchInfos(aNeedId TTypeID)
    is
      select LOT.FAL_LOT_ID
           , LPR.FAL_LOT_PROP_ID
           , nvl(LOT.LOT_PLAN_BEGIN_DTE, LPR.LOT_PLAN_BEGIN_DTE) LOT_PLAN_BEGIN_DTE
           , nvl(LOT.C_SCHEDULE_PLANNING, LPR.C_SCHEDULE_PLANNING) C_SCHEDULE_PLANNING
           , nvl(LOT.FAL_SCHEDULE_PLAN_ID, LPR.FAL_SCHEDULE_PLAN_ID) FAL_SCHEDULE_PLAN_ID
           , LOM.LOM_TASK_SEQ
           , LOM.LOM_INTERVAL
        from FAL_NETWORK_NEED FNN
           , FAL_LOT LOT
           , FAL_LOT_PROP LPR
           , FAL_LOT_MATERIAL_LINK LOM
       where FNN.FAL_NETWORK_NEED_ID = aNeedID
         and LOT.FAL_LOT_ID(+) = FNN.FAL_LOT_ID
         and LPR.FAL_LOT_PROP_ID(+) = FNN.FAL_LOT_PROP_ID
         and LOM.FAL_LOT_MATERIAL_LINK_ID(+) = nvl(FNN.FAL_LOT_MATERIAL_LINK_ID, FNN.FAL_LOT_MAT_LINK_PROP_ID);

    cursor crAttribFromBatch(aLotId TTypeID, aPropLotId TTypeID, aNeedId TTypeID)
    is
      select FNL.FAL_NETWORK_LINK_ID
           , FNL.FLN_SUPPLY_DELAY_SIM
           , FNL.FLN_NEED_DELAY
           , LOM.LOM_TASK_SEQ
           , LOM.LOM_INTERVAL
        from FAL_NETWORK_LINK FNL
           , FAL_NETWORK_NEED FNN
           , FAL_LOT_MATERIAL_LINK LOM
       where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
         and nvl(FNN.FAL_LOT_ID, FNN.FAL_LOT_PROP_ID) = nvl(aLotID, aPropLotID)
         and FNL.FAL_NETWORK_NEED_ID <> aNeedID
         and LOM.FAL_LOT_MATERIAL_LINK_ID(+) = nvl(FNN.FAL_LOT_MATERIAL_LINK_ID, FNN.FAL_LOT_MAT_LINK_PROP_ID);

    cursor crRequirementOfBatch(aSupplyID TTypeID, aLotId TTypeID, aPropLotId TTypeID)
    is
      select FAL_NETWORK_LINK_ID
           , FAL_NETWORK_NEED_ID
           , FLN_SUPPLY_DELAY_SIM
           , FLN_REAL_MARGIN
        from FAL_NETWORK_LINK
       where FAL_NETWORK_SUPPLY_ID = aSupplyID
         and FAL_NETWORK_NEED_ID is not null;

    tplNeedBatchInfos       crNeedBatchInfos%rowtype;
    aRecordFound            boolean;
    aRecordRealMargin       TTypeID;
    aRecordSupplyDelaySim   TTypeDate;
    aRecordNeedDelaySim     TTypeDate;
    aIsComponentNeed        boolean;
    aHasNeedLink            boolean;
    aLotID                  TTypeID;
    aPropLotID              TTypeID;
    aSupplyID               TTypeID;
    aSupplyExistInFAL_Delay boolean;
    aLocalSupplyDelay       TTypeDate;
    aLocalRealMargin        TTypeID;
    vSupplyDelayGap         number;
    Temp                    integer;
    IntoTemp                integer;
    LotBeginDate            date;
    LotDuration             number;
    vRecordNeedDelay        TTypeDate;
    vAttribSupplyDelay      TTypeDate;
    vLotBeginDateSim        TTypeDate;
  begin
    -- Récupérer le record pointé par aLinkID
    begin
      select FLN_NEED_DELAY_SIM
           , FLN_SUPPLY_DELAY_SIM
           , FLN_REAL_MARGIN
           , FLN_NEED_DELAY
        into aRecordNeedDelaySim
           , aRecordSupplyDelaySim
           , aRecordRealMargin
           , vRecordNeedDelay
        from FAL_NETWORK_LINK
       where FAL_NETWORK_LINK_ID = aLinkID;

      aRecordFound  := true;
    exception
      when no_data_found then
        aRecordFound  := false;
    end;

    if aRecordFound then
      -- Comparer aSupplyDelay au aRecordNeedDelaySim du record
      if aSupplyDelay <= aRecordNeedDelaySim then
        if aSupplyDelay > aRecordSupplyDelaySim then
          -- Mettre à jour le record avec la nouvelle date d'appro. Re-calculer la marge ...
          UpdateMargin(aDefaultCalendarTypeID, aLinkID, aSupplyDelay, aRecordNeedDelaySim);
        end if;
      else
        -- Mettre à jour le record avec la nouvelle date d'appro comme appro ET besoin Re-calculer la marge ...
        UpdateMargin(aDefaultCalendarTypeID, aLinkID, aSupplyDelay, aSupplyDelay);

        -- Récupérer les ID d attribution pour lesquelles l ID besoin est celui passé en paramètre
        -- Eviter le record qui vient d être traité
        for tplAttribInfosRecord in crRequirementsFromSameNeedId loop
          -- Mettre à jour le record avec la nouvelle date d'appro comme besoin
          -- Re-calculer la marge ...
          UpdateMargin(aDefaultCalendarTypeID, tplAttribInfosRecord.FAL_NETWORK_LINK_ID, tplAttribInfosRecord.FLN_SUPPLY_DELAY_SIM, aSupplyDelay);
        end loop;

        -- Est-ce que le besoin passé en paramètre correspond à un besoin d un composant d un lot
        -- (ou prop de lot) de fabrication
        aIsComponentNeed  := false;
        aLotID            := null;
        aPropLotID        := null;

        open crNeedBatchInfos(aNeedId);

        fetch crNeedBatchInfos
         into tplNeedBatchInfos;

        if crNeedBatchInfos%found then
          aLotID            := tplNeedBatchInfos.FAL_LOT_ID;
          aPropLotID        := tplNeedBatchInfos.FAL_LOT_PROP_ID;
          aIsComponentNeed  :=    (aLotID is not null)
                               or (aPropLotID is not null);
        end if;

        close crNeedBatchInfos;

        -- Le besoin est un composant de lot (prop de lot) de fabrication
        if aIsComponentNeed then
          -- Calculer le décalage si le composant est lié à une opération ou si un décalage est spécifié
          vSupplyDelayGap   := 0;

          if     (tplNeedBatchInfos.C_SCHEDULE_PLANNING <> '1')
             and (tplNeedBatchInfos.FAL_SCHEDULE_PLAN_ID is not null) then
            if tplNeedBatchInfos.LOM_TASK_SEQ > 0 then
              vSupplyDelayGap  := GetDateDelta(vRecordNeedDelay, nvl(tplNeedBatchInfos.LOT_PLAN_BEGIN_DTE, vRecordNeedDelay), aDefaultCalendarTypeID);
            end if;
          elsif tplNeedBatchInfos.LOM_INTERVAL <> 0 then
            vSupplyDelayGap  := -tplNeedBatchInfos.LOM_INTERVAL;
          end if;

          vLotBeginDateSim  := GetShiftedDate(aSupplyDelay, vSupplyDelayGap, aDefaultCalendarTypeID);

          -- Mettre à jour les attributions associés à tous les besoins composants
          -- du même lot (à l exception du besoin en cours) ...
          for tplAttribFromBatch in crAttribFromBatch(aLotID, aPropLotID, aNeedID) loop
            -- Mettre à jour le record avec la nouvelle date d'appro comme besoin
            -- Re-calculer la marge en tenant compte d'un éventuel lien
            -- composant/opération ou d'un décalage
            vAttribSupplyDelay  := vLotBeginDateSim;

            if     (tplNeedBatchInfos.C_SCHEDULE_PLANNING <> '1')
               and (tplNeedBatchInfos.FAL_SCHEDULE_PLAN_ID is not null) then
              if tplAttribFromBatch.LOM_TASK_SEQ > 0 then
                vAttribSupplyDelay  :=
                  GetShiftedDate(vLotBeginDateSim
                               , GetDateDelta(nvl(tplNeedBatchInfos.LOT_PLAN_BEGIN_DTE, tplAttribFromBatch.FLN_NEED_DELAY)
                                            , tplAttribFromBatch.FLN_NEED_DELAY
                                            , aDefaultCalendarTypeID
                                             )
                               , aDefaultCalendarTypeID
                                );
              end if;
            elsif tplAttribFromBatch.LOM_INTERVAL <> 0 then
              vAttribSupplyDelay  := GetShiftedDate(vLotBeginDateSim, tplAttribFromBatch.LOM_INTERVAL, aDefaultCalendarTypeID);
            end if;

            UpdateMargin(aDefaultCalendarTypeID, tplAttribFromBatch.FAL_NETWORK_LINK_ID, tplAttribFromBatch.FLN_SUPPLY_DELAY_SIM, vAttribSupplyDelay);
          end loop;

          -- Récupérer le SupplyID associé au lot (ou prop de lot) de fabrication
          aSupplyID         := 0;

          declare
            -- Curseur sur la table FAL_NETWORK_SUPPLY
            cursor GetApproInfosRecord
            is
              select FAL_NETWORK_SUPPLY_ID
                from FAL_NETWORK_SUPPLY
               where (     (   FAL_LOT_ID = aLotID
                            or aLotID is null)
                      and (   FAL_LOT_PROP_ID = aPropLotID
                           or aPropLotID is null) );

            -- Enregistrement de la table
            aApproInfosRecord GetApproInfosRecord%rowtype;
          begin
            -- Ouverture du curseur sur la table
            open GetApproInfosRecord;

            fetch GetApproInfosRecord
             into aApproInfosRecord;

            if GetApproInfosRecord%found then
              aSupplyID  := aApproInfosRecord.FAL_NETWORK_SUPPLY_ID;
            else
              aSupplyID  := 0;
            end if;

            close GetApproInfosRecord;
          end;

          -- Re-planification du lot/prop de lot (sans mise à jour)
          -- pour le calcul de la date fin du lot/prop de lot
          if aLotId is not null then
            FAL_PLANIF.Planif_Lot_Create(PrmFAL_LOT_ID              => aLotID
                                       , PrmLOT_TOLERANCE           => 0
                                       , DatePlanification          => vLotBeginDateSim
                                       , SelonDateDebut             => 1
                                       , MAJReqLiensComposantsLot   => 0
                                       , MAJ_Reseaux_Requise        => 0
                                       , LotBeginDate               => LotBeginDate
                                       , LotEndDate                 => aLocalSupplyDelay
                                       , LotDuration                => LotDuration
                                       , aDoHistorisationPlanif     => 0
                                       , UpdateFields               => 0
                                        );
          else
            FAL_PLANIF.PlanningProposition(aFalLotPropId   => aPropLotID
                                         , aPlanningDate   => vLotBeginDateSim
                                         , aUpdateProp     => 0
                                         , aBeginDate      => LotBeginDate
                                         , aEndDate        => aLocalSupplyDelay
                                         , aDuration       => LotDuration
                                          );
          end if;

          -- Est-ce que le lot de fab (ou proposition) associé au besoin est attribué
           -- à un besoin ?
          select count(1)
            into Temp
            from FAL_NETWORK_LINK
           where FAL_NETWORK_SUPPLY_ID = aSupplyID
             and FAL_NETWORK_NEED_ID is not null;

          aHasNeedLink      := Temp > 0;

          -- Le lot de fab (ou proposition) associé au besoin n est pas attribué à un besoin
          if not aHasNeedLink then
            -- L appro existe-t elle dans dans la table FAL_DELAY ? ...
            begin
              select 1
                into IntoTemp
                from FAL_DELAY
               where FAL_NETWORK_SUPPLY_ID = aSupplyID;

              aSupplyExistInFAL_Delay  := true;
            exception
              when no_data_found then
                aSupplyExistInFAL_Delay  := false;
            end;

            -- L'appro n'existe pas dans dans la table FAL_DELAY ...
            -- Ou comparaison avec la date portée par FAL_DELAY ...
            if    (not aSupplyExistInFAL_Delay)
               or (aLocalSupplyDelay > GetSupplySimulatedDelay(aSupplyID) ) then
              -- Création d un record dans la table FAL_DELAY
              IndexListSupply                                       := IndexListSupply + 1;
              ListSupplyToCreate(IndexListSupply).DefaultCalTypeId  := aDefaultCalendarTypeID;
              ListSupplyToCreate(IndexListSupply).SupplyID          := aSupplyID;
              ListSupplyToCreate(IndexListSupply).SupplyDelaySim    := aLocalSupplyDelay;
            end if;
          else
            declare
              type TTabAttribRecords is table of crRequirementOfBatch%rowtype
                index by binary_integer;

              TabAttribRecords TTabAttribRecords;
              vIndex           integer           := 0;
            begin
              -- Le lot de fab (ou proposition) associé au besoin est attribué à au moins un besoin
              for tplRequirementOfBatch in crRequirementOfBatch(aSupplyID, aLotID, aPropLotID) loop
                vIndex                                         := vIndex + 1;
                TabAttribRecords(vIndex).FAL_NETWORK_LINK_ID   := tplRequirementOfBatch.FAL_NETWORK_LINK_ID;
                TabAttribRecords(vIndex).FAL_NETWORK_NEED_ID   := tplRequirementOfBatch.FAL_NETWORK_NEED_ID;
                TabAttribRecords(vIndex).FLN_SUPPLY_DELAY_SIM  := aLocalSupplyDelay;
                TabAttribRecords(vIndex).FLN_REAL_MARGIN       := aMargin - greatest(tplRequirementOfBatch.FLN_REAL_MARGIN, 0);
              end loop;

              for J in 1 .. vIndex loop
                GrapheEvent_ReseauDynamique2(aDefaultCalendarTypeID
                                           , TabAttribRecords(vIndex).FAL_NETWORK_LINK_ID
                                           , TabAttribRecords(vIndex).FAL_NETWORK_NEED_ID
                                           , TabAttribRecords(vIndex).FLN_SUPPLY_DELAY_SIM
                                           , TabAttribRecords(vIndex).FLN_REAL_MARGIN
                                            );
              end loop;
            end;
          end if;
        -- Le besoin n est pas un composant de lot (prop de lot) de fabrication
        else
          -- Création d un record Besoin dans la table FAL_DELAY
          IndexListNeed                                     := IndexListNeed + 1;
          ListNeedToCreate(IndexListNeed).DefaultCalTypeId  := aDefaultCalendarTypeID;
          ListNeedToCreate(IndexListNeed).LinkID            := aLinkID;
        end if;
      end if;
    end if;
  end;

  /**
  * procedure GrapheEvent_ReseauDynamique1
  * Description : Lancement de la simulation des retards
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure GrapheEvent_ReseauDynamique1
  is
    aBadestMarginFound     boolean;
    aDefaultCalendarTypeID TTypeID;
  begin
    -- Récupére le type du calendrier par défaut ...
    aDefaultCalendarTypeID  := FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar;
    aBadestMarginFound      := true;

    while aBadestMarginFound loop
      declare
        /* Sélection de l'attribution où la marge simulée est la plus négative. On exclut les liens d'attribution qui ont le besoin et l'appro identiques (lot ou proposition -
           comme un OF qui aurait un composant identique au produit terminé, avec l'appro PT lié au besoin CPT). */
        cursor GetAttribInfosRecord
        is
          select   FAL_NETWORK_NEED_ID
                 , FAL_NETWORK_LINK_ID
                 , FLN_SUPPLY_DELAY_SIM
                 , FLN_MARGIN_SIMULATED
              from FAL_NETWORK_LINK LNK
             where FLN_MARGIN_SIMULATED < 0
               and FAL_NETWORK_NEED_ID is not null
               and FAL_NETWORK_SUPPLY_ID is not null
               and (select nvl(nvl(FAL_LOT_ID, FAL_LOT_PROP_ID), 0)
                      from FAL_NETWORK_SUPPLY
                     where FAL_NETWORK_SUPPLY_ID = LNK.FAL_NETWORK_SUPPLY_ID) <> (select nvl(nvl(FAL_LOT_ID, FAL_LOT_PROP_ID), 1)
                                                                                    from FAL_NETWORK_NEED
                                                                                   where FAL_NETWORK_NEED_ID = LNK.FAL_NETWORK_NEED_ID)
          order by FLN_MARGIN_SIMULATED asc;

        -- Enregistrement de la table
        aAttribInfosRecord GetAttribInfosRecord%rowtype;
      begin
        -- Ouverture du curseur sur la table
        open GetAttribInfosRecord;

        fetch GetAttribInfosRecord
         into aAttribInfosRecord;

        -- S assurer qu il y ai un enregistrement ...
        aBadestMarginFound  := GetAttribInfosRecord%found;

        if aBadestMarginFound then
          -- Démarrer le graphe : Réseaux dynamiques n° 2 ...
          GrapheEvent_ReseauDynamique2(aDefaultCalendarTypeID   => aDefaultCalendarTypeID
                                     , aLinkID                  => aAttribInfosRecord.FAL_NETWORK_LINK_ID
                                     , aNeedID                  => aAttribInfosRecord.FAL_NETWORK_NEED_ID
                                     , aSupplyDelay             => aAttribInfosRecord.FLN_SUPPLY_DELAY_SIM
                                     , aMargin                  => -1 * aAttribInfosRecord.FLN_MARGIN_SIMULATED
                                      );
        end if;

        -- Fermeture du curseur
        close GetAttribInfosRecord;
      end;
    end loop;

    for i in 1 .. IndexListNeed loop
      CreateDelayRecordForNeed(ListNeedToCreate(i).DefaultCalTypeId, ListNeedToCreate(i).LinkID);
    end loop;

    for i in 1 .. IndexListSupply loop
      CreateDelayRecordForSupply(ListSupplyToCreate(i).DefaultCalTypeId, ListSupplyToCreate(i).SupplyID, ListSupplyToCreate(i).SupplyDelaySim);
    end loop;
  end GrapheEvent_ReseauDynamique1;
end;
