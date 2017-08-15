--------------------------------------------------------
--  DDL for Procedure RPT_PAC_CONTACT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_CONTACT_SUB" (
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
      SELECT com.dic_communication_type_id, com.com_ext_number,
             com.com_int_number, com.com_area_code, per.per_name,
             ass.pac_person_association_id, ass.dic_association_type_id,
             ass.pas_function
        FROM pac_communication com,
             pac_person per,
             pac_person_association ass
       WHERE ass.pac_pac_person_id = com.pac_person_id(+)
         AND ass.pac_pac_person_id = per.pac_person_id
         AND ass.pac_person_id = parameter_99;
END rpt_pac_contact_sub;
