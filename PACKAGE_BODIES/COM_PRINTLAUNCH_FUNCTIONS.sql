--------------------------------------------------------
--  DDL for Package Body COM_PRINTLAUNCH_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRINTLAUNCH_FUNCTIONS" 
as

  /**
  * procedure getpackage
  * Description
  *    Récupère le nom du package à laquelle la procédure appartient
  */
  function getpackage(aproc in VARCHAR2) return VARCHAR2
  is
  begin
    for tplResult in (select PACKAGE_NAME from USER_ARGUMENTS where OBJECT_NAME = UPPER(aProc)) loop
      return tplResult.PACKAGE_NAME;
    end loop;
  return null;
  end getpackage;

end COM_PRINTLAUNCH_FUNCTIONS;
