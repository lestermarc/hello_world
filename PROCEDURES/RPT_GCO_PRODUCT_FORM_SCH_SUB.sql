--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_SCH_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_SCH_SUB" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, procuser_lanid in     pcs.pc_lang.lanid%type
, parameter_0    in     number
)
is
/**Description - used for report GCO_PRODUCT_FORM_FULL
* @author SMA 16.03.2015
* @lastUpdate
* @public
* PARAMETER_0:  Id de nomenclature
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;   --user language id
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select   SCH.SCH_REF
           , SCH.SCH_SHORT_DESCR
           , SCS.SCS_STEP_NUMBER
           , SCS.SCS_SHORT_DESCR
           , SCS.SCS_ADJUSTING_TIME
           , SCS.SCS_WORK_TIME
           , SCS.SCS_QTY_REF_WORK
           , SCS.SCS_WORK_RATE
           , SCS.SCS_AMOUNT
           , SCS.SCS_QTY_REF_AMOUNT
           , SCH.FAL_SCHEDULE_PLAN_ID
           , SCS.PPS_PPS_OPERATION_PROCEDURE_ID
           , SCS.PPS_OPERATION_PROCEDURE_ID
           , SCS.SCS_DIVISOR_AMOUNT
           , SCS.GCO_GCO_GOOD_ID
           , SCS.PAC_SUPPLIER_PARTNER_ID
           , SCS.FAL_FACTORY_FLOOR_ID
           , SCS.FAL_TASK_ID
           , SCS.C_OPERATION_TYPE
           , SCH.C_SCHEDULE_PLANNING
           , SCS.SCS_ADJUSTING_RATE
           , SCS.FAL_SCHEDULE_STEP_ID
           , SCS.PPS_TOOLS1_ID
           , SCS.PPS_TOOLS2_ID
           , SCS.PPS_TOOLS3_ID
           , SCS.PPS_TOOLS4_ID
           , SCS.PPS_TOOLS5_ID
           , SCS.FAL_FAL_FACTORY_FLOOR_ID
           , SCS.SCS_QTY_FIX_ADJUSTING
           , SCS.SCS_WEIGH
           , SCS.SCS_WEIGH_MANDATORY
           , (select GCO_GOOD.GOO_MAJOR_REFERENCE
                from GCO_GOOD
               where GCO_GOOD.GCO_GOOD_ID = SCS.PPS_TOOLS1_ID) Tool1
           , (select GCO_GOOD.GOO_MAJOR_REFERENCE
                from GCO_GOOD
               where GCO_GOOD.GCO_GOOD_ID = SCS.PPS_TOOLS2_ID) Tool2
           , (select GCO_GOOD.GOO_MAJOR_REFERENCE
                from GCO_GOOD
               where GCO_GOOD.GCO_GOOD_ID = SCS.PPS_TOOLS3_ID) Tool3
           , (select GCO_GOOD.GOO_MAJOR_REFERENCE
                from GCO_GOOD
               where GCO_GOOD.GCO_GOOD_ID = SCS.PPS_TOOLS4_ID) Tool4
           , (select GCO_GOOD.GOO_MAJOR_REFERENCE
                from GCO_GOOD
               where GCO_GOOD.GCO_GOOD_ID = SCS.PPS_TOOLS5_ID) Tool5
        from FAL_SCHEDULE_PLAN SCH
           , FAL_LIST_STEP_LINK SCS
       where SCH.FAL_SCHEDULE_PLAN_ID = SCS.FAL_SCHEDULE_PLAN_ID(+)
         and SCH.FAL_SCHEDULE_PLAN_ID = parameter_0
    order by SCH.SCH_REF
           , SCS.SCS_STEP_NUMBER;
end rpt_gco_product_form_sch_sub;
