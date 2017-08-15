--------------------------------------------------------
--  DDL for Procedure RPT_HRM_LPP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_LPP" (
  aRefCursor     in out crystal_cursor_types.DualCursorTyp
, procparam_0           number
, procparam_1           number
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
* description used for report HRM_LPP.rpt
* @author rhe, ire
* @created 07/2007
* @renamed vha NOV 2011
* @lastUpdate VHA 05.05.2014
* @public
* @param procparam_0  Id List
* @param procparam_1  Année
*/
begin
  HRM_REP_LIST.LppList(aRefCursor, procparam_0, procparam_1, procuser_lanid);
end;
