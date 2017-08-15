--------------------------------------------------------
--  DDL for Package Body DOC_DELETE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DELETE" 
is
  /**
  * procedure pDeleteDocEBPPInfos
  * Description
  *    Cette procedure va supprimer les informations e-finance (y.c. journal et
  *    fichier de traitement) du document dont la clef primaire est transmise en
  *    paramètre
  * @created AGE 24.02.2012
  * @lastUpdate
  * @private
  * @param inDocDocumentID : Clé primaire du document logistique
  */
  procedure pDeleteDocEBPPInfos(inDocDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  as
    lnComEbankingID COM_EBANKING.COM_EBANKING_ID%type;
  begin
    /* Récupération de la clef primaire du document e-facture */
    select COM_EBANKING_ID
      into lnComEbankingID
      from COM_EBANKING
     where DOC_DOCUMENT_ID = inDocDocumentID;

    /* Supression du journal de transaction du document e-facture */
    COM_I_PRC_EBANKING_DET.DeleteEBPPDetail(inComEbankingID => lnComEbankingID);
    /* Supression des fichiers de traitement du document e-facture */
    COM_I_PRC_EBANKING_FILES.DeleteEBPPFile(inComEbankingID => lnComEbankingID);

    /* Supression du document e-facture */
    delete from COM_EBANKING
          where COM_EBANKING_ID = lnComEbankingID;
  exception
    when no_data_found then
      null;   /* Pas d'information e-finance à supprimer, on ne fait rien */
  end pDeleteDocEBPPInfos;

  /**
  * Description
  *    Effacement d'un détail de position
  */
  procedure deletePositionDetail(aPositionDetailId in number, aParentPositionId out number, aUpdateFather in boolean default true)
  is
    genMvt              number(1);
    detCtrlId           DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    parentDetailId      DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    balanceQty          DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type;
    vCML_EVENTS_ID      DOC_POSITION_DETAIL.CML_EVENTS_ID%type;
    vCML_POSITION_ID    CML_POSITION.CML_POSITION_ID%type;
    vCML_INV_JOB_ID     DOC_DOCUMENT.CML_INVOICING_JOB_ID%type;
    vPOS_ID             DOC_POSITION_DETAIL.DOC_POSITION_ID%type;
    vC_GAUGE_TYPE_POS   DOC_POSITION.C_GAUGE_TYPE_POS%type;
    vDOC_PDE_LITIG_ID   DOC_POSITION_DETAIL.DOC_PDE_LITIG_ID%type;
    vPDE_FINAL_QUANTITY DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    lCurrencyRiskId     DOC_DOCUMENT.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lLotId              DOC_POSITION_DETAIL.FAL_LOT_ID%type;
    lGaugeId            DOC_GAUGE.DOC_GAUGE_ID%type;
    lError              varchar2(1000);
  begin
    -- recherches d'info sur le détail à effacer
    begin
      select PDE.PDE_GENERATE_MOVEMENT
           , PDE.DOC_DOC_POSITION_DETAIL_ID
           , PDE.PDE_FINAL_QUANTITY + PDE.PDE_BALANCE_QUANTITY_PARENT
           , PDE.PDE_FINAL_QUANTITY
           , DMT.CML_INVOICING_JOB_ID
           , PDE.CML_EVENTS_ID
           , POS.CML_POSITION_ID
           , PDE.DOC_POSITION_ID
           , POS.C_GAUGE_TYPE_POS
           , PDE.DOC_PDE_LITIG_ID
           , DMT.GAL_CURRENCY_RISK_VIRTUAL_ID
           , PDE.FAL_LOT_ID
           , PDE.DOC_GAUGE_ID
        into genMvt
           , parentDetailId
           , BalanceQty
           , vPDE_FINAL_QUANTITY
           , vCML_INV_JOB_ID
           , vCML_EVENTS_ID
           , vCML_POSITION_ID
           , vPOS_ID
           , vC_GAUGE_TYPE_POS
           , vDOC_PDE_LITIG_ID
           , lCurrencyRiskId
           , lLotId
           , lGaugeId
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
       where PDE.DOC_POSITION_DETAIL_ID = aPositionDetailId
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;
    exception
      when no_data_found then   -- pas de détail
        genMvt  := 0;
    end;

    -- Vérifie que le détail n'ait pas été déchargé
    select max(doc_position_detail_id)
      into detCtrlId
      from doc_position_detail
     where doc_doc_position_detail_id = aPositiondetailId;

    if detCtrlId is not null then
      raise_application_error(-20075, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le detail de position à effacer a été déchargé!') );
    end if;

    -- si Lot sous-traitance lié et suppression de la CAST, effacement de ce lot
    if     lLotId is not null
       and (DOC_LIB_SUBCONTRACTP.IsSUPOGauge(lGaugeId) = 1) then
      FAL_PRC_SUBCONTRACTP.DeleteBatch(aPositionDetailId, lError);

      if lError is not null then
        ra(aMessage => lError, aErrNo => -20900);
      end if;
    end if;

    -- Si aucun mouvements générés, effacement du detail
    if genMvt = 0 then
      -- Màj du litige, liberer le lien sur le détail final
      if     (vDOC_PDE_LITIG_ID is not null)
         and (vC_GAUGE_TYPE_POS = '21') then
        update DOC_LITIG
           set DOC_PDE_FINAL_ID = null
             , DLG_BALANCE_QTY = least(DLG_BALANCE_QTY + vPDE_FINAL_QUANTITY, DLG_QTY)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_DETAIL_ID = vDOC_PDE_LITIG_ID
           and DOC_PDE_FINAL_ID = aPositionDetailID;
      end if;

      -- Mise à jour des tables CML
      if    (vCML_EVENTS_ID is not null)
         or (vCML_POSITION_ID is not null) then
        updateCmlOnDocPosDelete(aCmlPositionId => vCML_POSITION_ID, aEventId => vCML_EVENTS_ID, aInvoicingJobId => vCML_INV_JOB_ID, aDocPositionId => vPOS_ID);
      end if;

      delete from DOC_LINK
            where DOC_PDE_SOURCE_ID = aPositionDetailID;

      delete from DOC_LINK
            where DOC_PDE_TARGET_ID = aPositionDetailID;

      -- Journalisation du détail effacé
      DOC_JOURNAL_FUNCTIONS.OnPosDetailDelete(aPositionDetailId);

      -- L'effacement des détail de positions provoque :
      --   - la maj qtés prov par trigger
      --   - l'effacement DOC_DELAY_HISTORY par trigger
      --   - maj des opérations de sous-traitance par trigger
      --   - maj des totalisateurs par trigger
      --   - maj des colis et effacement des positions des colis
      --   - la maj éventuelle de la quantité solde du détail parent
      if aUpdateFather then
        delete from V_DOC_POSITION_DETAIL_IO
              where DOC_POSITION_DETAIL_ID = aPositionDetailId;

        -- L'effacement par la vue instead of V_DOC_POSTIION_DETAIL_IO effectue la mise à jour du détail parent.
        -- Il ne faut donc plus effectuer la mise à jour de la quantité solde du père ci-dessous.
        -- Par contre, il faut tout de même effectuer la recherche de la position père pour une mise à jour
        -- de la quantité solde de la position père dans la méthode appelante (deletePosition).
        if parentDetailId is not null then
          select PDE.DOC_POSITION_ID
            into aParentPositionId
            from DOC_POSITION_DETAIL PDE
           where PDE.DOC_POSITION_DETAIL_ID = parentDetailId;
        end if;
      else
        -- Effacement des détails de position sans mise à jour du détail père.
        delete from DOC_POSITION_DETAIL
              where DOC_POSITION_DETAIL_ID = aPositionDetailId;
      end if;

      -- Mise de côté du document parent en vue d'une mise à jour du montant solde de ce dernier
      if     lCurrencyRiskId is not null
         and parentDetailId is not null then
        DOC_PRC_DOCUMENT.AddDocToListParent(iDetailId => parentDetailId);
      end if;
    else
      raise_application_error(-20074
                            , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le detail de position à effacer a généré un mouvement de stock!')
                             );
    end if;
  end deletePositionDetail;

  /**
  * Description
  *    Effacement d'une position de document
  */
  procedure deletePosition(
    aPositionId     in number
  , aMajDocStatus   in boolean
  , aDeleteDocument in boolean default false
  , aUpdateFather   in boolean default true
  , aDeletePT       in boolean default false
  )
  is
    cursor crDetail(cPositionId number)
    is
      select   DOC_POSITION_DETAIL_ID
          from DOC_POSITION_DETAIL
         where DOC_POSITION_ID = cPositionId
      order by nvl(DOC_DOC_POSITION_DETAIL_ID, 0)
             , nvl(PDE_BALANCE_PARENT, 0)
             , nvl(abs(PDE_BALANCE_QUANTITY_PARENT), 0);

    cursor crComponents(cPositionId number)
    is
      select DOC_POSITION_ID
        from DOC_POSITION
       where DOC_DOC_POSITION_ID = cPositionId;

    currentDetailId          DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    docId                    DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    genMvt                   number(1);
    tmpParentPositionId      DOC_POSITION.DOC_POSITION_ID%type;
    parentPositionId         DOC_POSITION.DOC_POSITION_ID%type;
    parentDocumentId         DOC_POSITION.DOC_DOCUMENT_ID%type;
    tmpBalanceQty            DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type;
    balanceQty               DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type       default 0;
    vGapDesignation          DOC_GAUGE_POSITION.GAP_DESIGNATION%type;
    posStatus                DOC_POSITION.C_DOC_POS_STATUS%type;
    typePos                  DOC_POSITION.C_GAUGE_TYPE_POS%type;
    lPosCreateMode           DOC_POSITION.C_POS_CREATE_MODE%type;
    isAsaRecordEvents        number(1);
    isAsaRecordComp          number(1);
    isCmlPositions           number(1);
    cmlPosId                 CML_POSITION.CML_POSITION_ID%type;
    cmlEventId               CML_EVENTS.CML_EVENTS_ID%type;
    cmlInvoicingJobID        CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type;
    nBalanceQuantity         DOC_POSITION.POS_BALANCE_QUANTITY%type;
    gauCancelStatus          DOC_GAUGE.GAU_CANCEL_STATUS%type;
    isInvoiceExpiryGenerated pls_integer;
    vProtected               DOC_DOCUMENT.DMT_PROTECTED%type;
    vFinancialCharging       DOC_DOCUMENT.DMT_FINANCIAL_CHARGING%type;
    vInvoiceExpiryId         DOC_POSITION.DOC_INVOICE_EXPIRY_ID%type;
    vDocumentBillBookId      DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    posPTId                  DOC_POSITION.DOC_DOC_POSITION_ID%type;
    gapLinkedGaugeId         DOC_GAUGE_POSITION.DOC_DOC_GAUGE_POSITION_ID%type;
    isLinkedComponent        boolean;
    lnScheduleStepID         FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    lnBalanceQuantitySU      DOC_POSITION.POS_BALANCE_QUANTITY%type;
  begin
    -- recherche d'infos relatives à la position à effacer
    begin
      select POS.C_GAUGE_TYPE_POS
           , POS.POS_GENERATE_MOVEMENT
           , POS.C_DOC_POS_STATUS
           , POS.C_POS_CREATE_MODE
           , POS.DOC_DOCUMENT_ID
           , POS.CML_POSITION_ID
           , POS.CML_EVENTS_ID
           , POS.DOC_INVOICE_EXPIRY_ID
           , DMT.CML_INVOICING_JOB_ID
           , DMT.DMT_FINANCIAL_CHARGING
           , DMT.DMT_PROTECTED
           , GAU.GAU_CANCEL_STATUS
           , POS.DOC_DOC_POSITION_ID
           , GAP.DOC_DOC_GAUGE_POSITION_ID
           , GAP.GAP_DESIGNATION
        into typePos
           , genMvt
           , posStatus
           , lPosCreateMode
           , docId
           , cmlPosId
           , cmlEventId
           , vInvoiceExpiryId
           , cmlInvoicingJobID
           , vFinancialCharging
           , vProtected
           , gauCancelStatus
           , posPTId
           , gapLinkedGaugeID
           , vGapDesignation
        from DOC_POSITION POS
           , DOC_GAUGE_POSITION GAP
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where POS.DOC_POSITION_ID = aPositionId
         and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;
    exception
      when no_data_found then
        null;
    end;

    -- Recherche si l'on traite un composant de type '1'.
    isLinkedComponent  := false;

    if     posPTId is not null
       and typePos = '1' then
      isLinkedComponent  := true;
    end if;

    -- Effacement des composants du produit terminé
    if typePos in('7', '8', '9', '10') then
      -- Si l'on ne traite pas un produit terminé qui autorise le kit partiel, il faut effectuer la recharge, au niveau
      -- des composants père, de l'ensemble des composants qui ont été effacés sur le fils.
      -- En effet, l'effacement d'un composant qui n'est pas en kit partiel ne recharge pas le père. Mais malheureusement,
      -- il ne reste plus de composant pour recharger le père avec le méchanisme habituel (vue instead of V_DOC_POSITION_DETAIL_IO).
      -- Il faut donc effectuer manuellement la recharge des composants pères restants si le composé du fils est effacé.
      if gapLinkedGaugeId is null then   -- Pas en kit partiel
        UpdateFatherComponentsOnDelete(aPositionId);
      end if;

      for tplComponents in crComponents(aPositionId) loop
        -- Efface les composants du produit terminé courant.
        deletePosition(tplComponents.DOC_POSITION_ID, false, aDeleteDocument, true, true);
      end loop;
    end if;

    -- Vérifie qu'il n'y ait pas d'enregistrements dans ASA_RECORD_EVENTS
    select sign(count(*) )
      into isAsaRecordEvents
      from ASA_RECORD_EVENTS
     where DOC_POSITION_ID = aPositionId;

    -- Vérifie si la position courante est lié à un composant d'un dossier de réparation (ASA_RECORD_COMP)
    --select sign(count(*))
    --  into isAsaRecordComp
    --  from ASA_RECORD_COMP
    -- where DOC_ATTRIB_POSITION_ID = aPositionId;

    -- Traitement de l'annulation d'une position. Attention, ce traitement est appelé uniquement à partir de
    -- l'effacement du document. Le traitement de l'effacement d'une position uniquement est effectué à partir de
    -- Delphi par l'appel de CancelPositionStatus ou DeletePosition en fonction de GAU_CANCEL_STATUS.
    -- Les positions de type 205 ne doivent pas être annulées mais supprimées directement
    if     genMvt = 0
       and gauCancelStatus = 1
       and not aDeleteDocument
       and vFinancialCharging = 0
       and typePos not in('4', '5', '6')
       and (lPosCreateMode <> '205')
       and posStatus in('02', '03') then
      -- Annule la position active
      DOC_POSITION_FUNCTIONS.CancelPositionStatus(aPositionId);
    -- Si aucun mouvement n'a été effectué
    elsif     genMvt = 0
          and vFinancialCharging = 0
          and (   posStatus in('01', '02', '04', '05')
               or typePos in('4', '5', '6')
               or (    typePos = '1'
                   and vGapDesignation = 'Packaging') )
          and (IsAsaRecordEvents = 0) then
      --and ( IsAsaRecordComp = 0 ) then
      begin
        -- Reset des extractions de commission liées à la position que l'on efface
        update doc_extract_commission
           set dec_doc_generated = 0
             , dec_document_id = null
             , dec_position_id = null
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where dec_position_id = aPositionId;

        -- Lecture des informations pour la mise à jour de l'opération lié à la position.
        DOC_SUBCONTRACT.GetInfoPosWithOP(aPositionId, lnScheduleStepID, lnBalanceQuantitySU);

        delete from DOC_LINK
              where DOC_POS_SOURCE_ID = aPositionId;

        delete from DOC_LINK
              where DOC_POS_TARGET_ID = aPositionId;

        ---
        -- Effacement des détail position liés
        --
        -- Il faut absolument que les détails de position soient effacés dans un certain ordre pour que
        -- le méchanisme de mise à jour du père s'effectue correctement. Ce méchanisme est implémenté dans
        -- le trigger d'effacement de la vue instead of V_DOC_POSITION_DETAIL_IO. Il faut toujours que le dernier
        -- détail à effacer soit le détail de "référence" (le détail qui contient toutes les informations liées
        -- à la décharge, soit : le flag soldé parent, la quantité soldée sur parent et le lien sur le père évidement).
        --
        -- Remarque : Le détail de référence ne peut pas être effacé dans l'interface utilisateur.
        --
        for tplDetail in crDetail(aPositionId) loop
          deletePositionDetail(tplDetail.DOC_POSITION_DETAIL_ID, tmpParentPositionId,(   aUpdateFather
                                                                                      or isLinkedComponent) );

          if (   aUpdateFather
              or isLinkedComponent) then
            select nvl(tmpParentPositionId, parentPositionId)
              into parentPositionId
              from dual;
          end if;
        end loop;

        -- Maj des quantités solde sur position parent pour les types de positions bien qui demande la mise à jour
        -- du père.
        if     parentPositionId is not null
           and typePos not in('4', '5', '6')
           and (   aUpdateFather
                or isLinkedComponent) then
          ----
          -- Recherche la nouvelle quantité solde à mettre à jour sur la position père.
          --
          select sum(PDE_BALANCE_QUANTITY)
            into nBalanceQuantity
            from DOC_POSITION_DETAIL PDE
           where PDE.DOC_POSITION_ID = parentPositionId;

          -- mise à jour de la quantité solde du parent
          -- et mise à jour de la quantité solde valeur et du status de la position parent
          update    DOC_POSITION parent
                set POS_BALANCE_QUANTITY = nBalanceQuantity
                  , POS_BALANCE_QTY_VALUE =
                      (select decode(sign(parent.POS_VALUE_QUANTITY)
                                   , -1, greatest(parent.POS_BALANCE_QTY_VALUE + child.POS_VALUE_QUANTITY, parent.POS_VALUE_QUANTITY)
                                   , least(parent.POS_BALANCE_QTY_VALUE + child.POS_VALUE_QUANTITY, parent.POS_VALUE_QUANTITY)
                                    )
                         from DOC_POSITION child
                        where DOC_POSITION_ID = aPositionId)
                  , C_DOC_POS_STATUS = decode(nBalanceQuantity, 0, '04', parent.POS_FINAL_QUANTITY, '02', '03')
                  , A_DATEMOD = sysdate
                  , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
              where parent.DOC_POSITION_ID = parentPositionId
                and parent.GCO_GOOD_ID is not null
          returning DOC_DOCUMENT_ID
               into parentDocumentId;

          -- Maj du status du document Parent
          DOC_PRC_DOCUMENT.UpdateDocumentStatus(parentDocumentId);

          -- Maj du solde montant (remise et taxe) de la position Parent
          update DOC_POSITION_CHARGE parent
             set PCH_BALANCE_AMOUNT =
                   (select decode(nvl(parentPos.POS_UPDATE_QTY_PRICE, 0)
                                , 0, decode(parentPos.POS_BALANCE_QUANTITY
                                          , parentPos.POS_FINAL_QUANTITY, parent.PCH_AMOUNT
                                          , parent.PCH_BALANCE_AMOUNT + child.PCH_AMOUNT
                                           )
                                , 1, decode(parentPos.POS_FINAL_QUANTITY
                                          , 0, 0
                                          , parent.PCH_AMOUNT *(parentPos.POS_BALANCE_QUANTITY / parentPos.POS_FINAL_QUANTITY)
                                           )
                                 )
                      from DOC_POSITION_CHARGE child
                         , DOC_POSITION parentPos
                     where child.DOC_POSITION_ID = aPositionId
                       and parentPos.DOC_POSITION_ID = parent.DOC_POSITION_ID
                       and child.DOC_DOC_POSITION_CHARGE_ID = parent.DOC_POSITION_CHARGE_ID)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_POSITION_ID = parentPositionId
             and exists(select DOC_POSITION_CHARGE_ID
                          from DOC_POSITION_CHARGE child
                         where DOC_POSITION_ID = aPositionId
                           and child.DOC_DOC_POSITION_CHARGE_ID = parent.DOC_POSITION_CHARGE_ID)
             and PCH_TRANSFERT_PROP = 1;
        end if;

        -- maj du status des documents liés via un échéancier sans décharge
        if vInvoiceExpiryId is not null then
          begin
            select INX.DOC_DOCUMENT_ID
              into vDocumentBillBookId
              from DOC_INVOICE_EXPIRY INX
                 , DOC_DOCUMENT DMT
             where INX.DOC_INVOICE_EXPIRY_ID = vInvoiceExpiryId
               and DMT.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID
               and INX.C_INVOICE_EXPIRY_DOC_TYPE = '3'
               and DMT.DMT_ONLY_AMOUNT_BILL_BOOK = 1;

            DOC_INVOICE_EXPIRY_FUNCTIONS.balanceDocumentCascade(vDocumentBillBookId, 0);
          exception
            when no_data_found then
              null;   -- si pas lié une échance de type facture finale sans décharge alors on fait rien
          end;
        end if;

        -- Effacement en cascade de DOC_POSITION_CHARGE par la contrainte DOC_POSITION_S_DOC_POS_CHARGE

        -- Effacement des détails d'échéancier lilés à la position
        select count(*)
          into isInvoiceExpiryGenerated
          from DOC_INVOICE_EXPIRY_DETAIL IED
             , DOC_INVOICE_EXPIRY INX
         where IED.DOC_POSITION_ID = aPositionId
           and INX.DOC_INVOICE_EXPIRY_ID = IED.DOC_INVOICE_EXPIRY_ID
           and INX.INX_INVOICE_GENERATED = 1;

        if isInvoiceExpiryGenerated > 0 then
          raise_application_error
                      (-20086
                     , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, la position est liée à un détail d''échéancier ayant généré un document.')
                      );
        else
          delete from DOC_INVOICE_EXPIRY_DETAIL
                where DOC_POSITION_ID = aPositionId;
        end if;

        -- Effacement des imputations de pèosition
        DOC_IMPUTATION_FUNCTIONS.DeletePositionImputations(aPositionId, null, null);

        -- Mise à jour de la table des propositions de facturation
        -- Si la position est issue d'un travail de facturation des interventions (SAV externe)
        -- on met à jour la proposition qui a donné lieu à cette position
        update ASA_INVOICING_PROCESS
           set DOC_POSITION_ID = null
             , DOC_DOCUMENT_ID = null
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_ID = aPositionId;

        -- Suppression des pesées et matières liés à la position en cours d'effacement.
        DOC_POSITION_ALLOY_FUNCTIONS.DeleteAllPositionMat(aPositionID);

        -- Supprime le lien entre la position et le composant de réparation
        update ASA_RECORD_COMP
           set DOC_ATTRIB_POSITION_ID = null
         where DOC_ATTRIB_POSITION_ID = aPositionID;

        -- Effacement de la position
        delete from DOC_POSITION
              where DOC_POSITION_ID = aPositionId;

        -- Effectue la mise à jour de l'opération liée à la position. Cette procédure doit être absolument être appelée après l'effacement
        -- de la position pour que le champ indiquant la présence de commande sous-traitance sur l'opération soit cohérent.
        if lnScheduleStepID is not null then
          FAL_PRC_SUBCONTRACTO.updateOpAtPosDelete(lnScheduleStepID, lnBalanceQuantitySU);
        end if;

        -- La mise à jour du status du document doit être faite si on est pas dans un processus d'effacement complet de document
        if aMajDocStatus then
          -- Mise à jour de l'indicateur de rupture de stock de la position.
          DOC_FUNCTIONS.FlagPositionManco(null, docId);
          -- Maj du status du document Parent
          DOC_PRC_DOCUMENT.UpdateDocumentStatus(docId);
        end if;
--       exception
--         when pos_movement then
--           raise_application_error
--             (-20072
--            , PCS.PC_FUNCTIONS.TranslateWord
--                            ('PCS - Effacement impossible, la position à effacer a généré un(des) mouvement(s) de stock!')
--             );
--         when discharged then
--           raise_application_error
--                 (-20075
--                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, la position à effacer a été déchargée!')
--                 );
--         when others then
--           raise;
      end;
    elsif genMvt = 1 then
      raise_application_error(-20072
                            , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, la position à effacer a généré un(des) mouvement(s) de stock!')
                             );
    elsif IsAsaRecordEvents = 1 then
      raise_application_error(-20079, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, liens avec ASA_RECORD_EVENTS') );
    elsif IsAsaRecordComp = 1 then
      raise_application_error(-20083, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, liens avec ASA_RECORD_COMP') );
    elsif posStatus = '03' then
      raise_application_error(-20080, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, statut de la position à "Partiellement soldé"') );
    elsif posStatus = '04' then
      raise_application_error(-20073, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, statut de la position à "Liquidé"') );
    end if;
  end deletePosition;

  /**
  * Description
  *    Effacement d'un document
  */
  procedure deleteDocument(aDocumentId in number, aCreditLimit in number)
  is
    cursor crPosition(cDocumentId number)
    is
      select DOC_POSITION_ID
        from DOC_POSITION
       where DOC_DOCUMENT_ID = cDocumentId
         and DOC_DOC_POSITION_ID is null;

    currentPositionId        DOC_POSITION.DOC_POSITION_ID%type;
    docStatus                DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    financialCharging        DOC_DOCUMENT.DMT_FINANCIAL_CHARGING%type;
    gaugeId                  DOC_GAUGE.DOC_GAUGE_ID%type;
    docNumber                DOC_DOCUMENT.DMT_NUMBER%type;
    genMvt                   number(1);
    cancelStatus             number(1);
    recordId                 DOC_RECORD.DOC_RECORD_ID%type;
    dmtProtected             DOC_DOCUMENT.DMT_PROTECTED%type;
    confirmFailReason        DOC_DOCUMENT.C_CONFIRM_FAIL_REASON%type;
    dmtSessionId             DOC_DOCUMENT.DMT_SESSION_ID%type;
    nbFalJobProgram          pls_integer;
    isInvoiceExpiryGenerated pls_integer;
    vNbFalOrder              pls_integer;
    vNbSqmAnc                pls_integer;
    nbAsaMission             pls_integer;
    dmtAddendumMgm           number(1);
    vThirdId                 DOC_DOCUMENT.PAC_THIRD_ID%type;
    lEstimateId              DOC_ESTIMATE.DOC_ESTIMATE_ID%type;
    lCurrencyRiskId          DOC_DOCUMENT.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lInvoiceExpiryId         DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type;
  begin
    --savepoint BeginDeleteDoc;

    -- recherche du statut et des éventuels mouvements de stock
    begin
      select GAU.DOC_GAUGE_ID
           , C_DOCUMENT_STATUS
           , DMT_NUMBER
           , DMT_PROTECTED
           , DMT_SESSION_ID
           , DMT_FINANCIAL_CHARGING
           , GAU_CANCEL_STATUS
           , DOC_RECORD_ID
           , DMT.PAC_THIRD_ID
           , DMT.C_CONFIRM_FAIL_REASON
           , DMT.DOC_ESTIMATE_ID
           , case
               when DMT.DMT_ADDENDUM_INDEX is null then 0
               else 1
             end
           , GAL_CURRENCY_RISK_VIRTUAL_ID
           , DOC_INVOICE_EXPIRY_ID
        into gaugeId
           , docStatus
           , docNumber
           , dmtProtected
           , dmtSessionId
           , financialCharging
           , cancelStatus
           , recordId
           , vThirdId
           , confirmFailReason
           , lEstimateId
           , dmtAddendumMgm
           , lCurrencyRiskId
           , lInvoiceExpiryId
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DMT.DOC_DOCUMENT_ID = aDocumentId
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;
    exception
      when no_data_found then
        -- Rien ne se passe, l'id de document n'existe simplement pas
        null;
    end;

    -- Deprotéger le document si celui-ci est protégé ET
    --  Bloqué par la limite de crédit ET on se trouve dans l'objet pour débloquer
    --  Bloqué par le risque de change ET on se trouve dans l'objet pour débloquer
    if     (dmtProtected = 1)
       and (COM_FUNCTIONS.is_session_alive(dmtSessionId) = 0) then
      if    (     (aCreditLimit = 1)
             and (confirmFailReason = '102') )
         or (     (nvl(PCS.PC_I_LIB_SESSION.GetObjectParam('DOC_CURRENCY_RISK'), '0') = '1')
             and (confirmFailReason in('130', '131', '132', '133', '134') ) ) then
        update    DOC_DOCUMENT
              set DMT_PROTECTED = 0
                , DMT_SESSION_ID = null
            where DOC_DOCUMENT_ID = aDocumentId
        returning DMT_PROTECTED
             into dmtProtected;
      end if;
    end if;

    -- si le document a été généré depuis un devis
    if lEstimateId is not null then
      declare
        lOfferGaugeId DOC_GAUGE.DOC_GAUGE_ID%type         := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_ESTIMATE', 'DOC_GAUGE_OFFER_ID', lEstimateId);
        lOrderGaugeId DOC_GAUGE.DOC_GAUGE_ID%type         := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_ESTIMATE', 'DOC_GAUGE_ORDER_ID', lEstimateId);
        lMaxOfferId   DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
        lOrderId      DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
      begin
        -- recherche ID dernière offer
        select max(DOC_DOCUMENT_ID)
          into lMaxOfferId
          from DOC_DOCUMENT
         where DOC_ESTIMATE_ID = lEstimateId
           and DOC_GAUGE_ID = lOfferGaugeId
           and DOC_DOCUMENT_ID <> aDocumentId;

        -- recherche ID commande
        select max(DOC_DOCUMENT_ID)
          into lOrderId
          from DOC_DOCUMENT
         where DOC_ESTIMATE_ID = lEstimateId
           and DOC_GAUGE_ID = lOrderGaugeId;

        -- si on a affaire à une offre
        if GaugeId = lOfferGaugeId then
          if    lOrderId is not null
             or lMaxOfferID > aDocumentId then
            null;   -- pas de maj car ce n'est pas la dernière offre qui est supprimée ou si on a déjà une commande
          elsif lMaxOfferId is not null then
            DOC_PRC_ESTIMATE.UpdateStatus(lEstimateId, '01');   -- status modifié si il reste d'autres offres
          else
            DOC_PRC_ESTIMATE.UpdateStatus(lEstimateId, '00');   -- status saisi si pas d'autres offres existantes
          end if;
        -- effacement de la commande
        elsif GaugeId = lOrderGaugeId then
          DOC_PRC_ESTIMATE.UpdateStatus(lEstimateId, '06');   -- status accepté
        end if;
      end;
    end if;

    -- si le document n'a pas été transféré en finance et qu'il n'est pas protégé
    -- alors on peut procéder à l'effacement
    if     (financialCharging = 0)
       and (dmtProtected = 0) then
      begin
        -- un avenant ou un document à l'origine d'un avenant ne peut pas être supprimé
        if dmtAddendumMgm = 1 then
          raise_application_error(-20090, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le document gère les avenants.') );
        end if;

        -- recherche des liens avec la table ASA_MISSION
        select count(*)
          into nbAsaMission
          from ASA_MISSION
         where MIS_DOCUMENT_ID = aDocumentId;

        if nbAsaMission > 0 then
          raise_application_error
                            (-20091
                           , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, il existe un lien entre ce document et une mission de sav externe.')
                            );
        end if;

        -- recherche des liens avec la table FAL_JOB_PROGRAMM
        select count(*)
          into nbFalJobProgram
          from FAL_JOB_PROGRAM
         where DOC_DOCUMENT_ID = aDocumentId;

        if nbFalJobProgram > 0 then
          raise_application_error
                           (-20081
                          , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, il existe un lien entre ce document et un programme de fabrication.')
                           );
        end if;

        -- Verifie que le document ne soit pas utilisé dans FAL_ORDER
        select count(*)
          into vNbFalOrder
          from FAL_ORDER
         where DOC_DOCUMENT_ID = aDocumentId;

        if vNbFalOrder > 0 then
          raise_application_error(-20087, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le document est lié à un ordre de pseudo-fabrication.') );
        end if;

        -- Verifie que le document ne soit pas utilisé dans SQM_ANC
        select count(*)
          into vNbSqmAnc
          from SQM_ANC
         where DOC_DOCUMENT_ID = aDocumentId;

        if vNbSqmAnc > 0 then
          raise_application_error(-20088, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le document est lié à un avis de non-conformité.') );
        end if;

        -- Verifie que le document ne soit pas utilisé dans SQM_ANC_POSITION
        select count(*)
          into vNbSqmAnc
          from SQM_ANC_POSITION
         where DOC_DOCUMENT2_ID = aDocumentId;

        if vNbSqmAnc > 0 then
          raise_application_error
                                 (-20089
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le document est lié à une position d''avis de non-conformité.')
                                 );
        end if;

        -- Vérifie qu'il n'y ait pas de document d'échéancier générés
        select count(*)
          into isInvoiceExpiryGenerated
          from DOC_INVOICE_EXPIRY
         where DOC_DOCUMENT_ID = aDocumentId
           and INX_INVOICE_GENERATED = 1;

        if isInvoiceExpiryGenerated > 0 then
          raise_application_error(-20085, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, il y a des documents d''échéancier générés.') );
        else
          delete from DOC_INVOICE_EXPIRY
                where DOC_DOCUMENT_ID = aDocumentId;
        end if;

        -- effacement des positions des coûts à répartir
        delete from DOC_POSITION_COST
              where DOC_DOCUMENT_ID = aDocumentID;

        delete from DOC_LINK
              where DOC_DMT_SOURCE_ID = aDocumentID;

        delete from DOC_LINK
              where DOC_DMT_TARGET_ID = aDocumentID;

        -- effacement des positions
        open crPosition(aDocumentId);

        fetch crPosition
         into currentPositionId;

        while crPosition%found loop
          deletePosition(currentPositionId, false, true);

          fetch crPosition
           into currentPositionId;
        end loop;

        close crPosition;

        -- effacement remises/taxes du pied de document
        for tplFootCharge in (select DOC_FOOT_CHARGE_ID
                                from DOC_FOOT_CHARGE
                               where DOC_FOOT_ID = aDocumentID) loop
          deleteFootCharge(tplFootCharge.DOC_FOOT_CHARGE_ID);
        end loop;

        -- Effacement des décomptes TVA, normalement inutile car déjà supprimés
        delete from DOC_VAT_DET_ACCOUNT
              where DOC_FOOT_ID = aDocumentId;

        /* Effacement des avances des matières précieuses pied
           Protection des docs sources des avances dans une transaction autonome
           car sinon la màj du doc source qui est dans le trigger d'effacement de l'avance fait un lock
           Valeur de retour = 0 -> Il y a au moins un doc source d'une avance qui est protégé */
        if DeleteAlloyAdvance(aDocumentId) = 0 then
          raise_application_error
                              (-20082
                             , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, un document source d''une avance matière précieuse est protégé !')
                              );
        end if;

        /* Déprotection des documents source des avances dans une transaction autonome
           TRANSACTION AUTONOME pour être sûr que les docs source des avances soient déprotégés
           s'il y a un problème dans la suite du processus d'effacement */
        --DOC_ALLOY_ADVANCE_FUNCTIONS.UnProtectSrcDocuments(1);

        -- Effacement des matières précieuses pied
        delete from DOC_FOOT_ALLOY
              where DOC_FOOT_ID = aDocumentId;

        -- Effacement des transactions de paiement multiple (vente au comptant)
        delete from DOC_FOOT_PAYMENT
              where DOC_FOOT_ID = aDocumentId;

        -- Supprime le lien entre le document et le dossier de réparation
        update ASA_RECORD
           set DOC_ATTRIB_DOCUMENT_ID = null
         where DOC_ATTRIB_DOCUMENT_ID = aDocumentID;

        -- Supprime le lien entre le document et l'intervention et met à jour le statut de la mission (SAV externe)
        update ASA_MISSION MIS
           set C_ASA_MIS_STATUS = '02'
         where MIS.ASA_MISSION_ID in(select ASA_MISSION_ID
                                       from ASA_INTERVENTION
                                      where DOC_DOCUMENT_ID = aDocumentID)
           and MIS.C_ASA_MIS_STATUS = '05';

        update ASA_INTERVENTION
           set DOC_DOCUMENT_ID = null
             , C_ASA_ITR_STATUS = '02'
         where DOC_DOCUMENT_ID = aDocumentID;

        -- Effacement du lien avec le document de pré-saisie
        deleteFinancialLink(iDocumentID => aDocumentId, iComName => ACI_LOGISTIC_DOCUMENT.getFinancialCompany(GaugeId, vThirdId) );

        -- Effacement du pied
        delete from DOC_FOOT
              where DOC_FOOT_ID = aDocumentId;

        -- Effacement des éléments liés au document e-facture.
        DOC_DELETE.pDeleteDocEBPPInfos(inDocDocumentID => aDocumentId);

        -- Effacement de l'historique de la couverture virtuelle (attention cette suppression doit être faite après celle du DOC_FOOT)
        delete from GAL_CURRENCY_RISK_V_HISTO
              where DOC_DOCUMENT_ID = aDocumentId;

        -- Effacement du document
        delete from DOC_DOCUMENT
              where DOC_DOCUMENT_ID = aDocumentId;

        -- Effacement eventuel du dossier
        deleteRecord(gaugeId, recordId, aDocumentId);
        -- Ajout à liste des documents dont on doit mettre à jour le status
        DOC_I_PRC_DOCUMENT.AddDocToListParent(iInvoiceExpiryId => lInvoiceExpiryId);
        -- Mise à jour du flag "échéance générée"
        DOC_INVOICE_EXPIRY_FUNCTIONS.UpdateInvoiceGeneratedFlag(iInvoiceExpiryId => lInvoiceExpiryId);
        -- mise à jour des documents parents
        DOC_PRC_DOCUMENT.ProcessListParent;
      exception
        when adv_src_doc_protected then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , currentPositionId   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'At least one document source of a precious mat. advance is protected'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
--          declare
--            /* liste des docs source a des avances à déprotéger */
--            cursor crDocList
--            is
--              select COM_LIST_ID_TEMP_ID
--                from COM_LIST_ID_TEMP
--               where LID_FREE_CHAR_1 = 'DOC_ALLOY_ADVANCE';
--
--            tplDocList crDocList%rowtype;
--          begin
--            open crDocList;
--
--            fetch crDocList
--             into tplDocList;
--
--            /* Il y a eu une erreur lors de l'effacement d'une avance matière précieuse
--               il faut annuler tout le processus d'effacement document */
--            --rollback to savepoint BeginDeleteDoc;
--
--            /* Déprotéger les documents sources qui se trouve dans la liste
--               des docs protégés par le processus d'effacement d'une avance */
--            while crDocList%found loop
--              /* Déprotéger le document source avec une transaction autonome
--                 pour que les docs sources soient biens déprotégés à cause
--                 du rollback du à l'exception que l'on a provoquée */
--              DOC_DOCUMENT_FUNCTIONS.DocumentProtect_AutoTrans(tplDocList.COM_LIST_ID_TEMP_ID   /* aDocumentID */
--                                                             , 0   /* aProtect */
--                                                             , null   /* aSessionID */
--                                                             , 'DOC_ALLOY_ADVANCE'   /* aListDescr */
--                                                              );
--
--              /* Enlever l'ID du document source à la liste des documents protégés */
--              DOC_DOCUMENT_FUNCTIONS.DelProtectedDocument(tplDocList.COM_LIST_ID_TEMP_ID, 'DOC_ALLOY_ADVANCE');
--
--              fetch crDocList
--               into tplDocList;
--            end loop;
--
--            close crDocList;
--          end;
--
          raise_application_error
                               (-20082
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, un document source d''une avance matière précieuse est protégé !')
                               );
        when pos_status_finished then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , currentPositionId   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'At least one position with status "04" : "finished"'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error
            (-20073
           , PCS.PC_FUNCTIONS.TranslateWord
                            ('PCS - Effacement impossible, le statut d''au moins une position du document à effacer est à "Liquidé" ou à "Partiellement soldée"')
            );
        when pos_status_partial then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , currentPositionId   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'At least one position with status "03" : "partialy balanced"'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error
            (-20080
           , PCS.PC_FUNCTIONS.TranslateWord
                            ('PCS - Effacement impossible, le statut d''au moins une position du document à effacer est à "Liquidé" ou à "Partiellement soldée"')
            );
        when movement then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , currentPositionId   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'At least one position with stock movements'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error
            (-20072
           , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, au moins une position du document à effacer a généré un(des) mouvement(s) de stock!')
            );
        when discharged then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , currentPositionId   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'At least one discharged position'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error(-20075
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, au moins une position du document à effacer a été déchargée!')
                                 );
        when record_events then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , currentPositionId   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'Positions used in table ASA_RECORD_EVENTS'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error(-20079
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, au moins une position du document est liée à une réparation!')
                                 );
        when record_comp then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , currentPositionId   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'Positions used in table ASA_RECORD_COMP'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error
                       (-20083
                      , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, au moins une position du document est liée à un composant de réparation!')
                       );
        when used_in_fal_job_program then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , null
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'LINK WITH FAL_JOB_PROGRAM'
                                               , 'There is a link between DOC_DOCUMENT and FAL_JOB_PROGRAM'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error
                            (-20081
                           , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, il existe un lien entre ce document et un programme de fabrication.')
                            );
        when fch_discharged then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , null   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'At least one discharged foot charge'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error(-20084, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, une charge financière du document a été déchargée !') );
        when invoice_expiry then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , null   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'It''s generated billbook documents'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error(-20085, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, il y a des documents d''échéancier générés.') );
        when invoice_expiry_detail then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , null   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'Position linked to a generated billbook detail'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error
                       (-20086
                      , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, la position est liée à un détail d''échéancier ayant généré un document.')
                       );
        when addendum_management then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , null   /* DOC_POSITION_ID */
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'DOCUMENT DELETE FORBIDDEN'
                                               , 'Document with addendum management'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error(-20090, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le document gère les avenants.') );
        when used_in_asa_mission then
          DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                               , null
                                               , docNumber   /* no de document */
                                               , 'PLSQL'   /* DUH_TYPE */
                                               , 'LINK WITH ASA_MISSION'
                                               , 'There is a link between DOC_DOCUMENT and ASA_MISSION'   /* description libre */
                                               , docStatus   /* status document */
                                               , null   /* status position */
                                                );
          raise_application_error
                             (-20091
                            , PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, il existe un lien entre ce document et une mission de sav externe.')
                             );
      end;
/*
    -- document liquidé, effacement impossible
    elsif docStatus = '04' then
      DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId,
                                             null, -- DOC_POSITION_ID
                                             docNumber, -- no de document
                                             'PLSQL', -- DUH_TYPE
                                             'DOCUMENT DELETE FORBIDDEN',
                                             'Document status is "04" : "finished"', -- description libre
                                             docStatus, -- status document
                                             null); -- status position
      raise_application_error(-20071,PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le document à effacer est "Liquidé"!'));
*/
/*
    -- Effacement non autorisé par le gabarit
    elsif (cancelStatus = 1) then
      DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId,
                                             null, -- DOC_POSITION_ID
                                             docNumber, -- no de document
                                             'PLSQL', -- DUH_TYPE
                                             'DOCUMENT DELETE FORBIDDEN',
                                             'Document cannot be deleted, it can only be canceled!', -- description libre
                                             docStatus, -- status document
                                             null); -- status position
      raise_application_error(-20077,PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le gabarit document l''interdit!'));
*/
    -- document transféré en finance
    elsif financialCharging = 1 then
      DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                           , null   /* DOC_POSITION_ID */
                                           , docNumber   /* no de document */
                                           , 'PLSQL'   /* DUH_TYPE */
                                           , 'DOCUMENT DELETE FORBIDDEN'
                                           , 'Financial transfer already carried out'   /* description libre */
                                           , docStatus   /* status document */
                                           , null   /* status position */
                                            );
      raise_application_error(-20076, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le document a été transféré en finance!') );
    elsif dmtProtected = 1 then
      DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                           , null   /* DOC_POSITION_ID */
                                           , docNumber   /* no de document */
                                           , 'PLSQL'   /* DUH_TYPE */
                                           , 'DOCUMENT DELETE FORBIDDEN'
                                           , 'Protected document'   /* description libre */
                                           , docStatus   /* status document */
                                           , null   /* status position */
                                            );
      raise_application_error(-20078, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, le document est protégé!') );
    end if;
  end deleteDocument;

  /**
  * Description
  *    Effacement d'un document. Sans déclenchement d'exception.
  *    Cette fonction retourne un code d'erreur.
  */
  procedure deleteDocument(aDocumentId in number, aCreditLimit in number, aErrorCode out varchar2)
  is
  begin
    deleteDocument(aDocumentId, aCreditLimit);
  exception
    when doc_status then
      aErrorCode  := 'doc_status';
    when movement then
      aErrorCode  := 'movement';
    when pos_status_finished then
      aErrorCode  := 'pos_status_finished';
    when pos_status_partial then
      aErrorCode  := 'pos_status_partial';
    when discharged then
      aErrorCode  := 'discharged';
    when financial_transfert then
      aErrorCode  := 'financial_transfert';
    when cancel_status then
      aErrorCode  := 'cancel_status';
    when protected_document then
      aErrorCode  := 'protected_document';
    when record_events then
      aErrorCode  := 'record_events';
    when record_comp then
      aErrorCode  := 'record_comp';
    when used_in_fal_job_program then
      aErrorCode  := 'used_in_fal_job_program';
    when adv_src_doc_protected then
      aErrorCode  := 'adv_src_doc_protected';
    when fch_discharged then
      aErrorCode  := 'fch_discharged';
    when invoice_expiry then
      aErrorCode  := 'invoice_expiry';
    when invoice_expiry_detail then
      aErrorCode  := 'invoice_expiry_detail';
    when used_in_fal_order then
      aErrorCode  := 'used_in_fal_order';
    when used_in_sqm_anc then
      aErrorCode  := 'used_in_sqm_anc';
    when used_in_sqm_anc_position then
      aErrorCode  := 'used_in_sqm_anc_position';
    when addendum_management then
      aErrorCode  := 'addendum_management';
    when used_in_asa_mission then
      aErrorCode  := 'used_in_asa_mission';
  end deleteDocument;

  /**
  * Description
  *   fonction d'effacement du dossier lié à un document que l'on vient de supprimer
  *   ne doit être appelé qu'en supression de document
  */
  function deleteRecord(aGaugeId in number, aRecordId in number, aDocumentId in number)
    return boolean
  is
    docGaugeID DOC_GAUGE.DOC_GAUGE_ID%type;
    vRecordId  DOC_RECORD.DOC_RECORD_ID%type;
  begin
    if     aRecordId is not null
       and aGaugeId is not null then
      begin
        select DOC_GAUGE_ID
          into docGaugeID
          from DOC_GAUGE
         where DOC_GAUGE_ID = aGaugeId
           and GAU_DOSSIER = 1
           and C_GAU_AUTO_CREATE_RECORD <> '0';

        -- recherche préliminaire pour éviter les locks
        select DOC_RECORD_ID
          into vRecordId
          from DOC_RECORD
         where DOC_RECORD_ID = aRecordId
           and DOC_PROJECT_DOCUMENT_ID = aDocumentId;

        -- Effacement du dossier si la config du gabarit l'exige
        delete from DOC_RECORD
              where DOC_RECORD_ID = vRecordId;
      exception
        when no_data_found then
          null;
      end;
    end if;

    if     aGaugeId is not null
       and PCS.PC_CONFIG.GetConfig('GAL_MANUFACTURING_MODE') = '1' then
      declare
        vCfgGAL_GAUGE_BALANCE_ORDER varchar2(2000);
      begin
        vCfgGAL_GAUGE_BALANCE_ORDER  := PCS.PC_CONFIG.GetConfig('GAL_GAUGE_BALANCE_ORDER');

        select DOC_GAUGE_ID
          into docGaugeID
          from DOC_GAUGE
         where DOC_GAUGE_ID = aGaugeId
           and checkList(GAU_DESCRIBE, vCfgGAL_GAUGE_BALANCE_ORDER) = 1
           and GAU_DOSSIER = 1
           and C_GAU_AUTO_CREATE_RECORD <> '0';

        -- recherche préliminaire pour éviter les locks
        select DOC_RECORD_ID
          into vRecordId
          from DOC_RECORD
         where DOC_PROJECT_DOCUMENT_ID = aDocumentId
           and C_RCO_TYPE = '09';

        -- Effacement du dossier si la config du gabarit l'exige
        delete from DOC_RECORD
              where DOC_RECORD_ID = vRecordId;
      exception
        when no_data_found then
          null;
      end;
    end if;

    -- fonction OK (Effacement OK ou effacement pas nécessaire)
    return true;
  exception
    -- pas de bloquage si le dossier ne peut être effacé
    when ex.CHILD_RECORD_FOUND then
      -- Problèmes à l'effacement car le dossier est utilisé par d'autres documents
      return false;
  end deleteRecord;

  /**
  * Description
  *   procedure d'effacement du dossier lié à un document que l'on vient de supprimer
  *   ne doit être appelé qu'en supression de document
  */
  procedure deleteRecord(aGaugeId in number, aRecordId in number, aDocumentId in number)
  is
  begin
    if deleteRecord(aGaugeId, aRecordId, aDocumentId) then
      null;
    end if;
  end deleteRecord;

  /**
  * procedure deleteFootCharge
  * Description
  *   procedure d'effacement d'une remise/taxe/frais de pied de document
  * @created ngv 31.08.2005
  * @lastUpdate
  * @private
  * @param aFootChargeID : Id de la remise/taxe/frais de pied de document a effacer
  */
  procedure deleteFootCharge(aFootChargeID in number)
  is
    SrcFootChargeID DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type;
    ChargeOrigin    DOC_FOOT_CHARGE.C_CHARGE_ORIGIN%type;
    FootID          DOC_FOOT.DOC_FOOT_ID%type;
    SrcFootID       DOC_FOOT.DOC_FOOT_ID%type;
    FchDischarged   DOC_FOOT_CHARGE.FCH_DISCHARGED%type;
  begin
    -- Vérifier si la charge pied est issue d'une décharge
    select DOC_FOOT_CHARGE_SRC_ID
         , C_CHARGE_ORIGIN
         , DOC_FOOT_ID
         , nvl(FCH_DISCHARGED, 0)
      into SrcFootChargeID
         , ChargeOrigin
         , FootID
         , FchDischarged
      from DOC_FOOT_CHARGE
     where DOC_FOOT_CHARGE_ID = aFootChargeID;

    -- charge pied déchargée
    if FchDischarged = 1 then
      raise_application_error(-20084, PCS.PC_FUNCTIONS.TranslateWord('PCS - Effacement impossible, une charge financière du document a été déchargée !') );
    end if;

    -- Màj de la charge pied parent
    if (SrcFootChargeID is not null) then
      -- Recherche l'id du foot de la charge source
      select max(DOC_FOOT_ID)
        into SrcFootID
        from DOC_FOOT_CHARGE
       where DOC_FOOT_CHARGE_ID = SrcFootChargeID;

      -- Si décharge il faut mettre à 0 le flag déchargé de la charge source
      if ChargeOrigin = 'DISCH' then
        update DOC_FOOT_CHARGE
           set FCH_DISCHARGED = 0
         where DOC_FOOT_CHARGE_ID = SrcFootChargeID;
      end if;

      -- la maj du compteur des charges pied dans la table de lien
      update DOC_DOCUMENT_LINK
         set DLK_COUNT = DLK_COUNT - 1
       where DOC_DOCUMENT_ID = FootID
         and DOC_DOCUMENT_SRC_ID = SrcFootID
         and C_DOCUMENT_LINK = 'FCH-' || ChargeOrigin;
    end if;

    -- effacement
    delete from DOC_FOOT_CHARGE
          where DOC_FOOT_CHARGE_ID = aFootChargeID;
  end deleteFootCharge;

  /**
  * Description
  *   Mise à jour des liens CML lors de l'effacement d'une position
  */
  procedure updateCmlOnDocPosDelete(aCmlPositionId in number, aEventId in number, aInvoicingJobId in number, aDocPositionId in number)
  is
    continue     number(1);
    amount       CML_GEN_DOC.CGD_VALUE%type;
    eventType    CML_EVENTS.C_CML_EVENT_TYPE%type;
    vExtractType CML_GEN_DOC.CGD_EXTRACTION_TYPE%type;
    vMultiply    CML_GEN_DOC.CGD_MULTIPLY%type;

    procedure clearProvDocument(aCmlPositionId in number, aDocPositionId in number)
    is
    begin
      -- contrôle si il existe encore des données sauvegardée en attente de confirmation du document
      update CML_POSITION
         set DOC_PROV_DOCUMENT_ID = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_ID = aCmlPositionId
         and exists(
               select cml_gen_doc.doc_position_id
                 from doc_position
                    , cml_gen_doc
                where cml_gen_doc.cml_position_id = CML_POSITION.CML_POSITION_ID
                  and doc_position.doc_position_id = cml_gen_doc.doc_position_id
                  and doc_position.doc_document_id = (select doc_document_id
                                                        from doc_position
                                                       where doc_position_id = aDocPositionId) );
    end clearProvDocument;
  begin
    if aEventId is not null then
      update    CML_EVENTS
            set (CEV_AMOUNT_DOC, CEV_INDICE, CEV_INDICE_V_DATE, CEV_INDICE_VARIABLE) =
                  (select CEV_AMOUNT_DOC
                        , CEV_INDICE
                        , CEV_INDICE_V_DATE
                        , CEV_INDICE_VARIABLE
                     from CML_EVENTS_BACK
                    where CML_EVENTS_BACK.CML_EVENTS_ID = CML_EVENTS.CML_EVENTS_ID)
              , DOC_POSITION_ID = null
              , A_DATEMOD = sysdate
              , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
          where CML_EVENTS_ID = aEventId
            and exists(select CML_EVENTS_ID
                         from CML_EVENTS_BACK
                        where CML_EVENTS_BACK.CML_EVENTS_ID = CML_EVENTS.CML_EVENTS_ID)
      returning C_CML_EVENT_TYPE
           into eventType;

      -- Si la table CML_EVENTS_BACK ne contenait rien pour l'enregistrement à mettre à jour
      if sql%notfound then
        update    CML_EVENTS
              set DOC_POSITION_ID = null
                , A_DATEMOD = sysdate
                , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
            where CML_EVENTS_ID = aEventId
        returning C_CML_EVENT_TYPE
             into eventType;
      else
        delete from CML_EVENTS_BACK
              where CML_EVENTS_ID = aEventId;
      end if;

      select nvl(max(CGD_VALUE * CGD_MULTIPLY), 0)
        into amount
        from CML_GEN_DOC
       where DOC_POSITION_ID = aDocPositionID;

      -- contrôle si il existe encore des données sauvegardée en attente de confirmation du document
      clearProvDocument(aCmlPositionId, aDocPositionId);

      delete from CML_GEN_DOC
            where DOC_POSITION_ID = aDocPositionID;

      -- Mise à jour des montants en fonction du type d'événement et du type de position CML
      -- 1 : Facturation complémentaire
      if eventType = '1' then
        update CML_POSITION
           set CPO_MAINT_AMOUNT = decode(C_CML_POS_TYPE, '1', CPO_MAINT_AMOUNT + amount, CPO_MAINT_AMOUNT)
             , CPO_RENT_AMOUNT = decode(C_CML_POS_TYPE, '1', CPO_RENT_AMOUNT, CPO_RENT_AMOUNT + amount)
             , CPO_POSITION_ADDED_AMOUNT = nvl(CPO_POSITION_ADDED_AMOUNT, 0) - amount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_POSITION_ID = aCmlPositionId;
      -- 2 : Montant supplémentaire facturé
      elsif eventType = '2' then
        update CML_POSITION
           set CPO_MAIN_ADDED_AMOUNT = decode(C_CML_POS_TYPE, '1', CPO_MAIN_ADDED_AMOUNT + amount, CPO_MAIN_ADDED_AMOUNT)
             , CPO_RENT_ADDED_AMOUNT = decode(C_CML_POS_TYPE, '1', CPO_RENT_ADDED_AMOUNT, CPO_RENT_ADDED_AMOUNT + amount)
             , CPO_POSITION_ADDED_AMOUNT = nvl(CPO_POSITION_ADDED_AMOUNT, 0) - amount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_POSITION_ID = aCmlPositionId;
      -- 3 : Note de crédit / montant facturé
      elsif eventType = '3' then
        update CML_POSITION
           set CPO_MAINT_AMOUNT = decode(C_CML_POS_TYPE, '1', CPO_MAINT_AMOUNT - amount, CPO_MAINT_AMOUNT)
             , CPO_RENT_AMOUNT = decode(C_CML_POS_TYPE, '1', CPO_RENT_AMOUNT, CPO_RENT_AMOUNT - amount)
             , CPO_POSITION_ADDED_AMOUNT = nvl(CPO_POSITION_ADDED_AMOUNT, 0) - amount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_POSITION_ID = aCmlPositionId;
      -- 4 : Note de crédit / perte
      elsif eventType = '4' then
        update CML_POSITION
           set CPO_MAINT_LOSS = decode(C_CML_POS_TYPE, '1', CPO_MAINT_LOSS + amount, CPO_MAINT_LOSS)
             , CPO_RENT_LOSS = decode(C_CML_POS_TYPE, '1', CPO_RENT_LOSS, CPO_RENT_LOSS + amount)
             , CPO_POSITION_LOSS = nvl(CPO_POSITION_LOSS, 0) + amount
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_POSITION_ID = aCmlPositionId;
      -- 5 : Excédents de consommation
      elsif eventType = '5' then
        -- La position CML n'est pas màj lors de la création d'un événement de
        -- type '5' -> donc rien à faire sur cette position cml lors de
        -- l'effacement de la position DOC
        null;
      end if;
    elsif aCmlPositionId is not null then
      begin
        -- Rechercher le type de la position facturée (Forfait, Pénalité ou Dépot)
        -- et si le document est une Facture ou Note de crédit
        select CGD_EXTRACTION_TYPE
             , CGD_MULTIPLY
          into vExtractType
             , vMultiply
          from CML_GEN_DOC
         where DOC_POSITION_ID = aDocPositionID;
      exception
        when no_data_found then
          vExtractType  := 3;
      end;

      -- 1 : 'DEPOSIT'
      if vExtractType = 1 then
        -- Facture
        if vMultiply = 1 then
          update CML_POSITION
             set CPO_DEPOT_BILL_DATE = null
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where CML_POSITION_ID = aCmlPositionId;
        else
          -- Note de crédit
          update CML_POSITION
             set CPO_DEPOT_CN_DATE = null
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where CML_POSITION_ID = aCmlPositionId;
        end if;
      -- 2 : 'PENALITY'
      elsif vExtractType = 2 then
        update CML_POSITION
           set CPO_PENALITY_BILL_DATE = null
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_POSITION_ID = aCmlPositionId;
      -- 3 : 'FIXEDPRICE'
      elsif vExtractType = 3 then
        -- récupération des anciennes valeurs de dates
        update CML_POSITION
           set (C_CML_POS_STATUS, CPO_DEPOT_BILL_GEN, CPO_DEPOT_CN_GEN, CPO_LAST_MAINT_DATE, CPO_LAST_PERIOD_BEGIN, CPO_LAST_PERIOD_END, CPO_LAST_RENT_DATE
              , CPO_NEXT_DATE, CPO_PENALITY_BILL_GEN, CPO_POSITION_AMOUNT, CPO_INDICE_VARIABLE, CPO_INDICE_V_DATE, CPO_MAINT_AMOUNT, CPO_RENT_AMOUNT) =
                 (select C_CML_POS_STATUS
                       , CPO_DEPOT_BILL_GEN
                       , CPO_DEPOT_CN_GEN
                       , CPO_LAST_MAINT_DATE
                       , CPO_LAST_PERIOD_BEGIN
                       , CPO_LAST_PERIOD_END
                       , CPO_LAST_RENT_DATE
                       , CPO_NEXT_DATE
                       , CPO_PENALITY_BILL_GEN
                       , CPO_POSITION_AMOUNT
                       , CPO_INDICE_VARIABLE
                       , CPO_INDICE_V_DATE
                       , CPO_MAINT_AMOUNT
                       , CPO_RENT_AMOUNT
                    from CML_POSITION_BACK
                   where CML_POSITION_BACK.CML_POSITION_ID = CML_POSITION.CML_POSITION_ID)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_POSITION_ID = aCmlPositionId
           and exists(select CML_POSITION_ID
                        from CML_POSITION_BACK
                       where CML_POSITION_BACK.CML_POSITION_ID = CML_POSITION.CML_POSITION_ID);
      end if;

      -- effacement des données d'historique qu'on vient de récupérer
      delete from CML_POSITION_BACK
            where CML_POSITION_ID = aCmlPositionId;

      -- contrôle si il existe encore des données sauvegardée en attente de confirmation du document
      clearProvDocument(aCmlPositionId, aDocPositionId);

      delete from CML_GEN_DOC
            where DOC_POSITION_ID = aDocPositionID;
    else
      -- contrôle si il existe encore des données sauvegardée en attente de confirmation du document
      clearProvDocument(aCmlPositionId, aDocPositionId);
    end if;

    -- Si la position est issue d'un travail de facturation des contrats
    -- on met à jour la proposition qui a donné lieu à cette position
    if aInvoicingJobId is not null then
      update CML_INVOICING_PROCESS
         set DOC_POSITION_ID = null
           , DOC_DOCUMENT_ID = null
           , INP_POS_DELETED = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_INVOICING_JOB_ID = aInvoicingJobId
         and DOC_POSITION_ID = aDocPositionId;
    end if;
  end updateCmlOnDocPosDelete;

  /**
  * Description
  *   Mise à jour du flag DMN_CREATING lors de l'abandon d'un document
  *   avant le post
  */
  procedure updateMissingNumberOnCancel(aDocNumber in varchar2)
  is
  begin
    update DOC_MISSING_NUMBER
       set DMN_CREATING = 0
     where DMN_NUMBER = aDocNumber;
  end updateMissingNumberOnCancel;

  /**
  * Description
  *   Mise à 0 du flag DOF_CREATING lors de l'abandon d'un document
  *   avant le post
  */
  procedure updateFreeNumberOnCancel(aGaugeId in number, aDocNumber in varchar2)
  is
    gauNumber  DOC_GAUGE.GAU_NUMBERING%type;
    freeNumber DOC_GAUGE_NUMBERING.GAN_FREE_NUMBER%type;
  begin
    -- Vérifie si la récupération des numéros libres est active
    begin
      select nvl(GAU_NUMBERING, 0)
           , nvl(GAN_FREE_NUMBER, 0)
        into gauNumber
           , freeNumber
        from DOC_GAUGE
           , DOC_GAUGE_NUMBERING
       where DOC_GAUGE_ID = aGaugeId
         and DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID(+) = DOC_GAUGE.DOC_GAUGE_NUMBERING_ID;
    exception
      when no_data_found then
        -- Rien ne se passe, l'id du gabarit n'existe simplement pas
        gauNumber   := 0;
        freeNumber  := 0;
    end;

    if (gauNumber = 1) then
      if (freeNumber = 1) then
        update DOC_FREE_NUMBER
           set DOF_CREATING = 0
             , DOF_SESSION_ID = 0
         where DOF_NUMBER = aDocNumber;
      else
        DOC_DOCUMENT_FUNCTIONS.freeSessionNumbers;
      end if;
    end if;
  end updateFreeNumberOnCancel;

  /**
  * Description
  *   fonction d'effacement des avances d'un document que l'on vient de supprimer
  *   ne doit être appelé qu'en supression de document
  */
  function DeleteAlloyAdvance(aDocumentId in number)
    return number
  is
    adv_src_doc_protected exception;
    pragma exception_init(adv_src_doc_protected, -20082);
    nContinue             number;
  begin
    /* Vérifier s'il y a un doc source d'une avance qui est protégé. nContinue peut avoir les valeurs suivantes :
        0 = Au moins un document lié à une avance est protègé, effacement interdit.
        1 = Au moins une avance existe et aucun document lié n'est protègé.
       -1 = Aucune avance n'existe sur le document courant. */
    select decode(max(DMT_PROTECTED), null, -1, 0, 1, 1, 0)
      into nContinue
      from DOC_DOCUMENT DMT
         , DOC_ALLOY_ADVANCE DAA
     where DAA.DOC_DOC_DOCUMENT_ID = aDocumentId
       and DMT.DOC_DOCUMENT_ID = DAA.DOC_DOCUMENT_ID;

    if nContinue = 1 then
      /* Balayer la liste des avances à effacer */
      for tplAdvList in (select DOC_ALLOY_ADVANCE_ID
                              , DOC_DOCUMENT_ID
                           from DOC_ALLOY_ADVANCE
                          where DOC_DOC_DOCUMENT_ID = aDocumentId) loop
        /* Protection du document source dans une transaction autonome */
        --DOC_ALLOY_ADVANCE_FUNCTIONS.ProtectSrcDocument(tplAdvList.DOC_DOCUMENT_ID, 1);

        /* Effacement de l'avance */
        delete from DOC_ALLOY_ADVANCE
              where DOC_ALLOY_ADVANCE_ID = tplAdvList.DOC_ALLOY_ADVANCE_ID;
      end loop;
    end if;

    return nContinue;
  end DeleteAlloyAdvance;

  /**
  * Description
  *    Supression du lien avec la finance
  */
  procedure deleteFinancialLink(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iComName in DOC_DOCUMENT.COM_NAME_ACI%type)
  is
    vSql        varchar2(20000);
    vScrDbOwner PCS.PC_SCRIP.SCRDBOWNER%type;
    vScrDblink  PCS.PC_SCRIP.SCRDB_LINK%type;
  begin
    if iComName is not null then
      PCS.PC_FUNCTIONS.GetCompanyOwner(iComName, vScrDbOwner, vScrDblink);

      if vScrDblink is not null then
        vScrDblink  := '@' || vScrDblink;
      end if;
    else
      vScrDbOwner  := PCS.PC_I_LIB_SESSION.GetCompanyOwner;
    end if;

    vSql  := 'delete from [COMPANY_OWNER2].ACT_DOC_RECEIPT@[DB_LINK] where DOC_DOCUMENT_ID = :DOC_DOCUMENT_ID';
    vSql  := replace(vSql, '[COMPANY_OWNER2]', vScrDbOwner);
    vSql  := replace(vSql, '@[DB_LINK]', vScrDbLink);

    execute immediate vSql
                using iDocumentID;
  end deleteFinancialLink;

  /**
  * Description
  *    Mise à jour des composants pères lors de l'effacement du produit terminé fils (composé). Traitement uniquement
  *    des composants pères qui ne possèdent plus de fils.
  */
  procedure UpdateFatherComponentsOnDelete(aPositionId in number)
  is
    cursor crComponents(cPositionId number)
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , POS.DOC_POSITION_ID
           , POS.POS_UTIL_COEFF
        from DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
       where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and POS.DOC_DOC_POSITION_ID = cPositionId;

    nDischargeQuantity     DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    nBalanceQuantity       DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type;
    nBalancedQuantity      DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY_PARENT%type;
    parentPositionDetailId DOC_POSITION_DETAIL.DOC_DOC_POSITION_DETAIL_ID%type;
    parentPositionId       DOC_POSITION.DOC_POSITION_ID%type;
    targetPositionDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  begin
    -- Remarque générale
    -- Le facteur de convertion n'intervient jamais dans le cadre de l'ensemble des positions kit ou assemblage, produit
    -- terminé et composants. Le facteur de conversion est toujours à 1.
    --
    -- Recherche les informations du produit terminé père.
    select max(PDE_FATHER.DOC_POSITION_DETAIL_ID)
         , max(PDE_FATHER.DOC_POSITION_ID)
      into parentPositionDetailID
         , parentPositionID
      from DOC_POSITION_DETAIL PDE
         , DOC_POSITION_DETAIL PDE_FATHER
     where PDE.DOC_POSITION_ID = aPositionID
       and PDE_FATHER.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID;

    -- Recherche la quantité du produit terminé à recharger sur les composants de la position père. On considère que
    -- le produit terminé possède éventuellement plusieurs détails mais de même père. Les détails qui ne sont pas liés
    -- à un père ne sont pas pris en compte.
    select sum(PDE.PDE_FINAL_QUANTITY)
         , sum(PDE.PDE_BALANCE_QUANTITY_PARENT)
      into nDischargeQuantity
         , nBalancedQuantity
      from DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where POS.DOC_POSITION_ID = aPositionId
       and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and PDE.DOC_DOC_POSITION_DETAIL_ID is not null;

    -- Balaye les composants du produit terminé du père en excluant les positions qui seront traitées lors de l'effacement du fils.
    for tplComponents in crComponents(parentPositionId) loop
      -- Vérifie que le détail du composant courant n'est pas lié à un détail de composant fils.
      select max(PDE.DOC_POSITION_DETAIL_ID)
        into targetPositionDetailId
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
       where POS.DOC_DOC_POSITION_ID = aPositionID
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and PDE.DOC_DOC_POSITION_DETAIL_ID = tplComponents.DOC_POSITION_DETAIL_ID;

      if targetPositionDetailId is null then
        -- Mise à jour de la quantity solde des détails pères.
        update DOC_POSITION_DETAIL
           set PDE_BALANCE_QUANTITY =
                 decode(sign(PDE_BASIS_QUANTITY)
                      , -1, greatest(least( (PDE_BALANCE_QUANTITY +
                                             ACS_FUNCTION.RoundNear(nDischargeQuantity * tplComponents.POS_UTIL_COEFF +
                                                                    nBalancedQuantity * tplComponents.POS_UTIL_COEFF
                                                                  , 1 / power(10, GCO_FUNCTIONS.GetNumberOfDecimal(GCO_GOOD_ID) )
                                                                  , 0
                                                                   )
                                            )
                                         , 0
                                          )
                                   , PDE_FINAL_QUANTITY
                                    )
                      , least(greatest( (PDE_BALANCE_QUANTITY +
                                         ACS_FUNCTION.RoundNear(nDischargeQuantity * tplComponents.POS_UTIL_COEFF +
                                                                nBalancedQuantity * tplComponents.POS_UTIL_COEFF
                                                              , 1 / power(10, GCO_FUNCTIONS.GetNumberOfDecimal(GCO_GOOD_ID) )
                                                              , 0
                                                               )
                                        )
                                     , 0
                                      )
                            , PDE_FINAL_QUANTITY
                             )
                       )
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_DETAIL_ID = tplComponents.DOC_POSITION_DETAIL_ID;

        -- Recherche la nouvelle quantité solde à mettre à jour sur la position courante. C'est toujours la somme
        -- des quantités soldes des détails de la position.
        select sum(PDE_BALANCE_QUANTITY)
          into nBalanceQuantity
          from DOC_POSITION_DETAIL PDE
         where PDE.DOC_POSITION_ID = tplComponents.DOC_POSITION_ID;

        -- Mise à jour de la quantité solde du parent. Le statut de la position n'est pas mise à jour
        -- ici, car le traitement d'effacement du PT fils effectuera à posteriori la mise à jour
        update DOC_POSITION parent
           set POS_BALANCE_QUANTITY = nBalanceQuantity
             , C_DOC_POS_STATUS = decode(nBalanceQuantity, 0, '04', POS_FINAL_QUANTITY, '02', '03')
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where parent.DOC_POSITION_ID = tplComponents.DOC_POSITION_ID
           and parent.GCO_GOOD_ID is not null;
      end if;
    end loop;
  end UpdateFatherComponentsOnDelete;
end DOC_DELETE;
