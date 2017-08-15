--------------------------------------------------------
--  DDL for Package Body DOC_PRC_INTERFACE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_INTERFACE" 
is
  /**
   * Description
   *   fonction retournant le type d'une caractéristique (pour l'attribut du
   *   noeud PRODUCT_CHARACTERISTIC/@type)
   * @private
   */
  function GetCharacteristicType(iCharacType in varchar2)
    return varchar2
  is
    result varchar2(5);
  begin
    select case
             when iCharacType = 'version' then '1'
             when iCharacType = 'characteristics' then '2'
             when iCharacType = 'part' then '3'
             when iCharacType = 'batch' then '4'
             when iCharacType = 'chronological' then '5'
           end
      into result
      from dual;

    return result;
  exception
    when others then
      return null;
  end GetCharacteristicType;

  /**
  * procedure  ExtractHeader
  * Description
  *   procedure d'extraction de l'entete de document du xml
  */
  procedure ExtractHeader(iXml in xmltype, iotplInterface in out DOC_INTERFACE%rowtype)
  is
  begin
    select substr(extractvalue(iXml, '/DOCUMENT/HEADER/THIS_DOCUMENT/DOCUMENT_REFERENCE_HISTORY/DOCUMENT_REFERENCE/DOCUMENT_NUMBER'), 1, 30)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/THIS_DOCUMENT/DOCUMENT_TYPE/LOGISTICS'), 1, 50)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/THIS_DOCUMENT/TERMS_OF_DELIVERY/SHIPPING_MODE'), 1, 30)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/REFERENCE'), 1, 50)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/DOCUMENT_NUMBER'), 1, 30)
         , to_date(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/DOCUMENT_DATE'), 'YYYY-MM-DD')
         , to_date(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/DOCUMENT_DATE'), 'YYYY-MM-DD')
         , to_date(extractvalue(iXml, '/DOCUMENT/HEADER/THIS_DOCUMENT/VALUE_DATE'), 'YYYY-MM-DD')
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/THIS_DOCUMENT/TERMS_OF_PAYMENT/IDENTIFIER'), 1, 50)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/THIS_DOCUMENT/CURRENCY'), 1, 3)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/THIS_DOCUMENT/DOCUMENT_TEXTS/DOCUMENT_TEXT'), 1, 4000)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/THIS_DOCUMENT/DOCUMENT_TEXTS/HEADING_TEXT'), 1, 4000)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/IDENTIFIER/KEY'), 1, 20)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/IDENTIFIER/KEY'), 1, 20)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/NAME1'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/NAME2'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/STREET'), 1, 255)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/ACTIVITY'), 1, 100)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/CARE_OF'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/PO_BOX'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/PO_BOX_NO'), 1, 9)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/COUNTY'), 1, 30)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/CONTACT_PERSON'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/COUNTRY_CODE'), 1, 5)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/ZIP'), 1, 15)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/CITY'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SENDER/ADDRESS/STATE'), 1, 30)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/IDENTIFIER/KEY'), 1, 20)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/IDENTIFIER/KEY'), 1, 20)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/NAME1'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/NAME2'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/STREET'), 1, 255)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/ACTIVITY'), 1, 100)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/CARE_OF'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/PO_BOX'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/PO_BOX_NO'), 1, 9)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/COUNTY'), 1, 30)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/CONTACT_PERSON'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/COUNTRY_CODE'), 1, 5)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/ZIP'), 1, 15)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/CITY'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/BILL_TO/ADDRESS/STATE'), 1, 30)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/IDENTIFIER/KEY'), 1, 20)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/IDENTIFIER/KEY'), 1, 20)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/NAME1'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/NAME2'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/STREET'), 1, 255)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/ACTIVITY'), 1, 100)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/CARE_OF'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/PO_BOX'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/PO_BOX_NO'), 1, 9)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/COUNTY'), 1, 30)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/CONTACT_PERSON'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/COUNTRY_CODE'), 1, 5)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/ZIP'), 1, 15)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/CITY'), 1, 60)
         , substr(extractvalue(iXml, '/DOCUMENT/HEADER/SHIP_TO/ADDRESS/STATE'), 1, 30)
      into iotplInterface.DMT_NUMBER
         , iotplInterface.DOI_DOCUMENT_TYPE
         , iotplInterface.DOI_SEN_KEY
         , iotplInterface.DOI_PARTNER_REFERENCE
         , iotplInterface.DOI_PARTNER_NUMBER
         , iotplInterface.DOI_PARTNER_DATE
         , iotplInterface.DOI_DOCUMENT_DATE
         , iotplInterface.DOI_VALUE_DATE
         , iotplInterface.DOI_PCO_DESCR
         , iotplInterface.DOI_CURRENCY
         , iotplInterface.DOI_DOCUMENT_TEXT
         , iotplInterface.DOI_HEADING_TEXT
         , iotplInterface.DOI_PER_KEY1
         , iotplInterface.DOI_PER_KEY2
         , iotplInterface.DOI_NAME1
         , iotplInterface.DOI_FORENAME1
         , iotplInterface.DOI_ADDRESS1
         , iotplInterface.DOI_ACTIVITY1
         , iotplInterface.DOI_CARE_OF1
         , iotplInterface.DOI_PO_BOX1
         , iotplInterface.DOI_PO_BOX_NBR1
         , iotplInterface.DOI_COUNTY1
         , iotplInterface.DOI_CONTACT1
         , iotplInterface.DOI_CNTID1
         , iotplInterface.DOI_ZIPCODE1
         , iotplInterface.DOI_TOWN1
         , iotplInterface.DOI_STATE1
         , iotplInterface.DOI_ADD2_PER_KEY1
         , iotplInterface.DOI_ADD2_PER_KEY2
         , iotplInterface.DOI_NAME2
         , iotplInterface.DOI_FORENAME2
         , iotplInterface.DOI_ADDRESS2
         , iotplInterface.DOI_ACTIVITY2
         , iotplInterface.DOI_CARE_OF2
         , iotplInterface.DOI_PO_BOX2
         , iotplInterface.DOI_PO_BOX_NBR2
         , iotplInterface.DOI_COUNTY2
         , iotplInterface.DOI_CONTACT2
         , iotplInterface.DOI_CNTID2
         , iotplInterface.DOI_ZIPCODE2
         , iotplInterface.DOI_TOWN2
         , iotplInterface.DOI_STATE2
         , iotplInterface.DOI_ADD3_PER_KEY1
         , iotplInterface.DOI_ADD3_PER_KEY2
         , iotplInterface.DOI_NAME3
         , iotplInterface.DOI_FORENAME3
         , iotplInterface.DOI_ADDRESS3
         , iotplInterface.DOI_ACTIVITY3
         , iotplInterface.DOI_CARE_OF3
         , iotplInterface.DOI_PO_BOX3
         , iotplInterface.DOI_PO_BOX_NBR3
         , iotplInterface.DOI_COUNTY3
         , iotplInterface.DOI_CONTACT3
         , iotplInterface.DOI_CNTID3
         , iotplInterface.DOI_ZIPCODE3
         , iotplInterface.DOI_TOWN3
         , iotplInterface.DOI_STATE3
      from dual;
  end ExtractHeader;

  /**
  * procedure  ExtractPosition
  * Description
  *   procedure d'extraction de la position de document du xml
  */
  procedure ExtractPosition(iXml in xmltype, itplInterface in DOC_INTERFACE%rowtype, iotplInterfacePos in out DOC_INTERFACE_POSITION%rowtype)
  is
  begin
    select substr(extractvalue(iXml, '/POSITION/POSITION_NUMBER'), -5)
         , substr(extractvalue(iXml, '/POSITION/LOGISTICS_PART/PRODUCT_REFERENCES/PRODUCT_REFERENCE'), 0, 30)
         , extractvalue(iXml, '/POSITION/PRICE/VAT/RATE')
         , extractvalue(iXml, '/POSITION/PRICE/VAT/AMOUNT')
         , extractvalue(iXml, '/POSITION/LOGISTICS_PART/QUANTITY')
         , extractvalue(iXml, '/POSITION/LOGISTICS_PART/QUANTITY')
         , extractvalue(iXml, '/POSITION/PRICE/UNIT_AMOUNT')
         , extractvalue(iXml, '/POSITION/PRICE/POSITION_GROSS_AMOUNT_VAT_INCL')
         , extractvalue(iXml, '/POSITION/PRICE/POSITION_GROSS_AMOUNT_VAT_EXCL')
         , extractvalue(iXml, '/POSITION/PRICE/POSITION_NET_AMOUNT_VAT_EXCL')
         , extractvalue(iXml, '/POSITION/PRICE/POSITION_NET_AMOUNT_VAT_INCL')
         , substr(extractvalue(iXml, '/POSITION/LOGISTICS_PART/PRODUCT_REFERENCES/DESCRIPTION_SHORT'), 0, 50)
         , substr(extractvalue(iXml, '/POSITION/LOGISTICS_PART/PRODUCT_REFERENCES/DESCRIPTION_LONG'), 0, 4000)
         , substr(extractvalue(iXml, '/POSITION/LOGISTICS_PART/PRODUCT_REFERENCES/DESCRIPTION_FREE'), 0, 4000)
         , substr(extractvalue(iXml, '/POSITION/LOGISTICS_PART/DOCUMENT_REFERENCE_HISTORY/DOCUMENT_NUMBER'), 0, 30)
         , substr(extractvalue(iXml, '/POSITION/LOGISTICS_PART/DOCUMENT_REFERENCE_HISTORY/DOCUMENT_POSITION'), 0, 30)
         , substr(extractvalue(iXml, '/POSITION/POSITION_NUMBER'), 1, 50)
      into iotplInterfacePos.DOP_POS_NUMBER
         , iotplInterfacePos.DOP_MAJOR_REFERENCE
         , iotplInterfacePos.DOP_VAT_RATE
         , iotplInterfacePos.DOP_VAT_AMOUNT
         , iotplInterfacePos.DOP_QTY
         , iotplInterfacePos.DOP_QTY_VALUE
         , iotplInterfacePos.DOP_GROSS_UNIT_VALUE
         , iotplInterfacePos.DOP_GROSS_VALUE
         , iotplInterfacePos.DOP_GROSS_VALUE_EXCL
         , iotplInterfacePos.DOP_NET_VALUE_EXCL
         , iotplInterfacePos.DOP_NET_VALUE_INCL
         , iotplInterfacePos.DOP_SHORT_DESCRIPTION
         , iotplInterfacePos.DOP_LONG_DESCRIPTION
         , iotplInterfacePos.DOP_FREE_DESCRIPTION
         , iotplInterfacePos.DOP_FATHER_DMT_NUMBER
         , iotplInterfacePos.DOP_FATHER_POS_NUMBER
         , iotplInterfacePos.DOP_PARTNER_POS_NUMBER
      from dual;

    iotplInterfacePos.DOP_PARTNER_REFERENCE  := itplInterface.DOI_PARTNER_REFERENCE;
    iotplInterfacePos.DOP_PARTNER_NUMBER     := itplInterface.DOI_PARTNER_NUMBER;
    iotplInterfacePos.DOP_PARTNER_DATE       := itplInterface.DOI_PARTNER_DATE;
  end ExtractPosition;

  /**
  * procedure  ExtractDetail
  * Description
  *   procedure d'extraction du détail de position de document du xml
  */
  procedure ExtractDetail(iXml in xmltype, iotplInterfacePos in out DOC_INTERFACE_POSITION%rowtype)
  is
  begin
    iotplInterfacePos.DOP_QTY                       := 0;
    iotplInterfacePos.DOP_QTY_VALUE                 := 0;
    iotplInterfacePos.DOP_BASIS_DELAY               := null;
    iotplInterfacePos.DOP_INTERMEDIATE_DELAY        := null;
    iotplInterfacePos.DOP_FINAL_DELAY               := null;
    iotplInterfacePos.C_CHARACT1_TYPE               := null;
    iotplInterfacePos.C_CHARACT2_TYPE               := null;
    iotplInterfacePos.C_CHARACT3_TYPE               := null;
    iotplInterfacePos.C_CHARACT4_TYPE               := null;
    iotplInterfacePos.C_CHARACT5_TYPE               := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_1  := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_2  := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_3  := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_4  := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_5  := null;

    select extractvalue(iXml, '/POSITION_DETAIL/QUANTITY')
         , extractvalue(iXml, '/POSITION_DETAIL/QUANTITY')
         , to_date(extractvalue(iXml, '/POSITION_DETAIL/DELIVERY_DATE'), 'YYYY-MM-DD')
         , to_date(extractvalue(iXml, '/POSITION_DETAIL/DELIVERY_DATE'), 'YYYY-MM-DD')
         , to_date(extractvalue(iXml, '/POSITION_DETAIL/DELIVERY_DATE'), 'YYYY-MM-DD')
         , GetCharacteristicType(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[1]/@type') )
         , GetCharacteristicType(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[2]/@type') )
         , GetCharacteristicType(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[3]/@type') )
         , GetCharacteristicType(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[4]/@type') )
         , GetCharacteristicType(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[5]/@type') )
         , substr(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[1]'), 0, 30)
         , substr(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[2]'), 0, 30)
         , substr(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[3]'), 0, 30)
         , substr(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[4]'), 0, 30)
         , substr(extractvalue(iXml, '/POSITION_DETAIL/PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC[5]'), 0, 30)
      into iotplInterfacePos.DOP_QTY
         , iotplInterfacePos.DOP_QTY_VALUE
         , iotplInterfacePos.DOP_BASIS_DELAY
         , iotplInterfacePos.DOP_INTERMEDIATE_DELAY
         , iotplInterfacePos.DOP_FINAL_DELAY
         , iotplInterfacePos.C_CHARACT1_TYPE
         , iotplInterfacePos.C_CHARACT2_TYPE
         , iotplInterfacePos.C_CHARACT3_TYPE
         , iotplInterfacePos.C_CHARACT4_TYPE
         , iotplInterfacePos.C_CHARACT5_TYPE
         , iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_1
         , iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_2
         , iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_3
         , iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_4
         , iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_5
      from dual;

    iotplInterfacePos.C_CHARACT1_TYPE_ORG           := iotplInterfacePos.C_CHARACT1_TYPE;
    iotplInterfacePos.C_CHARACT2_TYPE_ORG           := iotplInterfacePos.C_CHARACT2_TYPE;
    iotplInterfacePos.C_CHARACT3_TYPE_ORG           := iotplInterfacePos.C_CHARACT3_TYPE;
    iotplInterfacePos.C_CHARACT4_TYPE_ORG           := iotplInterfacePos.C_CHARACT4_TYPE;
    iotplInterfacePos.C_CHARACT5_TYPE_ORG           := iotplInterfacePos.C_CHARACT5_TYPE;
    iotplInterfacePos.DOP_CHARACT_VALUE_1_ORG       := iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_1;
    iotplInterfacePos.DOP_CHARACT_VALUE_2_ORG       := iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_2;
    iotplInterfacePos.DOP_CHARACT_VALUE_3_ORG       := iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_3;
    iotplInterfacePos.DOP_CHARACT_VALUE_4_ORG       := iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_4;
    iotplInterfacePos.DOP_CHARACT_VALUE_5_ORG       := iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_5;
  end ExtractDetail;

  /**
  * procedure  ResetHeader
  * Description
  *   Efface les valeurs des ids de DOC_INTERFACE
  */
  procedure ResetHeader(iotplInterface in out DOC_INTERFACE%rowtype)
  is
  begin
    iotplInterface.DOC_GAUGE_ID                 := null;
    iotplInterface.PAC_SENDING_CONDITION_ID     := null;
    iotplInterface.PAC_PAYMENT_CONDITION_ID     := null;
    iotplInterface.ACS_VAT_DET_ACCOUNT_ID       := null;
    iotplInterface.ACS_FIN_ACC_S_PAYMENT_ID     := null;
    iotplInterface.ACS_FINANCIAL_CURRENCY_ID    := null;
    iotplInterface.PAC_DISTRIBUTION_CHANNEL_ID  := null;
    iotplInterface.PAC_SALE_TERRITORY_ID        := null;
    iotplInterface.PAC_THIRD_ID                 := null;
    iotplInterface.PAC_THIRD_DELIVERY_ID        := null;
    iotplInterface.PAC_THIRD_ACI_ID             := null;
    iotplInterface.PAC_THIRD_TARIFF_ID          := null;
    iotplInterface.DIC_TARIFF_ID                := null;
    iotplInterface.PAC_ADDRESS_ID               := null;
    iotplInterface.PAC_PAC_ADDRESS_ID           := null;
    iotplInterface.PAC2_PAC_ADDRESS_ID          := null;
    iotplInterface.PAC_REPRESENTATIVE_ID        := null;
    iotplInterface.PAC_REPR_ACI_ID              := null;
    iotplInterface.PAC_REPR_DELIVERY_ID         := null;
    iotplInterface.PC_LANG_ID                   := null;
    iotplInterface.PC_CNTRY_ID                  := null;
    iotplInterface.PC_2_PC_CNTRY_ID             := null;
    iotplInterface.PC__PC_CNTRY_ID              := null;
    iotplInterface.DOC_RECORD_ID                := null;
  end ResetHeader;

  /**
  * procedure ResetPosition
  * Description
  *   Efface les valeurs des ids de DOC_INTERFACE_POSITION
  */
  procedure ResetPosition(iotplInterfacePos in out DOC_INTERFACE_POSITION%rowtype)
  is
  begin
    iotplInterfacePos.DOC_GAUGE_ID                  := null;
    iotplInterfacePos.GCO_GOOD_ID                   := null;
    iotplInterfacePos.GCO_CHARACTERIZATION_ID       := null;
    iotplInterfacePos.GCO_GCO_CHARACTERIZATION_ID   := null;
    iotplInterfacePos.GCO2_GCO_CHARACTERIZATION_ID  := null;
    iotplInterfacePos.GCO3_GCO_CHARACTERIZATION_ID  := null;
    iotplInterfacePos.GCO4_GCO_CHARACTERIZATION_ID  := null;
    iotplInterfacePos.C_CHARACT1_TYPE               := null;
    iotplInterfacePos.C_CHARACT2_TYPE               := null;
    iotplInterfacePos.C_CHARACT3_TYPE               := null;
    iotplInterfacePos.C_CHARACT4_TYPE               := null;
    iotplInterfacePos.C_CHARACT5_TYPE               := null;
    iotplInterfacePos.ACS_TAX_CODE_ID               := null;
    iotplInterfacePos.STM_STOCK_ID                  := null;
    iotplInterfacePos.STM_LOCATION_ID               := null;
    iotplInterfacePos.STM_STM_STOCK_ID              := null;
    iotplInterfacePos.STM_STM_LOCATION_ID           := null;
    iotplInterfacePos.DOC_RECORD_ID                 := null;
    iotplInterfacePos.PAC_REPRESENTATIVE_ID         := null;
    iotplInterfacePos.PAC_REPR_ACI_ID               := null;
    iotplInterfacePos.PAC_REPR_DELIVERY_ID          := null;
    iotplInterfacePos.DOC_DOCUMENT_ID               := null;
    iotplInterfacePos.DOC_POSITION_ID               := null;
  end ResetPosition;

  /**
  * procedure ConvertHeaderData
  * Description
  *   Converti les valeurs reçu en clair dans l'XML en Id (niveau Doc)
  */
  procedure ConvertHeaderData(
    iotplInterface in out DOC_INTERFACE%rowtype
  , iOrigin        in     DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  , iResetData     in     integer default 0
  )
  is
    type GaugeType is record(
      GaugeId               DOC_GAUGE.DOC_GAUGE_ID%type
    , GaugeDicTariffId      DOC_INTERFACE.DIC_TARIFF_ID%type
    , GaugePacPaymentCondId DOC_INTERFACE.PAC_PAYMENT_CONDITION_ID%type
    , GaugeFinPayment       DOC_INTERFACE.ACS_FIN_ACC_S_PAYMENT_ID%type
    , AddressTypeId         DOC_GAUGE.DIC_ADDRESS_TYPE_ID%type
    , AddressType1Id        DOC_GAUGE.DIC_ADDRESS_TYPE1_ID%type
    , AddressType2Id        DOC_GAUGE.DIC_ADDRESS_TYPE2_ID%type
    , AdminDomain           DOC_GAUGE.C_ADMIN_DOMAIN%type
    );

    type ThirdType is record(
      ThirdID                DOC_INTERFACE.PAC_THIRD_ID%type
    , PerName                DOC_INTERFACE.DOI_PER_NAME%type
    , PerShortName           DOC_INTERFACE.DOI_PER_SHORT_NAME%type
    , PerKey1                DOC_INTERFACE.DOI_PER_KEY1%type
    , PerKey2                DOC_INTERFACE.DOI_PER_KEY2%type
    , DicTariffId            DOC_INTERFACE.DIC_TARIFF_ID%type
    , PacPaymentConditionId  DOC_INTERFACE.PAC_PAYMENT_CONDITION_ID%type
    , PacSendingConditionId  DOC_INTERFACE.PAC_SENDING_CONDITION_ID%type
    , DicTypeSubmissionId    DOC_INTERFACE.DIC_TYPE_SUBMISSION_ID%type
    , AcsVatDetAccountId     DOC_INTERFACE.ACS_VAT_DET_ACCOUNT_ID%type
    , AcsFinAccSPaymentId    DOC_INTERFACE.ACS_FIN_ACC_S_PAYMENT_ID%type
    , PacAdressId            DOC_INTERFACE.PAC_ADDRESS_ID%type
    , CTarificationMode      PAC_CUSTOM_PARTNER.C_TARIFFICATION_MODE%type
    , DicComplementaryDataId PAC_CUSTOM_PARTNER.DIC_COMPLEMENTARY_DATA_ID%type
    , CDeliveryTyp           PAC_CUSTOM_PARTNER.C_DELIVERY_TYP%type
    );

    p_configInterface  DOC_INTERFACE_CONFIG%rowtype;
    p_gaugeNumberingId DOC_GAUGE.DOC_GAUGE_NUMBERING_ID%type;
    p_gaugeToGenerate  GaugeType;
    p_gaugeConfig      GaugeType;
    p_third            ThirdType;
    p_representativeId DOC_INTERFACE.PAC_REPRESENTATIVE_ID%type;
    p_lookupPacSending DOC_INTERFACE_CONFIG.C_DOC_INTERFACE_ORIGIN%type;
    p_lookupPacPayment DOC_INTERFACE_CONFIG.C_DOC_INTERFACE_ORIGIN%type;
    p_addressInfo      DOC_DOCUMENT_FUNCTIONS.TDOC_ADDRESS_INFO;
    p_currDoiPos       DOC_INTERFACE_POSITION%rowtype;

    cursor crInterfacePosition(p_interfaceId DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select *
        from DOC_INTERFACE_POSITION
       where DOC_INTERFACE_ID = p_interfaceId;
  begin
    -- Réinitialisation des données
    if iResetData = 1 then
      ResetHeader(iotplInterface);
    end if;

    -- mise à jour du code erreur
    iotplInterface.C_DOI_INTERFACE_FAIL_REASON  := null;
    iotplInterface.DOI_ERROR                    := 0;
    iotplInterface.DOI_ERROR_MESSAGE            := null;

    -- Recherche du tiers donneur d'ordre
    if iotplInterface.PAC_THIRD_ID is null then
      begin
        select PER.PAC_PERSON_ID
          into iotplInterface.PAC_THIRD_ID
          from PAC_PERSON PER
         where PER.PER_KEY1 = iotplInterface.DOI_PER_KEY1;
      exception
        when no_data_found then
          iotplInterface.PAC_THIRD_ID  := null;
      end;

      if iotplInterface.PAC_THIRD_ID is null then
        iotplInterface.DOI_ERROR                    := 1;
        iotplInterface.C_DOI_INTERFACE_FAIL_REASON  := '010';
        iotplInterface.C_DOI_INTERFACE_STATUS       := '90';
        return;
      end if;
    end if;

    -- Recherche des informations liés au tiers (si c'est un client uniquement )
    begin
      select CUS.PAC_DISTRIBUTION_CHANNEL_ID
           , CUS.PAC_SALE_TERRITORY_ID
           , CUS.PAC_REPRESENTATIVE_ID
        into iotplInterface.PAC_DISTRIBUTION_CHANNEL_ID
           , iotplInterface.PAC_SALE_TERRITORY_ID
           , iotplInterface.PAC_REPRESENTATIVE_ID
        from PAC_CUSTOM_PARTNER CUS
       where CUS.PAC_CUSTOM_PARTNER_ID = iotplInterface.PAC_THIRD_ID;
    exception
      when no_data_found then
        iotplInterface.PAC_DISTRIBUTION_CHANNEL_ID  := null;
        iotplInterface.PAC_SALE_TERRITORY_ID        := null;
        iotplInterface.PAC_REPRESENTATIVE_ID        := null;
    end;

    -- Recherche du tiers de livraison
    if iotplInterface.PAC_THIRD_DELIVERY_ID is null then
      begin
        select PER.PAC_PERSON_ID
          into iotplInterface.PAC_THIRD_DELIVERY_ID
          from PAC_PERSON PER
         where PER.PER_KEY1 = iotplInterface.DOI_ADD2_PER_KEY1;
      exception
        when no_data_found then
          iotplInterface.PAC_THIRD_DELIVERY_ID  := null;
      end;

      if iotplInterface.PAC_THIRD_DELIVERY_ID is null then
        if iotplInterface.DOI_ADD2_PER_KEY1 is not null then
          iotplInterface.DOI_ERROR                    := 1;
          iotplInterface.C_DOI_INTERFACE_FAIL_REASON  := '011';
          iotplInterface.C_DOI_INTERFACE_STATUS       := '90';
          return;
        else
          iotplInterface.PAC_THIRD_DELIVERY_ID  := iotplInterface.PAC_THIRD_ID;
        end if;
      end if;
    end if;

    -- Recherche du représentant liés au tiers (si c'est un client uniquement )
    begin
      select CUS.PAC_REPRESENTATIVE_ID
        into iotplInterface.PAC_REPR_DELIVERY_ID
        from PAC_CUSTOM_PARTNER CUS
       where CUS.PAC_CUSTOM_PARTNER_ID = iotplInterface.PAC_THIRD_DELIVERY_ID;
    exception
      when no_data_found then
        iotplInterface.PAC_REPR_DELIVERY_ID  := null;
    end;

    -- Recherche du tiers de facturation
    if iotplInterface.PAC_THIRD_ACI_ID is null then
      begin
        select PER.PAC_PERSON_ID
          into iotplInterface.PAC_THIRD_ACI_ID
          from PAC_PERSON PER
         where PER.PER_KEY1 = iotplInterface.DOI_ADD3_PER_KEY1;
      exception
        when no_data_found then
          iotplInterface.PAC_THIRD_ACI_ID  := null;
      end;

      if iotplInterface.PAC_THIRD_ACI_ID is null then
        if iotplInterface.DOI_ADD3_PER_KEY1 is not null then
          iotplInterface.DOI_ERROR                    := 1;
          iotplInterface.C_DOI_INTERFACE_FAIL_REASON  := '012';
          iotplInterface.C_DOI_INTERFACE_STATUS       := '90';
          return;
        else
          iotplInterface.PAC_THIRD_ACI_ID  := iotplInterface.PAC_THIRD_ID;
        end if;
      end if;
    end if;

    -- Recherche du représentant liés au tiers (si c'est un client uniquement )
    begin
      select CUS.PAC_REPRESENTATIVE_ID
        into iotplInterface.PAC_REPR_ACI_ID
        from PAC_CUSTOM_PARTNER CUS
       where CUS.PAC_CUSTOM_PARTNER_ID = iotplInterface.PAC_THIRD_ACI_ID;
    exception
      when no_data_found then
        iotplInterface.PAC_REPR_ACI_ID  := null;
    end;

    -- Recherche des informations de configuration (doc_interface_config)
    if DOC_INTERFACE_CONFIG_FCT.get_config(iOrigin, iotplInterface.PAC_THIRD_ID, iotplInterface.DOI_DOCUMENT_TYPE, 'THIRD,DEF_VALUE', p_configInterface) = 0 then
      iotplInterface.DOI_ERROR                    := 1;
      iotplInterface.C_DOI_INTERFACE_FAIL_REASON  := '990';
      iotplInterface.DOI_ERROR_MESSAGE            := PCS.PC_FUNCTIONS.translateword('Impossible de trouver les informations de paramétrage');
      iotplInterface.DOI_ERROR_MESSAGE            := replace(iotplInterface.DOI_ERROR_MESSAGE, '#1', iOrigin);
      iotplInterface.DOI_ERROR_MESSAGE            := replace(iotplInterface.DOI_ERROR_MESSAGE, '#2', to_char(iotplInterface.PAC_THIRD_ID, 'FM999999999999') );
      iotplInterface.DOI_ERROR_MESSAGE            := replace(iotplInterface.DOI_ERROR_MESSAGE, '#3', iotplInterface.DOI_DOCUMENT_TYPE);
      iotplInterface.C_DOI_INTERFACE_STATUS       := '90';
      return;
    else
      if p_configInterface.doc_gauge_config_id is null then
        p_configInterface.doc_gauge_config_id  := DOC_INTERFACE_FCT.getGaugeId(PCS.PC_CONFIG.getConfig('DOC_CART_CONFIG_GAUGE') );
      end if;
    end if;

    -- Génération du numéro de document DOI (sur la base du gabarit de configuration)
    DOC_DOCUMENT_FUNCTIONS.GetDocumentNumber(p_configInterface.doc_gauge_config_id, p_gaugeNumberingId, iotplInterface.DOI_NUMBER);
    -- Attribution et récupération des données du gabarit à générer et du gabarit de configuration
    iotplInterface.DOC_GAUGE_ID                 := p_configInterface.DOC_GAUGE_DST_ID;
    p_gaugeToGenerate.GaugeId                   := p_configInterface.DOC_GAUGE_DST_ID;
    DOC_INTERFACE_FCT.getGaugeInfo(p_gaugeToGenerate.GaugeId
                                 , p_gaugeToGenerate.GaugeDicTariffId
                                 , p_gaugeToGenerate.GaugePacPaymentCondId
                                 , p_gaugeToGenerate.GaugeFinPayment
                                 , p_gaugeToGenerate.AddressTypeId
                                 , p_gaugeToGenerate.AddressType1Id
                                 , p_gaugeToGenerate.AddressType2Id
                                 , p_gaugeToGenerate.AdminDomain
                                  );
    p_gaugeconfig.GaugeId                       := p_configInterface.DOC_GAUGE_CONFIG_ID;
    DOC_INTERFACE_FCT.getGaugeInfo(p_gaugeconfig.GaugeId
                                 , p_gaugeconfig.GaugeDicTariffId
                                 , p_gaugeconfig.GaugePacPaymentCondId
                                 , p_gaugeconfig.GaugeFinPayment
                                 , p_gaugeconfig.AddressTypeId
                                 , p_gaugeconfig.AddressType1Id
                                 , p_gaugeconfig.AddressType2Id
                                 , p_gaugeconfig.AdminDomain
                                  );
    -- Recherche des données générales du tiers
    p_third.ThirdID                             := iotplInterface.PAC_THIRD_ID;

    if p_gaugeToGenerate.AdminDomain = 1 then
      DOC_INTERFACE_FCT.getSupplierInfo(p_third.ThirdID
                                      , p_third.PerName
                                      , p_third.PerShortName
                                      , p_third.PerKey1
                                      , p_third.PerKey2
                                      , p_third.DicTariffId
                                      , p_third.PacPaymentConditionId
                                      , p_third.PacSendingConditionId
                                      , p_third.DicTypeSubmissionId
                                      , p_third.AcsVatDetAccountId
                                      , p_third.AcsFinAccSPaymentId
                                      , p_third.PacAdressId
                                      , p_third.CTarificationMode
                                      , p_third.DicComplementaryDataId
                                      , p_third.CDeliveryTyp
                                       );
      p_lookupPacSending  := 'LOG-001-1';
      p_lookupPacPayment  := 'LOG-002-1';
    elsif p_gaugeToGenerate.AdminDomain = 2 then
      DOC_INTERFACE_FCT.getCustomInfo(p_third.ThirdID
                                    , p_third.PerName
                                    , p_third.PerShortName
                                    , p_third.PerKey1
                                    , p_third.PerKey2
                                    , p_third.DicTariffId
                                    , p_third.PacPaymentConditionId
                                    , p_third.PacSendingConditionId
                                    , p_third.DicTypeSubmissionId
                                    , p_third.AcsVatDetAccountId
                                    , p_third.AcsFinAccSPaymentId
                                    , p_third.PacAdressId
                                    , p_representativeId
                                    , p_third.CTarificationMode
                                    , p_third.DicComplementaryDataId
                                    , p_third.CDeliveryTyp
                                     );
      p_lookupPacSending  := 'LOG-001-2';
      p_lookupPacPayment  := 'LOG-002-2';
    end if;

    -- Recherche condition de livraison
    if iotplInterface.PAC_SENDING_CONDITION_ID is null then
      iotplInterface.PAC_SENDING_CONDITION_ID  :=
                             COM_LOOKUP_FUNCTIONS.convert_value(p_lookupPacSending, iotplInterface.PAC_THIRD_ID, iotplInterface.DOI_SEN_KEY, 'THIRD,DEF_VALUE');

      if iotplInterface.PAC_SENDING_CONDITION_ID is null then
        iotplInterface.PAC_SENDING_CONDITION_ID  := p_third.PacSendingConditionId;
      end if;
    end if;

    -- Recherche condition de paiement
    if iotplInterface.PAC_PAYMENT_CONDITION_ID is null then
      iotplInterface.PAC_PAYMENT_CONDITION_ID  :=
                           COM_LOOKUP_FUNCTIONS.convert_value(p_lookupPacPayment, iotplInterface.PAC_THIRD_ID, iotplInterface.DOI_PCO_DESCR, 'THIRD,DEF_VALUE');

      if iotplInterface.PAC_PAYMENT_CONDITION_ID is null then
        iotplInterface.PAC_PAYMENT_CONDITION_ID  := p_third.PacPaymentConditionId;
      end if;
    end if;

    -- Recherche décompte TVA / vient toujours du tiers
    if iotplInterface.ACS_VAT_DET_ACCOUNT_ID is null then
      iotplInterface.ACS_VAT_DET_ACCOUNT_ID  := p_third.AcsVatDetAccountId;
      iotplInterface.DIC_TYPE_SUBMISSION_ID  := p_third.DicTypeSubmissionId;
    end if;

    -- Recherche de la monnaie
    if iotplInterface.ACS_FINANCIAL_CURRENCY_ID is null then
      iotplInterface.ACS_FINANCIAL_CURRENCY_ID  :=
                          DOC_INTERFACE_FCT.get_acs_financial_currency(iotplInterface.PAC_THIRD_ID, iotplInterface.DOI_CURRENCY, p_gaugeToGenerate.AdminDomain);

      if iotplInterface.ACS_FINANCIAL_CURRENCY_ID is null then
        iotplInterface.DOI_ERROR                    := 1;
        iotplInterface.C_DOI_INTERFACE_STATUS       := '90';
        iotplInterface.C_DOI_INTERFACE_FAIL_REASON  := '100';
        return;
      end if;
    end if;

    -- Recherche partenaire tariffication
    if iotplInterface.PAC_THIRD_TARIFF_ID is null then
      iotplInterface.PAC_THIRD_TARIFF_ID  := iotplInterface.PAC_THIRD_ID;
    end if;

    if iotplInterface.DIC_TARIFF_ID is null then
      iotplInterface.DIC_TARIFF_ID  := p_third.DicTariffId;
    end if;

    -- Recherche méthode de paiement
    if iotplInterface.ACS_FIN_ACC_S_PAYMENT_ID is null then
      iotplInterface.ACS_FIN_ACC_S_PAYMENT_ID  := p_third.AcsFinAccSPaymentId;
    end if;

    if iotplInterface.ACS_FIN_ACC_S_PAYMENT_ID is null then
      iotplInterface.ACS_FIN_ACC_S_PAYMENT_ID  := p_gaugeToGenerate.GaugeFinPayment;
    end if;

    -- Tiers donneur d'ordre / recherche des informations de l'adresse
    if iotplInterface.PAC_ADDRESS_ID is null then
      DOC_DOCUMENT_FUNCTIONS.getDocAddress(null, p_gaugeToGenerate.AddressTypeId, iotplInterface.PAC_THIRD_ID, p_addressInfo);
      iotplInterface.PAC_ADDRESS_ID  := p_addressInfo.PAC_ADDRESS_ID;

      if (    iotplInterface.DOI_NAME1 is null
          and iotplInterface.DOI_FORENAME1 is null
          and iotplInterface.DOI_ADDRESS1 is null
          and iotplInterface.DOI_ACTIVITY1 is null
          and iotplInterface.DOI_CARE_OF1 is null
          and iotplInterface.DOI_PO_BOX1 is null
          and iotplInterface.DOI_PO_BOX_NBR1 is null
          and iotplInterface.DOI_COUNTY1 is null
          and iotplInterface.DOI_CONTACT1 is null
          and iotplInterface.DOI_CNTID1 is null
          and iotplInterface.DOI_ZIPCODE1 is null
          and iotplInterface.DOI_TOWN1 is null
          and iotplInterface.DOI_STATE1 is null
         ) then
        iotplInterface.DOI_NAME1        := p_addressInfo.DMT_NAME;
        iotplInterface.DOI_FORENAME1    := p_addressInfo.DMT_FORENAME;
        iotplInterface.DOI_ADDRESS1     := p_addressInfo.DMT_ADDRESS;
        iotplInterface.DOI_ACTIVITY1    := p_addressInfo.DMT_ACTIVITY;
        iotplInterface.DOI_CARE_OF1     := p_addressInfo.DMT_CARE_OF;
        iotplInterface.DOI_PO_BOX1      := p_addressInfo.DMT_PO_BOX;
        iotplInterface.DOI_PO_BOX_NBR1  := p_addressInfo.DMT_PO_BOX_NBR;
        iotplInterface.DOI_COUNTY1      := p_addressInfo.DMT_COUNTY;
        iotplInterface.DOI_CONTACT1     := p_addressInfo.DMT_CONTACT;
        iotplInterface.PC_CNTRY_ID      := p_addressInfo.PC_CNTRY_ID;
        iotplInterface.DOI_ZIPCODE1     := p_addressInfo.DMT_POSTCODE;
        iotplInterface.DOI_TOWN1        := p_addressInfo.DMT_TOWN;
        iotplInterface.DOI_STATE1       := p_addressInfo.DMT_STATE;
      else
        begin
          select PC_CNTRY_ID
            into iotplInterface.PC_CNTRY_ID
            from PCS.PC_CNTRY
           where CNTID = iotplInterface.DOI_CNTID1;
        exception
          when no_data_found then
            iotplInterface.PC_CNTRY_ID  := null;
        end;
      end if;
    end if;

    -- Tiers livraison / recherche des informations de l'adresse
    if iotplInterface.PAC_PAC_ADDRESS_ID is null then
      DOC_DOCUMENT_FUNCTIONS.getDocAddress(null, p_gaugeToGenerate.AddressType1Id, iotplInterface.PAC_THIRD_DELIVERY_ID, p_addressInfo);
      iotplInterface.PAC_PAC_ADDRESS_ID  := p_addressInfo.PAC_ADDRESS_ID;

      if (    iotplInterface.DOI_NAME2 is null
          and iotplInterface.DOI_FORENAME2 is null
          and iotplInterface.DOI_ADDRESS2 is null
          and iotplInterface.DOI_ACTIVITY2 is null
          and iotplInterface.DOI_CARE_OF2 is null
          and iotplInterface.DOI_PO_BOX2 is null
          and iotplInterface.DOI_PO_BOX_NBR2 is null
          and iotplInterface.DOI_COUNTY2 is null
          and iotplInterface.DOI_CONTACT2 is null
          and iotplInterface.DOI_CNTID2 is null
          and iotplInterface.DOI_ZIPCODE2 is null
          and iotplInterface.DOI_TOWN2 is null
          and iotplInterface.DOI_STATE2 is null
         ) then
        iotplInterface.DOI_NAME2        := p_addressInfo.DMT_NAME;
        iotplInterface.DOI_FORENAME2    := p_addressInfo.DMT_FORENAME;
        iotplInterface.DOI_ADDRESS2     := p_addressInfo.DMT_ADDRESS;
        iotplInterface.DOI_ACTIVITY2    := p_addressInfo.DMT_ACTIVITY;
        iotplInterface.DOI_CARE_OF2     := p_addressInfo.DMT_CARE_OF;
        iotplInterface.DOI_PO_BOX2      := p_addressInfo.DMT_PO_BOX;
        iotplInterface.DOI_PO_BOX_NBR2  := p_addressInfo.DMT_PO_BOX_NBR;
        iotplInterface.DOI_COUNTY2      := p_addressInfo.DMT_COUNTY;
        iotplInterface.DOI_CONTACT2     := p_addressInfo.DMT_CONTACT;
        iotplInterface.PC__PC_CNTRY_ID  := p_addressInfo.PC_CNTRY_ID;
        iotplInterface.DOI_ZIPCODE2     := p_addressInfo.DMT_POSTCODE;
        iotplInterface.DOI_TOWN2        := p_addressInfo.DMT_TOWN;
        iotplInterface.DOI_STATE2       := p_addressInfo.DMT_STATE;
      else
        begin
          select PC_CNTRY_ID
            into iotplInterface.PC__PC_CNTRY_ID
            from PCS.PC_CNTRY
           where CNTID = iotplInterface.DOI_CNTID2;
        exception
          when no_data_found then
            iotplInterface.PC__PC_CNTRY_ID  := null;
        end;
      end if;
    end if;

    -- Tiers facturation / recherche des informations de l'adresse
    if iotplInterface.PAC2_PAC_ADDRESS_ID is null then
      DOC_DOCUMENT_FUNCTIONS.getDocAddress(null, p_gaugeToGenerate.AddressType2Id, iotplInterface.PAC_THIRD_ACI_ID, p_addressInfo);
      iotplInterface.PAC2_PAC_ADDRESS_ID  := p_addressInfo.PAC_ADDRESS_ID;

      if (    iotplInterface.DOI_NAME3 is null
          and iotplInterface.DOI_FORENAME3 is null
          and iotplInterface.DOI_ADDRESS3 is null
          and iotplInterface.DOI_ACTIVITY3 is null
          and iotplInterface.DOI_CARE_OF3 is null
          and iotplInterface.DOI_PO_BOX3 is null
          and iotplInterface.DOI_PO_BOX_NBR3 is null
          and iotplInterface.DOI_COUNTY3 is null
          and iotplInterface.DOI_CONTACT3 is null
          and iotplInterface.DOI_CNTID3 is null
          and iotplInterface.DOI_ZIPCODE3 is null
          and iotplInterface.DOI_TOWN3 is null
          and iotplInterface.DOI_STATE3 is null
         ) then
        iotplInterface.DOI_NAME3         := p_addressInfo.DMT_NAME;
        iotplInterface.DOI_FORENAME3     := p_addressInfo.DMT_FORENAME;
        iotplInterface.DOI_ADDRESS3      := p_addressInfo.DMT_ADDRESS;
        iotplInterface.DOI_ACTIVITY3     := p_addressInfo.DMT_ACTIVITY;
        iotplInterface.DOI_CARE_OF3      := p_addressInfo.DMT_CARE_OF;
        iotplInterface.DOI_PO_BOX3       := p_addressInfo.DMT_PO_BOX;
        iotplInterface.DOI_PO_BOX_NBR3   := p_addressInfo.DMT_PO_BOX_NBR;
        iotplInterface.DOI_COUNTY3       := p_addressInfo.DMT_COUNTY;
        iotplInterface.DOI_CONTACT3      := p_addressInfo.DMT_CONTACT;
        iotplInterface.PC_2_PC_CNTRY_ID  := p_addressInfo.PC_CNTRY_ID;
        iotplInterface.DOI_ZIPCODE3      := p_addressInfo.DMT_POSTCODE;
        iotplInterface.DOI_TOWN3         := p_addressInfo.DMT_TOWN;
        iotplInterface.DOI_STATE3        := p_addressInfo.DMT_STATE;
      else
        begin
          select PC_CNTRY_ID
            into iotplInterface.PC_2_PC_CNTRY_ID
            from PCS.PC_CNTRY
           where CNTID = iotplInterface.DOI_CNTID3;
        exception
          when no_data_found then
            iotplInterface.PC_2_PC_CNTRY_ID  := null;
        end;
      end if;
    end if;

    -- Conversion des valeurs reçu en clair dans l'XML en Id niveau Position
    open crInterfacePosition(iotplInterface.DOC_INTERFACE_ID);

    loop
      fetch crInterfacePosition
       into p_currDoiPos;

      exit when crInterfacePosition%notfound;
      ConvertPositionData(p_currDoiPos, iotplInterface, p_configInterface, iResetData);

      -- Report des modifications dans la base de données
      update DOC_INTERFACE_POSITION
         set row = p_currDoiPos
       where DOC_INTERFACE_POSITION_ID = p_currDoiPos.DOC_INTERFACE_POSITION_ID;
    end loop;

    close crInterfacePosition;
  end ConvertHeaderData;

  /**
  * procedure ConvertPositionData
  * Description
  *   Converti les valeurs reçu en clair dans l'XML en Id (niveau Pos)
  */
  procedure ConvertPositionData(
    iotplInterfacePos   in out DOC_INTERFACE_POSITION%rowtype
  , iotplInterface      in out DOC_INTERFACE%rowtype
  , itplInterfaceConfig in     DOC_INTERFACE_CONFIG%rowtype
  , iResetData          in     integer default 0
  )
  is
    p_pdtStockManagement GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    p_manageChar         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    -- Réinitialisation des données
    if iResetData = 1 then
      ResetPosition(iotplInterfacePos);
    end if;

    -- Récupération des données à reprendre telles quel de doc_interface
    iotplInterfacePos.DOC_GAUGE_ID            := iotplInterface.DOC_GAUGE_ID;
    iotplInterfacePos.PAC_REPRESENTATIVE_ID   := iotplInterface.PAC_REPRESENTATIVE_ID;
    iotplInterfacePos.PAC_REPR_ACI_ID         := iotplInterface.PAC_REPR_ACI_ID;
    iotplInterfacePos.PAC_REPR_DELIVERY_ID    := iotplInterface.PAC_REPR_DELIVERY_ID;

    -- Type de position
    select DOC_GAUGE_POSITION_ID
      into iotplInterfacePos.DOC_GAUGE_POSITION_ID
      from DOC_GAUGE_POSITION
     where DOC_GAUGE_ID = iotplInterface.DOC_GAUGE_ID
       and C_GAUGE_TYPE_POS = '1'
       and GAP_DEFAULT = 1;

    -- Recherche référence principale du bien
    if iotplInterfacePos.GCO_GOOD_ID is null then
      iotplInterfacePos.GCO_GOOD_ID  :=
                            DOC_INTERFACE_POSITION_FCT.getGoodInfo(iotplInterfacePos.DOP_MAJOR_REFERENCE, 'internal', 'recipient', iotplInterface.PAC_THIRD_ID);

      if iotplInterfacePos.GCO_GOOD_ID is null then
        iotplInterface.DOI_ERROR                       := 1;
        iotplInterfacePos.DOP_ERROR                    := 1;
        iotplInterfacePos.C_DOP_INTERFACE_FAIL_REASON  := '100';
        iotplInterfacePos.C_DOP_INTERFACE_STATUS       := '90';
        iotplInterface.C_DOI_INTERFACE_STATUS          := '90';
        return;
      end if;
    end if;

    -- Prix
    iotplInterfacePos.DOP_USE_GOOD_PRICE      := itplInterfaceConfig.DOG_USE_GOOD_PRICE;
    iotplInterfacePos.DOP_NET_TARIFF          := itplInterfaceConfig.DOG_IS_NET_TARIFF;
    iotplInterfacePos.DOP_INCLUDE_TAX_TARIFF  := itplInterfaceConfig.DOG_INCLUDE_TAX_TARIFF;
    -- Remises et taxes
    iotplInterfacePos.DOP_POS_CHARGE_COPY     := 0;

    -- TVA
    if     iotplInterfacePos.DOP_VAT_RATE is not null
       and iotplInterfacePos.ACS_TAX_CODE_ID is null then
      iotplInterfacePos.ACS_TAX_CODE_ID  :=
        COM_LOOKUP_FUNCTIONS.convert_number_value(ivComLookupType    => 'LOG-003'
                                                , iThirdId           => iotplInterface.PAC_THIRD_ID
                                                , iNumberToConvert   => iotplInterfacePos.DOP_VAT_RATE
                                                , ivSearchPath       => 'THIRD,DEF_VALUE'
                                                 );
    end if;

    if iotplInterfacePos.ACS_TAX_CODE_ID is null then
      /* Récupération du code TVA du client */
      iotplInterfacePos.ACS_TAX_CODE_ID  :=
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(iCode              => 1
                                              , iThirdId           => iotplInterface.PAC_THIRD_ID
                                              , iGoodId            => iotplInterfacePos.GCO_GOOD_ID
                                              , iDiscountId        => null
                                              , iChargeId          => null
                                              , iAdminDomain       => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name   => 'DOC_GAUGE'
                                                                                                            , iv_column_name   => 'C_ADMIN_DOMAIN'
                                                                                                            , it_pk_value      => iotplInterface.DOC_GAUGE_ID
                                                                                                             )
                                              , iSubmissionType    => null
                                              , iMovementType      => DOC_I_LIB_GAUGE.getTypeMovementID(iGaugeID => iotplInterface.DOC_GAUGE_ID)
                                              , iVatDetAccountId   => null
                                               );
    end if;

    if iotplInterfacePos.ACS_TAX_CODE_ID is null then
      iotplInterface.DOI_ERROR                       := 1;
      iotplInterfacePos.DOP_ERROR                    := 1;
      iotplInterfacePos.C_DOP_INTERFACE_FAIL_REASON  := '130';
      iotplInterfacePos.C_DOP_INTERFACE_STATUS       := '90';
      iotplInterface.C_DOI_INTERFACE_STATUS          := '90';
      return;
    end if;

    -- Stocks
    begin
      select PDT_STOCK_MANAGEMENT
        into p_pdtStockManagement
        from GCO_PRODUCT
       where GCO_GOOD_ID = iotplInterfacePos.GCO_GOOD_ID;
    exception
      when no_data_found then
        p_pdtStockManagement  := null;
    end;

    DOC_INTERFACE_POSITION_FCT.GetStockAndLocation(iotplInterfacePos.GCO_GOOD_ID
                                                 , null
                                                 , null
                                                 , 1
                                                 , 0
                                                 , null
                                                 , p_pdtStockManagement
                                                 , iotplInterfacePos.STM_STOCK_ID
                                                 , iotplInterfacePos.STM_LOCATION_ID
                                                 , iotplInterfacePos.STM_STM_STOCK_ID
                                                 , iotplInterfacePos.STM_STM_LOCATION_ID
                                                  );

    -- Caractérisations
    begin
      select max(GCO_CHARACTERIZATION_ID)
        into p_manageChar
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iotplInterfacePos.GCO_GOOD_ID;
    exception
      when no_data_found then
        p_manageChar  := null;
    end;

    if p_manageChar is not null then
      -- Reprendre les types/valeurs de caract origine
      iotplInterfacePos.C_CHARACT1_TYPE               := iotplInterfacePos.C_CHARACT1_TYPE_ORG;
      iotplInterfacePos.C_CHARACT2_TYPE               := iotplInterfacePos.C_CHARACT2_TYPE_ORG;
      iotplInterfacePos.C_CHARACT3_TYPE               := iotplInterfacePos.C_CHARACT3_TYPE_ORG;
      iotplInterfacePos.C_CHARACT4_TYPE               := iotplInterfacePos.C_CHARACT4_TYPE_ORG;
      iotplInterfacePos.C_CHARACT5_TYPE               := iotplInterfacePos.C_CHARACT5_TYPE_ORG;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_1  := iotplInterfacePos.DOP_CHARACT_VALUE_1_ORG;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_2  := iotplInterfacePos.DOP_CHARACT_VALUE_2_ORG;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_3  := iotplInterfacePos.DOP_CHARACT_VALUE_3_ORG;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_4  := iotplInterfacePos.DOP_CHARACT_VALUE_4_ORG;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_5  := iotplInterfacePos.DOP_CHARACT_VALUE_5_ORG;
      -- Réorganiser les caractérisations
      ReorderCharac(iotplInterfacePos);
    else
      iotplInterfacePos.C_CHARACT1_TYPE               := null;
      iotplInterfacePos.C_CHARACT2_TYPE               := null;
      iotplInterfacePos.C_CHARACT3_TYPE               := null;
      iotplInterfacePos.C_CHARACT4_TYPE               := null;
      iotplInterfacePos.C_CHARACT5_TYPE               := null;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_1  := null;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_2  := null;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_3  := null;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_4  := null;
      iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_5  := null;
    end if;
  end ConvertPositionData;

  /**
  * procedure ReorderCharac
  * Description
  *   Remet les caractérisation dans l'ordre, en fonction de ce qui est
  *   défini sur le produit
  */
  procedure ReorderCharac(iotplInterfacePos in out DOC_INTERFACE_POSITION%rowtype)
  is
    cursor crValues(aDoiPosId DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type, aCharacType GCO_CHARACTERIZATION.C_CHARACT_TYPE%type)
    is
      select DOP1.C_CHARACT1_TYPE C_CHARACT_TYPE
           , DOP1.DOP_CHARACTERIZATION_VALUE_1 DOP_CHARACTERIZATION_VALUE
        from DOC_INTERFACE_POSITION DOP1
       where DOP1.DOC_INTERFACE_POSITION_ID = aDoiPosId
         and DOP1.C_CHARACT1_TYPE = aCharacType
      union all
      select DOP2.C_CHARACT2_TYPE C_CHARACT_TYPE
           , DOP2.DOP_CHARACTERIZATION_VALUE_2 DOP_CHARACTERIZATION_VALUE
        from DOC_INTERFACE_POSITION DOP2
       where DOP2.DOC_INTERFACE_POSITION_ID = aDoiPosId
         and DOP2.C_CHARACT2_TYPE = aCharacType
      union all
      select DOP3.C_CHARACT3_TYPE C_CHARACT_TYPE
           , DOP3.DOP_CHARACTERIZATION_VALUE_3 DOP_CHARACTERIZATION_VALUE
        from DOC_INTERFACE_POSITION DOP3
       where DOP3.DOC_INTERFACE_POSITION_ID = aDoiPosId
         and DOP3.C_CHARACT3_TYPE = aCharacType
      union all
      select DOP4.C_CHARACT4_TYPE C_CHARACT_TYPE
           , DOP4.DOP_CHARACTERIZATION_VALUE_4 DOP_CHARACTERIZATION_VALUE
        from DOC_INTERFACE_POSITION DOP4
       where DOP4.DOC_INTERFACE_POSITION_ID = aDoiPosId
         and DOP4.C_CHARACT4_TYPE = aCharacType
      union all
      select DOP5.C_CHARACT5_TYPE C_CHARACT_TYPE
           , DOP5.DOP_CHARACTERIZATION_VALUE_5 DOP_CHARACTERIZATION_VALUE
        from DOC_INTERFACE_POSITION DOP5
       where DOP5.DOC_INTERFACE_POSITION_ID = aDoiPosId
         and DOP5.C_CHARACT5_TYPE = aCharacType;

    tplValues  crValues%rowtype;
    vIndex     integer;
    vCharType  GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    vCharValue DOC_INTERFACE_POSITION.DOP_CHARACTERIZATION_VALUE_1%type;
    vCharID    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    vIndex                                          := 1;
    iotplInterfacePos.C_CHARACT1_TYPE               := null;
    iotplInterfacePos.C_CHARACT2_TYPE               := null;
    iotplInterfacePos.C_CHARACT3_TYPE               := null;
    iotplInterfacePos.C_CHARACT4_TYPE               := null;
    iotplInterfacePos.C_CHARACT5_TYPE               := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_1  := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_2  := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_3  := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_4  := null;
    iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_5  := null;

    -- Boucler la liste des caractérisations du bien
    for tplChar in (select   C_CHARACT_TYPE
                           , GCO_CHARACTERIZATION_ID
                        from GCO_CHARACTERIZATION
                       where GCO_GOOD_ID = iotplInterfacePos.GCO_GOOD_ID
                    order by GCO_CHARACTERIZATION_ID) loop
      vCharType   := null;
      vCharID     := null;
      vCharValue  := null;

      -- Pour les caractérisations de type "caractéristique" il faut effectuer
      -- un contrôle sur la valeur de caract avec la table GCO_CHARACTERISTIC_ELEMENT
      -- car un bien peut avoir plusieurs caractérisations de type "caractéristique"
      if tplChar.C_CHARACT_TYPE = '2' then
        begin
          select '2'
               , CHE.GCO_CHARACTERIZATION_ID
               , CHE.CHE_VALUE
            into vCharType
               , vCharID
               , vCharValue
            from GCO_CHARACTERISTIC_ELEMENT CHE
               , (select DOP1.DOP_CHARACTERIZATION_VALUE_1 DOP_CHARACTERIZATION_VALUE
                    from DOC_INTERFACE_POSITION DOP1
                   where DOP1.DOC_INTERFACE_POSITION_ID = iotplInterfacePos.DOC_INTERFACE_POSITION_ID
                     and DOP1.C_CHARACT1_TYPE = '2'
                  union all
                  select DOP2.DOP_CHARACTERIZATION_VALUE_2 DOP_CHARACTERIZATION_VALUE
                    from DOC_INTERFACE_POSITION DOP2
                   where DOP2.DOC_INTERFACE_POSITION_ID = iotplInterfacePos.DOC_INTERFACE_POSITION_ID
                     and DOP2.C_CHARACT2_TYPE = '2'
                  union all
                  select DOP3.DOP_CHARACTERIZATION_VALUE_3 DOP_CHARACTERIZATION_VALUE
                    from DOC_INTERFACE_POSITION DOP3
                   where DOP3.DOC_INTERFACE_POSITION_ID = iotplInterfacePos.DOC_INTERFACE_POSITION_ID
                     and DOP3.C_CHARACT3_TYPE = '2'
                  union all
                  select DOP4.DOP_CHARACTERIZATION_VALUE_4 DOP_CHARACTERIZATION_VALUE
                    from DOC_INTERFACE_POSITION DOP4
                   where DOP4.DOC_INTERFACE_POSITION_ID = iotplInterfacePos.DOC_INTERFACE_POSITION_ID
                     and DOP4.C_CHARACT4_TYPE = '2'
                  union all
                  select DOP5.DOP_CHARACTERIZATION_VALUE_5 DOP_CHARACTERIZATION_VALUE
                    from DOC_INTERFACE_POSITION DOP5
                   where DOP5.DOC_INTERFACE_POSITION_ID = iotplInterfacePos.DOC_INTERFACE_POSITION_ID
                     and DOP5.C_CHARACT5_TYPE = '2') DOP
           where CHE.GCO_CHARACTERIZATION_ID = tplChar.GCO_CHARACTERIZATION_ID
             and CHE.CHE_VALUE = DOP.DOP_CHARACTERIZATION_VALUE;
        exception
          when no_data_found then
            null;
        end;
      else
        -- Recherche des caractérisations qui sont de ce type
        open crValues(iotplInterfacePos.DOC_INTERFACE_POSITION_ID, tplChar.C_CHARACT_TYPE);

        fetch crValues
         into tplValues;

        if crValues%found then
          vCharType   := tplChar.C_CHARACT_TYPE;
          vCharID     := tplChar.GCO_CHARACTERIZATION_ID;
          vCharValue  := tplValues.DOP_CHARACTERIZATION_VALUE;
        end if;

        close crValues;
      end if;

      -- Initialiser les données de la table DOC_INTERFACE_POSITION selon la position
      -- de la caractérisation dans la liste des caract. du bien
      case vIndex
        when 1 then
          iotplInterfacePos.C_CHARACT1_TYPE               := vCharType;
          iotplInterfacePos.GCO_CHARACTERIZATION_ID       := vCharID;
          iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_1  := vCharValue;
        when 2 then
          iotplInterfacePos.C_CHARACT2_TYPE               := vCharType;
          iotplInterfacePos.GCO_GCO_CHARACTERIZATION_ID   := vCharID;
          iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_2  := vCharValue;
        when 3 then
          iotplInterfacePos.C_CHARACT3_TYPE               := vCharType;
          iotplInterfacePos.GCO2_GCO_CHARACTERIZATION_ID  := vCharID;
          iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_3  := vCharValue;
        when 4 then
          iotplInterfacePos.C_CHARACT4_TYPE               := vCharType;
          iotplInterfacePos.GCO3_GCO_CHARACTERIZATION_ID  := vCharID;
          iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_4  := vCharValue;
        when 5 then
          iotplInterfacePos.C_CHARACT5_TYPE               := vCharType;
          iotplInterfacePos.GCO4_GCO_CHARACTERIZATION_ID  := vCharID;
          iotplInterfacePos.DOP_CHARACTERIZATION_VALUE_5  := vCharValue;
      end case;

      vIndex      := vIndex + 1;
    end loop;
  end ReorderCharac;
end DOC_PRC_INTERFACE;
