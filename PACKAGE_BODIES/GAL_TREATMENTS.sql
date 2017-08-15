--------------------------------------------------------
--  DDL for Package Body GAL_TREATMENTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_TREATMENTS" 
is
  procedure IND_GAL_TREATMENTS(
    a_proc_name             varchar2
  , a_treatment             varchar2
  , a_treatment_pos         varchar2
  , a_treatment_type        varchar2
  , a_entity                varchar2
  , a_Id                    varchar2
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    sqlStatement varchar2(2000);
  begin
    -- execution de la commande
    sqlStatement  := 'BEGIN ' || trim(a_proc_name) || '(:a_treatment,:a_treatment_pos,:a_treatment_type,:a_entity,:a_id,:out_warning,:out_error); END;';

    execute immediate sqlStatement
                using in a_treatment, in a_treatment_pos, in a_treatment_type, in a_entity, in a_id, in out out_warning, in out out_error;
  end IND_GAL_TREATMENTS;

  function Getconf_ind_treatments
    return varchar2
  is
    v_gal_ind_treatments varchar2(255);
  begin
    select PCS.PC_CONFIG.GETCONFIG('GAL_IND_TREATMENTS')
      into v_gal_ind_treatments
      from dual;

    return(v_gal_ind_treatments);
  exception
    when no_data_found then
      return(null);
  end;

  procedure ERREUR_DONNEE_MANQUANTE(out_error in out clob)
  is
  begin
    out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Donnée manquante') || chr(10);
  end ERREUR_DONNEE_MANQUANTE;

  procedure ERREUR_CODE_ETAT_AFFAIRE(out_error in out clob)
  is
  begin
    out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Le code état de l''affaire n''autorise pas cette action') || chr(10);
  end ERREUR_CODE_ETAT_AFFAIRE;

  procedure ERREUR_CODE_ETAT_TACHE(out_error in out clob)
  is
  begin
    out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Le code état de la tâche n''autorise pas cette action') || chr(10);
  end ERREUR_CODE_ETAT_TACHE;

  procedure ERREUR_CODE_ETAT_TACHE_DF(out_error in out clob)
  is
  begin
    out_error  :=
        rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Le code état de dossier(s) de fabrication lié(s) à la tâche n''autorise pas cette action')
        || chr(10);
  end ERREUR_CODE_ETAT_TACHE_DF;

  procedure ERREUR_CODE_ETAT_OPERATION(out_error in out clob)
  is
  begin
    out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Le code état de l''opération n''autorise pas cette action') || chr(10);
  end ERREUR_CODE_ETAT_OPERATION;

  procedure ERREUR_CODE_ETAT_BUDGET(out_error in out clob)
  is
  begin
    out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Le code état du budget n''autorise pas cette action') || chr(10);
  end ERREUR_CODE_ETAT_BUDGET;

  procedure ERREUR_CODE_ETAT_BUDGET_PERE(out_error in out clob)
  is
  begin
    out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Le code état du budget père n''autorise pas cette action') || chr(10);
  end ERREUR_CODE_ETAT_BUDGET_PERE;

  procedure ERREUR_DOCUMENT(out_error in out clob)
  is
  begin
    out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Erreur, l''état des documents suivants n''autorise pas cette action:') || chr(10);
  end ERREUR_DOCUMENT;

  procedure ERREUR_TRAITEMENT_INTERDIT(out_error in out clob)
  is
  begin
    out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Traitement interdit') || chr(10);
  end ERREUR_TRAITEMENT_INTERDIT;

  procedure WARNING_VALIDER_TRAITEMENT(out_warning in out clob)
  is
  begin
    out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cliquer sur le bouton VALIDER si vous désirez confirmer ce traitement') || chr(10);
  end WARNING_VALIDER_TRAITEMENT;

  procedure WARNING_DELIVER(out_warning in out clob)
  is
  begin
    out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Attention, les éléments suivants seront aussi livrés:') || chr(10);
  end WARNING_DELIVER;

  procedure WARNING_CLOSE(out_warning in out clob)
  is
  begin
    out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Attention, les éléments suivants seront aussi soldés:') || chr(10);
  end WARNING_CLOSE;

  procedure WARNING_HOLD(out_warning in out clob)
  is
  begin
    out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Attention, les éléments suivants seront aussi suspendus:') || chr(10);
  end WARNING_HOLD;

  procedure WARNING_REOPEN(out_warning in out clob)
  is
  begin
    out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Attention, les éléments suivants seront aussi réactivés:') || chr(10);
  end WARNING_REOPEN;

  procedure WARNING_TRAITEMENT_TERMINE(out_warning in out clob)
  is
  begin
    out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Traitement terminé') || chr(10);
  end WARNING_TRAITEMENT_TERMINE;

  --****** MAJ Solde d'une opération ***********************************************************************--
  procedure UPDATE_CLOSE_TASK_LINK(a_id varchar2, d_date_trt gal_task_link.TAL_BALANCE_DATE%type, a_comment gal_task_link.SCS_FREE_DESCR%type)
  is
  begin
    -- Solde OP
    update gal_task_link
       set C_TAL_STATE = '40'
         , TAL_TSK_BALANCE = 0
         , TAL_BALANCE_DATE = d_date_trt
         , TAL_HANGING_DATE = null
         , TAL_END_REAL_DATE = (select max(HOU.HOU_POINTING_DATE)
                                  from GAL_HOURS HOU
                                 where HOU.GAL_TASK_LINK_ID = a_id)
         , SCS_FREE_DESCR = a_comment
     where GAL_TASK_LINK_ID = a_id;
  end UPDATE_CLOSE_TASK_LINK;

--**********************************************************************************************************--

  --****** MAJ Réactivation d'une opération ***********************************************************************--
  procedure UPDATE_REOPEN_TASK_LINK(
    a_id          varchar2
  , d_date_trt    gal_task_link.TAL_BALANCE_DATE%type
  , a_comment     gal_task_link.SCS_FREE_DESCR%type
  , v_c_tas_state gal_task.C_TAS_STATE%type
  )
  is
  begin
    -- Réactivation OP
    update gal_task_link
       set C_TAL_STATE = decode(nvl(TAL_ACHIEVED_TSK, 0), 0, decode(v_c_tas_state, '30', '20', v_c_tas_state), '30')
         , TAL_BALANCE_DATE = null
         , TAL_HANGING_DATE = null
         , TAL_END_REAL_DATE = null
         , SCS_FREE_DESCR = a_comment
     where GAL_TASK_LINK_ID = a_id;
  end UPDATE_REOPEN_TASK_LINK;

--**********************************************************************************************************--

  --***** MAJ Suspendre une opération ***********************************************************************--
  procedure UPDATE_HOLD_TASK_LINK(a_id varchar2, d_date_trt gal_task_link.TAL_BALANCE_DATE%type, a_comment gal_task_link.SCS_FREE_DESCR%type)
  is
  begin
    -- Suspension OP
    update gal_task_link
       set C_TAL_STATE = '99'
         , TAL_HANGING_DATE = d_date_trt
         , SCS_FREE_DESCR = a_comment
     where GAL_TASK_LINK_ID = a_id;
  end UPDATE_HOLD_TASK_LINK;

--**********************************************************************************************************--

  --****** MAJ Lancement d'une tâche ***********************************************************************--
  procedure UPDATE_LAUNCH_TASK(a_id varchar2, d_date_trt gal_task.TAS_LAUNCHING_DATE%type, a_comment gal_task.TAS_COMMENT%type)
  is
  begin
    -- Lancement TAC
    update GAL_TASK
       set C_TAS_STATE = '20'
         , TAS_LAUNCHING_DATE = d_date_trt
         , TAS_TASK_PREPARED = 0
         , TAS_COMMENT = a_comment
     where GAL_TASK_ID = a_id;

    -- Lancement OP non lancées
    update gal_task_link
       set C_TAL_STATE = '20'
     where GAL_TASK_ID = a_id
       and C_TAL_STATE < '20';
  end UPDATE_LAUNCH_TASK;

--**********************************************************************************************************--

  --****** MAJ Solde d'une tâche ***********************************************************************--
  procedure UPDATE_CLOSE_TASK(a_id varchar2, d_date_trt gal_task.TAS_BALANCE_DATE%type, a_comment gal_task.TAS_COMMENT%type)
  is
  begin
    -- Solde TAC
    update gal_task
       set C_TAS_STATE = '40'
         , TAS_BALANCE_DATE = d_date_trt
         , TAS_HANGING_DATE = null
         , TAS_COMMENT = a_comment
     where GAL_TASK_ID = a_id;

    -- Solde OP non soldées
    begin
      for cOP in (select op.gal_task_link_id
                    from gal_task_link op
                   where op.GAL_TASK_ID = a_id
                     and op.C_TAL_STATE <> '40') loop
        UPDATE_CLOSE_TASK_LINK(Cop.gal_task_link_id, d_date_trt, a_comment);
      end loop;
    end;
  end UPDATE_CLOSE_TASK;

--**********************************************************************************************************--

  --****** MAJ Suspension d'une tâche ***********************************************************************--
  procedure UPDATE_HOLD_TASK(a_id varchar2, d_date_trt gal_task.TAS_HANGING_DATE%type, a_comment gal_task.TAS_COMMENT%type)
  is
  begin
    -- Suspension TAC
    update gal_task
       set C_TAS_STATE = '99'
         , TAS_HANGING_DATE = d_date_trt
         , TAS_COMMENT = a_comment
     where GAL_TASK_ID = a_id;

    -- Suspension OP non soldées non suspendues
    begin
      for cOP in (select op.gal_task_link_id
                    from gal_task_link op
                   where op.GAL_TASK_ID = a_id
                     and op.C_TAL_STATE <> '40'
                     and op.C_TAL_STATE <> '99') loop
        UPDATE_HOLD_TASK_LINK(Cop.gal_task_link_id, d_date_trt, a_comment);
      end loop;
    end;
  end UPDATE_HOLD_TASK;

--**********************************************************************************************************--

  --****** MAJ Réactivation d'une tâche ***********************************************************************--
  procedure UPDATE_REOPEN_TASK(a_id varchar2, d_date_trt gal_task.TAS_BALANCE_DATE%type, a_comment gal_task.TAS_COMMENT%type)
  is
  begin
    -- Réactivation TAC
    update gal_task
       set C_TAS_STATE = decode(TAS_ACTUAL_START_DATE, null, decode(TAS_LAUNCHING_DATE, null, '10', '20'), '30')
         , TAS_BALANCE_DATE = null
         , TAS_HANGING_DATE = null
         , TAS_COMMENT = a_comment
     where GAL_TASK_ID = a_id;

    -- Réactivation OP suspendues
    begin
      for cOP in (select op.gal_task_link_id
                       , ta.c_tas_state
                    from gal_task_link op
                       , gal_task ta
                   where ta.GAL_TASK_ID = a_id
                     and op.GAL_TASK_ID = ta.GAL_TASK_ID
                     and op.C_TAL_STATE = '99') loop
        UPDATE_REOPEN_TASK_LINK(Cop.gal_task_link_id, d_date_trt, a_comment, Cop.c_tas_state);
      end loop;
    end;
  end UPDATE_REOPEN_TASK;

--**********************************************************************************************************--

  --****** MAJ Livraison d'un code budget ***********************************************************************--
  procedure UPDATE_DELIVER_BUDGET(
    a_id             varchar2
  , d_date_trt       gal_budget.BDG_OUTSTANDING_DATE%type
  , a_comment        gal_budget.BDG_COMMENT%type
  , v_gal_project_id gal_project.gal_project_id%type
  )
  is
  begin
    -- Livraison BUD + sous BUD non livrés non soldées non suspendus
    begin
      for cBUD in (select bu.GAL_BUDGET_ID
                     from GAL_BUDGET bu
                    where bu.C_BDG_STATE <> '30'
                      and bu.C_BDG_STATE <> '40'
                      and bu.C_BDG_STATE <> '99'
                      and bu.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                    from GAL_BUDGET
                                                   where GAL_PROJECT_ID = v_gal_project_id
                                              connect by prior gal_budget_id = gal_father_budget_id
                                              start with gal_budget_id = a_id   -- Budget + Sous Budget
                                                                             ) ) loop
        update GAL_BUDGET
           set C_BDG_STATE = '30'
             , BDG_OUTSTANDING_DATE = d_date_trt
             , BDG_COMMENT = a_comment
         where GAL_BUDGET_ID = Cbud.GAL_BUDGET_ID;
      end loop;
    end;
  end UPDATE_DELIVER_BUDGET;

--**********************************************************************************************************--

  --****** MAJ Solde d'un code budget ***********************************************************************--
  procedure UPDATE_CLOSE_BUDGET(
    a_id             varchar2
  , d_date_trt       gal_budget.BDG_BALANCE_DATE%type
  , a_comment        gal_budget.BDG_COMMENT%type
  , v_gal_project_id gal_project.gal_project_id%type
  )
  is
  begin
    -- Solde BUD + sous BUD non soldées
    begin
      for cBUD in (select bu.GAL_BUDGET_ID
                     from GAL_BUDGET bu
                    where bu.C_BDG_STATE <> '40'
                      and bu.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                    from GAL_BUDGET
                                                   where GAL_PROJECT_ID = v_gal_project_id
                                              connect by prior gal_budget_id = gal_father_budget_id
                                              start with gal_budget_id = a_id   -- Budget + Sous Budget
                                                                             ) ) loop
        update GAL_BUDGET
           set C_BDG_STATE = '40'
             , BDG_BALANCE_DATE = d_date_trt
             , BDG_HANGING_DATE = null
             , BDG_OUTSTANDING_DATE = decode(BDG_OUTSTANDING_DATE, null, d_date_trt, BDG_OUTSTANDING_DATE)
             , BDG_COMMENT = a_comment
         where GAL_BUDGET_ID = Cbud.GAL_BUDGET_ID;

        -- Mise à 0 des restes de LIG avec reste
        update GAL_BUDGET_LINE
           set BLI_REMAINING_QUANTITY = 0
             , BLI_REMAINING_AMOUNT = 0
             , BLI_HANGING_SPENDING_QUANTITY = 0
             , BLI_HANGING_SPENDING_AMOUNT = 0
             , BLI_HANGING_SPENDING_AMOUNT_B = 0
             , BLI_LAST_REMAINING_DATE = d_date_trt
             , BLI_LAST_ESTIMATION_QUANTITY = 0
             , BLI_LAST_ESTIMATION_AMOUNT = 0
             , BLI_COMMENT = a_comment
         where GAL_BUDGET_ID = Cbud.GAL_BUDGET_ID;

        -- Solde TAC non soldées
        begin
          for cTA in (select ta.gal_task_id
                        from gal_task ta
                       where ta.GAL_BUDGET_ID = Cbud.GAL_BUDGET_ID
                         and ta.C_TAS_STATE <> '40') loop
            UPDATE_CLOSE_TASK(Cta.gal_task_id, d_date_trt, a_comment);
          end loop;
        end;
      end loop;
    end;
  end UPDATE_CLOSE_BUDGET;

--**********************************************************************************************************--

  --****** MAJ Suspension d'un code budget ***********************************************************************--
  procedure UPDATE_HOLD_BUDGET(
    a_id             varchar2
  , d_date_trt       gal_budget.BDG_HANGING_DATE%type
  , a_comment        gal_budget.BDG_COMMENT%type
  , v_gal_project_id gal_project.gal_project_id%type
  )
  is
  begin
    -- Suspension BUD + sous BUD non soldés non suspendus
    begin
      for cBUD in (select bu.GAL_BUDGET_ID
                     from GAL_BUDGET bu
                    where bu.C_BDG_STATE <> '40'
                      and bu.C_BDG_STATE <> '99'
                      and bu.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                    from GAL_BUDGET
                                                   where GAL_PROJECT_ID = v_gal_project_id
                                              connect by prior gal_budget_id = gal_father_budget_id
                                              start with gal_budget_id = a_id   -- Budget + Sous Budget
                                                                             ) ) loop
        update GAL_BUDGET
           set C_BDG_STATE = '99'
             , BDG_HANGING_DATE = d_date_trt
             , BDG_COMMENT = a_comment
         where GAL_BUDGET_ID = Cbud.GAL_BUDGET_ID;

        -- Suspension TAC non soldées non suspendues
        begin
          for cTA in (select ta.gal_task_id
                        from gal_task ta
                       where ta.GAL_BUDGET_ID = Cbud.GAL_BUDGET_ID
                         and ta.C_TAS_STATE <> '40'
                         and ta.C_TAS_STATE <> '99') loop
            UPDATE_HOLD_TASK(Cta.gal_task_id, d_date_trt, a_comment);
          end loop;
        end;
      end loop;
    end;
  end UPDATE_HOLD_BUDGET;

--**********************************************************************************************************--

  --****** MAJ Réactivation d'un code budget ***********************************************************************--
  procedure UPDATE_REOPEN_BUDGET(
    a_id             varchar2
  , d_date_trt       gal_budget.BDG_BALANCE_DATE%type
  , a_comment        gal_budget.BDG_COMMENT%type
  , v_gal_project_id gal_project.gal_project_id%type
  )
  is
  begin
    -- Réactivayion BUD + sous BUD livrés, soldés ou suspendus
    begin
      for cBUD in (select bu.GAL_BUDGET_ID
                     from GAL_BUDGET bu
                    where (    (    bu.gal_budget_id = a_id
                                and (   bu.C_BDG_STATE = '30'
                                     or bu.C_BDG_STATE = '40'
                                     or bu.C_BDG_STATE = '99') )
                           or (    bu.gal_budget_id <> a_id
                               and bu.C_BDG_STATE = '99')
                          )
                      and bu.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                    from GAL_BUDGET
                                                   where GAL_PROJECT_ID = v_gal_project_id
                                              connect by prior gal_budget_id = gal_father_budget_id
                                              start with gal_budget_id = a_id   -- Budget + Sous Budget
                                                                             ) ) loop
        update GAL_BUDGET
           set C_BDG_STATE = decode(C_BDG_STATE, '30', '10', decode(BDG_OUTSTANDING_DATE, null, '10', '30') )
             , BDG_HANGING_DATE = null
             , BDG_OUTSTANDING_DATE = decode(C_BDG_STATE, '30', null, BDG_OUTSTANDING_DATE)
             , BDG_BALANCE_DATE = null
             , BDG_COMMENT = a_comment
         where GAL_BUDGET_ID = Cbud.GAL_BUDGET_ID;

        -- Réactivation TAC suspendues
        begin
          for cTA in (select ta.gal_task_id
                        from gal_task ta
                       where ta.GAL_BUDGET_ID = Cbud.GAL_BUDGET_ID
                         and ta.C_TAS_STATE = '99') loop
            UPDATE_REOPEN_TASK(Cta.gal_task_id, d_date_trt, a_comment);
          end loop;
        end;
      end loop;
    end;
  end UPDATE_REOPEN_BUDGET;

--**********************************************************************************************************--

  --****** MAJ Lancement d'une affaire ***********************************************************************--
  procedure UPDATE_LAUNCH_PROJECT(a_id varchar2, d_date_trt gal_project.PRJ_LAUNCHING_DATE%type, a_comment gal_project.PRJ_COMMENT%type)
  is
  begin
    -- Lancement AFF
    update GAL_PROJECT
       set C_PRJ_STATE = '20'
         , PRJ_LAUNCHING_DATE = d_date_trt
         , PRJ_COMMENT = a_comment
     where GAL_PROJECT_ID = a_id;
  end UPDATE_LAUNCH_PROJECT;

--**********************************************************************************************************--

  --****** MAJ Livraison d'une affaire ***********************************************************************--
  procedure UPDATE_DELIVER_PROJECT(a_id varchar2, d_date_trt gal_project.PRJ_DELIVERY_DATE%type, a_comment gal_project.PRJ_COMMENT%type)
  is
  begin
    -- Livraison AFF
    update GAL_PROJECT
       set C_PRJ_STATE = '30'
         , PRJ_DELIVERY_DATE = d_date_trt
         , PRJ_COMMENT = a_comment
     where GAL_PROJECT_ID = a_id;

    -- Livraison BUD + sous BUD non livrés non soldées non suspendus
    begin
      for cBUD in (select bu.GAL_BUDGET_ID
                     from GAL_BUDGET bu
                    where bu.C_BDG_STATE <> '30'
                      and bu.C_BDG_STATE <> '40'
                      and bu.C_BDG_STATE <> '99'
                      and bu.GAL_PROJECT_ID = a_id
                      and bu.GAL_FATHER_BUDGET_ID is null) loop
        UPDATE_DELIVER_BUDGET(cBUD.gal_budget_id, d_date_trt, a_comment, a_id);
      end loop;
    end;
  end UPDATE_DELIVER_PROJECT;

--**********************************************************************************************************--

  --****** MAJ Solde d'une affaire ***********************************************************************--
  procedure UPDATE_CLOSE_PROJECT(a_id varchar2, d_date_trt gal_project.PRJ_BALANCE_DATE%type, a_comment gal_project.PRJ_COMMENT%type)
  is
  begin
    -- Solde AFF
    update GAL_PROJECT
       set C_PRJ_STATE = '40'
         , PRJ_HANGING_DATE = null
         , PRJ_DELIVERY_DATE = decode(PRJ_DELIVERY_DATE, null, d_date_trt, PRJ_DELIVERY_DATE)
         , PRJ_BALANCE_DATE = d_date_trt
         , PRJ_COMMENT = a_comment
     where GAL_PROJECT_ID = a_id;

    -- Solde BUD + sous BUD non soldés
    begin
      for cBUD in (select bu.GAL_BUDGET_ID
                     from GAL_BUDGET bu
                    where bu.C_BDG_STATE <> '40'
                      and bu.GAL_PROJECT_ID = a_id
                      and bu.GAL_FATHER_BUDGET_ID is null) loop
        UPDATE_CLOSE_BUDGET(cBUD.gal_budget_id, d_date_trt, a_comment, a_id);
      end loop;
    end;
  end UPDATE_CLOSE_PROJECT;

--**********************************************************************************************************--

  --****** MAJ Suspension d'une affaire ***********************************************************************--
  procedure UPDATE_HOLD_PROJECT(a_id varchar2, d_date_trt gal_project.PRJ_HANGING_DATE%type, a_comment gal_project.PRJ_COMMENT%type)
  is
  begin
    -- Suspension AFF
    update GAL_PROJECT
       set C_PRJ_STATE = '99'
         , PRJ_HANGING_DATE = d_date_trt
         , PRJ_COMMENT = a_comment
     where GAL_PROJECT_ID = a_id;

    -- Suspension BUD + sous BUD non soldés non suspendus
    begin
      for cBUD in (select bu.GAL_BUDGET_ID
                     from GAL_BUDGET bu
                    where bu.C_BDG_STATE <> '40'
                      and bu.C_BDG_STATE <> '99'
                      and bu.GAL_PROJECT_ID = a_id
                      and bu.GAL_FATHER_BUDGET_ID is null) loop
        UPDATE_HOLD_BUDGET(cBUD.gal_budget_id, d_date_trt, a_comment, a_id);
      end loop;
    end;
  end UPDATE_HOLD_PROJECT;

--**********************************************************************************************************--

  --****** MAJ Réactivation d'une affaire ***********************************************************************--
  procedure UPDATE_REOPEN_PROJECT(a_id varchar2, d_date_trt gal_project.PRJ_BALANCE_DATE%type, a_comment gal_project.PRJ_COMMENT%type)
  is
  begin
    -- Réactivation AFF
    update GAL_PROJECT
       set C_PRJ_STATE =
             decode(C_PRJ_STATE
                  , '30', decode(PRJ_LAUNCHING_DATE, null, '10', '20')
                  , decode(PRJ_DELIVERY_DATE, null, decode(PRJ_LAUNCHING_DATE, null, '10', '20'), '30')
                   )
         , PRJ_HANGING_DATE = null
         , PRJ_DELIVERY_DATE = decode(C_PRJ_STATE, '30', null, PRJ_DELIVERY_DATE)
         , PRJ_BALANCE_DATE = null
         , PRJ_COMMENT = a_comment
     where GAL_PROJECT_ID = a_id;

    -- Réactivation BUD + sous BUD non soldés non suspendus
    begin
      for cBUD in (select bu.GAL_BUDGET_ID
                     from GAL_BUDGET bu
                    where bu.C_BDG_STATE = '99'
                      and bu.GAL_PROJECT_ID = a_id
                      and bu.GAL_FATHER_BUDGET_ID is null) loop
        UPDATE_REOPEN_BUDGET(cBUD.gal_budget_id, d_date_trt, a_comment, a_id);
      end loop;
    end;
  end UPDATE_REOPEN_PROJECT;

--**********************************************************************************************************--

  --********** Controle d'un dossier *******************************************************************--
  function CONTROLE_EN_COURS_SUR_DOSSIER(v_doc_record_id gal_task.doc_record_id%type, v_status varchar2   -- valeur 'A' pour données en cours
                                                                                                          -- valeur 'C' pour données non comptabilisées
                                                                                                       )
    return clob
  is
    out_error clob   := null;
    cpt       number := 0;
  begin
    -- Contrôle des données LOGISTIQUE et INDUSTRIE
    if gal_functions.get_cpt_fsr(v_doc_record_id, 'A') <> 0 then
      out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Il existe des demandes d''approvisionnement en cours') || chr(10);
    end if;

    if gal_functions.get_cpt_poa(v_doc_record_id) <> 0 then
      out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Il existe des propositions d''approvisionnement en cours') || chr(10);
    end if;

    if gal_functions.get_cpt_pof(v_doc_record_id) <> 0 then
      out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Il existe des propositions de fabrication en cours') || chr(10);
    end if;

    if gal_functions.get_cpt_of(v_doc_record_id, 'A') <> 0 then
      out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Il existe des OF en cours') || chr(10);
    end if;

    -- Contrôle DOC non confirmés/liquidés
    --           ou non comptabilisés
    cpt  := 0;

    begin
      for cDOC in (select distinct GAU_DESCRIBE
                                 , DMT_NUMBER
                                 , C_DOCUMENT_STATUS
                              from (select gau.GAU_DESCRIBE
                                         , doc.DMT_NUMBER
                                         , doc.C_DOCUMENT_STATUS
                                      from DOC_GAUGE gau
                                         , DOC_GAUGE_STRUCTURED gas
                                         , DOC_DOCUMENT doc
                                         , DOC_POSITION pos
                                     where gau.DOC_GAUGE_ID = doc.DOC_GAUGE_ID
                                       and gas.DOC_GAUGE_ID = doc.DOC_GAUGE_ID
                                       and doc.DOC_DOCUMENT_ID = pos.DOC_DOCUMENT_ID
                                       and nvl(pos.POS_IMPUTATION, 0) = 0
                                       and pos.DOC_RECORD_ID = v_doc_record_id
                                       and (    (     (    (    gas.DIC_PROJECT_CONSOL_1_ID = '1'
                                                            and pos.C_DOC_POS_STATUS < '04')
                                                       or (    gas.DIC_PROJECT_CONSOL_1_ID = '2'
                                                           and pos.C_DOC_POS_STATUS < '02')
                                                       or (    gas.DIC_PROJECT_CONSOL_1_ID = '3'
                                                           and pos.C_DOC_POS_STATUS < '02')
                                                      )
                                                 and v_status in('A', 'C')
                                                )
                                            or (     (   pos.C_DOC_POS_STATUS < '04'
                                                      or (     (   gas.GAS_FINANCIAL_CHARGE = 1
                                                                or gas.GAS_ANAL_CHARGE = 1)
                                                          and exists(select aci.doc_document_id
                                                                       from ACI_DOCUMENT aci
                                                                      where aci.DOC_DOCUMENT_ID = doc.DOC_DOCUMENT_ID
                                                                        and aci.C_INTERFACE_CONTROL in('2', '3') )
                                                         )
                                                     )
                                                and v_status = 'C'
                                               )
                                           )
                                    union
                                    select gau.GAU_DESCRIBE
                                         , doc.DMT_NUMBER
                                         , doc.C_DOCUMENT_STATUS
                                      from DOC_GAUGE gau
                                         , DOC_GAUGE_STRUCTURED gas
                                         , DOC_DOCUMENT doc
                                         , DOC_POSITION pos
                                         , DOC_POSITION_IMPUTATION imp
                                     where gau.DOC_GAUGE_ID = doc.DOC_GAUGE_ID
                                       and gas.DOC_GAUGE_ID = doc.DOC_GAUGE_ID
                                       and doc.DOC_DOCUMENT_ID = pos.DOC_DOCUMENT_ID
                                       and pos.DOC_POSITION_ID = imp.DOC_POSITION_ID
                                       and nvl(pos.POS_IMPUTATION, 0) = 1
                                       and imp.DOC_RECORD_ID = v_doc_record_id
                                       and (    (     (    (    gas.DIC_PROJECT_CONSOL_1_ID = '1'
                                                            and pos.C_DOC_POS_STATUS < '04')
                                                       or (    gas.DIC_PROJECT_CONSOL_1_ID = '2'
                                                           and pos.C_DOC_POS_STATUS < '02')
                                                       or (    gas.DIC_PROJECT_CONSOL_1_ID = '3'
                                                           and pos.C_DOC_POS_STATUS < '02')
                                                      )
                                                 and v_status in('A', 'C')
                                                )
                                            or (     (   pos.C_DOC_POS_STATUS < '04'
                                                      or (     (   gas.GAS_FINANCIAL_CHARGE = 1
                                                                or gas.GAS_ANAL_CHARGE = 1)
                                                          and exists(select aci.doc_document_id
                                                                       from ACI_DOCUMENT aci
                                                                      where aci.DOC_DOCUMENT_ID = doc.DOC_DOCUMENT_ID
                                                                        and aci.C_INTERFACE_CONTROL in('2', '3') )
                                                         )
                                                     )
                                                and v_status = 'C'
                                               )
                                           ) )
                          order by GAU_DESCRIBE
                                 , DMT_NUMBER) loop
        cpt        := cpt + 1;
        --if cpt = 1
        --then
        --  ERREUR_DOCUMENT(out_error);
        --end if;
        out_error  :=
          rtrim(out_error) ||
          cDOC.GAU_DESCRIBE ||
          ' - ' ||
          cDOC.DMT_NUMBER ||
          ' : ' ||
          COM_FUNCTIONS.GETDESCODEDESCR('C_DOCUMENT_STATUS', cDOC.C_DOCUMENT_STATUS, nvl(pcs.PC_I_LIB_SESSION.GETUSERLANGID(), 1) ) ||
          chr(10);
      end loop;
    end;

    begin
      for cACI in (select distinct aci.DOC_NUMBER
                                 , aci.C_INTERFACE_CONTROL
                              from ACI_DOCUMENT aci
                                 , ACI_MGM_IMPUTATION mgm
                             where aci.ACI_DOCUMENT_ID = mgm.ACI_DOCUMENT_ID
                               and aci.DOC_DOCUMENT_ID is null
                               and mgm.DOC_RECORD_ID = v_doc_record_id
                               and (   aci.C_INTERFACE_CONTROL in('2', '3')
                                    or (    aci.C_INTERFACE_CONTROL = '1'
                                        and aci.DOC_INTEGRATION_DATE is null) )
                               and v_status = 'C'
                          order by DOC_NUMBER) loop
        cpt        := cpt + 1;
        --if cpt = 1
        --then
        --  ERREUR_DOCUMENT(out_error);
        --end if;
        out_error  :=
          rtrim(out_error) ||
          cACI.DOC_NUMBER ||
          ' : ' ||
          COM_FUNCTIONS.GETDESCODEDESCR('C_INTERFACE_CONTROL', cACI.C_INTERFACE_CONTROL, nvl(pcs.PC_I_LIB_SESSION.GETUSERLANGID(), 1) ) ||
          chr(10);
      end loop;
    end;

    return out_error;
  end CONTROLE_EN_COURS_SUR_DOSSIER;

--**********************************************************************************************************--

  --********** Lancement d'une affaire ***********************************************************************--
  procedure launch_project(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_project.PRJ_LAUNCHING_DATE%type
  , a_comment               gal_project.PRJ_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_state              gal_project.c_prj_state%type   := null;
    v_exist              number                         := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'LAUNCH', 'PRE', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      begin
        select C_PRJ_STATE
          into v_state
          from gal_project
         where GAL_PROJECT_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_state  := null;
      end;

      if     v_state is not null
         and v_state >= '20' then
        ERREUR_CODE_ETAT_AFFAIRE(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      begin
        select count(*)
          into v_exist
          from gal_budget
         where GAL_PROJECT_ID = a_id;
      exception
        when no_data_found then
          v_exist  := 0;
      end;

      if v_exist = 0 then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Aucun code budget n''a été créé') || chr(10);
      end if;

      begin
        select count(*)
          into v_exist
          from gal_task
         where GAL_PROJECT_ID = a_id;
      exception
        when no_data_found then
          v_exist  := 0;
      end;

      if v_exist = 0 then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Aucune tâche n''a été créée') || chr(10);
      end if;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'LAUNCH', 'POST', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

-- Mises à jour -------------------------------------------------------------------------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'LAUNCH', 'PRE', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;

      UPDATE_LAUNCH_PROJECT(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'LAUNCH', 'POST', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;
    end if;
  end launch_project;

--**********************************************************************************************************--

  --********** Livraison d'une affaire ***********************************************************************--
  procedure deliver_project(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_project.PRJ_DELIVERY_DATE%type
  , a_comment               gal_project.PRJ_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_prj_state        gal_project.c_prj_state%type   := null;
    cpt                  number                         := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'DELIVERY', 'PRE', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture budget
      begin
        select C_PRJ_STATE
          into v_c_prj_state
          from gal_project
         where GAL_PROJECT_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_prj_state  := null;
      end;

      if    v_c_prj_state = '30'
         or v_c_prj_state = '40'
         or v_c_prj_state = '99' then
        ERREUR_CODE_ETAT_AFFAIRE(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      -- Contrôle BUD non livrées
      cpt  := 0;

      begin
        for cBU in (select   bu.BDG_CODE
                           , bu.BDG_WORDING
                        from GAL_BUDGET bu
                       where bu.C_BDG_STATE <> '30'
                         and bu.C_BDG_STATE <> '40'
                         and bu.C_BDG_STATE <> '99'
                         and bu.GAL_PROJECT_ID = a_id
                    order by bu.BDG_CODE) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_DELIVER(out_warning);
          end if;

          out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'DELIVERY', 'POST', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'DELIVERY', 'PRE', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;

      UPDATE_DELIVER_PROJECT(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'DELIVERY', 'POST', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;
    end if;
  end deliver_project;

--**********************************************************************************************************--

  --********** Solde d'une affaire ***********************************************************************--
  procedure close_project(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_project.PRJ_BALANCE_DATE%type
  , a_comment               gal_project.PRJ_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_prj_state        gal_project.c_prj_state%type    := null;
    v_doc_record_id      doc_record.doc_record_id%type   := null;
    mes_error            clob                            := null;
    cpt                  number                          := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'PRE', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture affaire
      begin
        select C_PRJ_STATE
             , DOC_RECORD_ID
          into v_c_prj_state
             , v_doc_record_id
          from gal_project
         where GAL_PROJECT_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_prj_state    := null;
          v_doc_record_id  := null;
      end;

      if v_c_prj_state = '40' then
        ERREUR_CODE_ETAT_AFFAIRE(out_error);
      end if;

      -- Contrôle Données en cours ou non ecomptabilisées sur dossier AFF
      if v_doc_record_id is not null then
        out_error  := rtrim(out_error) || CONTROLE_EN_COURS_SUR_DOSSIER(v_doc_record_id, 'C');
      end if;

      -- Contrôle Données En cours ou non comptabilisées sur dossier BUD + Sous BUD
      begin
        for cBU in (select   bu.BDG_CODE
                           , bu.BDG_WORDING
                           , bu.DOC_RECORD_ID
                        from GAL_BUDGET bu
                       where bu.GAL_PROJECT_ID = a_id
                         and bu.DOC_RECORD_ID is not null
                    order by bu.BDG_CODE) loop
          mes_error  := CONTROLE_EN_COURS_SUR_DOSSIER(cBU.doc_record_id, 'C');

          if mes_error is not null then
            out_error  := rtrim(out_error) || '+' || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);
            out_error  := rtrim(out_error) || mes_error;
          end if;
        end loop;
      end;

      -- Contrôle Données En cours ou Non comptabilisées dossier TAC
      begin
        for cTA in (select   ta.TAS_CODE
                           , ta.TAS_WORDING
                           , ta.DOC_RECORD_ID
                        from GAL_TASK ta
                       where ta.GAL_PROJECT_ID = a_id
                         and ta.DOC_RECORD_ID is not null
                    order by ta.TAS_CODE) loop
          mes_error  := CONTROLE_EN_COURS_SUR_DOSSIER(cTA.doc_record_id, 'C');

          if mes_error is not null then
            out_error  := rtrim(out_error) || '+' || PCS.PC_FUNCTIONS.TranslateWord('Tâche') || ' : ' || cTA.TAS_CODE || ' / ' || cTA.TAS_WORDING || chr(10);
            out_error  := rtrim(out_error) || mes_error;
          end if;
        end loop;
      end;

      -- Contrôle Données en cours ou Non comptabilisées sur dossier OP
      begin
        for cOP in (select   ta.TAS_CODE
                           , op.SCS_STEP_NUMBER
                           , op.SCS_SHORT_DESCR
                           , op.DOC_RECORD_ID
                        from GAL_TASK_LINK op
                           , GAL_TASK ta
                       where op.GAL_TASK_ID = ta.GAL_TASK_ID
                         and ta.GAL_PROJECT_ID = a_id
                         and op.DOC_RECORD_ID is not null
                    order by ta.TAS_CODE
                           , op.SCS_STEP_NUMBER) loop
          mes_error  := CONTROLE_EN_COURS_SUR_DOSSIER(cOP.doc_record_id, 'C');

          if mes_error is not null then
            out_error  :=
              rtrim(out_error) ||
              '+' ||
              PCS.PC_FUNCTIONS.TranslateWord('Opération') ||
              ' : ' ||
              cOP.TAS_CODE ||
              ' / ' ||
              cOP.SCS_STEP_NUMBER ||
              ' / ' ||
              cOP.SCS_SHORT_DESCR ||
              chr(10);
            out_error  := rtrim(out_error) || mes_error;
          end if;
        end loop;
      end;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      if v_c_prj_state < '20' then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cette affaire n''a pas été lancée') || chr(10);
      end if;

      if v_c_prj_state = '99' then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cette affaire est suspendue') || chr(10);
      end if;

      -- Contrôle sous BUD non soldées
      cpt  := 0;

      begin
        for cBU in (select   bu.GAL_BUDGET_ID
                           , bu.BDG_CODE
                           , bu.BDG_WORDING
                        from GAL_BUDGET bu
                       where bu.C_BDG_STATE <> '40'
                         and bu.GAL_PROJECT_ID = a_id
                    order by bu.BDG_CODE) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_CLOSE(out_warning);
          end if;

          out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);

          -- Contrôle LIG avec reste non null
          begin
            for cLI in (select   li.BLI_WORDING
                            from GAL_BUDGET_LINE li
                           where (   nvl(BLI_REMAINING_QUANTITY, 0) <> 0
                                  or nvl(BLI_REMAINING_PRICE, 0) <> 0
                                  or nvl(BLI_REMAINING_AMOUNT, 0) <> 0)
                             and li.GAL_BUDGET_ID = Cbu.GAL_BUDGET_ID
                        order by li.BLI_WORDING) loop
              out_warning  :=
                          rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Ligne de budget') || ' : ' || cBU.BDG_CODE || ' / ' || cLI.BLI_WORDING
                          || chr(10);
            end loop;
          end;
        end loop;
      end;

      -- Contrôle TAC non soldées
      begin
        for cTA in (select   ta.TAS_CODE
                           , ta.TAS_WORDING
                        from GAL_TASK ta
                       where ta.C_TAS_STATE <> '40'
                         and ta.GAL_PROJECT_ID = a_id
                    order by ta.TAS_CODE) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_CLOSE(out_warning);
          end if;

          out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Tâche') || ' : ' || cTA.TAS_CODE || ' / ' || cTA.TAS_WORDING || chr(10);
        end loop;
      end;

      -- Contrôle OP non soldées
      begin
        for cOP in (select   ta.TAS_CODE
                           , op.SCS_STEP_NUMBER
                           , op.SCS_SHORT_DESCR
                        from GAL_TASK_LINK op
                           , GAL_TASK ta
                       where op.C_TAL_STATE <> '40'
                         and op.GAL_TASK_ID = ta.GAL_TASK_ID
                         and ta.GAL_PROJECT_ID = a_id
                    order by ta.TAS_CODE
                           , op.SCS_STEP_NUMBER) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_CLOSE(out_warning);
          end if;

          out_warning  :=
            rtrim(out_warning) ||
            PCS.PC_FUNCTIONS.TranslateWord('Opération') ||
            ' : ' ||
            cOP.TAS_CODE ||
            ' / ' ||
            cOP.SCS_STEP_NUMBER ||
            ' / ' ||
            cOP.SCS_SHORT_DESCR ||
            chr(10);
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'POST', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'PRE', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;

      UPDATE_CLOSE_PROJECT(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'POST', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;
    end if;
  end close_project;

--**********************************************************************************************************--

  --********** Suspension d'une affaire ***********************************************************************--
  procedure hold_project(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_project.PRJ_HANGING_DATE%type
  , a_comment               gal_project.PRJ_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_prj_state        gal_project.c_prj_state%type   := null;
    cpt                  number                         := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'PRE', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture affaire
      begin
        select C_PRJ_STATE
          into v_c_prj_state
          from gal_project
         where GAL_PROJECT_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_prj_state  := null;
      end;

      if    v_c_prj_state = '40'
         or v_c_prj_state = '99' then
        ERREUR_CODE_ETAT_AFFAIRE(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      -- Contrôle BUD non soldées/suspendues
      cpt  := 0;

      begin
        for cBU in (select   bu.BDG_CODE
                           , bu.BDG_WORDING
                        from GAL_BUDGET bu
                       where bu.C_BDG_STATE <> '40'
                         and bu.C_BDG_STATE <> '99'
                         and bu.GAL_PROJECT_ID = a_id
                    order by bu.BDG_CODE) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_HOLD(out_warning);
          end if;

          out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);
        end loop;
      end;

      -- Contrôle TAC non soldées/suspendues
      begin
        for cTA in (select   ta.TAS_CODE
                           , ta.TAS_WORDING
                        from GAL_TASK ta
                       where ta.C_TAS_STATE <> '40'
                         and ta.C_TAS_STATE <> '99'
                         and ta.GAL_PROJECT_ID = a_id
                    order by ta.TAS_CODE) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_HOLD(out_warning);
          end if;

          out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Tâche') || ' : ' || cTA.TAS_CODE || ' / ' || cTA.TAS_WORDING || chr(10);
        end loop;
      end;

      -- Contrôle OP non soldées/suspendues
      begin
        for cOP in (select   ta.TAS_CODE
                           , op.SCS_STEP_NUMBER
                           , op.SCS_SHORT_DESCR
                        from GAL_TASK_LINK op
                           , GAL_TASK ta
                       where op.C_TAL_STATE <> '40'
                         and op.C_TAL_STATE <> '99'
                         and op.GAL_TASK_ID = ta.GAL_TASK_ID
                         and ta.GAL_PROJECT_ID = a_id
                    order by ta.TAS_CODE
                           , op.SCS_STEP_NUMBER) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_HOLD(out_warning);
          end if;

          out_warning  :=
            rtrim(out_warning) ||
            PCS.PC_FUNCTIONS.TranslateWord('Opération') ||
            ' : ' ||
            cOP.TAS_CODE ||
            ' / ' ||
            cOP.SCS_STEP_NUMBER ||
            ' / ' ||
            cOP.SCS_SHORT_DESCR ||
            chr(10);
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'POST', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'PRE', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;

      UPDATE_HOLD_PROJECT(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'POST', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;
    end if;
  end hold_project;

--**********************************************************************************************************--

  --********** Réactivation d'une affaire ***********************************************************************--
  procedure reopen_project(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_project.PRJ_BALANCE_DATE%type
  , a_comment               gal_project.PRJ_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_prj_state        gal_project.c_prj_state%type   := null;
    cpt                  number                         := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'PRE', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture affaire
      begin
        select C_PRJ_STATE
          into v_c_prj_state
          from gal_project
         where GAL_PROJECT_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_prj_state  := null;
      end;

      if     v_c_prj_state <> '30'
         and v_c_prj_state <> '40'
         and v_c_prj_state <> '99' then
        ERREUR_CODE_ETAT_AFFAIRE(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      -- Contrôle BUD suspendues
      cpt  := 0;

      begin
        for cBU in (select   bu.BDG_CODE
                           , bu.BDG_WORDING
                        from GAL_BUDGET bu
                       where bu.C_BDG_STATE = '99'
                         and bu.GAL_PROJECT_ID = a_id
                    order by bu.BDG_CODE) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_REOPEN(out_warning);
          end if;

          out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);
        end loop;
      end;

      -- Contrôle TAC suspendues
      begin
        for cTA in (select   ta.TAS_CODE
                           , ta.TAS_WORDING
                        from GAL_TASK ta
                       where ta.C_TAS_STATE = '99'
                         and ta.GAL_PROJECT_ID = a_id
                    order by ta.TAS_CODE) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_REOPEN(out_warning);
          end if;

          out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Tâche') || ' : ' || cTA.TAS_CODE || ' / ' || cTA.TAS_WORDING || chr(10);
        end loop;
      end;

      -- Contrôle OP suspendues
      begin
        for cOP in (select   ta.TAS_CODE
                           , op.SCS_STEP_NUMBER
                           , op.SCS_SHORT_DESCR
                        from GAL_TASK_LINK op
                           , GAL_TASK ta
                       where op.C_TAL_STATE = '99'
                         and op.GAL_TASK_ID = ta.GAL_TASK_ID
                         and ta.GAL_PROJECT_ID = a_id
                    order by ta.TAS_CODE
                           , op.SCS_STEP_NUMBER) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_REOPEN(out_warning);
          end if;

          out_warning  :=
            rtrim(out_warning) ||
            PCS.PC_FUNCTIONS.TranslateWord('Opération') ||
            ' : ' ||
            cOP.TAS_CODE ||
            ' / ' ||
            cOP.SCS_STEP_NUMBER ||
            ' / ' ||
            cOP.SCS_SHORT_DESCR ||
            chr(10);
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'POST', 'CTRL', 'PRJ', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'PRE', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;

      UPDATE_REOPEN_PROJECT(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'POST', 'MAJ', 'PRJ', a_id, out_warning, out_error);
      end if;
    end if;
  end reopen_project;

--**********************************************************************************************************--

  --********** Livraison d'un code budget ***********************************************************************--
  procedure deliver_budget(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_budget.BDG_OUTSTANDING_DATE%type
  , a_comment               gal_budget.BDG_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_bdg_state        gal_budget.c_bdg_state%type       := null;
    v_gal_project_id     gal_project.gal_project_id%type   := null;
    cpt                  number                            := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'DELIVERY', 'PRE', 'CTRL', 'BUD', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture budget
      begin
        select C_BDG_STATE
             , GAL_PROJECT_ID
          into v_c_bdg_state
             , v_gal_project_id
          from gal_budget
         where GAL_BUDGET_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_bdg_state     := null;
          v_gal_project_id  := null;
      end;

      if    v_c_bdg_state = '30'
         or v_c_bdg_state = '40'
         or v_c_bdg_state = '99' then
        ERREUR_CODE_ETAT_BUDGET(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      -- Contrôle sous BUD non livrées
      cpt  := 0;

      begin
        for cBU in (select   bu.BDG_CODE
                           , bu.BDG_WORDING
                        from GAL_BUDGET bu
                       where bu.C_BDG_STATE <> '30'
                         and bu.C_BDG_STATE <> '40'
                         and bu.C_BDG_STATE <> '99'
                         and bu.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                       from GAL_BUDGET
                                                      where GAL_PROJECT_ID = v_gal_project_id
                                                 connect by prior gal_budget_id = gal_father_budget_id
                                                 start with gal_father_budget_id = a_id   -- Sous Budget
                                                                                       )
                    order by bu.BDG_CODE) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_DELIVER(out_warning);
          end if;

          out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'DELIVERY', 'POST', 'CTRL', 'BUD', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'DELIVERY', 'PRE', 'MAJ', 'BUD', a_id, out_warning, out_error);
      end if;

      UPDATE_DELIVER_BUDGET(a_id, d_date_trt, a_comment, v_gal_project_id);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'DELIVERY', 'POST', 'MAJ', 'BUD', a_id, out_warning, out_error);
      end if;
    end if;
  end deliver_budget;

--**********************************************************************************************************--

  --********** Solde d'un code budget ***********************************************************************--
  procedure close_budget(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_budget.BDG_BALANCE_DATE%type
  , a_comment               gal_budget.BDG_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_bdg_state        gal_budget.c_bdg_state%type       := null;
    v_gal_project_id     gal_project.gal_project_id%type   := null;
    mes_error            clob                              := null;
    cpt                  number                            := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'PRE', 'CTRL', 'BUD', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture budget
      begin
        select C_BDG_STATE
             , GAL_PROJECT_ID
          into v_c_bdg_state
             , v_gal_project_id
          from gal_budget
         where GAL_BUDGET_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_bdg_state     := null;
          v_gal_project_id  := null;
      end;

      if v_c_bdg_state = '40' then
        ERREUR_CODE_ETAT_BUDGET(out_error);
      end if;

      -- Contrôle Données En cours ou non comptabilisées sur dossier BUD + Sous BUD
      begin
        for cBU in (select   bu.GAL_BUDGET_ID
                           , bu.BDG_CODE
                           , bu.BDG_WORDING
                           , bu.DOC_RECORD_ID
                        from GAL_BUDGET bu
                       where bu.C_BDG_STATE <> '40'
                         and bu.DOC_RECORD_ID is not null
                         and bu.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                       from GAL_BUDGET
                                                      where GAL_PROJECT_ID = v_gal_project_id
                                                 connect by prior gal_budget_id = gal_father_budget_id
                                                 start with gal_budget_id = a_id   -- Budget + Sous Budget
                                                                                )
                    order by bu.BDG_CODE) loop
          mes_error  := CONTROLE_EN_COURS_SUR_DOSSIER(cBU.doc_record_id, 'C');

          if mes_error is not null then
            out_error  := rtrim(out_error) || '+' || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);
            out_error  := rtrim(out_error) || mes_error;
          end if;

          -- Contrôle Données En cours ou Non comptabilisées dossier TAC
          begin
            for cTA in (select   ta.GAL_TASK_ID
                               , ta.TAS_CODE
                               , ta.TAS_WORDING
                               , ta.DOC_RECORD_ID
                            from GAL_TASK ta
                           where ta.GAL_BUDGET_ID = Cbu.GAL_BUDGET_ID
                             and ta.DOC_RECORD_ID is not null
                        order by ta.TAS_CODE) loop
              mes_error  := CONTROLE_EN_COURS_SUR_DOSSIER(cTA.doc_record_id, 'C');

              if mes_error is not null then
                out_error  := rtrim(out_error) || '+' || PCS.PC_FUNCTIONS.TranslateWord('Tâche') || ' : ' || cTA.TAS_CODE || ' / ' || cTA.TAS_WORDING
                              || chr(10);
                out_error  := rtrim(out_error) || mes_error;
              end if;

              -- Contrôle Données en cours ou Non comptabilisées sur dossier OP
              begin
                for cOP in (select   op.SCS_STEP_NUMBER
                                   , op.SCS_SHORT_DESCR
                                   , op.DOC_RECORD_ID
                                from GAL_TASK_LINK op
                               where op.GAL_TASK_ID = Cta.GAL_TASK_ID
                                 and op.DOC_RECORD_ID is not null
                            order by op.SCS_STEP_NUMBER) loop
                  mes_error  := CONTROLE_EN_COURS_SUR_DOSSIER(cOP.doc_record_id, 'C');

                  if mes_error is not null then
                    out_error  :=
                      rtrim(out_error) ||
                      '+' ||
                      PCS.PC_FUNCTIONS.TranslateWord('Opération') ||
                      ' : ' ||
                      cTA.TAS_CODE ||
                      ' / ' ||
                      cOP.SCS_STEP_NUMBER ||
                      ' / ' ||
                      cOP.SCS_SHORT_DESCR ||
                      chr(10);
                    out_error  := rtrim(out_error) || mes_error;
                  end if;
                end loop;
              end;
            end loop;
          end;
        end loop;
      end;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      if v_c_bdg_state = '99' then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cet budget est suspendu') || chr(10);
      end if;

      -- Contrôle sous BUD non soldées
      cpt  := 0;

      begin
        for cBU in (select   bu.GAL_BUDGET_ID
                           , bu.BDG_CODE
                           , bu.BDG_WORDING
                        from GAL_BUDGET bu
                       where bu.C_BDG_STATE <> '40'
                         and bu.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                       from GAL_BUDGET
                                                      where GAL_PROJECT_ID = v_gal_project_id
                                                 connect by prior gal_budget_id = gal_father_budget_id
                                                 start with gal_budget_id = a_id   -- Budget + Sous Budget
                                                                                )
                    order by bu.BDG_CODE) loop
          if cBU.gal_budget_id <> a_id then
            cpt  := cpt + 1;
          end if;

          if cpt = 1 then
            WARNING_CLOSE(out_warning);
          end if;

          if cBU.gal_budget_id <> a_id then
            out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);
          end if;

          -- Contrôle LIG avec reste non nul
          begin
            for cLI in (select   li.BLI_WORDING
                            from GAL_BUDGET_LINE li
                           where (   nvl(BLI_REMAINING_QUANTITY, 0) <> 0
                                  or nvl(BLI_REMAINING_PRICE, 0) <> 0
                                  or nvl(BLI_REMAINING_AMOUNT, 0) <> 0
                                  or BLI_REMAINING_AMOUNT is null
                                 )
                             and li.GAL_BUDGET_ID = Cbu.GAL_BUDGET_ID
                        order by li.BLI_WORDING) loop
              cpt          := cpt + 1;

              if cpt = 1 then
                WARNING_CLOSE(out_warning);
              end if;

              out_warning  :=
                           rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Ligne de budget') || ' : ' || cBU.BDG_CODE || ' / ' || cLI.BLI_WORDING
                           || chr(10);
            end loop;
          end;

          -- Contrôle TAC non soldées
          begin
            for cTA in (select   ta.GAL_TASK_ID
                               , ta.TAS_CODE
                               , ta.TAS_WORDING
                            from GAL_TASK ta
                           where ta.C_TAS_STATE <> '40'
                             and ta.GAL_BUDGET_ID = Cbu.GAL_BUDGET_ID
                        order by ta.TAS_CODE) loop
              cpt          := cpt + 1;

              if cpt = 1 then
                WARNING_CLOSE(out_warning);
              end if;

              out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Tâche') || ' : ' || cTA.TAS_CODE || ' / ' || cTA.TAS_WORDING || chr(10);

              -- Contrôle OP non soldées
              begin
                for cOP in (select   op.SCS_STEP_NUMBER
                                   , op.SCS_SHORT_DESCR
                                from GAL_TASK_LINK op
                               where op.C_TAL_STATE <> '40'
                                 and op.GAL_TASK_ID = Cta.GAL_TASK_ID
                            order by op.SCS_STEP_NUMBER) loop
                  out_warning  :=
                    rtrim(out_warning) ||
                    PCS.PC_FUNCTIONS.TranslateWord('Opération') ||
                    ' : ' ||
                    cTA.TAS_CODE ||
                    ' / ' ||
                    cOP.SCS_STEP_NUMBER ||
                    ' / ' ||
                    cOP.SCS_SHORT_DESCR ||
                    chr(10);
                end loop;
              end;
            end loop;
          end;
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'POST', 'CTRL', 'BUD', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'PRE', 'MAJ', 'BUD', a_id, out_warning, out_error);
      end if;

      UPDATE_CLOSE_BUDGET(a_id, d_date_trt, a_comment, v_gal_project_id);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'POST', 'MAJ', 'BUD', a_id, out_warning, out_error);
      end if;
    end if;
  end close_budget;

--**********************************************************************************************************--

  --********** Suspension d'un code budget ***********************************************************************--
  procedure hold_budget(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_budget.BDG_HANGING_DATE%type
  , a_comment               gal_budget.BDG_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_bdg_state        gal_budget.c_bdg_state%type       := null;
    v_gal_project_id     gal_project.gal_project_id%type   := null;
    cpt                  number                            := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'PRE', 'CTRL', 'BUD', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture budget
      begin
        select C_BDG_STATE
             , GAL_PROJECT_ID
          into v_c_bdg_state
             , v_gal_project_id
          from gal_budget
         where GAL_BUDGET_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_bdg_state     := null;
          v_gal_project_id  := null;
      end;

      if    v_c_bdg_state = '40'
         or v_c_bdg_state = '99' then
        ERREUR_CODE_ETAT_BUDGET(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      -- Contrôle sous BUD non soldées/suspendues
      cpt  := 0;

      begin
        for cBU in (select   bu.GAL_BUDGET_ID
                           , bu.BDG_CODE
                           , bu.BDG_WORDING
                        from GAL_BUDGET bu
                       where bu.C_BDG_STATE <> '40'
                         and bu.C_BDG_STATE <> '99'
                         and bu.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                       from GAL_BUDGET
                                                      where GAL_PROJECT_ID = v_gal_project_id
                                                 connect by prior gal_budget_id = gal_father_budget_id
                                                 start with gal_budget_id = a_id   -- Budget + Sous Budget
                                                                                )
                    order by bu.BDG_CODE) loop
          if cBU.GAL_BUDGET_ID <> a_id then
            cpt  := cpt + 1;
          end if;

          if cpt = 1 then
            WARNING_HOLD(out_warning);
          end if;

          if cBU.GAL_BUDGET_ID <> a_id then
            out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);
          end if;

          -- Contrôle TAC non soldées/suspendues
          begin
            for cTA in (select   ta.GAL_TASK_ID
                               , ta.TAS_CODE
                               , ta.TAS_WORDING
                            from GAL_TASK ta
                           where ta.C_TAS_STATE <> '40'
                             and ta.C_TAS_STATE <> '99'
                             and ta.GAL_BUDGET_ID = Cbu.GAL_BUDGET_ID
                        order by ta.TAS_CODE) loop
              cpt          := cpt + 1;

              if cpt = 1 then
                WARNING_HOLD(out_warning);
              end if;

              out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Tâche') || ' : ' || cTA.TAS_CODE || ' / ' || cTA.TAS_WORDING || chr(10);

              -- Contrôle OP non soldées/suspendues
              begin
                for cOP in (select   op.SCS_STEP_NUMBER
                                   , op.SCS_SHORT_DESCR
                                from GAL_TASK_LINK op
                               where op.C_TAL_STATE <> '40'
                                 and op.C_TAL_STATE <> '99'
                                 and op.GAL_TASK_ID = Cta.GAL_TASK_ID
                            order by op.SCS_STEP_NUMBER) loop
                  out_warning  :=
                    rtrim(out_warning) ||
                    PCS.PC_FUNCTIONS.TranslateWord('Opération') ||
                    ' : ' ||
                    cTA.TAS_CODE ||
                    ' / ' ||
                    cOP.SCS_STEP_NUMBER ||
                    ' / ' ||
                    cOP.SCS_SHORT_DESCR ||
                    chr(10);
                end loop;
              end;
            end loop;
          end;
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'POST', 'CTRL', 'BUD', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'PRE', 'MAJ', 'BUD', a_id, out_warning, out_error);
      end if;

      UPDATE_HOLD_BUDGET(a_id, d_date_trt, a_comment, v_gal_project_id);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'POST', 'MAJ', 'BUD', a_id, out_warning, out_error);
      end if;
    end if;
  end hold_budget;

--**********************************************************************************************************--

  --********** Réactivation d'un code budget ***********************************************************************--
  procedure reopen_budget(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_budget.BDG_BALANCE_DATE%type
  , a_comment               gal_budget.BDG_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_bdg_state        gal_budget.c_bdg_state%type            := null;
    v_gal_project_id     gal_project.gal_project_id%type        := null;
    v_c_prj_state        gal_project.c_prj_state%type           := null;
    v_gal_budgetP_id     gal_budget.gal_father_budget_id%type   := null;
    v_c_bdgP_state       gal_budget.c_bdg_state%type            := null;
    cpt                  number                                 := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'PRE', 'CTRL', 'BUD', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture budget
      begin
        select C_BDG_STATE
             , GAL_PROJECT_ID
             , GAL_FATHER_BUDGET_ID
          into v_c_bdg_state
             , v_gal_project_id
             , v_gal_budgetP_id
          from gal_budget
         where GAL_BUDGET_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_bdg_state     := null;
          v_gal_project_id  := null;
          v_gal_budgetP_id  := null;
      end;

      if     v_c_bdg_state <> '30'
         and v_c_bdg_state <> '40'
         and v_c_bdg_state <> '99' then
        ERREUR_CODE_ETAT_BUDGET(out_error);
      end if;

      -- Lecture affaire
      begin
        select C_PRJ_STATE
          into v_c_prj_state
          from gal_project
         where GAL_PROJECT_ID = v_gal_project_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_prj_state  := null;
      end;

      if    v_c_prj_state = '30'
         or v_c_prj_state = '40'
         or v_c_prj_state = '99' then
        ERREUR_CODE_ETAT_AFFAIRE(out_error);
      end if;

      -- Lecture budget père
      if v_gal_budgetP_id is not null then
        begin
          select C_BDG_STATE
            into v_c_bdgP_state
            from gal_budget
           where GAL_BUDGET_ID = v_gal_budgetP_id;
        exception
          when no_data_found then
            ERREUR_DONNEE_MANQUANTE(out_error);
            v_c_bdgP_state  := null;
        end;

        if    v_c_bdgP_state = '30'
           or v_c_bdgP_state = '40'
           or v_c_bdgP_state = '99' then
          ERREUR_CODE_ETAT_BUDGET_PERE(out_error);
        end if;
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      -- Contrôle sous BUD livrées, soldés ou suspendues
      cpt  := 0;

      begin
        for cBU in (select   bu.GAL_BUDGET_ID
                           , bu.BDG_CODE
                           , bu.BDG_WORDING
                        from GAL_BUDGET bu
                       where (    (    bu.gal_budget_id = a_id
                                   and (   bu.C_BDG_STATE = '30'
                                        or bu.C_BDG_STATE = '40'
                                        or bu.C_BDG_STATE = '99') )
                              or (    bu.gal_budget_id <> a_id
                                  and bu.C_BDG_STATE = '99')
                             )
                         and bu.GAL_BUDGET_ID in(select     GAL_BUDGET_ID
                                                       from GAL_BUDGET
                                                      where GAL_PROJECT_ID = v_gal_project_id
                                                 connect by prior gal_budget_id = gal_father_budget_id
                                                 start with gal_budget_id = a_id   -- Budget + Sous Budget
                                                                                )
                    order by bu.BDG_CODE) loop
          if cBU.GAL_BUDGET_ID <> a_id then
            cpt  := cpt + 1;
          end if;

          if cpt = 1 then
            WARNING_REOPEN(out_warning);
          end if;

          if cBU.GAL_BUDGET_ID <> a_id then
            out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Budget') || ' : ' || cBU.BDG_CODE || ' / ' || cBU.BDG_WORDING || chr(10);
          end if;

          -- Contrôle TAC suspendues
          begin
            for cTA in (select   ta.GAL_TASK_ID
                               , ta.TAS_CODE
                               , ta.TAS_WORDING
                            from GAL_TASK ta
                           where ta.C_TAS_STATE = '99'
                             and ta.GAL_BUDGET_ID = Cbu.GAL_BUDGET_ID
                        order by ta.TAS_CODE) loop
              cpt          := cpt + 1;

              if cpt = 1 then
                WARNING_REOPEN(out_warning);
              end if;

              out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Tâche') || ' : ' || cTA.TAS_CODE || ' / ' || cTA.TAS_WORDING || chr(10);

              -- Contrôle OP suspendues
              begin
                for cOP in (select   op.SCS_STEP_NUMBER
                                   , op.SCS_SHORT_DESCR
                                from GAL_TASK_LINK op
                               where op.C_TAL_STATE = '99'
                                 and op.GAL_TASK_ID = cTA.GAL_TASK_ID
                            order by op.SCS_STEP_NUMBER) loop
                  out_warning  :=
                    rtrim(out_warning) ||
                    PCS.PC_FUNCTIONS.TranslateWord('Opération') ||
                    ' : ' ||
                    cTA.TAS_CODE ||
                    ' / ' ||
                    cOP.SCS_STEP_NUMBER ||
                    ' / ' ||
                    cOP.SCS_SHORT_DESCR ||
                    chr(10);
                end loop;
              end;
            end loop;
          end;
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'POST', 'CTRL', 'BUD', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'PRE', 'MAJ', 'BUD', a_id, out_warning, out_error);
      end if;

      UPDATE_REOPEN_BUDGET(a_id, d_date_trt, a_comment, v_gal_project_id);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'POST', 'MAJ', 'BUD', a_id, out_warning, out_error);
      end if;
    end if;
  end reopen_budget;

--**********************************************************************************************************--

  --********** Lancement d'une tâche ***********************************************************************--
  procedure launch_task(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_task.TAS_LAUNCHING_DATE%type
  , a_comment               gal_task.TAS_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_tas_state        gal_task.c_tas_state%type                := null;
    v_tas_start_date     gal_task.tas_start_date%type             := null;
    v_tas_end_date       gal_task.tas_end_date%type               := null;
    v_c_prj_state        gal_project.c_prj_state%type             := null;
    v_gal_project_id     gal_task.gal_project_id%type             := null;
    v_sessionID          number                                   := null;
    v_trace              char                                     := null;
    v_exist              number                                   := 0;
    v_tca_task_type      GAL_TASK_CATEGORY.C_TCA_TASK_TYPE%type;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'LAUNCH', 'PRE', 'CTRL', 'TAS', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture tâche
      begin   --SELECT C_TCA_TASK_TYPE FROM GAL_TASK_CATEGORY WHERE GAL_TASK_CATEGORY_ID = :P_GAL_TASK_CATEGORY_ID
        select C_TAS_STATE
             , TAS_START_DATE
             , TAS_END_DATE
             , GAL_PROJECT_ID
             , C_TCA_TASK_TYPE
          into v_c_tas_state
             , v_tas_start_date
             , v_tas_end_date
             , v_gal_project_id
             , v_tca_task_type
          from GAL_TASK_CATEGORY
             , GAL_TASK
         where GAL_TASK_CATEGORY.GAL_TASK_CATEGORY_ID = GAL_TASK.GAL_TASK_CATEGORY_ID
           and GAL_TASK_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_tas_state     := null;
          v_tas_start_date  := null;
          v_tas_end_date    := null;
          v_gal_project_id  := null;
          v_tca_task_type   := null;
      end;

      -- Lecture affaire
      begin
        select C_PRJ_STATE
          into v_c_prj_state
          from gal_project
         where GAL_PROJECT_ID = v_gal_project_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_prj_state  := null;
      end;

      if     v_c_prj_state is not null
         and v_c_prj_state < '20' then
        out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('L''affaire n''a pas été lancée') || chr(10);
      end if;

      if    v_tas_start_date is null
         or v_tas_end_date is null then
        out_error  := rtrim(out_error) || PCS.PC_FUNCTIONS.TranslateWord('Il manque une date sur la tâche') || chr(10);
      end if;

      if v_c_tas_state >= '20' then
        ERREUR_CODE_ETAT_TACHE(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'LAUNCH', 'POST', 'CTRL', 'TAS', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'LAUNCH', 'PRE', 'MAJ', 'TAS', a_id, out_warning, out_error);
      end if;

      UPDATE_LAUNCH_TASK(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'LAUNCH', 'POST', 'MAJ', 'TAS', a_id, out_warning, out_error);
      end if;
    end if;
  end launch_task;

--**********************************************************************************************************--

  --********** Solde d'une tâche ***********************************************************************--
  procedure close_task(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_task.TAS_BALANCE_DATE%type
  , a_comment               gal_task.TAS_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_tas_state        gal_task.c_tas_state%type     := null;
    v_doc_record_id      gal_task.doc_record_id%type   := null;
    mes_error            clob                          := null;
    cpt                  number                        := 0;
    v_gal_ind_treatments varchar2(255);
    lCount               number                        := 0;
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'PRE', 'CTRL', 'TAS', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture tâche
      begin
        select C_TAS_STATE
             , DOC_RECORD_ID
          into v_c_tas_state
             , v_doc_record_id
          from gal_task
         where GAL_TASK_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_tas_state    := null;
          v_doc_record_id  := null;
      end;

      if v_c_tas_state = '40' then
        ERREUR_CODE_ETAT_TACHE(out_error);
      end if;

      -- Lecture DF lié à la tâche et non soldé
      select count(*)
        into lCount
        from gal_task
       where C_TAS_STATE <> '40'
         and GAL_FATHER_TASK_ID = a_id;

      if lCount > 0 then
        ERREUR_CODE_ETAT_TACHE_DF(out_error);
      end if;

      -- Contrôle Données en cours sur dossier TAC
      if v_doc_record_id is not null then
        out_error  := rtrim(out_error) || CONTROLE_EN_COURS_SUR_DOSSIER(v_doc_record_id, 'A');
      end if;

      -- Contrôle Données en cours sur dossier OP
      begin
        for cOP in (select   ta.TAS_CODE
                           , op.SCS_STEP_NUMBER
                           , op.SCS_SHORT_DESCR
                           , op.DOC_RECORD_ID
                        from GAL_TASK_LINK op
                           , GAL_TASK ta
                       where op.GAL_TASK_ID = ta.GAL_TASK_ID
                         and ta.GAL_TASK_ID = a_id
                         and op.DOC_RECORD_ID is not null
                    order by op.SCS_STEP_NUMBER) loop
          mes_error  := CONTROLE_EN_COURS_SUR_DOSSIER(cOP.doc_record_id, 'A');

          if mes_error is not null then
            out_error  :=
              rtrim(out_error) ||
              '+' ||
              PCS.PC_FUNCTIONS.TranslateWord('Opération') ||
              ' : ' ||
              cOP.TAS_CODE ||
              ' / ' ||
              cOP.SCS_STEP_NUMBER ||
              ' / ' ||
              cOP.SCS_SHORT_DESCR ||
              chr(10);
            out_error  := rtrim(out_error) || mes_error;
          end if;
        end loop;
      end;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      if v_c_tas_state < '20' then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cette tâche n''a pas été lancée') || chr(10);
      end if;

      if v_c_tas_state = '99' then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cette tâche est suspendue') || chr(10);
      end if;

      -- Contrôle OP non soldées non suspendues
      cpt  := 0;

      begin
        for cOP in (select   op.SCS_STEP_NUMBER
                           , op.SCS_SHORT_DESCR
                        from GAL_TASK_LINK op
                       where op.GAL_TASK_ID = a_id
                         and op.C_TAL_STATE <> '40'
                    order by op.SCS_STEP_NUMBER) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_CLOSE(out_warning);
          end if;

          out_warning  :=
                      rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Opération') || ' : ' || cOP.SCS_STEP_NUMBER || ' / ' || cOP.SCS_SHORT_DESCR
                      || chr(10);
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'POST', 'CTRL', 'TAS', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'PRE', 'MAJ', 'TAS', a_id, out_warning, out_error);
      end if;

      UPDATE_CLOSE_TASK(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'POST', 'MAJ', 'TAS', a_id, out_warning, out_error);
      end if;
    end if;
  end close_task;

--**********************************************************************************************************--

  --********** Suspension d'une tâche ***********************************************************************--
  procedure hold_task(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_task.TAS_HANGING_DATE%type
  , a_comment               gal_task.TAS_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_tas_state        gal_task.c_tas_state%type   := null;
    cpt                  number                      := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'PRE', 'CTRL', 'TAS', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture tâche
      begin
        select C_TAS_STATE
          into v_c_tas_state
          from gal_task
         where GAL_TASK_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_tas_state  := null;
      end;

      if    v_c_tas_state = '40'
         or v_c_tas_state = '99' then
        ERREUR_CODE_ETAT_TACHE(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      if v_c_tas_state < '20' then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cette tâche n''a pas été lancée') || chr(10);
      end if;

      -- Contrôle OP non soldées non suspendues
      cpt  := 0;

      begin
        for cOP in (select   op.SCS_STEP_NUMBER
                           , op.SCS_SHORT_DESCR
                        from GAL_TASK_LINK op
                       where op.GAL_TASK_ID = a_id
                         and op.C_TAL_STATE <> '40'
                         and op.C_TAL_STATE <> '99'
                    order by op.SCS_STEP_NUMBER) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_HOLD(out_warning);
          end if;

          out_warning  :=
                      rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Opération') || ' : ' || cOP.SCS_STEP_NUMBER || ' / ' || cOP.SCS_SHORT_DESCR
                      || chr(10);
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'POST', 'CTRL', 'TAS', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'PRE', 'MAJ', 'TAS', a_id, out_warning, out_error);
      end if;

      UPDATE_HOLD_TASK(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'POST', 'MAJ', 'TAS', a_id, out_warning, out_error);
      end if;
    end if;
  end hold_task;

--**********************************************************************************************************--

  --********** Réactivation d'une tâche ***********************************************************************--
  procedure reopen_task(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_task.TAS_BALANCE_DATE%type
  , a_comment               gal_task.TAS_COMMENT%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_tas_state        gal_task.c_tas_state%type     := null;
    v_gal_budget_id      gal_task.gal_budget_id%type   := null;
    v_c_bdg_state        gal_budget.c_bdg_state%type   := null;
    cpt                  number                        := 0;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'PRE', 'CTRL', 'TAS', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture tâche
      begin
        select C_TAS_STATE
             , GAL_BUDGET_ID
          into v_c_tas_state
             , v_gal_budget_id
          from gal_task
         where GAL_TASK_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_tas_state    := null;
          v_gal_budget_id  := null;
      end;

      if     v_c_tas_state <> '40'
         and v_c_tas_state <> '99' then
        ERREUR_CODE_ETAT_TACHE(out_error);
      end if;

      -- Lecture budget
      begin
        select C_BDG_STATE
          into v_c_bdg_state
          from gal_budget
         where GAL_BUDGET_ID = v_gal_budget_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_bdg_state  := null;
      end;

      if    v_c_bdg_state = '40'
         or v_c_bdg_state = '99' then
        ERREUR_CODE_ETAT_BUDGET(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      -- Contrôle OP suspendues
      cpt  := 0;

      begin
        for cOP in (select   op.SCS_STEP_NUMBER
                           , op.SCS_SHORT_DESCR
                        from GAL_TASK_LINK op
                       where op.GAL_TASK_ID = a_id
                         and op.C_TAL_STATE = '99'
                    order by op.SCS_STEP_NUMBER) loop
          cpt          := cpt + 1;

          if cpt = 1 then
            WARNING_REOPEN(out_warning);
          end if;

          out_warning  :=
                      rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Opération') || ' : ' || cOP.SCS_STEP_NUMBER || ' / ' || cOP.SCS_SHORT_DESCR
                      || chr(10);
        end loop;
      end;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'POST', 'CTRL', 'TAS', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'PRE', 'MAJ', 'TAS', a_id, out_warning, out_error);
      end if;

      UPDATE_REOPEN_TASK(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'POST', 'MAJ', 'TAS', a_id, out_warning, out_error);
      end if;
    end if;
  end reopen_task;

--**********************************************************************************************************--

  --********** Solde d'une opération ***********************************************************************--
  procedure close_task_link(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_task_link.TAL_BALANCE_DATE%type
  , a_comment               gal_task_link.SCS_FREE_DESCR%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_tal_state        gal_task_link.c_tal_state%type   := null;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'PRE', 'CTRL', 'LNK', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture opération
      begin
        select C_TAL_STATE
          into v_c_tal_state
          from gal_task_link
         where GAL_TASK_LINK_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_tal_state  := null;
      end;

      if v_c_tal_state = '40' then
        ERREUR_CODE_ETAT_OPERATION(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      if v_c_tal_state < '20' then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cette opération n''a pas été lancée') || chr(10);
      end if;

      if v_c_tal_state = '99' then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cette opération est suspendue') || chr(10);
      end if;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'POST', 'CTRL', 'LNK', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'PRE', 'MAJ', 'LNK', a_id, out_warning, out_error);
      end if;

      UPDATE_CLOSE_TASK_LINK(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'CLOSE', 'POST', 'MAJ', 'LNK', a_id, out_warning, out_error);
      end if;
    end if;
  end close_task_link;

--**********************************************************************************************************--

  --********** Réactivation d'une opération ***********************************************************************--
  procedure reopen_task_link(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_task_link.TAL_BALANCE_DATE%type
  , a_comment               gal_task_link.SCS_FREE_DESCR%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_tal_state        gal_task_link.c_tal_state%type   := null;
    v_gal_task_id        gal_task_link.gal_task_id%type   := null;
    v_c_tas_state        gal_task.c_tas_state%type        := null;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'PRE', 'CTRL', 'LNK', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture opération
      begin
        select C_TAL_STATE
             , GAL_TASK_ID
          into v_c_tal_state
             , v_gal_task_id
          from gal_task_link
         where GAL_TASK_LINK_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_tal_state  := null;
          v_gal_task_id  := null;
      end;

      if     v_c_tal_state <> '40'
         and v_c_tal_state <> '99' then
        ERREUR_CODE_ETAT_OPERATION(out_error);
      end if;

      begin
        -- Lecture tâche
        select C_TAS_STATE
          into v_c_tas_state
          from gal_task
         where GAL_TASK_ID = v_gal_task_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_tas_state  := null;
      end;

      if    v_c_tas_state = '40'
         or v_c_tas_state = '99' then
        ERREUR_CODE_ETAT_TACHE(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'POST', 'CTRL', 'LNK', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'PRE', 'MAJ', 'LNK', a_id, out_warning, out_error);
      end if;

      UPDATE_REOPEN_TASK_LINK(a_id, d_date_trt, a_comment, v_c_tas_state);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'REOPEN', 'POST', 'MAJ', 'LNK', a_id, out_warning, out_error);
      end if;
    end if;
  end reopen_task_link;

--**********************************************************************************************************--

  --********** Suspendre une opération ***********************************************************************--
  procedure hold_task_link(
    a_treatment_type        varchar2
  , a_id                    varchar2
  , d_date_trt              gal_task_link.TAL_BALANCE_DATE%type
  , a_comment               gal_task_link.SCS_FREE_DESCR%type
  , out_warning      in out clob
  , out_error        in out clob
  )
  is
    v_c_tal_state        gal_task_link.c_tal_state%type   := null;
    v_gal_ind_treatments varchar2(255);
  begin
    --Entrée Traitement indiv
    begin
      select gal_treatments.Getconf_ind_treatments
        into v_gal_ind_treatments
        from dual;
    exception
      when no_data_found then
        v_gal_ind_treatments  := null;
    end;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'PRE', 'CTRL', 'LNK', a_id, out_warning, out_error);
    end if;

    begin
      -- Contrôles bloquants dans tous les cas ------------------------------------------------------
      -- Lecture opération
      begin
        select C_TAL_STATE
          into v_c_tal_state
          from gal_task_link
         where GAL_TASK_LINK_ID = a_id;
      exception
        when no_data_found then
          ERREUR_DONNEE_MANQUANTE(out_error);
          v_c_tal_state  := null;
      end;

      if    v_c_tal_state = '40'
         or v_c_tal_state = '99' then
        ERREUR_CODE_ETAT_OPERATION(out_error);
      end if;
    exception
      when others then
        out_error  := trim(out_error) || '...' || chr(10);
    end;

    if out_error is not null then
      ERREUR_TRAITEMENT_INTERDIT(out_error);
    end if;

    -- Contrôles non bloquants seulement si pas d'erreur et traitement de contrôle ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'CTRL' then
      if v_c_tal_state < '20' then
        out_warning  := rtrim(out_warning) || PCS.PC_FUNCTIONS.TranslateWord('Cette opération n''a pas été lancée') || chr(10);
      end if;

      WARNING_VALIDER_TRAITEMENT(out_warning);
    end if;

    if trim(v_gal_ind_treatments) is not null then
      gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'POST', 'CTRL', 'LNK', a_id, out_warning, out_error);
    end if;

    -- Mises à jour ----------------
    if     out_error is null
       and upper(a_treatment_type) = 'MAJ' then
      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'PRE', 'MAJ', 'LNK', a_id, out_warning, out_error);
      end if;

      UPDATE_HOLD_TASK_LINK(a_id, d_date_trt, a_comment);
      WARNING_TRAITEMENT_TERMINE(out_warning);

      if trim(v_gal_ind_treatments) is not null then
        gal_treatments.IND_GAL_TREATMENTS(v_gal_ind_treatments, 'HOLD', 'POST', 'MAJ', 'LNK', a_id, out_warning, out_error);
      end if;
    end if;
  end hold_task_link;
--**********************************************************************************************************--
end gal_treatments;
