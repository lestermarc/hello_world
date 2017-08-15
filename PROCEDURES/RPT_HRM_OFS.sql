--------------------------------------------------------
--  DDL for Procedure RPT_HRM_OFS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_OFS" (
  aRefCursor     in out crystal_cursor_types.DualCursorTyp
, procparam_0           number
, procparam_1           number
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
* description used for report HRM_LPP.rpt
* @author rhe, ire
* @created 08/2007
* @renamed vha 05.12.2013
* @lastUpdate SMA 25.09.2014
* @public
* @param procparam_0  Id List
* @param procparam_1  Année
*/
begin
  HRM_REP_LIST.OfsList(aRefCursor, procparam_0, procparam_1, procuser_lanid);
end;
