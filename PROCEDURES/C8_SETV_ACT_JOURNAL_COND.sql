--------------------------------------------------------
--  DDL for Procedure C8_SETV_ACT_JOURNAL_COND
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C8_SETV_ACT_JOURNAL_COND" (aJOU_NUMBER_From       in     varchar2,
                                                     aJOU_NUMBER_To         in     varchar2,
                                                     aACS_FINANCIAL_YEAR_ID in     varchar2,
                                                     aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
is
begin
  ACR_FUNCTIONS.JOU_NUMBER1 := aJOU_NUMBER_From;
  ACR_FUNCTIONS.JOU_NUMBER2 := aJOU_NUMBER_To;
  ACR_FUNCTIONS.FIN_YEAR_ID := aACS_FINANCIAL_YEAR_ID;
  open aRefCursor for
    select *
      from DUAL;
end;
