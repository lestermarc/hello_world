--------------------------------------------------------
--  DDL for Package Body DOC_EVENT_SAMPLES
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EVENT_SAMPLES" 
as
  function check_payment_condition(pDoc_document_id in doc_document.doc_document_id%type)
    return varchar2
  is
    vTotal_amount      doc_foot.FOO_DOCUMENT_TOTAL_AMOUNT%type;
    vPayment_condition pac_payment_condition.pac_payment_condition_id%type;
  begin
    select sum(pos.pos_net_value_incl)
      into vTotal_amount
      from doc_position pos
     where pos.doc_document_id = pDoc_document_id;

    if vTotal_amount > 1000000 then
      select dmt.pac_payment_condition_id
        into vPayment_condition
        from doc_document dmt
       where dmt.doc_document_id = pDoc_document_id;

      if vPayment_condition <> 5520 then
        return 'Le montant du document dépasse 1''000''000 CHF, choisir la condition de paiement : condition 1 [ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end check_payment_condition;

  procedure init_doc_document_value
  is
  begin
    doc_document_initialize.InitDocument_110;
    doc_document_initialize.DocumentInfo.use_dmt_reference  := 1;
    doc_document_initialize.DocumentInfo.dmt_reference      := pcs.PC_I_LIB_SESSION.getuserini;
    doc_document_initialize.DocumentInfo.use_dmt_text       := 1;
    doc_document_initialize.DocumentInfo.dmt_text_1         := 'Commande spéciale UserDay 2004';
  end;
end DOC_EVENT_SAMPLES;
