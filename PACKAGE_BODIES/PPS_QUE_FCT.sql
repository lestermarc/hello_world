--------------------------------------------------------
--  DDL for Package Body PPS_QUE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_QUE_FCT" 
/**
 * Procedures et fonctions pour la réplication de documents
 * inter sociétés par Advanced Queueing pour le domaine PPS.
 *
 * @version 1.1
 * @date 10/2002
 * @author rrimbert
 * @author spfister
 * @see Package REP_QUE_FCT
 *
 * Copyright 1997-2012 Pro-Concept SA. Tous droits réservés.
 */
is
  -- collection des références
  gttReferences             rep_que_fct.TT_REFERENCE_PROPERTIES_LIST;
  gcn_NOMENCLATURE constant integer                                  := 0;

--
-- Nomenclatures
--
  procedure p_enqueue_nomenclature(
    in_nomenclature_id in            pps_nomenclature.pps_nomenclature_id%type
  , iot_props          in out nocopy rep_que_fct.T_REFERENCE_PROPERTIES
  , iv_search_mode     in            varchar2
  )
  is
  begin
    if (rep_functions.IsBOMReplicable(in_nomenclature_id) = 1) then
      rep_que_fct.enqueue_publishable(in_nomenclature_id
                                    , iot_props
                                    , rep_functions.get_pps_nomenclature_XMLType(in_nomenclature_id, iv_search_mode)
                                    , 'NOMENCLATURE '
                                     );
    end if;
  end;

  procedure USE_ENQUEUE_NOMENCLATURE(pSearchMode in varchar2 default rep_utils.USE_KEY_VALUE)
  is
    ltt_publishable rep_que_fct.TT_PUBLISHABLE_LIST;
    ln_still_exists number(1);
  begin
    -- Chargement de la liste des identifiants publiables
    if (rep_que_fct.load_publishable(gttReferences(gcn_NOMENCLATURE).object_name, ltt_publishable) > 0) then
      -- Envoi de l'identifiant en queue et suppression de la liste de publication
      for cpt in ltt_publishable.first .. ltt_publishable.last loop
        begin
          -- Contrôle de la présence de l'élément dans le système
          select 1
            into ln_still_exists
            from PPS_NOMENCLATURE
           where PPS_NOMENCLATURE_ID = ltt_publishable(cpt);
          p_enqueue_nomenclature(ltt_publishable(cpt), gttReferences(gcn_NOMENCLATURE), pSearchMode);
        exception
          when no_data_found then
            -- Si l'élément n'existe plus, il doit être supprimé de la table de publication
            REP_QUE_FCT.remove_published(ltt_publishable(cpt), gttReferences(gcn_NOMENCLATURE).OBJECT_NAME);
          when others then
            null;
        end;
      end loop;
    end if;
  end;

  procedure USE_ENQUEUE_NOMENCLATURE(
    pPPS_NOMENCLATURE_ID in pps_nomenclature.pps_nomenclature_id%type
  , pSearchMode          in varchar2 default rep_utils.USE_KEY_VALUE
  )
  is
  begin
    -- Envoi de l'identifiant en queue et suppression de la liste de publication
    p_enqueue_nomenclature(pPPS_NOMENCLATURE_ID, gttReferences(gcn_NOMENCLATURE), pSearchMode);
  end;
begin
  gttReferences(gcn_NOMENCLATURE).object_name  := 'PPS_NOMENCLATURE';
  gttReferences(gcn_NOMENCLATURE).xpath        := '/BOM/PPS_NOMENCLATURE/GCO_GOOD/GOO_MAJOR_REFERENCE/text()';
end PPS_QUE_FCT;
