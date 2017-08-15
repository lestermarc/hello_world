--------------------------------------------------------
--  DDL for Function WFL_WHOAMI
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "WFL_WHOAMI" return varchar2
is
  cOwner varchar2(30);
  cName varchar2(30);
  nLineNum number;
  cType Varchar2(30);
begin
   WFL_WhoCalledMe(cOwner,cName,nLineNum,cType);
   Return cOwner || '.' || cName;
end;
