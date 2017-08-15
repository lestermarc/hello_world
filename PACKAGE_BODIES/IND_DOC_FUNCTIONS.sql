--------------------------------------------------------
--  DDL for Package Body IND_DOC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_DOC_FUNCTIONS" 
is

  function IsDocUnicVatRate(DocId doc_document.doc_document_id%type) return number
  -- Retourne 1 s'il n'y qu'un taux TVA pour le document
  -- Retourne 0 s'il y a plusieurs taux
  is
   retour number;
  begin

  select
  count(*) into retour
  from
  (select
        decode(vat.VDA_VAT_RATE,
      null,
      ACS_FUNCTION.GETVATRATE(vat.ACS_TAX_CODE_ID,decode(doc.DMT_DATE_DELIVERY,null,DMT_DATE_DOCUMENT,DMT_DATE_DELIVERY)),
      VDA_VAT_RATE)
   from
   doc_document doc,
   doc_vat_det_account vat
   where
   doc.doc_document_id=vat.doc_foot_id
   and doc.doc_document_id=DocId
   group by decode(vat.VDA_VAT_RATE,
      null,
      ACS_FUNCTION.GETVATRATE(vat.ACS_TAX_CODE_ID,decode(doc.DMT_DATE_DELIVERY,null,DMT_DATE_DOCUMENT,DMT_DATE_DELIVERY)),
      VDA_VAT_RATE)
  );

  if retour > 1
   then retour:=0;
   else retour:=1;
  end if;

  return retour;

  end IsDocUnicVatRate;

  function GetDocUnicVatRate(DocId doc_document.doc_document_id%type) return number
  -- Retourne le taux TVA du document. La fonction ne retourne qu'un taux (max)
  is
   retour number;
  begin

  select
  max(rate) into retour
  from
  (select
        decode(vat.VDA_VAT_RATE,
      null,
      ACS_FUNCTION.GETVATRATE(vat.ACS_TAX_CODE_ID,decode(doc.DMT_DATE_DELIVERY,null,DMT_DATE_DOCUMENT,DMT_DATE_DELIVERY)),
      VDA_VAT_RATE) rate
   from
   doc_document doc,
   doc_vat_det_account vat
   where
   doc.doc_document_id=vat.doc_foot_id
   and doc.doc_document_id=DocId
   group by decode(vat.VDA_VAT_RATE,
      null,
      ACS_FUNCTION.GETVATRATE(vat.ACS_TAX_CODE_ID,decode(doc.DMT_DATE_DELIVERY,null,DMT_DATE_DOCUMENT,DMT_DATE_DELIVERY)),
      VDA_VAT_RATE)
  );

  return retour;

  end GetDocUnicVatRate;

  procedure ChangeDocStatus(DocFrom doc_document.dmt_number%type, DocTo doc_document.dmt_number%type)
  -- "Dé-confirmation" des documents
  is
   cursor CurCheck is
    select
    doc_number||' ('||jou_description||')' doc_number
    from
    act_document a,
    act_journal b
    where
    a.act_journal_id=b.act_journal_id
    and doc_number>=DocFrom
    and doc_number<=DocTo;

    cursor CurDoc is
    select
    doc_document_id
    from
    doc_document
    where
    dmt_number>=DocFrom
    and dmt_number<=DocTo;

   vCount integer;
   Msg varchar2(4000);

  begin
   vCount:=0;
   Msg:='';

   -- *** ETAPE 1 *** Test si les documents logisitques sont en compta
   for RowCheck in CurCheck
   loop
    Msg:=Msg||RowCheck.doc_number||chr(10);
    vCount:=vCount+1;
   end loop;

   if vCount>0
   then raise_application_error(-20001,'>>>>>>>>>>>>>>>>'||chr(10)||chr(10)||
                                       'Les documents comptabilisés doivent être supprimés : '||chr(10)||
                                       Msg||chr(10)||
                                       '>>>>>>>>>>>>>>>>');
   end if;

   -- *** ETAPE 2 *** Changement de statut
   for RowDoc in CurDoc
   loop

    -- Statut du document
    update doc_document
    set C_DOCUMENT_STATUS='01'
    where
    doc_document_id=RowDoc.doc_document_id;

    -- Statut des position
    update doc_position
    set C_DOC_POS_STATUS='01'
    where
    doc_document_id=RowDoc.doc_document_id;

    -- Flag transfert en compta
    update doc_document
    set DMT_FINANCIAL_CHARGING=0
    where
    doc_document_id=RowDoc.doc_document_id;

   end loop;

  end ChangeDocStatus;

  procedure changeDocumentCurrRate(
    aDocumentId    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aNewCurrRate   in DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aNewBasePrice  in DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aAllowFinished in boolean default false
  , aRateType      in varchar2 default 1
  )
  is
    vDocStatus    DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    vDmtProtected DOC_DOCUMENT.DMT_PROTECTED%type;
    vDmtNumber    DOC_DOCUMENT.DMT_NUMBER%type;
    vDmtSessionId DOC_DOCUMENT.DMT_SESSION_ID%type;
  begin
    -- recherche status et vérification protection
    select C_DOCUMENT_STATUS
         , DMT_PROTECTED
         , DMT_SESSION_ID
         , DMT_NUMBER
      into vDocStatus
         , vDmtProtected
         , vDmtSessionId
         , vDmtNumber
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;

    pChangeDocumentCurrRate(aDocumentID
                                                 , vDmtNumber
                                                 , vDocStatus
                                                 , vDmtProtected
                                                 , vDmtSessionId
                                                 , aNewCurrRate
                                                 , aNewBasePrice
                                                 , aAllowFinished
                                                 , aRateType
                                                  );
    -- Finalisation du document, Attention il faudra éventuellement reconfirmer le document
    DOC_DOCUMENT_FUNCTIONS.FinalizeDocument(aDocumentId);
  end changeDocumentCurrRate;

  procedure pChangeDocumentCurrRate(
    aDocumentId    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDmtNumber     in DOC_DOCUMENT.DMT_NUMBER%type
  , aDocStatus     in DOC_DOCUMENT.C_DOCUMENT_STATUS%type
  , aDmtProtected  in DOC_DOCUMENT.DMT_PROTECTED%type
  , aDmtSessionId  in DOC_DOCUMENT.DMT_SESSION_ID%type
  , aNewCurrRate   in DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aNewBasePrice  in DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aAllowFinished in boolean default false
  , aRateType      in varchar2 default 1
  )
  is
    vModified number(1);
  begin
    -- controle que le document ne soit pas liquidé
    if     aDocStatus = '04'
       and not aAllowFinished then
      raise_application_error
                  (-20000
                 , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Document liquidé, traitement impossible : [DOCNO]')
                         , '[DOCNO]'
                         , aDmtNumber
                          )
                  );
    elsif aDocStatus = '05' then
      raise_application_error
                   (-20000
                  , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Document effacé, traitement impossible : [DOCNO]')
                          , '[DOCNO]'
                          , aDmtNumber
                           )
                   );
    end if;

    -- contrôle que le document ne soit pas protégé
    if     aDmtProtected = 1
       and aDmtSessionId is not null
       and (aDmtSessionId <> DBMS_SESSION.unique_session_id) then
      raise_application_error
        (-20000
       , replace
           (PCS.PC_FUNCTIONS.TranslateWord
                                       ('PCS - Document protégé ou en cours d''édition, traitement impossible : [DOCNO]')
          , '[DOCNO]'
          , aDmtNumber
           )
        );
    else
      update DOC_DOCUMENT
         set DMT_PROTECTED = 1
           , DMT_RATE_OF_EXCHANGE = decode(aRateType, 1, aNewCurrRate, DMT_RATE_OF_EXCHANGE)
           , DMT_BASE_PRICE = decode(aRateType, 1, aNewBasePrice, DMT_BASE_PRICE)
           , DMT_VAT_EXCHANGE_RATE = decode(aRateType, 2, aNewCurrRate, DMT_VAT_EXCHANGE_RATE)
           , DMT_VAT_BASE_PRICE = decode(aRateType, 2, aNewBasePrice, DMT_VAT_BASE_PRICE)
           , DMT_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID
       where DOC_DOCUMENT_ID = aDocumentId;

      DOC_VAT.RemoveVatCorrectionAmount(aDocumentId, 1, 1, vModified);
    end if;

    -- Suppression des documents comptables
    if     aAllowFinished
       and aDocStatus = '04' then
      -- Effacement ACI_DOCUMENT
      delete from ACI_DOCUMENT
            where DOC_DOCUMENT_ID = aDocumentId;

      -- Effacement ACT_DOCUMENT
      delete from ACT_DOCUMENT
            where DOC_DOCUMENT_ID = aDocumentId;

      -- Réactiver le document
      DOC_FUNCTIONS.ReactiveDocument(aDocumentId);
    end if;

    -- Recalcul de tous les montants monnaie de base dans les tables liées au document

    -- Màj du flag sur les positions du doc pour le recalcul des montants
    update DOC_POSITION
       set POS_RECALC_AMOUNTS = 1
         , POS_MODIFY_RATE = 1
     where DOC_DOCUMENT_ID = aDocumentId;

    -- Màj du flag sur les remises et taxes position du doc pour le recalcul des montants
    update DOC_POSITION_CHARGE
       set PCH_MODIFY_RATE = 1
     where DOC_DOCUMENT_ID = aDocumentId;

    -- Màj du flag sur les remises et taxes de pied du doc pour le recalcul des montants
    update DOC_FOOT_CHARGE
       set FCH_MODIFY_RATE = 1
     where DOC_FOOT_ID = aDocumentId;

/*    -- Màj du flag sur les échéances pour le recalcul des montants
    update DOC_INVOICE_EXPIRY_DETAIL
       set IED_MODIFY_RATE = 1
     where DOC_INVOICE_EXPIRY_ID in(select DOC_INVOICE_EXPIRY_ID
                                      from DOC_INVOICE_EXPIRY
                                     where DOC_DOCUMENT_ID = aDocumentId);

    -- Màj du flag sur les détails d'échéances pour le recalcul des montants
    update DOC_INVOICE_EXPIRY
       set INX_MODIFY_RATE = 1
     where DOC_DOCUMENT_ID = aDocumentId;
*/
    -- Màj des flags de recalcul des totaux
    update DOC_DOCUMENT
       set DMT_RECALC_TOTAL = 1
         , DMT_REDO_PAYMENT_DATE = 1
     where DOC_DOCUMENT_ID = aDocumentId;

    -- Mise à jour des totaux
    DOC_FUNCTIONS.UpdateFootTotals(aDocumentId, vModified);
    -- Reinitialisation des montants du document (report des nouveaux montants de taxe)
    DOC_DOCUMENT_FUNCTIONS.ReinitDocumentPrice(aDocumentId => aDocumentId, aReinitUnitPrice => 0);
  end pChangeDocumentCurrRate;

end ind_doc_functions;
