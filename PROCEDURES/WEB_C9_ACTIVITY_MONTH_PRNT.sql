--------------------------------------------------------
--  DDL for Procedure WEB_C9_ACTIVITY_MONTH_PRNT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "WEB_C9_ACTIVITY_MONTH_PRNT" (aRefCursor  IN OUT Crystal_Cursor_Types.DualCursorTyp, INITIALDATE IN VARCHAR2, USERINI     IN WEB_ACTIVITY.SAC_WHO%TYPE ) IS
/******************************************************************************
   NAME:       WEB_C9_ACTIVITY_MONTH_Prnt
   PURPOSE: Données pour rapport Analytique



  2005 03 09 Created this procedure.
  2008 10 02 RRI Prise en compte du paramètre provenant du ePrint


   NOTES:


******************************************************************************/
  vINITIALDATE varchar2(10);
BEGIN
  -- Sélection résultat.
    if substr(INITIALDATE,3,1) in ('0','1') then
      vINITIALDATE := substr(INITIALDATE,7,2)||' '||substr(INITIALDATE,5,2)||' '||substr(INITIALDATE,3,2);
    else
     vINITIALDATE := INITIALDATE;
  end if;

  OPEN aRefCursor FOR
     SELECT
            pac.cal_date,
            pac.CAL_OPENDAY,
            rco_title,
            web.web_activity_id,
            web.sac_date,
            NVL(sac_who,USERINI) SAC_WHO,
            sac_task_code,
            sac_project_id,
            sac_hours,
            sac_text,
            sac_hours,
            sac_bill_type,
            c_web_activity_state,
            web.a_datecre,
            web.a_datemod,
            web.a_idmod,
            web.new_doc_record_id,
            web.new_pac_custom_partner_id,
            web.new_price,
            new_sac_bill_type,
            sac_cust_machine,
            use_descr,
            rco.pac_third_id
     FROM
            PAC_CALENDAR_DAYS pac,
            WEB_ACTIVITY web,
            DOC_RECORD rco,
            pcs.pc_user p
     WHERE
            p.use_ini = USERINI
        AND pac.cal_date = web.sac_date (+)
        AND web.SAC_PROJECT_ID = rco.doc_record_id (+)
        AND web.sac_who(+) = USERINI
        AND TO_CHAR(cal_date,'YYMM') =  SUBSTR(vINITIALDATE,7,2)||SUBSTR(vINITIALDATE,4,2);
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END Web_C9_Activity_Month_Prnt;
