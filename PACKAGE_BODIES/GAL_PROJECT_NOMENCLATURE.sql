--------------------------------------------------------
--  DDL for Package Body GAL_PROJECT_NOMENCLATURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PROJECT_NOMENCLATURE" 
is
--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure generate_from_gal_task(
    a_Id               gal_task.gal_task_id%type
  , out_warning in out clob
  , out_error   in out clob
  , out_pps_id  in out gal_budget.pps_nomenclature_id%type
  )
  is
    v_pps               number;
    v_tas_record_id     gal_task.doc_record_id%type;
    v_prj_record_id     gal_task.doc_record_id%type;
    v_bud_record_id     gal_task.doc_record_id%type;
    v_gal_task_good_id  gal_task_good.gal_task_good_id%type;
    v_pps_new_hea_id    pps_nomenclature.pps_nomenclature_id%type;
    v_pps_new_nom_id    pps_nomenclature.pps_nomenclature_id%type;
    v_gml_is_fixed      gal_task_good.gml_is_fixed%type;
    v_gml_nom_version   pps_nomenclature.nom_version%type;
    v_good_id           gal_task_good.gco_good_id%type;
    v_gco_good_prj_id   gal_project.gco_good_id%type;
    v_pps_prj_id        gal_project.pps_nomenclature_id%type;
    v_prj_id            gal_project.gal_project_id%type;
    v_qty_dir           gal_task_good.gml_quantity%type;
    v_gco_good_bud_id   gal_project.gco_good_id%type;
    v_pps_bud_id        gal_project.pps_nomenclature_id%type;
    v_bud_id            gal_project.gal_project_id%type;
    v_cpt_sequence      number;
    v_PPS_Com_Numbering number;

    cursor C_GAL_TASK_GOOD
    is
      select   GAL_TASK_GOOD.pps_nomenclature_id
             , GAL_TASK.doc_record_id
             , gal_task_good_id
             , gml_is_fixed
             , GAL_TASK_GOOD.gco_good_id
             , GAL_TASK_GOOD.GML_QUANTITY
          from GAL_TASK_GOOD
             , GAL_TASK
         where GAL_TASK_GOOD.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
           and GAL_TASK_GOOD.PPS_NOMENCLATURE_ID is not null
           and GAL_TASK.GAL_TASK_ID = a_Id
      order by GML_SEQUENCE;
  begin
    v_cpt_sequence  := 0;

    open c_gal_task_good;

    loop
      fetch c_gal_task_good
       into v_pps
          , v_tas_record_id
          , v_gal_task_good_id
          , v_gml_is_fixed
          , v_good_id
          , v_qty_dir;

      exit when c_gal_task_good%notfound;
      v_cpt_sequence  := v_cpt_sequence + 1;

      if v_cpt_sequence = 1 then
        begin
          select PCS.PC_CONFIG.GETCONFIG('PPS_Com_Numbering')
            into v_PPS_Com_Numbering
            from dual;
        exception
          when no_data_found then
            v_PPS_Com_Numbering  := 1;
        end;
      end if;

      PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_NOMENCLATURE(v_pps
                                                    , v_tas_record_id
                                                    , null
                                                    , null
                                                    , null
                                                    , null
                                                    , v_good_id
                                                    , v_PPS_Com_Numbering
                                                    , v_qty_dir
                                                    , v_pps_new_hea_id
                                                    , v_pps_new_nom_id
                                                     );

      --Avec doc_record_id de gal_task
      if v_pps_new_nom_id is not null then
        update gal_task_good
           set pps_nomenclature_id = v_pps_new_nom_id
             , gml_is_fixed = 1
         where gal_task_good_id = v_gal_task_good_id;

        if sql%found then
          out_warning  :=
            rtrim(out_warning) ||
            PCS.PC_FUNCTIONS.TranslateWord('Rattachement de la nomenclature SAV à la tâche') ||
            ' docId>' ||
            to_char(v_tas_record_id) ||
            chr(10);
        end if;
      end if;

      if     v_gml_is_fixed <> 1
         and v_pps_new_nom_id is null then
        begin
          select nom_version
            into v_gml_nom_version
            from pps_nomenclature
           where pps_nomenclature_id = v_pps;

          begin
            select pps_nomenclature_id
              into v_pps_new_nom_id
              from pps_nomenclature
             where gco_good_id = v_good_id
               and (nvl(nom_version, ' ') ) =(nvl(v_gml_nom_version, ' ') )
               and doc_record_id = v_tas_record_id
               and rownum = 1;

            update gal_task_good
               set pps_nomenclature_id = v_pps_new_nom_id
                 , gml_is_fixed = 1
             where gal_task_id = a_Id
               and gco_good_id = v_good_id
               and pps_nomenclature_id = v_pps
               and gml_is_fixed <> 1;
          exception
            when no_data_found then
              null;
          end;
        exception
          when no_data_found then
            null;
        end;
      end if;
    end loop;

    close c_gal_task_good;
  end generate_from_gal_task;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure generate_from_gal_project(
    a_Id               gal_task.gal_task_id%type
  , out_warning in out clob
  , out_error   in out clob
  , out_pps_id  in out gal_project.pps_nomenclature_id%type
  )
  is
    v_pps               number;
    v_tas_record_id     gal_task.doc_record_id%type;
    v_prj_record_id     gal_task.doc_record_id%type;
    v_bud_record_id     gal_task.doc_record_id%type;
    v_gal_task_good_id  gal_task_good.gal_task_good_id%type;
    v_pps_new_hea_id    pps_nomenclature.pps_nomenclature_id%type;
    v_pps_new_nom_id    pps_nomenclature.pps_nomenclature_id%type;
    v_gml_is_fixed      gal_task_good.gml_is_fixed%type;
    v_good_id           gal_task_good.gco_good_id%type;
    v_gco_good_prj_id   gal_project.gco_good_id%type;
    v_pps_prj_id        gal_project.pps_nomenclature_id%type;
    v_prj_id            gal_project.gal_project_id%type;
    v_qty_dir           gal_task_good.gml_quantity%type;
    x_qty_dir           gal_task_good.gml_quantity%type;
    v_gco_good_bud_id   gal_project.gco_good_id%type;
    v_pps_bud_id        gal_project.pps_nomenclature_id%type;
    v_bud_id            gal_project.gal_project_id%type;
    v_pps_header_origin gal_project.pps_nomenclature_id%type;
    v_gco_header_origin gal_project.gco_good_id%type;
    v_prj_rec_id        gal_task.doc_record_id%type;
    v_gml_nom_version   pps_nomenclature.nom_version%type;
    v_tas_id            gal_project.gal_project_id%type;
    v_cpt_sequence      number;
    v_PPS_Com_Numbering number;

    cursor C_PRJ_TASK_GOOD
    is
      select   GAL_TASK_GOOD.pps_nomenclature_id
             , GAL_TASK.doc_record_id
             , GAL_PROJECT.doc_record_id
             , gal_task_good_id
             , gml_is_fixed
             , GAL_TASK_GOOD.gco_good_id
             , GAL_TASK_GOOD.GML_QUANTITY
             , GAL_PROJECT.GCO_GOOD_ID
             , GAL_PROJECT.PPS_NOMENCLATURE_ID
             , GAL_PROJECT.GAL_PROJECT_ID
             , GAL_TASK_GOOD.GAL_TASK_ID
          from GAL_PROJECT
             , GAL_TASK_GOOD
             , GAL_TASK
         where GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
           and GAL_TASK_GOOD.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
           --AND GAL_TASK_GOOD.PPS_NOMENCLATURE_ID IS NOT NULL
           and GAL_TASK.GAL_PROJECT_ID = a_Id
      --AND GAL_PROJECT.PPS_NOMENCLATURE_ID IS NOT NULL
      order by TAS_CODE
             , GML_SEQUENCE;
  begin
    begin
      select pps_nomenclature_id
           , gco_good_id
           , doc_record_id
        into v_pps_header_origin
           , v_gco_header_origin
           , v_prj_rec_id
        from gal_project
       where gal_project_id = a_Id;

      v_pps_new_hea_id  := null;
      v_pps_new_nom_id  := null;
      /* Path 1 = Création des nomenclatures Sav de tâche (article directeur) si n'existent pas */
      v_cpt_sequence    := 0;

      open c_prj_task_good;

      loop
        fetch c_prj_task_good
         into v_pps
            , v_tas_record_id
            , v_prj_record_id
            , v_gal_task_good_id
            , v_gml_is_fixed
            , v_good_id
            , v_qty_dir
            , v_gco_good_prj_id
            , v_pps_prj_id
            , v_prj_id
            , v_tas_id;

        exit when c_prj_task_good%notfound;
        v_cpt_sequence    := v_cpt_sequence + 1;
        v_pps_new_nom_id  := null;

        if v_cpt_sequence = 1 then
          begin
            select PCS.PC_CONFIG.GETCONFIG('PPS_Com_Numbering')
              into v_PPS_Com_Numbering
              from dual;
          exception
            when no_data_found then
              v_PPS_Com_Numbering  := 1;
          end;
        end if;

        if v_pps is not null then
          -->Debranché pour l'instant par
          if     v_gco_good_prj_id is not null
             and v_pps_prj_id is not null then   --On ne creera  pas la tête
            select sum(gml_quantity)
              into x_qty_dir   /*Qte cumulée*/
              from gal_task_good
             where gal_task_id = v_tas_id
               and pps_nomenclature_id = v_pps
               and pps_nomenclature_id is not null;

            PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_NOMENCLATURE(v_pps
                                                          , v_tas_record_id
                                                          , v_prj_record_id
                                                          , null
                                                          , v_gco_good_prj_id
                                                          , v_pps_prj_id
                                                          , v_good_id
                                                          , v_PPS_Com_Numbering
                                                          , x_qty_dir
                                                          , v_pps_new_hea_id
                                                          , v_pps_new_nom_id
                                                           );
          else   --On creera la tête
            PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_NOMENCLATURE(v_pps
                                                          , v_tas_record_id
                                                          , null
                                                          , null
                                                          , null
                                                          , null
                                                          , v_good_id
                                                          , v_PPS_Com_Numbering
                                                          , v_qty_dir
                                                          , v_pps_new_hea_id
                                                          , v_pps_new_nom_id
                                                           );
          end if;

/* debranché...
      if v_gco_good_prj_id is not null
      and v_pps_prj_id is null
      then --On ne creera  pas la tête
          PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_NOMENCLATURE(v_pps,v_tas_record_id,v_prj_record_id,null,v_gco_good_prj_id,v_pps_prj_id,v_good_id,v_PPS_Com_Numbering,v_qty_dir,v_pps_new_hea_id,v_pps_new_nom_id);
        else --On creera la tête
        PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_NOMENCLATURE(v_pps,v_tas_record_id,null,null,null,null,v_good_id,v_PPS_Com_Numbering,v_qty_dir,v_pps_new_hea_id,v_pps_new_nom_id);
          end if;
*/
          if v_pps_new_hea_id is not null then
            update gal_project
               set pps_nomenclature_id = v_pps_new_hea_id
             where gal_project_id = a_Id;

            if sql%found then
              out_warning  :=
                      rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Création de la nomenclature SAV') || ' PpsId>' || to_char(v_pps_new_hea_id)
                      || chr(10);
            end if;
          end if;

          --Avec doc_record_id de gal_task
          if v_pps_new_nom_id is not null then
            update gal_task_good
               set pps_nomenclature_id = v_pps_new_nom_id
                 , gml_is_fixed = 1
             where gal_task_good_id = v_gal_task_good_id;

            if sql%found then
              out_warning  :=
                rtrim(out_warning) ||
                PCS.PC_FUNCTIONS.TranslateWord('Rattachement de la nomenclature SAV à la tâche') ||
                ' docId>' ||
                to_char(v_tas_record_id) ||
                chr(10);
            end if;
          end if;

          if     v_gml_is_fixed <> 1
             and v_pps_new_nom_id is null then
            begin
              select nom_version
                into v_gml_nom_version
                from pps_nomenclature
               where pps_nomenclature_id = v_pps;

              begin
                select pps_nomenclature_id
                  into v_pps_new_nom_id
                  from pps_nomenclature
                 where gco_good_id = v_good_id
                   and (nvl(nom_version, ' ') ) =(nvl(v_gml_nom_version, ' ') )
                   and doc_record_id = v_tas_record_id
                   and rownum = 1;

                update gal_task_good
                   set pps_nomenclature_id = v_pps_new_nom_id
                     , gml_is_fixed = 1
                 where gal_task_id = v_tas_id
                   and gco_good_id = v_good_id
                   and pps_nomenclature_id = v_pps
                   and gml_is_fixed <> 1;
              exception
                when no_data_found then
                  null;
              end;
            exception
              when no_data_found then
                null;
            end;
          end if;
        end if;

        if v_pps is null then
          select sum(gml_quantity)
            into x_qty_dir   /*Qte cumulée*/
            from gal_task_good
           where gal_task_id = v_tas_id
             and gco_good_id = v_good_id
             and v_pps is null;

          PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_HEADER(v_prj_record_id, v_pps_new_hea_id, v_gco_good_prj_id, v_pps_prj_id);
          PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_COMPONENT(v_pps_new_hea_id, v_good_id, null, v_PPS_Com_Numbering, x_qty_dir);

          if v_gml_is_fixed <> 1 then
            update gal_task_good
               set gml_is_fixed = 1
             where gal_task_good_id = v_gal_task_good_id;
          end if;
        end if;
      end loop;

      close c_prj_task_good;
    /* Fin Path 1 */

    /* Path 2 = Création de la nomenclature complête de l'affaire à partir de l'id renseignée sur l'affaire*/

    -->Debranché pour l'instant
    /*
     v_pps_new_hea_id := null;
     v_pps_new_nom_id := null;

     begin
         select PCS.PC_CONFIG.GETCONFIG('PPS_Com_Numbering') into v_PPS_Com_Numbering from dual;
       exception when NO_DATA_FOUND then
         v_PPS_Com_Numbering := 1;
       end;

     PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_NOMENCLATURE(v_pps_header_origin,null,v_prj_rec_id,null,v_gco_header_origin,v_pps_header_origin,v_gco_header_origin,v_PPS_Com_Numbering,1,v_pps_new_hea_id,v_pps_new_nom_id);

     if v_pps_new_hea_id is not null
     then

       update gal_project set pps_nomenclature_id = v_pps_new_hea_id where gal_project_id = a_Id;

       if sql%found then
       out_warning := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Création de la nomenclature SAV') || ' PpsId>' || to_char(v_pps_new_hea_id)  || chr(10);
       End if;

     end if;

     if v_pps_new_hea_id is not null
     then out_pps_id := v_pps_new_hea_id;
     else out_pps_id := v_pps_header_origin;
     end if;
    */
     /* Fin Path 2*/
    exception
      when no_data_found then
        null;
    end;
  end generate_from_gal_project;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure generate_from_gal_budget(
    a_Id               gal_task.gal_task_id%type
  , out_warning in out clob
  , out_error   in out clob
  , out_pps_id  in out gal_budget.pps_nomenclature_id%type
  )
  is
    v_pps               number;
    v_tas_record_id     gal_task.doc_record_id%type;
    v_prj_record_id     gal_task.doc_record_id%type;
    v_bud_record_id     gal_task.doc_record_id%type;
    v_gal_task_good_id  gal_task_good.gal_task_good_id%type;
    v_pps_new_hea_id    pps_nomenclature.pps_nomenclature_id%type;
    v_pps_new_nom_id    pps_nomenclature.pps_nomenclature_id%type;
    v_gml_is_fixed      gal_task_good.gml_is_fixed%type;
    v_good_id           gal_task_good.gco_good_id%type;
    v_gco_good_prj_id   gal_project.gco_good_id%type;
    v_pps_prj_id        gal_project.pps_nomenclature_id%type;
    v_prj_id            gal_project.gal_project_id%type;
    v_qty_dir           gal_task_good.gml_quantity%type;
    x_qty_dir           gal_task_good.gml_quantity%type;
    v_gco_good_bud_id   gal_project.gco_good_id%type;
    v_pps_bud_id        gal_project.pps_nomenclature_id%type;
    v_bud_id            gal_project.gal_project_id%type;
    v_tas_id            gal_project.gal_project_id%type;
    v_gml_nom_version   pps_nomenclature.nom_version%type;
    v_pps_header_origin gal_project.pps_nomenclature_id%type;
    v_cpt_sequence      number;
    v_PPS_Com_Numbering number;

    cursor C_BUD_TASK_GOOD
    is
      select   GAL_TASK_GOOD.pps_nomenclature_id
             , GAL_TASK.doc_record_id
             , GAL_BUDGET.doc_record_id
             , gal_task_good_id
             , gml_is_fixed
             , GAL_TASK_GOOD.gco_good_id
             , GAL_TASK_GOOD.GML_QUANTITY
             , GAL_BUDGET.GCO_GOOD_ID
             , GAL_BUDGET.PPS_NOMENCLATURE_ID
             , GAL_BUDGET.GAL_BUDGET_ID
             , GAL_TASK_GOOD.GAL_TASK_ID
          from GAL_BUDGET
             , GAL_TASK_GOOD
             , GAL_TASK
         where GAL_BUDGET.GAL_BUDGET_ID = GAL_TASK.GAL_BUDGET_ID
           and GAL_TASK_GOOD.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
           --AND GAL_TASK_GOOD.PPS_NOMENCLATURE_ID IS NOT NULL
           and GAL_TASK.GAL_BUDGET_ID = a_Id
      --AND GAL_BUDGET.PPS_NOMENCLATURE_ID IS NOT NULL
      order by TAS_CODE
             , GML_SEQUENCE;
  begin
    v_cpt_sequence  := 0;

    select pps_nomenclature_id
      into v_pps_header_origin
      from gal_budget
     where gal_budget_id = a_Id;

    open c_bud_task_good;

    loop
      fetch c_bud_task_good
       into v_pps
          , v_tas_record_id
          , v_bud_record_id
          , v_gal_task_good_id
          , v_gml_is_fixed
          , v_good_id
          , v_qty_dir
          , v_gco_good_bud_id
          , v_pps_bud_id
          , v_bud_id
          , v_tas_id;

      exit when c_bud_task_good%notfound;
      v_cpt_sequence    := v_cpt_sequence + 1;
      v_pps_new_hea_id  := null;
      v_pps_new_nom_id  := null;

      if v_cpt_sequence = 1 then
        begin
          select PCS.PC_CONFIG.GETCONFIG('PPS_Com_Numbering')
            into v_PPS_Com_Numbering
            from dual;
        exception
          when no_data_found then
            v_PPS_Com_Numbering  := 1;
        end;
      end if;

      select sum(gml_quantity)
        into x_qty_dir   /*Qte cumulée*/
        from gal_task_good
       where gal_task_id = v_tas_id
         and (    (    pps_nomenclature_id = v_pps
                   and v_pps is not null)
              or (    gco_good_id = v_good_id
                  and v_pps is null) );

      if v_pps is not null then
        PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_NOMENCLATURE(v_pps
                                                      , v_tas_record_id
                                                      , null
                                                      , v_bud_record_id
                                                      , v_gco_good_bud_id
                                                      , v_pps_bud_id
                                                      , v_good_id
                                                      , v_PPS_Com_Numbering
                                                      , x_qty_dir
                                                      , v_pps_new_hea_id
                                                      , v_pps_new_nom_id
                                                       );

        if     v_pps_new_hea_id is not null
           and v_cpt_sequence = 1 then
          update gal_budget
             set pps_nomenclature_id = v_pps_new_hea_id
           where gal_budget_id = v_bud_id;

          if sql%found then
            out_warning  :=
                      rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Création de la nomenclature SAV') || ' PpsId>' || to_char(v_pps_new_hea_id)
                      || chr(10);
          end if;
        end if;

        --Avec doc_record_id de gal_task
        if v_pps_new_nom_id is not null then
          update gal_task_good
             set pps_nomenclature_id = v_pps_new_nom_id
               , gml_is_fixed = 1
           where gal_task_good_id = v_gal_task_good_id;

          if sql%found then
            out_warning  :=
              rtrim(out_warning) ||
              PCS.PC_FUNCTIONS.TranslateWord('Rattachement de la nomenclature SAV à la tâche') ||
              ' docId>' ||
              to_char(v_tas_record_id) ||
              chr(10);
          end if;
        end if;

        if     v_gml_is_fixed <> 1
           and v_pps_new_nom_id is null then
          begin
            select nom_version
              into v_gml_nom_version
              from pps_nomenclature
             where pps_nomenclature_id = v_pps;

            begin
              select pps_nomenclature_id
                into v_pps_new_nom_id
                from pps_nomenclature
               where gco_good_id = v_good_id
                 and (nvl(nom_version, ' ') ) =(nvl(v_gml_nom_version, ' ') )
                 and doc_record_id = v_tas_record_id
                 and rownum = 1;

              update gal_task_good
                 set pps_nomenclature_id = v_pps_new_nom_id
                   , gml_is_fixed = 1
               where gal_task_id = v_tas_id
                 and gco_good_id = v_good_id
                 and pps_nomenclature_id = v_pps
                 and gml_is_fixed <> 1;
            exception
              when no_data_found then
                null;
            end;
          exception
            when no_data_found then
              null;
          end;
        end if;
      end if;

      if v_pps is null then
        PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_HEADER(v_bud_record_id, v_pps_new_hea_id, v_gco_good_bud_id, v_pps_bud_id);
        PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_COMPONENT(v_pps_new_hea_id, v_good_id, null, v_PPS_Com_Numbering, x_qty_dir);

        if v_gml_is_fixed <> 1 then
          update gal_task_good
             set gml_is_fixed = 1
           where gal_task_good_id = v_gal_task_good_id;
        end if;
      end if;
    end loop;

    close c_bud_task_good;

    if v_pps_new_hea_id is not null then
      out_pps_id  := v_pps_new_hea_id;
    else
      out_pps_id  := v_pps_header_origin;
    end if;
  end generate_from_gal_budget;
begin
  null;
end gal_project_nomenclature;
