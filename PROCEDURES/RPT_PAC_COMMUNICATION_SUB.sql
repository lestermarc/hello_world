--------------------------------------------------------
--  DDL for Procedure RPT_PAC_COMMUNICATION_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_COMMUNICATION_SUB" (
   arefcursor     IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_99   IN       NUMBER
)
IS
/**
 Description - used for the report PAC_CUSTOM_FORM, PAC_SUPPLIER_FORM, PAC_ADDRESS_FORM

 @author AWU 1Dec 2008
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_99  PAC_PERSON_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT pad.dic_address_type_id, com.dic_communication_type_id,
             com.com_ext_number, com.com_area_code, com.com_int_number
        FROM pac_address pad, pac_communication com
       WHERE com.pac_address_id = pad.pac_address_id(+)
             AND com.pac_person_id = parameter_99;
END rpt_pac_communication_sub;
