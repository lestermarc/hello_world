--------------------------------------------------------
--  DDL for Package Body DOC_XML_PAYNET_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_XML_PAYNET_FUNCTIONS" 
/**
 * Générateur d'e-factures de document logistique, spécialisé pour PayNet.
 *
 * @version 1.1
 * @date 02/2008
 * @author ngomes
 * @author spfister
 *
 * Modifications:
 */
as
  /**
  * function GetPN2003A_DocCharges
  * Description
  *   Création d'un noeud xml pour le Paynet 2003A
  *   XML des Remises/Taxes/Frais du document
  */
  function GetPN2003A_DocCharges(aInfo in crGetPayNet2003AInfo%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    select XMLAgg(XMLElement("ALLOWANCE-OR-CHARGE"
                           , XMLAttributes(case
                                             when C_FINANCIAL_CHARGE = '02' then 'A'
                                             else 'C'
                                           end as "Type")
                           , XMLElement("Service-Code", XMLAttributes(case
                                                                        when C_FINANCIAL_CHARGE = '02' then 'DI'
                                                                        else 'HD'
                                                                      end as "Type") )
                           , XMLForest(XMLForest(substr(FCH_DESCRIPTION, 1, 35) as "Line-35") as "SERVICE-TEXT")
                           , XMLForest(case
                                         when C_CALCULATION_MODE in('2', '3', '4', '5', '7', '9') then FCH_RATE *(100 / decode(FCH_EXPRESS_IN, 0, 1) )
                                         else null
                                       end as "ALC-Percent"
                                      )
                           , XMLElement("ALC-AMOUNT"
                                      , XMLAttributes('25' as "Print-Status")
                                      , XMLElement("Amount", XMLAttributes(aInfo.CURRENCY as "Currency"), FCH_EXCL_AMOUNT)
                                       )
                           , XMLElement("ALC-BASE-AMOUNT", XMLElement("Amount", aInfo.FOO_DOCUMENT_TOTAL_AMOUNT) )
                           , XMLElement("TAX"
                                      , XMLElement("Rate", XMLAttributes('S' as "Category"), FCH_VAT_RATE)
                                      , XMLElement("Amount", XMLAttributes(aInfo.CURRENCY as "Currency"), FCH_VAT_TOTAL_AMOUNT)
                                       )
                            )
                 )
      into vXml
      from DOC_FOOT_CHARGE
     where DOC_FOOT_ID = aInfo.DOC_DOCUMENT_ID;

    return vXml;
  exception
    when others then
      return null;
  end GetPN2003A_DocCharges;

  /**
  * function GetPN2003A_PosCharges
  * Description
  *   Création d'un noeud xml pour le Paynet 2003A
  *   XML des Remises/Taxes de position
  */
  function GetPN2003A_PosCharges(aPositionID in DOC_POSITION.DOC_POSITION_ID%type, aCurrency in varchar2)
    return xmltype
  is
    vXml xmltype;
  begin
    select XMLAgg(XMLElement("ALLOWANCE-OR-CHARGE"
                           , XMLAttributes(case
                                             when C_FINANCIAL_CHARGE = '02' then 'A'
                                             else 'C'
                                           end as "Type")
                           , XMLElement("Service-Code", XMLAttributes(case
                                                                        when C_FINANCIAL_CHARGE = '02' then 'DI'
                                                                        else 'HD'
                                                                      end as "Type") )
                           , XMLForest(XMLForest(substr(PCH_DESCRIPTION, 1, 35) as "Line-35") as "SERVICE-TEXT")
                           , XMLForest(case
                                         when PCH_RATE is not null then PCH_RATE *(100 / PCH_EXPRESS_IN)
                                         else null
                                       end as "ALC-Percent")
                           , XMLElement("ALC-AMOUNT"
                                      , XMLAttributes('25' as "Print-Status")
                                      , XMLElement("Amount", XMLAttributes(aCurrency as "Currency"), PCH_AMOUNT)
                                       )
                            )
                 )
      into vXml
      from DOC_POSITION_CHARGE
     where DOC_POSITION_ID = aPositionID;

    return vXml;
  exception
    when others then
      return null;
  end GetPN2003A_PosCharges;

  /**
  * function GetPN2003A_IncludeContainer
  * Description
  *   Création d'un noeud xml pour le Paynet 2003A
  *   Noeud : /XML-FSCM-INVOICE-2003A/INVOICE/HEADER/REFERENCE/Back-Pack
  */
  function GetPN2003A_IncludeContainer(aInfo in crGetPayNet2003AInfo%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    -- Si le mode de présentation est
    -- 01 : Avec Bill Presentment, PDF intégré dans le XML
    if aInfo.C_ECS_BILL_PRESENTMENT = '01' then
      select case
               when CEB_PDF_FILE is not null then XMLElement("Back-Pack")
             end
        into vXml
        from COM_EBANKING
       where DOC_DOCUMENT_ID = aInfo.DOC_DOCUMENT_ID;
    end if;

    return vXml;
  exception
    when others then
      return null;
  end GetPN2003A_IncludeContainer;

  /**
  * function GetPN2003A_Header
  * Description
  *   Création d'un noeud xml pour le Paynet 2003A
  *   Noeud : /XML-FSCM-INVOICE-2003A/INVOICE/HEADER
  */
  function GetPN2003A_Header(aInfo in crGetPayNet2003AInfo%rowtype)
    return xmltype
  is
    vXml                  xmltype;
    vXml_OtherReference   xmltype;
    vXml_AllowanceCharge  xmltype;
    vXml_IncludeContainer xmltype;
  begin
    -- Données pour la référence du partenaire
    if     (aInfo.DMT_DATE_PARTNER_DOCUMENT is not null)
       and (aInfo.DMT_PARTNER_REFERENCE is not null) then
      select XMLElement("OTHER-REFERENCE"
                      , XMLAttributes('CR' as "Type")
                      , XMLElement("REFERENCE-DATE"
                                 , XMLElement("Reference-No", aInfo.DMT_PARTNER_REFERENCE)
                                 , XMLElement("Date", XMLAttributes('CCYYMMDD' as "Format"), aInfo.DMT_DATE_PARTNER_DOCUMENT)
                                  )
                       )
        into vXml_OtherReference
        from dual;
    end if;

    -- XML des Remises/Taxes/Frais du document
    vXml_AllowanceCharge  := GetPN2003A_DocCharges(aInfo);
    -- XML de la présence du Pdf de la facture
    vXml_IncludeContainer := GetPN2003A_IncludeContainer(aInfo);

    select XMLElement
                    ("HEADER"
                   , XMLElement("FUNCTION-FLAGS", XMLElement("Confirmation-Flag") )
                   , XMLElement("MESSAGE-REFERENCE"
                              , XMLElement("REFERENCE-DATE"
                                         , XMLElement("Reference-No", aInfo.DMT_NUMBER)
                                         , XMLElement("Date", XMLAttributes('CCYYMMDD' as "Format"), aInfo.TODAY_DATE)
                                          )
                               )
                   , XMLElement("PRINT-DATE", XMLElement("Date", XMLAttributes('CCYYMMDD' as "Format"), aInfo.DMT_DATE_DOCUMENT) )
                   , XMLElement("DELIVERY-DATE", XMLElement("Date", XMLAttributes('CCYYMMDD' as "Format"), aInfo.DMT_DATE_DELIVERY) )
                   , XMLElement("REFERENCE"
                              , XMLElement("INVOICE-REFERENCE"
                                         , XMLElement("REFERENCE-DATE"
                                                    , XMLElement("Reference-No", aInfo.DMT_NUMBER)
                                                    , XMLElement("Date", XMLAttributes('CCYYMMDD' as "Format"), aInfo.DMT_DATE_DOCUMENT)
                                                     )
                                          )
                       , vXml_IncludeContainer
                              , XMLElement("OTHER-REFERENCE"
                                         , XMLAttributes('ACL' as "Type")
                                         , XMLElement("REFERENCE-DATE"
                                                    , XMLElement("Reference-No", aInfo.DMT_REFERENCE)
                                                    , XMLElement("Date", XMLAttributes('CCYYMMDD' as "Format"), aInfo.DMT_DATE_DOCUMENT)
                                                     )
                                          )
                              , vXml_OtherReference
                               )
                   , XMLElement("BILLER"
                              , XMLElement("Tax-No", aInfo.COM_VATNO)
                              , XMLElement("Doc-Reference", XMLAttributes('ESR-NEU' as "Type"), aInfo.PAD_BVR_REFERENCE_NUM)
                              , XMLElement("PARTY-ID", XMLElement("Pid", aInfo.ECS_ACCOUNT) )
                              , XMLElement("NAME-ADDRESS"
                                         , XMLAttributes('COM' as "Format")
                                         , XMLForest(XMLForest(aInfo.BILLER_NAME_1 as "Line-35"
                                                             , aInfo.BILLER_NAME_2 as "Line-35"
                                                             , aInfo.BILLER_NAME_3 as "Line-35"
                                                             , aInfo.BILLER_NAME_4 as "Line-35"
                                                             , aInfo.BILLER_NAME_5 as "Line-35"
                                                              ) as "NAME"
                                                    )
                                         , XMLForest(XMLForest(aInfo.BILLER_STREET_1 as "Line-35"
                                                             , aInfo.BILLER_STREET_2 as "Line-35"
                                                             , aInfo.BILLER_STREET_3 as "Line-35"
                                                             , aInfo.BILLER_STREET_4 as "Line-35"
                                                             , aInfo.BILLER_STREET_5 as "Line-35"
                                                              ) as "STREET"
                                                    )
                                         , XMLForest(aInfo.BILLER_CITY as "City", aInfo.BILLER_ZIPCODE as "Zip", aInfo.BILLER_COUNTRY as "Country")
                                          )
                              , XMLElement("BANK-INFO"
                                         , XMLElement("Acct-No", aInfo.ACCT_NO)
                                         , XMLElement("BankId", XMLAttributes('BCNr-int' as "Type", 'CH' as "Country"), aInfo.BANK_ID)
                                          )
                               )
                   , XMLElement("PAYER"
                              , XMLElement("Tax-No", aInfo.THI_NO_TVA)
                              , XMLElement("PARTY-ID", XMLElement("Pid", aInfo.EBP_ACCOUNT) )
                              , XMLElement("NAME-ADDRESS"
                                         , XMLAttributes('COM' as "Format")
                                         , XMLForest(XMLForest(aInfo.PAYER_NAME_1 as "Line-35"
                                                             , aInfo.PAYER_NAME_2 as "Line-35"
                                                             , aInfo.PAYER_NAME_3 as "Line-35"
                                                             , aInfo.PAYER_NAME_4 as "Line-35"
                                                             , aInfo.PAYER_NAME_5 as "Line-35"
                                                              ) as "NAME"
                                                    )
                                         , XMLForest(XMLForest(aInfo.PAYER_STREET_1 as "Line-35"
                                                             , aInfo.PAYER_STREET_2 as "Line-35"
                                                             , aInfo.PAYER_STREET_3 as "Line-35"
                                                             , aInfo.PAYER_STREET_4 as "Line-35"
                                                             , aInfo.PAYER_STREET_5 as "Line-35"
                                                              ) as "STREET"
                                                    )
                                         , XMLForest(aInfo.PAYER_CITY as "City", aInfo.PAYER_ZIPCODE as "Zip", aInfo.PAYER_COUNTRY as "Country")
                                          )
                               )
                   , XMLForest(XMLForest(XMLConcat(XMLForest(XMLForest(aInfo.DELIV_NAME_1 as "Line-35"
                                                                     , aInfo.DELIV_NAME_2 as "Line-35"
                                                                     , aInfo.DELIV_NAME_3 as "Line-35"
                                                                     , aInfo.DELIV_NAME_4 as "Line-35"
                                                                     , aInfo.DELIV_NAME_5 as "Line-35"
                                                                      ) as "NAME"
                                                            )
                                                 , XMLForest(XMLForest(aInfo.DELIV_STREET_1 as "Line-35"
                                                                     , aInfo.DELIV_STREET_2 as "Line-35"
                                                                     , aInfo.DELIV_STREET_3 as "Line-35"
                                                                     , aInfo.DELIV_STREET_4 as "Line-35"
                                                                     , aInfo.DELIV_STREET_5 as "Line-35"
                                                                      ) as "STREET"
                                                            )
                                                 , XMLForest(aInfo.DELIV_CITY as "City", aInfo.DELIV_ZIPCODE as "Zip", aInfo.DELIV_COUNTRY as "Country")
                                                  ) as "NAME-ADDRESS"
                                        ) as "DELIVERY-PARTY"
                              )
                   , vXml_AllowanceCharge
                    )
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetPN2003A_Header;

  /**
  * Description
  *   Création du noeud LINE_ITEM pour Paynet 2003A, méthode privée
  *
  * @created pyvoirol 05.2012
  * @private
  * @param aInfo                : Curseur contenant les infos pour la création d'un xml au format PAYNET
  * @return : le noeud XML des Remises/Taxes/Frais du document
  */
  function p_GetPN2003A_LineItem(aInfo in crGetPayNet2003AInfo%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    select XMLAgg
             (XMLElement
                  ("LINE-ITEM"
                 , XMLAttributes(POS_NUMBER as "Line-Number")
                 , XMLElement("ITEM-ID", XMLElement("Item-Id", XMLAttributes('SA' as "Type"), substr(nvl(GOO_MAJOR_REFERENCE, POS_REFERENCE), 1, 35) ) )
                 , XMLElement("ITEM-DESCRIPTION"
                            , XMLElement("Item-Type-Code", 1011)
                            , XMLForest(substr(POS_SHORT_DESCRIPTION, 1, 35) as "Line-35", substr(POS_SHORT_DESCRIPTION, 36, 35) as "Line-35")
                             )
                 , case
                     when POS_PARTNER_NUMBER is not null
                      or POS_PARTNER_POS_NUMBER is not null
                      or POS_DATE_PARTNER_DOCUMENT is not null then XMLElement("ITEM-REFERENCE"
                                                                             , XMLAttributes('ON' as "Type")
                                                                             , XMLForest(XMLForest(POS_PARTNER_NUMBER as "Reference-No"
                                                                                                 , POS_PARTNER_POS_NUMBER as "Line-No"
                                                                                                 , POS_DATE_PARTNER_DOCUMENT as "Date"
                                                                                                  ) as "REFERENCE-DATE"
                                                                                        )
                                                                              )
                     else null
                   end
                 , XMLElement("Quantity"
                            , XMLAttributes('47' as "Type", UME_UOM_CODE as "Units")   -- Rechercher code UOM du dico unité mesure position
                            , POS_BASIS_QUANTITY
                             )
                 , XMLElement("Price", XMLAttributes('AAA' as "Type", 1 as "Basequantity"), POS_NET_UNIT_VALUE_INCL)
                 , XMLElement("Price", XMLAttributes('YYY' as "Type", 1 as "Basequantity"), POS_NET_UNIT_VALUE)
                 , XMLElement("ITEM-AMOUNT", XMLAttributes('38' as "Type"), XMLElement("Amount", XMLAttributes(aInfo.CURRENCY as "Currency"), POS_GROSS_VALUE) )
                 , XMLElement("ITEM-AMOUNT"
                            , XMLAttributes('66' as "Type")
                            , XMLElement("Amount", XMLAttributes(aInfo.CURRENCY as "Currency"), POS_NET_VALUE_EXCL)
                             )
                 , GetPN2003A_PosCharges(DOC_POSITION_ID, aInfo.CURRENCY)
                 , XMLElement("TAX"
                            , XMLElement("Rate", XMLAttributes('S' as "Category"), POS_VAT_RATE)
                            , XMLElement("Amount", XMLAttributes(aInfo.CURRENCY as "Currency"), POS_VAT_AMOUNT)
                             )
                  )
             )
      into vXml
      from (select   POS.POS_NUMBER
                   , POS.POS_BASIS_QUANTITY
                   , POS.POS_REFERENCE
                   , POS.POS_SHORT_DESCRIPTION
                   , POS.POS_PARTNER_NUMBER
                   , POS.POS_PARTNER_POS_NUMBER
                   , to_char(trunc(POS.POS_DATE_PARTNER_DOCUMENT), 'YYYYMMDD') POS_DATE_PARTNER_DOCUMENT
                   , POS.POS_NET_UNIT_VALUE_INCL
                   , POS.POS_NET_UNIT_VALUE
                   , POS.POS_GROSS_VALUE
                   , POS.POS_NET_VALUE_EXCL
                   , POS.DOC_POSITION_ID
                   , POS.POS_VAT_RATE
                   , POS.POS_VAT_AMOUNT
                   , GOO.GOO_MAJOR_REFERENCE
                   , UME.UME_UOM_CODE
                from DOC_POSITION POS
                   , GCO_GOOD GOO
                   , DIC_UNIT_OF_MEASURE UME
               where POS.DOC_DOCUMENT_ID = aInfo.DOC_DOCUMENT_ID
                 and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                 and POS.DIC_UNIT_OF_MEASURE_ID = UME.DIC_UNIT_OF_MEASURE_ID(+)
                 and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '5', '7', '8', '9', '10', '21')
            order by POS.POS_NUMBER);

    return vXml;
  end;

  /**
  * Description
  *   Création du noeud LINE_ITEM pour Paynet 2003A
  *
  *   NOTE :
  *    Le contenu du noeud LINE_ITEM peut être individualisé par la fonction
  *   MISE EN PLACE :
  *     1. Utilisation de l'objet de gestion "DOC_EDI_TYPE".
  *     2. Créer un "transfert de données"
  *        - type : export
  *        - méthode : E995
  *     3. Lier le "transfert de données" à un système d'échange de données de type "paynet"
  *     4. Ajouter un "paramètre de transfert"
  *        - nom du paramètre : "EXPORT_PROC.LINE_ITEM"
  *        - valeur du paramètre : nom de la fonction individualisée utilisée pour générer le noeud LINE_ITEM
  *        - la fonction reçoit doc_document_id en paramètre et retourne un type xmltype
  *
  * @created ngomes 02.2012
  * @lastUpdate AGE 21.02.2012
  * @private
  * @param aInfo                : Curseur contenant les infos pour la création d'un xml au format PAYNET
  * @param inPcExchangeSystemID : Clef primaire du système d'échange de données lié au document.
  * @return : le noeud XML des Remises/Taxes/Frais du document
  */
  function GetPN2003A_LineItem(aInfo in crGetPayNet2003AInfo%rowtype, inPcExchangeSystemID in PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type)
    return xmltype
  is
    vXml                xmltype;
    lvExternalIndivProc DOC_EDI_TYPE_PARAM.DEP_VALUE%type;
  begin
    /* Récupération du nom de la fonction individualisée.
       Si nulle, exécution standard, sinon, exécution de celle-ci. */
    begin
      select DEP_VALUE
        into lvExternalIndivProc
        from DOC_EDI_TYPE_PARAM
       where DOC_EDI_TYPE_ID = (select DOC_EDI_TYPE_ID
                                  from DOC_EDI_TYPE
                                 where PC_EXCHANGE_SYSTEM_ID = inPcExchangeSystemID)
         and upper(DEP_NAME) = 'EXPORT_PROC.LINE_ITEM';
    exception
      when no_data_found then
        lvExternalIndivProc  := null;
    end;

    /* Si proc Indiv. trouvée */
    if lvExternalIndivProc is not null then
      execute immediate 'select XMLAgg(' ||
                        lvExternalIndivProc ||
                        '(DOC_POSITION_ID))
                           from DOC_POSITION POS
                          where DOC_DOCUMENT_ID = ' ||
                        to_char(aInfo.DOC_DOCUMENT_ID, 'FM999999999999') ||
                        ' and POS.C_GAUGE_TYPE_POS in(''1'', ''2'', ''3'', ''5'', ''7'', ''8'', ''9'', ''10'', ''21'')' ||
                        ' order by POS.POS_NUMBER'
                   into vXml;
    else   /* Exécution standard */
      vXml  := p_GetPN2003A_LineItem(aInfo);
    end if;

    if vXml is null then
      select XMLElement("LINE-ITEM")
        into vxml
        from dual;
    end if;

    return vXml;
  exception
    when others then
      return null;
  end GetPN2003A_LineItem;

  /**
  * function GetPN2003A_Container
  * Description
  *   Création d'un noeud xml pour le Paynet 2003A
  *   Noeud : /XML-FSCM-INVOICE-2003A/INVOICE/SUMMARY/Back-Pack-Container
  */
  function GetPN2003A_Container(aInfo in crGetPayNet2003AInfo%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    --PCS.PC_ENCODING_FUNCTIONS.EncodeBase64(CEB_PDF_FILE)
    -- Si le mode de présentation est
    -- 01 : Avec Bill Presentment, PDF intégré dans le XML
    if aInfo.C_ECS_BILL_PRESENTMENT = '01' then
      -- On n'ajoute pas réellement le fichier pdf ici, car sinon on obtient l'erreur
      --   ORA-31167: XML nodes over 64K in size cannot be inserted
      select XMLForest(case
                         when CEB_PDF_FILE is not null then '[PCS_PDF_FILE_TO_REPLACE]'
                         else null
                       end as "Back-Pack-Container")
        into vXml
        from COM_EBANKING
       where DOC_DOCUMENT_ID = aInfo.DOC_DOCUMENT_ID;
    end if;

    return vXml;
  exception
    when others then
      return null;
  end GetPN2003A_Container;

  /**
  * function GetPN2003A_DocTax
  * Description
  *   Création d'un noeud xml pour le Paynet 2003A
  *   XML de la liste des TVA utilisées dans le document
  */
  function GetPN2003A_DocTax(aInfo in crGetPayNet2003AInfo%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    select XMLAgg(XMLElement("TAX"
                           , XMLElement("TAX-BASIS", XMLElement("Amount", XMLAttributes(aInfo.CURRENCY as "Currency"), VDA_LIABLE_AMOUNT) )
                           , XMLElement("Rate", XMLAttributes('S' as "Category"), VDA_VAT_RATE)
                           , XMLElement("Amount", XMLAttributes(aInfo.CURRENCY as "Currency"), VDA_VAT_TOTAL_AMOUNT)
                            )
                 )
      into vXml
      from DOC_VAT_DET_ACCOUNT
     where DOC_FOOT_ID = aInfo.DOC_DOCUMENT_ID;

    return vXml;
  exception
    when others then
      return null;
  end GetPN2003A_DocTax;

  /**
  * function GetPN2003A_Summary
  * Description
  *   Création d'un noeud xml pour le Paynet 2003A
  *   Noeud : /XML-FSCM-INVOICE-2003A/INVOICE/SUMMARY
  */
  function GetPN2003A_Summary(aInfo in crGetPayNet2003AInfo%rowtype)
    return xmltype
  is
    vXml           xmltype;
    vXml_Container xmltype;
    vXml_Tax       xmltype;
  begin
    vXml_Container  := GetPN2003A_Container(aInfo);
    vXml_Tax        := GetPN2003A_DocTax(aInfo);

    select XMLElement("SUMMARY"
                    , XMLElement("INVOICE-AMOUNT"
                               , XMLAttributes('25' as "Print-Status")
                               , XMLElement("Amount", XMLAttributes(aInfo.CURRENCY as "Currency"), aInfo.FOO_DOCUMENT_TOTAL_AMOUNT)
                                )
                    , XMLElement("VAT-AMOUNT"
                               , XMLAttributes('25' as "Print-Status")
                               , XMLElement("Amount", XMLAttributes(aInfo.CURRENCY as "Currency"), aInfo.FOO_TOTAL_VAT_AMOUNT)
                                )
                    , XMLElement("EXTENDED-AMOUNT", XMLAttributes('79' as "Type"), XMLElement("Amount", aInfo.EXTENDED_AMOUNT) )
                    , vXml_Tax
                    , XMLElement("PAYMENT-TERMS"
                               , XMLElement("BASIC"
                                          , XMLAttributes(case
                                                            when aInfo.C_TYPE_SUPPORT in('50', '51', '56') then 'NPY'
                                                            when aInfo.C_BVR_GENERATION_METHOD = '02' then 'ESP'
                                                            when aInfo.C_BVR_GENERATION_METHOD = '03' then 'ESR'
                                                          end as "Payment-Type"
                                                        , '1' as "Terms-Type"
                                                         )
                                          , XMLElement("TERMS", XMLElement("Date", aInfo.PAD_PAYMENT_DATE) )
                                           )
                                )
                    , vXml_Container
                     )
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetPN2003A_Summary;

  /**
  * function GetPN2003A_Invoice
  * Description
  *   Création d'un noeud xml pour le Paynet 2003A
  *   Noeud : /XML-FSCM-INVOICE-2003A/INVOICE
  */
  function GetPN2003A_Invoice(aInfo in crGetPayNet2003AInfo%rowtype, inPcExchangeSystemID in PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type)
    return xmltype
  is
    vXml          xmltype;
    vXml_Header   xmltype;
    vXml_LineItem xmltype;
    vXml_Summary  xmltype;
  begin
    -- Création du noeud xml : /XML-FSCM-INVOICE-2003A/INVOICE/HEADER
    vXml_Header    := GetPN2003A_Header(aInfo);
    -- Création du noeud xml : /XML-FSCM-INVOICE-2003A/INVOICE/LINE-ITEM
    vXml_LineItem  := GetPN2003A_LineItem(aInfo => aInfo, inPcExchangeSystemID => inPcExchangeSystemID);
    -- Création du noeud xml : /XML-FSCM-INVOICE-2003A/INVOICE/SUMMARY
    vXml_Summary   := GetPN2003A_Summary(aInfo);

    select XMLConcat(vXml_Header, vXml_LineItem, vXml_Summary)
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetPN2003A_Invoice;

  /**
  * function GetPayNet2003A_Clob
  * Description
  *   Création d'un xml pour le format PayNet 2003A
  */
  function GetPayNet2003A_Clob(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return clob
  is
    vXml_Interchange     xmltype;
    vXml_Invoice         xmltype;
    vClob                clob;
    vClobTmp             clob;
    vClob_Container      clob;
    tplInfo              crGetPayNet2003AInfo%rowtype;
    lnPcExchangeSystemID PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type;
  begin
    open crGetPayNet2003AInfo(aDocumentID);

    fetch crGetPayNet2003AInfo
     into tplInfo;

    close crGetPayNet2003AInfo;

    if tplInfo.DOC_DOCUMENT_ID is not null then
      -- Récupération de la clef primaire du système d'échange.
      select PC_EXCHANGE_SYSTEM_ID
        into lnPcExchangeSystemID
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = tplInfo.DOC_DOCUMENT_ID;

      -- Création du noeud xml : /XML-FSCM-INVOICE-2003A/INVOICE
      vXml_Invoice  := GetPN2003A_Invoice(aInfo => tplInfo, inPcExchangeSystemID => lnPcExchangeSystemID);

      select '<!DOCTYPE XML-FSCM-INVOICE-2003A SYSTEM "XML-FSCM-INVOICE-2003A.DTD">' ||
             XMLElement("XML-FSCM-INVOICE-2003A"
                      , XMLElement("INTERCHANGE"
                                 , XMLElement("IC-SENDER", XMLElement("Pid", tplInfo.ECS_ACCOUNT) )
                                 , XMLElement("IC-RECEIVER", XMLElement("Pid", '41010106799303734') )
                                 , XMLElement("IC-Ref", tplInfo.CEB_TRANSACTION_ID)
                                  )
                      , XMLElement("INVOICE", XMLAttributes(tplInfo.DOC_TYPE as "Type"), vXml_Invoice)
                       ).GetClobVal()
        into vClob
        from dual;
    end if;

    -- Remplacer la balise Confirmation-Flag selon les normes PayNet
    select replace(vClob, '<Confirmation-Flag></Confirmation-Flag>', '<Confirmation-Flag/>')
      into vClob
      from dual;

    -- Ajouter manuellement le fichier PDF
    if instr(vClob, '[PCS_PDF_FILE_TO_REPLACE]') > 0 then
      select PCS.PC_ENCODING_FUNCTIONS.EncodeBase64(CEB_PDF_FILE)
        into vClob_Container
        from COM_EBANKING
       where DOC_DOCUMENT_ID = tplInfo.DOC_DOCUMENT_ID;

      vClobTmp  := substr(vClob, 1, instr(vClob, '[PCS_PDF_FILE_TO_REPLACE]') - 1);
      vClob     := vClobTmp || vClob_Container || '</Back-Pack-Container></SUMMARY></INVOICE></XML-FSCM-INVOICE-2003A>';
    end if;

    return vClob;
  exception
    when others then
      null;
  end GetPayNet2003A_Clob;

  /**
  * function GetPayNet2003A_XMLType
  * Description
  *   Création d'un xml pour le format PayNet 2003A
  */
  function GetPayNet2003A_XMLType(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return xmltype
  is
  begin
    return xmltype(GetPayNet2003A_Clob(aDocumentID) );
  end GetPayNet2003A_XMLType;

  function GetDeliveryDate(in_document_id in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return date
  is
    ld_document date;
  begin
    select DMT_DATE_DOCUMENT
      into ld_document
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = in_document_id;

    return ld_document;
  exception
    when no_data_found then
      return null;
  end;
end DOC_XML_PAYNET_FUNCTIONS;
