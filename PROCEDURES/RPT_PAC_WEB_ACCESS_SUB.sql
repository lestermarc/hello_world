--------------------------------------------------------
--  DDL for Procedure RPT_PAC_WEB_ACCESS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_WEB_ACCESS_SUB" (
   arefcursor     IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_99   IN       NUMBER
)
IS
/**
 Description - used for the report PAC_CUSTOM_FORM, PAC_SUPPLIER_FORM, PAC_ADDRESS_FORM

 @author AWU 1 Dec 2008
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_99  PAC_CUSTOM_PARTNER_ID (PAC_SUPPLIER_PARTNER_ID,PAC_PERSON_ID)
*/
BEGIN
   OPEN arefcursor FOR
      SELECT thi.thi_web_key, web.web_user, web.web_password,
             NVL (web.web_password_modification, 0)
                                                   web_password_modification,
             web.web_days_validity, web.web_access_level, web.web_start_date,
             web.web_end_date, web.web_last_access,
             web.web_last_pw_modification, web.pc_lang_id
        FROM pac_third thi, pac_web_access web
       WHERE thi.pac_third_id = web.pac_third_id
         AND thi.pac_third_id = parameter_99;
END rpt_pac_web_access_sub;
