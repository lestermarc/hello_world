--------------------------------------------------------
--  DDL for Procedure RPT_FAL_POST_CALC_OPE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_POST_CALC_OPE_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR
)
IS
/**
*Description Used for report FAL_LOT_POST_CALCULATION.RPT

*@created MZHU 15 Jan 2008
*@lastUpdate
*@public
*@param parameter_0 :  LOT_REFCOMPL
*/
BEGIN
   OPEN arefcursor FOR
      SELECT faf.faf_total_amount, fac.fac_describe, ff_rate.ffr_rate1,
             ff_rate.ffr_rate2, ff_rate.ffr_rate3, ff_rate.ffr_rate4,
             ff_rate.ffr_rate5, lot.lot_asked_qty, lot.lot_total_qty,
             lot.lot_released_qty, lot.lot_refcompl, tal.tal_due_tsk,
             tal.tal_achieved_tsk, tal.tal_achieved_amt, tal.c_task_type,
             tal.scs_step_number, tal.scs_work_rate, tal.scs_amount,
             tal.scs_qty_ref_amount, tal.scs_short_descr,
             tal.scs_adjusting_time, tal.c_task_imputation,
             tal.scs_qty_fix_adjusting, tal.scs_adjusting_rate,
             tal.tal_achieved_ad_tsk, per.per_name
        FROM fal_lot lot,
             fal_task_link tal,
             pac_supplier_partner sup,
             pac_person per,
             fal_factory_floor fac,
             fal_affect faf,
             (SELECT ftl.fal_schedule_step_id, ffr.fal_factory_floor_id,
                     NVL (ffr.ffr_rate1, 0) ffr_rate1,
                     NVL (ffr.ffr_rate2, 0) ffr_rate2,
                     NVL (ffr.ffr_rate3, 0) ffr_rate3,
                     NVL (ffr.ffr_rate4, 0) ffr_rate4,
                     NVL (ffr.ffr_rate5, 0) ffr_rate5
                FROM fal_factory_rate ffr,
                     fal_factory_floor fff,
                     fal_task_link ftl
               WHERE ftl.fal_lot_id = (SELECT lot2.fal_lot_id
                                         FROM fal_lot lot2
                                        WHERE lot2.lot_refcompl = parameter_0)
                 AND ftl.fal_factory_floor_id = fff.fal_factory_floor_id
                 AND fff.fal_factory_floor_id = ffr.fal_factory_floor_id
                 AND TRUNC (ffr.ffr_validity_date) =
                        (SELECT MAX (TRUNC (ffr2.ffr_validity_date))
                           FROM fal_factory_rate ffr2
                          WHERE TRUNC (ffr2.ffr_validity_date) <=
                                   TRUNC (NVL (ftl.tal_end_real_date,
                                               ftl.tal_end_plan_date
                                              )
                                         )
                            AND ffr2.fal_factory_floor_id =
                                                      ffr.fal_factory_floor_id)) ff_rate
       WHERE lot.fal_lot_id = tal.fal_lot_id
         AND tal.pac_supplier_partner_id = sup.pac_supplier_partner_id(+)
         AND sup.pac_supplier_partner_id = per.pac_person_id(+)
         AND tal.fal_factory_floor_id = fac.fal_factory_floor_id(+)
         AND lot.fal_lot_id = faf.fal_lot_id(+)
         AND tal.fal_schedule_step_id = ff_rate.fal_schedule_step_id(+)
         AND lot.lot_refcompl = parameter_0;
END rpt_fal_post_calc_ope_sub;
