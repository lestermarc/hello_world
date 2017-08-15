--------------------------------------------------------
--  DDL for Package Body PAC_LIB_LOOKUP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_LIB_LOOKUP" 
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

function getPERSON(
  iv_PER_KEY1 IN VARCHAR2)
  return pac_person.pac_person_id%TYPE
is
  ln_result pac_person.pac_person_id%TYPE;
begin
  select PAC_PERSON_ID
  into ln_result
  from PAC_PERSON
  where PER_KEY1 = iv_PER_KEY1;

  return ln_result;
end;
function getPERSON_BY_NAME(
  iv_PER_NAME IN VARCHAR2,
  iv_PER_FORENAME IN VARCHAR2)
  return pac_person.pac_person_id%TYPE
is
  ln_result pac_person.pac_person_id%TYPE;
begin
  select max(PAC_PERSON_ID)
  into ln_result
  from PAC_PERSON
  where PER_NAME = iv_PER_NAME
    and ((PER_FORENAME = iv_PER_FORENAME) or
          ((PER_FORENAME is null) and (iv_PER_FORENAME is null))
        );
  return ln_result;
end;


function getADDRESS(
  iv_PER_KEY1 IN VARCHAR2,
  iv_DIC_ADDRESS_TYPE_ID IN VARCHAR2)
  return pac_address.pac_address_id%TYPE
is
  ln_result pac_address.pac_address_id%TYPE;
begin
  select max(PAC_ADDRESS_ID)
  into ln_result
  from PAC_ADDRESS
  where DIC_ADDRESS_TYPE_ID = iv_DIC_ADDRESS_TYPE_ID and
    PAC_PERSON_ID = (select PAC_PERSON_ID from PAC_PERSON
                     where PER_KEY1 = iv_PER_KEY1);
  return ln_result;
end;
function getADDRESS(
  iv_PERSON_ID IN NUMBER,
  iv_DIC_ADDRESS_TYPE_ID IN VARCHAR2)
  return pac_address.pac_address_id%TYPE
is
  ln_result pac_address.pac_address_id%TYPE;
begin
  select max(PAC_ADDRESS_ID)
  into ln_result
  from PAC_ADDRESS
  where DIC_ADDRESS_TYPE_ID = iv_DIC_ADDRESS_TYPE_ID and
    PAC_PERSON_ID = iv_PERSON_ID;
  return ln_result;
end;
function getADDRESS_PRINCIPAL(
  iv_PERSON_ID IN NUMBER)
  return pac_address.pac_address_id%TYPE
is
  ln_result pac_address.pac_address_id%TYPE;
begin
  select max(PAC_ADDRESS_ID)
  into ln_result
  from PAC_ADDRESS
  where PAC_PERSON_ID = iv_PERSON_ID
    and ADD_PRINCIPAL = 1;
  return ln_result;
end;
function getADDRESS_PRINCIPAL_CNTRY(
  iv_PERSON_ID IN NUMBER)
  return pac_address.pc_cntry_id%TYPE
is
  ln_result pac_address.pc_cntry_id%TYPE;
begin
  select PC_CNTRY_ID
  into ln_result
  from PAC_ADDRESS
  where PAC_PERSON_ID = iv_PERSON_ID
    and ADD_PRINCIPAL = 1;
  return ln_result;
end;
function getDIC_ADDRESS_TYPE_DEFAULT
  return dic_address_type.dic_address_type_id%TYPE
is
  lv_result dic_address_type.dic_address_type_id%TYPE;
begin
  select DIC_ADDRESS_TYPE_ID
  into lv_result
  from  DIC_ADDRESS_TYPE
  where DAD_DEFAULT = 1;
  return lv_result;
end;



function getCOMMUNICATION(
  iv_PER_KEY1 IN VARCHAR2,
  iv_DIC_COMMUNICATION_TYPE_ID IN VARCHAR2)
  return pac_communication.pac_communication_id%TYPE
is
  ln_result pac_communication.pac_communication_id%TYPE;
begin
  select max(PAC_COMMUNICATION_ID)
  into ln_result
  from PAC_COMMUNICATION
  where DIC_COMMUNICATION_TYPE_ID = iv_DIC_COMMUNICATION_TYPE_ID and
    PAC_PERSON_ID = (select PAC_PERSON_ID from PAC_PERSON
                     where PER_KEY1 = iv_PER_KEY1);
  return ln_result;
end;
function getCOMMUNICATION(
  in_PERSON_ID IN NUMBER,
  iv_DIC_COMMUNICATION_TYPE_ID IN VARCHAR2)
  return pac_communication.pac_communication_id%TYPE
is
  ln_result pac_communication.pac_communication_id%TYPE;
begin
  select max(PAC_COMMUNICATION_ID)
  into ln_result
  from PAC_COMMUNICATION
  where DIC_COMMUNICATION_TYPE_ID = iv_DIC_COMMUNICATION_TYPE_ID and
    PAC_PERSON_ID = in_PERSON_ID;
  return ln_result;
end;
function getCOM_DIC_DEFAULT(iv_DCO_TYPE dic_communication_type.dic_communication_type_id%TYPE)
  return dic_communication_type.dic_communication_type_id%TYPE
is
  lv_result dic_communication_type.dic_communication_type_id%TYPE;
begin
  select max(DIC_COMMUNICATION_TYPE_ID)
  into lv_result
  from DIC_COMMUNICATION_TYPE
  where
     (  (upper(iv_DCO_TYPE) = 'DCO_PHONE') and (DCO_PHONE = 1)) or
     (  (upper(iv_DCO_TYPE) = 'DCO_EMAIL') and (DCO_EMAIL = 1));
  return lv_result;
end;

function getPERSON_ASSOCIATION(
  iv_PER_KEY1_1 IN VARCHAR2,
  iv_PER_KEY1_2 IN VARCHAR2)
  return pac_person_association.pac_person_association_id%TYPE
is
  ln_result pac_person_association.pac_person_association_id%TYPE;
begin
  select pac_person_association_id
  into ln_result
  from pac_person_association
  where
    PAC_PERSON_ID = (select PAC_PERSON_ID from PAC_PERSON
                     where PER_KEY1 = iv_PER_KEY1_1) and
    PAC_PAC_PERSON_ID = (select PAC_PERSON_ID from PAC_PERSON
                        where PER_KEY1 = iv_PER_KEY1_2);
  return ln_result;
end;
function getPERSON_ASSOCIATION(
  in_PERSON_ID_1 IN NUMBER,
  in_PERSON_ID_2 IN NUMBER)
  return pac_person_association.pac_person_association_id%TYPE
is
  ln_result pac_person_association.pac_person_association_id%TYPE;
begin
  select pac_person_association_id
  into ln_result
  from pac_person_association
  where
    PAC_PERSON_ID = in_PERSON_ID_1 and
    PAC_PAC_PERSON_ID = in_PERSON_ID_2;
  return ln_result;
end;


function getTHIRD(
  iv_PER_KEY1 IN VARCHAR2)
  return pac_third.pac_third_id%TYPE
is
  ln_result pac_third.pac_third_id%TYPE;
begin
  select PAC_THIRD_ID
  into ln_result
  from PAC_THIRD
  where PAC_THIRD_ID = (select PAC_PERSON_ID from PAC_PERSON
                        where PER_KEY1 = iv_PER_KEY1);
  return ln_result;
end;


function getCUSTOM_PARTNER(
  iv_PER_KEY1 IN VARCHAR2)
  return pac_custom_partner.pac_custom_partner_id%TYPE
is
  ln_result pac_custom_partner.pac_custom_partner_id%TYPE;
begin
  select PAC_CUSTOM_PARTNER_ID
  into ln_result
  from PAC_CUSTOM_PARTNER
  where PAC_CUSTOM_PARTNER_ID = (select PAC_PERSON_ID from PAC_PERSON
                                 where PER_KEY1 = iv_PER_KEY1);
  return ln_result;
end;


function getSUPPLIER_PARTNER(
  iv_PER_KEY1 IN VARCHAR2)
  return pac_supplier_partner.pac_supplier_partner_id%TYPE
is
  ln_result pac_supplier_partner.pac_supplier_partner_id%TYPE;
begin
  select PAC_SUPPLIER_PARTNER_ID
  into ln_result
  from PAC_SUPPLIER_PARTNER
  where PAC_SUPPLIER_PARTNER_ID = (select PAC_PERSON_ID from PAC_PERSON
                                   where PER_KEY1 = iv_PER_KEY1);
  return ln_result;
end;


function getPAYMENT_CONDITION(
  iv_PCO_DESCR in VARCHAR2)
  return pac_payment_condition.pac_payment_condition_id%TYPE
is
  ln_result pac_payment_condition.pac_payment_condition_id%TYPE;
begin
  select Max(PAC_PAYMENT_CONDITION_ID)
  into ln_result
  from PAC_PAYMENT_CONDITION
  where PCO_DESCR = iv_PCO_DESCR;
  return ln_result;
end;

function getDefaultPAYMENT_CONDITION
  return pac_payment_condition.pac_payment_condition_id%TYPE
is
  ln_result pac_payment_condition.pac_payment_condition_id%TYPE;
begin
  select PAC_PAYMENT_CONDITION_ID
  into ln_result
  from PAC_PAYMENT_CONDITION
  where PCO_DEFAULT = 1;
  return ln_result;
end;


function getDefaultREMAINDER_CATEGORY
  return pac_remainder_category.pac_remainder_category_id%TYPE
is
  ln_result pac_remainder_category.pac_remainder_category_id%TYPE;
begin
  select PAC_REMAINDER_CATEGORY_ID
  into ln_result
  from PAC_REMAINDER_CATEGORY
  where RCA_DEFAULT = 1;
  return ln_result;
end;




function getVAT_DET_ACCOUNT(in_PC_CNTRY_ID in number)
  return acs_vat_det_account.acs_vat_det_account_id%type
is
  ln_result acs_vat_det_account.acs_vat_det_account_id%type;
begin
  select ACS_VAT_DET_ACCOUNT_ID
    into ln_result
    from (select   *
              from ACS_VAT_DET_ACCOUNT
             where PC_CNTRY_ID = in_PC_CNTRY_ID
          order by VDE_DEFAULT desc)
   where rownum = 1;

  return ln_result;
end;

function getDefaultVAT_DET_ACCOUNT
  return acs_vat_det_account.acs_vat_det_account_id%TYPE
is
  ln_result acs_vat_det_account.acs_vat_det_account_id%TYPE;
begin
  select ACS_VAT_DET_ACCOUNT_ID
  into ln_result
  from ACS_VAT_DET_ACCOUNT
  where VDE_DEFAULT = 1;
  return ln_result;
end;

  function getSUB_SET_ID(
  ivC_SUB_SET in VARCHAR)
 return acs_sub_set.acs_sub_set_id%TYPE
is
  ln_result acs_sub_set.acs_sub_set_id%TYPE;
begin
  select ACS_SUB_SET_ID
  into ln_result
  from (select * from ACS_SUB_SET
  where C_SUB_SET = ivC_SUB_SET
  order by SSE_DEFAULT desc)
  where rownum=1;
  return ln_result;
end;

END PAC_LIB_LOOKUP;
