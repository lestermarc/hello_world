--------------------------------------------------------
--  DDL for Package Body ASA_MISSION_GENERATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_MISSION_GENERATE" 
is
  /**
  * procedure AutoGenMissions
  * Description
  *    Génération automatique des missions selon le type de mission et la période à considérer
  * @created DSA 16.06.2006
  */
  procedure AutoGenMissions(aMisTypeID in ASA_MISSION_TYPE.ASA_MISSION_TYPE_ID%type, aPeriod in number)
  is
    vProc      ASA_MISSION_TYPE.MIT_AUTO_GEN_PROC%type;
    vRemovable ASA_MISSION_TYPE.MIT_REMOVABLE%type;
  begin
    -- Recherche de la procédure de génération associée au type de mission
    select MIT.MIT_AUTO_GEN_PROC
         , MIT.MIT_REMOVABLE
      into vProc
         , vRemovable
      from ASA_MISSION_TYPE MIT
     where MIT.ASA_MISSION_TYPE_ID = aMisTypeID;

    -- Suppression des missions provisoires de ce type si celui-ci l'autorise
    if (vRemovable = 1) then
      delete from ASA_MISSION
            where ASA_MISSION_TYPE_ID = aMisTypeID
              and C_ASA_MIS_STATUS = '00';
    end if;

    -- Exécution de la procédure
    execute immediate 'begin ' || vProc || '(:MisTypeId,:Period); end;'
                using aMisTypeID, aPeriod;
  exception
    when no_data_found then
      null;
  end AutoGenMissions;

  /**
  * Description
  *    Génération automatique des missions de type service
  */
  procedure GenerateServiceMissions(aMissionTypeID in ASA_MISSION_TYPE.ASA_MISSION_TYPE_ID%type, aPeriod in number)
  is
    tplNewMission ASA_MISSION%rowtype;

    cursor cr_Install(aASA_MISSION_TYPE_ID ASA_MISSION_TYPE.ASA_MISSION_TYPE_ID%type)
    is
      select RCO.DOC_RECORD_ID
           , RCO.RCO_MACHINE_GOOD_ID
           , AIM.PAC_CUSTOM_PARTNER_ID
           , AIM.PAC_DEPARTMENT_ID
           , AIM.PAC_ADDRESS_ID
           , AIM.AIM_LOCATION_COMMENT1
           , AIM.AIM_LOCATION_COMMENT2
           , AIM.AIM_MOVEMENT_DATE
        from DOC_RECORD RCO
           , ASA_INSTALLATION_MOVEMENT AIM
       where RCO.C_RCO_STATUS = '0'   -- installation active
         and AIM.DOC_RECORD_ID = RCO.DOC_RECORD_ID   -- avec base installée
         and AIM.C_ASA_AIM_HISTORY_CODE = '1'
         and AIM.DIC_AIM_LOCK_CODE_ID is null   -- non bloquée
         and exists(select SER.GCO_SERVICE_PLAN_ID
                      from GCO_SERVICE_PLAN SER
                         , GCO_COMPL_DATA_EXTERNAL_ASA CEA
                     where SER.GCO_COMPL_DATA_EXTERNAL_ASA_ID = CEA.GCO_COMPL_DATA_EXTERNAL_ASA_ID
                       and CEA.GCO_GOOD_ID = RCO.RCO_MACHINE_GOOD_ID)   -- avec plan de service
         and exists(
               select *
                 from CML_DOCUMENT CCO
                    , CML_POSITION CPO
                    , CML_POSITION_MACHINE CPM
                where CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
                  and CPO.CML_POSITION_ID = CPM.CML_POSITION_ID
                  and CPM.DOC_RCO_MACHINE_ID = RCO.DOC_RECORD_ID   -- lié au moins à un contrat
                  and CPO.C_CML_POS_STATUS in('02', '03')   -- actif
                  and CCO.PAC_CUSTOM_PARTNER_ID = AIM.PAC_CUSTOM_PARTNER_ID   -- sur le client de la base instalée
                  and CPO.CPO_END_CONTRACT_DATE >= add_months(trunc(sysdate), 2)   -- ne se terminant pas avant 2 mois
                  and CPO.CPO_RESILIATION_DATE is null
                  and CPO.CPO_SUSPENSION_DATE is null)   -- non en cours d'annulation
         and not exists(select ASA_MISSION_ID
                          from ASA_MISSION
                         where ASA_MACHINE_ID = RCO.DOC_RECORD_ID
                           and C_ASA_MIS_STATUS in('00', '01')
                           and ASA_MISSION_TYPE_ID = aASA_MISSION_TYPE_ID);   -- n'ayant aucune mission en cours de ce type

    tplInstall    cr_Install%rowtype;
  begin
    -- Sélection de toutes les installations vérifiant les conditions de génération des missions "services"
    open cr_Install(aMissionTypeID);

    loop
      fetch cr_Install
       into tplInstall;

      -- Initialisation des données de la nouvelle mission
      tplNewMission                        := null;
      tplNewMission.ASA_MISSION_TYPE_ID    := aMissionTypeID;
      tplNewMission.PAC_CUSTOM_PARTNER_ID  := tplInstall.PAC_CUSTOM_PARTNER_ID;
      tplNewMission.DOC_RECORD_ID          := tplInstall.DOC_RECORD_ID;
      tplNewMission.PAC_DEPARTMENT_ID      := tplInstall.PAC_DEPARTMENT_ID;
      tplNewMission.PAC_ADDRESS_ID         := tplInstall.PAC_ADDRESS_ID;
      tplNewMission.MIS_LOCATION_COMMENT1  := tplInstall.AIM_LOCATION_COMMENT1;
      tplNewMission.MIS_LOCATION_COMMENT2  := tplInstall.AIM_LOCATION_COMMENT2;

      -- Pour chaque machine, recherche des plans de service à terme fixe associés au modèle de l'installation
      for cr_ServicePlan1 in (select CTG.ASA_COUNTER_TYPE_ID
                                   , SER.GCO_SERVICE_PLAN_ID
                                   , SER.C_SERVICE_PLAN_PERIODICITY
                                   , SER.SER_PERIODICITY
                                   , SER.ASA_COUNTER_TYPE_S_GOOD_ID
                                   , SER.SER_COUNTER_STATE * nvl(SER.SER_CONVERSION_FACTOR, 1) SER_COUNTER_STATE
                                from GCO_SERVICE_PLAN SER
                                   , GCO_COMPL_DATA_EXTERNAL_ASA CEA
                                   , ASA_COUNTER_TYPE_S_GOOD CTG
                               where SER.GCO_COMPL_DATA_EXTERNAL_ASA_ID = CEA.GCO_COMPL_DATA_EXTERNAL_ASA_ID
                                 and CEA.GCO_GOOD_ID = tplInstall.RCO_MACHINE_GOOD_ID
                                 and SER.C_ASA_SERVICE_TYPE = '0'
                                 and CTG.GCO_GOOD_ID = CEA.GCO_GOOD_ID
                                 and (   CTG.ASA_COUNTER_TYPE_S_GOOD_ID = SER.ASA_COUNTER_TYPE_S_GOOD_ID
                                      or SER.ASA_COUNTER_TYPE_S_GOOD_ID is null) ) loop
        -- Réinitialisation des valeurs de la mission
        tplNewMission.GCO_SERVICE_PLAN_ID  := null;
        tplNewMission.MIS_REQUEST_DATE     := null;
        tplNewMission.MIS_SERVICE_MARKER   := null;

        -- Pour chaque plan, on vérifie qu'il n'existe aucune mission associée pour le plan de service/type de compteur
        if ExistsMissionService(aInstallID       => tplInstall.DOC_RECORD_ID
                              , aCounterTypeID   => cr_ServicePlan1.ASA_COUNTER_TYPE_ID
                              , aServicePlanId   => cr_ServicePlan1.GCO_SERVICE_PLAN_ID
                               ) = 0 then
          -- Initialisation du plan de service
          tplNewMission.GCO_SERVICE_PLAN_ID  := cr_ServicePlan1.GCO_SERVICE_PLAN_ID;

          -- Plan de service "temporel"
          if cr_ServicePlan1.ASA_COUNTER_TYPE_S_GOOD_ID is null then
            -- Initialisation du compteur
            tplNewMission.ASA_COUNTER_ID    := ASA_COUNTER_FUNCTIONS.GetCounter(cr_ServicePlan1.ASA_COUNTER_TYPE_ID, tplInstall.DOC_RECORD_ID);
            -- Calcul de la date de la nouvelle mission
            tplNewMission.MIS_REQUEST_DATE  :=
              GetMissionNextDate(tplInstall.DOC_RECORD_ID
                               , tplInstall.PAC_CUSTOM_PARTNER_ID
                               , cr_ServicePlan1.C_SERVICE_PLAN_PERIODICITY
                               , cr_ServicePlan1.SER_PERIODICITY
                                );

            -- Si la date de la nouvelle mission entre dans la période de génération, on peut créer la mission
            if     tplNewMission.MIS_REQUEST_DATE is not null
               and tplNewMission.MIS_REQUEST_DATE >= trunc(sysdate)
               and tplNewMission.MIS_REQUEST_DATE <= add_months(sysdate, aPeriod) then
              CreateMission(tplNewMission);
            end if;
          else   -- Plan de service "Etat compteur"
            -- Initialisation du compteur, de la date et de la borne de service
            GetNextServiceInfo(cr_ServicePlan1.ASA_COUNTER_TYPE_ID, cr_ServicePlan1.SER_COUNTER_STATE, aPeriod, tplNewMission);

            -- Si la date de la nouvelle mission entre dans la période de génération, on peut créer la mission
            if     tplNewMission.MIS_REQUEST_DATE is not null
               and tplNewMission.MIS_REQUEST_DATE >= trunc(sysdate)
               and tplNewMission.MIS_REQUEST_DATE <= add_months(sysdate, aPeriod)
               and nvl(tplNewMission.MIS_SERVICE_MARKER, 0) > 0 then
              CreateMission(tplNewMission);
            end if;
          end if;
        end if;
      end loop;

      -- Pour chaque machine, recherche des plans de service à terme régulier avec "Etat compteur"
      for cr_ServicePlan2 in
        (select *
           from (select   CTG.ASA_COUNTER_TYPE_ID
                        , SER.GCO_SERVICE_PLAN_ID
                        , SER.C_SERVICE_PLAN_PERIODICITY
                        , SER.SER_PERIODICITY
                        , SER.ASA_COUNTER_TYPE_S_GOOD_ID
                        , SER.SER_COUNTER_STATE *
                          nvl(SER.SER_CONVERSION_FACTOR, 1) *
                          ceil(COUNTER.CST_STATEMENT_QUANTITY /(SER.SER_COUNTER_STATE * nvl(SER.SER_CONVERSION_FACTOR, 1) ) ) SER_COUNTER_STATE
                        , COUNTER.ASA_COUNTER_ID
                        , COUNTER.CST_STATEMENT_QUANTITY
                        , SER.SER_COUNTER_STATE *
                          nvl(SER.SER_CONVERSION_FACTOR, 1) *
                          ceil(COUNTER.CST_STATEMENT_QUANTITY /(SER.SER_COUNTER_STATE * nvl(SER.SER_CONVERSION_FACTOR, 1) ) ) -
                          COUNTER.CST_STATEMENT_QUANTITY COPIES
                        , row_number() over(partition by CTG.ASA_COUNTER_TYPE_ID order by SER.SER_COUNTER_STATE *
                             nvl(SER.SER_CONVERSION_FACTOR, 1) *
                             ceil(COUNTER.CST_STATEMENT_QUANTITY /(SER.SER_COUNTER_STATE * nvl(SER.SER_CONVERSION_FACTOR, 1) ) ) -
                            COUNTER.CST_STATEMENT_QUANTITY
                         , ceil(COUNTER.CST_STATEMENT_QUANTITY /(SER.SER_COUNTER_STATE * nvl(SER.SER_CONVERSION_FACTOR, 1) ) ) ) APPLICABLE_SERVICE
                     from GCO_SERVICE_PLAN SER
                        , GCO_COMPL_DATA_EXTERNAL_ASA CEA
                        , ASA_COUNTER_TYPE_S_GOOD CTG
                        , (select *
                             from (select COU.ASA_COUNTER_TYPE_ID
                                        , CST.CST_STATEMENT_QUANTITY
                                        , CST.ASA_COUNTER_STATEMENT_ID
                                        , COU.ASA_COUNTER_ID
                                        , row_number() over(partition by COU.ASA_COUNTER_TYPE_ID order by CST.CST_STATEMENT_DATE desc
                                         , CST.CST_STATEMENT_QUANTITY) as APPLICABLE_COUNTER
                                     from ASA_COUNTER COU
                                        , ASA_COUNTER_STATEMENT CST
                                    where COU.ASA_COUNTER_ID = CST.ASA_COUNTER_ID
                                      and COU.DOC_RECORD_ID = tplInstall.DOC_RECORD_ID
                                      and CST.PAC_CUSTOM_PARTNER_ID = tplInstall.PAC_CUSTOM_PARTNER_ID
                                      and CST.C_COUNTER_STATEMENT_STATUS <> '2')
                            where APPLICABLE_COUNTER = 1) COUNTER
                    where SER.GCO_COMPL_DATA_EXTERNAL_ASA_ID = CEA.GCO_COMPL_DATA_EXTERNAL_ASA_ID
                      and CEA.GCO_GOOD_ID = tplInstall.RCO_MACHINE_GOOD_ID
                      and SER.C_ASA_SERVICE_TYPE = '1'
                      and CTG.GCO_GOOD_ID = CEA.GCO_GOOD_ID
                      and CTG.ASA_COUNTER_TYPE_S_GOOD_ID = SER.ASA_COUNTER_TYPE_S_GOOD_ID
                      and COUNTER.ASA_COUNTER_TYPE_ID = CTG.ASA_COUNTER_TYPE_ID
                 order by ASA_COUNTER_TYPE_ID)
          where APPLICABLE_SERVICE = 1) loop
        -- Réinitialisation des valeurs de la mission
        tplNewMission.GCO_SERVICE_PLAN_ID  := null;
        tplNewMission.MIS_REQUEST_DATE     := null;
        tplNewMission.MIS_SERVICE_MARKER   := null;

        -- Pour chaque plan, on vérifie qu'il n'existe aucune mission associée pour le plan de service/type de compteur
        if ExistsMissionService(aInstallID       => tplInstall.DOC_RECORD_ID
                              , aCounterTypeID   => cr_ServicePlan2.ASA_COUNTER_TYPE_ID
                              , aServicePlanId   => cr_ServicePlan2.GCO_SERVICE_PLAN_ID
                              , aServiceMarker   => cr_ServicePlan2.SER_COUNTER_STATE
                               ) = 0 then
          -- Initialisation du plan de service et du compteur
          tplNewMission.GCO_SERVICE_PLAN_ID  := cr_ServicePlan2.GCO_SERVICE_PLAN_ID;
          -- Initialisation du compteur, de la date et de la borne de service
          GetNextServiceInfo(cr_ServicePlan2.ASA_COUNTER_TYPE_ID, cr_ServicePlan2.SER_COUNTER_STATE, aPeriod, tplNewMission);

          -- Si la date de la nouvelle mission entre dans la période de génération, on peut créer la mission
          if     tplNewMission.MIS_REQUEST_DATE is not null
             and tplNewMission.MIS_REQUEST_DATE >= trunc(sysdate)
             and tplNewMission.MIS_REQUEST_DATE <= add_months(sysdate, aPeriod)
             and nvl(tplNewMission.MIS_SERVICE_MARKER, 0) > 0 then
            CreateMission(tplNewMission);
          end if;
        end if;
      end loop;

      -- Pour chaque machine, recherche des plans de service à terme régulier et "temporel"
      for cr_ServicePlan3 in
        (select ASA_COUNTER_TYPE_ID
              , GCO_SERVICE_PLAN_ID
              , NEXT_DATE
              , CML_POSITION_ID
           from (select   MAIN.*
                        , greatest(ceil(months_between(trunc(sysdate), DATE_REF) /
                                        (SER_PERIODICITY * case C_SERVICE_PLAN_PERIODICITY
                                           when 'W' then 12 / 52
                                           when 'M' then 1
                                           when 'Y' then 12
                                         end
                                        )
                                       )
                                 , 1
                                  ) SERVICE_COUNTER   -- nb de fois qu'il faut répéter la périodicité pour entre dans la période de génération
                        , case C_SERVICE_PLAN_PERIODICITY
                            when 'W' then date_ref +
                                          7 * greatest(ceil(months_between(trunc(sysdate), DATE_REF) /(SER_PERIODICITY *(12 / 52) ) ), 1) * ser_periodicity
                            when 'M' then add_months(date_ref
                                                   , greatest(ceil(months_between(trunc(sysdate), DATE_REF) /(SER_PERIODICITY * 1) ), 1) * ser_periodicity
                                                    )
                            when 'Y' then add_months(date_ref
                                                   , 12 * greatest(ceil(months_between(trunc(sysdate), DATE_REF) /(SER_PERIODICITY * 12) ), 1) * ser_periodicity
                                                    )
                          end NEXT_DATE   -- prochaine date à laquelle le service va s'appliquer
                        , row_number() over(partition by ASA_COUNTER_TYPE_ID order by case C_SERVICE_PLAN_PERIODICITY
                             when 'W' then date_ref + 7 * ceil(months_between(trunc(sysdate), DATE_REF) /(SER_PERIODICITY *(12 / 52) ) ) * ser_periodicity
                             when 'M' then add_months(date_ref, ceil(months_between(trunc(sysdate), DATE_REF) /(SER_PERIODICITY * 1) ) * ser_periodicity)
                             when 'Y' then add_months(date_ref, 12 * ceil(months_between(trunc(sysdate), DATE_REF) /(SER_PERIODICITY * 12) ) * ser_periodicity)
                           end) NBCOUNT   -- premier service à appliquer par type de compteur selon la date d'application
                     from (select CTG.ASA_COUNTER_TYPE_ID
                                , SER.GCO_SERVICE_PLAN_ID
                                , SER.C_SERVICE_PLAN_PERIODICITY
                                , SER.SER_PERIODICITY
                                , nvl( (select max(MIS.MIS_REQUEST_DATE)
                                          from ASA_MISSION MIS
                                             , ASA_COUNTER COU
                                         where MIS.ASA_MACHINE_ID = tplInstall.DOC_RECORD_ID
                                           and MIS.PAC_CUSTOM_PARTNER_ID = tplInstall.PAC_CUSTOM_PARTNER_ID
                                           and MIS.ASA_COUNTER_ID = COU.ASA_COUNTER_ID
                                           and COU.ASA_COUNTER_TYPE_ID = CTG.ASA_COUNTER_TYPE_ID
                                           and MIS.GCO_SERVICE_PLAN_ID = SER.GCO_SERVICE_PLAN_ID)
                                    , CONTRACT.CPO_BEGIN_CONTRACT_DATE
                                     ) DATE_REF   -- Date référence = date de la dernière mission pour ce service (ou date début contrat)
                                , CONTRACT.CML_POSITION_ID
                             from GCO_SERVICE_PLAN SER
                                , GCO_COMPL_DATA_EXTERNAL_ASA CEA
                                , ASA_COUNTER_TYPE_S_GOOD CTG
                                , (select   CMD.CMD_INITIAL_STATEMENT
                                          , CPO.CPO_BEGIN_CONTRACT_DATE
                                          , COU.ASA_COUNTER_TYPE_ID
                                          , COU.DOC_RECORD_ID
                                          , CPO.CML_POSITION_ID
                                       from CML_DOCUMENT CCO
                                          , CML_POSITION CPO
                                          , CML_POSITION_MACHINE CPM
                                          , CML_POSITION_MACHINE_DETAIL CMD
                                          , ASA_COUNTER COU
                                      where CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
                                        and CPO.CML_POSITION_ID = CPM.CML_POSITION_ID
                                        and CPM.DOC_RCO_MACHINE_ID = tplInstall.DOC_RECORD_ID   -- lié au moins à un contrat
                                        and CPO.C_CML_POS_STATUS in('02', '03')   -- actif
                                        and CCO.PAC_CUSTOM_PARTNER_ID = tplInstall.PAC_CUSTOM_PARTNER_ID   -- sur le client de la base instalée
                                        and CPO.CPO_END_CONTRACT_DATE >= add_months(trunc(sysdate), 2)   -- ne se terminant pas avant 2 mois
                                        and CPO.CPO_RESILIATION_DATE is null
                                        and CPO.CPO_SUSPENSION_DATE is null
                                        and CMD.CML_POSITION_MACHINE_ID = CPM.CML_POSITION_MACHINE_ID
                                        and CMD.ASA_COUNTER_ID = COU.ASA_COUNTER_ID
                                        and COU.DOC_RECORD_ID = tplInstall.DOC_RECORD_ID
                                   order by CPO.CPO_BEGIN_CONTRACT_DATE asc) CONTRACT   -- liste des contrats associés
                            where SER.GCO_COMPL_DATA_EXTERNAL_ASA_ID = CEA.GCO_COMPL_DATA_EXTERNAL_ASA_ID
                              and CEA.GCO_GOOD_ID = tplInstall.RCO_MACHINE_GOOD_ID
                              and SER.C_ASA_SERVICE_TYPE = '1'
                              and CTG.GCO_GOOD_ID = CEA.GCO_GOOD_ID
                              and SER.ASA_COUNTER_TYPE_S_GOOD_ID is null
                              and CONTRACT.ASA_COUNTER_TYPE_ID = CTG.ASA_COUNTER_TYPE_ID) MAIN
                 order by MAIN.ASA_COUNTER_TYPE_ID
                        , NEXT_DATE
                        , SERVICE_COUNTER) MAIN2
          where NBCOUNT = 1) loop
        --initialisation de la position de contrat
        tplNewMission.CML_POSITION_ID      := cr_ServicePlan3.CML_POSITION_ID;
        -- Réinitialisation des valeurs de la mission
        tplNewMission.GCO_SERVICE_PLAN_ID  := null;
        tplNewMission.MIS_REQUEST_DATE     := null;
        tplNewMission.MIS_SERVICE_MARKER   := null;

        -- Pour chaque plan, on vérifie qu'il n'existe aucune mission associée pour le plan de service/date
        if ExistsMissionService(aInstallID       => tplInstall.DOC_RECORD_ID
                              , aCounterTypeID   => cr_ServicePlan3.ASA_COUNTER_TYPE_ID
                              , aServicePlanId   => cr_ServicePlan3.GCO_SERVICE_PLAN_ID
                              , aServiceDate     => cr_ServicePlan3.NEXT_DATE
                               ) = 0 then
          -- Initialisation du plan de service et du compteur
          tplNewMission.GCO_SERVICE_PLAN_ID  := cr_ServicePlan3.GCO_SERVICE_PLAN_ID;
          -- Initialisation du compteur et de la date
          tplNewMission.ASA_COUNTER_ID       := ASA_COUNTER_FUNCTIONS.GetCounter(cr_ServicePlan3.ASA_COUNTER_TYPE_ID, tplInstall.DOC_RECORD_ID);
          tplNewMission.MIS_REQUEST_DATE     := cr_ServicePlan3.NEXT_DATE;

          -- Si la date de la nouvelle mission entre dans la période de génération, on peut créer la mission
          if     tplNewMission.MIS_REQUEST_DATE is not null
             and tplNewMission.MIS_REQUEST_DATE >= trunc(sysdate)
             and tplNewMission.MIS_REQUEST_DATE <= add_months(sysdate, aPeriod) then
            CreateMission(tplNewMission);
          end if;
        end if;
      end loop;

      exit when cr_Install%notfound;
    end loop;

    close cr_Install;
  end GenerateServiceMissions;

  /**
  * Description
  *    Fonction qui vérifie l'existence de missions associées à un trio Installation/Compteur/Plan de service
  */
  function ExistsMissionService(
    aInstallID     in DOC_RECORD.DOC_RECORD_ID%type
  , aCounterTypeID in ASA_COUNTER_TYPE.ASA_COUNTER_TYPE_ID%type
  , aServicePlanId in GCO_SERVICE_PLAN.GCO_SERVICE_PLAN_ID%type
  , aServiceDate   in ASA_MISSION.MIS_REQUEST_DATE%type default null
  , aServiceMarker in ASA_MISSION.MIS_SERVICE_MARKER%type default null
  )
    return number
  is
    vResult number(1);
  begin
    select least(count(*), 1)
      into vResult
      from ASA_MISSION MIS
         , ASA_COUNTER COU
     where MIS.ASA_COUNTER_ID = COU.ASA_COUNTER_ID
       and MIS.ASA_MACHINE_ID = aInstallID
       and COU.ASA_COUNTER_TYPE_ID = aCounterTypeID
       and MIS.GCO_SERVICE_PLAN_ID = aServicePlanId
       and (   MIS.MIS_REQUEST_DATE = aServiceDate
            or (aServiceDate is null) )
       and (   MIS.MIS_SERVICE_MARKER = aServiceMarker
            or (aServiceMarker is null) );

    return vResult;
  end ExistsMissionService;

  /**
  * Description
  *   Retourne la date de la nouvelle mission
  */
  function GetMissionNextDate(
    aInstallID    in DOC_RECORD.DOC_RECORD_ID%type
  , aPartnerID    in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPeriodicType in GCO_SERVICE_PLAN.C_SERVICE_PLAN_PERIODICITY%type
  , aPeriodicity  in GCO_SERVICE_PLAN.SER_PERIODICITY%type
  )
    return date
  is
    cursor cr_Contract
    is
      select   case aPeriodicType
                 when 'W' then CPO.CPO_BEGIN_CONTRACT_DATE + aPeriodicity * 7
                 when 'M' then add_months(CPO.CPO_BEGIN_CONTRACT_DATE, aPeriodicity)
                 when 'Y' then add_months(CPO.CPO_BEGIN_CONTRACT_DATE, aPeriodicity * 12)
                 else null
               end NEW_MISSION_DATE
             , CPO.CML_POSITION_ID
          from CML_DOCUMENT CCO
             , CML_POSITION CPO
             , CML_POSITION_MACHINE CPM
         where CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
           and CPO.CML_POSITION_ID = CPM.CML_POSITION_ID
           and CPM.DOC_RCO_MACHINE_ID = aInstallID   -- lié au moins à un contrat
           and CPO.C_CML_POS_STATUS in('02', '03')   -- actif
           and CCO.PAC_CUSTOM_PARTNER_ID = aPartnerID   -- sur le client de la base instalée
           and CPO.CPO_END_CONTRACT_DATE >= add_months(trunc(sysdate), 2)   -- ne se terminant pas avant 2 mois
           and CPO.CPO_RESILIATION_DATE is null
           and CPO.CPO_SUSPENSION_DATE is null
      order by CPO.CPO_BEGIN_CONTRACT_DATE asc;

    tplContract cr_Contract%rowtype;
  begin
    open cr_Contract;

    fetch cr_Contract
     into tplContract;

    close cr_Contract;

    return trunc(tplContract.NEW_MISSION_DATE);
  end GetMissionNextDate;

  /**
  * Description
  *   Recherche du compteur, de la date et de la borne de service
  */
  procedure GetNextServiceInfo(
    aCounterTypeID in     ASA_COUNTER_TYPE.ASA_COUNTER_TYPE_ID%type
  , aServiceQty    in     GCO_SERVICE_PLAN.SER_COUNTER_STATE%type
  , aPeriod        in     number
  , tplMission     in out ASA_MISSION%rowtype
  )
  is
    cursor cr_Counter
    is
      select   COU.ASA_COUNTER_ID
             , CST.CST_STATEMENT_QUANTITY
             , CST.CST_STATEMENT_DATE
          from ASA_COUNTER COU
             , ASA_COUNTER_STATEMENT CST
         where COU.DOC_RECORD_ID = tplMission.DOC_RECORD_ID
           and COU.ASA_COUNTER_TYPE_ID = aCounterTypeID
           and CST.ASA_COUNTER_ID = COU.ASA_COUNTER_ID
           and CST.PAC_CUSTOM_PARTNER_ID = tplMission.PAC_CUSTOM_PARTNER_ID
           and CST.C_COUNTER_STATEMENT_STATUS <> '2'   -- tous les états au statut non "refusé"
      order by CST.CST_STATEMENT_DATE desc;

    tplCounter  cr_Counter%rowtype;
    vAvgQty     ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type;   -- moyenne de consommation
    vNbMonth    number;   -- nombre de mois pour atteindre la prochaine borne de service

    cursor cr_Contract(
      aInstallID DOC_RECORD.DOC_RECORD_ID%type
    , aPartnerID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
    , aCounterID ASA_COUNTER.ASA_COUNTER_ID%type
    )
    is
      select   CMD.CMD_INITIAL_STATEMENT
             , CPO.CPO_BEGIN_CONTRACT_DATE
             , CPO.CML_POSITION_ID
          from CML_DOCUMENT CCO
             , CML_POSITION CPO
             , CML_POSITION_MACHINE CPM
             , CML_POSITION_MACHINE_DETAIL CMD
             , ASA_COUNTER COU
         where CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
           and CPO.CML_POSITION_ID = CPM.CML_POSITION_ID
           and CPM.DOC_RCO_MACHINE_ID = aInstallID   -- lié au moins à un contrat
           and CPO.C_CML_POS_STATUS in('02', '03')   -- actif
           and CCO.PAC_CUSTOM_PARTNER_ID = aPartnerID   -- sur le client de la base instalée
           and CPO.CPO_END_CONTRACT_DATE >= add_months(trunc(sysdate), 2)   -- ne se terminant pas avant 2 mois
           and CPO.CPO_RESILIATION_DATE is null
           and CPO.CPO_SUSPENSION_DATE is null
           and CMD.CML_POSITION_MACHINE_ID = CPM.CML_POSITION_MACHINE_ID
           and CMD.ASA_COUNTER_ID = aCounterID
           and COU.DOC_RECORD_ID = aInstallID
      order by CPO.CPO_BEGIN_CONTRACT_DATE asc;

    tplContract cr_Contract%rowtype;
  begin
    -- Recherche du compteur
    open cr_Counter;

    fetch cr_Counter
     into tplCounter;

    close cr_Counter;

    -- si un compteur a été trouvé pour ce client
    if tplCounter.ASA_COUNTER_ID > 0 then
      -- récupération des infos du dernier contrat (état compteur, date début contrat)
      open cr_Contract(tplMission.DOC_RECORD_ID, tplMission.PAC_CUSTOM_PARTNER_ID, tplCounter.ASA_COUNTER_ID);

      fetch cr_Contract
       into tplContract;

      close cr_Contract;

      --initialisation du contrat
      tplMission.CML_POSITION_ID  := tplContract.CML_POSITION_ID;
      -- Initialisation du compteur
      tplMission.ASA_COUNTER_ID   := tplCounter.ASA_COUNTER_ID;

      -- si l'état compteur est inférieur à la borne du service
      if tplCounter.CST_STATEMENT_QUANTITY < aServiceQty then
        -- Initialisation de la borne de service
        tplMission.MIS_SERVICE_MARKER  := aServiceQty;
        -- Calcul de la moyenne de consommation pour déterminer la date du prochain service
        vAvgQty                        :=
          ASA_COUNTER_FUNCTIONS.CalcCounterAvg(tplMission.ASA_COUNTER_ID
                                             , tplMission.PAC_CUSTOM_PARTNER_ID
                                             , tplContract.CMD_INITIAL_STATEMENT
                                             , tplContract.CPO_BEGIN_CONTRACT_DATE
                                             , 12   -- calcul de la moyenne sur les 12 derniers mois
                                              );

        -- Calcul de la date du service selon moyenne de consommation sur les aPeriod derniers mois
        if vAvgQty > 0 then
          vNbMonth  := (aServiceQty - tplCounter.CST_STATEMENT_QUANTITY) / vAvgQty;
        else
          vNbMonth  := 0;
        end if;

        tplMission.MIS_REQUEST_DATE    := trunc(tplCounter.CST_STATEMENT_DATE + vNbMonth * 30);
      end if;
    end if;
  end GetNextServiceInfo;

  /**
  * Description
  *   Création de la mission
  */
  procedure CreateMission(tplMission in out ASA_MISSION%rowtype)
  is
    cursor crPartnerInfo(aPAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
    is
      select   ASF.ACS_FINANCIAL_CURRENCY_ID
             , CUS.PAC_PAYMENT_CONDITION_ID
             , ADR.PC_LANG_ID
          from ACS_AUX_ACCOUNT_S_FIN_CURR ASF
             , PAC_CUSTOM_PARTNER CUS
             , PAC_ADDRESS ADR
             , DIC_ADDRESS_TYPE DAD
         where ASF.ACS_AUXILIARY_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID
           and ADR.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and ADR.DIC_ADDRESS_TYPE_ID = DAD.DIC_ADDRESS_TYPE_ID
           and DAD.DAD_DEFAULT = 1
      order by ASF.ASC_DEFAULT desc;

    tplPartnerInfo crPartnerInfo%rowtype;
    tplMissionType ASA_MISSION_TYPE%rowtype;
    vNumberingID   ASA_MISSION_TYPE.MIT_NUMBERING_ID%type;
  begin
    -- Informations du type de mission
    select *
      into tplMissionType
      from ASA_MISSION_TYPE
     where ASA_MISSION_TYPE_ID = tplMission.ASA_MISSION_TYPE_ID;

    -- Nouvel ID de mission
    select INIT_ID_SEQ.nextval
      into tplMission.ASA_MISSION_ID
      from dual;

    -- Statut "provisoire" si le type de mission l'autorise, sinon statut "confirmée"
    if tplMissionType.MIT_TEMPORARY = 1 then
      tplMission.C_ASA_MIS_STATUS  := '00';
    else
      tplMission.C_ASA_MIS_STATUS  := '01';
    end if;

    -- Information relative au client
    if tplMission.PAC_CUSTOM_PARTNER_ID is not null then
      open crPartnerInfo(tplMission.PAC_CUSTOM_PARTNER_ID);

      fetch crPartnerInfo
       into tplPartnerInfo;

      close crPartnerInfo;
    end if;

    -- Client facturation du contrat associé
    if tplMission.CML_POSITION_ID is not null then
      select max(nvl(CCO.PAC_CUSTOM_PARTNER_ACI_ID, nvl(CUS.PAC_PAC_THIRD_1_ID, CCO.PAC_CUSTOM_PARTNER_ID) ) )
        into tplMission.PAC_CUSTOM_PARTNER_ACI_ID
        from CML_POSITION CPO
           , CML_DOCUMENT CCO
           , PAC_CUSTOM_PARTNER CUS
       where CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
         and CPO.CML_POSITION_ID = tplMission.CML_POSITION_ID
         and CUS.PAC_CUSTOM_PARTNER_ID = CCO.PAC_CUSTOM_PARTNER_ID;
    end if;

    -- Création de la mission
    insert into ASA_MISSION
                (ASA_MISSION_ID
               , ASA_MISSION_TYPE_ID
               , MIS_NUMBER
               , C_ASA_MIS_STATUS
               , PAC_CUSTOM_PARTNER_ID
               , PAC_CUSTOM_PARTNER_ACI_ID
               , CML_POSITION_ID
               , PC_LANG_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , PAC_PAYMENT_CONDITION_ID
               , ASA_MACHINE_ID
               , PAC_DEPARTMENT_ID
               , PAC_ADDRESS_ID
               , MIS_LOCATION_COMMENT1
               , MIS_LOCATION_COMMENT2
               , MIS_DESCRIPTION
               , MIS_REQUEST_DATE
               , ASA_COUNTER_ID
               , GCO_SERVICE_PLAN_ID
               , MIS_SERVICE_MARKER
               , MIS_ACCOMPLISHED
               , MIS_NON_BILLABLE
               , A_DATECRE
               , A_IDCRE
                )
         values (tplMission.ASA_MISSION_ID
               , tplMission.ASA_MISSION_TYPE_ID
               , 'auto_' || to_char(tplMission.ASA_MISSION_ID)
               , tplMission.C_ASA_MIS_STATUS
               , tplMission.PAC_CUSTOM_PARTNER_ID
               , tplMission.PAC_CUSTOM_PARTNER_ACI_ID
               , tplMission.CML_POSITION_ID
               , tplPartnerInfo.PC_LANG_ID
               , tplPartnerInfo.ACS_FINANCIAL_CURRENCY_ID
               , tplPartnerInfo.PAC_PAYMENT_CONDITION_ID
               , tplMission.DOC_RECORD_ID
               , tplMission.PAC_DEPARTMENT_ID
               , tplMission.PAC_ADDRESS_ID
               , tplMission.MIS_LOCATION_COMMENT1
               , tplMission.MIS_LOCATION_COMMENT2
               , tplMissionType.MIT_MISSION_DESCR
               , tplMission.MIS_REQUEST_DATE
               , tplMission.ASA_COUNTER_ID
               , tplMission.GCO_SERVICE_PLAN_ID
               , nvl(tplMission.MIS_SERVICE_MARKER, 0)
               , 0   -- MIS_ACCOMPLISHED
               , tplMissionType.MIT_NON_BILLABLE
               , sysdate
               , pcs.PC_I_LIB_SESSION.GetUserIni
                );

    -- Numérotation automatique selon méthode définie sur le type de mission
    update ASA_MISSION
       set MIS_NUMBER = GCO_GOOD_NUMBERING_FUNCTIONS.AutoNumbering(tplMissionType.MIT_NUMBERING_ID, tplMission.ASA_MISSION_ID)
     where ASA_MISSION_ID = tplMission.ASA_MISSION_ID;
  end CreateMission;
end ASA_MISSION_GENERATE;
