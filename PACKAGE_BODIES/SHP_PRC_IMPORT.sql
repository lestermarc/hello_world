--------------------------------------------------------
--  DDL for Package Body SHP_PRC_IMPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_PRC_IMPORT" 
as
  /**
  * function isProductProtocol
  * Description
  *   Indique si le fichier xml pass� en param s'agit bien d'un protocol de produits
  */
  function isProductProtocol(iXml in xmltype)
    return boolean
  is
    lbPdtProtocol boolean;
    lvType        varchar2(200);
  begin
    begin
      -- Lecture du type
      select extractvalue(iXml, '/protocol/vendor/type')
        into lvType
        from dual;

      -- Comparaison du type du fichier xml avec notre constante pour les produits "Items"
      lbPdtProtocol  :=     (lvType is not null)
                        and (lvType = SHP_LIB_TYPES.gcvCtProducts);
    exception
      when others then
        lbPdtProtocol  := false;
    end;

    return lbPdtProtocol;
  end isProductProtocol;

  /**
  * procedure ImportProductsProtocol
  * Description
  *    Cette effectue la lecture du protocol de retour du shop concernant les produits
  * @created NGV 23.05.2012
  * @lastUpdate age 06.09.2012
  * @public
  * @param iXml             : XML � traiter
  * @param oProductProtocol : Indique s'il s'agit d'un protocol de produits
  */
  procedure ImportProductsProtocol(iXml in xmltype, oProductProtocol out boolean)
  is
  begin
    -- V�rifier s'il s'agit d'un protocol de produits avant de traiter l'�l�ment xml
    oProductProtocol  := SHP_PRC_IMPORT.isProductProtocol(iXml => iXml);

    if oProductProtocol then
      -- Import des produits qui ont �t� trait�s par le shop avec succes
      for ltplPdt in (select   GOO.GCO_GOOD_ID
                             , GOO.GOO_MAJOR_REFERENCE
                          from GCO_GOOD GOO
                             , (select extractvalue(column_value, '/success/ref') GOOD_REF
                                  from table(xmlsequence(extract(iXml, '/protocol/successes/success') ) ) ) IMP
                         where IMP.GOOD_REF = GOO.GCO_GOOD_ID
                      order by GOO.GOO_MAJOR_REFERENCE) loop
        SHP_PRC_PUBLISH.updatePublishedElementStatus(inSppRecID        => ltplPdt.GCO_GOOD_ID
                                                   , ivSppContext      => SHP_LIB_TYPES.gcvCtxProduct
                                                   , ivElementStatus   => '01'
                                                   , ivErrorMessage    => null
                                                    );
      end loop;

      -- Import des produits qui ont �t� trait�s par le shop et qui sont en erreur
      for ltplPdt in (select   GOO.GCO_GOOD_ID
                             , GOO.GOO_MAJOR_REFERENCE
                             , substr(IMP.ERROR_MESSAGE, 1, 4000) as ERROR_MESSAGE
                          from GCO_GOOD GOO
                             , (select extractvalue(column_value, '/error/ref') GOOD_REF
                                     , extractvalue(column_value, '/error/message') ERROR_MESSAGE
                                  from table(xmlsequence(extract(iXml, '/protocol/errors/error') ) ) ) IMP
                         where IMP.GOOD_REF = GOO.GCO_GOOD_ID
                      order by GOO.GOO_MAJOR_REFERENCE) loop
        SHP_PRC_PUBLISH.updatePublishedElementStatus(inSppRecID        => ltplPdt.GCO_GOOD_ID
                                                   , ivSppContext      => SHP_LIB_TYPES.gcvCtxProduct
                                                   , ivElementStatus   => '02'
                                                   , ivErrorMessage    => ltplPdt.ERROR_MESSAGE
                                                    );
      end loop;
    end if;
  end ImportProductsProtocol;

  /**
  * Description
  *   Insertion dans DOC_INTERFACE/DOC_INTERFACE_POSITION des donn�es relatives
  *     au document transmis dans le fichier xml (format standard ProConcept ERP)
  */
  function InsertDocument(
    iXml                in xmltype
  , iOrigin             in DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  , iPcExchangeSystemID in PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type
  , iPcExchangeDataInID in PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type
  )
    return DOC_INTERFACE.DOC_INTERFACE_ID%type
  is
    ltplInterface          DOC_INTERFACE%rowtype;
    ltplInterfacePos       DOC_INTERFACE_POSITION%rowtype;
    lXmlPos                xmltype;
    lEcsProcLogIntegration pcs.PC_EXCHANGE_SYSTEM.ECS_PROC_LOG_INTEGRATION%type;
  begin
    -- insertion et initialisation du record doc_interface
    ltplInterface.DOC_INTERFACE_ID        := getNewID;
    ltplInterface.C_DOC_INTERFACE_ORIGIN  := iOrigin;
    ltplInterface.C_DOI_INTERFACE_STATUS  := '02';
    ltplInterface.DOI_ERROR               := 0;
    ltplInterface.DOI_PROTECTED           := 0;
    ltplInterface.PC_EXCHANGE_DATA_IN_ID  := iPcExchangeDataInID;
    ltplInterface.A_DATECRE               := sysdate;
    ltplInterface.A_IDCRE                 := PCS.PC_I_LIB_SESSION.GetUserIni;
    -- Extraction des donn�es ent�te
    DOC_I_PRC_INTERFACE.ExtractHeader(iXml => iXml, iotplInterface => ltplInterface);

    -- Report des modifications dans la base de donn�es
    insert into DOC_INTERFACE
         values ltplInterface;

    -- r�cup�ration du fragment de document contenant les positions
    select extract(iXml, '/DOCUMENT/POSITIONS')
      into lXmlPos
      from dual;

    -- traitement des positions
    for ltplPos in (select column_value XML_VALUE
                      from table(xmlsequence(extract(lXmlPos, '/POSITIONS/POSITION') ) ) ) loop
      ltplInterfacePos                            := null;
      ltplInterfacePos.DOC_INTERFACE_POSITION_ID  := getNewID;
      ltplInterfacePos.DOC_INTERFACE_ID           := ltplInterface.DOC_INTERFACE_ID;
      ltplInterfacePos.C_DOP_INTERFACE_STATUS     := '02';
      ltplInterfacePos.DOP_INCLUDE_TAX_TARIFF     := 0;
      ltplInterfacePos.DOP_NET_TARIFF             := 0;
      ltplInterfacePos.DOP_ERROR                  := 0;
      ltplInterfacePos.DOP_USE_GOOD_PRICE         := 1;
      ltplInterfacePos.A_DATECRE                  := sysdate;
      ltplInterfacePos.A_IDCRE                    := PCS.PC_I_LIB_SESSION.GetUserIni;
      -- extraction des donn�es position
      DOC_I_PRC_INTERFACE.ExtractPosition(iXml => ltplPos.XML_VALUE, itplInterface => ltplInterface, iotplInterfacePos => ltplInterfacePos);
      -- Garder une copie de la valeur re�ue du shop.
      ltplInterfacePos.DOP_POS_DECIMAL_1          := ltplInterfacePos.DOP_GROSS_UNIT_VALUE;

      if ltplPos.xml_value.existsnode('/POSITION/LOGISTICS_PART/POSITION_DETAILS/POSITION_DETAIL') > 0 then
        -- traitement des d�tails
        for ltplDetail in (select column_value XML_VALUE
                             from table(xmlsequence(extract(ltplPos.xml_value, '/POSITION/LOGISTICS_PART/POSITION_DETAILS/POSITION_DETAIL') ) ) ) loop
          -- extraction des donn�es d�tails
          DOC_I_PRC_INTERFACE.ExtractDetail(iXml => ltplDetail.xml_value, iotplInterfacePos => ltplInterfacePos);

          -- Report des modifications dans la base de donn�es
          insert into DOC_INTERFACE_POSITION
               values ltplInterfacePos;
        end loop;
      else
        -- Report des modifications dans la base de donn�es
        insert into DOC_INTERFACE_POSITION
             values ltplInterfacePos;
      end if;
    end loop;

    /* Recherche et ex�cution de la m�thode utilisateur pour l'int�gration des donn�es
       logistiques d�finie sur le syst�me d'�change de donn�es d�fini sur le tuple DOC_INTERFACE */
    lEcsProcLogIntegration                := pcs.PC_I_LIB_EXCHANGE_SYSTEM_UTL.GET_ECS_PROC_LOG_INTEGRATION(in_pc_exchange_system_id => iPcExchangeSystemID);

    if lEcsProcLogIntegration is null then
      /* Si la m�thode n'est pas d�finie, on l�ve une erreur */
      ra(PCS.PC_FUNCTIONS.translateWord('PCS - La proc�dure d int�gration des donn�es logistique n est pas d�finie dans le syst�me d echange de donn�es !') );
    else
      /* Ex�cution de la proc�dure utilisateur d'int�gration des donn�es logistique d�finie dans le syst�me d'�change de donn�es. */
      execute immediate 'begin ' || co.cLineBreak || '  ' || lEcsProcLogIntegration || '(:DOC_INTERFACE_ID, :RESET_DATA); ' || co.cLineBreak || 'end; '
                  using in ltplInterface.DOC_INTERFACE_ID, in 0;
    end if;

    return ltplInterface.DOC_INTERFACE_ID;
  end InsertDocument;

  /**
  * Description
  *    Conversion en ID des donn�es transmises en claire. S'occupe de la conversion des donn�es
  *    propres au Shop puis appel la proc�dure standard (DOC_I_PRC_INTERFACE.ConvertHeaderData)
  */
  procedure ConvertData(iDocInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type, iResetData in integer)
  as
    ltplInterface DOC_INTERFACE%rowtype;
  begin
    /* R�cup�ration du DOC_INTERFACE_ID courant */
    select *
      into ltplInterface
      from DOC_INTERFACE
     where DOC_INTERFACE_ID = iDocInterfaceID;

    /* R�cup�ration du tiers donneur d'ordre (PAC_THIRD_ID). */
    ltplInterface.PAC_THIRD_ID  := SHP_LIB_USER.getCustomPartnerID(iWebUserID => ltplInterface.DOI_PER_KEY1);

    /* R�cup�ration de l'ID du tiers de livraison si transmis (PAC_THIRD_DELIVERY_ID). */
    if ltplInterface.DOI_ADD2_PER_KEY1 is not null then
      ltplInterface.PAC_THIRD_DELIVERY_ID  := SHP_LIB_USER.getCustomPartnerID(iWebUserID => ltplInterface.DOI_ADD2_PER_KEY1);
    end if;

    /* R�cup�ration de l'ID du tiers de facturation si transmis (PAC_THIRD_ACI_ID). */
    if ltplInterface.DOI_ADD3_PER_KEY1 is not null then
      ltplInterface.PAC_THIRD_ACI_ID  := SHP_LIB_USER.getCustomPartnerID(iWebUserID => ltplInterface.DOI_ADD3_PER_KEY1);
    end if;

    /* Conversion en ID des donn�es transmises en claire. */
    DOC_I_PRC_INTERFACE.ConvertHeaderData(iotplInterface => ltplInterface, iOrigin => ltplInterface.C_DOC_INTERFACE_ORIGIN);

    /* Report des modifications dans la base de donn�es */
    update DOC_INTERFACE
       set row = ltplInterface
     where DOC_INTERFACE_ID = ltplInterface.DOC_INTERFACE_ID;
  end ConvertData;
end SHP_PRC_IMPORT;
