--------------------------------------------------------
--  DDL for Procedure RPT_HRM_ABSENCES_MANAGEMENT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_ABSENCES_MANAGEMENT" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procparam_0      IN       VARCHAR2,
   procparam_1      IN       VARCHAR2,
   procparam_2      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*Description Used for report RPT_HRM_ABSENCES_MANAGEMENT

*author VHA
*created on 30 jun 2011
*update VHA 09 September 2013
*@public
*@param procparam_0: Date from (YYYYMMDD)
*@param procparam_1: Date to (YYYYMMDD)
*@param procparam_2: GROUP BY (0:ABSENCE TYPE, 1:EMPLOYE, 2:DEPARTEMENT)
*@param user_lanid  : user language
*/

   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
   v_date_from DATE;
   v_date_to    DATE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;
   v_date_from :=RPT_FUNCTIONS.StringToDate(procparam_0);
   v_date_to := RPT_FUNCTIONS.StringToDate(procparam_1);

  OPEN arefcursor FOR
        SELECT  v_date_from DATE_FROM,
                     v_date_to DATE_TO,
                     P.EMP_NUMBER,
                     P.PER_LAST_NAME||' '||P.PER_FIRST_NAME PER_NAME,
                     P.DIC_DEPARTMENT_ID,
                     (SELECT DD.DIT_DESCR
                        FROM    DICO_DESCRIPTION DD
                     WHERE   DD.DIT_CODE = P.DIC_DEPARTMENT_ID
                         AND     DD.DIT_TABLE = 'DIC_DEPARTMENT'
                         AND  DD.PC_LANG_ID(+) = vpc_lang_id) DIC_DEPARTMENT_DESCR,
                     P.HRM_PERSON_ID RES_ID,
                     SP.DIC_SCH_PERIOD_1_ID,
                     (SELECT DP.DIT_DESCR
                        FROM    DICO_DESCRIPTION DP
                        WHERE   DP.DIT_CODE(+) = SP.DIC_SCH_PERIOD_1_ID
                            AND       DP.DIT_TABLE(+) = 'DIC_SCH_PERIOD_1'
                            AND       DP.PC_LANG_ID(+) = vpc_lang_id) DIC_SCH_PERIOD_1_DESC,
                     SP.SCP_COMMENT,
                     SP.SCP_DATE,
                     SP.SCP_OPEN_TIME,
                     SP.SCP_CLOSE_TIME
        FROM    PAC_SCHEDULE_PERIOD SP,
                     HRM_PERSON P
        WHERE  P.PER_IS_EMPLOYEE = 1
            AND  SP.HRM_PERSON_ID(+) = P.HRM_PERSON_ID
            AND  SCP_DATE IS NOT NULL
            AND  NVL(SP.SCP_DATE, NEXT_DAY(v_date_from - 1, C_DAY_OF_WEEK)) BETWEEN v_date_from AND v_date_to;
END RPT_HRM_ABSENCES_MANAGEMENT;
