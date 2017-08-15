--------------------------------------------------------
--  DDL for Procedure RPT_FAL_MPS_8WEEKS_QTY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_MPS_8WEEKS_QTY" (
   arefcursor   IN OUT   crystal_cursor_types.dualcursortyp,
   user_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*Description - Used for report FAL_MPS_8WEEKS_QTY
*@created MZHU 12 Feb 2009
*@lastUpdate
*@public
*@param USER_LANID: user language
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
   firstday1     DATE;               --The first day of current week (week 1)
   firstday2     DATE;                              --The first day of week 1
   firstday3     DATE;                              --The first day of week 1
   firstday4     DATE;                              --The first day of week 1
   firstday5     DATE;                              --The first day of week 1
   firstday6     DATE;                              --The first day of week 1
   firstday7     DATE;                              --The first day of week 1
   firstday8     DATE;                              --The first day of week 1
   firstday9     DATE;                              --The first day of week 1
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (user_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;
   firstday1 := SYSDATE - TO_CHAR (SYSDATE, 'D') + 2;
                                     --get the date of Monday of current week
   firstday2 := firstday1 + 7;
   firstday3 := firstday2 + 7;
   firstday4 := firstday3 + 7;
   firstday5 := firstday4 + 7;
   firstday6 := firstday5 + 7;
   firstday7 := firstday6 + 7;
   firstday8 := firstday7 + 7;
   firstday9 := firstday8 + 7;

   OPEN arefcursor FOR
      SELECT goo.gco_good_id, goo.goo_major_reference,
             goo.goo_number_of_decimal, man.dic_unit_of_measure_id,
             lot.lot_refcompl,
             TO_CHAR (lot.lot_plan_begin_dte, 'IW') begin_dte,
             TO_CHAR (firstday1, 'IW') week1, TO_CHAR (firstday2, 'IW')
                                                                       week2,
             TO_CHAR (firstday3, 'IW') week3, TO_CHAR (firstday4, 'IW')
                                                                       week4,
             TO_CHAR (firstday5, 'IW') week5, TO_CHAR (firstday6, 'IW')
                                                                       week6,
             TO_CHAR (firstday7, 'IW') week7, TO_CHAR (firstday8, 'IW')
                                                                       week8,
             (CASE lot.c_lot_status
                 WHEN '1'
                    THEN lot.lot_total_qty
                 WHEN '2'
                    THEN lot.lot_total_qty
                 WHEN '5'
                    THEN lot.lot_released_qty
                 ELSE 0
              END
             ) qty,
             SYSDATE sys_date, TO_CHAR (SYSDATE, 'YYYYIW') sysweek
        FROM fal_lot lot, gco_good goo, gco_compl_data_manufacture man
       WHERE goo.gco_good_id = lot.gco_good_id
         AND goo.gco_good_id = man.gco_good_id
         AND NVL (man.dic_fab_condition_id, ' ') =
                                           NVL (lot.dic_fab_condition_id, ' ')
         AND lot.lot_plan_begin_dte >= firstday1
         AND lot.lot_plan_begin_dte < firstday9;
END rpt_fal_mps_8weeks_qty;
