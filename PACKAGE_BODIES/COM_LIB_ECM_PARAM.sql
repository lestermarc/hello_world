--------------------------------------------------------
--  DDL for Package Body COM_LIB_ECM_PARAM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_ECM_PARAM" 
/**
 * Paramètres d'exécution pour la gestion électronique de documents.
 *
 * @version 1.0
 * @date 11/2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
IS

  TYPE tt_params IS TABLE OF VARCHAR2(32767) INDEX BY VARCHAR2(32);
  gcv_params TT_PARAMS;


function Get(
  iv_name IN fwk_i_typ_definition.DEF_NAME)
  return VARCHAR2
is
begin
  if gcv_params.EXISTS(iv_name) then
    return gcv_params(iv_name);
  end if;
  return null;
end;
procedure Set(
  iv_name IN fwk_i_typ_definition.DEF_NAME,
  iv_value IN VARCHAR2)
is
begin
  gcv_params(iv_name) := iv_value;
end;

function Contains(
  iv_name IN fwk_i_typ_definition.DEF_NAME)
  return BOOLEAN
is
begin
  return gcv_params.EXISTS(iv_name);
end;

function IsNull(
  iv_name IN fwk_i_typ_definition.DEF_NAME)
  return BOOLEAN
is
begin
  if gcv_params.EXISTS(iv_name) then
    return gcv_params(iv_name) is null;
  end if;
  return FALSE;
end;

procedure Delete(
  iv_name IN fwk_i_typ_definition.DEF_NAME)
is
begin
  if gcv_params.EXISTS(iv_name) then
    gcv_params.DELETE(iv_name);
  end if;
end;
procedure Delete
is
begin
  gcv_params.DELETE;
end;


function List
  return TT_PARAMETERS
  pipelined
is
  lv_name fwk_i_typ_definition.DEF_NAME;
  lt_parameter T_PARAMETER;
begin
  lv_name := gcv_params.FIRST;
  if (lv_name is not null) then
    loop
      lt_parameter.name := lv_name;
      lt_parameter.value := gcv_params(lv_name);
      PIPE ROW(lt_parameter);
      lv_name := gcv_params.NEXT(lv_name);
      exit when lv_name is null;
    end loop;
  end if;
  return;

  exception
    when NO_DATA_NEEDED then
      return;
end;

END COM_LIB_ECM_PARAM;
