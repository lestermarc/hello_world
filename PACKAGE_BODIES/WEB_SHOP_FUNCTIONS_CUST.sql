--------------------------------------------------------
--  DDL for Package Body WEB_SHOP_FUNCTIONS_CUST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_SHOP_FUNCTIONS_CUST" as
    /**
	*  Individualisable par le client
	*  Ne pas oublier de modifier le wrapping dans le package WEB_SHOP_FUNCTIONS vers le package WEB_SHOP_FUNCTIONS_CUST
	**/

FUNCTION getAvailableQuantityWeb(pGcoGoodId             IN GCO_GOOD.GCO_GOOD_ID%type,
                                 pPacCustomPartnerId    IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type) return number
IS
BEGIN
	RETURN 0;
END getAvailableQuantityWeb;


FUNCTION getLinkedImageName(  pGcoGoodId GCO_GOOD.GCO_GOOD_ID%type,
                        pClfKey01 COM_IMAGE_FILES.IMF_KEY01%type) return varchar2
IS
BEGIN
  return 'custom function not defined';
END getLinkedImageName;

FUNCTION getPurchaseOrderMultiColInfo( pGcoGoodId              IN GCO_GOOD.GCO_GOOD_ID%type,
                                       pPacCustomPartnerId     IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type,
								       pAcsFinancialCurrencyId IN ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
									   pPcLangId               IN PCS.PC_LANG.PC_LANG_ID%type,
									   pColumnIndex            IN number) return varchar2 is
BEGIN
  return 'custom function not defined';
END;

end;
