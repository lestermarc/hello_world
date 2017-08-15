--------------------------------------------------------
--  DDL for Procedure IND_C9_COMPARE_PERIOD_TRIM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_COMPARE_PERIOD_TRIM" (PARAMETER_PROC0 varchar2, PARAMETER_PROC1 varchar2, PARAMETER_PROC2 varchar2, aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
 -- Procédure utilisée par les rapports Crystal HRM_COMPARE_PERIOD et HRM_COMPARE_TRIM
 is
 vPeriod varchar2(6);
 SearchName varchar2(200);
 Class7Display varchar2(10);

 begin
  vPeriod:=PARAMETER_PROC0;           --Période référence (YYYYMM)
  SearchName:=PARAMETER_PROC1;        --Nom de l'employé (vide -> tous les employés)
  Class7Display:=PARAMETER_PROC2;     --Forcer affichage des rubriques de la classe 7

  -- Ouverture du curseur
  OPEN AREFCURSOR FOR
  select
  hrm_employee_id,
  hrm_elements_id,
  hrm_elements_root_id,
  pc_lang_id,
  ele_code,
  c_root_type,
  c_root_variant,
  per_search_name,
  emp_number,
  ino_in,
  ino_out,
  to_char(add_months(to_date(vPeriod,'YYYYMM'),-2),'YYYYMM') period_yyyymm_2,
  to_char(add_months(to_date(vPeriod,'YYYYMM'),-1),'YYYYMM') period_yyyymm_1,
  vPeriod period_yyyymm,
  elr_root_code,
  erd_descr,
  hrm_itx.SUMELEMYYYYMM(hrm_employee_id,ele_code,to_char(add_months(to_date(vPeriod,'YYYYMM'),-2),'YYYYMM'),to_char(add_months(to_date(vPeriod,'YYYYMM'),-2),'YYYYMM')) his_pay_sum_val_chf_2,
  hrm_itx.GET_PERS_CURRYYYYMM(hrm_employee_id,to_char(add_months(to_date(vPeriod,'YYYYMM'),-2),'YYYYMM')) currency_2,
  hrm_itx.SUMELEMDEVISEYYYYMM(hrm_employee_id,ele_code,to_char(add_months(to_date(vPeriod,'YYYYMM'),-2),'YYYYMM'),to_char(add_months(to_date(vPeriod,'YYYYMM'),-2),'YYYYMM')) his_pay_sum_val_dev_2,
  hrm_itx.SUMELEMYYYYMM(hrm_employee_id,ele_code,to_char(add_months(to_date(vPeriod,'YYYYMM'),-1),'YYYYMM'),to_char(add_months(to_date(vPeriod,'YYYYMM'),-1),'YYYYMM')) his_pay_sum_val_chf_1,
  hrm_itx.GET_PERS_CURRYYYYMM(hrm_employee_id,to_char(add_months(to_date(vPeriod,'YYYYMM'),-1),'YYYYMM')) currency_1,
  hrm_itx.SUMELEMDEVISEYYYYMM(hrm_employee_id,ele_code,to_char(add_months(to_date(vPeriod,'YYYYMM'),-1),'YYYYMM'),to_char(add_months(to_date(vPeriod,'YYYYMM'),-1),'YYYYMM')) his_pay_sum_val_dev_1,
  hrm_itx.SUMELEMYYYYMM(hrm_employee_id,ele_code,vPeriod,vPeriod) his_pay_sum_val_chf,
  hrm_itx.GET_PERS_CURRYYYYMM(hrm_employee_id,vPeriod) currency,
  hrm_itx.SUMELEMDEVISEYYYYMM(hrm_employee_id,ele_code,vPeriod,vPeriod) his_pay_sum_val_dev
  from
  (select
   distinct
   a.hrm_employee_id,
   f.hrm_elements_id,
   d.hrm_elements_root_id,
   e.pc_lang_id,
   ele_code,
   c_root_type,
   c_root_variant,
   per_search_name,
   emp_number,
   entry ino_in,
   exit ino_out,
   elr_root_code,
   erd_descr
   from
   hrm_history_detail a,
   hrm_person b,
   hrm_elements_family c,
   hrm_elements_root d,
   hrm_elements_root_descr e,
   hrm_elements f,
   v_hrm_last_entry g
   where
   a.hrm_employee_id=b.hrm_person_id
   and a.hrm_elements_id=c.hrm_elements_id
   and c.hrm_elements_root_id=d.hrm_elements_root_id
   and d.hrm_elements_root_id=e.hrm_elements_root_id
   and c.hrm_elements_id=f.hrm_elements_id
   and e.pc_lang_id=b.pc_lang_id
   and b.hrm_person_id=g.empid
   and ELF_IS_REFERENCE=1
   and (to_char(a.his_pay_period,'YYYYMM')=vPeriod
       or a.his_pay_period=last_day(add_months(to_date(vPeriod,'YYYYMM'),-1))
	   or a.his_pay_period=last_day(add_months(to_date(vPeriod,'YYYYMM'),-2))
   	)
   and (to_char(a.his_pay_period,'YYYYMM')=vPeriod
       or a.his_pay_period=last_day(add_months(to_date(vPeriod,'YYYYMM'),-1)))
    and (
       (elr_is_print=1 and elr_condition<>'FALSE')
       or
        (substr(elr_root_code,1,1)='7' and elr_reporting=1 and upper(Class7Display)='VRAI')
       )
   and elr_root_code not like '8%'
   and (per_search_name like upper(SearchName||'%')
      or SearchName is null)
   )  ;

 end ind_c9_compare_period_trim;
