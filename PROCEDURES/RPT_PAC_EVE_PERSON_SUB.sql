--------------------------------------------------------
--  DDL for Procedure RPT_PAC_EVE_PERSON_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_EVE_PERSON_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**
 Description - used for the report PAC_EVENT_REP, PAC_EVENT_PLA

 @author AWU Jan 2009
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_0  PAC_PERSON_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT dco.dco_default1, dco.dco_default2, dco.dco_default3,
             adr.pac_address_id, adr.pac_person_id, adr.add_address1,
             adr.add_format, adr.add_principal,
             com.dic_communication_type_id, com.com_ext_number,
             com.com_int_number, com.com_area_code, per.per_name,
             per.per_forename, per.per_activity
        FROM dic_communication_type dco,
             pac_address adr,
             pac_communication com,
             pac_person per
       WHERE per.pac_person_id = adr.pac_person_id(+)
         AND per.pac_person_id = com.pac_person_id(+)
         AND com.dic_communication_type_id = dco.dic_communication_type_id(+)
         AND per.pac_person_id = parameter_0;
END rpt_pac_eve_person_sub;
