--------------------------------------------------------
--  DDL for Procedure RPT_STM_MAGLIST_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_STM_MAGLIST_SUB" (
   arefcursor     IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_14   IN       NUMBER
)
IS
/**
*Description USED FOR SUB-REPORT MAGLIST.RPT OF STM_STOCK_EFFECTIF_VAL/STM_STOCK_EFFECTIF_VALORISED_GAMME/STM_QTY_END_OF_MONTH_WITH_GROUP
* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZH 21 Feb 2009
* @LASTUPDATE 24 jan 2010
* @VERSION
* @PUBLIC
* @PARAM PARAMETER_14 COM_list : job_id
*/
BEGIN
   OPEN arefcursor FOR
      SELECT 'GROUP_STRING' group_string, loc.loc_description,
             sto.sto_description
        FROM stm_location loc, stm_stock sto,  com_list c_loc
       WHERE sto.stm_stock_id = loc.stm_stock_id
         AND loc.stm_location_id = c_loc.lis_id_1
         AND c_loc.lis_job_id = parameter_14
         AND c_loc.lis_code = 'STM_LOCATION_ID';
END rpt_stm_maglist_sub;
