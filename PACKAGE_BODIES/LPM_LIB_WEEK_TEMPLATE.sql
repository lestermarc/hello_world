--------------------------------------------------------
--  DDL for Package Body LPM_LIB_WEEK_TEMPLATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LPM_LIB_WEEK_TEMPLATE" 
as
  /**
  * procedure IsWeekTemplateDefined
  * description :
  *    Détermine si un template existe dans la base.
  */
  function IsWeekTemplateDefined(
    iDivisionOutlayID in LPM_DIVISION_OUTLAY.LPM_DIVISION_OUTLAY_ID%type
  , iBeneficiaryID    in SCH_STUDENT.SCH_STUDENT_ID%type
  , iDivisionID       in HRM_DIVISION.HRM_DIVISION_ID%type
  , iDayNum           in LPM_WEEK_TEMPLATE.LWT_DAY%type
  )
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from LPM_WEEK_TEMPLATE LWT
     where LWT.LPM_DIVISION_OUTLAY_ID = iDivisionOutlayID
       and (   LWT.SCH_STUDENT_ID = iBeneficiaryID
            or (    LWT.SCH_STUDENT_ID is null
                and iBeneficiaryID is null) )
       and LWT.HRM_DIVISION_ID = iDivisionID
       and LWT.LWT_DAY = iDayNum;

    return lnResult;
  end IsWeekTemplateDefined;
end LPM_LIB_WEEK_TEMPLATE;
