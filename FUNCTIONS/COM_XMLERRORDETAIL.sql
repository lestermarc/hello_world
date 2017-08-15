--------------------------------------------------------
--  DDL for Function COM_XMLERRORDETAIL
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "COM_XMLERRORDETAIL" (Error IN VARCHAR2) return XMLType
/**
 * OBSOLETE utiliser le public synonyme XmlErrorDetail
*/
IS
begin
  return XmlErrorDetail(iError => Error);
end;
