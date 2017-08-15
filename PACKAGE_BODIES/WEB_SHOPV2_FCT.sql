--------------------------------------------------------
--  DDL for Package Body WEB_SHOPV2_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_SHOPV2_FCT" AS
   /**
    * select * from table(web_shopv2_fct.GET_SHOP_LIST('REF','SST%',1,1348,10086))
    */
    FUNCTION GET_SHOP_LIST(pSEARCH_TYPE  VARCHAR2,
                           pSEARCH_PARAM VARCHAR2,
                           pPC_LANG_ID PCS.PC_LANG.PC_LANG_ID%type,
                           pPAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type,
                           pACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
                         ) RETURN WEB_SHOP_LIST_TABLE PIPELINED IS

   out_rec   web_shop_list;
   sqlstmt   VARCHAR2 (4000);
   TYPE ref0 IS REF CURSOR;
   cur0      ref0;
   pDIC_TARRIF_ID PTC_TARIFF.DIC_TARIFF_ID%type;
   vCurrency pcs.pc_curr.CURRENCY%type;
   vSEARCH_PARAM VARCHAR2(2000);
   vGooMajorReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;
   vProductExist number(1);
  BEGIN

   IF    (pSEARCH_PARAM IS NULL)
      OR (pSEARCH_PARAM = '')
   THEN
      BEGIN
         sqlstmt := 'SELECT null,null,null, null,null,'||
                          ' null,null, null,null, null,'||
                          ' null, null,null, null,null,'||
                          ' null,null, null,null, null,'||
                          ' null, null,null, null,null,'||
                          ' null, null,null,null from dual where rownum=0';

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id,
                  out_rec.sn,
                  out_rec.GOO_MAJOR_REFERENCE,
                  out_rec.TITLE           ,
                  out_rec.TITLE_LINK      ,
                  out_rec.DES_SHORT_DESCRIPTION ,
                  out_rec.DES_LONG_DESCRIPTION  ,
                  out_rec.DES_FREE_DESCRIPTION  ,
                  out_rec.DIC_UNIT_OF_MEASURE,
                  out_rec.FIELD_VALUE1    ,
                  out_rec.FIELD_VALUE2    ,
                  out_rec.FIELD_VALUE3    ,
                  out_rec.URL_NAME1       ,
                  out_rec.URL1            ,
                  out_rec.URL_NAME2       ,
                  out_rec.URL2            ,
                  out_rec.PRICE_TEXT1     ,
                  out_rec.PRICE1          ,
                  out_rec.PRICE_NUMBER1   ,
                  out_rec.PRICE_TEXT2     ,
                  out_rec.PRICE2          ,
                  out_rec.PRICE_NUMBER2   ,
                  out_rec.IMAGE_SMALL1    ,
                  out_rec.IMAGE_TEXT1     ,
                  out_rec.IMAGE_URL1      ,
                  out_rec.IMAGE_SMALL2    ,
                  out_rec.IMAGE_TEXT2     ,
                  out_rec.IMAGE_URL2      ,
                  out_rec.CAN_BE_ORDERED;


            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSIF (pSEARCH_TYPE = 'REF') THEN
      select
        DIC_TARIFF_ID
      into
       pDIC_TARRIF_ID
      from
        PAC_CUSTOM_PARTNER
      where
        PAC_CUSTOM_PARTNER_ID=pPAC_CUSTOM_PARTNER_ID;


      SELECT
        currency into vCurrency
      FROM
        pcs.pc_curr c,
        acs_financial_currency f
      WHERE
        f.pc_curr_id = c.pc_curr_id
        AND acs_financial_currency_id = pACS_FINANCIAL_CURRENCY_ID;


         sqlstmt := 'SELECT g.gco_good_id,'||
                    ' NULL sn, '||
                    ' goo_major_reference, '||
                    ' goo_major_reference title,'||
                    ' ''http://'' title_link, '||
                    ' des_short_description,'||
                    ' des_long_description,'||
                    ' des_free_description,'||
                    ' com_dic_functions.GETDICODESCR(''DIC_UNIT_OF_MEASURE'',DIC_UNIT_OF_MEASURE_ID,'||pPC_LANG_ID||') dic_unit_of_measure,'||
                    ' ''FIELD_VALUE1 from sql'' field_value1,'||
                    '  null field_value2,'||
                    ' ''FIELD_VALUE3 from sql'' field_value3, '||
                    ' ''lien fournisseur'' url_name1,'||
                    ' ''http://www.proconcept.ch?ref=''||goo_major_reference url1,'||
                    ' ''Catégorie produit'' url_name2,'||
                    ' ''http://www.proconcept.ch'' url2,'||
                    ' ''Prix'' price_text1, '||
                    ' ptc_find_tariff.gettariffprice(ptc_find_tariff.gettariffdirect (g.gco_good_id,'||
                                               pPAC_CUSTOM_PARTNER_ID||','||
                    '                          NULL,'||
                                               pACS_FINANCIAL_CURRENCY_ID||','||
                    '                          '''||pDIC_TARRIF_ID||''','||
                    '                          1,'||
                    '                          SYSDATE,'||
                    '                          ''A_FACTURER'','||
                    '                         ''1'''||
                    '                          ),'||
                    '1 )  price1,'||
                    ' ''Price action spécial'' price_text2,'||
                    ' null price2,'||
                    ' GOO_MAJOR_REFERENCE image_text1, '||
                    '(select ''./imagesCatalog/''||imf_file from com_image_files where imf_key01=''UrlSmall'' and imf_rec_id=g.gco_good_id) image_small1,'||
                    '(select ''./imagesCatalog/''||imf_file from com_image_files where imf_key01=''UrlLarge'' and imf_rec_id=g.gco_good_id) image_url1,'||
                    ' ''image txt3'' image_text2, '||
                    ' ''./imagesCatalog/s_eclate.jpg'' image_small2,'||
                    ' ''./imagesCatalog/l_eclate.jpg'' image_url2,'||
                    ' ''0'' CAN_BE_ORDERED '||
                    'FROM  '||
                    'GCO_GOOD g,'||
                    'GCO_DESCRIPTION d,'||
                    'WEB_GOOD W '||
                    'WHERE '||
                    ' w.gco_good_id(+)=g.gco_good_id '   ||
                    ' AND goo_web_published=1 '||
                    ' AND pc_lang_id = '||pPC_LANG_ID    ||
                    ' AND d.gco_good_id = g.gco_good_id '||
                    ' AND c_description_type = ''01'''   ||
                    ' AND (goo_major_reference LIKE :param)'||
                    ' AND ROWNUM<500 ORDER BY GOO_MAJOR_REFERENCE ';

         vSEARCH_PARAM := pSEARCH_PARAM||'%';

         OPEN cur0 FOR sqlstmt USING vSEARCH_PARAM;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id,
                  out_rec.sn,
                  out_rec.GOO_MAJOR_REFERENCE,
                  out_rec.TITLE           ,
                  out_rec.TITLE_LINK      ,
                  out_rec.DES_SHORT_DESCRIPTION ,
                  out_rec.DES_LONG_DESCRIPTION  ,
                  out_rec.DES_FREE_DESCRIPTION  ,
                  out_rec.DIC_UNIT_OF_MEASURE,
                  out_rec.FIELD_VALUE1    ,
                  out_rec.FIELD_VALUE2    ,
                  out_rec.FIELD_VALUE3    ,
                  out_rec.URL_NAME1       ,
                  out_rec.URL1            ,
                  out_rec.URL_NAME2       ,
                  out_rec.URL2            ,
                  out_rec.PRICE_TEXT1     ,
                  out_rec.PRICE_NUMBER1   ,
                  out_rec.PRICE_TEXT2     ,
                  out_rec.PRICE_NUMBER2   ,
                  out_rec.IMAGE_TEXT1     ,
                  out_rec.IMAGE_SMALL1    ,
                  out_rec.IMAGE_URL1      ,
                  out_rec.IMAGE_TEXT2     ,
                  out_rec.IMAGE_SMALL2    ,
                  out_rec.IMAGE_URL2      ,
                  out_rec.CAN_BE_ORDERED;


            if (out_rec.PRICE_NUMBER1 is null) then
              out_rec.PRICE1 := 'Sur demande';
              out_rec.PRICE_NUMBER1 := 0;
              out_rec.CAN_BE_ORDERED := 0;
            else
              out_rec.PRICE1 := out_rec.PRICE_NUMBER1 ||' '||vCurrency||' / '||out_rec.DIC_UNIT_OF_MEASURE;
              out_rec.CAN_BE_ORDERED := 1;
            end if;

            if (out_rec.PRICE_NUMBER2 is null) then
              out_rec.PRICE_TEXT2 := null;
              out_rec.PRICE_NUMBER2 := 0;
            else
              out_rec.PRICE2 := out_rec.PRICE_NUMBER2 ||' '||vCurrency||' / '||out_rec.DIC_UNIT_OF_MEASURE;
            end if;

            out_rec.HTML_INFO1 :='<span class="OraDataText">Disponibilité</span>';
            --out_rec.HTML_INFO2 :='<span class="OraDataText" style="background-image: url(images/TrafficRed.gif);background-repeat:no-repeat;background-position:right"> Non dispo<br>pour le moment</span>';
            select
              '<table border="0" width="100%"><tr><td align="left"><img src="images/TrafficRed.gif" alt="'||pcs.pc_functions.TRANSLATEWORD('Non disponible',pPC_LANG_ID)||'"/></td></tr></table>'
              into out_rec.HTML_INFO2
            from dual;


            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

   END IF;

  END;


  FUNCTION GET_DOCUMENT_LIST(pSEARCH_TYPE  VARCHAR2,
                             pSEARCH_PARAM VARCHAR2,
                             pPC_LANG_ID PCS.PC_LANG.PC_LANG_ID%type,
                             pPAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
                         ) RETURN WEB_DOCUMENT_LIST_TABLE PIPELINED IS

   out_rec   web_document_list;
   sqlstmt   VARCHAR2 (4000);
   TYPE ref0 IS REF CURSOR;
   cur0      ref0;
   vSEARCH_PARAM VARCHAR2(2000);
  BEGIN

   IF    (pSEARCH_PARAM IS NULL)
      OR (pSEARCH_PARAM = '')
   THEN
      BEGIN
         sqlstmt := 'SELECT null,null,null, null,'||
                          ' null,null, null,null from dual where rownum=0';

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
             INTO out_rec.DOC_DOCUMENT_ID,
                  out_rec.DMT_TITLE_TEXT,
                  out_rec.DMT_NUMBER,
                  out_rec.DOC_STATE,
                  out_rec.INFO_DOC1,
                  out_rec.INFO_DOC2,
                  out_rec.INFO_DOC3,
                  out_rec.INFO_DOC4 ;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;
         CLOSE cur0;
         RETURN;
      END;

   ELSIF (pSEARCH_TYPE = 'STD') THEN --recherche par no

         sqlstmt := 'select '||
                    'd.doc_document_id,'||
                    'dmt_title_text,'||
                    'dmt_number,'||
                    'pcs.pc_functions.GETDESCODEDESCR(''C_DOCUMENT_STATUS'',c_document_status, '||pPC_LANG_ID||') DOC_STATE,'||
                    'dmt_partner_number INFO_DOC1,'||
                    'f.FOO_DOCUMENT_TOTAL_AMOUNT||'' ''||acs_function.GETCURRENCYNAME(acs_financial_currency_id) INFO_DOC2,'||
                    ' '' '' INFO_DOC3,'||
                    'to_char(d.DMT_DATE_DOCUMENT) INFO_DOC4'||
                  ' from '||
                  '  doc_document d,'||
                  '  doc_foot f '||
                  'where '||
                  '  d.doc_document_id=f.doc_document_id'||
                  '  and d.pac_third_id='||pPAC_CUSTOM_PARTNER_ID||
                  '  and dmt_number like :DMT_NUMBER'||
                  ' order by dmt_number desc ';


         vSEARCH_PARAM := pSEARCH_PARAM||'%';


         OPEN cur0 FOR sqlstmt USING vSEARCH_PARAM;

         LOOP
            FETCH cur0
             INTO out_rec.DOC_DOCUMENT_ID,
                  out_rec.DMT_TITLE_TEXT,
                  out_rec.DMT_NUMBER,
                  out_rec.DOC_STATE,
                  out_rec.INFO_DOC1,
                  out_rec.INFO_DOC2,
                  out_rec.INFO_DOC3,
                  out_rec.INFO_DOC4;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;
         CLOSE cur0;
         RETURN;

   END IF;
  END GET_DOCUMENT_LIST;


   /**
    * Cette fonction retourne le détail de nomenclature
    * select * from table(web_shopv2_fct.GET_SHOP_BOM_LIST(123,1,1348,10086))
    *
    */
    FUNCTION GET_SHOP_BOM_LIST(pPPS_NOMENCLATURE_ID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type,
                           pPC_LANG_ID PCS.PC_LANG.PC_LANG_ID%type,
                           pPAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type,
                           pACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
                         ) RETURN WEB_SHOP_BOM_LIST_TABLE PIPELINED IS

     out_rec   web_shop_bom_list;
     sqlstmt   VARCHAR2 (4000);
     TYPE ref0 IS REF CURSOR;
     cur0      ref0;
     pDIC_TARRIF_ID PTC_TARIFF.DIC_TARIFF_ID%type;
     vCurrency pcs.pc_curr.CURRENCY%type;
  BEGIN

   IF    (pPPS_NOMENCLATURE_ID IS NULL)
   THEN
      BEGIN
         sqlstmt := 'SELECT null, null, null, null, null,'||
                          ' null, null, null, null, null,'||
                          ' null, null, null, null, null,'||
                          ' null, null, null, null, null,'||
                          ' null from dual where rownum=0';

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
              INTO  out_rec.PPS_NOMENCLATURE_ID
                   ,out_rec.COM_POS
                   ,out_rec.COM_UTIL_COEFF
                   ,out_rec.COM_TEXT
                   ,out_rec.gco_good_id
                   ,out_rec.goo_major_reference
                   ,out_rec.des_short_description
                   ,out_rec.des_long_description
                   ,out_rec.des_free_description
                   ,out_rec.dic_unit_of_measure
                   ,out_rec.FIELD_VALUE1
                   ,out_rec.FIELD_VALUE2
                   ,out_rec.FIELD_VALUE3
                   ,out_rec.PRICE_TEXT1
                   ,out_rec.price1
                   ,out_rec.PRICE_TEXT2
                   ,out_rec.price2
                   ,out_rec.can_be_ordered
                   ,out_rec.COM_SEQ
                   ,out_rec.price_number1
                   ,out_rec.price_number2;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSE

      select
        DIC_TARIFF_ID
      into
       pDIC_TARRIF_ID
      from
        PAC_CUSTOM_PARTNER
      where
        PAC_CUSTOM_PARTNER_ID=pPAC_CUSTOM_PARTNER_ID;


      SELECT
        currency into vCurrency
      FROM
        pcs.pc_curr c,
        acs_financial_currency f
      WHERE
        f.pc_curr_id = c.pc_curr_id
        AND acs_financial_currency_id = pACS_FINANCIAL_CURRENCY_ID;

         sqlstmt := 'select '||
                    'n.PPS_NOMENCLATURE_ID ' ||
                    ',n.COM_POS '||
                    ',n.COM_UTIL_COEFF'||
                    ',n.COM_TEXT'||
                    ',g.gco_good_id'||
                    ',g.goo_major_reference'||
                    ',d.des_short_description des_short_description'||
                    ',d.des_long_description'||
                    ',d.des_free_description'||
                    ',dic_unit_of_measure_id dic_unit_of_measure'||
                    ','''' FIELD_VALUE1'||
                    ','''' FIELD_VALUE2'||
                    ','''' FIELD_VALUE3'||
                    ',''Prix'' PRICE_TEXT1'||
                    ', null price1'||
                    ',''Prix action'' PRICE_TEXT2'||
                    ', null price2'||
                    ',1 can_be_ordered'||
                    ',COM_SEQ'||
                    --',0'||
                    ', ptc_find_tariff.gettariffprice(ptc_find_tariff.gettariffdirect (g.gco_good_id,'||
                                                                 pPAC_CUSTOM_PARTNER_ID||','||
                                      '                          NULL,'||
                                                                 pACS_FINANCIAL_CURRENCY_ID||','||
                                      '                          '''||pDIC_TARRIF_ID||''','||
                                      '                          1,'||
                                      '                          SYSDATE,'||
                                      '                          ''A_FACTURER'','||
                                      '                         ''1'''||
                                      '                          ),1) price_number1'||
                  ',null price_number2 '||
                  ' from'||
                  '  gco_good g'||
                  '  ,gco_description d'||
                  '  ,pps_nom_bond n '||
                  'where'||
                  '  n.GCO_GOOD_ID = g.GCO_GOOD_ID'||
                  '  and g.gco_good_id=d.gco_good_id'||
                  '  and pc_lang_id='||pPC_LANG_ID||
                  '  and c_Description_type=''01'''||
                  '  and PPS_NOMENCLATURE_ID='||pPPS_NOMENCLATURE_ID||
                  ' order by com_seq';

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
              INTO out_rec.PPS_NOMENCLATURE_ID
                   ,out_rec.COM_POS
                   ,out_rec.COM_UTIL_COEFF
                   ,out_rec.COM_TEXT
                   ,out_rec.gco_good_id
                   ,out_rec.goo_major_reference
                   ,out_rec.des_short_description
                   ,out_rec.des_long_description
                   ,out_rec.des_free_description
                   ,out_rec.dic_unit_of_measure
                   ,out_rec.FIELD_VALUE1
                   ,out_rec.FIELD_VALUE2
                   ,out_rec.FIELD_VALUE3
                   ,out_rec.PRICE_TEXT1
                   ,out_rec.price1
                   ,out_rec.PRICE_TEXT2
                   ,out_rec.price2
                   ,out_rec.can_be_ordered
                   ,out_rec.COM_SEQ
                   ,out_rec.price_number1
                   ,out_rec.price_number2;

            if (out_rec.PRICE_NUMBER1 is null) then
              out_rec.PRICE1 := 'Sur demande';
              out_rec.PRICE_NUMBER1 := 0;
              out_rec.CAN_BE_ORDERED := 0;
            else
              out_rec.PRICE1 := out_rec.PRICE_NUMBER1 ||' '||vCurrency||' / '||out_rec.DIC_UNIT_OF_MEASURE;
              out_rec.CAN_BE_ORDERED := 1;
            end if;

            if (out_rec.PRICE_NUMBER2 is null) then
              out_rec.PRICE_TEXT2 := null;
              out_rec.PRICE_NUMBER2 := 0;
            else
              out_rec.PRICE2 := out_rec.PRICE_NUMBER2 ||' '||vCurrency||' / '||out_rec.DIC_UNIT_OF_MEASURE;
            end if;

            --out_rec.HTML_INFO1 :='<span class="OraDataText">Disponibilité</span>';
            out_rec.HTML_INFO1 :=' ';
            --out_rec.HTML_INFO2 :='<span class="OraDataText" style="background-image: url(images/TrafficRed.gif);background-repeat:no-repeat;background-position:right"> Non dispo<br>pour le moment</span>';
            select
              '<table border="0" width="100%"><tr><td align="left"><img src="images/TrafficRed.gif" alt="'||pcs.pc_functions.TRANSLATEWORD('Non disponible',pPC_LANG_ID)||'"/></td></tr></table>'
              into out_rec.HTML_INFO2
            from dual;


            EXIT WHEN cur0%NOTFOUND;

            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

   END IF;

  END GET_SHOP_BOM_LIST;

   /**select * from table(web_shopv2_fct.GET_SHOP_CORRELATED_LIST(1385495,1,1348,10086))*/

  FUNCTION GET_SHOP_CORRELATED_LIST(pGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type,
                           pPC_LANG_ID PCS.PC_LANG.PC_LANG_ID%type,
                           pPAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type,
                           pACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
                         ) RETURN WEB_SHOP_CORRELATED_LIST_TABLE PIPELINED IS
     out_rec   web_shop_correlated_list;
     sqlstmt   VARCHAR2 (4000);
     TYPE ref0 IS REF CURSOR;
     cur0      ref0;
     pDIC_TARRIF_ID PTC_TARIFF.DIC_TARIFF_ID%type;
     vCurrency pcs.pc_curr.CURRENCY%type;
  BEGIN

   IF    (pGCO_GOOD_ID IS NULL)
   THEN
      BEGIN
         sqlstmt := 'SELECT null, null, null, null, null,'||
                          ' null, null, null, null, null,'||
                          ' null, null, null, null, null,'||
                          ' null, null, null '||
                          ' from dual where rownum=0';

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
              INTO  out_rec.GCO_GOOD_ID
                   ,out_rec.DIC_CONNECTED_TYPE
                   ,out_rec.goo_major_reference
                   ,out_rec.des_short_description
                   ,out_rec.des_long_description
                   ,out_rec.des_free_description
                   ,out_rec.dic_unit_of_measure
                   ,out_rec.FIELD_VALUE1
                   ,out_rec.FIELD_VALUE2
                   ,out_rec.FIELD_VALUE3
                   ,out_rec.PRICE_TEXT1
                   ,out_rec.price1
                   ,out_rec.PRICE_TEXT2
                   ,out_rec.price2
                   ,out_rec.can_be_ordered
                   ,out_rec.price_number1
                   ,out_rec.price_number2
                   ,out_rec.CONNECTED_GOOD_ID;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSE

      select
        DIC_TARIFF_ID
      into
       pDIC_TARRIF_ID
      from
        PAC_CUSTOM_PARTNER
      where
        PAC_CUSTOM_PARTNER_ID=pPAC_CUSTOM_PARTNER_ID;


      SELECT
        currency into vCurrency
      FROM
        pcs.pc_curr c,
        acs_financial_currency f
      WHERE
        f.pc_curr_id = c.pc_curr_id
        AND acs_financial_currency_id = pACS_FINANCIAL_CURRENCY_ID;


         sqlstmt := 'select c.GCO_GOOD_ID ' ||
                    ',com_dic_functions.GETDICODESCR(''DIC_CONNECTED_TYPE'',DIC_CONNECTED_TYPE_ID,'||pPC_LANG_ID||')  DIC_CONNECTED_TYPE '||
                    ',g.goo_major_reference'||
                    ',d.des_short_description||'' indiv'' des_short_description'||
                    ',d.des_long_description'||
                    ',d.des_free_description'||
                    ',dic_unit_of_measure_id dic_unit_of_measure'||
                    ','''' FIELD_VALUE1'||
                    ','''' FIELD_VALUE2'||
                    ','''' FIELD_VALUE3'||
                    ',''Prix'' PRICE_TEXT1'||
                    ', null price1'||
                    ',''Prix action'' PRICE_TEXT2'||
                    ', null price2'||
                    ',1 can_be_ordered'||
                    ', ptc_find_tariff.gettariffprice(ptc_find_tariff.gettariffdirect (g.gco_good_id,'||
                                                                 pPAC_CUSTOM_PARTNER_ID||','||
                                      '                          NULL,'||
                                                                 pACS_FINANCIAL_CURRENCY_ID||','||
                                      '                          '''||pDIC_TARRIF_ID||''','||
                                      '                          1,'||
                                      '                          SYSDATE,'||
                                      '                          ''A_FACTURER'','||
                                      '                         ''1'''||
                                      '                          ),1) price_number1'||
                    ',null price_number2 '||
                    ', gco_gco_good_id'||
                  ' from'||
                  '  gco_good g'||
                  '  ,gco_description d'||
                  '  ,gco_connected_good c '||
                  'where'||
                  '  c.GCO_GCO_GOOD_ID = g.GCO_GOOD_ID'||
                  '  and g.gco_good_id=d.gco_good_id'||
                  '  and pc_lang_id='||pPC_LANG_ID||
                  '  and c_Description_type=''01'''||
                  '  and c.gco_good_id='||pGCO_GOOD_ID;

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
              INTO  out_rec.GCO_GOOD_ID
                   ,out_rec.DIC_CONNECTED_TYPE
                   ,out_rec.goo_major_reference
                   ,out_rec.des_short_description
                   ,out_rec.des_long_description
                   ,out_rec.des_free_description
                   ,out_rec.dic_unit_of_measure
                   ,out_rec.FIELD_VALUE1
                   ,out_rec.FIELD_VALUE2
                   ,out_rec.FIELD_VALUE3
                   ,out_rec.PRICE_TEXT1
                   ,out_rec.price1
                   ,out_rec.PRICE_TEXT2
                   ,out_rec.price2
                   ,out_rec.can_be_ordered
                   ,out_rec.price_number1
                   ,out_rec.price_number2
                   ,out_rec.CONNECTED_GOOD_ID;


            if (out_rec.PRICE_NUMBER1 is null) then
              out_rec.PRICE1 := 'Sur demande';
              out_rec.PRICE_NUMBER1 := 0;
              out_rec.CAN_BE_ORDERED := 0;
            else
              out_rec.PRICE1 := out_rec.PRICE_NUMBER1 ||' '||vCurrency||' / '||out_rec.DIC_UNIT_OF_MEASURE;
              out_rec.CAN_BE_ORDERED := 1;
            end if;

            if (out_rec.PRICE_NUMBER2 is null) then
              out_rec.PRICE_TEXT2 := null;
              out_rec.PRICE_NUMBER2 := 0;
            else
              out_rec.PRICE2 := out_rec.PRICE_NUMBER2 ||' '||vCurrency||' / '||out_rec.DIC_UNIT_OF_MEASURE;
            end if;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

   END IF;

  END GET_SHOP_CORRELATED_LIST;

END WEB_SHOPV2_FCT;
