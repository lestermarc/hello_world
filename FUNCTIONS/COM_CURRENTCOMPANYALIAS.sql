--------------------------------------------------------
--  DDL for Function COM_CURRENTCOMPANYALIAS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "COM_CURRENTCOMPANYALIAS" (aDIC_PC_EXTERNAL_ALIAS_ID in pcs.DIC_PC_EXTERNAL_ALIAS.DIC_PC_EXTERNAL_ALIAS_ID%TYPE)
   return VARCHAR2
/**
 * Fonction com_currentCompanyAlias
 * @version 1.0
 * Sert à la retrouver le nom de l'alias de la société relative
 * au schéma actuellement connecté et au dictionnaire des alias externe
 * PCS.DIC_PC_EXTERNAL_ALIAS.
 */
is
  vCurrentSchema varchar2(2000);
  vCount  integer;
  vAlias  pcs.pc_comp_external_alias.EXT_ALIAS_NAME%TYPE;
begin
  -- utilisation d'une variable, car on a parfois des erreurs lorsque l'on
  -- utilise directement cette fonction COM_CURRENTSCHEMA dans une cmd sql
  vCurrentSchema  := upper(COM_CURRENTSCHEMA);

  SELECT COUNT (*) into vCount
    FROM pcs.pc_scrip
   WHERE SCRDBOWNER = vCurrentSchema;

  if vCount > 1 then
    Return 'Error : Duplicates in pcs.pc_scrip for schema ' || vCurrentSchema;
  end if;


  SELECT COUNT (*) into vCount
     FROM pcs.pc_comp, pcs.pc_scrip
  WHERE pc_comp.pc_scrip_id = pc_scrip.pc_scrip_id and SCRDBOWNER = vCurrentSchema;

  if vCount > 1 then
    Return 'Error : Duplicates in pcs.pc_comp for schema ' || vCurrentSchema;
  end if;

  begin
    SELECT EXT_ALIAS_NAME into vAlias
    FROM PCS.PC_COMP_EXTERNAL_ALIAS ALI, PCS.PC_COMP COM, PCS.PC_SCRIP SCR
    WHERE   SCR.SCRDBOWNER = vCurrentSchema
        AND SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID
        AND ALI.PC_COMP_ID = COM.PC_COMP_ID
        AND ALI.DIC_PC_EXTERNAL_ALIAS_ID = aDIC_PC_EXTERNAL_ALIAS_ID;

    Return vAlias;
  Exception
    when no_data_found then
        return 'Error : No alias found for schema ' || vCurrentSchema;
  end;
end;
