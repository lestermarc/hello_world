--------------------------------------------------------
--  DDL for Package Body DOC_FINALIZE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_FINALIZE" 
as
  /**
  * Description
  *   Mise à jour des totaux de document, des remises/taxes de pieds,
  *   de l'arrondi TVA et des échéances avant la libération (fin d'édition) du document
  */
  procedure FinalizeDocument(
    aDocumentId     in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDeprotected       number default 1
  , aExecExternProc    number default 1
  , aConfirm           number default 1
  )
  is
    gauUseManagedData  DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    gauConfirmStatus   DOC_GAUGE.GAU_CONFIRM_STATUS%type;
    cDocumentStatus    DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    vErrorText         varchar2(4000);
    vErrorCode         varchar2(30);
    lConfirmFailReason DOC_DOCUMENT.C_CONFIRM_FAIL_REASON%type;
    lProtected         DOC_DOCUMENT.DMT_PROTECTED%type;
  begin
    DOC_DOCUMENT_FUNCTIONS.FinalizeDocument(aDocumentId => aDocumentId, aDeprotected => aDeprotected, aExecExternProc => aExecExternProc);

    if (aConfirm = 1) then
      select GAU.GAU_USE_MANAGED_DATA
           , GAU.GAU_CONFIRM_STATUS
           , DMT.C_DOCUMENT_STATUS
           , DMT.C_CONFIRM_FAIL_REASON
           , nvl(DMT.DMT_PROTECTED, 0)
        into gauUseManagedData
           , gauConfirmStatus
           , cDocumentStatus
           , lConfirmFailReason
           , lProtected
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and DMT.DOC_DOCUMENT_ID = aDocumentId;

      -- Confirmation automatique du document
      -- Ne pas confirmer si bloqué par la gestion du risque de change
      if not(     (lProtected = 1)
             and (lConfirmFailReason in('130', '131', '132', '133', '134') ) ) then
        if    (gauConfirmStatus = 0)
           or (    gauConfirmStatus = 1
               and (cDocumentStatus <> '01') ) then
          DOC_DOCUMENT_FUNCTIONS.ConfirmDocument(aDocumentId, vErrorCode, vErrorText, 0);
        end if;
      end if;
    end if;
  end FinalizeDocument;
end DOC_FINALIZE;
