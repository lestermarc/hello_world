--------------------------------------------------------
--  DDL for Procedure IND_C9_AVS_CTRL_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_AVS_CTRL_SUB" (aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
--(PROCPARAM0 varchar2,PROCPARAM1 varchar2,PROCPARAM2 varchar2,aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
 -- Procédure pour rapport Crystal HRM_AVS_CTRL (sous-rapport)
 is
 --vPeriodFrom varchar2(6);
 --vPeriodTo varchar2(6);
 --EmpId number;

 begin
  --vPeriodFrom:=PROCPARAM0;
  --vPeriodTo:=PROCPARAM1;
  --EmpId:=to_number(PROCPARAM2);

  -- Ouverture du curseur
  OPEN AREFCURSOR FOR
  select
  b.hrm_elements_id,
  b.hrm_elements_root_id,
  d.hrm_employee_id,
  d.hrm_salary_sheet_id,
  elr_root_code,
  erd_descr,
  related_code,
  his_pay_period,
  to_char(his_pay_period,'YYYYMM') period_yyyymm,
  his_pay_sum_val his_pay_sum_val_chf,
  hrm_itx.GET_PERS_CURR(d.hrm_employee_id,his_pay_period) currency,
  hrm_itx.GET_PERS_RATE(d.hrm_employee_id,his_pay_period) rate,
  round(his_pay_sum_val/hrm_itx.GET_PERS_RATE(d.hrm_employee_id,his_pay_period),2) his_pay_sum_val_dev
  from
  hrm_formulas_structure a,
  hrm_elements_root b,
  hrm_elements_root_descr c,
  hrm_history_detail d
  where
  a.related_id=b.hrm_elements_id
  and b.hrm_elements_root_id=c.hrm_elements_root_id
  and b.hrm_elements_id=d.hrm_elements_id
  and main_code in ('CemBasAVS','CemBasAVS2','CemBasAVS3','CemBasAVS4','CemBasAVSPa100')
  and related_code not in ('CemBasAVS','CemBasAVS2','CemBasAVS3','CemBasAVS4','CemBasAVSPa100')
  and related_code<>'ConEmAVS'
  and c.pc_lang_id=1;
  --and d.hrm_employee_id=EmpId
  --and to_char(his_pay_period,'YYYYMM') between vPeriodFrom and vPeriodTo
  --order by his_pay_period,elr_root_code;


 end ind_c9_avs_ctrl_sub;
