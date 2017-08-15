--------------------------------------------------------
--  DDL for Package Body HRM_SHIFT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_SHIFT" 
IS

function SHIFTVAL(
  shiftCode IN VARCHAR2,
  valSource IN VARCHAR2)
  return VARCHAR2
is
  tmp varchar2(20);
  cursor c1 is
    select BSV_VALUE
      from HRM_BREAK_SHIFT_VAL
     where BSV_CODE=shiftcode
       and BSV_SOURCE_VAL=valSource;
begin
  open c1;
  loop
    fetch c1 INTO tmp;
    exit when c1%NOTFOUND;
  end loop;
  return tmp;

  exception
    when OTHERS then
      return null;
end;

function ADDCONC(
  ShiftOperationType IN VARCHAR2,
  accname IN VARCHAR2,
  shiftname IN VARCHAR2)
  return VARCHAR2
is
begin
  if (ShiftOperationType='ADD') then
    return to_number(accname) + to_number(shiftname);
  elsif (ShiftOperationType='CONC') then
    return accname || shiftname;
  elsif (ShiftOperationType='PREF') then
    return shiftname || accname;
  else
    raise_application_error(-20000, 'Invalid operation type ('||ShiftOperationType||')');
    return null;
  end if;
end;

END HRM_SHIFT;
