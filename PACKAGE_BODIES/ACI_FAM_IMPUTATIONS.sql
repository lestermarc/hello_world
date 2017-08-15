--------------------------------------------------------
--  DDL for Package Body ACI_FAM_IMPUTATIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_FAM_IMPUTATIONS" 
is

  /**
  * Description  Transfert des mouvements immobilisations (FAM) vers l'interface Finance (ACI)
  */
  procedure FAM_to_ACI_Transfer(aFAM_JOURNAL_ID FAM_JOURNAL.FAM_JOURNAL_ID%type)
  is
    cursor DocumentsToTransferCursor(aFAM_JOURNAL_ID FAM_JOURNAL.FAM_JOURNAL_ID%type) is
       select
             DOC.FAM_DOCUMENT_ID,
             DOC.FDO_DOCUMENT_DATE,
             DOC.ACS_FINANCIAL_CURRENCY_ID,
             DOC.FDO_INT_NUMBER,
             DOC.FDO_AMOUNT,
             FCAT.C_FAM_TRANSACTION_TYP,
             JSA.ACJ_JOB_TYPE_S_CATALOGUE_ID,
             CAT.CAT_KEY,
             TYP.TYP_KEY,
             TYP.C_ACI_FINANCIAL_LINK,
             CAT.C_TYPE_PERIOD,
             DECODE(CPN.ACJ_CATALOGUE_DOCUMENT_ID,NULL, 0,1) CPN,
             DECODE(ACC.ACJ_CATALOGUE_DOCUMENT_ID,NULL, 0,1) ACC
        from
             (select ACJ_CATALOGUE_DOCUMENT_ID
              from   ACJ_SUB_SET_CAT
              where  C_SUB_SET = 'CPN') CPN,
             (select ACJ_CATALOGUE_DOCUMENT_ID
              from   ACJ_SUB_SET_CAT
              where  C_SUB_SET = 'ACC') ACC,
             ACJ_JOB_TYPE             TYP,
             ACJ_CATALOGUE_DOCUMENT   CAT,
             ACJ_JOB_TYPE_S_CATALOGUE JSA,
             FAM_CATALOGUE            FCAT,
             FAM_DOCUMENT             DOC
        where
              DOC.FAM_JOURNAL_ID                = aFAM_JOURNAL_ID
          and DOC.FAM_CATALOGUE_ID              = FCAT.FAM_CATALOGUE_ID
          and FCAT.ACJ_JOB_TYPE_S_CATALOGUE2_ID = JSA.ACJ_JOB_TYPE_S_CATALOGUE_ID
          and JSA.ACJ_CATALOGUE_DOCUMENT_ID     = CAT.ACJ_CATALOGUE_DOCUMENT_ID
          and JSA.ACJ_JOB_TYPE_ID               = TYP.ACJ_JOB_TYPE_ID
          and JSA.ACJ_CATALOGUE_DOCUMENT_ID     = CPN.ACJ_CATALOGUE_DOCUMENT_ID(+)
          and JSA.ACJ_CATALOGUE_DOCUMENT_ID     = ACC.ACJ_CATALOGUE_DOCUMENT_ID(+)
        order by DOC.FDO_INT_NUMBER ;

    DocumentsToTransfer DocumentsToTransferCursor%rowtype;
    DocumentId          ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    vACIDocumentAmount  ACI_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type; --Réceptionne le montant avec lequel on met à jour le montant document ACI
    -------
    function CreateDocument(aDocumentsToTransfer DocumentsToTransferCursor%rowtype) return ACI_DOCUMENT.ACI_DOCUMENT_ID%type
    is
      DocumentId     ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
      NoExercise     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;
      CurrencyName   ACI_DOCUMENT.CURRENCY%type;
      TransactionKey ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type;
      TypKey         ACJ_JOB_TYPE.TYP_KEY%type;
      YearId         ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    begin
      YearId := ACS_FUNCTION.GetFinancialYearID(trunc(aDocumentsToTransfer.FDO_DOCUMENT_DATE));
      -- Lecture des textes selon la config de reprise des textes
      if upper(PCS.PC_CONFIG.GetConfig('FIN_TEXT_RECOVERING')) = 'TRUE' then
        NoExercise     := ACS_FUNCTION.GetFinancialYearNo(trunc(aDocumentsToTransfer.FDO_DOCUMENT_DATE));
        CurrencyName   := ACS_FUNCTION.GetCurrencyName(aDocumentsToTransfer.ACS_FINANCIAL_CURRENCY_ID);
        TransactionKey := aDocumentsToTransfer.CAT_KEY;
        TypKey         := aDocumentsToTransfer.TYP_KEY;
      end if;

      select ACI_ID_SEQ.NextVal into DocumentId from dual;

      insert into ACI_DOCUMENT
       (ACI_DOCUMENT_ID,
        C_INTERFACE_ORIGIN,
        C_INTERFACE_CONTROL,
        ACJ_JOB_TYPE_S_CATALOGUE_ID,
        DOC_NUMBER,
        DOC_TOTAL_AMOUNT_DC,
        DOC_DOCUMENT_DATE,
        ACS_FINANCIAL_CURRENCY_ID,
        CURRENCY,
        ACS_FINANCIAL_YEAR_ID,
        FYE_NO_EXERCICE,
        C_STATUS_DOCUMENT,
        CAT_KEY,
        TYP_KEY,
        DOC_CHARGES_LC,
        DOC_COMMENT,
        DOC_CCP_TAX,
        DOC_ORDER_NO,
        DOC_EFFECTIVE_DATE,
        DOC_EXECUTIVE_DATE,
        DOC_ESTABL_DATE,
        ACT_DOCUMENT_ID,
        ACS_FINANCIAL_ACCOUNT_ID,
        ACC_NUMBER,
        COM_OLE_ID,
        DIC_DOC_SOURCE_ID,
        DIC_DOC_DESTINATION_ID,
        DOC_INTEGRATION_DATE,
        C_FAIL_REASON,
        DOC_TOTAL_AMOUNT_EUR,
        ACI_CONVERSION_ID,
        DOC_DOCUMENT_ID,
        ACS_ACS_FINANCIAL_CURRENCY_ID,
        VAT_CURRENCY,
        ACJ_JOB_TYPE_S_CAT_PMT_ID,
        DOC_PAID_AMOUNT_LC,
        DOC_PAID_AMOUNT_FC,
        CAT_KEY_PMT,
        DOC_PAID_AMOUNT_EUR,
        FAM_DOCUMENT_ID,
        A_DATECRE,
        A_IDCRE)
      values
       (DocumentId,
        '3', -- C_INTERFACE_ORIGIN -> Autre
        '3', -- C_INTERFACE_CONTROL -> A contrôler
        aDocumentsToTransfer.ACJ_JOB_TYPE_S_CATALOGUE_ID,
        aDocumentsToTransfer.FDO_INT_NUMBER,
        aDocumentsToTransfer.FDO_AMOUNT,
        aDocumentsToTransfer.FDO_DOCUMENT_DATE,
        aDocumentsToTransfer.ACS_FINANCIAL_CURRENCY_ID,
        CurrencyName,
        YearId,
        NoExercise,
        'DEF',
        TransactionKey,
        TypKey,
        null, -- DOC_CHARGES_LC,
        null, -- DOC_COMMENT,
        null, -- DOC_CCP_TAX,
        null, -- DOC_ORDER_NO,
        null, -- DOC_EFFECTIVE_DATE,
        null, -- DOC_EXECUTIVE_DATE,
        null, -- DOC_ESTABL_DATE,
        null, -- ACT_DOCUMENT_ID,
        null, -- ACS_FINANCIAL_ACCOUNT_ID,
        null, -- ACC_NUMBER,
        null, -- COM_OLE_ID,
        null, -- DIC_DOC_SOURCE_ID,
        null, -- DIC_DOC_DESTINATION_ID,
        null, -- DOC_INTEGRATION_DATE,
        null, -- C_FAIL_REASON,
        null, -- DOC_TOTAL_AMOUNT_EUR,
        null, -- ACI_CONVERSION_ID,
        null, -- DOC_DOCUMENT_ID,
        null, -- ACS_ACS_FINANCIAL_CURRENCY_ID,
        null, -- VAT_CURRENCY,
        null, -- ACJ_JOB_TYPE_S_CAT_PMT_ID,
        null, -- DOC_PAID_AMOUNT_LC,
        null, -- DOC_PAID_AMOUNT_FC,
        null, -- CAT_KEY_PMT,
        null, -- DOC_PAID_AMOUNT_EUR,
        aDocumentsToTransfer.FAM_DOCUMENT_ID,
        trunc(sysdate),
        UserIni);

      return DocumentId;

    end CreateDocument;

    --------
    procedure CreateImputations(aDocumentsToTransfer DocumentsToTransferCursor%rowtype,
                                aACI_DOCUMENT_ID     ACI_DOCUMENT.ACI_DOCUMENT_ID%type)
    is
      cursor FAM_ImputationsCursor(aFAM_DOCUMENT_ID FAM_DOCUMENT.FAM_DOCUMENT_ID%type) is
        select
               IMP.FAM_IMPUTATION_ID,
               IMP.ACS_FINANCIAL_CURRENCY_ID,
               IMP.ACS_ACS_FINANCIAL_CURRENCY_ID,
               IMP.ACS_PERIOD_ID,
               IMP.FAM_JOURNAL_ID,
               IMP.FAM_FIXED_ASSETS_ID,
               IMP.FIM_DESCR,
               IMP.FIM_TRANSACTION_DATE,
               IMP.FIM_VALUE_DATE,
               IMP.FIM_EXCHANGE_RATE,
               IMP.FIM_BASE_PRICE,
               ACT.ACS_FINANCIAL_ACCOUNT_ID,
               ACT.ACS_DIVISION_ACCOUNT_ID,
               ACT.ACS_CPN_ACCOUNT_ID,
               ACT.ACS_CDA_ACCOUNT_ID,
               ACT.ACS_PF_ACCOUNT_ID,
               ACT.ACS_PJ_ACCOUNT_ID,
               ACT.GCO_GOOD_ID ,
               ACT.DOC_RECORD_ID,
               ACT.PAC_PERSON_ID,
               ACT.HRM_PERSON_ID,
               ACT.C_FAM_IMPUTATION_TYP,
               ACT.FIM_AMOUNT_LC_D ACT_FIM_AMOUNT_LC_D,
               ACT.FIM_AMOUNT_LC_C ACT_FIM_AMOUNT_LC_C,
               ACT.FIM_AMOUNT_FC_D ACT_FIM_AMOUNT_FC_D,
               ACT.FIM_AMOUNT_FC_C ACT_FIM_AMOUNT_FC_C,
               ACC.ACC_NUMBER,
               DIV.ACC_NUMBER DIV_NUMBER,
               CPN.ACC_NUMBER CPN_NUMBER,
               CDA.ACC_NUMBER CDA_NUMBER,
               PF.ACC_NUMBER  PF_NUMBER,
               PJ.ACC_NUMBER  PJ_NUMBER,
               decode(rownum, 1, 1, 0) IMF_PRIMARY
        from
             ACS_ACCOUNT        PJ,
             ACS_ACCOUNT        PF,
             ACS_ACCOUNT        CDA,
             ACS_ACCOUNT        CPN,
             ACS_ACCOUNT        DIV,
             ACS_ACCOUNT        ACC,
             FAM_ACT_IMPUTATION ACT,
             FAM_IMPUTATION     IMP
        where
              IMP.FAM_DOCUMENT_ID          = aFAM_DOCUMENT_ID
          and IMP.FAM_IMPUTATION_ID        = ACT.FAM_IMPUTATION_ID
          and ACT.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID (+)
          and ACT.ACS_DIVISION_ACCOUNT_ID  = DIV.ACS_ACCOUNT_ID (+)
          and ACT.ACS_CPN_ACCOUNT_ID       = CPN.ACS_ACCOUNT_ID (+)
          and ACT.ACS_CDA_ACCOUNT_ID       = CDA.ACS_ACCOUNT_ID (+)
          and ACT.ACS_PF_ACCOUNT_ID        = PF.ACS_ACCOUNT_ID (+)
          and ACT.ACS_PJ_ACCOUNT_ID        = PJ.ACS_ACCOUNT_ID (+)
       order by ACC.ACC_NUMBER asc;

      FAM_Imputations  FAM_ImputationsCursor%rowtype;
      ACI_ImputationId ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
      FAM_ImputationId FAM_IMPUTATION.FAM_IMPUTATION_ID%type;
      NoPeriod         ACS_PERIOD.PER_NO_PERIOD%type;
      FC_CurrencyName  ACI_FINANCIAL_IMPUTATION.CURRENCY1%type;
      LC_CurrencyName  ACI_FINANCIAL_IMPUTATION.CURRENCY2%type;
      ACCNumber        ACS_ACCOUNT.ACC_NUMBER%type;
      DIVNumber        ACS_ACCOUNT.ACC_NUMBER%type;
      CPNNumber        ACS_ACCOUNT.ACC_NUMBER%type;
      CDANumber        ACS_ACCOUNT.ACC_NUMBER%type;
      PFNumber         ACS_ACCOUNT.ACC_NUMBER%type;
      PJNumber         ACS_ACCOUNT.ACC_NUMBER%type;
      vPeriodId        ACI_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type;
      vAnalyticalSum_D ACI_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type; --Réceptionne somme montants débit des imputations du document uniquement analytique
      vAnalyticalSum_C ACI_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type; --Réceptionne somme montants crédit des imputations du document uniquement analytique
      vOnlyAnalytical  Boolean;                               --Indique si document est purement analytique (True) ou pas (false)
    ----
    begin
      vAnalyticalSum_D := 0;
      vAnalyticalSum_C := 0;

      open FAM_ImputationsCursor(aDocumentsToTransfer.FAM_DOCUMENT_ID);
      fetch FAM_ImputationsCursor into FAM_Imputations;

      if FAM_ImputationsCursor%found then
        FAM_ImputationId := FAM_Imputations.FAM_IMPUTATION_ID;
      end if;

      vOnlyAnalytical := true;
      while FAM_ImputationsCursor%found
      loop
        ACI_ImputationId := 0;
        /**
        * Période dépend de la date de transaction et du type de période géré du catalogue transaction
        * Si pas de période pour date et type spécifié, période de gestion à la date de transaction
        **/
        vPeriodId := ACS_FUNCTION.GetPeriodID(trunc(FAM_Imputations.FIM_TRANSACTION_DATE), aDocumentsToTransfer.C_TYPE_PERIOD);
        if vPeriodId is null then
          vPeriodId := ACS_FUNCTION.GetPeriodID(trunc(FAM_Imputations.FIM_TRANSACTION_DATE), '2');
        end if;

        -- lecture des textes selon la config de reprise des textes
        if upper(PCS.PC_CONFIG.GetConfig('FIN_TEXT_RECOVERING')) = 'TRUE' then
          NoPeriod        := ACS_FUNCTION.GetPerNumById(vPeriodId);
          FC_CurrencyName := ACS_FUNCTION.GetCurrencyName(FAM_Imputations.ACS_FINANCIAL_CURRENCY_ID);
          LC_CurrencyName := ACS_FUNCTION.GetCurrencyName(FAM_Imputations.ACS_ACS_FINANCIAL_CURRENCY_ID);
          ACCNumber       := FAM_Imputations.ACC_NUMBER;
          DIVNumber       := FAM_Imputations.DIV_NUMBER;
          CPNNumber       := FAM_Imputations.CPN_NUMBER;
          CDANumber       := FAM_Imputations.CDA_NUMBER;
          PFNumber        := FAM_Imputations.PF_NUMBER;
          PJNumber        := FAM_Imputations.PJ_NUMBER;
        end if;

        -- Les imputations financières ne sont transférées que si le catalogue finance le prévoit (ACJ_SUB_SET_CAT.C_SUB_SET = 'ACC')
        if aDocumentsToTransfer.ACC = 1 then
          vOnlyAnalytical := false;
          /** Le montant du document ACI est initialisé avec le montant de l'imputation "primaire"  **/
          if FAM_Imputations.IMF_PRIMARY  = 1 then
            if ACS_FUNCTION.GetLocalCurrencyId = aDocumentsToTransfer.acs_financial_currency_id then
              vACIDocumentAmount := abs(FAM_Imputations.ACT_FIM_AMOUNT_LC_D + FAM_Imputations.ACT_FIM_AMOUNT_LC_C);
            else
              vACIDocumentAmount := abs(FAM_Imputations.ACT_FIM_AMOUNT_FC_D + FAM_Imputations.ACT_FIM_AMOUNT_FC_C);
            end if;
          end if;

          select ACI_ID_SEQ.NextVal into ACI_ImputationId from dual;

          insert into ACI_FINANCIAL_IMPUTATION
           (ACI_FINANCIAL_IMPUTATION_ID,
            ACI_DOCUMENT_ID,
            IMF_TYPE,
            IMF_GENRE,
            IMF_PRIMARY,
            IMF_DESCRIPTION,
            IMF_AMOUNT_LC_D,
            IMF_AMOUNT_LC_C,
            IMF_EXCHANGE_RATE,
            IMF_BASE_PRICE,
            IMF_AMOUNT_FC_D,
            IMF_AMOUNT_FC_C,
            IMF_VALUE_DATE,
            IMF_TRANSACTION_DATE,
            ACS_DIVISION_ACCOUNT_ID,
            DIV_NUMBER,
            ACS_FINANCIAL_CURRENCY_ID,
            CURRENCY1,
            ACS_ACS_FINANCIAL_CURRENCY_ID,
            CURRENCY2,
            ACS_FINANCIAL_ACCOUNT_ID,
            ACC_NUMBER,
            ACS_PERIOD_ID,
            PER_NO_PERIOD,
            C_GENRE_TRANSACTION,
            FAM_FIXED_ASSETS_ID,
            C_FAM_TRANSACTION_TYP,
            ACI_PART_IMPUTATION_ID,
            TAX_EXCHANGE_RATE,
            DET_BASE_PRICE,
            TAX_INCLUDED_EXCLUDED,
            TAX_LIABLED_AMOUNT,
            TAX_LIABLED_RATE,
            TAX_RATE,
            TAX_VAT_AMOUNT_FC,
            TAX_VAT_AMOUNT_LC,
            TAX_REDUCTION,
            ACS_AUXILIARY_ACCOUNT_ID,
            AUX_NUMBER,
            ACS_TAX_CODE_ID,
            TAX_NUMBER,
            IMF_NUMBER,
            IMF_NUMBER2,
            IMF_TEXT1,
            IMF_TEXT2,
            IMF_AMOUNT_EUR_D,
            IMF_AMOUNT_EUR_C,
            TAX_VAT_AMOUNT_EUR,
            IMF_COMPARE_DATE,
            IMF_CONTROL_DATE,
            IMF_COMPARE_TEXT,
            IMF_CONTROL_TEXT,
            IMF_COMPARE_USE_INI,
            IMF_CONTROL_USE_INI,
            IMF_TEXT3,
            IMF_TEXT4,
            IMF_TEXT5,
            TAX_VAT_AMOUNT_VC,
            DIC_IMP_FREE1_ID,
            DIC_IMP_FREE2_ID,
            DIC_IMP_FREE3_ID,
            DIC_IMP_FREE4_ID,
            DIC_IMP_FREE5_ID,
            GCO_GOOD_ID,
            DOC_RECORD_ID,
            HRM_PERSON_ID,
            IMF_NUMBER3,
            IMF_NUMBER4,
            IMF_NUMBER5,
            PAC_PERSON_ID,
            A_DATECRE,
            A_IDCRE)
          values
           (ACI_ImputationId,
            aACI_DOCUMENT_ID,
            'MAN',
            'STD',
            FAM_Imputations.IMF_PRIMARY,
            FAM_Imputations.FIM_DESCR,
            FAM_Imputations.ACT_FIM_AMOUNT_LC_D,
            FAM_Imputations.ACT_FIM_AMOUNT_LC_C,
            FAM_Imputations.FIM_EXCHANGE_RATE,
            FAM_Imputations.FIM_BASE_PRICE,
            FAM_Imputations.ACT_FIM_AMOUNT_FC_D,
            FAM_Imputations.ACT_FIM_AMOUNT_FC_C,
            FAM_Imputations.FIM_VALUE_DATE,
            FAM_Imputations.FIM_TRANSACTION_DATE,
            FAM_Imputations.ACS_DIVISION_ACCOUNT_ID,
            DIVNumber,
            FAM_Imputations.ACS_FINANCIAL_CURRENCY_ID,
            FC_CurrencyName,
            FAM_Imputations.ACS_ACS_FINANCIAL_CURRENCY_ID,
            LC_CurrencyName,
            FAM_Imputations.ACS_FINANCIAL_ACCOUNT_ID,
            ACCNumber,
            vPeriodId,
            NoPeriod,
            '1',
            FAM_Imputations.FAM_FIXED_ASSETS_ID,
            aDocumentsToTransfer.C_FAM_TRANSACTION_TYP,
            null, -- ACI_PART_IMPUTATION_ID,
            null, -- TAX_EXCHANGE_RATE,
            null, -- DET_BASE_PRICE,
            null, -- TAX_INCLUDED_EXCLUDED,
            null, -- TAX_LIABLED_AMOUNT,
            null, -- TAX_LIABLED_RATE,
            null, -- TAX_RATE,
            null, -- TAX_VAT_AMOUNT_FC,
            null, -- TAX_VAT_AMOUNT_LC,
            null, -- TAX_REDUCTION,
            null, -- ACS_AUXILIARY_ACCOUNT_ID,
            null, -- AUX_NUMBER,
            null, -- ACS_TAX_CODE_ID,
            null, -- TAX_NUMBER,
            null, -- IMF_NUMBER,
            null, -- IMF_NUMBER2,
            null, -- IMF_TEXT1,
            null, -- IMF_TEXT2,
            null, -- IMF_AMOUNT_EUR_D,
            null, -- IMF_AMOUNT_EUR_C,
            null, -- TAX_VAT_AMOUNT_EUR,
            null, -- IMF_COMPARE_DATE,
            null, -- IMF_CONTROL_DATE,
            null, -- IMF_COMPARE_TEXT,
            null, -- IMF_CONTROL_TEXT,
            null, -- IMF_COMPARE_USE_INI,
            null, -- IMF_CONTROL_USE_INI,
            null, -- IMF_TEXT3,
            null, -- IMF_TEXT4,
            null, -- IMF_TEXT5,
            null, -- TAX_VAT_AMOUNT_VC,
            null, -- DIC_IMP_FREE1_ID,
            null, -- DIC_IMP_FREE2_ID,
            null, -- DIC_IMP_FREE3_ID,
            null, -- DIC_IMP_FREE4_ID,
            null, -- DIC_IMP_FREE5_ID,
            FAM_Imputations.GCO_GOOD_ID, -- GCO_GOOD_ID,
            FAM_Imputations.DOC_RECORD_ID, -- DOC_RECORD_ID,
            FAM_Imputations.HRM_PERSON_ID, -- HRM_PERSON_ID,
            null, -- IMF_NUMBER3,
            null, -- IMF_NUMBER4,
            null, -- IMF_NUMBER5,
            FAM_Imputations.PAC_PERSON_ID, -- PAC_PERSON_ID,
            trunc(sysdate),
            UserIni);
        end if;
        -- Les imputations analytiques ne sont transférées que si le catalogue finance le prévoit (ACJ_SUB_SET_CAT.C_SUB_SET = 'CPN')
        if aDocumentsToTransfer.CPN = 1 and (FAM_Imputations.ACS_CPN_ACCOUNT_ID is not null or
                                             FAM_Imputations.ACS_CDA_ACCOUNT_ID is not null or
                                             FAM_Imputations.ACS_PF_ACCOUNT_ID  is not null or
                                             FAM_Imputations.ACS_PJ_ACCOUNT_ID  is not null) then
          if ACS_FUNCTION.GetLocalCurrencyId = aDocumentsToTransfer.acs_financial_currency_id then
            vAnalyticalSum_D := vAnalyticalSum_D + FAM_Imputations.ACT_FIM_AMOUNT_LC_D;
            vAnalyticalSum_C := vAnalyticalSum_C + FAM_Imputations.ACT_FIM_AMOUNT_LC_C;
          else
            vAnalyticalSum_D := vAnalyticalSum_D + FAM_Imputations.ACT_FIM_AMOUNT_FC_D;
            vAnalyticalSum_C := vAnalyticalSum_C + FAM_Imputations.ACT_FIM_AMOUNT_FC_C;
          end if;
          insert into ACI_MGM_IMPUTATION
           (ACI_MGM_IMPUTATION_ID,
            ACI_DOCUMENT_ID,
            ACI_FINANCIAL_IMPUTATION_ID,
            IMM_TYPE,
            IMM_GENRE,
            IMM_PRIMARY,
            IMM_DESCRIPTION,
            IMM_AMOUNT_LC_D,
            IMM_AMOUNT_LC_C,
            IMM_EXCHANGE_RATE,
            IMM_BASE_PRICE,
            IMM_AMOUNT_FC_D,
            IMM_AMOUNT_FC_C,
            IMM_VALUE_DATE,
            IMM_TRANSACTION_DATE,
            ACS_FINANCIAL_CURRENCY_ID,
            CURRENCY1,
            ACS_ACS_FINANCIAL_CURRENCY_ID,
            CURRENCY2,
            ACS_CDA_ACCOUNT_ID,
            CDA_NUMBER,
            ACS_CPN_ACCOUNT_ID,
            CPN_NUMBER,
            ACS_PF_ACCOUNT_ID,
            PF_NUMBER,
            ACS_PJ_ACCOUNT_ID,
            PJ_NUMBER,
            ACS_PERIOD_ID,
            PER_NO_PERIOD,
            FAM_FIXED_ASSETS_ID,
            C_FAM_TRANSACTION_TYP,
            IMM_QUANTITY_D,
            IMM_QUANTITY_C,
            ACS_QTY_UNIT_ID,
            IMM_AMOUNT_EUR_D,
            IMM_AMOUNT_EUR_C,
            IMM_NUMBER,
            IMM_NUMBER2,
            IMM_TEXT1,
            IMM_TEXT2,
            IMM_TEXT3,
            IMM_TEXT4,
            IMM_TEXT5,
            DIC_IMP_FREE1_ID,
            DIC_IMP_FREE2_ID,
            DIC_IMP_FREE3_ID,
            DIC_IMP_FREE4_ID,
            DIC_IMP_FREE5_ID,
            DOC_RECORD_ID,
            GCO_GOOD_ID,
            HRM_PERSON_ID,
            IMM_NUMBER3,
            IMM_NUMBER4,
            IMM_NUMBER5,
            PAC_PERSON_ID,
            A_DATECRE,
            A_IDCRE)
          values
           (ACI_ID_SEQ.NextVal,
            aACI_DOCUMENT_ID,
            DECODE(ACI_ImputationId,0,NULL,ACI_ImputationId),
            'MAN',
            'STD',
            FAM_Imputations.IMF_PRIMARY,
            FAM_Imputations.FIM_DESCR,
            FAM_Imputations.ACT_FIM_AMOUNT_LC_D,
            FAM_Imputations.ACT_FIM_AMOUNT_LC_C,
            FAM_Imputations.FIM_EXCHANGE_RATE,
            FAM_Imputations.FIM_BASE_PRICE,
            FAM_Imputations.ACT_FIM_AMOUNT_FC_D,
            FAM_Imputations.ACT_FIM_AMOUNT_FC_C,
            FAM_Imputations.FIM_VALUE_DATE,
            FAM_Imputations.FIM_TRANSACTION_DATE,
            FAM_Imputations.ACS_FINANCIAL_CURRENCY_ID,
            FC_CurrencyName,
            FAM_Imputations.ACS_ACS_FINANCIAL_CURRENCY_ID,
            LC_CurrencyName,
            FAM_Imputations.ACS_CDA_ACCOUNT_ID,
            CDANumber,
            FAM_Imputations.ACS_CPN_ACCOUNT_ID,
            CPNNumber,
            FAM_Imputations.ACS_PF_ACCOUNT_ID,
            PFNumber,
            FAM_Imputations.ACS_PJ_ACCOUNT_ID,
            PJNumber,
            vPeriodId,
            NoPeriod,
            FAM_Imputations.FAM_FIXED_ASSETS_ID,
            aDocumentsToTransfer.C_FAM_TRANSACTION_TYP,
            null, -- IMM_QUANTITY_D,
            null, -- IMM_QUANTITY_C,
            null, -- ACS_QTY_UNIT_ID,
            null, -- IMM_AMOUNT_EUR_D,
            null, -- IMM_AMOUNT_EUR_C,
            null, -- IMM_NUMBER,
            null, -- IMM_NUMBER2,
            null, -- IMM_TEXT1,
            null, -- IMM_TEXT2,
            null, -- IMM_TEXT3,
            null, -- IMM_TEXT4,
            null, -- IMM_TEXT5,
            null, -- DIC_IMP_FREE1_ID,
            null, -- DIC_IMP_FREE2_ID,
            null, -- DIC_IMP_FREE3_ID,
            null, -- DIC_IMP_FREE4_ID,
            null, -- DIC_IMP_FREE5_ID,
            FAM_Imputations.DOC_RECORD_ID, -- DOC_RECORD_ID,
            FAM_Imputations.GCO_GOOD_ID, -- GCO_GOOD_ID,
            FAM_Imputations.HRM_PERSON_ID, -- HRM_PERSON_ID,
            null, -- IMM_NUMBER3,
            null, -- IMM_NUMBER4,
            null, -- IMM_NUMBER5,
            FAM_Imputations.PAC_PERSON_ID, -- PAC_PERSON_ID,
            trunc(sysdate),
            UserIni);
        end if;
        fetch FAM_ImputationsCursor into FAM_Imputations;
      end loop;
      close FAM_ImputationsCursor;
      /**  Si le document ne possède pas d'imputation financières, donc uniquement des imputations sur des comptes de sous-ensemble 'CPN' :
           Somme (sans traiter les zones en ABS) du débit -> si somme de crédit = 0
           Somme (sans traiter les zones en ABS) du crédit -> si somme de débit = 0
           Somme (sans traiter les zones en ABS) du débit -> si débit-crédit = 0
           Dans tous les autres cas, débit - crédit (sans traiter les zones en ABS)
      **/
      if vOnlyAnalytical then
        if vAnalyticalSum_D - vAnalyticalSum_C = 0 then
          vACIDocumentAmount := vAnalyticalSum_D;
        elsif  vAnalyticalSum_C = 0 then
          vACIDocumentAmount := vAnalyticalSum_D;
        elsif vAnalyticalSum_D = 0 then
          vACIDocumentAmount := vAnalyticalSum_C;
        else
          vACIDocumentAmount := vAnalyticalSum_D - vAnalyticalSum_C;
        end if;
      end if;

    end CreateImputations;

  -----
  begin
    open DocumentsToTransferCursor(aFAM_JOURNAL_ID);
    fetch DocumentsToTransferCursor into DocumentsToTransfer;
    while DocumentsToTransferCursor%found
    loop
      /** Création d'un document ACI pour chaque document FAM **/
      DocumentId := CreateDocument(DocumentsToTransfer);
      /** Création des imputations ACI sur la base des imputations du document FAM **/
      if DocumentId is not null then
        vACIDocumentAmount := 0;
        CreateImputations(DocumentsToTransfer, DocumentId);
        /* Le montant document est mis à jour selon le montant de l'imputation primaire*/
        update ACI_DOCUMENT
        set DOC_TOTAL_AMOUNT_DC = vACIDocumentAmount
        where ACI_DOCUMENT_ID = DocumentId;

        insert into ACI_DOCUMENT_STATUS (ACI_DOCUMENT_STATUS_ID,ACI_DOCUMENT_ID,C_ACI_FINANCIAL_LINK)
        values(ACI_ID_SEQ.NextVal,DocumentId,DocumentsToTransfer.C_ACI_FINANCIAL_LINK);
      end if;
      fetch DocumentsToTransferCursor into DocumentsToTransfer;
    end loop;
    close DocumentsToTransferCursor;
  end FAM_to_ACI_Transfer;

-- Initialisation des variables pour la session
-----
begin
  UserIni         := PCS.PC_I_LIB_SESSION.GetUserIni;
  LocalCurrencyId := ACS_FUNCTION.GetLocalCurrencyId;
end ACI_FAM_IMPUTATIONS;
