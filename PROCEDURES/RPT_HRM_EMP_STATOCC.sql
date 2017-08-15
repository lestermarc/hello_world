--------------------------------------------------------
--  DDL for Procedure RPT_HRM_EMP_STATOCC
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_EMP_STATOCC" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, parameter_0    in     varchar2
, parameter_1    in     varchar2
, parameter_2    in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
*Description
Used for report HRM_EMP_STATOCC

*author VHA
*created VHA 04 JUNE 2012    (DEVRPT-10573)
*updated VHA 28 March 2013
* @public
*@param parameter_0 :   LIST_ID
*@param  parameter_1 :   REF_DATE
*@param  parameter_2 : Detailled by establishment  (True/False)
*/
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type;
begin
  PCS.PC_I_LIB_SESSION.setLanId(procuser_lanid);
  vpc_lang_id  := PCS.PC_I_LIB_SESSION.GetUserLangId;

  open aRefCursor for
    select STS.DATE_REF
         , STS.HRM_PERSON_ID
         , least(1
               , nvl(case
                       when C_OFS_CONTRACT_TYPE in('3', '5') then nvl((select sum(HIS_PAY_SUM_VAL)
                                                                     from HRM_HISTORY_DETAIL DE
                                                                    where DE.HRM_EMPLOYEE_ID = HRM_PERSON_ID
                                                                      and HIS_PAY_PERIOD = DATE_REF
                                                                      and exists(
                                                                            select 1
                                                                              from HRM_CONTROL_ELEMENTS CE
                                                                             where CE.HRM_CONTROL_ELEMENTS_ID = DE.HRM_ELEMENTS_ID
                                                                               and CE.HRM_CONTROL_LIST_ID = parameter_0
                                                                               and COE_BOX = 'STAT03') ) /
                                                                  (STS.EST_HOURS_WEEK * (52/12) ), STS.RATE)
                       else STS.RATE
                     end
                   , 0
                    )
                ) RATE
         , STS.BORDER_WORKER
         , STS.PER_GENDER
         , case
             when upper(parameter_2) = 'TRUE'
             then (select EST_HOURS_WEEK
                     from HRM_ESTABLISHMENT
                    where HRM_ESTABLISHMENT_ID = EST.HRM_ESTABLISHMENT_ID)
             else (select EST_HOURS_WEEK
                     from HRM_ESTABLISHMENT
                    where EST_DEFAULT = 1)
           end EST_HOURS_WEEK
         , EST.HRM_ESTABLISHMENT_ID
         , EST.EST_NAME
         , EST.EST_ADDRESS
         , EST.EST_CITY
         , EST.EST_REE
      from (select   to_date(parameter_1, 'dd.MM.yyyy') DATE_REF
                   , C_OFS_CONTRACT_TYPE
                   , HRM_PERSON_ID
                   , least(100, sum(nvl(CON_ACTIVITY_RATE,PER_ACTIVITY_RATE)) ) / 100 RATE
                   , case
                       when DIC_NATIONALITY_ID <> 'CH'
                       and exists(
                             select 1
                               from HRM_EMPLOYEE_WK_PERMIT W
                              where W.HRM_PERSON_ID = P.HRM_PERSON_ID
                                and DIC_WORK_PERMIT_ID = 'G'
                                and to_date(parameter_1, 'dd.MM.yyyy') >= WOP_VALID_FROM
                                and (   to_date(parameter_1, 'dd.MM.yyyy') <= WOP_VALID_TO
                                     or WOP_VALID_TO is null) ) then 1
                       else 0
                     end BORDER_WORKER
                   , PER_GENDER
                   , min( (select EST_HOURS_WEEK
                             from HRM_ESTABLISHMENT
                            where HRM_ESTABLISHMENT_ID = IO.HRM_ESTABLISHMENT_ID) ) EST_HOURS_WEEK
                   , max( (select HRM_ESTABLISHMENT_ID
                             from HRM_IN_OUT
                            where HRM_IN_OUT_ID = IO.HRM_IN_OUT_ID) ) HRM_ESTABLISHMENT_ID
                from HRM_PERSON P
                   , HRM_CONTRACT C
                   , HRM_IN_OUT IO
               where P.HRM_PERSON_ID = IO.HRM_EMPLOYEE_ID
               and C_IN_OUT_CATEGORY='3'
                 and C.HRM_IN_OUT_ID (+) = IO.HRM_IN_OUT_ID
                 and  (   to_date(parameter_1, 'dd.MM.yyyy') >= CON_BEGIN
                      or CON_BEGIN is null)
                 and (   to_date(parameter_1, 'dd.MM.yyyy') <= CON_END
                      or CON_END is null)
                 and HRM_FUNCTIONS.ageingivenyear(to_date(parameter_1, 'dd.MM.yyyy'), PER_BIRTH_DATE) >= 18
            group by HRM_PERSON_ID
                   , C_OFS_CONTRACT_TYPE
                   , PER_GENDER
                   , DIC_NATIONALITY_ID
            union all
            select   add_months(to_date(parameter_1, 'dd.MM.yyyy'), -3)
                   , C_OFS_CONTRACT_TYPE
                   , HRM_PERSON_ID
                   , least(100, sum(nvl(CON_ACTIVITY_RATE,PER_ACTIVITY_RATE)) ) / 100 RATE
                   , case
                       when DIC_NATIONALITY_ID <> 'CH'
                       and exists(
                             select 1
                               from HRM_EMPLOYEE_WK_PERMIT W
                              where W.HRM_PERSON_ID = P.HRM_PERSON_ID
                                and DIC_WORK_PERMIT_ID = 'G'
                                and add_months(to_date(parameter_1, 'dd.MM.yyyy'), -3) >= WOP_VALID_FROM
                                and (   add_months(to_date(parameter_1, 'dd.MM.yyyy'), -3) <= WOP_VALID_TO
                                     or WOP_VALID_TO is null) ) then 1
                       else 0
                     end BORDER_WORKER
                   , PER_GENDER
                   , min( (select EST_HOURS_WEEK
                             from HRM_ESTABLISHMENT
                            where HRM_ESTABLISHMENT_ID = IO.HRM_ESTABLISHMENT_ID) ) EST_HOURS_WEEK
                   , max( (select HRM_ESTABLISHMENT_ID
                             from HRM_IN_OUT
                            where HRM_IN_OUT_ID = IO.HRM_IN_OUT_ID) ) HRM_ESTABLISHMENT_ID
                from HRM_PERSON P
                   , HRM_CONTRACT C
                   , HRM_IN_OUT IO
               where P.HRM_PERSON_ID = IO.HRM_EMPLOYEE_ID
                 and C_IN_OUT_CATEGORY='3'
                 and C.HRM_IN_OUT_ID (+) = IO.HRM_IN_OUT_ID
                 and (   add_months(to_date(parameter_1, 'dd.MM.yyyy'), -3) >= CON_BEGIN
                      or CON_BEGIN is null)
                 and (   add_months(to_date(parameter_1, 'dd.MM.yyyy'), -3) <= CON_END
                      or CON_END is null)
                 and HRM_FUNCTIONS.ageingivenyear(add_months(to_date(parameter_1, 'dd.MM.yyyy'), -3), PER_BIRTH_DATE) >= 18
            group by HRM_PERSON_ID
                   , C_OFS_CONTRACT_TYPE
                   , PER_GENDER
                   , DIC_NATIONALITY_ID) STS
         , HRM_ESTABLISHMENT EST
     where EST.HRM_ESTABLISHMENT_ID = STS.HRM_ESTABLISHMENT_ID;
end RPT_HRM_EMP_STATOCC;
