--------------------------------------------------------
--  DDL for Package Body HRM_BREAK_TRANSFER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_BREAK_TRANSFER" 
AS

  -- Cusor for accessing Break (HRM_BREAK) fields
  cursor csBreak(IdBreak number) is
    select * from hrm_break where hrm_break_id = IdBreak;
  -- Record for accessing Break's fields
  rBreak csBreak%rowtype;
  -- Config HRM_BREAK_COM_NAME_ACT
  BREAK_COM_NAME ACI_DOCUMENT.COM_NAME_ACT%TYPE;

/**
 * Initialisation des infos de la ventilation
 */
procedure set_BreakData(vBreakId IN hrm_break.hrm_break_id%TYPE)
is
begin
  open csBreak(vBreakId);
  fetch csBreak into rBreak;
  close csBreak;
end set_BreakData;

/**
 * Création du document dans l'ACI
 * (la création du statut du document se fait après le transfert à cause du trigger
 *  'ACI_DST_AIU_FINANCIAL_LINK' (intégration financière immédiate))
 */
procedure Aci_Doc_Create(
  vFinCurrId IN acs_financial_currency.acs_financial_currency_id%TYPE,
  vAciDocId OUT aci_document.aci_document_id%TYPE)
is
  JobType aci_document.acj_job_type_s_catalogue_id%TYPE;
  CatKey aci_document.cat_key%TYPE;
  TypKey aci_document.typ_key%TYPE;
  eJobTypeUnknown exception;
  eCatKeyUnknown exception;
  Currency aci_document.currency%TYPE;
begin
  -- Recherche du JobType
  select ss.acj_job_type_s_catalogue_id, currency into JobType, Currency
  from hrm_salary_sheet ss,  acs_financial_currency ac, pcs.pc_curr cu, hrm_break b
  where ss.hrm_salary_sheet_id = b.hrm_salary_sheet_id and
    b.hrm_break_id = rBreak.hrm_break_id and
    b.acs_financial_currency_id = ac.acs_financial_currency_id and
    ac.pc_curr_id = cu.pc_curr_id;
  if JobType is null then
    raise eJobTypeUnknown;
  end if;

  -- Recherche de la catégorie
  begin
    select c.cat_key, j.typ_key into CatKey, TypKey
    from acj_catalogue_document c, acj_job_type_s_catalogue t,
      hrm_salary_sheet ss, acj_job_type j, hrm_break b
    where
      b.hrm_break_id = rBreak.hrm_break_id and
      ss.hrm_salary_sheet_id = b.hrm_salary_sheet_id and
      t.acj_job_type_s_catalogue_id = ss.acj_job_type_s_catalogue_id and
      c.acj_catalogue_document_id = t.acj_catalogue_document_id and
      j.acj_job_type_id = t.acj_job_type_id;
    if CatKey is null then
      raise eCatKeyUnknown;
    end if;
  exception
    when no_data_found then
      raise eCatKeyUnknown;
  end;

  -- Vérification si intégration dans un shéma distinct
  BREAK_COM_NAME := pcs.pc_public.getconfig('HRM_BREAK_COM_NAME_ACT');
  if BREAK_COM_NAME = PCS.PC_I_LIB_SESSION.getComName() then
    BREAK_COM_NAME := '';
  end if;

  -- Création du document
  select aci_id_seq.nextval into vAciDocId from dual;
  insert into aci_document(
    aci_document_id,
    c_interface_origin,
    c_interface_control,
    acj_job_type_s_catalogue_id,
    cat_key,
    typ_key,
    doc_number,
    doc_effective_date,
    doc_document_date,
    acs_financial_currency_id,
    currency,
    fye_no_exercice,
    c_status_document,
    com_name_act,
    a_datecre,
    a_idcre)
  values (
    vAciDocId,
    '3',
    '3',
    JobType,
    CatKey,
    TypKey,
    rBreak.brk_document_cg, -- DOC_NUMBER
    rBreak.brk_value_date, -- DOC_EFFECTIVE_DATE
    rBreak.brk_break_date, -- DOC_DOCUMENT_DATE
    vFinCurrId, -- Monnaie de base finance
    currency,
    rBreak.brk_fye_no_exercice, -- FYE_NO_EXERCICE
    'DEF',
    BREAK_COM_NAME,
    SysDate,
    pcs.pc_public.GetUserIni);
  exception
    when eJobTypeUnknown then
    begin
      raise_application_error(-20061,'PCS-'||pcs.pc_functions.TranslateWord('Type de travail inconnu pour ce décompte'));
      rollback;
    end;
    when eCatKeyUnknown then
    begin
      raise_application_error(-20062,'PCS-'||pcs.pc_functions.TranslateWord('Méthode de travail comptable du décompte invalide ou inexistante'));
      rollback;
    end;
    when others then
    begin
      raise_application_error(-20063,'PCS-'||pcs.pc_functions.TranslateWord('Impossible de créer le document comptable'));
      rollback;
    end;
end Aci_Doc_Create;

/**
 * Création du status du document
 */
procedure Aci_DocStatus_Create(vAciDocId IN aci_document.aci_document_id%TYPE)
is
  CFinancialLink acj_job_type.c_aci_financial_link%TYPE;
begin
  -- Recherche du C_ACI_FINANCIAL_LINK
  begin
    if BREAK_COM_NAME is null then
      select t.c_aci_financial_link into CFinancialLink
      from acj_job_type t, acj_job_type_s_catalogue c, aci_document d
      where d.aci_document_id = vAciDocId and
        c.acj_job_type_s_catalogue_id = d.ACJ_JOB_TYPE_S_CATALOGUE_ID and
        t.acj_job_type_id = c.acj_job_type_id;
    else
      -- Forcer l'intégration dans un shéma distinct
      CFinancialLink := '8';
    end if;
  exception
    when no_data_found then
      CFinancialLink := '3';
  end;
  -- Création du status
  insert into aci_document_status
    (aci_document_status_id,
     aci_document_id,
     c_aci_financial_link)
  values
    (aci_id_seq.nextval,
     vAciDocId,
     CFinancialLink);
  exception
    when others then
    begin
      raise_application_error(-20067,'PCS-'||pcs.pc_functions.TranslateWord('Erreur lors de la création du status du document ACI.'));
      rollback;
    end;
end;

/**
 * Procédure de transfert
 */
procedure Aci_Transfert(vAciDocId IN aci_document.aci_document_id%TYPE,
  vFinCurrId IN acs_financial_currency.acs_financial_currency_id%TYPE)
is
  cursor csToTransfert(pcBreakId hrm_break.hrm_break_id%TYPE, pcSameCurr number) is
  select
    cg_number, div_number, cpn_number, cda_number, pf_number, pj_number,
    number1, number2, number3, number4, text1, text2, text3, text4,
    rco_title,
    decode(pcSameCurr, 1, debit_amount, foreign_debit_amount) ldebit_amount,
    decode(pcSameCurr, 1, credit_amount, foreign_credit_amount) lcredit_amount,
    decode(pcSameCurr, 1, foreign_debit_amount, debit_amount) fdebit_amount,
    decode(pcSameCurr, 1, foreign_credit_amount, credit_amount) fcredit_amount
  from
    v_hrm_break_cgan_grp
  where
    hrm_break_id = pcBreakId;

  rToTransfert csToTransfert%rowtype;
  AciImputationId aci_financial_imputation.aci_financial_imputation_id%TYPE;
  DefAccount aci_financial_imputation.acc_number%TYPE;
  eNoPrimary exception;
  nSameCurr number;
  strFinCurrName pcs.pc_curr.currency%TYPE;
  strBasicCurrName pcs.pc_curr.currency%TYPE;
begin
  -- Initialisation des monnaies
  strBasicCurrName := acs_function.getCurrencyName(rBreak.acs_financial_currency_id);
  if rBreak.acs_financial_currency_id = vFinCurrID then
    nSameCurr := 1;
    strFinCurrName := strBasicCurrName;
  else
    nSameCurr := 0;
    strFinCurrName := acs_function.getCurrencyName(vFinCurrID);
  end if;
  -- 1.Ovrir un curseur sur la vue V_HRM_BREAK_CGAN_GRP (filtré sur HRM_BREAK_ID)
  --   qui nous retourne les écritures CG et AN à transférer.
  open csToTransfert(rBreak.hrm_break_id, nSameCurr);
  loop
    fetch csToTransfert into rToTransfert;
    exit when csToTransfert%notfound;
    -- 2.Pour chaque "FETCH" de ces lignes,
    --   a) on créé une écriture financiére dans ACI_FINANCIAL_IMPUTATION
    AciImputationId := 0;
    select aci_id_seq.nextval into AciImputationId from dual;
    insert into aci_financial_imputation
        (aci_financial_imputation_id,
         aci_document_id,
         imf_type,
         imf_genre,
         imf_primary,
         imf_description,
         imf_amount_lc_d,
         imf_amount_lc_c,
         imf_exchange_rate,
         imf_base_price,
         imf_amount_fc_d,
         imf_amount_fc_c,
         imf_transaction_date,
         imf_value_date,
         currency1,
         acs_financial_currency_id,
         currency2,
         acs_acs_financial_currency_id,
         acc_number,
         div_number,
         imf_number,
         imf_number2,
         imf_number3,
         imf_number4,
         imf_text1,
         imf_text2,
         imf_text3,
         imf_text4,
         rco_title,
         c_genre_transaction,
         a_datecre,
         a_idcre)
    values
        (AciImputationId,
         vAciDocId,
         'MAN',
         'STD',
         0,
         rbreak.brk_description,
         rToTransfert.ldebit_amount,
         rToTransfert.lcredit_amount,
         0,
         0,
         rToTransfert.fdebit_amount,
         rToTransfert.fcredit_amount,
         rBreak.brk_document_cgdate,
         rBreak.brk_value_date,
         -- Monnaie de base RH
         strBasicCurrName,
         rBreak.acs_financial_currency_id,
         -- Monnaie de base FIN
         strFinCurrName,
         vFinCurrId,
         rToTransfert.cg_number,
         rToTransfert.div_number,
         To_Number(rToTransfert.number1),
         To_Number(rToTransfert.number2),
         To_Number(rToTransfert.number3),
         To_Number(rToTransfert.number4),
         rToTransfert.text1,
         rToTransfert.text2,
         rToTransfert.text3,
         rToTransfert.text4,
         rToTransfert.rco_title,
         '1',
         SysDate,
         pcs.pc_public.GetUserIni);

    -- b) Ecriture analytique dans ACI_MGM_IMPUTATION (si CPN Not Null)
    if rToTransfert.cpn_number is not null then
      insert into aci_mgm_imputation
         (aci_mgm_imputation_id,
          aci_document_id,
          aci_financial_imputation_id,
          imm_type,
          imm_genre,
          imm_primary,
          imm_description,
          imm_amount_lc_d,
          imm_amount_lc_c,
          imm_amount_fc_d,
          imm_amount_fc_c,
          imm_value_date,
          imm_transaction_date,
          currency1,
          acs_financial_currency_id,
          currency2,
          acs_acs_financial_currency_id,
          cda_number,
          cpn_number,
          pf_number,
          pj_number,
          imm_number,
          imm_number2,
          imm_number3,
          imm_number4,
          imm_text1,
          imm_text2,
          imm_text3,
          imm_text4,
          rco_title,
          per_no_period,
          a_datecre,
          a_idcre)
      values
          (aci_id_seq.nextval,
           vAciDocId,
           AciImputationId,
           'MAN',
           'STD',
           null,
           rBreak.brk_description,
           rToTransfert.ldebit_amount,
           rToTransfert.lcredit_amount,
           rToTransfert.fdebit_amount,
           rToTransfert.fcredit_amount,
           rBreak.brk_value_date,
           rBreak.brk_document_cgdate,
           -- Monnaie de base RH
           strBasicCurrName,
           rBreak.acs_financial_currency_id,
           -- Monnaie de base FIN
           strFinCurrName,
           vFinCurrId,
           rToTransfert.cda_number,
           rToTransfert.cpn_number,
           rToTransfert.pf_number,
           rToTransfert.pj_number,
           To_Number(rToTransfert.number1),
           To_Number(rToTransfert.number2),
           To_Number(rToTransfert.number3),
           To_Number(rToTransfert.number4),
           rToTransfert.text1,
           rToTransfert.text2,
           rToTransfert.text3,
           rToTransfert.text4,
           rToTransfert.rco_title,
           null,
           SysDate,
           pcs.pc_public.GetUserIni);
    end if;
  end loop;
  close csToTransfert;

  -- 3. Mise à jour de l'écriture primaire
  -- Recherche du compte de base
  select min(b.sab_account_name) into DefAccount
  from hrm_salary_breakdown b, hrm_elements e
  where b.hrm_break_id = rBreak.hrm_break_id and
    b.dic_account_type_id = 'CG' and
    b.hrm_elements_id = e.hrm_elements_id and
    e.ele_code = 'CemMontantPaye';

  -- Si on a pas trouvé, recherche du plus petit ACC_NUMBER
  if DefAccount is null then
    select min(acc_number) into DefAccount
    from aci_financial_imputation
    where aci_document_id = vAciDocId;
    if DefAccount is null then
      raise eNoPrimary;
    end if;
  end if;
  -- Mise à jour de l'écriture primaire
  update aci_financial_imputation set imf_primary = 1
  where aci_financial_imputation_id =
      (select min(aci_financial_imputation_id)
       from aci_financial_imputation
       where aci_document_id = vAciDocId and
         acc_number = DefAccount);
  exception
    when eNoPrimary then
    begin
      raise_application_error(-20064,'PCS-'||pcs.pc_functions.TranslateWord('Erreur lors de la mise à jour de l''écriture primaire.'));
      rollback;
    end;
    when others then
    begin
      raise_application_error(-20065,'PCS-'||pcs.pc_functions.TranslateWord('Impossible de transférer la ventilation.'));
      rollback;
    end;
end Aci_Transfert;

/**
 * Procédure de transfert (pour version 1)
 */
procedure Aci_TransfertV1(vAciDocId IN aci_document.aci_document_id%TYPE)
is
  strCurrName pcs.pc_curr.currency%TYPE;
  DefAccount aci_financial_imputation.acc_number%TYPE;
  eNoPrimary exception;
begin
  -- Initialisation des monnaies
  strCurrName := acs_function.GetLocalCurrencyName;

  insert into aci_financial_imputation
    (aci_financial_imputation_id,
     aci_document_id,
     imf_type,
     imf_genre,
     imf_primary,
     imf_description,
     imf_amount_lc_d,
     imf_amount_lc_c,
     imf_exchange_rate,
     imf_base_price,
     imf_amount_fc_d,
     imf_amount_fc_c,
     imf_transaction_date,
     imf_value_date,
     currency1,
     acs_financial_currency_id,
     currency2,
     acs_acs_financial_currency_id,
     acc_number,
     div_number,
     c_genre_transaction,
     a_datecre,
     a_idcre)
  select
     aci_id_seq.nextval,
     vAciDocId,
     'MAN',
     'STD',
     0,
     rbreak.brk_description,
     debit_amount, -- ldebit_amount
     credit_amount, -- lcredit_amount
     0,
     0,
     0, -- fdebit_amount
     0, -- fcredit_amount
     rBreak.brk_document_cgdate,
     rBreak.brk_value_date,
     strCurrName,
     rBreak.acs_financial_currency_id,
     -- Monnaie Finance identique à RH pour cette version
     strCurrName,
     rBreak.acs_financial_currency_id,
     acc_number,
     div_number,
     '1',
     SysDate,
     pcs.pc_public.GetUserIni
  from v_hrm_break_cg_div_grp
  where hrm_break_id = rBreak.hrm_break_id;

  -- Mise à jour de l'écriture primaire
  -- Recherche du compte de base
  select min(b.hdb_account_name) into DefAccount
  from hrm_break_detail b, hrm_elements e
  where b.hrm_break_id = rBreak.hrm_break_id and
    b.dic_account_type_id = 'CG' and
    b.hrm_elements_id = e.hrm_elements_id and
    e.ele_code = 'CemMontantPaye';

  -- Si on a pas trouvé, recherche du plus petit ACC_NUMBER
  if DefAccount is null then
    select min(acc_number) into DefAccount
    from aci_financial_imputation
    where aci_document_id = vAciDocId;
    if DefAccount is null then
      raise eNoPrimary;
    end if;
  end if;
  -- Mise à jour de l'écriture primaire
  update aci_financial_imputation set imf_primary = 1
  where aci_financial_imputation_id =
      (select min(aci_financial_imputation_id)
       from aci_financial_imputation
       where aci_document_id = vAciDocId and
         acc_number = DefAccount);
  exception
    when eNoPrimary then
    begin
      raise_application_error(-20064,'PCS-'||pcs.pc_functions.TranslateWord('Erreur lors de la mise à jour de l''écriture primaire.'));
      rollback;
    end;
    when others then
    begin
      raise_application_error(-20065,'PCS-'||pcs.pc_functions.TranslateWord('Impossible de transférer la ventilation.'));
      rollback;
    end;
end Aci_TransfertV1;

/**
 * Mise à jour des ID des comptes
 */
procedure Aci_UpdateAccountId(vAciDocId IN aci_document.aci_document_id%TYPE)
is
begin
  -- CG
  update aci_financial_imputation a
  set a.acs_financial_account_id =
      (select distinct b.acs_financial_account_id
       from v_acs_financial_account b
       where b.acc_number = a.acc_number)
  where aci_document_id = vAciDocId;
  -- DIV
  update aci_financial_imputation a
  set a.acs_division_account_id =
      (select distinct b.acs_division_account_id
       from v_acs_division_account b
       where b.acc_number = a.div_number)
  where aci_document_id = vAciDocId;
  -- CPN
  update aci_mgm_imputation a
  set a.acs_cpn_account_id =
      (select distinct b.acs_cpn_account_id
       from v_hrm_cpn_account b
       where b.acs_cpn_number = a.cpn_number)
  where aci_document_id = vAciDocId;
  -- CDA
  update aci_mgm_imputation a
  set a.acs_cda_account_id =
    (select distinct b.acs_cda_account_id
     from v_hrm_cda_account b
     where b.acs_cda_number = a.cda_number)
  where aci_document_id = vAciDocId;
  -- PF
  update aci_mgm_imputation a
  set a.acs_pf_account_id =
      (select distinct b.acs_pf_account_id
       from v_hrm_pf_account b
       where b.acs_pf_number = a.pf_number)
  where aci_document_id = vAciDocId;
  -- PJ
  update aci_mgm_imputation a
  set a.acs_pj_account_id =
      (select distinct b.acs_pj_account_id
       from v_hrm_pj_account b
       where b.acs_pj_number = a.pj_number)
  where aci_document_id = vAciDocId;

  -- DOC_RECORD
  update aci_financial_imputation f
  set (doc_record_id, rco_number) =
    (select r.doc_record_id, r.rco_number
     from doc_record r
     where r.rco_title = f.rco_title)
  where
    f.aci_document_id = vAciDocId and
    f.rco_title is not null;

  -- DOC_RECORD
  update aci_mgm_imputation m
  set (doc_record_id, rco_number) =
    (select r.doc_record_id, r.rco_number
     from doc_record r
     where r.rco_title = m.rco_title)
  where
    m.aci_document_id = vAciDocId and
    m.rco_title is not null;

  exception
    when others then
    begin
      raise_application_error(-20066,'PCS-'||pcs.pc_functions.TranslateWord('Erreur lors de la mise à jour des ID des comptes.'));
      rollback;
    end;
end Aci_UpdateAccountId;

END HRM_BREAK_TRANSFER;
