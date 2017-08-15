--------------------------------------------------------
--  DDL for Procedure WEB_C9_ACTIVITY_BY_RECORD_PRNT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "WEB_C9_ACTIVITY_BY_RECORD_PRNT" (
  aRefCursor  IN OUT Crystal_Cursor_Types.DualCursorTyp,
  INITIALDATE IN VARCHAR2,
  USERINI     IN WEB_ACTIVITY.SAC_WHO%type,
  REPORTTYPE  IN VARCHAR2,
  RECORDID      IN VARCHAR2,
  ONLYME      IN VARCHAR2
   ) IS
/******************************************************************************
   NAME:       WEB_C9_ACTIVITY_BY_RECORD_Prnt
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        09/03/2005          1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     WEB_C9_ACTIVITY_RECORD_Prnt
      Sysdate:         09/03/2005
      Date and Time:   09/03/2005, 09:57:28, and 09/03/2005 09:57:28
      Username:         (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
  -- Sélection résultat.
  OPEN aRefCursor FOR

 SELECT SEM_ACTIVITY.SAC_DATE,
        SEM_ACTIVITY.SAC_WHO,
		SEM_ACTIVITY.SAC_TEXT,
		SEM_ACTIVITY.SAC_HOURS,
		SEM_ACTIVITY.SAC_TASK_CODE,
		SEM_ACTIVITY.SAC_PROJECT_ID
 FROM   WEB_ACTIVITY SEM_ACTIVITY
 WHERE
    sac_who like decode(ONLYME,'true',USERINI,'%')
	and	SEM_ACTIVITY.SAC_PROJECT_ID = to_number(recordid)
	and sac_date=to_date(INITIALDATE,'dd-mm-yy');

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END WEB_C9_ACTIVITY_BY_RECORD_Prnt;
