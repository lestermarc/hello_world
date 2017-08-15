--------------------------------------------------------
--  DDL for Package Body FAL_DELETE_ATTRIBS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_DELETE_ATTRIBS" 
is
-- Déclaration des messages traduits utilisés par les exceptions
eLockedNetwExceptionMsg constant varchar2(255) := PCS.PC_PUBLIC.TranslateWord('Réseaux en cours de modification par un autre utilisateur! Suppression impossible pour le moment.');

  /***
  * PROCEDURE delete_all_attribs
  * Description :
  * Cette procedure permet de détruire toutes les attribs pour
  * un produit donné. si PrmGCO_GOOD_ID est null alors tous les produits sont concernés
  * les positions d'un document donné. si PrmDOC_DOCUMENT est null tous les documents sont concernés
  * une position donné. Si PrmDOC_POSSITION_ID est null cela concerne toutes les positions
  * Un mixe de tous les paramètres n'est pas possible
  */
  procedure delete_all_attribs(
    prmgco_good_id     pcs_pk_id
  , prmdoc_document_id pcs_pk_id
  , prmdoc_position_id pcs_pk_id
  , prmcommit          number default 1
  )
  is
    -- VJ20010516-0458
    cursor cneed_by_position
    is
      -- Traite les besoins des positions <> 7,8,9,10,71,81,91,101
      select fan.fal_network_need_id
        from fal_network_need fan
           , doc_position pos
       where fan.doc_position_id = prmdoc_position_id
         and fan.doc_position_id = pos.doc_position_id
         and pos.c_gauge_type_pos not in('7', '8', '9', '10')
      union all
      -- Traite les besions des positions 71,81,91,101
      select fan.fal_network_need_id
        from fal_network_need fan
           , doc_position pos
       where pos.doc_doc_position_id = prmdoc_position_id
         and fan.doc_position_id = pos.doc_position_id;

    cursor cneed_by_document
    is
      -- Traite les besoins des positions <> 7,8,9,10
      select fan.fal_network_need_id
        from fal_network_need fan
           , doc_position pos
       where fan.doc_position_id = pos.doc_position_id
         and pos.doc_document_id = prmdoc_document_id
         and pos.c_gauge_type_pos not in('7', '8', '9', '10');

    -- Sélection des attributions par besoin
    cursor clinkbyneed(aneed_id pcs_pk_id)
    is
      select fnl.fal_network_link_id
           , fnl.fal_network_need_id
           , fnl.fal_network_supply_id
           , fnl.stm_stock_position_id
           , fnl.stm_location_id
           , fnl.fln_qty
        from fal_network_link fnl
           , fal_network_need fnn
           , fal_network_supply fns
           , stm_stock_position spo
       where fnl.fal_network_need_id = aneed_id
         and fnl.fal_network_need_id = fnn.fal_network_need_id (+)
         and fnl.fal_network_supply_id = fns.fal_network_supply_id (+)
         and fnl.stm_stock_position_id = spo.stm_stock_position_id (+)
         -- On ne supprime pas les attributions en cours de traitement dans les sortie de composants
         and fnl.fal_network_link_id not in (select fcl.fal_network_link_id
                                               from fal_component_link fcl
                                              where fcl.fal_network_link_id = fnl.fal_network_link_id)
       for update of fnl.fln_qty
                   , fnn.fan_free_qty
                   , fns.fan_free_qty
                   , spo.spo_assign_quantity nowait;

    -- Sélection des attributions par approvisonnement
    cursor clinkbysupply(asupply_id pcs_pk_id)
    is
      select fnl.fal_network_link_id
           , fnl.fal_network_need_id
           , fnl.fal_network_supply_id
           , fnl.stm_stock_position_id
           , fnl.stm_location_id
           , fnl.fln_qty
        from fal_network_link fnl
           , fal_network_need fnn
           , fal_network_supply fns
           , stm_stock_position spo
       where fnl.fal_network_supply_id = asupply_id
         and fnl.fal_network_need_id = fnn.fal_network_need_id (+)
         and fnl.fal_network_supply_id = fns.fal_network_supply_id (+)
         and fnl.stm_stock_position_id = spo.stm_stock_position_id (+)
         -- On ne supprime pas les attributions en cours de traitement dans les sortie de composants
         and fnl.fal_network_link_id not in (select fcl.fal_network_link_id
                                               from fal_component_link fcl
                                              where fcl.fal_network_link_id = fnl.fal_network_link_id)
       for update of fnl.fln_qty
                   , fnn.fan_free_qty
                   , fns.fan_free_qty
                   , spo.spo_assign_quantity nowait;

    -- Curseur pour suppression des atributions par produit
    cursor cneed_by_good
    is
      -- Traite les besoins logistiques sans les positions 7,8,9,10
      select fan.fal_network_need_id
        from fal_network_need fan
           , doc_position pos
       where fan.gco_good_id = prmgco_good_id
         and pos.doc_position_id = fan.doc_position_id
         and pos.c_gauge_type_pos not in('7', '8', '9', '10')
      union all
      -- Traite les autres besoins
      select fan.fal_network_need_id
        from fal_network_need fan
       where fan.gco_good_id = prmgco_good_id
         and fan.doc_position_id is null
         and (   fan.doc_gauge_id is null
              or fan.doc_gauge_id not in(select doc_gauge_id
                                           from fal_prop_def
                                          where c_prop_type = 4) );

    -- Curseur pour suppression des atributions par produit
    cursor csupply_by_good
    is
      -- Traite les appros logistiques sans les positions 7,8,9,10
      select fan.fal_network_supply_id
        from fal_network_supply fan
           , doc_position pos
       where fan.gco_good_id = prmgco_good_id
         and pos.doc_position_id = fan.doc_position_id
         and pos.c_gauge_type_pos not in('7', '8', '9', '10')
      union all
      -- Traite les autres appros
      select fan.fal_network_supply_id
        from fal_network_supply fan
       where fan.gco_good_id = prmgco_good_id
         and fan.doc_position_id is null
         and (   fan.doc_gauge_id is null
              or fan.doc_gauge_id not in(select doc_gauge_id
                                           from fal_prop_def
                                          where c_prop_type = 4) );

    -- Curseur de suppression de toutes les attributions
    cursor clink
    is
      select fnk.fal_network_link_id
           , fnk.fal_network_need_id
           , fnk.fal_network_supply_id
           , fnk.stm_stock_position_id
           , fnk.stm_location_id
           , fnk.fln_qty
        from fal_network_supply fas
           , fal_network_need fan
           , fal_network_link fnk
           , stm_stock_position spo
       where fnk.fal_network_need_id = fan.fal_network_need_id(+)
         and fnk.fal_network_supply_id = fas.fal_network_supply_id(+)
         and fnk.stm_stock_position_id = spo.stm_stock_position_id (+)
         and nvl(fan.doc_position_id, -1) <> nvl(fas.doc_position_id, -2)
         -- Ne prend pas les attributions 7-7, 8-8, 9-9, 10-10
         and (   fan.doc_gauge_id is null
              or fan.doc_gauge_id not in(select doc_gauge_id
                                           from fal_prop_def
                                          where c_prop_type = 4) )
         and (   fas.doc_gauge_id is null
              or fas.doc_gauge_id not in(select doc_gauge_id
                                           from fal_prop_def
                                          where c_prop_type = 4) )
         -- On ne supprime pas les attributions en cours de traitement dans les sortie de composants
         and fnk.fal_network_link_id not in (select fcl.fal_network_link_id
                                               from fal_component_link fcl
                                              where fcl.fal_network_link_id = fnk.fal_network_link_id)
      for update of fas.fan_free_qty
                  , fan.fan_free_qty
                  , fnk.fln_qty
                  , spo.spo_assign_quantity nowait;

    --Variable pour clause INTO
    alink_id           pcs_pk_id;
    aneed_id           pcs_pk_id;
    asupply_id         pcs_pk_id;
    astock_position_id pcs_pk_id;
    alocation_id       pcs_pk_id;
    afln_qty           fal_network_link.fln_qty%type;
  begin

    savepoint justbeforedelete_all_attribs;

    -- Branche 1 -- PRODUIT = NULL, DOCUMENT = NULL, POSITION <> NULL
    if nvl(prmdoc_position_id, 0) <> 0 then
      open cneed_by_position;

      loop
        fetch cneed_by_position
         into aneed_id;

        exit when cneed_by_position%notfound;

        -- pour chaque attribution du besoin on détruit les attribs
        open clinkbyneed(aneed_id);

        loop
          fetch clinkbyneed
           into alink_id
              , aneed_id
              , asupply_id
              , astock_position_id
              , alocation_id
              , afln_qty;

          exit when clinkbyneed%notfound;
          -- Suppression attribution
          fal_redo_attribs.suppressionattribution(alink_id
                                                , aneed_id
                                                , asupply_id
                                                , astock_position_id
                                                , alocation_id
                                                , afln_qty
                                                 );
        end loop;

        close clinkbyneed;
      end loop;

      close cneed_by_position;
    end if;

    -- Branche 2 -- PRODUIT = NULL, DOCUMENT <> NULL, POSITION = NULL
    if nvl(prmdoc_document_id, 0) <> 0 then
      open cneed_by_document;

      loop
        fetch cneed_by_document
         into aneed_id;

        exit when cneed_by_document%notfound;

        -- pour chaque attribution du besoin on détruit les attribs
        open clinkbyneed(aneed_id);

        loop
          fetch clinkbyneed
           into alink_id
              , aneed_id
              , asupply_id
              , astock_position_id
              , alocation_id
              , afln_qty;

          exit when clinkbyneed%notfound;
          -- Suppression attribution
          fal_redo_attribs.suppressionattribution(alink_id
                                                , aneed_id
                                                , asupply_id
                                                , astock_position_id
                                                , alocation_id
                                                , afln_qty
                                                 );
        end loop;

        close clinkbyneed;
      end loop;

      close cneed_by_document;
    end if;

    -- Branche 3 -- PRODUIT <> NULL, DOCUMENT = NULL, POSITION = NULL
    if nvl(prmgco_good_id, 0) <> 0 then
      open cneed_by_good;

      loop
        fetch cneed_by_good
         into aneed_id;

        exit when cneed_by_good%notfound;

        -- pour chaque attribution du besoin on détruit les attribs
        open clinkbyneed(aneed_id);

        loop
          fetch clinkbyneed
           into alink_id
              , aneed_id
              , asupply_id
              , astock_position_id
              , alocation_id
              , afln_qty;

          exit when clinkbyneed%notfound;
          -- Suppression attribution
          fal_redo_attribs.suppressionattribution(alink_id
                                                , aneed_id
                                                , asupply_id
                                                , astock_position_id
                                                , alocation_id
                                                , afln_qty
                                                 );
        end loop;

        close clinkbyneed;
      end loop;

      close cneed_by_good;

      open csupply_by_good;

      loop
        fetch csupply_by_good
         into asupply_id;

        exit when csupply_by_good%notfound;

        -- pour chaque attribution du besoin on détruit les attribs
        open clinkbysupply(asupply_id);

        loop
          fetch clinkbysupply
           into alink_id
              , aneed_id
              , asupply_id
              , astock_position_id
              , alocation_id
              , afln_qty;

          exit when clinkbysupply%notfound;
          -- Suppression attribution
          fal_redo_attribs.suppressionattribution(alink_id
                                                , aneed_id
                                                , asupply_id
                                                , astock_position_id
                                                , alocation_id
                                                , afln_qty
                                                 );
        end loop;

        close clinkbysupply;
      end loop;

      close csupply_by_good;
    end if;

    -- Branche 4 -- PRODUIT = NULL, DOCUMENT = NULL, POSITION = NULL
    if     nvl(prmgco_good_id, 0) = 0
       and nvl(prmdoc_document_id, 0) = 0
       and nvl(prmdoc_position_id, 0) = 0 then
      -- pour toutes les  attributions du besoin on détruit les attribs
      open clink;

      loop
        fetch clink
         into alink_id
            , aneed_id
            , asupply_id
            , astock_position_id
            , alocation_id
            , afln_qty;

        exit when clink%notfound;
        -- Suppression attribution
        fal_redo_attribs.suppressionattribution(alink_id
                                              , aneed_id
                                              , asupply_id
                                              , astock_position_id
                                              , alocation_id
                                              , afln_qty
                                               );
      end loop;

      close clink;
    end if;

    if prmcommit = 1 then
      commit work;
    end if;
  exception
    When ex.ROW_LOCKED then begin
      rollback to savepoint justbeforedelete_all_attribs;
      raise_application_error(-20020,'PCS - ' || eLockedNetwExceptionMsg);
    end;
    when others then begin
      rollback to savepoint justbeforedelete_all_attribs;
      raise;
    end;
  end;

  /***
  * PROCEDURE delete_all_attribs
  *
  * Idem procédure précédente, mais avec retour d'un code erreur en cas de problème
  */
  procedure delete_all_attribs(
    prmgco_good_id     in pcs_pk_id
  , prmdoc_document_id in pcs_pk_id
  , prmdoc_position_id in pcs_pk_id
  , aErrorCode         in out varchar2
  )
  is
  begin
    delete_all_attribs(
        prmgco_good_id
      , prmdoc_document_id
      , prmdoc_position_id);
  exception
    When eLockedNetwException then begin
      aErrorCode := 'eLockedNetwException';
    end;
    when others then begin
      raise;
    end;
  end;


  /***
  * PROCEDURE delete_all_attribs_logstk
  * Description :
  * Supprime TOUTES les attributions LOGISTIQUES atribués SUR STOCK
  */
  procedure delete_all_attribs_logstk
  is
    cursor clink
    is
      -- Curseur renvoyant toutes les attributions sur stock pour les besoins logistiques
      select lnk.fal_network_link_id
           , lnk.fal_network_need_id
           , lnk.fal_network_supply_id
           , lnk.stm_stock_position_id
           , lnk.stm_location_id
           , lnk.fln_qty
        from fal_network_link lnk
           , fal_network_need fnn
           , stm_stock_position spo
       where fnn.doc_position_detail_id is not null
		     and fnn.fal_network_need_id = lnk.fal_network_need_id
		     and lnk.stm_stock_position_id = spo.stm_stock_position_id
      for update of lnk.fal_network_link_id
                  , fnn.fan_stk_qty
                  , spo.spo_assign_quantity;

    elink clink%rowtype;
  begin
    open clink;

    loop
      fetch clink
       into elink;

      exit when clink%notfound;
      -- Suprimer l'attribution
      fal_redo_attribs.suppressionattribution(elink.fal_network_link_id
                                            , elink.fal_network_need_id
                                            , elink.fal_network_supply_id
                                            , elink.stm_stock_position_id
                                            , elink.stm_location_id
                                            , elink.fln_qty
                                             );
    end loop;

    close clink;
  end;
end;
