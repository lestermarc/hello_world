--------------------------------------------------------
--  DDL for Package Body DOC_EDI_XML_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_XML_FUNCTIONS" 
/**
 * Package contenant les fonctions relatives aux XMLs utilisés par l'EDI
 *
 * @version 1.0
 * @date 08.2008
 * @author rforchelet
 * @author spfister
 */
IS
  /**
   * Description
   *   fonction de génération des documents logistique au format XML (standard PCS)
   *   version 1.0
   */
  function genXmlDoc_10(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return CLOB
  is
    obj XMLType;
  begin
    obj := genXmlDoc_10_XMLType(aDocumentId);
    return pc_jutils.get_XMLPrologDefault||Chr(10)||obj.getCLOBVal();
  end genXmlDoc_10;

  /**
   * Description
   *   fonction de génération des documents logistique retournant un XMLType
   */
  function genXmlDoc_10_XMLType(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    strError VARCHAR2(2000);
    obj XMLType;
  begin
    begin
      obj := get_doc_document_xml(aDocumentId);
    exception
      when OTHERS then
        strError := sqlerrm;
        -- Construction d'un petit xml vide
        select
          XMLElement(DOCUMENT,
            XMLComment(get_control),
            strError as ERROR
          ) into obj
        from dual;
    end;
    return obj;
  end genXmlDoc_10_XMLType;

  /**
   * Description
   *   fonction de génération des documents logistique
   * @private
   */
  function get_doc_document_xml(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(DOCUMENT,
        get_control,
        get_header(aDocumentId),
        get_positions(aDocumentId),
        get_footer(aDocumentId)
    ) into xmldata
      from dual;
    return xmldata;

    exception
      when others then return null;
  end get_doc_document_xml;

  /**
   * Description
   *   fonction retournant la branche "CONTROL" de l'XML (source technique du
   *   document)
   * @private
   */
  function get_control
    return XMLType
  is
    xmldata XMLType;
    test_mode string(10);
  begin
    -- La règle de gestion permettant de définir le mode "test" sera définie plus tard
    test_mode := 'false';

    select
      XMLElement(CONTROL,
        XMLForest(
          pcs.pc_erp_version.Banner as GENERATION_INFO,
          to_char(Sysdate, 'YYYY-MM-DD"T"HH24:MI:SS') as GENERATION_DATE,
          test_mode TEST_MODE,
          '1.0' as VERSION)
      ) into xmldata
    from dual;
    return xmldata;

    exception
      when others then return null;
  end get_control;

  /**
   * Description
   *   fonction retournant la branche "HEADER" de l'XML
   * @private
   */
  function get_header(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
     select
      XMLElement(HEADER,
        XMLElement(THIS_DOCUMENT,
          get_document_type(aDocumentId),
          XMLForest(
            doc.dmt_date_value as VALUE_DATE,
            cur.currency as CURRENCY
          ),
          get_terms_of_delivery(aDocumentId),
          get_terms_of_payment(aDocumentId),
          get_packing_informations(aDocumentId),
          get_weights(aDocumentID),
          get_document_texts(aDocumentID),
          get_doc_reference_history(aDocumentID)
        ),
        XMLElement(SENDER,
          get_sender_id,
          XMLForest(
            doc.dmt_number as DOCUMENT_NUMBER,
            doc.dmt_date_document as DOCUMENT_DATE,
            doc.dmt_reference as REFERENCE
          ),
          get_sender_address,
          get_sender_vat_info
        ),
        nvl2(doc.pac_third_id,
        XMLElement(RECIPIENT,
          get_third_id(aDocumentId, doc.pac_third_id),
          XMLForest(
            doc.dmt_number as DOCUMENT_NUMBER,
            doc.dmt_date_document as DOCUMENT_DATE
          ),
          get_recipient_address(aDocumentId),
          get_third_vat_info(doc.pac_third_id)
        ), null),
        nvl2(doc.pac_third_aci_id,
        XMLElement(BILL_TO,
          get_third_id(aDocumentId, doc.pac_third_aci_id),
          get_bill_to_address(aDocumentId),
          get_third_vat_info(doc.pac_third_aci_id)
        ), null),
        nvl2(doc.pac_third_delivery_id,
        XMLElement(SHIP_TO,
          get_third_id(aDocumentId, doc.pac_third_delivery_id),
          get_ship_to_address(aDocumentId),
          get_third_vat_info(doc.pac_third_delivery_id)
        ), null)
      )
      into xmldata
      from doc_document doc
         , pcs.pc_curr cur
         , acs_financial_currency acs
     where doc.doc_document_id = aDocumentId
       and cur.pc_curr_id = acs.pc_curr_id
       and acs.acs_financial_currency_id = doc.acs_financial_currency_id;
    return xmldata;

    exception
      when others then return null;
  end get_header;

  /**
   * Description
   *   fonction retournant la branche "DOCUMENT_TYPE" de l'XML
   * @private
   */
  function get_document_type(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(DOCUMENT_TYPE,
        XMLForest(
          nvl(gas.gas_edi_document_type, gau.gau_describe) as LOGISTICS,
          '*' as FINANCIAL
          )
        )
    into xmldata
    from doc_document doc
       , doc_gauge gau
       , doc_gauge_structured gas
    where doc.doc_document_id = aDocumentId
     and doc.doc_gauge_id = gau.doc_gauge_id
     and doc.doc_gauge_id = gas.doc_gauge_id(+);
    return xmldata;

    exception
      when others then return null;
  end get_document_type;

  /**
   * Description
   *   fonction retournant la branche "TERMS_OF_DELIVERY" de l'XML
   * @private
   */
  function get_terms_of_delivery(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(TERMS_OF_DELIVERY,
        XMLForest(
          doc.c_incoterms as INCOTERM,
          doc.dmt_incoterms_place as LOCATION,
          pac.sen_key as SHIPPING_MODE
          )
        )
    into xmldata
    from doc_document doc
       , pac_sending_condition pac
    where doc.doc_document_id = aDocumentId
     and doc.pac_sending_condition_id = pac.pac_sending_condition_id;
    return xmldata;

    exception
      when others then return null;
  end get_terms_of_delivery;

  /**
   * Description
   *   fonction retournant la branche "TERMS_OF_PAYMENT" de l'XML
   * @private
   */
  function get_terms_of_payment(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(TERMS_OF_PAYMENT,
        XMLForest(
          pac.pco_descr as IDENTIFIER,
          tra.apt_text as DESCRIPTION,
          pmt.pad_payment_date as DUE_DATE
          )
        )
    into xmldata
    from doc_document doc
       , pac_payment_condition pac
       , pcs.pc_appltxt_traduction tra
       , (select to_char(min(pmt2.pad_payment_date), 'YYYY-MM-DD HH24:MI:SS') pad_payment_date
            from doc_payment_date pmt2
               , doc_foot foo
           where foo.doc_foot_id = pmt2.doc_foot_id
             and aDocumentId = foo.doc_document_id) pmt
    where doc.doc_document_id = aDocumentId
     and doc.pac_payment_condition_id = pac.pac_payment_condition_id
     and pac.pc_appltxt_id = tra.pc_appltxt_id
     and tra.pc_lang_id = pcs.PC_I_LIB_SESSION.GetUserLangId;
    return xmldata;

    exception
      when others then return null;
  end get_terms_of_payment;

  /**
   * Description
   *   fonction retournant la branche "PACKING_INFORMATIONS" de l'XML
   * @private
   */
  function get_packing_informations(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(PACKING_INFORMATIONS,
        XMLForest(
          foo.foo_packaging as PACKING_DESCRIPTION,
          foo.foo_marking as PACKING_MARKING,
          foo.foo_measure as PACKING_MEASURE,
          foo.foo_parcel_qty as NUMBER_OF_PARCELS
          )
        )
    into xmldata
    from doc_foot foo
   where aDocumentId = foo.doc_document_id;
    return xmldata;

    exception
      when others then return null;
  end get_packing_informations;

  /**
   * Description
   *   fonction retournant la branche "WEIGHTS" de l'XML
   * @private
   */
  function get_weights(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(WEIGHTS,
        XMLForest(
          foo.foo_total_gross_weight_meas as GROSS_WEIGHT,
          foo.foo_total_gross_weight as GROSS_WEIGHT_CALC,
          foo.foo_total_net_weight_meas as NET_WEIGHT,
          foo.foo_total_net_weight as NET_WEIGHT_CALC
          )
        )
    into xmldata
    from doc_foot foo
   where aDocumentId = foo.doc_document_id;
    return xmldata;

    exception
      when others then return null;
  end get_weights;

  /**
   * Description
   *   fonction retournant la branche "DOCUMENT_TEXTS" de l'XML
   * @private
   */
  function get_document_texts(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(DOCUMENT_TEXTS,
        XMLForest(
          doc.dmt_heading_text as HEADING_TEXT,
          doc.dmt_document_text as DOCUMENT_TEXT
          )
        )
    into xmldata
    from doc_document doc
   where aDocumentId = doc.doc_document_id;
    return xmldata;

    exception
      when others then return null;
  end get_document_texts;


  /**
   * Description
   *   fonction retournant la branche "DOCUMENT_REFERENCE_HISTORY" de l'XML
   * @private
   */
  function get_doc_reference_history(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(DOCUMENT_REFERENCE_HISTORY,
        XMLElement(DOCUMENT_REFERENCE,
          XMLForest(
            doc.dmt_partner_number as DOCUMENT_NUMBER,
            doc.dmt_date_partner_document as DOCUMENT_DATE
            )
          )
        )
    into xmldata
    from doc_document doc
   where aDocumentId = doc.doc_document_id;
    return xmldata;

    exception
      when others then return null;
  end get_doc_reference_history;

  /**
   * Description
   *   fonction retournant la branche "SENDER/IDENTIFIER" de l'XML
   * @private
   */
  function get_sender_id
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(IDENTIFIER,
        XMLForest(
          com.com_edi as KEY
          )
        )
    into xmldata
    from pcs.pc_comp com
   where com.pc_comp_id = pcs.PC_I_LIB_SESSION.getCompanyId;
  return xmldata;

    exception
      when others then return null;
  end get_sender_id;

  /**
   * Description
   *   fonction retournant la branche "SENDER/ADDRESS" de l'XML
   * @private
   */
  function get_sender_address
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(ADDRESS,
        XMLForest(
          com.com_name as NAME1,
          com.com_descr as NAME2,
          com.com_adr as STREET,
          com.pc_cntry_id as COUNTRY_CODE,
          com.com_zip as ZIP,
          com.com_city as CITY
          )
        )
    into xmldata
    from pcs.pc_comp com
   where com.pc_comp_id = pcs.PC_I_LIB_SESSION.getCompanyId;
    return xmldata;

    exception
      when others then return null;
  end get_sender_address;

  /**
   * Description
   *   fonction retournant la branche "SENDER/VAT_INFORMATION" de l'XML
   * @private
   */
  function get_sender_vat_info
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(VAT_INFORMATION,
        XMLForest(
          com.com_vatno  as VAT_NO
          )
        )
    into xmldata
    from pcs.pc_comp com
   where com.pc_comp_id = pcs.PC_I_LIB_SESSION.getCompanyId
     and com.com_vatno is not null;
    return xmldata;

    exception
      when others then return null;
  end get_sender_vat_info;

  /**
   * Description
   *   fonction retournant la branche "IDENTIFIER" de l'XML
   * @private
   */
  function get_third_id(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , aThirdId in PAC_THIRD.PAC_THIRD_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(IDENTIFIER,
        XMLForest(
          case
            when gau.c_admin_domain = 1 then (select sup.cre_ean_number
                                               from pac_supplier_partner sup
                                              where aThirdId = sup.pac_supplier_partner_id)
            when gau.c_admin_domain = 2 then (select cus.cus_ean_number
                                               from pac_custom_partner cus
                                              where aThirdId = cus.pac_custom_partner_id)
            else null
          end as KEY
          )
        )
    into xmldata
    from doc_document doc
       , doc_gauge gau
   where doc.doc_gauge_id = gau.doc_gauge_id
   and aDocumentId = doc.doc_document_id;
    return xmldata;

    exception
      when others then return null;
  end get_third_id;

  /**
   * Description
   *   fonction retournant la branche "RECIPIENT/ADDRESS" de l'XML
   * @private
   */
  function get_recipient_address(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(ADDRESS,
        XMLForest(
          doc.dmt_name1 as NAME1,
          doc.dmt_forename1 as NAME2,
          doc.dmt_activity1 as ACTIVITY,
          doc.dmt_care_of1 as CARE_OF,
          doc.dmt_address1 as STREET,
          doc.dmt_po_box1 as PO_BOX,
          doc.dmt_po_box_nbr1 as PO_BOX_NO,
          cnt.cntid as COUNTRY_CODE,
          doc.dmt_postcode1 as ZIP,
          doc.dmt_town1 as CITY,
          doc.dmt_state1 as STATE,
          doc.dmt_county1 as COUNTY,
          doc.dmt_contact1 as CONTACT_PERSON
          )
        )
    into xmldata
    from doc_document doc
       , pcs.pc_cntry cnt
   where aDocumentId = doc.doc_document_id
     and doc.pc_cntry_id = cnt.pc_cntry_id;
    return xmldata;

    exception
      when others then return null;
  end get_recipient_address;

  /**
   * Description
   *   fonction retournant la branche "VAT_INFORMATION" de l'XML
   * @private
   */
  function get_third_vat_info(aThirdId in PAC_THIRD.PAC_THIRD_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(VAT_INFORMATION,
        XMLForest(
          thi.thi_no_tva as VAT_NO
          )
        )
    into xmldata
    from pac_third thi
   where aThirdId = thi.pac_third_id
     and thi.thi_no_tva is not null;
    return xmldata;

    exception
      when others then return null;
  end get_third_vat_info;

  /**
   * Description
   *   fonction retournant la branche "BILL_TO/ADDRESS" de l'XML
   * @private
   */
  function get_bill_to_address(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(ADDRESS,
        XMLForest(
          doc.dmt_name3 as NAME1,
          doc.dmt_forename3 as NAME2,
          doc.dmt_activity3 as ACTIVITY,
          doc.dmt_care_of3 as CARE_OF,
          doc.dmt_address3 as STREET,
          doc.dmt_po_box3 as PO_BOX,
          doc.dmt_po_box_nbr3 as PO_BOX_NO,
          cnt.cntid as COUNTRY_CODE,
          doc.dmt_postcode3 as ZIP,
          doc.dmt_town3 as CITY,
          doc.dmt_state3 as STATE,
          doc.dmt_county3 as COUNTY,
          doc.dmt_contact3 as CONTACT_PERSON
          )
        )
    into xmldata
    from doc_document doc
       , pcs.pc_cntry cnt
   where aDocumentId = doc.doc_document_id
     and doc.pc_2_pc_cntry_id = cnt.pc_cntry_id;
    return xmldata;

    exception
      when others then return null;
  end get_bill_to_address;

  /**
   * Description
   *   fonction retournant la branche "SHIP_TO/ADDRESS" de l'XML
   * @private
   */
  function get_ship_to_address(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(ADDRESS,
        XMLForest(
          doc.dmt_name2 as NAME1,
          doc.dmt_forename2 as NAME2,
          doc.dmt_activity2 as ACTIVITY,
          doc.dmt_care_of2 as CARE_OF,
          doc.dmt_address2 as STREET,
          doc.dmt_po_box2 as PO_BOX,
          doc.dmt_po_box_nbr2 as PO_BOX_NO,
          cnt.cntid as COUNTRY_CODE,
          doc.dmt_postcode2 as ZIP,
          doc.dmt_town2 as CITY,
          doc.dmt_state2 as STATE,
          doc.dmt_county2 as COUNTY,
          doc.dmt_contact2 as CONTACT_PERSON
          )
        )
    into xmldata
    from doc_document doc
       , pcs.pc_cntry cnt
   where aDocumentId = doc.doc_document_id
     and doc.pc__pc_cntry_id = cnt.pc_cntry_id;
    return xmldata;

    exception
      when others then return null;
  end get_ship_to_address;

  /**
   * Description
   *   fonction retournant la branche "POSITIONS" de l'XML
   *   (liste de toutes les positions du document)
   * @private
   */
  function get_positions(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLAgg(
        get_position(pos.doc_position_id)
        order by pos.pos_number asc
      )
    into xmldata
    from doc_position pos
   where aDocumentId = pos.doc_document_id
     and pos.c_gauge_type_pos in (1,2,3,5,7,8,10);

    -- Générer le tag principal uniquement s'il y a données
    if (xmldata is not null) then
      select
        XMLElement(POSITIONS,
          xmldata
        ) into xmldata
      from dual;
      return xmldata;
    end if;
    return null;

    exception
      when others then return null;
  end get_positions;

  /**
   * Description
   *   fonction retournant la branche "POSITION" de l'XML
   *   (détail d'une position)
   * @private
   */
  function get_position(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(POSITION,
        XMLForest(
          pos.pos_number as POSITION_NUMBER,
          pos.c_gauge_type_pos as POSITION_TYPE
        ),
        get_price(aPositionId),
        get_logistics_part(aPositionId),
        get_pos_charge_details(aPositionId),
        get_pos_discount_details(aPositionId)
      )
    into xmldata
    from doc_position pos
   where aPositionId = pos.doc_position_id;
    return xmldata;

    exception
      when others then return null;
  end get_position;

  /**
   * Description
   *   fonction retournant la branche "PRICE" de l'XML
   * @private
   */
  function get_price(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(PRICE,
        XMLForest(
          pos.pos_gross_unit_value as UNIT_AMOUNT,
          pos.pos_net_value_excl as POSITION_NET_AMOUNT_VAT_EXCL,
          pos.pos_net_value_incl as POSITION_NET_AMOUNT_VAT_INCL,
          pos.pos_gross_value as POSITION_GROSS_AMOUNT_VAT_EXCL,
          pos.pos_gross_value_incl as POSITION_GROSS_AMOUNT_VAT_INCL
        ),
        XMLElement(VAT,
          XMLForest(
            pos.pos_vat_amount as AMOUNT,
            pos.pos_vat_rate as RATE
          )
        ),
        get_pos_charge_details(aPositionId),
        get_pos_discount_details(aPositionId)
      )
    into xmldata
    from doc_position pos
   where aPositionId = pos.doc_position_id;
    return xmldata;

    exception
      when others then return null;
  end get_price;

  /**
   * Description
   *   fonction retournant la branche "POSITION/CHARGE_DETAILS" de l'XML
   * @private
   */
  function get_pos_charge_details(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLAgg(XMLElement(CHARGE_DETAIL,
        XMLForest(
          crg.crg_name as IDENTIFIER,
          pch.pch_description as DESCRIPTION,
          case
            when pos.pos_include_tax_tariff = 1 then
                 pch.pch_amount - (ACS_FUNCTION.CalcVatAmount(aLiabledAmount      => pch.pch_amount
                                      , aTaxCodeId          => POS.ACS_TAX_CODE_ID
                                      , aIE                 => 'I'
                                      , aDateRef            => nvl(POS.POS_DATE_DELIVERY, DMT.DMT_DATE_VALUE)
                                      , aRound              => 1))
            else pch.pch_amount
          end as AMOUNT_VAT_EXCL
        ),
        XMLElement(VAT,
          XMLForest(
            (ACS_FUNCTION.CalcVatAmount(aLiabledAmount      => pch.pch_amount
                                      , aTaxCodeId          => POS.ACS_TAX_CODE_ID
                                      , aIE                 => (case when pos.pos_include_tax_tariff = 1 then 'I' else 'E' end)
                                      , aDateRef            => nvl(POS.POS_DATE_DELIVERY, DMT.DMT_DATE_VALUE)
                                      , aRound              => 1) ) as AMOUNT,
            pos.pos_vat_rate as RATE
          )
        ),
        XMLForest(
          (case
             when pos.pos_include_tax_tariff = 1 then pch.pch_amount
             else pch.pch_amount + (ACS_FUNCTION.CalcVatAmount(aLiabledAmount      => pch.pch_amount
                                      , aTaxCodeId          => POS.ACS_TAX_CODE_ID
                                      , aIE                 => 'E'
                                      , aDateRef            => nvl(POS.POS_DATE_DELIVERY, DMT.DMT_DATE_VALUE)
                                      , aRound              => 1))
           end) as AMOUNT_VAT_INCL
        )
      ) order by crg.crg_name asc)
    into xmldata
    from doc_position pos
       , doc_position_charge pch
       , doc_document dmt
       , ptc_charge crg
   where aPositionId = pos.doc_position_id
     and pos.doc_position_id = pch.doc_position_id
     and pos.doc_document_id = dmt.doc_document_id
     and crg.ptc_charge_id = pch.ptc_charge_id;

    -- Générer le tag principal uniquement s'il y a données
    if (xmldata is not null) then
      select
        XMLElement(CHARGE_DETAILS,
          xmldata
        ) into xmldata
      from dual;
      return xmldata;
    end if;
    return null;

    exception
      when others then return null;
  end get_pos_charge_details;

  /**
   * Description
   *   fonction retournant la branche "POSITION/DISCOUNT_DETAILS" de l'XML
   * @private
   */
  function get_pos_discount_details(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLAgg(XMLElement(DISCOUNT_DETAIL,
        XMLForest(
          dnt.dnt_name as IDENTIFIER,
          pch.pch_description as DESCRIPTION,
          case
            when pos.pos_include_tax_tariff = 1 then
                 pch.pch_amount - (ACS_FUNCTION.CalcVatAmount(aLiabledAmount      => pch.pch_amount
                                      , aTaxCodeId          => POS.ACS_TAX_CODE_ID
                                      , aIE                 => 'I'
                                      , aDateRef            => nvl(POS.POS_DATE_DELIVERY, DMT.DMT_DATE_VALUE)
                                      , aRound              => 1))
            else pch.pch_amount
          end as AMOUNT_VAT_EXCL
        ),
        XMLElement(VAT,
          XMLForest(
            (ACS_FUNCTION.CalcVatAmount(aLiabledAmount      => pch.pch_amount
                                      , aTaxCodeId          => POS.ACS_TAX_CODE_ID
                                      , aIE                 => (case when pos.pos_include_tax_tariff = 1 then 'I' else 'E' end)
                                      , aDateRef            => nvl(POS.POS_DATE_DELIVERY, DMT.DMT_DATE_VALUE)
                                      , aRound              => 1) ) as AMOUNT,
            pos.pos_vat_rate as RATE
          )
        ),
        XMLForest(
          (case
             when pos.pos_include_tax_tariff = 1 then pch.pch_amount
             else pch.pch_amount + (ACS_FUNCTION.CalcVatAmount(aLiabledAmount      => pch.pch_amount
                                      , aTaxCodeId          => POS.ACS_TAX_CODE_ID
                                      , aIE                 => 'E'
                                      , aDateRef            => nvl(POS.POS_DATE_DELIVERY, DMT.DMT_DATE_VALUE)
                                      , aRound              => 1))
           end) as AMOUNT_VAT_INCL
        )
      ) order by dnt.dnt_name asc)
    into xmldata
    from doc_position pos
       , doc_position_charge pch
       , doc_document dmt
       , ptc_discount dnt
   where aPositionId = pos.doc_position_id
     and pos.doc_position_id = pch.doc_position_id
     and pos.doc_document_id = dmt.doc_document_id
     and dnt.ptc_discount_id = pch.ptc_discount_id;

    -- Générer le tag principal uniquement s'il y a données
    if (xmldata is not null) then
      select
        XMLElement(DISCOUNT_DETAILS,
          xmldata
        ) into xmldata
      from dual;
      return xmldata;
    end if;
    return null;

    exception
      when others then return null;
  end get_pos_discount_details;

  /**
   * Description
   *   fonction retournant la branche "LOGISTICS_PART" de l'XML
   * @private
   */
  function get_logistics_part(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(LOGISTICS_PART,
        get_pos_reference_history(aPositionId),
        get_product_references(aPositionId),
        XMLForest(
          pos.pos_final_quantity as QUANTITY,
          nvl(ume.ume_uom_code, pos.dic_unit_of_measure_id) as PRODUCT_UNIT
        ),
        get_pos_details(aPositionId),
        case when pos.pos_gross_weight is not null
              or pos.pos_net_weight is not null then
        XMLElement(WEIGHTS,
          XMLForest(
            pos.pos_gross_weight as GROSS_WEIGHT,
            pos.pos_net_weight as NET_WEIGHT
          )
        ) end
      )
    into xmldata
    from doc_position pos
       , dic_unit_of_measure ume
   where aPositionId = pos.doc_position_id
     and pos.dic_unit_of_measure_id = ume.dic_unit_of_measure_id;
    return xmldata;

    exception
      when others then return null;
  end get_logistics_part;


  /**
   * Description
   *   fonction retournant la branche "DOCUMENT_REFERENCE_HISTORY" de l'XML
   * @private
   */
  function get_pos_reference_history(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return XMLType
  is
    xmldata XMLType;
    sender number(1);
  begin
    select case
             when(    pos.pos_partner_pos_number is null
                  and pos.pos_partner_number is null
                  and pos.pos_date_partner_document is null
                 ) then 1
             else 0
           end
      into sender
      from doc_position pos
     where pos.doc_position_id = aPositionId;

    if sender = 1 then

      select
        XMLElement(DOCUMENT_REFERENCE_HISTORY,
          XMLAttributes('sender' as "type"),
          XMLForest(
            doc.dmt_number as DOCUMENT_NUMBER,
            doc.dmt_date_document as DOCUMENT_DATE
          )
        )
        into xmldata
        from doc_position pos
           , doc_document doc
       where aPositionId = pos.doc_position_id
         and pos.doc_document_id = doc.doc_document_id;
        return xmldata;

    else

      select
        XMLElement(DOCUMENT_REFERENCE_HISTORY,
          XMLAttributes('recipient' as "type"),
          XMLForest(
            pos.pos_partner_number as DOCUMENT_NUMBER,
            pos.pos_partner_pos_number as DOCUMENT_POSITION,
            pos.pos_date_partner_document as DOCUMENT_DATE
          )
        )
        into xmldata
        from doc_position pos
       where aPositionId = pos.doc_position_id;
        return xmldata;

    end if;

    exception
      when others then return null;
  end get_pos_reference_history;

  /**
   * Description
   *   fonction retournant la branche "PRODUCT_REFERENCES" de l'XML
   * @private
   */
  function get_product_references(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLElement(PRODUCT_REFERENCES,
        XMLElement(PRODUCT_REFERENCE,
          XMLAttributes('internal_reference' as "type", 'sender' as "party"),
          goo.goo_major_reference
        ),
        XMLForest(
          pos.pos_short_description as DESCRIPTION_SHORT,
          pos.pos_long_description as DESCRIPTION_LONG,
          pos.pos_free_description as DESCRIPTION_FREE
        )
      )
    into xmldata
    from doc_position pos
       , gco_good goo
   where aPositionId = pos.doc_position_id
     and pos.gco_good_id = goo.gco_good_id;
    return xmldata;

    exception
      when others then return null;
  end get_product_references;

  /**
   * Description
   *   fonction retournant le type d'une caractéristique (pour l'attribut du
   *   noeud PRODUCT_CHARACTERISTIC/@type)
   * @private
   */
  function get_characteristic_type(aCharacId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return Varchar2
  is
    charac_type varchar2(50);
  begin
    select case
              when cha.c_charact_type = 1 then 'version'
              when cha.c_charact_type = 2 then 'characteristics'
              when cha.c_charact_type = 3 then 'part'
              when cha.c_charact_type = 4 then 'batch'
              when cha.c_charact_type = 5 then 'chronological'
           end
     into charac_type
     from gco_characterization cha
    where cha.gco_characterization_id = aCharacId;
    return charac_type;

    exception
      when others then return null;
  end;

  /**
   * Description
   *   fonction retournant la branche "PRODUCT_CHARACTERISTICS" de l'XML
   * @private
   */
  function get_characteristics(aDetPositionId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin

    select
      XMLElement(PRODUCT_CHARACTERISTICS,
        case when pde.gco_characterization_id is not null then
        XMLElement(PRODUCT_CHARACTERISTIC,
          XMLAttributes(DOC_EDI_XML_FUNCTIONS.get_characteristic_type(pde.gco_characterization_id) as "type"),
          pde.pde_characterization_value_1
        )end ,
        case when pde.gco_gco_characterization_id is not null then
        XMLElement(PRODUCT_CHARACTERISTIC,
          XMLAttributes(DOC_EDI_XML_FUNCTIONS.get_characteristic_type(pde.gco_gco_characterization_id) as "type"),
          pde.pde_characterization_value_2
        ) end,
        case when pde.gco2_gco_characterization_id is not null then
        XMLElement(PRODUCT_CHARACTERISTIC,
          XMLAttributes(DOC_EDI_XML_FUNCTIONS.get_characteristic_type(pde.gco2_gco_characterization_id) as "type"),
          pde.pde_characterization_value_3
        ) end,
        case when pde.gco3_gco_characterization_id is not null then
        XMLElement(PRODUCT_CHARACTERISTIC,
          XMLAttributes(DOC_EDI_XML_FUNCTIONS.get_characteristic_type(pde.gco3_gco_characterization_id) as "type"),
          pde.pde_characterization_value_4
        ) end,
        case when pde.gco4_gco_characterization_id is not null then
        XMLElement(PRODUCT_CHARACTERISTIC,
          XMLAttributes(DOC_EDI_XML_FUNCTIONS.get_characteristic_type(pde.gco4_gco_characterization_id) as "type"),
          pde.pde_characterization_value_5
        ) end
      )
      into xmldata
      from doc_position_detail pde
     where aDetPositionId = pde.doc_position_detail_id;

    -- Générer le tag principal uniquement s'il y a données
    select xmldata
      into xmldata
      from dual
     where existsnode(xmldata,'/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC') = 1;
    return xmldata;

    exception
      when others then return null;
  end get_characteristics;


  /**
   * Description
   *   fonction retournant la branche "POSITION_DETAILS" de l'XML
   * @private
   */
  function get_pos_details(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLAgg(XMLElement(POSITION_DETAIL,
        XMLForest(
          pde.doc_position_detail_id as IDENTIFIER,
          pde.pde_final_quantity as QUANTITY
        ),
        get_characteristics(pde.doc_position_detail_id),
        XMLForest(
          case when gap.gap_delay = 1 then pde.pde_basis_delay end as DELIVERY_DATE
        )
      ))
    into xmldata
    from doc_position_detail pde
       , doc_gauge_position gap
       , doc_position pos
   where aPositionId = pde.doc_position_id
     and pde.doc_position_id = pos.doc_position_id
     and pos.doc_gauge_position_id = gap.doc_gauge_position_id;

    -- Générer le tag principal uniquement s'il y a données
    if (xmldata is not null) then
      select
        XMLElement(POSITION_DETAILS,
          xmldata
        ) into xmldata
      from dual;
      return xmldata;
    end if;
    return null;

    exception
      when others then return null;
  end get_pos_details;

  /**
   * Description
   *   fonction retournant la branche "FOOTER" de l'XML
   * @private
   */
  function get_footer(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
     select
      XMLElement(FOOTER,
        XMLElement(DOCUMENT_AMOUNTS,
          get_document_amount(aDocumentId)
        ),
        get_foo_charge_details(aDocumentId),
        get_foo_discount_details(aDocumentId)
      )
      into xmldata
      from doc_document doc
     where doc.doc_document_id = aDocumentId;
    return xmldata;

    exception
      when others then return null;
  end get_footer;

  /**
   * Description
   *   fonction retournant la branche "DOCUMENT_AMOUNT" de l'XML
   * @private
   */
  function get_document_amount(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLAgg(XMLElement(DOCUMENT_AMOUNT,
        XMLForest(
          acc.vda_liable_amount as TOTAL_AMOUNT_VAT_EXCL,
          acc.vda_vat_amount as VAT_TOTAL_AMOUNT,
          acc.vda_vat_rate as VAT_RATE,
          acc.vda_liable_amount + acc.vda_vat_amount as TOTAL_AMOUNT_VAT_INCL
        )
      ))
    into xmldata
    from doc_vat_det_account acc
        , doc_foot foo
   where aDocumentId = foo.doc_document_id
     and foo.doc_foot_id = acc.doc_foot_id;
    return xmldata;

    exception
      when others then return null;
  end get_document_amount;

  /**
   * Description
   *   fonction retournant la branche "FOOTER/CHARGE_DETAILS" de l'XML
   * @private
   */
  function get_foo_charge_details(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLAgg(XMLElement(CHARGE_DETAIL,
        XMLForest(
          crg.crg_name as IDENTIFIER,
          fch.fch_description as DESCRIPTION,
          fch.fch_excl_amount as AMOUNT_VAT_EXCL
        ),
        XMLElement(VAT,
          XMLForest(
            fch.fch_vat_amount as AMOUNT,
            fch.fch_vat_rate as RATE
          )
        ),
        XMLForest(
          fch.fch_incl_amount as AMOUNT_VAT_INCL
        )
      ) order by crg.crg_name asc)
    into xmldata
    from doc_foot foo
       , doc_foot_charge fch
       , ptc_charge crg
   where aDocumentId = foo.doc_document_id
     and foo.doc_foot_id = fch.doc_foot_id
     and crg.ptc_charge_id = fch.ptc_charge_id;

    -- Générer le tag principal uniquement s'il y a données
    if (xmldata is not null) then
      select
        XMLElement(CHARGE_DETAILS,
          xmldata
        ) into xmldata
      from dual;
      return xmldata;
    end if;
    return null;

    exception
      when others then return null;
  end get_foo_charge_details;

  /**
   * Description
   *   fonction retournant la branche "FOOTER/DISCOUNT_DETAILS" de l'XML
   * @private
   */
  function get_foo_discount_details(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return XMLType
  is
    xmldata XMLType;
  begin
    select
      XMLAgg(XMLElement(DISCOUNT_DETAIL,
        XMLForest(
          dnt.dnt_name as IDENTIFIER,
          fch.fch_description as DESCRIPTION,
          fch.fch_excl_amount as AMOUNT_VAT_EXCL
        ),
        XMLElement(VAT,
          XMLForest(
            fch.fch_vat_amount as AMOUNT,
            fch.fch_vat_rate as RATE
          )
        ),
        XMLForest(
          fch.fch_incl_amount as AMOUNT_VAT_INCL
        )
      ) order by dnt.dnt_name asc)
    into xmldata
    from doc_foot foo
       , doc_foot_charge fch
       , ptc_discount dnt
   where aDocumentId = foo.doc_document_id
     and foo.doc_foot_id = fch.doc_foot_id
     and dnt.ptc_discount_id = fch.ptc_discount_id;

    -- Générer le tag principal uniquement s'il y a données
    if (xmldata is not null) then
      select
        XMLElement(DISCOUNT_DETAILS,
          xmldata
        ) into xmldata
      from dual;
      return xmldata;
    end if;
    return null;

    exception
      when others then return null;
  end get_foo_discount_details;

END DOC_EDI_XML_FUNCTIONS;
 /*FMT(352) ERROR:
AS followed by an alias not allowed here (reserved for XMLCOLATTVAL, XMLFOREST and XMLATTRIBUTES only)
Input line 395 (near output line 398), col 22

*/
/*FMT(352) END UNFORMATTED */
