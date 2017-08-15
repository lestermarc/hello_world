--------------------------------------------------------
--  DDL for Package Body GAL_GRID_TREATMENTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_GRID_TREATMENTS" 
is
  procedure ERREUR_CODE_ETAT_AFFAIRE(out_error in out varchar2)
  is
  begin
    if    out_error is null
       or 4000 >=(length(trim(out_error) ) + length(trim(PCS.PC_FUNCTIONS.TranslateWord('Le code état affaire interdit ce traitement') || chr(10) ) ) ) then
      out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Le code état affaire interdit ce traitement') || chr(10);
    end if;
  end ERREUR_CODE_ETAT_AFFAIRE;

  procedure ERREUR_DATE_TACHE(out_error in out varchar2)
  is
  begin
    if    out_error is null
       or 4000 >=(length(trim(out_error) ) + length(trim(PCS.PC_FUNCTIONS.TranslateWord('Date de début/fin de tâche manquante') || chr(10) ) ) ) then
      out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Date de début/fin de tâche manquante') || chr(10);
    end if;
  end ERREUR_DATE_TACHE;

  procedure ERREUR_GAL_TASK_GOOD(out_error in out varchar2)
  is
  begin
    if    out_error is null
       or 4000 >=(length(trim(out_error) ) + length(trim(PCS.PC_FUNCTIONS.TranslateWord('Manque article ou nomenclature') || chr(10) ) ) ) then
      out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Manque article ou nomenclature') || chr(10);
    end if;
  end ERREUR_GAL_TASK_GOOD;

  procedure ERREUR_CODE_ETAT_TACHE(out_error in out varchar2)
  is
  begin
    if    out_error is null
       or 4000 >=(length(trim(out_error) ) + length(trim(PCS.PC_FUNCTIONS.TranslateWord('Le code état de la tâche interdit ce traitement') || chr(10) ) ) ) then
      out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Le code état de la tâche interdit ce traitement') || chr(10);
    end if;
  end ERREUR_CODE_ETAT_TACHE;

  --********** Sélection des tâches demandées ****************************************************************--
  procedure SUPPLY_TASK_CALC_SELECTION(
    A_PRJ_CODE_FROM                gal_project.prj_code%type
  , A_PRJ_CODE_TO                  gal_project.prj_code%type
  , A_DIC_GAL_PRJ_CATEGORY_ID_FROM gal_project.dic_gal_prj_category_id%type
  , A_DIC_GAL_PRJ_CATEGORY_ID_TO   gal_project.dic_gal_prj_category_id%type
  , A_SUPPLY_TAS_CODE_FROM         gal_task.tas_code%type
  , A_SUPPLY_TAS_CODE_TO           gal_task.tas_code%type
  , A_SUPPLY_TCA_CODE_FROM         gal_task_category.tca_code%type
  , A_SUPPLY_TCA_CODE_TO           gal_task_category.tca_code%type
  , A_TAS_START_DATE_FROM          gal_task.tas_start_date%type
  , A_TAS_START_DATE_TO            gal_task.tas_start_date%type
  , A_TAS_END_DATE_FROM            gal_task.tas_end_date%type
  , A_TAS_END_DATE_TO              gal_task.tas_end_date%type
  , A_TAS_TASK_MUST_BE_LAUNCH      gal_task.tas_task_must_be_launch%type
  , A_GCO_GOOD_ID                  gal_task_good.gco_good_id%type
  , A_PPS_NOMENCLATURE_ID          gal_task_good.pps_nomenclature_id%type
  )
  is
    CPT                 number         := 0;
    out_error           varchar2(4000);
    V_CPT_GAL_TASK_GOOD number         := 0;
  begin
    delete from GAL_GRID_TREATMENTS_TABLE;

    for cur in (select TAC.GAL_TASK_ID
                     , TAC.gal_project_id
                     , TAC.tas_start_date
                     , TAC.tas_end_date
                     , AFF.c_prj_state
                  from GAL_TASK TAC
                     , GAL_PROJECT AFF
                     , GAL_TASK_CATEGORY TCA
                 where TCA.c_tca_task_type = '1'
                   and TAC.c_tas_state <> '40'   -- Soldée
                   and TAC.c_tas_state <> '99'   -- Suspendue
                   and AFF.gal_project_id = TAC.gal_project_id
                   and TCA.gal_task_category_id = TAC.gal_task_category_id
                   and (   AFF.prj_code >= A_PRJ_CODE_FROM
                        or A_PRJ_CODE_FROM is null)
                   and (   AFF.prj_code <= A_PRJ_CODE_TO
                        or A_PRJ_CODE_TO is null)
                   and (   AFF.dic_gal_prj_category_id >= A_DIC_GAL_PRJ_CATEGORY_ID_FROM
                        or A_DIC_GAL_PRJ_CATEGORY_ID_FROM is null)
                   and (   AFF.dic_gal_prj_category_id <= A_DIC_GAL_PRJ_CATEGORY_ID_TO
                        or A_DIC_GAL_PRJ_CATEGORY_ID_TO is null)
                   and (   TAC.tas_code >= A_SUPPLY_TAS_CODE_FROM
                        or A_SUPPLY_TAS_CODE_FROM is null)
                   and (   TAC.tas_code <= A_SUPPLY_TAS_CODE_TO
                        or A_SUPPLY_TAS_CODE_TO is null)
                   and (   TCA.tca_code >= A_SUPPLY_TCA_CODE_FROM
                        or A_SUPPLY_TCA_CODE_FROM is null)
                   and (   TCA.tca_code <= A_SUPPLY_TCA_CODE_TO
                        or A_SUPPLY_TCA_CODE_TO is null)
                   and (   TAC.tas_start_date >= A_TAS_START_DATE_FROM
                        or A_TAS_START_DATE_FROM is null)
                   and (   TAC.tas_start_date <= A_TAS_START_DATE_TO
                        or A_TAS_START_DATE_TO is null)
                   and (   TAC.tas_end_date >= A_TAS_END_DATE_FROM
                        or A_TAS_END_DATE_FROM is null)
                   and (   TAC.tas_end_date <= A_TAS_END_DATE_TO
                        or A_TAS_END_DATE_TO is null)
                   and (   TAC.tas_task_must_be_launch = A_TAS_TASK_MUST_BE_LAUNCH
                        or A_TAS_TASK_MUST_BE_LAUNCH is null)
                   and (   A_GCO_GOOD_ID in(select gco_good_id
                                              from gal_task_good
                                             where gal_task_good.gal_task_id = TAC.gal_task_id)
                        or A_GCO_GOOD_ID is null)
                   and (   A_PPS_NOMENCLATURE_ID in(select pps_nomenclature_id
                                                      from gal_task_good
                                                     where gal_task_good.gal_task_id = TAC.gal_task_id)
                        or A_PPS_NOMENCLATURE_ID is null) ) loop
      CPT        := CPT + 1;
      out_error  := null;

      if    cur.c_prj_state < '20'
         or cur.c_prj_state >= '40' then
        ERREUR_CODE_ETAT_AFFAIRE(out_error);
      end if;

      if    cur.tas_start_date is null
         or cur.tas_end_date is null then
        ERREUR_DATE_TACHE(out_error);
      end if;

      select count(1)
        into v_cpt_gal_task_good
        from gal_task_good
       where gal_task_id = cur.gal_task_id;

      if v_cpt_gal_task_good = 0 then
        ERREUR_GAL_TASK_GOOD(out_error);
      end if;

      insert into GAL_GRID_TREATMENTS_TABLE
                  (GAL_GRID_TREATMENTS_TABLE_ID
                 , GAL_TASK_ID
                 , GGT_CALCULATION_BOOLEAN
                 , GGT_ERRORS
                  )
           values (CPT
                 , cur.GAL_TASK_ID
                 , 0
                 , out_error
                  );
    end loop;

    commit;
  end SUPPLY_TASK_CALC_SELECTION;

--**********************************************************************************************************--

  --********** Lancement du calcul de besoins pour les tâches sélectionnées **********************************--
  procedure TASK_CALCULATION
  is
    V_GAL_PRJ_CALC_METHOD varchar2(10) := null;
    V_PLANIF_DF           number;
    V_CALC_DF             number;
  begin
    for cur in (select TAS.gal_project_id
                     , GGT.gal_task_id
                     , TAS.c_tas_state
                  from GAL_PROJECT PRJ
                     , GAL_TASK TAS
                     , GAL_GRID_TREATMENTS_TABLE GGT
                 where GGT_CALCULATION_BOOLEAN = 1
                   and TAS.gal_task_id = GGT.gal_task_id
                   and PRJ.gal_project_id = TAS.gal_project_id
                   and PRJ.c_prj_state >= '20'
                   and PRJ.c_prj_state < '40'
                   and TAS.tas_start_date is not null
                   and TAS.tas_end_date is not null
                   and 0 < (select count(1)
                              from gal_task_good GTG
                             where GTG.gal_task_id = TAS.gal_task_id) ) loop
      select min(PCS.PC_CONFIG.GETCONFIG('GAL_PRJ_CALC_METHOD') )
        into V_GAL_PRJ_CALC_METHOD
        from dual;

      V_PLANIF_DF  := substr(V_GAL_PRJ_CALC_METHOD, 1, 1);
      V_CALC_DF    := substr(V_GAL_PRJ_CALC_METHOD, 3, 1);
      GAL_PROJECT_CALCULATION.CALCUL_AFFAIRE(cur.GAL_PROJECT_ID, cur.GAL_TASK_ID, cur.C_TAS_STATE, V_PLANIF_DF, V_CALC_DF, 0, 'N');
      commit;
    end loop;
  end TASK_CALCULATION;

--**********************************************************************************************************--
  function get_GalTaskGood_ref(A_GAL_TASK_ID gal_task.gal_task_id%type)
    return varchar2
  is
    CPT    number;
    result varchar2(4000);
  begin
    select count(1)
      into CPT
      from gal_task_good
     where gal_task_id = A_GAL_TASK_ID;

    if 1 < CPT then
      result  := PCS.PC_FUNCTIONS.TranslateWord('Plusieurs') || ' (' || to_char(CPT) || ')';
    else
      select goo_major_reference
        into result
        from gal_task_good GTG
           , gco_good GCO
       where GTG.gal_task_id = A_GAL_TASK_ID
         and GCO.gco_good_id = GTG.gco_good_id;
    end if;

    return result;
  end get_GalTaskGood_ref;

  function get_GalTaskGood_des(iTaskID in GAL_TASK.GAL_TASK_ID%type)
    return varchar2
  is
    cursor lcrTaskGood
    is
      select   trim(GOO.GOO_MAJOR_REFERENCE) || '/' || trim(NOM.NOM_VERSION) || ' ' || trim(DES.DES_SHORT_DESCRIPTION) as GOOD_REF
          from GAL_TASK_GOOD GML
             , GCO_GOOD GOO
             , GCO_DESCRIPTION DES
             , PPS_NOMENCLATURE NOM
         where GML.GAL_TASK_ID = iTaskID
           and GML.GCO_GOOD_ID = GOO.GCO_GOOD_ID
           and GML.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID(+)
           and GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID
           and DES.C_DESCRIPTION_TYPE = '01'
           and DES.PC_LANG_ID = nvl(PCS.PC_I_LIB_SESSION.GetUserLangId, 1)
      order by GOO.GOO_MAJOR_REFERENCE
             , NOM.NOM_VERSION;

    ltplTaskGood lcrTaskGood%rowtype;
    lnCount      integer;
    lvResult     varchar2(32767);
  begin
    lvResult  := '';

    select count(*)
      into lnCount
      from GAL_TASK_GOOD
     where GAL_TASK_ID = iTaskID;

    if lnCount > 0 then
      -- S'il n'y a qu'un seul produit, on renvoi que la description de celui-ci
      --   car la référence du produit est fournie par la fonction get_GalTaskGood_ref
      if lnCount = 1 then
        select DES.DES_SHORT_DESCRIPTION
          into lvResult
          from GAL_TASK_GOOD GML
             , GCO_DESCRIPTION DES
         where GML.GAL_TASK_ID = iTaskID
           and GML.GCO_GOOD_ID = DES.GCO_GOOD_ID
           and DES.C_DESCRIPTION_TYPE = '01'
           and DES.PC_LANG_ID = nvl(PCS.PC_I_LIB_SESSION.GetUserLangId, 1);
      else
        open lcrTaskGood;

        fetch lcrTaskGood
         into ltplTaskGood;

        -- La valeur de retour ne doit pas dépasser la longueur maximale de 4000 caractères
        --  car cette fonction est utilisée dans le select d'une commande sql externe
        while(lcrTaskGood%found)
         and (nvl(length(lvResult), 0) < 4000) loop
           -- Concaténer la référence/version nomenclature/description de tous les produits
          lvResult  := lvResult || ltplTaskGood.GOOD_REF || chr(10);

          fetch lcrTaskGood
           into ltplTaskGood;
        end loop;

        close lcrTaskGood;
      end if;
    end if;

    -- Tronquer le résultat à 4000 caractères
    if length(lvResult) > 4000 then
      lvResult  := substr(lvResult, 1, 3997) || '...';
    end if;

    return lvResult;
  end get_GalTaskGood_des;

  function get_GalTaskGood_ver(A_GAL_TASK_ID gal_task.gal_task_id%type)
    return varchar2
  is
    CPT    number;
    result varchar2(4000);
  begin
    select count(1)
      into CPT
      from gal_task_good
     where gal_task_id = A_GAL_TASK_ID;

    if 1 < CPT then
      result  := '';
    else
      select nom_version
        into result
        from gal_task_good GTG
           , pps_nomenclature PPS
       where GTG.gal_task_id = A_GAL_TASK_ID
         and PPS.pps_nomenclature_id(+) = GTG.pps_nomenclature_id;
    end if;

    return result;
  end get_GalTaskGood_ver;

  --********** Sélection des GAL_TASK_GOOD concernés ****************************************************************--
  procedure SUPPLY_TASK_PPS_VERSION_SELECT(A_PPS_NOMENCLATURE_ID gal_task_good.pps_nomenclature_id%type)
  is
    CPT       number         := 0;
    out_error varchar2(4000);
  begin
    delete from GAL_GRID_TREATMENTS_TABLE;

    for cur in (select GTG.GAL_TASK_GOOD_ID
                     , TAS.C_TAS_STATE
                     , PPS.nom_version
                  from GAL_TASK_GOOD GTG
                     , GAL_TASK TAS
                     , PPS_NOMENCLATURE PPS
                 where GTG.pps_nomenclature_id = A_PPS_NOMENCLATURE_ID
                   and TAS.gal_task_id = GTG.gal_task_id
                   and PPS.pps_nomenclature_id = GTG.pps_nomenclature_id) loop
      CPT        := CPT + 1;
      out_error  := null;

      if cur.c_tas_state >= '40' then
        ERREUR_CODE_ETAT_TACHE(out_error);
      end if;

      insert into GAL_GRID_TREATMENTS_TABLE
                  (GAL_GRID_TREATMENTS_TABLE_ID
                 , GAL_TASK_GOOD_ID
                 , GGT_NEW_VERSION
                 , GGT_ERRORS
                  )
           values (CPT
                 , cur.GAL_TASK_GOOD_ID
                 , cur.NOM_VERSION
                 , out_error
                  );
    end loop;

    commit;
  end SUPPLY_TASK_PPS_VERSION_SELECT;

--**********************************************************************************************************--

  --********** Mise à jour de la version de nomenclature pour les GAL_TASK_GOOD modifiés ***************************--
  procedure SUPPLY_TASK_PPS_VERSION_UPDATE
  is
    V_CPT                 number         := 0;
    out_error             varchar2(4000);
    V_PPS_NOMENCLATURE_ID number         := 0;
  begin
    for cur in (select GGT.gal_grid_treatments_table_id
                     , GTG.gal_task_good_id
                     , GTG.gco_good_id
                     , GTG.pps_nomenclature_id
                     , GGT.ggt_new_version
                     , TAS.c_tas_state
                  from GAL_GRID_TREATMENTS_TABLE GGT
                     , GAL_TASK_GOOD GTG
                     , PPS_NOMENCLATURE PPS
                     , GAL_TASK TAS
                 where GTG.gal_task_good_id = GGT.gal_task_good_id
                   and PPS.pps_nomenclature_id = GTG.pps_nomenclature_id
                   and nvl(GGT.GGT_NEW_VERSION, ' ') <> nvl(PPS.nom_version, ' ')   -- L'utilisateur a modifié la version de nomenclature
                   and TAS.gal_task_id = GTG.gal_task_id
                   and TAS.c_tas_state <= '40') loop
      select count(*)
        into V_CPT
        from PPS_NOMENCLATURE PPS
       where PPS.gco_good_id = cur.gco_good_id
         and nvl(PPS.nom_version, ' ') = nvl(cur.ggt_new_version, ' ');

      -- Cas d'une seule nomenclature pour cet article/version (indépendemment du type de nomenclature)
      if V_CPT = 1 then
        select pps_nomenclature_id
          into V_PPS_NOMENCLATURE_ID
          from PPS_NOMENCLATURE PPS
         where PPS.gco_good_id = cur.gco_good_id
           and nvl(PPS.nom_version, ' ') = nvl(cur.ggt_new_version, ' ');

        update GAL_TASK_GOOD
           set PPS_NOMENCLATURE_ID = V_PPS_NOMENCLATURE_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI
         where gal_task_good_id = cur.gal_task_good_id;
      end if;

      if V_CPT > 1 then
        -- Cas de plusieurs nomenclatures pour cet article/version
        -- On prend celle correspondant au type de nomenclature de l'ancienne version
        select pps_nomenclature_id
          into V_PPS_NOMENCLATURE_ID
          from PPS_NOMENCLATURE PPS
         where PPS.gco_good_id = cur.gco_good_id
           and nvl(PPS.nom_version, ' ') = nvl(cur.ggt_new_version, ' ')
           and PPS.c_type_nom = (select c_type_nom
                                   from PPS_NOMENCLATURE old
                                  where old.pps_nomenclature_id = cur.pps_nomenclature_id);

        update GAL_TASK_GOOD
           set PPS_NOMENCLATURE_ID = V_PPS_NOMENCLATURE_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI
         where gal_task_good_id = cur.gal_task_good_id;
      end if;

      commit;
    end loop;
  end SUPPLY_TASK_PPS_VERSION_UPDATE;

--**********************************************************************************************************--

  --********** Sélection des opérations demandées ************************************************************--
  procedure TASK_LINK_CLOSE_SELECT(
    A_FAC_REFERENCE_FROM           fal_factory_floor.fac_reference%type
  , A_FAC_REFERENCE_TO             fal_factory_floor.fac_reference%type
  , A_TAL_START_DATE_FROM          gal_task_link.tal_begin_plan_date%type
  , A_TAL_START_DATE_TO            gal_task_link.tal_begin_plan_date%type
  , A_TAL_END_DATE_FROM            gal_task_link.tal_end_plan_date%type
  , A_TAL_END_DATE_TO              gal_task_link.tal_end_plan_date%type
  , A_PRJ_CODE_FROM                gal_project.prj_code%type
  , A_PRJ_CODE_TO                  gal_project.prj_code%type
  , A_DIC_GAL_PRJ_CATEGORY_ID_FROM gal_project.dic_gal_prj_category_id%type
  , A_DIC_GAL_PRJ_CATEGORY_ID_TO   gal_project.dic_gal_prj_category_id%type
  , A_LABOR_TAS_CODE_FROM          gal_task.tas_code%type
  , A_LABOR_TAS_CODE_TO            gal_task.tas_code%type
  , A_LABOR_TCA_CODE_FROM          gal_task_category.tca_code%type
  , A_LABOR_TCA_CODE_TO            gal_task_category.tca_code%type
  , A_DIC_GAL_LOCATION_ID          gal_task.dic_gal_location_id%type
  )
  is
    CPT number := 0;
  begin
    delete from GAL_GRID_TREATMENTS_TABLE;

    for cur in (select GAL_TASK_LINK_ID
                     , TAL_TSK_BALANCE
                  from GAL_TASK_LINK OPE
                     , FAL_FACTORY_FLOOR RESS
                     , GAL_TASK TAC
                     , GAL_PROJECT AFF
                     , GAL_TASK_CATEGORY TCA
                 where OPE.c_tal_state <> '40'
                   and RESS.fal_factory_floor_id = OPE.fal_factory_floor_id
                   and (   RESS.fac_reference >= A_FAC_REFERENCE_FROM
                        or A_FAC_REFERENCE_FROM is null)
                   and (   RESS.fac_reference <= A_FAC_REFERENCE_TO
                        or A_FAC_REFERENCE_TO is null)
                   and (   OPE.tal_begin_plan_date >= A_TAL_START_DATE_FROM
                        or A_TAL_START_DATE_FROM is null)
                   and (   OPE.tal_begin_plan_date <= A_TAL_START_DATE_TO
                        or A_TAL_START_DATE_TO is null)
                   and (   OPE.tal_end_plan_date >= A_TAL_END_DATE_FROM
                        or A_TAL_END_DATE_FROM is null)
                   and (   OPE.tal_end_plan_date <= A_TAL_END_DATE_TO
                        or A_TAL_END_DATE_TO is null)
                   and TAC.gal_task_id = OPE.gal_task_id
                   and AFF.gal_project_id = TAC.gal_project_id
                   and TCA.gal_task_category_id = TAC.gal_task_category_id
                   and (   AFF.prj_code >= A_PRJ_CODE_FROM
                        or A_PRJ_CODE_FROM is null)
                   and (   AFF.prj_code <= A_PRJ_CODE_TO
                        or A_PRJ_CODE_TO is null)
                   and (   AFF.dic_gal_prj_category_id >= A_DIC_GAL_PRJ_CATEGORY_ID_FROM
                        or A_DIC_GAL_PRJ_CATEGORY_ID_FROM is null)
                   and (   AFF.dic_gal_prj_category_id <= A_DIC_GAL_PRJ_CATEGORY_ID_TO
                        or A_DIC_GAL_PRJ_CATEGORY_ID_TO is null)
                   and (   TAC.tas_code >= A_LABOR_TAS_CODE_FROM
                        or A_LABOR_TAS_CODE_FROM is null)
                   and (   TAC.tas_code <= A_LABOR_TAS_CODE_TO
                        or A_LABOR_TAS_CODE_TO is null)
                   and (   TCA.tca_code >= A_LABOR_TCA_CODE_FROM
                        or A_LABOR_TCA_CODE_FROM is null)
                   and (   TCA.tca_code <= A_LABOR_TCA_CODE_TO
                        or A_LABOR_TCA_CODE_TO is null)
                   and (   GAL_GRID_TREATMENTS.get_DicGalLocation_From_Task(TAC.gal_task_id) = A_DIC_GAL_LOCATION_ID
                        or A_DIC_GAL_LOCATION_ID is null) ) loop
      CPT  := CPT + 1;

      insert into GAL_GRID_TREATMENTS_TABLE
                  (GAL_GRID_TREATMENTS_TABLE_ID
                 , GAL_TASK_LINK_ID
                 , GGT_TSK_BALANCE
                 , GGT_CLOSE_BOOLEAN
                  )
           values (CPT
                 , cur.GAL_TASK_LINK_ID
                 , cur.TAL_TSK_BALANCE
                 , 0
                  );
    end loop;

    commit;
  end TASK_LINK_CLOSE_SELECT;

  --********** Mise à jour des opérations (solde ou charge restante) ***********************************************--
  procedure TASK_LINK_CLOSE_UPDATE
  is
    v_comment         gal_task_link.scs_free_descr%type     := null;
    v_tal_tsk_balance gal_task_link.tal_tsk_balance%type    := null;
    lGAL_TASK_LINK_ID gal_task_link.GAL_TASK_LINK_ID%type   := null;
    out_warning       clob                                  := null;
    out_error         clob                                  := null;
  begin
    for cur in (select GGT.GAL_TASK_LINK_ID
                     , GGT.ggt_close_boolean
                     , GGT.ggt_tsk_balance
                  from GAL_GRID_TREATMENTS_TABLE GGT) loop
      begin
        select TAL_TSK_BALANCE
             , SCS_FREE_DESCR
             , GAL_TASK_LINK_ID
          into v_tal_tsk_balance
             , v_comment
             , lGAL_TASK_LINK_ID
          from gal_task_link
         where GAL_TASK_LINK_ID = cur.GAL_TASK_LINK_ID;
      exception
        when no_data_found then
          lGAL_TASK_LINK_ID  := null;
      end;

      if lGAL_TASK_LINK_ID is not null then
        if cur.ggt_close_boolean = 1 then
          gal_treatments.close_task_link('MAJ', lGAL_TASK_LINK_ID, sysdate, v_comment, out_warning, out_error);
        else
          if cur.ggt_tsk_balance <> v_tal_tsk_balance then
            update gal_task_link
               set TAL_TSK_BALANCE = cur.GGT_TSK_BALANCE
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI
             where GAL_TASK_LINK_ID = lGAL_TASK_LINK_ID;
          end if;
        end if;

        commit;
      end if;
    end loop;
  end TASK_LINK_CLOSE_UPDATE;

  --********** Sélection des tâches à solder ************************************************************--
  procedure TASK_CLOSE_SELECT(
    A_PRJ_CODE_FROM                gal_project.prj_code%type
  , A_PRJ_CODE_TO                  gal_project.prj_code%type
  , A_DIC_GAL_PRJ_CATEGORY_ID_FROM gal_project.dic_gal_prj_category_id%type
  , A_DIC_GAL_PRJ_CATEGORY_ID_TO   gal_project.dic_gal_prj_category_id%type
  , A_TAS_CODE_FROM                gal_task.tas_code%type
  , A_TAS_CODE_TO                  gal_task.tas_code%type
  , A_TCA_CODE_FROM                gal_task_category.tca_code%type
  , A_TCA_CODE_TO                  gal_task_category.tca_code%type
  , A_TAS_START_DATE_FROM          gal_task.tas_start_date%type
  , A_TAS_START_DATE_TO            gal_task.tas_start_date%type
  , A_TAS_END_DATE_FROM            gal_task.tas_end_date%type
  , A_TAS_END_DATE_TO              gal_task.tas_end_date%type
  , A_DIC_GAL_LOCATION_ID          gal_task.dic_gal_location_id%type
  )
  is
    CPT         number                      := 0;
    v_comment   gal_task.tas_comment%type   := null;
    in_error    clob                        := null;
    out_warning clob                        := null;
    out_error   clob                        := null;
  begin
    delete from GAL_GRID_TREATMENTS_TABLE;

    for cur in (select GAL_TASK_ID
                  from GAL_TASK TAC
                     , GAL_PROJECT AFF
                     , GAL_TASK_CATEGORY TCA
                 where TAC.c_tas_state <> '40'
                   and AFF.gal_project_id = TAC.gal_project_id
                   and TCA.gal_task_category_id = TAC.gal_task_category_id
                   and (   AFF.prj_code >= A_PRJ_CODE_FROM
                        or A_PRJ_CODE_FROM is null)
                   and (   AFF.prj_code <= A_PRJ_CODE_TO
                        or A_PRJ_CODE_TO is null)
                   and (   AFF.dic_gal_prj_category_id >= A_DIC_GAL_PRJ_CATEGORY_ID_FROM
                        or A_DIC_GAL_PRJ_CATEGORY_ID_FROM is null)
                   and (   AFF.dic_gal_prj_category_id <= A_DIC_GAL_PRJ_CATEGORY_ID_TO
                        or A_DIC_GAL_PRJ_CATEGORY_ID_TO is null)
                   and (   TAC.tas_code >= A_TAS_CODE_FROM
                        or A_TAS_CODE_FROM is null)
                   and (   TAC.tas_code <= A_TAS_CODE_TO
                        or A_TAS_CODE_TO is null)
                   and (   TCA.tca_code >= A_TCA_CODE_FROM
                        or A_TCA_CODE_FROM is null)
                   and (   TCA.tca_code <= A_TCA_CODE_TO
                        or A_TCA_CODE_TO is null)
                   and (   TAC.tas_start_date >= A_TAS_START_DATE_FROM
                        or A_TAS_START_DATE_FROM is null)
                   and (   TAC.tas_start_date <= A_TAS_START_DATE_TO
                        or A_TAS_START_DATE_TO is null)
                   and (   TAC.taS_end_date >= A_TAS_END_DATE_FROM
                        or A_TAS_END_DATE_FROM is null)
                   and (   TAC.tas_end_date <= A_TAS_END_DATE_TO
                        or A_TAS_END_DATE_TO is null)
                   and (   GAL_GRID_TREATMENTS.get_DicGalLocation_From_Task(TAC.gal_task_id) = A_DIC_GAL_LOCATION_ID
                        or A_DIC_GAL_LOCATION_ID is null) ) loop
      CPT          := CPT + 1;
      out_warning  := null;
      out_error    := null;
      gal_treatments.close_task('CTRL', cur.GAL_TASK_ID, sysdate, v_comment, out_warning, out_error);
      in_error     := out_error;

      insert into GAL_GRID_TREATMENTS_TABLE
                  (GAL_GRID_TREATMENTS_TABLE_ID
                 , GAL_TASK_ID
                 , GGT_CLOSE_BOOLEAN
                 , GGT_ERRORS
                  )
           values (CPT
                 , cur.GAL_TASK_ID
                 , 0
                 , in_error
                  );
    end loop;

    commit;
  end TASK_CLOSE_SELECT;

  function get_NbClosedGalTaskLink(A_GAL_TASK_ID gal_task.gal_task_id%type)
    return number
  is
    result number;
  begin
    select count(1)
      into result
      from gal_task_link
     where gal_task_id = A_GAL_TASK_ID
       and c_tal_state = '40';

    return result;
  end get_NbClosedGalTaskLink;

  function get_NbTotalGalTaskLink(A_GAL_TASK_ID gal_task.gal_task_id%type)
    return number
  is
    result number;
  begin
    select count(1)
      into result
      from gal_task_link
     where gal_task_id = A_GAL_TASK_ID;

    return result;
  end get_NbTotalGalTaskLink;

  function get_DicGalLocation_From_Task(A_GAL_TASK_ID gal_task.gal_task_id%type)
    return gal_task.dic_gal_location_id%type
  is
    result               varchar2(10);
    v_gal_father_task_id number;
    v_gal_project_id     number;
  begin
    select min(dic_gal_location_id)
         , min(gal_father_task_id)
         , min(gal_project_id)
      into result
         , v_gal_father_task_id
         , v_gal_project_id
      from gal_task
     where gal_task_id = A_GAL_TASK_ID;

    if result is null then
      if v_gal_father_task_id is not null then
        select min(dic_gal_location_id)
          into result
          from gal_task
         where gal_task_id = v_gal_father_task_id;
      end if;

      if result is null then
        select min(dic_gal_location_id)
          into result
          from gal_project
         where gal_project_id = v_gal_project_id;
      end if;
    end if;

    return result;
  end get_DicGalLocation_From_Task;

  --********** Mise à jour des tâches (traitement de solde) ****************************************************--
  procedure TASK_CLOSE_UPDATE
  is
    v_comment   gal_task.tas_comment%type   := null;
    out_warning clob                        := null;
    out_error   clob                        := null;
  begin
    for cur in (select *
                  from GAL_GRID_TREATMENTS_TABLE
                 where GGT_CLOSE_BOOLEAN = 1) loop
      select TAS_COMMENT
        into v_comment
        from gal_task
       where gal_task_id = cur.gal_task_id;

      gal_treatments.close_task('MAJ', cur.GAL_TASK_ID, sysdate, v_comment, out_warning, out_error);
      commit;
    end loop;
  end TASK_CLOSE_UPDATE;

  --********** Sélection des tâches à lancer ************************************************************--
  procedure TASK_LAUNCH_SELECT(
    A_PRJ_CODE_FROM                gal_project.prj_code%type
  , A_PRJ_CODE_TO                  gal_project.prj_code%type
  , A_DIC_GAL_PRJ_CATEGORY_ID_FROM gal_project.dic_gal_prj_category_id%type
  , A_DIC_GAL_PRJ_CATEGORY_ID_TO   gal_project.dic_gal_prj_category_id%type
  , A_TAS_CODE_FROM                gal_task.tas_code%type
  , A_TAS_CODE_TO                  gal_task.tas_code%type
  , A_TCA_CODE_FROM                gal_task_category.tca_code%type
  , A_TCA_CODE_TO                  gal_task_category.tca_code%type
  , A_TAS_START_DATE_FROM          gal_task.tas_start_date%type
  , A_TAS_START_DATE_TO            gal_task.tas_start_date%type
  , A_TAS_END_DATE_FROM            gal_task.tas_end_date%type
  , A_TAS_END_DATE_TO              gal_task.tas_end_date%type
  , A_DIC_GAL_LOCATION_ID          gal_task.dic_gal_location_id%type
  )
  is
    CPT         number                      := 0;
    v_comment   gal_task.tas_comment%type   := null;
    in_error    clob                        := null;
    out_warning clob                        := null;
    out_error   clob                        := null;
  begin
    delete from GAL_GRID_TREATMENTS_TABLE;

    for cur in (select GAL_TASK_ID
                  from GAL_TASK TAC
                     , GAL_PROJECT AFF
                     , GAL_TASK_CATEGORY TCA
                 where TAC.c_tas_state < '20'
                   and AFF.gal_project_id = TAC.gal_project_id
                   and TCA.gal_task_category_id = TAC.gal_task_category_id
                   and (   AFF.prj_code >= A_PRJ_CODE_FROM
                        or A_PRJ_CODE_FROM is null)
                   and (   AFF.prj_code <= A_PRJ_CODE_TO
                        or A_PRJ_CODE_TO is null)
                   and (   AFF.dic_gal_prj_category_id >= A_DIC_GAL_PRJ_CATEGORY_ID_FROM
                        or A_DIC_GAL_PRJ_CATEGORY_ID_FROM is null)
                   and (   AFF.dic_gal_prj_category_id <= A_DIC_GAL_PRJ_CATEGORY_ID_TO
                        or A_DIC_GAL_PRJ_CATEGORY_ID_TO is null)
                   and (   TAC.tas_code >= A_TAS_CODE_FROM
                        or A_TAS_CODE_FROM is null)
                   and (   TAC.tas_code <= A_TAS_CODE_TO
                        or A_TAS_CODE_TO is null)
                   and (   TCA.tca_code >= A_TCA_CODE_FROM
                        or A_TCA_CODE_FROM is null)
                   and (   TCA.tca_code <= A_TCA_CODE_TO
                        or A_TCA_CODE_TO is null)
                   and (   TAC.tas_start_date >= A_TAS_START_DATE_FROM
                        or A_TAS_START_DATE_FROM is null)
                   and (   TAC.tas_start_date <= A_TAS_START_DATE_TO
                        or A_TAS_START_DATE_TO is null)
                   and (   TAC.taS_end_date >= A_TAS_END_DATE_FROM
                        or A_TAS_END_DATE_FROM is null)
                   and (   TAC.tas_end_date <= A_TAS_END_DATE_TO
                        or A_TAS_END_DATE_TO is null)
                   and (   GAL_GRID_TREATMENTS.get_DicGalLocation_From_Task(TAC.gal_task_id) = A_DIC_GAL_LOCATION_ID
                        or A_DIC_GAL_LOCATION_ID is null) ) loop
      CPT          := CPT + 1;
      out_warning  := null;
      out_error    := null;
      gal_treatments.launch_task('CTRL', cur.GAL_TASK_ID, sysdate, v_comment, out_warning, out_error);
      in_error     := out_error;

      insert into GAL_GRID_TREATMENTS_TABLE
                  (GAL_GRID_TREATMENTS_TABLE_ID
                 , GAL_TASK_ID
                 , GGT_LAUNCH_BOOLEAN
                 , GGT_ERRORS
                  )
           values (CPT
                 , cur.GAL_TASK_ID
                 , 0
                 , in_error
                  );
    end loop;

    commit;
  end TASK_LAUNCH_SELECT;

  --********** Mise à jour des tâches (traitement de lancement) ****************************************************--
  procedure TASK_LAUNCH_UPDATE
  is
    v_comment   gal_task.tas_comment%type   := null;
    out_warning clob                        := null;
    out_error   clob                        := null;
  begin
    for cur in (select *
                  from GAL_GRID_TREATMENTS_TABLE
                 where GGT_LAUNCH_BOOLEAN = 1) loop
      select TAS_COMMENT
        into v_comment
        from gal_task
       where gal_task_id = cur.gal_task_id;

      gal_treatments.launch_task('MAJ', cur.GAL_TASK_ID, sysdate, v_comment, out_warning, out_error);
      commit;
    end loop;
  end TASK_LAUNCH_UPDATE;
end GAL_GRID_TREATMENTS;
