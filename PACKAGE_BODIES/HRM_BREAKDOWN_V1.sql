--------------------------------------------------------
--  DDL for Package Body HRM_BREAKDOWN_V1
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_BREAKDOWN_V1" 
AS

procedure prep_temp_tables(period DATE)
is
begin
  /*
  Données de ventilation des éléments
  */
  DELETE FROM hrm_tmp_elements_break_v1;

  INSERT INTO hrm_tmp_elements_break_v1
     SELECT *
     FROM   v_hrm_elements_break_v1;

  /*
  Données de répartition ( groupes ) des éléments
  */
  DELETE FROM hrm_tmp_elements_ratio_group;

  INSERT INTO hrm_tmp_elements_ratio_group
     SELECT hrm_elements_id, 1
     FROM   hrm_elements
     WHERE  INSTR (ele_use_ratio_group, 1) > 0
     UNION ALL
     SELECT hrm_elements_id, 2
     FROM   hrm_elements
     WHERE  INSTR (ele_use_ratio_group, 2) > 0
     UNION ALL
     SELECT hrm_elements_id, 3
     FROM   hrm_elements
     WHERE  INSTR (ele_use_ratio_group, 3) > 0
     UNION ALL
     SELECT hrm_elements_id, 4
     FROM   hrm_elements
     WHERE  INSTR (ele_use_ratio_group, 4) > 0
     UNION ALL
     SELECT hrm_elements_id, 5
     FROM   hrm_elements
     WHERE  INSTR (ele_use_ratio_group, 5) > 0
     UNION ALL
     SELECT hrm_elements_id, 6
     FROM   hrm_elements
     WHERE  INSTR (ele_use_ratio_group, 6) > 0
     UNION ALL
     SELECT hrm_elements_id, 7
     FROM   hrm_elements
     WHERE  INSTR (ele_use_ratio_group, 7) > 0
     UNION ALL
     SELECT hrm_elements_id, 8
     FROM   hrm_elements
     WHERE  INSTR (ele_use_ratio_group, 8) > 0
     UNION ALL
     SELECT hrm_elements_id, 9
     FROM   hrm_elements
     WHERE  INSTR (ele_use_ratio_group, 9) > 0;

  /*
  Imputations de toute l'année de la période
  */
  EXECUTE IMMEDIATE 'truncate table hrm_tmp_break_detail';

  INSERT INTO hrm_tmp_break_detail BULK
              (hrm_break_id, hrm_history_detail_id, hdb_source, dic_account_type_id, hdb_amount_type,
               hrm_employee_id, hrm_elements_id, hdb_account_name, hdb_amount, hdb_zl, hdb_is_exported,
               hdb_ref_value, hdb_foreign_value, acs_financial_currency_id, hdb_value_date)
     SELECT d.hrm_break_id, hrm_history_detail_id, hdb_source, dic_account_type_id, hdb_amount_type,
            d.hrm_employee_id, d.hrm_elements_id, hdb_account_name, hdb_amount, hdb_zl, hdb_is_exported,
            hdb_ref_value, hdb_foreign_value, d.acs_financial_currency_id, brk_value_date
     FROM   hrm_break_detail d, hrm_break b
     WHERE  TRUNC (b.brk_value_date, 'YEAR') = TRUNC (period, 'YEAR') AND
            b.hrm_break_id = d.hrm_break_id AND
            EXISTS(SELECT 1
                   FROM hrm_history h
                   WHERE d.hrm_employee_id = h.hrm_employee_id AND
                         hit_pay_period = period AND
                         hit_accounted = 3); -- '(3) à ventiler'
end;

procedure launchbreak(
  empid      NUMBER,
  paynum     INTEGER,
  currency   NUMBER,
  breakid    NUMBER,
  status     INTEGER)
is
begin
  /*
  Remplissage de la table temporaire de l'historique calculé
  */
  DELETE FROM hrm_tmp_history_detail;

  INSERT INTO hrm_tmp_history_detail
             (hrm_history_detail_id, hrm_elements_id, hrm_employee_id, hrm_salary_sheet_id, his_pay_num,
              his_pay_period, his_pay_value, his_pay_sum_val, acs_financial_currency_id, his_currency_value,
              his_ref_value, his_definitive, his_accounted, his_paid, his_date, his_zl)
    SELECT hrm_history_detail_id, hrm_elements_id, hrm_employee_id, hrm_salary_sheet_id, his_pay_num,
           his_pay_period, his_pay_value, his_pay_sum_val, acs_financial_currency_id, his_currency_value,
           his_ref_value, his_definitive, his_accounted, his_paid, his_date, his_zl
    FROM   hrm_history_detail
    WHERE  hrm_employee_id = empid AND
           his_pay_num = paynum;

  /*
  Lancement des procédures de répartition
  */
  insert_pass01(BreakId, Currency, EmpId);
  insert_pass02(BreakId, Currency, EmpId);
  insert_pass03(BreakId, Currency, EmpId);
  insert_pass04(BreakId, Currency, EmpId);
  insert_pass05(BreakId, Currency, EmpId);
  insert_pass06(BreakId, Currency, EmpId);

end;

/**
* Ventilation des variables / constantes
* qui ont des données de répartition ( HRM_HISTORY_DETAIL_BREAK )
*/
procedure insert_pass01(breakid NUMBER, defaultcurrency NUMBER, personid NUMBER)
is
begin
  INSERT INTO hrm_tmp_break_detail
              (hrm_break_id, hrm_elements_id, hrm_employee_id, dic_account_type_id, hdb_amount, hdb_account_name,
               hdb_amount_type, hrm_history_detail_id, hdb_source, acs_financial_currency_id, hdb_is_exported,
               hdb_foreign_value, hdb_ref_value, hdb_zl)
     SELECT breakid, b.hrm_elements_id, hrm_employee_id, account_type,
            (ROUND ((eeb_value / 0.05) + 0.4999)) * 0.05,
            CASE
               WHEN account_type = 'CG' AND amount_type = 'D'
                  THEN NVL (NVL (eeb_d_cgbase,
                                 TO_CHAR (TO_NUMBER (base)
                                          + DECODE (shift,
                                                    100, TO_NUMBER (NVL (dic_department_id, 0)) * 1000,
                                                    500, TO_NUMBER (NVL (dic_department_id, 0)) * 1000
                                                     + TO_NUMBER (NVL (job_code, 0)),
                                                    0
                                                   ))),
                            '99999')
               WHEN account_type = 'DIV' AND amount_type = 'D'
                  THEN NVL (NVL (eeb_divbase, base), '000')
               WHEN account_type = 'CG' AND amount_type = 'C'
                  THEN NVL (NVL (eeb_c_cgbase,
                                 TO_CHAR (TO_NUMBER (base)
                                          + DECODE (shift,
                                                    100, TO_NUMBER (NVL (dic_department_id, 0)) * 1000,
                                                    500, TO_NUMBER (NVL (dic_department_id, 0)) * 1000
                                                     + TO_NUMBER (NVL (job_code, 0)),
                                                    0
                                                   ))),
                            '99999')
               WHEN account_type = 'DIV' AND amount_type = 'C'
                  THEN NVL (NVL (eeb_divbase, base), '000')
            END account_name,
            amount_type, b.hrm_history_detail_id, eeb_sequence SOURCE,
            NVL (acs_financial_currency_id, defaultcurrency), 0, 0, 0, his_zl
     FROM   hrm_history_detail_break c, hrm_tmp_elements_break_v1 a, hrm_tmp_history_detail b
     WHERE  a.hrm_elements_id = b.hrm_elements_id
            AND eeb_ratio_group > 0
            AND b.hrm_history_detail_id = c.hrm_history_detail_id;
end;

/**
* Comptabilisation de la provision 13ème selon la répartition
* des groupes donnés par la nomenclature
*/
procedure insert_pass02(breakid NUMBER, defaultcurrency NUMBER, personid NUMBER)
is
begin
  INSERT INTO hrm_tmp_break_detail
              (hrm_break_id, hrm_elements_id, hrm_employee_id, dic_account_type_id, hdb_amount, hdb_account_name,
               hdb_amount_type, hrm_history_detail_id, hdb_source, acs_financial_currency_id, hdb_is_exported,
               hdb_foreign_value, hdb_ref_value, hdb_zl)
     SELECT breakid, b.hrm_elements_id, b.hrm_employee_id, account_type,
            (ROUND ((his_pay_sum_val * rate / 0.05) + 0.4999)) * 0.05 break_value,
            CASE
               WHEN account_type = 'CG' AND amount_type = 'D'
                  THEN NVL (TO_CHAR (TO_NUMBER (base)
                                     + DECODE (shift,
                                               100, TO_NUMBER (NVL (dic_department_id, 0)) * 1000,
                                               500, TO_NUMBER (NVL (dic_department_id, 0)) * 1000
                                                + TO_NUMBER (NVL (job_code, 0)),
                                               0
                                              )),
                            '99999')
               WHEN account_type = 'DIV' AND amount_type = 'D'
                  THEN NVL (NVL (base, division), '000')
               WHEN account_type = 'CG' AND amount_type = 'C'
                  THEN NVL (TO_CHAR (TO_NUMBER (base)
                                     + DECODE (shift,
                                               100, TO_NUMBER (NVL (dic_department_id, 0)) * 1000,
                                               500, TO_NUMBER (NVL (dic_department_id, 0)) * 1000
                                                + TO_NUMBER (NVL (job_code, 0)),
                                               0
                                              )),
                            '99999')
               WHEN account_type = 'DIV' AND amount_type = 'C'
                  THEN NVL (NVL (base, division), '000')
            END account_name,
            amount_type, hrm_history_detail_id, SOURCE, NVL (acs_financial_currency_id, defaultcurrency), 0, 0, 0,
            his_zl
     FROM   (SELECT   eeb_divbase division, dic_department_id, job_code,
                      SUM (eeb_value)
                      / (SELECT SUM (eeb_value)
                         FROM   hrm_tmp_elements_ratio_group dg, hrm_formulas_structure e,
                                hrm_history_detail_break a, hrm_tmp_history_detail b
                         WHERE  related_id = b.hrm_elements_id
                                AND dg.hrm_elements_id = 6103
                                AND relation_type = 1
                                AND a.hrm_history_detail_id = b.hrm_history_detail_id
                                AND useratiogroup = a.eeb_ratio_group
                                AND main_id = 6103) rate,
                      TO_CHAR (eeb_ratio_group) || TO_CHAR (eeb_divbase) || '/'
                      || TO_CHAR (dic_department_id) || '/' || TO_CHAR (job_code) SOURCE,
                      eeb_ratio_group
             FROM     hrm_history_detail_break a, hrm_tmp_elements_ratio_group dg, hrm_formulas_structure e,
                      hrm_tmp_history_detail b
             WHERE    main_id = 6103
                      AND a.hrm_history_detail_id = b.hrm_history_detail_id
                      AND related_id = b.hrm_elements_id
                      AND dg.hrm_elements_id = 6103
                      AND relation_type = 1
                      AND useratiogroup = a.eeb_ratio_group
             -- CemProv13M
             GROUP BY eeb_divbase, dic_department_id, job_code, eeb_ratio_group) c,
            hrm_tmp_history_detail b, hrm_tmp_elements_break_v1 a
     WHERE  b.hrm_elements_id = 6103
            AND a.hrm_elements_id = 6103 --CemProv13M
            AND NOT EXISTS (SELECT 1
                            FROM   hrm_tmp_break_detail t
                            WHERE  hrm_break_id = breakid AND t.hrm_history_detail_id = b.hrm_history_detail_id);
end;

/**
* Répartition du 13ème salaire en fonction de la ventilation
* de la provision 13ème de l'année
*/
procedure insert_pass03(breakid NUMBER, defaultcurrency NUMBER, personid NUMBER)
is
begin
  INSERT INTO hrm_tmp_break_detail
              (hrm_break_id, hrm_elements_id, hrm_employee_id, dic_account_type_id, hdb_amount, hdb_account_name,
               hdb_amount_type, hrm_history_detail_id, hdb_source, acs_financial_currency_id, hdb_is_exported,
               hdb_foreign_value, hdb_ref_value, hdb_zl)
     SELECT breakid, b.hrm_elements_id, personid, account_type,
            (ROUND ((his_pay_sum_val * rate / 0.05) + 0.4999)) * 0.05 break_value,
            CASE
               WHEN account_type = 'CG'
                  THEN cg
               ELSE div
            END account_name, amount_type, hrm_history_detail_id, SOURCE,
            NVL (acs_financial_currency_id, defaultcurrency), 0, 0, 0, his_zl
     FROM   (SELECT   TO_CHAR (personid) || '-' || TO_CHAR (b.hdb_account_name) || '/'
                      || TO_CHAR (a.hdb_account_name) SOURCE,
                      a.hdb_account_name cg, b.hdb_account_name div,
                      SUM (a.hdb_amount)
                      / (SELECT SUM (hdb_amount) total
                         FROM   hrm_tmp_break_detail
                         WHERE  hrm_elements_id = 6103 --CemProv13M
                                AND dic_account_type_id = 'CG'
                                AND hrm_employee_id = personid) rate
             FROM     hrm_tmp_break_detail a, hrm_tmp_break_detail b
             WHERE    a.hrm_break_id = b.hrm_break_id
                      AND a.hrm_history_detail_id = b.hrm_history_detail_id
                      AND a.hdb_source = b.hdb_source
                      AND a.hdb_amount_type = b.hdb_amount_type
                      AND a.hrm_elements_id = 6103 --CemProv13M
                      AND a.dic_account_type_id = 'CG'
                      AND b.dic_account_type_id = 'DIV'
                      AND a.hrm_employee_id = personid
             GROUP BY a.hdb_account_name, b.hdb_account_name) c,
            hrm_tmp_history_detail b, hrm_tmp_elements_break_v1 a
     WHERE  a.hrm_elements_id = b.hrm_elements_id
            AND a.hrm_elements_id = 2798
            AND NOT EXISTS (SELECT 1
                            FROM   hrm_tmp_break_detail t
                            WHERE  hrm_break_id = breakid AND t.hrm_history_detail_id = b.hrm_history_detail_id);
end;

/**
* Répartition des éléments non ventilés selon la nomenclature
* + Prise en compte des éléments liés au salaire mensuel
* si 13ème salaire versé dans la période
*/
procedure insert_pass04(breakid NUMBER, defaultcurrency NUMBER, personid NUMBER)
is
begin
  INSERT INTO hrm_tmp_break_detail
              (hrm_break_id, hrm_elements_id, hrm_employee_id, dic_account_type_id, hdb_amount, hdb_account_name,
               hdb_amount_type, hrm_history_detail_id, hdb_source, acs_financial_currency_id, hdb_is_exported,
               hdb_foreign_value, hdb_ref_value, hdb_zl)
     SELECT breakid, b.hrm_elements_id, personid, account_type,
            (ROUND ((his_pay_sum_val * rate / 0.05) + 0.4999)) * 0.05 break_value,
            CASE
               WHEN account_type = 'DIV' AND amount_type = 'D'
                  THEN NVL (NVL (base, division), '000')
               WHEN account_type = 'CG' AND amount_type = 'D'
                  THEN NVL (TO_CHAR (TO_NUMBER (base)
                                     + DECODE (shift,
                                               100, TO_NUMBER (NVL (dic_department_id, 0)) * 1000,
                                               500, TO_NUMBER (NVL (dic_department_id, 0)) * 1000
                                                + TO_NUMBER (NVL (job_code, 0)),
                                               0
                                              )),
                            '99999')
               WHEN account_type = 'CG' AND amount_type = 'C'
                  THEN NVL (TO_CHAR (TO_NUMBER (base)
                                     + DECODE (shift,
                                               100, TO_NUMBER (NVL (dic_department_id, 0)) * 1000,
                                               500, TO_NUMBER (NVL (dic_department_id, 0)) * 1000
                                                + TO_NUMBER (NVL (job_code, 0)),
                                               0
                                              )),
                            '99999')
               WHEN account_type = 'DIV' AND amount_type = 'C'
                  THEN NVL (NVL (base, division), '000')
            END account_name,
            amount_type, hrm_history_detail_id, SOURCE, NVL (acs_financial_currency_id, defaultcurrency), 0, 0, 0,
            his_zl
     FROM   (SELECT a.hrm_employee_id, a.main_id, a.val / b.val rate, division, dic_department_id, job_code,
                    TO_CHAR (eeb_ratio_group) || '/' || TO_CHAR (division) || '/'
                    || TO_CHAR (dic_department_id) || '/' || TO_CHAR (job_code) SOURCE,
                    a.eeb_ratio_group
             FROM   (SELECT   hrm_employee_id, main_id, division, dic_department_id, job_code, SUM (val) val,
                              eeb_ratio_group
                     FROM
                              /*
                              Répartition selon nomenclature et répartition groupe
                              */
                              (SELECT b.hrm_employee_id, main_id, eeb_divbase division, dic_department_id,
                                      job_code, eeb_value val, eeb_ratio_group
                               FROM   hrm_formulas_structure e, hrm_tmp_elements_ratio_group dg,
                                      hrm_history_detail_break a, hrm_tmp_history_detail b
                               WHERE  a.hrm_history_detail_id = b.hrm_history_detail_id
                                      AND related_id = b.hrm_elements_id
                                      AND dg.hrm_elements_id = main_id
                                      AND useratiogroup = a.eeb_ratio_group
                               UNION ALL
                               /*
                               Répartition des éléments lié au salaire mensuel
                               lors de versement d'un 13ème dans la période
                               */
                               SELECT aa.hrm_employee_id, main_id hrm_elements_id, aa.div division,
                                      SUBSTR (cg, 1, 2) dic_department_id, SUBSTR (cg, 3, 3) job_code,
                                      hdb_amount val, 1 eeb_ratio_group
                               FROM   (SELECT a.hdb_value_date, a.hrm_break_id, a.hrm_employee_id,
                                              a.hrm_elements_id, a.hdb_source, a.hdb_amount_type,
                                              a.hdb_account_name cg, b.hdb_account_name div, a.hdb_amount
                                       FROM   hrm_tmp_break_detail a, hrm_tmp_history_detail det, hrm_tmp_break_detail b
                                       WHERE  a.hrm_break_id = breakid
                                              AND b.hrm_break_id = breakid
                                              AND a.hrm_elements_id = det.hrm_elements_id
                                              AND det.hrm_history_detail_id = a.hrm_history_detail_id
                                              AND a.hrm_history_detail_id = b.hrm_history_detail_id
                                              AND a.hrm_employee_id = personid
                                              AND a.hdb_source = b.hdb_source
                                              AND a.hdb_amount_type = b.hdb_amount_type
                                              AND det.hrm_elements_id = 2798
                                              AND a.dic_account_type_id = 'CG'
                                              AND b.dic_account_type_id = 'DIV') aa,
                                      hrm_formulas_structure e
                               WHERE  related_id = 1881
                                --AND relation_type = 1
                              ) a
                     -- Cem13èSalai
                     GROUP BY hrm_employee_id, main_id, division, dic_department_id, job_code, eeb_ratio_group) a,
                    (SELECT   main_id, SUM (val) val
                     FROM     (SELECT main_id, eeb_value val
                               FROM   hrm_formulas_structure e, hrm_tmp_elements_ratio_group dg,
                                      hrm_history_detail_break a, hrm_tmp_history_detail b
                               WHERE  a.hrm_history_detail_id = b.hrm_history_detail_id
                                      AND related_id = b.hrm_elements_id
                                      AND main_id = dg.hrm_elements_id
                                      --AND relation_type = 1
                                      AND useratiogroup = a.eeb_ratio_group
                               UNION ALL
                               SELECT main_id hrm_elements_id, hdb_amount val
                               FROM   (SELECT a.hdb_amount
                                       FROM   hrm_tmp_break_detail a, hrm_tmp_history_detail det
                                       WHERE  a.hrm_break_id = breakid
                                              AND det.hrm_history_detail_id = a.hrm_history_detail_id
                                              AND det.hrm_elements_id = 2798) aa,
                                      hrm_formulas_structure
                               WHERE  related_id = 1881)                                              -- Cem13èSalai
                     GROUP BY main_id) b
             WHERE  a.main_id = b.main_id) c,
            hrm_tmp_history_detail b, hrm_tmp_elements_break_v1 a
     WHERE  a.hrm_elements_id = b.hrm_elements_id
            AND b.hrm_elements_id = c.main_id
            AND NOT EXISTS (SELECT 1
                            FROM   hrm_tmp_break_detail t
                            WHERE  hrm_break_id = breakid AND b.hrm_history_detail_id = t.hrm_history_detail_id);
end;

/**
* Répartition des éléments par division selon les groupes.
*/
procedure insert_pass05(breakid NUMBER, defaultcurrency NUMBER, personid NUMBER)
is
begin
  INSERT INTO hrm_tmp_break_detail
              (hrm_break_id, hrm_elements_id, hrm_employee_id, dic_account_type_id, hdb_amount, hdb_account_name,
               hdb_amount_type, hrm_history_detail_id, hdb_source, acs_financial_currency_id, hdb_is_exported,
               hdb_foreign_value, hdb_ref_value, hdb_zl)
     SELECT breakid, b.hrm_elements_id, personid, account_type,
            (ROUND ((his_pay_sum_val * val / total / 0.05) + 0.4999)) * 0.05 break_value,
            CASE
               WHEN account_type = 'CG' AND amount_type = 'D'
                  THEN NVL (TO_CHAR (TO_NUMBER (base)
                                     + DECODE (shift,
                                               100, TO_NUMBER (NVL (dic_department_id, 0)) * 1000,
                                               500, TO_NUMBER (NVL (dic_department_id, 0)) * 1000
                                                + TO_NUMBER (NVL (job_code, 0)),
                                               0
                                              )),
                            '99999')
               WHEN account_type = 'DIV' AND amount_type = 'D'
                  THEN NVL (NVL (base, division), '000')
               WHEN account_type = 'CG' AND amount_type = 'C'
                  THEN NVL (TO_CHAR (TO_NUMBER (base)
                                     + DECODE (shift,
                                               100, TO_NUMBER (NVL (dic_department_id, 0)) * 1000,
                                               500, TO_NUMBER (NVL (dic_department_id, 0)) * 1000
                                                + TO_NUMBER (NVL (job_code, 0)),
                                               0
                                              )),
                            '99999')
               WHEN account_type = 'DIV' AND amount_type = 'C'
                  THEN NVL (NVL (base, division), '000')
            END account_name,
            amount_type, hrm_history_detail_id, SOURCE, NVL (acs_financial_currency_id, defaultcurrency), 0, 0, 0,
            his_zl
     FROM   (SELECT   TO_CHAR (personid) || '-' || TO_CHAR (c.hrm_elements_id) || '/'
                      || TO_CHAR (eeb_divbase) || '/' || TO_CHAR (dic_department_id) || '/'
                      || TO_CHAR (job_code) SOURCE,
                      c.hrm_elements_id, eeb_divbase division, dic_department_id, job_code, SUM (eeb_value) val
             FROM     hrm_tmp_elements_ratio_group dg, hrm_history_detail_break a, hrm_elements c,
                      hrm_tmp_history_detail b
             WHERE    c.hrm_elements_id = dg.hrm_elements_id
                      AND useratiogroup = eeb_ratio_group
                      AND a.hrm_history_detail_id = b.hrm_history_detail_id
             GROUP BY eeb_divbase, dic_department_id, job_code, c.hrm_elements_id) c,
            (SELECT   d.hrm_elements_id, SUM (eeb_value) total
             FROM     hrm_tmp_elements_ratio_group dg, hrm_history_detail_break a, hrm_elements d,
                      hrm_tmp_history_detail b
             WHERE    d.hrm_elements_id = dg.hrm_elements_id
                      AND useratiogroup = eeb_ratio_group
                      AND a.hrm_history_detail_id = b.hrm_history_detail_id
             GROUP BY d.hrm_elements_id) tot,
            hrm_tmp_history_detail b, hrm_tmp_elements_break_v1 a
     WHERE  a.hrm_elements_id = b.hrm_elements_id
            AND b.hrm_elements_id = c.hrm_elements_id
            AND tot.hrm_elements_id = c.hrm_elements_id
            AND NOT EXISTS (SELECT 1
                            FROM   hrm_tmp_break_detail t
                            WHERE  hrm_break_id = breakid AND t.hrm_history_detail_id = b.hrm_history_detail_id);
end;

/*
Répartition du reste selon les comptes et division saisies sur l'élément
*/
procedure insert_pass06(breakid NUMBER, defaultcurrency NUMBER, personid NUMBER)
is
begin
  INSERT INTO hrm_tmp_break_detail
              (hrm_break_id, hrm_elements_id, hrm_employee_id, dic_account_type_id, hdb_amount, hdb_account_name,
               hdb_amount_type, hrm_history_detail_id, hdb_source, acs_financial_currency_id, hdb_is_exported,
               hdb_foreign_value, hdb_ref_value, hdb_zl)
     SELECT breakid, b.hrm_elements_id, personid, account_type, his_pay_sum_val break_value,
            CASE
               WHEN account_type = 'CG' AND amount_type = 'D'
                  THEN NVL (base, '99999')
               WHEN account_type = 'CG' AND amount_type = 'C'
                  THEN NVL (base, '99999')
               WHEN account_type = 'DIV' AND amount_type = 'D'
                  THEN NVL (base, '000')
               WHEN account_type = 'DIV' AND amount_type = 'C'
                  THEN NVL (base, '000')
            END account_name,
            amount_type, hrm_history_detail_id, TO_CHAR (hrm_history_detail_id) SOURCE,
            NVL (acs_financial_currency_id, defaultcurrency), 0, 0, 0, his_zl
     FROM   hrm_tmp_elements_break_v1 a, hrm_tmp_history_detail b
     WHERE  a.hrm_elements_id = b.hrm_elements_id
            AND NOT EXISTS (SELECT 1
                            FROM   hrm_tmp_break_detail t
                            WHERE  hrm_break_id = breakid AND t.hrm_history_detail_id = b.hrm_history_detail_id);
end;

/**
 * Mise à jour après ventilation des employés :
 *  - Arrondi
 *  - Mise à jour de l'historique
 *  - Insertion de la table temporaire dans BreakDetail
 */
procedure UpdateBreakAfter(BreakId number, status number)
is
begin
  /*
  Suppression des ventilations différentes de la ventilation en cours
  */
  DELETE FROM hrm_tmp_break_detail
  WHERE       hrm_break_id <> breakid;

  /*
  Arrondi des montants
  */
  RoundBreak (BreakId);

  /*
  Mise à jour de l'historique avec le statut comptabilisé
  */
  UPDATE hrm_history h
  SET hit_accounted = 2-status -- (1) Définitif et (2) Provisoire
  WHERE hit_accounted = 3 and
      EXISTS (SELECT 1
              FROM   hrm_history_detail d, hrm_tmp_break_detail t
              WHERE  t.hrm_history_detail_id = d.hrm_history_detail_id AND
                     hit_pay_num = his_pay_num AND
                     h.hrm_employee_id = d.hrm_employee_id);

  UPDATE hrm_history_detail d
  SET his_accounted = 2-status -- (1) Définitif et (2) Provisoire
  WHERE  hrm_history_detail_id IN (SELECT hrm_history_detail_id
                                   FROM   hrm_tmp_break_detail t);

  /*
  Insertion de la ventilation en cours dans la table HRM_BREAK_DETAIL
  */
  INSERT INTO hrm_break_detail
              (hrm_break_id, hrm_history_detail_id, hdb_source, dic_account_type_id, hdb_amount_type,
               hrm_employee_id, hrm_elements_id, hdb_account_name, hdb_amount, hdb_zl, hdb_is_exported,
               hdb_ref_value, hdb_foreign_value, acs_financial_currency_id)
     SELECT hrm_break_id, hrm_history_detail_id, hdb_source, dic_account_type_id, hdb_amount_type,
            hrm_employee_id, hrm_elements_id, hdb_account_name, hdb_amount, hdb_zl, hdb_is_exported,
            hdb_ref_value, hdb_foreign_value, acs_financial_currency_id
     FROM   hrm_tmp_break_detail
     WHERE  hrm_break_id = breakid;
end;

/**
 * Procédure de traitement des arrondis
 */
procedure roundbreak(breakid NUMBER)
is
  /**
   * Curseur utilisé pour les diff. d'arrondi
   */
    CURSOR roundpay
    IS
      SELECT   b.hrm_history_detail_id, b.dic_account_type_id, b.hdb_amount_type,
               SUM (hdb_amount) - a.his_pay_sum_val delta,
               SUM (hdb_foreign_value) - a.his_currency_value delta_foreign,
               SUM (hdb_ref_value) - a.his_ref_value delta_ref
      FROM     hrm_history_detail a, hrm_tmp_break_detail b
      WHERE    a.hrm_history_detail_id = b.hrm_history_detail_id AND b.hrm_break_id = breakid
      GROUP BY b.hrm_history_detail_id, b.dic_account_type_id, b.hdb_amount_type, a.his_pay_sum_val,
               a.his_currency_value, a.his_ref_value
      HAVING   (SUM (hdb_amount) <> a.his_pay_sum_val
                OR SUM (hdb_foreign_value) <> a.his_currency_value
                OR SUM (hdb_ref_value) <> a.his_ref_value
               );
begin
   /*
  Ouverture du curseur de correction des arrondis pour les éléments en erreur
  */
  FOR aroundpay IN roundpay
  LOOP
     UPDATE hrm_tmp_break_detail
     SET hdb_amount = NVL (hdb_amount, 0) - NVL (aroundpay.delta, 0),
         hdb_foreign_value = NVL (hdb_foreign_value, 0) - NVL (aroundpay.delta_foreign, 0),
         hdb_ref_value = NVL (hdb_ref_value, 0) - NVL (aroundpay.delta_ref, 0)
     WHERE  hrm_break_id = breakid
            AND hrm_history_detail_id = aroundpay.hrm_history_detail_id
            AND dic_account_type_id = aroundpay.dic_account_type_id
            AND hdb_amount_type = aroundpay.hdb_amount_type
            AND hdb_source =
                  (SELECT MIN (hdb_source)
                   FROM   hrm_tmp_break_detail
                   WHERE  hrm_history_detail_id = aroundpay.hrm_history_detail_id
                          AND dic_account_type_id = aroundpay.dic_account_type_id
                          AND hdb_amount_type = aroundpay.hdb_amount_type
                          AND hrm_break_id = breakid);
  END LOOP;

  -- Mise à jour des inversions et permutations
  -- Fait après l'arrondi pour corriger le cas de la ventilation avec un groupe de répartition
  -- lorsqu'un des genres salaires a un montant négatif
  UPDATE hrm_tmp_break_detail b
  SET (hdb_amount_type, hdb_amount, hdb_foreign_value, hdb_ref_value) =
         (SELECT
                 -- Si la permutation est coché, et qu'après inversion on se retrouve en négatif,
                 -- il faut permuter D et C
                 DECODE (NVL (e.ele_swap_dc, 0),
                         1, DECODE (DECODE (NVL (e.ele_is_break_inverse, 0), 1, -1, 1),
                                    SIGN (hdb_amount), hdb_amount_type,         -- Si permutation et inversion et signe négatif au départ pas de changement
                                    DECODE (hdb_amount_type, 'D', 'C', 'D')     -- Si permutation et inversion et signe positif -> changement de côté
                                   ),                                           -- Si pas permutation et signe négatif -> changement de côté
                         hdb_amount_type
                        ),

                 -- Changer le signe des montants, en fonction de la permutation et de l'inversion
                 DECODE (NVL (e.ele_swap_dc, 0),
                         0, DECODE (NVL (e.ele_is_break_inverse, 0), 1, hdb_amount * -1, hdb_amount),
                         ABS (hdb_amount)
                        ),
                 DECODE (NVL (e.ele_swap_dc, 0),
                         0, DECODE (NVL (e.ele_is_break_inverse, 0), 1, hdb_foreign_value * -1, hdb_foreign_value),
                         ABS (hdb_foreign_value)
                        ),
                 DECODE (NVL (e.ele_swap_dc, 0),
                         0, DECODE (NVL (e.ele_is_break_inverse, 0), 1, hdb_ref_value * -1, hdb_ref_value),
                         ABS (hdb_ref_value)
                        )
          FROM   hrm_elements e
          WHERE  e.hrm_elements_id = b.hrm_elements_id)
  WHERE  hrm_break_id = breakid
         AND EXISTS (SELECT 1
                     FROM   hrm_elements e
                     WHERE  (ele_is_break_inverse = 1 OR ele_swap_dc = 1) AND e.hrm_elements_id = b.hrm_elements_id);
end;

/**
 * Gestion des erreurs, insertions dans HRM_ERRORS_LOG
 * Contrôles :
 *   - Parité par employé
 *   - Eléments non arrondis
 *   - Employés manquants
 */
procedure controlbreak(breakid NUMBER)
is
begin
  DELETE FROM hrm_errors_log
  WHERE       elo_type IN (2, 3);

  INSERT INTO hrm_errors_log
              (hrm_employee_id, hrm_elements_id, elo_message, elo_date, elo_type)
     SELECT   TO_NUMBER(NULL), TO_NUMBER(NULL),
              pcs.pc_public.translateword('La ventilation est vide !'),
              SysDate, 3
     FROM     DUAL
     WHERE NOT EXISTS (SELECT 1 FROM HRM_BREAK_DETAIL
                       WHERE HRM_BREAK_ID = BreakId)
     UNION ALL
     SELECT   hrm_employee_id, TO_NUMBER (NULL),
              pcs.pc_public.translateword ('Différence débit/crédit') || ' : '
              || TO_CHAR (SUM (debit_amount - credit_amount)),
              SYSDATE, 3
     FROM     v_hrm_break_cg_div
     WHERE    hrm_break_id = breakid
     GROUP BY hrm_employee_id
     HAVING   SUM (debit_amount - credit_amount) <> 0
     UNION ALL
     SELECT hrm_employee_id, e.hrm_elements_id, pcs.pc_public.translateword ('Elément non arrondi'), SYSDATE, 3
     FROM   hrm_break_detail b, hrm_elements e
     WHERE  e.hrm_elements_id = b.hrm_elements_id AND
            b.hrm_break_id = breakid AND
            TRUNC (hdb_amount, 2) <> hdb_amount;
end;

END HRM_BREAKDOWN_V1;
