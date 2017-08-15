--------------------------------------------------------
--  DDL for Package Body IND_HRM_VALIDATION2
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_HRM_VALIDATION2" 
AS

function test_empl_break (main_id in number, context in varchar2, message out varchar2) return integer
   -- Contrôle que le dossier soit bien renseigné dans les Données de comptabilisation de l'employé
   -- Uniquement s'il existe un record dans hrm_employee_break
   is
    retour integer;
   begin
    select
    count(*) into retour
    from
    hrm_employee_break a
    where
    hrm_employee_id=main_id and
    heb_rco_title is null
    and exists (select 1
                from hrm_employee_break b
                where a.hrm_employee_id=b.hrm_employee_id);

    if retour > 0
    then message := 'Données de comptabilisation : Le dossier doit être renseigné';
         retour  :=  pcs.pc_ctrl_validate.e_fatal;
    else message := '';
         retour  :=  pcs.pc_ctrl_validate.e_success;
    end if;

    RETURN retour;

   end test_empl_break;

   END ind_hrm_validation2;
