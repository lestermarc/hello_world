--------------------------------------------------------
--  DDL for Procedure RPT_PAC_SENDING_CONDITION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_SENDING_CONDITION" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2
)
IS
/**
 Description - used for report PAC_SENDING_CONDITION

 @author PYB
 @LastUpdate 24 NOV 2009
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
   per.pac_person_id,
   per.dic_person_politness_id,
   per.per_name,
   per.per_forename,
   per.per_short_name,
   per.per_activity,
   per.per_key1,
   per.per_key2,
   adr.add_principal,
   adr.dic_address_type_id,
   adr.add_address1,
   cty.cntid,
   cty.cntname,
   adr.pac_address_id,
   adr.add_zipcode,
   adr.add_city,
   adr.add_state,
   adr.add_format,
   adr.pc_lang_id,
   SEN.PAC_SENDING_CONDITION_ID,
   SEN.SEN_KEY,
   SEN.C_PARTNER_STATUS,
   SEN.C_CONDITION_MODE
   FROM pac_sending_condition sen,
        pcs.pc_cntry cty,
        pac_address adr,
        pac_person per
   WHERE SEN.PAC_ADDRESS_ID = ADR.PAC_ADDRESS_ID (+)
         AND  adr.pac_person_id = per.pac_person_id (+)
         AND  adr.pc_cntry_id = cty.pc_cntry_id (+)
         AND ((parameter_0 IS NULL AND parameter_1 IS NULL)
              OR (parameter_0 IS NOT NULL AND parameter_1 IS NULL AND SEN.SEN_KEY >= parameter_0)
              OR (parameter_1 IS NOT NULL AND parameter_0 IS NULL AND SEN.SEN_KEY <= parameter_1)
              OR (parameter_0 IS NOT NULL AND parameter_1 IS NOT NULL AND SEN.SEN_KEY >= parameter_0 AND SEN.SEN_KEY <= parameter_1));

END RPT_PAC_SENDING_CONDITION;
