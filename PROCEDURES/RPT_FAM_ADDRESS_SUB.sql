--------------------------------------------------------
--  DDL for Procedure RPT_FAM_ADDRESS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_ADDRESS_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2,
   procuser_lanid   IN       VARCHAR2
)
IS
/**
*Description - used for the report FAM_FIXED_ASSETS_FORM

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR JLIU 29 DEC  2008
* @LASTUPDATE 24 FEB 2009
* @VERSION
* @PUBLIC
* @PARAM PARAMETER_0: FAM_FIXED_ASSETS_ID
* @PARAM PROCUSER_LANID: User language
*/

vpc_lang_id   NUMBER (12);

BEGIN

   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT '1' group_string,          --userd fro group header in subreport
                              per.pac_person_id, per.dic_person_politness_id,
             per.per_name, per.per_forename, per.per_short_name,
             per.per_activity, per.per_key1, per.per_key2, adr.add_principal,
             adr.dic_address_type_id, adr.add_address1, cty.cntid,
             cty.cntname, adr.pac_address_id, adr.add_zipcode, adr.add_city,
             adr.add_state, adr.add_format, adr.pc_lang_id,
             adr.c_partner_status, fad.fam_address_id,
             fad.fam_fixed_assets_id, fad.dic_link_typ_id,
             com_dic_functions.getdicodescr
                                      ('DIC_LINK_TYP',
                                       fad.dic_link_typ_id,
                                       vpc_lang_id
                                      ) dic_link_typ_desc
        FROM pcs.pc_cntry cty,
             pac_address adr,
             pac_person per,
             fam_address fad
       WHERE adr.pac_person_id = per.pac_person_id
         AND cty.pc_cntry_id = adr.pc_cntry_id
         AND fad.pac_person_id = per.pac_person_id(+)
         AND fad.fam_fixed_assets_id = TO_NUMBER (parameter_0);
END rpt_fam_address_sub;
