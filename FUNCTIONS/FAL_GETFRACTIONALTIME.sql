--------------------------------------------------------
--  DDL for Function FAL_GETFRACTIONALTIME
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "FAL_GETFRACTIONALTIME" (TimeEntry VARCHAR2) RETURN FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%TYPE IS

-- Création FD le 23/10/2001
-- Permet de retourner une durée en heure et fraction d'heure suite à une entrée de type HH:MI
-- Cette fonction est utilisée dans le module du brouillard d'avancement des opérations pour le SQL*Loader
-- pour la société MECAPRO

  Result FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%TYPE;
  SeparatorPos Integer;
BEGIN

  SeparatorPos := INSTR(TimeEntry,':');

  if SeparatorPos <> 0 then
    Result := TO_NUMBER(SUBSTR(TimeEntry,1,SeparatorPos-1)) +
             (TO_NUMBER(SUBSTR(TimeEntry,SeparatorPos+1,LENGTH(TimeEntry) - SeparatorPos)) /60);
  else
    Result := NULL;
  end if;

  return Result;

  exception when OTHERS then return NULL;
END;
