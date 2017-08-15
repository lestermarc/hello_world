--------------------------------------------------------
--  DDL for Procedure RPT_DOC_BVR_3
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_BVR_3" (
   arefcursor          IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0         IN       VARCHAR2,
   proccompany_owner   IN       pcs.pc_scrip.scrdbowner%TYPE,
   proccompany_name    IN       pcs.pc_comp.com_name%TYPE
)
IS
/*
* Description stored procedure used for the report DOC_BVR_3

* @created MZHU 5 DEC 2008
* @lastupdate VHA 26 JUNE 2013
* @public
* @param PARAMETER_0 DMT_NUMBER
*/

vcom_adr                    VARCHAR2 (4000) := null;
vcomp_id                    pcs.pc_comp.pc_comp_id%TYPE := null;

BEGIN

   if (proccompany_name is not null) then
      SELECT com.com_adr || CHR (13) || com.com_zip || ' - ' || com.com_city, pc_comp_id
         INTO vcom_adr, vcomp_id
         FROM pcs.pc_comp com
        WHERE com.com_name = proccompany_name;
    end if;

    OPEN arefcursor FOR
           SELECT dmt.doc_document_id, pad.doc_payment_date_id, lan.pc_lang_id,
             (SELECT des.gad_describe
                FROM doc_gauge_description des
               WHERE des.doc_gauge_id = dmt.doc_gauge_id
                 AND des.pc_lang_id = DMT.PC_LANG_ID ) gad_describe,
             GAU.GAU_DESCRIBE,
             vcom_adr com_adr,
             lan.lanname, lan.lanid, dmt.dmt_number, dmt.dmt_title_text,
             dmt.dmt_date_document, per.per_name, per.per_forename,
             per.per_activity, dmt.dmt_address3 dmt_address1,
             dmt.dmt_postcode3 dmt_postcode1, dmt.dmt_town3 dmt_town1,
             dmt.dmt_format_city3 dmt_format_city1,
             foo.c_bvr_generation_method, foo.foo_generate_bvr_number,
             pad.pad_band_number, pad.pad_payment_date,
             pad.pad_discount_amount, pad.pad_bvr_reference_num,
             pad.pad_bvr_coding_line, pad.pad_net_date_amount,
             pcs.pc_functions.getappltxtlabel (pco.pc_appltxt_id,
                                               lan.pc_lang_id
                                              ) apt_label,
             pme.pme_sbvr, ban.ban_name1, ban.ban_zip, ban.ban_city,
             (SELECT com.com_logo_large
                FROM pcs.pc_comp com
               WHERE com.pc_comp_id = vcomp_id
                 ) com_logo_large,
             (   DECODE (NVL (dmt.dmt_forename1, per.per_forename),
                         NULL, '',
                         NVL (dmt.dmt_forename1, per.per_forename) || CHR (13)
                        )
              || DECODE (NVL (dmt.dmt_activity1, per.per_activity),
                         NULL, '',
                         NVL (dmt.dmt_activity1, per.per_activity) || CHR (13)
                        )
              || DECODE (dmt.dmt_care_of1,
                         NULL, '',
                         dmt.dmt_care_of1 || CHR (13)
                        )
              || DECODE (dmt.dmt_address1,
                         NULL, '',
                         dmt.dmt_address1 || CHR (13)
                        )
              || DECODE (dmt.dmt_format_city1,
                         NULL, '',
                         dmt.dmt_format_city1
                        )
             ) add_1
        FROM doc_document dmt,
             doc_foot foo,
             pac_person per,
             pac_payment_condition pco,
             doc_payment_date pad,
             acs_fin_acc_s_payment asp,
             acs_payment_method pme,
             pcs.pc_lang lan,
             acs_financial_account fin,
             pcs.pc_bank ban,
             doc_gauge gau
       WHERE dmt.doc_document_id = foo.doc_document_id(+)
         AND dmt.pc_lang_id = lan.pc_lang_id
         AND dmt.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         AND dmt.pac_third_aci_id = per.pac_person_id(+)
         AND dmt.pac_payment_condition_id = pco.pac_payment_condition_id(+)
         AND foo.doc_foot_id = pad.doc_foot_id
         AND dmt.acs_fin_acc_s_payment_id = asp.acs_fin_acc_s_payment_id(+)
         AND asp.acs_payment_method_id = pme.acs_payment_method_id(+)
         AND asp.acs_financial_account_id = fin.acs_financial_account_id(+)
         AND fin.pc_bank_id = ban.pc_bank_id(+)
         AND dmt.dmt_number = parameter_0;

END rpt_doc_bvr_3;
