--------------------------------------------------------
--  DDL for Procedure IND_C9_BILLING_SHEET
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_BILLING_SHEET" (PROCPARAM0 varchar2,PROCPARAM1 varchar2,PROCPARAM2 varchar2,aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
 -- Procédure utilisée par le rapport HRM_BILLING_SHEET
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
  per_search_name,
  emp_number,
  coe_descr,
  substr(coe_descr,1,3) regroup_code,
  substr(coe_descr,5,999) regroup_descr,
  coe_box,
  (select max(erd_descr)
   from hrm_elements_root r, hrm_elements_root_descr d
   where r.hrm_elements_root_id=d.hrm_elements_root_id
   and a.coe_box=r.elr_root_code
   and d.pc_lang_id=1) erd_descr_FR,
  (select max(erd_descr)
   from hrm_elements_root r, hrm_elements_root_descr d
   where r.hrm_elements_root_id=d.hrm_elements_root_id
   and a.coe_box=r.elr_root_code
   and d.pc_lang_id=3) erd_descr_EN,
  currency,
  sum(his_pay_sum_val_chf) his_pay_sum_val_chf,
  sum(his_pay_sum_val_dev) his_pay_sum_val_dev
  from
  v_ind_hrm_cub_list a
  where
  col_name='BILLING SHEET'
  and a.pc_lang_id=1
  and period between vPeriodFrom and vPeriodTo
  and (per_search_name like upper(SearchName||'%')
        or SearchName is null)
  group by per_search_name,
  emp_number,
  coe_descr,
  coe_box,
  currency;
 /*UNION ALL
   select
  per_search_name,
  emp_number,
  coe_descr,
  substr(coe_descr,1,3) regroup_code,
  substr(coe_descr,5,999) regroup_descr,
  coe_box,
  (select max(erd_descr)
   from hrm_elements_root r, hrm_elements_root_descr d
   where r.hrm_elements_root_id=d.hrm_elements_root_id
   and coe.coe_box=r.elr_root_code
   and d.pc_lang_id=1) erd_descr_FR,
  (select max(erd_descr)
   from hrm_elements_root r, hrm_elements_root_descr d
   where r.hrm_elements_root_id=d.hrm_elements_root_id
   and coe.coe_box=r.elr_root_code
   and d.pc_lang_id=3) erd_descr_EN,
  (select max(cod_code)
   from hrm_employee_const ec, hrm_constants c, hrm_code_table tb,
        (select hrm_employee_id, hrm_constants_id, max(emc_value_from) emc_value_from from hrm_employee_const group by hrm_employee_id, hrm_constants_id) lec
   where per.hrm_person_id=ec.hrm_employee_id
   and ec.hrm_constants_id=c.hrm_constants_id
   and ec.hrm_code_table_id=tb.hrm_code_table_id
   and ec.hrm_employee_id=lec.hrm_employee_id
   and ec.hrm_constants_id=lec.hrm_constants_id
   and ec.emc_value_from=lec.emc_value_from
   and con_code='ConEmMonnaieDéc'
   ) currency,
  sum(0) his_pay_sum_val_chf,
  sum(0) his_pay_sum_val_dev
  from
  hrm_person per,
  hrm_control_list col,
  hrm_control_elements coe
  where
  col.hrm_control_list_id=coe.hrm_control_list_id
  and col_name='BILLING SHEET'
  and (per_search_name like upper(SearchName||'%')
        or SearchName is null)
  and not exists (select 1
  	  	  		 from v_ind_hrm_cub_list v
                 where
                 col_name='BILLING SHEET'
				 and v.pc_lang_id=1
                 and period between vPeriodFrom and vPeriodTo
                 and per.hrm_person_id=v.hrm_employee_id
				 and coe.coe_box=v.coe_box)
  and exists (select 1
  	  		 from hrm_history h
			 where per.hrm_person_id=h.hrm_employee_id
			 and to_char(hit_pay_period,'YYYYMM') between vPeriodFrom and vPeriodTo)
  group by per_search_name,
  emp_number,
  coe_descr,
  coe_box,
  per.hrm_person_id ;
*/

 end ind_c9_billing_sheet;
