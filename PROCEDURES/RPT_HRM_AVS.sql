--------------------------------------------------------
--  DDL for Procedure RPT_HRM_AVS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_AVS" (
    aRefCursor in out crystal_cursor_types.DualCursorTyp
  , procparam_0 number
  , procparam_1 number
)
is
/**
* description used for report HRM_AVS.rpt
* @author rhe, ire
* @created 07/2007
* @lastUpdate VHA 06.05.2014
* @public
* @param procparam_0  Id List
* @param procparam_1  Année
*/
begin
  HRM_REP_LIST.AvsList(aRefCursor, procparam_0, procparam_1);
end;
