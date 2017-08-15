--------------------------------------------------------
--  DDL for Procedure RPT_FAM_ACCOUNTING_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_ACCOUNTING_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   procuser_lanid   IN       VARCHAR2
)
IS
/*
*Description - used for the report FAM_FIXED_ASSETS_FORM

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZH 27 FEB 2008
* @LASTUPDATE
* @VERSION
* @PUBLIC
* @PARAM PARAMETER_0: Fixed assets number
* @PARAM PROCUSER_LANID: User language
*/
   vpc_lang_id   NUMBER (12);
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT fix.fam_fixed_assets_id, fix.dic_use_unit_id,
             com_dic_functions.getdicodescr
                                      ('DIC_USE_UNIT',
                                       fix.dic_use_unit_id,
                                       vpc_lang_id
                                      ) dic_use_unit_desc,
             fix.fix_number, fix.fix_state_date, fix.fix_purchase_date,
             fix.fix_working_date, fix.fix_unit_quantity,
             fix.fix_man_accounting_allowed, fix.acs_division_account_id,
             acc1.acc_number acc_number_div,
             des1.des_description_summary des_description_summary_div,
             fix.acs_cda_account_id, acc2.acc_number acc_number_cda,
             des2.des_description_summary des_description_summary_cda,
             fix.acs_pf_account_id, acc3.acc_number acc_number_pf,
             des3.des_description_summary des_description_summary_pf,
             fix.acs_pj_account_id, acc4.acc_number acc_number_pj,
             des4.des_description_summary des_description_summary_pj,
             fix.pac_person_id, per.per_name, fix.hrm_person_id,
             hpe.per_fullname, fix.doc_record_id, dre.rco_title,
             dre.rco_description,
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
             fam_fixed_assets fix,
             gco_good gco
       WHERE fix.acs_division_account_id = acc1.acs_account_id(+)
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
         AND fix.gco_good_id = gco.gco_good_id(+)
         AND fix.fix_number = parameter_0;
END rpt_fam_accounting_sub;
