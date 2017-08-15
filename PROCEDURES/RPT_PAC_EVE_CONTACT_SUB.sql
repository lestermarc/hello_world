--------------------------------------------------------
--  DDL for Procedure RPT_PAC_EVE_CONTACT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_EVE_CONTACT_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER,
   parameter_8   IN       VARCHAR
)
IS
/**
 Description - used for the report PAC_EVENT_REP, PAC_EVENT_PLA

 @author AWU Jan 2009
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_0  PAC_PERSON_ID
 @PARAM  parameter_8  DIC_ASSOCIATION_TYPE_ID : #=all  / ID-list
*/
BEGIN
   OPEN arefcursor FOR
      SELECT com.dic_communication_type_id, com.com_ext_number,
             com.com_int_number, com.com_area_code, per.per_name,
             per.per_forename, pas.pac_person_id,
             pas.dic_association_type_id
        FROM pac_person_association pas,
             pac_person per,
             pac_communication com,
             THE
                (SELECT CAST
                           (doc_document_list_functions.in_list
                                                       (REPLACE (parameter_8,
                                                                 '''',
                                                                 ''
                                                                ),
                                                        ';'
                                                       ) AS char_table_type
                           )
                   FROM DUAL
                ) dic_association_type_id_list
       WHERE pas.pac_pac_person_id = per.pac_person_id
         AND per.pac_person_id = com.pac_person_id(+)
         AND (   pas.dic_association_type_id =
                                     dic_association_type_id_list.COLUMN_VALUE
              OR parameter_8 = '#'
             )
         AND pas.pac_person_id = parameter_0;
END rpt_pac_eve_contact_sub;
