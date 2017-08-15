--------------------------------------------------------
--  DDL for Procedure RPT_FAM_AMO_APPLICATION_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_AMO_APPLICATION_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2
)
IS
/**
*Description - used for the report FAM_FIXED_ASSETS_FORM

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZH 6 Jun 2008
* @LASTUPDATE 24 FEB 2009
* @VERSION
* @PUBLIC
* @PARAM PARAMETER_0: FAM_FIXED_ASSETS_ID
* @PARAM PROCUSER_LANID: User language
*/
BEGIN
   OPEN arefcursor FOR
      SELECT '1' group_string, app.fam_fixed_assets_id,
             app.fam_amortization_method_id, app.fam_managed_value_id,
             app.app_lin_amortization, app.app_dec_amortization,
             app.app_interest_rate, app.app_interest_rate_2,
             app.app_month_duration, app.app_amortization_begin,
             app.app_amortization_end, app.fam_amo_application_id,
             app.dic_fam_coefficient_id dic_fam_coefficient_2_id,
             val.val_key, met.amo_descr, cat.cat_descr, def.fam_default_id,
             def.def_lin_amortization, def.def_dec_amortization,
             def.def_interest_rate, def.def_interest_rate_2,
             def.dic_fam_coefficient_id dic_fam_coefficient_1_id,
             fpl.pye_no_exercise, fpl.start_amo_amount, fpl.amo_amount,
             fpl.sum_amo_amount, fpl.end_amo_amount,
               fpl.start_amo_amount
             - NVL ((SELECT   SUM (fpe1.fpe_adapted_amo_lc)
                         FROM fam_plan_header fph1, fam_plan_exercise fpe1
                        WHERE fph1.fam_plan_header_id =
                                                       fpe1.fam_plan_header_id
                          AND fph1.c_amo_plan_status = '1'
                          AND fph1.fam_fixed_assets_id =
                                                       TO_NUMBER (parameter_0)
                          AND fpe1.pye_no_exercise < fpl.pye_no_exercise
                          AND fph1.fam_managed_value_id =
                                                      val.fam_managed_value_id
                     GROUP BY fpe1.fpe_elem_1_amount),
                    0
                   ) year_start_amount,
             (SELECT     fpe1.fpe_elem_1_amount
                       - SUM (fpe1.fpe_adapted_amo_lc)
                  FROM fam_plan_header fph1, fam_plan_exercise fpe1
                 WHERE fph1.fam_plan_header_id = fpe1.fam_plan_header_id
                   AND fph1.c_amo_plan_status = '1'
                   AND fph1.fam_fixed_assets_id = TO_NUMBER (parameter_0)
                   AND fpe1.pye_no_exercise <= fpl.pye_no_exercise
                   AND fph1.fam_managed_value_id = val.fam_managed_value_id
              GROUP BY fpe1.fpe_elem_1_amount) year_end_amount
        FROM fam_fixed_assets ass,
             fam_amo_application app,
             fam_default def,
             fam_fixed_assets_categ cat,
             fam_amortization_method met,
             fam_managed_value val,
             (SELECT fph.fam_fixed_assets_id, fph.fam_managed_value_id,
                     fpe.pye_no_exercise,
                     fpe.fpe_elem_1_amount start_amo_amount,
                     fpe.fpe_adapted_amo_lc amo_amount,
                     fpe.fpe_amortization_lc sum_amo_amount,
                     fpe.fpe_amortization_lc end_amo_amount
                FROM fam_plan_header fph, fam_plan_exercise fpe
               WHERE fph.fam_plan_header_id = fpe.fam_plan_header_id
                 AND fph.c_amo_plan_status = '1'
                 AND fph.fam_fixed_assets_id = TO_NUMBER (parameter_0)) fpl
       WHERE app.fam_fixed_assets_id = ass.fam_fixed_assets_id
         AND app.fam_managed_value_id = val.fam_managed_value_id
         AND app.fam_amortization_method_id = met.fam_amortization_method_id
         AND ass.fam_fixed_assets_categ_id = cat.fam_fixed_assets_categ_id
         AND def.fam_fixed_assets_categ_id = ass.fam_fixed_assets_categ_id
         AND def.fam_amortization_method_id = app.fam_amortization_method_id
         AND val.fam_managed_value_id = fpl.fam_managed_value_id(+)
         AND app.fam_fixed_assets_id = TO_NUMBER (parameter_0)
      UNION ALL

      --to get the start amount for the depreciation plan, which will be used in the chart --
      (SELECT   '1' group_string, app.fam_fixed_assets_id,
                app.fam_amortization_method_id, app.fam_managed_value_id,
                app.app_lin_amortization, app.app_dec_amortization,
                app.app_interest_rate, app.app_interest_rate_2,
                app.app_month_duration, app.app_amortization_begin,
                app.app_amortization_end, app.fam_amo_application_id,
                app.dic_fam_coefficient_id dic_fam_coefficient_2_id,
                val.val_key, met.amo_descr, cat.cat_descr, def.fam_default_id,
                def.def_lin_amortization, def.def_dec_amortization,
                def.def_interest_rate, def.def_interest_rate_2,
                def.dic_fam_coefficient_id dic_fam_coefficient_1_id,
                0 pye_no_exercise, NULL start_amo_amount, NULL amo_amount,
                NULL sum_amo_amount, NULL end_amo_amount,
                NULL year_start_amount, fpl.start_amo_amount year_end_amount
           FROM fam_fixed_assets ass,
                fam_amo_application app,
                fam_default def,
                fam_fixed_assets_categ cat,
                fam_amortization_method met,
                fam_managed_value val,
                (SELECT fph.fam_fixed_assets_id, fph.fam_managed_value_id,
                        fpe.pye_no_exercise,
                        fpe.fpe_elem_1_amount start_amo_amount,
                        fpe.fpe_adapted_amo_lc amo_amount,
                        fpe.fpe_amortization_lc sum_amo_amount,
                        fpe.fpe_amortization_lc end_amo_amount
                   FROM fam_plan_header fph, fam_plan_exercise fpe
                  WHERE fph.fam_plan_header_id = fpe.fam_plan_header_id
                    AND fph.c_amo_plan_status = '1'
                    AND fph.fam_fixed_assets_id = TO_NUMBER (parameter_0)) fpl
          WHERE app.fam_fixed_assets_id = ass.fam_fixed_assets_id
            AND app.fam_managed_value_id = val.fam_managed_value_id
            AND app.fam_amortization_method_id =
                                                met.fam_amortization_method_id
            AND ass.fam_fixed_assets_categ_id = cat.fam_fixed_assets_categ_id
            AND def.fam_fixed_assets_categ_id = ass.fam_fixed_assets_categ_id
            AND def.fam_amortization_method_id =
                                                app.fam_amortization_method_id
            AND val.fam_managed_value_id = fpl.fam_managed_value_id(+)
            AND app.fam_fixed_assets_id = TO_NUMBER (parameter_0)
       GROUP BY app.fam_fixed_assets_id,
                app.fam_amortization_method_id,
                app.fam_managed_value_id,
                app.app_lin_amortization,
                app.app_dec_amortization,
                app.app_interest_rate,
                app.app_interest_rate_2,
                app.app_month_duration,
                app.app_amortization_begin,
                app.app_amortization_end,
                app.fam_amo_application_id,
                app.dic_fam_coefficient_id,
                val.val_key,
                met.amo_descr,
                cat.cat_descr,
                def.fam_default_id,
                def.def_lin_amortization,
                def.def_dec_amortization,
                def.def_interest_rate,
                def.def_interest_rate_2,
                def.dic_fam_coefficient_id,
                fpl.start_amo_amount);
END rpt_fam_amo_application_sub;
