--------------------------------------------------------
--  DDL for Procedure RPT_GCO_LIST_GOOD_MAN_ST_CONT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_LIST_GOOD_MAN_ST_CONT" (arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type)
is
/**
 Description - used for the report GCO_LIST_OF_GOODS_FOR_MANUAL_STOCK_CONTR

* @author SMA 25 SEP 2013
* @lastupdate
* @public
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select GOO.GOO_MAJOR_REFERENCE
         , GCO_LIB_FUNCTIONS.GetDescription(GOO.GCO_GOOD_ID, procuser_lanid, 1, null) DES_SHORT_DESCRIPTION
      from GCO_GOOD GOO
         , GCO_PRODUCT PDT
     where GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and PDT.PDT_STOCK_MANAGEMENT = '1';
end rpt_gco_list_good_man_st_cont;
