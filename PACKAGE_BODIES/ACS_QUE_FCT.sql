--------------------------------------------------------
--  DDL for Package Body ACS_QUE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_QUE_FCT" 
/**
 * Procedures et fonctions pour la réplication de documents
 * inter sociétés par Advanced Queueing pour le domaine ACS.
 *
 * @version 1.1
 * @date 06/2004
 * @author spfister
 * @author skalayci
 * @see Package REP_QUE_FCT
 *
 * Copyright 1997-2012 Pro-Concept SA. Tous droits réservés.
 */
is
  -- collection des références
  gttReferences                  rep_que_fct.TT_REFERENCE_PROPERTIES_LIST;
  -- entités réplicables
  gcn_ACCOUNT           constant integer                                  := 0;
  gcn_EVALUATION_METHOD constant integer                                  := gcn_ACCOUNT + 1;
  gcn_INTEREST_CATEG    constant integer                                  := gcn_EVALUATION_METHOD + 1;
  gcn_INT_CALC_METHOD   constant integer                                  := gcn_INTEREST_CATEG + 1;

--
-- Comptes
--
  procedure p_enqueue_account(
    in_account_id  in            acs_account.acs_account_id%type
  , iot_props      in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_account_id, iot_props, rep_functions.get_acs_account_XMLType(in_account_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_ACCOUNT(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_ACCOUNT).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from ACS_ACCOUNT
           where ACS_ACCOUNT_ID = ltt_publishable(cpt);

          p_enqueue_account(ltt_publishable(cpt), gttReferences(gcn_ACCOUNT), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_ACCOUNT).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_ACCOUNT(pACS_ACCOUNT_ID in acs_account.acs_account_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_account(pACS_ACCOUNT_ID, gttReferences(gcn_ACCOUNT), pSearchMode);
  end;

--
-- Méthodes de réévaluation
--
  procedure p_enqueue_evaluation_method(
    in_evaluation_method_id in            acs_evaluation_method.acs_evaluation_method_id%type
  , iot_props               in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode          in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_evaluation_method_id, iot_props, rep_functions.get_acs_eval_method_XMLType(in_evaluation_method_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_EVALUATION_METHOD(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_EVALUATION_METHOD).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from ACS_EVALUATION_METHOD
           where ACS_EVALUATION_METHOD_ID = ltt_publishable(cpt);

          p_enqueue_evaluation_method(ltt_publishable(cpt), gttReferences(gcn_EVALUATION_METHOD), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_EVALUATION_METHOD).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_EVALUATION_METHOD(
    pACS_EVALUATION_METHOD_ID in acs_evaluation_method.acs_evaluation_method_id%type
  , pSearchMode               in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_evaluation_method(pACS_EVALUATION_METHOD_ID, gttReferences(gcn_EVALUATION_METHOD), pSearchMode);
  end;

--
-- Catégories d'intérêts
--
  procedure p_enqueue_interest_categ(
    in_interest_categ_id in            acs_interest_categ.acs_interest_categ_id%type
  , iot_props            in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode       in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_interest_categ_id, iot_props, rep_functions.get_acs_interest_categ_XMLType(in_interest_categ_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_INTEREST_CATEG(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_INTEREST_CATEG).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from ACS_INTEREST_CATEG
           where ACS_INTEREST_CATEG_ID = ltt_publishable(cpt);

          p_enqueue_interest_categ(ltt_publishable(cpt), gttReferences(gcn_INTEREST_CATEG), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_INTEREST_CATEG).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_INTEREST_CATEG(
    pACS_INTEREST_CATEG_ID in acs_interest_categ.acs_interest_categ_id%type
  , pSearchMode            in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_interest_categ(pACS_INTEREST_CATEG_ID, gttReferences(gcn_INTEREST_CATEG), pSearchMode);
  end;

--
-- Méthodes de calcul des intérêts
--
  procedure p_enqueue_int_calc_method(
    in_int_calc_method_id in            acs_int_calc_method.acs_int_calc_method_id%type
  , iot_props             in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode        in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_int_calc_method_id, iot_props, rep_functions.get_acs_int_cal_method_XMLType(in_int_calc_method_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_INT_CALC_METHOD(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_INT_CALC_METHOD).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from ACS_INT_CALC_METHOD
           where ACS_INT_CALC_METHOD_ID = ltt_publishable(cpt);

          p_enqueue_int_calc_method(ltt_publishable(cpt), gttReferences(gcn_INT_CALC_METHOD), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_INT_CALC_METHOD).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_INT_CALC_METHOD(
    pACS_INT_CALC_METHOD_ID in acs_int_calc_method.acs_int_calc_method_id%type
  , pSearchMode             in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_int_calc_method(pACS_INT_CALC_METHOD_ID, gttReferences(gcn_INT_CALC_METHOD), pSearchMode);
  end;
begin
  gttReferences(gcn_ACCOUNT).object_name            := 'ACS_ACCOUNT';
  gttReferences(gcn_ACCOUNT).xpath                  := '/ACCOUNTS/ACS_ACCOUNT/ACC_NUMBER/text()';
  gttReferences(gcn_EVALUATION_METHOD).object_name  := 'ACS_EVALUATION_METHOD';
  gttReferences(gcn_EVALUATION_METHOD).xpath        := '/EVALUATION_METHODS/ACS_EVALUATION_METHOD/EVA_DESCR/text()';
  gttReferences(gcn_INTEREST_CATEG).object_name     := 'ACS_INTEREST_CATEG';
  gttReferences(gcn_INTEREST_CATEG).xpath           := '/INTEREST_CATEGS/ACS_INTEREST_CATEG/ICA_DESCRIPTION/text()';
  gttReferences(gcn_INT_CALC_METHOD).object_name    := 'ACS_INT_CALC_METHOD';
  gttReferences(gcn_INT_CALC_METHOD).xpath          := '/CALC_METHODS/ACS_INT_CALC_METHOD/ICM_DESCRIPTION/text()';
end ACS_QUE_FCT;
