--------------------------------------------------------
--  DDL for Procedure SETV_PPS_NOMENCLATURE_ID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "SETV_PPS_NOMENCLATURE_ID" (aNomId varchar2)
is
begin
PPS_INIT.PPS_NOMENCLATURE_ID := aNomId;
end SetV_PPS_NOMENCLATURE_ID;
