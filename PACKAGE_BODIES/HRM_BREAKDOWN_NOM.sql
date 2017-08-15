--------------------------------------------------------
--  DDL for Package Body HRM_BREAKDOWN_NOM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_BREAKDOWN_NOM" 
IS
   /* Monnaie HRM */
   g_currencyid     acs_financial_currency.acs_financial_currency_id%TYPE;
   /* Type d'arrondi de la monnaie HRM */
   g_roundtype      char;
   /* Montant arrondi de la monnaie HRM */
   g_round          ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%TYPE;

   /* Collection de l'ordre des groupes de répartition */
   TYPE t_break_group IS TABLE OF PLS_INTEGER
                            INDEX BY hrm_break_group.bre_description%TYPE;

   gt_break_group   t_break_group;

   /* Collection des décomptes salaires */
   TYPE t_history IS TABLE OF hrm_history%ROWTYPE
                        INDEX BY PLS_INTEGER;

   TYPE t_root IS RECORD
   (
      hrm_elements_root_id        NUMBER,
      acs_financial_currency_id   NUMBER,
      elr_swap_dc                 INTEGER,
      elr_is_break_inverse        INTEGER
   );

   /* Collection des détails de décomptes */
   TYPE r_history_detail IS RECORD
   (
      hrm_elements_id             hrm_elements_family.hrm_elements_id%TYPE,
      his_pay_sum_val             hrm_history_detail.his_pay_sum_val%TYPE,
      his_currency_value          hrm_history_detail.his_currency_value%TYPE,
      his_ref_value               hrm_history_detail.his_ref_value%TYPE,
      hrm_history_detail_id       hrm_history_detail.hrm_history_detail_id%TYPE,
      break_order                 VARCHAR2 (10),
      hrm_break_group_id          hrm_elements_family.hrm_break_group_id%TYPE,
      acs_financial_currency_id   acs_financial_currency.acs_financial_currency_id%TYPE,
      shift_used                  PLS_INTEGER,
      his_zl                      hrm_history_detail.his_zl%TYPE,
      elr_is_break_inverse        hrm_elements_root.elr_is_break_inverse%TYPE,
      elr_swap_dc                 hrm_elements_root.elr_swap_dc%TYPE
   );

   TYPE t_history_detail IS TABLE OF r_history_detail
                               INDEX BY PLS_INTEGER;

   /* Collection des comptes après déplacement */
   TYPE r_account_by_source IS RECORD
   (
      heb_ratio          hrm_employee_break.heb_ratio%TYPE,
      sab_source         hrm_salary_breakdown.sab_source%TYPE,
      hdb_account_name   hrm_salary_breakdown.sab_account_name%TYPE,
      eeb_d_cgbase       hrm_history_detail_break.eeb_d_cgbase%TYPE,
      eeb_c_cgbase       hrm_history_detail_break.eeb_c_cgbase%TYPE
   );

   TYPE t_account_by_source IS TABLE OF r_account_by_source
                                  INDEX BY PLS_INTEGER;

   /* collection des clés de répartition */
   TYPE r_break_data IS RECORD
   (
      heb_ratio           hrm_employee_break.heb_ratio%TYPE,
      heb_department_id   hrm_employee_break.heb_department_id%TYPE,
      heb_div_number      hrm_employee_break.heb_div_number%TYPE,
      heb_cda_number      hrm_employee_break.heb_cda_number%TYPE,
      heb_cpn_number      hrm_employee_break.heb_cpn_number%TYPE,
      heb_pf_number       hrm_employee_break.heb_pf_number%TYPE,
      heb_pj_number       hrm_employee_break.heb_pj_number%TYPE,
      heb_shift           hrm_employee_break.heb_shift%TYPE,
      heb_source          hrm_salary_breakdown.sab_source%TYPE,
      heb_rco_title       hrm_employee_break.heb_rco_title%TYPE,
      eeb_d_cgbase        hrm_history_detail_break.eeb_d_cgbase%TYPE,
      eeb_c_cgbase        hrm_history_detail_break.eeb_c_cgbase%TYPE
   );

   TYPE t_break_data IS TABLE OF r_break_data
                           INDEX BY PLS_INTEGER;

   /* Collection des détails des méthodes de ventilation */
   TYPE r_break_structure IS RECORD
   (
      ald_acc_name          hrm_allocation_detail.ald_acc_name%TYPE,
      ald_rate              hrm_allocation_detail.ald_acc_name%TYPE,
      dic_account_type_id   hrm_allocation_detail.dic_account_type_id%TYPE,
      hrm_break_shift_id    hrm_allocation_detail.hrm_break_shift_id%TYPE,
      allocation_id         hrm_allocation.hrm_allocation_id%TYPE,
      default_break_data    PLS_INTEGER
   );

   TYPE t_break_structure IS TABLE OF r_break_structure
                                INDEX BY PLS_INTEGER;


   FUNCTION root_prop (in_elemid IN HRM_ELEMENTS_FAMILY.HRM_ELEMENTS_ID%TYPE)
      RETURN t_root
      RESULT_CACHE RELIES_ON (HRM_ELEMENTS_ROOT)
   IS
      lr_result   t_root;
   BEGIN
      SELECT r.hrm_elements_root_id,
             acs_financial_currency_id,
             elr_swap_dc,
             elr_is_break_inverse
        INTO lr_result
        FROM hrm_elements_root r
       where hrm_elements_root_id = in_elemId;

      RETURN lr_result;
   END root_prop;

   /****************************************************************************
    * Procédure de traitement des arrondis
    ***************************************************************************/

   PROCEDURE RoundBreak (in_breakid IN hrm_break.hrm_break_id%TYPE, in_status IN INTEGER)
   IS
   BEGIN
      NULL;
   END;


   /****************************************************************************
    * Fonction des arrondis
    ***************************************************************************/
   FUNCTION RoundNear (aValue IN NUMBER, aRound IN NUMBER, aMode IN NUMBER DEFAULT 0)
      RETURN NUMBER
      DETERMINISTIC
   IS
      Divide1   NUMBER;
      Divide2   NUMBER;
      tmpVal    NUMBER;
   BEGIN
      tmpVal := ROUND (aValue);

      IF aRound > 0
      THEN
         Divide1 := aValue / aRound;
         Divide2 := ROUND (Divide1);

         IF aMode = 0
         THEN
            tmpVal := Divide2 * aRound;
         ELSE
            IF aMode = -1
            THEN
               IF Divide2 - Divide1 <= 0
               THEN
                  tmpVal := Divide2 * aRound;
               ELSE
                  tmpVal := (Divide2 - 1) * aRound;
               END IF;
            ELSE
               IF aMode = 1
               THEN
                  IF Divide2 - Divide1 < 0
                  THEN
                     tmpVal := (Divide2 + 1) * aRound;
                  ELSE
                     tmpVal := Divide2 * aRound;
                  END IF;
               ELSE
                  tmpVal := Divide2 * aRound;
               END IF;
            END IF;
         END IF;
      END IF;

      RETURN tmpVal;
   END RoundNear;

   /*****************************************************************************

    Procédure d'arrondi des montants en fonction de la configuration de la monnaie

   *****************************************************************************/
   FUNCTION rounded_value (in_amount IN hrm_history_detail.his_pay_sum_val%TYPE, in_roundtype in char, in_round in ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%TYPE)
      RETURN hrm_history_detail.his_pay_sum_val%TYPE
      DETERMINISTIC
   IS
      ln_result   hrm_history_detail.his_pay_sum_val%TYPE;
   BEGIN
      IF in_roundtype = '0'
      THEN
         ln_result := TRUNC (in_amount, 2);                                                                       -- Pas d'arrondi
      ELSIF in_roundtype = '1'
      THEN
         ln_result := RoundNear (in_amount, 0.05, 0);                                                        -- Arrondi commercial
      ELSIF in_roundtype = '2'
      THEN
         ln_result := RoundNear (in_amount, in_round, -1);                                                     -- Arrondi inférieur
      ELSIF in_roundtype = '3'
      THEN
         ln_result := RoundNear (in_amount, in_round, 0);                                                   -- Arrondi au plus près
      ELSIF in_roundtype = '4'
      THEN
         ln_result := RoundNear (in_amount, in_round, 1);                                                      -- Arrondi supérieur
      ELSE
         ln_result := TRUNC (in_amount, 2);
      END IF;

      RETURN ln_result;
   END rounded_value;


   /******************************************************************************

   Retourne l'ordre de passage du groupe de répartition

   ******************************************************************************/
   FUNCTION break_group_order (iv_bre_description IN hrm_break_group.bre_description%TYPE)
      RETURN VARCHAR2
      result_cache
   IS
   BEGIN
      IF iv_bre_description IS NULL
      THEN
         RETURN '999';
      ELSE
         RETURN LPAD (TO_CHAR (gt_break_group (iv_bre_description)), 3, '0');
      END IF;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         RETURN NVL (iv_bre_description, '999');
   END;


   /* Fonction indiquant s'il y a déplacement ou non */

   /****************************************************************************
    Procédure d'initialisation de la ventilation
      Suppression des ventilations provisoires
      Vider la table temporaire
   *****************************************************************************/
   PROCEDURE BreakInit (in_breakid IN hrm_break.hrm_break_id%TYPE)
   IS
      CURSOR init_break_order
      IS
             SELECT MAX (LEVEL) ordre, bre_description
               FROM hrm_break_group b,
                    hrm_break_group_root r,
                    hrm_elements_family f1,
                    hrm_elements_family f2
              WHERE     r.hrm_elements_root_id = f1.hrm_elements_root_id
                    AND b.hrm_break_group_id = r.hrm_break_group_id
                    AND f1.elf_is_reference = 1
                    AND f2.hrm_break_group_id = r.hrm_break_group_id
                    AND f2.elf_is_reference = 1
         CONNECT BY NOCYCLE PRIOR f1.hrm_elements_id = f2.hrm_elements_id
           GROUP BY bre_description, b.hrm_break_group_id
           ORDER BY 1 DESC;
   BEGIN
      FOR tplProvBreak IN (SELECT hrm_break_id
                             FROM hrm_break
                            WHERE brk_status = 0 AND hrm_break_id <> in_breakid)
      LOOP
         DELETE FROM hrm_salary_breakdown
               WHERE hrm_break_id = tplProvBreak.hrm_break_id;

         DELETE FROM hrm_break
               WHERE hrm_break_id = tplProvBreak.hrm_break_id;
      END LOOP;

      delete from hrm_tmp_break_detail;

      -- Définition de l'ordre des groupes de répartition
      FOR tpl_break IN init_break_order
      LOOP
         gt_break_group (tpl_break.bre_description) := tpl_break.ordre;
      END LOOP;
   END BreakInit;



   /*****************************************************************************
   Retourne les données de comptabilisation de l'employé

   *****************************************************************************/
   FUNCTION employee_break_data (in_empid IN hrm_person.hrm_person_id%TYPE)
      RETURN t_break_data
   IS
      lt_result   t_break_data;
      ln_x        PLS_INTEGER := 0;
   BEGIN
      /*
      Recherche de données de comptabilisation sur l'employé
      */
      FOR x IN (SELECT heb_ratio * 100 / SUM (heb_ratio) OVER () heb_ratio,
                       heb_department_id,
                       heb_div_number,
                       heb_cda_number,
                       heb_cpn_number,
                       heb_pf_number,
                       heb_pj_number,
                       heb_shift,
                       hrm_employee_break_id heb_source,
                       rco_title heb_rco_title
                  FROM v_hrm_empl_break
                 WHERE hrm_employee_id = in_empid)
      LOOP
         ln_x := ln_x + 1;
         lt_result (ln_x).heb_ratio := x.heb_ratio;
         lt_result (ln_x).heb_div_number := x.heb_div_number;
         lt_result (ln_x).heb_source := x.heb_source;
         lt_result (ln_x).heb_cda_number := x.heb_cda_number;
         lt_result (ln_x).heb_cpn_number := x.heb_cpn_number;
         lt_result (ln_x).heb_pf_number := x.heb_pf_number;
         lt_result (ln_x).heb_pj_number := x.heb_pj_number;
         lt_result (ln_x).heb_rco_title := x.heb_rco_title;
         lt_result (ln_x).heb_shift := x.heb_shift;
         lt_result (ln_x).heb_department_id := x.heb_department_id;
      END LOOP;


      RETURN lt_result;
   END employee_break_data;


   /*****************************************************************************
   Retourne les données de comptabilisation PAR DEFAUT de l'employé

   *****************************************************************************/
   FUNCTION employee_break_default_datas (in_empid IN hrm_person.hrm_person_id%TYPE)
      RETURN t_break_data
   IS
      lt_result   t_break_data;
      ln_x        PLS_INTEGER := 0;
   BEGIN
      FOR x IN (SELECT heb_ratio * 100 / SUM (heb_ratio) OVER () heb_ratio,
                       heb_department_id,
                       heb_div_number,
                       heb_cda_number,
                       heb_cpn_number,
                       heb_pf_number,
                       heb_pj_number,
                       heb_shift,
                       hrm_employee_break_id heb_source,
                       heb_rco_title,
                       NULL eeb_d_cgbase,
                       NULL eeb_c_cgbase
                  FROM hrm_employee_break
                 WHERE hrm_employee_id = in_empid AND heb_default_flag = 1)
      LOOP
         ln_x := ln_x + 1;
         lt_result (ln_x).heb_ratio := x.heb_ratio;
         lt_result (ln_x).heb_div_number := x.heb_div_number;
         lt_result (ln_x).heb_source := x.heb_source;
         lt_result (ln_x).heb_cda_number := x.heb_cda_number;
         lt_result (ln_x).heb_cpn_number := x.heb_cpn_number;
         lt_result (ln_x).heb_pf_number := x.heb_pf_number;
         lt_result (ln_x).heb_pj_number := x.heb_pj_number;
         lt_result (ln_x).heb_rco_title := x.heb_rco_title;
         lt_result (ln_x).heb_shift := x.heb_shift;
         lt_result (ln_x).heb_department_id := x.heb_department_id;
      END LOOP;

      RETURN lt_result;
   END employee_break_default_datas;


   /******************************************************************************
   Retourne les données de comptabilisation du détail de l'historique
   Ces données priment sur tout le reste
   Si un poste est mentionné, ce sont les données liées au poste qui sont prise en compte
   à défaut d'une saisie directe des données.
   ******************************************************************************/
   FUNCTION history_detail_break_datas (in_historydetailid IN hrm_history_detail.hrm_history_detail_id%TYPE)
      RETURN t_break_data
   IS
      lt_result   t_break_data;
      ln_x        PLS_INTEGER := 0;
   BEGIN
      FOR x IN (SELECT eeb_value * 100 / SUM (eeb_value) OVER () heb_ratio,
                       dic_department_id heb_department_id,
                       eeb_cpnbase heb_cpn_number,
                       eeb_divbase heb_div_number,
                       eeb_cdabase heb_cda_number,
                       eeb_pfbase heb_pf_number,
                       eeb_pjbase heb_pj_number,
                       eeb_shift heb_shift,
                       TO_CHAR (hrm_history_detail_id) || 'S' || TO_CHAR (eeb_sequence) heb_source,
                       eeb_rco_title heb_rco_title,
                       eeb_d_cgbase,
                       eeb_c_cgbase
                  FROM hrm_history_detail_break
                 WHERE hrm_history_detail_id = in_historydetailid)
      LOOP
         ln_x := ln_x + 1;
         lt_result (ln_x).heb_ratio := x.heb_ratio;
         lt_result (ln_x).heb_div_number := x.heb_div_number;
         lt_result (ln_x).heb_source := x.heb_source;
         lt_result (ln_x).heb_cda_number := x.heb_cda_number;
         lt_result (ln_x).heb_cpn_number := x.heb_cpn_number;
         lt_result (ln_x).heb_pf_number := x.heb_pf_number;
         lt_result (ln_x).heb_pj_number := x.heb_pj_number;
         lt_result (ln_x).heb_rco_title := x.heb_rco_title;
         lt_result (ln_x).heb_shift := x.heb_shift;
         lt_result (ln_x).heb_department_id := x.heb_department_id;
      END LOOP;


      RETURN lt_result;
   END history_detail_break_datas;



   /*******************************************************************************
   Retourne le détail de l'historique à comptabiliser

   La colonne TYP détermine la manière de comptabiliser ( en direct, selon nomenclature, cas spécial 13e, etc. ). Cette colonne va
   donner l'ordre de pratiquer la ventilation.

   *******************************************************************************/
   FUNCTION history_detail_elements (in_empid IN hrm_person.hrm_person_id%TYPE, in_paynum IN hrm_history.hit_pay_num%TYPE)
      RETURN t_history_detail
   IS
      lt_result   t_history_detail;
      ln_x        PLS_INTEGER := 0;
   BEGIN
      FOR x
         IN (  SELECT f.hrm_elements_root_id,
                      hrm_employee_id,
                      his_pay_num,
                      f.hrm_elements_id,
                      his_pay_sum_val,
                      his_currency_value,
                      his_ref_value,
                      hrm_history_detail_id,
                      d.acs_financial_currency_id,
                      CASE
                         WHEN EXISTS
                                 (SELECT 1
                                    FROM hrm_history_detail_break b
                                   WHERE b.hrm_history_detail_id = d.hrm_history_detail_id)
                         THEN
                            '6-'
                         WHEN EXISTS
                                 (SELECT 1
                                    FROM hrm_break_group_root g
                                   WHERE f.hrm_elements_root_id = g.hrm_elements_root_id)
                         THEN
                            '5-'
                            || (SELECT MAX (break_group_order (bre_description))
                                  FROM hrm_break_group_root
                                 WHERE f.hrm_elements_root_id = hrm_elements_root_id)
                         WHEN f.hrm_break_group_id IS NOT NULL
                         THEN
                            '1-' || break_group_order (g.bre_description)
                         ELSE
                            '4-'
                      END
                         typ,
                      g.hrm_break_group_id,
                      CASE
                         WHEN EXISTS
                                 (SELECT 1
                                    FROM hrm_allocation_detail dal, hrm_break_shift sh
                                   WHERE     dal.hrm_break_shift_id = sh.hrm_break_shift_id
                                         AND s.hrm_allocation_id = dal.hrm_allocation_id
                                         AND brs_source_field IS NOT NULL)
                         THEN
                            1
                         ELSE
                            0
                      END
                         shift_used,
                      his_zl
                 FROM hrm_elements_family f,
                      hrm_history_detail d,
                      hrm_break_group g,
                      hrm_break_structure s
                WHERE     hrm_employee_id = in_empid
                      AND his_pay_num = in_paynum
                      AND bre_item_id = d.hrm_elements_id
                      AND f.hrm_break_group_id = g.hrm_break_group_id(+)
                      AND bre_item_id = f.hrm_elements_id
             ORDER BY typ DESC)
      LOOP
         ln_x := ln_x + 1;
         lt_result (ln_x).hrm_elements_id := x.hrm_elements_id;
         lt_result (ln_x).his_pay_sum_val := x.his_pay_sum_val;
         lt_result (ln_x).his_currency_value := x.his_currency_value;
         lt_result (ln_x).his_ref_value := x.his_ref_value;
         lt_result (ln_x).hrm_history_detail_id := x.hrm_history_detail_id;
         lt_result (ln_x).break_order := x.typ;
         lt_result (ln_x).hrm_break_group_id := x.hrm_break_group_id;
         lt_result (ln_x).acs_financial_currency_id := root_prop(x.hrm_elements_root_id).acs_financial_currency_id;
         lt_result (ln_x).shift_used := x.shift_used;
         lt_result (ln_x).his_zl := x.his_zl;
         lt_result (ln_x).elr_is_break_inverse := root_prop(x.hrm_elements_root_id).elr_is_break_inverse;
         lt_result (ln_x).elr_swap_dc := root_prop(x.hrm_elements_root_id).elr_swap_dc;
      END LOOP;

      RETURN lt_result;
   END history_detail_elements;



   /*******************************************************************************
   Retourne les données de la méthode de ventilation de l'élément en paramètre
   *******************************************************************************/
   FUNCTION break_structure (in_elemid IN hrm_elements_family.hrm_elements_id%TYPE)
      RETURN t_break_structure
      RESULT_CACHE RELIES_ON (HRM_BREAK_STRUCTURE, HRM_ALLOCATION_DETAIL, HRM_ALLOCATION)
   IS
      lt_result   t_break_structure;
      ln_x        PLS_INTEGER := 0;
   BEGIN
      FOR x
         IN (SELECT ald_acc_name,
                    ald_rate,
                    dic_account_type_id,
                    hrm_break_shift_id,
                    d.hrm_allocation_id,
                    CASE WHEN INSTR (UPPER (all_code), '[DEFAULT]') > 0 THEN 1 ELSE 0 END default_break_data
               FROM hrm_allocation a, hrm_allocation_detail d, hrm_break_structure s
              WHERE     d.hrm_allocation_id = s.hrm_allocation_id
                    AND s.bre_item_id = in_elemid
                    AND a.hrm_allocation_id = d.hrm_allocation_id)
      LOOP
         ln_x := ln_x + 1;
         lt_result (ln_x).ald_acc_name := x.ald_acc_name;
         lt_result (ln_x).ald_rate := x.ald_rate;
         lt_result (ln_x).dic_account_type_id := x.dic_account_type_id;
         lt_result (ln_x).hrm_break_shift_id := x.hrm_break_shift_id;
         lt_result (ln_x).allocation_id := x.hrm_allocation_id;
         lt_result (ln_x).default_break_data := x.default_break_data;
      END LOOP;

      RETURN lt_result;
   END break_structure;



   /*******************************************************************************
   Retourne les données de comptabilisation selon les groupes de répartition

   Les données prises en considération sont celles qui sont déjà ventilées, il faut
   donc prendre garde à l'ordre de passage des groupes.
   *******************************************************************************/
   FUNCTION break_datas_by_links (in_empid          IN hrm_person.hrm_person_id%TYPE,
                                  in_paynum         IN hrm_history.hit_pay_num%TYPE,
                                  in_breakgroupid   IN hrm_break_group.hrm_break_group_id%TYPE)
      RETURN t_break_data
   IS
      lt_result   t_break_data;
      ln_x        PLS_INTEGER := 0;
   BEGIN
      FOR x IN (  SELECT heb_ratio * 100 / SUM (heb_ratio) OVER () heb_ratio,
                         heb_div_number,
                         heb_cda_number,
                         heb_cpn_number,
                         heb_pf_number,
                         heb_pj_number,
                         TO_CHAR (in_breakgroupid) || '-' || ROWNUM heb_source,
                         heb_rco_title
                    FROM (  SELECT SUM (heb_ratio) heb_ratio,
                                   heb_div_number,
                                   heb_cda_number,
                                   heb_cpn_number,
                                   heb_pf_number,
                                   heb_pj_number,
                                   heb_rco_title
                              FROM (  SELECT ABS (hdb_amount) * SIGN (SUM (his_pay_sum_val)) heb_ratio,
                                             MAX (CASE WHEN dic_account_type_id = 'DIV' THEN hdb_account_name ELSE ' ' END)
                                                heb_div_number,
                                             MAX (CASE WHEN dic_account_type_id = 'CDA' THEN hdb_account_name ELSE ' ' END)
                                                heb_cda_number,
                                             MAX (CASE WHEN dic_account_type_id = 'PF' THEN hdb_account_name ELSE ' ' END)
                                                heb_pf_number,
                                             MAX (CASE WHEN dic_account_type_id = 'PJ' THEN hdb_account_name ELSE ' ' END)
                                                heb_pj_number,
                                             MAX (CASE WHEN dic_account_type_id = 'CPN' THEN hdb_account_name ELSE ' ' END)
                                                heb_cpn_number,
                                             MAX (CASE WHEN dic_account_type_id = 'DOC_RECORD' THEN hdb_account_name ELSE ' ' END)
                                                heb_rco_title
                                        FROM hrm_tmp_break_detail b,
                                             hrm_break_group_root s,
                                             hrm_history_detail d,
                                             hrm_elements_root r,
                                             hrm_elements_family f
                                       WHERE     b.hrm_employee_id = in_empid
                                             AND d.his_pay_num = in_paynum
                                             AND dic_account_type_id NOT IN ('CG', 'CPN')
                                             AND b.hrm_history_detail_id = d.hrm_history_detail_id
                                             AND r.hrm_elements_root_id = s.hrm_elements_root_id
                                             AND s.hrm_break_group_id = in_breakgroupid
                                             AND f.hrm_elements_id = d.hrm_elements_id
                                             AND f.hrm_elements_root_id = r.hrm_elements_root_id
                                    GROUP BY hrm_break_id,
                                             b.hrm_history_detail_id,
                                             hdb_source,
                                             hdb_amount_type,
                                             hdb_amount)
                          GROUP BY heb_div_number,
                                   heb_cda_number,
                                   heb_cpn_number,
                                   heb_pf_number,
                                   heb_pj_number,
                                   heb_rco_title)
                ORDER BY 1, 2, 3)
      LOOP
         ln_x := ln_x + 1;
         lt_result (ln_x).heb_ratio := x.heb_ratio;
         lt_result (ln_x).heb_div_number := x.heb_div_number;
         lt_result (ln_x).heb_source := x.heb_source;
         lt_result (ln_x).heb_cda_number := x.heb_cda_number;
         lt_result (ln_x).heb_cpn_number := x.heb_cpn_number;
         lt_result (ln_x).heb_pf_number := x.heb_pf_number;
         lt_result (ln_x).heb_pj_number := x.heb_pj_number;
         lt_result (ln_x).heb_rco_title := x.heb_rco_title;
      END LOOP;


      RETURN lt_result;
   END break_datas_by_links;



   /*******************************************************************************
   Retourne les comptes en fonction des données des déplacements et du compte de base

   *******************************************************************************/
   FUNCTION accounts (in_breakshift       IN hrm_break_shift.hrm_break_shift_id%TYPE,
                      it_employeebreak    IN t_break_data,
                      iv_aldname          IN hrm_allocation_detail.ald_acc_name%TYPE,
                      iv_dicaccounttype   IN dic_account_type.dic_account_type_id%TYPE,
                      in_allocation_id    IN hrm_allocation.hrm_allocation_id%TYPE)
      RETURN t_account_by_source
   IS
      lt_result           t_account_by_source;
      ln_emp_break_data   PLS_INTEGER;
   BEGIN
      ln_emp_break_data := 0;


      /* Si la valeur de conversion est [NONE] aucun déplacement n'est appliqué
         Sinon, on prend la valeur convertie, voire la valeur source si aucune valeur résultante n'est indiquée
      */
      WHILE ln_emp_break_data < it_employeebreak.COUNT
      LOOP
         ln_emp_break_data := it_employeebreak.NEXT (ln_emp_break_data);

         -- Seules sont prises en compte les valeurs qui respectent les déplacements
         FOR brk_cur
            IN (SELECT shift_value,
                       brs_operation_type,
                       brs_source_field,
                       brs_replacement,
                       DECODE (BSV_VALUE, '[NONE]', ' ', NVL (BSV_VALUE, shift_value)) bsv_value
                  FROM (SELECT v.bsv_value,
                               s.brs_operation_type,
                               s.brs_source_field,
                               s.brs_replacement,
                               CASE s.brs_source_field
                                  WHEN 'HEB_DEPARTMENT_ID' THEN it_employeebreak (ln_emp_break_data).heb_department_id
                                  WHEN 'HEB_DIV_NUMBER' THEN it_employeebreak (ln_emp_break_data).heb_div_number
                                  WHEN 'HEB_CDA_NUMBER' THEN it_employeebreak (ln_emp_break_data).heb_cda_number
                                  WHEN 'HEB_SHIFT' THEN it_employeebreak (ln_emp_break_data).heb_shift
                                  WHEN 'HEB_RCO_TITLE' THEN it_employeebreak (ln_emp_break_data).heb_rco_title
                                  WHEN 'HEB_PF_NUMBER' THEN it_employeebreak (ln_emp_break_data).heb_pf_number
                                  WHEN 'HEB_PJ_NUMBER' THEN it_employeebreak (ln_emp_break_data).heb_pj_number
                                  ELSE NULL
                               END
                                  shift_value,
                               bsv_source_val,
                               bsv_source_val_to
                          FROM hrm_break_shift s, hrm_break_shift_val v
                         WHERE s.hrm_break_shift_id = in_breakshift AND s.hrm_break_shift_id = v.hrm_break_shift_id(+))
                 WHERE                                      /* lpad pour éviter des problèmes numériques/alphanum dans les tris */
                      LPAD (NVL (TRIM (shift_value), '0'), 9, '0') BETWEEN LPAD (bsv_source_val, 9, '0')
                                                                       AND LPAD (bsv_source_val_to, 9, '0')
                       OR brs_source_field IS NULL)
         LOOP
            lt_result (ln_emp_break_data).heb_ratio := it_employeebreak (ln_emp_break_data).heb_ratio;
            lt_result (ln_emp_break_data).sab_source :=
               TO_CHAR (in_allocation_id) || '-' || it_employeebreak (ln_emp_break_data).heb_source;


            -- Construction du déplacement
            BEGIN
               IF     brk_cur.brs_replacement = 'Y'
                  AND iv_dicaccounttype = 'CG'
                  AND it_employeebreak (ln_emp_break_data).eeb_d_cgbase IS NOT NULL
               THEN
                  lt_result (ln_emp_break_data).eeb_d_cgbase := it_employeebreak (ln_emp_break_data).eeb_d_cgbase;
               ELSIF     brk_cur.brs_replacement = 'Y'
                     AND iv_dicaccounttype = 'CG'
                     AND it_employeebreak (ln_emp_break_data).eeb_c_cgbase IS NOT NULL
               THEN
                  lt_result (ln_emp_break_data).eeb_c_cgbase := it_employeebreak (ln_emp_break_data).eeb_c_cgbase;
               ELSE
                  lt_result (ln_emp_break_data).hdb_account_name :=
                     CASE
                        WHEN brk_cur.brs_source_field IS NULL
                        THEN
                           iv_aldname
                        ELSE
                           CASE brk_cur.brs_operation_type
                              WHEN 'CONC'
                              THEN
                                 TRIM (NVL (iv_aldname, ' ') || NVL (brk_cur.bsv_value, NVL (brk_cur.shift_value, ' ')))
                              WHEN 'ADD'
                              THEN
                                 TO_CHAR (NVL (iv_aldname, 0) + coalesce(brk_cur.bsv_value, brk_cur.shift_value,0))
                              WHEN 'PREF'
                              THEN
                                 TRIM (NVL (brk_cur.bsv_value, brk_cur.shift_value) || NVL (iv_aldname, ' '))
                           END
                     END;
               END IF;
            EXCEPTION
               WHEN VALUE_ERROR
               THEN
                  raise_application_error (-20000, 'Problème de valeur numérique...' || brk_cur.brs_operation_type);
            END;
         END LOOP;
      END LOOP;

      -- Si aucune données de comptabilisation fournie
      IF lt_result.COUNT = 0
      THEN
         lt_result (1).heb_ratio := 100;
         lt_result (1).hdb_account_name := iv_aldname;
         lt_result (1).sab_source := in_allocation_id;
      END IF;

      RETURN lt_result;
   END accounts;



   /********************************************************************************

   Procédure de base

   ********************************************************************************/

   PROCEDURE base (in_sheetid IN hrm_history.hrm_salary_sheet_id%TYPE, id_period IN hrm_history.hit_pay_period%TYPE)
   IS
      lt_historysheets   t_history;
      ln_breakid         hrm_break.hrm_break_id%TYPE;
   BEGIN
      /*
      Création de la ventilation si inexistante
      */
      SELECT init_id_seq.NEXTVAL INTO ln_breakid FROM DUAL;


      INSERT INTO hrm_break (hrm_break_id,
                             brk_description,
                             brk_break_date,
                             brk_value_date,
                             hrm_salary_sheet_id)
           VALUES (ln_breakid,
                   'Ventilation ' || TO_CHAR (id_period, 'yyyy.mm.dd'),
                   SYSDATE,
                   id_period,
                   1);

      breakinit (ln_breakid);

      /*
      Boucle sur les décomptes
      */

      FOR x IN (SELECT *
                  FROM hrm_history
                 WHERE hrm_salary_sheet_id = in_sheetid AND hit_pay_period = id_period)
      LOOP
         launchbreak (in_empid      => x.hrm_employee_id,
                      in_paynum     => x.hit_pay_num,
                      in_currency   => g_currencyid,
                      id_period     => x.hit_pay_period,
                      in_breakid    => ln_breakid,
                      in_status     => 0);
      END LOOP;

      controlbreak (ln_breakid, 1);
   END base;


   /********************************************************************************

    Traitement des arrondis et des inversions de signe / côté

   ********************************************************************************/
   PROCEDURE set_breakdown_rows (in_breakid             IN hrm_break.hrm_break_id%TYPE,
                                 in_empid               IN hrm_person.hrm_person_id%TYPE,
                                 it_accounts            IN t_account_by_source,
                                 ir_employeehistory     IN r_history_detail,
                                 iv_dicaccounttype      IN dic_account_type.dic_account_type_id%TYPE,
                                 in_aldrate             IN hrm_allocation_detail.ald_rate%TYPE,
                                 in_elrisbreakinverse   IN hrm_elements_root.elr_is_break_inverse%TYPE)
   IS
      ln_account           PLS_INTEGER;
      lr_break_detail      hrm_tmp_break_detail%ROWTYPE;
      ln_sum_rounded       hrm_history_detail.his_pay_sum_val%TYPE;
      ln_sum_rounded_fc    hrm_history_detail.his_pay_sum_val%TYPE;
      ln_sum_rounded_ref   hrm_history_detail.his_pay_sum_val%TYPE;
   BEGIN
      /*
      Boucle sur les comptes de l'axe
      */
      ln_account := 0;

      ln_sum_rounded := 0;
      ln_sum_rounded_fc := 0;
      ln_sum_rounded_ref := 0;

      WHILE ln_account < it_accounts.COUNT
      LOOP
         ln_account := it_accounts.NEXT (ln_account);

         /*
         Insertion dans la table de contrôle
         */
         lr_break_detail.hrm_break_id := in_breakid;
         lr_break_detail.hrm_history_detail_id := ir_employeehistory.hrm_history_detail_id;
         lr_break_detail.hdb_source := it_accounts (ln_account).sab_source;
         lr_break_detail.dic_account_type_id := iv_dicaccounttype;
         lr_break_detail.hdb_amount_type := NULL;
         lr_break_detail.hrm_employee_id := in_empid;
         lr_break_detail.hrm_elements_id := ir_employeehistory.hrm_elements_id;
         lr_break_detail.hdb_account_name := it_accounts (ln_account).hdb_account_name;
         lr_break_detail.hdb_amount :=
            rounded_value (it_accounts (ln_account).heb_ratio / 100 * ir_employeehistory.his_pay_sum_val, g_roundtype, g_round)
            * (CASE WHEN in_elrisbreakinverse = 1 THEN -1 ELSE 1 END);
         lr_break_detail.hdb_zl := ir_employeehistory.his_zl;
         lr_break_detail.hdb_is_exported := 0;
         lr_break_detail.hdb_ref_value :=
            rounded_value (it_accounts (ln_account).heb_ratio / 100 * NVL (ir_employeehistory.his_ref_value, 0), g_roundtype, g_round)
            * (CASE WHEN in_elrisbreakinverse = 1 THEN -1 ELSE 1 END);
         lr_break_detail.hdb_foreign_value :=
            rounded_value (it_accounts (ln_account).heb_ratio / 100 * NVL (ir_employeehistory.his_currency_value, 0), g_roundtype, g_round)
            * (CASE WHEN in_elrisbreakinverse = 1 THEN -1 ELSE 1 END);

         lr_break_detail.acs_financial_currency_id := ir_employeehistory.acs_financial_currency_id;

         lr_break_detail.hdb_value_date := NULL;


         /*
         Ajustement du montant sur la dernière répartition
         */
         IF ln_account = it_accounts.LAST
         THEN
            lr_break_detail.hdb_amount :=
               (ir_employeehistory.his_pay_sum_val - ln_sum_rounded) * (CASE WHEN in_elrisbreakinverse = 1 THEN -1 ELSE 1 END);
            lr_break_detail.hdb_foreign_value :=
               (NVL (ir_employeehistory.his_currency_value, 0) - ln_sum_rounded_fc)
               * (CASE WHEN in_elrisbreakinverse = 1 THEN -1 ELSE 1 END);
            lr_break_detail.hdb_ref_value :=
               (NVL (ir_employeehistory.his_ref_value, 0) - ln_sum_rounded_ref)
               * (CASE WHEN in_elrisbreakinverse = 1 THEN -1 ELSE 1 END);
         ELSE
            ln_sum_rounded :=
               ln_sum_rounded + rounded_value (it_accounts (ln_account).heb_ratio / 100 * ir_employeehistory.his_pay_sum_val, g_roundtype, g_round);

            ln_sum_rounded_fc :=
               ln_sum_rounded_fc
               + rounded_value (it_accounts (ln_account).heb_ratio / 100 * nvl(ir_employeehistory.his_currency_value,0), g_roundtype, g_round);
            ln_sum_rounded_ref :=
               ln_sum_rounded_ref + rounded_value (it_accounts (ln_account).heb_ratio / 100 * nvl(ir_employeehistory.his_ref_value,0), g_roundtype, g_round);
         END IF;


         /* Insertion dans hrm_tmp_break_detail*/
         IF ir_employeehistory.his_pay_sum_val * it_accounts (ln_account).heb_ratio <> 0
         THEN
            -- Traitement de l'inversion débit/crédit
            lr_break_detail.hdb_amount_type :=
               CASE
                  WHEN SIGN (lr_break_detail.hdb_amount) = -1 AND NVL (ir_employeehistory.elr_swap_dc, 0) = 1
                  THEN
                     CASE in_aldrate WHEN -1 THEN 'D' ELSE 'C' END
                  ELSE
                     CASE in_aldrate WHEN -1 THEN 'C' ELSE 'D' END
               END;
            lr_break_detail.hdb_amount :=
               CASE
                  WHEN SIGN (lr_break_detail.hdb_amount) = -1 AND NVL (ir_employeehistory.elr_swap_dc, 0) = 1
                  THEN
                     ABS (lr_break_detail.hdb_amount)
                  ELSE
                     lr_break_detail.hdb_amount
               END;

            -- Traitement des comptes forcés
            IF lr_break_detail.hdb_amount_type = 'D' AND it_accounts (ln_account).eeb_d_cgbase IS NOT NULL
            THEN
               lr_break_detail.hdb_account_name := it_accounts (ln_account).eeb_d_cgbase;
            ELSIF lr_break_detail.hdb_amount_type = 'C' AND it_accounts (ln_account).eeb_c_cgbase IS NOT NULL
            THEN
               lr_break_detail.hdb_account_name := it_accounts (ln_account).eeb_c_cgbase;
            END IF;

            -- Mise à jour de la monnaie si pas spécifiée dans l'imputation
            IF lr_break_detail.acs_financial_currency_id IS NULL
            THEN
               lr_break_detail.acs_financial_currency_id := g_currencyid;
            END IF;


            INSERT INTO hrm_tmp_break_detail
                 VALUES lr_break_detail;
         END IF;
      END LOOP;
   END;



   /********************************************************************************

   procédure de génération de la ventilation pour un décompte

   ********************************************************************************/
   PROCEDURE launchbreak (in_empid      IN hrm_person.hrm_person_id%TYPE,
                          in_paynum     IN hrm_history.hit_pay_num%TYPE,
                          in_currency   IN acs_financial_currency.acs_financial_currency_id%TYPE,
                          id_period     IN DATE,
                          in_breakid    IN hrm_break.hrm_break_id%TYPE,
                          in_status     IN hrm_break.brk_status%TYPE)
   IS
      lt_emp_break_data         t_break_data;
      ln_emp_break              PLS_INTEGER;
      lt_null_break_data        t_break_data;
      lt_emp_break_default      t_break_data;
      lt_history_detail         t_history_detail;
      ln_historydetail          PLS_INTEGER;
      lr_history_detail         r_history_detail;
      lt_allocation_detail      t_break_structure;
      ln_allocation_detail      PLS_INTEGER;
      lr_allocation_detail      r_break_structure;
      lt_accounts               t_account_by_source;
      lt_history_detail_break   t_break_data;
      lt_break_group            t_break_data;
   BEGIN
      --Obtenir les données de comptabilisation de l'employé
      lt_emp_break_data := employee_break_data (in_empid);
      lt_emp_break_default := employee_break_default_datas (in_empid);
      --Obtenir les éléments calculés à comptabiliser du décompte de l'employé
      lt_history_detail := history_detail_elements (in_empid, in_paynum);

      --Boucle sur les éléments du décompte
      ln_historydetail := 0;

      WHILE ln_historydetail < lt_history_detail.COUNT
      LOOP
         ln_historydetail := lt_history_detail.NEXT (ln_historydetail);

         lr_history_detail := lt_history_detail (ln_historydetail);

         --Recherche de la source des données de comptabilisation ( historique, selon groupe, normal )
         IF lr_history_detail.break_order LIKE '6%'
         THEN
            lt_history_detail_break := history_detail_break_datas (in_historydetailid => lr_history_detail.hrm_history_detail_id);
         ELSIF lr_history_detail.hrm_break_group_id IS NOT NULL
         THEN
            begin
                lt_break_group :=
                   break_datas_by_links (in_empid          => in_empid,
                                         in_paynum         => in_paynum,
                                         in_breakgroupid   => lr_history_detail.hrm_break_group_id);
            exception when zero_divide then
               -- En cas de division par 0, on prend les données de comptabilisation standard de l'employé
               lt_break_group := lt_emp_break_data;
            end;
         END IF;

         -- En case de groupe vide, on prend les données de l'employé
         IF lt_break_group.COUNT = 0
         THEN
            lt_break_group := lt_emp_break_data;
         END IF;

         --Obtenir la méthode de comptabilisation de l'élément
         lt_allocation_detail := break_structure (in_elemid => lr_history_detail.hrm_elements_id);

         /*
         Boucle sur les différents axes et côtés de comptabilisation de l'élément
         */
         ln_allocation_detail := 0;

         WHILE ln_allocation_detail < lt_allocation_detail.COUNT
         LOOP
            ln_allocation_detail := lt_allocation_detail.NEXT (ln_allocation_detail);
            lr_allocation_detail := lt_allocation_detail (ln_allocation_detail);

            /*
            Obtenir les comptes de l'axe en fonction des données de comptabilisation de l'employé
                Fonctions supplémentaires
                    - Comptabilisation en fonction de la nomenclature
                    - Comptabilisation en fonction de données directes ( HistoryDetailBreak )
            */
            IF lr_history_detail.break_order LIKE '6%' AND lt_history_detail_break.COUNT > 0
            THEN
               lt_accounts :=
                  accounts (lr_allocation_detail.hrm_break_shift_id,
                            CASE WHEN lr_history_detail.shift_used = 1 THEN lt_history_detail_break ELSE lt_null_break_data END,
                            lr_allocation_detail.ald_acc_name,
                            lr_allocation_detail.dic_account_type_id,
                            lr_allocation_detail.allocation_id);
            ELSIF SUBSTR (lr_history_detail.break_order, 1, 1) IN ('1', '5') AND lr_history_detail.hrm_break_group_id IS NOT NULL
            THEN
               lt_accounts :=
                  accounts (lr_allocation_detail.hrm_break_shift_id,
                            CASE WHEN lr_history_detail.shift_used = 1 THEN lt_break_group ELSE lt_null_break_data END,
                            lr_allocation_detail.ald_acc_name,
                            lr_allocation_detail.dic_account_type_id,
                            lr_allocation_detail.allocation_id);
            ELSE
               lt_accounts :=
                  accounts (
                     lr_allocation_detail.hrm_break_shift_id,
                     CASE
                        WHEN lr_history_detail.shift_used = 1
                        THEN
                           CASE
                              WHEN lr_allocation_detail.default_break_data = 1 THEN lt_emp_break_default
                              ELSE lt_emp_break_data
                           END
                        ELSE
                           lt_null_break_data
                     END,
                     lr_allocation_detail.ald_acc_name,
                     lr_allocation_detail.dic_account_type_id,
                     lr_allocation_detail.allocation_id);
            END IF;



            /* Insertion des records dans la table temporaire */
            set_breakdown_rows (in_breakid             => in_breakid,
                                in_empid               => in_empid,
                                it_accounts            => lt_accounts,
                                ir_employeehistory     => lr_history_detail,
                                iv_dicaccounttype      => lr_allocation_detail.dic_account_type_id,
                                in_aldrate             => lr_allocation_detail.ald_rate,
                                in_elrisbreakinverse   => lr_history_detail.elr_is_break_inverse);
         END LOOP;
      END LOOP;

      /* Mise à jour du flag ventilé pour le décompte */
      IF in_status = '1'
      THEN
         UPDATE hrm_history
            SET hit_accounted = 1
          WHERE hrm_employee_id = in_empid AND hit_pay_num = in_paynum;
      END IF;
   END launchbreak;



   /*********************************************************************************

    * Migration des données de la table temporaire vers la table standard

    ********************************************************************************/
   PROCEDURE finalize_after_break (in_breakid IN hrm_break.hrm_break_id%TYPE)
   IS
   BEGIN

      /*
      Insertion de la ventilation en cours dans la table HRM_BREAK_DETAIL
      */
      INSERT INTO hrm_salary_breakdown (hrm_break_id,
                                        hrm_history_detail_id,
                                        sab_source,
                                        dic_account_type_id,
                                        sab_amount_type,
                                        hrm_employee_id,
                                        hrm_elements_id,
                                        sab_account_name,
                                        sab_amount,
                                        sab_zl,
                                        sab_exported,
                                        sab_ref_value,
                                        sab_foreign_amount,
                                        acs_financial_currency_id,
                                        sab_pay_num,
                                        sab_pay_date)
         SELECT hrm_break_id,
                b.hrm_history_detail_id,
                hdb_source,
                dic_account_type_id,
                hdb_amount_type,
                b.hrm_employee_id,
                b.hrm_elements_id,
                hdb_account_name,
                hdb_amount,
                hdb_zl,
                0,
                hdb_ref_value,
                hdb_foreign_value,
                b.acs_financial_currency_id,
                his_pay_num,
                his_pay_period
           FROM hrm_tmp_break_detail b, hrm_history_detail d
          WHERE hrm_break_id = in_breakid AND b.hrm_history_detail_id = d.hrm_history_detail_id;


      -- Mise à jour des ID des comptes si envoi dans ProConcept finance
      IF pcs.pc_public.getconfig ('HRM_BREAK_TARGET') = '0'
      THEN
         UPDATE hrm_salary_breakdown a
            SET sab_account_id =
                   (SELECT DISTINCT acs_account_id
                      FROM acs_account b, acs_sub_set s
                     WHERE b.acc_number = a.sab_account_name AND b.acs_sub_set_id = s.acs_sub_set_id
                           AND c_sub_set =
                                  CASE dic_account_type_id
                                     WHEN 'CG' THEN 'ACC'
                                     WHEN 'DIV' THEN 'DTO'
                                     WHEN 'CPN' THEN 'CPN'
                                     WHEN 'CDA' THEN 'CDA'
                                     WHEN 'PF' THEN 'COS'
                                     WHEN 'PJ' THEN 'PRO'
                                  END)
          WHERE hrm_break_id = in_breakid AND dic_account_type_id IN ('CG', 'DIV', 'CPN', 'CDA', 'PF', 'PJ');


         -- Mise à jour des ID des dossiers
         UPDATE hrm_salary_breakdown a
            SET sab_account_id =
                   (SELECT doc_record_id
                      FROM doc_record
                     WHERE rco_title = sab_account_name)
          WHERE hrm_break_id = in_breakid AND dic_account_type_id = 'DOC_RECORD';
      END IF;

      /* Suppression des données temporaires */
      DELETE FROM hrm_tmp_break_detail;


   END finalize_after_break;



   /*********************************************************************************
    * Gestion des erreurs, insertions dans HRM_ERRORS_LOG
    * Contrôles :
    *   - Parité par employé
    *   - Eléments non arrondis
    *   - Employés manquants
    ********************************************************************************/
   PROCEDURE controlbreak (in_breakid IN hrm_break.hrm_break_id%TYPE, bAllErrors IN INTEGER)
   IS
   lb_present number(1);
   BEGIN
      /* Les données sont-elles déjà dans la table définitive ? */
      select case when exists(select 1 from hrm_tmp_break_detail where hrm_break_id = in_breakid) then 0 else 1 end into lb_present from dual;

      DELETE FROM hrm_errors_log
            WHERE elo_type IN (2, 3);


      if lb_present = 0 then
          /* Les données n'ont pas encore été transférées dans HRM_SALARY_BREAKDOWN */
          INSERT INTO hrm_errors_log (hrm_employee_id,
                                      hrm_elements_id,
                                      elo_message,
                                      elo_date,
                                      elo_type)
             SELECT TO_NUMBER (NULL),
                    TO_NUMBER (NULL),
                    pcs.pc_public.translateword ('La ventilation est vide !'),
                    SYSDATE,
                    3
               FROM DUAL
              WHERE NOT EXISTS
                       (SELECT 1
                          FROM hrm_tmp_break_detail
                         WHERE hrm_break_id = in_breakid)
             UNION ALL
             SELECT hrm_employee_id,
                    TO_NUMBER (NULL),
                    pcs.pc_public.translateword ('Différence débit/crédit') || ' : ' || TO_CHAR (debit_amount - credit_amount),
                    SYSDATE,
                    3
               FROM v_hrm_break_cg_parity_control
              WHERE debit_amount - credit_amount <> 0
             UNION ALL
             SELECT hrm_employee_id,
                    e.hrm_elements_id,
                    pcs.pc_public.translateword ('Elément non arrondi'),
                    SYSDATE,
                    3
               FROM hrm_tmp_break_detail b, hrm_elements e
              WHERE e.hrm_elements_id = b.hrm_elements_id AND TRUNC (hdb_amount, 2) <> hdb_amount
             UNION ALL
             SELECT hrm_employee_id,
                    e.hrm_elements_id,
                    pcs.pc_public.translateword ('Compte inexistant'),
                    SYSDATE,
                    3
               FROM hrm_tmp_break_detail b, hrm_elements e
              WHERE     e.hrm_elements_id = b.hrm_elements_id
                    AND pcs.pc_public.getconfig ('HRM_BREAK_CONTROL_ACCOUNT') = '1'
                    and dic_account_type_id in ('CG','DIV','CPN','CDA','PF','PJ')
                    AND NOT EXISTS
                           (SELECT 1
                              FROM acs_account
                             WHERE acc_number = hdb_account_name);

          -- Transfert des données dans HRM_SALARY_BREAKDOWN
          finalize_after_break (in_breakid);

      else
            /* Insertion des erreurs lors du transfert de ventilation en comptabilité */
            INSERT INTO hrm_errors_log (hrm_employee_id,
                                      hrm_elements_id,
                                      elo_message,
                                      elo_date,
                                      elo_type)
             SELECT TO_NUMBER (NULL),
                    TO_NUMBER (NULL),
                    pcs.pc_public.translateword ('La ventilation est vide !'),
                    SYSDATE,
                    3
               FROM DUAL
              WHERE NOT EXISTS
                       (SELECT 1
                          FROM hrm_salary_breakdown
                         WHERE hrm_break_id = in_breakid)
             UNION ALL
             SELECT hrm_employee_id,
                    TO_NUMBER (NULL),
                    pcs.pc_public.translateword ('Différence débit/crédit') || ' : ' || TO_CHAR (debit_amount - credit_amount),
                    SYSDATE,
                    3
               FROM (   SELECT   hrm_employee_id,
                SUM (CASE sab_amount_type
                        WHEN 'D'
                           THEN sab_amount
                        ELSE 0
                     END) debit_amount,
                SUM (CASE sab_amount_type
                        WHEN 'C'
                           THEN sab_amount
                        ELSE 0
                     END
                    ) credit_amount
           FROM hrm_salary_breakdown
          WHERE hrm_break_id = in_breakid and dic_account_type_id = 'CG'
          GROUP BY hrm_employee_id)
              WHERE debit_amount - credit_amount <> 0
             UNION ALL
             SELECT hrm_employee_id,
                    e.hrm_elements_id,
                    pcs.pc_public.translateword ('Elément non arrondi'),
                    SYSDATE,
                    3
               FROM hrm_salary_breakdown b, hrm_elements e
              WHERE hrm_break_id = in_breakid and e.hrm_elements_id = b.hrm_elements_id AND TRUNC (sab_amount, 2) <> sab_amount
             UNION ALL
             SELECT hrm_employee_id,
                    e.hrm_elements_id,
                    pcs.pc_public.translateword ('Compte inexistant'),
                    SYSDATE,
                    3
               FROM hrm_salary_breakdown b, hrm_elements e
              WHERE     e.hrm_elements_id = b.hrm_elements_id
              and hrm_break_id = in_breakid
                    AND pcs.pc_public.getconfig ('HRM_BREAK_CONTROL_ACCOUNT') = '1'
                    and dic_account_type_id in ('CG','DIV','CPN','CDA','PF','PJ')
                    AND NOT EXISTS
                           (SELECT 1
                              FROM acs_account
                             WHERE acc_number = sab_account_name);
      end if;
   END controlbreak;


   PROCEDURE BreakInitBudget (BudgetId IN hrm_budget_version.hrm_budget_version_id%TYPE)
   IS
   BEGIN
      hrm_breakdown.BreakInitBudget (BudgetId);
   END BreakInitBudget;

   PROCEDURE LaunchBreakBudget (empId      IN hrm_person.hrm_person_id%TYPE,
                                headerId   IN hrm_budget_header.hrm_budget_header_id%TYPE,
                                budgetId   IN hrm_budget_version.hrm_budget_version_id%TYPE)
   IS
   BEGIN
      hrm_breakdown.LaunchBreakBudget (empid, headerid, budgetid);
   END LaunchBreakBudget;

   /**
    * Procédure de traitement des arrondis
    */
   PROCEDURE RoundBreakBudget (budgetid IN hrm_budget_version.hrm_budget_version_id%TYPE)
   IS
   BEGIN
      hrm_breakdown.RoundBreakBudget (budgetid);
   END RoundBreakBudget;

   /**
    * Gestion des erreurs, insertions dans HRM_ERRORS_LOG
    * Contrôles :
    *   - Parité par employé
    *   - Eléments non arrondis
    *   - Employés manquants
    */
   PROCEDURE ControlBreakBudget (budgetid IN hrm_budget_version.hrm_budget_version_id%TYPE, bAllErrors IN INTEGER)
   IS
   BEGIN
      hrm_breakdown.ControlBreakBudget (budgetid, ballerrors);
   END ControlBreakBudget;
BEGIN
   /* Initialisation des données relatives à la monnaie HRM */
   SELECT acs_financial_currency_id, c_round_type, fin_rounded_amount
     INTO g_currencyid, g_roundtype, g_round
     FROM acs_financial_currency
    WHERE fin_hrm_currency = 1;
END hrm_breakdown_nom;
