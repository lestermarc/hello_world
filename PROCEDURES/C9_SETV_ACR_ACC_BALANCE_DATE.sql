--------------------------------------------------------
--  DDL for Procedure C9_SETV_ACR_ACC_BALANCE_DATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C9_SETV_ACR_ACC_BALANCE_DATE" (aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
                                                         aACC_NUMBER_From       in     varchar2,
                                                         aACC_NUMBER_To         in     varchar2,
                                                         aACS_FINANCIAL_YEAR_ID in     varchar2,
                                                         aCUMUL_DATE            in     varchar2,
                                                         aCUMUL_DATE_FROM       in     varchar2)
is
begin
  if (aACC_NUMBER_From is not null) and (Length(Trim(aACC_NUMBER_From)) > 0) then
    ACR_FUNCTIONS.ACC_NUMBER1     := aACC_NUMBER_From;
  else
    ACR_FUNCTIONS.ACC_NUMBER1     := ' ';
  end if;
  if (aACC_NUMBER_To is not null) and (Length(Trim(aACC_NUMBER_To)) > 0) then
    ACR_FUNCTIONS.ACC_NUMBER2     := aACC_NUMBER_To;
  end if;
  if (aACS_FINANCIAL_YEAR_ID is not null) and (Length(Trim(aACS_FINANCIAL_YEAR_ID)) > 0) then
    ACR_FUNCTIONS.FIN_YEAR_ID     := aACS_FINANCIAL_YEAR_ID;
  end if;
  if (aCUMUL_DATE is not null) and (Length(Trim(aCUMUL_DATE)) > 0) then
    ACR_FUNCTIONS.CUMUL_DATE      := to_date(aCUMUL_DATE, 'yyyymmdd');
  end if;
  if (aCUMUL_DATE_FROM is not null) and (Length(Trim(aCUMUL_DATE_FROM)) > 0) then
    ACR_FUNCTIONS.CUMUL_DATE_FROM := to_date(aCUMUL_DATE_FROM, 'yyyymmdd');
  end if;
  if ACS_FUNCTION.GetFirstDivision is not null then
    ACR_FUNCTIONS.EXIST_DIVISION := 1;
  else
    ACR_FUNCTIONS.EXIST_DIVISION := 0;
  end if;
  open aRefCursor for
    select 1 ID
      from DUAL;
end;
