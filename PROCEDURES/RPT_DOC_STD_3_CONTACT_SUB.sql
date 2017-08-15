--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_CONTACT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_CONTACT_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_1   IN       NUMBER
)
IS
/**
*Description - Used for report DOC_STD_3

*@created MZHU 17 MAY 2009
*@lastUpdate   4 MAR 2009
*@public
*@param PARAMETER_1:  PAC_PERSON_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT per.per_name, per.per_forename
        FROM pac_person per, pac_person_association pac
       WHERE pac.pac_pac_person_id = per.pac_person_id
         AND pac.pac_person_id = parameter_1;
END rpt_doc_std_3_contact_sub;
