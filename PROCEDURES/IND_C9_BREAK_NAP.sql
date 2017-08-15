--------------------------------------------------------
--  DDL for Procedure IND_C9_BREAK_NAP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_BREAK_NAP" (aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,PARAMETER_0 varchar2)
 -- Procédure C9 pour rapport Crystal
 is
 vPeriod varchar2(6);

 begin
  vPeriod:=PARAMETER_0;

  open aRefCursor for
  select
  v.hrm_break_id,
  b.BRK_DESCRIPTION,
  b.BRK_BREAK_DATE,
  b.BRK_VALUE_DATE,
  b.BRK_STATUS,
  v.sab_pay_date,
  to_char(v.sab_pay_date,'YYYYMM') period,
  v.v_hbc_acc_name,
  c.DIC_FIN_ACC_CODE_1_ID,
  c.DIC_FIN_ACC_CODE_2_ID,
  v.heb_div_number,
  p.per_search_name,
  p.emp_secondary_key,
  v.currency,
  v.v_hbc_debit_amount_dev,
  v.v_hbc_credit_amount_dev,
  v.v_hbc_debit_amount,
  v.v_hbc_credit_amount
  from
  v_ind_hrm_break_detail v,
  hrm_break b,
  (select acc.acc_number,fac.DIC_FIN_ACC_CODE_1_ID,fac.DIC_FIN_ACC_CODE_2_ID
   from acs_account acc, ACS_FINANCIAL_ACCOUNT fac
   where acc.acs_account_id=fac.ACS_FINANCIAL_ACCOUNT_id
   and (fac.DIC_FIN_ACC_CODE_1_ID is not null
        or fac.DIC_FIN_ACC_CODE_2_ID is not null)) c,
  hrm_person p      
  where
  v.hrm_break_id=b.hrm_break_id
  and v.v_hbc_acc_name=c.acc_number
  and v.hrm_employee_id=p.hrm_person_id
  and to_char(sab_pay_date,'YYYYMM')=vPeriod;
  
end ind_c9_break_nap;
