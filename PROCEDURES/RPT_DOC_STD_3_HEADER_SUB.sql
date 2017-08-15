--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_HEADER_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_HEADER_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       doc_document.dmt_number%TYPE
)
IS
/**
*Description - Used for report DOC_STD_3

*@created MZHU 17 MAY 2009
*@lastUpdate   4 MAR 2009
*@public
*@param PARAMETER_0:  DMT_NUMBER
*/
BEGIN
   OPEN arefcursor FOR
      SELECT dmt.dmt_number dmt_number, dmt.dmt_date_document,DMT.DMT_DATE_FALLING_DUE,
             dmt.dmt_partner_number, dmt.dmt_partner_reference,
             dmt.dmt_date_partner_document, dmt.dmt_reference,
             dmt.c_incoterms, rep.rep_descr, rec.rco_title, thi.thi_no_intra,
             thi.thi_no_tva,
             pac_functions.getsendconddescr
                                     (psc.pac_sending_condition_id,
                                      dmt.pc_lang_id
                                     ) sen_descr,
             per_sen.per_name sen_per_name,
             per_sen.per_forename sen_per_forename,
             per_sen.per_activity sen_per_activity,
             adr_sen.add_address1 sen_add_address1,
             adr_sen.add_format sen_add_format,
             acs_function.getpaymethdescr
                                   (apm.acs_payment_method_id,
                                    dmt.pc_lang_id
                                   ) pay_meth_descr,
             pcs.pc_functions.getappltxtdescr (pmt.pc_appltxt_id,
                                               dmt.pc_lang_id
                                              ) cond_descr,
             cur.currency, per.per_key1, gst.c_gauge_title,
             gau.c_admin_domain, dpd.pad_payment_date,
             dpd.pad_net_date_amount, dpd.pad_band_number,
             dpd.pad_date_amount, dpd.pad_discount_amount
        FROM pcs.pc_lang lang,
             acs_fin_acc_s_payment afa,
             acs_payment_method apm,
             doc_record rec,
             doc_payment_date dpd,
             doc_foot foo,
             pac_sending_condition psc,
             pac_payment_condition pmt,
             acs_financial_currency afc,
             pac_address adr,
             pac_representative rep,
             pac_address adr_sen,
             pac_person per_sen,
             pac_person per,
             pac_third thi,
             pcs.pc_curr cur,
             doc_gauge gau,
             doc_gauge_structured gst,
             doc_document dmt
       WHERE dmt.doc_gauge_id = gau.doc_gauge_id
         AND gau.doc_gauge_id = gst.doc_gauge_id
         AND dmt.pc_lang_id = lang.pc_lang_id
         AND foo.doc_foot_id = dpd.doc_foot_id(+)
         AND dmt.acs_fin_acc_s_payment_id = afa.acs_fin_acc_s_payment_id(+)
         AND afa.acs_payment_method_id = apm.acs_payment_method_id(+)
         AND dmt.pac_representative_id = rep.pac_representative_id(+)
         AND dmt.doc_document_id = foo.doc_document_id(+)
         AND dmt.doc_record_id = rec.doc_record_id(+)
         AND dmt.pac_sending_condition_id = psc.pac_sending_condition_id(+)
         AND psc.pac_address_id = adr_sen.pac_address_id(+)
         AND adr_sen.pac_person_id = per_sen.pac_person_id(+)
         AND dmt.pac_third_id = thi.pac_third_id(+)
         AND dmt.pac_address_id = adr.pac_address_id(+)
         AND adr.pac_person_id = per.pac_person_id(+)
         AND dmt.acs_financial_currency_id = afc.acs_financial_currency_id(+)
         AND afc.pc_curr_id = cur.pc_curr_id(+)
         AND dmt.pac_payment_condition_id = pmt.pac_payment_condition_id(+)
         AND dmt.dmt_number = parameter_0;
END rpt_doc_std_3_header_sub;
