--------------------------------------------------------
--  DDL for Procedure RPT_PAC_CHARGE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_CHARGE_SUB" (
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
      SELECT crg.crg_name
        FROM ptc_charge crg, ptc_charge_s_partners cpa
       WHERE crg.ptc_charge_id = cpa.ptc_charge_id
         AND cpa.pac_third_id = parameter_99;
END rpt_pac_charge_sub;
