--------------------------------------------------------
--  DDL for Procedure RPT_ASA_MISSION_GOOD_DET_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_MISSION_GOOD_DET_SUB" (
   arefcursor     IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_99   IN       NUMBER
)
IS
/*
* Description stored procedure used for the report ASA_MISSION_GOOD

* @created awu 23 Jun 2008
* @lastupdate
* @public
* @param PARAMETER_99: ASA_INTERVENTION_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT DECODE (aid.gco_good_id, NULL, 's', 'g') good_service,
             goo.goo_major_reference, aid.aid_taken_quantity,
             aid.aid_consumed_quantity, aid.aid_invoicing_qty,
             aid.aid_unit_price, aid.aid_cost_price
        FROM asa_intervention_detail aid, gco_good goo
       WHERE NVL (aid.gco_good_id, aid.gco_service_id) = goo.gco_good_id
         AND aid.asa_intervention_id = parameter_99;
END rpt_asa_mission_good_det_sub;
