--------------------------------------------------------
--  DDL for Procedure RPT_PAC_EVENT_PLA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_EVENT_PLA" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2
)
IS
/**
 Description - used for the report PAC_EVENT_PLA

 @author AWU Jan 2009
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_0  PC_USER_ID : 0=all
 @PARAM  parameter_1  Date from : YYYYMMDD
 @PARAM  parameter_2  Date to : YYYYMMDD
 @PARAM  parameter_3  Private Events : 0=all, 1=not private, 2=private
 @PARAM  parameter_6  DIC_EVENT_DOMAIN_ID : #=all  / ID-list
*/
   vpc_lang_id    pcs.pc_lang.pc_lang_id%TYPE;
   para_private   NUMBER (1);
BEGIN
   CASE parameter_3
      WHEN '1'
      THEN
         para_private := 0;
      WHEN '2'
      THEN
         para_private := 1;
      WHEN '0'
      THEN
         para_private := 2;
      ELSE
         NULL;
   END CASE;

   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT eve.pac_event_id, eve.pac_person_id, eve.eve_text, eve.eve_date,
             eve.eve_number, eve.eve_date_completed, evo.eve_text eve_text_o,
             evo.eve_date eve_date_o, des.typ_long_description,
             deo.typ_long_description typ_long_description_o, lea.lea_label,
             per.per_short_name, pas.pac_pac_person_id, usr.pc_user_id,
             usr.use_name, usr.use_descr, eve.eve_percent_complete
        FROM pac_event eve,
             pac_person per,
             pac_person_association pas,
             pcs.pc_user usr,
             pac_event evo,
             pac_event_type tyo,
             pac_event_type_descr deo,
             pac_event_type typ,
             pac_event_type_descr des,
             pac_lead lea,
             THE
                (SELECT CAST
                           (doc_document_list_functions.in_list
                                                       (REPLACE (parameter_6,
                                                                 '''',
                                                                 ''
                                                                ),
                                                        ';'
                                                       ) AS char_table_type
                           )
                   FROM DUAL
                ) dic_event_domain_id_list
       WHERE eve.pac_event_id = per.pac_person_id(+)
         AND eve.pac_association_id = pas.pac_person_association_id(+)
         AND eve.eve_user_id = usr.pc_user_id
         AND eve.pac_pac_event_id = evo.pac_event_id(+)
         AND evo.pac_event_type_id = tyo.pac_event_type_id(+)
         AND tyo.pac_event_type_id = deo.pac_event_type_id(+)
         AND eve.pac_event_type_id = typ.pac_event_type_id
         AND typ.pac_event_type_id = des.pac_event_type_id(+)
         AND eve.pac_lead_id = lea.pac_lead_id(+)
         AND eve.eve_ended = 0
         AND eve.eve_date BETWEEN TO_DATE (parameter_1, 'YYYYMMDD')
                              AND TO_DATE (parameter_2, 'YYYYMMDD')
         AND (usr.pc_user_id = parameter_0 OR parameter_0 = 0)
         AND (eve.eve_private = para_private OR para_private = 2)
         AND (   typ.dic_event_domain_id =
                                         dic_event_domain_id_list.COLUMN_VALUE
              OR parameter_6 = '#'
             )
         AND (des.pac_event_type_id IS NULL OR des.pc_lang_id = vpc_lang_id)
         AND (deo.pac_event_type_id IS NULL OR deo.pc_lang_id = vpc_lang_id);
END rpt_pac_event_pla;
