--------------------------------------------------------
--  DDL for Package Body HRM_LIB_PERSON
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_LIB_PERSON" 
as
  /**
  * function GetPersonID
  * description :
  *    Recherche l'id de la personne en fonction de son numéro AVS.
  * @created rba 30.07.2014
  * @public
  * @return l'id de la personne
  */
  function GetPersonID(iNoAvs in hrm_person.EMP_SOCIAL_SECURITYNO2%type)
    return HRM_PERSON.HRM_PERSON_ID%type
  is
    ln_person_id hrm_person.hrm_person_id%type;
  begin
    select HRM_PERSON_ID
      into ln_person_id
      from HRM_PERSON
     where iNoAvs = EMP_SOCIAL_SECURITYNO2;

    return ln_person_id;
  exception
    when too_many_rows then
      raise_application_error(-20000, 'Several person found with avs number: ' || iNoAvs);
    when no_data_found then
      raise_application_error(-20000, 'Person with avs number ' || iNoAvs || ' not found');
  end GetPersonID;
end HRM_LIB_PERSON;
