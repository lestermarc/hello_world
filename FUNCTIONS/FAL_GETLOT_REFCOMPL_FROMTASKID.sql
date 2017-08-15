--------------------------------------------------------
--  DDL for Function FAL_GETLOT_REFCOMPL_FROMTASKID
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "FAL_GETLOT_REFCOMPL_FROMTASKID" (TaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE) RETURN VARCHAR2 IS

-- Création FD le 26/09/2000
-- Permet de retourner la référence complète d'un lot selon l'ID d'une opération
-- Cette fonction est utilisée dans le module du brouillard d'avancement des opérations pour le SQL*Loader

  Result FAL_LOT.LOT_REFCOMPL%TYPE;
BEGIN
  SELECT LOT_REFCOMPL INTO Result
  FROM   FAL_LOT LOT,FAL_TASK_LINK TASK_LINK
  WHERE  TASK_LINK.FAL_SCHEDULE_STEP_ID = TaskID
  AND    LOT.FAL_LOT_ID = TASK_LINK.FAL_LOT_ID;

  RETURN Result;

  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END;
