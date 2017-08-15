--------------------------------------------------------
--  DDL for Procedure RPT_FAL_MAN_TRACKING
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_MAN_TRACKING" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
, pc_comp_id     in     pcs.pc_comp.pc_comp_id%type
, pc_conli_id    in     pcs.pc_conli.pc_conli_id%type
)
is
/**
* Description - Used in report RPT_FAL_MAN_TRACKING

* Stored procedure used by the report FAL_MAN_TRACKING
* @created VHA 16 November 2012
* Modified
* lastUpdate
* @param proc_param_0    FAL_LOT_ID
*/
  vpc_lang_id  pcs.pc_lang.pc_lang_id%type;
  vpc_comp_id  pcs.pc_comp.pc_comp_id%type;
  vpc_conli_id pcs.pc_conli.pc_conli_id%type;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  pcs.PC_I_LIB_SESSION.setcompanyid(pc_comp_id);
  pcs.PC_I_LIB_SESSION.setconliid(pc_conli_id);
  vpc_lang_id   := pcs.PC_I_LIB_SESSION.getuserlangid;
  vpc_comp_id   := pcs.PC_I_LIB_SESSION.getcompanyid;
  vpc_conli_id  := pcs.PC_I_LIB_SESSION.getconliid;

  open arefcursor for
    select LOT.FAL_LOT_ID
         , LOT.LOT_REFCOMPL
         , LOT.LOT_SHORT_DESCR
         , RCO.RCO_TITLE
         , FSP.SCH_REF
         , PCS.PC_FUNCTIONS.GETDESCODEDESCR('C_LOT_STATUS', LOT.C_LOT_STATUS, vpc_lang_id) OF_STATUS
         , GCO.GOO_MAJOR_REFERENCE || '/' || GCO.GOO_SECONDARY_REFERENCE ARTICLE
         , LOT.LOT_TOTAL_QTY
         , nvl(LOT.LOT_RELEASED_QTY, 0) + nvl(LOT.LOT_REJECT_RELEASED_QTY, 0) + nvl(LOT.LOT_DISMOUNTED_QTY, 0) QTY_FINISHED
         , LOT.LOT_INPROD_QTY
         , GCO.DIC_UNIT_OF_MEASURE_ID
         , TAL.SCS_STEP_NUMBER
         , TAS.TAS_REF || '/' || TAL.SCS_SHORT_DESCR OP_DESCR
         , TAL.TAL_BEGIN_PLAN_DATE
         , TAL.TAL_END_PLAN_DATE
         , TAL.TAL_DUE_TSK
         , FLP.FLP_SEQ
         , FLP.FLP_DATE1 TRACKING_DATE
         , com_dic_functions.getdicodescr('DIC_OPERATOR', FLP.DIC_OPERATOR_ID, vpc_lang_id) operator
         , FLP.FLP_PRODUCT_QTY
         , FLP.FLP_PT_REJECT_QTY
         , FLP.FLP_CPT_REJECT_QTY
         , FLP.FLP_ADJUSTING_TIME
         , FLP.FLP_WORK_TIME
         , FLP.FLP_AMOUNT
         , FAL_WEIGHT.WEIGHT_MAT
         , PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT', vpc_comp_id, vpc_conli_id) PPS_WORK_UNIT_CONFIG
         , decode(TAL.SCS_QTY_FIX_ADJUSTING, 0, 0, FAL_TOOLS.RoundSuccInt(LOT.LOT_TOTAL_QTY / TAL.SCS_QTY_FIX_ADJUSTING) * nvl(TAL.SCS_ADJUSTING_TIME, 0) )
                                                                                                                                            SETTING_EXP_OP_TIME
         , (LOT.LOT_TOTAL_QTY / nvl(TAL.SCS_QTY_REF_WORK, 1) ) * nvl(TAL.SCS_WORK_TIME, 0) WORK_EXP_OP_TIME
      from FAL_LOT LOT
         , FAL_TASK_LINK TAL
         , FAL_TASK TAS
         , FAL_LOT_PROGRESS FLP
         , DOC_RECORD RCO
         , FAL_SCHEDULE_PLAN FSP
         , GCO_GOOD GCO
         , (select   FAL_LOT_PROGRESS_ID
                   , sum(FWE_WEIGHT_MAT) WEIGHT_MAT
                from FAL_WEIGH FWE
               where FWE_IN = 0
            group by FAL_LOT_PROGRESS_ID) FAL_WEIGHT
     where LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
       and LOT.GCO_GOOD_ID = GCO.GCO_GOOD_ID
       and TAL.FAL_TASK_ID = TAS.FAL_TASK_ID
       and LOT.FAL_SCHEDULE_PLAN_ID = FSP.FAL_SCHEDULE_PLAN_ID(+)
       and TAL.FAL_SCHEDULE_STEP_ID = FLP.FAL_SCHEDULE_STEP_ID(+)
       and LOT.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
       and FLP.FAL_LOT_PROGRESS_ID = FAL_WEIGHT.FAL_LOT_PROGRESS_ID(+)
       and instr(',' || parameter_0 || ',', ',' || LOT.FAL_LOT_ID || ',') > 0
       and (   FLP.FAL_LOT_PROGRESS_ID is null
            or FLP.FLP_REVERSAL = 0);
end RPT_FAL_MAN_TRACKING;
