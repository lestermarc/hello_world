--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PDT_DET_FORM_STOCK_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PDT_DET_FORM_STOCK_SUB" (arefcursor in out crystal_cursor_types.dualcursortyp, parameter_0 in number)
is
/**Description - used for report GCO_PRODUCT_FORM_FULL

* @author SMA 5 MARCH 2015
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
begin
  open arefcursor for
    select   CDS.GCO_GOOD_ID
           , STO.STO_DESCRIPTION
           , LOC.LOC_DESCRIPTION
           , CDS.CST_QUANTITY_MIN
           , CDS.CST_QUANTITY_MAX
           , CDS.CST_TRIGGER_POINT
           , CDS.DIC_TEMPERATURE_ID
           , CDS.DIC_LUMINOSITY_ID
           , CDS.DIC_RELATIVE_HUMIDITY_ID
           , CDS.DIC_STORAGE_POSITION_ID
        from GCO_COMPL_DATA_STOCK CDS
           , STM_STOCK STO
           , STM_LOCATION LOC
       where CDS.STM_STOCK_ID = STO.STM_STOCK_ID(+)
         and CDS.STM_LOCATION_ID = LOC.STM_LOCATION_ID(+)
         and CDS.GCO_GOOD_ID = parameter_0
    order by STO.STO_DESCRIPTION nulls first
           , LOC.LOC_DESCRIPTION nulls first;
end rpt_gco_pdt_det_form_stock_sub;
