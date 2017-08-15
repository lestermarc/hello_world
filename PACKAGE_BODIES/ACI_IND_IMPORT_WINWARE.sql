--------------------------------------------------------
--  DDL for Package Body ACI_IND_IMPORT_WINWARE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_IND_IMPORT_WINWARE" 
is

 vOutDocId aci_document.aci_document_id%TYPE;

procedure get_line_plus (file_in in UTL_FILE.FILE_TYPE,
                         line_out out varchar2,
       eof_out  out BOOLEAN) is
begin
UTL_FILE.GET_LINE(file_in,line_out);
eof_out := false;
Exception
 when OTHERS THEN
     line_out := null;
  eof_out := TRUE;
end get_line_plus;

 procedure lecture_fichier (FileDirectory varchar2, FileName varchar2, DocNum varchar2, DocDate date)
 is

 NewDocId number;
 par_repertoire varchar2(300):= FileDirectory;
 par_nom_fichier varchar2(200) := FileName;
 inc_err_vide EXCEPTION;
 inc_err_fichier EXCEPTION;
 vl_import_file UTL_FILE.FILE_TYPE;
 vl_import_record varchar2(4000);
 vl_eof BOOLEAN;
 v_line varchar2(4000);
 Error varchar2(100);
 Compteur integer;

 begin

 Error:='Ouverture du fichier';
 vl_import_file := UTL_FILE.FOPEN(par_repertoire,par_nom_fichier,'R',32767);

 Compteur:=0;

 delete from ind_import_winware
 where doc_number=DocNum;

 loop
 Error:='get_line_plus';
  get_line_plus(vl_import_file,vl_import_record,vl_eof);

  if vl_eof = TRUE then exit;
    else

    v_line:=vl_import_record;

 if Compteur>4 then -- On ne considère pas les premières lignes (entêtes de colonnes)

 Error:='Insert dans la table';
    insert into ind_import_winware (
    No_Ecr,
    Date_Ecr,
    Compte,
    debit_mb,
    credit_mb,
    Montant_TVA,
    Devise,
    debit_me,
    credit_me,
    Libelle,
    soc_fac,
    Matricule,
    Type_Ecr,
    doc_number,
    doc_date,
    A_DATECRE,
    IMP_LINE,
    IMPORT_SEQ_ID)
    values (
    ltrim(rtrim(replace(pcs.extractline(v_line,1,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,2,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,3,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,4,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,5,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,6,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,7,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,8,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,9,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,10,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,11,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,12,','),'"',''))),
    ltrim(rtrim(replace(pcs.extractline(v_line,13,','),'"',''))),
    DocNum,
    DocDate,
    sysdate,
    v_line,
    init_id_seq.nextval);
 end if;

 Compteur:=Compteur+1;

   end if;
 end loop;

 Error:='Fermeture du fichier';
 UTL_FILE.FCLOSE(vl_import_file);



 -- Lancement des procédures de création de document
  Error:='Création du document';
 Aci_Doc_Create(DocNum, DocDate, vOutDocId); -- Paramètre OUT
  Error:='Création du statut du docuement';
 Aci_DocStatus_Create(vOutDocId);
  Error:='Création des lignes d''imputation';
 Aci_Transfert(vOutDocId,DocNum);

 Exception
   when others then
    UTL_FILE.FCLOSE(vl_import_file);
    raise_application_error(-20001,'Erreur: '||Error);

 end lecture_fichier;

procedure Aci_Doc_Create(DocNum IN varchar2, DocDate IN date, vAciDocId OUT aci_document.aci_document_id%TYPE)
is
  JobType aci_document.acj_job_type_s_catalogue_id%TYPE;
  CatKey aci_document.cat_key%TYPE;
  eJobTypeUnknown exception;
  eCatKeyUnknown exception;
  vFinCurrId acs_financial_currency.acs_financial_currency_id%TYPE;
begin
  -- Recherche de la monnaie de base
  vFinCurrId := acs_function.GETLOCALCURRENCYID;

  -- Recherche du JobType
  select
  ACJ_JOB_TYPE_S_CATALOGUE_ID into JobType
  from
  ACJ_JOB_TYPE_S_CATALOGUE JOC,
  ACJ_CATALOGUE_DOCUMENT CAT
  where
  JOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
  and cat_key='ACC/CPN-EXT/PRI-DIR-1-2(3)';
  --and cat_key='REC/CPN-EXT/PRI-DIR-2-2-INT';
  if JobType is null then
    raise eJobTypeUnknown;
  end if;

  -- Recherche de la catégorie
  begin
    select
    cat_key into CatKey
    from
    ACJ_JOB_TYPE_S_CATALOGUE JOC,
    ACJ_CATALOGUE_DOCUMENT CAT
    where
    JOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
    and cat_key='ACC/CPN-EXT/PRI-DIR-1-2(3)';
    --and cat_key='REC/CPN-EXT/PRI-DIR-2-2-INT';
    if CatKey is null then
      raise eCatKeyUnknown;
    end if;
  exception
    when no_data_found then
      raise eCatKeyUnknown;
  end;

  -- Création du document
  select aci_id_seq.nextval into vAciDocId from dual;
  insert into aci_document(
    aci_document_id,
    c_interface_origin,
    c_interface_control,
    acj_job_type_s_catalogue_id,
    cat_key,
    doc_number,
    doc_effective_date,
    doc_document_date,
    acs_financial_currency_id,
    fye_no_exercice,
    c_status_document,
    a_datecre,
    a_idcre)
  values (
    vAciDocId,
    '3',
    '3',
    JobType,
    CatKey,
    DocNum, --rBreak.brk_document_cg, -- DOC_NUMBER
    DocDate, --rBreak.brk_value_date, -- DOC_EFFECTIVE_DATE
    DocDate, --rBreak.brk_break_date, -- DOC_DOCUMENT_DATE
    vFinCurrId, -- Monnaie de base finance
    to_char(DocDate,'YYYY'), --rBreak.brk_fye_no_exercice, -- FYE_NO_EXERCICE
    'DEF',
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

procedure Aci_DocStatus_Create(vAciDocId IN aci_document.aci_document_id%TYPE)
is
  CFinancialLink acj_job_type.c_aci_financial_link%TYPE;
begin
  -- Recherche du C_ACI_FINANCIAL_LINK
  begin
    select t.c_aci_financial_link into CFinancialLink
    from acj_job_type t, acj_job_type_s_catalogue c, aci_document d
    where d.aci_document_id = vAciDocId and
      c.acj_job_type_s_catalogue_id = d.ACJ_JOB_TYPE_S_CATALOGUE_ID and
      t.acj_job_type_id = c.acj_job_type_id;
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

procedure Aci_Transfert(vAciDocId IN aci_document.aci_document_id%TYPE,DocNum varchar2)
is
  cursor csToTransfert(DocNum varchar2) is
  select
  to_date(date_ecr,'DD.MM.YYYY') date_ecr,
  no_ecr,
  substr(ltrim(soc_fac),1,3) soc_fac,
  nvl(ltrim(rtrim(matricule)),'E00000') matricule,
  case
   when compte like '411%' then '411000'
   else compte --rpad(compte,6,'0')
  end compte,
  debit_MB,
  credit_MB,
  devise currency,
  debit_ME,
  credit_ME,
  nvl(no_ecr,'')||' - '||nvl(libelle,'')||' ('||nvl(type_ecr,'')||')' libelle,
  null rate,
  (select acs_financial_currency_id
    from acs_financial_currency b, pcs.pc_curr c
    where a.devise=c.currency
    and c.pc_curr_id=b.pc_curr_id) acs_financial_currency_id,
  type_ecr
  from
  ind_import_winware a
  where
  doc_number=DocNum
  order by no_ecr, date_ecr, matricule;

  rToTransfert csToTransfert%rowtype;
  AciImputationId aci_financial_imputation.aci_financial_imputation_id%TYPE;
  DefAccount aci_financial_imputation.acc_number%TYPE;
  eNoPrimary exception;
  strFinCurrName pcs.pc_curr.currency%TYPE;
  vFinCurrId acs_financial_currency.acs_financial_currency_id%TYPE;
  vCompteDossier number(1);
  vDocRecord doc_record.rco_title%type;
begin
    vFinCurrId := acs_function.GetLocalCurrencyID;
    strFinCurrName := acs_function.getCurrencyName(vFinCurrID);

  open csToTransfert(DocNum);
  loop
    fetch csToTransfert into rToTransfert;
    exit when csToTransfert%notfound;
    -- 2.Pour chaque "FETCH" de ces lignes,
    --   a) on créé une écriture financiére dans ACI_FINANCIAL_IMPUTATION
    AciImputationId := 0;
/*
    -- recherche si le compte doit être associé à un dossier
    select
    count(*) into vCompteDossier
    from
    acs_account acc,
    acs_financial_account fac
    where
    acc.acs_account_id=fac.acs_financial_account_id
    and acc.acc_number=rToTransfert.compte
    and fac.DIC_FIN_ACC_CODE_3_ID='OUI';

    if vCompteDossier>0
     then vDocRecord:=rToTransfert.soc_fac;
     else vDocRecord:=null;
    end if;
*/
  vDocRecord:=rToTransfert.soc_fac;

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
         rco_title,
         imf_text1,
         imf_text2,
         c_genre_transaction,
         a_datecre,
         a_idcre)
    values
        (AciImputationId,
         vAciDocId,
         'MAN',
         'STD',
         0,
         rToTransfert.libelle,
         rToTransfert.debit_mb,
         rToTransfert.credit_mb,
         decode(rToTransfert.currency,strFinCurrName,null,rToTransfert.rate),
         decode(rToTransfert.currency,strFinCurrName,null,1),
         decode(rToTransfert.currency,strFinCurrName,null,rToTransfert.debit_me),
         decode(rToTransfert.currency,strFinCurrName,null,rToTransfert.credit_me),
         rToTransfert.date_ecr,
         rToTransfert.date_ecr,
         -- Monnaie de base RH
         rToTransfert.currency,
         rToTransfert.acs_financial_currency_id,
         -- Monnaie de base FIN
         strFinCurrName,
         vFinCurrId,
         rToTransfert.compte,
         rToTransfert.matricule,-- division
         vDocRecord,--dossier
         rToTransfert.no_ecr,
         rToTransfert.type_ecr,
         '1',
         SysDate,
         pcs.pc_public.GetUserIni);

  end loop;
  close csToTransfert;

  -- 3. Mise à jour de l'écriture primaire
  -- Recherche du compte de base
  DefAccount := null;

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

end aci_ind_import_winware;
