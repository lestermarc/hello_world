--------------------------------------------------------
--  DDL for Procedure RPT_FAL_LOT_POST_CALC
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_LOT_POST_CALC" (
   arefcursor   IN OUT   crystal_cursor_types.dualcursortyp,
   user_lanid   IN       VARCHAR                                           --,
--PARAMETER_0      IN       NUMBER -- for corrected report
)
IS
/**
*Description Used for report FAL_LOT_POST_CALCULATION.RPT

*@created MZHU 12 Feb 2009
*@lastUpdate
*@public
*@param PARAMETER_0 :   FAL_LOT_ID
*/
   vpc_lang_id   NUMBER (12);
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (user_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT lot.fal_lot_id, lot.lot_total_qty, lot.lot_released_qty,
             lot.lot_reject_released_qty, lot.lot_refcompl,
             goo_pri.goo_major_reference goo_major_reference_pri,
             goo_pri.goo_number_of_decimal goo_number_of_decimal_pri,
             gco_functions.getdescription (goo_pri.gco_good_id,
                                           user_lanid,
                                           1,
                                           '01'
                                          ) v_descr
        FROM fal_lot lot, gco_good goo_pri
       WHERE lot.gco_good_id = goo_pri.gco_good_id;
END rpt_fal_lot_post_calc;
