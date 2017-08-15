--------------------------------------------------------
--  DDL for Procedure IND_C9_COMPARE_PAY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_COMPARE_PAY" (PARAMETER_PROC0 varchar2, PARAMETER_PROC1 varchar2, aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
 -- Procédure utilisée par les rapports Crystal HRM_COMPARE_BANK
 is
 vPeriod varchar2(6);
 SearchName varchar2(200);

 begin
  vPeriod:=PARAMETER_PROC0;
  SearchName:=PARAMETER_PROC1;

  -- Ouverture du curseur
  OPEN AREFCURSOR FOR
  select
  hrm_employee_id,
  per_search_name,
  emp_number,
  ino_in,
  ino_out,
  ban_name1,
  ban_city,
  cntid,
  pay_mode,
  pay_acc_num,
  --pay_ban_etab,
  --pay_ban_guich,
  --pay_swift,
  vPeriod period_yyyymm,
  to_char(add_months(to_date(vPeriod,'YYYYMM'),-1),'YYYYMM') period_yyyymm_1,
  currency,
  (select pay_amount
   from hrm_pay_log log
   where nvl(log.pc_bank_id,0)=nvl(sub.pc_bank_id,0)
   and nvl(log.pay_acc_num,'0')=nvl(sub.pay_acc_num,'0')
   and nvl(log.acs_financial_currency_id,0)=nvl(sub.acs_financial_currency_id,0)
   and log.pay_mode=sub.pay_mode
   and log.hrm_employee_id=sub.hrm_employee_id
   and to_char(log.pay_period,'YYYYMM')=vPeriod
   ) pay_amount,
  (select pay_amount
   from hrm_pay_log log
   where nvl(log.pc_bank_id,0)=nvl(sub.pc_bank_id,0)
   and nvl(log.pay_acc_num,'0')=nvl(sub.pay_acc_num,'0')
   and nvl(log.acs_financial_currency_id,0)=nvl(sub.acs_financial_currency_id,0)
   and log.pay_mode=sub.pay_mode
   and log.hrm_employee_id=sub.hrm_employee_id
   and log.pay_period=last_day(add_months(to_date(vPeriod,'YYYYMM'),-1))
   ) pay_amount_1
  from
  (select
   distinct
   a.hrm_employee_id,
   a.pc_bank_id,
   acs_financial_currency_id,
   per_search_name,
   emp_number,
   d.entry ino_in,
   d.exit ino_out,
   b.ban_name1,
   b.ban_city,
   (select cntid from pcs.pc_cntry cnt where b.pc_cntry_id=cnt.pc_cntry_id) cntid,
   pay_mode,
   pay_acc_num,
   (select currency
    from acs_financial_currency fcur, pcs.pc_curr cur
    where a.acs_financial_currency_id=fcur.acs_financial_currency_id
    and fcur.pc_curr_id=cur.pc_curr_id) currency
   --pay_ban_etab,
   --pay_ban_guich,
   --pay_swift
   from
   hrm_pay_log a,
   pcs.pc_bank b,
   hrm_person c,
   v_hrm_last_entry d
   where
   a.pc_bank_id=b.pc_bank_id(+)
   and a.hrm_employee_id=c.hrm_person_id
   and a.hrm_employee_id=d.empid(+)
   and (to_char(pay_period,'YYYYMM')=vPeriod
        or pay_period=last_day(add_months(to_date(vPeriod,'YYYYMM'),-1))
   	 )
   and (per_search_name like upper(SearchName||'%')
        or SearchName is null)
   ) sub;

 end ind_c9_compare_pay;
