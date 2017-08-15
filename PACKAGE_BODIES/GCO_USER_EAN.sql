--------------------------------------------------------
--  DDL for Package Body GCO_USER_EAN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_USER_EAN" 
is
  function EAN_GEN_001(C_GENRE in number, GOOD_ID in number)
    return varchar2
  is
    C_EAN varchar2(13);
  begin
    return null;
  end;

  function EAN_CTRL_001(C_GENRE in number, C_EAN in varchar2)
    return integer
  is
    test integer default 0;
  begin
    if C_EAN is null then
      test  := 1;
    else
      test  := 1;
    end if;

    return test;
  end;
end GCO_USER_EAN;
