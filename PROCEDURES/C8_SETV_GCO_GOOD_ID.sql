--------------------------------------------------------
--  DDL for Procedure C8_SETV_GCO_GOOD_ID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C8_SETV_GCO_GOOD_ID" (aGoodId in varchar2,
                                                 aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
is
begin
PPS_INIT.GCO_GOOD_ID := aGoodId;
open aRefCursor for
     select * from DUAL;

end C8_SetV_GCO_GOOD_ID;
