--------------------------------------------------------
--  DDL for Package Body STM_INVENTORY_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_INVENTORY_RPT" 
is
  procedure STM_INVENTORY_PRINT_ILP_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  , PARAMETER_0    in     STM_INVENTORY_PRINT.IPT_PRINT_SESSION%type
  )
  is
/**
* PROCEDURE STM_INVENTORY_PRINT_ILP_RPT_PK
* Description
*    Used in the STM_INVENTORY_LIST_COUNTING ,STM_INVENTORY_LIST_WITH_VALUE
* @created AWU Dec.2008
* @lastUpdate
* */
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select INV.INV_DESCRIPTION
           , ILI.ILI_DESCRIPTION
           , ILI.ILI_REMARK
           , GOO.GOO_MAJOR_REFERENCE
           , STO.STO_DESCRIPTION
           , LOC.LOC_DESCRIPTION
           , ILP.ILP_CHARACTERIZATION_VALUE_1
           , ILP.ILP_CHARACTERIZATION_VALUE_2
           , ILP.ILP_CHARACTERIZATION_VALUE_3
           , ILP.ILP_CHARACTERIZATION_VALUE_4
           , ILP.ILP_CHARACTERIZATION_VALUE_5
           , GCO_FUNCTIONS.GETDESCRIPTION(GOO.GCO_GOOD_ID, PROCUSER_LANID, 1, '01') DESCR
           , GCO_FUNCTIONS.GETCHARACDESCR4PRNT(ILP.GCO_CHARACTERIZATION_ID, PROCUSER_LANID) V_CHARPACT_DESC_1
           , GCO_FUNCTIONS.GETCHARACDESCR4PRNT(ILP.GCO_GCO_CHARACTERIZATION_ID, PROCUSER_LANID) V_CHARPACT_DESC_2
           , GCO_FUNCTIONS.GETCHARACDESCR4PRNT(ILP.GCO2_GCO_CHARACTERIZATION_ID, PROCUSER_LANID) V_CHARPACT_DESC_3
           , GCO_FUNCTIONS.GETCHARACDESCR4PRNT(ILP.GCO3_GCO_CHARACTERIZATION_ID, PROCUSER_LANID) V_CHARPACT_DESC_4
           , ILP.ILP_INVENTORY_VALUE
           , ILP.ILP_INVENTORY_QUANTITY
           , ILP.ILP_SYSTEM_VALUE
           , ILP.ILP_SYSTEM_QUANTITY
        from STM_INVENTORY_TASK INV
           , STM_INVENTORY_PRINT IPT
           , STM_INVENTORY_LIST ILI
           , STM_INVENTORY_LIST_POS ILP
           , STM_STOCK STO
           , STM_LOCATION LOC
           , STM_PERIOD PER
           , STM_EXERCISE EXE
           , GCO_GOOD GOO
           , GCO_GOOD_CALC_DATA GCD
       where INV.STM_INVENTORY_TASK_ID = ILP.STM_INVENTORY_TASK_ID
         and INV.STM_PERIOD_ID = PER.STM_PERIOD_ID
         and PER.STM_EXERCISE_ID = EXE.STM_EXERCISE_ID
         and IPT.STM_INVENTORY_LIST_ID = ILI.STM_INVENTORY_LIST_ID
         and ILI.STM_INVENTORY_LIST_ID = ILP.STM_INVENTORY_LIST_ID
         and ILP.STM_STOCK_ID = STO.STM_STOCK_ID
         and ILP.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and ILP.STM_LOCATION_ID = LOC.STM_LOCATION_ID
         and GOO.GCO_GOOD_ID = GCD.GCO_GOOD_ID
         and IPT.IPT_PRINT_SESSION = PARAMETER_0;
  end STM_INVENTORY_PRINT_ILP_RPT_PK;

  procedure STM_INV_PRINT_CUM_SUB_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  , PARAMETER_0    in     STM_INVENTORY_PRINT.IPT_PRINT_SESSION%type
  )
  is
/**
* PROCEDURE STM_INV_PRINT_CUM_SUB_RPT_PK
* Description
*    Used in the STM_INVENTORY_LIST_WITH_VALUE
* @created AWU Dec.2008
* @lastUpdate
* */
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select   INV.INV_DESCRIPTION
             , ILI.ILI_DESCRIPTION
             , STO.STO_DESCRIPTION
             , LOC.LOC_DESCRIPTION
             , sum(ILP.ILP_SYSTEM_VALUE) ILP_SYSTEM_VALUE_CUM
             , sum(ILP.ILP_SYSTEM_QUANTITY) ILP_SYSTEM_QUANTITY_CUM
             , sum(ILP.ILP_INVENTORY_VALUE) ILP_INVENTORY_VALUE_CUM
             , sum(ILP.ILP_INVENTORY_QUANTITY) ILP_INVENTORY_QUANTITY_CUM
             , sum(ILP.ILP_INVENTORY_VALUE - ILP.ILP_SYSTEM_VALUE) ILP_INVENTORY_DIFF_VALUE_CUM
             , sum(ILP.ILP_INVENTORY_QUANTITY - ILP.ILP_SYSTEM_QUANTITY) ILP_INVENTORY_DIFF_QTY_CUM
          from stm_inventory_task inv
             , stm_inventory_print ipt
             , stm_inventory_list ili
             , stm_inventory_list_pos ilp
             , stm_stock sto
             , stm_location loc
         where inv.stm_inventory_task_id = ilp.stm_inventory_task_id
           and ipt.stm_inventory_list_id = ili.stm_inventory_list_id
           and ili.stm_inventory_list_id = ilp.stm_inventory_list_id
           and ilp.stm_stock_id = sto.stm_stock_id
           and ilp.stm_location_id = loc.stm_location_id
           and ipt.IPT_PRINT_SESSION = PARAMETER_0
      group by ipt.ipt_print_session
             , inv.stm_inventory_task_id
             , inv.inv_description
             , ili.stm_inventory_list_id
             , ili.ili_description
             , sto.stm_stock_id
             , sto.sto_description
             , loc.stm_location_id
             , loc.loc_description;
  end STM_INV_PRINT_CUM_SUB_RPT_PK;

  procedure STM_INVENTORY_PRINT_IJO_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  , PARAMETER_0    in     STM_INVENTORY_PRINT.IPT_PRINT_SESSION%type
  )
  is
/**
* PROCEDURE STM_INVENTORY_PRINT_IJO_RPT_PK
* Description
*    Used in the STM_INVENTORY_JOB_DETAILED.rpt
* @created AWU Dec.2008
* @lastUpdate
* */
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select INV.INV_DESCRIPTION
           , ILI.ILI_DESCRIPTION
           , GOO.GOO_MAJOR_REFERENCE
           , IJO.IJO_JOB_DESCRIPTION
           , IJO.STM_INVENTORY_JOB_ID
           , IJD.IJD_CHARACTERIZATION_VALUE_1
           , IJD.IJD_CHARACTERIZATION_VALUE_2
           , IJD.IJD_CHARACTERIZATION_VALUE_3
           , IJD.IJD_CHARACTERIZATION_VALUE_4
           , IJD.IJD_CHARACTERIZATION_VALUE_5
           , IJD.IJD_QUANTITY
           , IJD.IJD_VALUE
           , IJD.IJD_UNIT_PRICE
           , GCO_FUNCTIONS.GETDESCRIPTION(GOO.GCO_GOOD_ID, PROCUSER_LANID, 1, '01') GCO_GOOD_DESCR
        from STM_INVENTORY_TASK INV
           , STM_INVENTORY_PRINT IPT
           , STM_INVENTORY_LIST ILI
           , STM_INVENTORY_JOB IJO
           , STM_INVENTORY_JOB_DETAIL IJD
           , STM_STOCK STO
           , STM_LOCATION LOC
           , STM_PERIOD PER
           , STM_EXERCISE EXE
           , GCO_GOOD GOO
           , GCO_GOOD_CALC_DATA GCD
       where INV.STM_INVENTORY_TASK_ID = IJO.STM_INVENTORY_TASK_ID
         and INV.STM_PERIOD_ID = PER.STM_PERIOD_ID
         and PER.STM_EXERCISE_ID = EXE.STM_EXERCISE_ID
         and IPT.STM_INVENTORY_JOB_ID = IJO.STM_INVENTORY_JOB_ID
         and IJO.STM_INVENTORY_JOB_ID = IJD.STM_INVENTORY_JOB_ID
         and IJO.STM_INVENTORY_LIST_ID = ILI.STM_INVENTORY_LIST_ID
         and IJD.STM_STOCK_ID = STO.STM_STOCK_ID
         and IJD.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and IJD.STM_LOCATION_ID = LOC.STM_LOCATION_ID
         and GOO.GCO_GOOD_ID = GCD.GCO_GOOD_ID
         and IPT.IPT_PRINT_SESSION = PARAMETER_0;
  end STM_INVENTORY_PRINT_IJO_RPT_PK;
end STM_INVENTORY_RPT;
