--------------------------------------------------------
--  DDL for Procedure RPT_FAL_COMPONENTS_BATCHES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_COMPONENTS_BATCHES" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, procuser_lanid in     pcs.pc_lang.lanid%type
, procparam_0    in     varchar2
)
is
/**
* Description - Used in report FAL_COMPONENTS_BATCHES

* Stored procedure used by the report FAL_COMPONENTS_BATCHES
* @created   SMA 26 April 2013
* Modified
* lastUpdate
* @param procparam_0    Job_id (COM_LIST)  -> Liste FAL_LOT_MATERIAL_LINK_ID
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;
  -- Calculer les quantités stock
  rpt_functions.ComponentsCalculateStock(to_number(procparam_0) );

  open arefcursor for
    select   LOM.FAL_LOT_MATERIAL_LINK_ID
           , GOO.GCO_GOOD_ID
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , LOT.FAL_LOT_ID
           , LOT.LOT_PLAN_BEGIN_DTE
           , LOT.LOT_REFCOMPL
           , LOM.LOM_BOM_REQ_QTY
           , LOM.LOM_NEED_DATE
           , LOM.LOM_NEED_QTY
           , LID.LID_FREE_NUMBER_3 AVAILABLE_STOCK
           , LID.LID_FREE_NUMBER_2 WORKSHOP_STOCK
           , LID.LID_FREE_NUMBER_4 MISS_COMPONENT
           , LID2.LID_ID_2 FAL_NETWORK_SUPPLY_ID
           , LID2.LID_FREE_CHAR_1 FAN_DESCRIPTION
           , LID2.LID_FREE_NUMBER_1 FAN_BALANCE_QTY
           , LID2.LID_FREE_DATE_1 FAN_END_PLAN
        from COM_LIST_ID_TEMP LID
           , FAL_LOT LOT
           , FAL_LOT_MATERIAL_LINK LOM
           , GCO_GOOD GOO
           , COM_LIST_ID_TEMP LID2
       where LID.LID_ID_3 = LOM.FAL_LOT_MATERIAL_LINK_ID
         and LID.LID_CODE = 'COMPONENT_MATERIAL_LINK'
         and LID.LID_ID_2 = GOO.GCO_GOOD_ID
         and LID.LID_ID_1 = LOT.FAL_LOT_ID
         and LID2.LID_CODE(+) = 'COMPONENT_MATERIAL_LINK_SUPPLY'
         and LID2.LID_ID_1(+) = LID.LID_ID_3
    order by GOO.GOO_MAJOR_REFERENCE
           , LOT.LOT_PLAN_BEGIN_DTE
           , LID2.LID_FREE_DATE_1
           , LID2.LID_ID_2;

  -- Effacer la liste des lots à traiter
  COM_PRC_LIST.DeleteIDList(aJobId => to_number(procparam_0), aSession => null, aCode => 'COMPONENTS_BATCHES');
end RPT_FAL_COMPONENTS_BATCHES;
