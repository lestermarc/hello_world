--------------------------------------------------------
--  DDL for Package Body IND_ACT_PO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_ACT_PO" 
is
  procedure reprise_po(NoJournal act_journal.jou_number%type)
  -- Passage des postes ouverts du  compte 411000 au 411100 (compte collectif)
  is
   cursor CurPO is
    select
    imp.*,
    case
     when imf_description like '%(NC)' then 'NC'
     else 'FC'
    end doc_type,
    substr(imf_description,1,10) doc_num,
    pcs.extractline(f.ind_line,13,';') date_expiry
    from
    act_financial_imputation imp, ind_fichier f
    where
    substr(imf_description,1,10)=pcs.extractline(f.ind_line,5,';') -- doc_number
    and pcs.extractline(f.ind_line,12,';')<>'0'
    and pcs.extractline(ind_line,12,';')<>'0.00'-- Offen
    and f.import_name='REPRISE_PO'
    and (imf_description like '%(NC)'
        or imf_description like '%(FACT)') -- filtre pour ne pas retourner (PA_FACT) -> encaissements
    and acs_financial_account_id in (select acs_account_id
                                    from acs_account
                                    where acc_number='411000');

   NewDocId act_document.doc_document_id%type;
   JobId act_job.act_job_id%type;
   JournalId act_journal.act_journal_id%type;
   CusId pac_custom_partner.pac_custom_partner_id%type;
   AuxId pac_custom_partner.acs_auxiliary_account_id%type;
   PartId act_part_imputation.act_part_imputation_id%type;
   PayConditionId pac_custom_partner.pac_payment_condition_id%type;

  begin

   -- propriétés du journal
   select
   act_job_id, act_journal_id
    into JobId, JournalId
   from
   act_journal
   where
   jou_number=NoJournal;

   for RowPO in CurPO
   loop
    --dbms_output.put_line('OK');

    -- ID du document
    select init_id_seq.nextval into NewDocId from dual;

    -- création document
    insert into act_document (
    ACT_DOCUMENT_ID,
    ACT_JOB_ID,
    DOC_NUMBER,
    DOC_DOCUMENT_DATE,
    ACS_FINANCIAL_CURRENCY_ID,
    ACJ_CATALOGUE_DOCUMENT_ID,
    ACT_JOURNAL_ID,
    ACS_FINANCIAL_YEAR_ID,
    DOC_FREE_TEXT5,
    A_DATECRE,
    A_IDCRE)
    select
    NewDocId,
    JobId,
    RowPO.doc_num,
    RowPO.imf_transaction_date,
    RowPO.ACS_FINANCIAL_CURRENCY_ID,
    case
     when RowPO.doc_type='NC'
     then (select ACJ_CATALOGUE_DOCUMENT_ID from ACJ_CATALOGUE_DOCUMENT where cat_description='DE - Note de crédit débiteur')
     else (select ACJ_CATALOGUE_DOCUMENT_ID from ACJ_CATALOGUE_DOCUMENT where cat_description='DE - Facture débiteur')
    end,
    JournalId,
    RowPO.IMF_ACS_FINANCIAL_YEAR_ID,
    RowPO.date_expiry,
    sysdate,
    'REP'
    from dual;

    -- propriétés client
    select
    cus.pac_custom_partner_id, cus.acs_auxiliary_account_id, pac_payment_condition_id
     into CusId, AuxId, PayConditionId
    from
    doc_record rco, pac_custom_partner cus
    where
    rco.pac_third_id=cus.pac_custom_partner_id
    and doc_record_id=RowPO.doc_record_id;

      if CusId is null
      then raise_application_error(-20001,'Aucun partenaire lié pour le dossier (id)'||nvl(RowPO.doc_record_id,'NULL'));
      end if;

    select init_id_seq.nextval into PartId from dual;

    -- imputation partenaire
    insert into act_part_imputation (
    ACT_PART_IMPUTATION_ID,
    ACT_DOCUMENT_ID,
    PAC_CUSTOM_PARTNER_ID,
    PAC_PAYMENT_CONDITION_ID,
    ACS_FINANCIAL_CURRENCY_ID,
    ACS_ACS_FINANCIAL_CURRENCY_ID,
    PAR_DOCUMENT,
    A_DATECRE,
    A_IDCRE)
    select
    PartId,
    NewDocId,
    CusId,
    PayConditionId,
    RowPO.ACS_FINANCIAL_CURRENCY_ID,
    RowPO.ACS_ACS_FINANCIAL_CURRENCY_ID,
    RowPO.doc_num,
    sysdate,
    'REP'
    from dual;

    -- imputations financières
    insert into act_financial_imputation (
    ACT_FINANCIAL_IMPUTATION_ID,
    ACS_PERIOD_ID,
    ACT_DOCUMENT_ID,
    ACS_FINANCIAL_ACCOUNT_ID,
    IMF_TYPE,
    IMF_PRIMARY,
    IMF_DESCRIPTION,
    IMF_AMOUNT_LC_D,
    IMF_AMOUNT_LC_C,
    IMF_EXCHANGE_RATE,
    IMF_AMOUNT_FC_D,
    IMF_AMOUNT_FC_C,
    IMF_VALUE_DATE,
    ACS_TAX_CODE_ID,
    IMF_TRANSACTION_DATE,
    ACS_AUXILIARY_ACCOUNT_ID,
    ACT_DET_PAYMENT_ID,
    IMF_GENRE,
    IMF_BASE_PRICE,
    ACS_FINANCIAL_CURRENCY_ID,
    ACS_ACS_FINANCIAL_CURRENCY_ID,
    C_GENRE_TRANSACTION,
    IMF_NUMBER,
    A_CONFIRM,
    A_DATECRE,
    A_IDCRE,
    ACT_PART_IMPUTATION_ID,
    IMF_NUMBER2,
    IMF_TEXT1,
    IMF_TEXT2,
    IMF_AMOUNT_EUR_D,
    IMF_AMOUNT_EUR_C,
    IMF_COMPARE_DATE,
    IMF_CONTROL_DATE,
    IMF_COMPARE_TEXT,
    IMF_CONTROL_TEXT,
    IMF_COMPARE_USE_INI,
    IMF_CONTROL_USE_INI,
    IMF_TEXT3,
    IMF_TEXT4,
    GCO_GOOD_ID,
    HRM_PERSON_ID,
    DOC_RECORD_ID,
    IMF_NUMBER3,
    IMF_NUMBER4,
    IMF_NUMBER5,
    FAM_FIXED_ASSETS_ID,
    PAC_PERSON_ID,
    C_FAM_TRANSACTION_TYP,
    IMF_ACS_DIVISION_ACCOUNT_ID,
    IMF_ACS_FINANCIAL_YEAR_ID)
    select
    init_id_seq.nextval ACT_FINANCIAL_IMPUTATION_ID,
    ACS_PERIOD_ID,
    NewDocId ACT_DOCUMENT_ID,
    case
     when (select acc_number from acs_account acc where acc.acs_account_id=imp.acs_financial_account_id)='411000'
     then (select acs_account_id
           from acs_account a, acs_financial_account b
           where a.acs_account_id=b.acs_financial_account_id
           and a.acc_number='411100')
      else (select acs_account_id
           from acs_account a, acs_financial_account b
           where a.acs_account_id=b.acs_financial_account_id
           and a.acc_number='411000')
    end ACS_FINANCIAL_ACCOUNT_ID,
    case
     when (select acc_number from acs_account acc where acc.acs_account_id=imp.acs_financial_account_id)='411000'
     then 'AUX'
     else 'MAN'
    end IMF_TYPE,
    case
     when (select acc_number from acs_account acc where acc.acs_account_id=imp.acs_financial_account_id)='411000'
     then 1
     else 0
    end IMF_PRIMARY,
    IMF_DESCRIPTION,
    IMF_AMOUNT_LC_D,
    IMF_AMOUNT_LC_C,
    IMF_EXCHANGE_RATE,
    IMF_AMOUNT_FC_D,
    IMF_AMOUNT_FC_C,
    IMF_VALUE_DATE,
    ACS_TAX_CODE_ID,
    IMF_TRANSACTION_DATE,
    case
     when (select acc_number from acs_account acc where acc.acs_account_id=imp.acs_financial_account_id)='411000'
     then AuxId
     else null
    end ACS_AUXILIARY_ACCOUNT_ID,
    ACT_DET_PAYMENT_ID,
    IMF_GENRE,
    IMF_BASE_PRICE,
    ACS_FINANCIAL_CURRENCY_ID,
    ACS_ACS_FINANCIAL_CURRENCY_ID,
    C_GENRE_TRANSACTION,
    IMF_NUMBER,
    A_CONFIRM,
    sysdate A_DATECRE,
    'REP' A_IDCRE,
    PartId ACT_PART_IMPUTATION_ID,
    IMF_NUMBER2,
    IMF_TEXT1,
    IMF_TEXT2,
    IMF_AMOUNT_EUR_D,
    IMF_AMOUNT_EUR_C,
    IMF_COMPARE_DATE,
    IMF_CONTROL_DATE,
    IMF_COMPARE_TEXT,
    IMF_CONTROL_TEXT,
    IMF_COMPARE_USE_INI,
    IMF_CONTROL_USE_INI,
    IMF_TEXT3,
    IMF_TEXT4,
    GCO_GOOD_ID,
    HRM_PERSON_ID,
    DOC_RECORD_ID,
    IMF_NUMBER3,
    IMF_NUMBER4,
    IMF_NUMBER5,
    FAM_FIXED_ASSETS_ID,
    PAC_PERSON_ID,
    C_FAM_TRANSACTION_TYP,
    IMF_ACS_DIVISION_ACCOUNT_ID,
    IMF_ACS_FINANCIAL_YEAR_ID
    from
    act_financial_imputation imp
    where
    substr(imf_description,1,10)=RowPO.doc_num
    and (imf_description like '%(NC)'
        or imf_description like '%(FACT)');

    -- imputation division
    insert into act_financial_distribution (
    ACT_FINANCIAL_DISTRIBUTION_ID,
    ACT_FINANCIAL_IMPUTATION_ID,
    FIN_DESCRIPTION,
    FIN_AMOUNT_LC_D,
    FIN_AMOUNT_FC_D,
    ACS_SUB_SET_ID,
    FIN_AMOUNT_LC_C,
    FIN_AMOUNT_FC_C,
    ACS_DIVISION_ACCOUNT_ID,
    A_DATECRE,
    A_IDCRE,
    FIN_AMOUNT_EUR_D,
    FIN_AMOUNT_EUR_C)
    select
    init_id_seq.nextval,
    act_financial_imputation_id,
    imf_description,
    IMF_AMOUNT_LC_D,
    IMF_AMOUNT_FC_D,
    (select acs_sub_set_id from acs_sub_set where c_sub_set='DTO'),
    IMF_AMOUNT_LC_C,
    IMF_AMOUNT_FC_C,
    IMF_ACS_DIVISION_ACCOUNT_ID,
    sysdate,
    'REP',
    IMF_AMOUNT_EUR_D,
    IMF_AMOUNT_EUR_C
    from
    act_financial_imputation imp, act_document doc
    where
    imp.act_document_id=doc.act_document_id
    and doc.doc_number=RowPO.doc_num
    and (imf_description like '%(NC)'
        or imf_description like '%(FACT)');

    -- Echéances
    insert into act_expiry (
    ACT_EXPIRY_ID,
    ACT_DOCUMENT_ID,
    ACT_PART_IMPUTATION_ID,
    EXP_ADAPTED,
    EXP_CALCULATED,
    EXP_AMOUNT_LC,
    EXP_AMOUNT_FC,
    EXP_SLICE,
    EXP_DISCOUNT_LC,
    EXP_DISCOUNT_FC,
    EXP_POURCENT,
    EXP_CALC_NET,
    C_STATUS_EXPIRY,
    A_DATECRE,
    A_IDCRE)
    select
    init_id_seq.nextval,
    NewDocId,
    ACT_PART_IMPUTATION_ID,
    to_date(doc_free_text5,'DD.MM.YYYY'),
    to_date(doc_free_text5,'DD.MM.YYYY'),
    IMF_AMOUNT_LC_D-IMF_AMOUNT_LC_C,
    IMF_AMOUNT_FC_D-IMF_AMOUNT_FC_C,
    1,
    0,
    0,
    IMF_AMOUNT_LC_D-IMF_AMOUNT_LC_C,
    1,
    '0',
    sysdate,
    'REP'
    from
    act_financial_imputation imp, act_document doc
    where
    imp.act_document_id=doc.act_document_id
    and doc.doc_number=RowPO.doc_num
    and imp.acs_financial_account_id in (select acs_account_id from acs_account where acc_number='411100')
    and (imf_description like '%(NC)'
        or imf_description like '%(FACT)');

   end loop;

  end reprise_po;

end ind_act_po;
