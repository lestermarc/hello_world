--------------------------------------------------------
--  DDL for Procedure RPT_DOC_GAU_FLOW_DATA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_GAU_FLOW_DATA" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
* Description
*    STORED PROCEDURE USED FOR THE REPORT DOC_GAUGE_FLOW_DATA

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR AWU 1 JAN 2009
* @LASTUPDATE 20 FEB 2009
* @VERSION
* @PUBLIC
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT 'DISCHARGE' code, dgf.gaf_describe, dgf.gaf_version,
             c_gaf_flow_status, gaf_comment, gad.gad_seq,
             des.gad_describe src, gad.gad_seq seq_dst,
             des_dst.gad_describe dst, gar_quantity_exceed,
             gar_good_changing, gar_partner_changing, gar_extourne_mvt,
             gar_balance_parent, gar_transfert_price, gar_transfert_quantity,
             gar_init_price_mvt, gar_init_qty_mvt, gar_part_discharge,
             gar_transfert_stock, gar_transfert_descr,
             gar_transfert_remise_taxe, gar_init_cost_price,
             gar_transfer_mvmt_swap, gar_invert_amount, gar_transfert_record,
             gar_transfert_represent, gar_transfert_free_data,
             gar_transfert_price_mvt, gar_transfert_precious_mat,
             NULL gac_transfert_price, NULL gac_transfert_quantity,
             NULL gac_init_price_mvt, NULL gac_init_qty_mvt, NULL gac_bond,
             NULL gac_part_copy, NULL gac_transfert_stock,
             NULL gac_transfert_descr, NULL gac_transfert_remise_taxe,
             NULL gac_transfert_record, NULL gac_transfert_represent,
             NULL gac_transfert_free_data, NULL gac_transfert_price_mvt,
             NULL gac_init_cost_price, NULL gac_transfert_charact,
             NULL gac_transfert_precious_mat, gau.doc_gauge_id gauge_src_id,
             gau_dst.doc_gauge_id gauge_dst_id, gar.doc_gauge_receipt_id,
             gad.doc_gauge_flow_docum_id flow_docum_src_id,
             dgf.doc_gauge_flow_id
        FROM doc_gauge gau,
             doc_gauge gau_dst,
             doc_gauge_receipt gar,
             doc_gauge_flow_docum gad,
             doc_gauge_flow dgf,
             doc_gauge_description des,
             doc_gauge_description des_dst
       WHERE gad.doc_gauge_id = gau.doc_gauge_id
         AND gar.doc_gauge_flow_docum_id = gad.doc_gauge_flow_docum_id
         AND gau_dst.doc_gauge_id = gar.doc_doc_gauge_id
         AND gad.doc_gauge_flow_id = dgf.doc_gauge_flow_id
         AND gau.doc_gauge_id = des.doc_gauge_id(+)
         AND des.pc_lang_id(+) = pcs.pc_public.getuserlangid
         AND gau_dst.doc_gauge_id = des_dst.doc_gauge_id(+)
         AND des_dst.pc_lang_id(+) = vpc_lang_id
      UNION ALL
      SELECT 'COPY' code, dgf.gaf_describe, gaf_version, c_gaf_flow_status,
             gaf_comment, gad.gad_seq, des.gad_describe src,
             gad.gad_seq seq_dst, des_dst.gad_describe dst,
             NULL gar_quantity_exceed, NULL gar_good_changing,
             NULL gar_partner_changing, NULL gar_extourne_mvt,
             NULL gar_balance_parent, NULL gar_transfert_price,
             NULL gar_transfert_quantity, NULL gar_init_price_mvt,
             NULL gar_init_qty_mvt, NULL gar_part_discharge,
             NULL gar_transfert_stock, NULL gar_transfert_descr,
             NULL gar_transfert_remise_taxe, NULL gar_init_cost_price,
             NULL gar_transfer_mvmt_swap, NULL gar_invert_amount,
             NULL gar_transfert_record, NULL gar_transfert_represent,
             NULL gar_transfert_free_data, NULL gar_transfert_price_mvt,
             NULL gar_transfert_precious_mat, gac_transfert_price,
             gac_transfert_quantity, gac_init_price_mvt, gac_init_qty_mvt,
             gac_bond, gac_part_copy, gac_transfert_stock,
             gac_transfert_descr, gac_transfert_remise_taxe,
             gac_transfert_record, gac_transfert_represent,
             gac_transfert_free_data, gac_transfert_price_mvt,
             gac_init_cost_price, gac_transfert_charact,
             gac_transfert_precious_mat, gau.doc_gauge_id,
             gau_dst.doc_gauge_id, gar.doc_gauge_copy_id,
             gad.doc_gauge_flow_docum_id, dgf.doc_gauge_flow_id
        FROM doc_gauge gau,
             doc_gauge gau_dst,
             doc_gauge_copy gar,
             doc_gauge_flow_docum gad,
             doc_gauge_flow dgf,
             doc_gauge_description des,
             doc_gauge_description des_dst
       WHERE gad.doc_gauge_id = gau.doc_gauge_id
         AND gar.doc_gauge_flow_docum_id = gad.doc_gauge_flow_docum_id
         AND gau_dst.doc_gauge_id = gar.doc_doc_gauge_id
         AND gad.doc_gauge_flow_id = dgf.doc_gauge_flow_id
         AND gau.doc_gauge_id = des.doc_gauge_id(+)
         AND des.pc_lang_id(+) = pcs.pc_public.getuserlangid
         AND gau_dst.doc_gauge_id = des_dst.doc_gauge_id(+)
         AND des_dst.pc_lang_id(+) = vpc_lang_id;
END rpt_doc_gau_flow_data;
