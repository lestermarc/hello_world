--------------------------------------------------------
--  DDL for Procedure C9_SETV_GCO_GOOD_ID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C9_SETV_GCO_GOOD_ID" (aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
                                                 aGoodId in varchar2)
is
begin
if length (trim(aGoodId)) > 0 then
   PPS_INIT.GCO_GOOD_ID := aGoodId;
end if;

open aRefCursor for
     select 1 ID from DUAL;

end C9_SetV_GCO_GOOD_ID;
