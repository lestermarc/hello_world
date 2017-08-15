--------------------------------------------------------
--  DDL for Package Body PPS_NOM_TRACABILITY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_NOM_TRACABILITY_FUNCTIONS" 
is
--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure generate_nom_tracability(
    a_pps_nomenclature_header_id pps_nomenclature.pps_nomenclature_id%type
  , a_gco_good_header_id         pps_nomenclature.gco_good_id%type
  , a_doc_record_header_id       doc_record.doc_record_id%type
  , a_acc                        number
  )   --1=PPS 2=Aff/budget 3=Tâches 4=Descente complete pour maj lien
  is
    v_idx                        number;
    v_exist                      char(1);
    v_pps_nomenclature_header_id pps_nomenclature.pps_nomenclature_id%type;
    v_datecre                    pps_nomenclature.a_datecre%type;
  begin
    /* Création de l'entête nomenclature de type sav si n'existe pas ou n'est pas renseigné (on utilise le gco_good_id qui est dans tous les cas passé) */
    if    (    a_pps_nomenclature_header_id is null
           and a_gco_good_header_id is not null)
       or (    a_pps_nomenclature_header_id = 0
           and a_gco_good_header_id is not null) then
      PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_HEADER(a_doc_record_header_id, v_pps_nomenclature_header_id, a_gco_good_header_id, a_pps_nomenclature_header_id);

      begin
        select '*'
          into v_exist
          from gal_project
         where doc_record_id = a_doc_record_header_id;

        update gal_project
           set pps_nomenclature_id = v_pps_nomenclature_header_id
         where doc_record_id = a_doc_record_header_id;
      exception
        when no_data_found then
          begin
            select '*'
              into v_exist
              from gal_budget
             where doc_record_id = a_doc_record_header_id;

            update gal_budget
               set pps_nomenclature_id = v_pps_nomenclature_header_id
             where doc_record_id = a_doc_record_header_id;
          exception
            when no_data_found then
              null;
          end;
      end;
    else
      v_pps_nomenclature_header_id  := a_pps_nomenclature_header_id;
    end if;

    /*Fin creation d'entete nomenc*/
    v_datecre  := sysdate;

    /*Mise à jour du flag pour les composants supprimés*/
    update pps_nom_tracability
       set pnt_del_comp = 1
     where doc_record_header_id = a_doc_record_header_id;

    if a_acc = 2   --Affaire/budget
                then
      v_idx  := 0;

      for CTask in (select   gal_task_id
                           , doc_record_id
                        from gal_task
                       where gal_budget_id = (select gal_budget_id
                                                from gal_budget
                                               where doc_record_id = a_doc_record_header_id)
                          or gal_project_id = (select gal_project_id
                                                 from gal_project
                                                where doc_record_id = a_doc_record_header_id)
                    order by tas_code) loop
        for CTaskGood in (select   GAL_TASK_GOOD.pps_nomenclature_id
                                 , GAL_TASK_GOOD.gco_good_id
                                 , GAL_TASK_GOOD.GML_QUANTITY
                                 , GAL_TASK_GOOD.GAL_TASK_GOOD_ID
                                 , GAL_TASK_GOOD.GML_SEQUENCE
                              from GAL_TASK_GOOD
                             where GAL_TASK_GOOD.GAL_TASK_ID = CTask.gal_task_id
                          --and GAL_TASK_GOOD.PPS_NOMENCLATURE_ID IS NOT NULL
                          order by GML_SEQUENCE) loop
          v_idx  := 0;

          if CTaskGood.GML_QUANTITY <> 0 then
            for i in 1 .. round(CTaskGood.GML_QUANTITY) loop
              v_idx  := v_idx + 10;
              pps_nom_tracability_functions.generate_nom_tracability_unit(CTaskGood.pps_nomenclature_id
                                                                        , CTaskGood.gco_good_id
                                                                        , CTask.doc_record_id
                                                                        , v_pps_nomenclature_header_id
                                                                        , a_gco_good_header_id
                                                                        , a_doc_record_header_id
                                                                        , CTaskGood.gal_task_good_id
                                                                        , 3
                                                                        , CTaskGood.GML_SEQUENCE
                                                                        , v_idx
                                                                        , v_datecre
                                                                         );
            end loop;
          end if;
        end loop;
      end loop;
    end if;

    pps_nom_tracability_functions.generate_nom_tracability_unit(v_pps_nomenclature_header_id
                                                              , a_gco_good_header_id
                                                              , a_doc_record_header_id
                                                              , v_pps_nomenclature_header_id
                                                              , a_gco_good_header_id
                                                              , a_doc_record_header_id
                                                              , null
                                                              , a_acc
                                                              , 10
                                                              , 10
                                                              , v_datecre
                                                               );   --Genere entete affaire/budget ou pps d'install
/*   pps_nom_tracability_functions.generate_nom_tracability_unit(v_pps_nomenclature_header_id,a_gco_good_header_id,a_doc_record_header_id
                                                ,v_pps_nomenclature_header_id,a_gco_good_header_id,a_doc_record_header_id
                                                ,null,4,10,10,v_datecre); --Genere entete affaire/budget ou pps d'install
*/
  end generate_nom_tracability;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure generate_task_nom_tracability(a_task_id gal_task.gal_task_id%type, a_doc_record_id gal_task.doc_record_id%type)
  is
    v_pps_id        GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_good_id       GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_task_good_id  GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_pps_header_id GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_bdg_pps_id    GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_gco_header_id GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_bdg_gco_id    GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_doc_header_id GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_bdg_doc_id    GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_prj_pps_id    GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_prj_gco_id    GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_prj_doc_id    GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    v_qte           number;
    v_idx           number;
    v_seq           number;
    v_datecre       pps_nomenclature.a_datecre%type;

    cursor C_TASK_GOOD
    is
      select   GAL_TASK_GOOD.pps_nomenclature_id
             , GAL_TASK_GOOD.gco_good_id
             , GAL_TASK_GOOD.GML_QUANTITY
             , GAL_TASK_GOOD.GAL_TASK_GOOD_ID
             , GAL_TASK_GOOD.GML_SEQUENCE
          from GAL_TASK_GOOD
         where GAL_TASK_GOOD.GAL_TASK_ID = a_task_id
      --AND GAL_TASK_GOOD.PPS_NOMENCLATURE_ID IS NOT NULL
      order by GML_SEQUENCE;
  begin
    v_idx      := 0;
    v_datecre  := sysdate;

    /*Mise à jour du flag pour les composants supprimés*/
    update pps_nom_tracability
       set pnt_del_comp = 1
     where doc_record_id = a_doc_record_id;

    select PRJ.PPS_NOMENCLATURE_ID
         , BDG.PPS_NOMENCLATURE_ID
         , PRJ.GCO_GOOD_ID
         , BDG.GCO_GOOD_ID
         , PRJ.DOC_RECORD_ID
         , BDG.DOC_RECORD_ID
      into v_prj_pps_id
         , v_bdg_pps_id
         , v_prj_gco_id
         , v_bdg_gco_id
         , v_prj_doc_id
         , v_bdg_doc_id
      from GAL_PROJECT PRJ
         , GAL_BUDGET BDG
         , GAL_TASK TAS
     where PRJ.GAL_PROJECT_ID = TAS.GAL_PROJECT_ID
       and BDG.GAL_BUDGET_ID = TAS.GAL_BUDGET_ID
       and TAS.GAL_TASK_ID = a_task_id;

    if v_prj_gco_id is not null then
      v_pps_header_id  := v_prj_pps_id;
      v_gco_header_id  := v_prj_gco_id;
      v_doc_header_id  := v_prj_doc_id;
      pps_nom_tracability_functions.generate_nom_tracability_unit(v_pps_header_id
                                                                , v_gco_header_id
                                                                , v_doc_header_id
                                                                , v_pps_header_id
                                                                , v_gco_header_id
                                                                , v_doc_header_id
                                                                , null
                                                                , 2
                                                                , 10
                                                                , 10
                                                                , v_datecre
                                                                 );   --Genere entete affaire/budget ou pps d'install
    elsif v_bdg_gco_id is not null then
      v_pps_header_id  := v_bdg_pps_id;
      v_gco_header_id  := v_bdg_gco_id;
      v_doc_header_id  := v_bdg_doc_id;
      pps_nom_tracability_functions.generate_nom_tracability_unit(v_pps_header_id
                                                                , v_gco_header_id
                                                                , v_doc_header_id
                                                                , v_pps_header_id
                                                                , v_gco_header_id
                                                                , v_doc_header_id
                                                                , null
                                                                , 2
                                                                , 10
                                                                , 10
                                                                , v_datecre
                                                                 );   --Genere entete affaire/budget ou pps d'install
    else
      v_pps_header_id  := null;
      v_gco_header_id  := null;
      v_doc_header_id  := null;
    end if;

    open C_TASK_GOOD;

    loop
      fetch C_TASK_GOOD
       into v_pps_id
          , v_good_id
          , v_qte
          , v_task_good_id
          , v_seq;

      exit when C_TASK_GOOD%notfound;
      v_idx  := 0;

      if v_qte <> 0 then
        for i in 1 .. round(v_qte) loop
          v_idx  := v_idx + 10;
          pps_nom_tracability_functions.generate_nom_tracability_unit(v_pps_id
                                                                    , v_good_id
                                                                    , a_doc_record_id
                                                                    , v_pps_header_id
                                                                    , v_gco_header_id
                                                                    , v_doc_header_id
                                                                    , v_task_good_id
                                                                    , 3
                                                                    , v_seq
                                                                    , v_idx
                                                                    , v_datecre
                                                                     );
        end loop;
      end if;
    end loop;

    close C_TASK_GOOD;
  end generate_task_nom_tracability;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure generate_nom_tracability_unit(
    a_pps_nomenclature_id        pps_nomenclature.pps_nomenclature_id%type
  , a_gco_good_id                pps_nomenclature.gco_good_id%type
  , a_doc_record_id              doc_record.doc_record_id%type
  , a_pps_nomenclature_header_id pps_nomenclature.pps_nomenclature_id%type
  , a_gco_good_header_id         pps_nomenclature.gco_good_id%type
  , a_doc_record_header_id       doc_record.doc_record_id%type
  , a_task_good_id               doc_record.doc_record_id%type
  , a_acc                        number
  ,   --1=PPS 2=Aff/taches
    a_seq                        number
  , a_idx                        number
  , a_date_cre                   date
  )
  is
    vNEWNID                        pps_nomenclature.pps_nomenclature_id%type;
    v_idx                          number;
    v_com_seq                      pps_nom_bond.com_seq%type;
    v_pps_nom_bond_id              pps_nomenclature.pps_nomenclature_id%type;
    v_pps_nomenclature_id          pps_nomenclature.pps_nomenclature_id%type;
    v_pps_pps_nomenclature_id      pps_nomenclature.pps_nomenclature_id%type;
    v_gco_good_id                  pps_nomenclature.pps_nomenclature_id%type;
    tsk_pps_nomenclature_header_id pps_nomenclature.pps_nomenclature_id%type;
    tsk_gco_good_header_id         pps_nomenclature.gco_good_id%type;
    tsk_doc_record_header_id       doc_record.doc_record_id%type;
    v_task_id                      gal_task.gal_task_id%type;
    v_plan_number                  gal_task_good.gml_plan_version%type;
    v_plan_version                 gal_task_good.gml_plan_number%type;
    v_nom_version                  pps_nomenclature.nom_version%type;
    v_doc_record_id                gal_task.doc_record_id%type;
    v_sys_connect_by_path          varchar2(4000);
    v_sys_connect_by_path_nseq     varchar2(4000);
    v_test_null_pps_pps            varchar2(60);
    v_level                        number;
    v_level_indent                 number;
    v_existid                      pps_nomenclature.pps_nomenclature_id%type;
    v_update_info_good             varchar2(1);
    v_type_nom                     varchar2(2);
    v_doc_record_pps               pps_nomenclature.doc_record_id%type;
    v_GCO_CHARACTERIZATION_ID      GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    v_GCO_GCO_CHARACTERIZATION_ID  GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    v_GCO2_GCO_CHARACTERIZATION_ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    v_GCO3_GCO_CHARACTERIZATION_ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    v_GCO4_GCO_CHARACTERIZATION_ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    x_pps_nomenclature_id          pps_nomenclature.pps_nomenclature_id%type;
    v_test_path                    varchar2(4000);
    v_path_parent                  varchar2(4000);
    v_from_art_dir                 varchar2(1);

    cursor c_pps_nomen
    is
      select     bond.pps_nom_bond_id
               , bond.pps_nomenclature_id
               , bond.pps_pps_nomenclature_id
               , bond.gco_good_id
               , sys_connect_by_path(lpad(bond.com_seq, 10, '0') || '-' || bond.gco_good_id, '/')
               , sys_connect_by_path(bond.gco_good_id, '/')
               , level + 1 + v_level_indent
               , bond.com_seq
               , (select nvl(min(doc_record_id), pps.doc_record_id)
                    from pps_nomenclature
                   where pps_nomenclature_id = bond.pps_pps_nomenclature_id)
               , nvl(trim(to_char(bond.pps_pps_nomenclature_id) ), 'X-X-X')
               , nbs.nom_version
               , pps.c_type_nom
               , pps.doc_record_id
            --nvl(nbs.c_type_nom,pps.c_type_nom),
            --nvl(nbs.doc_record_id,pps.doc_record_id)
      from       pps_nomenclature pps
               , pps_nomenclature nbs
               , pps_nom_bond bond
           where pps.pps_nomenclature_id(+) = bond.pps_nomenclature_id
             and nbs.pps_nomenclature_id(+) = bond.pps_pps_nomenclature_id
      start with bond.pps_nomenclature_id = x_pps_nomenclature_id
      connect by /*nocycle*/ prior bond.pps_pps_nomenclature_id = bond.pps_nomenclature_id
        order siblings by bond.pps_nomenclature_id
                , bond.com_seq;

--**********************************************************************************************************--
    procedure init_info_gco
    is
    begin
      begin   --Affaire
        select GAL_TASK_ID
             , GML_PLAN_NUMBER
             , GML_PLAN_VERSION
             , GML_SEQUENCE
             , NOM_VERSION
          into v_task_id
             , v_plan_number
             , v_plan_version
             , v_com_seq
             , v_nom_version
          from PPS_NOMENCLATURE PPS
             , GAL_TASK_GOOD GTG
         where PPS.PPS_NOMENCLATURE_ID(+) = GTG.PPS_NOMENCLATURE_ID
           and GTG.GAL_TASK_GOOD_ID = a_task_good_id;
      exception
        when no_data_found then
          begin   --Defaut article
            select trim(rpad(CMA_PLAN_NUMBER, 60) )
                 , trim(rpad(CMA_PLAN_VERSION, 60) )
              into v_plan_number
                 , v_plan_version
              from GCO_COMPL_DATA_MANUFACTURE
             where CMA_DEFAULT = 1
               and GCO_GOOD_ID = a_gco_good_id;
          exception
            when no_data_found then
              v_plan_number   := null;
              v_plan_version  := null;
          end;
      end;
    end init_info_gco;

--**********************************************************************************************************--
    procedure init_characterization(a_gco_good_id pps_nomenclature.gco_good_id%type)
    is
      v_cpt number;
    begin
      v_cpt                           := 0;
      v_GCO_CHARACTERIZATION_ID       := null;
      v_GCO_GCO_CHARACTERIZATION_ID   := null;
      v_GCO2_GCO_CHARACTERIZATION_ID  := null;
      v_GCO3_GCO_CHARACTERIZATION_ID  := null;
      v_GCO4_GCO_CHARACTERIZATION_ID  := null;

      for c_cur in (select   CHA1.GCO_CHARACTERIZATION_ID
                        from GCO_CHARACTERIZATION CHA1
                       where CHA1.GCO_GOOD_ID = a_gco_good_id
                    order by CHA1.C_CHARACT_TYPE) loop
        v_cpt  := v_cpt + 1;

        if v_cpt = 1 then
          v_GCO_CHARACTERIZATION_ID  := c_cur.GCO_CHARACTERIZATION_ID;
        elsif v_cpt = 2 then
          v_GCO_GCO_CHARACTERIZATION_ID  := c_cur.GCO_CHARACTERIZATION_ID;
        elsif v_cpt = 3 then
          v_GCO2_GCO_CHARACTERIZATION_ID  := c_cur.GCO_CHARACTERIZATION_ID;
        elsif v_cpt = 4 then
          v_GCO3_GCO_CHARACTERIZATION_ID  := c_cur.GCO_CHARACTERIZATION_ID;
        elsif v_cpt = 5 then
          v_GCO4_GCO_CHARACTERIZATION_ID  := c_cur.GCO_CHARACTERIZATION_ID;
        end if;
      end loop;
    end init_characterization;

--**********************************************************************************************************--
    procedure write_history(
      cType varchar2
    , v_id  PPS_NOM_TRACABILITY.PPS_NOM_TRACABILITY_ID%type
    , old   PPS_NOM_TRACABILITY_HISTORY.PTH_OLD_VALUE%type
    , new   PPS_NOM_TRACABILITY_HISTORY.PTH_OLD_VALUE%type
    )
    is
    begin
      select INIT_ID_SEQ.nextval
        into vNEWNID   /* Génération d'un nouvel Id*/
        from dual;

      insert into PPS_NOM_TRACABILITY_HISTORY
                  (PPS_NOM_TRACABILITY_ID
                 , PPS_NOM_TRACABILITY_HISTORY_ID
                 , C_STATUS_NOM_HISTORY
                 , PTH_OLD_VALUE
                 , PTH_NEW_VALUE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (v_id
                 , vNEWNID
                 , cType
                 , old
                 , new
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      update PPS_NOM_TRACABILITY
         set PNT_CHANGE_VERSION = 1
           , A_DATEMOD = a_date_cre
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where PPS_NOM_TRACABILITY_ID = v_id;
    end write_history;

--**********************************************************************************************************--
    function CheckNewComp(a_path_parent varchar2)
      return number
    is
      v_result PPS_NOM_TRACABILITY.PNT_NEW_COMP%type;
    begin
      select NewComp
        into v_result
        from (select   decode(A_DATECRE, a_date_cre, 0, 1) NewComp
                  from pps_nom_tracability
                 where doc_record_header_id in(a_doc_record_id, a_doc_record_header_id)
                   and pnt_nom_path like '%' || a_path_parent
              order by A_DATEMOD asc)
       where rownum = 1;

      return(v_result);
    exception
      when no_data_found then
        return(0);
    end CheckNewComp;

--**********************************************************************************************************--
    procedure init_line_tacability(a_NewComp PPS_NOM_TRACABILITY.PNT_NEW_COMP%type)
    is
--test_art varchar2(200);
    begin
      --Creation nomenclature si existait pas avant
      begin
        select trim(rpad(CMA_PLAN_NUMBER, 60) )
             , trim(rpad(CMA_PLAN_VERSION, 60) )
          into v_plan_number
             , v_plan_version
          from GCO_COMPL_DATA_MANUFACTURE
         where CMA_DEFAULT = 1
           and GCO_GOOD_ID = v_gco_good_id;
      exception
        when no_data_found then
          v_plan_number   := null;
          v_plan_version  := null;
      end;

      init_characterization(v_gco_good_id);

      select INIT_ID_SEQ.nextval
        into vNEWNID   /* Génération d'un nouvel Id nomenclature Sav */
        from dual;

--Select goo_major_reference into test_art from gco_good where gco_good_id = v_gco_good_id;
--DBMS_OUTPUT.PUT_LINE('INSERT ARTICLE : ' || test_art || ' --> ' || nvl(to_char(tsk_doc_record_header_id),'XXXXX' || to_char(a_doc_record_id)  )  );
      insert into pps_nom_tracability
                  (PPS_NOM_TRACABILITY_ID
                 , GCO_GOOD_ID
                 , PPS_NOM_BOND_ID
                 , PPS_NOMENCLATURE_ID
                 , PPS_PPS_NOMENCLATURE_ID
                 , GAL_TASK_GOOD_ID
                 , GAL_TASK_ID
                 , DOC_RECORD_ID
                 , DOC_RECORD_HEADER_ID
                 , PNT_NOM_PATH
                 , PNT_NOM_PATH_NO_SEQ
                 , PNT_NOM_LEVEL
                 , PPS_NOMENCLATURE_HEADER_ID
                 , PNT_PLAN_NUMBER
                 , PNT_PLAN_VERSION
                 , NOM_VERSION
                 , COM_SEQ
                 , PNT_INDEX
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , PNT_NEW_COMP
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vNEWNID
                 , v_gco_good_id
                 , v_pps_nom_bond_id
                 , v_pps_nomenclature_id
                 , v_pps_pps_nomenclature_id
                 , a_task_good_id
                 , v_task_id
                 , a_doc_record_id
                 , nvl(tsk_doc_record_header_id, a_doc_record_id)
                 , decode(v_from_art_dir
                        , 'N', decode(tsk_doc_record_header_id, null, null, to_char(tsk_doc_record_header_id) || '-') ||
                           to_char(a_gco_good_id) ||
                           V_SYS_CONNECT_BY_PATH
                        , decode(tsk_doc_record_header_id, null, null, to_char(tsk_doc_record_header_id) || '-' || to_char(tsk_gco_good_header_id) || '/') ||
                          lpad(to_char(a_seq), 10, '0') ||
                          '-' ||
                          to_char(a_gco_good_id) ||
                          V_SYS_CONNECT_BY_PATH
                         )
                 , decode(v_from_art_dir
                        , 'N', to_char(a_gco_good_id) || v_sys_connect_by_path_nseq
                        , decode(tsk_doc_record_header_id, null, null, to_char(tsk_gco_good_header_id) || '/') ||
                          to_char(a_gco_good_id) ||
                          v_sys_connect_by_path_nseq
                         )
                 , v_level
                 , nvl(tsk_pps_nomenclature_header_id, a_pps_nomenclature_id)
                 , v_plan_number
                 , v_plan_version
                 , v_nom_version
                 , v_com_seq
                 , a_idx
                 , v_GCO_CHARACTERIZATION_ID
                 , v_GCO_GCO_CHARACTERIZATION_ID
                 , v_GCO2_GCO_CHARACTERIZATION_ID
                 , v_GCO3_GCO_CHARACTERIZATION_ID
                 , v_GCO4_GCO_CHARACTERIZATION_ID
                 , a_NewComp
                 , a_date_cre
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end init_line_tacability;

--**********************************************************************************************************--
--**********************************************************************************************************--
    procedure Create_traca_nomenclature
    is
      v_nomT_version    PPS_NOM_TRACABILITY.NOM_VERSION%type;
      v_nomP_version    PPS_NOM_TRACABILITY.NOM_VERSION%type;
      x_exist_trc       number;
      xNEWNID           PPS_NOM_TRACABILITY.PPS_NOM_TRACABILITY_ID%type;
      v_trc_nom_version PPS_NOM_TRACABILITY.NOM_VERSION%type;
      v_is_new_comp     PPS_NOM_TRACABILITY.PNT_NEW_COMP%type;
      v_flag_doc_record number;
      v_flag_pnt_index  number;
      v_ctrl_gtg_id     PPS_NOM_TRACABILITY.GAL_TASK_GOOD_ID%type;
      v_ctrl_ok         number;
      test_art          varchar2(200);
    begin
      if    a_task_good_id is not null
         or a_acc = 1   --pps
         or v_from_art_dir = 'N' then
        /*Creation des lignes*/
        open c_pps_nomen;

        loop
          fetch c_pps_nomen
           into v_pps_nom_bond_id
              , v_pps_nomenclature_id
              , v_pps_pps_nomenclature_id
              , v_gco_good_id
              , v_sys_connect_by_path
              , v_sys_connect_by_path_nseq
              , v_level
              , v_com_seq
              , v_doc_record_id
              , v_test_null_pps_pps
              , v_nom_version
              , v_type_nom
              , v_doc_record_pps;

          exit when c_pps_nomen%notfound;

          /*Test supression de composants*/
          update pps_nom_tracability
             set pnt_del_comp = 0
           where doc_record_header_id in(a_doc_record_id, tsk_doc_record_header_id)
             and pnt_nom_path like '%' || v_sys_connect_by_path;

          begin
            select trim(rpad(CMA_PLAN_NUMBER, 60) )
                 , trim(rpad(CMA_PLAN_VERSION, 60) )
              into v_plan_number
                 , v_plan_version
              from GCO_COMPL_DATA_MANUFACTURE
             where CMA_DEFAULT = 1
               and GCO_GOOD_ID = v_gco_good_id;
          exception
            when no_data_found then
              v_plan_number   := null;
              v_plan_version  := null;
          end;

          if v_from_art_dir = 'Y' then
            /*Article Directeur...*/
            x_exist_trc  := 0;

            --Le lien existe déjà => on ne fait rien sauf mettre à jour
            for Ctrc in (select PPS_NOM_TRACABILITY_ID
                              , PNT_NOM_PATH
                              , substr(PNT_NOM_PATH, 1, instr(PNT_NOM_PATH, '/', 1, PNT_NOM_LEVEL) - 1)
                              , NOM_VERSION
                           --into v_existid,v_test_path,v_path_parent,v_trc_nom_version
                         from   PPS_NOM_TRACABILITY
                          where doc_record_header_id in(a_doc_record_id, tsk_doc_record_header_id)
                            and doc_record_id = a_doc_record_id
                            and v_from_art_dir = 'Y'
                            and gco_good_id = v_gco_good_id
                            and (    (nvl(nom_version, ' ') ) =(nvl(v_nom_version, ' ') )
                                 or (     (nvl(nom_version, ' ') ) <>(nvl(v_nom_version, ' ') )
                                     and pps_nom_bond_id = v_pps_nom_bond_id)
                                )
                            and substr(pnt_nom_path, instr(pnt_nom_path, '/')) = v_sys_connect_by_path
                            --and pnt_nom_path = decode(tsk_doc_record_header_id,null,null,to_char(tsk_doc_record_header_id) || '-' || to_char(tsk_gco_good_header_id) || '/') || lpad(to_char(a_seq),10,'0') || '-' || to_char(a_gco_good_id) || v_sys_connect_by_path
                            and a_task_good_id is not null   --and rownum = 1;
                            and gal_task_good_id = a_task_good_id
                            and pnt_index = a_Idx) loop
              x_exist_trc  := 1;

              /*Mise à jour du path + pps id*/
              update PPS_NOM_TRACABILITY
                 set PPS_NOMENCLATURE_HEADER_ID = nvl(tsk_pps_nomenclature_header_id, a_pps_nomenclature_id)
                   , DOC_RECORD_HEADER_ID = nvl(tsk_doc_record_header_id, a_doc_record_id)
                   , PPS_NOM_BOND_ID = v_pps_nom_bond_id
                   , PPS_NOMENCLATURE_ID = v_pps_nomenclature_id
                   , PPS_PPS_NOMENCLATURE_ID = v_pps_pps_nomenclature_id
                   , GAL_TASK_GOOD_ID = a_task_good_id
                   , GAL_TASK_ID = v_task_id
                   , DOC_RECORD_ID = a_doc_record_id
                   , PNT_NOM_PATH =
                       decode(tsk_doc_record_header_id, null, null, to_char(tsk_doc_record_header_id) || '-' || to_char(tsk_gco_good_header_id) || '/') ||
                       lpad(to_char(a_seq), 10, '0') ||
                       '-' ||
                       to_char(a_gco_good_id) ||
                       V_SYS_CONNECT_BY_PATH
                   , PNT_NOM_PATH_NO_SEQ =
                       decode(tsk_doc_record_header_id, null, null, to_char(tsk_gco_good_header_id) || '/') ||
                       to_char(a_gco_good_id) ||
                       v_sys_connect_by_path_nseq
                   , PNT_CHANGE_VERSION =
                       decode(PNT_CHANGE_VERSION
                            , 0, decode( (nvl(nom_version, ' ') ),(nvl(v_nom_version, ' ') ), 0   --Version identique = 0
                                                                                               , 1)   --Version differente = 1
                            , 1
                             )
                   , NOM_VERSION = v_nom_version
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                   , A_DATEMOD = a_date_cre
               where PPS_NOM_TRACABILITY_ID = Ctrc.PPS_NOM_TRACABILITY_ID;

              /*Modif version --> maj Historique*/
              if (nvl(Ctrc.nom_version, ' ') ) <>(nvl(v_nom_version, ' ') ) then
                write_history(53, Ctrc.PPS_NOM_TRACABILITY_ID, Ctrc.nom_version, v_nom_version);
              end if;
            end loop;

            if x_exist_trc = 0 then
              v_is_new_comp  := CheckNewComp(substr(v_sys_connect_by_path, 1, instr(v_sys_connect_by_path, '/', -1, 1) - 1) );
              init_line_tacability(v_is_new_comp);
            end if;
          /*Fin Article Directeur*/
          else
            /*Descente complete...*/
            x_exist_trc        := 0;
            v_flag_doc_record  := null;
            v_flag_pnt_index   := null;

--Select goo_major_reference into test_art from gco_good where gco_good_id = v_gco_good_id;
--DBMS_OUTPUT.PUT_LINE('INSERT ARTICLE : ' || test_art || ' --> ' || nvl(to_char(tsk_doc_record_header_id),'XXXXX') || nvl(to_char(a_doc_record_id),'YYYYY')  );
            for Ctrc in (select   PPS_NOM_TRACABILITY_ID
                                , PNT_NOM_PATH
                                , substr(PNT_NOM_PATH, 1, instr(PNT_NOM_PATH, '/', 1, PNT_NOM_LEVEL) - 1)
                                , NOM_VERSION
                                , DOC_RECORD_ID
                                , PNT_INDEX
                                , GAL_TASK_GOOD_ID
                                , PPS_NOMENCLATURE_ID
                                , (select decode(pps_nom_tracability.gco_good_id, t2.gco_good_id, 1, 0)
                                     from gal_task_good t2
                                    where t2.gal_task_good_id = pps_nom_tracability.gal_task_good_id) Is_Art_Dir
                             from PPS_NOM_TRACABILITY
                            where nvl(pnt_used_comp, 0) = 0
                              and doc_record_header_id in(a_doc_record_id, a_doc_record_header_id)   --= a_doc_record_header_id
                              and gco_good_id = v_gco_good_id
                              and v_from_art_dir = 'N'
                              and (    (nvl(nom_version, ' ') ) =(nvl(v_nom_version, ' ') )
                                   or (     (nvl(nom_version, ' ') ) <>(nvl(v_nom_version, ' ') )
                                       and pps_nom_bond_id = v_pps_nom_bond_id)
                                  )
--         and (/*PNT_NOM_PATH_NO_SEQ like '%' || V_SYS_CONNECT_BY_PATH_NSEQ
--          or*/ --v_sys_connect_by_path_nseq like '%' || replace(PNT_NOM_PATH_NO_SEQ, a_gco_good_header_id || '/','')
--          or to_char(a_gco_good_id) || v_sys_connect_by_path_nseq = PNT_NOM_PATH_NO_SEQ)
                         order by nvl(doc_record_id, 0)
                                , pnt_index) loop
              x_exist_trc  := 1;
              v_ctrl_ok    := 1;

              for Ctrc2 in   --Controle du pere (a partir de son path)
                          (select   T2.GAL_TASK_GOOD_ID
                                  , T2.PPS_PPS_NOMENCLATURE_ID
                                  , T2.DOC_RECORD_ID
                               from PPS_NOM_TRACABILITY T2
                              where T2.DOC_RECORD_HEADER_ID in(a_doc_record_id, a_doc_record_header_id)
                                and substr(to_char(a_gco_good_id) || v_sys_connect_by_path_nseq
                                         , 1
                                         , instr(to_char(a_gco_good_id) || v_sys_connect_by_path_nseq, '/', -1, 1) - 1
                                          ) = T2.PNT_NOM_PATH_NO_SEQ
                           order by nvl(doc_record_id, 0)
                                  , pnt_index) loop
--DBMS_OUTPUT.PUT_LINE('<<UPDATE ARTICLE BEFORE CRTL>> : ' || test_art || ' Is Art Dir <' || Ctrc.Is_Art_Dir || '> Ctrl2GTG : <' || Ctrc2.gal_task_good_id  || '>=<' || Ctrc.gal_task_good_id || ' ----- <' || Ctrc.PPS_NOMENCLATURE_ID  || '>=<' || ctrc2.PPS_PPS_NOMENCLATURE_ID  );
                if (   Ctrc2.gal_task_good_id = Ctrc.gal_task_good_id
                    or (    Ctrc2.gal_task_good_id is null
                        and Ctrc.Is_Art_Dir = 1) )
                                                  --and
                                                  --   (Ctrc.PPS_NOMENCLATURE_ID = ctrc2.PPS_PPS_NOMENCLATURE_ID
                                                  -- or Ctrc.PPS_NOMENCLATURE_ID = a_pps_nomenclature_header_id)
                then
                  v_ctrl_ok  := 1;
                  exit;
                else
                  v_ctrl_ok  := 0;
                end if;
              end loop;

--DBMS_OUTPUT.PUT_LINE('<<UPDATE ARTICLE BEFORE TEST>> : ' || test_art || ' CTRL : <' || v_ctrl_ok || '> --> ' || nvl(to_char(tsk_doc_record_header_id),'XXXXX') || ' - ' || nvl(to_char( a_doc_record_id),'YYYY')   );
              if     (   v_flag_doc_record = Ctrc.doc_record_id
                      or v_flag_doc_record is null)
                 and (v_ctrl_ok = 1)
                 and (   Ctrc.pnt_index > v_flag_pnt_index
                      or v_flag_pnt_index is null) then
--DBMS_OUTPUT.PUT_LINE('<<UPDATE ARTICLE>> : ' || test_art || ' --> ' || nvl(to_char(tsk_doc_record_header_id),'XXXXX') || ' - ' || nvl(to_char( a_doc_record_id),'YYYY')   );

                /*Mise à jour du path + pps id*/
                update PPS_NOM_TRACABILITY
                   set PPS_NOMENCLATURE_HEADER_ID = nvl(a_pps_nomenclature_header_id, a_pps_nomenclature_id)
                     --,a_doc_record_id)
                ,      DOC_RECORD_HEADER_ID = a_doc_record_header_id
                     /* Uncomment */
                ,      PPS_NOM_BOND_ID = v_pps_nom_bond_id
                     , PPS_NOMENCLATURE_ID = v_pps_nomenclature_id
                     , PPS_PPS_NOMENCLATURE_ID = v_pps_pps_nomenclature_id
                     /* Uncomment */
                ,      PNT_NOM_LEVEL = v_level
                     , COM_SEQ = v_com_seq
                     , PNT_NOM_PATH =
                             decode(a_doc_record_header_id, null, null, to_char(a_doc_record_header_id) || '-') || to_char(a_gco_good_id)
                             || V_SYS_CONNECT_BY_PATH
                     , PNT_NOM_PATH_NO_SEQ = to_char(a_gco_good_id) || v_sys_connect_by_path_nseq
                     , PNT_CHANGE_VERSION =
                         decode(PNT_CHANGE_VERSION
                              , 0, decode( (nvl(nom_version, ' ') ),(nvl(v_nom_version, ' ') ), 0   --Version identique = 0
                                                                                                 , 1)   --Version differente = 1
                              , 1
                               )
                     , NOM_VERSION = v_nom_version
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                     , A_DATEMOD = a_date_cre
                     , PNT_USED_COMP = 1
                 where PPS_NOM_TRACABILITY_ID = Ctrc.PPS_NOM_TRACABILITY_ID;

                v_flag_doc_record  := Ctrc.doc_record_id;
                v_flag_pnt_index   := Ctrc.pnt_index;
              end if;

              /*Modif version --> maj Historique*/
              if (nvl(Ctrc.nom_version, ' ') ) <>(nvl(v_nom_version, ' ') ) then
                write_history(53, Ctrc.PPS_NOM_TRACABILITY_ID, Ctrc.nom_version, v_nom_version);
              end if;
            end loop;

            if x_exist_trc = 0 then
              v_is_new_comp  := CheckNewComp(substr(v_sys_connect_by_path, 1, instr(v_sys_connect_by_path, '/', -1, 1) - 1) );
              init_line_tacability(v_is_new_comp);
            end if;
          end if;
        end loop;

        close c_pps_nomen;
      end if;
    end Create_traca_nomenclature;

--**********************************************************************************************************************--
--**********************************************************************************************************************--
    procedure Create_Header
    is
      v_nomT_version PPS_NOM_TRACABILITY.NOM_VERSION%type;
      v_nomP_version PPS_NOM_TRACABILITY.NOM_VERSION%type;
    begin
      v_level_indent  := 1;

      begin
        --Controle si existe pas déjà tête affaire ou budget
        select PPS_NOM_TRACABILITY_ID
             , NOM_VERSION
          into v_existid
             , v_nomT_version
          from PPS_NOM_TRACABILITY
         where PPS_NOMENCLATURE_HEADER_ID = a_pps_nomenclature_header_id
           and DOC_RECORD_HEADER_ID = a_doc_record_header_id
           and DOC_RECORD_ID = a_doc_record_header_id
           and GCO_GOOD_ID = a_gco_good_header_id
           and PNT_NOM_PATH = to_char(a_doc_record_id) || '-' || to_char(a_gco_good_header_id)
           and PPS_NOM_BOND_ID is null;

        begin   --> Si nomenclature sav, on ne met plus à jour les infos caracterisations,plan...
          select decode(nom_version, v_nomT_version, 'N', 'Y')
               , nom_version
            into v_update_info_good
               , v_nomP_version
            from pps_nomenclature pps
           where pps.pps_nomenclature_id = a_pps_nomenclature_header_id
             and pps.doc_record_id = a_doc_record_header_id;   --> Passage Sav
        exception
          when no_data_found then
            begin
              select decode(nom_version, v_nomT_version, 'N', 'Y')
                   , nom_version
                into v_update_info_good
                   , v_nomP_version
                from pps_nomenclature pps
               where pps.pps_nomenclature_id = a_pps_nomenclature_header_id;
            exception
              when no_data_found then
                v_update_info_good  := 'Y';
                v_nomP_version      := v_nomT_version;
            end;
        end;

        if (nvl(v_nomP_version, ' ') ) <>(nvl(v_nomT_version, ' ') ) then
          write_history(53, v_existid, v_nomT_version, v_nomP_version);
        end if;

        if v_update_info_good = 'Y' then
          begin   --Affaire
            select trim(rpad(PRJ_PLAN_NUMBER, 60) )
                 , trim(rpad(PRJ_PLAN_VERSION, 60) )
              into v_plan_number
                 , v_plan_version
              from GAL_PROJECT PRJ
             where PRJ.DOC_RECORD_ID = a_doc_record_header_id;
          exception
            when no_data_found then
              begin   --budget
                select trim(rpad(BDG_PLAN_NUMBER, 60) )
                     , trim(rpad(BDG_PLAN_VERSION, 60) )
                  into v_plan_number
                     , v_plan_version
                  from GAL_BUDGET BDG
                 where BDG.DOC_RECORD_ID = a_doc_record_header_id;
              exception
                when no_data_found then
                  begin   --Defaut article
                    select trim(rpad(CMA_PLAN_NUMBER, 60) )
                         , trim(rpad(CMA_PLAN_VERSION, 60) )
                      into v_plan_number
                         , v_plan_version
                      from GCO_COMPL_DATA_MANUFACTURE
                     where CMA_DEFAULT = 1
                       and GCO_GOOD_ID = a_gco_good_header_id;
                  exception
                    when no_data_found then
                      v_plan_number   := null;
                      v_plan_version  := null;
                  end;
              end;
          end;

          init_characterization(a_gco_good_header_id);
        end if;

        update PPS_NOM_TRACABILITY
           set PPS_NOMENCLATURE_HEADER_ID = a_pps_nomenclature_header_id
             , PPS_PPS_NOMENCLATURE_ID = a_pps_nomenclature_header_id
             , DOC_RECORD_HEADER_ID = a_doc_record_header_id
             , DOC_RECORD_ID = a_doc_record_header_id
             , PNT_NOM_PATH = to_char(a_doc_record_id) || '-' || to_char(a_gco_good_header_id)
             , NOM_VERSION = v_nomP_version   --decode(v_update_info_good,'Y',v_nomP_version,NOM_VERSION)
             , PNT_PLAN_NUMBER = decode(v_update_info_good, 'Y', v_plan_number, PNT_PLAN_NUMBER)
             , PNT_PLAN_VERSION = decode(v_update_info_good, 'Y', v_plan_version, PNT_PLAN_VERSION)
             , GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO_CHARACTERIZATION_ID, GCO_CHARACTERIZATION_ID)
             , GCO_GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO_GCO_CHARACTERIZATION_ID, GCO_GCO_CHARACTERIZATION_ID)
             , GCO2_GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO2_GCO_CHARACTERIZATION_ID, GCO2_GCO_CHARACTERIZATION_ID)
             , GCO3_GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO3_GCO_CHARACTERIZATION_ID, GCO3_GCO_CHARACTERIZATION_ID)
             , GCO4_GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO4_GCO_CHARACTERIZATION_ID, GCO4_GCO_CHARACTERIZATION_ID)
             , PNT_CHARACTERIZATION_VALUE_1 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_1)
             , PNT_CHARACTERIZATION_VALUE_2 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_2)
             , PNT_CHARACTERIZATION_VALUE_3 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_3)
             , PNT_CHARACTERIZATION_VALUE_4 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_4)
             , PNT_CHARACTERIZATION_VALUE_5 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_5)
             , PNT_DEL_COMP = 0
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = a_date_cre
         where PPS_NOMENCLATURE_HEADER_ID = a_pps_nomenclature_header_id
           and DOC_RECORD_HEADER_ID = a_doc_record_header_id
           and DOC_RECORD_ID = a_doc_record_header_id
           and GCO_GOOD_ID = a_gco_good_header_id
           and PNT_NOM_PATH = to_char(a_doc_record_id) || '-' || to_char(a_gco_good_header_id)
           and PPS_NOM_BOND_ID is null;
      exception
        when no_data_found then
          --Creation tête
          begin   --Affaire
            select trim(rpad(PRJ_PLAN_NUMBER, 60) )
                 , trim(rpad(PRJ_PLAN_VERSION, 60) )
              into v_plan_number
                 , v_plan_version
              from GAL_PROJECT PRJ
             where PRJ.DOC_RECORD_ID = a_doc_record_header_id;
          exception
            when no_data_found then
              begin   --budget
                select trim(rpad(BDG_PLAN_NUMBER, 60) )
                     , trim(rpad(BDG_PLAN_VERSION, 60) )
                  into v_plan_number
                     , v_plan_version
                  from GAL_BUDGET BDG
                 where BDG.DOC_RECORD_ID = a_doc_record_header_id;
              exception
                when no_data_found then
                  begin   --Defaut article
                    select trim(rpad(CMA_PLAN_NUMBER, 60) )
                         , trim(rpad(CMA_PLAN_VERSION, 60) )
                      into v_plan_number
                         , v_plan_version
                      from GCO_COMPL_DATA_MANUFACTURE
                     where CMA_DEFAULT = 1
                       and GCO_GOOD_ID = a_gco_good_header_id;
                  exception
                    when no_data_found then
                      v_plan_number   := null;
                      v_plan_version  := null;
                  end;
              end;
          end;

          init_characterization(a_gco_good_header_id);

          begin
            select nom_version
              into v_nom_version
              from pps_nomenclature pps
             where pps.pps_nomenclature_id = a_pps_nomenclature_header_id;
          exception
            when no_data_found then
              v_nom_version  := null;
          end;

          --Creation de la tête
          select INIT_ID_SEQ.nextval
            into vNEWNID   /* Génération d'un nouvel Id nomenclature Sav */
            from dual;

          insert into pps_nom_tracability
                      (PPS_NOM_TRACABILITY_ID
                     , GCO_GOOD_ID
                     , DOC_RECORD_ID
                     , DOC_RECORD_HEADER_ID
                     , PNT_NOM_PATH
                     , PNT_NOM_PATH_NO_SEQ
                     , PNT_NOM_LEVEL
                     ,
                       --PPS_NOMENCLATURE_ID,
                       PPS_PPS_NOMENCLATURE_ID
                     , PPS_NOMENCLATURE_HEADER_ID
                     , NOM_VERSION
                     , PNT_PLAN_NUMBER
                     , PNT_PLAN_VERSION
                     , PNT_INDEX
                     , GCO_CHARACTERIZATION_ID
                     , GCO_GCO_CHARACTERIZATION_ID
                     , GCO2_GCO_CHARACTERIZATION_ID
                     , GCO3_GCO_CHARACTERIZATION_ID
                     , GCO4_GCO_CHARACTERIZATION_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (vNEWNID
                     , a_gco_good_header_id
                     , a_doc_record_header_id
                     , a_doc_record_header_id
                     , to_char(a_doc_record_id) || '-' || to_char(a_gco_good_header_id)
                     ,
                       --to_char(a_doc_record_id) || '-' || to_char(a_gco_good_header_id),
                       to_char(a_gco_good_header_id)
                     , 1
                     ,
                       --a_pps_nomenclature_header_id,
                       a_pps_nomenclature_header_id
                     , a_pps_nomenclature_header_id
                     , v_nom_version
                     , v_plan_number
                     , v_plan_version
                     , a_idx
                     , v_GCO_CHARACTERIZATION_ID
                     , v_GCO_GCO_CHARACTERIZATION_ID
                     , v_GCO2_GCO_CHARACTERIZATION_ID
                     , v_GCO3_GCO_CHARACTERIZATION_ID
                     , v_GCO4_GCO_CHARACTERIZATION_ID
                     , a_date_cre
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
      end;
    end Create_Header;

--***********************************************************************************************************--
--***********************************************************************************************************--
    procedure Create_Art_directeur
    is
      v_nomT_version PPS_NOM_TRACABILITY.NOM_VERSION%type;
      v_nomP_version PPS_NOM_TRACABILITY.NOM_VERSION%type;
      v_parent_path  PPS_NOM_TRACABILITY.PNT_NOM_PATH%type;
      v_is_new_comp  PPS_NOM_TRACABILITY.PNT_NEW_COMP%type;
    begin
      begin
        /*Voir si archiver la ligne ...sur la base de la sequence/article par exemple....si nomenc sav*/

        --Controle si existe pas déjà tête article directeur
        select PPS_NOM_TRACABILITY_ID
             , PNT_INDEX
             , NOM_VERSION
          into v_existid
             , v_idx
             , v_nomT_version
          from PPS_NOM_TRACABILITY
         where DOC_RECORD_HEADER_ID in(a_doc_record_id, tsk_doc_record_header_id)
           and DOC_RECORD_ID = a_doc_record_id
           and GCO_GOOD_ID = a_gco_good_id
           and PNT_INDEX = a_Idx
           and gal_task_good_id = a_task_good_id
           and a_task_good_id is not null
           and PNT_NOM_PATH like '%' || a_gco_good_id
           and rownum = 1;

        begin   --> Si nomenclature sav, on ne met plus à jour les infos caracterisations,plan...
          select decode(nom_version, v_nomT_version, 'N', 'Y')
               , nom_version
            into v_update_info_good
               , v_nomP_version
            from pps_nomenclature pps
           where pps.pps_nomenclature_id = a_pps_nomenclature_id
             and pps.doc_record_id = a_doc_record_id;   --> Passage Sav
        exception
          when no_data_found then
            begin
              select decode(nom_version, v_nomT_version, 'N', 'Y')
                   , nom_version
                into v_update_info_good
                   , v_nomP_version
                from pps_nomenclature pps
               where pps.pps_nomenclature_id = a_pps_nomenclature_id;
            exception
              when no_data_found then
                v_update_info_good  := 'Y';
                v_nomP_version      := v_nomT_version;
            end;
        end;

        if (nvl(v_nomP_version, ' ') ) <>(nvl(v_nomT_version, ' ') ) then
          write_history(53, v_existid, v_nomT_version, v_nomP_version);
        end if;

        if v_update_info_good = 'Y' then
          init_info_gco;
          init_characterization(a_gco_good_id);
        end if;

        --Existe path = update...
        update PPS_NOM_TRACABILITY
           set PPS_NOMENCLATURE_HEADER_ID = nvl(tsk_pps_nomenclature_header_id, a_pps_nomenclature_id)
             , DOC_RECORD_HEADER_ID = nvl(tsk_doc_record_header_id, a_doc_record_id)
             , DOC_RECORD_ID = a_doc_record_id
             , GAL_TASK_GOOD_ID = a_task_good_id
             , GAL_TASK_ID = v_task_id
             --,PNT_NOM_PATH = decode(a_doc_record_header_id,null,null,to_char(a_doc_record_header_id) || '-' || lpad(to_char(a_seq),10,'0') || '-' || to_char(a_gco_good_header_id) || '/') || lpad(to_char(a_seq),10,'0') || '-' || to_char(a_gco_good_id)
        ,      PNT_NOM_PATH =
                 decode(tsk_doc_record_header_id, null, null, to_char(tsk_doc_record_header_id) || '-' || to_char(tsk_gco_good_header_id) || '/') ||
                 lpad(to_char(a_seq), 10, '0') ||
                 '-' ||
                 to_char(a_gco_good_id)
             , PNT_NOM_PATH_NO_SEQ = decode(tsk_doc_record_header_id, null, null, to_char(tsk_gco_good_header_id) || '/') || to_char(a_gco_good_id)
             , NOM_VERSION = v_nomP_version   --decode(v_update_info_good,'Y',v_nomP_version,NOM_VERSION)
             , PNT_PLAN_NUMBER = decode(v_update_info_good, 'Y', v_plan_number, PNT_PLAN_NUMBER)
             , PNT_PLAN_VERSION = decode(v_update_info_good, 'Y', v_plan_version, PNT_PLAN_VERSION)
             , PPS_NOMENCLATURE_ID = tsk_pps_nomenclature_header_id
             , PPS_PPS_NOMENCLATURE_ID = a_pps_nomenclature_id
             , COM_SEQ = a_seq
             , GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO_CHARACTERIZATION_ID, GCO_CHARACTERIZATION_ID)
             , GCO_GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO_GCO_CHARACTERIZATION_ID, GCO_GCO_CHARACTERIZATION_ID)
             , GCO2_GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO2_GCO_CHARACTERIZATION_ID, GCO2_GCO_CHARACTERIZATION_ID)
             , GCO3_GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO3_GCO_CHARACTERIZATION_ID, GCO3_GCO_CHARACTERIZATION_ID)
             , GCO4_GCO_CHARACTERIZATION_ID = decode(v_update_info_good, 'Y', v_GCO4_GCO_CHARACTERIZATION_ID, GCO4_GCO_CHARACTERIZATION_ID)
             , PNT_CHARACTERIZATION_VALUE_1 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_1)
             , PNT_CHARACTERIZATION_VALUE_2 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_2)
             , PNT_CHARACTERIZATION_VALUE_3 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_3)
             , PNT_CHARACTERIZATION_VALUE_4 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_4)
             , PNT_CHARACTERIZATION_VALUE_5 = decode(v_update_info_good, 'Y', ' ', PNT_CHARACTERIZATION_VALUE_5)
             , PNT_DEL_COMP = 0
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = a_date_cre
         where   /*PPS_NOM_TRACABILITY_ID = v_existid;*/
               DOC_RECORD_HEADER_ID in(a_doc_record_id, tsk_doc_record_header_id)
           and DOC_RECORD_ID = a_doc_record_id
           and GCO_GOOD_ID = a_gco_good_id
           and a_task_good_id is not null
           and pnt_index = a_Idx
           and gal_task_good_id = a_task_good_id
           and PNT_NOM_PATH like '%' || a_gco_good_id;
      exception
        when no_data_found then
          select decode(tsk_doc_record_header_id, null, null, to_char(tsk_doc_record_header_id) || '-' || to_char(tsk_gco_good_header_id) )
            into v_parent_path
            from dual;

          if trim(v_parent_path) is not null then
            v_is_new_comp  := CheckNewComp(v_parent_path);
--DBMS_OUTPUT.PUT_LINE('Art Dir ' || to_char(v_is_new_comp) || ' ' || v_parent_path);
          else
            begin
              select NewComp
                into v_is_new_comp
                from (select   decode(a_datecre, a_date_cre, 0, 1) NewComp
                          from pps_nom_tracability
                         where doc_record_id = a_doc_record_id
                      order by A_DATEMOD asc)
               where rownum = 1;
            exception
              when no_data_found then
                v_is_new_comp  := 0;
            end;
          end if;

--DBMS_OUTPUT.PUT_LINE('Art Dir ' || to_char(v_is_new_comp));

          --Creation tête art directeur
          init_info_gco;
          init_characterization(a_gco_good_id);

          --Creation de la tête
          select INIT_ID_SEQ.nextval
            into vNEWNID   /* Génération d'un nouvel Id nomenclature Sav */
            from dual;

          insert into pps_nom_tracability
                      (PPS_NOM_TRACABILITY_ID
                     , GCO_GOOD_ID
                     , GAL_TASK_GOOD_ID
                     , GAL_TASK_ID
                     , DOC_RECORD_ID
                     , DOC_RECORD_HEADER_ID
                     , PNT_NOM_PATH
                     , PNT_NOM_PATH_NO_SEQ
                     , PNT_NOM_LEVEL
                     , PPS_NOMENCLATURE_ID
                     , PPS_PPS_NOMENCLATURE_ID
                     , PPS_NOMENCLATURE_HEADER_ID
                     , PNT_PLAN_NUMBER
                     , PNT_PLAN_VERSION
                     , PNT_INDEX
                     , PNT_NEW_COMP
                     , COM_SEQ
                     , NOM_VERSION
                     , GCO_CHARACTERIZATION_ID
                     , GCO_GCO_CHARACTERIZATION_ID
                     , GCO2_GCO_CHARACTERIZATION_ID
                     , GCO3_GCO_CHARACTERIZATION_ID
                     , GCO4_GCO_CHARACTERIZATION_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (vNEWNID
                     , a_gco_good_id
                     , a_task_good_id
                     , v_task_id
                     , a_doc_record_id
                     , nvl(tsk_doc_record_header_id, a_doc_record_id)
                     ,
                       --decode(a_doc_record_header_id,null,null,to_char(a_doc_record_header_id) || '-' || lpad(to_char(a_seq),10,'0') || '-' || to_char(a_gco_good_header_id) || '/') || lpad(to_char(a_seq),10,'0') || '-' || to_char(a_gco_good_id),
                       decode(tsk_doc_record_header_id, null, null, to_char(tsk_doc_record_header_id) || '-' || to_char(tsk_gco_good_header_id) || '/') ||
                       lpad(to_char(a_seq), 10, '0') ||
                       '-' ||
                       to_char(a_gco_good_id)
                     , decode(tsk_doc_record_header_id, null, null, to_char(tsk_gco_good_header_id) || '/') || to_char(a_gco_good_id)
                     , decode(tsk_gco_good_header_id, null, 1, 2)
                     , tsk_pps_nomenclature_header_id
                     ,   --pps = header oblig si il n'est pas renseigné alors update pour le croché...
                       a_pps_nomenclature_id
                     ,   --pps_pps
                       nvl(tsk_pps_nomenclature_header_id, a_pps_nomenclature_id)
                     , v_plan_number
                     , v_plan_version
                     , a_Idx
                     ,   --v_IDX,
                       v_is_new_comp
                     , a_seq
                     , v_nom_version
                     , v_GCO_CHARACTERIZATION_ID
                     , v_GCO_GCO_CHARACTERIZATION_ID
                     , v_GCO2_GCO_CHARACTERIZATION_ID
                     , v_GCO3_GCO_CHARACTERIZATION_ID
                     , v_GCO4_GCO_CHARACTERIZATION_ID
                     , a_date_cre
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
      end;
    end Create_Art_directeur;

--**********************************************************************************************************--
    procedure Check_Nomen
    is   --Controle si le bien est dans la nomenclature de tete (affaire ou budget..)
      --Si non, il n'est pas raccroché ....
      v_exist char(1);
    begin
      select '*'
        into v_exist
        from dual
       where a_gco_good_id in(select     bond.gco_good_id
                                    from pps_nom_bond bond
                              start with bond.pps_nomenclature_id = tsk_pps_nomenclature_header_id
                              connect by /*nocycle*/ prior bond.pps_pps_nomenclature_id = bond.pps_nomenclature_id);
--DBMS_OUTPUT.PUT_LINE('TEST ARTICLE >> ' || a_gco_good_id);
    exception
      when no_data_found then
        tsk_pps_nomenclature_header_id  := null;
        tsk_gco_good_header_id          := null;
        tsk_doc_record_header_id        := null;
    end;
--**********************************************************************************************************--
--**********************************************************************************************************--
  begin
    --> access -- 1=PPS 2=Aff/budget 3=Tâches 4=Descente complete pour maj lien
    tsk_pps_nomenclature_header_id  := a_pps_nomenclature_header_id;
    tsk_gco_good_header_id          := a_gco_good_header_id;
    tsk_doc_record_header_id        := a_doc_record_header_id;

    /*Creation des entetes affaire/budget ou instalaltion*/
    if    a_acc = 2   --affaire ou budget
       or a_acc = 1   --Pps
                   then
      DBMS_OUTPUT.PUT_LINE('A ' || to_char(sysdate, 'DD/MM/YYYY HH-MI-SS') );
      Create_Header;
    else
      v_level_indent  := 0;
    end if;

    /*Fin Creation des entetes*/

    /*  Debranché pour l'instant

      if a_acc = 4 --Descente pour maj des liens articles directeurs
      then
        v_from_art_dir := 'N';
        update pps_nom_tracability set pnt_used_comp = 0 where doc_record_header_id = a_doc_record_header_id;
        x_pps_nomenclature_id := a_pps_nomenclature_header_id;

        --On debranche la descente complete de nomenclature .... on fait un simple update

        update pps_nom_tracability set doc_record_header_id = a_doc_record_header_id
                                     , pps_nomenclature_header_id = a_pps_nomenclature_header_id
                       , pnt_nom_path = decode(instr(pnt_nom_path, to_char(a_doc_record_header_id) || '-' || to_char(a_gco_good_header_id) || '/')
                                               ,0, to_char(a_doc_record_header_id) || '-' || to_char(a_gco_good_header_id) || '/' || pnt_nom_path
                                     , pnt_nom_path)
                                       , pnt_nom_path_no_seq = decode(instr(pnt_nom_path_no_seq, to_char(a_gco_good_header_id) || '/')
                                                      ,0, to_char(a_gco_good_header_id) || '/' || pnt_nom_path_no_seq
                                            , pnt_nom_path_no_seq)
        where doc_record_id in (select gal_task.doc_record_id from gal_task--,gal_task_good
                                   where --gal_task.gal_task_id = gal_task_good.gal_task_id and
                            (gal_task.gal_project_id in (select gal_project_id from gal_project where gal_project.doc_record_id = a_doc_record_header_id)
                       or    gal_task.gal_budget_id in (select gal_budget_id from gal_budget where gal_budget.doc_record_id = a_doc_record_header_id)))
        and a_doc_record_header_id is not null;

    --> Debranché pour l'instant   ... > Create_traca_nomenclature;

      end if;
    */
    if a_acc = 3   --Taches
                then
--> Debranché pour l'instant   ... >    if tsk_pps_nomenclature_header_id is not null then Check_Nomen; end if;
      DBMS_OUTPUT.PUT_LINE('B ' || to_char(sysdate, 'DD/MM/YYYY HH-MI-SS') );
      Create_Art_Directeur;
    end if;

    if    a_acc = 3   --Taches
       or a_acc = 1   --Pps
                   then
      if a_acc = 3 then
        v_from_art_dir  := 'Y';
      else
        v_from_art_dir  := 'N';
      end if;

      if tsk_gco_good_header_id is not null then
        v_level_indent  := 1;
      end if;

      if a_acc = 1 then
        v_level_indent  := 0;
      end if;

      x_pps_nomenclature_id  := a_pps_nomenclature_id;
--DBMS_OUTPUT.PUT_LINE('X ' || to_char(sysdate,'DD/MM/YYYY HH-MI-SS'));
      Create_traca_nomenclature;
    end if;
  end generate_nom_tracability_unit;
begin
  null;
end pps_nom_tracability_functions;
