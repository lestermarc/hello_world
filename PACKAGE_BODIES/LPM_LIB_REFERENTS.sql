--------------------------------------------------------
--  DDL for Package Body LPM_LIB_REFERENTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LPM_LIB_REFERENTS" 
as
  /**
  * procedure ValidateDate
  * description :
  *    Détermine si la date de début et de fin est correct pour une appartenance. Evite le chevauchement
  *    avec d'autres appartenances liée à une même structure structure pour un bénéficiaire donné.
  */
  function ValidateDate(
    iFromDate      in date
  , iToDate        in date
  , iBeneficiaryId in SCH_STUDENT.SCH_STUDENT_ID%type
  , iDivisionId    in HRM_DIVISION.HRM_DIVISION_ID%type
  , iReferentsId   in LPM_REFERENTS.LPM_REFERENTS_ID%type default null
  )
    return integer
  is
    ln_result  integer;
    ld_maxdate date;
  begin
    select to_date('31129999', 'DDMMYYYY')
      into ld_maxdate
      from dual;

    select abs(sign(count(*) ) - 1)
      into ln_result
      from LPM_REFERENTS P
     where SCH_STUDENT_ID = iBeneficiaryId
       and HRM_DIVISION_ID = iDivisionId
       and LPM_CONTRACT_ID is not null
       and (   iReferentsId is null
            or LPM_REFERENTS_ID <> iReferentsId)
       and (    (    nvl(LRE_END_DATE, ld_maxdate) >= iFromDate
                 and LRE_START_DATE <= iFromDate)
            or (    nvl(LRE_END_DATE, ld_maxdate) >= iFromDate
                and LRE_START_DATE <= nvl(iToDate, ld_maxdate) )
            or (    nvl(LRE_END_DATE, ld_maxdate) >= iFromDate
                and nvl(LRE_END_DATE, ld_maxdate) <= nvl(iToDate, ld_maxdate) )
           );

    return ln_result;
  exception
    when no_data_found then
      return 1;
  end ValidateDate;
end LPM_LIB_REFERENTS;
