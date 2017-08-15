--------------------------------------------------------
--  DDL for Procedure RPT_FAL_LOT_MATERIAL_EXIT_SCP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_LOT_MATERIAL_EXIT_SCP" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
)
is
/**
*Description
        Used for report FAL_LOT_MATERIAL_EXIT_SCP

*@created VHA 28 February 2013
*@lastUpdate SMA 21.05.2015
*@public
*@param parameter_0 : DMT_NUMBER
*@param procuser_lanid : user language
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;
begin
  open arefcursor for
    select DOC.DMT_NUMBER
         , PCS.PC_ISS_UTILS.Get_Lanid(DOC.PC_LANG_ID) DOC_LANID   --LANGUE DU DOCUMENT
         , DOC.DMT_DATE_DOCUMENT
         , gco_lib_functions.getMajorReference(POS.GCO_GOOD_ID) POS_GOO_MAJOR_REFERENCE
         , gco_lib_functions.GetNumberOfDecimal(POS.GCO_GOOD_ID) POS_GOO_NUMBER_OF_DECIMAL
         , gco_lib_functions.getMajorReference(POS.GCO_MANUFACTURED_GOOD_ID) POS_MAN_GOO_MAJOR_REFERENCE
         , gco_lib_functions.GetNumberOfDecimal(POS.GCO_MANUFACTURED_GOOD_ID) POS_MAN_GOO_NUMBER_OF_DECIMAL
         , gco_lib_functions.GetDescription2(POS.GCO_MANUFACTURED_GOOD_ID, DOC.PC_LANG_ID, 1, '01') POS_MAN_GOO_SHORT_DESCR
         , gco_lib_functions.GetDescription2(POS.GCO_MANUFACTURED_GOOD_ID, DOC.PC_LANG_ID, 2, '01') POS_MAN_GOO_LONG_DESCR
         , gco_lib_functions.GetDescription2(POS.GCO_MANUFACTURED_GOOD_ID, DOC.PC_LANG_ID, 3, '01') POS_MAN_GOO_FREE_DESCR
         , gco_lib_functions.GetDicUnitOfMeasure(POS.GCO_MANUFACTURED_GOOD_ID, DOC.PC_LANG_ID) POS_MAN_DIC_UNIT_OF_MEASURE
         , POS.POS_NUMBER
         , POS.POS_SHORT_DESCRIPTION
         , POS.POS_LONG_DESCRIPTION
         , POS.POS_FREE_DESCRIPTION
         , LOT.FAL_LOT_ID
         , LOT.LOT_PLAN_END_DTE
         , LOT.LOT_PLAN_NUMBER
         , LOT.LOT_PLAN_VERSION
         , LOT.FAL_ORDER_ID
         , LOT_TOTAL_QTY
         , (select nvl(sum(SPO.SPO_STOCK_QUANTITY), 0)
              from STM_STOCK_POSITION SPO
                 , STM_STOCK STM
             where SPO.STM_STOCK_ID = STM.STM_STOCK_ID
               and SPO.GCO_GOOD_ID = FLML.GCO_GOOD_ID
               and STM.PAC_SUPPLIER_PARTNER_ID = DOC.PAC_THIRD_ID
               and STM.STO_SUBCONTRACT = 1) SPO_STOCK_QUANTITY
         , (select nvl(sum(SPO.SPO_ASSIGN_QUANTITY), 0)
              from STM_STOCK_POSITION SPO
                 , STM_STOCK STM
             where SPO.STM_STOCK_ID = STM.STM_STOCK_ID
               and SPO.GCO_GOOD_ID = FLML.GCO_GOOD_ID
               and STM.PAC_SUPPLIER_PARTNER_ID = DOC.PAC_THIRD_ID
               and STM.STO_SUBCONTRACT = 1) SPO_ASSIGN_QUANTITY
         , (select nvl(sum(SPO.SPO_AVAILABLE_QUANTITY), 0)
              from STM_STOCK_POSITION SPO
                 , STM_STOCK STM
             where SPO.STM_STOCK_ID = STM.STM_STOCK_ID
               and SPO.GCO_GOOD_ID = FLML.GCO_GOOD_ID
               and STM.PAC_SUPPLIER_PARTNER_ID = DOC.PAC_THIRD_ID
               and STM.STO_SUBCONTRACT = 1) SPO_AVAILABLE_QUANTITY
         , FLML.GCO_GOOD_ID FLML_GCO_GOOD_ID
         , gco_lib_functions.getMajorReference(FLML.GCO_GOOD_ID) FLML_GOO_MAJOR_REFERENCE
         , gco_lib_functions.GetNumberOfDecimal(FLML.GCO_GOOD_ID) FLML_GOO_NUMBER_OF_DECIMAL
         , gco_lib_functions.GetDicUnitOfMeasure(FLML.GCO_GOOD_ID, DOC.PC_LANG_ID) FLML_GOO_DIC_UNIT_OF_MEASURE
         , FLML.LOM_TEXT
         , FLML.FAL_LOT_MATERIAL_LINK_ID
         , FLML.LOM_ADJUSTED_QTY
         , FLML.LOM_BOM_REQ_QTY
         , FLML.LOM_NEED_QTY
         , FLML.LOM_CONSUMPTION_QTY
         , FLML.LOM_FULL_REQ_QTY
         , FLML.LOM_EXIT_RECEIPT
         , FLML.LOM_SECONDARY_REF
         , FLML.LOM_SHORT_DESCR
         , FLML.LOM_LONG_DESCR
         , FLML.LOM_FREE_DECR
         , gco_lib_functions.GetDescription2(FLML.GCO_GOOD_ID, DOC.PC_LANG_ID, 1, '01') FLML_GOO_SHORT_DESCR
         , gco_lib_functions.GetDescription2(FLML.GCO_GOOD_ID, DOC.PC_LANG_ID, 2, '01') FLML_GOO_LONG_DESCR
         , gco_lib_functions.GetDescription2(FLML.GCO_GOOD_ID, DOC.PC_LANG_ID, 3, '01') FLML_GOO_FREE_DESCR
         , FLML.LOM_NEED_DATE
         , FLML.LOM_SEQ
         , FLML.C_KIND_COM
         , RES.FAN_PIECE
         , RES.FAN_SET
         , RES.FAN_VERSION
         , RES.FAN_CHRONOLOGICAL
         , RES.FAN_STK_QTY
         , RES.FLN_QTY
         , RES.GCO_CHARACTERIZATION1_ID
         , RES.GCO_CHARACTERIZATION2_ID
         , RES.GCO_CHARACTERIZATION3_ID
         , RES.GCO_CHARACTERIZATION4_ID
         , RES.GCO_CHARACTERIZATION5_ID
      from DOC_DOCUMENT DOC
         , DOC_POSITION POS
         , FAL_LOT LOT
         , FAL_LOT_MATERIAL_LINK FLML
         , (select FNN.FAN_PIECE
                 , FNN.FAN_SET
                 , FNN.FAN_VERSION
                 , FNN.FAN_CHRONOLOGICAL
                 , FNN.FAN_STK_QTY
                 , FNN.GCO_CHARACTERIZATION1_ID
                 , FNN.GCO_CHARACTERIZATION2_ID
                 , FNN.GCO_CHARACTERIZATION3_ID
                 , FNN.GCO_CHARACTERIZATION4_ID
                 , FNN.GCO_CHARACTERIZATION5_ID
                 , FNN.FAL_LOT_MATERIAL_LINK_ID
                 , FNL.FLN_QTY
              from FAL_NETWORK_NEED FNN
                 , FAL_NETWORK_LINK FNL
                 , STM_STOCK STM
                 , STM_LOCATION LOC
                 , DOC_DOCUMENT DOC2
             where FNL.FAL_NETWORK_NEED_ID(+) = FNN.FAL_NETWORK_NEED_ID
               and LOC.STM_LOCATION_ID = FNL.STM_LOCATION_ID
               and STM.STM_STOCK_ID = LOC.STM_STOCK_ID
               and DOC2.PAC_THIRD_ID = STM.PAC_SUPPLIER_PARTNER_ID
               and DOC2.DMT_NUMBER = parameter_0) RES
     where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
       and LOT.FAL_LOT_ID = POS.FAL_LOT_ID
       and FLML.FAL_LOT_ID = LOT.FAL_LOT_ID
       and RES.FAL_LOT_MATERIAL_LINK_ID(+) = FLML.FAL_LOT_MATERIAL_LINK_ID
       and DOC.DMT_NUMBER = parameter_0;
end RPT_FAL_LOT_MATERIAL_EXIT_SCP;
