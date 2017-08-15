--------------------------------------------------------
--  DDL for Procedure RPT_STM_INV_PRINT_CUM_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_STM_INV_PRINT_CUM_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       stm_inventory_print.ipt_print_session%TYPE
)
IS
/**
* Description Used for report STM_INVENTORY_LIST_WITH_VALUE
* @created AWU Dec.2008
* @lastUpdate mzhu 20 Feb 2009
* @param PARAMETER_0: Print session
* */
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT   ipt.ipt_print_session, inv.inv_description,
               ili.ili_description, sto.sto_description, loc.loc_description,
               SUM (ilp.ilp_system_value) ilp_system_value_cum,
               SUM (ilp.ilp_system_quantity) ilp_system_quantity_cum,
               SUM (ilp.ilp_inventory_value) ilp_inventory_value_cum,
               SUM (ilp.ilp_inventory_quantity) ilp_inventory_quantity_cum,
               SUM (ilp.ilp_inventory_value - ilp.ilp_system_value
                   ) ilp_inventory_diff_value_cum,
               SUM (ilp.ilp_inventory_quantity - ilp.ilp_system_quantity
                   ) ilp_inventory_diff_qty_cum
          FROM stm_inventory_task inv,
               stm_inventory_print ipt,
               stm_inventory_list ili,
               stm_inventory_list_pos ilp,
               stm_stock sto,
               stm_location loc
         WHERE inv.stm_inventory_task_id = ilp.stm_inventory_task_id
           AND ipt.stm_inventory_list_id = ili.stm_inventory_list_id
           AND ili.stm_inventory_list_id = ilp.stm_inventory_list_id
           AND ilp.stm_stock_id = sto.stm_stock_id
           AND ilp.stm_location_id = loc.stm_location_id
           AND ipt.ipt_print_session = parameter_0
      GROUP BY ipt.ipt_print_session,
               inv.stm_inventory_task_id,
               inv.inv_description,
               ili.stm_inventory_list_id,
               ili.ili_description,
               sto.stm_stock_id,
               sto.sto_description,
               loc.stm_location_id,
               loc.loc_description;
END rpt_stm_inv_print_cum_sub;
