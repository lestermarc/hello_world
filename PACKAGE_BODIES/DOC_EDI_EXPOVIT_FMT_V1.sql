--------------------------------------------------------
--  DDL for Package Body DOC_EDI_EXPOVIT_FMT_V1
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_EXPOVIT_FMT_V1" 
is
  function get_consignor_xml(irec_consignor t_consignor)
    return xmltype
  is
    lxt_consignor xmltype;
  begin
    select XMLElement("consignor"
                    , XMLElement("id", irec_consignor.id)
                    , XMLElement("name", irec_consignor.name)
                    , XMLElement("addressSupplement1", irec_consignor.addressSupplement1)
                    , XMLElement("addressSupplement2", irec_consignor.addressSupplement2)
                    , XMLElement("street", irec_consignor.street)
                    , XMLElement("postalCode", irec_consignor.postalCode)
                    , XMLElement("city", irec_consignor.city)
                    , XMLElement("country", irec_consignor.country)
                    , XMLElement("vatNumber", irec_consignor.vatNumber)
                    , XMLElement("email", irec_consignor.email)
                    , XMLElement("phone", irec_consignor.phone)
                    , XMLElement("tin", irec_consignor.tin)
                    , XMLElement("authorizationNumber", irec_consignor.authorizationNumber)
                     )
      into lxt_consignor
      from dual;

    return lxt_consignor;
  end;

  function get_consignee_xml(irec_consignee t_consignee)
    return xmltype
  is
    lxt_consignee xmltype;
  begin
    select XMLElement("consignee"
                    , XMLElement("id", irec_consignee.id)
                    , XMLElement("name", irec_consignee.name)
                    , XMLElement("addressSupplement1", irec_consignee.addressSupplement1)
                    , XMLElement("addressSupplement2", irec_consignee.addressSupplement2)
                    , XMLElement("street", irec_consignee.street)
                    , XMLElement("postalCode", irec_consignee.postalCode)
                    , XMLElement("city", irec_consignee.city)
                    , XMLElement("country", irec_consignee.country)
                    , XMLElement("vatNumber", irec_consignee.vatNumber)
                    , XMLElement("eoriNumber", irec_consignee.eori)
                     )
      into lxt_consignee
      from dual;

    return lxt_consignee;
  end;

  function get_delivery_xml(irec_delivery t_delivery)
    return xmltype
  is
    lxt_delivery xmltype;
    lvEnabled    varchar2(5);
  begin
    if irec_delivery.enabled then
      lvEnabled  := 'true';
    else
      lvEnabled  := 'false';
    end if;

    select XMLElement("delivery"
                    , XMLAttributes(lvEnabled as "enabled")
                    , XMLElement("id", irec_delivery.id)
                    , XMLElement("name", irec_delivery.name)
                    , XMLElement("addressSupplement1", irec_delivery.addressSupplement1)
                    , XMLElement("addressSupplement2", irec_delivery.addressSupplement2)
                    , XMLElement("street", irec_delivery.street)
                    , XMLElement("postalCode", irec_delivery.postalCode)
                    , XMLElement("city", irec_delivery.city)
                    , XMLElement("country", irec_delivery.country)
                    , XMLElement("vatNumber", irec_delivery.vatNumber)
                    , XMLElement("eoriNumber", irec_delivery.eori)
                     )
      into lxt_delivery
      from dual;

    return lxt_delivery;
  end;

  function get_carrier_xml(irec_carrier t_carrier)
    return xmltype
  is
    lxt_carrier xmltype;
  begin
    select XMLElement("carrier"
                    , XMLElement("id", irec_carrier.id)
                    , XMLElement("name", irec_carrier.name)
                    , XMLElement("addressSupplement1", irec_carrier.addressSupplement1)
                    , XMLElement("addressSupplement2", irec_carrier.addressSupplement2)
                    , XMLElement("street", irec_carrier.street)
                    , XMLElement("postalCode", irec_carrier.postalCode)
                    , XMLElement("city", irec_carrier.city)
                    , XMLElement("country", irec_carrier.country)
                    , XMLElement("contact", irec_carrier.contact)
                    , XMLElement("email", irec_carrier.email)
                    , XMLElement("phone", irec_carrier.phone)
                     )
      into lxt_carrier
      from dual;

    return lxt_carrier;
  end;

  function get_business_xml(irec_business t_business)
    return xmltype
  is
    lxt_business xmltype;
  begin
    select XMLElement("business"
                    , XMLElement("incoterms", irec_business.incoterms)
                    , XMLElement("companyNumberTaxpayer", irec_business.companyNumberTaxPayer)
                    , XMLElement("invoiceCurrency", irec_business.invoiceCurrency)
                     )
      into lxt_business
      from dual;

    return lxt_business;
  end;

  function get_transportMeans_xml(irec_transportMeans t_transportMeans)
    return xmltype
  is
    lxt_transportMeans xmltype;
  begin
    select XMLElement("transportMeans"
                    , XMLElement("transportMode", irec_transportMeans.transportMode)
                    , XMLElement("transportationCountry", irec_transportMeans.transportationCountry)
                     )
      into lxt_transportMeans
      from dual;

    return lxt_transportMeans;
  end;

  function get_container_xml(irec_container t_container)
    return xmltype
  is
    lxt_container xmltype;
  begin
    select XMLElement("Container", XMLElement("containerNumber", irec_container.containerNumber) )
      into lxt_container
      from dual;

    return lxt_container;
  end;

  function get_containers_xml(itbl_containers ttbl_containers)
    return xmltype
  is
    lxt_containers xmltype;
    lxt_container  xmltype;
  begin
    if itbl_containers.count > 0 then
      for ln_cpt in itbl_containers.first .. itbl_containers.last loop
        lxt_container  := get_container_xml(itbl_containers(ln_cpt) );

        select XMLConcat(lxt_containers, lxt_container)
          into lxt_containers
          from dual;
      end loop;
    end if;

    if lxt_containers is not null then
      select XMLElement("containers", lxt_containers)
        into lxt_containers
        from dual;
    end if;

    return lxt_containers;
  end;

  function get_specialMentionHeader_xml(irec_specialMention t_specialMention)
    return xmltype
  is
    lxt_specialMention xmltype;
  begin
    select XMLElement("SpecialMentionHeader", XMLElement("text", irec_specialMention.text) )
      into lxt_specialMention
      from dual;

    return lxt_specialMention;
  end;

  function get_specialMentionsHeader_xml(itbl_specialMentions ttbl_specialMentions)
    return xmltype
  is
    lxt_specialMentions xmltype;
    lxt_specialMention  xmltype;
  begin
    if itbl_specialMentions.count > 0 then
      for ln_cpt in itbl_specialMentions.first .. itbl_specialMentions.last loop
        lxt_specialMention  := get_specialMentionHeader_xml(itbl_specialMentions(ln_cpt) );

        select XMLConcat(lxt_specialMentions, lxt_specialMention)
          into lxt_specialMentions
          from dual;
      end loop;
    end if;

    if lxt_specialMentions is not null then
      select XMLElement("specialMentions", lxt_specialMentions)
        into lxt_specialMentions
        from dual;
    end if;

    return lxt_specialMentions;
  end;

  function get_goodsData_xml(irec_goodsData t_goodsData)
    return xmltype
  is
    lxt_goodsData xmltype;
  begin
    select XMLElement("goodsData"
                    , XMLElement("descriptionShort", irec_goodsData.descriptionShort)
                    , XMLElement("descriptionEn", irec_goodsData.descriptionEN)
                    , XMLElement("origin", irec_goodsData.origin)
                    , XMLElement("inEur", irec_goodsData.inEur)
                    , XMLElement("eurInvoices", irec_goodsData.eurInvoices)
                    , XMLElement("commodityCode", irec_goodsData.commodityCode)
                    , XMLElement("statisticalCode", irec_goodsData.statisticalCode)
                    , XMLElement("grossMass", irec_goodsData.grossMass)
                    , XMLElement("netMass", irec_goodsData.netMass)
                    , XMLElement("customsClearanceType", irec_goodsData.customsClearanceType)
                    , XMLElement("commercialGood", irec_goodsData.commercialGood)
                    , XMLElement("statisticalValue", irec_goodsData.statisticalValue)
                    , XMLElement("currency", irec_goodsData.currency)
                    , XMLElement("currencyRate", irec_goodsData.currencyRate)
                    , XMLElement("packagingType", irec_goodsData.packagingType)
                    , XMLElement("quantity", irec_goodsData.quantity)
                    , XMLElement("packagingReferenceNumber", irec_goodsData.packagingReferenceNumber)
                    , XMLElement("additionalUnit", irec_goodsData.additionalUnit)
                    , XMLElement("refundType", irec_goodsData.refundType)
                    , XMLElement("VOCQuantity", irec_goodsData.VOCQuantity)
                     )
      into lxt_goodsData
      from dual;

    return lxt_goodsData;
  end;

  function get_producedDocument_xml(irec_producedDocument t_producedDocument)
    return xmltype
  is
    lxt_producedDocument xmltype;
  begin
    select XMLElement("ProducedDocument"
                    , XMLElement("documentType", irec_producedDocument.documentType)
                    , XMLElement("documentReferenceNumber", irec_producedDocument.documentReferenceNumber)
                    , XMLElement("issueDate", irec_producedDocument.issueDate)
                    , XMLElement("additionalInformation", irec_producedDocument.additionalInformation)
                     )
      into lxt_producedDocument
      from dual;

    return lxt_producedDocument;
  end;

  function get_producedDocuments_xml(itbl_producedDocuments ttbl_producedDocuments)
    return xmltype
  is
    lxt_producedDocuments xmltype;
    lxt_producedDocument  xmltype;
  begin
    if itbl_producedDocuments.count > 0 then
      for ln_cpt in itbl_producedDocuments.first .. itbl_producedDocuments.last loop
        lxt_producedDocument  := get_producedDocument_xml(itbl_producedDocuments(ln_cpt) );

        select XMLConcat(lxt_producedDocuments, lxt_producedDocument)
          into lxt_producedDocuments
          from dual;
      end loop;
    end if;

    if lxt_producedDocuments is not null then
      select XMLElement("producedDocuments", lxt_producedDocuments)
        into lxt_producedDocuments
        from dual;
    end if;

    return lxt_producedDocuments;
  end;

  function get_permit_xml(irec_permit t_permit)
    return xmltype
  is
    lxt_permit xmltype;
  begin
    select XMLElement("Permit"
                    , XMLElement("permitNumber", irec_permit.permitNumber)
                    , XMLElement("permitType", irec_permit.permitType)
                    , XMLElement("permitAuthority", irec_permit.permitAuthority)
                    , XMLElement("issueDate", irec_permit.issueDate)
                    , XMLElement("additionalInformation", irec_permit.additionalInformation)
                     )
      into lxt_permit
      from dual;

    return lxt_permit;
  end;

  function get_permitsList_xml(itbl_permits ttbl_permits)
    return xmltype
  is
    lxt_permitsList xmltype;
    lxt_permit      xmltype;
  begin
    if itbl_permits.count > 0 then
      for ln_cpt in itbl_permits.first .. itbl_permits.last loop
        lxt_permit  := get_permit_xml(itbl_permits(ln_cpt) );

        select XMLConcat(lxt_permitsList, lxt_permit)
          into lxt_permitsList
          from dual;
      end loop;
    end if;

    if lxt_permitsList is not null then
      select XMLElement("permitList", lxt_permitsList)
        into lxt_permitsList
        from dual;
    end if;

    return lxt_permitsList;
  end;

  function get_permits(irec_permits t_permits)
    return xmltype
  is
    lxt_permits     xmltype;
    lxt_permitsList xmltype;
  begin
    lxt_permitsList  := get_permitsList_xml(irec_permits.permitsList.permit);

    if lxt_permitsList is not null then
      select XMLElement("permits", lxt_permitsList, XMLElement("permitObligation", irec_permits.permitObligation) )
        into lxt_permits
        from dual;
    end if;

    return lxt_permits;
  end;

  function get_nonCustomsLaw_xml(irec_nonCustomsLaw t_nonCustomsLaw)
    return xmltype
  is
    lxt_nonCustomsLaw xmltype;
  begin
    select XMLElement("NonCustomLaw", XMLElement("nonCustomLawType", irec_nonCustomsLaw.nonCustomLawType) )
      into lxt_nonCustomsLaw
      from dual;

    return lxt_nonCustomsLaw;
  end;

  function get_nonCustomsLawList_xml(itbl_nonCustomsLaws ttbl_nonCustomsLaw)
    return xmltype
  is
    lxt_nonCustomsLawList xmltype;
    lxt_nonCustomsLaw     xmltype;
  begin
    if itbl_nonCustomsLaws.count > 0 then
      for ln_cpt in itbl_nonCustomsLaws.first .. itbl_nonCustomsLaws.last loop
        lxt_nonCustomsLaw  := get_nonCustomsLaw_xml(itbl_nonCustomsLaws(ln_cpt) );

        select XMLConcat(lxt_nonCustomsLawList, lxt_nonCustomsLaw)
          into lxt_nonCustomsLawList
          from dual;
      end loop;
    end if;

    if lxt_nonCustomsLawList is not null then
      select XMLElement("nonCustomsLawList", lxt_nonCustomsLawList)
        into lxt_nonCustomsLawList
        from dual;
    end if;

    return lxt_nonCustomsLawList;
  end;

  function get_nonCustomLaws(irec_nonCustomsLaws t_nonCustomsLaws)
    return xmltype
  is
    lxt_nonCustomsLaw     xmltype;
    lxt_nonCustomsLawList xmltype;
  begin
    lxt_nonCustomsLawList  := get_nonCustomsLawList_xml(irec_nonCustomsLaws.nonCustomsLawList.nonCustomsLaw);

    if lxt_nonCustomsLawList is not null then
      select XMLElement("nonCustomLaws", XMLElement("nonCustomsLawObligation", irec_nonCustomsLaws.nonCustomsLawObligation), lxt_nonCustomsLawList)
        into lxt_nonCustomsLawList
        from dual;
    end if;

    return lxt_nonCustomsLawList;
  end;

  function get_SensibleGood_xml(irec_SensibleGood t_sensibleGood)
    return xmltype
  is
    lxt_SensibleGood xmltype;
  begin
    select XMLElement("SensibleGoods", XMLElement("type", irec_SensibleGood.type), XMLElement("weight", irec_SensibleGood.weight) )
      into lxt_SensibleGood
      from dual;

    return lxt_SensibleGood;
  end;

  function get_SensibleGoods_xml(itbl_sensibleGoods ttbl_sensibleGoods)
    return xmltype
  is
    lxt_sensibleGoods xmltype;
    lxt_sensibleGood  xmltype;
  begin
    if itbl_sensibleGoods.count > 0 then
      for ln_cpt in itbl_sensibleGoods.first .. itbl_sensibleGoods.last loop
        lxt_sensibleGood  := get_SensibleGood_xml(itbl_sensibleGoods(ln_cpt) );

        select XMLConcat(lxt_sensibleGoods, lxt_sensibleGood)
          into lxt_sensibleGoods
          from dual;
      end loop;
    end if;

    if lxt_sensibleGoods is not null then
      select XMLElement("sensibleGoods", lxt_sensibleGoods)
        into lxt_sensibleGoods
        from dual;
    end if;

    return lxt_sensibleGoods;
  end;

  function get_notification_xml(irec_notification t_notification)
    return xmltype
  is
    lxt_notification xmltype;
  begin
    select XMLElement("Notification", XMLElement("notificationCode", irec_notification.notificationCode) )
      into lxt_notification
      from dual;

    return lxt_notification;
  end;

  function get_notifications_xml(itbl_notifications ttbl_notifications)
    return xmltype
  is
    lxt_notifications xmltype;
    lxt_notification  xmltype;
  begin
    if itbl_notifications.count > 0 then
      for ln_cpt in itbl_notifications.first .. itbl_notifications.last loop
        lxt_notification  := get_notification_xml(itbl_notifications(ln_cpt) );

        select XMLConcat(lxt_notifications, lxt_notification)
          into lxt_notifications
          from dual;
      end loop;
    end if;

    if lxt_notifications is not null then
      select XMLElement("notifications", lxt_notifications)
        into lxt_notifications
        from dual;
    end if;

    return lxt_notifications;
  end;

  function get_specialMentionItem_xml(irec_specialMention t_specialMention)
    return xmltype
  is
    lxt_specialMention xmltype;
  begin
    select XMLElement("SpecialMention", XMLElement("text", irec_specialMention.text) )
      into lxt_specialMention
      from dual;

    return lxt_specialMention;
  end;

  function get_specialMentionsItem_xml(itbl_specialMentions ttbl_specialMentions)
    return xmltype
  is
    lxt_specialMentions xmltype;
    lxt_specialMention  xmltype;
  begin
    if itbl_specialMentions.count > 0 then
      for ln_cpt in itbl_specialMentions.first .. itbl_specialMentions.last loop
        lxt_specialMention  := get_specialMentionItem_xml(itbl_specialMentions(ln_cpt) );

        select XMLConcat(lxt_specialMentions, lxt_specialMention)
          into lxt_specialMentions
          from dual;
      end loop;
    end if;

    if lxt_specialMentions is not null then
      select XMLElement("specialMentions", lxt_specialMentions)
        into lxt_specialMentions
        from dual;
    end if;

    return lxt_specialMentions;
  end;

  function get_goodsItemDetail_xml(irec_goodsItemDetail t_goodsItemDetail)
    return xmltype
  is
    lxt_goodsItemDetail xmltype;
  begin
    select XMLElement("GoodsItemDetail", XMLElement("name", irec_goodsItemDetail.name), XMLElement("value", irec_goodsItemDetail.value) )
      into lxt_goodsItemDetail
      from dual;

    return lxt_goodsItemDetail;
  end;

  function get_goodsItemDetails_xml(itbl_goodsItemDetails ttbl_goodsItemDetail)
    return xmltype
  is
    lxt_goodsItemDetails xmltype;
    lxt_goodsItemDetail  xmltype;
  begin
    if itbl_goodsItemDetails.count > 0 then
      for ln_cpt in itbl_goodsItemDetails.first .. itbl_goodsItemDetails.last loop
        lxt_goodsItemDetail  := get_goodsItemDetail_xml(itbl_goodsItemDetails(ln_cpt) );

        select XMLConcat(lxt_goodsItemDetails, lxt_goodsItemDetail)
          into lxt_goodsItemDetails
          from dual;
      end loop;
    end if;

    if lxt_goodsItemDetails is not null then
      select XMLElement("goodsItemDetail", lxt_goodsItemDetails)
        into lxt_goodsItemDetails
        from dual;
    end if;

    return lxt_goodsItemDetails;
  end;

  function get_repairAndRefinement_xml(irec_repairAndRefinement t_repairAndRefinement)
    return xmltype
  is
    lxt_repairAndRefinement xmltype;
  begin
    select XMLElement("repairAndRefinement"
                    , XMLElement("direction", irec_repairAndRefinement.direction)
                    , XMLElement("refinementType", irec_repairAndRefinement.refinementType)
                    , XMLElement("processType", irec_repairAndRefinement.processType)
                    , XMLElement("billingType", irec_repairAndRefinement.billingType)
                    , XMLElement("temporaryAdmission", irec_repairAndRefinement.temporaryAdmission)
                    , XMLElement("exportValue", irec_repairAndRefinement.exportValue)
                     )
      into lxt_repairAndRefinement
      from dual;

    return lxt_repairAndRefinement;
  end;

  function get_goodsItem_xml(irec_goodsItem t_goodsItem)
    return xmltype
  is
    lxt_goodsItem           xmltype;
    lxt_goodsData           xmltype;
    lxt_producedDocuments   xmltype;
    lxt_permits             xmltype;
    lxt_nonCustomsLaws      xmltype;
    lxt_sensibleGoods       xmltype;
    lxt_notifications       xmltype;
    lxt_specialMentions     xmltype;
    lxt_goodsItemDetails    xmltype;
    lxt_repairAndRefinement xmltype;
  begin
    lxt_goodsData            := get_goodsData_xml(irec_goodsItem.goodsData);
    lxt_producedDocuments    := get_producedDocuments_xml(irec_goodsItem.producedDocuments.producedDocument);
    lxt_permits              := get_permits(irec_goodsItem.permits);
    lxt_nonCustomsLaws       := get_nonCustomLaws(irec_goodsItem.nonCustomsLaws);
    lxt_sensibleGoods        := get_SensibleGoods_xml(irec_goodsItem.sensiblegoods.sensiblegood);
    lxt_notifications        := get_notifications_xml(irec_goodsItem.notifications.notification);
    lxt_specialMentions      := get_specialMentionsItem_xml(irec_goodsItem.specialMentions.specialMention);
    lxt_goodsItemDetails     := get_goodsItemDetails_xml(irec_goodsItem.goodsItemDetails.goodsItemDetail);
    lxt_repairAndRefinement  := get_repairAndRefinement_xml(irec_goodsItem.repairAndRefinement);

    select XMLElement("GoodsItem"
                    , XMLElement("id", irec_goodsItem.id)
                    , lxt_goodsData
                    , lxt_producedDocuments
                    , lxt_permits
                    , lxt_nonCustomsLaws
                    , lxt_sensibleGoods
                    , lxt_notifications
                    , lxt_specialMentions
                    , lxt_goodsItemDetails
                    , lxt_repairAndRefinement
                     )
      into lxt_goodsItem
      from dual;

    return lxt_goodsItem;
  end;

  function get_goodsItems_xml(itbl_goodsItems ttbl_goodsItem)
    return xmltype
  is
    lxt_goodsItems xmltype;
    lxt_goodsItem  xmltype;
  begin
    if itbl_goodsItems.count > 0 then
      for ln_cpt in itbl_goodsItems.first .. itbl_goodsItems.last loop
        lxt_goodsItem  := get_goodsItem_xml(itbl_goodsItems(ln_cpt) );

        select XMLConcat(lxt_goodsItems, lxt_goodsItem)
          into lxt_goodsItems
          from dual;
      end loop;
    end if;

    if lxt_goodsItems is not null then
      select XMLElement("itemList", XMLElement("goodsItems", lxt_goodsItems) )
        into lxt_goodsItems
        from dual;
    end if;

    return lxt_goodsItems;
  end;

  function get_goodsDeclaration(irec_goodsDeclaration t_goodsDeclaration)
    return xmltype
  is
    lxt_goodsDeclaration xmltype;
    lxt_transportMeans   xmltype;
    lxt_containers       xmltype;
    lxt_specialMentions  xmltype;
    lxt_consignor        xmltype;
    lxt_consignee        xmltype;
    lxt_delivery         xmltype;
    lxt_carrier          xmltype;
    lxt_business         xmltype;
  begin
    lxt_transportMeans   := get_transportMeans_xml(irec_goodsDeclaration.transportMeans);
    lxt_containers       := get_containers_xml(irec_goodsDeclaration.containers.container);
    lxt_specialMentions  := get_specialMentionsHeader_xml(irec_goodsDeclaration.specialMentions.specialMention);
    lxt_consignor        := get_consignor_xml(irec_goodsDeclaration.consignor);
    lxt_consignee        := get_consignee_xml(irec_goodsDeclaration.consignee);
    lxt_delivery         := get_delivery_xml(irec_goodsDeclaration.delivery);
    lxt_carrier          := get_carrier_xml(irec_goodsDeclaration.carrier);
    lxt_business         := get_business_xml(irec_goodsDeclaration.business);

    select XMLElement("goodsDeclaration"
                    , XMLElement("traderDeclarationNumber", irec_goodsDeclaration.traderDeclarationNumber)
                    , XMLElement("traderReference", irec_goodsDeclaration.traderReference)
                    , XMLElement("deliveryDestination", irec_goodsDeclaration.deliveryDestination)
                    , lxt_transportMeans
                    , lxt_containers
                    , lxt_specialMentions
                    , lxt_consignor
                    , lxt_consignee
                    , lxt_delivery
                    , lxt_carrier
                    , lxt_business
                     )
      into lxt_goodsDeclaration
      from dual;

    return lxt_goodsDeclaration;
  end;

  function get_sending_xml(irec_sending t_sending_rec)
    return xmltype
  is
    lxt_sending          xmltype;
    lxt_goodsDeclaration xmltype;
    lxt_itemList         xmltype;
  begin
    lxt_goodsDeclaration  := get_goodsDeclaration(irec_sending.sending.goodsDeclaration);
    lxt_itemList          := get_goodsItems_xml(irec_sending.sending.itemList.goodsItems.goodsItem);

    select XMLElement("Sending", lxt_goodsDeclaration, lxt_itemList)
      into lxt_sending
      from dual;

    return lxt_sending;
  end;
end DOC_EDI_EXPOVIT_FMT_V1;
