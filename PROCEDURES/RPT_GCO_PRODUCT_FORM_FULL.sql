--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_FULL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_FULL" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, procuser_lanid in     pcs.pc_lang.lanid%type
, parameter_0    in     number
)
is
/**Description - used for report GCO_PRODUCT_FORM_FULL

* @author SMA 05 MARCH 2015
* @lastUpdate
* @public
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select GOO.GCO_GOOD_ID GC_GCO_GOOD_ID
         , GOO.GOO_MAJOR_REFERENCE
         , GOO.GOO_SECONDARY_REFERENCE
         , GOO.GOO_NUMBER_OF_DECIMAL
         , GOO.A_DATECRE
         , GOO.A_DATEMOD
         , VPC_LANG_ID PC_LANG_ID
         , GCO_FUNCTIONS.GETDESCRIPTION2(GOO.GCO_GOOD_ID, vpc_lang_id, 1, '01') DES_SHORT_DESCRIPTION
         , GCO_FUNCTIONS.GETDESCRIPTION2(GOO.GCO_GOOD_ID, vpc_lang_id, 2, '01') DES_LONG_DESCRIPTION
         , GCO_FUNCTIONS.GETDESCRIPTION2(GOO.GCO_GOOD_ID, vpc_lang_id, 3, '01') DES_FREE_DESCRIPTION
         , GOO.DIC_UNIT_OF_MEASURE_ID
         , GOO.C_MANAGEMENT_MODE
         , GOO.GOO_PRECIOUS_MAT
         , GOO.C_GOOD_STATUS
         , PDT.GCO_GOOD_ID
         , PDT.STM_STOCK_ID
         , PDT.PDT_FULL_TRACABILITY
         , STO.STO_DESCRIPTION
         , PDT.STM_LOCATION_ID
         , LOC.LOC_DESCRIPTION
         , PDT.C_SUPPLY_MODE
         , PDT.PDT_STOCK_MANAGEMENT
         , PDT.PDT_STOCK_OBTAIN_MANAGEMENT
         , PDT.PDT_CALC_REQUIREMENT_MNGMENT
         , PDT.PDT_CONTINUOUS_INVENTAR
         , PDT.PDT_PIC
         , PDT.PDT_BLOCK_EQUI
         , PDT.PDT_GUARANTY_USE
         , PDT.PDT_MULTI_SOURCING
         , PDT.PDT_VERSION
         , (select GDE.GCD_WORDING
              from GCO_GOOD_CATEGORY_DESCR GDE
             where GDE.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID
               and GDE.PC_LANG_ID = VPC_LANG_ID) GCD_WORDING
         , CDM.GCO_COMPL_DATA_MANUFACTURE_ID
         , CDM.PPS_NOMENCLATURE_ID
         , CDM.FAL_SCHEDULE_PLAN_ID
         , CDM.DIC_FAB_CONDITION_ID
         , CDM.CMA_MANUFACTURING_DELAY
         , CDM.CMA_LOT_QUANTITY
         , CDM.CMA_ECONOMICAL_QUANTITY
         , CDM.CMA_PLAN_NUMBER
         , CDM.CMA_PLAN_VERSION
         , 1 GROUPE   -- Permet de gérer un groupe supplémentaire pour l'affichage du rapport
      from GCO_GOOD GOO
         , GCO_PRODUCT PDT
         , STM_STOCK STO
         , STM_LOCATION LOC
         , GCO_COMPL_DATA_MANUFACTURE CDM
     where GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and GOO.GCO_GOOD_ID = CDM.GCO_GOOD_ID(+)
       and PDT.STM_STOCK_ID = STO.STM_STOCK_ID(+)
       and PDT.STM_LOCATION_ID = LOC.STM_LOCATION_ID(+)
       and GOO.GCO_GOOD_ID = parameter_0;
end rpt_gco_product_form_full;
