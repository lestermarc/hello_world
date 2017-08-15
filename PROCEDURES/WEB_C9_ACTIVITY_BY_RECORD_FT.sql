--------------------------------------------------------
--  DDL for Procedure WEB_C9_ACTIVITY_BY_RECORD_FT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "WEB_C9_ACTIVITY_BY_RECORD_FT" (
  aRefCursor  IN OUT Crystal_Cursor_Types.DualCursorTyp,
  INITIALDATE IN VARCHAR2,
  USERINI     IN WEB_ACTIVITY.SAC_WHO%TYPE,
  REPORTTYPE  IN VARCHAR2,
  RECORDID    IN VARCHAR2,
  ONLYME      IN VARCHAR2,
  FROMDATE    IN VARCHAR2
   ) IS
/******************************************************************************
   NAME:       WEB_C9_ACTIVITY_BY_RECORD_Prnt
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   			  23/02/2007  RRI			   Correction pour que ça fonctionne même si pas de message client à afficher
   			  06/12/2006  RRI			   Correction pour que ça fonctionne même si pas de message client à afficher
          17/11/2006  RRI              Remis le message supprimer par PYB
   			  01/11/2006  RRI 			   Ajout message client
          17/03/2006  RRI			   Add new param FROMDATE
   1.0    09/03/2005          1. Created this procedure.

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

  SELECT
    SEM_ACTIVITY.SAC_DATE,
    SEM_ACTIVITY.SAC_WHO,
 		SEM_ACTIVITY.SAC_TEXT,
 		SEM_ACTIVITY.SAC_HOURS,
 		SEM_ACTIVITY.SAC_HOURS_BILLED,
 		SEM_ACTIVITY.SAC_TASK_CODE,
 		SEM_ACTIVITY.SAC_PROJECT_ID,
 		SEM_ACTIVITY.SAC_CUST_MACHINE,
 		RCO.RCO_TITLE,
		SEM_ACTIVITY.sac_quick_op,
 		SEM_ACTIVITY.SAC_BILL_TYPE,
 		FROMDATE,
 		INITIALDATE,
 		(SELECT
		   wmt_message message
 		 FROM
		   WEB_MESSAGE_TRANSL t,
		   WEB_MESSAGE m,
		   DOC_RECORD r,
		   PAC_ADDRESS a
 		 WHERE
		   r.doc_record_id=TO_NUMBER(recordid)
		   AND r.PAC_THIRD_ID=a.pac_person_id
		   AND ADD_PRINCIPAL=1
		   AND m.web_message_id(+)=t.web_message_id
		   AND m.CME_MSG_TXT='MESSAGE RAPPORT CLIENT'
		   AND ROWNUM=1
		   AND t.pc_lang_id=a.pc_lang_id) MESSAGE
     FROM
	   WEB_ACTIVITY SEM_ACTIVITY,
  	   DOC_RECORD RCO
  WHERE
    sac_who LIKE DECODE(ONLYME,'true',USERINI,'%')
 	AND	SEM_ACTIVITY.SAC_PROJECT_ID = TO_NUMBER(recordid)
	AND SEM_ACTIVITY.SAC_PROJECT_ID = RCO.DOC_RECORD_ID
 	AND sac_date BETWEEN TO_DATE(INITIALDATE,'dd-mm-yy') AND TO_DATE(FROMDATE,'dd-mm-yy');

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END Web_C9_Activity_By_Record_Ft;
