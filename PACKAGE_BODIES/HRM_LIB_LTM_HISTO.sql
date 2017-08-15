--------------------------------------------------------
--  DDL for Package Body HRM_LIB_LTM_HISTO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_LIB_LTM_HISTO" 
/**
 * Package de gestion des historiques de modifications spécifiques HRM
 *
 * @version 1.0
 * @date 09/2010
 * @author spfister
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
AS

procedure PrepareDiffPerson(
  in_person_id IN hrm_person.hrm_person_id%TYPE,
  id_from IN TIMESTAMP default null,
  id_to IN TIMESTAMP default null,
  iv_user_name IN VARCHAR2 default null)
is
  ln_removed INTEGER;
begin
  ln_removed := ltm_histo_functions.removediff(in_person_id);
  ltm_histo_functions.GenerateDiff(in_person_id, id_from, id_to, iv_user_name);
end;

END HRM_LIB_LTM_HISTO;
