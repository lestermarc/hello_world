--------------------------------------------------------
--  DDL for Procedure C8_SETV_PPS_NOMENCLATURE_ID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C8_SETV_PPS_NOMENCLATURE_ID" (aNomId in varchar2,
                                                         aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
is
begin
PPS_INIT.PPS_NOMENCLATURE_ID := aNomId;
open aRefCursor for
     select * from DUAL;
end C8_SetV_PPS_NOMENCLATURE_ID;
