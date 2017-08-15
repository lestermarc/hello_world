--------------------------------------------------------
--  DDL for Procedure IND_C9_WEB_USER_LETTER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_WEB_USER_LETTER" (aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
 -- Procédure pour rapport Crystal HRM_AVS_CTRL
 is
 --vPeriodFrom varchar2(6);
 --vPeriodTo varchar2(6)

 begin
  --vPeriodFrom:=PROCPARAM0;
  --vPeriodTo:=PROCPARAM1;

  -- Ouverture du curseur
  OPEN AREFCURSOR FOR
  select
  w.WEB_USER_ID,
  w.WEU_LOGIN_NAME,
  w.WEU_PASSWORD_VALUE,
  w.WEU_FIRST_NAME,
  w.WEU_LAST_NAME,
  p.Per_mail_add_selected,
  w.WEU_EMAIL,
  w.WEU_CONFIRM_VALUE,
  w.WEU_LAST_LOGIN,
  w.WEU_DISABLED,
  w.WEU_PASSWORD_CHANGED,
  w.HRM_PERSON_ID,
  w.A_DATECRE,
  trunc(w.A_DATECRE) trunc_datecre,
  w.A_DATEMOD,
  w.A_IDCRE,
  w.A_IDMOD,
  w.PC_LANG_ID,
  (select lanid
   from pcs.pc_lang lan
   where lan.pc_lang_id=w.pc_lang_id) lanid,
  p.per_search_name,
  p.per_last_name,
  p.per_first_name,
  p.per_title,
  COM_DIC_FUNCTIONS.GETDICODESCR('DIC_PERSON_POLITNESS',p.per_title,w.pc_lang_id) politness,
  p.emp_number,
  p.emp_secondary_key,
  p.per_web_page,
  p.emp_marriage_place,
  HRM_ITX.get_last_pays_affect(p.hrm_person_id) DIC_SALARY_NUMBER_ID   -- MBA 2013.02.20
--  c.DIC_SALARY_NUMBER_ID
  from
  web_user w,
  hrm_person p
--  HRM_CONTRACT c
  where
  p.emp_status = 'ACT' and 
  w.hrm_person_id=p.hrm_person_id(+) --and 
--  c.hrm_employee_id=p.hrm_person_id
  order by DIC_SALARY_NUMBER_ID;

 end ind_c9_web_user_letter;
