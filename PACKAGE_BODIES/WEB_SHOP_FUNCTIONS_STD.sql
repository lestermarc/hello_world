--------------------------------------------------------
--  DDL for Package Body WEB_SHOP_FUNCTIONS_STD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_SHOP_FUNCTIONS_STD" AS

/**
*
*  Package std ne pas modifier
*  Pour les indiv :
*  Utiliser le package WEB_SHOP_FUNCTIONS_CUST pour définir la nouvelle fonction et son traitement
*  Puis modifier l'appel
*
*/

/** **************************************************************************************
* FUNCTION getAvailableQuantityWeb
*
*
******************************************************************************************/
FUNCTION getAvailableQuantityWeb(pGcoGoodId          IN GCO_GOOD.GCO_GOOD_ID%TYPE,
                                   pPacCustomPartnerId IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%TYPE) RETURN NUMBER
IS
  n NUMBER;
BEGIN
--	RETURN nvl(Stm_Functions.GetAvailableQuantity(pGcoGoodId),0);

SELECT (NVL (SPO_STOCK_QUANTITY,0) - NVL (SPO_PROVISORY_OUTPUT,0) + NVL (SPO_PROVISORY_INPUT,0) - BESOIN - NVL (STOCK_QTY,0)  + APPRO) THEORETICAL_TEPS
      INTO n
 FROM
  (SELECT SUM  (SPO_AVAILABLE_QUANTITY) SPO_AVAILABLE_QUANTITY,SUM (SPO_STOCK_QUANTITY) SPO_STOCK_QUANTITY,SUM (SPO_AVAILABLE_QUANTITY) +SUM (SPO_PROVISORY_INPUT) SPO_AVAILABLE_QTY_B,SUM (SPO_THEORETICAL_QUANTITY) SPO_THEORETICAL_QUANTITY,SUM (SPO_ASSIGN_QUANTITY) SPO_ASSIGN_QUANTITY,SUM (SPO_PROVISORY_INPUT) SPO_PROVISORY_INPUT,SUM (SPO_PROVISORY_OUTPUT) SPO_PROVISORY_OUTPUT,SUM (SPO_ALTERNATIV_QUANTITY_1) SPO_ALTERNATIV_QUANTITY_1,SUM (SPO_ALTERNATIV_QUANTITY_2) SPO_ALTERNATIV_QUANTITY_2,SUM (SPO_ALTERNATIV_QUANTITY_3) SPO_ALTERNATIV_QUANTITY_3
 FROM
  STM_STOCK_POSITION
 WHERE
  GCO_GOOD_ID = pGcoGoodId
),
  (SELECT NVL (SUM (NVL (FAN_FREE_QTY,0) + NVL (FAN_NETW_QTY,0) ),0) BESOIN,NVL (SUM (FAN_STK_QTY),0) STOCK_QTY
 FROM
  FAL_NETWORK_NEED
 WHERE
  GCO_GOOD_ID =pGcoGoodId),
  (SELECT NVL (SUM (FAN_BALANCE_QTY),0) APPRO
 FROM
  FAL_NETWORK_SUPPLY
 WHERE
  GCO_GOOD_ID =pGcoGoodId);

  RETURN n;
END;


/** **************************************************************************************
* FUNCTION getLinkedImageName
*
*
******************************************************************************************/
FUNCTION getLinkedImageName(pGcoGoodId GCO_GOOD.GCO_GOOD_ID%TYPE,
                            pClfKey01 COM_IMAGE_FILES.IMF_KEY01%TYPE) RETURN VARCHAR2 IS
  filename COM_IMAGE_FILES.IMF_FILE%TYPE;
  CURSOR getImg(ID GCO_GOOD.GCO_GOOD_ID%TYPE,
                key01 COM_IMAGE_FILES.IMF_KEY01%TYPE) IS
SELECT
  IMF_FILE
FROM
  COM_IMAGE_FILES A
WHERE
  A.IMF_KEY01=key01 AND
  A.IMF_TABLE='GCO_GOOD' AND
  IMF_REC_ID=ID
ORDER BY
  IMF_SEQUENCE DESC;
  BEGIN
    OPEN getImg(pGcoGoodId,pClfKey01);
	FETCH getImg INTO filename;
	IF (getImg%NOTFOUND) THEN
	  filename:='defaultSmallImg.jpg';
	END IF;
	CLOSE getImg;
	RETURN filename;
  END getLinkedImageName;


/** **************************************************************************************
* FUNCTION getWebCategArrayInfoOld
*
*
******************************************************************************************/
FUNCTION getWebCategArrayInfoOld( pWebCategArrayId        IN WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%TYPE,
								 pPcLangId               IN PCS.PC_LANG.PC_LANG_ID%TYPE,
								 pColumnName             IN VARCHAR2) RETURN VARCHAR2 IS

  CURSOR getInfo(ID WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%TYPE,
                 langId PCS.PC_LANG.PC_LANG_ID%TYPE) IS
		SELECT
		 WEB_CATEG_ARRAY_ID,
		 NVL(wcd_descr,'?') AS wcd_descr,
		 NVL(wcd_long_descr, NVL(wcd_descr,'?')) AS wcd_long_descr,
		 NVL(wcd_picture_url,wca_picture_url) AS wcd_picture_url,
		  NVL(wcd_picture_hint,wca_picture_hint) AS wcd_picture_hint,
		 pc_lang_id,
		 web_categ_id_level1
		FROM
		  WEB_CATEG_ARRAY wca,
		  WEB_CATEG_DESCR wcd,
		  WEB_CATEG c
		WHERE
		  wca_level=1 AND
		  wca_is_active=1 AND
		  web_categ_id_level1=wcd.web_categ_id AND
		  c.web_categ_id=wcd.web_categ_id  AND PC_LANG_ID=langId AND WEB_CATEG_ARRAY_ID=ID;

		vInfoRow getInfo%ROWTYPE;
		vReturn WEB_CATEG_DESCR.wcd_long_descr%TYPE;
  BEGIN

    OPEN getInfo(pWebCategArrayId,pPcLangId);
	FETCH getInfo INTO vInfoRow;

	IF (getInfo%NOTFOUND) THEN
	  vReturn:=NULL;
	ELSIF (pColumnName='WCD_DESCR') THEN
	  vReturn:=vInfoRow.WCD_DESCR;
	ELSIF (pColumnName='WCD_LONG_DESCR') THEN
	  vReturn:=vInfoRow.WCD_LONG_DESCR;
	ELSIF (pColumnName='WCD_PICTURE_URL') THEN
	  vReturn:=vInfoRow.WCD_PICTURE_URL;
  	ELSIF (pColumnName='WCD_PICTURE_HINT') THEN
      vReturn:=vInfoRow.WCD_PICTURE_HINT;
	END IF;
    CLOSE getInfo;
	RETURN vReturn;

END;

/** **************************************************************************************
* FUNCTION getWebCategArrayInfo
*
*
******************************************************************************************/
FUNCTION getWebCategArrayInfo( pWebCategArrayId        IN WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%TYPE,
								 pPcLangId               IN PCS.PC_LANG.PC_LANG_ID%TYPE,
								 pColumnName             IN VARCHAR2) RETURN VARCHAR2 IS


  CURSOR getInfo(ID WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%TYPE,
                 langId PCS.PC_LANG.PC_LANG_ID%TYPE) IS
	SELECT
         WEB_CATEG_ARRAY_ID,
		 NVL(wcd_descr,'?') AS wcd_descr,
		 wcd_long_descr,
		 NVL(wcd_picture_url,wca_picture_url) AS wcd_picture_url,
		 NVL(wcd_picture_hint,wca_picture_hint) AS wcd_picture_hint,
		 pc_lang_id,
		 wca_level,
		 web_categ_id_level1,
		 web_categ_id_level2,
		 web_categ_id_level3,
		 web_categ_id_level4,
		 web_categ_id_level5
		FROM
		  WEB_CATEG_ARRAY wca,
		  WEB_CATEG_DESCR wcd,
		  WEB_CATEG c
		WHERE
		  ((web_categ_id_level1=wcd.web_categ_id AND wca_level=1) OR
		   (web_categ_id_level2=wcd.web_categ_id AND wca_level=2) OR
		   (web_categ_id_level3=wcd.web_categ_id AND wca_level=3) OR
		   (web_categ_id_level4=wcd.web_categ_id AND wca_level=4) OR
		   (web_categ_id_level5=wcd.web_categ_id AND wca_level=5)) AND
		  c.web_categ_id=wcd.web_categ_id  AND
		  PC_LANG_ID=langId AND
		  WEB_CATEG_ARRAY_ID=ID;

		vInfoRow getInfo%ROWTYPE;
		vReturn WEB_CATEG_DESCR.wcd_long_descr%TYPE;
		vWcdDescr WEB_CATEG_DESCR.wcd_long_descr%TYPE;
  BEGIN

    OPEN getInfo(pWebCategArrayId,pPcLangId);
	FETCH getInfo INTO vInfoRow;

	IF (getInfo%NOTFOUND) THEN
	  vReturn:=NULL;
	ELSIF (pColumnName='WCD_DESCR') THEN
	  vReturn:=vInfoRow.WCD_DESCR;
	ELSIF (pColumnName='WCD_LONG_DESCR') THEN
	  vReturn:=vInfoRow.WCD_LONG_DESCR;
	ELSIF (pColumnName='WCD_PICTURE_URL') THEN
	  vReturn:=vInfoRow.WCD_PICTURE_URL;
  	ELSIF (pColumnName='WCD_PICTURE_HINT') THEN
      vReturn:=vInfoRow.WCD_PICTURE_HINT;
  	ELSIF (pColumnName='PATH') THEN
	  BEGIN
        vReturn := vInfoRow.WCD_DESCR;
	    IF (vInfoRow.wca_level>1) THEN
		  BEGIN
		  SELECT wcd_descr INTO vWcdDescr FROM WEB_CATEG_DESCR b WHERE web_Categ_id=vInfoRow.web_categ_id_level2 AND pc_lang_id=pPcLangId;
		  vReturn := vReturn||' > '||vWcdDescr;
	      END;
	    END IF;
	    IF (vInfoRow.wca_level>2) THEN
		  BEGIN
		  SELECT wcd_descr INTO vWcdDescr FROM WEB_CATEG_DESCR b WHERE web_Categ_id=vInfoRow.web_categ_id_level3 AND pc_lang_id=pPcLangId;
		  vReturn := vReturn||' > '||vWcdDescr;
	      END;
	    END IF;
	    IF (vInfoRow.wca_level>3) THEN
		  BEGIN
		  SELECT wcd_descr INTO vWcdDescr FROM WEB_CATEG_DESCR b WHERE web_Categ_id=vInfoRow.web_categ_id_level4 AND pc_lang_id=pPcLangId;
		  vReturn := vReturn||' > '||vWcdDescr;
	      END;
	    END IF;
	    IF (vInfoRow.wca_level>4) THEN
		  BEGIN
		  SELECT wcd_descr INTO vWcdDescr FROM WEB_CATEG_DESCR b WHERE web_Categ_id=vInfoRow.web_categ_id_level5 AND pc_lang_id=pPcLangId;
		  vReturn := vReturn||' > '||vWcdDescr;
	      END;
	    END IF;



	  END;
	END IF;
    CLOSE getInfo;
	RETURN vReturn;

END;

/** **************************************************************************************
* FUNCTION getPurchaseOrderMultiColInfo
*
*
******************************************************************************************/
FUNCTION getPurchaseOrderMultiColInfo( pGcoGoodId              IN GCO_GOOD.GCO_GOOD_ID%TYPE,
                                       pPacCustomPartnerId     IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%TYPE,
								       pAcsFinancialCurrencyId IN ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%TYPE,
									   pPcLangId               IN PCS.PC_LANG.PC_LANG_ID%TYPE,
									   pColumnIndex            IN NUMBER) RETURN VARCHAR2 IS

CURSOR getInfo(pGoodId GCO_GOOD.GCO_GOOD_ID%TYPE,
                pPcLangId PCS.PC_LANG.PC_LANG_ID%TYPE,
				pCDescriptionType IN GCO_DESCRIPTION.C_DESCRIPTION_TYPE%TYPE ) IS
  SELECT
    g.GOO_MAJOR_REFERENCE,
    d.DES_SHORT_DESCRIPTION
  FROM
    GCO_DESCRIPTION d,
	GCO_GOOD g
  WHERE
    g.GCO_GOOD_ID=d.GCO_GOOD_ID AND
    d.GCO_GOOD_ID=pGoodId AND
	d.PC_LANG_ID=pPcLangId AND
	d.C_DESCRIPTION_TYPE=pCDescriptionType;

vInfoRow getInfo%ROWTYPE;

vreturn GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%TYPE;

BEGIN
OPEN getInfo(pGcoGoodId,pPcLangId,'09');
FETCH getInfo INTO vInfoRow;

IF    (pColumnIndex=1)
  THEN vreturn := vInfoRow.GOO_MAJOR_REFERENCE;
ELSIF (pColumnIndex=2)
  THEN vreturn := vInfoRow.DES_SHORT_DESCRIPTION;
ELSE
  vreturn :='?';
END IF;

CLOSE getInfo;
RETURN vreturn;

END;


/** **************************************************************************************
* FUNCTION getWebCategArrayRight4WebUser
*
*
******************************************************************************************/
FUNCTION getWebCategArrayRight4WebUser(pWebCategArrayId        IN WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%TYPE,
								       pWebUserId              IN WEB_USER.WEB_USER_ID%TYPE) RETURN NUMBER IS
  ret WEB_CATEG_ARRAY_RIGHT.WCA_RIGHT%TYPE;
BEGIN
  SELECT wca_right INTO ret
  FROM WEB_CATEG_ARRAY_RIGHT WHERE web_categ_array_id=pWebCategArrayId AND web_user_id=pWebUserId;
  RETURN ret;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    BEGIN
	  RETURN 1;
	END;
END;


/** **************************************************************************************
* FUNCTION SetRightForUserToCatalog
*
*
******************************************************************************************/
PROCEDURE SetRightForUserToCatalog(pWebUserId IN WEB_USER.WEB_USER_ID%TYPE,
                                   pWebCategArrayId IN WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%TYPE,
								   pRight IN WEB_CATEG_ARRAY_RIGHT.WCA_RIGHT%TYPE) IS

  vExist NUMBER(1);

BEGIN
  -- try to update if exists
SELECT COUNT(*) INTO vExist
FROM
  WEB_CATEG_ARRAY_RIGHT
WHERE
  web_user_id=pWebUserId AND
  web_categ_Array_id=pWebCategArrayId;

  IF (vExist=1) THEN
    BEGIN
    UPDATE WEB_CATEG_ARRAY_RIGHT SET wca_right= pRight
    WHERE
      web_user_id=pWebUserId AND
      web_categ_Array_id=pWebCategArrayId;
	END;
  ELSE
    BEGIN

  -- if not, create new row
    INSERT INTO WEB_CATEG_ARRAY_RIGHT ( WEB_CATEG_ARRAY_RIGHT_ID, WEB_USER_ID, WEB_CATEG_ARRAY_ID, WCA_RIGHT )
	VALUES (
    INIT_ID_SEQ.NEXTVAL, pWebUserId, pWebCategArrayId, pRight );

   END;

  END IF;

END;


/** **************************************************************************************
* FUNCTION ActivateAllWebCategArray
*
*
******************************************************************************************/
PROCEDURE ActivateAllWebCategArray IS
BEGIN

	UPDATE WEB_GOOD SET WGO_IS_ACTIVE=1;

	UPDATE WEB_CATEG_ARRAY SET WCA_IS_ACTIVE=0;

	UPDATE WEB_CATEG_ARRAY SET WCA_IS_ACTIVE=1 WHERE WEB_CATEG_ARRAY_ID IN (SELECT DISTINCT WEB_CATEG_ARRAY_ID FROM WEB_GOOD);

	UPDATE WEB_CATEG_ARRAY SET WCA_IS_ACTIVE=1 WHERE web_categ_array_id IN (SELECT DISTINCT web_categ_Array_id_parent1 FROM WEB_CATEG_ARRAY WHERE WCA_IS_ACTIVE=1);

	UPDATE WEB_CATEG_ARRAY SET WCA_IS_ACTIVE=1 WHERE web_categ_array_id IN (SELECT DISTINCT web_categ_Array_id_parent2 FROM WEB_CATEG_ARRAY WHERE WCA_IS_ACTIVE=1);

	UPDATE WEB_CATEG_ARRAY SET WCA_IS_ACTIVE=1 WHERE web_categ_array_id IN (SELECT DISTINCT web_categ_Array_id_parent3 FROM WEB_CATEG_ARRAY WHERE WCA_IS_ACTIVE=1);

	UPDATE WEB_CATEG_ARRAY SET WCA_IS_ACTIVE=1 WHERE web_categ_array_id IN (SELECT DISTINCT web_categ_Array_id_parent4 FROM WEB_CATEG_ARRAY WHERE WCA_IS_ACTIVE=1);

END ActivateAllWebCategArray;

/** **************************************************************************************
* FUNCTION GenerateDocument
* declare
  reserr number(2);
  ADOCIDLIST varchar2(2000);
  AERRORCODE varchar2(2000);
begin
  ADOCIDLIST := null;
  AERRORCODE :=null;
  PCS.PC_I_LIB_SESSION.INITSESSION('DEVELOP', 'ECONCEPT', null, 'DEFAULT');
commit;
 DEVELOP.DOC_DOCUMENT_GENERATOR.GENERATEDOCUMENT (763,0,AERRORCODE,0,1,ADOCIDLIST);
dbms_output.put_line('AERRORCODE '||AERRORCODE);
dbms_output.put_line('ADOCIDLIST '||ADOCIDLIST);
end;
*
******************************************************************************************/
FUNCTION GenerateDocument(
  pDocInterfaceId IN DOC_INTERFACE.DOC_INTERFACE_ID%TYPE
, pDmtNumber      IN DOC_INTERFACE.DOI_NUMBER%TYPE
)
  RETURN VARCHAR2
IS
  vDmtNumber DOC_DOCUMENT.DMT_NUMBER%TYPE;
  ErrMsg     VARCHAR2(4000);
  ListDocID  VARCHAR2(4000);
  ACONFIRM number(1);
  ACOMMIT  number(1);
  ADEBUG number(1);
  AERRORCODE varchar2(2000);
BEGIN

  commit;

  ACONFIRM :=0;
  ACOMMIT :=0;
  ADEBUG :=0;
  /*
  Doc_Document_Generate.ResetDocumentInfo(Doc_Document_Initialize.DocumentInfo);
  Doc_Document_Initialize.DocumentInfo.CLEAR_DOCUMENT_INFO := 0;
  Doc_Document_Initialize.DocumentInfo.DMT_NUMBER  := pDmtNumber;
  Doc_Document_Generator.GenerateDocument(aInterfaceId          => pDocInterfaceId
                                        , aErrorMsg             => ErrMsg
                                        , aNewDocumentsIdList   => ListDocID
                                         );
  */

  DOC_DOCUMENT_GENERATOR.GENERATEDOCUMENT (pDocInterfaceId,ACONFIRM,AERRORCODE,ADEBUG,ACOMMIT,ListDocID);

  DOC_FINALIZE.FINALIZEDOCUMENT(ListDocID,1,null,0);

  SELECT DMT_NUMBER
    INTO vDmtNumber
    FROM DOC_DOCUMENT
   WHERE INSTR(',' || ListDocID || ',', ',' || TO_CHAR(DOC_DOCUMENT_ID) || ',') > 0
     AND ROWNUM = 1;

  RETURN vDmtNumber;
END GenerateDocument;


/** **************************************************************************************
* FUNCTION getGcoGoodWebCategArrayIdMain
*
*
******************************************************************************************/

FUNCTION getGcoGoodWebCategArrayIdMain(pGcoGoodId          IN GCO_GOOD.GCO_GOOD_ID%TYPE,
                                       pWebUserId          IN WEB_USER.WEB_USER_ID%TYPE) RETURN NUMBER IS

  mainWebCategArrayId WEB_GOOD.WEB_CATEG_ARRAY_ID%TYPE;
BEGIN

  SELECT web_categ_Array_id INTO mainWebCategArrayId
  FROM WEB_GOOD
  WHERE gco_good_id=pGcoGoodId AND
        --web_shop_functions.getWebCategArrayRight4WebUser(web_categ_array_id,pWebUserId)=1 and
		wgo_is_active=1 AND
		ROWNUM=1;

  RETURN mainWebCategArrayId;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    BEGIN
	  RETURN 0;
	END;

END getGcoGoodWebCategArrayIdMain;

  /** **************************************************************************************
  * FUNCTION loadImgInBlob4Print
  *
  *
  ******************************************************************************************/

PROCEDURE loadImgInBlob4Print(pGooMajorReference GCO_GOOD.GOO_MAJOR_REFERENCE%TYPE, keyPrecision WEB_BITMAP.WEB_BITMAP_ID%TYPE) IS
		/**
		*

		drop table WEB_BITMAP;


		CREATE TABLE WEB_BITMAP
		( WEB_BITMAP_ID  VARCHAR2(250) NOT NULL, REC_ID NUMBER(12), BIT_IMAGE BLOB   NOT NULL, A_DATECRE DATE  NOT NULL) TABLESPACE CPY
		PCTUSED    0 PCTFREE    10 INITRANS   1 MAXTRANS   255 STORAGE    (
		 INITIAL          9400K    MINEXTENTS       1       MAXEXTENTS       2147483645 PCTINCREASE      0    BUFFER_POOL      DEFAULT ) LOGGING NOCACHE NOPARALLEL;



		CREATE UNIQUE INDEX PK_WEB_BITMAP ON WEB_BITMAP (WEB_BITMAP_ID)
		LOGGING TABLESPACE CPY PCTFREE    10 INITRANS   2 MAXTRANS   255 STORAGE    (
		            INITIAL          16K             MINEXTENTS       1        MAXEXTENTS       2147483645            PCTINCREASE      0
		            BUFFER_POOL      DEFAULT  ) NOPARALLEL;


		ALTER TABLE WEB_BITMAP ADD (
		  CONSTRAINT PK_WEB_BITMAP PRIMARY KEY (WEB_BITMAP_ID)
		    USING INDEX  TABLESPACE CPY  PCTFREE    10  INITRANS   2   MAXTRANS   255   STORAGE    (
		                INITIAL          16K      MINEXTENTS       1      MAXEXTENTS       2147483645     PCTINCREASE      0    ));


		*

		**/
	newClob  BLOB;
	src_file BFILE;
	lgh_file BINARY_INTEGER;
	fname VARCHAR2(255);
	keyId WEB_BITMAP.WEB_BITMAP_ID%TYPE;
	pGcoGoodId GCO_GOOD.GCO_GOOD_ID%TYPE;
BEGIN

	  SELECT gco_good_id INTO pGcoGoodId FROM GCO_GOOD WHERE goo_major_reference = pGooMajorReference;

	IF (keyPrecision='UrlSmall') THEN
	  BEGIN
	    fname := getLinkedImageName(pGcoGoodId,'UrlSmall');
		keyId:='GCOSMALL'||TO_CHAR(pGcoGoodId);
	  END;

	ELSIF (keyPrecision='UrlLarge') THEN
	  BEGIN
	    fname := getLinkedImageName(pGcoGoodId,'UrlLarge');
		keyId:='GCOLARGE'||TO_CHAR(pGcoGoodId);
	  END;
	END IF;

	DELETE WEB_BITMAP WHERE WEB_BITMAP_ID=keyId;

	INSERT INTO WEB_BITMAP (  WEB_BITMAP_ID, REC_ID, BIT_IMAGE, A_DATECRE) VALUES (keyId,pGcoGoodId,EMPTY_BLOB(),SYSDATE)  RETURNING BIT_IMAGE INTO newClob;

	SELECT BIT_IMAGE INTO newClob  FROM WEB_BITMAP WHERE WEB_BITMAP_ID=keyId FOR UPDATE;
	src_file := BFILENAME('SHOPCONCEPTIMAGES', fname);
	dbms_lob.fileopen(src_file, dbms_lob.file_readonly);
	lgh_file := dbms_lob.getlength(src_file);
	dbms_lob.loadfromfile (newClob, src_file, lgh_file);

	UPDATE WEB_BITMAP SET BIT_IMAGE = newClob WHERE WEB_BITMAP_ID=keyId;

	dbms_lob.fileclose(src_file);

	COMMIT;

	EXCEPTION WHEN OTHERS THEN
	  BEGIN
	    NULL;
	  END;

END loadImgInBlob4Print;

  /** **************************************************************************************
  * FUNCTION getGcoGoodPrice
  *
  *
  ******************************************************************************************/

  FUNCTION getGcoGoodPrice(pGcoGoodId              IN GCO_GOOD.GCO_GOOD_ID%TYPE,
                           pPacCustomPartnerId     IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%TYPE,
						   pAcsFinancialCurrencyId IN ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%TYPE,
						   pQuantity               IN DOC_INTERFACE_POSITION.DOP_QTY%TYPE,
						   pPriceType              IN VARCHAR2 ) RETURN NUMBER IS
    searchPrice NUMBER(16,5);
  BEGIN
    searchPrice:=0;
    IF (pPriceType='stdPrice') THEN
	  BEGIN
	  	 SELECT
		    Ptc_Find_Tariff.GetFullPrice(pGcoGoodId,pQuantity,pPacCustomPartnerId,NULL,NULL,pAcsFinancialCurrencyId,'A_FACTURER','1',DIC_TARIFF_ID,SYSDATE,1,NULL,NULL,1,1)
			INTO searchPrice FROM PAC_CUSTOM_PARTNER
	   WHERE PAC_CUSTOM_PARTNER_ID=pPacCustomPartnerId;

	   EXCEPTION WHEN OTHERS THEN
	     searchPrice:=0;
	  END;
	ELSE
	IF (pPriceType='actionPrice') THEN
	  BEGIN
	  SELECT Ptc_Find_Tariff.GETTARIFFPRICE( Ptc_Find_Tariff.GetTariffDirect(pGcoGoodId,pPacCustomPartnerId,NULL, pAcsFinancialCurrencyId,DIC_TARIFF_ID, pQuantity, SYSDATE, 'A_FACTURER','1'),1)
	  INTO searchPrice FROM PAC_CUSTOM_PARTNER
	   WHERE PAC_CUSTOM_PARTNER_ID=pPacCustomPartnerId;

 	   EXCEPTION WHEN OTHERS THEN
	     searchPrice:=0;

	  END;
	ELSE
	IF (pPriceType='orderPrice') THEN
	  BEGIN

	  SELECT
	    Ptc_Find_Tariff.GetFullPrice(pGcoGoodId,pQuantity,pPacCustomPartnerId,NULL,NULL,pAcsFinancialCurrencyId,'A_FACTURER','1',DIC_TARIFF_ID,SYSDATE,1,NULL,NULL,1,1)
	  	  INTO searchPrice
	  FROM
	    PAC_CUSTOM_PARTNER
	  WHERE
	    PAC_CUSTOM_PARTNER_ID=pPacCustomPartnerId;

	   	   EXCEPTION WHEN OTHERS THEN
	     searchPrice:=0;

	  END;
	  END IF;
	 END IF;
	END IF;

	RETURN searchPrice;
  END;

  /** **************************************************************************************
  * FUNCTION getGcoGoodFreeMemo
  *
  *
  ******************************************************************************************/

  FUNCTION getGcoGoodFreeMemo(pGcoGoodId IN GCO_GOOD.GCO_GOOD_ID%TYPE,
							  pDicMemoCode IN GCO_FREE_CODE.DIC_GCO_MEMO_CODE_TYPE_ID%TYPE) RETURN GCO_FREE_CODE.FCO_MEM_CODE%TYPE IS
    vRet GCO_FREE_CODE.FCO_MEM_CODE%TYPE;
  BEGIN
    SELECT fco_mem_code INTO vRet FROM GCO_FREE_CODE WHERE gco_good_id=pGcoGoodId AND dic_gco_memo_code_type_id=pDicMemoCode;
	  RETURN vRet;
	EXCEPTION WHEN OTHERS THEN
	  RETURN NULL;
  END;


  /** **************************************************************************************
  * FUNCTION getLinkedFileName
  *
  *
  ******************************************************************************************/

  FUNCTION getLinkedFileName(pGcoGoodId GCO_GOOD.GCO_GOOD_ID%TYPE,
                       pClfKey01 COM_IMAGE_FILES.IMF_KEY01%TYPE) RETURN VARCHAR2 IS

  filename COM_IMAGE_FILES.IMF_FILE%TYPE;

  CURSOR getImg(ID GCO_GOOD.GCO_GOOD_ID%TYPE,
                key01 COM_IMAGE_FILES.IMF_KEY01%TYPE) IS

		SELECT
		  IMF_FILE
		FROM
		  COM_IMAGE_FILES A
		WHERE
		  A.IMF_KEY01=key01 AND
		  A.IMF_TABLE='GCO_GOOD' AND
		  IMF_REC_ID=ID
		ORDER BY
		  IMF_SEQUENCE DESC;

  BEGIN
    OPEN getImg(pGcoGoodId,pClfKey01);
	FETCH getImg INTO filename;
	IF (getImg%NOTFOUND) THEN
	  filename:=NULL;
	END IF;
	CLOSE getImg;
	RETURN filename;
  END getLinkedFileName;


  /** **************************************************************************************
  * FUNCTION setWebGoodSearchDatas
  *
  *
  ******************************************************************************************/

  PROCEDURE setWebGoodSearchDatas(pGcoGoodId GCO_GOOD.GCO_GOOD_ID%TYPE) IS

	vSearchDatas VARCHAR2(4000);
	vSearchDatasRef VARCHAR2(60);
	vSearchData1 VARCHAR2(3500);
	vSearchDescr VARCHAR2(3500);
	vSearchDataCateg VARCHAR2(100);
	vSearchDataCategs VARCHAR2(440);
	vIsNews WEB_GOOD_SEARCH.WGS_IS_NEW%TYPE;
	vIsAction WEB_GOOD_SEARCH.WGS_IS_ACTION%TYPE;
	vExists NUMBER(1);

  --récupère les descriptions
  CURSOR getDescriptions(pGcoGoodId GCO_GOOD.gco_good_id%TYPE) IS
    SELECT des_short_description||' '||des_long_description||' '||des_free_description datas FROM GCO_DESCRIPTION WHERE gco_good_id=pGcoGoodId;


 --récupère les catégories
  CURSOR getCategs(pGcoGoodId GCO_GOOD.gco_good_id%TYPE) IS
   SELECT
     Web_Shop_Functions_Std.GETWEBCATEGARRAYINFO(c.web_categ_array_id,pc_lang_id,'WCD_DESCR') datas
   FROM
	 pcs.pc_lang,
	 WEB_GOOD g,
	 WEB_CATEG_ARRAY c
   WHERE
     lanused=1 AND
     g.web_categ_array_id=c.web_categ_array_id AND gco_good_Id=pGcoGoodId;

	getDescription getDescriptions%ROWTYPE;
	getCateg getCategs%ROWTYPE;

  BEGIN
  SELECT goo_major_reference||' '||GOO_SECONDARY_REFERENCE INTO vSearchDatasRef FROM GCO_GOOD WHERE gco_good_id=pGcoGoodId;

  vSearchDescr :='';
  --load descriptions
  OPEN getDescriptions(pGcoGoodId);
  FETCH getDescriptions INTO getDescription;
  WHILE getDescriptions%FOUND LOOP
      vSearchDescr := SUBSTR(vSearchDescr||' '||getDescription.datas,1,3500); --limits the descriptions concatenation at 3500 characters
      FETCH getDescriptions INTO getDescription;
  END LOOP;

  CLOSE getDescriptions;

  --load web categorie
  vSearchDataCategs :='';

    OPEN getCategs(pGcoGoodId);
	FETCH getCategs INTO getCateg;
    WHILE getCategs%FOUND LOOP
      vSearchDataCategs := SUBSTR(vSearchDataCategs||' '||getCateg.datas,1,440); --limits the descriptions concatenation at 3500 characters
      FETCH getCategs INTO getCateg;
    END LOOP;
	CLOSE getCategs;


  SELECT SIGN(COUNT(*)) INTO vIsAction FROM PTC_TARIFF a WHERE gco_good_id=pGcoGoodId AND a.C_TARIFF_TYPE='A_FACTURER' AND trf_special_tariff=1 AND
  (    (TRF_STARTING_DATE IS NULL)  OR (    TRF_STARTING_DATE < SYSDATE AND (TRF_ENDING_DATE > SYSDATE OR TRF_ENDING_DATE IS NULL) ) );

  SELECT COUNT(*) INTO vIsNews FROM GCO_GOOD a WHERE gco_good_id=pGcoGoodId AND
	( (goo_innovation_from < SYSDATE) AND ((goo_innovation_to>SYSDATE) OR (goo_innovation_to IS NULL)) OR
	( (goo_innovation_to<SYSDATE) AND ( goo_innovation_from>SYSDATE OR goo_innovation_from IS NULL ) ));


  vSearchDatas := SUBSTR(vSearchDatasRef||' '||vSearchDescr||' '||vSearchDataCategs,1,4000);

  SELECT COUNT(*) INTO vExists FROM WEB_GOOD_SEARCH WHERE gco_good_id=pGcoGoodId;

  IF (vExists=0) THEN
    BEGIN
    INSERT INTO WEB_GOOD_SEARCH VALUES (pGcoGoodId,vSearchDatas,vIsAction,vIsNews);
	END;
  ELSE
    BEGIN
     UPDATE WEB_GOOD_SEARCH SET (/*WGS_search_datas,*/ wgs_is_action, wgs_is_new) = (SELECT /*vSearchDatas,*/vIsAction,vIsNews FROM dual) WHERE gco_good_id=pGcoGoodId;
	END;
  END IF;


  EXCEPTION WHEN NO_DATA_FOUND THEN
    BEGIN
	  RETURN;
	END;

  END;



  /** **************************************************************************************
  * FUNCTION setWebGoodSearchDatas
  *
  *
  ******************************************************************************************/
  PROCEDURE setAllWebGoodSearchDatas IS

  CURSOR goods IS
    SELECT gco_good_id FROM WEB_GOOD;

    good goods%ROWTYPE;
  BEGIN


    OPEN goods();
	FETCH goods INTO good;
    WHILE goods%FOUND LOOP
	  --DELETE WEB_GOOD_SEARCH WHERE gco_good_id=	good.gco_good_id; update in SETWEBGOODSEARCHDATAS(good.gco_good_id) procedure
      Web_Shop_Functions_Std.SETWEBGOODSEARCHDATAS(good.gco_good_id);
	  COMMIT;
	  FETCH goods INTO good;
    END LOOP;
	CLOSE goods;

  END setAllWebGoodSearchDatas;


  /** SetgeneratedorderValidate
   * plsqlParamPrefix1 contient le numéro du document
   */
  FUNCTION SetGeneratedOrderValidate(plsqlParamPrefix1 in DOC_DOCUMENT.DMT_NUMBER%type,
                                     pWebUserId        in  WEB_USER.WEB_USER_ID%type,
                                     pMsg              out varchar2) RETURN NUMBER IS
    aErrorCode  varchar2(5);
    aErrorText  varchar2(4000);
      vDocDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
      vDoiNumber DOC_INTERFACE.DOI_NUMBER%type;
      vPcLangId pcs.pc_lang.pc_lang_id%type;
    BEGIN

    select
      pc_lang_id into vPcLangId
    from
      web_user
    where
      web_user_id=pWebUserId;

    select
      doc_document_id, dmt_doi_number into vDocDocumentId,vDoiNumber
    from
      doc_document
    where
      dmt_number=plsqlParamPrefix1;

      doc_document_functions.ConfirmDocument(
            vDocDocumentId
          , aErrorCode
          , aErrorText
          , 1);

      select  pcs.pc_functions.TRANSLATEWORD('Votre commande est validée.',vPcLangId) into pMsg from dual;
      commit;

      RETURN WEB_FUNCTIONS.RETURN_OK;
  END SetgeneratedorderValidate;


  /** SetGeneratedOrderUpdatable
   * plsqlParamPrefix1 contient le numéro du document
   *repasser en 000 et 01
   *
   *
   */
  FUNCTION SetGeneratedOrderUpdatable(plsqlParamPrefix1 in DOC_DOCUMENT.DMT_NUMBER%type,
                                      pWebUserId        in  WEB_USER.WEB_USER_ID%type,
                                      pMsg              out varchar2) RETURN NUMBER IS
      vDocDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
      vDoiNumber DOC_INTERFACE.DOI_NUMBER%type;
      vDocInterfaceId doc_interface.doc_interface_id%type;
      vPcLangId pcs.pc_lang.pc_lang_id%type;
    BEGIN

    select
      pc_lang_id into vPcLangId
    from
      web_user
    where web_user_id=pWebUserId;

    select doc_document_id, dmt_doi_number into vDocDocumentId,vDoiNumber
    from
      doc_document
    where
      dmt_number=plsqlParamPrefix1;

    select i.doc_interface_id into vDocInterfaceId
    from
      doc_document d,
      doc_interface i
    where
      dmt_doi_number=doi_number and
      d.doc_document_id=vDocDocumentId;

     DOC_DELETE.DELETEDOCUMENT(vDocDocumentId,0,pMsg);

    update doc_interface
      set c_doi_interface_status='01'
    where
      doc_interface_id=vDocInterfaceId;

    update doc_interface
      set c_doc_interface_origin='000'
    where
      doc_interface_id=vDocInterfaceId;

    update doc_interface_position
      set c_dop_interface_status='02'
    where
      doc_interface_id=vDocInterfaceId;

    commit;

    select  pcs.pc_functions.TRANSLATEWORD('Vous pouvez modifier votre commande.',vPcLangId) into pMsg from dual;

    RETURN WEB_FUNCTIONS.RETURN_OK;
  END SetGeneratedOrderUpdatable;


  /** SetgeneratedorderCancel
   * plsqlParamPrefix1 contient le numéro du document
   */
  FUNCTION SetgeneratedorderCancel(  plsqlParamPrefix1 in DOC_DOCUMENT.DMT_NUMBER%type,
                                     pWebUserId        in  WEB_USER.WEB_USER_ID%type,
                                     pMsg              out varchar2) RETURN NUMBER is
      vDocDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
      vDoiNumber DOC_INTERFACE.DOI_NUMBER%type;
      vPcLangId pcs.pc_lang.pc_lang_id%type;
    BEGIN

    select pc_lang_id into vPcLangId from web_user where web_user_id=pWebUserId;

    select doc_document_id, dmt_doi_number into vDocDocumentId,vDoiNumber
    from
      doc_document
    where
      dmt_number=plsqlParamPrefix1;

    delete DOC_INTERFACE where doi_number=vDoiNumber;

    delete doc_position where doc_document_id=vDocDocumentId;
    delete doc_document where doc_document_id=vDocDocumentId;

    commit;

    select  pcs.pc_functions.TRANSLATEWORD('Votre commande à bien été annulée.',vPcLangId) into pMsg from dual;
    RETURN WEB_FUNCTIONS.RETURN_OK;
  END SetgeneratedorderCancel;

  ------------------------------------------------------------------------------------END
FUNCTION GetOrderStateId(pDoc_Interface_id NUMBER) RETURN varchar2 IS
  --------------------------------------------------------------------------------------
  --
  -- Function GetOrderStateId
  --
  --
  -- Author  : Rafael Rimbert
  -- Company : Pro-Concept SA
  --
  -- Purpose : Retourne l'Id de l'état d'une commande
  --
  --  Utilisé dans la vue V_OPS_ORDER_TABLE
  --  renvoie d'id
  --  l'état correspondant à afficher rendu par la fonction suivante
  --
  --   pOrder_State_ID='00' => 'Commande non trouvée';
  --                    '01'=> Dans l'OE mais pas de document généré
  --                           'Commande en cours de confirmation'
  --                    '40'=> Document généré mais pas de BL
  --					       'Commande en préparation';
  --                    '50'=> Il existe des Bulletins de livraison mais pas tous
  --						   'Partiellement livrée';
  --				    '80'=> Toutes les positions ont des BL soldés
  --					       'Commande soldée'
  --------------------------------------------------------------------------------------
    vState               VARCHAR2(60);
    vDoi_number          DOC_INTERFACE.DOI_NUMBER%TYPE;
    vDoc_interface_state DOC_INTERFACE.C_DOI_INTERFACE_STATUS%TYPE ;
    vParent_Doc_document_id DOC_DOCUMENT.DOC_DOCUMENT_ID%TYPE; --premier document généré depuis l'orderEntry
    vCount NUMBER;
	vc_doi_interface_status DOC_INTERFACE.C_DOI_INTERFACE_STATUS%TYPE;
    CURSOR c2 IS
	SELECT doc_document_id
	FROM DOC_DOCUMENT
	WHERE dmt_doi_number=vDoi_number;
	cursor cOrderState is
	SELECT
	  CC_STATUS,
	  BL_STATUS,
	  FC_STATUS
    FROM
      (
      SELECT
  doi_number,
  b.dmt_number CC_NUMBER,
  c.C_DOC_POS_STATUS CC_STATUS,
  BL_NUMBER,
  BL_STATUS,
  FC_NUMBER,
  FC_STATUS,
  POS_NUMBER,
  POS_SHORT_DESCRIPTION,
  POS_BASIS_QUANTITY,
  POS_REFERENCE,
  POS_DISCOUNT_AMOUNT,
  POS_VAT_BASE_AMOUNT,
  POS_GROSS_UNIT_VALUE,
  POS_NET_UNIT_VALUE,
  DIC_UNIT_OF_MEASURE_ID
FROM
 DOC_INTERFACE CC_DOC,
 DOC_DOCUMENT B,
 DOC_POSITION C,
 DOC_POSITION_DETAIL D,
 (SELECT
  BL_DOC.dmt_number BL_NUMBER,
  BL_POS.C_DOC_POS_STATUS BL_STATUS,
  BL_POS_DET.doc_position_detail_id BL_ID,
  BL_POS_DET.doc_doc_position_detail_id CC_ID
 FROM
  DOC_DOCUMENT BL_DOC,
  DOC_POSITION BL_POS,
  DOC_POSITION_DETAIL BL_POS_DET
 WHERE
  DIC_GAUGE_TYPE_DOC_ID='V-BL' and
  BL_POS_DET.doc_position_id=BL_POS.doc_position_id and
  BL_POS.doc_document_id=BL_DOC.doc_document_id) BL,
 (SELECT
  FC_DOC.dmt_number FC_NUMBER,
  FC_POS.C_DOC_POS_STATUS FC_STATUS,
  FC_POS_DET.doc_position_detail_id FC_ID,
  FC_POS_DET.doc_doc_position_detail_id BL_ID
FROM
  DOC_DOCUMENT FC_DOC,
  DOC_POSITION FC_POS,
  DOC_POSITION_DETAIL FC_POS_DET
WHERE
  DIC_GAUGE_TYPE_DOC_ID='V-FC' and
  FC_POS_DET.doc_position_id=FC_POS.doc_position_id and
  FC_POS.doc_document_id=FC_DOC.doc_document_id) FC
WHERE
  CC_DOC.DOI_NUMBER=B.DMT_DOI_NUMBER(+) and
  BL.CC_ID(+)=d.doc_position_detail_id and
  FC.BL_ID(+)=BL.BL_ID and
  D.doc_position_id=c.doc_position_id and
  C.doc_document_id=b.doc_document_id and
  DIC_GAUGE_TYPE_DOC_ID='V-CC'
      )
	WHERE
	 DOI_NUMBER in (select doi_number from doc_interface where doc_interface_id=pDoc_Interface_id);
    TYPE rOrderStateType IS RECORD (
	  CC_STATUS DOC_POSITION.C_DOC_POS_STATUS%TYPE,
	  BL_STATUS DOC_POSITION.C_DOC_POS_STATUS%TYPE,
	  FC_STATUS DOC_POSITION.C_DOC_POS_STATUS%TYPE);
  rOrderState rOrderStateType;
  cc01 number;   cc02 number;  cc03 number;  cc04 number;
  bl01 number;   bl02 number;  bl03 number;  bl04 number;
  fc01 number;   fc02 number;  fc03 number;  fc04 number;
  BEGIN
  vState:='-1'; --Etat inconnu
    --------------------ETAT = 0 : Document non trouvé dans DOC_INTERFACE -----------------
    --On recherche si doc_interface_id existe dans la table doc_interface
    --on renverra vState=0 si pas trouvé
    --On fait le test pour éviter un no data found
  SELECT COUNT(*) INTO vCount FROM DOC_INTERFACE WHERE DOC_INTERFACE_ID=pDoc_Interface_id;
  IF vCount=0 THEN
    begin
	  vState:='00'; --Commande pas trouvée et on arrête là
	end;
  END IF;
  IF vState='-1' THEN --statut pas encore déterminé mais La commande est trouvée
    BEGIN
      --On récupère l'id du premier document généré
      SELECT c_doi_interface_status into vC_Doi_interface_status FROM DOC_INTERFACE
      WHERE  DOC_INTERFACE_ID=pDoc_Interface_id;
	  if vc_doi_interface_status='01' then
	    begin
		vState :='01';
		end;
	  end if;
	  if vc_doi_interface_status='02' then
	    begin
		vState :='02';
		end;
	  end if;
	  if vc_doi_interface_status='04' then --documents générés
	    begin
		-- Initialisation des compteurs
		-- cc01 correspond au nombre de CC de statut 01
		-- ...
        cc01 :=0;   cc02 :=0;  cc03 :=0;  cc04 :=0;
        bl01 :=0;   bl02 :=0;  bl03 :=0;  bl04 :=0;
        fc01 :=0;   fc02 :=0;  fc03 :=0;  fc04 :=0;
           open cOrderState;
		   loop --boucle de comptage
		     FETCH cOrderState INTO rOrderState;
			 EXIT WHEN cOrderState%NOTFOUND;
		       if rOrderState.CC_STATUS='01' then cc01 := cc01 +1; end if;
			   if rOrderState.CC_STATUS='02' then cc02 := cc02 +1; end if;
			   if rOrderState.CC_STATUS='03' then cc03 := cc03 +1; end if;
			   if rOrderState.CC_STATUS='04' then cc04 := cc04 +1; end if;
		       if rOrderState.BL_STATUS='01' then bl01 := bl01 +1; end if;
			   if rOrderState.BL_STATUS='02' then bl02 := bl02 +1; end if;
			   if rOrderState.BL_STATUS='03' then bl03 := bl03 +1; end if;
			   if rOrderState.BL_STATUS='04' then bl04 := bl04 +1; end if;
		       if rOrderState.FC_STATUS='01' then fc01 := fc01 +1; end if;
			   if rOrderState.FC_STATUS='02' then fc02 := fc02 +1; end if;
			   if rOrderState.FC_STATUS='03' then fc03 := fc03 +1; end if;
			   if rOrderState.FC_STATUS='04' then fc04 := fc04 +1; end if;
           end loop;
		   --Analyse des compteurs
           --  if pOrder_State_ID='40' then --BL non déchargé => 'Commande en préparation',
           --  if pOrder_State_ID='50' then --BL partiel  => 'Partiellement livrée',
           --  if pOrder_State_ID='80' then --Toutes les positions ont des BL soldés
           if bl03+bl04 =0 then --pas de BL déchargé
		     vState:='40';
		   end if;
		   if (bl03+bl02>0 or (bl04>0 and cc03>0)) then --des positions de bl sont partielles
		     vState:='50';
		   end if;
		   if (bl04=cc04 and cc01+cc02+cc03=0) then -- toutes les cc sont déchargées par des bl
		     vState:='80';
		   end if;
		end;
	  end if; --'04'
	end;
  END IF;
    return vState;
end;
FUNCTION GetOrderState(pOrder_State_ID varchar2, pPc_Lang_Id NUMBER) RETURN VARCHAR2 IS
  --------------------------------------------------------------------------------------
  --
  -- Function GetOrderStateId
  --
  --
  -- Author  : Rafael Rimbert
  -- Company : Pro-Concept SA
  --
  -- Purpose : Retourne la description de l'état d'une commande
  --           traduit dans la langue passée en paramètre
  --
  -- Test : ok 25.01.2001
  --------------------------------------------------------------------------------------
  vStateDescr          VARCHAR2(50);
  /*cursor c1 is
    SELECT
      description
    FROM
      OPS_order_state_description
    WHERE
      country_code_id=pPc_Lang_ID
      AND order_state_id =pOrder_State_ID;*/
Begin
  --On recherche la traduction correspondante
  vStateDescr:=' ? ';
  --open c1;  fetch c1 into vStateDescr;  close c1;

  if pOrder_State_ID='00' then
        select decode(pPc_Lang_Id,1,'Commande non trouvée',
		                          2,'Order not found',
								  3,'Allemand :Commande non trouvée') into vStateDescr from dual;
  end if;
  if pOrder_State_ID='01' then --Dans l'OE mais pas de document généré
        select decode(pPc_Lang_Id,1,'Commande soumise',
		                          2,'Submited',
								  3,'Allemand :Commande soumise') into vStateDescr from dual;
  end if;
  --Des documents ont été générés (doc_interface_status=(04))
  if pOrder_State_ID='02' then --Dans l'OE mais pas de document généré mais interface confirmée (02)
        select decode(pPc_Lang_Id,1,'Commande confirmée',
		                          2,'Confirmed',
								  3,'Commande confirmée') into vStateDescr from dual;
  end if;
  if pOrder_State_ID='40' then --BL non déchargé
        select decode(pPc_Lang_Id,1,'En préparation',
		                          2,'En préparation',
								  3,'En préparation') into vStateDescr from dual;
  end if;
  if pOrder_State_ID='50' then --BL partiel
        select decode(pPc_Lang_Id,1,'Partiellement livrée',
		                          2,'Partiellement livrée',
								  3,'Partiellement livrée') into vStateDescr from dual;
  end if;
  if pOrder_State_ID='80' then --Toutes les positions ont des BL soldés
        select decode(pPc_Lang_Id,1,'soldée',
		                          2,'soldée',
								  3,'soldée') into vStateDescr from dual;
  end if;

  RETURN vStateDescr;
END;


END;
