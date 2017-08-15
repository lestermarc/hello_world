--------------------------------------------------------
--  DDL for Procedure RPT_HRM_LAA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_LAA" (
  aRefCursor     in out crystal_cursor_types.DualCursorTyp
, procparam_0           number
, procparam_1           number
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
* description used for report HRM_LAA.rpt
* @author rhe, ire
* @created 07/2007
* @renamed vha 05.12.2013
* @lastUpdate vha 05.05.2014
* @public
* @param procparam_0  Id List
* @param procparam_1  Année
*/
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type   := null;
begin
  if (procuser_lanid is not null) then
    PCS.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    vpc_lang_id  := PCS.PC_I_LIB_SESSION.GetUserLangId;
  end if;

  HRM_REP_LIST.LaaList(aRefCursor, procparam_0, procparam_1, 0, vpc_lang_id);
end;
