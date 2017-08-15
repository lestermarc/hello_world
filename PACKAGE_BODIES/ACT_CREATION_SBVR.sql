--------------------------------------------------------
--  DDL for Package Body ACT_CREATION_SBVR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_CREATION_SBVR" 
is
  function IsImputationOnDebit(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
    return boolean
  is
    vResult integer;
  begin
    select decode(sign(min(IMF_AMOUNT_LC_C) ), 0, 1, null, 1, 0)
      into vResult
      from ACT_FINANCIAL_IMPUTATION
     where ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

    return vResult = 1;
  end IsImputationOnDebit;

  procedure InitDefAccountsIdFromCharges(
    aACS_SUB_SET_ID in     ACS_SUB_SET.ACS_SUB_SET_ID%type
  , aDefAccountsId  out    ACS_DEF_ACCOUNT.DefAccountsIdRecType
  )
  is
  begin
    select ACS_CHARGES_ACCOUNT_ID
         , ACS_CDA_CHARGES_ID
         , ACS_PF_CHARGES_ID
         , ACS_PJ_CHARGES_ID
      into aDefAccountsId.DEF_FIN_ACCOUNT_ID
         , aDefAccountsId.DEF_CDA_ACCOUNT_ID
         , aDefAccountsId.DEF_PF_ACCOUNT_ID
         , aDefAccountsId.DEF_PJ_ACCOUNT_ID
      from ACS_SUB_SET
     where ACS_SUB_SET_ID = aACS_SUB_SET_ID;
  end InitDefAccountsIdFromCharges;

---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
  procedure GENERATE_FINANCIAL(aACT_ETAT_EVENT_ID number)
  is
    cursor Expiry_Selection(EtatEvent_id number, CreateOrder varchar2)
    is
      select   ACT_EXPIRY_SELECTION.ACT_EXPIRY_ID
             , ACT_EXPIRY_SELECTION.ACT_DOCUMENT_ID
             , nvl(ACT_EXPIRY_SELECTION.DET_PAIED_LC, 0) DET_PAIED_LC
             , nvl(ACT_EXPIRY_SELECTION.DET_PAIED_FC, 0) DET_PAIED_FC
             , ACT_EXPIRY_SELECTION.DET_CHARGES_LC DET_CHARGES_LC
             , ACT_EXPIRY_SELECTION.DET_CHARGES_FC DET_CHARGES_FC
             , ACT_EXPIRY_SELECTION.EXS_RECORD
             , ACT_EXPIRY_SELECTION.EXS_REFERENCE
             , ACT_EXPIRY_SELECTION.EXS_CUSTOM_PARTNER_ID
             , ACT_EXPIRY_SELECTION.EXS_SUPPLIER_PARTNER_ID
             , ACT_EXPIRY_SELECTION.ACS_FINANCIAL_CURRENCY_ID
             , nvl(ACT_EXPIRY_SELECTION.EXS_EXCHANGE_RATE, 0) EXS_EXCHANGE_RATE
             , nvl(ACT_EXPIRY_SELECTION.EXS_BASE_PRICE, 0) EXS_BASE_PRICE
             , ACT_EXPIRY.ACT_DOCUMENT_ID ACT_DOCUMENT_ID2
             , ACT_EXPIRY.EXP_SLICE
             , ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID
             , ACT_EXPIRY.ACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION_ID2
          from ACT_EXPIRY_SELECTION
             , ACT_EXPIRY
             , ACT_PART_IMPUTATION
         where ACT_EXPIRY_SELECTION.ACT_ETAT_EVENT_ID = EtatEvent_id
           and ACT_EXPIRY_SELECTION.ACT_EXPIRY_ID = ACT_EXPIRY.ACT_EXPIRY_ID(+)
           and ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID(+) = ACT_EXPIRY.ACT_PART_IMPUTATION_ID
      order by ACT_EXPIRY_SELECTION.ACT_DOCUMENT_ID asc
             , ACT_FUNCTIONS.GetPartImputCreateOrderValue(CreateOrder, null, ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID)
             , ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID asc
             , ACT_EXPIRY_SELECTION.EXS_RECORD asc;

    Expiry_Selection_tuple        Expiry_Selection%rowtype;

    cursor Expiry_Reminder(Expiry_id number)
    is
      select EXP2.*
           , EXP2.EXP_PAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER_ID
           , EXP2.EXP_PAC_SUPPLIER_PARTNER_ID PAC_SUPPLIER_PARTNER_ID
           , ACT_REMINDER.ACT_REMINDER_ID
        from ACT_EXPIRY EXP2
           , ACT_REMINDER
           , ACT_EXPIRY EXP1
       where EXP1.ACT_EXPIRY_ID = Expiry_id
         and ACT_REMINDER.ACT_PART_IMPUTATION_ID = EXP1.ACT_PART_IMPUTATION_ID
         and EXP2.ACT_EXPIRY_ID = ACT_REMINDER.ACT_EXPIRY_ID;

    Expiry_Reminder_tuple         Expiry_Reminder%rowtype;

    cursor UpdateCumuls(EtatEvent_id number)
    is
      select ACT_EXPIRY_SELECTION.ACT_DOCUMENT_ID
        from ACT_EXPIRY_SELECTION
           , ACT_DOCUMENT_STATUS
       where ACT_ETAT_EVENT_ID = EtatEvent_id
         and ACT_EXPIRY_SELECTION.ACT_DOCUMENT_ID = ACT_DOCUMENT_STATUS.ACT_DOCUMENT_ID;

    UpdateCumuls_tuple            UpdateCumuls%rowtype;
    Document_tuple                ACT_DOCUMENT%rowtype;
    Expiry_id                     ACT_EXPIRY.ACT_EXPIRY_ID%type;
    PartImputation_id             ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    DetPayment_id                 ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type;
    AuxAccount_id                 ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
    FinAccount_id                 ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
    DiffExchangeFinAccId          ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
    CurrentExpiry_id              ACT_EXPIRY.ACT_EXPIRY_ID%type;
    AmountCharge                  ACT_DET_PAYMENT.DET_CHARGES_LC%type;
    AmountDeductionLC             ACT_DET_PAYMENT.DET_DEDUCTION_LC%type;
    AmountDiscountLC              ACT_EXPIRY.EXP_DISCOUNT_LC%type;
    AmountToPayLC                 ACT_DET_PAYMENT.DET_PAIED_LC%type;
    AmountTotExpiryLC             ACT_EXPIRY.EXP_AMOUNT_LC%type;
    AmountToReportLC              ACT_DET_PAYMENT.DET_PAIED_LC%type;
    TotDeductionLC                ACT_DET_PAYMENT.DET_DEDUCTION_LC%type;
    TotDiscountLC                 ACT_DET_PAYMENT.DET_DISCOUNT_LC%type;
    AmountLC                      ACT_DET_PAYMENT.DET_PAIED_LC%type;
    AmountLC_D                    ACT_DET_PAYMENT.DET_PAIED_LC%type;
    AmountLC_C                    ACT_DET_PAYMENT.DET_PAIED_LC%type;
    vReminderChargesLC            ACT_PART_IMPUTATION.PAR_CHARGES_LC%type;
    vReminderInterestLC           ACT_PART_IMPUTATION.PAR_INTEREST_LC%type;
    TotAmountDocLC                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    CollAmountLC_D                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    CollAmountLC_C                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    DiffExchange                  ACT_DET_PAYMENT.DET_DIFF_EXCHANGE%type;
    AmountDeductionFC             ACT_DET_PAYMENT.DET_DEDUCTION_FC%type;
    AmountDiscountFC              ACT_EXPIRY.EXP_DISCOUNT_FC%type;
    AmountToPayFC                 ACT_DET_PAYMENT.DET_PAIED_FC%type;
    AmountTotExpiryFC             ACT_EXPIRY.EXP_AMOUNT_FC%type;
    AmountToReportFC              ACT_DET_PAYMENT.DET_PAIED_FC%type;
    TotDeductionFC                ACT_DET_PAYMENT.DET_DEDUCTION_FC%type;
    TotDiscountFC                 ACT_DET_PAYMENT.DET_DISCOUNT_FC%type;
    AmountFC                      ACT_DET_PAYMENT.DET_PAIED_FC%type;
    AmountFC_D                    ACT_DET_PAYMENT.DET_PAIED_LC%type;
    AmountFC_C                    ACT_DET_PAYMENT.DET_PAIED_LC%type;
    AmountChargesSBVR             ACT_FINANCIAL_IMPUTATION.IMF_CHARGES_SBVR%type;
    AmountChargesSBVR_EUR         ACT_FINANCIAL_IMPUTATION.IMF_CHARGES_SBVR_EUR%type;
    vReminderChargesFC            ACT_PART_IMPUTATION.PAR_CHARGES_FC%type;
    vReminderInterestFC           ACT_PART_IMPUTATION.PAR_INTEREST_FC%type;
    TotAmountDocFC                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    vAmountConvert                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    vAmountEUR                    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vExchangeRate                 ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    vBasePrice                    ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    LastPartner_id                ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    LastDocument_id               ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    FlagOk                        number;
    NumDocument                   ACT_DOCUMENT.DOC_NUMBER%type;
    DumpPartner_id                PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
    Signe                         number;
    ParDocDoubleBlocked           ACS_FIN_ACC_S_PAYMENT.PMM_DOUBLE_BLOCKED%type;
    FinImputation_id              ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    PeriodId                      ACS_PERIOD.ACS_PERIOD_ID%type;
    DefCurrencyId                 ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type;
    CurrencyId                    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    UserIni                       PCS.PC_USER.USE_INI%type;
    ExistPayment                  number;
    NegativeDeduction             boolean;
    ImputationDate                ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
    WhatDate                      varchar2(2);
    tblCalcVATEncashment          ACT_VAT_MANAGEMENT.tblCalcVATEncashmentType;
    Flag                          boolean                                                       := true;
    BaseInfoRec                   ACT_VAT_MANAGEMENT.BaseInfoRecType;
    InfoVATRec                    ACT_VAT_MANAGEMENT.InfoVATRecType;
    CalcVATRec                    ACT_VAT_MANAGEMENT.CalcVATRecType;
    const_BaseInfoRec             ACT_VAT_MANAGEMENT.BaseInfoRecType;
    const_InfoVATRec              ACT_VAT_MANAGEMENT.InfoVATRecType;
    const_CalcVATRec              ACT_VAT_MANAGEMENT.CalcVATRecType;
    blocked                       number;
    vReminderAdvanceExpId         ACT_EXPIRY.ACT_EXPIRY_ID%type;
    vAutoOverLettering            ACJ_CATALOGUE_DOCUMENT.CAT_AUTO_LETTRING%type;
    vAutoPartLettering            ACJ_CATALOGUE_DOCUMENT.CAT_AUTO_PART_LETT%type;
    vReminderPartImputationId     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    vReminderCategId              PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type;
    vReminderChargesTaxCodeId     ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    vOverLettering                boolean                                                       := false;
    vReminderDocNumber            ACT_DOCUMENT.DOC_NUMBER%type;
    vTypeRecord                   varchar2(3);
    vCreateOrder                  varchar2(10);
    vNumExpiry                    integer;
    FlagPartLettering             boolean;
    vAmount_OK                    boolean;
    vWithInterest                 boolean;
    vWithCharge                   boolean;
    VUseFC                        boolean;
    CatDescription                ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type;
    PaymentDescription            ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    ChargesDescription            ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    DiscountDescription           ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    DeductionDescription          ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    DiffExchangeDescription       ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    AdvanceDescription            ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatDiscountDescription        ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatDeductionDescription       ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatEncashmentDescription      ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    VatReminderChargesDescription ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    ReminderChargesDescription    ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    ReminderInterestDescription   ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
  begin
    ACT_FUNCTIONS.SetBRO(1);
    LastPartner_id     := 0;
    LastDocument_id    := 0;
    AmountCharge       := 0;
    DefCurrencyId      := ACS_FUNCTION.GetLocalCurrencyId;
    UserIni            := PCS.PC_I_LIB_SESSION.GetUserIni;
    AmountToPayLC      := 0;
    AmountDeductionLC  := 0;
    AmountDiscountLC   := 0;
    TotAmountDocLC     := 0;
    AmountToPayFC      := 0;
    AmountDeductionFC  := 0;
    AmountDiscountFC   := 0;
    TotAmountDocFC     := 0;

    --Mise à jour du status du document pour les cumuls
    open UpdateCumuls(aACT_ETAT_EVENT_ID);

    fetch UpdateCumuls
     into UpdateCumuls_tuple;

    while UpdateCumuls%found loop
      update ACT_DOCUMENT_STATUS
         set DOC_OK = 0
       where ACT_DOCUMENT_ID = UpdateCumuls_tuple.ACT_DOCUMENT_ID;

      fetch UpdateCumuls
       into UpdateCumuls_tuple;
    end loop;

    close UpdateCumuls;

    --Recherche du descode pour l'odre de création des part_imputation
    select nvl(min(ACS_FIN_ACC_S_PAYMENT.C_IMPUTATION_CREATE_ORDER), '1')
      into vCreateOrder
      from ACS_FIN_ACC_S_PAYMENT
         , ACT_DOCUMENT
         , ACT_EXPIRY_SELECTION
     where ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID = ACT_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID
       and ACT_EXPIRY_SELECTION.ACT_ETAT_EVENT_ID = aACT_ETAT_EVENT_ID
       and ACT_EXPIRY_SELECTION.ACT_DOCUMENT_ID = ACT_DOCUMENT.ACT_DOCUMENT_ID;

    -- ouverture du curseur sur l'imputation partenaire de l'interface
    open Expiry_Selection(aACT_ETAT_EVENT_ID, vCreateOrder);

    fetch Expiry_Selection
     into Expiry_Selection_tuple;

    while Expiry_Selection%found loop
      --Recherche du type de transaction
      vTypeRecord       := substr(Expiry_Selection_tuple.EXS_RECORD, 1, 3);
      --Monnaie des paiements
      CurrencyId        := nvl(Expiry_Selection_tuple.ACS_FINANCIAL_CURRENCY_ID, DefCurrencyId);
      --Utilisation LC ou FC
      vUseFC            := CurrencyId != DefCurrencyId;

      --Même monnaie et même cours pour l'ensemble des paiements
      if vUseFC then
        vExchangeRate  := Expiry_Selection_tuple.EXS_EXCHANGE_RATE;
        vBasePrice     := Expiry_Selection_tuple.EXS_BASE_PRICE;
      else
        vExchangeRate  := 0;
        vBasePrice     := 0;
      end if;

      --Lecture de la ligne du document de paiement
      if nvl(Expiry_Selection_tuple.ACT_DOCUMENT_ID, 0) <> nvl(Document_tuple.ACT_DOCUMENT_ID, 0) then
        select *
          into Document_tuple
          from ACT_DOCUMENT
         where ACT_DOCUMENT.ACT_DOCUMENT_ID = Expiry_Selection_tuple.ACT_DOCUMENT_ID;

        --Recherche info. compl. géré
        InitPayInfoImputation(Expiry_Selection_tuple.ACT_DOCUMENT_ID);

        --recherche si authorisation sur-paiement
        select nvl(CAT_AUTO_LETTRING, 0)
             , nvl(CAT_AUTO_PART_LETT, 0)
          into vAutoOverLettering
             , vAutoPartLettering
          from ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
         where DOC.ACT_DOCUMENT_ID = Expiry_Selection_tuple.ACT_DOCUMENT_ID
           and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;

        CatTransaction                 := Document_tuple.ACJ_CATALOGUE_DOCUMENT_ID;
        -- recherche si récuperation de taxe
        CatExtVAT                      := ExtVatOnDeduction(Expiry_Selection_tuple.ACT_DOCUMENT_ID, CatExtVATDiscount);
        -- recherche si catalogue gére analytique
        ExistMAN                       := IsManDocument(Expiry_Selection_tuple.ACT_DOCUMENT_ID);
        TypeOfPeriod                   := GetPeriodTypeOfCat(CatTransaction);
        CatDescription                 := ACT_FUNCTIONS.GetCatalogDescription(CatTransaction);
        PaymentDescription             := CatDescription;
        ChargesDescription             :=
          ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('frais de remb.')
                                        , 100);
        DiscountDescription            :=
               ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('escompte'), 100);
        DeductionDescription           :=
              ACT_FUNCTIONS.FormatDescription(CatDescription, ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('déduction'), 100);
        DiffExchangeDescription        :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('diff. de change')
                                        , 100
                                         );
        AdvanceDescription             :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('montant non lettré')
                                        , 100
                                         );
        VatDiscountDescription         :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA sur escompte')
                                        , 100
                                         );
        VatDeductionDescription        :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA sur déduction')
                                        , 100
                                         );
        VatEncashmentDescription       :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA / contres prestations reçues')
                                        , 100
                                         );
        ReminderInterestDescription    :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('intérêts moratoires')
                                        , 100
                                         );
        ReminderChargesDescription     :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('frais de relance')
                                        , 100
                                         );
        VatReminderChargesDescription  :=
          ACT_FUNCTIONS.FormatDescription(CatDescription
                                        , ' / ' || PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA / frais de relance')
                                        , 100
                                         );

        select min(C_DOCUMENT_DATE)
          into WhatDate
          from ACS_PAYMENT_METHOD
             , ACS_FIN_ACC_S_PAYMENT
         where ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID = Document_tuple.ACS_FIN_ACC_S_PAYMENT_ID
           and ACS_PAYMENT_METHOD.ACS_PAYMENT_METHOD_ID = ACS_FIN_ACC_S_PAYMENT.ACS_PAYMENT_METHOD_ID;

        if WhatDate = '03' then
          ImputationDate  := Document_tuple.DOC_ESTABL_DATE;
        elsif WhatDate = '02' then
          ImputationDate  := Document_tuple.DOC_EXECUTIVE_DATE;
        else
          ImputationDate  := Document_tuple.DOC_EFFECTIVE_DATE;
        end if;

        PeriodId                       := ACS_FUNCTION.GetPeriodId(ImputationDate, TypeOfPeriod);
        DumpPartner_id                 :=
                                        ACT_CREATION_SBVR.GetDefaultPartnerSBVR(Document_tuple.ACS_FIN_ACC_S_PAYMENT_ID);
        FinAccount_id                  := Document_tuple.ACS_FINANCIAL_ACCOUNT_ID;
        ParDocDoubleBlocked            := GetParDocDoubleBlocked(Document_tuple.ACS_FIN_ACC_S_PAYMENT_ID);
      end if;

      --Si BVR remboursement, montant payé - frais
      if IsBVRPayBack(Document_tuple.ACS_FIN_ACC_S_PAYMENT_ID) = 1 then
        AmountCharge                         :=
                    GetAmountCharge(Expiry_Selection_tuple.ACT_DOCUMENT_ID2)
                    * sign(Expiry_Selection_tuple.DET_PAIED_LC);
        Expiry_Selection_tuple.DET_PAIED_LC  := Expiry_Selection_tuple.DET_PAIED_LC - AmountCharge;
      else
        AmountCharge  := 0;
      end if;

      --Montant à reporter à 0
      AmountToReportLC  := 0;
      AmountToReportFC  := 0;

      if (Expiry_Selection_tuple.ACT_EXPIRY_ID is null) then
        --Si l'échéance n'existe pas, création d'une échance sur client 'poubelle'

        --Création avance sur partenaire poubelle.
        PartImputation_id  :=
          CREATE_PART_IMPUTATION_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                    , concat(concat(substr(Expiry_Selection_tuple.EXS_RECORD, 50, 10), ' ')
                                           , substr(Expiry_Selection_tuple.EXS_RECORD, 78, 9)
                                            )
                                    , DumpPartner_id
                                    , 0
                                    , 0
                                    , 0
                                    , vExchangeRate
                                    , vBasePrice
                                    , CurrencyId
                                     );
        --Sauvegarde du dernier partenaire et document traité.
        LastPartner_id     := Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID;
        LastDocument_id    := Expiry_Selection_tuple.ACT_DOCUMENT_ID;
        --Recherche du compte auxiliaire correspondant au partenaire.
        AuxAccount_id      := GetPartnerAuxAccount_id(DumpPartner_id, 1);

        --Création frais de remboursement
        if AmountCharge <> 0 then
          CREATE_FIN_IMP_CHARGES_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                    , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                    , PeriodId
                                    , null
                                    , ImputationDate
                                    , ImputationDate
                                    , ACT_FUNCTIONS.FormatDescription(ChargesDescription, ' / ' || NumDocument, 100)
                                    , AmountCharge   -- IMF_AMOUNT_LC_D
                                    , 0   -- IMF_AMOUNT_LC_C
                                    , 0   -- IMF_EXCHANGE_RATE
                                    , 0   -- IMF_BASE_PRICE
                                    , 0   -- IMF_AMOUNT_FC_D
                                    , 0   -- IMF_AMOUNT_FC_C
                                    , 0   -- IMF_AMOUNT_EUR_D
                                    , 0   -- IMF_AMOUNT_EUR_C
                                    , DefCurrencyId
                                    , DefCurrencyId
                                    , Document_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                                    , Document_tuple.ACS_FINANCIAL_ACCOUNT_ID
                                    , AuxAccount_id
                                    , UserIni
                                    , PartImputation_id
                                    , Expiry_Selection_tuple.ACT_EXPIRY_ID
                                     );
        end if;

        CREATE_ADVANCE_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                          , PartImputation_id
                          , AuxAccount_id
                          , Expiry_Selection_tuple.EXS_REFERENCE
                          , ImputationDate
                          , ImputationDate
                          , AdvanceDescription
                          , 0
                          , Expiry_Selection_tuple.DET_PAIED_LC
                          , vExchangeRate
                          , vBasePrice
                          , 0
                          , Expiry_Selection_tuple.DET_PAIED_FC
                          , 0
                          , 0
                          , CurrencyId
                          , null
                          , False
                          , Expiry_Selection_tuple.DET_CHARGES_LC
                          , Expiry_Selection_tuple.DET_CHARGES_FC
                           );
        TotAmountDocLC     := TotAmountDocLC + Expiry_Selection_tuple.DET_PAIED_LC;
        TotAmountDocFC     := TotAmountDocFC + Expiry_Selection_tuple.DET_PAIED_FC;
--------------------------
      else
        --Sinon, utilisation de l'échéance définie
        Expiry_id  := Expiry_Selection_tuple.ACT_EXPIRY_ID;

--**********************************************************************
        if GetDocTypeOfExpiry(Expiry_id) <> '8' then
          --Facture simple

          --Reprise des info compl. de la facture
          GetInfoImputationExpiry(Expiry_Selection_tuple.ACT_EXPIRY_ID);

          --Lecture de la ligne du document facture
          select DOC_NUMBER
            into NumDocument
            from ACT_DOCUMENT
           where ACT_DOCUMENT.ACT_DOCUMENT_ID = Expiry_Selection_tuple.ACT_DOCUMENT_ID2;

          select min(exp.act_expiry_id)
            into ExistPayment
            from ACT_DET_PAYMENT PAY
               , ACT_EXPIRY exp
           where PAY.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
             and exp.ACT_EXPIRY_ID = Expiry_Selection_tuple.ACT_EXPIRY_ID
             and rownum = 1;

          --Si dans le cas d'un surpaiement, le montant restant à payer = 0
          if not vOverLettering then
            AmountToPayLC      :=
                           abs(GetAmountLeft(Expiry_Selection_tuple.ACT_EXPIRY_ID, Document_tuple.DOC_ESTABL_DATE, 1) );
            AmountTotExpiryLC  := abs(GetAmountLeft(Expiry_Selection_tuple.ACT_EXPIRY_ID, null, 1) );

            if vUseFC then
              AmountToPayFC      :=
                           abs(GetAmountLeft(Expiry_Selection_tuple.ACT_EXPIRY_ID, Document_tuple.DOC_ESTABL_DATE, 0) );
              AmountTotExpiryFC  := abs(GetAmountLeft(Expiry_Selection_tuple.ACT_EXPIRY_ID, null, 0) );
            end if;
          else
            AmountToPayLC      := 0;
            AmountTotExpiryLC  := 0;
            AmountToPayFC      := 0;
            AmountTotExpiryFC  := 0;
          end if;

          CurrentExpiry_id   :=
            ACT_FUNCTIONS.GetExpiryIdOfToleranceDate(Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                                   , Expiry_Selection_tuple.EXP_SLICE
                                                   , Document_tuple.DOC_ESTABL_DATE
                                                    );
          AmountDiscountLC   := ACT_FUNCTIONS.GetDiscountOfExpiry(CurrentExpiry_id, 1);

          if vUseFC then
            AmountDiscountFC  := ACT_FUNCTIONS.GetDiscountOfExpiry(CurrentExpiry_id, 0);
            ACS_FUNCTION.ConvertAmount(AmountDiscountFC
                                     , CurrencyId
                                     , DefCurrencyId
                                     , ImputationDate
                                     , vExchangeRate
                                     , vBasePrice
                                     , 1
                                     , vAmountEUR
                                     , vAmountConvert
                                      );
            AmountDiscountLC  := vAmountConvert;
          else
            AmountDiscountFC  := 0;
          end if;

          Signe              := sign(Expiry_Selection_tuple.DET_PAIED_LC);
          FlagOK             := 0;
          AmountDeductionLC  := 0;
          AmountDeductionFC  := 0;
          DiffExchange       := 0;

          if     (TestExercice(Expiry_Selection_tuple.ACT_DOCUMENT_ID2, ImputationDate) = 1)
             and (AmountToPayLC <> 0)
             and not(     (GetDocTypeOfExpiry(Expiry_Selection_tuple.ACT_EXPIRY_ID) in('3', '4') )
                     and (GetAmount(Expiry_Selection_tuple.ACT_EXPIRY_ID, 1) < 0)
                    ) then
            if not vUseFC then
              if AmountToPayLC = abs(Expiry_Selection_tuple.DET_PAIED_FC) then
                FlagOk  := 1;
              elsif IsDeductionPossible(Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID
                                      , AmountToPayLC
                                      , abs(Expiry_Selection_tuple.DET_PAIED_LC)
                                       ) = 1 then
                FlagOK             := 1;
                AmountDeductionLC  := Signe *(AmountToPayLC - abs(Expiry_Selection_tuple.DET_PAIED_LC) );
              elsif     vAutoPartLettering = 1
                    and AmountToPayLC > abs(Expiry_Selection_tuple.DET_PAIED_LC) then
                FlagOK            := 1;
                AmountDiscountLC  := 0;
              elsif     vAutoOverLettering = 1
                    and AmountToPayLC < abs(Expiry_Selection_tuple.DET_PAIED_LC) then
                FlagOK  := 1;

                if AmountTotExpiryLC < abs(Expiry_Selection_tuple.DET_PAIED_LC) then
                  AmountToReportLC                     :=
                                                   (abs(Expiry_Selection_tuple.DET_PAIED_LC) - AmountTotExpiryLC)
                                                   * Signe;
                  Expiry_Selection_tuple.DET_PAIED_LC  := Expiry_Selection_tuple.DET_PAIED_LC - AmountToReportLC;
                  AmountDiscountLC                     := 0;
                else
                  AmountDiscountLC  := AmountTotExpiryLC - Expiry_Selection_tuple.DET_PAIED_LC;
                end if;
              end if;
            else
              if AmountToPayFC = abs(Expiry_Selection_tuple.DET_PAIED_FC) then
                FlagOk        := 1;
                DiffExchange  :=
                  Signe *
                  (AmountTotExpiryLC -
                   abs(Expiry_Selection_tuple.DET_PAIED_LC) -
                   abs(AmountDiscountLC) -
                   abs(AmountDeductionLC)
                  );
              elsif IsDeductionPossible(Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID
                                      , AmountToPayFC
                                      , abs(Expiry_Selection_tuple.DET_PAIED_FC)
                                       ) = 1 then
                FlagOK             := 1;
                AmountDeductionFC  := Signe *(AmountToPayFC - abs(Expiry_Selection_tuple.DET_PAIED_FC) );
                ACS_FUNCTION.ConvertAmount(AmountDeductionFC
                                         , CurrencyId
                                         , DefCurrencyId
                                         , ImputationDate
                                         , vExchangeRate
                                         , vBasePrice
                                         , 1
                                         , vAmountEUR
                                         , vAmountConvert
                                          );
                AmountDeductionLC  := vAmountConvert;
                DiffExchange       :=
                  Signe *
                  (AmountTotExpiryLC -
                   abs(Expiry_Selection_tuple.DET_PAIED_LC) -
                   abs(AmountDiscountLC) -
                   abs(AmountDeductionLC)
                  );
              elsif     vAutoPartLettering = 1
                    and AmountToPayFC > abs(Expiry_Selection_tuple.DET_PAIED_FC) then
                FlagOK            := 1;
                AmountDiscountLC  := 0;
                AmountDiscountFC  := 0;
              elsif     vAutoOverLettering = 1
                    and AmountToPayFC < abs(Expiry_Selection_tuple.DET_PAIED_FC) then
                FlagOK  := 1;

                if AmountTotExpiryFC < abs(Expiry_Selection_tuple.DET_PAIED_FC) then
                  AmountToReportFC                     :=
                                                   (abs(Expiry_Selection_tuple.DET_PAIED_FC) - AmountTotExpiryFC)
                                                   * Signe;
                  Expiry_Selection_tuple.DET_PAIED_FC  := Expiry_Selection_tuple.DET_PAIED_FC - AmountToReportFC;
                  ACS_FUNCTION.ConvertAmount(AmountToReportFC
                                           , CurrencyId
                                           , DefCurrencyId
                                           , ImputationDate
                                           , vExchangeRate
                                           , vBasePrice
                                           , 1
                                           , vAmountEUR
                                           , vAmountConvert
                                            );
                  AmountToReportLC                     := vAmountConvert;
                  Expiry_Selection_tuple.DET_PAIED_LC  := Expiry_Selection_tuple.DET_PAIED_LC - AmountToReportLC;
                  AmountDiscountLC                     := 0;
                  AmountDiscountFC                     := 0;
                  DiffExchange                         :=
                    Signe *
                    (AmountTotExpiryLC -
                     abs(Expiry_Selection_tuple.DET_PAIED_LC) -
                     abs(AmountDiscountLC) -
                     abs(AmountDeductionLC)
                    );
                else
                  AmountDiscountFC  := AmountTotExpiryFC - Expiry_Selection_tuple.DET_PAIED_FC;
                  ACS_FUNCTION.ConvertAmount(AmountDiscountFC
                                           , CurrencyId
                                           , DefCurrencyId
                                           , ImputationDate
                                           , vExchangeRate
                                           , vBasePrice
                                           , 1
                                           , vAmountEUR
                                           , vAmountConvert
                                            );
                  AmountDiscountLC  := vAmountConvert;
                  DiffExchange      :=
                    Signe *
                    (AmountTotExpiryLC -
                     abs(Expiry_Selection_tuple.DET_PAIED_LC) -
                     abs(AmountDiscountLC) -
                     abs(AmountDeductionLC)
                    );
                end if;
              end if;
            end if;
          end if;

          if    (FlagOK = 1)
             or (     (Signe < 0)
                 and (ExistPayment is not null) ) then
            --Montant OK -> paiement des montants
            --Création d'une imputation partenaire.
            PartImputation_id  :=
              CREATE_PART_IMPUTATION_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                        , concat(concat(substr(Expiry_Selection_tuple.EXS_RECORD, 50, 10), ' ')
                                               , substr(Expiry_Selection_tuple.EXS_RECORD, 78, 9)
                                                )
                                        , Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID
                                        , 0
                                        , 0
                                        , 0
                                        , vExchangeRate
                                        , vBasePrice
                                        , CurrencyId
                                         );
            --Recherche du compte auxiliaire correspondant au partenaire.
            AuxAccount_id      := GetPartnerAuxAccount_id(Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID, 1);
            --Sauvegarde du dernier partenaire et document traité.
            LastPartner_id     := Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID;
            LastDocument_id    := Expiry_Selection_tuple.ACT_DOCUMENT_ID;

            if Signe > 0 then
              DetPayment_id  :=
                CREATE_DET_PAYMENT_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                      , PartImputation_id
                                      , Expiry_id
                                      , Expiry_Selection_tuple.DET_PAIED_LC
                                      , AmountCharge
                                      , Signe * AmountDiscountLC
                                      , Signe * AmountDeductionLC
                                      , DiffExchange
                                      , Expiry_Selection_tuple.DET_PAIED_FC
                                      , 0   --AmountChargeFC
                                      , Signe * AmountDiscountFC
                                      , Signe * AmountDeductionFC
                                      , substr(Expiry_Selection_tuple.EXS_RECORD, 1, 3)
                                       );
            else
              DetPayment_id  :=
                CREATE_DET_PAYMENT_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                      , PartImputation_id
                                      , Expiry_id
                                      , Expiry_Selection_tuple.DET_PAIED_LC
                                      , AmountCharge
                                      , 0
                                      , 0
                                      , 0
                                      , Expiry_Selection_tuple.DET_PAIED_FC
                                      , 0   --AmountChargeFC
                                      , 0
                                      , 0
                                      , substr(Expiry_Selection_tuple.EXS_RECORD, 1, 3)
                                       );
            end if;

            -- Si paiement LSV+, suppression de la liste des paiements en attente
            if vTypeRecord = '202' then
              UpdatePaymentSelection(Expiry_id);
            end if;

            if Expiry_Selection_tuple.DET_PAIED_LC <> 0 then
              if Signe > 0 then
                CREATE_FIN_IMP_PAY_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID   --Doc paiement
                                      , Expiry_Selection_tuple.ACT_DOCUMENT_ID2   --Doc facture
                                      , Expiry_Selection_tuple.ACT_PART_IMPUTATION_ID2   --Part id facture
                                      , PeriodId
                                      , AuxAccount_id
                                      , DetPayment_id
                                      , ImputationDate
                                      , ImputationDate
                                      , ACT_FUNCTIONS.FormatDescription(PaymentDescription, ' / ' || NumDocument, 100)
                                      , 0
                                      , Expiry_Selection_tuple.DET_PAIED_LC +
                                        (Signe * AmountDiscountLC) +
                                        AmountDeductionLC
                                      , vExchangeRate   -- IMF_EXCHANGE_RATE
                                      , vBasePrice   -- IMF_EXCHANGE_RATE
                                      , 0   -- IMF_AMOUNT_FC_D
                                      , Expiry_Selection_tuple.DET_PAIED_FC +
                                        (Signe * AmountDiscountFC) +
                                        AmountDeductionFC
                                      , 0   -- IMF_AMOUNT_EUR_D
                                      , 0   -- IMF_AMOUNT_EUR_C
                                      , CurrencyId
                                      , DefCurrencyId
                                      , UserIni
                                      , PartImputation_id
                                      , Expiry_Selection_tuple.DET_CHARGES_LC
                                      , Expiry_Selection_tuple.DET_CHARGES_FC
                                       );
              else
                CREATE_FIN_IMP_PAY_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID   --Doc paiement
                                      , Expiry_Selection_tuple.ACT_DOCUMENT_ID2   --Doc facture
                                      , Expiry_Selection_tuple.ACT_PART_IMPUTATION_ID2   --Part id facture
                                      , PeriodId
                                      , AuxAccount_id
                                      , DetPayment_id
                                      , ImputationDate
                                      , ImputationDate
                                      , ACT_FUNCTIONS.FormatDescription(PaymentDescription, ' / ' || NumDocument, 100)
                                      , 0
                                      , Expiry_Selection_tuple.DET_PAIED_LC
                                      , vExchangeRate   -- IMF_EXCHANGE_RATE
                                      , vBasePrice   -- IMF_EXCHANGE_RATE
                                      , 0   -- IMF_AMOUNT_FC_D
                                      , Expiry_Selection_tuple.DET_PAIED_FC
                                      , 0   -- IMF_AMOUNT_EUR_D
                                      , 0   -- IMF_AMOUNT_EUR_C
                                      , CurrencyId
                                      , DefCurrencyId
                                      , UserIni
                                      , PartImputation_id
                                      , Expiry_Selection_tuple.DET_CHARGES_LC
                                      , Expiry_Selection_tuple.DET_CHARGES_FC
                                       );
              end if;
            end if;

            --Calcul proportion TVA
            tblCalcVat.delete;

            if    (    AmountDiscountLC <> 0
                   and CatExtVATDiscount = 1)
               or (    Signe > 0
                   and AmountDeductionLC <> 0
                   and CatExtVAT = 1) then
              CalcVatOnDeduction(CurrentExpiry_id, Expiry_Selection_tuple.ACT_DOCUMENT_ID);
            else
              tblCalcVat(1).ACS_TAX_CODE_ID           := 0;
              tblCalcVat(1).TAX_RATE                  := 0;
              tblCalcVat(1).ACS_FINANCIAL_ACCOUNT_ID  := 0;
              tblCalcVat(1).PROPORTION                := 100;
            end if;

            TotDiscountLC      := 0;
            TotDeductionLC     := 0;
            TotDiscountFC      := 0;
            TotDeductionFC     := 0;

            for i in 1 .. tblCalcVat.count loop
              if     (AmountDiscountLC <> 0)
                 and (Signe > 0) then
                if i = tblCalcVat.count then
                  AmountLC  :=(Signe * AmountDiscountLC - TotDiscountLC);

                  if vUseFC then
                    AmountFC  :=(Signe * AmountDiscountFC - TotDiscountFC);
                  else
                    AmountFC  := 0;
                  end if;
                else
                  AmountLC  :=(Signe * AmountDiscountLC * tblCalcVat(i).PROPORTION / 100);

                  if vUseFC then
                    AmountFC  :=(Signe * AmountDiscountFC * tblCalcVat(i).PROPORTION / 100);
                  else
                    AmountFC  := 0;
                  end if;
                end if;

                if round(AmountLC, 2) <> 0 then
                  BaseInfoRec       := const_BaseInfoRec;
                  InfoVATRec        := const_InfoVATRec;
                  CalcVATRec        := const_CalcVATRec;

                  if     (CatExtVATDiscount = 1)
                     and (tblCalcVat(i).ACS_TAX_CODE_ID <> 0) then
                    BaseInfoRec.TaxCodeId        := tblCalcVat(i).ACS_TAX_CODE_ID;
                    BaseInfoRec.PeriodId         := PeriodId;
                    BaseInfoRec.DocumentId       := Expiry_Selection_Tuple.ACT_DOCUMENT_ID;
                    BaseInfoRec.primary          := 0;
                    BaseInfoRec.AmountD_LC       := AmountLC;
                    BaseInfoRec.AmountC_LC       := 0;
                    BaseInfoRec.AmountD_FC       := AmountFC;
                    BaseInfoRec.AmountC_FC       := 0;
                    BaseInfoRec.AmountD_EUR      := 0;
                    BaseInfoRec.AmountC_EUR      := 0;
                    BaseInfoRec.ExchangeRate     := vExchangeRate;
                    BaseInfoRec.BasePrice        := vBasePrice;
                    BaseInfoRec.ValueDate        := ImputationDate;
                    BaseInfoRec.TransactionDate  := ImputationDate;
                    BaseInfoRec.FinCurrId_FC     := CurrencyId;
                    BaseInfoRec.FinCurrId_LC     := DefCurrencyId;
                    BaseInfoRec.PartImputId      := PartImputation_id;
                    CalcVATRec.Encashment        := tblcalcVat(i).TAX_TMP_VAT_ENCASHMENT;
                    CalcVAT(BaseInfoRec
                          , InfoVATRec
                          , CalcVATRec
                          , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                          , tblCalcVat(i).TAX_RATE
                           );
                    AmountLC                     := BaseInfoRec.AmountD_LC;
                    AmountFC                     := BaseInfoRec.AmountD_FC;
                  end if;

                  FinImputation_id  :=
                    CREATE_FIN_IMP_DISCOUNT_SBVR(Expiry_Selection_Tuple.ACT_DOCUMENT_ID
                                               , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                               , PeriodId
                                               , AuxAccount_id
                                               , DetPayment_id
                                               , ImputationDate
                                               , ImputationDate
                                               , ACT_FUNCTIONS.FormatDescription(DiscountDescription
                                                                               , ' / ' || NumDocument
                                                                               , 100
                                                                                )
                                               , AmountLC
                                               , 0   -- IMF_AMOUNT_LC_C
                                               , vExchangeRate   -- IMF_EXCHANGE_RATE
                                               , vBasePrice   -- IMF_BASE_PRICE
                                               , AmountFC   -- IMF_AMOUNT_FC_D
                                               , 0   -- IMF_AMOUNT_FC_C
                                               , 0   -- IMF_AMOUNT_EUR_D
                                               , 0   -- IMF_AMOUNT_EUR_C
                                               , CurrencyId
                                               , DefCurrencyId
                                               , UserIni
                                               , PartImputation_id
                                                );
                  TotDiscountLC     := TotDiscountLC + AmountLC;
                  TotDiscountFC     := TotDiscountFC + AmountFC;

                  if     (CatExtVATDiscount = 1)
                     and (tblCalcVat(i).ACS_TAX_CODE_ID <> 0) then
                    CREATE_VAT_SBVR(FinImputation_id
                                  , tblCalcVat(i).ACS_TAX_CODE_ID
                                  , tblCalcVat(i).TAX_RATE
                                  , tblCalcVat(i).ACS_FINANCIAL_ACCOUNT_ID
                                  , tblCalcVat(i).PROPORTION
                                  , VatDiscountDescription
                                  , NumDocument
                                  , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                  , AuxAccount_id
                                  , UserIni
                                  , BaseInfoRec
                                  , InfoVATRec
                                  , CalcVATRec
                                   );
                  end if;
                end if;
              end if;

              if     (AmountDeductionLC <> 0)
                 and (Signe > 0) then
                if i = tblCalcVat.count then
                  AmountLC  :=(AmountDeductionLC - TotDeductionLC);

                  if vUseFC then
                    AmountFC  :=(AmountDeductionFC - TotDeductionFC);
                  else
                    AmountFC  := 0;
                  end if;
                else
                  AmountLC  :=(AmountDeductionLC * tblCalcVat(i).PROPORTION / 100);

                  if vUseFC then
                    AmountFC  :=(AmountDeductionFC * tblCalcVat(i).PROPORTION / 100);
                  else
                    AmountFC  := 0;
                  end if;
                end if;

                if AmountLC < 0 then
                  NegativeDeduction  := true;
                  AmountLC_D         := 0;
                  AmountLC_C         := -AmountLC;
                  AmountFC_D         := 0;
                  AmountFC_C         := -AmountFC;
                else
                  NegativeDeduction  := false;
                  AmountLC_D         := AmountLC;
                  AmountLC_C         := 0;
                  AmountFC_D         := AmountFC;
                  AmountFC_C         := 0;
                end if;

                if round(AmountLC, 2) <> 0 then
                  BaseInfoRec       := const_BaseInfoRec;
                  InfoVATRec        := const_InfoVATRec;
                  CalcVATRec        := const_CalcVATRec;

                  if     (CatExtVAT = 1)
                     and (tblCalcVat(i).ACS_TAX_CODE_ID <> 0) then
                    BaseInfoRec.TaxCodeId        := tblCalcVat(i).ACS_TAX_CODE_ID;
                    BaseInfoRec.PeriodId         := PeriodId;
                    BaseInfoRec.DocumentId       := Expiry_Selection_Tuple.ACT_DOCUMENT_ID;
                    BaseInfoRec.primary          := 0;
                    BaseInfoRec.AmountD_LC       := AmountLC_D;
                    BaseInfoRec.AmountC_LC       := AmountLC_C;
                    BaseInfoRec.AmountD_FC       := AmountFC_D;
                    BaseInfoRec.AmountC_FC       := AmountFC_C;
                    BaseInfoRec.AmountD_EUR      := 0;
                    BaseInfoRec.AmountC_EUR      := 0;
                    BaseInfoRec.ExchangeRate     := vExchangeRate;
                    BaseInfoRec.BasePrice        := vBasePrice;
                    BaseInfoRec.ValueDate        := ImputationDate;
                    BaseInfoRec.TransactionDate  := ImputationDate;
                    BaseInfoRec.FinCurrId_FC     := CurrencyId;
                    BaseInfoRec.FinCurrId_LC     := DefCurrencyId;
                    BaseInfoRec.PartImputId      := PartImputation_id;
                    CalcVATRec.Encashment        := tblcalcVat(i).TAX_TMP_VAT_ENCASHMENT;
                    CalcVAT(BaseInfoRec
                          , InfoVATRec
                          , CalcVATRec
                          , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                          , tblCalcVat(i).TAX_RATE
                           );
                    AmountLC_D                   := BaseInfoRec.AmountD_LC;
                    AmountLC_C                   := BaseInfoRec.AmountC_LC;
                    AmountFC_D                   := BaseInfoRec.AmountD_FC;
                    AmountFC_C                   := BaseInfoRec.AmountC_FC;
                  end if;

                  FinImputation_id  :=
                    CREATE_FIN_IMP_DEDUCTION_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                                , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                                , PeriodId
                                                , AuxAccount_id
                                                , DetPayment_id
                                                , ImputationDate
                                                , ImputationDate
                                                , ACT_FUNCTIONS.FormatDescription(DeductionDescription
                                                                                , ' / ' || NumDocument
                                                                                , 100
                                                                                 )
                                                , AmountLC_D
                                                , AmountLC_C
                                                , vExchangeRate   -- IMF_EXCHANGE_RATE
                                                , vBasePrice   -- IMF_BASE_PRICE
                                                , AmountFC_D
                                                , AmountFC_C
                                                , 0   -- IMF_AMOUNT_EUR_D
                                                , 0   -- IMF_AMOUNT_EUR_C
                                                , CurrencyId
                                                , DefCurrencyId
                                                , UserIni
                                                , PartImputation_id
                                                , NegativeDeduction
                                                 );
                  TotDeductionLC    := TotDeductionLC + AmountLC;
                  TotDeductionFC    := TotDeductionFC + AmountFC;

                  if     (CatExtVAT = 1)
                     and (tblCalcVat(i).ACS_TAX_CODE_ID <> 0) then
                    CREATE_VAT_SBVR(FinImputation_id
                                  , tblCalcVat(i).ACS_TAX_CODE_ID
                                  , tblCalcVat(i).TAX_RATE
                                  , tblCalcVat(i).ACS_FINANCIAL_ACCOUNT_ID
                                  , tblCalcVat(i).PROPORTION
                                  , VatDeductionDescription
                                  , NumDocument
                                  , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                  , AuxAccount_id
                                  , UserIni
                                  , BaseInfoRec
                                  , InfoVATRec
                                  , CalcVATRec
                                   );
                  end if;
                end if;
              end if;
            end loop;

            --Création écriture reprise TVA provisoire
            if upper(PCS.PC_CONFIG.GetConfig('ACT_TAX_VAT_ENCASHMENT') ) = 'TRUE' then
              tblCalcVATEncashment.delete;
              Flag  :=
                    Flag
                and ACT_VAT_MANAGEMENT.CalcEncashmentVAT(Expiry_id
                                                       , Expiry_Selection_tuple.DET_PAIED_LC
                                                       , Expiry_Selection_tuple.DET_PAIED_FC
                                                       , tblCalcVATEncashment
                                                        );
              Flag  :=
                    Flag
                and ACT_VAT_MANAGEMENT.InsertEncashmentVAT(Expiry_Selection_Tuple.ACT_DOCUMENT_ID
                                                         , PeriodId
                                                         , null
                                                         , DetPayment_id
                                                         , ImputationDate
                                                         , ImputationDate
                                                         , ACT_FUNCTIONS.FormatDescription(VatEncashmentDescription
                                                                                         , ' / ' || NumDocument
                                                                                         , 100
                                                                                          )
                                                         , PartImputation_id
                                                         , tblCalcVATEncashment
                                                          );
            end if;

            -- Imputations différence de change et Correction TVA
            if DiffExchange <> 0 then
              -- Définition des montants
              ACT_PROCESS_PAYMENT.InitDiffChangeAmounts(true
                                                      , true
                                                      , false
                                                      , DiffExchange
                                                      , AmountLC_D
                                                      , AmountLC_C
                                                      , CollAmountLC_D
                                                      , CollAmountLC_C
                                                       );
              DiffExchangeFinAccId  := ACT_PROCESS_PAYMENT.GetDiffExchangeAccount(1, DiffExchange, CurrencyId);

              if    (round(AmountLC_D, 2) <> 0)
                 or (round(AmountLC_C, 2) <> 0) then
                FinImputation_Id  :=
                  ACT_PROCESS_PAYMENT.DiffExchangeImputations
                                                            (1
                                                           , Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                                           , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                                           , PeriodId
                                                           , DiffExchangeFinAccId
                                                           , AuxAccount_id
                                                           , DetPayment_id
                                                           , ImputationDate
                                                           , ImputationDate
                                                           , ACT_FUNCTIONS.FormatDescription(DiffExchangeDescription
                                                                                           , ' / ' || NumDocument
                                                                                           , 100
                                                                                            )
                                                           , AmountLC_D
                                                           , AmountLC_C
                                                           , 0
                                                           ,   -- PAR_EXCHANGE_RATE,
                                                             0
                                                           ,   -- PAR_BASE_PRICE,
                                                             CollAmountLC_D
                                                           , CollAmountLC_C
                                                           , CurrencyId
                                                           , DefCurrencyId
                                                           , UserIni
                                                           , PartImputation_id
                                                            );
              end if;
            end if;

            if AmountCharge <> 0 then
              CREATE_FIN_IMP_CHARGES_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                        , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                        , PeriodId
                                        , DetPayment_id
                                        , ImputationDate
                                        , ImputationDate
                                        , ACT_FUNCTIONS.FormatDescription(ChargesDescription, ' / ' || NumDocument, 100)
                                        , AmountCharge   -- IMF_AMOUNT_LC_D
                                        , 0   -- IMF_AMOUNT_LC_C
                                        , 0   -- IMF_EXCHANGE_RATE
                                        , 0   -- IMF_BASE_PRICE
                                        , 0   -- IMF_AMOUNT_FC_D
                                        , 0   -- IMF_AMOUNT_FC_C
                                        , 0   -- IMF_AMOUNT_EUR_D
                                        , 0   -- IMF_AMOUNT_EUR_C
                                        , DefCurrencyId
                                        , DefCurrencyId
                                        , Document_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                                        , Document_tuple.ACS_FINANCIAL_ACCOUNT_ID
                                        , AuxAccount_id
                                        , UserIni
                                        , PartImputation_id
                                        , Expiry_Selection_tuple.ACT_EXPIRY_ID
                                         );
            end if;

            TotAmountDocLC     :=
              TotAmountDocLC +
              (Expiry_Selection_tuple.DET_PAIED_LC + Signe * AmountDiscountLC + AmountDeductionLC) -
              ( (Signe * AmountDiscountLC) + AmountDeductionLC + AmountCharge
              );

            if vUseFC then
              TotAmountDocFC  :=
                TotAmountDocFC +
                (Expiry_Selection_tuple.DET_PAIED_FC + Signe * AmountDiscountFC + AmountDeductionFC) -
                ( (Signe * AmountDiscountFC) + AmountDeductionFC
                );
            end if;
          else
            if (     (ParDocDoubleBlocked = 1)
                and (AmountToPayLC = 0)
                and (IsExpiryInReminder(Expiry_Selection_tuple.ACT_EXPIRY_ID) = 1)
                and (    (    not vUseFC
                          and (Expiry_Selection_tuple.DET_PAIED_LC = GetAmount(Expiry_Selection_tuple.ACT_EXPIRY_ID, 1)
                              )
                         )
                     or (    vUseFC
                         and (Expiry_Selection_tuple.DET_PAIED_FC = GetAmount(Expiry_Selection_tuple.ACT_EXPIRY_ID, 0)
                             )
                        )
                    )
               ) then
              blocked  := 1;
            else
              blocked  := 0;
            end if;

            --Création d'une imputation partenaire.
            PartImputation_id  :=
              CREATE_PART_IMPUTATION_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                        , concat(concat(substr(Expiry_Selection_tuple.EXS_RECORD, 50, 10), ' ')
                                               , substr(Expiry_Selection_tuple.EXS_RECORD, 78, 9)
                                                )
                                        , Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID
                                        , blocked
                                        , 0
                                        , 0
                                        , vExchangeRate
                                        , vBasePrice
                                        , CurrencyId
                                         );
            --Recherche du compte auxiliaire correspondant au partenaire.
            AuxAccount_id      := GetPartnerAuxAccount_id(Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID, 1);
            --Sauvegarde du dernier partenaire et document traité.
            LastPartner_id     := Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID;
            LastDocument_id    := Expiry_Selection_tuple.ACT_DOCUMENT_ID;

            --Création frais de remboursement
            if AmountCharge <> 0 then
              CREATE_FIN_IMP_CHARGES_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                        , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                        , PeriodId
                                        , null
                                        , ImputationDate
                                        , ImputationDate
                                        , ACT_FUNCTIONS.FormatDescription(ChargesDescription, ' / ' || NumDocument, 100)
                                        , AmountCharge   -- IMF_AMOUNT_LC_D
                                        , 0   -- IMF_AMOUNT_LC_C
                                        , 0   -- IMF_EXCHANGE_RATE
                                        , 0   -- IMF_BASE_PRICE
                                        , 0   -- IMF_AMOUNT_FC_D
                                        , 0   -- IMF_AMOUNT_FC_C
                                        , 0   -- IMF_AMOUNT_EUR_D
                                        , 0   -- IMF_AMOUNT_EUR_C
                                        , DefCurrencyId
                                        , DefCurrencyId
                                        , Document_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                                        , Document_tuple.ACS_FINANCIAL_ACCOUNT_ID
                                        , AuxAccount_id
                                        , UserIni
                                        , PartImputation_id
                                        , Expiry_Selection_tuple.ACT_EXPIRY_ID
                                         );
            end if;

            CREATE_ADVANCE_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                              , PartImputation_id
                              , AuxAccount_id
                              , Expiry_Selection_tuple.EXS_REFERENCE
                              , ImputationDate
                              , ImputationDate
                              , AdvanceDescription
                              , 0
                              , Expiry_Selection_tuple.DET_PAIED_LC
                              , vExchangeRate
                              , vBasePrice
                              , 0
                              , Expiry_Selection_tuple.DET_PAIED_FC
                              , 0
                              , 0
                              , CurrencyId
                              , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                              , true
                              , Expiry_Selection_tuple.DET_CHARGES_LC
                              , Expiry_Selection_tuple.DET_CHARGES_FC
                               );
            TotAmountDocLC     := TotAmountDocLC + Expiry_Selection_tuple.DET_PAIED_LC;

            if vUseFC then
              TotAmountDocFC  := TotAmountDocFC + Expiry_Selection_tuple.DET_PAIED_FC;
            end if;
          end if;
--******************************************************************************************
        else
          --Relance
          AmountToPayLC  :=
                 GetAmountLeftReminder(Expiry_Selection_tuple.ACT_EXPIRY_ID, 1, vAmount_OK, vWithInterest, vWithCharge);

          if vUseFC then
            AmountToPayFC  :=
                 GetAmountLeftReminder(Expiry_Selection_tuple.ACT_EXPIRY_ID, 0, vAmount_OK, vWithInterest, vWithCharge);
          else
            AmountToPayFC  := 0;
          end if;

          Signe          := sign(Expiry_Selection_tuple.DET_PAIED_LC);

          --Recherche 1ere échéance de la relance pour info. compl.
          select min(ACT_EXPIRY_ID)
               , count(*)
            into vReminderAdvanceExpId
               , vNumExpiry
            from ACT_EXPIRY
           where ACT_EXPIRY_ID in(
                   select rem.ACT_EXPIRY_ID
                     from ACT_REMINDER rem
                        , ACT_EXPIRY exp
                    where exp.ACT_EXPIRY_ID = Expiry_Selection_tuple.ACT_EXPIRY_ID
                      and exp.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID);

          --Reprise des info compl. de la facture
          GetInfoImputationExpiry(vReminderAdvanceExpId);

          --Lettrage partiel ET une seul échéance dans cette relance
          if vUseFC then
            FlagPartLettering  :=
                  not(AmountToPayFC = Expiry_Selection_tuple.DET_PAIED_FC)
              and (    vAutoPartLettering = 1
                   and vNumExpiry = 1
                   and abs(AmountToPayFC) > abs(Expiry_Selection_tuple.DET_PAIED_FC)
                   and Signe = sign(AmountToPayFC)
                  );
          else
            FlagPartLettering  :=
                  not(AmountToPayLC = Expiry_Selection_tuple.DET_PAIED_LC)
              and (    vAutoPartLettering = 1
                   and vNumExpiry = 1
                   and abs(AmountToPayLC) > abs(Expiry_Selection_tuple.DET_PAIED_LC)
                   and Signe = sign(AmountToPayLC)
                  );
          end if;

          --Si montants égaux ou lettrage partiel
          if    FlagPartLettering
             or (    vAmount_OK
                 and (    (    not vUseFC
                           and AmountToPayLC = Expiry_Selection_tuple.DET_PAIED_LC)
                      or (    vUseFC
                          and AmountToPayFC = Expiry_Selection_tuple.DET_PAIED_FC)
                     )
                ) then
              --Montant OK -> paiement des facture de la relance
              -- ouverture du curseur sur les échéances à l'origine de la relance
            --Création d'une imputation partenaire.
            PartImputation_id  :=
              CREATE_PART_IMPUTATION_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                        , concat(concat(substr(Expiry_Selection_tuple.EXS_RECORD, 50, 10), ' ')
                                               , substr(Expiry_Selection_tuple.EXS_RECORD, 78, 9)
                                                )
                                        , Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID
                                        , 0
                                        , 0
                                        , 0
                                        , vExchangeRate
                                        , vBasePrice
                                        , CurrencyId
                                         );
            --Recherche du compte auxiliaire correspondant au partenaire.
            AuxAccount_id      :=
                           GetPartnerAuxAccount_id(nvl(Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID, DumpPartner_id), 1);
            --Sauvegarde du dernier partenaire et document traité.
            LastPartner_id     := Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID;
            LastDocument_id    := Expiry_Selection_tuple.ACT_DOCUMENT_ID;

            --Création frais de remboursement
            if AmountCharge <> 0 then
              CREATE_FIN_IMP_CHARGES_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                        , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                        , PeriodId
                                        , null
                                        , ImputationDate
                                        , ImputationDate
                                        , ACT_FUNCTIONS.FormatDescription(ChargesDescription, ' / ' || NumDocument, 100)
                                        , AmountCharge   -- IMF_AMOUNT_LC_D
                                        , 0   -- IMF_AMOUNT_LC_C
                                        , 0   -- IMF_EXCHANGE_RATE
                                        , 0   -- IMF_BASE_PRICE
                                        , 0   -- IMF_AMOUNT_FC_D
                                        , 0   -- IMF_AMOUNT_FC_C
                                        , 0   -- IMF_AMOUNT_EUR_D
                                        , 0   -- IMF_AMOUNT_EUR_C
                                        , DefCurrencyId
                                        , DefCurrencyId
                                        , Document_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                                        , Document_tuple.ACS_FINANCIAL_ACCOUNT_ID
                                        , AuxAccount_id
                                        , UserIni
                                        , PartImputation_id
                                        , Expiry_Selection_tuple.ACT_EXPIRY_ID
                                         );
            end if;

            open Expiry_Reminder(Expiry_Selection_tuple.ACT_EXPIRY_ID);

            fetch Expiry_Reminder
             into Expiry_Reminder_tuple;

            while Expiry_Reminder%found loop
----------------------------------
--Paiement une facture

              --Reprise des info compl. de la facture
              GetInfoImputationExpiry(Expiry_Reminder_tuple.ACT_EXPIRY_ID);

              --Lecture de la ligne du document facture
              select DOC_NUMBER
                into NumDocument
                from ACT_DOCUMENT
               where ACT_DOCUMENT.ACT_DOCUMENT_ID = Expiry_Reminder_tuple.ACT_DOCUMENT_ID;

              DiffExchange  := 0;
              AmountChargesSBVR := null;
              AmountChargesSBVR_EUR := null;

              if not FlagPartLettering then
                if vUseFC then
                  AmountFC      :=
                    (Expiry_Reminder_tuple.EXP_AMOUNT_FC -
                     ACT_FUNCTIONS.TotalPayment(Expiry_Reminder_tuple.ACT_EXPIRY_ID, 0)
                    );
                  ACS_FUNCTION.ConvertAmount(AmountFC
                                           , CurrencyId
                                           , DefCurrencyId
                                           , ImputationDate
                                           , vExchangeRate
                                           , vBasePrice
                                           , 1
                                           , vAmountEUR
                                           , vAmountConvert
                                            );
                  AmountLC      := vAmountConvert;
                  if Expiry_Selection_tuple.DET_PAIED_FC <> 0 and AmountFC <> 0 then
                    AmountChargesSBVR := Expiry_Selection_tuple.DET_CHARGES_LC / (Expiry_Selection_tuple.DET_PAIED_FC / AmountFC);
                    AmountChargesSBVR_EUR := Expiry_Selection_tuple.DET_CHARGES_FC / (Expiry_Selection_tuple.DET_PAIED_FC / AmountFC);
                  end if;
                  DiffExchange  :=
                    Signe *
                    (abs(Expiry_Reminder_tuple.EXP_AMOUNT_LC -
                         ACT_FUNCTIONS.TotalPayment(Expiry_Reminder_tuple.ACT_EXPIRY_ID, 1)
                        ) -
                     abs(AmountLC)
                    );
                else
                  AmountLC  :=
                    (Expiry_Reminder_tuple.EXP_AMOUNT_LC -
                     ACT_FUNCTIONS.TotalPayment(Expiry_Reminder_tuple.ACT_EXPIRY_ID, 1)
                    );
                  AmountFC  := 0;
                  if Expiry_Selection_tuple.DET_PAIED_LC <> 0 and AmountLC <> 0 then
                    AmountChargesSBVR := Expiry_Selection_tuple.DET_CHARGES_LC / (Expiry_Selection_tuple.DET_PAIED_LC / AmountLC);
                    AmountChargesSBVR_EUR := Expiry_Selection_tuple.DET_CHARGES_FC / (Expiry_Selection_tuple.DET_PAIED_LC / AmountLC);
                  end if;
                end if;
              else
                if vUseFC then
                  AmountFC  := Expiry_Selection_tuple.DET_PAIED_LC;
                  ACS_FUNCTION.ConvertAmount(AmountFC
                                           , CurrencyId
                                           , DefCurrencyId
                                           , ImputationDate
                                           , vExchangeRate
                                           , vBasePrice
                                           , 1
                                           , vAmountEUR
                                           , vAmountConvert
                                            );
                  AmountLC  := vAmountConvert;
                else
                  AmountLC  := Expiry_Selection_tuple.DET_PAIED_LC;
                  AmountFC  := 0;
                end if;
                AmountChargesSBVR := Expiry_Selection_tuple.DET_CHARGES_LC;
                AmountChargesSBVR_EUR := Expiry_Selection_tuple.DET_CHARGES_FC;
              end if;

              if AmountLC <> 0 then
                DetPayment_id   :=
                  CREATE_DET_PAYMENT_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                        , PartImputation_id
                                        , Expiry_Reminder_tuple.ACT_EXPIRY_ID
                                        , Signe * AmountLC
                                        , 0
                                        , 0
                                        , 0
                                        , DiffExchange
                                        , Signe * AmountFC
                                        , 0
                                        , 0
                                        , 0
                                        , substr(Expiry_Selection_tuple.EXS_RECORD, 1, 3)
                                        , Expiry_Reminder_tuple.ACT_REMINDER_ID
                                         );

                if Expiry_Reminder_tuple.EXP_AMOUNT_LC <> 0 then
                  CREATE_FIN_IMP_PAY_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID   --Doc paiement
                                        , Expiry_Reminder_tuple.ACT_DOCUMENT_ID   --Doc facture
                                        , Expiry_Reminder_tuple.ACT_PART_IMPUTATION_ID   --Doc facture
                                        , PeriodId
                                        , AuxAccount_id
                                        , DetPayment_id
                                        , ImputationDate
                                        , ImputationDate
                                        , ACT_FUNCTIONS.FormatDescription(PaymentDescription, ' / ' || NumDocument, 100)
                                        , 0
                                        , Signe * AmountLC
                                        , vExchangeRate   -- IMF_EXCHANGE_RATE
                                        , vBasePrice   -- IMF_EXCHANGE_RATE
                                        , 0   -- IMF_AMOUNT_FC_D
                                        , Signe * AmountFC
                                        , 0   -- IMF_AMOUNT_EUR_D
                                        , 0   -- IMF_AMOUNT_EUR_C
                                        , CurrencyId
                                        , DefCurrencyId
                                        , UserIni
                                        , PartImputation_id
                                        , AmountChargesSBVR
                                        , AmountChargesSBVR_EUR
                                         );
                end if;

                -- Imputations différence de change et Correction TVA
                if DiffExchange <> 0 then
                  -- Définition des montants
                  ACT_PROCESS_PAYMENT.InitDiffChangeAmounts(true
                                                          , true
                                                          , false
                                                          , DiffExchange
                                                          , AmountLC_D
                                                          , AmountLC_C
                                                          , CollAmountLC_D
                                                          , CollAmountLC_C
                                                           );
                  DiffExchangeFinAccId  := ACT_PROCESS_PAYMENT.GetDiffExchangeAccount(1, DiffExchange, CurrencyId);

                  if    (round(AmountLC_D, 2) <> 0)
                     or (round(AmountLC_C, 2) <> 0) then
                    FinImputation_Id  :=
                      ACT_PROCESS_PAYMENT.DiffExchangeImputations
                                                            (1
                                                           , Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                                           , Expiry_Reminder_tuple.ACT_DOCUMENT_ID
                                                           , PeriodId
                                                           , DiffExchangeFinAccId
                                                           , AuxAccount_id
                                                           , DetPayment_id
                                                           , ImputationDate
                                                           , ImputationDate
                                                           , ACT_FUNCTIONS.FormatDescription(DiffExchangeDescription
                                                                                           , ' / ' || NumDocument
                                                                                           , 100
                                                                                            )
                                                           , AmountLC_D
                                                           , AmountLC_C
                                                           , 0
                                                           ,   -- PAR_EXCHANGE_RATE,
                                                             0
                                                           ,   -- PAR_BASE_PRICE,
                                                             CollAmountLC_D
                                                           , CollAmountLC_C
                                                           , CurrencyId
                                                           , DefCurrencyId
                                                           , UserIni
                                                           , PartImputation_id
                                                            );
                  end if;
                end if;

                TotAmountDocLC  := TotAmountDocLC +(Signe * AmountLC) + Signe *(Expiry_Reminder_tuple.EXP_DISCOUNT_LC);

                if vUseFC then
                  TotAmountDocFC  := TotAmountDocFC +(Signe * AmountFC)
                                     + Signe *(Expiry_Reminder_tuple.EXP_DISCOUNT_FC);
                end if;
              end if;

----------------------------------
              fetch Expiry_Reminder
               into Expiry_Reminder_tuple;
            end loop;

            close Expiry_Reminder;

            --Si paiement partiel, pas de création imputations frais et intêret
            if not FlagPartLettering then
              select nvl(min(PART1.PAR_CHARGES_LC), 0)
                   , nvl(min(PART1.PAR_INTEREST_LC), 0)
                   , nvl(min(PART1.PAR_CHARGES_FC), 0)
                   , nvl(min(PART1.PAR_INTEREST_FC), 0)
                   , min(ACT_REMINDER.ACT_PART_IMPUTATION_ID)
                   , min(ACT_REMINDER.PAC_REMAINDER_CATEGORY_ID)
                   , min(ACT_REMINDER.ACS_TAX_CODE_ID)
                   , min(DOC1.DOC_NUMBER)
                into vReminderChargesLC
                   , vReminderInterestLC
                   , vReminderChargesFC
                   , vReminderInterestFC
                   , vReminderPartImputationId
                   , vReminderCategId
                   , vReminderChargesTaxCodeId
                   , vReminderDocNumber
                from ACT_DOCUMENT DOC1
                   , ACT_PART_IMPUTATION PART1
                   , ACT_REMINDER
                   , ACT_EXPIRY EXP1
               where EXP1.ACT_EXPIRY_ID = Expiry_id
                 and ACT_REMINDER.ACT_PART_IMPUTATION_ID = EXP1.ACT_PART_IMPUTATION_ID
                 and PART1.ACT_PART_IMPUTATION_ID = ACT_REMINDER.ACT_PART_IMPUTATION_ID
                 and DOC1.ACT_DOCUMENT_ID = PART1.ACT_DOCUMENT_ID;

              --Création frais relance
              if     vReminderChargesLC != 0
                 and vWithCharge then
                CREATE_REMINDER_CHARGES_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                           , PeriodId
                                           , ImputationDate
                                           , ImputationDate
                                           , ACT_FUNCTIONS.FormatDescription(ReminderChargesDescription
                                                                           , ' / ' || vReminderDocNumber
                                                                           , 100
                                                                            )
                                           , VatReminderChargesDescription
                                           , vReminderDocNumber
                                           , vReminderChargesLC   -- IMF_AMOUNT_LC_D
                                           , vExchangeRate
                                           , vBasePrice
                                           , vReminderChargesFC   -- IMF_AMOUNT_FC_D
                                           , 0   -- IMF_AMOUNT_EUR_D
                                           , CurrencyId
                                           , DefCurrencyId
                                           , AuxAccount_id
                                           , UserIni
                                           , PartImputation_id
                                           , vReminderCategId
                                           , vReminderChargesTaxCodeId
                                            );

                --Màj nouveaux champs
                update ACT_PART_IMPUTATION
                   set PAR_PAIED_CHARGES_LC = vReminderChargesLC
                     , PAR_PAIED_CHARGES_FC = vReminderChargesFC
                 where ACT_PART_IMPUTATION_ID = PartImputation_id;

                TotAmountDocLC  := TotAmountDocLC + vReminderChargesLC;

                if vUseFC then
                  TotAmountDocFC  := TotAmountDocFC + vReminderChargesFC;
                end if;
              end if;

              --Création intéret moratoire relance
              if     vReminderInterestLC != 0
                 and vWithInterest then
                CREATE_REMINDER_INTEREST_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                            , PeriodId
                                            , ImputationDate
                                            , ImputationDate
                                            , ACT_FUNCTIONS.FormatDescription(ReminderInterestDescription
                                                                            , ' / ' || vReminderDocNumber
                                                                            , 100
                                                                             )
                                            , vReminderInterestLC   -- IMF_AMOUNT_LC_D
                                            , vExchangeRate
                                            , vBasePrice
                                            , vReminderInterestFC   -- IMF_AMOUNT_FC_D
                                            , 0   -- IMF_AMOUNT_EUR_D
                                            , CurrencyId
                                            , DefCurrencyId
                                            , AuxAccount_id
                                            , UserIni
                                            , PartImputation_id
                                            , vReminderCategId
                                             );

                --Màj nouveaux champs
                update ACT_PART_IMPUTATION
                   set PAR_PAIED_INTEREST_LC = vReminderInterestLC
                     , PAR_PAIED_INTEREST_FC = vReminderInterestFC
                 where ACT_PART_IMPUTATION_ID = PartImputation_id;

                TotAmountDocLC  := TotAmountDocLC + vReminderInterestLC;

                if vUseFC then
                  TotAmountDocFC  := TotAmountDocFC + vReminderInterestFC;
                end if;
              end if;

              --Màj statut relance
              UpdateStatusReminders(vReminderPartImputationId);
            end if;
          else
            if (     (ParDocDoubleBlocked = 1)
                and (AmountToPayLC = 0)
                and (    (    not vUseFC
                          and (Expiry_Selection_tuple.DET_PAIED_LC = GetAmount(Expiry_Selection_tuple.ACT_EXPIRY_ID, 1)
                              )
                         )
                     or (    vUseFC
                         and (Expiry_Selection_tuple.DET_PAIED_FC = GetAmount(Expiry_Selection_tuple.ACT_EXPIRY_ID, 0)
                             )
                        )
                    )
               ) then   --Paiement double.
              blocked  := 1;
            else
              blocked  := 0;
            end if;

            --Création d'une imputation partenaire.
            PartImputation_id  :=
              CREATE_PART_IMPUTATION_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                        , concat(concat(substr(Expiry_Selection_tuple.EXS_RECORD, 50, 10), ' ')
                                               , substr(Expiry_Selection_tuple.EXS_RECORD, 78, 9)
                                                )
                                        , Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID
                                        , blocked
                                        , 0
                                        , 0
                                        , vExchangeRate
                                        , vBasePrice
                                        , CurrencyId
                                         );
            --Recherche du compte auxiliaire correspondant au partenaire.
            AuxAccount_id      := GetPartnerAuxAccount_id(Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID, 1);
            --Sauvegarde du dernier partenaire et document traité.
            LastPartner_id     := Expiry_Selection_tuple.PAC_CUSTOM_PARTNER_ID;
            LastDocument_id    := Expiry_Selection_tuple.ACT_DOCUMENT_ID;

            --Création frais de remboursement
            if AmountCharge <> 0 then
              CREATE_FIN_IMP_CHARGES_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                                        , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                                        , PeriodId
                                        , null
                                        , ImputationDate
                                        , ImputationDate
                                        , ACT_FUNCTIONS.FormatDescription(ChargesDescription, ' / ' || NumDocument, 100)
                                        , AmountCharge   -- IMF_AMOUNT_LC_D
                                        , 0   -- IMF_AMOUNT_LC_C
                                        , 0   -- IMF_EXCHANGE_RATE
                                        , 0   -- IMF_BASE_PRICE
                                        , 0   -- IMF_AMOUNT_FC_D
                                        , 0   -- IMF_AMOUNT_FC_C
                                        , 0   -- IMF_AMOUNT_EUR_D
                                        , 0   -- IMF_AMOUNT_EUR_C
                                        , DefCurrencyId
                                        , DefCurrencyId
                                        , Document_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                                        , Document_tuple.ACS_FINANCIAL_ACCOUNT_ID
                                        , AuxAccount_id
                                        , UserIni
                                        , PartImputation_id
                                        , Expiry_Selection_tuple.ACT_EXPIRY_ID
                                         );
            end if;

            CREATE_ADVANCE_SBVR(Expiry_Selection_tuple.ACT_DOCUMENT_ID
                              , PartImputation_id
                              , AuxAccount_id
                              , Expiry_Selection_tuple.EXS_REFERENCE
                              , ImputationDate
                              , ImputationDate
                              , AdvanceDescription
                              , 0
                              , Expiry_Selection_tuple.DET_PAIED_LC
                              , vExchangeRate
                              , vBasePrice
                              , 0
                              , Expiry_Selection_tuple.DET_PAIED_FC
                              , 0
                              , 0
                              , CurrencyId
                              , Expiry_Selection_tuple.ACT_DOCUMENT_ID2
                              , true
                              , Expiry_Selection_tuple.DET_CHARGES_LC
                              , Expiry_Selection_tuple.DET_CHARGES_FC
                               );
            TotAmountDocLC     := TotAmountDocLC + Expiry_Selection_tuple.DET_PAIED_LC;

            if vUseFC then
              TotAmountDocFC  := TotAmountDocFC + Expiry_Selection_tuple.DET_PAIED_FC;
            end if;
          end if;
        end if;
      end if;

      --Si pas de montant à reporter sur le paiement en cours (paiement + avance)
      if AmountToReportLC = 0 then
        --Prochain paiement
        fetch Expiry_Selection
         into Expiry_Selection_tuple;

        vOverLettering  := false;
      else
        --Même paiement avec le montant avec le reste du montant à payer (création d'une avance)
        Expiry_Selection_tuple.DET_PAIED_LC  := AmountToReportLC;
        Expiry_Selection_tuple.DET_PAIED_FC  := AmountToReportFC;
        AmountToReportLC                     := 0;
        AmountToReportFC                     := 0;
        vOverLettering                       := true;
      end if;

      --Ecriture de l'imputation primaire
      if    (    not Expiry_Selection%found
             and AmountToReportLC = 0)
         or (     (LastDocument_id <> 0)
             and (Expiry_Selection_tuple.ACT_DOCUMENT_ID <> LastDocument_id) ) then
        if vUseFC then
          CREATE_FIN_IMP_PRIMARY_SBVR(LastDocument_id
                                    ,   --Doc paiement
                                      FinAccount_id
                                    , ImputationDate
                                    , ImputationDate
                                    , PaymentDescription
                                    , TotAmountDocLC
                                    , 0
                                    , vExchangeRate
                                    , vBasePrice
                                    , TotAmountDocFC
                                    , 0
                                    , 0
                                    , 0
                                    , CurrencyId
                                     );
        else
          CREATE_FIN_IMP_PRIMARY_SBVR(LastDocument_id
                                    ,   --Doc paiement
                                      FinAccount_id
                                    , ImputationDate
                                    , ImputationDate
                                    , PaymentDescription
                                    , TotAmountDocLC
                                    , 0
                                    , 0
                                    , 0
                                    , 0
                                    , 0
                                    , 0
                                    , 0
                                    , CurrencyId
                                     );
        end if;

        TotAmountDocLC  := 0;
        TotAmountDocFC  := 0;
      end if;

      commit;
    end loop;

    close Expiry_Selection;

    CloseTransactionSBVR(aACT_ETAT_EVENT_ID);
  end GENERATE_FINANCIAL;

  /**
  * Description
  *   Création d'une echéance et d'une imputation partenaire pour le SBVR (client 'poubelle')
  */
/* *** DWA 21092005: Plus utilisé ? ***
  function CREATE_EXPIRY_SBVR(
    aACT_DOCUMENT_ID          number
  , aDate                     date
  , aPAR_DOCUMENT             varchar2
  , aDET_PAIED_LC             number
  , aDET_DISCOUNT_LC          number
  , aDET_CHARGES_LC           number
  , aEXS_REFERENCE            varchar2
  , aPAC_CUSTOM_PARTNER_ID    number
  , aACS_FIN_ACC_S_PAYMENT_ID number
  )
    return number
  is
    PartImputation_id ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    Expiry_id         ACT_EXPIRY.ACT_EXPIRY_ID%type;
  begin
    select init_id_seq.nextval
      into PartImputation_id
      from dual;

    select init_id_seq.nextval
      into Expiry_id
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
         values (PartImputation_id
               , aACT_DOCUMENT_ID
               , aPAR_DOCUMENT
               , 0
               , aPAC_CUSTOM_PARTNER_ID
               , null
               , null
               , null
               , null
               , null
               , null
               , ACS_FUNCTION.GetLocalCurrencyID
               , ACS_FUNCTION.GetLocalCurrencyID
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , trunc(sysdate)
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    insert into ACT_EXPIRY
                (ACT_EXPIRY_ID
               , ACT_DOCUMENT_ID
               , ACT_PART_IMPUTATION_ID
               , EXP_ADAPTED
               , EXP_CALCULATED
               , EXP_AMOUNT_LC
               , EXP_AMOUNT_FC
               , EXP_SLICE
               , EXP_DISCOUNT_LC
               , EXP_DISCOUNT_FC
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
         values (Expiry_id
               , aACT_DOCUMENT_ID
               , PartImputation_id
               , aDate
               , aDate
               , aDET_PAIED_LC
               , 0
               , 1
               , aDET_DISCOUNT_LC
               , 0
               , 100
               , 1
               , 0
               , null
               , null
               , aEXS_REFERENCE
               , aACS_FIN_ACC_S_PAYMENT_ID
               , 0
               , 0
               , trunc(sysdate)
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    return Expiry_id;
  end CREATE_EXPIRY_SBVR;
*/

  /**
  * Création d'une imputation partenaire pour le SBVR
  **/
  function CREATE_PART_IMPUTATION_SBVR(
    aACT_DOCUMENT_ID           number
  , aPAR_DOCUMENT              varchar2
  , aPAC_CUSTOM_PARTNER_ID     number
  , aPAR_BLOCKED_DOCUMENT      number
  , aPAR_CHARGES_LC            number
  , aPAR_CHARGES_FC            number
  , aPAR_EXCHANGE_RATE         number
  , aPAR_BASE_PRICE            number
  , aACS_FINANCIAL_CURRENCY_ID number
  )
    return number
  is
    PartImputation_id ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    DocPartner        ACT_PART_IMPUTATION.PAR_DOCUMENT%type;
  begin
    if instr(aPAR_DOCUMENT, '0', 1, 19) <> 0 then
      DocPartner  := '';
    else
      DocPartner  := aPAR_DOCUMENT;
    end if;

    select init_id_seq.nextval
      into PartImputation_id
      from dual;

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
         values (PartImputation_id
               , aACT_DOCUMENT_ID
               , DocPartner
               , aPAR_BLOCKED_DOCUMENT
               , aPAC_CUSTOM_PARTNER_ID
               , null
               , null
               , null
               , null
               , null
               , null
               , aACS_FINANCIAL_CURRENCY_ID
               , ACS_FUNCTION.GetLocalCurrencyID
               , null
               , aPAR_CHARGES_LC
               , null
               , aPAR_CHARGES_FC
               , aPAR_EXCHANGE_RATE
               , aPAR_BASE_PRICE
               , null
               , null
               , null
               , null
               , trunc(sysdate)
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    return PartImputation_id;
  end CREATE_PART_IMPUTATION_SBVR;

  /**
  * Création d'un paiement du SBVR
  **/
  function CREATE_DET_PAYMENT_SBVR(
    aACT_DOCUMENT_ID        number
  , aACT_PART_IMPUTATION_ID number
  , aACT_EXPIRY_ID          number
  , aDET_PAIED_LC           number
  , aDET_CHARGES_LC         number
  , aDET_DISCOUNT_LC        number
  , aDET_DEDUCTION_LC       number
  , aDET_DIFF_EXCHANGE      number
  , aDET_PAIED_FC           number
  , aDET_CHARGES_FC         number
  , aDET_DISCOUNT_FC        number
  , aDET_DEDUCTION_FC       number
  , aDET_TRANSACTION_TYPE   varchar2
  , aDET_ACT_REMINDER_ID    number default null
  )
    return number
  is
    DetPayment_id ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type;
  begin
    select init_id_seq.nextval
      into DetPayment_id
      from dual;

    -- Création d'un tuple pour les paiements
    insert into ACT_DET_PAYMENT
                (ACT_DET_PAYMENT_ID
               , ACT_EXPIRY_ID
               , ACT_DOCUMENT_ID
               , ACT_PART_IMPUTATION_ID
               , DET_PAIED_LC
               , DET_PAIED_FC
               , DET_CHARGES_LC
               , DET_CHARGES_FC
               , DET_DISCOUNT_LC
               , DET_DISCOUNT_FC
               , DET_DEDUCTION_LC
               , DET_DEDUCTION_FC
               , DET_LETTRAGE_NO
               , DET_DIFF_EXCHANGE
               , DET_TRANSACTION_TYPE
               , DET_SEQ_NUMBER
               , DET_ACT_REMINDER_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (DetPayment_id
               , aACT_EXPIRY_ID
               , aACT_DOCUMENT_ID
               , aACT_PART_IMPUTATION_ID
               , aDET_PAIED_LC
               , aDET_PAIED_FC
               , aDET_CHARGES_LC
               , aDET_CHARGES_FC
               , aDET_DISCOUNT_LC
               , aDET_DISCOUNT_FC
               , aDET_DEDUCTION_LC
               , aDET_DEDUCTION_FC
               , null
               , aDET_DIFF_EXCHANGE
               , aDET_TRANSACTION_TYPE
               , null
               , aDET_ACT_REMINDER_ID
               , trunc(sysdate)
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    return DetPayment_id;
  end CREATE_DET_PAYMENT_SBVR;

  /**
  * Description
  *   Création d'une imputation financière paiement.
  **/
  procedure CREATE_FIN_IMP_PAY_SBVR(
    aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type   --Doc paiement
  , aACT_DOCUMENT_ID2            ACT_DOCUMENT.ACT_DOCUMENT_ID%type   --Doc facture
  , aACT_PART_IMPUTATION_ID2     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aACS_PERIOD_ID               ACS_PERIOD.ACS_PERIOD_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACT_DET_PAYMENT_ID          ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C                 ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aIMF_EXCHANGE_RATE           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_FC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aAmount_EUR_D                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmount_EUR_C                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aA_IDCRE                     ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aACT_PART_IMPUTATION_ID      ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aAmountChargesSBVR           ACT_FINANCIAL_IMPUTATION.IMF_CHARGES_SBVR%type default null
  , aAmountChargesSBVR_EUR       ACT_FINANCIAL_IMPUTATION.IMF_CHARGES_SBVR_EUR%type default null
  )
  is
    FinImputation_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinAccount_id    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
    AuxAccount_id    ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputation_id
      from dual;

    FinAccount_id  :=
              ACT_CREATION_SBVR.GetFinAccount_id(aACS_AUXILIARY_ACCOUNT_ID, aACT_DOCUMENT_ID2, aACT_PART_IMPUTATION_ID2);

    if IsFinAccCollective(FinAccount_id) = 1 then
      AuxAccount_id  := aACS_AUXILIARY_ACCOUNT_ID;
    else
      AuxAccount_id  := null;
    end if;

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
               , IMF_AMOUNT_FC_D
               , IMF_AMOUNT_FC_C
               , IMF_AMOUNT_EUR_D
               , IMF_AMOUNT_EUR_C
               , IMF_CHARGES_SBVR
               , IMF_CHARGES_SBVR_EUR
               , IMF_VALUE_DATE
               , ACS_TAX_CODE_ID
               , IMF_TRANSACTION_DATE
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACT_DET_PAYMENT_ID
               , IMF_GENRE
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputation_id
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , FinAccount_id
               , 'AUX'
               , 0
               , aDescription
               , aAmount_LC_D
               , aAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , aAmount_FC_D
               , aAmount_FC_C
               , aAmount_EUR_D
               , aAmount_EUR_C
               , aAmountChargesSBVR
               , aAmountChargesSBVR_EUR
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , AuxAccount_id
               ,   --DW:15.06.98
                 aACT_DET_PAYMENT_ID
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , aF_ACS_FINANCIAL_CURRENCY_ID
               , 1
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    UpdateInfoImpIMF(FinImputation_id);
    CREATE_FIN_DISTRI_BVR(FinImputation_id
                        , aDescription
                        , aAmount_LC_D
                        , aAmount_LC_C
                        , aAmount_FC_D
                        , aAmount_FC_C
                        , aAmount_EUR_D
                        , aAmount_EUR_C
                        , FinAccount_id
                        , aACS_AUXILIARY_ACCOUNT_ID
                        , aACT_DOCUMENT_ID2
                        , aA_IDCRE
                        , aIMF_TRANSACTION_DATE
                        , 1
                         );
  end CREATE_FIN_IMP_PAY_SBVR;

  /**
  * Description
  *    Création d'une imputation financière primaire.
  **/
  procedure CREATE_FIN_IMP_PRIMARY_SBVR(
    aACT_DOCUMENT_ID           number
  ,   --Doc paiement
    aACS_FINANCIAL_ACCOUNT_ID  number
  , aIMF_TRANSACTION_DATE      ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE            ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription               varchar2
  , aAmount_LC_D               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_EXCHANGE_RATE         ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE            ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC_D               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_FC_C               ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aAmount_EUR_D              ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmount_EUR_C              ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  )
  is
    FinImputation_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinAccount_id    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputation_id
      from dual;

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
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
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
                )
         values (FinImputation_id
               , ACS_FUNCTION.GetPeriodId(aIMF_TRANSACTION_DATE, TypeOfPeriod)
               , aACT_DOCUMENT_ID
               , aACS_FINANCIAL_ACCOUNT_ID
               , 'MAN'
               , 1
               , aDescription
               , aAmount_LC_D
               , aAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , aAmount_FC_D
               , aAmount_FC_C
               , aAmount_EUR_D
               , aAmount_EUR_C
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , null
               , null
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , ACS_FUNCTION.GetLocalCurrencyId
               , 1
               , null
               , trunc(sysdate)
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    CREATE_FIN_DISTRI_BVR(FinImputation_id
                        , aDescription
                        , aAmount_LC_D
                        , aAmount_LC_C
                        , aAmount_FC_D
                        , aAmount_FC_C
                        , 0   -- aAmount_EUR_D,
                        , 0   -- aAmount_EUR_C,
                        , aACS_FINANCIAL_ACCOUNT_ID
                        , null   -- aACS_AUXILIARY_ACCOUNT_ID,
                        , null   -- aACT_DOCUMENT_ID2,
                        , PCS.PC_I_LIB_SESSION.GetUserIni
                        , aIMF_TRANSACTION_DATE
                        , 0
                         );
  end CREATE_FIN_IMP_PRIMARY_SBVR;

  /**
  * Description
  *   Création d'une imputation pour escompte.
  **/
  function CREATE_FIN_IMP_DISCOUNT_SBVR(
    aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACT_DOCUMENT_ID2            ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID               ACS_PERIOD.ACS_PERIOD_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACT_DET_PAYMENT_ID          ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aIMF_EXCHANGE_RATE           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_FC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aAmount_EUR_D                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmount_EUR_C                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aA_IDCRE                     ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aACT_PART_IMPUTATION_ID      ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  )
    return ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  is
    FinImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinAccountId    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputationId
      from dual;

    FinAccountId  := ACT_CREATION_SBVR.GetDiscountAccountId(aACS_AUXILIARY_ACCOUNT_ID, aACT_DOCUMENT_ID2);

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
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
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputationId
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , FinAccountId
               , 'MAN'
               , 0
               , aDescription
               , aAmount_LC_D
               , aAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , aAmount_FC_D
               , aAmount_FC_C
               , aAmount_EUR_D
               , aAmount_EUR_C
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , null
               , aACT_DET_PAYMENT_ID
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , aF_ACS_FINANCIAL_CURRENCY_ID
               , 2
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    UpdateInfoImpIMF(FinImputationId);
    CREATE_FIN_DISTRI_BVR(FinImputationId
                        , aDescription
                        , aAmount_LC_D
                        , aAmount_LC_C
                        , aAmount_FC_D
                        , aAmount_FC_C
                        , aAmount_EUR_D
                        , aAmount_EUR_C
                        , FinAccountId
                        , aACS_AUXILIARY_ACCOUNT_ID
                        , aACT_DOCUMENT_ID2
                        , aA_IDCRE
                        , aIMF_TRANSACTION_DATE
                        , 1
                         );

    if ExistMAN <> 0 then
      CreateMANImputForDiscount(FinAccountId
                              , aACS_FINANCIAL_CURRENCY_ID
                              , aF_ACS_FINANCIAL_CURRENCY_ID
                              , aACS_PERIOD_ID
                              , aACT_DOCUMENT_ID
                              , FinImputationId
                              , 'MAN'
                              , 'STD'
                              , aDescription
                              , 0
                              , aAmount_LC_D
                              , aAmount_LC_C
                              , aIMF_EXCHANGE_RATE
                              , aIMF_BASE_PRICE
                              , aAmount_FC_D
                              , aAmount_FC_C
                              , aAmount_EUR_D
                              , aAmount_EUR_C
                              , aIMF_VALUE_DATE
                              , aIMF_TRANSACTION_DATE
                              , aACS_AUXILIARY_ACCOUNT_ID
                              , aACT_DOCUMENT_ID2
                              , aA_IDCRE
                               );
    end if;

    return FinImputationId;
  end CREATE_FIN_IMP_DISCOUNT_SBVR;

  /**
  * Description
  *   Création d'une imputation pour réduction.
  **/
  function CREATE_FIN_IMP_DEDUCTION_SBVR(
    aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACT_DOCUMENT_ID2            ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID               ACS_PERIOD.ACS_PERIOD_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACT_DET_PAYMENT_ID          ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_EXCHANGE_RATE           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_FC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aAmount_EUR_D                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmount_EUR_C                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aA_IDCRE                     ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aACT_PART_IMPUTATION_ID      ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aNegativeDeduction           boolean
  )
    return ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  is
    FinImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinAccountId    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputationId
      from dual;

    FinAccountId  :=
               ACT_CREATION_SBVR.GetDeductionAccountId(aACS_AUXILIARY_ACCOUNT_ID, aACT_DOCUMENT_ID2, aNegativeDeduction);

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
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
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputationId
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , FinAccountId
               , 'MAN'
               , 0
               , aDescription
               , aAmount_LC_D
               , aAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , aAmount_FC_D
               , aAmount_FC_C
               , aAmount_EUR_D
               , aAmount_EUR_C
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , null
               , aACT_DET_PAYMENT_ID
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , aF_ACS_FINANCIAL_CURRENCY_ID
               , 3
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    UpdateInfoImpIMF(FinImputationId);
    CREATE_FIN_DISTRI_BVR(FinImputationId
                        , aDescription
                        , aAmount_LC_D
                        , aAmount_LC_C
                        , aAmount_FC_D
                        , aAmount_FC_C
                        , aAmount_EUR_D
                        , aAmount_EUR_C
                        , FinAccountId
                        , aACS_AUXILIARY_ACCOUNT_ID
                        , aACT_DOCUMENT_ID2
                        , aA_IDCRE
                        , aIMF_TRANSACTION_DATE
                        , 1
                         );

    if ExistMAN <> 0 then
      CreateMANImputForDeduction(FinAccountId
                               , aACS_FINANCIAL_CURRENCY_ID
                               , aF_ACS_FINANCIAL_CURRENCY_ID
                               , aACS_PERIOD_ID
                               , aACT_DOCUMENT_ID
                               , FinImputationId
                               , 'MAN'
                               , 'STD'
                               , aDescription
                               , 0
                               , aAmount_LC_D
                               , aAmount_LC_C
                               , aIMF_EXCHANGE_RATE
                               , aIMF_BASE_PRICE
                               , aAmount_FC_D
                               , aAmount_FC_C
                               , aAmount_EUR_D
                               , aAmount_EUR_C
                               , aIMF_VALUE_DATE
                               , aIMF_TRANSACTION_DATE
                               , aACS_AUXILIARY_ACCOUNT_ID
                               , aACT_DOCUMENT_ID2
                               , aA_IDCRE
                               , aNegativeDeduction
                                );
    end if;

    return FinImputationId;
  end CREATE_FIN_IMP_DEDUCTION_SBVR;

  /**
  * Description
  *    Création d'une imputation pour frais.
  **/
  procedure CREATE_FIN_IMP_CHARGES_SBVR(
    aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACT_DOCUMENT_ID2            ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID               ACS_PERIOD.ACS_PERIOD_ID%type
  , aACT_DET_PAYMENT_ID          ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmount_LC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_EXCHANGE_RATE           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC_D                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_FC_C                 ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aAmount_EUR_D                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aAmount_EUR_C                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_FIN_ACC_S_PAYMENT_ID    ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aA_IDCRE                     ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aACT_PART_IMPUTATION_ID      ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aACT_EXPIRY_ID               ACT_EXPIRY.ACT_EXPIRY_ID%type
  )
  is
    FinImputation_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinAccount_id    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputation_id
      from dual;

    FinAccount_id  := ACT_CREATION_SBVR.GetBVRChargeAccount_id(aACS_FIN_ACC_S_PAYMENT_ID);

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
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
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputation_id
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , FinAccount_id
               , 'MAN'
               , 0
               , aDescription
               , aAmount_LC_C
               , aAmount_LC_D
               , aIMF_EXCHANGE_RATE
               , aAmount_FC_C
               , aAmount_FC_D
               , aAmount_EUR_C
               , aAmount_EUR_D
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , null
               , aACT_DET_PAYMENT_ID
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , AF_ACS_FINANCIAL_CURRENCY_ID
               , 3
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    UpdateInfoImpIMF(FinImputation_id);
    CREATE_FIN_DISTRI_BVR(FinImputation_id
                        , aDescription
                        , aAmount_LC_D
                        , aAmount_LC_C
                        , aAmount_FC_D
                        , aAmount_FC_C
                        , aAmount_EUR_D
                        , aAmount_EUR_C
                        , FinAccount_id
                        , aACS_AUXILIARY_ACCOUNT_ID   -- aACS_AUXILIARY_ACCOUNT_ID,
                        , aACT_DOCUMENT_ID2   -- aACT_DOCUMENT_ID2,
                        , aA_IDCRE
                        , aIMF_TRANSACTION_DATE
                        , 1
                         );

    if ExistMAN <> 0 then
      CreateMANImputForCharges(FinAccount_id
                             , aACS_FINANCIAL_CURRENCY_ID
                             , aF_ACS_FINANCIAL_CURRENCY_ID
                             , aACS_PERIOD_ID
                             , aACT_DOCUMENT_ID
                             , FinImputation_id
                             , 'MAN'
                             , 'STD'
                             , aDescription
                             , 0
                             , aAmount_LC_C
                             , aAmount_LC_D
                             , aIMF_EXCHANGE_RATE
                             , aIMF_BASE_PRICE
                             , aAmount_FC_C
                             , aAmount_FC_D
                             , aAmount_EUR_C
                             , aAmount_EUR_D
                             , aIMF_VALUE_DATE
                             , aIMF_TRANSACTION_DATE
                             , aACS_AUXILIARY_ACCOUNT_ID
                             , aACT_DOCUMENT_ID2
                             , aA_IDCRE
                              );
    end if;

    select init_id_seq.nextval
      into FinImputation_id
      from dual;

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
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
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputation_id
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , aACS_FINANCIAL_ACCOUNT_ID
               , 'MAN'
               , 0
               , aDescription
               , aAmount_LC_D
               , aAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , aAmount_FC_D
               , aAmount_FC_C
               , aAmount_EUR_D
               , aAmount_EUR_C
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , null
               , aACT_DET_PAYMENT_ID
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , AF_ACS_FINANCIAL_CURRENCY_ID
               , 3
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    UpdateInfoImpIMF(FinImputation_id);
    CREATE_FIN_DISTRI_BVR(FinImputation_id
                        , aDescription
                        , aAmount_LC_D
                        , aAmount_LC_C
                        , aAmount_FC_D
                        , aAmount_FC_C
                        , aAmount_EUR_D
                        , aAmount_EUR_C
                        , aACS_FINANCIAL_ACCOUNT_ID
                        , aACS_AUXILIARY_ACCOUNT_ID   -- aACS_AUXILIARY_ACCOUNT_ID,
                        , aACT_DOCUMENT_ID2   -- aACT_DOCUMENT_ID2,
                        , aA_IDCRE
                        , aIMF_TRANSACTION_DATE
                        , 1
                         );
  end CREATE_FIN_IMP_CHARGES_SBVR;

  /**
  * Description
  *   Création d'une imputation et d'une expiry pour avance.
  **/
  procedure CREATE_ADVANCE_SBVR(
    aACT_DOCUMENT_ID           number
  , aACT_PART_IMPUTATION_ID    number
  , aACS_AUXILIARY_ACCOUNT_ID  number
  , aEXS_REFERENCE             varchar2
  , aIMF_TRANSACTION_DATE      ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE            ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription               ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC_D               number
  , aAmount_LC_C               number
  , aIMF_EXCHANGE_RATE         ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE            ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC_D               number
  , aAmount_FC_C               number
  , aAmount_EUR_D              number
  , aAmount_EUR_C              number
  , aACS_FINANCIAL_CURRENCY_ID number
  , aACT_DOCUMENT_ID2          number default null
  , aSetInfoImputation         boolean default false
  , aAmountChargesSBVR         ACT_FINANCIAL_IMPUTATION.IMF_CHARGES_SBVR%type default null
  , aAmountChargesSBVR_EUR     ACT_FINANCIAL_IMPUTATION.IMF_CHARGES_SBVR_EUR%type default null
  )
  is
    FinImputation_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinAccount_id    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type;
    DivAccount_id    ACT_FINANCIAL_DISTRIBUTION.ACS_DIVISION_ACCOUNT_ID%type;
    Expiry_id        ACT_EXPIRY.ACT_EXPIRY_ID%type;
    Amount_LC        ACT_EXPIRY.EXP_AMOUNT_LC%type;
    Amount_FC        ACT_EXPIRY.EXP_AMOUNT_FC%type;
    Amount_EUR       ACT_EXPIRY.EXP_AMOUNT_EUR%type;
  begin
    select init_id_seq.nextval
      into FinImputation_id
      from dual;

    select init_id_seq.nextval
      into Expiry_id
      from dual;

    Amount_LC   := -aAmount_LC_C;
    Amount_FC   := -aAmount_FC_C;
    Amount_EUR  := -aAmount_EUR_C;

    if Amount_LC = 0 then
      Amount_LC   := -aAmount_LC_D;
      Amount_FC   := -aAmount_FC_D;
      Amount_EUR  := -aAmount_EUR_C;
    end if;

    if aACT_DOCUMENT_ID2 is not null then
      FinAccount_id  := ACT_CREATION_SBVR.GetFinAccount_id(aACS_AUXILIARY_ACCOUNT_ID, aACT_DOCUMENT_ID2);
      DivAccount_id  := ACT_CREATION_SBVR.GetDivAccount_id(aACS_AUXILIARY_ACCOUNT_ID, aACT_DOCUMENT_ID2);
    end if;

    if FinAccount_id is null then
      select ACS_PREP_COLL_ID
        into FinAccount_id
        from ACS_AUXILIARY_ACCOUNT
       where ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID;
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
               , EXP_AMOUNT_PROV_EUR
               , A_DATECRE
               , A_IDCRE
                )
         values (Expiry_id
               , aACT_DOCUMENT_ID
               , aACT_PART_IMPUTATION_ID
               , aIMF_TRANSACTION_DATE
               , aIMF_TRANSACTION_DATE
               , aIMF_TRANSACTION_DATE
               , Amount_LC
               , Amount_FC
               , Amount_EUR
               , 1
               , 0
               , 0
               , 0
               , 100
               , 1
               , 0
               , null
               , null
               , aEXS_REFERENCE
               , null
               , 0
               , 0
               , 0
               , trunc(sysdate)
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
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
               , IMF_CHARGES_SBVR
               , IMF_CHARGES_SBVR_EUR
               , IMF_VALUE_DATE
               , ACS_TAX_CODE_ID
               , IMF_TRANSACTION_DATE
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACT_DET_PAYMENT_ID
               , IMF_GENRE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputation_id
               , ACS_FUNCTION.GetPeriodId(aIMF_TRANSACTION_DATE, TypeOfPeriod)
               , aACT_DOCUMENT_ID
               , FinAccount_id
               , 'MAN'
               , 0
               , aDescription
               , aAmount_LC_D
               , aAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , aIMF_BASE_PRICE
               , aAmount_FC_D
               , aAmount_FC_C
               , aAmount_EUR_D
               , aAmount_EUR_C
               , aAmountChargesSBVR
               , aAmountChargesSBVR_EUR
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , aACS_AUXILIARY_ACCOUNT_ID
               , null
               , 'STD'
               , aACS_FINANCIAL_CURRENCY_ID
               , ACS_FUNCTION.GetLocalCurrencyId
               , 1
               , null
               , trunc(sysdate)
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    if aSetInfoImputation then
      UpdateInfoImpIMF(FinImputation_id);
    end if;

    CREATE_FIN_DISTRI_BVR(FinImputation_id
                        , aDescription
                        , aAmount_LC_D
                        , aAmount_LC_C
                        , aAmount_FC_D
                        , aAmount_FC_C
                        , aAmount_EUR_D
                        , aAmount_EUR_C
                        , FinAccount_id
                        , null   -- aACS_AUXILIARY_ACCOUNT_ID,
                        , null   -- aACT_DOCUMENT_ID2,
                        , PCS.PC_I_LIB_SESSION.GetUserIni
                        , aIMF_TRANSACTION_DATE
                        , 0
                        , DivAccount_id
                         );
  end CREATE_ADVANCE_SBVR;

  /**
  * Description
  *    Retourne le type de document à l'origine d'une échéance
  **/
  function GetDocTypeOfExpiry(aACT_EXPIRY_ID number)
    return varchar2
  is
    TypeCatalogue acj_catalogue_document.c_type_catalogue%type;
  begin
    select acj_catalogue_document.c_type_catalogue
      into TypeCatalogue
      from act_expiry
         , act_document
         , acj_catalogue_document
     where act_expiry.act_document_id = act_document.act_document_id
       and acj_catalogue_document.acj_catalogue_document_id = act_document.acj_catalogue_document_id
       and act_expiry.act_expiry_id = aACT_EXPIRY_ID;

    return TypeCatalogue;
  end GetDocTypeOfExpiry;

  /**
  * Description
  *   Retourne le partenaire 'poubelle' d'une méthode de paiement SBVR
  **/
  function GetDefaultPartnerSBVR(aACS_FIN_ACC_S_PAYMENT_ID number)
    return number
  is
    Partner_id PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
  begin
    select PAC_CUSTOM_PARTNER_ID
      into Partner_id
      from ACS_FIN_ACC_S_PAYMENT
     where ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID = aACS_FIN_ACC_S_PAYMENT_ID;

    return Partner_id;
  end GetDefaultPartnerSBVR;

  /**
  * Description
  *    Recherche du compte de charges
  **/
  function GetBVRChargeAccount_id(aACS_FIN_ACC_S_PAYMENT_ID number)
    return number
  is
    ChargeAccount_id ACS_FIN_ACC_S_PAYMENT.ACS_FINANCIAL_ACCOUNT2_ID%type;
  begin
    select ACS_FINANCIAL_ACCOUNT2_ID
      into ChargeAccount_id
      from ACS_FIN_ACC_S_PAYMENT
     where ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID = aACS_FIN_ACC_S_PAYMENT_ID;

    if ChargeAccount_id is null then
      raise_application_error(-20000, 'PCS - CHARGES AMOUNT - ACCOUNT UNDEFINED');
    end if;

    return ChargeAccount_id;
  end GetBVRChargeAccount_id;

---------------------------------
  function GetFinancialImputationId(
    aACT_DOCUMENT_ID              ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID out ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  )
    return ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  is
    cursor OriginAccountCursor(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   IMP.ACS_FINANCIAL_ACCOUNT_ID
             , IMP.ACT_FINANCIAL_IMPUTATION_ID
          from ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.FIN_COLLECTIVE = 0
           and IMP.IMF_TYPE = 'MAN'
           and IMP.C_GENRE_TRANSACTION = '1'
      order by (IMP.IMF_AMOUNT_LC_D + IMP.IMF_AMOUNT_LC_C) desc;

    FinImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
  begin
    open OriginAccountCursor(aACT_DOCUMENT_ID);

    fetch OriginAccountCursor
     into aACS_FINANCIAL_ACCOUNT_ID
        , FinImputationId;

    close OriginAccountCursor;

    return FinImputationId;
  end GetFinancialImputationId;

  /**
  * Description
  *    Recherche du compte d'escompte
  **/
  function GetDiscountAccountId(
    aACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aOriginDocumentId         ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  )
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    DiscountAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    OriginImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
  begin
    select ACS_DISCOUNT_ACCOUNT_ID
      into DiscountAccountId
      from ACS_SUB_SET
         , ACS_ACCOUNT
     where ACS_ACCOUNT.ACS_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
       and ACS_SUB_SET.ACS_SUB_SET_ID = ACS_ACCOUNT.ACS_SUB_SET_ID;

    if DiscountAccountId is null then
      OriginImputationId  := GetFinancialImputationId(aOriginDocumentId, DiscountAccountId);
    end if;

    if DiscountAccountId is null then
      raise_application_error(-20000, 'PCS - DISCOUNT AMOUNT - ACCOUNT UNDEFINED');
    end if;

    return DiscountAccountId;
  end GetDiscountAccountId;

  /**
  * Description
  *    Recherche du compte de deduction
  */
  function GetDeductionAccountId(
    aACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aOriginDocumentId         ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aNegativeDeduction        boolean
  )
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    DeductionAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    OriginImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
  begin
    if aNegativeDeduction then
      select ACS_NEG_DEDUCTION_ID
        into DeductionAccountId
        from ACS_SUB_SET
           , ACS_ACCOUNT
       where ACS_ACCOUNT.ACS_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and ACS_SUB_SET.ACS_SUB_SET_ID = ACS_ACCOUNT.ACS_SUB_SET_ID;
    else
      select ACS_DEDUCTION_ACCOUNT_ID
        into DeductionAccountId
        from ACS_SUB_SET
           , ACS_ACCOUNT
       where ACS_ACCOUNT.ACS_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and ACS_SUB_SET.ACS_SUB_SET_ID = ACS_ACCOUNT.ACS_SUB_SET_ID;
    end if;

    if DeductionAccountId is null then
      OriginImputationId  := GetFinancialImputationId(aOriginDocumentId, DeductionAccountId);
    end if;

    if DeductionAccountId is null then
      raise_application_error(-20000, 'PCS - DEDUCTION AMOUNT - ACCOUNT UNDEFINED');
    end if;

    return DeductionAccountId;
  end GetDeductionAccountId;

  /**
  * Description
  *   Recherche du compte auxiliaire du partenaire
  *   (acustom = 1 -> pac_custom_partner, 0 -> pac_supplier_partner, null -> ?)
  **/
  function GetPartnerAuxAccount_id(aPAC_PARTNER_ID number, aCUSTOM number)
    return number
  is
    PartnerAuxAccount_id ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
  begin
    if    (aCUSTOM is null)
       or (aCUSTOM = 1) then
      select max(ACS_AUXILIARY_ACCOUNT_ID)
        into PartnerAuxAccount_id
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = aPAC_PARTNER_ID;
    end if;

    if    (aCUSTOM = 0)
       or (     (aCUSTOM is null)
           and (PartnerAuxAccount_id is null) ) then
      select max(ACS_AUXILIARY_ACCOUNT_ID)
        into PartnerAuxAccount_id
        from PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER_ID = aPAC_PARTNER_ID;
    end if;

    return PartnerAuxAccount_id;
  end GetPartnerAuxAccount_id;

  /**
  * Description
  *    Montant Restant à payer sur une échéance avec EXP_CALC_NET = 1 à une certaine date
  **/
  function GetAmountLeft(aACT_EXPIRY_ID number, aDATE date, aLC number)
    return number
  is
    Document_id       ACT_EXPIRY.ACT_DOCUMENT_ID%type;
    Slice             ACT_EXPIRY.EXP_SLICE%type;
    Status            ACT_EXPIRY.C_STATUS_EXPIRY%type;
    PartImputation_id ACT_EXPIRY.ACT_PART_IMPUTATION_ID%type;
    AmountToPay       ACT_EXPIRY.EXP_AMOUNT_LC%type;
    AmountToAdd       ACT_EXPIRY.EXP_AMOUNT_LC%type;
  begin
    select ACT_DOCUMENT_ID
         , EXP_SLICE
         , C_STATUS_EXPIRY
         , ACT_PART_IMPUTATION_ID
      into Document_id
         , Slice
         , Status
         , PartImputation_id
      from ACT_EXPIRY
     where ACT_EXPIRY_ID = aACT_EXPIRY_ID;

    if Status = 9 then
      begin
        if aLC = 1 then
          select sum(EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPayment(ACT_EXPIRY_ID, 1) )
            into AmountToPay
            from ACT_EXPIRY
           where ACT_EXPIRY_ID in(select ACT_EXPIRY_ID
                                    from ACT_REMINDER
                                   where ACT_DOCUMENT_ID = Document_id
                                     and ACT_PART_IMPUTATION_ID = PartImputation_id);

          --Recherche frais + intérêt
          select nvl(PAR_CHARGES_LC, 0) + nvl(PAR_INTEREST_LC, 0)
            into AmountToAdd
            from ACT_PART_IMPUTATION
           where ACT_PART_IMPUTATION_ID = PartImputation_id;

          AmountToPay  := AmountToPay + AmountToAdd;
        else
          select sum(EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPayment(ACT_EXPIRY_ID, 0) )
            into AmountToPay
            from ACT_EXPIRY
           where ACT_EXPIRY_ID in(select ACT_EXPIRY_ID
                                    from ACT_REMINDER
                                   where ACT_DOCUMENT_ID = Document_id
                                     and ACT_PART_IMPUTATION_ID = PartImputation_id);

          --Recherche frais + intérêt
          select nvl(PAR_CHARGES_FC, 0) + nvl(PAR_INTEREST_FC, 0)
            into AmountToAdd
            from ACT_PART_IMPUTATION
           where ACT_PART_IMPUTATION_ID = PartImputation_id;

          AmountToPay  := AmountToPay + AmountToAdd;
        end if;
      end;
    else
      begin
        if aLC = 1 then
          select max(EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPayment(aACT_EXPIRY_ID, 1) )
            into AmountToPay
            from ACT_EXPIRY
           where ACT_EXPIRY_ID = ACT_FUNCTIONS.GetExpiryIdOfToleranceDate(Document_id, Slice, aDate);
        else
          select max(EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPayment(aACT_EXPIRY_ID, 0) )
            into AmountToPay
            from ACT_EXPIRY
           where ACT_EXPIRY_ID = ACT_FUNCTIONS.GetExpiryIdOfToleranceDate(Document_id, Slice, aDate);
        end if;
      end;
    end if;

    return AmountToPay;
  end GetAmountLeft;

  procedure GetAmountLeftReminder(
    aACT_EXPIRY_ID      number
  , aLC                 number
  , aAmount         out number
  , aAmountOK       out integer
  , aAmountInterest out number
  , aAmountCharge   out number
  )
  is
    vAmountOK       boolean;
    vWithInterest   boolean;
    vWithCharge     boolean;
    vAmountCharges  ACT_PART_IMPUTATION.PAR_CHARGES_LC%type;
    vAmountInterest ACT_PART_IMPUTATION.PAR_INTEREST_LC%type;
  begin
    aAmount  := GetAmountLeftReminder(aACT_EXPIRY_ID, aLC, vAmountOK, vWithInterest, vWithCharge);

    if vAmountOK then
      aAmountOK  := 1;
    else
      aAmountOK  := 0;
    end if;

    if    vWithInterest
       or vWithCharge then
      if aLC = 1 then
        select nvl(PAR_CHARGES_LC, 0)
             , nvl(PAR_INTEREST_LC, 0)
          into vAmountCharges
             , vAmountInterest
          from ACT_PART_IMPUTATION PART
             , ACT_EXPIRY exp
         where PART.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and exp.ACT_EXPIRY_ID = aACT_EXPIRY_ID;
      else
        select nvl(PAR_CHARGES_FC, 0)
             , nvl(PAR_INTEREST_FC, 0)
          into vAmountCharges
             , vAmountInterest
          from ACT_PART_IMPUTATION PART
             , ACT_EXPIRY exp
         where PART.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and exp.ACT_EXPIRY_ID = aACT_EXPIRY_ID;
      end if;

      if vWithInterest then
        aAmountInterest  := vAmountInterest;
      else
        aAmountInterest  := 0;
      end if;

      if vWithCharge then
        aAmountCharge  := vAmountCharges;
      else
        aAmountCharge  := 0;
      end if;
    end if;
  end GetAmountLeftReminder;

  function GetAmountLeftReminder(
    aACT_EXPIRY_ID     number
  , aLC                number
  , aAmountOK      out boolean
  , aWithInterest  out boolean
  , aWithCharge    out boolean
  )
    return number
  is
    vAmountToPay       ACT_EXPIRY.EXP_AMOUNT_LC%type;
    vAmountCharges     ACT_PART_IMPUTATION.PAR_CHARGES_LC%type;
    vAmountInterest    ACT_PART_IMPUTATION.PAR_INTEREST_LC%type;
    vAmountClaims      ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    vClaimsCurr_id     ACT_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    vDocument_id       ACT_EXPIRY.ACT_DOCUMENT_ID%type;
    vPartImputation_id ACT_EXPIRY.ACT_PART_IMPUTATION_ID%type;
    vExpiryCurr_id     ACT_PART_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    vUpdateCharge      boolean;
    vUpdateInterest    boolean;
  begin
    select exp.ACT_DOCUMENT_ID
         , exp.ACT_PART_IMPUTATION_ID
         , PART.ACS_FINANCIAL_CURRENCY_ID
      into vDocument_id
         , vPartImputation_id
         , vExpiryCurr_id
      from ACT_PART_IMPUTATION PART
         , ACT_EXPIRY exp
     where exp.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and PART.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID;

    -- Recherche montant et monnaie de la relance
    select DOC_TOTAL_AMOUNT_DC
         , ACS_FINANCIAL_CURRENCY_ID
      into vAmountClaims
         , vClaimsCurr_id
      from ACT_DOCUMENT
     where ACT_DOCUMENT_ID = vDocument_id;

    vAmountCharges   := 0;
    vAmountInterest  := 0;

    if aLC = 1 then
      -- Recherche montant restant à payer sur l'ensemble des factures de la relance
      select sum(EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPayment(ACT_EXPIRY_ID, 1) )
        into vAmountToPay
        from ACT_EXPIRY
       where ACT_EXPIRY_ID in(select ACT_EXPIRY_ID
                                from ACT_REMINDER
                               where ACT_DOCUMENT_ID = vDocument_id
                                 and ACT_PART_IMPUTATION_ID = vPartImputation_id);

      if vExpiryCurr_id = vClaimsCurr_id then
        if vAmountToPay != vAmountClaims then
          --Recherche frais + intérêt
          select nvl(PAR_CHARGES_LC, 0)
               , nvl(PAR_INTEREST_LC, 0)
            into vAmountCharges
               , vAmountInterest
            from ACT_PART_IMPUTATION
           where ACT_PART_IMPUTATION_ID = vPartImputation_id;

          --Si on as des frais ou des interets on test si il faut en tenir compte
          if    vAmountCharges != 0
             or vAmountInterest != 0 then
            ACT_CLAIMS_MANAGEMENT.UpdateDocumentChargeOrInterest(vPartImputation_id, vUpdateCharge, vUpdateInterest);

            --Test des montants par rapport aux flags 'Màj montant document'
            if    vUpdateCharge
               or vUpdateInterest then
              if     (    vUpdateCharge
                      and vUpdateInterest)
                 and (vAmountCharges + vAmountInterest + vAmountToPay = vAmountClaims) then
                aWithInterest  := true;
                aWithCharge    := true;
              elsif     vUpdateCharge
                    and (vAmountCharges + vAmountToPay = vAmountClaims) then
                aWithCharge  := true;
              elsif     vUpdateInterest
                    and (vAmountInterest + vAmountToPay = vAmountClaims) then
                aWithInterest  := true;
              end if;
            end if;

            --Si on ne trouve rien (probablement une modification des flag après la génération des relances),
            -- on test seulement en fonction des montants
            if     not aWithInterest
               and not aWithCharge then
              if vAmountCharges + vAmountInterest + vAmountToPay = vAmountClaims then
                aWithInterest  := true;
                aWithCharge    := true;
              elsif vAmountCharges + vAmountToPay = vAmountClaims then
                aWithCharge  := true;
              elsif vAmountInterest + vAmountToPay = vAmountClaims then
                aWithInterest  := true;
              end if;
            end if;
          end if;
        end if;
      end if;
    else
      select sum(EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPayment(ACT_EXPIRY_ID, 0) )
        into vAmountToPay
        from ACT_EXPIRY
       where ACT_EXPIRY_ID in(select ACT_EXPIRY_ID
                                from ACT_REMINDER
                               where ACT_DOCUMENT_ID = vDocument_id
                                 and ACT_PART_IMPUTATION_ID = vPartImputation_id);

      if vExpiryCurr_id = vClaimsCurr_id then
        if vAmountToPay != vAmountClaims then
          --Recherche frais + intérêt
          select nvl(PAR_CHARGES_FC, 0)
               , nvl(PAR_INTEREST_FC, 0)
            into vAmountCharges
               , vAmountInterest
            from ACT_PART_IMPUTATION
           where ACT_PART_IMPUTATION_ID = vPartImputation_id;

          --Si on as des frais ou des interets on test si il faut en tenir compte
          if    vAmountCharges != 0
             or vAmountInterest != 0 then
            ACT_CLAIMS_MANAGEMENT.UpdateDocumentChargeOrInterest(vPartImputation_id, vUpdateCharge, vUpdateInterest);

            --Test des montants par rapport aux flags 'Màj montant document'
            if    vUpdateCharge
               or vUpdateInterest then
              if     (    vUpdateCharge
                      and vUpdateInterest)
                 and (vAmountCharges + vAmountInterest + vAmountToPay = vAmountClaims) then
                aWithInterest  := true;
                aWithCharge    := true;
              elsif     vUpdateCharge
                    and (vAmountCharges + vAmountToPay = vAmountClaims) then
                aWithCharge  := true;
              elsif     vUpdateInterest
                    and (vAmountInterest + vAmountToPay = vAmountClaims) then
                aWithInterest  := true;
              end if;
            end if;

            --Si on ne trouve rien (probablement une modification des flag après la génération des relances),
            -- on test seulement en fonction des montants
            if     not aWithInterest
               and not aWithCharge then
              if vAmountCharges + vAmountInterest + vAmountToPay = vAmountClaims then
                aWithInterest  := true;
                aWithCharge    := true;
              elsif vAmountCharges + vAmountToPay = vAmountClaims then
                aWithCharge  := true;
              elsif vAmountInterest + vAmountToPay = vAmountClaims then
                aWithInterest  := true;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;

    if aWithInterest then
      vAmountToPay  := vAmountToPay + vAmountInterest;
    end if;

    if aWithCharge then
      vAmountToPay  := vAmountToPay + vAmountCharges;
    end if;

    aAmountOK        := vAmountToPay = vAmountClaims;
    return vAmountToPay;
  end GetAmountLeftReminder;

---------------------------------------------------------------------------------------------------------------------
  function GetFinAccount_id(
    aACS_AUXILIARY_ACCOUNT_ID number
  , aACT_DOCUMENT_ID          number
  , aACT_PART_IMPUTATION_ID   number default null
  )
    return number   --Document facture
  is
    FinAccount_id ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    --Recherche avec part_imputation pour le cas de documents avec plusieurs échéances sur le même partenaire mais avec des comptes
    -- collectifs différent
    if aACT_PART_IMPUTATION_ID is not null then
      select min(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID)
        into FinAccount_id
        from ACS_FINANCIAL_ACCOUNT
           , ACT_FINANCIAL_IMPUTATION
       where ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
         and ACS_FINANCIAL_ACCOUNT.FIN_COLLECTIVE = 1
         and ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null;

      if FinAccount_id is null then
        select min(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID)
          into FinAccount_id
          from ACS_FINANCIAL_ACCOUNT
             , ACT_FINANCIAL_IMPUTATION
         where ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
           and ACS_FINANCIAL_ACCOUNT.FIN_COLLECTIVE = 1
           and ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null;
      end if;

      if FinAccount_id is null then
        select min(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID)
          into FinAccount_id
          from ACS_FINANCIAL_ACCOUNT
             , ACT_FINANCIAL_IMPUTATION
             , ACT_DOCUMENT
             , ACJ_CATALOGUE_DOCUMENT
         where ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
           and ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
           and ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null
           and ACT_DOCUMENT.ACT_DOCUMENT_ID = ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID
           and ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
           and (    (    ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE in('2', '5', '6')
                     and ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY = 1
                    )
                or (    ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE not in('2', '5', '6')
                    and ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY = 0
                   )
               )
           and ACT_FINANCIAL_IMPUTATION.C_GENRE_TRANSACTION = '1';
      end if;
    end if;

    --Recherche ancienne méthode seulement avec le doc et le compte aux.
    if FinAccount_id is null then
      select min(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID)
        into FinAccount_id
        from ACS_FINANCIAL_ACCOUNT
           , ACT_FINANCIAL_IMPUTATION
       where ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
         and ACS_FINANCIAL_ACCOUNT.FIN_COLLECTIVE = 1
         and ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null;
    end if;

    if FinAccount_id is null then
      select min(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID)
        into FinAccount_id
        from ACS_FINANCIAL_ACCOUNT
           , ACT_FINANCIAL_IMPUTATION
       where ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
         and ACS_FINANCIAL_ACCOUNT.FIN_COLLECTIVE = 1
         and ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null;
    end if;

    if FinAccount_id is null then
      select min(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID)
        into FinAccount_id
        from ACS_FINANCIAL_ACCOUNT
           , ACT_FINANCIAL_IMPUTATION
           , ACT_DOCUMENT
           , ACJ_CATALOGUE_DOCUMENT
       where ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
         and ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null
         and ACT_DOCUMENT.ACT_DOCUMENT_ID = ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID
         and ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
         and (    (    ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE in('2', '5', '6')
                   and ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY = 1
                  )
              or (    ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE not in('2', '5', '6')
                  and ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY = 0
                 )
             )
         and ACT_FINANCIAL_IMPUTATION.C_GENRE_TRANSACTION = '1';
    end if;

    return FinAccount_id;
  end GetFinAccount_id;

  function GetDivAccount_id(aACS_AUXILIARY_ACCOUNT_ID number, aACT_DOCUMENT_ID number)
    return number   --Document facture
  is
    DivAccount_id ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
  begin
    select min(ACT_FINANCIAL_IMPUTATION.IMF_ACS_DIVISION_ACCOUNT_ID)
      into DivAccount_id
      from ACS_FINANCIAL_ACCOUNT
         , ACT_FINANCIAL_IMPUTATION
     where ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
       and ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
       and ACS_FINANCIAL_ACCOUNT.FIN_COLLECTIVE = 1
       and ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
       and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null;

    if DivAccount_id is null then
      select min(ACT_FINANCIAL_IMPUTATION.IMF_ACS_DIVISION_ACCOUNT_ID)
        into DivAccount_id
        from ACS_FINANCIAL_ACCOUNT
           , ACT_FINANCIAL_IMPUTATION
       where ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
         and ACS_FINANCIAL_ACCOUNT.FIN_COLLECTIVE = 1
         and ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null;
    end if;

    if DivAccount_id is null then
      select min(ACT_FINANCIAL_IMPUTATION.IMF_ACS_DIVISION_ACCOUNT_ID)
        into DivAccount_id
        from ACS_FINANCIAL_ACCOUNT
           , ACT_FINANCIAL_IMPUTATION
           , ACT_DOCUMENT
           , ACJ_CATALOGUE_DOCUMENT
       where ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
         and ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
         and ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null
         and ACT_DOCUMENT.ACT_DOCUMENT_ID = ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID
         and ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
         and (    (    ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE in('2', '5', '6')
                   and ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY = 1
                  )
              or (    ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE not in('2', '5', '6')
                  and ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY = 0
                 )
             )
         and ACT_FINANCIAL_IMPUTATION.C_GENRE_TRANSACTION = '1';
    end if;

    return DivAccount_id;
  end GetDivAccount_id;

---------------------------------------------------------------------------------------------------------------------
  function IsBVRPayBack(aACS_FIN_ACC_S_PAYMENT_ID number)
    return number
  is
    PayBack ACS_PAYMENT_METHOD.PME_BVR_PAYBACK%type;
  begin
    select max(ACS_PAYMENT_METHOD.PME_BVR_PAYBACK)
      into PayBack
      from ACS_FIN_ACC_S_PAYMENT
         , ACS_PAYMENT_METHOD
     where ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID = aACS_FIN_ACC_S_PAYMENT_ID
       and ACS_FIN_ACC_S_PAYMENT.ACS_PAYMENT_METHOD_ID = ACS_PAYMENT_METHOD.ACS_PAYMENT_METHOD_ID;

    return PayBack;
  end IsBVRPayBack;

---------------------------------------------------------------------------------------------------------------------
  function GetAmountCharge(aACT_DOCUMENT_ID number)
    return number
  is
    DocCharge ACT_DOCUMENT.DOC_CHARGES_LC%type;
  begin
    select max(ACT_DOCUMENT.DOC_CHARGES_LC)
      into DocCharge
      from ACT_DOCUMENT
     where ACT_DOCUMENT.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    if DocCharge is null then
      DocCharge  := 0;
    end if;

    return DocCharge;
  end GetAmountCharge;

---------------------------------------------------------------------------------------------------------------------
  function IsDeductionPossible(aPAC_PARTNER_ID number, flAmountTot number, flAmountPayed number)
    return number
  is
    flDeduction ACT_DET_PAYMENT.DET_DEDUCTION_LC%type;
    flMaxAmount acs_sub_set.SSE_MAX_AMOUNT%type;
    flPercent   acs_sub_set.SSE_PERCENT_OK%type;
    result      number;
  begin
    select nvl(acs_sub_set.SSE_PERCENT_OK, 0)
         , nvl(acs_sub_set.SSE_MAX_AMOUNT, 0)
      into flPercent
         , flMaxAmount
      from acs_sub_set
         , pac_custom_partner
         , acs_account
     where pac_custom_partner.pac_custom_partner_id = aPAC_PARTNER_ID
       and pac_custom_partner.acs_auxiliary_account_id = acs_account.acs_account_id
       and acs_sub_set.acs_sub_set_id = acs_account.acs_sub_set_id;

    result       := 0;
    flDeduction  := abs(flAmountTot - flAmountPayed);

    if     (flMaxAmount = 0)
       and (flPercent = 0) then
      result  := 1;
    elsif(flMaxAmount = 0) then
      if abs( (flAmountTot * flPercent / 100) ) >= flDeduction then
        result  := 1;
      end if;
    elsif(flMaxAmount >= flDeduction) then
      if abs( (flAmountTot * flPercent / 100) ) >= flDeduction then
        result  := 1;
      end if;
    end if;

    return result;
  end IsDeductionPossible;

---------------------------------------------------------------------------------------------------------------------
  function MaxDeductionPossible(aPAC_CUSTOM_PARTNER_ID number, aPAC_SUPPLIER_PARTNER_ID number, flAmountTot number)
    return acs_sub_set.SSE_MAX_AMOUNT%type
  is
    flDeduction ACT_DET_PAYMENT.DET_DEDUCTION_LC%type;
    flMaxAmount acs_sub_set.SSE_MAX_AMOUNT%type;
    flPercent   acs_sub_set.SSE_PERCENT_OK%type;
    result      acs_sub_set.SSE_MAX_AMOUNT%type;
  begin
    if nvl(aPAC_CUSTOM_PARTNER_ID, 0) != 0 then
      select nvl(acs_sub_set.SSE_PERCENT_OK, 0)
           , nvl(acs_sub_set.SSE_MAX_AMOUNT, 0)
        into flPercent
           , flMaxAmount
        from acs_sub_set
           , pac_custom_partner
           , acs_account
       where pac_custom_partner.pac_custom_partner_id = aPAC_CUSTOM_PARTNER_ID
         and pac_custom_partner.acs_auxiliary_account_id = acs_account.acs_account_id
         and acs_sub_set.acs_sub_set_id = acs_account.acs_sub_set_id;
    else
      select nvl(acs_sub_set.SSE_PERCENT_OK, 0)
           , nvl(acs_sub_set.SSE_MAX_AMOUNT, 0)
        into flPercent
           , flMaxAmount
        from acs_sub_set
           , pac_supplier_partner
           , acs_account
       where pac_supplier_partner.pac_supplier_partner_id = aPAC_SUPPLIER_PARTNER_ID
         and pac_supplier_partner.acs_auxiliary_account_id = acs_account.acs_account_id
         and acs_sub_set.acs_sub_set_id = acs_account.acs_sub_set_id;
    end if;

    if     (flMaxAmount = 0)
       and (flPercent = 0) then
      return flAmountTot;
    elsif flPercent != 0 then
      result  :=(flAmountTot * flPercent / 100);
    end if;

    if    (flMaxAmount = 0)
       or (flMaxAmount > result) then
      return result;
    else
      return flMaxAmount;
    end if;
  end MaxDeductionPossible;

---------------------------------------------------------------------------------------------------------------------
  procedure CREATE_FIN_DISTRI_BVR(
    aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aDescription                 varchar2
  , aFIN_AMOUNT_LC_D             ACT_FINANCIAL_DISTRIBUTION.FIN_AMOUNT_LC_D%type
  , aFIN_AMOUNT_LC_C             ACT_FINANCIAL_DISTRIBUTION.FIN_AMOUNT_LC_C%type
  , aFIN_AMOUNT_FC_D             ACT_FINANCIAL_DISTRIBUTION.FIN_AMOUNT_FC_C%type
  , aFIN_AMOUNT_FC_C             ACT_FINANCIAL_DISTRIBUTION.FIN_AMOUNT_FC_C%type
  , aFIN_AMOUNT_EUR_D            ACT_FINANCIAL_DISTRIBUTION.FIN_AMOUNT_EUR_C%type
  , aFIN_AMOUNT_EUR_C            ACT_FINANCIAL_DISTRIBUTION.FIN_AMOUNT_EUR_C%type
  , aACS_FINANCIAL_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACT_DOCUMENT_ID2            ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  ,   --Doc facture
    aA_IDCRE                     ACT_FINANCIAL_DISTRIBUTION.A_IDCRE%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , IsPay                        number
  , aACS_DIVISION_ACCOUNT_ID     ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type default null
  )
  is
    DivisionAccountId ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    SubSetId          ACS_SUB_SET.ACS_SUB_SET_ID%type;
    FinColl           ACS_FINANCIAL_ACCOUNT.FIN_COLLECTIVE%type;
    Imputation_id     ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
  -----
  begin
    if ExistDIVI = 1 then
      FinColl  := 0;

      if aACS_DIVISION_ACCOUNT_ID is null then
        if IsPay = 1 then   -- Paiement
          --Recherche si compte est collectif
          select min(FIN.FIN_COLLECTIVE)
            into FinColl
            from ACS_FINANCIAL_ACCOUNT FIN
           where FIN.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

          if FinColl is null then
            FinColl  := 0;
          end if;

          if FinColl = 1 then
            select min(ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID)
              into Imputation_id
              from ACS_FINANCIAL_ACCOUNT
                 , ACT_FINANCIAL_IMPUTATION
             where ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
               and ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
               and ACS_FINANCIAL_ACCOUNT.FIN_COLLECTIVE = 1
               and ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID2
               and ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID is null;

            select min(IMF_ACS_DIVISION_ACCOUNT_ID)
              into DivisionAccountId
              from ACT_FINANCIAL_IMPUTATION
             where ACT_FINANCIAL_IMPUTATION_ID = Imputation_id;
          else
            select min(IMP.IMF_ACS_DIVISION_ACCOUNT_ID)
              into DivisionAccountId
              from ACS_FINANCIAL_ACCOUNT FIN
                 , ACT_FINANCIAL_IMPUTATION IMP
             where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID2
               and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and FIN.FIN_COLLECTIVE = 0
               and IMP.IMF_TYPE <> 'VAT';
          end if;
        end if;

        if    (FinColl = 0)
           or (DivisionAccountId is null) then
          DivisionAccountId  :=
            ACS_FUNCTION.GetDivisionOfAccount(aACS_FINANCIAL_ACCOUNT_ID
                                            , DivisionAccountId
                                            , aIMF_TRANSACTION_DATE
                                            , PCS.PC_I_LIB_SESSION.GETUSERID
                                            , 1
                                             );
        end if;
      else
        DivisionAccountId  := aACS_DIVISION_ACCOUNT_ID;
      end if;

      if DivisionAccountId is null then
        raise_application_error(-20000, 'PCS - ACS_DIVISION_ACCOUNT_ID not found');
      end if;

      select ACS_SUB_SET_ID
        into SubSetId
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = DivisionAccountId;

      insert into ACT_FINANCIAL_DISTRIBUTION
                  (ACT_FINANCIAL_DISTRIBUTION_ID
                 , ACT_FINANCIAL_IMPUTATION_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , FIN_AMOUNT_LC_D
                 , FIN_AMOUNT_LC_C
                 , FIN_AMOUNT_FC_D
                 , FIN_AMOUNT_FC_C
                 , FIN_AMOUNT_EUR_D
                 , FIN_AMOUNT_EUR_C
                 , ACS_SUB_SET_ID
                 , A_DATECRE
                 , A_IDCRE
                 , FIN_DESCRIPTION
                  )
           values (init_id_seq.nextval
                 , aACT_FINANCIAL_IMPUTATION_ID
                 , DivisionAccountId
                 , aFIN_AMOUNT_LC_D
                 , aFIN_AMOUNT_LC_C
                 , aFIN_AMOUNT_FC_D
                 , aFIN_AMOUNT_FC_C
                 , aFIN_AMOUNT_EUR_D
                 , aFIN_AMOUNT_EUR_C
                 , SubSetId
                 , trunc(sysdate)
                 , aA_IDCRE
                 , aDescription
                  );
    end if;
  end CREATE_FIN_DISTRI_BVR;

---------------------------------------------------------------------------------------------------------------------
  function ExistDIVI
    return number
  is
  begin
    return ACS_FUNCTION.ExistDivi;
  end ExistDIVI;

---------------------------------------------------------------------------------------------------------------------
  function GetParDocDoubleBlocked(aACS_FIN_ACC_S_PAYMENT_ID number)
    return number
  is
    ParDocBlocked ACS_FIN_ACC_S_PAYMENT.PMM_DOUBLE_BLOCKED%type;
  begin
    select nvl(max(PMM_DOUBLE_BLOCKED), 0)
      into ParDocBlocked
      from ACS_FIN_ACC_S_PAYMENT
     where ACS_FIN_ACC_S_PAYMENT_ID = aACS_FIN_ACC_S_PAYMENT_ID;

    return ParDocBlocked;
  end GetParDocDoubleBlocked;

---------------------------------------------------------------------------------------------------------------------
  function GetPeriodTypeOfCat(aACJ_CATALOGUE_DOCUMENT_ID number)
    return varchar2
  is
    CTypePeriod ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type;
  begin
    select C_TYPE_PERIOD
      into CTypePeriod
      from ACJ_CATALOGUE_DOCUMENT
     where ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID;

    return CTypePeriod;
  end GetPeriodTypeOfCat;

---------------------------------------------------------------------------------------------------------------------
  function IsFinAccCollective(aACS_FINANCIAL_ACCOUNT_ID number)
    return number
  is
    result number;
  begin
    select FIN_COLLECTIVE
      into result
      from ACS_FINANCIAL_ACCOUNT
     where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    if result is null then
      result  := 0;
    end if;

    return result;
  end IsFinAccCollective;

  /**
  * Description
  *    Montant à payer sur une échéance avec EXP_CALC_NET = 1
  **/
  function GetAmount(aACT_EXPIRY_ID number, aLC number)
    return number
  is
    AmountToPay ACT_EXPIRY.EXP_AMOUNT_LC%type;
  begin
    if aLC = 1 then
      select max(EXP_AMOUNT_LC)
        into AmountToPay
        from ACT_EXPIRY
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and EXP_CALC_NET + 0 = 1;
    else
      select max(EXP_AMOUNT_FC)
        into AmountToPay
        from ACT_EXPIRY
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and EXP_CALC_NET + 0 = 1;
    end if;

    return AmountToPay;
  end GetAmount;

---------------------------------------------------------------------------------------------------------------------
  function IsExpiryInReminder(aACT_EXPIRY_ID number)
    return number
  is
    result number;
  begin
    select min(ACT_REMINDER_ID)
      into result
      from ACT_REMINDER
     where ACT_EXPIRY_ID = aACT_EXPIRY_ID;

    if result is null then
      result  := 0;
    end if;

    return result;
  end IsExpiryInReminder;

---------------------------------------------------------------------------------------------------------------------
  procedure CloseTransactionSBVR(aACT_ETAT_EVENT_ID number)
  is
/*
    cursor EtatJournal(Job_id number) is
      select ACT_JOURNAL.ACT_JOURNAL_ID
      from ACT_JOURNAL
      where ACT_JOURNAL.ACT_JOB_ID = Job_id;
   EtatJournal_tuple EtatJournal%ROWTYPE;

   JobId ACT_JOB.ACT_JOB_ID%Type;
*/
  begin
/*
    select act_etat_event.act_job_id into JobId
    from act_etat_event
    where act_etat_event.act_etat_event_id = aACT_ETAT_EVENT_ID;

    --Mise à jour des états.
    update ACT_DOCUMENT
    set C_STATUS_DOCUMENT = 'DEF'
    where ACT_DOCUMENT_ID in (select ACT_DOCUMENT_ID FROM ACT_EXPIRY_SELECTION
                              where ACT_ETAT_EVENT_ID = aACT_ETAT_EVENT_ID);
    update ACT_JOB
    set C_JOB_STATE = 'TERM'
    where ACT_JOB_ID = JobId;

    open EtatJournal(JobId);
    fetch EtatJournal into EtatJournal_tuple;
    while EtatJournal%found loop
      update ACT_ETAT_JOURNAL
      set C_ETAT_JOURNAL = 'PROV'
      where ACT_JOURNAL_ID = EtatJournal_tuple.ACT_JOURNAL_ID;

      fetch EtatJournal into EtatJournal_tuple;
    end loop;
    close EtatJournal;
*/  --Effacement des record SBVR
    delete from act_expiry_selection
          where act_etat_event_id = aACT_ETAT_EVENT_ID;
  end CloseTransactionSBVR;

---------------------------------------------------------------------------------------------------------------------
  procedure CalcVatOnDeduction(aACT_EXPIRY_ID in number, aACT_DOCUMENT_ID in number)
  is
    cursor PartOfExpiry(aACT_EXPIRY_ID number)
    is
      select   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D
             , ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C
             , ACT_FINANCIAL_IMPUTATION.ACS_TAX_CODE_ID
             , TAX_INCLUDED_EXCLUDED
             , TAX_VAT_AMOUNT_LC
             , TAX_RATE
             , ACT_ACT_FINANCIAL_IMPUTATION
             , ACT_FINANCIAL_IMPUTATION2.ACS_FINANCIAL_ACCOUNT_ID
             , nvl(ACT_FINANCIAL_IMPUTATION2.IMF_EXCHANGE_RATE, TAX_EXCHANGE_RATE) TAX_EXCHANGE_RATE
             , nvl(ACT_FINANCIAL_IMPUTATION2.IMF_BASE_PRICE, DET_BASE_PRICE) DET_BASE_PRICE
             , ACT_DET_TAX.TAX_TMP_VAT_ENCASHMENT
          from ACT_EXPIRY
             , ACT_DET_TAX
             , ACS_ACCOUNT
             , ACT_FINANCIAL_IMPUTATION
             , ACT_FINANCIAL_IMPUTATION ACT_FINANCIAL_IMPUTATION2
         where ACT_DET_TAX.ACT_FINANCIAL_IMPUTATION_ID(+) = ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
           and ACT_FINANCIAL_IMPUTATION2.ACT_FINANCIAL_IMPUTATION_ID(+) = ACT_DET_TAX.ACT_ACT_FINANCIAL_IMPUTATION
           and ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID = ACT_EXPIRY.ACT_DOCUMENT_ID
           and ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY + 0 = 0
           and ACT_FINANCIAL_IMPUTATION.IMF_TYPE = 'MAN'
           and ACT_DET_TAX.ACT2_DET_TAX_ID is null
           and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACT_FINANCIAL_IMPUTATION.ACS_TAX_CODE_ID
           and ACS_ACCOUNT.ACC_INTEREST = 0
           and ACT_EXPIRY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
           and not exists(
                 select 0
                   from ACT_DET_TAX TAX2
                  where TAX2.ACT_DED1_FINANCIAL_IMP_ID = ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
                     or TAX2.ACT_DED2_FINANCIAL_IMP_ID = ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID)
      order by ACT_FINANCIAL_IMPUTATION.ACS_TAX_CODE_ID
             , ACT_DET_TAX.TAX_RATE
             , ACT_FINANCIAL_IMPUTATION2.ACS_FINANCIAL_ACCOUNT_ID;

    PartOfExpiry_tuple       PartOfExpiry%rowtype;

    type tblSoumisTyp is table of ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
      index by binary_integer;

    tblSoumis                tblSoumisTyp;
    TotSoumis                ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    VatAccountId             ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    Soumis                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    TotProp                  ACS_TAX_CODE.TAX_RATE%type;
    n                        binary_integer;
    BaseInfoRec              ACT_VAT_MANAGEMENT.BaseInfoRecType;
    InfoVATRec               ACT_VAT_MANAGEMENT.InfoVATRecType;
    UseEncash                boolean                                               := false;
    SameAccount              boolean                                               := false;
    ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    vEncashment              ACT_DET_TAX.TAX_TMP_VAT_ENCASHMENT%type;
  begin
    TotSoumis  := 0;

    --pour toutes les positions factures, mise à jour de la table PL/SQL
    open PartOfExpiry(aACT_EXPIRY_ID);

    fetch PartOfExpiry
     into PartOfExpiry_tuple;

    if PartOfExpiry%found then
      UseEncash  := upper(PCS.PC_CONFIG.GetConfig('ACT_TAX_VAT_ENCASHMENT') ) = 'TRUE';
    end if;

    while PartOfExpiry%found loop
      if PartOfExpiry_tuple.IMF_AMOUNT_LC_D <> 0 then
        if PartOfExpiry_tuple.TAX_INCLUDED_EXCLUDED = 'I' then
          Soumis  := PartOfExpiry_tuple.IMF_AMOUNT_LC_D;
        else
          Soumis  := PartOfExpiry_tuple.IMF_AMOUNT_LC_D + nvl(PartOfExpiry_tuple.TAX_VAT_AMOUNT_LC, 0);
        end if;
      else
        if PartOfExpiry_tuple.TAX_INCLUDED_EXCLUDED = 'I' then
          Soumis  := PartOfExpiry_tuple.IMF_AMOUNT_LC_C;
        else
          Soumis  := PartOfExpiry_tuple.IMF_AMOUNT_LC_C - nvl(PartOfExpiry_tuple.TAX_VAT_AMOUNT_LC, 0);
        end if;
      end if;

      TotSoumis  := TotSoumis + Soumis;

      --On ne remplit les tables que pour les écritures soumises
      if PartOfExpiry_tuple.ACS_TAX_CODE_ID is not null then
        if    (tblCalcVat.count = 0)
           or (PartOfExpiry_tuple.ACS_TAX_CODE_ID != tblCalcVat(tblCalcVat.last).ACS_TAX_CODE_ID)
           or (PartOfExpiry_tuple.TAX_RATE != tblCalcVat(tblCalcVat.last).TAX_RATE) then
          ACS_FINANCIAL_ACCOUNT_ID  := PartOfExpiry_tuple.ACS_FINANCIAL_ACCOUNT_ID;
          vEncashment               := 0;

          --Si on se trouve dans le cas d'un paiement sur tva provisoire, si paiement avec couverture
          -- pour décharge portefeuille -> utilisation du compte de prov. sinon utilisation du compte
          -- de récupération.
          if     UseEncash
             and (PartOfExpiry_tuple.TAX_TMP_VAT_ENCASHMENT = 1) then
            if ACT_VAT_MANAGEMENT.DelayedEncashmentVAT(aACT_DOCUMENT_ID) = 1 then
              vEncashment  := 1;
            else
              BaseInfoRec.TaxCodeId  := PartOfExpiry_tuple.ACS_TAX_CODE_ID;

              if ACT_VAT_MANAGEMENT.GetInfoVAT(BaseInfoRec, InfoVATRec) then
                if InfoVATRec.EtabCalcSheet = '2' then
                  ACS_FINANCIAL_ACCOUNT_ID  := InfoVATRec.PreaAccId;
                end if;
              end if;
            end if;
          end if;
        end if;

        if tblCalcVat.count > 0 then
          SameAccount  :=
                (nvl(ACS_FINANCIAL_ACCOUNT_ID, 0) = nvl(tblCalcVat(tblCalcVat.last).ACS_FINANCIAL_ACCOUNT_ID, 0)
                )
            and (PartOfExpiry_tuple.ACS_TAX_CODE_ID = tblCalcVat(tblCalcVat.last).ACS_TAX_CODE_ID)
            and (PartOfExpiry_tuple.TAX_RATE = tblCalcVat(tblCalcVat.last).TAX_RATE);
        end if;

        if SameAccount then
          tblSoumis(tblSoumis.last)  := tblSoumis(tblSoumis.last) + Soumis;
        else
          n                                       := nvl(tblCalcVat.last, 0) + 1;
          tblSoumis(n)                            := Soumis;
          tblCalcVat(n).ACS_TAX_CODE_ID           := PartOfExpiry_tuple.ACS_TAX_CODE_ID;
          tblCalcVat(n).TAX_RATE                  := PartOfExpiry_tuple.TAX_RATE;
          tblCalcVat(n).ACS_FINANCIAL_ACCOUNT_ID  := ACS_FINANCIAL_ACCOUNT_ID;
          tblCalcVat(n).TAX_EXCHANGE_RATE         := PartOfExpiry_tuple.TAX_EXCHANGE_RATE;
          tblCalcVat(n).DET_BASE_PRICE            := PartOfExpiry_tuple.DET_BASE_PRICE;
          tblCalcVat(n).TAX_TMP_VAT_ENCASHMENT    := vEncashment;
        end if;
      end if;

      fetch PartOfExpiry
       into PartOfExpiry_tuple;
    end loop;

    close PartOfExpiry;

    --CALCUL DE LA TABLE DES PROPORTIONS
    if tblCalcVat.count > 0 then
      TotProp  := 0;

      for i in 1 .. tblCalcVat.count loop
        --total des proportions déjà calculées
        tblCalcVat(i).PROPORTION  := tblSoumis(i) * 100 / TotSoumis;
        TotProp                   := TotProp + tblCalcVat(i).PROPORTION;
      end loop;

      if TotProp <> 100 then
        --Ecritures non soumises = reste
        n                                       := nvl(tblCalcVat.last, 0) + 1;
        tblCalcVat(n).PROPORTION                := 100 - TotProp;
        tblCalcVat(n).ACS_TAX_CODE_ID           := 0;
        tblCalcVat(n).TAX_RATE                  := 0;
        tblCalcVat(n).ACS_FINANCIAL_ACCOUNT_ID  := 0;
        tblCalcVat(n).TAX_EXCHANGE_RATE         := 0;
        tblCalcVat(n).DET_BASE_PRICE            := 0;
        tblCalcVat(n).TAX_TMP_VAT_ENCASHMENT    := 0;
      end if;
    else
      --Ecritures non soumises = reste
      n                                       := nvl(tblCalcVat.last, 0) + 1;
      tblCalcVat(n).PROPORTION                := 100;
      tblCalcVat(n).ACS_TAX_CODE_ID           := 0;
      tblCalcVat(n).TAX_RATE                  := 0;
      tblCalcVat(n).ACS_FINANCIAL_ACCOUNT_ID  := 0;
      tblCalcVat(n).TAX_EXCHANGE_RATE         := 0;
      tblCalcVat(n).DET_BASE_PRICE            := 0;
      tblCalcVat(n).TAX_TMP_VAT_ENCASHMENT    := 0;
    end if;
  end CalcVatOnDeduction;

---------------------------------------------------------------------------------------------------------------------
  function GetCPNAccountIdOfFIN(aACS_FINANCIAL_ACCOUNT_ID number)
    return number
  is
    result number;
  begin
    select ACS_CPN_ACCOUNT_ID
      into result
      from ACS_FINANCIAL_ACCOUNT
     where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    if result is null then
      result  := 0;
    end if;

    return result;
  end GetCPNAccountIdOfFIN;

---------------------------------------------------------------------------------------------------------------------
  function GetQTYAccountIdOfCPN(aACS_CPN_ACCOUNT_ID number)
    return number
  is
    result number;
  begin
    select max(ACS_QTY_UNIT_ID)
      into result
      from ACS_QTY_S_CPN_ACOUNT
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID;

/*
    if Result is null then
      Result := 0;
    end if;
*/
    return result;
  end GetQTYAccountIdOfCPN;

  /**
  * Description
  *    Création des imputations pour extourne TVA et enregistrement TVA dans ACT_DET_TAX.
  **/
  procedure CREATE_VAT_SBVR(
    aACT_FINANCIAL_IMPUTATION_ID        number
  , aACS_TAX_CODE_ID                    number
  , aTAX_RATE                           number
  , aACS_FINANCIAL_ACCOUNT_ID           number
  , aPROPORTION                         number
  , aDescription                        varchar2
  , aNumDoc                             varchar2
  , aACT_DOCUMENT_ID2                   number
  ,   --Pour division
    aACS_AUXILIARY_ACCOUNT_ID           number
  ,   --     "
    aA_IDCRE                            ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aBaseInfoRec                 in out ACT_VAT_MANAGEMENT.BaseInfoRecType
  , aInfoVATRec                  in     ACT_VAT_MANAGEMENT.InfoVATRecType
  , aCalcVATRec                  in     ACT_VAT_MANAGEMENT.CalcVATRecType
  )
  is
    FinImputation_id  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    FinImputation_id2 ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    DetTax_id         ACT_DET_TAX.ACT_DET_TAX_ID%type;
    Amount_LC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    Amount_LC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    Amount_FC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    Amount_FC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    Amount_EUR_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    Amount_EUR_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vDivisionId       ACT_FINANCIAL_DISTRIBUTION.ACS_DIVISION_ACCOUNT_ID%type;
  begin
    -- si pas auto-taxation
    if aCalcVATRec.IE != 'S' then
      if     (    aACS_FINANCIAL_ACCOUNT_ID <> 0
              and aACS_FINANCIAL_ACCOUNT_ID is not null)
         and (aCalcVATRec.Amount_LC <> 0) then
        Amount_LC_D   := 0;
        Amount_FC_D   := 0;
        Amount_EUR_D  := 0;
        Amount_LC_C   := 0;
        Amount_FC_C   := 0;
        Amount_EUR_C  := 0;

        if aCalcVATRec.IE = 'I' then
          if aCalcVATRec.Amount_LC > 0 then
            Amount_LC_D   := aCalcVATRec.Amount_LC;
            Amount_FC_D   := aCalcVATRec.Amount_FC;
            Amount_EUR_D  := aCalcVATRec.Amount_EUR;
          else
            Amount_LC_C   := aCalcVATRec.Amount_LC * -1;
            Amount_FC_C   := aCalcVATRec.Amount_FC * -1;
            Amount_EUR_C  := aCalcVATRec.Amount_EUR * -1;
          end if;
        else
          if IsImputationOnDebit(aACT_FINANCIAL_IMPUTATION_ID) then
            Amount_LC_D   := aCalcVATRec.Amount_LC;
            Amount_FC_D   := aCalcVATRec.Amount_FC;
            Amount_EUR_D  := aCalcVATRec.Amount_EUR;
          else
            Amount_LC_C   := aCalcVATRec.Amount_LC * -1;
            Amount_FC_C   := aCalcVATRec.Amount_FC * -1;
            Amount_EUR_C  := aCalcVATRec.Amount_EUR * -1;
          end if;
        end if;

        select init_id_seq.nextval
          into FinImputation_id
          from dual;

        insert into ACT_FINANCIAL_IMPUTATION
                    (ACT_FINANCIAL_IMPUTATION_ID
                   , ACS_PERIOD_ID
                   , ACT_DOCUMENT_ID
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
                   , ACT_DET_PAYMENT_ID
                   , IMF_GENRE
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , C_GENRE_TRANSACTION
                   , IMF_NUMBER
                   , A_DATECRE
                   , A_IDCRE
                   , ACT_PART_IMPUTATION_ID
                    )
             values (FinImputation_id
                   , aBaseInfoRec.PeriodId
                   , aBaseInfoRec.DocumentId
                   , aACS_FINANCIAL_ACCOUNT_ID
                   , 'VAT'
                   , 0
                   , aDescription
                   , Amount_LC_D
                   , Amount_LC_C
                   , nvl(aCalcVATRec.ExchangeRate, 0)
                   , nvl(aCalcVATRec.BasePrice, 0)
                   , Amount_FC_D
                   , Amount_FC_C
                   , Amount_EUR_D
                   , Amount_EUR_C
                   , aBaseInfoRec.ValueDate
                   , null
                   , aBaseInfoRec.TransactionDate
                   , null
                   , null
                   , 'STD'
                   , aCalcVATRec.FinCurrId_FC
                   , aCalcVATRec.FinCurrId_LC
                   , '1'
                   , null
                   , trunc(sysdate)
                   , aA_IDCRE
                   , aBaseInfoRec.PartImputId
                    );

        --Màj info compl.
        UpdateInfoImpIMF(FinImputation_id);
        CREATE_FIN_DISTRI_BVR(FinImputation_id
                            , aDescription
                            , Amount_LC_D
                            , Amount_LC_C
                            , Amount_FC_D
                            , Amount_FC_C
                            , Amount_EUR_D
                            , Amount_EUR_C
                            , aACS_FINANCIAL_ACCOUNT_ID
                            , aACS_AUXILIARY_ACCOUNT_ID
                            , aACT_DOCUMENT_ID2
                            , aA_IDCRE
                            , aBaseInfoRec.TransactionDate
                            , 1
                             );

        if ExistMAN <> 0 then
          CreateMgmVatImputations(aACT_FINANCIAL_IMPUTATION_ID
                                , aACS_FINANCIAL_ACCOUNT_ID
                                , aCalcVATRec.FinCurrId_FC
                                , aCalcVATRec.FinCurrId_LC
                                , aBaseInfoRec.PeriodId
                                , aBaseInfoRec.DocumentId
                                , FinImputation_id
                                , 'MAN'
                                , 'STD'
                                , aDescription
                                , 0
                                , Amount_LC_D
                                , Amount_LC_C
                                , aCalcVATRec.ExchangeRate
                                , aCalcVATRec.BasePrice
                                , Amount_FC_D
                                , Amount_FC_C
                                , Amount_EUR_D
                                , Amount_EUR_C
                                , aBaseInfoRec.ValueDate
                                , aBaseInfoRec.TransactionDate
                                , aA_IDCRE
                                 );
        end if;

        --Insertion du record de correction de tva pour le calcul du brut
        if aCalcVATRec.IE = 'I' then
          --recherche du compte financier de l'écriture
          select ACS_FINANCIAL_ACCOUNT_ID
            into aBaseInfoRec.FinAccId
            from ACT_FINANCIAL_IMPUTATION
           where ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

          --recherche division
          select min(ACS_DIVISION_ACCOUNT_ID)
            into vDivisionId
            from ACT_FINANCIAL_DISTRIBUTION
           where ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

          Amount_LC_D   := 0;
          Amount_EUR_D  := 0;
          Amount_FC_D   := 0;
          Amount_LC_C   := 0;
          Amount_EUR_C  := 0;
          Amount_FC_C   := 0;

          if aCalcVATRec.Amount_LC > 0 then
            Amount_LC_C   := aCalcVATRec.Amount_LC;
            Amount_FC_C   := aCalcVATRec.Amount_FC;
            Amount_EUR_C  := aCalcVATRec.Amount_EUR;
          else
            Amount_LC_D   := aCalcVATRec.Amount_LC * -1;
            Amount_FC_D   := aCalcVATRec.Amount_FC * -1;
            Amount_EUR_D  := aCalcVATRec.Amount_EUR * -1;
          end if;

          select init_id_seq.nextval
            into FinImputation_id2
            from dual;

          insert into ACT_FINANCIAL_IMPUTATION
                      (ACT_FINANCIAL_IMPUTATION_ID
                     , ACS_PERIOD_ID
                     , ACT_DOCUMENT_ID
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
                     , ACT_DET_PAYMENT_ID
                     , IMF_GENRE
                     , ACS_FINANCIAL_CURRENCY_ID
                     , ACS_ACS_FINANCIAL_CURRENCY_ID
                     , C_GENRE_TRANSACTION
                     , IMF_NUMBER
                     , A_DATECRE
                     , A_IDCRE
                     , ACT_PART_IMPUTATION_ID
                      )
               values (FinImputation_id2
                     , aBaseInfoRec.PeriodId
                     , aBaseInfoRec.DocumentId
                     , aBaseInfoRec.FinAccId
                     , 'VAT'
                     , 0
                     , aDescription
                     , Amount_LC_D
                     , Amount_LC_C
                     , nvl(aCalcVATRec.ExchangeRate, 0)
                     , nvl(aCalcVATRec.BasePrice, 0)
                     , Amount_FC_D
                     , Amount_FC_C
                     , Amount_EUR_D
                     , Amount_EUR_C
                     , aBaseInfoRec.ValueDate
                     , null
                     , aBaseInfoRec.TransactionDate
                     , null
                     , null
                     , 'STD'
                     , aCalcVATRec.FinCurrId_FC
                     , aCalcVATRec.FinCurrId_LC
                     , '1'
                     , null
                     , trunc(sysdate)
                     , aA_IDCRE
                     , aBaseInfoRec.PartImputId
                      );

          --Màj info compl.
          UpdateInfoImpIMF(FinImputation_id2);
          CREATE_FIN_DISTRI_BVR(FinImputation_id2
                              , aDescription
                              , Amount_LC_D
                              , Amount_LC_C
                              , Amount_FC_D
                              , Amount_FC_C
                              , Amount_EUR_D
                              , Amount_EUR_C
                              , aBaseInfoRec.FinAccId
                              , aACS_AUXILIARY_ACCOUNT_ID
                              , aACT_DOCUMENT_ID2
                              , aA_IDCRE
                              , aBaseInfoRec.TransactionDate
                              , 1
                              , vDivisionId
                               );

          if ExistMAN <> 0 then
            CreateMgmVatImputations(aACT_FINANCIAL_IMPUTATION_ID
                                  , aBaseInfoRec.FinAccId
                                  , aCalcVATRec.FinCurrId_FC
                                  , aCalcVATRec.FinCurrId_LC
                                  , aBaseInfoRec.PeriodId
                                  , aBaseInfoRec.DocumentId
                                  , FinImputation_id2
                                  , 'MAN'
                                  , 'STD'
                                  , aDescription
                                  , 0
                                  , Amount_LC_D
                                  , Amount_LC_C
                                  , nvl(aCalcVATRec.ExchangeRate, 0)
                                  , nvl(aCalcVATRec.BasePrice, 0)
                                  , Amount_FC_D
                                  , Amount_FC_C
                                  , Amount_EUR_D
                                  , Amount_EUR_C
                                  , aBaseInfoRec.ValueDate
                                  , aBaseInfoRec.TransactionDate
                                  , aA_IDCRE
                                   );
          end if;
        end if;
      end if;
    end if;

    --màj du code taxe de l'écriture
    update ACT_FINANCIAL_IMPUTATION
       set ACS_TAX_CODE_ID = aACS_TAX_CODE_ID
     where ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

    --création du détail de taxe
    select init_id_seq.nextval
      into DetTax_id
      from dual;

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
               , TAX_DEDUCTIBLE_RATE
               , ACS_SUB_SET_ID
               , ACS_ACCOUNT_ID2
               , ACT_ACT_FINANCIAL_IMPUTATION
               , ACT2_ACT_FINANCIAL_IMPUTATION
               , TAX_REDUCTION
               , DET_BASE_PRICE
               , A_DATECRE
               , A_IDCRE
               , TAX_TMP_VAT_ENCASHMENT
                )
         values (DetTax_id
               , aACT_FINANCIAL_IMPUTATION_ID
               , nvl(aCalcVATRec.ExchangeRate, 0)
               , aCalcVATRec.IE
               , aCalcVATRec.LiabledAmount
               , aInfoVATRec.LiabledRate
               , aInfoVATRec.Rate
               , aCalcVATRec.Amount_FC
               , aCalcVATRec.Amount_LC
               , aCalcVATRec.Amount_EUR
               , aCalcVATRec.TotAmount_FC
               , aCalcVATRec.TotAmount_LC
               , aCalcVATRec.TotAmount_EUR
               , aInfoVATRec.DeductibleRate
               , aInfoVATRec.SubSetId
               , null
               , FinImputation_id
               , FinImputation_id2
               , 0
               , nvl(aCalcVATRec.BasePrice, 0)
               , trunc(sysdate)
               , aA_IDCRE
               , aCalcVATRec.Encashment
                );

    -- si auto-taxation
    if aCalcVATRec.IE = 'S' then
      -- Création des imputations d'autotaxation
      if not ACT_VAT_MANAGEMENT.CreateVAT_ACI(aACT_FINANCIAL_IMPUTATION_ID) then
        raise_application_error(-20001, 'PCS - Problem with Self-Taxing');
      end if;
    end if;
  end CREATE_VAT_SBVR;

---------------------------------------------------------------------------------------------------------------------
  function GetSubSetOfAccount(aACS_ACCOUNT_ID number)
    return number
  is
    result ACS_SUB_SET.ACS_SUB_SET_ID%type;
  begin
    select ACS_SUB_SET_ID
      into result
      from ACS_ACCOUNT
     where ACS_ACCOUNT_ID = aACS_ACCOUNT_ID;

    return result;
  end GetSubSetOfAccount;

---------------------------------------------------------------------------------------------------------------------
  function GetCPNAccOfFINAcc(aACS_FINANCIAL_ACCOUNT_ID number)
    return number
  is
    result ACS_FINANCIAL_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
  begin
    select max(ACS_CPN_ACCOUNT_ID)
      into result
      from ACS_FINANCIAL_ACCOUNT
     where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    return result;
  end GetCPNAccOfFINAcc;

---------------------------------------------------------------------------------------------------------------------
  function GetQTYAccOfCPNAcc(aACS_CPN_ACCOUNT_ID number)
    return number
  is
    result ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
  begin
    select ACS_QTY_UNIT_ID
      into result
      from ACS_QTY_S_CPN_ACOUNT
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID;

    return result;
  end GetQTYAccOfCPNAcc;

--------------------------------
  procedure FindMANDiscountAccount(
    aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aOriginImputationId        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , atblMgmImputations  in out tblMgmImputationsTyp
  , atblMgmDistribution in out tblMgmDistributionTyp
  )
  is
    CDAId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PFId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PJId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    select ACS_CDA_DISCOUNT_ID
         , ACS_PF_DISCOUNT_ID
         , ACS_PJ_DISCOUNT_ID
      into CDAId
         , PFId
         , PJId
      from ACS_SUB_SET
         , ACS_ACCOUNT
     where ACS_ACCOUNT.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID
       and ACS_SUB_SET.ACS_SUB_SET_ID = ACS_ACCOUNT.ACS_SUB_SET_ID;

    MgmUniqueImputationProportion(CDAId, PFId, PJId, atblMgmImputations, atblMgmDistribution, aOriginImputationId);

    if atblMgmImputations.count < 1 then
      MgmImputationsProportion(aOriginImputationId, atblMgmImputations, atblMgmDistribution);
    end if;
  end FindMANDiscountAccount;

---------------------------------
  procedure FindMANDeductionAccount(
    aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aOriginImputationId        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , atblMgmImputations  in out tblMgmImputationsTyp
  , atblMgmDistribution in out tblMgmDistributionTyp
  , aNegativeDeduction         boolean
  )
  is
    CDAId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PFId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PJId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if aNegativeDeduction then
      select ACS_CDA_NEG_DEDUCTION_ID
           , ACS_PF_NEG_DEDUCTION_ID
           , ACS_PJ_NEG_DEDUCTION_ID
        into CDAId
           , PFId
           , PJId
        from ACS_SUB_SET
           , ACS_ACCOUNT
       where ACS_ACCOUNT.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID
         and ACS_SUB_SET.ACS_SUB_SET_ID = ACS_ACCOUNT.ACS_SUB_SET_ID;
    else
      select ACS_CDA_DEDUCTION_ID
           , ACS_PF_DEDUCTION_ID
           , ACS_PJ_DEDUCTION_ID
        into CDAId
           , PFId
           , PJId
        from ACS_SUB_SET
           , ACS_ACCOUNT
       where ACS_ACCOUNT.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID
         and ACS_SUB_SET.ACS_SUB_SET_ID = ACS_ACCOUNT.ACS_SUB_SET_ID;
    end if;

    MgmUniqueImputationProportion(CDAId, PFId, PJId, atblMgmImputations, atblMgmDistribution, aOriginImputationId);

    if atblMgmImputations.count < 1 then
      MgmImputationsProportion(aOriginImputationId, atblMgmImputations, atblMgmDistribution);
    end if;
  end FindMANDeductionAccount;

------------------------------
  procedure FindMANChargeAccount(
    aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aOriginImputationId        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , atblMgmImputations  in out tblMgmImputationsTyp
  , atblMgmDistribution in out tblMgmDistributionTyp
  )
  is
    CDAId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PFId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PJId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    select ACS_CDA_CHARGES_ID
         , ACS_PF_CHARGES_ID
         , ACS_PJ_CHARGES_ID
      into CDAId
         , PFId
         , PJId
      from ACS_SUB_SET
         , ACS_ACCOUNT
     where ACS_ACCOUNT.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID
       and ACS_SUB_SET.ACS_SUB_SET_ID = ACS_ACCOUNT.ACS_SUB_SET_ID;

    MgmUniqueImputationProportion(CDAId, PFId, PJId, atblMgmImputations, atblMgmDistribution, aOriginImputationId);

    if atblMgmImputations.count < 1 then
      MgmImputationsProportion(aOriginImputationId, atblMgmImputations, atblMgmDistribution);
    end if;
  end FindMANChargeAccount;

---------------------------------------------------------------------------------------------------------------------
  procedure FindMANDiffExchangeAccount(
    aACS_FINANCIAL_CURRENCY_ID        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aType                             number
  , atblMgmImputations         in out tblMgmImputationsTyp
  , atblMgmDistribution        in out tblMgmDistributionTyp
  , aOriginImputationId               ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type default null
  )
  -- aType : -- 4: Diff de change - client
             -- 5: Diff de change + client
             -- 6: Diff de change - Fournisseur
             -- 7: Diff de change + Fournisseur
  is
    CDAId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PFId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PJId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if aType = 4 then
      select ACS_CDA_EFF_LOSS_ID
           , ACS_PJ_EFF_LOSS_ID
           , ACS_PF_EFF_LOSS_ID
        into CDAId
           , PJId
           , PFId
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;
    elsif aType = 5 then
      select ACS_CDA_EFF_GAIN_ID
           , ACS_PJ_EFF_GAIN_ID
           , ACS_PF_EFF_GAIN_ID
        into CDAId
           , PJId
           , PFId
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;
    elsif aType = 6 then
      select ACS_PAY_CDA_EFF_LOSS_ID
           , ACS_PAY_PJ_EFF_LOSS_ID
           , ACS_PAY_PF_EFF_LOSS_ID
        into CDAId
           , PJId
           , PFId
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;
    elsif aType = 7 then
      select ACS_PAY_CDA_EFF_GAIN_ID
           , ACS_PAY_PJ_EFF_GAIN_ID
           , ACS_PAY_PF_EFF_GAIN_ID
        into CDAId
           , PJId
           , PFId
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;
    end if;

    MgmUniqueImputationProportion(CDAId, PFId, PJId, atblMgmImputations, atblMgmDistribution, aOriginImputationId);
  end FindMANDiffExchangeAccount;

  procedure FindMANDiffExchangeAccount_F(
    aACS_FINANCIAL_CURRENCY_ID        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aType                             number
  , atblMgmImputations         in out tblMgmImputationsTyp
  , atblMgmDistribution        in out tblMgmDistributionTyp
  , aOriginImputationId               ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type default null
  )
  -- aType : -- 4: Diff de change - client
             -- 5: Diff de change + client
             -- 6: Diff de change - Fournisseur
             -- 7: Diff de change + Fournisseur
  is
    CDAId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PFId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PJId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if aType = 4 then
      select ACS_CDA_EFF_LOSS_F_ID
           , ACS_PJ_EFF_LOSS_F_ID
           , ACS_PF_EFF_LOSS_F_ID
        into CDAId
           , PJId
           , PFId
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;
    elsif aType = 5 then
      select ACS_CDA_EFF_GAIN_F_ID
           , ACS_PJ_EFF_GAIN_F_ID
           , ACS_PF_EFF_GAIN_F_ID
        into CDAId
           , PJId
           , PFId
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;
    elsif aType = 6 then
      select ACS_PAY_CDA_EFF_LOSS_F_ID
           , ACS_PAY_PJ_EFF_LOSS_F_ID
           , ACS_PAY_PF_EFF_LOSS_F_ID
        into CDAId
           , PJId
           , PFId
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;
    elsif aType = 7 then
      select ACS_PAY_CDA_EFF_GAIN_F_ID
           , ACS_PAY_PJ_EFF_GAIN_F_ID
           , ACS_PAY_PF_EFF_GAIN_F_ID
        into CDAId
           , PJId
           , PFId
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;
    end if;

    MgmUniqueImputationProportion(CDAId, PFId, PJId, atblMgmImputations, atblMgmDistribution, aOriginImputationId);
  end FindMANDiffExchangeAccount_F;

---------------------------------------------------------------------------------------------------------------------
  procedure GetMANImputationPermission(
    aACS_CPN_ACCOUNT_ID in     number
  , aC_CDA_IMPUTATION   out    number
  , aC_PF_IMPUTATION    out    number
  , aC_PJ_IMPUTATION    out    number
  )
  is
  begin
    select C_CDA_IMPUTATION
         , C_PF_IMPUTATION
         , C_PJ_IMPUTATION
      into aC_CDA_IMPUTATION
         , aC_PF_IMPUTATION
         , aC_PJ_IMPUTATION
      from ACS_CPN_ACCOUNT
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID;
  end GetMANImputationPermission;

------------------------
  procedure GetMgmAccounts(
    aACS_CPN_ACCOUNT_ID               ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aOriginDocumentId                 ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_QTY_UNIT_ID           in out ACT_MGM_IMPUTATION.ACS_QTY_UNIT_ID%type
  , atblMgmImputations         in out tblMgmImputationsTyp
  , atblMgmDistribution        in out tblMgmDistributionTyp
  , aType                             number
  )   -- 1: Discount, 2: Déduction, 22: Déduction négative, 3: Charges,
      -- 4: Diff de change + client
      -- 5: Diff de change - client
      -- 6: Diff de change + Fournisseur
      -- 7: Diff de change - Fournisseur
  is
    PermissionCDA      ACS_CPN_ACCOUNT.C_CDA_IMPUTATION%type;
    PermissionPF       ACS_CPN_ACCOUNT.C_PF_IMPUTATION%type;
    PermissionPJ       ACS_CPN_ACCOUNT.C_PJ_IMPUTATION%type;
    OriginImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    AccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  -----
  begin
    aACS_QTY_UNIT_ID  := GetQTYAccountIdOfCPN(aACS_CPN_ACCOUNT_ID);

    if aType in(1, 2, 3, 22) then
      OriginImputationId  := GetFinancialImputationId(aOriginDocumentId, AccountId);   -- AccountId sans importance
    end if;

    if aType = 1 then
      FindMANDiscountAccount(aACS_AUXILIARY_ACCOUNT_ID, OriginImputationId, atblMgmImputations, atblMgmDistribution);
    elsif aType = 2 then
      FindMANDeductionAccount(aACS_AUXILIARY_ACCOUNT_ID
                            , OriginImputationId
                            , atblMgmImputations
                            , atblMgmDistribution
                            , false
                             );
    elsif aType = 22 then
      FindMANDeductionAccount(aACS_AUXILIARY_ACCOUNT_ID
                            , OriginImputationId
                            , atblMgmImputations
                            , atblMgmDistribution
                            , true
                             );
    elsif aType = 3 then
      FindMANChargeAccount(aACS_AUXILIARY_ACCOUNT_ID, OriginImputationId, atblMgmImputations, atblMgmDistribution);
    elsif aType in(4, 5, 6, 7) then
      FindMANDiffExchangeAccount(aACS_FINANCIAL_CURRENCY_ID
                               , aType
                               , atblMgmImputations
                               , atblMgmDistribution
                               , OriginImputationId
                                );
    end if;

    GetMANImputationPermission(aACS_CPN_ACCOUNT_ID, PermissionCDA, PermissionPF, PermissionPJ);

    if atblMgmImputations.count = 1 then
      if     (atblMgmImputations(1).ACS_CDA_ACCOUNT_ID is not null)
         and (PermissionCDA = '3') then
        atblMgmImputations(1).ACS_CDA_ACCOUNT_ID  := null;
      end if;

      if     (atblMgmImputations(1).ACS_PF_ACCOUNT_ID is not null)
         and (PermissionPF = '3') then
        atblMgmImputations(1).ACS_PF_ACCOUNT_ID  := null;
      end if;

      if     (atblMgmImputations(1).ACS_CDA_ACCOUNT_ID is not null)
         and (PermissionCDA = '2')
         and (PermissionPF = '2') then
        atblMgmImputations(1).ACS_PF_ACCOUNT_ID  := null;
      elsif     (atblMgmImputations(1).ACS_PF_ACCOUNT_ID is not null)
            and (PermissionCDA = '2')
            and (PermissionPF = '2') then
        atblMgmImputations(1).ACS_CDA_ACCOUNT_ID  := null;
      end if;

      if    (     (atblMgmImputations(1).ACS_PF_ACCOUNT_ID is null)
             and (atblMgmImputations(1).ACS_CDA_ACCOUNT_ID is null) )
         or (     (atblMgmImputations(1).ACS_PF_ACCOUNT_ID is null)
             and (PermissionPF = '1') )
         or (     (atblMgmImputations(1).ACS_CDA_ACCOUNT_ID is null)
             and (PermissionCDA = '1') ) then
        raise_application_error(-20000, 'PCS - Error permission of analytic imputation.');
      end if;

      if     atblMgmDistribution.count = 1
         and not(PermissionPJ in('1', '2') ) then
        atblMgmDistribution.delete;
      end if;
    end if;
  end GetMgmAccounts;

--------------------------

  procedure GetMgmAccounts_F(
    aACS_CPN_ACCOUNT_ID               ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_QTY_UNIT_ID           in out ACT_MGM_IMPUTATION.ACS_QTY_UNIT_ID%type
  , atblMgmImputations         in out tblMgmImputationsTyp
  , atblMgmDistribution        in out tblMgmDistributionTyp
  , aType                             number
  )
      -- 4: Diff de change - client
      -- 5: Diff de change + client
      -- 6: Diff de change - Fournisseur
      -- 7: Diff de change + Fournisseur
  is
    PermissionCDA      ACS_CPN_ACCOUNT.C_CDA_IMPUTATION%type;
    PermissionPF       ACS_CPN_ACCOUNT.C_PF_IMPUTATION%type;
    PermissionPJ       ACS_CPN_ACCOUNT.C_PJ_IMPUTATION%type;
    OriginImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    AccountId          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  -----
  begin
    aACS_QTY_UNIT_ID  := GetQTYAccountIdOfCPN(aACS_CPN_ACCOUNT_ID);

    if aType in(4, 5, 6, 7) then
      FindMANDiffExchangeAccount_F(aACS_FINANCIAL_CURRENCY_ID
                               , aType
                               , atblMgmImputations
                               , atblMgmDistribution
                               , OriginImputationId
                                );
    end if;

    GetMANImputationPermission(aACS_CPN_ACCOUNT_ID, PermissionCDA, PermissionPF, PermissionPJ);

    if atblMgmImputations.count = 1 then
      if     (atblMgmImputations(1).ACS_CDA_ACCOUNT_ID is not null)
         and (PermissionCDA = '3') then
        atblMgmImputations(1).ACS_CDA_ACCOUNT_ID  := null;
      end if;

      if     (atblMgmImputations(1).ACS_PF_ACCOUNT_ID is not null)
         and (PermissionPF = '3') then
        atblMgmImputations(1).ACS_PF_ACCOUNT_ID  := null;
      end if;

      if     (atblMgmImputations(1).ACS_CDA_ACCOUNT_ID is not null)
         and (PermissionCDA = '2')
         and (PermissionPF = '2') then
        atblMgmImputations(1).ACS_PF_ACCOUNT_ID  := null;
      elsif     (atblMgmImputations(1).ACS_PF_ACCOUNT_ID is not null)
            and (PermissionCDA = '2')
            and (PermissionPF = '2') then
        atblMgmImputations(1).ACS_CDA_ACCOUNT_ID  := null;
      end if;

      if    (     (atblMgmImputations(1).ACS_PF_ACCOUNT_ID is null)
             and (atblMgmImputations(1).ACS_CDA_ACCOUNT_ID is null) )
         or (     (atblMgmImputations(1).ACS_PF_ACCOUNT_ID is null)
             and (PermissionPF = '1') )
         or (     (atblMgmImputations(1).ACS_CDA_ACCOUNT_ID is null)
             and (PermissionCDA = '1') ) then
        raise_application_error(-20000, 'PCS - Error permission of analytic imputation.');
      end if;

      if     atblMgmDistribution.count = 1
         and not(PermissionPJ in('1', '2') ) then
        atblMgmDistribution.delete;
      end if;
    end if;
  end GetMgmAccounts_F;
--------------------------

  function GetVatMgmAccounts(
    aACS_CPN_ACCOUNT_ID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aOriginImputationId        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aACS_QTY_UNIT_ID    in out ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , atblMgmImputations  in out tblMgmImputationsTyp
  , atblMgmDistribution in out tblMgmDistributionTyp
  )
    return number
  is
    result number(1) := 0;
  begin
    aACS_QTY_UNIT_ID  := GetQTYAccountIdOfCPN(aACS_CPN_ACCOUNT_ID);

    if aOriginImputationId is not null then
      atblMgmImputations.delete;
      atblMgmDistribution.delete;
      MgmImputationsProportion(aOriginImputationId, atblMgmImputations, atblMgmDistribution);

      if atblMgmImputations.count > 0 then
        result  := 1;
      end if;
    end if;

    return result;
  end GetVatMgmAccounts;

-----------------------------------
  procedure CreateMANImputForDiscount(
    aACS_FINANCIAL_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID     ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_PERIOD_ID                 ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , aACT_DOCUMENT_ID               ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID   ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aIMM_TYPE                      ACT_MGM_IMPUTATION.IMM_TYPE%type
  , aIMM_GENRE                     ACT_MGM_IMPUTATION.IMM_GENRE%type
  , aIMM_DESCRIPTION               ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type
  , aIMM_PRIMARY                   ACT_MGM_IMPUTATION.IMM_PRIMARY%type
  , aIMM_AMOUNT_LC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type
  , aIMM_AMOUNT_LC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type
  , aIMM_EXCHANGE_RATE             ACT_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type
  , aIMM_BASE_PRICE                ACT_MGM_IMPUTATION.IMM_BASE_PRICE%type
  , aIMM_AMOUNT_FC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type
  , aIMM_AMOUNT_FC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type
  , aIMM_AMOUNT_EUR_D              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type
  , aIMM_AMOUNT_EUR_C              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type
  , aIMM_VALUE_DATE                ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type
  , aIMM_TRANSACTION_DATE          ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type
  , aACS_AUXILIARY_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aOriginDocumentId              ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aA_IDCRE                       ACT_MGM_IMPUTATION.A_IDCRE%type
  )
  is
    CpnAccount_id      ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    QtyAccount_id      ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    tblMgmImputations  tblMgmImputationsTyp;
    tblMgmDistribution tblMgmDistributionTyp;
  -----
  begin
    CpnAccount_id  := GetCPNAccOfFINAcc(aACS_FINANCIAL_ACCOUNT_ID);

    if CpnAccount_id is not null then
      GetMgmAccounts(CpnAccount_id
                   , aACS_AUXILIARY_ACCOUNT_ID
                   , null
                   , aOriginDocumentId
                   , QtyAccount_id
                   , tblMgmImputations
                   , tblMgmDistribution
                   , 1
                    );
      CreateMANImputations(aACS_FINANCIAL_ACCOUNT_ID
                         , CpnAccount_id
                         , QtyAccount_id
                         , tblMgmImputations
                         , tblMgmDistribution
                         , aACS_FINANCIAL_CURRENCY_ID
                         , aACS_ACS_FINANCIAL_CURRENCY_ID
                         , aACS_PERIOD_ID
                         , aACT_DOCUMENT_ID
                         , aACT_FINANCIAL_IMPUTATION_ID
                         , aIMM_TYPE
                         , aIMM_GENRE
                         , aIMM_DESCRIPTION
                         , aIMM_PRIMARY
                         , aIMM_AMOUNT_LC_D
                         , aIMM_AMOUNT_LC_C
                         , aIMM_EXCHANGE_RATE
                         , aIMM_BASE_PRICE
                         , aIMM_AMOUNT_FC_D
                         , aIMM_AMOUNT_FC_C
                         , aIMM_AMOUNT_EUR_D
                         , aIMM_AMOUNT_EUR_C
                         , aIMM_VALUE_DATE
                         , aIMM_TRANSACTION_DATE
                         , aA_IDCRE
                          );
    end if;
  end CreateMANImputForDiscount;

------------------------------------
  procedure CreateMANImputForDeduction(
    aACS_FINANCIAL_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID     ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_PERIOD_ID                 ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , aACT_DOCUMENT_ID               ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID   ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aIMM_TYPE                      ACT_MGM_IMPUTATION.IMM_TYPE%type
  , aIMM_GENRE                     ACT_MGM_IMPUTATION.IMM_GENRE%type
  , aIMM_DESCRIPTION               ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type
  , aIMM_PRIMARY                   ACT_MGM_IMPUTATION.IMM_PRIMARY%type
  , aIMM_AMOUNT_LC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type
  , aIMM_AMOUNT_LC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type
  , aIMM_EXCHANGE_RATE             ACT_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type
  , aIMM_BASE_PRICE                ACT_MGM_IMPUTATION.IMM_BASE_PRICE%type
  , aIMM_AMOUNT_FC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type
  , aIMM_AMOUNT_FC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type
  , aIMM_AMOUNT_EUR_D              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type
  , aIMM_AMOUNT_EUR_C              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type
  , aIMM_VALUE_DATE                ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type
  , aIMM_TRANSACTION_DATE          ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type
  , aACS_AUXILIARY_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aOriginDocumentId              ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aA_IDCRE                       ACT_MGM_IMPUTATION.A_IDCRE%type
  , aNegativeDeduction             boolean
  )
  is
    CpnAccount_id      ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    QtyAccount_id      ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    tblMgmImputations  tblMgmImputationsTyp;
    tblMgmDistribution tblMgmDistributionTyp;
  -----
  begin
    CpnAccount_id  := GetCPNAccOfFINAcc(aACS_FINANCIAL_ACCOUNT_ID);

    if CpnAccount_id is not null then
      if aNegativeDeduction then
        GetMgmAccounts(CpnAccount_id
                     , aACS_AUXILIARY_ACCOUNT_ID
                     , null
                     , aOriginDocumentId
                     , QtyAccount_id
                     , tblMgmImputations
                     , tblMgmDistribution
                     , 22
                      );
      else
        GetMgmAccounts(CpnAccount_id
                     , aACS_AUXILIARY_ACCOUNT_ID
                     , null
                     , aOriginDocumentId
                     , QtyAccount_id
                     , tblMgmImputations
                     , tblMgmDistribution
                     , 2
                      );
      end if;

      CreateMANImputations(aACS_FINANCIAL_ACCOUNT_ID
                         , CpnAccount_id
                         , QtyAccount_id
                         , tblMgmImputations
                         , tblMgmDistribution
                         , aACS_FINANCIAL_CURRENCY_ID
                         , aACS_ACS_FINANCIAL_CURRENCY_ID
                         , aACS_PERIOD_ID
                         , aACT_DOCUMENT_ID
                         , aACT_FINANCIAL_IMPUTATION_ID
                         , aIMM_TYPE
                         , aIMM_GENRE
                         , aIMM_DESCRIPTION
                         , aIMM_PRIMARY
                         , aIMM_AMOUNT_LC_D
                         , aIMM_AMOUNT_LC_C
                         , aIMM_EXCHANGE_RATE
                         , aIMM_BASE_PRICE
                         , aIMM_AMOUNT_FC_D
                         , aIMM_AMOUNT_FC_C
                         , aIMM_AMOUNT_EUR_D
                         , aIMM_AMOUNT_EUR_C
                         , aIMM_VALUE_DATE
                         , aIMM_TRANSACTION_DATE
                         , aA_IDCRE
                          );
    end if;
  end CreateMANImputForDeduction;

----------------------------------
  procedure CreateMANImputForCharges(
    aACS_FINANCIAL_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID     ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_PERIOD_ID                 ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , aACT_DOCUMENT_ID               ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID   ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aIMM_TYPE                      ACT_MGM_IMPUTATION.IMM_TYPE%type
  , aIMM_GENRE                     ACT_MGM_IMPUTATION.IMM_GENRE%type
  , aIMM_DESCRIPTION               ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type
  , aIMM_PRIMARY                   ACT_MGM_IMPUTATION.IMM_PRIMARY%type
  , aIMM_AMOUNT_LC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type
  , aIMM_AMOUNT_LC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type
  , aIMM_EXCHANGE_RATE             ACT_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type
  , aIMM_BASE_PRICE                ACT_MGM_IMPUTATION.IMM_BASE_PRICE%type
  , aIMM_AMOUNT_FC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type
  , aIMM_AMOUNT_FC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type
  , aIMM_AMOUNT_EUR_D              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type
  , aIMM_AMOUNT_EUR_C              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type
  , aIMM_VALUE_DATE                ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type
  , aIMM_TRANSACTION_DATE          ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type
  , aACS_AUXILIARY_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aOriginDocumentId              ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aA_IDCRE                       ACT_MGM_IMPUTATION.A_IDCRE%type
  )
  is
    CpnAccount_id      ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    QtyAccount_id      ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    tblMgmImputations  tblMgmImputationsTyp;
    tblMgmDistribution tblMgmDistributionTyp;
  -----
  begin
    CpnAccount_id  := GetCPNAccOfFINAcc(aACS_FINANCIAL_ACCOUNT_ID);

    if CpnAccount_id is not null then
      GetMgmAccounts(CpnAccount_id
                   , aACS_AUXILIARY_ACCOUNT_ID
                   , null
                   , aOriginDocumentId
                   , QtyAccount_id
                   , tblMgmImputations
                   , tblMgmDistribution
                   , 3
                    );
      CreateMANImputations(aACS_FINANCIAL_ACCOUNT_ID
                         , CpnAccount_id
                         , QtyAccount_id
                         , tblMgmImputations
                         , tblMgmDistribution
                         , aACS_FINANCIAL_CURRENCY_ID
                         , aACS_ACS_FINANCIAL_CURRENCY_ID
                         , aACS_PERIOD_ID
                         , aACT_DOCUMENT_ID
                         , aACT_FINANCIAL_IMPUTATION_ID
                         , aIMM_TYPE
                         , aIMM_GENRE
                         , aIMM_DESCRIPTION
                         , aIMM_PRIMARY
                         , aIMM_AMOUNT_LC_D
                         , aIMM_AMOUNT_LC_C
                         , aIMM_EXCHANGE_RATE
                         , aIMM_BASE_PRICE
                         , aIMM_AMOUNT_FC_D
                         , aIMM_AMOUNT_FC_C
                         , aIMM_AMOUNT_EUR_D
                         , aIMM_AMOUNT_EUR_C
                         , aIMM_VALUE_DATE
                         , aIMM_TRANSACTION_DATE
                         , aA_IDCRE
                          );
    end if;
  end CreateMANImputForCharges;

------------------------------
  procedure CreateMANImputations(
    aACS_FINANCIAL_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_CPN_ACCOUNT_ID            ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type
  , aACS_QTY_UNIT_ID               ACT_MGM_IMPUTATION.ACS_QTY_UNIT_ID%type
  , atblMgmImputations             tblMgmImputationsTyp
  , atblMgmDistribution            tblMgmDistributionTyp
  , aACS_FINANCIAL_CURRENCY_ID     ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_PERIOD_ID                 ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , aACT_DOCUMENT_ID               ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID   ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aIMM_TYPE                      ACT_MGM_IMPUTATION.IMM_TYPE%type
  , aIMM_GENRE                     ACT_MGM_IMPUTATION.IMM_GENRE%type
  , aIMM_DESCRIPTION               ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type
  , aIMM_PRIMARY                   ACT_MGM_IMPUTATION.IMM_PRIMARY%type
  , aIMM_AMOUNT_LC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type
  , aIMM_AMOUNT_LC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type
  , aIMM_EXCHANGE_RATE             ACT_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type
  , aIMM_BASE_PRICE                ACT_MGM_IMPUTATION.IMM_BASE_PRICE%type
  , aIMM_AMOUNT_FC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type
  , aIMM_AMOUNT_FC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type
  , aIMM_AMOUNT_EUR_D              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type
  , aIMM_AMOUNT_EUR_C              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type
  , aIMM_VALUE_DATE                ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type
  , aIMM_TRANSACTION_DATE          ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type
  , aA_IDCRE                       ACT_MGM_IMPUTATION.A_IDCRE%type
  )
  is
    MGMImputationId   ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    MGMDistributionId ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type;
    TotAmount_LC_D    ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type;
    TotAmount_LC_C    ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type;
    TotAmount_FC_D    ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type;
    TotAmount_FC_C    ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type;
    TotAmount_EUR_D   ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type;
    TotAmount_EUR_C   ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type;
    Amount_LC_D       ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type;
    Amount_LC_C       ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type;
    Amount_FC_D       ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type;
    Amount_FC_C       ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type;
    Amount_EUR_D      ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type;
    Amount_EUR_C      ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type;
    PJTotAmount_LC_D  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_D%type;
    PJTotAmount_LC_C  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_C%type;
    PJTotAmount_FC_D  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_FC_D%type;
    PJTotAmount_FC_C  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_FC_C%type;
    PJTotAmount_EUR_D ACT_MGM_DISTRIBUTION.MGM_AMOUNT_EUR_D%type;
    PJTotAmount_EUR_C ACT_MGM_DISTRIBUTION.MGM_AMOUNT_EUR_C%type;
    PJAmount_LC_D     ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_D%type;
    PJAmount_LC_C     ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_C%type;
    PJAmount_FC_D     ACT_MGM_DISTRIBUTION.MGM_AMOUNT_FC_D%type;
    PJAmount_FC_C     ACT_MGM_DISTRIBUTION.MGM_AMOUNT_FC_C%type;
    PJAmount_EUR_D    ACT_MGM_DISTRIBUTION.MGM_AMOUNT_EUR_D%type;
    PJAmount_EUR_C    ACT_MGM_DISTRIBUTION.MGM_AMOUNT_EUR_C%type;
    tblDistribution   tblMgmDistributionTyp;
  -----
  begin
    TotAmount_LC_D   := aIMM_AMOUNT_LC_D;
    TotAmount_LC_C   := aIMM_AMOUNT_LC_C;
    TotAmount_FC_D   := aIMM_AMOUNT_FC_D;
    TotAmount_FC_C   := aIMM_AMOUNT_FC_C;
    TotAmount_EUR_D  := aIMM_AMOUNT_EUR_D;
    TotAmount_EUR_C  := aIMM_AMOUNT_EUR_C;

    for i in 1 .. atblMgmImputations.count loop
      if i = atblMgmImputations.count then
        Amount_LC_D   := TotAmount_LC_D;
        Amount_LC_C   := TotAmount_LC_C;
        Amount_FC_D   := TotAmount_FC_D;
        Amount_FC_C   := TotAmount_FC_C;
        Amount_EUR_D  := TotAmount_EUR_D;
        Amount_EUR_C  := TotAmount_EUR_C;
      else
        Amount_LC_D   :=
          ACS_FUNCTION.RoundAmount(aIMM_AMOUNT_LC_D * atblMgmImputations(i).PROPORTION_C
                                 , aACS_ACS_FINANCIAL_CURRENCY_ID
                                  );
        Amount_LC_C   :=
          ACS_FUNCTION.RoundAmount(aIMM_AMOUNT_LC_C * atblMgmImputations(i).PROPORTION_D
                                 , aACS_ACS_FINANCIAL_CURRENCY_ID);
--      ACS_FUNCTION.ConvertAmount(Amount_LC_D, aACS_ACS_FINANCIAL_CURRENCY_ID, aACS_FINANCIAL_CURRENCY_ID,
--                                 aIMM_TRANSACTION_DATE, aIMM_EXCHANGE_RATE, aIMM_BASE_PRICE, 1, Amount_EUR_D, Amount_FC_D);
        Amount_FC_D   :=
             ACS_FUNCTION.RoundAmount(aIMM_AMOUNT_FC_D * atblMgmImputations(i).PROPORTION_C, aACS_FINANCIAL_CURRENCY_ID);
        Amount_FC_C   :=
             ACS_FUNCTION.RoundAmount(aIMM_AMOUNT_FC_C * atblMgmImputations(i).PROPORTION_D, aACS_FINANCIAL_CURRENCY_ID);
        Amount_EUR_D  := ACS_FUNCTION.RoundNear(aIMM_AMOUNT_EUR_D * atblMgmImputations(i).PROPORTION_C, 0.001, 0);
        Amount_EUR_C  := ACS_FUNCTION.RoundNear(aIMM_AMOUNT_EUR_C * atblMgmImputations(i).PROPORTION_D, 0.001, 0);
      end if;

      select init_id_seq.nextval
        into MGMImputationId
        from dual;

      insert into ACT_MGM_IMPUTATION
                  (ACT_MGM_IMPUTATION_ID
                 , ACS_CPN_ACCOUNT_ID
                 , ACS_QTY_UNIT_ID
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , ACS_PERIOD_ID
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
                 , IMM_VALUE_DATE
                 , IMM_TRANSACTION_DATE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (MGMImputationId
                 , aACS_CPN_ACCOUNT_ID
                 , aACS_QTY_UNIT_ID
                 , atblMgmImputations(i).ACS_CDA_ACCOUNT_ID
                 , atblMgmImputations(i).ACS_PF_ACCOUNT_ID
                 , aACS_FINANCIAL_CURRENCY_ID
                 , aACS_ACS_FINANCIAL_CURRENCY_ID
                 , aACS_PERIOD_ID
                 , aACT_DOCUMENT_ID
                 , aACT_FINANCIAL_IMPUTATION_ID
                 , aIMM_TYPE
                 , aIMM_GENRE
                 , aIMM_PRIMARY
                 , aIMM_DESCRIPTION
                 , Amount_LC_D
                 , Amount_LC_C
                 , aIMM_EXCHANGE_RATE
                 , aIMM_BASE_PRICE
                 , Amount_FC_D
                 , Amount_FC_C
                 , Amount_EUR_D
                 , Amount_EUR_C
                 , aIMM_VALUE_DATE
                 , aIMM_TRANSACTION_DATE
                 , trunc(sysdate)
                 , aA_IDCRE
                  );

      --Màj info compl.
      UpdateInfoImpIMM(MGMImputationId, atblMgmImputations(i).DOC_RECORD_ID);
      if (ACT_PROCESS_PAYMENT.ln_ResetHedgeRecord = 1) then
        ResetImmDocrecordId(MGMImputationId);
      end if;

      TotAmount_LC_D     := TotAmount_LC_D - Amount_LC_D;
      TotAmount_LC_C     := TotAmount_LC_C - Amount_LC_C;
      TotAmount_FC_D     := TotAmount_FC_D - Amount_FC_D;
      TotAmount_FC_C     := TotAmount_FC_C - Amount_FC_C;
      TotAmount_EUR_D    := TotAmount_EUR_D - Amount_EUR_D;
      TotAmount_EUR_C    := TotAmount_EUR_C - Amount_EUR_C;
      MgmDistributionProportion(atblMgmImputations(i).ACT_MGM_IMPUTATION_ID, atblMgmDistribution, tblDistribution);
      PJTotAmount_LC_D   := Amount_LC_D;
      PJTotAmount_LC_C   := Amount_LC_C;
      PJTotAmount_FC_D   := Amount_FC_D;
      PJTotAmount_FC_C   := Amount_FC_C;
      PJTotAmount_EUR_D  := Amount_EUR_D;
      PJTotAmount_EUR_C  := Amount_EUR_C;

      for j in 1 .. tblDistribution.count loop
        if j = tblDistribution.count then
          PJAmount_LC_D   := PJTotAmount_LC_D;
          PJAmount_LC_C   := PJTotAmount_LC_C;
          PJAmount_FC_D   := PJTotAmount_FC_D;
          PJAmount_FC_C   := PJTotAmount_FC_C;
          PJAmount_EUR_D  := PJTotAmount_EUR_D;
          PJAmount_EUR_C  := PJTotAmount_EUR_C;
        else
          PJAmount_LC_D   :=
                ACS_FUNCTION.RoundAmount(Amount_LC_D * tblDistribution(i).PROPORTION_C, aACS_ACS_FINANCIAL_CURRENCY_ID);
          PJAmount_LC_C   :=
                ACS_FUNCTION.RoundAmount(Amount_LC_C * tblDistribution(i).PROPORTION_D, aACS_ACS_FINANCIAL_CURRENCY_ID);
          PJAmount_FC_D   :=
                    ACS_FUNCTION.RoundAmount(Amount_FC_D * tblDistribution(i).PROPORTION_C, aACS_FINANCIAL_CURRENCY_ID);
          PJAmount_FC_C   :=
                    ACS_FUNCTION.RoundAmount(Amount_FC_C * tblDistribution(i).PROPORTION_D, aACS_FINANCIAL_CURRENCY_ID);
          PJAmount_EUR_D  := ACS_FUNCTION.RoundNear(Amount_EUR_D * tblDistribution(i).PROPORTION_C, 0.001, 0);
          PJAmount_EUR_C  := ACS_FUNCTION.RoundNear(Amount_EUR_C * tblDistribution(i).PROPORTION_D, 0.001, 0);
        end if;

        select init_id_seq.nextval
          into MGMDistributionId
          from dual;

        insert into ACT_MGM_DISTRIBUTION
                    (ACT_MGM_DISTRIBUTION_ID
                   , ACS_PJ_ACCOUNT_ID
                   , ACS_SUB_SET_ID
                   , MGM_AMOUNT_LC_D
                   , MGM_AMOUNT_LC_C
                   , MGM_AMOUNT_FC_D
                   , MGM_AMOUNT_FC_C
                   , MGM_AMOUNT_EUR_D
                   , MGM_AMOUNT_EUR_C
                   , MGM_DESCRIPTION
                   , ACT_MGM_IMPUTATION_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (MGMDistributionId
                   , tblDistribution(j).ACS_PJ_ACCOUNT_ID
                   , ACT_CREATION_SBVR.GetSubSetOfAccount(tblDistribution(j).ACS_PJ_ACCOUNT_ID)
                   , PJAmount_LC_D
                   , PJAmount_LC_C
                   , PJAmount_FC_D
                   , PJAmount_FC_C
                   , PJAmount_EUR_D
                   , PJAmount_EUR_C
                   , aIMM_DESCRIPTION
                   , MGMImputationId
                   , trunc(sysdate)
                   , aA_IDCRE
                    );

        --Màj info compl.
        UpdateInfoImpMGM(MGMDistributionId);
        PJTotAmount_LC_D   := PJTotAmount_LC_D - PJAmount_LC_D;
        PJTotAmount_LC_C   := PJTotAmount_LC_C - PJAmount_LC_C;
        PJTotAmount_FC_D   := PJTotAmount_FC_D - PJAmount_FC_D;
        PJTotAmount_FC_C   := PJTotAmount_FC_C - PJAmount_FC_C;
        PJTotAmount_EUR_D  := PJTotAmount_EUR_D - PJAmount_EUR_D;
        PJTotAmount_EUR_C  := PJTotAmount_EUR_C - PJAmount_EUR_C;
      end loop;
    end loop;
  end CreateMANImputations;

--------------------------
  function ExtVatOnDeduction(
    aACT_DOCUMENT_ID      in     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aCAT_EXT_VAT_DISCOUNT in out ACJ_CATALOGUE_DOCUMENT.CAT_EXT_VAT_DISCOUNT%type
  )
    return ACJ_CATALOGUE_DOCUMENT.CAT_EXT_VAT%type
  is
    CatExtVAT ACJ_CATALOGUE_DOCUMENT.CAT_EXT_VAT%type;
  begin
    begin
      -- recherche si récuperation de taxe
      select CAT.CAT_EXT_VAT
           , CAT_EXT_VAT_DISCOUNT
        into CatExtVAT
           , aCAT_EXT_VAT_DISCOUNT
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID;
    exception
      when no_data_found then
        CatExtVAT              := 0;
        aCAT_EXT_VAT_DISCOUNT  := 0;
    end;

    if CatExtVAT is null then
      CatExtVAT  := 0;
    end if;

    if aCAT_EXT_VAT_DISCOUNT is null then
      aCAT_EXT_VAT_DISCOUNT  := 0;
    end if;

    return CatExtVAT;
  end ExtVatOnDeduction;

----------------------
  function IsManDocument(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return number
  is
    CatalogId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    Ok        number(1)                                               := 1;
  begin
    begin
      -- recherche si catalogue gére analytique
      select DOC.ACJ_CATALOGUE_DOCUMENT_ID
        into CatalogId
        from ACJ_SUB_SET_CAT CAT
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_SUB_SET = 'CPN';
    exception
      when no_data_found then
        Ok  := 0;
    end;

    return Ok;
  end IsManDocument;

----------------------
  function IsPartnerInDumpPartners(aPAC_PERSON_ID PAC_PERSON.PAC_PERSON_ID%type)
    return number
  is
    PartnerId PAC_PERSON.PAC_PERSON_ID%type;
    Ok        number(1)                       := 1;
  begin
    -- recherche si partenaire est utilisé pour client poubelle
    select max(PAC_CUSTOM_PARTNER_ID)
      into PartnerId
      from ACS_FIN_ACC_S_PAYMENT
     where PAC_CUSTOM_PARTNER_ID = aPAC_PERSON_ID;

    if PartnerId is null then
      Ok  := 0;
    end if;

    return Ok;
  end IsPartnerInDumpPartners;

---------------------------------------
  procedure MgmUniqueImputationProportion(
    aCDA_ACCOUNT_ID                     ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aPF_ACOUNT_ID                       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aPJ_ACOUNT_ID                       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , atblMgmImputations           in out tblMgmImputationsTyp
  , atblMgmDistribution          in out tblMgmDistributionTyp
  , aACT_FINANCIAL_IMPUTATION_ID        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type default null
  )
  is
  begin
    atblMgmImputations.delete;
    atblMgmDistribution.delete;

    if    aCDA_ACCOUNT_ID is not null
       or aPF_ACOUNT_ID is not null then
      atblMgmImputations(1).ACT_MGM_IMPUTATION_ID  := 1;
      atblMgmImputations(1).ACS_CDA_ACCOUNT_ID     := aCDA_ACCOUNT_ID;
      atblMgmImputations(1).ACS_PF_ACCOUNT_ID      := aPF_ACOUNT_ID;
      atblMgmImputations(1).PROPORTION_D           := 1;
      atblMgmImputations(1).PROPORTION_C           := 1;

      --Recherche du DOC_RECORD_ID de la plus grande imputation analytique
      if aACT_FINANCIAL_IMPUTATION_ID is not null then
        select min(doc_record_id)
          into atblMgmImputations(1).DOC_RECORD_ID
          from (select   mgm.doc_record_id
                    from act_mgm_imputation mgm
                   where mgm.act_financial_imputation_id = aACT_FINANCIAL_IMPUTATION_ID
                order by (mgm.imm_amount_lc_d + mgm.imm_amount_lc_c) desc)
         where rownum = 1;
      end if;

      if aPJ_ACOUNT_ID is not null then
        atblMgmDistribution(1).ACT_MGM_IMPUTATION_ID  := 1;
        atblMgmDistribution(1).ACS_PJ_ACCOUNT_ID      := aPJ_ACOUNT_ID;
        atblMgmDistribution(1).MGM_AMOUNT_LC_D        := 1;
        atblMgmDistribution(1).MGM_AMOUNT_LC_C        := 1;   -- La proportion est calculée plus tard
      --  atblMgmDistribution(1).PROPORTION_D          := 1;
      --  atblMgmDistribution(1).PROPORTION_C          := 1;
      end if;
    end if;
  end MgmUniqueImputationProportion;

----------------------------------
  procedure MgmImputationsProportion(
    aACT_FINANCIAL_IMPUTATION_ID        ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , atblMgmImputations           in out tblMgmImputationsTyp
  , atblMgmDistribution          in out tblMgmDistributionTyp
  )
  is
    cursor MgmImputationsCursor(
      aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
    )
    is
      select   MGM.*
             , DIS.ACS_PJ_ACCOUNT_ID
             , DIS.MGM_AMOUNT_LC_D
             , DIS.MGM_AMOUNT_LC_C
          from ACT_MGM_IMPUTATION MGM
             , ACT_MGM_DISTRIBUTION DIS
         where MGM.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID
           and MGM.ACT_MGM_IMPUTATION_ID = DIS.ACT_MGM_IMPUTATION_ID(+)
      order by MGM.ACT_MGM_IMPUTATION_ID;

    MgmImputations  MgmImputationsCursor%rowtype;
    i               binary_integer                                  := 0;
    j               binary_integer                                  := 0;
    TotAmountD      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    TotAmountC      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    MgmImputationId ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
  -----
  begin
    TotAmountD  := 0;
    TotAmountC  := 0;
    atblMgmImputations.delete;
    atblMgmDistribution.delete;

    open MgmImputationsCursor(aACT_FINANCIAL_IMPUTATION_ID);

    fetch MgmImputationsCursor
     into MgmImputations;

    while MgmImputationsCursor%found loop
      if    (MgmImputationId is null)
         or (MgmImputationId <> MgmImputations.ACT_MGM_IMPUTATION_ID) then
        i                                            := i + 1;
        MgmImputationId                              := MgmImputations.ACT_MGM_IMPUTATION_ID;
        TotAmountD                                   := TotAmountD + MgmImputations.IMM_AMOUNT_LC_D;
        TotAmountC                                   := TotAmountC + MgmImputations.IMM_AMOUNT_LC_C;
        atblMgmImputations(i).ACT_MGM_IMPUTATION_ID  := MgmImputations.ACT_MGM_IMPUTATION_ID;
        atblMgmImputations(i).ACS_CDA_ACCOUNT_ID     := MgmImputations.ACS_CDA_ACCOUNT_ID;
        atblMgmImputations(i).ACS_PF_ACCOUNT_ID      := MgmImputations.ACS_PF_ACCOUNT_ID;
        atblMgmImputations(i).DOC_RECORD_ID          := MgmImputations.DOC_RECORD_ID;
        atblMgmImputations(i).IMM_AMOUNT_LC_D        := MgmImputations.IMM_AMOUNT_LC_D;
        atblMgmImputations(i).IMM_AMOUNT_LC_C        := MgmImputations.IMM_AMOUNT_LC_C;
      end if;

      if MgmImputations.ACS_PJ_ACCOUNT_ID is not null then
        j                                             := j + 1;
        atblMgmDistribution(i).ACT_MGM_IMPUTATION_ID  := MgmImputations.ACT_MGM_IMPUTATION_ID;
        atblMgmDistribution(i).ACS_PJ_ACCOUNT_ID      := MgmImputations.ACS_PJ_ACCOUNT_ID;
        atblMgmDistribution(i).MGM_AMOUNT_LC_D        := MgmImputations.MGM_AMOUNT_LC_D;
        atblMgmDistribution(i).MGM_AMOUNT_LC_C        := MgmImputations.MGM_AMOUNT_LC_C;
      end if;

      fetch MgmImputationsCursor
       into MgmImputations;
    end loop;

    close MgmImputationsCursor;

    -- CALCUL DE LA TABLE DES PROPORTIONS
    for i in 1 .. atblMgmImputations.count loop
      begin
        atblMgmImputations(i).PROPORTION_D  := atblMgmImputations(i).IMM_AMOUNT_LC_D / TotAmountD;
      exception
        when zero_divide then
          atblMgmImputations(i).PROPORTION_D  := 0;
      end;

      begin
        atblMgmImputations(i).PROPORTION_C  := atblMgmImputations(i).IMM_AMOUNT_LC_C / TotAmountC;
      exception
        when zero_divide then
          atblMgmImputations(i).PROPORTION_C  := 0;
      end;
/*
      if atblMgmImputations(i).PROPORTION_D > MaxPropD then
        MaxPropD     := atblMgmImputations(i).PROPORTION_D;
        MaxPositionD := i;
      end if;
      if atblMgmImputations(i).PROPORTION_C > MaxPropC then
        MaxPropC     := atblMgmImputations(i).PROPORTION_C;
        MaxPositionC := i;
      end if;
*/
    end loop;
/*
    -- DEPLACEMENT DE LA PROPORTION LA PLUS GRANDE EN DERNIERE POSITION
    if atblMgmImputations.Count > 0 then
      if MaxAmountD <> atblMgmImputations(atblMgmImputations.last).PROPORTION_D then
        astlCDA.Exchange(0, MaxPropIndex);
        astlPF.Exchange(0, MaxPropIndex);
        astlProp.Exchange(0, MaxPropIndex);
        astlAmount.Exchange(0, MaxPropIndex);
        astlMGMImputation.Exchange(0, MaxPropIndex);
      end;
*/
  end MgmImputationsProportion;

-----------------------------------
  procedure MgmDistributionProportion(
    aACT_MGM_IMPUTATION_ID        ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type
  , atblSource                    tblMgmDistributionTyp
  , atblTarget             in out tblMgmDistributionTyp
  )
  is
    cpt        number(12)                                  := 0;
    TotAmountD ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_D%type;
    TotAmountC ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_C%type;
  -----
  begin
    TotAmountD  := 0;
    TotAmountC  := 0;
    atblTarget.delete;

    for i in 1 .. atblSource.count loop
      if atblSource(i).ACT_MGM_IMPUTATION_ID = aACT_MGM_IMPUTATION_ID then
        cpt                                    := cpt + 1;
        atblTarget(cpt).ACT_MGM_IMPUTATION_ID  := atblSource(i).ACT_MGM_IMPUTATION_ID;
        atblTarget(cpt).ACS_PJ_ACCOUNT_ID      := atblSource(i).ACS_PJ_ACCOUNT_ID;
        atblTarget(cpt).MGM_AMOUNT_LC_D        := atblSource(i).MGM_AMOUNT_LC_D;
        atblTarget(cpt).MGM_AMOUNT_LC_C        := atblSource(i).MGM_AMOUNT_LC_C;
        TotAmountD                             := atblSource(i).MGM_AMOUNT_LC_D;
        TotAmountC                             := atblSource(i).MGM_AMOUNT_LC_C;
      end if;
    end loop;

    for i in 1 .. atblTarget.count loop
      begin
        atblTarget(i).PROPORTION_D  := atblTarget(i).MGM_AMOUNT_LC_D / TotAmountD;
      exception
        when zero_divide then
          atblTarget(i).PROPORTION_D  := 0;
      end;

      begin
        atblTarget(i).PROPORTION_C  := atblTarget(i).MGM_AMOUNT_LC_C / TotAmountC;
      exception
        when zero_divide then
          atblTarget(i).PROPORTION_C  := 0;
      end;
    end loop;
  end MgmDistributionProportion;

-------------------------------
  procedure CreateMgmVatImputations(
    aOriginImputationId            ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID     ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_PERIOD_ID                 ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , aACT_DOCUMENT_ID               ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID   ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aIMM_TYPE                      ACT_MGM_IMPUTATION.IMM_TYPE%type
  , aIMM_GENRE                     ACT_MGM_IMPUTATION.IMM_GENRE%type
  , aIMM_DESCRIPTION               ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type
  , aIMM_PRIMARY                   ACT_MGM_IMPUTATION.IMM_PRIMARY%type
  , aIMM_AMOUNT_LC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type
  , aIMM_AMOUNT_LC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type
  , aIMM_EXCHANGE_RATE             ACT_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type
  , aIMM_BASE_PRICE                ACT_MGM_IMPUTATION.IMM_BASE_PRICE%type
  , aIMM_AMOUNT_FC_D               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type
  , aIMM_AMOUNT_FC_C               ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type
  , aIMM_AMOUNT_EUR_D              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type
  , aIMM_AMOUNT_EUR_C              ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type
  , aIMM_VALUE_DATE                ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type
  , aIMM_TRANSACTION_DATE          ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type
  , aA_IDCRE                       ACT_MGM_IMPUTATION.A_IDCRE%type
  )
  is
    CpnAccountId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    QtyAccountId       ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    tblMgmImputations  tblMgmImputationsTyp;
    tblMgmDistribution tblMgmDistributionTyp;
  begin
    CpnAccountId  := GetCPNAccOfFINAcc(aACS_FINANCIAL_ACCOUNT_ID);

    if CpnAccountId is not null then
      if GetVatMgmAccounts(CpnAccountId, aOriginImputationId, QtyAccountId, tblMgmImputations, tblMgmDistribution) = 1 then
        CreateMANImputations(aACS_FINANCIAL_ACCOUNT_ID
                           , CpnAccountId
                           , QtyAccountId
                           , tblMgmImputations
                           , tblMgmDistribution
                           , aACS_FINANCIAL_CURRENCY_ID
                           , aACS_ACS_FINANCIAL_CURRENCY_ID
                           , aACS_PERIOD_ID
                           , aACT_DOCUMENT_ID
                           , aACT_FINANCIAL_IMPUTATION_ID
                           , aIMM_TYPE
                           , aIMM_GENRE
                           , aIMM_DESCRIPTION
                           , aIMM_PRIMARY
                           , aIMM_AMOUNT_LC_D
                           , aIMM_AMOUNT_LC_C
                           , aIMM_EXCHANGE_RATE
                           , aIMM_BASE_PRICE
                           , aIMM_AMOUNT_FC_D
                           , aIMM_AMOUNT_FC_C
                           , aIMM_AMOUNT_EUR_D
                           , aIMM_AMOUNT_EUR_C
                           , aIMM_VALUE_DATE
                           , aIMM_TRANSACTION_DATE
                           , aA_IDCRE
                            );
      end if;
    end if;
  end CreateMgmVatImputations;

-------------------------------
  procedure UpdateExpiryOfSelection(
    aACT_ETAT_EVENT_ID in ACT_EXPIRY_SELECTION.ACT_ETAT_EVENT_ID%type
  , aC_SUB_SET         in ACJ_SUB_SET_CAT.C_SUB_SET%type
  )
  is
  begin
    update ACT_EXPIRY_SELECTION
       set ACT_EXPIRY_SELECTION.ACT_EXPIRY_ID =
             (select min(ACT_EXPIRY.ACT_EXPIRY_ID)
                from ACT_DOCUMENT
                   , ACJ_CATALOGUE_DOCUMENT
                   , ACT_PART_IMPUTATION
                   , ACJ_SUB_SET_CAT
                   , ACT_EXPIRY
               where ACT_EXPIRY.EXP_CALC_NET + 0 = 1
                 and ACT_EXPIRY.ACT_PART_IMPUTATION_ID = ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID
                 and ACT_DOCUMENT.ACT_DOCUMENT_ID = ACT_EXPIRY.ACT_DOCUMENT_ID
                 and ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID = ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
                 and ACJ_SUB_SET_CAT.C_SUB_SET = aC_SUB_SET
                 and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
                 and ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE not in ('3', '4')
                 and ACT_EXPIRY.EXP_REF_BVR = ACT_EXPIRY_SELECTION.EXS_REFERENCE
                 and IsPartnerInDumpPartners(ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID) = 0)
     where ACT_EXPIRY_SELECTION.ACT_ETAT_EVENT_ID = aACT_ETAT_EVENT_ID;
  end UpdateExpiryOfSelection;

-------------------------------
  function TestExercice(
    aACT_DOCUMENT_ID in ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDATE            in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  )
    return number
  is
    result ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
  begin
    select min(ACS_FINANCIAL_YEAR.FYE_START_DATE)
      into result
      from ACS_FINANCIAL_YEAR
         , ACT_DOCUMENT
     where ACT_DOCUMENT.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
       and ACT_DOCUMENT.ACS_FINANCIAL_YEAR_ID = ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID
       and ACS_FINANCIAL_YEAR.FYE_START_DATE <= trunc(aDATE);

    if result is null then
      return 0;
    else
      return 1;
    end if;
  end TestExercice;

-------------------------------
  procedure CalcVAT(
    aBaseInfoRec       in out ACT_VAT_MANAGEMENT.BaseInfoRecType
  , aInfoVATRec        in out ACT_VAT_MANAGEMENT.InfoVATRecType
  , aCalcVATRec        in out ACT_VAT_MANAGEMENT.CalcVATRecType
  , aACT_DOCUMENT_ID2  in     number
  , aTAX_RATE          in     number
  , aTAX_EXCHANGE_RATE in     number default null
  , aDET_BASE_PRICE    in     number default null
  )
  is
    BillValueDate ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
    ImpValueDate  ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
    VatAmoutFC    ACT_DET_TAX.TAX_VAT_AMOUNT_FC%type;
    Flag          boolean                                        := true;
  begin
    select C_TYPE_CATALOGUE
         , ACT_VAT_MANAGEMENT.GetIEOfJobType(ACJ_JOB_TYPE_ID)
      into aBaseInfoRec.TypeCatalogue
         , aBaseInfoRec.IE
      from ACT_JOB
         , ACT_DOCUMENT
         , ACJ_CATALOGUE_DOCUMENT
     where ACT_DOCUMENT.ACT_DOCUMENT_ID = aBaseInfoRec.DocumentId
       and ACT_DOCUMENT.ACT_JOB_ID = ACT_JOB.ACT_JOB_ID
       and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

    --si catalogue spécifie HT -> on force la saisie des montants en TTC
    if aBaseInfoRec.IE = 'E' then
      aBaseInfoRec.AmountsIE  := 'I';
    end if;

    Flag                    :=     Flag
                               and ACT_VAT_MANAGEMENT.GetInfoVAT(aBaseInfoRec, aInfoVATRec);

    if aTAX_RATE != 0 then
      aInfoVATRec.Rate  := aTAX_RATE;
    end if;

    --Le calcule TVA (recherche cours de change) se fait avec la date de la facture
    select max(IMF_VALUE_DATE)
      into BillValueDate
      from ACT_FINANCIAL_IMPUTATION
     where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID2
       and IMF_PRIMARY = 1;

    ImpValueDate            := aBaseInfoRec.ValueDate;

    if BillValueDate is not null then
      aBaseInfoRec.ValueDate  := BillValueDate;
    end if;

    if     nvl(aTAX_EXCHANGE_RATE, 0) != 0
       and nvl(aDET_BASE_PRICE, 0) != 0 then
      aCalcVATRec.ExchangeRate  := aTAX_EXCHANGE_RATE;
      aCalcVATRec.BasePrice     := aDET_BASE_PRICE;
    end if;

    Flag                    :=     Flag
                               and ACT_VAT_MANAGEMENT.CalcVAT(aBaseInfoRec, aInfoVATRec, aCalcVATRec);
    aBaseInfoRec.ValueDate  := ImpValueDate;

    if (aCalcVATRec.Amount_LC <> 0) then
      --màj des montants pour HT
      if aCalcVATRec.IE = 'E' then
        --Si monnaie décompte TVA <> monnaie de l'écriture, on calcule en fonction du montant TVA dans la monnaie
        -- de l'écriture (Amount_BC)
        if aCalcVATRec.UseVatDetAccountCurrency then
          VatAmoutFC := aCalcVATRec.Amount_BC;
        else
          VatAmoutFC := aCalcVATRec.Amount_FC;
        end if;

        --Recalcule du montant soumis
        if aBaseInfoRec.AmountD_LC != 0 then
          aBaseInfoRec.AmountD_LC   := aBaseInfoRec.AmountD_LC - aCalcVATRec.Amount_LC;
          aBaseInfoRec.AmountD_FC   := aBaseInfoRec.AmountD_FC - VatAmoutFC;
          aBaseInfoRec.AmountD_EUR  := aBaseInfoRec.AmountD_EUR - aCalcVATRec.Amount_EUR;
        else
          aBaseInfoRec.AmountC_LC   := aBaseInfoRec.AmountC_LC + aCalcVATRec.Amount_LC;
          aBaseInfoRec.AmountC_FC   := aBaseInfoRec.AmountC_FC + VatAmoutFC;
          aBaseInfoRec.AmountC_EUR  := aBaseInfoRec.AmountC_EUR + aCalcVATRec.Amount_EUR;
        end if;

        --Recalcule du montant soumis
        if aBaseInfoRec.AmountD_LC != 0 then
          aCalcVATRec.LiabledAmount  :=
                        ACT_VAT_MANAGEMENT.CalcLiabledAmount(aBaseInfoRec.AmountD_LC, aInfoVATRec, aCalcVATRec.IE, 'E');
        else
          aCalcVATRec.LiabledAmount  :=
                       ACT_VAT_MANAGEMENT.CalcLiabledAmount(-aBaseInfoRec.AmountC_LC, aInfoVATRec, aCalcVATRec.IE, 'E');
        end if;
      end if;
    end if;
  end CalcVAT;

  procedure InitPayInfoImputation(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
  is
    vcatalogue_document_id ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
  begin
    -- recherche du catalogue
    select max(ACJ_CATALOGUE_DOCUMENT_ID)
      into vcatalogue_document_id
      from ACT_DOCUMENT DOC
     where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    -- recherche des info géreé pour le catalogue
    InfoImputationManaged                                  := ACT_IMP_MANAGEMENT.GetManagedData(vcatalogue_document_id);
    -- on active systématiquement le dossier
    InfoImputationManaged.primary.DOC_RECORD_ID.managed    := true;
    InfoImputationManaged.Secondary.DOC_RECORD_ID.managed  := true;
    RecoverInfoImputation                                  := InfoImputationManaged.managed;
  end InitPayInfoImputation;

  procedure GetInfoImputationExpiry(aACT_EXPIRY_ID ACT_EXPIRY.ACT_EXPIRY_ID%type)
  is
    vTypeCatalogue      ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
    vOriginImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vDocumentId         ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
  begin
    if RecoverInfoImputation then
      -- recherche du type de catalogue et du document id
      select max(CAT.C_TYPE_CATALOGUE)
           , max(DOC.ACT_DOCUMENT_ID)
        into vTypeCatalogue
           , vDocumentId
        from ACT_DOCUMENT DOC
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_EXPIRY EXP
       where DOC.ACT_DOCUMENT_ID = EXP.ACT_DOCUMENT_ID
         and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
         and EXP.ACT_EXPIRY_ID = aACT_EXPIRY_ID;

      -- si on est dans un paiement auto
      if vTypeCatalogue = '4' then
        select min(IMP.ACT_FINANCIAL_IMPUTATION_ID)
          into vOriginImputationId
          from ACT_FINANCIAL_IMPUTATION IMP,
               ACT_EXPIRY EXP
         where IMP.ACT_PART_IMPUTATION_ID = EXP.ACT_PART_IMPUTATION_ID
           and EXP.ACT_EXPIRY_ID = aACT_EXPIRY_ID
           and IMP.IMF_TYPE = 'MAN'
           and IMP.C_GENRE_TRANSACTION = '1';
      else
        vOriginImputationId := null;
      end if;

      if vOriginImputationId is null then
        select max(ACT_FINANCIAL_IMPUTATION_ID)
          into vOriginImputationId
          from (  select IMP.ACT_FINANCIAL_IMPUTATION_ID
                    from ACS_FINANCIAL_ACCOUNT FIN, ACT_FINANCIAL_IMPUTATION IMP
                   where IMP.ACT_DOCUMENT_ID = vDocumentId
                         and IMP.ACS_FINANCIAL_ACCOUNT_ID =
                                FIN.ACS_FINANCIAL_ACCOUNT_ID
                         and FIN.FIN_COLLECTIVE = 0
                         and IMP.IMF_TYPE = 'MAN'
                         and IMP.C_GENRE_TRANSACTION = '1'
                order by (IMP.IMF_AMOUNT_LC_D + IMP.IMF_AMOUNT_LC_C) desc)
         where rownum = 1;
      end if;

      -- récupération des données compl. facture
      ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMF(vOriginImputationId, InfoImputationValuesExpiry);
      -- Màj (null) des champs non gérés
      ACT_IMP_MANAGEMENT.UpdateManagedValues(InfoImputationValuesExpiry, InfoImputationManaged.Secondary);
    end if;
  end GetInfoImputationExpiry;

  procedure GetInfoImputationPrimary(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
  is
    vPrimaryImpId  ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
  begin
    select nvl(max(ACT_FINANCIAL_IMPUTATION_ID),0)
    into vPrimaryImpId
    from ACT_FINANCIAL_IMPUTATION
    where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
      and IMF_PRIMARY + 0 = 1;

    InfoImputationValuesExpiry := null;

    -- récupération des données compl. facture
    ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMF(vPrimaryImpId, InfoImputationValuesExpiry);
    -- Màj (null) des champs non gérés
    ACT_IMP_MANAGEMENT.UpdateManagedValues(InfoImputationValuesExpiry, InfoImputationManaged.Secondary);
  end GetInfoImputationPrimary;

  function GetInfoImp return ACT_IMP_MANAGEMENT.InfoImputationValuesRecType
  is
  begin
    if RecoverInfoImputation then
      return InfoImputationValuesExpiry;
    else
      return null;
    end if;
  end GetInfoImp;

  procedure UpdateInfoImpIMF(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
  is
  begin
    if RecoverInfoImputation then
      ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(aACT_FINANCIAL_IMPUTATION_ID, InfoImputationValuesExpiry);
    end if;
  end UpdateInfoImpIMF;

  procedure ResetImfDocRecordId(in_ActFinancialImputationId ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
  is
  begin
    update ACT_FINANCIAL_IMPUTATION
    set DOC_RECORD_ID = null
    where  ACT_FINANCIAL_IMPUTATION_ID = in_ActFinancialImputationId;
  exception
    when OTHERS then
      return;
  end ResetImfDocRecordId;

  procedure UpdateInfoImpIMM(
    aACT_MGM_IMPUTATION_ID ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type
  , aDOC_RECORD_ID         ACT_MGM_IMPUTATION.DOC_RECORD_ID%type default null
  )
  is
    vInfoImputationValuesExpiry ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
  begin
    if RecoverInfoImputation then
      --Si on passe un dossier en paramètre, on utilise celui-là
      vInfoImputationValuesExpiry  := InfoImputationValuesExpiry;

      if     aDOC_RECORD_ID is not null
         and InfoImputationManaged.Secondary.DOC_RECORD_ID.managed then
        vInfoImputationValuesExpiry.DOC_RECORD_ID  := aDOC_RECORD_ID;
      end if;

      ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMM(aACT_MGM_IMPUTATION_ID, vInfoImputationValuesExpiry);
    end if;
  end UpdateInfoImpIMM;

  procedure UpdateInfoImpMGM(aACT_MGM_DISTRIBUTION_ID ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type)
  is
  begin
    if RecoverInfoImputation then
      ACT_IMP_MANAGEMENT.SetInfoImputationValuesMGM(aACT_MGM_DISTRIBUTION_ID, InfoImputationValuesExpiry);
    end if;
  end UpdateInfoImpMGM;

  procedure ResetImmDocRecordId(in_ActMgmImputationId ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type)
  is
  begin
    update ACT_MGM_IMPUTATION
    set DOC_RECORD_ID = null
    where  ACT_MGM_IMPUTATION_ID = in_ActMgmImputationId;
  exception
    when OTHERS then
      return;
  end ResetImmDocRecordId;
  /**
  * Description
  *    Création d'une imputation pour frais de relance.
  **/
  procedure CREATE_REMINDER_CHARGES_SBVR(
    aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID               ACS_PERIOD.ACS_PERIOD_ID%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aVatDescription              ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aNumDocument                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aIMF_EXCHANGE_RATE           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_EUR                  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aA_IDCRE                     ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aACT_PART_IMPUTATION_ID      ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aPAC_REMAINDER_CATEGORY_ID   PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type
  , aACS_TAX_CODE_ID             ACS_TAX_CODE.ACS_TAX_CODE_ID%type
  )
  is
    FinImputation_id   ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vDefAccounts       ACS_DEF_ACCOUNT.DefAccountsRecType;
    vDefAccountsId     ACS_DEF_ACCOUNT.DefAccountsIdRecType;
    vAmount_LC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    vAmount_FC_C       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    vAmount_EUR_C      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vAmount_LC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    vAmount_FC_D       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    vAmount_EUR_D      ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    vChargesDefAccId   ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type;
    vChargeVATAccId    ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    BaseInfoRec        ACT_VAT_MANAGEMENT.BaseInfoRecType;
    InfoVATRec         ACT_VAT_MANAGEMENT.InfoVATRecType;
    CalcVATRec         ACT_VAT_MANAGEMENT.CalcVATRecType;
    vFinancialId       ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    vDivisionId        ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vCPNId             ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type;
    tblMgmImputations  tblMgmImputationsTyp;
    tblMgmDistribution tblMgmDistributionTyp;
    vDefValues         ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vInitValues        ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vTest              boolean;
    vACS_SUB_SET_ID    ACS_SUB_SET.ACS_SUB_SET_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputation_id
      from dual;

    -- Mise à null du sub_set pour savoir si on prend les comptes des comptes
    --  par défaut ou des comptes frais du sous-ensemble
    vACS_SUB_SET_ID  := null;

    if aPAC_REMAINDER_CATEGORY_ID is not null then
      --Recherche compte par défaut
      select ACS_DEF_ACC_CHARGE_ID
        into vChargesDefAccId
        from PAC_REMAINDER_CATEGORY
       where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID;
    else
      select min(ACS_DEFAULT_ACCOUNT_ID)
        into vChargesDefAccId
        from ACS_DEFAULT_ACCOUNT
       where C_DEFAULT_ELEMENT_TYPE = '08'
         and DEF_DEFAULT = 1;

      if vChargesDefAccId is null then
        select ACS_SUB_SET_ID
          into vACS_SUB_SET_ID
          from ACS_ACCOUNT
         where ACS_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID;

        InitDefAccountsIdFromCharges(vACS_SUB_SET_ID, vDefAccountsId);
      end if;
    end if;

    if aAmount_LC < 0 then
      --Intérêt due
      vAmount_LC_D   := -aAmount_LC;
      vAmount_FC_D   := -aAmount_FC;
      vAmount_EUR_D  := -aAmount_EUR;
      vAmount_LC_C   := 0;
      vAmount_FC_C   := 0;
      vAmount_EUR_C  := 0;
    else
      --Intérêt
      vAmount_LC_C   := aAmount_LC;
      vAmount_FC_C   := aAmount_FC;
      vAmount_EUR_C  := aAmount_EUR;
      vAmount_LC_D   := 0;
      vAmount_FC_D   := 0;
      vAmount_EUR_D  := 0;
    end if;

    -- recherche des comptes par défaut pour les frais
    if vACS_SUB_SET_ID is null then
      ACS_DEF_ACCOUNT.GetAccountOfHeader(vChargesDefAccId, aIMF_TRANSACTION_DATE, null, vDefAccounts);
      ACS_DEF_ACCOUNT.GetDefAccountsId(vDefAccounts, vDefAccountsId);
    end if;

    vFinancialId     := vDefAccountsId.DEF_FIN_ACCOUNT_ID;
    vDivisionId      := vDefAccountsId.DEF_DIV_ACCOUNT_ID;

    if ACT_VAT_MANAGEMENT.GetFinVATPossible(vFinancialId) = 1 then
      vChargeVATAccId  := aACS_TAX_CODE_ID;

      if vChargeVATAccId is not null then
        BaseInfoRec.TaxCodeId        := vChargeVATAccId;
        BaseInfoRec.PeriodId         := aACS_PERIOD_ID;
        BaseInfoRec.DocumentId       := aACT_DOCUMENT_ID;
        BaseInfoRec.primary          := 0;
        BaseInfoRec.AmountD_LC       := vAmount_LC_D;
        BaseInfoRec.AmountC_LC       := vAmount_LC_C;
        BaseInfoRec.AmountD_FC       := vAmount_FC_D;
        BaseInfoRec.AmountC_FC       := vAmount_FC_C;
        BaseInfoRec.AmountD_EUR      := vAmount_EUR_D;
        BaseInfoRec.AmountC_EUR      := vAmount_EUR_C;
        BaseInfoRec.ExchangeRate     := 0;
        BaseInfoRec.BasePrice        := 0;
        BaseInfoRec.ValueDate        := aIMF_VALUE_DATE;
        BaseInfoRec.TransactionDate  := aIMF_TRANSACTION_DATE;
        BaseInfoRec.FinCurrId_FC     := aACS_FINANCIAL_CURRENCY_ID;
        BaseInfoRec.FinCurrId_LC     := AF_ACS_FINANCIAL_CURRENCY_ID;
        BaseInfoRec.PartImputId      := aACT_PART_IMPUTATION_ID;
        CalcVATRec.Encashment        := 0;
        ACT_CREATION_SBVR.CalcVAT(BaseInfoRec, InfoVATRec, CalcVATRec, null, 0);
        vAmount_LC_D                 := BaseInfoRec.AmountD_LC;
        vAmount_LC_C                 := BaseInfoRec.AmountC_LC;
        vAmount_FC_D                 := BaseInfoRec.AmountD_FC;
        vAmount_FC_C                 := BaseInfoRec.AmountC_FC;
        vAmount_EUR_D                := BaseInfoRec.AmountD_EUR;
        vAmount_EUR_C                := BaseInfoRec.AmountC_EUR;
      end if;
    end if;

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
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
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputation_id
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , vFinancialId
               , 'MAN'
               , 0
               , aDescription
               , vAmount_LC_D
               , vAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , vAmount_FC_D
               , vAmount_FC_C
               , vAmount_EUR_D
               , vAmount_EUR_C
               , aIMF_VALUE_DATE
               , vChargeVATAccId
               , aIMF_TRANSACTION_DATE
               , null
               , null
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , AF_ACS_FINANCIAL_CURRENCY_ID
               , '6'
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    UpdateInfoImpIMF(FinImputation_id);
    CREATE_FIN_DISTRI_BVR(FinImputation_id
                        , aDescription
                        , vAmount_LC_D
                        , vAmount_LC_C
                        , vAmount_FC_D
                        , vAmount_FC_C
                        , vAmount_EUR_D
                        , vAmount_EUR_C
                        , vFinancialId
                        , aACS_AUXILIARY_ACCOUNT_ID   -- aACS_AUXILIARY_ACCOUNT_ID,
                        , null
                        , aA_IDCRE
                        , aIMF_TRANSACTION_DATE
                        , 1
                        , vDivisionId
                         );

    if ExistMAN <> 0 then
      vCPNId  := vDefAccountsId.DEF_CPN_ACCOUNT_ID;

      --Recherche si compte fin. lié à un compte cpn
      if vCPNId is null then
        vCPNId  := GetCPNAccountIdOfFIN(vFinancialId);
      end if;

      if vCPNId is not null then
        vDefValues.CDAAccId  := vDefAccountsId.DEF_CDA_ACCOUNT_ID;
        vDefValues.PFAccId   := vDefAccountsId.DEF_PF_ACCOUNT_ID;
        vDefValues.PJAccId   := vDefAccountsId.DEF_PJ_ACCOUNT_ID;
        --Contrôle et recherche info manquante dans les interactions
        vTest                := ACT_MGM_MANAGEMENT.ReInitialize(vCPNId, aIMF_TRANSACTION_DATE, vDefValues, vInitValues);

        if (   vInitValues.CDAAccId is not null
            or vInitValues.PFAccId is not null) then
          MgmUniqueImputationProportion(vInitValues.CDAAccId
                                      , vInitValues.PFAccId
                                      , vInitValues.PJAccId
                                      , tblMgmImputations
                                      , tblMgmDistribution
                                      , null
                                       );
          CreateMANImputations(vFinancialId
                             , vCPNId
                             , vDefAccountsId.DEF_QTY_ACCOUNT_ID
                             , tblMgmImputations
                             , tblMgmDistribution
                             , aACS_FINANCIAL_CURRENCY_ID
                             , AF_ACS_FINANCIAL_CURRENCY_ID
                             , aACS_PERIOD_ID
                             , aACT_DOCUMENT_ID
                             , FinImputation_id
                             , 'MAN'
                             , '6'
                             , aDescription
                             , 0
                             , vAmount_LC_D
                             , vAmount_LC_C
                             , aIMF_EXCHANGE_RATE
                             , aIMF_BASE_PRICE
                             , vAmount_FC_D
                             , vAmount_FC_C
                             , vAmount_EUR_D
                             , vAmount_EUR_C
                             , aIMF_VALUE_DATE
                             , aIMF_TRANSACTION_DATE
                             , aA_IDCRE
                              );
        else
          raise_application_error(-20000, 'PCS - Error permission of analytic imputation.');
        end if;
      end if;
    end if;

    if vChargeVATAccId is not null then
      ACT_CREATION_SBVR.CREATE_VAT_SBVR(FinImputation_id
                                      , vChargeVATAccId
                                      , 0
                                      , InfoVATRec.PreaAccId
                                      , 100
                                      , aVatDescription
                                      , aNumDocument
                                      , null
                                      , aACS_AUXILIARY_ACCOUNT_ID
                                      , aA_IDCRE
                                      , BaseInfoRec
                                      , InfoVATRec
                                      , CalcVATRec
                                       );
    end if;
  end CREATE_REMINDER_CHARGES_SBVR;

  /**
  * Description
  *    Création d'une imputation pour intérêt relance.
  **/
  procedure CREATE_REMINDER_INTEREST_SBVR(
    aACT_DOCUMENT_ID             ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID               ACS_PERIOD.ACS_PERIOD_ID%type
  , aIMF_TRANSACTION_DATE        ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE              ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                 ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aAmount_LC                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aIMF_EXCHANGE_RATE           ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_BASE_PRICE              ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aAmount_FC                   ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aAmount_EUR                  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aACS_FINANCIAL_CURRENCY_ID   ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aF_ACS_FINANCIAL_CURRENCY_ID ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aA_IDCRE                     ACT_FINANCIAL_IMPUTATION.A_IDCRE%type
  , aACT_PART_IMPUTATION_ID      ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aPAC_REMAINDER_CATEGORY_ID   PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type
  )
  is
    FinImputation_id         ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    vDefAccounts             ACS_DEF_ACCOUNT.DefAccountsRecType;
    vDefAccountsId           ACS_DEF_ACCOUNT.DefAccountsIdRecType;
    vAmount_LC_C             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    vAmount_FC_C             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    vAmount_EUR_C            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type;
    vAmount_LC_D             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    vAmount_FC_D             ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    vAmount_EUR_D            ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    vInterestAssetsDefAccId  ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type;
    vInterestLiabledDefAccId ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type;
    vDefAccountId            ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type;
    vFinancialId             ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    vDivisionId              ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vCPNId                   ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type;
    tblMgmImputations        tblMgmImputationsTyp;
    tblMgmDistribution       tblMgmDistributionTyp;
    vDefValues               ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vInitValues              ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vTest                    boolean;
    vACS_SUB_SET_ID          ACS_SUB_SET.ACS_SUB_SET_ID%type;
  begin
    select init_id_seq.nextval
      into FinImputation_id
      from dual;

    -- Mise à null du sub_set pour savoir si on prend les comptes des comptes
    --  par défaut ou des comptes frais du sous-ensemble
    vACS_SUB_SET_ID  := null;

    if aPAC_REMAINDER_CATEGORY_ID is not null then
      --Recherche compte par défaut
      select ACS_DEF_ACC_ASSETS_ID
           , ACS_DEF_ACC_LIABIL_ID
        into vInterestAssetsDefAccId
           , vInterestLiabledDefAccId
        from PAC_REMAINDER_CATEGORY
       where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID;
    else
      select min(ACS_DEFAULT_ACCOUNT_ID)
        into vInterestAssetsDefAccId
        from ACS_DEFAULT_ACCOUNT
       where C_DEFAULT_ELEMENT_TYPE = '05'
         and DEF_DEFAULT = 1;

      if vInterestAssetsDefAccId is null then
        select ACS_SUB_SET_ID
          into vACS_SUB_SET_ID
          from ACS_ACCOUNT
         where ACS_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID;

        InitDefAccountsIdFromCharges(vACS_SUB_SET_ID, vDefAccountsId);
      end if;

      vInterestLiabledDefAccId  := vInterestAssetsDefAccId;
    end if;

    if aAmount_LC < 0 then
      --Intérêt due
      vAmount_LC_D   := -aAmount_LC;
      vAmount_FC_D   := -aAmount_FC;
      vAmount_EUR_D  := -aAmount_EUR;
      vAmount_LC_C   := 0;
      vAmount_FC_C   := 0;
      vAmount_EUR_C  := 0;
      vDefAccountId  := vInterestAssetsDefAccId;
    else
      --Intérêt
      vAmount_LC_C   := aAmount_LC;
      vAmount_FC_C   := aAmount_FC;
      vAmount_EUR_C  := aAmount_EUR;
      vAmount_LC_D   := 0;
      vAmount_FC_D   := 0;
      vAmount_EUR_D  := 0;
      vDefAccountId  := vInterestLiabledDefAccId;
    end if;

    -- recherche des comptes par défaut
    if vACS_SUB_SET_ID is null then
      ACS_DEF_ACCOUNT.GetAccountOfHeader(vDefAccountId, aIMF_TRANSACTION_DATE, null, vDefAccounts);
      ACS_DEF_ACCOUNT.GetDefAccountsId(vDefAccounts, vDefAccountsId);
    end if;

    vFinancialId     := vDefAccountsId.DEF_FIN_ACCOUNT_ID;
    vDivisionId      := vDefAccountsId.DEF_DIV_ACCOUNT_ID;

    insert into ACT_FINANCIAL_IMPUTATION
                (ACT_FINANCIAL_IMPUTATION_ID
               , ACS_PERIOD_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , IMF_TYPE
               , IMF_PRIMARY
               , IMF_DESCRIPTION
               , IMF_AMOUNT_LC_D
               , IMF_AMOUNT_LC_C
               , IMF_EXCHANGE_RATE
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
               , IMF_BASE_PRICE
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_GENRE_TRANSACTION
               , IMF_NUMBER
               , A_DATECRE
               , A_IDCRE
               , ACT_PART_IMPUTATION_ID
                )
         values (FinImputation_id
               , aACS_PERIOD_ID
               , aACT_DOCUMENT_ID
               , vFinancialId
               , 'MAN'
               , 0
               , aDescription
               , vAmount_LC_D
               , vAmount_LC_C
               , aIMF_EXCHANGE_RATE
               , vAmount_FC_D
               , vAmount_FC_C
               , vAmount_EUR_D
               , vAmount_EUR_C
               , aIMF_VALUE_DATE
               , null
               , aIMF_TRANSACTION_DATE
               , null
               , null
               , 'STD'
               , aIMF_BASE_PRICE
               , aACS_FINANCIAL_CURRENCY_ID
               , AF_ACS_FINANCIAL_CURRENCY_ID
               , '5'
               , null
               , trunc(sysdate)
               , aA_IDCRE
               , aACT_PART_IMPUTATION_ID
                );

    --Màj info compl.
    UpdateInfoImpIMF(FinImputation_id);
    CREATE_FIN_DISTRI_BVR(FinImputation_id
                        , aDescription
                        , vAmount_LC_D
                        , vAmount_LC_C
                        , vAmount_FC_D
                        , vAmount_FC_C
                        , vAmount_EUR_D
                        , vAmount_EUR_C
                        , vFinancialId
                        , aACS_AUXILIARY_ACCOUNT_ID   -- aACS_AUXILIARY_ACCOUNT_ID,
                        , null
                        , aA_IDCRE
                        , aIMF_TRANSACTION_DATE
                        , 1
                        , vDivisionId
                         );

    if ExistMAN <> 0 then
      vCPNId  := vDefAccountsId.DEF_CPN_ACCOUNT_ID;

      --Recherche si compte fin. lié à un compte cpn
      if vCPNId is null then
        vCPNId  := GetCPNAccountIdOfFIN(vFinancialId);
      end if;

      if vCPNId is not null then
        vDefValues.CDAAccId  := vDefAccountsId.DEF_CDA_ACCOUNT_ID;
        vDefValues.PFAccId   := vDefAccountsId.DEF_PF_ACCOUNT_ID;
        vDefValues.PJAccId   := vDefAccountsId.DEF_PJ_ACCOUNT_ID;
        --Contrôle et recherche info manquante dans les interactions
        vTest                := ACT_MGM_MANAGEMENT.ReInitialize(vCPNId, aIMF_TRANSACTION_DATE, vDefValues, vInitValues);

        if (   vInitValues.CDAAccId is not null
            or vInitValues.PFAccId is not null) then
          MgmUniqueImputationProportion(vInitValues.CDAAccId
                                      , vInitValues.PFAccId
                                      , vInitValues.PJAccId
                                      , tblMgmImputations
                                      , tblMgmDistribution
                                      , null
                                       );
          CreateMANImputations(vFinancialId
                             , vCPNId
                             , vDefAccountsId.DEF_QTY_ACCOUNT_ID
                             , tblMgmImputations
                             , tblMgmDistribution
                             , aACS_FINANCIAL_CURRENCY_ID
                             , AF_ACS_FINANCIAL_CURRENCY_ID
                             , aACS_PERIOD_ID
                             , aACT_DOCUMENT_ID
                             , FinImputation_id
                             , 'MAN'
                             , '5'
                             , aDescription
                             , 0
                             , vAmount_LC_D
                             , vAmount_LC_C
                             , aIMF_EXCHANGE_RATE
                             , aIMF_BASE_PRICE
                             , vAmount_FC_D
                             , vAmount_FC_C
                             , vAmount_EUR_D
                             , vAmount_EUR_C
                             , aIMF_VALUE_DATE
                             , aIMF_TRANSACTION_DATE
                             , aA_IDCRE
                              );
        else
          raise_application_error(-20000, 'PCS - Error permission of analytic imputation.');
        end if;
      end if;
    end if;
  end CREATE_REMINDER_INTEREST_SBVR;

  procedure UpdateStatusReminders(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type)
  is
  begin
    --Màj statut relance à '4'
    update ACT_REMINDER
       set C_REM_STATUS_CHARGE = decode(C_REM_STATUS_CHARGE, '2', '4', C_REM_STATUS_CHARGE)
         , C_REM_STATUS_INTEREST = decode(C_REM_STATUS_INTEREST, '2', '4', C_REM_STATUS_INTEREST)
     where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;
  end UpdateStatusReminders;

  procedure UpdatePaymentSelection(aACT_EXPIRY_ID ACT_EXPIRY.ACT_EXPIRY_ID%type)
  is
    vExpPayId ACT_EXPIRY_PAYMENT.ACT_EXPIRY_PAYMENT_ID%type;
  begin
    select min(ACT_EXPIRY_PAYMENT_ID)
      into vExpPayId
      from ACT_EXPIRY_PAYMENT
     where ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and C_STATUS_PAYMENT = '0';

    --Màj de la table LSV+
    if vExpPayId is not null then
      update ACT_EXPIRY_PAYMENT
         set C_STATUS_PAYMENT = '1'
       where ACT_EXPIRY_PAYMENT_ID = vExpPayId;
    end if;
  end UpdatePaymentSelection;
end ACT_CREATION_SBVR;
