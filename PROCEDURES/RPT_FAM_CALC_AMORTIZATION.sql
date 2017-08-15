--------------------------------------------------------
--  DDL for Procedure RPT_FAM_CALC_AMORTIZATION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_CALC_AMORTIZATION" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*Description - used for report FAM_CALC_AMORTIZATION

*@created JLIU 1 JAN2009
*@lastUpdate 25 FEB 2008
*@public
*@param PARAMETER_0:  ACS_PERIOD_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT yea.fye_no_exercice, per.per_no_period, amo.acs_period_id,
             cal.cal_transaction_date, cal.cal_value_date,
             cal.cal_amortization_base_lc, cal.cal_amortization_rate,
             cal.cal_amortization_lc, cal.cal_days, cal.fam_imputation_id,
             ast.fam_fixed_assets_id, ast.fix_number, ast.fix_short_descr,
             cag.fam_fixed_assets_categ_id, cag.cat_descr,
             val.fam_managed_value_id, val.val_key, val.val_descr
        FROM acs_financial_year yea,
             acs_period per,
             fam_amortization_period amo,
             fam_calc_amortization cal,
             fam_fixed_assets ast,
             fam_fixed_assets_categ cag,
             fam_managed_value val,
             fam_per_calc_by_value byv
       WHERE amo.acs_period_id = byv.acs_period_id
         AND byv.fam_per_calc_by_value_id = cal.fam_per_calc_by_value_id
         AND cal.fam_fixed_assets_id = ast.fam_fixed_assets_id
         AND ast.fam_fixed_assets_categ_id = cag.fam_fixed_assets_categ_id
         AND byv.acs_period_id = per.acs_period_id
         AND per.acs_financial_year_id = yea.acs_financial_year_id
         AND byv.fam_managed_value_id = val.fam_managed_value_id
         AND amo.acs_period_id = TO_NUMBER (parameter_0)
         AND cal.cal_amortization_base_lc IS NOT NULL;
END rpt_fam_calc_amortization;
