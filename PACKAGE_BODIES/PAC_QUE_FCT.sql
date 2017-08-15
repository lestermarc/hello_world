--------------------------------------------------------
--  DDL for Package Body PAC_QUE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_QUE_FCT" 
/**
 * Procedures et fonctions pour la réplication de documents
 * inter sociétés par Advanced Queueing pour le domaine PAC.
 *
 * @version 1.0
 * @date 05/2003
 * @author spfister
 * @since Oracle 9.2
 * @see Package REP_QUE_FCT
 *
 * Copyright 1997-2012 Pro-Concept SA. Tous droits réservés.
 */
is
  -- collection des références
  gttReferences            rep_que_fct.TT_REFERENCE_PROPERTIES_LIST;
  -- entités réplicables
  gcn_ADDRESS     constant integer                                  := 0;
  gcn_ASSOCIATION constant integer                                  := gcn_ADDRESS + 1;

--
-- Partenaires
--
  procedure p_enqueue_person(
    in_person_id   in            pac_person.pac_person_id%type
  , iot_props      in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_person_id, iot_props, rep_functions.get_pac_person_XMLType(in_person_id, iv_search_mode) );
    pac_que_fct.use_enqueue_association(in_person_id, iv_search_mode);
  end;

  procedure USE_ENQUEUE_PERSON(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_ADDRESS).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from PAC_PERSON
           where PAC_PERSON_ID = ltt_publishable(cpt);
          p_enqueue_person(ltt_publishable(cpt), gttReferences(gcn_ADDRESS), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_ADDRESS).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_PERSON(pPAC_PERSON_ID in pac_person.pac_person_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_person(pPAC_PERSON_ID, gttReferences(gcn_ADDRESS), pSearchMode);
  end;

--
-- Contacts
--
  procedure p_enqueue_association(
    in_person_id   in            pac_person.pac_person_id%type
  , iot_props      in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_person_id, iot_props, rep_functions.get_pac_person_assoc_XMLType(in_person_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_ASSOCIATION(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_ASSOCIATION).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from PAC_PERSON_ASSOCIATION
           where PAC_PERSON_ID = ltt_publishable(cpt)
             and rownum = 1;
          p_enqueue_association(ltt_publishable(cpt), gttReferences(gcn_ASSOCIATION), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_ASSOCIATION).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_ASSOCIATION(pPAC_PERSON_ID in pac_person.pac_person_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_association(pPAC_PERSON_ID, gttReferences(gcn_ASSOCIATION), pSearchMode);
  end;
begin
  gttReferences(gcn_ADDRESS).object_name      := 'PAC_ADDRESS';
  gttReferences(gcn_ADDRESS).xpath            := '/PERSONS/PAC_PERSON/PER_KEY1/text()';
  gttReferences(gcn_ASSOCIATION).object_name  := 'PAC_PERSON_ASSOCIATION';
  gttReferences(gcn_ASSOCIATION).xpath        := '/PERSON_ASSOCIATIONS/PAC_PERSON_ASSOCIATION[1]/PAC_PERSON/PER_KEY1/text()';
end PAC_QUE_FCT;
