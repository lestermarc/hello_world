--------------------------------------------------------
--  DDL for Package Body DOC_QUE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_QUE_FCT" 
/**
 * Procedures et fonctions pour la réplication de documents
 * inter sociétés par Advanced Queueing pour le domaine DOC.
 *
 * @version 1.1
 * @date 10/2006
 * @author rforchelet
 * @author spfister
 * @since Oracle 9.2
 * @see Package REP_QUE_FCT
 *
 * Copyright 1997-2012 Pro-Concept SA. Tous droits réservés.
 */
is
  -- collection des références
  gttReferences              rep_que_fct.TT_REFERENCE_PROPERTIES_LIST;
  -- entités réplicables
  gcn_RECORD        constant integer                                  := 0;
  gcn_CATEGORY      constant integer                                  := gcn_RECORD + 1;
  gcn_CAT_LINK_TYPE constant integer                                  := gcn_CATEGORY + 1;

--
-- Documents
--
  procedure p_enqueue_record(
    in_record_id   in            doc_record.doc_record_id%type
  , iot_props      in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_record_id, iot_props, rep_functions.get_doc_record_XMLType(in_record_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_RECORD(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_RECORD).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from DOC_RECORD
           where DOC_RECORD_ID = ltt_publishable(cpt);
          p_enqueue_record(ltt_publishable(cpt), gttReferences(gcn_RECORD), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_RECORD).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_RECORD(pDOC_RECORD_ID in doc_record.doc_record_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_record(pDOC_RECORD_ID, gttReferences(gcn_RECORD), pSearchMode);
  end;

--
-- Catégories documents
--
  procedure p_enqueue_record_category(
    in_record_category_id in            doc_record_category.doc_record_category_id%type
  , iot_props             in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode        in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_record_category_id, iot_props, rep_functions.get_doc_record_cat_XMLType(in_record_category_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_RECORD_CATEGORY(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_CATEGORY).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from DOC_RECORD_CATEGORY
           where DOC_RECORD_CATEGORY_ID = ltt_publishable(cpt);
          p_enqueue_record_category(ltt_publishable(cpt), gttReferences(gcn_CATEGORY), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_CATEGORY).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_RECORD_CATEGORY(
    pDOC_RECORD_CATEGORY_ID in doc_record_category.doc_record_category_id%type
  , pSearchMode             in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_record_category(pDOC_RECORD_CATEGORY_ID, gttReferences(gcn_CATEGORY), pSearchMode);
  end;

--
-- Types de liens des catégories de documents
--
  procedure p_enqueue_rco_cat_lnk_type(
    in_record_cat_link_type_id in            doc_record_cat_link_type.doc_record_cat_link_type_id%type
  , iot_props                  in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode             in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_record_cat_link_type_id
                                  , iot_props
                                  , rep_functions.get_rco_cat_lnk_type_XMLType(in_record_cat_link_type_id, iv_search_mode)
                                   );
  end;

  procedure USE_ENQUEUE_RCO_CAT_LNK_TYPE(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_CAT_LINK_TYPE).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from DOC_RECORD_CAT_LINK_TYPE
           where DOC_RECORD_CAT_LINK_TYPE_ID = ltt_publishable(cpt);
          p_enqueue_rco_cat_lnk_type(ltt_publishable(cpt), gttReferences(gcn_CAT_LINK_TYPE), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_CAT_LINK_TYPE).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_RCO_CAT_LNK_TYPE(
    pDOC_RECORD_CAT_LINK_TYPE_ID in doc_record_cat_link_type.doc_record_cat_link_type_id%type
  , pSearchMode                  in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_rco_cat_lnk_type(pDOC_RECORD_CAT_LINK_TYPE_ID, gttReferences(gcn_CAT_LINK_TYPE), pSearchMode);
  end;
begin
  gttReferences(gcn_RECORD).object_name         := 'DOC_RECORD';
  gttReferences(gcn_RECORD).xpath               := '/DOCUMENTS/DOC_RECORD/RCO_TITLE/text()';
  gttReferences(gcn_CATEGORY).object_name       := 'DOC_RECORD_CATEGORY';
  gttReferences(gcn_CATEGORY).xpath             := '/CATEGORIES/DOC_RECORD_CATEGORY/RCY_KEY/text()';
  gttReferences(gcn_CAT_LINK_TYPE).object_name  := 'DOC_RECORD_CAT_LINK_TYPE';
  gttReferences(gcn_CAT_LINK_TYPE).xpath        := '/DOC_CATEGORIES_TYPE_LINKS/DOC_RECORD_CAT_LINK_TYPE/RLT_DESCR/text()';
end DOC_QUE_FCT;
