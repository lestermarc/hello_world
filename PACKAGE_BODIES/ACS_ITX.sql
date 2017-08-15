--------------------------------------------------------
--  DDL for Package Body ACS_ITX
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_ITX" 
is
 procedure CreateAccount(AccNum acs_account.acc_number%type,
                         AccDescr acs_description.des_description_summary%type,
                         BilanPP acs_financial_account.C_BALANCE_SHEET_PROFIT_LOSS%type,
                         AccBlocked acs_account.acc_blocked%type)
 is
  AccId acs_account.acs_account_id%type;
 begin

 select init_id_seq.nextval into AccId
 from dual;

 -- ACS_ACCOUNT
 insert into acs_account (
 ACS_ACCOUNT_ID,
 ACS_SUB_SET_ID,
 ACC_NUMBER,
 ACC_BLOCKED,
 A_DATECRE,
 A_IDCRE)
 select
 AccId,
 (select max(acs_sub_set_id) from acs_sub_set where c_sub_set='ACC'),
 AccNum,
 AccBlocked,
 sysdate,
 'RGU'
 from dual;

 -- ACS_FINANCIAL_ACCOUNT
 insert into acs_financial_account (
 ACS_FINANCIAL_ACCOUNT_ID,
 C_BALANCE_SHEET_PROFIT_LOSS,
 A_DATECRE,
 A_IDCRE)
 values (
 AccId,
 BilanPP,
 sysdate,
 'RGU');

 -- ACS_DESCRIPTION
 insert into acs_description (
 ACS_DESCRIPTION_ID,
 ACS_ACCOUNT_ID,
 PC_LANG_ID,
 DES_DESCRIPTION_SUMMARY,
 A_DATECRE,
 A_IDCRE)
 select
 init_id_seq.nextval,
 AccId,
 1,
 AccDescr,
 sysdate,
 'RGU'
 from dual;

 -- ACS_FIN_ACCOUNT_S_FIN_CURR
 insert into ACS_FIN_ACCOUNT_S_FIN_CURR (
 ACS_FINANCIAL_ACCOUNT_ID,
 ACS_FINANCIAL_CURRENCY_ID,
 FSC_DEFAULT)
 select
 AccId,
 ACS_FUNCTION.GetLocalCurrencyId,
 1
 from dual;

end CreateAccount;

end ACS_ITX;
