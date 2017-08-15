--------------------------------------------------------
--  DDL for Package Body DOC_QI
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_QI" 
is

  /**
  * procedure : UPDATE_STOCK
  * Description : Procédure permettant de remettre à jour le stock SOA/MPO des détail de position
  *               si ce stock a été modifié !
  * @created QI
  * @lastUpdate
  * @private
  * @param   iDocumentId : Document
  * @param   stock : SOA/MPO
  */
  procedure UPDATE_STOCK(iDocumentId in DOC_DOCUMENT.doc_document_id%type
  , stock varchar2)
  is
    --Curseur ramenant les positions du document
    cursor lcurPositions(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    is
      select *
        from doc_position
       where doc_document_id = iDocumentId;

    lStockId    stm_stock.stm_stock_id%type;
    lLocationId stm_location.stm_location_id%type;
  begin
    --Récupération de l'id du stock et de l'emplacement de stock
    select stm_stock_id
      into lStockId
      from stm_stock
     where sto_description = stock;

    select stm_location_id
      into lLocationId
      from stm_location
     where loc_description = stock;

    for ltplPositions in lcurPositions(iDocumentId) loop
      if (    lStockId is not null
          and lLocationId is not null) then
        --mise à jour du stock et de l'empalcement
        update doc_position
           set stm_stock_id = lStockId
             , stm_location_id = lLocationId
         where doc_position_id = ltplPositions.doc_position_id;

        update doc_position_detail
           set stm_location_id = lLocationId
         where doc_document_id = ltplPositions.doc_document_id;
      end if;
    end loop;
  end UPDATE_STOCK;

  /**
  * fonction : CTRL_COPY_DISCHARGE_INVQ
  * Description : contrôle facture quick payment
  *    1) Sur la facture quick payment, on contrôle que les détails père n'ont pas déjà
  *       un lien de copie sur une facture quick payment. Dans ce cas on aurait déjà
  *       effectué une copie et on averti l'utilisateur -> empêche qu'on copie 3 fois la facture
  *    2) On contrôle également qu'il n'y a pas de lien de décharge existant sur un PUR-RN
  *       (bloquant) ou sur un document de retour (avertissement)
  * @created QI
  * @lastUpdate
  * @public
  * @param   iDocumentId : Document
  */
  function CTRL_COPY_DISCHARGE_INVQ(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    return varchar2
  is
    --Curseur ramenant les détails pères du document (issus d'une copie)
    cursor lcurFatherDetailsByCopy(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    is
      select doc_father.dmt_number
           , pde_father.doc_position_detail_id
        from doc_position_detail pde
           , doc_position_detail pde_father
           , doc_document doc_father
       where pde.doc_document_id = iDocumentId
         and pde.doc2_doc_position_detail_id is not null
         and pde_father.doc_position_detail_id = pde.doc2_doc_position_detail_id
         and pde_father.doc_document_id = doc_father.doc_document_id;

    --Curseur ramenant tous les détails copiés des factures quick payment
    --autres que la facture quick payment en cours
    cursor lcurCopiedDetails(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    is
      select doc.dmt_number
           , doc2_doc_position_detail_id
        from doc_position_detail pde
           , doc_document doc
       where pde.doc_gauge_id in(select doc_gauge_id
                                   from doc_gauge gau
                                  where dic_gauge_categ_id = 'PUR-INVQ')
         and pde.doc_document_id <> iDocumentId
         and doc.doc_document_id = pde.doc_document_id;

    lbDocAlreadyCopied varchar2(250);
    lDocNumber         doc_document.dmt_number%type;
    lnTmp                integer;
  begin
    lbDocAlreadyCopied  := null;

    --Parcours des détails pères du document (issus d'une copie)
    for ltplFatherDetailsByCopy in lcurFatherDetailsByCopy(iDocumentId) loop
      --Sauvergarde du numéro du document à copier
      lDocNumber  := ltplFatherDetailsByCopy.dmt_number;

      --***CONTROLE D'UNE COPIE EXISTANTE ***
      --Contrôle d'une éventuelle décharge dans un PUR-RN -> copie interdite !
      select count(*)
        into lnTmp
        from doc_position_detail pde
       where pde.doc_gauge_id in(select doc_gauge_id
                                   from doc_gauge gau
                                  where dic_gauge_categ_id = 'PUR-RN')
         and pde.doc_doc_position_detail_id = ltplFatherDetailsByCopy.doc_position_detail_id;

      if (lnTmp) > 0 then
        return '[ABORT]' ||
               replace(pcs.pc_functions.translateword('Une décharge a déjà été faite pour le document [DOC].'), '[DOC]', lDocNumber);
      end if;

      --Contrôle d'une éventuelle décharge dans un autre gabarit (retours) -> avertissement!
      select count(*)
        into lnTmp
        from doc_position_detail pde
       where pde.doc_gauge_id in(select doc_gauge_id
                                   from doc_gauge gau
                                  where dic_gauge_categ_id in('PUR-SEWS', 'PUR-GRWS', 'PUR-SENS', 'PUR-GRNS') )
         and pde.doc_doc_position_detail_id = ltplFatherDetailsByCopy.doc_position_detail_id;

      if (lnTmp) > 0 then
        return replace(pcs.pc_functions.translateword('Une décharge a déjà été faite pour le document [DOC].'), '[DOC]', lDocNumber) ||
               ' ' ||
               pcs.pc_functions.translateword('Veuillez vérifier l''interrogation père/fils');
      end if;

      --***CONTROLE D'UNE COPIE EXISTANTE ***
      --Pour chaque détail père trouvé, on contrôle que ce détail n'apparaît pas déjà dans un lien de copie sur
      --une autre facture quick payment
      for ltplCopiedDetails in lcurCopiedDetails(iDocumentId) loop
        --Si ce détail est trouvé sur une autre facture, on averti l'utilisateur
        if (ltplFatherDetailsByCopy.doc_position_detail_id = ltplCopiedDetails.doc2_doc_position_detail_id) then
          --Ajout du nom du gabarit dans la liste des factures déjà copiées
          lbDocAlreadyCopied  := lbDocAlreadyCopied || ' - ' || ltplCopiedDetails.dmt_number;
        end if;
      end loop;
    end loop;

    if (lbDocAlreadyCopied is null) then
      return null;
    else
      return replace(pcs.pc_functions.translateword('Attention, le document [DOC] a déjà été copié dans la/les facture(s)'), '[DOC]', lDocNumber) ||
             ' ' ||
             lbDocAlreadyCopied ||
             ' !';
    end if;
  end CTRL_COPY_DISCHARGE_INVQ;

  /**
  * fonction : CTRL_COPY_DISCHARGE_RN
  * Description : contrôle bulletin de réception
  *    Sur le PUR-RN, on contrôle que les détails pères n'ont pas de liens de copie sur une facture.
  *    Ca voudrait dire qu'on est partis dans le flux quick payment.
  *    Dans ce cas-là, on bloque la validation
  * @created QI
  * @lastUpdate
  * @public
  * @param   iDocumentId : Document
  */
  function CTRL_COPY_DISCHARGE_RN(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    return varchar2
  is
    --Curseur ramenant les détails pères du document (issus d'une décharge)
    cursor lcurFatherDetailsByDisch(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    is
      select doc_father.dmt_number
           , pde_father.doc_position_detail_id
        from doc_position_detail pde
           , doc_position_detail pde_father
           , doc_document doc_father
       where pde.doc_document_id = iDocumentId
         and pde.doc_doc_position_detail_id is not null
         and pde_father.doc_position_detail_id = pde.doc_doc_position_detail_id
         and pde_father.doc_document_id = doc_father.doc_document_id;

    --Curseur ramenant tous les détails copiés des factures quick payment
    cursor lcurInvoicesDetails(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    is
      select doc.dmt_number
           , doc2_doc_position_detail_id
        from doc_position_detail pde
           , doc_document doc
       where pde.doc_gauge_id in(select doc_gauge_id
                                   from doc_gauge gau
                                  where dic_gauge_categ_id = 'PUR-INVQ')
         and doc.doc_document_id = pde.doc_document_id;

    lbDocAlreadyCopied varchar2(250);
    lDocNumber         doc_document.dmt_number%type;
  begin
    lbDocAlreadyCopied  := null;

    --Parcours des détails pères du document (issus d'une décharge)
    for ltplFatherDetailsByDisch in lcurFatherDetailsByDisch(iDocumentId) loop
      --Sauvergarde du numéro du document à copier
      lDocNumber  := ltplFatherDetailsByDisch.dmt_number;

      --Pour chaque détail père trouvé, on contrôle que ce détail n'apparaît pas déjà dans un lien de copie sur
      --une autre facture quick payment
      for ltplInvoicesDetails in lcurInvoicesDetails(iDocumentId) loop
        --Si ce détail est trouvé sur une autre facture, on averti l'utilisateur
        if (ltplFatherDetailsByDisch.doc_position_detail_id = ltplInvoicesDetails.doc2_doc_position_detail_id) then
          --Ajout du nom du gabarit dans la liste des factures déjà copiées
          lbDocAlreadyCopied  := lbDocAlreadyCopied || ' - ' || ltplInvoicesDetails.dmt_number;
        end if;
      end loop;
    end loop;

    if (lbDocAlreadyCopied is null) then
      return null;
    else
      return '[ABORT]' ||
             replace(pcs.pc_functions.translateword('Attention, le document [DOC] a déjà été copié dans la/les facture(s) '), '[DOC]', lDocNumber) ||
             ' ' ||
             lbDocAlreadyCopied ||
             ' !';
    end if;
  end CTRL_COPY_DISCHARGE_RN;

  /**
  * procedure : UPDATE_STOCK_MPO
  * Description : Procédure permettant de remettre à jour le stock MPO des détail de position
  *               si ce stock a été modifié !
  * @created QI
  * @lastUpdate
  * @public
  * @param   iDocumentId : Document
  */
  procedure UPDATE_STOCK_MPO(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
  is
  begin
    --Appel de la procédure de mise à jour du stock
    update_stock(iDocumentId, 'MPO');
  end UPDATE_STOCK_MPO;

  /**
  * procedure : UPDATE_STOCK_SOA
  * Description : Procédure permettant de remettre à jour le stock SOA des détail de position
  *               si ce stock a été modifié !
  * @created QI
  * @lastUpdate
  * @public
  * @param   iDocumentId : Document
  */
  procedure UPDATE_STOCK_SOA(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
  is
  begin
    --Appel de la procédure de mise à jour du stock
    update_stock(iDocumentId, 'SOA');
  end UPDATE_STOCK_SOA;

  /**
  * procedure : UPDATE_METAL_ACCOUNT
  * Description : Met à jour le stock de la position et du détail avec le compte poids
  *    du tiers FOURNISSEUR. Le tiers DOIT gérer un compte-poids. Pas de test si la matière
  *    de base ou l'alliage est gérée en compte poids (--> pas de lien sur PAC_THIRD_ALLOY).
  *    Pour les gabarits PM-Metal account Entry  PM-Metal account Issue.
  * @created QI
  * @lastUpdate
  * @public
  * @param   iDocumentId : Document
  */
  procedure UPDATE_METAL_ACCOUNT(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
  is
    cErrorTiers constant varchar2(4000) := pcs.pc_functions.translateword('Compte-poids non défini pour le tiers');
    cErrorLoc   constant varchar2(4000) := pcs.pc_functions.translateword('Aucun emplacement trouvé pour ce compte-poids');

    lDomain              DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lStockId             STM_STOCK.STM_STOCK_ID%type;
    lLocId               STM_LOCATION.STM_LOCATION_ID%type;
    lThirdId             DOC_DOCUMENT.PAC_THIRD_ID%type;
  begin
    select GAU.C_ADMIN_DOMAIN
         , DOC.PAC_THIRD_ID
      into lDomain
         , lThirdId
      from DOC_GAUGE GAU
         , DOC_DOCUMENT DOC
     where DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and DOC.DOC_DOCUMENT_ID = iDocumentId;

    -- Domaine Achat/Vente
    if lDomain in ('1','2') then
      -- Recherche du compte poids Client / Fournisseur
      lStockId := PAC_THIRD_ALLOY_FUNCTIONS.GetMetalAccount(lThirdId, lDomain);
      if lStockId is null then
        RAISE_APPLICATION_ERROR(-20000, cErrorTiers);
      end if;

      -- Recherche du premier emplacement pour ce compte-poids
      -- A priori il n'y en a besoin que d'1 seul .
      begin
        select min(STM_LOCATION_ID)
          into lLocId
          from STM_LOCATION
         where STM_STOCK_ID = lStockId;

        if lLocId is null then
          RAISE_APPLICATION_ERROR(-20000, cErrorLoc);
        end if;
      exception
        when no_data_found then
          RAISE_APPLICATION_ERROR(-20000, cErrorLoc);
      end;

      -- Mises à jour des positions et des détails
      update DOC_POSITION
         set STM_STOCK_ID = lStockId
           , STM_LOCATION_ID = lLocId
       where DOC_DOCUMENT_ID = iDocumentId;

      update DOC_POSITION_DETAIL
         set STM_LOCATION_ID = lLocId
       where DOC_DOCUMENT_ID = iDocumentId;

      commit;
    end if;

  end UPDATE_METAL_ACCOUNT;

  /**
  * procedure : UPDATE_METAL_ACCOUNT_TR
  * Description : Met à jour le stock DE TRANSFERT de la position et du détail avec le compte poids
  *    du tiers FOURNISSEUR. Le tiers DOIT gérer un compte-poids. Pas de test si la matière de base
  *    ou l'alliage est gérée en compte poids. Force également que le stock logique de la position
  *    et du détail soit une stock de type compte-poids. Pour le gabarit PM.
  * @created QI
  * @lastUpdate
  * @public
  * @param   iDocumentId : Document
  */
  procedure UPDATE_METAL_ACCOUNT_TR(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
  is
    cErrorTiers constant varchar2(4000) := pcs.pc_functions.translateword('Compte-poids non défini pour le tiers');
    cErrorLoc   constant varchar2(4000) := pcs.pc_functions.translateword('Aucun emplacement trouvé pour ce compte-poids');

    lDomain              DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lStockId             STM_STOCK.STM_STOCK_ID%type;
    lLocId               STM_LOCATION.STM_LOCATION_ID%type;
    lThirdId             DOC_DOCUMENT.PAC_THIRD_ID%type;
    lMessage             varchar2(32767);
  begin
    lMessage := null;

    select GAU.C_ADMIN_DOMAIN
         , DOC.PAC_THIRD_ID
      into lDomain
         , lThirdId
      from DOC_GAUGE GAU
         , DOC_DOCUMENT DOC
     where DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and DOC.DOC_DOCUMENT_ID = iDocumentId;

    -- Domaine achat/Vente
    if lDomain in ('1','2') then

      -- Recherche du compte poids Client / Fournisseur
      lStockId := PAC_THIRD_ALLOY_FUNCTIONS.GetMetalAccount(lThirdId, lDomain);
      if lStockId is null then
        RAISE_APPLICATION_ERROR(-20000, cErrorTiers);
      end if;


      -- Recherche du premier emplacement pour ce compte-poids
      -- A priori il n'y en a besoin que d'1 seul .
      begin
        select min(STM_LOCATION_ID)
          into lLocId
          from STM_LOCATION
         where STM_STOCK_ID = lStockId;

        if lLocId is null then
          RAISE_APPLICATION_ERROR(-20000, cErrorLoc);
        end if;
      exception
        when no_data_found then
          RAISE_APPLICATION_ERROR(-20000, cErrorLoc);
      end;

      -- Mises à jour du stock / emplacement de TRANSFERT des positions et des détails
      update DOC_POSITION
         set STM_STM_STOCK_ID = lStockId
           , STM_STM_LOCATION_ID = lLocId
       where DOC_DOCUMENT_ID = iDocumentId;

      update DOC_POSITION_DETAIL
         set STM_STM_LOCATION_ID = lLocId
       where DOC_DOCUMENT_ID = iDocumentId;

      commit;

      -- Contrôle des stocks : Emplacements logiques : Il doivent êtrent de type compte poids.
      lStockId  := null;
      lLocId    := null;
      for ltplPositions in (select STM_STOCK_ID
                                 , POS_NUMBER
                              from DOC_POSITION
                             where DOC_DOCUMENT_ID = iDocumentId
                          order by POS_NUMBER) loop
        begin
          select STM_STOCK_ID
            into lStockId
            from STM_STOCK
           where STM_STOCK_ID = ltplPositions.STM_STOCK_ID
             and STO_METAL_ACCOUNT = 1;
        exception
          when no_data_found then
            lMessage  := lMessage
              || chr(13)
              || replace(pcs.pc_functions.translateword('Position [NUMPOS]: Le stock logique n''est pas un compte poids!'), '[NUMPOS]', ltplPositions.POS_NUMBER);
        end;

      end loop;
      if lMessage is not null then
        RAISE_APPLICATION_ERROR(-20000, lMessage);
      end if;
    end if;
  end UPDATE_METAL_ACCOUNT_TR;

  /**
  * function CTRL_DEPOSIT_INVOICE
  * Description : Contrôle qu'il ne reste pas de factures d'accomptes pour le même tiers à la
  *    confirmation de la facture
  *
  * @created QI
  * @lastUpdate
  * @public
  * @param   iDocumentId : Document
  */
  function CTRL_DEPOSIT_INVOICE(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    return varchar2
  is
    --Récupération des factures d'accomptes qui ont le même tiers que le document à confrimer
    cursor lcurDepositInvoices(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    is
      select doc.dmt_number
           , foo_document_total_amount
           , cur.currency
        from doc_document doc
           , doc_document src
           , doc_gauge gau
           , doc_foot foo
           , pcs.pc_curr cur
           , acs_financial_currency acs
       where gau.doc_gauge_id = doc.doc_gauge_id
         and gau.dic_gauge_categ_id = 'SAL-DI'
         and src.doc_document_id = iDocumentId
         and doc.pac_third_id = src.pac_third_id
         and doc.c_document_status in('01', '02', '03')
         and foo.doc_document_id = doc.doc_document_id
         and doc.acs_financial_currency_id = acs.acs_financial_currency_id
         and acs.pc_curr_id = cur.pc_curr_id;

    lPendingDepositInvoices varchar2(250);
    lnTmp                      integer;
  begin
    lPendingDepositInvoices  := null;
    lnTmp                       := 0;

    --Pour chaque facture d'accompte...
    for ltplDepositInvoices in lcurDepositInvoices(iDocumentId) loop
      lPendingDepositInvoices  :=
        lPendingDepositInvoices ||
        ltplDepositInvoices.dmt_number ||
        ' (' ||
        ltplDepositInvoices.foo_document_total_amount ||
        ' ' ||
        ltplDepositInvoices.currency ||
        ') -';
      if length(lPendingDepositInvoices) > 230 then
        lPendingDepositInvoices := lPendingDepositInvoices||CHR(13)||'...';
        exit;
      end if;
      lnTmp                       := lnTmp + 1;
    end loop;

    --Si le nombre de document est > 0, on averti qu'il reste des factures
    --d'accomptes pour le même tiers
    if (lnTmp > 0) then
      return pcs.pc_functions.translateword('Attention, il reste des factures d''accomptes non soldées pour le même tiers :') ||' '||
             lPendingDepositInvoices;
    else
      return null;
    end if;
  end CTRL_DEPOSIT_INVOICE;

  function CTRL_PROSPECT(iDocumentId in DOC_DOCUMENT.doc_document_id%type)
    return varchar2
  is
    /*
      Interdit que le client PROSPECT soit le partenaire donneur d'ordre de certains documents origines .
      - Commande client (SAL-CC)
      - Commande de consignation (SAL-CCO)
      - Commande cadre (SAL-OA)
      - Facture de vente au comptant (SAL-CIC)
    */
    lName      pac_person.per_name%type;
    lShortName pac_person.per_name%type;
  begin
    select per.per_name
         , per.per_short_name
      into lName
         , lShortName
      from doc_document doc
         , doc_gauge gau
         , pac_person per
     where doc.doc_document_id = iDocumentId
       and doc.pac_third_id = per.pac_person_id
       and gau.doc_gauge_id = doc.doc_gauge_id
       and gau.dic_gauge_categ_id in('SAL-CO', 'SAL-CCO', 'SAL-OA', 'SAL-CIC');

    if (lShortName like 'PROSPECT%') then
      return '[ABORT]' ||
             pcs.pc_functions.translateword('Ce client ne peut pas être utilisé sur ce document !') ||
             ' (' ||
             lName ||
             ')';
    else
      return null;
    end if;
  end CTRL_PROSPECT;

  /**
  * function DOC_DISPUTE_POS_MOD_RESTRICT
  * Description : Contrôle litiges, modification position
  *
  * @created QI
  * @lastUpdate
  * @public
  * @param   iPositionId : position de document
  */
  function DOC_DISPUTE_POS_MOD_RESTRICT(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return varchar
  is
    --Curseur parcourant les détails de la position appelant la fonction
    cursor lcurDetail
    is
      (select det.*
         from doc_position_detail det
            , doc_position pos
        where pos.doc_position_id = det.doc_position_id
          and pos.doc_position_id = iPositionId);
  begin
    --Si au moins un détail de position concerne un litige, alors bloque la validation (la position ne doit pas être modifiée)
    for ltplDetail in lcurDetail loop
      if (ltplDetail.doc_pde_litig_id is not null) then
        return '[ABORT] ' ||
               pcs.pc_public.translateword('Vous ne pouvez pas modifier une position générée par les litiges !');
      end if;
    end loop;

    --Dans le cas contraire, on renvoie null
    return null;
  end DOC_DISPUTE_POS_MOD_RESTRICT;

  /**
  * function DOC_DISPUTE_POS_SUP_RESTRICT
  * Description : Contrôle litiges, suppression position
  *
  * @created QI
  * @lastUpdate
  * @public
  * @param   iPositionId : position de document
  */
  function DOC_DISPUTE_POS_SUP_RESTRICT(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return varchar
  is
    --Curseur parcourant les détails de la position appelant la fonction
    cursor lcurDetail
    is
      (select det.*
         from doc_position_detail det
            , doc_position pos
        where pos.doc_position_id = det.doc_position_id
          and pos.doc_position_id = iPositionId);
  begin
    --Si au moins un détail de position concerne un litige, alors bloque la suppression
    for ltplDetail in lcurDetail loop
      if (ltplDetail.doc_pde_litig_id is not null) then
        return '[ABORT] ' ||
               pcs.pc_public.translateword('Vous ne pouvez pas supprimer une position générée par les litiges !');
      end if;
    end loop;

    --Dans le cas contraire, on renvoie null
    return null;
  end DOC_DISPUTE_POS_SUP_RESTRICT;

  /**
  * function DOC_DISPUTE_SUP_RESTRICT
  * Description : Contrôle litiges, suppression document
  *
  * @created QI
  * @lastUpdate
  * @public
  * @param   iDocumentId : Document
  */
  function DOC_DISPUTE_SUP_RESTRICT(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar
  is
    --Curseur parcourant les détails de position du document appelant la fonction
    cursor lcurDetail
    is
      (select det.*
         from doc_position_detail det
            , doc_document doc
        where doc.doc_document_id = det.doc_document_id
          and doc.doc_document_id = iDocumentId);
  begin
    --Si au moins un détail de position concerne un litige, alors bloque la suppression
    for ltplDetail in lcurDetail loop
      if (ltplDetail.doc_pde_litig_id is not null) then
        return '[ABORT] ' ||
               pcs.pc_public.translateword('Vous ne pouvez pas supprimer un document généré par les litiges !');
      end if;
    end loop;

    --Dans le cas contraire, on renvoie null
    return null;
  end DOC_DISPUTE_SUP_RESTRICT;

end DOC_QI;
