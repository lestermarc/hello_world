--------------------------------------------------------
--  DDL for Package Body GAL_PROJECT_DUPLICATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PROJECT_DUPLICATION" 
is
  function getPathFromPriorBudget(
    a_duplicate_fathers GAL_BUDGET_DUPLICATE.GBD_DUPLICATE_FATHERS%type
  , a_duplicate_sons    GAL_BUDGET_DUPLICATE.GBD_DUPLICATE_SONS%type
  , a_duplicate_code    GAL_BUDGET_DUPLICATE.BDG_CODE%type
  , a_duplicate_pref    GAL_BUDGET_DUPLICATE.GBD_PREFIX%type
  , a_gal_budget_id     GAL_BUDGET.GAL_BUDGET_ID%type
  , a_gal_project_id    GAL_BUDGET.GAL_PROJECT_ID%type
  )
    return varchar2
  is
    v_result varchar2(1000);
  begin
    select     decode(a_duplicate_fathers, 0,('/' || a_duplicate_pref || a_duplicate_code), sys_connect_by_path(a_duplicate_pref || X.BDG_CODE, '/') )
          into v_result
          from GAL_BUDGET X
         where X.GAL_BUDGET_ID = a_gal_budget_id
    connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID
    start with X.GAL_PROJECT_ID = a_gal_project_id
           and GAL_FATHER_BUDGET_ID is null;

    select substr(v_result, 1, instr(v_result, '/', -1) ) || a_duplicate_pref || a_duplicate_code || decode(a_duplicate_sons, 0, '', '/...')
      into v_result
      from dual;

    return(v_result);
  exception
    when no_data_found then
      return('/' || a_duplicate_pref || a_duplicate_code);
  end getPathFromPriorBudget;

--**********************************************************************************************************--
  procedure insert_budget(
    v_gal_project_id_source gal_project.gal_project_id%type
  , v_gal_project_id_cible  gal_project.gal_project_id%type
  , a_dup_com_bud           integer
  , a_dup_des_bud           integer
  , a_prefix_bud            varchar2
  , a_dup_line              integer
  , a_dup_com_line          integer
  , a_dup_des_line          integer
  )
  is
    v_rec_budget    gal_budget%rowtype;
    v_father_id     gal_budget.gal_budget_id%type;
    v_exist         char(1);
    a_new_budget_id gal_budget.gal_budget_id%type;

--**********************************************************************************************************--
    procedure common_budget(
      a_budget_id       GAL_BUDGET.GAL_BUDGET_ID%type
    , a_father_id       GAL_BUDGET.GAL_FATHER_BUDGET_ID%type
    , a_bdg_code        GAL_BUDGET.BDG_CODE%type
    , a_bdg_wording     GAL_BUDGET.BDG_WORDING%type
    , a_bdg_description GAL_BUDGET.BDG_DESCRIPTION%type
    , a_bdg_comment     GAL_BUDGET.BDG_COMMENT%type
    , a_budget_categ_id GAL_BUDGET.GAL_BUDGET_CATEGORY_ID%type
    , x_prefix_bud      GAL_BUDGET_DUPLICATE.GBD_PREFIX%type
    )
    is
--**********************************************************************************************************--
      procedure insert_budline
      is
        vHourlyRate          GAL_COST_HOURLY_RATE.GCH_HOURLY_RATE%type;
        vCount               integer;
        a_new_budget_line_id GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type;
      begin
        if     a_new_budget_id is not null
           and a_dup_line = 1 then
          for tplBudgetLine in (select *
                                  from GAL_BUDGET_LINE
                                 where GAL_BUDGET_ID = a_budget_id) loop
            --Recherche si le code n'existe pas déjà...
            select count(*)
              into vCount
              from GAL_BUDGET_LINE
             where GAL_BUDGET_ID = a_new_budget_id
               and GAL_COST_CENTER_ID = tplBudgetLine.GAL_COST_CENTER_ID
               and nvl(GAL_BUDGET_PERIOD_ID, -1) = nvl(tplBudgetLine.GAL_BUDGET_PERIOD_ID, -1);

            if vCount = 0 then
              vHourlyRate  := GAL_PROJECT_SPENDING.GET_HOURLY_RATE_FROM_NAT_ANA(tplBudgetLine.GAL_COST_CENTER_ID, sysdate, '00', v_gal_project_id_cible);

              if nvl(vHourlyRate, 0) <> 0 then
                tplBudgetLine.BLI_BUDGET_PRICE  := vHourlyRate;
              end if;

              --**DEVPRP-10169**--
              if    nvl(tplBudgetLine.BLI_BUDGET_QUANTITY, 0) = 0
                 or nvl(tplBudgetLine.BLI_BUDGET_PRICE, 0) = 0 then
                null;
              else
                tplBudgetLine.BLI_BUDGET_AMOUNT  := nvl(tplBudgetLine.BLI_BUDGET_QUANTITY, 0) * nvl(tplBudgetLine.BLI_BUDGET_PRICE, 0);
              end if;

              select init_id_seq.nextval
                into a_new_budget_line_id
                from dual;

              insert into GAL_BUDGET_LINE
                          (GAL_BUDGET_LINE_ID
                         , GAL_BUDGET_ID
                         , GAL_COST_CENTER_ID
                         , GAL_BUDGET_PERIOD_ID
                         , BLI_SEQUENCE
                         , BLI_WORDING
                         , BLI_DESCRIPTION
                         , BLI_COMMENT
                         , BLI_LAST_BUDGET_DATE
                         , BLI_REMAINING_QUANTITY
                         , BLI_REMAINING_PRICE
                         , BLI_REMAINING_AMOUNT
                         , BLI_HANGING_SPENDING_QUANTITY
                         , BLI_HANGING_SPENDING_AMOUNT
                         , BLI_HANGING_SPENDING_AMOUNT_B
                         , BLI_LAST_REMAINING_DATE
                         , BLI_LAST_ESTIMATION_QUANTITY
                         , BLI_LAST_ESTIMATION_AMOUNT
                         , BLI_BUDGET_QUANTITY
                         , BLI_BUDGET_PRICE
                         , BLI_BUDGET_AMOUNT
                         , BLI_CLOTURED
                         , A_IDCRE
                         , A_DATECRE
                         , A_IDMOD
                         , A_DATEMOD
                          )
                select a_new_budget_line_id as GAL_BUDGET_LINE_ID
                     , a_new_budget_id as GAL_BUDGET_ID
                     , tplBudgetLine.GAL_COST_CENTER_ID
                     , tplBudgetLine.GAL_BUDGET_PERIOD_ID
                     , tplBudgetLine.BLI_SEQUENCE
                     , tplBudgetLine.BLI_WORDING
                     , decode(a_dup_des_line, 1, tplBudgetLine.BLI_DESCRIPTION, 0, null, null) as BLI_DESCRIPTION
                     , decode(a_dup_com_line, 1, tplBudgetLine.BLI_COMMENT, 0, null, null) as BLI_COMMENT
                     , sysdate as BLI_LAST_BUDGET_DATE
                     , null as BLI_REMAINING_QUANTITY
                     , null as BLI_REMAINING_PRICE
                     , null as BLI_REMAINING_AMOUNT
                     , null as BLI_HANGING_SPENDING_QUANTITY
                     , null as BLI_HANGING_SPENDING_AMOUNT
                     , null as BLI_HANGING_SPENDING_AMOUNT_B
                     , null as BLI_LAST_REMAINING_DATE
                     , tplBudgetLine.BLI_BUDGET_QUANTITY as BLI_LAST_ESTIMATION_QUANTITY
                     , tplBudgetLine.BLI_BUDGET_AMOUNT as BLI_LAST_ESTIMATION_AMOUNT
                     , tplBudgetLine.BLI_BUDGET_QUANTITY as BLI_BUDGET_QUANTITY
                     , tplBudgetLine.BLI_BUDGET_PRICE as BLI_BUDGET_PRICE
                     , tplBudgetLine.BLI_BUDGET_AMOUNT as BLI_BUDGET_AMOUNT
                     , 0 as BLI_CLOTURED
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , sysdate
                     , null
                     , null
                  from dual;

              COM_VFIELDS.DuplicateVirtualField('GAL_BUDGET_LINE', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                                tplBudgetLine.GAL_BUDGET_LINE_ID, a_new_budget_line_id);
            end if;
          end loop;
        end if;
      end insert_budline;
    begin   --**MAIN COMMON**--
      --Recherche du budget père
      if a_father_id is not null then
        begin
          select A.GAL_BUDGET_ID
            into v_father_id
            from GAL_BUDGET A
           where A.GAL_PROJECT_ID = v_gal_project_id_cible
             and A.BDG_CODE = (select trim(x_prefix_bud) || B.BDG_CODE
                                 from GAL_BUDGET B
                                where B.GAL_BUDGET_ID = a_father_id);
        exception
          when no_data_found then
            v_father_id  := null;
        end;
      else
        v_father_id  := null;
      end if;

      begin   --Recherche si le code n'existe pas déjà...
        select '*'
             , GAL_BUDGET_ID
          into v_exist
             , a_new_budget_id
          from GAL_BUDGET
         where GAL_PROJECT_ID = v_gal_project_id_cible
           and BDG_CODE = x_prefix_bud || a_bdg_code;
      exception
        when no_data_found then
          v_exist          := ' ';
          a_new_budget_id  := null;
      end;

      if v_exist <> '*' then
        select init_id_seq.nextval
          into a_new_budget_id
          from dual;

        insert into GAL_BUDGET
                    (GAL_BUDGET_ID
                   , GAL_PROJECT_ID
                   , DOC_RECORD_ID
                   , C_BDG_STATE
                   , GAL_FATHER_BUDGET_ID
                   , BDG_CODE
                   , BDG_RESERVE
                   , BDG_WORDING
                   , BDG_HANGING_DATE
                   , BDG_OUTSTANDING_DATE
                   , BDG_BALANCE_DATE
                   , BDG_DESCRIPTION
                   , BDG_COMMENT
                   , GAL_BUDGET_CATEGORY_ID
                   , HRM_BUDGET_PERSON_ID
                   , HRM_BUDGET_TECHNICAL_PERSON_ID
                   , DIC_GAL_BDG_FREE_1_ID
                   , DIC_GAL_BDG_FREE_2_ID
                   , BDG_START_DATE
                   , BDG_END_DATE
                   , BDG_SORT_CRITERIA
                   , BDG_CODE_CONSOLIDATION_1
                   , BDG_CODE_CONSOLIDATION_2
                   , BDG_CODE_CONSOLIDATION_3
                   , BDG_CODE_CONSOLIDATION_4
                   , BDG_CODE_CONSOLIDATION_5
                   , BDG_CODE_CONSOLIDATION_6
                   , BDG_CODE_CONSOLIDATION_7
                   , BDG_CODE_CONSOLIDATION_8
                   , BDG_BOOLEAN_1
                   , BDG_BOOLEAN_2
                   , BDG_DATE_1
                   , BDG_DATE_2
                   , BDG_DATE_3
                   , BDG_DATE_4
                   , A_IDCRE
                   , A_DATECRE
                   , A_IDMOD
                   , A_DATEMOD
                    )
          select a_new_budget_id as GAL_BUDGET_ID
               , v_gal_project_id_cible as GAL_PROJECT_ID
               , null as DOC_RECORD_ID
               , '10' as C_BDG_STATE
               , v_father_id as GAL_FATHER_BUDGET_ID
               , x_prefix_bud || a_bdg_code as BDG_CODE
               , BDG.BDG_RESERVE
               , a_bdg_wording as BDG_WORDING
               , null as BDG_HANGING_DATE
               , null as BDG_OUTSTANDING_DATE
               , null as BDG_BALANCE_DATE
               , decode(a_dup_des_bud, 1, a_bdg_description, 0, null, null) as BDG_DESCRIPTION
               , decode(a_dup_com_bud, 1, a_bdg_comment, 0, null, null) as BDG_COMMENT
               , a_budget_categ_id as GAL_BUDGET_CATEGORY_ID
               , BDG.HRM_BUDGET_PERSON_ID
               , BDG.HRM_BUDGET_TECHNICAL_PERSON_ID
               , BDG.DIC_GAL_BDG_FREE_1_ID
               , BDG.DIC_GAL_BDG_FREE_2_ID
               , null as BDG_START_DATE
               , null as BDG_END_DATE
               , BDG.BDG_SORT_CRITERIA
               , BDG.BDG_CODE_CONSOLIDATION_1
               , BDG.BDG_CODE_CONSOLIDATION_2
               , BDG.BDG_CODE_CONSOLIDATION_3
               , BDG.BDG_CODE_CONSOLIDATION_4
               , BDG.BDG_CODE_CONSOLIDATION_5
               , BDG.BDG_CODE_CONSOLIDATION_6
               , BDG.BDG_CODE_CONSOLIDATION_7
               , BDG.BDG_CODE_CONSOLIDATION_8
               , BDG.BDG_BOOLEAN_1
               , BDG.BDG_BOOLEAN_2
               , BDG.BDG_DATE_1
               , BDG.BDG_DATE_2
               , BDG.BDG_DATE_3
               , BDG.BDG_DATE_4
               , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
               , sysdate as A_DATECRE
               , null as A_IDMOD
               , null as A_DATEMOD
            from GAL_BUDGET BDG
           where BDG.GAL_BUDGET_ID = a_budget_id;

        COM_VFIELDS.DuplicateVirtualField('GAL_BUDGET', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                          a_budget_id, a_new_budget_id);
      end if;

      insert_budline;
    end common_budget;

--**********************************************************************************************************--
--**********************************************************************************************************--
    procedure insert_budget_duplicate
    is
      v_rec_budget_fils     GAL_BUDGET%rowtype;
      v_id                  varchar2(100);
      v_id_pere             varchar2(100);
      v_path_id             varchar2(2000);
      v_path_code           varchar2(2000);
      v_dup_id              GAL_BUDGET.GAL_BUDGET_ID%type;
      v_nivo                number;
      v_prj_id_source       GAL_BUDGET.GAL_PROJECT_ID%type;
      v_dup_budget_id       GAL_BUDGET_DUPLICATE.GAL_BUDGET_ID%type;
      v_bdg_description     GAL_BUDGET.BDG_DESCRIPTION%type;
      v_bdg_comment         GAL_BUDGET.BDG_COMMENT%type;
      v_dup_bdg_description GAL_BUDGET.BDG_DESCRIPTION%type;
      v_dup_bdg_comment     GAL_BUDGET.BDG_COMMENT%type;
      v_budget_categ_id     GAL_BUDGET.GAL_BUDGET_CATEGORY_ID%type;
      v_dup_budget_categ_id GAL_BUDGET.GAL_BUDGET_CATEGORY_ID%type;
      v_bdg_code            GAL_BUDGET.BDG_CODE%type;
      v_dup_bdg_code        GAL_BUDGET.BDG_CODE%type;
      v_bdg_wording         GAL_BUDGET.BDG_WORDING%type;
      v_dup_bdg_wording     GAL_BUDGET.BDG_WORDING%type;
      v_dup_fathers         GAL_BUDGET_DUPLICATE.GBD_DUPLICATE_FATHERS%type;
      v_dup_sons            GAL_BUDGET_DUPLICATE.GBD_DUPLICATE_SONS%type;
      v_pref                GAL_BUDGET_DUPLICATE.GBD_PREFIX%type;

      cursor C_BUD_DUPLICATE
      is
        select DUP.GAL_BUDGET_ID
             , DUP.BDG_CODE
             , DUP.BDG_WORDING
             , DUP.GBD_DUPLICATE_FATHERS
             , DUP.GBD_DUPLICATE_SONS
             , DUP.GBD_PREFIX
             , BUD.BDG_COMMENT
             , BUD.BDG_DESCRIPTION
             , BUD.GAL_BUDGET_CATEGORY_ID
          from GAL_BUDGET BUD
             , GAL_BUDGET_DUPLICATE DUP
         where BUD.GAL_BUDGET_ID = DUP.GAL_BUDGET_ID;

      cursor C_BUD
      is
        select     *
              from GAL_BUDGET
        connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID
        start with GAL_BUDGET_ID = v_dup_budget_id
          order siblings by BDG_CODE;
    begin
      open C_BUD_DUPLICATE;

      loop
        fetch C_BUD_DUPLICATE
         into v_dup_budget_id
            , v_dup_bdg_code
            , v_dup_bdg_wording
            , v_dup_fathers
            , v_dup_sons
            , v_pref
            , v_dup_bdg_comment
            , v_dup_bdg_description
            , v_dup_budget_categ_id;

        exit when C_BUD_DUPLICATE%notfound;

        --***************** creation des pères ******************--
        if v_dup_fathers = 1 then
          begin
            select GAL_PROJECT_ID
              into v_prj_id_source
              from GAL_BUDGET
             where GAL_BUDGET_ID = v_dup_budget_id;

            select     'NULL' || sys_connect_by_path(GAL_BUDGET_ID, '/') || '/'
                     , GAL_BUDGET_ID
                     , level
                  into v_path_id
                     , v_dup_id
                     , v_nivo
                  from GAL_BUDGET
                 where GAL_BUDGET_ID = v_dup_budget_id
            connect by prior GAL_BUDGET_ID = GAL_FATHER_BUDGET_ID
            start with GAL_PROJECT_ID = v_prj_id_source
                   and GAL_FATHER_BUDGET_ID is null
              order siblings by BDG_CODE;

            for cpt in 1 .. v_nivo loop
              select trim(substr(v_path_id, instr(v_path_id, '/', 1, cpt) + 1, instr(v_path_id, '/', 1, cpt + 1) - instr(v_path_id, '/', 1, cpt) - 1) )
                into v_id
                from dual;

              if cpt = 1 then
                v_id_pere  := null;
              else
                select trim(substr(v_path_id, instr(v_path_id, '/', 1, cpt - 1) + 1
                                 , instr(v_path_id, '/', 1, cpt - 1 + 1) - instr(v_path_id, '/', 1, cpt - 1) - 1) )
                  into v_id_pere
                  from dual;
              end if;

              if cpt = v_nivo then
                v_bdg_code         := v_dup_bdg_code;
                v_bdg_wording      := v_dup_bdg_wording;
                v_bdg_description  := v_dup_bdg_description;
                v_bdg_comment      := v_dup_bdg_comment;
                v_budget_categ_id  := v_dup_budget_categ_id;
              else
                select BDG_CODE
                     , BDG_WORDING
                     , BDG_DESCRIPTION
                     , BDG_COMMENT
                     , GAL_BUDGET_CATEGORY_ID
                  into v_bdg_code
                     , v_bdg_wording
                     , v_bdg_description
                     , v_bdg_comment
                     , v_budget_categ_id
                  from GAL_BUDGET
                 where GAL_BUDGET_ID = v_id;
              end if;

              common_budget(v_id, v_id_pere, v_bdg_code, v_bdg_wording, v_bdg_description, v_bdg_comment, v_budget_categ_id, v_pref);
            end loop;
          exception
            when no_data_found then
              null;
          end;
        else   --pas de creation des pères
          common_budget(v_dup_budget_id, null, v_dup_bdg_code, v_dup_bdg_wording, v_dup_bdg_description, v_dup_bdg_comment, v_dup_budget_categ_id, v_pref);
        end if;

        --***************** creation des fils ******************--
        if v_dup_sons = 1 then
          open C_BUD;

          loop
            fetch C_BUD
             into v_rec_budget_fils;

            exit when C_BUD%notfound;

            if v_dup_budget_id <> v_rec_budget_fils.GAL_BUDGET_ID then
              common_budget(v_rec_budget_fils.GAL_BUDGET_ID
                          , v_rec_budget_fils.GAL_FATHER_BUDGET_ID
                          , v_rec_budget_fils.BDG_CODE
                          , v_rec_budget_fils.BDG_WORDING
                          , v_rec_budget_fils.BDG_DESCRIPTION
                          , v_rec_budget_fils.BDG_COMMENT
                          , v_rec_budget_fils.GAL_BUDGET_CATEGORY_ID
                          , v_pref
                           );
            end if;
          end loop;

          close C_BUD;
        else   --pas de creation des fils
          null;   --Creer au niveau de la selection des peres
        end if;
      end loop;

      close C_BUD_DUPLICATE;
    end insert_budget_duplicate;
--******************************************MAIN BUDGET **************************************************--
  begin
    insert_budget_duplicate;   --TABLE TEMPORAIRE
  end insert_budget;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure insert_task(
    v_gal_project_id_source gal_project.gal_project_id%type
  , v_gal_project_id_cible  gal_project.gal_project_id%type
  , a_dup_com_tac           integer
  , a_dup_des_tac           integer
  , a_dup_dat_tac           integer
  , a_dup_com_ope           integer
  , a_dup_des_ope           integer
  , a_dup_dat_ope           integer
  , a_dup_com_art           integer
  , a_dup_des_art           integer
  , a_dup_ope               integer
  , a_dup_art               integer
  , a_prefix_tac            varchar2
  , a_prefix_ope            number
  , a_qte_mult_ope          number
  , a_qte_mult_art          number
  , a_dup_com_bud           integer
  , a_dup_des_bud           integer
  , a_prefix_bud            varchar2
  , a_dup_line              integer
  , a_dup_com_line          integer
  , a_dup_des_line          integer
  , a_manufacture_task_id   GAL_TASK.GAL_TASK_ID%type
  , a_destination_task_id   GAL_TASK.GAL_TASK_ID%type
  , a_budget_id             GAL_BUDGET.GAL_BUDGET_ID%type
  , a_acces                 integer default 0
  ,   -- 0 duplication complexe affaire / 1 copie de DF (delphi)
    b_dup_ens               integer
  , b_dup_com_ens           integer
  , b_dup_des_ens           integer
  , a_qte_mult_ens          number
  , a_tas_code              GAL_TASK.TAS_CODE%type
  )
  is
    a_new_task_id gal_task.gal_task_id%type;
    v_rec_task    gal_task%rowtype;
    v_budget_id   gal_budget.gal_budget_id%type;

--******************************************COMMON TASK **************************************************--
    procedure common_task(
      x_task_id     GAL_TASK.GAL_TASK_ID%type
    , x_tas_code    GAL_TASK.TAS_CODE%type
    , x_tas_wording GAL_TASK.TAS_WORDING%type
    , x_prefix_tac  GAL_TASK_DUPLICATE.GTD_PREFIX%type
    , a_budget_id   GAL_BUDGET.GAL_BUDGET_ID%type
    )
    is
    begin
      select init_id_seq.nextval
        into a_new_task_id
        from dual;

      --SELECT gal_budget_id into v_budget_id FROM GAL_BUDGET WHERE BDG_CODE = (SELECT BDG_CODE --!!!!!CHECKER!!!!!!!
      --                                                                        FROM GAL_BUDGET WHERE GAL_BUDGET_ID = v_rec_task.gal_budget_id
      --                                   )
      --                            AND GAL_PROJECT_ID = v_gal_project_id_cible;
      if a_budget_id is null then
        select gal_budget_id
          into v_budget_id
          from GAL_BUDGET
         where BDG_CODE = (select GBD_PREFIX || BDG_CODE
                             from GAL_BUDGET_DUPLICATE
                            where GAL_BUDGET_ID = (select GAL_BUDGET_ID
                                                     from GAL_TASK
                                                    where GAL_TASK_ID = x_task_id) )
           and GAL_PROJECT_ID = v_gal_project_id_cible;
      else
        v_budget_id  := a_budget_id;
      end if;

      insert into gal_task
                  (gal_task_id
                 , gal_task_category_id
                 , gal_project_id
                 , gco_good_id
                 , c_tas_state
                 , tas_code
                 , tas_wording
                 , tas_start_date
                 , tas_end_date
                 , tas_consolidation_code_1
                 , tas_consolidation_code_2
                 , tas_priority
                 , tas_launching_date
                 , tas_actual_start_date
                 , tas_balance_date
                 , tas_hanging_date
                 , tas_plan_number
                 , tas_product_identification
                 , tas_quantity
                 , tas_description
                 , tas_comment
                 , tas_task_must_be_launch
                 , a_idcre
                 , a_datecre
                 , a_datemod
                 , a_idmod
                 , hrm_task_person_id
                 , doc_record_id
                 , gal_budget_id
                 , gal_father_task_id
                 , tas_task_prepared
                  )
           values (a_new_task_id
                 , v_rec_task.gal_task_category_id
                 , v_gal_project_id_cible
                 , v_rec_task.gco_good_id
                 , '10'
                 , x_prefix_tac || x_tas_code
                 , x_tas_wording
                 , decode(a_dup_dat_tac, 1, v_rec_task.tas_start_date, 0, null, null)
                 , decode(a_dup_dat_tac, 1, v_rec_task.tas_end_date, 0, null, null)
                 , v_rec_task.tas_consolidation_code_1
                 , v_rec_task.tas_consolidation_code_2
                 , v_rec_task.tas_priority
                 , null   --TAS_LAUNCHING_DATE
                 , null   --TAS_ACTUAL_START_DATE
                 , null   --TAS_BALANCE_DATE
                 , null   --TAS_HANGING_DATE
                 , v_rec_task.tas_plan_number
                 , v_rec_task.tas_product_identification
                 , v_rec_task.tas_quantity
                 , decode(a_dup_des_tac, 1, v_rec_task.tas_description, 0, null, null)
                 , decode(a_dup_com_tac, 1, v_rec_task.tas_comment, 0, null, null)
                 , null   --TAS_TASK_MUST_BE_LAUNCH
                 , pcs.PC_I_LIB_SESSION.getuserini
                 , sysdate
                 , null   --A_DATEMOD
                 , null   --A_IDMOD
                 , v_rec_task.hrm_task_person_id
                 , null
                 ,   --DOC_RECORD
                   v_budget_id
                 , decode(a_destination_task_id, null, null, a_destination_task_id)
                 , 0
                  );

      COM_VFIELDS.DuplicateVirtualField('GAL_TASK', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                        v_rec_task.gal_task_id, a_new_task_id);

      if a_dup_ope = 1 then
        insert_operation(v_rec_task.gal_task_id, a_new_task_id, a_dup_com_ope, a_dup_des_ope, a_dup_dat_ope, a_prefix_ope, a_qte_mult_ope, a_acces);
      end if;

      if a_dup_art = 1 then
        insert_article_directeur(v_rec_task.gal_task_id, a_new_task_id, a_dup_com_art, a_dup_des_art, a_qte_mult_art);
      end if;

      if    a_acces = 1
         or b_dup_ens = 1   --(copie df ou copie complexe affaire)
                         then
        insert_lot(v_rec_task.gal_task_id, a_new_task_id, b_dup_com_ens, b_dup_des_ens, a_qte_mult_ens, a_acces);
      end if;

      if a_acces = 1 then
        insert_lot_link(v_rec_task.gal_task_id, a_new_task_id);
      end if;
    end common_task;

--******************************************TABLE TEMPORAIRE **************************************************--
    procedure insert_task_duplicate
    is
      v_rec_task_duplicate GAL_TASK_DUPLICATE%rowtype;

      cursor C_TASK_DUPLICATE
      is
        select *
          from GAL_TASK_DUPLICATE;
    begin
      open C_TASK_DUPLICATE;

      loop
        fetch C_TASK_DUPLICATE
         into v_rec_task_duplicate;

        exit when C_TASK_DUPLICATE%notfound;

        begin
          select *
            into v_rec_task
            from GAL_TASK
           where GAL_TASK_ID = v_rec_task_duplicate.GAL_TASK_ID;

          common_task(v_rec_task_duplicate.GAL_TASK_ID, v_rec_task_duplicate.TAS_CODE, v_rec_task_duplicate.TAS_WORDING, v_rec_task_duplicate.GTD_PREFIX, null);
        exception
          when no_data_found then
            null;
        end;
      end loop;

      close C_TASK_DUPLICATE;
    end insert_task_duplicate;
--******************************************MAIN TASK **************************************************--
  begin
    if a_acces = 0 then
      insert_task_duplicate;   --TABLE TEMPORAIRE
    else
      begin
        select *
          into v_rec_task
          from GAL_TASK
         where GAL_TASK_ID = a_manufacture_task_id;

        common_task(null, a_tas_code, v_rec_task.TAS_WORDING, '', a_budget_id);
      exception
        when no_data_found then
          null;
      end;
    end if;
  end insert_task;

--**********************************************************************************************************--
--*************************** DUPLICATION DES DOSSIERS DE FABRICATION **************************************--
--**********************************************************************************************************--
  procedure duplicate_manufacture_task(
    a_manufacture_task_id GAL_TASK.GAL_TASK_ID%type
  , a_destination_task_id GAL_TASK.GAL_TASK_ID%type
  , a_tas_code            GAL_TASK.TAS_CODE%type
  )
  is
    v_gal_project_id GAL_PROJECT.GAL_PROJECT_ID%type;
    v_gal_budget_id  GAL_BUDGET.GAL_BUDGET_ID%type;
  begin
    gal_project_duplication.tab_index  := 0;
    gal_project_duplication.table_rowid_lot_link.delete;

    select gal_project_id
         , gal_budget_id
      into v_gal_project_id
         , v_gal_budget_id
      from GAL_TASK
     where gal_task_id = a_destination_task_id;

    gal_project_duplication.insert_task(v_gal_project_id_source   => null
                                      , v_gal_project_id_cible    => v_gal_project_id
                                      , a_dup_com_tac             => 1
                                      , a_dup_des_tac             => 1
                                      , a_dup_dat_tac             => 0   --date de tache
                                      , a_dup_com_ope             => 1
                                      , a_dup_des_ope             => 1
                                      , a_dup_dat_ope             => 0   --date ope
                                      , a_dup_com_art             => 1
                                      , a_dup_des_art             => 1
                                      , a_dup_ope                 => 1
                                      , a_dup_art                 => 1
                                      , a_prefix_tac              => ''   --prefixe tache
                                      , a_prefix_ope              => null   --prefixe ope
                                      , a_qte_mult_ope            => 1
                                      , a_qte_mult_art            => 1
                                      , a_dup_com_bud             => 1
                                      , a_dup_des_bud             => 1
                                      , a_prefix_bud              => ''   --prefixe budget
                                      , a_dup_line                => 1
                                      , a_dup_com_line            => 1
                                      , a_dup_des_line            => 1
                                      , a_manufacture_task_id     => a_manufacture_task_id
                                      , a_destination_task_id     => a_destination_task_id
                                      , a_budget_id               => v_gal_budget_id
                                      , a_acces                   => 1
                                      , b_dup_ens                 => 1
                                      , b_dup_com_ens             => 1
                                      , b_dup_des_ens             => 1
                                      , a_qte_mult_ens            => 1   --Compose DF = Sous-ensemble Mo --> Meme table GAL_TASK_LOT
                                      , a_tas_code                => a_tas_code   --acces 1 : copie dossier fab
                                       );
  exception
    when no_data_found then
      null;
  end duplicate_manufacture_task;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure insert_operation(
    v_task_id_source gal_task.gal_task_id%type
  , v_new_task_id    gal_task.gal_task_id%type
  , v_dup_com_ope    integer
  , v_dup_des_ope    integer
  , v_dup_dat_ope    integer
  , v_prefix         number
  , v_qte_mult       number
  , a_acces          integer default 0   -- 0 duplication complexe affaire / 1 copie de DF (delphi)
  )
  is
    v_rec_task_link    gal_task_link%rowtype;
    a_new_task_link_id gal_task_link.gal_task_link_id%type;
    v_new_hourly_rate  gal_task_link.tal_hourly_rate%type;
    v_sysdate          gal_task.TAS_LAUNCHING_DATE%type;

    cursor c_task_link
    is
      select *
        from gal_task_link
       where gal_task_link.gal_task_id = v_task_id_source;
  begin
    begin   --au cas ou ça change encore !
      select sysdate
        into v_sysdate
        from dual;
    exception
      when no_data_found then
        v_sysdate  := null;
    end;

    open c_task_link;

    loop
      fetch c_task_link
       into v_rec_task_link;

      exit when c_task_link%notfound;

      select init_id_seq.nextval
        into a_new_task_link_id
        from dual;

      if a_acces = 1 then
        gal_project_duplication.tab_index                                                                     := gal_project_duplication.tab_index + 1;
        gal_project_duplication.table_rowid_lot_link(gal_project_duplication.tab_index).old_gal_task_link_id  := v_rec_task_link.gal_task_link_id;
        gal_project_duplication.table_rowid_lot_link(gal_project_duplication.tab_index).new_gal_task_link_id  := a_new_task_link_id;
      end if;

      select nvl(GAL_PROJECT_SPENDING.GET_HOURLY_RATE_FROM_RESS_OPE(v_rec_task_link.gal_task_link_id
                                                                  , v_rec_task_link.fal_factory_floor_id
                                                                  , v_rec_task_link.fal_fal_factory_floor_id
                                                                  , v_rec_task_link.gal_task_id
                                                                  , v_sysdate
                                                                   )
               , 0
                )
        into v_new_hourly_rate
        from dual;

      insert into gal_task_link
                  (gal_task_link_id
                 , gal_task_id
                 , pps_tools1_id
                 , pps_tools2_id
                 , pps_tools3_id
                 , pps_tools4_id
                 , pps_tools5_id
                 , pps_tools6_id
                 , pps_tools7_id
                 , pps_tools8_id
                 , pps_tools9_id
                 , pps_tools10_id
                 , pps_tools11_id
                 , pps_tools12_id
                 , pps_tools13_id
                 , pps_tools14_id
                 , pps_tools15_id
                 , fal_task_id
                 , pps_operation_procedure_id
                 , pps_pps_operation_procedure_id
                 , c_tal_state
                 , c_relation_type
                 , fal_factory_floor_id
                 , fal_fal_factory_floor_id
                 , tal_num_units_allocated
                 , scs_num_work_operator
                 , scs_step_number
                 , scs_short_descr
                 , tal_begin_plan_date
                 , tal_end_plan_date
                 , tal_due_tsk
                 , tal_hourly_rate
                 , tal_achieved_tsk
                 , tal_tsk_balance
                 , tal_begin_real_date
                 , tal_end_real_date
                 , tal_balance_date
                 , tal_hanging_date
                 , scs_delay
                 , scs_transfert_time
                 , scs_plan_rate
                 , tal_ean_code
                 , scs_free_descr
                 , scs_long_descr
                 , c_task_type
                 , gco_gco_good_id
                 , pac_supplier_partner_id
                 , a_datecre
                 , a_idcre
                 , a_datemod
                 , a_idmod
                  )
           values (a_new_task_link_id
                 , v_new_task_id
                 , v_rec_task_link.pps_tools1_id
                 , v_rec_task_link.pps_tools2_id
                 , v_rec_task_link.pps_tools3_id
                 , v_rec_task_link.pps_tools4_id
                 , v_rec_task_link.pps_tools5_id
                 , v_rec_task_link.pps_tools6_id
                 , v_rec_task_link.pps_tools7_id
                 , v_rec_task_link.pps_tools8_id
                 , v_rec_task_link.pps_tools9_id
                 , v_rec_task_link.pps_tools10_id
                 , v_rec_task_link.pps_tools11_id
                 , v_rec_task_link.pps_tools12_id
                 , v_rec_task_link.pps_tools13_id
                 , v_rec_task_link.pps_tools14_id
                 , v_rec_task_link.pps_tools15_id
                 , v_rec_task_link.fal_task_id
                 , v_rec_task_link.pps_operation_procedure_id
                 , v_rec_task_link.pps_pps_operation_procedure_id
                 , '10'
                 , v_rec_task_link.c_relation_type
                 , v_rec_task_link.fal_factory_floor_id
                 , v_rec_task_link.fal_fal_factory_floor_id
                 , v_rec_task_link.tal_num_units_allocated
                 , v_rec_task_link.scs_num_work_operator
                 , to_number(to_char(v_prefix) || v_rec_task_link.scs_step_number)
                 , v_rec_task_link.scs_short_descr
                 , decode(v_dup_dat_ope, 1, v_rec_task_link.tal_begin_plan_date, 0, null, null)
                 , decode(v_dup_dat_ope, 1, v_rec_task_link.tal_end_plan_date, 0, null, null)
                 , v_qte_mult * v_rec_task_link.tal_due_tsk
                 , v_new_hourly_rate
                 , null
                 ,   --OPE_DONE_CHARGE
                   v_qte_mult * v_rec_task_link.tal_due_tsk
                 ,   --OPE_REMAINING_CHARGE
                   null
                 ,   --OPE_ACTUAL_START_DATE
                   null
                 ,   --OPE_ACTUAL_END_DATE
                   null
                 ,   --OPE_BALANCE_DATE
                   null
                 ,   --OPE_HANGING_DATE
                   v_rec_task_link.scs_delay
                 , v_rec_task_link.scs_transfert_time
                 , v_rec_task_link.scs_plan_rate
                 , null
                 ,   --OPE_EAN_CODE
                   decode(v_dup_com_ope, 1, v_rec_task_link.scs_free_descr, 0, null, null)
                 , decode(v_dup_des_ope, 1, v_rec_task_link.scs_long_descr, 0, null, null)
                 , v_rec_task_link.c_task_type
                 , v_rec_task_link.gco_gco_good_id
                 , v_rec_task_link.pac_supplier_partner_id
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.getuserini
                 , null
                 ,   --A_DATEMOD
                   null   --A_IDMOD)
                  );

      COM_VFIELDS.DuplicateVirtualField('GAL_TASK_LINK', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                        v_rec_task_link.gal_task_link_id, a_new_task_link_id);
    end loop;

    close c_task_link;
  end insert_operation;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure insert_article_directeur(
    v_task_id_source gal_task.gal_task_id%type
  , v_new_task_id    gal_task.gal_task_id%type
  , v_dup_com_art    integer
  , v_dup_des_art    integer
  , v_qte_mult       number
  )
  is
    v_rec_task_good    gal_task_good%rowtype;
    a_new_task_good_id gal_task_good.gal_task_good_id%type;

    cursor c_task_good
    is
      select *
        from GAL_TASK_GOOD
       where GAL_TASK_GOOD.gal_task_id = v_task_id_source;
  begin
    open c_task_good;

    loop
      fetch c_task_good
       into v_rec_task_good;

      exit when c_task_good%notfound;

      select init_id_seq.nextval
        into a_new_task_good_id
        from dual;

      insert into GAL_TASK_GOOD
                  (GAL_TASK_GOOD_ID
                 , GAL_TASK_ID
                 , GCO_GOOD_ID
                 , GML_SEQUENCE
                 , GML_QUANTITY
                 , GML_COMMENT
                 , GML_DESCRIPTION
                 , C_PROJECT_SUPPLY_MODE
                 , PPS_NOMENCLATURE_ID
                 , GML_PLAN_NUMBER
                 , GML_PLAN_VERSION
                 , A_IDCRE
                 , A_DATECRE
                 , A_IDMOD
                 , A_DATEMOD
                  )
           values (a_new_task_good_id
                 , v_new_task_id
                 , v_rec_task_good.GCO_GOOD_ID
                 , v_rec_task_good.GML_SEQUENCE
                 , v_qte_mult * v_rec_task_good.GML_QUANTITY
                 , decode(v_dup_com_art, 1, v_rec_task_good.GML_COMMENT, 0, null, null)
                 , decode(v_dup_des_art, 1, v_rec_task_good.GML_DESCRIPTION, 0, null, null)
                 , v_rec_task_good.C_PROJECT_SUPPLY_MODE
                 , v_rec_task_good.PPS_NOMENCLATURE_ID
                 , v_rec_task_good.GML_PLAN_NUMBER
                 , v_rec_task_good.GML_PLAN_VERSION
                 , pcs.PC_I_LIB_SESSION.getuserini
                 , sysdate
                 , null
                 , null
                  );

      COM_VFIELDS.DuplicateVirtualField('GAL_TASK_GOOD', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                        v_rec_task_good.gal_task_good_id, a_new_task_good_id);
    end loop;
  end insert_article_directeur;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure insert_lot_link(v_task_id_source gal_task.gal_task_id%type, v_new_task_id gal_task.gal_task_id%type)
  is
    v_new_link_id  GAL_TASK_LINK.GAL_TASK_LINK_ID%type;
    v_new_lot_id   GAL_TASK_LOT.GAL_TASK_LOT_ID%type;
    v_rec_lot_link GAL_TASK_LOT_LINK%rowtype;
    v_qty          number;
    j              number;
    k              number;

    cursor c_lot_link
    is
      select *
        from GAL_TASK_LOT_LINK
       where GAL_TASK_ID = v_task_id_source;
  begin
    open c_lot_link;

    loop
      fetch c_lot_link
       into v_rec_lot_link;

      exit when c_lot_link%notfound;
      v_new_link_id  := null;
      v_new_lot_id   := null;
      v_qty          := null;
      j              := 1;
      k              := 1;

      for i in 1 .. gal_project_duplication.tab_index loop
        if gal_project_duplication.table_rowid_lot_link(i).old_gal_task_link_id = v_rec_lot_link.gal_task_link_id then
          v_new_link_id  := gal_project_duplication.table_rowid_lot_link(i).new_gal_task_link_id;
          j              := i;
        end if;

        if gal_project_duplication.table_rowid_lot_link(i).old_gal_task_lot_id = v_rec_lot_link.gal_task_lot_id then
          v_new_lot_id  := gal_project_duplication.table_rowid_lot_link(i).new_gal_task_lot_id;
          k             := i;
        end if;

        if     v_new_link_id is not null
           and v_new_lot_id is not null then
          begin   --recup de la quantity du lot pour la premiere opération
            select gal_project_duplication.table_rowid_lot_link(k).gtl_quantity
              into v_qty
              from dual
             where gal_project_duplication.table_rowid_lot_link(j).old_gal_task_link_id =
                                                               (select gal_task_link_id
                                                                  from GAL_TASK_LINK
                                                                 where scs_step_number = (select min(SCS_STEP_NUMBER)
                                                                                            from GAL_TASK_LINK
                                                                                           where GAL_TASK_ID = v_task_id_source)
                                                                   and GAL_TASK_ID = v_task_id_source);
          exception
            when no_data_found then
              v_qty  := null;
          end;

          insert into GAL_TASK_LOT_LINK
                      (GAL_TASK_ID
                     , GAL_TASK_LINK_ID
                     , GAL_TASK_LOT_ID
                     , GLL_QUANTITY
                     , A_IDCRE
                     , A_DATECRE
                     , A_DATEMOD
                     , A_IDMOD
                      )
               values (v_new_task_id
                     , v_new_link_id
                     , v_new_lot_id
                     , v_qty
                     , pcs.PC_I_LIB_SESSION.getuserini
                     , sysdate
                     , null
                     , null
                      );

          exit;
        end if;
      end loop;
    end loop;

    close c_lot_link;
  end insert_lot_link;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure insert_lot(
    v_task_id_source gal_task.gal_task_id%type
  , v_new_task_id    gal_task.gal_task_id%type
  , v_dup_com_ens    integer
  , v_dup_des_ens    integer
  , v_qte_mult_ens   number
  , v_acces          integer
  )
  is
    v_rec_lot         GAL_TASK_LOT%rowtype;
    a_new_task_lot_id GAL_TASK_LOT.GAL_TASK_LOT_ID%type;

    cursor c_task_lot
    is
      select *
        from gal_task_lot
       where gal_task_lot.gal_task_id = v_task_id_source;
  begin
    open c_task_lot;

    loop
      fetch c_task_lot
       into v_rec_lot;

      exit when c_task_lot%notfound;

      select init_id_seq.nextval
        into a_new_task_lot_id
        from dual;

      if v_acces = 1 then   --**Copie DF**--
        gal_project_duplication.tab_index                                                                    := gal_project_duplication.tab_index + 1;
        gal_project_duplication.table_rowid_lot_link(gal_project_duplication.tab_index).old_gal_task_lot_id  := v_rec_lot.gal_task_lot_id;
        gal_project_duplication.table_rowid_lot_link(gal_project_duplication.tab_index).new_gal_task_lot_id  := a_new_task_lot_id;
        gal_project_duplication.table_rowid_lot_link(gal_project_duplication.tab_index).gtl_quantity         := v_rec_lot.gtl_quantity;
      end if;

      insert into GAL_TASK_LOT
                  (GAL_TASK_LOT_ID
                 , GAL_TASK_ID
                 , GCO_GOOD_ID
                 , GTL_SEQUENCE
                 , GTL_QUANTITY
                 , GTL_LOT_DELTA_QUANTITY
                 , GTL_PPS_NEED_QUANTITY
                 , GTL_SURPLUS_RESOURCE
                 , GTL_PLAN_NUMBER
                 , GTL_PLAN_VERSION
                 , GTL_COMMENT
                 , DTL_DESCRIPTION
                 , A_IDCRE
                 , A_DATECRE
                 , A_DATEMOD
                 , A_IDMOD
                  )
           values (a_new_task_lot_id
                 , v_new_task_id
                 , v_rec_lot.GCO_GOOD_ID
                 , v_rec_lot.GTL_SEQUENCE
                 , v_qte_mult_ens * v_rec_lot.GTL_QUANTITY
                 , v_qte_mult_ens * v_rec_lot.GTL_LOT_DELTA_QUANTITY
                 , v_qte_mult_ens * v_rec_lot.GTL_PPS_NEED_QUANTITY
                 , v_rec_lot.GTL_SURPLUS_RESOURCE
                 , v_rec_lot.GTL_PLAN_NUMBER
                 , v_rec_lot.GTL_PLAN_VERSION
                 , decode(v_dup_com_ens, 1, v_rec_lot.GTL_COMMENT, 0, null, null)
                 , decode(v_dup_des_ens, 1, v_rec_lot.DTL_DESCRIPTION, 0, null, null)
                 , pcs.PC_I_LIB_SESSION.getuserini
                 , sysdate
                 , null
                 , null
                  );

      COM_VFIELDS.DuplicateVirtualField('GAL_TASK_LOT', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                        v_rec_lot.gal_task_lot_id, a_new_task_lot_id);
    end loop;

    close c_task_lot;
  end insert_lot;

--**********************************************************************************************************--
  procedure Duplicate_ProjectForEstimate(
    a_gal_project_id_source        GAL_PROJECT.GAL_PROJECT_ID%type
  , a_prj_code_cible               GAL_PROJECT.PRJ_CODE%type default null
  , a_new_prj_id            in out GAL_PROJECT.GAL_PROJECT_ID%type
  )
  is
  begin
    delete from GAL_TASK_DUPLICATE;

    insert into GAL_TASK_DUPLICATE
                (GAL_TASK_ID
               , TAS_CODE
               , TAS_WORDING
               , A_DATECRE
               , A_IDCRE
               , GTD_PREFIX
                )
      (select GAL_TASK_ID
            , TAS_CODE
            , TAS_WORDING
            , sysdate
            , PCS.PC_I_LIB_SESSION.GetUserIni
            , null
         from GAL_TASK
        where GAL_FATHER_TASK_ID is null
          and GAL_PROJECT_ID = a_gal_project_id_source);

    delete from GAL_BUDGET_DUPLICATE;

    insert into GAL_BUDGET_DUPLICATE BDD
                (BDD.GAL_BUDGET_ID
               , BDD.GBD_PREFIX
               , BDD.BDG_CODE
               , BDD.BDG_WORDING
               , BDD.A_DATECRE
               , BDD.A_IDCRE
               , BDD.GBD_DUPLICATE_FATHERS
               , BDD.GBD_DUPLICATE_SONS
                )
      (select BDG.GAL_BUDGET_ID
            , null
            , upper(BDG.BDG_CODE)
            , BDG.BDG_WORDING
            , sysdate
            , PCS.PC_I_LIB_SESSION.GetUserIni
            , 1
            , 1
         from GAL_BUDGET BDG
        where BDG.GAL_PROJECT_ID = a_gal_project_id_source);

    Duplicate_Project(a_gal_project_id_source
                    , a_prj_code_cible
                    , 1   -- b_dup_tac                      integer
                    , 0   -- b_dup_ope                      integer
                    , 0   -- b_dup_art                      integer
                    , 1   -- b_dup_bud                      integer
                    , 1   -- b_dup_com_tac                  integer
                    , 0   -- b_dup_com_ope                  integer
                    , 0   -- b_dup_com_art                  integer
                    , 1   -- b_dup_com_bud                  integer
                    , 1   -- b_dup_des_tac                  integer
                    , 0   -- b_dup_des_ope                  integer
                    , 0   -- b_dup_des_art                  integer
                    , 1   -- b_dup_des_bud                  integer
                    , 0   -- b_dup_dat_tac                  integer
                    , 0   -- b_dup_dat_ope                  integer
                    , null   --a_prefix_tac                   varchar2
                    , 0   --a_prefix_ope                   number
                    , null   --a_prefix_bud                   varchar2
                    , 0   -- a_qte_mult_ope                 number
                    , 0   -- a_qte_mult_art                 number
                    , 0   -- b_dup_line                     integer
                    , 0   -- b_dup_com_line                 integer
                    , 0   -- b_dup_des_line                 integer
                    , 0   -- b_dup_ens                      integer
                    , 0   -- b_dup_com_ens                  integer
                    , 0   -- b_dup_des_ens                  integer
                    , 0   -- a_qte_mult_ens                 number
                    , a_new_prj_id
                     );
  end Duplicate_ProjectForEstimate;

--**********************************************************************************************************--
  procedure duplicate_project(
    a_gal_project_id_source        varchar2
  , a_prj_code_cible               gal_project.prj_code%type default null
  , b_dup_tac                      integer
  , b_dup_ope                      integer
  , b_dup_art                      integer
  , b_dup_bud                      integer
  , b_dup_com_tac                  integer
  , b_dup_com_ope                  integer
  , b_dup_com_art                  integer
  , b_dup_com_bud                  integer
  , b_dup_des_tac                  integer
  , b_dup_des_ope                  integer
  , b_dup_des_art                  integer
  , b_dup_des_bud                  integer
  , b_dup_dat_tac                  integer
  , b_dup_dat_ope                  integer
  , a_prefix_tac                   varchar2
  , a_prefix_ope                   number
  , a_prefix_bud                   varchar2
  , a_qte_mult_ope                 number
  , a_qte_mult_art                 number
  , b_dup_line                     integer
  , b_dup_com_line                 integer
  , b_dup_des_line                 integer
  , b_dup_ens                      integer
  , b_dup_com_ens                  integer
  , b_dup_des_ens                  integer
  , a_qte_mult_ens                 number
  , a_new_prj_id            in out number
  )
  is
    a_new_project_id gal_project.gal_project_id%type;
    v_bud_dupl       number;
    v_tac_dupl       number;
    v_new_project    integer                           := 0;
  begin
    if a_gal_project_id_source is not null   --AND a_prj_code_cible IS NOT NULL
                                          then
      begin
        select gal_project_id
          into a_new_project_id
          from gal_project
         where trim(prj_code) = trim(a_prj_code_cible)
           and rownum = 1;
      exception
        when no_data_found then
          select init_id_seq.nextval
            into a_new_project_id
            from dual;

          v_new_project  := 1;

          insert into gal_project
                      (gal_project_id
                     , c_prj_state
                     , dic_gal_prj_category_id
                     , prj_code
                     , prj_wording
                     , prj_code_group_1
                     , prj_code_group_2
                     , prj_code_group_3
                     , prj_code_consolidation_1
                     , prj_code_consolidation_2
                     , prj_code_classification
                     , prj_launching_date
                     , prj_delivery_date
                     , prj_balance_date
                     , prj_hanging_date
                     , prj_internal
                     , prj_forecast
                     , prj_msproject_location
                     , prj_customer_order_ref
                     , prj_customer_order_date
                     , prj_customer_delivery_date
                     , prj_product_idenfitication
                     , prj_sale_price
                     , prj_comment
                     , prj_description
                     , prj_budget_period
                     , a_idcre
                     , a_datecre
                     , a_datemod
                     , a_idmod
                     , hrm_project_person_id
                     , hrm_technical_person_id
                     , pac_custom_partner_id
                     , doc_record_id
                     , dic_gal_location_id
                     , dic_gal_product_line_id
                     , dic_gal_division_id
                     , prj_exclude_provision
                      )
            select a_new_project_id
                 , '10'
                 , dic_gal_prj_category_id
                 , a_prj_code_cible
                 , prj_wording
                 , prj_code_group_1
                 , prj_code_group_2
                 , prj_code_group_3
                 , prj_code_consolidation_1
                 , prj_code_consolidation_2
                 , prj_code_classification
                 , null   --PRJ_LAUNCHING_DATE
                 , null   --PRJ_DELIVERY_DATE
                 , null   --PRJ_BALANCE_DATE
                 , null   --PRJ_HANGING_DATE
                 , prj_internal
                 , prj_forecast
                 , prj_msproject_location
                 , null
                 , null
                 , null
                 , prj_product_idenfitication
                 , null
                 , prj_comment
                 , prj_description
                 , prj_budget_period
                 , pcs.PC_I_LIB_SESSION.getuserini
                 , sysdate
                 , null   --A_DATEMOD
                 , null   --A_IDMOD
                 , hrm_project_person_id
                 , hrm_technical_person_id
                 , null
                 , null   --DOC_RECORD_ID
                 , dic_gal_location_id
                 , dic_gal_product_line_id
                 , dic_gal_division_id
                 , nvl(prj_exclude_provision, 0)
              from gal_project
             where gal_project_id = a_gal_project_id_source;

          COM_VFIELDS.DuplicateVirtualField('GAL_PROJECT', null,   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                            a_gal_project_id_source, a_new_project_id);
      end;
    end if;

    --**********BUDGET DUPLICATE************--
    begin
      select count(*)
        into v_bud_dupl
        from GAL_BUDGET_DUPLICATE;

      if v_bud_dupl <> 0 then
        if GAL_LIB_PROJECT.GetProjectCurrency(iProjectID => a_gal_project_id_source) <> GAL_LIB_PROJECT.GetProjectCurrency(iProjectID => a_new_project_id) then
          raise_application_error(-20000, pcs.pc_functions.translateword('PCS - Impossible de copier des budgets dans des projets ayant une autre monnaie') );
        else
          insert_budget(a_gal_project_id_source, a_new_project_id, b_dup_com_bud, b_dup_des_bud, a_prefix_bud, b_dup_line, b_dup_com_line, b_dup_des_line);
        end if;
      end if;
    exception
      when no_data_found then
        null;
    end;

    --**********TASK DUPLICATE************--
    begin
      select count(*)
        into v_tac_dupl
        from GAL_TASK_DUPLICATE;

      if v_tac_dupl <> 0 then
        insert_task(a_gal_project_id_source
                  , a_new_project_id
                  , b_dup_com_tac
                  , b_dup_des_tac
                  , b_dup_dat_tac
                  , b_dup_com_ope
                  , b_dup_des_ope
                  , b_dup_dat_ope
                  , b_dup_com_art
                  , b_dup_des_art
                  , b_dup_ope
                  , b_dup_art
                  , a_prefix_tac
                  , a_prefix_ope
                  , a_qte_mult_ope
                  , a_qte_mult_art
                  , b_dup_com_bud
                  , b_dup_des_bud
                  , a_prefix_bud
                  , b_dup_line
                  , b_dup_com_line
                  , b_dup_des_line
                  , null
                  , null
                  , null
                  , 0
                  , b_dup_ens
                  , b_dup_com_ens
                  , b_dup_des_ens
                  , a_qte_mult_ens
                  , null
                   );
      end if;
    exception
      when no_data_found then
        null;
    end;

    GAL_BDG_PERIOD_FUNCTIONS.UpdateProjectPeriod(aProjectID => a_new_project_id);
    a_new_prj_id  := a_new_project_id;   --Out variable
  end duplicate_project;
end gal_project_duplication;
