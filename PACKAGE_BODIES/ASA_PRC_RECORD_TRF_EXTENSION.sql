--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_TRF_EXTENSION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_TRF_EXTENSION" 
/**
 * Extension et personnalisation de l'importation de dossiers SAV transféré.
 *
 * @version 1.0
 * @date 06/2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

--
-- internal implementation
--

procedure p_internal_call(
  iv_cmd IN VARCHAR2)
is
  lv_cmd VARCHAR2(32767);
begin
  lv_cmd :=
    'DECLARE '||
      'lt_ctx asa_typ_record_trf_def.T_MERGE_CONTEXT := asa_prc_record_trf_extension.gt_ctx;'||
      'lt_asf asa_typ_record_trf_def.T_AFTER_SALES_FILE  := asa_prc_record_trf_extension.gt_asf;'||Chr(10)||
    'BEGIN'||Chr(10)||
      Replace(
        Replace(
          Replace(Trim(iv_cmd),
            '['||'COMPANY_OWNER]', pcs.PC_I_LIB_SESSION.GetCompanyOwner),
          co.cCompanyOwner, pcs.PC_I_LIB_SESSION.GetCompanyOwner),
        co.cPcsOwner, 'PCS') ||'(lt_ctx, lt_asf);'||Chr(10)||
      'asa_prc_record_trf_extension.gt_asf := lt_asf;'||Chr(10)||
    'END;';
  --dbms_output.put_line(lv_cmd);
  execute immediate
    lv_cmd;
end;

procedure p_execute(
  iv_cmd IN VARCHAR2,
  it_context IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_after_sales_file IN OUT NOCOPY asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
begin
  -- initialisation des variables globales
  gt_ctx := it_context;
  gt_asf := iot_after_sales_file;

  -- appel de la méthode individualisée
  p_internal_call(iv_cmd);

  -- récupération du record (éventuellement modifié)
  -- mise à nul des variables globales
  gt_ctx := null;
  iot_after_sales_file := gt_asf;
  gt_asf := null;

  exception
    when OTHERS then
      gt_ctx := null;
      gt_asf := null;
      raise;
end;

--
-- public implementation
--

procedure Execute(
  it_context IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_after_sales_file IN OUT NOCOPY asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
  lv_cmd VARCHAR2(128);
begin
  lv_cmd := pcs.pc_config.GetConfig('ASA_RECORD_TRF_PROC_CUST');
  if (lv_cmd is not null) then
    p_execute(lv_cmd, it_context, iot_after_sales_file);
  end if;
end;


procedure execute_before_import(
  it_context IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  it_after_sales_file IN asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
  lv_cmd VARCHAR2(128);
  lt_SAV asa_typ_record_trf_def.T_AFTER_SALES_FILE;
begin
  lv_cmd := pcs.pc_config.GetConfig('ASA_RECORD_TRF_PROC_BEFORE_IMP');
  if (lv_cmd is not null) then
    lt_SAV := it_after_sales_file;
    p_execute(lv_cmd, it_context, lt_SAV);
  end if;
end;

procedure execute_after_import(
  it_context IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  it_after_sales_file IN asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
  lv_cmd VARCHAR2(128);
  lt_SAV asa_typ_record_trf_def.T_AFTER_SALES_FILE;
begin
  lv_cmd := pcs.pc_config.GetConfig('ASA_RECORD_TRF_PROC_AFTER_IMP');
  if (lv_cmd is not null) then
    lt_SAV := it_after_sales_file;
    p_execute(lv_cmd, it_context, lt_SAV);
  end if;
end;


function control_transfert(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return INTEGER
is
  lv_cmd VARCHAR(128);
  ln_result NUMBER;
begin
  lv_cmd := pcs.pc_config.GetConfig('ASA_RECORD_TRF_PROC_CONTROL');
  if (lv_cmd is not null) then
    -- exécution de la procédure avant envoi
    execute immediate
      'BEGIN '||
        ':on_result := '||lv_cmd||'(:in_record_id); ' ||
      'END;'
      using out ln_result,
            in in_record_id;
    return ln_result;
  end if;
  return 1;
end;


function get_task_price(
  in_rep_type_id IN asa_rep_type.asa_rep_type_id%TYPE,
  in_good_to_repair_id IN asa_rep_type_good.gco_good_to_repair_id%TYPE,
  in_good_to_bill_id IN asa_rep_type_task.gco_bill_good_id%TYPE,
  in_task_id IN fal_task.fal_task_id%TYPE)
  return asa_rep_type_task.rtt_amount%TYPE
is
  lv_cmd VARCHAR(128);
  ln_result asa_rep_type_task.rtt_amount%TYPE;
begin
  lv_cmd := pcs.pc_config.GetConfig('ASA_RECORD_TRF_PROC_TASK_PRICE');
  if (lv_cmd is not null) then
    -- exécution de la fonction de calcul spécifique
    execute immediate
      'BEGIN '||
        ':on_result := '||lv_cmd||'(:in_rep_type_id,:in_good_to_repair_id,:in_good_to_bill_id,:in_task_id); ' ||
      'END;'
      using out ln_result,
            in in_rep_type_id,
            in in_good_to_repair_id,
            in in_good_to_bill_id,
            in in_task_id;
    return ln_result;
  end if;

  -- méthode de calcul standard
  return asa_lib_record_trf.get_task_price(in_rep_type_id, in_good_to_repair_id, in_good_to_bill_id, in_task_id);
end;

function format_explanation(
  in_record_id IN asa_record.asa_record_id%TYPE,
  iv_explanation IN VARCHAR2)
  return VARCHAR2
is
begin
  return
    '['||pcs.PC_I_LIB_SESSION.GetUserName ||' '|| to_char(Sysdate,'DD.MM.YYYY HH24:MI:SS') ||']' ||Chr(10)||
    RTrim(iv_explanation,' '||Chr(13)||Chr(10));
end;

END ASA_PRC_RECORD_TRF_EXTENSION;
