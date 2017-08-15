--------------------------------------------------------
--  DDL for Package Body GAL_FAL_IMPORT_PRESENCE_TIME
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_FAL_IMPORT_PRESENCE_TIME" 
is
  procedure ecriture_itempresent(
    v_personne       hrm_person.emp_number%type
  , v_date_heure     date
  , v_duree          number
  , v_filehandle_err UTL_FILE.file_type
  )
  is
    v_ligne            varchar2(300);
    ligne              natural                      := 1;
    v_inter_emp_number hrm_person.emp_number%type;
  begin
    begin
      select emp_number
        into v_inter_emp_number
        from hrm_person
       where emp_number = v_personne;
    exception
      when no_data_found then
        v_ligne  :=
          'Erreur: le numéro de personnel ' ||
          v_personne ||
          ' est inconnu' ||
          ', Date pointage: ' ||
          to_char(v_date_heure, 'DD/MM/YYYY HH24:MI') ||
          ', Durée : ' ||
          trunc(ltrim(to_char(v_duree) ), 2);
        UTL_FILE.putf(v_filehandle_err, '%s', v_ligne);
        UTL_FILE.new_line(v_filehandle_err, ligne);
        return;
    end;

    if    v_duree > 24
       or v_duree <= 0 then
      v_ligne  :=
        'Erreur: Durée incorrecte, Numéro de personnel ' ||
        v_personne ||
        ', Date pointage: ' ||
        to_char(v_date_heure, 'DD/MM/YYYY HH24:MI') ||
        ', Durée : ' ||
        trunc(ltrim(to_char(v_duree) ), 2);
      UTL_FILE.putf(v_filehandle_err, '%s', v_ligne);
      UTL_FILE.new_line(v_filehandle_err, ligne);
      return;
    end if;

    insert into gal_fal_tempresent_temp
         values (init_id_seq.nextval
               , v_personne
               , v_date_heure
               , v_duree
                );
  end ecriture_itempresent;

  procedure write_def_in_tempresent(v_filehandle_ok UTL_FILE.file_type)
  is
    v_cpt   number;
    v_ligne varchar2(300);
    ligne   natural       := 1;
  begin
    for v_tts_hours in (select   tts_emp_number
                               , min(tts_date) tts_date
                               , sum(tts_presence) duration
                            from gal_fal_tempresent_temp
                        group by tts_emp_number
                               , to_char(tts_date, 'DD/MM/YYYY')
                        order by tts_emp_number) loop
      select count(*)
        into v_cpt
        from gal_fal_tempresent
       where tps_emp_number = v_tts_hours.tts_emp_number
         and to_char(tps_date, 'DD/MM/YYYY') = to_char(v_tts_hours.tts_date, 'DD/MM/YYYY');

      if v_cpt = 0 then
        insert into gal_fal_tempresent
             values (init_id_seq.nextval
                   , v_tts_hours.tts_emp_number
                   , v_tts_hours.tts_date
                   , v_tts_hours.duration
                   , sysdate
                   , 'IMP'
                   , null
                   , null
                    );

        v_ligne  :=
          'Insertion données: Numéro de personnel ' ||
          v_tts_hours.tts_emp_number ||
          ', Date pointage: ' ||
          to_char(v_tts_hours.tts_date, 'DD/MM/YYYY') ||
          ', Durée : ' ||
          trunc(ltrim(to_char(v_tts_hours.duration) ), 2);
      else
        update gal_fal_tempresent
           set tps_presence = v_tts_hours.duration
             , a_datemod = sysdate
             , a_idmod = 'IMP'
         where tps_emp_number = v_tts_hours.tts_emp_number
           and to_char(tps_date, 'DD/MM/YYYY') = to_char(v_tts_hours.tts_date, 'DD/MM/YYYY');

        v_ligne  :=
          'Modification données: Numéro de personnel ' ||
          v_tts_hours.tts_emp_number ||
          ', Date pointage: ' ||
          to_char(v_tts_hours.tts_date, 'DD/MM/YYYY') ||
          ', Durée : ' ||
          trunc(ltrim(to_char(v_tts_hours.duration) ), 2);
      end if;

      UTL_FILE.putf(v_filehandle_ok, '%s', v_ligne);
      UTL_FILE.new_line(v_filehandle_ok, ligne);
    end loop;
  end write_def_in_tempresent;

/*
maà des données par employées et par date
*/
  procedure delete_gal_fal_mvt_time(v_date_start_treatment date)
  is
    v_count   number;
    v_count_1 number;
  begin
    for v_mvt_pres_temp in (select   mvt_emp_number   -- on cherche les données modifiées par employé et par date
                                   , to_char(mvt_date, 'DD/MM/YYYY') mvt_date
                                from gal_fal_mvt_temps
                               where a_datemod >= v_date_start_treatment
                                 and mvt_type in('E', 'S')
                            group by mvt_emp_number
                                   , to_char(mvt_date, 'DD/MM/YYYY') ) loop
      -- on cherche les données de mvt qui n'ont pas été touchées -> correction des erreur
      select count(mvt_emp_number)
        into v_count
        from gal_fal_mvt_temps
       where mvt_emp_number = v_mvt_pres_temp.mvt_emp_number
         and v_mvt_pres_temp.mvt_date = to_char(gal_fal_mvt_temps.mvt_date, 'DD/MM/YYYY')
         and a_datemod < v_date_start_treatment
         and mvt_type in('E', 'S');

      -- on recherche les éventuelles nouvelles données de mvt
      select count(mvt_emp_number)
        into v_count_1
        from gal_fal_mvt_temps   -- on efface les données par employé/date qui n'ont pas été modifiées dues à une correction
       where mvt_emp_number = v_mvt_pres_temp.mvt_emp_number
         and v_mvt_pres_temp.mvt_date = to_char(gal_fal_mvt_temps.mvt_date, 'DD/MM/YYYY')
         and a_datemod >= v_date_start_treatment
         and mvt_flag = '0'
         and mvt_type in('E', 'S');

      if    not v_count = 0
         or not v_count_1 = 0 then
        delete      gal_fal_mvt_temps   -- on efface les données par employé/date qui n'ont pas été modifiées dues à une correction
              where mvt_emp_number = v_mvt_pres_temp.mvt_emp_number
                and v_mvt_pres_temp.mvt_date = to_char(gal_fal_mvt_temps.mvt_date, 'DD/MM/YYYY')
                and a_datemod < v_date_start_treatment
                and mvt_type in('E', 'S');

        update gal_fal_mvt_temps   -- on flag ces données comme étant à reclaculer
           set mvt_flag = '0'
         where mvt_emp_number = v_mvt_pres_temp.mvt_emp_number
           and v_mvt_pres_temp.mvt_date = to_char(gal_fal_mvt_temps.mvt_date, 'DD/MM/YYYY')
           and mvt_type in('E', 'S');
      end if;
    end loop;
  end delete_gal_fal_mvt_time;

  function check_data_soon_in(v_personne gal_fal_mvt_temps.mvt_emp_number%type, v_date_heure date, v_type varchar2)
    return boolean
  is
    v_count number;
  begin
    select count(mvt_emp_number)   -- on cherche si la donnée existe déjà
      into v_count
      from gal_fal_mvt_temps
     where mvt_emp_number = v_personne
       and mvt_date = v_date_heure
       and mvt_type = v_type;

    if v_count > 0 then
      update gal_fal_mvt_temps   -- si oui on flag le a_date mode qui inous permettra par la suite de savoir qeu cette donée a déjà été impoortée
         set a_datemod = sysdate   -- car on peut avoir une seule entrée d'E/S modifiée sur les 4 nécessaires sur un jour
       where mvt_emp_number = v_personne
         and mvt_date = v_date_heure
         and mvt_type = v_type;

      return true;
    else
      return false;
    end if;
  end check_data_soon_in;

  procedure insert_gal_fal_mvt_time(
    v_personne   gal_fal_mvt_temps.mvt_emp_number%type
  , v_date_heure date
  , v_type       varchar2
  )
  is
    v_count number;
  begin
    v_count  := 0;

    select count(*)
      into v_count
      from gal_fal_mvt_temps
     where gal_fal_mvt_temps.mvt_emp_number = v_personne
       and to_char(gal_fal_mvt_temps.mvt_date, 'DD/MM/YYYY HH24:MI') = to_char(v_date_heure, 'DD/MM/YYYY HH24:MI')
       and gal_fal_mvt_temps.mvt_type in('E', 'S')
       and gal_fal_mvt_temps.mvt_type <> v_type;

    v_count  := v_count *(1 / 24 / 60 / 60);

    --Ajout 1 seconde par mouvement E S dans la même minute
    insert into gal_fal_mvt_temps
                (gal_fal_mvt_temps_id
               , mvt_emp_number
               , mvt_date
               , mvt_type
               , mvt_flag
               , a_datecre
               , a_idcre
               , a_datemod
                )
         values (init_id_seq.nextval
               , v_personne
               , v_date_heure + v_count
               , v_type
               , '0'
               , sysdate
               , 'IMP'
               , sysdate
                );
  end insert_gal_fal_mvt_time;

  procedure calcul_presence_duration(p_filedir varchar2)
  is
    v_duree             number;
    v_date_sortie       date;
    v_date_heure        date;
    v_personne          gal_fal_mvt_temps.mvt_emp_number%type;
    v_filedir           varchar2(400);
    v_filename_dest_err varchar2(400);
    v_filename_dest_ok  varchar2(400);
    v_filehandle_err    UTL_FILE.file_type;
    v_filehandle_ok     UTL_FILE.file_type;

    cursor selection_entree_non_traitee
    is
      select     mvt_emp_number
               , mvt_date
            from gal_fal_mvt_temps
           where mvt_type = 'E'
             and mvt_flag = '0'
        order by 1
               , 2
      for update;

    cursor selection_sortie_suivante
    is
      select     gal_fal_mvt_temps.mvt_date
            from gal_fal_mvt_temps
           where gal_fal_mvt_temps.mvt_emp_number = v_personne
             and gal_fal_mvt_temps.mvt_type = 'S'
             and to_char(gal_fal_mvt_temps.mvt_date, 'DD/MM/YYYY') = to_char(v_date_heure, 'DD/MM/YYYY')
             and gal_fal_mvt_temps.mvt_date =
                   (select min(a.mvt_date)
                      from gal_fal_mvt_temps a
                     where a.mvt_emp_number = gal_fal_mvt_temps.mvt_emp_number
                       and a.mvt_type = 'S'
                       and to_char(a.mvt_date, 'DD/MM/YYYY') = to_char(v_date_heure, 'DD/MM/YYYY')
                       and a.mvt_date > v_date_heure)
      for update;

    cursor selection_sortie_non_traitee
    is
      select     mvt_emp_number
               , mvt_date
            from gal_fal_mvt_temps
           where mvt_type = 'S'
             and mvt_flag = '0'
        order by 1
               , 2
      for update;
  begin
    ----- Ouverture fichier d'output
    v_filedir            := rtrim(p_filedir || '\outputfiles');
    v_filename_dest_err  := 'ER_importtps_' || to_char(sysdate, 'DD_MM_YYYY_HH24_MI') || '.txt';
    v_filename_dest_ok   := 'OK_importtps_' || to_char(sysdate, 'DD_MM_YYYY_HH24_MI') || '.txt';
    v_filehandle_err     := UTL_FILE.fopen(v_filedir, v_filename_dest_err, 'w');
    v_filehandle_ok      := UTL_FILE.fopen(v_filedir, v_filename_dest_ok, 'w');

    ----- Lecture des mouvements d'entree non traites
    open selection_entree_non_traitee;

    loop
      exit when selection_entree_non_traitee%notfound;

      fetch selection_entree_non_traitee
       into v_personne
          , v_date_heure;

      if selection_entree_non_traitee%found then   ----- Lecture mouvement de sortie suivant
        v_date_sortie  := null;

        open selection_sortie_suivante;

        loop
          fetch selection_sortie_suivante
           into v_date_sortie;

          exit when selection_sortie_suivante%notfound;

          if selection_sortie_suivante%found then
            ----- calcul duree entre heure Sortie et heure Entree
            v_duree  :=( (v_date_sortie - v_date_heure) * 24);
            ecriture_itempresent(v_personne, v_date_heure, v_duree, v_filehandle_err);

            ----- Ecriture dans fichier d'input de HIMPTPS
            update gal_fal_mvt_temps
               set mvt_flag = '1'
                 , a_idmod = 'IMP'
                 , a_datemod = sysdate
             where current of selection_sortie_suivante;
          end if;
        end loop;

        close selection_sortie_suivante;

        if v_date_sortie is null then
          ----- si pas de mouvement de sortie suivant
          ----- calcul duree entre 24:00 et heure Entree
          v_duree  :=
            ( ( (to_date(to_char(v_date_heure, 'DD/MM/YYYY') || ' 00:00:00', 'DD/MM/YYYY HH24:MI:SS') + 1)
               - v_date_heure) *
             24
            );
          ecriture_itempresent(v_personne, v_date_heure, v_duree, v_filehandle_err);
----- Ecriture dans fichier d'input de HIMPTPS                                                   ----- Ecriture dans fichier d'input de HIMPTPS
        end if;

        update gal_fal_mvt_temps
           set mvt_flag = '1'
             , a_idmod = 'IMP'
             , a_datemod = sysdate
         where current of selection_entree_non_traitee;
      end if;
    end loop;

    close selection_entree_non_traitee;

    ----- Lecture des mouvements de sortie non traites
    open selection_sortie_non_traitee;

    loop
      exit when selection_sortie_non_traitee%notfound;

      fetch selection_sortie_non_traitee
       into v_personne
          , v_date_heure;

      if selection_sortie_non_traitee%found then
        ----- si sortie sans entree
        ----- calcul duree entre heure sortie et 00:00
        v_duree  :=
            ( (v_date_heure - to_date(to_char(v_date_heure, 'DD/MM/YYYY') || ' 00:00:00', 'DD/MM/YYYY HH24:MI:SS') )
             * 24
            );
        ecriture_itempresent(v_personne, v_date_heure, v_duree, v_filehandle_err);

---- Ecriture dans fichier d'input de HIMPTPS                                                             ----- Ecriture dans fichier d'input de HIMPTPS
        update gal_fal_mvt_temps
           set mvt_flag = '1'
             , a_idmod = 'IMP'
             , a_datemod = sysdate
         where current of selection_sortie_non_traitee;
      end if;
    end loop;

    close selection_sortie_non_traitee;

    write_def_in_tempresent(v_filehandle_ok);
    ----- fermeture fichier d'output
    UTL_FILE.fclose(v_filehandle_err);
    UTL_FILE.fclose(v_filehandle_ok);
  end calcul_presence_duration;
end gal_fal_import_presence_time;
