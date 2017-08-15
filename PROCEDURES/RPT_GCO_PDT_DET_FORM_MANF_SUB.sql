--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PDT_DET_FORM_MANF_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PDT_DET_FORM_MANF_SUB" (arefcursor in out crystal_cursor_types.dualcursortyp, parameter_0 in number)
is
/**Description - used for report GCO_PRODUCT_FORM_FULL

* @author SMA 09 MARCH 2015
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;   --user language id
begin
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select   CDM.GCO_GOOD_ID
           , CDM.DIC_FAB_CONDITION_ID
           , CDM.CMA_LOT_QUANTITY
           , CDM.CMA_MANUFACTURING_DELAY
           , CDM.CMA_ECONOMICAL_QUANTITY
           , CDM.CMA_PLAN_NUMBER
           , CDM.CMA_PLAN_VERSION
           , PPS.PPS_NOMENCLATURE_ID
           , PPS.C_TYPE_NOM
           , PPS.NOM_VERSION
           , COM.PPS_NOM_BOND_ID
           , COM.PPS_NOMENCLATURE_ID
           , COM.COM_VAL
           , COM.COM_SEQ
           , COM.C_TYPE_COM
           , COM.C_KIND_COM
           , COM.GCO_GOOD_ID
           , COM.PPS_PPS_NOMENCLATURE_ID
           , GOO.GOO_SECONDARY_REFERENCE
           , DES.DES_SHORT_DESCRIPTION
           , GOO.DIC_UNIT_OF_MEASURE_ID
           , COM.COM_UTIL_COEFF
           , COM.COM_PDIR_COEFF
           , COM.COM_PERCENT_WASTE
           , COM.COM_FIXED_QUANTITY_WASTE
           , COM.COM_QTY_REFERENCE_LOSS
           , COM.COM_REC_PCENT
           , COM.COM_POS
           , COM.FAL_SCHEDULE_STEP_ID
           , COM.PPS_RANGE_OPERATION_ID
           , COM.STM_STOCK_ID
           , COM.STM_LOCATION_ID
           , COM.C_DISCHARGE_COM
           , COM.C_REMPLACEMENT_NOM
           , COM.COM_REMPLACEMENT
           , COM.COM_BEG_VALID
           , COM.COM_END_VALID
           , COM.COM_SUBSTITUT
           , COM.COM_INTERVAL
           , COM.COM_INCREASE_COST
           , COM.COM_TEXT
           , COM.COM_RES_TEXT
           , COM.COM_RES_NUM
           , COM.COM_MARK_TOPO
           , COM.COM_WEIGHING
           , COM.COM_WEIGHING_MANDATORY
           , GOO.GOO_PRECIOUS_MAT
           , COM.A_DATECRE
           , COM.A_IDCRE
           , COM.A_DATEMOD
           , COM.A_IDMOD
           , PPS.FAL_SCHEDULE_PLAN_ID
           , SCH.C_SCHEDULE_PLANNING
           , SCH.SCH_REF
        from GCO_COMPL_DATA_MANUFACTURE CDM
           , PPS_NOMENCLATURE PPS
           , PPS_NOM_BOND COM
           , GCO_GOOD GOO
           , GCO_DESCRIPTION DES
           , FAL_SCHEDULE_PLAN SCH
       where CDM.PPS_NOMENCLATURE_ID = PPS.PPS_NOMENCLATURE_ID(+)
         and COM.PPS_NOMENCLATURE_ID = pps.PPS_NOMENCLATURE_ID
         and GOO.GCO_GOOD_ID(+) = COM.GCO_GOOD_ID
         and pps.PPS_NOMENCLATURE_ID = COM.PPS_NOMENCLATURE_ID
         and COM.GCO_GOOD_ID = DES.GCO_GOOD_ID(+)
         and DES.PC_LANG_ID(+) = vpc_lang_id
         and DES.C_DESCRIPTION_TYPE(+) = '01'
         and CDM.FAL_SCHEDULE_PLAN_ID = SCH.FAL_SCHEDULE_PLAN_ID(+)
         and CDM.GCO_GOOD_ID = parameter_0
    order by CDM.DIC_FAB_CONDITION_ID nulls first
           , COM.COM_SEQ asc;
end rpt_gco_pdt_det_form_manf_sub;
