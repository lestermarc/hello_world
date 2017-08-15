--------------------------------------------------------
--  DDL for Package Body IND_HRM_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_HRM_FCT" 
is

function IsEmployeePayableLastYear(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from HRM_PERSON p
     where HRM_PERSON_ID = EmpId
       and EMP_CALCULATION != 0
       and exists(
             select 1
               from HRM_IN_OUT
              where HRM_EMPLOYEE_ID = P.HRM_PERSON_ID
                and C_IN_OUT_STATUS = 'ACT'
                and INO_IN <= hrm_date.ActivePeriodEndDate
                -- sortis annees precedentes
                and INO_OUT <= hrm_date.BeginOfYear
                ---and INO_OUT >= add_months(hrm_date.BeginOfYear,-12)
                and C_IN_OUT_CATEGORY = '3');

    return ln_result;
  exception
    when no_data_found then
      return 0;
end IsEmployeePayableLastYear;

function IsEmployeePayableAll(EmpId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from HRM_PERSON p
     where HRM_PERSON_ID = EmpId
       and EMP_CALCULATION != 0;

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end IsEmployeePayableAll;

end ind_hrm_fct;
