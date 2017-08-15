--------------------------------------------------------
--  DDL for Package Body HRM_PUBLIC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PUBLIC" IS

function EmplAgeinYear(vEmp_id IN hrm_person.hrm_person_id%TYPE)
  return INTEGER
is
begin
 return hrm_functions.EmplAgeinYear(vEmp_id);
end;

function EmplFirstEntry(vEmp_id IN hrm_person.hrm_person_id%TYPE)
  return DATE
is
begin
  return hrm_functions.EmplFirstEntry(vEmp_id);
end;

function EmplYearsOfService(vEmp_id IN hrm_person.hrm_person_id%TYPE)
  return NUMBER
is
begin
  return hrm_functions.EmplYearsOfService(vEmp_id);
end;

function EmplYearMonthsOfService(vEmp_id IN hrm_person.hrm_person_id%TYPE)
  return VARCHAR2
is
begin
  return hrm_functions.EmplYearMonthsOfService(vEmp_id);
end;

function sumElem(vEmp_id IN hrm_person.hrm_person_id%TYPE,
  vCode IN VARCHAR2, vBeginDate IN DATE, vEndDate IN DATE)
  return number
is
begin
  return hrm_functions.sumElem(vEmp_Id, vCode, vBeginDate, vEndDate);
end;

function sumElemInPeriod(vEmp_id IN hrm_person.hrm_person_id%TYPE,
  vCode IN VARCHAR2)
  return NUMBER
is
begin
  return hrm_functions.sumElemInPeriod(vEmp_Id, vCode);
end;

function sumElemInYear(vEmp_id IN hrm_person.hrm_person_id%TYPE,
  vCode IN VARCHAR2)
  return NUMBER
is
begin
  return hrm_functions.sumElemInYear(vEmp_Id, vCode);
end;

function xmlValue(vEmp_id IN hrm_person.hrm_person_id%TYPE,
  vTag IN VARCHAR2)
  return VARCHAR2
is
begin
  return hrm_xml.xmlValue(vEmp_id, vTag);
end;

function elemValue(vEmp_id IN hrm_person.hrm_person_id%TYPE,
  vStatCode in hrm_elements_root.elr_root_code%TYPE, vDate in Date)
  return hrm_employee_elements.emp_num_value%type
is
  result hrm_employee_elements.emp_num_value%type;
begin
  begin
    SELECT emp_num_value into result
    FROM hrm_employee_elements
    WHERE hrm_employee_id = vEmp_Id AND
      hrm_elements_id = (SELECT f.hrm_elements_id FROM hrm_elements_family f
                         WHERE f.HRM_ELEMENTS_PREFIXES_ID = 'EM' AND
                           f.hrm_elements_root_id =
                               (SELECT r.hrm_elements_root_id FROM hrm_elements_root r
                                WHERE r.elr_root_code = vStatCode)) AND
      vDate between emp_value_from and emp_value_to;
    return result;

    exception
      when NO_DATA_FOUND then null;
  end;

  SELECT emc_num_value into result
  FROM hrm_employee_const
  WHERE hrm_employee_id = vEmp_Id AND
    hrm_constants_id = (SELECT f.hrm_elements_id FROM hrm_elements_family f
                        WHERE f.HRM_ELEMENTS_PREFIXES_ID = 'CONEM' AND
                          f.hrm_elements_root_id =
                              (SELECT r.hrm_elements_root_id FROM hrm_elements_root r
                               WHERE r.elr_root_code = vStatCode)) AND
    vDate between emc_value_from and emc_value_to;
  return result;


  exception
    when OTHERS then return null;
end;

function elemHisValue(vEmp_id IN hrm_person.hrm_person_id%TYPE,
  vStatCode in hrm_elements_root.elr_root_code%TYPE,
  vDate in Date)
  return hrm_history_detail.his_pay_sum_val%type
is
  result hrm_history_detail.his_pay_sum_val%type;
begin
  SELECT SUM(his_pay_sum_val) into result
  FROM hrm_history_detail
  WHERE hrm_employee_id = vEmp_Id AND
      hrm_elements_id = (SELECT f.hrm_elements_id FROM hrm_elements_family f
                         WHERE f.elf_is_reference = 1 AND
                           f.hrm_elements_root_id =
                               (SELECT r.hrm_elements_root_id FROM hrm_elements_root r
                                WHERE r.elr_root_code = vStatCode)) AND
      his_pay_period = Last_Day(vDate);

  return result;

  exception
    when OTHERS then return null;
end;

END HRM_PUBLIC;
