--------------------------------------------------------
--  DDL for Procedure RPT_ASA_RECORD_FORM3
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_RECORD_FORM3" (
   arefcursor      IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0     IN       asa_record.are_number%TYPE,
   company_owner   IN       pcs.pc_comp.com_name%TYPE,
   user_lanid      IN       VARCHAR2
)
IS
/*
* description used for report asa_report_form3

*@created pna 21.08.2007 proconcept china
*@lastupdate mzh 3 Jun. 2010
*@version
*@public
*@param param procparam_0: asa_record.are_number
*/
   vpc_lang_id   NUMBER (12);
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (user_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT ARE.asa_record_id, ARE.asa_record_events_id, ARE.are_number,
             ARE.are_customer_ref, ARE.are_datecre, ARE.are_char1_value,
             goo.goo_major_reference,
                goo.goo_major_reference
             || ' / '
             || ARE.are_char1_value goo_goo_char,
             exc.goo_major_reference exc_major_reference,
                exc.goo_major_reference
             || ' / '
             || ARE.are_new_char1_value exc_goo_char,
             ARE.are_new_char1_value, ARE.gco_asa_exchange_id,
             ARE.are_exch_char1_value, ARE.c_asa_rep_status,
             com_functions.getdescodedescr
                                ('C_ASA_REP_STATUS',
                                 ARE.c_asa_rep_status,
                                 vpc_lang_id
                                ) c_asa_rep_status_descr,
             ARE.are_gco_short_descr_ex, ARE.are_gco_free_descr_ex,
             ARE.are_date_end_rep, ARE.are_date_end_ctrl,
             ARE.are_gco_short_descr, ARE.are_gco_long_descr,
             ARE.are_date_end_sending, ARE.gco_asa_to_repair_id,
             ARE.dic_garanty_code_id,
             com_dic_functions.getdicodescr
                               ('DIC_GARANTY_CODE',
                                ARE.dic_garanty_code_id,
                                vpc_lang_id
                               ) dic_garanty_code_des,
             per.per_name, ARE.are_address1,
             pcs.extractline (ARE.are_address1, 1) are_address1_extract,
             per.per_short_name, ARE.gco_new_good_id, ARE.asa_rep_type_id,
             lan.lanid, ret.c_asa_rep_type_kind,

             --for showing the picture
             rpt_functions.get_asa_img_path (ARE.asa_record_id) asa_picture,
             TO_CHAR (NVL (dlo.offer_datecre, SYSDATE),
                      'YYYYMMDD HH24:MI:SS'
                     ) offer_datecre,
             NVL ((SELECT COUNT (*)
                     FROM asa_record_task ret
                    WHERE ret.asa_record_id = ARE.asa_record_id
                      AND ret.asa_record_events_id = ARE.asa_record_events_id
                      AND ret.ret_optional = 0
                      AND (ret.a_datecre) <=
                                           (NVL (dlo.offer_datecre, SYSDATE)
                                           )),
                  0
                 ) ope_req,
             NVL ((SELECT COUNT (*)
                     FROM asa_record_comp arc
                    WHERE arc.asa_record_id = ARE.asa_record_id
                      AND arc.asa_record_events_id = ARE.asa_record_events_id
                      AND arc.arc_optional = 0
                      AND (arc.a_datecre) <=
                                           (NVL (dlo.offer_datecre, SYSDATE)
                                           )),
                  0
                 ) comp_req,
             NVL ((SELECT COUNT (*)
                     FROM asa_record_task ret
                    WHERE ret.asa_record_id = ARE.asa_record_id
                      AND ret.asa_record_events_id = ARE.asa_record_events_id
                      AND ret.ret_optional = 1
                      AND (ret.a_datecre) <=
                                           (NVL (dlo.offer_datecre, SYSDATE)
                                           )),
                  0
                 ) ope_opt,
             NVL ((SELECT COUNT (*)
                     FROM asa_record_comp arc
                    WHERE arc.asa_record_id = ARE.asa_record_id
                      AND arc.asa_record_events_id = ARE.asa_record_events_id
                      AND arc.arc_optional = 1
                      AND (arc.a_datecre) <=
                                           (NVL (dlo.offer_datecre, SYSDATE)
                                           )),
                  0
                 ) comp_opt,
             NVL ((SELECT COUNT (*)
                     FROM asa_record_task ret
                    WHERE ret.asa_record_id = ARE.asa_record_id
                      AND ret.asa_record_events_id = ARE.asa_record_events_id
                      AND (ret.a_datecre) >
                                           (NVL (dlo.offer_datecre, SYSDATE)
                                           )),
                  0
                 ) ope_add,
             NVL ((SELECT COUNT (*)
                     FROM asa_record_comp arc
                    WHERE arc.asa_record_id = ARE.asa_record_id
                      AND arc.asa_record_events_id = ARE.asa_record_events_id
                      AND (arc.a_datecre) >
                                           (NVL (dlo.offer_datecre, SYSDATE)
                                           )),
                  0
                 ) comp_add
        FROM asa_record ARE,
             gco_good goo,
             gco_good exc,
             pac_person per,
             (SELECT   MAX (rre1.a_datecre) offer_datecre, are1.asa_record_id
                  FROM asa_record are1, asa_record_events rre1
                 WHERE are1.asa_record_id = rre1.asa_record_id
                   AND are1.c_asa_rep_status = '02'
              GROUP BY are1.asa_record_id) dlo,
             pcs.pc_lang lan,
             asa_rep_type ret
       WHERE ARE.pac_custom_partner_id = per.pac_person_id
         AND ARE.gco_asa_to_repair_id = goo.gco_good_id(+)
         AND ARE.gco_asa_exchange_id = exc.gco_good_id(+)
         AND dlo.asa_record_id(+) = ARE.asa_record_id
         AND ARE.pc_asa_cust_lang_id = lan.pc_lang_id(+)
         AND ARE.asa_rep_type_id = ret.asa_rep_type_id(+)
         AND ARE.are_number = parameter_0;
END rpt_asa_record_form3;
