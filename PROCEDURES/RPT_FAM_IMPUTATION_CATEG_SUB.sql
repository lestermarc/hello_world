--------------------------------------------------------
--  DDL for Procedure RPT_FAM_IMPUTATION_CATEG_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_IMPUTATION_CATEG_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2
)
IS
/**
*Description - used for the report FAM_FIXED_ASSETS_FORM

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR JLIU 29 DEC 2008
* @LASTUPDATE 24 FEB 2009
* @VERSION
* @PUBLIC
* @PARAM PARAMETER_0: FAM_FIXED_ASSETS_ID
* @PARAM PROCUSER_LANID: User language
*/
BEGIN
   OPEN arefcursor FOR
      SELECT '1' group_string, imp.fam_imputation_account_id,
             imp.fam_default_id, val.val_key, ass.fam_fixed_assets_id,
             imp.c_fam_imputation_typ, imp.acs_financial_account_id,
             acc.acc_number acc_number_fin, imp.acs_division_account_id,
             div.acc_number acc_number_div, imp.acs_cpn_account_id,
             cpn.acc_number acc_number_cpn, imp.acs_cda_account_id,
             cda.acc_number acc_number_cda, imp.acs_pf_account_id,
             pf.acc_number acc_number_pf, imp.acs_pj_account_id,
             pj.acc_number acc_number_pj
        FROM acs_account pj,
             acs_account pf,
             acs_account cda,
             acs_account cpn,
             acs_account div,
             acs_account acc,
             fam_fixed_assets ass,
             fam_imputation_account imp,
             fam_default def,
             fam_managed_value val
       WHERE imp.fam_default_id = def.fam_default_id
         AND def.fam_managed_value_id = val.fam_managed_value_id
         AND def.fam_fixed_assets_categ_id = ass.fam_fixed_assets_categ_id
         AND imp.acs_financial_account_id = acc.acs_account_id(+)
         AND imp.acs_division_account_id = div.acs_account_id(+)
         AND imp.acs_cpn_account_id = cpn.acs_account_id(+)
         AND imp.acs_cda_account_id = cda.acs_account_id(+)
         AND imp.acs_pf_account_id = pf.acs_account_id(+)
         AND imp.acs_pj_account_id = pj.acs_account_id(+)
         AND ass.fam_fixed_assets_id = TO_NUMBER (parameter_0);
END rpt_fam_imputation_categ_sub;
