--------------------------------------------------------
--  DDL for Procedure RPT_PAC_SUPPLIER_FORM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_SUPPLIER_FORM" (
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
 Description - used for the report PAC_SUPPLIER_FORM

 @author AWU 1 Dec 2008
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_0  Client de : (PER_NAME)
 @PARAM  parameter_1  Client à : (PER_NAME)
 @PARAM  parameter_3  Sélection: 0 = Aucune, 1 = Création, 2 = Modification
 @PARAM  parameter_4  Date du: (Création ou modification) YYYYMMDD
 @PARAM  parameter_5  Date au: (Création ou modification) YYYYMMDD
 @PARAM  parameter_6  Initiales utilisateur: (Création ou modification)
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
             sup.pac_supplier_partner_id, sup.c_partner_category,
             acc2.acc_number, sup.pac_payment_condition_id,
             sup.c_partner_status, sup.c_status_settlement,
             sup.dic_type_submission_id, thi.thi_no_tva, thi.thi_no_intra,
             sup.c_remainder_launching, sup.cre_without_remind_date,
             sup.pac_remainder_category_id, sup.dic_type_partner_f_id,
             sup.cre_free_zone1, sup.cre_free_zone2, sup.cre_free_zone3,
             sup.cre_free_zone4, sup.cre_free_zone5, sup.dic_statistic_f1_id,
             sup.dic_statistic_f2_id, sup.dic_statistic_f3_id,
             sup.dic_statistic_f4_id, sup.dic_statistic_f5_id,
             pe1.per_name per_name_1, pe1.per_forename per_forename_1,
             pe2.per_name per_name_2, pe2.per_forename per_forename_2,
             sup.dic_ptc_third_group_id, sup.dic_tariff_id,
             sup.pac_sending_condition_id, sup.pac_calendar_type_id,
             sup.dic_complementary_data_id, sup.dic_pic_group_id,
             sup.c_incoterms, sup.cre_incoterms_place, sup.cre_supply_delay,
             sup.cre_manufacturer, sup.c_delivery_typ, sup.c_type_edi,
             sup.cre_data_export, sup.cre_customer_number, sup.cre_ean_number,
             sup.cre_sup_copy1, sup.cre_sup_copy2, sup.cre_sup_copy3,
             sup.cre_sup_copy4, sup.cre_sup_copy5, sup.cre_sup_copy6,
             sup.cre_sup_copy7, sup.cre_sup_copy8, sup.cre_sup_copy9,
             sup.cre_sup_copy10, thi.dic_third_activity_id,
             thi.dic_third_area_id, thi.dic_juridical_status_id,
             thi.dic_citi_code_id, thi.thi_no_siren, thi.thi_no_siret,
             thi.pac_pac_person_id, sup.dic_priority_payment_id,
             sup.dic_center_payment_id, sup.dic_level_priority_id,
             sup.cre_blocked, sup.pc_appltxt_id, sup.pc__pc_appltxt_id,
             sup.pc_2_pc_appltxt_id, sup.pc_3_pc_appltxt_id,
             sup.pc_4_pc_appltxt_id, sup.cre_day_capacity,
             aux.acs_auxiliary_account_id, aux.acs_prep_coll_id,
             aux.acs_invoice_coll_id, aux.acs_financial_account_id,
             acc2.acc_detail_printing, acc2.acc_blocked, acc2.acc_interest,
             acc2.acc_valid_since, acc2.acc_valid_to,
             des.des_description_summary,
             pcs.pc_functions.getappltxtlabel
                               (sup.pc_appltxt_id,
                                vpc_lang_id
                               ) c_texte_pied_1_description,
             pcs.pc_functions.getappltxtlabel
                           (sup.pc__pc_appltxt_id,
                            vpc_lang_id
                           ) c_texte_pied_2_description,
             pcs.pc_functions.getappltxtlabel
                          (sup.pc_2_pc_appltxt_id,
                           vpc_lang_id
                          ) c_texte_pied_3_description,
             pcs.pc_functions.getappltxtlabel
                          (sup.pc_3_pc_appltxt_id,
                           vpc_lang_id
                          ) c_texte_pied_4_description,
             pcs.pc_functions.getappltxtlabel
                          (sup.pc_4_pc_appltxt_id,
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
                                   sup.acs_vat_det_account_id
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
             sup.cre_tariff_by_set, thi.thi_custom_number
        FROM pac_person pe2,
             pac_person pe1,
             pac_third thi,
             acs_fin_acc_s_payment pay,
             acs_account acc1,
             pac_person per,
             pac_supplier_partner sup,
             acs_description des,
             acs_account acc2,
             acs_auxiliary_account aux,
             acs_sub_set sub
       WHERE per.pac_person_id = sup.pac_supplier_partner_id
         AND sup.acs_auxiliary_account_id = acc1.acs_account_id
         AND sup.acs_fin_acc_s_payment_id = pay.acs_fin_acc_s_payment_id(+)
         AND sup.pac_supplier_partner_id = thi.pac_third_id
         AND sup.pac_pac_third_1_id = pe1.pac_person_id(+)
         AND sup.pac_pac_third_2_id = pe2.pac_person_id(+)
         AND sup.acs_auxiliary_account_id = aux.acs_auxiliary_account_id(+)
         AND aux.acs_auxiliary_account_id = acc2.acs_account_id
         AND acc2.acs_account_id = des.acs_account_id
         AND acc2.acs_sub_set_id = sub.acs_sub_set_id
         AND sub.c_type_sub_set = 'AUX'
         AND (   (per.per_name >= parameter_0 AND per.per_name <= parameter_1
                 )
              OR (parameter_0 IS NULL AND parameter_1 IS NULL AND per.pac_person_id = parameter_8)
             )
         AND (   (    sup.a_datecre >= param_a_datecre_start
                  AND sup.a_datecre <= param_a_datecre_end
                 )
              OR param_a_datecre_start IS NULL
             )
         AND (   sup.a_idcre = param_a_idcre
              OR (    param_a_idcre IS NULL
                  AND (parameter_4 <> 0 OR parameter_3 <> '1')
                 )
             )
         AND (   (    sup.a_datemod >= param_a_datemod_start
                  AND sup.a_datemod <= param_a_datemod_end
                 )
              OR param_a_datemod_start IS NULL
             )
         AND (   sup.a_idmod = param_a_idmod
              OR (    param_a_idmod IS NULL
                  AND (parameter_4 <> 0 OR parameter_3 <> '2')
                 )
             )
         AND des.pc_lang_id = vpc_lang_id;
END rpt_pac_supplier_form;
