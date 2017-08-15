--------------------------------------------------------
--  DDL for Package Body DOC_EDI_EDEC_EXPOWIN_V4
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_EDEC_EXPOWIN_V4" 
as
  /**
  * procedure getFileName
  * Description
  *    Génération d'un nom du fichier de sortie
  */
  procedure getFileName(iEdecHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, iEdiTypeID in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type, oFilename out varchar2)
  is
  begin
    select DEH_TRADER_DECLARATION_NUMBER || '-' || to_char(sysdate, 'YYYYMMDD-HH24MISS') || '.txt'
      into oFilename
      from DOC_EDEC_HEADER
     where DOC_EDEC_HEADER_ID = iEdecHeaderID;
  end getFileName;

  /**
   * procedure GenerateAddresses
   * Description
   *    Création des adresses pour la déclaration EDEC
   */
  procedure GenerateAddresses(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type)
  is
    vDocumentID      DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vPackingListID   DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type;
    vAddress         DOC_EDEC_ADDRESSES%rowtype;
    vThirdDeliveryID PAC_THIRD.PAC_THIRD_ID%type;
    vDelivAddress    integer                                     default null;
  begin
    -- Rechercher la source des données pour les adresses (document ou envoi)
    select DEH.DOC_DOCUMENT_ID
         , DEH.DOC_PACKING_LIST_ID
         , DMT.PAC_THIRD_DELIVERY_ID
      into vDocumentID
         , vPackingListID
         , vThirdDeliveryID
      from DOC_EDEC_HEADER DEH
         , DOC_DOCUMENT DMT
     where DEH.DOC_EDEC_HEADER_ID = aHeaderID
       and DEH.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID(+);

    -- Adresse DESTINATAIRE
    select INIT_ID_SEQ.nextval
         , aHeaderID
         , '1'
         , PCS.PC_I_LIB_SESSION.GetUserIni
         , sysdate
      into vAddress.DOC_EDEC_ADDRESSES_ID
         , vAddress.DOC_EDEC_HEADER_ID
         , vAddress.C_EDEC_ADDRESS_TYPE
         , vAddress.A_IDCRE
         , vAddress.A_DATECRE
      from dual;

    -- Adresse DESTINATAIRE DE LA MARCHANDISE
    if vDocumentID is not null then
      -- Source des données = document (DOC_DOCUMENT)
      -- si partenaire de livraison non vide alors les valeurs sont prises sur l'adresse du partenaire de livraison
      --  sinon les valeurs sont prises sur l'adresse du partenaire de facturation
      if vThirdDeliveryID is not null then
        -- Adresse du partenaire de livraison
        select DMT.DMT_NAME2
             , substr(extractline(DMT.DMT_ADDRESS2, 1, chr(10) ), 1, 35)
             , substr(extractline(DMT.DMT_ADDRESS2, 2, chr(10) ), 1, 35)
             , substr(extractline(DMT.DMT_ADDRESS2, 3, chr(10) ), 1, 35)
             , substr(DMT.DMT_POSTCODE2, 1, 9)
             , substr(DMT.DMT_TOWN2, 1, 35)
             , DMT.PC__PC_CNTRY_ID
          into vAddress.DEA_NAME
             , vAddress.DEA_STREET
             , vAddress.DEA_ADDRESS_SUPPLEMENT_1
             , vAddress.DEA_ADDRESS_SUPPLEMENT_2
             , vAddress.DEA_POSTAL_CODE
             , vAddress.DEA_CITY
             , vAddress.PC_CNTRY_ID
          from DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = vDocumentID;
      else
        -- Adresse du partenaire de facturation
        select DMT.DMT_NAME3
             , substr(extractline(DMT.DMT_ADDRESS3, 1, chr(10) ), 1, 35)
             , substr(extractline(DMT.DMT_ADDRESS3, 2, chr(10) ), 1, 35)
             , substr(extractline(DMT.DMT_ADDRESS3, 3, chr(10) ), 1, 35)
             , substr(DMT.DMT_POSTCODE3, 1, 9)
             , substr(DMT.DMT_TOWN3, 1, 35)
             , DMT.PC_2_PC_CNTRY_ID
          into vAddress.DEA_NAME
             , vAddress.DEA_STREET
             , vAddress.DEA_ADDRESS_SUPPLEMENT_1
             , vAddress.DEA_ADDRESS_SUPPLEMENT_2
             , vAddress.DEA_POSTAL_CODE
             , vAddress.DEA_CITY
             , vAddress.PC_CNTRY_ID
          from DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = vDocumentID;
      end if;
    -- Source des données = envoi (DOC_PACKING_LIST)
    elsif vPackingListID is not null then
      -- Adresse DESTINATAIRE
      -- Vérifier si l'adresse du partenaire de livraison est renseigné sur l'envoi
      select sign(nvl(max(DOC_PACKING_LIST_ID), 0) )
        into vDelivAddress
        from DOC_PACKING_LIST
       where DOC_PACKING_LIST_ID = vPackingListID
         and (    (PAL_ADDRESS12 is not null)
              or (PAL_POSTCODE12 is not null)
              or (PAL_TOWN12 is not null)
              or (PC__PC_CNTRY_ID is not null) );

      -- Adresse du partenaire de livraison
      if vDelivAddress = 1 then
        select PAL_NAME12
             , substr(extractline(PAL_ADDRESS12, 1, chr(10) ), 1, 35)
             , substr(extractline(PAL_ADDRESS12, 2, chr(10) ), 1, 35)
             , substr(extractline(PAL_ADDRESS12, 3, chr(10) ), 1, 35)
             , substr(PAL_POSTCODE12, 1, 9)
             , substr(PAL_TOWN12, 1, 35)
             , PC__PC_CNTRY_ID
          into vAddress.DEA_NAME
             , vAddress.DEA_STREET
             , vAddress.DEA_ADDRESS_SUPPLEMENT_1
             , vAddress.DEA_ADDRESS_SUPPLEMENT_2
             , vAddress.DEA_POSTAL_CODE
             , vAddress.DEA_CITY
             , vAddress.PC_CNTRY_ID
          from DOC_PACKING_LIST
         where DOC_PACKING_LIST_ID = vPackingListID;
      else
        -- Adresse du partenaire de facturation
        select PAL_NAME13
             , substr(extractline(PAL_ADDRESS13, 1, chr(10) ), 1, 35)
             , substr(extractline(PAL_ADDRESS13, 2, chr(10) ), 1, 35)
             , substr(extractline(PAL_ADDRESS13, 3, chr(10) ), 1, 35)
             , substr(PAL_POSTCODE13, 1, 9)
             , substr(PAL_TOWN13, 1, 35)
             , PC_2_PC_CNTRY_ID
          into vAddress.DEA_NAME
             , vAddress.DEA_STREET
             , vAddress.DEA_ADDRESS_SUPPLEMENT_1
             , vAddress.DEA_ADDRESS_SUPPLEMENT_2
             , vAddress.DEA_POSTAL_CODE
             , vAddress.DEA_CITY
             , vAddress.PC_CNTRY_ID
          from DOC_PACKING_LIST
         where DOC_PACKING_LIST_ID = vPackingListID;
      end if;
    end if;

    -- Insertion de l'adresse DESTINATAIRE
    insert into DOC_EDEC_ADDRESSES
         values vAddress;

    -- Adresse EXPEDITEUR
    insert into DOC_EDEC_ADDRESSES
                (DOC_EDEC_ADDRESSES_ID
               , DOC_EDEC_HEADER_ID
               , C_EDEC_ADDRESS_TYPE
               , DEA_STREET
               , DEA_ADDRESS_SUPPLEMENT_1
               , DEA_ADDRESS_SUPPLEMENT_2
               , DEA_POSTAL_CODE
               , DEA_CITY
               , PC_CNTRY_ID
               , A_IDCRE
               , A_DATECRE
                )
      select INIT_ID_SEQ.nextval
           , aHeaderID
           , '2'
           , substr(extractline(COM_ADR, 1, chr(10) ), 1, 35)
           , substr(extractline(COM_ADR, 2, chr(10) ), 1, 35)
           , substr(extractline(COM_ADR, 3, chr(10) ), 1, 35)
           , substr(COM_ZIP, 1, 9)
           , substr(COM_CITY, 1, 35)
           , PC_CNTRY_ID
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , sysdate
        from PCS.PC_COMP
       where PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;

    vAddress  := null;

    -- Adresse TRANSPORTEUR
    select INIT_ID_SEQ.nextval
         , aHeaderID
         , '3'
         , PCS.PC_I_LIB_SESSION.GetUserIni
         , sysdate
      into vAddress.DOC_EDEC_ADDRESSES_ID
         , vAddress.DOC_EDEC_HEADER_ID
         , vAddress.C_EDEC_ADDRESS_TYPE
         , vAddress.A_IDCRE
         , vAddress.A_DATECRE
      from dual;

    -- Source des données = document (DOC_DOCUMENT)
    if VDocumentID is not null then
      -- Adresse TRANSPORTEUR
      select substr(extractline(ADR.ADD_ADDRESS1, 1, chr(10) ), 1, 35)
           , substr(extractline(ADR.ADD_ADDRESS1, 2, chr(10) ), 1, 35)
           , substr(extractline(ADR.ADD_ADDRESS1, 3, chr(10) ), 1, 35)
           , substr(ADR.ADD_ZIPCODE, 1, 9)
           , substr(ADR.ADD_CITY, 1, 35)
           , ADR.PC_CNTRY_ID
        into vAddress.DEA_STREET
           , vAddress.DEA_ADDRESS_SUPPLEMENT_1
           , vAddress.DEA_ADDRESS_SUPPLEMENT_2
           , vAddress.DEA_POSTAL_CODE
           , vAddress.DEA_CITY
           , vAddress.PC_CNTRY_ID
        from DOC_DOCUMENT DMT
           , PAC_SENDING_CONDITION SEN
           , PAC_ADDRESS ADR
       where DMT.DOC_DOCUMENT_ID = vDocumentID
         and DMT.PAC_SENDING_CONDITION_ID = SEN.PAC_SENDING_CONDITION_ID(+)
         and SEN.PAC_ADDRESS_ID = ADR.PAC_ADDRESS_ID(+);
    -- Source des données = envoi (DOC_PACKING_LIST)
    elsif vPackingListID is not null then
      -- Adresse TRANSPORTEUR
      select substr(extractline(PAL_ADDRESS21, 1, chr(10) ), 1, 35)
           , substr(extractline(PAL_ADDRESS21, 2, chr(10) ), 1, 35)
           , substr(extractline(PAL_ADDRESS21, 3, chr(10) ), 1, 35)
           , substr(PAL_POSTCODE21, 1, 9)
           , substr(PAL_TOWN21, 1, 35)
           , PC_3_PC_CNTRY_ID
        into vAddress.DEA_STREET
           , vAddress.DEA_ADDRESS_SUPPLEMENT_1
           , vAddress.DEA_ADDRESS_SUPPLEMENT_2
           , vAddress.DEA_POSTAL_CODE
           , vAddress.DEA_CITY
           , vAddress.PC_CNTRY_ID
        from DOC_PACKING_LIST
       where DOC_PACKING_LIST_ID = vPackingListID;
    end if;

    if vAddress.pc_cntry_id is not null then
      -- Insertion de l'adresse TRANSPORTEUR
      insert into DOC_EDEC_ADDRESSES
           values vAddress;
    end if;

    -- Adresse du DESTINATAIRE DE LA FACTURE
    select INIT_ID_SEQ.nextval
         , aHeaderID
         , '5'
         , PCS.PC_I_LIB_SESSION.GetUserIni
         , sysdate
      into vAddress.DOC_EDEC_ADDRESSES_ID
         , vAddress.DOC_EDEC_HEADER_ID
         , vAddress.C_EDEC_ADDRESS_TYPE
         , vAddress.A_IDCRE
         , vAddress.A_DATECRE
      from dual;

    if vDocumentID is not null then
      -- Source des données = document (DOC_DOCUMENT)
      select substr(extractline(DMT.DMT_ADDRESS3, 1, chr(10) ), 1, 35)
           , substr(extractline(DMT.DMT_ADDRESS3, 2, chr(10) ), 1, 35)
           , substr(extractline(DMT.DMT_ADDRESS3, 3, chr(10) ), 1, 35)
           , substr(DMT.DMT_POSTCODE3, 1, 9)
           , substr(DMT.DMT_TOWN3, 1, 35)
           , DMT.PC_2_PC_CNTRY_ID
        into vAddress.DEA_STREET
           , vAddress.DEA_ADDRESS_SUPPLEMENT_1
           , vAddress.DEA_ADDRESS_SUPPLEMENT_2
           , vAddress.DEA_POSTAL_CODE
           , vAddress.DEA_CITY
           , vAddress.PC_CNTRY_ID
        from DOC_DOCUMENT DMT
       where DMT.DOC_DOCUMENT_ID = vDocumentID;
    elsif vPackingListID is not null then
      select substr(extractline(PAL_ADDRESS13, 1, chr(10) ), 1, 35)
           , substr(extractline(PAL_ADDRESS13, 2, chr(10) ), 1, 35)
           , substr(extractline(PAL_ADDRESS13, 3, chr(10) ), 1, 35)
           , substr(PAL_POSTCODE13, 1, 9)
           , substr(PAL_TOWN13, 1, 35)
           , PC_2_PC_CNTRY_ID
        into vAddress.DEA_STREET
           , vAddress.DEA_ADDRESS_SUPPLEMENT_1
           , vAddress.DEA_ADDRESS_SUPPLEMENT_2
           , vAddress.DEA_POSTAL_CODE
           , vAddress.DEA_CITY
           , vAddress.PC_CNTRY_ID
        from DOC_PACKING_LIST
       where DOC_PACKING_LIST_ID = vPackingListID;
    end if;

    -- Insertion de l'adresse TRANSPORTEUR
    insert into DOC_EDEC_ADDRESSES
         values vAddress;
  end GenerateAddresses;

  /**
  * procedure GenerateExport
  * Description
  *   Méthode principale pour l'exportation d'une déclaration EDEC en fonction
  *   d'un type d'exporation EDI passé en paramètre
  */
  procedure GenerateExport(aEdecHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, aEdiTypeID in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type, aErrorMsg out varchar2)
  is
    vJobID DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type;
  begin
    -- Création du job d'exportation
    vJobID   := CreateEdecExportJob(aEdecHeaderID => aEdecHeaderID, aEdiTypeID => aEdiTypeID);
    -- Effacer les valeurs des variables globales
    vHeader  := null;
    vTblPositions.delete;
    vTblPacking.delete;
    -- Initialisation des données des éléments en fonction de la déclaration EDEC passée en param
    InitializeData(aEdecHeaderID => aEdecHeaderID, aEdiTypeID => aEdiTypeID);
    -- Insertion des données d'export relatives à l'élément Header
    DOC_EDI_EXPOWIN_FMT_V4.Write_Header(aExportJobID => vJobID, aItem => vHeader);
    -- Insertion des données d'export relatives aux éléments Position
    DOC_EDI_EXPOWIN_FMT_V4.Write_Positions(aExportJobID => vJobID, aList => vTblPositions);
    -- Insertion des données d'export relatives aux éléments Packing
    DOC_EDI_EXPOWIN_FMT_V4.Write_Packing(aExportJobID => vJobID, aList => vTblPacking);
    -- Envoi du job d'export dans les table du système d'échange de données
    DOC_EDI_EXPORT_JOB_FUNCTIONS.SendJobToPcExchange(aExportJobID => vJobID, aErrorMsg => aErrorMsg);
  end GenerateExport;

  /**
  * function getEdecPermitID
  * Description
  *   Renvoi le permis à utiliser en fonction de la date d'établissement de celui-ci
  */
  function getEdecPermitID(iEdecPosID in DOC_EDEC_POSITION.DOC_EDEC_POSITION_ID%type, iDate in date)
    return number
  is
    cursor lcrPermit
    is
      select   DOC_EDEC_PERMIT_ID
          from DOC_EDEC_PERMIT
         where DOC_EDEC_POSITION_ID = iEdecPosID
           and DEP_ISSUE_DATE <= trunc(iDate)
      order by DEP_ISSUE_DATE desc;

    lnPermitID DOC_EDEC_PERMIT.DOC_EDEC_PERMIT_ID%type;
  begin
    open lcrPermit;

    fetch lcrPermit
     into lnPermitID;

    close lcrPermit;

    return lnPermitID;
  end getEdecPermitID;

  /**
  * procedure pInitializeData
  * Description
  *  procédure interne
  *   Initialisation des données des éléments Master Data et Line Item
  *   en fonction de la déclaration EDEC passée en param
  */
  procedure pInitializeData(aEdecHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, aEdiTypeID in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type)
  is
    tplHeader   DOC_EDEC_HEADER%rowtype;
    tplAddress1 DOC_EDEC_ADDRESSES%rowtype;
    tplAddress3 DOC_EDEC_ADDRESSES%rowtype;
    tplAddress5 DOC_EDEC_ADDRESSES%rowtype;
    tplDocument DOC_DOCUMENT%rowtype;
    tplDocFoot  DOC_FOOT%rowtype;
    tplPacking  DOC_PACKING_LIST%rowtype;
    vIndex      number;
    vPosCpt1    integer;
    lnPermitID  DOC_EDEC_PERMIT.DOC_EDEC_PERMIT_ID%type;

    function GetCountryCode(aPC_CNTRY_ID PCS.PC_CNTRY.PC_CNTRY_ID%type)
      return PCS.PC_CNTRY.CNTID%type
    is
      vresult PCS.PC_CNTRY.CNTID%type;
    begin
      select max(CNTID)
        into vresult
        from PCS.PC_CNTRY
       where PC_CNTRY_ID = aPC_CNTRY_ID;

      return vresult;
    end GetCountryCode;

    function getLangCode(aPC_LANG_ID pcs.pc_lang.pc_lang_id%type)
      return pcs.pc_lang.lanid%type
    is
      vResult pcs.pc_lang.lanid%type;
    begin
      select decode(lan.lanid, 'GE', 'DE', lan.lanid)
        into vResult
        from pcs.pc_lang lan
       where lan.pc_lang_id = aPC_LANG_ID;

      return vResult;
    end getLangCode;

    function getAllDmtNumber(aDoc_packing_list_id doc_packing_list.doc_packing_list_id%type)
      return varchar2
    is
      vResult varchar2(6900);
    begin
      for tpl_packing in (select distinct dmt.dmt_number
                                     from doc_document dmt
                                        , doc_packing_parcel_pos pap
                                    where pap.doc_packing_list_id = aDoc_packing_list_id
                                      and pap.doc_document_id = dmt.doc_document_id) loop
        if length(vResult) + length(tpl_packing.dmt_number) + 1 <= 6900 then
          vResult  := vResult || tpl_packing.dmt_number || ',';
        end if;
      end loop;

      return rtrim(vResult, ',');
    end getAllDmtNumber;
  begin
    select *
      into tplHeader
      from DOC_EDEC_HEADER
     where DOC_EDEC_HEADER_ID = aEdecHeaderID;

    select DEA.*
      into tplAddress1
      from DOC_EDEC_ADDRESSES DEA
     where DEA.DOC_EDEC_HEADER_ID = aEdecHeaderID
       and DEA.C_EDEC_ADDRESS_TYPE = '1';

    begin
      tplAddress3  := null;

      select DEA.*
        into tplAddress3
        from DOC_EDEC_ADDRESSES DEA
       where DEA.DOC_EDEC_HEADER_ID = aEdecHeaderID
         and DEA.C_EDEC_ADDRESS_TYPE = '3';
    exception
      when no_data_found then
        null;
    end;

    select DEA.*
      into tplAddress5
      from DOC_EDEC_ADDRESSES DEA
     where DEA.DOC_EDEC_HEADER_ID = aEdecHeaderID
       and DEA.C_EDEC_ADDRESS_TYPE = '5';

    if tplHeader.doc_document_id is not null then
      select dmt.*
        into tplDocument
        from doc_document dmt
       where dmt.doc_document_id = tplHeader.doc_document_id;
    else
      select pal.*
        into tplPacking
        from doc_packing_list pal
       where pal.doc_packing_list_id = tplHeader.doc_packing_list_id;
    end if;

    vHeader.H1.H1MANR                   := '001';
    vHeader.H1.H1ARNR                   := tplHeader.DEH_TRADER_DECLARATION_NUMBER;
    vHeader.H1.H1ARDA                   := sysdate;   -- !!
    -- H1

    -- destinataire de la facture
    vHeader.H1.H1KDUI                   := '';   -- !!
    vHeader.H1.H1KNAME1                 := tplAddress1.DEA_NAME;
    vHeader.H1.H1KNAME4                 := tplAddress1.DEA_STREET;
    vHeader.H1.H1KSTR1                  := tplAddress1.DEA_ADDRESS_SUPPLEMENT_1;
    vHeader.H1.H1KSTR2                  := tplAddress1.DEA_ADDRESS_SUPPLEMENT_2;
    vHeader.H1.H1KPLZ                   := tplAddress1.DEA_POSTAL_CODE;
    vHeader.H1.H1KORT                   := GetCountryCode(tplAddress1.PC_CNTRY_ID) || '-' || tplAddress1.DEA_POSTAL_CODE || ' ' || tplAddress1.DEA_CITY;
    vHeader.H1.H1KLANDISO               := GetCountryCode(tplAddress1.PC_CNTRY_ID);
    -- destinataire de la marchandise
    vHeader.H1.H1LRUI                   := '';   -- !!
    vHeader.H1.H1LNAME1                 := tplAddress5.DEA_NAME;
    vHeader.H1.H1LNAME4                 := tplAddress5.DEA_STREET;
    vHeader.H1.H1LSTR1                  := tplAddress5.DEA_ADDRESS_SUPPLEMENT_1;
    vHeader.H1.H1LSTR2                  := tplAddress5.DEA_ADDRESS_SUPPLEMENT_2;
    vHeader.H1.H1LPLZ                   := tplAddress5.DEA_POSTAL_CODE;
    vHeader.H1.H1LORT                   := GetCountryCode(tplAddress5.PC_CNTRY_ID) || '-' || tplAddress5.DEA_POSTAL_CODE || ' ' || tplAddress5.DEA_CITY;
    vHeader.H1.H1LLANDISO               := GetCountryCode(tplAddress5.PC_CNTRY_ID);
    vHeader.H1.H1BSLDISO                := '';
    vHeader.H1.H1EDECVERSENDERREFERENZ  := '';   -- !!
    vHeader.H1.H1EDECSPEDDOSSIERNR      := case
                                            when tplHeader.doc_document_id is null then tplPacking.pal_number
                                            else tplDocument.dmt_number
                                          end;
    vHeader.H1.H1ICCD                   := tplHeader.c_incoterms;
    vHeader.H1.H1ICOR                   := '';   -- !!
    vHeader.H1.H1SPRACHCODE             := getLangCode(nvl(tplPacking.pc_lang_id, tplDocument.pc_lang_id) );
    vHeader.H1.H1VSAART                 :=
                                       case
                                         when tplHeader.doc_document_id is null then tplPacking.pac_sending_condition_id
                                         else tplDocument.pac_sending_condition_id
                                       end;
    vHeader.H1.H1EDECVERKEHRSWEIG       := tplHeader.c_edec_transport_mode;
    vHeader.H1.H1EDECBEFMITTELLANDISO   := GetCountryCode(tplHeader.DEH_TRANSPORTATION_PC_CNTRY_ID);
    vHeader.H1.H1EDECBEFMITTELKENNZ     := tplHeader.DEH_TRANSPORTATION_NUMBER;
    vHeader.H1.H1ZBED                   := case
                                            when tplHeader.doc_document_id is null then null
                                            else tplDocument.pac_payment_condition_id
                                          end;   -- !!
    vHeader.H1.H1RECHBETRAG_LW          := case
                                            when tplHeader.doc_document_id is null then -1
                                            else tplDocFoot.FOO_DOCUMENT_TOT_AMOUNT_B
                                          end;
    vHeader.H1.H1RECHBETRAG_FW          := case
                                            when tplHeader.doc_document_id is null then -1
                                            else tplDocFoot.FOO_DOCUMENT_TOTAL_AMOUNT
                                          end;
    vHeader.H1.H1WACD                   := 'CHF';   -- !!
    vHeader.H1.H1KURS                   := 1;   -- !!
    vHeader.H1.H1KUDI                   := 1;
    vHeader.H1.H1GWNE                   := null;
    vHeader.H1.H1GWBR                   := null;
    -- expéditeur
    vHeader.H1.H1SNAME1                 := tplAddress3.DEA_NAME;
    vHeader.H1.H1SNAME4                 := tplAddress3.DEA_STREET;
    vHeader.H1.H1SSTR1                  := tplAddress3.DEA_ADDRESS_SUPPLEMENT_1;
    vHeader.H1.H1SSTR2                  := tplAddress3.DEA_ADDRESS_SUPPLEMENT_2;
    vHeader.H1.H1SPLZ                   := tplAddress3.DEA_POSTAL_CODE;
    vHeader.H1.H1SORT                   := GetCountryCode(tplAddress3.PC_CNTRY_ID) || '-' || tplAddress3.DEA_POSTAL_CODE || ' ' || tplAddress3.DEA_CITY;
    vHeader.H1.H1SLANDISO               := GetCountryCode(tplAddress3.PC_CNTRY_ID);
    vHeader.H1.H1MWSTBETRAG             := 0;   -- !!
    vHeader.H1.H1MWSTPROZENT            := 0;   -- !!
    -- HV
    vHeader.HV.H1EDECBESCHWERDE         := case
                                            when tplHeader.doc_document_id is null then getAllDmtNumber(tplHeader.doc_packing_list_id)
                                            else tplDocument.dmt_number
                                          end;
    vPosCpt1                            := 0;

    for tplPosition in (select dep.C_EDEC_COMMERCIAL_GOOD
                             , dep.C_EDEC_CUSTOMS_CLEARANCE_TYPE
                             , dep.C_EDEC_PERMIT_OBLIGATION
                             , dep.C_EDEC_PREFERENCE
                             , dep.DEP_ADDITIONAL_UNIT
                             , dep.DEP_COMMODITY_CODE
                             , dep.DEP_CUSTOMS_NET_WEIGHT
                             , dep.DEP_DESCRIPTION
                             , dep.DEP_GROSS_MASS
                             , dep.DEP_NET_MASS
                             , dep.DEP_ORIGIN_PC_CNTRY_ID
                             , dep.DEP_POS_NUMBER
                             , dep.DEP_SEAL_NUMBER
                             , dep.DEP_STATISTICAL_CODE
                             , dep.DEP_STATISTICAL_VALUE
                             , dep.DOC_EDEC_HEADER_ID
                             , dep.DOC_EDEC_POSITION_ID
                             , goo.goo_major_reference
                             , cleanstr(pos.pos_long_description) pos_long_description
                             , pos.pos_final_quantity
                             , pos.dic_unit_of_measure_id
                             , pos.pos_net_weight
                             , pos.pos_gross_weight
                             , POS.POS_NET_VALUE_INCL
                             , POS.POS_NET_VALUE_INCL_B
                             , dmt.dmt_number
                             , nvl(DMT.DMT_DATE_DELIVERY, DMT.DMT_DATE_DOCUMENT) as DOCUMENT_DATE
                          from doc_edec_position dep
                             , doc_edec_position_detail det
                             , doc_position pos
                             , doc_document dmt
                             , gco_good goo
                         where dep.doc_edec_header_id = aEdecHeaderID
                           and dep.doc_edec_position_id = det.doc_edec_position_id
                           and det.doc_position_id = pos.doc_position_id
                           and pos.gco_good_id = goo.gco_good_id
                           and pos.doc_document_id = dmt.doc_document_id) loop
      vPosCpt1                                         := vPosCpt1 + 1;
      vTblPositions(vPosCpt1).P1.P1RENR                := tplHeader.DEH_TRADER_DECLARATION_NUMBER;
      vTblPositions(vPosCpt1).P1.P1REPOK               := tplPosition.DEP_POS_NUMBER;
      vTblPositions(vPosCpt1).P1.P1ATNR                := tplPosition.goo_major_reference;
      vTblPositions(vPosCpt1).P1.P1BEZ1                := substr(tplPosition.pos_long_description, 1, 35);
      vTblPositions(vPosCpt1).P1.P1BEZ2                := substr(tplPosition.pos_long_description, 36, 35);
      vTblPositions(vPosCpt1).P1.P1BEZ3                := substr(tplPosition.pos_long_description, 71, 35);
      vTblPositions(vPosCpt1).P1.P1BEZ4                := substr(tplPosition.pos_long_description, 106, 35);
      vTblPositions(vPosCpt1).P1.P1BEZ5                := substr(tplPosition.pos_long_description, 141, 35);
      vTblPositions(vPosCpt1).P1.P1ZUSP                := getCountryCode(tplPosition.dep_origin_pc_cntry_id);
      vTblPositions(vPosCpt1).P1.P1MEAF                := tplPosition.pos_final_quantity;
      vTblPositions(vPosCpt1).P1.P1MHAF                := tplPosition.dic_unit_of_measure_id;
      vTblPositions(vPosCpt1).P1.P1MENGENEINHEIT       := 1;   -- !!
      vTblPositions(vPosCpt1).P1.P1GWEN                :=
                                                tplPosition.pos_net_weight / case
                                                  when tplPosition.pos_final_quantity = 0 then 1
                                                  else tplPosition.pos_final_quantity
                                                end;
      vTblPositions(vPosCpt1).P1.P1GWPN                := tplPosition.pos_net_weight;
      vTblPositions(vPosCpt1).P1.P1EPLW                :=
                                          tplPosition.pos_net_value_incl_b / case
                                            when tplPosition.pos_final_quantity = 0 then 1
                                            else tplPosition.pos_final_quantity
                                          end;
      vTblPositions(vPosCpt1).P1.P1PWLW                := tplPosition.pos_net_value_incl_b;
      vTblPositions(vPosCpt1).P1.P1EPFW                :=
                                            tplPosition.pos_net_value_incl / case
                                              when tplPosition.pos_final_quantity = 0 then 1
                                              else tplPosition.pos_final_quantity
                                            end;
      vTblPositions(vPosCpt1).P1.P1PWFW                := tplPosition.pos_net_value_incl;
      --
      vTblPositions(vPosCpt1).P1.P1EDECVERANLAGUNGTYP  := tplPosition.C_EDEC_CUSTOMS_CLEARANCE_TYPE;
      vTblPositions(vPosCpt1).P1.P1EDECHANDELSWARE     := tplPosition.C_EDEC_COMMERCIAL_GOOD;
      vTblPositions(vPosCpt1).P1.P1EDECRUECKERSTTYP    := null;   -- Pas de correspondance dans l'ERP
      -- Permis pour la position
      lnPermitID                                       := getEdecPermitID(tplPosition.DOC_EDEC_POSITION_ID, tplPosition.DOCUMENT_DATE);

      if lnPermitID is null then
        vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGTYP      := null;
        vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGPFLICHT  := null;   -- Pas de correspondance dans l'ERP
        vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGSTELLE   := null;
        vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGNUMMER   := null;
        vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGDATUM    := null;
        vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGZUSATZ   := null;
      else
        select C_EDEC_PERMIT_TYPE
             , null
             , C_EDEC_PERMIT_AUTHORITY
             , DEP_PERMIT_NUMBER
             , DEP_ISSUE_DATE
             , DEP_ADDITIONAL_INFORMATION
          into vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGTYP
             , vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGPFLICHT   -- Pas de correspondance dans l'ERP
             , vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGSTELLE
             , vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGNUMMER
             , vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGDATUM
             , vTblPositions(vPosCpt1).P1.P1EDECBEWILLIGZUSATZ
          from DOC_EDEC_PERMIT
         where DOC_EDEC_PERMIT_ID = lnPermitID;
      end if;

      --
      vTblPositions(vPosCpt1).P1.P1WNR1                := tplPosition.DEP_COMMODITY_CODE;
      vTblPositions(vPosCpt1).P1.P1SCHLUESSEL          := tplPosition.DEP_STATISTICAL_CODE;
      vTblPositions(vPosCpt1).P1.P1EDECZUSATZMENGE     := 0;   -- !!
      vTblPositions(vPosCpt1).P1.P1SRENR               := tplPosition.dmt_number;
    end loop;
  end pInitializeData;

  /**
  * procedure InitializeData
  * Description
  *   Initialisation des données des éléments Master Data et Line Item
  *   en fonction de la déclaration EDEC passée en param
  */
  procedure InitializeData(aEdecHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, aEdiTypeID in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type)
  is
    vPackageName  DOC_EDI_TYPE_PARAM.DEP_VALUE%type;
    lv_errorMsg   varchar2(32000);
    lv_exp_method doc_edi_type.det_name%type;
  begin
    -- initialisation des données de l'en-tête
    -- recherche d'une procédure individualisée d'initialisation
    select max(det.det_name)
      into lv_exp_method
      from doc_edi_type det
     where det.doc_edi_type_id = aEdiTypeId;

    vPackageName  :=
                 nvl(doc_edi_function.getparamvalue('EXPORT_PACKAGE', aEdiTypeID), doc_edi_function.getparamvalue('EXPORT_PACKAGE.INITIALIZEDATA', aEdiTypeID) );

    if vPackageName is not null then
      begin
        -- exécution de la procédure individualisée
        execute immediate 'begin' || chr(10) || '  ' || vPackageName || '.InitializeData(:aEdecHeaderID,:aEdiTypeID);' || chr(10) || 'end;'
                    using in aEdecHeaderID, in aEdiTypeID;
      exception
        when others then
          lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0001');
          lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
          lv_errorMsg  := replace(lv_errorMsg, '%p2', 'EXPORT_PACKAGE.INITIALIZEDATA');
          lv_errorMsg  := replace(lv_errorMsg, '%p3', vPackageName || '.INITIALIZEDATA');
          lv_errorMsg  := lv_errorMsg || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('EDEC-0003') || ': ';
          lv_errorMsg  := lv_errorMsg || DBMS_UTILITY.format_error_backtrace;
          pcs.ra(substr(lv_errorMsg, 1, 4000) );
      end;
    else
      -- procédure standard
      pInitializeData(aEdecHeaderID, aEdiTypeID);
    end if;
  end InitializeData;

  /**
  * function pCreateEdecExportJob
  * Description
  *   Création du job d'exportation dans la table DOC_EDI_EXPORT_JOB en fonction
  *   de la déclaration EDEC et du type d'export EDI passé en param
  */
  function pCreateEdecExportJob(
    aEdecHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aEdiTypeID    in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type
  , aFilename     in DOC_EDI_EXPORT_JOB.DIJ_FILENAME%type
  )
    return DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  is
    vJobID       DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type;
    vFileName    DOC_EDI_EXPORT_JOB.DIJ_FILENAME%type;
    vDescription DOC_EDI_EXPORT_JOB.DIJ_DESCRIPTION%type;
  begin
    vFilename  := aFilename;

    -- Description et nom du fichier pour l'export
    select DEH.DEH_TRADER_DECLARATION_NUMBER || ' - ' || DET.DET_NAME
         , nvl(vFileName, DEH.DEH_TRADER_DECLARATION_NUMBER || '.txt')
      into vDescription
         , vFileName
      from DOC_EDEC_HEADER DEH
         , DOC_EDI_TYPE DET
     where DEH.DOC_EDEC_HEADER_ID = aEdecHeaderID
       and DET.DOC_EDI_TYPE_ID = aEdiTypeID;

    -- Création du job d'exportation
    vJobID     := DOC_EDI_EXPORT_JOB_FUNCTIONS.CreateExportJob(aFileName => vFileName, aDescription => vDescription, aEdiTypeID => aEdiTypeID);
    return vJobID;
  end pCreateEdecExportJob;

  /**
  * function CreateEdecExportJob
  * Description
  *   Création du job d'exportation dans la table DOC_EDI_EXPORT_JOB en fonction
  *   de la déclaration EDEC et du type d'export EDI passé en param
  */
  function CreateEdecExportJob(aEdecHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, aEdiTypeID in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type)
    return DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  is
    vPackageName DOC_EDI_TYPE_PARAM.DEP_VALUE%type;
    vFilename    varchar2(255);
  begin
    -- recherche d'une procédure individualisée d'initialisation
    vPackageName  :=
                   nvl(DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE', aEdiTypeID), DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE.GETFILENAME', aEdiTypeID) );

    if vPackageName is not null then
      begin
        -- exécution de la procédure individualisée
        execute immediate 'begin' || chr(10) || '  ' || vPackageName || '.getFilename (:aEdecHeaderID,:aEdiTypeID, :vFilename);' || chr(10) || 'end;'
                    using in aEdecHeaderID, in aEdiTypeID, out vFilename;
      exception
        when others then
          raise_application_error(-20000, 'PCS - ' || vPackageName || '.getFilename [' || sqlerrm || ' ]');
      end;
    else
      -- procédure standard
      getFilename(aEdecHeaderID, aEdiTypeID, vFilename);
    end if;

    -- procédure standard
    return pCreateEdecExportJob(aEdecHeaderID, aEdiTypeID, vFilename);
  end CreateEdecExportJob;

  /**
  * procedure GenerateHeader
  * Description
  *   Création de l'entête de la déclaration EDEC
  */
  procedure GenerateHeader(
    aHeaderID      out    DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPackingListID in     DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type default null
  )
  is
    vHeaderNumber DOC_EDEC_HEADER.DEH_TRADER_DECLARATION_NUMBER%type   default null;
    vLangID       DOC_EDEC_HEADER.PC_LANG_ID%type                      default null;
    vTranspMode   DOC_EDEC_HEADER.C_EDEC_TRANSPORT_MODE%type           default null;
    vIncoterms    DOC_EDEC_HEADER.C_INCOTERMS%type                     default null;
  begin
    aHeaderID      := null;
    -- Numérotation de l'entête de la déclaration EDEC
    vHeaderNumber  := DOC_EDEC_UTILITY_FUNCTIONS.GetNewHeaderNumber;

    -- Si on n'as pas reçu de n° de déclaration, on arrête la création
    if vHeaderNumber is not null then
      select INIT_ID_SEQ.nextval
        into aHeaderID
        from dual;

      -- Données pour l'interface EDEC à rechercher au niveau d'un document (DOC_DOCUMENT)
      if aDocumentID is not null then
        begin
          select DMT.PC_LANG_ID
               , nvl(SEN.C_CONDITION_MODE, '3')
               , DMT.C_INCOTERMS
            into vLangID
               , vTranspMode
               , vIncoterms
            from DOC_DOCUMENT DMT
               , PAC_SENDING_CONDITION SEN
           where DMT.DOC_DOCUMENT_ID = aDocumentID
             and DMT.PAC_SENDING_CONDITION_ID = SEN.PAC_SENDING_CONDITION_ID(+);
        exception
          when no_data_found then
            null;
        end;
      -- Données pour l'interface EDEC à rechercher au niveau d'un envoi (DOC_PACKING_LIST)
      elsif aPackingListID is not null then
        begin
          select PAL.PC_LANG_ID
               , nvl(SEN.C_CONDITION_MODE, '3')
               , PAL.C_INCOTERMS
            into vLangID
               , vTranspMode
               , vIncoterms
            from DOC_PACKING_LIST PAL
               , PAC_SENDING_CONDITION SEN
           where PAL.DOC_PACKING_LIST_ID = aPackingListID
             and PAL.PAC_SENDING_CONDITION_ID = SEN.PAC_SENDING_CONDITION_ID(+);
        exception
          when no_data_found then
            null;
        end;
      end if;

      -- insertion finale
      insert into DOC_EDEC_HEADER
                  (DOC_EDEC_HEADER_ID
                 , DEH_TRADER_DECLARATION_NUMBER
                 , DOC_DOCUMENT_ID
                 , DOC_PACKING_LIST_ID
                 , C_EDEC_SERVICE_TYPE
                 , C_EDEC_STATUS
                 , DEH_TRANSFER_TO_TRANSIT_SYSTEM
                 , DEH_TRANSPORT_IN_CONTAINER
                 , PC_LANG_ID
                 , C_EDEC_TRANSPORT_MODE
                 , C_INCOTERMS
                 , A_DATECRE
                 , A_IDCRE
                  )
        select aHeaderID
             , vHeaderNumber
             , aDocumentID
             , aPackingListID
             , '1'
             , '01'
             , 0
             , 0
             , vLangID
             , vTranspMode
             , vIncoterms
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from dual;

      -- Création des adresses de l'entête de la déclaration EDEC
      DOC_EDI_EDEC_EXPOWIN_V4.GenerateAddresses(aHeaderID => aHeaderID);
    end if;
  end GenerateHeader;

  /**
  * procedure ReinitializeHeader
  * Description
  *   Màj des données de l'entête et création des adresses
  */
  procedure ReinitializeHeader(
    aHeaderID      in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPackingListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type default null
  )
  is
    vHeaderNumber DOC_EDEC_HEADER.DEH_TRADER_DECLARATION_NUMBER%type   default null;
    vLangID       DOC_EDEC_HEADER.PC_LANG_ID%type                      default null;
    vTranspMode   DOC_EDEC_HEADER.C_EDEC_TRANSPORT_MODE%type           default null;
    vIncoterms    DOC_EDEC_HEADER.C_INCOTERMS%type                     default null;
  begin
    if aHeaderID is not null then
      -- Données pour l'interface EDEC à rechercher au niveau d'un document (DOC_DOCUMENT)
      if aDocumentID is not null then
        begin
          select DMT.PC_LANG_ID
               , SEN.C_CONDITION_MODE
               , DMT.C_INCOTERMS
            into vLangID
               , vTranspMode
               , vIncoterms
            from DOC_DOCUMENT DMT
               , PAC_SENDING_CONDITION SEN
           where DMT.DOC_DOCUMENT_ID = aDocumentID
             and DMT.PAC_SENDING_CONDITION_ID = SEN.PAC_SENDING_CONDITION_ID(+);
        exception
          when no_data_found then
            null;
        end;
      -- Données pour l'interface EDEC à rechercher au niveau d'un envoi (DOC_PACKING_LIST)
      elsif aPackingListID is not null then
        begin
          select PAL.PC_LANG_ID
               , SEN.C_CONDITION_MODE
               , PAL.C_INCOTERMS
            into vLangID
               , vTranspMode
               , vIncoterms
            from DOC_PACKING_LIST PAL
               , PAC_SENDING_CONDITION SEN
           where PAL.DOC_PACKING_LIST_ID = aPackingListID
             and PAL.PAC_SENDING_CONDITION_ID = SEN.PAC_SENDING_CONDITION_ID(+);
        exception
          when no_data_found then
            null;
        end;
      end if;

      -- insertion finale
      update DOC_EDEC_HEADER
         set DOC_DOCUMENT_ID = aDocumentID
           , DOC_PACKING_LIST_ID = aPackingListID
           , C_EDEC_SERVICE_TYPE = '1'
           , C_EDEC_STATUS = '01'
           , DEH_TRANSFER_TO_TRANSIT_SYSTEM = 0
           , DEH_TRANSPORT_IN_CONTAINER = 0
           , PC_LANG_ID = vLangID
           , C_EDEC_TRANSPORT_MODE = vTranspMode
           , C_INCOTERMS = vIncoterms
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_EDEC_HEADER_ID = aHeaderID;

      -- Effacement des adresses
      DOC_EDEC_UTILITY_FUNCTIONS.DeleteEdecAddresses(aHeaderID);
      -- Création des adresses de l'entête de la déclaration EDEC
      DOC_EDI_EDEC_EXPOWIN_V4.GenerateAddresses(aHeaderID => aHeaderID);
    end if;
  end ReinitializeHeader;

  /**
  * procedure DischargePositions
  * Description
  *    Création des positions EDEC par décharge d'un document (DOC_DOCUMENT) ou
  *      par décharge des positions liées à un envoi (DOC_PACKING_LIST)
  */
  procedure DischargePositions(
    aHeaderID      in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPackingListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type default null
  )
  is
    vNewPosID             DOC_EDEC_POSITION.DOC_EDEC_POSITION_ID%type;
    vPosNumber            DOC_EDEC_POSITION.DEP_POS_NUMBER%type;
    vCfg_PackingType      DIC_PACKING_TYPE.DIC_PACKING_TYPE_ID%type;
    vPackingTypeID        DIC_PACKING_TYPE.DIC_PACKING_TYPE_ID%type;
    bExists               boolean;
    iCpt                  integer;
    vCfg_PermitObligation GCO_CUSTOMS_ELEMENT.C_EDEC_PERMIT_OBLIGATION%type;
    vCfg_CommercialGood   GCO_CUSTOMS_ELEMENT.C_EDEC_COMMERCIAL_GOOD%type;
    vCntryID              PCS.PC_CNTRY.PC_CNTRY_ID%type;
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'DOC_POSITION_ID';

    -- La source des données = DOC_DOCUMENT
    if aDocumentID is not null then
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct DOC_POSITION_ID
                      , 'DOC_POSITION_ID'
                   from DOC_POSITION
                  where DOC_DOCUMENT_ID = aDocumentID
                    and C_GAUGE_TYPE_POS in('1', '7', '8', '9', '10');

      -- Définition du pays pour l'export
      -- Pays de livraison ou pays de facturation
      select nvl(PC__PC_CNTRY_ID, PC_2_PC_CNTRY_ID)
        into vCntryID
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aDocumentID;
    else
      -- La source des données = DOC_PACKING_LIST
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct POS.DOC_POSITION_ID
                      , 'DOC_POSITION_ID'
                   from DOC_PACKING_PARCEL_POS PAP
                      , DOC_POSITION POS
                  where PAP.DOC_PACKING_LIST_ID = aPackingListID
                    and PAP.DOC_POSITION_ID = POS.DOC_POSITION_ID
                    and POS.C_GAUGE_TYPE_POS in('1', '7', '8', '9', '10');

      -- Définition du pays pour l'export
      -- Pays de livraison ou pays de facturation
      select nvl(PC__PC_CNTRY_ID, PC_2_PC_CNTRY_ID)
        into vCntryID
        from DOC_PACKING_LIST
       where DOC_PACKING_LIST_ID = aPackingListID;
    end if;

    -- Configs
    vCfg_PackingType       := PCS.PC_CONFIG.GetConfig('DOC_EDEC_DEFAULT_PACKING_TYPE');
    vCfg_PermitObligation  := PCS.PC_CONFIG.GetConfig('GCO_CUSTOMS_PERMIT_OBLIGATION');
    vCfg_CommercialGood    := PCS.PC_CONFIG.GetConfig('GCO_CUSTOMS_COMMERCIAL_GOOD');

    -- Liste des positions EDEC à créer
    for tplPos in (select substr(CUS.CUS_CUSTONS_POSITION, 1, 9) CUS_CUSTONS_POSITION
                        , CUS.CUS_KEY_TARIFF
                        , nvl(CUS.C_EDEC_PERMIT_OBLIGATION, vCfg_PermitObligation) C_EDEC_PERMIT_OBLIGATION
                        , nvl(CUS.C_EDEC_COMMERCIAL_GOOD, vCfg_CommercialGood) C_EDEC_COMMERCIAL_GOOD
                        , CUS.PC_ORIGIN_PC_CNTRY_ID
                        , CUS.C_EDEC_PREFERENCE
                        , CUS.DIC_UNIT_OF_MEASURE_ID
                        , CUS.C_EDEC_CUSTOMS_CLEARANCE_TYPE
                        , CUS.C_EDEC_NON_CUSTOMS_LAW_OBLIG
                        , CUS.GCO_CUSTOMS_ELEMENT_ID
                        , nvl(POS.POS_GROSS_WEIGHT, 0) POS_GROSS_WEIGHT
                        , nvl(POS.POS_NET_WEIGHT, 0) POS_NET_WEIGHT
                        , nvl(POS.POS_FINAL_QUANTITY_SU, 0) * nvl(CUS.CUS_CONVERSION_FACTOR, 1) DEP_ADDITIONAL_UNIT
                        , nvl(POS.POS_NET_VALUE_INCL, 0) POS_NET_VALUE_INCL
                        , POS_LIST.DOC_POSITION_ID
                     from (select COM_LIST_ID_TEMP_ID as DOC_POSITION_ID
                             from COM_LIST_ID_TEMP
                            where LID_CODE = 'DOC_POSITION_ID') POS_LIST
                        , DOC_POSITION POS
                        , table(DOC_EDEC_UTILITY_FUNCTIONS.GetCustomsElement(vCntryID) ) CUS
                    where POS.DOC_POSITION_ID = POS_LIST.DOC_POSITION_ID
                      and POS.GCO_GOOD_ID = CUS.GCO_GOOD_ID) loop
      select INIT_ID_SEQ.nextval
        into vNewPosID
        from dual;

      -- N° de la position EDEC
      vPosNumber  := DOC_EDEC_UTILITY_FUNCTIONS.GetNextPosNumber(aHeaderID);

      insert into DOC_EDEC_POSITION
                  (DOC_EDEC_POSITION_ID
                 , DOC_EDEC_HEADER_ID
                 , DEP_POS_NUMBER
                 , DEP_DESCRIPTION
                 , DEP_COMMODITY_CODE
                 , DEP_STATISTICAL_CODE
                 , DEP_SEAL_NUMBER
                 , DEP_GROSS_MASS
                 , DEP_NET_MASS
                 , DEP_CUSTOMS_NET_WEIGHT
                 , DEP_ADDITIONAL_UNIT
                 , C_EDEC_PERMIT_OBLIGATION
                 , C_EDEC_CUSTOMS_CLEARANCE_TYPE
                 , C_EDEC_COMMERCIAL_GOOD
                 , DEP_STATISTICAL_VALUE
                 , DEP_ORIGIN_PC_CNTRY_ID
                 , C_EDEC_PREFERENCE
                 , C_EDEC_NON_CUSTOMS_LAW_OBLIG
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vNewPosID
             , aHeaderID
             , vPosNumber
             , vPosNumber
             , tplPos.CUS_CUSTONS_POSITION
             , tplPos.CUS_KEY_TARIFF
             , null
             , tplPos.POS_GROSS_WEIGHT
             , tplPos.POS_NET_WEIGHT
             , null
             , tplPos.DEP_ADDITIONAL_UNIT
             , tplPos.C_EDEC_PERMIT_OBLIGATION
             , tplPos.C_EDEC_CUSTOMS_CLEARANCE_TYPE
             , tplPos.C_EDEC_COMMERCIAL_GOOD
             , tplPos.POS_NET_VALUE_INCL
             , tplPos.PC_ORIGIN_PC_CNTRY_ID
             , tplPos.C_EDEC_PREFERENCE
             , tplPos.C_EDEC_NON_CUSTOMS_LAW_OBLIG
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from dual;

      -- Insertion des détails de position EDEC (DOC_EDEC_POSITION_DETAIL)
      insert into DOC_EDEC_POSITION_DETAIL
                  (DOC_EDEC_POSITION_DETAIL_ID
                 , DOC_EDEC_POSITION_ID
                 , DOC_POSITION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , vNewPosID
             , tplPos.doc_position_id
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from dual;

      -- Insertion des permis
      insert into DOC_EDEC_PERMIT
                  (DOC_EDEC_PERMIT_ID
                 , DOC_EDEC_POSITION_ID
                 , DEP_PERMIT_NUMBER
                 , DEP_ISSUE_DATE
                 , DEP_ADDITIONAL_INFORMATION
                 , C_EDEC_PERMIT_TYPE
                 , C_EDEC_PERMIT_AUTHORITY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , vNewPosID
             , DEP_PERMIT_NUMBER
             , DEP_ISSUE_DATE
             , DEP_ADDITIONAL_INFORMATION
             , C_EDEC_PERMIT_TYPE
             , C_EDEC_PERMIT_AUTHORITY
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from GCO_CUSTOMS_PERMIT
         where GCO_CUSTOMS_ELEMENT_ID = tplPos.GCO_CUSTOMS_ELEMENT_ID;
    end loop;

    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'DOC_POSITION_ID';
  end DischargePositions;
end DOC_EDI_EDEC_EXPOWIN_V4;
