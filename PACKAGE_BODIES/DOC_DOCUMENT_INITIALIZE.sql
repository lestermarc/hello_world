--------------------------------------------------------
--  DDL for Package Body DOC_DOCUMENT_INITIALIZE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DOCUMENT_INITIALIZE" 
is
  /*
  * Aiguillage de l'initialisation selon le mode de création
  */
  procedure CallInitProc
  is
    strIndivInitProc varchar2(250);
    tmpCode          varchar2(1);
  begin
    -- Procédure d'initialisation de l'utilisateur renseigné à l'appel de la méthode
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USER_INIT_PROCEDURE is not null then
      strIndivInitProc  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.USER_INIT_PROCEDURE;
    else
      -- Recherche si une procédure d'initialisation indiv a été renseignée
      --  pour le gabarit et le type de création défini.
      select max(GCP_INIT_PROCEDURE)
        into strIndivInitProc
        from DOC_GAUGE_CREATE_PROC
       where DOC_GAUGE_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
         and C_DOC_CREATE_MODE = DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOC_CREATE_MODE
         and C_GROUP_CREATE_MODE = 'DOC';
    end if;

    -- Procédure d'intialisation INDIV
    if strIndivInitProc is not null then
      DOC_DOCUMENT_INITIALIZE.CallInitProcIndiv(strIndivInitProc);
    -- Appel de la méthode d'init PCS uniquement si code PCS (100 à 399)
    elsif to_number(DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOC_CREATE_MODE) between 100 and 399 then
      -- Procédure d'initialisation PCS
      DOC_DOCUMENT_INITIALIZE.CallInitProcPCS(DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOC_CREATE_MODE);
    end if;

    -- Init des flags
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_FREE_DATA           := 0;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.COPY_FREE_DATA             := 0;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.COPY_FOOT_CHARGE           := 0;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DISCHARGE_FOOT_CHARGE  := 0;

    -- Création
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_TYPE = 'INSERT' then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_FREE_DATA  := 1;
    -- Copie
    elsif DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_TYPE = 'COPY' then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.COPY_FREE_DATA    := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.COPY_FOOT_CHARGE  := 1;
    -- Décharge
    elsif DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_TYPE = 'DISCHARGE' then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.COPY_FREE_DATA             := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DISCHARGE_FOOT_CHARGE  := 1;
    end if;
  end CallInitProc;

  /*
  *  Appel de la procédure d'initialisation PCS
  */
  procedure CallInitProcPCS(aInitMode in varchar2)
  is
    Sql_Statement varchar2(500);
  begin
    Sql_Statement  := ' BEGIN ' || '   DOC_DOCUMENT_INITIALIZE.InitDocument_' || aInitMode || ';' || ' END;';

    execute immediate Sql_Statement;
  end CallInitProcPCS;

  /*
  *  Appel de la procédure d'initialisation Indiv
  */
  procedure CallInitProcIndiv(aInitProc in DOC_GAUGE_CREATE_PROC.GCP_INIT_PROCEDURE%type)
  is
    Sql_Statement varchar2(500);
    tmpInitProc   DOC_GAUGE_CREATE_PROC.GCP_INIT_PROCEDURE%type;
  begin
    tmpInitProc    := trim(aInitProc);

    -- Ajouter le point-virgule s'il est absent
    if substr(tmpInitProc, length(tmpInitProc), 1) <> ';' then
      tmpInitProc  := tmpInitProc || ';';
    end if;

    Sql_Statement  := 'BEGIN ' || tmpInitProc || ' END;';

    execute immediate Sql_Statement;
  end CallInitProcIndiv;

  /*
  *  procedure InitDocument_110
  *  Description
  *    Création - Gestion des documents
  */
  procedure InitDocument_110
  is
  begin
    -- On fait l'appel de la méthode d'initialisation pour que les champs
    -- soient renseignés pour que l'utilisateur puisse les retoucher
    -- dans le cas ou il appele cette méthode dans sa méthode indiv
    ControlInitDocumentData;
  end InitDocument_110;

  /**
  *  procedure InitDocument_118
  *  Description
  *    Création - Gestion des litiges
  */
  procedure InitDocument_118
  is
  begin
    null;
  end;

  /**
  *  procedure InitDocument_120
  *  Description
  *    Création - Génération des cmds Sous-traitance
  */
  procedure InitDocument_120
  is
  begin
    -- Si l'opération a été passée en paramètre (donc regroupement par opération; null si regroupement par sous-traitant) et
    -- que la config DOC_SUBCONTRACT_ADDRESS_TYPE = 1, il faut vérifier si l'opération principale suivante est externe. Si
    -- c'est le cas, il faut initialiser l'adresse de livraison de la CST avec l'adresse par défaut de son fournisseur.
    if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.FAL_SCHEDULE_STEP_ID is not null)
       and PCS.PC_CONFIG.GetBooleanConfig('DOC_SUBCONTRACT_ADDRESS_TYPE') then
      for ltplNextSupAddrInfos in (select adr.PAC_ADDRESS_ID
                                        , adr.PC_CNTRY_ID
                                        , adr.ADD_ADDRESS1
                                        , adr.ADD_ZIPCODE
                                        , adr.ADD_CITY
                                        , adr.ADD_STATE
                                        , adr.ADD_CARE_OF
                                        , adr.ADD_PO_BOX
                                        , adr.ADD_PO_BOX_NBR
                                        , adr.ADD_COUNTY
                                     from FAL_TASK_LINK tal
                                        , PAC_ADDRESS adr
                                    where adr.PAC_PERSON_ID = tal.PAC_SUPPLIER_PARTNER_ID
                                      and FAL_SCHEDULE_STEP_ID = FAL_LIB_TASK_LINK.getNextMainTaskID(DOC_DOCUMENT_INITIALIZE.DocumentInfo.FAL_SCHEDULE_STEP_ID)
                                      and tal.C_TASK_TYPE = '2'
                                      and adr.ADD_PRINCIPAL = 1) loop
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_2       := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAC_ADDRESS_ID  := ltplNextSupAddrInfos.PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_CNTRY_ID     := ltplNextSupAddrInfos.PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS2        := ltplNextSupAddrInfos.ADD_ADDRESS1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE2       := ltplNextSupAddrInfos.ADD_ZIPCODE;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN2           := ltplNextSupAddrInfos.ADD_CITY;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE2          := ltplNextSupAddrInfos.ADD_STATE;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME2           := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME2       := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY2       := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF2        := ltplNextSupAddrInfos.ADD_CARE_OF;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX2         := ltplNextSupAddrInfos.ADD_PO_BOX;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR2     := ltplNextSupAddrInfos.ADD_PO_BOX_NBR;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY2         := ltplNextSupAddrInfos.ADD_COUNTY;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT2        := null;
      end loop;
    end if;
  end InitDocument_120;

  /**
  *  procedure InitDocument_121
  *  Description
  *    Création - Factures de débours
  */
  procedure InitDocument_121
  is
    cursor crSCH_BILL_HEADER(aSCH_BILL_HEADER_ID number)
    is
      select *
        from SCH_BILL_HEADER
       where SCH_BILL_HEADER_ID = aSCH_BILL_HEADER_ID;
  begin
    for TplSCH_BILL_HEADER_ID in crSCH_BILL_HEADER(DocumentInfo.DOC_DOCUMENT_SRC_ID) loop
      -- Condition de payement forcée
      DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
      DocumentInfo.PAC_PAYMENT_CONDITION_ID      := TplSCH_BILL_HEADER_ID.PAC_PAYMENT_CONDITION_ID;
      DocumentInfo.DMT_DATE_DOCUMENT             := TplSCH_BILL_HEADER_ID.HEA_BILL_DATE;
      DocumentInfo.USE_DMT_DATE_VALUE            := 1;
      DocumentInfo.DMT_DATE_VALUE                := TplSCH_BILL_HEADER_ID.HEA_VALUE_DATE;
      exit;
    end loop;

    -- Remise à zéro de l'ID document source
    DocumentInfo.DOC_DOCUMENT_SRC_ID  := null;
  end InitDocument_121;

  /**
  *  procedure InitDocument_122
  *  Description
  *    Création - Factures d'écolages
  */
  procedure InitDocument_122
  is
    cursor crSCH_BILL_HEADER(aSCH_BILL_HEADER_ID number)
    is
      select *
        from SCH_BILL_HEADER
       where SCH_BILL_HEADER_ID = aSCH_BILL_HEADER_ID;
  begin
    for TplSCH_BILL_HEADER_ID in crSCH_BILL_HEADER(DocumentInfo.DOC_DOCUMENT_SRC_ID) loop
      -- Condition de payement forcée
      DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
      DocumentInfo.PAC_PAYMENT_CONDITION_ID      := TplSCH_BILL_HEADER_ID.PAC_PAYMENT_CONDITION_ID;
      DocumentInfo.DMT_DATE_DOCUMENT             := TplSCH_BILL_HEADER_ID.HEA_BILL_DATE;
      DocumentInfo.USE_DMT_DATE_VALUE            := 1;
      DocumentInfo.DMT_DATE_VALUE                := TplSCH_BILL_HEADER_ID.HEA_VALUE_DATE;
      exit;
    end loop;

    -- Remise à zéro de l'ID document source
    DocumentInfo.DOC_DOCUMENT_SRC_ID  := null;
  end InitDocument_122;

  /**
  *  procedure InitDocument_123
  *  Description
  *    Création - Sous-traitance d'achat
  */
  procedure InitDocument_123
  is
  begin
    null;
  end InitDocument_123;

  /**
  *  procedure InitDocument_124
  *  Description
  *    Création - Sous-traitance d'achat - BLST/BLRST
  */
  procedure InitDocument_124
  is
  begin
    null;
  end InitDocument_124;

  /**
  *  procedure InitDocument_126
  *  Description
  *    Création - Devis - Offre client
  */
  procedure InitDocument_126
  is
    cursor lcrEstimate(cEstimateID number)
    is
      select DES.DES_NUMBER
           , DES.PAC_CUSTOM_PARTNER_ID
           , DES.ACS_FINANCIAL_CURRENCY_ID
           , DES.PC_LANG_ID
           , DES.DES_HEADING_TEXT
           , DES.DES_FOOT_TEXT
        from DOC_ESTIMATE DES
       where DOC_ESTIMATE_ID = cEstimateID;

    ltplEstimate lcrEstimate%rowtype;
  begin
    open lcrEstimate(DocumentInfo.DOC_ESTIMATE_ID);

    fetch lcrEstimate
     into ltplEstimate;

    if lcrEstimate%found then
      -- Init de la réf. du document avec le n° du devis
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_REFERENCE          := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_REFERENCE              := ltplEstimate.DES_NUMBER;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID           := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID               := ltplEstimate.PAC_CUSTOM_PARTNER_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := ltplEstimate.ACS_FINANCIAL_CURRENCY_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID             := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID                 := ltplEstimate.PC_LANG_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_HEADING_TEXT       := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_APPLTXT_ID              := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_HEADING_TEXT           := ltplEstimate.DES_HEADING_TEXT;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT          := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC_APPLTXT_ID         := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT              := ltplEstimate.DES_FOOT_TEXT;
    end if;

    close lcrEstimate;
  end InitDocument_126;

  /**
  *  procedure InitDocument_127
  *  Description
  *    Création - Devis - Commande client
  */
  procedure InitDocument_127
  is
  begin
    -- Devis simplifié
    -- Pour le moment, l'init de la commande client est la même que l'offre
    InitDocument_126;
  end InitDocument_127;

  /**
  *  procedure InitDocument_130
  *  Description
  *    Création - DRP (Demande de réapprovisionement)
  */
  procedure InitDocument_130
  is
  begin
    null;
  end InitDocument_130;

  /**
  *  procedure InitDocument_131
  *  Description
  *    Création - Traitement des lots périmés / refusés
  */
  procedure InitDocument_131
  is
  begin
    null;
  end InitDocument_131;

  /**
  *  procedure InitDocument_135
  *  Description
  *    Création - Reprise des POA
  */
  procedure InitDocument_135
  is
  begin
    null;
  end InitDocument_135;

  /**
  *  procedure InitDocument_137
  *  Description
  *    Création - Demandes de consultations
  */
  procedure InitDocument_137
  is
    cursor crConsultInfo(aConsultID FAL_DOC_CONSULT.FAL_DOC_CONSULT_ID%type)
    is
      select FDC.FDC_PARTNER_NUMBER
           , FDC.FDC_PARTNER_REFERENCE
           , FDC.FDC_DATE_PARTNER_DOCUMENT
        from FAL_DOC_CONSULT FDC
       where FDC.FAL_DOC_CONSULT_ID = aConsultID;

    tplConsultInfo crConsultInfo%rowtype;
  begin
    -- Initialisation des infos concernant le document partenaire
    open crConsultInfo(DocumentInfo.DOC_DOCUMENT_SRC_ID);

    fetch crConsultInfo
     into tplConsultInfo;

    if crConsultInfo%found then
      -- Numéro du document partenaire
      if tplConsultInfo.FDC_PARTNER_NUMBER is not null then
        DocumentInfo.USE_DMT_PARTNER_NUMBER  := 1;
        DocumentInfo.DMT_PARTNER_NUMBER      := tplConsultInfo.FDC_PARTNER_NUMBER;
      end if;

      -- Référence du document partenaire
      if tplConsultInfo.FDC_PARTNER_REFERENCE is not null then
        DocumentInfo.USE_DMT_PARTNER_REFERENCE  := 1;
        DocumentInfo.DMT_PARTNER_REFERENCE      := tplConsultInfo.FDC_PARTNER_REFERENCE;
      end if;

      -- Date du document partenaire
      if tplConsultInfo.FDC_DATE_PARTNER_DOCUMENT is not null then
        DocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT  := 1;
        DocumentInfo.DMT_DATE_PARTNER_DOCUMENT      := tplConsultInfo.FDC_DATE_PARTNER_DOCUMENT;
      end if;
    end if;

    close crConsultInfo;

    -- Remise à zéro de l'ID document source
    DocumentInfo.DOC_DOCUMENT_SRC_ID  := null;
  end InitDocument_137;

  /**
  *  procedure InitDocument_140
  *  Description
  *    Création - Générateur de documents
  */
  procedure InitDocument_140
  is
    cursor crInterfaceInfo(cInterfaceID DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select DOI.DOI_NUMBER
           , DOI.DMT_NUMBER
           , DOI.DOI_TITLE_TEXT
           , DOI.DOI_HEADING_TEXT
           , DOI.DOI_DOCUMENT_TEXT
           , DOI.PAC_THIRD_ID
           , DOI.PAC_THIRD_ACI_ID
           , DOI.PAC_THIRD_DELIVERY_ID
           , DOI.PAC_THIRD_TARIFF_ID
           , DOI.DOC_RECORD_ID
           , DOI.PAC_REPRESENTATIVE_ID
           , DOI.PAC_REPR_ACI_ID
           , DOI.PAC_REPR_DELIVERY_ID
           , DOI.PAC_SENDING_CONDITION_ID
           , DOI.PAC_DISTRIBUTION_CHANNEL_ID
           , DOI.PAC_SALE_TERRITORY_ID
           , DOI.PC_LANG_ID
           , DOI.PC_LANG_ACI_ID
           , DOI.PC_LANG_DELIVERY_ID
           , DOI.DOI_REFERENCE
           , DOI.DOI_PARTNER_REFERENCE
           , DOI.DOI_PARTNER_NUMBER
           , DOI.DOI_PARTNER_DATE
           , DOI.ACS_FINANCIAL_CURRENCY_ID
           , DOI.DOI_DOCUMENT_DATE
           , DOI.DOI_VALUE_DATE
           , DOI.DOI_DELIVERY_DATE
           , DOI.DIC_TYPE_SUBMISSION_ID
           , DOI.PAC_PAYMENT_CONDITION_ID
           , DOI.DIC_TARIFF_ID
           , DOI.ACS_VAT_DET_ACCOUNT_ID
           , DOI.ACS_FIN_ACC_S_PAYMENT_ID
           , DOI.PAC_ADDRESS_ID
           , DOI.DOI_ADDRESS1
           , DOI.PC_CNTRY_ID
           , DOI.DOI_ZIPCODE1
           , DOI.DOI_TOWN1
           , DOI.DOI_STATE1
           , DOI.DOI_NAME1
           , DOI.DOI_FORENAME1
           , DOI.DOI_ACTIVITY1
           , DOI.DOI_CARE_OF1
           , DOI.DOI_PO_BOX1
           , DOI.DOI_PO_BOX_NBR1
           , DOI.DOI_COUNTY1
           , DOI.DOI_CONTACT1
           , DOI.PAC_PAC_ADDRESS_ID
           , DOI.DOI_ADDRESS2
           , DOI.PC__PC_CNTRY_ID
           , DOI.DOI_ZIPCODE2
           , DOI.DOI_TOWN2
           , DOI.DOI_STATE2
           , DOI.DOI_NAME2
           , DOI.DOI_FORENAME2
           , DOI.DOI_ACTIVITY2
           , DOI.DOI_CARE_OF2
           , DOI.DOI_PO_BOX2
           , DOI.DOI_PO_BOX_NBR2
           , DOI.DOI_COUNTY2
           , DOI.DOI_CONTACT2
           , DOI.PAC2_PAC_ADDRESS_ID
           , DOI.DOI_ADDRESS3
           , DOI.PC_2_PC_CNTRY_ID
           , DOI.DOI_ZIPCODE3
           , DOI.DOI_TOWN3
           , DOI.DOI_STATE3
           , DOI.DOI_NAME3
           , DOI.DOI_FORENAME3
           , DOI.DOI_ACTIVITY3
           , DOI.DOI_CARE_OF3
           , DOI.DOI_PO_BOX3
           , DOI.DOI_PO_BOX_NBR3
           , DOI.DOI_COUNTY3
           , DOI.DOI_CONTACT3
           , DOI.DIC_POS_FREE_TABLE_1_ID
           , DOI.DIC_POS_FREE_TABLE_2_ID
           , DOI.DIC_POS_FREE_TABLE_3_ID
           , DOI.DOI_TEXT_1
           , DOI.DOI_TEXT_2
           , DOI.DOI_TEXT_3
           , DOI.DOI_DECIMAL_1
           , DOI.DOI_DECIMAL_2
           , DOI.DOI_DECIMAL_3
           , DOI.DOI_DATE_1
           , DOI.DOI_DATE_2
           , DOI.DOI_DATE_3
           , DOI.C_INCOTERMS
           , DOI.PC_EXCHANGE_DATA_IN_ID
           , DOI.DOI_DOCUMENT_TYPE
           , DOI.DOI_INCOTERMS
           , DOI.DOI_INCOTERM_LOCATION
           , DOI.DOI_TOTAL_NET_WEIGHT
           , DOI.DOI_TOTAL_GROSS_WEIGHT
           , DOI.DOI_TOTAL_NET_WEIGHT_MEAS
           , DOI.DOI_TOTAL_GROSS_WEIGHT_MEAS
           , DOI.DOI_PARCEL_QTY
           , DOI.ACS_FINANCIAL_ACCOUNT_ID
           , DOI.ACS_DIVISION_ACCOUNT_ID
           , DOI.ACS_CPN_ACCOUNT_ID
           , DOI.ACS_CDA_ACCOUNT_ID
           , DOI.ACS_PF_ACCOUNT_ID
           , DOI.ACS_PJ_ACCOUNT_ID
        from DOC_INTERFACE DOI
       where DOI.DOC_INTERFACE_ID = cInterfaceID;

    tplInterfaceInfo crInterfaceInfo%rowtype;
  begin
    open crInterfaceInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_INTERFACE_ID);

    fetch crInterfaceInfo
     into tplInterfaceInfo;

    if crInterfaceInfo%found then
      -- Tiers
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID      := tplInterfaceInfo.PAC_THIRD_ID;

      -- Partenaire facturation
      if tplInterfaceInfo.PAC_THIRD_ACI_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID      := tplInterfaceInfo.PAC_THIRD_ACI_ID;
      end if;

      -- Partenaire livraison
      if tplInterfaceInfo.PAC_THIRD_DELIVERY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID      := tplInterfaceInfo.PAC_THIRD_DELIVERY_ID;
      end if;

      -- Partenaire tarification
      if tplInterfaceInfo.PAC_THIRD_TARIFF_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID      := tplInterfaceInfo.PAC_THIRD_TARIFF_ID;
      end if;

      -- n° document Interface
      if tplInterfaceInfo.DOI_NUMBER is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DOI_NUMBER  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DOI_NUMBER      := tplInterfaceInfo.DOI_NUMBER;
      end if;

      -- N° du document final
      if tplInterfaceInfo.DMT_NUMBER is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER  := tplInterfaceInfo.DMT_NUMBER;
      end if;

      -- Texte titre
      if tplInterfaceInfo.DOI_TITLE_TEXT is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TITLE_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TITLE_TEXT      := tplInterfaceInfo.DOI_TITLE_TEXT;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_APPLTXT_ID   := null;
      end if;

      -- Texte entête
      if tplInterfaceInfo.DOI_HEADING_TEXT is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_HEADING_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_HEADING_TEXT      := tplInterfaceInfo.DOI_HEADING_TEXT;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_APPLTXT_ID         := null;
      end if;

      -- Texte document
      if tplInterfaceInfo.DOI_DOCUMENT_TEXT is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DOCUMENT_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DOCUMENT_TEXT      := tplInterfaceInfo.DOI_DOCUMENT_TEXT;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_APPLTXT_ID     := null;
      end if;

      -- Dossier
      if tplInterfaceInfo.DOC_RECORD_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID      := tplInterfaceInfo.DOC_RECORD_ID;
      end if;

      -- Représentant
      if tplInterfaceInfo.PAC_REPRESENTATIVE_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID      := tplInterfaceInfo.PAC_REPRESENTATIVE_ID;
      end if;

      -- Représentant facturation
      if tplInterfaceInfo.PAC_REPR_ACI_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_ACI_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_ACI_ID      := tplInterfaceInfo.PAC_REPR_ACI_ID;
      end if;

      -- Représentant livraison
      if tplInterfaceInfo.PAC_REPR_DELIVERY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_DELIVERY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_DELIVERY_ID      := tplInterfaceInfo.PAC_REPR_DELIVERY_ID;
      end if;

      -- Mode d'expédition
      if tplInterfaceInfo.PAC_SENDING_CONDITION_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SENDING_CONDITION_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SENDING_CONDITION_ID      := tplInterfaceInfo.PAC_SENDING_CONDITION_ID;
      end if;

      -- Canal de distribution
      if tplInterfaceInfo.PAC_DISTRIBUTION_CHANNEL_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_DIST_CHANNEL_ID      := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_DISTRIBUTION_CHANNEL_ID  := tplInterfaceInfo.PAC_DISTRIBUTION_CHANNEL_ID;
      end if;

      -- Territoire de vente
      if tplInterfaceInfo.PAC_SALE_TERRITORY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SALE_TERRITORY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SALE_TERRITORY_ID      := tplInterfaceInfo.PAC_SALE_TERRITORY_ID;
      end if;

      -- Code langue
      if tplInterfaceInfo.PC_LANG_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID      := tplInterfaceInfo.PC_LANG_ID;
      end if;

      -- Code langue facturation
      if tplInterfaceInfo.PC_LANG_ACI_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ACI_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ACI_ID      := tplInterfaceInfo.PC_LANG_ACI_ID;
      end if;

      -- Code langue livraison
      if tplInterfaceInfo.PC_LANG_DELIVERY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_DELIVERY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_DELIVERY_ID      := tplInterfaceInfo.PC_LANG_DELIVERY_ID;
      end if;

      -- Monnaie
      if tplInterfaceInfo.ACS_FINANCIAL_CURRENCY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := tplInterfaceInfo.ACS_FINANCIAL_CURRENCY_ID;
      end if;

      -- Date document
      if tplInterfaceInfo.DOI_DOCUMENT_DATE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT  := tplInterfaceInfo.DOI_DOCUMENT_DATE;
      end if;

      -- Date valeur
      if tplInterfaceInfo.DOI_VALUE_DATE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE      := tplInterfaceInfo.DOI_VALUE_DATE;
      end if;

      -- Date livraison
      if tplInterfaceInfo.DOI_DELIVERY_DATE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_DELIVERY  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DELIVERY      := tplInterfaceInfo.DOI_DELIVERY_DATE;
      end if;

      -- Type de soumission
      if tplInterfaceInfo.DIC_TYPE_SUBMISSION_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_SUBMISSION_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID      := tplInterfaceInfo.DIC_TYPE_SUBMISSION_ID;
      end if;

      -- Condition de paiement
      if tplInterfaceInfo.PAC_PAYMENT_CONDITION_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID      := tplInterfaceInfo.PAC_PAYMENT_CONDITION_ID;
      end if;

      -- Tarif
      if tplInterfaceInfo.DIC_TARIFF_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TARIFF_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TARIFF_ID      := tplInterfaceInfo.DIC_TARIFF_ID;
      end if;

      -- Décompte TVA
      if tplInterfaceInfo.ACS_VAT_DET_ACCOUNT_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_VAT_DET_ACCOUNT_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID      := tplInterfaceInfo.ACS_VAT_DET_ACCOUNT_ID;
      end if;

      -- Méthode de paiement
      if tplInterfaceInfo.ACS_FIN_ACC_S_PAYMENT_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_FIN_ACC_S_PAYMENT_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FIN_ACC_S_PAYMENT_ID      := tplInterfaceInfo.ACS_FIN_ACC_S_PAYMENT_ID;
      end if;

      -- Référence du document
      if tplInterfaceInfo.DOI_REFERENCE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_REFERENCE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_REFERENCE      := tplInterfaceInfo.DOI_REFERENCE;
      end if;

      -- Référence partenaire
      if tplInterfaceInfo.DOI_PARTNER_REFERENCE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_REFERENCE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_REFERENCE      := tplInterfaceInfo.DOI_PARTNER_REFERENCE;
      end if;

      -- N° document partenaire
      if tplInterfaceInfo.DOI_PARTNER_NUMBER is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_NUMBER  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_NUMBER      := tplInterfaceInfo.DOI_PARTNER_NUMBER;
      end if;

      -- Date document partenaire
      if tplInterfaceInfo.DOI_PARTNER_DATE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_PARTNER_DOCUMENT      := tplInterfaceInfo.DOI_PARTNER_DATE;
      end if;

      -- Adresse 1
      if    tplInterfaceInfo.PAC_ADDRESS_ID is not null
         or tplInterfaceInfo.DOI_ADDRESS1 is not null
         or tplInterfaceInfo.PC_CNTRY_ID is not null
         or tplInterfaceInfo.DOI_ZIPCODE1 is not null
         or tplInterfaceInfo.DOI_TOWN1 is not null
         or tplInterfaceInfo.DOI_STATE1 is not null
         or tplInterfaceInfo.DOI_NAME1 is not null
         or tplInterfaceInfo.DOI_FORENAME1 is not null
         or tplInterfaceInfo.DOI_ACTIVITY1 is not null
         or tplInterfaceInfo.DOI_CARE_OF1 is not null
         or tplInterfaceInfo.DOI_PO_BOX1 is not null
         or tplInterfaceInfo.DOI_PO_BOX_NBR1 is not null
         or tplInterfaceInfo.DOI_COUNTY1 is not null
         or tplInterfaceInfo.DOI_CONTACT1 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_1    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID   := tplInterfaceInfo.PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1     := tplInterfaceInfo.DOI_ADDRESS1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID      := tplInterfaceInfo.PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1    := tplInterfaceInfo.DOI_ZIPCODE1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1        := tplInterfaceInfo.DOI_TOWN1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1       := tplInterfaceInfo.DOI_STATE1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1        := tplInterfaceInfo.DOI_NAME1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1    := tplInterfaceInfo.DOI_FORENAME1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1    := tplInterfaceInfo.DOI_ACTIVITY1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1     := tplInterfaceInfo.DOI_CARE_OF1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1      := tplInterfaceInfo.DOI_PO_BOX1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1  := tplInterfaceInfo.DOI_PO_BOX_NBR1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1      := tplInterfaceInfo.DOI_COUNTY1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1     := tplInterfaceInfo.DOI_CONTACT1;
      end if;

      -- Adresse 2
      if    tplInterfaceInfo.PAC_PAC_ADDRESS_ID is not null
         or tplInterfaceInfo.DOI_ADDRESS2 is not null
         or tplInterfaceInfo.PC__PC_CNTRY_ID is not null
         or tplInterfaceInfo.DOI_ZIPCODE2 is not null
         or tplInterfaceInfo.DOI_TOWN2 is not null
         or tplInterfaceInfo.DOI_STATE2 is not null
         or tplInterfaceInfo.DOI_NAME2 is not null
         or tplInterfaceInfo.DOI_FORENAME2 is not null
         or tplInterfaceInfo.DOI_ACTIVITY2 is not null
         or tplInterfaceInfo.DOI_CARE_OF2 is not null
         or tplInterfaceInfo.DOI_PO_BOX2 is not null
         or tplInterfaceInfo.DOI_PO_BOX_NBR2 is not null
         or tplInterfaceInfo.DOI_COUNTY2 is not null
         or tplInterfaceInfo.DOI_CONTACT2 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_2       := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAC_ADDRESS_ID  := tplInterfaceInfo.PAC_PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS2        := tplInterfaceInfo.DOI_ADDRESS2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_CNTRY_ID     := tplInterfaceInfo.PC__PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE2       := tplInterfaceInfo.DOI_ZIPCODE2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN2           := tplInterfaceInfo.DOI_TOWN2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE2          := tplInterfaceInfo.DOI_STATE2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME2           := tplInterfaceInfo.DOI_NAME2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME2       := tplInterfaceInfo.DOI_FORENAME2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY2       := tplInterfaceInfo.DOI_ACTIVITY2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF2        := tplInterfaceInfo.DOI_CARE_OF2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX2         := tplInterfaceInfo.DOI_PO_BOX2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR2     := tplInterfaceInfo.DOI_PO_BOX_NBR2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY2         := tplInterfaceInfo.DOI_COUNTY2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT2        := tplInterfaceInfo.DOI_CONTACT2;
      end if;

      -- Adresse 3
      if    tplInterfaceInfo.PAC2_PAC_ADDRESS_ID is not null
         or tplInterfaceInfo.DOI_ADDRESS3 is not null
         or tplInterfaceInfo.PC_2_PC_CNTRY_ID is not null
         or tplInterfaceInfo.DOI_ZIPCODE3 is not null
         or tplInterfaceInfo.DOI_TOWN3 is not null
         or tplInterfaceInfo.DOI_STATE3 is not null
         or tplInterfaceInfo.DOI_NAME3 is not null
         or tplInterfaceInfo.DOI_FORENAME3 is not null
         or tplInterfaceInfo.DOI_ACTIVITY3 is not null
         or tplInterfaceInfo.DOI_CARE_OF3 is not null
         or tplInterfaceInfo.DOI_PO_BOX3 is not null
         or tplInterfaceInfo.DOI_PO_BOX_NBR3 is not null
         or tplInterfaceInfo.DOI_COUNTY3 is not null
         or tplInterfaceInfo.DOI_CONTACT3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_3        := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC2_PAC_ADDRESS_ID  := tplInterfaceInfo.PAC2_PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS3         := tplInterfaceInfo.DOI_ADDRESS3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_CNTRY_ID     := tplInterfaceInfo.PC_2_PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE3        := tplInterfaceInfo.DOI_ZIPCODE3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN3            := tplInterfaceInfo.DOI_TOWN3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE3           := tplInterfaceInfo.DOI_STATE3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME3            := tplInterfaceInfo.DOI_NAME3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME3        := tplInterfaceInfo.DOI_FORENAME3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY3        := tplInterfaceInfo.DOI_ACTIVITY3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF3         := tplInterfaceInfo.DOI_CARE_OF3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX3          := tplInterfaceInfo.DOI_PO_BOX3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR3      := tplInterfaceInfo.DOI_PO_BOX_NBR3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY3          := tplInterfaceInfo.DOI_COUNTY3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT3         := tplInterfaceInfo.DOI_CONTACT3;
      end if;

      -- Dicos libres
      if    tplInterfaceInfo.DIC_POS_FREE_TABLE_1_ID is not null
         or tplInterfaceInfo.DIC_POS_FREE_TABLE_2_ID is not null
         or tplInterfaceInfo.DIC_POS_FREE_TABLE_3_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_POS_FREE_TABLE   := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_1_ID  := tplInterfaceInfo.DIC_POS_FREE_TABLE_1_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_2_ID  := tplInterfaceInfo.DIC_POS_FREE_TABLE_2_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_3_ID  := tplInterfaceInfo.DIC_POS_FREE_TABLE_3_ID;
      end if;

      -- Textes libres
      if    tplInterfaceInfo.DOI_TEXT_1 is not null
         or tplInterfaceInfo.DOI_TEXT_2 is not null
         or tplInterfaceInfo.DOI_TEXT_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_1    := tplInterfaceInfo.DOI_TEXT_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_2    := tplInterfaceInfo.DOI_TEXT_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_3    := tplInterfaceInfo.DOI_TEXT_3;
      end if;

      -- Décimaux libres
      if    tplInterfaceInfo.DOI_DECIMAL_1 is not null
         or tplInterfaceInfo.DOI_DECIMAL_2 is not null
         or tplInterfaceInfo.DOI_DECIMAL_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DECIMAL  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_1    := tplInterfaceInfo.DOI_DECIMAL_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_2    := tplInterfaceInfo.DOI_DECIMAL_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_3    := tplInterfaceInfo.DOI_DECIMAL_3;
      end if;

      -- Dates libres
      if    tplInterfaceInfo.DOI_DATE_1 is not null
         or tplInterfaceInfo.DOI_DATE_2 is not null
         or tplInterfaceInfo.DOI_DATE_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_1    := tplInterfaceInfo.DOI_DATE_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_2    := tplInterfaceInfo.DOI_DATE_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_3    := tplInterfaceInfo.DOI_DATE_3;
      end if;

      -- Document entrant
      if tplInterfaceInfo.PC_EXCHANGE_DATA_IN_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_EXCHANGE_DATA_IN    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_EXCHANGE_DATA_IN_ID  := tplInterfaceInfo.PC_EXCHANGE_DATA_IN_ID;
      end if;

      -- Récupère les incoterms
      if    tplInterfaceInfo.C_INCOTERMS is not null
         or tplInterfaceInfo.DOI_INCOTERM_LOCATION is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_INCOTERMS        := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS          := tplInterfaceInfo.C_INCOTERMS;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE  := tplInterfaceInfo.DOI_INCOTERM_LOCATION;
      end if;

      -- Poids total
      if    tplInterfaceInfo.DOI_TOTAL_NET_WEIGHT is not null
         or tplInterfaceInfo.DOI_TOTAL_GROSS_WEIGHT is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_TOTAL_WEIGHT    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_NET_WEIGHT    := tplInterfaceInfo.DOI_TOTAL_NET_WEIGHT;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_GROSS_WEIGHT  := tplInterfaceInfo.DOI_TOTAL_GROSS_WEIGHT;
      end if;

      -- Poids total mesuré
      if    tplInterfaceInfo.DOI_TOTAL_NET_WEIGHT_MEAS is not null
         or tplInterfaceInfo.DOI_TOTAL_GROSS_WEIGHT_MEAS is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_TOTAL_WEIGHT_MEAS    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_NET_WEIGHT_MEAS    := tplInterfaceInfo.DOI_TOTAL_NET_WEIGHT_MEAS;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_GROSS_WEIGHT_MEAS  := tplInterfaceInfo.DOI_TOTAL_GROSS_WEIGHT_MEAS;
      end if;

      -- Comptes
      if    (tplInterfaceInfo.ACS_FINANCIAL_ACCOUNT_ID is not null)
         or (tplInterfaceInfo.ACS_DIVISION_ACCOUNT_ID is not null)
         or (tplInterfaceInfo.ACS_CPN_ACCOUNT_ID is not null)
         or (tplInterfaceInfo.ACS_CDA_ACCOUNT_ID is not null)
         or (tplInterfaceInfo.ACS_PF_ACCOUNT_ID is not null)
         or (tplInterfaceInfo.ACS_PJ_ACCOUNT_ID is not null) then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACCOUNTS              := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_ACCOUNT_ID  := tplInterfaceInfo.ACS_FINANCIAL_ACCOUNT_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_DIVISION_ACCOUNT_ID   := tplInterfaceInfo.ACS_DIVISION_ACCOUNT_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CPN_ACCOUNT_ID        := tplInterfaceInfo.ACS_CPN_ACCOUNT_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CDA_ACCOUNT_ID        := tplInterfaceInfo.ACS_CDA_ACCOUNT_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PF_ACCOUNT_ID         := tplInterfaceInfo.ACS_PF_ACCOUNT_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PJ_ACCOUNT_ID         := tplInterfaceInfo.ACS_PJ_ACCOUNT_ID;
      end if;
    end if;

    close crInterfaceInfo;
  end InitDocument_140;

  /**
  *  procedure InitDocument_141
  *  Description
  *    Création - Générateur de documents concernant la dématérialisation
  */
  procedure InitDocument_141
  is
  begin
    -- L'initialisation du 141 est actuellement la même que celle du 140
    InitDocument_140;
  end InitDocument_141;

  /**
  *  procedure InitDocument_142
  *  Description
  *    Création - Générateur de documents - E-Shop
  */
  procedure InitDocument_142
  is
  begin
    -- L'initialisation du 142 est actuellement la même que celle du 140
    InitDocument_140;
  end InitDocument_142;

  /**
  *  procedure InitDocument_150
  *  Description
  *    Création - Dossiers SAV
  */
  procedure InitDocument_150
  is
    cursor crRecordInfo(cRecordID ASA_RECORD.ASA_RECORD_ID%type, aLangId PCS.PC_LANG.PC_LANG_ID%type)
    is
      select REC.*
           , ARD1.ARD_SHORT_DESCRIPTION ARD_SHORT_DESCRIPTION_1
           , ARD1.ARD_LONG_DESCRIPTION ARD_LONG_DESCRIPTION_1
           , ARD1.ARD_FREE_DESCRIPTION ARD_FREE_DESCRIPTION_1
           , ARD2.ARD_SHORT_DESCRIPTION ARD_SHORT_DESCRIPTION_2
           , ARD2.ARD_LONG_DESCRIPTION ARD_LONG_DESCRIPTION_2
           , ARD2.ARD_FREE_DESCRIPTION ARD_FREE_DESCRIPTION_2
           , GAU.GAU_DOSSIER
           , GAU.C_ADMIN_DOMAIN
           , decode(GAU.C_ADMIN_DOMAIN, '1', REC.PAC_SUPPLIER_PARTNER_ID, REC.PAC_CUSTOM_PARTNER_ID) PAC_THIRD_ID
           , GAU.GAU_TRAVELLER
           , PER.PER_NAME
           , PER.PER_FORENAME
           , PER.PER_ACTIVITY
        from ASA_RECORD REC
           , ASA_RECORD_DESCR ARD1
           , ASA_RECORD_DESCR ARD2
           , DOC_GAUGE GAU
           , PAC_PERSON PER
       where REC.ASA_RECORD_ID = cRecordID
         and REC.ASA_RECORD_ID = ARD1.ASA_RECORD_ID(+)
         and GAU.DOC_GAUGE_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
         and ARD1.C_ASA_DESCRIPTION_TYPE(+) = '1'
         and ARD1.PC_LANG_ID(+) = aLangId
         and REC.ASA_RECORD_ID = ARD2.ASA_RECORD_ID(+)
         and ARD2.C_ASA_DESCRIPTION_TYPE(+) = '2'
         and ARD2.PC_LANG_ID(+) = aLangId
         and PER.PAC_PERSON_ID = decode(GAU.C_ADMIN_DOMAIN, '1', REC.PAC_SUPPLIER_PARTNER_ID, REC.PAC_CUSTOM_PARTNER_ID);

    tplRecordInfo crRecordInfo%rowtype;
    vLangId       PCS.PC_LANG.PC_LANG_ID%type;
  begin
    -- Recherche de la langue utilisée selon le type de gabarit : Achat ou Vente
    select decode(GAU.C_ADMIN_DOMAIN, '1', REC.PC_ASA_SUP_LANG_ID, REC.PC_ASA_CUST_LANG_ID)
      into vLangId
      from ASA_RECORD REC
         , DOC_GAUGE GAU
     where REC.ASA_RECORD_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.ASA_RECORD_ID
       and GAU.DOC_GAUGE_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID;

    open crRecordInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.ASA_RECORD_ID, vLangId);

    fetch crRecordInfo
     into tplRecordInfo;

    if crRecordInfo%found then
      -- Tiers
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID           := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID               := tplRecordInfo.PAC_THIRD_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID       := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID           := tplRecordInfo.PAC_THIRD_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID      := tplRecordInfo.PAC_THIRD_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID    := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID        := tplRecordInfo.PAC_THIRD_ID;

      -- Code langue
      if vLangId is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID      := vLangId;
      end if;

      -- Dossier
      if     tplRecordInfo.GAU_DOSSIER = 1
         and tplRecordInfo.DOC_RECORD_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID      := tplRecordInfo.DOC_RECORD_ID;
      end if;

      -- Document du domaine "Vente"
      if tplRecordInfo.C_ADMIN_DOMAIN = '2' then
        -- Adresse 1
        if    tplRecordInfo.PAC_ASA_ADDR1_ID is not null
           or tplRecordInfo.PC_ASA_CNTRY1_ID is not null
           or tplRecordInfo.ARE_ADDRESS1 is not null
           or tplRecordInfo.ARE_POSTCODE1 is not null
           or tplRecordInfo.ARE_TOWN1 is not null
           or tplRecordInfo.ARE_STATE1 is not null
           or tplRecordInfo.ARE_CARE_OF1 is not null
           or tplRecordInfo.ARE_PO_BOX1 is not null
           or tplRecordInfo.ARE_PO_BOX_NBR1 is not null
           or tplRecordInfo.ARE_COUNTY1 is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_1    := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID   := tplRecordInfo.PAC_ASA_ADDR1_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID      := tplRecordInfo.PC_ASA_CNTRY1_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1     := tplRecordInfo.ARE_ADDRESS1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1    := tplRecordInfo.ARE_POSTCODE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1        := tplRecordInfo.ARE_TOWN1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1       := tplRecordInfo.ARE_STATE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1        := tplRecordInfo.PER_NAME;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1    := tplRecordInfo.PER_FORENAME;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1    := tplRecordInfo.PER_ACTIVITY;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1     := tplRecordInfo.ARE_CARE_OF1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1      := tplRecordInfo.ARE_PO_BOX1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1  := tplRecordInfo.ARE_PO_BOX_NBR1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1      := tplRecordInfo.ARE_COUNTY1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1     := null;
        end if;

        -- Adresse 2
        if    tplRecordInfo.PAC_ASA_ADDR2_ID is not null
           or tplRecordInfo.PC_ASA_CNTRY2_ID is not null
           or tplRecordInfo.ARE_ADDRESS2 is not null
           or tplRecordInfo.ARE_POSTCODE2 is not null
           or tplRecordInfo.ARE_TOWN2 is not null
           or tplRecordInfo.ARE_STATE2 is not null
           or tplRecordInfo.ARE_CARE_OF2 is not null
           or tplRecordInfo.ARE_PO_BOX2 is not null
           or tplRecordInfo.ARE_PO_BOX_NBR2 is not null
           or tplRecordInfo.ARE_COUNTY2 is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_2       := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAC_ADDRESS_ID  := tplRecordInfo.PAC_ASA_ADDR2_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_CNTRY_ID     := tplRecordInfo.PC_ASA_CNTRY2_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS2        := tplRecordInfo.ARE_ADDRESS2;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE2       := tplRecordInfo.ARE_POSTCODE2;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN2           := tplRecordInfo.ARE_TOWN2;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE2          := tplRecordInfo.ARE_STATE2;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME2           := tplRecordInfo.PER_NAME;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME2       := tplRecordInfo.PER_FORENAME;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY2       := tplRecordInfo.PER_ACTIVITY;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF2        := tplRecordInfo.ARE_CARE_OF2;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX2         := tplRecordInfo.ARE_PO_BOX2;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR2     := tplRecordInfo.ARE_PO_BOX_NBR2;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY2         := tplRecordInfo.ARE_COUNTY2;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT2        := null;
        else   -- identique à l'adresse 1
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_2       := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAC_ADDRESS_ID  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_CNTRY_ID     := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS2        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE2       := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN2           := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE2          := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME2           := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME2       := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY2       := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF2        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX2         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR2     := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY2         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT2        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1;
        end if;

        -- Adresse 3
        if    tplRecordInfo.PAC_ASA_ADDR3_ID is not null
           or tplRecordInfo.PC_ASA_CNTRY3_ID is not null
           or tplRecordInfo.ARE_ADDRESS3 is not null
           or tplRecordInfo.ARE_POSTCODE3 is not null
           or tplRecordInfo.ARE_TOWN3 is not null
           or tplRecordInfo.ARE_STATE3 is not null
           or tplRecordInfo.ARE_CARE_OF3 is not null
           or tplRecordInfo.ARE_PO_BOX3 is not null
           or tplRecordInfo.ARE_PO_BOX_NBR3 is not null
           or tplRecordInfo.ARE_COUNTY3 is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_3        := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC2_PAC_ADDRESS_ID  := tplRecordInfo.PAC_ASA_ADDR3_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_CNTRY_ID     := tplRecordInfo.PC_ASA_CNTRY3_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS3         := tplRecordInfo.ARE_ADDRESS3;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE3        := tplRecordInfo.ARE_POSTCODE3;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN3            := tplRecordInfo.ARE_TOWN3;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE3           := tplRecordInfo.ARE_STATE3;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME3            := tplRecordInfo.PER_NAME;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME3        := tplRecordInfo.PER_FORENAME;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY3        := tplRecordInfo.PER_ACTIVITY;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF3         := tplRecordInfo.ARE_CARE_OF3;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX3          := tplRecordInfo.ARE_PO_BOX3;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR3      := tplRecordInfo.ARE_PO_BOX_NBR3;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY3          := tplRecordInfo.ARE_COUNTY3;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT3         := null;
        else   -- identique à l'adresse 1
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_3        := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC2_PAC_ADDRESS_ID  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_CNTRY_ID     := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS3         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE3        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN3            := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE3           := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME3            := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME3        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY3        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF3         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX3          := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR3      := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY3          := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT3         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1;
        end if;

        -- Représentant
        if     tplRecordInfo.GAU_TRAVELLER = 1
           and tplRecordInfo.PAC_REPRESENTATIVE_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID      := tplRecordInfo.PAC_REPRESENTATIVE_ID;
        end if;

        -- Condition de paiement
        if tplRecordInfo.PAC_PAYMENT_CONDITION_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID      := tplRecordInfo.PAC_PAYMENT_CONDITION_ID;
        end if;

        -- Méthode de paiement
        if tplRecordInfo.ACS_FIN_ACC_S_PAYMENT_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_FIN_ACC_S_PAYMENT_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FIN_ACC_S_PAYMENT_ID      := tplRecordInfo.ACS_FIN_ACC_S_PAYMENT_ID;
        end if;

        -- Monnaie
        if tplRecordInfo.ACS_FINANCIAL_CURRENCY_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := tplRecordInfo.ACS_FINANCIAL_CURRENCY_ID;
        end if;

        -- Mode d'expédition
        if tplRecordInfo.PAC_SENDING_CONDITION_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SENDING_CONDITION_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SENDING_CONDITION_ID      := tplRecordInfo.PAC_SENDING_CONDITION_ID;
        end if;

        -- Type de soumission
        if tplRecordInfo.DIC_TYPE_SUBMISSION_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_SUBMISSION_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID      := tplRecordInfo.DIC_TYPE_SUBMISSION_ID;
        end if;
      else   -- Document dont le domaine est différent de "Vente"
        if    tplRecordInfo.PAC_ASA_SUPPLIER_ADDR_ID is not null
           or tplRecordInfo.PC_ASA_SUPPLIER_CNTRY_ID is not null
           or tplRecordInfo.ARE_ADDRESS_SUPPLIER is not null
           or tplRecordInfo.ARE_POSTCODE_SUPPLIER is not null
           or tplRecordInfo.ARE_TOWN_SUPPLIER is not null
           or tplRecordInfo.ARE_STATE_SUPPLIER is not null
           or tplRecordInfo.ARE_CARE_OF_SUP is not null
           or tplRecordInfo.ARE_PO_BOX_SUP is not null
           or tplRecordInfo.ARE_PO_BOX_NBR_SUP is not null
           or tplRecordInfo.ARE_COUNTY_SUP is not null then
          -- Adresse 1
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_1        := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID       := tplRecordInfo.PAC_ASA_SUPPLIER_ADDR_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID          := tplRecordInfo.PC_ASA_SUPPLIER_CNTRY_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1         := tplRecordInfo.ARE_ADDRESS_SUPPLIER;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1        := tplRecordInfo.ARE_POSTCODE_SUPPLIER;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1            := tplRecordInfo.ARE_TOWN_SUPPLIER;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1           := tplRecordInfo.ARE_STATE_SUPPLIER;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1            := tplRecordInfo.PER_NAME;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1        := tplRecordInfo.PER_FORENAME;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1        := tplRecordInfo.PER_ACTIVITY;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1         := tplRecordInfo.ARE_CARE_OF_SUP;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1          := tplRecordInfo.ARE_PO_BOX_SUP;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1      := tplRecordInfo.ARE_PO_BOX_NBR_SUP;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1          := tplRecordInfo.ARE_COUNTY_SUP;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1         := null;
          -- Adresse 2
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_2        := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAC_ADDRESS_ID   := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_CNTRY_ID      := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS2         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE2        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN2            := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE2           := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME2            := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME2        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY2        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF2         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX2          := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR2      := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY2          := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT2         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1;
          -- Adresse 3
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_3        := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC2_PAC_ADDRESS_ID  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_CNTRY_ID     := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS3         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE3        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN3            := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE3           := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME3            := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME3        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY3        := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF3         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX3          := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR3      := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY3          := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT3         := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1;
        end if;

        -- Monnaie
        if tplRecordInfo.ACS_ASA_SUP_FIN_CURR_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := tplRecordInfo.ACS_ASA_SUP_FIN_CURR_ID;
        end if;

        -- Dossier sous-traitance
        if tplRecordInfo.ASA_RECORD_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ASA_RECORD_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.ASA_RECORD_ID      := tplRecordInfo.ASA_RECORD_ID;
        end if;
      end if;
    end if;

    close crRecordInfo;
  end InitDocument_150;

  /**
  *  procedure InitDocument_155
  *  Description
  *    Création - SAV externe (Facturation des interventions)
  */
  procedure InitDocument_155
  is
    cursor crMissionInfo(aProcessID ASA_INVOICING_PROCESS.ASA_INVOICING_PROCESS_ID%type)
    is
      select MIS.DOC_RECORD_ID
           , case
               when (select count(distinct PAC_CUSTOM_PARTNER_ID)
                       from ASA_INVOICING_PROCESS
                      where AIP_REGROUP_ID = AIP.AIP_REGROUP_ID) > 1 then AIP.PAC_CUSTOM_PARTNER_ACI_ID
               else AIP.PAC_CUSTOM_PARTNER_ID
             end PAC_CUSTOM_PARTNER_ID
           , AIP.PAC_CUSTOM_PARTNER_ACI_ID
           , case
               when (select count(distinct MIS2.PAC_CUSTOM_PARTNER_TARIFF_ID)
                       from ASA_INVOICING_PROCESS AIP2
                          , ASA_MISSION MIS2
                      where AIP2.AIP_REGROUP_ID = AIP.AIP_REGROUP_ID
                        and MIS2.ASA_MISSION_ID = AIP2.ASA_MISSION_ID
                        and MIS2.PAC_CUSTOM_PARTNER_TARIFF_ID is not null) > 1 then null
               else (select max(MIS2.PAC_CUSTOM_PARTNER_TARIFF_ID)
                       from ASA_INVOICING_PROCESS AIP2
                          , ASA_MISSION MIS2
                      where AIP2.AIP_REGROUP_ID = AIP.AIP_REGROUP_ID
                        and MIS2.ASA_MISSION_ID = AIP2.ASA_MISSION_ID
                        and MIS2.PAC_CUSTOM_PARTNER_TARIFF_ID is not null)
             end as PAC_CUSTOM_PARTNER_TARIFF_ID
           , AIP.ACS_FINANCIAL_CURRENCY_ID
           , nvl(AIP.PAC_PAYMENT_CONDITION_ID, GAS.PAC_PAYMENT_CONDITION_ID) PAC_PAYMENT_CONDITION_ID
           , MIS.PC_LANG_ID
           , GAU.GAU_DOSSIER
           , GAS_PAY_CONDITION
        from ASA_INVOICING_PROCESS AIP
           , ASA_MISSION MIS
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where ASA_INVOICING_PROCESS_ID = aProcessId
         and MIS.ASA_MISSION_ID = AIP.ASA_MISSION_ID
         and GAU.DOC_GAUGE_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    tplMissionInfo crMissionInfo%rowtype;
  begin
    open crMissionInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_SRC_ID);

    fetch crMissionInfo
     into tplMissionInfo;

    if crMissionInfo%found then
      -- Dossier
      if     tplMissionInfo.GAU_DOSSIER = 1
         and tplMissionInfo.DOC_RECORD_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID      := tplMissionInfo.DOC_RECORD_ID;
      end if;

      -- Tiers
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID           := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID               := tplMissionInfo.PAC_CUSTOM_PARTNER_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID      := tplMissionInfo.PAC_CUSTOM_PARTNER_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID       := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID           := tplMissionInfo.PAC_CUSTOM_PARTNER_ACI_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID    := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID        := tplMissionInfo.PAC_CUSTOM_PARTNER_TARIFF_ID;

      -- Monnaie
      if tplMissionInfo.ACS_FINANCIAL_CURRENCY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := tplMissionInfo.ACS_FINANCIAL_CURRENCY_ID;
      end if;

      -- Condition de paiement
      if     tplMissionInfo.GAS_PAY_CONDITION = 1
         and tplMissionInfo.PAC_PAYMENT_CONDITION_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID      := tplMissionInfo.PAC_PAYMENT_CONDITION_ID;
      end if;

      -- Code langue
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID             := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID                 := tplMissionInfo.PC_LANG_ID;
    end if;

    close crMissionInfo;
  end InitDocument_155;

  /**
  *  procedure InitDocument_160
  *  Description
  *    Création - Contrats de maintenance
  */
  procedure InitDocument_160
  is
    cursor crContractInfo(aPositionID CML_POSITION.CML_POSITION_ID%type)
    is
      select   CCO.CCO_DECIMAL_1 D_CCO_DECIMAL_1
             , CCO.CCO_DECIMAL_2 D_CCO_DECIMAL_2
             , CCO.CCO_DECIMAL_3 D_CCO_DECIMAL_3
             , CCO.CCO_TEXT_1 D_CCO_TEXT_1
             , CCO.CCO_TEXT_2 D_CCO_TEXT_2
             , CCO.CCO_TEXT_3 D_CCO_TEXT_3
             , CCO.DIC_POS_FREE_TABLE_1_ID D_DIC_POS_FREE_TABLE_1_ID
             , CCO.DIC_POS_FREE_TABLE_2_ID D_DIC_POS_FREE_TABLE_2_ID
             , CCO.DIC_POS_FREE_TABLE_3_ID D_DIC_POS_FREE_TABLE_3_ID
             , CCO.CCO_NUMBER
             , CCO.PAC_CUSTOM_PARTNER_ID
             , CCO.PAC_CUSTOM_PARTNER_ACI_ID
             , CCO.PAC_CUSTOM_PARTNER_TARIFF_ID
             , CCO.PC_LANG_ID
             , CCO.PAC_REPRESENTATIVE_ID
             , nvl(GAS.PAC_PAYMENT_CONDITION_ID, CCO.PAC_PAYMENT_CONDITION_ID) PAC_PAYMENT_CONDITION_ID
             , nvl(CPO.DOC_RECORD_ID, CCO.DOC_RECORD_ID) DOC_RECORD_ID
             , CPO.ACS_FINANCIAL_CURRENCY_ID
             , DES.GCDTEXT1
             , GAU.GAU_DOSSIER
             , GAU.GAU_TRAVELLER
             , GAS_PAY_CONDITION
          from CML_DOCUMENT CCO
             , CML_POSITION CPO
             , PCS.V_PC_DESCODES DES
             , DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
         where CPO.CML_POSITION_ID = aPositionId
           and CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
           and CPO.DOC_PROV_DOCUMENT_ID is null
           and DES.GCGNAME = 'C_CML_POS_TYPE'
           and DES.GCLCODE = CPO.C_CML_POS_TYPE
           and DES.PC_LANG_ID = CCO.PC_LANG_ID
           and GAU.DOC_GAUGE_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
           and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
      order by CCO.PAC_CUSTOM_PARTNER_ID
             , CPO.ACS_FINANCIAL_CURRENCY_ID
             , CCO.CCO_NUMBER
             , CPO.CPO_SEQUENCE;

    tplContractInfo crContractInfo%rowtype;
  begin
    open crContractInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.CML_POSITION_ID);

    fetch crContractInfo
     into tplContractInfo;

    if crContractInfo%found then
      -- Tiers
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID    := tplContractInfo.PAC_CUSTOM_PARTNER_ID;

      -- Tiers facturation
      if tplContractInfo.PAC_CUSTOM_PARTNER_ACI_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID      := tplContractInfo.PAC_CUSTOM_PARTNER_ACI_ID;
      end if;

      -- Tiers tarification
      if tplContractInfo.PAC_CUSTOM_PARTNER_TARIFF_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID      := tplContractInfo.PAC_CUSTOM_PARTNER_TARIFF_ID;
      end if;

      -- Code langue
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID      := tplContractInfo.PC_LANG_ID;

      -- Dossier
      if     tplContractInfo.GAU_DOSSIER = 1
         and tplContractInfo.DOC_RECORD_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID      := tplContractInfo.DOC_RECORD_ID;
      end if;

      -- Représentant
      if     tplContractInfo.GAU_TRAVELLER = 1
         and tplContractInfo.PAC_REPRESENTATIVE_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID      := tplContractInfo.PAC_REPRESENTATIVE_ID;
      end if;

      -- Condition de paiement
      if     tplContractInfo.GAS_PAY_CONDITION = 1
         and tplContractInfo.PAC_PAYMENT_CONDITION_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID      := tplContractInfo.PAC_PAYMENT_CONDITION_ID;
      end if;

      -- Monnaie
      if tplContractInfo.ACS_FINANCIAL_CURRENCY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := tplContractInfo.ACS_FINANCIAL_CURRENCY_ID;
      end if;

      -- Code tabelle libre
      if    tplContractInfo.D_DIC_POS_FREE_TABLE_1_ID is not null
         or tplContractInfo.D_DIC_POS_FREE_TABLE_2_ID is not null
         or tplContractInfo.D_DIC_POS_FREE_TABLE_3_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_POS_FREE_TABLE   := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_1_ID  := tplContractInfo.D_DIC_POS_FREE_TABLE_1_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_2_ID  := tplContractInfo.D_DIC_POS_FREE_TABLE_2_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_3_ID  := tplContractInfo.D_DIC_POS_FREE_TABLE_3_ID;
      end if;

      -- Champs texte
      if    tplContractInfo.D_CCO_TEXT_1 is not null
         or tplContractInfo.D_CCO_TEXT_2 is not null
         or tplContractInfo.D_CCO_TEXT_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_1    := tplContractInfo.D_CCO_TEXT_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_2    := tplContractInfo.D_CCO_TEXT_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_3    := tplContractInfo.D_CCO_TEXT_3;
      end if;

      -- Champs décimal
      if    tplContractInfo.D_CCO_DECIMAL_1 is not null
         or tplContractInfo.D_CCO_DECIMAL_2 is not null
         or tplContractInfo.D_CCO_DECIMAL_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DECIMAL  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_1    := tplContractInfo.D_CCO_DECIMAL_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_2    := tplContractInfo.D_CCO_DECIMAL_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_3    := tplContractInfo.D_CCO_DECIMAL_3;
      end if;
    end if;

    close crContractInfo;
  end InitDocument_160;

  /**
  *  procedure InitDocument_165
  *  Description
  *    Création - Facturation des contrats de maintenance
  */
  procedure InitDocument_165
  is
    cursor crContractInfo(aProcessID CML_INVOICING_PROCESS.CML_INVOICING_PROCESS_ID%type)
    is
      select   CCO.CCO_DECIMAL_1 D_CCO_DECIMAL_1
             , CCO.CCO_DECIMAL_2 D_CCO_DECIMAL_2
             , CCO.CCO_DECIMAL_3 D_CCO_DECIMAL_3
             , CCO.CCO_TEXT_1 D_CCO_TEXT_1
             , CCO.CCO_TEXT_2 D_CCO_TEXT_2
             , CCO.CCO_TEXT_3 D_CCO_TEXT_3
             , CCO.DIC_POS_FREE_TABLE_1_ID D_DIC_POS_FREE_TABLE_1_ID
             , CCO.DIC_POS_FREE_TABLE_2_ID D_DIC_POS_FREE_TABLE_2_ID
             , CCO.DIC_POS_FREE_TABLE_3_ID D_DIC_POS_FREE_TABLE_3_ID
             , CCO.CCO_NUMBER
             , INP.PAC_CUSTOM_PARTNER_ACI_ID
             , case
                 when (select count(distinct PAC_CUSTOM_PARTNER_ID)
                         from CML_INVOICING_PROCESS
                        where INP_REGROUP_ID = INP.INP_REGROUP_ID) > 1 then INP.PAC_CUSTOM_PARTNER_ACI_ID
                 else INP.PAC_CUSTOM_PARTNER_ID
               end PAC_CUSTOM_PARTNER_ID
             , INP.CML_INVOICING_JOB_ID
             , CCO.PC_LANG_ID
             , CCO.PAC_REPRESENTATIVE_ID
             , nvl(INP.PAC_PAYMENT_CONDITION_ID, GAS.PAC_PAYMENT_CONDITION_ID) PAC_PAYMENT_CONDITION_ID
             , nvl(CPO.DOC_RECORD_ID, CCO.DOC_RECORD_ID) DOC_RECORD_ID
             , INP.ACS_FINANCIAL_CURRENCY_ID
             , GAU.GAU_DOSSIER
             , GAU.GAU_TRAVELLER
             , GAS_PAY_CONDITION
          from CML_INVOICING_PROCESS INP
             , CML_DOCUMENT CCO
             , CML_POSITION CPO
             , DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
         where INP.CML_INVOICING_PROCESS_ID = aProcessID
           and CPO.CML_POSITION_ID = INP.CML_POSITION_ID
           and CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
           and CPO.DOC_PROV_DOCUMENT_ID is null
           and GAU.DOC_GAUGE_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
           and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
      order by CCO.PAC_CUSTOM_PARTNER_ACI_ID
             , CPO.ACS_FINANCIAL_CURRENCY_ID
             , CCO.CCO_NUMBER
             , CPO.CPO_SEQUENCE;

    tplContractInfo crContractInfo%rowtype;
  begin
    open crContractInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_SRC_ID);

    fetch crContractInfo
     into tplContractInfo;

    if crContractInfo%found then
      -- Tiers
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID           := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID               := tplContractInfo.PAC_CUSTOM_PARTNER_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID      := tplContractInfo.PAC_CUSTOM_PARTNER_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID       := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID           := tplContractInfo.PAC_CUSTOM_PARTNER_ACI_ID;
      -- Code langue
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID             := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID                 := tplContractInfo.PC_LANG_ID;
      -- ID du travail de facturation
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_CML_INVOICING_JOB_ID   := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.CML_INVOICING_JOB_ID       := tplContractInfo.CML_INVOICING_JOB_ID;

      -- Dossier
      if     tplContractInfo.GAU_DOSSIER = 1
         and tplContractInfo.DOC_RECORD_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID      := tplContractInfo.DOC_RECORD_ID;
      end if;

      -- Représentant
      if     tplContractInfo.GAU_TRAVELLER = 1
         and tplContractInfo.PAC_REPRESENTATIVE_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID      := tplContractInfo.PAC_REPRESENTATIVE_ID;
      end if;

      -- Condition de paiement
      if     tplContractInfo.GAS_PAY_CONDITION = 1
         and tplContractInfo.PAC_PAYMENT_CONDITION_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID      := tplContractInfo.PAC_PAYMENT_CONDITION_ID;
      end if;

      -- Monnaie
      if tplContractInfo.ACS_FINANCIAL_CURRENCY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := tplContractInfo.ACS_FINANCIAL_CURRENCY_ID;
      end if;

      -- Code tabelle libre
      if    tplContractInfo.D_DIC_POS_FREE_TABLE_1_ID is not null
         or tplContractInfo.D_DIC_POS_FREE_TABLE_2_ID is not null
         or tplContractInfo.D_DIC_POS_FREE_TABLE_3_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_POS_FREE_TABLE   := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_1_ID  := tplContractInfo.D_DIC_POS_FREE_TABLE_1_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_2_ID  := tplContractInfo.D_DIC_POS_FREE_TABLE_2_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_3_ID  := tplContractInfo.D_DIC_POS_FREE_TABLE_3_ID;
      end if;

      -- Champs texte
      if    tplContractInfo.D_CCO_TEXT_1 is not null
         or tplContractInfo.D_CCO_TEXT_2 is not null
         or tplContractInfo.D_CCO_TEXT_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_1    := tplContractInfo.D_CCO_TEXT_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_2    := tplContractInfo.D_CCO_TEXT_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_3    := tplContractInfo.D_CCO_TEXT_3;
      end if;

      -- Champs décimal
      if    tplContractInfo.D_CCO_DECIMAL_1 is not null
         or tplContractInfo.D_CCO_DECIMAL_2 is not null
         or tplContractInfo.D_CCO_DECIMAL_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DECIMAL  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_1    := tplContractInfo.D_CCO_DECIMAL_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_2    := tplContractInfo.D_CCO_DECIMAL_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_3    := tplContractInfo.D_CCO_DECIMAL_3;
      end if;
    end if;

    close crContractInfo;
  end InitDocument_165;

  /**
  *  procedure InitDocument_170
  *  Description
  *    Création - Assistant des devis
  */
  procedure InitDocument_170
  is
  begin
    null;
  end InitDocument_170;

  /**
  *  procedure InitDocument_180
  *  Description
  *    Création - Extraction des commissions
  */
  procedure InitDocument_180
  is
  begin
    null;
  end InitDocument_180;

  /**
  *  procedure InitDocument_205
  *  Description
  *    Copie - Duplication document gestion des documents
  */
  procedure InitDocument_205
  is
    -- Informations du document source
    cursor crInfoDocSource(cDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select DOC.ACS_FINANCIAL_CURRENCY_ID
           , DOC.DMT_RATE_OF_EXCHANGE
           , DOC.DMT_BASE_PRICE
           , DOC.DMT_RATE_EURO
           , DOC.ACS_ACS_FINANCIAL_CURRENCY_ID
           , DOC.DMT_VAT_EXCHANGE_RATE
           , DOC.DMT_VAT_BASE_PRICE
           , DOC.ACS_VAT_DET_ACCOUNT_ID
           , DOC.DIC_TYPE_SUBMISSION_ID
           , DOC.PAC_THIRD_ID
           , DOC.PAC_THIRD_ACI_ID
           , DOC.PAC_THIRD_DELIVERY_ID
           , DOC.PAC_THIRD_TARIFF_ID
           , DOC.PC_LANG_ID
           , DOC.PC_LANG_ACI_ID
           , DOC.PC_LANG_DELIVERY_ID
           , DOC.DOC_RECORD_ID
           , DOC.ACS_FINANCIAL_ACCOUNT_ID
           , DOC.ACS_DIVISION_ACCOUNT_ID
           , DOC.PAC_PAYMENT_CONDITION_ID
           , DOC.PAC_SENDING_CONDITION_ID
           , DOC.PAC_REPRESENTATIVE_ID
           , DOC.PAC_REPR_ACI_ID
           , DOC.PAC_REPR_DELIVERY_ID
           , DOC.PAC_FINANCIAL_REFERENCE_ID
           , DOC.DIC_TARIFF_ID
           , DOC.PAC_ADDRESS_ID
           , DOC.DMT_ADDRESS1
           , DOC.DMT_POSTCODE1
           , DOC.DMT_TOWN1
           , DOC.DMT_STATE1
           , DOC.DMT_NAME1
           , DOC.DMT_FORENAME1
           , DOC.DMT_ACTIVITY1
           , DOC.DMT_CARE_OF1
           , DOC.DMT_PO_BOX1
           , DOC.DMT_PO_BOX_NBR1
           , DOC.DMT_COUNTY1
           , DOC.DMT_CONTACT1
           , DOC.PC_CNTRY_ID
           , DOC.PAC_PAC_ADDRESS_ID
           , DOC.DMT_ADDRESS2
           , DOC.DMT_POSTCODE2
           , DOC.DMT_TOWN2
           , DOC.DMT_STATE2
           , DOC.DMT_NAME2
           , DOC.DMT_FORENAME2
           , DOC.DMT_ACTIVITY2
           , DOC.DMT_CARE_OF2
           , DOC.DMT_PO_BOX2
           , DOC.DMT_PO_BOX_NBR2
           , DOC.DMT_COUNTY2
           , DOC.DMT_CONTACT2
           , DOC.PC__PC_CNTRY_ID
           , DOC.PAC2_PAC_ADDRESS_ID
           , DOC.DMT_ADDRESS3
           , DOC.DMT_POSTCODE3
           , DOC.DMT_TOWN3
           , DOC.DMT_STATE3
           , DOC.DMT_NAME3
           , DOC.DMT_FORENAME3
           , DOC.DMT_ACTIVITY3
           , DOC.DMT_CARE_OF3
           , DOC.DMT_PO_BOX3
           , DOC.DMT_PO_BOX_NBR3
           , DOC.DMT_COUNTY3
           , DOC.DMT_CONTACT3
           , DOC.PC_2_PC_CNTRY_ID
           , DOC.PC_APPLTXT_ID
           , DOC.DMT_HEADING_TEXT
           , DOC.PC__PC_APPLTXT_ID
           , DOC.DMT_TITLE_TEXT
           , DOC.PC_2_PC_APPLTXT_ID
           , DOC.DMT_DOCUMENT_TEXT
           , DOC.C_INCOTERMS
           , DOC.DMT_INCOTERMS_PLACE
           , DOC.PAC_DISTRIBUTION_CHANNEL_ID
           , DOC.PAC_SALE_TERRITORY_ID
           , DOC.ACS_FIN_ACC_S_PAYMENT_ID
           , DOC.DMT_DATE_DELIVERY
           , DOC.DMT_RATE_FACTOR
           , DOC.DMT_PARTNER_NUMBER
           , DOC.DMT_PARTNER_REFERENCE
           , DOC.DMT_DATE_PARTNER_DOCUMENT
           , DOC.DMT_REFERENCE
           , DOC.DIC_GAUGE_FREE_CODE_1_ID
           , DOC.DIC_GAUGE_FREE_CODE_2_ID
           , DOC.DIC_GAUGE_FREE_CODE_3_ID
           , DOC.DMT_GAU_FREE_NUMBER1
           , DOC.DMT_GAU_FREE_NUMBER2
           , DOC.DMT_GAU_FREE_DATE1
           , DOC.DMT_GAU_FREE_DATE2
           , DOC.DMT_GAU_FREE_BOOL1
           , DOC.DMT_GAU_FREE_BOOL2
           , DOC.DMT_GAU_FREE_TEXT_LONG
           , DOC.DMT_GAU_FREE_TEXT_SHORT
           , DOC.DIC_POS_FREE_TABLE_1_ID
           , DOC.DIC_POS_FREE_TABLE_2_ID
           , DOC.DIC_POS_FREE_TABLE_3_ID
           , DOC.DMT_TEXT_1
           , DOC.DMT_TEXT_2
           , DOC.DMT_TEXT_3
           , DOC.DMT_DECIMAL_1
           , DOC.DMT_DECIMAL_2
           , DOC.DMT_DECIMAL_3
           , DOC.DMT_DATE_1
           , DOC.DMT_DATE_2
           , DOC.DMT_DATE_3
           , DOC.DMT_FIN_DOC_BLOCKED
           , DOC.DIC_BLOCKED_REASON_ID
           , DOC.C_THIRD_MATERIAL_RELATION_TYPE
           , FOO.PC_APPLTXT_ID FOOT_PC_APPLTXT_ID
           , FOO.PC__PC_APPLTXT_ID FOOT_PC__PC_APPLTXT_ID
           , FOO.PC_2_PC_APPLTXT_ID FOOT_PC_2_PC_APPLTXT_ID
           , FOO.PC_3_PC_APPLTXT_ID FOOT_PC_3_PC_APPLTXT_ID
           , FOO.PC_4_PC_APPLTXT_ID FOOT_PC_4_PC_APPLTXT_ID
           , FOO.FOO_FOOT_TEXT
           , FOO.FOO_FOOT_TEXT2
           , FOO.FOO_FOOT_TEXT3
           , FOO.FOO_FOOT_TEXT4
           , FOO.FOO_FOOT_TEXT5
           , FOO.DOC_GAUGE_SIGNATORY_ID
           , FOO.DOC_DOC_GAUGE_SIGNATORY_ID
           , FOO.FOO_PACKAGING
           , FOO.FOO_MARKING
           , FOO.FOO_MEASURE
           , GAU.C_ADMIN_DOMAIN
           , nvl(GAS.GAS_WEIGHT_MAT, 0) GAS_WEIGHT_MAT
           , GAU.DOC_GAUGE_ID
        from DOC_DOCUMENT DOC
           , DOC_FOOT FOO
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where DOC.DOC_DOCUMENT_ID = cDocumentID
         and DOC.DOC_DOCUMENT_ID = FOO.DOC_FOOT_ID
         and GAU.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID;

    tplInfoDocSource       crInfoDocSource%rowtype;

    -- informations sur le gabarit du document à créér
    cursor crGaugeInfo(cGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select GAU.C_ADMIN_DOMAIN
           , GAU.GAU_REF_PARTNER
           , GAU.GAU_DOSSIER
           , GAU.PAC_THIRD_ID
           , GAU.PAC_THIRD_ACI_ID
           , GAU.PAC_THIRD_DELIVERY_ID
           , GAU.GAU_FREE_DATA_USE
           , GAU.GAU_COPY_SOURCE_FREE_DATA
           , GAU.PC_APPLTXT_ID
           , GAU.PC__PC_APPLTXT_ID
           , nvl(GAS.C_DOC_PRE_ENTRY, '0') C_DOC_PRE_ENTRY
           , nvl(GAS.C_DOC_PRE_ENTRY_THIRD, '0') C_DOC_PRE_ENTRY_THIRD
           , nvl(GAS.GAS_VAT, 0) GAS_VAT
           , nvl(GAS.GAS_FINANCIAL_REF, 0) GAS_FINANCIAL_REF
           , GAS.PAC_PAYMENT_CONDITION_ID
           , nvl(GAS.GAS_WEIGHT_MAT, 0) GAS_WEIGHT_MAT
           , GAS.GAS_INVOICE_EXPIRY
        from DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = cGaugeID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID(+);

    tplGaugeInfo           crGaugeInfo%rowtype;

    cursor crPartnerInfo(cThirdID in PAC_THIRD.PAC_THIRD_ID%type, cGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then VAT_SUP.ACS_FINANCIAL_CURRENCY_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then VAT_CUS.ACS_FINANCIAL_CURRENCY_ID
                else nvl(VAT_CUS.ACS_FINANCIAL_CURRENCY_ID, VAT_SUP.ACS_FINANCIAL_CURRENCY_ID)
              end
             ) VAT_CURRENCY_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_PAYMENT_CONDITION_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_PAYMENT_CONDITION_ID
                else nvl(CUS.PAC_PAYMENT_CONDITION_ID, SUP.PAC_PAYMENT_CONDITION_ID)
              end
             ) PAC_PAYMENT_CONDITION_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_SENDING_CONDITION_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_SENDING_CONDITION_ID
                else nvl(CUS.PAC_SENDING_CONDITION_ID, SUP.PAC_SENDING_CONDITION_ID)
              end
             ) PAC_SENDING_CONDITION_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then null
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_REPRESENTATIVE_ID
                else CUS.PAC_REPRESENTATIVE_ID
              end) PAC_REPRESENTATIVE_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.ACS_FIN_ACC_S_PAYMENT_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.ACS_FIN_ACC_S_PAYMENT_ID
                else nvl(CUS.ACS_FIN_ACC_S_PAYMENT_ID, SUP.ACS_FIN_ACC_S_PAYMENT_ID)
              end
             ) ACS_FIN_ACC_S_PAYMENT_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.DIC_TYPE_SUBMISSION_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.DIC_TYPE_SUBMISSION_ID
                else nvl(CUS.DIC_TYPE_SUBMISSION_ID, SUP.DIC_TYPE_SUBMISSION_ID)
              end
             ) DIC_TYPE_SUBMISSION_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.C_INCOTERMS
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.C_INCOTERMS
                else nvl(CUS.C_INCOTERMS, SUP.C_INCOTERMS)
              end
             ) C_INCOTERMS
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.CRE_INCOTERMS_PLACE
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.CUS_INCOTERMS_PLACE
                else nvl(CUS.CUS_INCOTERMS_PLACE, SUP.CRE_INCOTERMS_PLACE)
              end
             ) INCOTERMS_PLACE
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.ACS_VAT_DET_ACCOUNT_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.ACS_VAT_DET_ACCOUNT_ID
                else nvl(CUS.ACS_VAT_DET_ACCOUNT_ID, SUP.ACS_VAT_DET_ACCOUNT_ID)
              end
             ) ACS_VAT_DET_ACCOUNT_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then null
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.C_BVR_GENERATION_METHOD
                else CUS.C_BVR_GENERATION_METHOD
              end
             ) C_BVR_GENERATION_METHOD
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then null
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_DISTRIBUTION_CHANNEL_ID
                else CUS.PAC_DISTRIBUTION_CHANNEL_ID
              end
             ) PAC_DISTRIBUTION_CHANNEL_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then null
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_SALE_TERRITORY_ID
                else CUS.PAC_SALE_TERRITORY_ID
              end) PAC_SALE_TERRITORY_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.C_DELIVERY_TYP
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.C_DELIVERY_TYP
                else nvl(CUS.C_DELIVERY_TYP, SUP.C_DELIVERY_TYP)
              end
             ) C_DELIVERY_TYP
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.C_THIRD_MATERIAL_RELATION_TYPE
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.C_THIRD_MATERIAL_RELATION_TYPE
                else nvl(CUS.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
              end
             ) C_THIRD_MATERIAL_RELATION_TYPE
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.C_PARTNER_STATUS
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.C_PARTNER_STATUS
                else nvl(CUS.C_PARTNER_STATUS, SUP.C_PARTNER_STATUS)
              end
             ) C_PARTNER_STATUS
        from DOC_GAUGE GAU
           , PAC_THIRD THI
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
           , ACS_VAT_DET_ACCOUNT VAT_CUS
           , ACS_VAT_DET_ACCOUNT VAT_SUP
       where GAU.DOC_GAUGE_ID = cGaugeID
         and THI.PAC_THIRD_ID = cThirdID
         and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
         and CUS.C_PARTNER_STATUS(+) = '1'
         and CUS.ACS_VAT_DET_ACCOUNT_ID = VAT_CUS.ACS_VAT_DET_ACCOUNT_ID(+)
         and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
         and SUP.C_PARTNER_STATUS(+) = '1'
         and SUP.ACS_VAT_DET_ACCOUNT_ID = VAT_SUP.ACS_VAT_DET_ACCOUNT_ID(+);

    tplPartnerInfo         crPartnerInfo%rowtype;
    -- Config sur le tranfert des textes et des cours des monnaies
    cfgTransfertCurRate    varchar2(1);
    cfgTransfertTextHead   varchar2(1);
    cfgTransfertTextFoot   varchar2(9);
    cfgTransfertTextFoot_1 varchar2(1);
    cfgTransfertTextFoot_2 varchar2(1);
    cfgTransfertTextFoot_3 varchar2(1);
    cfgTransfertTextFoot_4 varchar2(1);
    cfgTransfertTextFoot_5 varchar2(1);
    -- Variables en rapport avec le tiers
    vPAC_THIRD_ID          DOC_DOCUMENT.PAC_THIRD_ID%type;
    vPAC_THIRD_ACI_ID      DOC_DOCUMENT.PAC_THIRD_ACI_ID%type;
    vPAC_THIRD_TARIFF_ID   DOC_DOCUMENT.PAC_THIRD_TARIFF_ID%type;
    -- Flag du flux copie/décharge indiquant le transfert du cours
    lnFlowTransfertRate    number;
    -- variables pour la recherche des cours
    BaseChange             number;
    RateExchangeEUR_ME     number;
    FixedRateEUR_ME        number;
    RateExchangeEUR_MB     number;
    FixedRateEUR_MB        number;
    NumTmp                 number;
    VATBaseChange          number;
    VATRateExchangeEUR_ME  number;
    VATFixedRateEUR_ME     number;
    VATRateExchangeEUR_MB  number;
    VATFixedRateEUR_MB     number;
    -- pour la recherche du n° de document
    GaugeNumberingID       DOC_GAUGE.DOC_GAUGE_NUMBERING_ID%type;
    -- Récupération des infos de pré-saisie
    vPE_ThirdID            PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    vPE_DocNumber          ACT_DOCUMENT.DOC_NUMBER%type;
    vPE_DocDate            ACT_DOCUMENT.DOC_DOCUMENT_DATE%type;
    vPE_CurrencyID         ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    vPE_ExchRate           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    vPE_BasePrice          ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    vPE_ValueDate          ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
    vPE_TransactionDate    ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
    vPE_PartnerNumber      ACT_PART_IMPUTATION.PAR_DOCUMENT%type;
    vPE_PayConditionID     ACT_PART_IMPUTATION.PAC_PAYMENT_CONDITION_ID%type;
    vPE_FinRefID           ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID%type;
    vPE_BlockedDoc         ACT_PART_IMPUTATION.PAR_BLOCKED_DOCUMENT%type;
    vPE_DicBlockedReason   ACT_PART_IMPUTATION.DIC_BLOCKED_REASON_ID%type;
    vPE_RefBVR             ACT_EXPIRY.EXP_REF_BVR%type;
    -- défini si on lie le document au dossier
    vLinkRecord            number(1);
    vRecordId              DOC_RECORD.DOC_RECORD_ID%type;
    vRecordCategoryId      DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type;
  begin
    -- Informations liées au document source
    open crInfoDocSource(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_SRC_ID);

    fetch crInfoDocSource
     into tplInfoDocSource;

    if crInfoDocSource%found then
      -- Si en décharge et que l'utilisateur passe des tiers en param,
      -- bloquer la création du document si pas mêmes tiers
      if (substr(DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOC_CREATE_MODE, 1, 1) = '3') then
        -- Vérifier s'il y a un changement de tiers
        if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID = 1)
           and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID <> tplInfoDocSource.PAC_THIRD_ID) then
          -- Arrêter l'execution de cette procédure
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  :=
                                                      PCS.PC_FUNCTIONS.TranslateWord('Le tiers du document source est different de celui passé en paramètre !');
          return;
        end if;

        -- Vérifier s'il y a un changement de tiers
        if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID = 1)
           and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID <> tplInfoDocSource.PAC_THIRD_ACI_ID) then
          -- Arrêter l'execution de cette procédure
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  :=
                                  PCS.PC_FUNCTIONS.TranslateWord('Le partenaire de facturation du document source est différent de celui passé en paramètre !');
          return;
        end if;

        -- Vérifier s'il y a un changement de tiers
        if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID = 1)
           and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID <> tplInfoDocSource.PAC_THIRD_DELIVERY_ID) then
          -- Arrêter l'execution de cette procédure
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  :=
                                    PCS.PC_FUNCTIONS.TranslateWord('Le partenaire de livraison du document source est différent de celui passé en paramètre !');
          return;
        end if;

        -- Vérifier s'il y a un changement de tiers
        if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID = 1)
           and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID <> tplInfoDocSource.PAC_THIRD_TARIFF_ID) then
          -- Arrêter l'execution de cette procédure
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  :=
                                 PCS.PC_FUNCTIONS.TranslateWord('Le partenaire de tarification du document source est différent de celui passé en paramètre !');
          return;
        end if;
      end if;

      -- Information du gabarit du document à créér
      open crGaugeInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID);

      fetch crGaugeInfo
       into tplGaugeInfo;

      close crGaugeInfo;

      -- Recherche les configs sur les transfert des textes et cours des monnaies
      cfgTransfertCurRate                                                  := nvl(PCS.PC_CONFIG.GETCONFIG('DOC_CURRENCY_RATE_TRANSFERT'), '0');
      cfgTransfertTextHead                                                 := nvl(PCS.PC_CONFIG.GETCONFIG('DOC_TRANSFERT_TEXT_HEAD'), '0');
      cfgTransfertTextFoot                                                 := nvl(PCS.PC_CONFIG.GETCONFIG('DOC_TRANSFERT_TEXT_FOOT'), '0,0,0,0,0');
      cfgTransfertTextFoot_1                                               := substr(cfgTransfertTextFoot, 1, 1);
      cfgTransfertTextFoot_2                                               := substr(cfgTransfertTextFoot, 3, 1);
      cfgTransfertTextFoot_3                                               := substr(cfgTransfertTextFoot, 5, 1);
      cfgTransfertTextFoot_4                                               := substr(cfgTransfertTextFoot, 7, 1);
      cfgTransfertTextFoot_5                                               := substr(cfgTransfertTextFoot, 9, 1);

      -- Vérifie si le n° de document a été passé en paramétre ou bien si l'on doit le générer
      -- Le numéro est généré ici, car on a besoin de lui pour l'eventuelle création du dossier
      if nvl(rtrim(ltrim(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER) ), '-1') = '-1' then
        DOC_DOCUMENT_FUNCTIONS.GetDocumentNumber(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                               , GaugeNumberingID
                                               , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER
                                                );
      end if;

      -- Si pré-saisie pas autorisée dans le gabarit, effacer l'ID de pré-saisie
      if tplGaugeInfo.C_DOC_PRE_ENTRY = '0' then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PRE_ENTRY    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PRE_ENTRY    := 0;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID  := null;
      else
        -- Si document de pré-saisie est obligatoire, vérifier qu'il soit renseigné
        if     (to_number(tplGaugeInfo.C_DOC_PRE_ENTRY) in(3, 4) )
           and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID is null) then
          -- Arrêter l'execution de cette procédure
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Le document comptable est manquant !');
          return;
        end if;

        -- ID de pré-saisie passé
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PRE_ENTRY          := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PRE_ENTRY          := 1;
          -- Rechercher les infos concernant le document de pré-saisie
          -- Faire le contrôle Tiers Finance = Tiers logistique selon le gabarit
          -- Contrôler si la monnaie de la pré-saisie est active pour le tiers du document logistique
          DOC_DOCUMENT_FUNCTIONS.ControlAndInitPreEntry
                                                 (aActDocumentID         => DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID
                                                , aDocThirdID            => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                , aAciThirdID            => nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID
                                                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                                               )
                                                , aGaugeID               => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                , aAciCompany            => ACI_LOGISTIC_DOCUMENT.getFinancialCompany
                                                                                                             (DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                                                                            , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                                                                             )
                                                , aPE_ThirdID            => vPE_ThirdID
                                                , aPE_DocNumber          => vPE_DocNumber
                                                , aPE_DocDate            => vPE_DocDate
                                                , aPE_CurrencyID         => vPE_CurrencyID
                                                , aPE_ExchRate           => vPE_ExchRate
                                                , aPE_BasePrice          => vPE_BasePrice
                                                , aPE_ValueDate          => vPE_ValueDate
                                                , aPE_TransactionDate    => vPE_TransactionDate
                                                , aPE_PartnerNumber      => vPE_PartnerNumber
                                                , aPE_PayConditionID     => vPE_PayConditionID
                                                , aPE_FinRefID           => vPE_FinRefID
                                                , aPE_BlockedDoc         => vPE_BlockedDoc
                                                , aPE_DicBlockedReason   => vPE_DicBlockedReason
                                                , aPE_RefBVR             => vPE_RefBVR
                                                 );
          -- La date de la pré-saisie est déjà initialisée à l'interface lors de la sélection de la pré-saisie
          -- et celle-ci a passé les controles de validité périodes/exercices et il ne faut donc pas l'écraser
          vPE_TransactionDate                                         := null;

          -- si le tiers de pré-saisie est différent du tiers de facturation du doc source
          -- et Contrôle tiers -> C_DOC_PRE_ENTRY_THIRD = 1 : Tiers logistique = Tiers finance
          if     (nvl(vPE_ThirdID, -1) <> nvl(tplInfoDocSource.PAC_THIRD_ACI_ID, 0) )
             and (tplGaugeInfo.C_DOC_PRE_ENTRY_THIRD = '1') then
            -- Arrêter l'execution de cette procédure
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  :=
                      PCS.PC_FUNCTIONS.TranslateWord('Le partenaire du document comptable ne correspond pas au partenaire de facturation du document source !');
            return;
          end if;

          -- Utiliser le tiers de la pré-saisie en priorité
          if (vPE_ThirdID is not null) then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID  := 1;

            -- Contrôle tiers -> C_DOC_PRE_ENTRY_THIRD
            -- 1 : Tiers logistique = Tiers finance
            -- 2 : Tiers logistique <> Tiers finance (peut-etre diff., ce n'est pas obligatoire)
            if tplGaugeInfo.C_DOC_PRE_ENTRY_THIRD = '1' then
              -- Forcer l'utilisation du tiers du document comptable
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID  := vPE_ThirdID;
            else
              -- Si tiers pas init. alors utilisation tiers doc. comptable
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID  := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID, vPE_ThirdID);
            end if;
          end if;

          -- Utilisation de la monnaie de Pré-saisie
          if     (vPE_CurrencyID is not null)
             and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID = vPE_ThirdID) then
            -- Utiliser en priorité la Monnaie de la pré-saisie
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := vPE_CurrencyID;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_OF_EXCHANGE       := vPE_ExchRate;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_BASE_PRICE             := vPE_BasePrice;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_EURO              := 0;
          end if;

          -- Date document avec la date de la transaction de la pré-saisie
          if vPE_TransactionDate is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT  := vPE_TransactionDate;
          end if;

          -- Initialisation de la date valeur avec la date valeur de la pré-saisie si celle-ci est renseignée
          if vPE_ValueDate is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE  := 1;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE      := vPE_ValueDate;
          end if;

          -- N° du document partenaire de la pré-saisie
          if vPE_PartnerNumber is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_NUMBER  := 1;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_NUMBER      := vPE_PartnerNumber;
          end if;

          -- Date document partenaire
          if vPE_DocDate is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT  := 1;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_PARTNER_DOCUMENT      := vPE_DocDate;
          end if;

          -- Condition de payement de la pré-saisie
          if vPE_PayConditionID is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID      := vPE_PayConditionID;
          end if;

          -- Réf. financière de la pré-saisie
          if vPE_FinRefID is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_FINANCIAL_REFERENCE_ID  := 1;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_FINANCIAL_REFERENCE_ID      := vPE_FinRefID;
          end if;

          -- Blocage du document finance
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FIN_DOC_BLOCKED    := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FIN_DOC_BLOCKED    := vPE_BlockedDoc;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_BLOCKED_REASON_ID  := vPE_DicBlockedReason;

          -- Méthode de génération du BVR
          if vPE_RefBVR is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_REF_BVR_NUMBER  := 1;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_REF_BVR_NUMBER      := vPE_RefBVR;
          end if;
        else
          -- Pas de document de pré-saisie initialisé
          vPE_ThirdID           := null;
          vPE_DocDate           := null;
          vPE_CurrencyID        := null;
          vPE_ExchRate          := null;
          vPE_BasePrice         := null;
          vPE_ValueDate         := null;
          vPE_TransactionDate   := null;
          vPE_PartnerNumber     := null;
          vPE_PayConditionID    := null;
          vPE_FinRefID          := null;
          vPE_BlockedDoc        := null;
          vPE_DicBlockedReason  := null;
          vPE_RefBVR            := null;
        end if;
      end if;

      -- Reprise du tiers du document source si réf partenaire sur le doc à créér
      if tplGaugeInfo.GAU_REF_PARTNER = 1 then
        -- Partenaire donneur d'ordre
        if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID is null)
           or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID = 0) then
          -- Utiliser les tiers du document source
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID  := tplInfoDocSource.PAC_THIRD_ID;
        end if;

        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID           := 1;
        vPAC_THIRD_ID                                                   := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID;

        -- Tiers pas défini mais gabarit exige réf. partenaire
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID is null then
          -- Arrêter l'execution de cette procédure
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de document - Le tiers est manquant !');
          return;
        end if;

        -- Recherche des partenaires liés au partenaire donneur d'ordre
        select (case
                  when tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_PAC_THIRD_1_ID
                  when tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_PAC_THIRD_1_ID
                  else nvl(CUS.PAC_PAC_THIRD_1_ID, SUP.PAC_PAC_THIRD_1_ID)
                end
               ) PAC_THIRD_ACI_ID
             , (case
                  when tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_PAC_THIRD_2_ID
                  when tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_PAC_THIRD_2_ID
                  else nvl(CUS.PAC_PAC_THIRD_2_ID, SUP.PAC_PAC_THIRD_2_ID)
                end
               ) PAC_THIRD_TARIFF_ID
          into vPAC_THIRD_ACI_ID
             , vPAC_THIRD_TARIFF_ID
          from PAC_THIRD THI
             , PAC_CUSTOM_PARTNER CUS
             , PAC_SUPPLIER_PARTNER SUP
         where THI.PAC_THIRD_ID = vPAC_THIRD_ID
           and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
           and CUS.C_PARTNER_STATUS(+) = '1'
           and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
           and SUP.C_PARTNER_STATUS(+) = '1';

        -- Partenaire facturation
        if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID is null)
           or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID = 0) then
          -- Utiliser les tiers du document source
          if tplInfoDocSource.PAC_THIRD_ACI_ID is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID  := tplInfoDocSource.PAC_THIRD_ACI_ID;
          else
            -- Initialisation du partenaire facturation
            -- 1.Partenaire facturation du gabarit
            -- 2.Partenaire facturation du partenaire donneur d’ordre
            -- 3.Partenaire donneur d’ordre
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID  := nvl(tplGaugeInfo.PAC_THIRD_ACI_ID, nvl(vPAC_THIRD_ACI_ID, vPAC_THIRD_ID) );
          end if;
        end if;

        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID       := 1;

        -- Partenaire tarification
        if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID is null)
           or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID = 0) then
          -- Utiliser les tiers du document source
          if tplInfoDocSource.PAC_THIRD_TARIFF_ID is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID  := tplInfoDocSource.PAC_THIRD_TARIFF_ID;
          else
            -- Initialisation du partenaire tarification
            -- 1.Partenaire tarification du partenaire donneur d’ordre
            -- 2.Partenaire donneur d’ordre
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID  := nvl(vPAC_THIRD_TARIFF_ID, vPAC_THIRD_ID);
          end if;
        end if;

        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID    := 1;

        -- Partenaire livraison
        if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is null)
           or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID = 0) then
          -- Initialisation du partenaire livraison
          -- 1.Partenaire livraison du doc source
          -- 2.Partenaire livraison du gabarit
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID  := nvl(tplInfoDocSource.PAC_THIRD_DELIVERY_ID, tplGaugeInfo.PAC_THIRD_DELIVERY_ID);

          --3.Si domaine « Vente » ou « SAV » => Partenaire donneur d’ordre
          --   Sinon  Partenaire livraison = vide
          if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is null)
             and (tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') ) then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID  := vPAC_THIRD_ID;
          end if;
        end if;

        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID  := 1;
      else
        -- Gabarit sans réf. partenaire
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID  := null;
      end if;

      -- Recherche les informations du partenaire
      open crPartnerInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID);

      fetch crPartnerInfo
       into tplPartnerInfo;

      close crPartnerInfo;

      if     DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID is not null
         and (nvl(tplPartnerInfo.C_PARTNER_STATUS, '0') <> '1') then   -- Le tiers n'est pas actif finance et logistique
        -- Arrêter l'execution de cette procédure
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de document - Le tiers n''est pas actif !');
        return;
      end if;

      -- Reprise du code langue du document source
      if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID = 0) then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID      := tplInfoDocSource.PC_LANG_ID;
      end if;

      -- Reprise du code langue facturation du document source
      if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ACI_ID = 0) then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ACI_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ACI_ID      := tplInfoDocSource.PC_LANG_ACI_ID;
      end if;

      -- Reprise du code langue livraison du document source
      if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_DELIVERY_ID = 0) then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_DELIVERY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_DELIVERY_ID      := tplInfoDocSource.PC_LANG_DELIVERY_ID;
      end if;

      -- Date du document, cascade de l'initialisation
      -- 1. Date de transaction de la pré-saisie (initialisé plus haut), 2. Date document passée en param, 3. Date du jour
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT is null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT  := trunc(sysdate);
      end if;

      -- Gabarit gère le dossier
      if tplGaugeInfo.GAU_DOSSIER = 1 then
        -- Initialisation du dossier si USE_DOC_RECORD_ID = 0
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID = 0 then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;

          select DOC_RECORD_CATEGORY_ID
            into vRecordCategoryId
            from DOC_GAUGE
           where DOC_GAUGE_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID;

          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID    := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID, getNewId);
          -- Création du dossier
          vRecordId                                               :=
            Doc_Record_Management.CreateRecord(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                             , ''
                                             , tplInfoDocSource.DOC_RECORD_ID
                                             , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                             , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID
                                             , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER
                                             , vLinkRecord
                                             , vRecordCategoryId
                                              );

          if     vLinkRecord = 1
             and vRecordId <> -1
             and tplInfoDocSource.DOC_RECORD_ID is null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID  := vRecordId;
          else
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID  := tplInfoDocSource.DOC_RECORD_ID;
          end if;
        end if;
      else
        -- Dossier pas géré dans le gabarit
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID      := null;
      end if;

      -- Recherche de la monnaie du document si USE_DOC_CURRENCY = 0
      -- Et même partenaire facturation doc source et doc cible
      if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY = 0)
         and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID = tplInfoDocSource.PAC_THIRD_ACI_ID) then
        -- Monnaie du document source
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := tplInfoDocSource.ACS_FINANCIAL_CURRENCY_ID;
        lnFlowTransfertRate                                             := 0;

        -- Config indiquant le Transfert du cours du document en copie/décharge
        -- Valeur 2 : Selon champ "Transfert cours" du flux
        if cfgTransfertCurRate = '2' then
          declare
            lnFlowID    DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type         default null;
            lnCopyID    DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type         default null;
            lnReceiptID DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type   default null;
          begin
            -- Dupliquer document
            if DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOC_CREATE_MODE = '205' then
              -- Pas de lecture du Transfert cours au niveau du flux
              -- Forcer transfert à OUI
              lnFlowTransfertRate  := 1;
            else
              -- Rechercher le flux de document défini sur le document source
              select max(PDE.DOC_GAUGE_FLOW_ID)
                into lnFlowID
                from DOC_DOCUMENT DMT
                   , DOC_POSITION POS
                   , DOC_POSITION_DETAIL PDE
               where DMT.DOC_DOCUMENT_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_SRC_ID
                 and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                 and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID;

              -- Le document source n'a pas de flux de défini ou erreur lors de la recherche précèdente
              --
              -- Recherche de l'id du flux de copie
              if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.CREATE_TYPE = 'COPY') then
                lnCopyID             :=
                  DOC_LIB_GAUGE.GetGaugeCopyID(iSourceGaugeId   => tplInfoDocSource.DOC_GAUGE_ID
                                             , iTargetGaugeId   => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                             , iThirdID         => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                             , iFlowID          => lnFlowID
                                              );
                -- Lecture du champ en question selon flux de copie
                lnFlowTransfertRate  := DOC_LIB_GAUGE.GetGaugeCopyFlag(iCopyID => lnCopyID, iFieldName => 'GAC_TRANSFERT_CURR_RATE');
              else
                -- Recherche de l'id du flux de décharge
                lnReceiptID          :=
                  DOC_LIB_GAUGE.GetGaugeReceiptID(iSourceGaugeId   => tplInfoDocSource.DOC_GAUGE_ID
                                                , iTargetGaugeId   => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                , iThirdID         => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                , iFlowID          => lnFlowID
                                                 );
                -- Lecture du champ en question selon flux de décharge
                lnFlowTransfertRate  := DOC_LIB_GAUGE.GetGaugeReceiptFlag(iReceiptID => lnReceiptID, iFieldName => 'GAR_TRANSFERT_CURR_RATE');
              end if;
            end if;
          end;
        end if;

        -- Transfert du cours de monnaie du document source sur le document cible = OUI
        if    (cfgTransfertCurRate = '1')
           or (     (cfgTransfertCurRate = '2')
               and (lnFlowTransfertRate = 1) ) then
          -- Utiliser le cours de la pré-saisie si renseigné
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_OF_EXCHANGE  := tplInfoDocSource.DMT_RATE_OF_EXCHANGE;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_BASE_PRICE        := tplInfoDocSource.DMT_BASE_PRICE;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_EURO         := tplInfoDocSource.DMT_RATE_EURO;
        end if;
      end if;

      -- Document avec TVA
      if tplGaugeInfo.GAS_VAT = 1 then
        -- Si même domaine, même tiers et que le décompte TVA est défini sur le doc source copier toutes les données
        if     (tplGaugeInfo.C_ADMIN_DOMAIN = tplInfoDocSource.C_ADMIN_DOMAIN)
           and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID = tplInfoDocSource.PAC_THIRD_ID)
           and (tplInfoDocSource.ACS_VAT_DET_ACCOUNT_ID is not null) then
          -- Utilisation du décompte TVA du document source
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_VAT_DET_ACCOUNT_ID     := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID         := tplInfoDocSource.ACS_VAT_DET_ACCOUNT_ID;
          -- Utilisation du type de soumission du document source ou si null, utiliser celui du tiers
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_SUBMISSION_ID     := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID         :=
                                                                            nvl(tplInfoDocSource.DIC_TYPE_SUBMISSION_ID, tplPartnerInfo.DIC_TYPE_SUBMISSION_ID);
          -- Utilisation de la monnaie TVA du document source
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_VAT_CURRENCY               := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID  := tplInfoDocSource.ACS_ACS_FINANCIAL_CURRENCY_ID;

          -- Transfert du cours de monnaie TVA du doc source sur le document cible = OUI
          if cfgTransfertCurRate = '1' then
            -- Utilisation de la monnaie TVA et ses cours du document source
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE  := tplInfoDocSource.DMT_VAT_EXCHANGE_RATE;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE     := tplInfoDocSource.DMT_VAT_BASE_PRICE;
          end if;
        end if;
      else   -- Document sans TVA
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_SUBMISSION_ID     := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID         := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_VAT_DET_ACCOUNT_ID     := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID         := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_VAT_CURRENCY               := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID  := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE          := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE             := null;
      end if;

      -- Gabarit gére la Référence financière
      if tplGaugeInfo.GAS_FINANCIAL_REF = 1 then
        if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_FINANCIAL_REFERENCE_ID = 0)
           and (tplInfoDocSource.PAC_FINANCIAL_REFERENCE_ID is not null) then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_FINANCIAL_REFERENCE_ID  := 1;
          -- Cascade d'initialisation pour la réf. financière
          -- 1. Document de pré-saisie(déjà initialisé plus haut), 2. Document source, 3. Tiers
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_FINANCIAL_REFERENCE_ID      := tplInfoDocSource.PAC_FINANCIAL_REFERENCE_ID;
        end if;
      else
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_FINANCIAL_REFERENCE_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_FINANCIAL_REFERENCE_ID      := null;
      end if;

      -- Comptes (il n'y a que le compte Finance et la division qui se copient
      -- Si le compte Finance et Division ne sont pas renseignés sur le doc source
      -- ceux-ci seront recherches lors de la méthode InitDocumentData
      if    tplInfoDocSource.ACS_FINANCIAL_ACCOUNT_ID is not null
         or tplInfoDocSource.ACS_DIVISION_ACCOUNT_ID is not null then
        -- Reprise du Compte Finance et Division du document source
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_ACCOUNT_ID  := tplInfoDocSource.ACS_FINANCIAL_ACCOUNT_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_DIVISION_ACCOUNT_ID   := tplInfoDocSource.ACS_DIVISION_ACCOUNT_ID;
        -- Recherche du reste des comptes
        DOC_DOCUMENT_FUNCTIONS.GetFinancialInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_DIVISION_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CPN_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CDA_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PF_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PJ_ACCOUNT_ID
                                               );
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACCOUNTS              := 1;
      -- Le contrôle de l'interaction entre comptes se fait dans la méthode
      -- InitDocumentData qui sera executée juste avant l'insertion du document
      end if;

      -- Copier l'adresse principale si au moins un des champs de l'adresse principale du doc source est renseignée
      if    tplInfoDocSource.PAC_ADDRESS_ID is not null
         or tplInfoDocSource.PC_CNTRY_ID is not null
         or tplInfoDocSource.DMT_ADDRESS1 is not null
         or tplInfoDocSource.DMT_POSTCODE1 is not null
         or tplInfoDocSource.DMT_TOWN1 is not null
         or tplInfoDocSource.DMT_STATE1 is not null
         or tplInfoDocSource.DMT_NAME1 is not null
         or tplInfoDocSource.DMT_FORENAME1 is not null
         or tplInfoDocSource.DMT_ACTIVITY1 is not null
         or tplInfoDocSource.DMT_CARE_OF1 is not null
         or tplInfoDocSource.DMT_PO_BOX1 is not null
         or tplInfoDocSource.DMT_PO_BOX_NBR1 is not null
         or tplInfoDocSource.DMT_COUNTY1 is not null
         or tplInfoDocSource.DMT_CONTACT1 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_1    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID   := tplInfoDocSource.PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID      := tplInfoDocSource.PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1     := tplInfoDocSource.DMT_ADDRESS1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1    := tplInfoDocSource.DMT_POSTCODE1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1        := tplInfoDocSource.DMT_TOWN1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1       := tplInfoDocSource.DMT_STATE1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1        := tplInfoDocSource.DMT_NAME1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1    := tplInfoDocSource.DMT_FORENAME1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1    := tplInfoDocSource.DMT_ACTIVITY1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1     := tplInfoDocSource.DMT_CARE_OF1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1      := tplInfoDocSource.DMT_PO_BOX1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1  := tplInfoDocSource.DMT_PO_BOX_NBR1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1      := tplInfoDocSource.DMT_COUNTY1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1     := tplInfoDocSource.DMT_CONTACT1;
      end if;

      -- Copier la 2ème adresse si au moins un des champs de la 2ème adresse du doc source est renseignée
      if    tplInfoDocSource.PAC_PAC_ADDRESS_ID is not null
         or tplInfoDocSource.PC__PC_CNTRY_ID is not null
         or tplInfoDocSource.DMT_ADDRESS2 is not null
         or tplInfoDocSource.DMT_POSTCODE2 is not null
         or tplInfoDocSource.DMT_TOWN2 is not null
         or tplInfoDocSource.DMT_STATE2 is not null
         or tplInfoDocSource.DMT_NAME2 is not null
         or tplInfoDocSource.DMT_FORENAME2 is not null
         or tplInfoDocSource.DMT_ACTIVITY2 is not null
         or tplInfoDocSource.DMT_CARE_OF2 is not null
         or tplInfoDocSource.DMT_PO_BOX2 is not null
         or tplInfoDocSource.DMT_PO_BOX_NBR2 is not null
         or tplInfoDocSource.DMT_COUNTY2 is not null
         or tplInfoDocSource.DMT_CONTACT2 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_2       := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAC_ADDRESS_ID  := tplInfoDocSource.PAC_PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_CNTRY_ID     := tplInfoDocSource.PC__PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS2        := tplInfoDocSource.DMT_ADDRESS2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE2       := tplInfoDocSource.DMT_POSTCODE2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN2           := tplInfoDocSource.DMT_TOWN2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE2          := tplInfoDocSource.DMT_STATE2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME2           := tplInfoDocSource.DMT_NAME2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME2       := tplInfoDocSource.DMT_FORENAME2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY2       := tplInfoDocSource.DMT_ACTIVITY2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF2        := tplInfoDocSource.DMT_CARE_OF2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX2         := tplInfoDocSource.DMT_PO_BOX2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR2     := tplInfoDocSource.DMT_PO_BOX_NBR2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY2         := tplInfoDocSource.DMT_COUNTY2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT2        := tplInfoDocSource.DMT_CONTACT2;
      end if;

      -- Copier la 3ème adresse si au moins un des champs de la 3ème adresse du doc source est renseignée
      if    tplInfoDocSource.PAC2_PAC_ADDRESS_ID is not null
         or tplInfoDocSource.PC_2_PC_CNTRY_ID is not null
         or tplInfoDocSource.DMT_ADDRESS3 is not null
         or tplInfoDocSource.DMT_POSTCODE3 is not null
         or tplInfoDocSource.DMT_TOWN3 is not null
         or tplInfoDocSource.DMT_STATE3 is not null
         or tplInfoDocSource.DMT_NAME3 is not null
         or tplInfoDocSource.DMT_FORENAME3 is not null
         or tplInfoDocSource.DMT_ACTIVITY3 is not null
         or tplInfoDocSource.DMT_CARE_OF3 is not null
         or tplInfoDocSource.DMT_PO_BOX3 is not null
         or tplInfoDocSource.DMT_PO_BOX_NBR3 is not null
         or tplInfoDocSource.DMT_COUNTY3 is not null
         or tplInfoDocSource.DMT_CONTACT3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_3        := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC2_PAC_ADDRESS_ID  := tplInfoDocSource.PAC2_PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_CNTRY_ID     := tplInfoDocSource.PC_2_PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS3         := tplInfoDocSource.DMT_ADDRESS3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE3        := tplInfoDocSource.DMT_POSTCODE3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN3            := tplInfoDocSource.DMT_TOWN3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE3           := tplInfoDocSource.DMT_STATE3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME3            := tplInfoDocSource.DMT_NAME3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME3        := tplInfoDocSource.DMT_FORENAME3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY3        := tplInfoDocSource.DMT_ACTIVITY3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF3         := tplInfoDocSource.DMT_CARE_OF3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX3          := tplInfoDocSource.DMT_PO_BOX3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR3      := tplInfoDocSource.DMT_PO_BOX_NBR3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY3          := tplInfoDocSource.DMT_COUNTY3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT3         := tplInfoDocSource.DMT_CONTACT3;
      end if;

      -- Copier le Texte d'en-tête de document depuis document source si la config
      -- DOC_TRANSFERT_TEXT_HEAD = 1
      if cfgTransfertTextHead = '1' then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_HEADING_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_APPLTXT_ID         := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_HEADING_TEXT      := tplInfoDocSource.DMT_HEADING_TEXT;
      else
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_HEADING_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_APPLTXT_ID         := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_HEADING_TEXT      :=
                                             PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(tplGaugeInfo.PC_APPLTXT_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID);
      end if;

      -- Initialiser le Texte de titre
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TITLE_TEXT              := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_APPLTXT_ID               := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TITLE_TEXT                  :=
                                          PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(tplGaugeInfo.PC__PC_APPLTXT_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID);
      -- Copier le Texte de document du document source
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DOCUMENT_TEXT           := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_APPLTXT_ID              := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DOCUMENT_TEXT               := tplInfoDocSource.DMT_DOCUMENT_TEXT;

      -- Copier le représentant si celui-ci figure sur le doc source
      if tplInfoDocSource.PAC_REPRESENTATIVE_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID      := tplInfoDocSource.PAC_REPRESENTATIVE_ID;
      end if;

      -- Copier le représentant livraison si celui-ci figure sur le doc source
      if tplInfoDocSource.PAC_REPR_DELIVERY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_DELIVERY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_DELIVERY_ID      := tplInfoDocSource.PAC_REPR_DELIVERY_ID;
      end if;

      -- Copier le représentant livraison si celui-ci figure sur le doc source
      if tplInfoDocSource.PAC_REPR_ACI_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_ACI_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_ACI_ID      := tplInfoDocSource.PAC_REPR_ACI_ID;
      end if;

      -- Copier le Code tarif du doc source
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TARIFF_ID               := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TARIFF_ID                   := tplInfoDocSource.DIC_TARIFF_ID;

      -- Si le gabarit n'a pas de condition de paiement mais que le doc source en a
      -- on copie la condition de paiement du doc source
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;

        -- ne pas reprendre les conditions de paiement du document source si celle-ci sont de type échéancier
        -- et qu'on ne gère pas l'échéancier sur le gabarit cible
        if     tplGaugeInfo.GAS_INVOICE_EXPIRY = 0
           and PAC_FUNCTIONS.getPayCondKind(tplInfoDocSource.PAC_PAYMENT_CONDITION_ID) = '02' then
          -- Condition de payement, cascade d'initialisation
          -- 1. Document pré-saisie(déjà initialisé plus haut), 2. Gabarit, 3. Tiers
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID  := nvl(tplGaugeInfo.PAC_PAYMENT_CONDITION_ID, tplPartnerInfo.PAC_PAYMENT_CONDITION_ID);
        else
          -- Condition de payement, cascade d'initialisation
          -- 1. Document pré-saisie(déjà initialisé plus haut), 2. Gabarit, 3. Document source, 4. Tiers
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID  :=
                           nvl(tplGaugeInfo.PAC_PAYMENT_CONDITION_ID, nvl(tplInfoDocSource.PAC_PAYMENT_CONDITION_ID, tplPartnerInfo.PAC_PAYMENT_CONDITION_ID) );
        end if;
      end if;

      -- Copier le Mode d'expédition du doc source, si celui-ci est renseigné
      if tplInfoDocSource.PAC_SENDING_CONDITION_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SENDING_CONDITION_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SENDING_CONDITION_ID      := tplInfoDocSource.PAC_SENDING_CONDITION_ID;
      end if;

      -- Copier les incoterms, si une donnée des incoterms est renseignée sur le doc source
      if    tplInfoDocSource.C_INCOTERMS is not null
         or tplInfoDocSource.DMT_INCOTERMS_PLACE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_INCOTERMS        := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS          := tplInfoDocSource.C_INCOTERMS;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE  := tplInfoDocSource.DMT_INCOTERMS_PLACE;
      end if;

      -- Copier "Canal de distribution", si renseigné sur le doc source
      if tplInfoDocSource.PAC_DISTRIBUTION_CHANNEL_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_DIST_CHANNEL_ID      := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_DISTRIBUTION_CHANNEL_ID  := tplInfoDocSource.PAC_DISTRIBUTION_CHANNEL_ID;
      end if;

      -- Copier "Territoire de vente", si renseigné sur le doc source
      if tplInfoDocSource.PAC_SALE_TERRITORY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SALE_TERRITORY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SALE_TERRITORY_ID      := tplInfoDocSource.PAC_SALE_TERRITORY_ID;
      end if;

      -- Copier la Méthode de paiement du doc source si celle-ci est renseignée
      if tplInfoDocSource.ACS_FIN_ACC_S_PAYMENT_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_FIN_ACC_S_PAYMENT_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FIN_ACC_S_PAYMENT_ID      := tplInfoDocSource.ACS_FIN_ACC_S_PAYMENT_ID;
      end if;

      -- Copier la Date de livraison du doc source si celle-ci est renseignée
      if tplInfoDocSource.DMT_DATE_DELIVERY is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_DELIVERY  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DELIVERY      := tplInfoDocSource.DMT_DATE_DELIVERY;
      end if;

      -- Copie du Coefficient en %
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_RATE_FACTOR             := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_FACTOR                 := tplInfoDocSource.DMT_RATE_FACTOR;

      -- Copier le N° du document partenaire de la pré-saisie (déjà initialisé plus haut) ou du doc source si cellui-ci est renseigné
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_NUMBER = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_NUMBER  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_NUMBER      := tplInfoDocSource.DMT_PARTNER_NUMBER;
      end if;

      -- Copier la réf. partenaire du doc source si celle-ci est renseignée
      if tplInfoDocSource.DMT_PARTNER_REFERENCE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_REFERENCE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_REFERENCE      := tplInfoDocSource.DMT_PARTNER_REFERENCE;
      end if;

      -- Copier la Date de livraison de la pré-saisie(déjà initialisé plus haut) ou du doc source si celle-ci est renseignée
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_PARTNER_DOCUMENT      := tplInfoDocSource.DMT_DATE_PARTNER_DOCUMENT;
      end if;

      -- Copier la Référence du doc source si celle-ci est renseignée
      if tplInfoDocSource.DMT_REFERENCE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_REFERENCE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_REFERENCE      := tplInfoDocSource.DMT_REFERENCE;
      end if;

      -- Copier les données libres du document source si le gabarit gére
      -- les données libres et qu'il faut reprendre le données libres en copie de document
      if     tplGaugeInfo.GAU_FREE_DATA_USE = 1
         and tplGaugeInfo.GAU_COPY_SOURCE_FREE_DATA = 1 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_GAUGE_FREE_DATA       := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_GAUGE_FREE_CODE_1_ID  := tplInfoDocSource.DIC_GAUGE_FREE_CODE_1_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_GAUGE_FREE_CODE_2_ID  := tplInfoDocSource.DIC_GAUGE_FREE_CODE_2_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_GAUGE_FREE_CODE_3_ID  := tplInfoDocSource.DIC_GAUGE_FREE_CODE_3_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_NUMBER1      := tplInfoDocSource.DMT_GAU_FREE_NUMBER1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_NUMBER2      := tplInfoDocSource.DMT_GAU_FREE_NUMBER2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_DATE1        := tplInfoDocSource.DMT_GAU_FREE_DATE1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_DATE2        := tplInfoDocSource.DMT_GAU_FREE_DATE2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_BOOL1        := tplInfoDocSource.DMT_GAU_FREE_BOOL1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_BOOL2        := tplInfoDocSource.DMT_GAU_FREE_BOOL2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_TEXT_LONG    := tplInfoDocSource.DMT_GAU_FREE_TEXT_LONG;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_TEXT_SHORT   := tplInfoDocSource.DMT_GAU_FREE_TEXT_SHORT;
      end if;

      -- Copie des Dicos libres du document
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_POS_FREE_TABLE          := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_1_ID         := tplInfoDocSource.DIC_POS_FREE_TABLE_1_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_2_ID         := tplInfoDocSource.DIC_POS_FREE_TABLE_2_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_3_ID         := tplInfoDocSource.DIC_POS_FREE_TABLE_3_ID;
      -- Copie des Textes libres du document
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TEXT                    := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_1                      := tplInfoDocSource.DMT_TEXT_1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_2                      := tplInfoDocSource.DMT_TEXT_2;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_3                      := tplInfoDocSource.DMT_TEXT_3;
      -- Copie des Numériques libres du document
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DECIMAL                 := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_1                   := tplInfoDocSource.DMT_DECIMAL_1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_2                   := tplInfoDocSource.DMT_DECIMAL_2;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_3                   := tplInfoDocSource.DMT_DECIMAL_3;
      -- Copie des Dates libres du document
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE                    := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_1                      := tplInfoDocSource.DMT_DATE_1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_2                      := tplInfoDocSource.DMT_DATE_2;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_3                      := tplInfoDocSource.DMT_DATE_3;

      -- Champs de gestion des poids matières précieuses
      if     tplGaugeInfo.GAS_WEIGHT_MAT = 1
         and tplInfoDocSource.GAS_WEIGHT_MAT = 1 then
        -- Impossible de définir que le document est créé par décharge
        -- tant qu'aucune position n'est déchargée.
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CREATE_FOOT_MAT  := 1;   -- Matières à créer /* 2;   -- Matières créées */
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RECALC_FOOT_MAT  := 0;
      elsif     tplGaugeInfo.GAS_WEIGHT_MAT = 1
            and tplInfoDocSource.GAS_WEIGHT_MAT = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CREATE_FOOT_MAT  := 1;   -- Matières à créer
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RECALC_FOOT_MAT  := 0;
      else
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CREATE_FOOT_MAT  := 0;   -- Matières pas gérées
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RECALC_FOOT_MAT  := 0;
      end if;

      -- Reprend le type de relation avec tiers du document source si pas null. Sinon initialisation en fonction du tiers.
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_THIRD_MATERIAL_RELATION_TYPE  :=
                                                             nvl(tplInfoDocSource.C_THIRD_MATERIAL_RELATION_TYPE, tplPartnerInfo.C_THIRD_MATERIAL_RELATION_TYPE);

      -- Données concernant le pied du document

      -- Copie du texte de pied 1 si config = 1
      if cfgTransfertTextFoot_1 = '1' then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT   := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC_APPLTXT_ID  := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT       := tplInfoDocSource.FOO_FOOT_TEXT;
      end if;

      -- Copie du texte de pied 2 si config = 1
      if cfgTransfertTextFoot_2 = '1' then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT2      := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC__PC_APPLTXT_ID  := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT2          := tplInfoDocSource.FOO_FOOT_TEXT2;
      end if;

      -- Copie du texte de pied 3 si config = 1
      if cfgTransfertTextFoot_3 = '1' then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT3       := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC_2_PC_APPLTXT_ID  := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT3           := tplInfoDocSource.FOO_FOOT_TEXT3;
      end if;

      -- Copie du texte de pied 4 si config = 1
      if cfgTransfertTextFoot_4 = '1' then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT4       := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC_3_PC_APPLTXT_ID  := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT4           := tplInfoDocSource.FOO_FOOT_TEXT4;
      end if;

      -- Copie du texte de pied 5 si config = 1
      if cfgTransfertTextFoot_5 = '1' then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT5       := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC_4_PC_APPLTXT_ID  := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT5           := tplInfoDocSource.FOO_FOOT_TEXT5;
      end if;

      -- Signataire
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_GAUGE_SIGNATORY_ID      := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_SIGNATORY_ID          := tplInfoDocSource.DOC_GAUGE_SIGNATORY_ID;
      -- Signataire secondaire
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_DOC_GAUGE_SIGNATORY_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOC_GAUGE_SIGNATORY_ID      := tplInfoDocSource.DOC_DOC_GAUGE_SIGNATORY_ID;
      -- Emballage
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_PACKAGING               := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_PACKAGING                   := tplInfoDocSource.FOO_PACKAGING;
      -- Marquage
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_MARKING                 := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_MARKING                     := tplInfoDocSource.FOO_MARKING;
      -- Mesure
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_MEASURE                 := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_MEASURE                     := tplInfoDocSource.FOO_MEASURE;
      -- Blocage du document finance
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FIN_DOC_BLOCKED             := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FIN_DOC_BLOCKED             := tplInfoDocSource.DMT_FIN_DOC_BLOCKED;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_BLOCKED_REASON_ID           := tplInfoDocSource.DIC_BLOCKED_REASON_ID;
    end if;

    close crInfoDocSource;
  end InitDocument_205;

  /**
  *  procedure InitDocument_210
  *  Description
  *    Copie - Gestion des documents
  */
  procedure InitDocument_210
  is
  begin
    -- Actuellement l'initialisation lors de la copie est la même qu'en duplication
    InitDocument_205;
  end InitDocument_210;

  /**
  *  procedure InitDocument_215
  *  Description
  *    Copie - Gestion des documents avec avenant
  */
  procedure InitDocument_215
  is
  begin
    begin
      select 1
           , DMT_ADDENDUM_OF_DOC_ID
           , DMT_ADDENDUM_SRC_DOC_ID
           , nvl(DMT_ADDENDUM_INDEX, 0)
           , DMT_ADDENDUM_NUMBER
           , DMT_ADDENDUM_COMMENT
           , DMT_DATE_DOCUMENT
        into DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDENDUM
           , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_OF_DOC_ID
           , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_SRC_DOC_ID
           , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_INDEX
           , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_NUMBER
           , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_COMMENT
           , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_SRC_ID;
    exception
      when no_data_found then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDENDUM  := 0;
    end;

    -- Actuellement l'initialisation lors de la copie avec avenant est la même qu'en duplication
    InitDocument_205;
  end InitDocument_215;

  /**
  *  procedure InitDocument_218
  *  Description
  *    Copie - Gestion des litiges
  */
  procedure InitDocument_218
  is
  begin
    InitDocument_205;
  end InitDocument_218;

  /**
  *  procedure InitDocument_290
  *  Description
  *    Copie - Echéancier
  */
  procedure InitDocument_290
  is
  begin
    InitDocument_205;
  end InitDocument_290;

  /**
  *  procedure InitDocument_310
  *  Description
  *    Décharge - Gestion des documents
  */
  procedure InitDocument_310
  is
  begin
    -- Actuellement l'initialisation lors de la décharge est la même qu'en duplication
    InitDocument_205;
  end InitDocument_310;

  /**
  *  procedure InitDocument_318
  *  Description
  *    Décharge - Litiges
  */
  procedure InitDocument_318
  is
  begin
    InitDocument_205;
  end InitDocument_318;

  /**
  *  procedure InitDocument_320
  *  Description
  *    Décharge - Facturation périodique
  */
  procedure InitDocument_320
  is
  begin
    -- Actuellement l'initialisation lors de cette décharge est la même qu'en duplication
    InitDocument_205;
  end InitDocument_320;

  /**
  *  procedure InitDocument_325
  *  Description
  *    Décharge - Livraison périodique
  */
  procedure InitDocument_325
  is
  begin
    -- Actuellement l'initialisation lors de cette décharge est la même qu'en duplication
    InitDocument_205;
  end InitDocument_325;

  /**
  *  procedure InitDocument_330
  *  Description
  *    Décharge - Livraison Barcode
  */
  procedure InitDocument_330
  is
  begin
    -- Actuellement l'initialisation lors de cette décharge est la même qu'en duplication
    InitDocument_205;
  end InitDocument_330;

  /**
  *  procedure InitDocument_340
  *  Description
  *    Décharge - Générateur de documents
  */
  procedure InitDocument_340
  is
    cursor crInterfaceInfo(cInterfaceID DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select DOI.DOI_NUMBER
           , DOI.DMT_NUMBER
           , DOI.DOI_TITLE_TEXT
           , DOI.DOI_HEADING_TEXT
           , DOI.DOI_DOCUMENT_TEXT
           , DOI.PAC_THIRD_ID
           , DOI.PAC_THIRD_ACI_ID
           , DOI.PAC_THIRD_DELIVERY_ID
           , DOI.PAC_THIRD_TARIFF_ID
           , DOI.DOC_RECORD_ID
           , DOI.PAC_REPRESENTATIVE_ID
           , DOI.PAC_REPR_ACI_ID
           , DOI.PAC_REPR_DELIVERY_ID
           , DOI.PAC_SENDING_CONDITION_ID
           , DOI.PC_LANG_ID
           , DOI.PC_LANG_ACI_ID
           , DOI.PC_LANG_DELIVERY_ID
           , DOI.DOI_REFERENCE
           , DOI.DOI_PARTNER_REFERENCE
           , DOI.DOI_PARTNER_NUMBER
           , DOI.DOI_PARTNER_DATE
           , DOI.DOI_DOCUMENT_DATE
           , DOI.DOI_VALUE_DATE
           , DOI.DOI_DELIVERY_DATE
           , DOI.DIC_TARIFF_ID
           , DOI.ACS_VAT_DET_ACCOUNT_ID
           , DOI.ACS_FIN_ACC_S_PAYMENT_ID
           , DOI.PAC_ADDRESS_ID
           , DOI.DOI_ADDRESS1
           , DOI.PC_CNTRY_ID
           , DOI.DOI_ZIPCODE1
           , DOI.DOI_TOWN1
           , DOI.DOI_STATE1
           , DOI.DOI_NAME1
           , DOI.DOI_FORENAME1
           , DOI.DOI_ACTIVITY1
           , DOI.DOI_CARE_OF1
           , DOI.DOI_PO_BOX1
           , DOI.DOI_PO_BOX_NBR1
           , DOI.DOI_COUNTY1
           , DOI.DOI_CONTACT1
           , DOI.PAC_PAC_ADDRESS_ID
           , DOI.DOI_ADDRESS2
           , DOI.PC__PC_CNTRY_ID
           , DOI.DOI_ZIPCODE2
           , DOI.DOI_TOWN2
           , DOI.DOI_STATE2
           , DOI.DOI_NAME2
           , DOI.DOI_FORENAME2
           , DOI.DOI_ACTIVITY2
           , DOI.DOI_CARE_OF2
           , DOI.DOI_PO_BOX2
           , DOI.DOI_PO_BOX_NBR2
           , DOI.DOI_COUNTY2
           , DOI.DOI_CONTACT2
           , DOI.PAC2_PAC_ADDRESS_ID
           , DOI.DOI_ADDRESS3
           , DOI.PC_2_PC_CNTRY_ID
           , DOI.DOI_ZIPCODE3
           , DOI.DOI_TOWN3
           , DOI.DOI_STATE3
           , DOI.DOI_NAME3
           , DOI.DOI_FORENAME3
           , DOI.DOI_ACTIVITY3
           , DOI.DOI_CARE_OF3
           , DOI.DOI_PO_BOX3
           , DOI.DOI_PO_BOX_NBR3
           , DOI.DOI_COUNTY3
           , DOI.DOI_CONTACT3
           , DOI.DIC_POS_FREE_TABLE_1_ID
           , DOI.DIC_POS_FREE_TABLE_2_ID
           , DOI.DIC_POS_FREE_TABLE_3_ID
           , DOI.DOI_TEXT_1
           , DOI.DOI_TEXT_2
           , DOI.DOI_TEXT_3
           , DOI.DOI_DECIMAL_1
           , DOI.DOI_DECIMAL_2
           , DOI.DOI_DECIMAL_3
           , DOI.DOI_DATE_1
           , DOI.DOI_DATE_2
           , DOI.DOI_DATE_3
           , DOI.DOC_DOCUMENT_ID
           , DOI.C_INCOTERMS
           , DOI.PC_EXCHANGE_DATA_IN_ID
           , DOI.DOI_DOCUMENT_TYPE
           , DOI.DOI_INCOTERMS
           , DOI.DOI_INCOTERM_LOCATION
           , DOI.DOI_TOTAL_NET_WEIGHT
           , DOI.DOI_TOTAL_GROSS_WEIGHT
           , DOI.DOI_TOTAL_NET_WEIGHT_MEAS
           , DOI.DOI_TOTAL_GROSS_WEIGHT_MEAS
           , DOI.DOI_PARCEL_QTY
        from DOC_INTERFACE DOI
       where DOI.DOC_INTERFACE_ID = cInterfaceID;

    tplInterfaceInfo crInterfaceInfo%rowtype;
  begin
    open crInterfaceInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_INTERFACE_ID);

    fetch crInterfaceInfo
     into tplInterfaceInfo;

    if crInterfaceInfo%found then
      -- Document source
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOC_DOCUMENT_ID  := tplInterfaceInfo.DOC_DOCUMENT_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_SRC_ID  := tplInterfaceInfo.DOC_DOCUMENT_ID;

      -- Tiers
      if tplInterfaceInfo.PAC_THIRD_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID      := tplInterfaceInfo.PAC_THIRD_ID;
      end if;

      -- Partenaire facturation
      if tplInterfaceInfo.PAC_THIRD_ACI_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID      := tplInterfaceInfo.PAC_THIRD_ACI_ID;
      end if;

      -- Partenaire livraison
      if tplInterfaceInfo.PAC_THIRD_DELIVERY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID      := tplInterfaceInfo.PAC_THIRD_DELIVERY_ID;
      end if;

      -- Partenaire tarification
      if tplInterfaceInfo.PAC_THIRD_TARIFF_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID      := tplInterfaceInfo.PAC_THIRD_TARIFF_ID;
      end if;

      -- n° document Interface
      if tplInterfaceInfo.DOI_NUMBER is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DOI_NUMBER  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DOI_NUMBER      := tplInterfaceInfo.DOI_NUMBER;
      end if;

      -- N° du document final
      if tplInterfaceInfo.DMT_NUMBER is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER  := tplInterfaceInfo.DMT_NUMBER;
      end if;

      -- Texte titre
      if tplInterfaceInfo.DOI_TITLE_TEXT is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TITLE_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TITLE_TEXT      := tplInterfaceInfo.DOI_TITLE_TEXT;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_APPLTXT_ID   := null;
      end if;

      -- Texte entête
      if tplInterfaceInfo.DOI_HEADING_TEXT is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_HEADING_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_HEADING_TEXT      := tplInterfaceInfo.DOI_HEADING_TEXT;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_APPLTXT_ID         := null;
      end if;

      -- Texte document
      if tplInterfaceInfo.DOI_DOCUMENT_TEXT is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DOCUMENT_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DOCUMENT_TEXT      := tplInterfaceInfo.DOI_DOCUMENT_TEXT;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_APPLTXT_ID     := null;
      end if;

      -- Dossier
      if tplInterfaceInfo.DOC_RECORD_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID      := tplInterfaceInfo.DOC_RECORD_ID;
      end if;

      -- Représentant
      if tplInterfaceInfo.PAC_REPRESENTATIVE_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID      := tplInterfaceInfo.PAC_REPRESENTATIVE_ID;
      end if;

      -- Représentant facturation
      if tplInterfaceInfo.PAC_REPR_ACI_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_ACI_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_ACI_ID      := tplInterfaceInfo.PAC_REPR_ACI_ID;
      end if;

      -- Représentant livraison
      if tplInterfaceInfo.PAC_REPR_DELIVERY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_DELIVERY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_DELIVERY_ID      := tplInterfaceInfo.PAC_REPR_DELIVERY_ID;
      end if;

      -- Mode d'expédition
      if tplInterfaceInfo.PAC_SENDING_CONDITION_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SENDING_CONDITION_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SENDING_CONDITION_ID      := tplInterfaceInfo.PAC_SENDING_CONDITION_ID;
      end if;

      -- Code langue
      if tplInterfaceInfo.PC_LANG_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID      := tplInterfaceInfo.PC_LANG_ID;
      end if;

      -- Code langue facturation
      if tplInterfaceInfo.PC_LANG_ACI_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ACI_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ACI_ID      := tplInterfaceInfo.PC_LANG_ACI_ID;
      end if;

      -- Code langue livraison
      if tplInterfaceInfo.PC_LANG_DELIVERY_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_DELIVERY_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_DELIVERY_ID      := tplInterfaceInfo.PC_LANG_DELIVERY_ID;
      end if;

      -- Date document
      if tplInterfaceInfo.DOI_DOCUMENT_DATE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT  := tplInterfaceInfo.DOI_DOCUMENT_DATE;
      end if;

      -- Date valeur
      if tplInterfaceInfo.DOI_VALUE_DATE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE      := tplInterfaceInfo.DOI_VALUE_DATE;
      end if;

      -- Date livraison
      if tplInterfaceInfo.DOI_DELIVERY_DATE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_DELIVERY  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DELIVERY      := tplInterfaceInfo.DOI_DELIVERY_DATE;
      end if;

      -- Tarif
      if tplInterfaceInfo.DIC_TARIFF_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TARIFF_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TARIFF_ID      := tplInterfaceInfo.DIC_TARIFF_ID;
      end if;

      -- Décompte TVA
      if tplInterfaceInfo.ACS_VAT_DET_ACCOUNT_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_VAT_DET_ACCOUNT_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID      := tplInterfaceInfo.ACS_VAT_DET_ACCOUNT_ID;
      end if;

      -- Méthode de paiement
      if tplInterfaceInfo.ACS_FIN_ACC_S_PAYMENT_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_FIN_ACC_S_PAYMENT_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FIN_ACC_S_PAYMENT_ID      := tplInterfaceInfo.ACS_FIN_ACC_S_PAYMENT_ID;
      end if;

      -- Référence du document
      if tplInterfaceInfo.DOI_REFERENCE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_REFERENCE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_REFERENCE      := tplInterfaceInfo.DOI_REFERENCE;
      end if;

      -- Référence partenaire
      if tplInterfaceInfo.DOI_PARTNER_REFERENCE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_REFERENCE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_REFERENCE      := tplInterfaceInfo.DOI_PARTNER_REFERENCE;
      end if;

      -- N° document partenaire
      if tplInterfaceInfo.DOI_PARTNER_NUMBER is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_NUMBER  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_NUMBER      := tplInterfaceInfo.DOI_PARTNER_NUMBER;
      end if;

      -- Date document partenaire
      if tplInterfaceInfo.DOI_PARTNER_DATE is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_PARTNER_DOCUMENT      := tplInterfaceInfo.DOI_PARTNER_DATE;
      end if;

      -- Adresse 1
      if    tplInterfaceInfo.PAC_ADDRESS_ID is not null
         or tplInterfaceInfo.DOI_ADDRESS1 is not null
         or tplInterfaceInfo.PC_CNTRY_ID is not null
         or tplInterfaceInfo.DOI_ZIPCODE1 is not null
         or tplInterfaceInfo.DOI_TOWN1 is not null
         or tplInterfaceInfo.DOI_STATE1 is not null
         or tplInterfaceInfo.DOI_NAME1 is not null
         or tplInterfaceInfo.DOI_FORENAME1 is not null
         or tplInterfaceInfo.DOI_ACTIVITY1 is not null
         or tplInterfaceInfo.DOI_CARE_OF1 is not null
         or tplInterfaceInfo.DOI_PO_BOX1 is not null
         or tplInterfaceInfo.DOI_PO_BOX_NBR1 is not null
         or tplInterfaceInfo.DOI_COUNTY1 is not null
         or tplInterfaceInfo.DOI_CONTACT1 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_1    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID   := tplInterfaceInfo.PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1     := tplInterfaceInfo.DOI_ADDRESS1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID      := tplInterfaceInfo.PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1    := tplInterfaceInfo.DOI_ZIPCODE1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1        := tplInterfaceInfo.DOI_TOWN1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1       := tplInterfaceInfo.DOI_STATE1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1        := tplInterfaceInfo.DOI_NAME1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1    := tplInterfaceInfo.DOI_FORENAME1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1    := tplInterfaceInfo.DOI_ACTIVITY1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1     := tplInterfaceInfo.DOI_CARE_OF1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1      := tplInterfaceInfo.DOI_PO_BOX1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1  := tplInterfaceInfo.DOI_PO_BOX_NBR1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1      := tplInterfaceInfo.DOI_COUNTY1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1     := tplInterfaceInfo.DOI_CONTACT1;
      end if;

      -- Adresse 2
      if    tplInterfaceInfo.PAC_PAC_ADDRESS_ID is not null
         or tplInterfaceInfo.DOI_ADDRESS2 is not null
         or tplInterfaceInfo.PC__PC_CNTRY_ID is not null
         or tplInterfaceInfo.DOI_ZIPCODE2 is not null
         or tplInterfaceInfo.DOI_TOWN2 is not null
         or tplInterfaceInfo.DOI_STATE2 is not null
         or tplInterfaceInfo.DOI_NAME2 is not null
         or tplInterfaceInfo.DOI_FORENAME2 is not null
         or tplInterfaceInfo.DOI_ACTIVITY2 is not null
         or tplInterfaceInfo.DOI_CARE_OF2 is not null
         or tplInterfaceInfo.DOI_PO_BOX2 is not null
         or tplInterfaceInfo.DOI_PO_BOX_NBR2 is not null
         or tplInterfaceInfo.DOI_COUNTY2 is not null
         or tplInterfaceInfo.DOI_CONTACT2 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_2       := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAC_ADDRESS_ID  := tplInterfaceInfo.PAC_PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS2        := tplInterfaceInfo.DOI_ADDRESS2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_CNTRY_ID     := tplInterfaceInfo.PC__PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE2       := tplInterfaceInfo.DOI_ZIPCODE2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN2           := tplInterfaceInfo.DOI_TOWN2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE2          := tplInterfaceInfo.DOI_STATE2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME2           := tplInterfaceInfo.DOI_NAME2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME2       := tplInterfaceInfo.DOI_FORENAME2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY2       := tplInterfaceInfo.DOI_ACTIVITY2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF2        := tplInterfaceInfo.DOI_CARE_OF2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX2         := tplInterfaceInfo.DOI_PO_BOX2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR2     := tplInterfaceInfo.DOI_PO_BOX_NBR2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY2         := tplInterfaceInfo.DOI_COUNTY2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT2        := tplInterfaceInfo.DOI_CONTACT2;
      end if;

      -- Adresse 3
      if    tplInterfaceInfo.PAC2_PAC_ADDRESS_ID is not null
         or tplInterfaceInfo.DOI_ADDRESS3 is not null
         or tplInterfaceInfo.PC_2_PC_CNTRY_ID is not null
         or tplInterfaceInfo.DOI_ZIPCODE3 is not null
         or tplInterfaceInfo.DOI_TOWN3 is not null
         or tplInterfaceInfo.DOI_STATE3 is not null
         or tplInterfaceInfo.DOI_NAME3 is not null
         or tplInterfaceInfo.DOI_FORENAME3 is not null
         or tplInterfaceInfo.DOI_ACTIVITY3 is not null
         or tplInterfaceInfo.DOI_CARE_OF3 is not null
         or tplInterfaceInfo.DOI_PO_BOX3 is not null
         or tplInterfaceInfo.DOI_PO_BOX_NBR3 is not null
         or tplInterfaceInfo.DOI_COUNTY3 is not null
         or tplInterfaceInfo.DOI_CONTACT3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_3        := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC2_PAC_ADDRESS_ID  := tplInterfaceInfo.PAC2_PAC_ADDRESS_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS3         := tplInterfaceInfo.DOI_ADDRESS3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_CNTRY_ID     := tplInterfaceInfo.PC_2_PC_CNTRY_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE3        := tplInterfaceInfo.DOI_ZIPCODE3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN3            := tplInterfaceInfo.DOI_TOWN3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE3           := tplInterfaceInfo.DOI_STATE3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME3            := tplInterfaceInfo.DOI_NAME3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME3        := tplInterfaceInfo.DOI_FORENAME3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY3        := tplInterfaceInfo.DOI_ACTIVITY3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF3         := tplInterfaceInfo.DOI_CARE_OF3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX3          := tplInterfaceInfo.DOI_PO_BOX3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR3      := tplInterfaceInfo.DOI_PO_BOX_NBR3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY3          := tplInterfaceInfo.DOI_COUNTY3;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT3         := tplInterfaceInfo.DOI_CONTACT3;
      end if;

      -- Dicos libres
      if    tplInterfaceInfo.DIC_POS_FREE_TABLE_1_ID is not null
         or tplInterfaceInfo.DIC_POS_FREE_TABLE_2_ID is not null
         or tplInterfaceInfo.DIC_POS_FREE_TABLE_3_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_POS_FREE_TABLE   := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_1_ID  := tplInterfaceInfo.DIC_POS_FREE_TABLE_1_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_2_ID  := tplInterfaceInfo.DIC_POS_FREE_TABLE_2_ID;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_3_ID  := tplInterfaceInfo.DIC_POS_FREE_TABLE_3_ID;
      end if;

      -- Textes libres
      if    tplInterfaceInfo.DOI_TEXT_1 is not null
         or tplInterfaceInfo.DOI_TEXT_2 is not null
         or tplInterfaceInfo.DOI_TEXT_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TEXT  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_1    := tplInterfaceInfo.DOI_TEXT_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_2    := tplInterfaceInfo.DOI_TEXT_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_3    := tplInterfaceInfo.DOI_TEXT_3;
      end if;

      -- Décimaux libres
      if    tplInterfaceInfo.DOI_DECIMAL_1 is not null
         or tplInterfaceInfo.DOI_DECIMAL_2 is not null
         or tplInterfaceInfo.DOI_DECIMAL_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DECIMAL  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_1    := tplInterfaceInfo.DOI_DECIMAL_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_2    := tplInterfaceInfo.DOI_DECIMAL_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_3    := tplInterfaceInfo.DOI_DECIMAL_3;
      end if;

      -- Dates libres
      if    tplInterfaceInfo.DOI_DATE_1 is not null
         or tplInterfaceInfo.DOI_DATE_2 is not null
         or tplInterfaceInfo.DOI_DATE_3 is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_1    := tplInterfaceInfo.DOI_DATE_1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_2    := tplInterfaceInfo.DOI_DATE_2;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_3    := tplInterfaceInfo.DOI_DATE_3;
      end if;

      -- Document entrant
      if tplInterfaceInfo.PC_EXCHANGE_DATA_IN_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_EXCHANGE_DATA_IN    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_EXCHANGE_DATA_IN_ID  := tplInterfaceInfo.PC_EXCHANGE_DATA_IN_ID;
      end if;

      -- Récupère les incoterms
      if    tplInterfaceInfo.C_INCOTERMS is not null
         or tplInterfaceInfo.DOI_INCOTERM_LOCATION is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_INCOTERMS        := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS          := tplInterfaceInfo.C_INCOTERMS;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE  := tplInterfaceInfo.DOI_INCOTERM_LOCATION;
      end if;

      -- Poids total
      if    tplInterfaceInfo.DOI_TOTAL_NET_WEIGHT is not null
         or tplInterfaceInfo.DOI_TOTAL_GROSS_WEIGHT is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_TOTAL_WEIGHT    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_NET_WEIGHT    := tplInterfaceInfo.DOI_TOTAL_NET_WEIGHT;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_GROSS_WEIGHT  := tplInterfaceInfo.DOI_TOTAL_GROSS_WEIGHT;
      end if;

      -- Poids total mesuré
      if    tplInterfaceInfo.DOI_TOTAL_NET_WEIGHT_MEAS is not null
         or tplInterfaceInfo.DOI_TOTAL_GROSS_WEIGHT_MEAS is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_TOTAL_WEIGHT_MEAS    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_NET_WEIGHT_MEAS    := tplInterfaceInfo.DOI_TOTAL_NET_WEIGHT_MEAS;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_GROSS_WEIGHT_MEAS  := tplInterfaceInfo.DOI_TOTAL_GROSS_WEIGHT_MEAS;
      end if;
    end if;

    close crInterfaceInfo;

    InitDocument_205;
  end InitDocument_340;

  /**
  *  procedure InitDocument_341
  *  Description
  *    Décharge - Générateur de documents concernant la dématérialisation
  */
  procedure InitDocument_341
  is
  begin
    -- L'initialisation du 341 est actuellement la même que celle du 340
    InitDocument_340;
  end InitDocument_341;

  /**
  *  procedure InitDocument_345
  *  Description
  *    Décharge - Générateur de documents Order Entry
  */
  procedure InitDocument_345
  is
  begin
    -- reprendre le tiers du document à l'origine de l'Order Entry
    select PAC_THIRD_ID
      into DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
      from DOC_INTERFACE
     where DOC_INTERFACE_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_INTERFACE_ID;

    InitDocument_205;
  end InitDocument_345;

  /**
  *  procedure InitDocument_390
  *  Description
  *    Décharge - Echéancier
  */
  procedure InitDocument_390
  is
  begin
    InitDocument_205;
  end InitDocument_390;

  /**
  *  procedure ControlInitDocumentData
  *  Description
  *    Contrôle les données et si besoin initialise avant l'insertion même dans la table DOC_DOCUMENT
  */
  procedure ControlInitDocumentData
  is
    -- informations sur le gabarit du document à créér
    cursor crGaugeInfo(cGaugeID DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select GAU.DIC_GAUGE_TYPE_DOC_ID
           , GAU.GAU_REF_PARTNER
           , GAU.PAC_THIRD_ID
           , GAU.PAC_THIRD_ACI_ID
           , GAU.PAC_THIRD_DELIVERY_ID
           , GAU.GAU_TRAVELLER
           , GAU.GAU_CONFIRM_STATUS
           , GAU.GAU_EXPIRY_NBR
           , GAU.PC_APPLTXT_ID
           , GAU.PC__PC_APPLTXT_ID
           , GAU.PC_2_PC_APPLTXT_ID
           , nvl(GAU.C_GAU_INCOTERMS, '0') C_GAU_INCOTERMS
           , GAU.GAU_INCOTERMS
           , GAU.C_GAU_THIRD_VAT
           , GAU.GAU_FREE_DATA_USE
           , GAU.DIC_GAUGE_FREE_CODE_1_ID
           , GAU.DIC_GAUGE_FREE_CODE_2_ID
           , GAU.DIC_GAUGE_FREE_CODE_3_ID
           , GAU.GAU_FREE_NUMBER1
           , GAU.GAU_FREE_NUMBER2
           , GAU.GAU_FREE_DATE1
           , GAU.GAU_FREE_DATE2
           , GAU.GAU_FREE_BOOL1
           , GAU.GAU_FREE_BOOL2
           , GAU.GAU_FREE_TEXT_LONG
           , GAU.GAU_FREE_TEXT_SHORT
           , GAU.DOC_GAUGE_SIGNATORY_ID
           , GAU.DOC_DOC_GAUGE_SIGNATORY_ID
           , GAU.DIC_TYPE_DOC_CUSTOM_ID
           , GAU.C_DIRECTION_NUMBER
           , GAU.GAU_DOSSIER
           , GAU.DIC_ADDRESS_TYPE_ID
           , GAU.DIC_ADDRESS_TYPE1_ID
           , GAU.DIC_ADDRESS_TYPE2_ID
           , GAU.C_ADMIN_DOMAIN
           , decode(nvl(GAS.DOC_GAUGE_ID, 0), 0, 0, 1) IS_GAUGE_STRUCTURED
           , nvl(GAS.GAS_FINANCIAL_CHARGE, 0) GAS_FINANCIAL_CHARGE
           , nvl(GAS.GAS_ANAL_CHARGE, 0) GAS_ANAL_CHARGE
           , nvl(GAS.GAS_VISIBLE_COUNT, 0) GAS_VISIBLE_COUNT
           , nvl(GAS.GAS_FINANCIAL_REF, 0) GAS_FINANCIAL_REF
           , nvl(GAS.GAS_BALANCE_STATUS, 0) GAS_BALANCE_STATUS
           , nvl(GAS.GAS_PAY_CONDITION, 0) GAS_PAY_CONDITION
           , nvl(GAS.GAS_SENDING_CONDITION, 0) GAS_SENDING_CONDITION
           , nvl(GAS.GAS_DISTRIBUTION_CHANNEL, 0) GAS_DISTRIBUTION_CHANNEL
           , nvl(GAS.GAS_SALE_TERRITORY, 0) GAS_SALE_TERRITORY
           , GAS.ACS_FIN_ACC_S_PAYMENT_ID
           , GAS.PAC_PAYMENT_CONDITION_ID
           , nvl(GAS.GAS_VAT, 0) GAS_VAT
           , GAS.C_BVR_GENERATION_METHOD
           , nvl(GAS.GAS_CASH_REGISTER, 0) GAS_CASH_REGISTER
           , GAS.ACJ_JOB_TYPE_S_CAT_PMT_ID
           , nvl(GAS.GAS_PCENT, 0) GAS_PCENT
           , nvl(GAS.C_DOC_PRE_ENTRY, '0') C_DOC_PRE_ENTRY
           , nvl(GAS.C_DOC_PRE_ENTRY_THIRD, '0') C_DOC_PRE_ENTRY_THIRD
           , nvl(GAS.GAS_WEIGHT_MAT, 0) GAS_WEIGHT_MAT
           , GAS.C_CREDIT_LIMIT
           , nvl(GAS.GAS_ADDENDUM, 0) GAS_ADDENDUM
           , nvl(GAS.GAS_EBPP_REFERENCE, 0) GAS_EBPP_REFERENCE
           , GAS.C_START_CONTROL_DATE
           , GAS.C_CONTROLE_DATE_DOCUM
        from DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = cGaugeID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID(+);

    tplGaugeInfo               crGaugeInfo%rowtype;

    cursor crPartnerInfo(cThirdID in PAC_THIRD.PAC_THIRD_ID%type, cGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then VAT_SUP.ACS_FINANCIAL_CURRENCY_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then VAT_CUS.ACS_FINANCIAL_CURRENCY_ID
                else nvl(VAT_CUS.ACS_FINANCIAL_CURRENCY_ID, VAT_SUP.ACS_FINANCIAL_CURRENCY_ID)
              end
             ) VAT_CURRENCY_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_PAYMENT_CONDITION_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_PAYMENT_CONDITION_ID
                else nvl(CUS.PAC_PAYMENT_CONDITION_ID, SUP.PAC_PAYMENT_CONDITION_ID)
              end
             ) PAC_PAYMENT_CONDITION_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_SENDING_CONDITION_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_SENDING_CONDITION_ID
                else nvl(CUS.PAC_SENDING_CONDITION_ID, SUP.PAC_SENDING_CONDITION_ID)
              end
             ) PAC_SENDING_CONDITION_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then null
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_REPRESENTATIVE_ID
                else CUS.PAC_REPRESENTATIVE_ID
              end) PAC_REPRESENTATIVE_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.ACS_FIN_ACC_S_PAYMENT_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.ACS_FIN_ACC_S_PAYMENT_ID
                else nvl(CUS.ACS_FIN_ACC_S_PAYMENT_ID, SUP.ACS_FIN_ACC_S_PAYMENT_ID)
              end
             ) ACS_FIN_ACC_S_PAYMENT_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.DIC_TYPE_SUBMISSION_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.DIC_TYPE_SUBMISSION_ID
                else nvl(CUS.DIC_TYPE_SUBMISSION_ID, SUP.DIC_TYPE_SUBMISSION_ID)
              end
             ) DIC_TYPE_SUBMISSION_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.C_INCOTERMS
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.C_INCOTERMS
                else nvl(CUS.C_INCOTERMS, SUP.C_INCOTERMS)
              end
             ) C_INCOTERMS
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.CRE_INCOTERMS_PLACE
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.CUS_INCOTERMS_PLACE
                else nvl(CUS.CUS_INCOTERMS_PLACE, SUP.CRE_INCOTERMS_PLACE)
              end
             ) INCOTERMS_PLACE
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.ACS_VAT_DET_ACCOUNT_ID
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.ACS_VAT_DET_ACCOUNT_ID
                else nvl(CUS.ACS_VAT_DET_ACCOUNT_ID, SUP.ACS_VAT_DET_ACCOUNT_ID)
              end
             ) ACS_VAT_DET_ACCOUNT_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then null
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.C_BVR_GENERATION_METHOD
                else CUS.C_BVR_GENERATION_METHOD
              end
             ) C_BVR_GENERATION_METHOD
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then null
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_DISTRIBUTION_CHANNEL_ID
                else CUS.PAC_DISTRIBUTION_CHANNEL_ID
              end
             ) PAC_DISTRIBUTION_CHANNEL_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then null
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_SALE_TERRITORY_ID
                else CUS.PAC_SALE_TERRITORY_ID
              end) PAC_SALE_TERRITORY_ID
           , (case
                when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.C_DELIVERY_TYP
                when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.C_DELIVERY_TYP
                else nvl(CUS.C_DELIVERY_TYP, SUP.C_DELIVERY_TYP)
              end
             ) C_DELIVERY_TYP
           , nvl(case
                   when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.C_PARTNER_STATUS
                   when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.C_PARTNER_STATUS
                   else nvl(CUS.C_PARTNER_STATUS, SUP.C_PARTNER_STATUS)
                 end
               , '0'
                ) C_PARTNER_STATUS
           , SUP.PAC_SUPPLIER_PARTNER_ID
           , CUS.PAC_CUSTOM_PARTNER_ID
        from DOC_GAUGE GAU
           , PAC_THIRD THI
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
           , ACS_VAT_DET_ACCOUNT VAT_CUS
           , ACS_VAT_DET_ACCOUNT VAT_SUP
       where GAU.DOC_GAUGE_ID = cGaugeID
         and THI.PAC_THIRD_ID = cThirdID
         and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
         and CUS.ACS_VAT_DET_ACCOUNT_ID = VAT_CUS.ACS_VAT_DET_ACCOUNT_ID(+)
         and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
         and SUP.ACS_VAT_DET_ACCOUNT_ID = VAT_SUP.ACS_VAT_DET_ACCOUNT_ID(+);

    tplPartnerInfo             crPartnerInfo%rowtype;
    tplPartnerInfo_ACI         crPartnerInfo%rowtype;
    tplPartnerInfo_DELIVERY    crPartnerInfo%rowtype;
    --
    vDOC_ADDRESS_INFO          DOC_DOCUMENT_FUNCTIONS.TDOC_ADDRESS_INFO;
    vDOC_ADDRESS_INFO_ACI      DOC_DOCUMENT_FUNCTIONS.TDOC_ADDRESS_INFO;
    vDOC_ADDRESS_INFO_DELIVERY DOC_DOCUMENT_FUNCTIONS.TDOC_ADDRESS_INFO;
    -- variable pour la recherche du n° de document
    GaugeNumberingID           DOC_GAUGE.DOC_GAUGE_NUMBERING_ID%type;
    -- Variables en rapport avec le tiers
    vPAC_THIRD_ID              DOC_DOCUMENT.PAC_THIRD_ID%type;
    vPAC_THIRD_ACI_ID          DOC_DOCUMENT.PAC_THIRD_ACI_ID%type;
    vPAC_THIRD_TARIFF_ID       DOC_DOCUMENT.PAC_THIRD_TARIFF_ID%type;
    -- Pré-saisie
    vPE_ThirdID                PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    vPE_DocNumber              ACT_DOCUMENT.DOC_NUMBER%type;
    vPE_DocDate                ACT_DOCUMENT.DOC_DOCUMENT_DATE%type;
    vPE_CurrencyID             ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    vPE_ExchRate               ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    vPE_BasePrice              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    vPE_ValueDate              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
    vPE_TransactionDate        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
    vPE_PartnerNumber          ACT_PART_IMPUTATION.PAR_DOCUMENT%type;
    vPE_PayConditionID         ACT_PART_IMPUTATION.PAC_PAYMENT_CONDITION_ID%type;
    vPE_FinRefID               ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID%type;
    vPE_BlockedDoc             ACT_PART_IMPUTATION.PAR_BLOCKED_DOCUMENT%type;
    vPE_DicBlockedReason       ACT_PART_IMPUTATION.DIC_BLOCKED_REASON_ID%type;
    vPE_RefBVR                 ACT_EXPIRY.EXP_REF_BVR%type;
    -- Variables pour les cours de change
    LocalCurrencyID            DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type               default ACS_FUNCTION.GetLocalCurrencyID;
    BaseChange                 number;
    RateExchangeEUR_ME         number;
    FixedRateEUR_ME            number;
    RateExchangeEUR_MB         number;
    FixedRateEUR_MB            number;
    VATBaseChange              number;
    VATRateExchangeEUR_ME      number;
    VATFixedRateEUR_ME         number;
    VATRateExchangeEUR_MB      number;
    VATFixedRateEUR_MB         number;
    NumTmp                     number;
    vPartnerType               varchar2(1);
    vPartnerCategory           PAC_SUPPLIER_PARTNER.C_PARTNER_CATEGORY%type;
    vPartnerLimitType          PAC_CREDIT_LIMIT.C_LIMIT_TYPE%type;
    vPartnerLimitAmount        number;
    vGroupLimitType            PAC_CREDIT_LIMIT.C_LIMIT_TYPE%type;
    vGroupLimitAmount          number;
    -- défini si on lie le document au dossier
    vLinkRecord                number(1);
    vRecordId                  DOC_RECORD.DOC_RECORD_ID%type;
    vRecordCategoryId          DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type;
    docDivisionAccId           DOC_DOCUMENT.ACS_DIVISION_ACCOUNT_ID%type;
    docFinancialAccId          DOC_DOCUMENT.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    -- Vérifier que le gabarit soit renseigné
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID is null then
      -- Arrêter l'execution de cette procédure
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de document - L''ID du gabarit est manquant !');
      return;
    end if;

    -- Recherche des info du gabarit pour la création
    open crGaugeInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID);

    fetch crGaugeInfo
     into tplGaugeInfo;

    -- Recherche l'ID du document à créér s'il n'a pas été passé en paramètre
    if nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID, 0) = 0 then
      select INIT_ID_SEQ.nextval
        into DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID
        from dual;
    end if;

    -- Vérifie si le n° de document a été passé en paramétre ou bien si l'on doit le générer
    if nvl(rtrim(ltrim(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER) ), '-1') = '-1' then
      DOC_DOCUMENT_FUNCTIONS.GetDocumentNumber(aGaugeID            => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                             , aGaugeNumberingID   => GaugeNumberingID
                                             , aDocNumber          => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER
                                              );
    end if;

    -- Si pré-saisie pas autorisée dans le gabarit, effacer l'ID de pré-saisie
    if tplGaugeInfo.C_DOC_PRE_ENTRY = '0' then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PRE_ENTRY    := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PRE_ENTRY    := 0;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID  := null;
    -- Si document de pré-saisie est obligatoire, vérifier qu'il soit renseigné
    else
      if     (to_number(tplGaugeInfo.C_DOC_PRE_ENTRY) in(3, 4) )
         and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID is null) then
        -- Arrêter l'execution de cette procédure
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de document - Le document comptable est manquant !');
        return;
      end if;

      -- Document de pré-saisie passé en param
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID is not null then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PRE_ENTRY          := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PRE_ENTRY          := 1;
        -- Rechercher les infos concernant le document de pré-saisie
        -- Faire le contrôle Tiers Finance = Tiers logistique selon le gabarit
        -- Contrôler si la monnaie de la pré-saisie est active pour le tiers du document logistique
        DOC_DOCUMENT_FUNCTIONS.ControlAndInitPreEntry
                                       (aActDocumentID         => DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID
                                      , aDocThirdID            => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                      , aAciThirdID            => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID
                                      , aGaugeID               => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                      , aAciCompany            => ACI_LOGISTIC_DOCUMENT.getFinancialCompany
                                                                                                   (DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                                                                  , nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID
                                                                                                      , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                                                                       )
                                                                                                   )
                                      , aPE_ThirdID            => vPE_ThirdID
                                      , aPE_DocNumber          => vPE_DocNumber
                                      , aPE_DocDate            => vPE_DocDate
                                      , aPE_CurrencyID         => vPE_CurrencyID
                                      , aPE_ExchRate           => vPE_ExchRate
                                      , aPE_BasePrice          => vPE_BasePrice
                                      , aPE_ValueDate          => vPE_ValueDate
                                      , aPE_TransactionDate    => vPE_TransactionDate
                                      , aPE_PartnerNumber      => vPE_PartnerNumber
                                      , aPE_PayConditionID     => vPE_PayConditionID
                                      , aPE_FinRefID           => vPE_FinRefID
                                      , aPE_BlockedDoc         => vPE_BlockedDoc
                                      , aPE_DicBlockedReason   => vPE_DicBlockedReason
                                      , aPE_RefBVR             => vPE_RefBVR
                                       );
        -- La date de la pré-saisie est déjà initialisée à l'interface lors de la sélection de la pré-saisie
        -- et celle-ci a passé les controles de validité périodes/exercices et il ne faut donc pas l'écraser
        vPE_TransactionDate                                         := null;

        -- Utiliser le tiers de la pré-saisie en priorité
        if (vPE_ThirdID is not null) then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID      := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID      := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID, vPE_ThirdID);
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID  := nvl(vPE_ThirdID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID);
        end if;

        -- Utilisation de la monnaie de Pré-saisie
        if     (vPE_CurrencyID is not null)
           and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID = vPE_ThirdID) then
          -- Utiliser en priorité la Monnaie de la pré-saisie
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := vPE_CurrencyID;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_OF_EXCHANGE       := vPE_ExchRate;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_BASE_PRICE             := vPE_BasePrice;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_EURO              := 0;
        end if;

        -- Date document avec la date de la transaction de la pré-saisie
        if vPE_TransactionDate is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT  := vPE_TransactionDate;
        end if;

        -- Initialisation de la date valeur avec la date valeur de la pré-saisie si celle-ci est renseignée
        if vPE_ValueDate is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE      := vPE_ValueDate;
        end if;

        -- Date document partenaire
        if vPE_DocDate is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_PARTNER_DOCUMENT      := vPE_DocDate;
        end if;

        -- N° du document partenaire de la pré-saisie
        if vPE_PartnerNumber is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_NUMBER  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_NUMBER      := vPE_PartnerNumber;
        end if;

        -- Condition de payement de la pré-saisie
        if vPE_PayConditionID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID      := vPE_PayConditionID;
        end if;

        -- Réf. financière de la pré-saisie
        if vPE_FinRefID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_FINANCIAL_REFERENCE_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_FINANCIAL_REFERENCE_ID      := vPE_FinRefID;
        end if;

        -- Blocage du document finance
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FIN_DOC_BLOCKED    := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FIN_DOC_BLOCKED    := vPE_BlockedDoc;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_BLOCKED_REASON_ID  := vPE_DicBlockedReason;

        -- Méthode de génération du BVR
        if vPE_RefBVR is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_REF_BVR_NUMBER  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_REF_BVR_NUMBER      := vPE_RefBVR;
        end if;
      else
        -- Pas de document de pré-saisie initialisé
        vPE_ThirdID           := null;
        vPE_DocDate           := null;
        vPE_CurrencyID        := null;
        vPE_ExchRate          := null;
        vPE_BasePrice         := null;
        vPE_ValueDate         := null;
        vPE_TransactionDate   := null;
        vPE_PartnerNumber     := null;
        vPE_PayConditionID    := null;
        vPE_FinRefID          := null;
        vPE_BlockedDoc        := null;
        vPE_DicBlockedReason  := null;
        vPE_RefBVR            := null;
      end if;
    end if;

    -- Vérifie si la date du document a été passée
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT is null then
      -- Utiliser la date du jour
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT  := trunc(sysdate);
    end if;

    -- Ctrl de la date du document lors de la création demandé par le gabarit
    if tplGaugeInfo.C_START_CONTROL_DATE in('1', '3') then
      declare
        lvErrorTitle  varchar2(32000);
        lvErrorMsg    varchar2(32000);
        lvConfirmFail varchar2(32000);
        lnCtrlOK      integer;
      begin
        -- Contrôle de la validaté de la date du document
        DOC_DOCUMENT_FUNCTIONS.ValidateDocumentDate(aDate         => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT
                                                  , aCtrlType     => tplGaugeInfo.C_CONTROLE_DATE_DOCUM
                                                  , ErrorTitle    => lvErrorTitle
                                                  , ErrorMsg      => lvErrorMsg
                                                  , ConfirmFail   => lvConfirmFail
                                                  , CtrlOK        => lnCtrlOK
                                                   );

        if lnCtrlOK = 0 then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := lvErrorTitle || chr(10) || lvErrorMsg;
          return;
        end if;
      end;
    end if;

    -- Initialise le champ "Type document gabarit"
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_GAUGE_TYPE_DOC_ID           := tplGaugeInfo.DIC_GAUGE_TYPE_DOC_ID;

    -- Si Réf. partenaire vérifier que celui-ci soit renseigné
    if tplGaugeInfo.GAU_REF_PARTNER = 1 then
      -- Si tiers pas initialisé
      if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID = 0)
         or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID is null) then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ID  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID      := nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID, tplGaugeInfo.PAC_THIRD_ID);
      end if;

      vPAC_THIRD_ID                                                   := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID;

      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID is null then
        -- Arrêter l'execution de cette procédure
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de document - Le tiers est manquant !');
        return;
      end if;

      -- Recherche des partenaires liés au partenaire donneur d'ordre
      select (case
                when tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_PAC_THIRD_1_ID
                when tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_PAC_THIRD_1_ID
                else nvl(CUS.PAC_PAC_THIRD_1_ID, SUP.PAC_PAC_THIRD_1_ID)
              end
             ) PAC_THIRD_ACI_ID
           , (case
                when tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_PAC_THIRD_2_ID
                when tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_PAC_THIRD_2_ID
                else nvl(CUS.PAC_PAC_THIRD_2_ID, SUP.PAC_PAC_THIRD_2_ID)
              end
             ) PAC_THIRD_TARIFF_ID
        into vPAC_THIRD_ACI_ID
           , vPAC_THIRD_TARIFF_ID
        from PAC_THIRD THI
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where THI.PAC_THIRD_ID = vPAC_THIRD_ID
         and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
         and CUS.C_PARTNER_STATUS(+) = '1'
         and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
         and SUP.C_PARTNER_STATUS(+) = '1';

      -- Partenaire facturation
      if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID is null)
         or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID = 0) then
        -- 1.Partenaire facturation du gabarit
        -- 2.Partenaire facturation du partenaire donneur d’ordre
        -- 3.Partenaire donneur d’ordre
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID  := nvl(tplGaugeInfo.PAC_THIRD_ACI_ID, nvl(vPAC_THIRD_ACI_ID, vPAC_THIRD_ID) );
      end if;

      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_ACI_ID       := 1;

      -- Partenaire tarification
      if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID is null)
         or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID = 0) then
        -- 1.Partenaire tarification du partenaire donneur d’ordre
        -- 2.Partenaire donneur d’ordre
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID  := nvl(vPAC_THIRD_TARIFF_ID, vPAC_THIRD_ID);
      end if;

      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_TARIFF_ID    := 1;

      -- Partenaire livraison
      if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is null)
         or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID = 0) then
        -- 1.Partenaire livraison du gabarit
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID  := tplGaugeInfo.PAC_THIRD_DELIVERY_ID;

        -- 2.Si domaine « Vente » ou « SAV » => Partenaire donneur d’ordre
        --   Sinon  Partenaire livraison = vide
        if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is null)
           and (tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') ) then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID  := vPAC_THIRD_ID;
        end if;
      end if;

      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_THIRD_DELIVERY_ID  := 1;
    else
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID           := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID       := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID    := null;
    end if;

    -- Recherche les information liées au partenaire donneur d'ordre
    open crPartnerInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID);

    fetch crPartnerInfo
     into tplPartnerInfo;

    close crPartnerInfo;

    -- Contrôler que le tiers existe en tant que client ou fournisseur selon le domaine
    if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID is not null) then
      -- Domaine Vente et SAV : contrôler que le client existe
      if     (tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') )
         and (tplPartnerInfo.PAC_CUSTOM_PARTNER_ID is null) then
        -- Arrêter l'execution de cette procédure
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de document - Le client n''existe pas !');
        return;
      end if;

      -- Domaine Achat et Sous-traitance : contrôler que le fournisseur existe
      if     (tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') )
         and (tplPartnerInfo.PAC_SUPPLIER_PARTNER_ID is null) then
        -- Arrêter l'execution de cette procédure
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de document - Le fournisseur n''existe pas !');
        return;
      end if;
    end if;

    if     DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID is not null
       and (nvl(tplPartnerInfo.C_PARTNER_STATUS, '0') <> '1') then   -- Le tiers n'est pas actif finance et logistique
      -- Arrêter l'execution de cette procédure
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR          := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de document - Le tiers n''est pas actif !');
      return;
    end if;

    -- Tiers de réf. TVA
    -- 1 = Partenaire Donneur d'ordre
    -- 2 = Partenaire livraison
    -- 3 = Partenaire facturation
    -- 1 = Partenaire Donneur d'ordre
    if tplGaugeInfo.C_GAU_THIRD_VAT = 1 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_VAT_ID  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID;
    -- 2 = Partenaire livraison
    elsif tplGaugeInfo.C_GAU_THIRD_VAT = 2 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_VAT_ID  :=
                                             nvl(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID);
    -- 3 = Partenaire facturation
    elsif tplGaugeInfo.C_GAU_THIRD_VAT = 3 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_VAT_ID  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_GAU_THIRD_VAT                 := tplGaugeInfo.C_GAU_THIRD_VAT;

    -- Définition du tiers pour la recherche des données compl.
    if     (tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') )
       and (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is not null) then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_CDA_ID  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID;
    else
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_CDA_ID  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID;
    end if;

    /* Si le gabarit ne gère pas le statut 'à confirmer' mais que le couple
       gabarit/tiers document nécessite un contrôle limite de crédit bloquante
       logistique-finance, alors on initialise quand même le statut
       'à confirmer' sur le document en création. */

    -- Recherche des limites de crédit du partenaire et de son groupe
    vPartnerLimitType                                                    := 0;
    vGroupLimitType                                                      := 0;

    if     (tplGaugeInfo.GAU_CONFIRM_STATUS = 0)
       and DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID is not null then
      if tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then
        vPartnerType  := 'S';

        select nvl(max(C_PARTNER_CATEGORY), '0')
          into vPartnerCategory
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID;
      else
        vPartnerType  := 'C';

        select nvl(max(C_PARTNER_CATEGORY), '0')
          into vPartnerCategory
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID;
      end if;

      DOC_DOCUMENT_FUNCTIONS.GetCreditLimit(vPartnerType
                                          , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID
                                          , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID
                                          , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT
                                          , vPartnerCategory
                                          , vPartnerLimitType
                                          , vPartnerLimitAmount
                                          , vGroupLimitType
                                          , vGroupLimitAmount
                                           );
    end if;

    -- Initialise le statut du document
    if    (tplGaugeInfo.GAU_CONFIRM_STATUS = 1)
       or (     (tplGaugeInfo.C_CREDIT_LIMIT = '2')
           and (vPartnerLimitType = '3') )
       or (     (tplGaugeInfo.C_CREDIT_LIMIT = '2')
           and (vGroupLimitType = '3') ) then
      -- Statut "à confirmer"
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOCUMENT_STATUS  := '01';
    else
      if tplGaugeInfo.GAS_BALANCE_STATUS = 1 then
        -- Statut "à solder"
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOCUMENT_STATUS  := '02';
      else
        -- Statut "liquidé"
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DOCUMENT_STATUS  := '04';
      end if;
    end if;

    -- Initialise la date de création du document si elle est nulle
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_DATECRE is null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_DATECRE  := sysdate;
    end if;

    -- Initialise l'ID de la personne qui a créé le document s'il est nul
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_IDCRE is null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_IDCRE  := PCS.PC_I_LIB_SESSION.GetUserIni;
    end if;

    -- Recherche les information liées au partenaire facturation
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID then
      tplPartnerInfo_ACI  := tplPartnerInfo;
    else
      open crPartnerInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID);

      fetch crPartnerInfo
       into tplPartnerInfo_ACI;

      close crPartnerInfo;
    end if;

    -- Recherche les information liées au partenaire livraison
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID then
      tplPartnerInfo_DELIVERY  := tplPartnerInfo;
    elsif DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID then
      tplPartnerInfo_DELIVERY  := tplPartnerInfo_ACI;
    else
      open crPartnerInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID);

      fetch crPartnerInfo
       into tplPartnerInfo_DELIVERY;

      close crPartnerInfo;
    end if;

    -- Rechercher l'adresse du partenaire donneur d'ordre
    DOC_DOCUMENT_FUNCTIONS.GetDocAddress(aAddressTypeID   => tplGaugeInfo.DIC_ADDRESS_TYPE_ID
                                       , aThirdID         => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                       , aAddressInfo     => vDOC_ADDRESS_INFO
                                        );
    -- Rechercher l'adresse du partenaire facturation
    DOC_DOCUMENT_FUNCTIONS.GetDocAddress(aAddressTypeID   => tplGaugeInfo.DIC_ADDRESS_TYPE2_ID
                                       , aThirdID         => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID
                                       , aAddressInfo     => vDOC_ADDRESS_INFO_ACI
                                        );
    -- Rechercher l'adresse du partenaire livraison
    DOC_DOCUMENT_FUNCTIONS.GetDocAddress(aAddressTypeID   => tplGaugeInfo.DIC_ADDRESS_TYPE1_ID
                                       , aThirdID         => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID
                                       , aAddressInfo     => vDOC_ADDRESS_INFO_DELIVERY
                                        );

    -- Si le code langue du partenaire DONNEUR D'ORDRE n'a pas été initialisé, Utiliser code langue des adresses
    if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID = 0)
       or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID is null) then
      -- Si code langue du tiers renseigné, utiliser le code langue du tiers
      -- Document sans Tiers, utiliser le code langue de l'utilisateur
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID  := nvl(vDOC_ADDRESS_INFO.PC_LANG_ID, PCS.PC_I_LIB_SESSION.GetUserLangID);
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ID                  := 1;

    -- Si le code langue du partenaire de FACTURATION n'a pas été initialisé, Utiliser code langue des adresses
    if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ACI_ID = 0)
       or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ACI_ID is null) then
      -- Si code langue du tiers renseigné, utiliser le code langue du tiers
      -- Document sans Tiers, utiliser le code langue de l'utilisateur
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ACI_ID  := nvl(vDOC_ADDRESS_INFO_ACI.PC_LANG_ID, PCS.PC_I_LIB_SESSION.GetUserLangID);
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_ACI_ID              := 1;

    -- Si le code langue du partenaire de LIVRAISON n'a pas été initialisé, Utiliser code langue des adresses
    if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_DELIVERY_ID = 0)
       or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_DELIVERY_ID is null) then
      -- Si code langue du tiers renseigné, utiliser le code langue du tiers
      -- Document sans Tiers, utiliser le code langue de l'utilisateur
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_DELIVERY_ID  := nvl(vDOC_ADDRESS_INFO_DELIVERY.PC_LANG_ID, PCS.PC_I_LIB_SESSION.GetUserLangID);
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PC_LANG_DELIVERY_ID         := 1;

    -- Gabarit gére le Représentant
    if tplGaugeInfo.GAU_TRAVELLER = 1 then
      -- Si Représentant pas initialisé, utiliser le Représentant du partenaire donneur d'ordre
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPRESENTATIVE_ID = 0 then
        -- Vérifier que le Représentant du partenaire donneur d'ordre soit "Actif logistique et finance"
        select max(decode(C_PARTNER_STATUS, '1', PAC_REPRESENTATIVE_ID, null) )
          into DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID
          from PAC_REPRESENTATIVE
         where PAC_REPRESENTATIVE_ID = tplPartnerInfo.PAC_REPRESENTATIVE_ID;
      end if;

      -- Si Représentant pas initialisé, utiliser le Représentant du partenaire facturation
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_ACI_ID = 0 then
        -- Vérifier que le Représentant du partenaire facturation soit "Actif logistique et finance"
        select max(decode(C_PARTNER_STATUS, '1', PAC_REPRESENTATIVE_ID, null) )
          into DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_ACI_ID
          from PAC_REPRESENTATIVE
         where PAC_REPRESENTATIVE_ID = tplPartnerInfo_ACI.PAC_REPRESENTATIVE_ID;
      end if;

      -- Si Représentant pas initialisé, utiliser le Représentant du partenaire livraison
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_DELIVERY_ID = 0 then
        -- Vérifier que le Représentant du partenaire livraison soit "Actif logistique et finance"
        select max(decode(C_PARTNER_STATUS, '1', PAC_REPRESENTATIVE_ID, null) )
          into DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_DELIVERY_ID
          from PAC_REPRESENTATIVE
         where PAC_REPRESENTATIVE_ID = tplPartnerInfo_DELIVERY.PAC_REPRESENTATIVE_ID;
      end if;
    else
      -- Pas de Représentant géré au niveau du gabarit
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPRESENTATIVE_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_ACI_ID        := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_REPR_DELIVERY_ID   := null;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPRESENTATIVE_ID       := 1;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_ACI_ID             := 1;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_REPR_DELIVERY_ID        := 1;

    -- Gabarit gére la Condition de paiement
    if tplGaugeInfo.GAS_PAY_CONDITION = 1 then
      -- Si Condition de paiement pas initialisée, utiliser la Condition de paiement du tiers
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID  :=
                                                                        nvl(tplGaugeInfo.PAC_PAYMENT_CONDITION_ID, tplPartnerInfo_ACI.PAC_PAYMENT_CONDITION_ID);
      end if;
    else
      -- Pas de Condition de paiement gérée au niveau du gabarit
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAYMENT_CONDITION_ID  := null;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID    := 1;

    -- Recherche de la monnaie du document si USE_DOC_CURRENCY = 0
    -- ou bien si USE_DOC_CURRENCY = 1 et que la monnaie est renseignée mais pas le cours
    if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY = 0)
       or (    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY = 1
           and DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID is not null
           and DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_BASE_PRICE is null
           and DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_OF_EXCHANGE is null
           and DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_EURO is null
          ) then
      -- La monnaie n'a pas été initialisée par l'utilisateur
      if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY = 0) then
        -- Monnaie du tiers de facturation
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID is not null then
          -- Recherche la monnaie du tiers
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  :=
            DOC_DOCUMENT_FUNCTIONS.GetThirdCurrencyID(DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID);
        else   -- Document sans tiers, Monnaie document := Monaie locale
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := LocalCurrencyID;
        end if;
      end if;

      -- Recherche du cours
      NumTmp                                                 :=
        Acs_Function.GetRateOfExchangeEUR(DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID
                                        , 1   /* Cours du jour */
                                        , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT
                                        , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_OF_EXCHANGE
                                        , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_BASE_PRICE
                                        , BaseChange
                                        , RateExchangeEUR_ME
                                        , FixedRateEUR_ME
                                        , RateExchangeEUR_MB
                                        , FixedRateEUR_MB
                                        , 1
                                         );

      /* Si le cours est en monnaie étrangère, alors il faut le convertir en monnaie base */
      if BaseChange = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_OF_EXCHANGE  :=
          ( (DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_BASE_PRICE * DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_BASE_PRICE) /
           DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_OF_EXCHANGE
          );
      end if;

      -- Si la monnaie du document fait partie de la monnaie EURO
      if FixedRateEUR_ME = 1 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_EURO  := RateExchangeEUR_ME;
      else
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_EURO  := 0;
      end if;

      -- Lorsqu'appelé en initialisation
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY  := 1;
    end if;

    -- Si Méthode de paiement pas initialisée, utiliser la Méthode de paiement du partenaire facturation OU gabarit
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_FIN_ACC_S_PAYMENT_ID = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_FIN_ACC_S_PAYMENT_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FIN_ACC_S_PAYMENT_ID      :=
                                                                        nvl(tplPartnerInfo_ACI.ACS_FIN_ACC_S_PAYMENT_ID, tplGaugeInfo.ACS_FIN_ACC_S_PAYMENT_ID);
    end if;

    -- Gabarit gére la Référence financière
    if tplGaugeInfo.GAS_FINANCIAL_REF = 1 then
      -- Si Référence financière pas initialisée, utiliser la Référence financière du tiers
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_FINANCIAL_REFERENCE_ID = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_FINANCIAL_REFERENCE_ID  :=
          ACS_I_LIB_LOGISTIC_FINANCIAL.GetFinancialReference(iThirdID         => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID
                                                           , iAdminDomain     => tplGaugeInfo.C_ADMIN_DOMAIN
                                                           , iDocCurrencyID   => DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID
                                                           , iPayMethodID     => DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FIN_ACC_S_PAYMENT_ID
                                                            );
      end if;
    else
      -- Pas de Référence financière gérée au niveau du gabarit
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_FINANCIAL_REFERENCE_ID  := null;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_FINANCIAL_REFERENCE_ID  := 1;

    -- Si Tarif pas initialisé, utiliser le Tarif du partenaire de tarification
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TARIFF_ID = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TARIFF_ID  := 1;

      select max(case
                   when tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then SUP.DIC_TARIFF_ID
                   when tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') then CUS.DIC_TARIFF_ID
                   else nvl(CUS.DIC_TARIFF_ID, SUP.DIC_TARIFF_ID)
                 end
                ) DIC_TARIFF_ID
        into DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TARIFF_ID
        from PAC_THIRD THI
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where THI.PAC_THIRD_ID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_TARIFF_ID
         and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
         and CUS.C_PARTNER_STATUS(+) = '1'
         and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
         and SUP.C_PARTNER_STATUS(+) = '1';
    end if;

    -- Document avec TVA
    if tplGaugeInfo.GAS_VAT = 1 then
      -- Document avec réf. partenaire -> Utilisation du décompte du tiers
      if tplGaugeInfo.GAU_REF_PARTNER = 1 then
        -- Si Type de soumission pas initialisé, utiliser le Type de soumission du tiers
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_SUBMISSION_ID = 0 then
          -- Tiers de réf. TVA = C_GAU_THIRD_VAT
          -- 1 = Partenaire Donneur d'ordre
          -- 2 = Partenaire livraison
          -- 3 = Partenaire facturation
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_SUBMISSION_ID  := 1;

          -- 1 = Partenaire Donneur d'ordre
          if tplGaugeInfo.C_GAU_THIRD_VAT = 1 then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID  := tplPartnerInfo.DIC_TYPE_SUBMISSION_ID;
          -- 2 = Partenaire livraison
          elsif tplGaugeInfo.C_GAU_THIRD_VAT = 2 then
            if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is not null then
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID  := tplPartnerInfo_DELIVERY.DIC_TYPE_SUBMISSION_ID;
            else
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID  := null;

              -- Si Domaine Achat ou Sous-Traitance, utiliser type soumission du donneur d'ordre
              if tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then
                DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID  := tplPartnerInfo.DIC_TYPE_SUBMISSION_ID;
              end if;
            end if;
          -- 3 = Partenaire facturation
          elsif tplGaugeInfo.C_GAU_THIRD_VAT = 3 then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID  := tplPartnerInfo_ACI.DIC_TYPE_SUBMISSION_ID;
          end if;
        end if;

        -- Si Décompte TVA pas initialisé, utiliser le Décompte TVA du tiers
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_VAT_DET_ACCOUNT_ID = 0 then
          -- Tiers de réf. TVA = C_GAU_THIRD_VAT
          -- 1 = Partenaire Donneur d'ordre
          -- 2 = Partenaire livraison
          -- 3 = Partenaire facturation
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_VAT_DET_ACCOUNT_ID  := 1;

          -- 1 = Partenaire Donneur d'ordre
          if tplGaugeInfo.C_GAU_THIRD_VAT = 1 then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID  := tplPartnerInfo.ACS_VAT_DET_ACCOUNT_ID;
          -- 2 = Partenaire livraison
          elsif tplGaugeInfo.C_GAU_THIRD_VAT = 2 then
            if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is not null then
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID  := tplPartnerInfo_DELIVERY.ACS_VAT_DET_ACCOUNT_ID;
            else
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID  := null;

              -- Si Domaine Achat ou Sous-Traitance, utiliser décompte TVA du donneur d'ordre
              if tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then
                DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID  := tplPartnerInfo.ACS_VAT_DET_ACCOUNT_ID;
              end if;
            end if;
          -- 3 = Partenaire facturation
          elsif tplGaugeInfo.C_GAU_THIRD_VAT = 3 then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID  := tplPartnerInfo_ACI.ACS_VAT_DET_ACCOUNT_ID;
          end if;
        end if;

        -- Recherche de la monnaie TVA
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_VAT_CURRENCY = 0 then
          -- Tiers de réf. TVA = C_GAU_THIRD_VAT
          -- 1 = Partenaire Donneur d'ordre
          -- 2 = Partenaire livraison
          -- 3 = Partenaire facturation
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_VAT_CURRENCY       := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE     := null;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE  := null;

          -- 1 = Partenaire Donneur d'ordre
          if tplGaugeInfo.C_GAU_THIRD_VAT = 1 then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID  := tplPartnerInfo.VAT_CURRENCY_ID;
          -- 2 = Partenaire livraison
          elsif tplGaugeInfo.C_GAU_THIRD_VAT = 2 then
            if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is not null then
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID  := tplPartnerInfo_DELIVERY.VAT_CURRENCY_ID;
            else
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID  := null;

              -- Si Domaine Achat ou Sous-Traitance, utiliser Monnaie TVA du donneur d'ordre
              if tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then
                DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID  := tplPartnerInfo.VAT_CURRENCY_ID;
              end if;
            end if;
          -- 3 = Partenaire facturation
          elsif tplGaugeInfo.C_GAU_THIRD_VAT = 3 then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID  := tplPartnerInfo_ACI.VAT_CURRENCY_ID;
          end if;
        end if;
      else
        -- Pas de réf. partenaire

        -- Si Type de soumission pas initialisé,
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_SUBMISSION_ID = 0 then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_SUBMISSION_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID      := PCS.PC_CONFIG.GETCONFIG('DOC_DefltTYPE_SUBMISSION');
        end if;

        -- Recherche décompte TVA par défaut de la société
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_VAT_DET_ACCOUNT_ID = 0 then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACS_VAT_DET_ACCOUNT_ID  := 1;

          -- Recherche décompte TVA par défaut de la société
          select ACS_VAT_DET_ACCOUNT_ID
            into DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID
            from ACS_VAT_DET_ACCOUNT
           where VDE_DEFAULT = 1;
        end if;

        -- Recherche de la monnaie TVA
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_VAT_CURRENCY = 0 then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_VAT_CURRENCY  := 1;

          -- Recherche la monnaie TVA du décompte TVA par défaut de la société
          select ACS_FINANCIAL_CURRENCY_ID
               , null
               , null
            into DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID
               , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE
               , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE
            from ACS_VAT_DET_ACCOUNT
           where VDE_DEFAULT = 1;
        end if;
      end if;

      -- Recherche du cours de la monnaie TVA si USE_VAT_CURRENCY = 0
      -- ou bien que USE_VAT_CURRENCY = 1 que la monnaie TVA est renseignée mais pas le cours
      if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_VAT_CURRENCY = 0)
         or (    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_VAT_CURRENCY = 1
             and DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID is not null
             and DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE is null
             and DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE is null
            ) then
        -- Si les monnaies sont comme l'ex:
        --   Monnaie de base   CHF
        --   Monnaie document  EUR
        --   Monnaie TVA       CHF
        -- Alors le cours de la monnaie TVA doit être le cours TVA entre la monnaie TVA et la monnaie du Doc
        if     (LocalCurrencyID = DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID)
           and (LocalCurrencyID <> DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID) then
          NumTmp  :=
            Acs_Function.GetRateOfExchangeEUR
                                            (DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID   -- Recherche cours entre Monnaie Doc et Monnaie TVA
                                           , 6   -- Cours TVA
                                           , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT
                                           , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE
                                           , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE
                                           , VATBaseChange
                                           , VATRateExchangeEUR_ME
                                           , VATFixedRateEUR_ME
                                           , VATRateExchangeEUR_MB
                                           , VATFixedRateEUR_MB
                                           , 1
                                            );

          -- Si le cours est en monnaie étrangère, alors il faut le convertir en monnaie base
          if VATBaseChange = 0 then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE  :=
              ( (DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE * DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE) /
               DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE
              );
          end if;
        else   -- Recherche cours TVA de la monnaie TVA par rapport à la monnaie de base
          NumTmp  :=
            Acs_Function.GetRateOfExchangeEUR(DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID
                                            , 6   -- Cours TVA
                                            , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT
                                            , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE
                                            , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE
                                            , VATBaseChange
                                            , VATRateExchangeEUR_ME
                                            , VATFixedRateEUR_ME
                                            , VATRateExchangeEUR_MB
                                            , VATFixedRateEUR_MB
                                            , 1
                                             );

          -- Si le cours est en monnaie étrangère, alors il faut le convertir en monnaie base
          if VATBaseChange = 0 then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE  :=
              ( (DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE * DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE) /
               DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE
              );
          end if;
        end if;
      end if;
    else   -- Document sans TVA
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_SUBMISSION_ID         := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_VAT_DET_ACCOUNT_ID         := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_ACS_FINANCIAL_CURRENCY_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_EXCHANGE_RATE          := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_VAT_BASE_PRICE             := null;
    end if;

    if tplGaugeInfo.GAU_DOSSIER = 1 then
      -- Initialisation du dossier si USE_DOC_RECORD_ID = 0
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID = 0 then
        vRecordId  :=
          Doc_Record_Management.CreateRecord(aGaugeId            => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                           , aGaugeName          => ''
                                           , aRecordId           => null
                                           , aThirdId            => DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                           , aDocumentId         => null
                                           , aDocNumber          => DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NUMBER
                                           , aLinkRecord         => vLinkRecord
                                           , aRecordCategoryId   => vRecordCategoryId
                                            );

        -- Lorsque la méthode CreateRecord n'a pas reussi à créer un dossier
        -- elle retourne la valeur -1 au lieu de NULL
        -- Il faut donc en tenir compte pour ne pas inserer la valeur -1 dans la table
        if     vLinkRecord = 1
           and vRecordId <> -1 then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_RECORD_ID  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID      := vRecordId;
        end if;
      end if;
    else
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID  := null;
    end if;

    if    tplGaugeInfo.GAS_FINANCIAL_CHARGE = 1
       or tplGaugeInfo.GAS_ANAL_CHARGE = 1
       or tplGaugeInfo.GAS_VISIBLE_COUNT = 1 then
      -- Recherche des comptes si USE_ACCOUNTS = 0
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACCOUNTS = 0 then
        DOC_DOCUMENT_FUNCTIONS.GetFinancialInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOCUMENT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_RECORD_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_DIVISION_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CPN_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CDA_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PF_ACCOUNT_ID
                                              , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PJ_ACCOUNT_ID
                                               );
      end if;

      ACS_I_LIB_LOGISTIC_FINANCIAL.CheckAccountPermission(DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_ACCOUNT_ID
                                                        , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_DIVISION_ACCOUNT_ID
                                                        , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CPN_ACCOUNT_ID
                                                        , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CDA_ACCOUNT_ID
                                                        , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PF_ACCOUNT_ID
                                                        , DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PJ_ACCOUNT_ID
                                                         );
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACCOUNTS  := 1;
    else
      if     tplGaugeInfo.GAS_FINANCIAL_CHARGE = 0
         and tplGaugeInfo.GAS_VISIBLE_COUNT = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_ACCOUNT_ID  := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_DIVISION_ACCOUNT_ID   := null;
      end if;

      if     tplGaugeInfo.GAS_ANAL_CHARGE = 0
         and tplGaugeInfo.GAS_VISIBLE_COUNT = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CPN_ACCOUNT_ID  := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_CDA_ACCOUNT_ID  := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PF_ACCOUNT_ID   := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_PJ_ACCOUNT_ID   := null;
      end if;
    end if;

    -- Si l'adresse 1 n'a pas été initialisée, Rechercher l'adresse
    if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_1 = 0) then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_1    := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_ADDRESS_ID   := vDOC_ADDRESS_INFO.PAC_ADDRESS_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_CNTRY_ID      := vDOC_ADDRESS_INFO.PC_CNTRY_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS1     := vDOC_ADDRESS_INFO.DMT_ADDRESS;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE1    := vDOC_ADDRESS_INFO.DMT_POSTCODE;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN1        := vDOC_ADDRESS_INFO.DMT_TOWN;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE1       := vDOC_ADDRESS_INFO.DMT_STATE;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME1        := vDOC_ADDRESS_INFO.DMT_NAME;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME1    := vDOC_ADDRESS_INFO.DMT_FORENAME;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY1    := vDOC_ADDRESS_INFO.DMT_ACTIVITY;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF1     := vDOC_ADDRESS_INFO.DMT_CARE_OF;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX1      := vDOC_ADDRESS_INFO.DMT_PO_BOX;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR1  := vDOC_ADDRESS_INFO.DMT_PO_BOX_NBR;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY1      := vDOC_ADDRESS_INFO.DMT_COUNTY;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT1     := vDOC_ADDRESS_INFO.DMT_CONTACT;
    -- la màj adresse formatée se fait dans le FinalizeDocument
    end if;

    -- Si l'adresse 2 n'a pas été initialisée, Rechercher l'adresse
    if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_2 = 0) then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_2       := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_PAC_ADDRESS_ID  := vDOC_ADDRESS_INFO_DELIVERY.PAC_ADDRESS_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_CNTRY_ID     := vDOC_ADDRESS_INFO_DELIVERY.PC_CNTRY_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS2        := vDOC_ADDRESS_INFO_DELIVERY.DMT_ADDRESS;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE2       := vDOC_ADDRESS_INFO_DELIVERY.DMT_POSTCODE;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN2           := vDOC_ADDRESS_INFO_DELIVERY.DMT_TOWN;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE2          := vDOC_ADDRESS_INFO_DELIVERY.DMT_STATE;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME2           := vDOC_ADDRESS_INFO_DELIVERY.DMT_NAME;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME2       := vDOC_ADDRESS_INFO_DELIVERY.DMT_FORENAME;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY2       := vDOC_ADDRESS_INFO_DELIVERY.DMT_ACTIVITY;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF2        := vDOC_ADDRESS_INFO_DELIVERY.DMT_CARE_OF;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX2         := vDOC_ADDRESS_INFO_DELIVERY.DMT_PO_BOX;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR2     := vDOC_ADDRESS_INFO_DELIVERY.DMT_PO_BOX_NBR;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY2         := vDOC_ADDRESS_INFO_DELIVERY.DMT_COUNTY;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT2        := vDOC_ADDRESS_INFO_DELIVERY.DMT_CONTACT;
    -- la màj adresse formatée se fait dans le FinalizeDocument
    end if;

    -- Si l'adresse 3 n'a pas été initialisée, Rechercher l'adresse
    if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_3 = 0) then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDRESS_3        := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC2_PAC_ADDRESS_ID  := vDOC_ADDRESS_INFO_ACI.PAC_ADDRESS_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_CNTRY_ID     := vDOC_ADDRESS_INFO_ACI.PC_CNTRY_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDRESS3         := vDOC_ADDRESS_INFO_ACI.DMT_ADDRESS;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_POSTCODE3        := vDOC_ADDRESS_INFO_ACI.DMT_POSTCODE;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TOWN3            := vDOC_ADDRESS_INFO_ACI.DMT_TOWN;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_STATE3           := vDOC_ADDRESS_INFO_ACI.DMT_STATE;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_NAME3            := vDOC_ADDRESS_INFO_ACI.DMT_NAME;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_FORENAME3        := vDOC_ADDRESS_INFO_ACI.DMT_FORENAME;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ACTIVITY3        := vDOC_ADDRESS_INFO_ACI.DMT_ACTIVITY;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CARE_OF3         := vDOC_ADDRESS_INFO_ACI.DMT_CARE_OF;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX3          := vDOC_ADDRESS_INFO_ACI.DMT_PO_BOX;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PO_BOX_NBR3      := vDOC_ADDRESS_INFO_ACI.DMT_PO_BOX_NBR;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_COUNTY3          := vDOC_ADDRESS_INFO_ACI.DMT_COUNTY;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CONTACT3         := vDOC_ADDRESS_INFO_ACI.DMT_CONTACT;
    -- la màj adresse formatée se fait dans le FinalizeDocument
    end if;

    -- Initialisation du champ "Texte de titre" s'il est nul
    if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TITLE_TEXT = 0)
       or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TITLE_TEXT is null) then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TITLE_TEXT  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC__PC_APPLTXT_ID   := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TITLE_TEXT      :=
                                         PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(tplGaugeInfo.PC__PC_APPLTXT_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID);
    end if;

    -- Initialisation du champ "Texte d'en-tête" si pas initialisé
    if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_HEADING_TEXT = 0) then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_HEADING_TEXT  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_APPLTXT_ID         := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_HEADING_TEXT      :=
                                             PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(tplGaugeInfo.PC_APPLTXT_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID);
    end if;

    -- Initialisation du champ "Texte de document" si pas initialisé
    if (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DOCUMENT_TEXT = 0) then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DOCUMENT_TEXT  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_2_PC_APPLTXT_ID     := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DOCUMENT_TEXT      :=
                                        PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(tplGaugeInfo.PC_2_PC_APPLTXT_ID, DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID);
    end if;

    -- Gabarit gére le Mode d'expédition
    if tplGaugeInfo.GAS_SENDING_CONDITION = 1 then
      -- Si Mode d'expédition pas initialisé, utiliser le Mode d'expédition du tiers
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SENDING_CONDITION_ID = 0 then
        -- Domaine Achat ou Sous-traitance (1 ou 5) = Mode d'expédition du partenaire donneur d'ordre
        -- Domaine Vente ou SAV (2 ou 7) = Mode d'expédition du partenaire livraison
        select case
                 when tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then tplPartnerInfo.PAC_SENDING_CONDITION_ID
                 when tplGaugeInfo.C_ADMIN_DOMAIN in('2', '7') then tplPartnerInfo_DELIVERY.PAC_SENDING_CONDITION_ID
                 else nvl(tplPartnerInfo_DELIVERY.PAC_SENDING_CONDITION_ID, tplPartnerInfo.PAC_SENDING_CONDITION_ID)
               end
          into DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SENDING_CONDITION_ID
          from dual;
      end if;
    else
      -- Pas de Mode d'expédition géré au niveau du gabarit
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SENDING_CONDITION_ID  := null;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SENDING_CONDITION_ID    := 1;

    -- Gabarit gére les Incoterms
    if tplGaugeInfo.C_GAU_INCOTERMS <> 0 then
      -- Si Incoterms pas initialisé, utiliser les Incoterms du tiers
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_INCOTERMS = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS          := null;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE  := null;

        -- Incoterms = C_GAU_INCOTERMS
        -- 0 = Pas de gestion
        -- 1 = Partenaire donneur d'ordre
        -- 2 = Partenaire livraison
        -- 3 = Partenaire facturation

        -- 1 = Partenaire donneur d'ordre
        if tplGaugeInfo.C_GAU_INCOTERMS = 1 then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS          := tplPartnerInfo.C_INCOTERMS;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE  := tplPartnerInfo.INCOTERMS_PLACE;
        -- 2 = Partenaire livraison
        elsif tplGaugeInfo.C_GAU_INCOTERMS = 2 then
          if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is not null then
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS          := tplPartnerInfo_DELIVERY.C_INCOTERMS;
            DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE  := tplPartnerInfo_DELIVERY.INCOTERMS_PLACE;
          else
            -- Si Domaine Achat ou Sous-Traitance, utiliser les incoterms du donneur d'ordre
            if tplGaugeInfo.C_ADMIN_DOMAIN in('1', '5') then
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS          := tplPartnerInfo.C_INCOTERMS;
              DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE  := tplPartnerInfo.INCOTERMS_PLACE;
            end if;
          end if;
        -- 3 = Partenaire facturation
        elsif tplGaugeInfo.C_GAU_INCOTERMS = 3 then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS          := tplPartnerInfo_ACI.C_INCOTERMS;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE  := tplPartnerInfo_ACI.INCOTERMS_PLACE;
        end if;

        -- Forcer l'utilisation uniquement s'il y a une valeur (pour pouvoir utiliser la valeur par défaut définie sur le champ)
        if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS is not null)
           or (DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE is not null) then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_INCOTERMS  := 1;
        end if;
      end if;
    else
      -- Pas d' Incoterms gérés au niveau du gabarit
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_INCOTERMS        := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_INCOTERMS          := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_INCOTERMS_PLACE  := null;
    end if;

    -- Gabarit gére "Canal de distribution"
    if tplGaugeInfo.GAS_DISTRIBUTION_CHANNEL = 1 then
      -- Si "Canal de distribution" pas initialisé, utiliser celui du tiers
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_DIST_CHANNEL_ID = 0 then
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_DISTRIBUTION_CHANNEL_ID  := tplPartnerInfo_DELIVERY.PAC_DISTRIBUTION_CHANNEL_ID;
        else
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_DISTRIBUTION_CHANNEL_ID  := tplPartnerInfo.PAC_DISTRIBUTION_CHANNEL_ID;
        end if;
      end if;
    else
      -- "Canal de distribution" pas géré au niveau du gabarit
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_DISTRIBUTION_CHANNEL_ID  := null;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_DIST_CHANNEL_ID         := 1;

    -- Gabarit gére "Territoire de vente"
    if tplGaugeInfo.GAS_SALE_TERRITORY = 1 then
      -- Si "Territoire de vente" pas initialisé, utiliser celui du tiers
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SALE_TERRITORY_ID = 0 then
        if DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_DELIVERY_ID is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SALE_TERRITORY_ID  := tplPartnerInfo_DELIVERY.PAC_SALE_TERRITORY_ID;
        else
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SALE_TERRITORY_ID  := tplPartnerInfo.PAC_SALE_TERRITORY_ID;
        end if;
      end if;
    else
      -- "Territoire de vente" pas géré au niveau du gabarit
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_SALE_TERRITORY_ID  := null;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_SALE_TERRITORY_ID       := 1;

    -- Date de livraison
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_DELIVERY = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_DELIVERY  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DELIVERY      := null;
    end if;

    -- Si Date valeur pas initialisée, utiliser la date du document pour la date valeur
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE      := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DOCUMENT;
    end if;

    -- Si Date valeur pas initialisée, utiliser la date du document pour calculer la date d'écheance
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_FALLING_DUE = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_FALLING_DUE  := 1;

      if tplGaugeInfo.IS_GAUGE_STRUCTURED = 1 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_FALLING_DUE  := DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE + tplGaugeInfo.GAU_EXPIRY_NBR;
      else
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_FALLING_DUE  := trunc(sysdate) + tplGaugeInfo.GAU_EXPIRY_NBR;
      end if;
    end if;

    -- Coefficient en %
    if tplGaugeInfo.GAS_PCENT = 1 then
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_RATE_FACTOR = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_FACTOR  := 0;
      end if;
    else
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RATE_FACTOR  := 0;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_RATE_FACTOR             := 1;

    -- Type de livraison
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_C_DMT_DELIVERY_TYP = 0 then
      -- Reliquat du partenaire donneur d'ordre
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_C_DMT_DELIVERY_TYP  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DMT_DELIVERY_TYP      := tplPartnerInfo.C_DELIVERY_TYP;
    end if;

    -- Pré-saisie
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PRE_ENTRY = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PRE_ENTRY    := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PRE_ENTRY    := 0;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACT_DOCUMENT_ID  := null;
    end if;

    -- Avenant
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_CML_POSITION_ID = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_CML_POSITION_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.CML_POSITION_ID      := null;
    end if;

    -- Dossier de réparation
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ASA_RECORD_ID = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ASA_RECORD_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.ASA_RECORD_ID      := null;
    end if;

    -- N° document table interface
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DOI_NUMBER = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DOI_NUMBER  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DOI_NUMBER      := null;
    end if;

    -- N° document partenaire
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_NUMBER = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_NUMBER  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_NUMBER      := null;
    end if;

    -- Référence partenaire
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_REFERENCE = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_REFERENCE  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_REFERENCE      := null;
    end if;

    -- Date document partenaire
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_PARTNER_DOCUMENT  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_PARTNER_DOCUMENT      := null;
    end if;

    -- Référence du document
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_REFERENCE = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_REFERENCE  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_REFERENCE      := null;
    end if;

    -- Données libres du gabarit
    if     (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_GAUGE_FREE_DATA = 0)
       and (tplGaugeInfo.GAU_FREE_DATA_USE = 1) then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_GAUGE_FREE_DATA       := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_GAUGE_FREE_CODE_1_ID  := tplGaugeInfo.DIC_GAUGE_FREE_CODE_1_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_GAUGE_FREE_CODE_2_ID  := tplGaugeInfo.DIC_GAUGE_FREE_CODE_2_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_GAUGE_FREE_CODE_3_ID  := tplGaugeInfo.DIC_GAUGE_FREE_CODE_3_ID;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_NUMBER1      := tplGaugeInfo.GAU_FREE_NUMBER1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_NUMBER2      := tplGaugeInfo.GAU_FREE_NUMBER2;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_DATE1        := tplGaugeInfo.GAU_FREE_DATE1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_DATE2        := tplGaugeInfo.GAU_FREE_DATE2;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_BOOL1        := nvl(tplGaugeInfo.GAU_FREE_BOOL1, 0);
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_BOOL2        := nvl(tplGaugeInfo.GAU_FREE_BOOL2, 0);
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_TEXT_LONG    := tplGaugeInfo.GAU_FREE_TEXT_LONG;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_GAU_FREE_TEXT_SHORT   := tplGaugeInfo.GAU_FREE_TEXT_SHORT;
    end if;

    -- Dicos libres du document
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_POS_FREE_TABLE = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_POS_FREE_TABLE   := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_1_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_2_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_POS_FREE_TABLE_3_ID  := null;
    end if;

    -- Textes libres du document
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TEXT = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TEXT  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_1    := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_2    := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_TEXT_3    := null;
    end if;

    -- Numériques libres du document
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DECIMAL = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DECIMAL  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_1    := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_2    := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DECIMAL_3    := null;
    end if;

    -- Dates libres du document
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_1    := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_2    := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_3    := null;
    end if;

    -- Champs de gestion des poids matières précieuses
    if tplGaugeInfo.GAS_WEIGHT_MAT = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_CREATE_FOOT_MAT  := 0;   -- Matières pas gèrées
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RECALC_FOOT_MAT  := 0;
    else
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_RECALC_FOOT_MAT  := 0;
    end if;

    -- Regroupement comptable
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_GRP_KEY = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_GRP_KEY  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GRP_KEY      := null;
    end if;

    -- Date de modification de document
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_DATEMOD = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_DATEMOD  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_DATEMOD      := null;
    end if;

    -- ID utilisateur de la modification de document
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_IDMOD = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_IDMOD  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_IDMOD      := null;
    end if;

    -- Niveau
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_RECLEVEL = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_RECLEVEL  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_RECLEVEL      := null;
    end if;

    -- Statut du tuple
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_RECSTATUS = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_RECSTATUS  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_RECSTATUS      := null;
    end if;

    -- Confirmation
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_CONFIRM = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_A_CONFIRM  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.A_CONFIRM      := 0;
    end if;

    /**** Champs relatifs à la table DOC_FOOT ****/

    -- Le BVR n'est disponnible que sur les documents structurés
    if tplGaugeInfo.IS_GAUGE_STRUCTURED = 1 then
      -- Initialisation de la méthode de génération du BVR
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_C_BVR_GENERATION_METHOD = 0 then
        -- Initialisation de la méthode de génération BVR :
        --   1. Gabarit
        --   2. Tiers
        --   3. Par défaut -> '03'
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_BVR_GENERATION_METHOD  :=
                                                              nvl(tplGaugeInfo.C_BVR_GENERATION_METHOD, nvl(tplPartnerInfo_ACI.C_BVR_GENERATION_METHOD, '03') );
      end if;
    else
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_BVR_GENERATION_METHOD  := null;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_C_BVR_GENERATION_METHOD     := 1;

    -- Montant payé
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_PAID_AMOUNT = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_PAID_AMOUNT  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_PAID_AMOUNT      := 0;
    end if;

    -- Montant à rendre
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_RETURN_AMOUNT = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_RETURN_AMOUNT  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_RETURN_AMOUNT      := 0;
    end if;

    -- Signataire
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_GAUGE_SIGNATORY_ID = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_GAUGE_SIGNATORY_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_SIGNATORY_ID      := tplGaugeInfo.DOC_GAUGE_SIGNATORY_ID;
    end if;

    -- Signataire secondaire
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_DOC_GAUGE_SIGNATORY_ID = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_DOC_GAUGE_SIGNATORY_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_DOC_GAUGE_SIGNATORY_ID      := tplGaugeInfo.DOC_DOC_GAUGE_SIGNATORY_ID;
    end if;

    -- Réference BVR
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_REF_BVR_NUMBER = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_REF_BVR_NUMBER  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_REF_BVR_NUMBER      := null;
    end if;

    -- Emballage
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_PACKAGING = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_PACKAGING  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_PACKAGING      := null;
    end if;

    -- Marquage
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_MARKING = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_MARKING  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_MARKING      := null;
    end if;

    -- Mesure
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_MEASURE = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_MEASURE  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_MEASURE      := null;
    end if;

    -- Poids mesurés
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_TOTAL_WEIGHT_MEAS = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_TOTAL_WEIGHT_MEAS    := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_GROSS_WEIGHT_MEAS  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_TOTAL_NET_WEIGHT_MEAS    := null;
    end if;

    -- Type de décompte
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_DOC_CUSTOM_ID = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DIC_TYPE_DOC_CUSTOM_ID  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DIC_TYPE_DOC_CUSTOM_ID      := tplGaugeInfo.DIC_TYPE_DOC_CUSTOM_ID;
    end if;

    -- Direction
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_C_DIRECTION_NUMBER = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_C_DIRECTION_NUMBER  := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.C_DIRECTION_NUMBER      := tplGaugeInfo.C_DIRECTION_NUMBER;
    end if;

    -- Transaction paiement du modèle
    if tplGaugeInfo.GAS_CASH_REGISTER = 1 then
      if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACJ_JOB_TYPE_S_CAT_PMT_ID = 0 then
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACJ_JOB_TYPE_S_CAT_PMT_ID  := tplGaugeInfo.ACJ_JOB_TYPE_S_CAT_PMT_ID;
      end if;
    else
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACJ_JOB_TYPE_S_CAT_PMT_ID  := null;
    end if;

    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ACJ_JOB_TYPE_S_CAT_PMT_ID   := 1;

    -- Texte de pied 1
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT   := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC_APPLTXT_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT       :=
        PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(1
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                                                  )
                                            , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID
                                             );
    end if;

    -- Texte de pied 2
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT2 = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT2      := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC__PC_APPLTXT_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT2          :=
        PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(2
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                                                  )
                                            , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID
                                             );
    end if;

    -- Texte de pied 3
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT3 = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT3       := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC_2_PC_APPLTXT_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT3           :=
        PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(3
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                                                  )
                                            , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID
                                             );
    end if;

    -- Texte de pied 4
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT4 = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT4       := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC_3_PC_APPLTXT_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT4           :=
        PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(4
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                                                  )
                                            , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID
                                             );
    end if;

    -- Texte de pied 5
    if DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT5 = 0 then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT5       := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOOT_PC_4_PC_APPLTXT_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT5           :=
        PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(DOC_DOCUMENT_FUNCTIONS.GetFootTextId(5
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_GAUGE_ID
                                                                                 , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ID
                                                                                  )
                                            , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_LANG_ID
                                             );
    end if;

    -- Avenant de document si géré au niveau du gabarit
    if    (DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDENDUM = 0)
       or (tplGaugeInfo.GAS_ADDENDUM = 0) then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_ADDENDUM             := 1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_OF_DOC_ID   := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_SRC_DOC_ID  := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_INDEX       := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_NUMBER      := null;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_ADDENDUM_COMMENT     := null;
    end if;

    -- Données EBPP
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_EXCHANGE_SYSTEM_ID           := null;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_EBPP_REFERENCE_ID           := null;

    if (tplGaugeInfo.GAS_EBPP_REFERENCE = 1) then
      -- Recherche des références EBPP du partenaire facturation du document
      DOC_DOCUMENT_FUNCTIONS.getEBPPReferences(DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_THIRD_ACI_ID
                                             , DOC_DOCUMENT_INITIALIZE.DocumentInfo.COM_NAME_ACI
                                             , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PC_EXCHANGE_SYSTEM_ID
                                             , DOC_DOCUMENT_INITIALIZE.DocumentInfo.PAC_EBPP_REFERENCE_ID
                                              );
    end if;

    close crGaugeInfo;
  end ControlInitDocumentData;
end DOC_DOCUMENT_INITIALIZE;
