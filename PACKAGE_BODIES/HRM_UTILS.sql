--------------------------------------------------------
--  DDL for Package Body HRM_UTILS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_UTILS" 
IS

  -- private constant for boolean String value
  DEF_TRUE_STR CONSTANT VARCHAR2(4) := 'True';
  DEF_FALSE_STR CONSTANT VARCHAR2(5) := 'False';
  -- private variable that hold True and False String value
  p_TrueBoolStr VARCHAR2(10);
  p_FalseBoolStr VARCHAR2(10);

function get_TrueBoolStr return VARCHAR2 is
begin
  return p_TrueBoolStr;
end;
procedure set_TrueBoolStr(TrueBoolStr IN VARCHAR2) is
begin
  p_TrueBoolStr := case
    when TrueBoolStr is null then DEF_TRUE_STR
    else Substr(TrueBoolStr, 1, 10)
  end;
end;

function get_FalseBoolStr return VARCHAR2 is
begin
  return p_FalseBoolStr;
end;
procedure set_FalseBoolStr(FalseBoolStr IN VARCHAR2) is
begin
  p_FalseBoolStr := case
    when FalseBoolStr is null then DEF_FALSE_STR
    else Substr(FalseBoolStr, 1, 10)
  end;
end;

function BoolToStr(p IN NUMBER) return VARCHAR2 is
begin
  return BoolToStr(p > 0.0);
end;
function BoolToStr(p IN BOOLEAN) return VARCHAR2 is
begin
  return case when (p is not null and p)
    then p_TrueBoolStr
    else p_FalseBoolStr
  end;
end;

function ConvertToSearchText(S IN VARCHAR2) return VARCHAR2 is
begin
  return Replace(
    Translate(Upper(S), 'баюдцйихк─нмлотсржушзыэщг', 'AAAAAEEEEEIIIIOOOOOUUUUYC'),
    '''');
end;

BEGIN
  p_TrueBoolStr := DEF_TRUE_STR;
  p_FalseBoolStr := DEF_FALSE_STR;
END HRM_UTILS;
