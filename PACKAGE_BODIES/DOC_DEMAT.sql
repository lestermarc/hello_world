--------------------------------------------------------
--  DDL for Package Body DOC_DEMAT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DEMAT" 
is
  /**
   * Description
   *   retourne l'Id de la société en fonction de son nom
   */
  function getCompanyId(aCompanyName in varchar2)
    return number
  is
    result PCS.PC_COMP.PC_COMP_ID%type;
  begin
    select COM.PC_COMP_ID
      into result
      from PCS.PC_COMP COM
     where upper(COM.COM_NAME) = upper(aCompanyName);

    return result;
  exception
    when no_data_found then
      select COM.PC_COMP_ID
        into result
        from PCS.PC_COMP COM
           , PCS.PC_SCRIP SCR
       where COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID
         and upper(SCR.SCRDBOWNER) = upper(aCompanyName);

      return result;
    when others then
      return null;
  end getCompanyId;

  /**
   * Description
   *   procedure initialisant les XMLs "documents"
   */
  procedure init_pc_exchange_data(aDataId in PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type)
  is
    v_recipientFin string(200);
    v_recipientLog string(200);
    v_SenderName   string(200);
    v_documentNo   string(50);
    v_linkedUrl    string(4000);
    p_currDataIn   PCS.PC_EXCHANGE_DATA_IN%rowtype;
    p_continue     boolean                           := true;
  begin
    -- Récupération des infos contenu dans la table PC_EXCHANGE_DATA_IN
    select EDI.*
      into p_currDataIn
      from PCS.PC_EXCHANGE_DATA_IN EDI
     where EDI.PC_EXCHANGE_DATA_IN_ID = aDataId;

    select extractvalue(xmltype(EDI.EDI_IMPORTED_XML_DOCUMENT), '/DOCUMENT/HEADER/RECIPIENT/IDENTIFIER/FINANCIAL_COMPANY_NAME')
         , extractvalue(xmltype(EDI.EDI_IMPORTED_XML_DOCUMENT), '/DOCUMENT/HEADER/RECIPIENT/IDENTIFIER/LOGISTICS_COMPANY_NAME')
         , extractvalue(xmltype(EDI.EDI_IMPORTED_XML_DOCUMENT), '/DOCUMENT/HEADER/SENDER/IDENTIFIER/LOGISTICS_COMPANY_NAME')
         , extractvalue(xmltype(EDI.EDI_IMPORTED_XML_DOCUMENT), '/DOCUMENT/HEADER/SENDER/DOCUMENT_NUMBER')
         , extractvalue(xmltype(EDI.EDI_IMPORTED_XML_DOCUMENT), '/DOCUMENT/HEADER/THIS_DOCUMENT/EXTERNAL_INFORMATION/URL')
      into v_recipientFin
         , v_recipientLog
         , v_SenderName
         , v_documentNo
         , v_linkedUrl
      from PCS.PC_EXCHANGE_DATA_IN EDI
     where EDI.PC_EXCHANGE_DATA_IN_ID = aDataId;

    p_currDataIn.C_EDI_PROCESS_STATUS    := '02';
    p_currDataIn.C_EDI_MAIN_FAIL_REASON  := null;

    -- Récupération de la société finance
    if     p_currDataIn.PC_COMP_ACT_ID is null
       and v_recipientFin is not null then
      p_currDataIn.PC_COMP_ACT_ID  := getCompanyId(v_recipientFin);

      if p_currDataIn.PC_COMP_ACT_ID is null then
        p_currDataIn.C_EDI_PROCESS_STATUS    := '92';
        p_currDataIn.C_EDI_MAIN_FAIL_REASON  := '001';
        p_continue                           := false;
      end if;
    end if;

    -- Récupération de la société logistique
    if     p_continue
       and p_currDataIn.PC_COMP_DOC_ID is null
       and v_recipientLog is not null then
      p_currDataIn.PC_COMP_DOC_ID  := getCompanyId(v_recipientLog);

      if p_currDataIn.PC_COMP_DOC_ID is null then
        p_currDataIn.C_EDI_PROCESS_STATUS    := '92';
        p_currDataIn.C_EDI_MAIN_FAIL_REASON  := '002';
        p_continue                           := false;
      end if;
    end if;

    -- Vérification de la présence d'au moins une des deux sociétés
    if     p_continue
       and p_currDataIn.PC_COMP_ACT_ID is null
       and p_currDataIn.PC_COMP_DOC_ID is null then
      p_currDataIn.C_EDI_PROCESS_STATUS    := '92';
      p_currDataIn.C_EDI_MAIN_FAIL_REASON  := '003';
      p_continue                           := false;
    end if;

    if p_continue then
      -- Mise à jour du document
      p_currDataIn.EDI_LINKED_FILE_URL     := v_linkedUrl;
      p_currDataIn.EDI_MESSAGE             := v_documentNo;
      p_currDataIn.EDI_PARTNER_COMP        := v_SenderName;
      p_currDataIn.EDI_XML_DOCUMENT        := p_currDataIn.EDI_IMPORTED_XML_DOCUMENT;
      -- Mise à jour du statut du document XML
      p_currDataIn.C_EDI_PROCESS_STATUS    := '09';
      p_currDataIn.C_EDI_MAIN_FAIL_REASON  := null;
      p_currDataIn.C_EDI_STATUS_DOC        := '0';
      p_currDataIn.C_EDI_STATUS_ACT        := '0';
    end if;

    -- Report des modifications dans la base de données
    update PCS.PC_EXCHANGE_DATA_IN
       set row = p_currDataIn
     where PC_EXCHANGE_DATA_IN_ID = aDataId;
  end init_pc_exchange_data;

  procedure init_doc_interface(aExchangeDataId in PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type, aDocInterface in out doc_interface%rowtype)
  is
    p_doiId number(12);
  begin
    -- Id pour le nouveau DOI
    select PCS.init_id_seq.nextval
      into p_doiId
      from dual;

    -- Création du nouveau record dans doc_interface
    insert into DOC_INTERFACE
                (DOC_INTERFACE_ID
               , C_DOC_INTERFACE_ORIGIN
               , DOI_PROTECTED
               , C_DOI_INTERFACE_STATUS
               , PC_EXCHANGE_DATA_IN_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (p_doiId
               , '301'
               , 1
               , '01'
               , aExchangeDataId
               , sysdate
               , PCS.PC_I_LIB_SESSION.GETUSERINI
                );

    select doi.*
      into aDocInterface
      from doc_interface doi
     where doi.doc_interface_id = p_doiId;
  end init_doc_interface;

  procedure init_doc_interface_position(aDocInterface doc_interface%rowtype, aDocInterfacePosition in out doc_interface_position%rowtype)
  is
    p_PosDoiId number(12);
  begin
    select PCS.init_id_seq.nextval
      into p_PosDoiId
      from dual;

    -- Création du nouveau record dans doc_interface_position
    insert into DOC_INTERFACE_POSITION
                (DOC_INTERFACE_POSITION_ID
               , DOC_INTERFACE_ID
               , DOP_USE_GOOD_PRICE
               , A_DATECRE
               , A_IDCRE
                )
         values (p_PosDoiId
               , aDocInterface.doc_interface_id
               , 1
               , sysdate
               , PCS.PC_I_LIB_SESSION.GETUSERINI
                );

    select dop.*
      into aDocInterfacePosition
      from doc_interface_position dop
     where dop.doc_interface_position_id = p_posDoiId;
  end init_doc_interface_position;

  /**
   * Description
   *   fonction transférants les données présentes dans le document XML
   *   dans les champs correspondants de doc_interface
   */
  function transfer_data(aDataId in PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type)
    return number
  is
    p_xml              xmltype;
    lv_xmlPositions    xmltype;
    lv_xmlPositionsDet xmltype;
    p_currNode         xmltype;
    p_currDoi          DOC_INTERFACE%rowtype;
    p_currPosDoi       DOC_INTERFACE_POSITION%rowtype;
    i                  integer;
    iDet               integer;
  begin
    -- Récupération du XML
    select xmltype(EDI.EDI_XML_DOCUMENT)
      into p_xml
      from PCS.PC_EXCHANGE_DATA_IN EDI
     where EDI.PC_EXCHANGE_DATA_IN_ID = aDataId;

    -- insertion et initialisation du record doc_interface
    init_doc_interface(aDataId, p_currDoi);
    -- Extraction des données entête
    DOC_PRC_INTERFACE.ExtractHeader(iXml => p_xml, iotplInterface => p_currDoi);

    -- Report des modifications dans la base de données
    update DOC_INTERFACE
       set row = p_currDoi
     where DOC_INTERFACE_ID = p_currDoi.doc_interface_id;

    -- récupération du fragment de document contenant les positions
    select extract(p_xml, '/DOCUMENT/POSITIONS')
      into lv_xmlPositions
      from dual;

    -- traitement des positions
    for tpl_xmlPositions in (select column_value XML_VALUE
                               from table(xmlsequence(extract(lv_xmlPositions, '/POSITIONS/POSITION') ) ) ) loop
      -- insertion et initialisation du record doc_interface_position
      init_doc_interface_position(p_currDoi, p_currPosDoi);
      -- extraction des données position
      DOC_PRC_INTERFACE.ExtractPosition(iXml => tpl_xmlPositions.xml_value, itplInterface => p_currDoi, iotplInterfacePos => p_currPosDoi);

      /* DEVLOG-16036 - Modifications demandée par PYV */
      if tpl_xmlPositions.xml_value.existsnode('/POSITION/LOGISTICS_PART/POSITION_DETAILS/POSITION_DETAIL') > 0 then
        -- traitement des détails
        for tpl_xmlPositionsDet in (select column_value XML_VALUE
                             from table(xmlsequence(extract(tpl_xmlPositions.xml_value, '/POSITION/LOGISTICS_PART/POSITION_DETAILS/POSITION_DETAIL') ) ) ) loop
          -- extraction des données détails
          DOC_PRC_INTERFACE.ExtractDetail(iXml => tpl_xmlPositionsDet.xml_value, iotplInterfacePos => p_currPosDoi);

          -- Report des modifications dans la base de données
          update DOC_INTERFACE_POSITION
             set row = p_currPosDoi
           where DOC_INTERFACE_ID = p_currDoi.doc_interface_id;
        end loop;
      else
        -- Report des modifications dans la base de données
        update DOC_INTERFACE_POSITION
           set row = p_currPosDoi
         where DOC_INTERFACE_ID = p_currDoi.doc_interface_id;
      end if;
    end loop;

    -- Appel de la procédure de conversion en Id des données reçues en clair
    convert_data(p_currDoi.doc_interface_id, 0);
    return p_currDoi.doc_interface_id;
  end transfer_data;

  /**
   * Description
   *   Converti les valeurs reçu en clair dans l'XML en Id (niveau Doc)
   */
  procedure convert_data(aDocInterfaceId in DOC_INTERFACE.DOC_INTERFACE_ID%type, aReset_data in integer)
  is
    p_currDoi DOC_INTERFACE%rowtype;
  begin
    -- Récupération du DOC_INTERFACE_COURANT
    select *
      into p_currDoi
      from DOC_INTERFACE
     where DOC_INTERFACE_ID = aDocInterfaceId;

    -- Conversion des valeurs reçu en clair dans l'XML en Id niveau Entête
    DOC_PRC_INTERFACE.ConvertHeaderData(iotplInterface => p_currDoi, iOrigin => '301', iResetData => aReset_data);

    -- Report des modifications dans la base de données
    update DOC_INTERFACE
       set row = p_currDoi
     where DOC_INTERFACE_ID = aDocInterfaceId;

    -- Mise à jour erreur dans PC_EXCHANGE_DATA_IN
    if p_currDoi.C_DOI_INTERFACE_STATUS <> '01' then
      update PCS.PC_EXCHANGE_DATA_IN EDI
         set EDI.C_EDI_PROCESS_STATUS = '93'
           , EDI.C_EDI_STATUS_DOC = '2'
       where EDI.PC_EXCHANGE_DATA_IN_ID = p_currDoi.PC_EXCHANGE_DATA_IN_ID;
    else
      update PCS.PC_EXCHANGE_DATA_IN EDI
         set EDI.C_EDI_STATUS_DOC = '3'
       where EDI.PC_EXCHANGE_DATA_IN_ID = p_currDoi.PC_EXCHANGE_DATA_IN_ID;
    end if;
  end convert_data;
end DOC_DEMAT;
