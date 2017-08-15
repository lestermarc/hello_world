--------------------------------------------------------
--  DDL for Function HRM_PAYCOUNT
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "HRM_PAYCOUNT" (vEmpId IN HRM_PERSON.HRM_PERSON_ID%TYPE,
  vPeriod IN DATE)
  RETURN INTEGER
/**
 * @version 2.0
 * @date 12/2005
 * @author jsomers
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Calculate the number of Pay calculated de finitively in a given Period for
 * a given employee.
 * Return the number of payroll calculated.
 * @param vEmpId  Identifier of the employee.
 *
 * Modifications:
 * 20.12.2006: Remplacement du curseur par l'appel direct de la commande.
 */
IS
  result INTEGER;
BEGIN
  SELECT count(*) INTO result
  FROM hrm_history
  WHERE hrm_employee_id = vEmpId AND hit_pay_period = vPeriod AND
    hit_definitive = 1;
  return result;

  exception
    when no_data_found then return 0;
END;
