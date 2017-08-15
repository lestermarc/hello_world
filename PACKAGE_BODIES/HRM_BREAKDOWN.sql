--------------------------------------------------------
--  DDL for Package Body HRM_BREAKDOWN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_BREAKDOWN" 
IS

  function StrToNumber(astring IN VARCHAR2) return NUMBER
  is
  begin
    return To_Number(astring);

    exception
      when INVALID_NUMBER then
        return 0.0;
  end StrToNumber;


  procedure BreakInit(breakid IN hrm_break.hrm_break_id%TYPE)
  is
  begin
    for tplProvBreak in (
        select hrm_break_id from hrm_break
        where brk_status = 0 and hrm_break_id <> breakid)
    loop
      delete from hrm_salary_breakdown
      where hrm_break_id = tplProvBreak.hrm_break_id;

      delete from hrm_break
      where hrm_break_id = tplProvBreak.hrm_break_id;
   end loop;
  end BreakInit;

  procedure LaunchBreak(
    empid IN hrm_person.hrm_person_id%TYPE,
    paynum IN hrm_history_detail.his_pay_num%TYPE,
    currency IN acs_financial_currency.acs_financial_currency_id%TYPE,
    period IN DATE,
    breakid IN hrm_break.hrm_break_id%TYPE,
    status IN INTEGER)
  is
    -- Curseur du détail de l'historique pour le décompte donné en paramètre ( empid / paynum )
    -- Contient toutes les données nécessaires à l'imputation
    cursor crPayDet is
      -- Imputation directe selon HRM_HISTORY_DETAIL_BREAK de l'élément
      -- Priorité : données du job si connu, sinon de l'imputation
      SELECT 0 hrm_break_group_id,
           eeb_sequence,
           eeb_d_cgbase,
           eeb_c_cgbase,
           d.hrm_history_detail_id,
           hrm_elements_id,
           Nvl(j.job_div_number, eeb_divbase) div_number,
           eeb_cpnbase,
           Nvl(job_cda_number, eeb_cdabase) cda_number,
           Nvl(job_pf_number, eeb_pfbase) pf_number,
           Nvl(job_pj_number, eeb_pjbase) pj_number,
           eeb_per_rate / 100 eeb_per_rate,
           Nvl(j.dic_department_id, db.dic_department_id) heb_department_id,
           Nvl(j.job_shift, eeb_shift) heb_shift,
           Nvl(j.job_rco_title, eeb_rco_title) rco_title,
           his_pay_sum_val * eeb_per_rate / 100 his_pay_sum_val,
           his_currency_value * eeb_per_rate / 100 his_currency_value,
           his_ref_value * eeb_per_rate / 100 his_ref_value,
           his_zl
        FROM hrm_history_detail d, hrm_history_detail_break db, hrm_job j, hrm_break_structure s
       WHERE d.hrm_elements_id = s.bre_item_id
        AND his_pay_num = paynum
        AND hrm_employee_id = empid
        AND d.hrm_history_detail_id = db.hrm_history_detail_id
        AND j.job_code(+) = db.job_code
      UNION ALL
      -- Imputation en fonction du groupe de comptabilisation
      -- Selon table HRM_BREAK_GROUP ( définition des éléments constitutifs du groupe )
      -- uniquement pour les éléments n'ayant pas fait l'objet d'une comptabilisation plus haut
      -- En fonction d'éléments de comptabilisation issus de HRM_HISTORY_DETAIL_BREAK ou issus de HRM_EMPLOYEE_BREAK
      SELECT f.hrm_break_group_id,
           eeb_sequence,
           NULL,
           NULL,
           hrm_history_detail_id,
           d.hrm_elements_id,
           div_number,
           NULL,
           cda_number,
           pf_number,
           pj_number,
           case when (totalgrp = 0) then Abs(val)/AbsTotalGrp else val/totalgrp end,
           dic_department_id,
           eeb_shift,
           rco_title,
           case when (totalgrp = 0) then
             his_pay_sum_val * Abs(val) / Abstotalgrp
           else
             his_pay_sum_val * val / totalgrp
           end,
           case when (totalgrp_curr = 0) then
             his_currency_value * Abs(val_curr) / Abstotalgrp_curr
           else
             his_currency_value * val_curr / totalgrp_curr
           end,
           case when (totalgrp_ref = 0) then
             his_ref_value * Abs(val_ref) / Abstotalgrp_ref
           else
             his_ref_value * val_ref / totalgrp_ref
           end,
           his_zl
        FROM hrm_history_detail d,
           hrm_elements_family f,
           hrm_break_structure str,
           /* Imputations des éléments du groupe
             Cascade : job de l'historique, historique, ventilation de l'employé
             La proportion affectée correspond à la proportion du montant de référence affecté à l'imputation dans le groupe.
           */
           (SELECT bgr.hrm_break_group_id,
                eeb_sequence,
                d2.his_pay_sum_val * eeb_per_rate / 100 val,
                d2.his_currency_value * eeb_per_rate / 100 val_curr,
                d2.his_ref_value * eeb_per_rate / 100 val_ref,
                Nvl(j2.job_div_number, eeb_divbase) div_number,
                Nvl(j2.job_cda_number, eeb_cdabase) cda_number,
                Nvl(j2.job_pf_number, eeb_pfbase) pf_number,
                Nvl(j2.job_pj_number, eeb_pjbase) pj_number,
                Nvl(j2.dic_department_id, db2.dic_department_id) dic_department_id,
                Nvl(j2.job_shift, eeb_shift) eeb_shift,
                Nvl(j2.job_rco_title, eeb_rco_title) rco_title
             FROM hrm_history_detail d2,
                hrm_elements_family f2,
                hrm_history_detail_break db2,
                hrm_break_group_root bgr,
                hrm_job j2
            WHERE f2.hrm_elements_root_id = bgr.hrm_elements_root_id
              AND d2.hrm_elements_id = f2.hrm_elements_id
              AND d2.hrm_employee_id = empid
              AND d2.his_pay_num = paynum
              AND d2.hrm_history_detail_id = db2.hrm_history_detail_id
              AND db2.job_code = j2.job_code(+)
            UNION ALL
            SELECT  bgr.hrm_break_group_id,
                  hrm_employee_break_id,
                  Sum(d2.his_pay_sum_val * heb_ratio / totprop),
                  Sum(d2.his_currency_value * heb_ratio / totprop),
                  Sum(d2.his_ref_value * heb_ratio / totprop),
                  heb_div_number,
                  heb_cda_number,
                  heb_pf_number,
                  heb_pj_number,
                  heb_department_id,
                  heb_shift,
                  rco_title
              FROM hrm_history_detail d2,
                  hrm_elements_family f2,
                  hrm_break_group_root bgr,
                  v_hrm_empl_break vb,
                  (SELECT Sum(heb_ratio) totprop
                   FROM v_hrm_empl_break
                   WHERE hrm_employee_id = empid) vbt
              WHERE f2.hrm_elements_root_id = bgr.hrm_elements_root_id
               AND d2.hrm_employee_id = empid
               AND elf_is_reference = 1
               AND d2.his_pay_num = paynum
               AND d2.hrm_elements_id = f2.hrm_elements_id
               AND vb.hrm_employee_id = empid
               AND NOT EXISTS (SELECT 1 FROM hrm_history_detail_break db3
                               WHERE db3.hrm_history_detail_id = d2.hrm_history_detail_id)
            GROUP BY bgr.hrm_break_group_id,
                  hrm_employee_break_id,
                  heb_div_number,
                  heb_cda_number,
                  heb_pf_number,
                  heb_pj_number,
                  heb_department_id,
                  heb_shift,
                  rco_title) ref_hbr,
           (SELECT  bgr.hrm_break_group_id,
                  Sum(d2.his_pay_sum_val) totalgrp,
                  Sum(d2.his_currency_value) totalgrp_curr,
                  Sum(d2.his_ref_value) totalgrp_ref,
                  Sum(Abs(d2.his_pay_sum_val)) AbsTotalgrp,
                  Sum(Abs(d2.his_currency_value)) AbsTotalgrp_curr,
                  Sum(Abs(d2.his_ref_value)) AbsTotalgrp_ref
              FROM hrm_history_detail d2, hrm_elements_family f2, hrm_break_group_root bgr
              WHERE d2.hrm_elements_id = f2.hrm_elements_id
               AND bgr.hrm_elements_root_id = f2.hrm_elements_root_id
               AND d2.hrm_employee_id = empid
               AND elf_is_reference = 1
               AND d2.his_pay_num = paynum
            GROUP BY bgr.hrm_break_group_id) ref_tot
       WHERE hrm_employee_id = empid
        AND his_pay_num = paynum
        AND f.hrm_elements_id = d.hrm_elements_id
        AND str.bre_item_id = d.hrm_elements_id
        AND f.hrm_break_group_id = ref_tot.hrm_break_group_id
        AND f.hrm_break_group_id = ref_hbr.hrm_break_group_id
        AND NOT EXISTS (SELECT 1 FROM hrm_history_detail_break b
                        WHERE b.hrm_history_detail_id = d.hrm_history_detail_id)
      UNION ALL
      -- Eléments n'intégrant aucun groupe et donc comptabilisés selon définition de HRM_EMPLOYEE_BREAK
      SELECT hrm_break_group_id,
           hrm_employee_break_id,
           NULL,
           NULL,
           hrm_history_detail_id,
           d.hrm_elements_id,
           heb_div_number,
           NULL,
           heb_cda_number,
           heb_pf_number,
           heb_pj_number,
           heb_ratio / val,
           heb_department_id,
           heb_shift,
           rco_title,
           his_pay_sum_val * heb_ratio / val,
           his_currency_value * heb_ratio / val his_currency_value,
           his_ref_value * heb_ratio / val his_ref_value,
           his_zl
        FROM v_hrm_empl_break v,
           (SELECT hrm_employee_id, Sum(heb_ratio) val
            FROM v_hrm_empl_break
            WHERE hrm_employee_id = empid
            GROUP BY hrm_employee_id) vt,
           hrm_history_detail d,
           hrm_elements_family s,
           hrm_break_structure str
       WHERE d.hrm_elements_id = s.hrm_elements_id
        AND str.bre_item_id = s.hrm_elements_id
        AND v.hrm_employee_id = empid
        AND d.his_pay_num = paynum
        AND d.hrm_employee_id = empid
        AND NOT EXISTS (SELECT 1 FROM hrm_history_detail_break br
                        WHERE d.hrm_history_detail_id = br.hrm_history_detail_id)
        -- Si pas de groupe de répartition ou éléments constituants le groupe de répartition non-ventilés
        AND NOT EXISTS (SELECT 1
                    FROM hrm_history_detail d, hrm_elements_family f, hrm_break_group_root g
                    WHERE d.his_pay_num = paynum
                     AND d.hrm_employee_id = empid
                     AND f.elf_is_reference = 1
                     AND d.hrm_elements_id = f.hrm_elements_id
                     AND f.hrm_elements_root_id = g.hrm_elements_root_id
                     AND g.hrm_break_group_id = s.hrm_break_group_id)
      UNION ALL
      -- Eléments n'intégrant aucun groupe et sans données dans HRM_EMPLOYEE_BREAK
      SELECT hrm_break_group_id,
           hrm_person_id,
           NULL,
           NULL,
           hrm_history_detail_id,
           d.hrm_elements_id,
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           1,
           NULL,
           NULL,
           NULL,
           1,
           his_currency_value his_currency_value,
           his_ref_value his_ref_value,
           his_zl
        FROM hrm_person v, hrm_history_detail d, hrm_elements_family s
       WHERE d.hrm_elements_id = s.hrm_elements_id
        AND v.hrm_person_id = empid
        AND d.his_pay_num = paynum
        AND d.hrm_employee_id = empid
        AND NOT EXISTS (SELECT 1 FROM hrm_history_detail_break br
                        WHERE d.hrm_history_detail_id = br.hrm_history_detail_id)
        AND NOT EXISTS (SELECT 1 FROM hrm_employee_break
                        WHERE hrm_employee_id = empid)
        -- Si pas de groupe de répartition ou éléments constituants le groupe de répartition non-ventilés
        AND NOT EXISTS (SELECT 1
                    FROM hrm_history_detail d, hrm_elements_family f, hrm_break_group_root g
                    WHERE d.his_pay_num = paynum
                     AND d.hrm_employee_id = empid
                     AND d.hrm_elements_id = f.hrm_elements_id
                     AND f.elf_is_reference = 1
                     AND f.hrm_elements_root_id = g.hrm_elements_root_id
                     AND g.hrm_break_group_id = s.hrm_break_group_id);
  begin
    -- Ouverture du curseur du détail
    for tplPayDet in crPaydet loop
      -- Insertion dans la table de comptabilisation
      INSERT INTO hrm_salary_breakdown
      (hrm_break_id, hrm_history_detail_id, hrm_elements_id, hrm_employee_id, sab_pay_num, sab_source,
       dic_account_type_id, sab_account_id, sab_account_name, sab_amount_type, sab_amount, sab_foreign_amount,
       sab_ref_value, acs_financial_currency_id, sab_break_date, sab_pay_date, sab_exported, sab_zl)
        SELECT breakid,
             tplPayDet.hrm_history_detail_id,
             tplPayDet.hrm_elements_id,
             empid,
             paynum,
             tplPayDet.hrm_break_group_id || tplPayDet.eeb_sequence,
             dic_account_type_id,
             NULL,
             -- Si le déplacement le spécifie, remplacement des valeurs de comptabilisation
             -- par celles du détail
             DECODE(brs_replacement,
                  'R', DECODE(dic_account_type_id,
                           'CPN', tplPayDet.eeb_cpnbase,
                           'CG', DECODE(DECODE(Nvl(e.ele_swap_dc, 0),
                                          1, DECODE(Sign(DECODE(Nvl(e.ele_is_break_inverse, 0),
                                                          1, tplPayDet.his_pay_sum_val * -1,
                                                          tplPayDet.his_pay_sum_val
                                                          )
                                                    ),
                                                 -1, ald_rate * -1,
                                                 ald_rate
                                                ),
                                          ald_rate
                                         ),
                                    1, tplPayDet.eeb_d_cgbase,
                                    tplPayDet.eeb_c_cgbase
                                    ),
                           'CDA', tplPayDet.cda_number,
                           'PJ', tplPayDet.pj_number,
                           'PF', tplPayDet.pf_number,
                           'DIV', tplPayDet.div_number,
                           'DOC_RECORD', tplPayDet.rco_title,
                           '0'
                          ),
                  -- Construction du compte en fonction de l'opérateur CONC / ADD / PREF
                  DECODE(brs_operation_type,
                        'CONC', ald_acc_name
                        || Nvl(bsv_value,
                              DECODE(bsv_source_field,
                                   'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                   'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                   'HEB_PF_NUMBER', tplPayDet.pf_number,
                                   'HEB_DIV_NUMBER', tplPayDet.div_number,
                                   'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                   'HEB_SHIFT', tplPayDet.heb_shift,
                                   'HEB_RCO_TITLE', tplPayDet.rco_title,
                                   ''
                                  )
                             ),
                        'PREF', Nvl(bsv_value,
                                DECODE(bsv_source_field,
                                   'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                   'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                   'HEB_PF_NUMBER', tplPayDet.pf_number,
                                   'HEB_DIV_NUMBER', tplPayDet.div_number,
                                   'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                   'HEB_SHIFT', tplPayDet.heb_shift,
                                   'HEB_RCO_TITLE', tplPayDet.rco_title,
                                   ''
                                   )
                                )||ald_acc_name,
                        Nvl(ald_acc_name, 0)
                        + hrm_breakdown.StrToNumber(Nvl(bsv_value,
                                               DECODE(bsv_source_field,
                                                    'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                                    'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                                    'HEB_PF_NUMBER', tplPayDet.pf_number,
                                                    'HEB_DIV_NUMBER', tplPayDet.div_number,
                                                    'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                                    'HEB_SHIFT', Nvl(tplPayDet.heb_shift, '0'),
                                                    'HEB_RCO_TITLE', tplPayDet.rco_title,
                                                    '0'
                                                    )
                                              )
                                           )
                       )
                  ),
             -- La prise en compte de l'inversion débit / crédit est faite plus tard
             case when (ald_rate < 0) then 'C' else 'D' end,
             -- Tronquage de la valeur à 2 décimales
             Trunc(tplPayDet.his_pay_sum_val, 2),
             Nvl(Trunc(tplPayDet.his_currency_value,2),0),
             Nvl(Trunc(tplPayDet.his_ref_value,2),0),
             currency,
             Sysdate,
             period,
             0,
             Nvl(tplPayDet.his_zl, 0)
          FROM hrm_break_structure s, hrm_allocation_detail ad, hrm_break_shift sh, hrm_break_shift_val shv, hrm_elements e
         WHERE tplPayDet.hrm_elements_id = s.bre_item_id
          -- Source numérique
          AND sh.brs_format = 'N'
          AND sh.hrm_break_shift_id = shv.hrm_break_shift_id(+)
          AND ad.hrm_allocation_id = s.hrm_allocation_id
          AND tplPayDet.hrm_elements_id = e.hrm_elements_id
          AND sh.hrm_break_shift_id = ad.hrm_break_shift_id
          -- Déplacement à prendre en compte
          AND ((hrm_breakdown.StrToNumber(DECODE(bsv_source_field,
                                      'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                      'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                      'HEB_PF_NUMBER', tplPayDet.pf_number,
                                      'HEB_DIV_NUMBER', tplPayDet.div_number,
                                      'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                      'HEB_SHIFT', Nvl(tplPayDet.heb_shift, '0'),
                                      'HEB_RCO_TITLE', tplPayDet.rco_title,
                                      '0'
                                     )
                                ) BETWEEN hrm_breakdown.StrToNumber(bsv_source_val)
                                    AND hrm_breakdown.StrToNumber(bsv_source_val_to)
               )
               OR bsv_source_field IS NULL
              )
        UNION ALL
        SELECT breakid,
             tplPayDet.hrm_history_detail_id,
             tplPayDet.hrm_elements_id,
             empid,
             paynum,
             tplPayDet.hrm_break_group_id || tplPayDet.eeb_sequence,
             dic_account_type_id,
             NULL,
             -- Si le déplacement le spécifie, remplacement des valeurs de comptabilisation
             -- par celles du détail
             DECODE(brs_replacement,
                  'R', DECODE(dic_account_type_id,
                           'CPN', tplPayDet.eeb_cpnbase,
                           'CG', DECODE(DECODE(Nvl(e.ele_swap_dc, 0),
                                          1, DECODE(Sign(DECODE(Nvl(e.ele_is_break_inverse, 0),
                                                          1, tplPayDet.his_pay_sum_val * -1,
                                                          tplPayDet.his_pay_sum_val
                                                          )
                                                    ),
                                                 -1, ald_rate * -1,
                                                 ald_rate
                                                ),
                                          ald_rate
                                         ),
                                    1, tplPayDet.eeb_d_cgbase,
                                    tplPayDet.eeb_c_cgbase
                                    ),
                           'CDA', tplPayDet.cda_number,
                           'PJ', tplPayDet.pj_number,
                           'PF', tplPayDet.pf_number,
                           'DIV', tplPayDet.div_number,
                           'DOC_RECORD', tplPayDet.rco_title,
                           '0'
                          ),
                  -- Construction du compte en fonction de l'opérateur CONC / ADD / PREF
                  DECODE(brs_operation_type,
                        'CONC', ald_acc_name
                        || Nvl(bsv_value,
                              DECODE(bsv_source_field,
                                   'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                   'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                   'HEB_PF_NUMBER', tplPayDet.pf_number,
                                   'HEB_DIV_NUMBER', tplPayDet.div_number,
                                   'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                   'HEB_SHIFT', tplPayDet.heb_shift,
                                   'HEB_RCO_TITLE', tplPayDet.rco_title,
                                   ''
                                  )
                             ),
                        'PREF', Nvl(bsv_value,
                                DECODE(bsv_source_field,
                                   'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                   'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                   'HEB_PF_NUMBER', tplPayDet.pf_number,
                                   'HEB_DIV_NUMBER', tplPayDet.div_number,
                                   'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                   'HEB_SHIFT', tplPayDet.heb_shift,
                                   'HEB_RCO_TITLE', tplPayDet.rco_title,
                                   ''
                                   )
                                )||ald_acc_name,
                        Nvl(ald_acc_name, 0)
                        + hrm_breakdown.StrToNumber(Nvl(bsv_value,
                                               DECODE(bsv_source_field,
                                                    'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                                    'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                                    'HEB_PF_NUMBER', tplPayDet.pf_number,
                                                    'HEB_DIV_NUMBER', tplPayDet.div_number,
                                                    'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                                    'HEB_SHIFT', Nvl(tplPayDet.heb_shift, '0'),
                                                    'HEB_RCO_TITLE', tplPayDet.rco_title,
                                                    '0'
                                                    )
                                              )
                                           )
                       )
                  ),
             -- La prise en compte de l'inversion débit / crédit est fait plus tard
             case when (ald_rate < 0) then 'C' else 'D' end,
             -- Tronquage de la valeur à 2 décimales
             Trunc(tplPayDet.his_pay_sum_val,2),
             Nvl(Trunc(tplPayDet.his_currency_value,2),0),
             Nvl(Trunc(tplPayDet.his_ref_value,2),0),
             currency,
             Sysdate,
             period,
             0,
             Nvl(tplPayDet.his_zl, 0)
          FROM hrm_break_structure s, hrm_allocation_detail ad, hrm_break_shift sh, hrm_break_shift_val shv, hrm_elements e
         WHERE tplPayDet.hrm_elements_id = s.bre_item_id
          -- Source NON numérique
          AND brs_format <> 'N'
          AND ad.hrm_allocation_id = s.hrm_allocation_id
          AND tplPayDet.hrm_elements_id = e.hrm_elements_id
          AND sh.hrm_break_shift_id = ad.hrm_break_shift_id
          AND sh.hrm_break_shift_id = shv.hrm_break_shift_id(+)
          -- Déplacement à prendre en compte
          AND ((DECODE(bsv_source_field,
                    'HEB_CDA_NUMBER', tplPayDet.cda_number,
                    'HEB_PJ_NUMBER', tplPayDet.pj_number,
                    'HEB_PF_NUMBER', tplPayDet.pf_number,
                    'HEB_DIV_NUMBER', tplPayDet.div_number,
                    'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                    'HEB_SHIFT', Nvl(tplPayDet.heb_shift, '0'),
                    'HEB_RCO_TITLE', tplPayDet.rco_title,
                    '0'
                   ) BETWEEN (bsv_source_val) AND (bsv_source_val_to)
               )
               OR bsv_source_field IS NULL
              );
    end loop;

    -- Mise à jour du flag dans l'historique
    if (status = 1) then
      UPDATE hrm_history
      SET hit_accounted = 1
      WHERE hrm_employee_id = empid  AND hit_pay_num = paynum;
    end if;
  end LaunchBreak;

  procedure RoundBreak(
    breakid IN hrm_break.hrm_break_id%TYPE,
    status IN INTEGER)
  is
    --Curseur utilisé pour les diff. d'arrondi
    cursor roundpay is--(empid number, pay_num integer)
      select
        b.hrm_history_detail_id,
        b.dic_account_type_id,
        b.sab_amount_type,
        Sum(sab_amount) - a.his_pay_sum_val delta,
        Sum(sab_foreign_amount) - a.his_currency_value delta_foreign,
        Sum(sab_ref_value) - a.his_ref_value delta_ref
      from
        hrm_history_detail a, hrm_salary_breakdown b
      where
        a.hrm_history_detail_id = b.hrm_history_detail_id and
        b.hrm_break_id = breakid and
        dic_account_type_id in ('CG', 'CPN')
      group by
        b.hrm_history_detail_id,
        b.dic_account_type_id,
        b.sab_amount_type,
        a.his_pay_sum_val,
        a.his_currency_value,
        a.his_ref_value
      having (Sum(sab_amount) <> a.his_pay_sum_val or
              Sum(sab_foreign_amount) <> a.his_currency_value or
              Sum(sab_ref_value) <> a.his_ref_value);

  begin
    -- Ouverture du curseur de correction des arrondis pour les éléments en erreur
    for tplRoundPay in roundpay loop --(aPayroll.empid,aPayroll.paynum)
      UPDATE hrm_salary_breakdown sb
        SET sb.sab_amount = Nvl(sb.sab_amount, 0) - Nvl(tplRoundPay.delta, 0),
            sb.sab_foreign_amount = Nvl(sb.sab_foreign_amount, 0) - Nvl(tplRoundPay.delta_foreign, 0),
            sb.sab_ref_value = Nvl(sb.sab_ref_value, 0) - Nvl(tplRoundPay.delta_ref, 0)
       WHERE sb.hrm_history_detail_id = tplRoundPay.hrm_history_detail_id
        AND (sb.dic_account_type_id = tplRoundPay.dic_account_type_id or
             sb.dic_account_type_id in ('DIV', 'DOC_RECORD') AND tplRoundPay.dic_account_type_id = 'CG' or
             sb.dic_account_type_id in ('CDA', 'PF', 'PJ') AND tplRoundPay.dic_account_type_id = 'CPN' )
        AND sb.sab_amount_type = tplRoundPay.sab_amount_type
        AND sb.sab_source = (SELECT Min(sab_source)
                             FROM hrm_salary_breakdown m
                             WHERE m.hrm_history_detail_id = tplRoundPay.hrm_history_detail_id AND
                               m.dic_account_type_id = sb.dic_account_type_id AND
                               m.sab_amount_type = tplRoundPay.sab_amount_type);
    end loop;

    -- Mise à jour des inversions et permutations
    -- Fait après l'arrondi pour corriger le cas de la ventilation avec un groupe de répartition
    -- lorsqu'un des genres salaires a un montant négatif
    update hrm_salary_breakdown b
    set (sab_amount_type, sab_amount, sab_foreign_amount, sab_ref_value) =
      (SELECT
        -- Si la permutation est coché, et qu'après inversion on se retrouve en négatif,
        -- il faut permuter D et C
        DECODE(Nvl(e.ele_swap_dc, 0),
               1, DECODE(DECODE(Nvl(e.ele_is_break_inverse, 0), 1, -1, 1), Sign(sab_amount),
                         sab_amount_type, DECODE(sab_amount_type, 'D', 'C', 'D')),
               sab_amount_type),
        -- Changer le signe des montants, en fonction de la permutation et de l'inversion
        case
          when (Nvl(e.ele_swap_dc, 0) = 0) then
            DECODE(Nvl(e.ele_is_break_inverse, 0), 1, sab_amount * -1, sab_amount)
          else
            Abs(sab_amount)
        end,
        case
          when (NVL(e.ele_swap_dc, 0) = 0) then
            DECODE(Nvl(e.ele_is_break_inverse, 0), 1, sab_foreign_amount * -1, sab_foreign_amount)
          else
            Abs(sab_foreign_amount)
        end,
        case
          when (Nvl(e.ele_swap_dc, 0) = 0) then
            DECODE(Nvl(e.ele_is_break_inverse, 0), 1, sab_ref_value * -1, sab_ref_value)
          else
            Abs(sab_ref_value)
        end
      FROM hrm_elements e
      WHERE e.hrm_elements_id = b.hrm_elements_id)
    WHERE hrm_break_id = breakid AND
       EXISTS (SELECT 1 FROM hrm_elements e
               WHERE (ele_is_break_inverse = 1 OR ele_swap_dc = 1) AND
                 e.hrm_elements_id = b.hrm_elements_id);

    -- Mise à jour du flag de comptabilisation dans l'historique détaillé
    -- DEVHRM-10976
    -- Cette mise à jour n'a plus lieu d'être et provoque un fullscan sur les bases encryptées
    --if (status = 1) then
    --  update hrm_history_detail
    --  set his_accounted = 1
    --  where hrm_history_detail_id in (select hrm_history_detail_id
    --                                  from hrm_salary_breakdown
    --                                  where hrm_break_id = breakid);
    --end if;

    -- Mise à jour des ID de comptes
    update hrm_salary_breakdown a
    set sab_account_id = (select distinct acs_account_id
                          from acs_account b, acs_sub_set s
                          where b.acc_number = a.sab_account_name and
                            b.acs_sub_set_id = s.acs_sub_set_id and
                            c_sub_set = case dic_account_type_id
                                when 'CG' then 'ACC'
                                when 'DIV' then 'DTO'
                                when 'CPN' then 'CPN'
                                when 'CDA' then 'CDA'
                                when 'PF' then 'COS'
                                when 'PJ' then 'PRO'
                                end)
    where hrm_break_id = breakid AND
      dic_account_type_id in ('CG', 'DIV', 'CPN', 'CDA', 'PF', 'PJ');

    -- Mise à jour des ID des dossiers
    UPDATE hrm_salary_breakdown a
    SET sab_account_id = (SELECT doc_record_id FROM doc_record
                          WHERE rco_title = sab_account_name)
    WHERE hrm_break_id = breakid AND dic_account_type_id = 'DOC_RECORD';
  end RoundBreak;

  procedure ControlBreak(
    breakid IN hrm_break.hrm_break_id%TYPE,
    bAllErrors IN INTEGER)
  is
  begin
    delete from hrm_errors_log
    where elo_type in (2, 3);

    INSERT INTO hrm_errors_log
    (hrm_employee_id, hrm_elements_id, elo_message, elo_date, elo_type)
    (SELECT hrm_employee_id, 0,
           pcs.pc_public.TranslateWord('Différence débit/crédit') ||' : '||
              to_Char(Sum(v_hbc_debit_amount - v_hbc_credit_amount)),
           Sysdate,
           3
    FROM v_hrm_break_cgdiv2
    WHERE hrm_break_id = breakid
    GROUP BY hrm_employee_id
    HAVING Sum(v_hbc_debit_amount - v_hbc_credit_amount) <> 0
    UNION ALL
    SELECT hrm_employee_id, e.hrm_elements_id,
           pcs.pc_public.TranslateWord('Elément non arrondi'),
           Sysdate,
           3
    FROM hrm_salary_breakdown b, hrm_elements e
    WHERE e.hrm_elements_id = b.hrm_elements_id AND b.hrm_break_id = breakid AND
          Trunc(sab_amount, 2) <> sab_amount
    UNION ALL
    SELECT 0, bre_item_id,
           pcs.pc_public.TranslateWord('Groupe erroné'),
           Sysdate,
           3
    FROM hrm_break_structure s, hrm_elements_family f
    WHERE hrm_break_group_id IS NOT NULL AND bre_item_id = hrm_elements_id AND
      NOT EXISTS (SELECT 1 FROM hrm_break_group_root g
                  WHERE f.hrm_break_group_id = g.hrm_break_group_id)
    );

    --Contrôle des comptes si configuration à 1
    if (pcs.pc_config.GetConfig('HRM_BREAK_CONTROL_ACCOUNT') = 1) then
      INSERT INTO hrm_errors_log
      (hrm_employee_id, hrm_elements_id, elo_message, elo_date, elo_type)
      (SELECT hrm_employee_id, hrm_elements_id,
              case when (dic_account_type_id = 'DOC_RECORD') then
                Replace(pcs.pc_public.TranslateWord('Le dossier ''%s'' est inexistant'),
                      '%s', sab_account_name)
              else
                Replace(pcs.pc_public.TranslateWord('Le compte ''%s'' est inexistant'),
                      '%s', dic_account_type_id ||' '|| sab_account_name)
              end,
              Sysdate,
              3
      FROM hrm_salary_breakdown
      WHERE sab_account_id IS NULL AND hrm_break_id = breakid AND
        dic_account_type_id in ('CG','DIV','CDA','PF','PJ','CPN','DOC_RECORD')
      );
    end if;
  end ControlBreak;

  procedure BreakInitBudget(
    BudgetId IN hrm_budget_version.hrm_budget_version_id%TYPE)
  is
  begin
    delete hrm_budget_break
    where hrm_budget_version_id = BudgetId;
  end BreakInitBudget;

  procedure LaunchBreakBudget(
    empId IN hrm_person.hrm_person_id%TYPE,
    headerId IN hrm_budget_header.hrm_budget_header_id%TYPE,
    budgetId IN hrm_budget_version.hrm_budget_version_id%TYPE)
  is
    -- Curseur du détail de l'historique pour le décompte donné en paramètre ( empid / paynum )
    --Contient toutes les données nécessaires à l'imputation
    -- Pas de saisie de répartition => la ventilation se fait selon les données de comptabilisation
    cursor crPaydet is
      -- Comptabilisation selon définition de HRM_EMPLOYEE_BREAK
      SELECT hrm_employee_break_id eeb_sequence,
           NULL eeb_d_cgbase,
           NULL eeb_c_cgbase,
           hrm_budget_detail_id,
           d.hrm_elements_id,
           heb_div_number div_number,
           NULL eeb_cpnbase,
           heb_cda_number cda_number,
           heb_pf_number pf_number,
           heb_pj_number pj_number,
           heb_ratio / val eeb_per_rate,
           heb_department_id,
           heb_shift,
           rco_title,
           hbu_pay_sum_val * heb_ratio / val hbu_pay_sum_val
       FROM v_hrm_empl_break v,
          (SELECT hrm_employee_id,
                  Sum(heb_ratio) val
           FROM v_hrm_empl_break
           WHERE hrm_employee_id = empid
           GROUP BY hrm_employee_id) vt,
          hrm_budget_detail d
      WHERE v.hrm_employee_id = empId AND
        d.hrm_budget_header_id = headerId
      UNION ALL
       -- Eléments sans données dans HRM_EMPLOYEE_BREAK
      SELECT hrm_person_id,
           NULL,
           NULL,
           hrm_budget_detail_id,
           d.hrm_elements_id,
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           1,
           NULL,
           NULL,
           NULL,
           1
        FROM hrm_person v, hrm_budget_detail d
       WHERE v.hrm_person_id = empId AND
         d.hrm_budget_header_id = headerId AND
         NOT EXISTS (SELECT 1 FROM hrm_employee_break
                     WHERE hrm_employee_id = empid);
  begin
      -- Ouverture du curseur du détail
    for tplPayDet IN crPaydet loop
      -- Insertion dans la table de comptabilisation
      INSERT INTO hrm_budget_break
      (hrm_budget_break_id, hrm_budget_version_id, hrm_budget_detail_id, hrm_elements_id, hbu_source,
       hbu_cg_account, hbu_div_account, hbu_rec_account,
       hbu_cpn_account, hbu_cda_account, hbu_pf_account, hbu_pj_account,
       hbu_amount_type, hbu_amount)
      SELECT INIT_ID_SEQ.NextVal, s.*
      FROM (
        SELECT
          budgetId, hrm_budget_detail_id, hrm_elements_id, hbu_source,
          Max(case when (DIC_ACCOUNT_TYPE_ID = 'CG') then ACCOUNT_NAME end) hbu_cg_account,
          Max(case when (DIC_ACCOUNT_TYPE_ID = 'DIV') then ACCOUNT_NAME end) hbu_div_account,
          Max(case when (DIC_ACCOUNT_TYPE_ID = 'DOC_RECORD') then ACCOUNT_NAME end) hbu_rec_account,
          Max(case when (DIC_ACCOUNT_TYPE_ID = 'CPN') then ACCOUNT_NAME end) hbu_cpn_account,
          Max(case when (DIC_ACCOUNT_TYPE_ID = 'CDA') then ACCOUNT_NAME end) hbu_cda_account,
          Max(case when (DIC_ACCOUNT_TYPE_ID = 'PF') then ACCOUNT_NAME end) hbu_pf_account,
          Max(case when (DIC_ACCOUNT_TYPE_ID = 'PJ') then ACCOUNT_NAME end) hbu_pj_account,
          amount_type,
          Sum(case when (DIC_ACCOUNT_TYPE_ID = 'CG') then AMOUNT else 0 end) hbu_ammount
        FROM
          (SELECT tplPayDet.hrm_budget_detail_id hrm_budget_detail_id,
               tplPayDet.hrm_elements_id hrm_elements_id,
               empid,
               tplPayDet.eeb_sequence hbu_source,
               dic_account_type_id,
               -- Si le déplacement le spécifie, remplacement des valeurs de comptabilisation
               -- par celles du détail
               DECODE(brs_replacement,
                    'R', DECODE(dic_account_type_id,
                             'CPN', tplPayDet.eeb_cpnbase,
                             'CG', DECODE(DECODE(Nvl(e.ele_swap_dc, 0),
                                            1, DECODE(Sign(DECODE(Nvl(e.ele_is_break_inverse, 0),
                                                            1, tplPayDet.hbu_pay_sum_val * -1,
                                                            tplPayDet.hbu_pay_sum_val
                                                            )
                                                      ),
                                                   -1, ald_rate * -1,
                                                   ald_rate
                                                  ),
                                            ald_rate
                                           ),
                                      1, tplPayDet.eeb_d_cgbase,
                                      tplPayDet.eeb_c_cgbase
                                      ),
                             'CDA', tplPayDet.cda_number,
                             'PJ', tplPayDet.pj_number,
                             'PF', tplPayDet.pf_number,
                             'DIV', tplPayDet.div_number,
                             'DOC_RECORD', tplPayDet.rco_title,
                             '0'
                            ),
                    -- Construction du compte en fonction de l'opérateur CONC / ADD / PREF
                    DECODE(brs_operation_type,
                          'CONC', ald_acc_name
                          || Nvl(bsv_value,
                                DECODE(bsv_source_field,
                                     'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                     'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                     'HEB_PF_NUMBER', tplPayDet.pf_number,
                                     'HEB_DIV_NUMBER', tplPayDet.div_number,
                                     'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                     'HEB_SHIFT', tplPayDet.heb_shift,
                                     'HEB_RCO_TITLE', tplPayDet.rco_title,
                                     ''
                                    )
                               ),
                          'PREF', Nvl(bsv_value,
                                  DECODE(bsv_source_field,
                                     'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                     'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                     'HEB_PF_NUMBER', tplPayDet.pf_number,
                                     'HEB_DIV_NUMBER', tplPayDet.div_number,
                                     'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                     'HEB_SHIFT', tplPayDet.heb_shift,
                                     'HEB_RCO_TITLE', tplPayDet.rco_title,
                                     ''
                                     )
                                  )||ald_acc_name,
                          Nvl(ald_acc_name, 0)
                          + hrm_breakdown.StrToNumber(Nvl(bsv_value,
                                                 DECODE(bsv_source_field,
                                                      'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                                      'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                                      'HEB_PF_NUMBER', tplPayDet.pf_number,
                                                      'HEB_DIV_NUMBER', tplPayDet.div_number,
                                                      'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                                      'HEB_SHIFT', Nvl(tplPayDet.heb_shift, '0'),
                                                      'HEB_RCO_TITLE', tplPayDet.rco_title,
                                                      '0'
                                                      )
                                                )
                                             )
                         )
                    ) Account_name,
               -- La prise en compte de l'inversion débit / crédit est faite plus tard
               case when (ald_rate < 0) then 'C' else 'D' end Amount_Type,
               -- Tronquage de la valeur à 2 décimales
               Trunc(tplPayDet.hbu_pay_sum_val, 2) Amount
            FROM hrm_break_structure s, hrm_allocation_detail ad, hrm_break_shift sh, hrm_break_shift_val shv, hrm_elements e
           WHERE tplPayDet.hrm_elements_id = s.bre_item_id and
            -- Source numérique
            sh.brs_format = 'N' and
            sh.hrm_break_shift_id = shv.hrm_break_shift_id(+) and
            ad.hrm_allocation_id = s.hrm_allocation_id and
            tplPayDet.hrm_elements_id = e.hrm_elements_id and
            sh.hrm_break_shift_id = ad.hrm_break_shift_id
            -- Déplacement à prendre en compte
            AND ((hrm_breakdown.StrToNumber(DECODE(bsv_source_field,
                                        'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                        'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                        'HEB_PF_NUMBER', tplPayDet.pf_number,
                                        'HEB_DIV_NUMBER', tplPayDet.div_number,
                                        'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                        'HEB_SHIFT', Nvl(tplPayDet.heb_shift, 0),
                                        'HEB_RCO_TITLE', tplPayDet.rco_title,
                                        '0'
                                       )
                                  ) BETWEEN hrm_breakdown.StrToNumber(bsv_source_val)
                                      AND hrm_breakdown.StrToNumber(bsv_source_val_to)
                 )
                 OR bsv_source_field IS NULL
                )
          UNION ALL
          SELECT tplPayDet.hrm_budget_detail_id,
               tplPayDet.hrm_elements_id,
               empid,
               tplPayDet.eeb_sequence,
               dic_account_type_id,
               -- Si le déplacement le spécifie, remplacement des valeurs de comptabilisation
               -- par celles du détail
               DECODE(brs_replacement,
                    'R', DECODE(dic_account_type_id,
                             'CPN', tplPayDet.eeb_cpnbase,
                             'CG', DECODE(DECODE(Nvl(e.ele_swap_dc, 0),
                                            1, DECODE(Sign(DECODE(Nvl(e.ele_is_break_inverse, 0),
                                                            1, tplPayDet.hbu_pay_sum_val * -1,
                                                            tplPayDet.hbu_pay_sum_val
                                                            )
                                                      ),
                                                   -1, ald_rate * -1,
                                                   ald_rate
                                                  ),
                                            ald_rate
                                           ),
                                      1, tplPayDet.eeb_d_cgbase,
                                      tplPayDet.eeb_c_cgbase
                                      ),
                             'CDA', tplPayDet.cda_number,
                             'PJ', tplPayDet.pj_number,
                             'PF', tplPayDet.pf_number,
                             'DIV', tplPayDet.div_number,
                             'DOC_RECORD', tplPayDet.rco_title,
                             0
                            ),
                    -- Construction du compte en fonction de l'opérateur CONC / ADD / PREF
                    DECODE(brs_operation_type,
                          'CONC', ald_acc_name
                          || Nvl(bsv_value,
                                DECODE(bsv_source_field,
                                     'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                     'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                     'HEB_PF_NUMBER', tplPayDet.pf_number,
                                     'HEB_DIV_NUMBER', tplPayDet.div_number,
                                     'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                     'HEB_SHIFT', tplPayDet.heb_shift,
                                     'HEB_RCO_TITLE', tplPayDet.rco_title,
                                     ''
                                    )
                               ),
                          'PREF', Nvl(bsv_value,
                                  DECODE(bsv_source_field,
                                     'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                     'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                     'HEB_PF_NUMBER', tplPayDet.pf_number,
                                     'HEB_DIV_NUMBER', tplPayDet.div_number,
                                     'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                     'HEB_SHIFT', tplPayDet.heb_shift,
                                     'HEB_RCO_TITLE', tplPayDet.rco_title,
                                     ''
                                     )
                                  )||ald_acc_name,
                          Nvl(ald_acc_name, 0)
                          + hrm_breakdown.StrToNumber(Nvl(bsv_value,
                                                 DECODE(bsv_source_field,
                                                      'HEB_CDA_NUMBER', tplPayDet.cda_number,
                                                      'HEB_PJ_NUMBER', tplPayDet.pj_number,
                                                      'HEB_PF_NUMBER', tplPayDet.pf_number,
                                                      'HEB_DIV_NUMBER', tplPayDet.div_number,
                                                      'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                                                      'HEB_SHIFT', Nvl(tplPayDet.heb_shift, 0),
                                                      'HEB_RCO_TITLE', tplPayDet.rco_title,
                                                      '0'
                                                      )
                                                )
                                             )
                         )
                    ),
               -- La prise en compte de l'inversion débit / crédit est fait plus tard
               case when (ald_rate < 0) then 'C' else 'D' end,
               -- Tronquage de la valeur à 2 décimales
               Trunc(tplPayDet.hbu_pay_sum_val,2)
            FROM hrm_break_structure s, hrm_allocation_detail ad, hrm_break_shift sh, hrm_break_shift_val shv, hrm_elements e
           WHERE tplPayDet.hrm_elements_id = s.bre_item_id and
            -- Source NON numérique
            brs_format <> 'N' and
            ad.hrm_allocation_id = s.hrm_allocation_id and
            tplPayDet.hrm_elements_id = e.hrm_elements_id and
            sh.hrm_break_shift_id = ad.hrm_break_shift_id and
            sh.hrm_break_shift_id = shv.hrm_break_shift_id(+)
            -- Déplacement à prendre en compte
            AND ((DECODE(bsv_source_field,
                      'HEB_CDA_NUMBER', tplPayDet.cda_number,
                      'HEB_PJ_NUMBER', tplPayDet.pj_number,
                      'HEB_PF_NUMBER', tplPayDet.pf_number,
                      'HEB_DIV_NUMBER', tplPayDet.div_number,
                      'HEB_DEPARTMENT_ID', tplPayDet.heb_department_id,
                      'HEB_SHIFT', Nvl(tplPayDet.heb_shift, 0),
                      'HEB_RCO_TITLE', tplPayDet.rco_title,
                      0
                     ) BETWEEN (bsv_source_val) AND (bsv_source_val_to)
                 )
                 OR bsv_source_field IS NULL
                )
          )
        GROUP BY
          budgetId, hrm_budget_detail_id, hrm_elements_id, hbu_source, amount_type
        ) s;
    end loop;
  end LaunchBreakBudget;


  procedure RoundBreakBudget(
    budgetid IN hrm_budget_version.hrm_budget_version_id%TYPE)
  is
    -- Curseur utilisé pour les diff. d'arrondi
    cursor crRoundBreak is
      SELECT b.hrm_budget_detail_id,
             b.hbu_amount_type,
             Nvl(Sum(hbu_amount) - a.hbu_pay_sum_val, 0) AS DELTA
      FROM hrm_budget_detail a, hrm_budget_break b
      WHERE a.hrm_budget_detail_id = b.hrm_budget_detail_id AND
        b.hrm_budget_version_id = budgetid
      GROUP BY b.hrm_budget_detail_id,
               b.hbu_amount_type,
               a.hbu_pay_sum_val
      HAVING Sum(hbu_amount) <> a.hbu_pay_sum_val;

  begin
    -- Ouverture du curseur de correction des arrondis pour les éléments en erreur
    for tplRoundBreak IN crRoundBreak LOOP
      UPDATE hrm_budget_break
      SET hbu_amount = Nvl(hbu_amount, 0) - tplRoundBreak.delta
      WHERE hrm_budget_version_id = budgetId AND
        hrm_budget_detail_id = tplRoundBreak.hrm_budget_detail_id AND
        hbu_amount_type = tplRoundBreak.hbu_amount_type AND
        hbu_source = (SELECT Min(hbu_source) FROM hrm_budget_break
                      WHERE hrm_budget_detail_id = tplRoundBreak.hrm_budget_detail_id AND
                        hbu_amount_type = tplRoundBreak.hbu_amount_type AND
                        hrm_budget_version_id = budgetid);
    end loop;

    -- Mise à jour des inversions et permutations
    -- Fait après l'arrondi pour corriger le cas de la ventilation avec un groupe de répartition
    -- lorsqu'un des genres salaires a un montant négatif
    UPDATE hrm_budget_break b
    SET (hbu_amount_type, hbu_amount) =
      (SELECT
        -- Si la permutation est coché, et qu'après inversion on se retrouve en négatif,
        -- il faut permuter D et C
        case
          when (Nvl(e.ele_swap_dc, 0) = 1) then
            case
              when DECODE(Nvl(e.ele_is_break_inverse, 0), 1, -1, 1) = Sign(hbu_amount) then
                hbu_amount_type
              else
                case when hbu_amount_type = 'D' then 'C' else 'D' end
            end
          else hbu_amount_type
        end,
        -- Changer le signe des montants, en fonction de la permutation et de l'inversion
        case
          when (Nvl(e.ele_swap_dc, 0) = 0) then
            case
              when Nvl(e.ele_is_break_inverse, 0) = 1 then hbu_amount * -1
              else hbu_amount
            end
          else
            Abs(hbu_amount)
        end
      FROM hrm_elements e
      WHERE e.hrm_elements_id = b.hrm_elements_id)
    WHERE hrm_budget_version_id = budgetid AND
       EXISTS (SELECT 1 FROM hrm_elements e
               WHERE (ele_is_break_inverse = 1 OR ele_swap_dc = 1) AND
                 e.hrm_elements_id = b.hrm_elements_id);
  end RoundBreakBudget;

  procedure ControlBreakBudget(
    budgetid IN hrm_budget_version.hrm_budget_version_id%TYPE,
    bAllErrors IN INTEGER)
  is
  begin
    delete from hrm_errors_log
    where elo_type IN (2, 3);

    INSERT INTO hrm_errors_log
    (hrm_employee_id, hrm_elements_id, elo_message, elo_date, elo_type)
    (SELECT hrm_employee_id, 0,
            pcs.pc_public.TranslateWord('Différence débit/crédit') ||' : '||
            To_Char(Sum(case when (HBU_AMOUNT_TYPE = 'D') then HBU_AMOUNT else 0 end) -
                    Sum(case when (HBU_AMOUNT_TYPE = 'C') then HBU_AMOUNT else 0 end)),
            Sysdate,
            3
    FROM hrm_budget_header bh, hrm_budget_detail bd, hrm_budget_break bb
    WHERE bh.hrm_budget_header_id(+) = bd.hrm_budget_header_id AND
      bd.hrm_budget_detail_id(+) = bb.hrm_budget_detail_id AND
      bb.hrm_budget_version_id = budgetId
    GROUP BY bh.hrm_employee_id
    HAVING (Sum(case when (HBU_AMOUNT_TYPE = 'D') then HBU_AMOUNT else 0 end) -
            Sum(case when (HBU_AMOUNT_TYPE = 'C') then HBU_AMOUNT else 0 end)) <> 0
    UNION ALL
    SELECT bh.hrm_employee_id, bb.hrm_elements_id,
           pcs.pc_public.TranslateWord('Elément non arrondi'),
           Sysdate,
           3
    FROM hrm_budget_header bh, hrm_budget_detail bd, hrm_budget_break bb
    WHERE bh.hrm_budget_header_id(+) = bd.hrm_budget_header_id AND
      bd.hrm_budget_detail_id(+) = bb.hrm_budget_detail_id AND
      bb.hrm_budget_version_id = budgetid AND
      Trunc(hbu_amount, 2) <> hbu_amount
    );

    -- Contrôle des employés manquants (selon paramètre, pour ne pas bloquer le transfert en compta)
    if (bAllErrors = 1) then
      INSERT INTO hrm_errors_log
      (hrm_employee_id, elo_message, elo_date, elo_type)
      (SELECT hrm_employee_id,
          pcs.pc_public.TranslateWord('L''employé est manquant dans la ventilation. Contrôlez les données de comptabilisation'),
          Sysdate,
          3
       FROM hrm_budget_header bh
       WHERE bh.hrm_budget_version_id = budgetId and
         NOT EXISTS (SELECT 1
                     FROM hrm_budget_header bh2, hrm_budget_detail bd,
                       hrm_budget_break bb
                     WHERE bh2.hrm_budget_header_id = bd.hrm_budget_header_id AND
                       bd.hrm_budget_detail_id = bb.hrm_budget_detail_id AND
                       bb.hrm_budget_version_id = budgetid AND
                       bh2.hrm_employee_id = bh.hrm_employee_id)
      );
    end if;

    --Contrôle des comptes si configuration à 1
    if (pcs.pc_config.GetConfig('HRM_BREAK_CONTROL_ACCOUNT') = 1) then
      INSERT INTO hrm_errors_log
      (hrm_employee_id, hrm_elements_id, elo_message, elo_date, elo_type)
      (SELECT
        bh.hrm_employee_id,
        v.hrm_elements_id,
        case when (account_type = 'DOC_RECORD') then
          Replace(pcs.pc_public.TranslateWord('Le dossier ''%s'' est inexistant'),
                  '%s', account_name)
        else
          Replace(pcs.pc_public.TranslateWord('Le compte ''%s'' est inexistant'),
                  '%s', account_type ||' '|| account_name)
        end,
        Sysdate,
        3
      FROM
        hrm_budget_header bh,
        hrm_budget_detail bd,
        (
        select hrm_budget_version_id, hrm_budget_detail_id, hrm_elements_id,
         hbu_cg_account account_name, 'CG' account_type from hrm_budget_break b
        where hbu_cg_account is not null and
         not exists (select 1 from acs_account a, acs_sub_set s
                 where a.acs_sub_set_id = s.acs_sub_set_id and s.c_sub_set = 'ACC' and
                     a.acc_number = b.hbu_cg_account)
        union all
        select hrm_budget_version_id, hrm_budget_detail_id, hrm_elements_id,
         hbu_div_account, 'DIV' from hrm_budget_break b
        where hbu_div_account is not null and
         not exists (select 1 from acs_account a, acs_sub_set s
                 where a.acs_sub_set_id = s.acs_sub_set_id and s.c_sub_set = 'DTO' and
                     a.acc_number = b.hbu_div_account)
        union all
        select hrm_budget_version_id, hrm_budget_detail_id, hrm_elements_id,
         hbu_cpn_account, 'CPN' from hrm_budget_break b
        where hbu_cpn_account is not null and
         not exists (select 1 from acs_account a, acs_sub_set s
                 where a.acs_sub_set_id = s.acs_sub_set_id and s.c_sub_set = 'CPN' and
                     a.acc_number = b.hbu_cpn_account)
        union all
        select hrm_budget_version_id, hrm_budget_detail_id, hrm_elements_id,
         hbu_cda_account, 'CDA' from hrm_budget_break b
        where hbu_cda_account is not null and
         not exists (select 1 from acs_account a, acs_sub_set s
                 where a.acs_sub_set_id = s.acs_sub_set_id and s.c_sub_set = 'CDA' and
                     a.acc_number = b.hbu_cda_account)
        union all
        select hrm_budget_version_id, hrm_budget_detail_id, hrm_elements_id,
         hbu_pf_account, 'PF' from hrm_budget_break b
        where hbu_pf_account is not null and
         not exists (select 1 from acs_account a, acs_sub_set s
                 where a.acs_sub_set_id = s.acs_sub_set_id and s.c_sub_set = 'COS' and
                     a.acc_number = b.hbu_pf_account)
        union all
        select hrm_budget_version_id, hrm_budget_detail_id, hrm_elements_id,
         hbu_pj_account, 'PJ' from hrm_budget_break b
        where hbu_pj_account is not null and
         not exists (select 1 from acs_account a, acs_sub_set s
                 where a.acs_sub_set_id = s.acs_sub_set_id and s.c_sub_set = 'PRO' and
                     a.acc_number = b.hbu_pj_account)
        union all
        select hrm_budget_version_id, hrm_budget_detail_id, hrm_elements_id,
         hbu_rec_account, 'DOC_RECORD' from hrm_budget_break b
        where hbu_rec_account is not null and
         not exists (select 1 from doc_record r
                 where r.rco_title = b.hbu_rec_account)
        ) v
      WHERE v.HRM_BUDGET_VERSION_ID = BudgetId and
          v.hrm_budget_detail_id = bd.hrm_budget_detail_id(+) and
          bd.hrm_budget_header_id = bh.hrm_budget_header_id(+)
      );
    end if;
  end ControlBreakBudget;

END HRM_BREAKDOWN;
