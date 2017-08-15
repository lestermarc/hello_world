--------------------------------------------------------
--  DDL for Package Body WEB_REPORT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_REPORT_FUNCTIONS" 
AS

function getVAGoodInfo(
  pGcoGoodId              IN GCO_GOOD.GCO_GOOD_ID%type,
  pPacCustomPartnerId     IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type,
  pAcsFinancialCurrencyId IN ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
  pPcLangId               IN PCS.PC_LANG.PC_LANG_ID%type,
  pKey                    IN VARCHAR2) return varchar2
is
  cursor goods(pGcoGoodId number,pPcLangId number) is
  select
    goo_major_reference,
    dic_unit_of_measure_id ,
    hrm_functions.GETDICODESCR('DIC_UNIT_OF_MEASURE',DIC_UNIT_OF_MEASURE_ID,pPcLangId) dic_unit_of_measure_id_value,
    des_short_description,
    des_long_description,
    des_free_description
  from gco_good g,gco_description d
  where
    d.gco_good_id=g.gco_good_id and
    d.C_DESCRIPTION_TYPE='01' and
    g.gco_good_id=pGcoGoodId and
    pc_lang_id=pPcLangId;

  returnVal varchar2(2000);
  r goods%rowtype;
begin
  open goods(pGcoGoodId,pPcLangId);
  fetch goods into r;

  if (pKey='1') then
    returnVal:=r.goo_major_reference;
  elsif (pKey='2') then
    returnVal:=r.des_short_description;
  elsif (pKey='3') then
    returnVal:=r.des_long_description;
  elsif (pKey='4') then
    returnVal:=r.des_free_description;
  elsif (pKey='5') then
    returnVal:=r.dic_unit_of_measure_id;
  elsif (pKey='6') then
    returnVal:=r.dic_unit_of_measure_id_value;
  end if;
  return returnVal;
end;

function getNGoodInfo(
  pGcoGoodId              IN GCO_GOOD.GCO_GOOD_ID%type,
  pPacCustomPartnerId     IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type,
  pAcsFinancialCurrencyId IN ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
  pPcLangId               IN PCS.PC_LANG.PC_LANG_ID%type,
  pKey                    IN VARCHAR2) return number
is
 returnVal number(16,5);
begin
  if (pKey='1') then
    returnVal:=1;
  elsif (pKey='2') then
    returnVal:=2;
  elsif (pKey='3') then
    returnVal:=3;
  elsif (pKey='4') then
    returnVal:=4;
  elsif (pKey='5') then
    returnVal:=5;
  elsif (pKey='6') then
    returnVal:=6;
  end if;
  return returnVal;
end;

function getDateGoodInfo(
  pGcoGoodId              IN GCO_GOOD.GCO_GOOD_ID%type,
  pPacCustomPartnerId     IN PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type,
  pAcsFinancialCurrencyId IN ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type,
  pPcLangId               IN PCS.PC_LANG.PC_LANG_ID%type,
  pKey                    IN VARCHAR2) return date
is
  returnVal date;
begin
  if (pKey='1') then
    select sysdate into returnVal from dual;
  elsif (pKey='2') then
    select sysdate into returnVal from dual;
  elsif (pKey='3') then
    select sysdate into returnVal from dual;
  elsif (pKey='4') then
    select sysdate into returnVal from dual;
  elsif (pKey='5') then
    select sysdate into returnVal from dual;
  elsif (pKey='6') then
    select sysdate into returnVal from dual;
  end if;
  return returnVal;
end;

end web_report_functions;
