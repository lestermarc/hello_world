--------------------------------------------------------
--  DDL for Procedure SETV_GCO_GOOD_ID
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "SETV_GCO_GOOD_ID" (aGoodId varchar2)
is
begin
PPS_INIT.GCO_GOOD_ID := aGoodId;
end SetV_GCO_GOOD_ID;
