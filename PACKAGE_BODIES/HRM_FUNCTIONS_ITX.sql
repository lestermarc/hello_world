--------------------------------------------------------
--  DDL for Package Body HRM_FUNCTIONS_ITX
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_FUNCTIONS_ITX" 
AS
   /* fonction retournant le département saisi dans les données de comptabilisation */
   FUNCTION getDepartment (empid hrm_person.hrm_person_id%TYPE)
      RETURN VARCHAR2
   IS
      lv_return   HRM_EMPLOYEE_BREAK.HEB_DEPARTMENT_ID%TYPE;
   BEGIN
      SELECT HEB_DEPARTMENT_ID
        INTO lv_return
        FROM hrm_employee_break
       WHERE     heb_default_flag = 1
             AND hrm_employee_id = empid
             -- 25.01.2016 : Ajout d'une clause de séléction à cause des personnes ayants plusieurs départements dans "Comptabilisation"
             AND rownum <= 1
             AND heb_ratio =
                    (SELECT MAX (heb_ratio)
                       FROM hrm_employee_break
                      WHERE heb_default_flag = 1 AND hrm_employee_id = empid);

      RETURN lv_return;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN '';
      WHEN DUP_VAL_ON_INDEX
      THEN
         SELECT HEB_DEPARTMENT_ID
           INTO lv_return
           FROM hrm_employee_break
          WHERE     heb_default_flag = 1
                AND hrm_employee_id = empid
                -- 25.01.2016 : Ajout d'une clause de séléction à cause des personnes ayants plusieurs départements dans "Comptabilisation"
                AND rownum <= 1
                AND heb_ratio =
                       (SELECT MAX (heb_ratio)
                          FROM hrm_employee_break
                         WHERE     heb_default_flag = 1
                               AND hrm_employee_id = empid)
                AND ROWNUM = 1;

         RETURN lv_return;
   END getDepartment;
END HRM_FUNCTIONS_ITX;
