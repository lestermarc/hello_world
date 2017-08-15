--------------------------------------------------------
--  DDL for Procedure C8_SETV_ACT_EXPIRIES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C8_SETV_ACT_EXPIRIES" (aDate            in     varchar2,
                                                 aACC_NUMBER_From in     varchar2,
                                                 aACC_NUMBER_To   in     varchar2,
                                                 aBRO             in     varchar2,
                                                 aRateType        in     varchar2,
                                                 aRefCursor       in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
is
begin
  ACT_FUNCTIONS.ANALYSE_DATE       := to_date(aDate, 'yyyymmdd');
  ACT_FUNCTIONS.ANALYSE_AUXILIARY1 := aACC_NUMBER_From;
  ACT_FUNCTIONS.ANALYSE_AUXILIARY2 := aACC_NUMBER_To;
  if aBRO = '1' then
    ACT_FUNCTIONS.BRO := 1;
  else
    ACT_FUNCTIONS.BRO := 0;
  end if;
  begin
    ACT_CURRENCY_EVALUATION.RATE_TYPE := to_number(aRateType);
  exception
    when INVALID_NUMBER then
      ACT_CURRENCY_EVALUATION.RATE_TYPE := 1;  -- Cours du jour
  end;
  open aRefCursor for
    select *
      from DUAL;
end;
