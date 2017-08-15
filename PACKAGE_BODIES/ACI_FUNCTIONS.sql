--------------------------------------------------------
--  DDL for Package Body ACI_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_FUNCTIONS" 
as
  -------------------------
  procedure DeleteDocuments(aDOC_INTEGRATION_DATE ACI_DOCUMENT.DOC_INTEGRATION_DATE%type)
  is

    cursor DocumentsToDeleteCursor is
      select ACI_DOCUMENT_ID
        from ACI_DOCUMENT
        where C_INTERFACE_CONTROL = 1
          and DOC_INTEGRATION_DATE is not null
          and DOC_INTEGRATION_DATE <= aDOC_INTEGRATION_DATE;

    Id ACI_DOCUMENT.ACI_DOCUMENT_ID%type;

  begin
    open DocumentsToDeleteCursor;
    fetch DocumentsToDeleteCursor into Id;
    while DocumentsToDeleteCursor%found loop
      delete from ACI_DOCUMENT
        where ACI_DOCUMENT_ID = Id;
      delete from ACI_DOCUMENT_STATUS
        where ACI_DOCUMENT_ID = Id;
      commit;
      fetch DocumentsToDeleteCursor into Id;
    end loop;
    close DocumentsToDeleteCursor;
  end DeleteDocuments;

  ---------------------------
  function GetACT_DOCUMENT_ID(aACI_DOCUMENT_ID ACI_DOCUMENT.ACI_DOCUMENT_ID%type) return ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  is
    Ok         boolean default True;
    CustomerId ACI_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID%type;
    SupplierId ACI_PART_IMPUTATION.PAC_SUPPLIER_PARTNER_ID%type;
    DocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type default null;
  begin
    begin
      select PAC_CUSTOM_PARTNER_ID,
             PAC_SUPPLIER_PARTNER_ID into CustomerId, SupplierId
        from ACI_PART_IMPUTATION
        where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;
    exception
        when TOO_MANY_ROWS then
          Ok := False;
    end;
    if Ok then
      select min(REC.ACT_DOCUMENT_ID) into DocumentId
        from ACT_DOC_RECEIPT REC,
             ACI_DOCUMENT    DOC
        where DOC.ACI_DOCUMENT_ID = aACI_DOCUMENT_ID
          and DOC.DOC_DOCUMENT_ID = REC.DOC_DOCUMENT_ID;
      if DocumentId is null then
      begin
        if CustomerId is not null then
          select DACT.ACT_DOCUMENT_ID into DocumentId
            from ACI_PART_IMPUTATION PACI,
                 ACT_PART_IMPUTATION PACT,
                 ACT_DOCUMENT        DACT
            where PACI.ACI_DOCUMENT_ID       = aACI_DOCUMENT_ID
              and PACI.PAC_CUSTOM_PARTNER_ID = PACT.PAC_CUSTOM_PARTNER_ID
              and PACI.PAR_DOCUMENT          = PACT.PAR_DOCUMENT
              and DACT.ACT_DOCUMENT_ID       = PACT.ACT_DOCUMENT_ID;
        else
          select DACT.ACT_DOCUMENT_ID into DocumentId
            from ACI_PART_IMPUTATION PACI,
                 ACT_PART_IMPUTATION PACT,
                 ACT_DOCUMENT        DACT
            where PACI.ACI_DOCUMENT_ID         = aACI_DOCUMENT_ID
              and PACI.PAC_SUPPLIER_PARTNER_ID = PACT.PAC_SUPPLIER_PARTNER_ID
              and PACI.PAR_DOCUMENT            = PACT.PAR_DOCUMENT
              and DACT.ACT_DOCUMENT_ID         = PACT.ACT_DOCUMENT_ID;
        end if;
      exception
        when NO_DATA_FOUND then
          DocumentId := null;
        when TOO_MANY_ROWS then
          DocumentId := null;
      end;
      end if;
    end if;
    return DocumentId;
  end GetACT_DOCUMENT_ID;

  /**
  * Description
  *    retourne le premier ID trouvé
  *    pour une écriture financière dans un ACi_DOCUMENT_ID donné, concernant un ACC_NUMBER donné
  *    et un DIV_NUMBER donnée. Cette fonction n'est donc utilisable que sur des documents non détaillé
  *    en particulier les documents générés depuis la ventilation des salaires (unicité ACI_DOCUMENT_ID,
  *    ACC_NUMBER, DIV_NUMBER).
  * @Used : Cette fonction est utilisée dans la vue V_HRM_BREAK_AN_TRANSFERT lors du passage en compta
  *         pour faire le lien entre l'écriture financière et analytique
  */
  function GetACI_FINANCIAL_IMPUTATION_ID(aACI_DOCUMENT_ID ACI_DOCUMENT.ACI_DOCUMENT_ID%type,
                                          aDIV_NUMBER ACI_FINANCIAL_IMPUTATION.DIV_NUMBER%type,
                                          aACC_NUMBER ACI_FINANCIAL_IMPUTATION.ACC_NUMBER%type)
       return ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type
  is
    cursor financialImputation is
      select ACI_FINANCIAL_IMPUTATION_ID
        from ACI_FINANCIAL_IMPUTATION
        where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID
          and ACC_NUMBER= aACC_NUMBER
          and DIV_NUMBER= aDIV_NUMBER;
    Id ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
    vACC_NUMBER ACS_ACCOUNT.ACC_NUMBER%type;
    vACI_DOCUMENT_ID ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
  begin

    vACC_NUMBER:=aACC_NUMBER;
    vACI_DOCUMENT_ID:=aACI_DOCUMENT_ID;

    open financialImputation;
    fetch financialImputation into Id;
    close financialImputation;

    if Id is null then
      begin
        select ACI_FINANCIAL_IMPUTATION_ID into Id
          from ACI_FINANCIAL_IMPUTATION
         where ACI_DOCUMENT_ID = vACI_DOCUMENT_ID
           and ACC_NUMBER=vACC_NUMBER
           and (div_number is null or div_number='')
           and ROWNUM=1;
      end;
    end if;

    return Id;

  end GetACI_FINANCIAL_IMPUTATION_ID;

  /**
  * Description
  *    Réactive un document déjà envoyé en finance afin qu'on puisse le reconfirmer
  *    Ca va le créer une nouvelle fois, il faut dans certains cas prendre le soin
  *    d'effacer le document ACT préalablement.
  */
  procedure ReactiveDocument(aDocumentId in number)
  is
  begin
    update ACI_DOCUMENT
       set C_INTERFACE_CONTROL = '3',
           DOC_INTEGRATION_DATE = null
     where ACI_DOCUMENT_ID = aDocumentId;
    update ACI_DOCUMENT_STATUS
       set C_ACI_FINANCIAL_LINK = '3'
     where ACI_DOCUMENT_ID = aDocumentId;
  end ReactiveDocument;


  /**
  * procedure DeleteConversionType
  * Description
  *  Suppression du type de conversion selon la date de création
  */
  procedure DeleteConversionType(aACI_CONVERSION_TYPE_ID ACI_CONVERSION_TYPE.ACI_CONVERSION_TYPE_ID%type,
                                 aA_DATECRE              ACI_CONVERSION_TYPE.A_DATECRE%type)
  is
  begin
    DELETE FROM
      ACI_CONVERSION
    WHERE
      A_DATECRE              < aA_DATECRE AND
      ACI_CONVERSION_TYPE_ID = aACI_CONVERSION_TYPE_ID;
  end DeleteConversionType;

  /**
  * Description
  *    Retour du document logistique à l'origine du document comptable
  **/
  procedure GET_DOC_DOCUMENT_ID (aACI_DOCUMENT_ID ACI_DOCUMENT.ACI_DOCUMENT_ID%type,
                                 aDOC_DOCUMENT_ID out DOC_DOCUMENT.DOC_DOCUMENT_ID%type,
                                 aCOM_NAME_DOC out ACT_DOCUMENT.COM_NAME_DOC%type)
  is
    vDocNumber  ACI_DOCUMENT.DOC_NUMBER%type;
    vComNameDOC ACI_DOCUMENT.COM_NAME_DOC%type;
    vComNameACT ACI_DOCUMENT.COM_NAME_ACT%type;
    vSql_code   varchar2(200);
    vDBOwner    PCS.PC_SCRIP.SCRDBOWNER%type := null;
    vDBLink     PCS.PC_SCRIP.SCRDB_LINK%type := null;
  begin
    aCOM_NAME_DOC := null;
    aDOC_DOCUMENT_ID := 0;

    /*Recherche du document logistique dans le document financier*/
    select min(DOC.DOC_DOCUMENT_ID)
         , min(DOC.COM_NAME_DOC)
      into aDOC_DOCUMENT_ID
         , vComNameDOC
     from  ACI_DOCUMENT DOC
    where DOC.ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;

    --Recherche société courante
    select COM_NAME
      into vComNameACT
      from PCS.PC_COMP
      where PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;

    --Recherche des info de connexion si document sur une autre société
    if not ((vComNameDOC = vComNameACT) or vComNameDOC is null) then
      select PC_SCRIP.SCRDBOWNER
          , PC_SCRIP.SCRDB_LINK
        into vDBOwner
          , vDBLink
        from PCS.PC_SCRIP
          , PCS.PC_COMP
      where PC_SCRIP.PC_SCRIP_ID = PC_COMP.PC_SCRIP_ID
        and PC_COMP.COM_NAME = vComNameDOC;

      aCOM_NAME_DOC := vDBOwner;

      if vDBLink is not null then
        vDBLink := '@' || vDBLink;
      end if;
      if vDBOwner is not null then
        vDBOwner := vDBOwner || '.';
      end if;
    end if;

    -- Si pas d'id recherche du document en fonction de son numéro
    if aDOC_DOCUMENT_ID is null then
      --Recherche numéro document
      select min(DOC.DOC_NUMBER)
        into vDocNumber
      from ACI_DOCUMENT DOC
      where DOC.ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;

      --Si pas de num document on quitte
      if vDocNumber is null then
        return;
      end if;

      /*Recherche du document logistique par le n° document*/
      vSql_code  :=
          'select min(DOC_DOCUMENT_ID) ' ||
          '  from [COMPANY_OWNER_2]DOC_DOCUMENT[COMPANY_DBLINK_2] ' ||
          ' where DMT_NUMBER = :DocNumber';
      vSql_code  := replace(vSql_code, '[COMPANY_OWNER_2]', vDBOwner);
      vSql_code  := replace(vSql_code, '[COMPANY_DBLINK_2]', vDBLink);

      execute immediate vSql_code
                    into aDOC_DOCUMENT_ID
                  using in vDocNumber;

    end if;

  end GET_DOC_DOCUMENT_ID;


end ACI_FUNCTIONS;
