--------------------------------------------------------
--  DDL for Procedure C8_SETV_ACT_IMPUTATION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C8_SETV_ACT_IMPUTATION" (aACC_NUMBER_From       in     varchar2,
                                                   aACC_NUMBER_To         in     varchar2,
                                                   aACS_FINANCIAL_YEAR_ID in     varchar2,
                                                   aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
is
begin
  ACR_FUNCTIONS.ACC_NUMBER1    := aACC_NUMBER_From;
  ACR_FUNCTIONS.ACC_NUMBER2    := aACC_NUMBER_To;
  ACR_FUNCTIONS.FIN_YEAR_ID    := aACS_FINANCIAL_YEAR_ID;
  if ACS_FUNCTION.GetFirstDivision is not null then
    ACR_FUNCTIONS.EXIST_DIVISION := 1;
  else
    ACR_FUNCTIONS.EXIST_DIVISION := 0;
  end if;
  open aRefCursor for
    select *
      from DUAL;
end;
