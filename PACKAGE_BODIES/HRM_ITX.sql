--------------------------------------------------------
--  DDL for Package Body HRM_ITX
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_ITX" 
IS
   FUNCTION sumElemByDec (vEmp_id       NUMBER,
                          vCode         VARCHAR2,
                          vBeginDate    DATE,
                          vEndDate      DATE,
                          SheetId       NUMBER)
      RETURN NUMBER
   IS
      tmp   NUMBER (16, 6);
   BEGIN
      IF vCode IS NULL
      THEN
         RETURN 0;
      END IF;

      SELECT SUM (h.his_pay_sum_val)
        INTO tmp
        FROM hrm_history_detail h, v_hrm_elements_short v
       WHERE     UPPER (v.code) = UPPER (vCode)
             AND h.hrm_elements_id = v.elemId
             AND h.hrm_employee_id = vEmp_id
             AND h.hrm_salary_sheet_id = SheetId
             AND h.his_pay_period BETWEEN vBeginDate AND vEndDate;

      IF tmp IS NULL
      THEN
         RETURN 0;
      ELSE
         RETURN tmp;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END sumElemByDec;

   FUNCTION sumElemCharByDec (vEmp_id       NUMBER,
                              vCode         VARCHAR2,
                              vBeginDate    DATE,
                              vEndDate      DATE,
                              SheetId       NUMBER)
      RETURN VARCHAR2
   IS
      tmp   VARCHAR2 (100);
   BEGIN
      IF vCode IS NULL
      THEN
         RETURN NULL;
      END IF;

      SELECT MAX (h.his_pay_value)
        INTO tmp
        FROM hrm_history_detail h, v_hrm_elements_short v
       WHERE     UPPER (v.code) = UPPER (vCode)
             AND h.hrm_elements_id = v.elemId
             AND h.hrm_employee_id = vEmp_id
             AND h.hrm_salary_sheet_id = SheetId
             AND h.his_pay_period BETWEEN vBeginDate AND vEndDate;

      IF tmp IS NULL
      THEN
         RETURN NULL;
      ELSE
         RETURN tmp;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END sumElemCharByDec;

   FUNCTION sumElemDevise (vEmp_id       NUMBER,
                           vCode         VARCHAR2,
                           vBeginDate    DATE,
                           vEndDate      DATE)
      RETURN NUMBER
   IS
      -- SumElem en devise: retourne la somme des montants ramanés au cours de chaque mois
      tmp   NUMBER (16, 6);
   BEGIN
      IF vCode IS NULL
      THEN
         RETURN 0;
      END IF;

      SELECT SUM (
                ROUND (
                     h.his_pay_sum_val
                   / hrm_itx.get_pers_rate (vEmp_id, h.his_pay_period),
                   2))
        INTO tmp
        FROM hrm_history_detail h, v_hrm_elements_short v
       WHERE     UPPER (v.code) = UPPER (vCode)
             AND h.hrm_elements_id = v.elemId
             AND h.hrm_employee_id = vEmp_id
             AND h.his_pay_period BETWEEN vBeginDate AND vEndDate;

      IF tmp IS NULL
      THEN
         RETURN 0;
      ELSE
         RETURN ROUND (tmp, 2);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END sumElemDevise;

   FUNCTION sumElemDeviseYYYYMM (vEmp_id         NUMBER,
                                 vCode           VARCHAR2,
                                 vBeginPeriod    VARCHAR2,
                                 vEndPeriod      VARCHAR2)
      RETURN NUMBER
   IS
      -- SumElem en devise: retourne la somme des montants ramanés au cours de chaque mois
      -- format période YYYYMM
      tmp   NUMBER (16, 6);
   BEGIN
      IF vCode IS NULL
      THEN
         RETURN 0;
      END IF;

      SELECT SUM (
                  h.his_pay_sum_val
                / hrm_itx.get_pers_rate (vEmp_id, h.his_pay_period))
        INTO tmp
        FROM hrm_history_detail h, v_hrm_elements_short v
       WHERE     UPPER (v.code) = UPPER (vCode)
             AND h.hrm_elements_id = v.elemId
             AND h.hrm_employee_id = vEmp_id
             AND TO_CHAR (h.his_pay_period, 'YYYYMM') BETWEEN vBeginPeriod
                                                          AND vEndPeriod;

      IF tmp IS NULL
      THEN
         RETURN 0;
      ELSE
         RETURN ROUND (tmp, 2);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END sumElemDeviseYYYYMM;

   FUNCTION sumElemYYYYMM (vEmp_id         NUMBER,
                           vCode           VARCHAR2,
                           vBeginPeriod    VARCHAR2,
                           vEndPeriod      VARCHAR2)
      RETURN NUMBER
   IS
      -- SumElem avec paramètre période au format YYYYMM plutôt que date
      tmp   NUMBER (16, 6);
   BEGIN
      IF vCode IS NULL
      THEN
         RETURN 0;
      END IF;

      SELECT SUM (h.his_pay_sum_val)
        INTO tmp
        FROM hrm_history_detail h, v_hrm_elements_short v
       WHERE     UPPER (v.code) = UPPER (vCode)
             AND h.hrm_elements_id = v.elemId
             AND h.hrm_employee_id = vEmp_id
             AND TO_CHAR (h.his_pay_period, 'YYYYMM') BETWEEN vBeginPeriod
                                                          AND vEndPeriod;

      IF tmp IS NULL
      THEN
         RETURN 0;
      ELSE
         RETURN tmp;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END sumElemYYYYMM;

   FUNCTION get_retro_amount (PERSONID        NUMBER,
                              gs              VARCHAR2,
                              fromdate        DATE,
                              currency        VARCHAR2,
                              activeperiod    DATE,
                              amount          NUMBER)
      RETURN NUMBER
   IS
      RESULT    NUMBER;
      lastpay   DATE;
   BEGIN
      SELECT MAX (his_pay_period)
        INTO lastpay
        FROM hrm_history_detail d, hrm_elements_family f, hrm_elements_root r
       WHERE     f.hrm_elements_id = d.hrm_elements_id
             AND f.hrm_elements_root_id = r.hrm_elements_root_id
             AND r.elr_root_name = gs
             AND elf_is_reference = 1
             AND HRM_EMPLOYEE_ID = PERSONID;

      lastpay := NVL (lastpay, fromdate);
      RESULT :=
           GREATEST (
              0,
              MONTHS_BETWEEN (activeperiod, GREATEST (fromdate, lastpay)))
         * amount;
      RETURN RESULT;
   END get_retro_amount;

   FUNCTION get_pers_job (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne la description du poste pour la période active. Si pusieurs postes actifs: max(description)
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.job_descr)
        INTO retour
        FROM hrm_person_job a, hrm_job b
       WHERE     a.hrm_job_id = b.hrm_job_id
             AND a.hrm_person_id = EmpId
             AND a.pej_from <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.pej_to >= hrm_date.ACTIVEPERIOD OR a.pej_to IS NULL);

      RETURN Retour;
   END get_pers_job;

   FUNCTION get_pers_last_job (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne la description du dernier poste (selon dates de validité). Si pusieurs postes actifs: max(description)
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (job_descr)
        INTO retour
        FROM hrm_person_job pj1,
             (  SELECT MAX (pej_from) pej_from, hrm_person_id
                  FROM hrm_person_job
              GROUP BY hrm_person_id) pj2,
             hrm_job job
       WHERE     pj1.hrm_person_id = pj2.hrm_person_id
             AND pj1.pej_from = pj2.pej_from
             AND pj1.hrm_job_id = job.hrm_job_id
             AND pj1.hrm_person_id = EmpId;

      RETURN Retour;
   END get_pers_last_job;

   FUNCTION get_pers_job_resp_hier (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne le responsable hiérarchique du poste pour la période active (champ virtuel). Si pusieurs postes actifs: max(retour)
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.VFI_CHAR_01)
        INTO retour
        FROM hrm_person_job a, com_vfields_record b
       WHERE     a.hrm_person_job_id = b.vfi_rec_id
             AND a.hrm_person_id = EmpId
             AND a.pej_from <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.pej_to >= hrm_date.ACTIVEPERIOD OR a.pej_to IS NULL)
             AND b.vfi_tabname = 'HRM_PERSON_JOB';

      RETURN Retour;
   END get_pers_job_resp_hier;

   FUNCTION get_pers_job_resp_carriere (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne le responsable de carrière du poste pour la période active (champ virtuel). Si pusieurs postes actifs: max(retour)
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.VFI_CHAR_02)
        INTO retour
        FROM hrm_person_job a, com_vfields_record b
       WHERE     a.hrm_person_job_id = b.vfi_rec_id
             AND a.hrm_person_id = EmpId
             AND a.pej_from <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.pej_to >= hrm_date.ACTIVEPERIOD OR a.pej_to IS NULL)
             AND b.vfi_tabname = 'HRM_PERSON_JOB';

      RETURN Retour;
   END get_pers_job_resp_carriere;

   FUNCTION get_pers_job_matricule_affect (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne le matricule d'affectation du poste pour la période active (champ virtuel). Si pusieurs postes actifs: max(retour)
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.VFI_CHAR_03)
        INTO retour
        FROM hrm_person_job a, com_vfields_record b
       WHERE     a.hrm_person_job_id = b.vfi_rec_id
             AND a.hrm_person_id = EmpId
             AND a.pej_from <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.pej_to >= hrm_date.ACTIVEPERIOD OR a.pej_to IS NULL)
             AND b.vfi_tabname = 'HRM_PERSON_JOB';

      RETURN Retour;
   END get_pers_job_matricule_affect;

   FUNCTION get_pers_job_fonction_glob (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne la fonction globale du poste pour la période active (champ virtuel). Si pusieurs postes actifs: max(retour)
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.VFI_CHAR_04)
        INTO retour
        FROM hrm_person_job a, com_vfields_record b
       WHERE     a.hrm_person_job_id = b.vfi_rec_id
             AND a.hrm_person_id = EmpId
             AND a.pej_from <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.pej_to >= hrm_date.ACTIVEPERIOD OR a.pej_to IS NULL)
             AND b.vfi_tabname = 'HRM_PERSON_JOB';

      RETURN Retour;
   END get_pers_job_fonction_glob;

   FUNCTION get_pers_job_region_affect (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne la région d'affectation du poste pour la période active (champ virtuel). Si pusieurs postes actifs: max(retour)
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.VFI_CHAR_05)
        INTO retour
        FROM hrm_person_job a, com_vfields_record b
       WHERE     a.hrm_person_job_id = b.vfi_rec_id
             AND a.hrm_person_id = EmpId
             AND a.pej_from <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.pej_to >= hrm_date.ACTIVEPERIOD OR a.pej_to IS NULL)
             AND b.vfi_tabname = 'HRM_PERSON_JOB';

      RETURN Retour;
   END get_pers_job_region_affect;

   FUNCTION get_pers_job_statut_salarie (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne le statut du salarié du poste pour la période active (champ virtuel). Si pusieurs postes actifs: max(retour)
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.VFI_CHAR_06)
        INTO retour
        FROM hrm_person_job a, com_vfields_record b
       WHERE     a.hrm_person_job_id = b.vfi_rec_id
             AND a.hrm_person_id = EmpId
             AND a.pej_from <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.pej_to >= hrm_date.ACTIVEPERIOD OR a.pej_to IS NULL)
             AND b.vfi_tabname = 'HRM_PERSON_JOB';

      RETURN Retour;
   END get_pers_job_statut_salarie;

   FUNCTION get_pers_ino_matricule_orig (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne le matricule de la société d'origine des entrées/sorties pour la période active (champ virtuel). Si pusieurs postes actifs: max(retour)
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.VFI_CHAR_01)
        INTO retour
        FROM hrm_in_out a, com_vfields_record b
       WHERE     a.hrm_in_out_id = b.vfi_rec_id
             AND a.hrm_employee_id = EmpId
             AND a.ino_in <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.ino_out >= hrm_date.ACTIVEPERIOD OR a.ino_out IS NULL)
             AND b.vfi_tabname = 'HRM_IN_OUT';

      RETURN Retour;
   END get_pers_ino_matricule_orig;

   FUNCTION get_pers_ino_filiale_orig (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne la filiale d'origine des entrées/sorties pour la période active (champ virtuel). Si pusieurs postes actifs: max(retour)
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.VFI_CHAR_02)
        INTO retour
        FROM hrm_in_out a, com_vfields_record b
       WHERE     a.hrm_in_out_id = b.vfi_rec_id
             AND a.hrm_employee_id = EmpId
             AND a.ino_in <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.ino_out >= hrm_date.ACTIVEPERIOD OR a.ino_out IS NULL)
             AND b.vfi_tabname = 'HRM_IN_OUT';

      RETURN Retour;
   END get_pers_ino_filiale_orig;

   FUNCTION get_pers_ino_filiale_orig_id (InOutId NUMBER)
      RETURN VARCHAR2
   -- retourne la filiale d'origine des entrées/sorties (champ virtuel) selon HRM_IN_OUT_ID
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (b.VFI_CHAR_02)
        INTO retour
        FROM com_vfields_record b
       WHERE b.vfi_rec_id = InOutId AND b.vfi_tabname = 'HRM_IN_OUT';

      RETURN Retour;
   END get_pers_ino_filiale_orig_id;

   FUNCTION get_pers_ino_filiale_orig_des (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne la filiale d'origine (description) des entrées/sorties pour la période active (champ virtuel). Si pusieurs postes actifs: max(retour)
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (
                com_dic_functions.GETDICODESCR ('DIC_CONTRACT_CATEGORY',
                                                b.VFI_CHAR_02,
                                                1))
        INTO retour
        FROM hrm_in_out a, com_vfields_record b
       WHERE     a.hrm_in_out_id = b.vfi_rec_id
             AND a.hrm_employee_id = EmpId
             AND a.ino_in <= hrm_date.ACTIVEPERIODENDDATE
             AND (a.ino_out >= hrm_date.ACTIVEPERIOD OR a.ino_out IS NULL)
             AND b.vfi_tabname = 'HRM_IN_OUT';

      RETURN Retour;
   END get_pers_ino_filiale_orig_des;

   FUNCTION get_pers_ino_filiale_orig_id_d (InOutId NUMBER)
      RETURN VARCHAR2
   -- retourne la filiale d'origine (description) des entrées/sorties (champ virtuel) selon HRM_IN_OUT_ID
   -- utilisé dans les extractions utilisateurs
   IS
      Retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (
                com_dic_functions.GETDICODESCR ('DIC_CONTRACT_CATEGORY',
                                                b.VFI_CHAR_02,
                                                1))
        INTO retour
        FROM com_vfields_record b
       WHERE b.vfi_rec_id = InOutId AND b.vfi_tabname = 'HRM_IN_OUT';

      RETURN Retour;
   END get_pers_ino_filiale_orig_id_d;

   FUNCTION exchangeRateDate (vCurrency VARCHAR2, vType NUMBER, vDate DATE)
      RETURN NUMBER
   -- retourne le taux de change à une date donnée
   IS
      fSelectedRate   NUMBER;
   BEGIN
      SELECT CASE vType
                WHEN 1 THEN c.pcu_dayly_price / c.pcu_base_price       --Daily
                WHEN 2 THEN c.pcu_valuation_price / c.pcu_base_price --Evaluation
                WHEN 3 THEN c.pcu_inventory_price / c.pcu_base_price --Inventory
                WHEN 4 THEN c.pcu_closing_price / c.pcu_base_price     --Close
             END
                SELECTED_RATE
        INTO fSelectedRate
        FROM acs_price_currency c,
             (  SELECT MAX (pcu_start_validity) pcu_start_validity,
                       acs_between_curr_id,
                       acs_and_curr_id
                  FROM acs_price_currency c,
                       acs_financial_currency a,
                       pcs.pc_curr b
                 WHERE     b.currency = vCurrency
                       AND a.pc_curr_id = b.pc_curr_id
                       AND c.acs_between_curr_id = a.acs_financial_currency_id
                       AND c.acs_and_curr_id = acs_function.getlocalcurrencyid
                       AND c.pcu_start_validity <= vDate
              GROUP BY acs_and_curr_id, acs_between_curr_id) v
       WHERE     c.acs_and_curr_id = v.acs_and_curr_id
             AND c.acs_between_curr_id = v.acs_between_curr_id
             AND c.pcu_start_validity = v.pcu_start_validity;

      RETURN fSelectedRate;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 1;
   END;

   FUNCTION exchangeRateDate2 (vCurrency VARCHAR2, vType NUMBER, vDate DATE)
      RETURN NUMBER
   -- idem exchangeRateDate mais ne retourne rien s'il n'y a pas de taux dans le période (exchangeRateDate retourne le dernier taux, même si hors période)
   IS
      fSelectedRate   NUMBER;
   BEGIN
      SELECT NVL (
                MAX (
                   CASE vType
                      WHEN 1 THEN c.pcu_dayly_price / c.pcu_base_price --Daily
                      WHEN 2 THEN c.pcu_valuation_price / c.pcu_base_price --Evaluation
                      WHEN 3 THEN c.pcu_inventory_price / c.pcu_base_price --Inventory
                      WHEN 4 THEN c.pcu_closing_price / c.pcu_base_price --Close
                   END),
                1)
                SELECTED_RATE
        INTO fSelectedRate
        FROM acs_price_currency c,
             (  SELECT MAX (pcu_start_validity) pcu_start_validity,
                       acs_between_curr_id,
                       acs_and_curr_id
                  FROM acs_price_currency c,
                       acs_financial_currency a,
                       pcs.pc_curr b
                 WHERE     b.currency = vCurrency
                       AND a.pc_curr_id = b.pc_curr_id
                       AND c.acs_between_curr_id = a.acs_financial_currency_id
                       AND c.acs_and_curr_id = acs_function.getlocalcurrencyid
                       AND c.pcu_start_validity <= vDate
                       AND vDate <= LAST_DAY (c.pcu_start_validity)
              GROUP BY acs_and_curr_id, acs_between_curr_id) v
       WHERE     c.acs_and_curr_id = v.acs_and_curr_id
             AND c.acs_between_curr_id = v.acs_between_curr_id
             AND c.pcu_start_validity = v.pcu_start_validity;

      RETURN fSelectedRate;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 1;
   END exchangeRateDate2;

   FUNCTION exchangeRatePeriod (vCurrency    VARCHAR2,
                                vType        NUMBER,
                                vPeriod      VARCHAR2)
      RETURN NUMBER
   -- retourne le taux de change à une période (YYYYMM) donnée
   IS
      fSelectedRate   NUMBER;
   BEGIN
      SELECT CASE vType
                WHEN 1 THEN c.pcu_dayly_price / c.pcu_base_price       --Daily
                WHEN 2 THEN c.pcu_valuation_price / c.pcu_base_price --Evaluation
                WHEN 3 THEN c.pcu_inventory_price / c.pcu_base_price --Inventory
                WHEN 4 THEN c.pcu_closing_price / c.pcu_base_price     --Close
             END
                SELECTED_RATE
        INTO fSelectedRate
        FROM acs_price_currency c,
             (  SELECT MAX (pcu_start_validity) pcu_start_validity,
                       acs_between_curr_id,
                       acs_and_curr_id
                  FROM acs_price_currency c,
                       acs_financial_currency a,
                       pcs.pc_curr b
                 WHERE     b.currency = vCurrency
                       AND a.pc_curr_id = b.pc_curr_id
                       AND c.acs_between_curr_id = a.acs_financial_currency_id
                       AND c.acs_and_curr_id = acs_function.getlocalcurrencyid
                       AND c.pcu_start_validity <=
                              LAST_DAY (TO_DATE (vPeriod, 'YYYYMM'))
              GROUP BY acs_and_curr_id, acs_between_curr_id) v
       WHERE     c.acs_and_curr_id = v.acs_and_curr_id
             AND c.acs_between_curr_id = v.acs_between_curr_id
             AND c.pcu_start_validity = v.pcu_start_validity;

      RETURN fSelectedRate;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 1;
   END;

   FUNCTION exchangeRatePeriod2 (vCurrency    VARCHAR2,
                                 vType        NUMBER,
                                 vPeriod      VARCHAR2)
      RETURN NUMBER
   -- idem exchangeRatePeriod mais ne retourne rien s'il n'y a pas de taux dans le période (exchangeRatePeriod retourne le dernier taux, même si hors période)
   IS
      fSelectedRate   NUMBER;
   BEGIN
      SELECT CASE vType
                WHEN 1 THEN c.pcu_dayly_price / c.pcu_base_price       --Daily
                WHEN 2 THEN c.pcu_valuation_price / c.pcu_base_price --Evaluation
                WHEN 3 THEN c.pcu_inventory_price / c.pcu_base_price --Inventory
                WHEN 4 THEN c.pcu_closing_price / c.pcu_base_price     --Close
             END
                SELECTED_RATE
        INTO fSelectedRate
        FROM acs_price_currency c,
             (  SELECT MAX (pcu_start_validity) pcu_start_validity,
                       acs_between_curr_id,
                       acs_and_curr_id
                  FROM acs_price_currency c,
                       acs_financial_currency a,
                       pcs.pc_curr b
                 WHERE     b.currency = vCurrency
                       AND a.pc_curr_id = b.pc_curr_id
                       AND c.acs_between_curr_id = a.acs_financial_currency_id
                       AND c.acs_and_curr_id = acs_function.getlocalcurrencyid
                       AND c.pcu_start_validity <=
                              LAST_DAY (TO_DATE (vPeriod, 'YYYYMM'))
                       AND TO_DATE (vPeriod, 'YYYYMM') <=
                              LAST_DAY (c.pcu_start_validity)
              GROUP BY acs_and_curr_id, acs_between_curr_id) v
       WHERE     c.acs_and_curr_id = v.acs_and_curr_id
             AND c.acs_between_curr_id = v.acs_between_curr_id
             AND c.pcu_start_validity = v.pcu_start_validity;

      RETURN fSelectedRate;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 1;
   END exchangeRatePeriod2;


   FUNCTION get_pers_curr (EmpId NUMBER, vDate DATE)
      RETURN VARCHAR2
   -- retourne la monnaie de l'employé à une date donnée (HISTORIQUE)
   IS
      retour   VARCHAR2 (10);
   BEGIN
      SELECT MAX (REPLACE (his_pay_value, '"', ''))
        INTO retour
        FROM hrm_history_detail a, hrm_constants b
       WHERE     a.hrm_elements_id = b.hrm_constants_id
             AND a.hrm_employee_id = EmpId
             AND a.his_pay_period = LAST_DAY (vDate)
             AND b.con_code = 'ConEmMonnaieDéc';

      RETURN retour;
   END get_pers_curr;

   FUNCTION get_pers_curr_code (EmpId NUMBER, vDate DATE)
      RETURN VARCHAR2
   -- retourne la monnaie de l'employé à une date donnée (CODE SOUMISSION)
   IS
      retour   VARCHAR2 (10);
   BEGIN
      SELECT MAX (cod_code)
        INTO retour
        FROM hrm_employee_const a, hrm_constants b, hrm_code_table c
       WHERE     a.hrm_constants_id = b.hrm_constants_id
             AND a.hrm_code_table_id = c.hrm_code_table_id
             AND a.hrm_employee_id = EmpId
             AND a.emc_value_from <= LAST_DAY (vDate)
             AND a.emc_value_to >= ADD_MONTHS (LAST_DAY (vDate), -1) + 1
             AND b.con_code = 'ConEmMonnaieDéc';

      RETURN retour;
   END get_pers_curr_code;

   FUNCTION get_pers_rate (EmpId NUMBER, vDate DATE)
      RETURN NUMBER
   -- retourne le taux de change de l'employé à une date donnée
   IS
      retour   NUMBER;
   BEGIN
      -- 13.01.2017 : Désactivé car la société ITX ne gère pas le multi-monnaie
      -- Il faut retourner 0 pour que les différentes listes puissent se calculer
      /*
      SELECT MAX (his_pay_sum_val)
        INTO retour
        FROM hrm_history_detail a, hrm_elements b
       WHERE     a.hrm_elements_id = b.hrm_elements_id
             AND a.hrm_employee_id = EmpId
             AND a.his_pay_period = LAST_DAY (vDate)
             AND b.ele_code = 'DivMonnaieDécTaux';
      */
      SELECT 1
        INTO retour
        FROM dual;
      
      RETURN retour;
   END get_pers_rate;

   FUNCTION get_pers_currYYYYMM (EmpId NUMBER, vDate VARCHAR2)
      RETURN VARCHAR2
   -- retourne la monnaie de l'employé à une date donnée (format date YYYYMM)
   IS
      retour   VARCHAR2 (10);
   BEGIN
      SELECT MAX (REPLACE (his_pay_value, '"', ''))
        INTO retour
        FROM hrm_history_detail a, hrm_constants b
       WHERE     a.hrm_elements_id = b.hrm_constants_id
             AND a.hrm_employee_id = EmpId
             AND TO_CHAR (a.his_pay_period, 'YYYYMM') = vDate
             AND b.con_code = 'ConEmMonnaieDéc';

      RETURN retour;
   END get_pers_currYYYYMM;

   FUNCTION get_pers_rateYYYYMM (EmpId NUMBER, vDate VARCHAR2)
      RETURN NUMBER
   -- retourne le taux de change de l'employé à une date donnée (format date YYYYMM)
   IS
      retour   NUMBER;
   BEGIN
      SELECT MAX (his_pay_sum_val)
        INTO retour
        FROM hrm_history_detail a, hrm_elements b
       WHERE     a.hrm_elements_id = b.hrm_elements_id
             AND a.hrm_employee_id = EmpId
             AND TO_CHAR (a.his_pay_period, 'YYYYMM') = vDate
             AND b.ele_code = 'DivMonnaieDécTaux';

      RETURN retour;
   END get_pers_rateYYYYMM;

   PROCEDURE transfert_var (vPeriod VARCHAR2)
   -- Reprend les données saisies dans l'objet de saisie et les transfert dans la
   -- table d'importation
   IS
      -- Contrôle des décomptes provisoires
      CURSOR CurCtrl
      IS
         SELECT per_search_name || ' (' || emp_number || ')' per_fullname
           FROM hrm_person p, ind_hrm_NDF n
          WHERE     p.hrm_person_id = n.hrm_person_id
                AND TO_CHAR (emp_value_from, 'YYYYMM') <= vPeriod
                AND (   TO_CHAR (emp_valu_to, 'YYYYMM') >= vPeriod
                     OR emp_valu_to IS NULL)
                AND to_transfer = 1
                AND EXISTS
                       (SELECT 1
                          FROM hrm_history h
                         WHERE     h.hrm_employee_id = p.hrm_person_id
                               AND hit_definitive = 0);

      CURSOR CurVar
      IS
         SELECT *
           FROM ind_hrm_NDF
          WHERE     TO_CHAR (emp_value_from, 'YYYYMM') <= vPeriod
                AND (   TO_CHAR (emp_valu_to, 'YYYYMM') = vPeriod
                     OR emp_valu_to IS NULL)
                AND to_transfer = 1;

      CURSOR CurFix
      IS
         SELECT *
           FROM ind_hrm_NDF
          WHERE     TO_CHAR (emp_value_from, 'YYYYMM') <= vPeriod
                AND (   TO_CHAR (emp_valu_to, 'YYYYMM') > vPeriod
                     OR emp_valu_to IS NULL)
                AND to_transfer = 1;

      NumImport   NUMBER;
      CtrlSheet   NUMBER;
      EmpName     VARCHAR2 (4000);
   BEGIN
      -- recherche du numéro d'importation
      SELECT NVL (MAX (is_transfered), 0) + 1
        INTO NumImport
        FROM IND_HRM_TRANSF;

      CtrlSheet := 0;
      EmpName := '';

      -- *** CONTROLE *** --
      FOR RowCtrl IN CurCtrl
      LOOP
         EmpName := EmpName || CHR (10) || RowCtrl.per_fullname;
         CtrlSheet := CtrlSheet + 1;
      END LOOP;

      IF CtrlSheet > 0
      THEN
         raise_application_error (
            -20001,
               CHR (10)
            || CHR (10)
            || '>>>>>>>>>>>>>>>>>>'
            || CHR (10)
            || CHR (10)
            || 'Les décomptes "Provisoire" suivants empêchent le transfert:'
            || CHR (10)
            || EmpName
            || CHR (10)
            || CHR (10)
            || 'Les décomptes doivent être en statut "Non calculé"'
            || CHR (10)
            || CHR (10)
            || '>>>>>>>>>>>>>>>>>>'
            || CHR (10)
            || CHR (10));
      END IF;

      -- *** VARIABLES *** --
      FOR RowVar IN CurVar
      LOOP
         -- Insert dans la table historique
         INSERT INTO ind_hrm_ndf_histo
            SELECT RowVar.HRM_PERSON_ID,
                   RowVar.HRM_ELEMENTS_ID,
                   RowVar.EMP_TEXT,
                   RowVar.EMP_FOREIGN_VALUE,
                   RowVar.PC_CURR_ID,
                   RowVar.EMP_EX_RATE,
                   RowVar.EMP_NUM_VALUE,
                   RowVar.EMP_VALUE_FROM,
                   RowVar.EMP_VALU_TO,
                   RowVar.A_DATECRE,
                   RowVar.A_DATEMOD,
                   RowVar.A_IDCRE,
                   RowVar.A_IDMOD,
                   NumImport IS_TRANSFERED,
                   hrm_itx.get_pers_curr_code (RowVar.hrm_person_id,
                                               hrm_date.activeperiod + 1)
                      MONNAIE_DEC,
                   ROUND (
                        RowVar.emp_num_value
                      / hrm_itx.exchangeRateDate (
                           hrm_itx.get_pers_curr_code (
                              RowVar.hrm_person_id,
                              hrm_date.activeperiod + 1),
                           4,
                           hrm_date.activeperiod + 1),
                      2)
                      VALUE_DEC,
                   RowVar.to_transfer,
                   RowVar.NDF_ID
              FROM DUAL;

         -- suppression dans la table de saisie
         DELETE FROM ind_hrm_ndf
               WHERE ndf_id = RowVar.ndf_id;

         COMMIT;
      END LOOP;

      -- *** FIXES *** --
      FOR RowFix IN CurFix
      LOOP
         -- recherche de décompte provisoire
         SELECT COUNT (*)
           INTO CtrlSheet
           FROM hrm_history
          WHERE     hrm_employee_id = RowFix.hrm_person_id
                AND hit_pay_period = hrm_date.activeperiodenddate
                AND hit_definitive = 0;

         IF CtrlSheet > 0
         THEN
            raise_application_error (
               -20001,
                  CHR (10)
               || CHR (10)
               || '>>>>>>>>>>>>>>>>>>'
               || CHR (10)
               || CHR (10)
               || 'Un décompte Provisoire empêche le transfert. Les décomptes doivent être en statut Non calculé'
               || CHR (10)
               || CHR (10)
               || '>>>>>>>>>>>>>>>>>>'
               || CHR (10)
               || CHR (10));
         END IF;

         -- Insert dans la table historique
         INSERT INTO ind_hrm_ndf_histo
            SELECT RowFix.HRM_PERSON_ID,
                   RowFix.HRM_ELEMENTS_ID,
                   RowFix.EMP_TEXT,
                   RowFix.EMP_FOREIGN_VALUE,
                   RowFix.PC_CURR_ID,
                   RowFix.EMP_EX_RATE,
                   RowFix.EMP_NUM_VALUE,
                   RowFix.EMP_VALUE_FROM,
                   RowFix.EMP_VALU_TO,
                   RowFix.A_DATECRE,
                   RowFix.A_DATEMOD,
                   RowFix.A_IDCRE,
                   RowFix.A_IDMOD,
                   NumImport IS_TRANSFERED,
                   hrm_itx.get_pers_curr_code (RowFix.hrm_person_id,
                                               hrm_date.activeperiod + 1)
                      MONNAIE_DEC,
                   ROUND (
                        RowFix.emp_num_value
                      / hrm_itx.exchangeRateDate (
                           hrm_itx.get_pers_curr_code (
                              RowFix.hrm_person_id,
                              hrm_date.activeperiod + 1),
                           4,
                           hrm_date.activeperiod + 1),
                      2)
                      VALUE_DEC,
                   RowFix.to_transfer,
                   RowFix.NDF_ID
              FROM DUAL;

         -- Mise à jour du flag "A transférer"
         UPDATE ind_hrm_ndf
            SET to_transfer = 0
          WHERE ndf_id = RowFix.ndf_id;

         COMMIT;
      END LOOP;

      -- Insert dans la table transfert
      INSERT INTO IND_HRM_TRANSF (HRM_PERSON_ID,
                                  HRM_ELEMENTS_ID,
                                  EMP_NUM_VALUE,
                                  EMP_VALUE_FROM,
                                  EMP_VALU_TO,
                                  A_DATECRE,
                                  A_IDCRE,
                                  PERIOD,
                                  IS_TRANSFERED)
           SELECT hrm_person_id,
                  hrm_elements_id,
                  SUM (emp_num_value),
                  TO_DATE (
                        '01.'
                     || SUBSTR (vPeriod, 5, 2)
                     || '.'
                     || SUBSTR (vPeriod, 1, 4),
                     'DD.MM.YYYY')
                     emp_value_from,
                  LAST_DAY (
                     TO_DATE (
                           '01.'
                        || SUBSTR (vPeriod, 5, 2)
                        || '.'
                        || SUBSTR (vPeriod, 1, 4),
                        'DD.MM.YYYY'))
                     emp_valu_to,
                  SYSDATE,
                  'PROC',
                  vPeriod,
                  is_transfered
             FROM ind_hrm_NDF_histo
            WHERE is_transfered = NumImport
         GROUP BY hrm_person_id, hrm_elements_id, is_transfered;

      COMMIT;

      -- Transfert dans les variables
      BEGIN
         hrm_itx.transfert_empl_var (NumImport);
      END;

      COMMIT;
   END transfert_var;

   PROCEDURE transfert_empl_var (NumImport NUMBER)
   -- Transfert les données de la table d'importation dans les variables des employés
   IS
      CURSOR CurVar
      IS
         SELECT HRM_PERSON_ID,
                HRM_ELEMENTS_ID,
                EMP_NUM_VALUE,
                EMP_VALUE_FROM,
                EMP_VALU_TO,
                PERIOD,
                IS_TRANSFERED
           FROM IND_HRM_TRANSF
          WHERE IS_TRANSFERED = NumImport;

      Ctrl     NUMBER;
      Amount   NUMBER;
   BEGIN
      FOR RowVar IN CurVar
      LOOP
         Ctrl := NULL;

         SELECT MAX (hrm_employee_elements_id)
           INTO Ctrl
           FROM hrm_employee_elements
          WHERE     hrm_employee_id = RowVar.hrm_person_id
                AND hrm_elements_id = RowVar.hrm_elements_id
                AND emp_value_from <= RowVar.emp_value_from
                AND emp_value_to >= RowVar.emp_valu_to;

         IF ctrl IS NULL
         THEN
            INSERT INTO hrm_employee_elements (HRM_EMPLOYEE_ELEMENTS_ID,
                                               HRM_EMPLOYEE_ID,
                                               HRM_ELEMENTS_ID,
                                               EMP_VALUE,
                                               EMP_FROM,
                                               EMP_TO,
                                               EMP_VALUE_FROM,
                                               EMP_VALUE_TO,
                                               EMP_ACTIVE,
                                               A_DATECRE,
                                               A_IDCRE,
                                               EMP_OVERRIDE,
                                               EMP_NUM_VALUE)
               SELECT init_id_seq.NEXTVAL,
                      RowVar.hrm_person_id,
                      RowVar.hrm_elements_id,
                      TO_CHAR (RowVar.emp_num_value),
                      TO_DATE ('01.01.2000', 'DD.MM.YYYY'),
                      TO_DATE ('31.12.2022', 'DD.MM.YYYY'),
                      RowVar.emp_value_from,
                      RowVar.emp_valu_to,
                      1,
                      SYSDATE,
                      TO_CHAR (NumImport),
                      0,
                      RowVar.emp_num_value
                 FROM DUAL;
         ELSE
            -- mise à jour du montant (numérique)
            UPDATE hrm_employee_elements
               SET emp_num_value = emp_num_value + RowVar.emp_num_value
             WHERE hrm_employee_elements_id = Ctrl;

            -- mise à jour du montant (varchar)
            UPDATE hrm_employee_elements
               SET emp_value = emp_value + RowVar.emp_num_value
             WHERE hrm_employee_elements_id = Ctrl;

            -- IDMOD
            UPDATE hrm_employee_elements
               SET a_idmod = TO_CHAR (NumImport)
             WHERE hrm_employee_elements_id = Ctrl;

            -- DATEMOD
            UPDATE hrm_employee_elements
               SET a_datemod = SYSDATE
             WHERE hrm_employee_elements_id = Ctrl;
         END IF;
      END LOOP;
   END transfert_empl_var;

   FUNCTION curr_transfert (EmpId NUMBER)
      RETURN VARCHAR2
   /*
     recherche s'il existe une référence financière principale (séquence 0)
     sur une monnaie autre que la monnaie du décompte (code soumission)
     pour laquelle il n'y a pas de montant fixe (Montant pour réf. financière de la même monnaie)
   */

   IS
      FinRefExists   NUMBER;
      retour         VARCHAR2 (20);
   BEGIN
      -- Recherche  s'il existe une référence financière dans la monnaie du décompte
      SELECT COUNT (*)
        INTO FinRefExists
        FROM hrm_financial_ref a, acs_financial_currency b, pcs.pc_curr c
       WHERE     a.acs_financial_currency_id = b.acs_financial_currency_id
             AND b.pc_curr_id = c.pc_curr_id
             AND a.hrm_employee_id = EmpId
             AND c.currency =
                    hrm_itx.GET_PERS_CURR_CODE (EmpId, hrm_date.ACTIVEPERIOD)
             -- 06.05.2009: qui soit de séquence 0 et non reliée à un Montant pour référence financère
             AND a.fin_sequence = 0
             AND NOT EXISTS
                        (SELECT 1
                           FROM hrm_employee_const emc, hrm_constants con
                          WHERE     emc.hrm_constants_id =
                                       con.hrm_constants_id
                                AND emc.hrm_employee_id = EmpId
                                AND emc.emc_value_from <=
                                       hrm_date.ACTIVEPERIODENDDATE
                                AND emc.emc_value_to >= hrm_date.ACTIVEPERIOD
                                AND emc.emc_active = 1
                                AND con.dic_group2_id = 'FIN'
                                AND NOT EXISTS
                                           (SELECT 1
                                              FROM hrm_financial_ref fin,
                                                   hrm_elements_family fam,
                                                   hrm_elements_root root
                                             WHERE     con.hrm_constants_id =
                                                          fam.hrm_elements_id
                                                   AND fam.hrm_elements_root_id =
                                                          root.hrm_elements_root_id
                                                   AND root.hrm_elements_id =
                                                          fin.hrm_elements_id
                                                   AND fin.hrm_employee_id =
                                                          EmpId)
                                AND b.acs_financial_currency_id =
                                       NVL (con.acs_financial_currency_id,
                                            acs_function.GetLocalCurrencyID));

      -- S'il n'y a pas de référence fin. dans la monnaie du décompte...
      IF FinRefExists = 0
      THEN
         -- Recherche des Références financières
         SELECT MIN (c.currency)
           INTO retour
           FROM hrm_financial_ref a, acs_financial_currency b, pcs.pc_curr c
          WHERE     a.acs_financial_currency_id = b.acs_financial_currency_id
                AND b.pc_curr_id = c.pc_curr_id
                AND a.hrm_employee_id = EmpId
                AND a.hrm_elements_id IS NULL
                AND a.fin_sequence = 0
                -- Dont la monnaie est différente que la monnaie du décompte
                AND c.currency <>
                       hrm_itx.GET_PERS_CURR_CODE (EmpId,
                                                   hrm_date.ACTIVEPERIOD)
                -- Ne se trouvant pas dans Employés avec GS
                AND NOT EXISTS
                           (SELECT 1
                              FROM hrm_employee_const emc, hrm_constants con
                             WHERE     emc.hrm_constants_id =
                                          con.hrm_constants_id
                                   AND emc.hrm_employee_id = EmpId
                                   AND emc.emc_value_from <=
                                          hrm_date.ACTIVEPERIODENDDATE
                                   AND emc.emc_value_to >=
                                          hrm_date.ACTIVEPERIOD
                                   AND emc.emc_active = 1
                                   AND con.dic_group2_id = 'FIN'
                                   -- Exclusion des montants liés à une Référence financière
                                   AND NOT EXISTS
                                              (SELECT 1
                                                 FROM hrm_financial_ref fin,
                                                      hrm_elements_family fam,
                                                      hrm_elements_root root
                                                WHERE     con.hrm_constants_id =
                                                             fam.hrm_elements_id
                                                      AND fam.hrm_elements_root_id =
                                                             root.hrm_elements_root_id
                                                      AND root.hrm_elements_id =
                                                             fin.hrm_elements_id
                                                      AND fin.hrm_employee_id =
                                                             EmpId)
                                   AND b.acs_financial_currency_id =
                                          con.acs_financial_currency_id);
      END IF;

      RETURN retour;
   END curr_transfert;

   FUNCTION GetCompanyConstDate (vCode VARCHAR2, vDate DATE)
      RETURN NUMBER
   IS
      retour   NUMBER;
   BEGIN
      SELECT MAX (com_num_amount)
        INTO retour
        FROM hrm_company_elements a, hrm_elements b
       WHERE     a.hrm_elements_id = b.hrm_elements_id
             AND b.ele_code = vCode
             AND TO_CHAR (com_from, 'YYYYMM') <= TO_CHAR (vDate, 'YYYYMM')
             AND TO_CHAR (com_to, 'YYYYMM') >= TO_CHAR (vDate, 'YYYYMM');

      RETURN NVL (retour, 0);
   END GetCompanyConstDate;

   FUNCTION IsBreak (ElemId NUMBER)
      RETURN NUMBER
   IS
      retour   NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO retour
        FROM hrm_break_structure
       WHERE bre_item_id = ElemId;

      IF retour > 0
      THEN
         retour := 1;
      ELSE
         retour := 0;
      END IF;

      RETURN NVL (retour, 0);
   END IsBreak;

   FUNCTION get_pays_affect (EmpId NUMBER)
      RETURN VARCHAR2
   -- Retourne le pays d'affectation de l'employé (Contrats) dans la période active
   IS
      retour   VARCHAR2 (100);
   BEGIN
      SELECT MAX (UPPER (dic_salary_number_id))
        INTO retour
        FROM hrm_contract
       WHERE     hrm_employee_id = EmpId
             AND con_begin <= hrm_date.ACTIVEPERIODENDDATE
             AND (con_end >= hrm_date.ACTIVEPERIOD OR con_end IS NULL);

      RETURN retour;
   END get_pays_affect;

   FUNCTION get_last_pays_affect (EmpId NUMBER)
      RETURN VARCHAR2
   -- Retourne le pays d'affectation de l'employé (Contrats) - le dernier en date (selon date début)
   IS
      retour   VARCHAR2 (100);
   BEGIN
      SELECT MAX (UPPER (dic_salary_number_id))
        INTO retour
        FROM hrm_contract c1,
             (  SELECT hrm_employee_id, MAX (con_begin) con_begin
                  FROM hrm_contract
              GROUP BY hrm_employee_id) c2
       WHERE     c1.hrm_employee_id = c2.hrm_employee_id
             AND c1.con_begin = c2.con_begin
             AND c2.hrm_employee_id = EmpId;

      RETURN retour;
   END get_last_pays_affect;

   FUNCTION get_soc_affect_descr (EmpId NUMBER)
      RETURN VARCHAR2
   -- Retourne la société  d'affectation de l'employé (Contrats) dans la période active / Description
   IS
      retour   VARCHAR2 (100);
   BEGIN
      SELECT MAX (coc_descr)
        INTO retour
        FROM hrm_contract a, dic_contract_category b
       WHERE     hrm_employee_id = EmpId
             AND a.dic_contract_category_id = b.dic_contract_category_id
             AND con_begin <= hrm_date.ACTIVEPERIODENDDATE
             AND (con_end >= hrm_date.ACTIVEPERIOD OR con_end IS NULL);

      RETURN retour;
   END get_soc_affect_descr;

   FUNCTION get_soc_affect_descrWithId (ContractId NUMBER)
      RETURN VARCHAR2
   -- Retourne la société  d'affectation de l'employé (Contrats) dans la période active / Description
   -- paramètre: HRM_CONTRACT_ID
   IS
      retour   VARCHAR2 (100);
   BEGIN
      SELECT MAX (coc_descr)
        INTO retour
        FROM hrm_contract a, dic_contract_category b
       WHERE     hrm_contract_id = ContractId
             AND a.dic_contract_category_id = b.dic_contract_category_id;

      RETURN retour;
   END get_soc_affect_descrWithId;

   FUNCTION get_soc_affect_code (EmpId NUMBER)
      RETURN VARCHAR2
   -- Retourne la société  d'affectation de l'employé (Contrats) dans la période active / Code
   IS
      retour   VARCHAR2 (100);
   BEGIN
      SELECT MAX (a.dic_contract_category_id)
        INTO retour
        FROM hrm_contract a
       WHERE     hrm_employee_id = EmpId
             AND con_begin <= hrm_date.ACTIVEPERIODENDDATE
             AND (con_end >= hrm_date.ACTIVEPERIOD OR con_end IS NULL);

      RETURN retour;
   END get_soc_affect_code;

   FUNCTION get_pays_affect_descr (EmpId NUMBER)
      RETURN VARCHAR2
   -- Retourne le pays d'affectation de l'employé (Contrats) dans la période active / Description
   IS
      retour   VARCHAR2 (100);
   BEGIN
      SELECT MAX (san_descr)
        INTO retour
        FROM hrm_contract a, dic_salary_number b
       WHERE     hrm_employee_id = EmpId
             AND a.dic_salary_number_id = b.dic_salary_number_id
             AND con_begin <= hrm_date.ACTIVEPERIODENDDATE
             AND (con_end >= hrm_date.ACTIVEPERIOD OR con_end IS NULL);

      RETURN retour;
   END get_pays_affect_descr;

   FUNCTION jours_calendrier
      RETURN NUMBER
   -- Retourne le nombre de jours dans la période active (selon calendrier)
   IS
      retour   NUMBER;
   BEGIN
      SELECT MAX (hrm_date.ACTIVEPERIODENDDATE - hrm_date.ACTIVEPERIOD + 1)
        INTO retour
        FROM DUAL;

      RETURN NVL (retour, 0);
   END jours_calendrier;

   FUNCTION get_pers_division_prin (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne la division principale (société de facturation) de l'employé:
   -- celle ayant la plus grande proportion. Si plusieurs proportions identiques, Min sur la division
   IS
      retour   VARCHAR2 (100);
   BEGIN
      SELECT MIN (heb_div_number)
        INTO retour
        FROM hrm_employee_break a,
             (  SELECT hrm_employee_id, MAX (heb_ratio) heb_ratio
                  FROM hrm_employee_break
                 WHERE hrm_employee_id = EmpId
              GROUP BY hrm_employee_id) b
       WHERE     a.hrm_employee_id = b.hrm_employee_id
             AND a.heb_ratio = b.heb_ratio;

      RETURN retour;
   END get_pers_division_prin;

   FUNCTION get_pers_dossier_prin (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne le dossier principal (société de facturation) de l'employé:
   -- celle ayant la plus grande proportion. Si plusieurs proportions identiques, Min sur le dossier
   IS
      retour   VARCHAR2 (100);
   BEGIN
      SELECT MIN (heb_rco_title)
        INTO retour
        FROM hrm_employee_break a,
             (  SELECT hrm_employee_id, MAX (heb_ratio) heb_ratio
                  FROM hrm_employee_break
                 WHERE hrm_employee_id = EmpId
              GROUP BY hrm_employee_id) b
       WHERE     a.hrm_employee_id = b.hrm_employee_id
             AND a.heb_ratio = b.heb_ratio;

      RETURN retour;
   END get_pers_dossier_prin;

   FUNCTION get_pers_socfac_prin (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne la société de facturation de l'employé:
   -- si compta ProConcept -> Dossier, sinin Division
   IS
      ComptaTarget   VARCHAR2 (10);
      retour         VARCHAR2 (100);
   BEGIN
      SELECT MAX (COCOCVAL)
        INTO ComptaTarget
        FROM pcs.pc_cocom a, pcs.pc_cbase b
       WHERE     a.pc_cbase_id = b.pc_cbase_id
             AND b.cbacname_upper = 'HRM_BREAK_TARGET'
             AND a.pc_comp_id = pcs.pc_init_session.GetCompanyID;

      IF ComptaTarget = '0'
      -- Vers la comptabilité ProConcept
      THEN
         SELECT hrm_itx.get_pers_dossier_prin (EmpId) INTO retour FROM DUAL;
      -- Vers une autre comptabilité (fichier ASCII)
      ELSE
         SELECT hrm_itx.get_pers_division_prin (EmpId) INTO retour FROM DUAL;
      END IF;

      RETURN retour;
   END get_pers_socfac_prin;

   FUNCTION get_pers_nbr_child (EmpId NUMBER)
      RETURN NUMBER
   -- retourne le nombre d'enfant pour un employé
   IS
      retour   NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO retour
        FROM hrm_related_to
       WHERE hrm_employee_id = EmpId AND c_related_to_type = 2;

      RETURN NVL (retour, 0);
   END get_pers_nbr_child;

   FUNCTION SumElemLastxMonthPrec (EmpId          NUMBER,
                                   vCode          VARCHAR2,
                                   vIntervalle    NUMBER)
      RETURN NUMBER
   -- retourne la valeur d'un élément sur les x mois précédents (pas le mois actuel)
   -- Attention: on retourne un montant CHF mais les montants sont revalorisés chque mois au cours du mois
   IS
      tmp   NUMBER (16, 6);
   BEGIN
      IF vCode IS NULL
      THEN
         RETURN 0;
      END IF;

      SELECT SUM (
                  his_pay_sum_val
                / hrm_itx.GET_PERS_RATEYYYYMM (
                     h.hrm_employee_id,
                     TO_CHAR (h.his_pay_period, 'YYYYMM'))
                * hrm_itx.EXCHANGERATEDATE (
                     hrm_itx.GET_PERS_CURR_CODE (h.hrm_employee_id,
                                                 h.his_pay_period),
                     4,
                     hrm_date.ACTIVEPERIODENDDATE))
        INTO tmp
        FROM hrm_history_detail h, v_hrm_elements_short v
       WHERE     UPPER (v.code) = UPPER (vCode)
             AND h.hrm_elements_id = v.elemId
             AND h.hrm_employee_id = EmpId
             AND h.his_pay_period BETWEEN ADD_MONTHS (hrm_date.activeperiod,
                                                      -vIntervalle)
                                      AND LAST_DAY (
                                             ADD_MONTHS (
                                                hrm_date.activeperiod,
                                                -1));

      IF tmp IS NULL
      THEN
         RETURN 0;
      ELSE
         RETURN tmp;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END SumElemLastxMonthPrec;

   FUNCTION GetPaysAffectPeriod (Empid NUMBER, vPeriod VARCHAR2)
      RETURN VARCHAR2
   -- retourne le pays d'affectration (description de l'employé à une date donnée (période)
   IS
      retour       VARCHAR2 (100);
      ContractId   NUMBER;
   BEGIN
      SELECT MAX (san_descr)
        INTO retour
        FROM hrm_contract a, dic_salary_number b
       WHERE     a.dic_salary_number_id = b.dic_salary_number_id
             AND hrm_employee_id = EmpId
             AND TO_CHAR (con_begin, 'YYYYMM') <= vPeriod
             AND (TO_CHAR (con_end, 'YYYYMM') >= vPeriod OR con_end IS NULL);

      -- Si pays d'affectation = null -> recherche pays d'affectation du dernier contrat en date
      IF retour IS NULL
      THEN
         SELECT MAX (san_descr)
           INTO retour
           FROM hrm_contract c1,
                (  SELECT MAX (con_begin) con_begin, hrm_employee_id
                     FROM hrm_contract
                    WHERE TO_CHAR (con_end, 'YYYYMM') < vPeriod
                 GROUP BY hrm_employee_id) c2,
                dic_salary_number d
          WHERE     c1.con_begin = c2.con_begin
                AND c1.hrm_employee_id = c2.hrm_employee_id
                AND c1.hrm_employee_id = EmpId
                AND c1.dic_salary_number_id = d.dic_salary_number_id;
      END IF;

      -- Si pays d'affectation toujours null -> recherche pays d'affectation du contrat suivant
      IF retour IS NULL
      THEN
         SELECT MAX (san_descr)
           INTO retour
           FROM hrm_contract c1,
                (  SELECT MIN (con_begin) con_begin, hrm_employee_id
                     FROM hrm_contract
                    WHERE TO_CHAR (con_begin, 'YYYYMM') > vPeriod
                 GROUP BY hrm_employee_id) c2,
                dic_salary_number d
          WHERE     c1.con_begin = c2.con_begin
                AND c1.hrm_employee_id = c2.hrm_employee_id
                AND c1.hrm_employee_id = EmpId
                AND c1.dic_salary_number_id = d.dic_salary_number_id;
      END IF;

      RETURN retour;
   END GetPaysAffectPeriod;

   FUNCTION SumElemActuVTS (EmpId        NUMBER,
                            vCode        VARCHAR2,
                            vDate        VARCHAR2,
                            CurrValue    NUMBER)
      RETURN NUMBER
   -- Utilisée dans le VTS
   -- Retourne la somme d'un élément depuis la date donnée en paramètre (format caractère) jusqu'à la période active
   -- La valeur actuelle calculée dans le VTS est ajoutée
   IS
      tmp   NUMBER (16, 6);
   BEGIN
      IF vCode IS NULL
      THEN
         RETURN 0;
      END IF;

      SELECT NVL (SUM (h.his_pay_sum_val), 0)
        INTO tmp
        FROM hrm_history_detail h, v_hrm_elements_short v
       WHERE     UPPER (v.code) = UPPER (vCode)
             AND h.hrm_elements_id = v.elemId
             AND h.hrm_employee_id = EmpId
             AND h.his_pay_period BETWEEN TO_DATE (vDate, 'DD.MM.YYYY')
                                      AND hrm_date.ACTIVEPERIODENDDATE;

      tmp := tmp + CurrValue;

      RETURN tmp;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END SumElemActuVTS;

   FUNCTION get_comp_const_num (vCode VARCHAR2, vDate DATE)
      RETURN NUMBER
   -- Retourne la valeur (numérique) d'une constante entreprise à une date donnée
   IS
      retour   NUMBER;
   BEGIN
      SELECT MAX (com_num_amount)
        INTO retour
        FROM hrm_company_elements a, hrm_elements b
       WHERE     a.hrm_elements_id = b.hrm_elements_id
             AND b.ele_code = vCode
             AND a.com_from <= vDate
             AND a.com_to >= vDate;

      RETURN NVL (retour, 0);
   END get_comp_const_num;

   FUNCTION get_div_descr (AccNum VARCHAR2)
      RETURN VARCHAR2
   -- Retourne la description de la division (no de compte). LangId = 1
   IS
      retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (des_description_summary)
        INTO retour
        FROM acs_account a, acs_division_account b, acs_description c
       WHERE     a.acs_account_id = b.acs_division_account_id
             AND a.acs_account_id = c.acs_account_id
             AND a.acc_number = AccNum
             AND c.pc_lang_id = 1;

      RETURN retour;
   END get_div_descr;

   FUNCTION get_div_descr_compl (AccNum VARCHAR2)
      RETURN VARCHAR2
   -- Retourne la description de la division (no de compte). LangId = 1
   IS
      retour   VARCHAR2 (200);
   BEGIN
      SELECT MAX (des_description_large)
        INTO retour
        FROM acs_account a, acs_division_account b, acs_description c
       WHERE     a.acs_account_id = b.acs_division_account_id
             AND a.acs_account_id = c.acs_account_id
             AND a.acc_number = AccNum
             AND c.pc_lang_id = 1;

      RETURN retour;
   END get_div_descr_compl;

   FUNCTION getFinRefId (EmpId NUMBER, NumRow NUMBER)
      RETURN NUMBER
   -- retourne l'id de la référence financière
   -- le paramètee NumRow détermine quelle référence il faut retourner: la première, deuxième, troisième, etc.
   IS
      CURSOR CurFin
      IS
           SELECT hrm_financial_ref_id
             FROM hrm_financial_ref
            WHERE hrm_employee_id = EmpId
         ORDER BY acs_financial_currency_id, fin_sequence;

      CountRow   NUMBER;
      retour     NUMBER;
   BEGIN
      CountRow := 1;

      FOR RowFin IN CurFin
      LOOP
         IF CountRow = NumRow
         THEN
            retour := RowFin.hrm_financial_ref_id;
         END IF;

         CountRow := CountRow + 1;
      END LOOP;

      RETURN retour;
   END getFinRefId;

   FUNCTION get_pers_child_name (EmpId NUMBER, NumRow NUMBER)
      RETURN VARCHAR2
   -- retourne le nom d'un enfant
   -- le paramètre NumRow détermine quel enfant il faut retourner: le premier, deuxième, troisième, etc.
   IS
      CURSOR CurChild
      IS
           SELECT RTRIM (rel_name || ' ' || NVL (rel_first_name, '')) rel_name
             FROM hrm_related_to
            WHERE c_related_to_type = 2 AND hrm_employee_id = EmpId
         ORDER BY rel_birth_date, hrm_related_to_id;

      CountRow   NUMBER;
      retour     VARCHAR2 (120);
   BEGIN
      CountRow := 1;

      FOR RowChild IN CurChild
      LOOP
         IF CountRow = NumRow
         THEN
            retour := RowChild.rel_name;
         END IF;

         CountRow := CountRow + 1;
      END LOOP;

      RETURN retour;
   END get_pers_child_name;

   FUNCTION get_pers_child_date (EmpId NUMBER, NumRow NUMBER)
      RETURN DATE
   -- retourne la date de naissance d'un enfant
   -- le paramètre NumRow détermine quel enfant il faut retourner: le premier, deuxième, troisième, etc.
   IS
      CURSOR CurChild
      IS
           SELECT rel_birth_date
             FROM hrm_related_to
            WHERE c_related_to_type = 2 AND hrm_employee_id = EmpId
         ORDER BY rel_birth_date, hrm_related_to_id;

      CountRow   NUMBER;
      retour     DATE;
   BEGIN
      CountRow := 1;

      FOR RowChild IN CurChild
      LOOP
         IF CountRow = NumRow
         THEN
            retour := RowChild.rel_birth_date;
         END IF;

         CountRow := CountRow + 1;
      END LOOP;

      RETURN retour;
   END get_pers_child_date;

   FUNCTION GetDicoDescr (
      aTable      VARCHAR2,
      aCode       VARCHAR2,
      LangId   IN pcs.pc_lang.pc_lang_id%TYPE DEFAULT pcs.pc_Init_Session.GetUserLangId)
      RETURN dico_Description.dit_descr%TYPE
   -- reprend la fonction COM_DIC_FUNCTIONS.GetDicoDescr
   -- utilisable ainsi dans l'objet HRM_USER_EXTRACTION
   IS
      retour   dico_Description.dit_descr%TYPE;
   BEGIN
      SELECT COM_DIC_FUNCTIONS.GetDicoDescr (aTable, aCode, LangId)
        INTO retour
        FROM DUAL;

      RETURN retour;
   END GetDicoDescr;

   FUNCTION GetUserDescr (UserId NUMBER)
      RETURN VARCHAR2
   -- Retourne la description de l'utilisateur connecté
   IS
      retour   pcs.pc_user.use_descr%TYPE;
   BEGIN
      SELECT use_descr
        INTO retour
        FROM pcs.pc_user
       WHERE pc_user_id = UserId;

      RETURN retour;
   END GetUserDescr;

   FUNCTION GetUserMail (UserId NUMBER)
      RETURN VARCHAR2
   -- Retourne la description de l'utilisateur connecté
   IS
      retour   pcs.pc_user.use_email%TYPE;
   BEGIN
      SELECT use_email
        INTO retour
        FROM pcs.pc_user
       WHERE pc_user_id = UserId;

      RETURN retour;
   END GetUserMail;

   FUNCTION GetUserPhone (UserId NUMBER)
      RETURN VARCHAR2
   -- Retourne la description de l'utilisateur connecté
   IS
      retour   pcs.pc_user.use_phone%TYPE;
   BEGIN
      SELECT use_phone
        INTO retour
        FROM pcs.pc_user
       WHERE pc_user_id = UserId;

      RETURN retour;
   END GetUserPhone;

   FUNCTION IsCalculated (EmpId NUMBER, Period VARCHAR2)
      RETURN NUMBER
   -- retourne 1 si l'employé est calculé dans la période donnée en paramètre ou 0 s'il n'est pas caclulé
   IS
      retour   NUMBER (1);
   BEGIN
      SELECT COUNT (*)
        INTO retour
        FROM hrm_history
       WHERE     hrm_employee_id = EmpId
             AND TO_CHAR (hit_pay_period, 'YYYYMM') = Period;

      IF retour > 0
      THEN
         retour := 1;
      ELSE
         retour := 0;
      END IF;

      RETURN retour;
   END IsCalculated;

   FUNCTION GetConjointId (EmpId NUMBER)
      RETURN NUMBER
   -- retourne l'id du coinjoint si celui-ci se trouve également dans la gestion des employés
   -- Le lien se fait par le No AVS des Dépendants de la Gestion des employés
   IS
      retour   NUMBER;
   BEGIN
      SELECT MAX (c.hrm_person_id)
        INTO retour
        FROM hrm_person p, hrm_related_to r, hrm_person c
       WHERE     p.hrm_person_id = r.hrm_employee_id
             AND r.rel_social_securityno = c.emp_social_securityno
             AND p.hrm_person_id = EmpId
             AND r.c_related_to_type = '1';

      RETURN retour;
   END GetConjointId;

   PROCEDURE UpdateDateConstBeforeOpen (EmpId NUMBER)
   -- Procédure utilisée dans le pilotage de mise à jour des dates des constantes employés
   -- Initialise les tables de paramètres en fonction de l'employé sélectionné
   IS
   BEGIN
      -- vide les tables
      DELETE FROM ind_hrm_const_update_header;

      DELETE FROM ind_hrm_const_update_detail;

      -- insert header
      INSERT
        INTO ind_hrm_const_update_header (hrm_employee_id, spr_validate_trans)
      VALUES (EmpId, 0);

      -- insert detail
      INSERT INTO ind_hrm_const_update_detail (hrm_employee_id,
                                               C_HRM_SAL_CONST_TYPE,
                                               emc_active)
         SELECT EmpId, b.GCLCODE, 1
           FROM pcs.PC_GCGRP a, pcs.PC_GCLST b
          WHERE     a.PC_GCGRP_id = b.PC_GCGRP_id
                AND a.GCGNAME = 'C_HRM_SAL_CONST_TYPE';
   END UpdateDateConstBeforeOpen;

   PROCEDURE UpdateDateConstAfterClose
   -- Procédure utilisée dans le pilotage de mise à jour des dates des constantes employés
   -- Met à jour les dates de validité (Employés avec GS)
   IS
      CURSOR CurConst
      IS
         SELECT DISTINCT a.hrm_employee_id,
                         a.hrm_constants_id,
                         c.emc_value_from new_date_from,
                         c.emc_value_to new_date_to
           FROM hrm_employee_const a,
                hrm_constants b,
                ind_hrm_const_update_header c,
                ind_hrm_const_update_detail d
          WHERE     a.hrm_constants_id = b.hrm_constants_id
                AND a.hrm_employee_id = c.hrm_employee_id
                AND b.C_HRM_SAL_CONST_TYPE = d.C_HRM_SAL_CONST_TYPE
                AND c.hrm_employee_id = d.hrm_employee_id
                AND c.SPR_VALIDATE_TRANS = 1
                AND d.emc_active = 1
                AND b.con_code NOT IN
                       ('ConEmMonnaieDéc', 'ConEmMonnaieDécTypeTaux');

      DateMin       DATE;
      DateMax       DATE;
      DateBetween   DATE;
      CountRecord   INTEGER;
      Ctrl1         NUMBER;
      Ctrl2         NUMBER;
   BEGIN
      FOR RowConst IN CurConst
      LOOP
         -- DATE DEBUT
         IF RowConst.new_date_from IS NOT NULL
         THEN
            -- Recherche nb de lignes pour la constante
            SELECT COUNT (*)
              INTO CountRecord
              FROM hrm_employee_const
             WHERE     hrm_employee_id = RowConst.hrm_employee_id
                   AND hrm_constants_id = RowConst.hrm_constants_id;

            -- Recherche de la plus petite date de début
            SELECT MIN (emc_value_from)
              INTO DateMin
              FROM hrm_employee_const
             WHERE     hrm_employee_id = RowConst.hrm_employee_id
                   AND hrm_constants_id = RowConst.hrm_constants_id;

            -- Recherche de la date de début de l'intervalle dans lequel se trouve la nouvelle date
            SELECT MIN (emc_value_from)
              INTO DateBetween
              FROM hrm_employee_const
             WHERE     hrm_employee_id = RowConst.hrm_employee_id
                   AND hrm_constants_id = RowConst.hrm_constants_id
                   AND emc_value_to >= RowConst.new_date_from
                   AND emc_value_from <= RowConst.new_date_from;

            -- Si un seul record pour la constante -> update
            IF CountRecord = 1
            THEN
               UPDATE hrm_employee_const
                  SET emc_value_from = RowConst.new_date_from,
                      a_idmod = 'AUTO',
                      a_datemod = SYSDATE
                WHERE     hrm_employee_id = RowConst.hrm_employee_id
                      AND hrm_constants_id = RowConst.hrm_constants_id;
            ELSIF -- Si la nouvelle date < plus petite date -> update sur la ligne de la plus petite date
                 RowConst.new_date_from <= DateMin
            THEN
               UPDATE hrm_employee_const
                  SET emc_value_from = RowConst.new_date_from,
                      a_idmod = 'AUTO',
                      a_datemod = SYSDATE
                WHERE     hrm_employee_id = RowConst.hrm_employee_id
                      AND hrm_constants_id = RowConst.hrm_constants_id
                      AND emc_value_from = DateMin;
            ELSE       -- sinon update sur la ligne comprise dans l'intervalle
               UPDATE hrm_employee_const
                  SET emc_value_from = RowConst.new_date_from,
                      a_idmod = 'AUTO',
                      a_datemod = SYSDATE
                WHERE     hrm_employee_id = RowConst.hrm_employee_id
                      AND hrm_constants_id = RowConst.hrm_constants_id
                      AND emc_value_from = DateBetween;
            END IF;
         --dbms_output.put_line('OK');

         END IF;                                                 -- DATE DEBUT

         -- DATE FIN
         IF RowConst.new_date_to IS NOT NULL
         THEN
            -- Recherche nb de lignes pour la constante
            SELECT COUNT (*)
              INTO CountRecord
              FROM hrm_employee_const
             WHERE     hrm_employee_id = RowConst.hrm_employee_id
                   AND hrm_constants_id = RowConst.hrm_constants_id;

            -- Recherche de la plus grande date de fin
            SELECT MAX (emc_value_to)
              INTO DateMax
              FROM hrm_employee_const
             WHERE     hrm_employee_id = RowConst.hrm_employee_id
                   AND hrm_constants_id = RowConst.hrm_constants_id;

            -- Recherche de la plus petite date de fin supérieure à la nouvelle date
            SELECT MIN (emc_value_to)
              INTO DateBetween
              FROM hrm_employee_const
             WHERE     hrm_employee_id = RowConst.hrm_employee_id
                   AND hrm_constants_id = RowConst.hrm_constants_id
                   AND emc_value_to >= RowConst.new_date_to;

            -- Si un seul record pour la constante -> update (pour autant que la date soit supérieure à la date de début)
            IF CountRecord = 1
            THEN
               UPDATE hrm_employee_const
                  SET emc_value_to = RowConst.new_date_to,
                      a_idmod = 'AUTO',
                      a_datemod = SYSDATE
                WHERE     hrm_employee_id = RowConst.hrm_employee_id
                      AND hrm_constants_id = RowConst.hrm_constants_id
                      AND RowConst.new_date_to > emc_value_from;
            ELSIF -- Si la nouvelle date > plus grande date -> update sur la ligne de la plus grande date
                 RowConst.new_date_to >= DateMax
            THEN
               UPDATE hrm_employee_const
                  SET emc_value_to = RowConst.new_date_to,
                      a_idmod = 'AUTO',
                      a_datemod = SYSDATE
                WHERE     hrm_employee_id = RowConst.hrm_employee_id
                      AND hrm_constants_id = RowConst.hrm_constants_id
                      AND emc_value_to = DateMax;
            ELSE       -- sinon update sur la ligne comprise dans l'intervalle
               UPDATE hrm_employee_const
                  SET emc_value_to = RowConst.new_date_to,
                      a_idmod = 'AUTO',
                      a_datemod = SYSDATE
                WHERE     hrm_employee_id = RowConst.hrm_employee_id
                      AND hrm_constants_id = RowConst.hrm_constants_id
                      AND emc_value_to = DateBetween;
            END IF;
         --dbms_output.put_line('OK');

         END IF;                                                   -- DATE FIN

         -- mise à jour du flag Actif - activation
         UPDATE hrm_employee_const
            SET emc_active = 1
          WHERE     hrm_employee_id = RowConst.hrm_employee_id
                AND hrm_constants_id = RowConst.hrm_constants_id
                AND emc_value_to >= hrm_date.ACTIVEPERIOD
                AND emc_value_from <= hrm_date.ACTIVEPERIODENDDATE;

         -- mise à jour du flag Actif - désactivation
         UPDATE hrm_employee_const
            SET emc_active = 0
          WHERE     hrm_employee_id = RowConst.hrm_employee_id
                AND hrm_constants_id = RowConst.hrm_constants_id
                AND (   emc_value_to < hrm_date.ACTIVEPERIOD
                     OR emc_value_from > hrm_date.ACTIVEPERIODENDDATE);
      END LOOP;
   END UpdateDateConstAfterClose;

   PROCEDURE InsertCertifParamBeforeOpen
   -- Préparation des GS manquants sur le Certificat de salaire dans une table temporaire
   IS
   BEGIN
      DELETE FROM ind_certif_param;

      INSERT INTO ind_certif_param
         SELECT 1 emc_active,
                '01-Brut' c_root_type,
                a.hrm_elements_id,
                (SELECT hrm_control_list_id
                   FROM hrm_control_list
                  WHERE col_name = 'Certificat de salaire')
                   hrm_control_list_id,
                b.ele_code,
                (SELECT erd_descr
                   FROM hrm_elements_root_descr d
                  WHERE     a.hrm_elements_root_id = d.hrm_elements_root_id
                        AND pc_lang_id = 1)
                   coe_descr,
                a.elr_root_code coe_box,
                SYSDATE a_datecre,
                'RGU' a_idcre,
                0 coe_inverse
           FROM hrm_elements_root a, hrm_elements b, hrm_formulas_structure c
          WHERE     a.hrm_elements_id = b.hrm_elements_id
                AND a.hrm_elements_id = c.related_id
                AND c.main_code IN
                       ('CemSalBrut',
                        'CemSalBrut2',
                        'CemSalBrut3',
                        'CemBaseBrut',
                        'CemSalBrut4',
                        'CemSalBrut5')
                AND b.ele_code NOT IN
                       ('CemSalBrut2',
                        'CemSalBrut3',
                        'CemBaseBrut',
                        'CemSalBrut4',
                        'CemSalBrut5')
                AND b.ele_code NOT IN
                       ('CemBasSalRetro1', 'CemBasSalRetroEUR1')
                AND NOT EXISTS
                           (SELECT 1
                              FROM hrm_control_elements coe,
                                   hrm_control_list col
                             WHERE     coe.hrm_control_list_id =
                                          col.hrm_control_list_id
                                   AND coe.hrm_control_elements_id =
                                          b.hrm_elements_id
                                   AND col.col_name = 'Certificat de salaire')
         UNION ALL
         SELECT 1 emc_active,
                '02-Déductions' c_root_type,
                a.hrm_elements_id,
                (SELECT hrm_control_list_id
                   FROM hrm_control_list
                  WHERE col_name = 'Certificat de salaire')
                   hrm_control_list_id,
                b.ele_code,
                (SELECT erd_descr
                   FROM hrm_elements_root_descr d
                  WHERE     a.hrm_elements_root_id = d.hrm_elements_root_id
                        AND pc_lang_id = 1)
                   coe_descr,
                NVL ( (SELECT MAX (elr_root_code)
                         FROM hrm_elements_root
                        WHERE elr_root_name = 'TotDéd'),
                     (SELECT MAX (elr_root_code)
                        FROM hrm_elements_root
                       WHERE elr_root_name = 'TotDédCertif'))
                   coe_box,
                SYSDATE,
                'RGU',
                0
           FROM hrm_elements_root a, hrm_elements b, hrm_formulas_structure c
          WHERE     a.hrm_elements_id = b.hrm_elements_id
                AND a.hrm_elements_id = c.related_id
                AND c.main_code IN
                       ('CemTotDéd',
                        'CemTotDéd2',
                        'CemTotDéd3',
                        'CemBaseRetSalDéd',
                        'CemBaseAutreRetSal')
                AND b.ele_code NOT IN ('CemTotDéd2', 'CemTotDéd3')
                AND b.ele_code NOT IN ('CemPartLogeDéd')
                AND b.ele_code NOT LIKE 'CemSalLocal%'
                AND NOT EXISTS
                           (SELECT 1
                              FROM hrm_control_elements coe,
                                   hrm_control_list col
                             WHERE     coe.hrm_control_list_id =
                                          col.hrm_control_list_id
                                   AND coe.hrm_control_elements_id =
                                          b.hrm_elements_id
                                   AND col.col_name = 'Certificat de salaire')
         UNION ALL
         SELECT 1 emc_active,
                '03-Salaire local' c_root_type,
                a.hrm_elements_id,
                (SELECT hrm_control_list_id
                   FROM hrm_control_list
                  WHERE col_name = 'Certificat de salaire')
                   hrm_control_list_id,
                b.ele_code,
                (SELECT erd_descr
                   FROM hrm_elements_root_descr d
                  WHERE     a.hrm_elements_root_id = d.hrm_elements_root_id
                        AND pc_lang_id = 1)
                   coe_descr,
                elr_root_code coe_box,
                SYSDATE,
                'RGU',
                0
           FROM hrm_elements_root a, hrm_elements b, hrm_formulas_structure c
          WHERE     a.hrm_elements_id = b.hrm_elements_id
                AND a.hrm_elements_id = c.related_id
                AND c.main_code IN
                       ('CemTotDéd', 'CemTotDéd2', 'CemTotDéd3')
                AND b.ele_code NOT IN ('CemTotDéd2', 'CemTotDéd3')
                --and b.ele_code not in ('CemPartLogeDéd')
                AND b.ele_code LIKE 'CemSalLocal%'
                AND NOT EXISTS
                           (SELECT 1
                              FROM hrm_control_elements coe,
                                   hrm_control_list col
                             WHERE     coe.hrm_control_list_id =
                                          col.hrm_control_list_id
                                   AND coe.hrm_control_elements_id =
                                          b.hrm_elements_id
                                   AND col.col_name = 'Certificat de salaire')
         UNION ALL
         SELECT 1 emc_active,
                '04-Participation logement' c_root_type,
                a.hrm_elements_id,
                (SELECT hrm_control_list_id
                   FROM hrm_control_list
                  WHERE col_name = 'Certificat de salaire')
                   hrm_control_list_id,
                b.ele_code,
                (SELECT erd_descr
                   FROM hrm_elements_root_descr d
                  WHERE     a.hrm_elements_root_id = d.hrm_elements_root_id
                        AND pc_lang_id = 1)
                   coe_descr,
                elr_root_code coe_box,
                SYSDATE,
                'RGU',
                0
           FROM hrm_elements_root a, hrm_elements b, hrm_formulas_structure c
          WHERE     a.hrm_elements_id = b.hrm_elements_id
                AND a.hrm_elements_id = c.related_id
                AND c.main_code IN
                       ('CemTotDéd', 'CemTotDéd2', 'CemTotDéd3')
                AND b.ele_code NOT IN ('CemTotDéd2', 'CemTotDéd3')
                AND b.ele_code LIKE 'CemPartLoge%'
                AND NOT EXISTS
                           (SELECT 1
                              FROM hrm_control_elements coe,
                                   hrm_control_list col
                             WHERE     coe.hrm_control_list_id =
                                          col.hrm_control_list_id
                                   AND coe.hrm_control_elements_id =
                                          b.hrm_elements_id
                                   AND col.col_name = 'Certificat de salaire');
   END InsertCertifParamBeforeOpen;

   PROCEDURE InsertCertifParamGenerate
   -- Insertion des GS dans le certificat de salaire
   IS
   BEGIN
      INSERT INTO hrm_control_elements (HRM_CONTROL_ELEMENTS_ID,
                                        HRM_CONTROL_LIST_ID,
                                        COE_CODE,
                                        COE_DESCR,
                                        COE_BOX,
                                        A_DATECRE,
                                        A_IDCRE,
                                        COE_INVERSE)
         SELECT HRM_ELEMENTS_ID,
                HRM_CONTROL_LIST_ID,
                ELE_CODE,
                COE_DESCR,
                COE_BOX,
                A_DATECRE,
                A_IDCRE,
                COE_INVERSE
           FROM ind_certif_param
          WHERE emc_active = 1;

      DELETE FROM ind_certif_param;
   END InsertCertifParamGenerate;

   FUNCTION GetEmpDaysCal (EmpId NUMBER, DateFrom DATE, DateTo DATE)
      RETURN NUMBER
   -- Retourne le nombre de jours calendaires travaillés selon les entrées/sorties
   IS
      retour   NUMBER;
   BEGIN
      SELECT SUM (
                  LEAST (NVL (ino_out, TO_DATE ('31.12.2022', 'DD.MM.YYYY')),
                         DateTo)
                - GREATEST (
                     NVL (ino_in, TO_DATE ('01.01.1899', 'DD.MM.YYYY')),
                     DateFrom)
                + 1)
        INTO retour
        FROM hrm_person p,
             (SELECT hrm_employee_id, ino_in, ino_out
                FROM hrm_in_out
               WHERE     (ino_out >= DateFrom OR ino_out IS NULL)
                     AND ino_in <= DateTo) i
       WHERE     p.hrm_person_id = i.hrm_employee_id(+)
             AND p.hrm_person_id = EmpId;

      RETURN NVL (retour, 0);
   END GetEmpDaysCal;

   FUNCTION to_word_en (pn$nombre IN NUMBER, vCurr VARCHAR2)
      RETURN VARCHAR2
   IS
      --
      TYPE table_varchar IS TABLE OF VARCHAR2 (255);

      --
      lv$multiples        table_varchar
                             := table_varchar ('',
                                               ' thousand ',
                                               ' million ',
                                               ' billion ',
                                               ' trillion ',
                                               ' quadrillion ',
                                               ' quintillion ',
                                               ' sextillion ',
                                               ' septillion ',
                                               ' octillion ',
                                               ' nonillion ',
                                               ' decillion ',
                                               ' undecillion ',
                                               ' duodecillion ',
                                               ' tridecillion ',
                                               ' quaddecillion ',
                                               ' quindecillion ',
                                               ' sexdecillion ',
                                               ' septdecillion ',
                                               ' octdecillion ',
                                               ' nondecillion ',
                                               ' dedecillion ');

      lv$entier           VARCHAR2 (255)
                             := TRUNC (TO_NUMBER (REPLACE (pn$nombre, ' ', '')));
      lv$decimales        VARCHAR2 (255) := SUBSTR (pn$nombre - lv$entier, 2);
      lv$mots_complets    VARCHAR2 (4000);
      lv$entier_lettres   VARCHAR2 (4000);
      li$nb_zero          INTEGER;
   BEGIN
      --
      -- Traitement de la partie décimale
      --
      IF NVL (lv$decimales, 0) != 0
      THEN
         FOR i IN 1 .. lv$multiples.COUNT
         LOOP
            EXIT WHEN lv$decimales IS NULL;

            --
            IF (SUBSTR (lv$decimales, LENGTH (lv$decimales) - 2, 3) <> 0)
            THEN
               lv$mots_complets :=
                     TO_CHAR (
                        TO_DATE (
                           SUBSTR (lv$decimales,
                                   LENGTH (lv$decimales) - 2,
                                   3),
                           'j'),
                        'jsp')
                  || lv$multiples (i)
                  || lv$mots_complets;
            END IF;

            lv$decimales :=
               SUBSTR (lv$decimales, 1, LENGTH (lv$decimales) - 3);
         END LOOP;

         --ajoute les zeros après la virgule
         li$nb_zero :=
              INSTR (
                 TRANSLATE (SUBSTR (pn$nombre - lv$entier, 2),
                            '123456789',
                            'x'),
                 'x')
            - 1;

         IF li$nb_zero > 0
         THEN
            FOR i IN 1 .. li$nb_zero
            LOOP
               lv$mots_complets := 'zero ' || lv$mots_complets;
            END LOOP;
         END IF;

         -- Annonce la décimale (remplacer par Euro pour les montants en euros par exemple)
         --lv$mots_complets := ' '||nvl(vCurr,'point')||' and ' || lv$mots_complets;
         lv$mots_complets := ' and ' || lv$mots_complets;
      END IF;

      lv$mots_complets := ' ' || NVL (vCurr, '') || lv$mots_complets;

      --
      -- Traitement de la partie entière
      --
      IF NVL (lv$entier, 0) = 0
      THEN
         lv$mots_complets := 'zero' || lv$mots_complets;
      ELSE
         FOR i IN 1 .. lv$multiples.COUNT
         LOOP
            EXIT WHEN lv$entier IS NULL;

            --
            IF (SUBSTR (lv$entier, LENGTH (lv$entier) - 2, 3) <> 0)
            THEN
               lv$mots_complets :=
                     TO_CHAR (
                        TO_DATE (
                           SUBSTR (lv$entier, LENGTH (lv$entier) - 2, 3),
                           'j'),
                        'jsp')
                  || lv$multiples (i)
                  || lv$mots_complets;
            END IF;

            lv$entier := SUBSTR (lv$entier, 1, LENGTH (lv$entier) - 3);
         END LOOP;
      END IF;

      RETURN lv$mots_complets;
   END to_word_en;

   FUNCTION translate_fr (pn$nombre_en IN VARCHAR2)
      RETURN VARCHAR2
   IS
      lv$nombre_fr   VARCHAR2 (255);
   BEGIN
      lv$nombre_fr :=
         REPLACE (
            REPLACE (
               REPLACE (
                  REPLACE (
                     REPLACE (
                        REPLACE (
                           REPLACE (
                              REPLACE (
                                 REPLACE (
                                    REPLACE (
                                       REPLACE (
                                          REPLACE (
                                             REPLACE (
                                                REPLACE (
                                                   REPLACE (
                                                      REPLACE (
                                                         REPLACE (
                                                            REPLACE (
                                                               REPLACE (
                                                                  REPLACE (
                                                                     REPLACE (
                                                                        REPLACE (
                                                                           REPLACE (
                                                                              REPLACE (
                                                                                 REPLACE (
                                                                                    REPLACE (
                                                                                       REPLACE (
                                                                                          REPLACE (
                                                                                             REPLACE (
                                                                                                REPLACE (
                                                                                                   REPLACE (
                                                                                                      REPLACE (
                                                                                                         REPLACE (
                                                                                                            REPLACE (
                                                                                                               REPLACE (
                                                                                                                  REPLACE (
                                                                                                                     REPLACE (
                                                                                                                        REPLACE (
                                                                                                                           REPLACE (
                                                                                                                              REPLACE (
                                                                                                                                 REPLACE (
                                                                                                                                    REPLACE (
                                                                                                                                       REPLACE (
                                                                                                                                          REPLACE (
                                                                                                                                             REPLACE (
                                                                                                                                                REPLACE (
                                                                                                                                                   REPLACE (
                                                                                                                                                      REPLACE (
                                                                                                                                                         REPLACE (
                                                                                                                                                            REPLACE (
                                                                                                                                                               REPLACE (
                                                                                                                                                                  REPLACE (
                                                                                                                                                                     REPLACE (
                                                                                                                                                                        REPLACE (
                                                                                                                                                                           REPLACE (
                                                                                                                                                                              REPLACE (
                                                                                                                                                                                 REPLACE (
                                                                                                                                                                                    REPLACE (
                                                                                                                                                                                       REPLACE (
                                                                                                                                                                                          REPLACE (
                                                                                                                                                                                             REPLACE (
                                                                                                                                                                                                REPLACE (
                                                                                                                                                                                                   REPLACE (
                                                                                                                                                                                                      REPLACE (
                                                                                                                                                                                                         REPLACE (
                                                                                                                                                                                                            REPLACE (
                                                                                                                                                                                                               REPLACE (
                                                                                                                                                                                                                  REPLACE (
                                                                                                                                                                                                                     REPLACE (
                                                                                                                                                                                                                        REPLACE (
                                                                                                                                                                                                                           REPLACE (
                                                                                                                                                                                                                              REPLACE (
                                                                                                                                                                                                                                 REPLACE (
                                                                                                                                                                                                                                    REPLACE (
                                                                                                                                                                                                                                       REPLACE (
                                                                                                                                                                                                                                          REPLACE (
                                                                                                                                                                                                                                             REPLACE (
                                                                                                                                                                                                                                                REPLACE (
                                                                                                                                                                                                                                                   REPLACE (
                                                                                                                                                                                                                                                      REPLACE (
                                                                                                                                                                                                                                                         REPLACE (
                                                                                                                                                                                                                                                            REPLACE (
                                                                                                                                                                                                                                                               REPLACE (
                                                                                                                                                                                                                                                                  REPLACE (
                                                                                                                                                                                                                                                                     REPLACE (
                                                                                                                                                                                                                                                                        REPLACE (
                                                                                                                                                                                                                                                                           REPLACE (
                                                                                                                                                                                                                                                                              REPLACE (
                                                                                                                                                                                                                                                                                 REPLACE (
                                                                                                                                                                                                                                                                                    REPLACE (
                                                                                                                                                                                                                                                                                       REPLACE (
                                                                                                                                                                                                                                                                                          REPLACE (
                                                                                                                                                                                                                                                                                             REPLACE (
                                                                                                                                                                                                                                                                                                REPLACE (
                                                                                                                                                                                                                                                                                                   REPLACE (
                                                                                                                                                                                                                                                                                                      REPLACE (
                                                                                                                                                                                                                                                                                                         REPLACE (
                                                                                                                                                                                                                                                                                                            REPLACE (
                                                                                                                                                                                                                                                                                                               REPLACE (
                                                                                                                                                                                                                                                                                                                  REPLACE (
                                                                                                                                                                                                                                                                                                                     REPLACE (
                                                                                                                                                                                                                                                                                                                        REPLACE (
                                                                                                                                                                                                                                                                                                                           REPLACE (
                                                                                                                                                                                                                                                                                                                              REPLACE (
                                                                                                                                                                                                                                                                                                                                 REPLACE (
                                                                                                                                                                                                                                                                                                                                    REPLACE (
                                                                                                                                                                                                                                                                                                                                       REPLACE (
                                                                                                                                                                                                                                                                                                                                          REPLACE (
                                                                                                                                                                                                                                                                                                                                             REPLACE (
                                                                                                                                                                                                                                                                                                                                                REPLACE (
                                                                                                                                                                                                                                                                                                                                                   REPLACE (
                                                                                                                                                                                                                                                                                                                                                      REPLACE (
                                                                                                                                                                                                                                                                                                                                                         REPLACE (
                                                                                                                                                                                                                                                                                                                                                            REPLACE (
                                                                                                                                                                                                                                                                                                                                                               pn$nombre_en,
                                                                                                                                                                                                                                                                                                                                                               'million',
                                                                                                                                                                                                                                                                                                                                                               'millions'),
                                                                                                                                                                                                                                                                                                                                                            'billion',
                                                                                                                                                                                                                                                                                                                                                            'milliards'),
                                                                                                                                                                                                                                                                                                                                                         'trillion',
                                                                                                                                                                                                                                                                                                                                                         'trillions'),
                                                                                                                                                                                                                                                                                                                                                      'quadrillion',
                                                                                                                                                                                                                                                                                                                                                      'quadrillions'),
                                                                                                                                                                                                                                                                                                                                                   'quintillion',
                                                                                                                                                                                                                                                                                                                                                   'cintillions'),
                                                                                                                                                                                                                                                                                                                                                'sextillion',
                                                                                                                                                                                                                                                                                                                                                'sextillions'),
                                                                                                                                                                                                                                                                                                                                             'septillion',
                                                                                                                                                                                                                                                                                                                                             'septillions'),
                                                                                                                                                                                                                                                                                                                                          'octillion',
                                                                                                                                                                                                                                                                                                                                          'octillions'),
                                                                                                                                                                                                                                                                                                                                       'nonillion',
                                                                                                                                                                                                                                                                                                                                       'nonillions'),
                                                                                                                                                                                                                                                                                                                                    'decillion',
                                                                                                                                                                                                                                                                                                                                    'decillions'),
                                                                                                                                                                                                                                                                                                                                 'undecillion',
                                                                                                                                                                                                                                                                                                                                 'undecillions'),
                                                                                                                                                                                                                                                                                                                              'duodecillion',
                                                                                                                                                                                                                                                                                                                              'duodecillions'),
                                                                                                                                                                                                                                                                                                                           'tridecillion',
                                                                                                                                                                                                                                                                                                                           'tridecillions'),
                                                                                                                                                                                                                                                                                                                        'quaddecillion',
                                                                                                                                                                                                                                                                                                                        'quaddecillions'),
                                                                                                                                                                                                                                                                                                                     'quindecillion',
                                                                                                                                                                                                                                                                                                                     'quindecillions'),
                                                                                                                                                                                                                                                                                                                  'sexdecillion',
                                                                                                                                                                                                                                                                                                                  'sexdecillions'),
                                                                                                                                                                                                                                                                                                               'septdecillion',
                                                                                                                                                                                                                                                                                                               'septdecillions'),
                                                                                                                                                                                                                                                                                                            'octdecillion',
                                                                                                                                                                                                                                                                                                            'octdecillions'),
                                                                                                                                                                                                                                                                                                         'nondecillion',
                                                                                                                                                                                                                                                                                                         'nondecillions'),
                                                                                                                                                                                                                                                                                                      'dedecillion',
                                                                                                                                                                                                                                                                                                      'dedecillions'),
                                                                                                                                                                                                                                                                                                   'thousand',
                                                                                                                                                                                                                                                                                                   'mille'),
                                                                                                                                                                                                                                                                                                'hundred',
                                                                                                                                                                                                                                                                                                'cent'),
                                                                                                                                                                                                                                                                                             'ninety',
                                                                                                                                                                                                                                                                                             'quatre-vingt-dix'),
                                                                                                                                                                                                                                                                                          'eighty',
                                                                                                                                                                                                                                                                                          'quatre-vingts'),
                                                                                                                                                                                                                                                                                       'seventy',
                                                                                                                                                                                                                                                                                       'soixante-dix'),
                                                                                                                                                                                                                                                                                    'sixty',
                                                                                                                                                                                                                                                                                    'soixante'),
                                                                                                                                                                                                                                                                                 'fifty',
                                                                                                                                                                                                                                                                                 'cinquante'),
                                                                                                                                                                                                                                                                              'forty',
                                                                                                                                                                                                                                                                              'quarante'),
                                                                                                                                                                                                                                                                           'thirty',
                                                                                                                                                                                                                                                                           'trente'),
                                                                                                                                                                                                                                                                        'twenty',
                                                                                                                                                                                                                                                                        'vingt'),
                                                                                                                                                                                                                                                                     'nineteen',
                                                                                                                                                                                                                                                                     'dix-neuf'),
                                                                                                                                                                                                                                                                  'eighteen',
                                                                                                                                                                                                                                                                  'dix-huit'),
                                                                                                                                                                                                                                                               'seventeen',
                                                                                                                                                                                                                                                               'dix-sept'),
                                                                                                                                                                                                                                                            'sixteen',
                                                                                                                                                                                                                                                            'seize'),
                                                                                                                                                                                                                                                         'fifteen',
                                                                                                                                                                                                                                                         'quinze'),
                                                                                                                                                                                                                                                      'fourteen',
                                                                                                                                                                                                                                                      'quatorze'),
                                                                                                                                                                                                                                                   'thirteen',
                                                                                                                                                                                                                                                   'treize'),
                                                                                                                                                                                                                                                'twelve',
                                                                                                                                                                                                                                                'douze'),
                                                                                                                                                                                                                                             'eleven',
                                                                                                                                                                                                                                             'onze'),
                                                                                                                                                                                                                                          'ten',
                                                                                                                                                                                                                                          'dix'),
                                                                                                                                                                                                                                       'nine',
                                                                                                                                                                                                                                       'neuf'),
                                                                                                                                                                                                                                    'eight',
                                                                                                                                                                                                                                    'huit'),
                                                                                                                                                                                                                                 'seven',
                                                                                                                                                                                                                                 'sept'),
                                                                                                                                                                                                                              'five',
                                                                                                                                                                                                                              'cinq'),
                                                                                                                                                                                                                           'four',
                                                                                                                                                                                                                           'quatre'),
                                                                                                                                                                                                                        'three',
                                                                                                                                                                                                                        'trois'),
                                                                                                                                                                                                                     'two',
                                                                                                                                                                                                                     'deux'),
                                                                                                                                                                                                                  'one',
                                                                                                                                                                                                                  'un'),
                                                                                                                                                                                                               'dix-six',
                                                                                                                                                                                                               'seize'),
                                                                                                                                                                                                            'dix-cinq',
                                                                                                                                                                                                            'quinze'),
                                                                                                                                                                                                         'dix-quatre',
                                                                                                                                                                                                         'quatorze'),
                                                                                                                                                                                                      'dix-trois',
                                                                                                                                                                                                      'treize'),
                                                                                                                                                                                                   'dix-deux',
                                                                                                                                                                                                   'douze'),
                                                                                                                                                                                                'dix-un',
                                                                                                                                                                                                'onze'),
                                                                                                                                                                                             '-un ',
                                                                                                                                                                                             '-une '),
                                                                                                                                                                                          'un cent',
                                                                                                                                                                                          'cent'),
                                                                                                                                                                                       'une',
                                                                                                                                                                                       'un'),
                                                                                                                                                                                    'soixante-onze',
                                                                                                                                                                                    'soixante et onze'),
                                                                                                                                                                                 'quatre-vingts-',
                                                                                                                                                                                 'quatre-vingt-'),
                                                                                                                                                                              '-un',
                                                                                                                                                                              ' et un'),
                                                                                                                                                                           'quatre-vingt et un',
                                                                                                                                                                           'quatre-vingt-un'),
                                                                                                                                                                        'deux cent',
                                                                                                                                                                        'deux cents'),
                                                                                                                                                                     'trois cent',
                                                                                                                                                                     'trois cents'),
                                                                                                                                                                  'quatre cent',
                                                                                                                                                                  'quatre cents'),
                                                                                                                                                               'cinq cent',
                                                                                                                                                               'cinq cents'),
                                                                                                                                                            'six cent',
                                                                                                                                                            'six cents'),
                                                                                                                                                         'sept cent',
                                                                                                                                                         'sept cents'),
                                                                                                                                                      'huit cent',
                                                                                                                                                      'huit cents'),
                                                                                                                                                   'neuf cent',
                                                                                                                                                   'neuf cents'),
                                                                                                                                                'cents ',
                                                                                                                                                'cent '),
                                                                                                                                             'un millions',
                                                                                                                                             'un million'),
                                                                                                                                          'un bidecillions',
                                                                                                                                          'un bidecillion'),
                                                                                                                                       'un cintillions',
                                                                                                                                       'un cintillion'),
                                                                                                                                    'un milliards',
                                                                                                                                    'un milliard'),
                                                                                                                                 'un trillions',
                                                                                                                                 'un trillion'),
                                                                                                                              'un quadrillions',
                                                                                                                              'un quadrillion'),
                                                                                                                           'un sextillions',
                                                                                                                           'un sextillion'),
                                                                                                                        'un septillions',
                                                                                                                        'un septillion'),
                                                                                                                     'un octillions',
                                                                                                                     'un octillion'),
                                                                                                                  'un nonillions',
                                                                                                                  'un nonillion'),
                                                                                                               'un decillions',
                                                                                                               'un decillion'),
                                                                                                            'un undecillions',
                                                                                                            'un undecillion'),
                                                                                                         'un duodecillions',
                                                                                                         'un duodecillion'),
                                                                                                      'un tridecillions',
                                                                                                      'un tridecillion'),
                                                                                                   'un quaddecillions',
                                                                                                   'un quaddecillion'),
                                                                                                'un quindecillions',
                                                                                                'un quindecillion'),
                                                                                             'un sexdecillions',
                                                                                             'un sexdecillion'),
                                                                                          'un septdecillions',
                                                                                          'un septdecillion'),
                                                                                       'un octdecillions',
                                                                                       'un octdecillion'),
                                                                                    'un nondecillions',
                                                                                    'un nondecillion'),
                                                                                 'un dedecillions',
                                                                                 'un dedecillion'),
                                                                              '-un trillion',
                                                                              '-un trillions'),
                                                                           '-un quadrillion',
                                                                           '-un quadrillions'),
                                                                        '-un sextillion',
                                                                        '-un sextillions'),
                                                                     '-un septillion',
                                                                     '-un septillions'),
                                                                  '-un octillion',
                                                                  '-un octillions'),
                                                               '-un nonillion',
                                                               '-un nonillions'),
                                                            '-un decillion',
                                                            '-un decillions'),
                                                         '-un undecillion',
                                                         '-un undecillions'),
                                                      '-un duodecillion',
                                                      '-un duodecillions'),
                                                   '-un tridecillion',
                                                   '-un tridecillions'),
                                                '-un quaddecillion',
                                                '-un quaddecillions'),
                                             '-un quindecillion',
                                             '-un quindecillions'),
                                          '-un sexdecillion',
                                          '-un sexdecillions'),
                                       '-un septdecillion',
                                       '-un septdecillions'),
                                    '-un octdecillion',
                                    '-un octdecillions'),
                                 '-un nondecillion',
                                 '-un nondecillions'),
                              '-un dedecillion',
                              '-un dedecillions'),
                           '-un million',
                           '-un millions'),
                        '-un bidecillion',
                        '-un bidecillions'),
                     '-un cintillion',
                     '-un cintillions'),
                  '-un milliard',
                  '-un milliards'),
               'point',
               'virgule'),
            '  ',
            ' ');

      IF SUBSTR (lv$nombre_fr, 1, 8) = 'un mille'
      THEN
         lv$nombre_fr := SUBSTR (lv$nombre_fr, 4);
      END IF;

      RETURN REPLACE (lv$nombre_fr, 'and', 'et');
   END translate_fr;

   FUNCTION SumElemPreviousMonth (EmpId   IN hrm_person.hrm_person_id%TYPE,
                                  vCode   IN VARCHAR2)
      RETURN NUMBER
   -- Calcule la valeur d'une rubrique dans la période précédente (le mois d'avant)
   IS
      retour   NUMBER;
   BEGIN
      SELECT -NVL (hrm_functions.sumelem (
                      EmpId,
                      vCode,
                      TRUNC (ADD_MONTHS (hrm_date.ACTIVEPERIODENDDATE, -1),
                             'MONTH'),
                      ADD_MONTHS (hrm_date.ACTIVEPERIODENDDATE, -1)),
                   0)
        INTO retour
        FROM DUAL;

      RETURN retour;
   END SumElemPreviousMonth;

   FUNCTION GetBanqueEmpSeq0 (EmpId hrm_person.hrm_person_id%TYPE)
      RETURN VARCHAR2
   -- Retourne la banque d'un employé en SEQUENCE 0 (Gestion des employés / Employé / Réf.financières)
   IS
      retour   VARCHAR2 (200);
   BEGIN
      SELECT DISTINCT --HRM_FINANCIAL_REF_ID,
                      --HRM_EMPLOYEE_ID,
                      --HRM_FINANCIAL_REF.PC_BANK_ID, --> BANQUE
                      BAN_NAME1
        INTO retour
        --HRM_FINANCIAL_REF.PC_CNTRY_ID, --> PAYS
        --CNTNAME,
        --C_FINANCIAL_REF_TYPE,
        --FIN_NAME,
        --FIN_AMOUNT,
        --FIN_ACCOUNT_NUMBER,
        --FIN_SEQUENCE,
        --HRM_FINANCIAL_REF.ACS_FINANCIAL_CURRENCY_ID, --> DEVISE
        --ACS_FINANCIAL_CURRENCY.PC_CURR_ID,
        --PCS.PC_CURR.CURRNAME
        FROM HRM_FINANCIAL_REF,
             PCS.PC_BANK,
             PCS.PC_CNTRY,
             ACS_FINANCIAL_CURRENCY,
             PCS.PC_CURR
       WHERE     HRM_FINANCIAL_REF.PC_BANK_ID = PCS.PC_BANK.PC_BANK_ID -- JOINTURE BANQUE
             /*
             AND HRM_FINANCIAL_REF.PC_CNTRY_ID = (CASE WHEN HRM_FINANCIAL_REF.PC_CNTRY_ID is not null THEN PCS.PC_CNTRY.PC_CNTRY_ID
                                                       WHEN HRM_FINANCIAL_REF.PC_CNTRY_ID is null THEN 1
                                                       END)
             */
             AND HRM_FINANCIAL_REF.ACS_FINANCIAL_CURRENCY_ID =
                    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID -- JOINTURE DEVISE 1
             AND ACS_FINANCIAL_CURRENCY.PC_CURR_ID = PCS.PC_CURR.PC_CURR_ID -- JOINTURE DEVISE 2
             AND HRM_EMPLOYEE_ID = EmpId
             AND FIN_SEQUENCE = 0;

      RETURN retour;
   END GetBanqueEmpSeq0;

   FUNCTION GetBanqueEmpSeq1 (EmpId hrm_person.hrm_person_id%TYPE)
      RETURN VARCHAR2
   -- Retourne la banque d'un employé en SEQUENCE 1 (Gestion des employés / Employé / Réf.financières)
   IS
      retour   VARCHAR2 (200);
   BEGIN
      SELECT DISTINCT BAN_NAME1
        INTO retour
        FROM HRM_FINANCIAL_REF,
             PCS.PC_BANK,
             PCS.PC_CNTRY,
             ACS_FINANCIAL_CURRENCY,
             PCS.PC_CURR
       WHERE     HRM_FINANCIAL_REF.PC_BANK_ID = PCS.PC_BANK.PC_BANK_ID -- JOINTURE BANQUE
             AND HRM_FINANCIAL_REF.ACS_FINANCIAL_CURRENCY_ID =
                    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID -- JOINTURE DEVISE 1
             AND ACS_FINANCIAL_CURRENCY.PC_CURR_ID = PCS.PC_CURR.PC_CURR_ID -- JOINTURE DEVISE 2
             AND HRM_EMPLOYEE_ID = EmpId
             AND FIN_SEQUENCE = 1;

      RETURN retour;
   END GetBanqueEmpSeq1;

   FUNCTION GetBanqueEmpSeq2 (EmpId hrm_person.hrm_person_id%TYPE)
      RETURN VARCHAR2
   -- Retourne la banque d'un employé en SEQUENCE 2 (Gestion des employés / Employé / Réf.financières)
   IS
      retour   VARCHAR2 (200);
   BEGIN
      SELECT DISTINCT BAN_NAME1
        INTO retour
        FROM HRM_FINANCIAL_REF,
             PCS.PC_BANK,
             PCS.PC_CNTRY,
             ACS_FINANCIAL_CURRENCY,
             PCS.PC_CURR
       WHERE     HRM_FINANCIAL_REF.PC_BANK_ID = PCS.PC_BANK.PC_BANK_ID -- JOINTURE BANQUE
             AND HRM_FINANCIAL_REF.ACS_FINANCIAL_CURRENCY_ID =
                    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID -- JOINTURE DEVISE 1
             AND ACS_FINANCIAL_CURRENCY.PC_CURR_ID = PCS.PC_CURR.PC_CURR_ID -- JOINTURE DEVISE 2
             AND HRM_EMPLOYEE_ID = EmpId
             AND FIN_SEQUENCE = 2;

      RETURN retour;
   END GetBanqueEmpSeq2;

   FUNCTION GetChampFinance1 (EmpId hrm_person.hrm_person_id%TYPE)
      RETURN VARCHAR2
   -- Retourne la saisie dans "Champ Finance 1" (Gestion des employés / Attributs / OGIM)
   IS
      retour   VARCHAR2 (200);
   BEGIN
      SELECT DISTINCT
             com_vfields_4_prnt.GetVF2Value_char ('HRM_PERSON',
                                                  'VFLD_CHAMP_FINANCE1',
                                                  EmpId)
        INTO retour
        FROM DUAL;

      RETURN retour;
   END GetChampFinance1;

   FUNCTION GetChampFinance2 (EmpId hrm_person.hrm_person_id%TYPE)
      RETURN VARCHAR2
   -- Retourne la saisie dans "Champ Finance 2" (Gestion des employés / Attributs / OGIM)
   IS
      retour   VARCHAR2 (200);
   BEGIN
      SELECT DISTINCT
             com_vfields_4_prnt.GetVF2Value_char ('HRM_PERSON',
                                                  'VFLD_CHAMP_FINANCE2',
                                                  EmpId)
        INTO retour
        FROM DUAL;

      RETURN retour;
   END GetChampFinance2;

   FUNCTION GetSocieteAffectPeriod (Empid NUMBER, vPeriod VARCHAR2)
      RETURN VARCHAR2
   -- retourne la société d'affectration de l'employé (à une date donnée (période))
   IS
      retour       VARCHAR2 (100);
      ContractId   NUMBER;
   BEGIN
      SELECT MAX (DIC_CONTRACT_CATEGORY_ID)
        INTO retour
        FROM hrm_contract a, dic_salary_number b
       WHERE     a.dic_salary_number_id = b.dic_salary_number_id
             AND hrm_employee_id = EmpId
             AND TO_CHAR (con_begin, 'YYYYMM') <= vPeriod
             AND (TO_CHAR (con_end, 'YYYYMM') >= vPeriod OR con_end IS NULL);

      -- Si pays d'affectation = null -> recherche pays d'affectation du dernier contrat en date
      IF retour IS NULL
      THEN
         SELECT MAX (DIC_CONTRACT_CATEGORY_ID)
           INTO retour
           FROM hrm_contract c1,
                (  SELECT MAX (con_begin) con_begin, hrm_employee_id
                     FROM hrm_contract
                    WHERE TO_CHAR (con_end, 'YYYYMM') < vPeriod
                 GROUP BY hrm_employee_id) c2,
                dic_salary_number d
          WHERE     c1.con_begin = c2.con_begin
                AND c1.hrm_employee_id = c2.hrm_employee_id
                AND c1.hrm_employee_id = EmpId
                AND c1.dic_salary_number_id = d.dic_salary_number_id;
      END IF;

      -- Si pays d'affectation toujours null -> recherche pays d'affectation du contrat suivant
      IF retour IS NULL
      THEN
         SELECT MAX (DIC_CONTRACT_CATEGORY_ID)
           INTO retour
           FROM hrm_contract c1,
                (  SELECT MIN (con_begin) con_begin, hrm_employee_id
                     FROM hrm_contract
                    WHERE TO_CHAR (con_begin, 'YYYYMM') > vPeriod
                 GROUP BY hrm_employee_id) c2,
                dic_salary_number d
          WHERE     c1.con_begin = c2.con_begin
                AND c1.hrm_employee_id = c2.hrm_employee_id
                AND c1.hrm_employee_id = EmpId
                AND c1.dic_salary_number_id = d.dic_salary_number_id;
      END IF;

      RETURN retour;
   END GetSocieteAffectPeriod;

   FUNCTION get_pers_departement_prin (EmpId NUMBER)
      RETURN VARCHAR2
   -- retourne le département  de l'employé:
   --
   IS
      retour   VARCHAR2 (100);
   BEGIN
      SELECT HEB_DEPARTMENT_ID
        INTO retour
        FROM HRM_EMPLOYEE_BREAK
       WHERE hrm_employee_id = EmpId;

      RETURN retour;
   END get_pers_departement_prin;
   
   FUNCTION get_rco_descr (vRcoTitle VARCHAR2)
   RETURN VARCHAR2
   -- Retourne la description du client (rco_title).
   IS
      retour   VARCHAR2 (200);
   BEGIN
      select RCO_DESCRIPTION
        into retour
        from doc_record rec 
       where rec.RCO_TITLE = vRcoTitle;
      
      RETURN retour;
      
   END get_rco_descr;
   
   FUNCTION GetDécTaux --(vRcoTitle VARCHAR2)
   RETURN VARCHAR2
   -- Retourne 1 pour faire fonctionner la rubrique "MonnaieDécTaux"
   IS
      retour   VARCHAR2 (200);
   BEGIN
      select 1
        into retour
        from dual; 

      RETURN retour;
      
   END GetDécTaux;
   
   FUNCTION GetTauxIS (vCanton VARCHAR2)
   RETURN NUMBER
   -- Retourne le taux de commission de l'impôt à la source (selon Canton)
   IS
      retour NUMBER;
   BEGIN
      select TAX_COMMISSION 
        into retour
        from HRM_TAXSOURCE_DEFINITION 
       where C_HRM_CANTON = vCanton;

      RETURN retour;
      
   END GetTauxIS;
   
   
END HRM_ITX;
