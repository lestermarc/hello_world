--------------------------------------------------------
--  DDL for Package Body IND_PAC_VALIDATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_PAC_VALIDATION" is

 function cus_mandatory_fields(main_id in number, context in varchar2, message out varchar2) return number
 -- teste les champs obligatoires (règles de gestion) lors de la saisie des clients
 is
  retour number;
  ValeurFG pac_custom_partner.CUS_FREE_ZONE4%type;
  TypeFG PAC_CUSTOM_PARTNER.DIC_STATISTIC_1_ID%type;
  CurrFG PAC_CUSTOM_PARTNER.DIC_STATISTIC_2_ID%type;
  ShortName pac_person.per_short_name%type;
  vCount integer;
 begin
   -- Recherche des valeurs
   select
   max(CUS_FREE_ZONE4), max(DIC_STATISTIC_1_ID),  max(DIC_STATISTIC_2_ID), max(per_short_name)
   into ValeurFG, TypeFG, CurrFG, ShortName
   from
   pac_custom_partner cus, pac_person pac
   where
   cus.pac_custom_partner_id=pac.pac_person_id and
   pac_custom_partner_id=main_id;

      -- recherche s'il existe déjà un client avec ce no (nom abrégé)
   select count(*) into vCount
   from pac_person
   where pac_person_id <> main_id
   and per_short_name=ShortName;

    -- No existe déjà
    if vCount > 0
     then message:='Le Nom abrégé "'||ShortName||'" est déjà utilisé dans la Gestion des adresses';
          retour:=pcs.pc_ctrl_validate.e_fatal;
    -- Type FG non renseigné
    elsif TypeFG is null
     then message:='Le champ "Type Frais de gestion" est obligatoire';
          retour:=pcs.pc_ctrl_validate.e_fatal;
     -- Valeur FG = numérique
    elsif ValeurFG not between '0' and '99999999999'
     then message:='Le champ "Valeur Frais de gestion" doit être de type numérique';
          retour:=pcs.pc_ctrl_validate.e_fatal;
    -- Si Pourcent -> valeur entre 0 et 100
    elsif TypeFG='Pourcent' and to_number(ValeurFG) not between 0 and 100
     then message:='Le champ "Valeur Frais de gestion" doit être compris entre 0 et 100';
          retour:=pcs.pc_ctrl_validate.e_fatal;
    -- Si Montant -> monnaie obligatoire
    elsif TypeFG='Montant' and CurrFG is null
     then message:='Le champ "Monnaie Frais de gestion" doit être renseigné';
          retour:=pcs.pc_ctrl_validate.e_fatal;
    else message:='';
         retour:=pcs.pc_ctrl_validate.e_success;
    end if;

 return retour;

 end cus_mandatory_fields;

 function create_doc_record(main_id in number, context in varchar2, message out varchar2) return number
 -- Création d'un dossier lors de la création d'un client
 is
  retour number;
  RcoTitle doc_record.rco_title%type;
  RcoDescr doc_record.rco_description%type;
  RcoIdExists doc_record.doc_record_id%type;
  vCount integer;
 begin
   -- Recherche des valeurs
   select max(per_short_name), max(per_name)
          into RcoTitle, RcoDescr
   from pac_custom_partner cus, pac_person pac
   where cus.pac_custom_partner_id=pac.pac_person_id and
   cus.pac_custom_partner_id=main_id;

   -- recherche si un dossier existe déjà
   select max(doc_record_id) into RcoIdExists
   from doc_record
   where rco_title=RcoTitle;

    -- Si pas de dossier existant -> création -> sinon mise à jour du lien
    if RcoIdExists is null
     then
          insert into doc_record (
          DOC_RECORD_ID,
          PAC_THIRD_ID,
          RCO_TITLE,
          RCO_DESCRIPTION,
          A_DATECRE,
          A_IDCRE)
          select
          init_id_seq.nextval,
          main_id,
          RcoTitle,
          RcoDescr,
          sysdate,
          'AUTO'
          from dual;
          commit;

          message:='Un nouveau dossier "'||RcoTitle||'" a été créé';
          retour:=pcs.pc_ctrl_validate.e_warning;
      else
          update doc_record
          set PAC_THIRD_ID=main_id
          where doc_record_id=RcoIdExists;
          commit;

          message:='Un dossier "'||RcoTitle||'" existe déjà. Le client crée a été rattaché à ce dossier';
          retour:=pcs.pc_ctrl_validate.e_warning;
    end if;

 return retour;

 end create_doc_record;

 function cus_group(main_id in number, context in varchar2, message out varchar2) return number
 -- contrôle si le client doit être membre d'un groupe (C_PARTNER_CATEGORY)
 is
  retour number;
  vShortName pac_person.per_short_name%type;
  vCateg pac_custom_partner.C_PARTNER_CATEGORY%type;
  vMsg varchar2(4000);
  vCount integer;
 begin
   -- Recherche des valeurs
   select
   max(per_short_name), max(C_PARTNER_CATEGORY)
   into vShortName, vCateg
   from
   pac_custom_partner cus, pac_person pac
   where
   cus.pac_custom_partner_id=pac.pac_person_id and
   pac_custom_partner_id=main_id;

   vCount:=0;

   if PCS.PC_INIT_SESSION.GETCOMPANYOWNER='C_ARKEMA'
   then
        -- recherche si 301 ou 308
     select count(*) into vCount
     from pac_custom_partner cus, pac_person pac
     where cus.pac_custom_partner_id=pac.pac_person_id
     and pac_person_id=main_id
     and (substr(per_short_name,1,3)='301'
          or
          substr(per_short_name,1,3)='308');

     vMsg:='Le client devrait être Membre de groupe (Catégorie partenaire = 3)';

   end if;


    -- No existe déjà
    if vCount > 0 and vCateg <> '3'
     then message:=vMsg;
          retour:=pcs.pc_ctrl_validate.e_warning;
    else message:='';
         retour:=pcs.pc_ctrl_validate.e_success;
    end if;

 return retour;

 end cus_group;

end ind_pac_validation;
