--------------------------------------------------------
--  DDL for Package Body DOC_EDI_EDEC_ETRANS_TEMPLATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_EDEC_ETRANS_TEMPLATE" 
is
  /**
  * procedure InitializeData
  * Description
  *   Initialisation des données des éléments Master Data et Line Item
  *   en fonction de la déclaration EDEC passée en param
  */
  procedure InitializeData(
    aEdecHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aEdiTypeID    in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type
  )
  is
    tplHeader   DOC_EDEC_HEADER%rowtype;
    tplAddress1 DOC_EDEC_ADDRESSES%rowtype;
    tplAddress3 DOC_EDEC_ADDRESSES%rowtype;
    vIndex      number;

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

      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Consignee_Address.Line1         := tplAddress1.DEA_ADDRESS_SUPPLEMENT_1;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Consignee_Address.Line2         := tplAddress1.DEA_ADDRESS_SUPPLEMENT_2;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Consignee_Address.Country_Code  := GetCountryCode(tplAddress1.PC_CNTRY_ID);
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Consignee_Address.name          := tplAddress1.DEA_NAME;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Consignee_Address.Place         := tplAddress1.DEA_CITY;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Consignee_Address.Street        := tplAddress1.DEA_STREET;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Consignee_Address.Zip_Code      := tplAddress1.DEA_POSTAL_CODE;
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

      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Forwarder_Address.Line1         := tplAddress3.DEA_ADDRESS_SUPPLEMENT_1;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Forwarder_Address.Line2         := tplAddress3.DEA_ADDRESS_SUPPLEMENT_2;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Forwarder_Address.Country_Code  := GetCountryCode(tplAddress3.PC_CNTRY_ID);
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Forwarder_Address.name          := tplAddress3.DEA_NAME;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Forwarder_Address.Place         := tplAddress3.DEA_CITY;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Forwarder_Address.Street        := tplAddress3.DEA_STREET;
      DOC_EDI_EDEC_ETRANS_V1.vMasterData.Forwarder_Address.Zip_Code      := tplAddress3.DEA_POSTAL_CODE;
    exception
      when no_data_found then
        null;
    end;

    /* Master_Data */
    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Order_Number            := tplHeader.DEH_TRADER_DECLARATION_NUMBER;
    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Order_Date              := sysdate;
    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Forwarder_Name          :=
                                                               DOC_EDI_EDEC_ETRANS_V1.vMasterData.Forwarder_Address.name;
--    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Pickup_Date                  := null;   --date d'enlèvement (à voir) uniquement si pas transitaire
--    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Delivery_Date                := null;   --date de livraison souhaitée (transitaire)
--    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.collect                      := null;   --date d'enlèvement souhaitée si transitaire
    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Country_of_Destination  := GetCountryCode(tplAddress3.PC_CNTRY_ID);
    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Mode_of_Delivery        := tplHeader.C_EDEC_TRANSPORT_MODE;
    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Place_of_Destination    := tplAddress3.DEA_CITY;   --lieu de destination des marchandises
--    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Dangerous_Goods              := null;   --0 = pas dangeureux, 1 = dangeureux
    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Mode_of_Dispatch        := tplHeader.C_EDEC_TRANSPORT_MODE;
    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Incoterm                := tplHeader.C_INCOTERMS;
    DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Place_of_Incoterm       := tplHeader.DEH_PLACE_OF_LOADING;

    select substr(max(DMT_NUMBER), 1, 50)
      into DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Internal_Order_Number
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = tplHeader.DOC_DOCUMENT_ID;

    if DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Internal_Order_Number is null then
      select substr(max(PAL_NUMBER), 1, 50)
        into DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Internal_Order_Number
        from DOC_PACKING_LIST
       where DOC_PACKING_LIST_ID = tplHeader.DOC_PACKING_LIST_ID;
    end if;

    -- initialisation des données de lignes
    for tplLineItem in (select *
                          from DOC_EDEC_POSITION
                         where DOC_EDEC_HEADER_ID = aEdecHeaderId) loop
      vIndex                                                                      :=
                                                                          DOC_EDI_EDEC_ETRANS_V1.vtblLineItem.count + 1;
      /* DOC_EDI_EDEC_ETRANS_V1.vtblLineItem.Article */
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Article.Order_Number            :=
                                                                 DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Order_Number;
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Article.Country_of_Destination  :=
                                                       DOC_EDI_EDEC_ETRANS_V1.vMasterData.TOrder.Country_of_Destination;
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Article.Country_of_Origin       :=
                                                                     GetCountryCode(tplLineItem.DEP_ORIGIN_PC_CNTRY_ID);
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Article.Customs_Tariff_Number   := tplLineItem.DEP_COMMODITY_CODE;
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Article.Gross_Weight            := tplLineItem.DEP_GROSS_MASS;
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Article.Value_In_CHF            := tplLineItem.DEP_STATISTICAL_VALUE;   --valeur de la marchandise
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Article.key                     := tplLineItem.DEP_STATISTICAL_CODE;
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Article.Additional_Pieces       := tplLineItem.DEP_ADDITIONAL_UNIT;
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Article.Net_Weight              := tplLineItem.DEP_NET_MASS;
      /* DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Edec */
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Edec.eDec_Permit_Obligation     :=
                                                                                   tplLineItem.C_EDEC_PERMIT_OBLIGATION;
      DOC_EDI_EDEC_ETRANS_V1.vtblLineItem(vIndex).Edec.eDec_Commercial_Goods      := tplLineItem.C_EDEC_COMMERCIAL_GOOD;
    end loop;
  end InitializeData;
end DOC_EDI_EDEC_ETRANS_TEMPLATE;
