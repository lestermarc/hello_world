--------------------------------------------------------
--  DDL for Package Body REP_LIB_NLS_PARAMETERS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_LIB_NLS_PARAMETERS" 
/**
 * Package utilitaire de gestion des paramètres NLS (National Language Support)
 * de globalisation spécifique à la réplication.
 *
 * @version 1.0
 * @date 01/2011
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

  /** Format standard des numériques. */
  gv_prev_numeric_fmt pcs.pc_lib_nls_parameters.NLS_NAME;
  /** Format standard des dates. */
  gv_prev_date_fmt pcs.pc_lib_nls_parameters.NLS_NAME;
  /** Format standard des date longues. */
  gv_prev_timestamp_fmt pcs.pc_lib_nls_parameters.NLS_NAME;


procedure SetNLSFormat
is
begin
  if (gv_prev_numeric_fmt is null) then
    gv_prev_numeric_fmt := pcs.pc_lib_nls_parameters.SetNumericFormat('.,');
  end if;
  if (gv_prev_date_fmt is null) then
    gv_prev_date_fmt := pcs.pc_lib_nls_parameters.SetDateFormat(rep_utils.GetReplicatorDateFormat);
  end if;
  if (gv_prev_timestamp_fmt is null) then
    gv_prev_timestamp_fmt := pcs.pc_lib_nls_parameters.SetTimeStampFormat(rep_utils.GetReplicatorDateFormat);
  end if;
end;

procedure ResetNLSFormat
is
  lv_tmp pcs.pc_lib_nls_parameters.NLS_NAME;
begin
  if (gv_prev_numeric_fmt is not null) then
    lv_tmp := pcs.pc_lib_nls_parameters.SetNumericFormat(gv_prev_numeric_fmt);
    gv_prev_numeric_fmt := null;
  end if;
  if (gv_prev_date_fmt is not null) then
    lv_tmp := pcs.pc_lib_nls_parameters.SetDateFormat(gv_prev_date_fmt);
    gv_prev_date_fmt := null;
  end if;
  if (gv_prev_timestamp_fmt is not null) then
    lv_tmp := pcs.pc_lib_nls_parameters.SetTimeStampFormat(gv_prev_timestamp_fmt);
    gv_prev_timestamp_fmt := null;
  end if;
end;

END REP_LIB_NLS_PARAMETERS;
