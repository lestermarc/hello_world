--------------------------------------------------------
--  DDL for Procedure IND_C9_CERTIF_NDF_PERIOD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_CERTIF_NDF_PERIOD" (PROCPARAM0 varchar2,PROCPARAM1 varchar2,PROCPARAM2 varchar2,aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
 -- Procédure de génération des données AVS
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
  a.hrm_person_id,
  a.per_last_name||' '||a.per_first_name per_fullname,
  a.emp_number,
  com_dic_functions.GETDICODESCR('DIC_PERSON_POLITNESS',a.per_title,a.pc_lang_id) per_title,
  case
   when a.per_mail_add_selector=0 then a.per_businessstreet
   when a.per_mail_add_selector=1 then a.per_homestreet
   when a.per_mail_add_selector=2 then a.per_otherstreet
   when a.per_mail_add_selector=3 then a.per_taxstreet
  end per_homestreet,
  case
   when a.per_mail_add_selector=0 then a.per_businesspostalcode
   when a.per_mail_add_selector=1 then a.per_homepostalcode
   when a.per_mail_add_selector=2 then a.per_otherpostalcode
   when a.per_mail_add_selector=3 then a.per_taxpostalcode
  end per_homepostalcode,
  case
   when a.per_mail_add_selector=0 then a.per_businesscity
   when a.per_mail_add_selector=1 then a.per_homecity
   when a.per_mail_add_selector=2 then a.per_othercity
   when a.per_mail_add_selector=3 then a.per_taxcity
  end per_homecity,
  case
   when a.per_mail_add_selector=0 then a.per_businesscountry
   when a.per_mail_add_selector=1 then a.per_homecountry
   when a.per_mail_add_selector=2 then a.per_othercountry
   when a.per_mail_add_selector=3 then a.per_taxcountry
  end per_homecountry,
  b.ino_in,
  b.ino_out,
  c.con_begin,
  c.con_end,
  case
   when c.con_begin is null or c.con_begin < last_day(to_date(vPeriodFrom,'YYYYMM'))
   then to_date(vPeriodFrom,'YYYYMM')
   else c.con_begin
  end certif_begin,
  case
   when c.con_end is null or c.con_end > to_date(vPeriodTo,'YYYYMM')
   then last_day(to_date(vPeriodTo,'YYYYMM'))
   else c.con_end
  end certif_end,
  c.dic_salary_number_id,
  com_dic_functions.getDicoDescr('DIC_SALARY_NUMBER',c.dic_salary_number_id,a.pc_lang_id) san_descr,
  (select max(job_descr)
   from hrm_person_job pj, hrm_job job
   where a.hrm_person_id=pj.hrm_person_id
   and pj.hrm_job_id=job.hrm_job_id
   and pj.pej_from<=(case
                     when c.con_end is null or c.con_end > to_date(vPeriodTo,'YYYYMM')
                     then last_day(to_date(vPeriodTo,'YYYYMM'))
                     else c.con_end
                    end) --certif_end
    and nvl(pj.pej_to,to_date('31.12.4000','DD.MM.YYYY'))>=(case
                                               when c.con_begin is null or c.con_begin < to_date(vPeriodFrom,'YYYYMM')
                                               then to_date(vPeriodFrom,'YYYYMM')
                                               else c.con_begin
                                              end) --certif_begin
   ) job_title,
  a.pc_lang_id,
  e.hrm_elements_id,
  e.elr_root_code,
  e.erd_descr,
  hrm_itx.get_pers_currYYYYMM(a.hrm_person_id,(select to_char(max(hit_pay_period),'YYYYMM')
                                                               from hrm_history hit2
                                                       where hit2.hrm_employee_id=a.hrm_person_id
                                                       and hit2.hit_pay_period<=nvl(last_day(to_date(vPeriodTo,'YYYYMM')),to_date('31.12.4000','DD.MM.YYYY'))
                                                )
                             ) currency,
  hrm_itx.sumelemdevise(a.hrm_person_id,e.ele_code, case
                                                     when c.con_begin is null or c.con_begin < last_day(to_date(vPeriodFrom,'YYYYMM'))
                                                     then to_date(vPeriodFrom,'YYYYMM')
                                                     else c.con_begin
                                                    end,
                                                    case
                                                      when hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,substr(vPeriodTo,1,4)) > last_day(to_date(vPeriodTo,'YYYYMM'))
                                                      then last_day(to_date(vPeriodTo,'YYYYMM'))
                                                      else hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,substr(vPeriodTo,1,4))
                                                     end) his_pay_sum_val,
  substr(vPeriodFrom,1,4) year,
  vPeriodFrom period_from,
  vPeriodTo period_to
  from
  hrm_person a,
  hrm_in_out b,
  hrm_contract c,
  (-- Eléments de la liste avec leur description: le lien se fait sur le Positionnement = code statistique
  select e1.hrm_control_elements_id hrm_elements_id,
            e1.coe_code ele_code,
          e1.coe_box elr_root_code,
          d1.erd_descr,
          d1.pc_lang_id
          from hrm_control_elements e1, hrm_elements_root r1, hrm_elements_root_descr d1
          where e1.coe_box=r1.elr_root_code(+)
          and r1.hrm_elements_root_id=d1.hrm_elements_root_id(+)
          and e1.hrm_control_list_id=(select hrm_control_list_id from hrm_control_list where col_name='Certificat d''avantages en nature')
    ) e
  where
  a.hrm_person_id=b.hrm_employee_id
  and b.hrm_in_out_id=c.hrm_in_out_id
  and e.pc_lang_id=a.pc_lang_id
  and (c.con_begin<=last_day(to_date(vPeriodTo,'YYYYMM'))
      or c.con_begin is null)
  and (c.con_end>=to_date(vPeriodFrom,'YYYYMM')
      or c.con_end is null)
  and (b.ino_in<=last_day(to_date(vPeriodTo,'YYYYMM'))
      or b.ino_in is null)
  and (b.ino_out>=to_date(vPeriodFrom,'YYYYMM')
      or b.ino_out is null)
  and hrm_itx.sumelemdevise(a.hrm_person_id,e.ele_code, case
                                                     when c.con_begin is null or c.con_begin < last_day(to_date(vPeriodFrom,'YYYYMM'))
                                                     then to_date(vPeriodFrom,'YYYYMM')
                                                     else c.con_begin
                                                    end,
                                                    case
                                                      when hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,substr(vPeriodTo,1,4)) > last_day(to_date(vPeriodTo,'YYYYMM'))
                                                      then last_day(to_date(vPeriodTo,'YYYYMM'))
                                                      else hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,substr(vPeriodTo,1,4))
                                                     end) <> 0
  and (per_search_name like upper(SearchName||'%')
      or SearchName is null);


 end ind_c9_certif_NDF_period;
