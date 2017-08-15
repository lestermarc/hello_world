--------------------------------------------------------
--  DDL for Procedure C9_SETV_PPS_NOMENCLATURE_ID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C9_SETV_PPS_NOMENCLATURE_ID" (aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
                                                         aNomId in varchar2)
is
begin

if length (trim(aNomId)) > 0 then
   PPS_INIT.PPS_NOMENCLATURE_ID := aNomId;
end if;

open aRefCursor for
     select 1 ID from DUAL;
end C9_SetV_PPS_NOMENCLATURE_ID;
