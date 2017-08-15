--------------------------------------------------------
--  DDL for Package Body FAL_QUE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_QUE_FCT" 
/**
 * Procedures et fonctions pour la réplication de documents
 * inter sociétés par Advanced Queueing pour le domaine FAL.
 *
 * @version 1.0
 * @date 02/2012
 * @author dsaade
 * @author spfister
 * @see Package REP_QUE_FCT
 *
 * Copyright 1997-2012 Pro-Concept SA. Tous droits réservés.
 */
is
  -- collection des références
  gttReferences          rep_que_fct.TT_REFERENCE_PROPERTIES_LIST;
  gcn_SCH_PLAN  constant integer                                  := 0;
  gcn_TASK      constant integer                                  := gcn_SCH_PLAN + 1;
  gcn_FAC_FLOOR constant integer                                  := gcn_TASK + 1;

--
-- Gamme opératoire
--
  procedure p_enqueue_sch_plan(
    in_schedule_plan_id in            fal_schedule_plan.fal_schedule_plan_id%type
  , iot_props           in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode      in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_schedule_plan_id, iot_props, rep_functions.get_fal_schedule_plan_XMLType(in_schedule_plan_id, iv_search_mode), 'GAMME ');
  end;

  procedure USE_ENQUEUE_SCH_PLAN(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_SCH_PLAN).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from FAL_SCHEDULE_PLAN
           where FAL_SCHEDULE_PLAN_ID = ltt_publishable(cpt);
          p_enqueue_sch_plan(ltt_publishable(cpt), gttReferences(gcn_SCH_PLAN), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_SCH_PLAN).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_SCH_PLAN(pFAL_SCHEDULE_PLAN_ID in fal_schedule_plan.fal_schedule_plan_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_sch_plan(pFAL_SCHEDULE_PLAN_ID, gttReferences(gcn_SCH_PLAN), pSearchMode);
  end;

--
-- Opération standard
--
  procedure p_enqueue_task(in_task_id in fal_task.fal_task_id%type, iot_props in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES, iv_search_mode in varchar2)
  is
  begin
    rep_que_fct.enqueue_publishable(in_task_id, iot_props, rep_functions.get_fal_task_XMLType(in_task_id, iv_search_mode), 'OPERATION ');
  end;

  procedure USE_ENQUEUE_TASK(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_TASK).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from FAL_TASK
           where FAL_TASK_ID = ltt_publishable(cpt);
          p_enqueue_task(ltt_publishable(cpt), gttReferences(gcn_TASK), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_TASK).OBJECT_NAME);
          when others then
            null;
            --ra(sqlErrm);
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_TASK(pFAL_TASK_ID in fal_task.fal_task_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_task(pFAL_TASK_ID, gttReferences(gcn_TASK), pSearchMode);
  end;

--
-- Ateliers
--
  procedure p_enqueue_fac_floor(
    in_factory_floor_id in            fal_factory_floor.fal_factory_floor_id%type
  , iot_props           in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode      in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_factory_floor_id
                                  , iot_props
                                  , rep_functions.get_fal_factory_floor_XMLType(in_factory_floor_id, iv_search_mode)
                                  , 'ATELIER '
                                   );
  end;

  procedure USE_ENQUEUE_FAC_FLOOR(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_FAC_FLOOR).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from FAL_FACTORY_FLOOR
           where FAL_FACTORY_FLOOR_ID = ltt_publishable(cpt);
          p_enqueue_fac_floor(ltt_publishable(cpt), gttReferences(gcn_FAC_FLOOR), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_FAC_FLOOR).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_FAC_FLOOR(
    pFAL_FACTORY_FLOOR_ID in fal_factory_floor.fal_factory_floor_id%type
  , pSearchMode           in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_fac_floor(pFAL_FACTORY_FLOOR_ID, gttReferences(gcn_FAC_FLOOR), pSearchMode);
  end;
begin
  gttReferences(gcn_SCH_PLAN).object_name   := 'FAL_SCHEDULE_PLAN';
  gttReferences(gcn_SCH_PLAN).xpath         := '/SCHEDULE_PLANS/FAL_SCHEDULE_PLAN/SCH_REF/text()';
  gttReferences(gcn_TASK).object_name       := 'FAL_TASK';
  gttReferences(gcn_TASK).xpath             := '/TASKS/FAL_TASK/TAS_REF/text()';
  gttReferences(gcn_FAC_FLOOR).object_name  := 'FAL_FACTORY_FLOOR';
  gttReferences(gcn_FAC_FLOOR).xpath        := '/FACTORY_FLOORS/FAL_FACTORY_FLOOR/FAC_REFERENCE/text()';
end FAL_QUE_FCT;
