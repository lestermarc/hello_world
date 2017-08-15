--------------------------------------------------------
--  DDL for Package Body WEB_UPD_DATA_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_UPD_DATA_FCT" 
as
/******************************************************************************
   NAME:       WEB_UPD_DATA_FCT
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10.10.2008  FMa RRi          1. Created this package.
******************************************************************************/

  /*  Pourrais être configurable */
  cenable_notification constant number          := 1;
  cemail_default       constant varchar2(4000)  := 'eHrmPortal@proconcept.ch';
  cline_break          constant varchar2(1)      := chr(10);

  type tstring_array is table of varchar2(4000);

  type tdata is record(
    field_name web_update_data.wup_fieldname%type
  , new_c      web_update_data.wup_new_c%type
  , new_d      web_update_data.wup_new_d%type
  , new_n      web_update_data.wup_new_n%type
  , old_c      web_update_data.wup_old_c%type
  , old_d      web_update_data.wup_old_d%type
  , old_n      web_update_data.wup_old_n%type
  );

  type t_entity_list is table of t_entity_code
    index by t_entity_code;
  type t_country_code is table of integer index by hrm_country.cnt_code%type;
  type t_country_name is table of tstring_array index by pls_integer;

  /* Definition des entit‚s */
  type tc_entities is ref cursor;

  m_molk                        tentities_table;
  m_countries_code              t_country_code;
  m_countries_name              t_country_name;

  procedure init_table_entities
  as
    cEntities tc_entities;
  begin
    m_molk  := tentities_table();

    open cEntities for
      select tab
           , fld
           , seq
           , entity
        from ( (select 'PAC_SCHEDULE_PERIOD' tab
                     , 'DIC_SCH_PERIOD_1_ID' fld
                     , 1 seq
                     , web_upd_data_fct.s_entity_schedule entity
                  from dual
                union
                select 'PAC_SCHEDULE_PERIOD' tab
                     , 'SCP_COMMENT' fld
                     , 2 seq
                     , web_upd_data_fct.s_entity_schedule entity
                  from dual
                union
                select 'PAC_SCHEDULE_PERIOD' tab
                     , 'SCP_FROM_DATE' fld
                     , 3 seq
                     , web_upd_data_fct.s_entity_schedule entity
                  from dual
                union
                select 'PAC_SCHEDULE_PERIOD' tab
                     , 'SCP_TO_DATE' fld
                     , 4 seq
                     , web_upd_data_fct.s_entity_schedule entity
                  from dual
                union
                select 'PAC_SCHEDULE_PERIOD' tab
                     , 'SCP_OPEN_TIME' fld
                     , 5 seq
                     , web_upd_data_fct.s_entity_schedule entity
                  from dual
                union
                select 'PAC_SCHEDULE_PERIOD' tab
                     , 'SCP_CLOSE_TIME' fld
                     , 6 seq
                     , web_upd_data_fct.s_entity_schedule entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_LAST_NAME' fld
                     , 3 seq
                     , web_upd_data_fct.s_entity_person_per entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_FIRST_NAME' fld
                     , 2 seq
                     , web_upd_data_fct.s_entity_person_per entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'C_CIVIL_STATUS' fld
                     , 1 seq
                     , web_upd_data_fct.s_entity_person_per entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_HOME_PHONE' fld
                     , 1 seq
                     , web_upd_data_fct.s_entity_person_com entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_MOBILE_PHONE' fld
                     , 2 seq
                     , web_upd_data_fct.s_entity_person_com entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_EMAIL' fld
                     , 3 seq
                     , web_upd_data_fct.s_entity_person_com entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_HOMESTREET' fld
                     , 1 seq
                     , web_upd_data_fct.s_entity_person_add entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_HOMECITY' fld
                     , 2 seq
                     , web_upd_data_fct.s_entity_person_add entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_HOMEPOSTALCODE' fld
                     , 3 seq
                     , web_upd_data_fct.s_entity_person_add entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_HOMECOUNTRY' fld
                     , 4 seq
                     , web_upd_data_fct.s_entity_person_add entity
                  from dual
                union
                select 'HRM_PERSON' tab
                     , 'PER_HOMESTATE' fld
                     , 5 seq
                     , web_upd_data_fct.s_entity_person_add entity
                  from dual)
                /* HRM_POSTULATION */
                union
              (select 'HRM_POSTULATION' tab
                     , 'HRM_JOB_ID' fld
                     , 1 seq
                     , web_upd_data_fct.s_entity_apply_job entity
                  from dual
                union
                select 'HRM_POSTULATION' tab
                     , 'POS_DATE' fld
                     , 2 seq
                     , web_upd_data_fct.s_entity_apply_job entity
                  from dual)
                /* HRM_SUBSCRIPTION */
                union
              (select 'HRM_SUBSCRIPTION' tab
                     , 'HRM_SUBSCRIPTION_ID' fld
                     , 1 seq
                     , web_upd_data_fct.s_entity_join_training entity
                  from dual
                union
                select 'HRM_SUBSCRIPTION' tab
                     , 'SUB_PLAN_DATE' fld
                     , 2 seq
                     , web_upd_data_fct.s_entity_join_training entity
                  from dual
                union
                select 'HRM_SUBSCRIPTION' tab
                     , 'SUB_COMMENT' fld
                     , 3 seq
                     , web_upd_data_fct.s_entity_join_training entity
                  from dual
                union
                select 'HRM_SUBSCRIPTION' tab
                     , 'C_TRAINING_PRIORITY' fld
                     , 4 seq
                     , web_upd_data_fct.s_entity_join_training entity
                  from dual
                )
                );

    fetch cEntities
    bulk collect into m_molk;

    close cEntities;
  end init_table_entities;

  function list2array(list varchar2) return tstring_array
  is
    item varchar2(4000);
    separator varchar2(1) := '|';
    startPos integer := 1;
    pos integer := 0;
    result tstring_array := tstring_array();
  begin
   loop
     pos := nvl(instr(list, separator, startPos), 0);
     if (pos > 0) then
       item := trim(substr(list, startPos, pos-startPos));
       if (length(item) > 0) then
         result.extend;
         result(result.count) := item;
       end if;
       startPos := pos + 1;
     else
       exit;
     end if;
   end loop;
   if (startPos <= length(list)) then
     item := trim(substr(list, startPos));
     if (length(item) > 0) then
       result.extend;
       result(result.count) := item;
     end if;
    end if;
    return result;
  end list2array;


  procedure init_countries
  as
    nindex integer := 0;
    codes tstring_array;
    names tstring_array;
  begin
    for tplCountry in (select cnt_code, cnt_name, cnt_postal_code zip
                         from hrm_country
                        where not cnt_code is null) loop
      nindex := nindex + 1;
      names := list2array(tplCountry.cnt_name);
      m_countries_name(nindex) := names;
      codes := list2array(tplCountry.cnt_code);
      for i in 1..codes.count loop
        m_countries_code(upper(codes(i))) := nindex;
      end loop;
    end loop;
  end init_countries;

  /**
  * function retrieve_table_entities
  * Description
  *   voir sp‚cification
  */
  function retrieve_table_entities
    return tentities_table pipelined
  is
  begin
    for i in m_molk.first .. m_molk.last loop
      pipe row(m_molk(i) );
    end loop;
  end retrieve_table_entities;


  /**
  * function retrieve_web_update_data
  * Description
  *   voir sp‚cification
  */
  function retrieve_web_update_data(wud_data_list in t_web_update_data_list)
    return t_web_update_data pipelined
  is
  begin
    for i in wud_data_list.first .. wud_data_list.last loop
      pipe row(wud_data_list(i) );
    end loop;
  end retrieve_web_update_data;

  /**
  * function retrieve_table_hrm_in_charge
  * Description
  *   voir sp‚cification
  */
  function retrieve_table_hrm_in_charge(phrm_in_charge_id hrm_person.hrm_person_id%type)
    return thrm_in_charge_table pipelined
  is
    type tref_cursor is ref cursor;

    person_id_cur tref_cursor;
    person_id     hrm_person.HRM_PERSON_ID%type;
    sql_stmt      clob;
  begin
    sql_stmt := pcs.pc_sql.getSQL('HRM_PERSON',
                                  'HrmPortalAppModule',
                                  'ViewMyDependants',
                                  null, 'ANSI SQL', false);
    open person_id_cur for 'select hrm_person_id from (' || to_char(sql_stmt) || ')' using phrm_in_charge_id;
    loop
      fetch person_id_cur
       into person_id;

      exit when person_id_cur%notfound;
      pipe row(person_id);
    end loop;

    close person_id_cur;
  end;


  /**
  * function get_appl_text
  * Description
  *   Retourne un texte.
  * @return retourn un texte.
  */
  function get_appl_text(
    pcode         pcs.v_pc_appltxt.aph_code%type
  , ppclangid     pcs.v_pc_appltxt.pc_lang_id%type
  , pctexttype    pcs.v_pc_appltxt.c_text_type%type
  , pdicpcthemeid pcs.v_pc_appltxt.dic_pc_theme_id%type default '065-WEB'
  )
    return varchar2
  is
    text varchar2(4000);
  begin
    select apt_text
      into text
      from pcs.v_pc_appltxt
     where aph_code = pcode
       and pc_lang_id = ppclangid
       and c_text_type = pctexttype
       and dic_pc_theme_id = pdicpcthemeid;

    return text;
  exception
    when no_data_found then
      return '#' || pcode;
  end get_appl_text;

  function retrieve_person_data(
    pparenttable            varchar2
  , pparentid               number
  , ppersondata  out nocopy tperson_data
  , perrormsg    out nocopy varchar2
  )
    return integer
  is
    result integer;
  begin
    result     := web_functions.return_ok;
    perrormsg  := '';

    case pparenttable
      when 'HRM_PERSON' then
        select hp.hrm_person_id
             , hp.per_first_name
             , hp.per_last_name
             , hp.per_email
             , hp.pc_lang_id
          into ppersondata.id
             , ppersondata.first_name
             , ppersondata.last_name
             , ppersondata.email_address
             , ppersondata.pc_lang_id
          from hrm_person hp
         where hrm_person_id = pparentid;
      else
        result     := web_functions.return_fatal;
        perrormsg  := 'Table Parent pas connue ' || pparenttable;
    end case;

    return result;
  exception
    when no_data_found then
      perrormsg  := 'Parent ID ' || pparentid || ' pas trouv‚ dans ' || ' Table Parent ' || pparenttable;
      return web_functions.return_error;
  end retrieve_person_data;

  /**
  *
  */
  function retrieve_eco_user_data(
    pecu_id                econcept.eco_users.ECO_USERS_ID%type
  , pcompany               varchar2
  , ppersondata out nocopy tperson_data
  , perrormsg   out nocopy varchar2
  )
    return integer
  is
    result        integer;
    hrm_person_id number(12);
  begin
    result         := web_functions.return_ok;
    perrormsg      := '';
    hrm_person_id  := econcept.eco_users_mgm.GETFIRSTLINK(pecu_id, pcompany, 'HRM_PERSON');
    return retrieve_person_data('HRM_PERSON', hrm_person_id, ppersondata, perrormsg);
    return result;
  exception
    when no_data_found then
      perrormsg  := 'ECO_USER_ID ' || pecu_id || ' pas trouv‚';
      return web_functions.return_error;
  end retrieve_eco_user_data;

  /**
  *
  */
  function convert_cnd_2_varchar(pchar varchar, pnum number, pdate date)
    return varchar2
  is
  begin
    case
      when pchar is not null then
        return pchar;
      when pnum is not null then
        return to_char(pnum);
      when pdate is not null then
        return to_char(pdate);
      else
        return null;
    end case;
  end convert_cnd_2_varchar;

  /**
  *
  */
  function send_email(pmail eml_sender.tmail, perrormsg out nocopy varchar2)
    return number
  is
    verrorcodes varchar2(4000);
    vmailid     number;
  begin
    verrorcodes  := eml_sender.send(perrormsg, vmailid, pmail);

    if (verrorcodes is null) then
      perrormsg  := vmailid;
    end if;

    return verrorcodes;
  end send_email;

  /**
  *
  */
  procedure initialize_mail(
    pentity_code               t_entity_code
  , paction                    varchar2
  , pcomment                   varchar
  , pvalidator                 tperson_data
  , pperson                    tperson_data
  , pmail        in out nocopy eml_sender.tmail
  )
  as
    result  integer        := web_functions.RETURN_OK;
    sresult varchar2(4000);
  begin
    pmail.msender         := pvalidator.email_address;
    pmail.mreplyto        := pvalidator.email_address;
    pmail.mrecipients     := pperson.email_address;
    pmail.mccrecipients   := '';
    pmail.mbccrecipients  := '';
    pmail.msubject        := get_subject_mail(pentity_code, paction, pperson.pc_lang_id);
    pmail.mbodyplain      :=
                        get_text_refusal_mail('plain', pcomment, pentity_code, pvalidator, pperson, pperson.pc_lang_id);
    pmail.mbodyhtml       :=
                         get_text_refusal_mail('html', pcomment, pentity_code, pvalidator, pperson, pperson.pc_lang_id);
    pmail.mnotification   := cenable_notification;
    pmail.mpriority       := eml_sender.cpriotity_high_level;
    pmail.mcustomheaders  := 'X-Mailer: PCS mailer';
    pmail.msendmode       := eml_sender.csendmode_immediate;
    pmail.mdatetosend     := sysdate;
    pmail.mbackupmode     := eml_sender.cbackup_database;
    pmail.mbackupoptions  := '';
  end initialize_mail;

  /**
   * select * from table(web_upd_data_fct.GET_UPD_DATA_LIST(1302804,1))
   */
  function get_upd_data_list(
    phrm_in_charge_id hrm_division.hrm_in_charge_id%type
  , ppc_lang_id       pcs.pc_lang.pc_lang_id%type
  )
    return web_upd_data_entity_table pipelined
  is
    out_rec     web_upd_data_entity;
    entity_data t_entity_data_gudl;
  begin
    if    (phrm_in_charge_id is null)
       or (ppc_lang_id is null) then
      /* @TODO: Where log the error ? */
      return;
    else
      for tpldatalist in
        (select distinct wup_recid recid
                       , entity entity_code
                       , wup_date_create date_create
                       , c_web_update_state state
                       , get_entity_name_gudl(web_update_data_id, entity, ppc_lang_id) entity_name
                    from (   /* Filtre des employ‚s par responsable */
                          select web_update_data_id
                               , wup_recid
                               , wup_tabname
                               , wup_fieldname
                               , wup_date_create
                               , c_web_update_state
                            from (select column_value hrm_person_id
                                    from table(retrieve_table_hrm_in_charge(phrm_in_charge_id) ) ) in_charge
                               , web_update_data
                           where c_web_update_state in
                                   (web_upd_data_fct.s_new
                                  , web_upd_data_fct.s_update
                                  , web_upd_data_fct.s_delete_to_validate
                                   )
                             and in_charge.hrm_person_id =
                                                       case
                                                         when wup_tabname = 'HRM_PERSON' then wup_recid
                                                         else wud_parent_id
                                                       end) wud
                       , (select tab
                               , fld
                               , entity
                            from table(retrieve_table_entities() ) ) tble
                   where tble.entity not in (web_upd_data_fct.s_entity_apply_job)
                     and wud.wup_tabname = tble.tab
                     and wud.wup_fieldname = tble.fld
                order by entity) loop
        entity_data.recid                := tpldatalist.recid;
        entity_data.code                 := tpldatalist.entity_code;
        entity_data.state                := tpldatalist.state;
        entity_data.date_create          := tpldatalist.date_create;
        out_rec.entity_code              := tpldatalist.entity_code;
        out_rec.wup_recid                := tpldatalist.recid;
        out_rec.entity_name              := tpldatalist.entity_name;
        out_rec.entity_info_to_validate  := get_text_gudl(entity_data, ppc_lang_id);
        out_rec.entity_info_bulle        := get_text_bulle_gudl(entity_data, ppc_lang_id);
        out_rec.entity_datetime          := tpldatalist.date_create;
        pipe row(out_rec);
      end loop;
    end if;
  end get_upd_data_list;

  /** PAC_SCHEDULE_PERIOD_SAVE
  declare
  a number(1);
  msg varchar2(2000);
  begin
    a:= WEB_UPD_DATA_FCT.PAC_SCHEDULE_PERIOD_SAVE(60003342102, --HRM_PERSON_ID
                           1,                                  --PAC_SCHEDULE_PERIOD_ID
                           'VAC',                              --DIC_SCH_PERIOD_1_ID  nouvelle valeur
                           'COMMENT',                          --SCP_COMMENT       nouvelle valeur
                           to_date('24082008','ddmmyyyy'),     --SCP_FROM_DATE nouvelle valeur
                           to_date('27082008','ddmmyyyy'),     --SCP_TO_DATE nouvelle valeur
                           0.5,                                --SCP_OPEN_TIME nouvelle valeur
                           0.6,                                --SCP_CLOSE_TIME nouvelle valeur
                           null, --DIC_SCH_PERIOD_1_ID  ancienne valeur
                           null, --SCP_COMMENT ancienne valeur
                           null, --SCP_FROM_DATE ancienne valeur
                           null, --SCP_TO_DATE ancienne valeur
                           null, --SCP_OPEN_TIME ancienne valeur
                           null,  --SCP_CLOSE_TIME ancienne valeur
                           '00',  -- '0' si cr‚ation, '1' si modification
                           'RRI00', --Initials de l'utilisateur en cours
                            msg     --message de retour
                         );
    end;

  */
  function pac_schedule_period_save(
    phrm_person_id                      web_update_data.wup_recid%type
  , ppac_schedule_period_id             pac_schedule_period.pac_schedule_period_id%type
  ,
    /*                     new VALUES                                     */
    pdic_sch_period_1_id                pac_schedule_period.dic_sch_period_1_id%type
  , pscp_comment                        pac_schedule_period.scp_comment%type
  , pscp_from_date                      pac_schedule_period.scp_date%type
  , pscp_to_date                        pac_schedule_period.scp_date%type
  , pscp_open_time                      pac_schedule_period.scp_open_time%type
  , pscp_close_time                     pac_schedule_period.scp_close_time%type
  ,
    /*                     OLD VALUES                                     */
    pdic_sch_period_1_id_old            pac_schedule_period.dic_sch_period_1_id%type
  , pscp_comment_old                    pac_schedule_period.scp_comment%type
  , pscp_from_date_old                  pac_schedule_period.scp_date%type
  , pscp_to_date_old                    pac_schedule_period.scp_date%type
  , pscp_open_time_old                  pac_schedule_period.scp_open_time%type
  , pscp_close_time_old                 pac_schedule_period.scp_close_time%type
  , pstate                              number
  , pecu_initial                        econcept.eco_users.ecu_initial%type
  , perrormsg                out nocopy varchar2
  )
    return integer
  is
    newpac_schedule_period_id web_update_data.wup_recid%type;
    updateofnotvalidatedrow   number(1);
    newstate                  web_update_data.c_web_update_state%type;
    now                       date                                      := sysdate;
    pn_max_length_comment     number := 255;
  begin

    /* CheckPoint des valeurs des paramŠtres:
     * - pscp_comment:
     * - pscp_from_date <= pscp_to_date
     */
    BEGIN
      SELECT utc.data_length INTO pn_max_length_comment
        FROM user_tab_columns utc
       WHERE utc.table_name = 'PAC_SCHEDULE_PERIOD'
         AND utc.column_name = 'SCP_COMMENT';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
    END;
    IF Length(pscp_comment) > pn_max_length_comment THEN
      perrormsg := 'Maximal Length for Comment is ' || pn_max_length_comment;
      RETURN web_functions.return_error;
    END IF;
    IF pscp_from_date > pscp_to_date THEN
      perrormsg := 'From Date is greatest than To Date';
      RETURN web_functions.return_error;
    END IF;
    newstate  := to_char(pstate);

    if (newstate in(web_upd_data_fct.s_update, web_upd_data_fct.s_delete_to_validate) ) then
      -- V‚rifie l'existance de...
      --select count(*) into updateOfNotValidatedRow
      --from dual
      --where Exists(select 1 from web_update_data
      --             where WUP_RECID=pPAC_SCHEDULE_PERIOD_ID and C_WEB_UPDATE_STATE=web_upd_data_fct.S_NEW);
      -- Lequel choisir?
      -- Compte le nombre de
      select count(*)
        into updateofnotvalidatedrow
        from web_update_data
       where wup_recid = ppac_schedule_period_id
         and c_web_update_state = web_upd_data_fct.s_new;

      --si modification d'un ‚l‚ment modifi‚
      if (    updateofnotvalidatedrow > 0
          and newstate = web_upd_data_fct.s_update) then
        newstate  := web_upd_data_fct.s_new;
      end if;

      delete      web_update_data
            where wup_recid = ppac_schedule_period_id
              and wup_tabname = 'PAC_SCHEDULE_PERIOD';

      newpac_schedule_period_id  := ppac_schedule_period_id;
    else
      select init_id_seq.nextval
        into newpac_schedule_period_id
        from dual;
    end if;

    /** DIC_SCH_PERIOD_1_ID **/
    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'PAC_SCHEDULE_PERIOD'
               , newpac_schedule_period_id
               , 'DIC_SCH_PERIOD_1_ID'
               , newstate
               , null
               , pdic_sch_period_1_id_old
               , null
               , null
               , pdic_sch_period_1_id
               , null
               , 'HRM_PERSON'
               , phrm_person_id
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    /** SCP_COMMENT **/
    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'PAC_SCHEDULE_PERIOD'
               , newpac_schedule_period_id
               , 'SCP_COMMENT'
               , newstate
               , null
               , pscp_comment_old
               , null
               , null
               , pscp_comment
               , null
               , 'HRM_PERSON'
               , phrm_person_id
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    /** SCP_FROM_DATE **/
    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'PAC_SCHEDULE_PERIOD'
               , newpac_schedule_period_id
               , 'SCP_FROM_DATE'
               , newstate
               , null
               , null
               , pscp_from_date_old
               , null
               , null
               , pscp_from_date
               , 'HRM_PERSON'
               , phrm_person_id
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    /** SCP_TO_DATE **/
    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'PAC_SCHEDULE_PERIOD'
               , newpac_schedule_period_id
               , 'SCP_TO_DATE'
               , newstate
               , null
               , null
               , pscp_to_date_old
               , null
               , null
               , pscp_to_date
               , 'HRM_PERSON'
               , phrm_person_id
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    /** SCP_OPEN_TIME **/
    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'PAC_SCHEDULE_PERIOD'
               , newpac_schedule_period_id
               , 'SCP_OPEN_TIME'
               , newstate
               , pscp_open_time_old
               , null
               , null
               , pscp_open_time
               , null
               , null
               , 'HRM_PERSON'
               , phrm_person_id
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    /** SCP_CLOSE_TIME **/
    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'PAC_SCHEDULE_PERIOD'
               , newpac_schedule_period_id
               , 'SCP_CLOSE_TIME'
               , newstate
               , pscp_close_time_old
               , null
               , null
               , pscp_close_time
               , null
               , null
               , 'HRM_PERSON'
               , phrm_person_id
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    return web_functions.return_ok;
  end pac_schedule_period_save;

  function pac_schedule_period_process(pid web_update_data.wup_recid%type, perrormsg out nocopy varchar2)
    return integer
  is
    ascheduleid             pac_schedule.pac_schedule_id%type;
    anonworkingday          number(1);
    acomment                pac_schedule_period.scp_comment%type;
    ahrmpersonid            hrm_person.hrm_person_id%type;
    adicschperiod1          dic_sch_period_1.dic_sch_period_1_id%type;
    adicschperiod2          dic_sch_period_2.dic_sch_period_2_id%type;
    ainitials               pac_schedule_period.a_idcre%type;
    tmpfromdate             date;
    tmptodate               date;
    astarttime              date;
    aendtime                date;
    tmpstarttime            pac_schedule_period.scp_open_time%type            default 0.0;
    tmpendtime              pac_schedule_period.scp_close_time%type           default 0.0;
    etat                    varchar2(2);
    adayofweek              varchar2(3);
    anewpacscheduleperiodid pac_schedule_period.pac_schedule_period_id%type;
    countitem               number(12);
    ventryid                pac_schedule_period.scp_entry_id%type;
    vdays                   number(12);
    now                     date                                              := sysdate;

    type datetab is table of date
      index by pls_integer;

    days                    datetab;
  begin

    select c_web_update_state
      into etat
      from web_update_data
     where wup_tabname = 'PAC_SCHEDULE_PERIOD'
       and wup_recid = pid
       and wup_fieldname = 'SCP_FROM_DATE';

    if (etat = web_upd_data_fct.s_to_delete) then
      --search if pac_schedule_period exists
      delete      pac_schedule_period
            where pac_schedule_period_id = pid;

      --
      delete      web_update_data
            where wup_recid = pid
              and wup_tabname = 'PAC_SCHEDULE_PERIOD';

      return web_functions.return_ok;
    end if;

    --recherche si cr‚ation ou existant
    select wup_new_d
         , wup_initials_create
         , wud_parent_id
         , decode(PAC_I_LIB_SCHEDULE.isopenday(web_hrm_portal_fct.get_schedule_id(wud_parent_id),
                                                   wup_new_d, 'HRM_PERSON', wud_parent_id), 1, 0, 1)
         , to_char(wup_new_d, 'DY')
      into tmpfromdate
         , ainitials
         , ahrmpersonid
         , anonworkingday
         , adayofweek
      from web_update_data
     where wup_tabname = 'PAC_SCHEDULE_PERIOD'
       and wup_recid = pid
       and wup_fieldname = 'SCP_FROM_DATE';

    --select tmpDate+wup_new_n into aStartTime
    select wup_new_d
      into tmptodate
      from web_update_data
     where wup_tabname = 'PAC_SCHEDULE_PERIOD'
       and wup_recid = pid
       and wup_fieldname = 'SCP_TO_DATE';

    --select tmpDate+wup_new_n into aStartTime
    select wup_new_n
      into tmpstarttime
      from web_update_data
     where wup_tabname = 'PAC_SCHEDULE_PERIOD'
       and wup_recid = pid
       and wup_fieldname = 'SCP_OPEN_TIME';

    --select tmpDate+wup_new_n into aEndTime
    select wup_new_n
      into tmpendtime
      from web_update_data
     where wup_tabname = 'PAC_SCHEDULE_PERIOD'
       and wup_recid = pid
       and wup_fieldname = 'SCP_CLOSE_TIME';

    select wup_new_c
      into adicschperiod1
      from web_update_data
     where wup_tabname = 'PAC_SCHEDULE_PERIOD'
       and wup_recid = pid
       and wup_fieldname = 'DIC_SCH_PERIOD_1_ID';

    select wup_new_c
      into acomment
      from web_update_data
     where wup_tabname = 'PAC_SCHEDULE_PERIOD'
       and wup_recid = pid
       and wup_fieldname = 'SCP_COMMENT';

    select count(*)
      into countitem
      from pac_schedule_period
     where pac_schedule_period_id = pid;

    if (countitem = 0) then   --cas de la cr‚ation
      vdays  := tmptodate - tmpfromdate;

      if (vdays > 0) then
        select init_id_seq.nextval
          into ventryid
          from dual;
      else
        ventryid  := null;
      end if;

      --  Charge la table INDEX_BY avec toutes les date
      for i in 0 .. vdays loop
        days(i)  := tmpfromdate + i;
      end loop;

      -- insert into pac_schedule_period
      ascheduleid := web_hrm_portal_fct.get_schedule_id(ahrmpersonid);
      forall i in 0 .. vdays
        insert into pac_schedule_period
                    (pac_schedule_period_id
                   , pac_schedule_id
                   , c_day_of_week
                   , scp_date
                   , scp_nonworking_day
                   , scp_open_time
                   , scp_close_time
                   , scp_comment
                   , pac_custom_partner_id
                   , pac_supplier_partner_id
                   , pac_department_id
                   , fal_factory_floor_id
                   , hrm_person_id
                   , scp_resource_number
                   , scp_resource_capacity
                   , scp_resource_cap_in_qty
                   , scp_pieces_hour_cap
                   , dic_sch_period_1_id
                   , dic_sch_period_2_id
                   , a_datecre
                   , a_idcre
                   , scp_entry_id
                    )
             values (init_id_seq.nextval
                   , ascheduleid
                   , null   -- aDayOfWeek
                   , days(i)
                   , 0   --aNonWorkingDay non utilis‚ en RH
                   , tmpstarttime
                   --decode(aNonWorkingDay, 0, tmpStartTime, null)
        ,            tmpendtime
                   -- decode(aNonWorkingDay, 0, tmpEndTime, null)
        ,            acomment
                   , null
                   , null
                   , null
                   , null
                   , ahrmpersonid
                   , null
                   , null
                   , null
                   , null
                   , adicschperiod1
                   , adicschperiod2
                   , now
                   , ainitials
                   , ventryid
                    );
    end if;

    if (countitem <> 0) then   --modification
      update pac_schedule_period
         set c_day_of_week = adayofweek
           , scp_date = tmpfromdate
           , scp_nonworking_day = anonworkingday
           , scp_open_time = decode(anonworkingday, 0, tmpstarttime, null)
           , scp_close_time = decode(anonworkingday, 0, tmpendtime, null)
           , scp_comment = acomment
           , dic_sch_period_1_id = adicschperiod1
           , a_datemod = now
           , a_idmod = ainitials
       where pac_schedule_period_id = pid;
    end if;

    --delete web_update_data
    delete      web_update_data
          where wup_tabname = 'PAC_SCHEDULE_PERIOD'
            and wup_recid = pid;

    return web_functions.return_ok;
  end pac_schedule_period_process;

  function hrm_person_per_save(
    phrm_person_id                 web_update_data.wup_recid%type
  ,
    /*                     new VALUES                                     */
    pper_first_name                web_update_data.wup_old_c%type
  , pper_last_name                 web_update_data.wup_old_c%type
  ,
    /*                     old VALUES                                     */
    pper_first_name_old            web_update_data.wup_new_c%type
  , pper_last_name_old             web_update_data.wup_old_c%type
  , pecu_initial                   econcept.eco_users.ecu_initial%type
  , perrormsg           out nocopy varchar2
  )
    return integer
  is
  begin
    return web_functions.return_ok;
  end hrm_person_per_save;

  function hrm_person_per_process(pid web_update_data.wup_recid%type, perrormsg out nocopy varchar2)
    return integer
  is
  begin
    return web_functions.return_ok;
  end hrm_person_per_process;

  function hrm_person_com_save(
    phrm_person_id                   web_update_data.wup_recid%type
  ,
    /*                     new VALUES                                     */
    pper_home_phone                  web_update_data.wup_new_c%type
  , pper_mobile_phone                web_update_data.wup_new_c%type
  , pper_email                       web_update_data.wup_new_c%type
  ,
    /*                     old VALUES                                     */
    pper_home_phone_old              web_update_data.wup_new_c%type
  , pper_mobile_phone_old            web_update_data.wup_new_c%type
  , pper_email_old                   web_update_data.wup_new_c%type
  , pecu_initial                     econcept.eco_users.ecu_initial%type
  , perrormsg             out nocopy varchar2
  )
    return integer
  is
  begin
    return web_functions.return_ok;
  end;

  function hrm_person_com_process(pid web_update_data.wup_recid%type, perrormsg out nocopy varchar2)
    return integer
  is
    vhrm_person_id hrm_person.hrm_person_id%type;
    vecu_initial   econcept.eco_users.ecu_initial%type;
    updatedate     date;
    newchar        varchar2(2000);
  begin
    /*On passe les modification si changement*/

    /* PER_EMAIL */
    begin
      select wup_new_c
           , wup_initials_create
           , wup_date_create
        into newchar
           , vecu_initial
           , updatedate
        from web_update_data
       where wup_tabname = 'HRM_PERSON'
         and wup_recid = pid
         and wup_fieldname = 'PER_EMAIL'
         and equal_string(wup_old_c, wup_new_c) != 0;

      update hrm_person
         set (per_email, a_datemod, a_idmod) = (select newchar
                                                     , updatedate
                                                     , vecu_initial
                                                  from dual)
       where hrm_person_id = pid;
    exception
      when no_data_found then
        null;
    end;

    /* PER_HOME_PHONE */
    begin
      select wup_new_c
           , wup_initials_create
           , wup_date_create
        into newchar
           , vecu_initial
           , updatedate
        from web_update_data
       where wup_tabname = 'HRM_PERSON'
         and wup_recid = pid
         and wup_fieldname = 'PER_HOME_PHONE'
         and equal_string(wup_old_c, wup_new_c) != 0;

      update hrm_person
         set (per_home_phone, a_datemod, a_idmod) = (select newchar
                                                          , updatedate
                                                          , vecu_initial
                                                       from dual)
       where hrm_person_id = pid;
    exception
      when no_data_found then
        null;
    end;

    /* PER_MOBILE_PHONE */
    begin
      select wup_new_c
           , wup_initials_create
           , wup_date_create
        into newchar
           , vecu_initial
           , updatedate
        from web_update_data
       where wup_tabname = 'HRM_PERSON'
         and wup_fieldname = 'PER_MOBILE_PHONE'
         and wup_recid = pid
         and equal_string(wup_old_c, wup_new_c) != 0;

      update hrm_person
         set (per_mobile_phone, a_datemod, a_idmod) = (select newchar
                                                            , updatedate
                                                            , vecu_initial
                                                         from dual)
       where hrm_person_id = pid;
    exception
      when no_data_found then
        null;
    end;

    delete      web_update_data
          where wup_tabname = 'HRM_PERSON'
            and wup_fieldname in('PER_EMAIL', 'PER_HOME_PHONE', 'PER_MOBILE_PHONE')
            and wup_recid = pid;

    return web_functions.return_ok;
  end;

  /** TO TEST IT
  declare
  a number(1);
  msg varchar2(2000);
  begin
  a:= WEB_UPD_DATA_FCT.HRM_PERSON_ADD_SAVE(60003342102,
                               'new street',
                               'new city',
                               'new state',
                               'new postalcode',
                               'new country',
                               'old street',
                               'old city',
                               'old state',
                               'old postal',
                               'old country',
                               'RRI00',
                               msg
                         );
  end;
   */
  function hrm_person_add_save(
    phrm_person_id                      web_update_data.wup_recid%type
  ,
    /*                     new VALUES                                     */
    pper_homestreet                     web_update_data.wup_new_c%type
  , pper_homecity                       web_update_data.wup_new_c%type
  , pper_homestate                      web_update_data.wup_new_c%type
  , pper_homespostalcode                web_update_data.wup_new_c%type
  , pper_homecountry                    web_update_data.wup_new_c%type
  ,
    /*                     old VALUES                                     */
    pper_homestreet_old                 web_update_data.wup_new_c%type
  , pper_homecity_old                   web_update_data.wup_new_c%type
  , pper_homestate_old                  web_update_data.wup_new_c%type
  , pper_homespostalcode_old            web_update_data.wup_new_c%type
  , pper_homecountry_old                web_update_data.wup_new_c%type
  , pecu_initial                        econcept.eco_users.ecu_initial%type
  , perrormsg                out nocopy varchar2
  )
    return integer
  is
    now date := sysdate;
  begin
    --Supprime les ‚ventuelles donn‚es en cours de modifications
    delete      web_update_data
          where wup_recid = phrm_person_id
            and wup_tabname in(select tab
                                 from table(web_upd_data_fct.retrieve_table_entities)
                                where entity = web_upd_data_fct.s_entity_person_add)
            and wup_fieldname in(select fld
                                   from table(web_upd_data_fct.retrieve_table_entities)
                                  where entity = web_upd_data_fct.s_entity_person_add);

    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'HRM_PERSON'
               , phrm_person_id
               , 'PER_HOMESTREET'
               , web_upd_data_fct.s_update
               , null
               , pper_homestreet_old
               , null
               , null
               , pper_homestreet
               , null
               , null
               , null
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'HRM_PERSON'
               , phrm_person_id
               , 'PER_HOMECITY'
               , web_upd_data_fct.s_update
               , null
               , pper_homecity_old
               , null
               , null
               , pper_homecity
               , null
               , null
               , null
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'HRM_PERSON'
               , phrm_person_id
               , 'PER_HOMESTATE'
               , web_upd_data_fct.s_update
               , null
               , pper_homestate_old
               , null
               , null
               , pper_homestate
               , null
               , null
               , null
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'HRM_PERSON'
               , phrm_person_id
               , 'PER_HOMESPOSTALCODE'
               , web_upd_data_fct.s_update
               , null
               , pper_homespostalcode_old
               , null
               , null
               , pper_homespostalcode
               , null
               , null
               , null
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    insert into web_update_data
                (web_update_data_id
               , wup_tabname
               , wup_recid
               , wup_fieldname
               , c_web_update_state
               , wup_old_n
               , wup_old_c
               , wup_old_d
               , wup_new_n
               , wup_new_c
               , wup_new_d
               , wud_parent_tab
               , wud_parent_id
               , wup_initials_create
               , wup_date_create
               , wup_initials_valid
               , wup_date_valid
               , wup_date_proces
                )
         values (init_id_seq.nextval
               , 'HRM_PERSON'
               , phrm_person_id
               , 'PER_HOMECOUNTRY'
               , web_upd_data_fct.s_update
               , null
               , pper_homecountry_old
               , null
               , null
               , pper_homecountry
               , null
               , null
               , null
               , pecu_initial
               , now
               , null
               , null
               , null
                );

    return web_functions.return_ok;
  end hrm_person_add_save;

  function hrm_person_address_process(pid web_update_data.wup_recid%type, perrormsg out nocopy varchar2)
    return integer
  is
    newchar      varchar2(2000);
    vecu_initial hrm_person.a_idmod%type;
    updatedate   date;
  begin
    /* PER_HOMECOUNTRY */
    begin
      select wup_new_c
           , wup_initials_create
           , wup_date_create
        into newchar
           , vecu_initial
           , updatedate
        from web_update_data
       where wup_tabname = 'HRM_PERSON'
         and wup_recid = pid
         and wup_fieldname = 'PER_HOMECOUNTRY'
         and equal_string(wup_old_c, wup_new_c) != 0;

      update hrm_person
         set (per_homecountry, a_datemod, a_idmod) = (select newchar
                                                           , updatedate
                                                           , vecu_initial
                                                        from dual)
       where hrm_person_id = pid;
    exception
      when no_data_found then
        null;
    end;

    begin
      select wup_new_c
           , wup_initials_create
           , wup_date_create
        into newchar
           , vecu_initial
           , updatedate
        from web_update_data
       where wup_tabname = 'HRM_PERSON'
         and wup_recid = pid
         and wup_fieldname = 'PER_HOMECITY'
         and equal_string(wup_old_c, wup_new_c) != 0;

      update hrm_person
         set (per_homecity, a_datemod, a_idmod) = (select newchar
                                                        , updatedate
                                                        , vecu_initial
                                                     from dual)
       where hrm_person_id = pid;
    exception
      when no_data_found then
        null;
    end;

    begin
      select wup_new_c
           , wup_initials_create
           , wup_date_create
        into newchar
           , vecu_initial
           , updatedate
        from web_update_data
       where wup_tabname = 'HRM_PERSON'
         and wup_recid = pid
         and wup_fieldname = 'PER_HOMESTATE'
         and equal_string(wup_old_c, wup_new_c) != 0;

      update hrm_person
         set (per_homestate, a_datemod, a_idmod) = (select newchar
                                                         , updatedate
                                                         , vecu_initial
                                                      from dual)
       where hrm_person_id = pid;
    exception
      when no_data_found then
        null;
    end;

    begin
      select wup_new_c
           , wup_initials_create
           , wup_date_create
        into newchar
           , vecu_initial
           , updatedate
        from web_update_data
       where wup_tabname = 'HRM_PERSON'
         and wup_recid = pid
         and wup_fieldname = 'PER_HOMEPOSTALCODE'
         and equal_string(wup_old_c, wup_new_c) != 0;

      update hrm_person
         set (per_homepostalcode, a_datemod, a_idmod) = (select newchar
                                                              , updatedate
                                                              , vecu_initial
                                                           from dual)
       where hrm_person_id = pid;
    exception
      when no_data_found then
        null;
    end;

    begin
      select wup_new_c
           , wup_initials_create
           , wup_date_create
        into newchar
           , vecu_initial
           , updatedate
        from web_update_data
       where wup_tabname = 'HRM_PERSON'
         and wup_recid = pid
         and wup_fieldname = 'PER_HOMESTREET'
         and equal_string(wup_old_c, wup_new_c) != 0;

      update hrm_person
         set (per_homestreet, a_datemod, a_idmod) = (select newchar
                                                          , updatedate
                                                          , vecu_initial
                                                       from dual)
       where hrm_person_id = pid;
    exception
      when no_data_found then
        null;
    end;

    /* Mise … jour du champ PER_MAIL_ADDRESS */
    update hrm_person set per_mail_add_selected = (select encodeAddress(per_homestreet
                                                                      , per_homepostalcode
                                                                      , per_homecity
                                                                      , per_homestate
                                                                      , per_homecountry)
                                                     from hrm_person
                                                    where hrm_person_id = pid)
     where hrm_person_id = pid;

    delete      web_update_data
          where wup_recid = pid
            and wup_tabname in(select tab
                                 from table(web_upd_data_fct.retrieve_table_entities)
                                where entity = 'HRM_PERSON_ADDRESS')
            and wup_fieldname in(select fld
                                   from table(web_upd_data_fct.retrieve_table_entities)
                                  where entity = 'HRM_PERSON_ADDRESS');

    return web_functions.return_ok;
  end hrm_person_address_process;

  /**
  *
  */
  function hrm_subscription_process(pid web_update_data.wup_recid%type, perrormsg out nocopy varchar2)
    return integer
  is
  begin
    return web_functions.return_ok;
  end hrm_subscription_process;

  /**
  *
  */
  function web_upd_process(
    pid                     web_update_data.wup_recid%type
  , pentity_code            t_entity_code
  , perrormsg    out nocopy varchar2
  )
    return integer
  is
  begin
    case pentity_code
      when web_upd_data_fct.s_entity_person_per then
        return hrm_person_per_process(pid, perrormsg);
      when web_upd_data_fct.s_entity_person_com then
        return hrm_person_com_process(pid, perrormsg);
      when web_upd_data_fct.s_entity_person_add then
        return hrm_person_address_process(pid, perrormsg);
      when web_upd_data_fct.s_entity_schedule then
        return pac_schedule_period_process(pid, perrormsg);
      when web_upd_data_fct.s_entity_join_training then
        return hrm_subscription_process(pid, perrormsg);
      else
        perrormsg  := 'entity ' || pentity_code || ' not defined. Update not processed';
        return web_functions.return_error;
    end case;
  end web_upd_process;

  /**
  *
  */
  function get_text_gudl(pdata t_entity_data_gudl, ppc_lang_id pcs.pc_lang.pc_lang_id%type)
    return varchar2
  is
    txt varchar2(4000) := '';
  begin
    txt  :=
      txt ||
      pcs.pc_functions.translateword(case pdata.state
                                       when web_upd_data_fct.s_new then 'Nouvelle'
                                       when web_upd_data_fct.s_update then 'Modification'
                                       when web_upd_data_fct.s_delete_to_validate then 'Suppression'
                                       else ''
                                     end
                                   , ppc_lang_id
                                    ) ||
      ' ';

    case pdata.code
      when web_upd_data_fct.s_entity_schedule then
        select txt || hrm_functions.getdicodescr('DIC_SCH_PERIOD_1', wup_new_c, ppc_lang_id)
          into txt
          from web_update_data
         where wup_tabname = 'PAC_SCHEDULE_PERIOD'
           and wup_fieldname = 'DIC_SCH_PERIOD_1_ID'
           and wup_recid = pdata.recid;

        select txt || ' ' || to_char(wup_new_d)
          into txt
          from web_update_data
         where wup_tabname = 'PAC_SCHEDULE_PERIOD'
           and wup_fieldname = 'SCP_FROM_DATE'
           and wup_recid = pdata.recid;

        select txt || ' ' || to_char(wup_new_d)
          into txt
          from web_update_data
         where wup_tabname = 'PAC_SCHEDULE_PERIOD'
           and wup_fieldname = 'SCP_TO_DATE'
           and wup_recid = pdata.recid;
      when web_upd_data_fct.s_entity_PERSON_ADD then
        begin
          txt  := txt || pcs.pc_functions.translateword('Adresse', ppc_lang_id) || ' :';

          /**
          PER_HOMESTREET
          PER_HOMECITY
          PER_HOMESPOSTALCODE
          PER_HOMECOUNTRY
          PER_HOMESTATE */
          select txt || wup_new_c || ' '
            into txt
            from web_update_data
           where wup_tabname = 'HRM_PERSON'
             and wup_fieldname = 'PER_HOMESTREET'
             and wup_recid = pdata.recid;

          select txt || wup_new_c || ' '
            into txt
            from web_update_data
           where wup_tabname = 'HRM_PERSON'
             and wup_fieldname = 'PER_HOMEPOSTALCODE'
             and wup_recid = pdata.recid;

          select txt || wup_new_c || ' '
            into txt
            from web_update_data
           where wup_tabname = 'HRM_PERSON'
             and wup_fieldname = 'PER_HOMECITY'
             and wup_recid = pdata.recid;

          select txt || wup_new_c || ' '
            into txt
            from web_update_data
           where wup_tabname = 'HRM_PERSON'
             and wup_fieldname = 'PER_HOMESTATE'
             and wup_recid = pdata.recid;

          select txt || wup_new_c
            into txt
            from web_update_data
           where wup_tabname = 'HRM_PERSON'
             and wup_fieldname = 'PER_HOMECOUNTRY'
             and wup_recid = pdata.recid;
        end;
      when web_upd_data_fct.s_entity_PERSON_COM then
        begin
          /*
          PER_HOME_PHONE
          PER_MOBIL_PHONE
          PER_EMAIL
          */
          txt  := txt || pcs.pc_functions.translateword('Donn‚es de communication', ppc_lang_id) || ' :';

          select txt || pcs.pc_functions.translateword('Tel Domicile', ppc_lang_id) || ' : ' || wup_new_c
            into txt
            from web_update_data
           where wup_tabname = 'HRM_PERSON'
             and wup_fieldname = 'PER_HOME_PHONE'
             and wup_recid = pdata.recid;

          select txt || pcs.pc_functions.translateword('Mobile', ppc_lang_id) || ' : ' || wup_new_c
            into txt
            from web_update_data
           where wup_tabname = 'HRM_PERSON'
             and wup_fieldname = 'PER_MOBILE_PHONE'
             and wup_recid = pdata.recid;

          select txt || pcs.pc_functions.translateword('Email', ppc_lang_id) || ' : ' || wup_new_c
            into txt
            from web_update_data
           where wup_tabname = 'HRM_PERSON'
             and wup_fieldname = 'PER_EMAIL'
             and wup_recid = pdata.recid;
        end;
      else
        txt  := txt || '';
    end case;

    return txt;
  end get_text_gudl;

  /**
  *
  */
  function get_text_bulle_gudl(pdata t_entity_data_gudl, ppc_lang_id pcs.pc_lang.pc_lang_id%type)
    return varchar2
  is
    txt varchar2(4000) := '';
  begin
    txt  := '<b>' || get_text_gudl(pdata, ppc_lang_id) || '</b>';
    return txt;
  end get_text_bulle_gudl;

  /**
  *
  */
  function get_entity_name_gudl(
    pwud_id      web_update_data.web_update_data_id%type
  , pentity_code t_entity_code
  , ppc_lang_id  pcs.pc_lang.pc_lang_id%type
  )
    return varchar2
  is
    ret    varchar2(4000);
    mainid number(12);
  begin
    case pentity_code
      when web_upd_data_fct.s_entity_schedule then
        select wud_parent_id
          into mainid
          from web_update_data wup
         where web_update_data_id = pwud_id;

        if (mainid is null) then
          select psp.hrm_person_id
            into mainid
            from web_update_data wup
               , pac_schedule_period psp
           where pac_schedule_period_id = wup_recid
             and web_update_data_id = pwud_id;
        end if;

        select pcs.pc_functions.translateword('Agenda', ppc_lang_id) || ' ' || per_fullname
          into ret
          from hrm_person p
         where hrm_person_id = mainid;

      when web_upd_data_fct.s_entity_person_per then
        select pcs.pc_functions.translateword('Personne', ppc_lang_id) || ' ' || per_fullname || ' '
          into ret
          from hrm_person p
             , web_update_data wup
         where hrm_person_id = wup_recid
           and web_update_data_id = pwud_id;

      when web_upd_data_fct.s_entity_person_com then
        select pcs.pc_functions.translateword('Communication', ppc_lang_id) || ' ' || per_fullname || ' '
          into ret
          from hrm_person p
             , web_update_data wup
         where hrm_person_id = wup_recid
           and web_update_data_id = pwud_id;

      when web_upd_data_fct.s_entity_person_add then
        select pcs.pc_functions.translateword('Adresse', ppc_lang_id) || ' ' || per_fullname || ' '
          into ret
          from hrm_person p
             , web_update_data wup
         where hrm_person_id = wup_recid
           and web_update_data_id = pwud_id;

      when web_upd_data_fct.s_entity_person_fin then
        ret := 'R‚f‚rence financiŠre';

      when web_upd_data_fct.s_entity_person_dep then
        ret := 'D‚pendant';

      when web_upd_data_fct.s_entity_join_training then
        select wud_parent_id
          into mainid
          from web_update_data wup
         where web_update_data_id = pwud_id;

        select pcs.pc_functions.translateword('Formation', ppc_lang_id) || ' ' || per_fullname
          into ret
          from hrm_person p
         where hrm_person_id = mainid;
      else
        ret := null;
    end case;

    return ret;
  end get_entity_name_gudl;

/*
declare
  a varchar2(2000);
  n number(1);
  begin
  --n:= WEB_UPD_DATA_FCT.PAC_SCHEDULE_PERIOD_DELETE(60033453784,'RRI',a);
  --n:= WEB_UPD_DATA_FCT.PAC_SCHEDULE_PERIOD_DELETE(60044209771,'RRI',a);
  n:= WEB_UPD_DATA_FCT.PAC_SCHEDULE_PERIOD_DELETE(60044192295,'RRI',a);

end; */
  function pac_schedule_period_delete(
    ppac_schedule_period_id            pac_schedule_period.pac_schedule_period_id%type
  , pecu_initial                       econcept.eco_users.ecu_initial%type
  , perrormsg               out nocopy varchar2
  )
    return integer
  is
    istempdata           number(1);
    phrm_person_id       pac_schedule_period.hrm_person_id%type;
    pdic_sch_period_1_id pac_schedule_period.dic_sch_period_1_id%type;
    pscp_comment         pac_schedule_period.scp_comment%type;
    pscp_date            pac_schedule_period.scp_date%type;
    pscp_open_time       pac_schedule_period.scp_open_time%type;
    pscp_close_time      pac_schedule_period.scp_close_time%type;
  begin
    select decode(count(*), 0, 0, 1)
      into istempdata
      from web_update_data
     where wup_recid = ppac_schedule_period_id
       and wup_tabname = 'PAC_SCHEDULE_PERIOD';

    if (istempdata = 1) then
      delete      web_update_data
            where wup_recid = ppac_schedule_period_id
              and wup_tabname = 'PAC_SCHEDULE_PERIOD';
    else
      --insert into web_update_data avec status … 4
      select hrm_person_id
           , dic_sch_period_1_id
           , scp_comment
           , scp_date
           , scp_open_time
           , scp_close_time
        into phrm_person_id
           , pdic_sch_period_1_id
           , pscp_comment
           , pscp_date
           , pscp_open_time
           , pscp_close_time
        from pac_schedule_period
       where pac_schedule_period_id = ppac_schedule_period_id;

      return pac_schedule_period_save(phrm_person_id
                                    ,   --HRM_PERSON_ID
                                      ppac_schedule_period_id
                                    ,   --PAC_SCHEDULE_PERIOD_ID
                                      pdic_sch_period_1_id
                                    ,
                                      --DIC_SCH_PERIOD_1_ID  nouvelle valeur
                                      pscp_comment
                                    ,   --SCP_COMMENT       nouvelle valeur
                                      pscp_date
                                    ,   --SCP_FROM_DATE nouvelle valeur
                                      null
                                    ,   --SCP_TO_DATE nouvelle valeur
                                      pscp_open_time
                                    ,   --SCP_OPEN_TIME nouvelle valeur
                                      pscp_close_time
                                    ,   --SCP_CLOSE_TIME nouvelle valeur
                                      null
                                    ,   --DIC_SCH_PERIOD_1_ID  ancienne valeur
                                      null
                                    ,   --SCP_COMMENT ancienne valeur
                                      null
                                    ,   --SCP_FROM_DATE ancienne valeur
                                      null
                                    ,   --SCP_TO_DATE ancienne valeur
                                      null
                                    ,   --SCP_OPEN_TIME ancienne valeur
                                      null
                                    ,   --SCP_CLOSE_TIME ancienne valeur
                                      s_delete_to_validate
                                    ,
                                      -- … supprimer aprŠs validation
                                      pecu_initial
                                    ,   --Initials de l'utilisateur en cours
                                      perrormsg   --message de retour
                                     );
    end if;

    return web_functions.return_ok;
  end;

  function get_web_upd_data_pac_sch(phrm_person_id hrm_person.hrm_person_id%type, pfirst_date date, plast_date date)
    return web_upd_data_pac_sch_table pipelined
  is
    out_rec     web_upd_data_pac_sch;
    vfromdate   date;
    vtodate     date;
    vdays       number(12);
    ventryid    pac_schedule_period.scp_entry_id%type;
    ascheduleid pac_schedule.pac_schedule_id%type;
  begin
    if phrm_person_id is null then
      begin
        pipe row(out_rec);
        return;
      end;
    else
      ascheduleid := web_hrm_portal_fct.get_schedule_id(phrm_person_id);

      -- Recherche des entit‚s … pr‚senter
      for tplentity in (select qryrslt.wup_recid
                             , qryrslt.wup_date_create
                             , qryrslt.wup_initials_create
                             , web_upd_data_fct.s_new wup_status
                          from (select   wud.wup_recid
                                       , wud.wup_date_create
                                       , wud.wup_initials_create
                                       , min(wup_new_d) fromdate
                                       , max(wup_new_d) todate
                                    from web_update_data wud
                                   where wud.wup_tabname = 'PAC_SCHEDULE_PERIOD'
                                     and wud.wud_parent_tab = 'HRM_PERSON'
                                     and wud.c_web_update_state = web_upd_data_fct.s_new
                                     and wud.wud_parent_id = phrm_person_id
                                     and wud.wup_fieldname in('SCP_FROM_DATE', 'SCP_TO_DATE')
                                group by wud.wup_recid
                                       , wup_date_create
                                       , wup_initials_create) qryrslt
                         where pfirst_date between qryrslt.fromdate and qryrslt.todate
                            or plast_date between qryrslt.fromdate and qryrslt.todate
                            or qryrslt.fromdate between pfirst_date and plast_date
                            or qryrslt.todate between pfirst_date and plast_date
                        union
                        select qryrslt1.wup_recid
                             , qryrslt1.wup_date_create
                             , qryrslt1.wup_initials_create
                             , web_upd_data_fct.s_update wup_status
                          from (select   wud.wup_recid
                                       , wud.wup_date_create
                                       , wud.wup_initials_create
                                       , min(wup_new_d) fromdate
                                       , max(wup_new_d) todate
                                    from web_update_data wud
                                       , pac_schedule_period sp
                                   where sp.pac_schedule_period_id = wud.wup_recid
                                     and wup_tabname = 'PAC_SCHEDULE_PERIOD'
                                     and sp.hrm_person_id = phrm_person_id
                                     and c_web_update_state = web_upd_data_fct.s_update
                                     and wud.wup_fieldname in('SCP_FROM_DATE', 'SCP_TO_DATE')
                                group by wud.wup_recid
                                       , wud.wup_date_create
                                       , wud.wup_initials_create) qryrslt1
                         where pfirst_date between qryrslt1.fromdate and qryrslt1.todate
                            or plast_date between qryrslt1.fromdate and qryrslt1.todate
                            or qryrslt1.fromdate between pfirst_date and plast_date
                            or qryrslt1.todate between pfirst_date and plast_date) loop
        out_rec.a_datemod               := tplentity.wup_date_create;
        out_rec.a_idmod                 := tplentity.wup_initials_create;
        out_rec.pac_schedule_period_id  := tplentity.wup_recid;
        out_rec.pac_schedule_id         := ascheduleid;
        out_rec.hrm_person_id           := phrm_person_id;
        out_rec.scp_nonworking_day      := null;
        out_rec.dic_sch_period_2_id     := null;
        out_rec.wup_status              := tplentity.wup_status;

        /*  Pour chaque entit‚, examine le d‚tail */
        for tpldetail in (select wup_fieldname
                               , wup_new_n
                               , wup_new_c
                               , wup_new_d
                            from web_update_data
                           where wup_recid = tplentity.wup_recid) loop
          case tpldetail.wup_fieldname
            when 'DIC_SCH_PERIOD_1_ID' then
              out_rec.dic_sch_period_1_id  := tpldetail.wup_new_c;
            when 'SCP_COMMENT' then
              out_rec.scp_comment  := tpldetail.wup_new_c;
            when 'SCP_FROM_DATE' then
              vfromdate  := greatest(tpldetail.wup_new_d, pfirst_date);
            when 'SCP_TO_DATE' then
              vtodate  := least(tpldetail.wup_new_d, plast_date);
            when 'SCP_OPEN_TIME' then
              out_rec.open_time  := tpldetail.wup_new_n;
            when 'SCP_CLOSE_TIME' then
              out_rec.close_time  := tpldetail.wup_new_n;
            else
              /* Nom de champ pas connu que faire? */
              null;
          end case;
        end loop;   --fin du row

        /* G‚nŠre une entr‚e pour chaque jour dans l'interval  de pFirst_date … pLast_date */
        vdays                           := vtodate - vfromdate;
        if (vdays > 1) then
          select init_id_seq.nextval into out_rec.scp_entry_id from dual;
        else
          out_rec.scp_entry_id := null;
        end if;

        for i in 0 .. vdays loop
          out_rec.scp_date     := vfromdate + i;
          out_rec.week_number  := to_char(out_rec.scp_date, 'IW', 'NLS_DATE_LANGUAGE = American');
          out_rec.day_of_week  := null /* to_char(wup_new_d,'DY','NLS_DATE_LANGUAGE = American') day_of_week */;
          pipe row(out_rec);
        end loop;
      end loop;   -- tplEntity
    end if;
  end get_web_upd_data_pac_sch;

  /**
  *
  */
  function web_upd_valid(
    pid                      web_update_data.wup_recid%type
  , pcompany                 varchar2
  , pentity_code             t_entity_code
  , pcomment                 varchar2
  , pvalidator_id            econcept.eco_users.ECO_USERS_ID%type
  , perrormsg     out nocopy varchar2
  )
    return integer
  is
  begin
    update web_update_data
       set c_web_update_state =
             case c_web_update_state
               when web_upd_data_fct.s_new then web_upd_data_fct.s_validated
               when web_upd_data_fct.s_update then web_upd_data_fct.s_validated
               when web_upd_data_fct.s_delete_to_validate then web_upd_data_fct.s_to_delete
             end
     where wup_tabname in(select tab
                            from table(web_upd_data_fct.retrieve_table_entities)
                           where entity = pentity_code)
       and wup_fieldname in(select fld
                              from table(web_upd_data_fct.retrieve_table_entities)
                             where entity = pentity_code)
       and wup_recid = pid
       and c_web_update_state in
                              (web_upd_data_fct.s_new, web_upd_data_fct.s_update, web_upd_data_fct.s_delete_to_validate);

    return web_upd_process(pid, pentity_code, perrormsg);
  end web_upd_valid;

  /**
  *
  */
  function web_refuse_process(
    pid                     web_update_data.wup_recid%type
  , pentity_code            t_entity_code
  , perrormsg    out nocopy varchar2
  )
    return integer
  is
    result integer := web_functions.return_ok;
  begin
    perrormsg  := '';

    begin
      delete from web_update_data
            where web_update_data_id in(
                    select wud.web_update_data_id
                      from (select tab
                                 , fld
                              from table(web_upd_data_fct.RETRIEVE_TABLE_ENTITIES)
                             where entity = pentity_code) entities
                         , web_update_data wud
                     where entities.tab = wud.wup_tabname
                       and entities.fld = wud.wup_fieldname
                       and wud.wup_recid = pid
                       and wud.c_web_update_state in(web_upd_data_fct.s_new, web_upd_data_fct.s_update) );
    exception
      when others then
        result     := web_functions.return_error;
        perrormsg  := 'Cannot delete entity ' || pentity_code || ': ' || sqlcode || ' ' || sqlerrm;
    end;

    return result;
  end web_refuse_process;

  /**
  *
  */
  function web_upd_refuse(
    pid                      web_update_data.wup_recid%type
  , pcompany                 varchar2
  , pentity_code             t_entity_code
  , pcomment                 varchar2
  , pvalidator_id            econcept.eco_users.ECO_USERS_ID%type
  , perrormsg     out nocopy varchar2
  )
    return integer
  is
    result                integer                               := web_functions.return_ok;
    sresult               varchar2(4000);
    ismailsenderavailable boolean                               := is_mail_sender_available;
    person_table          web_update_data.wud_parent_tab%type;
    person_id             web_update_data.wud_parent_id%type;
    requester_data        tperson_data;
    validator_data        tperson_data;
    mail                  eml_sender.tmail;
    refuse_error_occured  exception;
  begin
    begin
      select distinct nvl(wud.wud_parent_tab, wud.wup_tabname) table_name
                    , nvl(wud.wud_parent_id, wud.wup_recid) id
                 into person_table
                    , person_id
                 from (select tab
                            , fld
                         from table(web_upd_data_fct.RETRIEVE_TABLE_ENTITIES)
                        where entity = pentity_code) entities
                    , web_update_data wud
                where entities.tab = wud.wup_tabname
                  and entities.fld = wud.wup_fieldname
                  and wud.wup_recid = pid;
    exception
      when no_data_found then
        perrormsg  := 'ENTITY-CODE NOT KNOWN: ' || pentity_code;
        result     := web_functions.return_fatal;
        raise refuse_error_occured;
    end;

    /*  Donn‚es de la personne */
    result  := retrieve_person_data(person_table, person_id, requester_data, perrormsg);

    if (result <> web_functions.return_ok) then
      raise refuse_error_occured;
    end if;

    /* Donn‚es personnelles du validateur */
    result  := retrieve_eco_user_data(pvalidator_id, pcompany, validator_data, perrormsg);

    if (result <> web_functions.return_ok) then
      raise refuse_error_occured;
    end if;

    /*  Traite le refus */
    result  := web_refuse_process(pid, pentity_code, perrormsg);

    if (result in(web_functions.return_error, web_functions.return_fatal) ) then
      raise refuse_error_occured;
    end if;

    /* Envoie un courriel pour notifier le refus … l'utilisateur */
    if (result = web_functions.return_ok) then
      if (not is_mail_sender_available) then
        result     := web_functions.return_warning;
        perrormsg  := '';
        raise refuse_error_occured;
      end if;

      if (requester_data.email_address is null) then
        result     := web_functions.return_warning;
        perrormsg  := '';
        raise refuse_error_occured;
      end if;

      if (validator_data.email_address is null) then
        validator_data.email_address  := cemail_default;
      end if;

      initialize_mail(pentity_code, 'REFUSE', pcomment, validator_data, requester_data, mail);
      sresult  := send_email(mail, perrormsg);

      if (sresult is not null) then
        result  := web_functions.return_warning;
        raise refuse_error_occured;
      end if;
    end if;

    return result;
  exception
    when refuse_error_occured then
      return result;
    when others then
      result     := web_functions.return_error;
      perrormsg  := 'Unexpected Error ' || pentity_code || ': ' || sqlcode || ' ' || sqlerrm;
      return result;
  end web_upd_refuse;

  /**
   *  Retourne 0 si les deux string sont ‚gaux ou si les deux strings sont vides.
   *
   */
  function equal_string(ps_s1 in varchar2,
                        ps_s2 in varchar2) return integer
  is
    vb_is_equal boolean := false;
  begin
    if (ps_s1 is null or ps_s2 is null) then
       vb_is_equal := (ps_s1 is null and ps_s2 is null);
    else
       vb_is_equal := (ps_s1 = ps_s2);
    end if;
    if (vb_is_equal) then
      return 0;
    else
      return 1;
     end if;
  end equal_string;

  procedure has_fields_modified(
    pnewValue                  varchar2
  , poldValue                  varchar2
  , ptab_name                  web_update_data.WUP_TABNAME%type
  , pfld_name                  web_update_data.WUP_FIELDNAME%type
  , pentity_list in out nocopy t_entity_list
  )
  as
    entity t_entity_code;
  begin
    if (equal_string(pnewValue, poldValue) != 0) then
      begin
        select e.entity
          into entity
          from table(web_upd_data_fct.retrieve_table_entities) e
         where e.tab = ptab_name
           and e.fld = pfld_name;

        if (not pentity_list.exists(entity) ) then
          pentity_list(entity)  := entity;
        end if;
      exception
        when no_data_found then
          null;
      end;
    end if;
  end has_fields_modified;

  /**
  *
  */
  function hrm_person_save_process(
    phrm_person_id          web_update_data.wup_recid%type
  ,
    /*                     new VALUES                                     */
    pper_homestreet         web_update_data.wup_new_c%type
  , pper_homepostalcode     web_update_data.wup_new_c%type
  , pper_homestate          web_update_data.wup_new_c%type
  , pper_homecity           web_update_data.wup_new_c%type
  , pper_home_country       web_update_data.wup_new_c%type
  , pper_home_phone         web_update_data.wup_new_c%type
  , pper_mobile_phone       web_update_data.wup_new_c%type
  , pper_email              web_update_data.wup_new_c%type
  ,
    /*                     old VALUES                                     */
    pper_homestreet_old     web_update_data.wup_old_c%type
  , pper_homepostalcode_old web_update_data.wup_old_c%type
  , pper_homestate_old      web_update_data.wup_old_c%type
  , pper_homecity_old       web_update_data.wup_old_c%type
  , pper_home_country_old   web_update_data.wup_old_c%type
  , pper_home_phone_old     web_update_data.wup_old_c%type
  , pper_mobile_phone_old   web_update_data.wup_old_c%type
  , pper_email_old          web_update_data.wup_old_c%type
  , pecu_initial            econcept.eco_users.ecu_initial%type
  )
    return t_web_update_data pipelined
  is
    person      web_upd_data_fct.t_web_update_data_list := t_web_update_data_list();
    entity_list t_entity_list;
    now         date                                    := sysdate;
  begin
    has_fields_modified(pper_homestreet, pper_homestreet_old, 'HRM_PERSON', 'PER_HOMESTREET', entity_list);
    has_fields_modified(pper_homepostalcode, pper_homepostalcode_old, 'HRM_PERSON', 'PER_HOMEPOSTALCODE', entity_list);
    has_fields_modified(pper_homestate, pper_homestate_old, 'HRM_PERSON', 'PER_HOMESTATE', entity_list);
    has_fields_modified(pper_homecity, pper_homecity_old, 'HRM_PERSON', 'PER_HOMECITY', entity_list);
    has_fields_modified(pper_home_country, pper_home_country_old, 'HRM_PERSON', 'PER_HOMECOUNTRY', entity_list);
    has_fields_modified(pper_home_phone, pper_home_phone_old, 'HRM_PERSON', 'PER_HOME_PHONE', entity_list);
    has_fields_modified(pper_mobile_phone, pper_mobile_phone_old, 'HRM_PERSON', 'PER_MOBILE_PHONE', entity_list);
    has_fields_modified(pper_email, pper_email_old, 'HRM_PERSON', 'PER_EMAIL', entity_list);

    --person.extend(count_fields);

    /*  Peuple la collection avec les donnees de la personne */
    if (entity_list.exists(web_upd_data_fct.s_entity_person_add) ) then
      person.extend;
      person(person.count).wup_fieldname  := 'PER_HOMESTREET';
      person(person.count).wup_old_c      := pper_homestreet_old;
      person(person.count).wup_new_c      := pper_homestreet;
      person.extend;
      person(person.count).wup_fieldname  := 'PER_HOMEPOSTALCODE';
      person(person.count).wup_old_c      := pper_homepostalcode_old;
      person(person.count).wup_new_c      := pper_homepostalcode;
      person.extend;
      person(person.count).wup_fieldname  := 'PER_HOMESTATE';
      person(person.count).wup_old_c      := pper_homestate_old;
      person(person.count).wup_new_c      := pper_homestate;
      person.extend;
      person(person.count).wup_fieldname  := 'PER_HOMECITY';
      person(person.count).wup_old_c      := pper_homecity_old;
      person(person.count).wup_new_c      := pper_homecity;
      person.extend;
      person(person.count).wup_fieldname  := 'PER_HOMECOUNTRY';
      person(person.count).wup_old_c      := pper_home_country_old;
      person(person.count).wup_new_c      := pper_home_country;
    end if;

    if (entity_list.exists(web_upd_data_fct.s_entity_person_com) ) then
      person.extend;
      person(person.count).wup_fieldname  := 'PER_HOME_PHONE';
      person(person.count).wup_old_c      := pper_home_phone_old;
      person(person.count).wup_new_c      := pper_home_phone;
      person.extend;
      person(person.count).wup_fieldname  := 'PER_MOBILE_PHONE';
      person(person.count).wup_old_c      := pper_mobile_phone_old;
      person(person.count).wup_new_c      := pper_mobile_phone;
      person.extend;
      person(person.count).wup_fieldname  := 'PER_EMAIL';
      person(person.count).wup_old_c      := pper_email_old;
      person(person.count).wup_new_c      := pper_email;
    end if;

    /*  Peuple la table avec les invariants */
    if (person.count > 0) then
      for i in person.first .. person.last loop
        select init_id_seq.nextval
          into person(i).web_update_data_id
          from dual;   /* Pas r‚ellement un invariant */

        person(i).wup_tabname          := 'HRM_PERSON';
        person(i).wup_recid            := phrm_person_id;
        person(i).c_web_update_state   := web_upd_data_fct.s_update;
        person(i).wup_initials_create  := pecu_initial;
        person(i).wup_date_create      := now;
        pipe row(person(i) );
      end loop;
    end if;
  end hrm_person_save_process;

/**
 *declare
  a number(1);
  pErrorMsg varchar2(2000);
begin
a:=web_upd_data_fct.HRM_PERSON_SAVE(1141378,
                               'le v‚l‚',
                               '2605',
                               'BE',
                               'Sonceboz',
                               'Suisse',
                               '032 488 4848',
                               '079 488 4848',
                               'toto@sage.com',
                               'le vele',
                               '2222',
                               'BE',
                               'Sonceboz',
                               'Suisse',
                               '032 488 4848',
                               '079 488 4848',
                               'toto@sage.com',
                               'RRI',
                               pErrorMsg);
dbms_output.put_line(a||' '||pErrorMsg);
end;
*/
  function hrm_person_save(
    phrm_person_id                     web_update_data.wup_recid%type
  ,
    /*                     new VALUES                                     */
    pper_homestreet                    web_update_data.wup_new_c%type
  , pper_homepostalcode                web_update_data.wup_new_c%type
  , pper_homestate                     web_update_data.wup_new_c%type
  , pper_homecity                      web_update_data.wup_new_c%type
  , pper_home_country                  web_update_data.wup_new_c%type
  , pper_home_phone                    web_update_data.wup_new_c%type
  , pper_mobile_phone                  web_update_data.wup_new_c%type
  , pper_email                         web_update_data.wup_new_c%type
  ,
    /*                     old VALUES                                     */
    pper_homestreet_old                web_update_data.wup_old_c%type
  , pper_homepostalcode_old            web_update_data.wup_old_c%type
  , pper_homestate_old                 web_update_data.wup_old_c%type
  , pper_homecity_old                  web_update_data.wup_old_c%type
  , pper_home_country_old              web_update_data.wup_old_c%type
  , pper_home_phone_old                web_update_data.wup_old_c%type
  , pper_mobile_phone_old              web_update_data.wup_old_c%type
  , pper_email_old                     web_update_data.wup_old_c%type
  , pecu_initial                       econcept.eco_users.ecu_initial%type
  , perrormsg               out nocopy varchar2
  )
    return integer
  is
  begin
    /*  Sauve ces donn‚es */
    merge into web_update_data wud
      using (select *
               from table(web_upd_data_fct.hrm_person_save_process(phrm_person_id
                                                                 ,
                                                                   /*                     new VALUES                                     */
                                                                   pper_homestreet
                                                                 , pper_homepostalcode
                                                                 , pper_homestate
                                                                 , pper_homecity
                                                                 , pper_home_country
                                                                 , pper_home_phone
                                                                 , pper_mobile_phone
                                                                 , pper_email
                                                                 ,
                                                                   /*                     old VALUES                                     */
                                                                   pper_homestreet_old
                                                                 , pper_homepostalcode_old
                                                                 , pper_homestate_old
                                                                 , pper_homecity_old
                                                                 , pper_home_country_old
                                                                 , pper_home_phone_old
                                                                 , pper_mobile_phone_old
                                                                 , pper_email_old
                                                                 , pecu_initial
                                                                  )
                         ) ) p
      on (    wud.wup_tabname = 'HRM_PERSON'
          and wud.wup_recid = phrm_person_id
          and wud.wup_fieldname = p.wup_fieldname)
      when matched then
        update
           set wud.WUP_new_N = p.WUP_new_N,
               wud.wup_new_c = p.wup_new_c,
               wud.WUP_new_D = p.WUP_new_D
      when not matched then
        insert(web_update_data_id, wup_tabname, wup_recid, wup_fieldname,
               c_web_update_state,
               wup_old_n, wup_old_c, wup_old_d,
               wup_new_n, wup_new_c, wup_new_d,
               wud_parent_tab, wud_parent_id,
               wup_initials_create,
               wup_date_create,
               wup_initials_valid,
               wup_date_valid,
               wup_date_proces)
        values(p.web_update_data_id, p.wup_tabname, p.wup_recid, p.wup_fieldname,
               p.c_web_update_state,
               p.wup_old_n, p.wup_old_c, p.wup_old_d,
               p.wup_new_n, p.wup_new_c, p.wup_new_d,
               p.wud_parent_tab, p.wud_parent_id,
               p.wup_initials_create,
               p.wup_date_create,
               p.wup_initials_valid,
               p.wup_date_valid,
               p.wup_date_proces
               );
    return web_functions.return_ok;
  end hrm_person_save;

  /**
  * function hrm_job_apply_save
  * Descritption
  *   voir sp‚cification
  */
  function hrm_job_apply_save(
    phrm_person_id                     web_update_data.wup_recid%type
  , phrm_job_id                        web_update_data.wup_new_n%type
  , ppos_date                          web_update_data.wup_new_d%type
  , pecu_initial                       econcept.eco_users.ecu_initial%type
  , perrormsg               out nocopy varchar2
  )
    return integer
  is
    newhrm_postulation_id  web_update_data.wup_recid%type;
    newstate               web_update_data.c_web_update_state%type := web_upd_data_fct.s_new;
    postulation            web_upd_data_fct.t_web_update_data_list := t_web_update_data_list();
    now                    date := sysdate;
  begin
    select init_id_seq.nextval into newhrm_postulation_id from dual;
    /** HRM_JOB_ID **/
    postulation.extend;
    postulation(postulation.count).wup_fieldname := 'HRM_JOB_ID';
    postulation(postulation.count).wup_new_n := phrm_job_id;
    /** POS_DATE **/
    postulation.extend;
    postulation(postulation.count).wup_fieldname := 'POS_DATE';
    postulation(postulation.count).wup_new_d := ppos_date;

    /*  Peuple la table avec les invariants */
    for i in postulation.first..postulation.last loop
      select init_id_seq.nextval into postulation(i).web_update_data_id
        from dual;   /* Pas r‚ellement un invariant */
      postulation(i).wup_tabname          := 'HRM_POSTULATION';
      postulation(i).wup_recid            := newhrm_postulation_id;
      postulation(i).c_web_update_state   := web_upd_data_fct.s_new;
      postulation(i).wud_parent_tab       := 'HRM_PERSON';
      postulation(i).wud_parent_id        := phrm_person_id;
      postulation(i).wup_initials_create  := pecu_initial;
      postulation(i).wup_date_create      := now;
    end loop;

    forall i in postulation.first..postulation.last
      insert into web_update_data values postulation(i);

    perrormsg := '';
    return web_functions.return_ok;
  end hrm_job_apply_save;

  /**
  * function hrm_training_join_save
  * Descritption
  *   voir sp‚cification
  */
  function hrm_training_join_save(
    phrm_person_id                     web_update_data.wup_recid%type
  , phrm_training_id                   web_update_data.wup_new_n%type
  , phrm_subscription_id               web_update_data.wup_new_n%type
  , psub_plan_date                     web_update_data.wup_new_d%type
  , psub_comment                       web_update_data.wup_new_c%type
  , pc_training_priority               web_update_data.wup_new_c%type
  , pecu_initial                       econcept.eco_users.ecu_initial%type
  , perrormsg               out nocopy varchar2
  )
    return integer
  is
    newhrm_subscription_id  web_update_data.wup_recid%type;
    newstate                web_update_data.c_web_update_state%type := web_upd_data_fct.s_new;
    subscription            web_upd_data_fct.t_web_update_data_list := t_web_update_data_list();
    now                     date := sysdate;
  begin
    select init_id_seq.nextval into newhrm_subscription_id from dual;
    /** HRM_TRAINING_ID **/
    subscription.extend();
    subscription(subscription.count).wup_fieldname := 'HRM_TRAINING_ID';
    subscription(subscription.count).wup_new_n := phrm_training_id;
    /** SUB_PLAN_DATE **/
    subscription.extend();
    subscription(subscription.count).wup_fieldname := 'SUB_PLAN_DATE';
    subscription(subscription.count).wup_new_d := psub_plan_date;
    /** SUB_COMMENT **/
    subscription.extend();
    subscription(subscription.count).wup_fieldname := 'SUB_COMMENT';
    subscription(subscription.count).wup_new_c := psub_comment;
    /** C_TRAINING_PRIORITY **/
    subscription.extend();
    subscription(subscription.count).wup_fieldname := 'C_TRAINING_PRIORITY';
    subscription(subscription.count).wup_new_c := pc_training_priority;
    /** SUB_DATE **/
    subscription.extend();
    subscription(subscription.count).wup_fieldname := 'SUB_DATE';
    subscription(subscription.count).wup_new_d := now;
    /** C_SUBSCRIPTION_STATUS **/
    subscription.extend();
    subscription(subscription.count).wup_fieldname := 'C_SUBSCRIPTION_STATUS';
    subscription(subscription.count).wup_new_c := '2'; /* Pour Validation */
    /*  Peuple la table avec les invariants */
    for i in subscription.first..subscription.last loop
      select init_id_seq.nextval into subscription(i).web_update_data_id
        from dual;   /* Pas r‚ellement un invariant */
      subscription(i).wup_tabname          := 'HRM_SUBSCRIPTION';
      subscription(i).wup_recid            := newhrm_subscription_id;
      subscription(i).c_web_update_state   := web_upd_data_fct.s_new;
      subscription(i).wud_parent_tab       := 'HRM_PERSON';
      subscription(i).wud_parent_id        := phrm_person_id;
      subscription(i).wup_initials_create  := pecu_initial;
      subscription(i).wup_date_create      := now;
    end loop;

    forall i in subscription.first..subscription.last
      insert into web_update_data values subscription(i);

    perrormsg := '';
    return web_functions.return_ok;
  end ;

  /**
   * function hrm_training_join_update
  * Descritption
  *   voir sp‚cification
  */
  function hrm_training_join_update(
    phrm_person_id                     web_update_data.wup_recid%type
  , phrm_training_id                   web_update_data.wup_new_n%type
  , psub_plan_date                     web_update_data.wup_new_d%type
  , psub_comment                       web_update_data.wup_new_c%type
  , pc_training_priority               web_update_data.wup_new_c%type
  , pecu_initial                       econcept.eco_users.ecu_initial%type
  , perrormsg               out nocopy varchar2
  )
    return integer
  is
  begin
    perrormsg := 'Unsupported Operation';
    return web_functions.return_fatal;
  end ;

  /**
  * function hrm_training_join_delete
  * Descritption
  *   voir sp‚cification
  */
  function hrm_training_join_delete(
    phrm_person_id                     web_update_data.wup_recid%type
  , phrm_training_id                   web_update_data.wup_new_n%type
  , ppos_date                          web_update_data.wup_new_d%type
  , pecu_initial                       econcept.eco_users.ecu_initial%type
  , perrormsg               out nocopy varchar2
  )
    return integer
  is
  begin
    perrormsg := 'Unsupported Operation';
    return web_functions.return_fatal;
  end ;

  /**
  *
  */
  function get_text_refusal_mail(
    pmime_type  varchar2
  , pcomment    varchar2
  , pentity     t_entity_code
  , pvalidator  tperson_data
  , pperson     tperson_data
  , ppc_lang_id pcs.pc_lang.pc_lang_id%type
  )
    return clob
  is
  begin
    return to_clob(pcomment);
  end get_text_refusal_mail;

  /**
  *
  */
  function get_text_approval_mail(
    pmime_type  varchar2
  , pcomment    varchar2
  , pentity     t_entity_code
  , pvalidator  tperson_data
  , pperson     tperson_data
  , ppc_lang_id pcs.pc_lang.pc_lang_id%type
  )
    return clob
  is
  begin
    return to_clob(pcomment);
  end get_text_approval_mail;

  /**
  *
  */
  function get_subject_mail(pentity_code varchar2, action varchar2, ppclangid pcs.v_pc_appltxt.pc_lang_id%type)
    return clob
  is
    result clob := empty_clob();
  begin
    return result;
  exception
    when no_data_found then
      return to_clob('#' || pentity_code || ':' || action);
    when others then
      raise;
  end get_subject_mail;

  /**
  *
  */
  function is_mail_sender_available
    return boolean
  is
  begin
    return(pcs.pc_option_functions.isoptionactive('MAIL_SENDER') <> 0);
  end is_mail_sender_available;

  /**
  *
  */
  procedure read_postulation_data(rec    in out nocopy tpostulation_data
                                , precid web_update_data.wup_recid%type)
  as
  begin
    for tpldata in (select wup_fieldname
                         , wup_new_n
                         , wup_new_c
                         , wup_new_d
                      from web_update_data
                     where wup_recid = precid) loop
      case tpldata.wup_fieldname
        when 'HRM_JOB_ID' then
          rec.hrm_job_id    := tpldata.wup_new_n;
        when 'POS_DATE' then
          rec.pos_date      := tpldata.wup_new_d;
        else
          /* Nom de champ pas connu que faire? */
          null;
      end case;
    end loop;
  end read_postulation_data;

  /**
  *
  */
  function retrieve_postulation_data(phrm_person_id hrm_person.hrm_person_id%type)
    return tpostutalions_table pipelined
  is
    post_rec tpostulation_data;
  begin
    for tplpostulation in (select distinct wud.wup_recid, wud.wud_parent_id
                             from web_update_data wud
                            where wud.wud_parent_id = phrm_person_id
                              and wud.WUP_TABNAME = 'HRM_POSTULATION') loop
      post_rec.recid         := tplpostulation.wup_recid;
      post_rec.hrm_person_id := tplpostulation.wud_parent_id;
      read_postulation_data(post_rec, tplpostulation.wup_recid);
      pipe row(post_rec);
    end loop;
  end retrieve_postulation_data;

  /**
  *
  */
  function retrieve_postulation_data
    return tpostutalions_table pipelined
  is
    post_rec tpostulation_data;
  begin
    for tplpostulation in (select distinct wud.wup_recid, wud.wud_parent_id
                             from web_update_data wud
                            where wud.WUP_TABNAME = 'HRM_POSTULATION') loop
      post_rec.recid         := tplpostulation.wup_recid;
      post_rec.hrm_person_id := tplpostulation.wud_parent_id;
      read_postulation_data(post_rec, tplpostulation.wup_recid);
      pipe row(post_rec);
    end loop;
  end retrieve_postulation_data;

  /**
  * Lit
  */
  procedure read_subscription_data(rec    in out nocopy tsubscription_data
                                 , precid web_update_data.wup_recid%type)
  as
  begin
    for tpldata in (select wup_fieldname
                         , wup_new_n
                         , wup_new_c
                         , wup_new_d
                    from web_update_data
                   where wup_recid = precid) loop
      case tpldata.wup_fieldname
        when 'HRM_TRAINING_ID' then
          rec.hrm_training_id     := tpldata.wup_new_n;
        when 'SUB_PLAN_DATE' then
          rec.sub_plan_date       := tpldata.wup_new_d;
        when 'SUB_COMMENT' then
          rec.sub_comment         := tpldata.wup_new_c;
        when 'C_TRAINING_PRIORITY' then
          rec.c_training_priority := tpldata.wup_new_c;
        when 'SUB_DATE' then
          rec.sub_date := tpldata.wup_new_d;
        when 'C_SUBSCRIPTION_STATUS' then
          rec.c_subscription_status := tpldata.wup_new_c;
        else
          /* Nom de champ pas connu que faire? */
          null;
      end case;
    end loop;
  end read_subscription_data;

  /**
  *
  */
  function retrieve_subscription_data(phrm_person_id hrm_person.hrm_person_id%type)
    return tsubscriptions_table pipelined
  is
    subscript_rec tsubscription_data;
  begin
    for tplsubscription in (select distinct wud.wup_recid, wud.wud_parent_id
                              from web_update_data wud
                             where wud.wud_parent_id = phrm_person_id
                               and wud.WUP_TABNAME = 'HRM_SUBSCRIPTION') loop
      subscript_rec.recid         := tplsubscription.wup_recid;
      subscript_rec.hrm_person_id := tplsubscription.wud_parent_id;
      read_subscription_data(subscript_rec, tplsubscription.wup_recid);
      pipe row(subscript_rec);
    end loop;
  end retrieve_subscription_data;

  /**
  *
  */
  function retrieve_subscription_data
    return tsubscriptions_table pipelined
  is
    subscript_rec tsubscription_data;
  begin
    for tplsubscription in (select distinct wud.wup_recid, wud.wud_parent_id
                              from web_update_data wud
                             where wud.WUP_TABNAME = 'HRM_SUBSCRIPTION') loop
      subscript_rec.recid         := tplsubscription.wup_recid;
      subscript_rec.hrm_person_id := tplsubscription.wud_parent_id;
      read_subscription_data(subscript_rec, tplsubscription.wup_recid);
      pipe row(subscript_rec);
    end loop;
  end retrieve_subscription_data;

  /**
   * Lire les données d'un record de WEB_UPDATE_DATA pour l'entité PAC_SCHEDULE_PERIOD
   */
  PROCEDURE read_schedule_data(
    prec_schedule in out nocopy t_schedule_rec
  , pn_recid      in web_update_data.wup_recid%type
  )
  AS
  BEGIN
    FOR tpl_data IN (SELECT wup_fieldname
                          , wup_new_n
                          , wup_new_c
                          , wup_new_d
                      FROM web_update_data
                     WHERE wup_recid = pn_recid) LOOP
      CASE tpl_data.wup_fieldname
        WHEN 'DIC_SCH_PERIOD_1_ID' THEN
          prec_schedule.dic_sch_period_1_id := tpl_data.wup_new_c;
        WHEN 'SCP_COMMENT' THEN
          prec_schedule.scp_comment := tpl_data.wup_new_c;
        WHEN 'SCP_FROM_DATE' THEN
          prec_schedule.scp_from_date := tpl_data.wup_new_d;
        WHEN 'SCP_TO_DATE' THEN
          prec_schedule.scp_to_date := tpl_data.wup_new_d;
        WHEN 'SCP_OPEN_TIME' THEN
          prec_schedule.scp_open_time := tpl_data.wup_new_n;
        WHEN 'SCP_CLOSE_TIME' THEN
          prec_schedule.scp_close_time := tpl_data.wup_new_n;
        ELSE
           /* Nom de champs pas connu */
           NULL;
      END CASE;
    END LOOP;
  END read_schedule_data;

  /**
   * Voir spécification
   */
  FUNCTION retrieve_schedule_data
  RETURN t_schedule_table pipelined
  IS
    vrec_schedule t_schedule_rec;
  BEGIN
    FOR tpl_schedule IN (select distinct wup_recid
                               , wud_parent_id
                               , c_web_update_state
                              from web_update_data
                             where wup_tabname = s_entity_schedule) LOOP
      vrec_schedule.recid := tpl_schedule.wup_recid;
      vrec_schedule.hrm_person_id := tpl_schedule.wud_parent_id;
      vrec_schedule.c_web_update_state := tpl_schedule.c_web_update_state;
      read_schedule_data(vrec_schedule, tpl_schedule.wup_recid);
      PIPE ROW (vrec_schedule);
    END LOOP;
  END retrieve_schedule_data;

  /**
    * Voir spécification
    *
    */
  FUNCTION initializeCalendarRequest (
    p_hrm_personid  IN       hrm_person.hrm_person_id%TYPE,
    pd_from_date    IN       DATE,
    pd_to_date      IN       DATE,
    ps_msg          OUT NOCOPY VARCHAR2
  ) RETURN NUMBER
  IS
  BEGIN
    RETURN WEB_HRM_PORTAL_FCT.initializeCalendarRequest(p_hrm_personid,
                                                        pd_from_date,
                                                        pd_to_date,
                                                        ps_msg);
  END initializeCalendarRequest;

  /**
    * Voir spécification
    *
    */
  FUNCTION initializeCalendarRequest (
    pn_hrm_personid  IN       hrm_person.hrm_person_id%TYPE
  , pd_day           IN       DATE
  , pn_modeview      IN       INTEGER
  , ps_msg           OUT NOCOPY VARCHAR2
  ) RETURN NUMBER
  IS
  BEGIN
    RETURN WEB_HRM_PORTAL_FCT.initializeCalendarRequest(pn_hrm_personid,
                                                        pd_day,
                                                        pn_modeview,
                                                        ps_msg);
  END initializeCalendarRequest;

  /**
    * Voir spécification
    *
    */
  FUNCTION initializeCalendarRequest (
    pn_hrm_personid  IN       hrm_person.hrm_person_id%TYPE
  , pn_day           IN       INTEGER
  , pn_month         IN       INTEGER
  , pn_year          IN       INTEGER
  , pn_modeview      IN       INTEGER
  , ps_msg           OUT NOCOPY VARCHAR2
  ) RETURN NUMBER
  IS
  BEGIN
    RETURN WEB_HRM_PORTAL_FCT.initializeCalendarRequest(pn_hrm_personid,
                                                        pn_day,
                                                        pn_month,
                                                        pn_year,
                                                        pn_modeview,
                                                        ps_msg);
  END initializeCalendarRequest;

  /**
    * Voir spécification
    */
  FUNCTION initializeCalendarRequest (
    ps_person_list_id IN       VARCHAR2
  , pd_day            IN       DATE
  , pn_modeview       IN       INTEGER
  , pn_with_holiday   IN       NUMBER
  , ps_msg            OUT NOCOPY VARCHAR2
  ) RETURN NUMBER
  IS
  BEGIN
    RETURN WEB_HRM_PORTAL_FCT.initializeCalendarRequest(ps_person_list_id,
                                                        pd_day,
                                                        pn_modeview,
                                                        pn_with_holiday,
                                                        ps_msg);
  END initializeCalendarRequest;

  /**
   * Initialise la table pac_schedule_interro pour une pédiode et pour
   * la liste de personnes spécifiée.
   */
  FUNCTION initializeCalendarRequest (
     ps_personListId IN         VARCHAR2
   , pd_from_date    IN         DATE
   , pd_to_date      IN         DATE
   , pn_with_holiday IN         NUMBER DEFAULT 0
   , ps_msg          OUT NOCOPY VARCHAR2
  ) RETURN NUMBER
  IS
  BEGIN
    RETURN WEB_HRM_PORTAL_FCT.initializeCalendarRequest(ps_personListId,
                                                        pd_from_date,
                                                        pd_to_date,
                                                        pn_with_holiday,
                                                        ps_msg);
  END initializeCalendarRequest;

  /**
   * Initialise la table pac_schedule_interro pour une pédiode et pour
   * une personne spécifiée.
   */
  FUNCTION initializeCalendarRequest (
     pn_personId     IN         hrm_person.hrm_person_id%TYPE
   , pd_from_date    IN         DATE
   , pd_to_date      IN         DATE
   , pn_with_holiday IN         NUMBER DEFAULT 0
   , ps_msg          OUT NOCOPY VARCHAR2
  ) RETURN NUMBER
  IS
  BEGIN
    RETURN WEB_HRM_PORTAL_FCT.initializeCalendarRequest(pn_personId,
                                                        pd_from_date,
                                                        pd_to_date,
                                                        pn_with_holiday,
                                                        ps_msg);
  END initializeCalendarRequest;


  /* ################### Decoder and Encoder Mail-Address ################### */
  /**
  *
  */
  function decodeAddress(pmailaddress varchar2) return taddress_mail_record
  is
    address taddress_mail_record;
    not_implemented_procedure exception;
  begin
    raise not_implemented_procedure;
  end ;

  /**
  *
  */
  function company_cntry_code return varchar2
  is
    result pcs.pc_cntry.cntid%type;
  begin
    select cntry.cntid  into result
      from pcs.pc_comp pcc, pcs.pc_cntry cntry
     where pcc.PC_COMP_ID = pcs.PC_I_LIB_SESSION.GETCOMPANYID
       and pcc.PC_CNTRY_ID = cntry.PC_CNTRY_ID;
    return result;
  exception
    when no_data_found then
      return '';
  end;

  /**
  *
  */
  function index_of_cntry_company return integer
  is
  begin
    return m_countries_code(upper(company_cntry_code));
  exception
    when no_data_found then
      return 0;
  end index_of_cntry_company;

  /**
  *
  */
  function has_name(pindex integer, pcountry varchar2) return boolean
  is
    names tstring_array;
    cntry varchar2(4000) := upper(pcountry);
    result boolean := false;
  begin
    names := m_countries_name(pindex);
    for i in 1..names.count loop
      if (cntry = upper(names(i))) then
        result := true;
        exit;
      end if;
    end loop;
    return result;
  end has_name;

  /**
  *
  */
  function encodeAddress(address taddress_mail_record) return varchar2
  is
  begin
    return encodeAddress(address.street
                       , address.zip
                       , address.city
                       , address.state
                       , address.country);
  end encodeAddress;

  function encodeAddress(
    street  varchar2
  , zip     varchar2
  , city    varchar2
  , state   varchar2
  , country varchar2
  )
  return varchar2
  is
    result varchar2(4000) := '';
    szip_city varchar2(4000);
    bshort_country constant boolean := zip is not null and (instr(zip, '-') <> 0);
    bspecify_country boolean := true;
    nindex integer;

  begin
    if (street is not null) then
      result := street;
    end if;

    szip_city := trim(zip ||' '|| city); -- Zip + City
    if (szip_city is not null) then
      if (result is not null) then
        result := result || cline_break || szip_city;
      else
        result := szip_city;
      end if;
    end if;

    if (not bshort_country) and (country is not null) then -- Country
      nindex := index_of_cntry_company;
      if (nindex > 0) then
        bspecify_country := not has_name(nindex, country);
      end if;
      if (bspecify_country) then
        if (result is not null) then
          result := result || cline_break || country;
        else
          result := country;
        end if;
      end if;
    end if;
    return result;
  end encodeAddress;

begin
  init_table_entities;
  init_countries;
end web_upd_data_fct;
