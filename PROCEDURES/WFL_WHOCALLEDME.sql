--------------------------------------------------------
--  DDL for Procedure WFL_WHOCALLEDME
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "WFL_WHOCALLEDME" (aOwner out Varchar2,
                                            aName out Varchar2,
                                            aLineNum out Number,
                                            aType out Varchar2)
is
  cCallStack  Varchar2(4000) default dbms_utility.format_call_stack;
  nNum Number;
  bFoundStack Boolean default False;
  cLine Varchar2(255);
  nCnt Number := 0;
begin
  loop
    nNum := Instr(cCallStack,chr(10));
    exit when (nCnt=3 or nNum is NULL or nNum = 0);

    cLine := Substr(cCallStack,1,nNum-1);
    cCallStack := Substr(cCallStack,nNum+1);
    if (not bFoundStack) then
      if (cLine like '%handle%number%name%') then
        bFoundStack := True;
      end if;
    else
      nCnt := nCnt+1;

      -- line is like : 0x56b84cf0       103  package body WFL_WORKFLOW_MANAGEMENT.PL_FLOW
      --
      -- nCnt = 1 is ME
      --
      -- nCnt = 2 is MY Caller
      --
      -- nCnt = 3 is Their Caller
      if (nCnt = 3) then
        aLineNum := To_Number(Substr(cLine,11,10));
        cLine := Substr(cLine,23);

        if (cLine like 'pr%') then
          nNum := Length('procedure ');
        elsif (cLine like 'fun%') then
          nNum := Length('function ');
        elsif (cLine like 'package body%') then
          nNum := Length('package body ');
        elsif (cLine like 'pack%') then
          nNum := Length('package ');
        elsif (cLine like 'anonymous%') then
          nNum := Length('anonymous block ');
        else
          nNum := null;
        end if;

        if (nNum is not null) then
          aType := LTrim(RTrim(Upper(Substr(cLine, 1, nNum-1))));
        else
          aType := 'TRIGGER';
        end if;

        cLine := Substr(cLine,nvl(nNum,1));
        nNum := Instr(cLine,'.');
        aOwner := LTrim(RTrim(Substr(cLine,1,nNum-1)));
        aName := LTrim(RTrim(Substr(cLine,nNum+1)));
      end if;
    end if;
  end loop;
end;
