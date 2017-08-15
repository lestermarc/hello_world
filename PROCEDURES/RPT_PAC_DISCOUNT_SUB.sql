--------------------------------------------------------
--  DDL for Procedure RPT_PAC_DISCOUNT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_DISCOUNT_SUB" (
   arefcursor     IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_99   IN       NUMBER
)
IS
/**
 Description - used for the report PAC_CUSTOM_FORM, PAC_SUPPLIER_FORM
 @author AWU 1 Dec 2008
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_99  PAC_CUSTOM_PARTNER_ID (PAC_SUPPLIER_PARTNER_ID)
*/
BEGIN
   OPEN arefcursor FOR
      SELECT dnt.dnt_name
        FROM ptc_discount dnt, ptc_discount_s_third dth
       WHERE dnt.ptc_discount_id = dth.ptc_discount_id
         AND dth.pac_third_id = parameter_99;
END rpt_pac_discount_sub;
