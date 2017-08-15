--------------------------------------------------------
--  DDL for Package Body HRM_BREAK_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_BREAK_FCT" 
AS

/**
 * Rechercher d'un numéro de compte analytique.
 */
function get_Account_Number(
  vHisDetailId IN hrm_salary_breakdown.hrm_history_detail_id%TYPE,
  vSource IN hrm_salary_breakdown.sab_source%TYPE,
  vAmountType IN hrm_salary_breakdown.sab_amount_type%TYPE,
  vAccountType IN hrm_salary_breakdown.dic_account_type_id%TYPE)
  return hrm_salary_breakdown.sab_account_name%TYPE
is
  result hrm_salary_breakdown.sab_account_name%TYPE;
begin
  select sab_account_name into result
  from hrm_salary_breakdown
  where dic_account_type_id = vAccountType and
    hrm_history_detail_id = vHisDetailId and
    sab_source = vSource and
    sab_amount_type = vAmountType;
  return result;

  exception
    when NO_DATA_FOUND then
      return null;
end;


/**
 * Rechercher de la description d'un compte analytique en fonction de l'id
 */
function get_Account_Descr(
  vAccountId IN acs_account.acs_account_id%TYPE,
  vLangId IN pcs.pc_lang.pc_lang_id%TYPE)
  return acs_description.des_description_summary%TYPE
is
  result acs_description.des_description_summary%TYPE;
begin
  if (vAccountId is not null) then
    select des_description_summary into result
    from acs_description
    where acs_account_id = vAccountId and pc_lang_id = vLangId;
    return result;
  end if;
  return null;

  exception
    when NO_DATA_FOUND then
      return null;
end;

/**
 * Rechercher de la description d'un compte analytique en fonction du numéro
 */
function get_Account_Descr(
  pSubSet IN acs_sub_set.c_sub_set%TYPE,
  pAccountNum IN acs_account.acc_number%TYPE,
  pLangId IN pcs.pc_lang.pc_lang_id%TYPE)
  return acs_description.des_description_summary%TYPE
is
  result acs_description.des_description_summary%TYPE;
begin
  select des_description_summary into result
  from acs_description
  where acs_account_id =
      (select acs_account_id
       from acs_account a, acs_sub_set s
       where a.acs_sub_set_id = s.acs_sub_set_id and
         s.c_sub_set = pSubSet and
         a.acc_number = pAccountNum) and
    pc_lang_id = pLangId;
  return result;

  exception
    when NO_DATA_FOUND then
      return null;
end;

END HRM_BREAK_FCT;
