--------------------------------------------------------
--  DDL for Package Body DOC_LIB_SAFT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_SAFT" 
as
  /**
  * Description :
  *    Retourne la date du document dans le format correspondant aux spécifications techniques de l'autorité
  *    fiscale portugaise (AAAA-MM-DD)
  */
  function getInvoiceDate(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar2
  as
    lInvoiceDate varchar2(100);
  begin
    select to_char(PCS_FWK.FWK_LIB_ENTITY.getDateFieldFromPk(iv_entity_name   => 'DOC_DOCUMENT', iv_column_name => 'DMT_DATE_DOCUMENT'
                                                           , it_pk_value      => iDocumentID)
                 , 'YYYY-MM-DD'
                  )
      into lInvoiceDate
      from dual;

    return lInvoiceDate;
  end getInvoiceDate;

  /**
  * Description :
  *    Retourne la date du système lors de la génération de la signature dans le format correspondant
  *    aux spécifications techniques de l'autorité fiscale portugaise (AAAA-MM-DDTHH:MI:SS)
  */
  function getSysTemEntryDate(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar2
  as
    lSysTemEntryDate varchar2(100);
  begin
    select to_char(A_DATEMOD, 'YYYY-MM-DD"T"HH24:MI:SS')
      into lSysTemEntryDate
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = iDocumentID;

    return lSysTemEntryDate;
  end getSysTemEntryDate;

  /**
  * Description :
  *    Retourne le numéro de document lors de la génération de la signature dans le format correspondant
  *    aux spécifications techniques de l'autorité fiscale portugaise.
  *    Attention, le format de document (DMT_NUMER) doit correspondre à ceci : */
--*    "([a-zA-Z0-9./_-])+ ([a-zA-Z0-9]*/[0-9]+)"
--*    Texte libre, suivi d'un espace, suivi d'un identificateur de série, suivi d'un "/" suivi d'un numéro séquentiel
--*    de document dans la série. ex : FC 2012/001
--*/
  function getInvoiceNo(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar2
  as
    lInvoiceNo varchar2(100);
  begin
    lInvoiceNo  := PCS_FWK.FWK_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name => 'DOC_DOCUMENT', iv_column_name => 'DMT_NUMBER', it_pk_value => iDocumentID);
    return lInvoiceNo;
  end getInvoiceNo;

  /**
  * Description :
  *    Retourne le montant net hors TVA dans le format correspondant aux spécifications techniques de l'autorité
  *    fiscale portugaise (2 décimales, "." comme séparateur, pas de séparateur de millier. Ex : 1200.40)
  */
  function getGrossTotal(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar2
  as
    lGrossTotal varchar2(100);
  begin
    select to_char(FOO_DOCUMENT_TOTAL_AMOUNT - FOO_TOTAL_VAT_AMOUNT, 'FM999999999999990D00')
      into lGrossTotal
      from DOC_FOOT
     where DOC_FOOT_ID = iDocumentID;

    return lGrossTotal;
  end getGrossTotal;

  /**
  * Description :
  *    Retourne la signateur du document précédent de la série (champ DOC_DOCUMENT.DMT_SAFT_KEY).
  *    Retourne null s'il s'agit du premier document de la série.
  */
  function getPreviousHash(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_DOCUMENT.DMT_SAFT_KEY%type
  as
    lCurrentSerie     varchar2(100);
    lCurrentIncrement number;
    lPreviousHash     DOC_DOCUMENT.DMT_SAFT_KEY%type;
  begin
    /* Extraction de la série et de la séquence du document en cours */
    lCurrentSerie      := getDocSerie(iDocumentID);
    lCurrentIncrement  := getDocSerieIncrement(getInvoiceNo(iDocumentID) );

    /* Recherche du document de la série avec l'incrément le plus grand */
    select DMT_SAFT_KEY
      into lPreviousHash
      from DOC_DOCUMENT
     where DOC_LIB_SAFT.getDocSerie(DOC_DOCUMENT_ID) = lCurrentSerie
       and (DOC_LIB_SAFT.getDocSerieIncrement(DMT_NUMBER) ) =   --incrément d'avant
                           (select max(DOC_LIB_SAFT.getDocSerieIncrement(DMT_NUMBER) )
                              from DOC_DOCUMENT
                             where DOC_LIB_SAFT.getDocSerie(DOC_DOCUMENT_ID) = lCurrentSerie
                               and DOC_LIB_SAFT.getDocSerieIncrement(DMT_NUMBER) < lCurrentIncrement);

    return lPreviousHash;
  exception
    when no_data_found then
      return null;
  end getPreviousHash;

  /**
  * Description :
  *    Génère la signature SAFT du document dont l'ID est transmis en paramètre.
  */
  function generateSAFTKey(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_DOCUMENT.DMT_SAFT_KEY%type
  as
    lSaftKey     DOC_DOCUMENT.DMT_SAFT_KEY%type;
    lImputString varchar2(4000)                   := '';
  begin
    /* Construction de la chaine de caractère à signer selon les spécifications techniques de l'autorité fiscale portugaise */
    lImputString  :=
      getInvoiceDate(iDocumentID) ||
      ';' ||
      getSysTemEntryDate(iDocumentID) ||
      ';' ||
      getInvoiceNo(iDocumentID) ||
      ';' ||
      getGrossTotal(iDocumentID) ||
      ';' ||
      getPreviousHash(iDocumentID);
    lSaftKey      := COM_I_LIB_RSA.signWithPKS8Key(iInputString => lImputString, iCompany => pcs.PC_I_LIB_SESSION.GetCompanyOwner);
    return lSaftKey;
  end GenerateSAFTKey;

  /**
  * Description :
  *    Génère la signature SAFT du document dont l'ID est transmis en paramètre.
  */
  function generateSAFTKey(iInvoiceDate in varchar2, iSysTemEntryDate in varchar2, iInvoiceNo in varchar2, iGrossTotal in varchar2, iPreviousHash in varchar2)
    return DOC_DOCUMENT.DMT_SAFT_KEY%type
  as
    lSaftKey     DOC_DOCUMENT.DMT_SAFT_KEY%type;
    lImputString varchar2(4000)                   := '';
  begin
    /* Construction de la chaine de caractère à signer selon les spécifications techniques de l'autorité fiscale portugaise */
    lImputString  := iInvoiceDate || ';' || iSysTemEntryDate || ';' || iInvoiceNo || ';' || iGrossTotal || ';' || iPreviousHash;
    lSaftKey      := COM_I_LIB_RSA.signWithPKS8Key(iInputString => lImputString, iCompany => pcs.PC_I_LIB_SESSION.GetCompanyOwner);
    return lSaftKey;
  end GenerateSAFTKey;

  /**
  * Description :
  *    Retourne la signature partielle du document transmis en paramètre pour impression
  */
  function getPrintSAFTKey(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_DOCUMENT.DMT_SAFT_KEY%type
  as
    lPrintSAFTKey DOC_DOCUMENT.DMT_SAFT_KEY%type;
  begin
    -- TODO Code implementation here
    return lPrintSAFTKey;
  end GetPrintSAFTKey;

  /**
  * Description :
  *    Retourne l'xml complet pour audit SAFT
  */
  function getSAFTXml(iDateFrom in date, iDateTo in date)
    return xmltype
  as
    lSAFTXml xmltype;
  begin
    -- TODO Code implementation here
    return lSAFTXml;
  end GetSAFTXml;

  /**
  * Description :
  *    Retourne l'incrément de la série du document
  */
  function getDocSerieIncrement(iDocInvoiceNo in varchar2)
    return number
  as
  begin
    /* L'incrément se trouve en fin de numéro de facture après le caractère '/' */
    return to_number(substr(iDocInvoiceNo, instr(iDocInvoiceNo, '/') + 1) );
  end getDocSerieIncrement;

  /**
  * Description :
  *    Retourne l'identifiant de la série du document
  */
  function getDocSerie(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar2
  as
    lInvoiceNo varchar2(100);
    lSerie     varchar2(100);
    lStartPos  number;
    lEndPos    number;
  begin
    lInvoiceNo  := getInvoiceNo(iDocumentID);

    /* Extraction de la série du document en cours (série = DMT_NUMBER après l'espace (" ") et avant le slash ("/")) */
    select instr(lInvoiceNo, ' ') + 1
         , instr(lInvoiceNo, '/')
      into lStartPos
         , lEndPos
      from dual;

    select substr(lInvoiceNo, lStartPos, lEndPos - lStartPos)
      into lSerie
      from dual;

    return lSerie;
  end getDocSerie;
end DOC_LIB_SAFT;
