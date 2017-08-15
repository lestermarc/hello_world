--------------------------------------------------------
--  DDL for Package Body GAL_FAL_IMPORT_TIME_PROD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_FAL_IMPORT_TIME_PROD" 
is
  v_pointing_ok                varchar2(1);
  v_gal_hours_check_hrm_in_out varchar2(1);
  v_gal_hours_pointing_period  varchar2(30);
  v_deb_period_act             date;
  v_deb_period_nmoins1         date;
  v_max_date_saisie_ok         date;

  procedure insert_mvt_time(v_personne hrm_person.emp_number%type, v_operation varchar2, v_type varchar2, v_date_heure date, a_err_mess in out t_err_mess)
  is
    v_i             integer;
    v_hrm_person_id number(12);
  begin
    if trunc(v_date_heure, 'DD') > trunc(sysdate, 'DD') then
      v_i                                       := a_err_mess.count + 1;
      a_err_mess(v_i).mvt_type                  := v_type;
      a_err_mess(v_i).mvt_gal_fal_task_link_id  := v_operation;
      a_err_mess(v_i).mvt_emp_number            := v_personne;
      a_err_mess(v_i).mvt_date                  := v_date_heure;
      return;
    end if;

    begin
      select hrm_person_id
        into v_hrm_person_id
        from hrm_person
       where emp_number = v_personne;
    exception
      when no_data_found then
        v_i                                       := a_err_mess.count + 1;
        a_err_mess(v_i).mvt_type                  := v_type;
        a_err_mess(v_i).mvt_gal_fal_task_link_id  := v_operation;
        a_err_mess(v_i).mvt_emp_number            := v_personne;
        a_err_mess(v_i).mvt_date                  := v_date_heure;
        return;
    end;

    update gal_fal_mvt_temps
       set mvt_type = v_type
         , mvt_gal_fal_task_link_id = v_operation
         , mvt_flag = '1'
     where mvt_emp_number = v_personne
       and mvt_date = v_date_heure
       and mvt_type in('I', 'O');

    if sql%notfound then
      insert into gal_fal_mvt_temps
                  (gal_fal_mvt_temps_id
                 , mvt_emp_number
                 , mvt_date
                 , mvt_type
                 , mvt_gal_fal_task_link_id
                 , mvt_flag
                 , a_datecre
                 , a_idcre
                  )
           values (init_id_seq.nextval
                 , v_personne
                 , v_date_heure
                 , v_type
                 , v_operation
                 , '1'
                 , sysdate
                 , 'IMP'
                  );
    end if;
  end insert_mvt_time;

  procedure ecriture_itemproduction(
    v_personne   hrm_person.emp_number%type
  , v_operation  varchar2
  , v_type       char
  , v_date_heure date
  , v_duree      number
  , v_prov       varchar2
  )
  is
  begin
    -- No de bon non renseigné n'est pas une anomalie
    -- (cas des personnes qui badgent leur présence mais pas leur temps de production)
    if v_operation is not null then
      insert into gal_fal_hours_temp
           values (init_id_seq.nextval
                 , v_date_heure
                 , v_operation
                 , v_personne
                 , v_duree
                 , v_type
                 , v_prov
                  );
    end if;
  end ecriture_itemproduction;

  procedure update_mvt_time_to_treate
  is
    cursor selection_mouvement_a_traiter
    is
      select   mvt_emp_number
             , min(mvt_date)
          from gal_fal_mvt_temps
         where mvt_flag = '1'
      group by mvt_emp_number;

    v_personne   hrm_person.emp_number%type;
    v_date_heure date;
  begin
    open selection_mouvement_a_traiter;

    ----- Lecture du plus petit mouvement a traiter pour chaque personne
    loop
      exit when selection_mouvement_a_traiter%notfound;

      fetch selection_mouvement_a_traiter
       into v_personne
          , v_date_heure;

      if selection_mouvement_a_traiter%found then
        update gal_fal_mvt_temps
           set mvt_flag = '1'
         where mvt_emp_number = v_personne
           and mvt_flag = '2'
           and mvt_date >= to_date(to_char(v_date_heure, 'DD/MM/YYYY') || ' 00:00:00', 'DD/MM/YYYY HH24:MI:SS');
      end if;
    end loop;

    close selection_mouvement_a_traiter;
  end update_mvt_time_to_treate;

  procedure calc_prod_duration_with_mvt(v_prov varchar2)
  is
    v_personne             hrm_person.emp_number%type;
    v_date_heure           date;
    v_date_debut           date;
    v_date_fin             date;
    v_duree                number(14, 2);
    v_type_precedent       char(1);
    v_operation_precedente varchar2(12);
    v_type                 varchar2(1);
    v_operation            varchar2(12);
    v_id                   number(12);

    cursor selection_entree_non_traitee
    is
      select     gal_fal_mvt_temps_id
               , mvt_emp_number
               , mvt_date
            from gal_fal_mvt_temps
           where mvt_type = 'E'
             and mvt_flag = '1'
        order by mvt_emp_number
               , mvt_date
      for update;

    cursor selection_fin_suivante
    is
      select     gal_fal_mvt_temps_id
               , mvt_date
               , mvt_type
               , mvt_gal_fal_task_link_id
            from gal_fal_mvt_temps
           where mvt_emp_number = v_personne
             and to_char(mvt_date, 'DD/MM/YYYY') = to_char(v_date_heure, 'DD/MM/YYYY')
             and (    (    mvt_type in('S')
                       and mvt_date >= v_date_heure)
                  or (    mvt_type in('O', 'I')
                      and mvt_date >= v_date_heure) )
        order by mvt_emp_number
               , mvt_date
      for update;

    cursor selection_sortie_non_traitee
    is
      select     gal_fal_mvt_temps_id
               , mvt_emp_number
               , mvt_date
            from gal_fal_mvt_temps
           where mvt_type = 'S'
             and mvt_flag = '1'
        order by mvt_emp_number
               , mvt_date
      for update;

    cursor selection_debut_precedent
    is
      select     gal_fal_mvt_temps_id
               , mvt_date
               , mvt_type
               , mvt_gal_fal_task_link_id
            from gal_fal_mvt_temps
           where mvt_emp_number = v_personne
             and to_char(mvt_date, 'DD/MM/YYYY') = to_char(v_date_heure, 'DD/MM/YYYY')
             and (    (    mvt_type in('E')
                       and mvt_date <= v_date_heure)
                  or (    mvt_type in('O', 'I')
                      and mvt_date <= v_date_heure) )
        order by mvt_emp_number
               , mvt_date desc
      for update;

    -- Non prise en compte des badges BarMan dont la date est supérieure au dernier temps de présence
    -- (cas des présences importées après controle avec un décalage d'une journée)
    cursor selection_ope_non_traitee
    is
      select     gal_fal_mvt_temps_id
               , mvt_emp_number
               , mvt_date
            from gal_fal_mvt_temps
           where mvt_type in('O', 'I')
             and mvt_flag = '1'
             and mvt_date <= (select max(tps_date)
                                from gal_fal_tempresent)
        order by mvt_emp_number
               , mvt_date
      for update;
  begin
    ----- Lecture des mouvements d'entree non traites
    open selection_entree_non_traitee;

    loop
      exit when selection_entree_non_traitee%notfound;

      fetch selection_entree_non_traitee
       into v_id
          , v_personne
          , v_date_heure;

      if selection_entree_non_traitee%found then   ----- Lecture mouvement de fin suivant
        v_date_debut  := v_date_heure;
        v_date_fin    := null;

        begin
          select gal_fal_mvt_temps.gal_fal_mvt_temps_id
               , gal_fal_mvt_temps.mvt_type
               , gal_fal_mvt_temps.mvt_gal_fal_task_link_id
            into v_id
               , v_type_precedent
               , v_operation_precedente
            ----- Lecture derniere operation precedente
          from   gal_fal_mvt_temps
           where gal_fal_mvt_temps.mvt_emp_number = v_personne
             and gal_fal_mvt_temps.mvt_type in('O', 'I')
             and gal_fal_mvt_temps.mvt_date = (select max(a.mvt_date)
                                                 from gal_fal_mvt_temps a
                                                where a.mvt_emp_number = v_personne
                                                  and a.mvt_type in('O', 'I')
                                                  and a.mvt_date < v_date_heure)
             and rownum = 1;
        exception
          when no_data_found then
            v_type_precedent        := 'O';
            v_operation_precedente  := null;
        end;

        open selection_fin_suivante;

        loop
          fetch selection_fin_suivante
           into v_id
              , v_date_fin
              , v_type
              , v_operation;

          exit when selection_fin_suivante%notfound;

          if selection_fin_suivante%found then
            v_duree  :=( (v_date_fin - v_date_debut) * 24);
            ----- calcul duree entre heure Fin et heure Debut
            ecriture_itemproduction(v_personne, v_operation_precedente, v_type, v_date_heure, v_duree, v_prov);

            ----- Ecriture dans fichier d'input de HIMPHEU
            update gal_fal_mvt_temps
               set mvt_flag = '2'
             where current of selection_fin_suivante;

            if v_type in('O', 'I') then
              v_date_debut            := v_date_fin;
              v_date_fin              := null;
              v_type_precedent        := v_type;
              v_operation_precedente  := v_operation;
            else
              exit;
            end if;
          end if;
        end loop;

        close selection_fin_suivante;

        if v_date_fin is null then
          ----- si pas de mouvement de sortie suivant
          ----- calcul duree entre 24:00 et heure Debut
          v_duree  :=( ( (to_date(to_char(v_date_debut, 'DD/MM/YYYY') || ' 00:00:00', 'DD/MM/YYYY HH24:MI:SS') + 1) - v_date_debut) * 24);
          ecriture_itemproduction(v_personne, v_operation_precedente, v_type, v_date_heure, v_duree, v_prov);
        ----- Ecriture dans fichier d'input de HIMPHEU
        end if;

        update gal_fal_mvt_temps
           set mvt_flag = '2'
         where current of selection_entree_non_traitee;
      end if;
    end loop;

    close selection_entree_non_traitee;

    ----- Lecture des mouvements de sortie non traites
    open selection_sortie_non_traitee;

    loop
      exit when selection_sortie_non_traitee%notfound;

      fetch selection_sortie_non_traitee
       into v_id
          , v_personne
          , v_date_heure;

      if selection_sortie_non_traitee%found then
        ----- Lecture mouvement de debut precedent
        v_date_debut  := null;
        v_date_fin    := v_date_heure;

        open selection_debut_precedent;

        ----- Lecture derniere operation precedente
        loop
          fetch selection_debut_precedent
           into v_id
              , v_date_debut
              , v_type_precedent
              , v_operation_precedente;

          exit when selection_debut_precedent%notfound;

          if selection_debut_precedent%found then   ----- calcul duree entre heure Fin et heure Debut
            v_duree  :=( (v_date_fin - v_date_debut) * 24);
            ecriture_itemproduction(v_personne, v_operation_precedente, v_type, v_date_heure, v_duree, v_prov);

            ----- Ecriture dans fichier d'input de HIMPHEU
            update gal_fal_mvt_temps
               set mvt_flag = '2'
             where current of selection_debut_precedent;

            if v_type_precedent in('O', 'I') then
              v_date_fin    := v_date_debut;
              v_date_debut  := null;
            else
              exit;
            end if;
          end if;
        end loop;

        close selection_debut_precedent;

        if v_date_debut is null then
          begin
            select gal_fal_mvt_temps.gal_fal_mvt_temps_id
                 , gal_fal_mvt_temps.mvt_type
                 , gal_fal_mvt_temps.mvt_gal_fal_task_link_id
              into v_id
                 , v_type_precedent
                 , v_operation_precedente
              from gal_fal_mvt_temps
             where gal_fal_mvt_temps.mvt_emp_number = v_personne
               and gal_fal_mvt_temps.mvt_type in('O', 'I')
               and gal_fal_mvt_temps.mvt_date = (select max(a.mvt_date)
                                                   from gal_fal_mvt_temps a
                                                  where a.mvt_emp_number = v_personne
                                                    and a.mvt_type in('O', 'I')
                                                    and a.mvt_date < v_date_fin)
               and rownum = 1;
          exception
            when no_data_found then
              v_type_precedent        := 'O';
              v_operation_precedente  := null;
          end;

          ----- si pas de mouvement de debut precedent
          ----- calcul duree entre 24:00 et heure Fin
          v_duree  :=( (v_date_fin - to_date(to_char(v_date_fin, 'DD/MM/YYYY') || ' 00:00:00', 'DD/MM/YYYY HH24:MI:SS') ) * 24);
          ecriture_itemproduction(v_personne, v_operation_precedente, v_type, v_date_heure, v_duree, v_prov);
        ----- Ecriture dans fichier d'input de HIMPHEU
        end if;

        update gal_fal_mvt_temps
           set mvt_flag = '2'
         where current of selection_sortie_non_traitee;
      end if;
    end loop;

    close selection_sortie_non_traitee;

    ----- Lecture des mouvements d'operation non traites
    open selection_ope_non_traitee;

    loop
      exit when selection_ope_non_traitee%notfound;

      fetch selection_ope_non_traitee
       into v_id
          , v_personne
          , v_date_heure;

      if selection_ope_non_traitee%found then
        ----- Lecture derniere operation precedente
        begin
          select gal_fal_mvt_temps.gal_fal_mvt_temps_id
               , gal_fal_mvt_temps.mvt_type
               , gal_fal_mvt_temps.mvt_gal_fal_task_link_id
            into v_id
               , v_type_precedent
               , v_operation_precedente
            from gal_fal_mvt_temps
           where gal_fal_mvt_temps.mvt_emp_number = v_personne
             and gal_fal_mvt_temps.mvt_type in('O', 'I')
             and gal_fal_mvt_temps.mvt_date = (select max(a.mvt_date)
                                                 from gal_fal_mvt_temps a
                                                where a.mvt_emp_number = v_personne
                                                  and a.mvt_type in('O', 'I')
                                                  and a.mvt_date < v_date_heure)
             and rownum = 1;
        exception
          when no_data_found then
            v_type_precedent        := 'O';
            v_operation_precedente  := null;
        end;

        ----- operation sans presence
        ----- duree 0
        v_duree  := -1;
        ecriture_itemproduction(v_personne, v_operation_precedente, v_type, v_date_heure, v_duree, v_prov);

        ----- Ecriture dans fichier d'input de HIMPHEU
        update gal_fal_mvt_temps
           set mvt_flag = '2'
         where current of selection_ope_non_traitee;
      end if;
    end loop;

    close selection_ope_non_traitee;
  end calc_prod_duration_with_mvt;

  function checkhrminout(v_date date, v_hrm_person_id hrm_person.hrm_person_id%type)
    return boolean
  is
    v_internumber number;
  begin
    select count(*)
      into v_internumber
      from hrm_in_out
     where hrm_employee_id = v_hrm_person_id
       and c_in_out_status = 'ACT'
       and trunc(v_date, 'DD') between ino_in and nvl(ino_out, to_date('2199/12/31', 'YYYY/MM/DD') );

    if v_internumber = 0 then
      select count(*)
        into v_internumber
        from hrm_in_out
       where hrm_employee_id = v_hrm_person_id
         and v_date between ino_in and ino_out
         and rownum = 1;

      if v_internumber = 0 then
        return false;
      end if;
    end if;

    return true;
  end checkhrminout;

  procedure init_var_activeperiod
  is
    v_period                   varchar2(4);
    v_usecalend                varchar2(1);
    v_number_day_max_saisie_ok number;
    v_calendarId               number;
  begin
    if substr(v_gal_hours_pointing_period, 1, 1) = 'M' then
      v_period  := 'MM';
    elsif substr(v_gal_hours_pointing_period, 1, 1) = 'T' then
      v_period  := 'Q';
    elsif substr(v_gal_hours_pointing_period, 1, 1) = 'A' then
      v_period  := 'YYYY';
    end if;

    v_usecalend                 := substr(v_gal_hours_pointing_period, 2, 1);
    --si utilise jour ouvrable ou non (F/O)
    v_number_day_max_saisie_ok  := to_number(substr(v_gal_hours_pointing_period, 3, 10) );
    --Nb de jour apres la fenetre de saisie ou lon autorise les pointage
    v_calendarId                := fal_schedule_functions.getdefaultcalendar;

    --defini l'id du calendrier par defaut
    if v_period = 'MM' then
      select trunc(sysdate, 'MM')
        into v_deb_period_act
        from dual;

      select (trunc(sysdate, 'MM') + interval '-1' month)
        into v_deb_period_nmoins1
        from dual;
    end if;

    if v_period = 'Q' then
      select trunc(sysdate, 'Q')
        into v_deb_period_act
        from dual;

      select (trunc(sysdate, 'Q') + interval '-3' month)
        into v_deb_period_nmoins1
        from dual;
    end if;

    if v_period = 'YYYY' then
      select trunc(sysdate, 'YYYY')
        into v_deb_period_act
        from dual;

      select (trunc(sysdate, 'YYYY') + interval '-1' year)
        into v_deb_period_nmoins1
        from dual;
    end if;

    if v_usecalend = 'O' then
      v_max_date_saisie_ok  :=
                    fal_schedule_functions.getdecalageforwarddate(null, null, null, null, null, v_calendarId, v_deb_period_act - 1, v_number_day_max_saisie_ok);
    else
      v_max_date_saisie_ok  := v_deb_period_act - 1 + v_number_day_max_saisie_ok;
    end if;
  end init_var_activeperiod;

  function check_activeperiod(v_date date)
    return boolean
  is
  begin
    if trunc(v_date, 'DD') < trunc(v_deb_period_act, 'DD') then   -- on est dans la période précédente n-1 ou n-2 .....
      if trunc(v_date, 'DD') < trunc(v_deb_period_nmoins1, 'DD') then   -- on est dans léa période n-2
        return false;
      else
        if trunc(v_max_date_saisie_ok, 'DD') < trunc(sysdate, 'DD') then
          -- on est dans la période n-1 et hors de la fenêtre autortisée
          return false;
        else
          return true;
        end if;
      end if;
    end if;

    return true;
  end check_activeperiod;

  procedure check_validity_gal(v_ret in out number, v_error_txt in out varchar2, v_hours_temp gal_fal_hours_temp%rowtype, v_type varchar2)
  is
    v_inter_number       number;
    v_inter_text         varchar2(20);
    v_hrm_person_id      hrm_person.hrm_person_id%type;
    v_date_max_in_compta date;
  begin
    if    v_hours_temp.htp_date is null
       or nvl(trim(v_hours_temp.htp_emp_number), 0) = 0
                                                       -- OR NVL (TRIM (v_hours_temp.htp_gal_fal_task_link_id), 0) = 0 0n a déjà fait le test dans l'écriture
    then
      v_ret        := 1;
      v_error_txt  := 'Données incomplètes';
      return;
    end if;

    begin
      select hrm_person_id
        into v_hrm_person_id
        from hrm_person
       where emp_number = v_hours_temp.htp_emp_number;
    exception
      when no_data_found then
        v_ret        := 1;
        v_error_txt  := 'N° de personne inexistant';
        return;
    end;

    if v_hours_temp.htp_worked_time < 0 then
      v_ret        := 1;
      v_error_txt  := 'Impossible de reconstituer la durée de op';
      return;
    end if;

    if     v_gal_hours_check_hrm_in_out = 1
       and not checkhrminout(v_hours_temp.htp_date, v_hrm_person_id) then
      v_ret        := 1;
      v_error_txt  := 'Contrat de cette personne plus valable';
      return;
    end if;

    if trunc(v_hours_temp.htp_date, 'DD') > trunc(sysdate, 'DD') then
      v_ret        := 1;
      v_error_txt  := 'Date de saisie > date du jour';
      return;
    end if;

    v_date_max_in_compta  := null;

    select max(hou_pointing_date)
      into v_date_max_in_compta
      from gal_hours
     where c_hou_state = '30'
       and hrm_person_id = v_hrm_person_id;

    /*and c_hou_origin = '2';*/

    --  DBMS_OUTPUT.put_line('hrm ' || to_char(v_hrm_person_id) );
    -- DBMS_OUTPUT.put_line('date ' || to_char(v_date_max_in_compta) );
    if     not v_date_max_in_compta is null
       and (trunc(v_hours_temp.htp_date, 'DD') <= trunc(v_date_max_in_compta) ) then
      --   DBMS_OUTPUT.put_line('test date ' ) ;
      select count(*)
        into v_inter_number
        from gal_hours
       where hrm_person_id = v_hrm_person_id
         and trunc(hou_pointing_date, 'DD') = trunc(v_hours_temp.htp_date, 'DD')
         /*and c_hou_origin = '2'*/
         and c_hou_state = '30';

      -- DBMS_OUTPUT.put_line('test point ' || to_char(v_inter_number) ) ;
      if v_inter_number > '0' then
        v_ret        := 1;
        v_error_txt  := 'Saisie déjà comptabilisée';
        return;
      end if;
    end if;

    if     v_gal_hours_pointing_period <> '0'
       and not check_activeperiod(v_hours_temp.htp_date) then
      v_ret        := 1;
      v_error_txt  := 'Date de saisie plus dans la période active';
      return;
    end if;

    if v_type = 'O' then
      begin
        select gal_task_link_id
          into v_inter_number
          from gal_task_link
         where gal_task_link_id = v_hours_temp.htp_gal_fal_task_link_id;
      exception
        when no_data_found then
          v_ret        := 1;
          v_error_txt  := 'N° de bon opération inexistant';
          return;
      end;

      -- select c_tas_state
      --   into v_inter_number
      --   from gal_task
      --      , gal_task_link
      --  where gal_task.gal_task_id = gal_task_link.gal_task_id
      --    and gal_task_link_id = v_hours_temp.htp_gal_fal_task_link_id;

      --      if v_inter_number = 40 then
      --      v_ret        := 1;
      --    v_error_txt  := 'Tâche soldée, pointage non autorisé';
      --  return;
      --  end if;
      select c_tal_state
        into v_inter_number
        from gal_task_link
       where gal_task_link_id = v_hours_temp.htp_gal_fal_task_link_id;

      if v_inter_number <= 10 then
        v_ret        := 1;
        v_error_txt  := 'Op non lancée, pointage non autorisé';
        return;
      end if;

      if v_inter_number = 40 then
        if v_pointing_ok = 0 then
          v_ret        := 1;
          v_error_txt  := 'Op soldée, pointage non autorisé';
          return;
        elsif v_pointing_ok = 1 then
          v_ret        := 2;
          v_error_txt  := 'Op soldée, mais le pointage est autorisé';
          return;
        end if;
      end if;
    end if;

    if v_type = 'I' then
      begin
        select dic_gal_hour_code_ind_id
          into v_inter_text
          from dic_gal_hour_code_ind
         where dic_gal_hour_code_ind_id = v_hours_temp.htp_gal_fal_task_link_id
           and nvl(dic_gal_hour_code_ind.dic_hci_out_of_order, 0) = 0;
      exception
        when no_data_found then
          v_ret        := 1;
          v_error_txt  := 'Code indirect inexistant ou hors-service';
          return;
      end;

      v_inter_number  := 0;

      select gal_project_spending.get_gal_cost_center_fromcpncda(null
                                                               , gal_project_spending.get_acs_cda_account_of_person(v_hrm_person_id, v_hours_temp.htp_date)
                                                               , 'GAL_ANALYTIC_NATURE_LABOUR'
                                                                )
        into v_inter_number
        from dual;

      if v_inter_number is null then
        v_ret        := 1;
        v_error_txt  := 'Personne non liée à une nature analytique';
        return;
      end if;

      select gal_project_spending.get_hourly_rate_from_nat_ana(v_inter_number, v_hours_temp.htp_date)
        into v_inter_number
        from dual;

      if v_inter_number = 0 then
        v_ret        := 2;
        v_error_txt  := 'Taux de la nature valorisé à 0';
        return;
      end if;

      if v_inter_number is null then
        v_ret        := 2;
        v_error_txt  := 'Taux de la nature non défini -> poussé à 0';
        return;
      end if;
    end if;
  end check_validity_gal;

  procedure init_var_check_gal_hours
  is
  begin
    begin
      select pcs.pc_config.getconfig('GAL_HOURS_POINTING_AUTHORIZATI')
        into v_pointing_ok
        from dual;
    exception
      when no_data_found then
        v_pointing_ok  := 0;
    end;

    begin
      select pcs.pc_config.getconfig('GAL_HOURS_CHECK_HRM_IN_OUT')
        into v_gal_hours_check_hrm_in_out
        from dual;
    exception
      when no_data_found then
        v_gal_hours_check_hrm_in_out  := 0;
    end;

    begin
      select pcs.pc_config.getconfig('GAL_HOURS_POINTING_PERIOD')
        into v_gal_hours_pointing_period
        from dual;
    exception
      when no_data_found then
        v_gal_hours_pointing_period  := 0;
    end;

    if v_gal_hours_pointing_period <> '0' then
      init_var_activeperiod;
    end if;
  end init_var_check_gal_hours;

  procedure import_hours_in_gal(
    v_ret                 in out number
  , v_error_txt           in out varchar2
  , v_hours_temp                 gal_fal_hours_temp%rowtype
  , v_date_deb_traitement        date
  , v_type                       varchar2
  , v_recalcul_from_mvt          boolean
  , v_hou_origin                 varchar2
  )
  is
    v_hrm_person_id      hrm_person.hrm_person_id%type;
    v_hour_rate          number(14, 2);
    v_gal_task_id        gal_task.gal_task_id%type;
    v_gal_project_id     gal_project.gal_project_id%type;
    v_inter_number       number;
    v_gal_cost_center_id gal_cost_center.gal_cost_center_id%type   := null;
    v_inter_text         varchar2(20);
  begin
    --    ind_import_prod_duration.ind_check_validity_gal(v_ret, v_error_txt, v_hours_temp, v_type);
    -- TMP DéSACTIVé -> corrigé poiur SP5!!
    if v_ret = 1 then
      return;
    end if;

    check_validity_gal(v_ret, v_error_txt, v_hours_temp, v_type);

    if v_ret = 1 then
      return;
    end if;

    select hrm_person_id
      into v_hrm_person_id
      from hrm_person
     where v_hours_temp.htp_emp_number = hrm_person.emp_number;

    if v_type = 'O' then
      select gal_task_id
        into v_gal_task_id
        from gal_task_link
       where gal_task_link.gal_task_link_id = v_hours_temp.htp_gal_fal_task_link_id;

      select gal_project_id
        into v_gal_project_id
        from gal_task
       where gal_task.gal_task_id = v_gal_task_id;

      select gal_project_spending.get_hourly_rate_from_ress_ope(v_hours_temp.htp_gal_fal_task_link_id, 0, 0, 0, v_hours_temp.htp_date)
        into v_hour_rate
        from dual;

      if v_hour_rate is null then
        v_hour_rate  := 0;
      end if;

      select fff.gal_cost_center_id
        into v_gal_cost_center_id
        from gal_task_link gtl
           , fal_factory_floor fff
       where fff.fal_factory_floor_id = gtl.fal_factory_floor_id
         and gtl.gal_task_link_id = v_hours_temp.htp_gal_fal_task_link_id;

      if v_gal_cost_center_id is null then
        begin
          select gal_cost_center_id
            into v_gal_cost_center_id
            from gal_cost_center
           where gcc_code = pcs.pc_config.GetConfig('GAL_ANALYTIC_NATURE_LABOUR');
        exception
          when no_data_found then
            v_gal_cost_center_id  := null;
        end;
      end if;
    elsif v_type = 'I' then
      select gal_project_spending.get_gal_cost_center_fromcpncda(null
                                                               , gal_project_spending.get_acs_cda_account_of_person(v_hrm_person_id, v_hours_temp.htp_date)
                                                               , 'GAL_ANALYTIC_NATURE_LABOUR'
                                                                )
        into v_gal_cost_center_id
        from dual;

      select gal_project_spending.get_hourly_rate_from_nat_ana(v_gal_cost_center_id, v_hours_temp.htp_date)
        into v_hour_rate
        from dual;

      if v_hour_rate is null then
        v_hour_rate  := 0;
      end if;
    end if;

    if v_recalcul_from_mvt then
      select count(*)
        into v_inter_number
        from gal_hours
       where hrm_person_id = v_hrm_person_id
         and trunc(hou_pointing_date, 'DD') = trunc(v_hours_temp.htp_date, 'DD')
         and c_hou_origin = '2'
         and a_datecre < v_date_deb_traitement;

      if v_inter_number > 0 then
        delete      gal_hours
              where hrm_person_id = v_hrm_person_id
                and trunc(hou_pointing_date, 'DD') = trunc(v_hours_temp.htp_date, 'DD')
                and c_hou_origin = '2';
      end if;
    end if;

    if v_hours_temp.htp_worked_time > 0 then
      if v_type = 'O' then
        insert into gal_hours
                    (gal_hours_id
                   , hrm_person_id
                   , gal_project_id
                   , gal_task_id
                   , gal_task_link_id
                   , c_hou_state
                   , c_hou_origin
                   , hou_pointing_date
                   , hou_worked_time
                   , gal_cost_center_id
                   , hou_hourly_rate
                   , a_datecre
                   , a_idcre
                    )
             values (init_id_seq.nextval
                   , v_hrm_person_id
                   , v_gal_project_id
                   , v_gal_task_id
                   , v_hours_temp.htp_gal_fal_task_link_id
                   , '10'
                   , v_hou_origin
                   , trunc(v_hours_temp.htp_date, 'DD')
                   , v_hours_temp.htp_worked_time
                   , v_gal_cost_center_id
                   , v_hour_rate
                   , sysdate
                   , 'IMP'
                    );
      elsif v_type = 'I' then
        insert into gal_hours
                    (gal_hours_id
                   , hrm_person_id
                   , dic_gal_hour_code_ind_id
                   , c_hou_state
                   , c_hou_origin
                   , hou_pointing_date
                   , hou_worked_time
                   , gal_cost_center_id
                   , hou_hourly_rate
                   , a_datecre
                   , a_idcre
                    )
             values (init_id_seq.nextval
                   , v_hrm_person_id
                   , v_hours_temp.htp_gal_fal_task_link_id
                   , '10'
                   , v_hou_origin
                   , trunc(v_hours_temp.htp_date, 'DD')
                   , v_hours_temp.htp_worked_time
                   , v_gal_cost_center_id
                   , v_hour_rate
                   , sysdate
                   , 'IMP'
                    );
      end if;
    end if;
  end import_hours_in_gal;

  procedure det_which_type_of_hours_gal(v_hours_temp gal_fal_hours_temp%rowtype, v_type in out varchar2)
  is
    v_inter_text   varchar2(20);
    v_inter_number number(12);
  begin
    v_type  := 'O';

    begin
      select gal_task_link_id
        into v_inter_number
        from gal_task_link
       where gal_task_link.gal_task_link_id = v_hours_temp.htp_gal_fal_task_link_id;
    exception
      when others then
        begin
          v_type  := 'I';

          select dic_gal_hour_code_ind_id
            into v_inter_text
            from dic_gal_hour_code_ind
           where dic_gal_hour_code_ind_id = v_hours_temp.htp_gal_fal_task_link_id;
        exception
          when others then
            null;
        end;
    end;
  end det_which_type_of_hours_gal;

  procedure init_text_for_mes_gal(v_type varchar2, v_hours_temp gal_fal_hours_temp%rowtype, v_txt in out varchar2)
  is
  begin
    if v_type = 'O' then
      begin
        select scs_step_number || ' ' || scs_short_descr
          into v_txt
          from gal_task_link
         where gal_task_link_id = v_hours_temp.htp_gal_fal_task_link_id;
      exception
        when others then
          v_txt  := 'ID OP ' || v_hours_temp.htp_gal_fal_task_link_id;
      end;
    else
      v_txt  := v_hours_temp.htp_gal_fal_task_link_id;
    end if;
  end init_text_for_mes_gal;
end gal_fal_import_time_prod;
