--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ORDER_DET_HIS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ORDER_DET_HIS" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**
*Description Used for report FAL_ORDER_DETAILED_BATCH_HIST

* @created AWU NOV.2008
*@ lastUpdate MZHU 22 Feb 2009
* @public
* @param parameter_0: FAL_HIST_LOT_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT fjp.jop_reference, flo.fal_lot_hist_id fal_lot_id,
             flo.gco_good_id gco_good_id_lot, flo.lot_ref, flo.lot_asked_qty,
             flo.lot_reject_plan_qty, flo.lot_total_qty,
             flo.lot_plan_begin_dte, flo.lot_plan_end_dte,
             flo.lot_plan_lead_time, flo.lot_plan_number,
             flo.fal_schedule_plan_id, flo.stm_location_id,
             flo.pps_operation_procedure_id, flo.stm_stock_id,
             fod.fal_order_hist_id fal_order_hist_id,
             fod.gco_good_id gco_good_id_ord, fod.ord_ref,
             fod.ord_oshort_descr, fod.ord_released_qty, fod.ord_opened_qty,
             fod.ord_still_to_release_qty, fod.ord_planned_qty,
             fod.ord_end_date, fod.ord_pshort_descr,
             (SELECT COUNT (*)
                FROM fal_lot_mat_link_hist fml
               WHERE fml.fal_lot_hist_id = flo.fal_lot_hist_id) mat_record,
             (SELECT COUNT (*)
                FROM fal_task_link_hist ftl
               WHERE ftl.fal_lot_hist_id = flo.fal_lot_hist_id) task_record,
             flo.lot_refcompl
        FROM fal_order_hist fod, fal_lot_hist flo, fal_job_program_hist fjp
       WHERE fod.fal_order_hist_id = flo.fal_order_hist_id(+)
         AND fod.fal_job_program_hist_id = fjp.fal_job_program_hist_id(+)
         AND fod.fal_order_hist_id >= 1
         AND flo.fal_lot_hist_id = parameter_0;
END rpt_fal_order_det_his;
