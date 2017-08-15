--------------------------------------------------------
--  DDL for Procedure IND_C9_CTRL_MAJOR_AVS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_CTRL_MAJOR_AVS" (PROCPARAM0 varchar2,PROCPARAM1 varchar2,aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
-- Procédure utilisée dans le rapport Crystal HRM_MAJORATION_AVS 
is
 vPeriod varchar2(6);
 SearchName varchar2(200);
begin
 vPeriod:=PROCPARAM0;
 SearchName:=PROCPARAM1;

 OPEN AREFCURSOR FOR
  select
hrm_employee_id,
per_search_name,
emp_number,
coe_box,
coe_descr,
coe_code,
elr_root_code,
erd_descr,
his_pay_period,
period,
his_pay_value,
his_pay_sum_val_chf,
currency,
his_pay_sum_val_dev
from
v_ind_hrm_cub_list
where
col_name='Contrôle Majoration AVS'
and pc_lang_id=1
and period=vPeriod
  and (per_search_name like upper(SearchName||'%')
      or SearchName is null);
end ind_c9_ctrl_major_avs;
