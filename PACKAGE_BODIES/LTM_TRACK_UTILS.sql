--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_UTILS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_UTILS" 
/**
 * Package utilitaire pour le suivi de modifications.
 *
 * @version 1.0
 * @date 01/2009
 * @author spfister
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
AS

  -- package private global constants
  gcv_DEF_DATE_FORMAT CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';


--
-- Public methods
--

function GetDefaultDateFormat return VARCHAR2 is
begin
  return gcv_DEF_DATE_FORMAT;
end;

/**
 * @deprecated Use pcs.pc_lib_nls_parameters.DateFormat
 */
function GetDateFormat return VARCHAR2
is
begin
  return pcs.pc_lib_nls_parameters.DateFormat;
end;

/**
 * @deprecated Use pcs.pc_lib_nls_parameters.SetDateFormat
 */
function SetDateFormat(DateFormat IN VARCHAR2) return VARCHAR2
is
begin
  return pcs.pc_lib_nls_parameters.SetDateFormat(DateFormat);
end;

function FormatDate(Value IN VARCHAR2) return DATE is
begin
  if (value is not null) then
    begin
      return to_date(value, gcv_DEF_DATE_FORMAT);
      exception
        when OTHERS then null;
    end;
    begin
      return to_date(value);
      exception
        when OTHERS then null;
    end;
  end if;
  return null;
end;

function FormatDate(Value IN DATE) return VARCHAR2 is
begin
  if (value is not null) then
    begin
      return to_char(value, gcv_DEF_DATE_FORMAT);
      exception
        when OTHERS then null;
    end;
  end if;
  return null;
end;

END LTM_TRACK_UTILS;
