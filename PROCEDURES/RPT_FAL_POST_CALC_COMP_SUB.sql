--------------------------------------------------------
--  DDL for Procedure RPT_FAL_POST_CALC_COMP_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_POST_CALC_COMP_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2
)
IS
/**
*Description Used for report FAL_LOT_POST_CALCULATION.RPT

*@created MZHU 12 Feb 2009
*@lastUpdate
*@public
*@param PARAMETER_0 :   FAL_LOT_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT lot.fal_lot_id, lot.lot_refcompl, lom.lom_seq,
             lom.lom_secondary_ref, lom.c_kind_com, lom.gco_good_id,
             lom.lom_full_req_qty, lom.lom_rejected_qty,
             lom.lom_exit_receipt, lom.lom_price, lom.lom_increase_cost,
             goo.goo_major_reference, goo.goo_number_of_decimal,
             pdt.pdt_stock_management,
             goo_out.goo_major_reference goo_major_reference_out,
             goo_out.goo_secondary_reference goo_secondary_reference_out,
             pdt_out.pdt_stock_management pdt_stock_management_out,
             OUT.out_qte, OUT.out_price
        FROM fal_job_program jop,
             fal_order ord,
             fal_lot lot,
             fal_lot_material_link lom,
             gco_good goo,
             gco_product pdt,
             fal_factory_out OUT,
             gco_good goo_out,
             gco_product pdt_out
       WHERE jop.fal_job_program_id = ord.fal_job_program_id(+)
         AND ord.fal_order_id = lot.fal_order_id(+)
         AND lot.fal_lot_id = lom.fal_lot_id(+)
         AND lom.gco_good_id = goo.gco_good_id
         AND goo.gco_good_id = pdt.gco_good_id(+)
         AND lom.fal_lot_id = OUT.fal_lot_id(+)
         AND lom.gco_good_id = OUT.gco_good_id(+)
         AND OUT.gco_good_id = goo_out.gco_good_id(+)
         AND goo_out.gco_good_id = pdt_out.gco_good_id(+)
         AND lot.c_lot_status = '5'
         AND lom.lom_increase_cost = 1
         AND lot.lot_refcompl = parameter_0;
END rpt_fal_post_calc_comp_sub;
