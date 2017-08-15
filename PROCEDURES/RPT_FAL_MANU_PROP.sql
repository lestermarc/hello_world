--------------------------------------------------------
--  DDL for Procedure RPT_FAL_MANU_PROP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_MANU_PROP" (
   arefcursor   IN OUT   crystal_cursor_types.dualcursortyp,
   user_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*Description Used for report FAL_FACTORY_FLOOR,FAL_FACTORY_FLOOR_BATCH. This one is used only since SP6

*@created LBU 05 SEP 2008
*@lastUpdate CLIU 17 Mar 2010
*@Published VHA 20 Sept 2011
*@public
*@param USER_LANID  : user language
*/
   vpc_lang_id             pcs.pc_lang.pc_lang_id%TYPE;
   vno_accountable_group   VARCHAR2 (4000 CHAR);
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (user_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;
   vno_accountable_group :=
      pcs.pc_functions.translateword2 ('Pas de groupe responsable',
                                       vpc_lang_id
                                      );

   OPEN arefcursor FOR
      SELECT gd.c_description_type, nvl(goo.dic_accountable_group_id,vno_ACCOUNTABLE_GROUP) dic_accountable_group_id,
             goo.goo_major_reference, gd.des_short_description,
             gd.des_long_description, gd.des_free_description,
             goo.goo_number_of_decimal, fns.fan_beg_plan, fns.fan_end_plan,
             fnn.fan_balance_qty, fnn.fan_beg_plan fnn_beg_plan,
             fnn.fan_end_plan fnn_end_plan,
             fns.fan_description fns_description, goo.dic_unit_of_measure_id,
             fsr.fsr_texte, fsr.fsr_number, fnl.fln_qty, fnl.fln_need_delay,
             fsr.fsr_delay, fsr.fsr_total_qty, flp.lot_total_qty,
             cda.dic_unit_of_measure_id, flp.lot_asked_qty,
             flp.lot_reject_plan_qty, flp.fal_lot_prop_id,
             fnl.fal_network_need_id, flp.fal_supply_request_id,
             flp.gco_good_id, sto.sto_description, fnn.fal_lot_id,
             fnn.fan_description, lot.lot_refcompl,
             gco_functions.getcostpricewithmanagementmode
                                                  (goo.gco_good_id)
                                                                   cost_price
        FROM fal_lot_prop flp,
             gco_compl_data_manufacture cda,
             gco_good goo,
             gco_description gd,
             fal_supply_request fsr,
             fal_network_supply fns,
             fal_network_link fnl,
             fal_network_need fnn,
             stm_location loc,
             stm_stock sto,
             fal_lot lot
       WHERE goo.gco_good_id = flp.gco_good_id
         AND gd.pc_lang_id = vpc_lang_id
         AND gd.gco_good_id = goo.gco_good_id
         AND gd.c_description_type = '01'
         AND cda.gco_good_id = flp.gco_good_id
         AND cda.dic_fab_condition_id = flp.dic_fab_condition_id
         AND flp.fal_lot_prop_id >= 0
         AND flp.fal_lot_prop_id = fns.fal_lot_prop_id(+)
         AND fnl.fal_network_supply_id(+) = fns.fal_network_supply_id
         AND fnl.fal_network_need_id = fnn.fal_network_need_id(+)
         AND loc.stm_location_id(+) = fnl.stm_location_id
         AND sto.stm_stock_id(+) = loc.stm_stock_id
         AND flp.fal_supply_request_id = fsr.fal_supply_request_id(+)
         AND lot.fal_lot_id(+) = fnn.fal_lot_id;
END rpt_fal_manu_prop;
