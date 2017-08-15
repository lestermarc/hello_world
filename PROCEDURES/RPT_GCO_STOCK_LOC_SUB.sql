--------------------------------------------------------
--  DDL for Procedure RPT_GCO_STOCK_LOC_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_STOCK_LOC_SUB" (arefcursor in out crystal_cursor_types.dualcursortyp, procParamdummy in varchar2 default null)
is
/**Description - used for report GCO_LIST_OF_GOODS_FOR_MANUAL_STOCK_CONTR

* @author SMA 25 SEP 2013
* @lastUpdate
* @public
*/
begin
  open arefcursor for
    select   STM.STO_DESCRIPTION
           , LOC.LOC_DESCRIPTION
        from STM_STOCK STM
           , STM_LOCATION LOC
       where STM.STM_STOCK_ID = LOC.STM_STOCK_ID
         and STM.C_ACCESS_METHOD = 'PUBLIC'
    order by STM.STO_DESCRIPTION
           , LOC.LOC_DESCRIPTION;
end RPT_GCO_STOCK_LOC_SUB;
