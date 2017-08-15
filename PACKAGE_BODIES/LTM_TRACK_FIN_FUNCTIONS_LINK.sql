--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_FIN_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_FIN_FUNCTIONS_LINK" 
/**
 * Package LTM_TRACK_FIN_FUNCTIONS_LINK
 * @version 1.0
 * @date 10/2006
 * @author rforchelet
 * @author spfister
 * @since Oracle 9.2
 *
 * Copyright 1997-2008 Pro-Concept SA. Tous droits réservés.
 *
 * Package contenant les fonctions de génération de document Xml pour des
 * liaisons sur des clés étrangères.
 * Spécialisation: Finance (ACS)
 */
AS

function get_acs_fin_curr_link(Id IN acs_financial_currency.acs_financial_currency_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_FINANCIAL_CURRENCY')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select f.acs_financial_currency_id, c.currency
      from pcs.pc_curr c, acs_financial_currency f
      where c.pc_curr_id = f.pc_curr_id and f.acs_financial_currency_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_acs_account_link(Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_ACCOUNT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select a.acs_account_id, a.acc_number, a.c_valid, s.c_type_sub_set, s.c_sub_set
      from acs_sub_set s, acs_account a
      where s.acs_sub_set_id = a.acs_sub_set_id and a.acs_account_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_acs_fin_acc_s_payment_link(Id IN acs_fin_acc_s_payment.acs_fin_acc_s_payment_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_FIN_ACC_S_PAYMENT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_FIN_ACC_S_PAYMENT,
      ltm_xml_utils.genXML(CURSOR(
        select acs_fin_acc_s_payment_id, acs_financial_account_id, acs_payment_method_id
        from acs_fin_acc_s_payment
        where acs_fin_acc_s_payment_id = T.acs_fin_acc_s_payment_id),
        ''),
      ltm_track_fin_functions_link.get_acs_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_payment_method_link(acs_payment_method_id)
    ) into obj
  from acs_fin_acc_s_payment T
  where acs_fin_acc_s_payment_id = Id;

  if (obj is not null and FieldRef != 'ACS_FIN_ACC_S_PAYMENT') then
    return ltm_xml_utils.transform_root_ref('ACS_FIN_ACC_S_PAYMENT', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_acs_vat_det_account_link(Id IN acs_vat_det_account.acs_vat_det_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_VAT_DET_ACCOUNT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_VAT_DET_ACCOUNT,
      ltm_xml_utils.genXML(CURSOR(
        select acs_vat_det_account_id, acs_sub_set_id
        from acs_vat_det_account
        where acs_vat_det_account_id = T.acs_vat_det_account_id),
        ''),
      ltm_track_fin_functions_link.get_acs_sub_set_link(acs_sub_set_id)
    ) into obj
  from acs_vat_det_account T
  where acs_vat_det_account_id = Id;

  if (obj is not null and FieldRef != 'ACS_VAT_DET_ACCOUNT') then
    return ltm_xml_utils.transform_root_ref('ACS_VAT_DET_ACCOUNT', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_acs_payment_method_link(Id IN acs_payment_method.acs_payment_method_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_PAYMENT_METHOD')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select acs_payment_method_id, c_type_support, c_method_category
      from acs_payment_method
      where acs_payment_method_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_acs_sub_set_link(Id IN acs_sub_set.acs_sub_set_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_DESCRIPTION')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(ACS_DESCRIPTION,
      ltm_xml_utils.genXML(CURSOR(
        select d.acs_sub_set_id, l.lanid, d.des_description_summary
        from pcs.pc_lang l, acs_description d, acs_vat_det_account v
        where v.acs_vat_det_account_id = T.acs_vat_det_account_id and
          d.acs_sub_set_id = v.acs_sub_set_id and
          l.pc_lang_id = d.pc_lang_id),
        ''),
      ltm_track_pc_functions_link.get_pc_lang_link(d.pc_lang_id))
    order by T.a_datecre, d.a_datecre
    ) into obj
  from acs_description d, acs_vat_det_account T
  where T.acs_sub_set_id = Id and d.acs_sub_set_id = T.acs_sub_set_id;

  if (obj is not null and FieldRef != 'ACS_DESCRIPTION') then
    return ltm_xml_utils.transform_root_ref('ACS_DESCRIPTION', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

END LTM_TRACK_FIN_FUNCTIONS_LINK;
