--------------------------------------------------------
--  DDL for Procedure RPT_DOC_GAUGE_FLOW
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_GAUGE_FLOW" (AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, PROCUSER_LANID in PCS.PC_LANG.LANID%type)
is
  VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
begin
  PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
  VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

  open AREFCURSOR for
    select 'DISCHARGE' code
         , dgf.gaf_describe
         , dgf.gaf_version
         , c_gaf_flow_status
         , gaf_comment
         , gad.gad_seq
         , des.gad_describe src
         , gad.gad_seq seq_dst
         , des_dst.gad_describe dst
         , gar_quantity_exceed
         , gar_good_changing
         , gar_partner_changing
         , gar_extourne_mvt
         , gar_balance_parent
         , gar_transfert_price
         , gar_transfert_quantity
         , gar_init_price_mvt
         , gar_init_qty_mvt
         , gar_part_discharge
         , gar_transfert_stock
         , gar_transfert_descr
         , gar_transfert_remise_taxe
         , gar_init_cost_price
         , gar_transfer_mvmt_swap
         , gar_invert_amount
         , gar_transfert_record
         , gar_transfert_represent
         , gar_transfert_free_data
         , gar_transfert_price_mvt
         , gar_transfert_precious_mat
         , null gac_transfert_price
         , null gac_transfert_quantity
         , null gac_init_price_mvt
         , null gac_init_qty_mvt
         , null gac_bond
         , null gac_part_copy
         , null gac_transfert_stock
         , null gac_transfert_descr
         , null gac_transfert_remise_taxe
         , null gac_transfert_record
         , null gac_transfert_represent
         , null gac_transfert_free_data
         , null gac_transfert_price_mvt
         , null gac_init_cost_price
         , null gac_transfert_charact
         , null gac_transfert_precious_mat
         , gau.doc_gauge_id gauge_src_id
         , gau_dst.doc_gauge_id gauge_dst_id
         , gar.doc_gauge_receipt_id
         , gad.doc_gauge_flow_docum_id flow_docum_src_id
         , dgf.doc_gauge_flow_id
      from doc_gauge gau
         , doc_gauge gau_dst
         , doc_gauge_receipt gar
         , doc_gauge_flow_docum gad
         , doc_gauge_flow dgf
         , doc_gauge_description des
         , doc_gauge_description des_dst
     where gad.doc_gauge_id = gau.doc_gauge_id
       and gar.doc_gauge_flow_docum_id = gad.doc_gauge_flow_docum_id
       and gau_dst.doc_gauge_id = gar.doc_doc_gauge_id
       and gad.doc_gauge_flow_id = dgf.doc_gauge_flow_id
       and gau.doc_gauge_id = des.doc_gauge_id(+)
       and des.pc_lang_id(+) = pcs.pc_public.getuserlangid
       and gau_dst.doc_gauge_id = des_dst.doc_gauge_id(+)
       and des_dst.pc_lang_id(+) = VPC_LANG_ID
    union all
    select 'COPY' code
         , dgf.gaf_describe
         , gaf_version
         , c_gaf_flow_status
         , gaf_comment
         , gad.gad_seq
         , des.gad_describe src
         , gad.gad_seq seq_dst
         , des_dst.gad_describe dst
         , null gar_quantity_exceed
         , null gar_good_changing
         , null gar_partner_changing
         , null gar_extourne_mvt
         , null gar_balance_parent
         , null gar_transfert_price
         , null gar_transfert_quantity
         , null gar_init_price_mvt
         , null gar_init_qty_mvt
         , null gar_part_discharge
         , null gar_transfert_stock
         , null gar_transfert_descr
         , null gar_transfert_remise_taxe
         , null gar_init_cost_price
         , null gar_transfer_mvmt_swap
         , null gar_invert_amount
         , null gar_transfert_record
         , null gar_transfert_represent
         , null gar_transfert_free_data
         , null gar_transfert_price_mvt
         , null gar_transfert_precious_mat
         , gac_transfert_price
         , gac_transfert_quantity
         , gac_init_price_mvt
         , gac_init_qty_mvt
         , gac_bond
         , gac_part_copy
         , gac_transfert_stock
         , gac_transfert_descr
         , gac_transfert_remise_taxe
         , gac_transfert_record
         , gac_transfert_represent
         , gac_transfert_free_data
         , gac_transfert_price_mvt
         , gac_init_cost_price
         , gac_transfert_charact
         , gac_transfert_precious_mat
         , gau.doc_gauge_id
         , gau_dst.doc_gauge_id
         , gar.doc_gauge_copy_id
         , gad.doc_gauge_flow_docum_id
         , dgf.doc_gauge_flow_id
      from doc_gauge gau
         , doc_gauge gau_dst
         , doc_gauge_copy gar
         , doc_gauge_flow_docum gad
         , doc_gauge_flow dgf
         , doc_gauge_description des
         , doc_gauge_description des_dst
     where gad.doc_gauge_id = gau.doc_gauge_id
       and gar.doc_gauge_flow_docum_id = gad.doc_gauge_flow_docum_id
       and gau_dst.doc_gauge_id = gar.doc_doc_gauge_id
       and gad.doc_gauge_flow_id = dgf.doc_gauge_flow_id
       and gau.doc_gauge_id = des.doc_gauge_id(+)
       and des.pc_lang_id(+) = pcs.pc_public.getuserlangid
       and gau_dst.doc_gauge_id = des_dst.doc_gauge_id(+)
       and des_dst.pc_lang_id(+) = VPC_LANG_ID;
end RPT_DOC_GAUGE_FLOW;
