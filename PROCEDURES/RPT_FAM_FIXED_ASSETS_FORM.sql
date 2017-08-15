--------------------------------------------------------
--  DDL for Procedure RPT_FAM_FIXED_ASSETS_FORM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_FIXED_ASSETS_FORM" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   parameter_5      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2,
   parameter_7      IN       VARCHAR2,
   parameter_8      IN       VARCHAR2,
   parameter_9      IN       VARCHAR2,
   parameter_10     IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/*
*Description - used for the report FAM_FIXED_ASSETS_FORM

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZH 6 Jun 2008
* @LASTUPDATE 6 JUN 2009
* @VERSION
* @PUBLIC
* @PARAM PARAMETER_0: Fixed assets number. Min value
* @PARAM PARAMETER_1: Fixed assets number. Max value
* @PARAM PARAMETER_2: Fixed assets status.
* @PARAM PARAMETER_4: Fixed assets category. Min value
* @PARAM PARAMETER_5: Fixed assets category. Max value
* @PARAM PARAMETER_6: Condition choose for date creation, modification or userid
* @PARAM PARAMETER_7: Fixed assets creation or modification date. Min value
* @PARAM PARAMETER_8: Fixed assets creation or modification date. Max value
* @PARAM PARAMETER_9: Fixed assets modification user id
* @PARAM PARAMETER_10: Fam_fixed_asset_id
* @PARAM PROCUSER_LANID: User language
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
   p_7           DATE;
   p_8           DATE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;


   IF parameter_7 = '0'
   THEN
      p_7 := TO_DATE (10000101, 'yyyyMMdd');
   ELSE
      p_7 := TO_DATE (parameter_7, 'yyyyMMdd');
   END IF;

   IF parameter_8 = '0'
   THEN
      p_8 := TO_DATE (30001231, 'yyyyMMdd');
   ELSE
      p_8 := TO_DATE (parameter_8, 'yyyyMMdd');
   END IF;

   OPEN arefcursor FOR
      SELECT fix.fam_fixed_assets_id fam_fixed_assets_id1,
             fix.fam_fixed_assets_categ_id, fix.c_fixed_assets_typ,
             fix.c_ownership, fix.c_fixed_assets_status, fix.dic_liability_id,
             fix.dic_location_id, fix.dic_state_id, fix.dic_use_unit_id,
             fix.fix_number, fix.fix_description, fix.fix_short_descr,
             fix.fix_long_descr, fix.fix_year, fix.fix_model,
             fix.fix_serial_number, fix.fix_warrant_duration,
             fix.fix_warrant_end, fix.fix_landowner_number,
             fix.fix_land_registry_number, fix.fix_surface, fix.fix_volume,
             fix.fix_state_date, fix.fix_purchase_date, fix.fix_working_date,
             fix.fix_unit_quantity, fix.fix_man_accounting_allowed,
             fix.acs_division_account_id, acc1.acc_number acc_number_div,
             des1.des_description_summary des_description_summary_div,
             fix.acs_cda_account_id, acc2.acc_number acc_number_cda,
             des2.des_description_summary des_description_summary_cda,
             fix.acs_pf_account_id, acc3.acc_number acc_number_pf,
             des3.des_description_summary des_description_summary_pf,
             fix.acs_pj_account_id, acc4.acc_number acc_number_pj,
             des4.des_description_summary des_description_summary_pj,
             fix.fam_fam_fixed_assets_id, fix.pac_person_id, per.per_name,
             fix.hrm_person_id, hpe.per_fullname, fix.doc_record_id,
             dre.rco_title, dre.rco_description,
             fix_far.c_fixed_assets_typ c_fixed_assets_typ_far,
             fix_far.fix_number fix_number_far,
             fix_far.fix_short_descr fix_short_descr_far,
             fix_son.c_fixed_assets_typ c_fixed_assets_typ_son,
             fix_son.fix_number fix_number_son,
             fix_son.fix_short_descr fix_short_descr_son, fix.a_datecre,
             fix.a_datemod, fix.a_idmod, fix.a_idcre,
             fix.dic_fam_fix_freecod1_id, fix.dic_fam_fix_freecod2_id,
             fix.dic_fam_fix_freecod3_id, fix.dic_fam_fix_freecod4_id,
             fix.dic_fam_fix_freecod5_id, fix.dic_fam_fix_freecod6_id,
             fix.dic_fam_fix_freecod7_id, fix.dic_fam_fix_freecod8_id,
             fix.dic_fam_fix_freecod9_id, fix.dic_fam_fix_freecod10_id,
             cat.cat_descr,
             (SELECT MAX (fdo.fdo_ext_number)
                FROM fam_imputation fim, fam_document fdo
               WHERE fim.fam_fixed_assets_id =
                                       fix.fam_fixed_assets_id
                 AND fim.fam_document_id = fdo.fam_document_id)
                                                               fdo_ext_number,
             gco.goo_major_reference
        FROM doc_record dre,
             hrm_person hpe,
             pac_person per,
             acs_account acc1,
             acs_account acc2,
             acs_account acc3,
             acs_account acc4,
             acs_description des1,
             acs_description des2,
             acs_description des3,
             acs_description des4,
             fam_fixed_assets fix_son,
             fam_fixed_assets fix_far,
             fam_fixed_assets fix,
             fam_fixed_assets_categ cat,
             gco_good gco
       WHERE fix.fam_fixed_assets_id = fix_far.fam_fam_fixed_assets_id(+)
         AND fix_son.fam_fixed_assets_id(+) = fix.fam_fam_fixed_assets_id
         AND fix.acs_division_account_id = acc1.acs_account_id(+)
         AND fix.acs_cda_account_id = acc2.acs_account_id(+)
         AND fix.acs_pf_account_id = acc3.acs_account_id(+)
         AND fix.acs_pj_account_id = acc4.acs_account_id(+)
         AND acc1.acs_account_id = des1.acs_account_id(+)
         AND des1.pc_lang_id(+) = vpc_lang_id
         AND acc2.acs_account_id = des2.acs_account_id(+)
         AND des2.pc_lang_id(+) = vpc_lang_id
         AND acc3.acs_account_id = des3.acs_account_id(+)
         AND des3.pc_lang_id(+) = vpc_lang_id
         AND acc4.acs_account_id = des4.acs_account_id(+)
         AND des4.pc_lang_id(+) = vpc_lang_id
         AND fix.pac_person_id = per.pac_person_id(+)
         AND fix.hrm_person_id = hpe.hrm_person_id(+)
         AND fix.doc_record_id = dre.doc_record_id(+)
         AND fix.fam_fixed_assets_categ_id = cat.fam_fixed_assets_categ_id(+)
         AND fix.gco_good_id = gco.gco_good_id(+)
         AND ((parameter_10 is null) and (parameter_0 is null OR fix.fix_number >= parameter_0) AND (parameter_1 is null OR fix.fix_number <= parameter_1)
          OR  (fix.fam_fixed_assets_id = parameter_10))
         AND ((parameter_4 is null OR cat.cat_descr >= parameter_4) AND (parameter_5 is null OR cat.cat_descr <= parameter_5))
         AND INSTR (parameter_2, fix.c_fixed_assets_status) > 0
         AND (   parameter_6 = '0'
              OR (    parameter_6 = '1'
                  AND fix.a_datecre >= p_7
                  AND fix.a_datecre <= p_8
                  AND (fix.a_idcre = parameter_9 OR parameter_9 IS NULL)
                 )
              OR (    parameter_6 = '2'
                  AND fix.a_datemod >= p_7
                  AND fix.a_datemod <= p_8
                  AND (fix.a_idmod = parameter_9 OR parameter_9 IS NULL)
                 )
             );
END rpt_fam_fixed_assets_form;
