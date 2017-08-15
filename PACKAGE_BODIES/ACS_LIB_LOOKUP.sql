--------------------------------------------------------
--  DDL for Package Body ACS_LIB_LOOKUP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_LIB_LOOKUP" 
/**
* Package utilitaire de recherche de d'identifiant unique d'entité.
*
* @version 1.0
* @date 2011
* @author spfister
* @author skalayci
*
* Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
*/
AS

function getFINANCIAL_CURRENCY(
  iv_CURRENCY IN VARCHAR2)
  return acs_financial_currency.acs_financial_currency_id%TYPE
is
  ln_result acs_financial_currency.acs_financial_currency_id%TYPE;
begin
  select ACS_FINANCIAL_CURRENCY_ID
  into ln_result
  from ACS_FINANCIAL_CURRENCY
  where PC_CURR_ID = (select PC_CURR_ID from PCS.PC_CURR
                      where CURRENCY = iv_CURRENCY);
  return ln_result;
end;

END ACS_LIB_LOOKUP;
