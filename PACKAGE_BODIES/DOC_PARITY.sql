--------------------------------------------------------
--  DDL for Package Body DOC_PARITY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PARITY" 
is
  /**
  * Description
  *    remise à jour des quantités provisoires en stock
  */
  procedure RestoreProvQty
  is
  begin
    DOC_PRC_PARITY.RestoreProvQty;
  end RestoreProvQty;

  /**
  * Description
  *    remise à jour des quantités provisoires en stock pour un bien
  */
  procedure RestoreProvQtyGood(aGoodId in number)
  is
  begin
    DOC_PRC_PARITY.RestoreProvQtyGood(iGoodId => aGoodId);
  end RestoreProvQtyGood;

  /**
  * Description
  *    Reconstruction du décompte TVA
  */
  procedure recalcVatDetAccount(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aRecalcPositionVat in number)
  is
  begin
    DOC_PRC_PARITY.recalcVatDetAccount(iDocumentId => aDocumentId
                                     , iRecalcPositionVat => aRecalcPositionVat);
  end recalcVatDetAccount;

end DOC_PARITY;
