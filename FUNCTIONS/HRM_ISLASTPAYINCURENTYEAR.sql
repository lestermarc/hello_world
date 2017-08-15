--------------------------------------------------------
--  DDL for Function HRM_ISLASTPAYINCURENTYEAR
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "HRM_ISLASTPAYINCURENTYEAR" (LastPayDate IN DATE)
  RETURN INTEGER
/**
 * @version 2.0
 * @date 12/2005
 * @author jsomers
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Tested in the where clause of v_hrm_emp_sum as no sums should be carried over the end of year.
 * Return 1(one) if lastPayDate is in the year defined by the active period, otherwise 0(zero)
 *
 * Modifications:
 * 20.12.2006: Remplacement du curseur par l'appel direct de la commande.
 */
IS
  result INTEGER;
BEGIN
  SELECT case when Trunc(Max(per_begin),'Y') = Trunc(LastPayDate,'Y') then 1 else 0 end INTO result
  FROM hrm_period
  WHERE per_act = 1;

  return result;

  exception
    when no_data_found then return 0;
END;
