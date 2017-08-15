--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ORDER_MAT_EX_CUM_BATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ORDER_MAT_EX_CUM_BATCH" (
  arefcursor        in out crystal_cursor_types.dualcursortyp
, procuser_lanid    in     pcs.pc_lang.lanid%type
, proccompany_owner in     pcs.pc_scrip.scrdbowner%type
, proccompany_name  in     pcs.pc_comp.com_name%type
, parameter_0       in     varchar2
)
is
/**
*Description
        Used for report FAL_ORDER_MATERIAL_EXIT_CUM_BATCH

*@created SMA 16 SEPT 2014
*@lastUpdate
*@public
*@param parameter_0    FAL_LOT_ID
*@param PROCUSER_LANID : user language
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type   := null;
  vOrderId    FAL_ORDER.FAL_ORDER_ID%type;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  -- Le rapport ne gère pas des ordres différents
  select max(FAL_ORDER_ID)
    into vOrderId
    from FAL_LOT
   where instr(',' || parameter_0 || ',', ',' || FAL_LOT_ID || ',') > 0;

  open arefcursor for
    select   ORD.FAL_ORDER_ID
           , LOM.LOM_LONG_DESCR
           , LOM.LOM_FREE_DECR
           , LOM.LOM_SHORT_DESCR
           , LOM.LOM_SECONDARY_REF
           , CPT.GOO_MAJOR_REFERENCE
           , LOM.LOM_FULL_REQ_QTY
           , LOM.LOM_CONSUMPTION_QTY
           , LOM.LOM_NEED_QTY
           , CPT.DIC_UNIT_OF_MEASURE_ID
           , LOM.FAL_LOT_MATERIAL_LINK_ID
           , LOM.LOM_SEQ
           , CPT.GOO_NUMBER_OF_DECIMAL
           , LOM.C_KIND_COM
           , LOM.C_TYPE_COM
           , JOP.JOP_REFERENCE
           , ORD.ORD_REF
           , LOT.FAL_LOT_ID
        from FAL_JOB_PROGRAM JOP
           , FAL_ORDER ORD
           , FAL_LOT LOT
           , FAL_LOT_MATERIAL_LINK LOM
           , GCO_GOOD CPT
       where JOP.FAL_JOB_PROGRAM_ID = ORD.FAL_JOB_PROGRAM_ID
         and ORD.FAL_ORDER_ID = LOT.FAL_ORDER_ID
         and LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
         and LOM.GCO_GOOD_ID(+) = CPT.GCO_GOOD_ID
         and LOM.C_KIND_COM(+) = '1'
         and LOM.C_TYPE_COM(+) = '1'
         and ORD.FAL_ORDER_ID = vOrderId
    order by ORD.FAL_ORDER_ID
           , CPT.GOO_MAJOR_REFERENCE;
end RPT_FAL_ORDER_MAT_EX_CUM_BATCH;
