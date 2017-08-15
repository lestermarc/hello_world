--------------------------------------------------------
--  DDL for Package Body PAC_ITX
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_ITX" 
is

 function GetShortName(PersonId pac_person.pac_person_id%type) return varchar2
 -- Retourne le Nom abrégé de la personne
 is
  retour pac_person.per_short_name%type;
 begin
  select
  max(per_short_name) into retour
  from
  pac_person
  where
  pac_person_id=PersonId;

  return retour;

 end GetShortName;

 function GetCusLangId(PersonId pac_person.pac_person_id%type) return number
 -- retourne la langue (pc_lang_id) de la personne
 -- Langue de l'adresse de facturation (première si plusieurs)
 is
  retour pcs.pc_lang.pc_lang_id%type;
 begin
  select
  min(a.pc_lang_id) into retour
  from
  pac_address a,
  (select min(pac_address_id) pac_address_id, pac_person_id
   from pac_address
   where pac_person_id=PersonId
   and DIC_ADDRESS_TYPE_ID='Fac'
   group by pac_person_id) b
  where a.pac_address_id=b.pac_address_id;

  return nvl(retour,1);

 end GetCusLangId;

end pac_itx;
