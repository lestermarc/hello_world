--------------------------------------------------------
--  DDL for Procedure C9_SETV_ACT_EXPIRIES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C9_SETV_ACT_EXPIRIES" (aRefCursor       in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
                                                 aDate            in     varchar2,
                                                 aACC_NUMBER_From in     varchar2,
                                                 aACC_NUMBER_To   in     varchar2,
                                                 aBRO             in     varchar2,
                                                 aRateType        in     varchar2)
is
begin
  if (aDate is not null) and (Length(Trim(aDate)) > 0) then
    ACT_FUNCTIONS.ANALYSE_DATE       := to_date(aDate, 'YYYYMMDD');
  end if;
  if (aACC_NUMBER_From is not null) and (Length(Trim(aACC_NUMBER_From)) > 0)   then
    ACT_FUNCTIONS.ANALYSE_AUXILIARY1 := aACC_NUMBER_From;
  else
    ACT_FUNCTIONS.ANALYSE_AUXILIARY1 := ' ';
  end if;
  if (aACC_NUMBER_To is not null) and (Length(Trim(aACC_NUMBER_To)) > 0)   then
    ACT_FUNCTIONS.ANALYSE_AUXILIARY2 := aACC_NUMBER_To;
  else
    ACT_FUNCTIONS.ANALYSE_AUXILIARY2 := ' ';
  end if;
  if (aBRO is not null) and (Length(Trim(aBRO)) > 0)   then
    if aBRO = '1' then
      ACT_FUNCTIONS.BRO := 1;
    else
      ACT_FUNCTIONS.BRO := 0;
    end if;
  end if;

  if (aRateType is not null) and (Length(Trim(aRateType)) > 0)   then
    begin
      ACT_CURRENCY_EVALUATION.RATE_TYPE := to_number(aRateType);
    exception
      when INVALID_NUMBER then
        ACT_CURRENCY_EVALUATION.RATE_TYPE := 1;  -- Cours du jour
    end;
  end if;

  open aRefCursor for
    select 1 ID
      from DUAL;
end;
