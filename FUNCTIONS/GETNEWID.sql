--------------------------------------------------------
--  DDL for Function GETNEWID
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "GETNEWID" 
  return number
is
  vId PCS.PC_COMP.PC_COMP_ID%type;
begin
  select INIT_ID_SEQ.nextval
    into vId
    from dual;

  return vId;
end getNewId;
