--------------------------------------------------------
--  DDL for Package Body DOC_EDI_EXPOVIT_V1
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_EXPOVIT_V1" 
is
  function GetCountryCode(iCntryID PCS.PC_CNTRY.PC_CNTRY_ID%type)
    return PCS.PC_CNTRY.CNTID%type
  is
    lvResult PCS.PC_CNTRY.CNTID%type;
  begin
    select max(CNTID)
      into lvResult
      from PCS.PC_CNTRY
     where PC_CNTRY_ID = iCntryID;

    return lvResult;
  end GetCountryCode;

  procedure p_InitializeGoodsDeclaration(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    ltplDoc DOC_DOCUMENT%rowtype;
  begin
    -- Infos du document
    select *
      into ltplDoc
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = iDocumentID;

    gSending.sending.goodsDeclaration.traderDeclarationNumber       := init_id_seq.nextval;
    gSending.sending.goodsDeclaration.traderReference               := ltplDoc.DMT_NUMBER;
    -- Pays : Adresse de livraison, sinon adresse facturation
    gSending.sending.goodsDeclaration.deliveryDestination           := GetCountryCode(nvl(ltplDoc.PC__PC_CNTRY_ID, ltplDoc.PC_2_PC_CNTRY_ID) );

    -- Transport
    -- sending.goodsDeclaration.transportMeans.transportMode
    -- sending.goodsDeclaration.transportMeans.transportationCountry
    if ltplDoc.PAC_SENDING_CONDITION_ID is not null then
      begin
        select SEN.C_CONDITION_MODE
             , GetCountryCode(ADR.PC_CNTRY_ID)
          into gSending.sending.goodsDeclaration.transportMeans.transportMode
             , gSending.sending.goodsDeclaration.transportMeans.transportationCountry
          from PAC_SENDING_CONDITION SEN
             , PAC_ADDRESS ADR
         where SEN.PAC_SENDING_CONDITION_ID = ltplDoc.PAC_SENDING_CONDITION_ID
           and SEN.PAC_ADDRESS_ID = ADR.PAC_ADDRESS_ID(+);
      exception
        when no_data_found then
          gSending.sending.goodsDeclaration.transportMeans.transportMode          := null;
          gSending.sending.goodsDeclaration.transportMeans.transportationCountry  := null;
      end;
    end if;

    --
    -- gSending.sending.goodsDeclaration.containers           n'est pas possible pour un document
    -- gSending.sending.goodsDeclaration.specialMentions      n'est pas possible pour un document
    -- gSending.sending.goodsDeclaration.consignor            expéditeur, géré par Expovit (valeur par défaut)

    -- Partenaire de facturation
    begin
      select PER.PAC_PERSON_ID
           , substr(THI.THI_NO_TVA, 1, 20)
        into gSending.sending.goodsDeclaration.consignee.id
           , gSending.sending.goodsDeclaration.consignee.vatNumber
        from PAC_THIRD THI
           , PAC_PERSON PER
       where THI.PAC_THIRD_ID = ltplDoc.PAC_THIRD_ACI_ID
         and THI.PAC_THIRD_ID = PER.PAC_PERSON_ID;
    exception
      when no_data_found then
        gSending.sending.goodsDeclaration.consignee.id         := null;
        gSending.sending.goodsDeclaration.consignee.vatNumber  := null;
    end;

    gSending.sending.goodsDeclaration.consignee.name                := substr(ltplDoc.DMT_NAME3, 1, 35);
    gSending.sending.goodsDeclaration.consignee.street              := substr(extractline(ltplDoc.DMT_ADDRESS3, 1, chr(10) ), 1, 35);
    gSending.sending.goodsDeclaration.consignee.addressSupplement1  := substr(extractline(ltplDoc.DMT_ADDRESS3, 2, chr(10) ), 1, 35);
    gSending.sending.goodsDeclaration.consignee.addressSupplement2  := substr(extractline(ltplDoc.DMT_ADDRESS3, 3, chr(10) ), 1, 35);
    gSending.sending.goodsDeclaration.consignee.postalCode          := substr(ltplDoc.DMT_POSTCODE3, 1, 9);
    gSending.sending.goodsDeclaration.consignee.city                := substr(ltplDoc.DMT_TOWN3, 1, 35);
    gSending.sending.goodsDeclaration.consignee.country             := GetCountryCode(ltplDoc.PC_2_PC_CNTRY_ID);

    -- Partenaire de livraison
    if ltplDoc.PAC_THIRD_DELIVERY_ID is not null then
      begin
        select PER.PAC_PERSON_ID
             , substr(THI.THI_NO_TVA, 1, 20)
          into gSending.sending.goodsDeclaration.delivery.id
             , gSending.sending.goodsDeclaration.delivery.vatNumber
          from PAC_THIRD THI
             , PAC_PERSON PER
         where THI.PAC_THIRD_ID = ltplDoc.PAC_THIRD_DELIVERY_ID
           and THI.PAC_THIRD_ID = PER.PAC_PERSON_ID;
      exception
        when no_data_found then
          gSending.sending.goodsDeclaration.delivery.id         := null;
          gSending.sending.goodsDeclaration.delivery.vatNumber  := null;
      end;

      gSending.sending.goodsDeclaration.delivery.name                := substr(ltplDoc.DMT_NAME2, 1, 35);
      gSending.sending.goodsDeclaration.delivery.street              := substr(extractline(ltplDoc.DMT_ADDRESS2, 1, chr(10) ), 1, 35);
      gSending.sending.goodsDeclaration.delivery.addressSupplement1  := substr(extractline(ltplDoc.DMT_ADDRESS2, 2, chr(10) ), 1, 35);
      gSending.sending.goodsDeclaration.delivery.addressSupplement2  := substr(extractline(ltplDoc.DMT_ADDRESS2, 3, chr(10) ), 1, 35);
      gSending.sending.goodsDeclaration.delivery.postalCode          := substr(ltplDoc.DMT_POSTCODE2, 1, 9);
      gSending.sending.goodsDeclaration.delivery.city                := substr(ltplDoc.DMT_TOWN2, 1, 35);
      gSending.sending.goodsDeclaration.delivery.country             := GetCountryCode(ltplDoc.PC__PC_CNTRY_ID);

      -- Vérifier si l'adresse de livraison est indentique à l'adresse de facturation
      if    (gSending.sending.goodsDeclaration.delivery.id <> gSending.sending.goodsDeclaration.consignee.id)
         or (gSending.sending.goodsDeclaration.delivery.vatNumber <> gSending.sending.goodsDeclaration.consignee.vatNumber)
         or (gSending.sending.goodsDeclaration.delivery.name <> gSending.sending.goodsDeclaration.consignee.name)
         or (gSending.sending.goodsDeclaration.delivery.street <> gSending.sending.goodsDeclaration.consignee.street)
         or (gSending.sending.goodsDeclaration.delivery.addressSupplement1 <> gSending.sending.goodsDeclaration.consignee.addressSupplement1)
         or (gSending.sending.goodsDeclaration.delivery.addressSupplement2 <> gSending.sending.goodsDeclaration.consignee.addressSupplement2)
         or (gSending.sending.goodsDeclaration.delivery.postalCode <> gSending.sending.goodsDeclaration.consignee.postalCode)
         or (gSending.sending.goodsDeclaration.delivery.city <> gSending.sending.goodsDeclaration.consignee.city)
         or (gSending.sending.goodsDeclaration.delivery.country <> gSending.sending.goodsDeclaration.consignee.country) then
        gSending.sending.goodsDeclaration.delivery.enabled  := true;
      else
        gSending.sending.goodsDeclaration.delivery.enabled  := false;
      end if;
    else
      gSending.sending.goodsDeclaration.delivery.enabled             := false;
      gSending.sending.goodsDeclaration.delivery.id                  := gSending.sending.goodsDeclaration.consignee.id;
      gSending.sending.goodsDeclaration.delivery.vatNumber           := gSending.sending.goodsDeclaration.consignee.vatNumber;
      gSending.sending.goodsDeclaration.delivery.name                := gSending.sending.goodsDeclaration.consignee.name;
      gSending.sending.goodsDeclaration.delivery.street              := gSending.sending.goodsDeclaration.consignee.street;
      gSending.sending.goodsDeclaration.delivery.addressSupplement1  := gSending.sending.goodsDeclaration.consignee.addressSupplement1;
      gSending.sending.goodsDeclaration.delivery.addressSupplement2  := gSending.sending.goodsDeclaration.consignee.addressSupplement2;
      gSending.sending.goodsDeclaration.delivery.postalCode          := gSending.sending.goodsDeclaration.consignee.postalCode;
      gSending.sending.goodsDeclaration.delivery.city                := gSending.sending.goodsDeclaration.consignee.city;
      gSending.sending.goodsDeclaration.delivery.country             := gSending.sending.goodsDeclaration.consignee.country;
    end if;

    -- Transporteur
    declare
      lnPersonID  PAC_PERSON.PAC_PERSON_ID%type;
      lnAddressID PAC_ADDRESS.PAC_ADDRESS_ID%type;
    begin
      select PER.PAC_PERSON_ID
           , substr(PER.PER_NAME, 1, 35)
           , substr(extractline(ADR.ADD_ADDRESS1, 1, chr(10) ), 1, 35)
           , substr(extractline(ADR.ADD_ADDRESS1, 2, chr(10) ), 1, 35)
           , substr(extractline(ADR.ADD_ADDRESS1, 3, chr(10) ), 1, 35)
           , substr(ADR.ADD_ZIPCODE, 1, 9)
           , substr(ADR.ADD_CITY, 1, 35)
           , GetCountryCode(ADR.PC_CNTRY_ID)
           , PER.PAC_PERSON_ID
           , ADR.PAC_ADDRESS_ID
        into gSending.sending.goodsDeclaration.carrier.id
           , gSending.sending.goodsDeclaration.carrier.name
           , gSending.sending.goodsDeclaration.carrier.street
           , gSending.sending.goodsDeclaration.carrier.addressSupplement1
           , gSending.sending.goodsDeclaration.carrier.addressSupplement2
           , gSending.sending.goodsDeclaration.carrier.postalCode
           , gSending.sending.goodsDeclaration.carrier.city
           , gSending.sending.goodsDeclaration.carrier.country
           , lnPersonID
           , lnAddressID
        from PAC_SENDING_CONDITION SEN
           , PAC_ADDRESS ADR
           , PAC_PERSON PER
       where SEN.PAC_SENDING_CONDITION_ID = ltplDoc.PAC_SENDING_CONDITION_ID
         and SEN.PAC_ADDRESS_ID = ADR.PAC_ADDRESS_ID
         and ADR.PAC_PERSON_ID = PER.PAC_PERSON_ID;

      -- gSending.sending.goodsDeclaration.carrier.contact := null;
      -- gSending.sending.goodsDeclaration.carrier.phone  := null;

      -- Email de l'adresse
      if lnAddressID is not null then
        -- Email - recherche la communication contenant l'email (en premier celui spécifié comme préféré)
        select max(EMAIL)
          into gSending.sending.goodsDeclaration.carrier.email
          from (select   COM.COM_EXT_NUMBER as EMAIL
                    from DIC_COMMUNICATION_TYPE TYP
                       , PAC_COMMUNICATION COM
                   where COM.PAC_ADDRESS_ID = lnAddressID
                     and COM.DIC_COMMUNICATION_TYPE_ID = TYP.DIC_COMMUNICATION_TYPE_ID
                     and nvl(TYP.DCO_EMAIL, 0) = 1
                order by nvl(COM.COM_PREFERRED_CONTACT, 0) desc)
         where rownum = 1;
      end if;

      -- Si email est vide, Email du partenaire
      if gSending.sending.goodsDeclaration.carrier.email is null then
        -- Email - recherche la communication contenant l'email (en premier celui spécifié comme préféré)
        select max(EMAIL)
          into gSending.sending.goodsDeclaration.carrier.email
          from (select   COM.COM_EXT_NUMBER as EMAIL
                    from DIC_COMMUNICATION_TYPE TYP
                       , PAC_COMMUNICATION COM
                   where COM.PAC_PERSON_ID = lnPersonID
                     and COM.DIC_COMMUNICATION_TYPE_ID = TYP.DIC_COMMUNICATION_TYPE_ID
                     and nvl(TYP.DCO_EMAIL, 0) = 1
                order by nvl(COM.COM_PREFERRED_CONTACT, 0) desc)
         where rownum = 1;
      end if;
    exception
      when no_data_found then
        gSending.sending.goodsDeclaration.carrier.id                  := null;
        gSending.sending.goodsDeclaration.carrier.name                := null;
        gSending.sending.goodsDeclaration.carrier.street              := null;
        gSending.sending.goodsDeclaration.carrier.addressSupplement1  := null;
        gSending.sending.goodsDeclaration.carrier.addressSupplement2  := null;
        gSending.sending.goodsDeclaration.carrier.postalCode          := null;
        gSending.sending.goodsDeclaration.carrier.city                := null;
        gSending.sending.goodsDeclaration.carrier.country             := null;
        gSending.sending.goodsDeclaration.carrier.contact             := null;
        gSending.sending.goodsDeclaration.carrier.phone               := null;
        gSending.sending.goodsDeclaration.carrier.email               := null;
    end;

    gSending.sending.goodsDeclaration.business.incoterms            := ltplDoc.C_INCOTERMS;

    declare
      lvCurrency PCS.PC_CURR.CURRENCY%type;
    begin
      select upper(CURRENCY)
        into lvCurrency
        from ACS_FINANCIAL_CURRENCY FIN
           , PCS.PC_CURR CUR
       where FIN.ACS_FINANCIAL_CURRENCY_ID = ltplDoc.ACS_FINANCIAL_CURRENCY_ID
         and FIN.PC_CURR_ID = CUR.PC_CURR_ID;

      -- CHF
      if lvCurrency = 'CHF' then
        gSending.sending.goodsDeclaration.business.invoiceCurrency  := '1';
      -- EUR
      elsif lvCurrency = 'EUR' then
        gSending.sending.goodsDeclaration.business.invoiceCurrency  := '2';
      -- Pays de l'UE mais pas monnaie EUR
      --  Bulgarie      BGN
      --  Danemark      DKK
      --  Hongrie       HUF
      --  Letonnie      LVL
      --  Lituanie      LTL
      --  Pologne       PLN
      --  Rép. Tchèque  CZK
      --  Roumanie      RON
      --  Royaume-Uni   GBP
      --  Suède         SEK
      elsif lvCurrency in('BGN', 'DKK', 'HUF', 'LVL', 'LTL', 'PLN', 'CZK', 'RON', 'GBP', 'SEK') then
        gSending.sending.goodsDeclaration.business.invoiceCurrency  := '3';
      -- USD
      elsif lvCurrency = 'USD' then
        gSending.sending.goodsDeclaration.business.invoiceCurrency  := '4';
      -- Autres monnaies
      else
        gSending.sending.goodsDeclaration.business.invoiceCurrency  := '5';
      end if;
    end;
  end;

  procedure InitializeGoodsDeclaration(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iEdiTypeID doc_edi_type.doc_edi_type_id%type)
  is
    lvPackageName DOC_EDI_TYPE_PARAM.DEP_VALUE%type;
  begin
    -- recherche d'une procédure individualisée d'initialisation
    lvPackageName  :=
      nvl(DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE', iEdiTypeID)
        , DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE.INITIALIZEGOODSDECLARATION', iEdiTypeID) );

    if lvPackageName is not null then
      begin
        -- exécution de la procédure individualisée
        execute immediate 'begin' || chr(10) || '  ' || lvPackageName || '.InitializeGoodsDeclaration (:iDocumentID,:iEdiTypeID);' || chr(10) || 'end;'
                    using in iDocumentID, in iEdiTypeID;
      exception
        when others then
          raise_application_error(-20000, 'PCS - ' || lvPackageName || '.InitializeGoodsDeclaration [' || sqlerrm || ' ]');
      end;
    else
      p_InitializeGoodsDeclaration(iDocumentID);
    end if;
  end InitializeGoodsDeclaration;

  procedure p_InitializeItemList(iDocumentID in doc_document.doc_document_id%type)
  is
    cursor crCustomsElement(cGoodID GCO_GOOD.GCO_GOOD_ID%type, cCntryID PCS.PC_CNTRY.PC_CNTRY_ID%type)
    is
      select   CUS.*
          from GCO_CUSTOMS_ELEMENT CUS
         where CUS.GCO_GOOD_ID = cGoodID
           and CUS.C_CUSTOMS_ELEMENT_TYPE = 'EXPORT'
           and nvl(CUS.PC_CNTRY_ID, cCntryID) = cCntryID
      order by CUS.PC_CNTRY_ID nulls last;

    ltplCustomsElement crCustomsElement%rowtype;
    lnItemCount        integer;
    lnPermitCount      integer;
  begin
    for ltplPos in (select   nvl(DMT.PC__PC_CNTRY_ID, DMT.PC_2_PC_CNTRY_ID) PC_CNTRY_ID
                           , GOO.GOO_MAJOR_REFERENCE
                           , POS.GCO_GOOD_ID
                           , POS.POS_SHORT_DESCRIPTION
                           , cast(POS.POS_GROSS_WEIGHT as number(10, 1) ) as POS_GROSS_WEIGHT   -- Format Expovit -> Decimal(9, 1)
                           , cast(POS.POS_NET_WEIGHT as number(12, 3) ) as POS_NET_WEIGHT   -- Format Expovit -> Decimal(9, 3)
                           , cast(POS.POS_NET_VALUE_INCL_B as number(12, 2) ) as POS_NET_VALUE_INCL_B   -- Format Expovit -> Decimal(10, 2)
                           , POS.POS_FINAL_QUANTITY_SU
                        from DOC_DOCUMENT DMT
                           , DOC_POSITION POS
                           , GCO_GOOD GOO
                       where DMT.DOC_DOCUMENT_ID = iDocumentID
                         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                         and POS.C_GAUGE_TYPE_POS in('1', '7', '8', '9', '10')
                         and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                    order by POS.POS_NUMBER) loop
      open crCustomsElement(ltplPos.GCO_GOOD_ID, ltplPos.PC_CNTRY_ID);

      fetch crCustomsElement
       into ltplCustomsElement;

      close crCustomsElement;

      lnItemCount                                                                             := gSending.sending.itemlist.goodsItems.goodsItem.count + 1;
      gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).id                          := substr(ltplPos.GOO_MAJOR_REFERENCE, 1, 17);
      gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).goodsData.descriptionShort  := substr(ltplPos.POS_SHORT_DESCRIPTION, 1, 35);
      gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).goodsData.commodityCode     := substr(ltplCustomsElement.CUS_CUSTONS_POSITION, 1, 10);
      gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).goodsData.statisticalCode   := ltplCustomsElement.CUS_KEY_TARIFF;
      gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).goodsData.grossMass         := ltplPos.POS_GROSS_WEIGHT;
      gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).goodsData.netMass           := ltplPos.POS_NET_WEIGHT;
      gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).goodsData.commercialGood    := ltplCustomsElement.C_EDEC_COMMERCIAL_GOOD;
      gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).goodsData.statisticalValue  := ltplPos.POS_NET_VALUE_INCL_B;

      -- additionalUnit -> Decimal(9, 1)
      select cast(ltplPos.POS_FINAL_QUANTITY_SU * nvl(ltplCustomsElement.CUS_CONVERSION_FACTOR, 1) as number(10, 1) )
        into gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).goodsData.additionalUnit
        from dual;

      -- gSending.sending.itemlist.goodsItems.goodsItem (lnItemCount).producedDocuments;   n'est pas possible pour un document
      for ltplPermit in (select   *
                             from GCO_CUSTOMS_PERMIT
                            where GCO_CUSTOMS_ELEMENT_ID = ltplCustomsElement.GCO_CUSTOMS_ELEMENT_ID
                         order by DEP_PERMIT_NUMBER) loop
        lnPermitCount                                                                                                                :=
                                                               gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).permits.permitsList.permit.count + 1;
        gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).permits.permitsList.permit(lnPermitCount).permitNumber           :=
                                                                                                                                   ltplPermit.DEP_PERMIT_NUMBER;
        gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).permits.permitsList.permit(lnPermitCount).permitType             :=
                                                                                                                                  ltplPermit.C_EDEC_PERMIT_TYPE;
        gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).permits.permitsList.permit(lnPermitCount).permitAuthority        :=
                                                                                                                              ltplPermit.C_EDEC_PERMIT_AUTHORITY;
        gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).permits.permitsList.permit(lnPermitCount).issueDate              :=
                                                                                                                                      ltplPermit.DEP_ISSUE_DATE;
        gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).permits.permitsList.permit(lnPermitCount).additionalInformation  :=
                                                                                                                          ltplPermit.DEP_ADDITIONAL_INFORMATION;
      end loop;

      -- Ajouter le champ "Assujetis au permis"
      gSending.sending.itemlist.goodsItems.goodsItem(lnItemCount).permits.permitObligation    := ltplCustomsElement.C_EDEC_PERMIT_OBLIGATION;
    -- gSending.sending.itemlist.goodsItems.goodsItem (lnItemCount).nonCustomsLaws.nonCustomsLawObligation;    n'existe pas dans l'ERP
    -- gSending.sending.itemlist.goodsItems.goodsItem (lnItemCount).sensibleGoods;                             n'existe pas dans l'ERP
    -- gSending.sending.itemlist.goodsItems.goodsItem (lnItemCount).notifications;                             n'existe pas dans l'ERP
    -- gSending.sending.itemlist.goodsItems.goodsItem (lnItemCount).specialMentions;                           n'existe pas dans l'ERP
    -- gSending.sending.itemlist.goodsItems.goodsItem (lnItemCount).goodsItemDetail;                           n'existe pas dans l'ERP
    -- gSending.sending.itemlist.goodsItems.goodsItem (lnItemCount).repairAndRefinement;                       n'existe pas dans l'ERP
    end loop;
  end;

  procedure InitializeItemList(iDocumentID doc_document.doc_document_id%type, iEdiTypeID doc_edi_type.doc_edi_type_id%type)
  is
    lvPackageName DOC_EDI_TYPE_PARAM.DEP_VALUE%type;
  begin
    -- recherche d'une procédure individualisée d'initialisation
    lvPackageName  :=
            nvl(DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE', iEdiTypeID), DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE.INITIALIZEITEMLIST', iEdiTypeID) );

    if lvPackageName is not null then
      begin
        -- exécution de la procédure individualisée
        execute immediate 'begin' || chr(10) || '  ' || lvPackageName || '.InitializeItemList (:iDocumentID,:iEdiTypeID);' || chr(10) || 'end;'
                    using in iDocumentID, in iEdiTypeID;
      exception
        when others then
          raise_application_error(-20000, 'PCS - ' || lvPackageName || '.InitializeGoodsDeclaration [' || sqlerrm || ' ]');
      end;
    else
      p_InitializeItemList(iDocumentID);
    end if;
  end InitializeItemList;

  /**
   * function pCreateExportJob
   * Description
   *   Transfert du document xml dans le table données OUT (pc_exchange_data_out)
   */
  procedure p_CreateExportJob(
    iDocumentID   in doc_document.doc_document_id%type
  , iDocEdiTypeID in doc_edi_type.doc_edi_type_id%type
  , iFilename     in DOC_EDI_EXPORT_JOB.DIJ_FILENAME%type
  , iXML          in xmltype
  )
  is
    lvFilename   DOC_EDI_EXPORT_JOB.DIJ_FILENAME%type;
    lvEcsKey     pcs.pc_exchange_system.ecs_key%type;
    lrec_dataOut pcs.pc_lib_exchange_data_const.t_exchange_data_type;
  begin
    lvFilename    := iFilename;

    -- nom du fichier pour l'export
    select nvl(lvFilename, DMT.DMT_NUMBER || '.xml')
      into lvFilename
      from DOC_DOCUMENT DMT
     where DMT.DOC_DOCUMENT_ID = iDocumentID;

    -- système d'échange de données
    select ECS.ECS_KEY
      into lvEcsKey
      from DOC_EDI_TYPE DET
         , PCS.PC_EXCHANGE_SYSTEM ECS
     where DET.DOC_EDI_TYPE_ID = iDocEdiTypeID
       and DET.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID;

    -- Exportation du fichier
    lrec_dataOut  :=
          PCS.PC_MGT_EXCHANGE_DATA_OUT.open(iv_exchange_system_key   => lvEcsKey, iv_Filename => lvFilename, iv_destination_url => null
                                          , iv_file_encoding         => null);
    PCS.PC_MGT_EXCHANGE_DATA_OUT.put_xml_type(lrec_dataOut, iXML);
    PCS.PC_MGT_EXCHANGE_DATA_OUT.close(lrec_dataOut);
  end p_CreateExportJob;

  /**
  *
  */
  procedure CreateExportJob(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iEdiTypeID in DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type, iXML in xmltype)
  is
    lvFilename    varchar2(255);
    lvPackageName DOC_EDI_TYPE_PARAM.DEP_VALUE%type;
  begin
    -- recherche d'une procédure individualisée d'initialisation
    lvPackageName  :=
                   nvl(DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE', iEdiTypeID), DOC_EDI_FUNCTION.GetParamValue('EXPORT_PACKAGE.GETFILENAME', iEdiTypeID) );

    if lvPackageName is not null then
      begin
        -- exécution de la procédure individualisée
        execute immediate 'begin' || chr(10) || '  ' || lvPackageName || '.getFilename (:iDocumentID,:iEdiTypeID, :lvFilename);' || chr(10) || 'end;'
                    using in iDocumentID, in iEdiTypeID, out lvFilename;
      exception
        when others then
          raise_application_error(-20000, 'PCS - ' || lvPackageName || '.getFilename [' || sqlerrm || ' ]');
      end;
    end if;

    -- procédure standard
    p_CreateExportJob(iDocumentID, iEdiTypeID, lvFilename, iXML);
  end CreateExportJob;

  procedure GenerateExport(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lnEdiTypeID DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type;
    lxSending   xmltype;
  begin
    -- Rechercher le type Edi pour ExpoVit
    lnEdiTypeID  := DOC_EDI_FUNCTION.GetEdiTypeID;
    -- Effacement variable globale
    gSending     := null;
    -- Init des données
    InitializeGoodsDeclaration(iDocumentID, lnEdiTypeID);
    InitializeItemList(iDocumentID, lnEdiTypeID);
    -- Création du fichier XML
    lxSending    := DOC_EDI_EXPOVIT_FMT_V1.get_sending_xml(gSending);

    if (lxSending is not null) then
      CreateExportJob(iDocumentID, lnEdiTypeID, lxSending);
    end if;
  end generateExport;
end DOC_EDI_EXPOVIT_V1;
