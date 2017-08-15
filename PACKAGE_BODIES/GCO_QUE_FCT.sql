--------------------------------------------------------
--  DDL for Package Body GCO_QUE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_QUE_FCT" 
/**
 * Procedures et fonctions pour la réplication de documents
 * inter sociétés par Advanced Queueing pour le domaine GCO.
 *
 * @version 1.1
 * @date 10/2002
 * @author rrimbert
 * @author spfister
 * @since Oracle 9.2
 * @see Package REP_QUE_FCT
 *
 * Copyright 1997-2012 Pro-Concept SA. Tous droits réservés.
 */
is
  -- collection des références
  gttReferences                  rep_que_fct.TT_REFERENCE_PROPERTIES_LIST;
  -- entités réplicables
  gcn_PRODUCT           constant integer                                  := 0;
  gcn_CATEGORY          constant integer                                  := gcn_PRODUCT + 1;
  gcn_ATTRIBUTE_FIELDS  constant integer                                  := gcn_CATEGORY + 1;
  gcn_PRODUCT_GROUP     constant integer                                  := gcn_ATTRIBUTE_FIELDS + 1;
  gcn_DISTRIBUTION_UNIT constant integer                                  := gcn_PRODUCT_GROUP + 1;
  gcn_ALLOY             constant integer                                  := gcn_DISTRIBUTION_UNIT + 1;
  gcn_QUALITY_STATUS    constant integer                                  := gcn_ALLOY + 1;
  gcn_QUALITY_STAT_FLOW constant integer                                  := gcn_QUALITY_STATUS + 1;

--
-- Articles
--
  procedure p_enqueue_good(in_good_id in gco_good.gco_good_id%type, iot_props in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES, iv_search_mode in varchar2)
  is
  begin
    rep_que_fct.enqueue_publishable(in_good_id, iot_props, rep_functions.get_gco_good_XMLType(in_good_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_GOOD(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_PRODUCT).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from GCO_GOOD
           where GCO_GOOD_ID = ltt_publishable(cpt);

          p_enqueue_good(ltt_publishable(cpt), gttReferences(gcn_PRODUCT), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_PRODUCT).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_GOOD(pGCO_GOOD_ID in gco_good.gco_good_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_good(pGCO_GOOD_ID, gttReferences(gcn_PRODUCT), pSearchMode);
  end;


--
-- Catégories articles
--
  procedure p_enqueue_category(
    in_good_category_id in            gco_good_category.gco_good_category_id%type
  , iot_props           in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode      in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_good_category_id, iot_props, rep_functions.get_gco_good_category_XMLType(in_good_category_id, iv_search_mode) );
    gco_que_fct.use_enqueue_attribute_fields(in_good_category_id, iv_search_mode);
  end;

  procedure USE_ENQUEUE_CATEGORY(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
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
            from GCO_GOOD_CATEGORY
           where GCO_GOOD_CATEGORY_ID = ltt_publishable(cpt);

          p_enqueue_category(ltt_publishable(cpt), gttReferences(gcn_CATEGORY), pSearchMode);
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

  procedure USE_ENQUEUE_CATEGORY(pGCO_GOOD_CATEGORY_ID in gco_good_category.gco_good_category_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_category(pGCO_GOOD_CATEGORY_ID, gttReferences(gcn_CATEGORY), pSearchMode);
  end;

  procedure p_enqueue_quality_status(in_QUALITY_STATUS_id in gco_QUALITY_STATUS.gco_QUALITY_STATUS_id%type, iot_props in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES, iv_search_mode in varchar2)
  is
  begin
    rep_que_fct.enqueue_publishable(in_QUALITY_STATUS_id, iot_props, rep_functions.get_gco_QUALITY_STATUS_XMLType(in_QUALITY_STATUS_id, iv_search_mode) );
  end p_enqueue_quality_status;

  procedure USE_ENQUEUE_QUALITY_STATUS(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_QUALITY_STATUS).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from GCO_QUALITY_STATUS
           where GCO_QUALITY_STATUS_ID = ltt_publishable(cpt);

          p_enqueue_QUALITY_STATUS(ltt_publishable(cpt), gttReferences(gcn_QUALITY_STATUS), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_QUALITY_STATUS).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end USE_ENQUEUE_QUALITY_STATUS;

  procedure USE_ENQUEUE_QUALITY_STATUS(pGCO_QUALITY_STATUS_ID in gco_QUALITY_STATUS.gco_QUALITY_STATUS_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_QUALITY_STATUS(pGCO_QUALITY_STATUS_ID, gttReferences(gcn_QUALITY_STATUS), pSearchMode);
  end USE_ENQUEUE_QUALITY_STATUS;


  procedure p_enqueue_QUALITY_STAT_FLOW(in_QUALITY_STAT_FLOW_id in gco_QUALITY_STAT_FLOW.gco_QUALITY_STAT_FLOW_id%type, iot_props in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES, iv_search_mode in varchar2)
  is
  begin
    rep_que_fct.enqueue_publishable(in_QUALITY_STAT_FLOW_id, iot_props, rep_functions.get_gco_qual_stat_flow_XMLType(in_QUALITY_STAT_FLOW_id, iv_search_mode) );
  end p_enqueue_QUALITY_STAT_FLOW;

  procedure USE_ENQUEUE_QUALITY_STAT_FLOW(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_QUALITY_STAT_FLOW).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from GCO_QUALITY_STAT_FLOW
           where GCO_QUALITY_STAT_FLOW_ID = ltt_publishable(cpt);

          p_enqueue_QUALITY_STAT_FLOW(ltt_publishable(cpt), gttReferences(gcn_QUALITY_STAT_FLOW), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_QUALITY_STAT_FLOW).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end USE_ENQUEUE_QUALITY_STAT_FLOW;

  procedure USE_ENQUEUE_QUALITY_STAT_FLOW(pGCO_QUALITY_STAT_FLOW_ID in gco_QUALITY_STAT_FLOW.gco_QUALITY_STAT_FLOW_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_QUALITY_STAT_FLOW(pGCO_QUALITY_STAT_FLOW_ID, gttReferences(gcn_QUALITY_STAT_FLOW), pSearchMode);
  end USE_ENQUEUE_QUALITY_STAT_FLOW;

  procedure p_enqueue_attribute_fields(
    in_good_category_id in            gco_good_category.gco_good_category_id%type
  , iot_props           in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode      in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_good_category_id, iot_props, rep_functions.get_gco_attribute_flds_XMLType(in_good_category_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_ATTRIBUTE_FIELDS(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_ATTRIBUTE_FIELDS).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from GCO_ATTRIBUTE_FIELDS f
               , GCO_GOOD_CATEGORY c
           where c.GCO_GOOD_CATEGORY_ID = ltt_publishable(cpt)
             and   -- Liaison avec les 20 champs du dictionnaire
                 f.DIC_TABSHEET_ATTRIBUTE_ID in
                   (c.DIC_TABSHEET_ATTRIBUTE_1_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_2_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_3_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_4_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_5_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_6_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_7_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_8_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_9_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_10_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_11_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_12_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_13_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_14_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_15_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_16_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_17_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_18_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_19_ID
                  , c.DIC_TABSHEET_ATTRIBUTE_20_ID
                   )
             and rownum = 1;

          p_enqueue_attribute_fields(ltt_publishable(cpt), gttReferences(gcn_ATTRIBUTE_FIELDS), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_ATTRIBUTE_FIELDS).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_ATTRIBUTE_FIELDS(
    pGCO_GOOD_CATEGORY_ID in gco_good_category.gco_good_category_id%type
  , pSearchMode           in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_attribute_fields(pGCO_GOOD_CATEGORY_ID, gttReferences(gcn_ATTRIBUTE_FIELDS), pSearchMode);
  end;

--
-- Groupes de produits
--
  procedure p_enqueue_product_group(
    in_product_group_id in            gco_product_group.gco_product_group_id%type
  , iot_props           in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode      in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_product_group_id, iot_props, rep_functions.get_gco_product_group_XMLType(in_product_group_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_PRODUCT_GROUP(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_PRODUCT_GROUP).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from GCO_PRODUCT_GROUP
           where GCO_PRODUCT_GROUP_ID = ltt_publishable(cpt);

          p_enqueue_product_group(ltt_publishable(cpt), gttReferences(gcn_PRODUCT_GROUP), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_PRODUCT_GROUP).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_PRODUCT_GROUP(
    pGCO_PRODUCT_GROUP_ID in gco_product_group.gco_product_group_id%type
  , pSearchMode           in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_product_group(pGCO_PRODUCT_GROUP_ID, gttReferences(gcn_PRODUCT_GROUP), pSearchMode);
  end;

--
-- Unités de distribution
--
  procedure p_enqueue_distribution_unit(
    in_distribution_unit_id in            stm_distribution_unit.stm_distribution_unit_id%type
  , iot_props               in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode          in            varchar2
  )
  is
  begin
    rep_que_fct.enqueue_publishable(in_distribution_unit_id, iot_props, rep_functions.get_stm_distrib_unit_XMLType(in_distribution_unit_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_DISTRIBUTION_UNIT(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_DISTRIBUTION_UNIT).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from STM_DISTRIBUTION_UNIT
           where STM_DISTRIBUTION_UNIT_ID = ltt_publishable(cpt);

          p_enqueue_product_group(ltt_publishable(cpt), gttReferences(gcn_DISTRIBUTION_UNIT), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_DISTRIBUTION_UNIT).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_DISTRIBUTION_UNIT(
    pSTM_DISTRIBUTION_UNIT_ID in stm_distribution_unit.stm_distribution_unit_id%type
  , pSearchMode               in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_distribution_unit(pSTM_DISTRIBUTION_UNIT_ID, gttReferences(gcn_DISTRIBUTION_UNIT), pSearchMode);
  end;

--
-- Alliages
--
  procedure p_enqueue_alloy(in_alloy_id in gco_alloy.gco_alloy_id%type, iot_props in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES, iv_search_mode in varchar2)
  is
  begin
    rep_que_fct.enqueue_publishable(in_alloy_id, iot_props, rep_functions.get_gco_alloy_XMLType(in_alloy_id, iv_search_mode) );
  end;

  procedure USE_ENQUEUE_ALLOY(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_ALLOY).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from GCO_ALLOY
           where GCO_ALLOY_ID = ltt_publishable(cpt);

          p_enqueue_alloy(ltt_publishable(cpt), gttReferences(gcn_ALLOY), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_ALLOY).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_ALLOY(pGCO_ALLOY_ID in gco_alloy.gco_alloy_id%type, pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_alloy(pGCO_ALLOY_ID, gttReferences(gcn_ALLOY), pSearchMode);
  end;
begin
  gttReferences(gcn_PRODUCT).object_name            := 'GCO_PRODUCT';
  gttReferences(gcn_PRODUCT).xpath                  := '/ARTICLES/GCO_GOOD/GOO_MAJOR_REFERENCE/text()';
  gttReferences(gcn_CATEGORY).object_name           := 'GCO_GOOD_CATEGORY';
  gttReferences(gcn_CATEGORY).xpath                 := '/CATEGORIES/GCO_GOOD_CATEGORY/GCO_CATEGORY_CODE/text()';
  gttReferences(gcn_ATTRIBUTE_FIELDS).object_name   := 'GCO_ATTRIBUTE_FIELDS';
  gttReferences(gcn_ATTRIBUTE_FIELDS).xpath         := '/ATTRIBUTE_FIELDS/GCO_ATTRIBUTE_FIELDS[1]/DIC_TABSHEET_ATTRIBUTE/VALUE/text()';
  gttReferences(gcn_PRODUCT_GROUP).object_name      := 'GCO_PRODUCT_GROUP';
  gttReferences(gcn_PRODUCT_GROUP).xpath            := '/PRODUCT_GROUPS/GCO_PRODUCT_GROUP/PRG_NAME/text()';
  gttReferences(gcn_DISTRIBUTION_UNIT).object_name  := 'STM_DISTRIBUTION_UNIT';
  gttReferences(gcn_DISTRIBUTION_UNIT).xpath        := '/DISTRIBUTION_UNITS/STM_DISTRIBUTION_UNIT/DIU_NAME/text()';
  gttReferences(gcn_ALLOY).object_name              := 'GCO_ALLOY';
  gttReferences(gcn_ALLOY).xpath                    := '/ALLOYS/GCO_ALLOY/GAL_ALLOY_REF/text()';
  gttReferences(gcn_QUALITY_STATUS).object_name     := 'GCO_QUALITY_STATUS';
  gttReferences(gcn_QUALITY_STATUS).xpath           := '/QUALITY_STATUS/GCO_QUALITY_STATUS/QST_REFERENCE/text()';
  gttReferences(gcn_QUALITY_STAT_FLOW).object_name  := 'GCO_QUALITY_STAT_FLOW';
  gttReferences(gcn_QUALITY_STAT_FLOW).xpath        := '/QUALITY_STATUS_FLOW/GCO_QUALITY_STAT_FLOW/QSF_REFERENCE/text()';
end GCO_QUE_FCT;
