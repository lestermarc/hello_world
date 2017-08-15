--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_MANF_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_MANF_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 14 JUL 2009
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT cdm.gco_good_id, cdm.dic_fab_condition_id, nom.c_type_nom,
             nom.nom_version, sch.c_schedule_planning, cdm.cma_lot_quantity,
             sch.sch_ref, cdm.cma_manufacturing_delay,
             cdm.cma_economical_quantity, cdm.cma_plan_number,
             cdm.cma_plan_version
        FROM gco_compl_data_manufacture cdm,
             pps_nomenclature nom,
             fal_schedule_plan sch
       WHERE cdm.pps_nomenclature_id = nom.pps_nomenclature_id(+)
         AND cdm.fal_schedule_plan_id = sch.fal_schedule_plan_id(+)
         AND (cdm.cma_default = 1 OR cdm.cma_default IS NULL)
         AND cdm.gco_good_id = parameter_0;
END rpt_gco_product_form_manf_sub;
