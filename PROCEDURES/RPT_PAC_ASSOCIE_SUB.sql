--------------------------------------------------------
--  DDL for Procedure RPT_PAC_ASSOCIE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_ASSOCIE_SUB" (
   arefcursor     IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_99   IN       NUMBER
)
IS
/**
 Description - used for the report PAC_ADDRESS_FORM

 @author AWU 1 Dec 2008
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_99  PAC_PERSON_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT adr.pac_person_id, adr.add_address1, adr.add_format,
             thi.pac_pac_person_id
        FROM pac_third thi, pac_address adr
       WHERE thi.pac_pac_person_id = adr.pac_person_id(+)
             AND adr.pac_person_id = parameter_99;
END rpt_pac_associe_sub;
