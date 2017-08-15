--------------------------------------------------------
--  DDL for Procedure RPT_FAM_FREE_CODE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_FREE_CODE_SUB" (
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
      SELECT fix.fam_fixed_assets_id, fix.fix_number,
             fix.dic_fam_fix_freecod1_id,
             com_dic_functions.getdicodescr
                      ('DIC_FAM_FIX_FREECOD1',
                       fix.dic_fam_fix_freecod1_id,
                       vpc_lang_id
                      ) dic_fam_fix_freecod1_desc,
             fix.dic_fam_fix_freecod2_id,
             com_dic_functions.getdicodescr
                      ('DIC_FAM_FIX_FREECOD2',
                       fix.dic_fam_fix_freecod2_id,
                       vpc_lang_id
                      ) dic_fam_fix_freecod2_desc,
             fix.dic_fam_fix_freecod3_id,
             com_dic_functions.getdicodescr
                      ('DIC_FAM_FIX_FREECOD3',
                       fix.dic_fam_fix_freecod3_id,
                       vpc_lang_id
                      ) dic_fam_fix_freecod3_desc,
             fix.dic_fam_fix_freecod4_id,
             com_dic_functions.getdicodescr
                      ('DIC_FAM_FIX_FREECOD4',
                       fix.dic_fam_fix_freecod4_id,
                       vpc_lang_id
                      ) dic_fam_fix_freecod4_desc,
             fix.dic_fam_fix_freecod5_id,
             com_dic_functions.getdicodescr
                      ('DIC_FAM_FIX_FREECOD5',
                       fix.dic_fam_fix_freecod5_id,
                       vpc_lang_id
                      ) dic_fam_fix_freecod5_desc,
             fix.dic_fam_fix_freecod6_id,
             com_dic_functions.getdicodescr
                      ('DIC_FAM_FIX_FREECOD6',
                       fix.dic_fam_fix_freecod6_id,
                       vpc_lang_id
                      ) dic_fam_fix_freecod6_desc,
             fix.dic_fam_fix_freecod7_id,
             com_dic_functions.getdicodescr
                      ('DIC_FAM_FIX_FREECOD7',
                       fix.dic_fam_fix_freecod7_id,
                       vpc_lang_id
                      ) dic_fam_fix_freecod7_desc,
             fix.dic_fam_fix_freecod8_id,
             com_dic_functions.getdicodescr
                      ('DIC_FAM_FIX_FREECOD8',
                       fix.dic_fam_fix_freecod8_id,
                       vpc_lang_id
                      ) dic_fam_fix_freecod8_desc,
             fix.dic_fam_fix_freecod9_id,
             com_dic_functions.getdicodescr
                      ('DIC_FAM_FIX_FREECOD9',
                       fix.dic_fam_fix_freecod9_id,
                       vpc_lang_id
                      ) dic_fam_fix_freecod9_desc,
             fix.dic_fam_fix_freecod10_id,
             com_dic_functions.getdicodescr
                    ('DIC_FAM_FIX_FREECOD10',
                     fix.dic_fam_fix_freecod10_id,
                     vpc_lang_id
                    ) dic_fam_fix_freecod10_desc
        FROM fam_fixed_assets fix
       WHERE fix.fix_number = parameter_0;
END rpt_fam_free_code_sub;
