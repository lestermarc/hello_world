--------------------------------------------------------
--  DDL for Procedure RPT_GCO_SERVICE_RESOURCE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_SERVICE_RESOURCE_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_SERVICE_FORM_BATCH

* @author AWU 13 OCT 2009
* @lastUpdate 7 MAY 2009
* @public
* @param parameter_0: GCO_GOOD_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT rtp.dic_resource_type_wording, res.gco_resource_id,
             res.gco_resource_wording, srs.gco_good_id,
             rtp.dic_resource_type_id
        FROM gco_service_resource srs,
             gco_resource res,
             dic_resource_type rtp
       WHERE srs.gco_resource_id = res.gco_resource_id
         AND res.dic_resource_type_id = rtp.dic_resource_type_id
         AND srs.gco_good_id = parameter_0;
END rpt_gco_service_resource_sub;
