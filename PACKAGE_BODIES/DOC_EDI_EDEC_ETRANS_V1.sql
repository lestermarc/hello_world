--------------------------------------------------------
--  DDL for Package Body DOC_EDI_EDEC_ETRANS_V1
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_EDEC_ETRANS_V1" 
is
  type tPackingType is record(
    DIC_PACKING_TYPE_ID DIC_PACKING_TYPE.DIC_PACKING_TYPE_ID%type
  );

  type ttblPackingType is table of tPackingType
    index by binary_integer;

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
    vJobID       := CreateEdecExportJob(aEdecHeaderID => aEdecHeaderID, aEdiTypeID => aEdiTypeID);
    -- Initialisation des données des éléments Master Data et Line Item
    -- en fonction de la déclaration EDEC passée en param
    vMasterData  := null;
    vTblLineItem.delete;
    InitializeData(aEdecHeaderID => aEdecHeaderID, aEdiTypeID => aEdiTypeID);
    -- Insertion des données d'export relatives à l'élément Master Data
    DOC_EDI_ETRANS_FMT_V1.Write_tMasterData(aExportJobID => vJobID, aMasterData => vMasterData);
    -- Insertion des données d'export relatives aux éléments Line Item
    DOC_EDI_ETRANS_FMT_V1.Write_ttblLineItem(aExportJobID => vJobID, aTblLineItem => vTblLineItem);
    -- Envoi du job d'export dans les table du système d'échange de données
    DOC_EDI_EXPORT_JOB_FUNCTIONS.SendJobToPcExchange(aExportJobID => vJobID, aErrorMsg => aErrorMsg);
  end GenerateExport;

  /**
  * procedure pInitializeData
  * Description
  *   procédure interne
  *
  *   Initialisation des données des éléments Master Data et Line Item
  *   en fonction de la déclaration EDEC passée en param
  */
  procedure pInitializeData(aEdecHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, aEdiTypeID in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type)
  is
    tplHeader   DOC_EDEC_HEADER%rowtype;
    tplAddress1 DOC_EDEC_ADDRESSES%rowtype;
    tplAddress3 DOC_EDEC_ADDRESSES%rowtype;
    vIndex      number;

    function GetCountryCode(aPC_CNTRY_ID PCS.PC_CNTRY.PC_CNTRY_ID%type)
      return PCS.PC_CNTRY.CNTID%type
    is
      lvCntID PCS.PC_CNTRY.CNTID%type;
    begin
      select max(CNTID)
        into lvCntID
        from PCS.PC_CNTRY
       where PC_CNTRY_ID = aPC_CNTRY_ID;

      return lvCntID;
    end GetCountryCode;
  begin
    -- initialisation des données de l'en-tête
    select *
      into tplHeader
      from DOC_EDEC_HEADER
     where DOC_EDEC_HEADER_ID = aEdecHeaderID;

    /* Consignee_Address */
    begin
      select *
        into tplAddress1
        from DOC_EDEC_ADDRESSES
       where DOC_EDEC_HEADER_ID = aEdecHeaderId
         and C_EDEC_ADDRESS_TYPE = '1';

      vMasterData.Consignee_Address.Line1         := tplAddress1.DEA_ADDRESS_SUPPLEMENT_1;
      vMasterData.Consignee_Address.Line2         := tplAddress1.DEA_ADDRESS_SUPPLEMENT_2;
      vMasterData.Consignee_Address.Country_Code  := GetCountryCode(tplAddress1.PC_CNTRY_ID);
      vMasterData.Consignee_Address.name          := tplAddress1.DEA_NAME;
      vMasterData.Consignee_Address.Place         := tplAddress1.DEA_CITY;
      vMasterData.Consignee_Address.Street        := tplAddress1.DEA_STREET;
      vMasterData.Consignee_Address.Zip_Code      := tplAddress1.DEA_POSTAL_CODE;
    exception
      when no_data_found then
        null;
    end;

    /* Forwarder_Address */
    begin
      select *
        into tplAddress3
        from DOC_EDEC_ADDRESSES
       where DOC_EDEC_HEADER_ID = aEdecHeaderId
         and C_EDEC_ADDRESS_TYPE = '3';

      vMasterData.Forwarder_Address.Line1         := tplAddress3.DEA_ADDRESS_SUPPLEMENT_1;
      vMasterData.Forwarder_Address.Line2         := tplAddress3.DEA_ADDRESS_SUPPLEMENT_2;
      vMasterData.Forwarder_Address.Country_Code  := GetCountryCode(tplAddress3.PC_CNTRY_ID);
      vMasterData.Forwarder_Address.name          := tplAddress3.DEA_NAME;
      vMasterData.Forwarder_Address.Place         := tplAddress3.DEA_CITY;
      vMasterData.Forwarder_Address.Street        := tplAddress3.DEA_STREET;
      vMasterData.Forwarder_Address.Zip_Code      := tplAddress3.DEA_POSTAL_CODE;
    exception
      when no_data_found then
        null;
    end;

    /* Master_Data */
    vMasterData.TOrder.Order_Number            := tplHeader.DEH_TRADER_DECLARATION_NUMBER;
    vMasterData.TOrder.Order_Type              := 0;
    vMasterData.TOrder.Order_Date              := sysdate;
    vMasterData.TOrder.Forwarder_Name          := vMasterData.Forwarder_Address.name;
    vMasterData.TOrder.Country_of_Destination  := GetCountryCode(tplHeader.DEH_DELIVERY_DEST_PC_CNTRY_ID);
    vMasterData.TOrder.Mode_of_Delivery        := tplHeader.C_EDEC_TRANSPORT_MODE;
    vMasterData.TOrder.Place_of_Destination    := tplHeader.DEH_PLACE_OF_UNLOADING;   --lieu de destination des marchandises
    vMasterData.TOrder.Mode_of_Dispatch        := tplHeader.C_EDEC_TRANSPORT_MODE;
    vMasterData.TOrder.Incoterm                := tplHeader.C_INCOTERMS;
    vMasterData.TOrder.Place_of_Incoterm       := tplHeader.DEH_PLACE_OF_LOADING;

    select substr(max(DMT_NUMBER), 1, 50)
      into vMasterData.TOrder.Internal_Order_Number
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = tplHeader.DOC_DOCUMENT_ID;

    if vMasterData.TOrder.Internal_Order_Number is null then
      select substr(max(PAL_NUMBER), 1, 50)
        into vMasterData.TOrder.Internal_Order_Number
        from DOC_PACKING_LIST
       where DOC_PACKING_LIST_ID = tplHeader.DOC_PACKING_LIST_ID;
    end if;

    -- initialisation des données de lignes
    for tplLineItem in (select *
                          from DOC_EDEC_POSITION
                         where DOC_EDEC_HEADER_ID = aEdecHeaderId) loop
      vIndex                                               := vTblLineItem.count + 1;
      /* vTblLineItem.Article */
      vTblLineItem(vIndex).Article.Order_Number            := vMasterData.TOrder.Order_Number;
      vTblLineItem(vIndex).Article.Country_of_Destination  := vMasterData.TOrder.Country_of_Destination;
      vTblLineItem(vIndex).Article.Country_of_Origin       := GetCountryCode(tplLineItem.DEP_ORIGIN_PC_CNTRY_ID);
      vTblLineItem(vIndex).Article.Customs_Tariff_Number   := tplLineItem.DEP_COMMODITY_CODE;
      vTblLineItem(vIndex).Article.Gross_Weight            := tplLineItem.DEP_GROSS_MASS;
      vTblLineItem(vIndex).Article.Value_In_CHF            := tplLineItem.DEP_STATISTICAL_VALUE;   --valeur de la marchandise
      vTblLineItem(vIndex).Article.key                     := tplLineItem.DEP_STATISTICAL_CODE;
      vTblLineItem(vIndex).Article.Additional_Pieces       := tplLineItem.DEP_ADDITIONAL_UNIT;
      vTblLineItem(vIndex).Article.Net_Weight              := tplLineItem.DEP_NET_MASS;
      /* vTblLineItem(vIndex).Edec */
      vTblLineItem(vIndex).Edec.eDec_Permit_Obligation     := tplLineItem.C_EDEC_PERMIT_OBLIGATION;
      vTblLineItem(vIndex).Edec.eDec_Commercial_Goods      := tplLineItem.C_EDEC_COMMERCIAL_GOOD;
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
    lv_exp_method DOC_EDI_TYPE.DET_NAME%type;
  begin
    -- recherche d'une procédure individualisée d'initialisation
    -- ancien nom de paramètre EDI : EXPORT_PACKAGE,
    -- nouveau nom de paramètre EDI : EXPORT_PACKAGE.INITIALIZEDATA
    select max(DET.DET_NAME)
      into lv_exp_method
      from DOC_EDI_TYPE DET
     where DET.DOC_EDI_TYPE_ID = aEdiTypeId;

    vPackageName  :=
                 nvl(DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE', aEdiTypeID), DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE.INITIALIZEDATA', aEdiTypeID) );

    if vPackageName is not null then
      begin
        -- exécution de la procédure individualisée
        execute immediate 'begin' || chr(10) || '  ' || vPackageName || '.InitializeData(:aEdecHeaderID,:aEdiTypeID);' || chr(10) || 'end;'
                    using aEdecHeaderID, aEdiTypeID;
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
  * function CreateEdecExportJob
  * Description
  *   Création du job d'exportation dans la table DOC_EDI_EXPORT_JOB en fonction
  *   de la déclaration EDEC et du type d'export EDI passé en param
  */
  function CreateEdecExportJob(aEdecHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, aEdiTypeID in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type)
    return DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  is
    vJobID       DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type;
    vFileName    DOC_EDI_EXPORT_JOB.DIJ_FILENAME%type;
    vDescription DOC_EDI_EXPORT_JOB.DIJ_DESCRIPTION%type;
  begin
    -- Description et nom du fichier pour l'export
    select DEH.DEH_TRADER_DECLARATION_NUMBER || ' - ' || DET.DET_NAME as DIJ_DESCRIPTION
         , DEH.DEH_TRADER_DECLARATION_NUMBER || '.txt'
      into vDescription
         , vFileName
      from DOC_EDEC_HEADER DEH
         , DOC_EDI_TYPE DET
     where DEH.DOC_EDEC_HEADER_ID = aEdecHeaderID
       and DET.DOC_EDI_TYPE_ID = aEdiTypeID;

    -- Création du job d'exportation
    vJobID  := DOC_EDI_EXPORT_JOB_FUNCTIONS.CreateExportJob(aFileName => vFileName, aDescription => vDescription, aEdiTypeID => aEdiTypeID);
    return vJobID;
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
        select aHeaderID as DOC_EDEC_HEADER_ID
             , vHeaderNumber as DEH_TRADER_DECLARATION_NUMBER
             , aDocumentID as DOC_DOCUMENT_ID
             , aPackingListID as DOC_PACKING_LIST_ID
             , '1' as C_EDEC_SERVICE_TYPE
             , '01' as C_EDEC_STATUS
             , 0 as DEH_TRANSFER_TO_TRANSIT_SYSTEM
             , 0 as DEH_TRANSPORT_IN_CONTAINER
             , vLangID as PC_LANG_ID
             , vTranspMode as C_EDEC_TRANSPORT_MODE
             , vIncoterms as C_INCOTERMS
             , sysdate as A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
          from dual;

      -- Création des adresses de l'entête de la déclaration EDEC
      DOC_EDI_EDEC_ETRANS_V1.GenerateAddresses(aHeaderID => aHeaderID);
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
      DOC_EDI_EDEC_ETRANS_V1.GenerateAddresses(aHeaderID => aHeaderID);
    end if;
  end ReinitializeHeader;

  -- Adresse destinataire marchandise
  procedure pGenerateAddress1(
    aHeaderID        in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aThirdDeliveryID in PAC_THIRD.PAC_THIRD_ID%type
  , aPackingListID   in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type
  )
  is
    vAddress      DOC_EDEC_ADDRESSES%rowtype;
    vDelivAddress integer                      default null;
  begin
    -- Adresse DESTINATAIRE
    select INIT_ID_SEQ.nextval as DOC_EDEC_ADDRESSES_ID
         , aHeaderID as DOC_EDEC_HEADER_ID
         , '1' as C_EDEC_ADDRESS_TYPE
         , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
         , sysdate as A_DATECRE
      into vAddress.DOC_EDEC_ADDRESSES_ID
         , vAddress.DOC_EDEC_HEADER_ID
         , vAddress.C_EDEC_ADDRESS_TYPE
         , vAddress.A_IDCRE
         , vAddress.A_DATECRE
      from dual;

    -- Source des données = document (DOC_DOCUMENT)
    if aDocumentID is not null then
      -- Adresse DESTINATAIRE
      -- si partenaire de livraison non vide alors les valeurs sont prises sur l'adresse du partenaire de livraison
      --  sinon les valeurs sont prises sur l'adresse du partenaire de facturation
      if aThirdDeliveryID is not null then
        -- Adresse du partenaire de livraison
        select substr(extractline(DMT.DMT_ADDRESS2, 1, chr(10) ), 1, 35)
             , substr(extractline(DMT.DMT_ADDRESS2, 2, chr(10) ), 1, 35)
             , substr(extractline(DMT.DMT_ADDRESS2, 3, chr(10) ), 1, 35)
             , substr(DMT.DMT_POSTCODE2, 1, 9)
             , substr(DMT.DMT_TOWN2, 1, 35)
             , DMT.PC__PC_CNTRY_ID
          into vAddress.DEA_STREET
             , vAddress.DEA_ADDRESS_SUPPLEMENT_1
             , vAddress.DEA_ADDRESS_SUPPLEMENT_2
             , vAddress.DEA_POSTAL_CODE
             , vAddress.DEA_CITY
             , vAddress.PC_CNTRY_ID
          from DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = aDocumentID;
      else
        -- Adresse du partenaire de facturation
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
         where DMT.DOC_DOCUMENT_ID = aDocumentID;
      end if;
    -- Source des données = envoi (DOC_PACKING_LIST)
    elsif aPackingListID is not null then
      -- Adresse DESTINATAIRE
      -- Vérifier si l'adresse du partenaire de livraison est renseigné sur l'envoi
      select sign(nvl(max(DOC_PACKING_LIST_ID), 0) )
        into vDelivAddress
        from DOC_PACKING_LIST
       where DOC_PACKING_LIST_ID = aPackingListID
         and (    (PAL_ADDRESS12 is not null)
              or (PAL_POSTCODE12 is not null)
              or (PAL_TOWN12 is not null)
              or (PC__PC_CNTRY_ID is not null) );

      -- Adresse du partenaire de livraison
      if vDelivAddress = 1 then
        select substr(extractline(PAL_ADDRESS12, 1, chr(10) ), 1, 35)
             , substr(extractline(PAL_ADDRESS12, 2, chr(10) ), 1, 35)
             , substr(extractline(PAL_ADDRESS12, 3, chr(10) ), 1, 35)
             , substr(PAL_POSTCODE12, 1, 9)
             , substr(PAL_TOWN12, 1, 35)
             , PC__PC_CNTRY_ID
          into vAddress.DEA_STREET
             , vAddress.DEA_ADDRESS_SUPPLEMENT_1
             , vAddress.DEA_ADDRESS_SUPPLEMENT_2
             , vAddress.DEA_POSTAL_CODE
             , vAddress.DEA_CITY
             , vAddress.PC_CNTRY_ID
          from DOC_PACKING_LIST
         where DOC_PACKING_LIST_ID = aPackingListID;
      else
        -- Adresse du partenaire de facturation
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
         where DOC_PACKING_LIST_ID = aPackingListID;
      end if;
    end if;

    -- Insertion de l'adresse DESTINATAIRE
    insert into DOC_EDEC_ADDRESSES
         values vAddress;
  end pGenerateAddress1;

  -- Adresse EXPEDITEUR
  procedure pGenerateAddress2(
    aHeaderID        in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aThirdDeliveryID in PAC_THIRD.PAC_THIRD_ID%type
  , aPackingListID   in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type
  )
  is
  begin
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
      select INIT_ID_SEQ.nextval as DOC_EDEC_ADDRESSES_ID
           , aHeaderID as DOC_EDEC_HEADER_ID
           , '2' as C_EDEC_ADDRESS_TYPE
           , substr(extractline(COM_ADR, 1, chr(10) ), 1, 35) as DEA_STREET
           , substr(extractline(COM_ADR, 2, chr(10) ), 1, 35) as DEA_ADDRESS_SUPPLEMENT_1
           , substr(extractline(COM_ADR, 3, chr(10) ), 1, 35) as DEA_ADDRESS_SUPPLEMENT_2
           , substr(COM_ZIP, 1, 9) as DEA_POSTAL_CODE
           , substr(COM_CITY, 1, 35) as DEA_CITY
           , PC_CNTRY_ID as PC_CNTRY_ID
           , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
           , sysdate as A_DATECRE
        from PCS.PC_COMP
       where PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;
  end pGenerateAddress2;

  -- Adresse TRANSPORTEUR
  procedure pGenerateAddress3(
    aHeaderID        in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aThirdDeliveryID in PAC_THIRD.PAC_THIRD_ID%type
  , aPackingListID   in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type
  )
  is
    vAddress DOC_EDEC_ADDRESSES%rowtype;
  begin
    -- Adresse TRANSPORTEUR
    select INIT_ID_SEQ.nextval as DOC_EDEC_ADDRESSES_ID
         , aHeaderID as DOC_EDEC_HEADER_ID
         , '3' as C_EDEC_ADDRESS_TYPE
         , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
         , sysdate as A_DATECRE
      into vAddress.DOC_EDEC_ADDRESSES_ID
         , vAddress.DOC_EDEC_HEADER_ID
         , vAddress.C_EDEC_ADDRESS_TYPE
         , vAddress.A_IDCRE
         , vAddress.A_DATECRE
      from dual;

    -- Source des données = document (DOC_DOCUMENT)
    if aDocumentID is not null then
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
       where DMT.DOC_DOCUMENT_ID = aDocumentID
         and DMT.PAC_SENDING_CONDITION_ID = SEN.PAC_SENDING_CONDITION_ID(+)
         and SEN.PAC_ADDRESS_ID = ADR.PAC_ADDRESS_ID(+);
    -- Source des données = envoi (DOC_PACKING_LIST)
    elsif aPackingListID is not null then
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
       where DOC_PACKING_LIST_ID = aPackingListID;
    end if;

    -- Insertion de l'adresse TRANSPORTEUR
    insert into DOC_EDEC_ADDRESSES
         values vAddress;
  end pGenerateAddress3;

  /**
  * procedure GenerateAddresses
  * Description
  *    Création des adresses pour la déclaration EDEC
  */
  procedure GenerateAddresses(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type)
  is
    lDocumentID      DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lPackingListID   DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type;
    lThirdDeliveryID PAC_THIRD.PAC_THIRD_ID%type;
  begin
    -- Rechercher la source des données pour les adresses (document ou envoi)
    select DEH.DOC_DOCUMENT_ID
         , DEH.DOC_PACKING_LIST_ID
         , DMT.PAC_THIRD_DELIVERY_ID
      into lDocumentID
         , lPackingListID
         , lThirdDeliveryID
      from DOC_EDEC_HEADER DEH
         , DOC_DOCUMENT DMT
     where DEH.DOC_EDEC_HEADER_ID = aHeaderID
       and DEH.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID(+);

    -- destinataire marchandise
    pGenerateAddress1(aHeaderID, lDocumentID, lThirdDeliveryID, lPackingListID);
    -- expéditeur
    pGenerateAddress2(aHeaderID, lDocumentID, lThirdDeliveryID, lPackingListID);
    -- transporteur
    pGenerateAddress3(aHeaderID, lDocumentID, lThirdDeliveryID, lPackingListID);
  end GenerateAddresses;

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
    vtblPackingType       ttblPackingType;
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
    for tplPos in (select   CUS.CUS_CUSTONS_POSITION
                          , CUS.CUS_KEY_TARIFF
                          , nvl(CUS.C_EDEC_PERMIT_OBLIGATION, vCfg_PermitObligation) C_EDEC_PERMIT_OBLIGATION
                          , nvl(CUS.C_EDEC_COMMERCIAL_GOOD, vCfg_CommercialGood) C_EDEC_COMMERCIAL_GOOD
                          , CUS.PC_ORIGIN_PC_CNTRY_ID
                          , CUS.C_EDEC_PREFERENCE
                          , CUS.DIC_UNIT_OF_MEASURE_ID
                          , sum(nvl(POS.POS_GROSS_WEIGHT, 0) ) POS_GROSS_WEIGHT
                          , sum(nvl(POS.POS_NET_WEIGHT, 0) ) POS_NET_WEIGHT
                          , sum(POS.POS_FINAL_QUANTITY_SU * nvl(CUS.CUS_CONVERSION_FACTOR, 1) ) DEP_ADDITIONAL_UNIT
                          , sum(nvl(POS.POS_NET_VALUE_INCL_B, 0) ) POS_NET_VALUE_INCL_B
                       from (select COM_LIST_ID_TEMP_ID as DOC_POSITION_ID
                               from COM_LIST_ID_TEMP
                              where LID_CODE = 'DOC_POSITION_ID') POS_LIST
                          , DOC_POSITION POS
                          , table(DOC_EDEC_UTILITY_FUNCTIONS.GetCustomsElement(vCntryID) ) CUS
                      where POS.DOC_POSITION_ID = POS_LIST.DOC_POSITION_ID
                        and POS.GCO_GOOD_ID = CUS.GCO_GOOD_ID
                   group by CUS.CUS_CUSTONS_POSITION
                          , CUS.CUS_KEY_TARIFF
                          , nvl(CUS.C_EDEC_PERMIT_OBLIGATION, vCfg_PermitObligation)
                          , nvl(CUS.C_EDEC_COMMERCIAL_GOOD, vCfg_CommercialGood)
                          , CUS.PC_ORIGIN_PC_CNTRY_ID
                          , CUS.C_EDEC_PREFERENCE
                          , CUS.DIC_UNIT_OF_MEASURE_ID) loop
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
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vNewPosID as DOC_EDEC_POSITION_ID
             , aHeaderID as DOC_EDEC_HEADER_ID
             , vPosNumber as DEP_POS_NUMBER
             , vPosNumber as DEP_DESCRIPTION
             , tplPos.CUS_CUSTONS_POSITION as DEP_COMMODITY_CODE
             , tplPos.CUS_KEY_TARIFF as DEP_STATISTICAL_CODE
             , null as DEP_SEAL_NUMBER
             , tplPos.POS_GROSS_WEIGHT as DEP_GROSS_MASS
             , tplPos.POS_NET_WEIGHT as DEP_NET_MASS
             , null as DEP_CUSTOMS_NET_WEIGHT
             , tplPos.DEP_ADDITIONAL_UNIT as DEP_ADDITIONAL_UNIT
             , tplPos.C_EDEC_PERMIT_OBLIGATION as C_EDEC_PERMIT_OBLIGATION
             , null as C_EDEC_CUSTOMS_CLEARANCE_TYPE
             , tplPos.C_EDEC_COMMERCIAL_GOOD as C_EDEC_COMMERCIAL_GOOD
             , tplPos.POS_NET_VALUE_INCL_B as DEP_STATISTICAL_VALUE
             , tplPos.PC_ORIGIN_PC_CNTRY_ID as DEP_ORIGIN_PC_CNTRY_ID
             , tplPos.C_EDEC_PREFERENCE as C_EDEC_PREFERENCE
             , sysdate as A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
          from dual;

      -- Insertion des détails de position EDEC (DOC_EDEC_POSITION_DETAIL)
      insert into DOC_EDEC_POSITION_DETAIL
                  (DOC_EDEC_POSITION_DETAIL_ID
                 , DOC_EDEC_POSITION_ID
                 , DOC_POSITION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval as DOC_EDEC_POSITION_DETAIL_ID
             , vNewPosID as DOC_EDEC_POSITION_ID
             , POS.DOC_POSITION_ID as DOC_POSITION_ID
             , sysdate as A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
          from (select COM_LIST_ID_TEMP_ID as DOC_POSITION_ID
                  from COM_LIST_ID_TEMP
                 where LID_CODE = 'DOC_POSITION_ID') POS_LIST
             , DOC_POSITION POS
             , table(DOC_EDEC_UTILITY_FUNCTIONS.GetCustomsElement(vCntryID) ) CUS
         where POS_LIST.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and POS.GCO_GOOD_ID = CUS.GCO_GOOD_ID
           and CUS.CUS_CUSTONS_POSITION = tplPos.CUS_CUSTONS_POSITION
           and CUS.CUS_KEY_TARIFF = tplPos.CUS_KEY_TARIFF
           and nvl(CUS.C_EDEC_PERMIT_OBLIGATION, vCfg_PermitObligation) = tplPos.C_EDEC_PERMIT_OBLIGATION
           and nvl(CUS.C_EDEC_COMMERCIAL_GOOD, vCfg_CommercialGood) = tplPos.C_EDEC_COMMERCIAL_GOOD
           and CUS.PC_ORIGIN_PC_CNTRY_ID = tplPos.PC_ORIGIN_PC_CNTRY_ID
           and CUS.DIC_UNIT_OF_MEASURE_ID = tplPos.DIC_UNIT_OF_MEASURE_ID;

      -- Insertion des positions emballage
      -- Balayer les biens présents sur les positions document (DOC_POSITION)
      for tplPackaging in (select   DMT.PAC_THIRD_CDA_ID
                                  , POS.GCO_GOOD_ID
                               from (select COM_LIST_ID_TEMP_ID as DOC_POSITION_ID
                                       from COM_LIST_ID_TEMP
                                      where LID_CODE = 'DOC_POSITION_ID') POS_LIST
                                  , DOC_POSITION POS
                                  , table(DOC_EDEC_UTILITY_FUNCTIONS.GetCustomsElement(vCntryID) ) CUS
                                  , DOC_DOCUMENT DMT
                              where POS_LIST.DOC_POSITION_ID = POS.DOC_POSITION_ID
                                and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                                and POS.GCO_GOOD_ID = CUS.GCO_GOOD_ID
                                and CUS.CUS_CUSTONS_POSITION = tplPos.CUS_CUSTONS_POSITION
                                and CUS.CUS_KEY_TARIFF = tplPos.CUS_KEY_TARIFF
                                and nvl(CUS.C_EDEC_PERMIT_OBLIGATION, vCfg_PermitObligation) = tplPos.C_EDEC_PERMIT_OBLIGATION
                                and nvl(CUS.C_EDEC_COMMERCIAL_GOOD, vCfg_CommercialGood) = tplPos.C_EDEC_COMMERCIAL_GOOD
                                and CUS.PC_ORIGIN_PC_CNTRY_ID = tplPos.PC_ORIGIN_PC_CNTRY_ID
                                and CUS.DIC_UNIT_OF_MEASURE_ID = tplPos.DIC_UNIT_OF_MEASURE_ID
                           group by CUS.CUS_CUSTONS_POSITION
                                  , CUS.CUS_KEY_TARIFF
                                  , nvl(CUS.C_EDEC_PERMIT_OBLIGATION, vCfg_PermitObligation)
                                  , nvl(CUS.C_EDEC_COMMERCIAL_GOOD, vCfg_CommercialGood)
                                  , CUS.PC_ORIGIN_PC_CNTRY_ID
                                  , CUS.DIC_UNIT_OF_MEASURE_ID
                                  , DMT.PAC_THIRD_CDA_ID
                                  , POS.GCO_GOOD_ID) loop
        -- Récuperer le type d'emballage définit sur les données compl. de vente
        -- du bien ou config par défaut
        select nvl(max(DIC_PACKING_TYPE_ID), vCfg_PackingType)
          into vPackingTypeID
          from GCO_COMPL_DATA_SALE
         where GCO_COMPL_DATA_SALE_ID = GCO_FUNCTIONS.GetComplDataSaleId(tplPackaging.GCO_GOOD_ID, tplPackaging.PAC_THIRD_CDA_ID);

        -- Ajouter dans une liste le type d'emballage courant à la liste des
        -- emballages EDEC à créer pour la position EDEC courante
        if vPackingTypeID is not null then
          bExists  := false;

          if (vtblPackingType.count > 0) then
            iCpt  := 1;

            -- Balayer la liste des pos emballage à créer pour savoir si la valeur
            -- du type d'emballage courante est déjà dans la liste.
            while iCpt <= vtblPackingType.count loop
              if vtblPackingType(iCpt).DIC_PACKING_TYPE_ID = vPackingTypeID then
                bExists  := true;
              end if;

              iCpt  := iCpt + 1;
            end loop;
          end if;

          if not bExists then
            iCpt                                       := vtblPackingType.count + 1;
            vtblPackingType(iCpt).DIC_PACKING_TYPE_ID  := vPackingTypeID;
          end if;
        end if;
      end loop;

      -- Création des positions emballage EDEC pour le regroupement position EDEC courante
      if vtblPackingType.count = 0 then
        -- Création d'une seule position emballage sans type d'emballage
        insert into DOC_EDEC_PACKAGING
                    (DOC_EDEC_PACKAGING_ID
                   , DOC_EDEC_POSITION_ID
                   , DIC_PACKING_TYPE_ID
                   , C_EDEC_PACKAGING_TYPE
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , vNewPosID
               , null
               , '0'
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from dual;
      else
        iCpt  := 1;

        -- Création des positions emballage EDEC pour le regroupement position EDEC courante
        while iCpt <= vtblPackingType.count loop
          insert into DOC_EDEC_PACKAGING
                      (DOC_EDEC_PACKAGING_ID
                     , DOC_EDEC_POSITION_ID
                     , DIC_PACKING_TYPE_ID
                     , C_EDEC_PACKAGING_TYPE
                     , A_DATECRE
                     , A_IDCRE
                      )
            select INIT_ID_SEQ.nextval
                 , vNewPosID
                 , vtblPackingType(iCpt).DIC_PACKING_TYPE_ID
                 , '0'
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
              from dual;

          iCpt  := iCpt + 1;
        end loop;
      end if;
    end loop;

    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'DOC_POSITION_ID';
  end DischargePositions;
end DOC_EDI_EDEC_ETRANS_V1;
