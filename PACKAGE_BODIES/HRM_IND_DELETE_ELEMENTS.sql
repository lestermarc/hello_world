--------------------------------------------------------
--  DDL for Package Body HRM_IND_DELETE_ELEMENTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IND_DELETE_ELEMENTS" 
is

 procedure delete_elements
 -- Précdure se suppression automatique des GS.
 -- Lancement à la création des GS pour épuration de la base des GS
 -- En liaison avec pilotage
 is

  -- Curseur de contrôle: les éléments supprimés ne doivent pas se trouver dans une formule (exception faite des Bases)
  cursor CurCheck1 is
  select
  c.ele_stat_code||' '||c.ele_code element
  from
  hrm_elements_family a,
  ind_hrm_elements_delete b,
  hrm_elements c
  where
  a.hrm_elements_root_id=b.hrm_elements_root_id
  and a.hrm_elements_id=c.hrm_elements_id
  and b.suppress=1
  and a.HRM_ELEMENTS_PREFIXES_ID not in ('CUMCEM','OUTCUMCEM')
  and exists (select 1
  	   		from hrm_elements_family fam, ind_hrm_elements_delete del, hrm_elements_root root
 			where fam.hrm_elements_root_id=del.hrm_elements_root_id
 			and fam.hrm_elements_root_id=root.hrm_elements_root_id
 			and instr(fam.elf_expression,c.ele_code)>0
 			and del.suppress=0
 			and root.c_root_variant<>'Base')
  order by 1;

  --Curseur pour la mise à jour des formules de type BASE
  cursor CurUpdate is
    select a.hrm_elements_root_id,c.ele_code
	  from ind_hrM_elements_delete a,
	       hrm_elements_family b,
		   hrm_elements c
	 where nvl(a.suppress,0) = 1
	 and   a.hrm_elements_root_id = b.hrm_elements_root_id
	 and   b.hrm_elements_id = c.hrm_elements_id
	 and   b.elf_is_reference=1;


 Error1 varchar2(2000);

 begin

 Error1:='Eléments encore présents dans les formules';

 -- Contrôle
  for RowCheck1 in CurCheck1  loop
     Error1:=Error1||chr(10)||RowCheck1.element;
     end loop;

 if Error1<>'Eléments encore présents dans les formules'
 then raise_application_error(-20001,Error1);
 end if;

 -- Contrôle OK
/*
 -- Mise à jour des formules des bases

 for RowUpdate in CurUpdate loop
   update hrM_elements_family a  set elf_expression = replace(replace(replace(elf_expression,RowUpdate.ele_code,''),'++',''),'--','')
   where instr(elf_expression,RowUpdate.ele_code) > 0
   and   exists (
           select 1
    	   from hrm_elements_root b
    	   where a.hrM_elements_root_id = b.hrM_elements_root_id
    	   and   c_root_variant = 'Base'
  	       and   elf_is_reference=1);
   end loop;
*/
 -- Mise à jour des formules sur la table hrm_elements pour les éléments de type Base

 update hrm_elements a set ele_expression = (
      select elf_expression
      from hrm_elements_family b,
           hrm_elements_root   c
      where a.hrm_elements_id = b.hrm_elements_id
      and   b.hrm_elements_root_id = c.hrm_elements_root_id
      --and   c_root_variant = 'Base'
	  and   elf_is_reference=1)
 where exists (
      select 1
      from hrm_elements_family b,
           hrm_elements_root   c
      where a.hrm_elements_id = b.hrm_elements_id
      and   b.hrm_elements_root_id = c.hrm_elements_root_id
      --and   c_root_variant = 'Base'
	  and   elf_is_reference=1);


  --suppression de la table display
  delete
  from hrm_elements_root_display a
  where exists (
        select 1
		from ind_hrm_elements_delete b
		where a.hrM_elements_root_id = b.hrm_elements_root_id
		and   nvl(SUPPRESS,0) = 1);

  --suppression de la table root description
  delete
  from hrm_elements_root_descr a
  where exists (
        select 1
		from ind_hrm_elements_delete b
		where a.hrM_elements_root_id = b.hrm_elements_root_id
		and   nvl(SUPPRESS,0) = 1);

  --suppression de la table hrm_elements_descr
  delete
  from hrm_elements_descr  a
  where exists (
        select 1
		from ind_hrm_elements_delete b,
		     hrm_elements_family c
		where b.hrM_elements_root_id = c.hrm_elements_root_id
		and   a.hrm_elements_id = c.hrm_elements_id
		and   nvl(SUPPRESS,0) = 1);

  --suppression de la table hrm_elements
  delete
  from hrm_elements  a
  where exists (
        select 1
		from ind_hrm_elements_delete b,
		     hrm_elements_family c
		where b.hrM_elements_root_id = c.hrm_elements_root_id
		and   a.hrm_elements_id = c.hrm_elements_id
		and   nvl(SUPPRESS,0) = 1);


  --suppression de la table hrm_constants  descr
  delete
  from hrm_const_descr  a
  where exists (
        select 1
		from ind_hrm_elements_delete b,
		     hrm_elements_family c
		where b.hrM_elements_root_id = c.hrm_elements_root_id
		and   a.hrm_constants_id = c.hrm_elements_id
		and   nvl(SUPPRESS,0) = 1);

    --suppression de la table hrm_constants
  delete
  from hrm_constants  a
  where exists (
        select 1
		from ind_hrm_elements_delete b,
		     hrm_elements_family c
		where b.hrM_elements_root_id = c.hrm_elements_root_id
		and   a.hrm_constants_id = c.hrm_elements_id
		and   nvl(SUPPRESS,0) = 1);

  --suppression de la table hrm_elements_family
  delete
  from hrm_elements_family  a
  where exists (
        select 1
		from ind_hrm_elements_delete b
		where a.hrM_elements_root_id = b.hrm_elements_root_id
		and   nvl(SUPPRESS,0) = 1);


  --suppression de la table hrm_elements_root
  delete
  from hrm_elements_root  a
  where exists (
        select 1
		from ind_hrm_elements_delete b
		where a.hrM_elements_root_id = b.hrm_elements_root_id
		and   nvl(SUPPRESS,0) = 1);



 end delete_elements;

end hrm_ind_delete_elements;
