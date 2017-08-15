--------------------------------------------------------
--  DDL for Package Body HRM_IND_AVS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IND_AVS" 
is

 function nextConBeginEnd(EmpId number, BeginDate date, YearRef varchar2) return date
 /* retourne la date de début de contrat suivant moins 1
    si pas de contrat suivant, alors 31.12 de l'année de référence
    cela permet de ne pas exclure de décompte payé en- dehors des dates de contrat.
	   Exemple: contrat du 01.01.2006 au 31.03.2006
	                       01.07.2006 au 31.12.2006
				si un décompte complémentaire est payé en avril et qu'on se base uniquement sur les dates de contrat,
				les montants liés à ce décompte ne sortiront pas.
				Mais si on prend du 01.01.2006 au 30.06.2006 (01.07.2006 - 1), on récupère tous les décomptes.
 */
 is
  retour date;
 begin
  select min(con_begin-1) into retour
  from hrm_contract
  where hrm_employee_id=EmpId
  and con_begin > BeginDate;

  return nvl(retour,to_date('31.12.'||YearRef,'DD.MM.YYYY'));
 end nextConBeginEnd;

 function prevConBeginEnd(EmpId number, BeginDate date, YearRef varchar2) return date
 /* retourne la date de fin de contrat précédent plus 1
    si pas de contrat précédent, alors 01.01 de l'année de référence
    Attention: il ne faut pas qu'il y ait de croisement entre prevConBeginEnd et nextConBeginEnd
	           pour cela, on vérifie qu'il n'y ait pas de contrat antérieur
 */
 is
  ctrl number;
  retour date;
 begin

  -- contrôle qu'il n'y ait pas de date de contrat avant (dans la même année)
  select count(*) into ctrl
  from hrm_contract
  where hrm_employee_id=EmpId
  and con_begin < BeginDate
  and to_char(con_end,'YYYY')=YearRef
  ;

  -- si pas de contrat antérieur, alors début d'année, date de fin + 1
  if ctrl=0
  then retour:=to_date('01.01.'||YearRef,'DD.MM.YYYY');
  /*
  else select max(con_end)+1 into retour
       from hrm_contract
       where hrm_employee_id=EmpId
       and con_begin < BeginDate
       and to_char(con_end,'YYYY')=YearRef
       */
    else retour:=BeginDate
       ;
  end if;

  return retour;
 end prevConBeginEnd;

 procedure ind_generate_avs(PROCPARAM0 varchar2)
 -- Procédure de génération des données AVS
 is
 vPeriod varchar2(6);

 begin
  vPeriod:=PROCPARAM0;


  -- suppression des records existants
  delete from ind_hrm_avs
  where year=vPeriod;

  -- insert des nouvelle données
  insert into ind_hrm_avs
  select
  a.hrm_person_id,
  a.per_last_name,
  a.per_first_name,
  a.per_last_name||' '||a.per_first_name per_fullname,
  a.emp_number,
  a.per_birth_date,
  nvl(a.emp_social_securityno2,a.emp_social_securityno),
  b.ino_in,
  b.ino_out,
  c.con_begin,
  c.con_end,
  case
   when c.con_begin is null or c.con_begin < to_date('01.01.'||vPeriod,'DD.MM.YYYY')
   then to_date('01.01.'||vPeriod,'DD.MM.YYYY')
   else c.con_begin
  end avs_begin,
  case
   when c.con_end is null or c.con_end > to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   then to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   else c.con_end
  end avs_ens,
  c.dic_salary_number_id,
  com_dic_functions.getDicoDescr('DIC_SALARY_NUMBER',c.dic_salary_number_id,1) san_descr,
  nvl(hrm_functions.sumelem(a.hrm_person_id,'CemSoumAVSGlobal', hrm_ind_avs.prevConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod)
  													   ,case
   														 when hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod) > to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   														 then to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   														 else hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod)
  														 end),0) soum_avs,
   nvl(hrm_functions.sumelem(a.hrm_person_id,'CemSoumACGlobal', hrm_ind_avs.prevConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod)
  													  ,case
   														 when hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod) > to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   														 then to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   														 else hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod)
  														 end),0) soumac,
  vPeriod
  from
  hrm_person a,
  hrm_in_out b,
  hrm_contract c
  where
  a.hrm_person_id=b.hrm_employee_id (+)
  and b.hrm_in_out_id=c.hrm_in_out_id (+)
  and (c.con_begin<=to_date('31.12.'||vPeriod,'DD.MM.YYYY')
      or c.con_begin is null)
  and (c.con_end>=to_date('01.01.'||vPeriod,'DD.MM.YYYY')
      or c.con_end is null)
  and (b.ino_in<=to_date('31.12.'||vPeriod,'DD.MM.YYYY')
      or b.ino_in is null)
  and (b.ino_out>=to_date('01.01.'||vPeriod,'DD.MM.YYYY')
      or b.ino_out is null)
  and exists (select 1
  		   from hrm_history_detail his, hrm_elements ele
  		   where a.hrm_person_id=his.hrm_employee_id
		   and his.hrm_elements_id=ele.hrm_elements_id
  		   and to_char(his.his_pay_period,'YYYY')=vPeriod
		   and ele.ele_code='CemSoumAVS')
  order by emp_social_securityno;
 end ind_generate_avs;

 procedure ind_generate_certif(PROCPARAM0 varchar2)
 -- Procédure de génération des données AVS
 is
 vPeriod varchar2(6);

 begin
  vPeriod:=PROCPARAM0;


  -- suppression des records existants
  delete from ind_hrm_certif
  where year=vPeriod;

  -- insert des nouvelle données
  insert into ind_hrm_certif
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
   when c.con_begin is null or c.con_begin < to_date('01.01.'||vPeriod,'DD.MM.YYYY')
   then to_date('01.01.'||vPeriod,'DD.MM.YYYY')
   else c.con_begin
  end certif_begin,
  case
   when c.con_end is null or c.con_end > to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   then to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   else c.con_end
  end certif_end,
  c.dic_salary_number_id,
  com_dic_functions.getDicoDescr('DIC_SALARY_NUMBER',c.dic_salary_number_id,1) san_descr,
  /*(select replace(max(his_pay_value),'"','')
   from hrm_history_detail his, hrm_elements ele
   where his.hrm_elements_id=ele.hrm_elements_id
   and his.hrm_employee_id=a.hrm_person_id
   and ele.ele_code='DivColFunction'
   and his.his_pay_period in (select max(hit_pay_period)
   	   					  	 from hrm_history hit
							 where hit.hrm_employee_id=his.hrm_employee_id
							 and hit.hit_pay_period<nvl(c.con_end,to_date('31.12.4000','DD.MM.YYYY')))
   ) job_title,*/
  (select max(job_descr)
   from hrm_person_job pj, hrm_job job
   where a.hrm_person_id=pj.hrm_person_id
   and pj.hrm_job_id=job.hrm_job_id
   and pj.pej_from<=(case
                     when c.con_end is null or c.con_end > to_date('31.12.'||vPeriod,'DD.MM.YYYY')
                     then to_date('31.12.'||vPeriod,'DD.MM.YYYY')
                     else c.con_end
                    end) --certif_end
	and nvl(pj.pej_to,to_date('31.12.4000','DD.MM.YYYY'))>=(case
                                               when c.con_begin is null or c.con_begin < to_date('01.01.'||vPeriod,'DD.MM.YYYY')
                                               then to_date('01.01.'||vPeriod,'DD.MM.YYYY')
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
							 						  and hit2.hit_pay_period<nvl(c.con_end,to_date('31.12.4000','DD.MM.YYYY'))
												)
							 ) currency,
  hrm_itx.sumelemdevise(a.hrm_person_id,e.ele_code, hrm_ind_avs.prevConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod)
  													,case
   														 when hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod) > to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   														 then to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   														 else hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod)
  														 end) his_pay_sum_val,
  vPeriod year
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
		  and e1.hrm_control_list_id=(select hrm_control_list_id from hrm_control_list where col_name='Certificat de salaire')
   /*union all
   -- Elements du brut avec leur description
   select str.related_id,
		  str.related_code,
		  elr_root_code,
		  d2.erd_descr,
		  d2.pc_lang_id
		  from hrm_formulas_structure str, hrm_elements ele,hrm_elements_family f,hrm_elements_root r2,hrm_elements_root_descr d2
		  where str.related_id=ele.hrm_elements_id
		  and str.related_id=f.hrm_elements_id
          and f.hrm_elements_root_id=r2.hrm_elements_root_id
          and r2.hrm_elements_root_id=d2.hrm_elements_root_id
		  and main_code in ('CemSalBrut','CemSalBrut2','CemSalBrut3')
		  and related_code not in ('CemSalBrut','CemSalBrut2','CemSalBrut3')
	*/
	) e
  where
  a.hrm_person_id=b.hrm_employee_id
  and b.hrm_in_out_id=c.hrm_in_out_id
  and e.pc_lang_id=a.pc_lang_id
  and (c.con_begin<=to_date('31.12.'||vPeriod,'DD.MM.YYYY')
      or c.con_begin is null)
  and (c.con_end>=to_date('01.01.'||vPeriod,'DD.MM.YYYY')
      or c.con_end is null)
  and (b.ino_in<=to_date('31.12.'||vPeriod,'DD.MM.YYYY')
      or b.ino_in is null)
  and (b.ino_out>=to_date('01.01.'||vPeriod,'DD.MM.YYYY')
      or b.ino_out is null)
  and hrm_itx.sumelemdevise(a.hrm_person_id,e.ele_code, hrm_ind_avs.prevConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod)
  	  													,case
   														 when hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod) > to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   														 then to_date('31.12.'||vPeriod,'DD.MM.YYYY')
   														 else hrm_ind_avs.nextConBeginEnd(a.hrm_person_id,c.con_begin,vPeriod)
  														 end) <> 0;


 end ind_generate_certif;

end hrm_ind_avs;
