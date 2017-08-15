--------------------------------------------------------
--  DDL for Procedure RPT_PAC_ACS_AUX_CUR_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_ACS_AUX_CUR_SUB" (
   arefcursor     IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_99   IN       NUMBER
)
IS
/**
 Description - used for the report PAC_CUSTOM_FORM, PAC_SUPPLIER_FORM

 @author AWU 1 Dec 2008
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_99  ACS_AUXILIARY_ACCOUNT_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT aac.acs_auxiliary_account_id,
             NVL (aac.asc_default, 0) asc_default, pcu.currency,
             pcu.currname
        FROM acs_aux_account_s_fin_curr aac,
             acs_financial_currency fcr,
             pcs.pc_curr pcu
       WHERE aac.acs_financial_currency_id = fcr.acs_financial_currency_id
         AND fcr.pc_curr_id = pcu.pc_curr_id
         AND aac.acs_auxiliary_account_id = parameter_99;
END rpt_pac_acs_aux_cur_sub;
