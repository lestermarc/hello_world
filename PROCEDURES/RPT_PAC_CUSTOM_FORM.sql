--------------------------------------------------------
--  DDL for Procedure RPT_PAC_CUSTOM_FORM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_CUSTOM_FORM" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   parameter_5      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2,
   parameter_8      IN       VARCHAR2
)
IS
/**
 Description - used for the report PAC_CUSTOM_FORM

 @author AWU 1 Dec 2008
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_0  Client de : (PER_NAME)
 @PARAM  parameter_1  Client à: (PER_NAME)
 @PARAM  parameter_3  Section: 0 = Aucune, 1 = Crétion, 2 = Modification
 @PARAM  parameter_4  Date du: (Crétion ou modification) YYYYMMDD
 @PARAM  parameter_5  Date au: (Crétion ou modification) YYYYMMDD
 @PARAM  parameter_6  Initiales utilisateur: (Crétion ou modification)
 @PARAM  parameter_8  pac_person_id
*/
   vpc_lang_id             pcs.pc_lang.pc_lang_id%TYPE;
   param_a_datecre_start   DATE;
   param_a_datecre_end     DATE;
   param_a_idcre           VARCHAR2 (5);
   param_a_datemod_start   DATE;
   param_a_datemod_end     DATE;
   param_a_idmod           VARCHAR2 (5);
BEGIN
   CASE parameter_3
      WHEN '0'
      THEN
         NULL;
      WHEN '1'
      THEN
         IF parameter_4 = '0'
         THEN
            IF parameter_6 IS NOT NULL
            THEN
               param_a_idcre := parameter_6;
            END IF;
         ELSE
            param_a_datecre_start := parameter_4;
            param_a_datecre_end := parameter_5;

            IF parameter_6 IS NOT NULL
            THEN
               param_a_idcre := parameter_6;
            END IF;
         END IF;
      WHEN '2'
      THEN
         IF parameter_4 = '0'
         THEN
            IF parameter_6 IS NOT NULL
            THEN
               param_a_idmod := parameter_6;
            END IF;
         ELSE
            param_a_datemod_start := parameter_4;
            param_a_datemod_end := parameter_5;

            IF parameter_6 IS NOT NULL
            THEN
               param_a_idmod := parameter_6;
            END IF;
         END IF;
      ELSE
         NULL;
   END CASE;

   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT per.pac_person_id, per.per_key1, per.per_key2,
             per.dic_person_politness_id, per.per_name, per.per_forename,
             per.per_short_name, per.per_activity, per.per_comment,
             per.dic_free_code1_id, per.dic_free_code2_id,
             per.dic_free_code3_id, per.dic_free_code4_id,
             per.dic_free_code5_id, per.dic_free_code6_id,
             per.dic_free_code7_id, per.dic_free_code8_id,
             per.dic_free_code9_id, per.dic_free_code10_id,
             cus.pac_custom_partner_id, cus.c_partner_category,
             acc1.acc_number, cus.pac_payment_condition_id,
             cus.c_partner_status, cus.c_status_settlement,
             cus.dic_type_submission_id, thi.thi_no_tva, thi.thi_no_intra,
             cus.c_remainder_launching, cus.cus_without_remind_date,
             cus.pac_remainder_category_id, cus.dic_type_partner_id,
             cus.cus_free_zone1, cus.cus_free_zone2, cus.cus_free_zone3,
             cus.cus_free_zone4, cus.cus_free_zone5, cus.dic_statistic_1_id,
             cus.dic_statistic_2_id, cus.dic_statistic_3_id,
             cus.dic_statistic_4_id, cus.dic_statistic_5_id,
             pe1.per_name per_name_1, pe1.per_forename per_forename_1,
             pe2.per_name per_name_2, pe2.per_forename per_forename_2,
             cus.pac_representative_id, cus.dic_ptc_third_group_id,
             cus.dic_tariff_id, cus.pac_sending_condition_id,
             cus.cus_rate_for_value, cus.pac_calendar_type_id,
             cus.dic_complementary_data_id, cus.dic_pic_group_id,
             cus.c_incoterms, cus.cus_incoterms_place, cus.c_reservation_typ,
             cus.cus_delivery_delay,
             NVL (cus.cus_periodic_delivery, 0) cus_periodic_delivery,
             cus.c_delivery_typ, cus.dic_delivery_period_id,
             cus.c_doc_creation,
             NVL (cus.cus_periodic_invoicing, 0) cus_periodic_invoicing,
             cus.dic_invoicing_period_id, cus.c_doc_creation_invoice,
             cus.cus_min_invoicing, cus.cus_min_invoicing_delay,
             cus.c_bvr_generation_method, cus.c_type_edi, cus.cus_data_export,
             cus.cus_supplier_number, cus.cus_ean_number, cus.doc_gauge_id,
             cus.doc_doc_gauge_id, cus.cus_sup_copy1, cus.cus_sup_copy2,
             cus.cus_sup_copy3, cus.cus_sup_copy4, cus.cus_sup_copy5,
             cus.cus_sup_copy6, cus.cus_sup_copy7, cus.cus_sup_copy8,
             cus.cus_sup_copy9, cus.cus_sup_copy10, thi.dic_third_activity_id,
             thi.dic_third_area_id, thi.dic_juridical_status_id,
             thi.dic_citi_code_id, thi.thi_no_siren, thi.thi_no_siret,
             thi.pac_pac_person_id, cus.pc_appltxt_id, cus.pc__pc_appltxt_id,
             cus.pc_2_pc_appltxt_id, cus.pc_3_pc_appltxt_id,
             cus.pc_4_pc_appltxt_id, cus.cus_lapsing_marge,
             aux.acs_auxiliary_account_id, aux.acs_prep_coll_id,
             aux.acs_invoice_coll_id, aux.acs_financial_account_id,
             NVL (acc2.acc_detail_printing, 0) acc_detail_printing,
             NVL (acc2.acc_blocked, 0) acc_blocked, acc2.acc_valid_since,
             acc2.acc_valid_to, des.des_description_summary,
             pcs.pc_functions.getappltxtlabel
                               (cus.pc_appltxt_id,
                                vpc_lang_id
                               ) c_texte_pied_1_description,
             pcs.pc_functions.getappltxtlabel
                           (cus.pc__pc_appltxt_id,
                            vpc_lang_id
                           ) c_texte_pied_2_description,
             pcs.pc_functions.getappltxtlabel
                          (cus.pc_2_pc_appltxt_id,
                           vpc_lang_id
                          ) c_texte_pied_3_description,
             pcs.pc_functions.getappltxtlabel
                          (cus.pc_3_pc_appltxt_id,
                           vpc_lang_id
                          ) c_texte_pied_4_description,
             pcs.pc_functions.getappltxtlabel
                          (cus.pc_4_pc_appltxt_id,
                           vpc_lang_id
                          ) c_texte_pied_5_description,
             (SELECT ade1.des_description_summary
                FROM acs_description ade1
               WHERE ade1.acs_sub_set_id = acc1.acs_sub_set_id
                 AND ade1.pc_lang_id = vpc_lang_id) acs_sub_se,
             (SELECT ade2.des_description_summary
                FROM acs_description ade2
               WHERE ade2.acs_payment_method_id =
                                    pay.acs_payment_method_id
                 AND ade2.pc_lang_id = vpc_lang_id) acs_payment_met,
             (SELECT ade3.des_description_summary
                FROM acs_description ade3
               WHERE ade3.acs_vat_det_account_id =
                                   cus.acs_vat_det_account_id
                 AND ade3.pc_lang_id = vpc_lang_id) acs_vat_det_acc,
             (SELECT ade4.des_description_summary
                FROM acs_description ade4
               WHERE ade4.acs_accounting_id =
                                      aux.acs_invoice_coll_id
                 AND ade4.pc_lang_id = vpc_lang_id) acs_invoice_col,
             (SELECT ade5.des_description_summary
                FROM acs_description ade5
               WHERE ade5.acs_account_id = aux.acs_prep_coll_id
                 AND ade5.pc_lang_id = vpc_lang_id) acs_prep_col,
             (SELECT ade6.des_description_summary
                FROM acs_description ade6
               WHERE ade6.acs_account_id =
                               aux.acs_financial_account_id
                 AND ade6.pc_lang_id = vpc_lang_id) acs_financial_acc,
             NVL (cus.cus_no_rem_charge, 0) cus_no_rem_charge,
             NVL (cus.cus_no_moratorium_interest,
                  0
                 ) cus_no_moratorium_interest,
             NVL (cus.cus_tariff_by_set, 0) cus_tariff_by_set,
             thi.thi_custom_number
        FROM pac_person pe2,
             pac_person pe1,
             pac_third thi,
             acs_fin_acc_s_payment pay,
             acs_account acc1,
             pac_person per,
             pac_custom_partner cus,
             acs_description des,
             acs_account acc2,
             acs_auxiliary_account aux,
             acs_sub_set sub
       WHERE per.pac_person_id = cus.pac_custom_partner_id
         AND cus.acs_auxiliary_account_id = acc1.acs_account_id(+)
         AND cus.acs_fin_acc_s_payment_id = pay.acs_fin_acc_s_payment_id(+)
         AND cus.pac_custom_partner_id = thi.pac_third_id
         AND cus.pac_pac_third_1_id = pe1.pac_person_id(+)
         AND cus.pac_pac_third_2_id = pe2.pac_person_id(+)
         AND cus.acs_auxiliary_account_id = aux.acs_auxiliary_account_id(+)
         AND aux.acs_auxiliary_account_id = acc2.acs_account_id
         AND acc2.acs_account_id = des.acs_account_id
         AND acc2.acs_sub_set_id = sub.acs_sub_set_id
         AND sub.c_type_sub_set = 'AUX'
         AND (   (per.per_name >= parameter_0 AND per.per_name <= parameter_1
                 )
              OR (parameter_0 IS NULL AND parameter_1 IS NULL AND per.pac_person_id = parameter_8)
             )
         AND (   (    cus.a_datecre >= param_a_datecre_start
                  AND cus.a_datecre <= param_a_datecre_end
                 )
              OR param_a_datecre_start IS NULL
             )
         AND (   cus.a_idcre = param_a_idcre
              OR (    param_a_idcre IS NULL
                  AND (parameter_4 <> 0 OR parameter_3 <> '1')
                 )
             )
         AND (   (    cus.a_datemod >= param_a_datemod_start
                  AND cus.a_datemod <= param_a_datemod_end
                 )
              OR param_a_datemod_start IS NULL
             )
         AND (   cus.a_idmod = param_a_idmod
              OR (    param_a_idmod IS NULL
                  AND (parameter_4 <> 0 OR parameter_3 <> '2')
                 )
             )
         AND des.pc_lang_id = vpc_lang_id;
END rpt_pac_custom_form;
