--------------------------------------------------------
--  DDL for Procedure RPT_ACT_CUSTOMER_EXTRACT2
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_CUSTOMER_EXTRACT2" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS

/**
* description used for report  ACT_CUSTOMER_EXTRACT2  (SI - rupture par no abonnement)

* @author PNA
* @lastupdate 12 Feb 2009
* @Update 4 feb 2010
* @public
* @param PROCPARAM_0    customer id         ACC_NUMBER (AUXILIARY_ACCOUNT)

*/
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);

   OPEN arefcursor FOR
      SELECT 1 union_number, det.act_det_payment_id det_det_id1,
             imf.act_det_payment_id imf_det_id1,
             imf.act_financial_imputation_id id1,
             imf2.act_financial_imputation_id id2, NULL id3,
             det2.act_det_payment_id det_payment_id2,
             acc.acc_number acc_number, pac.per_name per_name,
             pac.pac_person_id pac_person_id,
             DECODE
                 (SUBSTR (imp.par_document, -2),
                  '-X', (SELECT MAX (exp0.act_expiry_id)
                           FROM act_expiry exp0, act_part_imputation imp0
                          WHERE exp0.act_part_imputation_id =
                                                   imp0.act_part_imputation_id
                            AND imp0.par_document =
                                   SUBSTR (imp.par_document,
                                           0,
                                           LENGTH (imp.par_document) - 2
                                          )),
                  EXP.act_expiry_id
                 ) act_expiry_id_0,
             EXP.act_expiry_id act_expiry_id,
             det.act_part_imputation_id act_part_imputation_id,
             imp.act_part_imputation_id act_part_imputation_id_2,
             doc.doc_number doc_number, det.det_paied_lc det_paied_lc,
             imf.imf_amount_lc_d imf_amount_lc_d,
             imf.imf_amount_lc_c imf_amount_lc_c, det.det_diff_exchange,
             imf2.act_document_id act_document_id_2,
             doc2.doc_number doc_number_2, EXP.exp_amount_lc exp_amount_lc,
             imf2.imf_amount_lc_d imf_amount_lc_d_2,
             imf2.imf_amount_lc_c imf_amount_lc_c_2,
             det2.det_diff_exchange det_diff_exchange_2_invoice,
             imf2.imf_amount_lc_d - imf2.imf_amount_lc_c text_value,
             NULL doc_number_3, NULL imf_amount_lc_d_3,
             NULL imf_amount_lc_c_3, NULL imf_transation_date_3,
             NULL imf_description_3, curr3.currency currency_3,
             imf2.imf_transaction_date imf_transaction_date_2,
             imf2.imf_description imf_description_2,
             curr2.currency currency_2,
             imf.imf_transaction_date imf_transaction_date,
             imf.imf_description imf_description,
             acj.c_type_catalogue c_type_catalogue,
             acj.cat_description cat_description, curr.currency currency,
             adr.pc_lang_id, EXP.exp_adapted,
             (SELECT MAX (REM.rem_number)
                FROM act_reminder REM
               WHERE EXP.act_expiry_id = REM.act_expiry_id
                 AND REM.rem_number <> 0) rem_number,
             imp.par_blocked_document,
             imf.act_det_payment_id act_det_payment_id_1, pac.per_forename,
             pac.per_activity, pol.dpo_descr,
             imf2.imf_number2 imf_number2, adr.add_address1 add_address1,
             CASE
                WHEN adr.add_zipcode IS NULL
                   THEN adr.add_city
                ELSE adr.add_zipcode || ' ' || adr.add_city
             END add_zipcode_city,
             adr.add_city add_city,
             CASE
                WHEN country.pc_cntry_id = 1
                   THEN ' '
                ELSE UPPER (country.cntname)
             END cntname,
             imf.act_document_id act_document_id,
             jou.c_sub_set c_sub_set, acf.fin_collective fin_collective,
             imp.par_document par_document
        FROM act_det_payment det,
             act_det_payment det2,
             act_expiry EXP,
             act_part_imputation imp,
             act_financial_imputation imf,
             acj_catalogue_document acj,
             acs_financial_currency fcurr,
             pcs.pc_curr curr,
             act_document doc,
             act_financial_imputation imf2,
             acs_financial_currency fcurr2,
             acs_financial_currency fcurr3,
             pcs.pc_curr curr2,
             pcs.pc_curr curr3,
             acs_financial_account acf,
             act_document doc2,
             act_etat_journal jou,
             acs_account acc,
             pac_custom_partner par,
             pac_person pac,
             pac_address adr,
             dic_person_politness pol,
             pcs.pc_cntry country
       WHERE det.act_det_payment_id = imf.act_det_payment_id
         AND imf2.act_det_payment_id = det2.act_det_payment_id(+)
         AND (   det.det_paied_lc + det.det_discount_lc + det.DET_CHARGES_LC + det.DET_DEDUCTION_LC = imf.imf_amount_lc_c
              OR - (det.det_paied_lc + det.det_discount_lc + det.DET_CHARGES_LC + det.DET_DEDUCTION_LC) =
                                                           imf.imf_amount_lc_d
             )
         AND imf.act_document_id = doc.act_document_id
         AND doc.acj_catalogue_document_id = acj.acj_catalogue_document_id
         AND fcurr.fin_local_currency = '1'
         AND fcurr.pc_curr_id = curr.pc_curr_id(+)
         AND det.act_expiry_id(+) = EXP.act_expiry_id
         AND EXP.act_part_imputation_id = imp.act_part_imputation_id
         AND imp.act_part_imputation_id = imf2.act_part_imputation_id
         AND fcurr2.fin_local_currency = '1'
         AND fcurr2.pc_curr_id = curr2.pc_curr_id(+)
         AND fcurr3.fin_local_currency = '1'
         AND fcurr3.pc_curr_id = curr3.pc_curr_id(+)
         AND acf.fin_collective = 1
         AND imf2.acs_financial_account_id = acf.acs_financial_account_id
         AND doc2.act_document_id = imf2.act_document_id
         AND doc2.act_journal_id = jou.act_journal_id
         AND jou.c_sub_set = 'REC'
         AND imp.pac_custom_partner_id = pac.pac_person_id
         AND par.pac_custom_partner_id = pac.pac_person_id
         AND par.acs_auxiliary_account_id = acc.acs_account_id
         AND pac.pac_person_id = adr.pac_person_id
         AND adr.add_principal = 1
         AND det.det_diff_exchange = 0
         AND det2.act_det_payment_id IS NULL
         AND det.act_det_payment_id IS NOT NULL
         AND pac.pac_person_id = parameter_0
         and adr.pc_cntry_id = country.pc_cntry_id
         AND pac.dic_person_politness_id = pol.dic_person_politness_id(+)
      UNION
      SELECT 2 union_number, NULL det_det_id1, NULL imf_det_id1, NULL id1,
             imf2.act_financial_imputation_id id2, NULL id3,
             det2.act_det_payment_id det_payment_id2,
             acc.acc_number acc_number, pac.per_name per_name,
             pac.pac_person_id pac_person_id,
             DECODE
                (SUBSTR (imp2.par_document, -2),
                 '-X', (SELECT MAX (exp0.act_expiry_id)
                          FROM act_expiry exp0, act_part_imputation imp0
                         WHERE exp0.act_part_imputation_id =
                                                   imp0.act_part_imputation_id
                           AND imp0.par_document =
                                  SUBSTR (imp2.par_document,
                                          0,
                                          LENGTH (imp2.par_document) - 2
                                         )),
                 EXP.act_expiry_id
                ) act_expiry_id_0,
             EXP.act_expiry_id act_expiry_id,
             det.act_part_imputation_id act_part_imputation_id,
             imf2.act_document_id act_document_id_2, NULL doc_number,
             det.det_paied_lc det_paied_lc, NULL imf_amount_lc_d,
             NULL imf_amount_lc_c, det.det_diff_exchange,
             NULL act_part_imputation_id_2, doc2.doc_number doc_number_2,

             EXP.exp_amount_lc exp_amount_lc,
             imf2.imf_amount_lc_d imf_amount_lc_d_2,
             imf2.imf_amount_lc_c imf_amount_lc_c_2,
             NULL det_diff_exchange_2_invoice,
             imf2.imf_amount_lc_d - imf2.imf_amount_lc_c text_value,
             NULL doc_number_3, NULL imf_amount_lc_d_3,
             NULL imf_amount_lc_c_3, NULL imf_transation_date_3,
             NULL imf_description_3, curr3.currency currency_3,
             imf2.imf_transaction_date imf_transaction_date_2,
             imf2.imf_description imf_description_2,
             curr2.currency currency_2, NULL imf_transaction_date,
             NULL imf_description, NULL c_type_catalogue,
             NULL cat_description, NULL currency, adr.pc_lang_id,
             EXP.exp_adapted,
             (SELECT MAX (REM.rem_number)
                FROM act_reminder REM
               WHERE EXP.act_expiry_id = REM.act_expiry_id
                 AND REM.rem_number <> 0) rem_number,
             imp2.par_blocked_document, NULL act_det_payment_id_1,
             pac.per_forename,
             pac.per_activity, pol.dpo_descr,
             imf2.imf_number2 imf_number2,
             adr.add_address1 add_address1,
             CASE
                WHEN adr.add_zipcode IS NULL
                   THEN adr.add_city
                ELSE adr.add_zipcode || ' ' || adr.add_city
             END add_zipcode_city,
             adr.add_city add_city,
             CASE
                WHEN country.pc_cntry_id = 1
                   THEN ' '
                ELSE UPPER (country.cntname)
             END cntname,
             NULL act_document_id,
             jou.c_sub_set c_sub_set, acf.fin_collective fin_collective,
             imp2.par_document par_document
        FROM act_det_payment det,
             act_det_payment det2,
             act_expiry EXP,
             act_part_imputation imp2,
             act_financial_imputation imf2,
             acs_financial_currency fcurr2,
             pcs.pc_curr curr2,
             acs_financial_currency fcurr3,
             pcs.pc_curr curr3,
             acs_financial_account acf,
             act_document doc2,
             act_etat_journal jou,
             acs_account acc,
             pac_custom_partner par,
             pac_person pac,
             pac_address adr,
             dic_person_politness pol,
             pcs.pc_cntry country
       WHERE det.act_expiry_id(+) = EXP.act_expiry_id
         AND imf2.act_det_payment_id = det2.act_det_payment_id(+)
         AND EXP.act_part_imputation_id = imp2.act_part_imputation_id
         AND imp2.act_part_imputation_id = imf2.act_part_imputation_id
         AND fcurr2.fin_local_currency = '1'
         AND fcurr2.pc_curr_id = curr2.pc_curr_id(+)
         AND fcurr3.fin_local_currency = '1'
         AND fcurr3.pc_curr_id = curr3.pc_curr_id(+)
         AND acf.fin_collective = 1
         AND imf2.acs_financial_account_id = acf.acs_financial_account_id
         AND doc2.act_document_id = imf2.act_document_id
         AND doc2.act_journal_id = jou.act_journal_id
         AND jou.c_sub_set = 'REC'
         AND imp2.pac_custom_partner_id = pac.pac_person_id
         AND par.pac_custom_partner_id = pac.pac_person_id
         AND par.acs_auxiliary_account_id = acc.acs_account_id
         AND pac.pac_person_id = adr.pac_person_id
         AND adr.add_principal = 1
         AND NVL (det.det_paied_lc, 0) = 0
         AND EXP.exp_discount_lc = 0
         AND (det2.act_det_payment_id IS NULL)
         AND pac.pac_person_id = parameter_0
         and adr.pc_cntry_id = country.pc_cntry_id
         AND pac.dic_person_politness_id = pol.dic_person_politness_id(+)
      UNION
      SELECT 3 union_number, det.act_det_payment_id det_det_id1,
             imf.act_det_payment_id imf_det_id1,
             imf.act_financial_imputation_id id1,
             imf2.act_financial_imputation_id id2,
             imf3.act_financial_imputation_id id3,
             det2.act_det_payment_id det_payment_id2,
             acc.acc_number acc_number, pac.per_name per_name,
             pac.pac_person_id pac_person_id,
             DECODE
                 (SUBSTR (imp.par_document, -2),
                  '-X', (SELECT MAX (exp0.act_expiry_id)
                           FROM act_expiry exp0, act_part_imputation imp0
                          WHERE exp0.act_part_imputation_id =
                                                   imp0.act_part_imputation_id
                            AND imp0.par_document =
                                   SUBSTR (imp.par_document,
                                           0,
                                           LENGTH (imp.par_document) - 2
                                          )),
                  EXP.act_expiry_id
                 ) act_expiry_id_0,
             EXP.act_expiry_id act_expiry_id,
             det.act_part_imputation_id act_part_imputation_id,
             imp.act_part_imputation_id act_part_imputation_id_2,
             doc.doc_number doc_number, det.det_paied_lc det_paied_lc,
             imf.imf_amount_lc_d imf_amount_lc_d,
             imf.imf_amount_lc_c imf_amount_lc_c, det.det_diff_exchange,
             imf2.act_document_id act_document_id_2,
             doc2.doc_number doc_number_2, EXP.exp_amount_lc exp_amount_lc,
             imf2.imf_amount_lc_d imf_amount_lc_d_2,
             imf2.imf_amount_lc_c imf_amount_lc_c_2,
             NULL det_diff_exchange_2_invoice,
             imf2.imf_amount_lc_d - imf2.imf_amount_lc_c text_value,
             doc2.doc_number doc_number_3,
             imf3.imf_amount_lc_d imf_amount_lc_d_3,
             imf3.imf_amount_lc_c imf_amount_lc_c_3,
             imf3.imf_transaction_date imf_transation_date_3,
             imf3.imf_description imf_description_3,
             curr3.currency currency_3,
             imf2.imf_transaction_date imf_transaction_date_2,
             imf2.imf_description imf_description_2,
             curr2.currency currency_2,
             imf.imf_transaction_date imf_transaction_date,
             imf.imf_description imf_description,
             acj.c_type_catalogue c_type_catalogue,
             acj.cat_description cat_description, curr.currency currency,
             adr.pc_lang_id, EXP.exp_adapted,
             (SELECT MAX (REM.rem_number)
                FROM act_reminder REM
               WHERE EXP.act_expiry_id = REM.act_expiry_id
                 AND REM.rem_number <> 0) rem_number,
             imp.par_blocked_document,
             imf.act_det_payment_id act_det_payment_id_1, pac.per_forename,
             pac.per_activity, pol.dpo_descr,
             imf2.imf_number2 imf_number2, adr.add_address1 add_address1,
             CASE
                WHEN adr.add_zipcode IS NULL
                   THEN adr.add_city
                ELSE adr.add_zipcode || ' ' || adr.add_city
             END add_zipcode_city,
             adr.add_city add_city,
             CASE
                WHEN country.pc_cntry_id = 1
                   THEN ' '
                ELSE UPPER (country.cntname)
             END cntname,
             imf.act_document_id act_document_id,
             jou.c_sub_set c_sub_set, acf.fin_collective fin_collective,
             imp.par_document par_document
        FROM act_det_payment det,
             act_det_payment det2,
             act_expiry EXP,
             act_part_imputation imp,
             act_financial_imputation imf,
             acj_catalogue_document acj,
             act_financial_imputation imf3,
             act_document doc3,
             acs_financial_currency fcurr,
             pcs.pc_curr curr,
             act_document doc,
             act_financial_imputation imf2,
             acs_financial_currency fcurr2,
             pcs.pc_curr curr2,
             acs_financial_currency fcurr3,
             pcs.pc_curr curr3,
             acs_financial_account acf,
             act_document doc2,
             act_etat_journal jou,
             acs_account acc,
             pac_custom_partner par,
             pac_person pac,
             pac_address adr,
             dic_person_politness pol,
             pcs.pc_cntry country
       WHERE det.act_det_payment_id = imf.act_det_payment_id
         AND imf2.act_det_payment_id = det2.act_det_payment_id(+)
         AND (   det.det_paied_lc + det.det_discount_lc = imf.imf_amount_lc_c
              OR - (det.det_paied_lc + det.det_discount_lc) =
                                                           imf.imf_amount_lc_d
             )
         AND imf.act_document_id = doc.act_document_id
         AND doc.acj_catalogue_document_id = acj.acj_catalogue_document_id
         AND fcurr.fin_local_currency = '1'
         AND fcurr.pc_curr_id = curr.pc_curr_id(+)
         AND det.act_expiry_id(+) = EXP.act_expiry_id
         AND det2.act_det_payment_id IS NULL
         AND EXP.act_part_imputation_id = imp.act_part_imputation_id
         AND imp.act_part_imputation_id = imf2.act_part_imputation_id
         AND fcurr2.fin_local_currency = '1'
         AND fcurr2.pc_curr_id = curr2.pc_curr_id(+)
         AND fcurr3.fin_local_currency = '1'
         AND fcurr3.pc_curr_id = curr3.pc_curr_id(+)
         AND acf.fin_collective = 1
         AND imf2.acs_financial_account_id = acf.acs_financial_account_id
         AND doc2.act_document_id = imf2.act_document_id
         AND doc2.act_journal_id = jou.act_journal_id
         AND jou.c_sub_set = 'REC'
         AND imp.pac_custom_partner_id = pac.pac_person_id
         AND par.pac_custom_partner_id = pac.pac_person_id
         AND par.acs_auxiliary_account_id = acc.acs_account_id
         AND pac.pac_person_id = adr.pac_person_id
         AND adr.add_principal = 1
         AND imf3.acs_financial_account_id = imf.acs_financial_account_id
         AND imf.act_det_payment_id = imf3.act_det_payment_id
         AND imf3.c_genre_transaction = 4
         AND imf3.act_document_id = doc3.act_document_id
         AND det.act_det_payment_id IS NOT NULL
         AND pac.pac_person_id = parameter_0
         and adr.pc_cntry_id = country.pc_cntry_id
         AND pac.dic_person_politness_id = pol.dic_person_politness_id(+);

END rpt_act_customer_extract2;
