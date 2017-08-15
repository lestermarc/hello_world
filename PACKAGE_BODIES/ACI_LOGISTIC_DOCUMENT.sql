--------------------------------------------------------
--  DDL for Package Body ACI_LOGISTIC_DOCUMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_LOGISTIC_DOCUMENT" 
IS

  procedure calcAmounts(
    aForeignCurrencyId        number
  , tax_code_id               number
  , vat_date                  date
  , vat_currency_id           number
  , position_amount           number
  , position_amount_b         number
  , position_amount_e         number
  , position_amount_v         number
  , admin_domain              varchar2
  , gauge_title               varchar2
  , type_catalogue            varchar2
  , pos_include_tax           number
  , amount_lc_c        out    number
  , amount_lc_d        out    number
  , amount_fc_c        out    number
  , amount_fc_d        out    number
  , amount_eur_c       out    number
  , amount_eur_d       out    number
  , taxIE              out    varchar2
  , aRateTax           in     number
  , aLiabledRate       in     number
  , vat_amount_lc      out    number
  , vat_amount_fc      out    number
  , vat_amount_eur     out    number
  , vat_amount_vc      out    number
  , aDeductibleRate    in     number
  , aVatTotAmountLC    out    number
  , aVatTotAmountFC    out    number
  , aVatTotAmountVC    out    number
  )
  is
    taxCode1Id      ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    taxCode2Id      ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    SelfTaxing      boolean;
    Interest        boolean;
    imp_rate_tax    ACS_TAX_CODE.TAX_RATE%type          default 0;
    rate_tax        number;
    liabled_rate    number;
    deductible_rate number;
  begin
    amount_lc_d      := 0;
    amount_fc_d      := 0;
    amount_eur_d     := 0;
    amount_lc_c      := 0;
    amount_fc_c      := 0;
    amount_eur_c     := 0;
    vat_amount_lc    := 0;
    vat_amount_fc    := 0;
    vat_amount_eur   := 0;
    vat_amount_vc    := 0;
    -- valeurs par défaut
    rate_tax         := nvl(aRateTax, 0);
    liabled_rate     := nvl(aLiabledRate, 100);
    deductible_rate  := nvl(aDeductibleRate, 100);

    -- recherche des données TVA
    if tax_code_id is not null then
      -- auto-taxation
      SelfTaxing       := ACS_FUNCTION.IsSelfTax(tax_code_id, taxCode1Id, taxCode2Id);
      -- Taxe pure
      Interest         := ACS_FUNCTION.IsInterest(tax_code_id);

      select nvl(rate_tax, nvl(VAT_RATE, TAX_RATE) )
           , nvl(liabled_rate, TAX_LIABLED_RATE)
           , nvl(deductible_rate, TAX_DEDUCTIBLE_RATE)
        into rate_tax
           , liabled_rate
           , deductible_rate
        from ACS_TAX_CODE
           , (select max(VAT_RATE) VAT_RATE
                from ACS_VAT_RATE
               where ACS_TAX_CODE_ID = tax_code_id
                 and VAT_SINCE <= trunc(vat_date)
                 and VAT_TO >= trunc(vat_date) )
       where ACS_TAX_CODE.ACS_TAX_CODE_ID = tax_code_id;

      rate_tax         := nvl(aRateTax, nvl(rate_tax, 0) );
      liabled_rate     := nvl(aLiabledRate, nvl(liabled_rate, 100) );
      deductible_rate  := nvl(aDeductibleRate, nvl(deductible_rate, 100) );

      if Interest then
        taxIE         := 'I';
        imp_rate_tax  := rate_tax *(liabled_rate / 100) *(deductible_rate / 100);
      elsif SelfTaxing then
        taxIE         := 'S';
        imp_rate_tax  := 0;
      else
        taxIE         := 'E';
        imp_rate_tax  := rate_tax *(liabled_rate / 100) *(deductible_rate / 100);
      end if;
    end if;

    if     pos_include_tax = 0
       and taxIE in('E', 'S') then
      -- mise à jour des montants
      if    (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
             and type_catalogue in('5', '6') )
         or (    admin_domain in(cAdminDomainSale)
             and type_catalogue in('2') )
         or (gauge_title in('5', '6', '8', '30') ) then
        amount_lc_c   := position_amount_b *( (100 + imp_rate_tax) / 100);
        amount_fc_c   := position_amount *( (100 + imp_rate_tax) / 100);
        amount_eur_c  := position_amount_e *( (100 + imp_rate_tax) / 100);
      elsif    (    admin_domain in(cAdminDomainSale)
                and type_catalogue in('5', '6') )
            or (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                and type_catalogue in('2') )
            or (gauge_title in('1', '4', '9') ) then
        amount_lc_d   := position_amount_b *( (100 + imp_rate_tax) / 100);
        amount_fc_d   := position_amount *( (100 + imp_rate_tax) / 100);
        amount_eur_d  := position_amount_e *( (100 + imp_rate_tax) / 100);
      end if;

      vat_amount_fc    := position_amount *(liabled_rate / 100) *(rate_tax / 100) *(deductible_rate / 100);
      vat_amount_eur   := position_amount_e *(liabled_rate / 100) *(rate_tax / 100) *(deductible_rate / 100);
      vat_amount_vc    := position_amount_v *(liabled_rate / 100) *(rate_tax / 100) *(deductible_rate / 100);
      aVatTotAmountFC  := position_amount *(liabled_rate / 100) *(rate_tax / 100);
      aVatTotAmountVC  := position_amount_v *(liabled_rate / 100) *(rate_tax / 100);

      if vat_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
        vat_amount_lc    := vat_amount_vc;
        aVatTotAmountLC  := aVatTotAmountVC;
      else
        vat_amount_lc    := position_amount_b *(liabled_rate / 100) *(rate_tax / 100) *(deductible_rate / 100);
        aVatTotAmountLC  := position_amount_b *(liabled_rate / 100) *(rate_tax / 100);
      end if;
    elsif     Interest
          and taxIe = 'I' then
      -- mise à jour des montants
      if    (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
             and type_catalogue in('5', '6') )
         or (    admin_domain in(cAdminDomainSale)
             and type_catalogue in('2') )
         or (gauge_title in('5', '6', '8', '30') ) then
        amount_lc_c   := position_amount_b;
        amount_fc_c   := position_amount;
        amount_eur_c  := position_amount_e;
      elsif    (    admin_domain in(cAdminDomainSale)
                and type_catalogue in('5', '6') )
            or (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                and type_catalogue in('2') )
            or (gauge_title in('1', '4', '9') ) then
        amount_lc_d   := position_amount_b;
        amount_fc_d   := position_amount;
        amount_eur_d  := position_amount_e;
      end if;

      vat_amount_fc    := position_amount *(deductible_rate / 100);
      vat_amount_eur   := position_amount_e *(deductible_rate / 100);
      vat_amount_vc    := position_amount_v *(deductible_rate / 100);
      aVatTotAmountFC  := position_amount;
      aVatTotAmountVC  := position_amount_v;

      if vat_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
        vat_amount_lc    := vat_amount_vc;
        aVatTotAmountLC  := aVatTotAmountVC;
      else
        vat_amount_lc    := position_amount_b *(deductible_rate / 100);
        aVatTotAmountLC  := position_amount_b;
      end if;
    else
      -- mise à jour des montants
      if    (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
             and type_catalogue in('5', '6') )
         or (    admin_domain in(cAdminDomainSale)
             and type_catalogue in('2') )
         or (gauge_title in('5', '6', '8', '30') ) then
        amount_lc_c   := position_amount_b;
        amount_fc_c   := position_amount;
        amount_eur_c  := position_amount_e;
      elsif    (    admin_domain in(cAdminDomainSale)
                and type_catalogue in('5', '6') )
            or (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                and type_catalogue in('2') )
            or (gauge_title in('1', '4', '9') ) then
        amount_lc_d   := position_amount_b;
        amount_fc_d   := position_amount;
        amount_eur_d  := position_amount_e;
      end if;

      vat_amount_fc    :=
                  position_amount - 100 *
                                    position_amount *
                                    (liabled_rate / 100) *
                                    (deductible_rate / 100) /
                                    (rate_tax + 100);
      vat_amount_eur   :=
              position_amount_e - 100 *
                                  position_amount_e *
                                  (liabled_rate / 100) *
                                  (deductible_rate / 100) /
                                  (rate_tax + 100);
      vat_amount_vc    :=
              position_amount_v - 100 *
                                  position_amount_v *
                                  (liabled_rate / 100) *
                                  (deductible_rate / 100) /
                                  (rate_tax + 100);
      aVatTotAmountFC  := position_amount - 100 * position_amount *(liabled_rate / 100) /(rate_tax + 100);
      aVatTotAmountVC  := position_amount_v - 100 * position_amount_v *(liabled_rate / 100) /(rate_tax + 100);

      if vat_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
        vat_amount_lc    := vat_amount_vc;
        aVatTotAmountLC  := aVatTotAmountVC;
      else
        vat_amount_lc    :=
             position_amount_b - 100 *
                                 position_amount_b *
                                 (liabled_rate / 100) *
                                 (deductible_rate / 100) /
                                 (rate_tax + 100);
        aVatTotAmountLC  := position_amount_b - 100 * position_amount_b *(liabled_rate / 100) /(rate_tax + 100);
      end if;
    end if;

    if    aForeignCurrencyId = ACS_FUNCTION.getLocalCurrencyId
       or nvl(aForeignCurrencyId, 0) = 0 then
      amount_fc_c      := 0;
      amount_fc_d      := 0;
      vat_amount_fc    := 0;
      aVatTotAmountFC  := 0;
    end if;

    -- Correction des signes
    if    amount_lc_d < 0
       or amount_lc_c < 0 then
      if amount_lc_d < 0 then
        -- Si montant débit < 0 : -> insérer le montant au crédit, en positif
        amount_lc_c   := -amount_lc_d;
        amount_fc_c   := -amount_fc_d;
        amount_eur_c  := -amount_eur_d;
        amount_lc_d   := 0;
        amount_fc_d   := 0;
        amount_eur_d  := 0;
      elsif amount_lc_c < 0 then
        -- Si montant crédit < 0 : -> insérer le montant au débit, en positif
        amount_lc_d   := -amount_lc_c;
        amount_fc_d   := -amount_fc_c;
        amount_eur_d  := -amount_eur_c;
        amount_lc_c   := 0;
        amount_fc_c   := 0;
        amount_eur_c  := 0;
      end if;
    end if;
  end calcAmounts;

  procedure getTextRecovering(
    aFinancialAccountId     number
  , aAuxiliaryAccountId     number
  , aDivisionAccountId      number
  , aTaxCodeId              number
  , aCdaAccountId           number
  , aCpnAccountId           number
  , aPfAccountId            number
  , aPjAccountId            number
  , aDocumentCurrencyId     number
  , aDocumentDate           date
  , aGoodID                 number
  , aRecordID               number
  , aHrmPersonId            number
  , aFixedAssetsId          number
  , aPacPersonID            number
  , aQueuing                boolean
  , TextRecoveringRec   out TextRecoveringRecType
  )
  is
  begin
    TextRecoveringRec  := null;

    -- lecture des textes selon  la config de reprise des textes
    if    PCS.PC_CONFIG.GetBooleanConfig('FIN_TEXT_RECOVERING')
       or aQueuing then
      -- recherche du numéro de compte financier
      select max(ACC_NUMBER)
        into TextRecoveringRec.fin_acc_number
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = aFinancialAccountId;

      -- recherche du numéro de compte auxilliaire
      select max(ACC_NUMBER)
        into TextRecoveringRec.aux_acc_number
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = aAuxiliaryAccountId;

      -- recherche du numéro de compte division
      select max(ACC_NUMBER)
        into TextRecoveringRec.div_acc_number
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = aDivisionAccountId;

      -- recherche du numéro de compte TVA
      select max(ACC_NUMBER)
        into TextRecoveringRec.tax_acc_number
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = aTaxCodeId;

      -- recherche du numéro de compte centre d'analyse
      select max(ACC_NUMBER)
        into TextRecoveringRec.cda_acc_number
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = aCdaAccountId;

      -- recherche du numéro de compte charge par nature
      select max(ACC_NUMBER)
        into TextRecoveringRec.cpn_acc_number
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = aCpnAccountId;

      -- recherche du numéro de compte porteur de frais
      select max(ACC_NUMBER)
        into TextRecoveringRec.pf_acc_number
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = aPfAccountId;

      -- recherche du numéro de compte projet
      select max(ACC_NUMBER)
        into TextRecoveringRec.pj_acc_number
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = aPjAccountId;

      -- recherche du nom de la monnaie locale
      TextRecoveringRec.local_currency_name  := ACS_FUNCTION.GetLocalCurrencyName;

      -- recherche de la monnaie du tiers
      select max(CURRENCY)
        into TextRecoveringRec.document_currency_name
        from ACS_FINANCIAL_CURRENCY
           , PCS.PC_CURR
       where ACS_FINANCIAL_CURRENCY.PC_CURR_ID = PC_CURR.PC_CURR_ID
         and ACS_FINANCIAL_CURRENCY_ID = aDocumentCurrencyId;

      -- recherche du  la référence article
      if aGoodID is not null then
        select GOO_MAJOR_REFERENCE
          into TextRecoveringRec.goo_major_reference
          from GCO_GOOD
         where GCO_GOOD_ID = aGoodID;
      end if;

      -- recherche des infos dossier
      if aRecordID is not null then
        select RCO_NUMBER
             , RCO_TITLE
          into TextRecoveringRec.rco_number
             , TextRecoveringRec.rco_title
          from DOC_RECORD
         where DOC_RECORD_ID = aRecordID;
      end if;

      -- recherche du nom de la personne (salaire)
      if aHrmPersonId is not null then
        select EMP_NUMBER
          into TextRecoveringRec.emp_number
          from HRM_PERSON
         where HRM_PERSON_ID = aHrmPersonId;
      end if;

      -- recherche du numéro d'immob
      if aFixedAssetsId is not null then
        select FIX_NUMBER
          into TextRecoveringRec.fix_number
          from FAM_FIXED_ASSETS
         where FAM_FIXED_ASSETS_ID = aFixedAssetsId;
      end if;

      -- recherche des clef de la personne (commerciale)
      if aPacPersonID is not null then
        select PER_KEY1
             , PER_KEY2
          into TextRecoveringRec.per_key1
             , TextRecoveringRec.per_key2
          from PAC_PERSON
         where PAC_PERSON_ID = aPacPersonId;
      end if;

      -- recherche du numéro de période
      TextRecoveringRec.no_period            := ACS_FUNCTION.GetPeriodNo(trunc(aDocumentDate), '2');
    end if;
  end getTextRecovering;

  /**
  * procedure positionChargeImputation
  * Description
  *   procedure de tranfert des taxes dans l'interface comptable
  * @created FP
  * @lastUpdate
  * @private
  * @param new_document_id
  * @param vFinancialCharge
  * @param pos_include_tax
  * @param description
  * @param position_number
  * @param financial_account_id
  * @param division_account_id
  * @param cda_account_id
  * @param cpn_account_id
  * @param pf_account_id
  * @param pj_account_id
  * @param admin_domain
  * @param gauge_title
  * @param type_catalogue
  * @param document_date
  * @param delivery_date
  * @param value_date
  * @param document_currency_id
  * @param tax_code_id
  * @param position_amount
  * @param position_amount_b
  * @param position_amount_e
  * @param charge_amount
  * @param charge_amount_b
  * @param charge_amount_e
  * @param charge_amount_v
  * @param rate_factor
  * @param rate_of_exchange
  * @param vat_rate_factor
  * @param vat_rate_of_exchange
  * @param part_imputation_id
  * @param round_type
  * @param foreign_currency
  * @param record_id
  * @param good_id
  * @param third_id
  * @param person_id
  * @param fixed_assets_id
  * @param fam_transaction_typ
  * @param number1
  * @param number2
  * @param number3
  * @param number4
  * @param number5
  * @param text1
  * @param text2
  * @param text3
  * @param text4
  * @param text5
  * @param date1
  * @param date2
  * @param date3
  * @param date4
  * @param date5
  * @param dic_imp1_id
  * @param dic_imp2_id
  * @param dic_imp3_id
  * @param dic_imp4_id
  * @param dic_imp5_id
  * @param lc_vat_amount
  * @param fc_vat_amount
  * @param eur_vat_amount
  * @param vc_vat_amount
  * @param vat_currency_id
  * @param anal_charge
  * @param financial_charge
  * @param aQueuing   : indique si on déplace le document dans une queue XML
  */
  procedure positionChargeImputation(
    new_document_id      in     number
  , aFinancialCharge     in     varchar2
  , pos_include_tax      in     number
  , description          in     varchar2
  , position_number      in     number
  , financial_account_id in     number
  , division_account_id  in     number
  , cda_account_id       in     number
  , cpn_account_id       in     number
  , pf_account_id        in     number
  , pj_account_id        in     number
  , admin_domain         in     varchar2
  , gauge_title          in     varchar2
  , type_catalogue       in     varchar2
  , document_date        in     date
  , delivery_date        in     date
  , value_date           in     date
  , document_currency_id in     number
  , tax_code_id          in     number
  , position_amount      in     number
  , position_amount_b    in     number
  , position_amount_e    in     number
  , charge_amount        in     number
  , charge_amount_b      in     number
  , charge_amount_e      in     number
  , charge_amount_v      in     number
  , rate_factor          in     number
  , rate_of_exchange     in     number
  , vat_rate_factor      in     number
  , vat_rate_of_exchange in     number
  , part_imputation_id   in     number
  , round_type           in     varchar2
  , foreign_currency     in     number
  , record_id            in     number
  , good_id              in     number
  , third_id             in     number
  , person_id            in     number
  , fixed_assets_id      in     number
  , fam_transaction_typ  in     varchar2
  , number1              in     number
  , number2              in     number
  , number3              in     number
  , number4              in     number
  , number5              in     number
  , text1                in     varchar2
  , text2                in     varchar2
  , text3                in     varchar2
  , text4                in     varchar2
  , text5                in     varchar2
  , date1                in     date
  , date2                in     date
  , date3                in     date
  , date4                in     date
  , date5                in     date
  , dic_imp1_id          in     varchar2
  , dic_imp2_id          in     varchar2
  , dic_imp3_id          in     varchar2
  , dic_imp4_id          in     varchar2
  , dic_imp5_id          in     varchar2
  , aRateTax             in     ACS_TAX_CODE.TAX_RATE%type
  , aLiabledRate         in     ACI_FINANCIAL_IMPUTATION.TAX_LIABLED_RATE%type
  , lc_vat_amount        out    number
  , fc_vat_amount        out    number
  , eur_vat_amount       out    number
  , vc_vat_amount        out    number
  , aDeductibleRate      in     ACI_FINANCIAL_IMPUTATION.TAX_DEDUCTIBLE_RATE%type
  , aVatTotAmountLC      out    number
  , aVatTotAmountFC      out    number
  , aVatTotAmountVC      out    number
  , vat_currency_id      in     number
  , financial_charge     in     number
  , anal_charge          in     number
  , aQueuing             in     boolean
  , main_imputation_id   in out number
  )
  is
    amount_lc_d          ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    amount_fc_d          ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    amount_eur_d         ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    amount_lc_c          ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    amount_fc_c          ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    amount_eur_c         ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vat_amount_lc        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type;
    vat_amount_fc        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type;
    vat_amount_eur       ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_EUR%type;
    vat_amount_vc        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type;
    liable_amount        ACI_FINANCIAL_IMPUTATION.TAX_LIABLED_AMOUNT%type            default 0;
    charge_imputation_id ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
    taxIE                varchar2(1);
    TextRecoveringRec    TextRecoveringRecType;
    main_amount          ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
  begin
    if aFinancialCharge = '02' then   -- remises
      calcAmounts(foreign_currency
                , tax_code_id
                , nvl(delivery_date, document_date)
                , vat_currency_id
                , charge_amount
                , charge_amount_b
                , charge_amount_e
                , charge_amount_v
                , admin_domain
                , gauge_title
                , type_catalogue
                , pos_include_tax
                , amount_lc_d
                , amount_lc_c
                , amount_fc_d
                , amount_fc_c
                , amount_eur_d
                , amount_eur_c
                , taxIE
                , aRateTax
                , aLiabledRate
                , vat_amount_lc
                , vat_amount_fc
                , vat_amount_eur
                , vat_amount_vc
                , aDeductibleRate
                , aVatTotAmountLC
                , aVatTotAmountFC
                , aVatTotAmountVC
                 );
    else
      calcAmounts(foreign_currency
                , tax_code_id
                , nvl(delivery_date, document_date)
                , vat_currency_id
                , charge_amount
                , charge_amount_b
                , charge_amount_e
                , charge_amount_v
                , admin_domain
                , gauge_title
                , type_catalogue
                , pos_include_tax
                , amount_lc_c
                , amount_lc_d
                , amount_fc_c
                , amount_fc_d
                , amount_eur_c
                , amount_eur_d
                , taxIE
                , aRateTax
                , aLiabledRate
                , vat_amount_lc
                , vat_amount_fc
                , vat_amount_eur
                , vat_amount_vc
                , aDeductibleRate
                , aVatTotAmountLC
                , aVatTotAmountFC
                , aVatTotAmountVC
                 );
    end if;

    -- lecture des textes selon  la config de reprise des textes
    getTextRecovering(financial_account_id
                    , null
                    , division_account_id
                    , tax_code_id
                    , cda_account_id
                    , cpn_account_id
                    , pf_account_id
                    , pj_account_id
                    , document_currency_id
                    , document_date
                    , good_id
                    , record_id
                    , person_id
                    , fixed_assets_id
                    , third_id
                    , aQueuing
                    , TextRecoveringRec
                     );

    if financial_charge = 1 then
      select ACI_ID_SEQ.nextval
        into charge_imputation_id
        from dual;

      -- creation de l'imputation financiere pour la taxe
      insert into ACI_FINANCIAL_IMPUTATION
                  (ACI_FINANCIAL_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , ACI_PART_IMPUTATION_ID
                 , IMF_PRIMARY
                 , IMF_TYPE
                 , IMF_GENRE
                 , TAX_INCLUDED_EXCLUDED
                 , C_GENRE_TRANSACTION
                 , IMF_DESCRIPTION
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACC_NUMBER
                 , ACS_DIVISION_ACCOUNT_ID
                 , DIV_NUMBER
                 , IMF_AMOUNT_LC_D
                 , IMF_AMOUNT_FC_D
                 , IMF_AMOUNT_EUR_D
                 , IMF_AMOUNT_LC_C
                 , IMF_AMOUNT_FC_C
                 , IMF_AMOUNT_EUR_C
                 , ACS_TAX_CODE_ID
                 , TAX_NUMBER
                 , IMF_VALUE_DATE
                 , IMF_TRANSACTION_DATE
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , IMF_EXCHANGE_RATE
                 , IMF_BASE_PRICE
                 , TAX_EXCHANGE_RATE
                 , DET_BASE_PRICE
                 , TAX_RATE
                 , TAX_LIABLED_AMOUNT
                 , TAX_LIABLED_RATE
                 , TAX_VAT_AMOUNT_LC
                 , TAX_VAT_AMOUNT_FC
                 , TAX_VAT_AMOUNT_EUR
                 , TAX_VAT_AMOUNT_VC
                 , TAX_REDUCTION
                 , DOC_RECORD_ID
                 , RCO_NUMBER
                 , RCO_TITLE
                 , GCO_GOOD_ID
                 , GOO_MAJOR_REFERENCE
                 , PAC_PERSON_ID
                 , PER_KEY1
                 , PER_KEY2
                 , HRM_PERSON_ID
                 , FAM_FIXED_ASSETS_ID
                 , FIX_NUMBER
                 , C_FAM_TRANSACTION_TYP
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
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (charge_imputation_id
                 , new_document_id
                 , part_imputation_id
                 , 0
                 , 'MAN'
                 , 'STD'
                 , taxIE
                 , '1'
                 , substr(description, 1, 100)
                 , financial_account_id
                 , TextRecoveringRec.fin_acc_number
                 , division_account_id
                 , TextRecoveringRec.div_acc_number
                 , amount_lc_d
                 , amount_fc_d
                 , amount_eur_d
                 , amount_lc_c
                 , amount_fc_c
                 , amount_eur_c
                 , tax_code_id
                 , TextRecoveringRec.tax_acc_number
                 , trunc(nvl(delivery_date, value_date) )
                 , trunc(document_date)
                 , ACS_FUNCTION.GetPeriodId(trunc(document_date), '2')
                 , TextRecoveringRec.no_period
                 , document_currency_id
                 , TextRecoveringRec.document_currency_name
                 , ACS_FUNCTION.GetLocalCurrencyId
                 , TextRecoveringRec.local_currency_name
                 , rate_of_exchange
                 , rate_factor
                 , vat_rate_of_exchange
                 , vat_rate_factor
                 , aRateTax
                 , abs(amount_lc_d + amount_lc_c) - decode(taxIE, 'E', abs(vat_amount_lc), 0)
                 , aLiabledRate
                 , abs(vat_amount_lc)
                 , abs(vat_amount_fc)
                 , abs(vat_amount_eur)
                 , abs(vat_amount_vc)
                 , 0
                 , record_id
                 , TextRecoveringRec.rco_number
                 , TextRecoveringRec.rco_title
                 , good_id
                 , TextRecoveringRec.goo_major_reference
                 , third_id
                 , TextRecoveringRec.per_key1
                 , TextRecoveringRec.per_key2
                 , person_id
                 , fixed_assets_id
                 , TextRecoveringRec.fix_number
                 , fam_transaction_typ
                 , position_number
                 , number2
                 , number3
                 , number4
                 , number5
                 , text1
                 , text2
                 , text3
                 , text4
                 , text5
                 , date1
                 , date2
                 , date3
                 , date4
                 , date5
                 , dic_imp1_id
                 , dic_imp2_id
                 , dic_imp3_id
                 , dic_imp4_id
                 , dic_imp5_id
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;

    -- si l'imputation principale est vide, on prend celle de la remise/taxes
    select abs(imf_amount_lc_c + imf_amount_lc_d)
      into main_amount
      from ACI_FINANCIAL_IMPUTATION
     where ACI_FINANCIAL_IMPUTATION_ID = main_imputation_id;

    if main_amount < abs(amount_lc_c + amount_lc_d) then
      main_imputation_id  := charge_imputation_id;
    end if;

    select decode(taxIE, 'S', 0, vat_amount_lc)
         , decode(taxIE, 'S', 0, vat_amount_fc)
         , decode(taxIE, 'S', 0, vat_amount_vc)
      into lc_vat_amount
         , fc_vat_amount
         , vc_vat_amount
      from dual;

    if     anal_charge = 1
       and (   cda_account_id is not null
            or cpn_account_id is not null
            or pf_account_id is not null
            or pj_account_id is not null
           ) then
      insert into ACI_MGM_IMPUTATION
                  (ACI_MGM_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , ACI_FINANCIAL_IMPUTATION_ID
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
                 , IMM_VALUE_DATE
                 , IMM_TRANSACTION_DATE
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , ACS_CDA_ACCOUNT_ID
                 , CDA_NUMBER
                 , ACS_CPN_ACCOUNT_ID
                 , CPN_NUMBER
                 , ACS_PF_ACCOUNT_ID
                 , PF_NUMBER
                 , ACS_PJ_ACCOUNT_ID
                 , PJ_NUMBER
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , DOC_RECORD_ID
                 , RCO_NUMBER
                 , RCO_TITLE
                 , GCO_GOOD_ID
                 , GOO_MAJOR_REFERENCE
                 , PAC_PERSON_ID
                 , PER_KEY1
                 , PER_KEY2
                 , HRM_PERSON_ID
                 , FAM_FIXED_ASSETS_ID
                 , FIX_NUMBER
                 , C_FAM_TRANSACTION_TYP
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
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aci_id_seq.nextval
                 , new_document_id
                 , charge_imputation_id
                 , 'MAN'
                 , 'STD'
                 , 0
                 , substr(description, 1, 100)
                 , amount_lc_d - decode(taxIE, 'S', 0, 'I', 0, decode(amount_lc_d, 0, 0, abs(vat_amount_lc) ) )
                 , amount_lc_c - decode(taxIE, 'S', 0, 'I', 0, decode(amount_lc_c, 0, 0, abs(vat_amount_lc) ) )
                 , rate_of_exchange
                 , rate_factor
                 , amount_fc_d - decode(taxIE, 'S', 0, 'I', 0, decode(amount_fc_d, 0, 0, abs(vat_amount_fc) ) )
                 , amount_fc_c - decode(taxIE, 'S', 0, 'I', 0, decode(amount_fc_c, 0, 0, abs(vat_amount_fc) ) )
                 , amount_eur_d - decode(taxIE, 'S', 0, 'I', 0, decode(amount_eur_d, 0, 0, abs(vat_amount_eur) ) )
                 , amount_eur_c - decode(taxIE, 'S', 0, 'I', 0, decode(amount_eur_c, 0, 0, abs(vat_amount_eur) ) )
                 , trunc(value_date)
                 , trunc(document_date)
                 , document_currency_id
                 , TextRecoveringRec.document_currency_name
                 , ACS_FUNCTION.GetLocalCurrencyId
                 , TextRecoveringRec.local_currency_name
                 , cda_account_id
                 , TextRecoveringRec.cda_acc_number
                 , cpn_account_id
                 , TextRecoveringRec.cpn_acc_number
                 , pf_account_id
                 , TextRecoveringRec.pf_acc_number
                 , pj_account_id
                 , TextRecoveringRec.pj_acc_number
                 , ACS_FUNCTION.GetPeriodId(trunc(document_date), '2')
                 , TextRecoveringRec.no_period
                 , record_id
                 , TextRecoveringRec.rco_number
                 , TextRecoveringRec.rco_title
                 , good_id
                 , TextRecoveringRec.goo_major_reference
                 , third_id
                 , TextRecoveringRec.per_key1
                 , TextRecoveringRec.per_key2
                 , person_id
                 , fixed_assets_id
                 , TextRecoveringRec.fix_number
                 , fam_transaction_typ
                 , number1
                 , number2
                 , number3
                 , number4
                 , number5
                 , text1
                 , text2
                 , text3
                 , text4
                 , text5
                 , date1
                 , date2
                 , date3
                 , date4
                 , date5
                 , dic_imp1_id
                 , dic_imp2_id
                 , dic_imp3_id
                 , dic_imp4_id
                 , dic_imp5_id
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end PositionChargeImputation;

  /**
  * procedure footImputation
  * Description
  *    procedure de transfert des remises/taxes de pied dans l'interface comptable
  * @created FP
  * @lastUpdate
  * @private
  * @param new_document_id
  * @param includeTaxTariff  1=TTC ou 0=HT
  * @param aCFinancialCharge
  * @param description
  * @param foot_excl_amount
  * @param foot_excl_amount_b
  * @param foot_excl_amount_e
  * @param foot_incl_amount
  * @param foot_incl_amount_b
  * @param foot_incl_amount_e
  * @param foot_vat_amount
  * @param foot_vat_amount_b
  * @param foot_vat_amount_e
  * @param foot_vat_amount_v
  * @param financial_account_id
  * @param division_account_id
  * @param cda_account_id
  * @param cpn_account_id
  * @param pf_account_id
  * @param pj_account_id
  * @param admin_domain
  * @param gauge_title
  * @param type_catalogue
  * @param document_date
  * @param delivery_date
  * @param value_date
  * @param document_currency_id
  * @param tax_code_id
  * @param rate_factor
  * @param rate_of_exchange
  * @param vat_rate_factor
  * @param vat_rate_of_exchange
  * @param part_imputation_id
  * @param round_type
  * @param foreign_currency
  * @param financial_charge
  * @param anal_charge
  * @param record_id
  * @param third_id
  * @param person_id
  * @param fixed_assets_id
  * @param fam_transaction_typ
  * @param number1
  * @param number2
  * @param number3
  * @param number4
  * @param number5
  * @param text1
  * @param text2
  * @param text3
  * @param text4
  * @param text5
  * @param date1
  * @param date2
  * @param date3
  * @param date4
  * @param date5
  * @param dic_imp1_id
  * @param dic_imp2_id
  * @param dic_imp3_id
  * @param dic_imp4_id
  * @param dic_imp5_id
  */
  procedure footImputation(
    new_document_id       in number
  , includeTaxTariff      in number
  , aCFinancialCharge     in varchar2
  , description           in varchar2
  , foot_excl_amount      in number
  , foot_excl_amount_b    in number
  , foot_excl_amount_e    in number
  , foot_incl_amount      in number
  , foot_incl_amount_b    in number
  , foot_incl_amount_e    in number
  , aRateTax              in ACS_TAX_CODE.TAX_RATE%type
  , aLiabledRate          in ACI_FINANCIAL_IMPUTATION.TAX_LIABLED_RATE%type
  , foot_vat_amount       in number
  , foot_vat_amount_b     in number
  , foot_vat_amount_e     in number
  , foot_vat_amount_v     in number
  , aDeductibleRate       in ACI_FINANCIAL_IMPUTATION.TAX_DEDUCTIBLE_RATE%type
  , aFootVatTotalAmount   in number
  , aFootVatTotalAmount_b in number
  , aFootVatTotalAmount_v in number
  , financial_account_id  in number
  , division_account_id   in number
  , cda_account_id        in number
  , cpn_account_id        in number
  , pf_account_id         in number
  , pj_account_id         in number
  , admin_domain          in varchar2
  , gauge_title           in varchar2
  , type_catalogue        in varchar2
  , document_date         in date
  , delivery_date         in date
  , value_date            in date
  , document_currency_id  in number
  , tax_code_id           in number
  , rate_factor           in number
  , rate_of_exchange      in number
  , vat_rate_factor       in number
  , vat_rate_of_exchange  in number
  , part_imputation_id    in number
  , round_type            in varchar2
  , foreign_currency      in number
  , financial_charge      in number
  , anal_charge           in number
  , record_id             in number
  , third_id              in number
  , person_id             in number
  , fixed_assets_id       in number
  , fam_transaction_typ   in varchar2
  , number1               in number
  , number2               in number
  , number3               in number
  , number4               in number
  , number5               in number
  , text1                 in varchar2
  , text2                 in varchar2
  , text3                 in varchar2
  , text4                 in varchar2
  , text5                 in varchar2
  , date1                 in date
  , date2                 in date
  , date3                 in date
  , date4                 in date
  , date5                 in date
  , dic_imp1_id           in varchar2
  , dic_imp2_id           in varchar2
  , dic_imp3_id           in varchar2
  , dic_imp4_id           in varchar2
  , dic_imp5_id           in varchar2
  , aQueuing              in boolean
  )
  is
    amount_lc_d        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    amount_fc_d        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    amount_eur_d       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    amount_lc_c        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    amount_fc_c        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    amount_eur_c       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vImfAmountLC_D     ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    vImfAmountFC_D     ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    vImfAmountEUR_D    ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    vImfAmountLC_C     ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    vImfAmountFC_C     ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    vImfAmountEUR_C    ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vat_amount_lc      ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type;
    vat_amount_fc      ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type;
    vat_amount_eur     ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_EUR%type;
    vat_amount_vc      ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type;
    vVatTotAmountLC    ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_LC%type;
    vVatTotAmountFC    ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_FC%type;
    vVatTotAmountVC    ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_VC%type;
    rate_tax           ACS_TAX_CODE.TAX_RATE%type                                  default 0;
    imp_rate_tax       ACS_TAX_CODE.TAX_RATE%type                                  default 0;
    liabled_rate       ACS_TAX_CODE.TAX_LIABLED_RATE%type                          default 100;
    discount_rate      ACS_TAX_CODE.TAX_RATE%type;
    main_imputation_id ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
    taxIE              varchar2(1);
    taxCode1Id         ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    taxCode2Id         ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    SelfTaxing         boolean;
    Interest           boolean;
    TextRecoveringRec  TextRecoveringRecType;
  begin
    -- recherche des données TVA
    if tax_code_id is not null then
      -- auto-taxation
      SelfTaxing  := ACS_FUNCTION.IsSelfTax(tax_code_id, taxCode1Id, taxCode2Id);
      -- Taxe pure
      Interest    := ACS_FUNCTION.IsInterest(tax_code_id);

      select nvl(VAT_RATE, TAX_RATE)
           , TAX_LIABLED_RATE
        into rate_tax
           , liabled_rate
        from ACS_TAX_CODE
           , (select max(VAT_RATE) VAT_RATE
                from ACS_VAT_RATE
               where ACS_TAX_CODE_ID = tax_code_id
                 and VAT_SINCE <= trunc(nvl(delivery_date, document_date) )
                 and VAT_TO >= trunc(nvl(delivery_date, document_date) ) )
       where ACS_TAX_CODE.ACS_TAX_CODE_ID = tax_code_id;

      if Interest then
        taxIE         := 'I';
        imp_rate_tax  := (liabled_rate / 100) *(aDeductibleRate / 100);
      elsif SelfTaxing then
        taxIE         := 'S';
        imp_rate_tax  := 0;
      else
        taxIE         := 'E';
        imp_rate_tax  := (liabled_rate / 100) *(aDeductibleRate / 100);
      end if;
    end if;

    if aCFinancialCharge = '02' then
      -- mise à jour des montants
      if    (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
             and type_catalogue in('5', '6') )
         or (    admin_domain in(cAdminDomainSale)
             and type_catalogue in('2') )
         or (gauge_title in('5', '6', '8', '30') ) then
        if foot_excl_amount_b >= 0 then
          amount_lc_d      := foot_excl_amount_b;
          amount_eur_d     := foot_excl_amount_e;
          -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
          amount_fc_d      := foot_excl_amount * foreign_currency;

          if    not interest
             or taxIe = 'S' then
            vImfAmountLC_D   := amount_lc_d + foot_vat_amount_b;
            vImfAmountFC_D   := amount_fc_d + foot_vat_amount;
            vImfAmountEUR_D  := amount_eur_d + foot_vat_amount_e;
          else
            vImfAmountLC_D   := amount_lc_d;
            vImfAmountFC_D   := amount_fc_d;
            vImfAmountEUR_D  := amount_eur_d;
          end if;

          -- mise à 0 des montants au crédit
          amount_lc_c      := 0;
          amount_fc_c      := 0;
          amount_eur_c     := 0;
          vImfAmountLC_C   := 0;
          vImfAmountFC_C   := 0;
          vImfAmountEUR_C  := 0;
        else
          amount_lc_c      := -foot_excl_amount_b;
          amount_eur_c     := -foot_excl_amount_e;
          -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
          amount_fc_c      := -foot_excl_amount * foreign_currency;

          if    not interest
             or taxIe = 'S' then
            vImfAmountLC_C   := amount_lc_c - foot_vat_amount_b;
            vImfAmountFC_C   := amount_fc_c - foot_vat_amount;
            vImfAmountEUR_C  := amount_eur_c - foot_vat_amount_e;
          else
            vImfAmountLC_C   := amount_lc_c;
            vImfAmountFC_C   := amount_fc_c;
            vImfAmountEUR_C  := amount_eur_c;
          end if;

          -- mise à 0 des montants au débit
          amount_lc_d      := 0;
          amount_fc_d      := 0;
          amount_eur_d     := 0;
          vImfAmountLC_D   := 0;
          vImfAmountFC_D   := 0;
          vImfAmountEUR_D  := 0;
        end if;
      elsif    (    admin_domain in(cAdminDomainSale)
                and type_catalogue in('5', '6') )
            or (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                and type_catalogue in('2') )
            or (gauge_title in('1', '4', '9') ) then
        if foot_excl_amount_b >= 0 then
          amount_lc_c      := foot_excl_amount_b;
          amount_eur_c     := foot_excl_amount_e;
          -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
          amount_fc_c      := foot_excl_amount * foreign_currency;

          if    not interest
             or taxIe = 'S' then
            vImfAmountLC_C   := amount_lc_c + foot_vat_amount_b;
            vImfAmountFC_C   := amount_fc_c + foot_vat_amount;
            vImfAmountEUR_C  := amount_eur_c + foot_vat_amount_e;
          else
            vImfAmountLC_C   := amount_lc_c;
            vImfAmountFC_C   := amount_fc_c;
            vImfAmountEUR_C  := amount_eur_c;
          end if;

          -- mise à 0 des montants au débit
          amount_lc_d      := 0;
          amount_fc_d      := 0;
          amount_eur_d     := 0;
          vImfAmountLC_D   := 0;
          vImfAmountFC_D   := 0;
          vImfAmountEUR_D  := 0;
        else
          amount_lc_d      := -foot_excl_amount_b;
          amount_eur_d     := -foot_excl_amount_e;
          -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
          amount_fc_d      := -foot_excl_amount * foreign_currency;

          if    not interest
             or taxIe = 'S' then
            vImfAmountLC_D   := amount_lc_d - foot_vat_amount_b;
            vImfAmountFC_D   := amount_fc_d - foot_vat_amount;
            vImfAmountEUR_D  := amount_eur_d - foot_vat_amount_e;
          else
            vImfAmountLC_D   := amount_lc_c;
            vImfAmountFC_D   := amount_fc_c;
            vImfAmountEUR_D  := amount_eur_c;
          end if;

          -- mise à 0 des montants au débit
          amount_lc_c      := 0;
          amount_fc_c      := 0;
          amount_eur_c     := 0;
          vImfAmountLC_C   := 0;
          vImfAmountFC_C   := 0;
          vImfAmountEUR_C  := 0;
        end if;
      end if;
    else
      -- mise à jour des montants
      if    (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
             and type_catalogue in('5', '6') )
         or (    admin_domain in(cAdminDomainSale)
             and type_catalogue in('2') )
         or (gauge_title in('5', '6', '8', '30') ) then
        if foot_excl_amount_b >= 0 then
          amount_lc_c      := foot_excl_amount_b;
          amount_eur_c     := foot_excl_amount_e;
          -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
          amount_fc_c      := foot_excl_amount * foreign_currency;

          if    not interest
             or taxIe = 'S' then
            vImfAmountLC_C   := amount_lc_c + foot_vat_amount_b;
            vImfAmountFC_C   := amount_fc_c + foot_vat_amount;
            vImfAmountEUR_C  := amount_eur_c + foot_vat_amount_e;
          else
            vImfAmountLC_C   := amount_lc_c;
            vImfAmountFC_C   := amount_fc_c;
            vImfAmountEUR_C  := amount_eur_c;
          end if;

          -- mise à 0 des montants au crédit
          amount_lc_d      := 0;
          amount_fc_d      := 0;
          amount_eur_d     := 0;
          vImfAmountLC_D   := 0;
          vImfAmountFC_D   := 0;
          vImfAmountEUR_D  := 0;
        else
          amount_lc_d      := -foot_excl_amount_b;
          amount_eur_d     := -foot_excl_amount_e;
          -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
          amount_fc_d      := -foot_excl_amount * foreign_currency;

          if    not interest
             or taxIe = 'S' then
            vImfAmountLC_D   := amount_lc_d - foot_vat_amount_b;
            vImfAmountFC_D   := amount_fc_d - foot_vat_amount;
            vImfAmountEUR_D  := amount_eur_d - foot_vat_amount_e;
          else
            vImfAmountLC_D   := amount_lc_d;
            vImfAmountFC_D   := amount_fc_d;
            vImfAmountEUR_D  := amount_eur_d;
          end if;

          -- mise à 0 des montants au débit
          amount_lc_c      := 0;
          amount_fc_c      := 0;
          amount_eur_c     := 0;
          vImfAmountLC_C   := 0;
          vImfAmountFC_C   := 0;
          vImfAmountEUR_C  := 0;
        end if;
      elsif    (    admin_domain in(cAdminDomainSale)
                and type_catalogue in('5', '6') )
            or (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                and type_catalogue in('2') )
            or (gauge_title in('1', '4', '9') ) then
        if foot_excl_amount_b >= 0 then
          amount_lc_d      := foot_excl_amount_b;
          amount_eur_d     := foot_excl_amount_e;
          -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
          amount_fc_d      := foot_excl_amount * foreign_currency;

          if    not interest
             or taxIe = 'S' then
            vImfAmountLC_D   := amount_lc_d + foot_vat_amount_b;
            vImfAmountFC_D   := amount_fc_d + foot_vat_amount;
            vImfAmountEUR_D  := amount_eur_d + foot_vat_amount_e;
          else
            vImfAmountLC_D   := amount_lc_d;
            vImfAmountFC_D   := amount_fc_d;
            vImfAmountEUR_D  := amount_eur_d;
          end if;

          -- mise à 0 des montants au débit
          amount_lc_c      := 0;
          amount_fc_c      := 0;
          amount_eur_c     := 0;
          vImfAmountLC_C   := 0;
          vImfAmountFC_C   := 0;
          vImfAmountEUR_C  := 0;
        else
          amount_lc_c      := -foot_excl_amount_b;
          amount_eur_c     := -foot_excl_amount_e;
          -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
          amount_fc_c      := -foot_excl_amount * foreign_currency;

          if    not interest
             or taxIe = 'S' then
            vImfAmountLC_C   := amount_lc_c - foot_vat_amount_b;
            vImfAmountFC_C   := amount_fc_c - foot_vat_amount;
            vImfAmountEUR_C  := amount_eur_c - foot_vat_amount_e;
          else
            vImfAmountLC_C   := amount_lc_c;
            vImfAmountFC_C   := amount_fc_c;
            vImfAmountEUR_C  := amount_eur_c;
          end if;

          -- mise à 0 des montants au crédit
          amount_lc_d      := 0;
          amount_fc_d      := 0;
          amount_eur_d     := 0;
          vImfAmountLC_D   := 0;
          vImfAmountFC_D   := 0;
          vImfAmountEUR_D  := 0;
        end if;
      end if;
    end if;

    -- calcul de la TVA si on est en mode auto-taxation car elle est à 0 sur le document logistique
    -- ce qui est faux en finance
    if     Interest
       and taxIe = 'I' then
      vat_amount_lc    := (amount_lc_c + amount_lc_d) *(aDeductibleRate / 100);
      vat_amount_fc    := (amount_fc_c + amount_fc_d) *(aDeductibleRate / 100);
      vat_amount_eur   := (amount_eur_c + amount_eur_d) *(aDeductibleRate / 100);
      vVatTotAmountLC  :=(amount_lc_c + amount_lc_d);
      vVatTotAmountFC  :=(amount_fc_c + amount_fc_d);

      -- calcul de la TVA en monnaie TVA
      if nvl(vat_rate_of_exchange, 0) <> 0 then
        vat_amount_vc    := vat_amount_lc *(vat_rate_factor / vat_rate_of_exchange);
        vVatTotAmountVC  := vVatTotAmountLC *(vat_rate_factor / vat_rate_of_exchange);
      end if;
    elsif taxIe = 'S' then
      if includeTaxTariff = 1 then
        vat_amount_lc    :=
                 (amount_lc_c + amount_lc_d)
                 - 100 *(amount_lc_c + amount_lc_d) *(aDeductibleRate / 100) /(rate_tax + 100);
        vat_amount_fc    :=
                 (amount_fc_c + amount_fc_d)
                 - 100 *(amount_fc_c + amount_fc_d) *(aDeductibleRate / 100) /(rate_tax + 100);
        vat_amount_eur   :=
             (amount_eur_c + amount_eur_d)
             - 100 *(amount_eur_c + amount_eur_d) *(aDeductibleRate / 100) /(rate_tax + 100);
        vVatTotAmountLC  := (amount_lc_c + amount_lc_d) - 100 *(amount_lc_c + amount_lc_d) /(rate_tax + 100);
        vVatTotAmountFC  := (amount_fc_c + amount_fc_d) - 100 *(amount_fc_c + amount_fc_d) /(rate_tax + 100);
      else
        vat_amount_lc    := (amount_lc_c + amount_lc_d) *(rate_tax / 100) *(aDeductibleRate / 100);
        vat_amount_fc    := (amount_fc_c + amount_fc_d) *(rate_tax / 100) *(aDeductibleRate / 100);
        vat_amount_eur   := (amount_eur_c + amount_eur_d) *(rate_tax / 100) *(aDeductibleRate / 100);
        vVatTotAmountLC  := (amount_lc_c + amount_lc_d) *(rate_tax / 100);
        vVatTotAmountFC  := (amount_fc_c + amount_fc_d) *(rate_tax / 100);
      end if;

      -- calcul de la TVA en monnaie TVA
      if nvl(vat_rate_of_exchange, 0) <> 0 then
        vat_amount_vc    := vat_amount_lc *(vat_rate_factor / vat_rate_of_exchange);
        vVatTotAmountVC  := vVatTotAmountLC *(vat_rate_factor / vat_rate_of_exchange);
      end if;
    else
      vat_amount_lc    := abs(foot_vat_amount_b);
      vat_amount_fc    := abs(foot_vat_amount * foreign_currency);
      vat_amount_eur   := abs(foot_vat_amount_e);
      vat_amount_vc    := abs(foot_vat_amount_v);
      vVatTotAmountLC  := abs(aFootVatTotalAmount_b);
      vVatTotAmountFC  := abs(aFootVatTotalAmount);
      vVatTotAmountVC  := abs(aFootVatTotalAmount_v);
    end if;

    -- lecture des textes selon  la config de reprise des textes
    getTextRecovering(financial_account_id
                    , null
                    , division_account_id
                    , tax_code_id
                    , cda_account_id
                    , cpn_account_id
                    , pf_account_id
                    , pj_account_id
                    , document_currency_id
                    , document_date
                    , null   --good_id
                    , record_id
                    , person_id
                    , fixed_assets_id
                    , third_id
                    , aQueuing
                    , TextRecoveringRec
                     );

    -- si on gère la comptabilité financière
    if financial_charge = 1 then
      select ACI_ID_SEQ.nextval
        into main_imputation_id
        from dual;

      -- creation de l'imputation financiere pour la taxe
      insert into ACI_FINANCIAL_IMPUTATION
                  (ACI_FINANCIAL_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , ACI_PART_IMPUTATION_ID
                 , IMF_PRIMARY
                 , IMF_TYPE
                 , IMF_GENRE
                 , TAX_INCLUDED_EXCLUDED
                 , C_GENRE_TRANSACTION
                 , IMF_DESCRIPTION
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACC_NUMBER
                 , ACS_DIVISION_ACCOUNT_ID
                 , DIV_NUMBER
                 , IMF_AMOUNT_LC_D
                 , IMF_AMOUNT_FC_D
                 , IMF_AMOUNT_EUR_D
                 , IMF_AMOUNT_LC_C
                 , IMF_AMOUNT_FC_C
                 , IMF_AMOUNT_EUR_C
                 , ACS_TAX_CODE_ID
                 , TAX_NUMBER
                 , IMF_VALUE_DATE
                 , IMF_TRANSACTION_DATE
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , IMF_EXCHANGE_RATE
                 , IMF_BASE_PRICE
                 , TAX_EXCHANGE_RATE
                 , DET_BASE_PRICE
                 , TAX_RATE
                 , TAX_LIABLED_AMOUNT
                 , TAX_LIABLED_RATE
                 , TAX_VAT_AMOUNT_LC
                 , TAX_VAT_AMOUNT_FC
                 , TAX_VAT_AMOUNT_EUR
                 , TAX_VAT_AMOUNT_VC
                 , TAX_TOT_VAT_AMOUNT_LC
                 , TAX_TOT_VAT_AMOUNT_FC
                 , TAX_TOT_VAT_AMOUNT_VC
                 , TAX_DEDUCTIBLE_RATE
                 , TAX_REDUCTION
                 , DOC_RECORD_ID
                 , RCO_NUMBER
                 , RCO_TITLE
                 , PAC_PERSON_ID
                 , PER_KEY1
                 , PER_KEY2
                 , HRM_PERSON_ID
                 , EMP_NUMBER
                 , FAM_FIXED_ASSETS_ID
                 , FIX_NUMBER
                 , C_FAM_TRANSACTION_TYP
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
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (main_imputation_id
                 , new_document_id
                 , part_imputation_id
                 , 0
                 , 'MAN'
                 , 'STD'
                 , taxIE
                 , '1'
                 , substr(description, 1, 100)
                 , financial_account_id
                 , TextRecoveringRec.fin_acc_number
                 , division_account_id
                 , TextRecoveringRec.div_acc_number
                 , vImfAmountLC_D
                 , vImfAmountFC_D
                 , vImfAmountEUR_D
                 , vImfAmountLC_C
                 , vImfAmountFC_C
                 , vImfAmountEUR_C
                 , tax_code_id
                 , TextRecoveringRec.tax_acc_number
                 , trunc(nvl(delivery_date, value_date) )
                 , trunc(document_date)
                 , ACS_FUNCTION.GetPeriodId(trunc(document_date), '2')
                 , TextRecoveringRec.no_period
                 , document_currency_id
                 , TextRecoveringRec.document_currency_name
                 , ACS_FUNCTION.GetLocalCurrencyId
                 , TextRecoveringRec.local_currency_name
                 , rate_of_exchange
                 , rate_factor
                 , vat_rate_of_exchange
                 , vat_rate_factor
                 , rate_tax
                 , abs(vImfAmountLC_D + vImfAmountLC_C) - decode(taxIE, 'E', abs(vat_amount_lc), 0)
                 , liabled_rate
                 , abs(vat_amount_lc)
                 , abs(vat_amount_fc)
                 , abs(vat_amount_eur)
                 , abs(vat_amount_vc)
                 , abs(vVatTotAmountLC)
                 , abs(vVatTotAmountFC)
                 , abs(vVatTotAmountVC)
                 , aDeductibleRate
                 , 0
                 , record_id
                 , TextRecoveringRec.RCO_NUMBER
                 , TextRecoveringRec.RCO_TITLE
                 , third_id
                 , TextRecoveringRec.PER_KEY1
                 , TextRecoveringRec.PER_KEY2
                 , person_id
                 , TextRecoveringRec.EMP_NUMBER
                 , fixed_assets_id
                 , TextRecoveringRec.FIX_NUMBER
                 , fam_transaction_typ
                 , number1
                 , number2
                 , number3
                 , number4
                 , number5
                 , text1
                 , text2
                 , text3
                 , text4
                 , text5
                 , date1
                 , date2
                 , date3
                 , date4
                 , date5
                 , dic_imp1_id
                 , dic_imp2_id
                 , dic_imp3_id
                 , dic_imp4_id
                 , dic_imp5_id
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;

    if     anal_charge = 1
       and (   cda_account_id is not null
            or cpn_account_id is not null
            or pf_account_id is not null
            or pj_account_id is not null
           ) then
      insert into ACI_MGM_IMPUTATION
                  (ACI_MGM_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , ACI_FINANCIAL_IMPUTATION_ID
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
                 , IMM_VALUE_DATE
                 , IMM_TRANSACTION_DATE
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , ACS_CDA_ACCOUNT_ID
                 , CDA_NUMBER
                 , ACS_CPN_ACCOUNT_ID
                 , CPN_NUMBER
                 , ACS_PF_ACCOUNT_ID
                 , PF_NUMBER
                 , ACS_PJ_ACCOUNT_ID
                 , PJ_NUMBER
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , DOC_RECORD_ID
                 , RCO_NUMBER
                 , RCO_TITLE
                 , PAC_PERSON_ID
                 , PER_KEY1
                 , PER_KEY2
                 , HRM_PERSON_ID
                 , FAM_FIXED_ASSETS_ID
                 , FIX_NUMBER
                 , C_FAM_TRANSACTION_TYP
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
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aci_id_seq.nextval
                 , new_document_id
                 , main_imputation_id
                 , 'MAN'
                 , 'STD'
                 , 0
                 , substr(description, 1, 100)
                 , vImfAmountLC_D - decode(taxIE, 'S', 0, 'I', 0, decode(vImfAmountLC_D, 0, 0, vat_amount_lc) )
                 , vImfAmountLC_C - decode(taxIE, 'S', 0, 'I', 0, decode(vImfAmountLC_C, 0, 0, vat_amount_lc) )
                 , rate_of_exchange
                 , rate_factor
                 , vImfAmountFC_D - decode(taxIE, 'S', 0, 'I', 0, decode(vImfAmountFC_D, 0, 0, vat_amount_fc) )
                 , vImfAmountFC_C - decode(taxIE, 'S', 0, 'I', 0, decode(vImfAmountFC_C, 0, 0, vat_amount_fc) )
                 , vImfAmountEUR_D - decode(taxIE, 'S', 0, 'I', 0, decode(vImfAmountEUR_D, 0, 0, vat_amount_eur) )
                 , vImfAmountEUR_C - decode(taxIE, 'S', 0, 'I', 0, decode(vImfAmountEUR_C, 0, 0, vat_amount_eur) )
                 , trunc(value_date)
                 , trunc(document_date)
                 , document_currency_id
                 , TextRecoveringRec.document_currency_name
                 , ACS_FUNCTION.GetLocalCurrencyId
                 , TextRecoveringRec.local_currency_name
                 , cda_account_id
                 , TextRecoveringRec.cda_acc_number
                 , cpn_account_id
                 , TextRecoveringRec.cpn_acc_number
                 , pf_account_id
                 , TextRecoveringRec.pf_acc_number
                 , pj_account_id
                 , TextRecoveringRec.pj_acc_number
                 , ACS_FUNCTION.GetPeriodId(trunc(document_date), '2')
                 , TextRecoveringRec.no_period
                 , record_id
                 , TextRecoveringRec.rco_number
                 , TextRecoveringRec.rco_title
                 , third_id
                 , TextRecoveringRec.per_key1
                 , TextRecoveringRec.per_key2
                 , person_id
                 , fixed_assets_id
                 , TextRecoveringRec.fix_number
                 , fam_transaction_typ
                 , number1
                 , number2
                 , number3
                 , number4
                 , number5
                 , text1
                 , text2
                 , text3
                 , text4
                 , text5
                 , date1
                 , date2
                 , date3
                 , date4
                 , date5
                 , dic_imp1_id
                 , dic_imp2_id
                 , dic_imp3_id
                 , dic_imp4_id
                 , dic_imp5_id
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end footImputation;

 /**
  * procedure positionImputation
  * Description
  *   procedure de transfert d'une position de document logistique dans l'interface comptable
  * @created FP
  * @lastUpdate
  * @private
  * @param new_document_id
  * @param pos_include_tax
  * @param wording
  * @param position_number
  * @param financial_account_id
  * @param division_account_id
  * @param cda_account_id
  * @param cpn_account_id
  * @param pf_account_id
  * @param pj_account_id
  * @param admin_domain
  * @param gauge_title
  * @param type_catalogue
  * @param document_date
  * @param delivery_date
  * @param value_date
  * @param document_currency_id
  * @param tax_code_id
  * @param good_id
  * @param third_id
  * @param record_id
  * @param person_id
  * @param fixed_assets_id
  * @param fam_transaction_typ
  * @param number2
  * @param number3
  * @param number4
  * @param number5
  * @param text1
  * @param text2
  * @param text3
  * @param text4
  * @param text5
  * @param date1
  * @param date2
  * @param date3
  * @param date4
  * @param date5
  * @param dic_imp1_id
  * @param dic_imp2_id
  * @param dic_imp3_id
  * @param dic_imp4_id
  * @param dic_imp5_id
  * @param position_amount
  * @param position_amount_b
  * @param position_amount_e
  * @param position_amount_v
  * @param rate_factor
  * @param rate_of_exchange
  * @param vat_rate_factor
  * @param vat_rate_of_exchange
  * @param part_imputation_id
  * @param round_type
  * @param lc_vat_amount
  * @param fc_vat_amount
  * @param eur_vat_amount
  * @param vc_vat_amount
  * @param vat_currency_id
  * @param foreign_currency
  * @param main_imputation_id
  * @param anal_charge
  * @param financial_charge
  * @param aQueuing   : indique si on déplace le document dans une queue XML
  */
  procedure positionImputation(
    new_document_id      in     number
  , pos_include_tax      in     number
  , wording              in     varchar2
  , position_number      in     number
  , financial_account_id in     number
  , division_account_id  in     number
  , cda_account_id       in     number
  , cpn_account_id       in     number
  , pf_account_id        in     number
  , pj_account_id        in     number
  , admin_domain         in     varchar2
  , gauge_title          in     varchar2
  , type_catalogue       in     varchar2
  , document_date        in     date
  , delivery_date        in     date
  , value_date           in     date
  , document_currency_id in     number
  , tax_code_id          in     number
  , good_id              in     number
  , third_id             in     number
  , record_id            in     number
  , person_id            in     number
  , fixed_assets_id      in     number
  , fam_transaction_typ  in     varchar2
  , number2              in     number
  , number3              in     number
  , number4              in     number
  , number5              in     number
  , text1                in     varchar2
  , text2                in     varchar2
  , text3                in     varchar2
  , text4                in     varchar2
  , text5                in     varchar2
  , date1                in     date
  , date2                in     date
  , date3                in     date
  , date4                in     date
  , date5                in     date
  , dic_imp1_id          in     varchar2
  , dic_imp2_id          in     varchar2
  , dic_imp3_id          in     varchar2
  , dic_imp4_id          in     varchar2
  , dic_imp5_id          in     varchar2
  , position_amount      in     number
  , position_amount_b    in     number
  , position_amount_e    in     number
  , position_amount_v    in     number
  , rate_factor          in     number
  , rate_of_exchange     in     number
  , vat_rate_factor      in     number
  , vat_rate_of_exchange in     number
  , part_imputation_id   in     number
  , round_type           in     varchar2
  , aRateTax             in     ACS_TAX_CODE.TAX_RATE%type
  , aLiabledRate         in     ACI_FINANCIAL_IMPUTATION.TAX_LIABLED_RATE%type
  , lc_vat_amount        out    number
  , fc_vat_amount        out    number
  , eur_vat_amount       out    number
  , vc_vat_amount        out    number
  , aDeductibleRate      in     ACI_FINANCIAL_IMPUTATION.TAX_DEDUCTIBLE_RATE%type
  , aVatTotAmountLC      out    number
  , aVatTotAmountFC      out    number
  , aVatTotAmountVC      out    number
  , vat_currency_id      in     number
  , foreign_currency     in     number
  , main_imputation_id   out    number
  , financial_charge     in     number
  , anal_charge          in     number
  , aQueuing             in     boolean
  )
  is
    amount_lc_d       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    amount_fc_d       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    amount_eur_d      ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    amount_lc_c       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    amount_fc_c       ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    amount_eur_c      ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vat_amount_lc     ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type;
    vat_amount_fc     ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type;
    vat_amount_eur    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_EUR%type;
    vat_amount_vc     ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type    default 0;
    taxIE             varchar2(1);
    TextRecoveringRec TextRecoveringRecType;
  begin
    calcAmounts(foreign_currency
              , tax_code_id
              , nvl(delivery_date, document_date)
              , vat_currency_id
              , position_amount
              , position_amount_b
              , position_amount_e
              , position_amount_v
              , admin_domain
              , gauge_title
              , type_catalogue
              , pos_include_tax
              , amount_lc_c
              , amount_lc_d
              , amount_fc_c
              , amount_fc_d
              , amount_eur_c
              , amount_eur_d
              , taxIE
              , aRateTax
              , aLiabledRate
              , vat_amount_lc
              , vat_amount_fc
              , vat_amount_eur
              , vat_amount_vc
              , aDeductibleRate
              , aVatTotAmountLC
              , aVatTotAmountFC
              , aVatTotAmountVC
               );
    -- lecture des textes selon  la config de reprise des textes
    getTextRecovering(financial_account_id
                    , null
                    , division_account_id
                    , tax_code_id
                    , cda_account_id
                    , cpn_account_id
                    , pf_account_id
                    , pj_account_id
                    , document_currency_id
                    , document_date
                    , good_id
                    , record_id
                    , person_id
                    , fixed_assets_id
                    , third_id
                    , aQueuing
                    , TextRecoveringRec
                     );

    if financial_charge = 1 then
      select ACI_ID_SEQ.nextval
        into main_imputation_id
        from dual;

      --raise_application_error(-20000,vat_rate_of_exchange);

      -- Creation d'une imputation financière
      insert into ACI_FINANCIAL_IMPUTATION
                  (ACI_FINANCIAL_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , ACI_PART_IMPUTATION_ID
                 , IMF_PRIMARY
                 , IMF_NUMBER
                 , IMF_TYPE
                 , IMF_GENRE
                 , TAX_INCLUDED_EXCLUDED
                 , C_GENRE_TRANSACTION
                 , IMF_DESCRIPTION
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACC_NUMBER
                 , ACS_DIVISION_ACCOUNT_ID
                 , DIV_NUMBER
                 , IMF_AMOUNT_LC_D
                 , IMF_AMOUNT_FC_D
                 , IMF_AMOUNT_EUR_D
                 , IMF_AMOUNT_LC_C
                 , IMF_AMOUNT_FC_C
                 , IMF_AMOUNT_EUR_C
                 , ACS_TAX_CODE_ID
                 , TAX_NUMBER
                 , IMF_VALUE_DATE
                 , IMF_TRANSACTION_DATE
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , IMF_EXCHANGE_RATE
                 , IMF_BASE_PRICE
                 , TAX_EXCHANGE_RATE
                 , DET_BASE_PRICE
                 , TAX_RATE
                 , TAX_LIABLED_AMOUNT
                 , TAX_LIABLED_RATE
                 , TAX_VAT_AMOUNT_LC
                 , TAX_VAT_AMOUNT_FC
                 , TAX_VAT_AMOUNT_EUR
                 , TAX_VAT_AMOUNT_VC
                 , TAX_TOT_VAT_AMOUNT_LC
                 , TAX_TOT_VAT_AMOUNT_FC
                 , TAX_TOT_VAT_AMOUNT_VC
                 , TAX_DEDUCTIBLE_RATE
                 , TAX_REDUCTION
                 , DOC_RECORD_ID
                 , RCO_NUMBER
                 , RCO_TITLE
                 , GCO_GOOD_ID
                 , GOO_MAJOR_REFERENCE
                 , PAC_PERSON_ID
                 , PER_KEY1
                 , PER_KEY2
                 , HRM_PERSON_ID
                 , FAM_FIXED_ASSETS_ID
                 , FIX_NUMBER
                 , C_FAM_TRANSACTION_TYP
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
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (main_imputation_id   -- ACI_FINANCIAL_IMPUTATION_ID
                 , new_document_id   -- ACI_DOCUMENT_ID
                 , part_imputation_id   -- ACI_PART_IMPUTATION_ID
                 , 0   -- IMF_PRIMARY
                 , position_number   -- IMF_NUMBER
                 , 'MAN'   -- IMF_TYPE
                 , 'STD'   -- IMF_GENRE
                 , taxIE   -- TAX_INCLUDED_EXCLUDED
                 , '1'   -- C_GENRE_TRANSACTION
                 , substr(wording, 1, 100)   -- IMF_DESCRIPTION
                 , financial_account_id   -- ACS_FINANCIAL_ACCOUNT_ID
                 , TextRecoveringRec.fin_acc_number   -- ACC_NUMBER
                 , division_account_id   -- ACS_DIVISION_ACCOUNT_ID
                 , TextRecoveringRec.div_acc_number   -- DIV_NUMBER
                 , amount_lc_d   -- IMF_AMOUNT_LC_D
                 , amount_fc_d   -- IMF_AMOUNT_FC_D
                 , amount_eur_d   -- IMF_AMOUNT_EUR_D
                 , amount_lc_c   -- IMF_AMOUNT_LC_C
                 , amount_fc_c   -- IMF_AMOUNT_FC_C
                 , amount_eur_c   -- IMF_AMOUNT_EUR_C
                 , tax_code_id   -- ACS_TAX_CODE_ID
                 , TextRecoveringRec.tax_acc_number   -- TAX_NUMBER
                 , trunc(nvl(delivery_date, value_date) )   -- IMF_VALUE_DATE
                 , trunc(document_date)   -- IMF_TRANSACTION_DATE
                 , ACS_FUNCTION.GetPeriodId(trunc(document_date), '2')   -- ACS_PERIOD_ID
                 , TextRecoveringRec.no_period   -- PER_NO_PERIOD
                 , document_currency_id   -- ACS_FINANCIAL_CURRENCY_ID
                 , TextRecoveringRec.document_currency_name   -- CURRENCY1
                 , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                 , TextRecoveringRec.local_currency_name   -- CURRENCY2
                 , rate_of_exchange   -- IMF_EXCHANGE_RATE
                 , rate_factor   -- IMF_BASE_PRICE
                 , vat_rate_of_exchange   -- TAX_EXCHANGE_RATE
                 , vat_rate_factor   -- DET_BASE_PRICE
                 , aRateTax   -- TAX_RATE
                 , abs( (amount_lc_d + amount_lc_c) ) - decode(taxIE, 'E', abs(vat_amount_lc), 0)   -- TAX_LIABLED_AMOUNT
                 , aLiabledRate   -- TAX_LIABLED_RATE
                 , abs(vat_amount_lc)   -- TAX_VAT_AMOUNT_LC
                 , abs(vat_amount_fc)   -- TAX_VAT_AMOUNT_FC
                 , abs(vat_amount_eur)   -- TAX_VAT_AMOUNT_EUR
                 , abs(vat_amount_vc)   -- TAX_VAT_AMOUNT_VC
                 , abs(aVatTotAmountLC)   -- TAX_TOT_VAT_AMOUNT_LC
                 , abs(aVatTotAmountFC)   -- TAX_TOT_VAT_AMOUNT_FC
                 , abs(aVatTotAmountVC)   -- TAX_TOT_VAT_AMOUNT_VC
                 , aDeductibleRate   -- TAX_DEDUCTIBLE_RATE
                 , 0   -- TAX_REDUCTION
                 , record_id
                 , TextRecoveringRec.rco_number
                 , TextRecoveringRec.rco_title
                 , good_id
                 , TextRecoveringRec.goo_major_reference
                 , third_id
                 , TextRecoveringRec.per_key1
                 , TextRecoveringRec.per_key2
                 , person_id
                 , fixed_assets_id
                 , TextRecoveringRec.fix_number
                 , fam_transaction_typ   -- C_FAM_TRANSACTION_TYP
                 , number2   -- IMF_NUMBER2
                 , number3   -- IMF_NUMBER3
                 , number4   -- IMF_NUMBER4
                 , number5   -- IMF_NUMBER5
                 , text1   -- IMF_TEXT1
                 , text2   -- IMF_TEXT2
                 , text3   -- IMF_TEXT3
                 , text4   -- IMF_TEXT4
                 , text5   -- IMF_TEXT5
                 , date1   -- IMF_DATE1
                 , date2   -- IMF_DATE2
                 , date3   -- IMF_DATE3
                 , date4   -- IMF_DATE4
                 , date5   -- IMF_DATE5
                 , dic_imp1_id   -- DIC_IMP_FREE1_ID
                 , dic_imp2_id   -- DIC_IMP_FREE2_ID
                 , dic_imp3_id   -- DIC_IMP_FREE3_ID
                 , dic_imp4_id   -- DIC_IMP_FREE4_ID
                 , dic_imp5_id   -- DIC_IMP_FREE5_ID
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );
    end if;

    --raise_application_error(-20000,aVatTotAmountLC);
    select decode(taxIE, 'S', 0, vat_amount_lc)
         , decode(taxIE, 'S', 0, vat_amount_fc)
         , decode(taxIE, 'S', 0, vat_amount_vc)
      into lc_vat_amount
         , fc_vat_amount
         , vc_vat_amount
      from dual;

    if     anal_charge = 1
       and (   cda_account_id is not null
            or cpn_account_id is not null
            or pf_account_id is not null
            or pj_account_id is not null
           ) then
      insert into ACI_MGM_IMPUTATION
                  (ACI_MGM_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , ACI_FINANCIAL_IMPUTATION_ID
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
                 , IMM_VALUE_DATE
                 , IMM_TRANSACTION_DATE
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , ACS_CDA_ACCOUNT_ID
                 , CDA_NUMBER
                 , ACS_CPN_ACCOUNT_ID
                 , CPN_NUMBER
                 , ACS_PF_ACCOUNT_ID
                 , PF_NUMBER
                 , ACS_PJ_ACCOUNT_ID
                 , PJ_NUMBER
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , DOC_RECORD_ID
                 , RCO_NUMBER
                 , RCO_TITLE
                 , GCO_GOOD_ID
                 , GOO_MAJOR_REFERENCE
                 , PAC_PERSON_ID
                 , PER_KEY1
                 , PER_KEY2
                 , HRM_PERSON_ID
                 , FAM_FIXED_ASSETS_ID
                 , FIX_NUMBER
                 , C_FAM_TRANSACTION_TYP
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
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aci_id_seq.nextval
                 , new_document_id
                 , main_imputation_id
                 , 'MAN'
                 , 'STD'
                 , 0
                 , substr(wording, 1, 100)
                 , amount_lc_d - decode(taxIE, 'S', 0, 'I', 0, decode(amount_lc_d, 0, 0, abs(vat_amount_lc) ) )
                 , amount_lc_c - decode(taxIE, 'S', 0, 'I', 0, decode(amount_lc_c, 0, 0, abs(vat_amount_lc) ) )
                 , rate_of_exchange
                 , rate_factor
                 , amount_fc_d - decode(taxIE, 'S', 0, 'I', 0, decode(amount_fc_d, 0, 0, abs(vat_amount_fc) ) )
                 , amount_fc_c - decode(taxIE, 'S', 0, 'I', 0, decode(amount_fc_c, 0, 0, abs(vat_amount_fc) ) )
                 , amount_eur_d - decode(taxIE, 'S', 0, 'I', 0, decode(amount_eur_d, 0, 0, abs(vat_amount_eur) ) )
                 , amount_eur_c - decode(taxIE, 'S', 0, 'I', 0, decode(amount_eur_c, 0, 0, abs(vat_amount_eur) ) )
                 , trunc(nvl(delivery_date, value_date) )
                 , trunc(document_date)
                 , document_currency_id
                 , TextRecoveringRec.document_currency_name
                 , ACS_FUNCTION.GetLocalCurrencyId
                 , TextRecoveringRec.local_currency_name
                 , cda_account_id
                 , TextRecoveringRec.cda_acc_number
                 , cpn_account_id
                 , TextRecoveringRec.cpn_acc_number
                 , pf_account_id
                 , TextRecoveringRec.pf_acc_number
                 , pj_account_id
                 , TextRecoveringRec.pj_acc_number
                 , ACS_FUNCTION.GetPeriodId(trunc(document_date), '2')
                 , TextRecoveringRec.no_period
                 , record_id
                 , TextRecoveringRec.rco_number
                 , TextRecoveringRec.rco_title
                 , good_id
                 , TextRecoveringRec.goo_major_reference
                 , third_id
                 , TextRecoveringRec.per_key1
                 , TextRecoveringRec.per_key2
                 , person_id
                 , fixed_assets_id
                 , TextRecoveringRec.fix_number
                 , fam_transaction_typ
                 , number2
                 , number3
                 , number4
                 , number5
                 , text1
                 , text2
                 , text3
                 , text4
                 , text5
                 , date1
                 , date2
                 , date3
                 , date4
                 , date5
                 , dic_imp1_id
                 , dic_imp2_id
                 , dic_imp3_id
                 , dic_imp4_id
                 , dic_imp5_id
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end positionImputation;

  /**
  * procedure primaryImputation
  * Description
  *   procedure de creation de l'imputation primaire
  * @created FP
  * @lastUpdate
  * @private
  * @param document_id
  * @param financial_account_id
  * @param third_id
  * @param admin_domain
  * @param gauge_title
  * @param document_date
  * @param value_date
  * @param document_currency_id
  * @param division_account_id
  * @param cda_account_id
  * @param cpn_account_id
  * @param pf_account_id
  * @param pj_account_id
  * @param type_catalogue
  * @param document_amount
  * @param document_amount_b
  * @param document_amount_e
  * @param vat_amount
  * @param vat_amount_b
  * @param vat_amount_e
  * @param vat_amount_v
  * @param rate_factor
  * @param rate_of_exchange
  * @param vat_rate_factor
  * @param vat_rate_of_exchange
  * @param round_type
  * @param part_imputation_id
  * @param foreign_currency
  * @param description
  * @param financial_charge
  * @param anal_charge
  * @param aQueuing   : indique si on déplace le document dans une queue XML
  */
  procedure primaryImputation(
    document_id          in number
  , financial_account_id in number
  , third_id             in number
  , admin_domain         in varchar2
  , gauge_title          in varchar2
  , document_date        in date
  , value_date           in date
  , document_currency_id in number
  , division_account_id  in number
  , cda_account_id       in number
  , cpn_account_id       in number
  , pf_account_id        in number
  , pj_account_id        in number
  , type_catalogue       in varchar2
  , document_amount      in number
  , document_amount_b    in number
  , document_amount_e    in number
  , vat_amount           in number
  , vat_amount_b         in number
  , vat_amount_e         in number
  , vat_amount_v         in number
  , rate_factor          in number
  , rate_of_exchange     in number
  , vat_rate_factor      in number
  , vat_rate_of_exchange in number
  , round_type           in varchar2
  , part_imputation_id   in number
  , foreign_currency     in number
  , description          in varchar2
  , financial_charge     in number
  , anal_charge          in number
  , aQueuing             in boolean
  )
  is
    auxiliary_account_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    main_imputation_id   ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
    vat_amount_lc_d      ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type               default 0;
    amount_lc_d          ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    vat_amount_fc_d      ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type               default 0;
    amount_fc_d          ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    vat_amount_eur_d     ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type              default 0;
    amount_eur_d         ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    vat_amount_vc_d      ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    vat_amount_lc_c      ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type               default 0;
    amount_lc_c          ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    vat_amount_fc_c      ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type               default 0;
    amount_fc_c          ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    vat_amount_eur_c     ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type              default 0;
    amount_eur_c         ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vat_amount_vc_c      ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             default 0;
    TextRecoveringRec    TextRecoveringRecType;
  begin
    -- mise à jour des montants
    if     (    (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                 and type_catalogue in('5', '6') )
            or (    admin_domain in(cAdminDomainSale)
                and type_catalogue in('2') )
            or (gauge_title in('5', '6', '8', '30') )
           )
       and document_amount_b >= 0 then
      vat_amount_lc_d   := vat_amount_b;
      amount_lc_d       := document_amount_b;
      amount_eur_d      := document_amount_e;
      vat_amount_eur_d  := vat_amount_e;
      vat_amount_vc_d   := vat_amount_v;
      -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
      vat_amount_fc_d   := vat_amount * foreign_currency;
      amount_fc_d       := document_amount * foreign_currency;
      -- mise à 0 des montants au crédit
      amount_lc_c       := 0;
      amount_fc_c       := 0;
      amount_eur_c      := 0;
    elsif(    (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
               and type_catalogue in('5', '6') )
          or (    admin_domain in(cAdminDomainSale)
              and type_catalogue in('2') )
          or (gauge_title in('5', '6', '8', '30') )
         ) then
      vat_amount_lc_c   := -vat_amount_b;
      amount_lc_c       := -document_amount_b;
      amount_eur_c      := -document_amount_e;
      vat_amount_eur_c  := -vat_amount_e;
      vat_amount_vc_c   := -vat_amount_v;
      -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
      vat_amount_fc_c   := -vat_amount * foreign_currency;
      amount_fc_c       := -document_amount * foreign_currency;
      -- mise à 0 des montants au crédit
      amount_lc_d       := 0;
      amount_fc_d       := 0;
      amount_eur_d      := 0;
    elsif     (    (    admin_domain in(cAdminDomainSale)
                    and type_catalogue in('5', '6') )
               or (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                   and type_catalogue in('2') )
               or (gauge_title in('1', '4', '9') )
              )
          and document_amount_b >= 0 then
      vat_amount_lc_c   := vat_amount_b;
      amount_lc_c       := document_amount_b;
      vat_amount_eur_c  := vat_amount_e;
      amount_eur_c      := document_amount_e;
      vat_amount_vc_c   := vat_amount_v;
      -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
      vat_amount_fc_c   := vat_amount * foreign_currency;
      amount_fc_c       := document_amount * foreign_currency;
      -- mise à 0 des montants au débit
      amount_lc_d       := 0;
      amount_fc_d       := 0;
      amount_eur_d      := 0;
    elsif(    (    admin_domain in(cAdminDomainSale)
               and type_catalogue in('5', '6') )
          or (    admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
              and type_catalogue in('2') )
          or (gauge_title in('1', '4', '9') )
         ) then
      vat_amount_lc_d   := -vat_amount_b;
      amount_lc_d       := -document_amount_b;
      vat_amount_eur_d  := -vat_amount_e;
      amount_eur_d      := -document_amount_e;
      vat_amount_vc_d   := -vat_amount_v;
      -- montant en monnaie étrangère = monatant document si doc en monnaie étrangère
      vat_amount_fc_d   := -vat_amount * foreign_currency;
      amount_fc_d       := -document_amount * foreign_currency;
      -- mise à 0 des montants au débit
      amount_lc_c       := 0;
      amount_fc_c       := 0;
      amount_eur_c      := 0;
    end if;

    -- recherche du compte auxiliaire en fonction du partenaire
    if type_catalogue <> '1' then
      if gauge_title in('1', '4', '5') then
        select max(ACS_AUXILIARY_ACCOUNT_ID)
          into auxiliary_account_id
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = third_id;
      elsif gauge_title in('6', '8', '9', '15', '30') then
        select max(ACS_AUXILIARY_ACCOUNT_ID)
          into auxiliary_account_id
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = third_id;
      end if;
    end if;

    -- lecture des textes selon  la config de reprise des textes
    getTextRecovering(financial_account_id
                    , auxiliary_account_id
                    , division_account_id
                    , null
                    , cda_account_id
                    , cpn_account_id
                    , pf_account_id
                    , pj_account_id
                    , document_currency_id
                    , document_date
                    , null
                    , null
                    , null
                    , null
                    , null
                    , aQueuing
                    , TextRecoveringRec
                     );

    if financial_charge = 1 then
      select ACI_ID_SEQ.nextval
        into main_imputation_id
        from dual;

      -- creation de l'imputation financiere primaire
      insert into ACI_FINANCIAL_IMPUTATION
                  (ACI_FINANCIAL_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , ACI_PART_IMPUTATION_ID
                 , IMF_PRIMARY
                 , IMF_TYPE
                 , IMF_GENRE
                 , C_GENRE_TRANSACTION
                 , IMF_DESCRIPTION
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACC_NUMBER
                 , ACS_AUXILIARY_ACCOUNT_ID
                 , AUX_NUMBER
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , IMF_VALUE_DATE
                 , IMF_TRANSACTION_DATE
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , ACS_DIVISION_ACCOUNT_ID
                 , DIV_NUMBER
                 , IMF_AMOUNT_LC_D
                 , IMF_AMOUNT_FC_D
                 , IMF_AMOUNT_EUR_D
                 , IMF_AMOUNT_LC_C
                 , IMF_AMOUNT_FC_C
                 , IMF_AMOUNT_EUR_C
                 , IMF_EXCHANGE_RATE
                 , IMF_BASE_PRICE
                 , TAX_EXCHANGE_RATE
                 , DET_BASE_PRICE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (main_imputation_id
                 , document_id
                 , part_imputation_id
                 , 1
                 , 'MAN'
                 , 'STD'
                 , '1'
                 , description
                 , financial_account_id
                 , TextRecoveringRec.fin_acc_number
                 , auxiliary_account_id
                 , TextRecoveringRec.aux_acc_number
                 , ACS_FUNCTION.GetPeriodId(trunc(document_date), '2')
                 , TextRecoveringRec.no_period
                 , trunc(value_date)
                 , trunc(document_date)
                 , document_currency_id
                 , TextRecoveringRec.document_currency_name
                 , ACS_FUNCTION.GetLocalCurrencyId
                 , TextRecoveringRec.local_currency_name
                 , division_account_id
                 , TextRecoveringRec.div_acc_number
                 , amount_lc_d
                 , amount_fc_d
                 , amount_eur_d
                 , amount_lc_c
                 , amount_fc_c
                 , amount_eur_c
                 , rate_of_exchange
                 , rate_factor
                 , vat_rate_of_exchange
                 , vat_rate_factor
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;

    if     anal_charge = 1
       and (   cda_account_id is not null
            or cpn_account_id is not null
            or pf_account_id is not null
            or pj_account_id is not null
           ) then
      insert into ACI_MGM_IMPUTATION
                  (ACI_MGM_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , ACI_FINANCIAL_IMPUTATION_ID
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
                 , IMM_VALUE_DATE
                 , IMM_TRANSACTION_DATE
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , ACS_CDA_ACCOUNT_ID
                 , CDA_NUMBER
                 , ACS_CPN_ACCOUNT_ID
                 , CPN_NUMBER
                 , ACS_PF_ACCOUNT_ID
                 , PF_NUMBER
                 , ACS_PJ_ACCOUNT_ID
                 , PJ_NUMBER
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aci_id_seq.nextval
                 , document_id
                 , main_imputation_id
                 , 'MAN'
                 , 'STD'
                 , 1
                 , description
                 , amount_lc_d
                 , amount_lc_c
                 , rate_of_exchange
                 , rate_factor
                 , amount_fc_d
                 , amount_fc_c
                 , amount_eur_d
                 , amount_eur_c
                 , trunc(value_date)
                 , trunc(document_date)
                 , document_currency_id
                 , TextRecoveringRec.document_currency_name
                 , ACS_FUNCTION.GetLocalCurrencyId
                 , TextRecoveringRec.local_currency_name
                 , cda_account_id
                 , TextRecoveringRec.cda_acc_number
                 , cpn_account_id
                 , TextRecoveringRec.cpn_acc_number
                 , pf_account_id
                 , TextRecoveringRec.pf_acc_number
                 , pj_account_id
                 , TextRecoveringRec.pj_acc_number
                 , ACS_FUNCTION.GetPeriodId(trunc(document_date), '2')
                 , TextRecoveringRec.no_period
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end primaryImputation;

  /**
  * procedure thirdDetPayment
  * Description
  *    procedure de creation des détails de paiement en fonction des transactions de payment du document
  * @created VJ
  * @lastUpdate
  * @private
  * @param partImputationID
  * @param footID
  */
  procedure thirdDetPayment(
    newDocumentID    in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aDocCurrencyId   in ACI_DET_PAYMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , partImputationID in ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  , footID           in DOC_FOOT.DOC_FOOT_ID%type
  , expiryID         in ACI_EXPIRY.ACI_EXPIRY_ID%type
  , aGaugeTitle      in DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type
  )
  is
    -- curseur sur les transactions de paiement
    cursor footPayment(footID DOC_FOOT.DOC_FOOT_ID%type)
    is
      select   FOP.DOC_FOOT_PAYMENT_ID
             , FOP.DOC_FOOT_ID
             , FOP.ACJ_JOB_TYPE_S_CATALOGUE_ID
             , FOP.ACS_FINANCIAL_CURRENCY_ID
             , FOP.DIC_IMP_FREE1_ID
             , FOP.DIC_IMP_FREE2_ID
             , FOP.DIC_IMP_FREE3_ID
             , FOP.DIC_IMP_FREE4_ID
             , FOP.DIC_IMP_FREE5_ID
             , FOP.FAM_FIXED_ASSETS_ID
             , FOP.HRM_PERSON_ID
             , FOP.C_FAM_TRANSACTION_TYP
             , FOP.FOP_EXCHANGE_RATE
             , FOP.FOP_BASE_PRICE
             , FOP.FOP_PAID_AMOUNT
             , FOP.FOP_PAID_AMOUNT_MD
             , FOP.FOP_PAID_AMOUNT_MB
             , FOP.FOP_RECEIVED_AMOUNT
             , FOP.FOP_RECEIVED_AMOUNT_MD
             , FOP.FOP_RECEIVED_AMOUNT_MB
             , FOP.FOP_RETURNED_AMOUNT
             , FOP.FOP_RETURNED_AMOUNT_MD
             , FOP.FOP_RETURNED_AMOUNT_MB
             , FOP.FOP_DEDUCTION_AMOUNT
             , FOP.FOP_DEDUCTION_AMOUNT_MD
             , FOP.FOP_DEDUCTION_AMOUNT_MB
             , FOP.FOP_DISCOUNT_AMOUNT
             , FOP.FOP_DISCOUNT_AMOUNT_MD
             , FOP.FOP_DISCOUNT_AMOUNT_MB
             , FOP.FOP_PAID_BALANCED_AMOUNT
             , FOP.FOP_PAID_BALANCED_AMOUNT_MD
             , FOP.FOP_PAID_BALANCED_AMOUNT_MB
             , FOP.FOP_TERMINAL
             , FOP.FOP_TERMINAL_SEQ
             , FOP.FOP_TRANSACTION_DATE
             , FOP.FOP_IMF_TEXT_1
             , FOP.FOP_IMF_TEXT_2
             , FOP.FOP_IMF_TEXT_3
             , FOP.FOP_IMF_TEXT_4
             , FOP.FOP_IMF_TEXT_5
             , FOP.FOP_IMF_NUMBER_1
             , FOP.FOP_IMF_NUMBER_2
             , FOP.FOP_IMF_NUMBER_3
             , FOP.FOP_IMF_NUMBER_4
             , FOP.FOP_IMF_NUMBER_5
          from DOC_FOOT_PAYMENT FOP
         where FOP.DOC_FOOT_ID = footID
      order by FOP.DOC_FOOT_PAYMENT_ID;

    footPaymentTuple        footPayment%rowtype;
    detPaymentID            ACI_DET_PAYMENT.ACI_DET_PAYMENT_ID%type;
    paymentKey              ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type;
    detPaymentSeq           number;
    baseFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    padDiscountAmountFC     DOC_PAYMENT_DATE.PAD_DISCOUNT_AMOUNT%type;
    padDiscountAmountLC     DOC_PAYMENT_DATE.PAD_DISCOUNT_AMOUNT_B%type;
  begin
    open footPayment(footID);

    fetch footPayment
     into footPaymentTuple;

    detPaymentSeq            := 1;
    -- Recherche la monnaie de base
    baseFinancialCurrencyID  := ACS_FUNCTION.GetLocalCurrencyID;

    -- Recherche les montants d'escomptes de la première tranche de la première échéance
    begin
      select   PAD.PAD_DISCOUNT_AMOUNT
             , PAD.PAD_DISCOUNT_AMOUNT_B
          into padDiscountAmountFC
             , padDiscountAmountLC
          from DOC_DOCUMENT DMT
             , DOC_PAYMENT_DATE PAD
         where DMT.DOC_DOCUMENT_ID = footID
           and PAD.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
           and rownum = 1
      order by PAD.PAD_BAND_NUMBER
             , PAD.PAD_PAYMENT_DATE;
    exception
      when no_data_found then
        null;
    end;

    -- boucle sur les transactions de paiment
    while footPayment%found loop
      select CAT_KEY
        into paymentKey
        from ACJ_JOB_TYPE_S_CATALOGUE
           , ACJ_CATALOGUE_DOCUMENT
       where ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID = footPaymentTuple.ACJ_JOB_TYPE_S_CATALOGUE_ID
         and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

      select ACI_ID_SEQ.nextval
        into detPaymentID
        from dual;

      -- création du détail de paiment
      insert into ACI_DET_PAYMENT
                  (ACI_DET_PAYMENT_ID
                 , ACI_DOCUMENT_ID
                 , ACI_PART_IMPUTATION_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , DET_EXCHANGE_RATE
                 , DET_BASE_PRICE
                 , DET_PAIED_LC
                 , DET_PAIED_FC
                 , DET_PAIED_PC
                 , DET_DISCOUNT_LC
                 , DET_DISCOUNT_FC
                 , DET_DISCOUNT_PC
                 , DET_DEDUCTION_LC
                 , DET_DEDUCTION_FC
                 , DET_DEDUCTION_PC
                 , DET_SEQ_NUMBER
                 , ACT_EXPIRY_ID
                 , ACJ_JOB_TYPE_S_CAT_DET_ID
                 , CAT_KEY_DET
                 , COV_TERMINAL
                 , COV_TERMINAL_SEQ
                 , COV_TRANSACTION_DATE
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , FAM_FIXED_ASSETS_ID
                 , HRM_PERSON_ID
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
                 , C_FAM_TRANSACTION_TYP
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (detPaymentID   -- ACI_DET_PAYMENT_ID
                 , newDocumentID
                 , partImputationID   -- ACI_PART_IMPUTATION_ID
                 , footPaymentTuple.ACS_FINANCIAL_CURRENCY_ID   -- ACS_FINANCIAL_CURRENCY_ID
                 , ACS_FUNCTION.GetCurrencyName(footPaymentTuple.ACS_FINANCIAL_CURRENCY_ID)   -- CURRENCY1
                 , footPaymentTuple.FOP_EXCHANGE_RATE   -- DET_EXCHANGE_RATE
                 , footPaymentTuple.FOP_BASE_PRICE   -- DET_BASE_PRICE
                 , decode(aGaugeTitle
                        , '5', -footPaymentTuple.FOP_PAID_AMOUNT_MB
                        , '9', -footPaymentTuple.FOP_PAID_AMOUNT_MB
                        , footPaymentTuple.FOP_PAID_AMOUNT_MB
                         )   -- DET_PAIED_LC
                 , nvl(decode(ACS_FUNCTION.GetLocalCurrencyId
                            , aDocCurrencyId, 0
                            , decode(aGaugeTitle
                                   , '9', -footPaymentTuple.FOP_PAID_AMOUNT_MD
                                   , '5', -footPaymentTuple.FOP_PAID_AMOUNT_MD
                                   , footPaymentTuple.FOP_PAID_AMOUNT_MD
                                    )
                             )
                     , 0
                      )   -- DET_PAIED_FC
                 , nvl(decode(aGaugeTitle
                            , '9', -footPaymentTuple.FOP_PAID_AMOUNT
                            , '5', -footPaymentTuple.FOP_PAID_AMOUNT
                            , footPaymentTuple.FOP_PAID_AMOUNT
                             )
                     , 0
                      )   -- DET_PAIED_PC
                 , nvl(decode(aGaugeTitle
                            , '9', -footPaymentTuple.FOP_DISCOUNT_AMOUNT_MB
                            , '5', -footPaymentTuple.FOP_DISCOUNT_AMOUNT_MB
                            , footPaymentTuple.FOP_DISCOUNT_AMOUNT_MB
                             )
                     , 0
                      )   -- DET_DISCOUNT_LC
                 , nvl(decode(ACS_FUNCTION.GetLocalCurrencyId
                            , aDocCurrencyId, 0
                            , decode(aGaugeTitle
                                   , '9', -footPaymentTuple.FOP_DISCOUNT_AMOUNT_MD
                                   , '5', -footPaymentTuple.FOP_DISCOUNT_AMOUNT_MD
                                   , footPaymentTuple.FOP_DISCOUNT_AMOUNT_MD
                                    )
                             )
                     , 0
                      )   -- DET_DISCOUNT_FC
                 , nvl(decode(aGaugeTitle
                            , '9', -footPaymentTuple.FOP_DISCOUNT_AMOUNT
                            , '5', -footPaymentTuple.FOP_DISCOUNT_AMOUNT
                            , footPaymentTuple.FOP_DISCOUNT_AMOUNT
                             )
                     , 0
                      )   -- DET_DISCOUNT_PC
                 , nvl(decode(aGaugeTitle
                            , '9', -footPaymentTuple.FOP_DEDUCTION_AMOUNT_MB
                            , '5', -footPaymentTuple.FOP_DEDUCTION_AMOUNT_MB
                            , footPaymentTuple.FOP_DEDUCTION_AMOUNT_MB
                             )
                     , 0
                      )   -- DET_DEDUCTION_LC
                 , nvl(decode(ACS_FUNCTION.GetLocalCurrencyId
                            , aDocCurrencyId, 0
                            , decode(aGaugeTitle
                                   , '9', -footPaymentTuple.FOP_DEDUCTION_AMOUNT_MD
                                   , '5', -footPaymentTuple.FOP_DEDUCTION_AMOUNT_MD
                                   , footPaymentTuple.FOP_DEDUCTION_AMOUNT_MD
                                    )
                             )
                     , 0
                      )   -- DET_DEDUCTION_FC
                 , nvl(decode(aGaugeTitle
                            , '9', -footPaymentTuple.FOP_DEDUCTION_AMOUNT
                            , '5', -footPaymentTuple.FOP_DEDUCTION_AMOUNT
                            , footPaymentTuple.FOP_DEDUCTION_AMOUNT
                             )
                     , 0
                      )   -- DET_DEDUCTION_PC
                 , lpad(detPaymentSeq, 10, '0')   -- DET_SEQ_NUMBER
                 , expiryID   -- ACT_EXPIRY_ID
                 , footPaymentTuple.ACJ_JOB_TYPE_S_CATALOGUE_ID   -- ACJ_JOB_TYPE_S_CAT_DET_ID
                 , paymentKey   -- CAT_KEY_DET
                 , footPaymentTuple.FOP_TERMINAL
                 , footPaymentTuple.FOP_TERMINAL_SEQ
                 , footPaymentTuple.FOP_TRANSACTION_DATE
                 , footPaymentTuple.DIC_IMP_FREE1_ID   -- DIC_IMP_FREE1_ID
                 , footPaymentTuple.DIC_IMP_FREE2_ID   -- DIC_IMP_FREE2_ID
                 , footPaymentTuple.DIC_IMP_FREE3_ID   -- DIC_IMP_FREE3_ID
                 , footPaymentTuple.DIC_IMP_FREE4_ID   -- DIC_IMP_FREE4_ID
                 , footPaymentTuple.DIC_IMP_FREE5_ID   -- DIC_IMP_FREE5_ID
                 , footPaymentTuple.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                 , footPaymentTuple.HRM_PERSON_ID   -- HRM_PERSON_ID
                 , footPaymentTuple.FOP_IMF_NUMBER_1   -- IMF_NUMBER
                 , footPaymentTuple.FOP_IMF_NUMBER_2   -- IMF_NUMBER2
                 , footPaymentTuple.FOP_IMF_NUMBER_3   -- IMF_NUMBER3
                 , footPaymentTuple.FOP_IMF_NUMBER_4   -- IMF_NUMBER4
                 , footPaymentTuple.FOP_IMF_NUMBER_5   -- IMF_NUMBER5
                 , footPaymentTuple.FOP_IMF_TEXT_1   -- IMF_TEXT1
                 , footPaymentTuple.FOP_IMF_TEXT_2   -- IMF_TEXT2
                 , footPaymentTuple.FOP_IMF_TEXT_3   -- IMF_TEXT3
                 , footPaymentTuple.FOP_IMF_TEXT_4   -- IMF_TEXT4
                 , footPaymentTuple.FOP_IMF_TEXT_5   -- IMF_TEXT5
                 , footPaymentTuple.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );

      fetch footPayment
       into footPaymentTuple;

      detPaymentSeq        := detPaymentSeq + 1;
      -- Applique l'escompte sur le premier détail de paiement uniquement
      padDiscountAmountFC  := null;
      padDiscountAmountLC  := null;
    end loop;

    close footPayment;
  end thirdDetPayment;

  /**
  * procedure thirdExpiry
  * Description
  *    procedure de creation des echeances de paiement
  * @created FP
  * @lastUpdate
  * @private
  * @param part_imputation_id
  * @param foot_id
  * @param fin_acc_s_payment_id
  * @param round_type
  * @param document_currency_id
  * @param type_catalogue
  * @param document_date
  * @param change_rate
  */
  procedure thirdExpiry(
    part_imputation_id   in number
  , foot_id              in number
  , fin_acc_s_payment_id in number
  , round_type           in varchar2
  , document_currency_id in number
  , type_catalogue       in varchar2
  , document_date        in date
  , change_rate          in number
  )
  is
    cursor expiry(foot_id number)
    is
      select distinct PAD_BAND_NUMBER
                    , PAD_PAYMENT_DATE
                    , PAD_DATE_AMOUNT
                    , PAD_DATE_AMOUNT_B
                    , PAD_DATE_AMOUNT_E
                    , PAD_DISCOUNT_AMOUNT
                    , PAD_DISCOUNT_AMOUNT_B
                    , PAD_DISCOUNT_AMOUNT_E
                    , PAD_BVR_REFERENCE_NUM
                    , PAD_BVR_CODING_LINE
                    , PAD_AMOUNT_PROV_FC
                    , PAD_AMOUNT_PROV_LC
                    , PAD_AMOUNT_PROV_E
                    , PAD_NET_DATE_AMOUNT
                    , PAD_NET_DATE_AMOUNT_B
                    , PAD_NET_DATE_AMOUNT_E
                 from DOC_PAYMENT_DATE
                where DOC_FOOT_ID = foot_id;

    expiry_tuple        expiry%rowtype;
    expiry_id           ACI_EXPIRY.ACI_EXPIRY_ID%type;
    net_expiry          number(1);
    amount_fc           ACI_EXPIRY.EXP_AMOUNT_FC%type;
    sum_amount_fc       ACI_EXPIRY.EXP_AMOUNT_FC%type               default 0;
    sum_calc_amount_lc  ACI_EXPIRY.EXP_AMOUNT_FC%type               default 0;
    sum_calc_amount_eur ACI_EXPIRY.EXP_AMOUNT_EUR%type              default 0;
    discount_fc         ACI_EXPIRY.EXP_DISCOUNT_FC%type;
    amount_lc           ACI_EXPIRY.EXP_AMOUNT_LC%type;
    discount_lc         ACI_EXPIRY.EXP_DISCOUNT_LC%type;
    amount_eur          ACI_EXPIRY.EXP_AMOUNT_EUR%type;
    discount_eur        ACI_EXPIRY.EXP_DISCOUNT_EUR%type;
    reference_bvr       ACI_EXPIRY.EXP_REF_BVR%type;
    bvr_coding_line     DOC_PAYMENT_DATE.PAD_BVR_CODING_LINE%type;
    val_sign            number(1)                                   default 1;
    status_expiry       ACI_EXPIRY.C_STATUS_EXPIRY%type;
    pmt_date            date;
  begin
    open expiry(foot_id);

    fetch expiry
     into expiry_tuple;

    if type_catalogue in('5', '6') then
      val_sign  := -1;
    else
      val_sign  := 1;
    end if;

    -- boucle sur les échéances de paiement
    while expiry%found loop
      net_expiry       := 1 - sign(nvl(expiry_tuple.pad_discount_amount, 0) );

      if     net_expiry = 1
         and expiry_tuple.pad_date_amount = 0 then
        status_expiry  := '1';
        pmt_date       := trunc(document_date);
      else
        status_expiry  := '0';
      end if;

      -- cumul du montant de tranche pour controle de paritél
      sum_amount_fc    := sum_amount_fc + expiry_tuple.pad_date_amount * val_sign;

      if document_currency_id <> ACS_FUNCTION.GetLocalCurrencyId then
        -- monnaie étrangère
        amount_fc     := expiry_tuple.pad_net_date_amount * val_sign;
        discount_fc   := expiry_tuple.pad_discount_amount * val_sign;
        amount_eur    := expiry_tuple.pad_net_date_amount_e * val_sign;
        discount_eur  := expiry_tuple.pad_discount_amount_e * val_sign;
        amount_lc     := expiry_tuple.pad_net_date_amount_b * val_sign;
        discount_lc   := expiry_tuple.pad_discount_amount_b * val_sign;
      else
        -- Monnaie de base
        amount_fc     := 0;
        discount_fc   := 0;
        amount_eur    := expiry_tuple.pad_net_date_amount_e * val_sign;
        discount_eur  := expiry_tuple.pad_discount_amount_e * val_sign;
        amount_lc     := expiry_tuple.pad_net_date_amount * val_sign;
        discount_lc   := expiry_tuple.pad_discount_amount * val_sign;
      end if;

      -- référence bvr selon config du gabarit
      reference_bvr    := expiry_tuple.pad_bvr_reference_num;
      bvr_coding_line  := expiry_tuple.pad_bvr_coding_line;

      select ACI_ID_SEQ.nextval
        into expiry_id
        from dual;

      -- création de l'echeance de payement
      insert into ACI_EXPIRY
                  (ACI_EXPIRY_ID
                 , ACI_PART_IMPUTATION_ID
                 , C_STATUS_EXPIRY
                 , EXP_DATE_PMT_TOT
                 , EXP_SLICE
                 , EXP_AMOUNT_LC
                 , EXP_AMOUNT_FC
                 , EXP_AMOUNT_EUR
                 , EXP_DISCOUNT_LC
                 , EXP_DISCOUNT_FC
                 , EXP_DISCOUNT_EUR
                 , EXP_ADAPTED
                 , EXP_CALCULATED
                 , EXP_BVR_CODE
                 , EXP_REF_BVR
                 , EXP_CALC_NET
                 , EXP_POURCENT
                 , EXP_AMOUNT_PROV_LC
                 , EXP_AMOUNT_PROV_FC
                 , EXP_AMOUNT_PROV_EUR
                 , ACS_FIN_ACC_S_PAYMENT_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (expiry_id
                 , part_imputation_id
                 , status_expiry
                 , trunc(pmt_date)
                 , expiry_tuple.pad_band_number
                 , amount_lc
                 , amount_fc
                 , amount_eur
                 , discount_lc
                 , discount_fc
                 , discount_eur
                 , trunc(expiry_tuple.pad_payment_date)
                 , trunc(expiry_tuple.pad_payment_date)
                 , bvr_coding_line
                 , reference_bvr
                 , net_expiry
                 , expiry_tuple.pad_date_amount
                 , expiry_tuple.pad_amount_prov_lc
                 , expiry_tuple.pad_amount_prov_fc
                 , expiry_tuple.pad_amount_prov_e
                 , fin_acc_s_payment_id
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      fetch expiry
       into expiry_tuple;
    end loop;

    close expiry;
  end thirdExpiry;

  /**
  * procedure thirdImputation
  * Description
  *   procedure de création de l'imputation partenaire
  * @created FP
  * @lastUpdate fp 13.02.2006
  * @private
  * @param aDocumentId
  * @param aThirdId
  * @param aAdminDomain
  * @param aGaugeTitle
  * @param aDocumentCurrencyId
  * @param aPaymentConditionId
  * @param aFinancialReferenceId
  * @param aFinAccSPaymentId
  * @param aDocumentnumber
  * @param aDeliveryDate
  * @param aForeignCurrency
  * @param aRateFactor
  * @param aRateOfExchange
  * @param aImputationId
  * @param aQueuing
  * @param aBlocked
  * @param aDicBlocked
  */
  procedure thirdImputation(
    aDocumentId           in     number
  , aThirdId              in     number
  , aAdminDomain          in     varchar2
  , aGaugeTitle           in     varchar2
  , aDocumentCurrencyId   in     number
  , aPaymentConditionId   in     number
  , aFinancialReferenceId in     number
  , aFinAccSPaymentId     in     number
  , aDocumentnumber       in     varchar2
  , aDeliveryDate         in     date
  , aForeignCurrency      in     number
  , aRateFactor           in     number
  , aRateOfExchange       in     number
  , aImputationId         out    number
  , aQueuing              in     boolean
  , aBlocked              in     number
  , aDicBlocked           in     varchar2
  )
  is
    vCustomerId           PAC_THIRD.PAC_THIRD_ID%type;
    vSupplierId           PAC_THIRD.PAC_THIRD_ID%type;
    vCustKey1             ACI_PART_IMPUTATION.PER_CUST_KEY1%type;
    vCustKey2             ACI_PART_IMPUTATION.PER_CUST_KEY2%type;
    vSuppKey1             ACI_PART_IMPUTATION.PER_SUPP_KEY1%type;
    vSuppKey2             ACI_PART_IMPUTATION.PER_SUPP_KEY2%type;
    vLocalCurrencyName    ACI_PART_IMPUTATION.CURRENCY1%type;
    vDocumentCurrencyName ACI_PART_IMPUTATION.CURRENCY2%type;
    vPaymentDescr         PAC_PAYMENT_CONDITION.PCO_DESCR%type;
    vFinRefDescr          PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_NUMBER%type;
    vPayMethodDescr       ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type;
  begin
    -- recherche si on a affaire à un client ou un fournisseur
    if aGaugeTitle in('1', '4', '5') then
      vSupplierId  := aThirdId;
    elsif aGaugeTitle in('6', '8', '9', '15', '30') then
      vCustomerId  := aThirdId;
    end if;

    -- lecture des textes selon  la config de reprise des textes
    if    PCS.PC_CONFIG.GetBooleanConfig('FIN_TEXT_RECOVERING')
       or aQueuing then
      -- recherche des descriptions du partenaire
      if vSupplierId is not null then
        select PER_KEY1
             , PER_KEY2
          into vSuppKey1
             , vSuppKey2
          from PAC_PERSON
         where PAC_PERSON_ID = vSupplierId;
      elsif vCustomerId is not null then
        select PER_KEY1
             , PER_KEY2
          into vCustKey1
             , vCustKey2
          from PAC_PERSON
         where PAC_PERSON_ID = vCustomerId;
      end if;

      -- recherche du nom de la monnaie locale
      vLocalCurrencyName  := ACS_FUNCTION.GetLocalCurrencyName;

      -- recherche de la monnaie du tiers
      select max(CURRENCY)
        into vDocumentCurrencyName
        from ACS_FINANCIAL_CURRENCY
           , PCS.PC_CURR
       where ACS_FINANCIAL_CURRENCY.PC_CURR_ID = PC_CURR.PC_CURR_ID
         and ACS_FINANCIAL_CURRENCY_ID = aDocumentCurrencyId;

      -- recherche de la description des conditions de payment
      select max(PCO_DESCR)
        into vPaymentDescr
        from PAC_PAYMENT_CONDITION
       where PAC_PAYMENT_CONDITION_ID = aPaymentConditionId;

      -- recherche de la description de la référence financière
      select max(FRE_ACCOUNT_NUMBER)
        into vFinRefDescr
        from PAC_FINANCIAL_REFERENCE
       where PAC_FINANCIAL_REFERENCE_ID = aFinancialReferenceId;

      -- recherche de la description de la méthode de paiement
      select max(DES.DES_DESCRIPTION_SUMMARY)
        into vPayMethodDescr
        from ACS_DESCRIPTION DES
           , ACS_FIN_ACC_S_PAYMENT SPAY
           , ACS_PAYMENT_METHOD MET
       where DES.PC_LANG_ID = PCS.PC_I_LIB_SESSION.getCompLangId
         and DES.ACS_PAYMENT_METHOD_ID = MET.ACS_PAYMENT_METHOD_ID
         and MET.ACS_PAYMENT_METHOD_ID = SPAY.ACS_PAYMENT_METHOD_ID
         and SPAY.ACS_FIN_ACC_S_PAYMENT_ID = aFinAccSPaymentId;
    end if;

    -- Id de l'imputation que l'on va creer
    select ACI_ID_SEQ.nextval
      into aImputationId
      from dual;

    -- création de l'imputation primaire de l'interface comptable
    insert into ACI_PART_IMPUTATION
                (ACI_PART_IMPUTATION_ID
               , ACI_DOCUMENT_ID
               , PAC_CUSTOM_PARTNER_ID
               , PER_CUST_KEY1
               , PER_CUST_KEY2
               , PAC_SUPPLIER_PARTNER_ID
               , PER_SUPP_KEY1
               , PER_SUPP_KEY2
               , ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY1
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY2
               , PAC_PAYMENT_CONDITION_id
               , PCO_DESCR
               , PAC_FINANCIAL_REFERENCE_ID
               , FRE_ACCOUNT_NUMBER
               , ACS_FIN_ACC_S_PAYMENT_ID
               , DES_DESCRIPTION_SUMMARY
               , PAR_DOCUMENT
               , DOC_DATE_DELIVERY
               , PAR_BLOCKED_DOCUMENT
               , DIC_BLOCKED_REASON_ID
               , PAR_EXCHANGE_RATE
               , PAR_BASE_PRICE
               , A_DATECRE
               , A_IDCRE
                )
         values (aImputationId
               , aDocumentId
               , vCustomerId
               , vCustKey1
               , vCustKey2
               , vSupplierId
               , vSuppKey1
               , vSuppKey2
               , aDocumentCurrencyId
               , vDocumentCurrencyName
               , ACS_FUNCTION.GetLocalCurrencyId
               , vLocalCurrencyName
               , aPaymentConditionId
               , vPaymentDescr
               , aFinancialReferenceId
               , vFinRefDescr
               , aFinAccSPaymentId
               , vPayMethodDescr
               , aDocumentnumber
               , aDeliveryDate
               , aBlocked
               , aDicBlocked
               , aRateOfExchange
               , aRateFactor
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end thirdImputation;


  /**
  * procedure headerInterface
  * Description
  *   procedure de creation de l'entete du document d'interface comptable
  * @created FP
  * @lastUpdate fp 20.10.2005
  * @private
  * @param aDocumentId
  * @param aUsePartnerDate
  * @param aDateDocument
  * @param aDatePartnerDocument
  * @param aDocumentAmount
  * @param aDocumentAmountEur
  * @param aFinancialCurrencyId
  * @param aVatFinancialCurrencyId
  * @param aJobType_S_CatalogueId
  * @param aJobType_s_CatPmtId
  * @param aPaidAmountLc
  * @param aPaidAmountFc
  * @param aPaidAmountEur
  * @param aDmtNumber
  * @param aDocDocumentId  : id du document logistique
  * @param aCoverType  Gestion du risque de change
  * @param aDocgrpkey :
  * @param aComName : nom de la société finance dans laquelle doit être intégrer le document
  * @param aQueuing : paramètre de retour indiquant si on passe parle queueing
  */
  procedure headerInterface(
    aDocumentId             in     number
  , aUsePartnerDate         in     number
  , aDateDocument           in     date
  , aDatePartnerDocument    in     date
  , aDocumentAmount         in     number
  , aDocumentAmountEur      in     number
  , aFinancialCurrencyId    in     number
  , aVatFinancialCurrencyId in     number
  , aJobType_S_CatalogueId  in     number
  , aJobType_s_CatPmtId     in     number
  , aPaidAmountLc           in     number
  , aPaidAmountFc           in     number
  , aPaidAmountEur          in     number
  , aDmtNumber              in     varchar2
  , aDocDocumentId          in     number
  , aCoverType              in     ACI_DOCUMENT.C_CURR_RATE_COVER_TYPE%type
  , aDocGrpKey              in     ACI_DOCUMENT.DOC_GRP_KEY%type
  , aComNameACT             in     PCS.PC_COMP.COM_NAME%type
  , aQueuing                out    boolean
  )
  is
    vNoExercise      ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;
    vCurrencyName    ACI_DOCUMENT.CURRENCY%type;
    vVatCurrencyName ACI_DOCUMENT.CURRENCY%type;
    vTransactionKey  ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type;
    vTypeKey         ACJ_JOB_TYPE.TYP_KEY%type;
    vPmtKey          ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type;
    vDocDate         date;
    vComNameDOC      PCS.PC_COMP.COM_NAME%type;
  begin
    if aUsePartnerDate = 1 then
      vDocDate  := nvl(trunc(aDatePartnerDocument), trunc(aDateDocument) );
    else
      vDocDate  := trunc(aDateDocument);
    end if;

    -- recherche du nom de la société
    select COM_NAME
      into vComNameDOC
      from PCS.PC_COMP
     where PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;

    -- défini si le document devra passer par le queueing
    aQueuing  :=     aComNameACT is not null
                 and aComNameACT <> vComNameDOC;

    -- lecture des textes selon  la config de reprise des textes
    if    PCS.PC_CONFIG.GetBooleanConfig('FIN_TEXT_RECOVERING')
       or aQueuing then
      vNoExercise       := ACS_FUNCTION.GetFinancialYearNo(trunc(aDateDocument) );
      vCurrencyName     := ACS_FUNCTION.GetCurrencyName(aFinancialCurrencyId);
      vVatCurrencyName  := ACS_FUNCTION.GetCurrencyName(aVatFinancialCurrencyId);

      -- recherche de la description de la transaction
      select CAT_KEY
           , TYP_KEY
        into vTransactionKey
           , vTypeKey
        from ACJ_JOB_TYPE_S_CATALOGUE
           , ACJ_JOB_TYPE
           , ACJ_CATALOGUE_DOCUMENT
       where ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID = aJobType_S_CatalogueId
         and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
         and ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID;

      -- recherche de la description de la transaction de paiement
      if aJobType_s_CatPmtId is not null then
        select CAT_KEY
          into vPmtKey
          from ACJ_JOB_TYPE_S_CATALOGUE
             , ACJ_CATALOGUE_DOCUMENT
         where ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID = aJobType_s_CatPmtId
           and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;
      end if;
    end if;

    -- Creation de l'entete
    insert into ACI_DOCUMENT
                (ACI_DOCUMENT_ID
               , C_INTERFACE_ORIGIN
               , C_INTERFACE_CONTROL
               , C_CURR_RATE_COVER_TYPE
               , ACJ_JOB_TYPE_S_CATALOGUE_ID
               , CAT_KEY
               , TYP_KEY
               , ACJ_JOB_TYPE_S_CAT_PMT_ID
               , CAT_KEY_PMT
               , DOC_TOTAL_AMOUNT_DC
               , DOC_TOTAL_AMOUNT_EUR
               , DOC_DOCUMENT_DATE
               , ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , VAT_CURRENCY
               , ACS_FINANCIAL_YEAR_ID
               , FYE_NO_EXERCICE
               , C_STATUS_DOCUMENT
               , DOC_NUMBER
               , DOC_DOCUMENT_ID
               , DOC_PAID_AMOUNT_LC
               , DOC_PAID_AMOUNT_FC
               , DOC_PAID_AMOUNT_EUR
               , DOC_GRP_KEY
               , COM_NAME_DOC
               , COM_NAME_ACT
               , A_DATECRE
               , A_IDCRE
                )
         values (aDocumentId
               , '1'
               , '3'   -- à contrôler
               , nvl(aCoverType,'00')
               , aJobType_S_CatalogueId
               , vTransactionKey
               , vTypeKey
               , aJobType_s_CatPmtId
               , vPmtKey
               , nvl(aDocumentAmount, 0)
               , nvl(aDocumentAmountEur, 0)
               , vDocDate
               , aFinancialCurrencyId
               , vCurrencyName
               , aVatFinancialCurrencyId
               , vVatCurrencyName
               , ACS_FUNCTION.GetFinancialYearId(trunc(aDateDocument) )
               , vNoExercise
               , 'DEF'
               , aDmtNumber
               , aDocDocumentId
               , aPaidAmountLc
               , aPaidAmountFc
               , aPaidAmountEur
               , aDocGrpKey
               , vComNameDOC
               , nvl(aComNameACT, vComNameDOC)
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end headerInterface;

  /**
  * Description
  *    procedure principale a appeler depuis le trigger d'insertion des mouvements de stock
  *    elle appelle la procedure de creation d'entete et la procedure de creation des
  *    imputations
  */
  procedure Write_Document_Interface(aDocumentId in number)
  is
    -- curseur sur le document
    cursor crDocument(aDocumentId number)
    is
      select DOC_DOCUMENT.DOC_DOCUMENT_ID
           , DOC_DOCUMENT.DMT_DATE_DOCUMENT
           , DOC_DOCUMENT.DMT_DATE_PARTNER_DOCUMENT
           , DOC_DOCUMENT.DMT_DATE_VALUE
           , DOC_DOCUMENT.DMT_DATE_DELIVERY
           , DOC_DOCUMENT.DMT_PARTNER_NUMBER
           , decode(DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID
                  , ACS_FUNCTION.GetLocalCurrencyId, 0
                  , FOO_DOCUMENT_TOTAL_AMOUNT
                   ) FOO_DOCUMENT_TOTAL_AMOUNT
           , DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT FOO_DOCUMENT_TOTAL_AMOUNT2
           , DOC_GAUGE_STRUCTURED.ACJ_JOB_TYPE_S_CATALOGUE_ID
           , DOC_FOOT.ACJ_JOB_TYPE_S_CAT_PMT_ID
           , DOC_GAUGE.C_ADMIN_DOMAIN
           , nvl(DOC_DOCUMENT.PAC_THIRD_ACI_ID, DOC_DOCUMENT.PAC_THIRD_ID) PAC_THIRD_ID
           , DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_E
           , DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID
           , DOC_DOCUMENT.ACS_ACS_FINANCIAL_CURRENCY_ID
           , DOC_DOCUMENT.PAC_PAYMENT_CONDITION_ID
           , DOC_FOOT.DOC_FOOT_ID
           , decode(DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.GetLocalCurrencyId, 0, FOO_TOTAL_VAT_AMOUNT)
                                                                                                   FOO_TOTAL_VAT_AMOUNT
           , DOC_FOOT.FOO_TOTAL_VAT_AMOUNT FOO_TOTAL_VAT_AMOUNT2
           , DOC_FOOT.FOO_TOT_VAT_AMOUNT_B
           , DOC_FOOT.FOO_TOT_VAT_AMOUNT_E
           , DOC_FOOT.FOO_TOT_VAT_AMOUNT_V
           , DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B
           , decode(DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID
                  , ACS_FUNCTION.GetLocalCurrencyId, 0
                  , DOC_FOOT.FOO_PAID_AMOUNT
                   ) FOO_PAID_AMOUNT
           , DOC_FOOT.FOO_PAID_AMOUNT_B
           , DOC_FOOT.FOO_PAID_AMOUNT_EUR
           , DOC_DOCUMENT.PAC_FINANCIAL_REFERENCE_ID
           , DOC_DOCUMENT.DMT_NUMBER
           , DOC_DOCUMENT.ACS_FINANCIAL_ACCOUNT_ID
           , DOC_DOCUMENT.ACS_DIVISION_ACCOUNT_ID
           , DOC_DOCUMENT.DMT_BASE_PRICE
           , DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE
           , DOC_DOCUMENT.DMT_VAT_BASE_PRICE
           , DOC_DOCUMENT.DMT_VAT_EXCHANGE_RATE
           , DOC_DOCUMENT.DMT_RATE_EURO
           , DOC_FOOT.FOO_GOOD_TOTAL_AMOUNT
           , DOC_DOCUMENT.DMT_FINANCIAL_CHARGING
           , DOC_DOCUMENT.C_DOCUMENT_STATUS
           , DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE
           , DOC_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID
           , DOC_GAUGE.GAU_DESCRIBE
           , DOC_GAUGE_STRUCTURED.C_ROUND_TYPE
           , DOC_GAUGE.GAU_EXPIRY
           , DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_REF
           , DOC_FOOT.FOO_REF_BVR_NUMBER
           , DOC_GAUGE_STRUCTURED.GAS_PAY_CONDITION
           , DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE
           , DOC_GAUGE.GAU_REF_PARTNER
           , DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE
           , DOC_DOCUMENT.ACS_CDA_ACCOUNT_ID
           , DOC_DOCUMENT.ACS_CPN_ACCOUNT_ID
           , DOC_DOCUMENT.ACS_PF_ACCOUNT_ID
           , DOC_DOCUMENT.ACS_PJ_ACCOUNT_ID
           , DOC_DOCUMENT.DOC_RECORD_ID
           , DOC_GAUGE_STRUCTURED.GAS_USE_PARTNER_DATE
           , DOC_DOCUMENT.C_CURR_RATE_COVER_TYPE
           , DOC_DOCUMENT.DOC_GRP_KEY
           , DOC_DOCUMENT.COM_NAME_ACI
           , DOC_DOCUMENT.DMT_FIN_DOC_BLOCKED
           , DOC_DOCUMENT.DIC_BLOCKED_REASON_ID
           , DOC_GAUGE_STRUCTURED.GAS_USE_PARTNER_NUMBER
        from DOC_DOCUMENT
           , DOC_FOOT
           , DOC_GAUGE_STRUCTURED
           , DOC_GAUGE
       where DOC_DOCUMENT.DOC_DOCUMENT_ID = aDocumentId
         and DOC_FOOT.DOC_DOCUMENT_ID = DOC_DOCUMENT.DOC_DOCUMENT_ID
         and DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID = DOC_DOCUMENT.DOC_GAUGE_ID
         and DOC_GAUGE.DOC_GAUGE_ID = DOC_DOCUMENT.DOC_GAUGE_ID;

    -- curseur sur les positions du document
    cursor crPositions(aDocumentId number)
    is
      select POS.DOC_POSITION_ID
           , POS.POS_IMPUTATION
           , POS.POS_REFERENCE
           , POS.POS_SHORT_DESCRIPTION
           , POS.ACS_FINANCIAL_ACCOUNT_ID
           , POS.ACS_DIVISION_ACCOUNT_ID
           , POS.ACS_TAX_CODE_ID
           , decode(DOC.ACS_FINANCIAL_CURRENCY_ID
                  , ACS_FUNCTION.GetLocalCurrencyId, 0
                  , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE, POS.POS_GROSS_VALUE_INCL)
                   ) POS_GROSS_VALUE
           , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_B, POS.POS_GROSS_VALUE_INCL_B) POS_GROSS_VALUE_B
           , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_E, POS.POS_GROSS_VALUE_INCL_E) POS_GROSS_VALUE_E
           , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_V, POS.POS_GROSS_VALUE_INCL_V) POS_GROSS_VALUE_V
           , POS.POS_NUMBER
           , POS.POS_VAT_LIABLED_RATE
           , POS.POS_VAT_RATE
           , POS.POS_VAT_DEDUCTIBLE_RATE
           , decode(DOC.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.GetLocalCurrencyId, 0, POS.POS_VAT_AMOUNT)
                                                                                                         POS_VAT_AMOUNT
           , decode(DOC.ACS_ACS_FINANCIAL_CURRENCY_ID
                  , ACS_FUNCTION.GetLocalCurrencyId, POS.POS_VAT_AMOUNT_V
                  , POS.POS_VAT_BASE_AMOUNT
                   ) POS_VAT_BASE_AMOUNT
           , POS.POS_VAT_AMOUNT_E
           , POS.POS_VAT_AMOUNT_V
           , decode(DOC.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.GetLocalCurrencyId, 0, POS.POS_VAT_TOTAL_AMOUNT)
                                                                                                   POS_VAT_TOTAL_AMOUNT
           , decode(DOC.ACS_ACS_FINANCIAL_CURRENCY_ID
                  , ACS_FUNCTION.GetLocalCurrencyId, POS.POS_VAT_TOTAL_AMOUNT_V
                  , POS.POS_VAT_TOTAL_AMOUNT_B
                   ) POS_VAT_TOTAL_AMOUNT_B
           , POS.POS_VAT_TOTAL_AMOUNT_V
           , POS.POS_NET_VALUE_EXCL
           ,   -- pour la taxe pure
             POS.POS_NET_VALUE_EXCL_B
           ,   -- pour la taxe pure
             POS.POS_NET_VALUE_EXCL_E
           ,   -- pour la taxe pure
             POS.POS_NET_VALUE_EXCL_V
           ,   -- pour la taxe pure
             POS.ACS_CDA_ACCOUNT_ID
           , POS.ACS_CPN_ACCOUNT_ID
           , POS.ACS_PF_ACCOUNT_ID
           , POS.ACS_PJ_ACCOUNT_ID
           , POS.POS_INCLUDE_TAX_TARIFF
           , POS.GCO_GOOD_ID
           , nvl(POS.PAC_PERSON_ID, nvl(DOC.PAC_THIRD_ACI_ID, DOC.PAC_THIRD_ID) ) PAC_THIRD_ID
           , nvl(POS.DOC_DOC_RECORD_ID, POS.DOC_RECORD_ID) DOC_RECORD_ID
           , POS.HRM_PERSON_ID
           , POS.FAM_FIXED_ASSETS_ID
           , POS.C_FAM_TRANSACTION_TYP
           , POS.POS_IMF_TEXT_1
           , POS.POS_IMF_TEXT_2
           , POS.POS_IMF_TEXT_3
           , POS.POS_IMF_TEXT_4
           , POS.POS_IMF_TEXT_5
           , POS.POS_IMF_NUMBER_2
           , POS.POS_IMF_NUMBER_3
           , POS.POS_IMF_NUMBER_4
           , POS.POS_IMF_NUMBER_5
           , POS.POS_IMF_DATE_1
           , POS.POS_IMF_DATE_2
           , POS.POS_IMF_DATE_3
           , POS.POS_IMF_DATE_4
           , POS.POS_IMF_DATE_5
           , POS.DIC_IMP_FREE1_ID
           , POS.DIC_IMP_FREE2_ID
           , POS.DIC_IMP_FREE3_ID
           , POS.DIC_IMP_FREE4_ID
           , POS.DIC_IMP_FREE5_ID
           , POS.POS_DATE_DELIVERY
        from DOC_DOCUMENT DOC
           , DOC_POSITION POS
       where POS.DOC_DOCUMENT_ID = aDocumentId
         and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.C_GAUGE_TYPE_POS <> '4'
         and   -- texte
             POS.C_GAUGE_TYPE_POS <> '6'
         and   -- Recapitulative
             POS.C_GAUGE_TYPE_POS <> '9'
         and   -- Kit (valeur CPT)
             POS.C_GAUGE_TYPE_POS <> '71'
         and   -- Composant Assemblage (valeur PT)
             POS.C_GAUGE_TYPE_POS <> '81'
         and   -- Composant Assemblage (valeur PT somme CPT)
             POS.C_GAUGE_TYPE_POS <> '101';   -- Composant Kit (valeur PT)

    cursor crVentilation(aPositionId number, aPositionChargeId number, aFootChargeId number)
    is
      select   ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , POI_AMOUNT
             , POI_AMOUNT_B
             , POI_AMOUNT_E
             , POI_AMOUNT_V
             /*
             , POS.POS_NET_VALUE_EXCL
             ,   -- pour la taxe pure
               POS.POS_NET_VALUE_EXCL_B
             ,   -- pour la taxe pure
               POS.POS_NET_VALUE_EXCL_E
             ,   -- pour la taxe pure
               POS.POS_NET_VALUE_EXCL_V
             ,   -- pour la taxe pure
             */
      ,        ACS_CDA_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , DOC_RECORD_ID
             , HRM_PERSON_ID
             , FAM_FIXED_ASSETS_ID
             , C_FAM_TRANSACTION_TYP
             , POI_IMF_TEXT_1
             , POI_IMF_TEXT_2
             , POI_IMF_TEXT_3
             , POI_IMF_TEXT_4
             , POI_IMF_TEXT_5
             , POI_IMF_NUMBER_1
             , POI_IMF_NUMBER_2
             , POI_IMF_NUMBER_3
             , POI_IMF_NUMBER_4
             , POI_IMF_NUMBER_5
             , POI_IMF_DATE_1
             , POI_IMF_DATE_2
             , POI_IMF_DATE_3
             , POI_IMF_DATE_4
             , POI_IMF_DATE_5
             , DIC_IMP_FREE1_ID
             , DIC_IMP_FREE2_ID
             , DIC_IMP_FREE3_ID
             , DIC_IMP_FREE4_ID
             , DIC_IMP_FREE5_ID
          from DOC_POSITION_IMPUTATION
         where (    aPositionId is not null
                and DOC_POSITION_ID = aPositionId)
            or (    aPositionChargeId is not null
                and DOC_POSITION_CHARGE_ID = aPositionChargeId)
            or (    aFootChargeId is not null
                and DOC_FOOT_CHARGE_ID = aFootChargeId)
      order by POI_RATIO desc;

    -- curseur sur les remises et les taxes de la position
    cursor crCharge(position_id number)
    is
      select PCH.DOC_POSITION_CHARGE_ID
           , PCH.C_FINANCIAL_CHARGE
           , PCH.PTC_CHARGE_ID
           , PCH.PTC_DISCOUNT_ID
           , PCH.PCH_IMPUTATION
           , PCH.ACS_FINANCIAL_ACCOUNT_ID
           , PCH.ACS_DIVISION_ACCOUNT_ID
           , PCH.PCH_DESCRIPTION
           , decode(DOC.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.GetLocalCurrencyId, 0, PCH_AMOUNT) PCH_AMOUNT
           , PCH.PCH_AMOUNT_B
           , PCH.PCH_AMOUNT_E
           , PCH.PCH_AMOUNT_V
           , PCH.ACS_CPN_ACCOUNT_ID
           , PCH.ACS_PF_ACCOUNT_ID
           , PCH.ACS_PJ_ACCOUNT_ID
           , PCH.ACS_CDA_ACCOUNT_ID
           , PCH.FAM_FIXED_ASSETS_ID
           , PCH.C_FAM_TRANSACTION_TYP
           , PCH.HRM_PERSON_ID
           , PCH.PCH_IMP_TEXT_1
           , PCH.PCH_IMP_TEXT_2
           , PCH.PCH_IMP_TEXT_3
           , PCH.PCH_IMP_TEXT_4
           , PCH.PCH_IMP_TEXT_5
           , PCH.PCH_IMP_NUMBER_1
           , PCH.PCH_IMP_NUMBER_2
           , PCH.PCH_IMP_NUMBER_3
           , PCH.PCH_IMP_NUMBER_4
           , PCH.PCH_IMP_NUMBER_5
           , PCH.PCH_IMP_DATE_1
           , PCH.PCH_IMP_DATE_2
           , PCH.PCH_IMP_DATE_3
           , PCH.PCH_IMP_DATE_4
           , PCH.PCH_IMP_DATE_5
           , PCH.DIC_IMP_FREE1_ID
           , PCH.DIC_IMP_FREE2_ID
           , PCH.DIC_IMP_FREE3_ID
           , PCH.DIC_IMP_FREE4_ID
           , PCH.DIC_IMP_FREE5_ID
        from DOC_POSITION_CHARGE PCH
           , DOC_DOCUMENT DOC
       where PCH.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and PCH.DOC_POSITION_ID = position_id;

    cursor crFootCharge(foot_id number)
    is
      select FCH.DOC_FOOT_CHARGE_ID
           , FCH.C_FINANCIAL_CHARGE
           , FCH.FCH_IMPUTATION
           , FCH.ACS_TAX_CODE_ID
           , FCH.PTC_CHARGE_ID
           , FCH.PTC_DISCOUNT_ID
           , FCH.ACS_FINANCIAL_ACCOUNT_ID
           , FCH.ACS_DIVISION_ACCOUNT_ID
           , FCH.FCH_DESCRIPTION
           , decode(DOC.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.GetLocalCurrencyId, 0, FCH.FCH_VAT_AMOUNT)
                                                                                                         FCH_VAT_AMOUNT
           , FCH.FCH_VAT_BASE_AMOUNT FCH_VAT_AMOUNT_B
           , FCH.FCH_VAT_AMOUNT_E
           , FCH.FCH_VAT_AMOUNT_V
           , decode(DOC.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.GetLocalCurrencyId, 0, FCH.FCH_VAT_TOTAL_AMOUNT)
                                                                                                   FCH_VAT_TOTAL_AMOUNT
           , FCH.FCH_VAT_TOTAL_AMOUNT_B FCH_VAT_TOTAL_AMOUNT_B
           , FCH.FCH_VAT_TOTAL_AMOUNT_V
           , FCH.FCH_VAT_RATE
           , FCH.FCH_VAT_LIABLED_RATE
           , FCH.FCH_VAT_DEDUCTIBLE_RATE
           , decode(DOC.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.GetLocalCurrencyId, 0, FCH.FCH_EXCL_AMOUNT)
                                                                                                        FCH_EXCL_AMOUNT
           , FCH.FCH_EXCL_AMOUNT_B
           , FCH.FCH_EXCL_AMOUNT_E
           , decode(DOC.ACS_FINANCIAL_CURRENCY_ID, ACS_FUNCTION.GetLocalCurrencyId, 0, FCH.FCH_INCL_AMOUNT)
                                                                                                        FCH_INCL_AMOUNT
           , FCH.FCH_INCL_AMOUNT_B
           , FCH.FCH_INCL_AMOUNT_E
           , FCH.ACS_CPN_ACCOUNT_ID
           , FCH.ACS_PF_ACCOUNT_ID
           , FCH.ACS_PJ_ACCOUNT_ID
           , FCH.ACS_CDA_ACCOUNT_ID
           , FCH.FAM_FIXED_ASSETS_ID
           , FCH.C_FAM_TRANSACTION_TYP
           , FCH.HRM_PERSON_ID
           , FCH.FCH_IMP_TEXT_1
           , FCH.FCH_IMP_TEXT_2
           , FCH.FCH_IMP_TEXT_3
           , FCH.FCH_IMP_TEXT_4
           , FCH.FCH_IMP_TEXT_5
           , FCH.FCH_IMP_NUMBER_1
           , FCH.FCH_IMP_NUMBER_2
           , FCH.FCH_IMP_NUMBER_3
           , FCH.FCH_IMP_NUMBER_4
           , FCH.FCH_IMP_NUMBER_5
           , FCH.FCH_IMP_DATE_1
           , FCH.FCH_IMP_DATE_2
           , FCH.FCH_IMP_DATE_3
           , FCH.FCH_IMP_DATE_4
           , FCH.FCH_IMP_DATE_5
           , FCH.DIC_IMP_FREE1_ID
           , FCH.DIC_IMP_FREE2_ID
           , FCH.DIC_IMP_FREE3_ID
           , FCH.DIC_IMP_FREE4_ID
           , FCH.DIC_IMP_FREE5_ID
        from DOC_FOOT_CHARGE FCH
           , DOC_DOCUMENT DOC
       where FCH.DOC_FOOT_ID = foot_id
         and DOC.DOC_DOCUMENT_ID = FCH.DOC_FOOT_ID;

    tplDocument           crDocument%rowtype;
    new_document_id       ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    type_catalogue        ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
    aci_financial_link    ACJ_JOB_TYPE.C_ACI_FINANCIAL_LINK%type;
    rate_factor           DOC_DOCUMENT.DMT_BASE_PRICE%type;
    rate_of_exchange      DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    vat_rate_factor       DOC_DOCUMENT.DMT_BASE_PRICE%type;
    vat_rate_of_exchange  DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    mbRateExchangeEuro    DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    meRateExchangeEuro    DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    mbEuro                number(1);
    meEuro                number(1);
    mvEuro                number(1);
    part_imputation_id    ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type;
    change_rate           DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    lc_vat_amount         ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type;
    lc_pos_vat_amount     ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type;
    lc_vat_dif_amount     ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type;
    vTotVatAmountLC       ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_LC%type;
    vTotVatDifAmountLC    ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_LC%type;
    fc_vat_amount         ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type;
    fc_vat_dif_amount     ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type;
    vTotVatAmountFC       ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_FC%type;
    vTotVatDifAmountFC    ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_FC%type;
    eur_vat_amount        ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_EUR%type;
    eur_pos_vat_amount    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_EUR%type;
    eur_vat_dif_amount    ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_EUR%type;
    vc_vat_amount         ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type;
    vc_pos_vat_amount     ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type;
    vc_vat_dif_amount     ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type;
    vTotVatAmountVC       ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_VC%type;
    vTotVatDifAmountVC    ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_VC%type;
    max_imp_id            ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
    max_mgm_id            ACI_MGM_IMPUTATION.ACI_MGM_IMPUTATION_ID%type;
    bln_foreign_currency  number(1);
    bln_doc_euro          number(1)                                                   default 0;
    qty_parity            ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    qty_parity_eur        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    partner_number        ACI_PART_IMPUTATION.PAR_DOCUMENT%type;
    engagement            number(1);
    pri_value_date        date;
    nbPaymentTransaction  number;
    includeTaxTariff      number(1);
    vQueuing              boolean;
    vIsDateDeliveryUnique number(1)                                                   default 1;
    vUniqueDateDelivery   date;
    vThirdDeliveryDate    date;
    vImpDeliveryDate      date;
    vIsNullDeliveryDates  number(1)                                                   default 0;
    vNbDiffDeliveryDate   number;
    vNbPos                number;
    lb_exportXmlResult BOOLEAN;
  begin
    if (pcs.pc_config.GetConfigUpper('ACI_XML_TRANSFERT', pcs.PC_I_LIB_SESSION.GetCompanyId) = 'TRUE') then
      update DOC_DOCUMENT
         set COM_NAME_ACI = aci_logistic_document.GetFinancialCompany(DOC_GAUGE_ID, PAC_THIRD_ID)
       where DOC_DOCUMENT_ID = aDocumentId;
    end if;

    -- ouverture du curseur de document
    open crDocument(aDocumentId);

    fetch crDocument
     into tplDocument;

    -- Le traitement ne se fait que si on interface les mouvements de stock en finance
    -- et l'imputation financière du mouvement de stock est à false
    if     (PCS.PC_CONFIG.GetConfigUpper('DOC_FINANCIAL_IMPUTATION') = 'TRUE')
       and (   tplDocument.gas_financial_charge = 1
            or tplDocument.gas_anal_charge = 1) then
      -- si on a pas d'enregistrement sur le curseur, il y a erreur
      if    tplDocument.acj_job_type_s_catalogue_id is null
         or crDocument%notfound then
        raise_application_error(-20001, 'PCS - Document configuration does not allowed financial recover');
      end if;

      -- recherche si on a affaire à un document de type engagement
      begin
        select decode(SUB.C_TYPE_CUMUL, 'ENG', 1, 0)
          into engagement
          from acj_job_type_s_catalogue cat
             , acj_sub_set_cat sub
         where cat.acj_job_type_s_catalogue_id = tplDocument.acj_job_type_s_catalogue_id
           and cat.acj_catalogue_document_id = sub.acj_catalogue_document_id
           and sub.c_sub_set in('REC', 'PAY');
      exception
        -- si on ne trouve pas de type cumul ou si on en trouve plusieurs
        when others then
          engagement  := 0;
      end;

      -- si le document n'est pas encore exporté et que son status permet l'exportation
      if     (tplDocument.dmt_financial_charging = 0)
         and (tplDocument.c_document_status in('01', '02', '04') ) then
        -- recherche d'un nouvel id unique pour le document que l'on va creer
        select ACI_ID_SEQ.nextval
          into new_document_id
          from dual;

        -- Recherche du type de catalogue transaction
        select max(C_TYPE_CATALOGUE)
             , max(C_ACI_FINANCIAL_LINK)
          into type_catalogue
             , aci_financial_link
          from ACJ_CATALOGUE_DOCUMENT
             , ACJ_JOB_TYPE_S_CATALOGUE
             , ACJ_JOB_TYPE
         where ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID = tplDocument.acj_job_type_s_catalogue_id
           and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID
           and ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID;

            -- si on a trouve un document parametre pour le transfert en finance,
        -- on crée l'interface
        if crDocument%found then
          -- Recherche si la monnaie de base est IN/OUT ou Euro et du taux fixe Euro
          begin
            -- Recherche du taux EURO de la monnaie de base
            select FIN_EURO_RATE
                 , 1
              into mbRateExchangeEURO
                 , mbEuro
              from ACS_FINANCIAL_CURRENCY
             where ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
               and FIN_EURO_FROM <= tplDocument.dmt_date_document;
          exception
            when no_data_found then
              -- Si la monnaie de base n'est pas une monnaie Euro pour la date recherchée Taux de change à 1
              mbRateExchangeEURO  := 1;
              mbEuro              := 0;
          end;

          -- Recherche si la monnaie de étrangère est IN/OUT ou Euro
          begin
            -- Recherche si la monnaie étrangère est IN
            select tplDocument.dmt_rate_euro
                 , 1
              into meRateExchangeEURO
                 , meEuro
              from ACS_FINANCIAL_CURRENCY
             where ACS_FINANCIAL_CURRENCY_ID = tplDocument.acs_financial_currency_id
               and FIN_EURO_FROM <= tplDocument.dmt_date_document;
          exception
            when no_data_found then
              -- Monnaie étrangère non euro
              meRateExchangeEuro  := 1;
              meEuro              := 0;
          end;

          -- Recherche si la monnaie de taxe est IN/OUT ou Euro
          begin
            -- Recherche si la monnaie taxe est IN
            select 1
              into mvEuro
              from ACS_FINANCIAL_CURRENCY
             where ACS_FINANCIAL_CURRENCY_ID = tplDocument.acs_acs_financial_currency_id
               and FIN_EURO_FROM <= tplDocument.dmt_date_document;
          exception
            when no_data_found then
              -- Monnaie Taxe non euro
              mvEuro  := 0;
          end;

          -- Document en monnaie de base
          -- taux et facteur de conversion de change à zero si on a pas de monnaie étrangère
          if tplDocument.acs_financial_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
            rate_of_exchange      := 0;
            rate_factor           := 0;
            change_rate           := 1;
            bln_foreign_currency  := 0;
          -- Document en monnaie étrangère
          elsif     (   ACS_FUNCTION.GetLocalCurrencyId = ACS_FUNCTION.GetEuroCurrency
                     or mbEuro = 1)
                and (   tplDocument.acs_financial_currency_id = ACS_FUNCTION.GetEuroCurrency
                     or meEuro = 1) then
            rate_of_exchange      := 1;
            rate_factor           := 1;
            change_rate           := tplDocument.dmt_rate_of_exchange / tplDocument.dmt_base_price;
            bln_foreign_currency  := 1;
          else
            rate_of_exchange      := tplDocument.dmt_rate_of_exchange;
            rate_factor           := tplDocument.dmt_base_price;
            change_rate           := rate_of_exchange / rate_factor;
            bln_foreign_currency  := 1;
          end if;

          -- TVA en monnaie de base
          -- taux et facteur de conversion de change à zero si on a pas de monnaie étrangère
          if     tplDocument.acs_acs_financial_currency_id = ACS_FUNCTION.GetLocalCurrencyId
             and tplDocument.acs_financial_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
            vat_rate_of_exchange  := 0;
            vat_rate_factor       := 0;
          -- Document en monnaie étrangère
          elsif     (   ACS_FUNCTION.GetLocalCurrencyId = ACS_FUNCTION.GetEuroCurrency
                     or mbEuro = 1)
                and (   tplDocument.acs_acs_financial_currency_id = ACS_FUNCTION.GetEuroCurrency
                     or mvEuro = 1) then
            vat_rate_of_exchange  := 1;
            vat_rate_factor       := 1;
          else
            vat_rate_of_exchange  := tplDocument.dmt_vat_exchange_rate;
            vat_rate_factor       := tplDocument.dmt_vat_base_price;
          end if;

          -- Recherche si des transactions de paiment comptant existent pour ce document. Si c'est le cas, il ne faut
          -- pas utilisé les données du pied qui concernent la vente au comptant traditionnelle.
          select count(FOP.DOC_FOOT_PAYMENT_ID)
            into nbPaymentTransaction
            from DOC_FOOT_PAYMENT FOP
           where FOP.DOC_FOOT_ID = aDocumentId;

          select max(POS_DATE_DELIVERY)
               , count(distinct POS_DATE_DELIVERY)
               , count(*)
               , max(decode(POS_DATE_DELIVERY, null, 1, 0) )
            into vUniqueDateDelivery
               , vNbDiffDeliveryDate
               , vNbPos
               , vIsNullDeliveryDates
            from DOC_POSITION POS
           where DOC_DOCUMENT_ID = aDocumentId
             and POS.C_GAUGE_TYPE_POS <> '4'
             and   -- texte
                 POS.C_GAUGE_TYPE_POS <> '6'
             and   -- Recapitulative
                 POS.C_GAUGE_TYPE_POS <> '9'
             and   -- Kit (valeur CPT)
                 POS.C_GAUGE_TYPE_POS <> '71'
             and   -- Composant Assemblage (valeur PT)
                 POS.C_GAUGE_TYPE_POS <> '81'
             and   -- Composant Assemblage (valeur PT somme CPT)
                 POS.C_GAUGE_TYPE_POS <> '101';   -- Composant Kit (valeur PT)

          if    vNbDiffDeliveryDate > 1
             or (    vNbPos = 1
                 and vNbDiffDeliveryDate = 1) then
            vThirdDeliveryDate  := null;
          elsif     vNbDiffDeliveryDate = 1
                and vIsNullDeliveryDates = 0 then
            vThirdDeliveryDate  := nvl(tplDocument.DMT_DATE_DELIVERY, vUniqueDateDelivery);
          else
            vThirdDeliveryDate  := null;
          end if;

          if (nbPaymentTransaction > 0) then
            -- creation de l'entete du document interface
            headerInterface(new_document_id
                          , tplDocument.gas_use_partner_date
                          , tplDocument.dmt_date_document
                          , tplDocument.dmt_date_partner_document
                          , tplDocument.foo_document_total_amount2
                          , tplDocument.foo_document_tot_amount_e
                          , tplDocument.acs_financial_currency_id
                          , tplDocument.acs_acs_financial_currency_id
                          , tplDocument.acj_job_type_s_catalogue_id
                          , null
                          , 0
                          , 0
                          , 0
                          , tplDocument.dmt_number
                          , tplDocument.doc_document_id
                          , tplDocument.c_curr_rate_cover_type
                          , tplDocument.doc_grp_key
                          , tplDocument.com_name_aci
                          , vQueuing
                           );
          else
            -- creation de l'entete du document interface
            headerInterface(new_document_id
                          , tplDocument.gas_use_partner_date
                          , tplDocument.dmt_date_document
                          , tplDocument.dmt_date_partner_document
                          , tplDocument.foo_document_total_amount2
                          , tplDocument.foo_document_tot_amount_e
                          , tplDocument.acs_financial_currency_id
                          , tplDocument.acs_acs_financial_currency_id
                          , tplDocument.acj_job_type_s_catalogue_id
                          , tplDocument.acj_job_type_s_cat_pmt_id
                          , tplDocument.foo_paid_amount_b
                          , tplDocument.foo_paid_amount
                          , tplDocument.foo_paid_amount_eur
                          , tplDocument.dmt_number
                          , tplDocument.doc_document_id
                          , tplDocument.c_curr_rate_cover_type
                          , tplDocument.doc_grp_key
                          , tplDocument.com_name_aci
                          , vQueuing
                           );
          end if;

          -- si on doit passer par le queing, on outrepasse la méthode définie dans la société courante
          if vQueuing then
            aci_financial_link  := '8';   -- queueing XML
          end if;

          -- si on a affaire à un document de type engagement, la date valeur sera initialisée avec
          -- le plus petit delai de position du document
          if engagement = 1 then
            select nvl(min(pde_final_delay), tplDocument.dmt_date_value)
              into pri_value_date
              from doc_position_detail
             where doc_document_id = aDocumentId
               and pde_final_delay is not null;
          else
            pri_value_date  := tplDocument.dmt_date_value;
          end if;

          -- si on a des partenaires pour le gabarit document et que l'on gère la comptabilité financière
          if     tplDocument.gau_ref_partner = 1
             and tplDocument.gas_financial_charge = 1
             and type_catalogue <> '1' then
            -- ancienne façon
            /*if tplDocument.c_gauge_title in('1', '4', '5', '15') then
              partner_number  := nvl(tplDocument.dmt_partner_number, tplDocument.dmt_number);
            else
              partner_number  := tplDocument.dmt_number;
            end if;*/

            -- Initialisation du numéro de document dans l'imputation partenaire selon que
            -- l'on ait affaire à un client ou un fournisseur
            if tplDocument.gas_use_partner_number = 1 then
              partner_number  := tplDocument.dmt_partner_number;
            elsif    tplDocument.c_admin_domain = 1
                  or tplDocument.c_admin_domain = 5 then
              partner_number  := null;
            else
              partner_number  := tplDocument.dmt_number;
            end if;

            -- creation de l'imputation partenaire
            thirdImputation(new_document_id
                          , tplDocument.pac_third_id
                          , tplDocument.c_admin_domain
                          , tplDocument.c_gauge_title
                          , tplDocument.acs_financial_currency_id
                          , tplDocument.pac_payment_condition_id
                          , tplDocument.pac_financial_reference_id
                          , tplDocument.acs_fin_acc_s_payment_id
                          , partner_number
                          , vThirdDeliveryDate
                          , bln_foreign_currency
                          , rate_factor
                          , rate_of_exchange
                          , part_imputation_id
                          , vQueuing
                          , tplDocument.DMT_FIN_DOC_BLOCKED
                          , tplDocument.DIC_BLOCKED_REASON_ID
                           );

            -- si on a des échéances pour le gabarit du document en traitement
            -- et que le document n'est pas de type engagement
            if     tplDocument.gas_pay_condition = 1
               and engagement = 0 then
              -- creation des echeances de paiement
              thirdExpiry(part_imputation_id
                        , tplDocument.doc_foot_id
                        , tplDocument.acs_fin_acc_s_payment_id
                        , tplDocument.c_round_type
                        , tplDocument.acs_financial_currency_id
                        , type_catalogue
                        , tplDocument.dmt_date_document
                        , change_rate
                         );
            end if;
          end if;

          -- Création des détails de paiement
          if (nbPaymentTransaction > 0) then
            thirdDetPayment(new_document_id
                          , tplDocument.acs_financial_currency_id
                          , part_imputation_id
                          , tplDocument.DOC_FOOT_ID
                          , null
                          , tplDocument.C_GAUGE_TITLE
                           );
          end if;

          -- Création de l'imputation primaire
          primaryImputation(new_document_id
                          , tplDocument.acs_financial_account_id
                          , tplDocument.pac_third_id
                          , tplDocument.c_admin_domain
                          , tplDocument.c_gauge_title
                          , tplDocument.dmt_date_document
                          , pri_value_date
                          , tplDocument.acs_financial_currency_id
                          , tplDocument.acs_division_account_id
                          , tplDocument.acs_cda_account_id
                          , tplDocument.acs_cpn_account_id
                          , tplDocument.acs_pf_account_id
                          , tplDocument.acs_pj_account_id
                          , type_catalogue
                          , tplDocument.foo_document_total_amount
                          , tplDocument.foo_document_tot_amount_b
                          , tplDocument.foo_document_tot_amount_e
                          , tplDocument.foo_total_vat_amount
                          , tplDocument.foo_tot_vat_amount_b
                          , tplDocument.foo_tot_vat_amount_e
                          , tplDocument.foo_tot_vat_amount_v
                          , rate_factor
                          , rate_of_exchange
                          , vat_rate_factor
                          , vat_rate_of_exchange
                          , tplDocument.c_round_type
                          , part_imputation_id
                          , bln_foreign_currency
                          , tplDocument.gau_describe
                          , tplDocument.gas_financial_charge
                          , tplDocument.gas_anal_charge
                          , vQueuing
                           );

          -- boucle sur toutes les positions du document
          for tplPosition in crPositions(aDocumentId) loop
            declare
              vImputationId         ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
              vMainImputationId     ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
              vTotVatParityAmountLC ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_LC%type         := 0;
              lc_vat_parity_amount  ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_LC%type             := 0;
              fc_vat_parity_amount  ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_FC%type             := 0;
              vTotVatParityAmountFC ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_FC%type         := 0;
              eur_vat_parity_amount ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_EUR%type            := 0;
              vc_vat_parity_amount  ACI_FINANCIAL_IMPUTATION.TAX_VAT_AMOUNT_VC%type             := 0;
              vTotVatParityAmountVC ACI_FINANCIAL_IMPUTATION.TAX_TOT_VAT_AMOUNT_VC%type         := 0;
            begin
              if    vNbDiffDeliveryDate > 1
                 or (    vNbPos = 1
                     and vNbDiffDeliveryDate = 1) then
                vImpDeliveryDate  :=
                    nvl(tplPosition.POS_DATE_DELIVERY, nvl(tplDocument.DMT_DATE_DELIVERY, tplDocument.DMT_DATE_VALUE) );
              elsif     vNbDiffDeliveryDate = 1
                    and vIsNullDeliveryDates = 0 then
                vImpDeliveryDate  := tplDocument.DMT_DATE_VALUE;
              else
                vImpDeliveryDate  := tplDocument.DMT_DATE_VALUE;
              end if;

              -- test if ventilation is needed
              if tplPosition.POS_IMPUTATION = 1 then
                for tplVentilation in crVentilation(tplPosition.DOC_POSITION_ID, null, null) loop
                  positionImputation(new_document_id
                                   , tplPosition.pos_include_tax_tariff
                                   , tplPosition.pos_short_description || ' ' || tplPosition.pos_reference
                                   , tplPosition.pos_number
                                   , tplVentilation.acs_financial_account_id
                                   , tplVentilation.acs_division_account_id
                                   , tplVentilation.acs_cda_account_id
                                   , tplVentilation.acs_cpn_account_id
                                   , tplVentilation.acs_pf_account_id
                                   , tplVentilation.acs_pj_account_id
                                   , tplDocument.c_admin_domain
                                   , tplDocument.c_gauge_title
                                   , type_catalogue
                                   , tplDocument.dmt_date_document
                                   , vImpDeliveryDate
                                   , tplDocument.dmt_date_value
                                   , tplDocument.acs_financial_currency_id
                                   , tplPosition.acs_tax_code_id
                                   , tplPosition.gco_good_id
                                   , tplPosition.pac_third_id
                                   , tplVentilation.doc_record_id
                                   , tplVentilation.hrm_person_id
                                   , tplVentilation.fam_fixed_assets_id
                                   , tplVentilation.c_fam_transaction_typ
                                   , tplVentilation.poi_imf_number_2
                                   , tplVentilation.poi_imf_number_3
                                   , tplVentilation.poi_imf_number_4
                                   , tplVentilation.poi_imf_number_5
                                   , tplVentilation.poi_imf_text_1
                                   , tplVentilation.poi_imf_text_2
                                   , tplVentilation.poi_imf_text_3
                                   , tplVentilation.poi_imf_text_4
                                   , tplVentilation.poi_imf_text_5
                                   , tplVentilation.poi_imf_date_1
                                   , tplVentilation.poi_imf_date_2
                                   , tplVentilation.poi_imf_date_3
                                   , tplVentilation.poi_imf_date_4
                                   , tplVentilation.poi_imf_date_5
                                   , tplVentilation.dic_imp_free1_id
                                   , tplVentilation.dic_imp_free2_id
                                   , tplVentilation.dic_imp_free3_id
                                   , tplVentilation.dic_imp_free4_id
                                   , tplVentilation.dic_imp_free5_id
                                   , tplVentilation.POI_AMOUNT
                                   , tplVentilation.POI_AMOUNT_b
                                   , tplVentilation.POI_AMOUNT_e
                                   , tplVentilation.POI_AMOUNT_v
                                   , rate_factor
                                   , rate_of_exchange
                                   , vat_rate_factor
                                   , vat_rate_of_exchange
                                   , part_imputation_id
                                   , tplDocument.c_round_type
                                   , tplPosition.pos_vat_rate
                                   , tplPosition.pos_vat_liabled_rate
                                   , lc_vat_amount
                                   , fc_vat_amount
                                   , eur_vat_amount
                                   , vc_vat_amount
                                   , tplPosition.pos_vat_deductible_rate
                                   , vTotVatAmountLC
                                   , vTotVatAmountFC
                                   , vTotVatAmountVC
                                   , tplDocument.acs_acs_financial_currency_id
                                   , bln_foreign_currency
                                   , vImputationId
                                   , tplDocument.gas_financial_charge
                                   , tplDocument.gas_anal_charge
                                   , vQueuing
                                    );
                  vMainImputationId      := nvl(vMainImputationId, vImputationId);
                  -- mise à jour totalisateurs
                  lc_vat_parity_amount   := lc_vat_parity_amount + lc_vat_amount;
                  fc_vat_parity_amount   := fc_vat_parity_amount + fc_vat_amount;
                  eur_vat_parity_amount  := eur_vat_parity_amount + eur_vat_amount;
                  vc_vat_parity_amount   := vc_vat_parity_amount + vc_vat_amount;
                  vTotVatParityAmountLC  := vTotVatParityAmountLC + vTotVatAmountLC;
                  vTotVatParityAmountFC  := vTotVatParityAmountFC + vTotVatAmountFC;
                  vTotVatParityAmountVC  := vTotVatParityAmountVC + vTotVatAmountVC;
                end loop;
              else
                -- creation d'une imputation financière et d'une imputation analytique par position
                positionImputation(new_document_id
                                 , tplPosition.pos_include_tax_tariff
                                 , tplPosition.pos_short_description || ' ' || tplPosition.pos_reference
                                 , tplPosition.pos_number
                                 , tplPosition.acs_financial_account_id
                                 , tplPosition.acs_division_account_id
                                 , tplPosition.acs_cda_account_id
                                 , tplPosition.acs_cpn_account_id
                                 , tplPosition.acs_pf_account_id
                                 , tplPosition.acs_pj_account_id
                                 , tplDocument.c_admin_domain
                                 , tplDocument.c_gauge_title
                                 , type_catalogue
                                 , tplDocument.dmt_date_document
                                 , vImpDeliveryDate
                                 , tplDocument.dmt_date_value
                                 , tplDocument.acs_financial_currency_id
                                 , tplPosition.acs_tax_code_id
                                 , tplPosition.gco_good_id
                                 , tplPosition.pac_third_id
                                 , tplPosition.doc_record_id
                                 , tplPosition.hrm_person_id
                                 , tplPosition.fam_fixed_assets_id
                                 , tplPosition.c_fam_transaction_typ
                                 , tplPosition.pos_imf_number_2
                                 , tplPosition.pos_imf_number_3
                                 , tplPosition.pos_imf_number_4
                                 , tplPosition.pos_imf_number_5
                                 , tplPosition.pos_imf_text_1
                                 , tplPosition.pos_imf_text_2
                                 , tplPosition.pos_imf_text_3
                                 , tplPosition.pos_imf_text_4
                                 , tplPosition.pos_imf_text_5
                                 , tplPosition.pos_imf_date_1
                                 , tplPosition.pos_imf_date_2
                                 , tplPosition.pos_imf_date_3
                                 , tplPosition.pos_imf_date_4
                                 , tplPosition.pos_imf_date_5
                                 , tplPosition.dic_imp_free1_id
                                 , tplPosition.dic_imp_free2_id
                                 , tplPosition.dic_imp_free3_id
                                 , tplPosition.dic_imp_free4_id
                                 , tplPosition.dic_imp_free5_id
                                 , tplPosition.pos_gross_value
                                 , tplPosition.pos_gross_value_b
                                 , tplPosition.pos_gross_value_e
                                 , tplPosition.pos_gross_value_v
                                 , rate_factor
                                 , rate_of_exchange
                                 , vat_rate_factor
                                 , vat_rate_of_exchange
                                 , part_imputation_id
                                 , tplDocument.c_round_type
                                 , tplPosition.pos_vat_rate
                                 , tplPosition.pos_vat_liabled_rate
                                 , lc_vat_amount
                                 , fc_vat_amount
                                 , eur_vat_amount
                                 , vc_vat_amount
                                 , tplPosition.pos_vat_deductible_rate
                                 , vTotVatAmountLC
                                 , vTotVatAmountFC
                                 , vTotVatAmountVC
                                 , tplDocument.acs_acs_financial_currency_id
                                 , bln_foreign_currency
                                 , vMainImputationId
                                 , tplDocument.gas_financial_charge
                                 , tplDocument.gas_anal_charge
                                 , vQueuing
                                  );
                -- mise à jour totalisateurs
                lc_vat_parity_amount   := lc_vat_amount;
                fc_vat_parity_amount   := fc_vat_amount;
                eur_vat_parity_amount  := eur_vat_amount;
                vc_vat_parity_amount   := vc_vat_amount;
                vTotVatParityAmountLC  := vTotVatAmountLC;
                vTotVatParityAmountFC  := vTotVatAmountFC;
                vTotVatParityAmountVC  := vTotVatAmountVC;
              end if;

              -- boucle sur toutes les remises et taxes de la position
              for tplCharge in crCharge(tplPosition.doc_position_id) loop
                if    tplPosition.POS_IMPUTATION = 1
                   or tplCharge.PCH_IMPUTATION = 1 then
                  for tplVentilation in crVentilation(null, tplCharge.DOC_POSITION_CHARGE_ID, null) loop
                    -- création d'une imputation financière pour la taxe
                    positionChargeImputation(new_document_id
                                           , tplCharge.c_financial_charge
                                           , tplPosition.pos_include_tax_tariff
                                           , tplCharge.pch_description
                                           , tplPosition.pos_number
                                           , tplVentilation.acs_financial_account_id
                                           , tplVentilation.acs_division_account_id
                                           , tplVentilation.acs_cda_account_id
                                           , tplVentilation.acs_cpn_account_id
                                           , tplVentilation.acs_pf_account_id
                                           , tplVentilation.acs_pj_account_id
                                           , tplDocument.c_admin_domain
                                           , tplDocument.c_gauge_title
                                           , type_catalogue
                                           , tplDocument.dmt_date_document
                                           , vImpDeliveryDate
                                           , tplDocument.dmt_date_value
                                           , tplDocument.acs_financial_currency_id
                                           , tplPosition.acs_tax_code_id
                                           , tplPosition.pos_gross_value
                                           , tplPosition.pos_gross_value_b
                                           , tplPosition.pos_gross_value_e
                                           , tplVentilation.POI_AMOUNT
                                           , tplVentilation.POI_AMOUNT_b
                                           , tplVentilation.POI_AMOUNT_e
                                           , tplVentilation.POI_AMOUNT_v
                                           , rate_factor
                                           , rate_of_exchange
                                           , vat_rate_factor
                                           , vat_rate_of_exchange
                                           , part_imputation_id
                                           , tplDocument.c_round_type
                                           , bln_foreign_currency
                                           , tplVentilation.doc_record_id
                                           , tplPosition.gco_good_id
                                           , tplPosition.pac_third_id
                                           , tplVentilation.hrm_person_id
                                           , tplVentilation.fam_fixed_assets_id
                                           , tplVentilation.c_fam_transaction_typ
                                           , tplVentilation.POI_IMF_NUMBER_1
                                           , tplVentilation.POI_IMF_NUMBER_2
                                           , tplVentilation.POI_IMF_NUMBER_3
                                           , tplVentilation.POI_IMF_NUMBER_4
                                           , tplVentilation.POI_IMF_NUMBER_5
                                           , tplVentilation.POI_IMF_TEXT_1
                                           , tplVentilation.POI_IMF_TEXT_2
                                           , tplVentilation.POI_IMF_TEXT_3
                                           , tplVentilation.POI_IMF_TEXT_4
                                           , tplVentilation.POI_IMF_TEXT_5
                                           , tplVentilation.POI_IMF_DATE_1
                                           , tplVentilation.POI_IMF_DATE_2
                                           , tplVentilation.POI_IMF_DATE_3
                                           , tplVentilation.POI_IMF_DATE_4
                                           , tplVentilation.POI_IMF_DATE_5
                                           , tplVentilation.dic_imp_free1_id
                                           , tplVentilation.dic_imp_free2_id
                                           , tplVentilation.dic_imp_free3_id
                                           , tplVentilation.dic_imp_free4_id
                                           , tplVentilation.dic_imp_free5_id
                                           , tplPosition.pos_vat_rate
                                           , tplPosition.pos_vat_liabled_rate
                                           , lc_vat_amount
                                           , fc_vat_amount
                                           , eur_vat_amount
                                           , vc_vat_amount
                                           , tplPosition.pos_vat_deductible_rate
                                           , vTotVatAmountLC
                                           , vTotVatAmountFC
                                           , vTotVatAmountVC
                                           , tplDocument.acs_acs_financial_currency_id
                                           , tplDocument.gas_financial_charge
                                           , tplDocument.gas_anal_charge
                                           , vQueuing
                                           , vMainImputationId
                                            );

                    -- mise à jour totalisateurs
                    if tplCharge.c_financial_charge = '02' then
                      lc_vat_parity_amount   := lc_vat_parity_amount - lc_vat_amount;
                      fc_vat_parity_amount   := fc_vat_parity_amount - fc_vat_amount;
                      eur_vat_parity_amount  := eur_vat_parity_amount - eur_vat_amount;
                      vc_vat_parity_amount   := vc_vat_parity_amount - vc_vat_amount;
                      vTotVatParityAmountLC  := vTotVatParityAmountLC - vTotVatAmountLC;
                      vTotVatParityAmountFC  := vTotVatParityAmountFC - vTotVatAmountFC;
                      vTotVatParityAmountVC  := vTotVatParityAmountVC - vTotVatAmountVC;
                    else
                      lc_vat_parity_amount   := lc_vat_parity_amount + lc_vat_amount;
                      fc_vat_parity_amount   := fc_vat_parity_amount + fc_vat_amount;
                      eur_vat_parity_amount  := eur_vat_parity_amount + eur_vat_amount;
                      vc_vat_parity_amount   := vc_vat_parity_amount + vc_vat_amount;
                      vTotVatParityAmountLC  := vTotVatParityAmountLC + vTotVatAmountLC;
                      vTotVatParityAmountFC  := vTotVatParityAmountFC + vTotVatAmountFC;
                      vTotVatParityAmountVC  := vTotVatParityAmountVC + vTotVatAmountVC;
                    end if;
                  end loop;
                else
                  -- création d'une imputation financière pour la taxe
                  positionChargeImputation(new_document_id
                                         , tplCharge.c_financial_charge
                                         , tplPosition.pos_include_tax_tariff
                                         , tplCharge.pch_description
                                         , tplPosition.pos_number
                                         , tplCharge.acs_financial_account_id
                                         , tplCharge.acs_division_account_id
                                         , tplCharge.acs_cda_account_id
                                         , tplCharge.acs_cpn_account_id
                                         , tplCharge.acs_pf_account_id
                                         , tplCharge.acs_pj_account_id
                                         , tplDocument.c_admin_domain
                                         , tplDocument.c_gauge_title
                                         , type_catalogue
                                         , tplDocument.dmt_date_document
                                         , vImpDeliveryDate
                                         , tplDocument.dmt_date_value
                                         , tplDocument.acs_financial_currency_id
                                         , tplPosition.acs_tax_code_id
                                         , tplPosition.pos_gross_value
                                         , tplPosition.pos_gross_value_b
                                         , tplPosition.pos_gross_value_e
                                         , tplCharge.pch_amount
                                         , tplCharge.pch_amount_b
                                         , tplCharge.pch_amount_e
                                         , tplCharge.pch_amount_v
                                         , rate_factor
                                         , rate_of_exchange
                                         , vat_rate_factor
                                         , vat_rate_of_exchange
                                         , part_imputation_id
                                         , tplDocument.c_round_type
                                         , bln_foreign_currency
                                         , tplPosition.doc_record_id
                                         , tplPosition.gco_good_id
                                         , tplPosition.pac_third_id
                                         , tplCharge.hrm_person_id
                                         , tplCharge.fam_fixed_assets_id
                                         , tplCharge.c_fam_transaction_typ
                                         , tplCharge.pch_imp_number_1
                                         , tplCharge.pch_imp_number_2
                                         , tplCharge.pch_imp_number_3
                                         , tplCharge.pch_imp_number_4
                                         , tplCharge.pch_imp_number_5
                                         , tplCharge.pch_imp_text_1
                                         , tplCharge.pch_imp_text_2
                                         , tplCharge.pch_imp_text_3
                                         , tplCharge.pch_imp_text_4
                                         , tplCharge.pch_imp_text_5
                                         , tplCharge.pch_imp_date_1
                                         , tplCharge.pch_imp_date_2
                                         , tplCharge.pch_imp_date_3
                                         , tplCharge.pch_imp_date_4
                                         , tplCharge.pch_imp_date_5
                                         , tplCharge.dic_imp_free1_id
                                         , tplCharge.dic_imp_free2_id
                                         , tplCharge.dic_imp_free3_id
                                         , tplCharge.dic_imp_free4_id
                                         , tplCharge.dic_imp_free5_id
                                         , tplPosition.pos_vat_rate
                                         , tplPosition.pos_vat_liabled_rate
                                         , lc_vat_amount
                                         , fc_vat_amount
                                         , eur_vat_amount
                                         , vc_vat_amount
                                         , tplPosition.pos_vat_deductible_rate
                                         , vTotVatAmountLC
                                         , vTotVatAmountFC
                                         , vTotVatAmountVC
                                         , tplDocument.acs_acs_financial_currency_id
                                         , tplDocument.gas_financial_charge
                                         , tplDocument.gas_anal_charge
                                         , vQueuing
                                         , vMainImputationId
                                          );

                  -- mise à jour totalisateurs
                  if tplCharge.c_financial_charge = '02' then
                    lc_vat_parity_amount   := lc_vat_parity_amount - lc_vat_amount;
                    fc_vat_parity_amount   := fc_vat_parity_amount - fc_vat_amount;
                    eur_vat_parity_amount  := eur_vat_parity_amount - eur_vat_amount;
                    vc_vat_parity_amount   := vc_vat_parity_amount - vc_vat_amount;
                    vTotVatParityAmountLC  := vTotVatParityAmountLC - vTotVatAmountLC;
                    vTotVatParityAmountFC  := vTotVatParityAmountFC - vTotVatAmountFC;
                    vTotVatParityAmountVC  := vTotVatParityAmountVC - vTotVatAmountVC;
                  else
                    lc_vat_parity_amount   := lc_vat_parity_amount + lc_vat_amount;
                    fc_vat_parity_amount   := fc_vat_parity_amount + fc_vat_amount;
                    eur_vat_parity_amount  := eur_vat_parity_amount + eur_vat_amount;
                    vc_vat_parity_amount   := vc_vat_parity_amount + vc_vat_amount;
                    vTotVatParityAmountLC  := vTotVatParityAmountLC + vTotVatAmountLC;
                    vTotVatParityAmountFC  := vTotVatParityAmountFC + vTotVatAmountFC;
                    vTotVatParityAmountVC  := vTotVatParityAmountVC + vTotVatAmountVC;
                  end if;
                end if;
              end loop;

              if tplPosition.pos_include_tax_tariff = 1 then
                -- controle de cohérence et éventuellement correction en monnaie locale
                if    (    tplDocument.c_admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                       and type_catalogue in('5', '6')
                      )
                   or (    tplDocument.c_admin_domain in(cAdminDomainSale)
                       and type_catalogue in('2') )
                   or (tplDocument.c_gauge_title in('5', '6', '8', '30') ) then
                  -- correction des erreur d'arrondi TVA en monnaie de base
                  if    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and (   abs(tplPosition.pos_vat_base_amount) <> lc_vat_parity_amount
                              or abs(tplPosition.pos_vat_total_amount_b) <> vTotVatParityAmountLC
                             )
                        )
                     or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and (   abs(tplPosition.pos_net_value_excl_b) <> lc_vat_parity_amount
                              or abs(tplPosition.pos_net_value_excl_b) <> vTotVatParityAmountLC
                             )
                        ) then
                    lc_vat_dif_amount   := abs(tplPosition.pos_vat_base_amount) - abs(lc_vat_parity_amount);
                    vTotVatDifAmountLC  := abs(tplPosition.pos_vat_total_amount_b) - abs(vTotVatParityAmountLC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_LC = TAX_VAT_AMOUNT_LC + lc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_LC = TAX_TOT_VAT_AMOUNT_LC + vTotVatDifAmountLC
                         , TAX_LIABLED_AMOUNT =
                               sign(TAX_VAT_AMOUNT_LC) *
                               (sign(TAX_VAT_AMOUNT_LC) * TAX_LIABLED_AMOUNT - lc_vat_dif_amount
                               )
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    if ACS_FUNCTION.GetLocalCurrencyId = tplDocument.acs_acs_financial_currency_id then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_VAT_AMOUNT_VC = TAX_VAT_AMOUNT_LC
                           , TAX_TOT_VAT_AMOUNT_VC = TAX_TOT_VAT_AMOUNT_LC
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;

                    -- Cas 5
                    if     tplDocument.acs_financial_currency_id <> ACS_FUNCTION.GetLocalCurrencyId
                       and tplDocument.acs_acs_financial_currency_id <> ACS_FUNCTION.GetLocalCurrencyId
                       and tplDocument.acs_acs_financial_currency_id <> tplDocument.acs_financial_currency_id then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_EXCHANGE_RATE =
                                 decode(TAX_VAT_AMOUNT_LC
                                      , 0, 0
                                      , (TAX_VAT_AMOUNT_VC * DET_BASE_PRICE) / TAX_VAT_AMOUNT_LC
                                       )
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;

                    update ACI_MGM_IMPUTATION
                       set IMM_AMOUNT_LC_C = decode(IMM_AMOUNT_LC_C, 0, 0, IMM_AMOUNT_LC_C - lc_vat_dif_amount)
                         , IMM_AMOUNT_LC_D = decode(IMM_AMOUNT_LC_D, 0, 0, IMM_AMOUNT_LC_D - lc_vat_dif_amount)
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;

                  -- correction des erreur d'arrondi TVA en EURO
                  if    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and abs(tplPosition.pos_vat_amount_e) <> eur_vat_parity_amount
                        )
                     or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and abs(tplPosition.pos_net_value_excl_e) <> eur_vat_parity_amount
                        ) then
                    eur_vat_dif_amount  := tplPosition.pos_vat_amount_e - eur_vat_parity_amount;

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_EUR = TAX_VAT_AMOUNT_EUR + eur_vat_dif_amount
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    update ACI_MGM_IMPUTATION
                       set IMM_AMOUNT_EUR_C = decode(IMM_AMOUNT_EUR_C, 0, 0, IMM_AMOUNT_EUR_C - eur_vat_dif_amount)
                         , IMM_AMOUNT_EUR_D = decode(IMM_AMOUNT_EUR_D, 0, 0, IMM_AMOUNT_EUR_D - eur_vat_dif_amount)
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;

                  -- controle de cohérence et éventuellement correction en monnaie étrangère
                  if     ACS_FUNCTION.GetLocalCurrencyId <> tplDocument.acs_financial_currency_id
                     and (    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                               and (   abs(tplPosition.pos_vat_amount) <> fc_vat_parity_amount
                                    or abs(tplPosition.pos_vat_total_amount) <> vTotVatParityAmountFC
                                   )
                              )
                          or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                              and (   abs(tplPosition.pos_net_value_excl) <> fc_vat_parity_amount
                                   or abs(tplPosition.pos_net_value_excl) <> vTotVatParityAmountFC
                                  )
                             )
                         ) then
                    fc_vat_dif_amount   := abs(tplPosition.pos_vat_amount) - abs(fc_vat_parity_amount);
                    vTotVatDifAmountFC  := abs(tplPosition.pos_vat_total_amount) - abs(vTotVatParityAmountFC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_FC = TAX_VAT_AMOUNT_FC + fc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_FC = TAX_TOT_VAT_AMOUNT_FC + vTotVatDifAmountFC
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    -- Cas 2
                    if     tplDocument.acs_financial_currency_id <> tplDocument.acs_acs_financial_currency_id
                       and tplDocument.acs_acs_financial_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_EXCHANGE_RATE =
                                 decode(TAX_VAT_AMOUNT_FC
                                      , 0, 0
                                      , (TAX_VAT_AMOUNT_VC * DET_BASE_PRICE) / TAX_VAT_AMOUNT_FC
                                       )
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;

                    update ACI_MGM_IMPUTATION
                       set IMM_AMOUNT_FC_C = decode(IMM_AMOUNT_FC_C, 0, 0, IMM_AMOUNT_FC_C - fc_vat_dif_amount)
                         , IMM_AMOUNT_FC_D = decode(IMM_AMOUNT_FC_D, 0, 0, IMM_AMOUNT_FC_D - fc_vat_dif_amount)
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;

                  -- controle de cohérence et éventuellement correction en monnaie TVA
                  if     ACS_FUNCTION.GetLocalCurrencyId <> tplDocument.acs_acs_financial_currency_id
                     and (    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                               and (   abs(tplPosition.pos_vat_amount_v) <> vc_vat_parity_amount
                                    or abs(tplPosition.pos_vat_total_amount_v) <> vTotVatParityAmountVC
                                   )
                              )
                          or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                              and (   abs(tplPosition.pos_net_value_excl_v) <> vc_vat_parity_amount
                                   or abs(tplPosition.pos_net_value_excl_v) <> vTotVatParityAmountVC
                                  )
                             )
                         ) then
                    vc_vat_dif_amount   := abs(tplPosition.pos_vat_amount_v) - abs(vc_vat_parity_amount);
                    vTotVatDifAmountVC  := abs(tplPosition.pos_vat_total_amount_v) - abs(vTotVatParityAmountVC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_VC = TAX_VAT_AMOUNT_VC + vc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_VC = TAX_TOT_VAT_AMOUNT_VC + vTotVatDifAmountVC
                         , TAX_EXCHANGE_RATE =
                             decode(TAX_VAT_AMOUNT_VC + vc_vat_dif_amount
                                  , 0, 0
                                  , (TAX_VAT_AMOUNT_LC * DET_BASE_PRICE) /(TAX_VAT_AMOUNT_VC + vc_vat_dif_amount)
                                   )
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;
                elsif    (    tplDocument.c_admin_domain in(cAdminDomainSale)
                          and type_catalogue in('5', '6') )
                      or (    tplDocument.c_admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                          and type_catalogue in('2')
                         )
                      or (tplDocument.c_gauge_title in('1', '4', '9') ) then
                  -- correction des erreur d'arrondi TVA en monnaie de base
                  if    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and (   abs(tplPosition.pos_vat_base_amount) <> lc_vat_parity_amount
                              or abs(tplPosition.pos_vat_total_amount_b) <> vTotVatParityAmountLC
                             )
                        )
                     or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and (   abs(tplPosition.pos_net_value_excl) <> lc_vat_parity_amount
                              or abs(tplPosition.pos_net_value_excl_b) <> vTotVatParityAmountLC
                             )
                        ) then
                    lc_vat_dif_amount   := abs(tplPosition.pos_vat_base_amount) - abs(lc_vat_parity_amount);
                    vTotVatDifAmountLC  := abs(tplPosition.pos_vat_base_amount) - abs(vTotVatParityAmountLC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_LC = TAX_VAT_AMOUNT_LC + lc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_LC = TAX_TOT_VAT_AMOUNT_LC + vTotVatDifAmountLC
                         , TAX_LIABLED_AMOUNT =
                               sign(TAX_VAT_AMOUNT_LC) *
                               (sign(TAX_VAT_AMOUNT_LC) * TAX_LIABLED_AMOUNT - lc_vat_dif_amount
                               )
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    if ACS_FUNCTION.GetLocalCurrencyId = tplDocument.acs_acs_financial_currency_id then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_VAT_AMOUNT_VC = TAX_VAT_AMOUNT_LC
                           , TAX_TOT_VAT_AMOUNT_VC = TAX_TOT_VAT_AMOUNT_LC
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;

                    -- Cas 5
                    if     tplDocument.acs_financial_currency_id <> ACS_FUNCTION.GetLocalCurrencyId
                       and tplDocument.acs_acs_financial_currency_id <> ACS_FUNCTION.GetLocalCurrencyId
                       and tplDocument.acs_acs_financial_currency_id <> tplDocument.acs_financial_currency_id then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_EXCHANGE_RATE =
                                 decode(TAX_VAT_AMOUNT_VC
                                      , 0, 0
                                      , (TAX_VAT_AMOUNT_LC * DET_BASE_PRICE) / TAX_VAT_AMOUNT_VC
                                       )
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;

                    update ACI_MGM_IMPUTATION
                       set IMM_AMOUNT_LC_D = IMM_AMOUNT_LC_D - lc_vat_dif_amount
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;

                  -- correction des erreur d'arrondi TVA en monnaie de base
                  if    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and abs(tplPosition.pos_vat_amount_e) <> eur_vat_parity_amount
                        )
                     or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and abs(tplPosition.pos_net_value_excl_e) <> eur_vat_parity_amount
                        ) then
                    eur_vat_dif_amount  := -abs(tplPosition.pos_vat_amount_e) + abs(eur_vat_parity_amount);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_EUR = TAX_VAT_AMOUNT_EUR + eur_vat_dif_amount
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    update ACI_MGM_IMPUTATION
                       set IMM_AMOUNT_EUR_D = IMM_AMOUNT_EUR_D - eur_vat_dif_amount
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;

                  -- controle de cohérence et éventuellement correction en monnaie étrangère
                  if     ACS_FUNCTION.GetLocalCurrencyId <> tplDocument.acs_financial_currency_id
                     and (    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                               and abs(tplPosition.pos_vat_amount) <> fc_vat_parity_amount
                              )
                          or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                              and abs(tplPosition.pos_net_value_excl) <> fc_vat_parity_amount
                             )
                         ) then
                    fc_vat_dif_amount   := -abs(tplPosition.pos_vat_amount) + abs(fc_vat_parity_amount);
                    vTotVatDifAmountFC  := -abs(tplPosition.pos_vat_total_amount) + abs(vTotVatParityAmountFC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_FC = TAX_VAT_AMOUNT_FC + fc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_FC = TAX_TOT_VAT_AMOUNT_FC + vTotVatDifAmountFC
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    -- Cas 2
                    if     tplDocument.acs_financial_currency_id <> tplDocument.acs_acs_financial_currency_id
                       and tplDocument.acs_acs_financial_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_EXCHANGE_RATE =
                                 decode(TAX_VAT_AMOUNT_FC
                                      , 0, 0
                                      , (TAX_VAT_AMOUNT_VC * DET_BASE_PRICE) / TAX_VAT_AMOUNT_FC
                                       )
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;

                    update ACI_MGM_IMPUTATION
                       set IMM_AMOUNT_FC_D = IMM_AMOUNT_FC_D - fc_vat_dif_amount
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;

                  -- controle de cohérence et éventuellement correction en monnaie TVA
                  if     ACS_FUNCTION.GetLocalCurrencyId <> tplDocument.acs_acs_financial_currency_id
                     and (    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                               and abs(tplPosition.pos_vat_amount_v) <> vc_vat_parity_amount
                              )
                          or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                              and abs(tplPosition.pos_net_value_excl_v) <> vc_vat_parity_amount
                             )
                         ) then
                    vc_vat_dif_amount   := -abs(tplPosition.pos_vat_amount_v) + abs(vc_vat_parity_amount);
                    vTotVatDifAmountVC  := -abs(tplPosition.pos_vat_total_amount_v) + abs(vTotVatParityAmountVC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_VC = TAX_VAT_AMOUNT_VC + vc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_VC = TAX_TOT_VAT_AMOUNT_VC + vTotVatDifAmountVC
                         , TAX_EXCHANGE_RATE =
                             decode( (TAX_VAT_AMOUNT_VC + vc_vat_dif_amount)
                                  , 0, 0
                                  , (TAX_VAT_AMOUNT_LC * DET_BASE_PRICE) /(TAX_VAT_AMOUNT_VC + vc_vat_dif_amount)
                                   )
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;
                end if;
              else
                -- controle de cohérence et éventuellement correction en monnaie locale
                if    (    tplDocument.c_admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                       and type_catalogue in('5', '6')
                      )
                   or (    tplDocument.c_admin_domain in(cAdminDomainSale)
                       and type_catalogue in('2') )
                   or (tplDocument.c_gauge_title in('5', '6', '8', '30') ) then
                  -- correction des erreur d'arrondi TVA en monnaie de base
                  if    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and (   abs(tplPosition.pos_vat_base_amount) <> lc_vat_parity_amount
                              or abs(tplPosition.pos_vat_total_amount_b) <> vTotVatParityAmountLC
                             )
                        )
                     or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and (   abs(tplPosition.pos_net_value_excl) <> lc_vat_parity_amount
                              or abs(tplPosition.pos_net_value_excl) <> vTotVatParityAmountLC
                             )
                        ) then
                    lc_vat_dif_amount   := abs(tplPosition.pos_vat_base_amount) - abs(lc_vat_parity_amount);
                    vTotVatDifAmountLC  := abs(tplPosition.pos_vat_total_amount_b) - abs(vTotVatParityAmountLC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_LC = TAX_VAT_AMOUNT_LC + lc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_LC = TAX_TOT_VAT_AMOUNT_LC + vTotVatDifAmountLC
                         , IMF_AMOUNT_LC_C = decode(IMF_AMOUNT_LC_C, 0, 0, IMF_AMOUNT_LC_C + lc_vat_dif_amount)
                         , IMF_AMOUNT_LC_D = decode(IMF_AMOUNT_LC_D, 0, 0, IMF_AMOUNT_LC_D + lc_vat_dif_amount)
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    if ACS_FUNCTION.GetLocalCurrencyId = tplDocument.acs_acs_financial_currency_id then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_VAT_AMOUNT_VC = TAX_VAT_AMOUNT_LC
                           , TAX_TOT_VAT_AMOUNT_VC = TAX_TOT_VAT_AMOUNT_LC
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;

                    -- Cas 5
                    if     tplDocument.acs_financial_currency_id <> ACS_FUNCTION.GetLocalCurrencyId
                       and tplDocument.acs_acs_financial_currency_id <> ACS_FUNCTION.GetLocalCurrencyId
                       and tplDocument.acs_acs_financial_currency_id <> tplDocument.acs_financial_currency_id then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_EXCHANGE_RATE =
                                 decode(TAX_VAT_AMOUNT_VC
                                      , 0, 0
                                      , (TAX_VAT_AMOUNT_LC * DET_BASE_PRICE) / TAX_VAT_AMOUNT_VC
                                       )
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;
                  end if;

                  -- correction des erreur d'arrondi TVA en EURO
                  if    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and abs(tplPosition.pos_vat_amount_e) <> eur_vat_parity_amount
                        )
                     or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and abs(tplPosition.pos_net_value_excl_e) <> eur_vat_parity_amount
                        ) then
                    eur_vat_dif_amount  := abs(tplPosition.pos_vat_amount_e) - abs(eur_vat_parity_amount);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_EUR = TAX_VAT_AMOUNT_EUR + eur_vat_dif_amount
                         , IMF_AMOUNT_EUR_C = decode(IMF_AMOUNT_EUR_C, 0, 0, IMF_AMOUNT_EUR_C + eur_vat_dif_amount)
                         , IMF_AMOUNT_EUR_D = decode(IMF_AMOUNT_EUR_D, 0, 0, IMF_AMOUNT_EUR_D + eur_vat_dif_amount)
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;

                  -- controle de cohérence et éventuellement correction en monnaie étrangère
                  if     ACS_FUNCTION.GetLocalCurrencyId <> tplDocument.acs_financial_currency_id
                     and (    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                               and (   abs(tplPosition.pos_vat_amount) <> fc_vat_parity_amount
                                    or abs(tplPosition.pos_vat_total_amount) <> vTotVatParityAmountFC
                                   )
                              )
                          or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                              and (   abs(tplPosition.pos_net_value_excl) <> fc_vat_parity_amount
                                   or abs(tplPosition.pos_net_value_excl) <> vTotVatParityAmountFC
                                  )
                             )
                         ) then
                    fc_vat_dif_amount   := abs(tplPosition.pos_vat_amount) - abs(fc_vat_parity_amount);
                    vTotVatDifAmountFC  := abs(tplPosition.pos_vat_total_amount) - abs(vTotVatParityAmountFC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_FC = TAX_VAT_AMOUNT_FC + fc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_FC = TAX_TOT_VAT_AMOUNT_FC + vTotVatDifAmountFC
                         , IMF_AMOUNT_FC_C = decode(IMF_AMOUNT_FC_C, 0, 0, IMF_AMOUNT_FC_C + fc_vat_dif_amount)
                         , IMF_AMOUNT_FC_D = decode(IMF_AMOUNT_FC_D, 0, 0, IMF_AMOUNT_FC_D + fc_vat_dif_amount)
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    -- Cas 2
                    if     tplDocument.acs_financial_currency_id <> tplDocument.acs_acs_financial_currency_id
                       and tplDocument.acs_acs_financial_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_EXCHANGE_RATE =
                                 decode(TAX_VAT_AMOUNT_FC
                                      , 0, 0
                                      , (TAX_VAT_AMOUNT_VC * DET_BASE_PRICE) / TAX_VAT_AMOUNT_FC
                                       )
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;
                  end if;

                  -- controle de cohérence et éventuellement correction en monnaie TVA
                  if     ACS_FUNCTION.GetLocalCurrencyId <> tplDocument.acs_acs_financial_currency_id
                     and (    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                               and (   abs(tplPosition.pos_vat_amount_v) <> vc_vat_parity_amount
                                    or abs(tplPosition.pos_vat_total_amount_v) <> vTotVatParityAmountVC
                                   )
                              )
                          or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                              and (   abs(tplPosition.pos_net_value_excl_v) <> vc_vat_parity_amount
                                   or abs(tplPosition.pos_net_value_excl_v) <> vTotVatParityAmountVC
                                  )
                             )
                         ) then
                    vc_vat_dif_amount   := abs(tplPosition.pos_vat_amount_v) - abs(vc_vat_parity_amount);
                    vTotVatDifAmountVC  := abs(tplPosition.pos_vat_total_amount_v) - abs(vTotVatParityAmountVC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_VC = TAX_VAT_AMOUNT_VC + vc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_VC = TAX_TOT_VAT_AMOUNT_VC + vTotVatDifAmountVC
                         , TAX_EXCHANGE_RATE =
                             decode( (TAX_VAT_AMOUNT_VC + vc_vat_dif_amount)
                                  , 0, 0
                                  , (TAX_VAT_AMOUNT_LC * DET_BASE_PRICE) /(TAX_VAT_AMOUNT_VC + vc_vat_dif_amount)
                                   )
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;
                elsif    (    tplDocument.c_admin_domain in(cAdminDomainSale)
                          and type_catalogue in('5', '6') )
                      or (    tplDocument.c_admin_domain in(cAdminDomainPurchase, cAdminDomainSubContract)
                          and type_catalogue in('2')
                         )
                      or (tplDocument.c_gauge_title in('1', '4', '9') ) then
                  -- correction des erreur d'arrondi TVA en monnaie de base
                  if    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and (   abs(tplPosition.pos_vat_base_amount) <> lc_vat_parity_amount
                              or abs(tplPosition.pos_vat_total_amount_b) <> vTotVatParityAmountLC
                             )
                        )
                     or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and (   abs(tplPosition.pos_net_value_excl_b) <> lc_vat_parity_amount
                              or abs(tplPosition.pos_net_value_excl_b) <> vTotVatParityAmountLC
                             )
                        ) then
                    lc_vat_dif_amount   := -abs(lc_vat_parity_amount) + abs(tplPosition.pos_vat_base_amount);
                    vTotVatDifAmountLC  := -abs(vTotVatParityAmountLC) + abs(tplPosition.pos_vat_total_amount_b);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_LC = TAX_VAT_AMOUNT_LC + lc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_LC = TAX_TOT_VAT_AMOUNT_LC + vTotVatDifAmountLC
                         , IMF_AMOUNT_LC_D = decode(IMF_AMOUNT_LC_D, 0, 0, IMF_AMOUNT_LC_D + lc_vat_dif_amount)
                         , IMF_AMOUNT_LC_C = decode(IMF_AMOUNT_LC_C, 0, 0, IMF_AMOUNT_LC_C + lc_vat_dif_amount)
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    if ACS_FUNCTION.GetLocalCurrencyId = tplDocument.acs_acs_financial_currency_id then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_VAT_AMOUNT_VC = TAX_VAT_AMOUNT_LC
                           , TAX_TOT_VAT_AMOUNT_VC = TAX_TOT_VAT_AMOUNT_LC
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;

                    -- Cas 5
                    if     tplDocument.acs_financial_currency_id <> ACS_FUNCTION.GetLocalCurrencyId
                       and tplDocument.acs_acs_financial_currency_id <> ACS_FUNCTION.GetLocalCurrencyId
                       and tplDocument.acs_acs_financial_currency_id <> tplDocument.acs_financial_currency_id then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_EXCHANGE_RATE =
                                 decode(TAX_VAT_AMOUNT_VC
                                      , 0, 0
                                      , (TAX_VAT_AMOUNT_LC * DET_BASE_PRICE) / TAX_VAT_AMOUNT_VC
                                       )
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;
                  end if;

                  -- correction des erreur d'arrondi TVA en monnaie de base
                  if    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and abs(tplPosition.pos_vat_amount_e) <> eur_vat_parity_amount
                        )
                     or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                         and abs(tplPosition.pos_net_value_excl_e) <> eur_vat_parity_amount
                        ) then
                    eur_vat_dif_amount  := -abs(tplPosition.pos_vat_amount_e) + abs(eur_vat_parity_amount);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_EUR = TAX_VAT_AMOUNT_EUR + eur_vat_dif_amount
                         , IMF_AMOUNT_EUR_D = decode(IMF_AMOUNT_EUR_D, 0, 0, IMF_AMOUNT_EUR_D + eur_vat_dif_amount)
                         , IMF_AMOUNT_EUR_C = decode(IMF_AMOUNT_EUR_C, 0, 0, IMF_AMOUNT_EUR_C + eur_vat_dif_amount)
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;

                  -- controle de cohérence et éventuellement correction en monnaie étrangère
                  if     ACS_FUNCTION.GetLocalCurrencyId <> tplDocument.acs_financial_currency_id
                     and (    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                               and (   abs(tplPosition.pos_vat_amount) <> fc_vat_parity_amount
                                    or abs(tplPosition.pos_vat_total_amount) <> vTotVatParityAmountFC
                                   )
                              )
                          or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                              and (   abs(tplPosition.pos_net_value_excl) <> fc_vat_parity_amount
                                   or abs(tplPosition.pos_net_value_excl) <> vTotVatParityAmountFC
                                  )
                             )
                         ) then
                    fc_vat_dif_amount   := -abs(tplPosition.pos_vat_amount) + abs(fc_vat_parity_amount);
                    vTotVatDifAmountFC  := -abs(tplPosition.pos_vat_total_amount) + abs(vTotVatParityAmountFC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_FC = TAX_VAT_AMOUNT_FC + fc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_FC = TAX_TOT_VAT_AMOUNT_FC + vTotVatDifAmountFC
                         , IMF_AMOUNT_FC_D = decode(IMF_AMOUNT_FC_D, 0, 0, IMF_AMOUNT_FC_D + fc_vat_dif_amount)
                         , IMF_AMOUNT_FC_C = decode(IMF_AMOUNT_FC_C, 0, 0, IMF_AMOUNT_FC_C + fc_vat_dif_amount)
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;

                    -- Cas 2
                    if     tplDocument.acs_financial_currency_id <> tplDocument.acs_acs_financial_currency_id
                       and tplDocument.acs_acs_financial_currency_id = ACS_FUNCTION.GetLocalCurrencyId then
                      update ACI_FINANCIAL_IMPUTATION
                         set TAX_EXCHANGE_RATE =
                                 decode(TAX_VAT_AMOUNT_FC
                                      , 0, 0
                                      , (TAX_VAT_AMOUNT_VC * DET_BASE_PRICE) / TAX_VAT_AMOUNT_FC
                                       )
                       where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                    end if;
                  end if;

                  -- controle de cohérence et éventuellement correction en monnaie TVA
                  if     ACS_FUNCTION.GetLocalCurrencyId <> tplDocument.acs_acs_financial_currency_id
                     and (    (    not ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                               and (   abs(tplPosition.pos_vat_amount_v) <> vc_vat_parity_amount
                                    or abs(tplPosition.pos_vat_total_amount_v) <> vTotVatParityAmountVC
                                   )
                              )
                          or (    ACS_FUNCTION.IsInterest(tplPosition.acs_tax_code_id)
                              and (   abs(tplPosition.pos_net_value_excl_v) <> vc_vat_parity_amount
                                   or abs(tplPosition.pos_vat_total_amount_v) <> vTotVatParityAmountVC
                                  )
                             )
                         ) then
                    vc_vat_dif_amount   := -abs(tplPosition.pos_vat_amount_v) + abs(vc_vat_parity_amount);
                    vTotVatDifAmountVC  := -abs(tplPosition.pos_vat_total_amount_v) + abs(vTotVatParityAmountVC);

                    update ACI_FINANCIAL_IMPUTATION
                       set TAX_VAT_AMOUNT_VC = TAX_VAT_AMOUNT_VC + vc_vat_dif_amount
                         , TAX_TOT_VAT_AMOUNT_VC = TAX_TOT_VAT_AMOUNT_VC + vTotVatDifAmountVC
                         , TAX_EXCHANGE_RATE =
                             decode( (TAX_VAT_AMOUNT_VC + vc_vat_dif_amount)
                                  , 0, 0
                                  , (TAX_VAT_AMOUNT_LC * DET_BASE_PRICE) /(TAX_VAT_AMOUNT_VC + vc_vat_dif_amount)
                                   )
                     where ACI_FINANCIAL_IMPUTATION_ID = vMainImputationId;
                  end if;
                end if;
              end if;
            end;
          end loop;
        end if;

        -- Recherche si au moins un gabarit position est geré TTC
        select nvl(max(GAP.GAP_INCLUDE_TAX_TARIFF), 0)
          into includeTaxTariff
          from DOC_DOCUMENT DOC
             , DOC_GAUGE_POSITION GAP
         where GAP.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
           and DOC.DOC_DOCUMENT_ID = aDocumentId;

        for tplFootCharge in crFootCharge(tplDocument.doc_foot_id) loop
          if tplFootCharge.FCH_IMPUTATION = 1 then
            for tplVentilation in crVentilation(null, null, tplFootCharge.DOC_FOOT_CHARGE_ID) loop
              -- création d'une imputation financière pour la taxe
              footImputation(new_document_id
                           , includeTaxTariff
                           , tplFootCharge.c_financial_charge
                           , substr(tplFootCharge.fch_description, 1, 100)
                           , tplFootCharge.fch_excl_amount
                           , tplFootCharge.fch_excl_amount_b
                           , tplFootCharge.fch_excl_amount_e
                           , tplFootCharge.fch_incl_amount
                           , tplFootCharge.fch_incl_amount_b
                           , tplFootCharge.fch_incl_amount_e
                           , tplFootCharge.fch_vat_rate
                           , tplFootCharge.fch_vat_liabled_rate
                           , tplFootCharge.fch_vat_amount
                           , tplFootCharge.fch_vat_amount_b
                           , tplFootCharge.fch_vat_amount_e
                           , tplFootCharge.fch_vat_amount_v
                           , tplFootCharge.fch_vat_deductible_rate
                           , tplFootCharge.fch_vat_total_amount
                           , tplFootCharge.fch_vat_total_amount_b
                           , tplFootCharge.fch_vat_total_amount_v
                           , tplVentilation.acs_financial_account_id
                           , tplVentilation.acs_division_account_id
                           , tplVentilation.acs_cda_account_id
                           , tplVentilation.acs_cpn_account_id
                           , tplVentilation.acs_pf_account_id
                           , tplVentilation.acs_pj_account_id
                           , tplDocument.c_admin_domain
                           , tplDocument.c_gauge_title
                           , type_catalogue
                           , tplDocument.dmt_date_document
                           , tplDocument.dmt_date_delivery
                           , tplDocument.dmt_date_value
                           , tplDocument.acs_financial_currency_id
                           , tplFootCharge.acs_tax_code_id
                           , rate_factor
                           , rate_of_exchange
                           , vat_rate_factor
                           , vat_rate_of_exchange
                           , part_imputation_id
                           , tplDocument.c_round_type
                           , bln_foreign_currency
                           , tplDocument.gas_financial_charge
                           , tplDocument.gas_anal_charge
                           , tplVentilation.doc_record_id
                           , tplDocument.pac_third_id
                           , tplVentilation.hrm_person_id
                           , tplVentilation.fam_fixed_assets_id
                           , tplVentilation.c_fam_transaction_typ
                           , tplVentilation.poi_imf_number_1
                           , tplVentilation.poi_imf_number_2
                           , tplVentilation.poi_imf_number_3
                           , tplVentilation.poi_imf_number_4
                           , tplVentilation.poi_imf_number_5
                           , tplVentilation.poi_imf_text_1
                           , tplVentilation.poi_imf_text_2
                           , tplVentilation.poi_imf_text_3
                           , tplVentilation.poi_imf_text_4
                           , tplVentilation.poi_imf_text_5
                           , tplVentilation.poi_imf_date_1
                           , tplVentilation.poi_imf_date_2
                           , tplVentilation.poi_imf_date_3
                           , tplVentilation.poi_imf_date_4
                           , tplVentilation.poi_imf_date_5
                           , tplVentilation.dic_imp_free1_id
                           , tplVentilation.dic_imp_free2_id
                           , tplVentilation.dic_imp_free3_id
                           , tplVentilation.dic_imp_free4_id
                           , tplVentilation.dic_imp_free5_id
                           , vQueuing
                            );
            end loop;
          else
            -- création d'une imputation financière pour la taxe
            footImputation(new_document_id
                         , includeTaxTariff
                         , tplFootCharge.c_financial_charge
                         , substr(tplFootCharge.fch_description, 1, 100)
                         , tplFootCharge.fch_excl_amount
                         , tplFootCharge.fch_excl_amount_b
                         , tplFootCharge.fch_excl_amount_e
                         , tplFootCharge.fch_incl_amount
                         , tplFootCharge.fch_incl_amount_b
                         , tplFootCharge.fch_incl_amount_e
                         , tplFootCharge.fch_vat_rate
                         , tplFootCharge.fch_vat_liabled_rate
                         , tplFootCharge.fch_vat_amount
                         , tplFootCharge.fch_vat_amount_b
                         , tplFootCharge.fch_vat_amount_e
                         , tplFootCharge.fch_vat_amount_v
                         , tplFootCharge.fch_vat_deductible_rate
                         , tplFootCharge.fch_vat_total_amount
                         , tplFootCharge.fch_vat_total_amount_b
                         , tplFootCharge.fch_vat_total_amount_v
                         , tplFootCharge.acs_financial_account_id
                         , tplFootCharge.acs_division_account_id
                         , tplFootCharge.acs_cda_account_id
                         , tplFootCharge.acs_cpn_account_id
                         , tplFootCharge.acs_pf_account_id
                         , tplFootCharge.acs_pj_account_id
                         , tplDocument.c_admin_domain
                         , tplDocument.c_gauge_title
                         , type_catalogue
                         , tplDocument.dmt_date_document
                         , tplDocument.dmt_date_delivery
                         , tplDocument.dmt_date_value
                         , tplDocument.acs_financial_currency_id
                         , tplFootCharge.acs_tax_code_id
                         , rate_factor
                         , rate_of_exchange
                         , vat_rate_factor
                         , vat_rate_of_exchange
                         , part_imputation_id
                         , tplDocument.c_round_type
                         , bln_foreign_currency
                         , tplDocument.gas_financial_charge
                         , tplDocument.gas_anal_charge
                         , tplDocument.doc_record_id
                         , tplDocument.pac_third_id
                         , tplFootCharge.hrm_person_id
                         , tplFootCharge.fam_fixed_assets_id
                         , tplFootCharge.c_fam_transaction_typ
                         , tplFootCharge.fch_imp_number_1
                         , tplFootCharge.fch_imp_number_2
                         , tplFootCharge.fch_imp_number_3
                         , tplFootCharge.fch_imp_number_4
                         , tplFootCharge.fch_imp_number_5
                         , tplFootCharge.fch_imp_text_1
                         , tplFootCharge.fch_imp_text_2
                         , tplFootCharge.fch_imp_text_3
                         , tplFootCharge.fch_imp_text_4
                         , tplFootCharge.fch_imp_text_5
                         , tplFootCharge.fch_imp_date_1
                         , tplFootCharge.fch_imp_date_2
                         , tplFootCharge.fch_imp_date_3
                         , tplFootCharge.fch_imp_date_4
                         , tplFootCharge.fch_imp_date_5
                         , tplFootCharge.dic_imp_free1_id
                         , tplFootCharge.dic_imp_free2_id
                         , tplFootCharge.dic_imp_free3_id
                         , tplFootCharge.dic_imp_free4_id
                         , tplFootCharge.dic_imp_free5_id
                         , vQueuing
                          );
          end if;
        end loop;

        -- seulement si le document est en monnaie étrangère
        if ACS_FUNCTION.GetLocalCurrencyId <> tplDocument.acs_financial_currency_id then
          -- recherche de la différence entre débit et crédit sur les imputations du document
          select sum(nvl(imf_amount_lc_d, 0) - nvl(imf_amount_lc_c, 0) )
            into qty_parity
            from aci_financial_imputation
           where aci_document_id = new_document_id;

          -- correction des arrondis dus au change sur l'inputation primaire si on a un problème d'arrondi
          if qty_parity <> 0 then
            -- recherche de l'imputation qui a le plus grand montant afin de ne pas trop influencer le montant corrigé
            select max(ACI_FINANCIAL_IMPUTATION_ID)
              into max_imp_id
              from ACI_FINANCIAL_IMPUTATION
             where ACI_DOCUMENT_ID = new_document_id
               and IMF_PRIMARY = 0
               and abs(IMF_AMOUNT_LC_D) + abs(IMF_AMOUNT_LC_C) =
                                                           (select max(abs(IMF_AMOUNT_LC_D) + abs(IMF_AMOUNT_LC_C) )
                                                              from ACI_FINANCIAL_IMPUTATION
                                                             where ACI_DOCUMENT_ID = new_document_id
                                                               and IMF_PRIMARY = 0);

            -- recherche de l'imputation qui a le plus grand montant afin de ne pas trop influencer le montant corrigé
            select max(ACI_MGM_IMPUTATION_ID)
              into max_mgm_id
              from ACI_MGM_IMPUTATION
             where ACI_FINANCIAL_IMPUTATION_ID = max_imp_id
               and abs(IMM_AMOUNT_LC_D) + abs(IMM_AMOUNT_LC_C) =
                                                    (select max(abs(IMM_AMOUNT_LC_D) + abs(IMM_AMOUNT_LC_C) )
                                                       from ACI_MGM_IMPUTATION
                                                      where ACI_FINANCIAL_IMPUTATION_ID = max_imp_id
                                                        and IMM_PRIMARY = 0);

            -- correction du montant au dédit si c'est un document "débit"
            update ACI_FINANCIAL_IMPUTATION
               set IMF_AMOUNT_LC_D = IMF_AMOUNT_LC_D - qty_parity
                 , TAX_LIABLED_AMOUNT = TAX_LIABLED_AMOUNT - qty_parity * sign(IMF_AMOUNT_LC_D)
             where ACI_FINANCIAL_IMPUTATION_ID = max_imp_id
               and IMF_AMOUNT_LC_D <> 0;

            -- correction du montant analytique au dédit si c'est un document "débit"
            -- et qu'on gère les imputations analytiques
            update ACI_MGM_IMPUTATION
               set IMM_AMOUNT_LC_D = IMM_AMOUNT_LC_D - qty_parity
             where ACI_MGM_IMPUTATION_ID = max_mgm_id
               and IMM_AMOUNT_LC_D <> 0;

            -- correction du montant au crédit si c'est un document "crédit"
            update ACI_FINANCIAL_IMPUTATION
               set IMF_AMOUNT_LC_C = IMF_AMOUNT_LC_C + qty_parity
                 , TAX_LIABLED_AMOUNT = TAX_LIABLED_AMOUNT + qty_parity * sign(IMF_AMOUNT_LC_C)
             where ACI_FINANCIAL_IMPUTATION_ID = max_imp_id
               and IMF_AMOUNT_LC_C <> 0;

            -- correction du montant analytique au crédit si c'est un document "crédit"
            -- et qu'on gère les imputations analytiques
            update ACI_MGM_IMPUTATION
               set IMM_AMOUNT_LC_C = IMM_AMOUNT_LC_C + qty_parity
             where ACI_MGM_IMPUTATION_ID = max_mgm_id
               and IMM_AMOUNT_LC_C <> 0;
          end if;
        end if;

        -- seulement si le document contient une monnaie Euro
        if    mbEuro = 1
           or meEuro = 1 then
          -- recherche de la différence entre débit et crédit sur les imputations du document
          select sum(nvl(imf_amount_eur_d, 0) - nvl(imf_amount_eur_c, 0) )
            into qty_parity_eur
            from aci_financial_imputation
           where aci_document_id = new_document_id;

          -- correction des arrondis dus au change sur l'inputation dont le montant est le plus grand si on a un problème d'arrondi
          if qty_parity_eur <> 0 then
            -- recherche de l'imputation qui a le plus grand montant afin de ne pas trop influencer le montant corrigé
            select max(ACI_FINANCIAL_IMPUTATION_ID)
              into max_imp_id
              from ACI_FINANCIAL_IMPUTATION
             where ACI_DOCUMENT_ID = new_document_id
               and abs(IMF_AMOUNT_EUR_D) + abs(IMF_AMOUNT_EUR_C) =
                                                           (select max(abs(IMF_AMOUNT_EUR_D) + abs(IMF_AMOUNT_EUR_C) )
                                                              from ACI_FINANCIAL_IMPUTATION
                                                             where ACI_DOCUMENT_ID = new_document_id
                                                               and IMF_PRIMARY = 0);

            -- correction du montant au dédit si c'est un document "débit"
            update ACI_FINANCIAL_IMPUTATION
               set IMF_AMOUNT_EUR_D = IMF_AMOUNT_EUR_D - qty_parity_eur
             where ACI_FINANCIAL_IMPUTATION_ID = max_imp_id
               and IMF_AMOUNT_EUR_D <> 0;

            -- correction du montant au crédit si c'est un document "crédit"
            update ACI_FINANCIAL_IMPUTATION
               set IMF_AMOUNT_EUR_C = IMF_AMOUNT_EUR_C + qty_parity_eur
             where ACI_FINANCIAL_IMPUTATION_ID = max_imp_id
               and IMF_AMOUNT_EUR_C <> 0;
          end if;
        end if;

        -- mise à jour du flag d'imputation financière du document et
        -- suppression du lien entre le document pré-saisi finance et le document logistique
        update DOC_DOCUMENT
           set DMT_FINANCIAL_CHARGING = 1
             , ACT_DOCUMENT_ID = null
         where DOC_DOCUMENT_ID = aDocumentId;

        -- Init de la pré-saisie
        update ACT_DOC_RECEIPT
           set ACI_DOCUMENT_ID = new_document_id
         where DOC_DOCUMENT_ID = tplDocument.doc_document_id;

        -- création d'une position de status du document
        insert into ACI_DOCUMENT_STATUS
                    (ACI_DOCUMENT_STATUS_ID
                   , ACI_DOCUMENT_ID
                   , C_ACI_FINANCIAL_LINK
                    )
             values (ACI_ID_SEQ.nextval
                   , new_document_id
                   , aci_financial_link
                    );

        -- exportation du document ACI au format XML (transfert des documents ACI entre sociétés via la mécanique des Queues)
        -- la règle de gestion régissant l'exportation du document ACI est définie dans la fonction ExportAciDocument
        lb_exportXmlResult := aci_queue_functions.ExportAciDocument(new_document_id);
      end if;
    end if;

    -- fermeture du curseur sur le document
    close crDocument;
  end Write_Document_Interface;

  /**
  * Description
  *   Intégration des documents "différés"
  */
  procedure controlAndRecoverPendingDocs(aCommit number default 0)
  is
    vContinue     boolean;
    vCurrentDocId ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
  begin
    vContinue  := true;

    while vContinue loop
      select min(ACI_DOCUMENT_STATUS.aci_document_id)
        into vCurrentDocId
        from ACI_DOCUMENT
           , ACI_DOCUMENT_STATUS
       where ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK = '3'
         and ACI_DOCUMENT.C_INTERFACE_CONTROL = '1'
         and ACI_DOCUMENT.ACI_DOCUMENT_ID = ACI_DOCUMENT_STATUS.ACI_DOCUMENT_ID;

      if vCurrentDocId is not null then
        update ACI_DOCUMENT_STATUS
           set C_ACI_FINANCIAL_LINK = '2'
         where ACI_DOCUMENT_ID = vCurrentDocId;

        if aCommit = 1 then
          commit;
        end if;
      else
        vContinue  := false;
      end if;
    end loop;
  end controlAndRecoverPendingDocs;

  /**
  * Description
  *    retourne le nom de la société cible pour transfert en finance
  */
  function getFinancialCompany(
    aGaugeId in DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aThirdID in DOC_DOCUMENT.PAC_THIRD_ID%type
  )
    return varchar2
  is
    vAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type;
    vResult      DOC_DOCUMENT.COM_NAME_ACI%type;
  begin
    if PCS.PC_CONFIG.GetConfigUpper('PC_LINKABLE_FIN_COMP') != 'DEFAULT' then
      -- d'abord rechercher dans le gabarit
      select GAU.C_ADMIN_DOMAIN
           , GAS.COM_NAME_ACI
        into vAdminDomain
           , vResult
        from DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = aGaugeId
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

      -- si pas trouvé, recherche au niveau du client/fournisseur
      if vResult is null then
        if vAdminDomain = cAdminDomainPurchase then
          select COM_NAME
            into vResult
            from PAC_SUPPLIER_PARTNER
           where PAC_SUPPLIER_PARTNER_ID = aThirdId;
        elsif vAdminDomain = cAdminDomainSale then
          select COM_NAME
            into vResult
            from PAC_CUSTOM_PARTNER
           where PAC_CUSTOM_PARTNER_ID = aThirdId;
        end if;
      end if;
    end if;

    if vResult = PCS.PC_I_LIB_SESSION.GetComName then
      return null;
    else
      return vResult;
    end if;
  exception
    when no_data_found then
      return null;
  end getFinancialCompany;

END ACI_LOGISTIC_DOCUMENT;
