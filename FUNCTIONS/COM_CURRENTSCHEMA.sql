--------------------------------------------------------
--  DDL for Function COM_CURRENTSCHEMA
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "COM_CURRENTSCHEMA" return VARCHAR2
/**
 * Fonction COM_CURRENTSCHEMA
 * @version 1.0
 * @date 05/2005
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Sert à la retrouver le nom du schéma actuellement connecté.
 *
 * Modifications:
 */
is
  vSchema varchar2(2000);
  vPart1 varchar2(2000);
  vPart2 varchar2(2000);
  vDblink varchar2(2000);
  vPart1_type varchar2(2000);
  vObjectNr number;
begin
  dbms_utility.name_resolve('COM_CURRENTSCHEMA', 1,
      vSchema, vPart1, vPart2, vDblink, vPart1_type, vObjectNr);
  return vSchema;

  exception
    when others then return '';
end;
