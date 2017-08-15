--------------------------------------------------------
--  DDL for Procedure RPT_ASA_ACKNOWLEDGEMENT_3
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_ACKNOWLEDGEMENT_3" (
   arefcursor      IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0     IN       VARCHAR2,
   company_owner   IN       VARCHAR2,
   output_mode     IN       NUMBER
)
IS
/*
* Description STORED PROCEDURE USED FOR REPORT ASA_ACKNOWLEDGEMENT_3

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZHU 06 Dec 2008
* @lastupdate VHA 26 JUNE 2013
* @PUBLIC
* @PARAM PROCPARAM_0: Document number (Repair Acknowledgement)
*/
   vcom_vfields_record_id   NUMBER (12);
   vvfi_date_01             DATE;
   vcom_logo_large          pcs.pc_comp.com_logo_large%TYPE := null;
BEGIN
   BEGIN
      SELECT vfi.com_vfields_record_id, vfi.vfi_date_01
        INTO vcom_vfields_record_id, vvfi_date_01
        FROM asa_record ARE, com_vfields_record vfi
       WHERE ARE.asa_record_id = vfi.vfi_rec_id
         AND ARE.are_number = parameter_0;

      IF (vvfi_date_01 IS NULL) AND output_mode <> 0 AND output_mode <> 100
      THEN
         UPDATE com_vfields_record vfi
            SET vfi.vfi_date_01 = SYSDATE
          WHERE vfi.com_vfields_record_id = vcom_vfields_record_id;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END;

   if (company_owner is not null) then
       SELECT com.com_logo_large
         INTO vcom_logo_large
         FROM pcs.pc_comp com, pcs.pc_scrip scr
        WHERE com.pc_scrip_id = scr.pc_scrip_id AND scr.scrdbowner = company_owner;
    end if;

   OPEN arefcursor FOR
      SELECT vcom_logo_large com_logo_large,
      ARE.are_number,
             ARE.are_address_fin_cust,
             ARE.are_format_city_fin_cust,
             ARE.are_char1_value,
             ARE.are_customer_ref,
             ARE.a_datecre,
             ARE.a_idcre,
             ARE.a_idmod,
             ARE.are_gco_short_descr,
             ARE.are_gco_long_descr,
             ARE.are_gco_free_descr,
             vfi.com_vfields_record_id,
             vfi.vfi_char_01,
             vfi.vfi_date_01,
             goo.goo_major_reference,
             per_fin.per_name per_name_fin,
             per_fin.per_forename per_forename_fin,
             per_fin.per_key1 per_key1_fin,
             lan.lanid,
             rpt_functions.getasaadr (ARE.asa_record_id,
                                      1,
                                      1,
                                      ARE.pc_asa_cust_lang_id
                                     ) block1_title,
             rpt_functions.getasaadr (ARE.asa_record_id,
                                      2,
                                      1,
                                      ARE.pc_asa_cust_lang_id
                                     ) block1_name,
             rpt_functions.getasaadr (ARE.asa_record_id,
                                      3,
                                      1,
                                      ARE.pc_asa_cust_lang_id
                                     ) block1_info,
             rpt_functions.getasaadr (ARE.asa_record_id,
                                      1,
                                      2,
                                      ARE.pc_asa_cust_lang_id
                                     ) block2_title,
             rpt_functions.getasaadr (ARE.asa_record_id,
                                      2,
                                      2,
                                      ARE.pc_asa_cust_lang_id
                                     ) block2_name,
             rpt_functions.getasaadr (ARE.asa_record_id,
                                      3,
                                      2,
                                      ARE.pc_asa_cust_lang_id
                                     ) block2_info,
             rpt_functions.getasaadr (ARE.asa_record_id,
                                      1,
                                      3,
                                      ARE.pc_asa_cust_lang_id
                                     ) block3_title,
             rpt_functions.getasaadr (ARE.asa_record_id,
                                      2,
                                      3,
                                      ARE.pc_asa_cust_lang_id
                                     ) block3_name,
             rpt_functions.getasaadr (ARE.asa_record_id,
                                      3,
                                      3,
                                      ARE.pc_asa_cust_lang_id
                                     ) block3_info
        FROM asa_record ARE,
             com_vfields_record vfi,
             gco_good goo,
             gco_good goo_exc,
             pac_person per,
             pac_person per_fin,
             pcs.pc_lang lan
       WHERE ARE.asa_record_id = vfi.vfi_rec_id(+)
         AND ARE.pac_custom_partner_id = per.pac_person_id
         AND ARE.pac_asa_fin_cust_id = per_fin.pac_person_id(+)
         AND ARE.pc_asa_cust_lang_id = lan.pc_lang_id
         AND ARE.gco_asa_to_repair_id = goo.gco_good_id
         AND ARE.gco_asa_exchange_id = goo_exc.gco_good_id(+)
         AND ARE.are_number = parameter_0;
END rpt_asa_acknowledgement_3;
