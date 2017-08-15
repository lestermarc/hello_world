--------------------------------------------------------
--  DDL for Function COM_CURRENTCOMPID
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "COM_CURRENTCOMPID" return VARCHAR2 deterministic
/**
* function COM_CURRENTCOMPID
* Description
*   return the PC_COMP_ID of the PLSQL object owner
* @created fpe 28.04.2015
* @updated
* @public
* @return see decription
*/
is
  lResult PCS.PC_COMP.PC_COMP_ID%type;
begin
  select min(PC_COMP_ID)
    into lResult
    from PCS.PC_COMP COM, PCS.PC_SCRIP SCR
   where SCRDBOWNER = COM_CURRENTSCHEMA
     and COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID;
  return lResult;

  exception
    when NO_DATA_FOUND then return null;
end COM_CURRENTCOMPID;
