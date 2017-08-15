--------------------------------------------------------
--  DDL for Procedure RPT_ACJ_CATALOGUE_TYPE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACJ_CATALOGUE_TYPE_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2
)
IS

/**
*DESCRIPTION
Used for report the subreport of ACJ_CATALOGUE_TYPE
*author MZHU
*lastUpdate 18 Nov. 2009
*public
*@param PARAMETER_0:  ACJ_CATALOGUE_TYPE_ID
*/


BEGIN


OPEN arefcursor FOR

SELECT
imt.acj_catalogue_type_id, imt.acj_imputation_type_id,
          imt.pac_custom_partner_id,
          pac_functions.getnamesandcity
                                      (imt.pac_custom_partner_id)
                                                                 cus_per_name,
          imt.pac_supplier_partner_id,
          pac_functions.getnamesandcity
                                    (imt.pac_supplier_partner_id)
                                                                 sup_per_name,
          imt.imt_bvr_ref, imt.imt_primary, imt.imt_sequence,
          imt.imt_description, imt.acs_financial_account_id,
          acs_function.getaccountnumber
                                    (imt.acs_financial_account_id)
                                                                  fin_account,
          imt.acs_division_account_id,
          acs_function.getaccountnumber
                                     (imt.acs_division_account_id)
                                                                  div_account,
          imt.acs_tax_code_id,
          acs_function.getaccountnumber (imt.acs_tax_code_id) tax_code,
          imt.acs_cpn_account_id,
          acs_function.getaccountnumber (imt.acs_cpn_account_id) cpn_account,
          imt.acs_cda_account_id,
          acs_function.getaccountnumber (imt.acs_cda_account_id) cda_account,
          imt.acs_pf_account_id,
          acs_function.getaccountnumber (imt.acs_pf_account_id) pf_account,
          imt.acs_pj_account_id,
          acs_function.getaccountnumber (imt.acs_pj_account_id) pj_account,
          imt.imt_value_d, imt.imt_value_c
     FROM acj_imputation_type imt
     WHERE imt.acj_catalogue_type_id = TO_NUMBER(PARAMETER_0);

END RPT_ACJ_CATALOGUE_TYPE_SUB;
