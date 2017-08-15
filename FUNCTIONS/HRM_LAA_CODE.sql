--------------------------------------------------------
--  DDL for Function HRM_LAA_CODE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "HRM_LAA_CODE" (
  vEmpId IN hrm_person.hrm_person_id%TYPE,
  vPayNum IN hrm_history_detail.his_pay_num%TYPE)
  return VARCHAR2
  RESULT_CACHE RELIES_ON (HRM_HISTORY_DETAIL,HRM_ELEMENTS_ROOT)
/**
 * Recherche du code LAA utilisé pour le calcul d'un décompte d'une personne.
 * @param vEmpId  Identifiant de l'employé.
 * @param vPayNum  Numéro du décompte calculé
 * @return le code LAA de l'employé pour le décompte, sinon null.
 *
 * @version 2.0
 * @date 12/2005
 * @author jsomers
 * @author spfister
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 *
 * Modification:
 * spfister 29.09.2010: Activation du cache du résultat.
 * 30.08.2006: Remplacement du curseur par l'appel direct de la commande.
 */
IS
  lv_result VARCHAR2(2);
BEGIN
  select Replace(HIS_PAY_VALUE, '"')
  into lv_result
  from HRM_HISTORY_DETAIL
  where HRM_EMPLOYEE_ID = vEmpId and HIS_PAY_NUM = vPayNum and
    HRM_ELEMENTS_ID = (select HRM_ELEMENTS_ID from HRM_ELEMENTS_ROOT
                       where C_ROOT_FUNCTION='LAA' and C_HRM_SAL_CONST_TYPE='2');
  return lv_result;

  exception
    when NO_DATA_FOUND then
      return '';
END;
