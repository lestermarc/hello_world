--------------------------------------------------------
--  DDL for Package Body ACT_INTERFACE_RECOVERING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_INTERFACE_RECOVERING" 
IS

  type TLinkDetPayACI_ACT is record(
    ACT_DET_PAYMENT_ID ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , ACI_DET_PAYMENT_ID ACI_DET_PAYMENT.ACI_DET_PAYMENT_ID%type
  );

  type TtblLinkDetPayACI_ACT is table of TLinkDetPayACI_ACT;

  ------------------------------------------------------------------------------------------

  procedure CreateImputationForVAT(aACT_FINANCIAL_IMPUTATION_ID in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                                  aREF_FINANCIAL_IMPUTATION_ID in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                                  aMGMImput ACT_MGM_IMPUTATION%rowtype)
  is
    BaseInfoRec ACT_VAT_MANAGEMENT.BaseInfoRecType;
  begin
    begin
      select ACS_PERIOD_ID
           , ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID
           , IMF_PRIMARY
           , IMF_DESCRIPTION
           , IMF_AMOUNT_LC_D
           , IMF_AMOUNT_LC_C
           , IMF_AMOUNT_EUR_D
           , IMF_AMOUNT_EUR_C
           , IMF_EXCHANGE_RATE
           , IMF_AMOUNT_FC_D
           , IMF_AMOUNT_FC_C
           , IMF_VALUE_DATE
           , ACS_TAX_CODE_ID
           , IMF_TRANSACTION_DATE
           , IMF_BASE_PRICE
           , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
           , ACS_ACS_FINANCIAL_CURRENCY_ID
           , aREF_FINANCIAL_IMPUTATION_ID
           , ACT_PART_IMPUTATION_ID
           , C_TYPE_CATALOGUE
           , ACT_FINANCIAL_DISTRIBUTION.ACS_DIVISION_ACCOUNT_ID
        into BaseInfoRec.PeriodId
           , BaseInfoRec.DocumentId
           , BaseInfoRec.primary
           , BaseInfoRec.Description
           , BaseInfoRec.AmountD_LC
           , BaseInfoRec.AmountC_LC
           , BaseInfoRec.AmountD_EUR
           , BaseInfoRec.AmountC_EUR
           , BaseInfoRec.ExchangeRate
           , BaseInfoRec.AmountD_FC
           , BaseInfoRec.AmountC_FC
           , BaseInfoRec.ValueDate
           , BaseInfoRec.TaxCodeId
           , BaseInfoRec.TransactionDate
           , BaseInfoRec.BasePrice
           , BaseInfoRec.FinCurrId_FC
           , BaseInfoRec.FinCurrId_LC
           , BaseInfoRec.FinImputId
           , BaseInfoRec.PartImputId
           , BaseInfoRec.TypeCatalogue
           , BaseInfoRec.DivAccId
        from ACT_FINANCIAL_IMPUTATION
           , ACT_FINANCIAL_DISTRIBUTION
           , ACT_DOCUMENT
           , ACJ_CATALOGUE_DOCUMENT
       where ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID
         and ACT_DOCUMENT.ACT_DOCUMENT_ID = ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID
         and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
         and ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_IMPUTATION_ID (+) = ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID;

    exception
      when no_data_found then
        return;
    end;

    ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMF(aACT_FINANCIAL_IMPUTATION_ID, BaseInfoRec.InfoImputationValues);

    ACT_VAT_MANAGEMENT.CreateVATSecMAN(aACT_FINANCIAL_IMPUTATION_ID, aMGMImput, BaseInfoRec);

  end CreateImputationForVAT;

  ------------------------------------------------------------------------------------------

  function AutoCoverDirectPayment(
    aACJ_CATALOGUE_DOCUMENT_ID ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aACS_FIN_ACC_S_PAYMENT_ID  ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  )
    return boolean
  is
    vCheck number(1);
  begin
    select 0
      into vCheck
      from ACS_FIN_ACC_S_PAYMENT SPAY
     where SPAY.ACS_FIN_ACC_S_PAYMENT_ID = aACS_FIN_ACC_S_PAYMENT_ID
       and SPAY.PMM_COVER_GENERATION = 1;

    select 0
      into vCheck
      from ACS_FINANCIAL_ACCOUNT FIN
         , ACJ_CATALOGUE_DOCUMENT CAT
     where FIN.ACS_FINANCIAL_ACCOUNT_ID = CAT.ACS_FINANCIAL_ACCOUNT_ID
       and CAT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
       and CAT.CAT_COVER_INFORMATION = 1
       and FIN.FIN_PORTFOLIO = 1;

    return true;
  exception
    when no_data_found then
      return false;
  end AutoCoverDirectPayment;

  /**
  * Description :
  *   Màj des infos complémentaires des imputations d'un document de paiements en fonction
  *   des données de ACI_DET_PAYMENT. atblLinkDetPayACI_ACT contient les liens entre
  *   ACI_DET_PAYMENT et ACT_DET_PAYMENT (plusieurs ACT_DET_PAYMENT_ID possible pour
  *   un ACI_DET_PAYMENT).
  */
  procedure UpdateDocPayInfoImputations(
    aACT_DOCUMENT_ID      ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , atblLinkDetPayACI_ACT TtblLinkDetPayACI_ACT
  )
  is
    cursor csr_doc_payment_ids(document_id number, det_payment_id number)
    is
      select distinct imp.act_financial_imputation_id
                    , mgm.act_mgm_imputation_id
                    , dist.act_mgm_distribution_id
                 from act_mgm_distribution dist
                    , act_mgm_imputation mgm
                    , act_financial_imputation imp
                    , (select tax.act_act_financial_imputation imp1
                            , tax.act2_act_financial_imputation imp2
                            , tax2.act_financial_imputation_id imp3
                            , tax3.act_financial_imputation_id imp4
                            , imp.act_financial_imputation_id
                         from act_det_tax tax3
                            , act_det_tax tax2
                            , act_det_tax tax
                            , act_financial_imputation imp
                        where imp.act_document_id = document_id
                          and imp.act_det_payment_id = det_payment_id
                          and imp.act_financial_imputation_id = tax.act_financial_imputation_id(+)
                          and tax.act_det_tax_id = tax2.act2_det_tax_id(+)
                          and tax2.tax_included_excluded(+) = 'I'
                          and tax.act_det_tax_id = tax3.act2_det_tax_id(+)
                          and tax3.tax_included_excluded(+) = 'E') tt
                where imp.act_document_id = document_id
                  and (   imp.act_det_payment_id = det_payment_id
                       or imp.act_financial_imputation_id in(tt.imp1, tt.imp2, tt.imp3, tt.imp4)
                      )
                  and imp.act_financial_imputation_id = mgm.act_financial_imputation_id(+)
                  and mgm.act_mgm_imputation_id = dist.act_mgm_imputation_id(+)
             order by imp.act_financial_imputation_id
                    , mgm.act_mgm_imputation_id
                    , dist.act_mgm_distribution_id;

    lastdoc_payment_ids     csr_doc_payment_ids%rowtype;
    InfoImputationManaged   ACT_IMP_MANAGEMENT.InfoImputationRecType;
    InfoImputationValues    ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    detInfoImputationValues ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    curInfoImputationValues ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    lastACI_DET_PAYMENT_ID  ACI_DET_PAYMENT.ACI_DET_PAYMENT_ID%type                 := null;
    catalogue_document_id   ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
  begin
    -- recherche du catalogue
    select max(ACJ_CATALOGUE_DOCUMENT_ID)
      into catalogue_document_id
      from ACT_DOCUMENT DOC
     where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    -- recherche des info géreé pour le catalogue
    InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);

    for i in atblLinkDetPayACI_ACT.first .. atblLinkDetPayACI_ACT.last loop
      if nvl(lastACI_DET_PAYMENT_ID, 0) != atblLinkDetPayACI_ACT(i).ACI_DET_PAYMENT_ID then
        -- récupération des données compl. des ACI
        ACT_IMP_MANAGEMENT.GetInfoImputationValuesDET_ACI(atblLinkDetPayACI_ACT(i).ACI_DET_PAYMENT_ID
                                                        , detInfoImputationValues
                                                         );
        -- sauvegarde de la pos. ACI
        lastACI_DET_PAYMENT_ID  := atblLinkDetPayACI_ACT(i).ACI_DET_PAYMENT_ID;
      end if;

      lastdoc_payment_ids  := null;

      for tpl_doc_payment_ids in csr_doc_payment_ids(aACT_DOCUMENT_ID, atblLinkDetPayACI_ACT(i).ACT_DET_PAYMENT_ID) loop
        --Copie valeurs du det_payment
        InfoImputationValues := detInfoImputationValues;

        -- màj des info compl. des ACT
        if nvl(tpl_doc_payment_ids.act_financial_imputation_id, 0) !=
                                                                nvl(lastdoc_payment_ids.act_financial_imputation_id, 0) then
          -- récupération des données compl. existante
          ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMF(tpl_doc_payment_ids.act_financial_imputation_id
                                                      , curInfoImputationValues);
          -- fusion des données compl. ACI avec les données existantes (données des ACI prioritaire)
          ACT_IMP_MANAGEMENT.MergeManagedValues(InfoImputationValues, curInfoImputationValues);
          -- màj des données compl. en tenant compte des axes gérés
          ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(tpl_doc_payment_ids.act_financial_imputation_id
                                                      , InfoImputationValues
                                                      , InfoImputationManaged.Secondary);
        end if;

        if nvl(tpl_doc_payment_ids.act_mgm_imputation_id, 0) != nvl(lastdoc_payment_ids.act_mgm_imputation_id, 0) then
          -- récupération des données compl. existante
          ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMM(tpl_doc_payment_ids.act_mgm_imputation_id
                                                      , curInfoImputationValues);
          -- fusion des données compl. ACI avec les données existantes (données des ACI prioritaire)
          ACT_IMP_MANAGEMENT.MergeManagedValues(InfoImputationValues, curInfoImputationValues);
          -- màj des données compl. en tenant compte des axes gérés
          ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMM(tpl_doc_payment_ids.act_mgm_imputation_id
                                                      , InfoImputationValues
                                                      , InfoImputationManaged.Secondary);
        end if;

        if nvl(tpl_doc_payment_ids.act_mgm_distribution_id, 0) != nvl(lastdoc_payment_ids.act_mgm_distribution_id, 0) then
          -- récupération des données compl. existante
          ACT_IMP_MANAGEMENT.GetInfoImputationValuesMGM(tpl_doc_payment_ids.act_mgm_distribution_id
                                                      , curInfoImputationValues);
          -- fusion des données compl. ACI avec les données existantes (données des ACI prioritaire)
          ACT_IMP_MANAGEMENT.MergeManagedValues(InfoImputationValues, curInfoImputationValues);
          -- màj des données compl. en tenant compte des axes gérés
          ACT_IMP_MANAGEMENT.SetInfoImputationValuesMGM(tpl_doc_payment_ids.act_mgm_distribution_id
                                                      , InfoImputationValues
                                                      , InfoImputationManaged.Secondary);
        end if;

        lastdoc_payment_ids  := tpl_doc_payment_ids;
      end loop;
    end loop;
  end UpdateDocPayInfoImputations;

  /**
  * Description
  *    Procedure de recalcule du cours de change si la diff. MB - ME
  *    est plus grande que le montant d'arrondi de la monnaie ME
  */
  procedure UpdateExchangeRate(
    aAmountLC                  in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmountFC                  in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aACS_FINANCIAL_CURRENCY_ID in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aExchangeRate              in out ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aBasePrice                 in out ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  )
  is
    roundCurrency ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type;
  begin
    --Recherche du montant d'arrondi
    select decode(FCUR.C_ROUND_TYPE, 0, 0.00, 1, 0.05, FCUR.FIN_ROUNDED_AMOUNT)
      into roundCurrency
      from ACS_FINANCIAL_CURRENCY FCUR
     where FCUR.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;

    --Màj du cours de change
    if     (nvl(aBasePrice, 0) != 0)
       and (nvl(aAmountFC, 0) != 0) then
      if abs( ( (aAmountFC * aExchangeRate) / aBasePrice) - aAmountLC) > roundCurrency then
        aExchangeRate  := (aAmountLC * aBasePrice) / aAmountFC;
      end if;
    end if;
  end UpdateExchangeRate;

  /**
  * Description :
  *   Création d'une écriture (financière + distribution)
  */
  function Create_imputation(
    document_id               in number
  , period_id                 in number
  , financial_account_id      in number
  , acs_division_account_id   in number
  , description               in varchar2
  , amount_lc_d               in number
  , amount_lc_c               in number
  , amount_fc_d               in number
  , amount_fc_c               in number
  , amount_eur_d              in number
  , amount_eur_c              in number
  , acs_financial_currency_id in number
  , value_date                in date
  , transaction_date          in date
  , exchange_rate             in number
  , base_price                in number
  , primary                   in number
  , force_division            in boolean default false
  )
    return ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  is
    financial_imputation_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    division_id             ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    sub_set_id              ACS_SUB_SET.ACS_SUB_SET_ID%type;
    divi_sub_set_id         ACS_SUB_SET.ACS_SUB_SET_ID%type;
  begin
    -- Imputation primaire du document de paiement
    select init_id_seq.nextval
      into financial_imputation_id
      from dual;

    -- Création de l'imputation primaire
    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACT_DOCUMENT_ID
               , ACT_PART_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_AMOUNT_FC_D
               , IMF_AMOUNT_FC_C
               , IMF_AMOUNT_EUR_D
               , IMF_AMOUNT_EUR_C
               , IMF_VALUE_DATE
               , ACS_TAX_CODE_ID
               , IMF_TRANSACTION_DATE
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACT_DET_PAYMENT_ID
               , IMF_GENRE
               , IMF_EXCHANGE_RATE
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , A_DATECRE
               , A_IDCRE
                )
         values (financial_imputation_id
               , document_id
               , null   --act_part_imputation_id,
               , period_id   -- fin_imputation_tuple.imf_period_id,
               , financial_account_id   -- fin_imputation_tuple.acs_financial_account_id,
               , 'MAN'   -- fin_imputation_tuple.IMF_TYPE,
               , primary   --IMF_PRIMARY,
               , description   -- fin_imputation_tuple.IMF_DESCRIPTION,
               , nvl(amount_lc_d, 0)   -- fin_imputation_tuple.IMF_AMOUNT_LC_D - vat_amount_lc_d,
               , nvl(amount_lc_c, 0)   -- fin_imputation_tuple.IMF_AMOUNT_LC_C - vat_amount_lc_c,
               , nvl(amount_fc_d, 0)   -- fin_imputation_tuple.IMF_AMOUNT_FC_D - vat_amount_fc_d,
               , nvl(amount_fc_c, 0)   -- fin_imputation_tuple.IMF_AMOUNT_FC_C - vat_amount_fc_c,
               , nvl(amount_eur_d, 0)   -- fin_imputation_tuple.IMF_AMOUNT_EUR_D - vat_amount_eur_d,
               , nvl(amount_eur_c, 0)   -- fin_imputation_tuple.IMF_AMOUNT_EUR_C - vat_amount_eur_c,
               , value_date   -- fin_imputation_tuple.IMF_VALUE_DATE,
               , null   -- fin_imputation_tuple.acs_tax_code_id,
               , transaction_date   -- fin_imputation_tuple.IMF_TRANSACTION_DATE,
               , null   -- fin_imputation_tuple.acs_auxiliary_account_id,
               , null   -- ACT_DET_PAYMENT_ID,
               , 'STD'   -- fin_imputation_tuple.IMF_GENRE,
               , nvl(exchange_rate, 0)   -- cours du document facture compta
               , nvl(base_price, 0)   -- cours du document facture compta
               , acs_financial_currency_id   -- fin_imputation_tuple.imf_financial_currency_id,
               , ACS_FUNCTION.GetLocalCurrencyId   -- fin_imputation_tuple.imf_imf_financial_currency_id,
               , '1'   -- fin_imputation_tuple.C_GENRE_TRANSACTION,
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    -- vérifie si on a un sous-ensemble division avant de générer les distributions
    select max(ACS_SUB_SET_ID)
      into divi_sub_set_id
      from ACS_SUB_SET
     where C_TYPE_SUB_SET = 'DIVI';

    if divi_sub_set_id is not null then
      if acs_division_account_id is null or not force_division then
        -- recherche de la division
        division_id  :=
                     ACS_FUNCTION.GetDivisionOfAccount(financial_account_id, acs_division_account_id, transaction_date);
      else
        division_id := acs_division_account_id;
      end if;

      if division_id is null then
        raise_application_error(-20000, 'PCS - No default division account defined');
      end if;

      -- recherche de acs_sub_set_id à partir du compte division
      select ACS_SUB_SET_ID
        into sub_set_id
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = division_id;

      -- création de la distribution financière
      insert into ACT_FINANCIAL_DISTRIBUTION
                  (ACT_FINANCIAL_DISTRIBUTION_ID
                 , ACT_FINANCIAL_IMPUTATION_ID
                 , FIN_DESCRIPTION
                 , FIN_AMOUNT_LC_D
                 , FIN_AMOUNT_FC_D
                 , FIN_AMOUNT_EUR_D
                 , FIN_AMOUNT_LC_C
                 , FIN_AMOUNT_FC_C
                 , FIN_AMOUNT_EUR_C
                 , ACS_SUB_SET_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , financial_imputation_id
                 , description
                 , nvl(amount_lc_d, 0)
                 , nvl(amount_lc_c, 0)
                 , nvl(amount_eur_d, 0)
                 , nvl(amount_lc_c, 0)
                 , nvl(amount_fc_c, 0)
                 , nvl(amount_eur_c, 0)
                 , sub_set_id
                 , division_id
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;

    return financial_imputation_id;
  end Create_imputation;

  /**
  * Description
  *    Cette procedure recherche le type de travaille à utiliser
  *    et si il n'existe pas, elle le crée
  */
  procedure GetJob(
    job_type_s_catalogue_id in     number
  , aci_control_date        in     date
  , aci_control_date2       in     date
  , financial_year_id       in     number
  , period_id               in     number
  , restricted_period       in     number
  , group_key                      ACI_DOCUMENT.DOC_GRP_KEY%type
  , job_id                  in out number
  , typ_detail              in out number
  , typ_zero_doc            in out number
  , typ_zero_pos            in out number
  , typ_dc_group            in out number
  , journal_id              in out number
  , an_journal_id           in out number
  )
  is
    job_type_id           ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type;
    job_descr             ACJ_JOB_TYPE.TYP_DESCRIPTION%type;
    jou_descr             ACT_JOB.JOB_DESCRIPTION%type;
    jnumber               ACT_JOURNAL.JOU_NUMBER%type;
    aci_cadence           ACJ_JOB_TYPE.C_ACI_CADENCE%type;
    accounting_id         ACS_ACCOUNTING.ACS_ACCOUNTING_ID%type;
    catalogue_document_id ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    cat_id                ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    year_week_id          PCS.PC_YEAR_WEEK.PC_YEAR_WEEK_ID%type;
    year_month_id         PCS.PC_YEAR_MONTH.PC_YEAR_MONTH_ID%type;
    date_titre            varchar2(20);
    user_ini              PCS.PC_USER.USE_INI%type;
    fin_sub_set           ACJ_SUB_SET_CAT.C_SUB_SET%type;
    mgm_sub_set           ACJ_SUB_SET_CAT.C_SUB_SET%type;
    typ_acc_jou           ACJ_JOB_TYPE.TYP_JOURNALIZE_ACCOUNTING%type;
    pragma autonomous_transaction;
  begin
    user_ini  := PCS.PC_I_LIB_SESSION.GetUserIni2;

    -- recherche de acj_job_type_id
    select     ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID
             , C_ACI_CADENCE
             , TYP_DESCRIPTION
             , ACJ_CATALOGUE_DOCUMENT_ID
             , TYP_ACI_DETAIL
             , TYP_ZERO_DOCUMENT
             , TYP_ZERO_POSITION
             , TYP_DEBIT_CREDIT_GROUP
             , nvl(TYP_JOURNALIZE_ACCOUNTING, 0)
          into job_type_id
             , aci_cadence
             , job_descr
             , catalogue_document_id
             , typ_detail
             , typ_zero_doc
             , typ_zero_pos
             , typ_dc_group
             , typ_acc_jou
          from ACJ_JOB_TYPE_S_CATALOGUE
             , ACJ_JOB_TYPE
         where ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_catalogue_id
           and ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID
    for update;

    -- d'après le type de cadence, on va rechercher act_job_id
    if aci_cadence = '1' then   -- jour
      -- recherche du travail
      select max(act_job_id)
        into job_id
        from act_job
       where acj_job_type_id = job_type_id
         and C_JOB_STATE = 'FINT'
         and to_char(JOB_ACI_CONTROL_DATE, 'YYYY,MM,DD') = to_char(aci_control_date, 'YYYY,MM,DD')
         and ACS_FINANCIAL_YEAR_ID = financial_year_id
         and (    (typ_acc_jou = 0)
              or (    typ_acc_jou = 1
                  and (    (    group_key is not null
                            and ACT_JOB.ACI_GRP_KEY = group_key)
                       or (    group_key is null
                           and ACT_JOB.ACI_GRP_KEY is null)
                      )
                 )
             )
         and (    (    restricted_period = 1
                   and nvl(ACT_JOB.ACS_PERIOD_ID, 0) = nvl(period_id, 0) )
              or (    restricted_period = 0
                  and ACT_JOB.ACS_PERIOD_ID is null)
             );

      date_titre  := to_char(aci_control_date, 'YYYY-MM-DD');
    elsif aci_cadence = '2' then   -- semaine
      -- recherche de la semaine correspondant à la date du document
      select PCS.PC_FUNCTIONS.GetYearWeek_ID(aci_control_date)
        into year_week_id
        from dual;

      -- recherche du travail
      select max(act_job_id)
        into job_id
        from ACT_JOB
           , PCS.PC_YEAR_WEEK
           , ACS_PERIOD ACS_PERIOD1
           , ACS_PERIOD ACS_PERIOD2
       where ACJ_JOB_TYPE_ID = job_type_id
         and PC_YEAR_WEEK_ID = year_week_id
         and C_JOB_STATE = 'FINT'
         and trunc(ACT_JOB.JOB_ACI_CONTROL_DATE) between PYW_BEGIN_WEEK and PYW_END_WEEK
         and trunc(ACT_JOB.JOB_ACI_CONTROL_DATE) between ACS_PERIOD1.PER_START_DATE and ACS_PERIOD1.PER_END_DATE
         and trunc(aci_control_date) between ACS_PERIOD2.PER_START_DATE and ACS_PERIOD2.PER_END_DATE
         and ACS_PERIOD1.ACS_PERIOD_ID = ACS_PERIOD2.ACS_PERIOD_ID
         and ACT_JOB.ACS_FINANCIAL_YEAR_ID = financial_year_id
         and (    (typ_acc_jou = 0)
              or (    typ_acc_jou = 1
                  and (    (    group_key is not null
                            and ACT_JOB.ACI_GRP_KEY = group_key)
                       or (    group_key is null
                           and ACT_JOB.ACI_GRP_KEY is null)
                      )
                 )
             )
         and (    (    restricted_period = 1
                   and nvl(ACT_JOB.ACS_PERIOD_ID, 0) = nvl(period_id, 0) )
              or (    restricted_period = 0
                  and ACT_JOB.ACS_PERIOD_ID is null)
             );

      select to_char(pyw_year) || '-' || to_char(pyw_week, '00')
        into date_titre
        from pcs.pc_year_week
       where pc_year_week_id = year_week_id;
    elsif aci_cadence = '3' then   -- mois
      -- recherche du mois correspondant à la date du document
      select PCS.PC_FUNCTIONS.GetYearMonth_ID(aci_control_date)
        into year_month_id
        from dual;

      -- recherche du travail
      select max(act_job_id)
        into job_id
        from ACT_JOB
           , PCS.PC_YEAR_MONTH
           , ACS_PERIOD
       where ACJ_JOB_TYPE_ID = job_type_id
         and PC_YEAR_MONTH_ID = year_month_id
         and C_JOB_STATE = 'FINT'
         and trunc(aci_control_date) between ACS_PERIOD.PER_START_DATE and ACS_PERIOD.PER_END_DATE
         and trunc(ACT_JOB.JOB_ACI_CONTROL_DATE) between ACS_PERIOD.PER_START_DATE and ACS_PERIOD.PER_END_DATE
         and trunc(ACT_JOB.JOB_ACI_CONTROL_DATE) between PYM_BEGIN_MONTH and PYM_END_MONTH
         and ACT_JOB.ACS_FINANCIAL_YEAR_ID = financial_year_id
         and (    (typ_acc_jou = 0)
              or (    typ_acc_jou = 1
                  and (    (    group_key is not null
                            and ACT_JOB.ACI_GRP_KEY = group_key)
                       or (    group_key is null
                           and ACT_JOB.ACI_GRP_KEY is null)
                      )
                 )
             )
         and (    (    restricted_period = 1
                   and nvl(ACT_JOB.ACS_PERIOD_ID, 0) = nvl(period_id, 0) )
              or (    restricted_period = 0
                  and ACT_JOB.ACS_PERIOD_ID is null)
             );

      date_titre  := PCS.PC_FUNCTIONS.DateToCharCompLang(aci_control_date, 'YYYY-MON');
    elsif aci_cadence = '4' then   -- jours DATE DOCUMENT
      -- recherche du travail
      select max(act_job_id)
        into job_id
        from act_job
       where acj_job_type_id = job_type_id
         and C_JOB_STATE = 'FINT'
         and to_char(JOB_ACI_CONTROL_DATE, 'YYYY,MM,DD') = to_char(aci_control_date2, 'YYYY,MM,DD')
         and act_job.acs_financial_year_id = financial_year_id
         and (    (typ_acc_jou = 0)
              or (    typ_acc_jou = 1
                  and (    (    group_key is not null
                            and ACT_JOB.ACI_GRP_KEY = group_key)
                       or (    group_key is null
                           and ACT_JOB.ACI_GRP_KEY is null)
                      )
                 )
             )
         and (    (    restricted_period = 1
                   and nvl(ACT_JOB.ACS_PERIOD_ID, 0) = nvl(period_id, 0) )
              or (    restricted_period = 0
                  and ACT_JOB.ACS_PERIOD_ID is null)
             );

      date_titre  := to_char(aci_control_date2, 'YYYY-MM-DD');
    elsif aci_cadence = '5' then   -- semaine
      -- recherche de la semaine correspondant à la date du document
      select PCS.PC_FUNCTIONS.GetYearWeek_ID(aci_control_date2)
        into year_week_id
        from dual;

      -- recherche du travail
      select max(act_job_id)
        into job_id
        from ACT_JOB
           , PCS.PC_YEAR_WEEK
           , ACS_PERIOD ACS_PERIOD1
           , ACS_PERIOD ACS_PERIOD2
       where ACJ_JOB_TYPE_ID = job_type_id
         and PC_YEAR_WEEK_ID = year_week_id
         and C_JOB_STATE = 'FINT'
         and trunc(ACT_JOB.JOB_ACI_CONTROL_DATE) between PYW_BEGIN_WEEK and PYW_END_WEEK
         and trunc(ACT_JOB.JOB_ACI_CONTROL_DATE) between ACS_PERIOD1.PER_START_DATE and ACS_PERIOD1.PER_END_DATE
         and trunc(aci_control_date2) between ACS_PERIOD2.PER_START_DATE and ACS_PERIOD2.PER_END_DATE
         and ACS_PERIOD1.ACS_PERIOD_ID = ACS_PERIOD2.ACS_PERIOD_ID
         and ACT_JOB.ACS_FINANCIAL_YEAR_ID = financial_year_id
         and (    (typ_acc_jou = 0)
              or (    typ_acc_jou = 1
                  and (    (    group_key is not null
                            and ACT_JOB.ACI_GRP_KEY = group_key)
                       or (    group_key is null
                           and ACT_JOB.ACI_GRP_KEY is null)
                      )
                 )
             )
         and (    (    restricted_period = 1
                   and nvl(ACT_JOB.ACS_PERIOD_ID, 0) = nvl(period_id, 0) )
              or (    restricted_period = 0
                  and ACT_JOB.ACS_PERIOD_ID is null)
             );

      select to_char(pyw_year) || '-' || to_char(pyw_week, '00')
        into date_titre
        from pcs.pc_year_week
       where pc_year_week_id = year_week_id;
    elsif aci_cadence = '6' then   -- mois
      -- recherche du mois correspondant à la date du document
      select PCS.PC_FUNCTIONS.GetYearMonth_ID(aci_control_date2)
        into year_month_id
        from dual;

      -- recherche du travail
      select max(act_job_id)
        into job_id
        from ACT_JOB
           , PCS.PC_YEAR_MONTH
           , ACS_PERIOD
       where ACJ_JOB_TYPE_ID = job_type_id
         and PC_YEAR_MONTH_ID = year_month_id
         and C_JOB_STATE = 'FINT'
         and trunc(aci_control_date2) between ACS_PERIOD.PER_START_DATE and ACS_PERIOD.PER_END_DATE
         and trunc(ACT_JOB.JOB_ACI_CONTROL_DATE) between ACS_PERIOD.PER_START_DATE and ACS_PERIOD.PER_END_DATE
         and trunc(ACT_JOB.JOB_ACI_CONTROL_DATE) between PYM_BEGIN_MONTH and PYM_END_MONTH
         and ACT_JOB.ACS_FINANCIAL_YEAR_ID = financial_year_id
         and (    (typ_acc_jou = 0)
              or (    typ_acc_jou = 1
                  and (    (    group_key is not null
                            and ACT_JOB.ACI_GRP_KEY = group_key)
                       or (    group_key is null
                           and ACT_JOB.ACI_GRP_KEY is null)
                      )
                 )
             )
         and (    (    restricted_period = 1
                   and nvl(ACT_JOB.ACS_PERIOD_ID, 0) = nvl(period_id, 0) )
              or (    restricted_period = 0
                  and ACT_JOB.ACS_PERIOD_ID is null)
             );

      date_titre  := PCS.PC_FUNCTIONS.DateToCharCompLang(aci_control_date2, 'YYYY-MON');
    end if;

    -- si on a pas trouvé de travail, on en crée un
    if job_id is null then
      if group_key is null then
        jou_descr  := substr(job_descr || ' / ' || date_titre, 1, 100);
      else
        jou_descr  := substr(job_descr || ' / ' || date_titre || ' / ' || group_key, 1, 100);
      end if;

      -- recherche d'un id pour le travail que l'on va créer
      select init_id_seq.nextval
        into job_id
        from dual;

      -- création du travail
      if aci_cadence in('1', '2', '3') then
        insert into ACT_JOB
                    (ACT_JOB_ID
                   , C_JOB_STATE
                   , JOB_DESCRIPTION
                   , ACJ_JOB_TYPE_ID
                   , ACS_FINANCIAL_YEAR_ID
                   , JOB_ACI_CONTROL_DATE
                   , ACS_PERIOD_ID
                   , ACI_GRP_KEY
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (job_id
                   , 'FINT'
                   , jou_descr
                   , job_type_id
                   , financial_year_id
                   , trunc(aci_control_date)
                   , decode(restricted_period, 1, period_id, null)
                   , decode(typ_acc_jou, 1, group_key, null)
                   , sysdate
                   , User_ini
                    );
      elsif aci_cadence in('4', '5', '6') then
        insert into ACT_JOB
                    (ACT_JOB_ID
                   , C_JOB_STATE
                   , JOB_DESCRIPTION
                   , ACJ_JOB_TYPE_ID
                   , ACS_FINANCIAL_YEAR_ID
                   , JOB_ACI_CONTROL_DATE
                   , ACS_PERIOD_ID
                   , ACI_GRP_KEY
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (job_id
                   , 'FINT'
                   , jou_descr
                   , job_type_id
                   , financial_year_id
                   , trunc(aci_control_date2)
                   , decode(restricted_period, 1, period_id, null)
                   , decode(typ_acc_jou, 1, group_key, null)
                   , sysdate
                   , User_Ini
                    );
      end if;

      -- création des état de l'événement
      insert into ACT_ETAT_EVENT
                  (ACT_ETAT_EVENT_ID
                 , ACT_JOB_ID
                 , C_TYPE_EVENT
                 , C_STATUS_EVENT
                 , ETA_SEQUENCE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval
             , job_id
             , C_TYPE_EVENT
             , 'TODO'
             , 0
             , sysdate
             , User_Ini
          from ACJ_EVENT
         where ACJ_JOB_TYPE_ID = job_type_id;

      -- recherche si financière nécessaire
      select max(b.c_sub_set)
        into fin_sub_set
        from ACJ_JOB_TYPE_S_CATALOGUE a
           , ACJ_SUB_SET_CAT b
       where A.ACJ_JOB_TYPE_ID = job_type_id
         and A.ACJ_CATALOGUE_DOCUMENT_ID = B.ACJ_CATALOGUE_DOCUMENT_ID
         and B.C_SUB_SET = 'ACC';

      if fin_sub_set is not null then
        -- recherche ACS_ACCOUNTING
        select ACS_ACCOUNTING_ID
          into accounting_id
          from ACS_ACCOUNTING
         where C_TYPE_ACCOUNTING = 'FIN';

        -- recherche du prochain numéro de journal
        select nvl(max(JOU_NUMBER), 0) + 1
          into jnumber
          from ACT_JOURNAL
         where ACS_FINANCIAL_YEAR_ID = financial_year_id
           and ACS_ACCOUNTING_ID = accounting_id;

        -- recherche d'un id pour le journal que l'on va créer
        select init_id_seq.nextval
          into journal_id
          from dual;

        -- création d'un journal
        insert into ACT_JOURNAL
                    (ACT_JOURNAL_ID
                   , JOU_DESCRIPTION
                   , ACS_ACCOUNTING_ID
                   , C_TYPE_JOURNAL
                   , ACT_JOB_ID
                   , JOU_NUMBER
                   , ACS_FINANCIAL_YEAR_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (journal_id
                   , jou_descr
                   , accounting_id
                   , 'IMP'
                   , job_id
                   , jnumber
                   , financial_year_id
                   , sysdate
                   , User_Ini
                    );

        -- création des état_journal
        insert into ACT_ETAT_JOURNAL
                    (ACT_ETAT_JOURNAL_ID
                   , ACT_JOURNAL_ID
                   , C_ETAT_JOURNAL
                   , C_SUB_SET
                   , A_DATECRE
                   , A_IDCRE
                    )
          select init_id_seq.nextval
               , journal_id
               , sa.c_etat_journal
               , sa.c_sub_set
               , sysdate
               , User_Ini
            from (select distinct decode(C_METHOD_CUMUL, 'DIR', 'PROV', 'DEF', 'BRO') c_etat_journal
                                , C_SUB_SET
                             from ACJ_SUB_SET_CAT A
                                , ACJ_JOB_TYPE_S_CATALOGUE B
                            where B.ACJ_JOB_TYPE_ID = job_type_id
                              and A.ACJ_CATALOGUE_DOCUMENT_ID = B.ACJ_CATALOGUE_DOCUMENT_ID
                              and A.C_SUB_SET <> 'CPN') sa;
      end if;

      -- recherche si analytique nécessaire
      select max(b.c_sub_set)
        into mgm_sub_set
        from ACJ_JOB_TYPE_S_CATALOGUE a
           , ACJ_SUB_SET_CAT b
       where A.ACJ_JOB_TYPE_ID = job_type_id
         and A.ACJ_CATALOGUE_DOCUMENT_ID = B.ACJ_CATALOGUE_DOCUMENT_ID
         and B.C_SUB_SET = 'CPN';

      if mgm_sub_set is not null then
        -- recherche ACS_ACCOUNTING
        select ACS_ACCOUNTING_ID
          into accounting_id
          from ACS_ACCOUNTING
         where C_TYPE_ACCOUNTING = 'MAN';

        -- recherche du prochain numéro de journal
        select nvl(max(JOU_NUMBER), 0) + 1
          into jnumber
          from ACT_JOURNAL
         where ACS_FINANCIAL_YEAR_ID = financial_year_id
           and ACS_ACCOUNTING_ID = accounting_id;

        -- recherche d'un id pour le journal que l'on va créer
        select init_id_seq.nextval
          into an_journal_id
          from dual;

        -- création d'un journal
        insert into ACT_JOURNAL
                    (ACT_JOURNAL_ID
                   , JOU_DESCRIPTION
                   , ACS_ACCOUNTING_ID
                   , C_TYPE_JOURNAL
                   , ACT_JOB_ID
                   , JOU_NUMBER
                   , ACS_FINANCIAL_YEAR_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (an_journal_id
                   , jou_descr
                   , accounting_id
                   , 'IMP'
                   , job_id
                   , jnumber
                   , financial_year_id
                   , sysdate
                   , User_Ini
                    );

        -- création de l'état_journal analytique
        insert into ACT_ETAT_JOURNAL
                    (ACT_ETAT_JOURNAL_ID
                   , ACT_JOURNAL_ID
                   , C_ETAT_JOURNAL
                   , C_SUB_SET
                   , A_DATECRE
                   , A_IDCRE
                    )
          select init_id_seq.nextval
               , an_journal_id
               , SA.C_ETAT_JOURNAL
               , SA.C_SUB_SET
               , sysdate
               , User_Ini
            from (select distinct decode(A.C_METHOD_CUMUL, 'DIR', 'PROV', 'DEF', 'BRO') C_ETAT_JOURNAL
                                , A.C_SUB_SET
                             from ACJ_SUB_SET_CAT A
                                , ACJ_JOB_TYPE_S_CATALOGUE B
                            where B.ACJ_JOB_TYPE_ID = job_type_id
                              and A.ACJ_CATALOGUE_DOCUMENT_ID = B.ACJ_CATALOGUE_DOCUMENT_ID
                              and A.C_SUB_SET = 'CPN') SA;
      end if;
    else
      -- recherche si financière nécessaire
      select max(c_sub_set)
        into fin_sub_set
        from ACJ_SUB_SET_CAT b
       where B.ACJ_CATALOGUE_DOCUMENT_ID = catalogue_document_id
         and B.C_SUB_SET = 'ACC';

      if fin_sub_set is not null then
        -- recherche du journal financier
        select max(ACT_JOURNAL_ID)
          into journal_id
          from ACT_JOURNAL
             , ACS_ACCOUNTING
         where ACT_JOB_ID = job_id
           and ACT_JOURNAL.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
           and C_TYPE_ACCOUNTING = 'FIN';
      end if;

      -- recherche si analytique nécessaire
      select max(c_sub_set)
        into mgm_sub_set
        from ACJ_SUB_SET_CAT b
       where B.ACJ_CATALOGUE_DOCUMENT_ID = catalogue_document_id
         and B.C_SUB_SET = 'CPN';

      if mgm_sub_set is not null then
        -- recherche du journal analytique
        select max(ACT_JOURNAL_ID)
          into an_journal_id
          from ACT_JOURNAL
             , ACS_ACCOUNTING
         where ACT_JOB_ID = job_id
           and ACT_JOURNAL.ACS_ACCOUNTING_ID = ACS_ACCOUNTING.ACS_ACCOUNTING_ID
           and C_TYPE_ACCOUNTING = 'MAN';
      end if;
    end if;

    commit;
  end GetJob;

  /**
  * Description
  *     Cette procedure balaye tous les documents qui sont dans l'interface
  *     elle appelle la procedure de création de document ACT
  */
  procedure Recover_all
  is
    cursor document
    is
      select ACI_DOCUMENT.ACI_DOCUMENT_ID
        from ACI_DOCUMENT
           , ACI_DOCUMENT_STATUS
       where ACI_DOCUMENT_STATUS.ACI_DOCUMENT_ID = ACI_DOCUMENT.ACI_DOCUMENT_ID
         and C_INTERFACE_CONTROL = '1';
  begin
    -- pour tous les documents_controlés
    for document_tuple in document loop
      -- création de l'entête du document
      Recover_Doc(document_tuple.ACI_DOCUMENT_ID);
    end loop;
  end Recover_all;

  /**
  * Description
  *     Reprise d'un document aci
  *     elle appelle la procedure de création de document ACT
  */
  procedure Recover_GrpKey(grp_key in varchar2)
  is
    cursor csr_document(grpkey varchar2)
    is
      select   ACI_DOCUMENT.ACI_DOCUMENT_ID
             , ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK
             , ACJ_JOB_TYPE.C_ACI_FINANCIAL_LINK JOB_C_ACI_FINANCIAL_LINK
          from ACJ_JOB_TYPE
             , ACJ_JOB_TYPE_S_CATALOGUE
             , ACI_DOCUMENT
             , ACI_DOCUMENT_STATUS
         where ACI_DOCUMENT_STATUS.ACI_DOCUMENT_ID = ACI_DOCUMENT.ACI_DOCUMENT_ID
           and ACI_DOCUMENT.ACJ_JOB_TYPE_S_CATALOGUE_ID = ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID
           and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID
           and DOC_INTEGRATION_DATE is null
           and DOC_GRP_KEY = grpkey
           and C_INTERFACE_CONTROL = '1'
           and ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK in('4', '5')
      order by ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK
             , DOC_NUMBER;

    job_id      ACT_JOB.ACT_JOB_ID%type;
    last_job_id ACT_JOB.ACT_JOB_ID%type                         := null;
    last_link   ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK%type;
  begin
    -- si TOUS les documents avec la clé de regroupement sont contrôlé OK
    if ACI_DOCUMENT_CONTROL.GrpKey_Check(grp_key) = 1 then
      -- ouverture du curseur sur les documents contrôlés
      for tpl_document in csr_document(grp_key) loop
        -- création de l'entête du document
        job_id       := Recover_Doc(tpl_document.ACI_DOCUMENT_ID);

        -- si link = '5' (regrouper) et changement de job -> regroupement des documents du job
        if     last_link = '5'
           and (   job_id != nvl(last_job_id, job_id)
                or (    job_id is null
                    and last_job_id is not null) ) then
          ACT_DOC_TRANSACTION.GroupDocuments(last_job_id);
          ACT_DOC_TRANSACTION.GroupImputations(last_job_id);
        end if;

        last_job_id  := job_id;
        last_link    := tpl_document.JOB_C_ACI_FINANCIAL_LINK;
      end loop;

      -- si dernier document est link = '5' (regrouper) -> regroupement des document du job
      if     last_link = '5'
         and last_job_id is not null then
        ACT_DOC_TRANSACTION.GroupDocuments(last_job_id);
        ACT_DOC_TRANSACTION.GroupImputations(last_job_id);
      end if;
    end if;
  end Recover_GrpKey;

  /**
  * Description
  *     Reprise d'un document aci
  *     elle appelle la procedure de création de document ACT
  */
  procedure Recover_doc(
    document_id        in number
  , aci_financial_link in ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK%type default null
  )
  is
    job_id ACT_JOB.ACT_JOB_ID%type;
  begin
    job_id  := Recover_doc(document_id, aci_financial_link);
  end Recover_doc;

  /**
  * Description
  *     Reprise d'un document aci
  *     elle appelle la procedure de création de document ACT
  */
  function Recover_doc(
    document_id        in number
  , aci_financial_link in ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK%type default null
  )
    return ACT_JOB.ACT_JOB_ID%type
  is
    document_tuple         ACI_DOCUMENT%rowtype;
    job_id                 ACT_JOB.ACT_JOB_ID%type                                 := null;
    typ_detail             ACJ_JOB_TYPE.TYP_ACI_DETAIL%type;
    typ_zero_doc           ACJ_JOB_TYPE.TYP_ZERO_DOCUMENT%type;
    typ_zero_pos           ACJ_JOB_TYPE.TYP_ZERO_POSITION%type;
    typ_dc_group           ACJ_JOB_TYPE.TYP_DEBIT_CREDIT_GROUP%type;
    doc_zero               number(1);
    journal_id             ACT_JOURNAL.ACT_JOURNAL_ID%type;
    an_journal_id          ACT_JOURNAL.ACT_JOURNAL_ID%type;
    catalogue_document_id  ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    fin_acc_s_payment_id   ACJ_CATALOGUE_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID%type;
    new_document_id        ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    new_part_imputation_id ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    new_expiry_id          ACT_EXPIRY.ACT_EXPIRY_ID%type;
    old_part_imputation_id ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type;
    interface_control      ACI_DOCUMENT.C_INTERFACE_CONTROL%type;
    interface_link         ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK%type;
    transaction_date       ACI_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
    transaction_date2      ACI_DOCUMENT.DOC_DOCUMENT_DATE%type;
    period_id              ACS_PERIOD.ACS_PERIOD_ID%type;
    vat_currency_id        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    PreEntryDocument       ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    dc_type                varchar2(1);
    GroupKey               ACI_DOCUMENT.DOC_GRP_KEY%type;
    document_number        ACT_DOCUMENT.DOC_NUMBER%type;
    restricted_period      ACJ_JOB_TYPE.TYP_RESTRICT_PERIOD%type;
    type_catalogue         ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
    num_currency           number;
    financial_currency_id  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    financial_account_id   ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    cat_description        ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type;
    sub_set                ACJ_SUB_SET_CAT.C_SUB_SET%type;
    base_price             ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    exchange_rate          ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    tot_amount_lc          ACT_DET_PAYMENT.DET_PAIED_LC%type;
    tot_amount_fc          ACT_DET_PAYMENT.DET_PAIED_FC%type;
    tot_amount_eur         ACT_DET_PAYMENT.DET_PAIED_EUR%type;
    tot_amount_lc_d        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    tot_amount_lc_c        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    tot_amount_fc_d        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    tot_amount_fc_c        ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    tot_amount_eur_d       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    tot_amount_eur_c       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vTestDocId             ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    lb_exportXmlResult  BOOLEAN;
  begin
    if aci_financial_link is null then
      -- Recherche de la méthode d'intégration
      select C_ACI_FINANCIAL_LINK
        into interface_link
        from ACI_DOCUMENT_STATUS
       where ACI_DOCUMENT_ID = document_id;
    else
      interface_link  := aci_financial_link;
    end if;

    -- Transfert ACI entre sociétés via queues.
    if (interface_link = '8') then
      -- exportation du document ACI au format XML (transfert des documents ACI entre sociétés via la mécanique des Queues)
      -- la règle de gestion régissant l'exportation du document ACI est définie dans la fonction ExportAciDocument
      lb_exportXmlResult := aci_queue_functions.ExportAciDocument(document_id);
      return null;
    end if;

    -- Simulation
    if interface_link = '7' then
      update ACI_DOCUMENT
         set DOC_INTEGRATION_DATE = sysdate
           , ACT_DOCUMENT_ID = 0
       where ACI_DOCUMENT_ID = document_id;

      return null;
    end if;

    -- test si le document est contrôlé, sinon on ne peut pas faire la reprise
    select C_INTERFACE_CONTROL
      into interface_control
      from ACI_DOCUMENT
     where ACI_DOCUMENT_ID = document_id;

    -- initialisation du user si la session n'a pas été initialisé
    if PCS.PC_I_LIB_SESSION.GetUserId is null then
      PCS.PC_I_LIB_SESSION.SetUserId(null);
    end if;

    -- contrôle si document déjà intégré
    begin
      select     ACT_DOCUMENT_ID
            into vTestDocId
            from ACI_DOCUMENT
           where ACI_DOCUMENT_ID = document_id
             and ACT_DOCUMENT_ID is null
             and DOC_INTEGRATION_DATE is null
      for update wait 2;
    exception
      when timeout_on_resource then
        return null;
      when no_data_found then
        return null;
    end;

    -- si déjà intégré, on quitte
    if vTestDocId is not null then
      return null;
    end if;

    -- On fait la reprise seulement si le document est contrôlé
    if interface_control = '1' then
      -- recherche info sur document
      select *
        into document_tuple
        from ACI_DOCUMENT
       where ACI_DOCUMENT_ID = document_id;

      -- recherche du catalogue de document
      select max(ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID)
           , max(ACJ_CATALOGUE_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID)
           , max(ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE)
           , nvl(max(ACJ_JOB_TYPE.TYP_RESTRICT_PERIOD), 0)
        into catalogue_document_id
           , fin_acc_s_payment_id
           , type_catalogue
           , restricted_period
        from ACJ_JOB_TYPE
           , ACJ_CATALOGUE_DOCUMENT
           , ACJ_JOB_TYPE_S_CATALOGUE
       where ACJ_JOB_TYPE_S_CATALOGUE_ID = document_tuple.acj_job_type_s_catalogue_id
         and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
         and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID;

      select nvl(nvl(IMF_TRANSACTION_DATE, IMM_TRANSACTION_DATE), DOC_DOCUMENT_DATE)
           , DOC_DOCUMENT_DATE
           , nvl(ACI_FINANCIAL_IMPUTATION.ACS_PERIOD_ID, ACI_MGM_IMPUTATION.ACS_PERIOD_ID)
           , DOC_GRP_KEY
        into transaction_date
           , transaction_date2
           , period_id
           , GroupKey
        from ACI_MGM_IMPUTATION
           , ACI_FINANCIAL_IMPUTATION
           , ACI_DOCUMENT
       where ACI_DOCUMENT.ACI_DOCUMENT_ID = document_id
         and ACI_FINANCIAL_IMPUTATION.ACI_DOCUMENT_ID(+) = ACI_DOCUMENT.ACI_DOCUMENT_ID
         and ACI_MGM_IMPUTATION.ACI_DOCUMENT_ID(+) = ACI_DOCUMENT.ACI_DOCUMENT_ID
         and IMF_PRIMARY(+) = 1
         and IMM_PRIMARY(+) = 1;

      if period_id is null then
        -- recherche de la période active
        select max(ACS_PERIOD_ID)
          into period_id
          from ACS_PERIOD
         where trunc(transaction_date) between PER_START_DATE and PER_END_DATE
           and ACS_FINANCIAL_YEAR_ID = document_tuple.acs_financial_year_id
           and C_STATE_PERIOD = 'ACT'
           and C_TYPE_PERIOD = '2';
      end if;

      -- recherche ou création du travail
      GetJob(document_tuple.acj_job_type_s_catalogue_id
           , transaction_date
           , transaction_date2
           , document_tuple.acs_financial_year_id
           , period_id
           , restricted_period
           , GroupKey
           , job_id
           , typ_detail
           , typ_zero_doc
           , typ_zero_pos
           , typ_dc_group
           , journal_id
           , an_journal_id
            );

      -- regarde d'après les monatnt des imputations, si on a affaire à un document à zero
      select 1 - sign(count(*) )
        into doc_zero
        from ACI_FINANCIAL_IMPUTATION
       where (   IMF_AMOUNT_LC_D <> 0
              or IMF_AMOUNT_LC_C <> 0)
         and ACI_DOCUMENT_ID = document_id;

      -- controle identique sur le imputation analytiques
      if doc_zero = 1 then
        select 1 - sign(count(*) )
          into doc_zero
          from ACI_MGM_IMPUTATION
         where (   IMM_AMOUNT_LC_D <> 0
                or IMM_AMOUNT_LC_C <> 0)
           and ACI_DOCUMENT_ID = document_id;
      end if;

      -- test si la monnaie TVA est différente de la monnaie de base
      if     document_tuple.acs_acs_financial_currency_id is not null
         and document_tuple.acs_acs_financial_currency_id <> ACS_FUNCTION.GetLocalCurrencyId then
        vat_currency_id  := document_tuple.acs_acs_financial_currency_id;
      else
        vat_currency_id  := 0;
      end if;

      if not(    doc_zero = 1
             and typ_zero_doc = 0) then
        if type_catalogue = '3' then
          Recover_Det_Payment_Manual(document_id, job_id, journal_id, an_journal_id, type_catalogue);

          -- mise à jour du flag indiquant que le document a été repris en finance
          update ACI_DOCUMENT
             set DOC_INTEGRATION_DATE = sysdate
           where ACI_DOCUMENT_ID = document_id;
        else
          if document_tuple.DOC_NUMBER is null then
            -- recherche du numéro de document
            ACT_FUNCTIONS.GetDocNumber(catalogue_document_id, document_tuple.acs_financial_year_id, document_number);
          else
            document_number  := document_tuple.DOC_NUMBER;
          end if;

          -- Si le document est à 0, alors ont reprend toutes les imputations quel que soit
          -- la valeur du flag "Reprise des position à 0"
          if     doc_zero = 1
             and document_tuple.DOC_TOTAL_AMOUNT_DC = 0 then
            typ_zero_pos  := 1;
          end if;

          -- recherche un ID pour le document que l'on va créer
          select init_id_seq.nextval
            into new_document_id
            from dual;

          insert into ACT_DOCUMENT
                      (ACT_DOCUMENT_ID
                     , ACT_JOB_ID
                     , ACT_JOURNAL_ID
                     , ACT_ACT_JOURNAL_ID
                     , DOC_NUMBER
                     , DOC_TOTAL_AMOUNT_DC
                     , DOC_TOTAL_AMOUNT_EUR
                     , DOC_CHARGES_LC
                     , DOC_DOCUMENT_DATE
                     , DOC_COMMENT
                     , DOC_CCP_TAX
                     , DOC_ORDER_NO
                     , DOC_EFFECTIVE_DATE
                     , DOC_EXECUTIVE_DATE
                     , DOC_ESTABL_DATE
                     , C_STATUS_DOCUMENT
                     , C_CURR_RATE_COVER_TYPE
                     , DIC_DOC_SOURCE_ID
                     , DIC_DOC_DESTINATION_ID
                     , ACS_FINANCIAL_YEAR_ID
                     , ACS_FINANCIAL_CURRENCY_ID
                     , ACJ_CATALOGUE_DOCUMENT_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , DOC_DOCUMENT_ID
                     , STM_STOCK_MOVEMENT_ID
                     , DIC_ACT_DOC_FREE_CODE1_ID
                     , DIC_ACT_DOC_FREE_CODE2_ID
                     , DIC_ACT_DOC_FREE_CODE3_ID
                     , DIC_ACT_DOC_FREE_CODE4_ID
                     , DIC_ACT_DOC_FREE_CODE5_ID
                     , DOC_FREE_TEXT1
                     , DOC_FREE_TEXT2
                     , DOC_FREE_TEXT3
                     , DOC_FREE_TEXT4
                     , DOC_FREE_TEXT5
                     , DOC_FREE_NUMBER1
                     , DOC_FREE_NUMBER2
                     , DOC_FREE_NUMBER3
                     , DOC_FREE_NUMBER4
                     , DOC_FREE_NUMBER5
                     , DOC_FREE_DATE1
                     , DOC_FREE_DATE2
                     , DOC_FREE_DATE3
                     , DOC_FREE_DATE4
                     , DOC_FREE_DATE5
                     , DOC_FREE_MEMO1
                     , DOC_FREE_MEMO2
                     , DOC_FREE_MEMO3
                     , DOC_FREE_MEMO4
                     , DOC_FREE_MEMO5
                     , COM_NAME_DOC
                     , COM_NAME_ACT
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (new_document_id
                     , job_id
                     , journal_id
                     , an_journal_id
                     , document_number
                     , nvl(document_tuple.DOC_TOTAL_AMOUNT_DC, 0)
                     , nvl(document_tuple.DOC_TOTAL_AMOUNT_EUR, 0)
                     , nvl(document_tuple.DOC_CHARGES_LC, 0)
                     , document_tuple.DOC_DOCUMENT_DATE
                     , document_tuple.DOC_COMMENT
                     , document_tuple.DOC_CCP_TAX
                     , document_tuple.DOC_ORDER_NO
                     , document_tuple.DOC_EFFECTIVE_DATE
                     , document_tuple.DOC_EXECUTIVE_DATE
                     , document_tuple.DOC_ESTABL_DATE
                     , nvl(document_tuple.c_status_document, 'DEF')
                     , document_tuple.c_curr_rate_cover_type
                     , document_tuple.dic_doc_source_id
                     , document_tuple.dic_doc_destination_id
                     , document_tuple.acs_financial_year_id
                     , document_tuple.acs_financial_currency_id
                     , catalogue_document_id
                     , document_tuple.acs_financial_account_id
                     , document_tuple.doc_document_id
                     , document_tuple.stm_stock_movement_id
                     , document_tuple.DIC_ACT_DOC_FREE_CODE1_ID
                     , document_tuple.DIC_ACT_DOC_FREE_CODE2_ID
                     , document_tuple.DIC_ACT_DOC_FREE_CODE3_ID
                     , document_tuple.DIC_ACT_DOC_FREE_CODE4_ID
                     , document_tuple.DIC_ACT_DOC_FREE_CODE5_ID
                     , document_tuple.DOC_FREE_TEXT1
                     , document_tuple.DOC_FREE_TEXT2
                     , document_tuple.DOC_FREE_TEXT3
                     , document_tuple.DOC_FREE_TEXT4
                     , document_tuple.DOC_FREE_TEXT5
                     , document_tuple.DOC_FREE_NUMBER1
                     , document_tuple.DOC_FREE_NUMBER2
                     , document_tuple.DOC_FREE_NUMBER3
                     , document_tuple.DOC_FREE_NUMBER4
                     , document_tuple.DOC_FREE_NUMBER5
                     , document_tuple.DOC_FREE_DATE1
                     , document_tuple.DOC_FREE_DATE2
                     , document_tuple.DOC_FREE_DATE3
                     , document_tuple.DOC_FREE_DATE4
                     , document_tuple.DOC_FREE_DATE5
                     , document_tuple.DOC_FREE_MEMO1
                     , document_tuple.DOC_FREE_MEMO2
                     , document_tuple.DOC_FREE_MEMO3
                     , document_tuple.DOC_FREE_MEMO4
                     , document_tuple.DOC_FREE_MEMO5
                     , document_tuple.com_name_doc
                     , document_tuple.com_name_act
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          -- création de l'imputation partenaire
          Recover_Part_Imp(document_id
                         , fin_acc_s_payment_id
                         , document_tuple.acs_financial_year_id
                         , document_tuple.doc_document_date
                         , job_id
                         , journal_id
                         , an_journal_id
                         , new_document_id
                         , type_catalogue
                         , new_part_imputation_id
                         , new_expiry_id
                         , old_part_imputation_id
                          );

          -- Reprise détaillée
          if typ_detail = 1 then
            -- Imputations financières et analytiques liées
            Recover_Fin_Imp_Detail(document_id
                                 , new_document_id
                                 , new_part_imputation_id
                                 , document_tuple.acs_financial_year_id
                                 , vat_currency_id
                                 , typ_zero_pos
                                 , catalogue_document_id
                                 , document_number
                                 , dc_type
                                  );
            -- Imputations_analytiques indépendantes
            Recover_Mgm_Imp_Detail(document_id
                                 , new_document_id
                                 , document_tuple.acs_financial_year_id
                                 , typ_zero_pos
                                 , catalogue_document_id
                                  );
          -- Reprise cumulée
          elsif(typ_dc_group = 0) then
            -- Imputations financières et analytiques liées
            Recover_Fin_Imp_Cumul(document_id
                                , new_document_id
                                , new_part_imputation_id
                                , document_tuple.acs_financial_year_id
                                , vat_currency_id
                                , typ_zero_pos
                                , catalogue_document_id
                                , document_number
                                , dc_type
                                 );
            -- Imputations_analytiques indépendantes
            Recover_Mgm_Imp_Cumul(document_id
                                , new_document_id
                                , document_tuple.acs_financial_year_id
                                , typ_zero_pos
                                , catalogue_document_id
                                 );
          -- reprise cumulée avec cumul débit-crédit
          else
            -- Imputations financières et analytiques liées
            Recover_Fin_Imp_Cumul_Group(document_id
                                      , new_document_id
                                      , new_part_imputation_id
                                      , document_tuple.acs_financial_year_id
                                      , vat_currency_id
                                      , typ_zero_pos
                                      , catalogue_document_id
                                      , document_number
                                      , dc_type
                                       );
            -- Imputations_analytiques indépendantes
            Recover_Mgm_Imp_Cumul_Group(document_id
                                      , new_document_id
                                      , document_tuple.acs_financial_year_id
                                      , typ_zero_pos
                                      , catalogue_document_id
                                       );
          end if;

          -- reprise des paiements directs + couvertures
          Recover_Det_Payment_Direct(document_id
                                   , job_id
                                   , journal_id
                                   , an_journal_id
                                   , new_document_id
                                   , dc_type
                                   , type_catalogue
                                    );
          Recover_Det_Payment_Imput(document_id
                                  , job_id
                                  , journal_id
                                  , an_journal_id
                                  , new_document_id
                                  , dc_type
                                  , type_catalogue
                                   );

          -- Indique que l'état du document
          insert into ACT_DOCUMENT_STATUS
                      (ACT_DOCUMENT_STATUS_ID
                     , ACT_DOCUMENT_ID
                     , DOC_OK
                      )
               values (init_id_seq.nextval
                     , new_document_id
                     , 0
                      );

          -- Calcul des cumuls du document créé
          ACT_DOC_TRANSACTION.DocImputations(new_document_id, 0);

          -- mise à jour du flag indiquant que le document a été repris en finance
          update ACI_DOCUMENT
             set DOC_INTEGRATION_DATE = sysdate
               , ACT_DOCUMENT_ID = new_document_id
           where ACI_DOCUMENT_ID = document_id;

          -- mise à jour à intégré du statut du système d'échange de données
          update PCS.PC_EXCHANGE_DATA_IN
             set C_EDI_STATUS_ACT = '3'
               , ACT_DOCUMENT_ID = new_document_id
           where ACI_DOCUMENT_ID = document_id;

           -- mise à jour de la table "Historique d'imputations d'heures en ACI"
           update FAL_ACI_TIME_HIST_DET
               set ACT_DOCUMENT_ID = new_document_id
             where ACI_DOCUMENT_ID = document_id;

           -- mise à jour de la table "Ecart d'élément de coût"
           update FAL_ELT_COST_DIFF_DET
               set ACT_DOCUMENT_ID = new_document_id
             where ACI_DOCUMENT_ID = document_id;

        end if;
      else
        -- mise à jour du flag indiquant que le document a été traité mais pas repris en finance
        update ACI_DOCUMENT
           set DOC_INTEGRATION_DATE = sysdate
         where ACI_DOCUMENT_ID = document_id;
      end if;

      -- Màj si necessaire (selon EBPP) de ACT_DOCUMENT_ID de DOC_DOCUMENT
      Update_EBPP(document_id, new_document_id);

      select max(ACT_DOCUMENT_ID)
        into PreEntryDocument
        from ACT_DOC_RECEIPT
       where ACI_DOCUMENT_ID = document_id;

      -- Dans le cas ou un document de présaisie est lié
      if PreEntryDocument is not null then
        -- Maj info de présaisie
        update ACT_DOCUMENT
           set (DOC_PRE_ENTRY_VALIDATION, DOC_PRE_ENTRY_INI, DOC_PRE_ENTRY_NUMBER, DOC_COMMENT) =
                 (select DOC_PRE_ENTRY_VALIDATION
                       , DOC_PRE_ENTRY_INI
                       , DOC_NUMBER
                       , DOC_COMMENT
                    from ACT_DOCUMENT
                   where ACT_DOCUMENT_ID = PreEntryDocument)
         where ACT_DOCUMENT_ID = new_document_id;

        -- Suppression des cumuls
        ACT_DOC_TRANSACTION.DocImputations(PreEntryDocument, 0);

        -- redirection de COM_IMAGE_FILE vers le nouveau document
        update COM_IMAGE_FILES
           set IMF_REC_ID = new_document_id
         where IMF_TABLE = 'ACT_DOCUMENT'
           and IMF_REC_ID = PreEntryDocument;

        -- Suppression du numéro document pour éviter qu'il soit repris
        --   dans les numéros libres lors de l'effacement (FIN-050621-54146)
        update ACT_DOCUMENT
           set DOC_NUMBER = null
         where ACT_DOCUMENT_ID = PreEntryDocument;

        -- Effacement de l'éventuel document pré-saisi
        delete from ACT_DOCUMENT
              where ACT_DOCUMENT_ID = PreEntryDocument;
      end if;

      -- Màj de la date modification et user pour màj par trigger du nbre de document du job
      update ACT_JOB
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI
       where ACT_JOB_ID = job_id;
    end if;

    return job_id;
  end Recover_doc;

  /**
  * Description
  *    reprise de l'imputation partenaire
  */
  procedure Recover_Part_Imp(
    document_id            in     number
  , fin_acc_s_payment_id   in     number
  , financial_year_id      in     number
  , document_date          in     date
  , job_id                 in     number
  , journal_id             in     number
  , an_journal_id          in     number
  , new_document_id        in     number
  , type_catalogue         in     varchar2
  , new_part_imputation_id in out number
  , new_expiry_id          in out number
  , old_part_imputation_id in out number
  )
  is
    cursor part_imputation(document_id number)
    is
      select *
        from ACI_PART_IMPUTATION
       where ACI_DOCUMENT_ID = document_id;
  begin
    for part_imputation_tuple in part_imputation(document_id) loop
      -- recherche un ID pour l'imputation partenaire que l'on va créer
      select init_id_seq.nextval
        into new_part_imputation_id
        from dual;

      -- récupère l'id de l'imputation partenaire ACI
      old_part_imputation_id  := part_imputation_tuple.aci_part_imputation_id;

      -- Création d'un tuple pour l'imputation partenaire
      insert into ACT_PART_IMPUTATION
                  (ACT_PART_IMPUTATION_ID
                 , ACT_DOCUMENT_ID
                 , PAR_DOCUMENT
                 , PAR_BLOCKED_DOCUMENT
                 , PAC_CUSTOM_PARTNER_ID
                 , PAC_PAYMENT_CONDITION_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , DIC_PRIORITY_PAYMENT_ID
                 , DIC_CENTER_PAYMENT_ID
                 , DIC_LEVEL_PRIORITY_ID
                 , DIC_BLOCKED_REASON_ID
                 , PAC_FINANCIAL_REFERENCE_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , PAR_PAIED_LC
                 , PAR_CHARGES_LC
                 , PAR_PAIED_FC
                 , PAR_CHARGES_FC
                 , PAR_EXCHANGE_RATE
                 , PAR_BASE_PRICE
                 , PAC_ADDRESS_ID
                 , PAR_REMIND_DATE
                 , PAR_REMIND_PRINTDATE
                 , PAC_COMMUNICATION_ID
                 , DOC_DATE_DELIVERY
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (new_part_imputation_id
                 , new_document_id
                 , part_imputation_tuple.PAR_DOCUMENT
                 , part_imputation_tuple.PAR_BLOCKED_DOCUMENT
                 , part_imputation_tuple.pac_custom_partner_id
                 , part_imputation_tuple.pac_payment_condition_id
                 , part_imputation_tuple.pac_supplier_partner_id
                 , part_imputation_tuple.DIC_PRIORITY_PAYMENT_ID
                 , part_imputation_tuple.DIC_CENTER_PAYMENT_ID
                 , part_imputation_tuple.DIC_LEVEL_PRIORITY_ID
                 , part_imputation_tuple.DIC_BLOCKED_REASON_ID
                 , part_imputation_tuple.pac_financial_reference_id
                 , part_imputation_tuple.acs_financial_currency_id
                 , part_imputation_tuple.acs_acs_financial_currency_id
                 , nvl(part_imputation_tuple.PAR_PAIED_LC, 0)
                 , nvl(part_imputation_tuple.PAR_CHARGES_LC, 0)
                 , nvl(part_imputation_tuple.PAR_PAIED_FC, 0)
                 , nvl(part_imputation_tuple.PAR_CHARGES_FC, 0)
                 , nvl(part_imputation_tuple.PAR_EXCHANGE_RATE, 0)
                 , nvl(part_imputation_tuple.PAR_BASE_PRICE, 0)
                 , part_imputation_tuple.PAC_ADDRESS_ID
                 , part_imputation_tuple.PAR_REMIND_DATE
                 , part_imputation_tuple.PAR_REMIND_PRINTDATE
                 , part_imputation_tuple.PAC_COMMUNICATION_ID
                 , part_imputation_tuple.DOC_DATE_DELIVERY
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      -- reprise des échéances
      Recover_Expiry(part_imputation_tuple.aci_part_imputation_id
                   , nvl(part_imputation_tuple.acs_fin_acc_s_payment_id, fin_acc_s_payment_id)
                   , new_document_id
                   , new_part_imputation_id
                   , new_expiry_id
                    );
      -- Création des lettrages/paiements
      Recover_Det_Payment(part_imputation_tuple.ACI_PART_IMPUTATION_ID
                        , nvl(part_imputation_tuple.pac_supplier_partner_id
                            , part_imputation_tuple.pac_custom_partner_id)
                        , document_date
                        , part_imputation_tuple.acs_financial_currency_id
                        , financial_year_id
                        , new_part_imputation_id
                        , new_document_id
                        , type_catalogue
                         );
      -- Création des relances
      Recover_Reminder(part_imputation_tuple.ACI_PART_IMPUTATION_ID
                     , nvl(part_imputation_tuple.pac_supplier_partner_id, part_imputation_tuple.pac_custom_partner_id)
                     , new_part_imputation_id
                     , new_document_id
                      );
    end loop;
  end Recover_Part_Imp;

  /**
  * Description
  *   reprise des échéances
  */
  procedure Recover_Expiry(
    part_imputation_id     in     number
  , fin_acc_s_payment_id   in     number
  , new_document_id        in     number
  , new_part_imputation_id in     number
  , new_expiry_id          out    number
  )
  is
    cursor expiry(part_imputation_id number)
    is
      select   *
          from ACI_EXPIRY
         where ACI_PART_IMPUTATION_ID = part_imputation_id
      order by EXP_SLICE
             , EXP_CALC_NET desc;

    strBvrRef         ACT_EXPIRY.EXP_REF_BVR%type;
    strBvrCode        ACT_EXPIRY.EXP_BVR_CODE%type;
    sliceNo           ACT_EXPIRY.EXP_SLICE%type                default 0;
    DateInterestValue ACT_EXPIRY.EXP_INTEREST_VALUE%type;
    vtype_support     ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type;
    vStatus           ACT_EXPIRY.C_STATUS_EXPIRY%type;
  begin
    -- Recherche de la date calculé de la 1ere tranche nette pour mettre dans la date valeur interet
    select min(EXP_CALCULATED)
      into DateInterestValue
      from ACI_EXPIRY
     where ACI_PART_IMPUTATION_ID = part_imputation_id
       and EXP_CALC_NET = 1
       and EXP_SLICE = 1;

    select max(MET.C_TYPE_SUPPORT)
      into vtype_support
      from ACS_PAYMENT_METHOD MET
         , ACS_FIN_ACC_S_PAYMENT FPAY
     where FPAY.ACS_FIN_ACC_S_PAYMENT_ID = fin_acc_s_payment_id
       and FPAY.ACS_PAYMENT_METHOD_ID = MET.ACS_PAYMENT_METHOD_ID;

    -- pour chaque échéance
    for expiry_tuple in expiry(part_imputation_id) loop
      -- Si la transaction doit avoir une référence BVR et qu'elle n'en a pas,
      -- On génère une référence et un code
      if     fin_acc_s_payment_id is not null
         and vtype_support in('33', '34', '35', '50', '51', '56')
         and expiry_tuple.EXP_REF_BVR is null
         and expiry_tuple.EXP_BVR_CODE is null then
        if sliceNo <> expiry_tuple.EXP_SLICE then
          ACS_FUNCTION.Set_BVR_Ref(fin_acc_s_payment_id, '2', to_char(new_document_id), strBvrRef);
        end if;

        strBvrCode  := ACS_FUNCTION.Get_BVR_Coding_Line(fin_acc_s_payment_id, strBVRRef, expiry_tuple.EXP_AMOUNT_LC);
      else
        strBvrRef  := trim(expiry_tuple.EXP_REF_BVR);
      end if;

      if sliceNo <> expiry_tuple.EXP_SLICE then
        sliceNo  := expiry_tuple.EXP_SLICE;
      end if;

      if     expiry_tuple.EXP_CALC_NET = 1
         and expiry_tuple.EXP_AMOUNT_LC = 0
         and expiry_tuple.EXP_AMOUNT_FC = 0 then
        vStatus  := '1';
      else
        vStatus  := expiry_tuple.C_STATUS_EXPIRY;
      end if;

      insert into ACT_EXPIRY
                  (ACT_EXPIRY_ID
                 , ACT_DOCUMENT_ID
                 , ACT_PART_IMPUTATION_ID
                 , EXP_ADAPTED
                 , EXP_CALCULATED
                 , EXP_INTEREST_VALUE
                 , EXP_AMOUNT_LC
                 , EXP_AMOUNT_FC
                 , EXP_AMOUNT_EUR
                 , EXP_SLICE
                 , EXP_DISCOUNT_LC
                 , EXP_DISCOUNT_FC
                 , EXP_DISCOUNT_EUR
                 , EXP_POURCENT
                 , EXP_CALC_NET
                 , C_STATUS_EXPIRY
                 , EXP_DATE_PMT_TOT
                 , EXP_BVR_CODE
                 , EXP_REF_BVR
                 , ACS_FIN_ACC_S_PAYMENT_ID
                 , EXP_AMOUNT_PROV_LC
                 , EXP_AMOUNT_PROV_FC
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , new_document_id
                 , new_part_imputation_id
                 , expiry_tuple.EXP_ADAPTED
                 , expiry_tuple.EXP_CALCULATED
                 , decode(expiry_tuple.EXP_CALC_NET, 1, DateInterestValue, null)
                 , nvl(expiry_tuple.EXP_AMOUNT_LC, 0)
                 , nvl(expiry_tuple.EXP_AMOUNT_FC, 0)
                 , nvl(expiry_tuple.EXP_AMOUNT_EUR, 0)
                 , expiry_tuple.EXP_SLICE
                 , nvl(expiry_tuple.EXP_DISCOUNT_LC, 0)
                 , nvl(expiry_tuple.EXP_DISCOUNT_FC, 0)
                 , nvl(expiry_tuple.EXP_DISCOUNT_EUR, 0)
                 , expiry_tuple.EXP_POURCENT
                 , expiry_tuple.EXP_CALC_NET
                 , vStatus
                 , decode(vStatus
                        , '1', nvl(expiry_tuple.EXP_DATE_PMT_TOT, trunc(sysdate) )
                        , expiry_tuple.EXP_DATE_PMT_TOT
                         )
                 , nvl(expiry_tuple.EXP_BVR_CODE, strBvrCode)
                 , strBvrRef
                 , nvl(expiry_tuple.ACS_FIN_ACC_S_PAYMENT_ID, fin_acc_s_payment_id)
                 , expiry_tuple.EXP_AMOUNT_PROV_LC
                 , expiry_tuple.EXP_AMOUNT_PROV_FC
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;

    select min(ACT_EXPIRY_ID)
      into new_expiry_id
      from ACT_EXPIRY
     where ACT_PART_IMPUTATION_ID = new_part_imputation_id
       and EXP_SLICE = 1
       and EXP_CALC_NET + 0 = 1;
  end Recover_Expiry;

  /**
  * Description
  *    reprise des paiements (lettrages)
  */
  procedure Recover_Det_Payment(
    aPartImputationId    in number
  , aThirdId             in number
  , aDocumentDate        in date
  , aDocumentCurrencyId  in number
  , aFinancialYearId     in number
  , aNewPartImputationId in number
  , aNewDocumentId       in number
  , type_catalogue       in varchar2
  )
  is
    cursor detPayment(cPartImputationId number)
    is
      select *
        from ACI_DET_PAYMENT
       where ACI_PART_IMPUTATION_ID = cPartImputationId;

    expiryId             ACT_EXPIRY.ACT_EXPIRY_ID%type;
    periodId             ACS_PERIOD.ACS_PERIOD_ID%type;
    paymentDescription   ACI_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    det_payment_id       ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type         := null;
    tblLinkDetPayACI_ACT TtblLinkDetPayACI_ACT                           := TtblLinkDetPayACI_ACT();
  begin
    if type_catalogue in('2', '5', '6') then
      return;
    end if;

    for detPayment_tuple in detPayment(aPartImputationId) loop
      if detPayment_tuple.ACT_EXPIRY_ID is null then
        -- recherche de l'échéance liée au lettrage
        select exp.ACT_EXPIRY_ID
          into expiryId
          from ACT_EXPIRY exp
             , ACT_PART_IMPUTATION PAR
         where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
           and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
           and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
           and EXP_SLICE = nvl(detPayment_tuple.DET_SEQ_NUMBER, 1)
           and EXP_CALC_NET + 0 = 1;
      -- and EXP.C_STATUS_EXPIRY = 0;
      else
        expiryId  := detPayment_tuple.ACT_EXPIRY_ID;
      end if;

      select init_id_seq.nextval
        into det_payment_id
        from dual;

      -- insertion du détail paiement
      insert into ACT_DET_PAYMENT
                  (ACT_DET_PAYMENT_ID
                 , ACT_EXPIRY_ID
                 , ACT_DOCUMENT_ID
                 , ACT_PART_IMPUTATION_ID
                 , DET_PAIED_LC
                 , DET_PAIED_FC
                 , DET_PAIED_EUR
                 , DET_CHARGES_LC
                 , DET_CHARGES_FC
                 , DET_CHARGES_EUR
                 , DET_DISCOUNT_LC
                 , DET_DISCOUNT_FC
                 , DET_DISCOUNT_EUR
                 , DET_DEDUCTION_LC
                 , DET_DEDUCTION_FC
                 , DET_DEDUCTION_EUR
                 , DET_LETTRAGE_NO
                 , DET_DIFF_EXCHANGE
                 , DET_TRANSACTION_TYPE
                 , DET_SEQ_NUMBER
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (det_payment_id
                 , expiryId
                 , aNewDocumentId
                 , aNewPartImputationId
                 , nvl(detPayment_tuple.DET_PAIED_LC, 0)
                 , nvl(detPayment_tuple.DET_PAIED_FC, 0)
                 , nvl(detPayment_tuple.DET_PAIED_EUR, 0)
                 , nvl(detPayment_tuple.DET_CHARGES_LC, 0)
                 , nvl(detPayment_tuple.DET_CHARGES_FC, 0)
                 , nvl(detPayment_tuple.DET_CHARGES_EUR, 0)
                 , nvl(detPayment_tuple.DET_DISCOUNT_LC, 0)
                 , nvl(detPayment_tuple.DET_DISCOUNT_FC, 0)
                 , nvl(detPayment_tuple.DET_DISCOUNT_EUR, 0)
                 , nvl(detPayment_tuple.DET_DEDUCTION_LC, 0)
                 , nvl(detPayment_tuple.DET_DEDUCTION_FC, 0)
                 , nvl(detPayment_tuple.DET_DEDUCTION_EUR, 0)
                 , detPayment_tuple.DET_LETTRAGE_NO
                 , nvl(detPayment_tuple.DET_DIFF_EXCHANGE, 0)
                 , detPayment_tuple.DET_TRANSACTION_TYPE
                 , nvl(detPayment_tuple.DET_SEQ_NUMBER, 1)
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      tblLinkDetPayACI_ACT.extend;
      tblLinkDetPayACI_ACT(tblLinkDetPayACI_ACT.last).ACT_DET_PAYMENT_ID  := det_payment_id;
      tblLinkDetPayACI_ACT(tblLinkDetPayACI_ACT.last).ACI_DET_PAYMENT_ID  := detPayment_tuple.aci_det_payment_id;
    end loop;

    -- si on a créé au moins un det_payment
    if det_payment_id is not null then
      -- recherche de la période active
      select max(ACS_PERIOD_ID)
        into periodId
        from ACS_PERIOD
       where aDocumentDate between PER_START_DATE and trunc(PER_END_DATE) + 0.99999
         and ACS_FINANCIAL_YEAR_ID = aFinancialYearId
         and C_STATE_PERIOD = 'ACT'
         and C_TYPE_PERIOD = '2';

      -- génération des contres écritures du document
      ACT_PROCESS_PAYMENT.ProcessPayment
        (aNewDocumentId
       , periodId
       , aDocumentDate   -- aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
       , aDocumentDate   -- aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
       , aDocumentCurrencyId   -- aACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
       , ACS_FUNCTION.GetLocalCurrencyId   -- aACS_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type,
       , 0   -- aIMF_AMOUNT_LC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type,
       , 0   -- aIMF_AMOUNT_LC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type,
       , 0   -- aIMF_AMOUNT_FC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type,
       , 0   -- aIMF_AMOUNT_FC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type,
       , paymentDescription   --aIMF_DESCRIPTION ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
        );
      -- maj du status des échéances liées au paiement
      ACT_EXPIRY_MANAGEMENT.Update_Doc_Expiry(aNewDocumentId);
      -- màj des infos compl. en fonction de aci_det_payment
      UpdateDocPayInfoImputations(aNewDocumentId, tblLinkDetPayACI_ACT);
    end if;
  end Recover_Det_Payment;

  /**
  * Description
  *    reprise des relances
  */
  procedure Recover_Reminder(
    aPartImputationId    in number
  , aThirdId             in number
  , aNewPartImputationId in number
  , aNewDocumentId       in number
  )
  is
    cursor reminder(cPartImputationId number)
    is
      select *
        from ACI_REMINDER
       where ACI_PART_IMPUTATION_ID = cPartImputationId;

    cursor remindertext(cPartImputationId number)
    is
      select *
        from ACI_REMINDER_TEXT
       where ACI_PART_IMPUTATION_ID = cPartImputationId;

    remindertext_tuple remindertext%rowtype;
    expiryId           ACT_EXPIRY.ACT_EXPIRY_ID%type;
  begin
    for reminder_tuple in reminder(aPartImputationId) loop
      -- recherche de l'échéance liée à la relance
      select exp.ACT_EXPIRY_ID
        into expiryId
        from ACT_EXPIRY exp
           , ACT_PART_IMPUTATION PAR
       where PAR.PAR_DOCUMENT = reminder_tuple.PAR_DOCUMENT
         and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
         and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
         and EXP_SLICE = nvl(reminder_tuple.REM_SEQ_NUMBER, 1)
         and EXP_CALC_NET + 0 = 1;

      -- insertion du la relance
      insert into ACT_REMINDER
                  (ACT_REMINDER_ID
                 , ACT_EXPIRY_ID
                 , ACT_DOCUMENT_ID
                 , ACT_PART_IMPUTATION_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , REM_PAYABLE_AMOUNT_LC
                 , REM_PAYABLE_AMOUNT_FC
                 , REM_PAYABLE_AMOUNT_EUR
                 , REM_COVER_AMOUNT_LC
                 , REM_COVER_AMOUNT_FC
                 ,
--          REM_COVER_AMOUNT_EUR,
                   REM_NUMBER
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , expiryId
                 , aNewDocumentId
                 , aNewPartImputationId
                 , reminder_tuple.ACS_FINANCIAL_CURRENCY_ID
                 , reminder_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                 , nvl(reminder_tuple.REM_PAYABLE_AMOUNT_LC, 0)
                 , nvl(reminder_tuple.REM_PAYABLE_AMOUNT_FC, 0)
                 , nvl(reminder_tuple.REM_PAYABLE_AMOUNT_EUR, 0)
                 , nvl(reminder_tuple.REM_COVER_AMOUNT_LC, 0)
                 , nvl(reminder_tuple.REM_COVER_AMOUNT_FC, 0)
                 ,
--          reminder_tuple.REM_COVER_AMOUNT_EUR,
                   nvl(reminder_tuple.REM_NUMBER, 0)
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      for remindertext_tuple in remindertext(aPartImputationId) loop
        -- insertion des textes de la relance
        insert into ACT_REMINDER_TEXT
                    (ACT_REMINDER_TEXT_ID
                   , ACT_DOCUMENT_ID
                   , ACT_PART_IMPUTATION_ID
                   , C_TEXT_TYPE
                   , REM_TEXT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (init_id_seq.nextval
                   , aNewDocumentId
                   , aNewPartImputationId
                   , remindertext_tuple.C_TEXT_TYPE
                   , remindertext_tuple.REM_TEXT
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end loop;
    end loop;
  end Recover_Reminder;

  procedure update_doc_amounts(
    pmt_document_id       in number
  , new_document_id       in number
  , doc_is_pay            in boolean
  , dc_type               in varchar2
  , period_id             in number
  , date_transaction      in date
  , date_value            in date
  , financial_currency_id in number
  , cat_description       in varchar2
  , tblLinkDetPayACI_ACT  in TtblLinkDetPayACI_ACT
  , payed_amount          in number default null
  , payed_fin_currency_id in number default null
  )
  is
    TotLC             ACT_DET_PAYMENT.DET_PAIED_LC%type;
    TotFC             ACT_DET_PAYMENT.DET_PAIED_FC%type;
    TotEUR            ACT_DET_PAYMENT.DET_PAIED_EUR%type;
    doc_tot_amount_lc ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    tmp_dc_type       varchar2(1);
    signexp           number;
    signdoc           number;
  begin
    -- màj montants
    select nvl(sum(nvl(det_paied_lc, 0) + nvl(det_charges_lc, 0) ), 0)
         , nvl(sum(nvl(det_paied_fc, 0) + nvl(det_charges_fc, 0) ), 0)
         , nvl(sum(nvl(det_paied_eur, 0) + nvl(det_charges_eur, 0) ), 0)
      into TotLC
         , TotFC
         , TotEUR
      from act_det_payment
     where act_document_id = pmt_document_id;

    select nvl(sum(-exp_amount_lc), 0) + TotLC
         , nvl(sum(-exp_amount_fc), 0) + TotFC
         , nvl(sum(-exp_amount_eur), 0) + TotEUR
      into TotLC
         , TotFC
         , TotEUR
      from act_expiry
     where act_document_id = pmt_document_id
       and exp_calc_net = 1;

    -- màj montant imputation partenaire (un seul part_imputation par document)
    update ACT_PART_IMPUTATION
       set PAR_PAIED_LC = TotLC
         , PAR_PAIED_FC = TotFC
     where ACT_DOCUMENT_ID = pmt_document_id;

    if new_document_id is null then
      if sign(TotLC) = 1 then
        if doc_is_pay then
          tmp_dc_type  := 'C';
        else
          tmp_dc_type  := 'D';
        end if;
      else
        if doc_is_pay then
          tmp_dc_type  := 'D';
        else
          tmp_dc_type  := 'C';
        end if;
      end if;

      doc_tot_amount_lc  := 1;
    else
      -- recherche du montant total en monnaie de base
      select imf_amount_lc_c + imf_amount_lc_d
        into doc_tot_amount_lc
        from ACT_FINANCIAL_IMPUTATION
       where ACT_DOCUMENT_ID = new_document_id
         and IMF_PRIMARY = 1;

      tmp_dc_type  := dc_type;

      if payed_fin_currency_id is not null then
        -- on peut avoir le document + écriture prim. dans une monnaie diff. de la monnaie du paiement (Part + écriture sec.)
        if financial_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
          if payed_fin_currency_id != financial_currency_id then
            TotFC := payed_amount;
          end if;
        elsif payed_fin_currency_id != ACS_FUNCTION.GetLocalCurrencyId then
          if payed_fin_currency_id != financial_currency_id then
            TotFC := payed_amount;
          end if;
        else
          TotFC := 0;
        end if;
      end if;

      select decode(sign(nvl(sum(nvl(exp.exp_amount_lc, 0) ), 0)), -1, -1, 1)
        into signexp
        from act_det_payment det
           , act_expiry exp
       where det.act_document_id = pmt_document_id
         and exp.act_expiry_id = det.act_expiry_id;

      -- inversion coté si signe montant paiement <> signe montant facture
      if     tmp_dc_type is not null then
        if signexp <> sign(TotLC) then
          if tmp_dc_type = 'D' then
            tmp_dc_type  := 'C';
          else
            tmp_dc_type  := 'D';
          end if;
        end if;
      end if;
    end if;

    -- màj montant document
    update ACT_DOCUMENT
       set DOC_TOTAL_AMOUNT_DC = decode(ACS_FINANCIAL_CURRENCY_ID
                                      , ACS_FUNCTION.GetLocalCurrencyId, abs(TotLC)
                                      , abs(TotFC)
                                       )
         , DOC_TOTAL_AMOUNT_EUR = TotEUR
     where ACT_DOCUMENT_ID = pmt_document_id;

    if sign(doc_tot_amount_lc) < 0 then
      signdoc := -1;
    else
      signdoc := 1;
    end if;

    -- màj montant imputation primaire (m^me côté que document payé et m^me signe
    update ACT_FINANCIAL_IMPUTATION
       set IMF_AMOUNT_LC_D = decode(tmp_dc_type, 'D', signdoc * abs(TotLC), 0)
         , IMF_AMOUNT_LC_C = decode(tmp_dc_type, 'C', signdoc * abs(TotLC), 0)
         , IMF_AMOUNT_FC_D = decode(tmp_dc_type, 'D', signdoc * abs(TotFC), 0)
         , IMF_AMOUNT_FC_C = decode(tmp_dc_type, 'C', signdoc * abs(TotFC), 0)
         , IMF_AMOUNT_EUR_D = decode(tmp_dc_type, 'D', signdoc * abs(TotEUR), 0)
         , IMF_AMOUNT_EUR_C = decode(tmp_dc_type, 'C', signdoc * abs(TotEUR), 0)
     where ACT_DOCUMENT_ID = pmt_document_id
       and IMF_PRIMARY + 0 = 1;

    -- màj montant imputation primaire (m^me côté que document payé et m^me signe
    update ACT_FINANCIAL_DISTRIBUTION
       set FIN_AMOUNT_LC_D = decode(tmp_dc_type, 'D', signdoc * abs(TotLC), 0)
         , FIN_AMOUNT_LC_C = decode(tmp_dc_type, 'C', signdoc * abs(TotLC), 0)
         , FIN_AMOUNT_FC_D = decode(tmp_dc_type, 'D', signdoc * abs(TotFC), 0)
         , FIN_AMOUNT_FC_C = decode(tmp_dc_type, 'C', signdoc * abs(TotFC), 0)
         , FIN_AMOUNT_EUR_D = decode(tmp_dc_type, 'D', signdoc * abs(TotEUR), 0)
         , FIN_AMOUNT_EUR_C = decode(tmp_dc_type, 'C', signdoc * abs(TotEUR), 0)
     where ACT_FINANCIAL_IMPUTATION_ID = (select min(ACT_FINANCIAL_IMPUTATION_ID)
                                            from ACT_FINANCIAL_IMPUTATION
                                           where ACT_DOCUMENT_ID = pmt_document_id
                                             and IMF_PRIMARY + 0 = 1);

    -- génération des contres écritures du document de paiement
    ACT_PROCESS_PAYMENT.ProcessPayment
      (pmt_document_id
     , period_id
     , date_transaction   -- aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
     , date_value   -- aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
     , financial_currency_id   -- aACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
     , ACS_FUNCTION.GetLocalCurrencyId   -- aACS_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type,
     , 0   -- aIMF_AMOUNT_LC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type,
     , 0   -- aIMF_AMOUNT_LC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type,
     , 0   -- aIMF_AMOUNT_FC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type,
     , 0   -- aIMF_AMOUNT_FC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type,
     , cat_description   --aIMF_DESCRIPTION ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
      );
    -- maj du status des échéances liées au paiement
    ACT_EXPIRY_MANAGEMENT.Update_Doc_Expiry(pmt_document_id);

    if tblLinkDetPayACI_ACT.count > 0 then
      -- màj des infos compl. en fonction de aci_det_payment
      UpdateDocPayInfoImputations(pmt_document_id, tblLinkDetPayACI_ACT);
    end if;

    -- Indique l'état du document
    insert into ACT_DOCUMENT_STATUS
                (ACT_DOCUMENT_STATUS_ID
               , ACT_DOCUMENT_ID
               , DOC_OK
                )
         values (init_id_seq.nextval
               , pmt_document_id
               , 0
                );

    -- Calcul des cumuls du document de paiement
    ACT_DOC_TRANSACTION.DocImputations(pmt_document_id, 0);

  end update_doc_amounts;

  /**
  * Description
  *    reprise des paiements manuels
  */
  procedure Recover_Det_Payment_Manual(
    document_id    in number
  , job_id         in number
  , journal_id     in number
  , an_journal_id  in number
  , type_catalogue in varchar2
  )
  is
    cursor detPayment(documentId number)
    is
      select   det.*
             , part.pac_supplier_partner_id
             , part.pac_custom_partner_id
             , part.acs_financial_currency_id part_acs_fin_curr_id
             , part.acs_acs_financial_currency_id part_acs_acs_fin_curr_id
             , part.PAR_EXCHANGE_RATE
             , part.PAR_BASE_PRICE
          from aci_part_imputation part
             , aci_det_payment det
         where part.ACI_DOCUMENT_ID = documentId
           and det.ACI_PART_IMPUTATION_ID = part.ACI_PART_IMPUTATION_ID
      order by part.ACS_FINANCIAL_CURRENCY_ID asc;

    document_tuple         ACI_DOCUMENT%rowtype;
    expiryId               ACT_EXPIRY.ACT_EXPIRY_ID%type;
    period_id              ACS_PERIOD.ACS_PERIOD_ID%type;
    det_payment_id         ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type                     := null;
    tblLinkDetPayACI_ACT   TtblLinkDetPayACI_ACT                                       := TtblLinkDetPayACI_ACT();
    pmt_document_id        ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    pmt_part_imputation_id ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    financial_account_id   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    catalogue_document_id  ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    cat_description        ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type;
    document_number        ACT_DOCUMENT.DOC_NUMBER%type;
    lastCurrencyId         ACT_PART_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    lastPartImputionId     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    lastIsPayPart          boolean;
    payment_condition_id   PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
    imputation_id          ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    createAdvance          boolean;
    vInfoImputationValues  ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    vInfoImputationManaged ACT_IMP_MANAGEMENT.InfoImputationRecType;
  begin
    if type_catalogue != '3' then
      return;
    end if;

    select *
      into document_tuple
      from ACI_DOCUMENT
     where ACI_DOCUMENT_ID = document_id;

    select max(ACS_PERIOD_ID)
      into period_id
      from ACS_PERIOD
     where document_tuple.DOC_DOCUMENT_DATE between PER_START_DATE and trunc(PER_END_DATE) + 0.99999
       and ACS_FINANCIAL_YEAR_ID = document_tuple.acs_financial_year_id
       and C_STATE_PERIOD = 'ACT'
       and C_TYPE_PERIOD = '2';

    lastCurrencyId      := 0;
    lastPartImputionId  := 0;
    lastIsPayPart       := false;
    document_number     := null;

    for detPayment_tuple in detPayment(document_id) loop
      -- test si création d'un non-lettré
      createAdvance  :=
            detPayment_tuple.ACT_EXPIRY_ID is null
        and detPayment_tuple.PAR_DOCUMENT is null
        and detPayment_tuple.DET_SEQ_NUMBER is null;

      -- un document et part imputation par monnaie
      if    lastCurrencyId != detPayment_tuple.part_acs_fin_curr_id
         or lastPartImputionId != detPayment_tuple.ACI_PART_IMPUTATION_ID then
        -- recherche des info sur le catalogue
        select ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
             , ACJ_CATALOGUE_DOCUMENT.ACS_FINANCIAL_ACCOUNT_ID
             , ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION
          into catalogue_document_id
             , financial_account_id
             , cat_description
          from ACJ_JOB_TYPE_S_CATALOGUE
             , ACJ_CATALOGUE_DOCUMENT
         where ACJ_JOB_TYPE_S_CATALOGUE_ID = document_tuple.ACJ_JOB_TYPE_S_CATALOGUE_ID
           and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

        -- si changement de document -> màj montants de l'ancien
        if lastPartImputionId != 0 then
          update_doc_amounts(pmt_document_id
                           , null
                           , lastIsPayPart
                           , null
                           , period_id
                           , document_tuple.DOC_DOCUMENT_DATE
                           , document_tuple.DOC_DOCUMENT_DATE
                           , lastCurrencyId
                           , cat_description
                           , tblLinkDetPayACI_ACT
                            );
        end if;

        lastCurrencyId      := detPayment_tuple.part_acs_fin_curr_id;
        lastPartImputionId  := detPayment_tuple.ACI_PART_IMPUTATION_ID;
        lastIsPayPart       := detPayment_tuple.pac_supplier_partner_id is not null;

        if     document_number is null
           and document_tuple.DOC_NUMBER is not null then
          document_number  := document_tuple.DOC_NUMBER;
        else
          -- recherche du numéro de document
          ACT_FUNCTIONS.GetDocNumber(catalogue_document_id, document_tuple.acs_financial_year_id, document_number);
        end if;

        -- création du document de paiement
        select init_id_seq.nextval
          into pmt_document_id
          from dual;

        insert into ACT_DOCUMENT
                    (ACT_DOCUMENT_ID
                   , ACT_JOB_ID
                   , ACT_JOURNAL_ID
                   , ACT_ACT_JOURNAL_ID
                   , DOC_NUMBER
                   , DOC_TOTAL_AMOUNT_DC
                   , DOC_TOTAL_AMOUNT_EUR
                   , DOC_CHARGES_LC
                   , DOC_DOCUMENT_DATE
                   , DOC_COMMENT
                   , DOC_CCP_TAX
                   , DOC_ORDER_NO
                   , DOC_EFFECTIVE_DATE
                   , DOC_EXECUTIVE_DATE
                   , DOC_ESTABL_DATE
                   , C_STATUS_DOCUMENT
                   , C_CURR_RATE_COVER_TYPE
                   , DIC_DOC_SOURCE_ID
                   , DIC_DOC_DESTINATION_ID
                   , ACS_FINANCIAL_YEAR_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACJ_CATALOGUE_DOCUMENT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , PC_USER_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (pmt_document_id
                   , job_id
                   , journal_id
                   , an_journal_id
                   , document_number
                   , 0
                   , 0
                   , null   --DOC_CHARGES_LC,
                   , document_tuple.DOC_DOCUMENT_DATE
                   , null   --DOC_COMMENT,
                   , null   --DOC_CCP_TAX,
                   , null   --DOC_ORDER_NO,
                   , null   --DOC_EFFECTIVE_DATE,
                   , null   --DOC_EXECUTIVE_DATE,
                   , null   --DOC_ESTABL_DATE,
                   , nvl(document_tuple.c_status_document, 'DEF')
                   , document_tuple.c_curr_rate_cover_type
                   , null   --dic_doc_source_id,
                   , null   --dic_doc_destination_id,
                   , document_tuple.acs_financial_year_id
                   , detPayment_tuple.part_acs_fin_curr_id
                   , catalogue_document_id
                   , null   --acs_financial_account_id,
                   , PCS.PC_I_LIB_SESSION.GetUserId
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        -- Recherche de la condition de paiement
        if detPayment_tuple.pac_supplier_partner_id is not null then
          select PAC_PAYMENT_CONDITION_ID
            into payment_condition_id
            from PAC_SUPPLIER_PARTNER
           where PAC_SUPPLIER_PARTNER_ID = detPayment_tuple.pac_supplier_partner_id;
        elsif detPayment_tuple.pac_custom_partner_id is not null then
          select PAC_PAYMENT_CONDITION_ID
            into payment_condition_id
            from PAC_CUSTOM_PARTNER
           where PAC_CUSTOM_PARTNER_ID = detPayment_tuple.pac_custom_partner_id;
        end if;

        -- Imputation partenaire du document de paiement
        select init_id_seq.nextval
          into pmt_part_imputation_id
          from dual;

        -- Création d'un tuple pour l'imputation partenaire
        insert into ACT_PART_IMPUTATION
                    (ACT_PART_IMPUTATION_ID
                   , ACT_DOCUMENT_ID
                   , PAR_DOCUMENT
                   , PAR_BLOCKED_DOCUMENT
                   , PAC_CUSTOM_PARTNER_ID
                   , PAC_PAYMENT_CONDITION_ID
                   , PAC_SUPPLIER_PARTNER_ID
                   , DIC_PRIORITY_PAYMENT_ID
                   , DIC_CENTER_PAYMENT_ID
                   , DIC_LEVEL_PRIORITY_ID
                   , PAC_FINANCIAL_REFERENCE_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , PAR_PAIED_LC
                   , PAR_CHARGES_LC
                   , PAR_PAIED_FC
                   , PAR_CHARGES_FC
                   , PAR_EXCHANGE_RATE
                   , PAR_BASE_PRICE
                   , PAC_ADDRESS_ID
                   , PAR_REMIND_DATE
                   , PAR_REMIND_PRINTDATE
                   , PAC_COMMUNICATION_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (pmt_part_imputation_id
                   , pmt_document_id
                   , null   -- PAR_DOCUMENT,
                   , 0   --part_imputation_tuple.PAR_BLOCKED_DOCUMENT,
                   , detPayment_tuple.pac_custom_partner_id
                   , payment_condition_id   --part_imputation_tuple.pac_payment_condition_id,
                   , detPayment_tuple.pac_supplier_partner_id
                   , null   --part_imputation_tuple.DIC_PRIORITY_PAYMENT_ID,
                   , null   --part_imputation_tuple.DIC_CENTER_PAYMENT_ID,
                   , null   --part_imputation_tuple.DIC_LEVEL_PRIORITY_ID,
                   , null   --pac_financial_reference_id,
                   , detPayment_tuple.part_acs_fin_curr_id
                   , detPayment_tuple.part_acs_acs_fin_curr_id
                   , 0
                   , 0   --PAR_CHARGES_LC,
                   , 0
                   , 0   --PAR_CHARGES_FC,
                   , nvl(detPayment_tuple.PAR_EXCHANGE_RATE, 0)   -- cours du document facture compta
                   , nvl(detPayment_tuple.PAR_BASE_PRICE, 0)   -- cours du document facture compta
                   , null   --PAC_ADDRESS_ID,
                   , null   --PAR_REMIND_DATE,
                   , null   --PAR_REMIND_PRINTDATE,
                   , null   --PAC_COMMUNICATION_ID,
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        select max(ACS_PERIOD_ID)
          into period_id
          from ACS_PERIOD
         where document_tuple.DOC_DOCUMENT_DATE between PER_START_DATE and trunc(PER_END_DATE) + 0.99999
           and ACS_FINANCIAL_YEAR_ID = document_tuple.acs_financial_year_id
           and C_STATE_PERIOD = 'ACT'
           and C_TYPE_PERIOD = '2';

        -- Imputation primaire du document de paiement
        imputation_id       :=
          Create_imputation(pmt_document_id
                          , period_id
                          , financial_account_id
                          , null
                          , cat_description
                          , 0
                          , 0
                          , 0
                          , 0
                          , 0
                          , 0
                          , detPayment_tuple.part_acs_fin_curr_id
                          , document_tuple.DOC_DOCUMENT_DATE
                          , document_tuple.DOC_DOCUMENT_DATE
                          , nvl(detPayment_tuple.PAR_EXCHANGE_RATE, 0)
                          , nvl(detPayment_tuple.PAR_BASE_PRICE, 0)
                          , 1
                           );
      end if;

      if not createAdvance then
        if detPayment_tuple.ACT_EXPIRY_ID is null then
          -- recherche de l'échéance liée au lettrage
          select exp.ACT_EXPIRY_ID
            into expiryId
            from ACT_EXPIRY exp
               , ACT_PART_IMPUTATION PAR
           where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
             and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) =
                                   nvl(detPayment_tuple.pac_supplier_partner_id, detPayment_tuple.pac_custom_partner_id)
             and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
             and EXP_SLICE = nvl(detPayment_tuple.DET_SEQ_NUMBER, 1)
             and EXP_CALC_NET + 0 = 1;
        -- and EXP.C_STATUS_EXPIRY = 0;
        else
          expiryId  := detPayment_tuple.ACT_EXPIRY_ID;
        end if;

        select init_id_seq.nextval
          into det_payment_id
          from dual;

        -- insertion du détail paiement
        insert into ACT_DET_PAYMENT
                    (ACT_DET_PAYMENT_ID
                   , ACT_EXPIRY_ID
                   , ACT_DOCUMENT_ID
                   , ACT_PART_IMPUTATION_ID
                   , DET_PAIED_LC
                   , DET_PAIED_FC
                   , DET_PAIED_EUR
                   , DET_CHARGES_LC
                   , DET_CHARGES_FC
                   , DET_CHARGES_EUR
                   , DET_DISCOUNT_LC
                   , DET_DISCOUNT_FC
                   , DET_DISCOUNT_EUR
                   , DET_DEDUCTION_LC
                   , DET_DEDUCTION_FC
                   , DET_DEDUCTION_EUR
                   , DET_LETTRAGE_NO
                   , DET_DIFF_EXCHANGE
                   , DET_TRANSACTION_TYPE
                   , DET_SEQ_NUMBER
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (det_payment_id
                   , expiryId
                   , pmt_document_id
                   , pmt_part_imputation_id
                   , nvl(detPayment_tuple.DET_PAIED_LC, 0)
                   , nvl(detPayment_tuple.DET_PAIED_FC, 0)
                   , nvl(detPayment_tuple.DET_PAIED_EUR, 0)
                   , nvl(detPayment_tuple.DET_CHARGES_LC, 0)
                   , nvl(detPayment_tuple.DET_CHARGES_FC, 0)
                   , nvl(detPayment_tuple.DET_CHARGES_EUR, 0)
                   , nvl(detPayment_tuple.DET_DISCOUNT_LC, 0)
                   , nvl(detPayment_tuple.DET_DISCOUNT_FC, 0)
                   , nvl(detPayment_tuple.DET_DISCOUNT_EUR, 0)
                   , nvl(detPayment_tuple.DET_DEDUCTION_LC, 0)
                   , nvl(detPayment_tuple.DET_DEDUCTION_FC, 0)
                   , nvl(detPayment_tuple.DET_DEDUCTION_EUR, 0)
                   , detPayment_tuple.DET_LETTRAGE_NO
                   , nvl(detPayment_tuple.DET_DIFF_EXCHANGE, 0)
                   , detPayment_tuple.DET_TRANSACTION_TYPE
                   , nvl(detPayment_tuple.DET_SEQ_NUMBER, 1)
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        tblLinkDetPayACI_ACT.extend;
        tblLinkDetPayACI_ACT(tblLinkDetPayACI_ACT.last).ACT_DET_PAYMENT_ID  := det_payment_id;
        tblLinkDetPayACI_ACT(tblLinkDetPayACI_ACT.last).ACI_DET_PAYMENT_ID  := detPayment_tuple.aci_det_payment_id;
      else
        -- recherche des info géreé pour le catalogue
        vInfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);

        if vInfoImputationManaged.managed then
          -- récupération des données compl. des ACI
          ACT_IMP_MANAGEMENT.GetInfoImputationValuesDET_ACI(detPayment_tuple.aci_det_payment_id, vInfoImputationValues);
          -- Màj (null) des champs non gérés
          ACT_IMP_MANAGEMENT.UpdateManagedValues(vInfoImputationValues, vInfoImputationManaged.Secondary);
        else
          vInfoImputationValues  := null;
        end if;

        ACT_PROCESS_PAYMENT.CreateAdvance(pmt_part_imputation_id
                                        , period_id
                                        , detPayment_tuple.DET_PAIED_LC
                                        , detPayment_tuple.DET_PAIED_FC
                                        , document_tuple.DOC_DOCUMENT_DATE
                                        , document_tuple.DOC_DOCUMENT_DATE
                                        , document_tuple.DOC_DOCUMENT_DATE
                                        , cat_description
                                        , vInfoImputationValues
                                         );
      end if;
    end loop;

    -- màj du dernier document
    if pmt_document_id is not null then
      update_doc_amounts(pmt_document_id
                       , null
                       , lastIsPayPart
                       , null
                       , period_id
                       , document_tuple.DOC_DOCUMENT_DATE
                       , document_tuple.DOC_DOCUMENT_DATE
                       , lastCurrencyId
                       , cat_description
                       , tblLinkDetPayACI_ACT
                        );
    end if;
  end Recover_Det_Payment_Manual;

  /**
  * Description
  *    reprise des paiements
  */
  procedure Recover_Det_Payment_Direct(
    document_id     in number
  , job_id          in number
  , journal_id      in number
  , an_journal_id   in number
  , new_document_id in number
  , dc_type         in varchar2
  , type_catalogue  in varchar2
  )
  is
    cursor crExpiry(
      document_id      ACT_DOCUMENT.ACT_DOCUMENT_ID%type
    , document_date in ACI_DOCUMENT.DOC_DOCUMENT_DATE%type
    )
    is
      select   EXP1.ACT_EXPIRY_ID
             , abs(EXP2.EXP_AMOUNT_LC) EXP_AMOUNT_LC
             , abs(EXP2.EXP_AMOUNT_FC) EXP_AMOUNT_FC
             , abs(EXP2.EXP_AMOUNT_EUR) EXP_AMOUNT_EUR
             , abs(EXP1.EXP_AMOUNT_LC) EXP_AMOUNT_LC_MAX
             , abs(EXP1.EXP_AMOUNT_FC) EXP_AMOUNT_FC_MAX
             , abs(EXP1.EXP_AMOUNT_EUR) EXP_AMOUNT_EUR_MAX
             , abs(EXP2.EXP_DISCOUNT_LC) EXP_DISCOUNT_LC
             , abs(EXP2.EXP_DISCOUNT_FC) EXP_DISCOUNT_FC
             , abs(EXP2.EXP_DISCOUNT_EUR) EXP_DISCOUNT_EUR
             , 0.0 EXP_DEDUCTION_LC
             , 0.0 EXP_DEDUCTION_FC
             , 0.0 EXP_DEDUCTION_EUR
             , 0.0 EXP_DIFF_EXCHANGE
             , 0.0 EXP_AMOUNT_PC
--              , 0.0 EXP_DEDUCTION_PC
--              , 0.0 EXP_DISCOUNT_PC
             , sign(EXP1.EXP_AMOUNT_LC) EXP_SIGN
             , 0 ACI_DET_PAYMENT_ID
             , 0 ACT_DET_PAYMENT_ID
             , 0 ACJ_JOB_TYPE_S_CAT_DET_ID
             , null ACS_FINANCIAL_CURRENCY_ID
             , 0 DET_EXCHANGE_RATE
             , 0 DET_BASE_PRICE
          from ACT_EXPIRY EXP2
             , ACT_EXPIRY EXP1
         where EXP1.ACT_DOCUMENT_ID = document_id
           and EXP1.EXP_CALC_NET + 0 = 1
           and EXP2.ACT_EXPIRY_ID = ACT_FUNCTIONS.GetExpiryIdOfDate(EXP1.ACT_DOCUMENT_ID, EXP1.EXP_SLICE, document_date)
      order by EXP1.EXP_SLICE;

    tplExpiry                   crExpiry%rowtype;

    type TtblExpiry is table of crExpiry%rowtype;

    tblExpiry                   TtblExpiry                                                  := TtblExpiry();

    cursor crExpiryDet(document_id ACI_DOCUMENT.ACI_DOCUMENT_ID%type)
    is
      select   EXP1.EXP_AMOUNT_LC
             , EXP1.EXP_AMOUNT_FC
             , EXP1.EXP_AMOUNT_EUR
             , EXP1.EXP_DISCOUNT_LC
             , EXP1.EXP_DISCOUNT_FC
             , EXP1.EXP_DISCOUNT_EUR
             , 0.0 EXP_DEDUCTION_LC
             , 0.0 EXP_DEDUCTION_FC
             , 0.0 EXP_DEDUCTION_EUR
             , 0 ACT_DET_PAYMENT_ID
             , EXP1.ACT_EXPIRY_ID
             , PART.ACS_FINANCIAL_CURRENCY_ID
          from ACT_EXPIRY EXP1
             , ACT_PART_IMPUTATION PART
         where EXP1.ACT_DOCUMENT_ID = document_id
           and PART.ACT_PART_IMPUTATION_ID = EXP1.ACT_PART_IMPUTATION_ID
           and EXP1.EXP_CALC_NET + 0 = 1
      order by EXP1.EXP_ADAPTED
             , EXP1.EXP_SLICE;

    tplExpiryDet                crExpiryDet%rowtype;

    cursor det_payment(document_id number)
    is
      select   nvl(DET.DET_PAIED_LC, 0) DET_PAIED_LC
             , nvl(DET.DET_PAIED_FC, 0) DET_PAIED_FC
             , nvl(DET.DET_CHARGES_LC, 0) DET_CHARGES_LC
             , nvl(DET.DET_CHARGES_FC, 0) DET_CHARGES_FC
             , nvl(DET.DET_DISCOUNT_LC, 0) DET_DISCOUNT_LC
             , nvl(DET.DET_DISCOUNT_FC, 0) DET_DISCOUNT_FC
             , nvl(DET.DET_DEDUCTION_LC, 0) DET_DEDUCTION_LC
             , nvl(DET.DET_DEDUCTION_FC, 0) DET_DEDUCTION_FC
             , nvl(DET.DET_DIFF_EXCHANGE, 0) DET_DIFF_EXCHANGE
             , nvl(DET.DET_PAIED_EUR, 0) DET_PAIED_EUR
             , nvl(DET.DET_CHARGES_EUR, 0) DET_CHARGES_EUR
             , nvl(DET.DET_DISCOUNT_EUR, 0) DET_DISCOUNT_EUR
             , nvl(DET.DET_DEDUCTION_EUR, 0) DET_DEDUCTION_EUR
             , nvl(DET.DET_PAIED_PC, 0) DET_PAIED_PC
             , nvl(DET.DET_CHARGES_PC, 0) DET_CHARGES_PC
             , nvl(DET.DET_DISCOUNT_PC, 0) DET_DISCOUNT_PC
             , nvl(DET.DET_DEDUCTION_PC, 0) DET_DEDUCTION_PC
             , DET.ACI_DET_PAYMENT_ID
             , DET.ACJ_JOB_TYPE_S_CAT_DET_ID
             , PART.ACS_FINANCIAL_CURRENCY_ID
             , PART.ACS_ACS_FINANCIAL_CURRENCY_ID
             , DET.ACS_FINANCIAL_CURRENCY_ID PAIED_ACS_FIN_CURRENCY_ID
             , nvl(DET.DET_EXCHANGE_RATE, 0) DET_EXCHANGE_RATE
             , nvl(DET.DET_BASE_PRICE, 0) DET_BASE_PRICE
             , (select sum(nvl(EXP_AMOUNT_LC, 0) )
                  from ACI_EXPIRY
                 where ACI_PART_IMPUTATION_ID = PART.ACI_PART_IMPUTATION_ID) EXP_AMOUNT_LC
          from ACI_DET_PAYMENT DET
             , ACI_PART_IMPUTATION PART
         where PART.ACI_DOCUMENT_ID = document_id
           and PART.ACI_PART_IMPUTATION_ID = DET.ACI_PART_IMPUTATION_ID
           and DET.ACJ_JOB_TYPE_S_CAT_DET_ID is not null
      order by PCS.PC_BITMAN.BIT_XOR(decode(sign(nvl(DET.DET_PAIED_LC, 0) ), -1, 0, 1), decode(sign(nvl(EXP_AMOUNT_LC, 0) ), -1, 0, 1) ) desc
             , DET.DET_SEQ_NUMBER
             , DET.ACI_DET_PAYMENT_ID;

    det_payment_tuple           det_payment%rowtype;
    part_imputation_tuple       ACI_PART_IMPUTATION%rowtype;
    document_tuple              ACI_DOCUMENT%rowtype;
    primary_imp_tuple           ACI_FINANCIAL_IMPUTATION%rowtype;
    period_id                   ACS_PERIOD.ACS_PERIOD_ID%type;
    financial_account_id        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    division_id                 ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    sub_set_id                  ACS_SUB_SET.ACS_SUB_SET_ID%type;
    divi_sub_set_id             ACS_SUB_SET.ACS_SUB_SET_ID%type;
    catalogue_document_id       ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    payment_condition_id        PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
    total_payment_lc_c          ACT_DET_PAYMENT.DET_PAIED_LC%type;
    total_payment_fc_c          ACT_DET_PAYMENT.DET_PAIED_FC%type;
    total_payment_eur_c         ACT_DET_PAYMENT.DET_PAIED_EUR%type;
    total_payment_lc_d          ACT_DET_PAYMENT.DET_PAIED_LC%type;
    total_payment_fc_d          ACT_DET_PAYMENT.DET_PAIED_FC%type;
    total_payment_eur_d         ACT_DET_PAYMENT.DET_PAIED_EUR%type;
    total_charges_lc            ACT_DET_PAYMENT.DET_CHARGES_LC%type;
    total_charges_fc            ACT_DET_PAYMENT.DET_CHARGES_FC%type;
    total_charges_eur           ACT_DET_PAYMENT.DET_CHARGES_EUR%type;
    payment_amount_lc           ACT_DET_PAYMENT.DET_PAIED_LC%type;
    payment_amount_fc           ACT_DET_PAYMENT.DET_PAIED_FC%type;
    payment_amount_eur          ACT_DET_PAYMENT.DET_PAIED_EUR%type;
    discount_lc                 ACT_DET_PAYMENT.DET_DISCOUNT_LC%type;
    discount_fc                 ACT_DET_PAYMENT.DET_DISCOUNT_FC%type;
    discount_eur                ACT_DET_PAYMENT.DET_DISCOUNT_EUR%type;
    deduction_lc                ACT_DET_PAYMENT.DET_DEDUCTION_LC%type;
    deduction_fc                ACT_DET_PAYMENT.DET_DEDUCTION_FC%type;
    deduction_eur               ACT_DET_PAYMENT.DET_DEDUCTION_EUR%type;
    pmt_document_id             ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    pmt_part_imputation_id      ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    pmt_financial_imputation_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    det_payment_id              ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type;
    cur_det_payment_id          ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type;
    expiry_of_date              ACT_EXPIRY.ACT_EXPIRY_ID%type;
    net_expiry_id               ACT_EXPIRY.ACT_EXPIRY_ID%type;
    slice                       number(2);
    nb_slice                    number(2);
    doc_tot_amount_lc           ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    balance_amount_doc_lc       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    balance_amount_pmt_lc       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    balance_amount_pmt_fc       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    balance_amount_pmt_eur      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    expiry_amount_lc            ACT_EXPIRY.EXP_AMOUNT_LC%type;
    expiry_amount_fc            ACT_EXPIRY.EXP_AMOUNT_FC%type;
    expiry_amount_eur           ACT_EXPIRY.EXP_AMOUNT_EUR%type;
    cat_description             ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type;
    document_number             ACT_DOCUMENT.DOC_NUMBER%type;
    max_ded_lc                  ACT_EXPIRY.EXP_AMOUNT_LC%type;
    max_ded_fc                  ACT_EXPIRY.EXP_AMOUNT_FC%type;
    max_ded_eur                 ACT_EXPIRY.EXP_AMOUNT_EUR%type;
    without_det_payment         boolean;
    tblLinkDetPayACI_ACT        TtblLinkDetPayACI_ACT                                       := TtblLinkDetPayACI_ACT();
    TotPaymentLC                ACT_DET_PAYMENT.DET_PAIED_LC%type;
    TotPaymentFC                ACT_DET_PAYMENT.DET_PAIED_FC%type;
    TotPaymentEUR               ACT_DET_PAYMENT.DET_PAIED_EUR%type;
    imputation_id               ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vCoverId                    ACT_COVER_INFORMATION.ACT_COVER_INFORMATION_ID%type;
  begin
    if type_catalogue not in('2', '5', '6') then
      -- Création des couvertures
      -- Déplacé ici car la création des couvertures dépend
      --  de la présence de paiements directs
      vCoverId  := Recover_Covering(new_document_id);
      return;
    end if;

    select *
      into document_tuple
      from ACI_DOCUMENT
     where ACI_DOCUMENT_ID = document_id;

    without_det_payment  := document_tuple.ACJ_JOB_TYPE_S_CAT_PMT_ID is not null;

    select *
      into part_imputation_tuple
      from ACI_PART_IMPUTATION
     where ACI_DOCUMENT_ID = document_id;

    select *
      into primary_imp_tuple
      from ACI_FINANCIAL_IMPUTATION
     where ACI_DOCUMENT_ID = document_id
       and IMF_PRIMARY = 1;

    period_id            := primary_imp_tuple.ACS_PERIOD_ID;

    if     without_det_payment
       and nvl(document_tuple.doc_paid_amount_lc, 0) = 0
       and nvl(document_tuple.doc_paid_amount_fc, 0) = 0 then
      -- Paiement à 0 -> on ne l'intègre pas
      return;
    end if;

    if without_det_payment then
      -- Pas de det_payment -> Utilisation du montant document
      select ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
           , ACJ_CATALOGUE_DOCUMENT.ACS_FINANCIAL_ACCOUNT_ID
           , ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION
        into catalogue_document_id
           , financial_account_id
           , cat_description
        from ACJ_JOB_TYPE_S_CATALOGUE
           , ACJ_CATALOGUE_DOCUMENT
       where ACJ_JOB_TYPE_S_CATALOGUE_ID = document_tuple.ACJ_JOB_TYPE_S_CAT_PMT_ID
         and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

      -- Création des couvertures
      -- Déplacé ici car la création des couvertures dépand
      --  de la présence de paiements directs
      vCoverId                := Recover_Covering(new_document_id, catalogue_document_id);
      -- recherche du numéro de document
      ACT_FUNCTIONS.GetDocNumber(catalogue_document_id, document_tuple.acs_financial_year_id, document_number);

      -- création du document de paiement
      select init_id_seq.nextval
        into pmt_document_id
        from dual;

      insert into ACT_DOCUMENT
                  (ACT_DOCUMENT_ID
                 , ACT_JOB_ID
                 , ACT_JOURNAL_ID
                 , ACT_ACT_JOURNAL_ID
                 , DOC_NUMBER
                 , DOC_TOTAL_AMOUNT_DC
                 , DOC_TOTAL_AMOUNT_EUR
                 , DOC_CHARGES_LC
                 , DOC_DOCUMENT_DATE
                 , DOC_COMMENT
                 , DOC_CCP_TAX
                 , DOC_ORDER_NO
                 , DOC_EFFECTIVE_DATE
                 , DOC_EXECUTIVE_DATE
                 , DOC_ESTABL_DATE
                 , C_STATUS_DOCUMENT
                 , C_CURR_RATE_COVER_TYPE
                 , DIC_DOC_SOURCE_ID
                 , DIC_DOC_DESTINATION_ID
                 , ACS_FINANCIAL_YEAR_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACJ_CATALOGUE_DOCUMENT_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , PC_USER_ID
                 , A_DATECRE
                 , A_IDCRE
                 , ACT_COVER_INFORMATION_ID
                  )
           values (pmt_document_id
                 , job_id
                 , journal_id
                 , an_journal_id
                 , document_number
                 , nvl(decode(document_tuple.doc_paid_amount_fc
                        , 0, document_tuple.doc_paid_amount_lc
                        , document_tuple.doc_paid_amount_fc
                         ), 0)
                 , nvl(document_tuple.doc_paid_amount_eur, 0)
                 , null   --DOC_CHARGES_LC,
                 , document_tuple.DOC_DOCUMENT_DATE
                 , null   --DOC_COMMENT,
                 , null   --DOC_CCP_TAX,
                 , null   --DOC_ORDER_NO,
                 , null   --DOC_EFFECTIVE_DATE,
                 , null   --DOC_EXECUTIVE_DATE,
                 , null   --DOC_ESTABL_DATE,
                 , nvl(document_tuple.c_status_document, 'DEF')
                 , document_tuple.c_curr_rate_cover_type
                 , null   --dic_doc_source_id,
                 , null   --dic_doc_destination_id,
                 , document_tuple.acs_financial_year_id
                 , document_tuple.acs_financial_currency_id
                 , catalogue_document_id
                 , null   --acs_financial_account_id,
                 , PCS.PC_I_LIB_SESSION.GetUserId
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , vCoverId
                  );

      -- Recherche de la condition de paiement
      if part_imputation_tuple.pac_supplier_partner_id is not null then
        select PAC_PAYMENT_CONDITION_ID
          into payment_condition_id
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = part_imputation_tuple.pac_supplier_partner_id;
      elsif part_imputation_tuple.pac_custom_partner_id is not null then
        select PAC_PAYMENT_CONDITION_ID
          into payment_condition_id
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = part_imputation_tuple.pac_custom_partner_id;
      end if;

      -- Imputation partenaire du document de paiement
      select init_id_seq.nextval
        into pmt_part_imputation_id
        from dual;

      -- Création d'un tuple pour l'imputation partenaire
      insert into ACT_PART_IMPUTATION
                  (ACT_PART_IMPUTATION_ID
                 , ACT_DOCUMENT_ID
                 , PAR_DOCUMENT
                 , PAR_BLOCKED_DOCUMENT
                 , PAC_CUSTOM_PARTNER_ID
                 , PAC_PAYMENT_CONDITION_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , DIC_PRIORITY_PAYMENT_ID
                 , DIC_CENTER_PAYMENT_ID
                 , DIC_LEVEL_PRIORITY_ID
                 , PAC_FINANCIAL_REFERENCE_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , PAR_PAIED_LC
                 , PAR_CHARGES_LC
                 , PAR_PAIED_FC
                 , PAR_CHARGES_FC
                 , PAR_EXCHANGE_RATE
                 , PAR_BASE_PRICE
                 , PAC_ADDRESS_ID
                 , PAR_REMIND_DATE
                 , PAR_REMIND_PRINTDATE
                 , PAC_COMMUNICATION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (pmt_part_imputation_id
                 , pmt_document_id
                 , null   -- PAR_DOCUMENT,
                 , 0   --part_imputation_tuple.PAR_BLOCKED_DOCUMENT,
                 , part_imputation_tuple.pac_custom_partner_id
                 , payment_condition_id   --part_imputation_tuple.pac_payment_condition_id,
                 , part_imputation_tuple.pac_supplier_partner_id
                 , null   --part_imputation_tuple.DIC_PRIORITY_PAYMENT_ID,
                 , null   --part_imputation_tuple.DIC_CENTER_PAYMENT_ID,
                 , null   --part_imputation_tuple.DIC_LEVEL_PRIORITY_ID,
                 , null   --pac_financial_reference_id,
                 , part_imputation_tuple.acs_financial_currency_id
                 , part_imputation_tuple.acs_acs_financial_currency_id
                 , nvl(document_tuple.doc_paid_amount_lc, 0)
                 , 0   --PAR_CHARGES_LC,
                 , nvl(document_tuple.doc_paid_amount_fc, 0)
                 , 0   --PAR_CHARGES_FC,
                 , nvl(primary_imp_tuple.IMF_EXCHANGE_RATE, 0)   -- cours du document facture compta
                 , nvl(primary_imp_tuple.IMF_BASE_PRICE, 0)   -- cours du document facture compta
                 , null   --PAC_ADDRESS_ID,
                 , null   --PAR_REMIND_DATE,
                 , null   --PAR_REMIND_PRINTDATE,
                 , null   --PAC_COMMUNICATION_ID,
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      -- recherche du montant total en monnaie de base
      select imf_amount_lc_c + imf_amount_lc_d
        into doc_tot_amount_lc
        from ACT_FINANCIAL_IMPUTATION
       where ACT_DOCUMENT_ID = new_document_id
         and IMF_PRIMARY = 1;

      balance_amount_pmt_lc   := 0;
      balance_amount_pmt_fc   := 0;
      balance_amount_pmt_eur  := 0;

      -- chargement de la table PL des montants des échéances
      -- les échéances sont TOUJOURS positive m^me pour les NC
      for tplExpiry in crExpiry(new_document_id, document_tuple.DOC_DOCUMENT_DATE) loop
        tblExpiry.extend;
        tblExpiry(tblExpiry.last)  := tplExpiry;
        balance_amount_pmt_lc      := balance_amount_pmt_lc + tplExpiry.EXP_AMOUNT_LC;
        balance_amount_pmt_fc      := balance_amount_pmt_fc + tplExpiry.EXP_AMOUNT_FC;
        balance_amount_pmt_eur     := balance_amount_pmt_eur + tplExpiry.EXP_AMOUNT_EUR;
      end loop;

      balance_amount_pmt_lc   := document_tuple.doc_paid_amount_lc - balance_amount_pmt_lc;
      balance_amount_pmt_fc   := document_tuple.doc_paid_amount_fc - balance_amount_pmt_fc;
      balance_amount_pmt_eur  := document_tuple.doc_paid_amount_eur - balance_amount_pmt_eur;

      -- surpaiement -> diminution des escomptes
      if    (    sign(doc_tot_amount_lc) = 1
             and balance_amount_pmt_lc > 0)
         or (    sign(doc_tot_amount_lc) = -1
             and balance_amount_pmt_lc < 0) then
        for ind in tblExpiry.first .. tblExpiry.last loop
          if     balance_amount_pmt_lc != 0
             and tblExpiry(ind).EXP_DISCOUNT_LC != 0 then
            if abs(balance_amount_pmt_lc) < abs(tblExpiry(ind).EXP_DISCOUNT_LC) then
              tblExpiry(ind).EXP_DISCOUNT_LC   := tblExpiry(ind).EXP_DISCOUNT_LC - balance_amount_pmt_lc;
              tblExpiry(ind).EXP_DISCOUNT_FC   := tblExpiry(ind).EXP_DISCOUNT_FC - balance_amount_pmt_fc;
              tblExpiry(ind).EXP_DISCOUNT_EUR  := tblExpiry(ind).EXP_DISCOUNT_EUR - balance_amount_pmt_eur;
              tblExpiry(ind).EXP_AMOUNT_LC     := tblExpiry(ind).EXP_AMOUNT_LC_MAX - tblExpiry(ind).EXP_DISCOUNT_LC;
              tblExpiry(ind).EXP_AMOUNT_FC     := tblExpiry(ind).EXP_AMOUNT_FC_MAX - tblExpiry(ind).EXP_DISCOUNT_FC;
              tblExpiry(ind).EXP_AMOUNT_EUR    := tblExpiry(ind).EXP_AMOUNT_EUR_MAX - tblExpiry(ind).EXP_DISCOUNT_EUR;
              balance_amount_pmt_lc            := 0;
              balance_amount_pmt_fc            := 0;
              balance_amount_pmt_eur           := 0;
            else
              balance_amount_pmt_lc            := balance_amount_pmt_lc - tblExpiry(ind).EXP_DISCOUNT_LC;
              balance_amount_pmt_fc            := balance_amount_pmt_fc - tblExpiry(ind).EXP_DISCOUNT_FC;
              balance_amount_pmt_eur           := balance_amount_pmt_eur - tblExpiry(ind).EXP_DISCOUNT_EUR;
              tblExpiry(ind).EXP_DISCOUNT_LC   := 0;
              tblExpiry(ind).EXP_DISCOUNT_FC   := 0;
              tblExpiry(ind).EXP_DISCOUNT_EUR  := 0;
              tblExpiry(ind).EXP_AMOUNT_LC     := tblExpiry(ind).EXP_AMOUNT_LC_MAX;
              tblExpiry(ind).EXP_AMOUNT_FC     := tblExpiry(ind).EXP_AMOUNT_FC_MAX;
              tblExpiry(ind).EXP_AMOUNT_EUR    := tblExpiry(ind).EXP_AMOUNT_EUR_MAX;
            end if;
          end if;
        end loop;

        -- toujours surpaiement -> passage en déduction négative dans les limites tolérées
        if    (    sign(doc_tot_amount_lc) = 1
               and balance_amount_pmt_lc > 0)
           or (    sign(doc_tot_amount_lc) = -1
               and balance_amount_pmt_lc < 0) then
          for ind in tblExpiry.first .. tblExpiry.last loop
            max_ded_lc   :=
              ACT_CREATION_SBVR.MaxDeductionPossible(part_imputation_tuple.pac_custom_partner_id
                                                   , part_imputation_tuple.pac_supplier_partner_id
                                                   , tblExpiry(ind).EXP_AMOUNT_LC_MAX
                                                    );
            max_ded_fc   :=
              ACT_CREATION_SBVR.MaxDeductionPossible(part_imputation_tuple.pac_custom_partner_id
                                                   , part_imputation_tuple.pac_supplier_partner_id
                                                   , tblExpiry(ind).EXP_AMOUNT_FC_MAX
                                                    );
            max_ded_eur  :=
              ACT_CREATION_SBVR.MaxDeductionPossible(part_imputation_tuple.pac_custom_partner_id
                                                   , part_imputation_tuple.pac_supplier_partner_id
                                                   , tblExpiry(ind).EXP_AMOUNT_EUR_MAX
                                                    );

            if     balance_amount_pmt_lc != 0
               and max_ded_lc != 0 then
              if abs(balance_amount_pmt_lc) < abs(max_ded_lc) then
                tblExpiry(ind).EXP_DEDUCTION_LC   := -balance_amount_pmt_lc;
                tblExpiry(ind).EXP_DEDUCTION_FC   := -balance_amount_pmt_fc;
                tblExpiry(ind).EXP_DEDUCTION_EUR  := -balance_amount_pmt_eur;
                tblExpiry(ind).EXP_AMOUNT_LC      := tblExpiry(ind).EXP_AMOUNT_LC - tblExpiry(ind).EXP_DEDUCTION_LC;
                tblExpiry(ind).EXP_AMOUNT_FC      := tblExpiry(ind).EXP_AMOUNT_FC - tblExpiry(ind).EXP_DEDUCTION_FC;
                tblExpiry(ind).EXP_AMOUNT_EUR     := tblExpiry(ind).EXP_AMOUNT_EUR - tblExpiry(ind).EXP_DEDUCTION_EUR;
                balance_amount_pmt_lc             := 0;
                balance_amount_pmt_fc             := 0;
                balance_amount_pmt_eur            := 0;
              else
                balance_amount_pmt_lc             := balance_amount_pmt_lc - max_ded_lc;
                balance_amount_pmt_fc             := balance_amount_pmt_fc - max_ded_fc;
                balance_amount_pmt_eur            := balance_amount_pmt_eur - max_ded_eur;
                tblExpiry(ind).EXP_DEDUCTION_LC   := -max_ded_lc;
                tblExpiry(ind).EXP_DEDUCTION_FC   := -max_ded_fc;
                tblExpiry(ind).EXP_DEDUCTION_EUR  := -max_ded_eur;
                tblExpiry(ind).EXP_AMOUNT_LC      := tblExpiry(ind).EXP_AMOUNT_LC + max_ded_lc;
                tblExpiry(ind).EXP_AMOUNT_FC      := tblExpiry(ind).EXP_AMOUNT_FC + max_ded_fc;
                tblExpiry(ind).EXP_AMOUNT_EUR     := tblExpiry(ind).EXP_AMOUNT_EUR + max_ded_eur;
              end if;
            end if;
          end loop;
        end if;
      -- souspaiement -> passage en déduction dans les limites tolérées
      elsif    (    sign(doc_tot_amount_lc) = 1
                and balance_amount_pmt_lc < 0)
            or (    sign(doc_tot_amount_lc) = -1
                and balance_amount_pmt_lc > 0) then
        for ind in tblExpiry.first .. tblExpiry.last loop
          max_ded_lc   :=
            ACT_CREATION_SBVR.MaxDeductionPossible(part_imputation_tuple.pac_custom_partner_id
                                                 , part_imputation_tuple.pac_supplier_partner_id
                                                 , tblExpiry(ind).EXP_AMOUNT_LC_MAX
                                                  );
          max_ded_fc   :=
            ACT_CREATION_SBVR.MaxDeductionPossible(part_imputation_tuple.pac_custom_partner_id
                                                 , part_imputation_tuple.pac_supplier_partner_id
                                                 , tblExpiry(ind).EXP_AMOUNT_FC_MAX
                                                  );
          max_ded_eur  :=
            ACT_CREATION_SBVR.MaxDeductionPossible(part_imputation_tuple.pac_custom_partner_id
                                                 , part_imputation_tuple.pac_supplier_partner_id
                                                 , tblExpiry(ind).EXP_AMOUNT_EUR_MAX
                                                  );

          if     balance_amount_pmt_lc != 0
             and max_ded_lc != 0 then
            if abs(balance_amount_pmt_lc) < abs(max_ded_lc) then
              tblExpiry(ind).EXP_DEDUCTION_LC   := -balance_amount_pmt_lc;
              tblExpiry(ind).EXP_DEDUCTION_FC   := -balance_amount_pmt_fc;
              tblExpiry(ind).EXP_DEDUCTION_EUR  := -balance_amount_pmt_eur;
              tblExpiry(ind).EXP_AMOUNT_LC      := tblExpiry(ind).EXP_AMOUNT_LC - tblExpiry(ind).EXP_DEDUCTION_LC;
              tblExpiry(ind).EXP_AMOUNT_FC      := tblExpiry(ind).EXP_AMOUNT_FC - tblExpiry(ind).EXP_DEDUCTION_FC;
              tblExpiry(ind).EXP_AMOUNT_EUR     := tblExpiry(ind).EXP_AMOUNT_EUR - tblExpiry(ind).EXP_DEDUCTION_EUR;
              balance_amount_pmt_lc             := 0;
              balance_amount_pmt_fc             := 0;
              balance_amount_pmt_eur            := 0;
            else
              balance_amount_pmt_lc             := balance_amount_pmt_lc + max_ded_lc;
              balance_amount_pmt_fc             := balance_amount_pmt_fc + max_ded_fc;
              balance_amount_pmt_eur            := balance_amount_pmt_eur + max_ded_eur;
              tblExpiry(ind).EXP_DEDUCTION_LC   := max_ded_lc;
              tblExpiry(ind).EXP_DEDUCTION_FC   := max_ded_fc;
              tblExpiry(ind).EXP_DEDUCTION_EUR  := max_ded_eur;
              tblExpiry(ind).EXP_AMOUNT_LC      := tblExpiry(ind).EXP_AMOUNT_LC - tblExpiry(ind).EXP_DEDUCTION_LC;
              tblExpiry(ind).EXP_AMOUNT_FC      := tblExpiry(ind).EXP_AMOUNT_FC - tblExpiry(ind).EXP_DEDUCTION_FC;
              tblExpiry(ind).EXP_AMOUNT_EUR     := tblExpiry(ind).EXP_AMOUNT_EUR - tblExpiry(ind).EXP_DEDUCTION_EUR;
            end if;
          end if;
        end loop;
      end if;

      -- toujours souspaiement -> les échéances ne peuvent pas etre compensées.
      -- répartition simple du paiement (paiement partiel)
      if    (    sign(doc_tot_amount_lc) = 1
             and balance_amount_pmt_lc < 0)
         or (    sign(doc_tot_amount_lc) = -1
             and balance_amount_pmt_lc > 0) then
        tblExpiry.delete;
        balance_amount_pmt_lc   := document_tuple.doc_paid_amount_lc;
        balance_amount_pmt_fc   := document_tuple.doc_paid_amount_fc;
        balance_amount_pmt_eur  := document_tuple.doc_paid_amount_eur;

        for tplExpiry in crExpiry(new_document_id, document_tuple.DOC_DOCUMENT_DATE) loop
          if balance_amount_pmt_lc > 0 then
            tblExpiry.extend;
            tblExpiry(tblExpiry.last)  := tplExpiry;
            balance_amount_pmt_lc      := balance_amount_pmt_lc - tplExpiry.EXP_AMOUNT_LC;
            balance_amount_pmt_fc      := balance_amount_pmt_fc - tplExpiry.EXP_AMOUNT_FC;
            balance_amount_pmt_eur     := balance_amount_pmt_eur - tplExpiry.EXP_AMOUNT_EUR;

            if balance_amount_pmt_lc < 0 then
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_LC   := 0;
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_FC   := 0;
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_EUR  := 0;
              tblExpiry(tblExpiry.last).EXP_AMOUNT_LC     := tplExpiry.EXP_AMOUNT_LC + balance_amount_pmt_lc;
              tblExpiry(tblExpiry.last).EXP_AMOUNT_FC     := tplExpiry.EXP_AMOUNT_FC + balance_amount_pmt_fc;
              tblExpiry(tblExpiry.last).EXP_AMOUNT_EUR    := tplExpiry.EXP_AMOUNT_EUR + balance_amount_pmt_eur;
            end if;
          end if;
        end loop;
      end if;

      if tblExpiry.count > 0 then
        for ind in tblExpiry.first .. tblExpiry.last loop
          net_expiry_id       := tblExpiry(ind).ACT_EXPIRY_ID;
          -- on change le signe en fonction des échéances (NC)
          payment_amount_lc   := tblExpiry(ind).EXP_SIGN * tblExpiry(ind).EXP_AMOUNT_LC;
          payment_amount_fc   := tblExpiry(ind).EXP_SIGN * tblExpiry(ind).EXP_AMOUNT_FC;
          payment_amount_eur  := tblExpiry(ind).EXP_SIGN * tblExpiry(ind).EXP_AMOUNT_EUR;
          discount_lc         := tblExpiry(ind).EXP_SIGN * tblExpiry(ind).EXP_DISCOUNT_LC;
          discount_fc         := tblExpiry(ind).EXP_SIGN * tblExpiry(ind).EXP_DISCOUNT_FC;
          discount_eur        := tblExpiry(ind).EXP_SIGN * tblExpiry(ind).EXP_DISCOUNT_EUR;
          deduction_lc        := tblExpiry(ind).EXP_SIGN * tblExpiry(ind).EXP_DEDUCTION_LC;
          deduction_fc        := tblExpiry(ind).EXP_SIGN * tblExpiry(ind).EXP_DEDUCTION_FC;
          deduction_eur       := tblExpiry(ind).EXP_SIGN * tblExpiry(ind).EXP_DEDUCTION_EUR;

          -- id du paiement
          select init_id_seq.nextval
            into det_payment_id
            from dual;

          insert into act_det_payment
                      (ACT_DET_PAYMENT_ID
                     , ACT_EXPIRY_ID
                     , ACT_DOCUMENT_ID
                     , ACT_PART_IMPUTATION_ID
                     , DET_PAIED_LC
                     , DET_PAIED_FC
                     , DET_PAIED_EUR
                     , DET_CHARGES_LC
                     , DET_CHARGES_FC
                     , DET_CHARGES_EUR
                     , DET_DISCOUNT_LC
                     , DET_DISCOUNT_FC
                     , DET_DISCOUNT_EUR
                     , DET_DEDUCTION_LC
                     , DET_DEDUCTION_FC
                     , DET_DEDUCTION_EUR
                     , DET_LETTRAGE_NO
                     , DET_DIFF_EXCHANGE
                     , DET_TRANSACTION_TYPE
                     , DET_SEQ_NUMBER
                     , DET_FILE_AMOUNT
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (det_payment_id
                     , net_expiry_id
                     , pmt_document_id
                     , pmt_part_imputation_id
                     , nvl(payment_amount_lc, 0)
                     , nvl(payment_amount_fc, 0)
                     , nvl(payment_amount_eur, 0)
                     , 0   --document_tuple.DET_CHARGES_LC,
                     , 0   --document_tuple.DET_CHARGES_FC,
                     , 0   --document_tuple.DET_CHARGES_EUR,
                     , nvl(discount_lc, 0)
                     , nvl(discount_fc, 0)
                     , nvl(discount_eur, 0)
                     , nvl(deduction_lc, 0)
                     , nvl(deduction_fc, 0)
                     , nvl(deduction_eur, 0)
                     , null   --document_tuple.DET_LETTRAGE_NO,
                     , 0   --document_tuple.DET_DIFF_EXCHANGE,
                     , null   --document_tuple.DET_TRANSACTION_TYPE,
                     , null   --document_tuple.DET_SEQ_NUMBER,
                     , null   -- file_amount
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end loop;
      end if;

      -- attribution des montants de l'écriture primaire
      select decode(dc_type, 'C', sign(doc_tot_amount_lc) * document_tuple.doc_paid_amount_lc, 0)
           , decode(dc_type, 'D', sign(doc_tot_amount_lc) * document_tuple.doc_paid_amount_lc, 0)
           , decode(dc_type, 'C', sign(doc_tot_amount_lc) * document_tuple.doc_paid_amount_fc, 0)
           , decode(dc_type, 'D', sign(doc_tot_amount_lc) * document_tuple.doc_paid_amount_fc, 0)
           , decode(dc_type, 'C', sign(doc_tot_amount_lc) * nvl(document_tuple.doc_paid_amount_eur, 0), 0)
           , decode(dc_type, 'D', sign(doc_tot_amount_lc) * nvl(document_tuple.doc_paid_amount_eur, 0), 0)
        into total_payment_lc_c
           , total_payment_lc_d
           , total_payment_fc_c
           , total_payment_fc_d
           , total_payment_eur_c
           , total_payment_eur_d
        from dual;

      -- Imputation primaire du document de paiement
      imputation_id           :=
        Create_imputation(pmt_document_id
                        , period_id
                        , financial_account_id
                        , primary_imp_tuple.acs_division_account_id
                        , cat_description
                        , total_payment_lc_d
                        , total_payment_lc_c
                        , total_payment_fc_d
                        , total_payment_fc_c
                        , total_payment_eur_d
                        , total_payment_eur_c
                        , document_tuple.acs_financial_currency_id
                        , primary_imp_tuple.IMF_VALUE_DATE
                        , primary_imp_tuple.IMF_TRANSACTION_DATE
                        , primary_imp_tuple.IMF_EXCHANGE_RATE
                        , primary_imp_tuple.IMF_BASE_PRICE
                        , 1
                         );
      -- génération des contres écritures du document de paiement
      ACT_PROCESS_PAYMENT.ProcessPayment
        (pmt_document_id
       , period_id
       , primary_imp_tuple.IMF_TRANSACTION_DATE   -- aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
       , primary_imp_tuple.IMF_VALUE_DATE   -- aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type,
       , document_tuple.acs_financial_currency_id   -- aACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
       , ACS_FUNCTION.GetLocalCurrencyId   -- aACS_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type,
       , total_payment_lc_d   -- aIMF_AMOUNT_LC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type,
       , total_payment_lc_c   -- aIMF_AMOUNT_LC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type,
       , total_payment_fc_d   -- aIMF_AMOUNT_FC_D ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type,
       , total_payment_fc_c   -- aIMF_AMOUNT_FC_C ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type,
       , cat_description   --aIMF_DESCRIPTION ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
        );
      -- maj du status des échéances liées au paiement
      ACT_EXPIRY_MANAGEMENT.Update_Doc_Expiry(pmt_document_id);

      -- Indique l'état du document
      insert into ACT_DOCUMENT_STATUS
                  (ACT_DOCUMENT_STATUS_ID
                 , ACT_DOCUMENT_ID
                 , DOC_OK
                  )
           values (init_id_seq.nextval
                 , pmt_document_id
                 , 0
                  );

      -- Calcul des cumuls du document de paiement
      ACT_DOC_TRANSACTION.DocImputations(pmt_document_id, 0);
    else
      -- Utilisation des det_payment
      open det_payment(document_id);

      fetch det_payment
       into det_payment_tuple;

      open crExpiryDet(new_document_id);

      fetch crExpiryDet
       into tplExpiryDet;

      -- Si on n'a pas de montant dans le paiement celui-ci n'est pas intégré.
      if    det_payment_tuple.DET_PAIED_LC != 0
         or det_payment_tuple.DET_DISCOUNT_LC != 0
         or det_payment_tuple.DET_DEDUCTION_LC != 0 then
        while det_payment%found
         and crExpiryDet%found loop
          TotPaymentLC   :=
            det_payment_tuple.DET_PAIED_LC +
            det_payment_tuple.DET_DISCOUNT_LC +
            det_payment_tuple.DET_DEDUCTION_LC +
            det_payment_tuple.DET_DIFF_EXCHANGE;
          TotPaymentFC   :=
                 det_payment_tuple.DET_PAIED_FC + det_payment_tuple.DET_DISCOUNT_FC + det_payment_tuple.DET_DEDUCTION_FC;
          TotPaymentEUR  :=
              det_payment_tuple.DET_PAIED_EUR + det_payment_tuple.DET_DISCOUNT_EUR + det_payment_tuple.DET_DEDUCTION_EUR;
--           TotPaymentPC   :=
--                  det_payment_tuple.DET_PAIED_PC + det_payment_tuple.DET_DISCOUNT_PC + det_payment_tuple.DET_DEDUCTION_PC;

          -- id du paiement
          select init_id_seq.nextval
            into det_payment_id
            from dual;

          if Sign(TotPaymentLC) != Sign(tplExpiryDet.EXP_AMOUNT_LC) or
              Abs(TotPaymentLC) <= Abs(tplExpiryDet.EXP_AMOUNT_LC) then
            tblExpiry.extend;
            tblExpiry(tblExpiry.last).ACT_EXPIRY_ID                             := tplExpiryDet.ACT_EXPIRY_ID;
            tblExpiry(tblExpiry.last).ACT_DET_PAYMENT_ID                        := det_payment_id;
            tblExpiry(tblExpiry.last).ACI_DET_PAYMENT_ID                        := det_payment_tuple.ACI_DET_PAYMENT_ID;
            tblExpiry(tblExpiry.last).ACJ_JOB_TYPE_S_CAT_DET_ID                 :=
                                                                            det_payment_tuple.ACJ_JOB_TYPE_S_CAT_DET_ID;
            tblExpiry(tblExpiry.last).ACS_FINANCIAL_CURRENCY_ID                 :=
                                                                            det_payment_tuple.PAIED_ACS_FIN_CURRENCY_ID;

            if tblExpiry(tblExpiry.last).ACS_FINANCIAL_CURRENCY_ID != ACS_FUNCTION.GetLocalCurrencyId then
              if     nvl(det_payment_tuple.DET_EXCHANGE_RATE, 0) <> 0
                 and nvl(det_payment_tuple.DET_BASE_PRICE, 0) <> 0 then
                tblExpiry(tblExpiry.last).DET_EXCHANGE_RATE  := det_payment_tuple.DET_EXCHANGE_RATE;
                tblExpiry(tblExpiry.last).DET_BASE_PRICE     := det_payment_tuple.DET_BASE_PRICE;
              else
                tblExpiry(tblExpiry.last).DET_EXCHANGE_RATE  := primary_imp_tuple.IMF_EXCHANGE_RATE;
                tblExpiry(tblExpiry.last).DET_BASE_PRICE     := primary_imp_tuple.IMF_BASE_PRICE;
              end if;
            else
              tblExpiry(tblExpiry.last).DET_EXCHANGE_RATE  := 0;
              tblExpiry(tblExpiry.last).DET_BASE_PRICE     := 0;
            end if;

            tblExpiry(tblExpiry.last).EXP_AMOUNT_LC                             := det_payment_tuple.DET_PAIED_LC;
            tblExpiry(tblExpiry.last).EXP_AMOUNT_FC                             := det_payment_tuple.DET_PAIED_FC;
            tblExpiry(tblExpiry.last).EXP_AMOUNT_EUR                            := det_payment_tuple.DET_PAIED_EUR;
            tblExpiry(tblExpiry.last).EXP_AMOUNT_PC                             := det_payment_tuple.DET_PAIED_PC;
            tblExpiry(tblExpiry.last).EXP_DISCOUNT_LC                           := det_payment_tuple.DET_DISCOUNT_LC;
            tblExpiry(tblExpiry.last).EXP_DISCOUNT_FC                           := det_payment_tuple.DET_DISCOUNT_FC;
            tblExpiry(tblExpiry.last).EXP_DISCOUNT_EUR                          := det_payment_tuple.DET_DISCOUNT_EUR;
--            tblExpiry(tblExpiry.last).EXP_DISCOUNT_PC                           := det_payment_tuple.DET_DISCOUNT_PC;
            tblExpiry(tblExpiry.last).EXP_DEDUCTION_LC                          := det_payment_tuple.DET_DEDUCTION_LC;
            tblExpiry(tblExpiry.last).EXP_DEDUCTION_FC                          := det_payment_tuple.DET_DEDUCTION_FC;
            tblExpiry(tblExpiry.last).EXP_DEDUCTION_EUR                         := det_payment_tuple.DET_DEDUCTION_EUR;
--            tblExpiry(tblExpiry.last).EXP_DEDUCTION_PC                          := det_payment_tuple.DET_DEDUCTION_PC;
            tblExpiry(tblExpiry.last).EXP_DIFF_EXCHANGE                         := det_payment_tuple.DET_DIFF_EXCHANGE;
            -- montant restant à payer sur l'échéance
            tplExpiryDet.EXP_AMOUNT_LC                                          :=
              tplExpiryDet.EXP_AMOUNT_LC -
              tblExpiry(tblExpiry.last).EXP_AMOUNT_LC -
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_LC -
              tblExpiry(tblExpiry.last).EXP_DEDUCTION_LC -
              tblExpiry(tblExpiry.last).EXP_DIFF_EXCHANGE;
            tplExpiryDet.EXP_AMOUNT_FC   :=
              tplExpiryDet.EXP_AMOUNT_FC -
              tblExpiry(tblExpiry.last).EXP_AMOUNT_FC -
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_FC -
              tblExpiry(tblExpiry.last).EXP_DEDUCTION_FC;
            tplExpiryDet.EXP_AMOUNT_EUR  :=
              tplExpiryDet.EXP_AMOUNT_EUR -
              tblExpiry(tblExpiry.last).EXP_AMOUNT_EUR -
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_EUR -
              tblExpiry(tblExpiry.last).EXP_DEDUCTION_EUR;

            tblLinkDetPayACI_ACT.extend;
            tblLinkDetPayACI_ACT(tblLinkDetPayACI_ACT.last).ACI_DET_PAYMENT_ID  := det_payment_tuple.aci_det_payment_id;
            tblLinkDetPayACI_ACT(tblLinkDetPayACI_ACT.last).ACT_DET_PAYMENT_ID  :=
                                                                            tblExpiry(tblExpiry.last).act_det_payment_id;

            fetch det_payment
             into det_payment_tuple;
          else
            tblExpiry.extend;
            tblExpiry(tblExpiry.last).ACT_EXPIRY_ID                             := tplExpiryDet.ACT_EXPIRY_ID;
            tblExpiry(tblExpiry.last).ACT_DET_PAYMENT_ID                        := det_payment_id;
            tblExpiry(tblExpiry.last).ACI_DET_PAYMENT_ID                        := det_payment_tuple.ACI_DET_PAYMENT_ID;
            tblExpiry(tblExpiry.last).ACJ_JOB_TYPE_S_CAT_DET_ID                 :=
                                                                            det_payment_tuple.ACJ_JOB_TYPE_S_CAT_DET_ID;

            tblExpiry(tblExpiry.last).ACS_FINANCIAL_CURRENCY_ID                 :=
                                                                            det_payment_tuple.PAIED_ACS_FIN_CURRENCY_ID;

            if tblExpiry(tblExpiry.last).ACS_FINANCIAL_CURRENCY_ID != ACS_FUNCTION.GetLocalCurrencyId then
              if     nvl(det_payment_tuple.DET_EXCHANGE_RATE, 0) <> 0
                 and nvl(det_payment_tuple.DET_BASE_PRICE, 0) <> 0 then
                tblExpiry(tblExpiry.last).DET_EXCHANGE_RATE  := det_payment_tuple.DET_EXCHANGE_RATE;
                tblExpiry(tblExpiry.last).DET_BASE_PRICE     := det_payment_tuple.DET_BASE_PRICE;
              else
                tblExpiry(tblExpiry.last).DET_EXCHANGE_RATE  := primary_imp_tuple.IMF_EXCHANGE_RATE;
                tblExpiry(tblExpiry.last).DET_BASE_PRICE     := primary_imp_tuple.IMF_BASE_PRICE;
              end if;
            else
              tblExpiry(tblExpiry.last).DET_EXCHANGE_RATE  := 0;
              tblExpiry(tblExpiry.last).DET_BASE_PRICE     := 0;
            end if;

            tblExpiry(tblExpiry.last).EXP_AMOUNT_LC                             :=
              ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_PAIED_LC / TotPaymentLC * tplExpiryDet.EXP_AMOUNT_LC
                                     , det_payment_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                      );
            tblExpiry(tblExpiry.last).EXP_DISCOUNT_LC                           :=
              ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_DISCOUNT_LC / TotPaymentLC * tplExpiryDet.EXP_AMOUNT_LC
                                     , det_payment_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                      );
            tblExpiry(tblExpiry.last).EXP_DEDUCTION_LC                          :=
              ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_DEDUCTION_LC / TotPaymentLC * tplExpiryDet.EXP_AMOUNT_LC
                                     , det_payment_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                      );
            tblExpiry(tblExpiry.last).EXP_DIFF_EXCHANGE                         :=
              ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_DIFF_EXCHANGE / TotPaymentLC * tplExpiryDet.EXP_AMOUNT_LC
                                     , det_payment_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                                      );

            -- recalcule des montants en ME
            if TotPaymentFC <> 0 then
              tblExpiry(tblExpiry.last).EXP_AMOUNT_FC     :=
                ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_PAIED_FC / TotPaymentFC * tplExpiryDet.EXP_AMOUNT_FC
                                       , det_payment_tuple.ACS_FINANCIAL_CURRENCY_ID
                                        );
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_FC   :=
                ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_DISCOUNT_FC / TotPaymentFC * tplExpiryDet.EXP_AMOUNT_FC
                                       , det_payment_tuple.ACS_FINANCIAL_CURRENCY_ID
                                        );
              tblExpiry(tblExpiry.last).EXP_DEDUCTION_FC  :=
                ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_DEDUCTION_FC / TotPaymentFC
                                         * tplExpiryDet.EXP_AMOUNT_FC
                                       , det_payment_tuple.ACS_FINANCIAL_CURRENCY_ID
                                        );
            else
              tblExpiry(tblExpiry.last).EXP_AMOUNT_FC     := 0;
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_FC   := 0;
              tblExpiry(tblExpiry.last).EXP_DEDUCTION_FC  := 0;
            end if;

            -- recalcule des montants en EUR
            if TotPaymentEUR <> 0 then
              tblExpiry(tblExpiry.last).EXP_AMOUNT_EUR     :=
                ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_PAIED_EUR / TotPaymentEUR * tplExpiryDet.EXP_AMOUNT_EUR
                                       , ACS_FUNCTION.GetEuroCurrency
                                        );
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_EUR   :=
                ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_DISCOUNT_EUR /
                                         TotPaymentEUR *
                                         tplExpiryDet.EXP_AMOUNT_EUR
                                       , ACS_FUNCTION.GetEuroCurrency
                                        );
              tblExpiry(tblExpiry.last).EXP_DEDUCTION_EUR  :=
                ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_DEDUCTION_EUR /
                                         TotPaymentEUR *
                                         tplExpiryDet.EXP_AMOUNT_EUR
                                       , ACS_FUNCTION.GetEuroCurrency
                                        );
            else
              tblExpiry(tblExpiry.last).EXP_AMOUNT_EUR     := 0;
              tblExpiry(tblExpiry.last).EXP_DISCOUNT_EUR   := 0;
              tblExpiry(tblExpiry.last).EXP_DEDUCTION_EUR  := 0;
            end if;

--
--             -- recalcule des montants de paiements si nécessaire
--             if tblExpiry(tblExpiry.last).ACS_FINANCIAL_CURRENCY_ID != part_imputation_tuple.acs_financial_currency_id then
--               tblExpiry(tblExpiry.last).EXP_AMOUNT_PC     :=
--                 ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_PAIED_PC / TotPaymentLC * tplExpiryDet.EXP_AMOUNT_LC
--                                        , tblExpiry(tblExpiry.last).ACS_FINANCIAL_CURRENCY_ID
--                                         );
--               tblExpiry(tblExpiry.last).EXP_DISCOUNT_PC   :=
--                 ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_DISCOUNT_FC / TotPaymentLC * tplExpiryDet.EXP_AMOUNT_LC
--                                        , tblExpiry(tblExpiry.last).ACS_FINANCIAL_CURRENCY_ID
--                                         );
--               tblExpiry(tblExpiry.last).EXP_DEDUCTION_PC  :=
--                 ACS_FUNCTION.RoundAmount(det_payment_tuple.DET_DEDUCTION_LC / TotPaymentLC
--                                          * tplExpiryDet.EXP_AMOUNT_FC
--                                        , tblExpiry(tblExpiry.last).ACS_FINANCIAL_CURRENCY_ID
--                                         );
--             else
--               tblExpiry(tblExpiry.last).EXP_AMOUNT_PC     := 0;
--               tblExpiry(tblExpiry.last).EXP_DISCOUNT_PC   := 0;
--               tblExpiry(tblExpiry.last).EXP_DEDUCTION_PC  := 0;
--             end if;

            -- Seul le montant total nous interresse pour màj document et imp. prim.
            tblExpiry(tblExpiry.last).EXP_AMOUNT_PC  := det_payment_tuple.DET_PAIED_PC;

            -- correction des erreur d'arrondi pour lettrage complet de l'échéance
            tblExpiry(tblExpiry.last).EXP_AMOUNT_LC                             :=
              tblExpiry(tblExpiry.last).EXP_AMOUNT_LC +
              (tplExpiryDet.EXP_AMOUNT_LC -
               tblExpiry(tblExpiry.last).EXP_AMOUNT_LC -
               tblExpiry(tblExpiry.last).EXP_DISCOUNT_LC -
               tblExpiry(tblExpiry.last).EXP_DEDUCTION_LC -
               tblExpiry(tblExpiry.last).EXP_DIFF_EXCHANGE
              );
            tblExpiry(tblExpiry.last).EXP_AMOUNT_FC   :=
              tblExpiry(tblExpiry.last).EXP_AMOUNT_FC +
              (tplExpiryDet.EXP_AMOUNT_FC -
               tblExpiry(tblExpiry.last).EXP_AMOUNT_FC -
               tblExpiry(tblExpiry.last).EXP_DISCOUNT_FC -
               tblExpiry(tblExpiry.last).EXP_DEDUCTION_FC
              );
            tblExpiry(tblExpiry.last).EXP_AMOUNT_EUR  :=
              tblExpiry(tblExpiry.last).EXP_AMOUNT_EUR +
              (tplExpiryDet.EXP_AMOUNT_EUR -
               tblExpiry(tblExpiry.last).EXP_AMOUNT_EUR -
               tblExpiry(tblExpiry.last).EXP_DISCOUNT_EUR -
               tblExpiry(tblExpiry.last).EXP_DEDUCTION_EUR
              );
--             tblExpiry(tblExpiry.last).EXP_AMOUNT_PC  :=
--               tblExpiry(tblExpiry.last).EXP_AMOUNT_PC +
--               ((det_payment_tuple.DET_PAIED_PC / TotPaymentLC * tplExpiryDet.EXP_AMOUNT_LC) -
--                tblExpiry(tblExpiry.last).EXP_AMOUNT_PC -
--                tblExpiry(tblExpiry.last).EXP_DISCOUNT_PC -
--                tblExpiry(tblExpiry.last).EXP_DEDUCTION_PC
--               );

            -- montant restant à lettrer sur le paiement
            det_payment_tuple.DET_PAIED_LC                                      :=
                                                det_payment_tuple.DET_PAIED_LC - tblExpiry(tblExpiry.last).EXP_AMOUNT_LC;
            det_payment_tuple.DET_DISCOUNT_LC                                   :=
                                           det_payment_tuple.DET_DISCOUNT_LC - tblExpiry(tblExpiry.last).EXP_DISCOUNT_LC;
            det_payment_tuple.DET_DEDUCTION_LC                                  :=
                                         det_payment_tuple.DET_DEDUCTION_LC - tblExpiry(tblExpiry.last).EXP_DEDUCTION_LC;
            det_payment_tuple.DET_DIFF_EXCHANGE                                 :=
                                       det_payment_tuple.DET_DIFF_EXCHANGE - tblExpiry(tblExpiry.last).EXP_DIFF_EXCHANGE;

            det_payment_tuple.DET_PAIED_FC       :=
                                             det_payment_tuple.DET_PAIED_FC - tblExpiry(tblExpiry.last).EXP_AMOUNT_FC;
            det_payment_tuple.DET_DISCOUNT_FC    :=
                                        det_payment_tuple.DET_DISCOUNT_FC - tblExpiry(tblExpiry.last).EXP_DISCOUNT_FC;
            det_payment_tuple.DET_DEDUCTION_FC   :=
                                      det_payment_tuple.DET_DEDUCTION_FC - tblExpiry(tblExpiry.last).EXP_DEDUCTION_FC;
            det_payment_tuple.DET_PAIED_EUR      :=
                                           det_payment_tuple.DET_PAIED_EUR - tblExpiry(tblExpiry.last).EXP_AMOUNT_EUR;
            det_payment_tuple.DET_DISCOUNT_EUR   :=
                                      det_payment_tuple.DET_DISCOUNT_EUR - tblExpiry(tblExpiry.last).EXP_DISCOUNT_EUR;
            det_payment_tuple.DET_DEDUCTION_EUR  :=
                                    det_payment_tuple.DET_DEDUCTION_EUR - tblExpiry(tblExpiry.last).EXP_DEDUCTION_EUR;

            tblLinkDetPayACI_ACT.extend;
            tblLinkDetPayACI_ACT(tblLinkDetPayACI_ACT.last).ACI_DET_PAYMENT_ID  := det_payment_tuple.aci_det_payment_id;
            tblLinkDetPayACI_ACT(tblLinkDetPayACI_ACT.last).ACT_DET_PAYMENT_ID  :=
                                                                            tblExpiry(tblExpiry.last).act_det_payment_id;

            fetch crExpiryDet
             into tplExpiryDet;
          end if;
        end loop;
      end if;

      close crExpiryDet;

      close det_payment;

      cur_det_payment_id  := 0;

      if tblExpiry.count > 0 then
        for ind in tblExpiry.first .. tblExpiry.last loop

          -- un nouveau document pour chaques aci_det_payment_id
          if tblExpiry(ind).ACI_DET_PAYMENT_ID != cur_det_payment_id then
            -- si changement de document -> màj montants de l'ancien
            if cur_det_payment_id != 0 then
              update_doc_amounts(pmt_document_id
                               , new_document_id
                               , null
                               , dc_type
                               , period_id
                               , primary_imp_tuple.IMF_TRANSACTION_DATE
                               , primary_imp_tuple.IMF_VALUE_DATE
                               , part_imputation_tuple.acs_financial_currency_id
                               , cat_description
                               , tblLinkDetPayACI_ACT
                               , tblExpiry(ind-1).EXP_AMOUNT_PC
                               , tblExpiry(ind-1).ACS_FINANCIAL_CURRENCY_ID
                                );

              -- Création des couvertures
              -- Déplacé ici car la création des couvertures dépand
              --  de la présence de paiements directs
              vCoverId  := Recover_Covering(new_document_id, catalogue_document_id, pmt_document_id, cur_det_payment_id);
            end if;

            select ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
                 , ACJ_CATALOGUE_DOCUMENT.ACS_FINANCIAL_ACCOUNT_ID
                 , ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION
              into catalogue_document_id
                 , financial_account_id
                 , cat_description
              from ACJ_JOB_TYPE_S_CATALOGUE
                 , ACJ_CATALOGUE_DOCUMENT
             where ACJ_JOB_TYPE_S_CATALOGUE_ID = tblExpiry(ind).ACJ_JOB_TYPE_S_CAT_DET_ID
               and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

            cur_det_payment_id  := tblExpiry(ind).ACI_DET_PAYMENT_ID;
            -- recherche du numéro de document
            ACT_FUNCTIONS.GetDocNumber(catalogue_document_id, document_tuple.acs_financial_year_id, document_number);

            -- création du document de paiement
            select init_id_seq.nextval
              into pmt_document_id
              from dual;

            insert into ACT_DOCUMENT
                        (ACT_DOCUMENT_ID
                       , ACT_JOB_ID
                       , ACT_JOURNAL_ID
                       , ACT_ACT_JOURNAL_ID
                       , DOC_NUMBER
                       , DOC_TOTAL_AMOUNT_DC
                       , DOC_TOTAL_AMOUNT_EUR
                       , DOC_CHARGES_LC
                       , DOC_DOCUMENT_DATE
                       , DOC_COMMENT
                       , DOC_CCP_TAX
                       , DOC_ORDER_NO
                       , DOC_EFFECTIVE_DATE
                       , DOC_EXECUTIVE_DATE
                       , DOC_ESTABL_DATE
                       , C_STATUS_DOCUMENT
                       , C_CURR_RATE_COVER_TYPE
                       , DIC_DOC_SOURCE_ID
                       , DIC_DOC_DESTINATION_ID
                       , ACS_FINANCIAL_YEAR_ID
                       , ACS_FINANCIAL_CURRENCY_ID
                       , ACJ_CATALOGUE_DOCUMENT_ID
                       , ACS_FINANCIAL_ACCOUNT_ID
                       , PC_USER_ID
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (pmt_document_id
                       , job_id
                       , journal_id
                       , an_journal_id
                       , document_number
                       , 0
                       , 0
                       , null   --DOC_CHARGES_LC,
                       , document_tuple.DOC_DOCUMENT_DATE
                       , null   --DOC_COMMENT,
                       , null   --DOC_CCP_TAX,
                       , null   --DOC_ORDER_NO,
                       , null   --DOC_EFFECTIVE_DATE,
                       , null   --DOC_EXECUTIVE_DATE,
                       , null   --DOC_ESTABL_DATE,
                       , nvl(document_tuple.c_status_document, 'DEF')
                       , document_tuple.c_curr_rate_cover_type
                       , null   --dic_doc_source_id,
                       , null   --dic_doc_destination_id,
                       , document_tuple.acs_financial_year_id
                       , tblExpiry(ind).ACS_FINANCIAL_CURRENCY_ID
                       , catalogue_document_id
                       , null   --acs_financial_account_id,
                       , PCS.PC_I_LIB_SESSION.GetUserId
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );

            -- Recherche de la condition de paiement
            if part_imputation_tuple.pac_supplier_partner_id is not null then
              select PAC_PAYMENT_CONDITION_ID
                into payment_condition_id
                from PAC_SUPPLIER_PARTNER
               where PAC_SUPPLIER_PARTNER_ID = part_imputation_tuple.pac_supplier_partner_id;
            elsif part_imputation_tuple.pac_custom_partner_id is not null then
              select PAC_PAYMENT_CONDITION_ID
                into payment_condition_id
                from PAC_CUSTOM_PARTNER
               where PAC_CUSTOM_PARTNER_ID = part_imputation_tuple.pac_custom_partner_id;
            end if;

            -- Imputation partenaire du document de paiement
            select init_id_seq.nextval
              into pmt_part_imputation_id
              from dual;

            -- Création d'un tuple pour l'imputation partenaire
            insert into ACT_PART_IMPUTATION
                        (ACT_PART_IMPUTATION_ID
                       , ACT_DOCUMENT_ID
                       , PAR_DOCUMENT
                       , PAR_BLOCKED_DOCUMENT
                       , PAC_CUSTOM_PARTNER_ID
                       , PAC_PAYMENT_CONDITION_ID
                       , PAC_SUPPLIER_PARTNER_ID
                       , DIC_PRIORITY_PAYMENT_ID
                       , DIC_CENTER_PAYMENT_ID
                       , DIC_LEVEL_PRIORITY_ID
                       , PAC_FINANCIAL_REFERENCE_ID
                       , ACS_FINANCIAL_CURRENCY_ID
                       , ACS_ACS_FINANCIAL_CURRENCY_ID
                       , PAR_PAIED_LC
                       , PAR_CHARGES_LC
                       , PAR_PAIED_FC
                       , PAR_CHARGES_FC
                       , PAR_EXCHANGE_RATE
                       , PAR_BASE_PRICE
                       , PAC_ADDRESS_ID
                       , PAR_REMIND_DATE
                       , PAR_REMIND_PRINTDATE
                       , PAC_COMMUNICATION_ID
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (pmt_part_imputation_id
                       , pmt_document_id
                       , null   -- PAR_DOCUMENT,
                       , 0   --part_imputation_tuple.PAR_BLOCKED_DOCUMENT,
                       , part_imputation_tuple.pac_custom_partner_id
                       , payment_condition_id   --part_imputation_tuple.pac_payment_condition_id,
                       , part_imputation_tuple.pac_supplier_partner_id
                       , null   --part_imputation_tuple.DIC_PRIORITY_PAYMENT_ID,
                       , null   --part_imputation_tuple.DIC_CENTER_PAYMENT_ID,
                       , null   --part_imputation_tuple.DIC_LEVEL_PRIORITY_ID,
                       , null   --pac_financial_reference_id,
                       , part_imputation_tuple.acs_financial_currency_id
                       , part_imputation_tuple.acs_acs_financial_currency_id
                       , 0
                       , 0   --PAR_CHARGES_LC,
                       , 0
                       , 0   --PAR_CHARGES_FC,
                       , nvl(primary_imp_tuple.IMF_EXCHANGE_RATE, 0)   -- cours du document facture compta
                       , nvl(primary_imp_tuple.IMF_BASE_PRICE, 0)   -- cours du document facture compta
                       , null   --PAC_ADDRESS_ID,
                       , null   --PAR_REMIND_DATE,
                       , null   --PAR_REMIND_PRINTDATE,
                       , null   --PAC_COMMUNICATION_ID,
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );

            -- Imputation primaire du document de paiement
            imputation_id       :=
              Create_imputation(pmt_document_id
                              , period_id
                              , financial_account_id
                              , primary_imp_tuple.acs_division_account_id
                              , cat_description
                              , 0
                              , 0
                              , 0
                              , 0
                              , 0
                              , 0
                              , tblExpiry(ind).ACS_FINANCIAL_CURRENCY_ID
                              , primary_imp_tuple.IMF_VALUE_DATE
                              , primary_imp_tuple.IMF_TRANSACTION_DATE
                              , nvl(tblExpiry(ind).DET_EXCHANGE_RATE, 0)
                              , nvl(tblExpiry(ind).DET_BASE_PRICE, 0)
                              , 1
                               );
          end if;

          net_expiry_id       := tblExpiry(ind).ACT_EXPIRY_ID;
          payment_amount_lc   := tblExpiry(ind).EXP_AMOUNT_LC;
          payment_amount_fc   := tblExpiry(ind).EXP_AMOUNT_FC;
          payment_amount_eur  := tblExpiry(ind).EXP_AMOUNT_EUR;
          discount_lc         := tblExpiry(ind).EXP_DISCOUNT_LC;
          discount_fc         := tblExpiry(ind).EXP_DISCOUNT_FC;
          discount_eur        := tblExpiry(ind).EXP_DISCOUNT_EUR;
          deduction_lc        := tblExpiry(ind).EXP_DEDUCTION_LC;
          deduction_fc        := tblExpiry(ind).EXP_DEDUCTION_FC;
          deduction_eur       := tblExpiry(ind).EXP_DEDUCTION_EUR;
          det_payment_id      := tblExpiry(ind).ACT_DET_PAYMENT_ID;

          insert into act_det_payment
                      (ACT_DET_PAYMENT_ID
                     , ACT_EXPIRY_ID
                     , ACT_DOCUMENT_ID
                     , ACT_PART_IMPUTATION_ID
                     , DET_PAIED_LC
                     , DET_PAIED_FC
                     , DET_PAIED_EUR
                     , DET_CHARGES_LC
                     , DET_CHARGES_FC
                     , DET_CHARGES_EUR
                     , DET_DISCOUNT_LC
                     , DET_DISCOUNT_FC
                     , DET_DISCOUNT_EUR
                     , DET_DEDUCTION_LC
                     , DET_DEDUCTION_FC
                     , DET_DEDUCTION_EUR
                     , DET_LETTRAGE_NO
                     , DET_DIFF_EXCHANGE
                     , DET_TRANSACTION_TYPE
                     , DET_SEQ_NUMBER
                     , DET_FILE_AMOUNT
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (det_payment_id
                     , net_expiry_id
                     , pmt_document_id
                     , pmt_part_imputation_id
                     , nvl(payment_amount_lc, 0)
                     , nvl(payment_amount_fc, 0)
                     , nvl(payment_amount_eur, 0)
                     , 0   --document_tuple.DET_CHARGES_LC,
                     , 0   --document_tuple.DET_CHARGES_FC,
                     , 0   --document_tuple.DET_CHARGES_EUR,
                     , nvl(discount_lc, 0)
                     , nvl(discount_fc, 0)
                     , nvl(discount_eur, 0)
                     , nvl(deduction_lc, 0)
                     , nvl(deduction_fc, 0)
                     , nvl(deduction_eur, 0)
                     , null   --document_tuple.DET_LETTRAGE_NO,
                     , 0   --document_tuple.DET_DIFF_EXCHANGE,
                     , null   --document_tuple.DET_TRANSACTION_TYPE,
                     , null   --document_tuple.DET_SEQ_NUMBER,
                     , null   -- file_amount
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end loop;

        -- màj du dernier document
        if pmt_document_id is not null then
          update_doc_amounts(pmt_document_id
                           , new_document_id
                           , null
                           , dc_type
                           , period_id
                           , primary_imp_tuple.IMF_TRANSACTION_DATE
                           , primary_imp_tuple.IMF_VALUE_DATE
                           , part_imputation_tuple.acs_financial_currency_id
                           , cat_description
                           , tblLinkDetPayACI_ACT
                           , tblExpiry(tblExpiry.last).EXP_AMOUNT_PC
                           , tblExpiry(tblExpiry.last).ACS_FINANCIAL_CURRENCY_ID
                            );
          -- Création des couvertures
          -- Déplacé ici car la création des couvertures dépand
          --  de la présence de paiements directs
          vCoverId  :=
            Recover_Covering(new_document_id
                           , catalogue_document_id
                           , pmt_document_id
                           , tblExpiry(tblExpiry.last).ACI_DET_PAYMENT_ID
                            );
    --       begin
--             raise_application_error(-20000, '3 new_document_id = ' || new_document_id || '; catalogue_document_id = ' || catalogue_document_id || '; pmt_document_id = ' || pmt_document_id || '; ACI_DET_PAYMENT_ID = ' || tblExpiry(tblExpiry.last).ACI_DET_PAYMENT_ID);
--           exception
  --           when others then null;
      --     end;
        end if;
      else
        -- Création des couvertures
        -- Déplacé ici car la création des couvertures dépend
        --  de la présence de paiements directs
        vCoverId  := Recover_Covering(new_document_id);
      end if;
    end if;
  end Recover_Det_Payment_Direct;

  /**
  * Description
  *    reprise des paiements
  */
  procedure Recover_Det_Payment_Imput(
    document_id     in number
  , job_id          in number
  , journal_id      in number
  , an_journal_id   in number
  , new_document_id in number
  , dc_type         in varchar2
  , type_catalogue  in varchar2
  )
  is
    cursor csr_det_payment(document_id number)
    is
      select   det.ACI_DET_PAYMENT_ID
             , det.ACJ_JOB_TYPE_S_CAT_DET_ID
             , nvl(det.DET_PAIED_LC, 0) DET_PAIED_LC
             , nvl(det.DET_PAIED_FC, 0) DET_PAIED_FC
             , nvl(det.DET_PAIED_PC, 0) DET_PAIED_PC
             , nvl(det.DET_PAIED_EUR, 0) DET_PAIED_EUR
             , imp.ACS_FINANCIAL_ACCOUNT_ID
             , imp.ACS_DIVISION_ACCOUNT_ID
             , det.ACS_FINANCIAL_CURRENCY_ID DET_ACS_FINANCIAL_CURRENCY_ID
             , det.DET_EXCHANGE_RATE
             , det.DET_BASE_PRICE
             , imp.ACS_FINANCIAL_CURRENCY_ID IMP_ACS_FINANCIAL_CURRENCY_ID
             , imp.IMF_EXCHANGE_RATE
             , imp.IMF_BASE_PRICE
             , imp.IMF_AMOUNT_LC_D
             , imp.IMF_AMOUNT_LC_C
          from aci_financial_imputation imp
             , aci_det_payment det
         where det.ACI_DOCUMENT_ID = imp.ACI_DOCUMENT_ID
           and det.ACI_DOCUMENT_ID = document_id
           and imp.IMF_PRIMARY + 0 = 1
      order by det.ACJ_JOB_TYPE_S_CAT_DET_ID;

    tpl_document          ACI_DOCUMENT%rowtype;
    tpl_imputation        ACT_FINANCIAL_IMPUTATION%rowtype;
    period_id             ACS_PERIOD.ACS_PERIOD_ID%type;
    financial_account_id  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    catalogue_document_id ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    pmt_document_id       ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    cat_description       ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type;
    document_number       ACT_DOCUMENT.DOC_NUMBER%type;
    imputation_id         ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    InfoImputationManaged ACT_IMP_MANAGEMENT.InfoImputationRecType;
    InfoImputationValues  ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    doc_amount            ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    doc_currency_id       ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    exchange_rate         ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    base_price            ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    financial_currency_id ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    paied_fc              ACT_DET_PAYMENT.DET_PAIED_FC%type;
    isDebImp              boolean;
    signDetPay            number(1);
    signImp               number(1);
  begin
    -- uniquement pour type 1 avec det_payment
    if type_catalogue != '1' then
      return;
    end if;

    select *
      into tpl_document
      from ACI_DOCUMENT
     where ACI_DOCUMENT_ID = document_id;

    -- recherche signe paiement (-1 -> NC, 1 -> Fact)
    select decode(sign(sum(nvl(DET_PAIED_LC, 0) ) ), -1, -1, 1)
      into signDetPay
      from ACI_DET_PAYMENT
     where ACI_DOCUMENT_ID = document_id;

    for tpl_det_payment in csr_det_payment(document_id) loop
      select ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
           , ACJ_CATALOGUE_DOCUMENT.ACS_FINANCIAL_ACCOUNT_ID
           , ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION
        into catalogue_document_id
           , financial_account_id
           , cat_description
        from ACJ_JOB_TYPE_S_CATALOGUE
           , ACJ_CATALOGUE_DOCUMENT
       where ACJ_JOB_TYPE_S_CATALOGUE_ID = tpl_det_payment.ACJ_JOB_TYPE_S_CAT_DET_ID
         and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

      -- recherche des info géreé pour le catalogue
      if nvl(InfoImputationManaged.ACJ_CATALOGUE_DOCUMENT_ID, 0) != catalogue_document_id then
        InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
      end if;

      -- récupération des données compl. des ACI
      ACT_IMP_MANAGEMENT.GetInfoImputationValuesDET_ACI(tpl_det_payment.ACI_DET_PAYMENT_ID, InfoImputationValues);
      -- Màj (null) des champs non gérés
      ACT_IMP_MANAGEMENT.UpdateManagedValues(InfoImputationValues, InfoImputationManaged.primary);
      -- recherche du numéro de document
      ACT_FUNCTIONS.GetDocNumber(catalogue_document_id, tpl_document.acs_financial_year_id, document_number);

      -- monnaie du paiement
      if tpl_det_payment.DET_ACS_FINANCIAL_CURRENCY_ID is not null and
         nvl(tpl_det_payment.DET_PAIED_PC, 0) != 0 then
        financial_currency_id := tpl_det_payment.DET_ACS_FINANCIAL_CURRENCY_ID;
        base_price := tpl_det_payment.DET_BASE_PRICE;
        paied_fc := tpl_det_payment.DET_PAIED_PC;
      else
        financial_currency_id := tpl_det_payment.IMP_ACS_FINANCIAL_CURRENCY_ID;
        base_price := tpl_det_payment.IMF_BASE_PRICE;
        paied_fc := tpl_det_payment.DET_PAIED_FC;
      end if;

      if     financial_currency_id != ACS_FUNCTION.GetLocalCurrencyId
         and nvl(paied_fc, 0) != 0 then
        doc_amount       := abs(paied_fc);
      else
        doc_amount       := abs(tpl_det_payment.DET_PAIED_LC);
        paied_fc         := 0;
      end if;
      doc_currency_id  := financial_currency_id;

      -- création du document de paiement
      select init_id_seq.nextval
        into pmt_document_id
        from dual;

      insert into ACT_DOCUMENT
                  (ACT_DOCUMENT_ID
                 , ACT_JOB_ID
                 , ACT_JOURNAL_ID
                 , ACT_ACT_JOURNAL_ID
                 , DOC_NUMBER
                 , DOC_TOTAL_AMOUNT_DC
                 , DOC_TOTAL_AMOUNT_EUR
                 , DOC_CHARGES_LC
                 , DOC_DOCUMENT_DATE
                 , DOC_COMMENT
                 , DOC_CCP_TAX
                 , DOC_ORDER_NO
                 , DOC_EFFECTIVE_DATE
                 , DOC_EXECUTIVE_DATE
                 , DOC_ESTABL_DATE
                 , C_STATUS_DOCUMENT
                 , C_CURR_RATE_COVER_TYPE
                 , DIC_DOC_SOURCE_ID
                 , DIC_DOC_DESTINATION_ID
                 , ACS_FINANCIAL_YEAR_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACJ_CATALOGUE_DOCUMENT_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , PC_USER_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (pmt_document_id
                 , job_id
                 , journal_id
                 , an_journal_id
                 , document_number
                 , nvl(doc_amount, 0)
                 , 0
                 , null   --DOC_CHARGES_LC,
                 , tpl_document.DOC_DOCUMENT_DATE
                 , null   --DOC_COMMENT,
                 , null   --DOC_CCP_TAX,
                 , null   --DOC_ORDER_NO,
                 , null   --DOC_EFFECTIVE_DATE,
                 , null   --DOC_EXECUTIVE_DATE,
                 , null   --DOC_ESTABL_DATE,
                 , nvl(tpl_document.c_status_document, 'DEF')
                 , tpl_document.c_curr_rate_cover_type
                 , null   --dic_doc_source_id,
                 , null   --dic_doc_destination_id,
                 , tpl_document.acs_financial_year_id
                 , doc_currency_id
                 , catalogue_document_id
                 , null   --acs_financial_account_id,
                 , PCS.PC_I_LIB_SESSION.GetUserId
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      select max(ACS_PERIOD_ID)
        into period_id
        from ACS_PERIOD
       where tpl_document.DOC_DOCUMENT_DATE between PER_START_DATE and trunc(PER_END_DATE) + 0.99999
         and ACS_FINANCIAL_YEAR_ID = tpl_document.acs_financial_year_id
         and C_STATE_PERIOD = 'ACT'
         and C_TYPE_PERIOD = '2';

      -- recherche signe imput. facture
      if nvl(tpl_det_payment.IMF_AMOUNT_LC_C, 0) != 0 then
        signImp   := sign(tpl_det_payment.IMF_AMOUNT_LC_C);
        isDebImp  := false;

        if signDetPay != sign(tpl_det_payment.IMF_AMOUNT_LC_C) then
          signImp  := signImp * -1;
          isDebImp := true;
        end if;
      else
        signImp   := sign(tpl_det_payment.IMF_AMOUNT_LC_D);

        -- si montant = 0 alors comme facture
        if signImp = 0 then
          signImp  := 1;
        end if;

        isDebImp  := true;

        if signDetPay != sign(tpl_det_payment.IMF_AMOUNT_LC_D) then
          signImp  := signImp * -1;
          isDebImp := false;
        end if;
      end if;

      -- Adaptation signe pour le cas de paiements mixte positif et négatif
      if signDetPay != sign(tpl_det_payment.DET_PAIED_LC) then
        signImp  := signImp * -1;
      end if;

      tpl_imputation  := null;

      if not isDebImp then
        tpl_imputation.imf_amount_lc_d   := 0;
        tpl_imputation.imf_amount_lc_c   := signImp * abs(tpl_det_payment.DET_PAIED_LC);
        tpl_imputation.imf_amount_fc_d   := 0;
        tpl_imputation.imf_amount_fc_c   := signImp * abs(paied_fc);
        tpl_imputation.imf_amount_eur_d  := 0;
        tpl_imputation.imf_amount_eur_c  := signImp * abs(tpl_det_payment.DET_PAIED_EUR);
      else
        tpl_imputation.imf_amount_lc_d   := signImp * abs(tpl_det_payment.DET_PAIED_LC);
        tpl_imputation.imf_amount_lc_c   := 0;
        tpl_imputation.imf_amount_fc_d   := signImp * abs(paied_fc);
        tpl_imputation.imf_amount_fc_c   := 0;
        tpl_imputation.imf_amount_eur_d  := signImp * abs(tpl_det_payment.DET_PAIED_EUR);
        tpl_imputation.imf_amount_eur_c  := 0;
      end if;

      -- recalcule du cours en fonction des montants du paiement
      if financial_currency_id != ACS_FUNCTION.GetLocalCurrencyId then
        exchange_rate  :=
          ACS_FUNCTION.CalcRateOfExchangeEUR(tpl_det_payment.DET_PAIED_LC
                                           , paied_fc
                                           , financial_currency_id
                                           , tpl_document.DOC_DOCUMENT_DATE
                                           , base_price
                                            );
      end if;

      -- Imputation primaire du document
      imputation_id   :=
        Create_imputation(pmt_document_id
                        , period_id
                        , financial_account_id
                        , tpl_det_payment.acs_division_account_id
                        , cat_description
                        , tpl_imputation.imf_amount_lc_d
                        , tpl_imputation.imf_amount_lc_c
                        , tpl_imputation.imf_amount_fc_d
                        , tpl_imputation.imf_amount_fc_c
                        , tpl_imputation.imf_amount_eur_d
                        , tpl_imputation.imf_amount_eur_c
                        , financial_currency_id
                        , tpl_document.DOC_DOCUMENT_DATE
                        , tpl_document.DOC_DOCUMENT_DATE
                        , exchange_rate
                        , base_price
                        , 1
                         );
      -- màj des info compl. des ACT
      ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(imputation_id, InfoImputationValues);
      tpl_imputation  := null;

      if isDebImp then
        tpl_imputation.imf_amount_lc_d   := 0;
        tpl_imputation.imf_amount_lc_c   := signImp * abs(tpl_det_payment.DET_PAIED_LC);
        tpl_imputation.imf_amount_fc_d   := 0;
        tpl_imputation.imf_amount_fc_c   := signImp * abs(paied_fc);
        tpl_imputation.imf_amount_eur_d  := 0;
        tpl_imputation.imf_amount_eur_c  := signImp * abs(tpl_det_payment.DET_PAIED_EUR);
      else
        tpl_imputation.imf_amount_lc_d   := signImp * abs(tpl_det_payment.DET_PAIED_LC);
        tpl_imputation.imf_amount_lc_c   := 0;
        tpl_imputation.imf_amount_fc_d   := signImp * abs(paied_fc);
        tpl_imputation.imf_amount_fc_c   := 0;
        tpl_imputation.imf_amount_eur_d  := signImp * abs(tpl_det_payment.DET_PAIED_EUR);
        tpl_imputation.imf_amount_eur_c  := 0;
      end if;

      -- Imputation secondaire du document
      imputation_id   :=
        Create_imputation(pmt_document_id
                        , period_id
                        , tpl_det_payment.acs_financial_account_id
                        , tpl_det_payment.acs_division_account_id
                        , cat_description
                        , tpl_imputation.imf_amount_lc_d
                        , tpl_imputation.imf_amount_lc_c
                        , tpl_imputation.imf_amount_fc_d
                        , tpl_imputation.imf_amount_fc_c
                        , tpl_imputation.imf_amount_eur_d
                        , tpl_imputation.imf_amount_eur_c
                        , financial_currency_id
                        , tpl_document.DOC_DOCUMENT_DATE
                        , tpl_document.DOC_DOCUMENT_DATE
                        , exchange_rate
                        , base_price
                        , 0
                         );
      -- màj des info compl. des ACT
      ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(imputation_id, InfoImputationValues);

      -- Indique que l'état du document
      insert into ACT_DOCUMENT_STATUS
                  (ACT_DOCUMENT_STATUS_ID
                 , ACT_DOCUMENT_ID
                 , DOC_OK
                  )
           values (init_id_seq.nextval
                 , pmt_document_id
                 , 0
                  );

      -- Calcul des cumuls du document créé
      ACT_DOC_TRANSACTION.DocImputations(pmt_document_id, 0);
    end loop;
  end Recover_Det_Payment_Imput;

  /**
  * Description
  *    reprise détaillée des imputations financières
  */
  procedure Recover_Fin_Imp_Detail(
    document_id            in     number
  , new_document_id        in     number
  , new_part_imputation_id in     number
  , financial_year_id      in     number
  , vat_currency_id        in     number
  , pos_zero               in     number
  , catalogue_document_id  in     number
  , doc_number             in     varchar2
  , dc_type                out    varchar2
  )
  is
    cursor fin_imputation(document_id number, managed_info ACT_IMP_MANAGEMENT.IInfoImputationBaseRecType)
    is
      select ACI_FINANCIAL_IMPUTATION_ID
           , IMF_TYPE
           , IMF_GENRE
           , IMF_PRIMARY
           , IMF_DESCRIPTION
           , IMF_AMOUNT_LC_D
           , IMF_AMOUNT_LC_C
           , nvl(IMF_EXCHANGE_RATE, 0) IMF_EXCHANGE_RATE
           , nvl(IMF_BASE_PRICE, 0) IMF_BASE_PRICE
           , IMF_AMOUNT_FC_D
           , IMF_AMOUNT_FC_C
           , IMF_AMOUNT_EUR_D
           , IMF_AMOUNT_EUR_C
           , IMF_VALUE_DATE
           , IMF_TRANSACTION_DATE
           , nvl(TAX_EXCHANGE_RATE, 0) TAX_EXCHANGE_RATE
           , nvl(DET_BASE_PRICE, 0) DET_BASE_PRICE
           , TAX_INCLUDED_EXCLUDED
           , TAX_LIABLED_AMOUNT
           , TAX_LIABLED_RATE
           , TAX_RATE
           , TAX_DEDUCTIBLE_RATE
           , TAX_VAT_AMOUNT_FC
           , TAX_VAT_AMOUNT_LC
           , TAX_VAT_AMOUNT_EUR
           , TAX_VAT_AMOUNT_VC
           , TAX_TOT_VAT_AMOUNT_FC
           , TAX_TOT_VAT_AMOUNT_LC
           , TAX_TOT_VAT_AMOUNT_VC
           , TAX_REDUCTION
           , ACS_DIVISION_ACCOUNT_ID
           , ACI_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMF_FINANCIAL_CURRENCY_ID
           , ACI_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMF_IMF_FINANCIAL_CURRENCY_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_AUXILIARY_ACCOUNT_ID
           , ACS_TAX_CODE_ID
           , ACI_FINANCIAL_IMPUTATION.ACS_PERIOD_ID IMF_PERIOD_ID
           , C_GENRE_TRANSACTION
           , decode(managed_info.NUMBER1.managed, 0, null, 1, IMF_NUMBER) IMF_NUMBER
           , decode(managed_info.NUMBER2.managed, 0, null, 1, IMF_NUMBER2) IMF_NUMBER2
           , decode(managed_info.NUMBER3.managed, 0, null, 1, IMF_NUMBER3) IMF_NUMBER3
           , decode(managed_info.NUMBER4.managed, 0, null, 1, IMF_NUMBER4) IMF_NUMBER4
           , decode(managed_info.NUMBER5.managed, 0, null, 1, IMF_NUMBER5) IMF_NUMBER5
           , decode(managed_info.TEXT1.managed, 0, null, 1, IMF_TEXT1) IMF_TEXT1
           , decode(managed_info.TEXT2.managed, 0, null, 1, IMF_TEXT2) IMF_TEXT2
           , decode(managed_info.TEXT3.managed, 0, null, 1, IMF_TEXT3) IMF_TEXT3
           , decode(managed_info.TEXT4.managed, 0, null, 1, IMF_TEXT4) IMF_TEXT4
           , decode(managed_info.TEXT5.managed, 0, null, 1, IMF_TEXT5) IMF_TEXT5
           , decode(managed_info.DATE1.managed, 0, null, 1, IMF_DATE1) IMF_DATE1
           , decode(managed_info.DATE2.managed, 0, null, 1, IMF_DATE2) IMF_DATE2
           , decode(managed_info.DATE3.managed, 0, null, 1, IMF_DATE3) IMF_DATE3
           , decode(managed_info.DATE4.managed, 0, null, 1, IMF_DATE4) IMF_DATE4
           , decode(managed_info.DATE5.managed, 0, null, 1, IMF_DATE5) IMF_DATE5
           , decode(managed_info.DICO1.managed, 0, null, 1, DIC_IMP_FREE1_ID) DIC_IMP_FREE1_ID
           , decode(managed_info.DICO2.managed, 0, null, 1, DIC_IMP_FREE2_ID) DIC_IMP_FREE2_ID
           , decode(managed_info.DICO3.managed, 0, null, 1, DIC_IMP_FREE3_ID) DIC_IMP_FREE3_ID
           , decode(managed_info.DICO4.managed, 0, null, 1, DIC_IMP_FREE4_ID) DIC_IMP_FREE4_ID
           , decode(managed_info.DICO5.managed, 0, null, 1, DIC_IMP_FREE5_ID) DIC_IMP_FREE5_ID
           , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, GCO_GOOD_ID) GCO_GOOD_ID
           , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, DOC_RECORD_ID) DOC_RECORD_ID
           , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, HRM_PERSON_ID) HRM_PERSON_ID
           , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, PAC_PERSON_ID) PAC_PERSON_ID
           , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, FAM_FIXED_ASSETS_ID) FAM_FIXED_ASSETS_ID
           , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, C_FAM_TRANSACTION_TYP)
                                                                                                  C_FAM_TRANSACTION_TYP
        from ACI_FINANCIAL_IMPUTATION
       where ACI_FINANCIAL_IMPUTATION.ACI_DOCUMENT_ID = document_id;

    cursor mgm_imputation(fin_imputation_id number, managed_info ACT_IMP_MANAGEMENT.IInfoImputationBaseRecType)
    is
      select ACI_MGM_IMPUTATION_ID
           , IMM_TYPE
           , IMM_GENRE
           , IMM_PRIMARY
           , IMM_DESCRIPTION
           , IMM_AMOUNT_LC_D
           , IMM_AMOUNT_LC_C
           , nvl(IMM_EXCHANGE_RATE, 0) IMM_EXCHANGE_RATE
           , nvl(IMM_BASE_PRICE, 0) IMM_BASE_PRICE
           , IMM_AMOUNT_FC_D
           , IMM_AMOUNT_FC_C
           , IMM_AMOUNT_EUR_D
           , IMM_AMOUNT_EUR_C
           , IMM_VALUE_DATE
           , IMM_TRANSACTION_DATE
           , IMM_QUANTITY_D
           , IMM_QUANTITY_C
           , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMM_FINANCIAL_CURRENCY_ID
           , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMM_IMM_FINANCIAL_CURRENCY_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
           , ACS_QTY_UNIT_ID
           , ACI_MGM_IMPUTATION.ACS_PERIOD_ID IMM_PERIOD_ID
           , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER) IMM_NUMBER
           , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2) IMM_NUMBER2
           , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3) IMM_NUMBER3
           , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4) IMM_NUMBER4
           , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5) IMM_NUMBER5
           , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1) IMM_TEXT1
           , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2) IMM_TEXT2
           , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3) IMM_TEXT3
           , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4) IMM_TEXT4
           , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5) IMM_TEXT5
           , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1) IMM_DATE1
           , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2) IMM_DATE2
           , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3) IMM_DATE3
           , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4) IMM_DATE4
           , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5) IMM_DATE5
           , decode(managed_info.DICO1.managed, 0, null, 1, DIC_IMP_FREE1_ID) DIC_IMP_FREE1_ID
           , decode(managed_info.DICO2.managed, 0, null, 1, DIC_IMP_FREE2_ID) DIC_IMP_FREE2_ID
           , decode(managed_info.DICO3.managed, 0, null, 1, DIC_IMP_FREE3_ID) DIC_IMP_FREE3_ID
           , decode(managed_info.DICO4.managed, 0, null, 1, DIC_IMP_FREE4_ID) DIC_IMP_FREE4_ID
           , decode(managed_info.DICO5.managed, 0, null, 1, DIC_IMP_FREE5_ID) DIC_IMP_FREE5_ID
           , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, GCO_GOOD_ID) GCO_GOOD_ID
           , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, DOC_RECORD_ID) DOC_RECORD_ID
           , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, HRM_PERSON_ID) HRM_PERSON_ID
           , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, PAC_PERSON_ID) PAC_PERSON_ID
           , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, FAM_FIXED_ASSETS_ID) FAM_FIXED_ASSETS_ID
           , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, C_FAM_TRANSACTION_TYP)
                                                                                                  C_FAM_TRANSACTION_TYP
        from ACI_MGM_IMPUTATION
       where ACI_MGM_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_id;

    fin_imputation_tuple   fin_imputation%rowtype;
    new_financial_imp_id   ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    new_financial_imp_id2  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    new_fin_imp_nonded_id  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    new_mgm_imp_id         ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    vat_amount_lc_d        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_amount_lc_c        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_amount_fc_d        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_fc_c        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_eur_d       ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_EUR%type            default 0;
    vat_amount_eur_c       ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_EUR%type            default 0;
    vat_amount_vc_d        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_amount_vc_c        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_tot_amount_lc_d    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_tot_amount_lc_c    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_tot_amount_fc_d    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_tot_amount_fc_c    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_tot_amount_vc_d    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_tot_amount_vc_c    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    amount_lc_d            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
    amount_lc_c            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type               default 0;
    amount_fc_d            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    amount_fc_c            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    amount_eur_d           ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    amount_eur_c           ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    mgm_amount_fc_d        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type                     default 0;
    mgm_amount_fc_c        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type                     default 0;
    mgm_amount_eur_d       ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type                     default 0;
    mgm_amount_eur_c       ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type                     default 0;
    tax_col_fin_account_id ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    es_calc_sheet          ACS_TAX_CODE.C_ESTABLISHING_CALC_SHEET%type;
    prea_account_id        ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    prov_account_id        ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    fin_nonded_acc_id      ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    sign_liabled           number(1);
    lang_id                PCS.PC_LANG.PC_LANG_ID%type;
    exchangeRate           ACI_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    basePrice              ACI_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    roundCurrency          ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type;
    description_vat        ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    description_vat_nonded ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    InfoImputationManaged  ACT_IMP_MANAGEMENT.InfoImputationRecType;
    IInfoImputationManaged ACT_IMP_MANAGEMENT.IInfoImputationRecType;
    encashment             boolean;
    vOldValues             ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vNewValues             ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vACS_CPN_ACCOUNT_ID    ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type;
    MGMImput               ACT_MGM_IMPUTATION%rowtype;
    ded_amount_lc_d        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
    ded_amount_lc_c        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type               default 0;
    ded_amount_fc_d        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    ded_amount_fc_c        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    ded_amount_eur_d       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    ded_amount_eur_c       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    ded_financial_currency_id ACI_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- recherche des info géreé pour le catalogue et conversion des boolean en integer pour la commande SQL
    InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
    ACT_IMP_MANAGEMENT.ConvertManagedValuesToInt(InfoImputationManaged, IInfoImputationManaged);

    -- ouverture du curseur sur les imputations financières
    open fin_imputation(document_id, IInfoImputationManaged.primary);

    fetch fin_imputation
     into fin_imputation_tuple;

    -- Si le document comporte des imputations financières
    if fin_imputation%found then
      -- message d'erreur s'il n'y a pas de compte financier valid dans l'interface
      if fin_imputation_tuple.acs_financial_account_id is null then
        raise_application_error
                             (-20001
                            , 'PCS - No valid financial account in the financial imputation interface. Document : ' ||
                              to_char(document_id)
                             );
      end if;

      -- message d'erreur s'il n'y a pas de période valide dans l'interface
      if fin_imputation_tuple.imf_period_id is null then
        raise_application_error(-20001, 'PCS - No valid financial period in the financial imputation interface');
      end if;

      -- recherche de la langue du partenaire
      select nvl(min(A.PC_LANG_ID), PCS.PC_I_LIB_SESSION.GETCOMPLANGID)
        into lang_id
        from PAC_ADDRESS A
           , DIC_ADDRESS_TYPE B
           , ACT_PART_IMPUTATION C
       where C.ACT_DOCUMENT_ID = new_document_id
         and A.PAC_PERSON_ID = nvl(C.PAC_CUSTOM_PARTNER_ID, PAC_SUPPLIER_PARTNER_ID)
         and A.DIC_ADDRESS_TYPE_ID = B.DIC_ADDRESS_TYPE_ID
         and DAD_DEFAULT = 1;

      -- initialisation de la description pour la TVA
      description_vat         :=
                         replace(PCS.PC_FUNCTIONS.TranslateWord2('TVA sur DOCNUMBER', Lang_id), 'DOCNUMBER', doc_number);
      description_vat_nonded  := description_vat || ' ' || PCS.PC_FUNCTIONS.TranslateWord2('(non déductible)', Lang_id);

      -- pour toutes les imputations financières
      while fin_imputation%found loop
        -- valeur de retour afin de savoir si on a un document débit ou crédit
        if fin_imputation_tuple.imf_primary = 1 then
          if fin_imputation_tuple.IMF_AMOUNT_LC_C <> 0 then
            dc_type  := 'C';
          else
            dc_type  := 'D';
          end if;
        end if;

        -- mise à jour des montants TVA
        if fin_imputation_tuple.acs_tax_code_id is not null then
          if fin_imputation_tuple.IMF_AMOUNT_LC_C <> 0 then
            vat_amount_lc_c      := fin_imputation_tuple.TAX_VAT_AMOUNT_LC;
            vat_amount_eur_c     := fin_imputation_tuple.TAX_VAT_AMOUNT_EUR;
            vat_tot_amount_lc_c  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_LC;

            if sign(vat_currency_id) = 1 then
              vat_amount_vc_c      := fin_imputation_tuple.TAX_VAT_AMOUNT_VC;
              vat_tot_amount_vc_c  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_VC;
            end if;

            if not fin_imputation_tuple.imf_financial_currency_id = fin_imputation_tuple.imf_imf_financial_currency_id then
              vat_amount_fc_c      := fin_imputation_tuple.TAX_VAT_AMOUNT_FC;
              vat_tot_amount_fc_c  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_FC;
            end if;
          else
            vat_amount_lc_d      := fin_imputation_tuple.TAX_VAT_AMOUNT_LC;
            vat_amount_eur_d     := fin_imputation_tuple.TAX_VAT_AMOUNT_EUR;
            vat_tot_amount_lc_d  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_LC;

            if sign(vat_currency_id) = 1 then
              vat_amount_vc_d      := fin_imputation_tuple.TAX_VAT_AMOUNT_VC;
              vat_tot_amount_vc_d  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_VC;
            end if;

            if not fin_imputation_tuple.imf_financial_currency_id = fin_imputation_tuple.imf_imf_financial_currency_id then
              vat_amount_fc_d      := fin_imputation_tuple.TAX_VAT_AMOUNT_FC;
              vat_tot_amount_fc_d  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_FC;
            end if;
          end if;
        else
          vat_amount_lc_c      := 0;
          vat_amount_lc_d      := 0;
          vat_amount_fc_c      := 0;
          vat_amount_fc_d      := 0;
          vat_amount_eur_c     := 0;
          vat_amount_eur_d     := 0;
          vat_amount_vc_d      := 0;
          vat_amount_vc_c      := 0;
          vat_tot_amount_lc_c  := 0;
          vat_tot_amount_lc_d  := 0;
          vat_tot_amount_fc_c  := 0;
          vat_tot_amount_fc_d  := 0;
          vat_tot_amount_vc_d  := 0;
          vat_tot_amount_vc_c  := 0;
        end if;

        exchangeRate            := fin_imputation_tuple.IMF_EXCHANGE_RATE;
        basePrice               := fin_imputation_tuple.IMF_BASE_PRICE;

        if fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
          amount_lc_d  := fin_imputation_tuple.IMF_AMOUNT_LC_D - vat_amount_lc_d;
          amount_lc_c  := fin_imputation_tuple.IMF_AMOUNT_LC_C - vat_amount_lc_c;
          amount_fc_d  := fin_imputation_tuple.IMF_AMOUNT_FC_D - vat_amount_fc_d;
          amount_fc_c  := fin_imputation_tuple.IMF_AMOUNT_FC_C - vat_amount_fc_c;
        else
          amount_lc_d  := fin_imputation_tuple.IMF_AMOUNT_LC_D;
          amount_lc_c  := fin_imputation_tuple.IMF_AMOUNT_LC_C;
          amount_fc_d  := fin_imputation_tuple.IMF_AMOUNT_FC_D;
          amount_fc_c  := fin_imputation_tuple.IMF_AMOUNT_FC_C;
        end if;

        if fin_imputation_tuple.imf_financial_currency_id != fin_imputation_tuple.imf_imf_financial_currency_id then
          --Màj du cours de change
          UpdateExchangeRate( (amount_lc_c + amount_lc_d)
                           , (amount_fc_c + amount_fc_d)
                           , fin_imputation_tuple.imf_financial_currency_id
                           , exchangeRate
                           , basePrice
                            );
        end if;

/*
        -- mise à jour des montants EURO (ils sont à 0 s'il ne sont pas gêrés)
        amount_eur_c := fin_imputation_tuple.IMF_AMOUNT_EUR_D - vat_amount_eur_d;
        amount_eur_d := fin_imputation_tuple.IMF_AMOUNT_EUR_C - vat_amount_eur_c;

        -- mise à jour des montants en monnaie étrangère si elle est utilisée
        if not fin_imputation_tuple.imf_financial_currency_id = fin_imputation_tuple.imf_imf_financial_currency_id then
          amount_fc_c := fin_imputation_tuple.IMF_AMOUNT_FC_D - vat_amount_fc_d;
          amount_fc_d := fin_imputation_tuple.IMF_AMOUNT_FC_C - vat_amount_fc_c;
        end if;
*/
        if    (   fin_imputation_tuple.IMF_AMOUNT_LC_D <> 0
               or fin_imputation_tuple.IMF_AMOUNT_LC_C <> 0
               or fin_imputation_tuple.IMF_AMOUNT_FC_D <> 0
               or fin_imputation_tuple.IMF_AMOUNT_FC_C <> 0
              )
           or fin_imputation_tuple.IMF_PRIMARY = 1
           or pos_zero = 1 then
          -- recherche d'un id unique pour l'imputation que l'on va créer
          select init_id_seq.nextval
            into new_financial_imp_id
            from dual;

          -- Reprise de l'imputation pointée par le curseur.
          insert into ACT_FINANCIAL_IMPUTATION
                      (ACT_FINANCIAL_IMPUTATION_ID
                     , ACT_DOCUMENT_ID
                     , ACT_PART_IMPUTATION_ID
                     , ACS_PERIOD_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , IMF_TYPE
                     , IMF_PRIMARY
                     , IMF_DESCRIPTION
                     , IMF_AMOUNT_LC_D
                     , IMF_AMOUNT_LC_C
                     , IMF_EXCHANGE_RATE
                     , IMF_BASE_PRICE
                     , IMF_AMOUNT_FC_D
                     , IMF_AMOUNT_FC_C
                     , IMF_AMOUNT_EUR_D
                     , IMF_AMOUNT_EUR_C
                     , IMF_VALUE_DATE
                     , ACS_TAX_CODE_ID
                     , IMF_TRANSACTION_DATE
                     , ACS_AUXILIARY_ACCOUNT_ID
                     ,
                       -- ACT_DET_PAYMENT_ID,
                       IMF_GENRE
                     , ACS_FINANCIAL_CURRENCY_ID
                     , ACS_ACS_FINANCIAL_CURRENCY_ID
                     , C_GENRE_TRANSACTION
                     , IMF_NUMBER
                     , IMF_NUMBER2
                     , IMF_NUMBER3
                     , IMF_NUMBER4
                     , IMF_NUMBER5
                     , IMF_TEXT1
                     , IMF_TEXT2
                     , IMF_TEXT3
                     , IMF_TEXT4
                     , IMF_TEXT5
                     , IMF_DATE1
                     , IMF_DATE2
                     , IMF_DATE3
                     , IMF_DATE4
                     , IMF_DATE5
                     , DIC_IMP_FREE1_ID
                     , DIC_IMP_FREE2_ID
                     , DIC_IMP_FREE3_ID
                     , DIC_IMP_FREE4_ID
                     , DIC_IMP_FREE5_ID
                     , GCO_GOOD_ID
                     , DOC_RECORD_ID
                     , HRM_PERSON_ID
                     , PAC_PERSON_ID
                     , FAM_FIXED_ASSETS_ID
                     , C_FAM_TRANSACTION_TYP
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (new_financial_imp_id
                     , new_document_id
                     , new_part_imputation_id
                     , fin_imputation_tuple.imf_period_id
                     , fin_imputation_tuple.acs_financial_account_id
                     , fin_imputation_tuple.IMF_TYPE
                     , fin_imputation_tuple.IMF_PRIMARY
                     , fin_imputation_tuple.IMF_DESCRIPTION
                     , nvl(fin_imputation_tuple.IMF_AMOUNT_LC_D, 0) -
                       decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_lc_d, 0), 0)
                     , nvl(fin_imputation_tuple.IMF_AMOUNT_LC_C, 0) -
                       decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_lc_c, 0), 0)
                     , exchangeRate
                     , basePrice
                     , nvl(fin_imputation_tuple.IMF_AMOUNT_FC_D, 0) -
                       decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_fc_d, 0), 0)
                     , nvl(fin_imputation_tuple.IMF_AMOUNT_FC_C, 0) -
                       decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_fc_c, 0), 0)
                     , nvl(fin_imputation_tuple.IMF_AMOUNT_EUR_D, 0) -
                       decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_eur_d, 0), 0)
                     , nvl(fin_imputation_tuple.IMF_AMOUNT_EUR_C, 0) -
                       decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_eur_c, 0), 0)
                     , fin_imputation_tuple.IMF_VALUE_DATE
                     , fin_imputation_tuple.acs_tax_code_id
                     , fin_imputation_tuple.IMF_TRANSACTION_DATE
                     , fin_imputation_tuple.acs_auxiliary_account_id
                     ,
                       -- fin_imputation_tuple.ACT_DET_PAYMENT_ID,
                       fin_imputation_tuple.IMF_GENRE
                     , fin_imputation_tuple.imf_financial_currency_id
                     , fin_imputation_tuple.imf_imf_financial_currency_id
                     , fin_imputation_tuple.C_GENRE_TRANSACTION
                     , fin_imputation_tuple.IMF_NUMBER
                     , fin_imputation_tuple.IMF_NUMBER2
                     , fin_imputation_tuple.IMF_NUMBER3
                     , fin_imputation_tuple.IMF_NUMBER4
                     , fin_imputation_tuple.IMF_NUMBER5
                     , fin_imputation_tuple.IMF_TEXT1
                     , fin_imputation_tuple.IMF_TEXT2
                     , fin_imputation_tuple.IMF_TEXT3
                     , fin_imputation_tuple.IMF_TEXT4
                     , fin_imputation_tuple.IMF_TEXT5
                     , fin_imputation_tuple.IMF_DATE1
                     , fin_imputation_tuple.IMF_DATE2
                     , fin_imputation_tuple.IMF_DATE3
                     , fin_imputation_tuple.IMF_DATE4
                     , fin_imputation_tuple.IMF_DATE5
                     , fin_imputation_tuple.DIC_IMP_FREE1_ID
                     , fin_imputation_tuple.DIC_IMP_FREE2_ID
                     , fin_imputation_tuple.DIC_IMP_FREE3_ID
                     , fin_imputation_tuple.DIC_IMP_FREE4_ID
                     , fin_imputation_tuple.DIC_IMP_FREE5_ID
                     , fin_imputation_tuple.GCO_GOOD_ID
                     , fin_imputation_tuple.DOC_RECORD_ID
                     , fin_imputation_tuple.HRM_PERSON_ID
                     , fin_imputation_tuple.PAC_PERSON_ID
                     , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                     , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          -- si on a un compte division, on crée la distribution financière
          if fin_imputation_tuple.acs_division_account_id is not null then
            if fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
              Recover_Fin_Distrib(new_financial_imp_id
                                , fin_imputation_tuple.IMF_DESCRIPTION
                                , fin_imputation_tuple.IMF_AMOUNT_LC_D - vat_amount_lc_d
                                , fin_imputation_tuple.IMF_AMOUNT_FC_D - vat_amount_fc_d
                                , fin_imputation_tuple.IMF_AMOUNT_EUR_D - vat_amount_eur_d
                                , fin_imputation_tuple.IMF_AMOUNT_LC_C - vat_amount_lc_c
                                , fin_imputation_tuple.IMF_AMOUNT_FC_C - vat_amount_fc_c
                                , fin_imputation_tuple.IMF_AMOUNT_EUR_C - vat_amount_eur_c
                                , fin_imputation_tuple.acs_division_account_id
                                 );
            else
              Recover_Fin_Distrib(new_financial_imp_id
                                , fin_imputation_tuple.IMF_DESCRIPTION
                                , fin_imputation_tuple.IMF_AMOUNT_LC_D
                                , fin_imputation_tuple.IMF_AMOUNT_FC_D
                                , fin_imputation_tuple.IMF_AMOUNT_EUR_D
                                , fin_imputation_tuple.IMF_AMOUNT_LC_C
                                , fin_imputation_tuple.IMF_AMOUNT_FC_C
                                , fin_imputation_tuple.IMF_AMOUNT_EUR_C
                                , fin_imputation_tuple.acs_division_account_id
                                 );
            end if;
          end if;

          for mgm_imputation_tuple in mgm_imputation(fin_imputation_tuple.aci_financial_imputation_id
                                                   , IInfoImputationManaged.primary
                                                    ) loop
            exchangeRate  := mgm_imputation_tuple.IMM_EXCHANGE_RATE;
            basePrice     := mgm_imputation_tuple.IMM_BASE_PRICE;

            if mgm_imputation_tuple.imm_financial_currency_id != mgm_imputation_tuple.imm_imm_financial_currency_id then
              --Màj du cours de change
              UpdateExchangeRate( (mgm_imputation_tuple.IMM_AMOUNT_LC_C + mgm_imputation_tuple.IMM_AMOUNT_LC_D)
                               , (mgm_imputation_tuple.IMM_AMOUNT_FC_C + mgm_imputation_tuple.IMM_AMOUNT_FC_D)
                               , mgm_imputation_tuple.imm_financial_currency_id
                               , exchangeRate
                               , basePrice
                                );
            end if;

            -- recherche d'un id unique pour l'imputation que l'on va créer
            select init_id_seq.nextval
              into new_mgm_imp_id
              from dual;

            insert into ACT_MGM_IMPUTATION
                        (ACT_MGM_IMPUTATION_ID
                       , ACS_FINANCIAL_CURRENCY_ID
                       , ACS_ACS_FINANCIAL_CURRENCY_ID
                       , ACS_PERIOD_ID
                       , ACS_CPN_ACCOUNT_ID
                       , ACS_CDA_ACCOUNT_ID
                       , ACS_PF_ACCOUNT_ID
                       , ACT_DOCUMENT_ID
                       , ACT_FINANCIAL_IMPUTATION_ID
                       , IMM_TYPE
                       , IMM_GENRE
                       , IMM_PRIMARY
                       , IMM_DESCRIPTION
                       , IMM_AMOUNT_LC_D
                       , IMM_AMOUNT_LC_C
                       , IMM_EXCHANGE_RATE
                       , IMM_BASE_PRICE
                       , IMM_AMOUNT_FC_D
                       , IMM_AMOUNT_FC_C
                       , IMM_AMOUNT_EUR_D
                       , IMM_AMOUNT_EUR_C
                       , IMM_QUANTITY_D
                       , IMM_QUANTITY_C
                       , IMM_VALUE_DATE
                       , IMM_TRANSACTION_DATE
                       , ACS_QTY_UNIT_ID
                       , IMM_TEXT1
                       , IMM_TEXT2
                       , IMM_TEXT3
                       , IMM_TEXT4
                       , IMM_TEXT5
                       , IMM_DATE1
                       , IMM_DATE2
                       , IMM_DATE3
                       , IMM_DATE4
                       , IMM_DATE5
                       , IMM_NUMBER
                       , IMM_NUMBER2
                       , IMM_NUMBER3
                       , IMM_NUMBER4
                       , IMM_NUMBER5
                       , DIC_IMP_FREE1_ID
                       , DIC_IMP_FREE2_ID
                       , DIC_IMP_FREE3_ID
                       , DIC_IMP_FREE4_ID
                       , DIC_IMP_FREE5_ID
                       , DOC_RECORD_ID
                       , GCO_GOOD_ID
                       , HRM_PERSON_ID
                       , PAC_PERSON_ID
                       , FAM_FIXED_ASSETS_ID
                       , C_FAM_TRANSACTION_TYP
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (new_mgm_imp_id
                       , mgm_imputation_tuple.imm_financial_currency_id
                       , mgm_imputation_tuple.imm_imm_financial_currency_id
                       , mgm_imputation_tuple.imm_period_id
                       , mgm_imputation_tuple.acs_cpn_account_id
                       , mgm_imputation_tuple.acs_cda_account_id
                       , mgm_imputation_tuple.acs_pf_account_id
                       , new_document_id
                       , new_financial_imp_id
                       , mgm_imputation_tuple.IMM_TYPE
                       , mgm_imputation_tuple.IMM_GENRE
                       , mgm_imputation_tuple.IMM_PRIMARY
                       , mgm_imputation_tuple.IMM_DESCRIPTION
                       , nvl(mgm_imputation_tuple.IMM_AMOUNT_LC_D, 0)
                       , nvl(mgm_imputation_tuple.IMM_AMOUNT_LC_C, 0)
                       , exchangeRate
                       , basePrice
                       , nvl(mgm_imputation_tuple.IMM_AMOUNT_FC_D, 0)
                       , nvl(mgm_imputation_tuple.IMM_AMOUNT_FC_C, 0)
                       , nvl(mgm_imputation_tuple.IMM_AMOUNT_EUR_D, 0)
                       , nvl(mgm_imputation_tuple.IMM_AMOUNT_EUR_C, 0)
                       , nvl(mgm_imputation_tuple.IMM_QUANTITY_D, 0)
                       , nvl(mgm_imputation_tuple.IMM_QUANTITY_C, 0)
                       , mgm_imputation_tuple.IMM_VALUE_DATE
                       , mgm_imputation_tuple.IMM_TRANSACTION_DATE
                       , mgm_imputation_tuple.ACS_QTY_UNIT_ID
                       , mgm_imputation_tuple.IMM_TEXT1
                       , mgm_imputation_tuple.IMM_TEXT2
                       , mgm_imputation_tuple.IMM_TEXT3
                       , mgm_imputation_tuple.IMM_TEXT4
                       , mgm_imputation_tuple.IMM_TEXT5
                       , mgm_imputation_tuple.IMM_DATE1
                       , mgm_imputation_tuple.IMM_DATE2
                       , mgm_imputation_tuple.IMM_DATE3
                       , mgm_imputation_tuple.IMM_DATE4
                       , mgm_imputation_tuple.IMM_DATE5
                       , mgm_imputation_tuple.IMM_NUMBER
                       , mgm_imputation_tuple.IMM_NUMBER2
                       , mgm_imputation_tuple.IMM_NUMBER3
                       , mgm_imputation_tuple.IMM_NUMBER4
                       , mgm_imputation_tuple.IMM_NUMBER5
                       , mgm_imputation_tuple.DIC_IMP_FREE1_ID
                       , mgm_imputation_tuple.DIC_IMP_FREE2_ID
                       , mgm_imputation_tuple.DIC_IMP_FREE3_ID
                       , mgm_imputation_tuple.DIC_IMP_FREE4_ID
                       , mgm_imputation_tuple.DIC_IMP_FREE5_ID
                       , mgm_imputation_tuple.DOC_RECORD_ID
                       , mgm_imputation_tuple.GCO_GOOD_ID
                       , mgm_imputation_tuple.HRM_PERSON_ID
                       , mgm_imputation_tuple.PAC_PERSON_ID
                       , mgm_imputation_tuple.FAM_FIXED_ASSETS_ID
                       , mgm_imputation_tuple.C_FAM_TRANSACTION_TYP
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );

            -- si on a un compte division, on crée la distribution financière
            if mgm_imputation_tuple.acs_pj_account_id is not null then
              -- mise à jour des montants en monnaie étrangère si elle est utilisée
              if not mgm_imputation_tuple.imm_financial_currency_id =
                                                                     mgm_imputation_tuple.imm_imm_financial_currency_id then
                mgm_amount_fc_d  := mgm_imputation_tuple.IMM_AMOUNT_FC_D;
                mgm_amount_fc_c  := mgm_imputation_tuple.IMM_AMOUNT_FC_C;
              end if;

              Recover_Mgm_Distrib(new_mgm_imp_id
                                , mgm_imputation_tuple.IMM_DESCRIPTION
                                , mgm_imputation_tuple.IMM_AMOUNT_LC_D
                                , mgm_amount_fc_d
                                , mgm_imputation_tuple.IMM_AMOUNT_EUR_D
                                , mgm_imputation_tuple.IMM_AMOUNT_LC_C
                                , mgm_amount_fc_c
                                , mgm_imputation_tuple.IMM_AMOUNT_EUR_C
                                , mgm_imputation_tuple.IMM_QUANTITY_D
                                , mgm_imputation_tuple.IMM_QUANTITY_C
                                , mgm_imputation_tuple.IMM_TEXT1
                                , mgm_imputation_tuple.IMM_TEXT2
                                , mgm_imputation_tuple.IMM_TEXT3
                                , mgm_imputation_tuple.IMM_TEXT4
                                , mgm_imputation_tuple.IMM_TEXT5
                                , mgm_imputation_tuple.IMM_DATE1
                                , mgm_imputation_tuple.IMM_DATE2
                                , mgm_imputation_tuple.IMM_DATE3
                                , mgm_imputation_tuple.IMM_DATE4
                                , mgm_imputation_tuple.IMM_DATE5
                                , mgm_imputation_tuple.IMM_NUMBER
                                , mgm_imputation_tuple.IMM_NUMBER2
                                , mgm_imputation_tuple.IMM_NUMBER3
                                , mgm_imputation_tuple.IMM_NUMBER4
                                , mgm_imputation_tuple.IMM_NUMBER5
                                , mgm_imputation_tuple.acs_pj_account_id
                                 );
            end if;
          end loop;
        end if;

        -- s'il y a de la TVA sur l'imputation
        if fin_imputation_tuple.acs_tax_code_id is not null then
          if fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
            -- recherche du compte financier d'imputation de la TVA
            select C_ESTABLISHING_CALC_SHEET
                 , ACS_PREA_ACCOUNT_ID
                 , ACS_PROV_ACCOUNT_ID
              into es_calc_sheet
                 , prea_account_id
                 , prov_account_id
              from ACS_TAX_CODE
             where ACS_TAX_CODE_ID = fin_imputation_tuple.acs_tax_code_id;

            encashment := False;
            if es_calc_sheet = '1' then
              tax_col_fin_account_id  := prea_account_id;
            elsif es_calc_sheet = '2' then
              tax_col_fin_account_id  := prov_account_id;
              encashment := nvl(PCS.PC_CONFIG.GetConfigUpper('ACT_TAX_VAT_ENCASHMENT'), 'FALSE') = 'TRUE';
            end if;

            if encashment or (abs(vat_amount_lc_d) + abs(vat_amount_lc_c) > 0) then
              -- recherche d'un id unique pour l'imputation que l'on va créer
              select init_id_seq.nextval
                into new_financial_imp_id2
                from dual;

              if tax_col_fin_account_id is null then
                raise_application_error(-20003, 'PCS - No financial account in the tax code definition');
              end if;

              if    encashment
                 or vat_amount_lc_d <> 0
                 or vat_amount_lc_c <> 0
                 or vat_amount_fc_d <> 0
                 or vat_amount_fc_c <> 0
                 or vat_amount_vc_d <> 0
                 or vat_amount_vc_c <> 0 then
                -- Reprise de l'imputation pointée par le curseur.
                insert into ACT_FINANCIAL_IMPUTATION
                            (ACT_FINANCIAL_IMPUTATION_ID
                           , ACT_DOCUMENT_ID
                           , ACT_PART_IMPUTATION_ID
                           , ACS_PERIOD_ID
                           , ACS_FINANCIAL_ACCOUNT_ID
                           , IMF_TYPE
                           , IMF_PRIMARY
                           , IMF_DESCRIPTION
                           , IMF_AMOUNT_LC_D
                           , IMF_AMOUNT_LC_C
                           , IMF_EXCHANGE_RATE
                           , IMF_BASE_PRICE
                           , IMF_AMOUNT_FC_D
                           , IMF_AMOUNT_FC_C
                           , IMF_AMOUNT_EUR_D
                           , IMF_AMOUNT_EUR_C
                           , IMF_VALUE_DATE
                           , IMF_TRANSACTION_DATE
                           , ACS_AUXILIARY_ACCOUNT_ID
                           ,
                             -- ACT_DET_PAYMENT_ID,
                             IMF_GENRE
                           , ACS_FINANCIAL_CURRENCY_ID
                           , ACS_ACS_FINANCIAL_CURRENCY_ID
                           , C_GENRE_TRANSACTION
                           , IMF_NUMBER
                           , IMF_NUMBER2
                           , IMF_NUMBER3
                           , IMF_NUMBER4
                           , IMF_NUMBER5
                           , IMF_TEXT1
                           , IMF_TEXT2
                           , IMF_TEXT3
                           , IMF_TEXT4
                           , IMF_TEXT5
                           , IMF_DATE1
                           , IMF_DATE2
                           , IMF_DATE3
                           , IMF_DATE4
                           , IMF_DATE5
                           , DIC_IMP_FREE1_ID
                           , DIC_IMP_FREE2_ID
                           , DIC_IMP_FREE3_ID
                           , DIC_IMP_FREE4_ID
                           , DIC_IMP_FREE5_ID
                           , GCO_GOOD_ID
                           , DOC_RECORD_ID
                           , HRM_PERSON_ID
                           , PAC_PERSON_ID
                           , FAM_FIXED_ASSETS_ID
                           , C_FAM_TRANSACTION_TYP
                           , A_DATECRE
                           , A_IDCRE
                            )
                     values (new_financial_imp_id2
                           , new_document_id
                           , new_part_imputation_id
                           , fin_imputation_tuple.imf_period_id
                           , tax_col_fin_account_id
                           , 'VAT'
                           , fin_imputation_tuple.IMF_PRIMARY
                           ,
                             -- fin_imputation_tuple.IMF_DESCRIPTION,
                             description_vat
                           , nvl(vat_amount_lc_d, 0)
                           , nvl(vat_amount_lc_c, 0)
                           , fin_imputation_tuple.TAX_EXCHANGE_RATE
                           , fin_imputation_tuple.DET_BASE_PRICE
                           , decode(sign(vat_currency_id), 1, nvl(vat_amount_vc_d, 0), nvl(vat_amount_fc_d, 0))
                           , decode(sign(vat_currency_id), 1, nvl(vat_amount_vc_c, 0), nvl(vat_amount_fc_c, 0))
                           , nvl(vat_amount_eur_d, 0)
                           , nvl(vat_amount_eur_c, 0)
                           , fin_imputation_tuple.IMF_VALUE_DATE
                           , fin_imputation_tuple.IMF_TRANSACTION_DATE
                           , fin_imputation_tuple.acs_auxiliary_account_id
                           ,
                             -- fin_imputation_tuple.ACT_DET_PAYMENT_ID,
                             fin_imputation_tuple.IMF_GENRE
                           , decode(sign(vat_currency_id)
                                  , 1, vat_currency_id
                                  , fin_imputation_tuple.imf_financial_currency_id
                                   )
                           , fin_imputation_tuple.imf_imf_financial_currency_id
                           , fin_imputation_tuple.C_GENRE_TRANSACTION
                           , fin_imputation_tuple.IMF_NUMBER
                           , fin_imputation_tuple.IMF_NUMBER2
                           , fin_imputation_tuple.IMF_NUMBER3
                           , fin_imputation_tuple.IMF_NUMBER4
                           , fin_imputation_tuple.IMF_NUMBER5
                           , fin_imputation_tuple.IMF_TEXT1
                           , fin_imputation_tuple.IMF_TEXT2
                           , fin_imputation_tuple.IMF_TEXT3
                           , fin_imputation_tuple.IMF_TEXT4
                           , fin_imputation_tuple.IMF_TEXT5
                           , fin_imputation_tuple.IMF_DATE1
                           , fin_imputation_tuple.IMF_DATE2
                           , fin_imputation_tuple.IMF_DATE3
                           , fin_imputation_tuple.IMF_DATE4
                           , fin_imputation_tuple.IMF_DATE5
                           , fin_imputation_tuple.DIC_IMP_FREE1_ID
                           , fin_imputation_tuple.DIC_IMP_FREE2_ID
                           , fin_imputation_tuple.DIC_IMP_FREE3_ID
                           , fin_imputation_tuple.DIC_IMP_FREE4_ID
                           , fin_imputation_tuple.DIC_IMP_FREE5_ID
                           , fin_imputation_tuple.GCO_GOOD_ID
                           , fin_imputation_tuple.DOC_RECORD_ID
                           , fin_imputation_tuple.HRM_PERSON_ID
                           , fin_imputation_tuple.PAC_PERSON_ID
                           , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                           , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                           , sysdate
                           , PCS.PC_I_LIB_SESSION.GetUserIni
                            );

                if fin_imputation_tuple.acs_division_account_id is not null then
                  if sign(vat_currency_id) = 1 then
                    Recover_Fin_Distrib
                                     (new_financial_imp_id2
                                    , description_vat
                                    , vat_amount_lc_d
                                    , vat_amount_vc_d
                                    , vat_amount_eur_d
                                    , vat_amount_lc_c
                                    , vat_amount_vc_c
                                    , vat_amount_eur_c
                                    , ACS_FUNCTION.GetDivisionOfAccount(tax_col_fin_account_id
                                                                      , fin_imputation_tuple.acs_division_account_id
                                                                      , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                                                       )
                                     );
                  else
                    Recover_Fin_Distrib
                                     (new_financial_imp_id2
                                    , description_vat
                                    , vat_amount_lc_d
                                    , vat_amount_fc_d
                                    , vat_amount_eur_d
                                    , vat_amount_lc_c
                                    , vat_amount_fc_c
                                    , vat_amount_eur_c
                                    , ACS_FUNCTION.GetDivisionOfAccount(tax_col_fin_account_id
                                                                      , fin_imputation_tuple.acs_division_account_id
                                                                      , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                                                       )
                                     );
                  end if;
                end if;
              end if;
            end if;

            if fin_imputation_tuple.TAX_DEDUCTIBLE_RATE <> 100 then
              ded_amount_lc_d := nvl(vat_tot_amount_lc_d, 0) - nvl(vat_amount_lc_d, 0);
              ded_amount_lc_c := nvl(vat_tot_amount_lc_c, 0) - nvl(vat_amount_lc_c, 0);

              if sign(vat_currency_id) =  1 then
                ded_amount_fc_d := nvl(vat_tot_amount_vc_d, 0) - nvl(vat_amount_vc_d, 0);
                ded_amount_fc_c := nvl(vat_tot_amount_vc_c, 0) - nvl(vat_amount_vc_c, 0);
                ded_financial_currency_id     := vat_currency_id;
              else
                ded_amount_fc_d := nvl(vat_tot_amount_fc_d, 0) - nvl(vat_amount_vc_d, 0);
                ded_amount_fc_c := nvl(vat_tot_amount_fc_c, 0) - nvl(vat_amount_fc_c, 0);
                ded_financial_currency_id     := fin_imputation_tuple.imf_financial_currency_id;
              end if;

              ded_amount_eur_d := null;
              ded_amount_eur_c := null;

              select nvl(ACS_NONDED_ACCOUNT_ID, fin_imputation_tuple.acs_financial_account_id)
                into fin_nonded_acc_id
                from ACS_TAX_CODE
               where ACS_TAX_CODE_ID = fin_imputation_tuple.acs_tax_code_id;

              -- recherche d'un id unique pour l'imputation que l'on va créer
              select init_id_seq.nextval
                into new_fin_imp_nonded_id
                from dual;

              insert into ACT_FINANCIAL_IMPUTATION
                          (ACT_FINANCIAL_IMPUTATION_ID
                         , ACT_DOCUMENT_ID
                         , ACT_PART_IMPUTATION_ID
                         , ACS_PERIOD_ID
                         , ACS_FINANCIAL_ACCOUNT_ID
                         , IMF_TYPE
                         , IMF_PRIMARY
                         , IMF_DESCRIPTION
                         , IMF_AMOUNT_LC_D
                         , IMF_AMOUNT_LC_C
                         , IMF_EXCHANGE_RATE
                         , IMF_BASE_PRICE
                         , IMF_AMOUNT_FC_D
                         , IMF_AMOUNT_FC_C
                         , IMF_AMOUNT_EUR_D
                         , IMF_AMOUNT_EUR_C
                         , IMF_VALUE_DATE
                         , IMF_TRANSACTION_DATE
                         , ACS_AUXILIARY_ACCOUNT_ID
                         ,
                           -- ACT_DET_PAYMENT_ID,
                           IMF_GENRE
                         , ACS_FINANCIAL_CURRENCY_ID
                         , ACS_ACS_FINANCIAL_CURRENCY_ID
                         , C_GENRE_TRANSACTION
                         , IMF_NUMBER
                         , IMF_NUMBER2
                         , IMF_NUMBER3
                         , IMF_NUMBER4
                         , IMF_NUMBER5
                         , IMF_TEXT1
                         , IMF_TEXT2
                         , IMF_TEXT3
                         , IMF_TEXT4
                         , IMF_TEXT5
                         , IMF_DATE1
                         , IMF_DATE2
                         , IMF_DATE3
                         , IMF_DATE4
                         , IMF_DATE5
                         , DIC_IMP_FREE1_ID
                         , DIC_IMP_FREE2_ID
                         , DIC_IMP_FREE3_ID
                         , DIC_IMP_FREE4_ID
                         , DIC_IMP_FREE5_ID
                         , GCO_GOOD_ID
                         , DOC_RECORD_ID
                         , HRM_PERSON_ID
                         , PAC_PERSON_ID
                         , FAM_FIXED_ASSETS_ID
                         , C_FAM_TRANSACTION_TYP
                         , A_DATECRE
                         , A_IDCRE
                          )
                   values (new_fin_imp_nonded_id
                         , new_document_id
                         , new_part_imputation_id
                         , fin_imputation_tuple.imf_period_id
                         , fin_nonded_acc_id
                         , 'MAN'
                         , fin_imputation_tuple.IMF_PRIMARY
                         ,
                           -- fin_imputation_tuple.IMF_DESCRIPTION,
                           description_vat_nonded
                         , ded_amount_lc_d
                         , ded_amount_lc_c
                         , fin_imputation_tuple.TAX_EXCHANGE_RATE
                         , fin_imputation_tuple.DET_BASE_PRICE
                         , ded_amount_fc_d
                         , ded_amount_fc_c
                         , ded_amount_eur_d
                         , ded_amount_eur_c
                         , fin_imputation_tuple.IMF_VALUE_DATE
                         , fin_imputation_tuple.IMF_TRANSACTION_DATE
                         , fin_imputation_tuple.acs_auxiliary_account_id
                         ,
                           -- fin_imputation_tuple.ACT_DET_PAYMENT_ID,
                           fin_imputation_tuple.IMF_GENRE
                         , ded_financial_currency_id
                         , fin_imputation_tuple.imf_imf_financial_currency_id
                         , '1'
                         , fin_imputation_tuple.IMF_NUMBER
                         , fin_imputation_tuple.IMF_NUMBER2
                         , fin_imputation_tuple.IMF_NUMBER3
                         , fin_imputation_tuple.IMF_NUMBER4
                         , fin_imputation_tuple.IMF_NUMBER5
                         , fin_imputation_tuple.IMF_TEXT1
                         , fin_imputation_tuple.IMF_TEXT2
                         , fin_imputation_tuple.IMF_TEXT3
                         , fin_imputation_tuple.IMF_TEXT4
                         , fin_imputation_tuple.IMF_TEXT5
                         , fin_imputation_tuple.IMF_DATE1
                         , fin_imputation_tuple.IMF_DATE2
                         , fin_imputation_tuple.IMF_DATE3
                         , fin_imputation_tuple.IMF_DATE4
                         , fin_imputation_tuple.IMF_DATE5
                         , fin_imputation_tuple.DIC_IMP_FREE1_ID
                         , fin_imputation_tuple.DIC_IMP_FREE2_ID
                         , fin_imputation_tuple.DIC_IMP_FREE3_ID
                         , fin_imputation_tuple.DIC_IMP_FREE4_ID
                         , fin_imputation_tuple.DIC_IMP_FREE5_ID
                         , fin_imputation_tuple.GCO_GOOD_ID
                         , fin_imputation_tuple.DOC_RECORD_ID
                         , fin_imputation_tuple.HRM_PERSON_ID
                         , fin_imputation_tuple.PAC_PERSON_ID
                         , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                         , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                         , sysdate
                         , PCS.PC_I_LIB_SESSION.GetUserIni
                          );

              if fin_imputation_tuple.acs_division_account_id is not null then
                Recover_Fin_Distrib
                                   (new_fin_imp_nonded_id
                                  , description_vat_nonded
                                  , ded_amount_lc_d
                                  , ded_amount_fc_d
                                  , null
                                  , ded_amount_lc_c
                                  , ded_amount_fc_c
                                  , null
                                  , ACS_FUNCTION.GetDivisionOfAccount(fin_nonded_acc_id
                                                                    , fin_imputation_tuple.acs_division_account_id
                                                                    , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                                                     )
                                   );
              end if;

              if new_mgm_imp_id is not null then
                if fin_nonded_acc_id = fin_imputation_tuple.acs_financial_account_id then
                  MGMImput := null;

                  MGMImput.IMM_AMOUNT_LC_D  := ded_amount_lc_d;
                  MGMImput.IMM_AMOUNT_LC_C  := ded_amount_lc_c;
                  MGMImput.IMM_AMOUNT_FC_D  := ded_amount_fc_d;
                  MGMImput.IMM_AMOUNT_EUR_D := ded_amount_eur_d;
                  MGMImput.IMM_AMOUNT_FC_C  := ded_amount_fc_c;
                  MGMImput.IMM_AMOUNT_EUR_C := ded_amount_eur_c;

                  MGMImput.ACS_FINANCIAL_CURRENCY_ID     := ded_financial_currency_id;
                  MGMImput.ACS_ACS_FINANCIAL_CURRENCY_ID := fin_imputation_tuple.imf_imf_financial_currency_id;

                  MGMImput.IMM_EXCHANGE_RATE := fin_imputation_tuple.TAX_EXCHANGE_RATE;
                  MGMImput.IMM_BASE_PRICE    := fin_imputation_tuple.DET_BASE_PRICE;

                  MGMImput.IMM_DESCRIPTION := description_vat_nonded;
                  MGMImput.IMM_TYPE := 'MAN';

                  CreateImputationForVAT(new_fin_imp_nonded_id, new_financial_imp_id, MGMImput);
                else
                  vACS_CPN_ACCOUNT_ID := ACS_FUNCTION.GetCpnOfFinAcc(fin_nonded_acc_id);

                  if vACS_CPN_ACCOUNT_ID is not null then

                    select min(ACS_CDA_ACCOUNT_ID)
                         , min(ACS_PF_ACCOUNT_ID)
                         , min(ACS_PJ_ACCOUNT_ID)
                      into vOldValues.CDAAccId
                         , vOldValues.PFAccId
                         , vOldValues.PJAccId
                      from (select IMP.ACS_CDA_ACCOUNT_ID
                                 , IMP.ACS_PF_ACCOUNT_ID
                                 , DIST.ACS_PJ_ACCOUNT_ID
                              from ACT_MGM_DISTRIBUTION DIST
                                 , ACT_MGM_IMPUTATION IMP
                             where IMP.ACT_FINANCIAL_IMPUTATION_ID = new_financial_imp_id
                               and IMP.ACT_MGM_IMPUTATION_ID = DIST.ACT_MGM_IMPUTATION_ID(+)
                               and rownum = 1);

                    declare
                      vTest Boolean;
                    begin
                      vTest := ACT_MGM_MANAGEMENT.ReInitialize(vACS_CPN_ACCOUNT_ID, fin_imputation_tuple.IMF_TRANSACTION_DATE, vOldValues, vNewValues);
                    end;

                    select init_id_seq.nextval
                      into new_mgm_imp_id
                      from dual;

                    insert into ACT_MGM_IMPUTATION
                                (ACT_MGM_IMPUTATION_ID
                               , ACS_FINANCIAL_CURRENCY_ID
                               , ACS_ACS_FINANCIAL_CURRENCY_ID
                               , ACS_PERIOD_ID
                               , ACS_CPN_ACCOUNT_ID
                               , ACS_CDA_ACCOUNT_ID
                               , ACS_PF_ACCOUNT_ID
                               , ACT_DOCUMENT_ID
                               , ACT_FINANCIAL_IMPUTATION_ID
                               , IMM_TYPE
                               , IMM_GENRE
                               , IMM_PRIMARY
                               , IMM_DESCRIPTION
                               , IMM_AMOUNT_LC_D
                               , IMM_AMOUNT_LC_C
                               , IMM_EXCHANGE_RATE
                               , IMM_BASE_PRICE
                               , IMM_AMOUNT_FC_D
                               , IMM_AMOUNT_FC_C
                               , IMM_AMOUNT_EUR_D
                               , IMM_AMOUNT_EUR_C
                               , IMM_QUANTITY_D
                               , IMM_QUANTITY_C
                               , IMM_VALUE_DATE
                               , IMM_TRANSACTION_DATE
                               , ACS_QTY_UNIT_ID
                               , IMM_TEXT1
                               , IMM_TEXT2
                               , IMM_TEXT3
                               , IMM_TEXT4
                               , IMM_TEXT5
                               , IMM_DATE1
                               , IMM_DATE2
                               , IMM_DATE3
                               , IMM_DATE4
                               , IMM_DATE5
                               , IMM_NUMBER
                               , IMM_NUMBER2
                               , IMM_NUMBER3
                               , IMM_NUMBER4
                               , IMM_NUMBER5
                               , DIC_IMP_FREE1_ID
                               , DIC_IMP_FREE2_ID
                               , DIC_IMP_FREE3_ID
                               , DIC_IMP_FREE4_ID
                               , DIC_IMP_FREE5_ID
                               , DOC_RECORD_ID
                               , GCO_GOOD_ID
                               , HRM_PERSON_ID
                               , PAC_PERSON_ID
                               , FAM_FIXED_ASSETS_ID
                               , C_FAM_TRANSACTION_TYP
                               , A_DATECRE
                               , A_IDCRE
                                )
                         values (new_mgm_imp_id
                               , ded_financial_currency_id
                               , fin_imputation_tuple.imf_imf_financial_currency_id
                               , fin_imputation_tuple.imf_period_id
                               , vACS_CPN_ACCOUNT_ID
                               , vNewValues.CDAAccId
                               , vNewValues.PFAccId
                               , new_document_id
                               , new_fin_imp_nonded_id
                               , 'MAN'
                               , fin_imputation_tuple.IMF_GENRE
                               , fin_imputation_tuple.IMF_PRIMARY
                               , description_vat_nonded
                               , ded_amount_lc_d
                               , ded_amount_lc_c
                               , fin_imputation_tuple.TAX_EXCHANGE_RATE
                               , fin_imputation_tuple.DET_BASE_PRICE
                               , ded_amount_fc_d
                               , ded_amount_fc_c
                               , ded_amount_eur_d
                               , ded_amount_eur_c
                               , 0
                               , 0
                               , fin_imputation_tuple.IMF_VALUE_DATE
                               , fin_imputation_tuple.IMF_TRANSACTION_DATE
                               , ACT_CREATION_SBVR.GetQTYAccountIdOfCPN(vACS_CPN_ACCOUNT_ID)
                               , fin_imputation_tuple.IMF_TEXT1
                               , fin_imputation_tuple.IMF_TEXT2
                               , fin_imputation_tuple.IMF_TEXT3
                               , fin_imputation_tuple.IMF_TEXT4
                               , fin_imputation_tuple.IMF_TEXT5
                               , fin_imputation_tuple.IMF_DATE1
                               , fin_imputation_tuple.IMF_DATE2
                               , fin_imputation_tuple.IMF_DATE3
                               , fin_imputation_tuple.IMF_DATE4
                               , fin_imputation_tuple.IMF_DATE5
                               , fin_imputation_tuple.IMF_NUMBER
                               , fin_imputation_tuple.IMF_NUMBER2
                               , fin_imputation_tuple.IMF_NUMBER3
                               , fin_imputation_tuple.IMF_NUMBER4
                               , fin_imputation_tuple.IMF_NUMBER5
                               , fin_imputation_tuple.DIC_IMP_FREE1_ID
                               , fin_imputation_tuple.DIC_IMP_FREE2_ID
                               , fin_imputation_tuple.DIC_IMP_FREE3_ID
                               , fin_imputation_tuple.DIC_IMP_FREE4_ID
                               , fin_imputation_tuple.DIC_IMP_FREE5_ID
                               , fin_imputation_tuple.DOC_RECORD_ID
                               , fin_imputation_tuple.GCO_GOOD_ID
                               , fin_imputation_tuple.HRM_PERSON_ID
                               , fin_imputation_tuple.PAC_PERSON_ID
                               , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                               , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                               , sysdate
                               , PCS.PC_I_LIB_SESSION.GetUserIni
                                );

                    if vNewValues.PJAccId is not null then
                      Recover_Mgm_Distrib(new_mgm_imp_id
                                        , description_vat_nonded
                                        , ded_amount_lc_d
                                        , ded_amount_fc_d
                                        , ded_amount_eur_d
                                        , ded_amount_lc_c
                                        , ded_amount_fc_c
                                        , ded_amount_eur_c
                                        , 0
                                        , 0
                                        , fin_imputation_tuple.IMF_TEXT1
                                        , fin_imputation_tuple.IMF_TEXT2
                                        , fin_imputation_tuple.IMF_TEXT3
                                        , fin_imputation_tuple.IMF_TEXT4
                                        , fin_imputation_tuple.IMF_TEXT5
                                        , fin_imputation_tuple.IMF_DATE1
                                        , fin_imputation_tuple.IMF_DATE2
                                        , fin_imputation_tuple.IMF_DATE3
                                        , fin_imputation_tuple.IMF_DATE4
                                        , fin_imputation_tuple.IMF_DATE5
                                        , fin_imputation_tuple.IMF_NUMBER
                                        , fin_imputation_tuple.IMF_NUMBER2
                                        , fin_imputation_tuple.IMF_NUMBER3
                                        , fin_imputation_tuple.IMF_NUMBER4
                                        , fin_imputation_tuple.IMF_NUMBER5
                                        , vNewValues.PJAccId
                                         );
                    end if;
                  end if;
                end if;
              end if;
            end if;
          end if;
          -- recherche du signe du montant soumis, celui-ci n'étant pas signé depuis la logistique
          if fin_imputation_tuple.IMF_AMOUNT_LC_D - fin_imputation_tuple.IMF_AMOUNT_LC_C = 0 then
            sign_liabled  := 1;
          else
            sign_liabled  := sign(fin_imputation_tuple.IMF_AMOUNT_LC_D - fin_imputation_tuple.IMF_AMOUNT_LC_C);
          end if;
          -- test du signe du montant soumis
          if sign(fin_imputation_tuple.TAX_LIABLED_AMOUNT) < 0 then
            sign_liabled  := sign_liabled * -1;
          end if;


          if new_financial_imp_id is not null then
            if sign(vat_currency_id) = 1 then
              Recover_Tax_Code(new_financial_imp_id
                             , new_financial_imp_id2
                             , fin_imputation_tuple.TAX_INCLUDED_EXCLUDED
                             , fin_imputation_tuple.TAX_EXCHANGE_RATE
                             , fin_imputation_tuple.TAX_LIABLED_AMOUNT * sign_liabled
                             , fin_imputation_tuple.TAX_LIABLED_RATE
                             , fin_imputation_tuple.TAX_RATE
                             , vat_amount_lc_d - vat_amount_lc_c
                             , vat_amount_vc_d - vat_amount_vc_c
                             , vat_amount_eur_d - vat_amount_eur_c
                             , vat_tot_amount_lc_d - vat_tot_amount_lc_c
                             , vat_tot_amount_vc_d - vat_tot_amount_vc_c
                             , null
                             , fin_imputation_tuple.TAX_DEDUCTIBLE_RATE
                             , new_fin_imp_nonded_id
                             , fin_imputation_tuple.ACS_TAX_CODE_ID
                             , fin_imputation_tuple.TAX_REDUCTION
                             , fin_imputation_tuple.DET_BASE_PRICE
                              );
            else
              Recover_Tax_Code(new_financial_imp_id
                             , new_financial_imp_id2
                             , fin_imputation_tuple.TAX_INCLUDED_EXCLUDED
                             , fin_imputation_tuple.TAX_EXCHANGE_RATE
                             , fin_imputation_tuple.TAX_LIABLED_AMOUNT * sign_liabled
                             , fin_imputation_tuple.TAX_LIABLED_RATE
                             , fin_imputation_tuple.TAX_RATE
                             , vat_amount_lc_d - vat_amount_lc_c
                             , vat_amount_fc_d - vat_amount_fc_c
                             , vat_amount_eur_d - vat_amount_eur_c
                             , vat_tot_amount_lc_d - vat_tot_amount_lc_c
                             , vat_tot_amount_fc_d - vat_tot_amount_fc_c
                             , null
                             , fin_imputation_tuple.TAX_DEDUCTIBLE_RATE
                             , new_fin_imp_nonded_id
                             , fin_imputation_tuple.ACS_TAX_CODE_ID
                             , fin_imputation_tuple.TAX_REDUCTION
                             , fin_imputation_tuple.DET_BASE_PRICE
                              );
            end if;
          end if;
        end if;

        -- Création des imputations d'autotaxation
        if     new_financial_imp_id is not null
           and fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'S'
           and not ACT_VAT_MANAGEMENT.CreateVAT_ACI(new_financial_imp_id) then
          raise_application_error(-20001, 'PCS - Problem with Self-Taxing');
        end if;

        -- imputation suivante
        fetch fin_imputation
         into fin_imputation_tuple;

        -- remise à 0 des variables
        new_financial_imp_id    := null;
        new_financial_imp_id2   := null;
        tax_col_fin_account_id  := null;
        amount_lc_c             := 0;
        amount_lc_d             := 0;
        amount_fc_c             := 0;
        amount_fc_d             := 0;
        vat_amount_lc_d         := 0;
        vat_amount_lc_c         := 0;
        vat_amount_fc_d         := 0;
        vat_amount_fc_c         := 0;
        vat_amount_eur_d        := 0;
        vat_amount_eur_c        := 0;
        vat_amount_vc_d         := 0;
        vat_amount_vc_c         := 0;
        vat_tot_amount_lc_c     := 0;
        vat_tot_amount_lc_d     := 0;
        vat_tot_amount_fc_c     := 0;
        vat_tot_amount_fc_d     := 0;
        vat_tot_amount_vc_d     := 0;
        vat_tot_amount_vc_c     := 0;
      end loop;
    end if;

    -- fermeture du curseur
    close fin_imputation;
  end Recover_Fin_Imp_Detail;

  /**
  * Description
  *    reprise cumulée des imputations financières
  */
  procedure Recover_Fin_Imp_Cumul(
    document_id            in     number
  , new_document_id        in     number
  , new_part_imputation_id in     number
  , financial_year_id      in     number
  , vat_currency_id        in     number
  , pos_zero               in     number
  , catalogue_document_id  in     number
  , doc_number             in     varchar2
  , dc_type                out    varchar2
  )
  is
    cursor fin_imputation(
      document_id  number
    , managed_info ACT_IMP_MANAGEMENT.IInfoImputationBaseRecType
    , cPosZero     number
    )
    is
      select   IMF_TYPE
             , IMF_GENRE
             , IMF_PRIMARY
             , sum(nvl(IMF_AMOUNT_LC_D, 0) ) IMF_AMOUNT_LC_D
             , sum(nvl(IMF_AMOUNT_LC_C, 0) ) IMF_AMOUNT_LC_C
             , nvl(IMF_EXCHANGE_RATE, 0) IMF_EXCHANGE_RATE
             , nvl(IMF_BASE_PRICE, 0) IMF_BASE_PRICE
             , sum(nvl(IMF_AMOUNT_FC_D, 0) ) IMF_AMOUNT_FC_D
             , sum(nvl(IMF_AMOUNT_FC_C, 0) ) IMF_AMOUNT_FC_C
             , sum(nvl(IMF_AMOUNT_EUR_D, 0) ) IMF_AMOUNT_EUR_D
             , sum(nvl(IMF_AMOUNT_EUR_C, 0) ) IMF_AMOUNT_EUR_C
             , IMF_VALUE_DATE
             , IMF_TRANSACTION_DATE
             , nvl(TAX_EXCHANGE_RATE, 0) TAX_EXCHANGE_RATE
             , nvl(DET_BASE_PRICE, 0) DET_BASE_PRICE
             , TAX_INCLUDED_EXCLUDED
             , sum(nvl(TAX_LIABLED_AMOUNT, 0) ) TAX_LIABLED_AMOUNT
             , TAX_LIABLED_RATE
             , TAX_RATE
             , TAX_DEDUCTIBLE_RATE
             , sum(nvl(TAX_VAT_AMOUNT_FC, 0) ) TAX_VAT_AMOUNT_FC
             , sum(nvl(TAX_VAT_AMOUNT_LC, 0) ) TAX_VAT_AMOUNT_LC
             , sum(nvl(TAX_VAT_AMOUNT_EUR, 0) ) TAX_VAT_AMOUNT_EUR
             , sum(nvl(TAX_VAT_AMOUNT_VC, 0) ) TAX_VAT_AMOUNT_VC
             , sum(nvl(TAX_TOT_VAT_AMOUNT_FC, 0) ) TAX_TOT_VAT_AMOUNT_FC
             , sum(nvl(TAX_TOT_VAT_AMOUNT_LC, 0) ) TAX_TOT_VAT_AMOUNT_LC
             , sum(nvl(TAX_TOT_VAT_AMOUNT_VC, 0) ) TAX_TOT_VAT_AMOUNT_VC
             , TAX_REDUCTION
             , ACS_DIVISION_ACCOUNT_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMF_FINANCIAL_CURRENCY_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMF_IMF_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_AUXILIARY_ACCOUNT_ID
             , ACS_TAX_CODE_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_PERIOD_ID IMF_PERIOD_ID
             , C_GENRE_TRANSACTION
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMF_NUMBER) IMF_NUMBER
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMF_NUMBER2) IMF_NUMBER2
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMF_NUMBER3) IMF_NUMBER3
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMF_NUMBER4) IMF_NUMBER4
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMF_NUMBER5) IMF_NUMBER5
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMF_TEXT1) IMF_TEXT1
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMF_TEXT2) IMF_TEXT2
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMF_TEXT3) IMF_TEXT3
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMF_TEXT4) IMF_TEXT4
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMF_TEXT5) IMF_TEXT5
             , decode(managed_info.DATE1.managed, 0, null, 1, IMF_DATE1) IMF_DATE1
             , decode(managed_info.DATE2.managed, 0, null, 1, IMF_DATE2) IMF_DATE2
             , decode(managed_info.DATE3.managed, 0, null, 1, IMF_DATE3) IMF_DATE3
             , decode(managed_info.DATE4.managed, 0, null, 1, IMF_DATE4) IMF_DATE4
             , decode(managed_info.DATE5.managed, 0, null, 1, IMF_DATE5) IMF_DATE5
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE1_ID)
                                                                                                       DIC_IMP_FREE1_ID
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE2_ID)
                                                                                                       DIC_IMP_FREE2_ID
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE3_ID)
                                                                                                       DIC_IMP_FREE3_ID
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE4_ID)
                                                                                                       DIC_IMP_FREE4_ID
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE5_ID)
                                                                                                       DIC_IMP_FREE5_ID
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.GCO_GOOD_ID) GCO_GOOD_ID
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DOC_RECORD_ID)
                                                                                                          DOC_RECORD_ID
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.HRM_PERSON_ID)
                                                                                                          HRM_PERSON_ID
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.PAC_PERSON_ID)
                                                                                                          PAC_PERSON_ID
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed
                    , 0, null
                    , 1, ACI_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID
                     ) FAM_FIXED_ASSETS_ID
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed
                    , 0, null
                    , 1, ACI_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP
                     ) C_FAM_TRANSACTION_TYP
             , max(ACI_MGM_IMPUTATION_ID) ACI_MGM_IMPUTATION_ID
             , max(ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID) ACI_FINANCIAL_IMPUTATION_ID
             , IMM_TYPE
             , IMM_GENRE
             , IMM_PRIMARY
             , sum(nvl(IMM_AMOUNT_LC_D, 0) ) IMM_AMOUNT_LC_D
             , sum(nvl(IMM_AMOUNT_LC_C, 0) ) IMM_AMOUNT_LC_C
             , nvl(IMM_EXCHANGE_RATE, 0) IMM_EXCHANGE_RATE
             , nvl(IMM_BASE_PRICE, 0) IMM_BASE_PRICE
             , sum(nvl(IMM_AMOUNT_FC_D, 0) ) IMM_AMOUNT_FC_D
             , sum(nvl(IMM_AMOUNT_FC_C, 0) ) IMM_AMOUNT_FC_C
             , sum(nvl(IMM_AMOUNT_EUR_D, 0) ) IMM_AMOUNT_EUR_D
             , sum(nvl(IMM_AMOUNT_EUR_C, 0) ) IMM_AMOUNT_EUR_C
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , sum(IMM_QUANTITY_D) IMM_QUANTITY_D
             , sum(IMM_QUANTITY_C) IMM_QUANTITY_C
             , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMM_FINANCIAL_CURRENCY_ID
             , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMM_IMM_FINANCIAL_CURRENCY_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , ACI_MGM_IMPUTATION.ACS_PERIOD_ID IMM_PERIOD_ID
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1) IMM_TEXT1
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2) IMM_TEXT2
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3) IMM_TEXT3
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4) IMM_TEXT4
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5) IMM_TEXT5
             , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1) IMM_DATE1
             , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2) IMM_DATE2
             , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3) IMM_DATE3
             , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4) IMM_DATE4
             , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5) IMM_DATE5
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER) IMM_NUMBER
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2) IMM_NUMBER2
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3) IMM_NUMBER3
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4) IMM_NUMBER4
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5) IMM_NUMBER5
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE1_ID) IMM_DIC_IMP_FREE1_ID
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE2_ID) IMM_DIC_IMP_FREE2_ID
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE3_ID) IMM_DIC_IMP_FREE3_ID
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE4_ID) IMM_DIC_IMP_FREE4_ID
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE5_ID) IMM_DIC_IMP_FREE5_ID
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.DOC_RECORD_ID)
                                                                                                      IMM_DOC_RECORD_ID
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.GCO_GOOD_ID) IMM_GCO_GOOD_ID
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.HRM_PERSON_ID)
                                                                                                      IMM_HRM_PERSON_ID
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.PAC_PERSON_ID)
                                                                                                      IMM_PAC_PERSON_ID
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID)
                                                                                                IMM_FAM_FIXED_ASSETS_ID
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, ACI_MGM_IMPUTATION.C_FAM_TRANSACTION_TYP)
                                                                                              IMM_C_FAM_TRANSACTION_TYP
          from ACI_FINANCIAL_IMPUTATION
             , ACI_MGM_IMPUTATION
         where ACI_FINANCIAL_IMPUTATION.ACI_DOCUMENT_ID = document_id
           and ACI_MGM_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID(+) = ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID
           and (   IMF_AMOUNT_LC_C + IMF_AMOUNT_LC_D <> 0
                or IMF_PRIMARY = 1
                or cPosZero = 1)
      group by IMF_TYPE
             , IMF_GENRE
             , IMF_PRIMARY
             , nvl(IMF_EXCHANGE_RATE, 0)
             , nvl(IMF_BASE_PRICE, 0)
             , IMF_TRANSACTION_DATE
             , IMF_VALUE_DATE
             , nvl(TAX_EXCHANGE_RATE, 0)
             , nvl(DET_BASE_PRICE, 0)
             , TAX_INCLUDED_EXCLUDED
             , TAX_LIABLED_RATE
             , TAX_RATE
             , TAX_DEDUCTIBLE_RATE
             , TAX_REDUCTION
             , ACS_DIVISION_ACCOUNT_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_AUXILIARY_ACCOUNT_ID
             , ACS_TAX_CODE_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_PERIOD_ID
             , C_GENRE_TRANSACTION
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMF_NUMBER)
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMF_NUMBER2)
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMF_NUMBER3)
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMF_NUMBER4)
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMF_NUMBER5)
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMF_TEXT1)
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMF_TEXT2)
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMF_TEXT3)
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMF_TEXT4)
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMF_TEXT5)
             , decode(managed_info.DATE1.managed, 0, null, 1, IMF_DATE1)
             , decode(managed_info.DATE2.managed, 0, null, 1, IMF_DATE2)
             , decode(managed_info.DATE3.managed, 0, null, 1, IMF_DATE3)
             , decode(managed_info.DATE4.managed, 0, null, 1, IMF_DATE4)
             , decode(managed_info.DATE5.managed, 0, null, 1, IMF_DATE5)
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE1_ID)
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE2_ID)
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE3_ID)
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE4_ID)
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE5_ID)
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.GCO_GOOD_ID)
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DOC_RECORD_ID)
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.HRM_PERSON_ID)
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.PAC_PERSON_ID)
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed
                    , 0, null
                    , 1, ACI_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID
                     )
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed
                    , 0, null
                    , 1, ACI_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP
                     )
             , sign(IMF_AMOUNT_LC_C)
             , sign(IMF_AMOUNT_LC_D)
             , IMM_TYPE
             , IMM_GENRE
             , IMM_PRIMARY
             , nvl(IMM_EXCHANGE_RATE, 0)
             , nvl(IMM_BASE_PRICE, 0)
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
             , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , ACI_MGM_IMPUTATION.ACS_PERIOD_ID
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1)
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2)
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3)
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4)
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5)
             , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1)
             , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2)
             , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3)
             , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4)
             , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5)
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER)
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2)
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3)
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4)
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5)
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE1_ID)
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE2_ID)
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE3_ID)
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE4_ID)
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE5_ID)
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.DOC_RECORD_ID)
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.GCO_GOOD_ID)
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.HRM_PERSON_ID)
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.PAC_PERSON_ID)
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID)
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, ACI_MGM_IMPUTATION.C_FAM_TRANSACTION_TYP)
      order by max(ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID);

    fin_imputation_tuple   fin_imputation%rowtype;
    imf_descr              ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    new_mgm_imp_id         ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    new_financial_imp_id   ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    new_financial_imp_id2  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    new_fin_imp_nonded_id  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vat_amount_lc_d        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_amount_lc_c        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_amount_fc_d        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_fc_c        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_eur_d       ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_eur_c       ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_vc_d        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_amount_vc_c        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_tot_amount_lc_d    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_tot_amount_lc_c    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_tot_amount_fc_d    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_tot_amount_fc_c    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_tot_amount_vc_d    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_tot_amount_vc_c    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    amount_lc_d            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
    amount_lc_c            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type               default 0;
    amount_fc_d            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    amount_fc_c            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    amount_eur_d           ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    amount_eur_c           ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    mgm_amount_fc_d        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type                     default 0;
    mgm_amount_fc_c        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type                     default 0;
    mgm_amount_eur_d       ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type                     default 0;
    mgm_amount_eur_c       ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type                     default 0;
    tax_col_fin_account_id ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    es_calc_sheet          ACS_TAX_CODE.C_ESTABLISHING_CALC_SHEET%type;
    prea_account_id        ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    prov_account_id        ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    fin_nonded_acc_id      ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    sign_liabled           number(1);
    lang_id                PCS.PC_LANG.PC_LANG_ID%type;
    exchangeRate           ACI_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    basePrice              ACI_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    roundCurrency          ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type;
    NewFinImp              boolean;
    lastFinImpId           ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type   := 0;
    description_vat        ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    description_vat_nonded ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    InfoImputationManaged  ACT_IMP_MANAGEMENT.InfoImputationRecType;
    IInfoImputationManaged ACT_IMP_MANAGEMENT.IInfoImputationRecType;
    encashment             boolean;
    vOldValues             ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vNewValues             ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vACS_CPN_ACCOUNT_ID    ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type;
    MGMImput               ACT_MGM_IMPUTATION%rowtype;
    ded_amount_lc_d        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
    ded_amount_lc_c        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type               default 0;
    ded_amount_fc_d        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    ded_amount_fc_c        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    ded_amount_eur_d       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    ded_amount_eur_c       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    ded_financial_currency_id ACI_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- recherche des info géreé pour le catalogue et conversion des boolean en integer pour la commande SQL
    InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
    ACT_IMP_MANAGEMENT.ConvertManagedValuesToInt(InfoImputationManaged, IInfoImputationManaged);

    -- ouverture du curseur sur les imputations financières
    open fin_imputation(document_id, IInfoImputationManaged.primary, pos_zero);

    fetch fin_imputation
     into fin_imputation_tuple;

    -- si le document comprend des imputations financières
    if fin_imputation%found then
      -- recherche la descreiption de l'imputation primaire qui sera utilisée
      -- comme description de toutes les imputations cumulées
      select IMF_DESCRIPTION
        into imf_descr
        from ACI_FINANCIAL_IMPUTATION
       where ACI_DOCUMENT_ID = document_id
         and IMF_PRIMARY = 1;

      -- recherche de la langue du partenaire
      select nvl(min(A.PC_LANG_ID), PCS.PC_I_LIB_SESSION.GETCOMPLANGID)
        into lang_id
        from PAC_ADDRESS A
           , DIC_ADDRESS_TYPE B
           , ACT_PART_IMPUTATION C
       where C.ACT_DOCUMENT_ID = new_document_id
         and A.PAC_PERSON_ID = nvl(C.PAC_CUSTOM_PARTNER_ID, PAC_SUPPLIER_PARTNER_ID)
         and A.DIC_ADDRESS_TYPE_ID = B.DIC_ADDRESS_TYPE_ID
         and DAD_DEFAULT = 1;

      -- initialisation de la description pour la TVA
      description_vat         :=
                         replace(PCS.PC_FUNCTIONS.TranslateWord2('TVA sur DOCNUMBER', Lang_id), 'DOCNUMBER', doc_number);
      description_vat_nonded  := description_vat || ' ' || PCS.PC_FUNCTIONS.TranslateWord2('(non déductible)', Lang_id);

      -- pour toutes les imputations financières
      while fin_imputation%found loop
        -- nouvelle imputation financière ou même imputation ?
        NewFinImp               := lastFinImpId != fin_imputation_tuple.ACI_FINANCIAL_IMPUTATION_ID;
        lastFinImpId            := fin_imputation_tuple.ACI_FINANCIAL_IMPUTATION_ID;

        -- message d'erreur s'il n'y a pas de compte financier valid dans l'interface
        if fin_imputation_tuple.acs_financial_account_id is null then
          raise_application_error
                             (-20001
                            , 'PCS - No valid financial account in the financial imputation interface. Document : ' ||
                              to_char(document_id)
                             );
        end if;

        -- message d'erreur s'il n'y a pas de période valide dans l'interface
        if fin_imputation_tuple.imf_period_id is null then
          raise_application_error(-20001, 'PCS - No valid financial period in the financial imputation interface');
        end if;

        -- valeur de retour afin de savoir si on a un document débit ou crédit
        if fin_imputation_tuple.imf_primary = 1 then
          if fin_imputation_tuple.IMF_AMOUNT_LC_C <> 0 then
            dc_type  := 'C';
          elsif fin_imputation_tuple.IMF_AMOUNT_LC_D <> 0 then
            dc_type  := 'D';
          else
            dc_type  := 'D';
          end if;
        end if;

        -- mise à jour des montants TVA
        if fin_imputation_tuple.acs_tax_code_id is not null then
          if fin_imputation_tuple.IMF_AMOUNT_LC_C <> 0 then
            vat_amount_lc_c      := fin_imputation_tuple.TAX_VAT_AMOUNT_LC;
            vat_amount_eur_c     := fin_imputation_tuple.TAX_VAT_AMOUNT_EUR;
            vat_tot_amount_lc_c  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_LC;

            if sign(vat_currency_id) = 1 then
              vat_amount_vc_c      := fin_imputation_tuple.TAX_VAT_AMOUNT_VC;
              vat_tot_amount_vc_c  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_VC;
            end if;

            if not fin_imputation_tuple.imf_financial_currency_id = fin_imputation_tuple.imf_imf_financial_currency_id then
              vat_amount_fc_c      := fin_imputation_tuple.TAX_VAT_AMOUNT_FC;
              vat_tot_amount_fc_c  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_FC;
            end if;
          else
            vat_amount_lc_d      := fin_imputation_tuple.TAX_VAT_AMOUNT_LC;
            vat_amount_eur_d     := fin_imputation_tuple.TAX_VAT_AMOUNT_EUR;
            vat_tot_amount_lc_d  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_LC;

            if sign(vat_currency_id) = 1 then
              vat_amount_vc_d      := fin_imputation_tuple.TAX_VAT_AMOUNT_VC;
              vat_tot_amount_vc_d  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_VC;
            end if;

            if not fin_imputation_tuple.imf_financial_currency_id = fin_imputation_tuple.imf_imf_financial_currency_id then
              vat_amount_fc_d      := fin_imputation_tuple.TAX_VAT_AMOUNT_FC;
              vat_tot_amount_fc_d  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_FC;
            end if;
          end if;
        end if;

        exchangeRate            := fin_imputation_tuple.IMF_EXCHANGE_RATE;
        basePrice               := fin_imputation_tuple.IMF_BASE_PRICE;

        if fin_imputation_tuple.imf_financial_currency_id != fin_imputation_tuple.imf_imf_financial_currency_id then
          declare
            vAmountLc number;
            vAmountFc number;
          begin
            if fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
              vAmountLc  :=
                (fin_imputation_tuple.IMF_AMOUNT_LC_D - vat_amount_lc_d) +
                (fin_imputation_tuple.IMF_AMOUNT_LC_C - vat_amount_lc_c
                );
              vAmountFc  :=
                (fin_imputation_tuple.IMF_AMOUNT_FC_D - vat_amount_fc_d) +
                (fin_imputation_tuple.IMF_AMOUNT_FC_C - vat_amount_fc_c
                );
            else
              vAmountLc  := fin_imputation_tuple.IMF_AMOUNT_LC_D + fin_imputation_tuple.IMF_AMOUNT_LC_C;
              vAmountFc  := fin_imputation_tuple.IMF_AMOUNT_FC_D + fin_imputation_tuple.IMF_AMOUNT_FC_C;
            end if;

            --Màj du cours de change
            UpdateExchangeRate(vAmountLc
                             , vAmountFc
                             , fin_imputation_tuple.imf_financial_currency_id
                             , exchangeRate
                             , basePrice
                              );
          end;
        end if;

        if    (   fin_imputation_tuple.IMF_AMOUNT_LC_D <> 0
               or fin_imputation_tuple.IMF_AMOUNT_LC_C <> 0
               or fin_imputation_tuple.IMF_AMOUNT_FC_D <> 0
               or fin_imputation_tuple.IMF_AMOUNT_FC_C <> 0
              )
           or fin_imputation_tuple.IMF_PRIMARY = 1
           or pos_zero = 1 then
          if NewFinImp then
            -- recherche d'un id unique pour l'imputation que l'on va créer
            select init_id_seq.nextval
              into new_financial_imp_id
              from dual;

            -- Reprise de l'imputation pointée par le curseur.
            insert into ACT_FINANCIAL_IMPUTATION
                        (ACT_FINANCIAL_IMPUTATION_ID
                       , ACT_DOCUMENT_ID
                       , ACT_PART_IMPUTATION_ID
                       , ACS_PERIOD_ID
                       , ACS_FINANCIAL_ACCOUNT_ID
                       , IMF_TYPE
                       , IMF_PRIMARY
                       , IMF_DESCRIPTION
                       , IMF_AMOUNT_LC_D
                       , IMF_AMOUNT_LC_C
                       , IMF_EXCHANGE_RATE
                       , IMF_BASE_PRICE
                       , IMF_AMOUNT_FC_D
                       , IMF_AMOUNT_FC_C
                       , IMF_AMOUNT_EUR_D
                       , IMF_AMOUNT_EUR_C
                       , IMF_VALUE_DATE
                       , ACS_TAX_CODE_ID
                       , IMF_TRANSACTION_DATE
                       , ACS_AUXILIARY_ACCOUNT_ID
                       , IMF_GENRE
                       , ACS_FINANCIAL_CURRENCY_ID
                       , ACS_ACS_FINANCIAL_CURRENCY_ID
                       , C_GENRE_TRANSACTION
                       , IMF_NUMBER
                       , IMF_NUMBER2
                       , IMF_NUMBER3
                       , IMF_NUMBER4
                       , IMF_NUMBER5
                       , IMF_TEXT1
                       , IMF_TEXT2
                       , IMF_TEXT3
                       , IMF_TEXT4
                       , IMF_TEXT5
                       , IMF_DATE1
                       , IMF_DATE2
                       , IMF_DATE3
                       , IMF_DATE4
                       , IMF_DATE5
                       , DIC_IMP_FREE1_ID
                       , DIC_IMP_FREE2_ID
                       , DIC_IMP_FREE3_ID
                       , DIC_IMP_FREE4_ID
                       , DIC_IMP_FREE5_ID
                       , GCO_GOOD_ID
                       , DOC_RECORD_ID
                       , HRM_PERSON_ID
                       , PAC_PERSON_ID
                       , FAM_FIXED_ASSETS_ID
                       , C_FAM_TRANSACTION_TYP
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (new_financial_imp_id
                       , new_document_id
                       , new_part_imputation_id
                       , fin_imputation_tuple.imf_period_id
                       , fin_imputation_tuple.acs_financial_account_id
                       , fin_imputation_tuple.IMF_TYPE
                       , fin_imputation_tuple.IMF_PRIMARY
                       , imf_descr
                       , nvl(fin_imputation_tuple.IMF_AMOUNT_LC_D, 0) -
                         decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_lc_d, 0), 0)
                       , nvl(fin_imputation_tuple.IMF_AMOUNT_LC_C, 0) -
                         decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_lc_c, 0), 0)
                       , exchangeRate
                       , basePrice
                       , nvl(fin_imputation_tuple.IMF_AMOUNT_FC_D, 0) -
                         decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_fc_d, 0), 0)
                       , nvl(fin_imputation_tuple.IMF_AMOUNT_FC_C, 0) -
                         decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_fc_c, 0), 0)
                       , nvl(fin_imputation_tuple.IMF_AMOUNT_EUR_D, 0) -
                         decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_eur_d, 0), 0)
                       , nvl(fin_imputation_tuple.IMF_AMOUNT_EUR_C, 0) -
                         decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_eur_c, 0), 0)
                       , fin_imputation_tuple.IMF_VALUE_DATE
                       , fin_imputation_tuple.acs_tax_code_id
                       , fin_imputation_tuple.IMF_TRANSACTION_DATE
                       , fin_imputation_tuple.acs_auxiliary_account_id
                       , fin_imputation_tuple.IMF_GENRE
                       , fin_imputation_tuple.imf_financial_currency_id
                       , fin_imputation_tuple.imf_imf_financial_currency_id
                       , fin_imputation_tuple.C_GENRE_TRANSACTION
                       , fin_imputation_tuple.IMF_NUMBER
                       , fin_imputation_tuple.IMF_NUMBER2
                       , fin_imputation_tuple.IMF_NUMBER3
                       , fin_imputation_tuple.IMF_NUMBER4
                       , fin_imputation_tuple.IMF_NUMBER5
                       , fin_imputation_tuple.IMF_TEXT1
                       , fin_imputation_tuple.IMF_TEXT2
                       , fin_imputation_tuple.IMF_TEXT3
                       , fin_imputation_tuple.IMF_TEXT4
                       , fin_imputation_tuple.IMF_TEXT5
                       , fin_imputation_tuple.IMF_DATE1
                       , fin_imputation_tuple.IMF_DATE2
                       , fin_imputation_tuple.IMF_DATE3
                       , fin_imputation_tuple.IMF_DATE4
                       , fin_imputation_tuple.IMF_DATE5
                       , fin_imputation_tuple.DIC_IMP_FREE1_ID
                       , fin_imputation_tuple.DIC_IMP_FREE2_ID
                       , fin_imputation_tuple.DIC_IMP_FREE3_ID
                       , fin_imputation_tuple.DIC_IMP_FREE4_ID
                       , fin_imputation_tuple.DIC_IMP_FREE5_ID
                       , fin_imputation_tuple.GCO_GOOD_ID
                       , fin_imputation_tuple.DOC_RECORD_ID
                       , fin_imputation_tuple.HRM_PERSON_ID
                       , fin_imputation_tuple.PAC_PERSON_ID
                       , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                       , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );

            -- si on a un compte division, on crée la distribution financière
            if fin_imputation_tuple.acs_division_account_id is not null then
              if fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
                Recover_Fin_Distrib(new_financial_imp_id
                                  , imf_descr
                                  , fin_imputation_tuple.IMF_AMOUNT_LC_D - vat_amount_lc_d
                                  , fin_imputation_tuple.IMF_AMOUNT_FC_D - vat_amount_fc_d
                                  , fin_imputation_tuple.IMF_AMOUNT_EUR_D - vat_amount_eur_d
                                  , fin_imputation_tuple.IMF_AMOUNT_LC_C - vat_amount_lc_c
                                  , fin_imputation_tuple.IMF_AMOUNT_FC_C - vat_amount_fc_c
                                  , fin_imputation_tuple.IMF_AMOUNT_EUR_C - vat_amount_eur_c
                                  , fin_imputation_tuple.acs_division_account_id
                                   );
              else
                Recover_Fin_Distrib(new_financial_imp_id
                                  , imf_descr
                                  , fin_imputation_tuple.IMF_AMOUNT_LC_D
                                  , fin_imputation_tuple.IMF_AMOUNT_FC_D
                                  , fin_imputation_tuple.IMF_AMOUNT_EUR_D
                                  , fin_imputation_tuple.IMF_AMOUNT_LC_C
                                  , fin_imputation_tuple.IMF_AMOUNT_FC_C
                                  , fin_imputation_tuple.IMF_AMOUNT_EUR_C
                                  , fin_imputation_tuple.acs_division_account_id
                                   );
              end if;
            end if;
          end if;

          if fin_imputation_tuple.aci_mgm_imputation_id is not null then
            exchangeRate  := fin_imputation_tuple.IMM_EXCHANGE_RATE;
            basePrice     := fin_imputation_tuple.IMM_BASE_PRICE;

            if fin_imputation_tuple.imm_financial_currency_id != fin_imputation_tuple.imm_imm_financial_currency_id then
              --Màj du cours de change
              UpdateExchangeRate( (fin_imputation_tuple.IMM_AMOUNT_LC_C + fin_imputation_tuple.IMM_AMOUNT_LC_D)
                               , (fin_imputation_tuple.IMM_AMOUNT_FC_C + fin_imputation_tuple.IMM_AMOUNT_FC_D)
                               , fin_imputation_tuple.imm_financial_currency_id
                               , exchangeRate
                               , basePrice
                                );
            end if;

            select init_id_seq.nextval
              into new_mgm_imp_id
              from dual;

            insert into ACT_MGM_IMPUTATION
                        (ACT_MGM_IMPUTATION_ID
                       , ACS_FINANCIAL_CURRENCY_ID
                       , ACS_ACS_FINANCIAL_CURRENCY_ID
                       , ACS_PERIOD_ID
                       , ACS_CPN_ACCOUNT_ID
                       , ACS_CDA_ACCOUNT_ID
                       , ACS_PF_ACCOUNT_ID
                       , ACT_DOCUMENT_ID
                       , ACT_FINANCIAL_IMPUTATION_ID
                       , IMM_TYPE
                       , IMM_GENRE
                       , IMM_PRIMARY
                       , IMM_DESCRIPTION
                       , IMM_AMOUNT_LC_D
                       , IMM_AMOUNT_LC_C
                       , IMM_EXCHANGE_RATE
                       , IMM_BASE_PRICE
                       , IMM_AMOUNT_FC_D
                       , IMM_AMOUNT_FC_C
                       , IMM_AMOUNT_EUR_D
                       , IMM_AMOUNT_EUR_C
                       , IMM_QUANTITY_D
                       , IMM_QUANTITY_C
                       , IMM_VALUE_DATE
                       , IMM_TRANSACTION_DATE
                       , ACS_QTY_UNIT_ID
                       , IMM_NUMBER
                       , IMM_NUMBER2
                       , IMM_NUMBER3
                       , IMM_NUMBER4
                       , IMM_NUMBER5
                       , IMM_TEXT1
                       , IMM_TEXT2
                       , IMM_TEXT3
                       , IMM_TEXT4
                       , IMM_TEXT5
                       , IMM_DATE1
                       , IMM_DATE2
                       , IMM_DATE3
                       , IMM_DATE4
                       , IMM_DATE5
                       , DIC_IMP_FREE1_ID
                       , DIC_IMP_FREE2_ID
                       , DIC_IMP_FREE3_ID
                       , DIC_IMP_FREE4_ID
                       , DIC_IMP_FREE5_ID
                       , GCO_GOOD_ID
                       , DOC_RECORD_ID
                       , HRM_PERSON_ID
                       , PAC_PERSON_ID
                       , FAM_FIXED_ASSETS_ID
                       , C_FAM_TRANSACTION_TYP
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (new_mgm_imp_id
                       , fin_imputation_tuple.imm_financial_currency_id
                       , fin_imputation_tuple.imm_imm_financial_currency_id
                       , fin_imputation_tuple.imm_period_id
                       , fin_imputation_tuple.acs_cpn_account_id
                       , fin_imputation_tuple.acs_cda_account_id
                       , fin_imputation_tuple.acs_pf_account_id
                       , new_document_id
                       , new_financial_imp_id
                       , fin_imputation_tuple.IMM_TYPE
                       , fin_imputation_tuple.IMM_GENRE
                       , fin_imputation_tuple.IMM_PRIMARY
                       , imf_descr
                       , nvl(fin_imputation_tuple.IMM_AMOUNT_LC_D, 0)
                       , nvl(fin_imputation_tuple.IMM_AMOUNT_LC_C, 0)
                       , exchangeRate
                       , basePrice
                       , nvl(fin_imputation_tuple.IMM_AMOUNT_FC_D, 0)
                       , nvl(fin_imputation_tuple.IMM_AMOUNT_FC_C, 0)
                       , nvl(fin_imputation_tuple.IMM_AMOUNT_EUR_D, 0)
                       , nvl(fin_imputation_tuple.IMM_AMOUNT_EUR_C, 0)
                       , nvl(fin_imputation_tuple.IMM_QUANTITY_D, 0)
                       , nvl(fin_imputation_tuple.IMM_QUANTITY_C, 0)
                       , fin_imputation_tuple.IMM_VALUE_DATE
                       , fin_imputation_tuple.IMM_TRANSACTION_DATE
                       , fin_imputation_tuple.ACS_QTY_UNIT_ID
                       , fin_imputation_tuple.IMM_NUMBER
                       , fin_imputation_tuple.IMM_NUMBER2
                       , fin_imputation_tuple.IMM_NUMBER3
                       , fin_imputation_tuple.IMM_NUMBER4
                       , fin_imputation_tuple.IMM_NUMBER5
                       , fin_imputation_tuple.IMM_TEXT1
                       , fin_imputation_tuple.IMM_TEXT2
                       , fin_imputation_tuple.IMM_TEXT3
                       , fin_imputation_tuple.IMM_TEXT4
                       , fin_imputation_tuple.IMM_TEXT5
                       , fin_imputation_tuple.IMM_DATE1
                       , fin_imputation_tuple.IMM_DATE2
                       , fin_imputation_tuple.IMM_DATE3
                       , fin_imputation_tuple.IMM_DATE4
                       , fin_imputation_tuple.IMM_DATE5
                       , fin_imputation_tuple.IMM_DIC_IMP_FREE1_ID
                       , fin_imputation_tuple.IMM_DIC_IMP_FREE2_ID
                       , fin_imputation_tuple.IMM_DIC_IMP_FREE3_ID
                       , fin_imputation_tuple.IMM_DIC_IMP_FREE4_ID
                       , fin_imputation_tuple.IMM_DIC_IMP_FREE5_ID
                       , fin_imputation_tuple.IMM_GCO_GOOD_ID
                       , fin_imputation_tuple.IMM_DOC_RECORD_ID
                       , fin_imputation_tuple.IMM_HRM_PERSON_ID
                       , fin_imputation_tuple.IMM_PAC_PERSON_ID
                       , fin_imputation_tuple.IMM_FAM_FIXED_ASSETS_ID
                       , fin_imputation_tuple.IMM_C_FAM_TRANSACTION_TYP
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );

            -- si on a un compte projet, on crée la distribution financière
            if fin_imputation_tuple.acs_pj_account_id is not null then
              -- mise à jour des montants en monnaie étrangère si elle est utilisée
              if not fin_imputation_tuple.imm_financial_currency_id =
                                                                     fin_imputation_tuple.imm_imm_financial_currency_id then
                mgm_amount_fc_d  := fin_imputation_tuple.IMM_AMOUNT_FC_D;
                mgm_amount_fc_c  := fin_imputation_tuple.IMM_AMOUNT_FC_C;
              end if;

              Recover_Mgm_Distrib(new_mgm_imp_id
                                , imf_descr
                                , fin_imputation_tuple.IMM_AMOUNT_LC_D
                                , mgm_amount_fc_d
                                , fin_imputation_tuple.IMM_AMOUNT_EUR_D
                                , fin_imputation_tuple.IMM_AMOUNT_LC_C
                                , mgm_amount_fc_c
                                , fin_imputation_tuple.IMM_AMOUNT_EUR_C
                                , fin_imputation_tuple.IMM_QUANTITY_D
                                , fin_imputation_tuple.IMM_QUANTITY_C
                                , fin_imputation_tuple.IMM_TEXT1
                                , fin_imputation_tuple.IMM_TEXT2
                                , fin_imputation_tuple.IMM_TEXT3
                                , fin_imputation_tuple.IMM_TEXT4
                                , fin_imputation_tuple.IMM_TEXT5
                                , fin_imputation_tuple.IMM_DATE1
                                , fin_imputation_tuple.IMM_DATE2
                                , fin_imputation_tuple.IMM_DATE3
                                , fin_imputation_tuple.IMM_DATE4
                                , fin_imputation_tuple.IMM_DATE5
                                , fin_imputation_tuple.IMM_NUMBER
                                , fin_imputation_tuple.IMM_NUMBER2
                                , fin_imputation_tuple.IMM_NUMBER3
                                , fin_imputation_tuple.IMM_NUMBER4
                                , fin_imputation_tuple.IMM_NUMBER5
                                , fin_imputation_tuple.acs_pj_account_id
                                 );
            end if;
          end if;
        else
          NewFinImp  := false;
        end if;

        if NewFinImp then
          -- s'il y a de la TVA sur l'imputation
          if fin_imputation_tuple.acs_tax_code_id is not null then
            if fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
              -- recherche du compte financier d'imputation de la TVA
              select C_ESTABLISHING_CALC_SHEET
                   , ACS_PREA_ACCOUNT_ID
                   , ACS_PROV_ACCOUNT_ID
                into es_calc_sheet
                   , prea_account_id
                   , prov_account_id
                from ACS_TAX_CODE
               where ACS_TAX_CODE_ID = fin_imputation_tuple.acs_tax_code_id;

              encashment := False;
              if es_calc_sheet = '1' then
                tax_col_fin_account_id  := prea_account_id;
              elsif es_calc_sheet = '2' then
                tax_col_fin_account_id  := prov_account_id;
                encashment := nvl(PCS.PC_CONFIG.GetConfigUpper('ACT_TAX_VAT_ENCASHMENT'), 'FALSE') = 'TRUE';
              end if;

              if encashment or (abs(vat_amount_lc_d) + abs(vat_amount_lc_c)) > 0 then
                -- recherche d'un id unique pour l'imputation que l'on va créer
                select init_id_seq.nextval
                  into new_financial_imp_id2
                  from dual;

                if tax_col_fin_account_id is null then
                  raise_application_error(-20003, 'PCS - No financial account in the tax code definition');
                end if;

                if    encashment
                   or vat_amount_lc_d <> 0
                   or vat_amount_lc_c <> 0
                   or vat_amount_fc_d <> 0
                   or vat_amount_fc_c <> 0 then
                  -- Reprise de l'imputation pointée par le curseur.
                  insert into ACT_FINANCIAL_IMPUTATION
                              (ACT_FINANCIAL_IMPUTATION_ID
                             , ACT_DOCUMENT_ID
                             , ACT_PART_IMPUTATION_ID
                             , ACS_PERIOD_ID
                             , ACS_FINANCIAL_ACCOUNT_ID
                             , IMF_TYPE
                             , IMF_PRIMARY
                             , IMF_DESCRIPTION
                             , IMF_AMOUNT_LC_D
                             , IMF_AMOUNT_LC_C
                             , IMF_EXCHANGE_RATE
                             , IMF_BASE_PRICE
                             , IMF_AMOUNT_FC_D
                             , IMF_AMOUNT_FC_C
                             , IMF_AMOUNT_EUR_D
                             , IMF_AMOUNT_EUR_C
                             , IMF_VALUE_DATE
                             , IMF_TRANSACTION_DATE
                             , ACS_AUXILIARY_ACCOUNT_ID
                             ,
                               -- ACT_DET_PAYMENT_ID,
                               IMF_GENRE
                             , ACS_FINANCIAL_CURRENCY_ID
                             , ACS_ACS_FINANCIAL_CURRENCY_ID
                             , C_GENRE_TRANSACTION
                             , IMF_NUMBER
                             , IMF_NUMBER2
                             , IMF_NUMBER3
                             , IMF_NUMBER4
                             , IMF_NUMBER5
                             , IMF_TEXT1
                             , IMF_TEXT2
                             , IMF_TEXT3
                             , IMF_TEXT4
                             , IMF_TEXT5
                             , IMF_DATE1
                             , IMF_DATE2
                             , IMF_DATE3
                             , IMF_DATE4
                             , IMF_DATE5
                             , DIC_IMP_FREE1_ID
                             , DIC_IMP_FREE2_ID
                             , DIC_IMP_FREE3_ID
                             , DIC_IMP_FREE4_ID
                             , DIC_IMP_FREE5_ID
                             , GCO_GOOD_ID
                             , DOC_RECORD_ID
                             , HRM_PERSON_ID
                             , PAC_PERSON_ID
                             , FAM_FIXED_ASSETS_ID
                             , C_FAM_TRANSACTION_TYP
                             , A_DATECRE
                             , A_IDCRE
                              )
                       values (new_financial_imp_id2
                             , new_document_id
                             , new_part_imputation_id
                             , fin_imputation_tuple.imf_period_id
                             , tax_col_fin_account_id
                             , 'VAT'
                             , fin_imputation_tuple.IMF_PRIMARY
                             ,
                               -- imf_descr,
                               description_vat
                             , nvl(vat_amount_lc_d, 0)
                             , nvl(vat_amount_lc_c, 0)
                             , fin_imputation_tuple.TAX_EXCHANGE_RATE
                             , fin_imputation_tuple.DET_BASE_PRICE
                             , decode(sign(vat_currency_id), 1, nvl(vat_amount_vc_d, 0), nvl(vat_amount_fc_d, 0))
                             , decode(sign(vat_currency_id), 1, nvl(vat_amount_vc_c, 0), nvl(vat_amount_fc_c, 0))
                             , nvl(vat_amount_eur_d, 0)
                             , nvl(vat_amount_eur_c, 0)
                             , fin_imputation_tuple.IMF_VALUE_DATE
                             , fin_imputation_tuple.IMF_TRANSACTION_DATE
                             , fin_imputation_tuple.acs_auxiliary_account_id
                             ,
                               -- fin_imputation_tuple.ACT_DET_PAYMENT_ID,
                               fin_imputation_tuple.IMF_GENRE
                             , decode(sign(vat_currency_id)
                                    , 1, vat_currency_id
                                    , fin_imputation_tuple.imf_financial_currency_id
                                     )
                             , fin_imputation_tuple.imf_imf_financial_currency_id
                             , fin_imputation_tuple.C_GENRE_TRANSACTION
                             , fin_imputation_tuple.IMF_NUMBER
                             , fin_imputation_tuple.IMF_NUMBER2
                             , fin_imputation_tuple.IMF_NUMBER3
                             , fin_imputation_tuple.IMF_NUMBER4
                             , fin_imputation_tuple.IMF_NUMBER5
                             , fin_imputation_tuple.IMF_TEXT1
                             , fin_imputation_tuple.IMF_TEXT2
                             , fin_imputation_tuple.IMF_TEXT3
                             , fin_imputation_tuple.IMF_TEXT4
                             , fin_imputation_tuple.IMF_TEXT5
                             , fin_imputation_tuple.IMF_DATE1
                             , fin_imputation_tuple.IMF_DATE2
                             , fin_imputation_tuple.IMF_DATE3
                             , fin_imputation_tuple.IMF_DATE4
                             , fin_imputation_tuple.IMF_DATE5
                             , fin_imputation_tuple.DIC_IMP_FREE1_ID
                             , fin_imputation_tuple.DIC_IMP_FREE2_ID
                             , fin_imputation_tuple.DIC_IMP_FREE3_ID
                             , fin_imputation_tuple.DIC_IMP_FREE4_ID
                             , fin_imputation_tuple.DIC_IMP_FREE5_ID
                             , fin_imputation_tuple.GCO_GOOD_ID
                             , fin_imputation_tuple.DOC_RECORD_ID
                             , fin_imputation_tuple.HRM_PERSON_ID
                             , fin_imputation_tuple.PAC_PERSON_ID
                             , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                             , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                             , sysdate
                             , PCS.PC_I_LIB_SESSION.GetUserIni
                              );

                  if fin_imputation_tuple.acs_division_account_id is not null then
                    if sign(vat_currency_id) = 1 then
                      Recover_Fin_Distrib
                                     (new_financial_imp_id2
                                    , description_vat
                                    , vat_amount_lc_d
                                    , vat_amount_vc_d
                                    , vat_amount_eur_d
                                    , vat_amount_lc_c
                                    , vat_amount_vc_c
                                    , vat_amount_eur_c
                                    , ACS_FUNCTION.GetDivisionOfAccount(tax_col_fin_account_id
                                                                      , fin_imputation_tuple.acs_division_account_id
                                                                      , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                                                       )
                                     );
                    else
                      Recover_Fin_Distrib
                                     (new_financial_imp_id2
                                    , description_vat
                                    , vat_amount_lc_d
                                    , vat_amount_fc_d
                                    , vat_amount_eur_d
                                    , vat_amount_lc_c
                                    , vat_amount_fc_c
                                    , vat_amount_eur_c
                                    , ACS_FUNCTION.GetDivisionOfAccount(tax_col_fin_account_id
                                                                      , fin_imputation_tuple.acs_division_account_id
                                                                      , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                                                       )
                                     );
                    end if;
                  end if;
                end if;
              end if;

              if fin_imputation_tuple.TAX_DEDUCTIBLE_RATE <> 100 then
                ded_amount_lc_d := nvl(vat_tot_amount_lc_d, 0) - nvl(vat_amount_lc_d, 0);
                ded_amount_lc_c := nvl(vat_tot_amount_lc_c, 0) - nvl(vat_amount_lc_c, 0);

                if sign(vat_currency_id) =  1 then
                  ded_amount_fc_d := nvl(vat_tot_amount_vc_d, 0) - nvl(vat_amount_vc_d, 0);
                  ded_amount_fc_c := nvl(vat_tot_amount_vc_c, 0) - nvl(vat_amount_vc_c, 0);
                  ded_financial_currency_id     := vat_currency_id;
                else
                  ded_amount_fc_d := nvl(vat_tot_amount_fc_d, 0) - nvl(vat_amount_vc_d, 0);
                  ded_amount_fc_c := nvl(vat_tot_amount_fc_c, 0) - nvl(vat_amount_fc_c, 0);
                  ded_financial_currency_id     := fin_imputation_tuple.imf_financial_currency_id;
                end if;

                ded_amount_eur_d := null;
                ded_amount_eur_c := null;

                select nvl(ACS_NONDED_ACCOUNT_ID, fin_imputation_tuple.acs_financial_account_id)
                  into fin_nonded_acc_id
                  from ACS_TAX_CODE
                 where ACS_TAX_CODE_ID = fin_imputation_tuple.acs_tax_code_id;

                -- recherche d'un id unique pour l'imputation que l'on va créer
                select init_id_seq.nextval
                  into new_fin_imp_nonded_id
                  from dual;

                insert into ACT_FINANCIAL_IMPUTATION
                            (ACT_FINANCIAL_IMPUTATION_ID
                           , ACT_DOCUMENT_ID
                           , ACT_PART_IMPUTATION_ID
                           , ACS_PERIOD_ID
                           , ACS_FINANCIAL_ACCOUNT_ID
                           , IMF_TYPE
                           , IMF_PRIMARY
                           , IMF_DESCRIPTION
                           , IMF_AMOUNT_LC_D
                           , IMF_AMOUNT_LC_C
                           , IMF_EXCHANGE_RATE
                           , IMF_BASE_PRICE
                           , IMF_AMOUNT_FC_D
                           , IMF_AMOUNT_FC_C
                           , IMF_AMOUNT_EUR_D
                           , IMF_AMOUNT_EUR_C
                           , IMF_VALUE_DATE
                           , IMF_TRANSACTION_DATE
                           , ACS_AUXILIARY_ACCOUNT_ID
                           ,
                             -- ACT_DET_PAYMENT_ID,
                             IMF_GENRE
                           , ACS_FINANCIAL_CURRENCY_ID
                           , ACS_ACS_FINANCIAL_CURRENCY_ID
                           , C_GENRE_TRANSACTION
                           , IMF_NUMBER
                           , IMF_NUMBER2
                           , IMF_NUMBER3
                           , IMF_NUMBER4
                           , IMF_NUMBER5
                           , IMF_TEXT1
                           , IMF_TEXT2
                           , IMF_TEXT3
                           , IMF_TEXT4
                           , IMF_TEXT5
                           , IMF_DATE1
                           , IMF_DATE2
                           , IMF_DATE3
                           , IMF_DATE4
                           , IMF_DATE5
                           , DIC_IMP_FREE1_ID
                           , DIC_IMP_FREE2_ID
                           , DIC_IMP_FREE3_ID
                           , DIC_IMP_FREE4_ID
                           , DIC_IMP_FREE5_ID
                           , GCO_GOOD_ID
                           , DOC_RECORD_ID
                           , HRM_PERSON_ID
                           , PAC_PERSON_ID
                           , FAM_FIXED_ASSETS_ID
                           , C_FAM_TRANSACTION_TYP
                           , A_DATECRE
                           , A_IDCRE
                            )
                     values (new_fin_imp_nonded_id
                           , new_document_id
                           , new_part_imputation_id
                           , fin_imputation_tuple.imf_period_id
                           , fin_nonded_acc_id
                           , 'MAN'
                           , fin_imputation_tuple.IMF_PRIMARY
                           , description_vat_nonded
                           , ded_amount_lc_d
                           , ded_amount_lc_c
                           , fin_imputation_tuple.TAX_EXCHANGE_RATE
                           , fin_imputation_tuple.DET_BASE_PRICE
                           , ded_amount_fc_d
                           , ded_amount_fc_c
                           , ded_amount_eur_d
                           , ded_amount_eur_c
                           , fin_imputation_tuple.IMF_VALUE_DATE
                           , fin_imputation_tuple.IMF_TRANSACTION_DATE
                           , fin_imputation_tuple.acs_auxiliary_account_id
                           ,
                             -- fin_imputation_tuple.ACT_DET_PAYMENT_ID,
                             fin_imputation_tuple.IMF_GENRE
                           , ded_financial_currency_id
                           , fin_imputation_tuple.imf_imf_financial_currency_id
                           , '1'
                           , fin_imputation_tuple.IMF_NUMBER
                           , fin_imputation_tuple.IMF_NUMBER2
                           , fin_imputation_tuple.IMF_NUMBER3
                           , fin_imputation_tuple.IMF_NUMBER4
                           , fin_imputation_tuple.IMF_NUMBER5
                           , fin_imputation_tuple.IMF_TEXT1
                           , fin_imputation_tuple.IMF_TEXT2
                           , fin_imputation_tuple.IMF_TEXT3
                           , fin_imputation_tuple.IMF_TEXT4
                           , fin_imputation_tuple.IMF_TEXT5
                           , fin_imputation_tuple.IMF_DATE1
                           , fin_imputation_tuple.IMF_DATE2
                           , fin_imputation_tuple.IMF_DATE3
                           , fin_imputation_tuple.IMF_DATE4
                           , fin_imputation_tuple.IMF_DATE5
                           , fin_imputation_tuple.DIC_IMP_FREE1_ID
                           , fin_imputation_tuple.DIC_IMP_FREE2_ID
                           , fin_imputation_tuple.DIC_IMP_FREE3_ID
                           , fin_imputation_tuple.DIC_IMP_FREE4_ID
                           , fin_imputation_tuple.DIC_IMP_FREE5_ID
                           , fin_imputation_tuple.GCO_GOOD_ID
                           , fin_imputation_tuple.DOC_RECORD_ID
                           , fin_imputation_tuple.HRM_PERSON_ID
                           , fin_imputation_tuple.PAC_PERSON_ID
                           , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                           , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                           , sysdate
                           , PCS.PC_I_LIB_SESSION.GetUserIni
                            );

                if fin_imputation_tuple.acs_division_account_id is not null then
                  Recover_Fin_Distrib
                                   (new_fin_imp_nonded_id
                                  , description_vat_nonded
                                  , ded_amount_lc_d
                                  , ded_amount_fc_d
                                  , null
                                  , ded_amount_lc_c
                                  , ded_amount_fc_c
                                  , null
                                  , ACS_FUNCTION.GetDivisionOfAccount(fin_nonded_acc_id
                                                                    , fin_imputation_tuple.acs_division_account_id
                                                                    , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                                                     )
                                   );
                end if;
                if new_mgm_imp_id is not null then
                  if fin_nonded_acc_id = fin_imputation_tuple.acs_financial_account_id then
                    MGMImput := null;

                    MGMImput.IMM_AMOUNT_LC_D  := ded_amount_lc_d;
                    MGMImput.IMM_AMOUNT_LC_C  := ded_amount_lc_c;
                    MGMImput.IMM_AMOUNT_FC_D  := ded_amount_fc_d;
                    MGMImput.IMM_AMOUNT_EUR_D := ded_amount_eur_d;
                    MGMImput.IMM_AMOUNT_FC_C  := ded_amount_fc_c;
                    MGMImput.IMM_AMOUNT_EUR_C := ded_amount_eur_c;

                    MGMImput.ACS_FINANCIAL_CURRENCY_ID     := ded_financial_currency_id;
                    MGMImput.ACS_ACS_FINANCIAL_CURRENCY_ID := fin_imputation_tuple.imf_imf_financial_currency_id;

                    MGMImput.IMM_EXCHANGE_RATE := fin_imputation_tuple.TAX_EXCHANGE_RATE;
                    MGMImput.IMM_BASE_PRICE    := fin_imputation_tuple.DET_BASE_PRICE;

                    MGMImput.IMM_DESCRIPTION := description_vat_nonded;
                    MGMImput.IMM_TYPE := 'MAN';

                    CreateImputationForVAT(new_fin_imp_nonded_id, new_financial_imp_id, MGMImput);
                  else
                    vACS_CPN_ACCOUNT_ID := ACS_FUNCTION.GetCpnOfFinAcc(fin_nonded_acc_id);

                    if vACS_CPN_ACCOUNT_ID is not null then

                      select min(ACS_CDA_ACCOUNT_ID)
                           , min(ACS_PF_ACCOUNT_ID)
                           , min(ACS_PJ_ACCOUNT_ID)
                        into vOldValues.CDAAccId
                           , vOldValues.PFAccId
                           , vOldValues.PJAccId
                        from (select IMP.ACS_CDA_ACCOUNT_ID
                                   , IMP.ACS_PF_ACCOUNT_ID
                                   , DIST.ACS_PJ_ACCOUNT_ID
                                from ACT_MGM_DISTRIBUTION DIST
                                   , ACT_MGM_IMPUTATION IMP
                               where IMP.ACT_FINANCIAL_IMPUTATION_ID = new_financial_imp_id
                                 and IMP.ACT_MGM_IMPUTATION_ID = DIST.ACT_MGM_IMPUTATION_ID(+)
                                 and rownum = 1);

                      declare
                        vTest Boolean;
                      begin
                        vTest := ACT_MGM_MANAGEMENT.ReInitialize(vACS_CPN_ACCOUNT_ID, fin_imputation_tuple.IMF_TRANSACTION_DATE, vOldValues, vNewValues);
                      end;

                      select init_id_seq.nextval
                        into new_mgm_imp_id
                        from dual;

                      insert into ACT_MGM_IMPUTATION
                                  (ACT_MGM_IMPUTATION_ID
                                 , ACS_FINANCIAL_CURRENCY_ID
                                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                                 , ACS_PERIOD_ID
                                 , ACS_CPN_ACCOUNT_ID
                                 , ACS_CDA_ACCOUNT_ID
                                 , ACS_PF_ACCOUNT_ID
                                 , ACT_DOCUMENT_ID
                                 , ACT_FINANCIAL_IMPUTATION_ID
                                 , IMM_TYPE
                                 , IMM_GENRE
                                 , IMM_PRIMARY
                                 , IMM_DESCRIPTION
                                 , IMM_AMOUNT_LC_D
                                 , IMM_AMOUNT_LC_C
                                 , IMM_EXCHANGE_RATE
                                 , IMM_BASE_PRICE
                                 , IMM_AMOUNT_FC_D
                                 , IMM_AMOUNT_FC_C
                                 , IMM_AMOUNT_EUR_D
                                 , IMM_AMOUNT_EUR_C
                                 , IMM_QUANTITY_D
                                 , IMM_QUANTITY_C
                                 , IMM_VALUE_DATE
                                 , IMM_TRANSACTION_DATE
                                 , ACS_QTY_UNIT_ID
                                 , IMM_TEXT1
                                 , IMM_TEXT2
                                 , IMM_TEXT3
                                 , IMM_TEXT4
                                 , IMM_TEXT5
                                 , IMM_DATE1
                                 , IMM_DATE2
                                 , IMM_DATE3
                                 , IMM_DATE4
                                 , IMM_DATE5
                                 , IMM_NUMBER
                                 , IMM_NUMBER2
                                 , IMM_NUMBER3
                                 , IMM_NUMBER4
                                 , IMM_NUMBER5
                                 , DIC_IMP_FREE1_ID
                                 , DIC_IMP_FREE2_ID
                                 , DIC_IMP_FREE3_ID
                                 , DIC_IMP_FREE4_ID
                                 , DIC_IMP_FREE5_ID
                                 , DOC_RECORD_ID
                                 , GCO_GOOD_ID
                                 , HRM_PERSON_ID
                                 , PAC_PERSON_ID
                                 , FAM_FIXED_ASSETS_ID
                                 , C_FAM_TRANSACTION_TYP
                                 , A_DATECRE
                                 , A_IDCRE
                                  )
                           values (new_mgm_imp_id
                                 , ded_financial_currency_id
                                 , fin_imputation_tuple.imf_imf_financial_currency_id
                                 , fin_imputation_tuple.imf_period_id
                                 , vACS_CPN_ACCOUNT_ID
                                 , vNewValues.CDAAccId
                                 , vNewValues.PFAccId
                                 , new_document_id
                                 , new_fin_imp_nonded_id
                                 , 'MAN'
                                 , fin_imputation_tuple.IMF_GENRE
                                 , fin_imputation_tuple.IMF_PRIMARY
                                 , description_vat_nonded
                                 , ded_amount_lc_d
                                 , ded_amount_lc_c
                                 , fin_imputation_tuple.TAX_EXCHANGE_RATE
                                 , fin_imputation_tuple.DET_BASE_PRICE
                                 , ded_amount_fc_d
                                 , ded_amount_fc_c
                                 , ded_amount_eur_d
                                 , ded_amount_eur_c
                                 , 0
                                 , 0
                                 , fin_imputation_tuple.IMF_VALUE_DATE
                                 , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                 , ACT_CREATION_SBVR.GetQTYAccountIdOfCPN(vACS_CPN_ACCOUNT_ID)
                                 , fin_imputation_tuple.IMF_TEXT1
                                 , fin_imputation_tuple.IMF_TEXT2
                                 , fin_imputation_tuple.IMF_TEXT3
                                 , fin_imputation_tuple.IMF_TEXT4
                                 , fin_imputation_tuple.IMF_TEXT5
                                 , fin_imputation_tuple.IMF_DATE1
                                 , fin_imputation_tuple.IMF_DATE2
                                 , fin_imputation_tuple.IMF_DATE3
                                 , fin_imputation_tuple.IMF_DATE4
                                 , fin_imputation_tuple.IMF_DATE5
                                 , fin_imputation_tuple.IMF_NUMBER
                                 , fin_imputation_tuple.IMF_NUMBER2
                                 , fin_imputation_tuple.IMF_NUMBER3
                                 , fin_imputation_tuple.IMF_NUMBER4
                                 , fin_imputation_tuple.IMF_NUMBER5
                                 , fin_imputation_tuple.DIC_IMP_FREE1_ID
                                 , fin_imputation_tuple.DIC_IMP_FREE2_ID
                                 , fin_imputation_tuple.DIC_IMP_FREE3_ID
                                 , fin_imputation_tuple.DIC_IMP_FREE4_ID
                                 , fin_imputation_tuple.DIC_IMP_FREE5_ID
                                 , fin_imputation_tuple.DOC_RECORD_ID
                                 , fin_imputation_tuple.GCO_GOOD_ID
                                 , fin_imputation_tuple.HRM_PERSON_ID
                                 , fin_imputation_tuple.PAC_PERSON_ID
                                 , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                                 , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                                 , sysdate
                                 , PCS.PC_I_LIB_SESSION.GetUserIni
                                  );

                      if vNewValues.PJAccId is not null then
                        Recover_Mgm_Distrib(new_mgm_imp_id
                                          , description_vat_nonded
                                          , ded_amount_lc_d
                                          , ded_amount_fc_d
                                          , ded_amount_eur_d
                                          , ded_amount_lc_c
                                          , ded_amount_fc_c
                                          , ded_amount_eur_c
                                          , 0
                                          , 0
                                          , fin_imputation_tuple.IMF_TEXT1
                                          , fin_imputation_tuple.IMF_TEXT2
                                          , fin_imputation_tuple.IMF_TEXT3
                                          , fin_imputation_tuple.IMF_TEXT4
                                          , fin_imputation_tuple.IMF_TEXT5
                                          , fin_imputation_tuple.IMF_DATE1
                                          , fin_imputation_tuple.IMF_DATE2
                                          , fin_imputation_tuple.IMF_DATE3
                                          , fin_imputation_tuple.IMF_DATE4
                                          , fin_imputation_tuple.IMF_DATE5
                                          , fin_imputation_tuple.IMF_NUMBER
                                          , fin_imputation_tuple.IMF_NUMBER2
                                          , fin_imputation_tuple.IMF_NUMBER3
                                          , fin_imputation_tuple.IMF_NUMBER4
                                          , fin_imputation_tuple.IMF_NUMBER5
                                          , vNewValues.PJAccId
                                           );
                      end if;
                    end if;
                  end if;
                end if;
              end if;
            end if;

            -- recherche du signe du montant soumis, celui-ci n'étant pas signé depuis la logistique
            if fin_imputation_tuple.IMF_AMOUNT_LC_D - fin_imputation_tuple.IMF_AMOUNT_LC_C = 0 then
              sign_liabled  := 1;
            else
              sign_liabled  := sign(fin_imputation_tuple.IMF_AMOUNT_LC_D - fin_imputation_tuple.IMF_AMOUNT_LC_C);
            end if;
            -- test du signe du montant soumis
            if sign(fin_imputation_tuple.TAX_LIABLED_AMOUNT) < 0 then
              sign_liabled  := sign_liabled * -1;
            end if;

            if new_financial_imp_id is not null then
              if sign(vat_currency_id) = 1 then
                Recover_Tax_Code(new_financial_imp_id
                               , new_financial_imp_id2
                               , fin_imputation_tuple.TAX_INCLUDED_EXCLUDED
                               , fin_imputation_tuple.TAX_EXCHANGE_RATE
                               , fin_imputation_tuple.TAX_LIABLED_AMOUNT * sign_liabled
                               , fin_imputation_tuple.TAX_LIABLED_RATE
                               , fin_imputation_tuple.TAX_RATE
                               , vat_amount_lc_d - vat_amount_lc_c
                               , vat_amount_vc_d - vat_amount_vc_c
                               , vat_amount_eur_d - vat_amount_eur_c
                               , vat_tot_amount_lc_d - vat_tot_amount_lc_c
                               , vat_tot_amount_vc_d - vat_tot_amount_vc_c
                               , null
                               , fin_imputation_tuple.TAX_DEDUCTIBLE_RATE
                               , new_fin_imp_nonded_id
                               , fin_imputation_tuple.ACS_TAX_CODE_ID
                               , fin_imputation_tuple.TAX_REDUCTION
                               , fin_imputation_tuple.DET_BASE_PRICE
                                );
              else
                Recover_Tax_Code(new_financial_imp_id
                               , new_financial_imp_id2
                               , fin_imputation_tuple.TAX_INCLUDED_EXCLUDED
                               , fin_imputation_tuple.TAX_EXCHANGE_RATE
                               , fin_imputation_tuple.TAX_LIABLED_AMOUNT * sign_liabled
                               , fin_imputation_tuple.TAX_LIABLED_RATE
                               , fin_imputation_tuple.TAX_RATE
                               , vat_amount_lc_d - vat_amount_lc_c
                               , vat_amount_fc_d - vat_amount_fc_c
                               , vat_amount_eur_d - vat_amount_eur_c
                               , vat_tot_amount_lc_d - vat_tot_amount_lc_c
                               , vat_tot_amount_fc_d - vat_tot_amount_fc_c
                               , null
                               , fin_imputation_tuple.TAX_DEDUCTIBLE_RATE
                               , new_fin_imp_nonded_id
                               , fin_imputation_tuple.ACS_TAX_CODE_ID
                               , fin_imputation_tuple.TAX_REDUCTION
                               , fin_imputation_tuple.DET_BASE_PRICE
                                );
              end if;
            end if;
          end if;

          -- Création des imputations d'autotaxation
          if     new_financial_imp_id is not null
             and fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'S'
             and not ACT_VAT_MANAGEMENT.CreateVAT_ACI(new_financial_imp_id) then
            raise_application_error(-20001, 'PCS - Problem with Self-Taxing');
          end if;
        end if;

        -- imputation suivante
        fetch fin_imputation
         into fin_imputation_tuple;

        -- remise à 0 des montants
        -- new_financial_imp_id := null;
        new_financial_imp_id2   := null;
        tax_col_fin_account_id  := null;
        amount_fc_c             := 0;
        amount_fc_d             := 0;
        amount_eur_c            := 0;
        amount_eur_d            := 0;
        vat_amount_lc_d         := 0;
        vat_amount_lc_c         := 0;
        vat_amount_fc_d         := 0;
        vat_amount_fc_c         := 0;
        vat_amount_eur_d        := 0;
        vat_amount_eur_c        := 0;
        vat_amount_vc_d         := 0;
        vat_amount_vc_c         := 0;
        vat_tot_amount_lc_c     := 0;
        vat_tot_amount_lc_d     := 0;
        vat_tot_amount_fc_c     := 0;
        vat_tot_amount_fc_d     := 0;
        vat_tot_amount_vc_d     := 0;
        vat_tot_amount_vc_c     := 0;
      end loop;
    end if;

    close fin_imputation;
  end Recover_Fin_Imp_Cumul;

  /**
  * Description
  *   reprise cumulée des imputations financières avec cumul débit-crédit
  */
  procedure Recover_Fin_Imp_Cumul_Group(
    document_id            in     number
  , new_document_id        in     number
  , new_part_imputation_id in     number
  , financial_year_id      in     number
  , vat_currency_id        in     number
  , pos_zero               in     number
  , catalogue_document_id  in     number
  , doc_number             in     varchar2
  , dc_type                out    varchar2
  )
  is
    cursor fin_imputation(document_id number, managed_info ACT_IMP_MANAGEMENT.IInfoImputationBaseRecType)
    is
      select   IMF_TYPE
             , IMF_GENRE
             , IMF_PRIMARY
             , sum(nvl(IMF_AMOUNT_LC_D, 0) - nvl(IMF_AMOUNT_LC_C, 0) ) IMF_AMOUNT_LC
             , nvl(IMF_EXCHANGE_RATE, 0) IMF_EXCHANGE_RATE
             , nvl(IMF_BASE_PRICE, 0) IMF_BASE_PRICE
             , sum(nvl(IMF_AMOUNT_FC_D, 0) - nvl(IMF_AMOUNT_FC_C, 0) ) IMF_AMOUNT_FC
             , sum(nvl(IMF_AMOUNT_EUR_D, 0) - nvl(IMF_AMOUNT_EUR_C, 0) ) IMF_AMOUNT_EUR
             , IMF_VALUE_DATE
             , IMF_TRANSACTION_DATE
             , nvl(TAX_EXCHANGE_RATE, 0) TAX_EXCHANGE_RATE
             , nvl(DET_BASE_PRICE, 0) DET_BASE_PRICE
             , TAX_INCLUDED_EXCLUDED
             , sum(nvl(TAX_LIABLED_AMOUNT, 0) * sign(nvl(IMF_AMOUNT_LC_D, 0) - nvl(IMF_AMOUNT_LC_C, 0) ) )
                                                                                                     TAX_LIABLED_AMOUNT
             , TAX_LIABLED_RATE
             , TAX_RATE
             , TAX_DEDUCTIBLE_RATE
             , abs(sum(decode(sign(abs(IMF_AMOUNT_FC_C) ), 1, nvl(TAX_VAT_AMOUNT_FC, 0), -nvl(TAX_VAT_AMOUNT_FC, 0) ) ) )
                                                                                                      TAX_VAT_AMOUNT_FC
             , abs(sum(decode(sign(abs(IMF_AMOUNT_LC_C) ), 1, nvl(TAX_VAT_AMOUNT_LC, 0), -nvl(TAX_VAT_AMOUNT_LC, 0) ) ) )
                                                                                                      TAX_VAT_AMOUNT_LC
             , abs(sum(decode(sign(abs(IMF_AMOUNT_EUR_C) ), 1, nvl(TAX_VAT_AMOUNT_EUR, 0), -nvl(TAX_VAT_AMOUNT_EUR, 0) ) )
                  ) TAX_VAT_AMOUNT_EUR
             , abs(sum(decode(sign(abs(IMF_AMOUNT_LC_C) ), 1, nvl(TAX_VAT_AMOUNT_VC, 0), -nvl(TAX_VAT_AMOUNT_VC, 0) ) ) )
                                                                                                      TAX_VAT_AMOUNT_VC
             , abs(sum(decode(sign(abs(IMF_AMOUNT_FC_C) )
                            , 1, nvl(TAX_TOT_VAT_AMOUNT_FC, 0)
                            , -nvl(TAX_TOT_VAT_AMOUNT_FC, 0)
                             )
                      )
                  ) TAX_TOT_VAT_AMOUNT_FC
             , abs(sum(decode(sign(abs(IMF_AMOUNT_LC_C) )
                            , 1, nvl(TAX_TOT_VAT_AMOUNT_LC, 0)
                            , -nvl(TAX_TOT_VAT_AMOUNT_LC, 0)
                             )
                      )
                  ) TAX_TOT_VAT_AMOUNT_LC
             , abs(sum(decode(sign(abs(IMF_AMOUNT_LC_C) )
                            , 1, nvl(TAX_TOT_VAT_AMOUNT_VC, 0)
                            , -nvl(TAX_TOT_VAT_AMOUNT_VC, 0)
                             )
                      )
                  ) TAX_TOT_VAT_AMOUNT_VC
             , TAX_REDUCTION
             , ACS_DIVISION_ACCOUNT_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMF_FINANCIAL_CURRENCY_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMF_IMF_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_AUXILIARY_ACCOUNT_ID
             , ACS_TAX_CODE_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_PERIOD_ID IMF_PERIOD_ID
             , C_GENRE_TRANSACTION
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMF_NUMBER) IMF_NUMBER
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMF_NUMBER2) IMF_NUMBER2
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMF_NUMBER3) IMF_NUMBER3
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMF_NUMBER4) IMF_NUMBER4
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMF_NUMBER5) IMF_NUMBER5
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMF_TEXT1) IMF_TEXT1
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMF_TEXT2) IMF_TEXT2
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMF_TEXT3) IMF_TEXT3
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMF_TEXT4) IMF_TEXT4
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMF_TEXT5) IMF_TEXT5
             , decode(managed_info.DATE1.managed, 0, null, 1, IMF_DATE1) IMF_DATE1
             , decode(managed_info.DATE2.managed, 0, null, 1, IMF_DATE2) IMF_DATE2
             , decode(managed_info.DATE3.managed, 0, null, 1, IMF_DATE3) IMF_DATE3
             , decode(managed_info.DATE4.managed, 0, null, 1, IMF_DATE4) IMF_DATE4
             , decode(managed_info.DATE5.managed, 0, null, 1, IMF_DATE5) IMF_DATE5
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE1_ID)
                                                                                                       DIC_IMP_FREE1_ID
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE2_ID)
                                                                                                       DIC_IMP_FREE2_ID
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE3_ID)
                                                                                                       DIC_IMP_FREE3_ID
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE4_ID)
                                                                                                       DIC_IMP_FREE4_ID
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE5_ID)
                                                                                                       DIC_IMP_FREE5_ID
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.GCO_GOOD_ID) GCO_GOOD_ID
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DOC_RECORD_ID)
                                                                                                          DOC_RECORD_ID
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.HRM_PERSON_ID)
                                                                                                          HRM_PERSON_ID
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.PAC_PERSON_ID)
                                                                                                          PAC_PERSON_ID
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed
                    , 0, null
                    , 1, ACI_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID
                     ) FAM_FIXED_ASSETS_ID
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed
                    , 0, null
                    , 1, ACI_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP
                     ) C_FAM_TRANSACTION_TYP
             , max(ACI_MGM_IMPUTATION_ID) ACI_MGM_IMPUTATION_ID
             , max(ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID) ACI_FINANCIAL_IMPUTATION_ID
             , IMM_TYPE
             , IMM_GENRE
             , IMM_PRIMARY
             , sum(nvl(IMM_AMOUNT_LC_D, 0) - nvl(IMM_AMOUNT_LC_C, 0) ) IMM_AMOUNT_LC
             , nvl(IMM_EXCHANGE_RATE, 0) IMM_EXCHANGE_RATE
             , nvl(IMM_BASE_PRICE, 0) IMM_BASE_PRICE
             , sum(nvl(IMM_AMOUNT_FC_D, 0) - nvl(IMM_AMOUNT_FC_C, 0) ) IMM_AMOUNT_FC
             , sum(nvl(IMM_AMOUNT_EUR_D, 0) - nvl(IMM_AMOUNT_EUR_C, 0) ) IMM_AMOUNT_EUR
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , sum(nvl(IMM_QUANTITY_D, 0) - nvl(IMM_QUANTITY_C, 0) ) IMM_QUANTITY
             , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMM_FINANCIAL_CURRENCY_ID
             , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMM_IMM_FINANCIAL_CURRENCY_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , ACI_MGM_IMPUTATION.ACS_PERIOD_ID IMM_PERIOD_ID
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER) IMM_NUMBER
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2) IMM_NUMBER2
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3) IMM_NUMBER3
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4) IMM_NUMBER4
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5) IMM_NUMBER5
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1) IMM_TEXT1
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2) IMM_TEXT2
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3) IMM_TEXT3
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4) IMM_TEXT4
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5) IMM_TEXT5
             , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1) IMM_DATE1
             , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2) IMM_DATE2
             , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3) IMM_DATE3
             , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4) IMM_DATE4
             , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5) IMM_DATE5
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE1_ID) IMM_DIC_IMP_FREE1_ID
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE2_ID) IMM_DIC_IMP_FREE2_ID
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE3_ID) IMM_DIC_IMP_FREE3_ID
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE4_ID) IMM_DIC_IMP_FREE4_ID
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE5_ID) IMM_DIC_IMP_FREE5_ID
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.DOC_RECORD_ID)
                                                                                                      IMM_DOC_RECORD_ID
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.GCO_GOOD_ID) IMM_GCO_GOOD_ID
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.HRM_PERSON_ID)
                                                                                                      IMM_HRM_PERSON_ID
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.PAC_PERSON_ID)
                                                                                                      IMM_PAC_PERSON_ID
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID)
                                                                                                IMM_FAM_FIXED_ASSETS_ID
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, ACI_MGM_IMPUTATION.C_FAM_TRANSACTION_TYP)
                                                                                              IMM_C_FAM_TRANSACTION_TYP
          from ACI_FINANCIAL_IMPUTATION
             , ACI_MGM_IMPUTATION
         where ACI_FINANCIAL_IMPUTATION.ACI_DOCUMENT_ID = document_id
           and ACI_MGM_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID(+) = ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID
      group by IMF_TYPE
             , IMF_GENRE
             , IMF_PRIMARY
             , nvl(IMF_EXCHANGE_RATE, 0)
             , nvl(IMF_BASE_PRICE, 0)
             , IMF_TRANSACTION_DATE
             , IMF_VALUE_DATE
             , nvl(TAX_EXCHANGE_RATE, 0)
             , nvl(DET_BASE_PRICE, 0)
             , TAX_INCLUDED_EXCLUDED
             , TAX_LIABLED_RATE
             , TAX_RATE
             , TAX_DEDUCTIBLE_RATE
             , TAX_REDUCTION
             , ACS_DIVISION_ACCOUNT_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_AUXILIARY_ACCOUNT_ID
             , ACS_TAX_CODE_ID
             , ACI_FINANCIAL_IMPUTATION.ACS_PERIOD_ID
             , C_GENRE_TRANSACTION
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMF_NUMBER)
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMF_NUMBER2)
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMF_NUMBER3)
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMF_NUMBER4)
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMF_NUMBER5)
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMF_TEXT1)
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMF_TEXT2)
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMF_TEXT3)
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMF_TEXT4)
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMF_TEXT5)
             , decode(managed_info.DATE1.managed, 0, null, 1, IMF_DATE1)
             , decode(managed_info.DATE2.managed, 0, null, 1, IMF_DATE2)
             , decode(managed_info.DATE3.managed, 0, null, 1, IMF_DATE3)
             , decode(managed_info.DATE4.managed, 0, null, 1, IMF_DATE4)
             , decode(managed_info.DATE5.managed, 0, null, 1, IMF_DATE5)
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE1_ID)
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE2_ID)
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE3_ID)
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE4_ID)
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DIC_IMP_FREE5_ID)
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.GCO_GOOD_ID)
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.DOC_RECORD_ID)
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.HRM_PERSON_ID)
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_FINANCIAL_IMPUTATION.PAC_PERSON_ID)
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed
                    , 0, null
                    , 1, ACI_FINANCIAL_IMPUTATION.FAM_FIXED_ASSETS_ID
                     )
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed
                    , 0, null
                    , 1, ACI_FINANCIAL_IMPUTATION.C_FAM_TRANSACTION_TYP
                     )
             , IMM_TYPE
             , IMM_GENRE
             , IMM_PRIMARY
             , nvl(IMM_EXCHANGE_RATE, 0)
             , nvl(IMM_BASE_PRICE, 0)
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
             , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , ACI_MGM_IMPUTATION.ACS_PERIOD_ID
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER)
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2)
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3)
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4)
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5)
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1)
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2)
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3)
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4)
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5)
             , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1)
             , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2)
             , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3)
             , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4)
             , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5)
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE1_ID)
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE2_ID)
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE3_ID)
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE4_ID)
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE5_ID)
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.DOC_RECORD_ID)
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.GCO_GOOD_ID)
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.HRM_PERSON_ID)
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.PAC_PERSON_ID)
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID)
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, ACI_MGM_IMPUTATION.C_FAM_TRANSACTION_TYP)
      order by max(ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID);

    fin_imputation_tuple   fin_imputation%rowtype;
    imf_descr              ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    new_mgm_imp_id         ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    new_financial_imp_id   ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    new_financial_imp_id2  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    new_fin_imp_nonded_id  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vat_amount_lc_d        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_amount_lc_c        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_amount_fc_d        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_fc_c        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_eur_d       ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_eur_c       ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_amount_vc_d        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_amount_vc_c        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_tot_amount_lc_d    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_tot_amount_lc_c    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             default 0;
    vat_tot_amount_fc_d    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_tot_amount_fc_c    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             default 0;
    vat_tot_amount_vc_d    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_tot_amount_vc_c    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    amount_lc_d            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
    amount_lc_c            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type               default 0;
    amount_fc_d            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    amount_fc_c            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    amount_eur_d           ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    amount_eur_c           ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    mgm_amount_lc_d        ACI_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type                     default 0;
    mgm_amount_lc_c        ACI_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type                     default 0;
    mgm_amount_fc_d        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type                     default 0;
    mgm_amount_fc_c        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type                     default 0;
    mgm_amount_eur_d       ACI_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type                    default 0;
    mgm_amount_eur_c       ACI_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type                    default 0;
    mgm_quantity_d         ACI_MGM_IMPUTATION.IMM_QUANTITY_C%type                      default 0;
    mgm_quantity_c         ACI_MGM_IMPUTATION.IMM_QUANTITY_C%type                      default 0;
    tax_col_fin_account_id ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    es_calc_sheet          ACS_TAX_CODE.C_ESTABLISHING_CALC_SHEET%type;
    prea_account_id        ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    prov_account_id        ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    fin_nonded_acc_id      ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    lang_id                PCS.PC_LANG.PC_LANG_ID%type;
    exchangeRate           ACI_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    basePrice              ACI_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    roundCurrency          ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type;
    NewFinImp              boolean;
    lastFinImpId           ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type   := 0;
    description_vat        ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    description_vat_nonded ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    InfoImputationManaged  ACT_IMP_MANAGEMENT.InfoImputationRecType;
    IInfoImputationManaged ACT_IMP_MANAGEMENT.IInfoImputationRecType;
    encashment             boolean;
    vOldValues             ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vNewValues             ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vACS_CPN_ACCOUNT_ID    ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type;
    MGMImput               ACT_MGM_IMPUTATION%rowtype;
    ded_amount_lc_d        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
    ded_amount_lc_c        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type               default 0;
    ded_amount_fc_d        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    ded_amount_fc_c        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    ded_amount_eur_d       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    ded_amount_eur_c       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    ded_financial_currency_id ACI_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- recherche des info géreé pour le catalogue et conversion des boolean en integer pour la commande SQL
    InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
    ACT_IMP_MANAGEMENT.ConvertManagedValuesToInt(InfoImputationManaged, IInfoImputationManaged);

    -- ouverture du curseur sur les imputations financières
    open fin_imputation(document_id, IInfoImputationManaged.primary);

    fetch fin_imputation
     into fin_imputation_tuple;

    -- si le document comprend des imputations financières
    if fin_imputation%found then
      -- recherche la descreiption de l'imputation primaire qui sera utilisée
      -- comme description de toutes les imputations cumulées
      select IMF_DESCRIPTION
        into imf_descr
        from ACI_FINANCIAL_IMPUTATION
       where ACI_DOCUMENT_ID = document_id
         and IMF_PRIMARY = 1;

      -- recherche de la langue du partenaire
      select nvl(min(A.PC_LANG_ID), PCS.PC_I_LIB_SESSION.GETCOMPLANGID)
        into lang_id
        from PAC_ADDRESS A
           , DIC_ADDRESS_TYPE B
           , ACT_PART_IMPUTATION C
       where C.ACT_DOCUMENT_ID = new_document_id
         and A.PAC_PERSON_ID = nvl(C.PAC_CUSTOM_PARTNER_ID, PAC_SUPPLIER_PARTNER_ID)
         and A.DIC_ADDRESS_TYPE_ID = B.DIC_ADDRESS_TYPE_ID
         and DAD_DEFAULT = 1;

      -- initialisation de la description pour la TVA
      description_vat         :=
                         replace(PCS.PC_FUNCTIONS.TranslateWord2('TVA sur DOCNUMBER', Lang_id), 'DOCNUMBER', doc_number);
      description_vat_nonded  := description_vat || ' ' || PCS.PC_FUNCTIONS.TranslateWord2('(non déductible)', Lang_id);
    end if;

    -- pour toutes les imputations financières
    while fin_imputation%found loop
      -- nouvelle imputation financière ou même imputation ?
      NewFinImp               := lastFinImpId <> fin_imputation_tuple.ACI_FINANCIAL_IMPUTATION_ID;
      lastFinImpId            := fin_imputation_tuple.ACI_FINANCIAL_IMPUTATION_ID;

      -- message d'erreur s'il n'y a pas de compte financier valid dans l'interface
      if fin_imputation_tuple.acs_financial_account_id is null then
        raise_application_error
                             (-20001
                            , 'PCS - No valid financial account in the financial imputation interface. Document : ' ||
                              to_char(document_id)
                             );
      end if;

      -- message d'erreur s'il n'y a pas de période valide dans l'interface
      if fin_imputation_tuple.imf_period_id is null then
        raise_application_error(-20001, 'PCS - No valid financial period in the financial imputation interface');
      end if;

      -- valeur de retour afin de savoir si on a un document débit ou crédit
      if fin_imputation_tuple.imf_primary = 1 then
        if sign(fin_imputation_tuple.IMF_AMOUNT_LC) = 1 then
          dc_type  := 'D';
        else
          dc_type  := 'C';
        end if;
      end if;

      -- mise à jour des montants TVA
      if fin_imputation_tuple.acs_tax_code_id is not null then
        if fin_imputation_tuple.IMF_AMOUNT_LC > 0 then
          vat_amount_eur_d     := fin_imputation_tuple.TAX_VAT_AMOUNT_EUR;
          vat_amount_lc_d      := fin_imputation_tuple.TAX_VAT_AMOUNT_LC;
          vat_tot_amount_lc_d  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_LC;

          if sign(vat_currency_id) = 1 then
            vat_amount_vc_d      := fin_imputation_tuple.TAX_VAT_AMOUNT_VC;
            vat_tot_amount_vc_d  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_VC;
          end if;

          if not fin_imputation_tuple.imf_financial_currency_id = fin_imputation_tuple.imf_imf_financial_currency_id then
            vat_amount_fc_d      := fin_imputation_tuple.TAX_VAT_AMOUNT_FC;
            vat_tot_amount_fc_d  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_FC;
          end if;
        else
          vat_amount_eur_c     := fin_imputation_tuple.TAX_VAT_AMOUNT_EUR;
          vat_amount_lc_c      := fin_imputation_tuple.TAX_VAT_AMOUNT_LC;
          vat_tot_amount_lc_c  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_LC;

          if sign(vat_currency_id) = 1 then
            vat_amount_vc_c      := fin_imputation_tuple.TAX_VAT_AMOUNT_VC;
            vat_tot_amount_vc_c  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_VC;
          end if;

          if not fin_imputation_tuple.imf_financial_currency_id = fin_imputation_tuple.imf_imf_financial_currency_id then
            vat_amount_fc_c      := fin_imputation_tuple.TAX_VAT_AMOUNT_FC;
            vat_tot_amount_fc_c  := fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_FC;
          end if;
        end if;
      end if;

      -- Recherche si les montants sont débit ou crédit
      select decode(sign(fin_imputation_tuple.IMF_AMOUNT_LC), 1, fin_imputation_tuple.IMF_AMOUNT_LC, 0)
        into amount_lc_d
        from dual;

      select decode(sign(fin_imputation_tuple.IMF_AMOUNT_LC), -1, -fin_imputation_tuple.IMF_AMOUNT_LC, 0)
        into amount_lc_c
        from dual;

      select decode(sign(fin_imputation_tuple.IMF_AMOUNT_FC), 1, fin_imputation_tuple.IMF_AMOUNT_FC, 0)
        into amount_fc_d
        from dual;

      select decode(sign(fin_imputation_tuple.IMF_AMOUNT_FC), -1, -fin_imputation_tuple.IMF_AMOUNT_FC, 0)
        into amount_fc_c
        from dual;

      select decode(sign(fin_imputation_tuple.IMF_AMOUNT_EUR), 1, fin_imputation_tuple.IMF_AMOUNT_EUR, 0)
        into amount_eur_d
        from dual;

      select decode(sign(fin_imputation_tuple.IMF_AMOUNT_EUR), -1, -fin_imputation_tuple.IMF_AMOUNT_EUR, 0)
        into amount_eur_c
        from dual;

      select decode(sign(fin_imputation_tuple.IMM_QUANTITY), 1, fin_imputation_tuple.IMM_QUANTITY, 0)
        into mgm_quantity_d
        from dual;

      select decode(sign(fin_imputation_tuple.IMM_QUANTITY), -1, -fin_imputation_tuple.IMM_QUANTITY, 0)
        into mgm_quantity_c
        from dual;

      exchangeRate            := fin_imputation_tuple.IMF_EXCHANGE_RATE;
      basePrice               := fin_imputation_tuple.IMF_BASE_PRICE;

      if fin_imputation_tuple.imf_financial_currency_id != fin_imputation_tuple.imf_imf_financial_currency_id then
        declare
          vAmountLc number;
          vAmountFc number;
        begin
          if fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
            vAmountLc  := (amount_lc_d - vat_amount_lc_d) +(amount_lc_c - vat_amount_lc_c);
            vAmountFc  := (amount_fc_d - vat_amount_fc_d) +(amount_fc_c - vat_amount_fc_c);
          else
            vAmountLc  := amount_lc_d + amount_lc_c;
            vAmountFc  := amount_fc_d + amount_fc_c;
          end if;

          --Màj du cours de change
          UpdateExchangeRate(vAmountLc
                           , vAmountFc
                           , fin_imputation_tuple.imf_financial_currency_id
                           , exchangeRate
                           , basePrice
                            );
        end;
      end if;

      if    (   fin_imputation_tuple.IMF_AMOUNT_LC <> 0
             or fin_imputation_tuple.IMF_AMOUNT_LC <> 0
             or fin_imputation_tuple.IMF_AMOUNT_FC <> 0
             or fin_imputation_tuple.IMF_AMOUNT_FC <> 0
            )
         or fin_imputation_tuple.IMF_PRIMARY = 1
         or pos_zero = 1 then
        if NewFinImp then
          -- recherche d'un id unique pour l'imputation que l'on va créer
          select init_id_seq.nextval
            into new_financial_imp_id
            from dual;

          -- Reprise de l'imputation pointée par le curseur.
          insert into ACT_FINANCIAL_IMPUTATION
                      (ACT_FINANCIAL_IMPUTATION_ID
                     , ACT_DOCUMENT_ID
                     , ACT_PART_IMPUTATION_ID
                     , ACS_PERIOD_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , IMF_TYPE
                     , IMF_PRIMARY
                     , IMF_DESCRIPTION
                     , IMF_AMOUNT_LC_D
                     , IMF_AMOUNT_LC_C
                     , IMF_EXCHANGE_RATE
                     , IMF_BASE_PRICE
                     , IMF_AMOUNT_FC_D
                     , IMF_AMOUNT_FC_C
                     , IMF_AMOUNT_EUR_D
                     , IMF_AMOUNT_EUR_C
                     , IMF_VALUE_DATE
                     , ACS_TAX_CODE_ID
                     , IMF_TRANSACTION_DATE
                     , ACS_AUXILIARY_ACCOUNT_ID
                     , IMF_GENRE
                     , ACS_FINANCIAL_CURRENCY_ID
                     , ACS_ACS_FINANCIAL_CURRENCY_ID
                     , C_GENRE_TRANSACTION
                     , IMF_NUMBER
                     , IMF_NUMBER2
                     , IMF_NUMBER3
                     , IMF_NUMBER4
                     , IMF_NUMBER5
                     , IMF_TEXT1
                     , IMF_TEXT2
                     , IMF_TEXT3
                     , IMF_TEXT4
                     , IMF_TEXT5
                     , IMF_DATE1
                     , IMF_DATE2
                     , IMF_DATE3
                     , IMF_DATE4
                     , IMF_DATE5
                     , DIC_IMP_FREE1_ID
                     , DIC_IMP_FREE2_ID
                     , DIC_IMP_FREE3_ID
                     , DIC_IMP_FREE4_ID
                     , DIC_IMP_FREE5_ID
                     , GCO_GOOD_ID
                     , DOC_RECORD_ID
                     , HRM_PERSON_ID
                     , PAC_PERSON_ID
                     , FAM_FIXED_ASSETS_ID
                     , C_FAM_TRANSACTION_TYP
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (new_financial_imp_id
                     , new_document_id
                     , new_part_imputation_id
                     , fin_imputation_tuple.imf_period_id
                     , fin_imputation_tuple.acs_financial_account_id
                     , fin_imputation_tuple.IMF_TYPE
                     , fin_imputation_tuple.IMF_PRIMARY
                     , imf_descr
                     , nvl(amount_lc_d, 0) - decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_lc_d, 0), 0)
                     , nvl(amount_lc_c, 0) - decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_lc_c, 0), 0)
                     , exchangeRate
                     , basePrice
                     , nvl(amount_fc_d, 0) - decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_fc_d, 0), 0)
                     , nvl(amount_fc_c, 0) - decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_fc_c, 0), 0)
                     , nvl(amount_eur_d, 0) - decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_eur_d, 0), 0)
                     , nvl(amount_eur_c, 0) - decode(fin_imputation_tuple.TAX_INCLUDED_EXCLUDED, 'E', nvl(vat_amount_eur_c, 0), 0)
                     , fin_imputation_tuple.IMF_VALUE_DATE
                     , fin_imputation_tuple.acs_tax_code_id
                     , fin_imputation_tuple.IMF_TRANSACTION_DATE
                     , fin_imputation_tuple.acs_auxiliary_account_id
                     , fin_imputation_tuple.IMF_GENRE
                     , fin_imputation_tuple.imf_financial_currency_id
                     , fin_imputation_tuple.imf_imf_financial_currency_id
                     , fin_imputation_tuple.C_GENRE_TRANSACTION
                     , fin_imputation_tuple.IMF_NUMBER
                     , fin_imputation_tuple.IMF_NUMBER2
                     , fin_imputation_tuple.IMF_NUMBER3
                     , fin_imputation_tuple.IMF_NUMBER4
                     , fin_imputation_tuple.IMF_NUMBER5
                     , fin_imputation_tuple.IMF_TEXT1
                     , fin_imputation_tuple.IMF_TEXT2
                     , fin_imputation_tuple.IMF_TEXT3
                     , fin_imputation_tuple.IMF_TEXT4
                     , fin_imputation_tuple.IMF_TEXT5
                     , fin_imputation_tuple.IMF_DATE1
                     , fin_imputation_tuple.IMF_DATE2
                     , fin_imputation_tuple.IMF_DATE3
                     , fin_imputation_tuple.IMF_DATE4
                     , fin_imputation_tuple.IMF_DATE5
                     , fin_imputation_tuple.DIC_IMP_FREE1_ID
                     , fin_imputation_tuple.DIC_IMP_FREE2_ID
                     , fin_imputation_tuple.DIC_IMP_FREE3_ID
                     , fin_imputation_tuple.DIC_IMP_FREE4_ID
                     , fin_imputation_tuple.DIC_IMP_FREE5_ID
                     , fin_imputation_tuple.GCO_GOOD_ID
                     , fin_imputation_tuple.DOC_RECORD_ID
                     , fin_imputation_tuple.HRM_PERSON_ID
                     , fin_imputation_tuple.PAC_PERSON_ID
                     , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                     , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          -- si on a un compte division, on crée la distribution financière
          if fin_imputation_tuple.acs_division_account_id is not null then
            if fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
              Recover_Fin_Distrib(new_financial_imp_id
                                , imf_descr
                                , amount_lc_d - vat_amount_lc_d
                                , amount_fc_d - vat_amount_fc_d
                                , amount_eur_d - vat_amount_eur_d
                                , amount_lc_c - vat_amount_lc_c
                                , amount_fc_c - vat_amount_fc_c
                                , amount_eur_c - vat_amount_eur_c
                                , fin_imputation_tuple.acs_division_account_id
                                 );
            else
              Recover_Fin_Distrib(new_financial_imp_id
                                , imf_descr
                                , amount_lc_d
                                , amount_fc_d
                                , amount_eur_d
                                , amount_lc_c
                                , amount_fc_c
                                , amount_eur_c
                                , fin_imputation_tuple.acs_division_account_id
                                 );
            end if;
          end if;
        end if;

        if fin_imputation_tuple.aci_mgm_imputation_id is not null then
          select init_id_seq.nextval
            into new_mgm_imp_id
            from dual;

          -- Recherche si les montants sont débit ou crédit
          select decode(sign(fin_imputation_tuple.IMM_AMOUNT_LC), 1, fin_imputation_tuple.IMM_AMOUNT_LC, 0)
            into mgm_amount_lc_d
            from dual;

          select decode(sign(fin_imputation_tuple.IMM_AMOUNT_LC), -1, -fin_imputation_tuple.IMM_AMOUNT_LC, 0)
            into mgm_amount_lc_c
            from dual;

          select decode(sign(fin_imputation_tuple.IMM_AMOUNT_FC), 1, fin_imputation_tuple.IMM_AMOUNT_FC, 0)
            into mgm_amount_fc_d
            from dual;

          select decode(sign(fin_imputation_tuple.IMM_AMOUNT_FC), -1, -fin_imputation_tuple.IMM_AMOUNT_FC, 0)
            into mgm_amount_fc_c
            from dual;

          select decode(sign(fin_imputation_tuple.IMM_AMOUNT_EUR), 1, fin_imputation_tuple.IMM_AMOUNT_EUR, 0)
            into mgm_amount_eur_d
            from dual;

          select decode(sign(fin_imputation_tuple.IMM_AMOUNT_EUR), -1, -fin_imputation_tuple.IMM_AMOUNT_EUR, 0)
            into mgm_amount_eur_c
            from dual;

          exchangeRate  := fin_imputation_tuple.IMM_EXCHANGE_RATE;
          basePrice     := fin_imputation_tuple.IMM_BASE_PRICE;

          if fin_imputation_tuple.imm_financial_currency_id != fin_imputation_tuple.imm_imm_financial_currency_id then
            --Màj du cours de change
            UpdateExchangeRate( (mgm_amount_lc_c + mgm_amount_lc_d)
                             , (mgm_amount_fc_c + mgm_amount_fc_d)
                             , fin_imputation_tuple.imm_financial_currency_id
                             , exchangeRate
                             , basePrice
                              );
          end if;

          insert into ACT_MGM_IMPUTATION
                      (ACT_MGM_IMPUTATION_ID
                     , ACS_FINANCIAL_CURRENCY_ID
                     , ACS_ACS_FINANCIAL_CURRENCY_ID
                     , ACS_PERIOD_ID
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACT_DOCUMENT_ID
                     , ACT_FINANCIAL_IMPUTATION_ID
                     , IMM_TYPE
                     , IMM_GENRE
                     , IMM_PRIMARY
                     , IMM_DESCRIPTION
                     , IMM_AMOUNT_LC_D
                     , IMM_AMOUNT_LC_C
                     , IMM_EXCHANGE_RATE
                     , IMM_BASE_PRICE
                     , IMM_AMOUNT_FC_D
                     , IMM_AMOUNT_FC_C
                     , IMM_AMOUNT_EUR_D
                     , IMM_AMOUNT_EUR_C
                     , IMM_QUANTITY_D
                     , IMM_QUANTITY_C
                     , IMM_VALUE_DATE
                     , IMM_TRANSACTION_DATE
                     , ACS_QTY_UNIT_ID
                     , IMM_NUMBER
                     , IMM_NUMBER2
                     , IMM_NUMBER3
                     , IMM_NUMBER4
                     , IMM_NUMBER5
                     , IMM_TEXT1
                     , IMM_TEXT2
                     , IMM_TEXT3
                     , IMM_TEXT4
                     , IMM_TEXT5
                     , IMM_DATE1
                     , IMM_DATE2
                     , IMM_DATE3
                     , IMM_DATE4
                     , IMM_DATE5
                     , DIC_IMP_FREE1_ID
                     , DIC_IMP_FREE2_ID
                     , DIC_IMP_FREE3_ID
                     , DIC_IMP_FREE4_ID
                     , DIC_IMP_FREE5_ID
                     , GCO_GOOD_ID
                     , DOC_RECORD_ID
                     , HRM_PERSON_ID
                     , PAC_PERSON_ID
                     , FAM_FIXED_ASSETS_ID
                     , C_FAM_TRANSACTION_TYP
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (new_mgm_imp_id
                     , fin_imputation_tuple.imm_financial_currency_id
                     , fin_imputation_tuple.imm_imm_financial_currency_id
                     , fin_imputation_tuple.imm_period_id
                     , fin_imputation_tuple.acs_cpn_account_id
                     , fin_imputation_tuple.acs_cda_account_id
                     , fin_imputation_tuple.acs_pf_account_id
                     , new_document_id
                     , new_financial_imp_id
                     , fin_imputation_tuple.IMM_TYPE
                     , fin_imputation_tuple.IMM_GENRE
                     , fin_imputation_tuple.IMM_PRIMARY
                     , imf_descr
                     , nvl(mgm_amount_lc_d, 0)
                     , nvl(mgm_amount_lc_c, 0)
                     , exchangeRate
                     , basePrice
                     , nvl(mgm_amount_fc_d, 0)
                     , nvl(mgm_amount_fc_c, 0)
                     , nvl(mgm_amount_eur_d, 0)
                     , nvl(mgm_amount_eur_c, 0)
                     , nvl(mgm_quantity_d, 0)
                     , nvl(mgm_quantity_c, 0)
                     , fin_imputation_tuple.IMM_VALUE_DATE
                     , fin_imputation_tuple.IMM_TRANSACTION_DATE
                     , fin_imputation_tuple.ACS_QTY_UNIT_ID
                     , fin_imputation_tuple.IMM_NUMBER
                     , fin_imputation_tuple.IMM_NUMBER2
                     , fin_imputation_tuple.IMM_NUMBER3
                     , fin_imputation_tuple.IMM_NUMBER4
                     , fin_imputation_tuple.IMM_NUMBER5
                     , fin_imputation_tuple.IMM_TEXT1
                     , fin_imputation_tuple.IMM_TEXT2
                     , fin_imputation_tuple.IMM_TEXT3
                     , fin_imputation_tuple.IMM_TEXT4
                     , fin_imputation_tuple.IMM_TEXT5
                     , fin_imputation_tuple.IMM_DATE1
                     , fin_imputation_tuple.IMM_DATE2
                     , fin_imputation_tuple.IMM_DATE3
                     , fin_imputation_tuple.IMM_DATE4
                     , fin_imputation_tuple.IMM_DATE5
                     , fin_imputation_tuple.IMM_DIC_IMP_FREE1_ID
                     , fin_imputation_tuple.IMM_DIC_IMP_FREE2_ID
                     , fin_imputation_tuple.IMM_DIC_IMP_FREE3_ID
                     , fin_imputation_tuple.IMM_DIC_IMP_FREE4_ID
                     , fin_imputation_tuple.IMM_DIC_IMP_FREE5_ID
                     , fin_imputation_tuple.IMM_GCO_GOOD_ID
                     , fin_imputation_tuple.IMM_DOC_RECORD_ID
                     , fin_imputation_tuple.IMM_HRM_PERSON_ID
                     , fin_imputation_tuple.IMM_PAC_PERSON_ID
                     , fin_imputation_tuple.IMM_FAM_FIXED_ASSETS_ID
                     , fin_imputation_tuple.IMM_C_FAM_TRANSACTION_TYP
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          -- si on a un compte projet, on crée la distribution financière
          if fin_imputation_tuple.acs_pj_account_id is not null then
            Recover_Mgm_Distrib(new_mgm_imp_id
                              , imf_descr
                              , mgm_amount_lc_d
                              , mgm_amount_fc_d
                              , mgm_amount_eur_d
                              , mgm_amount_lc_c
                              , mgm_amount_fc_c
                              , mgm_amount_eur_c
                              , mgm_quantity_d
                              , mgm_quantity_c
                              , fin_imputation_tuple.IMM_TEXT1
                              , fin_imputation_tuple.IMM_TEXT2
                              , fin_imputation_tuple.IMM_TEXT3
                              , fin_imputation_tuple.IMM_TEXT4
                              , fin_imputation_tuple.IMM_TEXT5
                              , fin_imputation_tuple.IMM_DATE1
                              , fin_imputation_tuple.IMM_DATE2
                              , fin_imputation_tuple.IMM_DATE3
                              , fin_imputation_tuple.IMM_DATE4
                              , fin_imputation_tuple.IMM_DATE5
                              , fin_imputation_tuple.IMM_NUMBER
                              , fin_imputation_tuple.IMM_NUMBER2
                              , fin_imputation_tuple.IMM_NUMBER3
                              , fin_imputation_tuple.IMM_NUMBER4
                              , fin_imputation_tuple.IMM_NUMBER5
                              , fin_imputation_tuple.acs_pj_account_id
                               );
          end if;
        end if;
      else
        NewFinImp  := false;
      end if;

      if NewFinImp then
        -- s'il y a de la TVA sur l'imputation
        if fin_imputation_tuple.acs_tax_code_id is not null then
          if fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
            -- recherche du compte financier d'imputation de la TVA
            select C_ESTABLISHING_CALC_SHEET
                 , ACS_PREA_ACCOUNT_ID
                 , ACS_PROV_ACCOUNT_ID
              into es_calc_sheet
                 , prea_account_id
                 , prov_account_id
              from ACS_TAX_CODE
             where ACS_TAX_CODE_ID = fin_imputation_tuple.acs_tax_code_id;

            encashment := False;
            if es_calc_sheet = '1' then
              tax_col_fin_account_id  := prea_account_id;
            elsif es_calc_sheet = '2' then
              tax_col_fin_account_id  := prov_account_id;
              encashment := nvl(PCS.PC_CONFIG.GetConfigUpper('ACT_TAX_VAT_ENCASHMENT'), 'FALSE') = 'TRUE';
            end if;

            if encashment or (abs(vat_amount_lc_d) + abs(vat_amount_lc_c) > 0) then
              -- recherche d'un id unique pour l'imputation que l'on va créer
              select init_id_seq.nextval
                into new_financial_imp_id2
                from dual;

              if tax_col_fin_account_id is null then
                raise_application_error(-20003, 'PCS - No financial account in the tax code definition');
              end if;

              if    encashment
                 or vat_amount_lc_d <> 0
                 or vat_amount_lc_c <> 0
                 or vat_amount_fc_d <> 0
                 or vat_amount_fc_c <> 0 then
                -- Reprise de l'imputation pointée par le curseur.
                insert into ACT_FINANCIAL_IMPUTATION
                            (ACT_FINANCIAL_IMPUTATION_ID
                           , ACT_DOCUMENT_ID
                           , ACT_PART_IMPUTATION_ID
                           , ACS_PERIOD_ID
                           , ACS_FINANCIAL_ACCOUNT_ID
                           , IMF_TYPE
                           , IMF_PRIMARY
                           , IMF_DESCRIPTION
                           , IMF_AMOUNT_LC_D
                           , IMF_AMOUNT_LC_C
                           , IMF_EXCHANGE_RATE
                           , IMF_BASE_PRICE
                           , IMF_AMOUNT_FC_D
                           , IMF_AMOUNT_FC_C
                           , IMF_AMOUNT_EUR_D
                           , IMF_AMOUNT_EUR_C
                           , IMF_VALUE_DATE
                           , IMF_TRANSACTION_DATE
                           , ACS_AUXILIARY_ACCOUNT_ID
                           , IMF_GENRE
                           , ACS_FINANCIAL_CURRENCY_ID
                           , ACS_ACS_FINANCIAL_CURRENCY_ID
                           , C_GENRE_TRANSACTION
                           , IMF_NUMBER
                           , IMF_NUMBER2
                           , IMF_NUMBER3
                           , IMF_NUMBER4
                           , IMF_NUMBER5
                           , IMF_TEXT1
                           , IMF_TEXT2
                           , IMF_TEXT3
                           , IMF_TEXT4
                           , IMF_TEXT5
                           , IMF_DATE1
                           , IMF_DATE2
                           , IMF_DATE3
                           , IMF_DATE4
                           , IMF_DATE5
                           , DIC_IMP_FREE1_ID
                           , DIC_IMP_FREE2_ID
                           , DIC_IMP_FREE3_ID
                           , DIC_IMP_FREE4_ID
                           , DIC_IMP_FREE5_ID
                           , GCO_GOOD_ID
                           , DOC_RECORD_ID
                           , HRM_PERSON_ID
                           , PAC_PERSON_ID
                           , FAM_FIXED_ASSETS_ID
                           , C_FAM_TRANSACTION_TYP
                           , A_DATECRE
                           , A_IDCRE
                            )
                     values (new_financial_imp_id2
                           , new_document_id
                           , new_part_imputation_id
                           , fin_imputation_tuple.imf_period_id
                           , tax_col_fin_account_id
                           , 'VAT'
                           , fin_imputation_tuple.IMF_PRIMARY
                           ,
                             -- imf_descr,
                             description_vat
                           , nvl(vat_amount_lc_d, 0)
                           , nvl(vat_amount_lc_c, 0)
                           , fin_imputation_tuple.TAX_EXCHANGE_RATE
                           , fin_imputation_tuple.DET_BASE_PRICE
                           , decode(sign(vat_currency_id), 1, nvl(vat_amount_vc_d, 0), nvl(vat_amount_fc_d, 0))
                           , decode(sign(vat_currency_id), 1, nvl(vat_amount_vc_c, 0), nvl(vat_amount_fc_c, 0))
                           , nvl(vat_amount_eur_d, 0)
                           , nvl(vat_amount_eur_c, 0)
                           , fin_imputation_tuple.IMF_VALUE_DATE
                           , fin_imputation_tuple.IMF_TRANSACTION_DATE
                           , fin_imputation_tuple.acs_auxiliary_account_id
                           , fin_imputation_tuple.IMF_GENRE
                           , decode(sign(vat_currency_id)
                                  , 1, vat_currency_id
                                  , fin_imputation_tuple.imf_financial_currency_id
                                   )
                           , fin_imputation_tuple.imf_imf_financial_currency_id
                           , fin_imputation_tuple.C_GENRE_TRANSACTION
                           , fin_imputation_tuple.IMF_NUMBER
                           , fin_imputation_tuple.IMF_NUMBER2
                           , fin_imputation_tuple.IMF_NUMBER3
                           , fin_imputation_tuple.IMF_NUMBER4
                           , fin_imputation_tuple.IMF_NUMBER5
                           , fin_imputation_tuple.IMF_TEXT1
                           , fin_imputation_tuple.IMF_TEXT2
                           , fin_imputation_tuple.IMF_TEXT3
                           , fin_imputation_tuple.IMF_TEXT4
                           , fin_imputation_tuple.IMF_TEXT5
                           , fin_imputation_tuple.IMF_DATE1
                           , fin_imputation_tuple.IMF_DATE2
                           , fin_imputation_tuple.IMF_DATE3
                           , fin_imputation_tuple.IMF_DATE4
                           , fin_imputation_tuple.IMF_DATE5
                           , fin_imputation_tuple.DIC_IMP_FREE1_ID
                           , fin_imputation_tuple.DIC_IMP_FREE2_ID
                           , fin_imputation_tuple.DIC_IMP_FREE3_ID
                           , fin_imputation_tuple.DIC_IMP_FREE4_ID
                           , fin_imputation_tuple.DIC_IMP_FREE5_ID
                           , fin_imputation_tuple.GCO_GOOD_ID
                           , fin_imputation_tuple.DOC_RECORD_ID
                           , fin_imputation_tuple.HRM_PERSON_ID
                           , fin_imputation_tuple.PAC_PERSON_ID
                           , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                           , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                           , sysdate
                           , PCS.PC_I_LIB_SESSION.GetUserIni
                            );

                if fin_imputation_tuple.acs_division_account_id is not null then
                  if sign(vat_currency_id) = 1 then
                    Recover_Fin_Distrib
                                     (new_financial_imp_id2
                                    , description_vat
                                    , vat_amount_lc_d
                                    , vat_amount_vc_d
                                    , vat_amount_eur_d
                                    , vat_amount_lc_c
                                    , vat_amount_vc_c
                                    , vat_amount_eur_c
                                    , ACS_FUNCTION.GetDivisionOfAccount(tax_col_fin_account_id
                                                                      , fin_imputation_tuple.acs_division_account_id
                                                                      , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                                                       )
                                     );
                  else
                    Recover_Fin_Distrib
                                     (new_financial_imp_id2
                                    , description_vat
                                    , vat_amount_lc_d
                                    , vat_amount_fc_d
                                    , vat_amount_eur_d
                                    , vat_amount_lc_c
                                    , vat_amount_fc_c
                                    , vat_amount_eur_c
                                    , ACS_FUNCTION.GetDivisionOfAccount(tax_col_fin_account_id
                                                                      , fin_imputation_tuple.acs_division_account_id
                                                                      , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                                                       )
                                     );
                  end if;
                end if;
              end if;
            end if;

            if fin_imputation_tuple.TAX_DEDUCTIBLE_RATE <> 100 then
              ded_amount_lc_d := nvl(vat_tot_amount_lc_d, 0) - nvl(vat_amount_lc_d, 0);
              ded_amount_lc_c := nvl(vat_tot_amount_lc_c, 0) - nvl(vat_amount_lc_c, 0);

              if sign(vat_currency_id) =  1 then
                ded_amount_fc_d := nvl(vat_tot_amount_vc_d, 0) - nvl(vat_amount_vc_d, 0);
                ded_amount_fc_c := nvl(vat_tot_amount_vc_c, 0) - nvl(vat_amount_vc_c, 0);
                ded_financial_currency_id     := vat_currency_id;
              else
                ded_amount_fc_d := nvl(vat_tot_amount_fc_d, 0) - nvl(vat_amount_vc_d, 0);
                ded_amount_fc_c := nvl(vat_tot_amount_fc_c, 0) - nvl(vat_amount_fc_c, 0);
                ded_financial_currency_id     := fin_imputation_tuple.imf_financial_currency_id;
              end if;

              ded_amount_eur_d := null;
              ded_amount_eur_c := null;

              select nvl(ACS_NONDED_ACCOUNT_ID, fin_imputation_tuple.acs_financial_account_id)
                into fin_nonded_acc_id
                from ACS_TAX_CODE
               where ACS_TAX_CODE_ID = fin_imputation_tuple.acs_tax_code_id;

              -- recherche d'un id unique pour l'imputation que l'on va créer
              select init_id_seq.nextval
                into new_fin_imp_nonded_id
                from dual;

              insert into ACT_FINANCIAL_IMPUTATION
                          (ACT_FINANCIAL_IMPUTATION_ID
                         , ACT_DOCUMENT_ID
                         , ACT_PART_IMPUTATION_ID
                         , ACS_PERIOD_ID
                         , ACS_FINANCIAL_ACCOUNT_ID
                         , IMF_TYPE
                         , IMF_PRIMARY
                         , IMF_DESCRIPTION
                         , IMF_AMOUNT_LC_D
                         , IMF_AMOUNT_LC_C
                         , IMF_EXCHANGE_RATE
                         , IMF_BASE_PRICE
                         , IMF_AMOUNT_FC_D
                         , IMF_AMOUNT_FC_C
                         , IMF_AMOUNT_EUR_D
                         , IMF_AMOUNT_EUR_C
                         , IMF_VALUE_DATE
                         , IMF_TRANSACTION_DATE
                         , ACS_AUXILIARY_ACCOUNT_ID
                         , IMF_GENRE
                         , ACS_FINANCIAL_CURRENCY_ID
                         , ACS_ACS_FINANCIAL_CURRENCY_ID
                         , C_GENRE_TRANSACTION
                         , IMF_NUMBER
                         , IMF_NUMBER2
                         , IMF_NUMBER3
                         , IMF_NUMBER4
                         , IMF_NUMBER5
                         , IMF_TEXT1
                         , IMF_TEXT2
                         , IMF_TEXT3
                         , IMF_TEXT4
                         , IMF_TEXT5
                         , IMF_DATE1
                         , IMF_DATE2
                         , IMF_DATE3
                         , IMF_DATE4
                         , IMF_DATE5
                         , DIC_IMP_FREE1_ID
                         , DIC_IMP_FREE2_ID
                         , DIC_IMP_FREE3_ID
                         , DIC_IMP_FREE4_ID
                         , DIC_IMP_FREE5_ID
                         , GCO_GOOD_ID
                         , DOC_RECORD_ID
                         , HRM_PERSON_ID
                         , PAC_PERSON_ID
                         , FAM_FIXED_ASSETS_ID
                         , C_FAM_TRANSACTION_TYP
                         , A_DATECRE
                         , A_IDCRE
                          )
                   values (new_fin_imp_nonded_id
                         , new_document_id
                         , new_part_imputation_id
                         , fin_imputation_tuple.imf_period_id
                         , fin_nonded_acc_id
                         , 'MAN'
                         , fin_imputation_tuple.IMF_PRIMARY
                         ,
                           -- fin_imputation_tuple.IMF_DESCRIPTION,
                           description_vat_nonded
                         , ded_amount_lc_d
                         , ded_amount_lc_c
                         , fin_imputation_tuple.TAX_EXCHANGE_RATE
                         , fin_imputation_tuple.DET_BASE_PRICE
                         , ded_amount_fc_d
                         , ded_amount_fc_c
                         , ded_amount_eur_d
                         , ded_amount_eur_c
                         , fin_imputation_tuple.IMF_VALUE_DATE
                         , fin_imputation_tuple.IMF_TRANSACTION_DATE
                         , fin_imputation_tuple.acs_auxiliary_account_id
                         , fin_imputation_tuple.IMF_GENRE
                         , ded_financial_currency_id
                         , fin_imputation_tuple.imf_imf_financial_currency_id
                         , '1'
                         , fin_imputation_tuple.IMF_NUMBER
                         , fin_imputation_tuple.IMF_NUMBER2
                         , fin_imputation_tuple.IMF_NUMBER3
                         , fin_imputation_tuple.IMF_NUMBER4
                         , fin_imputation_tuple.IMF_NUMBER5
                         , fin_imputation_tuple.IMF_TEXT1
                         , fin_imputation_tuple.IMF_TEXT2
                         , fin_imputation_tuple.IMF_TEXT3
                         , fin_imputation_tuple.IMF_TEXT4
                         , fin_imputation_tuple.IMF_TEXT5
                         , fin_imputation_tuple.IMF_DATE1
                         , fin_imputation_tuple.IMF_DATE2
                         , fin_imputation_tuple.IMF_DATE3
                         , fin_imputation_tuple.IMF_DATE4
                         , fin_imputation_tuple.IMF_DATE5
                         , fin_imputation_tuple.DIC_IMP_FREE1_ID
                         , fin_imputation_tuple.DIC_IMP_FREE2_ID
                         , fin_imputation_tuple.DIC_IMP_FREE3_ID
                         , fin_imputation_tuple.DIC_IMP_FREE4_ID
                         , fin_imputation_tuple.DIC_IMP_FREE5_ID
                         , fin_imputation_tuple.GCO_GOOD_ID
                         , fin_imputation_tuple.DOC_RECORD_ID
                         , fin_imputation_tuple.HRM_PERSON_ID
                         , fin_imputation_tuple.PAC_PERSON_ID
                         , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                         , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                         , sysdate
                         , PCS.PC_I_LIB_SESSION.GetUserIni
                          );

              if fin_imputation_tuple.acs_division_account_id is not null then
                Recover_Fin_Distrib
                                   (new_fin_imp_nonded_id
                                  , description_vat_nonded
                                  , ded_amount_lc_d
                                  , ded_amount_fc_d
                                  , null
                                  , ded_amount_lc_c
                                  , ded_amount_fc_c
                                  , null
                                  , ACS_FUNCTION.GetDivisionOfAccount(fin_nonded_acc_id
                                                                    , fin_imputation_tuple.acs_division_account_id
                                                                    , fin_imputation_tuple.IMF_TRANSACTION_DATE
                                                                     )
                                   );
              end if;

              if new_mgm_imp_id is not null then
                if fin_nonded_acc_id = fin_imputation_tuple.acs_financial_account_id then
                  MGMImput := null;

                  MGMImput.IMM_AMOUNT_LC_D  := ded_amount_lc_d;
                  MGMImput.IMM_AMOUNT_LC_C  := ded_amount_lc_c;
                  MGMImput.IMM_AMOUNT_FC_D  := ded_amount_fc_d;
                  MGMImput.IMM_AMOUNT_EUR_D := ded_amount_eur_d;
                  MGMImput.IMM_AMOUNT_FC_C  := ded_amount_fc_c;
                  MGMImput.IMM_AMOUNT_EUR_C := ded_amount_eur_c;

                  MGMImput.ACS_FINANCIAL_CURRENCY_ID     := ded_financial_currency_id;
                  MGMImput.ACS_ACS_FINANCIAL_CURRENCY_ID := fin_imputation_tuple.imf_imf_financial_currency_id;

                  MGMImput.IMM_EXCHANGE_RATE := fin_imputation_tuple.TAX_EXCHANGE_RATE;
                  MGMImput.IMM_BASE_PRICE    := fin_imputation_tuple.DET_BASE_PRICE;

                  MGMImput.IMM_DESCRIPTION := description_vat_nonded;
                  MGMImput.IMM_TYPE := 'MAN';

                  CreateImputationForVAT(new_fin_imp_nonded_id, new_financial_imp_id, MGMImput);
                else
                  vACS_CPN_ACCOUNT_ID := ACS_FUNCTION.GetCpnOfFinAcc(fin_nonded_acc_id);

                  if vACS_CPN_ACCOUNT_ID is not null then

                    select min(ACS_CDA_ACCOUNT_ID)
                         , min(ACS_PF_ACCOUNT_ID)
                         , min(ACS_PJ_ACCOUNT_ID)
                      into vOldValues.CDAAccId
                         , vOldValues.PFAccId
                         , vOldValues.PJAccId
                      from (select IMP.ACS_CDA_ACCOUNT_ID
                                 , IMP.ACS_PF_ACCOUNT_ID
                                 , DIST.ACS_PJ_ACCOUNT_ID
                              from ACT_MGM_DISTRIBUTION DIST
                                 , ACT_MGM_IMPUTATION IMP
                             where IMP.ACT_FINANCIAL_IMPUTATION_ID = new_financial_imp_id
                               and IMP.ACT_MGM_IMPUTATION_ID = DIST.ACT_MGM_IMPUTATION_ID(+)
                               and rownum = 1);

                    declare
                      vTest Boolean;
                    begin
                      vTest := ACT_MGM_MANAGEMENT.ReInitialize(vACS_CPN_ACCOUNT_ID, fin_imputation_tuple.IMF_TRANSACTION_DATE, vOldValues, vNewValues);
                    end;

                    select init_id_seq.nextval
                      into new_mgm_imp_id
                      from dual;

                    insert into ACT_MGM_IMPUTATION
                                (ACT_MGM_IMPUTATION_ID
                               , ACS_FINANCIAL_CURRENCY_ID
                               , ACS_ACS_FINANCIAL_CURRENCY_ID
                               , ACS_PERIOD_ID
                               , ACS_CPN_ACCOUNT_ID
                               , ACS_CDA_ACCOUNT_ID
                               , ACS_PF_ACCOUNT_ID
                               , ACT_DOCUMENT_ID
                               , ACT_FINANCIAL_IMPUTATION_ID
                               , IMM_TYPE
                               , IMM_GENRE
                               , IMM_PRIMARY
                               , IMM_DESCRIPTION
                               , IMM_AMOUNT_LC_D
                               , IMM_AMOUNT_LC_C
                               , IMM_EXCHANGE_RATE
                               , IMM_BASE_PRICE
                               , IMM_AMOUNT_FC_D
                               , IMM_AMOUNT_FC_C
                               , IMM_AMOUNT_EUR_D
                               , IMM_AMOUNT_EUR_C
                               , IMM_QUANTITY_D
                               , IMM_QUANTITY_C
                               , IMM_VALUE_DATE
                               , IMM_TRANSACTION_DATE
                               , ACS_QTY_UNIT_ID
                               , IMM_TEXT1
                               , IMM_TEXT2
                               , IMM_TEXT3
                               , IMM_TEXT4
                               , IMM_TEXT5
                               , IMM_DATE1
                               , IMM_DATE2
                               , IMM_DATE3
                               , IMM_DATE4
                               , IMM_DATE5
                               , IMM_NUMBER
                               , IMM_NUMBER2
                               , IMM_NUMBER3
                               , IMM_NUMBER4
                               , IMM_NUMBER5
                               , DIC_IMP_FREE1_ID
                               , DIC_IMP_FREE2_ID
                               , DIC_IMP_FREE3_ID
                               , DIC_IMP_FREE4_ID
                               , DIC_IMP_FREE5_ID
                               , DOC_RECORD_ID
                               , GCO_GOOD_ID
                               , HRM_PERSON_ID
                               , PAC_PERSON_ID
                               , FAM_FIXED_ASSETS_ID
                               , C_FAM_TRANSACTION_TYP
                               , A_DATECRE
                               , A_IDCRE
                                )
                         values (new_mgm_imp_id
                               , ded_financial_currency_id
                               , fin_imputation_tuple.imf_imf_financial_currency_id
                               , fin_imputation_tuple.imf_period_id
                               , vACS_CPN_ACCOUNT_ID
                               , vNewValues.CDAAccId
                               , vNewValues.PFAccId
                               , new_document_id
                               , new_fin_imp_nonded_id
                               , 'MAN'
                               , fin_imputation_tuple.IMF_GENRE
                               , fin_imputation_tuple.IMF_PRIMARY
                               , description_vat_nonded
                               , ded_amount_lc_d
                               , ded_amount_lc_c
                               , fin_imputation_tuple.TAX_EXCHANGE_RATE
                               , fin_imputation_tuple.DET_BASE_PRICE
                               , ded_amount_fc_d
                               , ded_amount_fc_c
                               , ded_amount_eur_d
                               , ded_amount_eur_c
                               , 0
                               , 0
                               , fin_imputation_tuple.IMF_VALUE_DATE
                               , fin_imputation_tuple.IMF_TRANSACTION_DATE
                               , ACT_CREATION_SBVR.GetQTYAccountIdOfCPN(vACS_CPN_ACCOUNT_ID)
                               , fin_imputation_tuple.IMF_TEXT1
                               , fin_imputation_tuple.IMF_TEXT2
                               , fin_imputation_tuple.IMF_TEXT3
                               , fin_imputation_tuple.IMF_TEXT4
                               , fin_imputation_tuple.IMF_TEXT5
                               , fin_imputation_tuple.IMF_DATE1
                               , fin_imputation_tuple.IMF_DATE2
                               , fin_imputation_tuple.IMF_DATE3
                               , fin_imputation_tuple.IMF_DATE4
                               , fin_imputation_tuple.IMF_DATE5
                               , fin_imputation_tuple.IMF_NUMBER
                               , fin_imputation_tuple.IMF_NUMBER2
                               , fin_imputation_tuple.IMF_NUMBER3
                               , fin_imputation_tuple.IMF_NUMBER4
                               , fin_imputation_tuple.IMF_NUMBER5
                               , fin_imputation_tuple.DIC_IMP_FREE1_ID
                               , fin_imputation_tuple.DIC_IMP_FREE2_ID
                               , fin_imputation_tuple.DIC_IMP_FREE3_ID
                               , fin_imputation_tuple.DIC_IMP_FREE4_ID
                               , fin_imputation_tuple.DIC_IMP_FREE5_ID
                               , fin_imputation_tuple.DOC_RECORD_ID
                               , fin_imputation_tuple.GCO_GOOD_ID
                               , fin_imputation_tuple.HRM_PERSON_ID
                               , fin_imputation_tuple.PAC_PERSON_ID
                               , fin_imputation_tuple.FAM_FIXED_ASSETS_ID
                               , fin_imputation_tuple.C_FAM_TRANSACTION_TYP
                               , sysdate
                               , PCS.PC_I_LIB_SESSION.GetUserIni
                                );

                    if vNewValues.PJAccId is not null then
                      Recover_Mgm_Distrib(new_mgm_imp_id
                                        , description_vat_nonded
                                        , ded_amount_lc_d
                                        , ded_amount_fc_d
                                        , ded_amount_eur_d
                                        , ded_amount_lc_c
                                        , ded_amount_fc_c
                                        , ded_amount_eur_c
                                        , 0
                                        , 0
                                        , fin_imputation_tuple.IMF_TEXT1
                                        , fin_imputation_tuple.IMF_TEXT2
                                        , fin_imputation_tuple.IMF_TEXT3
                                        , fin_imputation_tuple.IMF_TEXT4
                                        , fin_imputation_tuple.IMF_TEXT5
                                        , fin_imputation_tuple.IMF_DATE1
                                        , fin_imputation_tuple.IMF_DATE2
                                        , fin_imputation_tuple.IMF_DATE3
                                        , fin_imputation_tuple.IMF_DATE4
                                        , fin_imputation_tuple.IMF_DATE5
                                        , fin_imputation_tuple.IMF_NUMBER
                                        , fin_imputation_tuple.IMF_NUMBER2
                                        , fin_imputation_tuple.IMF_NUMBER3
                                        , fin_imputation_tuple.IMF_NUMBER4
                                        , fin_imputation_tuple.IMF_NUMBER5
                                        , vNewValues.PJAccId
                                         );
                    end if;
                  end if;
                end if;
              end if;
            end if;
          end if;

          -- Création du déatil TVA
          if new_financial_imp_id is not null then
            if sign(vat_currency_id) = 1 then
              Recover_Tax_Code(new_financial_imp_id
                             , new_financial_imp_id2
                             , fin_imputation_tuple.TAX_INCLUDED_EXCLUDED
                             , fin_imputation_tuple.TAX_EXCHANGE_RATE
                             , fin_imputation_tuple.TAX_LIABLED_AMOUNT
                             , fin_imputation_tuple.TAX_LIABLED_RATE
                             , fin_imputation_tuple.TAX_RATE
                             , vat_amount_lc_d - vat_amount_lc_c
                             , vat_amount_vc_d - vat_amount_vc_c
                             , vat_amount_eur_d - vat_amount_eur_c
                             , vat_tot_amount_lc_d - vat_tot_amount_lc_c
                             , vat_tot_amount_vc_d - vat_tot_amount_vc_c
                             , null
                             , fin_imputation_tuple.TAX_DEDUCTIBLE_RATE
                             , new_fin_imp_nonded_id
                             , fin_imputation_tuple.ACS_TAX_CODE_ID
                             , fin_imputation_tuple.TAX_REDUCTION
                             , fin_imputation_tuple.DET_BASE_PRICE
                              );
            else
              Recover_Tax_Code(new_financial_imp_id
                             , new_financial_imp_id2
                             , fin_imputation_tuple.TAX_INCLUDED_EXCLUDED
                             , fin_imputation_tuple.TAX_EXCHANGE_RATE
                             , fin_imputation_tuple.TAX_LIABLED_AMOUNT
                             , fin_imputation_tuple.TAX_LIABLED_RATE
                             , fin_imputation_tuple.TAX_RATE
                             , vat_amount_lc_d - vat_amount_lc_c
                             , vat_amount_fc_d - vat_amount_fc_c
                             , vat_amount_eur_d - vat_amount_eur_c
                             , vat_tot_amount_lc_d - vat_tot_amount_lc_c
                             , vat_tot_amount_fc_d - vat_tot_amount_fc_c
                             , null
                             , fin_imputation_tuple.TAX_DEDUCTIBLE_RATE
                             , new_fin_imp_nonded_id
                             , fin_imputation_tuple.ACS_TAX_CODE_ID
                             , fin_imputation_tuple.TAX_REDUCTION
                             , fin_imputation_tuple.DET_BASE_PRICE
                              );
            end if;
          end if;
        end if;

        -- Création des imputations d'autotaxation
        if     new_financial_imp_id is not null
           and fin_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'S'
           and not ACT_VAT_MANAGEMENT.CreateVAT_ACI(new_financial_imp_id) then
          raise_application_error(-20001, 'PCS - Problem with Self-Taxing');
        end if;
      end if;

      -- imputation suivante
      fetch fin_imputation
       into fin_imputation_tuple;

      -- remise à 0 des montants
      -- new_financial_imp_id := null;
      new_financial_imp_id2   := null;
      tax_col_fin_account_id  := null;
      amount_lc_c             := 0;
      amount_lc_d             := 0;
      amount_fc_c             := 0;
      amount_fc_d             := 0;
      amount_eur_c            := 0;
      amount_eur_d            := 0;
      mgm_amount_lc_c         := 0;
      mgm_amount_lc_d         := 0;
      mgm_amount_fc_c         := 0;
      mgm_amount_fc_d         := 0;
      mgm_amount_eur_c        := 0;
      mgm_amount_eur_d        := 0;
      mgm_quantity_d          := 0;
      mgm_quantity_c          := 0;
      vat_amount_lc_d         := 0;
      vat_amount_lc_c         := 0;
      vat_amount_fc_d         := 0;
      vat_amount_fc_c         := 0;
      vat_amount_eur_d        := 0;
      vat_amount_eur_c        := 0;
      vat_amount_vc_d         := 0;
      vat_amount_vc_c         := 0;
      vat_tot_amount_lc_c     := 0;
      vat_tot_amount_lc_d     := 0;
      vat_tot_amount_fc_c     := 0;
      vat_tot_amount_fc_d     := 0;
      vat_tot_amount_vc_d     := 0;
      vat_tot_amount_vc_c     := 0;
    end loop;

    close fin_imputation;
  end Recover_Fin_Imp_Cumul_Group;

  /**
  * Description
  *   reprise détaillée des imputations analytiques sans relations
  *   avec les imputations financières
  */
  procedure Recover_Mgm_Imp_Detail(
    document_id           in number
  , new_document_id       in number
  , financial_year_id     in number
  , pos_zero              in number
  , catalogue_document_id in number
  )
  is
    cursor mgm_imputation(document_id number, managed_info ACT_IMP_MANAGEMENT.IInfoImputationBaseRecType)
    is
      select ACI_MGM_IMPUTATION_ID
           , IMM_TYPE
           , IMM_GENRE
           , IMM_PRIMARY
           , IMM_DESCRIPTION
           , IMM_AMOUNT_LC_D
           , IMM_AMOUNT_LC_C
           , nvl(IMM_EXCHANGE_RATE, 0) IMM_EXCHANGE_RATE
           , nvl(IMM_BASE_PRICE, 0) IMM_BASE_PRICE
           , IMM_AMOUNT_FC_D
           , IMM_AMOUNT_FC_C
           , IMM_AMOUNT_EUR_D
           , IMM_AMOUNT_EUR_C
           , IMM_VALUE_DATE
           , IMM_TRANSACTION_DATE
           , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1) IMM_TEXT1
           , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2) IMM_TEXT2
           , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3) IMM_TEXT3
           , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4) IMM_TEXT4
           , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5) IMM_TEXT5
           , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1) IMM_DATE1
           , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2) IMM_DATE2
           , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3) IMM_DATE3
           , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4) IMM_DATE4
           , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5) IMM_DATE5
           , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER) IMM_NUMBER
           , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2) IMM_NUMBER2
           , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3) IMM_NUMBER3
           , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4) IMM_NUMBER4
           , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5) IMM_NUMBER5
           , decode(managed_info.DICO1.managed, 0, null, 1, DIC_IMP_FREE1_ID) DIC_IMP_FREE1_ID
           , decode(managed_info.DICO2.managed, 0, null, 1, DIC_IMP_FREE2_ID) DIC_IMP_FREE2_ID
           , decode(managed_info.DICO3.managed, 0, null, 1, DIC_IMP_FREE3_ID) DIC_IMP_FREE3_ID
           , decode(managed_info.DICO4.managed, 0, null, 1, DIC_IMP_FREE4_ID) DIC_IMP_FREE4_ID
           , decode(managed_info.DICO5.managed, 0, null, 1, DIC_IMP_FREE5_ID) DIC_IMP_FREE5_ID
           , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, GCO_GOOD_ID) GCO_GOOD_ID
           , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, DOC_RECORD_ID) DOC_RECORD_ID
           , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, HRM_PERSON_ID) HRM_PERSON_ID
           , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, PAC_PERSON_ID) PAC_PERSON_ID
           , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, FAM_FIXED_ASSETS_ID) FAM_FIXED_ASSETS_ID
           , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, C_FAM_TRANSACTION_TYP)
                                                                                                  C_FAM_TRANSACTION_TYP
           , IMM_QUANTITY_D
           , IMM_QUANTITY_C
           , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMM_FINANCIAL_CURRENCY_ID
           , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMM_IMM_FINANCIAL_CURRENCY_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
           , ACS_QTY_UNIT_ID
           , ACI_MGM_IMPUTATION.ACS_PERIOD_ID IMM_PERIOD_ID
        from ACI_MGM_IMPUTATION
       where ACI_MGM_IMPUTATION.ACI_DOCUMENT_ID = document_id
         and ACI_FINANCIAL_IMPUTATION_ID is null;

    new_mgm_imp_id         ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    mgm_amount_fc_d        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type          default 0;
    mgm_amount_fc_c        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type          default 0;
    exchangeRate           ACI_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type;
    basePrice              ACI_MGM_IMPUTATION.IMM_BASE_PRICE%type;
    roundCurrency          ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type;
    InfoImputationManaged  ACT_IMP_MANAGEMENT.InfoImputationRecType;
    IInfoImputationManaged ACT_IMP_MANAGEMENT.IInfoImputationRecType;
  begin
    -- recherche des info géreé pour le catalogue et conversion des boolean en integer pour la commande SQL
    InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
    ACT_IMP_MANAGEMENT.ConvertManagedValuesToInt(InfoImputationManaged, IInfoImputationManaged);

    -- pour toutes les imputations financières
    for mgm_imputation_tuple in mgm_imputation(document_id, IInfoImputationManaged.primary) loop
      -- message d'erreur s'il n'y a pas de période valide dans l'interface
      if mgm_imputation_tuple.imm_period_id is null then
        raise_application_error(-20011, 'PCS - No valid financial period in the mgm imputation interface');
      end if;

      -- Ecriture reportée seulement si les montants ne sont pas nuls.
      if    (   mgm_imputation_tuple.IMM_AMOUNT_LC_D <> 0
             or mgm_imputation_tuple.IMM_AMOUNT_LC_C <> 0
             or mgm_imputation_tuple.IMM_AMOUNT_FC_D <> 0
             or mgm_imputation_tuple.IMM_AMOUNT_FC_C <> 0
            )
         or pos_zero = 1 then
        exchangeRate  := mgm_imputation_tuple.IMM_EXCHANGE_RATE;
        basePrice     := mgm_imputation_tuple.IMM_BASE_PRICE;

        if nvl(mgm_imputation_tuple.imm_financial_currency_id, mgm_imputation_tuple.imm_imm_financial_currency_id) !=
                                                                     mgm_imputation_tuple.imm_imm_financial_currency_id then
          --Màj du cours de change
          UpdateExchangeRate( (mgm_imputation_tuple.IMM_AMOUNT_LC_C + mgm_imputation_tuple.IMM_AMOUNT_LC_D)
                           , (mgm_imputation_tuple.IMM_AMOUNT_FC_C + mgm_imputation_tuple.IMM_AMOUNT_FC_D)
                           , nvl(mgm_imputation_tuple.imm_financial_currency_id
                               , mgm_imputation_tuple.imm_imm_financial_currency_id
                                )
                           , exchangeRate
                           , basePrice
                            );
        end if;

        -- recherche d'un id unique pour l'imputation que l'on va créer
        select init_id_seq.nextval
          into new_mgm_imp_id
          from dual;

/*          raise_application_error(-20000,
                                  'Currency : '||to_char(mgm_imputation_tuple.imm_financial_currency_id)||
                                  'Currency2 : '||to_char(mgm_imputation_tuple.imm_imm_financial_currency_id)||
                                  'Period : '||to_char(mgm_imputation_tuple.imm_period_id)||
                                  'CPN Account : '||to_char(mgm_imputation_tuple.ACS_CPN_ACCOUNT_ID)||
                                  'TYPE : '||mgm_imputation_tuple.IMM_TYPE||
                                  'GENRE : '||mgm_imputation_tuple.IMM_GENRE||
                                  'Descr : '||mgm_imputation_tuple.IMM_DESCRIPTION);
*/
        insert into ACT_MGM_IMPUTATION
                    (ACT_MGM_IMPUTATION_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , ACS_PERIOD_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACT_DOCUMENT_ID
                   , IMM_TYPE
                   , IMM_GENRE
                   , IMM_PRIMARY
                   , IMM_DESCRIPTION
                   , IMM_AMOUNT_LC_D
                   , IMM_AMOUNT_LC_C
                   , IMM_EXCHANGE_RATE
                   , IMM_BASE_PRICE
                   , IMM_AMOUNT_FC_D
                   , IMM_AMOUNT_FC_C
                   , IMM_AMOUNT_EUR_D
                   , IMM_AMOUNT_EUR_C
                   , IMM_QUANTITY_D
                   , IMM_QUANTITY_C
                   , IMM_VALUE_DATE
                   , IMM_TRANSACTION_DATE
                   , IMM_TEXT1
                   , IMM_TEXT2
                   , IMM_TEXT3
                   , IMM_TEXT4
                   , IMM_TEXT5
                   , IMM_DATE1
                   , IMM_DATE2
                   , IMM_DATE3
                   , IMM_DATE4
                   , IMM_DATE5
                   , IMM_NUMBER
                   , IMM_NUMBER2
                   , IMM_NUMBER3
                   , IMM_NUMBER4
                   , IMM_NUMBER5
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , GCO_GOOD_ID
                   , DOC_RECORD_ID
                   , HRM_PERSON_ID
                   , PAC_PERSON_ID
                   , FAM_FIXED_ASSETS_ID
                   , C_FAM_TRANSACTION_TYP
                   , ACS_QTY_UNIT_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (new_mgm_imp_id
                   , nvl(mgm_imputation_tuple.imm_financial_currency_id
                       , mgm_imputation_tuple.imm_imm_financial_currency_id
                        )
                   , mgm_imputation_tuple.imm_imm_financial_currency_id
                   , mgm_imputation_tuple.imm_period_id
                   , mgm_imputation_tuple.acs_cpn_account_id
                   , mgm_imputation_tuple.acs_cda_account_id
                   , mgm_imputation_tuple.acs_pf_account_id
                   , new_document_id
                   , mgm_imputation_tuple.IMM_TYPE
                   , mgm_imputation_tuple.IMM_GENRE
                   , mgm_imputation_tuple.IMM_PRIMARY
                   , mgm_imputation_tuple.IMM_DESCRIPTION
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_LC_D, 0)
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_LC_C, 0)
                   , exchangeRate
                   , basePrice
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_FC_D, 0)
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_FC_C, 0)
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_EUR_D, 0)
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_EUR_C, 0)
                   , nvl(mgm_imputation_tuple.IMM_QUANTITY_D, 0)
                   , nvl(mgm_imputation_tuple.IMM_QUANTITY_C, 0)
                   , mgm_imputation_tuple.IMM_VALUE_DATE
                   , mgm_imputation_tuple.IMM_TRANSACTION_DATE
                   , mgm_imputation_tuple.IMM_TEXT1
                   , mgm_imputation_tuple.IMM_TEXT2
                   , mgm_imputation_tuple.IMM_TEXT3
                   , mgm_imputation_tuple.IMM_TEXT4
                   , mgm_imputation_tuple.IMM_TEXT5
                   , mgm_imputation_tuple.IMM_DATE1
                   , mgm_imputation_tuple.IMM_DATE2
                   , mgm_imputation_tuple.IMM_DATE3
                   , mgm_imputation_tuple.IMM_DATE4
                   , mgm_imputation_tuple.IMM_DATE5
                   , mgm_imputation_tuple.IMM_NUMBER
                   , mgm_imputation_tuple.IMM_NUMBER2
                   , mgm_imputation_tuple.IMM_NUMBER3
                   , mgm_imputation_tuple.IMM_NUMBER4
                   , mgm_imputation_tuple.IMM_NUMBER5
                   , mgm_imputation_tuple.DIC_IMP_FREE1_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE2_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE3_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE4_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE5_ID
                   , mgm_imputation_tuple.GCO_GOOD_ID
                   , mgm_imputation_tuple.DOC_RECORD_ID
                   , mgm_imputation_tuple.HRM_PERSON_ID
                   , mgm_imputation_tuple.PAC_PERSON_ID
                   , mgm_imputation_tuple.FAM_FIXED_ASSETS_ID
                   , mgm_imputation_tuple.C_FAM_TRANSACTION_TYP
                   , mgm_imputation_tuple.ACS_QTY_UNIT_ID
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        -- si on a un compte projet, on crée la distribution financière
        if mgm_imputation_tuple.acs_pj_account_id is not null then
          -- mise à jour des montants en monnaie étrangère si elle est utilisée
          if not mgm_imputation_tuple.imm_financial_currency_id = mgm_imputation_tuple.imm_imm_financial_currency_id then
            mgm_amount_fc_c  := mgm_imputation_tuple.IMM_AMOUNT_FC_C;
            mgm_amount_fc_d  := mgm_imputation_tuple.IMM_AMOUNT_FC_D;
          end if;

          Recover_Mgm_Distrib(new_mgm_imp_id
                            , mgm_imputation_tuple.IMM_DESCRIPTION
                            , mgm_imputation_tuple.IMM_AMOUNT_LC_D
                            , mgm_amount_fc_d
                            , mgm_imputation_tuple.IMM_AMOUNT_EUR_D
                            , mgm_imputation_tuple.IMM_AMOUNT_LC_C
                            , mgm_amount_fc_c
                            , mgm_imputation_tuple.IMM_AMOUNT_EUR_C
                            , mgm_imputation_tuple.IMM_QUANTITY_D
                            , mgm_imputation_tuple.IMM_QUANTITY_C
                            , mgm_imputation_tuple.IMM_TEXT1
                            , mgm_imputation_tuple.IMM_TEXT2
                            , mgm_imputation_tuple.IMM_TEXT3
                            , mgm_imputation_tuple.IMM_TEXT4
                            , mgm_imputation_tuple.IMM_TEXT5
                            , mgm_imputation_tuple.IMM_DATE1
                            , mgm_imputation_tuple.IMM_DATE2
                            , mgm_imputation_tuple.IMM_DATE3
                            , mgm_imputation_tuple.IMM_DATE4
                            , mgm_imputation_tuple.IMM_DATE5
                            , mgm_imputation_tuple.IMM_NUMBER
                            , mgm_imputation_tuple.IMM_NUMBER2
                            , mgm_imputation_tuple.IMM_NUMBER3
                            , mgm_imputation_tuple.IMM_NUMBER4
                            , mgm_imputation_tuple.IMM_NUMBER5
                            , mgm_imputation_tuple.acs_pj_account_id
                             );
        end if;
      end if;
    end loop;
  end Recover_Mgm_Imp_Detail;

  /**
  * Description
  *    reprise cumulée des imputations analytiques sans relations
  *    avec les imputations financières
  */
  procedure Recover_Mgm_Imp_Cumul(
    document_id           in number
  , new_document_id       in number
  , financial_year_id     in number
  , pos_zero              in number
  , catalogue_document_id in number
  )
  is
    cursor mgm_imputation(document_id number, managed_info ACT_IMP_MANAGEMENT.IInfoImputationBaseRecType)
    is
      select   IMM_TYPE
             , IMM_GENRE
             , IMM_PRIMARY
             , min(IMM_DESCRIPTION) IMM_DESCRIPTION
             , sum(nvl(IMM_AMOUNT_LC_D, 0) ) IMM_AMOUNT_LC_D
             , sum(nvl(IMM_AMOUNT_LC_C, 0) ) IMM_AMOUNT_LC_C
             , nvl(IMM_EXCHANGE_RATE, 0) IMM_EXCHANGE_RATE
             , nvl(IMM_BASE_PRICE, 0) IMM_BASE_PRICE
             , sum(nvl(IMM_AMOUNT_FC_D, 0) ) IMM_AMOUNT_FC_D
             , sum(nvl(IMM_AMOUNT_FC_C, 0) ) IMM_AMOUNT_FC_C
             , sum(nvl(IMM_AMOUNT_EUR_D, 0) ) IMM_AMOUNT_EUR_D
             , sum(nvl(IMM_AMOUNT_EUR_C, 0) ) IMM_AMOUNT_EUR_C
             , sum(nvl(IMM_QUANTITY_D, 0) ) IMM_QUANTITY_D
             , sum(nvl(IMM_QUANTITY_C, 0) ) IMM_QUANTITY_C
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMM_FINANCIAL_CURRENCY_ID
             , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMM_IMM_FINANCIAL_CURRENCY_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , ACI_MGM_IMPUTATION.ACS_PERIOD_ID IMM_PERIOD_ID
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1) IMM_TEXT1
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2) IMM_TEXT2
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3) IMM_TEXT3
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4) IMM_TEXT4
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5) IMM_TEXT5
             , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1) IMM_DATE1
             , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2) IMM_DATE2
             , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3) IMM_DATE3
             , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4) IMM_DATE4
             , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5) IMM_DATE5
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER) IMM_NUMBER
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2) IMM_NUMBER2
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3) IMM_NUMBER3
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4) IMM_NUMBER4
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5) IMM_NUMBER5
             , decode(managed_info.DICO1.managed, 0, null, 1, DIC_IMP_FREE1_ID) DIC_IMP_FREE1_ID
             , decode(managed_info.DICO2.managed, 0, null, 1, DIC_IMP_FREE2_ID) DIC_IMP_FREE2_ID
             , decode(managed_info.DICO3.managed, 0, null, 1, DIC_IMP_FREE3_ID) DIC_IMP_FREE3_ID
             , decode(managed_info.DICO4.managed, 0, null, 1, DIC_IMP_FREE4_ID) DIC_IMP_FREE4_ID
             , decode(managed_info.DICO5.managed, 0, null, 1, DIC_IMP_FREE5_ID) DIC_IMP_FREE5_ID
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, GCO_GOOD_ID) GCO_GOOD_ID
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, DOC_RECORD_ID) DOC_RECORD_ID
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, HRM_PERSON_ID) HRM_PERSON_ID
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, PAC_PERSON_ID) PAC_PERSON_ID
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, FAM_FIXED_ASSETS_ID) FAM_FIXED_ASSETS_ID
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, C_FAM_TRANSACTION_TYP)
                                                                                                  C_FAM_TRANSACTION_TYP
          from ACI_MGM_IMPUTATION
         where ACI_MGM_IMPUTATION.ACI_DOCUMENT_ID = document_id
           and ACI_FINANCIAL_IMPUTATION_ID is null
      group by IMM_TYPE
             , IMM_GENRE
             , IMM_PRIMARY
             , nvl(IMM_EXCHANGE_RATE, 0)
             , nvl(IMM_BASE_PRICE, 0)
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
             , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , ACI_MGM_IMPUTATION.ACS_PERIOD_ID
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1)
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2)
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3)
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4)
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5)
             , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1)
             , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2)
             , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3)
             , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4)
             , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5)
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER)
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2)
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3)
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4)
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5)
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE1_ID)
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE2_ID)
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE3_ID)
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE4_ID)
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE5_ID)
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.DOC_RECORD_ID)
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.GCO_GOOD_ID)
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.HRM_PERSON_ID)
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.PAC_PERSON_ID)
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID)
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, ACI_MGM_IMPUTATION.C_FAM_TRANSACTION_TYP);

    new_mgm_imp_id         ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    mgm_amount_fc_d        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type          default 0;
    mgm_amount_fc_c        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type          default 0;
    exchangeRate           ACI_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type;
    basePrice              ACI_MGM_IMPUTATION.IMM_BASE_PRICE%type;
    roundCurrency          ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type;
    InfoImputationManaged  ACT_IMP_MANAGEMENT.InfoImputationRecType;
    IInfoImputationManaged ACT_IMP_MANAGEMENT.IInfoImputationRecType;
  begin
    -- recherche des info géreé pour le catalogue et conversion des boolean en integer pour la commande SQL
    InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
    ACT_IMP_MANAGEMENT.ConvertManagedValuesToInt(InfoImputationManaged, IInfoImputationManaged);

    -- pour toutes les imputations financières
    for mgm_imputation_tuple in mgm_imputation(document_id, IInfoImputationManaged.primary) loop
      -- message d'erreur s'il n'y a pas de période valide dans l'interface
      if mgm_imputation_tuple.imm_period_id is null then
        raise_application_error(-20011, 'PCS - No valid financial period in the mgm imputation interface');
      end if;

      -- Ecriture reportée seulement si les montants ne sont pas nuls ou que l'on reprend les positions à 0
      if    (   mgm_imputation_tuple.IMM_AMOUNT_LC_D <> 0
             or mgm_imputation_tuple.IMM_AMOUNT_LC_C <> 0
             or mgm_imputation_tuple.IMM_AMOUNT_FC_D <> 0
             or mgm_imputation_tuple.IMM_AMOUNT_FC_C <> 0
            )
         or pos_zero = 1 then
        exchangeRate  := mgm_imputation_tuple.IMM_EXCHANGE_RATE;
        basePrice     := mgm_imputation_tuple.IMM_BASE_PRICE;

        if nvl(mgm_imputation_tuple.imm_financial_currency_id, mgm_imputation_tuple.imm_imm_financial_currency_id) !=
                                                                     mgm_imputation_tuple.imm_imm_financial_currency_id then
          --Màj du cours de change
          UpdateExchangeRate( (mgm_imputation_tuple.IMM_AMOUNT_LC_C + mgm_imputation_tuple.IMM_AMOUNT_LC_D)
                           , (mgm_imputation_tuple.IMM_AMOUNT_FC_C + mgm_imputation_tuple.IMM_AMOUNT_FC_D)
                           , nvl(mgm_imputation_tuple.imm_financial_currency_id
                               , mgm_imputation_tuple.imm_imm_financial_currency_id
                                )
                           , exchangeRate
                           , basePrice
                            );
        end if;

        select init_id_seq.nextval
          into new_mgm_imp_id
          from dual;

        insert into ACT_MGM_IMPUTATION
                    (ACT_MGM_IMPUTATION_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , ACS_PERIOD_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACT_DOCUMENT_ID
                   , IMM_TYPE
                   , IMM_GENRE
                   , IMM_PRIMARY
                   , IMM_DESCRIPTION
                   , IMM_AMOUNT_LC_D
                   , IMM_AMOUNT_LC_C
                   , IMM_EXCHANGE_RATE
                   , IMM_BASE_PRICE
                   , IMM_AMOUNT_FC_D
                   , IMM_AMOUNT_FC_C
                   , IMM_AMOUNT_EUR_D
                   , IMM_AMOUNT_EUR_C
                   , IMM_QUANTITY_D
                   , IMM_QUANTITY_C
                   , IMM_VALUE_DATE
                   , IMM_TRANSACTION_DATE
                   , ACS_QTY_UNIT_ID
                   , IMM_TEXT1
                   , IMM_TEXT2
                   , IMM_TEXT3
                   , IMM_TEXT4
                   , IMM_TEXT5
                   , IMM_DATE1
                   , IMM_DATE2
                   , IMM_DATE3
                   , IMM_DATE4
                   , IMM_DATE5
                   , IMM_NUMBER
                   , IMM_NUMBER2
                   , IMM_NUMBER3
                   , IMM_NUMBER4
                   , IMM_NUMBER5
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , GCO_GOOD_ID
                   , DOC_RECORD_ID
                   , HRM_PERSON_ID
                   , PAC_PERSON_ID
                   , FAM_FIXED_ASSETS_ID
                   , C_FAM_TRANSACTION_TYP
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (new_mgm_imp_id
                   , nvl(mgm_imputation_tuple.imm_financial_currency_id
                       , mgm_imputation_tuple.imm_imm_financial_currency_id
                        )
                   , mgm_imputation_tuple.imm_imm_financial_currency_id
                   , mgm_imputation_tuple.imm_period_id
                   , mgm_imputation_tuple.acs_cpn_account_id
                   , mgm_imputation_tuple.acs_cda_account_id
                   , mgm_imputation_tuple.acs_pf_account_id
                   , new_document_id
                   , mgm_imputation_tuple.IMM_TYPE
                   , mgm_imputation_tuple.IMM_GENRE
                   , mgm_imputation_tuple.IMM_PRIMARY
                   , mgm_imputation_tuple.IMM_DESCRIPTION
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_LC_D, 0)
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_LC_C, 0)
                   , exchangeRate
                   , basePrice
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_FC_D, 0)
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_FC_C, 0)
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_EUR_D, 0)
                   , nvl(mgm_imputation_tuple.IMM_AMOUNT_EUR_C, 0)
                   , nvl(mgm_imputation_tuple.IMM_QUANTITY_D, 0)
                   , nvl(mgm_imputation_tuple.IMM_QUANTITY_C, 0)
                   , mgm_imputation_tuple.IMM_VALUE_DATE
                   , mgm_imputation_tuple.IMM_TRANSACTION_DATE
                   , mgm_imputation_tuple.ACS_QTY_UNIT_ID
                   , mgm_imputation_tuple.IMM_TEXT1
                   , mgm_imputation_tuple.IMM_TEXT2
                   , mgm_imputation_tuple.IMM_TEXT3
                   , mgm_imputation_tuple.IMM_TEXT4
                   , mgm_imputation_tuple.IMM_TEXT5
                   , mgm_imputation_tuple.IMM_DATE1
                   , mgm_imputation_tuple.IMM_DATE2
                   , mgm_imputation_tuple.IMM_DATE3
                   , mgm_imputation_tuple.IMM_DATE4
                   , mgm_imputation_tuple.IMM_DATE5
                   , mgm_imputation_tuple.IMM_NUMBER
                   , mgm_imputation_tuple.IMM_NUMBER2
                   , mgm_imputation_tuple.IMM_NUMBER3
                   , mgm_imputation_tuple.IMM_NUMBER4
                   , mgm_imputation_tuple.IMM_NUMBER5
                   , mgm_imputation_tuple.DIC_IMP_FREE1_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE2_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE3_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE4_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE5_ID
                   , mgm_imputation_tuple.GCO_GOOD_ID
                   , mgm_imputation_tuple.DOC_RECORD_ID
                   , mgm_imputation_tuple.HRM_PERSON_ID
                   , mgm_imputation_tuple.PAC_PERSON_ID
                   , mgm_imputation_tuple.FAM_FIXED_ASSETS_ID
                   , mgm_imputation_tuple.C_FAM_TRANSACTION_TYP
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        -- si on a un compte projet, on crée la distribution financière
        if mgm_imputation_tuple.acs_pj_account_id is not null then
          -- mise à jour des montants en monnaie étrangère si elle est utilisée
          if not mgm_imputation_tuple.imm_financial_currency_id = mgm_imputation_tuple.imm_imm_financial_currency_id then
            mgm_amount_fc_d  := mgm_imputation_tuple.IMM_AMOUNT_FC_D;
            mgm_amount_fc_c  := mgm_imputation_tuple.IMM_AMOUNT_FC_C;
          end if;

          Recover_Mgm_Distrib(new_mgm_imp_id
                            , mgm_imputation_tuple.IMM_DESCRIPTION
                            , mgm_imputation_tuple.IMM_AMOUNT_LC_D
                            , mgm_amount_fc_d
                            , mgm_imputation_tuple.IMM_AMOUNT_EUR_D
                            , mgm_imputation_tuple.IMM_AMOUNT_LC_C
                            , mgm_amount_fc_c
                            , mgm_imputation_tuple.IMM_AMOUNT_EUR_C
                            , mgm_imputation_tuple.IMM_QUANTITY_D
                            , mgm_imputation_tuple.IMM_QUANTITY_C
                            , mgm_imputation_tuple.IMM_TEXT1
                            , mgm_imputation_tuple.IMM_TEXT2
                            , mgm_imputation_tuple.IMM_TEXT3
                            , mgm_imputation_tuple.IMM_TEXT4
                            , mgm_imputation_tuple.IMM_TEXT5
                            , mgm_imputation_tuple.IMM_DATE1
                            , mgm_imputation_tuple.IMM_DATE2
                            , mgm_imputation_tuple.IMM_DATE3
                            , mgm_imputation_tuple.IMM_DATE4
                            , mgm_imputation_tuple.IMM_DATE5
                            , mgm_imputation_tuple.IMM_NUMBER
                            , mgm_imputation_tuple.IMM_NUMBER2
                            , mgm_imputation_tuple.IMM_NUMBER3
                            , mgm_imputation_tuple.IMM_NUMBER4
                            , mgm_imputation_tuple.IMM_NUMBER5
                            , mgm_imputation_tuple.acs_pj_account_id
                             );
        end if;
      end if;
    end loop;
  end Recover_Mgm_Imp_Cumul;

  /**
  * Description
  *   Reprise cumulée des imputations analytiques sans relations avec les imputations financières
  *   avec cumul débit-crédit
  */
  procedure Recover_Mgm_Imp_Cumul_Group(
    document_id           in number
  , new_document_id       in number
  , financial_year_id     in number
  , pos_zero              in number
  , catalogue_document_id in number
  )
  is
    cursor mgm_imputation(document_id number, managed_info ACT_IMP_MANAGEMENT.IInfoImputationBaseRecType)
    is
      select   IMM_TYPE
             , IMM_GENRE
             , IMM_PRIMARY
             , IMM_DESCRIPTION
             , sum(nvl(IMM_AMOUNT_LC_D, 0) - nvl(IMM_AMOUNT_LC_C, 0) ) IMM_AMOUNT_LC
             , nvl(IMM_EXCHANGE_RATE, 0) IMM_EXCHANGE_RATE
             , nvl(IMM_BASE_PRICE, 0) IMM_BASE_PRICE
             , sum(nvl(IMM_AMOUNT_FC_D, 0) - nvl(IMM_AMOUNT_FC_C, 0) ) IMM_AMOUNT_FC
             , sum(nvl(IMM_AMOUNT_EUR_D, 0) - nvl(IMM_AMOUNT_EUR_C, 0) ) IMM_AMOUNT_EUR
             , sum(nvl(IMM_QUANTITY_D, 0) ) - sum(nvl(IMM_QUANTITY_C, 0) ) IMM_QUANTITY
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID IMM_FINANCIAL_CURRENCY_ID
             , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID IMM_IMM_FINANCIAL_CURRENCY_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , ACI_MGM_IMPUTATION.ACS_PERIOD_ID IMM_PERIOD_ID
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1) IMM_TEXT1
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2) IMM_TEXT2
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3) IMM_TEXT3
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4) IMM_TEXT4
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5) IMM_TEXT5
             , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1) IMM_DATE1
             , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2) IMM_DATE2
             , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3) IMM_DATE3
             , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4) IMM_DATE4
             , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5) IMM_DATE5
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER) IMM_NUMBER
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2) IMM_NUMBER2
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3) IMM_NUMBER3
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4) IMM_NUMBER4
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5) IMM_NUMBER5
             , decode(managed_info.DICO1.managed, 0, null, 1, DIC_IMP_FREE1_ID) DIC_IMP_FREE1_ID
             , decode(managed_info.DICO2.managed, 0, null, 1, DIC_IMP_FREE2_ID) DIC_IMP_FREE2_ID
             , decode(managed_info.DICO3.managed, 0, null, 1, DIC_IMP_FREE3_ID) DIC_IMP_FREE3_ID
             , decode(managed_info.DICO4.managed, 0, null, 1, DIC_IMP_FREE4_ID) DIC_IMP_FREE4_ID
             , decode(managed_info.DICO5.managed, 0, null, 1, DIC_IMP_FREE5_ID) DIC_IMP_FREE5_ID
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, GCO_GOOD_ID) GCO_GOOD_ID
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, DOC_RECORD_ID) DOC_RECORD_ID
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, HRM_PERSON_ID) HRM_PERSON_ID
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, PAC_PERSON_ID) PAC_PERSON_ID
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, FAM_FIXED_ASSETS_ID) FAM_FIXED_ASSETS_ID
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, C_FAM_TRANSACTION_TYP)
                                                                                                  C_FAM_TRANSACTION_TYP
          from ACI_MGM_IMPUTATION
         where ACI_MGM_IMPUTATION.ACI_DOCUMENT_ID = document_id
           and ACI_FINANCIAL_IMPUTATION_ID is null
      group by IMM_TYPE
             , IMM_GENRE
             , IMM_PRIMARY
             , IMM_DESCRIPTION
             , nvl(IMM_EXCHANGE_RATE, 0)
             , nvl(IMM_BASE_PRICE, 0)
             , IMM_VALUE_DATE
             , IMM_TRANSACTION_DATE
             , ACI_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
             , ACI_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , ACI_MGM_IMPUTATION.ACS_PERIOD_ID
             , decode(managed_info.TEXT1.managed, 0, null, 1, IMM_TEXT1)
             , decode(managed_info.TEXT2.managed, 0, null, 1, IMM_TEXT2)
             , decode(managed_info.TEXT3.managed, 0, null, 1, IMM_TEXT3)
             , decode(managed_info.TEXT4.managed, 0, null, 1, IMM_TEXT4)
             , decode(managed_info.TEXT5.managed, 0, null, 1, IMM_TEXT5)
             , decode(managed_info.DATE1.managed, 0, null, 1, IMM_DATE1)
             , decode(managed_info.DATE2.managed, 0, null, 1, IMM_DATE2)
             , decode(managed_info.DATE3.managed, 0, null, 1, IMM_DATE3)
             , decode(managed_info.DATE4.managed, 0, null, 1, IMM_DATE4)
             , decode(managed_info.DATE5.managed, 0, null, 1, IMM_DATE5)
             , decode(managed_info.NUMBER1.managed, 0, null, 1, IMM_NUMBER)
             , decode(managed_info.NUMBER2.managed, 0, null, 1, IMM_NUMBER2)
             , decode(managed_info.NUMBER3.managed, 0, null, 1, IMM_NUMBER3)
             , decode(managed_info.NUMBER4.managed, 0, null, 1, IMM_NUMBER4)
             , decode(managed_info.NUMBER5.managed, 0, null, 1, IMM_NUMBER5)
             , decode(managed_info.DICO1.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE1_ID)
             , decode(managed_info.DICO2.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE2_ID)
             , decode(managed_info.DICO3.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE3_ID)
             , decode(managed_info.DICO4.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE4_ID)
             , decode(managed_info.DICO5.managed, 0, null, 1, ACI_MGM_IMPUTATION.DIC_IMP_FREE5_ID)
             , decode(managed_info.DOC_RECORD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.DOC_RECORD_ID)
             , decode(managed_info.GCO_GOOD_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.GCO_GOOD_ID)
             , decode(managed_info.HRM_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.HRM_PERSON_ID)
             , decode(managed_info.PAC_PERSON_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.PAC_PERSON_ID)
             , decode(managed_info.FAM_FIXED_ASSETS_ID.managed, 0, null, 1, ACI_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID)
             , decode(managed_info.C_FAM_TRANSACTION_TYP.managed, 0, null, 1, ACI_MGM_IMPUTATION.C_FAM_TRANSACTION_TYP);

    new_mgm_imp_id         ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    imm_descr              ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type;
    mgm_amount_lc_d        ACI_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type          default 0;
    mgm_amount_lc_c        ACI_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type          default 0;
    mgm_amount_fc_d        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type          default 0;
    mgm_amount_fc_c        ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type          default 0;
    mgm_amount_eur_d       ACI_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type         default 0;
    mgm_amount_eur_c       ACI_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type         default 0;
    mgm_quantity_d         ACI_MGM_IMPUTATION.IMM_QUANTITY_C%type           default 0;
    mgm_quantity_c         ACI_MGM_IMPUTATION.IMM_QUANTITY_C%type           default 0;
    exchangeRate           ACI_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type;
    basePrice              ACI_MGM_IMPUTATION.IMM_BASE_PRICE%type;
    roundCurrency          ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type;
    InfoImputationManaged  ACT_IMP_MANAGEMENT.InfoImputationRecType;
    IInfoImputationManaged ACT_IMP_MANAGEMENT.IInfoImputationRecType;
  begin
    -- recherche des info géreé pour le catalogue et conversion des boolean en integer pour la commande SQL
    InfoImputationManaged  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
    ACT_IMP_MANAGEMENT.ConvertManagedValuesToInt(InfoImputationManaged, IInfoImputationManaged);

    -- recherche la descreiption de l'imputation primaire qui sera utilisée
    -- comme description de toutes les imputations cumulées
    select max(IMM_DESCRIPTION)
      into imm_descr
      from ACI_MGM_IMPUTATION
     where ACI_DOCUMENT_ID = document_id
       and IMM_PRIMARY = 1;

    -- pour toutes les imputations financières
    for mgm_imputation_tuple in mgm_imputation(document_id, IInfoImputationManaged.primary) loop
      -- message d'erreur s'il n'y a pas de période valide dans l'interface
      if mgm_imputation_tuple.imm_period_id is null then
        raise_application_error(-20011, 'PCS - No valid financial period in the mgm imputation interface');
      end if;

      -- Ecriture reportée seulement si les montants ne sont pas nuls ou que l'on reprend les positions à 0
      if    (   mgm_imputation_tuple.IMM_AMOUNT_LC <> 0
             or mgm_imputation_tuple.IMM_AMOUNT_LC <> 0
             or mgm_imputation_tuple.IMM_AMOUNT_FC <> 0
             or mgm_imputation_tuple.IMM_AMOUNT_FC <> 0
            )
         or pos_zero = 1 then
        -- Recherche si les montants sont débit ou crédit
        select decode(sign(mgm_imputation_tuple.IMM_AMOUNT_LC), 1, mgm_imputation_tuple.IMM_AMOUNT_LC, 0)
          into mgm_amount_lc_d
          from dual;

        select decode(sign(mgm_imputation_tuple.IMM_AMOUNT_LC), -1, -mgm_imputation_tuple.IMM_AMOUNT_LC, 0)
          into mgm_amount_lc_c
          from dual;

        select decode(sign(mgm_imputation_tuple.IMM_AMOUNT_FC), 1, mgm_imputation_tuple.IMM_AMOUNT_FC, 0)
          into mgm_amount_fc_d
          from dual;

        select decode(sign(mgm_imputation_tuple.IMM_AMOUNT_FC), -1, -mgm_imputation_tuple.IMM_AMOUNT_FC, 0)
          into mgm_amount_fc_c
          from dual;

        select decode(sign(mgm_imputation_tuple.IMM_AMOUNT_EUR), 1, mgm_imputation_tuple.IMM_AMOUNT_EUR, 0)
          into mgm_amount_eur_d
          from dual;

        select decode(sign(mgm_imputation_tuple.IMM_AMOUNT_EUR), -1, -mgm_imputation_tuple.IMM_AMOUNT_EUR, 0)
          into mgm_amount_eur_c
          from dual;

        select decode(sign(mgm_imputation_tuple.IMM_QUANTITY), 1, mgm_imputation_tuple.IMM_QUANTITY, 0)
          into mgm_quantity_d
          from dual;

        select decode(sign(mgm_imputation_tuple.IMM_QUANTITY), -1, -mgm_imputation_tuple.IMM_QUANTITY, 0)
          into mgm_quantity_c
          from dual;

        exchangeRate  := mgm_imputation_tuple.IMM_EXCHANGE_RATE;
        basePrice     := mgm_imputation_tuple.IMM_BASE_PRICE;

        if nvl(mgm_imputation_tuple.imm_financial_currency_id, mgm_imputation_tuple.imm_imm_financial_currency_id) !=
                                                                      mgm_imputation_tuple.imm_imm_financial_currency_id then
          --Màj du cours de change
          UpdateExchangeRate( (mgm_amount_lc_c + mgm_amount_lc_d)
                           , (mgm_amount_fc_c + mgm_amount_fc_d)
                           , nvl(mgm_imputation_tuple.imm_financial_currency_id
                               , mgm_imputation_tuple.imm_imm_financial_currency_id
                                )
                           , exchangeRate
                           , basePrice
                            );
        end if;

        select init_id_seq.nextval
          into new_mgm_imp_id
          from dual;

        insert into ACT_MGM_IMPUTATION
                    (ACT_MGM_IMPUTATION_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , ACS_PERIOD_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACT_DOCUMENT_ID
                   , IMM_TYPE
                   , IMM_GENRE
                   , IMM_PRIMARY
                   , IMM_DESCRIPTION
                   , IMM_AMOUNT_LC_D
                   , IMM_AMOUNT_LC_C
                   , IMM_EXCHANGE_RATE
                   , IMM_BASE_PRICE
                   , IMM_AMOUNT_FC_D
                   , IMM_AMOUNT_FC_C
                   , IMM_AMOUNT_EUR_D
                   , IMM_AMOUNT_EUR_C
                   , IMM_QUANTITY_D
                   , IMM_QUANTITY_C
                   , IMM_VALUE_DATE
                   , IMM_TRANSACTION_DATE
                   , ACS_QTY_UNIT_ID
                   , IMM_TEXT1
                   , IMM_TEXT2
                   , IMM_TEXT3
                   , IMM_TEXT4
                   , IMM_TEXT5
                   , IMM_DATE1
                   , IMM_DATE2
                   , IMM_DATE3
                   , IMM_DATE4
                   , IMM_DATE5
                   , IMM_NUMBER
                   , IMM_NUMBER2
                   , IMM_NUMBER3
                   , IMM_NUMBER4
                   , IMM_NUMBER5
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , GCO_GOOD_ID
                   , DOC_RECORD_ID
                   , HRM_PERSON_ID
                   , PAC_PERSON_ID
                   , FAM_FIXED_ASSETS_ID
                   , C_FAM_TRANSACTION_TYP
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (new_mgm_imp_id
                   , mgm_imputation_tuple.imm_financial_currency_id
                   , mgm_imputation_tuple.imm_imm_financial_currency_id
                   , mgm_imputation_tuple.imm_period_id
                   , mgm_imputation_tuple.acs_cpn_account_id
                   , mgm_imputation_tuple.acs_cda_account_id
                   , mgm_imputation_tuple.acs_pf_account_id
                   , new_document_id
                   , mgm_imputation_tuple.IMM_TYPE
                   , mgm_imputation_tuple.IMM_GENRE
                   , mgm_imputation_tuple.IMM_PRIMARY
                   , mgm_imputation_tuple.IMM_DESCRIPTION
                   , nvl(mgm_amount_lc_d, 0)
                   , nvl(mgm_amount_lc_c, 0)
                   , exchangeRate
                   , basePrice
                   , nvl(mgm_amount_fc_d, 0)
                   , nvl(mgm_amount_lc_c, 0)
                   , nvl(mgm_amount_eur_d, 0)
                   , nvl(mgm_amount_eur_c, 0)
                   , nvl(mgm_quantity_d, 0)
                   , nvl(mgm_quantity_c, 0)
                   , mgm_imputation_tuple.IMM_VALUE_DATE
                   , mgm_imputation_tuple.IMM_TRANSACTION_DATE
                   , mgm_imputation_tuple.ACS_QTY_UNIT_ID
                   , mgm_imputation_tuple.IMM_TEXT1
                   , mgm_imputation_tuple.IMM_TEXT2
                   , mgm_imputation_tuple.IMM_TEXT3
                   , mgm_imputation_tuple.IMM_TEXT4
                   , mgm_imputation_tuple.IMM_TEXT5
                   , mgm_imputation_tuple.IMM_DATE1
                   , mgm_imputation_tuple.IMM_DATE2
                   , mgm_imputation_tuple.IMM_DATE3
                   , mgm_imputation_tuple.IMM_DATE4
                   , mgm_imputation_tuple.IMM_DATE5
                   , mgm_imputation_tuple.IMM_NUMBER
                   , mgm_imputation_tuple.IMM_NUMBER2
                   , mgm_imputation_tuple.IMM_NUMBER3
                   , mgm_imputation_tuple.IMM_NUMBER4
                   , mgm_imputation_tuple.IMM_NUMBER5
                   , mgm_imputation_tuple.DIC_IMP_FREE1_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE2_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE3_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE4_ID
                   , mgm_imputation_tuple.DIC_IMP_FREE5_ID
                   , mgm_imputation_tuple.GCO_GOOD_ID
                   , mgm_imputation_tuple.DOC_RECORD_ID
                   , mgm_imputation_tuple.HRM_PERSON_ID
                   , mgm_imputation_tuple.PAC_PERSON_ID
                   , mgm_imputation_tuple.FAM_FIXED_ASSETS_ID
                   , mgm_imputation_tuple.C_FAM_TRANSACTION_TYP
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        -- si on a un compte projet, on crée la distribution financière
        if mgm_imputation_tuple.acs_pj_account_id is not null then
          Recover_Mgm_Distrib(new_mgm_imp_id
                            , imm_descr
                            , mgm_amount_lc_d
                            , mgm_amount_fc_d
                            , mgm_amount_eur_d
                            , mgm_amount_lc_c
                            , mgm_amount_fc_c
                            , mgm_amount_eur_c
                            , mgm_quantity_d
                            , mgm_quantity_c
                            , mgm_imputation_tuple.IMM_TEXT1
                            , mgm_imputation_tuple.IMM_TEXT2
                            , mgm_imputation_tuple.IMM_TEXT3
                            , mgm_imputation_tuple.IMM_TEXT4
                            , mgm_imputation_tuple.IMM_TEXT5
                            , mgm_imputation_tuple.IMM_DATE1
                            , mgm_imputation_tuple.IMM_DATE2
                            , mgm_imputation_tuple.IMM_DATE3
                            , mgm_imputation_tuple.IMM_DATE4
                            , mgm_imputation_tuple.IMM_DATE5
                            , mgm_imputation_tuple.IMM_NUMBER
                            , mgm_imputation_tuple.IMM_NUMBER2
                            , mgm_imputation_tuple.IMM_NUMBER3
                            , mgm_imputation_tuple.IMM_NUMBER4
                            , mgm_imputation_tuple.IMM_NUMBER5
                            , mgm_imputation_tuple.acs_pj_account_id
                             );
        end if;
      end if;
    end loop;
  end Recover_Mgm_Imp_Cumul_Group;

  /**
  * Description
  *    reprise des distributions financières
  */
  procedure Recover_Fin_Distrib(
    financial_imputation_id in number
  , description             in varchar2
  , amount_lc_d             in number
  , amount_fc_d             in number
  , amount_eur_d            in number
  , amount_lc_c             in number
  , amount_fc_c             in number
  , amount_eur_c            in number
  , division_account_id     in number
  )
  is
    sub_set_id ACS_SUB_SET.ACS_SUB_SET_ID%type;
  begin
    -- recherche de acs_sub_set_id à partir du compte division
    select ACS_SUB_SET_ID
      into sub_set_id
      from ACS_ACCOUNT
     where ACS_ACCOUNT_ID = division_account_id;

    -- création de la distribution financière
    insert into ACT_FINANCIAL_DISTRIBUTION
                (ACT_FINANCIAL_DISTRIBUTION_ID
               , ACT_FINANCIAL_IMPUTATION_ID
               , FIN_DESCRIPTION
               , FIN_AMOUNT_LC_D
               , FIN_AMOUNT_FC_D
               , FIN_AMOUNT_EUR_D
               , FIN_AMOUNT_LC_C
               , FIN_AMOUNT_FC_C
               , FIN_AMOUNT_EUR_C
               , ACS_SUB_SET_ID
               , ACS_DIVISION_ACCOUNT_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , financial_imputation_id
               , description
               , nvl(amount_lc_d, 0)
               , nvl(amount_fc_d, 0)
               , nvl(amount_eur_d, 0)
               , nvl(amount_lc_c, 0)
               , nvl(amount_fc_c, 0)
               , nvl(amount_eur_c, 0)
               , sub_set_id
               , division_account_id
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end Recover_Fin_Distrib;

  /*
  * Description
  *    reprise des distributions financières
  */
  procedure Recover_Mgm_Distrib(
    mgm_imputation_id in number
  , description       in varchar2
  , amount_lc_d       in number
  , amount_fc_d       in number
  , amount_eur_d      in number
  , amount_lc_c       in number
  , amount_fc_c       in number
  , amount_eur_c      in number
  , quantity_d        in number
  , quantity_c        in number
  , TEXT1             in varchar2
  , TEXT2             in varchar2
  , TEXT3             in varchar2
  , TEXT4             in varchar2
  , TEXT5             in varchar2
  , date1             in date
  , date2             in date
  , date3             in date
  , date4             in date
  , date5             in date
  , number1           in number
  , number2           in number
  , number3           in number
  , number4           in number
  , number5           in number
  , pj_account_id     in number
  )
  is
    sub_set_id ACS_SUB_SET.ACS_SUB_SET_ID%type;
  begin
    -- recherche de acs_sub_set_id à partir du compte division
    select ACS_SUB_SET_ID
      into sub_set_id
      from ACS_ACCOUNT
     where ACS_ACCOUNT_ID = pj_account_id;

    -- création de la distribution financière
    insert into ACT_MGM_DISTRIBUTION
                (ACT_MGM_DISTRIBUTION_ID
               , ACT_MGM_IMPUTATION_ID
               , MGM_DESCRIPTION
               , MGM_AMOUNT_LC_D
               , MGM_AMOUNT_FC_D
               , MGM_AMOUNT_EUR_D
               , MGM_AMOUNT_LC_C
               , MGM_AMOUNT_FC_C
               , MGM_AMOUNT_EUR_C
               , MGM_QUANTITY_D
               , MGM_QUANTITY_C
               , MGM_TEXT1
               , MGM_TEXT2
               , MGM_TEXT3
               , MGM_TEXT4
               , MGM_TEXT5
               , MGM_NUMBER
               , MGM_NUMBER2
               , MGM_NUMBER3
               , MGM_NUMBER4
               , MGM_NUMBER5
               , ACS_SUB_SET_ID
               , ACS_PJ_ACCOUNT_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , mgm_imputation_id
               , description
               , nvl(amount_lc_d, 0)
               , nvl(amount_fc_d, 0)
               , nvl(amount_eur_d, 0)
               , nvl(amount_lc_c, 0)
               , nvl(amount_fc_c, 0)
               , nvl(amount_eur_c, 0)
               , nvl(quantity_d, 0)
               , nvl(quantity_c, 0)
               , text1
               , text2
               , text3
               , text4
               , text5
               , number1
               , number2
               , number3
               , number4
               , number5
               , sub_set_id
               , pj_account_id
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end Recover_Mgm_Distrib;

  -- procedure de création du détail TVA
  procedure Recover_Tax_Code(
    fin_imputation_id1 in number
  , fin_imputation_id2 in number
  , aIE                in varchar2
  , exchange_rate      in number
  , liable_amount      in number
  , liable_rate        in number
  , rate_tax           in number
  , vat_amount_lc      in number
  , vat_amount_fc      in number
  , vat_amount_eur     in number
  , vat_tot_amount_lc  in number
  , vat_tot_amount_fc  in number
  , vat_tot_amount_eur in number
  , deductible_rate    in number
  , fin_imp_ded_id     in number
  , tax_code_id        in number
  , reduction          in number
  , base_price         in number
  )
  is
    sub_set_id            ACS_SUB_SET.ACS_SUB_SET_ID%type;
    establishingCalcSheet ACS_TAX_CODE.C_ESTABLISHING_CALC_SHEET%type;
  begin
    -- recherche de acs_sub_set_id à partir du compte division
    select ACS_SUB_SET_ID
         , C_ESTABLISHING_CALC_SHEET
      into sub_set_id
         , establishingCalcSheet
      from ACS_ACCOUNT
         , ACS_TAX_CODE
     where ACS_ACCOUNT_ID = tax_code_id
       and ACS_TAX_CODE_ID = ACS_ACCOUNT_ID;

    insert into ACT_DET_TAX
                (ACT_DET_TAX_ID
               , ACT_FINANCIAL_IMPUTATION_ID
               , TAX_EXCHANGE_RATE
               , TAX_INCLUDED_EXCLUDED
               , TAX_LIABLED_AMOUNT
               , TAX_LIABLED_RATE
               , TAX_RATE
               , TAX_VAT_AMOUNT_FC
               , TAX_VAT_AMOUNT_LC
               , TAX_VAT_AMOUNT_EUR
               , TAX_TOT_VAT_AMOUNT_FC
               , TAX_TOT_VAT_AMOUNT_LC
               , TAX_TOT_VAT_AMOUNT_EUR
               , ACS_SUB_SET_ID
               , ACT_ACT_FINANCIAL_IMPUTATION
               , TAX_REDUCTION
               , DET_BASE_PRICE
               , TAX_TMP_VAT_ENCASHMENT
               , TAX_DEDUCTIBLE_RATE
               , ACT_DED1_FINANCIAL_IMP_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , fin_imputation_id1
               , nvl(exchange_rate, 0)
               , aIE
               , nvl(liable_amount, 0)
               , nvl(liable_rate, 0)
               , rate_tax
               , nvl(vat_amount_fc, 0)
               , nvl(vat_amount_lc, 0)
               , nvl(vat_amount_eur, 0)
               , nvl(vat_tot_amount_fc, 0)
               , nvl(vat_tot_amount_lc, 0)
               , nvl(vat_tot_amount_eur, 0)
               , sub_set_id
               , fin_imputation_id2
               , reduction
               , nvl(base_price, 0)
               , decode(establishingCalcSheet
                      , 2, decode(nvl(PCS.PC_CONFIG.GetConfigUpper('ACT_TAX_VAT_ENCASHMENT'), 'FALSE')
                                , 'FALSE', 0
                                , 'TRUE', 1
                                 )
                      , 0
                       )
               , deductible_rate
               , fin_imp_ded_id
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end Recover_Tax_Code;

  /*
  * Description :
  *   Procédure de création automatique des couvertures
  */
  function Recover_Covering(
    new_document_id           in number
  , pay_catalogue_document_id in number default null
  , pay_document_id           in number default null
  , aACI_DET_PAYMENT_ID       in ACI_DET_PAYMENT.ACI_DET_PAYMENT_ID%type default null
  )
    return ACT_COVER_INFORMATION.ACT_COVER_INFORMATION_ID%type
  is
    cursor cover(act_id number)
    is
      select part.acs_financial_currency_id
           , part.acs_acs_financial_currency_id
           , expi.acs_fin_acc_s_payment_id
           , part.pac_financial_reference_id
           , expi.exp_amount_lc amount_lc
           , decode(part.acs_financial_currency_id
                  , part.acs_acs_financial_currency_id, expi.exp_amount_lc
                  , expi.exp_amount_fc
                   ) amount_fc
           , expi.exp_amount_eur amount_eur
           , act.doc_number || '.' || to_char(exp_slice) cov_number
           , substr(act.doc_number, 1, 10) cov_drawn_ref
           , act.doc_document_date
           , expi.exp_adapted
           , cust.pac_custom_partner_id
           , expi.act_expiry_id
           , (select met.c_type_support
                from acs_payment_method met
               where met.acs_payment_method_id = fin.acs_payment_method_id) c_type_support
           , (select met.c_status_settlement
                from acs_payment_method met
               where met.acs_payment_method_id = fin.acs_payment_method_id) c_status_settlement
        from act_document act
           , act_part_imputation part
           , act_expiry expi
           , pac_custom_partner cust
           , acs_fin_acc_s_payment fin
       where act.act_document_id = act_id
         and part.act_document_id = act.act_document_id
         and expi.act_part_imputation_id = part.act_part_imputation_id
         and part.pac_custom_partner_id = cust.pac_custom_partner_id
         and fin.acs_fin_acc_s_payment_id = expi.acs_fin_acc_s_payment_id
         and fin.pmm_cover_generation = 1
         and expi.exp_calc_net + 0 = 1;

    cursor cover_detpay(act_doc_id number, act_doc_detpay_id number)
    is
      select part.acs_financial_currency_id
           , part.acs_acs_financial_currency_id
           , cat.acs_fin_acc_s_payment_id
           , part.pac_financial_reference_id
           , det.det_paied_lc amount_lc
           , decode(part.acs_financial_currency_id
                  , part.acs_acs_financial_currency_id, det.det_paied_lc
                  , det.det_paied_fc
                   ) amount_fc
           , expi.exp_amount_eur amount_eur
           , act.doc_number || '.' || to_char(exp_slice) cov_number
           , substr(act.doc_number, 1, 10) cov_drawn_ref
           , act.doc_document_date
           , expi.exp_adapted
           , cust.pac_custom_partner_id
           , expi.act_expiry_id
           , (select met.c_type_support
                from acs_payment_method met
               where met.acs_payment_method_id = fin.acs_payment_method_id) c_type_support
           , (select met.c_status_settlement
                from acs_payment_method met
               where met.acs_payment_method_id = fin.acs_payment_method_id) c_status_settlement
        from act_document act
           , act_part_imputation part
           , act_document pay
           , acj_catalogue_document cat
           , act_det_payment det
           , act_expiry expi
           , pac_custom_partner cust
           , acs_fin_acc_s_payment fin
       where act.act_document_id = act_doc_id
         and pay.act_document_id = act_doc_detpay_id
         and pay.acj_catalogue_document_id = cat.acj_catalogue_document_id
         and cat.acs_fin_acc_s_payment_id = fin.acs_fin_acc_s_payment_id
         and fin.pmm_cover_generation = 1
         and part.act_document_id = act.act_document_id
         and expi.act_part_imputation_id = part.act_part_imputation_id
         and part.pac_custom_partner_id = cust.pac_custom_partner_id
         and pay.act_document_id = det.act_document_id
         and det.act_expiry_id = expi.act_expiry_id
         and expi.exp_calc_net + 0 = 1;

    cover_tuple         cover%rowtype;
    vCoverDirectPayment boolean;
    vResult             ACT_COVER_INFORMATION.ACT_COVER_INFORMATION_ID%type;
    vTotAmountLC        ACT_COVER_INFORMATION.COV_AMOUNT_LC%type;
    vTotAmountFC        ACT_COVER_INFORMATION.COV_AMOUNT_FC%type;
    vTotAmountEUR       ACT_COVER_INFORMATION.COV_AMOUNT_EUR%type;
    vCovTerminal        ACT_COVER_INFORMATION.COV_TERMINAL%type               := null;
    vCovTerminalSeq     ACT_COVER_INFORMATION.COV_TERMINAL_SEQ%type           := null;
    vCovTransactionDate ACT_COVER_INFORMATION.COV_TRANSACTION_DATE%type       := null;
  begin
    vCoverDirectPayment  := false;
    vResult              := null;
    vTotAmountLC         := 0;
    vTotAmountFC         := 0;
    vTotAmountEUR        := 0;

    if pay_document_id is null then
      open cover(new_document_id);

      fetch cover
       into cover_tuple;

      if cover%found then
        -- Si ID catalogue paiement -> paiement direct -> une seule couverture pour l'ensemble du document
        if pay_catalogue_document_id is not null then
          vCoverDirectPayment  :=
                                AutoCoverDirectPayment(pay_catalogue_document_id, cover_tuple.acs_fin_acc_s_payment_id);
        end if;
      end if;

      while cover%found loop
        if    vResult is null
           or not vCoverDirectPayment then
          select INIT_ID_SEQ.nextval
            into vResult
            from dual;

          -- Insertion dans la table "Couverture"
          insert into ACT_COVER_INFORMATION
                      (ACT_COVER_INFORMATION_ID
                     , ACS_FINANCIAL_CURRENCY_ID
                     , ACS_ACS_FINANCIAL_CURRENCY_ID
                     , ACS_FIN_ACC_S_PAYMENT_ID
                     , C_STATUS_SETTLEMENT
                     , PAC_FINANCIAL_REFERENCE_ID
                     , COV_AMOUNT_LC
                     , COV_AMOUNT_FC
                     , COV_AMOUNT_EUR
                     , COV_NUMBER
                     , COV_DRAWN_REF
                     , COV_DATE
                     , COV_EXPIRY_DATE
                     , PAC_CUSTOM_PARTNER_ID
                     , COV_DIRECT
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (vResult
                     , cover_tuple.ACS_FINANCIAL_CURRENCY_ID
                     , cover_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , cover_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                     , cover_tuple.C_STATUS_SETTLEMENT
                     , cover_tuple.PAC_FINANCIAL_REFERENCE_ID
                     , nvl(cover_tuple.amount_lc, 0)
                     , nvl(cover_tuple.amount_fc, 0)
                     , nvl(cover_tuple.amount_eur, 0)
                     , cover_tuple.cov_number
                     , cover_tuple.cov_drawn_ref
                     , cover_tuple.doc_document_date
                     , cover_tuple.exp_adapted
                     , cover_tuple.pac_custom_partner_id
                     , 1
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          vTotAmountLC   := nvl(cover_tuple.amount_lc, 0);
          vTotAmountFC   := nvl(cover_tuple.amount_fc, 0);
          vTotAmountEUR  := nvl(cover_tuple.amount_eur, 0);
        else
          vTotAmountLC   := vTotAmountLC + nvl(cover_tuple.amount_lc, 0);
          vTotAmountFC   := vTotAmountFC + nvl(cover_tuple.amount_fc, 0);
          vTotAmountEUR  := vTotAmountEUR + nvl(cover_tuple.amount_eur, 0);
        end if;

        -- Insertion dans la table "Couvre échéance"
        insert into ACT_COVER_S_EXPIRY
                    (ACT_COVER_INFORMATION_ID
                   , ACT_EXPIRY_ID
                    )
             values (INIT_ID_SEQ.currval
                   , cover_tuple.act_expiry_id
                    );

        fetch cover
         into cover_tuple;
      end loop;

      close cover;

      if     vCoverDirectPayment
         and vResult is not null then
        -- Maj montant tot de la couverture
        update ACT_COVER_INFORMATION
           set COV_AMOUNT_LC = vTotAmountLC
             , COV_AMOUNT_FC = vTotAmountFC
             , COV_AMOUNT_EUR = vTotAmountEUR
         where ACT_COVER_INFORMATION_ID = vResult;

        -- On retourne l'id de la couverture créé
        return vResult;
      else
        return null;
      end if;
    else
      open cover_detpay(new_document_id, pay_document_id);

      fetch cover_detpay
       into cover_tuple;

      if cover_detpay%found then
        if nvl(aACI_DET_PAYMENT_ID, 0) > 0 then
          select COV_TERMINAL
               , COV_TERMINAL_SEQ
               , COV_TRANSACTION_DATE
            into vCovTerminal
               , vCovTerminalSeq
               , vCovTransactionDate
            from ACI_DET_PAYMENT
           where ACI_DET_PAYMENT_ID = aACI_DET_PAYMENT_ID;
        end if;

        -- Si ID catalogue paiement -> paiement direct -> une seule couverture pour l'ensemble du document
        if pay_catalogue_document_id is not null then
          vCoverDirectPayment  :=
                                AutoCoverDirectPayment(pay_catalogue_document_id, cover_tuple.acs_fin_acc_s_payment_id);
        end if;
      end if;

      while cover_detpay%found loop
        select INIT_ID_SEQ.nextval
          into vResult
          from dual;

        -- Insertion dans la table "Couverture"
        insert into ACT_COVER_INFORMATION
                    (ACT_COVER_INFORMATION_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , ACS_FIN_ACC_S_PAYMENT_ID
                   , C_STATUS_SETTLEMENT
                   , PAC_FINANCIAL_REFERENCE_ID
                   , COV_AMOUNT_LC
                   , COV_AMOUNT_FC
                   , COV_AMOUNT_EUR
                   , COV_NUMBER
                   , COV_DRAWN_REF
                   , COV_DATE
                   , COV_EXPIRY_DATE
                   , PAC_CUSTOM_PARTNER_ID
                   , COV_DIRECT
                   , COV_TERMINAL
                   , COV_TERMINAL_SEQ
                   , COV_TRANSACTION_DATE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (vResult
                   , cover_tuple.ACS_FINANCIAL_CURRENCY_ID
                   , cover_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID
                   , cover_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                   , cover_tuple.C_STATUS_SETTLEMENT
                   , cover_tuple.PAC_FINANCIAL_REFERENCE_ID
                   , nvl(cover_tuple.amount_lc, 0)
                   , nvl(cover_tuple.amount_fc, 0)
                   , nvl(cover_tuple.amount_eur, 0)
                   , cover_tuple.cov_number
                   , cover_tuple.cov_drawn_ref
                   , cover_tuple.doc_document_date
                   , cover_tuple.exp_adapted
                   , cover_tuple.pac_custom_partner_id
                   , 1
                   , case
                       when cover_tuple.c_type_support = '80' then vCovTerminal
                       else null
                     end
                   , case
                       when cover_tuple.c_type_support = '80' then vCovTerminalSeq
                       else null
                     end
                   , case
                       when cover_tuple.c_type_support = '80' then vCovTransactionDate
                       else null
                     end
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        -- Insertion dans la table "Couvre échéance"
        insert into ACT_COVER_S_EXPIRY
                    (ACT_COVER_INFORMATION_ID
                   , ACT_EXPIRY_ID
                    )
             values (INIT_ID_SEQ.currval
                   , cover_tuple.act_expiry_id
                    );

        -- Insertion dans la table des remises de couverture pour les paiements CB (80)
        -- Permet la décharge du document depuis le portefeuille
        if vCoverDirectPayment and (cover_tuple.c_type_support = '80') then
          insert into ACT_COV_INFO_S_DOCUMENT
                      (ACT_COVER_INFORMATION_ID
                     , ACT_DOCUMENT_ID
                      )
               values (vResult
                     , pay_document_id
                      );
        end if;

        fetch cover_detpay
         into cover_tuple;
      end loop;

      close cover_detpay;

      if     vCoverDirectPayment
         and vResult is not null then
        -- Màj lien couverture du document paiement
        update act_document
           set act_cover_information_id = vResult
         where act_document_id = pay_document_id;

        -- On retourne l'id de la couverture créé
        return vResult;
      else
        return null;
      end if;
    end if;
  end Recover_Covering;

  /**
  * Description :
  *   Màj sur le document logistique (COM_EBANKING) de l'ACT_DOCUMENT_ID
  */
  procedure Update_EBPP(aACI_DOCUMENT_ID in number, aACT_DOCUMENT_ID in number)
  is
    vDOC_DOCUMENT_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type   := null;
    vCOM_EBANKING_ID COM_EBANKING.COM_EBANKING_ID%type;
    vComNameDOC      ACI_DOCUMENT.COM_NAME_DOC%type;
    vComNameACT      ACI_DOCUMENT.COM_NAME_ACT%type;
    vSql_code        varchar2(300);
    vDBOwner         PCS.PC_SCRIP.SCRDBOWNER%type        := null;
    vDBLink          PCS.PC_SCRIP.SCRDB_LINK%type        := null;
  begin
    /*Recherche du document logistique dans le document financier*/
    select min(DOC.DOC_DOCUMENT_ID)
         , min(DOC.COM_NAME_DOC)
      into vDOC_DOCUMENT_ID
         , vComNameDOC
      from ACI_DOCUMENT DOC
     where DOC.ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;

    if vDOC_DOCUMENT_ID is not null then
      --Recherche société courante
      select COM_NAME
        into vComNameACT
        from PCS.PC_COMP
       where PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;

      --Recherche des info de connexion si document sur une autre société
      if not(    (vComNameDOC = vComNameACT)
             or vComNameDOC is null) then
        select PC_SCRIP.SCRDBOWNER
             , PC_SCRIP.SCRDB_LINK
          into vDBOwner
             , vDBLink
          from PCS.PC_SCRIP
             , PCS.PC_COMP
         where PC_SCRIP.PC_SCRIP_ID = PC_COMP.PC_SCRIP_ID
           and PC_COMP.COM_NAME = vComNameDOC;

        if vDBLink is not null then
          vDBLink  := '@' || vDBLink;
        end if;

        if vDBOwner is not null then
          vDBOwner  := vDBOwner || '.';
        end if;
      end if;

      --Recherche si màj necessaire
      vSql_code  :=
        'select min(COM_EBANKING_ID) ' ||
        '  from [COMPANY_OWNER_2]COM_EBANKING[COMPANY_DBLINK_2] ' ||
        ' where DOC_DOCUMENT_ID = :DOC_DOCUMENT_ID ';
      vSql_code  := replace(vSql_code, '[COMPANY_OWNER_2]', vDBOwner);
      vSql_code  := replace(vSql_code, '[COMPANY_DBLINK_2]', vDBLink);

      execute immediate vSql_code
                   into vCOM_EBANKING_ID
                  using vDOC_DOCUMENT_ID;

      if vCOM_EBANKING_ID is not null then
        --Màj du document logistique
        vSql_code  :=
          'update [COMPANY_OWNER_2]COM_EBANKING[COMPANY_DBLINK_2] ' ||
          '   set ACT_DOCUMENT_ID = :ACT_DOCUMENT_ID ' ||
          ' where COM_EBANKING_ID = :COM_EBANKING_ID';
        vSql_code  := replace(vSql_code, '[COMPANY_OWNER_2]', vDBOwner);
        vSql_code  := replace(vSql_code, '[COMPANY_DBLINK_2]', vDBLink);

        execute immediate vSql_code
                    using aACT_DOCUMENT_ID, vCOM_EBANKING_ID;


        --Contrôle des données
        vSql_code  :=
          'begin  [COMPANY_OWNER_2]COM_PRC_EBANKING.control_data[COMPANY_DBLINK_2] ' ||
          '   (:COM_EBANKING_ID); end; ';
        vSql_code  := replace(vSql_code, '[COMPANY_OWNER_2]', vDBOwner);
        vSql_code  := replace(vSql_code, '[COMPANY_DBLINK_2]', vDBLink);

        execute immediate vSql_code
                    using vCOM_EBANKING_ID;


      end if;
    end if;
  end Update_EBPP;

END ACT_INTERFACE_RECOVERING;
