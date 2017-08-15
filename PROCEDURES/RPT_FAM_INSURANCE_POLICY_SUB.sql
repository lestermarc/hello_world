--------------------------------------------------------
--  DDL for Procedure RPT_FAM_INSURANCE_POLICY_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_INSURANCE_POLICY_SUB" (
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
      SELECT '1' group_string,          --userd fro group header in subreport
                              per.pac_person_id, per.dic_person_politness_id,
             per.per_name, per.per_forename, per.per_short_name,
             per.per_activity, per.per_key1, per.per_key2, adr.add_principal,
             adr.dic_address_type_id, adr.add_address1, cty.cntid,
             cty.cntname, adr.pac_address_id, adr.add_zipcode, adr.add_city,
             adr.add_state, adr.add_format, adr.pc_lang_id,
             adr.c_partner_status, fis.fam_fixed_assets_id,
             fis.ins_declared_value, fis.ins_effective_value,
             fis.ins_new_value, fip.fam_insurance_policy_id, fip.pol_number,
             fip.pol_designation
        FROM pcs.pc_cntry cty,
             pac_address adr,
             pac_person per,
             fam_insurance fis,
             fam_insurance_policy fip
       WHERE adr.pac_person_id = per.pac_person_id
         AND cty.pc_cntry_id = adr.pc_cntry_id
         AND fis.fam_insurance_policy_id = fip.fam_insurance_policy_id
         AND fip.pac_person_id = per.pac_person_id
         AND fis.fam_fixed_assets_id = TO_NUMBER (parameter_0);
END rpt_fam_insurance_policy_sub;
