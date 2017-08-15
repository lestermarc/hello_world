--------------------------------------------------------
--  DDL for Package Body IND_PAC_REC_VALIDATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_PAC_REC_VALIDATION" is

 function cus_insert_doc_record(main_id in number, context in varchar2, message out varchar2) return number
 -- Création d'un dossier lors de la création d'un client
 is
  retour number;
  CusShortName pac_person.per_short_name%type;
  CusName pac_person.per_name%type;
  RecLinkId doc_record.pac_third_id%type;
  RecLinkTitle doc_record.rco_title%type;
  RcoIdExists doc_record.doc_record_id%type;

 begin
   -- Recherche des valeurs
   select max(per_short_name), max(per_name)
          into CusShortName, CusName
   from pac_custom_partner cus, pac_person pac
   where cus.pac_custom_partner_id=pac.pac_person_id and
   cus.pac_custom_partner_id=main_id;

   -- recherche si un dossier existe déjà - en fonction du nom
   select max(doc_record_id), max(pac_third_id)
          into RcoIdExists, RecLinkId
   from doc_record
   where rco_title=CusShortName;


    -- Si pas de dossier existant -> création
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
          CusShortName,
          CusName,
          sysdate,
          'AUTO'
          from dual;
          commit;

          message:='Un nouveau dossier "'||CusShortName||'" a été créé';
          retour:=pcs.pc_ctrl_validate.e_success;

      -- Si le dossier existe djà, mais qu'il n'y a pas de lien sur ce dossier -> mise à jour du lien
      elsif RecLinkId is null
       then

          update doc_record
          set PAC_THIRD_ID=main_id
          where doc_record_id=RcoIdExists;
          commit;

          message:='Un dossier "'||CusShortName||'" existe déjà. Le client crée a été rattaché à ce dossier';
          retour:=pcs.pc_ctrl_validate.e_success;

      -- S'il existe déjà un lien sur le dossier -> pas de lien et avertissement à l'utilisateur
      else
          message:='Un dossier "'||CusShortName||'" existe déjà. Ce dossier est rattaché à un autre client. Veuillez contrôler les liens entre le client et le dossier';
          retour:=pcs.pc_ctrl_validate.e_warning;

    end if;

 return retour;

 end cus_insert_doc_record;

 function cus_update_doc_record(main_id in number, context in varchar2, message out varchar2) return number
 -- Mise à jour d'un dossier lors de la mise à jour d'un client
 is
  retour number;
  CusShortName pac_person.per_short_name%type;
  CusName pac_person.per_name%type;
  RecLinkId doc_record.pac_third_id%type;
  RecLinkTitle doc_record.rco_title%type;
  RcoIdExists doc_record.doc_record_id%type;
  RcoTitle doc_record.rco_title%type;
  RcoDescr doc_record.rco_description%type;

 begin
   -- Recherche des valeurs
   select max(per_short_name), max(per_name)
          into CusShortName, CusName
   from pac_custom_partner cus, pac_person pac
   where cus.pac_custom_partner_id=pac.pac_person_id and
   cus.pac_custom_partner_id=main_id;

   -- recherche si un dossier existe déjà - en fonction de l'id (pac_third_id)
   select max(doc_record_id), max(rco_title), max(rco_description)
          into RcoIdExists, RcoTitle, RcoDescr
   from doc_record
   where pac_third_id=main_id;

    -- Si pas de dossier existant -> création
    if RcoIdExists is null
     then

          message:='Aucun lien avec un dossier pour le client "'||CusShortName||'"';
          retour:=pcs.pc_ctrl_validate.e_warning;

      -- Si le dossier existe déjà -> mise à jour du titre et description
      else
          -- quoi qu'il arrive, on met à jour le titre et le nom du dossier
          update doc_record
          set rco_title       = CusShortName,
              rco_description = CusName
          where doc_record_id=RcoIdExists;
          commit;

          -- gestion du message de retour
          if CusShortName = RcoTitle and CusName <> RcoDescr
          then
                message:='La description du dossier "'||RcoTitle||'" a été mise à jour';
                retour:=pcs.pc_ctrl_validate.e_success;

          elsif CusShortName <> RcoTitle
          then
                message:='Le titre du dossier à été changé ('||RcoTitle||' devient '||CusShortName||'). Veuillez contrôler la liaison des employés avec ce dossier; Il faut peut-être réaffecter les employés au nouveau dossier';
                retour:=pcs.pc_ctrl_validate.e_warning;
          else
                message:='';
                retour:=pcs.pc_ctrl_validate.e_success;
          end if;

    end if;

 return retour;

 end cus_update_doc_record;

end ind_pac_rec_validation;
