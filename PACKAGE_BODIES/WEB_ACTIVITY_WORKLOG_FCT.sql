--------------------------------------------------------
--  DDL for Package Body WEB_ACTIVITY_WORKLOG_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_ACTIVITY_WORKLOG_FCT" IS

 /**
 * return 3 : ok, 2:warning, 1:error, 0:technical error
 *
 * Exemple d'appel :
     declare
      n integer;
      msg varchar2(200);
    begin
      n:=web_Activity_worklog_fct.STOPWEBACTIVITYWORKLOG(60039209790,'2008-03-20 16:14:00.00 Europe/Berlin',1,msg);
      dbms_output.put_line('n');
      dbms_output.put_line(msg);
    end;
 */
  FUNCTION stopWebActivityWorkLog(webActivityWorkLogId WEB_ACTIVITY_WORKLOG.WEB_ACTIVITY_WORKLOG_ID%TYPE,
      								wawEnd VARCHAR2,
									cWebActivityWorklogState WEB_ACTIVITY_WORKLOG.C_WEB_ACTIVITY_WORKLOG_STATE%TYPE,
                                    errMsg OUT VARCHAR2) RETURN NUMBER IS
    vWebUserId WEB_USER.WEB_USER_ID%TYPE;
	vWebUser   WEB_USER.WEU_FIRST_NAME%TYPE;
	caseError VARCHAR2(200);

	vDicRecord1Id    DIC_RECORD1.DIC_RECORD1_ID%TYPE;
	vDicDepartmentId DIC_RECORD1.DIC_RECORD1_ID%TYPE;
	vSacWho      WEB_ACTIVITY.SAC_WHO%TYPE;
	vControlDate WEB_ACTIVITY.SAC_DATE%TYPE;
	vProjectId   WEB_ACTIVITY.SAC_PROJECT_ID%TYPE;
	vTaskCode    WEB_ACTIVITY.SAC_TASK_CODE%TYPE;
    vInterval    WEB_ACTIVITY.SAC_HOURS%TYPE;
	webUserId    WEB_ACTIVITY_WORKLOG.WEB_USER_ID%TYPE;

	vReturnMsg    VARCHAR2(200);
	vReturnCode   NUMBER;
	vSql_code     VARCHAR2(4000);
	timeCoherence VARCHAR2(10);
  BEGIN

	  vSql_code  :=
          'UPDATE WEB_ACTIVITY_WORKLOG SET (WAW_END, C_WEB_ACTIVITY_WORKLOG_STATE)=(SELECT TIMESTAMP '''||wawEnd||''','''||cWebActivityWorklogState||''' FROM dual) WHERE '||
          ' WEB_ACTIVITY_WORKLOG_ID= :ID';

    EXECUTE IMMEDIATE vSql_code USING IN webActivityWorkLogId;


	--Check if endTime < startTime

	SELECT DECODE( SIGN((EXTRACT(DAY FROM (waw_end-waw_start))*24*60+
	                     EXTRACT(HOUR FROM (waw_end-waw_start))*60+
		                 EXTRACT(MINUTE FROM (waw_end-waw_start)))/60),1,'true','false' ) INTO timeCoherence
    FROM
	  WEB_ACTIVITY_WORKLOG
	WHERE
	  WEB_ACTIVITY_WORKLOG_ID=webActivityWorkLogId;

	IF (timeCoherence='false') THEN
	  BEGIN
	  	errMsg:='End time cannot be smaller than start time... Please correct.';
	    vReturnCode:=1;
	    ROLLBACK;
	  RETURN vReturnCode;
	  END;
	END IF;

	SELECT
	  web_user_id,
	  sac_project_id,
	  sac_task_code INTO webUserId,vProjectId,vTaskCode
	FROM
	  WEB_ACTIVITY_WORKLOG
	WHERE
	  web_activity_worklog_id=webActivityWorkLogId;

	SELECT
	  WEU_LOGIN_NAME INTO vWebUser
	FROM
	  WEB_USER
	WHERE
	  WEB_USER_ID=webUserId;


	SELECT
	  Web_Functions.getWebUserData(vWebUser,'USER_INI') INTO vSacWho
	FROM
	  DUAL;


	SELECT
	  TO_DATE(TO_CHAR(waw_start,'dd.mm.yyyy'),'dd.mm.yyyy') INTO vControlDate
	FROM
	  WEB_ACTIVITY_WORKLOG
	WHERE
	  web_activity_worklog_id=webActivityWorkLogId;

	SELECT
	  SUM(sac_hours) INTO vInterval
	FROM
	  WEB_ACTIVITY
	WHERE
	  sac_who=vSacWho
      AND sac_Date=vControlDate
	  AND C_WEB_ACTIVITY_STATE='1';

	SELECT
	  NVL(vInterval,0) INTO vInterval
	FROM
	  dual;

	SELECT vInterval+(EXTRACT(DAY FROM (waw_end-waw_start))*24*60+
                     EXTRACT(HOUR FROM (waw_end-waw_start))*60+
	                 EXTRACT(MINUTE FROM (waw_end-waw_start)))/60 INTO vInterval
    FROM WEB_ACTIVITY_WORKLOG
	WHERE
	  web_activity_worklog_id=webActivityWorkLogId;


	vReturnMsg:='ok';
	vReturnCode:=3;

   IF ( (vInterval>8) AND (vInterval<=12))
	   THEN
	   BEGIN
	    vReturnMsg:='work time exceeded '||vInterval||'h vs 8h/day or 12h with overtime.';
	    vReturnCode:=2;
	   END;
	ELSIF (vInterval>12)
	   THEN
	   BEGIN
	    vReturnMsg:='work time exceeded '||vInterval||'h vs 8h/day. End time should not be after hh.mm';
	    vReturnCode:=1;
	   END;

	 END IF;

	IF ((vReturnCode=2)OR(vReturnCode=3))
	THEN
	BEGIN
      generateWebActivity( webActivityWorkLogId, vSacWho);
    END;

	END IF;

	errMsg := vReturnMsg;
	RETURN vReturnCode;


  END;


PROCEDURE generateWebActivity(webActivityWorkLogId WEB_ACTIVITY_WORKLOG.WEB_ACTIVITY_WORKLOG_ID%TYPE,
                              pSacWho WEB_ACTIVITY.SAC_WHO%TYPE) IS

  isWebActivityExist NUMBER(1);
  projectId     WEB_ACTIVITY.SAC_PROJECT_ID%TYPE;
  taskCode      WEB_ACTIVITY.SAC_TASK_CODE%TYPE;
  sacDate       WEB_ACTIVITY.SAC_DATE%TYPE;
  sacHours      WEB_ACTIVITY.SAC_HOURS%TYPE;
  webActivityId WEB_ACTIVITY.WEB_ACTIVITY_ID%TYPE;
  vSacText      WEB_ACTIVITY.SAC_TEXT%type;
  vNewWebActivityId WEB_ACTIVITY.WEB_ACTIVITY_ID%type;
BEGIN
    SELECT
	   TO_DATE(TO_CHAR(waw_start,'yyyymmdd'),'yyyymmdd'),
	   SAC_PROJECT_ID,
	   SAC_TASK_CODE,
	   (EXTRACT(DAY FROM (waw_end-waw_start))*24*60+
		 EXTRACT(HOUR FROM (waw_end-waw_start))*60+
		 EXTRACT(MINUTE FROM (waw_end-waw_start)))/60,
		 web_activity_id
	   INTO
         sacDate,
         projectId,
         taskcode,
         sacHours,
         webActivityId
	 FROM
	   WEB_ACTIVITY_WORKLOG
	 WHERE
       web_activity_worklog_id=webActivityWorkLogId;

	IF (webActivityId IS NULL) THEN
	BEGIN

	SELECT
	  COUNT(*) INTO isWebActivityExist
	FROM
	  WEB_ACTIVITY A,
      WEB_ACTIVITY_WORKLOG W
	WHERE
	  a.sac_date=sacDate
	  AND a.sac_who=pSacWho
	  AND a.sac_project_id=projectId
	  --AND sac_text='summary'
      AND W.WEB_ACTIVITY_ID=A.WEB_ACTIVITY_ID
	  AND a.sac_task_code=taskcode;

	IF (isWebActivityExist=0) THEN --then create
	BEGIN

    select init_id_seq.NEXTVAL into vNewWebActivityId from dual;

    select
      sac_comment into vSacText
    from
      web_activity_worklog
    where
      web_activity_worklog_id=webActivityWorkLogId;

	INSERT INTO WEB_ACTIVITY (
      WEB_ACTIVITY_ID,
      SAC_DATE,
      SAC_WHO,
      SAC_TASK_CODE,
      SAC_PROJECT_ID,
	  SAC_HOURS,
      SAC_TEXT,
      SAC_HOURS_BILLED,
      SAC_BILL_TYPE,
      C_WEB_ACTIVITY_STATE,
      A_DATECRE,
      A_DATEMOD,
	  A_IDCRE,
      A_IDMOD,
      NEW_DOC_RECORD_ID,
      NEW_PAC_CUSTOM_PARTNER_ID,
      NEW_PRICE,
      NEW_SAC_BILL_TYPE,
	  SAC_CUST_MACHINE,
      DIC_SEM_FREE_MOTIV_ID,
      SAC_QUICK_OP )
	VALUES (vNewWebActivityId,
		    sacDate,
			pSacWho,
			taskCode,
			projectId,
			sacHours,
			vSacText,
			0,
			'H',
			'1',
			SYSDATE, NULL, pSacWho, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0);

    UPDATE
	  WEB_ACTIVITY_WORKLOG
	 SET
	   WEB_ACTIVITY_ID=vNewWebActivityId
	 WHERE
	   web_activity_worklog_id=webActivityWorkLogId;


	END;
    ELSE
	BEGIN --update on ajoute

    SELECT
	    max(a.web_activity_id) INTO webActivityId
    FROM
	  WEB_ACTIVITY A,
      WEB_ACTIVITY_WORKLOG W
	WHERE
	  a.sac_date=sacDate
	  AND a.sac_who=pSacWho
	  AND a.sac_project_id=projectId
	  --AND sac_text='summary'
      AND W.WEB_ACTIVITY_ID=A.WEB_ACTIVITY_ID
	  AND a.sac_task_code=taskcode;
/*
FROM
	    WEB_ACTIVITY
	  WHERE
  	    sac_date=sacDate
		AND sac_who=pSacWho
		AND sac_project_id=projectId
		AND sac_text='summary'
		AND sac_task_code=taskcode;*/

     vSacText := buildCommentFromWorklog(webActivityWorkLogId,webActivityId);

	 UPDATE
	   WEB_ACTIVITY
	  SET
	    (sac_hours,sac_text) = (SELECT sac_hours+sacHours,vSacText FROM dual)
	  WHERE
	    web_activity_id=webActivityId;

     UPDATE
	   WEB_ACTIVITY_WORKLOG
	 SET
	   WEB_ACTIVITY_ID=webActivityId
	 WHERE
	   web_activity_worklog_id=webActivityWorkLogId;


	END;

	END IF;

  END; --on traite uniquement si web_activity_id is null
  END IF;
 END;

 /**
 *  procédure utilisée pour fermer automatiquement les worklogs
 *  en pratique exécutée depuis le job.
 *
 */
 PROCEDURE findAndCloseTimeOutWorkLog IS
 BEGIN
  UPDATE WEB_ACTIVITY_WORKLOG wl
    SET (WAW_END, C_web_activity_worklog_state) =
    (SELECT
	  (
	    /*(
		  CASE WHEN
	       ( SELECT D.DIC_DEPARTMENT_ID
		     FROM HRM_DIVISION D, HRM_PERSON P, WEB_USER W
			 WHERE
			   W.WEB_USER_ID=WL.WEB_USER_ID
			   AND W.HRM_PERSON_ID=P.HRM_PERSON_ID
			   AND p.HRM_DIVISION_ID=D.HRM_DIVISION_ID
			) ='DIR' THEN 12
 	        ELSE 8
          END
		)*/
		8-
		( SELECT
		    NVL(SUM(sac_hours),0)
		  FROM
		    WEB_ACTIVITY
		  WHERE
		    SAC_DATE=TO_DATE(EXTRACT(YEAR FROM WAW_START)||EXTRACT(MONTH FROM WAW_START)||EXTRACT(DAY FROM WAW_START),'YYYYMMDD')
    		AND SAC_WHO=Web_Functions.getWebUserData( (SELECT WEU_LOGIN_NAME FROM WEB_USER w WHERE w.web_user_id=wl.web_user_id), 'USER_INI')))/24+waw_start
	,2 state
	FROM
	  dual)
	WHERE C_WEB_ACTIVITY_WORKLOG_STATE ='0';
 END;


  /**
  * return 3 : ok, 2:warning, 1:error, 0:technical error
  *
  * si type = hsup, errMsg renvoie true ou false en fonction si la colonne Heures sup doivent être montrées
   */
 FUNCTION checkActivityByDate( dateToCheck DATE,
  		   					   checkType VARCHAR2,
							   userIni VARCHAR2,
                               errMsg OUT VARCHAR2) RETURN NUMBER
  IS
    workPlace         HRM_PERSON.DIC_WORKPLACE_ID%TYPE;
	maxHours          NUMBER;
	autorizedMaxHours NUMBER;
	totHours          NUMBER;
	totHSup           NUMBER;
	a                 NUMBER;
	solde             NUMBER;
	soldeVA           VARCHAR2(500);
	newEndTime        WEB_ACTIVITY_WORKLOG.WAW_END%TYPE;
	compId 			  pcs.pc_comp.pc_comp_id%TYPE;
	configValue		  pcs.pc_cbase.CBACVALUE%TYPE;
	sqlToCheck        VARCHAR2(4000);
	returnErr         VARCHAR2(4000);
	returnCode		  NUMBER;
  BEGIN

  SELECT
    pc_comp_id INTO compId
  FROM
    pcs.pc_comp c, pcs.pc_scrip s
  WHERE
    s.pc_scrip_id=c.pc_scrip_id
	AND ROWNUM=1
	AND s.SCRDBOWNER=USER;

  pcs.PC_I_LIB_SESSION.SetCompanyId(compId);

  configValue := pcs.pc_config.GetConfig('WEB_ACTIVITY_PKG_NAME');
  IF (configValue IS NOT NULL) THEN
  BEGIN
    sqlToCheck:='DECLARE errMsg varchar2(4000); returnCode number(2); '||
	            'BEGIN returnCode:='||configValue||'.checkActivityByDate(:date,:checktype,:userini, errMsg); :returnErr:=errMsg; :returnCode:=returnCode; END;';
    EXECUTE IMMEDIATE sqlToCheck USING dateToCheck,checkType,userIni,OUT returnErr,OUT returnCode;

    errMsg := returnErr;
	RETURN  returnCode;
  END;
  END IF;

  IF (checkType='hsup') THEN
    BEGIN
      SELECT SUM(sac_hours) INTO a FROM WEB_ACTIVITY WHERE sac_who=userIni AND sac_date=dateToCheck;
      errMsg := 'false';
      IF (a>8) THEN
	    errMsg:='true';
	  END IF;
      RETURN 3;
    END;
  END IF;

  SELECT
	SUM(sac_hours),SUM(sac_hours_billed) INTO totHours, totHSup
  FROM
	WEB_ACTIVITY
  WHERE
	sac_who = userIni
	AND sac_date = dateToCheck;

  --Recherche du maximum
	autorizedMaxHours:=8;
	maxHours:=12;

	IF (totHours>maxHours) THEN
	BEGIN
	solde := (totHours-maxHours)/60;
	soldeVA := LPAD(REPLACE(Web_Activity_Worklog_Fct.getHoursMinutesFromNumber(solde),'h',':'),5,'0');

	  errMsg :='Maximun hours per day is '||getHoursMinutesFromNumber(maxHours)||'. Total input is '||getHoursMinutesFromNumber(totHours)||'. You have to reduce worktime :'||soldeVA||'.';
	  RETURN 1;
	END;
	ELSIF (totHours>autorizedMaxHours) THEN
	BEGIN
	  errMsg :='Maximum hours per day is '||getHoursMinutesFromNumber(autorizedMaxHours)||'. Total input is '||getHoursMinutesFromNumber(totHours)||' with '||getHoursMinutesFromNumber(totHSup)||' overtime.';
	  solde := totHours-totHSup-autorizedMaxHours;
	  IF (solde>0) THEN
	    errMsg := errMsg||' Specify  '|| getHoursMinutesFromNumber(solde) ||' overtime more.';
	  END IF;
	  RETURN 2;
	END;
	END IF;

    RETURN 3;
  END;

  FUNCTION getHoursMinutesFromNumber(num NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN FLOOR(num)||'h'|| LPAD( FLOOR((num-FLOOR(num))*60),2,'0');
  END;

  /**
  * return 3 : ok, 2:warning, 1:error, 0:technical error
  */
  FUNCTION validateWebActivity(concatenedIds VARCHAR2,errMsg OUT VARCHAR2) RETURN NUMBER IS
  vSql_code VARCHAR2(2000);
  BEGIN
   vSql_code  := 'update web_activity set (c_web_activity_state,a_datemod, a_idmod) = (select 3,sysdate,''MAIL'' from dual) where web_activity_id in ('||concatenedIds||')';
  EXECUTE IMMEDIATE vSql_code;
   errMsg := 'Accepted inputs saved.';
  RETURN 3;
  EXCEPTION WHEN OTHERS THEN
    BEGIN
    errMsg := 'Exception during update with ids : '||concatenedIds;
    RETURN 1;
	END;

  END;

  /**
  * return 3 : ok, 2:warning, 1:error, 0:technical error
  */
  FUNCTION refuseWebActivity(concatenedIds VARCHAR2,errMsg OUT VARCHAR2) RETURN NUMBER IS
  vSql_code VARCHAR2(2000);
  BEGIN
   vSql_code  := 'update web_activity set (c_web_activity_state,a_datemod, a_idmod) = (select 4,sysdate,''MAIL'' from dual) where web_activity_id in ('||concatenedIds||')';
  EXECUTE IMMEDIATE vSql_code;
   errMsg := 'Refused input saved.';
  RETURN 3;
  EXCEPTION WHEN OTHERS THEN
    BEGIN
    errMsg := 'Exception during update with ids : '||concatenedIds;
    RETURN 1;
	END;

  END;

  FUNCTION cancelWebActivityWorkLog(webActivityWorkLogId WEB_ACTIVITY_WORKLOG.WEB_ACTIVITY_WORKLOG_ID%TYPE,
                                  errMsg OUT VARCHAR2) RETURN NUMBER IS
	vSql_code VARCHAR2(4000);
  BEGIN
	vSql_code  := 'DELETE WEB_ACTIVITY_WORKLOG WHERE WEB_ACTIVITY_WORKLOG_ID= :ID';

    EXECUTE IMMEDIATE vSql_code USING IN webActivityWorkLogId;

	RETURN 3;

  END;

  FUNCTION showSacHoursBilled(webActivityId IN WEB_ACTIVITY.WEB_ACTIVITY_ID%TYPE) RETURN varchar2 IS
    vResult varchar2(3) := '';
  BEGIN
    SELECT
      count(*) into vResult
    FROM
      WEB_ACTIVITY wa
    WHERE
      wa.WEB_ACTIVITY_ID = webActivityId;
         --AND wa.SAC_DATE < SYSDATE-2;
    RETURN vResult;

  EXCEPTION WHEN NO_DATA_FOUND THEN
      begin
      return 999;
      end;/* Do Nothing */


  END showSacHoursBilled;

  FUNCTION buildCommentFromWorklog(webActivityWorklogId WEB_ACTIVITY_WORKLOG.WEB_ACTIVITY_WORKLOG_ID%type, webActivityId WEB_ACTIVITY.WEB_ACTIVITY_ID%type) return VARCHAR2 IS
    vCommentWorkLog WEB_ACTIVITY_WORKLOG.SAC_COMMENT%type;
    vText WEB_ACTIVITY.SAC_TEXT%type;
  BEGIN

    SELECT
      nvl(SAC_TEXT,'') into vText
    FROM
      WEB_ACTIVITY
    where
      WEB_ACTIVITY_ID=webActivityId;


    SELECT
      nvl(SAC_COMMENT,'') into vCommentWorkLog
    FROM
      WEB_ACTIVITY_WORKLOG
    WHERE
      WEB_ACTIVITY_WORKLOG_ID=webActivityWorklogId;

    if length(vCommentWorkLog)=0
      then return vText;
    elsif length(vText)=0
      then vText:=vCommentWorkLog;
    else
      vText:=vText||chr(10)||vCommentWorkLog;
    end if;
    return vText;

  END;

END;
