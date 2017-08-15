--------------------------------------------------------
--  DDL for Procedure RPT_FAM_ADDITION_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_ADDITION_SUB" (
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
      SELECT fix.fam_fixed_assets_id, fix.fix_number, fix.fix_year,
             fix.fix_model, fix.fix_serial_number, fix.fix_warrant_duration,
             fix.fix_warrant_end, fix.fix_landowner_number,
             fix.fix_land_registry_number, fix.fix_surface, fix.fix_volume,
             fix.dic_liability_id,
             com_dic_functions.getdicodescr
                                    ('DIC_LIABILITY',
                                     fix.dic_liability_id,
                                     vpc_lang_id
                                    ) dic_liability_desc,
             fix.dic_location_id,
             com_dic_functions.getdicodescr
                                      ('DIC_LOCATION',
                                       fix.dic_location_id,
                                       vpc_lang_id
                                      ) dic_location_desc,
             fix.dic_state_id,
             com_dic_functions.getdicodescr ('DIC_STATE',
                                             fix.dic_state_id,
                                             vpc_lang_id
                                            ) dic_state_desc,
             fix.fix_state_date
        FROM fam_fixed_assets fix
       WHERE fix.fix_number = parameter_0;
END rpt_fam_addition_sub;
