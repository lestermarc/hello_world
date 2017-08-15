--------------------------------------------------------
--  DDL for Procedure RPT_HRM_TAXSOURCE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_TAXSOURCE" (
  aRefCursor  in out crystal_cursor_types.DualCursorTyp
, ProcParam_0        number
, ProcParam_1        number
, ProcParam_2        number
, ProcParam_3        varchar2
, ProcParam_4        varchar2
, ProcParam_5        varchar2
)
is
/**
* description used for report HRM_TAXSOURCE.rpt
* @author rhe
* @created 06/2014
* @lastUpdate
* @public
* @param ProcParam_0  Id List
* @param ProcParam_1  Année mois ( début )
* @param ProcParam_2  Année mois ( fin )
* @param ProcParam_3  Contact
* @param ProcParam_4  Tél
* @param ProcParam_5  canton
*/
begin
  open aRefCursor for
    select EMP_SOCIAL_SECURITYNO2
         , PER_LAST_NAME
         , PER_FIRST_NAME
         , D.HIS_PAY_SUM_VAL
         , D.HIS_PAY_PERIOD
         , CE.COE_BOX
         , PER_BIRTH_DATE
         , T.EMT_CANTON
         , nvl(OFS_CITY, T.EMT_CITY) as EMT_CITY
         , PER_SEARCH_NAME
         , P.HRM_PERSON_ID
         , IO.INO_IN
         , IO.INO_OUT
         , CE.HRM_CONTROL_LIST_ID
         , T.EMT_VALUE
         , T.EMT_FROM
         , T.EMT_TO
         , H.HIT_PAY_PERIOD
         , IO.C_IN_OUT_CATEGORY
         , to_char(H.HIT_PAY_PERIOD, 'YYYYMM') as HISPERIODYYYYMM
         , to_char(H.HIT_PAY_PERIOD, 'MM') as HISPERIODMM
         , HRM_DATE.NEXTINOUTINDATE(IO.INO_IN, IO.HRM_EMPLOYEE_ID) as NEXTINDATE
         , HRM_IS_VD_EMPACI.NEXTEMPTAXINDATE(T.EMT_FROM, T.HRM_PERSON_ID) as NEXTEMTFROM
         , last_day(T.EMT_TO) as LASTDAYEMTTO
         , ProcParam_3 as CONTACT
         , ProcParam_4 as CONTACT_PHONE
         , TAX_PAYER_NO
         , TAX_COMMISSION
      from HRM_EMPLOYEE_TAXSOURCE T
         , HRM_HISTORY_DETAIL D
         , HRM_CONTROL_ELEMENTS CE
         , HRM_HISTORY H
         , HRM_PERSON P
         , HRM_IN_OUT IO
         , HRM_TAXSOURCE_DEFINITION TD
         , PCS.PC_OFS_CITY CITY
     where D.HRM_ELEMENTS_ID = CE.HRM_CONTROL_ELEMENTS_ID
       and D.HRM_EMPLOYEE_ID = H.HRM_EMPLOYEE_ID
       and D.HIS_PAY_NUM = H.HIT_PAY_NUM
       and H.HRM_EMPLOYEE_ID = P.HRM_PERSON_ID
       and T.HRM_PERSON_ID = P.HRM_PERSON_ID
       and P.HRM_PERSON_ID = IO.HRM_EMPLOYEE_ID
       and IO.C_IN_OUT_CATEGORY = '3'
       and CE.HRM_CONTROL_LIST_ID = ProcParam_0
       and T.EMT_CANTON = TD.C_HRM_CANTON
       and (   T.EMT_CANTON = ProcParam_5
            or ProcParam_5 is null)
       and H.HIT_PAY_PERIOD between IO.INO_IN and HRM_DATE.NextInOutInDate(IO.INO_IN, IO.HRM_EMPLOYEE_ID)
       and hit_pay_period between to_date(nvl(ProcParam_1, '190001') || 01, 'YYYYMMDD') and last_day(to_date(nvl(ProcParam_2, '290001') || 01, 'YYYYMMDD') )
       and H.HIT_PAY_PERIOD between T.EMT_FROM and HRM_DATE.EndEmpTaxDate(t.emt_from, t.emt_to,t.hrm_person_id)
       and T.PC_OFS_CITY_ID = CITY.PC_OFS_CITY_ID(+);
end;
