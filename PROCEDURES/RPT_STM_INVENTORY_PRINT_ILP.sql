--------------------------------------------------------
--  DDL for Procedure RPT_STM_INVENTORY_PRINT_ILP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_STM_INVENTORY_PRINT_ILP" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       stm_inventory_print.ipt_print_session%TYPE
)
IS
/**
* Description Used for report STM_INVENTORY_LIST_COUNTING ,STM_INVENTORY_LIST_WITH_VALUE

* @created AWU Dec.2008
* @lastUpdate mzhu 20 Feb 2009
* @param PARAMETER_0: Print session
* */
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT inv.inv_description, ili.ili_description, ili.ili_remark,
             goo.goo_major_reference, goo.goo_number_of_decimal,
             sto.sto_description, loc.loc_description,
             ilp.ilp_characterization_value_1,
             ilp.ilp_characterization_value_2,
             ilp.ilp_characterization_value_3,
             ilp.ilp_characterization_value_4,
             ilp.ilp_characterization_value_5,
             gco_functions.getdescription (goo.gco_good_id,
                                           procuser_lanid,
                                           1,
                                           '01'
                                          ) descr,
             gco_functions.getcharacdescr4prnt
                              (ilp.gco_characterization_id,
                               procuser_lanid
                              ) v_charpact_desc_1,
             gco_functions.getcharacdescr4prnt
                          (ilp.gco_gco_characterization_id,
                           procuser_lanid
                          ) v_charpact_desc_2,
             gco_functions.getcharacdescr4prnt
                         (ilp.gco2_gco_characterization_id,
                          procuser_lanid
                         ) v_charpact_desc_3,
             gco_functions.getcharacdescr4prnt
                         (ilp.gco3_gco_characterization_id,
                          procuser_lanid
                         ) v_charpact_desc_4,
             ilp.ilp_inventory_value, ilp.ilp_inventory_quantity,
             ilp.ilp_system_value, ilp.ilp_system_quantity
        FROM stm_inventory_task inv,
             stm_inventory_print ipt,
             stm_inventory_list ili,
             stm_inventory_list_pos ilp,
             stm_stock sto,
             stm_location loc,
             stm_period per,
             stm_exercise exe,
             gco_good goo,
             gco_good_calc_data gcd
       WHERE inv.stm_inventory_task_id = ilp.stm_inventory_task_id
         AND inv.stm_period_id = per.stm_period_id
         AND per.stm_exercise_id = exe.stm_exercise_id
         AND ipt.stm_inventory_list_id = ili.stm_inventory_list_id
         AND ili.stm_inventory_list_id = ilp.stm_inventory_list_id
         AND ilp.stm_stock_id = sto.stm_stock_id
         AND ilp.gco_good_id = goo.gco_good_id
         AND ilp.stm_location_id = loc.stm_location_id
         AND goo.gco_good_id = gcd.gco_good_id
         AND ipt.ipt_print_session = parameter_0;
END rpt_stm_inventory_print_ilp;
