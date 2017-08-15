--------------------------------------------------------
--  DDL for Procedure C9_SETINTERVALDATES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C9_SETINTERVALDATES" (aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
                                                aFrom      in varchar2,
                                                aTo        in varchar2)
is
begin
  if (aFrom is not null) and (Length(Trim(aFrom)) > 0) then
    ACT_FUNCTIONS.DATE_FROM := to_date(aFrom, 'yyyymmdd');
  end if;
  if (aTo is not null) and (Length(Trim(aTo)) > 0) then
    ACT_FUNCTIONS.DATE_TO   := to_date(aTo, 'yyyymmdd');
  end if;
  open aRefCursor for
    select 1 ID
      from DUAL;
end;
