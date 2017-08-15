--------------------------------------------------------
--  DDL for Package Body HRM_IND_SPEC_ARKEMA
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IND_SPEC_ARKEMA" is

 function GetDivGroup1(EmpId number, Group1Id varchar2) return varchar2
 -- Retourne la division ppur un employé et un groupe de facturation donné
 is
  retour varchar2(30);
 begin
  select
  max(heb_div_number) into retour
  from IND_HRM_GROUP1_AFFECT
  where hrm_employee_id=EmpId
  and dic_group1_id=Group1Id;

 return retour;

 end GetDivGroup1;
 
 function GetDossierGroup1(EmpId number, Group1Id varchar2) return varchar2
 -- Retourne la division ppur un employé et un groupe de facturation donné
 is
  retour varchar2(30);
 begin
  select
  max(rco_title) into retour
  from IND_HRM_GROUP1_AFFECT
  where hrm_employee_id=EmpId
  and dic_group1_id=Group1Id;

 return retour;

 end GetDossierGroup1;

 procedure InitEmpDivGroup1
 -- Génère les lignes dans la table de correspondance employé - division - dictionnaire de regroupement
 is

 begin

  insert into ind_hrm_group1_affect (
  HRM_EMPLOYEE_ID,
  DIC_GROUP1_ID,
  HEB_DIV_NUMBER,
  A_DATECRE,
  A_IDCRE)
  select
  a.hrm_person_id,
  b.dic_group1_id,
  null,
  sysdate,
  'PROC'
  from
  hrm_person a,
  dic_group1 b
  where
  a.per_is_employee=1
  and not exists (select 1
  			   from ind_hrm_group1_affect c
  			   where a.hrm_person_id=c.hrm_employee_id
  			   and b.dic_group1_id=c.dic_group1_id);

 end InitEmpDivGroup1;

  procedure ComplEmpDivGroup1
 -- Complète les lignes dans la table de correspondance employé - division - dictionnaire de regroupement
 -- pour les employés Actifs dont les répartitions sont incomplètent
 is

  cursor CurNotExtist is
  -- Curseur retournant les employés dont les lignes ne sont pas créées
  select
  hrm_person_id hrm_employee_id,
  PER_LAST_NAME||' '||PER_FIRST_NAME PER_FULLNAME,
  EMP_NUMBER,
  emp_status,
  (select max(heb_div_number)
   from hrm_employee_break bre
   where bre.hrm_employee_id=a.hrm_person_id) heb_div_number,
  b.dic_group1_id
  from
  hrm_person a,
  dic_group1 b
  where
  a.emp_status in ('ACT','SUS')
  and not exists (select 1
                 from ind_hrm_group1_affect c
                 where a.hrm_person_id=c.hrm_employee_id
                 and b.dic_group1_id=c.dic_group1_id);

  cursor CurNull is
  -- Curseur retournant les employés dont les lignes existent mais avec la valeur NULL
  select
  hrm_person_id hrm_employee_id,
  PER_LAST_NAME||' '||PER_FIRST_NAME PER_FULLNAME,
  EMP_NUMBER,
  emp_status,
  (select max(heb_div_number)
   from hrm_employee_break bre
   where bre.hrm_employee_id=a.hrm_person_id) heb_div_number,
  b.dic_group1_id
  from
  hrm_person a,
  dic_group1 b
  where
  a.emp_status in ('ACT','SUS')
  and exists (select 1
             from ind_hrm_group1_affect d
             where a.hrm_person_id=d.hrm_employee_id
             and b.dic_group1_id=d.dic_group1_id
             and heb_div_number is null);

 begin
  -- PERMIERE BOUCLE: INSERT
  for RowNotExtist in CurNotExtist
  loop
   insert into ind_hrm_group1_affect (
   HRM_EMPLOYEE_ID,
   DIC_GROUP1_ID,
   HEB_DIV_NUMBER,
   A_DATECRE,
   A_IDCRE)
   values
   (RowNotExtist.hrm_employee_id,
   RowNotExtist.dic_group1_id,
   RowNotExtist.heb_div_number,
   sysdate,
   'PROC2');
  end loop;

  -- DEUXIEME BOUCLE: UPDATE
  for RowNull in CurNull
  loop
   update ind_hrm_group1_affect
   set HEB_DIV_NUMBER=RowNull.heb_div_number
   where
   hrm_employee_id=RowNull.hrm_employee_id
   and DIC_GROUP1_ID=RowNull.dic_group1_id;
  end loop;

 end ComplEmpDivGroup1;
 
end hrm_ind_spec_arkema;
