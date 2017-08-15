--------------------------------------------------------
--  DDL for Package Body WEB_HRM_EVAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_HRM_EVAL" AS
/******************************************************************************
   NAME:       WEB_HRM_EVAL
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        11.07.2005             1. Created this package body.

  function HrmEvalGoalCheck
   retourne 1 si c'est ok sinon 0 si une erreur a été rencontrée. dans ce cas le param errMsg contient l'erreur
******************************************************************************/

  FUNCTION HrmEvalGoalCheck(hrmEvalGoalId IN HRM_EVAL_GOAL.HRM_EVAL_GOAL_ID%TYPE, errMsg OUT VARCHAR2) RETURN NUMBER IS
    n NUMBER;
	goalType HRM_EVAL_GOAL.DIC_GOAL_TYPE_ID%TYPE;
	goalDateFrom  HRM_EVAL_GOAL.EVG_FROM%TYPE;
	goalDateTo    HRM_EVAL_GOAL.EVG_TO%TYPE;
  BEGIN

	SELECT DIC_GOAL_TYPE_ID,EVG_FROM, EVG_TO  INTO goalType,goalDateFrom,goalDateTo
    FROM HRM_EVAL_GOAL WHERE HRM_EVAL_GOAL_ID=hrmEvalGoalId;

	IF (goalType='SOC') THEN
	BEGIN
      SELECT COUNT(*) INTO n FROM HRM_EVAL_GOAL WHERE dic_goal_type_id='SOC' AND
	  ((goalDateFrom BETWEEN evg_from AND evg_to) OR (goalDateTo BETWEEN evg_from AND evg_to )) AND HRM_EVAL_GOAL_ID<>hrmEvalGoalId;

	  IF (n>=1) THEN
	  BEGIN

      errMsg := 'Ne définir qu''un seul objectif "Société" sur la période.';
      RETURN 2;
	  END;
	  END IF;
	  RETURN 0;

	END;
	END IF;

	RETURN 0;

	EXCEPTION WHEN NO_DATA_FOUND THEN
	BEGIN

	  errMsg := 'Objectif ('||hrmEvalGoalId||') non trouvé.';
	  RETURN 2;
	END;

  END;

END WEB_HRM_EVAL;
