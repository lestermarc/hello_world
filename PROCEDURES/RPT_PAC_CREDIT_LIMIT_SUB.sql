--------------------------------------------------------
--  DDL for Procedure RPT_PAC_CREDIT_LIMIT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_CREDIT_LIMIT_SUB" (
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
      SELECT crl.c_valid, crl.c_limit_type, crl.pc_user_id,
             crl.cre_amount_limit, crl.cre_comment, crl.cre_limit_date,
             acs_function.getcurrencyname
                                       (crl.acs_financial_currency_id)
                                                                     monnaie
        FROM pac_credit_limit crl
       WHERE crl.pac_custom_partner_id = parameter_99;
END rpt_pac_credit_limit_sub;
