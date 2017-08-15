--------------------------------------------------------
--  DDL for Procedure IND_C9_PAY_NB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_PAY_NB" (aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,PROCPARAM0 varchar2)
 -- Procédure C9 pour rapport Crystal
 is
 vPeriod varchar2(6);

 begin
  vPeriod:=PROCPARAM0;

  open aRefCursor for
  select
pay.hrm_employee_id,
per.per_search_name,
per.emp_number,
pay.pay_period,
to_char(pay.pay_period,'YYYYMM') period,
(select currency
 from ACS_FINANCIAL_CURRENCY a, pcs.pc_curr b
 where a.pc_curr_id=b.pc_curr_id
 and a.ACS_FINANCIAL_CURRENCY_ID=pay.ACS_FINANCIAL_CURRENCY_id) currency,
pay.pay_amount,
(select case
         when min(to_char(ino_in,'YYYYMM'))=vPeriod then '1. Entrée dans le mois'
         when max(trunc(ino_out,'MM'))=add_months(to_date(vPeriod,'YYYYMM'),-1) then '2. Sortie mois précédent'
         else '3. Présent'
        end
from hrm_in_out ino
 where ino.hrm_employee_id=per.hrm_person_id
 and ino_in <= last_day(to_date(vPeriod,'YYYYMM'))
 and (ino_out >= add_months(to_date(vPeriod,'YYYYMM'),-1)
     or ino_out is null)
 ) presence,
(select min(ino_in)
 from hrm_in_out ino
 where ino.hrm_employee_id=per.hrm_person_id
 and ino_in <= last_day(to_date(vPeriod,'YYYYMM'))
 and (ino_out >= add_months(to_date(vPeriod,'YYYYMM'),-1)
     or ino_out is null)
 ) ino_in,
(select max(ino_out)
 from hrm_in_out ino
 where ino.hrm_employee_id=per.hrm_person_id
 and ino_in <= last_day(to_date(vPeriod,'YYYYMM'))
 and (ino_out >= add_months(to_date(vPeriod,'YYYYMM'),-1)
     or ino_out is null)
 ) ino_out,
(select max(dic_salary_number_id)
 from hrm_contract con
 where con.hrm_employee_id=per.hrm_person_id
 and con_begin <= last_day(to_date(vPeriod,'YYYYMM'))
 and (con_end >= add_months(to_date(vPeriod,'YYYYMM'),-1)
     or con_end is null)
 ) dic_salary_number_id
from
hrm_pay_log pay,
hrm_person per
where
pay.hrm_employee_id=per.hrm_person_id
and pay_period <= last_day(to_date(vPeriod,'YYYYMM'))
and pay_period >= add_months(to_date(vPeriod,'YYYYMM'),-1);

 end ind_c9_pay_nb;
