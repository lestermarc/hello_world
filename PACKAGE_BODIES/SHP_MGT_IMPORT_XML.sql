--------------------------------------------------------
--  DDL for Package Body SHP_MGT_IMPORT_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_MGT_IMPORT_XML" 
as
  procedure ImportDocuments(ivExchangeKey in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type)
  is
    ltDataFile          pcs.PC_LIB_EXCHANGE_DATA_CONST.t_exchange_data_type;
    lXmlDoc             xmltype;
    lnInterfaceID       DOC_INTERFACE.DOC_INTERFACE_ID%type;
    lPcExchangeSystemID PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type;
  begin
    /* Récupération de l'ID du système d'échange de données */
    lPcExchangeSystemID  := pcs.PC_I_LIB_EXCHANGE_SYSTEM_UTL.get_exchange_system_id(iv_ecs_key => ivExchangeKey);
    ltDataFile           := PCS.PC_MGT_EXCHANGE_DATA_IN.FindFirst(ivExchangeKey);

    while not ltDataFile.EoSearch loop
      /* ouverture du fichier importé */
      PCS.PC_MGT_EXCHANGE_DATA_IN.open(ltDataFile);
      lXmlDoc        := PCS.PC_MGT_EXCHANGE_DATA_IN.get_xml_type(ltDataFile);
      /* Ajout du document du xml dans le DOC_INTERFACE */
      lnInterfaceID  :=
        SHP_PRC_IMPORT.InsertDocument(iXml                  => lXmlDoc
                                    , iOrigin               => '401'
                                    , iPcExchangeSystemID   => lPcExchangeSystemID
                                    , iPcExchangeDataInID   => ltDataFile.exchange_data_id
                                     );
      /* fermeture du fichier importé */
      PCS.PC_MGT_EXCHANGE_DATA_IN.close(iorec_exchange_data       => ltDataFile
                                      , ib_delete_exchange_data   => (lnInterfaceID is not null)
                                      , ib_change_status          => (lnInterfaceID is not null)
                                       );
      /* récupération du prochain fichier */
      ltDataFile     := PCS.PC_MGT_EXCHANGE_DATA_IN.FindNext(ltDataFile);
    end loop;

    /* fermeture de la recherche */
    PCS.PC_MGT_EXCHANGE_DATA_IN.FindClose(ltDataFile);
  end ImportDocuments;

  /**
  * procedure ImportProductsProtocol
  * Description
  *   fonction transférant les données présentes dans le document XML
  *   contenant le résultat de l'import des produits chez le shop
  */
  procedure ImportProductsProtocol(ivExchangeKey in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type)
  is
    ltDataFile        pcs.pc_lib_exchange_data_const.t_exchange_data_type;
    lXmlPdt           xmltype;
    lbProductProtocol boolean;
  begin
    ltDataFile  := PCS.PC_MGT_EXCHANGE_DATA_IN.FindFirst(ivExchangeKey);

    while not ltDataFile.EoSearch loop
      /* ouverture du fichier importé */
      PCS.PC_MGT_EXCHANGE_DATA_IN.open(ltDataFile);
      lXmlPdt     := PCS.PC_MGT_EXCHANGE_DATA_IN.get_xml_type(ltDataFile);
      -- Import du protocol des données produit
      SHP_PRC_IMPORT.ImportProductsProtocol(iXml => lXmlPdt, oProductProtocol => lbProductProtocol);
      /* fermeture du fichier importé */
      PCS.PC_MGT_EXCHANGE_DATA_IN.close(iorec_exchange_data       => ltDataFile, ib_delete_exchange_data => lbProductProtocol
                                      , ib_change_status          => lbProductProtocol);
      /* récupération du prochain fichier */
      ltDataFile  := PCS.PC_MGT_EXCHANGE_DATA_IN.FindNext(ltDataFile);
    end loop;

    /* fermeture de la recherche */
    PCS.PC_MGT_EXCHANGE_DATA_IN.FindClose(ltDataFile);
  end ImportProductsProtocol;
end SHP_MGT_IMPORT_XML;
