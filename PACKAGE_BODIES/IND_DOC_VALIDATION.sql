--------------------------------------------------------
--  DDL for Package Body IND_DOC_VALIDATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_DOC_VALIDATION" 
is
  function ctrl_doc_division(DocumentId doc_document.doc_document_id%type) RETURN VARCHAR2
  -- Contrôle que les divisions soient renseignées sur le document
  is
    DivType acs_division_account.DIC_DIV_ACC_CODE_1_ID%type;
    DivisionId acs_division_account.acs_division_account_id%type;
    vCount integer;
    retour VARCHAR2(100);
   begin

    -- Recherche du type de division sur l'en-tête
    select max(DIC_DIV_ACC_CODE_1_ID), max(doc.acs_division_account_id)
          into DivType, DivisionId
    from doc_document doc, acs_division_account div
    where doc.acs_division_account_id= div.acs_division_account_id
    and doc.doc_document_id=DocumentID;

    -- Recherche s'il existe des positions sans division
    select count(*) into vCount
    from doc_position pos, acs_division_account div
    where doc_document_id=DocumentId
    and pos.acs_division_account_id= div.acs_division_account_id
    and (pos.acs_division_account_id is null
         or DIC_DIV_ACC_CODE_1_ID='01')
    AND DOC_GAUGE_POSITION_ID='1';


    -- Type 01 = Division à remplacer -> message d'erreur
    if DivType='01' or DivisionId is null
      then retour:='Une division doit être renseignée dans l''en-tête de document [ABORT]';
      elsif vCount > 0
        then retour:='Division non renseignée pour une ou plusieurs positions [ABORT]';
    end if;

  return retour;

  end ctrl_doc_division;

  function ctrl_doc_after(DocumentId doc_document.doc_document_id%type) RETURN VARCHAR2
  -- Contrôle que le dossier et les date de facturation (champs virtuels) soient renseignés
  is
    vCount integer;
    DateFrom date;
    DateTo date;
    retour VARCHAR2(100);
   begin

    -- Recherche des positions sans dossier
    select
    count(*) into vCount
    from
    doc_position
    where
    doc_document_id=DocumentId
    and doc_record_id is null;

    -- S'il manque un dossier -> Erreur
    if vCount > 0
      then retour:='Attention, il existe des positions sans dossier [ABORT]';
    end if;

    -- Recherche des dates de période facturation
    select
    max(VFI_DATE_01), max(VFI_DATE_02)
     into DateFrom, DateTo
    from
    doc_document doc,
    com_vfields_record vfi
    where
    doc.doc_document_id=DocumentId
    and doc.doc_document_id=vfi_rec_id
    and vfi.vfi_tabname='DOC_DOCUMENT';

    if DateFrom is null or DateTo is null
      then retour:='Attention, les périodes de facturation n''ont pas été renseignées (onglet Attributs) [ABORT]';
    end if;

  return retour;

  end ctrl_doc_after;

  procedure UpdatePosition(PositionId doc_position.doc_position_id%type)
  -- Update la division de la position avec celle du docuemnt (si la division n'est pas A REMPLACER)
  -- Update du dossier de la positionen fonction du client
  is
   DocDivId acs_division_account.acs_division_account_id%type;
   PosDivId acs_division_account.acs_division_account_id%type;
   DocDivType DIC_DIV_ACC_CODE_1.DIC_DIV_ACC_CODE_1_ID%type;
   PosDivType DIC_DIV_ACC_CODE_1.DIC_DIV_ACC_CODE_1_ID%type;
   DocRecId doc_record.doc_record_id%type;
   PosRecId doc_record.doc_record_id%type;

   begin
    -- recherche des valeurs
    select
    doc.acs_division_account_id,
    ddiv.DIC_DIV_ACC_CODE_1_ID,
    pos.acs_division_account_id,
    pdiv.DIC_DIV_ACC_CODE_1_ID,
    rec.doc_record_id,
    pos.doc_record_id
    into DocDivId, DocDivType, PosDivId, PosDivType, DocRecId, PosRecId
    from
    doc_position pos,
    doc_document doc,
    acs_division_account pdiv,
    acs_division_account ddiv,
    doc_record rec
    where
    pos.doc_document_id=doc.doc_document_id
    and pos.acs_division_account_id=pdiv.acs_division_account_id
    and doc.acs_division_account_id=ddiv.acs_division_account_id
    and doc.pac_third_id=rec.pac_third_id(+)
    and doc_position_id=PositionId;

        -- Dossier
    if DocRecId is not null and PosRecId is null
    then update doc_position
         set doc_record_id=DocRecId
         where doc_position_id=PositionId;
    end if;

    -- Division document <> 'E' et <> 'E99999'
    -- et Division position = 'E'
    if nvl(DocDivType,'NULL') <> '01' and nvl(DocDivType,'NULL') <> '03' and nvl(PosDivType,'NULL') = '01'
    then update doc_position
         set acs_division_account_id=DocDivId
         where doc_position_id=PositionId;
    end if;

  end UpdatePosition;

  procedure UpdateDocument(DocumentId doc_document.doc_document_id%type)
  -- mise à jour d'éléments du document
  is
   RecordId doc_record.doc_record_id%type;
   DivType acs_division_account.DIC_DIV_ACC_CODE_1_ID%type;
   DivisionId acs_division_account.acs_division_account_id%type;

  begin
  -- DOSSIER
   -- recherche du dossier en fonction du partenaire
    select max(a.doc_record_id) into RecordId
    from doc_record a, doc_document b
    where b.doc_document_id=DocumentId
    and a.pac_third_id=b.pac_third_id;

    -- mise à jour document
    update doc_document
    set doc_record_id=RecordId
    where doc_document_id=DocumentId
    and doc_record_id is null;

    -- mise à jour positions
    update doc_position
    set doc_record_id=RecordId
    where doc_document_id=DocumentId
    and doc_record_id is null;
/*
   -- DIVISION
     -- Recherche du type de division sur l'en-tête
    select max(DIC_DIV_ACC_CODE_1_ID), max(doc.acs_division_account_id)
          into DivType, DivisionId
    from doc_document doc, acs_division_account div
    where doc.acs_division_account_id= div.acs_division_account_id
    and doc.doc_document_id=DocumentID;

    if DivType is null or DivType='02'
    then update doc_position
         set acs_division_account_id=DivisionId
         where doc_document_id=DocumentId;
    end if;
*/
   end UpdateDocument;

end ind_doc_validation;
