--------------------------------------------------------
--  DDL for Procedure RPT_PAC_PAYMENT_CONDITION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_PAYMENT_CONDITION" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2
)
IS
/**
 Description - used for report PAC_PAYMENT_CONDITION

 @author JLIU
 @LastUpdate 25 Aug 2009
 @public
 @PARAM  parameter_0  PCO_DESCR: (from)
 @PARAM  parameter_1  PCO_DESCR: (to)
*/
   vpc_lang_id             pcs.pc_lang.pc_lang_id%TYPE;

BEGIN


   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR

SELECT
CON.PAC_PAYMENT_CONDITION_ID,
CON.PCO_DESCR,
CON.PCO_DEFAULT,
CON.C_PARTNER_STATUS,
CON.PCO_DEFAULT_PAY,
CON.DIC_CONDITION_TYP_ID,
TXT.PC_APPLTXT_ID,
TXT.C_TEXT_TYPE,
TXT.APH_CODE,
TRA.PC_LANG_ID,
TRA.APT_TEXT
FROM
PAC_PAYMENT_CONDITION CON,
PCS.PC_APPLTXT TXT,
PCS.PC_APPLTXT_TRADUCTION TRA
WHERE
CON.PC_APPLTXT_ID = TXT.PC_APPLTXT_ID(+)
AND TXT.PC_APPLTXT_ID = TRA.PC_APPLTXT_ID(+)
AND TRA.PC_LANG_ID = vpc_lang_id
AND ((parameter_0 IS NULL AND parameter_1 IS NULL)
    OR (parameter_0 IS NOT NULL AND parameter_1 IS NULL AND CON.PCO_DESCR >= parameter_0)
    OR (parameter_1 IS NOT NULL AND parameter_0 IS NULL AND CON.PCO_DESCR <= parameter_1)
    OR (parameter_0 IS NOT NULL AND parameter_1 IS NOT NULL AND CON.PCO_DESCR >= parameter_0 AND CON.PCO_DESCR <= parameter_1))


;
END RPT_PAC_PAYMENT_CONDITION;
