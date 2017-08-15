--------------------------------------------------------
--  DDL for Package Body DOC_PRC_DOCUMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_DOCUMENT" 
is
  gtblDocListParent             ID_TABLE_TYPE                 := ID_TABLE_TYPE();
  gcCOM_CURRENCY_RISK_MANAGE    boolean                       := PCS.PC_CONFIG.GetBooleanConfig('COM_CURRENCY_RISK_MANAGE');
  gcDOC_CURRENCY_RATE_TRANSFERT varchar2(1)                   := PCS.PC_CONFIG.GetConfigUpper('DOC_CURRENCY_RATE_TRANSFERT');
  gcGAL_GAUGE_BALANCE_ORDER     PCS.PC_CBASE.CBACVALUE%type   := PCS.PC_CONFIG.GetConfig('GAL_GAUGE_BALANCE_ORDER');
  gcDOC_CURRENCY_FORCE_EXP_RATE varchar2(1)                   := PCS.PC_CONFIG.GetConfigUpper('DOC_CURRENCY_FORCE_EXPIRY_RATE');

  /**
  * procedure ControlUpdateDocument
  * Description
  *   Méthode permettant de contrôler l'état du document en vue d'une modification éventuelle.
  */
  procedure ControlUpdateDocument(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, oErrorText out DOC_DOCUMENT.DMT_ERROR_MESSAGE%type)
  is
    lnProtected         DOC_DOCUMENT.DMT_PROTECTED%type;
    lvDocumentStatus    DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    lnFinancialCharging DOC_DOCUMENT.DMT_FINANCIAL_CHARGING%type;
    lnNbPosNoMvt        number;
  begin
    -- Recherche les informations permettant le contrôle du document
    begin
      select DMT.DMT_PROTECTED
           , DMT.C_DOCUMENT_STATUS
           , DMT.DMT_FINANCIAL_CHARGING
        into lnProtected
           , lvDocumentStatus
           , lnFinancialCharging
        from DOC_DOCUMENT DMT
       where DMT.DOC_DOCUMENT_ID = iDocumentID;
    exception
      when no_data_found then
        oErrorText  := 'PCS - no document defined';
    end;

    if (lvDocumentStatus = '04') then   -- Document est liquidé
      oErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Ce document est liquidé !');
    elsif(lvDocumentStatus = '05') then   -- Document est annulé
      oErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Ce document est annulé !');
    elsif(lnFinancialCharging = 1) then   -- Transfert en finance effectué
      oErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Document avec transfert en finance effectué !');
    else
      -- Recherche si toutes les positions du document ont généré des mouvements de stock
      select nvl(count(POS.DOC_POSITION_ID) - sum(POS.POS_GENERATE_MOVEMENT), 1)
        into lnNbPosNoMvt
        from DOC_POSITION POS
       where POS.DOC_DOCUMENT_ID = iDocumentID
         and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '71', '81', '91', '101')
         and POS.STM_MOVEMENT_KIND_ID is not null;

      if (lnNbPosNoMvt = 0) then   -- Tous les mouvement de stock sont déjà effectué
        oErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Tous les mouvements ont été générés sur ce document !');
      end if;
    end if;
  end ControlUpdateDocument;

  /**
  * procedure StartUpdateDocument
  * Description
  *   Méthode permettant la préparation du document en vue d'une modification éventuelle.
  */
  procedure StartUpdateDocument(
    inDocumentID in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , outErrorCode in out DOC_DOCUMENT.C_CONFIRM_FAIL_REASON%type
  , outErrorText in out DOC_DOCUMENT.DMT_ERROR_MESSAGE%type
  , iContext     in     varchar2 default 'DOC_UPDATE_QUANTITY'
  )
  is
    lModified        number;
    lChanged         number;
    unknownException integer;
    errMess          DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    backTrace        DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    dmtNumber        DOC_DOCUMENT.DMT_NUMBER%type;
  begin
    unknownException  := 1;
    savepoint start_update_document;

----
-- Contrôle de l'autorisation de modification du document par le workflow.
--
-- A réaliser
-- -------------------------------------------------------------------
    if (iContext = 'DOC_UPDATE_QUANTITY') then
      -- supression eventuel "arrondi Swisscom"
      DOC_DISCOUNT_CHARGE.removeDocumentRoundAmount(inDocumentID);
      ----
      -- Retrait du montant de correction d'arrondi TVA
      --
      outErrorCode  := '902';   -- Exception sur Retrait du montant de correction d'arrondi TVA
      DOC_PRC_VAT.RemoveVATCorrectionAmount(inDocumentID, 1, 1, lModified);
      ----
      -- Recalcul des tarifs par assortiment ainsi que les montants du pied de document suite au retrait de la correction d'arrondi
      --
      outErrorCode  := '912';   -- Exception sur Recalcul des tarifs par assortiment
      DOC_TARIFF_SET.DOCUpdatePriceForTariffSet(inDocumentID);
      outErrorCode  := '922';   -- Exception sur Recalcul des montants du pied de document
      DOC_FUNCTIONS.UpdateFootTotals(inDocumentID, lChanged);
      ----
      -- Supprime le montant de correction lorsque le montant monnaie document = 0 ET montant monnaie base <> 0
      --
      outErrorCode  := '932';   -- Exception sur Retrait du montant de correction
      DOC_FUNCTIONS.RemoveZeroAmmountCorrection(inDocumentID);
      ----
      -- Protection du document et retrait de la correction d'arrondi TVA.
      --
      outErrorCode  := '942';   -- Exception sur Protection du document et retrait de la correction d'arrondi TVA
      DocumentProtect(iDocumentID => inDocumentID, iProtect => 1, iSessionID => DBMS_SESSION.UNIQUE_SESSION_ID, iManageVAT => 1);
    else   -- DOC_UPDATE_FOOT_PAYMENT
      ----
      -- Protection du document et sans retrait de la correction d'arrondi TVA dans le cas d'une modification
      -- des modes de paiement du document
      --
      outErrorCode  := '941';   -- Exception sur Protection du document
      DocumentProtect(iDocumentID => inDocumentID, iProtect => 1, iSessionID => DBMS_SESSION.UNIQUE_SESSION_ID, iManageVAT => 0);
    end if;

    outErrorCode      := null;
    outErrorText      := null;
    unknownException  := 0;
  exception
    when others then
      -- Sauvegarde les informations de l'exception principale.
      errMess    := sqlerrm;
      backTrace  := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
      rollback to savepoint start_update_document;

      -- Construit le texte d'erreur uniquement si c'est une erreur inconnue. Sinon on obtient toujours
      -- le code d'erreur Oracle -20000 suivi du code d'erreur PCS.
      if (unknownException = 1) then
        addText(outErrorText, errMess || co.cLineBreak || backTrace);
      end if;

      begin
        select DMT.DMT_NUMBER
          into dmtNumber
          from DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = inDocumentID;
      exception
        when others then
          null;
      end;

      -- Inscription de l'événement dans l'historique des modifications
      DOC_FUNCTIONS.CreateHistoryInformation(inDocumentID
                                           , null
                                           , dmtNumber
                                           , 'PL/SQL'
                                           , 'EXCEPTION START UPDATE DOCUMENT'
                                           , 'Error Code : ' || outErrorCode || co.cLineBreak || errMess || co.cLineBreak || backTrace
                                           , null
                                           , null
                                            );
      raise;
  end StartUpdateDocument;

  /**
  * procedure PostUpdateDocument
  * Description
  *   Méthode permettant la validation du document après modification.
  */
  procedure PostUpdateDocument(
    inDocumentID in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , outErrorCode in out DOC_DOCUMENT.C_CONFIRM_FAIL_REASON%type
  , outErrorText in out DOC_DOCUMENT.DMT_ERROR_MESSAGE%type
  )
  is
    lReturnID number;
  begin
    ----
    -- Mise à jour du statut du document en fonction de l'état des positions.
    --
    DOC_FUNCTIONS.UpdateDocumentStatus(inDocumentID);
    ----
    -- Finalise le document courant. Mise à jour des totaux de document, des remises/taxes de pieds,
    -- de l'arrondi TVA et des échéances avant la libération (fin d'édition) du document
    --
    DOC_FINALIZE.FinalizeDocument(aDocumentID => inDocumentID, AExecExternProc => 0, AConfirm => 0);
  end PostUpdateDocument;

  /**
  * procedure UpdatePositionQtyUnitPrice
  * Description
  *   Méthode permettant la modification de la quantité et/ou du prix d'une position
  */
  procedure UpdatePositionQtyUnitPrice(
    inPositionID in     DOC_POSITION.DOC_POSITION_ID%type
  , inQuantity   in     DOC_POSITION.POS_BASIS_QUANTITY%type
  , inUnitPrice  in     DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , outErrorCode in out DOC_DOCUMENT.C_CONFIRM_FAIL_REASON%type
  , outErrorText in out DOC_DOCUMENT.DMT_ERROR_MESSAGE%type
  )
  is
    docDocumentID             DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    dmtNumber                 DOC_DOCUMENT.DMT_NUMBER%type;
    dmtProtected              DOC_DOCUMENT.DMT_PROTECTED%type;
    cGaugeTypePos             DOC_POSITION.C_GAUGE_TYPE_POS%type;
    docCPTPositionID          DOC_POSITION.DOC_DOC_POSITION_ID%type;
    pdeBasisQuantity          DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type;
    pdeIntermediateQuantity   DOC_POSITION_DETAIL.PDE_INTERMEDIATE_QUANTITY%type;
    pdeFinalQuantity          DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    pdeBasisQuantitySU        DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY_SU%type;
    pdeIntermediateQuantitySU DOC_POSITION_DETAIL.PDE_INTERMEDIATE_QUANTITY_SU%type;
    pdeFinalQuantitySU        DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type;
    pdeBalanceQuantity        DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type;
    sendPosition              DOC_POSITION%rowtype;
    receivedPosition          DOC_POSITION%rowtype;
    detailNumber              number;
    unknownException          integer;
    errMess                   DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    backTrace                 DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
  begin
    unknownException                   := 1;
    outErrorCode                       := null;   -- Aucune erreur par défaut.
    --
    savepoint update_position_qty_unit_price;

    -- Détermine le document qui doit être modifié en se basant sur la position
    begin
      select DMT.DOC_DOCUMENT_ID
           , DMT.DMT_NUMBER
           , DMT.DMT_PROTECTED
           , POS.C_GAUGE_TYPE_POS
           , POS.DOC_DOC_POSITION_ID
        into docDocumentID
           , dmtNumber
           , dmtProtected
           , cGaugeTypePos
           , docCPTPositionID
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
       where POS.DOC_POSITION_ID = inPositionID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID;
    exception
      when no_data_found then
        outErrorCode      := '000';   -- Document ou position inexistant
        unknownException  := 0;
        raise;
    end;

    begin
      if dmtProtected = 1 then
        -- Le document est en cours de modification (protégé)
        outErrorCode      := '001';
        unknownException  := 0;
        raise_application_error(-20000, 'PCS - protected document - update quantity and price not allowed in this context');
      end if;

      -- Vérification de la possibilité de modifier la quantité et le prix de la position
      select count(DOC_POSITION_DETAIL_ID)
        into detailNumber
        from DOC_POSITION_DETAIL
       where DOC_POSITION_ID = inPositionID;

      if detailNumber <> 1 then
        -- La modification de la quantité de la position est interdite si la position possède plusieurs détails de position.
        outErrorCode      := '011';
        unknownException  := 0;
        raise_application_error(-20000, 'PCS - several existing detail - update quantity and price not allowed in this context');
      end if;

      if    (docCPTPositionID is not null)
         or (to_number(cGaugeTypePos) > 6) then
        -- La modification de la quantité de la position est interdite pour les positions kit et assemblage et leurs composants.
        outErrorCode      := '021';
        unknownException  := 0;
        raise_application_error(-20000, 'PCS - component present - update quantity and price not allowed in this context');
      end if;
    exception
      when others then
        if outErrorCode is null then
          outErrorCode  := '901';   -- Erreur non controlée lors de la vérification de l'autorisation de modifier la position.
        end if;

        raise;
    end;

    -- Préparation du document pour permettre sa modification.
    begin
      StartUpdateDocument(docDocumentID, outErrorCode, outErrorText);
    exception
      when others then
        if outErrorCode is null then
          outErrorCode  := '992';   -- Erreur non controlée lors de la préparation du document.
        end if;

        raise;
    end;

    -- Inscription de l'événement dans l'historique des modifications
    DOC_FUNCTIONS.CreateHistoryInformation(docDocumentID, null, dmtNumber, 'PL/SQL', 'START UPDATE QUANTITY PRICE POSITION', null, null, null);
    ----
    -- Contrôle de l'autorisation de valider la position par le workflow
    --
    ----
    -- Mise à jour de la position en fonction de la nouvelle quantité et du nouveau prix.
    --
    -- Selon le principe suivant :
    --
    -- C'est uniquement par rapport à la présence d'une valeur dans le champ que l'on déclenche la mise à jour.
    --
    --   Exemple :
    --
    --     si sendPosition.POS_BASIS_QUANTITY <> null alors mise à jour de la position en fonction de la nouvelle quantité
    --     si sendPosition.POS_GROSS_UNIT_VALUE <> null alors mise à jour de la position en fonction du nouveau prix
    --
    sendPosition.DOC_POSITION_ID       := inPositionID;
    sendPosition.POS_BASIS_QUANTITY    := inQuantity;
    sendPosition.POS_GROSS_UNIT_VALUE  := inUnitPrice;

    begin
      DOC_PRC_POSITION.GetUpdatedFields(inSendPosition        => sendPosition
                                      , inUpdate              => 1
                                      , outReceivedPosition   => receivedPosition
                                      , outErrorCode          => outErrorCode
                                      , outErrorText          => outErrorText
                                       );
    exception
      when others then
        if outErrorCode is null then
          outErrorCode  := '904';
        end if;

        raise;
    end;

    ----
    -- Mise à jour des détails de la position
    --
    if outErrorCode is null then
      begin
        select POS_BASIS_QUANTITY
             , POS_INTERMEDIATE_QUANTITY
             , POS_FINAL_QUANTITY
             , POS_BASIS_QUANTITY_SU
             , POS_INTERMEDIATE_QUANTITY_SU
             , POS_FINAL_QUANTITY_SU
             , POS_BALANCE_QUANTITY
          into pdeBasisQuantity
             , pdeIntermediateQuantity
             , pdeFinalQuantity
             , pdeBasisQuantitySU
             , pdeIntermediateQuantitySU
             , pdeFinalQuantitySU
             , pdeBalanceQuantity
          from DOC_POSITION
         where DOC_POSITION_ID = inPositionID;

        update V_DOC_POSITION_DETAIL_IO
           set PDE_BASIS_QUANTITY = pdeBasisQuantity
             , PDE_INTERMEDIATE_QUANTITY = pdeIntermediateQuantity
             , PDE_FINAL_QUANTITY = pdeFinalQuantity
             , PDE_BASIS_QUANTITY_SU = pdeBasisQuantitySU
             , PDE_INTERMEDIATE_QUANTITY_SU = pdeBasisQuantitySU
             , PDE_FINAL_QUANTITY_SU = pdeBasisQuantitySU
             , PDE_BALANCE_QUANTITY = pdeBalanceQuantity
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSITION_ID = inPositionID;

        ----
        -- Mise à jour des prix des mouvements sur les détails de position d'une position
        DOC_FUNCTIONS.PosUpdateDetailMovementPrice(inPositionID);
      exception
        when others then
          if outErrorCode is null then
            outErrorCode  := '904';
          end if;

          raise;
      end;
    end if;

    ----
    -- Arrondi les montant de la position
    --

    ----
    -- Valide le document après modification
    --
    if outErrorCode is null then
      begin
        PostUpdateDocument(docDocumentID, outErrorCode, outErrorText);
      exception
        when others then
          if outErrorCode is null then
            outErrorCode  := '996';
          end if;

          raise;
      end;
    end if;

    if outErrorCode is null then
      -- Inscription de l'événement dans l'historique des modifications
      DOC_FUNCTIONS.CreateHistoryInformation(docDocumentID, null, dmtNumber, 'PL/SQL', 'UPDATE QUANTITY PRICE POSITION SUCCESSFUL COMPLETED', null, null, null);
    end if;
  exception
    when others then
      -- Sauvegarde les informations de l'exception principale.
      errMess    := sqlerrm;
      backTrace  := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
      rollback to savepoint update_position_qty_unit_price;

      -- Construit le texte d'erreur uniquement si c'est une erreur inconnue. Sinon on obtient toujours
      -- le code d'erreur Oracle -20000 suivi du code d'erreur PCS.
      if (unknownException = 1) then
        addText(outErrorText, errMess || co.cLineBreak || backTrace);
      end if;

      -- Inscription de l'événement dans l'historique des modifications
      DOC_FUNCTIONS.CreateHistoryInformation(docDocumentID
                                           , null
                                           , dmtNumber
                                           , 'PL/SQL'
                                           , 'EXCEPTION UPDATE QUANTITY PRICE POSITION'
                                           , 'Error Code : ' || outErrorCode || co.cLineBreak || errMess || chr(13) || backTrace
                                           , null
                                           , null
                                            );
  end UpdatePositionQtyUnitPrice;

  /* Protection ou déprotection du document */
  procedure DocumentProtect(
    iDocumentID number
  , iProtect    number
  , iSessionID  varchar2 default null
  , iListDescr  COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null
  , iManageVat  number default 0
  )
  is
    lAmountModified number(1);
  begin
    DOC_FUNCTIONS.CreateHistoryInformation(iDocumentId
                                         , null   -- DOC_POSITION_ID
                                         , null   -- no de document
                                         , 'PLSQL'   -- DUH_TYPE
                                         , 'Protect document'
                                         , 'Mode : ' || iProtect   -- description libre
                                         , null   -- status document
                                         , null   -- status position
                                          );

    -- gestion de la TVA
    if iManageVat = 1 then
      if iProtect = 1 then
        -- supression eventuel "arrondi Swisscom"
        DOC_DISCOUNT_CHARGE.removeDocumentRoundAmount(iDocumentId);
        -- retrait de l'arrondi TVA (il faut enlever la correction TVA car les remises
        -- de groupe peuvent modifier le montant TVA de la position)
        DOC_PRC_VAT.RemoveVatCorrectionAmount(iDocumentID, 1, 1, lAmountModified);
      else
        -- mise en place de l'arondi TVA
        DOC_PRC_VAT.AppendVatCorrectionAmount(iDocumentID, 1, 1, lAmountModified);
      end if;
    end if;

    declare
      lDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    begin
      -- teste si le document n'est pas déjà dans l'état que l'on demande
      select DOC_DOCUMENT_ID
        into lDocumentId
        from DOC_DOCUMENT
       where DOC_DOCUMENT_Id = iDocumentId
         and DMT_PROTECTED <> iProtect;

      /* Màj du flag de protection du document */
      update DOC_DOCUMENT
         set DMT_PROTECTED = iProtect
           , DMT_SESSION_ID = decode(iProtect, 1, iSessionID, null)
       where DOC_DOCUMENT_ID = iDocumentID;
    exception
      when no_data_found then
        null;
    end;

    if iProtect = 1 then
      /* Ajouter l'ID du document source à la liste des documents protégés */
      AddProtectedDocument(iDocumentID, iListDescr);
    else
      /* Enlever l'ID du document source à la liste des documents protégés */
      DelProtectedDocument(iDocumentID, iListDescr);
    end if;
  end DocumentProtect;

  /**
  * Description
  *    Protection ou déprotection du document dans une transaction autonome
  */
  procedure DocumentProtect_AutoTrans(
    iDocumentID     number
  , iProtect        number
  , iSessionID      varchar2 default null
  , iListDescr      COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null
  , iShowError      number default 1
  , iManageVat      number default 0
  , oUpdated    out number
  )
  is
    pragma autonomous_transaction;
    lDocumentId     DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lSessionId      DOC_DOCUMENT.DMT_SESSION_ID%type;
    lProtected      DOC_DOCUMENT.DMT_PROTECTED%type;
    lAmountModified number(1);
    lHedge          number(1);
  begin
    DOC_FUNCTIONS.CreateHistoryInformation(iDocumentId
                                         , null   -- DOC_POSITION_ID
                                         , null   -- no de document
                                         , 'PLSQL'   -- DUH_TYPE
                                         , 'Protect document autotrans'
                                         , 'Mode : ' || iProtect || ' / Vat : ' || iManageVat   -- description libre
                                         , null   -- status document
                                         , null   -- status position
                                          );

    if iProtect = 1 then
      -- teste si le document n'est pas déjà protégé par quelqu'un d'autre
      select DOC_DOCUMENT_ID
        into lDocumentId
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = iDocumentId
         and not(    DMT_SESSION_ID <> iSessionId
                 and DMT_PROTECTED = 1
                 and iProtect = 1);

      declare
        lDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
      begin
        -- teste si le document n'est pas déjà dans l'état que l'on demande
        select DOC_DOCUMENT_ID
          into lDocumentId
          from DOC_DOCUMENT
         where DOC_DOCUMENT_Id = iDocumentId
           and DMT_PROTECTED <> 1;

        /* Màj du flag de protection du document */
        update DOC_DOCUMENT
           set DMT_PROTECTED = 1
             , DMT_SESSION_ID = iSessionID
         where DOC_DOCUMENT_ID = iDocumentID;
      exception
        when no_data_found then
          null;
      end;

      if iManageVat = 1 then
        -- supression eventuel "arrondi Swisscom"
        DOC_DISCOUNT_CHARGE.removeDocumentRoundAmount(iDocumentId);
        -- retrait de l'arrondi TVA (il faut enlever la correction TVA car les remises
        -- de groupe peuvent modifier le montant TVA de la position)
        DOC_PRC_VAT.RemoveVatCorrectionAmount(iDocumentID, 1, 1, lAmountModified);
      end if;

      oUpdated  := 1;
    else
      -- teste si le document n'est pas déjà protégé par quelqu'un d'autre
      select DOC_DOCUMENT_ID
           , DMT_SESSION_ID
           , DMT_PROTECTED
           , sign(GAL_CURRENCY_RISK_VIRTUAL_ID)
        into lDocumentId
           , lSessionId
           , lProtected
           , lHedge
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = iDocumentId;

      if lSessionId = iSessionId then
        -- document protégé par la session en cours
        oUpdated  := 1;
      elsif     iSessionId is null
            and COM_FUNCTIONS.Is_Session_Alive(lSessionId) = 0 then
        -- déprotection manuelle (outil de déprotection) d'un document dont la session n'est pas vivante
        oUpdated  := 1;
      elsif     lProtected = 0
            and lSessionId is null then
        -- document déjà déprotégé
        oUpdated  := 0;
      else
        if iShowError = 1 then
          raise_application_error(-20000
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Vous essayez de déprotéger un document qui a été protégé par un autre utilisateur.')
                                 );
        else
          oUpdated  := 0;
        end if;
      end if;

      if oUpdated = 1 then
        if iManageVat = 1 then
          -- mise en place de l'arondi TVA
          DOC_PRC_VAT.AppendVatCorrectionAmount(iDocumentID, 1, 1, lAmountModified);
        end if;

        if lHedge = 1 then
          DOC_FUNCTIONS.UpdateBalanceTotal(iDocumentId);
        end if;

        /* Màj du flag de protection du document */
        update DOC_DOCUMENT
           set DMT_PROTECTED = 0
             , DMT_SESSION_ID = null
         where DOC_DOCUMENT_ID = iDocumentID;
      end if;
    end if;

    commit;   /* Car on utilise une transaction autonome */
  exception
    when no_data_found then
      if iShowError = 1 then
        if iProtect = 1 then
          raise_application_error(-20000
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Vous essayez de protéger un document qui est déjà protégé par un autre utilisateur.')
                                 );
        else
          raise_application_error(-20000
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Vous essayez de déprotéger un document qui a été protégé par un autre utilisateur.')
                                 );
        end if;
      else
        oUpdated  := 0;
      end if;
  end DocumentProtect_AutoTrans;

  /**
  * Description
  *    Protection ou déprotection du document dans une transaction autonome
  */
  procedure DocumentProtect_AutoTrans(
    iDocumentID number
  , iProtect    number
  , iSessionID  varchar2 default null
  , iListDescr  COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null
  , iShowError  number default 1
  )
  is
    lUpdated number(1);
  begin
    DocumentProtect_AutoTrans(iDocumentID, iProtect, iSessionID, iListDescr, iShowError, 0, lUpdated);
  end DocumentProtect_AutoTrans;

  /* Ajoute le document courant dans la liste des documents protègés */
  procedure AddProtectedDocument(iDocumentID number, iListDescr COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null)
  is
    bStop     boolean;
    comListID COM_LIST_ID_TEMP.COM_LIST_ID_TEMP_ID%type;
  begin
    bStop  := true;

    -- Garantit que le document courant n'est pas déjà dans la liste des documents protègé.
    begin
      select COM_LIST_ID_TEMP_ID
        into comListID
        from COM_LIST_ID_TEMP
       where COM_LIST_ID_TEMP_ID = iDocumentID
         and (   LID_FREE_CHAR_1 = iListDescr
              or iListDescr is null);
    exception
      when no_data_found then
        bStop  := false;
    end;

    if not bStop then
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_FREE_CHAR_1
                  )
           values (iDocumentID
                 , iListDescr
                  );
    end if;
  end AddProtectedDocument;

  /* Retire le document courant dans la liste des documents protègés */
  procedure DelProtectedDocument(iDocumentID number, iListDescr COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null)
  is
  begin
    /* Enlever l'ID du document source à la liste des documents protégés */
    delete from COM_LIST_ID_TEMP
          where COM_LIST_ID_TEMP_ID = iDocumentID
            and LID_FREE_CHAR_1 = iListDescr;
  end DelProtectedDocument;

  /**
  * Description
  *    Lancements d'OF depuis une commande de sous-traitance
  */
  procedure LaunchSubContractPBatches(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, oError out varchar2)
  is
    lvError varchar2(4000);
  begin
    for ltplPositionDetail in (select PDE.DOC_POSITION_DETAIL_ID
                                    , DMT.DMT_NUMBER
                                 from DOC_DOCUMENT DMT
                                    , DOC_POSITION POS
                                    , DOC_POSITION_DETAIL PDE
                                    , FAL_LOT LOT
                                where DMT.DOC_DOCUMENT_ID = iDocumentId
                                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                                  and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                                  and LOT.FAL_LOT_ID = PDE.FAL_LOT_ID
                                  and LOT.C_LOT_STATUS = FAL_I_LIB_BATCH.cLotStatusPlanified) loop
      FAL_PRC_SUBCONTRACTP.LaunchBatch(ltplPositionDetail.DOC_POSITION_DETAIL_ID, lvError);

      if lvError is not null then
        lvError  := PCS.PC_FUNCTIONS.TranslateWord('Le lancement du lot suivant est impossible : ') || ltplPositionDetail.DMT_NUMBER || co.cLineBreak
                    || lvError;
      end if;

      if lvError is not null then
        if oError is null then
          oError  := lvError;
        else
          oError  := oError || co.cLineBreak || lvError;
        end if;
      end if;
    end loop;
  end LaunchSubContractPBatches;

  /**
  * Description
  *    Réceptions d'OF depuis une commande de sous-traitance
  */
  procedure ReceiptSubContractPBatches(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, oError out varchar2)
  is
    lvError varchar2(4000);
  begin
    for ltplPositionDetail in (select PDE.DOC_POSITION_DETAIL_ID
                                    , DMT.DMT_NUMBER
                                    , LOT.C_LOT_STATUS
                                 from DOC_DOCUMENT DMT
                                    , DOC_POSITION POS
                                    , DOC_GAUGE_POSITION GAP
                                    , STM_MOVEMENT_KIND MOK
                                    , DOC_POSITION_DETAIL PDE
                                    , FAL_LOT LOT
                                where DMT.DOC_DOCUMENT_ID = iDocumentId
                                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                                  and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                                  and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
                                  and LOT.FAL_LOT_ID = PDE.FAL_LOT_ID
                                  and MOK.STM_MOVEMENT_KIND_ID = GAP.STM_MOVEMENT_KIND_ID
                                  and POS.C_DOC_POS_STATUS = '01'
                                  and MOK.MOK_BATCH_RECEIPT = 1) loop
      if ltplPositionDetail.C_LOT_STATUS = FAL_I_LIB_BATCH.cLotStatusLaunched then
        FAL_PRC_SUBCONTRACTP.ReceiptBatch(ltplPositionDetail.DOC_POSITION_DETAIL_ID, 0, lvError);
      elsif ltplPositionDetail.C_LOT_STATUS = FAL_I_LIB_BATCH.cLotStatusPlanified then
        lvError  := PCS.PC_FUNCTIONS.TranslateWord('La réception du lot suivant est impossible (lot au statut planifié) : ');
        lvError  := lvError || ltplPositionDetail.DMT_NUMBER;
      end if;

      if lvError is not null then
        if oError is null then
          oError  := lvError;
        else
          oError  := oError || co.cLineBreak || lvError;
        end if;
      end if;
    end loop;
  end ReceiptSubContractPBatches;

  /**
  * procedure CreateDocLink
  * Description
  *   Création d'un lien dans la table DOC_LINK
  */
  procedure CreateDocLink(
    iLinkType     in DOC_LINK.C_DOC_LINK_TYPE%type
  , iDocSourceID  in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , iPosSourceID  in DOC_POSITION.DOC_POSITION_ID%type default null
  , iPdeSourceID  in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  , iDocTargetID  in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , iPosTargetID  in DOC_POSITION.DOC_POSITION_ID%type default null
  , iPdeTargetID  in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  , iLotMatLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  )
  is
    ltDocLink FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocLink, ltDocLink);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocLink, 'C_DOC_LINK_TYPE', iLinkType);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocLink, 'DOC_DMT_SOURCE_ID', iDocSourceID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocLink, 'DOC_POS_SOURCE_ID', iPosSourceID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocLink, 'DOC_PDE_SOURCE_ID', iPdeSourceID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocLink, 'DOC_DMT_TARGET_ID', iDocTargetID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocLink, 'DOC_POS_TARGET_ID', iPosTargetID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocLink, 'DOC_PDE_TARGET_ID', iPdeTargetID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocLink, 'FAL_LOT_MATERIAL_LINK_ID', iLotMatLinkID);
    FWK_I_MGT_ENTITY.InsertEntity(ltDocLink);
    FWK_I_MGT_ENTITY.Release(ltDocLink);
  end CreateDocLink;

  /**
  * procedure DeleteFreeNumber
  * Description
  *   Effacement d'un n° de document dans la table DOC_FREE_NUMBER
  */
  procedure DeleteFreeNumber(iDmtNumber in DOC_DOCUMENT.DMT_NUMBER%type)
  is
    pragma autonomous_transaction;
  begin
    delete from DOC_FREE_NUMBER
          where DOF_NUMBER = iDmtNumber;

    commit;
  end DeleteFreeNumber;

  /**
  * procedure DeleteMissingNumber
  * Description
  *   Effacement d'un n° de document dans la table DOC_MISSING_NUMBER
  */
  procedure DeleteMissingNumber(iDmtNumber in DOC_DOCUMENT.DMT_NUMBER%type)
  is
    pragma autonomous_transaction;
  begin
    delete from DOC_MISSING_NUMBER
          where DMN_NUMBER = iDmtNumber;

    commit;
  end DeleteMissingNumber;

  /**
  * Description : mise à jour du status d'un document
  */
  procedure UpdateDocumentStatus(
    iDocumentId           in number
  , iCancelDocument       in number default 0
  , iIsOnlyAmountBillBook in DOC_DOCUMENT.DMT_ONLY_AMOUNT_BILL_BOOK%type default 0
  , iConfirmation         in number default 0
  )
  is
    lPosCount         number;
    lPosCountStatus01 number;
    lPosCountStatus02 number;
    lPosCountStatus03 number;
    lPosCountStatus04 number;
    lPosCountStatus05 number;
    lConfirmStatus    DOC_GAUGE.GAU_CONFIRM_STATUS%type;
    lBalanceStatus    DOC_GAUGE_STRUCTURED.GAS_BALANCE_STATUS%type;
    lOldDocStatus     DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    lNewDocStatus     DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
  begin
    -- Sauvegarde le statut actuel du document
    -- recherche du status par défaut selon le gabarit
    select GAU.GAU_CONFIRM_STATUS
         , nvl(GAS.GAS_BALANCE_STATUS, 0)
         , DMT.C_DOCUMENT_STATUS
      into lConfirmStatus
         , lBalanceStatus
         , lOldDocStatus
      from DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
         , DOC_DOCUMENT DMT
     where DOC_DOCUMENT_ID = iDocumentId
       and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID;

    -- Copier le statut dans la var pour qu'à la fin on ne fasse la màj que s'il y a une diff.
    lNewDocStatus  := lOldDocStatus;

    -- Recherche le statut des positions
    select count(DOC_POSITION_ID) POS_COUNT
         , sum(decode(C_DOC_POS_STATUS, '01', 1, 0) ) STATUS_01
         , sum(decode(C_DOC_POS_STATUS, '02', 1, 0) ) STATUS_02
         , sum(decode(C_DOC_POS_STATUS, '03', 1, 0) ) STATUS_03
         , sum(decode(C_DOC_POS_STATUS, '04', 1, 0) ) STATUS_04
         , sum(decode(C_DOC_POS_STATUS, '05', 1, 0) ) STATUS_05
      into lPosCount
         , lPosCountStatus01
         , lPosCountStatus02
         , lPosCountStatus03
         , lPosCountStatus04
         , lPosCountStatus05
      from DOC_POSITION
     where DOC_DOCUMENT_ID = iDocumentId
       and C_GAUGE_TYPE_POS not in('4', '5', '6');

    if lPosCount > 0 then
      -- Toutes les positions sont au statut Annulé
      if lPosCount = lPosCountStatus05 then
        -- Le document devient Annulé
        lNewDocStatus  := '05';
      -- Toutes les positions sont au statut Liquidé (Ne pas tenir compte des positions annulées)
      elsif lPosCount =(lPosCountStatus04 + lPosCountStatus05) then
        -- Normalement le document devient "Liquidé", mais il y a une exception pour les document portant un
        -- échéanciers si la facture finale n'a pas encore été générée ou que le document n'est pas totallement déchargé, on ne solde pas le document DEVLOG-16555
        if     FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'DMT_INVOICE_EXPIRY', iDocumentId) = 1
           and (   not DOC_INVOICE_EXPIRY_FUNCTIONS.IsFinalInvoiceGenerated(iDocumentId)
                or not DOC_LIB_DOCUMENT.IsDocumentTotallyDischarged(iDocumentId) ) then
          lNewDocStatus  := '03';
        else
          lNewDocStatus  := '04';
        end if;
      -- Toutes les positions sont au statut A solder (Ne pas tenir compte des positions annulées)
      elsif lPosCount =(lPosCountStatus02 + lPosCountStatus05) then
        -- Le document devient A solder
        lNewDocStatus  := '02';
      -- Toutes les positions sont au statut A confirmer (Ne pas tenir compte des positions annulées)
      elsif lPosCount =(lPosCountStatus01 + lPosCountStatus05) then
        -- Le document devient A confirmer
        lNewDocStatus  := '01';
      else
        -- Le document devient Soldé partiellement
        lNewDocStatus  := '03';
      end if;
    elsif nvl(iCancelDocument, 0) = 1 then
      -- Document sans positions bien mais lors d'une demande d'annulation
      -- Le document devient Annulé
      lNewDocStatus  := '05';
    else
      -- Document sans positions bien
      if (lConfirmStatus = 1) and (iConfirmation = 0) then
        -- Le document devient à confirmer (Si pas en mode confirmation du document)
        lNewDocStatus  := '01';
      elsif lBalanceStatus = 1 then
        -- Le document devient A solder
        lNewDocStatus  := '02';
      else
        -- Le document devient Liquidé
        lNewDocStatus  := '04';
      end if;
    end if;

    -- Effectuer la màj du statut du document s'il y a un changement
    -- ne pas permettre de passer au statut "à confirmer" si le document était dans un statut supérieur à '01'
    if     (lOldDocStatus <> lNewDocStatus)
       and not(    lNewDocStatus = '01'
               and lOldDocStatus != '01') then
      update DOC_DOCUMENT
         set C_DOCUMENT_STATUS = lNewDocStatus
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_DOCUMENT_ID = iDocumentId;
    end if;
  end UpdateDocumentStatus;

  /**
  * Description
  *    Mise à jour des statuts documents et position à la confirmation
  */
  procedure ConfirmStatus(
    iDocumentId           in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iBalanceStatus        in DOC_GAUGE_STRUCTURED.GAS_BALANCE_STATUS%type
  , iControlExpiryLink    in DOC_GAUGE_STRUCTURED.GAS_CHECK_INVOICE_EXPIRY_LINK%type default 0
  , iIsOnlyAmountBillBook in DOC_DOCUMENT.DMT_ONLY_AMOUNT_BILL_BOOK%type default 0
  )
  is
    lToConfirm boolean                              := false;
    lFinished  boolean                              := false;
    lNewStatus DOC_POSITION.C_DOC_POS_STATUS%type;
  begin
    -- mise à jour du status de chaque position
    for ltplPositions in (select DOC_POSITION_ID
                            from DOC_POSITION
                           where DOC_DOCUMENT_ID = iDocumentId
                             and C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21', '71', '81', '91', '101') ) loop
      -- si le gabarit ne fait pas de contrôle des liens avec l'échéancier
      if iControlExpiryLink = 0 then
        if iBalanceStatus = 0 then
          -- Mise à jour du status selon le flag de gestion du statut  "à solder"
          DOC_POSITION_FUNCTIONS.BalancePosition(ltplPositions.DOC_POSITION_ID);
        else
          -- Mise à jour du status selon le flag de gestion du statut  "à solder"
          update    DOC_POSITION
                set C_DOC_POS_STATUS = '02'
              where DOC_POSITION_ID = ltplPositions.DOC_POSITION_ID;
        end if;
      else   -- si le gabarit contrôle les liens avec l'échéancier
        -- si la position est issue d'un ancètre avec échéancier
        if DOC_INVOICE_EXPIRY_FUNCTIONS.ExpiryForcePosBalance(ltplPositions.DOC_POSITION_ID) or iBalanceStatus = 0 then
          -- On force le statut à "liquidé"
          DOC_POSITION_FUNCTIONS.BalancePosition(ltplPositions.DOC_POSITION_ID);
        elsif iBalanceStatus = 1 then
          -- Mise à jour du status selon le flag de gestion du statut  "à solder"
          update    DOC_POSITION
                set C_DOC_POS_STATUS = '02'
              where DOC_POSITION_ID = ltplPositions.DOC_POSITION_ID;
        end if;
      end if;
    end loop;

    UpdateDocumentStatus(iDocumentId => iDocumentId, iIsOnlyAmountBillBook => iIsOnlyAmountBillBook, iConfirmation => 1);
  end ConfirmStatus;

  procedure SetCurrRiskVirtualId(
    iDocumentId           in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iGalCurrRiskVirtualId in GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , iRateOfExchange       in GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type
  , iBasePrice            in GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type
  , iCurrRateCoverType    in DOC_DOCUMENT.C_CURR_RATE_COVER_TYPE%type
  , iCurrRiskForced       in DOC_DOCUMENT.DMT_CURR_RISK_FORCED%type default 0
  )
  is
    ltComp     FWK_I_TYP_DEFINITION.t_crud_def;
    lvRateType varchar2(1);
  begin
    lvRateType  := '1';
    --Maj table DOC_DOCUMENT
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcDocDocument, iot_crud_definition => ltComp, in_main_id => iDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'GAL_CURRENCY_RISK_VIRTUAL_ID', iGalCurrRiskVirtualId);

    if iGalCurrRiskVirtualId is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DMT_CURR_RATE_FORCED', 0);
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DMT_CURR_RATE_FORCED', 1);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'C_CURR_RATE_COVER_TYPE', iCurrRateCoverType);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DMT_RATE_OF_EXCHANGE', iRateOfExchange);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DMT_BASE_PRICE', iBasePrice);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DMT_CURR_RISK_FORCED', iCurrRiskForced);

    -- Forcer le cours de change TVA
    if     iCurrRateCoverType in('01', '02', '03', '04')
       and iGalCurrRiskVirtualId <> 0 then
      lvRateType  := '0';
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DMT_VAT_EXCHANGE_RATE', iRateOfExchange);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DMT_VAT_BASE_PRICE', iBasePrice);
    end if;

    FWK_I_MGT_ENTITY.UpdateEntity(ltComp);
    FWK_I_MGT_ENTITY.Release(ltComp);
    -- Maj table DOC_FOOT
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcDocFoot, iot_crud_definition => ltComp, in_main_id => iDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'GAL_CURRENCY_RISK_VIRTUAL_ID', iGalCurrRiskVirtualId);
    FWK_I_MGT_ENTITY.UpdateEntity(ltComp);
    FWK_I_MGT_ENTITY.Release(ltComp);
    -- Recalcul des montants en monnaie de base
    DOC_DOCUMENT_FUNCTIONS.changeDocumentCurrRate(aDocumentId     => iDocumentId
                                                , aNewCurrRate    => iRateOfExchange
                                                , aNewBasePrice   => iBasePrice
                                                , aRateType       => lvRateType
                                                , aFinalizeDoc    => false
                                                 );
  end SetCurrRiskVirtualId;

  /**
  * procedure DocCurrRiskNotManaged
  * Description
  *    Forcer à non géré les infos liées au risque de change d'un document
  */
  procedure DocCurrRiskNotManaged(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    ltEntity FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    --Maj table DOC_DOCUMENT
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcDocDocument, iot_crud_definition => ltEntity, in_main_id => iDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltEntity, 'GAL_CURRENCY_RISK_VIRTUAL_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEntity, 'DMT_CURR_RATE_FORCED', 0);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEntity, 'C_CURR_RATE_COVER_TYPE', '00');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEntity, 'DMT_CURR_RISK_FORCED', 0);
    FWK_I_MGT_ENTITY.UpdateEntity(ltEntity);
    FWK_I_MGT_ENTITY.Release(ltEntity);
    -- Maj table DOC_FOOT
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcDocFoot, iot_crud_definition => ltEntity, in_main_id => iDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltEntity, 'GAL_CURRENCY_RISK_VIRTUAL_ID');
    FWK_I_MGT_ENTITY.UpdateEntity(ltEntity);
    FWK_I_MGT_ENTITY.Release(ltEntity);
  end DocCurrRiskNotManaged;

  /**
      * procedure InheritCurrRiskVirtuallFor4_5_6MC
      * Description
      *   Recherche et assigne la tranche virtuelle à un document en reprenant celle de la dernière trabnche utilisé cas des NC 4 5 6 sur échéancier de type multi couverts
      */
  procedure InheritCurrRiskVirtual4_5_6MC(
    iDocumentIdParent in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iDocumentId       in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , oErrorCode        out    number
  )
  is
    lvRiskType       GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type;
    lnRiskId         GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lnRateOfExchange GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type;
    lnBasePrice      GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type;
    lnCurrRiskForced number(1)                                                     := 0;
  begin
    begin
      select DMT.GAL_CURRENCY_RISK_VIRTUAL_ID
           , DMT.C_CURR_RATE_COVER_TYPE
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , DMT.DMT_CURR_RISK_FORCED
        into lnRiskId
           , lvRiskType
           , lnRateOfExchange
           , lnBasePrice
           , lnCurrRiskForced
        from DOC_DOCUMENT DMT
       where DMT.DOC_DOCUMENT_ID = iDocumentIdParent;
    exception
      when no_data_found then
        oErrorCode  := 1;
    end;

    if lnRiskId is null then
      oErrorCode  := 1;
    end if;

    if nvl(oErrorCode, 0) = 0 then
      SetCurrRiskVirtualId(iDocumentId             => iDocumentId
                         , iGalCurrRiskVirtualId   => lnRiskId
                         , iRateOfExchange         => lnRateOfExchange
                         , iBasePrice              => lnBasePrice
                         , iCurrRateCoverType      => lvRiskType
                         , iCurrRiskForced         => lnCurrRiskForced
                          );
    end if;
  end InheritCurrRiskVirtual4_5_6MC;

  /**
  * procedure AssignCurrRiskVirtual
  * Description
  *   Recherche et assigne la tranche virtuelle à un document
  */
  procedure AssignCurrRiskVirtual(
    iDocumentId        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , oCurrRiskVirtualID out    GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , oErrorCode         out    number
  , iInitTranche       in     number default 0
  )
  is
    lProjectID        GAL_PROJECT.GAL_PROJECT_ID%type;
    lvRiskType        GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type;
    lnRateOfExchange  GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type;
    lnBasePrice       GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type;
    lDocumentIDParent DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    oCurrRiskVirtualID  := null;
    oErrorCode          := null;

    for ltplDocument in (select DMT.GAL_CURRENCY_RISK_VIRTUAL_ID
                              , DMT.ACS_FINANCIAL_CURRENCY_ID
                              , DMT.DOC_DOCUMENT_ID
                              , decode(GAU.C_ADMIN_DOMAIN, '1', '1', '2', '2') C_GAL_RISK_DOMAIN
                              , FOO.FOO_DOCUMENT_TOTAL_AMOUNT
                              , FOO_GOOD_TOTAL_AMOUNT
                           from DOC_DOCUMENT DMT
                              , DOC_GAUGE GAU
                              , DOC_FOOT FOO
                          where DMT.DOC_DOCUMENT_ID = iDocumentId
                            and FOO.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
                            and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID) loop
      if ltplDocument.GAL_CURRENCY_RISK_VIRTUAL_ID is null then
        if ltplDocument.FOO_GOOD_TOTAL_AMOUNT <> 0 then
          -- Recherche de la tranche virtuelle
          if iInitTranche = 1 then
            if DOC_INVOICE_EXPIRY_FUNCTIONS.GetInvoiceExpiryDocType(iDocumentId) in('4', '6') then
              lDocumentIDParent  := DOC_INVOICE_EXPIRY_FUNCTIONS.GetLastRiskVirtualFor4_5_6MC(iDocumentId => iDocumentID, iType => 2);
            else
              lDocumentIDParent  := DOC_INVOICE_EXPIRY_FUNCTIONS.GetLastRiskVirtualFor4_5_6MC(iDocumentId => iDocumentID, iType => 1);
            end if;

            InheritCurrRiskVirtual4_5_6MC(lDocumentIDParent, iDocumentId, oErrorCode);
          else
            GAL_I_LIB_PROJECT.GetLogisticCurrRiskData(iDocumentID   => ltplDocument.DOC_DOCUMENT_ID
                                                    , iAmount       => ltplDocument.FOO_DOCUMENT_TOTAL_AMOUNT
                                                    , oRiskId       => oCurrRiskVirtualID
                                                    , oRiskType     => lvRiskType
                                                    , oRiskRate     => lnRateOfExchange
                                                    , oRiskBase     => lnBasePrice
                                                    , oErrorCode    => oErrorCode
                                                     );
          end if;

          -- Code d'erreur de la recherche de la tranche virtuelle
          --   0 = pas d'erreur
          --   1 = pas de tranche virtuelle pour la monnaie demandée
          --   2 = pas de couverture du montant du document

          -- 0 = Pas d'erreur -> montant du doc couvert par une tranche
          if (oErrorCode = 0) then
            SetCurrRiskVirtualId(iDocumentId             => iDocumentId
                               , iGalCurrRiskVirtualId   => oCurrRiskVirtualID
                               , iRateOfExchange         => lnRateOfExchange
                               , iBasePrice              => lnBasePrice
                               , iCurrRateCoverType      => lvRiskType
                                );
          elsif(oErrorCode = 1) then
            -- 1 = pas de tranche virtuelle pour la monnaie demandée -> Risque de change pas géré
            DocCurrRiskNotManaged(iDocumentID => iDocumentID);
          else
            -- pas de couverture du montant du document
            oCurrRiskVirtualID  := null;
          end if;
        end if;
      end if;
    end loop;
  end AssignCurrRiskVirtual;

  /**
  * procedure AssignCurrRiskVirtual
  * Description
  *   Recherche et assigne la tranche virtuelle à un document
  */
  procedure InheritCurrRiskVirtual(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lProjectID       GAL_PROJECT.GAL_PROJECT_ID%type;
    lvRiskType       GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type;
    lnRiskId         GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lnRateOfExchange GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type;
    lnBasePrice      GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type;
    lvErrorCode      number(1)                                                     := 0;
    lnCurrRiskForced number(1)                                                     := 0;
  begin
    for ltplDocument in (select DMT.GAL_CURRENCY_RISK_VIRTUAL_ID
                           from DOC_DOCUMENT DMT
                          where DMT.DOC_DOCUMENT_ID = iDocumentId) loop
      if ltplDocument.GAL_CURRENCY_RISK_VIRTUAL_ID is null then
        -- Document issu d'un échéancier, reprise des infos de tranche sur le document d'origine de l'échéancier
        DOC_INVOICE_EXPIRY_FUNCTIONS.GetRootDocCurrRiskData(iDocumentID   => iDocumentId
                                                          , oRiskId       => lnRiskId
                                                          , oRiskType     => lvRiskType
                                                          , oRiskRate     => lnRateOfExchange
                                                          , oRiskBase     => lnBasePrice
                                                          , oRiskForced   => lnCurrRiskForced
                                                          , oErrorCode    => lvErrorCode
                                                           );

        if (lvErrorCode = 2) then
          ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur lors de la reprise de la monnaie du document parent.') );
        else
          SetCurrRiskVirtualId(iDocumentId             => iDocumentId
                             , iGalCurrRiskVirtualId   => lnRiskId
                             , iRateOfExchange         => lnRateOfExchange
                             , iBasePrice              => lnBasePrice
                             , iCurrRateCoverType      => lvRiskType
                             , iCurrRiskForced         => lnCurrRiskForced
                              );
        end if;
      end if;
    end loop;
  end InheritCurrRiskVirtual;

  /**
    * procedure InheritExchangeRate
    * Description: Pour le mode Gestion du taux de couverture et si document non couvert selon la valeur de la config gcDOC_CURRENCY_FORCE_EXP_RATE et si on transfert le cours les documents reprennent ce taux même si on change la date de document
    *
    */
  procedure InheritExchangeRate(
    iDocumentId        in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iDocGaugeReceiptId in Doc_GAUGE_COPY.DOC_GAUGE_COPY_ID%type
  , IDocGaugeCopyId    in Doc_GAUGE_COPY.DOC_GAUGE_COPY_ID%type
  , iIsAddendum        in number
  )
  is
    lProjectID            GAL_PROJECT.GAL_PROJECT_ID%type;
    lvRiskType            GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type;
    lnRiskId              GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lnRateOfExchange      GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type;
    lnBasePrice           GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type;
    lvErrorCode           number(1)                                                     := 0;
    lnCurrRiskForced      number(1)                                                     := 0;
    lCountDocFatherExpiry number(3)                                                     := 0;
    lnTransfertRate       DOC_GAUGE_COPY.GAC_TRANSFERT_CURR_RATE%type;
    lnRecalRate           boolean                                                       := false;
  begin
    -- avanenant
    if iIsAddendum = 1 then
      lnRecalRate  := true;
    end if;

    -- document généré par un échéancier, Acompe, NC. Facture part et finale
    if not lnRecalRate then
      select count(doc.doc_invoice_expiry_id) + count(pos.doc_invoice_expiry_id)
        into lCountDocFatherExpiry
        from doc_document doc
           , doc_position pos
       where pos.doc_document_id = doc.doc_document_id
         and doc.doc_document_id = iDocumentId;

      if lCountDocFatherExpiry > 0 then
        lnRecalRate  := true;
      end if;
    end if;

    --document issus d'une copie et flag de transfert dans le flux à Oui
    if     IDocGaugeCopyId is not null
       and not lnRecalRate then
      select nvl(max(GAC_TRANSFERT_CURR_RATE), 0)
        into lnTransfertRate
        from DOC_GAUGE_COPY
       where DOC_GAUGE_COPY_ID = IDocGaugeCopyId;

      if lnTransfertRate <> 0 then
        lnRecalRate  := true;
      end if;
    end if;

    --document issus d'une décharge et flag de transfert dans le flux à Oui
    if     iDocGaugeReceiptId is not null
       and not lnRecalRate then
      select nvl(max(GAR_TRANSFERT_CURR_RATE), 0)
        into lnTransfertRate
        from DOC_GAUGE_RECEIPT
       where DOC_GAUGE_RECEIPT_ID = iDocGaugeReceiptId;

      if lnTransfertRate <> 0 then
        lnRecalRate  := true;
      end if;
    end if;

    if lnRecalRate then
      DOC_INVOICE_EXPIRY_FUNCTIONS.GetRootDocCurrRiskData(iDocumentID   => iDocumentId
                                                        , oRiskId       => lnRiskId
                                                        , oRiskType     => lvRiskType
                                                        , oRiskRate     => lnRateOfExchange
                                                        , oRiskBase     => lnBasePrice
                                                        , oRiskForced   => lnCurrRiskForced
                                                        , oErrorCode    => lvErrorCode
                                                         );

      if (lvErrorCode = 2) then
        ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur lors de la reprise de la monnaie du document parent.') );
      elsif lvErrorCode = 3 then
        SetCurrRiskVirtualId(iDocumentId             => iDocumentId
                           , iGalCurrRiskVirtualId   => lnRiskId
                           , iRateOfExchange         => lnRateOfExchange
                           , iBasePrice              => lnBasePrice
                           , iCurrRateCoverType      => lvRiskType
                           , iCurrRiskForced         => lnCurrRiskForced
                            );
      end if;
    end if;
  end InheritExchangeRate;

  /**
  * procedure CtrlDocumentCurrencyRisk
  * Description
  *   Contrôles sur le document par rapport au risque de change
  */
  procedure CtrlDocumentCurrencyRisk(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, oErrorCode out varchar2)
  is
    cursor lcrDoc(cDocumentID number)
    is
      select DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.GAL_CURRENCY_RISK_VIRTUAL_ID
           , DMT.C_CURR_RATE_COVER_TYPE
           , GAS.GAS_CURR_RATE_FORCED
           , sign(instr(';' || gcGAL_GAUGE_BALANCE_ORDER || ';', ';' || GAU.GAU_DESCRIBE || ';') ) as IS_GAUGE_BALANCE_ORDER
           , case
               when PCO.C_PAYMENT_CONDITION_KIND = '02' then 1
               else 0
             end IS_PAY_COND_INV_EXPIRY
           , GCK.GAL_PROJECT_ID as PROJECT_RISK_ID
           , case
               when DMT.C_DOC_CREATE_MODE = '215' then 1
               else 0
             end IS_ADDENDUM
           , DMT.DMT_CURR_RISK_FORCED
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , GAL_CURRENCY_RISK_VIRTUAL GCK
           , PAC_PAYMENT_CONDITION PCO
       where DMT.DOC_DOCUMENT_ID = cDocumentID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and DMT.GAL_CURRENCY_RISK_VIRTUAL_ID = GCK.GAL_CURRENCY_RISK_VIRTUAL_ID(+)
         and DMT.PAC_PAYMENT_CONDITION_ID = PCO.PAC_PAYMENT_CONDITION_ID(+);

    cursor lcrDocSrcInfo(cDocumentID number)
    is
      select   GAS_SRC.GAS_CURR_RATE_FORCED
             , DMT_SRC.ACS_FINANCIAL_CURRENCY_ID
             , DMT_SRC.GAL_CURRENCY_RISK_VIRTUAL_ID
             , DMT_SRC.DMT_RATE_OF_EXCHANGE
             , DMT_SRC.DMT_BASE_PRICE
             , DMT_SRC.C_CURR_RATE_COVER_TYPE
             , DMT_SRC.DMT_CURR_RISK_FORCED
             , case
                 when PDE.DOC_GAUGE_RECEIPT_ID is not null then 1
                 else 0
               end as DOC_DISCHARGE
             , case
                 when PDE.DOC_GAUGE_COPY_ID is not null then 1
                 else 0
               end as DOC_COPY
             , PDE.DOC_GAUGE_COPY_ID
             , PDE.DOC_GAUGE_RECEIPT_ID
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , DOC_GAUGE_STRUCTURED GAS_SRC
             , DOC_DOCUMENT DMT_SRC
             , DOC_POSITION POS_SRC
             , DOC_POSITION_DETAIL PDE_SRC
         where DMT.DOC_DOCUMENT_ID = iDocumentID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and nvl(PDE.DOC_DOC_POSITION_DETAIL_ID, PDE.DOC2_DOC_POSITION_DETAIL_ID) = PDE_SRC.DOC_POSITION_DETAIL_ID
           and POS_SRC.DOC_POSITION_ID = PDE_SRC.DOC_POSITION_ID
           and DMT_SRC.DOC_DOCUMENT_ID = POS_SRC.DOC_DOCUMENT_ID
           and DMT_SRC.DOC_GAUGE_ID = GAS_SRC.DOC_GAUGE_ID
      order by POS.POS_NUMBER asc
             , PDE.DOC_POSITION_DETAIL_ID asc
             , PDE.DOC2_DOC_POSITION_DETAIL_ID asc nulls last;

    ltplDoc                  lcrDoc%rowtype;
    ltplDocSrcInfo           lcrDocSrcInfo%rowtype;
    lnProjectRiskManag       number(1);
    lnProjectCount           integer;
    lnCount                  integer;
    lCurrRiskVirtualID       DOC_DOCUMENT.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lSrcDocCurrRiskVirtualID DOC_DOCUMENT.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lCurrencyID              ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lDocumentSrcID           DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lbRateForced             boolean;
    lbInitializeRate         boolean;
    lnTransfertRate          DOC_GAUGE_COPY.GAC_TRANSFERT_CURR_RATE%type;
    lnErrorCode              number(1);
    lRiskProjectID           GAL_PROJECT.GAL_PROJECT_ID%type;
    lnCurrRiskForced         DOC_DOCUMENT.DMT_CURR_RISK_FORCED%type;
  begin
    oErrorCode  := null;

    -- Contrôles liés au risque du cours de change PRP
    -- Seuls les documents non-issus d'un échéancier sont pris en compte (sauf les NC sur contrat) (DEVLOG-16582 règle 3720)
    if gcCOM_CURRENCY_RISK_MANAGE then
      open lcrDoc(iDocumentID);

      fetch lcrDoc
       into ltplDoc;

      if not DOC_INVOICE_EXPIRY_FUNCTIONS.IsBillBookChild(iDocumentID => iDocumentID) then
        -- Contrôles sur le risque de change uniquement si pas en monnaie de société
        if ltplDoc.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyID then
          -- Ctrl si le document est lié à une affaire avec risque de change
          -- Ctrl le nbre d'affaire liées au document
          DOC_LIB_DOCUMENT.CtrlProjectRisk(iDocumentID         => iDocumentID
                                         , oProjectID          => lRiskProjectID
                                         , oProjectRiskManag   => lnProjectRiskManag
                                         , oProjectCount       => lnProjectCount
                                          );

          if     lnProjectCount = 0
             and lRiskProjectID is null
             and gcDOC_CURRENCY_FORCE_EXP_RATE = 1 then
            open lcrDocSrcInfo(iDocumentID);

            fetch lcrDocSrcInfo
             into ltplDocSrcInfo;

            InheritExchangeRate(iDocumentId          => iDocumentID
                              , iDocGaugeReceiptId   => ltplDocSrcInfo.DOC_GAUGE_RECEIPT_ID
                              , iDocGaugeCopyId      => ltplDocSrcInfo.DOC_GAUGE_COPY_ID
                              , iIsAddendum          => ltplDoc.IS_ADDENDUM
                               );

            close lcrDocSrcInfo;
          end if;

          -- Si le document possède une tranche virtuelle
          --   vérifier que celle-ci correspond à l'affaire du risque de change (ex. suite au changement ou effacement du dossier sur la position)
          if     (ltplDoc.GAL_CURRENCY_RISK_VIRTUAL_ID is not null)
             and (    (lnProjectRiskManag = 0)
                  or (     (lnProjectCount = 1)
                      and (ltplDoc.PROJECT_RISK_ID <> lRiskProjectID) ) ) then
            -- Si ce n'est pas la même affaire (ex. changement de dossier) effacer la tranche virtuelle
            --  pour procèder à une nouvelle initialisation de la tranche
            DOC_PRC_DOCUMENT.DocCurrRiskNotManaged(iDocumentId => iDocumentID);
            -- Vider l'id de la tranche virtuelle du curseur, car c'est ce que la méthode ci-dessus à fait
            ltplDoc.GAL_CURRENCY_RISK_VIRTUAL_ID  := null;
            ltplDoc.PROJECT_RISK_ID               := null;
          end if;

          -- Lien avec une affaire avec gestion du risque de change
          if (lnProjectRiskManag = 1) then
            -- Lien sur plusieurs affaires
            if (lnProjectCount > 1) then
              oErrorCode  := '130';
            -- Gabarit document dans la config GAL_GAUGE_BALANCE_ORDER  et
            --  pas de cond. de paiement avec échéancier définie et
            --  Document de vente en multi couverture
            elsif     (ltplDoc.IS_GAUGE_BALANCE_ORDER = 1)
                  and (ltplDoc.IS_PAY_COND_INV_EXPIRY = 0)
                  and (DOC_LIB_DOCUMENT.IsDocCurrRiskSaleMultiCover(iDocumentID) = 1) then
              oErrorCode  := '134';
            else
              -- Document d'origine ou facture issue d'un échéancier en mode multi couverture
              if    DOC_LIB_DOCUMENT.IsOriginalDocument(iDocumentID) = 1
                 or FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_DOCUMENT', 'DOC_INVOICE_EXPIRY_ID', iDocumentId) is not null then
                -- Cours forcé
                if ltplDoc.GAS_CURR_RATE_FORCED = 1 then
                  -- Pas encore de tranche virtuelle définie
                  if ltplDoc.GAL_CURRENCY_RISK_VIRTUAL_ID is null then
                    -- En Config Multi-couverture, les Notes de crédit isssues de l'échéancier n'obtiennent jamais une tranche virtuelle en automatique
                    --   On bloque le document et c'est à l'utilisateur d'aller forcer une trance manuellement
                    if     (PCS.PC_CONFIG.GetBooleanConfig('GAL_CUR_SALE_MULTI_COVER') )
                       and (DOC_INVOICE_EXPIRY_FUNCTIONS.GetInvoiceExpiryDocType(iDocumentId) in('4', '5', '6') ) then
                      DOC_PRC_DOCUMENT.AssignCurrRiskVirtual(iDocumentId          => iDocumentID
                                                           , oCurrRiskVirtualID   => lCurrRiskVirtualID
                                                           , oErrorCode           => lnErrorCode
                                                           , iInitTranche         => 1
                                                            );
                    else
                      -- Assignation d'une tranche virtuelle
                      DOC_PRC_DOCUMENT.AssignCurrRiskVirtual(iDocumentId          => iDocumentID
                                                           , oCurrRiskVirtualID   => lCurrRiskVirtualID
                                                           , oErrorCode           => lnErrorCode
                                                           , iInitTranche         => 0
                                                            );

                      -- La tranche virtuelle n'a pas pu être assignée
                      if lnErrorCode = 2 then
                        oErrorCode  := '132';
                      end if;
                    end if;
                  else
                    -- Vérifier si le montant du document est couvert par la tranche virtuelle
                    if DOC_LIB_DOCUMENT.CtrlDocumentCurrRiskAmount(iDocumentID => iDocumentID, iCurrRiskVirtualID => ltplDoc.GAL_CURRENCY_RISK_VIRTUAL_ID) = 0 then
                      oErrorCode  := '132';
                    end if;
                  end if;
                end if;
              else
                -- document avec des positions issues d'une copie/décharge
                open lcrDocSrcInfo(iDocumentID);

                fetch lcrDocSrcInfo
                 into ltplDocSrcInfo;

                close lcrDocSrcInfo;

                lbRateForced  := false;

                -- Identifier le flag cours forcé
                if (ltplDocSrcInfo.DOC_DISCHARGE = 1) then
                  lbRateForced  :=    (ltplDoc.GAS_CURR_RATE_FORCED = 1)
                                   or (ltplDocSrcInfo.GAS_CURR_RATE_FORCED = 1);
                elsif(ltplDocSrcInfo.DOC_COPY = 1) then
                  lbRateForced  :=(ltplDoc.GAS_CURR_RATE_FORCED = 1);
                end if;

                -- Cours forcé
                if lbRateForced then
                  -- Une seule tranche virtuelle (lecture des tranches définies sur les documents parents)
                  select count(*)
                       , min(DOC_DOCUMENT_ID)
                       , min(GAL_CURRENCY_RISK_VIRTUAL_ID)
                    into lnCount
                       , lDocumentSrcID
                       , lSrcDocCurrRiskVirtualID
                    from (select   min(DMT_SRC.DOC_DOCUMENT_ID) as DOC_DOCUMENT_ID
                                 , min(DMT_SRC.GAL_CURRENCY_RISK_VIRTUAL_ID) as GAL_CURRENCY_RISK_VIRTUAL_ID
                              from DOC_DOCUMENT DMT
                                 , DOC_POSITION POS
                                 , DOC_POSITION_DETAIL PDE
                                 , DOC_DOCUMENT DMT_SRC
                                 , DOC_POSITION POS_SRC
                                 , DOC_POSITION_DETAIL PDE_SRC
                             where DMT.DOC_DOCUMENT_ID = iDocumentID
                               and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                               and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                               and nvl(PDE.DOC_DOC_POSITION_DETAIL_ID, PDE.DOC2_DOC_POSITION_DETAIL_ID) = PDE_SRC.DOC_POSITION_DETAIL_ID
                               and POS_SRC.DOC_POSITION_ID = PDE_SRC.DOC_POSITION_ID
                               and DMT_SRC.DOC_DOCUMENT_ID = POS_SRC.DOC_DOCUMENT_ID
                               and DMT_SRC.GAL_CURRENCY_RISK_VIRTUAL_ID is not null
                          group by DMT_SRC.GAL_CURRENCY_RISK_VIRTUAL_ID
                                 , DMT_SRC.DMT_RATE_OF_EXCHANGE);

                  -- Documents source avec plusieurs tranches virtuelles
                  if lnCount > 1 then
                    oErrorCode  := '131';
                  else
                    lbInitializeRate  := false;

                    -- Tranche virtuelle pas encore définie sur le document courant
                    if (ltplDoc.GAL_CURRENCY_RISK_VIRTUAL_ID is null) then
                      -- Initialiser la tranche si le père ne possede pas de tranche virtuelle
                      if (lSrcDocCurrRiskVirtualID is null) then
                        lbInitializeRate  := true;
                      else
                        if (ltplDocSrcInfo.DOC_COPY = 1) then
                          -- En avenant, reprendre toujours le cours du père
                          if ltplDoc.IS_ADDENDUM = 1 then
                            lbInitializeRate  := false;
                          else
                            -- Config DOC_CURRENCY_RATE_TRANSFERT
                            --   Reprise du taux de change du document source sur le document cible
                            --   lors de la copie/décharge/duplication de document
                            --   0 = Recherche du cours de change selon la date du document
                            --   1 = Reprise du cours de change du document parent
                            --   2 = Selon champ "Transfert cours" du flux
                            if gcDOC_CURRENCY_RATE_TRANSFERT = '0' then
                              lbInitializeRate  := true;
                            elsif gcDOC_CURRENCY_RATE_TRANSFERT = '2' then
                              -- Rechercher sur le flux de copie l'info du transfert du cours
                              select nvl(max(GAC_TRANSFERT_CURR_RATE), 0)
                                into lnTransfertRate
                                from DOC_GAUGE_COPY
                               where DOC_GAUGE_COPY_ID = ltplDocSrcInfo.DOC_GAUGE_COPY_ID;

                              -- Initialisation de la tranche si pas de transfert du cours
                              if lnTransfertRate = 0 then
                                lbInitializeRate  := true;
                              end if;
                            end if;
                          end if;
                        end if;
                      end if;
                    end if;

                    -- Initialisation de la tranche virtuelle
                    if lbInitializeRate then
                      -- Assignation d'une tranche virtuelle
                      DOC_PRC_DOCUMENT.AssignCurrRiskVirtual(iDocumentId          => iDocumentID
                                                           , oCurrRiskVirtualID   => lCurrRiskVirtualID
                                                           , oErrorCode           => lnErrorCode
                                                           , iInitTranche         => 0
                                                            );

                      -- La tranche virtuelle n'a pas pu être assignée
                      if lnErrorCode = 2 then
                        oErrorCode  := '132';
                      end if;
                    else
                      -- Contrôle de la monnaie document = monnaie tranche virtuelle
                      lCurrRiskVirtualID  := nvl(ltplDoc.GAL_CURRENCY_RISK_VIRTUAL_ID, lSrcDocCurrRiskVirtualID);

                      -- Rechercher la monnaie de la tranche virtuelle
                      select nvl(max(ACS_FINANCIAL_CURRENCY_ID), 0)
                        into lCurrencyID
                        from GAL_CURRENCY_RISK_VIRTUAL
                       where GAL_CURRENCY_RISK_VIRTUAL_ID = lCurrRiskVirtualID;

                      -- Vérifier que la monnaie du document ne soit pas différente de la monnaie de la tranche virtuelle
                      -- Ne pas contrôler l'égalité de la monnaie si Hors couverture (car la monnaie du type de couverture 04 est toujours en MB )
                      if     (ltplDoc.ACS_FINANCIAL_CURRENCY_ID <> lCurrencyID)
                         and (ltplDoc.C_CURR_RATE_COVER_TYPE <> '04') then
                        oErrorCode  := '133';
                      else
                        -- Ne pas reprendre le flag Couverture forcée du parent si en copie
                        if (ltplDocSrcInfo.DOC_COPY = 1) then
                          lnCurrRiskForced  := 0;
                        else
                          lnCurrRiskForced  := ltplDocSrcInfo.DMT_CURR_RISK_FORCED;
                        end if;

                        -- Vérifier si le montant du document est couvert par la tranche virtuelle
                        --  Contrôler uniquement si la couverture n'a pas été forcée sur le parent
                        -- Pas de contrôle si avenant
                        if     (lnCurrRiskForced = 0)
                           and ltplDoc.IS_ADDENDUM <> 1
                           and (DOC_LIB_DOCUMENT.CtrlDocumentCurrRiskAmount(iDocumentID => iDocumentID, iCurrRiskVirtualID => lCurrRiskVirtualID) = 0) then
                          oErrorCode  := '132';
                        end if;

                        -- Pas encore de tranche virtuelle définie
                        if     (oErrorCode is null)
                           and (ltplDoc.GAL_CURRENCY_RISK_VIRTUAL_ID is null) then
                          DOC_PRC_DOCUMENT.SetCurrRiskVirtualId(iDocumentId             => iDocumentID
                                                              , iGalCurrRiskVirtualId   => ltplDocSrcInfo.GAL_CURRENCY_RISK_VIRTUAL_ID
                                                              , iRateOfExchange         => ltplDocSrcInfo.DMT_RATE_OF_EXCHANGE
                                                              , iBasePrice              => ltplDocSrcInfo.DMT_BASE_PRICE
                                                              , iCurrRateCoverType      => ltplDocSrcInfo.C_CURR_RATE_COVER_TYPE
                                                              , iCurrRiskForced         => lnCurrRiskForced
                                                               );
                          DOC_PRC_DOCUMENT.UpdateCurrRiskParentBalance(iDocumentId => iDocumentID);
                        end if;
                      end if;
                    end if;
                  end if;
                end if;
              end if;
            end if;
          end if;
        end if;
      else
        -- Document issus d'un échéancier (sauf facture en mode multicouvert) et couverture
        if     ltplDoc.GAL_CURRENCY_RISK_VIRTUAL_ID is null
           and ltplDoc.DMT_CURR_RISK_FORCED = 0 then
          -- Ctrl si le document est lié à une affaire avec risque de change
          -- Ctrl le nbre d'affaire liées au document
          DOC_LIB_DOCUMENT.CtrlProjectRisk(iDocumentID         => iDocumentID
                                         , oProjectID          => lRiskProjectID
                                         , oProjectRiskManag   => lnProjectRiskManag
                                         , oProjectCount       => lnProjectCount
                                          );

          if (lnProjectRiskManag = 1) then
            -- Assignation d'une tranche virtuelle
            InheritCurrRiskVirtual(iDocumentId => iDocumentID);
          end if;
        end if;
      end if;

      close lcrDoc;
    end if;
  end CtrlDocumentCurrencyRisk;

  /**
  * Description
  *   Déclenche la mise à jour du solde de la tranche virtuelle pour les documents parents liés à une tranche
  */
  procedure UpdateCurrRiskParentBalance(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    -- pour chaque doucument parent
    for ltplDocument in (select distinct DMTPAR.DOC_DOCUMENT_ID
                                    from DOC_POSITION_DETAIL PDESON
                                       , DOC_POSITION_DETAIL PDEPAR
                                       , DOC_DOCUMENT DMTPAR
                                   where PDESON.DOC_DOCUMENT_ID = iDocumentId
                                     and PDEPAR.DOC_POSITION_DETAIL_ID = PDESON.DOC_DOC_POSITION_DETAIL_ID
                                     and DMTPAR.DOC_DOCUMENT_ID = PDEPAR.DOC_DOCUMENT_ID
                                     and DMTPAR.GAL_CURRENCY_RISK_VIRTUAL_ID is not null) loop
      DOC_FUNCTIONS.UpdateBalanceTotal(ltplDocument.DOC_DOCUMENT_ID);
    end loop;

    ProcessListParent;
  end UpdateCurrRiskParentBalance;

  /**
  * procedure ForceCurrRiskVirtual
  * Description
  *   Force une tranche virtuelle sur un document (les ctrls sur le dépassement du montant ne se feront plus)
  */
  procedure ForceCurrRiskVirtual(
    iDocumentID           in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iGalCurrRiskVirtualId in GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type default null
  )
  is
    ltDocument          FWK_I_TYP_DEFINITION.t_crud_def;
    lnRateOfExchange    GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type;
    iBasePrice          GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type;
    lvCurrRateCoverType GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type;
  begin
    -- Protection du document
    DOC_DOCUMENT_FUNCTIONS.DocumentProtect(aDocumentID => iDocumentId, aProtect => 1);

    -- Assignation de la tranche virtuelle si renseignée
    if iGalCurrRiskVirtualId is not null then
      -- Rechercher les infos de la tranche virtuelle
      select GCV_RATE_OF_EXCHANGE
           , GCV_BASE_PRICE
           , C_GAL_RISK_TYPE
        into lnRateOfExchange
           , iBasePrice
           , lvCurrRateCoverType
        from GAL_CURRENCY_RISK_VIRTUAL
       where GAL_CURRENCY_RISK_VIRTUAL_ID = iGalCurrRiskVirtualId;

      -- Assignation de la tranche virtuelle et recalcul des montants MB du document
      DOC_PRC_DOCUMENT.SetCurrRiskVirtualId(iDocumentId             => iDocumentId
                                          , iGalCurrRiskVirtualId   => iGalCurrRiskVirtualId
                                          , iRateOfExchange         => lnRateOfExchange
                                          , iBasePrice              => iBasePrice
                                          , iCurrRateCoverType      => lvCurrRateCoverType
                                          , iCurrRiskForced         => 1
                                           );
    else
      --Maj table DOC_DOCUMENT
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcDocDocument, iot_crud_definition => ltDocument, in_main_id => iDocumentId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocument, 'DMT_CURR_RISK_FORCED', 1);
      FWK_I_MGT_ENTITY.UpdateEntity(ltDocument);
      FWK_I_MGT_ENTITY.Release(ltDocument);
    end if;

    DOC_DOCUMENT_FUNCTIONS.FinalizeDocument(iDocumentID);
  end ForceCurrRiskVirtual;

  /**
  * Description
  *   Ajoute le document lié au parent dans la liste des documents dont il faut recalculer le montant solde
  */
  procedure AddDocToListParent(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lDocId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    null;   -- Formatage
    gtblDocListParent := gtblDocListParent multiset union distinct ID_TABLE_TYPE(iDocumentId);
  end AddDocToListParent;

  /**
  * Description
  *   Ajoute le document lié au parent dans la liste des documents dont il faut recalculer le montant solde
  */
  procedure AddDocToListParent(iDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
  is
    lDocId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select DOC_DOCUMENT_ID
      into lDocId
      from DOC_POSITION_DETAIL
     where DOC_POSITION_DETAIL_ID = iDetailId;

    null;   -- Formatage
    gtblDocListParent := gtblDocListParent multiset union distinct ID_TABLE_TYPE(lDocId);
  end AddDocToListParent;

  /**
  * Description
  *   Ajoute le document lié à l'échéancier dans la liste des documents dont il faut recalculer le montant solde
  */
  procedure AddDocToListParent(iInvoiceExpiryId in DOC_DOCUMENT.DOC_INVOICE_EXPIRY_ID%type)
  is
    lDocId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    if iInvoiceExpiryId is not null then
      select DOC_DOCUMENT_ID
        into lDocId
        from DOC_INVOICE_EXPIRY
       where DOC_INVOICE_EXPIRY_ID = iInvoiceExpiryId;

      null;   -- Formatage
      gtblDocListParent := gtblDocListParent multiset union distinct ID_TABLE_TYPE(lDocId);
    end if;
  end AddDocToListParent;

  /**
  * Description
  *   Clear la liste des documents contenue dans la variable globale  gtblDocListParent
  */
  procedure ClearListParent
  is
  begin
    gtblDocListParent  := ID_TABLE_TYPE();
  end ClearListParent;

  /**
  * Description
  *   Met à jour le montant solde des documents conteu dans la variable globale  gtblDocListParent
  */
  procedure ProcessListParent
  is
  begin
    if gtblDocListParent.count > 0 then
      for i in gtblDocListParent.first .. gtblDocListParent.last loop
        DOC_FUNCTIONS.UpdateBalanceTotal(gtblDocListParent(i) );
      end loop;
    end if;

    ClearListParent;
  end ProcessListParent;

  /**
  * Description
  *   Remet à zéro les messages d'erreur du document
  */
  procedure ResetConfirmError(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    update DOC_DOCUMENT
       set C_CONFIRM_FAIL_REASON = null
         , DMT_ERROR_MESSAGE = null
     where DOC_DOCUMENT_ID = iDocumentID;
  end ResetConfirmError;

  /**
  * procedure SetRecalcDocAmounts
  * Description
  *   Assigne à 1 tous les flags pour relancer le calcul des montants du document
  */
  procedure SetFlagsRateModified(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iDocRevaluationRate in DOC_DOCUMENT.DMT_REVALUATION_RATE%type default 1)
  is
  begin
    -- Màj du flag sur les positions du doc pour le recalcul des montants
    update DOC_POSITION
       set POS_RECALC_AMOUNTS = 1
         , POS_MODIFY_RATE = 1
     where DOC_DOCUMENT_ID = iDocumentID;

    -- Màj du flag sur les remises et taxes position du doc pour le recalcul des montants
    update DOC_POSITION_CHARGE
       set PCH_MODIFY_RATE = 1
     where DOC_DOCUMENT_ID = iDocumentID;

    -- Màj du flag sur les remises et taxes de pied du doc pour le recalcul des montants
    update DOC_FOOT_CHARGE
       set FCH_MODIFY_RATE = 1
     where DOC_FOOT_ID = iDocumentID;

    -- Màj du flag sur les échéances pour le recalcul des montants
    update DOC_INVOICE_EXPIRY_DETAIL
       set IED_MODIFY_RATE = 1
     where DOC_INVOICE_EXPIRY_ID in(select DOC_INVOICE_EXPIRY_ID
                                      from DOC_INVOICE_EXPIRY
                                     where DOC_DOCUMENT_ID = iDocumentID);

    -- Màj du flag sur les détails d'échéances pour le recalcul des montants
    update DOC_INVOICE_EXPIRY
       set INX_MODIFY_RATE = 1
     where DOC_DOCUMENT_ID = iDocumentID;

    -- Màj des flags de recalcul des totaux
    update DOC_DOCUMENT
       set DMT_RECALC_TOTAL = 1
         , DMT_REDO_PAYMENT_DATE = 1
         , DMT_REVALUATION_RATE = iDocRevaluationRate
     where DOC_DOCUMENT_ID = iDocumentID;
  end SetFlagsRateModified;
end DOC_PRC_DOCUMENT;
