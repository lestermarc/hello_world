--------------------------------------------------------
--  DDL for Package Body DOC_E_PRC_FOOT_PAYMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_E_PRC_FOOT_PAYMENT" 
is
  /**
  * procedure CreateFOOT_PAYMENT
  * Description
  *   Méthode permettant l'ajout d'un mode de paiement sur un document existant
  *
  */
  procedure CreateFOOT_PAYMENT(
    iv_DMT_NUMBER            in     DOC_DOCUMENT.DMT_NUMBER%type
  , iv_CAT_KEY               in     ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type
  , iv_CURRENCY              in     PCS.PC_CURR.CURRENCY%type
  , in_FOP_RECEIVED_AMOUNT   in     DOC_FOOT_PAYMENT.FOP_RECEIVED_AMOUNT%type
  , ion_FOP_PAID_AMOUNT      in out DOC_FOOT_PAYMENT.FOP_PAID_AMOUNT%type
  , ion_FOP_RETURNED_AMOUNT  in out DOC_FOOT_PAYMENT.FOP_RETURNED_AMOUNT%type
  , on_DOC_FOOT_PAYMENT_ID   out    DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  , in_FINALIZE_DOCUMENT     in     number default 1
  )
  is
    lnDocumentID          DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnProtected           DOC_DOCUMENT.DMT_PROTECTED%type;
    lnUnknownException    integer;
    lnErrorCode           number;
    lvErrorCode           DOC_DOCUMENT.C_CONFIRM_FAIL_REASON%type;
    lvErrorText           DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    lvErrMess             DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    lvBackTrace           DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    lnJobTypeID           ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type;
    lnJobTypeCatID        ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID%type;
    lnFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    lnUnknownException  := 1;
    lnErrorCode         := null;
    lvErrorText         := '';
    --
    savepoint add_foot_payment;

    -- Recherche les informations sur le document spécifié nécessaires à la création du paiement direct
    begin
      select DMT.DOC_DOCUMENT_ID
           , DMT.DMT_PROTECTED
           , JCA.ACJ_JOB_TYPE_ID
        into lnDocumentID
           , lnProtected
           , lnJobTypeID
        from DOC_DOCUMENT DMT
           , DOC_FOOT FOO
           , DOC_GAUGE_STRUCTURED GAS
           , ACJ_JOB_TYPE_S_CATALOGUE JCA
       where DMT.DMT_NUMBER = iv_DMT_NUMBER
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.GAS_CASH_REGISTER = 1
         and FOO.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
         and JCA.ACJ_JOB_TYPE_S_CATALOGUE_ID = GAS.ACJ_JOB_TYPE_S_CATALOGUE_ID;

      -- Contrôle si le document est protégé
      if lnProtected = 1 then
        lnErrorCode         := -20800;   -- Le document est en cours de modification (protégé)
        lvErrorText         := 'PCS - protected document - insert foot payment not allowed in this context';
        lnUnknownException  := 0;
      end if;
    exception
      when no_data_found then
        lnErrorCode         := -20800;   -- Document inexistant ou pas de vente au comptant défini
        lvErrorText         := 'PCS - no document or no cash sale defined';
        lnUnknownException  := 0;
        raise;
    end;

    -- Recherche le mode de paiement correspondant au catalogue de transaction spécifié (CAT_KEY)
    if lvErrorText is null then
      begin
        select JCA.ACJ_JOB_TYPE_S_CATALOGUE_ID
          into lnJobTypeCatID
          from ACJ_JOB_TYPE_S_CATALOGUE JCA
             , ACJ_CATALOGUE_DOCUMENT CAT
         where CAT.CAT_KEY = iv_CAT_KEY
           and JCA.ACJ_JOB_TYPE_ID = lnJobTypeID
           and JCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID;
      exception
        when no_data_found then
          lnErrorCode         := -20800;   -- Mode de paiement inexistant ou non autorisé
          lvErrorText         := 'PCS - payment transaction not found (' || lnJobTypeID || ') or unautorized';
          lnUnknownException  := 0;
          raise;
      end;
    end if;

    -- Recherche la monnaie d'encaissement en fonction du code monnaie spécifié (PC_CURR.CURRENCY)
    if lvErrorText is null then
      begin
        select   FIN.ACS_FINANCIAL_CURRENCY_ID
            into lnFinancialCurrencyID
            from ACS_FINANCIAL_CURRENCY FIN
               , PCS.PC_CURR CUR
           where CUR.CURRENCY = iv_CURRENCY
             and FIN.PC_CURR_ID = CUR.PC_CURR_ID
             and ACS_FUNCTION.IsValidCurrency(FIN.ACS_FINANCIAL_CURRENCY_ID) = 1
        order by CUR.CURRENCY asc
               , CUR.CURRNAME asc;
      exception
        when no_data_found then
          lnErrorCode         := -20800;   -- Monnaie inexistante ou invalide
          lvErrorText         := 'PCS - no currency or invalide currency';
          lnUnknownException  := 0;
          raise;
      end;
    end if;

    -- Contrôle de l'état du document pour permettre sa modification.
    if lvErrorText is null then
      begin
        DOC_PRC_DOCUMENT.ControlUpdateDocument(lnDocumentID, lvErrorText);

        if lvErrorText is not null then
          lnErrorCode         := -20800;   -- Le document n'est pas dans un état permettant la modification.
          lnUnknownException  := 0;
        end if;
      exception
        when others then
          -- TODO code d'erreur
          if lvErrorText is null then
            lvErrorCode  := '991';   -- Erreur non controlée lors du control du document.
            lnErrorCode  := -20800;   -- Edition du document impossible.
          end if;

          raise;
      end;
    end if;

    -- Préparation du document pour permettre sa modification.
    if lvErrorText is null then
      begin
        DOC_PRC_DOCUMENT.StartUpdateDocument(lnDocumentID, lvErrorCode, lvErrorText, 'DOC_UPDATE_FOOT_PAYMENT');

        if lvErrorText is not null then
          lnErrorCode         := -20800;   -- Préparation pour la modification du document impossible.
          lnUnknownException  := 0;
        end if;
      exception
        when others then
          if lvErrorCode is null then
            lvErrorCode  := '992';   -- Erreur non controlée lors de la préparation du document.
            lnErrorCode  := -20800;   -- Edition du document impossible.
          end if;

          raise;
      end;
    end if;

    if lvErrorText is null then
      -- Ajout d'un mode de paiement sur un document existant
      DOC_I_PRC_FOOT_PAYMENT.createFootPayment(iFootID                => lnDocumentID
                                          , iJobTypeCatID          => lnJobTypeCatID
                                          , iFinancialCurrencyID   => lnFinancialCurrencyID
                                          , iReceivedAmount        => in_FOP_RECEIVED_AMOUNT
                                          , ioPaidAmount           => ion_FOP_PAID_AMOUNT
                                          , ioReturnedAmount       => ion_FOP_RETURNED_AMOUNT
                                          , oFootPaymentID         => on_DOC_FOOT_PAYMENT_ID
                                           );
      DOC_FUNCTIONS.CreateHistoryInformation(lnDocumentID
                                           , null
                                           , iv_DMT_NUMBER
                                           , 'PL/SQL'
                                           , 'ADD FOOT PAYMENT'
                                           , null
                                           , null
                                           , null
                                            );
    end if;

    ----
    -- Valide le document après modification
    --
    if     lvErrorText is null
       and (in_FINALIZE_DOCUMENT = 1) then
      begin
        DOC_PRC_DOCUMENT.PostUpdateDocument(lnDocumentID, lvErrorCode, lvErrorText);

        if lvErrorText is not null then
          lnErrorCode         := -20800;
          lnUnknownException  := 0;
        end if;
      exception
        when others then
          if lvErrorCode is null then
            lvErrorCode  := '996';
            lnErrorCode  := -20800;   -- Exception d'appel
          end if;

          raise;
      end;

      DOC_FUNCTIONS.CreateHistoryInformation(lnDocumentID
                                           , null
                                           , iv_DMT_NUMBER
                                           , 'PL/SQL'
                                           , 'ADD FOOT PAYMENT WITH FINALIZE SUCCESSFUL COMPLETED'
                                           , 'FootPaymentID : ' || on_DOC_FOOT_PAYMENT_ID
                                           , null
                                           , null
                                            );
    elsif lvErrorText is null then
      DOC_FUNCTIONS.CreateHistoryInformation(lnDocumentID
                                           , null
                                           , iv_DMT_NUMBER
                                           , 'PL/SQL'
                                           , 'ADD FOOT PAYMENT SUCCESSFUL COMPLETED'
                                           , 'FootPaymentID : ' || on_DOC_FOOT_PAYMENT_ID
                                           , null
                                           , null
                                            );
    end if;

    -- Monte l'exception pour effectuer le traitement associé
    if lvErrorText is not null then
      ra(aMessage => lvErrorText, aErrNo => lnErrorCode);
    end if;
  exception
    when others then
      -- Sauvegarde les informations de l'exception principale.
      lvErrMess    := sqlerrm;
      lvBackTrace  := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
      rollback to savepoint add_foot_payment;

      -- Construit le texte d'erreur uniquement si c'est une erreur inconnue. Sinon on obtient toujours
      -- le code d'erreur Oracle -20000 suivi du code d'erreur PCS.
      if (lnUnknownException = 1) then
        addText(lvErrorText, lvErrMess || co.cLineBreak || lvBackTrace);
      end if;

      DOC_FUNCTIONS.CreateHistoryInformation(lnDocumentID
                                           , null
                                           , iv_DMT_NUMBER
                                           , 'PL/SQL'
                                           , 'EXCEPTION ADD FOOT PAYMENT '
                                           , 'Error Code : ' ||
                                             lnErrorCode ||
                                             co.cLineBreak ||
                                             lvErrMess ||
                                             chr(13) ||
                                             lvBackTrace
                                           , null
                                           , null
                                            );
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => lnErrorCode
                                        , iv_message       => lvErrorText
                                        , iv_stack_trace   => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                                        , iv_cause         => 'CreateFOOT_PAYMENT'
                                         );
  end CreateFOOT_PAYMENT;

  /**
  * procedure DeleteFOOT_PAYMENT
  * Description
  *   Méthode permettant la suppression d'un paiement sur un document existant
  *
  */
  procedure DeleteFOOT_PAYMENT(
    iv_DMT_NUMBER          in DOC_DOCUMENT.DMT_NUMBER%type
  , in_DOC_FOOT_PAYMENT_ID in DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type
  )
  is
    ltDocFootPayment    FWK_I_TYP_DEFINITION.t_crud_def;
    lnDocumentID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnProtected         DOC_DOCUMENT.DMT_PROTECTED%type;
    lnLastFootPaymentID DOC_FOOT_PAYMENT.DOC_FOOT_PAYMENT_ID%type;
    lnUnknownException  integer;
    lnErrorCode         number;
    lvErrorCode         DOC_DOCUMENT.C_CONFIRM_FAIL_REASON%type;
    lvErrorText         DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    lvErrMess           DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    lvBackTrace         DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
  begin
    lnUnknownException  := 1;
    lnErrorCode         := null;
    lvErrorText         := '';
    --
    savepoint delete_foot_payment;

    -- Recherche les informations sur le document spécifié nécessaires à la création du paiement direct
    begin
      select DMT.DOC_DOCUMENT_ID
           , DMT.DMT_PROTECTED
           , (select max(FOP.DOC_FOOT_PAYMENT_ID)
                from DOC_FOOT_PAYMENT FOP
               where FOP.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID)
        into lnDocumentID
           , lnProtected
           , lnLastFootPaymentID
        from DOC_DOCUMENT DMT
           , DOC_FOOT FOO
           , DOC_GAUGE_STRUCTURED GAS
           , ACJ_JOB_TYPE_S_CATALOGUE JCA
       where DMT.DMT_NUMBER = iv_DMT_NUMBER
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.GAS_CASH_REGISTER = 1
         and FOO.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
         and JCA.ACJ_JOB_TYPE_S_CATALOGUE_ID = GAS.ACJ_JOB_TYPE_S_CATALOGUE_ID;

      -- Contrôle si le document est protégé
      if (lnProtected = 1) then
        lnErrorCode         := -20800;   -- Le document est en cours de modification (protégé)
        lvErrorText         := 'PCS - protected document - delete foot payment not allowed in this context';
        lnUnknownException  := 0;
      elsif(lnLastFootPaymentID <> in_DOC_FOOT_PAYMENT_ID) then   -- Le paiement à effacer n'est pas le dernier créé.
        lnErrorCode         := -20800;   -- Uniquement le dernier paiement créé peut être supprimé
        lvErrorText         := 'PCS - invalid payment - only the last payment created can be deleted';
        lnUnknownException  := 0;
      end if;
    exception
      when no_data_found then
        lnErrorCode         := -20800;   -- Document inexistant ou pas de vente au comptant défini
        lvErrorText         := 'PCS - no document or no cash sale defined';
        lnUnknownException  := 0;
        raise;
    end;

    -- Contrôle de l'état du document pour permettre sa modification.
    if lvErrorText is null then
      begin
        DOC_PRC_DOCUMENT.ControlUpdateDocument(lnDocumentID, lvErrorText);

        if lvErrorText is not null then
          lnErrorCode         := -20800;   -- Le document n'est pas dans un état permettant la modification.
          lnUnknownException  := 0;
        end if;
      exception
        when others then
          -- TODO code d'erreur
          if lvErrorText is null then
            lvErrorCode  := '991';   -- Erreur non controlée lors du control du document.
            lnErrorCode  := -20800;   -- Edition du document impossible.
          end if;

          raise;
      end;
    end if;

    -- Préparation du document pour permettre sa modification.
    if lvErrorText is null then
      begin
        DOC_PRC_DOCUMENT.StartUpdateDocument(lnDocumentID, lvErrorCode, lvErrorText, 'DOC_UPDATE_FOOT_PAYMENT');

        if lvErrorText is not null then
          lnErrorCode         := -20800;   -- Préparation pour la modification du document impossible.
          lnUnknownException  := 0;
        end if;
      exception
        when others then
          if lvErrorCode is null then
            lvErrorCode  := '992';   -- Erreur non controlée lors de la préparation du document.
            lnErrorCode  := -20800;   -- Edition du document impossible.
          end if;

          raise;
      end;
    end if;

    if lvErrorText is null then
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocFootPayment, ltDocFootPayment);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDocFootPayment, 'DOC_FOOT_PAYMENT_ID', in_DOC_FOOT_PAYMENT_ID);
        FWK_I_MGT_ENTITY.DeleteEntity(ltDocFootPayment);
        FWK_I_MGT_ENTITY.Release(ltDocFootPayment);
      exception
        when others then
          if lvErrorCode is null then
            lvErrorCode  := '995';   -- Erreur non controlée lors de la suppression d'un paiement
            lnErrorCode  := -20800;   -- Suppression du paiement impossible.
          end if;

          raise;
      end;

      DOC_FUNCTIONS.CreateHistoryInformation(lnDocumentID
                                           , null
                                           , iv_DMT_NUMBER
                                           , 'PL/SQL'
                                           , 'DELETE FOOT PAYMENT'
                                           , null
                                           , null
                                           , null
                                            );
    end if;

    ----
    -- Valide le document après suppression
    --
    if lvErrorText is null then
      begin
        DOC_PRC_DOCUMENT.PostUpdateDocument(lnDocumentID, lvErrorCode, lvErrorText);

        if lvErrorCode is not null then
          lnErrorCode         := -20800;   -- Validation du document impossible.
          lnUnknownException  := 0;
        end if;
      exception
        when others then
          if lvErrorCode is null then
            lvErrorCode  := '996';
            lnErrorCode  := -20800;   -- Exception d'appel
          end if;

          raise;
      end;

      DOC_FUNCTIONS.CreateHistoryInformation(lnDocumentID
                                           , null
                                           , iv_DMT_NUMBER
                                           , 'PL/SQL'
                                           , 'DELETE FOOT PAYMENT SUCCESSFUL COMPLETED'
                                           , 'FootPaymentID : ' || in_DOC_FOOT_PAYMENT_ID
                                           , null
                                           , null
                                            );
    end if;

    -- Monte l'exception pour effectuer le traitement associé
    if lvErrorText is not null then
      ra(aMessage => lvErrorText, aErrNo => lnErrorCode);
    end if;
  exception
    when others then
      -- Sauvegarde les informations de l'exception principale.
      lvErrMess    := sqlerrm;
      lvBackTrace  := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
      rollback to savepoint delete_foot_payment;

      -- Construit le texte d'erreur uniquement si c'est une erreur inconnue. Sinon on obtient toujours
      -- le code d'erreur Oracle -20000 suivi du code d'erreur PCS.
      if (lnUnknownException = 1) then
        addText(lvErrorText, lvErrMess || co.cLineBreak || lvBackTrace);
      end if;

      DOC_FUNCTIONS.CreateHistoryInformation(lnDocumentID
                                           , null
                                           , iv_DMT_NUMBER
                                           , 'PL/SQL'
                                           , 'EXCEPTION DELETE FOOT PAYMENT '
                                           , lvErrMess || co.cLineBreak || lvBackTrace
                                           , null
                                           , null
                                            );
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => lnErrorCode
                                        , iv_message       => lvErrorText
                                        , iv_stack_trace   => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                                        , iv_cause         => 'DeleteFOOT_PAYMENT'
                                         );
  end DeleteFOOT_PAYMENT;
end DOC_E_PRC_FOOT_PAYMENT;
