--------------------------------------------------------
--  DDL for Package Body ACI_XML_DOC_INTEGRATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_XML_DOC_INTEGRATE" 
as
  type TACI_EXPIRY is table of ACI_EXPIRY%rowtype
    index by binary_integer;

  type TACI_DET_PAYMENT is table of ACI_DET_PAYMENT%rowtype
    index by binary_integer;

  type TACI_FINANCIAL_IMPUTATION is table of ACI_FINANCIAL_IMPUTATION%rowtype
    index by binary_integer;

  type TACI_MGM_IMPUTATION is table of ACI_MGM_IMPUTATION%rowtype
    index by binary_integer;

  type TACI_PART_IMPUTATION is table of ACI_PART_IMPUTATION%rowtype
    index by binary_integer;

  type TACI_REMINDER is table of ACI_REMINDER%rowtype
    index by binary_integer;

  type TACI_REMINDER_TEXT is table of ACI_REMINDER_TEXT%rowtype
    index by binary_integer;

  -- Monnaie locale de la société cible (utilisée pour l'importation d'un XML)
  vTgtCompLocalCurr varchar2(5);
  -- Clé unique du catalogue document pour la recherche du numéro de période comptable de la société cible
  vCAT_KEY          ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type;

  /**
  * procedure Extract_ACI_DOCUMENT
  * Description
  *   Méthode pour extraire les données de la table ACI_DOCUMENT de l'XML
  */
  procedure Extract_ACI_DOCUMENT(aDOC_Row out nocopy ACI_DOCUMENT%rowtype, aXML in xmltype)
  is
    vXPath       varchar2(2000) default '/ACI_DOCUMENT/';
    vLocalCurr   varchar2(5)    default 'NULL';
    vForeignCurr varchar2(5)    default 'NULL';
  begin
    -- Les champs C_INTERFACE_CONTROL et DOC_INTEGRATION_DATE ne doivent pas être repris.
    -- C'est le traitement d'intégration qui s'en charge
    select ACI_ID_SEQ.nextval
         , extractvalue(aXML, vXPath || 'ACC_NUMBER')
         , extractvalue(aXML, vXPath || 'C_FAIL_REASON')
         , extractvalue(aXML, vXPath || 'C_INTERFACE_ORIGIN')
         , extractvalue(aXML, vXPath || 'C_STATUS_DOCUMENT')
         , extractvalue(aXML, vXPath || 'C_CURR_RATE_COVER_TYPE')
         , extractvalue(aXML, vXPath || 'CAT_KEY')
         , extractvalue(aXML, vXPath || 'CAT_KEY_PMT')
         , extractvalue(aXML, vXPath || 'COM_NAME_ACT')
         , extractvalue(aXML, vXPath || 'COM_NAME_DOC')
         , extractvalue(aXML, vXPath || 'CURRENCY')
         , extractvalue(aXML, vXPath || 'DIC_ACT_DOC_FREE_CODE1_ID')
         , extractvalue(aXML, vXPath || 'DIC_ACT_DOC_FREE_CODE2_ID')
         , extractvalue(aXML, vXPath || 'DIC_ACT_DOC_FREE_CODE3_ID')
         , extractvalue(aXML, vXPath || 'DIC_ACT_DOC_FREE_CODE4_ID')
         , extractvalue(aXML, vXPath || 'DIC_ACT_DOC_FREE_CODE5_ID')
         , extractvalue(aXML, vXPath || 'DIC_DOC_DESTINATION_ID')
         , extractvalue(aXML, vXPath || 'DIC_DOC_SOURCE_ID')
         , extractvalue(aXML, vXPath || 'DOC_CCP_TAX')
         , to_number(extractvalue(aXML, vXPath || 'DOC_CHARGES_LC') )
         , extractvalue(aXML, vXPath || 'DOC_COMMENT')
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_DOCUMENT_DATE') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_DOCUMENT_ID') )
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_EFFECTIVE_DATE') )
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_ESTABL_DATE') )
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_EXECUTIVE_DATE') )
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_FREE_DATE1') )
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_FREE_DATE2') )
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_FREE_DATE3') )
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_FREE_DATE4') )
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_FREE_DATE5') )
         , extractvalue(aXML, vXPath || 'DOC_FREE_MEMO1')
         , extractvalue(aXML, vXPath || 'DOC_FREE_MEMO2')
         , extractvalue(aXML, vXPath || 'DOC_FREE_MEMO3')
         , extractvalue(aXML, vXPath || 'DOC_FREE_MEMO4')
         , extractvalue(aXML, vXPath || 'DOC_FREE_MEMO5')
         , to_number(extractvalue(aXML, vXPath || 'DOC_FREE_NUMBER1') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_FREE_NUMBER2') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_FREE_NUMBER3') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_FREE_NUMBER4') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_FREE_NUMBER5') )
         , extractvalue(aXML, vXPath || 'DOC_FREE_TEXT1')
         , extractvalue(aXML, vXPath || 'DOC_FREE_TEXT2')
         , extractvalue(aXML, vXPath || 'DOC_FREE_TEXT3')
         , extractvalue(aXML, vXPath || 'DOC_FREE_TEXT4')
         , extractvalue(aXML, vXPath || 'DOC_FREE_TEXT5')
         , extractvalue(aXML, vXPath || 'DOC_GRP_KEY')
         , extractvalue(aXML, vXPath || 'DOC_NUMBER')
         , to_number(extractvalue(aXML, vXPath || 'DOC_ORDER_NO') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_PAID_AMOUNT_EUR') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_PAID_AMOUNT_FC') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_PAID_AMOUNT_LC') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_TOTAL_AMOUNT_DC') )
         , to_number(extractvalue(aXML, vXPath || 'DOC_TOTAL_AMOUNT_EUR') )
         , REP_UTILS.ReplicatorDateToDate(extractvalue(aXML, vXPath || 'DOC_XML_DOC_DATE') )
         , aXML.GetClobVal()
         , to_number(extractvalue(aXML, vXPath || 'FYE_NO_EXERCICE') )
         , extractvalue(aXML, vXPath || 'TYP_KEY')
         , extractvalue(aXML, vXPath || 'VAT_CURRENCY')
         , to_number(extractvalue(aXML, vXPath || 'STM_STOCK_MOVEMENT_ID') )
         , sysdate
         , PCS.PC_I_LIB_SESSION.GetUserIni
      into aDOC_Row.ACI_DOCUMENT_ID
         , aDOC_Row.ACC_NUMBER
         , aDOC_Row.C_FAIL_REASON
         , aDOC_Row.C_INTERFACE_ORIGIN
         , aDOC_Row.C_STATUS_DOCUMENT
         , aDOC_Row.C_CURR_RATE_COVER_TYPE
         , aDOC_Row.CAT_KEY
         , aDOC_Row.CAT_KEY_PMT
         , aDOC_Row.COM_NAME_ACT
         , aDOC_Row.COM_NAME_DOC
         , aDOC_Row.CURRENCY
         , aDOC_Row.DIC_ACT_DOC_FREE_CODE1_ID
         , aDOC_Row.DIC_ACT_DOC_FREE_CODE2_ID
         , aDOC_Row.DIC_ACT_DOC_FREE_CODE3_ID
         , aDOC_Row.DIC_ACT_DOC_FREE_CODE4_ID
         , aDOC_Row.DIC_ACT_DOC_FREE_CODE5_ID
         , aDOC_Row.DIC_DOC_DESTINATION_ID
         , aDOC_Row.DIC_DOC_SOURCE_ID
         , aDOC_Row.DOC_CCP_TAX
         , aDOC_Row.DOC_CHARGES_LC
         , aDOC_Row.DOC_COMMENT
         , aDOC_Row.DOC_DOCUMENT_DATE
         , aDOC_Row.DOC_DOCUMENT_ID
         , aDOC_Row.DOC_EFFECTIVE_DATE
         , aDOC_Row.DOC_ESTABL_DATE
         , aDOC_Row.DOC_EXECUTIVE_DATE
         , aDOC_Row.DOC_FREE_DATE1
         , aDOC_Row.DOC_FREE_DATE2
         , aDOC_Row.DOC_FREE_DATE3
         , aDOC_Row.DOC_FREE_DATE4
         , aDOC_Row.DOC_FREE_DATE5
         , aDOC_Row.DOC_FREE_MEMO1
         , aDOC_Row.DOC_FREE_MEMO2
         , aDOC_Row.DOC_FREE_MEMO3
         , aDOC_Row.DOC_FREE_MEMO4
         , aDOC_Row.DOC_FREE_MEMO5
         , aDOC_Row.DOC_FREE_NUMBER1
         , aDOC_Row.DOC_FREE_NUMBER2
         , aDOC_Row.DOC_FREE_NUMBER3
         , aDOC_Row.DOC_FREE_NUMBER4
         , aDOC_Row.DOC_FREE_NUMBER5
         , aDOC_Row.DOC_FREE_TEXT1
         , aDOC_Row.DOC_FREE_TEXT2
         , aDOC_Row.DOC_FREE_TEXT3
         , aDOC_Row.DOC_FREE_TEXT4
         , aDOC_Row.DOC_FREE_TEXT5
         , aDOC_Row.DOC_GRP_KEY
         , aDOC_Row.DOC_NUMBER
         , aDOC_Row.DOC_ORDER_NO
         , aDOC_Row.DOC_PAID_AMOUNT_EUR
         , aDOC_Row.DOC_PAID_AMOUNT_FC
         , aDOC_Row.DOC_PAID_AMOUNT_LC
         , aDOC_Row.DOC_TOTAL_AMOUNT_DC
         , aDOC_Row.DOC_TOTAL_AMOUNT_EUR
         , aDOC_Row.DOC_XML_DOC_DATE
         , aDOC_Row.DOC_XML_DOCUMENT
         , aDOC_Row.FYE_NO_EXERCICE
         , aDOC_Row.TYP_KEY
         , aDOC_Row.VAT_CURRENCY
         , aDOC_Row.STM_STOCK_MOVEMENT_ID
         , aDOC_Row.A_DATECRE
         , aDOC_Row.A_IDCRE
      from dual;

    -- Valeur du contrôle du document ACI ->  3 = A contrôler
    aDOC_Row.C_INTERFACE_CONTROL  := '3';
    -- Initialiser la variable globale contenant la clé unique du catalogue
    vCAT_KEY                      := aDOC_Row.CAT_KEY;

    begin
      -- Cascade pour la recherche des monnaies pour les montants ACI_DOCUMENT
      --  1. Monnaies sur ACI_PART_IMPUTATION
      --  2. Monnaies sur ACI_FINANCIAL_IMPUTATION pour la ligne ayant le IMF_PRIMARY = 1

      --  1. Monnaies sur ACI_PART_IMPUTATION
      vXPath  := replace('/ACI_DOCUMENT/ACI_PART_IMPUTATION/LIST_ITEM[###]/', '###', to_char(1, 'FM999') );

      select extractvalue(aXML, vXPath || 'CURRENCY2')
           , extractvalue(aXML, vXPath || 'CURRENCY1')
        into vLocalCurr
           , vForeignCurr
        from dual;

      -- Pas de monnaies trouvées sur ACI_PART_IMPUTATION
      --  2. Monnaies sur ACI_FINANCIAL_IMPUTATION pour la ligne ayant le IMF_PRIMARY = 1
      if nvl(vLocalCurr, 'NULL') = 'NULL' then
        begin
          select CURRENCY2
               , CURRENCY1
            into vLocalCurr
               , vForeignCurr
            from (select extractvalue(column_value, '/LIST_ITEM/CURRENCY1') CURRENCY1
                       , extractvalue(column_value, '/LIST_ITEM/CURRENCY2') CURRENCY2
                       , to_number(extractvalue(column_value, '/LIST_ITEM/IMF_PRIMARY') ) IMF_PRIMARY
                    from table(xmlsequence(extract(aXML, '/ACI_DOCUMENT/ACI_FINANCIAL_IMPUTATION/LIST_ITEM') ) ) )
           where IMF_PRIMARY = 1;
        exception
          when no_data_found then
            vLocalCurr    := 'NULL';
            vForeignCurr  := 'NULL';
        end;
      end if;

      -- Pas de monnaies trouvées sur ACI_FINANCIAL_IMPUTATION
      --  Il s'agit d'un document purement analytique donc pas besoin de continuer
      if nvl(vLocalCurr, 'NULL') = 'NULL' and nvl(vForeignCurr, 'NULL') = 'NULL' then
        return;
      end if;

      -- Si la monnaie de la société cible ne correspond a aucune des 2 monnaies de l'xml
      -- il faut arreter l'importation
      if     (nvl(vLocalCurr, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(vForeignCurr, 'NULL') <> vTgtCompLocalCurr) then
        raise_application_error(-20000
                              , 'Currency error - ACI_DOCUMENT' ||
                                chr(13) ||
                                'Company = ' ||
                                vTgtCompLocalCurr ||
                                chr(13) ||
                                'XML Local = ' ||
                                nvl(vLocalCurr, 'NULL') ||
                                chr(13) ||
                                'XML Foreign = ' ||
                                nvl(vForeignCurr, 'NULL')
                               );
      end if;

      -- Si la monnaie de la société de l'xml n'est pas la même que la monnaie de la société cible
      -- ET que la monnaie étrangère de l'xml correspond à  la monnaie de la société cible
      -- Alors, il faut utiliser les montants en monnaie étrangère de l'xml et
      -- et les placer dans les montants en monnaie de base
      if     (nvl(vLocalCurr, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(vForeignCurr, 'NULL') = vTgtCompLocalCurr) then
        aDOC_Row.DOC_PAID_AMOUNT_LC  := aDOC_Row.DOC_PAID_AMOUNT_FC;
        aDOC_Row.DOC_PAID_AMOUNT_FC  := 0;
      end if;
    exception
      when no_data_found then
        null;
    end;
  end Extract_ACI_DOCUMENT;

  /**
  * procedure Extract_ACI_DET_PAYMENT
  * Description
  *   Méthode pour extraire les données de la table ACI_DET_PAYMENT de l'XML
  */
  procedure Extract_ACI_DET_PAYMENT(
    aDET_Data    in out nocopy TACI_DET_PAYMENT
  , aXML         in            xmltype
  , aDocID       in            ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aPartID      in            ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  , aLocalCurr   in            varchar2
  , aForeignCurr in            varchar2
  )
  is
    vXPath varchar2(2000) default '/LIST_ITEM/';
    vIndex integer;
  begin
    for tplXml in (select column_value XML_VALUE
                     from table(xmlsequence(extract(aXML, '/ACI_DET_PAYMENT/LIST_ITEM') ) ) ) loop
      vIndex  := aDET_Data.count + 1;

      select ACI_ID_SEQ.nextval
           , aDocID
           , aPartID
           , extractvalue(tplXml.XML_VALUE, vXPath || 'C_FAM_TRANSACTION_TYP')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CAT_KEY_DET')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_CHARGES_EUR') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_CHARGES_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_CHARGES_LC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_CONTROL_FLAG') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_DEDUCTION_EUR') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_DEDUCTION_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_DEDUCTION_LC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_DIFF_EXCHANGE') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_DISCOUNT_EUR') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_DISCOUNT_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_DISCOUNT_LC') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DET_LETTRAGE_NO')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_PAIED_EUR') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_PAIED_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_PAIED_LC') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DET_SEQ_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DET_TRANSACTION_TYPE')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE1_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE2_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE3_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE4_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE5_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'EMP_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'FIX_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'GOO_MAJOR_REFERENCE')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER2') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER3') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER4') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER5') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT2')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT3')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT4')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT5')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_DOCUMENT')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_KEY1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_KEY2')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'RCO_NUMBER') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'RCO_TITLE')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CURRENCY1')
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        into aDET_Data(vIndex).ACI_DET_PAYMENT_ID
           , aDET_Data(vIndex).ACI_DOCUMENT_ID
           , aDET_Data(vIndex).ACI_PART_IMPUTATION_ID
           , aDET_Data(vIndex).C_FAM_TRANSACTION_TYP
           , aDET_Data(vIndex).CAT_KEY_DET
           , aDET_Data(vIndex).DET_CHARGES_EUR
           , aDET_Data(vIndex).DET_CHARGES_FC
           , aDET_Data(vIndex).DET_CHARGES_LC
           , aDET_Data(vIndex).DET_CONTROL_FLAG
           , aDET_Data(vIndex).DET_DEDUCTION_EUR
           , aDET_Data(vIndex).DET_DEDUCTION_FC
           , aDET_Data(vIndex).DET_DEDUCTION_LC
           , aDET_Data(vIndex).DET_DIFF_EXCHANGE
           , aDET_Data(vIndex).DET_DISCOUNT_EUR
           , aDET_Data(vIndex).DET_DISCOUNT_FC
           , aDET_Data(vIndex).DET_DISCOUNT_LC
           , aDET_Data(vIndex).DET_LETTRAGE_NO
           , aDET_Data(vIndex).DET_PAIED_EUR
           , aDET_Data(vIndex).DET_PAIED_FC
           , aDET_Data(vIndex).DET_PAIED_LC
           , aDET_Data(vIndex).DET_SEQ_NUMBER
           , aDET_Data(vIndex).DET_TRANSACTION_TYPE
           , aDET_Data(vIndex).DIC_IMP_FREE1_ID
           , aDET_Data(vIndex).DIC_IMP_FREE2_ID
           , aDET_Data(vIndex).DIC_IMP_FREE3_ID
           , aDET_Data(vIndex).DIC_IMP_FREE4_ID
           , aDET_Data(vIndex).DIC_IMP_FREE5_ID
           , aDET_Data(vIndex).EMP_NUMBER
           , aDET_Data(vIndex).FIX_NUMBER
           , aDET_Data(vIndex).GOO_MAJOR_REFERENCE
           , aDET_Data(vIndex).IMF_NUMBER
           , aDET_Data(vIndex).IMF_NUMBER2
           , aDET_Data(vIndex).IMF_NUMBER3
           , aDET_Data(vIndex).IMF_NUMBER4
           , aDET_Data(vIndex).IMF_NUMBER5
           , aDET_Data(vIndex).IMF_TEXT1
           , aDET_Data(vIndex).IMF_TEXT2
           , aDET_Data(vIndex).IMF_TEXT3
           , aDET_Data(vIndex).IMF_TEXT4
           , aDET_Data(vIndex).IMF_TEXT5
           , aDET_Data(vIndex).PAR_DOCUMENT
           , aDET_Data(vIndex).PER_KEY1
           , aDET_Data(vIndex).PER_KEY2
           , aDET_Data(vIndex).RCO_NUMBER
           , aDET_Data(vIndex).RCO_TITLE
           , aDET_Data(vIndex).CURRENCY1
           , aDET_Data(vIndex).A_DATECRE
           , aDET_Data(vIndex).A_IDCRE
        from dual;

      -- Si la monnaie de la société cible ne correspond a aucune des 2 monnaies de l'xml
      -- il faut arreter l'importation
      if     (nvl(aLocalCurr, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aForeignCurr, 'NULL') <> vTgtCompLocalCurr) then
        raise_application_error(-20000
                              , 'Currency error - ACI_DET_PAYMENT' ||
                                chr(13) ||
                                'Company = ' ||
                                vTgtCompLocalCurr ||
                                chr(13) ||
                                'XML Local = ' ||
                                nvl(aLocalCurr, 'NULL') ||
                                chr(13) ||
                                'XML Foreign = ' ||
                                nvl(aForeignCurr, 'NULL')
                               );
      end if;

      -- Si la monnaie de la société de l'xml n'est pas la même que la monnaie de la société cible
      -- ET que la monnaie étrangère de l'xml correspond à  la monnaie de la société cible
      -- Alors, il faut utiliser les montants en monnaie étrangère de l'xml et
      -- et les placer dans les montants en monnaie de base
      if     (nvl(aLocalCurr, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aForeignCurr, 'NULL') = vTgtCompLocalCurr) then
        aDET_Data(vIndex).DET_CHARGES_LC    := aDET_Data(vIndex).DET_CHARGES_FC;
        aDET_Data(vIndex).DET_DEDUCTION_LC  := aDET_Data(vIndex).DET_DEDUCTION_FC;
        aDET_Data(vIndex).DET_DISCOUNT_LC   := aDET_Data(vIndex).DET_DISCOUNT_FC;
        aDET_Data(vIndex).DET_PAIED_LC      := aDET_Data(vIndex).DET_PAIED_FC;
        aDET_Data(vIndex).DET_CHARGES_FC    := 0;
        aDET_Data(vIndex).DET_DEDUCTION_FC  := 0;
        aDET_Data(vIndex).DET_DISCOUNT_FC   := 0;
        aDET_Data(vIndex).DET_PAIED_FC      := 0;
      end if;
    end loop;
  end Extract_ACI_DET_PAYMENT;

  /**
  * procedure Extract_ACI_EXPIRY
  * Description
  *   Méthode pour extraire les données de la table ACI_EXPIRY de l'XML
  */
  procedure Extract_ACI_EXPIRY(
    aEXP_Data    in out nocopy TACI_EXPIRY
  , aXML         in            xmltype
  , aPartID      in            ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  , aLocalCurr   in            varchar2
  , aForeignCurr in            varchar2
  )
  is
    vXPath varchar2(2000) default '/LIST_ITEM/';
    vIndex integer;
  begin
    for tplXml in (select column_value XML_VALUE
                     from table(xmlsequence(extract(aXML, '/ACI_EXPIRY/LIST_ITEM') ) ) ) loop
      vIndex  := aEXP_Data.count + 1;

      select ACI_ID_SEQ.nextval
           , aPartID
           , extractvalue(tplXml.XML_VALUE, vXPath || 'C_STATUS_EXPIRY')
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_ADAPTED') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_AMOUNT_EUR') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_AMOUNT_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_AMOUNT_LC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_AMOUNT_PROV_EUR') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_AMOUNT_PROV_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_AMOUNT_PROV_LC') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_BVR_CODE')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_CALC_NET') )
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_CALCULATED') )
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_DATE_PMT_TOT') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_DISCOUNT_EUR') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_DISCOUNT_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_DISCOUNT_LC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_POURCENT') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_REF_BVR')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'EXP_SLICE') )
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        into aEXP_Data(vIndex).ACI_EXPIRY_ID
           , aEXP_Data(vIndex).ACI_PART_IMPUTATION_ID
           , aEXP_Data(vIndex).C_STATUS_EXPIRY
           , aEXP_Data(vIndex).EXP_ADAPTED
           , aEXP_Data(vIndex).EXP_AMOUNT_EUR
           , aEXP_Data(vIndex).EXP_AMOUNT_FC
           , aEXP_Data(vIndex).EXP_AMOUNT_LC
           , aEXP_Data(vIndex).EXP_AMOUNT_PROV_EUR
           , aEXP_Data(vIndex).EXP_AMOUNT_PROV_FC
           , aEXP_Data(vIndex).EXP_AMOUNT_PROV_LC
           , aEXP_Data(vIndex).EXP_BVR_CODE
           , aEXP_Data(vIndex).EXP_CALC_NET
           , aEXP_Data(vIndex).EXP_CALCULATED
           , aEXP_Data(vIndex).EXP_DATE_PMT_TOT
           , aEXP_Data(vIndex).EXP_DISCOUNT_EUR
           , aEXP_Data(vIndex).EXP_DISCOUNT_FC
           , aEXP_Data(vIndex).EXP_DISCOUNT_LC
           , aEXP_Data(vIndex).EXP_POURCENT
           , aEXP_Data(vIndex).EXP_REF_BVR
           , aEXP_Data(vIndex).EXP_SLICE
           , aEXP_Data(vIndex).A_DATECRE
           , aEXP_Data(vIndex).A_IDCRE
        from dual;

      -- Si la monnaie de la société cible ne correspond a aucune des 2 monnaies de l'xml
      -- il faut arreter l'importation
      if     (nvl(aLocalCurr, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aForeignCurr, 'NULL') <> vTgtCompLocalCurr) then
        raise_application_error(-20000
                              , 'Currency error - ACI_EXPIRY' ||
                                chr(13) ||
                                'Company = ' ||
                                vTgtCompLocalCurr ||
                                chr(13) ||
                                'XML Local = ' ||
                                nvl(aLocalCurr, 'NULL') ||
                                chr(13) ||
                                'XML Foreign = ' ||
                                nvl(aForeignCurr, 'NULL')
                               );
      end if;

      -- Si la monnaie de la société de l'xml n'est pas la même que la monnaie de la société cible
      -- ET que la monnaie étrangère de l'xml correspond à  la monnaie de la société cible
      -- Alors, il faut utiliser les montants en monnaie étrangère de l'xml et
      -- et les placer dans les montants en monnaie de base
      if     (nvl(aLocalCurr, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aForeignCurr, 'NULL') = vTgtCompLocalCurr) then
        aEXP_Data(vIndex).EXP_AMOUNT_LC       := aEXP_Data(vIndex).EXP_AMOUNT_FC;
        aEXP_Data(vIndex).EXP_AMOUNT_PROV_LC  := aEXP_Data(vIndex).EXP_AMOUNT_PROV_FC;
        aEXP_Data(vIndex).EXP_DISCOUNT_LC     := aEXP_Data(vIndex).EXP_DISCOUNT_FC;
        aEXP_Data(vIndex).EXP_AMOUNT_FC       := 0;
        aEXP_Data(vIndex).EXP_AMOUNT_PROV_FC  := 0;
        aEXP_Data(vIndex).EXP_DISCOUNT_FC     := 0;
      end if;
    end loop;
  end Extract_ACI_EXPIRY;

  /**
  * procedure Extract_ACI_MGM_IMPUTATION
  * Description
  *   Méthode pour extraire les données de la table ACI_MGM_IMPUTATION de l'XML
  */
  procedure Extract_ACI_MGM_IMPUTATION(
    aMGM_Data in out nocopy TACI_MGM_IMPUTATION
  , aXML      in            xmltype
  , aDocID    in            ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aFinID    in            ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type
  )
  is
    vXPath varchar2(2000) default '/LIST_ITEM/';
    vIndex integer;
  begin
    for tplXml in (select column_value XML_VALUE
                     from table(xmlsequence(extract(aXML, '/ACI_MGM_IMPUTATION/LIST_ITEM') ) ) ) loop
      vIndex  := aMGM_Data.count + 1;

      select ACI_ID_SEQ.nextval
           , aDocID
           , aFinID
           , extractvalue(tplXml.XML_VALUE, vXPath || 'C_FAM_TRANSACTION_TYP')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CDA_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CPN_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CURRENCY1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CURRENCY2')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE1_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE2_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE3_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE4_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE5_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'EMP_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'FIX_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'GOO_MAJOR_REFERENCE')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_AMOUNT_EUR_C') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_AMOUNT_EUR_D') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_AMOUNT_FC_C') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_AMOUNT_FC_D') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_AMOUNT_LC_C') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_AMOUNT_LC_D') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_BASE_PRICE') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_CONTROL_FLAG') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_DESCRIPTION')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_EXCHANGE_RATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_GENRE')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_NUMBER') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_NUMBER2') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_NUMBER3') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_NUMBER4') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_NUMBER5') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_PRIMARY') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_QUANTITY_C') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_QUANTITY_D') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_TEXT1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_TEXT2')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_TEXT3')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_TEXT4')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_TEXT5')
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_TRANSACTION_DATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_TYPE')
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'IMM_VALUE_DATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_KEY1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_KEY2')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PF_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PJ_NUMBER')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'RCO_NUMBER') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'RCO_TITLE')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'QTY_NUMBER')
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        into aMGM_Data(vIndex).ACI_MGM_IMPUTATION_ID
           , aMGM_Data(vIndex).ACI_DOCUMENT_ID
           , aMGM_Data(vIndex).ACI_FINANCIAL_IMPUTATION_ID
           , aMGM_Data(vIndex).C_FAM_TRANSACTION_TYP
           , aMGM_Data(vIndex).CDA_NUMBER
           , aMGM_Data(vIndex).CPN_NUMBER
           , aMGM_Data(vIndex).CURRENCY1
           , aMGM_Data(vIndex).CURRENCY2
           , aMGM_Data(vIndex).DIC_IMP_FREE1_ID
           , aMGM_Data(vIndex).DIC_IMP_FREE2_ID
           , aMGM_Data(vIndex).DIC_IMP_FREE3_ID
           , aMGM_Data(vIndex).DIC_IMP_FREE4_ID
           , aMGM_Data(vIndex).DIC_IMP_FREE5_ID
           , aMGM_Data(vIndex).EMP_NUMBER
           , aMGM_Data(vIndex).FIX_NUMBER
           , aMGM_Data(vIndex).GOO_MAJOR_REFERENCE
           , aMGM_Data(vIndex).IMM_AMOUNT_EUR_C
           , aMGM_Data(vIndex).IMM_AMOUNT_EUR_D
           , aMGM_Data(vIndex).IMM_AMOUNT_FC_C
           , aMGM_Data(vIndex).IMM_AMOUNT_FC_D
           , aMGM_Data(vIndex).IMM_AMOUNT_LC_C
           , aMGM_Data(vIndex).IMM_AMOUNT_LC_D
           , aMGM_Data(vIndex).IMM_BASE_PRICE
           , aMGM_Data(vIndex).IMM_CONTROL_FLAG
           , aMGM_Data(vIndex).IMM_DESCRIPTION
           , aMGM_Data(vIndex).IMM_EXCHANGE_RATE
           , aMGM_Data(vIndex).IMM_GENRE
           , aMGM_Data(vIndex).IMM_NUMBER
           , aMGM_Data(vIndex).IMM_NUMBER2
           , aMGM_Data(vIndex).IMM_NUMBER3
           , aMGM_Data(vIndex).IMM_NUMBER4
           , aMGM_Data(vIndex).IMM_NUMBER5
           , aMGM_Data(vIndex).IMM_PRIMARY
           , aMGM_Data(vIndex).IMM_QUANTITY_C
           , aMGM_Data(vIndex).IMM_QUANTITY_D
           , aMGM_Data(vIndex).IMM_TEXT1
           , aMGM_Data(vIndex).IMM_TEXT2
           , aMGM_Data(vIndex).IMM_TEXT3
           , aMGM_Data(vIndex).IMM_TEXT4
           , aMGM_Data(vIndex).IMM_TEXT5
           , aMGM_Data(vIndex).IMM_TRANSACTION_DATE
           , aMGM_Data(vIndex).IMM_TYPE
           , aMGM_Data(vIndex).IMM_VALUE_DATE
           , aMGM_Data(vIndex).PER_KEY1
           , aMGM_Data(vIndex).PER_KEY2
           , aMGM_Data(vIndex).PF_NUMBER
           , aMGM_Data(vIndex).PJ_NUMBER
           , aMGM_Data(vIndex).RCO_NUMBER
           , aMGM_Data(vIndex).RCO_TITLE
           , aMGM_Data(vIndex).QTY_NUMBER
           , aMGM_Data(vIndex).A_DATECRE
           , aMGM_Data(vIndex).A_IDCRE
        from dual;

      -- Rechercher le numéro de période comptable de la société cible
      -- correspondant au CAT_KEY source et donc la date de transaction donnée
      select max(PER.PER_NO_PERIOD)
        into aMGM_Data(vIndex).PER_NO_PERIOD
        from ACS_PERIOD PER
           , ACJ_CATALOGUE_DOCUMENT CAT
       where CAT.CAT_KEY = vCAT_KEY
         and PER.C_TYPE_PERIOD = CAT.C_TYPE_PERIOD
         and aMGM_Data(vIndex).IMM_TRANSACTION_DATE between PER.PER_START_DATE and PER.PER_END_DATE;

      -- Si la monnaie de la société cible ne correspond a aucune des 2 monnaies de l'xml
      -- il faut arreter l'importation
      if     (nvl(aMGM_Data(vIndex).CURRENCY2, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aMGM_Data(vIndex).CURRENCY1, 'NULL') <> vTgtCompLocalCurr) then
        raise_application_error(-20000
                              , 'Currency error - ACI_MGM_IMPUTATION' ||
                                chr(13) ||
                                'Company = ' ||
                                vTgtCompLocalCurr ||
                                chr(13) ||
                                'XML Local = ' ||
                                nvl(aMGM_Data(vIndex).CURRENCY2, 'NULL') ||
                                chr(13) ||
                                'XML Foreign = ' ||
                                nvl(aMGM_Data(vIndex).CURRENCY1, 'NULL')
                               );
      end if;

      -- Si la monnaie de la société de l'xml n'est pas la même que la monnaie de la société cible
      -- ET que la monnaie étrangère de l'xml correspond à  la monnaie de la société cible
      -- Alors, il faut utiliser les montants en monnaie étrangère de l'xml et
      -- et les placer dans les montants en monnaie de base
      if     (nvl(aMGM_Data(vIndex).CURRENCY2, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aMGM_Data(vIndex).CURRENCY1, 'NULL') = vTgtCompLocalCurr) then
        aMGM_Data(vIndex).IMM_AMOUNT_LC_C    := aMGM_Data(vIndex).IMM_AMOUNT_FC_C;
        aMGM_Data(vIndex).IMM_AMOUNT_LC_D    := aMGM_Data(vIndex).IMM_AMOUNT_FC_D;
        aMGM_Data(vIndex).IMM_AMOUNT_FC_C    := 0;
        aMGM_Data(vIndex).IMM_AMOUNT_FC_D    := 0;
        aMGM_Data(vIndex).IMM_BASE_PRICE     := 0;
        aMGM_Data(vIndex).IMM_EXCHANGE_RATE  := 0;
        aMGM_Data(vIndex).CURRENCY2          := aMGM_Data(vIndex).CURRENCY1;
      end if;
    end loop;
  end Extract_ACI_MGM_IMPUTATION;

  /**
  * procedure Extract_ACI_FIN_IMPUTATION
  * Description
  *   Méthode pour extraire les données de la table ACI_FINANCIAL_IMPUTATION de l'XML
  */
  procedure Extract_ACI_FIN_IMPUTATION(
    aFIN_Data in out nocopy TACI_FINANCIAL_IMPUTATION
  , aMGM_Data in out nocopy TACI_MGM_IMPUTATION
  , aXML      in            xmltype
  , aDocID    in            ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aPartID   in            ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  )
  is
    vXPath   varchar2(2000) default '/LIST_ITEM/';
    vIndex   integer;
    vXML_MGM xmltype;
  begin
    for tplXml in (select column_value XML_VALUE
                     from table(xmlsequence(extract(aXML, '/ACI_FINANCIAL_IMPUTATION/LIST_ITEM') ) ) ) loop
      vIndex  := aFIN_Data.count + 1;

      select ACI_ID_SEQ.nextval
           , aDocID
           , aPartID
           , extractvalue(tplXml.XML_VALUE, vXPath || 'ACC_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'AUX_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'C_FAM_TRANSACTION_TYP')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'C_GENRE_TRANSACTION')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CURRENCY1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CURRENCY2')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'DET_BASE_PRICE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE1_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE2_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE3_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE4_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_IMP_FREE5_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIV_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'EMP_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'FIX_NUMBER')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'GOO_MAJOR_REFERENCE')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_AMOUNT_EUR_C') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_AMOUNT_EUR_D') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_AMOUNT_FC_C') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_AMOUNT_FC_D') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_AMOUNT_LC_C') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_AMOUNT_LC_D') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_BASE_PRICE') )
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_COMPARE_DATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_COMPARE_TEXT')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_COMPARE_USE_INI')
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_CONTROL_DATE') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_CONTROL_FLAG') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_CONTROL_TEXT')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_CONTROL_USE_INI')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_DESCRIPTION')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_EXCHANGE_RATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_GENRE')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER2') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER3') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER4') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_NUMBER5') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_PRIMARY') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT2')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT3')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT4')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TEXT5')
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TRANSACTION_DATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_TYPE')
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'IMF_VALUE_DATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_KEY1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_KEY2')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'RCO_NUMBER') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'RCO_TITLE')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_EXCHANGE_RATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_INCLUDED_EXCLUDED')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_LIABLED_AMOUNT') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_LIABLED_RATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_NUMBER')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_RATE') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_REDUCTION') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_VAT_AMOUNT_EUR') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_VAT_AMOUNT_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_VAT_AMOUNT_LC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'TAX_VAT_AMOUNT_VC') )
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        into aFIN_Data(vIndex).ACI_FINANCIAL_IMPUTATION_ID
           , aFIN_Data(vIndex).ACI_DOCUMENT_ID
           , aFIN_Data(vIndex).ACI_PART_IMPUTATION_ID
           , aFIN_Data(vIndex).ACC_NUMBER
           , aFIN_Data(vIndex).AUX_NUMBER
           , aFIN_Data(vIndex).C_FAM_TRANSACTION_TYP
           , aFIN_Data(vIndex).C_GENRE_TRANSACTION
           , aFIN_Data(vIndex).CURRENCY1
           , aFIN_Data(vIndex).CURRENCY2
           , aFIN_Data(vIndex).DET_BASE_PRICE
           , aFIN_Data(vIndex).DIC_IMP_FREE1_ID
           , aFIN_Data(vIndex).DIC_IMP_FREE2_ID
           , aFIN_Data(vIndex).DIC_IMP_FREE3_ID
           , aFIN_Data(vIndex).DIC_IMP_FREE4_ID
           , aFIN_Data(vIndex).DIC_IMP_FREE5_ID
           , aFIN_Data(vIndex).DIV_NUMBER
           , aFIN_Data(vIndex).EMP_NUMBER
           , aFIN_Data(vIndex).FIX_NUMBER
           , aFIN_Data(vIndex).GOO_MAJOR_REFERENCE
           , aFIN_Data(vIndex).IMF_AMOUNT_EUR_C
           , aFIN_Data(vIndex).IMF_AMOUNT_EUR_D
           , aFIN_Data(vIndex).IMF_AMOUNT_FC_C
           , aFIN_Data(vIndex).IMF_AMOUNT_FC_D
           , aFIN_Data(vIndex).IMF_AMOUNT_LC_C
           , aFIN_Data(vIndex).IMF_AMOUNT_LC_D
           , aFIN_Data(vIndex).IMF_BASE_PRICE
           , aFIN_Data(vIndex).IMF_COMPARE_DATE
           , aFIN_Data(vIndex).IMF_COMPARE_TEXT
           , aFIN_Data(vIndex).IMF_COMPARE_USE_INI
           , aFIN_Data(vIndex).IMF_CONTROL_DATE
           , aFIN_Data(vIndex).IMF_CONTROL_FLAG
           , aFIN_Data(vIndex).IMF_CONTROL_TEXT
           , aFIN_Data(vIndex).IMF_CONTROL_USE_INI
           , aFIN_Data(vIndex).IMF_DESCRIPTION
           , aFIN_Data(vIndex).IMF_EXCHANGE_RATE
           , aFIN_Data(vIndex).IMF_GENRE
           , aFIN_Data(vIndex).IMF_NUMBER
           , aFIN_Data(vIndex).IMF_NUMBER2
           , aFIN_Data(vIndex).IMF_NUMBER3
           , aFIN_Data(vIndex).IMF_NUMBER4
           , aFIN_Data(vIndex).IMF_NUMBER5
           , aFIN_Data(vIndex).IMF_PRIMARY
           , aFIN_Data(vIndex).IMF_TEXT1
           , aFIN_Data(vIndex).IMF_TEXT2
           , aFIN_Data(vIndex).IMF_TEXT3
           , aFIN_Data(vIndex).IMF_TEXT4
           , aFIN_Data(vIndex).IMF_TEXT5
           , aFIN_Data(vIndex).IMF_TRANSACTION_DATE
           , aFIN_Data(vIndex).IMF_TYPE
           , aFIN_Data(vIndex).IMF_VALUE_DATE
           , aFIN_Data(vIndex).PER_KEY1
           , aFIN_Data(vIndex).PER_KEY2
           , aFIN_Data(vIndex).RCO_NUMBER
           , aFIN_Data(vIndex).RCO_TITLE
           , aFIN_Data(vIndex).TAX_EXCHANGE_RATE
           , aFIN_Data(vIndex).TAX_INCLUDED_EXCLUDED
           , aFIN_Data(vIndex).TAX_LIABLED_AMOUNT
           , aFIN_Data(vIndex).TAX_LIABLED_RATE
           , aFIN_Data(vIndex).TAX_NUMBER
           , aFIN_Data(vIndex).TAX_RATE
           , aFIN_Data(vIndex).TAX_REDUCTION
           , aFIN_Data(vIndex).TAX_VAT_AMOUNT_EUR
           , aFIN_Data(vIndex).TAX_VAT_AMOUNT_FC
           , aFIN_Data(vIndex).TAX_VAT_AMOUNT_LC
           , aFIN_Data(vIndex).TAX_VAT_AMOUNT_VC
           , aFIN_Data(vIndex).A_DATECRE
           , aFIN_Data(vIndex).A_IDCRE
        from dual;

      -- Rechercher le numéro de période comptable de la société cible
      -- correspondant au CAT_KEY source et donc la date de transaction donnée
      select max(PER.PER_NO_PERIOD)
        into aFIN_Data(vIndex).PER_NO_PERIOD
        from ACS_PERIOD PER
           , ACJ_CATALOGUE_DOCUMENT CAT
       where CAT.CAT_KEY = vCAT_KEY
         and PER.C_TYPE_PERIOD = CAT.C_TYPE_PERIOD
         and aFIN_Data(vIndex).IMF_TRANSACTION_DATE between PER.PER_START_DATE and PER.PER_END_DATE;

      -- Si la monnaie de la société cible ne correspond a aucune des 2 monnaies de l'xml
      -- il faut arreter l'importation
      if     (nvl(aFIN_Data(vIndex).CURRENCY2, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aFIN_Data(vIndex).CURRENCY1, 'NULL') <> vTgtCompLocalCurr) then
        raise_application_error(-20000
                              , 'Currency error - ACI_FINANCIAL_IMPUTATION' ||
                                chr(13) ||
                                'Company = ' ||
                                vTgtCompLocalCurr ||
                                chr(13) ||
                                'XML Local = ' ||
                                nvl(aFIN_Data(vIndex).CURRENCY2, 'NULL') ||
                                chr(13) ||
                                'XML Foreign = ' ||
                                nvl(aFIN_Data(vIndex).CURRENCY1, 'NULL')
                               );
      end if;

      -- Si la monnaie de la société de l'xml n'est pas la même que la monnaie de la société cible
      -- ET que la monnaie étrangère de l'xml correspond à  la monnaie de la société cible
      -- Alors, il faut utiliser les montants en monnaie étrangère de l'xml et
      -- et les placer dans les montants en monnaie de base
      if     (nvl(aFIN_Data(vIndex).CURRENCY2, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aFIN_Data(vIndex).CURRENCY1, 'NULL') = vTgtCompLocalCurr) then
        aFIN_Data(vIndex).IMF_AMOUNT_LC_C    := aFIN_Data(vIndex).IMF_AMOUNT_FC_C;
        aFIN_Data(vIndex).IMF_AMOUNT_LC_D    := aFIN_Data(vIndex).IMF_AMOUNT_FC_D;
        aFIN_Data(vIndex).TAX_VAT_AMOUNT_LC  := aFIN_Data(vIndex).TAX_VAT_AMOUNT_FC;
        aFIN_Data(vIndex).IMF_AMOUNT_FC_C    := 0;
        aFIN_Data(vIndex).IMF_AMOUNT_FC_D    := 0;
        aFIN_Data(vIndex).TAX_VAT_AMOUNT_FC  := 0;
        aFIN_Data(vIndex).IMF_BASE_PRICE     := 0;
        aFIN_Data(vIndex).IMF_EXCHANGE_RATE  := 0;
        aFIN_Data(vIndex).CURRENCY2          := aFIN_Data(vIndex).CURRENCY1;

        -- Calcul Finance, parce qu'il n'y a pas de champ Montant TVA en monnaie étrangère
        if aFIN_Data(vIndex).TAX_INCLUDED_EXCLUDED != 'I' then
          aFIN_Data(vIndex).TAX_LIABLED_AMOUNT  :=
            abs(aFIN_Data(vIndex).IMF_AMOUNT_LC_D + aFIN_Data(vIndex).IMF_AMOUNT_LC_C) -
            abs(aFIN_Data(vIndex).TAX_VAT_AMOUNT_LC);
        else
          aFIN_Data(vIndex).TAX_LIABLED_AMOUNT  :=
            (abs(aFIN_Data(vIndex).IMF_AMOUNT_LC_D + aFIN_Data(vIndex).IMF_AMOUNT_LC_C) *
             aFIN_Data(vIndex).TAX_LIABLED_RATE
            ) /
            100;
        end if;
      end if;

      -- XML de la table ACI_MGM_IMPUTATION liée à  ACI_FINANCIAL_IMPUTATION
      select extract(tplXml.XML_VALUE, vXPath || '/ACI_MGM_IMPUTATION')
        into vXML_MGM
        from dual;

      -- Extraire les données de la table ACI_MGM_IMPUTATION de l'XML
      Extract_ACI_MGM_IMPUTATION(aMGM_Data
                               , vXML_MGM
                               , aFIN_Data(vIndex).ACI_DOCUMENT_ID
                               , aFIN_Data(vIndex).ACI_FINANCIAL_IMPUTATION_ID
                                );
    end loop;
  end Extract_ACI_FIN_IMPUTATION;

  /**
  * procedure Extract_ACI_REMINDER
  * Description
  *   Méthode pour extraire les données de la table ACI_REMINDER de l'XML
  */
  procedure Extract_ACI_REMINDER(
    aRMD_Data in out nocopy TACI_REMINDER
  , aXML      in            xmltype
  , aPartID   in            ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  )
  is
    vXPath varchar2(2000) default '/LIST_ITEM/';
    vIndex integer;
  begin
    for tplXml in (select column_value XML_VALUE
                     from table(xmlsequence(extract(aXML, '/ACI_REMINDER/LIST_ITEM') ) ) ) loop
      vIndex  := aRMD_Data.count + 1;

      select ACI_ID_SEQ.nextval
           , aPartID
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CURRENCY1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CURRENCY2')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_DOCUMENT')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'REM_COVER_AMOUNT_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'REM_COVER_AMOUNT_LC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'REM_NUMBER') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'REM_PAYABLE_AMOUNT_EUR') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'REM_PAYABLE_AMOUNT_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'REM_PAYABLE_AMOUNT_LC') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'REM_SEQ_NUMBER')
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        into aRMD_Data(vIndex).ACI_REMINDER_ID
           , aRMD_Data(vIndex).ACI_PART_IMPUTATION_ID
           , aRMD_Data(vIndex).CURRENCY1
           , aRMD_Data(vIndex).CURRENCY2
           , aRMD_Data(vIndex).PAR_DOCUMENT
           , aRMD_Data(vIndex).REM_COVER_AMOUNT_FC
           , aRMD_Data(vIndex).REM_COVER_AMOUNT_LC
           , aRMD_Data(vIndex).REM_NUMBER
           , aRMD_Data(vIndex).REM_PAYABLE_AMOUNT_EUR
           , aRMD_Data(vIndex).REM_PAYABLE_AMOUNT_FC
           , aRMD_Data(vIndex).REM_PAYABLE_AMOUNT_LC
           , aRMD_Data(vIndex).REM_SEQ_NUMBER
           , aRMD_Data(vIndex).A_DATECRE
           , aRMD_Data(vIndex).A_IDCRE
        from dual;

      -- Si la monnaie de la société cible ne correspond a aucune des 2 monnaies de l'xml
      -- il faut arreter l'importation
      if     (nvl(aRMD_Data(vIndex).CURRENCY2, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aRMD_Data(vIndex).CURRENCY1, 'NULL') <> vTgtCompLocalCurr) then
        raise_application_error(-20000
                              , 'Currency error - ACI_REMINDER' ||
                                chr(13) ||
                                'Company = ' ||
                                vTgtCompLocalCurr ||
                                chr(13) ||
                                'XML Local = ' ||
                                nvl(aRMD_Data(vIndex).CURRENCY2, 'NULL') ||
                                chr(13) ||
                                'XML Foreign = ' ||
                                nvl(aRMD_Data(vIndex).CURRENCY1, 'NULL')
                               );
      end if;

      -- Si la monnaie de la société de l'xml n'est pas la même que la monnaie de la société cible
      -- ET que la monnaie étrangère de l'xml correspond à  la monnaie de la société cible
      -- Alors, il faut utiliser les montants en monnaie étrangère de l'xml et
      -- et les placer dans les montants en monnaie de base
      if     (nvl(aRMD_Data(vIndex).CURRENCY2, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aRMD_Data(vIndex).CURRENCY1, 'NULL') = vTgtCompLocalCurr) then
        aRMD_Data(vIndex).REM_COVER_AMOUNT_LC    := aRMD_Data(vIndex).REM_COVER_AMOUNT_FC;
        aRMD_Data(vIndex).REM_PAYABLE_AMOUNT_LC  := aRMD_Data(vIndex).REM_PAYABLE_AMOUNT_FC;
        aRMD_Data(vIndex).REM_COVER_AMOUNT_FC    := 0;
        aRMD_Data(vIndex).REM_PAYABLE_AMOUNT_FC  := 0;
        aRMD_Data(vIndex).CURRENCY2              := aRMD_Data(vIndex).CURRENCY1;
      end if;
    end loop;
  end Extract_ACI_REMINDER;

  /**
  * procedure Extract_ACI_REMINDER_TEXT
  * Description
  *   Méthode pour extraire les données de la table ACI_REMINDER_TEXT de l'XML
  */
  procedure Extract_ACI_REMINDER_TEXT(
    aRMT_Data in out nocopy TACI_REMINDER_TEXT
  , aXML      in            xmltype
  , aDocID    in            ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aPartID   in            ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  )
  is
    vXPath varchar2(2000) default '/LIST_ITEM/';
    vIndex integer;
  begin
    for tplXml in (select column_value XML_VALUE
                     from table(xmlsequence(extract(aXML, '/ACI_REMINDER_TEXT/LIST_ITEM') ) ) ) loop
      vIndex  := aRMT_Data.count + 1;

      select ACI_ID_SEQ.nextval
           , aDocID
           , aPartID
           , extractvalue(tplXml.XML_VALUE, vXPath || 'C_TEXT_TYPE')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'REM_TEXT')
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        into aRMT_Data(vIndex).ACI_REMINDER_TEXT_ID
           , aRMT_Data(vIndex).ACI_DOCUMENT_ID
           , aRMT_Data(vIndex).ACI_PART_IMPUTATION_ID
           , aRMT_Data(vIndex).C_TEXT_TYPE
           , aRMT_Data(vIndex).REM_TEXT
           , aRMT_Data(vIndex).A_DATECRE
           , aRMT_Data(vIndex).A_IDCRE
        from dual;
    end loop;
  end Extract_ACI_REMINDER_TEXT;

  /**
  * procedure Extract_ACI_PART_IMPUTATION
  * Description
  *   Méthode pour extraire les données de la table ACI_PART_IMPUTATION de l'XML
  */
  procedure Extract_ACI_PART_IMPUTATION(
    aPAR_Data in out nocopy TACI_PART_IMPUTATION
  , aDET_Data in out nocopy TACI_DET_PAYMENT
  , aFIN_Data in out nocopy TACI_FINANCIAL_IMPUTATION
  , aMGM_Data in out nocopy TACI_MGM_IMPUTATION
  , aEXP_Data in out nocopy TACI_EXPIRY
  , aRMD_Data in out nocopy TACI_REMINDER
  , aRMT_Data in out nocopy TACI_REMINDER_TEXT
  , aXML      in            xmltype
  , aDocID    in            ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  )
  is
    vXPath   varchar2(2000) default '/LIST_ITEM/';
    vIndex   integer;
    vXML_DET xmltype;
    vXML_FIN xmltype;
    vXML_EXP xmltype;
    vXML_RMD xmltype;
    vXML_RMT xmltype;
  begin
    for tplXml in (select column_value XML_VALUE
                     from table(xmlsequence(extract(aXML, '/ACI_PART_IMPUTATION/LIST_ITEM') ) ) ) loop
      vIndex  := aPAR_Data.count + 1;

      select ACI_ID_SEQ.nextval
           , aDocID
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CURRENCY1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'CURRENCY2')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DES_DESCRIPTION_SUMMARY')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_BLOCKED_REASON_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_CENTER_PAYMENT_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_LEVEL_PRIORITY_ID')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'DIC_PRIORITY_PAYMENT_ID')
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'DOC_DATE_DELIVERY') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'FRE_ACCOUNT_NUMBER')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_BASE_PRICE') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_BLOCKED_DOCUMENT') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_CHARGES_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_CHARGES_LC') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_COMMENT')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_DOCUMENT')
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_EXCHANGE_RATE') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_PAIED_FC') )
           , to_number(extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_PAIED_LC') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_REF_BVR')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_BVR_CODE')
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_REMIND_DATE') )
           , REP_UTILS.ReplicatorDateToDate(extractvalue(tplXml.XML_VALUE, vXPath || 'PAR_REMIND_PRINTDATE') )
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PCO_DESCR')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_CUST_KEY1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_CUST_KEY2')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_SUPP_KEY1')
           , extractvalue(tplXml.XML_VALUE, vXPath || 'PER_SUPP_KEY2')
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        into aPAR_Data(vIndex).ACI_PART_IMPUTATION_ID
           , aPAR_Data(vIndex).ACI_DOCUMENT_ID
           , aPAR_Data(vIndex).CURRENCY1
           , aPAR_Data(vIndex).CURRENCY2
           , aPAR_Data(vIndex).DES_DESCRIPTION_SUMMARY
           , aPAR_Data(vIndex).DIC_BLOCKED_REASON_ID
           , aPAR_Data(vIndex).DIC_CENTER_PAYMENT_ID
           , aPAR_Data(vIndex).DIC_LEVEL_PRIORITY_ID
           , aPAR_Data(vIndex).DIC_PRIORITY_PAYMENT_ID
           , aPAR_Data(vIndex).DOC_DATE_DELIVERY
           , aPAR_Data(vIndex).FRE_ACCOUNT_NUMBER
           , aPAR_Data(vIndex).PAR_BASE_PRICE
           , aPAR_Data(vIndex).PAR_BLOCKED_DOCUMENT
           , aPAR_Data(vIndex).PAR_CHARGES_FC
           , aPAR_Data(vIndex).PAR_CHARGES_LC
           , aPAR_Data(vIndex).PAR_COMMENT
           , aPAR_Data(vIndex).PAR_DOCUMENT
           , aPAR_Data(vIndex).PAR_EXCHANGE_RATE
           , aPAR_Data(vIndex).PAR_PAIED_FC
           , aPAR_Data(vIndex).PAR_PAIED_LC
           , aPAR_Data(vIndex).PAR_REF_BVR
           , aPAR_Data(vIndex).PAR_BVR_CODE
           , aPAR_Data(vIndex).PAR_REMIND_DATE
           , aPAR_Data(vIndex).PAR_REMIND_PRINTDATE
           , aPAR_Data(vIndex).PCO_DESCR
           , aPAR_Data(vIndex).PER_CUST_KEY1
           , aPAR_Data(vIndex).PER_CUST_KEY2
           , aPAR_Data(vIndex).PER_SUPP_KEY1
           , aPAR_Data(vIndex).PER_SUPP_KEY2
           , aPAR_Data(vIndex).A_DATECRE
           , aPAR_Data(vIndex).A_IDCRE
        from dual;

      -- XML des table ... liées à  ACI_FINANCIAL_IMPUTATION
      select extract(tplXml.XML_VALUE, vXPath || '/ACI_DET_PAYMENT')
           , extract(tplXml.XML_VALUE, vXPath || '/ACI_FINANCIAL_IMPUTATION')
           , extract(tplXml.XML_VALUE, vXPath || '/ACI_EXPIRY')
           , extract(tplXml.XML_VALUE, vXPath || '/ACI_REMINDER')
           , extract(tplXml.XML_VALUE, vXPath || '/ACI_REMINDER_TEXT')
        into vXML_DET
           , vXML_FIN
           , vXML_EXP
           , vXML_RMD
           , vXML_RMT
        from dual;

      -- Extraire les données de la table ACI_DET_PAYMENT de l'XML
      Extract_ACI_DET_PAYMENT(aDET_Data
                            , vXML_DET
                            , aPAR_Data(vIndex).ACI_DOCUMENT_ID
                            , aPAR_Data(vIndex).ACI_PART_IMPUTATION_ID
                            , aPAR_Data(vIndex).CURRENCY2
                            , aPAR_Data(vIndex).CURRENCY1
                             );
      -- Extraire les données de la table ACI_FINANCIAL_IMPUTATION de l'XML
      Extract_ACI_FIN_IMPUTATION(aFIN_Data
                               , aMGM_Data
                               , vXML_FIN
                               , aPAR_Data(vIndex).ACI_DOCUMENT_ID
                               , aPAR_Data(vIndex).ACI_PART_IMPUTATION_ID
                                );
      -- Extraire les données de la table ACI_EXPIRY de l'XML
      Extract_ACI_EXPIRY(aEXP_Data
                       , vXML_EXP
                       , aPAR_Data(vIndex).ACI_PART_IMPUTATION_ID
                       , aPAR_Data(vIndex).CURRENCY2
                       , aPAR_Data(vIndex).CURRENCY1
                        );
      -- Extraire les données de la table ACI_REMINDER de l'XML
      Extract_ACI_REMINDER(aRMD_Data, vXML_RMD, aPAR_Data(vIndex).ACI_PART_IMPUTATION_ID);
      -- Extraire les données de la table ACI_REMINDER de l'XML
      Extract_ACI_REMINDER_TEXT(aRMT_Data
                              , vXML_RMT
                              , aPAR_Data(vIndex).ACI_DOCUMENT_ID
                              , aPAR_Data(vIndex).ACI_PART_IMPUTATION_ID
                               );

      -- Si la monnaie de la société cible ne correspond a aucune des 2 monnaies de l'xml
      -- il faut arreter l'importation
      if     (nvl(aPAR_Data(vIndex).CURRENCY2, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aPAR_Data(vIndex).CURRENCY1, 'NULL') <> vTgtCompLocalCurr) then
        raise_application_error(-20000
                              , 'Currency error - ACI_PART_IMPUTATION' ||
                                chr(13) ||
                                'Company = ' ||
                                vTgtCompLocalCurr ||
                                chr(13) ||
                                'XML Local = ' ||
                                nvl(aPAR_Data(vIndex).CURRENCY2, 'NULL') ||
                                chr(13) ||
                                'XML Foreign = ' ||
                                nvl(aPAR_Data(vIndex).CURRENCY1, 'NULL')
                               );
      end if;

      -- Si la monnaie de la société de l'xml n'est pas la même que la monnaie de la société cible
      -- ET que la monnaie étrangère de l'xml correspond à  la monnaie de la société cible
      -- Alors, il faut utiliser les montants en monnaie étrangère de l'xml et
      -- et les placer dans les montants en monnaie de base
      if     (nvl(aPAR_Data(vIndex).CURRENCY2, 'NULL') <> vTgtCompLocalCurr)
         and (nvl(aPAR_Data(vIndex).CURRENCY1, 'NULL') = vTgtCompLocalCurr) then
        aPAR_Data(vIndex).PAR_CHARGES_LC     := aPAR_Data(vIndex).PAR_CHARGES_FC;
        aPAR_Data(vIndex).PAR_PAIED_LC       := aPAR_Data(vIndex).PAR_PAIED_FC;
        aPAR_Data(vIndex).PAR_CHARGES_FC     := 0;
        aPAR_Data(vIndex).PAR_PAIED_FC       := 0;
        aPAR_Data(vIndex).PAR_BASE_PRICE     := 0;
        aPAR_Data(vIndex).PAR_EXCHANGE_RATE  := 0;
        aPAR_Data(vIndex).CURRENCY2          := aPAR_Data(vIndex).CURRENCY1;
      end if;
    end loop;
  end Extract_ACI_PART_IMPUTATION;

  /**
   * function ImportXml_ACI_DOCUMENT
   * Description
   *   Méthode pour importer des données ACI_DOCUMENT figurant dans l'XML passé
   *    Les données insérées sont celles des tables ci-dessous qui liées à  l'id ACI_DOCUMENT_ID
   *    ACI_DOCUMENT, ACI_DET_PAYMENT, ACI_EXPIRY, ACI_FINANCIAL_IMPUTATION, ACI_MGM_IMPUTATION
   *    ACI_PART_IMPUTATION, ACI_REMINDER, ACI_REMINDER_TEXT
   */
  function ImportXml_ACI_DOCUMENT(aXML in xmltype)
    return number
  is
    NewACI_DOCUMENT_ID ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    vXML_DET           xmltype;
    vXML_FIN           xmltype;
    vXML_MGM           xmltype;
    vXML_PAR           xmltype;
    vXML_RMT           xmltype;
    vXPath             varchar2(2000);
    vCpt               integer;
    --
    tplDOC             ACI_DOCUMENT%rowtype;
    tblDET             TACI_DET_PAYMENT;
    tblMGM             TACI_MGM_IMPUTATION;
    tblFIN             TACI_FINANCIAL_IMPUTATION;
    tblPAR             TACI_PART_IMPUTATION;
    tblEXP             TACI_EXPIRY;
    tblRMD             TACI_REMINDER;
    tblRMT             TACI_REMINDER_TEXT;
    vLocalCurr         varchar2(5)                         default 'NULL';
    vForeignCurr       varchar2(5)                         default 'NULL';
  begin
    -- Rechercher la monnaie locale
    vTgtCompLocalCurr   := ACS_FUNCTION.GetLocalCurrencyName;

    -- Table directement liées à  la table ACI_DOCUMENT
    select extract(aXML, '/ACI_DOCUMENT/ACI_DET_PAYMENT')
         , extract(aXML, '/ACI_DOCUMENT/ACI_FINANCIAL_IMPUTATION')
         , extract(aXML, '/ACI_DOCUMENT/ACI_MGM_IMPUTATION')
         , extract(aXML, '/ACI_DOCUMENT/ACI_PART_IMPUTATION')
         , extract(aXML, '/ACI_DOCUMENT/ACI_REMINDER_TEXT')
      into vXML_DET
         , vXML_FIN
         , vXML_MGM
         , vXML_PAR
         , vXML_RMT
      from dual;

    -- Extraire les données de la table ACI_DOCUMENT de l'XML
    Extract_ACI_DOCUMENT(tplDOC, aXML);
    NewACI_DOCUMENT_ID  := tplDOC.ACI_DOCUMENT_ID;

    -- Rechercher la monnaie pour l'ACI_DET_PAYMENT dans les données de l'imputation financière ACI_FINANCIAL_IMPUTATION
    begin
      --
      vXPath  := replace('/ACI_DOCUMENT/ACI_FINANCIAL_IMPUTATION/LIST_ITEM[###]/', '###', to_char(1, 'FM999') );

      -- Rechercher la monnaie pour l'ACI_DET_PAYMENT dans les données de l'imputation financière ACI_FINANCIAL_IMPUTATION
      select extractvalue(aXML, vXPath || 'CURRENCY2')
           , extractvalue(aXML, vXPath || 'CURRENCY1')
        into vLocalCurr
           , vForeignCurr
        from dual;
    exception
      when others then
        vLocalCurr    := 'NULL';
        vForeignCurr  := 'NULL';
    end;

    -- Extraire les données de la table ACI_DET_PAYMENT de l'XML
    Extract_ACI_DET_PAYMENT(tblDET, vXML_DET, NewACI_DOCUMENT_ID, null, vLocalCurr, vForeignCurr);
    --
    -- Extraire les données de la table ACI_MGM_IMPUTATION de l'XML
    Extract_ACI_MGM_IMPUTATION(tblMGM, vXML_MGM, NewACI_DOCUMENT_ID, null);
    --
    -- Extraire les données de la table ACI_FINANCIAL_IMPUTATION de l'XML
    Extract_ACI_FIN_IMPUTATION(tblFIN, tblMGM, vXML_FIN, NewACI_DOCUMENT_ID, null);
    --
    -- Extraire les données de la table ACI_REMINDER_TEXT de l'XML
    Extract_ACI_REMINDER_TEXT(tblRMT, vXML_RMT, NewACI_DOCUMENT_ID, null);
    --
    -- Extraire les données de la table ACI_PART_IMPUTATION de l'XML
    Extract_ACI_PART_IMPUTATION(tblPAR, tblDET, tblFIN, tblMGM, tblEXP, tblRMD, tblRMT, vXML_PAR, NewACI_DOCUMENT_ID);

    --
    -- Création du tuple ACI_DOCUMENT
    insert into ACI_DOCUMENT
         values tplDOC;

    -- Création des tuples ACI_PART_IMPUTATION
    if tblPAR.count > 0 then
      forall vCpt in tblPAR.first .. tblPAR.last
        insert into ACI_PART_IMPUTATION
             values tblPAR(vCpt);
    end if;

    -- Création des tuples ACI_DET_PAYMENT
    if tblDET.count > 0 then
      forall vCpt in tblDET.first .. tblDET.last
        insert into ACI_DET_PAYMENT
             values tblDET(vCpt);
    end if;

    -- Création des tuples ACI_FINANCIAL_IMPUTATION
    if tblFIN.count > 0 then
      forall vCpt in tblFIN.first .. tblFIN.last
        insert into ACI_FINANCIAL_IMPUTATION
             values tblFIN(vCpt);
    end if;

    -- Création des tuples ACI_MGM_IMPUTATION
    if tblMGM.count > 0 then
      forall vCpt in tblMGM.first .. tblMGM.last
        insert into ACI_MGM_IMPUTATION
             values tblMGM(vCpt);
    end if;

    -- Création des tuples ACI_EXPIRY
    if tblEXP.count > 0 then
      forall vCpt in tblEXP.first .. tblEXP.last
        insert into ACI_EXPIRY
             values tblEXP(vCpt);
    end if;

    -- Création des tuples ACI_REMINDER
    if tblRMD.count > 0 then
      forall vCpt in tblRMD.first .. tblRMD.last
        insert into ACI_REMINDER
             values tblRMD(vCpt);
    end if;

    -- Création des tuples ACI_REMINDER_TEXT
    if tblRMT.count > 0 then
      forall vCpt in tblRMT.first .. tblRMT.last
        insert into ACI_REMINDER_TEXT
             values tblRMT(vCpt);
    end if;

    --
    return NewACI_DOCUMENT_ID;
  exception
    when others then
      raise;
  end ImportXml_ACI_DOCUMENT;
end ACI_XML_DOC_INTEGRATE;
