--------------------------------------------------------
--  DDL for Procedure C9_SET_ACT_VAT_DET_ACCOUNT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C9_SET_ACT_VAT_DET_ACCOUNT" (pRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
                                                       aFrom      in varchar2,
                                                       aTo        in varchar2,
                                                       pVatDetAccountId in varchar2)
is
begin
  if aFrom is not null and Length(Trim(aFrom)) > 0 then
    ACT_FUNCTIONS.DATE_FROM := to_date(aFrom, 'YYYYMMDD');
  end if;
  if aTo is not null  and Length(Trim(aTo)) > 0 then
    ACT_FUNCTIONS.DATE_TO   := to_date(aTo, 'YYYYMMDD');
  end if;
  if (pVatDetAccountId is not null) and (Length(Trim(pVatDetAccountId)) > 0) and (pVatDetAccountId <> '0') then
    ACT_FUNCTIONS.VAT_DET_ACC_ID  := pVatDetAccountId;
  end if;
  open pRefCursor for
   select 1 ID
   from DUAL;
end;
