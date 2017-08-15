--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ORDER_DET_BAT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ORDER_DET_BAT" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2
)
IS
/**
*Description - used for report FAL_ORDER_DETAILED_BATCH
*@created AWU 01 NOV 2008
*@lastUpdate MZH 10 May 2010, CLIU 10 Aug. 2010
*@public
*@param parameter_0: FAL_LOT_ID  -> INSTR necessary when report is called for > 1 fal_lot_id .
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT flo.lot_refcompl
             ,flo.c_lot_status
             ,flo.fal_lot_id
             ,flo.lot_ref
             ,flo.gco_good_id gco_good_id_lot
             ,flo.lot_asked_qty
             ,flo.lot_reject_plan_qty
             ,flo.lot_total_qty
             ,flo.lot_plan_begin_dte
             ,flo.lot_plan_end_dte
             ,flo.lot_plan_lead_time
             ,flo.lot_plan_number
             ,flo.fal_schedule_plan_id
             ,flo.pps_operation_procedure_id
             ,flo.stm_stock_id
             ,flo.stm_location_id
             ,flo.lot_plan_version
             ,flo.lot_pshort_descr -- short description of the product.
             ,flo.lot_ptext        -- long description of the product.
             ,flo.lot_pfree_text   -- free description of the product.
             ,flo.lot_short_descr  -- short description of the BATCH.
             ,flo.lot_long_descr   -- long description of the BATCH.
             ,flo.lot_free_descr   -- free description of the BATCH.
             ,flo.lot_free_num1
             ,flo.lot_free_num2
             ,flo.dic_lot_code2_id
             ,flo.dic_lot_code3_id
             ,flo.doc_record_id
             ,gco.goo_major_reference
             ,gco.dic_unit_of_measure_id
             ,gco.goo_number_of_decimal
             ,pps.gco_good_id gco_good_id_pps
             ,fod.fal_order_id, fod.gco_good_id gco_good_id_ord, fod.ord_ref,
             fod.ord_oshort_descr, fod.ord_released_qty, fod.ord_opened_qty,
             fod.ord_still_to_release_qty, fod.ord_planned_qty,
             fod.ord_end_date, fod.ord_pshort_descr,
             fjp.jop_reference,
             (SELECT COUNT (*)
                FROM fal_lot_material_link fml
               WHERE fml.fal_lot_id = flo.fal_lot_id) mat_record,
             (SELECT COUNT (*)
                FROM fal_task_link ftl
               WHERE ftl.fal_lot_id = flo.fal_lot_id) task_record,
             (SELECT COUNT (*)
                FROM FAL_LOT_DETAIL FAD
               WHERE FAD.FAL_LOT_ID = FLO.FAL_LOT_ID) DETAIL_RECORD
        FROM fal_order fod,
             fal_lot flo,
             fal_job_program fjp,
             gco_good gco,
             pps_nomenclature pps
       WHERE fod.fal_order_id = flo.fal_order_id
         and instr(',' || parameter_0 ||',' , ',' || flo.fal_lot_id ||',') > 0
         and fod.fal_job_program_id = fjp.fal_job_program_id
         and flo.gco_good_id = gco.gco_good_id
         and pps.pps_nomenclature_id (+) = flo.pps_nomenclature_id
         and fod.fal_order_id >= 1;

END rpt_fal_order_det_bat;
