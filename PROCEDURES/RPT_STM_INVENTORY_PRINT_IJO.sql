--------------------------------------------------------
--  DDL for Procedure RPT_STM_INVENTORY_PRINT_IJO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_STM_INVENTORY_PRINT_IJO" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       stm_inventory_print.ipt_print_session%TYPE
)
IS
/**
* Description Used for report STM_INVENTORY_JOB_DETAILED
* @created AWU Dec.2008
* @lastUpdate MZHU 22 Feb 2009
* @param PARAMETER_0: Print session
* */
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT inv.inv_description, ili.ili_description,
             goo.goo_major_reference, goo.goo_number_of_decimal,
             ijo.ijo_job_description, ijo.stm_inventory_job_id,
             ijd.ijd_characterization_value_1,
             ijd.ijd_characterization_value_2,
             ijd.ijd_characterization_value_3,
             ijd.ijd_characterization_value_4,
             ijd.ijd_characterization_value_5, ijd.ijd_quantity,
             ijd.ijd_value, ijd.ijd_unit_price,
             gco_functions.getdescription (goo.gco_good_id,
                                           procuser_lanid,
                                           1,
                                           '01'
                                          ) gco_good_descr
        FROM stm_inventory_task inv,
             stm_inventory_print ipt,
             stm_inventory_list ili,
             stm_inventory_job ijo,
             stm_inventory_job_detail ijd,
             stm_stock sto,
             stm_location loc,
             stm_period per,
             stm_exercise exe,
             gco_good goo,
             gco_good_calc_data gcd
       WHERE inv.stm_inventory_task_id = ijo.stm_inventory_task_id
         AND inv.stm_period_id = per.stm_period_id
         AND per.stm_exercise_id = exe.stm_exercise_id
         AND ipt.stm_inventory_job_id = ijo.stm_inventory_job_id
         AND ijo.stm_inventory_job_id = ijd.stm_inventory_job_id
         AND ijo.stm_inventory_list_id = ili.stm_inventory_list_id
         AND ijd.stm_stock_id = sto.stm_stock_id
         AND ijd.gco_good_id = goo.gco_good_id
         AND ijd.stm_location_id = loc.stm_location_id
         AND goo.gco_good_id = gcd.gco_good_id
         AND ipt.ipt_print_session = parameter_0;
END rpt_stm_inventory_print_ijo;
