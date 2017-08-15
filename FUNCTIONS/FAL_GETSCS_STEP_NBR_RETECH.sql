--------------------------------------------------------
--  DDL for Function FAL_GETSCS_STEP_NBR_RETECH
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "FAL_GETSCS_STEP_NBR_RETECH" (TaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE)
RETURN FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE IS

-- Cr�ation FD le 17/05/2001
-- Permet de retourner la s�quence d'une op�ration selon l'ID de l'op�ration
-- Cette fonction est utilis�e dans le module du brouillard d'avancement des op�rations pour le SQL*Loader
-- pour l'interfa�age avec le syst�me de RETECH

  Result FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE;
BEGIN
  SELECT SCS_STEP_NUMBER INTO Result
  FROM   FAL_TASK_LINK TASK_LINK
  WHERE  TO_NUMBER(SUBSTR(TASK_LINK.FAL_SCHEDULE_STEP_ID,-LEAST(LENGTH(TASK_LINK.FAL_SCHEDULE_STEP_ID),9),9)) = TaskID;

  RETURN Result;

  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END;
