--------------------------------------------------------
--  DDL for Package Body WEB_HRM_PORTAL_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_HRM_PORTAL_FCT" 
as

/******************************************************************************
   NAME:       WEB_HRM_PORTAL
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        02.07.2008             1. Created this package.
******************************************************************************/

  ------------------------------------------------------------------------------
  -- Internal Types and records
  ------------------------------------------------------------------------------
  SUBTYPE DicIdType IS dic_sch_period_1.dic_sch_period_1_id%TYPE;
  SUBTYPE ColorCodeType IS VARCHAR(256);

  TYPE ColorCodeRec IS RECORD (
     ID         DicIdType,
     COLOR      ColorCodeType,
     CODE       NUMBER,
     DESCR      pcs.pc_dico.dictrans%type,
     IS_VISIBLE NUMBER
  );

  TYPE ColorCodeAssoc IS TABLE OF ColorCodeRec INDEX BY DicIdType;

  -- type for special char table
  TYPE SpecialCharRec IS RECORD (
      pattern   VARCHAR2(4)
    , replaceBy VARCHAR2(2)
  );
  TYPE specialChar IS TABLE OF specialCharRec INDEX BY BINARY_INTEGER;

  /* Type de calculation de l'occupation d'une absence */
  gcn_computied_height_duration CONSTANT INTEGER := 0;
  gcn_computied_height_am_pm CONSTANT INTEGER := 1;
  gcn_computied_height INTEGER := gcn_computied_height_am_pm;

  /* Tableau associatif entre clé code absence et couleur */
  gassoc_color_code ColorCodeAssoc;
  /* Code pour un jour avec plusieurs absences */
  gs_code_more_absence DicIdType := '';
  /* Code pour un jour férié */
  gs_code_holiday DicIdType := '';
  /* Code indiquant une erreur */
  gs_code_failure DicIdType := '';
  /* Table conversion des caractères JSON */
  gtab_special_chars specialChar;
  /* Drapeau indiquant que le module est initialisé */
  gn_initialized NUMBER(1) := 0;

  /**
   * Voir spécification
   */
  Function formatDate(
     dateArg IN DATE
   , format IN VARCHAR2
   , nls IN VARCHAR2 := 'NLS_DATE_LANGUAGE=American'
  )
     RETURN VARCHAR2
  is
  begin
    return to_char(dateArg, format, nls);
  end formatDate;

  /**
   *
   */
  function internalCalendarRequest (
    p_persons AgendaPersonTable
  , p_from_date in date
  , p_to_date in date
  , pn_diplay_no_working_day NUMBER := 0
  , msg out nocopy varchar2
  )
    return number
  is
    interro_number   constant pac_schedule_interro.sci_interro_number%type   := to_char(sysdate, 'HH24MISS');
    vn_hrm_person_id hrm_person.hrm_person_id%TYPE;
    vn_schedule_id   pac_schedule.pac_schedule_id%TYPE;
    vn_row_count     number;
  begin
     IF p_from_date > p_to_date THEN
       msg := 'From Date > To Date';
       RETURN WEB_FUNCTIONS.RETURN_ERROR;
     END IF;

    delete from pac_schedule_interro;

    /* Si persons est vide retourne immédiatement ayant vidé pac_schedule_interro */
    IF p_persons.Count() = 0 THEN
      msg := '0';
      return WEB_FUNCTIONS.RETURN_OK;
    END IF;
    for i in p_persons.first..p_persons.last  loop
      vn_hrm_person_id := p_persons(i).id;
      vn_schedule_id := web_hrm_portal_fct.get_schedule_id(vn_hrm_person_id);
      insert into pac_schedule_interro
                  (pac_schedule_interro_id
                 , sci_interro_number
                 , pac_schedule_period_id
                 , pac_schedule_id
                 , hrm_person_id
                 , c_day_of_week
                 , dic_sch_period_1_id
                 , dic_sch_period_2_id
                 , sci_start_time
                 , sci_end_time
                 , scp_open_time
                 , scp_close_time
                 , scp_date
                 , scp_comment
                 , scp_nonworking_day
                 , a_datecre
                 , a_datemod
                 , a_idcre
                 , a_idmod
                 , a_confirm
                  )
          (select init_id_seq.nextval
                , interro_number
                , rslt.pac_schedule_period_id
                , rslt.pac_schedule_id
                , rslt.hrm_person_id
                , rslt.c_day_of_week
                , rslt.dic_sch_period_1_id
                , rslt.dic_sch_period_2_id
                , rslt.sci_start_time
                , rslt.sci_stop_time
                , rslt.scp_open_time
                , rslt.scp_close_time
                , rslt.day_date
                , rslt.scp_comment
                , rslt.scp_nonworking_day
                , rslt.a_datecre
                , rslt.a_datemod
                , rslt.a_idcre
                , rslt.a_idmod
                , rslt.wup_status
            from ( with
                     /* Enumeration des dates dans la période recherchée */
                     days as
                     (select trunc(p_from_date - 1) + num.no day_date
                           , formatDate(trunc(p_from_date - 1) + num.no, 'DY') day_text
                        from pcs.pc_number num
                       where num.no <=(p_to_date - p_from_date + 1) )
                     ,
                     /* Les rdv d'une personne */
                     schedule_period as
                     (select pac_schedule_period_id
                           , pac_schedule_id
                           , c_day_of_week
                           , dic_sch_period_1_id
                           , dic_sch_period_2_id
                           , scp_open_time
                           , scp_close_time
                           , scp_comment
                           , scp_nonworking_day
                           , scp_date
                           , hrm_person_id
                           , a_datecre
                           , a_datemod
                           , a_idcre
                           , a_idmod
                           , 2 /*web_upd_data_fct.s_validated*/ wup_status
                        from pac_schedule_period
                      where hrm_person_id = vn_hrm_person_id
                        and ((scp_date between p_from_date and p_to_date) or
                             (not c_day_of_week is null)))
                     ,
                     /* Les rdv d'une personne en attente de validation */
                     upd_data_schedule_period as
                     (select pac_schedule_period_id
                           , pac_schedule_id
                           , day_of_week
                           , dic_sch_period_1_id
                           , dic_sch_period_2_id
                           , open_time
                           , close_time
                           , scp_comment
                           , scp_nonworking_day
                           , scp_date
                           , hrm_person_id
                           , null as a_datecre
                           , a_datemod
                           , null as a_idcre
                           , a_idmod
                           , wup_status
                        from table(WEB_UPD_DATA_FCT.GET_WEB_UPD_DATA_PAC_SCH(vn_hrm_person_id, p_from_date, p_to_date)))
                     ,
                     /* Récupère tous les rdv par date */
                     rdv_date as
                     (select days.day_date
                           , select_rdv_date.*
                       from (select pac_schedule_period_id
                                  , pac_schedule_id
                                  , c_day_of_week
                                  , dic_sch_period_1_id
                                  , dic_sch_period_2_id
                                  , scp_open_time
                                  , scp_close_time
                                  , scp_comment
                                  , scp_nonworking_day
                                  , scp_date
                                  , hrm_person_id
                                  , a_datecre
                                  , a_datemod
                                  , a_idcre
                                  , a_idmod
                                  , 2 /*web_upd_data_fct.s_validated*/ wup_status
                               from schedule_period
                              union all
                             select pac_schedule_period_id
                                  , pac_schedule_id
                                  , day_of_week
                                  , dic_sch_period_1_id
                                  , dic_sch_period_2_id
                                  , open_time
                                  , close_time
                                  , scp_comment
                                  , scp_nonworking_day
                                  , scp_date
                                  , hrm_person_id
                                  , null as a_datecre
                                  , a_datemod
                                  , null as a_idcre
                                  , a_idmod
                                  , wup_status
                               from upd_data_schedule_period) select_rdv_date
                                  , days
                              where select_rdv_date.hrm_person_id = vn_hrm_person_id
                                and select_rdv_date.scp_date = days.day_date)
                     ,
                     /* Récupère tous les rdv périodiques */
                     rdv_period as
                     (select days.day_date
                           , select_rdv_period.*
                        from (select pac_schedule_period_id
                                   , pac_schedule_id
                                   , c_day_of_week
                                   , dic_sch_period_1_id
                                   , dic_sch_period_2_id
                                   , scp_open_time
                                   , scp_close_time
                                   , scp_comment
                                   , scp_nonworking_day
                                   , scp_date
                                   , hrm_person_id
                                   , a_datecre
                                   , a_datemod
                                   , a_idcre
                                   , a_idmod
                                   , 2 /*web_upd_data_fct.s_validated*/ wup_status
                                from schedule_period
                               union all
                              select pac_schedule_period_id
                                   , pac_schedule_id, day_of_week
                                   , dic_sch_period_1_id
                                   , dic_sch_period_2_id
                                   , open_time
                                   , close_time
                                   , scp_comment
                                   , scp_nonworking_day
                                   , scp_date
                                   , hrm_person_id
                                   , null as a_datecre
                                   , a_datemod
                                   , null as a_idcre
                                   , a_idmod
                                   , wup_status
                               from upd_data_schedule_period) select_rdv_period
                                  , days
                              where select_rdv_period.hrm_person_id = vn_hrm_person_id
                                and select_rdv_period.c_day_of_week = days.day_text)
                     /*  */
                     select all_rdv.pac_schedule_period_id
                          , nvl(all_rdv.pac_schedule_id, web_hrm_portal_fct.get_schedule_id(vn_hrm_person_id) ) pac_schedule_id
                          , vn_hrm_person_id hrm_person_id
                          , all_rdv.c_day_of_week
                          , all_rdv.dic_sch_period_1_id
                          , all_rdv.dic_sch_period_2_id
                          , days.day_date + all_rdv.scp_open_time as sci_start_time
                          , days.day_date + all_rdv.scp_close_time as sci_stop_time
                          , all_rdv.scp_open_time, all_rdv.scp_close_time
                          , days.day_date
                          , all_rdv.scp_comment
                          , all_rdv.scp_nonworking_day
                          , all_rdv.a_datecre
                          , all_rdv.a_datemod
                          , all_rdv.a_idcre
                          , all_rdv.a_idmod
                          , all_rdv.wup_status
                       from (select rdv_date.*
                               from rdv_date
                             union all
                             select rdv_period.*
                               from rdv_period) all_rdv
                          , days
                      where days.day_date = all_rdv.day_date(+)
                  /* end with */) rslt
          );
        vn_row_count := sql%rowcount;
        IF pn_diplay_no_working_day <> 0 THEN
          FOR tplHolidays IN (SELECT psp.scp_comment, psi.scp_date, psi.hrm_person_id
                                FROM (SELECT scp_date, pac_schedule_id, hrm_person_id
                                        FROM pac_schedule_interro
                                       WHERE pac_schedule_period_id IS NULL) psi
                                   , pac_schedule_period psp
                              WHERE psp.PAC_CUSTOM_PARTNER_ID IS NULL
                                AND psp.PAC_SUPPLIER_PARTNER_ID IS NULL
                                AND psp.HRM_PERSON_ID IS NULL
                                AND psp.FAL_FACTORY_FLOOR_ID IS NULL
                                AND psp.HRM_PERSON_ID IS NULL
                                AND psi.pac_schedule_id = psp.pac_schedule_id
                                AND (trunc(psi.scp_date) = trunc(psp.scp_date)
                                     OR web_hrm_portal_fct.formatDate(psi.scp_date, 'DY') = psp.c_day_of_week)
                                AND psp.SCP_NONWORKING_DAY <> 0) LOOP
          UPDATE pac_schedule_interro SET scp_comment = tplHolidays.scp_comment
                                        , scp_nonworking_day = 1
           WHERE scp_date = tplHolidays.scp_date
             AND hrm_person_id = tplHolidays.hrm_person_id;
          END LOOP;
        END IF;
    end loop;

    msg := to_char(sql%rowcount + vn_row_count);
    return WEB_FUNCTIONS.RETURN_OK;
  end internalCalendarRequest;

  /**
   *
   */
  function internalCalendarRequest (
    persons AgendaPersonTable
  , day_date in date
  , modeview in integer
  , pn_diplay_no_working_day NUMBER := 0
  , msg out nocopy varchar2
  )
    return number
  is
    interro_number   constant pac_schedule_interro.sci_interro_number%type   := to_char(sysdate, 'HH24MISS');
    v_from_date      date;
    v_to_date        date;
    vn_hrm_person_id hrm_person.hrm_person_id%TYPE;
    vn_schedule_id   pac_schedule.pac_schedule_id%TYPE;
    vn_row_count     number;
    vn_result        NUMBER := WEB_FUNCTIONS.RETURN_OK;
  begin

    IF modeview = mode_view_day THEN
      delete from pac_schedule_interro;
      /* Si persons est vide retourne immédiatement ayant vidé pac_schedule_interro */
      IF persons.Count() = 0 THEN
        msg := '0';
        return WEB_FUNCTIONS.RETURN_OK;
      END IF;
      for i in persons.first..persons.last  loop
        vn_hrm_person_id := persons(i).id;
        vn_schedule_id := web_hrm_portal_fct.get_schedule_id(vn_hrm_person_id);
        insert into pac_schedule_interro
                    (pac_schedule_interro_id
                   , sci_interro_number
                   , pac_schedule_period_id
                   , pac_schedule_id
                   , hrm_person_id
                   , c_day_of_week
                   , dic_sch_period_1_id
                   , dic_sch_period_2_id
                   , sci_start_time
                   , sci_end_time
                   , scp_open_time
                   , scp_close_time
                   , scp_date
                   , scp_comment
                   , scp_nonworking_day
                   , a_datecre
                   , a_datemod
                   , a_idcre
                   , a_idmod
                   , a_confirm
                   --, scp_working_time
                   --, pac_department_id

                    )
          (select init_id_seq.nextval
                , interro_number
                , pac_schedule_period_id
                , pac_schedule_id
                , hrm_person_id
                , day_of_week
                , dic_sch_period_1_id
                , dic_sch_period_2_id
                , SCI_OPEN
                , SCI_CLOSE
                , open_time
                , close_time
                , scp_date
                , scp_comment
                , 0 scp_nonworking_day
                , a_DATEMOD
                , null
                , a_IDMOD
                , null
                , wup_status
                --, round((close_time-open_time)*24, 2)
                --, scp_entry_id
             from (select pac_schedule_period_id
                        , pac_schedule_id
                        , hrm_person_id
                        , day_of_week
                        , dic_sch_period_1_id
                        , dic_sch_period_2_id
                        , nvl(scp_date, day_date) + open_time SCI_OPEN
                        , nvl(scp_date, day_date) + close_time SCI_CLOSE
                        , open_time
                        , close_time
                        , nvl(scp_date, day_date) scp_date
                        , scp_comment
                        , a_DATEMOD
                        , a_IDMOD
                        , to_number(WUP_STATUS) wup_status
                        --, scp_entry_id
                     from table(WEB_UPD_DATA_FCT.GET_WEB_UPD_DATA_PAC_SCH(vn_hrm_person_id, day_date, day_date) )
                   union all
                   select pac_schedule_period_id
                        , pac_schedule_id
                        , hrm_person_id
                        , c_day_of_week
                        , dic_sch_period_1_id
                        , dic_sch_period_2_id
                        , nvl(scp_date, day_date) + scp_open_time
                        , nvl(scp_date, day_date) + scp_close_time
                        , scp_open_time
                        , scp_close_time
                        , nvl(scp_date, day_date) scp_date
                        , scp_comment
                        , nvl(a_DATEMOD, A_datecre)
                        , nvl(a_IDMOD, a_idcre)
                        , to_number(WEB_UPD_DATA_FCT.S_VALIDATED) STATE
                        --, scp_entry_id
                     from pac_schedule_period p
                    where hrm_person_id = vn_hrm_person_id
                      and (   p.scp_date between day_date and day_date
                           /* Pour un rendez-vous périodique */
                           or (p.c_day_of_Week in (select formatDate(day_date + pcn.no - 1, 'DY')
                                                     from PCS.pc_NUMBER PCN
                                                    where PCN.no between 1 and (day_date - day_date + 1) ) )
                          )
                      and pac_schedule_period_id not in(select wup_recid
                                                          from web_update_data
                                                         where wup_tabname = 'PAC_SCHEDULE_PERIOD') ) );

        IF (SQL%ROWCOUNT = 0 AND pn_diplay_no_working_day <> 0) THEN
          /* Indique si le jour est non ouvrable */
          INSERT INTO pac_schedule_interro
                      (pac_schedule_interro_id
                     , sci_interro_number
                     , pac_schedule_period_id
                     , pac_schedule_id
                     , hrm_person_id
                     , c_day_of_week
                     , dic_sch_period_1_id
                     , dic_sch_period_2_id
                     , sci_start_time
                     , sci_end_time
                     , scp_open_time
                     , scp_close_time
                     , scp_date
                     , scp_comment
                     , scp_nonworking_day
                     , a_datecre
                     , a_datemod
                     , a_idcre
                     , a_idmod
                     , a_confirm
                    )
               (SELECT init_id_seq.nextval
                     , NULL
                     , pac_schedule_period_id
                     , pac_schedule_id
                     , hrm_person_id
                     , c_day_of_week
                     , dic_sch_period_1_id
                     , dic_sch_period_2_id
                     , nvl(scp_date, day_date) + scp_open_time
                     , nvl(scp_date, day_date) + scp_close_time
                     , scp_open_time
                     , scp_close_time
                     , nvl(scp_date, day_date) scp_date
                     , scp_comment
                     , 1 scp_nonworking_day
                     , a_datemod
                     , NULL
                     , a_idmod
                     , NULL
                     , to_number(WEB_UPD_DATA_FCT.S_VALIDATED) wup_status
                  FROM pac_schedule_period
                 WHERE pac_schedule_id = vn_schedule_id
                   AND PAC_I_LIB_SCHEDULE.isopenday(vn_schedule_id, day_date, null, null) = 0
                   AND (Trunc(SCP_DATE) = Trunc(day_Date) OR
                        web_hrm_portal_fct.formatDate(day_Date, 'DY') = c_day_of_week)
              );
        END IF;
        if (sql%rowcount = 0) then
          /*  Insert a dummy entry at day_date, it is a day without rendez-vous */
          insert into pac_schedule_interro
                      (pac_schedule_interro_id
                     , scp_date
                      )
               values (init_id_seq.nextval
                     , day_date
                      );
        end if;
      end loop;
      msg := to_char(sql%rowcount + vn_row_count);
    else
      /* pour mode_view_week et mode_view_month */
      v_from_date  := case modeview
                        when mode_view_week then trunc(day_date, 'DAY') + 1
                        else trunc(trunc(day_date, 'MONTH'), 'D') + 1
                      end;
      v_to_date   := case modeview
                       when mode_view_week then v_from_date + 6
                       else v_from_date + 41
                     end;

      vn_result := internalCalendarRequest(persons,
                                           v_from_date, v_to_date,
                                           pn_diplay_no_working_day,
                                           msg);
    end if;
    return vn_result;
  end internalCalendarRequest;

  /**
   * Voir spécification
   */
  function initializeCalendarRequest(
    hrmpersonid in            hrm_person.hrm_person_id%type
  , dayDate     in            date
  , modeView    in            integer
  , msg         out nocopy    varchar2
  )
    return number
  is
    person      AgendaPersonRec;
    persons     AgendaPersonTable := AgendaPersonTable();
  begin
    select hrmpersonid, '' into person from dual;
    persons.extend(1);
    persons(1) := person;
    return internalCalendarRequest(persons,
                                   dayDate,
                                   modeview,
                                   1,
                                   msg);
  end initializeCalendarRequest;

  /**
   * Voir spécification
   */
  function initializeCalendarRequest(
    hrmpersonid in            hrm_person.hrm_person_id%type
  , day         in            integer
  , month       in            integer
  , year        in            integer
  , modeview    in            integer
  , msg         out nocopy    varchar2
  )
    return number
  is
    dayDate date := to_date(day || '.' || month || '.' || year, 'dd-MM-yyyy');
  begin
    return initializeCalendarRequest(hrmpersonid,
                                     dayDate,
                                     modeview,
                                     msg);
  end initializeCalendarRequest;

  /**
   * Voir spécification
   */
  FUNCTION initializeCalendarRequest (
    hrmpersonid   IN       hrm_person.hrm_person_id%TYPE
  , dayFromDate   IN       DATE
  , dayToDate     IN       DATE
  , msg           OUT NOCOPY VARCHAR2
  )
    RETURN NUMBER
  IS
    v_person      AgendaPersonRec;
    v_persons     AgendaPersonTable := AgendaPersonTable();
  BEGIN
    select hrmpersonid, '' into v_person from dual;
    v_persons.extend(1);
    v_persons(1) := v_person;
    return internalCalendarRequest(v_persons,
                                   dayFromDate,
                                   dayToDate,
                                   0,
                                   msg);
   END initializeCalendarRequest;


  /**
   * Voir spécification
   */
  function Get_Rdv_Summary(dayDate in date)
    return varchar2
  is
    hrmPersonID HRM_PERSON.HRM_PERSON_ID%TYPE;
  begin
    select unique hrm_person_id into hrmPersonID
      from pac_schedule_interro
     where scp_date = DayDate
       and hrm_person_id is not null
       and Sci_Start_Time is not null;
    return Get_Rdv_Summary(dayDate, hrmPersonID);
  end Get_Rdv_Summary;

  /** Voir spéicifcation
   */
  function Get_Rdv_Summary (
      dayDate in date
    , hrmPersonID IN HRM_PERSON.HRM_PERSON_ID%TYPE
    , pn_with_holiday IN INTEGER := 0
  )
    return varchar2
  is
    result varchar2(4000);
    ln_is_open_day integer;
    ln_schedule_id pac_schedule.pac_schedule_id%TYPE;
  begin
   for tplSchedule in (select dic_sch_period_1_id absence_code
                            , sci_start_time start_time
                            , sci_end_time end_time
                            , nvl(a_confirm, web_upd_data_fct.s_validated) state_upd_data
                            , a_confirm
                            , com_dic_functions.getDicoDescr('DIC_SCH_PERIOD_1', dic_sch_period_1_id) absence_descr
                            , scp_comment
                           from pac_schedule_interro psi
                          where scp_date = DayDate
                            and hrm_person_id = hrmPersonID
                            and Sci_Start_Time is not null
                       order by Sci_Start_Time) loop
     result  := result
                || formatDate(tplSchedule.start_time, 'HH24:MI')
                || '-'
                || formatDate(tplSchedule.end_time, 'HH24:MI')
                || ' '
                || '<img src="img/icons/status/wupStatus'||tplSchedule.state_upd_data||'.png"' ||
                   ' alt="'||pcs.pc_functions.translateword('WUP_STATUS_'||tplSchedule.state_upd_data)||'"/>'
                || chr(10)
                || nvl(tplSchedule.scp_comment, tplSchedule.absence_descr)
                || chr(10);
   end loop;

    /* On affiche les commentaire pour les jours férie */
    IF (result is null AND pn_with_holiday <> 0) THEN
      ln_schedule_id := get_schedule_id(hrmPersonID);
      BEGIN
        SELECT scp_comment into result
          FROM pac_schedule_interro
         WHERE hrm_person_id = hrmPersonId
           AND scp_date = dayDate
           AND scp_nonworking_day <> 0;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
    return result;
  end Get_Rdv_Summary;

  /**
   *
   */
  function retrievePersons(personListId  in varchar2) return AgendaPersonTable
  is
    sqlList clob;
    sqlCommand clob := empty_clob();
    persons      AgendaPersonTable := AgendaPersonTable();
  begin

    if personListId is not null then
      /* Recupere l'interrogation SQL de la liste des personnnes */
      sqlList := pcs.pc_sql.getsql('PAC_SCHEDULE_INTERRO',
                                   'HrmPortalAppModule',
                                   'ViewAgendaPersonListSql',
                                   null, 'ANSI SQL', false);

      /* Retourne la commande SQL à exécuter*/
      execute immediate to_char(sqlList) into sqlCommand using personListId;
    end if;
    /* Dans persons, la liste des personnes */
    if (NOT sqlCommand is null and length(sqlCommand) > 0) then
      execute immediate to_char(sqlCommand) bulk collect into persons;
    end if;
    return persons;
  end retrievePersons;

  /**
   * Voir specification
   */
  function initializeCalendarRequest (
    personListId  in         varchar2
  , dayDate       in         date
  , modeView      in         integer
  , pn_with_holiday IN       NUMBER
  , msg           out nocopy varchar2
  )
    return number
  is
  begin
    return internalCalendarRequest(retrievePersons(personListId),
                                   dayDate,
                                   modeView,
                                   pn_with_holiday,
                                   msg);
  end initializeCalendarRequest;

  /**
   * Voir specification
   */
  FUNCTION initializeCalendarRequest (
    ps_personListId IN         VARCHAR2
  , pd_from_date    IN         DATE
  , pd_to_date      IN         DATE
  , pn_with_holiday IN         NUMBER DEFAULT 0
  , ps_msg          OUT NOCOPY VARCHAR2
  )
    RETURN NUMBER
  IS
  BEGIN
    RETURN internalCalendarRequest(retrievePersons(ps_personListId),
                                   pd_from_date,
                                   pd_to_date,
                                   pn_with_holiday,
                                   ps_msg);
  END initializeCalendarRequest;

  /**
   * Voir specification
   */
  FUNCTION initializeCalendarRequest (
    pn_personId     IN         hrm_person.hrm_person_id%TYPE
  , pd_from_date    IN         DATE
  , pd_to_date      IN         DATE
  , pn_with_holiday IN         NUMBER DEFAULT 0
  , ps_msg          OUT NOCOPY VARCHAR2
  )
    RETURN NUMBER
  IS
    lr_person      AgendaPersonRec;
    lt_persons     AgendaPersonTable := AgendaPersonTable();
  BEGIN
    select pn_personId, '' into lr_person from dual;
    lt_persons.extend(1);
    lt_persons(1) := lr_person;
    RETURN internalCalendarRequest(lt_persons,
                                   pd_from_date,
                                   pd_to_date,
                                   pn_with_holiday,
                                   ps_msg);
  END initializeCalendarRequest;

  /**
   * Voir specification
   */
  function retrievePersonsList(personListId in VARCHAR2)
     return AgendaPersonTable PIPELINED
  is
    persons      AgendaPersonTable;
  begin
    /* Dans persons, la liste des personnes */
    begin
      persons := retrievePersons(personListId);
      exception
        when NO_DATA_FOUND then
          return;
    end;
    IF persons.count() > 0 THEN
      for i in persons.first .. persons.last loop
        pipe row(persons(i));
      end loop;
    END IF;
  end retrievePersonsList;


  /**
   * Voir specification
   */
  Function getAgendaAbsenceCodeSummary (
      dayDate IN DATE
    , hrmPersonID IN HRM_PERSON.HRM_PERSON_ID%TYPE
  )
      RETURN VARCHAR2
  is
    result varchar2(4000);
    ln_is_open_day integer;
  begin
    for tplResult in (select DIC_SCH_PERIOD_1_ID absenceCode
                        from pac_schedule_interro psi
                       where psi.HRM_PERSON_ID = hrmPersonId
                         and psi.SCP_DATE = dayDate) loop
      result := result || tplResult.absenceCode ||';';
    end loop;
    result := RTrim(result, ';');

    if (result is null) then
      BEGIN
        SELECT gcv_dic_holiday into result
          FROM pac_schedule_interro
         WHERE hrm_person_id = hrmPersonId
           AND scp_date = dayDate
           AND scp_nonworking_day <> 0;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
      END;
    end if;
    return result;
  end getAgendaAbsenceCodeSummary;

  /**
   * Voir spécification
   */
  Function getAgendaAbsenceCodeSummary (
      dayDate IN DATE
  )
      RETURN VARCHAR2
  is
    result varchar2(4000);
    ln_is_open_day integer;
  begin
    for tplResult in (select DIC_SCH_PERIOD_1_ID absenceCode
                        from pac_schedule_interro psi
                       where psi.SCP_DATE = dayDate) loop
      result := result || tplResult.absenceCode ||';';
    end loop;
    result := RTrim(result, ';');

    if (result is null) then
      BEGIN
        SELECT gcv_dic_holiday into result
          FROM pac_schedule_interro
         WHERE scp_date = dayDate
           AND scp_nonworking_day <> 0;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
      END;
    end if;
    return result;
  end getAgendaAbsenceCodeSummary;

  /**
   *
   */
  FUNCTION is_holiday (
    pd_day      IN DATE
  , pn_hrm_person_id IN HRM_PERSON.HRM_PERSON_ID%TYPE
  )
    RETURN BOOLEAN
  IS
    result pac_schedule_interro.scp_nonworking_day%TYPE := 0;
  BEGIN
    BEGIN
      SELECT scp_nonworking_day into result
        FROM pac_schedule_interro
       WHERE (hrm_person_id = pn_hrm_person_id OR pn_hrm_person_id IS NULL)
         AND scp_date = pd_day;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    RETURN (result <> 0);
  END is_holiday;

  /**
   * Voir spécification
   */
  FUNCTION get_agenda_absence_summary (
    pd_day      IN DATE
  , pn_hrm_person_id IN HRM_PERSON.HRM_PERSON_ID%TYPE
  )
    RETURN AbsenceCodeTable
  IS
    lset_absence_code AbsenceCodeTable;
  BEGIN
    SELECT dic_sch_period_1_id BULK COLLECT INTO lset_absence_code
      FROM pac_schedule_interro
     WHERE NOT dic_sch_period_1_id IS NULL
       AND scp_date = pd_day
       AND (hrm_person_id = pn_hrm_person_id OR pn_hrm_person_id IS NULL);

    IF lset_absence_code.COUNT > 1 THEN
      lset_absence_code := AbsenceCodeTable(gs_code_more_absence);
    ELSE IF lset_absence_code.COUNT = 0 AND is_holiday(pd_day, pn_hrm_person_id) THEN
      lset_absence_code := AbsenceCodeTable(gs_code_holiday);
    END IF;    END IF;
    RETURN lset_absence_code;
  END get_agenda_absence_summary;

  /**
   *
   */
  FUNCTION encodeJSONValue (ps_value IN VARCHAR2) RETURN VARCHAR2
  IS
    result VARCHAR2(4000);
    c VARCHAR2(4000);
  BEGIN
    IF ps_value IS NOT NULL THEN
      FOR i IN 1..Length(ps_value) LOOP
        c := Substr(ps_value, i, 1);
        CASE c
          WHEN gtab_special_chars(1).pattern THEN c := gtab_special_chars(1).replaceBy;
          WHEN gtab_special_chars(2).pattern THEN c := gtab_special_chars(2).replaceBy;
          WHEN gtab_special_chars(3).pattern THEN c := gtab_special_chars(3).replaceBy;
          WHEN gtab_special_chars(4).pattern THEN c := gtab_special_chars(4).replaceBy;
          WHEN gtab_special_chars(5).pattern THEN c := gtab_special_chars(5).replaceBy;
          WHEN gtab_special_chars(6).pattern THEN c := gtab_special_chars(6).replaceBy;
          WHEN gtab_special_chars(7).pattern THEN c := gtab_special_chars(7).replaceBy;
          WHEN gtab_special_chars(8).pattern THEN c := gtab_special_chars(8).replaceBy;
          WHEN gtab_special_chars(9).pattern THEN c := gtab_special_chars(9).replaceBy;
          ELSE NULL;
        END CASE;
        result := result || c;
      END LOOP;
    END IF;
    RETURN '"' || result || '"';
  END encodeJSONValue;

  /**
   * Encode les données d'une absence au format JSON. Les données sont mémorisées
   * dans un objet avec les noms des valeurs suivant:
   * ID pn_id: 'id'
   * Absence Code ps_absence_code: 'ac'
   * Start Time pd_start_time: 'st'
   * End Time pd_end_time: 'et'
   * Absence state ps_state: 'as'
   * Comment ps_comment: 'ct'
   * All day absence pn_all_day: 'ad'
   * Top pn_top: 't'
   * Bottom pn_bottom: 'b'
   * Les noms ont une longueur limité à 2 caractères pour sauvegarder la bande
   * passante.
   */
  FUNCTION encodeJSONObject_absence(
      pn_id IN NUMBER
    , ps_absence_code IN VARCHAR2
    , pd_start_time IN DATE
    , pd_end_time IN DATE
    , ps_state IN VARCHAR2
    , ps_comment IN VARCHAR2
    , pn_all_day IN NUMBER
    , pn_top IN NUMBER
    , pn_bottom IN NUMBER
  )
    RETURN VARCHAR2
  IS
    ls_all_day VARCHAR2(100);
    ls_start_time VARCHAR2(10) := 'null';
    ls_end_time VARCHAR2(10) := 'null';
  BEGIN
    IF pn_all_day <> 0 THEN
      ls_all_day := '1';
    ELSE
      ls_all_day := '0';
    END IF;
    IF pd_start_time IS NOT NULL THEN
      ls_start_time := encodeJSONValue(formatDate(pd_start_time, 'HH24MI'));
    END IF;
    IF pd_end_time IS NOT NULL THEN
      ls_end_time := encodeJSONValue(formatDate(pd_end_time, 'HH24MI'));
    END IF;
    RETURN  '{' -- Object Javascript
            || 'id:' || pn_id || ','
            || 'ac:' || encodeJSONValue(ps_absence_code) || ','
            || 'st:' || ls_start_time || ','
            || 'et:' || ls_end_time || ','
            || 'as:' || encodeJSONValue(ps_state)  || ','
            || 'ct:' || encodeJSONValue(ps_comment) || ','
            || 'ad:' || ls_all_day || ','
            || 't:' || pn_top || ','
            || 'b:' || pn_bottom ||
            '}';
  END encodeJSONObject_absence;

  /**
   *  Voir spécification
   */
  FUNCTION get_json_agenda_absence (
      pd_day           IN DATE
    , pn_hrm_person_id IN HRM_PERSON.HRM_PERSON_ID%TYPE
    , pn_with_holiday  IN INTEGER := 0
  )
    RETURN VARCHAR2
  IS
    result VARCHAR2(4000);
    ln_is_open_day INTEGER;
    ln_schedule_id pac_schedule.pac_schedule_id%TYPE;
    ln_top NUMBER := 0;
    ln_bottom NUMBER := 100;
    lblob_sql CLOB := empty_clob();
    ln_id NUMBER;
  BEGIN
    /* Recupere l'interrogation SQL pour le calcul  */
    lblob_sql := pcs.pc_sql.getsql('PAC_SCHEDULE_INTERRO',
                                   'HrmPortalAppModule',
                                   'ViewAgendaDetermineHeight',
                                   null, 'ANSI SQL', false);
    FOR tplSchedule IN (SELECT pac_schedule_interro_id id
                             , dic_sch_period_1_id absence_code
                             , sci_start_time start_time
                             , sci_end_time stop_time
                             , NVL(a_confirm, web_upd_data_fct.s_validated) state_upd_data
                             , a_confirm
                             , com_dic_functions.getDicoDescr('DIC_SCH_PERIOD_1', dic_sch_period_1_id) absence_descr
                             , scp_comment
                          FROM pac_schedule_interro psi
                         WHERE scp_date = pd_day
                           AND hrm_person_id = pn_hrm_person_id
                           AND Sci_Start_Time IS NOT NULL
                      ORDER BY Sci_Start_Time) LOOP
      EXECUTE IMMEDIATE to_char(lblob_sql) INTO ln_top, ln_bottom
                                           USING tplSchedule.start_time,
                                                 tplSchedule.stop_time,
                                                 0;
      result := result || encodeJSONObject_absence(tplSchedule.id,
                                                   tplSchedule.absence_code,
                                                   tplSchedule.start_time,
                                                   tplSchedule.stop_time,
                                                   tplSchedule.state_upd_data,
                                                   nvl(tplSchedule.scp_comment, tplSchedule.absence_descr),
                                                   0,
                                                   ln_top, ln_bottom) || ',';
    END LOOP;

    /* On affiche les commentaire pour les jours férie */
    IF (result IS NULL AND pn_with_holiday <> 0) THEN
      ln_schedule_id := get_schedule_id(pn_hrm_person_id);
      BEGIN
        SELECT pac_schedule_interro_id
             , scp_comment
          INTO ln_id, result
          FROM pac_schedule_interro
         WHERE hrm_person_id = pn_hrm_person_id
           AND scp_date = pd_day
           AND scp_nonworking_day <> 0;
        result := encodeJSONObject_absence(ln_id,
                                           gs_code_holiday,
                                           null,
                                           null,
                                           web_upd_data_fct.s_validated,
                                           result,
                                           1,
                                           ln_top, ln_bottom) || ',';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
    IF (result IS NOT NULL) THEN
      result := Substr(result, 1, length(result)-1);
    END IF;
    IF result IS NOT NULL THEN
      RETURN '[' || result || ']';
    ELSE
      RETURN NULL;
    END IF;

  END get_json_agenda_absence;

  /**
   * Voir spécification
  */
--   FUNCTION get_agenda_absence_summary (
--     pd_day     IN DATE
--   )
--     RETURN AbsenceCodeTable
--   IS
--   BEGIN
--     RETURN get_agenda_absence_summary(pd_day, NULL);
--   END get_agenda_absence_summary;

  /**
   * Voir spécification
  */
  FUNCTION get_agenda_absence_color_code (
    pd_day IN DATE
  , pn_hrm_person_id IN HRM_PERSON.HRM_PERSON_ID%TYPE := NULL
  )
    RETURN VARCHAR2
  IS
    ls_color_code VARCHAR2(4000) := '';
    lset_absence_code AbsenceCodeTable;
  BEGIN
    lset_absence_code := get_agenda_absence_summary(pd_day, pn_hrm_person_id);
    IF (lset_absence_code.COUNT > 0) THEN
      ls_color_code := gassoc_color_code(lset_absence_code(1)).COLOR;
    END IF;
    RETURN ls_color_code;
  END get_agenda_absence_color_code;

  /**
   * Voir spécification
  */
  FUNCTION get_absence_color_code (
    ps_absence_code IN VARCHAR2
  )
    RETURN VARCHAR2
  IS
    ls_color_code VARCHAR2(4000) := '';
  BEGIN
    ls_color_code := gassoc_color_code(ps_absence_code).COLOR;
    RETURN ls_color_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN '';
      WHEN OTHERS THEN
        RETURN '';
  END get_absence_color_code;

  /**
   * Voir spécification
  */
  FUNCTION get_schedule_id(
      in_hrmPersonId in hrm_person.hrm_person_id%TYPE
    , id_date IN DATE := NULL
    )
    RETURN pac_schedule.pac_schedule_id%TYPE
  IS
    ln_schedule_id pac_schedule.pac_schedule_id%type;
    lcob_sql clob := empty_clob();
  BEGIN
    lcob_sql := pcs.pc_sql.getsql('HRM_PERSON',
                                  'HrmPortalAppModule',
                                  'ViewPersonSchedule',
                                  null, 'ANSI SQL', false);

    IF (NOT lcob_sql IS NULL OR Length(lcob_sql) > 0) THEN
      EXECUTE IMMEDIATE to_char(lcob_sql) INTO ln_schedule_id
                                          USING in_hrmPersonId;
    ELSE
      ln_schedule_id := PAC_I_LIB_SCHEDULE.getDefaultSchedule;
    END IF;
    RETURN ln_schedule_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        /* *@TODO: trace the error */
        RETURN PAC_I_LIB_SCHEDULE.getDefaultSchedule;
      WHEN TOO_MANY_ROWS THEN
        /* @TODO: trace the error */
        RETURN PAC_I_LIB_SCHEDULE.getDefaultSchedule;
      WHEN OTHERS THEN
        /* @TODO: trace the error */
        RETURN PAC_I_LIB_SCHEDULE.getDefaultSchedule;
  END get_schedule_id;

  /**
   * Voir spécification
   */
  FUNCTION get_status_selection_list
    RETURN Selection_Item_Table PIPELINED
  IS
    v_sqlstmnt CLOB;
    v_list Selection_Item_Table;
    vs_sql VARCHAR2(4000);
  BEGIN
    v_sqlstmnt := pcs.pc_sql.getsql('WEB_UPDATE_DATA',
                                    'HrmPortalAppModule',
                                    'ViewWebUpdateDataStatusCode');
    -- Select only fields status and descr and ignore others field to populate Selection_Item_Table
    vs_sql := 'SELECT status, descr FROM (' || to_char(v_sqlstmnt) || ')';
    EXECUTE IMMEDIATE vs_sql BULK COLLECT INTO v_list;
    FOR i IN v_list.first..v_list.last LOOP
      PIPE ROW(v_list(i));
    END LOOP;
  END get_status_selection_list;

  /**
   * Voir spécification
   */
  FUNCTION retrieve_absence(
    p_hrm_person_id  IN hrm_person.hrm_person_id%TYPE
  , p_absence_type_include  IN VARCHAR2
  , p_absence_type_exclude  IN VARCHAR2
  , p_status         IN NUMBER
  , p_date_from      IN DATE
  , p_date_to        IN DATE
  )
    RETURN Absence_History_Table PIPELINED
  IS
    TYPE schedule_period_id_table IS TABLE OF pac_schedule_period.pac_schedule_period_id%TYPE
      INDEX BY VARCHAR2(20);

    v_rec_absence     Absence_History_Record;
    vn_last_entry_id  pac_schedule_period.scp_entry_id%TYPE;
    /* Sauvegarde des PKs */
    v_schedule_period_ids schedule_period_id_table;
    vs_psp_id         VARCHAR2(20);
    ln_allDay         NUMBER;
    ln_topPos         NUMBER;
    ln_bottomPos      NUMBER;
  BEGIN
    /* */
    IF p_hrm_person_id IS NULL THEN
      RETURN;
    END IF;
    /* Traitement des absences dans la table wep_update_data */
    FOR tplData IN (SELECT pac_schedule_period_id
                         , scp_date
                         , open_time
                         , close_time
                         , scp_nonworking_day
                         , dic_sch_period_1_id
                         , scp_comment
                         , wup_status
                         , scp_entry_id
                      FROM table(web_upd_data_fct.get_web_upd_data_pac_sch(p_hrm_person_id,
                                                                           p_date_from,
                                                                           p_date_to))
                      WHERE (p_status IS NULL OR p_status = wup_status)
                        AND (p_absence_type_include IS NULL OR dic_sch_period_1_id IN (p_absence_type_include))
                        AND (p_absence_type_exclude IS NULL OR NOT dic_sch_period_1_id IN (p_absence_type_exclude))
                      ORDER BY  scp_entry_id ASC NULLS FIRST, scp_date ASC, open_time ASC) LOOP
      vs_psp_id := to_char(tplData.pac_schedule_period_id);
      IF NOT v_schedule_period_ids.Exists(vs_psp_id) THEN
        v_schedule_period_ids(vs_psp_id) := tplData.pac_schedule_period_id;
      END IF;
      IF (tplData.scp_entry_id IS NULL) THEN
        v_rec_absence.pac_schedule_period_id := tplData.pac_schedule_period_id;
        v_rec_absence.date_from := tplData.scp_date + tplData.open_time;
        v_rec_absence.date_to :=  tplData.scp_date + tplData.close_time;
        v_rec_absence.total := null;
        v_rec_absence.dic_sch_period_1_id := tplData.dic_sch_period_1_id;
        v_rec_absence.scp_comment := tplData.scp_comment;
        v_rec_absence.c_web_update_state := tplData.wup_status;
        v_rec_absence.reason := null;
        v_rec_absence.action_modify := null;
        v_rec_absence.action_delete := null;
        v_rec_absence.free_comment := null;
        ln_allDay := 0;
        SELECT topPos, bottomPos INTO ln_topPos, ln_bottomPos
          FROM table(retrieve_absence_height(v_rec_absence.date_from,
                                             v_rec_absence.date_to,
                                             ln_allDay));
        v_rec_absence.json_data := encodeJSONObject_absence(tplData.pac_schedule_period_id,
                                                            tplData.dic_sch_period_1_id,
                                                            v_rec_absence.date_from,
                                                            v_rec_absence.date_to,
                                                            tplData.wup_status,
                                                            tplData.scp_comment,
                                                            ln_allDay,
                                                            ln_topPos,
                                                            ln_bottomPos);
        PIPE ROW(v_rec_absence);
      ELSE
        /* Nouveau enregistrement */
        IF vn_last_entry_id IS NULL OR tplData.scp_entry_id != vn_last_entry_id THEN
          /* Sauve le dernier enregistrement si il existe */
          IF NOT vn_last_entry_id IS NULL THEN
            PIPE ROW (v_rec_absence);
          END IF;
          vn_last_entry_id := tplData.scp_entry_id;
          v_rec_absence.pac_schedule_period_id := tplData.pac_schedule_period_id;
          v_rec_absence.date_from := tplData.scp_date + tplData.open_time;
          v_rec_absence.total := null;
          v_rec_absence.dic_sch_period_1_id := tplData.dic_sch_period_1_id;
          v_rec_absence.scp_comment := tplData.scp_comment;
          v_rec_absence.c_web_update_state := tplData.wup_status;
          v_rec_absence.reason := null;
          v_rec_absence.action_modify := null;
          v_rec_absence.action_delete := null;
          v_rec_absence.free_comment := null;
          ln_allDay := 0;
          SELECT topPos, bottomPos INTO ln_topPos, ln_bottomPos
            FROM table(retrieve_absence_height(v_rec_absence.date_from,
                                               v_rec_absence.date_to,
                                               ln_allDay));
          v_rec_absence.json_data := encodeJSONObject_absence(tplData.pac_schedule_period_id,
                                                              tplData.dic_sch_period_1_id,
                                                              v_rec_absence.date_from,
                                                              v_rec_absence.date_to,
                                                              tplData.wup_status,
                                                              tplData.scp_comment,
                                                              ln_allDay,
                                                              ln_topPos,
                                                              ln_bottomPos);
        END IF;
        v_rec_absence.date_to :=  tplData.scp_date + tplData.close_time;
      END IF;
    END LOOP;

    /* Sauve le dernier enregistrement */
    IF NOT vn_last_entry_id IS NULL THEN
      PIPE ROW (v_rec_absence);
    END IF;

    /* Traitement des absences dans pac_schedule_period, les absences périodiques
     * ne sont pas traités.
     */
    vn_last_entry_id := null;
    FOR tplData IN (SELECT pac_schedule_period_id
                         , scp_date
                         , scp_open_time open_time
                         , scp_close_time close_time
                         , scp_nonworking_day
                         , dic_sch_period_1_id
                         , scp_comment
                         , 2 wup_status
                         , scp_entry_id
                      FROM pac_schedule_period
                     WHERE  hrm_person_id = p_hrm_person_id
                       AND  scp_date between p_date_from and p_date_to
                       AND (p_status IS NULL OR p_status = 2)
                       AND (p_absence_type_include IS NULL OR dic_sch_period_1_id IN (p_absence_type_include))
                       AND (p_absence_type_exclude IS NULL OR NOT dic_sch_period_1_id IN (p_absence_type_exclude))
                     ORDER BY  scp_entry_id ASC NULLS FIRST, scp_date ASC, open_time ASC) LOOP
      /* Si enregistrement pas encore traité */
      vs_psp_id := to_char(tplData.pac_schedule_period_id);
      IF NOT v_schedule_period_ids.Exists(vs_psp_id) THEN
        IF (tplData.scp_entry_id IS NULL) THEN
          v_rec_absence.pac_schedule_period_id := tplData.pac_schedule_period_id;
          v_rec_absence.date_from := tplData.scp_date + tplData.open_time;
          v_rec_absence.date_to :=  tplData.scp_date + tplData.close_time;
          v_rec_absence.total := null;
          v_rec_absence.dic_sch_period_1_id := tplData.dic_sch_period_1_id;
          v_rec_absence.scp_comment := tplData.scp_comment;
          v_rec_absence.c_web_update_state := tplData.wup_status;
          v_rec_absence.reason := null;
          v_rec_absence.action_modify := null;
          v_rec_absence.action_delete := null;
          v_rec_absence.free_comment := null;
          ln_allDay := 0;
          SELECT topPos, bottomPos INTO ln_topPos, ln_bottomPos
            FROM table(retrieve_absence_height(v_rec_absence.date_from,
                                               v_rec_absence.date_to,
                                               ln_allDay));
          v_rec_absence.json_data := encodeJSONObject_absence(tplData.pac_schedule_period_id,
                                                              tplData.dic_sch_period_1_id,
                                                              v_rec_absence.date_from,
                                                              v_rec_absence.date_to,
                                                              tplData.wup_status,
                                                              tplData.scp_comment,
                                                              ln_allDay,
                                                              ln_topPos,
                                                              ln_bottomPos);
          PIPE ROW(v_rec_absence);
        ELSE
          /* Nouveau enregistrement */
          IF vn_last_entry_id IS NULL OR tplData.scp_entry_id != vn_last_entry_id THEN
            /* Sauve le dernier enregistrement si il existe */
            IF NOT vn_last_entry_id IS NULL THEN
              PIPE ROW (v_rec_absence);
            END IF;
            vn_last_entry_id := tplData.scp_entry_id;
            v_rec_absence.pac_schedule_period_id := tplData.pac_schedule_period_id;
            v_rec_absence.date_from := tplData.scp_date + tplData.open_time;
            v_rec_absence.total := null;
            v_rec_absence.dic_sch_period_1_id := tplData.dic_sch_period_1_id;
            v_rec_absence.scp_comment := tplData.scp_comment;
            v_rec_absence.c_web_update_state := tplData.wup_status;
            v_rec_absence.reason := null;
            v_rec_absence.action_modify := null;
            v_rec_absence.action_delete := null;
            v_rec_absence.free_comment := null;
            ln_allDay := 0;
            SELECT topPos, bottomPos INTO ln_topPos, ln_bottomPos
              FROM table(retrieve_absence_height(v_rec_absence.date_from,
                                                 v_rec_absence.date_to,
                                                 ln_allDay));
            v_rec_absence.json_data := encodeJSONObject_absence(tplData.pac_schedule_period_id,
                                                                tplData.dic_sch_period_1_id,
                                                                v_rec_absence.date_from,
                                                                v_rec_absence.date_to,
                                                                tplData.wup_status,
                                                                tplData.scp_comment,
                                                                ln_allDay,
                                                                ln_topPos,
                                                                ln_bottomPos);
          END IF;
          v_rec_absence.date_to :=  tplData.scp_date + tplData.close_time;
        END IF;
      END IF;
    END LOOP;

    /* Sauve le dernier enregistrement */
    IF NOT vn_last_entry_id IS NULL THEN
      PIPE ROW (v_rec_absence);
    END IF;

  END retrieve_absence;

  /**
   *  Voir Spécification
   */
  FUNCTION retrieve_cmd_history_absences(
    ps_command_id IN VARCHAR2
  )
    RETURN CLOB
  IS
   vclob_sql CLOB := empty_clob();
   vclob_command CLOB := empty_clob();
  BEGIN
    /* Recupere l'interrogation SQL de l'historique des absences */
    vclob_sql := pcs.pc_sql.getsql('WEB_UPDATE_DATA',
                                   'HrmPortalAppModule',
                                   'ViewTypeAbsenceListSql',
                                   null, 'ANSI SQL', false);
    IF vclob_sql IS NOT NULL AND Length(vclob_sql) > 0 THEN
      BEGIN
        EXECUTE IMMEDIATE to_char(vclob_sql) INTO vclob_command
                                             USING ps_command_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          -- Consider logging the error and then re-raise
          RAISE;
      END;
    END IF;
    RETURN vclob_command;
  END;

  /**
   * Voir spécification
   */
  FUNCTION build_absence_list(
    p_list IN VARCHAR2
  , pn_include_all IN NUMBER DEFAULT 1
  )
    RETURN AbsenceCodeTable PIPELINED
  IS
    cs_comma_separator CONSTANT VARCHAR2(5) := '[^,]+';
    vs_code dic_sch_period_1.dic_sch_period_1_id%TYPE;
  BEGIN
    IF p_list IS NULL THEN
      IF pn_include_all != 0 THEN
        FOR tplAbsenceCode IN (SELECT dic_sch_period_1_id code
                                 FROM dic_sch_period_1) LOOP
          PIPE ROW(tplAbsenceCode.code);
        END LOOP;
      END IF;
    ELSE
      /* Découpe un string. Le délimiteur est la virgule */
      FOR i in (SELECT regexp_substr(p_list, cs_comma_separator, 1, level) code
                  FROM dual
                CONNECT BY level <= length(regexp_replace(p_list, cs_comma_separator)) + 1) LOOP
        vs_code := Trim(Upper(i.code));
        IF gassoc_color_code.Exists(vs_code) THEN
          PIPE ROW(vs_code);
        END IF;
        NULL;
      END LOOP;
    END IF;
  END build_absence_list;

  /**
   *  Voir spécification
   */
  FUNCTION retrieve_cmd_dependant_list(
    ps_command_id IN VARCHAR2
  )
    RETURN CLOB
  IS
   vclob_sql CLOB := empty_clob();
   vclob_command CLOB := empty_clob();
  BEGIN
    /* Recupere l'interrogation SQL de l'historique des absences */
    vclob_sql := pcs.pc_sql.getsql('HRM_PERSON',
                                   'HrmPortalAppModule',
                                   'ViewMyDependantsListSql',
                                   null, 'ANSI SQL', false);
    IF vclob_sql IS NOT NULL AND Length(vclob_sql) > 0 THEN
      BEGIN
        EXECUTE IMMEDIATE to_char(vclob_sql) INTO vclob_command
                                             USING ps_command_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          -- Consider logging the error and then re-raise
          RAISE;
      END;
    END IF;
    RETURN vclob_command;
  END retrieve_cmd_dependant_list;

  /**
   *  Voir Spécification
   */
  FUNCTION retrieve_dependents_list(
    p_hrm_in_charge_id  IN NUMBER
  , ps_command_id       IN VARCHAR2
  )
    RETURN Hrm_Person_Id_Table PIPELINED
  IS
    vclob_command CLOB := empty_clob();
    v_list_hrm_person_id Hrm_Person_Id_Table;
  BEGIN
    vclob_command := retrieve_cmd_dependant_list(ps_command_id);
    IF vclob_command IS NOT NULL AND Length(vclob_command) > 0 THEN
      EXECUTE IMMEDIATE to_char(vclob_command) BULK COLLECT INTO v_list_hrm_person_id
                                               USING p_hrm_in_charge_id;
      FOR i IN v_list_hrm_person_id.FIRST..v_list_hrm_person_id.LAST LOOP
        PIPE ROW(v_list_hrm_person_id(i));
      END LOOP;
    END IF;
  END retrieve_dependents_list;

  /**
   * Retourne les soldes de vacances et autres information pour une équipe
   */
  FUNCTION retrieve_team_absences_balance(
    p_hrm_in_charge_id  IN NUMBER
  , ps_dependant_list   IN VARCHAR2
  )
    RETURN Team_Information_Table PIPELINED
  IS
    vr_person_info Person_Team_Information_Record;
  BEGIN
    FOR tplTeam IN (SELECT hp.hrm_person_id
                         , hp.per_last_name || ' ' || hp.per_first_name full_name
                      FROM TABLE(web_hrm_portal_fct.retrieve_dependents_list(p_hrm_in_charge_id, ps_dependant_list)) team
                         , hrm_person hp
                     WHERE team.column_value = hp.hrm_person_id) LOOP
      vr_person_info.hrm_person_id := tplTeam.hrm_person_id;
      vr_person_info.col_info_1 := tplTeam.full_name;
      vr_person_info.col_info_2 := to_char(0);
      vr_person_info.col_info_3 := to_char(0);
      vr_person_info.col_info_4 := to_char(0);
      vr_person_info.col_info_5 := to_char(0);
      vr_person_info.col_info_6 := to_char(0);
      vr_person_info.col_info_7 := to_char(0);
      vr_person_info.col_info_8 := '';
      vr_person_info.col_info_9 := '';
      vr_person_info.col_info_10 := '';
      PIPE ROW(vr_person_info);
    END LOOP;

  END retrieve_team_absences_balance;

  /**
   * Voir spécification
   */
  FUNCTION get_absence_descr(
    ps_absence_code IN VARCHAR2
  , p_pc_lang_id IN pcs.pc_dico.pc_lang_id%type DEFAULT NULL
  )
    RETURN VARCHAR2
  IS
    vs_descr VARCHAR2(4000) := NULL;
  BEGIN
    BEGIN
      /* Test existence du code absence */
      IF gassoc_color_code.Exists(ps_absence_code) THEN
        IF p_pc_lang_id IS NULL THEN
          vs_descr := gassoc_color_code(ps_absence_code).DESCR;
        ELSE
          vs_descr := com_dic_functions.getDicoDescr('DIC_SCH_PERIOD_1',
                                                     ps_absence_code,
                                                     p_pc_lang_id);
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN vs_descr;
  END get_absence_descr;


  /**
   * Voir spécification
   */
  FUNCTION get_wup_status_descr(
    pn_wup_status IN NUMBER
  , p_pc_lang_id IN pcs.pc_dico.pc_lang_id%type DEFAULT NULL
  )
    RETURN VARCHAR2
  IS
   cs_prefix_wup_status CONSTANT VARCHAR2(4000) := 'WUP_STATUS_';
   vs_wup_status VARCHAR2(4000) := cs_prefix_wup_status || pn_wup_status;
  BEGIN
    IF p_pc_lang_id IS NULL THEN
      RETURN pcs.pc_functions.translateword(vs_wup_status);
    ELSE
      RETURN pcs.pc_functions.translateword(vs_wup_status, p_pc_lang_id);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN vs_wup_status;
  END get_wup_status_descr;

  /**
   * Voir spécification.
   *
   * Tous les calculs en internes se font en seconde.
   */
  FUNCTION retrieve_absence_height(
    pd_start_time IN DATE
  , pd_stop_time   IN DATE
  , pn_all_day    IN NUMBER
  )
    RETURN Height_Absence_Table PIPELINED
  IS
    lci_begin_time  CONSTANT INTEGER := convert_date_to_second(to_date('08:00', 'HH24:MI'));
    lci_middle_time CONSTANT INTEGER := convert_date_to_second(to_date('12:00', 'HH24:MI'));
    lci_end_time    CONSTANT INTEGER := convert_date_to_second(to_date('17:00', 'HH24:MI'));
    lci_duration    CONSTANT INTEGER := lci_end_time - lci_begin_time;

    li_start_time INTEGER := convert_date_to_second(pd_start_time);
    li_stop_time INTEGER := convert_date_to_second(pd_stop_time);
    lrec_height Height_Absence_Record;
  BEGIN
    li_start_time := greatest(least(li_start_time, li_stop_time), lci_begin_time);
    li_stop_time := least(greatest(li_start_time, li_stop_time), lci_end_time);
    lrec_height.topPos := gcn_min_top;
    lrec_height.bottomPos := gcn_max_bottom;
    IF pn_all_day = 0 THEN
      CASE gcn_computied_height
        WHEN gcn_computied_height_am_pm THEN
          /* AM */
          IF li_start_time < lci_middle_time AND li_stop_time <= lci_middle_time THEN
            lrec_height.topPos := 0;
            lrec_height.bottomPos := 50;
          /* PM */
          ELSIF li_start_time >= lci_middle_time AND li_stop_time > lci_middle_time THEN
            lrec_height.topPos := 50;
            lrec_height.bottomPos := 100;
          ELSE
            NULL;
          END IF;

        ELSE /* par défaut gcn_computied_height_duration */
          lrec_height.topPos := (li_start_time - lci_begin_time) / lci_duration * 100.0;
          lrec_height.bottomPos := lrec_height.topPos + (li_stop_time - li_start_time) / lci_duration * 100.0;
      END CASE;
    END IF;
    PIPE ROW(lrec_height);
  END retrieve_absence_height;

  /**
   * Voir spécification
   */
  FUNCTION convert_date_to_second(
    pd_date IN DATE
  )
    RETURN INTEGER
  IS
    lts_date TIMESTAMP := Cast(pd_date AS TIMESTAMP);
  BEGIN
    RETURN Extract(SECOND from lts_date) +
           60 * (Extract(MINUTE from lts_date) +
           60 * Extract(HOUR from lts_date));
  END convert_date_to_second;


  /**
   * Inits special char table for coding and decoding value.
   **/
  PROCEDURE initSpecCharTable is
  BEGIN
  	gtab_special_chars(1).pattern := '\';
	  gtab_special_chars(2).pattern := '/';
	  gtab_special_chars(3).pattern := '"';
	  gtab_special_chars(4).pattern := chr(8);  -- backspace
	  gtab_special_chars(5).pattern := chr(9);  -- tablulation
	  gtab_special_chars(6).pattern := chr(10); -- new line
	  gtab_special_chars(7).pattern := chr(12); -- form feed
	  gtab_special_chars(8).pattern := chr(13); -- carriage return
	  gtab_special_chars(9).pattern := '#hex';  -- four hexadecimal digit
	  --
	  gtab_special_chars(1).replaceBy := '\\';
	  gtab_special_chars(2).replaceBy := '\/';
	  gtab_special_chars(3).replaceBy := '\"';
	  gtab_special_chars(4).replaceBy := '\b'; -- backspace
	  gtab_special_chars(5).replaceBy := '\t'; -- tablulation
	  gtab_special_chars(6).replaceBy := '\n'; -- new line
	  gtab_special_chars(7).replaceBy := '\f'; -- form feed
	  gtab_special_chars(8).replaceBy := '\r'; -- carriage return
	  gtab_special_chars(9).replaceBy := '\u'; -- four hexadecimal digit
  END initSpecCharTable;

  /**
   * Initialise les variables globales du module
   * - gv_dic_holiday_
   */
  PROCEDURE init_module AS
    TYPE RefCursor IS REF CURSOR;

    lcob_sql clob := empty_clob();
    lrec_color_code ColorCodeRec;
    lrefc_color_code RefCursor;
  BEGIN
    lcob_sql := pcs.pc_sql.getsql('DIC_SCH_PERIOD_1',
                                  'HrmPortalAppModule',
                                  'ViewAbsenceColorCode',
                                  null, 'ANSI SQL', false);
    /* gv_dic_holiday_ */
    BEGIN
      EXECUTE IMMEDIATE 'select id from (' || to_char(lcob_sql) || ') where code = 1'
        INTO gv_dic_holiday;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          dbms_output.put_line('web_hrm_portal_fct.init_module failed: CODE = 1 Not Found');
        WHEN TOO_MANY_ROWS THEN
          dbms_output.put_line('web_hrm_portal_fct.init_module failed: Multiple definition of Code = 1');
        WHEN OTHERS THEN
          dbms_output.put_line('web_hrm_portal_fct.init_module failed ' ||
                               SQLCODE() || ':' || SQLERRM());
    END;
    BEGIN
      OPEN lrefc_color_code FOR to_char(lcob_sql);
      LOOP
        FETCH lrefc_color_code INTO lrec_color_code;
        EXIT WHEN lrefc_color_code%NOTFOUND;
        gassoc_color_code(lrec_color_code.ID) := lrec_color_code;
        CASE lrec_color_code.CODE
          WHEN 1 THEN
            gs_code_holiday := lrec_color_code.ID;
          WHEN 2 THEN
           gs_code_more_absence := lrec_color_code.ID;
          WHEN 999 THEN
            gs_code_failure := lrec_color_code.ID;
          ELSE
            NULL;
        END CASE;
      END LOOP;
      CLOSE lrefc_color_code;
    EXCEPTION
      WHEN OTHERS THEN
      dbms_output.put_line('web_hrm_portal_fct.init_module fill color table ' ||
                               SQLCODE() || ':' || SQLERRM());
    END;
  END init_module;

BEGIN
  initSpecCharTable;
  init_module;
  gn_initialized := 1;
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('web_hrm_portal_fct initialization failed ' ||
                           SQLCODE() || ':' || SQLERRM());
END web_hrm_portal_fct;
