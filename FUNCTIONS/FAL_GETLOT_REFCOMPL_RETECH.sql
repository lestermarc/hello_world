--------------------------------------------------------
--  DDL for Function FAL_GETLOT_REFCOMPL_RETECH
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "FAL_GETLOT_REFCOMPL_RETECH" (TaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE) RETURN VARCHAR2 IS

-- Cr�ation FD le 17/05/2001
-- Permet de retourner la r�f�rence compl�te d'un lot selon l'ID d'une op�ration
-- Cette fonction est utilis�e dans le module du brouillard d'avancement des op�rations pour le SQL*Loader
-- pour l'interfa�age avec le syst�me de RETECH

  Result FAL_LOT.LOT_REFCOMPL%TYPE;
BEGIN
  SELECT LOT_REFCOMPL INTO Result
  FROM   FAL_TASK_LINK TASK_LINK, FAL_LOT LOT
  WHERE  TO_NUMBER(SUBSTR(TASK_LINK.FAL_SCHEDULE_STEP_ID,-LEAST(LENGTH(TASK_LINK.FAL_SCHEDULE_STEP_ID),9),9)) = TaskID
  AND    LOT.FAL_LOT_ID = TASK_LINK.FAL_LOT_ID;

  RETURN Result;

  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END;
