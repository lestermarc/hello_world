--------------------------------------------------------
--  DDL for Procedure IND_C9_AVS_CTRL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_AVS_CTRL" (PROCPARAM0 varchar2,PROCPARAM1 varchar2,PROCPARAM2 varchar2,aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
 -- Procédure pour rapport Crystal HRM_AVS_CTRL
 is
 vPeriodFrom varchar2(6);
 vPeriodTo varchar2(6);
 SearchName varchar2(200);

 begin
  vPeriodFrom:=PROCPARAM0;
  vPeriodTo:=PROCPARAM1;
  SearchName:=PROCPARAM2;

  -- Ouverture du curseur
  OPEN AREFCURSOR FOR
  select
  a.hrm_employee_id,
  per_search_name,
  emp_number,
  emp_social_securityno,
  emp_social_securityno2,
  hit_pay_period,
  to_char(hit_pay_period,'YYYYMM') period_yyyymm,
  nvl(hrm_functions.sumelem(a.hrm_employee_id,'CemSoumAVS',hit_pay_period,hit_pay_period),0)+
   nvl(hrm_functions.sumelem(a.hrm_employee_id,'CemBasAVSPa100',hit_pay_period,hit_pay_period),0) soum_avs,
  nvl(hrm_functions.sumelem(a.hrm_employee_id,'CemMaxSoumAC',hit_pay_period,hit_pay_period),0) max_soum_ac,
  nvl(hrm_functions.sumelem(a.hrm_employee_id,'CemSoumAC',hit_pay_period,hit_pay_period),0)+
    nvl(hrm_functions.sumelem(a.hrm_employee_id,'CemSoumACPa',hit_pay_period,hit_pay_period),0) soum_ac,
nvl(hrm_functions.sumelem(a.hrm_employee_id,'CemMaxSoumACC',hit_pay_period,hit_pay_period),0) max_soum_acc,
  nvl(hrm_functions.sumelem(a.hrm_employee_id,'CemSoumACC',hit_pay_period,hit_pay_period),0)+
    nvl(hrm_functions.sumelem(a.hrm_employee_id,'CemSoumACCPa',hit_pay_period,hit_pay_period),0) soum_acc
  from
  (select distinct hrm_employee_id, hit_pay_period from hrm_history) a,
  hrm_person b
  where
  a.hrm_employee_id=b.hrm_person_id
  and to_char(hit_pay_period,'YYYYMM') between vPeriodFrom and vPeriodTo
  and exists (select 1
  		   from hrm_history_detail his, hrm_elements ele
  		   where his.hrm_elements_id=ele.hrm_elements_id
  		   and a.hrm_employee_id=his.hrm_employee_id
  		   and a.hit_pay_period=his.his_pay_period
  		   and ele.ele_code in ('CemSoumAVS','CemBasAVSPa100','CemMaxSoumAC','CemSoumAC','CemSoumACPa')
  		   )
  and (per_search_name like upper(SearchName||'%')
      or SearchName is null);
  --order by per_search_name;


 end ind_c9_avs_ctrl;
