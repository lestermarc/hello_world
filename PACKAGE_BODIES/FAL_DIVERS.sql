--------------------------------------------------------
--  DDL for Package Body FAL_DIVERS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_DIVERS" 
is

    -------------------------------------------------------------------------------------
	-- Function crée à la demande de Roberto Polombo
	-- Elle renvoie l'atelier de l'opération suivante pointé par PrmFAL_SCHEDULE_STEP_ID
	-- Attention les opérations inactives et indépendantes ne sont pas prises en compte
	-- Paramètres entrant:
	--             PrmFAL_SCHEDULE_STEP_ID contient l'ID de l'opération
	--             PrmTakePrincipalOnly = 0 l'op suivante sera la prochaine op secondaire ou principale
	--                                  = 1 l'op suivante sera la prochaine op principale
    -- Valeur de retour: Id Atelier
    -------------------------------------------------------------------------------------
	function GetNextFFloorOfCurrentOp(PrmFAL_SCHEDULE_STEP_ID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE, prmTakePrincipalOnly NUMBER  default 0) RETURN FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%TYPE
	is

	 CurrentSCS_STEP_NUMBER FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE;
	 CurrentFAL_LOT_ID FAL_LOT.FAL_LOT_ID%TYPE;
	 aFAL_FACTORY_FLOOR_ID FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%TYPE;

	begin

	 -- Récupère les valeurs pertientes de l'op en cours
	 SELECT SCS_STEP_NUMBER, FAL_LOT_ID into CurrentSCS_STEP_NUMBER, CurrentFAL_LOT_ID
	  from FAL_TASK_LINK
	   Where FAL_SCHEDULE_STEP_ID = PrmFAL_SCHEDULE_STEP_ID;


	 -- récupère l'atelier de l'opération suivante
	 SELECT FAL_FACTORY_FLOOR_ID into aFAL_FACTORY_FLOOR_ID FROM FAL_TASK_LINK
	  WHERE  FAL_LOT_ID = CurrentFAL_LOT_ID
	         AND SCS_STEP_NUMBER = (SELECT MIN(SCS_STEP_NUMBER) from fal_task_link
								    where FAL_LOT_ID = CurrentFAL_LOT_ID
								      and scs_step_number > CurrentSCS_STEP_NUMBER
								      and C_OPERATION_TYPE in (1,2)
									  and
										 (
										  (prmTakePrincipalOnly=0)
										  or
										  (prmTakePrincipalOnly=1 AND C_OPERATION_TYPE = 1)
										 ));

	 RETURN aFAL_FACTORY_FLOOR_ID;

	 Exception
	  when no_data_found
	   then return NULL;
	end;

    -------------------------------------------------------------------------------------
	-- Function crée à la demande de Roberto Polombo
	-- Elle renvoie l'atelier de l'opération précédente pointé par PrmFAL_SCHEDULE_STEP_ID
	-- Attention les opérations inactives et indépendantes ne sont pas prises en compte
	-- Paramètres entrant:
	--             PrmFAL_SCHEDULE_STEP_ID contient l'ID de l'opération
	--             PrmTakePrincipalOnly = 0 l'op précédente sera la prochaine op secondaire ou principale
	--                                  = 1 l'op précédente sera la prochaine op principale
    -- Valeur de retour: Id Atelier
    -------------------------------------------------------------------------------------
	function GetPrevFFloorOfCurrentOp(PrmFAL_SCHEDULE_STEP_ID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE, prmTakePrincipalOnly NUMBER default 0) RETURN FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%TYPE
	is

	 CurrentSCS_STEP_NUMBER FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE;
	 CurrentFAL_LOT_ID FAL_LOT.FAL_LOT_ID%TYPE;
	 aFAL_FACTORY_FLOOR_ID FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%TYPE;

	begin

	 -- Récupère les valeurs pertientes de l'op en cours
	 SELECT SCS_STEP_NUMBER,FAL_LOT_ID into CurrentSCS_STEP_NUMBER, CurrentFAL_LOT_ID
	  from FAL_TASK_LINK
	   Where FAL_SCHEDULE_STEP_ID = PrmFAL_SCHEDULE_STEP_ID;


	 -- récupère l'atelier de l'opération précédente
	 SELECT FAL_FACTORY_FLOOR_ID into aFAL_FACTORY_FLOOR_ID FROM FAL_TASK_LINK
	  WHERE  FAL_LOT_ID = CurrentFAL_LOT_ID
	         AND SCS_STEP_NUMBER = (SELECT MAX(SCS_STEP_NUMBER) from fal_task_link
								    where FAL_LOT_ID = CurrentFAL_LOT_ID
								      and scs_step_number < CurrentSCS_STEP_NUMBER
								      and C_OPERATION_TYPE in (1,2)
									  and
										 (
										  (prmTakePrincipalOnly=0)
										  or
										  (prmTakePrincipalOnly=1 AND C_OPERATION_TYPE = 1)
										 ));



	 RETURN aFAL_FACTORY_FLOOR_ID;

	 Exception
	  when no_data_found
	   then return NULL;
	end;



END;
