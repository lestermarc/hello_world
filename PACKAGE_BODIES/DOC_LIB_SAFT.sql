--------------------------------------------------------
--  DDL for Package Body DOC_LIB_SAFT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_SAFT" 
as
  /**
  * Description :
  *    Retourne la date du document dans le format correspondant aux sp�cifications techniques de l'autorit�
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
  *    Retourne la date du syst�me lors de la g�n�ration de la signature dans le format correspondant
  *    aux sp�cifications techniques de l'autorit� fiscale portugaise (AAAA-MM-DDTHH:MI:SS)
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
  *    Retourne le num�ro de document lors de la g�n�ration de la signature dans le format correspondant
  *    aux sp�cifications techniques de l'autorit� fiscale portugaise.
  *    Attention, le format de document (DMT_NUMER) doit correspondre � ceci : */
--*    "([a-zA-Z0-9./_-])+ ([a-zA-Z0-9]*/[0-9]+)"
--*    Texte libre, suivi d'un espace, suivi d'un identificateur de s�rie, suivi d'un "/" suivi d'un num�ro s�quentiel
--*    de document dans la s�rie. ex : FC 2012/001
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
  *    Retourne le montant net hors TVA dans le format correspondant aux sp�cifications techniques de l'autorit�
  *    fiscale portugaise (2 d�cimales, "." comme s�parateur, pas de s�parateur de millier. Ex : 1200.40)
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
  *    Retourne la signateur du document pr�c�dent de la s�rie (champ DOC_DOCUMENT.DMT_SAFT_KEY).
  *    Retourne null s'il s'agit du premier document de la s�rie.
  */
  function getPreviousHash(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_DOCUMENT.DMT_SAFT_KEY%type
  as
    lCurrentSerie     varchar2(100);
    lCurrentIncrement number;
    lPreviousHash     DOC_DOCUMENT.DMT_SAFT_KEY%type;
  begin
    /* Extraction de la s�rie et de la s�quence du document en cours */
    lCurrentSerie      := getDocSerie(iDocumentID);
    lCurrentIncrement  := getDocSerieIncrement(getInvoiceNo(iDocumentID) );

    /* Recherche du document de la s�rie avec l'incr�ment le plus grand */
    select DMT_SAFT_KEY
      into lPreviousHash
      from DOC_DOCUMENT
     where DOC_LIB_SAFT.getDocSerie(DOC_DOCUMENT_ID) = lCurrentSerie
       and (DOC_LIB_SAFT.getDocSerieIncrement(DMT_NUMBER) ) =   --incr�ment d'avant
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
  *    G�n�re la signature SAFT du document dont l'ID est transmis en param�tre.
  */
  function generateSAFTKey(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_DOCUMENT.DMT_SAFT_KEY%type
  as
    lSaftKey     DOC_DOCUMENT.DMT_SAFT_KEY%type;
    lImputString varchar2(4000)                   := '';
  begin
    /* Construction de la chaine de caract�re � signer selon les sp�cifications techniques de l'autorit� fiscale portugaise */
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
  *    G�n�re la signature SAFT du document dont l'ID est transmis en param�tre.
  */
  function generateSAFTKey(iInvoiceDate in varchar2, iSysTemEntryDate in varchar2, iInvoiceNo in varchar2, iGrossTotal in varchar2, iPreviousHash in varchar2)
    return DOC_DOCUMENT.DMT_SAFT_KEY%type
  as
    lSaftKey     DOC_DOCUMENT.DMT_SAFT_KEY%type;
    lImputString varchar2(4000)                   := '';
  begin
    /* Construction de la chaine de caract�re � signer selon les sp�cifications techniques de l'autorit� fiscale portugaise */
    lImputString  := iInvoiceDate || ';' || iSysTemEntryDate || ';' || iInvoiceNo || ';' || iGrossTotal || ';' || iPreviousHash;
    lSaftKey      := COM_I_LIB_RSA.signWithPKS8Key(iInputString => lImputString, iCompany => pcs.PC_I_LIB_SESSION.GetCompanyOwner);
    return lSaftKey;
  end GenerateSAFTKey;

  /**
  * Description :
  *    Retourne la signature partielle du document transmis en param�tre pour impression
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
  *    Retourne l'incr�ment de la s�rie du document
  */
  function getDocSerieIncrement(iDocInvoiceNo in varchar2)
    return number
  as
  begin
    /* L'incr�ment se trouve en fin de num�ro de facture apr�s le caract�re '/' */
    return to_number(substr(iDocInvoiceNo, instr(iDocInvoiceNo, '/') + 1) );
  end getDocSerieIncrement;

  /**
  * Description :
  *    Retourne l'identifiant de la s�rie du document
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

    /* Extraction de la s�rie du document en cours (s�rie = DMT_NUMBER apr�s l'espace (" ") et avant le slash ("/")) */
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
