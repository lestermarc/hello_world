--------------------------------------------------------
--  DDL for Function IMP_CHECKCCP
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "IMP_CHECKCCP" (pRefNumber varchar2)
  return number
is
  type TtblCCP is table of varchar2(20)
    index by binary_integer;

  vtblCCP TtblCCP;
  vCont   varchar2(20);
  vKey    varchar2(2);
begin
  select column_value
  bulk collect into vtblCCP
    from table(charListToTable(pRefNumber, '-') );

  if vtblCCP.count = 3 then
    vCont  := lpad(vtblCCP(1), 2, '0') || lpad(vtblCCP(2), 6, '0');
    vKey   := vtblCCP(3);
  elsif vtblCCP.count = 1 then
    vCont  := lpad(substr(vtblCCP(1), 1, length(vtblCCP(1) ) - 1), 8, '0');
    vKey   := substr(vtblCCP(1), length(vtblCCP(1) ), 1);
  else
    return 0;
  end if;

  if ACS_FUNCTION.Modulo10(vCont) = vKey then
    return 1;
  else
    return 0;
  end if;
end IMP_CheckCCP;
