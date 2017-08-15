--------------------------------------------------------
--  DDL for Package Body SHP_LIB_DOCUMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_LIB_DOCUMENT" 
as
  /**
  * Description
  *    Cette fonction retourne le statut du document dans le Shop en fonction du
  *    statut du son �tat dans l'ERP.
  */
  function getShopFromErpDocStatus(ivErpDocStatus in DOC_DOCUMENT.C_DOCUMENT_STATUS%type, inDmtBalanced in DOC_DOCUMENT.DMT_BALANCED%type)
    return SHP_TO_PUBLISH.STP_SHOP_DOC_STATUS%type
  is
    lvShopDocStatus SHP_TO_PUBLISH.STP_SHOP_DOC_STATUS%type;
  begin
    case ivErpDocStatus
      when '01' then   /* � confirmer */
        lvShopDocStatus  := '1';   --> Cr��
      when '02' then   /* � solder */
        lvShopDocStatus  := '5';   --> Valid�
      when '03' then   /* sold� partiellement */
        lvShopDocStatus  := '6';   --> Livr� partiellement
      when '04' then   /* liquid� */
        if inDmtBalanced = '0' then
          lvShopDocStatus  := '7';   --> Livr� compl�tement
        else   /* sold� manuellement */
          lvShopDocStatus  := '8';   --> Annul�
        end if;
    end case;

    return lvShopDocStatus;
  exception
    when others then
      return null;
  end getShopFromErpDocStatus;

  /**
  * Description
  *   Cette fonction retourne sous forme Binaire un XML contenant les statuts des documents
  *   dont la clef primaire est transimse en param�tre (ittDocumentIDs).
  */
  function GetDocumentStatusXml(
    ittDocumentIDs        in ID_TABLE_TYPE
  , ivVendorID            in varchar2
  , ivVendorKey           in varchar2
  , ivVendorContentType   in varchar2
  , ivDatasource4Document in varchar2
  )
    return clob
  as
    lxXmlData xmltype;
  begin
    select XMLElement("orders"
                    , SHP_LIB_VENDOR.getVendorXmltype(ivVendorID => ivVendorID, ivVendorKey => ivVendorKey, ivVendorContentType => ivVendorContentType)
                    , XMLAgg(SHP_LIB_DOCUMENT.getDocumentStatusXmlType(tbl.column_value, ivDatasource4Document) )
                     )
      into lxXmlData
      from table(PCS.IdTableTypeToTable(ittDocumentIDs) ) tbl;

    if lxXmlData is not null then
      return lxXmlData.getclobval();
    else
      return null;
    end if;
  end GetDocumentStatusXml;

  /**
  * Description
  *   Cette fonction retourne sous forme binaire le noeud XML "order" contenant
  *   les informations relatives au statut du document.
  */
  function getDocumentStatusXmlType(inDocDocumentID in SHP_TO_PUBLISH.STP_REC_ID%type, ivDatasource4Document in varchar2)
    return xmltype
  as
    lxXmlData xmltype;
  begin
    select XMLElement("order"
                    , XMLElement("shop_orderid", SHOP_ORDERID)
                    , XMLElement("external_orderid", EXTERNAL_ORDERID)
                    , XMLElement("status_code", SHOP_STATUS_CODE)
                    , XMLElement("update_datetime", UPDATE_DATETIME)
                     )
      into lxXmlData
      from table(getDocumentStatusData(inDocDocumentID, ivDatasource4Document) );

    return lxXmlData;
  end getDocumentStatusXmlType;

  /**
  * function getDocumentStatusData
  * Description
  *   Cette fonction retourne les donn�es du statut du document dont la clef
  *   primaire est transise en param�tre. Elle appelle la source de donn�es
  *   transmise en param�tre
  */
  function getDocumentStatusData(inDocDocumentID in SHP_TO_PUBLISH.STP_REC_ID%type, ivDatasource4Document in varchar2)
    return SHP_LIB_TYPES.ttDocumentStatus pipelined
  as
    cv               SYS_REFCURSOR;
    lvSqlQuery       varchar2(4000);
    ltDocumentStatus SHP_LIB_TYPES.tDocumentStatus;
  begin
    lvSqlQuery  :=
      'select SHOP_ORDERID
            , EXTERNAL_ORDERID
            , SHOP_STATUS_CODE
            , UPDATE_DATETIME
         from TABLE(' ||
      ivDatasource4Document ||
      '(' ||
      inDocDocumentID ||
      '))';

    open cv for lvSqlQuery;

    fetch cv
     into ltDocumentStatus;

    while cv%found loop
      pipe row(ltDocumentStatus);

      fetch cv
       into ltDocumentStatus;
    end loop;

    close cv;
  exception
    when no_data_needed then
      return;
  end getDocumentStatusData;
end SHP_LIB_DOCUMENT;
