--------------------------------------------------------
--  DDL for Procedure IND_C9_CTRL_TAUX_BLOQUE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_CTRL_TAUX_BLOQUE" (PROCPARAM0 varchar2,PROCPARAM1 varchar2,aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
-- Procédure utilisée dans le rapport Crystal HRM_TAUX_BLOQUE
is
 vPeriod varchar2(6);
 SearchName varchar2(200);
begin
 vPeriod:=PROCPARAM0;
 SearchName:=PROCPARAM1;

 OPEN AREFCURSOR FOR
  select
  related_id,
  hrm_person_id,
  per_search_name,
  elr_root_code,
  erd_descr,
  his_pay_period,
  to_char(his_pay_period,'YYYYMM') period_yyyymm,
  his_pay_sum_val his_pay_sum_val_chf,
  hrm_itx.GET_PERS_CURR(d.hrm_employee_id,d.his_pay_period) currency,
  round(his_pay_sum_val/hrm_itx.GET_PERS_RATE(d.hrm_employee_id,d.his_pay_period),2) his_pay_sum_val_dev,
  'Base' gs
  from
  hrm_formulas_structure a,
  hrm_elements_root b,
  hrm_elements_root_descr c,
  hrm_history_detail d,
  hrm_person e
  where
  a.related_id=b.hrm_elements_id
  and b.hrm_elements_root_id=c.hrm_elements_root_id
  and b.hrm_elements_id=d.hrm_elements_id
  and d.hrm_employee_id=e.hrm_person_id
  and main_code in ('CemBasTauxBloqué','CemBasTauxBloqué2','CemBasTauxBloqué3','CemBasTauxBloqué4')
  and related_code not in ('CemBasTauxBloqué','CemBasTauxBloqué2','CemBasTauxBloqué3','CemBasTauxBloqué4')
  and c.pc_lang_id=1
  and to_char(his_pay_period,'YYYYMM')=vPeriod
  and (per_search_name like upper(SearchName||'%')
      or SearchName is null)
  UNION ALL
  select
  a.hrm_elements_id,
  hrm_person_id,
  per_search_name,
  elr_root_code,
  erd_descr,
  his_pay_period,
  to_char(his_pay_period,'YYYYMM') period_yyyymm,
  his_pay_sum_val his_pay_sum_val_chf,
  hrm_itx.GET_PERS_CURR(d.hrm_employee_id,d.his_pay_period) currency,
  round(his_pay_sum_val/hrm_itx.GET_PERS_RATE(d.hrm_employee_id,d.his_pay_period),2) his_pay_sum_val_dev,
  elr_root_name gs
  from
  hrm_elements a,
  hrm_elements_root b,
  hrm_elements_root_descr c,
  hrm_history_detail d,
  hrm_person e
  where
  a.hrm_elements_id=b.hrm_elements_id
  and b.hrm_elements_root_id=c.hrm_elements_root_id
  and b.hrm_elements_id=d.hrm_elements_id
  and d.hrm_employee_id=e.hrm_person_id
  and ele_code in ('CemBasTauxBloqué','DivEURTaux','DivUSDTaux','DivGBPTaux','DivJPYTaux','DivCNYTaux',
  'CemEURTauxBloqué','CemUSDTauxBloqué','CemGBPTauxBloqué','CemJPYTauxBloqué','CemCNYTauxBloqué',
  'CemBasDiffTauxBloqué','CemMontantPaye','CemMontantPayeAffich')
  and c.pc_lang_id=1
  and to_char(his_pay_period,'YYYYMM')=vPeriod
  and (per_search_name like upper(SearchName||'%')
      or SearchName is null);
end ind_c9_ctrl_taux_bloque;
