--------------------------------------------------------
--  DDL for Package Body GAL_MSP_PROJECT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_MSP_PROJECT" 
is
  procedure ctrlinfotaches(v_numaff gal_project.prj_code%type, v_numtache gal_task.tas_code%type, v_cursor in out type_cursor)
  is
  begin
    open v_cursor for
      select /*+ INDEX(GAL_TASK GAL_TASK_PK2) */
             c_tca_task_type
           , c_tas_state
           , bdg_code
           , tas_start_date
           , tas_end_date
        from gal_project
           , gal_task
           , gal_task_category
           , gal_budget
       where prj_code = v_numaff
         and gal_project.gal_project_id = gal_task.gal_project_id
         and tas_code = v_numtache
         and gal_task_category.gal_task_category_id = gal_task.gal_task_category_id
         and gal_task.gal_budget_id = gal_budget.gal_budget_id;
  end ctrlinfotaches;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure ctrlnumtachenondouble(
    v_numaff      in     gal_project.prj_code%type
  , v_numtache    in     gal_task.tas_code%type
  , v_typetache   in     gal_task_category.c_tca_task_type%type
  , v_numbertache out    number
  , firstpass     in     number
  )
  is
    v_internumbertache number;
  begin
    if firstpass = 1 then
      insert into gal_msp_ctrl_task
           values (v_numaff
                 , v_numtache
                 , v_typetache
                  );

      v_numbertache  := 1;
    else
      if    v_typetache = '2'
         or v_typetache = '3'
         or v_typetache = '2'
         or v_typetache = 'K' then   -- type K pas de correspondance avec une catégorie de tâche
        select /*+ INDEX(GAL_MSP_CTRL_TASK MSPGALOPCTRLNumTaches_Idx1) */
               count(tas_code)
          into v_numbertache
          from gal_msp_ctrl_task
         where prj_code = v_numaff
           and tas_code = v_numtache;
      elsif v_typetache = '1' then
        select /*+ INDEX(GAL_MSP_CTRL_TASK MSPGALOPCTRLNumTaches_Idx1) */
               count(tas_code)
          into v_numbertache
          from gal_msp_ctrl_task
         where prj_code = v_numaff
           and tas_code = v_numtache
           and c_tca_task_type <> 'F';
--          SELECT /*+ INDEX(GAL_MSP_CTRL_TASK MSPGALOPCTRLNumTaches_Idx1) */ COUNT(TAS_CODE) INTO v_InterNumberTache
--          FROM GAL_MSP_CTRL_TASK
--          WHERE PRJ_CODE = v_NumAff
--          AND   TAS_CODE = v_NumTache
--          AND   TAS_TASK_TYPE = 'F';

      --          IF v_NumberTache > 1 OR v_InterNumberTache > 1 THEN
--             v_NumberTache := 2;
--          END IF;

      --       ELSIF v_TypeTache = 'F' THEN
--          SELECT /*+ INDEX(GAL_MSP_CTRL_TASK,MSPGALOPCTRLNumTaches_Idx1) */ COUNT(TAS_CODE) INTO v_NumberTache
--          FROM GAL_MSP_CTRL_TASK
--          WHERE PRJ_CODE = v_NumAff
--          AND   TAS_CODE = v_NumTache
--          AND   TAS_TASK_TYPE <> 'A';

      --          SELECT /*+ INDEX(GAL_MSP_CTRL_TASK MSPGALOPCTRLNumTaches_Idx1) */ COUNT(TAS_CODE) INTO v_InterNumberTache
--          FROM GAL_MSP_CTRL_TASK
--          WHERE PRJ_CODE = v_NumAff
--          AND   TAS_CODE = v_NumTache
--          AND   TAS_TASK_TYPE = 'A';

      --          IF v_NumberTache > 1 OR v_InterNumberTache > 1 THEN
--             v_NumberTache := 2;
--          END IF;

      --       ELSIF v_TypeTache = 'Z' THEN
--          SELECT /*+ INDEX(GAL_MSP_CTRL_TASK MSPGALOPCTRLNumTaches_Idx1) */ COUNT(TAS_CODE) INTO v_NumberTache
--          FROM GAL_MSP_CTRL_TASK
--          WHERE PRJ_CODE = v_NumAff
--          AND   TAS_CODE = v_NumTache
--          AND   TAS_TASK_TYPE = 'A';
      end if;
    end if;
  end ctrlnumtachenondouble;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure deleteinfonumtachedouble(v_numaff in gal_project.prj_code%type)
  is
-- hmo todo change table
  begin
    delete      gal_msp_ctrl_task
          where prj_code = v_numaff;
  end deleteinfonumtachedouble;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure lieraffairemspgalop(v_numaff in gal_project.prj_code%type, v_localisation varchar2)
  is
  begin
    update gal_project
       set prj_msproject_location = v_localisation
     where prj_code = v_numaff;
  end lieraffairemspgalop;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  function searchcodeetat(v_numaff in gal_project.prj_code%type, v_numtache in gal_task.tas_code%type)
    return gal_task.c_tas_state%type
  is
    v_intercodeetat gal_task.c_tas_state%type;
  begin
    select /*+ INDEX(GAL_TASK GAL_TASK_PK2) */
           c_tas_state
      into v_intercodeetat
      from gal_task
         , gal_project
     where prj_code = v_numaff
       and tas_code = v_numtache
       and gal_task.gal_project_id = gal_project.gal_project_id;

    return v_intercodeetat;
  end searchcodeetat;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- FUNCTION DetMinMaxOfDate (v_Date1 NUMBER, v_Date2 NUMBER, v_Min BOOLEAN) RETURN DATE
-- IS
--    v_DateResult      DATE;
-- BEGIN
--
--    IF v_Date1 = 0 AND v_Date2 = 0 THEN
--       SELECT TRUNC(SYSDATE,'DD') INTO v_DateResult FROM DUAL;        -- on envoir une datze sans heure -> test dans 'interface
--       RETURN v_DateResult;
--    ELSE
--       IF v_Date1 = 0 THEN
--          v_DateResult := GAL_FUNCTIONS.DateGToDate (v_Date2);
--       ELSIF v_Date2 = 0 THEN
--          v_DateResult := GAL_FUNCTIONS.DateGToDate (v_Date1);
--       ELSE
--          IF v_Date1 < v_Date2 THEN
--             IF v_Min THEN
--                v_DateResult := GAL_FUNCTIONS.DateGToDate (v_Date1);
--             ELSE
--                v_DateResult := GAL_FUNCTIONS.DateGToDate (v_Date2);
--             END IF;
--          ELSE
--             IF v_Min THEN
--                v_DateResult := GAL_FUNCTIONS.DateGToDate (v_Date2);
--
--             ELSE
--                v_DateResult := GAL_FUNCTIONS.DateGToDate (v_Date1);
--             END IF;
--          END IF;
--       END IF;
--       IF v_Min THEN
--          RETURN v_DateResult +0.25;
--       ELSE
--          RETURN v_DateResult +0.75;
--       END IF;
--    END IF;
--
-- END DetMinMaxOfDate;

  -- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  function searchdatesolde(v_numaff in gal_project.prj_code%type, v_numtache in gal_task.tas_code%type)
    return date
  is
    v_interdate date;
  begin
    select /*+ INDEX(GAL_TASK GAL_TASK_PK2) */
           tas_balance_date
      into v_interdate
      from gal_task
         , gal_project
     where prj_code = v_numaff
       and tas_code = v_numtache
       and gal_project.gal_project_id = gal_task.gal_project_id;

    if v_interdate is null then
      select /*+ INDEX(GAL_TASK GAL_TASK_PK2) */
             tas_end_date
        into v_interdate
        from gal_task
           , gal_project
       where prj_code = v_numaff
         and tas_code = v_numtache
         and gal_project.gal_project_id = gal_task.gal_project_id;
    end if;

    return(v_interdate + 0.75);
  end searchdatesolde;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure searchinfotachesa(
    v_numaff    in     gal_project.prj_code%type
  , v_numtache  in     gal_task.tas_code%type
  , v_datemin   out    date
  , v_datemax   out    date
  , v_datesolde out    date
  , v_codeetat  out    gal_task.c_tas_state%type
  )
  is
    v_interdate          date;
    v_interdate1         date;
    v_interdatemax       date;
    a_task_doc_record_id number;
  begin
    v_codeetat  := searchcodeetat(v_numaff, v_numtache);

    if v_codeetat = '20' then
      select /*+ INDEX(GAL_TASK GAL_TASK_PK2) */
             tas_launching_date
        into v_interdate
        from gal_task
           , gal_project
       where prj_code = v_numaff
         and tas_code = v_numtache
         and gal_project.gal_project_id = gal_task.gal_project_id;

      if v_interdate is null then
        select /*+ INDEX(GAL_TASK GAL_TASK_PK2) */
               tas_start_date
          into v_interdate
          from gal_task
             , gal_project
         where prj_code = v_numaff
           and tas_code = v_numtache
           and gal_project.gal_project_id = gal_task.gal_project_id;
      end if;

      v_datemin  := v_interdate + 0.25;
    end if;

    if v_codeetat > '20' then
      select /*+ INDEX(GAL_TASK GAL_TASK_PK2) */
             tas_launching_date
        into v_interdate
        from gal_task
           , gal_project
       where prj_code = v_numaff
         and tas_code = v_numtache
         and gal_project.gal_project_id = gal_task.gal_project_id;

      select /*+ INDEX(GAL_TASK GAL_TASK_PK2) */
             tas_actual_start_date
        into v_interdate1
        from gal_task
           , gal_project
       where prj_code = v_numaff
         and tas_code = v_numtache
         and gal_project.gal_project_id = gal_task.gal_project_id;

      if     v_interdate is null
         and v_interdate1 is null then
        select /*+ INDEX(GAL_TASK GAL_TASK_PK2) */
               tas_start_date
          into v_interdate
          from gal_task
             , gal_project
         where prj_code = v_numaff
           and tas_code = v_numtache
           and gal_project.gal_project_id = gal_task.gal_project_id;
      else
        if v_interdate is null then
          v_interdate  := v_interdate1;
        end if;

        if not v_interdate1 is null then
          if v_interdate1 > v_interdate then
            v_interdate  := v_interdate1;
          end if;
        end if;
      end if;

      v_datemin  := v_interdate + 0.25;

      if v_codeetat = '40' then
        v_datesolde  := searchdatesolde(v_numaff, v_numtache);
      end if;

      select gal_task.doc_record_id
        into a_task_doc_record_id
        from gal_task
           , gal_project
       where prj_code = v_numaff
         and tas_code = v_numtache
         and gal_project.gal_project_id = gal_task.gal_project_id;

      select max(datum)
        into v_interdate
        from (
--****** APPROS sur Commandes fournisseur --*********************************
              select pde_final_delay datum
                from pac_person
                   , gco_good
                   , doc_position_detail
                   , doc_position
                   , doc_document
                   , doc_gauge_structured
                   , doc_gauge
               where pac_person.pac_person_id(+) = doc_document.pac_third_id
                 and gco_good.gco_good_id = doc_position_detail.gco_good_id
                 and doc_position_detail.pde_balance_quantity <> 0
                 and doc_position_detail.doc_position_id = doc_position.doc_position_id
                 and doc_position.doc_document_id = doc_document.doc_document_id
                 and doc_gauge_structured.dic_project_consol_1_id = '1'
                 --gabarit configuré appro (appro affaire)
                 and doc_gauge_structured.doc_gauge_id(+) = doc_gauge.doc_gauge_id
                 and doc_gauge.c_admin_domain <> '3'
                 --sauf gabarit domaine stock
                 and doc_gauge.doc_gauge_id = doc_document.doc_gauge_id
                 and (   doc_position.doc_record_id = a_task_doc_record_id
                      or doc_document.doc_record_id = a_task_doc_record_id)
--position prend le dessus mais peut etre vide alors doc_record_id de doc_document (et multi doc_record_id sur les position....)
                 and c_doc_pos_status <> '05'
              --non selection des doc. annulés
              union all
--****** DISPO sur Commandes fournisseur --*********************************
              select pde_final_delay datum
                from pac_person
                   , gco_good
                   , doc_position_detail
                   , doc_position
                   , doc_document
                   , doc_gauge_structured
                   , doc_gauge
               where pac_person.pac_person_id(+) = doc_document.pac_third_id
                 and gco_good.gco_good_id = doc_position_detail.gco_good_id
                 and doc_position_detail.pde_final_quantity <> 0
                 and doc_position_detail.doc_position_id = doc_position.doc_position_id
                 and doc_position.doc_document_id = doc_document.doc_document_id
                 and doc_gauge_structured.dic_project_consol_1_id = '2'
                 --gabarit configuré dipso (dispo affaire)
                 and doc_gauge_structured.doc_gauge_id(+) = doc_gauge.doc_gauge_id
                 and doc_gauge.c_admin_domain <> '3'
                 --sauf gabarit domaine stock
                 and doc_gauge.doc_gauge_id = doc_document.doc_gauge_id
                 and (   doc_position.doc_record_id = a_task_doc_record_id
                      or doc_document.doc_record_id = a_task_doc_record_id)
--position prend le dessus mais peut etre vide alors doc_record_id de doc_document (et multi doc_record_id sur les position....)
                 and c_doc_pos_status <> '05'
                                             --non selection des doc. annulés
             );

      if v_interdate is null then
        select tas_end_date
          into v_interdate
          from gal_task
             , gal_project
         where prj_code = v_numaff
           and tas_code = v_numtache
           and gal_project.gal_project_id = gal_task.gal_project_id;
      end if;

      v_datemax  := v_interdatemax + 0.75;
    end if;
  end searchinfotachesa;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure searchinfoh(
    v_numaff               gal_project.prj_code%type
  , v_numtache             gal_task.tas_code%type
  , v_typeheure     in     number
  , v_typeressource in     varchar2
  , v_cursor        in out type_cursor
  )
  is
  begin
-- sans affectation / GAL_HOURS sur GAL_TASK
    if v_typeheure = 1 then
      open v_cursor for
        select   /*+ INDEX(GAL_HOURS GAL_HOURS_S_TASK_FK) */
                 round(sum(hou_worked_time), 0) * 60 nbrheure
               , hou_pointing_date datesais
            from gal_project
               , gal_task
               , gal_hours
           where prj_code = v_numaff
             and tas_code = v_numtache
             and gal_project.gal_project_id = gal_task.gal_project_id
             and gal_hours.gal_task_id = gal_task.gal_task_id
        group by hou_pointing_date
        order by hou_pointing_date;
-- affectation = Centre de Charge / GAL_HOURS sur GAL_TASK

    -- ELSIF v_TypeHeure = 2 THEN

    /*
         OPEN v_Cursor FOR
            SELECT ROUND(SUM(Tps),0)*60 NbrHeure, DateP DateSais
            FROM  ((
                  SELECT HOU_WORKED_TIME Tps, HOU_POINTING_DATE DateP
                   FROM GAL_PROJECT,GAL_TASK, GAL_OPERATION, GAL_HOURS
                   WHERE   PRJ_CODE = v_NumAff
                   AND  TAS_CODE = v_NumTache
                   AND  GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
                   AND  GAL_HOURS.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
                   AND  GAL_OPERATION.GAL_OPERATION_ID = GAL_HOURS.GAL_OPERATION_ID
                  AND   GAL_OPERATION.GAL_CHARGE_POST_ID
                  IN
                  (  SELECT   GAL_CHARGE_POST.GAL_CHARGE_POST_ID FROM GAL_CHARGE_POST, GAL_CHARGE_CENTER
                     WHERE GAL_CHARGE_POST.GAL_CHARGE_CENTER_ID = GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
                        AND   GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
                  ))
                  UNION
                  (
                  SELECT HOU_WORKED_TIME Tps, HOU_POINTING_DATE DateP
                  FROM GAL_PROJECT,GAL_TASK, GAL_OPERATION, GAL_HOURS
                  WHERE PRJ_CODE = v_NumAff
                  AND   TAS_CODE = v_NumTache
                  AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
                  AND   GAL_HOURS.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
                  AND GAL_OPERATION.GAL_OPERATION_ID = GAL_HOURS.GAL_OPERATION_ID
                  AND GAL_OPERATION.GAL_CHARGE_CENTER_ID
                  IN
                  (
                     SELECT   GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
                     FROM  GAL_CHARGE_CENTER
                     WHERE GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
                  )
                  )
               )
            GROUP BY
               DateP
            ORDER BY
               DateP;
*/
-- Affectation = Poste de charge / GAL_HOURS sur GAL_TASK
    elsif v_typeheure = 3 then
      open v_cursor for
        select   round(sum(tps), 0) * 60 nbrheure
               , datep datesais
            from (select hou_worked_time tps
                       , hou_pointing_date datep
                    from gal_project
                       , gal_task
                       , gal_hours
                       , gal_task_link
                       , fal_factory_floor
                   where prj_code = v_numaff
                     and tas_code = v_numtache
                     and gal_project.gal_project_id = gal_task.gal_project_id
                     and gal_task.gal_task_id = gal_task_link.gal_task_id
                     and gal_task_link.gal_task_link_id = gal_hours.gal_task_link_id
                     and gal_task_link.fal_factory_floor_id = fal_factory_floor.fal_factory_floor_id
                     and upper(fal_factory_floor.fac_reference) = upper(v_typeressource) )
        group by datep
        order by datep;
-- sans affectation / GAL_HOURS sur OF

    --    ELSIF v_TypeHeure = 4 THEN
   --    OPEN v_Cursor FOR
      --    SELECT ROUND(SUM (NbrHeure),-2)*6/10, DateSais FROM(
         --    SELECT /*+INDEX(Affectation CLE2_Affectation INDEX(GAL_HOURS CLE2_Heures)  INDEX(Orfab CLE_orfab)*/
            -- (HOU_WORKED_TIME + TPS_Passe_Prepa)*(Affectation.Afc_Qte_Affectee/DECODE(orfab.qte_lancee,0,Affectation.Afc_Qte_Affectee,orfab.qte_lancee)) NbrHeure, HOU_POINTING_DATE Datesais
               --FROM GAL_HOURS, Affectation, Orfab
--             WHERE Affectation.Afc_Type_Lancement = 'F'
   --          AND   Affectation.PRJ_CODE = v_NumAff
      --       AND   Affectation.TAS_CODE = v_NumTache
         --    AND   Orfab.No_Of = Affectation.Afc_No_Lancement
            -- AND   GAL_HOURS.Heu_Type_Lancement = 'F'
               --AND GAL_HOURS.Heu_No_Lanc1 = Affectation.Afc_No_Lancement)
--          GROUP BY
   --          DateSais
      --    ORDER BY
         --    DateSais;

    --  affectation sur Centre de Charge / GAL_HOURS sur OF

    --    ELSIF v_TypeHeure = 5 THEN
   --    OPEN v_Cursor FOR
      --    SELECT ROUND(SUM (NbrHeure),-2)*6/10, DateSais FROM(
         --    SELECT /*+INDEX(Affectation CLE2_Affectation INDEX(GAL_HOURS CLE2_Heures)  INDEX(Orfab CLE_orfab)*/
            -- (HOU_WORKED_TIME + TPS_Passe_Prepa)*(Affectation.Afc_Qte_Affectee/DECODE(orfab.qte_lancee,0,Affectation.Afc_Qte_Affectee,orfab.qte_lancee)) NbrHeure, HOU_POINTING_DATE Datesais
               --FROM GAL_HOURS, Affectation, GAL_OPERATION, Orfab
--             WHERE Affectation.Afc_Type_Lancement = 'F'
   ---            AND   Affectation.PRJ_CODE = v_NumAff
      --       AND   Affectation.TAS_CODE = v_NumTache
         --    AND   Orfab.No_Of = Affectation.Afc_No_Lancement
            -- AND   GAL_OPERATION.Ope_Type_Lancement = 'F'
               --AND GAL_OPERATION.Ope_Poste_Charge
                  --IN  (SELECT GCH_CODE
                     --FROM GAL_CHARGE_POST
--                   WHERE    Code_Centre_Charge =  v_TypeRessource)
   --          AND   GAL_OPERATION.Ope_No_Lanc1 = Affectation.Afc_No_Lancement
      --       AND   GAL_HOURS.Heu_Type_Lancement = 'F'
         --    AND   GAL_HOURS.Heu_No_Lanc1 = Affectation.Afc_No_Lancement
            -- AND   GAL_HOURS.OPE_CODE = GAL_OPERATION.OPE_CODE)
--       GROUP BY
   --       DateSais
      -- ORDER BY
         -- DateSais;

    --  affectation sur poste de charge / GAL_HOURS sur OF

    --    ELSIF v_TypeHeure = 6 THEN
   --    OPEN v_Cursor FOR
      --    SELECT ROUND(SUM (NbrHeure),-2)*6/10, DateSais FROM(
         --    SELECT /*+INDEX(Affectation CLE2_Affectation INDEX(GAL_HOURS CLE2_Heures)  INDEX(Orfab CLE_orfab)*/
            -- (HOU_WORKED_TIME + TPS_Passe_Prepa)*(Affectation.Afc_Qte_Affectee/DECODE(orfab.qte_lancee,0,Affectation.Afc_Qte_Affectee,orfab.qte_lancee)) NbrHeure, HOU_POINTING_DATE Datesais
               --FROM GAL_HOURS, Affectation, GAL_OPERATION, Orfab
--             WHERE Affectation.Afc_Type_Lancement = 'F'
   ---            AND   Affectation.PRJ_CODE = v_NumAff
      --       AND   Affectation.TAS_CODE = v_NumTache
         --    AND   Orfab.No_Of = Affectation.Afc_No_Lancement
            -- AND   GAL_OPERATION.Ope_Type_Lancement = 'F'
               --AND GAL_OPERATION.Ope_Poste_Charge = v_TypeRessource
--             AND   GAL_OPERATION.Ope_No_Lanc1 = Affectation.Afc_No_Lancement
   --          AND   GAL_HOURS.Heu_Type_Lancement = 'F'
      --       AND   GAL_HOURS.Heu_No_Lanc1 = Affectation.Afc_No_Lancement
         --    AND   GAL_HOURS.OPE_CODE = GAL_OPERATION.OPE_CODE)
--       GROUP BY
   --       DateSais
      -- ORDER BY
         -- DateSais;
    end if;
  end searchinfoh;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure searchinfotacheemf(
    v_numaff                gal_project.prj_code%type
  , v_numtache              gal_task.tas_code%type
  , v_nbreop         out    number
  , v_codeetat       out    gal_task.c_tas_state%type
  , v_nbrehreste     out    number
  , v_datemin        out    date
  , v_datemax        out    date
  , v_datesolde      out    date
  , v_typeheure      in     number
  , v_nbrehdonereel  out    number
  , v_resnotdeclared out    number
  )
  is
    v_interdate   date;
    v_interdate1  date;
    v_internumber number;
  begin
    v_codeetat  := searchcodeetat(v_numaff, v_numtache);

    if v_codeetat = 40 then
      v_datesolde  := searchdatesolde(v_numaff, v_numtache);
    end if;

    if v_typeheure < 4 then
      select /*+ INDEX(GAL_HOURS GAL_HOURS_S_TASK_FK) */
             nvl(sum(hou_worked_time), 0)
        into v_internumber
        from gal_project
           , gal_task
           , gal_hours
       where prj_code = v_numaff
         and tas_code = v_numtache
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_hours.gal_task_id = gal_task.gal_task_id;

      v_nbrehdonereel  := v_internumber * 60;

--       SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */
   --    NVL(COUNT(Ope_Poste_Charge),0) INTO v_InterNumber
      -- FROM GAL_PROJECT, GAL_TASK, GAL_OPERATION
         --WHERE  Ope_No_Lanc2 = v_NumTache
--       AND   Ope_No_Lanc1 = v_NumAff
   --    AND   Ope_Type_Lancement = 'A'
      -- AND   Ope_Poste_Charge = ' ';

      --       SELECT /*+ INDEX(GAL_HOURS CLE2_Heures) */
   --    NVL(COUNT(EMP_CODE),0) INTO  v_ResNotDeclared
      -- FROM GAL_HOURS
         --WHERE  Heu_No_Lanc2 = v_NumTache
--       AND   Heu_No_Lanc1 = v_NumAff
   --    AND   OPE_CODE = 0
      -- AND   Heu_Type_Lancement = 'A'
         --AND    EMP_CODE
            --IN  (SELECT EMP_CODE
               --FROM GAL_EMPLOYEE
               --WHERE  GCH_CODE =  ' ');

      --v_ResNotDeclared := v_ResNotDeclared + v_InterNumber;

      --       SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */
   --    NVL(COUNT(Ope_Poste_Charge),0) INTO v_InterNumber
      -- FROM GAL_OPERATION
         --WHERE  Ope_No_Lanc2 = v_NumTache
--       AND   Ope_No_Lanc1 = v_NumAff
   --    AND   Ope_Type_Lancement = 'A'
      -- AND   Ope_Poste_Charge
         -- IN (SELECT GCH_CODE
            -- FROM GAL_CHARGE_POST
               --WHERE  Code_Centre_Charge =  ' ');

      --       v_ResNotDeclared := v_ResNotDeclared + v_InterNumber;
      select /*+ INDEX(GAL_OPERATION PK_GAL_OPERATION) */
             nvl(count(gal_task_link_id), 0)
        into v_nbreop
        from gal_project
           , gal_task
           , gal_task_link
       where tas_code = v_numtache
         and prj_code = v_numaff
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_task_link.gal_task_id = gal_task.gal_task_id;

      select /*+ INDEX(GAL_OPERATION PK_GAL_OPERATION) */
             nvl(round(sum(tal_tsk_balance), 0), 0) * 60
        into v_nbrehreste
        from gal_project
           , gal_task
           , gal_task_link
       where tas_code = v_numtache
         and prj_code = v_numaff
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_task_link.gal_task_id = gal_task.gal_task_id;

      select /*+ INDEX(GAL_HOURS GAL_HOURS_S_TASK_FK) */
             min(hou_pointing_date)
        into v_datemin
        from gal_project
           , gal_task
           , gal_hours
       where tas_code = v_numtache
         and prj_code = v_numaff
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_hours.gal_task_id = gal_task.gal_task_id;

      v_datemin        := v_datemin + 0.25;

--       SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */
--       NVL(MIN(Date_Debut_Tot),0) INTO v_InterDate1
   --    FROM GAL_PROJECT, GAL_TASK, GAL_HOURS
      -- WHERE    TAS_CODE = v_NumTache
         --AND    PRJ_CODE = v_NumAff
--       AND      GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
   --    AND      GAL_HOURS.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID ;

      --       v_DateMin := DetMinMaxOfDate (v_InterDate, v_InterDate1, TRUE);
      select /*+ INDEX(GAL_HOURS GAL_HOURS_S_TASK_FK) */
             max(hou_pointing_date)
        into v_datemax
        from gal_project
           , gal_task
           , gal_hours
       where tas_code = v_numtache
         and prj_code = v_numaff
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_hours.gal_task_id = gal_task.gal_task_id;

      v_datemax        := v_datemax + 0.75;
--       SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */
   --    NVL(MAX(Date_Fin_Tard),0) INTO v_InterDate1
      -- FROM GAL_OPERATION
         --WHERE  Ope_No_Lanc2 = v_NumTache
--       AND   Ope_No_Lanc1 = v_NumAff
   --    AND   Ope_Type_Lancement = 'A';

    --       v_DateMax := DetMinMaxOfDate (v_InterDate, v_InterDate1, FALSE);

    --    ELSE
   --    SELECT /*+INDEX(Affectation CLE2_Affectation) INDEX(GAL_HOURS CLE2_Heures)  INDEX(Orfab CLE_orfab)*/
      -- NVL(SUM((HOU_WORKED_TIME + TPS_Passe_Prepa)*(Affectation.Afc_Qte_Affectee/DECODE(orfab.qte_lancee,0,Affectation.Afc_Qte_Affectee,orfab.qte_lancee))),0)  INTO v_InterNumber
         --FROM GAL_HOURS, Affectation, Orfab
--       WHERE Affectation.Afc_Type_Lancement = 'F'
   --    AND   Affectation.PRJ_CODE = v_NumAff
      -- AND   Affectation.TAS_CODE = v_NumTache
         --AND    Orfab.No_Of = Affectation.Afc_No_Lancement
--       AND   GAL_HOURS.Heu_Type_Lancement = 'F'
   --    AND   GAL_HOURS.Heu_No_Lanc1 = Affectation.Afc_No_Lancement;
--
   --    v_NbreHDoneReel := v_InterNumber*6/10;
--
   --    SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */ NVL(COUNT(Ope_Poste_Charge),0) INTO v_ResNotDeclared
      -- FROM GAL_OPERATION
         --WHERE  Ope_Type_Lancement = 'F'
--       AND   Ope_Poste_Charge
   --       IN (SELECT GCH_CODE
      --       FROM GAL_CHARGE_POST
         --    WHERE    Code_Centre_Charge =  ' ')
--       AND   Ope_No_Lanc1
   --       IN    (SELECT /*+ INDEX(Affectation CLE2_Affectation) */ Afc_No_Lancement
      --       FROM Affectation
         --    WHERE Afc_Type_Lancement = 'F'
            -- AND   PRJ_CODE = v_NumAff
               --AND TAS_CODE = v_NumTache);

    --       SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */ NVL(COUNT(Ope_Type_Lancement),0) INTO v_NbreOp
   --    FROM GAL_OPERATION
      -- WHERE Ope_Type_Lancement = 'F'
         --AND Ope_No_Lanc1
--          IN    (SELECT /*+ INDEX(Affectation CLE2_Affectation) */ Afc_No_Lancement
   --          FROM Affectation
      --       WHERE Afc_Type_Lancement = 'F'
         --    AND   PRJ_CODE = v_NumAff
            -- AND   TAS_CODE = v_NumTache);

    --       SELECT /*+INDEX(Affectation CLE2_Affectation INDEX(Orfab CLE_orfab)*/
   --    NVL(ROUND(SUM((OPE_REMAINING_CHARGE)*(Affectation.Afc_Qte_Affectee/DECODE(orfab.qte_lancee,0,Affectation.Afc_Qte_Affectee,orfab.qte_lancee))),-2),0)*6/10 INTO v_NbreHReste
      -- FROM  Affectation, GAL_OPERATION, Orfab
         --WHERE  Affectation.Afc_Type_Lancement = 'F'
--       AND   Affectation.PRJ_CODE = v_NumAff
   --    AND   Affectation.TAS_CODE = v_NumTache
      -- AND   Orfab.No_Of = Affectation.Afc_No_Lancement
         --AND GAL_OPERATION.Ope_Type_Lancement = 'F'
--       AND   GAL_OPERATION.Ope_No_Lanc1 = Affectation.Afc_No_Lancement;

    --    SELECT /*+ INDEX(GAL_HOURS CLE2_Heures) */ NVL(MIN (HOU_POINTING_DATE),0) INTO v_InterDate
      -- FROM GAL_HOURS
         --WHERE  Heu_Type_Lancement = 'F'
--       AND   Heu_No_Lanc1
   --       IN    (SELECT /*+ INDEX(Affectation CLE2_Affectation) */ Afc_No_Lancement
      --       FROM Affectation
         --    WHERE Afc_Type_Lancement = 'F'
            -- AND   PRJ_CODE = v_NumAff
               --AND TAS_CODE = v_NumTache);

    --       SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */ NVL(MIN(Date_Debut_Tot),0) INTO v_InterDate1
   --    FROM GAL_OPERATION
      -- WHERE Ope_Type_Lancement = 'F'
         --AND Ope_No_Lanc1
            --IN  (SELECT /*+ INDEX(Affectation CLE2_Affectation) */ Afc_No_Lancement
--             FROM Affectation
   --          WHERE Afc_Type_Lancement = 'F'
      --       AND   PRJ_CODE = v_NumAff
         --    AND   TAS_CODE = v_NumTache);

    --       v_DateMin := DetMinMaxOfDate (v_InterDate, v_InterDate1, TRUE);
--
   --    SELECT /*+ INDEX(GAL_HOURS CLE2_Heures) */ NVL(MAX(HOU_POINTING_DATE),0) INTO v_InterDate
      -- FROM GAL_HOURS
         --WHERE  Heu_Type_Lancement = 'F'
--       AND   Heu_No_Lanc1
   --       IN    (SELECT /*+ INDEX(Affectation CLE2_Affectation) */ Afc_No_Lancement
      --       FROM Affectation
         --    WHERE Afc_Type_Lancement = 'F'
            -- AND   PRJ_CODE = v_NumAff
               --AND TAS_CODE = v_NumTache);

    --       SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */ NVL(MAX(Date_Fin_Tard),0) INTO v_InterDate1
   --    FROM GAL_OPERATION
      -- WHERE Ope_Type_Lancement = 'F'
         --AND Ope_No_Lanc1
            --IN  (SELECT /*+ INDEX(Affectation CLE2_Affectation) */ Afc_No_Lancement
               --FROM Affectation
--             WHERE Afc_Type_Lancement = 'F'
   --          AND   PRJ_CODE = v_NumAff
      --       AND   TAS_CODE = v_NumTache);
--
   --    v_DateMax := DetMinMaxOfDate (v_InterDate, v_InterDate1, FALSE);
    end if;
  end searchinfotacheemf;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure searchinfohpourass(
    v_numaff               gal_project.prj_code%type
  , v_numtache             gal_task.tas_code%type
  , v_nbreop        out    number
  , v_nbrehreste    out    number
  , v_typeheure     in     number
  , v_typeressource in     varchar2
  , v_datemax       out    date
  , v_nbrehdonereel out    number
  )
  is
    v_internbreheure  number;
    v_internbreheure1 number;
    v_interdate       date;
    v_interdate1      date;
  begin
/*
-- affectation = Centre de Charge / GAL_HOURS sur GAL_TASK

      IF v_Typeheure = 2 THEN

         SELECT
         NVL(SUM(HOU_WORKED_TIME),0) INTO v_InterNbreHeure
         FROM GAL_PROJECT, GAL_TASK, GAL_HOURS, GAL_TASK_LINK
         WHERE TAS_CODE = v_NumTache
         AND   PRJ_CODE = v_NumAff
         AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
         AND   GAL_TASK_LINK.GAL_TASK_ID = GAL_TASK_LINK.GAL_TASK_ID
         AND   GAL_HOURS.GAL_TASK_LINK_ID = GAL_TASK_LINK.GAL_TASK_LINK_ID
         AND   GAL_TASK_LINK.GAL_TASK_LINK_ID
            IN
            (  SELECT   GAL_CHARGE_POST.GAL_CHARGE_POST_ID FROM GAL_CHARGE_POST, GAL_CHARGE_CENTER
               WHERE GAL_CHARGE_POST.GAL_CHARGE_CENTER_ID = GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
                  AND   GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
            );

         SELECT
         NVL(SUM(HOU_WORKED_TIME),0) INTO v_InterNbreHeure1
         FROM GAL_PROJECT, GAL_TASK, GAL_HOURS, GAL_OPERATION
         WHERE TAS_CODE = v_NumTache
         AND   PRJ_CODE = v_NumAff
         AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
         AND   GAL_OPERATION.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
         AND   GAL_HOURS.GAL_OPERATION_ID = GAL_OPERATION.GAL_OPERATION_ID
         AND GAL_OPERATION.GAL_CHARGE_CENTER_ID
         IN
         (
          SELECT  GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
          FROM GAL_CHARGE_CENTER
          WHERE   GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
         );

         v_NbreHDoneReel := (v_InterNbreHeure+v_InterNbreHeure1)*60;

         SELECT
         NVL(COUNT(GAL_OPERATION_ID),0) INTO v_InterNbreHeure
         FROM GAL_PROJECT, GAL_TASK,GAL_OPERATION
         WHERE TAS_CODE = v_NumTache
         AND   PRJ_CODE = v_NumAff
         AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
         AND   GAL_OPERATION.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
         AND   GAL_OPERATION.GAL_CHARGE_POST_ID
            IN
            (  SELECT   GAL_CHARGE_POST.GAL_CHARGE_POST_ID FROM GAL_CHARGE_POST, GAL_CHARGE_CENTER
               WHERE GAL_CHARGE_POST.GAL_CHARGE_CENTER_ID = GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
                  AND   GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
            );

         SELECT
         NVL(COUNT(GAL_OPERATION_ID),0) INTO v_InterNbreHeure1
         FROM GAL_PROJECT, GAL_TASK,GAL_OPERATION
         WHERE TAS_CODE = v_NumTache
         AND   PRJ_CODE = v_NumAff
         AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
         AND   GAL_OPERATION.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
         AND GAL_OPERATION.GAL_CHARGE_CENTER_ID
         IN
         (
          SELECT  GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
          FROM GAL_CHARGE_CENTER
          WHERE   GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
         );

         v_NbreOp := v_InterNbreHeure+v_InterNbreHeure1;

         SELECT
         NVL(ROUND(SUM(OPE_REMAINING_CHARGE),0),0)*60 INTO v_InterNbreHeure
         FROM GAL_PROJECT, GAL_TASK,GAL_OPERATION
         WHERE TAS_CODE = v_NumTache
         AND   PRJ_CODE = v_NumAff
         AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
         AND   GAL_OPERATION.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
         AND   GAL_OPERATION.GAL_CHARGE_POST_ID
            IN
            (  SELECT   GAL_CHARGE_POST.GAL_CHARGE_POST_ID FROM GAL_CHARGE_POST, GAL_CHARGE_CENTER
               WHERE GAL_CHARGE_POST.GAL_CHARGE_CENTER_ID = GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
                  AND   GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
            );


         SELECT
                  NVL(ROUND(SUM(OPE_REMAINING_CHARGE),0),0)*60 INTO v_InterNbreHeure1
         FROM GAL_PROJECT, GAL_TASK,GAL_OPERATION
         WHERE TAS_CODE = v_NumTache
         AND   PRJ_CODE = v_NumAff
         AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
         AND   GAL_OPERATION.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
         AND GAL_OPERATION.GAL_CHARGE_CENTER_ID
         IN
         (
          SELECT  GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
          FROM GAL_CHARGE_CENTER
          WHERE   GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
         );

         v_NbreHReste := v_InterNbreHeure+v_InterNbreHeure1;


         SELECT
         MAX(HOU_POINTING_DATE) INTO v_InterDate1
         FROM GAL_PROJECT, GAL_TASK, GAL_HOURS, GAL_OPERATION
         WHERE TAS_CODE = v_NumTache
         AND   PRJ_CODE = v_NumAff
         AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
         AND   GAL_OPERATION.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
         AND   GAL_HOURS.GAL_OPERATION_ID = GAL_OPERATION.GAL_OPERATION_ID
         AND   GAL_OPERATION.GAL_CHARGE_POST_ID
            IN
            (  SELECT   GAL_CHARGE_POST.GAL_CHARGE_POST_ID FROM GAL_CHARGE_POST, GAL_CHARGE_CENTER
               WHERE GAL_CHARGE_POST.GAL_CHARGE_CENTER_ID = GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
                  AND   GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
            );

         SELECT
         MAX(HOU_POINTING_DATE) INTO v_InterDate
         FROM GAL_PROJECT, GAL_TASK, GAL_HOURS, GAL_OPERATION
         WHERE TAS_CODE = v_NumTache
         AND   PRJ_CODE = v_NumAff
         AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
         AND   GAL_OPERATION.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
         AND   GAL_HOURS.GAL_OPERATION_ID = GAL_OPERATION.GAL_OPERATION_ID
         AND GAL_OPERATION.GAL_CHARGE_CENTER_ID
         IN
         (
          SELECT  GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID
          FROM GAL_CHARGE_CENTER
          WHERE   GAL_CHARGE_CENTER.CEN_CODE = v_TypeRessource
         );

         IF v_InterDate1 IS NULL OR v_InterDate IS NULL THEN
            IF v_InterDate1 IS NULL THEN
                 v_DateMax := v_InterDate+0.75;
            END IF;
            IF v_InterDate IS NULL THEN
                 v_DateMax := v_InterDate1+0.75;
            END IF;
         ELSE
            IF v_InterDate1 < v_InterDate THEN
                  v_DateMax := v_InterDate+0.75;
            ELSE
               v_DateMax := v_InterDate1+0.75;
            END IF;
         END IF;
*/
-- Affectation = Poste de charge / GAL_HOURS sur GAL_TASK
    if v_typeheure = 3 then
      select /*+ INDEX(GAL_HOURS GAL_HOURS_S_TASK_FK)*/
             nvl(sum(hou_worked_time), 0)
        into v_internbreheure
        from gal_project
           , gal_task
           , gal_hours
           , gal_task_link
           , fal_factory_floor
       where tas_code = v_numtache
         and prj_code = v_numaff
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_task_link.gal_task_id = gal_task.gal_task_id
         and gal_hours.gal_task_link_id = gal_task_link.gal_task_link_id
         and gal_task_link.fal_factory_floor_id = fal_factory_floor.fal_factory_floor_id
         and upper(fal_factory_floor.fac_reference) = upper(v_typeressource);

      v_nbrehdonereel  := v_internbreheure * 60;

      select /*+ INDEX(GAL_OPERATION PK_GAL_OPERATION) */
             nvl(count(gal_task_link_id), 0)
        into v_nbreop
        from gal_project
           , gal_task
           , gal_task_link
           , fal_factory_floor
       where tas_code = v_numtache
         and prj_code = v_numaff
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_task_link.gal_task_id = gal_task.gal_task_id
         and gal_task_link.fal_factory_floor_id = fal_factory_floor.fal_factory_floor_id
         and upper(fal_factory_floor.fac_reference) = upper(v_typeressource);

      select /*+ INDEX(GAL_OPERATION PK_GAL_OPERATION) */
             nvl(round(sum(gal_task_link.tal_tsk_balance), 0), 0) * 60
        into v_nbrehreste
        from gal_project
           , gal_task
           , gal_task_link
           , fal_factory_floor
       where tas_code = v_numtache
         and prj_code = v_numaff
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_task_link.gal_task_id = gal_task.gal_task_id
         and gal_task_link.fal_factory_floor_id = fal_factory_floor.fal_factory_floor_id
         and upper(fal_factory_floor.fac_reference) = upper(v_typeressource);

      select /*+ INDEX(GAL_HOURS GAL_HOURS_S_TASK_FK)*/
             max(hou_pointing_date)
        into v_interdate1
        from gal_project
           , gal_task
           , gal_hours
           , gal_task_link
           , fal_factory_floor
       where tas_code = v_numtache
         and prj_code = v_numaff
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_task_link.gal_task_id = gal_task.gal_task_id
         and gal_hours.gal_task_link_id = gal_task_link.gal_task_link_id
         and gal_task_link.fal_factory_floor_id = fal_factory_floor.fal_factory_floor_id
         and upper(fal_factory_floor.fac_reference) = upper(v_typeressource);

      v_datemax        := v_interdate1 + 0.75;
-- Affectation = Centre de Charge/ GAL_HOURS sur OF

    --    ELSIF v_Typeheure = 5 THEN
--
   --    SELECT /*+INDEX(Affectation CLE2_Affectation) INDEX(GAL_HOURS CLE2_Heures)  INDEX(Orfab CLE_orfab)*/
      -- NVL(SUM ((HOU_WORKED_TIME + TPS_Passe_Prepa)*(Affectation.Afc_Qte_Affectee/DECODE(orfab.qte_lancee,0,Affectation.Afc_Qte_Affectee,orfab.qte_lancee))),0) INTO v_InterNumber
         --FROM GAL_HOURS, Affectation, GAL_OPERATION, Orfab
--       WHERE Affectation.Afc_Type_Lancement = 'F'
   --    AND   Affectation.PRJ_CODE = v_NumAff
      -- AND   Affectation.TAS_CODE = v_NumTache
         --AND    Orfab.No_Of = Affectation.Afc_No_Lancement
--       AND   GAL_OPERATION.Ope_Type_Lancement = 'F'
   --    AND   GAL_OPERATION.Ope_Poste_Charge
      --       IN (SELECT GCH_CODE
         --    FROM GAL_CHARGE_POST
            -- WHERE    Code_Centre_Charge =  v_TypeRessource)
--       AND   GAL_OPERATION.Ope_No_Lanc1 = Affectation.Afc_No_Lancement
   --    AND   GAL_HOURS.Heu_Type_Lancement = 'F'
      -- AND   GAL_HOURS.Heu_No_Lanc1 = Affectation.Afc_No_Lancement
         --AND GAL_HOURS.OPE_CODE = GAL_OPERATION.OPE_CODE;

    --       v_NbreHDoneReel := v_InterNumber*6/10;
--
   --    SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */
      -- NVL(COUNT(Ope_Type_Lancement),0) INTO v_NbreOp
         --FROM GAL_OPERATION
--       WHERE Ope_Type_Lancement = 'F'
   --    AND   Ope_Poste_Charge
      --       IN (SELECT Code_Poste_Charg
         --    FROM GAL_CHARGE_POST
            -- WHERE    Code_Centre_Charge =  v_TypeRessource)
--       AND   Ope_No_Lanc1
   --       IN    (SELECT /*+ INDEX(Affectation CLE2_Affectation) */ Afc_No_Lancement
      --       FROM Affectation
         --    WHERE Afc_Type_Lancement = 'F'
            -- AND   PRJ_CODE = v_NumAff
               --AND TAS_CODE = v_NumTache);

    --       SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) INDEX(Affectation CLE2_Affectation) INDEX(Orfab CLE_orfab)*/
   --    NVL(ROUND(SUM((OPE_REMAINING_CHARGE)*(Affectation.Afc_Qte_Affectee/DECODE(orfab.qte_lancee,0,Affectation.Afc_Qte_Affectee,orfab.qte_lancee))),-2),0)*6/10 INTO v_NbreHReste
      -- FROM GAL_OPERATION, Affectation, Orfab
         --WHERE   Afc_Type_Lancement = 'F'
--       AND   Affectation.PRJ_CODE = v_NumAff
  --           AND   Affectation.TAS_CODE = v_NumTache
   --    AND   Orfab.No_Of = Affectation.Afc_No_Lancement
      -- AND   GAL_OPERATION.Ope_Type_Lancement = 'F'
         --AND    GAL_OPERATION.Ope_No_Lanc1 = Affectation.Afc_No_Lancement
--       AND   Ope_Poste_Charge
   --       IN (SELECT GCH_CODE
      --       FROM GAL_CHARGE_POST
         --    WHERE    Code_Centre_Charge =  v_TypeRessource);

    --       SELECT /*+ INDEX(GAL_HOURS CLE2_Heures)*/
   ---      NVL(MAX(HOU_POINTING_DATE),0) INTO v_InterDate1
      -- FROM GAL_HOURS
         --WHERE  Heu_Type_Lancement = 'F'
--       AND   Heu_No_Lanc1
   --       IN    (SELECT /*+ INDEX(Affectation CLE2_AFFECTATION) */ Afc_No_Lancement
      --       FROM Affectation
         --    WHERE Afc_Type_Lancement = 'F'
            -- AND   PRJ_CODE = v_NumAff
               --AND TAS_CODE = v_NumTache)
--       AND   GAL_HOURS.OPE_CODE
   --       IN    (SELECT  GAL_OPERATION.OPE_CODE
      --       FROM GAL_OPERATION
         --    WHERE Ope_Type_Lancement = 'F'
            -- AND   Ope_Poste_Charge
               -- IN (SELECT GCH_CODE
                  -- FROM GAL_CHARGE_POST
                     --WHERE  Code_Centre_Charge =  v_TypeRessource)
--             AND   Ope_No_Lanc1
   --             IN    (SELECT /*+ INDEX(Affectation CLE2_AFFECTATION) */ Afc_No_Lancement
      --             FROM Affectation
         --          WHERE Afc_Type_Lancement = 'F'
            --       AND   PRJ_CODE = v_NumAff
               --    AND   TAS_CODE = v_NumTache));

    --       v_DateMax := v_InterDate1+0.75;

    -- Affectation = Poste de charge / GAL_HOURS sur OF

    --    ELSIF  v_Typeheure = 6 THEN
--
   ---      SELECT /*+INDEX(Affectation CLE2_Affectation INDEX(GAL_HOURS CLE2_Heures)  INDEX(Orfab CLE_orfab)*/
      --    NVL(SUM ((HOU_WORKED_TIME + TPS_Passe_Prepa)*(Affectation.Afc_Qte_Affectee/DECODE(orfab.qte_lancee,0,Affectation.Afc_Qte_Affectee,orfab.qte_lancee))),0) INTO v_InterNumber
         --FROM GAL_HOURS, Affectation, GAL_OPERATION, Orfab
--       WHERE Affectation.Afc_Type_Lancement = 'F'
   --    AND   Affectation.PRJ_CODE = v_NumAff
      -- AND   Affectation.TAS_CODE = v_NumTache
         --AND    Orfab.No_Of = Affectation.Afc_No_Lancement
--       AND   GAL_OPERATION.Ope_Type_Lancement = 'F'
   --    AND   GAL_OPERATION.Ope_Poste_Charge = v_TypeRessource
      -- AND   GAL_OPERATION.Ope_No_Lanc1 = Affectation.Afc_No_Lancement
         --AND GAL_HOURS.Heu_Type_Lancement = 'F'
--       AND   GAL_HOURS.Heu_No_Lanc1 = Affectation.Afc_No_Lancement
   --    AND   GAL_HOURS.OPE_CODE = GAL_OPERATION.OPE_CODE;

    -- v_NbreHDoneReel := v_InterNumber*6/10;
--
   --    SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */ NVL(COUNT(Ope_Type_Lancement),0) INTO v_NbreOp
      -- FROM GAL_OPERATION
         --WHERE  Ope_Poste_Charge = v_TypeRessource
--       AND   Ope_Type_Lancement = 'F'
   --    AND   Ope_No_Lanc1
      --    IN    (SELECT /*+ INDEX(Affectation CLE2_AFFECTATION) */ Afc_No_Lancement
         --    FROM Affectation
            -- WHERE Afc_Type_Lancement = 'F'
               --AND PRJ_CODE = v_NumAff
--             AND   TAS_CODE = v_NumTache);

    --    SELECT /*+INDEX(Affectation CLE2_Affectation) INDEX(Orfab CLE_orfab)*/
      --    NVL(ROUND(SUM((OPE_REMAINING_CHARGE)*(Affectation.Afc_Qte_Affectee/DECODE(orfab.qte_lancee,0,Affectation.Afc_Qte_Affectee,orfab.qte_lancee))),-2),0)*6/10 INTO v_NbreHReste
         -- FROM GAL_OPERATION, Affectation, Orfab
            --WHERE  Affectation.Afc_Type_Lancement = 'F'
--          AND   Affectation.PRJ_CODE = v_NumAff
   --       AND   Affectation.TAS_CODE = v_NumTache
      --    AND   Orfab.No_Of = Affectation.Afc_No_Lancement
         -- AND   GAL_OPERATION.Ope_Type_Lancement = 'F'
            --AND GAL_OPERATION.Ope_Poste_Charge = v_TypeRessource
--          AND   GAL_OPERATION.Ope_No_Lanc1 = Affectation.Afc_No_Lancement;

    --    SELECT /*+ INDEX(GAL_HOURS CLE2_Heures)*/ NVL(MAX(HOU_POINTING_DATE),0) INTO v_InterDate1
      -- FROM GAL_HOURS
         --WHERE  Heu_Type_Lancement = 'F'
--       AND   Heu_No_Lanc1
   --       IN    (SELECT /*+ INDEX(Affectation CLE2_AFFECTATION) */ Afc_No_Lancement
      --       FROM Affectation
         --    WHERE Afc_Type_Lancement = 'F'
            -- AND   PRJ_CODE = v_NumAff
               --AND TAS_CODE = v_NumTache)
--       AND   GAL_HOURS.OPE_CODE
   --       IN    (SELECT  GAL_OPERATION.OPE_CODE
      --       FROM GAL_OPERATION
         --    WHERE Ope_Type_Lancement = 'F'
            -- AND   Ope_Poste_Charge = v_TypeRessource
               --AND Ope_No_Lanc1
                  --IN  (SELECT /*+ INDEX(Affectation CLE2_AFFECTATION) */ Afc_No_Lancement
                     --FROM Affectation
--                   WHERE Afc_Type_Lancement = 'F'
   --                AND   PRJ_CODE = v_NumAff
      --             AND   TAS_CODE = v_NumTache));

    --v_DateMax := GAL_FUNCTIONS.DateGToDate (v_InterDate1)+0.75;
    end if;
  end searchinfohpourass;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure searchaffect(v_numaff gal_project.prj_code%type, v_numtache gal_task.tas_code%type, v_typeheure in number, v_cursoraff in out type_cursor)
  is
    vv varchar2(3);
  begin
    select '4'
      into vv
      from dual;

-- affectation = Centre de Charge/ GAL_HOURS sur GAL_TASK
/*
      IF v_TypeHeure = 2 THEN

         OPEN v_CursorAff FOR
            SELECT
            DISTINCT CEN_CODE Affectation
            FROM GAL_PROJECT, GAL_TASK, GAL_TASK_LINK
            --, GAL_CHARGE_CENTER
            WHERE TAS_CODE = v_NumTache
            AND   PRJ_CODE  = v_NumAff
            AND   GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK. GAL_PROJECT_ID
            AND   GAL_TASK_LINK.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID;
            --AND GAL_OPERATION.GAL_CHARGE_CENTER_ID = GAL_CHARGE_CENTER.GAL_CHARGE_CENTER_ID;

-- Affectation = Poste de charge / GAL_HOURS sur GAL_TASK
*/
    if v_typeheure = 3 then
      open v_cursoraff for
        select          /*+ INDEX(GAL_OPERATION PK_GAL_OPERATION) */
               distinct fac_reference affectation
                   from gal_project
                      , gal_task
                      , gal_task_link
                      , fal_factory_floor
                  where tas_code = v_numtache
                    and prj_code = v_numaff
                    and gal_project.gal_project_id = gal_task.gal_project_id
                    and gal_task_link.gal_task_id = gal_task.gal_task_id
                    and fal_factory_floor.fal_factory_floor_id = gal_task_link.fal_factory_floor_id;
    end if;
--  affectation sur centre de Charge / GAL_HOURS sur OF

  --    ELSIF v_TypeHeure = 5 THEN
--       OPEN v_CursorAff FOR
--          SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */
--          DISTINCT GAL_CHARGE_POST.Code_Centre_Charge Affectation
--          FROM GAL_OPERATION, GAL_CHARGE_POST
--          WHERE Ope_Type_Lancement = 'F'
--          AND   Ope_Poste_Charge = GAL_CHARGE_POST.GCH_CODE
--          AND   GAL_CHARGE_POST.Code_Centre_Charge <> ' '
--          AND   Ope_No_Lanc1
--             IN    (SELECT /*+ INDEX(Affectation CLE2_Affectation) */ Afc_No_Lancement
--                FROM Affectation
--                WHERE Afc_Type_Lancement = 'F'
--                AND   PRJ_CODE = v_NumAff
--                AND   TAS_CODE = v_NumTache);
--
--  affectation sur poste de charge / GAL_HOURS sur OF

  --    ELSIF v_TypeHeure = 6 THEN
--       OPEN v_CursorAff FOR
--          SELECT /*+ INDEX(GAL_OPERATION CLE_Oper) */
--          DISTINCT Ope_Poste_Charge Affectation
--          FROM GAL_OPERATION
--          WHERE Ope_Type_Lancement = 'F'
--          AND   Ope_No_Lanc1
--             IN    (SELECT /*+ INDEX(Affectation CLE2_Affectation) */ Afc_No_Lancement
--                FROM Affectation
--                WHERE Afc_Type_Lancement = 'F'
--                AND   PRJ_CODE = v_NumAff
--                AND   TAS_CODE = v_NumTache);
   -- END IF;
  end searchaffect;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure existtacheinaffaire(v_numaff gal_project.prj_code%type, v_numtache gal_task.tas_code%type, v_cursoraff in out type_cursor)
  is
  begin
    open v_cursoraff for
      select tas_code
           , tca_code
           , tas_wording
           , bdg_code
           , c_tca_task_type
        from gal_project
           , gal_task
           , gal_budget
           , gal_task_category
       where gal_project.prj_code = v_numaff
         and tas_code = v_numtache
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_budget.gal_budget_id = gal_task.gal_budget_id
         and gal_task.gal_task_category_id = gal_task_category.gal_task_category_id;
  end existtacheinaffaire;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure searchallnotacheinaffaire(v_numaff gal_project.prj_code%type, v_cursoraff in out type_cursor)
  is
  begin
    open v_cursoraff for
      select   tas_code
          from gal_project
             , gal_task
         where gal_project.prj_code = v_numaff
           and gal_project.gal_project_id = gal_task.gal_project_id
      order by tas_code;
  end searchallnotacheinaffaire;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure searchchampunetacheinaffaire(v_numaff gal_project.prj_code%type, v_numtache gal_task.tas_code%type, v_cursoraff in out type_cursor)
  is
  begin
    open v_cursoraff for
      select tas_code
           , tca_code
           , tas_wording
           , bdg_code
           , tas_start_date
           , tas_end_date
           , c_tca_task_type
        from gal_project
           , gal_task
           , gal_budget
           , gal_task_category
       where gal_project.prj_code = v_numaff
         and tas_code = v_numtache
         and gal_project.gal_project_id = gal_task.gal_project_id
         and gal_budget.gal_budget_id = gal_task.gal_budget_id
         and gal_task.gal_task_category_id = gal_task_category.gal_task_category_id;
  end searchchampunetacheinaffaire;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  procedure dettypepcoucc(v_numaff gal_project.prj_code%type, v_numtache gal_task.tas_code%type, v_retour out varchar2)
  is
    v_nbrecch number;
    v_nbrecha number;
  begin
/*
        SELECT
      NVL(COUNT(GAL_CHARGE_POST_ID),0) INTO v_NbreCha
      FROM GAL_PROJECT, GAL_TASK, GAL_TASK_LINK
      WHERE TAS_CODE = v_NumTache
      AND      PRJ_CODE = v_NumAff
      AND      GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
      AND      GAL_TASK_LINK.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID;

        SELECT
      NVL(COUNT(GAL_CHARGE_CENTER_ID),0) INTO v_NbreCCh
      FROM GAL_PROJECT, GAL_TASK, GAL_OPERATION
      WHERE TAS_CODE = v_NumTache
      AND      PRJ_CODE = v_NumAff
      AND      GAL_PROJECT.GAL_PROJECT_ID = GAL_TASK.GAL_PROJECT_ID
      AND      GAL_OPERATION.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID;

        IF v_NbreCha > 0 AND v_NbreCCh > 0 THEN
            v_Retour := 'MI';
        ELSE
            IF v_NbreCha > 0 THEN
                v_Retour := 'PC';
            END IF;
            IF v_NbreCCh > 0 THEN
                v_Retour := 'CC';
            END IF;
        END IF;
*/
    v_retour  := 'PC';
  end dettypepcoucc;

  procedure detsiopenday(v_date varchar2, v_error out number, v_schemaname varchar2)
  is
    v_datein      date;
    v_societename varchar2(20);
  begin
    select com_name
      into v_societename
      from pcs.pc_comp cp
         , pcs.pc_scrip sc
     where sc.scrdbowner = upper(v_schemaname)
       and cp.pc_scrip_id = sc.pc_scrip_id;

    pcs.PC_I_LIB_SESSION.initsession(v_societename, 'GALEI');
    v_datein  := to_date(v_date, 'DD/MM/YYYY');
    v_error   := DOC_DELAY_FUNCTIONS.IsOpenDay(aDate => v_datein, aThirdID => null, aAdminDomain => 1);
  end detsiopenday;

-- Spécifique CODERE
  procedure searchchampalltacheinaffaire(v_numaff gal_project.prj_code%type, v_cursoraff in out type_cursor)
  is
  begin
    open v_cursoraff for
      select   tas_code
             , tca_code
             , tas_wording
             , bdg_code
             , tas_start_date
             , tas_end_date
             , c_tca_task_type
          from gal_project
             , gal_task
             , gal_budget
             , gal_task_category
         where gal_project.prj_code = v_numaff
           and gal_project.gal_project_id = gal_task.gal_project_id
           and gal_budget.gal_budget_id = gal_task.gal_budget_id
           and gal_task.gal_task_category_id = gal_task_category.gal_task_category_id
      order by gal_task.tas_code;
  end searchchampalltacheinaffaire;
end gal_msp_project;
