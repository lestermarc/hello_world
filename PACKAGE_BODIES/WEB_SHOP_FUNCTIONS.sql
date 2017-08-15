--------------------------------------------------------
--  DDL for Package Body WEB_SHOP_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_SHOP_FUNCTIONS" AS

FUNCTION getAvailableQuantityWeb(pGcoGoodId           IN GCO_GOOD.GCO_GOOD_ID%TYPE,
                                 pPacCustomePartnerId IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%TYPE) RETURN NUMBER
IS
BEGIN
  RETURN Web_Shop_Functions_Std.getAvailableQuantityWeb(pGcoGoodId,pPacCustomePartnerId);
	--RETURN web_shop_functions_cust.getAvailableQuantityWeb(pGcoGoodId,pPacCustomePartnerId);
END getAvailableQuantityWeb;


FUNCTION getLinkedImageName( pGcoGoodId GCO_GOOD.GCO_GOOD_ID%TYPE,
		 					 pClfKey01 COM_IMAGE_FILES.IMF_KEY01%TYPE) RETURN VARCHAR2 IS
BEGIN
  RETURN Web_Shop_Functions_Std.getLinkedImageName(pGcoGoodId,pClfKey01);
  --RETURN web_shop_functions_cust.getLinkedImageName(pGcoGoodId,pClfKey01);
END getLinkedImageName;



FUNCTION getPurchaseOrderMultiColInfo( pGcoGoodId              IN GCO_GOOD.GCO_GOOD_ID%TYPE,
                                       pPacCustomPartnerId     IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%TYPE,
								       pAcsFinancialCurrencyId IN ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%TYPE,
									   pPcLangId               IN PCS.PC_LANG.PC_LANG_ID%TYPE,
									   pColumnIndex            IN NUMBER) RETURN VARCHAR2 IS
BEGIN
  RETURN Web_Shop_Functions_Std.getPurchaseOrderMultiColInfo(pGcoGoodId,pPacCustomPartnerId,pAcsFinancialCurrencyId,pPcLangId,pColumnIndex);
  --RETURN web_shop_functions_cust.getPurchaseOrderMultiColInfo(pGcoGoodId,pPacCustomPartnerId,pAcsFinancialCurrencyId,pPcLangId,pColumnIndex);
END;

FUNCTION getWebCategArrayRight4WebUser(pWebCategArrayId        IN WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%TYPE,
									   pWebUserId              IN WEB_USER.WEB_USER_ID%TYPE) RETURN NUMBER IS
BEGIN
  RETURN Web_Shop_Functions_Std.getWebCategArrayRight4WebUser(pWebCategArrayId,pWebUserId);
  --RETURN web_shop_functions_cust.getWebCategArrayRight4WebUser(pWebCategArrayId,pWebUserId);
END;


PROCEDURE SetRightForUserToCatalog(pWebUserId IN WEB_USER.WEB_USER_ID%TYPE,
                             pWebCategArrayId IN WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%TYPE,
						               pRight IN WEB_CATEG_ARRAY_RIGHT.WCA_RIGHT%TYPE) IS
BEGIN
  Web_Shop_Functions_Std.SetRightForUserToCatalog(pWebUserId,pWebCategArrayId,pRight);
  --  RETURN web_shop_functions_cust.SetRightForUserToCatalog(pWebUserId,pWebCategArrayId,pRight);
END;


FUNCTION getLinkedFileName(pGcoGoodId GCO_GOOD.GCO_GOOD_ID%TYPE,
                     pClfKey01 COM_IMAGE_FILES.IMF_KEY01%TYPE) RETURN VARCHAR2 IS
BEGIN
  RETURN Web_Shop_Functions_Std.getLinkedFileName(pGcoGoodId,pClfKey01);
  --RETURN web_shop_functions_cust.getLinkedImageName(pGcoGoodId,pClfKey01);
END getLinkedFileName;


END;
