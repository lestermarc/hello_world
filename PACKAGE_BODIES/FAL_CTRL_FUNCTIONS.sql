--------------------------------------------------------
--  DDL for Package Body FAL_CTRL_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_CTRL_FUNCTIONS" 
is
  /***
  *  Fonction qui renvoie une description courte d'un produit sinon longue dans la langue de la companie
  *     agco_good_id          : Produit
  *     apc_lang_id           : Langue
  *     ac_description_type   : Type de description
  */
  function getdescription(agco_good_id in number, apc_lang_id in number, ac_description_type in varchar2)
    return varchar2
  is
    -- Curseurs
    cursor cursor_descr(agoodid in number, apclangid in number, acdescriptiontype in varchar2)
    is
      select   nvl(des_short_description, des_long_description) description
          from gco_description
         where gco_good_id = agoodid
           and pc_lang_id = apclangid
           and (   c_description_type = acdescriptiontype
                or c_description_type = '01')
      order by c_description_type asc;

    -- Variables
    cursor_descr_tuple cursor_descr%rowtype;
  begin
    open cursor_descr(agco_good_id, apc_lang_id, ac_description_type);

    fetch cursor_descr
     into cursor_descr_tuple;

    if cursor_descr%notfound then
      return '';
    else
      return cursor_descr_tuple.description;
    end if;

    close cursor_descr;
  end getdescription;

  /***
  *  Fonction qui renvoie la capacité en heure pour une période donnée.
  *     aDATE : format YYYY.IW ou YYYY.MM -> Année.semaine ou Année.mois.
  *     aPeriode : 1 = Mois ; 2 = Semaine ; 3 = Jours
  *     aFAL_FACTORY_FLOOR_ID : Atelier dont on veut calculer la capacité.
  *     avec une transaction autonome pour que cette fonction puisse être utilisée dans un SELECT
  */
  function calculcapacity(adate date, aperiode number, afal_factory_floor_id fal_factory_floor.fal_factory_floor_id%type)
    return number
  is
    afloor_pac_schedule_id pac_schedule.pac_schedule_id%type;
    aStartDate             date;
    aEndDATE               date;
    aTime                  number;
    aResourceCapacity      PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAPACITY%type;
    aResourceCapQty        PAC_SCHEDULE_PERIOD.SCP_RESOURCE_CAP_IN_QTY%type;
    pragma autonomous_transaction;
  begin
    -- Recherche des dates de début et de fin de la période.
    -- Pour le mois
    if aPeriode = 1 then
      aStartDate  := last_day(add_months(aDate, -1) ) + 1;
      aEndDate    := last_day(aDate);
    -- Pour la semaine
    elsif aperiode = 2 then
      aStartDate  := next_day(aDate, 'MONDAY') - 7;
      aEndDate    := next_day(aDate, 'MONDAY') - 1;
    -- Pour le jour
    elsif aperiode = 3 then
      aStartDate  := aDate - 1;
      aEndDate    := aDate + 1;
    else
      return 0;
    end if;

    -- Calcul de la capacité
    PAC_I_LIB_SCHEDULE.CalcOpenTimeBetween(aTime
                                         , aResourceCapacity
                                         , aResourceCapQty
                                         , FAL_SCHEDULE_FUNCTIONS.getfloorcalendar(afal_factory_floor_id)
                                         , aStartDate
                                         , aEndDate
                                         , 'FACTORY_FLOOR'
                                         , afal_factory_floor_id
                                          );
    commit;
    return aResourceCapacity;
  exception
    when others then
      return 0;
  end calculcapacity;

  /**
  * procedure : GetFalFactoryFloorOccupancy
  * Description : Calcul des taux d'occupation des atelier, utilisé via le portail
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param  aSessionId     Session oracle
  */
  function GetFalFactoryFloorOccupancy(aDate date)
    return TRatingLoads pipelined
  is
    cursor crFactoryBlock
    is
      select fal_factory_floor_id
           , pac_schedule_id
           , fac_resource_number
        from fal_factory_floor
       where fac_is_block = 1
         and fac_out_of_order = 0;

    cursor crBlocksMachines(aBlockID number)
    is
      select fal_factory_floor_id
           , pac_schedule_id
           , fac_resource_number
        from fal_factory_floor
       where fal_fal_factory_floor_id = aBlockID
         and fac_out_of_order = 0;

    TabRatingLoad          TRatingLoads;
    ldCurrentWeekStart     date;
    ldCurrentWeekEnd       date;
    cfgDOC_DELAY_WEEKSTART varchar2(10);
    lvWeekStartDay         varchar2(10);
    tabindex               integer;
    lnTotalCapacity        number;
    lnTotalWorkLoad        number;
    blnBlockWithMachines   boolean;

    -- Calcul de la charge réelle entre deux dates
    function GetRealWorkLoad(aFal_Factory_Floor_Id number, aStartDate date, aEndDate date)
      return number
    is
      lnRealWorkLoad number;
    begin
      select nvl(sum(nvl(flp_adjusting_time, 0) + nvl(flp_work_time, 0) ), 0)
        into lnRealWorkLoad
        from fal_lot_progress flp
       where fal_factory_floor_id = afal_factory_floor_id
         and flp_date1 between aStartDate and aEndDate;

      return lnRealWorkLoad;
    end;

    -- Calcul de la charge prévisionelle entre deux dates
    function GetPlannedWorkLoad(aFal_Factory_Floor_Id number, aStartDate date, aEndDate date)
      return number
    is
      lnPlannedWorkLoad number;
    begin
      select nvl(sum(nvl(scs_adjusting_time, 0) + nvl(scs_work_time, 0) ), 0)
        into lnPlannedWorkLoad
        from fal_task_link ftl
       where fal_factory_floor_id = afal_factory_floor_id
         and tal_begin_plan_date between aStartDate and aEndDate;

      return lnPlannedWorkLoad;
    end;
  begin
    -- Recherche des bornes des Trois semaines à afficher
    cfgDOC_DELAY_WEEKSTART  := PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART');
    lvWeekStartDay          :=
      case cfgDOC_DELAY_WEEKSTART
        when 1 then 'SUNDAY'
        when 2 then 'MONDAY'
        when 3 then 'TUESDAY'
        when 4 then 'WEDNESDAY'
        when 5 then 'THURSDAY'
        when 6 then 'FRIDAY'
        when 7 then 'SATURDAY'
        else 'SUNDAY'
      end;
    -- Parcours des ilots et machines et insertion des données dans le tableau
    -- pour les 5 semaines autour de la semaine courante
    ldCurrentWeekStart      := next_day(trunc(aDate), lvWeekStartDay) - 3 * 7;
    ldCurrentWeekend        := ldCurrentWeekStart + 7;
    tabindex                := 0;
    TabRatingLoad           := TRatingLoads();

    loop
      lnTotalCapacity                 := 0;
      lnTotalWorkLoad                 := 0;
      -- Sortie à la semaine correspondant au paramètre + 3 semaines.
      exit when ldCurrentWeekStart > next_day(trunc(aDate), lvWeekStartDay) + 1 * 7;
      tabindex                        := tabindex + 1;

      -- Parcours des îlots
      for tplFactoryBlock in crFactoryBlock loop
        blnBlockWithMachines  := false;

        -- Parcours des machines
        for tplBlocksMachines in crBlocksMachines(tplFactoryBlock.fal_factory_floor_id) loop
          blnBlockWithMachines  := true;
          -- Calcul de la capacité
          lnTotalCapacity       :=
            lnTotalCapacity +
            tplBlocksMachines.fac_resource_number *
            PAC_I_LIB_SCHEDULE.GetOpenTimeBetween(ldCurrentWeekStart
                                                , ldCurrentWeekEnd
                                                , tplBlocksMachines.pac_schedule_id
                                                , null
                                                , 'FACTORY_FLOOR'
                                                , tplBlocksMachines.fal_factory_floor_id
                                                 );

          -- Calcul de la charge
          if ldCurrentWeekEnd < aDate then
            lnTotalWorkLoad  := lnTotalWorkLoad + GetRealWorkLoad(tplBlocksMachines.fal_factory_floor_id, ldCurrentWeekStart, ldCurrentWeekEnd);
          elsif ldCurrentWeekStart > aDate then
            lnTotalWorkLoad  := lnTotalWorkLoad + GetPlannedWorkLoad(tplBlocksMachines.fal_factory_floor_id, ldCurrentWeekStart, ldCurrentWeekEnd);
          else
            lnTotalWorkLoad  := lnTotalWorkLoad + GetRealWorkLoad(tplBlocksMachines.fal_factory_floor_id, ldCurrentWeekStart, aDate);
            lnTotalWorkLoad  := lnTotalWorkLoad + GetPlannedWorkLoad(tplBlocksMachines.fal_factory_floor_id, aDate, ldCurrentWeekEnd);
          end if;
        end loop;

        -- l'îlot n'a pas de machines, le calcul se fait alors sur l'îlot
        if blnBlockWithMachines = false then
          -- Calcul de la capacité
          lnTotalCapacity  :=
            lnTotalCapacity +
            tplFactoryBlock.fac_resource_number *
            PAC_I_LIB_SCHEDULE.GetOpenTimeBetween(ldCurrentWeekStart
                                                , ldCurrentWeekEnd
                                                , tplFactoryBlock.pac_schedule_id
                                                , null
                                                , 'FACTORY_FLOOR'
                                                , tplFactoryBlock.fal_factory_floor_id
                                                 );

          -- Calcul de la charge
          if ldCurrentWeekEnd < aDate then
            lnTotalWorkLoad  := lnTotalWorkLoad + GetRealWorkLoad(tplFactoryBlock.fal_factory_floor_id, ldCurrentWeekStart, ldCurrentWeekEnd);
          elsif ldCurrentWeekStart > aDate then
            lnTotalWorkLoad  := lnTotalWorkLoad + GetPlannedWorkLoad(tplFactoryBlock.fal_factory_floor_id, ldCurrentWeekStart, ldCurrentWeekEnd);
          else
            lnTotalWorkLoad  := lnTotalWorkLoad + GetRealWorkLoad(tplFactoryBlock.fal_factory_floor_id, ldCurrentWeekStart, aDate);
            lnTotalWorkLoad  := lnTotalWorkLoad + GetPlannedWorkLoad(tplFactoryBlock.fal_factory_floor_id, aDate, ldCurrentWeekEnd);
          end if;
        end if;
      end loop;

      -- Ajout dans le tableau
      TabRatingLoad.extend;
      TabRatingLoad(tabindex).V_WEEK  := DOC_DELAY_FUNCTIONS.DATETOWEEK(ldCurrentWeekStart);

      if nvl(lnTotalCapacity, 0) = 0 then
        TabRatingLoad(tabindex).V_RATING_LOAD  := 100;
      else
        TabRatingLoad(tabindex).V_RATING_LOAD  := (nvl(lnTotalWorkLoad, 0) / lnTotalCapacity) * 100;
      end if;

      -- Incrément de semaine
      ldCurrentWeekStart              := ldCurrentWeekStart + 7;
      ldCurrentWeekEnd                := ldCurrentWeekStart + 7;
    end loop;

    -- Envoi des données
    if TabRatingLoad.count > 0 then
      for tabIndex in TabRatingLoad.first .. TabRatingLoad.last loop
        pipe row(TabRatingLoad(tabIndex) );
      end loop;
    end if;
  end;
end;
