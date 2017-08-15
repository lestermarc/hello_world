--------------------------------------------------------
--  DDL for Package Body ACI_ASCII_DOCUMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_ASCII_DOCUMENT" 
is

  /**
  * Description
  *   Reprise d'un fichier de données
  */
  procedure Recover_file(conversion_id in number)
  is

    cursor file_documents(conversion_id number) is
      select
        A.DOC_NUMBER,
        A.CSO_JOIN_KEY
      from
        V_ACI_ASCII_DOCUMENT A
      where
        A.ACI_CONVERSION_ID = conversion_id
      order by A.ACI_CONVERSION_SOURCE_ID;

    file_documents_tuple file_documents%rowtype;
    i integer;

  begin

    -- ouverture d'un curseur sur les documents contenus dans un fichier de reprise
    open file_documents(conversion_id);
    fetch file_documents into file_documents_tuple;

    -- Intégration de tous les document du fichier de reprise
    while file_documents%found loop

      Write_Document_Interface(conversion_id, file_documents_tuple.CSO_JOIN_KEY);
      fetch file_documents into file_documents_tuple;

      commit;

    end loop;

    -- Met à jour la date de transfert, qui indique que le fichier à été repris dans l'interface
    update ACI_CONVERSION set CNV_TRANSFERT_DATE = sysdate where ACI_CONVERSION_ID = conversion_id;

    close file_documents;

    commit;

  end Recover_file;


  /**
  * Description
  *    procedure de création du document, de l'imputation partenaire et des échéances comptables
  */
  procedure Write_Document_Interface(
    conversion_id in number,
    join_key in varchar2)
  is

    -- curseur sur le document
    cursor document(conversion_id number, join_key varchar2) is
      select
        ACI_CONVERSION_ID,
        ACI_CONVERSION_SOURCE_ID,
        C_INTERFACE_ORIGIN,
        C_INTERFACE_CONTROL,
        ACJ_JOB_TYPE_S_CATALOGUE_ID,
        CAT_KEY,
        DOC_TOTAL_AMOUNT_DC,
        DOC_DOCUMENT_DATE,
        DOC_TRANSACTION_DATE,
        DOC_VALUE_DATE,
        CURRENCY,
        FYE_NO_EXERCICE,
        CTY_DOC_NUMBER,
        DOC_NUMBER,
        DOC_GRP_KEY,
        DOC_COMMENT,
        CAT_KEY_PMT,
        DOC_PAID_AMOUNT_LC,
        DOC_PAID_AMOUNT_FC,
        TYP_KEY
      from
        V_ACI_ASCII_DOCUMENT
      where
        ACI_CONVERSION_ID = conversion_id and
        CSO_JOIN_KEY = join_key;

    -- curseur sur les imputations partenaires
    cursor part_imputation_cursor(conversion_id number, join_key varchar2) is
      select
        NVL(PAR.PAR_DOCUMENT,PAR.DOC_NUMBER) DOC_NUMBER,
        PAR.PER_CUST_KEY1,
        PAR.PER_CUST_KEY2,
        PAR.PER_SUPP_KEY1,
        PAR.PER_SUPP_KEY2,
        PAR.CURRENCY1,
        PAR.CURRENCY2,
        PAR.PCO_DESCR,
        PAR.FRE_ACCOUNT_NUMBER,
        PAR.PAR_BLOCKED_DOCUMENT,
        PAR.PAR_REF_BVR,
        PAR.DES_DESCRIPTION_SUMMARY,
        PAR.IMF_BASE_PRICE,
        PAR.IMF_EXCHANGE_RATE
      from
        V_ACI_ASCII_PART_IMPUTATION PAR
      where
        PAR.ACI_CONVERSION_ID = conversion_id and
        PAR.CSO_JOIN_KEY = join_key;


    document_tuple document%ROWTYPE;
    part_tuple part_imputation_cursor%ROWTYPE;
    aci_financial_link ACJ_JOB_TYPE.C_ACI_FINANCIAL_LINK%TYPE;
    rate_of_exchange DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%TYPE;
    rate_factor DOC_DOCUMENT.DMT_BASE_PRICE%TYPE;
    part_imputation_id ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%TYPE;
    change_rate DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%TYPE;
    vDocumentId     ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    vDocumentNumber ACI_DOCUMENT.DOC_NUMBER%type;
  begin

    -- ouverture du curseur de document
    open document(conversion_id, join_key);
    fetch document into document_tuple;

    -- si on a pas d'enregistrement sur le curseur, il y a erreur
    if document_tuple.acj_job_type_s_catalogue_id is null
      or document%NOTFOUND then
      raise_application_error(-20001,'PCS - Document configuration does not allowed financial recover');
    end if;

    -- Recherche du type de catalogue transaction
    select MAX(C_ACI_FINANCIAL_LINK)
        into aci_financial_link
      from ACJ_CATALOGUE_DOCUMENT, ACJ_JOB_TYPE_S_CATALOGUE, ACJ_JOB_TYPE
      where ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID = document_tuple.acj_job_type_s_catalogue_id
        and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID
        and ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID;

    -- si on a trouve un document parametre pour le transfert en finance,
    -- on crée l'interface
    if document%found then

      --Reprise du numéro document uniquement si le flag l'indique
      if document_tuple.CTY_DOC_NUMBER = 1 then
        vDocumentNumber := document_tuple.DOC_NUMBER;
      else
        vDocumentNumber := '';
      end if;
      -- recherche d'un nouvel id unique pour le document que l'on va creer
      select ACI_ID_SEQ.nextval into vDocumentId from dual;
      -- Creation de l'entete du document interface
      Header_Interface(vDocumentId,
                       document_tuple.ACJ_JOB_TYPE_S_CATALOGUE_ID,
                       document_tuple.CAT_KEY,
                       vDocumentNumber,
                       document_tuple.DOC_TOTAL_AMOUNT_DC,
                       document_tuple.DOC_DOCUMENT_DATE,
                       document_tuple.DOC_COMMENT,
                       document_tuple.DOC_GRP_KEY,
                       document_tuple.CAT_KEY_PMT,
                       document_tuple.DOC_PAID_AMOUNT_LC,
                       document_tuple.DOC_PAID_AMOUNT_FC,
                       document_tuple.TYP_KEY,
                       document_tuple.CURRENCY,
                       document_tuple.FYE_NO_EXERCICE,
                       document_tuple.ACI_CONVERSION_ID);

      -- ouverture du curseur l'imputation partenaire
      open part_imputation_cursor(conversion_id, join_key);
      fetch part_imputation_cursor into part_tuple;
      if part_imputation_cursor%found then

        -- creation de l'imputation partenaire
        Third_Imputation(vDocumentId,
                         part_tuple.PER_CUST_KEY1,
                         part_tuple.PER_CUST_KEY2,
                         part_tuple.PER_SUPP_KEY1,
                         part_tuple.PER_SUPP_KEY2,
                         part_tuple.CURRENCY1,
                         part_tuple.CURRENCY2,
                         part_tuple.PCO_DESCR,
                         part_tuple.DES_DESCRIPTION_SUMMARY,
                         part_tuple.FRE_ACCOUNT_NUMBER,
                         part_tuple.DOC_NUMBER,
                         part_tuple.PAR_REF_BVR,
                         part_tuple.IMF_BASE_PRICE,
                         part_tuple.IMF_EXCHANGE_RATE,
                         part_imputation_id);

        -- creation des echeances de paiement
        Third_Expiry(join_key,
                     conversion_id,
                     part_imputation_id,
                     part_tuple.par_ref_bvr,
                     document_tuple.DOC_DOCUMENT_DATE);

        Third_Payment(join_key,
                      conversion_id,
                      part_imputation_id);
      end if;

      -- Création des imputations financières et analytiques liées
      Financial_Imputation(
        vDocumentId,
        conversion_id,
        join_key,
        NVL(document_tuple.DOC_TRANSACTION_DATE,document_tuple.DOC_DOCUMENT_DATE),
        NVL(document_tuple.DOC_VALUE_DATE,document_tuple.DOC_DOCUMENT_DATE),
        part_imputation_id);

      -- Création des imputations analytiques non liées à des imputations financières
      Mgm_Imputation(
        vDocumentId,
        conversion_id,
        join_key,
        NVL(document_tuple.DOC_TRANSACTION_DATE,document_tuple.DOC_DOCUMENT_DATE),
        NVL(document_tuple.DOC_VALUE_DATE,document_tuple.DOC_DOCUMENT_DATE),
        part_imputation_id);

      -- mise à jour du flag d'imputation financière du document
      update ACI_CONVERSION_SOURCE
         set CSO_TRANSFERT_DATE = SYSDATE
       where ACI_CONVERSION_ID = conversion_id and
             CSO_JOIN_KEY = join_key;

      -- création d'une position de status du document
      insert into ACI_DOCUMENT_STATUS(
        ACI_DOCUMENT_STATUS_ID,
        ACI_DOCUMENT_ID,
        C_ACI_FINANCIAL_LINK)
      values(
        ACI_ID_SEQ.nextval,
        vDocumentId,
        aci_financial_link);

      if aci_financial_link = '21' then
        commit;
      end if;

      close part_imputation_cursor;

    end if;

    -- fermeture du curseur sur le document
    close document;

  end Write_Document_Interface;


  /**
  * Description
  *    procedure de création de l'entête di document comptable
  */
  procedure Header_Interface(pDocumentId           ACI_DOCUMENT.ACI_DOCUMENT_ID%type,
                             pJobTypeCatId         ACI_DOCUMENT.ACJ_JOB_TYPE_S_CATALOGUE_ID%type,
                             pCatKey               ACI_DOCUMENT.CAT_KEY%type,
                             pDocNumber            ACI_DOCUMENT.DOC_NUMBER%type,
                             pDocAmount            ACI_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type,
                             pDocDate              ACI_DOCUMENT.DOC_DOCUMENT_DATE%type,
                             pDocComment           ACI_DOCUMENT.DOC_COMMENT%type,
                             pGrpKey               ACI_DOCUMENT.DOC_GRP_KEY%type,
                             pCatKeyPmt            ACI_DOCUMENT.CAT_KEY_PMT%type,
                             pPaidAmountLC         ACI_DOCUMENT.DOC_PAID_AMOUNT_LC%type,
                             pPaidAmountFC         ACI_DOCUMENT.DOC_PAID_AMOUNT_FC%type,
                             pTypKey               ACI_DOCUMENT.TYP_KEY%type,
                             pCurrency             ACI_DOCUMENT.CURRENCY%type,
                             pExerciseNumber       ACI_DOCUMENT.FYE_NO_EXERCICE%type,
                             pConversionId         ACI_DOCUMENT.ACI_CONVERSION_ID%type)
  is
  begin

    /*Création de l'entête document*/
    INSERT INTO ACI_DOCUMENT(ACI_DOCUMENT_ID,
                             C_INTERFACE_ORIGIN,
                             C_INTERFACE_CONTROL,
                             ACJ_JOB_TYPE_S_CATALOGUE_ID,
                             CAT_KEY,
                             DOC_TOTAL_AMOUNT_DC,
                             DOC_DOCUMENT_DATE,
                             DOC_COMMENT,
                             DOC_GRP_KEY,
                             CAT_KEY_PMT,
                             DOC_PAID_AMOUNT_LC,
                             DOC_PAID_AMOUNT_FC,
                             TYP_KEY,
                             CURRENCY,
                             VAT_CURRENCY,
                             FYE_NO_EXERCICE,
                             C_STATUS_DOCUMENT,
                             DOC_NUMBER,
                             ACI_CONVERSION_ID,
                             C_CURR_RATE_COVER_TYPE,
                             A_DATECRE,
                             A_IDCRE)
    VALUES(pDocumentId,
           '1',
           '3',
           pJobTypeCatId,
           pCatKey,
           NVL(pDocAmount,0),
           trunc(pDocDate),
           pDocComment,
           pGrpKey,
           pCatKeyPmt,
           pPaidAmountLC,
           pPaidAmountFC,
           pTypKey,
           pCurrency,
           pCurrency,
           pExerciseNumber,
           'DEF',
           pDocNumber,
           pConversionId,
           '00',
           sysdate,
           PCS.PC_I_LIB_SESSION.GetUserIni);

  end Header_Interface;

  /**
  * Description
  *   procedure de création de l'imputation partenaire
  */
  procedure Third_Imputation(pDocumentId               ACI_PART_IMPUTATION.ACI_DOCUMENT_ID%type,
                             pCustomKey1               ACI_PART_IMPUTATION.PER_CUST_KEY1%type,
                             pCustomKey2               ACI_PART_IMPUTATION.PER_CUST_KEY2%type,
                             pSupplierKey1             ACI_PART_IMPUTATION.PER_SUPP_KEY1%type,
                             pSupplierKey2             ACI_PART_IMPUTATION.PER_SUPP_KEY2%type,
                             pDocCurrency              ACI_PART_IMPUTATION.CURRENCY1%type,
                             pLocalCurrency            ACI_PART_IMPUTATION.CURRENCY2%type,
                             pPayConditionDescr        ACI_PART_IMPUTATION.PCO_DESCR%type,
                             pPmtMethodDescr           ACI_PART_IMPUTATION.DES_DESCRIPTION_SUMMARY%type,
                             pFinRefDescr              ACI_PART_IMPUTATION.FRE_ACCOUNT_NUMBER%type,
                             pDocNumber                ACI_PART_IMPUTATION.PAR_DOCUMENT%type,
                             pBVRRef                   ACI_PART_IMPUTATION.PAR_REF_BVR%type,
                             pBasePrice                ACI_PART_IMPUTATION.PAR_BASE_PRICE%type,
                             pExchangeRate             ACI_PART_IMPUTATION.PAR_EXCHANGE_RATE%type,
                             pPartImputationId  OUT    ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type)

  is
  begin

    -- Id de l'imputation que l'on va creer
    select ACI_ID_SEQ.nextval into pPartImputationId from DUAL;

    -- création de l'imputation primaire de l'interface comptable
    insert into ACI_PART_IMPUTATION(ACI_PART_IMPUTATION_ID,
                                    ACI_DOCUMENT_ID,
                                    PER_CUST_KEY1,
                                    PER_CUST_KEY2,
                                    PER_SUPP_KEY1,
                                    PER_SUPP_KEY2,
                                    CURRENCY1,
                                    CURRENCY2,
                                    PCO_DESCR,
                                    DES_DESCRIPTION_SUMMARY,
                                    FRE_ACCOUNT_NUMBER,
                                    PAR_DOCUMENT,
                                    PAR_BLOCKED_DOCUMENT,
                                    PAR_REF_BVR,
                                    PAR_BASE_PRICE,
                                    PAR_EXCHANGE_RATE,
                                    A_DATECRE,
                                    A_IDCRE)
    values(pPartImputationId,
           pDocumentId,
           pCustomKey1,
           pCustomKey2,
           pSupplierKey1,
           pSupplierKey2,
           pDocCurrency,
           pLocalCurrency,
           pPayConditionDescr,
           pPmtMethodDescr,
           pFinRefDescr,
           pDocNumber,
           0,
           pBVRRef,
           pBasePrice,
           pExchangeRate,
           sysdate,
           PCS.PC_I_LIB_SESSION.GetUserIni);

  end Third_Imputation;



  /**
  * Description
  *    procedure de creation des echeances de paiement
  */
  procedure Third_Expiry(
    join_key IN varchar2,
    conversion_id IN number,
    part_imputation_id IN number,
    ref_bvr IN varchar2,
    document_date IN date)
  is
    cursor expiry(conversion_id number, join_key varchar2) is
      select distinct
        ACI_CONVERSION_ID,
        C_STATUS_EXPIRY,
        DOC_NUMBER,
        EXP_SLICE,
        EXP_DATE_PMT_TOT,
        EXP_ADAPTED,
        EXP_CALCULATED,
        EXP_AMOUNT_LC,
        EXP_AMOUNT_FC,
        EXP_DISCOUNT_LC,
        EXP_DISCOUNT_FC,
        EXP_CALC_NET,
        EXP_REF_BVR
      from
        V_ACI_ASCII_EXPIRY
      where ACI_CONVERSION_ID = conversion_id and
            CSO_JOIN_KEY = join_key;

    expiry_tuple expiry%ROWTYPE;
    expiry_id ACI_EXPIRY.ACI_EXPIRY_ID%TYPE;
    reference_bvr ACI_EXPIRY.EXP_REF_BVR%type;
    bvr_coding_line DOC_PAYMENT_DATE.PAD_BVR_CODING_LINE%type;
    pmt_date date;

  begin

    open expiry(conversion_id, join_key);
    fetch expiry into expiry_tuple;

    -- boucle sur les échéances de paiement
    while expiry%found loop

      select ACI_ID_SEQ.nextval into expiry_id from dual;
                                                                                                                      -- création de l'echeance de payement
      insert into ACI_EXPIRY(
        ACI_EXPIRY_ID,
        ACI_PART_IMPUTATION_ID,
        C_STATUS_EXPIRY,
        EXP_DATE_PMT_TOT,
        EXP_SLICE,
        EXP_AMOUNT_LC,
        EXP_AMOUNT_FC,
        EXP_DISCOUNT_LC,
        EXP_DISCOUNT_FC,
        EXP_ADAPTED,
        EXP_CALCULATED,
--        EXP_BVR_CODE,
        EXP_REF_BVR,
        EXP_CALC_NET,
--        EXP_POURCENT,
--        ACS_FIN_ACC_S_PAYMENT_ID,
        A_DATECRE,
        A_IDCRE)
      values(
        expiry_id,
        part_imputation_id,
        expiry_tuple.C_STATUS_EXPIRY,
        expiry_tuple.EXP_DATE_PMT_TOT,
        expiry_tuple.EXP_SLICE,
        expiry_tuple.EXP_AMOUNT_LC,
        expiry_tuple.EXP_AMOUNT_FC,
        expiry_tuple.EXP_DISCOUNT_LC,
        expiry_tuple.EXP_DISCOUNT_FC,
        trunc(expiry_tuple.EXP_ADAPTED),
        trunc(expiry_tuple.EXP_CALCULATED),
--        bvr_coding_line,
        expiry_tuple.EXP_REF_BVR,
        expiry_tuple.EXP_CALC_NET,
--        expiry_tuple.cde_account,
--        fin_acc_s_payment_id,
        sysdate,
        PCS.PC_I_LIB_SESSION.GetUserIni);

      fetch expiry into expiry_tuple;

    end loop;

    close expiry;

  end Third_Expiry;

  /**
  * Description
  *    procedure de creation des détails paiements
  */
  procedure Third_Payment(pJoinKey          ACI_CONVERSION_SOURCE.CSO_JOIN_KEY%type,
                          pConversionId     ACI_CONVERSION.ACI_CONVERSION_ID%type,
                          pPartImputationId ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type)
  is
    cursor PaymentDetailCursor(conversion_id number,
                        join_key varchar2)
    is
      select distinct
        PAR_DOCUMENT,
        DET_SEQ_NUMBER,
        ACT_EXPIRY_ID,
        DET_PAIED_LC,
        DET_PAIED_FC,
        DET_DISCOUNT_LC,
        DET_DISCOUNT_FC,
        DET_DEDUCTION_LC,
        DET_DEDUCTION_FC,
        DET_DIFF_EXCHANGE,
        CAT_KEY_DET
      from  V_ACI_ASCII_DET_PMT
      where ACI_CONVERSION_ID = pConversionId and
            CSO_JOIN_KEY      = pJoinKey;

    vPaymentDetails  PaymentDetailCursor%rowtype;
    vDetpaymentId    ACI_DET_PAYMENT.ACI_DET_PAYMENT_ID%type;
  begin

    open PaymentDetailCursor(pConversionId, pJoinKey);
    fetch PaymentDetailCursor into vPaymentDetails;
    while PaymentDetailCursor%found
    loop

      select ACI_ID_SEQ.NextVal into vDetpaymentId from dual;

      insert into ACI_DET_PAYMENT(ACI_DET_PAYMENT_ID,
                                  ACI_PART_IMPUTATION_ID,
                                  DET_PAIED_LC,
                                  DET_PAIED_FC,
                                  DET_DISCOUNT_LC,
                                  DET_DISCOUNT_FC,
                                  DET_DEDUCTION_LC,
                                  DET_DEDUCTION_FC,
                                  DET_DIFF_EXCHANGE,
                                  DET_SEQ_NUMBER,
                                  PAR_DOCUMENT,
                                  CAT_KEY_DET,
                                  ACT_EXPIRY_ID,
                                  A_DATECRE,
                                  A_IDCRE)
      values(vDetpaymentId,
             pPartImputationId,
             vPaymentDetails.DET_PAIED_LC,
             vPaymentDetails.DET_PAIED_FC,
             vPaymentDetails.DET_DISCOUNT_LC,
             vPaymentDetails.DET_DISCOUNT_FC,
             vPaymentDetails.DET_DEDUCTION_LC,
             vPaymentDetails.DET_DEDUCTION_FC,
             vPaymentDetails.DET_DIFF_EXCHANGE,
             vPaymentDetails.DET_SEQ_NUMBER,
             vPaymentDetails.PAR_DOCUMENT,
             vPaymentDetails.CAT_KEY_DET,
             vPaymentDetails.ACT_EXPIRY_ID,
             sysdate,
             PCS.PC_I_LIB_SESSION.GetUserIni);

      fetch PaymentDetailCursor into vPaymentDetails;
    end loop;
    close PaymentDetailCursor;
  end Third_Payment;

  /**
  * Description
  *    procedure de creation des imputations financières
  */
  procedure Financial_Imputation(
    document_id IN number,
    conversion_id IN number,
    join_key IN varchar2,
    transaction_date IN date,
    value_date IN date,
    part_imputation_id IN number)
  is

    cursor imputation(conversion_id number, join_key varchar2) is
      select
        A.DOC_NUMBER,
        A.IMF_PRIMARY,
        A.ACC_NUMBER,
        A.DIV_NUMBER,
        A.TAX_NUMBER,
        A.IMF_DESCRIPTION,
        A.CURRENCY1,
        A.CURRENCY2,
        A.IMF_AMOUNT_LC_D,
        A.IMF_AMOUNT_LC_C,
        A.IMF_AMOUNT_FC_D,
        A.IMF_AMOUNT_FC_C,
        A.IMF_EXCHANGE_RATE,
        A.IMF_BASE_PRICE,
        A.IMM_QUANTITY_D,
        A.IMM_QUANTITY_C,
        A.TAX_INCLUDED_EXCLUDED,
        A.TAX_LIABLED_AMOUNT,
        A.TAX_LIABLED_RATE,
        A.TAX_RATE,
        A.TAX_VAT_AMOUNT_LC,
        A.TAX_VAT_AMOUNT_FC,
        A.CDA_NUMBER,
        A.CPN_NUMBER,
        A.PF_NUMBER,
        A.PJ_NUMBER,
        A.QTY_NUMBER,
        A.IMM_DESCRIPTION,
        A.IMM_AMOUNT_LC_D,
        A.IMM_AMOUNT_LC_C,
        A.IMM_AMOUNT_FC_D,
        A.IMM_AMOUNT_FC_C,
        A.IMM_EXCHANGE_RATE,
        A.IMM_BASE_PRICE,
        A.PER_KEY1 FIN_PER_KEY1,
        A.EMP_NUMBER FIN_EMP_NUMBER,
        A.RCO_TITLE FIN_RCO_TITLE,
        A.GOO_MAJOR_REFERENCE FIN_GOO_MAJOR_REF,
        A.FIX_NUMBER FIN_FIX_NUMBER,
        A.C_FAM_TRANSACTION_TYP FIN_C_FAM_TRANSACTION_TYP,
        A.IMF_NUMBER,
        A.IMF_NUMBER2,
        A.IMF_NUMBER3,
        A.IMF_NUMBER4,
        A.IMF_NUMBER5,
        A.IMF_TEXT1,
        A.IMF_TEXT2,
        A.IMF_TEXT3,
        A.IMF_TEXT4,
        A.IMF_TEXT5,
        A.DIC_IMP_FREE1_ID FIN_DIC_IMP_FREE1,
        A.DIC_IMP_FREE2_ID FIN_DIC_IMP_FREE2,
        A.DIC_IMP_FREE3_ID FIN_DIC_IMP_FREE3,
        A.DIC_IMP_FREE4_ID FIN_DIC_IMP_FREE4,
        A.DIC_IMP_FREE5_ID FIN_DIC_IMP_FREE5,
        A.PER_KEY1 MGM_PER_KEY1,
        A.EMP_NUMBER MGM_EMP_NUMBER,
        A.RCO_TITLE MGM_RCO_TITLE,
        A.GOO_MAJOR_REFERENCE MGM_GOO_MAJOR_REF,
        A.FIX_NUMBER MGM_FIX_NUMBER,
        A.C_FAM_TRANSACTION_TYP MGM_C_FAM_TRANSACTION_TYP,
        A.IMM_NUMBER,
        A.IMM_NUMBER2,
        A.IMM_NUMBER3,
        A.IMM_NUMBER4,
        A.IMM_NUMBER5,
        A.IMM_TEXT1,
        A.IMM_TEXT2,
        A.IMM_TEXT3,
        A.IMM_TEXT4,
        A.IMM_TEXT5,
        A.DIC_IMP_FREE1_ID MGM_DIC_IMP_FREE1,
        A.DIC_IMP_FREE2_ID MGM_DIC_IMP_FREE2,
        A.DIC_IMP_FREE3_ID MGM_DIC_IMP_FREE3,
        A.DIC_IMP_FREE4_ID MGM_DIC_IMP_FREE4,
        A.DIC_IMP_FREE5_ID MGM_DIC_IMP_FREE5
      from
        V_ACI_ASCII_FIN_IMPUTATION A
      where
        A.CSO_JOIN_KEY = join_key and
        A.ACI_CONVERSION_ID = conversion_id
      order by CSO_LINE_NUMBER;


    imputation_tuple imputation%rowtype;

    main_imputation_id ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%TYPE;

    no_period ACS_PERIOD.PER_NO_PERIOD%TYPE;
    lnCurrencyFactor number(1);
    mgm_amount_lc_d ACI_MGM_IMPUTATION.IMM_AMOUNT_LC_D%Type;
    mgm_amount_lc_c ACI_MGM_IMPUTATION.IMM_AMOUNT_LC_C%Type;
    mgm_amount_fc_d ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%Type;
    mgm_amount_fc_c ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%Type;

  begin

    open imputation(conversion_id, join_key);

    fetch imputation into imputation_tuple;

    while imputation%found loop

      -- recherche du numéro de période
      no_period := ACS_FUNCTION.GetPeriodNo(trunc(transaction_date),'2');
     --Dans le cas d'imputation financière / analytique en monnaie de base (ME = MB)
     --remplacer les colonne 'cours' et 'diviseur' avec '0' (zéro)
     -- => Facteur de multiplication = 1 ou 0 selon cette égalité
      lnCurrencyFactor := 1;
      if  imputation_tuple.CURRENCY1 = imputation_tuple.CURRENCY2 then
        lnCurrencyFactor := 0;
      end if;

      select aci_id_seq.nextval into main_imputation_id from dual;

      -- creation de l'imputation financiere primaire
      insert into ACI_FINANCIAL_IMPUTATION(
        ACI_FINANCIAL_IMPUTATION_ID,
        ACI_DOCUMENT_ID,
        ACI_PART_IMPUTATION_ID,
        IMF_PRIMARY,
        IMF_TYPE,
        IMF_GENRE,
        C_GENRE_TRANSACTION,
        IMF_DESCRIPTION,
        ACC_NUMBER,
        TAX_NUMBER,
        PER_NO_PERIOD,
        IMF_VALUE_DATE,
        IMF_TRANSACTION_DATE,
        CURRENCY1,
        CURRENCY2,
        DIV_NUMBER,
        IMF_AMOUNT_LC_D,
        IMF_AMOUNT_LC_C,
        IMF_AMOUNT_FC_D,
        IMF_AMOUNT_FC_C,
        IMF_EXCHANGE_RATE,
        IMF_BASE_PRICE,
        TAX_EXCHANGE_RATE,
        DET_BASE_PRICE,
        TAX_INCLUDED_EXCLUDED,
        TAX_RATE,
        TAX_LIABLED_AMOUNT,
        TAX_LIABLED_RATE,
        TAX_VAT_AMOUNT_LC,
        TAX_VAT_AMOUNT_FC,
        TAX_VAT_AMOUNT_VC,
        TAX_REDUCTION,
        PER_KEY1,
        EMP_NUMBER,
        RCO_TITLE,
        GOO_MAJOR_REFERENCE,
        FIX_NUMBER,
        C_FAM_TRANSACTION_TYP,
        IMF_NUMBER,
        IMF_NUMBER2,
        IMF_NUMBER3,
        IMF_NUMBER4,
        IMF_NUMBER5,
        IMF_TEXT1,
        IMF_TEXT2,
        IMF_TEXT3,
        IMF_TEXT4,
        IMF_TEXT5,
        DIC_IMP_FREE1_ID,
        DIC_IMP_FREE2_ID,
        DIC_IMP_FREE3_ID,
        DIC_IMP_FREE4_ID,
        DIC_IMP_FREE5_ID,
        A_DATECRE,
        A_IDCRE)
      values(
        main_imputation_id,
        document_id,
        part_imputation_id,
        imputation_tuple.IMF_PRIMARY,
        'MAN',
        'STD',
        '1',
        imputation_tuple.IMF_DESCRIPTION,
        imputation_tuple.ACC_NUMBER,
        imputation_tuple.TAX_NUMBER,
        no_period,
        trunc(value_date),
        trunc(transaction_date),
        imputation_tuple.CURRENCY1,
        imputation_tuple.CURRENCY2,
        imputation_tuple.DIV_NUMBER,
        imputation_tuple.IMF_AMOUNT_LC_D,
        imputation_tuple.IMF_AMOUNT_LC_C,
        imputation_tuple.IMF_AMOUNT_FC_D,
        imputation_tuple.IMF_AMOUNT_FC_C,
        lnCurrencyFactor * imputation_tuple.IMF_EXCHANGE_RATE,
        lnCurrencyFactor * imputation_tuple.IMF_BASE_PRICE,
        lnCurrencyFactor * imputation_tuple.IMF_EXCHANGE_RATE,
        lnCurrencyFactor * imputation_tuple.IMF_BASE_PRICE,
        imputation_tuple.TAX_INCLUDED_EXCLUDED,
        imputation_tuple.TAX_RATE,
        imputation_tuple.TAX_LIABLED_AMOUNT,
        imputation_tuple.TAX_LIABLED_RATE,
        imputation_tuple.TAX_VAT_AMOUNT_LC,
        imputation_tuple.TAX_VAT_AMOUNT_FC,
        imputation_tuple.TAX_VAT_AMOUNT_FC,
        0,
        imputation_tuple.FIN_PER_KEY1,
        imputation_tuple.FIN_EMP_NUMBER,
        imputation_tuple.FIN_RCO_TITLE,
        imputation_tuple.FIN_GOO_MAJOR_REF,
        imputation_tuple.FIN_FIX_NUMBER,
        imputation_tuple.FIN_C_FAM_TRANSACTION_TYP,
        imputation_tuple.IMF_NUMBER,
        imputation_tuple.IMF_NUMBER2,
        imputation_tuple.IMF_NUMBER3,
        imputation_tuple.IMF_NUMBER4,
        imputation_tuple.IMF_NUMBER5,
        imputation_tuple.IMF_TEXT1,
        imputation_tuple.IMF_TEXT2,
        imputation_tuple.IMF_TEXT3,
        imputation_tuple.IMF_TEXT4,
        imputation_tuple.IMF_TEXT5,
        imputation_tuple.FIN_DIC_IMP_FREE1,
        imputation_tuple.FIN_DIC_IMP_FREE2,
        imputation_tuple.FIN_DIC_IMP_FREE3,
        imputation_tuple.FIN_DIC_IMP_FREE4,
        imputation_tuple.FIN_DIC_IMP_FREE5,
        SYSDATE,
        PCS.PC_I_LIB_SESSION.GetUserIni);

      if imputation_tuple.CDA_NUMBER is not null or
         imputation_tuple.CPN_NUMBER is not null or
         imputation_tuple.PF_NUMBER  is not null or
         imputation_tuple.PJ_NUMBER  is not null or
         imputation_tuple.QTY_NUMBER is not null then


        if imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
          if imputation_tuple.IMM_AMOUNT_LC_D <> 0 then
            mgm_amount_lc_d := Round(imputation_tuple.IMM_AMOUNT_LC_D, 2) - Round(imputation_tuple.TAX_VAT_AMOUNT_LC, 2);
            mgm_amount_lc_c := 0;
            mgm_amount_fc_d := Round(imputation_tuple.IMM_AMOUNT_FC_D, 2) - Round(imputation_tuple.TAX_VAT_AMOUNT_FC, 2);
            mgm_amount_fc_c := 0;
          else
            mgm_amount_lc_d := 0;
            mgm_amount_lc_c := Round(imputation_tuple.IMM_AMOUNT_LC_C, 2) - Round(imputation_tuple.TAX_VAT_AMOUNT_LC, 2);
            mgm_amount_fc_d := 0;
            mgm_amount_fc_c := Round(imputation_tuple.IMM_AMOUNT_FC_C, 2) - Round(imputation_tuple.TAX_VAT_AMOUNT_FC, 2);
          end if;
        else
          mgm_amount_lc_d := imputation_tuple.IMM_AMOUNT_LC_D;
          mgm_amount_lc_c := imputation_tuple.IMM_AMOUNT_LC_C;
          mgm_amount_fc_d := imputation_tuple.IMM_AMOUNT_FC_D;
          mgm_amount_fc_c := imputation_tuple.IMM_AMOUNT_FC_C;
        end if;



        insert into ACI_MGM_IMPUTATION(
          ACI_MGM_IMPUTATION_ID,
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
          IMM_QUANTITY_D,
          IMM_QUANTITY_C,
          IMM_VALUE_DATE,
          IMM_TRANSACTION_DATE,
          CURRENCY1,
          CURRENCY2,
          CDA_NUMBER,
          CPN_NUMBER,
          PF_NUMBER,
          PJ_NUMBER,
          QTY_NUMBER,
          PER_NO_PERIOD,
          PER_KEY1,
          EMP_NUMBER,
          RCO_TITLE,
          GOO_MAJOR_REFERENCE,
          FIX_NUMBER,
          C_FAM_TRANSACTION_TYP,
          IMM_NUMBER,
          IMM_NUMBER2,
          IMM_NUMBER3,
          IMM_NUMBER4,
          IMM_NUMBER5,
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
          A_DATECRE,
          A_IDCRE)
        VALUES(
          aci_id_seq.nextval,
          document_id,
          main_imputation_id,
          'MAN',
          'STD',
          imputation_tuple.IMF_PRIMARY,
          imputation_tuple.IMM_DESCRIPTION,
          mgm_amount_lc_d,
          mgm_amount_lc_c,
          lnCurrencyFactor * imputation_tuple.IMM_EXCHANGE_RATE,
          lnCurrencyFactor * imputation_tuple.IMM_BASE_PRICE,
          mgm_amount_fc_d,
          mgm_amount_fc_c,
          imputation_tuple.IMM_QUANTITY_D,
          imputation_tuple.IMM_QUANTITY_C,
          trunc(value_date),
          trunc(transaction_date),
          imputation_tuple.CURRENCY1,
          imputation_tuple.CURRENCY2,
          imputation_tuple.CDA_NUMBER,
          imputation_tuple.CPN_NUMBER,
          imputation_tuple.PF_NUMBER,
          imputation_tuple.PJ_NUMBER,
          imputation_tuple.QTY_NUMBER,
          no_period,
          imputation_tuple.MGM_PER_KEY1,
          imputation_tuple.MGM_EMP_NUMBER,
          imputation_tuple.MGM_RCO_TITLE,
          imputation_tuple.MGM_GOO_MAJOR_REF,
          imputation_tuple.MGM_FIX_NUMBER,
          imputation_tuple.MGM_C_FAM_TRANSACTION_TYP,
          imputation_tuple.IMM_NUMBER,
          imputation_tuple.IMM_NUMBER2,
          imputation_tuple.IMM_NUMBER3,
          imputation_tuple.IMM_NUMBER4,
          imputation_tuple.IMM_NUMBER5,
          imputation_tuple.IMM_TEXT1,
          imputation_tuple.IMM_TEXT2,
          imputation_tuple.IMM_TEXT3,
          imputation_tuple.IMM_TEXT4,
          imputation_tuple.IMM_TEXT5,
          imputation_tuple.MGM_DIC_IMP_FREE1,
          imputation_tuple.MGM_DIC_IMP_FREE2,
          imputation_tuple.MGM_DIC_IMP_FREE3,
          imputation_tuple.MGM_DIC_IMP_FREE4,
          imputation_tuple.MGM_DIC_IMP_FREE5,
          SYSDATE,
          PCS.PC_I_LIB_SESSION.GetUserIni);

      end if;

      fetch imputation into imputation_tuple;

    end loop;

    close imputation;

  end Financial_Imputation;


  /**
  * Description
  *    procedure de creation des imputations analytiques non liée à des imputations financières
  */
  procedure Mgm_Imputation(
    document_id IN number,
    conversion_id IN number,
    join_key IN varchar2,
    transaction_date IN date,
    value_date IN date,
    part_imputation_id IN number)
  is

    cursor mgm_imputation(conversion_id number, join_key varchar2) is
      select
        DOC_NUMBER,
        CURRENCY1,
        CURRENCY2,
        CDA_NUMBER,
        CPN_NUMBER,
        PF_NUMBER,
        PJ_NUMBER,
        QTY_NUMBER,
        IMM_DESCRIPTION,
        IMM_QUANTITY_D,
        IMM_QUANTITY_C,
        IMM_AMOUNT_LC_D,
        IMM_AMOUNT_LC_C,
        IMM_AMOUNT_FC_D,
        IMM_AMOUNT_FC_C,
        IMM_EXCHANGE_RATE,
        IMM_BASE_PRICE,
        TAX_INCLUDED_EXCLUDED,
        TAX_VAT_AMOUNT_LC,
        TAX_VAT_AMOUNT_FC,
        PER_KEY1,
        EMP_NUMBER,
        RCO_TITLE,
        GOO_MAJOR_REFERENCE,
        FIX_NUMBER,
        C_FAM_TRANSACTION_TYP,
        IMM_NUMBER,
        IMM_NUMBER2,
        IMM_NUMBER3,
        IMM_NUMBER4,
        IMM_NUMBER5,
        IMM_TEXT1,
        IMM_TEXT2,
        IMM_TEXT3,
        IMM_TEXT4,
        IMM_TEXT5,
        DIC_IMP_FREE1_ID,
        DIC_IMP_FREE2_ID,
        DIC_IMP_FREE3_ID,
        DIC_IMP_FREE4_ID,
        DIC_IMP_FREE5_ID
      from
        V_ACI_ASCII_MGM_IMPUTATION
      where
        CSO_JOIN_KEY = join_key and
        ACI_CONVERSION_ID = conversion_id
      order by CSO_LINE_NUMBER;

    mgm_imputation_tuple mgm_imputation%rowtype;

    no_period ACS_PERIOD.PER_NO_PERIOD%TYPE;
    lnCurrencyFactor number(1);
    amount_lc_d ACI_MGM_IMPUTATION.IMM_AMOUNT_LC_D%Type;
    amount_lc_c ACI_MGM_IMPUTATION.IMM_AMOUNT_LC_C%Type;
    amount_fc_d ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_D%Type;
    amount_fc_c ACI_MGM_IMPUTATION.IMM_AMOUNT_FC_C%Type;

  begin

    open mgm_imputation(conversion_id, join_key);

    fetch mgm_imputation into mgm_imputation_tuple;

    while mgm_imputation%found loop

      -- recherche du numéro de période
      no_period := ACS_FUNCTION.GetPeriodNo(trunc(transaction_date),'2');
     --Dans le cas d'imputation financière / analytique en monnaie de base (ME = MB)
     --remplacer les colonne 'cours' et 'diviseur' avec '0' (zéro)
     -- => Facteur de multiplication = 1 ou 0 selon cette égalité
      lnCurrencyFactor := 1;
      if  mgm_imputation_tuple.CURRENCY1 = mgm_imputation_tuple.CURRENCY2 then
        lnCurrencyFactor := 0;
      end if;

      if mgm_imputation_tuple.TAX_INCLUDED_EXCLUDED = 'E' then
        if mgm_imputation_tuple.IMM_AMOUNT_LC_D <> 0 then
          amount_lc_d := Round(mgm_imputation_tuple.IMM_AMOUNT_LC_D, 2) - Round(mgm_imputation_tuple.TAX_VAT_AMOUNT_LC, 2);
          amount_lc_c := 0;
          amount_fc_d := Round(mgm_imputation_tuple.IMM_AMOUNT_FC_D, 2) - Round(mgm_imputation_tuple.TAX_VAT_AMOUNT_FC, 2);
          amount_fc_c := 0;
        else
          amount_lc_d := 0;
          amount_lc_c := Round(mgm_imputation_tuple.IMM_AMOUNT_LC_C, 2) - Round(mgm_imputation_tuple.TAX_VAT_AMOUNT_LC, 2);
          amount_fc_d := 0;
          amount_fc_c := Round(mgm_imputation_tuple.IMM_AMOUNT_FC_C, 2) - Round(mgm_imputation_tuple.TAX_VAT_AMOUNT_FC, 2);
        end if;
      else
        amount_lc_d := mgm_imputation_tuple.IMM_AMOUNT_LC_D;
        amount_lc_c := mgm_imputation_tuple.IMM_AMOUNT_LC_C;
        amount_fc_d := mgm_imputation_tuple.IMM_AMOUNT_FC_D;
        amount_fc_c := mgm_imputation_tuple.IMM_AMOUNT_FC_C;
      end if;

      insert into ACI_MGM_IMPUTATION(
        ACI_MGM_IMPUTATION_ID,
        ACI_DOCUMENT_ID,
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
        IMM_QUANTITY_D,
        IMM_QUANTITY_C,
        IMM_VALUE_DATE,
        IMM_TRANSACTION_DATE,
        CURRENCY1,
        CURRENCY2,
        CDA_NUMBER,
        CPN_NUMBER,
        PF_NUMBER,
        PJ_NUMBER,
        QTY_NUMBER,
        PER_NO_PERIOD,
        PER_KEY1,
        EMP_NUMBER,
        RCO_TITLE,
        GOO_MAJOR_REFERENCE,
        FIX_NUMBER,
        C_FAM_TRANSACTION_TYP,
        IMM_NUMBER,
        IMM_NUMBER2,
        IMM_NUMBER3,
        IMM_NUMBER4,
        IMM_NUMBER5,
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
        A_DATECRE,
        A_IDCRE)
      VALUES(
        aci_id_seq.nextval,
        document_id,
        'MAN',
        'STD',
        0,
        mgm_imputation_tuple.IMM_DESCRIPTION,
        amount_lc_d,
        amount_lc_c,
        lnCurrencyFactor * mgm_imputation_tuple.IMM_EXCHANGE_RATE,
        lnCurrencyFactor * mgm_imputation_tuple.IMM_BASE_PRICE,
        amount_fc_d,
        amount_fc_c,
        mgm_imputation_tuple.IMM_QUANTITY_D,
        mgm_imputation_tuple.IMM_QUANTITY_C,
        trunc(value_date),
        trunc(transaction_date),
        mgm_imputation_tuple.CURRENCY1,
        mgm_imputation_tuple.CURRENCY2,
        mgm_imputation_tuple.CDA_NUMBER,
        mgm_imputation_tuple.CPN_NUMBER,
        mgm_imputation_tuple.PF_NUMBER,
        mgm_imputation_tuple.PJ_NUMBER,
        mgm_imputation_tuple.QTY_NUMBER,
        no_period,
        mgm_imputation_tuple.PER_KEY1,
        mgm_imputation_tuple.EMP_NUMBER,
        mgm_imputation_tuple.RCO_TITLE,
        mgm_imputation_tuple.GOO_MAJOR_REFERENCE,
        mgm_imputation_tuple.FIX_NUMBER,
        mgm_imputation_tuple.C_FAM_TRANSACTION_TYP,
        mgm_imputation_tuple.IMM_NUMBER,
        mgm_imputation_tuple.IMM_NUMBER2,
        mgm_imputation_tuple.IMM_NUMBER3,
        mgm_imputation_tuple.IMM_NUMBER4,
        mgm_imputation_tuple.IMM_NUMBER5,
        mgm_imputation_tuple.IMM_TEXT1,
        mgm_imputation_tuple.IMM_TEXT2,
        mgm_imputation_tuple.IMM_TEXT3,
        mgm_imputation_tuple.IMM_TEXT4,
        mgm_imputation_tuple.IMM_TEXT5,
        mgm_imputation_tuple.DIC_IMP_FREE1_ID,
        mgm_imputation_tuple.DIC_IMP_FREE2_ID,
        mgm_imputation_tuple.DIC_IMP_FREE3_ID,
        mgm_imputation_tuple.DIC_IMP_FREE4_ID,
        mgm_imputation_tuple.DIC_IMP_FREE5_ID,
        SYSDATE,
        PCS.PC_I_LIB_SESSION.GetUserIni);

      fetch mgm_imputation into mgm_imputation_tuple;

    end loop;

    close mgm_imputation;

  end Mgm_Imputation;

end ACI_ASCII_DOCUMENT;
