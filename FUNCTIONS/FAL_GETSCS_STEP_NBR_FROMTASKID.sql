--------------------------------------------------------
--  DDL for Function FAL_GETSCS_STEP_NBR_FROMTASKID
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "FAL_GETSCS_STEP_NBR_FROMTASKID" (TaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE)
RETURN FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE IS

-- Cr�ation FD le 26/09/2000
-- Permet de retourner la s�quence d'une op�ration selon l'ID de l'op�ration
-- Cette fonction est utilis�e dans le module du brouillard d'avancement des op�rations pour le SQL*Loader 

  Result FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE;
BEGIN
  SELECT SCS_STEP_NUMBER INTO Result
  FROM   FAL_TASK_LINK TASK_LINK
  WHERE  TASK_LINK.FAL_SCHEDULE_STEP_ID = TaskID;

  RETURN Result;

  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END;
