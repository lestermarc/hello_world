--------------------------------------------------------
--  DDL for Package Body ACI_PRC_STOCK_MOVEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_PRC_STOCK_MOVEMENT" 
is
  /**
  * procedure pInterfaceHeader
  * Description
  *    procedure de creation de l'entete du document d'interface comptable
  * @created fp
  * @lastUpdate FPE fp.02.2008
  * @private
  * @param iDocumentId                : id du nouveau document
  * @param iDocumentNumber            : numéro du document
  * @param iTransactionKey            : clef de la trabsaction
  * @param iJobTypeSCatalogue         : type de catalogue transaction
  * @param iMovementDate              : date du mouvement
  * @param iMovementValue             : valeur du mouvement
  * @param iStockMovementId           : id du mouvement de stock
  */
  procedure pInterfaceHeader(
    iDocumentId        in number
  , iDocumentNumber    in varchar2
  , iTransactionCatKey in varchar2
  , iTransactionTypKey in varchar2
  , iJobTypeSCatalogue in number
  , iMovementDate      in date
  , iMovementValue     in number
  , iStockMovementId   in number
  )
  is
    lNoExercise ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;
    lMoneyName  ACI_DOCUMENT.CURRENCY%type;
  begin
    -- si la config de reprise des textes est à False on efface le numéro d'exercice
    if upper(PCS.PC_CONFIG.GetConfig('FIN_TEXT_RECOVERING') ) = 'TRUE' then
      lNoExercise  := ACS_FUNCTION.GetFinancialYearNo(iMovementDate);
      lMoneyName   := ACS_FUNCTION.GetLocalCurrencyName;
    end if;

    -- Creation de l'entete
    insert into ACI_DOCUMENT
                (ACI_DOCUMENT_ID
               , DOC_NUMBER
               , C_INTERFACE_ORIGIN
               , C_INTERFACE_CONTROL
               , ACJ_JOB_TYPE_S_CATALOGUE_ID
               , CAT_KEY
               , TYP_KEY
               , DOC_TOTAL_AMOUNT_DC
               , DOC_DOCUMENT_DATE
               , ACS_FINANCIAL_CURRENCY_ID
               , CURRENCY
               , ACS_FINANCIAL_YEAR_ID
               , FYE_NO_EXERCICE
               , C_STATUS_DOCUMENT
               , STM_STOCK_MOVEMENT_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (iDocumentId   -- ACI_DOCUMENT_ID
               , iDocumentNumber   -- DOC_NUMBER
               , '2'   -- C_INTERFACE_ORIGIN
               , '3'   -- C_INTERFACE_CONTROL
               , iJobTypeSCatalogue   -- ACJ_JOB_TYPE_S_CATALOGUE_ID
               , iTransactionCatKey   -- CAT_KEY
               , iTransactionTypKey   -- TYP_KEY
               , iMovementValue   -- DOC_TOTAL_AMOUNT_DC
               , trunc(iMovementDate)   -- DOC_DOCUMENT_DATE
               , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
               , lMoneyName   -- CURRENCY
               , ACS_FUNCTION.GetFinancialYearId(trunc(iMovementDate) )   -- ACS_FINANCIAL_YEAR_ID
               , lNoExercise   -- FYE_NO_EXERCICE
               , 'DEF'   -- C_STATUS_DOCUMENT
               , iStockMovementId   -- STM_STOCK_MOVEMENT_ID
               , sysdate   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                );
  end pInterfaceHeader;

  /**
  * procedure pInterfaceImputations
  * Description
  *    procedure de creation des imputations d'interface comptable
  * @created fp
  * @lastUpdate
  * @private
  * @param iDocumentId             : id document ACI
  * @param iImpDescr               : description de l'imputation
  * @param iMovementDate           : date du mouvement
  * @param iMovementValue          : valeur du mouvement
  * @param iDivisionAccountId     : compte division
  * @param iFinancialAccountId    : compte financier
  * @param iDivisionAccountId2    : compte division
  * @param iFinancialAccountId2   : compte financier
  * @param iCpnAccountId          : compte charge par nature
  * @param iCpnAccountId2         : compte charge par nature
  * @param iCdaAccountId          : compte centre d'analyse
  * @param iCdaAccountId2         : compte centre d'analyse
  * @param iPfAccountId           : compte porteur de frais
  * @param iPfAccountId2          : compte porteur de frais
  * @param iPjAccountId           : compte projet
  * @param iPjAccountId2          : compte projet
  * @param iGoodId                 : id du bien
  * @param iThirdId                : id du tiers
  * @param iRecordId               : id du dossier
  * @param ibInputMovement          : flag mouvement d'entrée
  * @param ibFinancialImputation    : flag création imputation financière
  * @param ibAnalImputation         : flag création imputation analytique
  * @param ibExtourneMvt              : mouvement d'extourne
  * @param ioAccountInfo            : informations complémentaires bilan
  * @param ioAccountInfo2           : informations complémentaires résultat
  * @param iGapPurchasePrice       : écart d'achat (optionnel)
  */
  procedure pInterfaceImputations(
    iDocumentId           in     number
  , iImpDescr             in     varchar2
  , iMovementDate         in     date
  , iMovementValue        in     number
  , iDivisionAccountId    in     number
  , iFinancialAccountId   in     number
  , iDivisionAccountId2   in     number
  , iFinancialAccountId2  in     number
  , iCpnAccountId         in     number
  , iCpnAccountId2        in     number
  , iCdaAccountId         in     number
  , iCdaAccountId2        in     number
  , iPfAccountId          in     number
  , iPfAccountId2         in     number
  , iPjAccountId          in     number
  , iPjAccountId2         in     number
  , iGoodId               in     number
  , iThirdId              in     number
  , iRecordId             in     number
  , ibInputMovement       in     number
  , ibFinancialImputation in     number
  , ibAnalImputation      in     number
  , ibExtourneMvt         in     number
  , ioAccountInfo         in out ACS_LIB_LOGISTIC_FINANCIAL.tAccountInfo
  , ioAccountInfo2        in out ACS_LIB_LOGISTIC_FINANCIAL.tAccountInfo
  , iGapPurchasePrice     in     number default null
  )
  is
    lFinAccNumber             ACS_ACCOUNT.ACC_NUMBER%type;
    lDivAccNumber             ACS_ACCOUNT.ACC_NUMBER%type;
    lFinAccNumber2            ACS_ACCOUNT.ACC_NUMBER%type;
    lDivAccNumber2            ACS_ACCOUNT.ACC_NUMBER%type;
    lCpnAccNumber             ACS_ACCOUNT.ACC_NUMBER%type;
    lCpnAccNumber2            ACS_ACCOUNT.ACC_NUMBER%type;
    lCdaAccNumber             ACS_ACCOUNT.ACC_NUMBER%type;
    lCdaAccNumber2            ACS_ACCOUNT.ACC_NUMBER%type;
    lPfAccNumber              ACS_ACCOUNT.ACC_NUMBER%type;
    lPfAccNumber2             ACS_ACCOUNT.ACC_NUMBER%type;
    lPjAccNumber              ACS_ACCOUNT.ACC_NUMBER%type;
    lPjAccNumber2             ACS_ACCOUNT.ACC_NUMBER%type;
    lNoPeriod                 ACS_PERIOD.PER_NO_PERIOD%type;
    lValueD2                  ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    lValueC2                  ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    lMoneyName                ACI_DOCUMENT.CURRENCY%type;
    lMainImputationId         ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
    lMainImputationId2        ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type;
    lAcsGapFinancialAccountID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    lAccGapNumber             ACS_ACCOUNT.ACC_NUMBER%type;
    lAcsGapCPNAccountID       ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    lAccGapCPNNumber          ACS_ACCOUNT.ACC_NUMBER%type;
    lValueD                   ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    lValueC                   ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    lGapValueD                ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    lGapValueC                ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    lAgaintsPartValueD        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    lAgaintsPartValueC        ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    lAgaintsPartGapValueD     ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    lAgaintsPartGapValueC     ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    lImfDescription           ACI_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    ltTextRecoveringRec       ACI_LOGISTIC_DOCUMENT.TextRecoveringRecType;
  begin
    -- si la config de reprise des textes est à False on efface le numéro de période
    if upper(PCS.PC_CONFIG.GetConfig('FIN_TEXT_RECOVERING') ) = 'TRUE' then
      -- recherche du nom de la monnaie locale
      lMoneyName  := ACS_FUNCTION.GetLocalCurrencyName;
      -- recherche du num‚ro de periode
      lNoPeriod   := ACS_FUNCTION.GetPeriodNo(trunc(iMovementDate), '2');

      -- recherche du numero du compte financier en fonction de l'id
      select max(ACC_NUMBER)
        into lFinAccNumber
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iFinancialAccountId;

      -- recherche du numero du compte division en fonction de l'id
      select max(ACC_NUMBER)
        into lDivAccNumber
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iDivisionAccountId;

      -- recherche du numero du compte financier de contre-partie en fonction de l'id
      select max(ACC_NUMBER)
        into lFinAccNumber2
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iFinancialAccountId2;

      -- recherche du numero du compte division de contre-partie en fonction de l'id
      select max(ACC_NUMBER)
        into lDivAccNumber2
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iDivisionAccountId2;

      -- recherche du numero du compte charge par nature en fonction de l'id
      select max(ACC_NUMBER)
        into lCpnAccNumber
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iCpnAccountId;

      -- recherche du numero du compte charge par nature de contre-partie en fonction de l'id
      select max(ACC_NUMBER)
        into lCpnAccNumber2
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iCpnAccountId2;

      -- recherche du numero du compte centre d'analyse en fonction de l'id
      select max(ACC_NUMBER)
        into lCdaAccNumber
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iCdaAccountId;

      -- recherche du numero du compte centre d'analyse de contre-partie en fonction de l'id
      select max(ACC_NUMBER)
        into lCdaAccNumber2
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iCdaAccountId2;

      -- recherche du numero du compte porteur de frais en fonction de l'id
      select max(ACC_NUMBER)
        into lPfAccNumber
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iPfAccountId;

      -- recherche du numero du compte porteur de frais de contre-partie en fonction de l'id
      select max(ACC_NUMBER)
        into lPfAccNumber2
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iPfAccountId2;

      -- recherche du numero du compte projet en fonction de l'id
      select max(ACC_NUMBER)
        into lPjAccNumber
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iPjAccountId;

      -- recherche du numero du compte projet de contre-partie en fonction de l'id
      select max(ACC_NUMBER)
        into lPjAccNumber2
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = iPjAccountId2;
    end if;

    ----
    -- Détermine si nous traitons une imputation avec montant négatif (en principe une extourne). Dans ce cas,
    -- il faut inverser la valeur de l'imputation et les montants débit/crédit.
    --
    if     (nvl(ibExtourneMvt, 0) = 0)
       and (iMovementValue > 0) then   -- Pas d'extourne et Mouvement avec valeur positive
      -- si entree -> mouvement crédit avec valeur positive
      -- si sortie -> mouvement débit avec valeur positive
      if ibInputMovement = 1 then
        lValueC2  := iMovementValue;
        lValueD2  := 0;
      else
        lValueC2  := 0;
        lValueD2  := iMovementValue;
      end if;
    else   -- (iMovementValue < 0)  Mouvement d'extourne ou mouvement avec valeur négative
      -- si entree avec quantité négative -> mouvement débit avec valeur positive
      -- si sortie avec quantité négative -> mouvement crédit avec valeur positive
      if ibInputMovement = 1 then
        lValueC2  := 0;
        lValueD2  := iMovementValue * -1;
      else
        lValueC2  := iMovementValue * -1;
        lValueD2  := 0;
      end if;
    end if;

    -- si création d'une imputation financière
    if ibFinancialImputation = 1 then
      -- recherche de l'id de l'imputation
      select ACI_ID_SEQ.nextval
        into lMainImputationId
        from dual;

      -- création de l'imputation primaire de l'interface comptable
      insert into ACI_FINANCIAL_IMPUTATION
                  (ACI_FINANCIAL_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , IMF_TYPE
                 , IMF_GENRE
                 , C_GENRE_TRANSACTION
                 , IMF_PRIMARY
                 , IMF_DESCRIPTION
                 , IMF_BASE_PRICE
                 , IMF_AMOUNT_LC_D
                 , IMF_AMOUNT_LC_C
                 , IMF_EXCHANGE_RATE
                 , IMF_AMOUNT_FC_D
                 , IMF_AMOUNT_FC_C
                 , IMF_VALUE_DATE
                 , IMF_TRANSACTION_DATE
                 , ACS_DIVISION_ACCOUNT_ID
                 , DIV_NUMBER
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACC_NUMBER
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , FAM_FIXED_ASSETS_ID
                 , C_FAM_TRANSACTION_TYP
                 , HRM_PERSON_ID
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , IMF_TEXT1
                 , IMF_TEXT2
                 , IMF_TEXT3
                 , IMF_TEXT4
                 , IMF_TEXT5
                 , IMF_NUMBER
                 , IMF_NUMBER2
                 , IMF_NUMBER3
                 , IMF_NUMBER4
                 , IMF_NUMBER5
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (lMainImputationId   -- ACI_FINANCIAL_IMPUTATION_ID
                 , iDocumentId   -- ACI_DOCUMENT_ID
                 , 'MAN'   -- IMF_TYPE
                 , 'STD'   -- IMF_GENRE
                 , '1'   -- C_GENRE_TRANSACTION
                 , 1   -- IMF_PRIMARY
                 , iImpDescr   -- IMF_DESCRIPTION
                 , 0   -- IMF_BASE_PRICE
                 , lValueC2   -- IMF_AMOUNT_LC_D
                 , lValueD2   -- IMF_AMOUNT_LC_C
                 , 0   -- IMF_EXCHANGE_RATE
                 , 0   -- IMF_AMOUNT_FC_D
                 , 0   -- IMF_AMOUNT_FC_C
                 , trunc(iMovementDate)   -- IMF_VALUE_DATE
                 , trunc(iMovementDate)   -- IMF_TRANSACTION_DATE
                 , iDivisionAccountId   -- ACS_DIVISION_ACCOUNT_ID
                 , lDivAccNumber   -- DIV_NUMBER
                 , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                 , lMoneyName   -- CURRENCY1
                 , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                 , lMoneyName   -- CURRENCY2
                 , iFinancialAccountId   -- ACS_FINANCIAL_ACCOUNT_ID
                 , lFinAccNumber   -- ACC_NUMBER
                 , ACS_FUNCTION.GetPeriodId(trunc(iMovementDate), '2')   -- ACS_PERIOD_ID
                 , lNoPeriod   -- PER_NO_PERIOD
                 , ioAccountInfo.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                 , ioAccountInfo.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                 , ACS_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(ioAccountInfo.DEF_HRM_PERSON)   -- HRM_PERSON_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE1   -- DIC_IMP_FREE1_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE2   -- DIC_IMP_FREE2_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE3   -- DIC_IMP_FREE3_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE4   -- DIC_IMP_FREE4_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE5   -- DIC_IMP_FREE5_ID
                 , ioAccountInfo.DEF_TEXT1   -- IMF_TEXT1
                 , ioAccountInfo.DEF_TEXT2   -- IMF_TEXT2
                 , ioAccountInfo.DEF_TEXT3   -- IMF_TEXT3
                 , ioAccountInfo.DEF_TEXT4   -- IMF_TEXT4
                 , ioAccountInfo.DEF_TEXT5   -- IMF_TEXT5
                 , to_number(ioAccountInfo.DEF_NUMBER1)   -- IMF_NUMBER
                 , to_number(ioAccountInfo.DEF_NUMBER2)   -- IMF_NUMBER2
                 , to_number(ioAccountInfo.DEF_NUMBER3)   -- IMF_NUMBER3
                 , to_number(ioAccountInfo.DEF_NUMBER4)   -- IMF_NUMBER4
                 , to_number(ioAccountInfo.DEF_NUMBER5)   -- IMF_NUMBER5
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );
    end if;

    -- imputation analytique primaire
    if     ibAnalImputation = 1
       and (   iCpnAccountId is not null
            or iCdaAccountId is not null
            or iPfAccountId is not null
            or iPjAccountId is not null
           ) then
      insert into ACI_MGM_IMPUTATION
                  (ACI_MGM_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , ACI_FINANCIAL_IMPUTATION_ID
                 , IMM_TYPE
                 , IMM_GENRE
                 , IMM_PRIMARY
                 , IMM_DESCRIPTION
                 , IMM_AMOUNT_LC_C
                 , IMM_AMOUNT_LC_D
                 , IMM_EXCHANGE_RATE
                 , IMM_BASE_PRICE
                 , IMM_AMOUNT_FC_C
                 , IMM_AMOUNT_FC_D
                 , IMM_AMOUNT_EUR_C
                 , IMM_AMOUNT_EUR_D
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
                 , FAM_FIXED_ASSETS_ID
                 , C_FAM_TRANSACTION_TYP
                 , HRM_PERSON_ID
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , IMM_TEXT1
                 , IMM_TEXT2
                 , IMM_TEXT3
                 , IMM_TEXT4
                 , IMM_TEXT5
                 , IMM_NUMBER
                 , IMM_NUMBER2
                 , IMM_NUMBER3
                 , IMM_NUMBER4
                 , IMM_NUMBER5
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aci_id_seq.nextval   -- ACI_MGM_IMPUTATION_ID
                 , iDocumentId   -- ACI_DOCUMENT_ID
                 , lMainImputationId   -- ACI_FINANCIAL_IMPUTATION_ID
                 , 'MAN'   -- IMM_TYPE
                 , 'STD'   -- IMM_GENRE
                 , 1   -- IMM_PRIMARY
                 , iImpDescr   -- IMM_DESCRIPTION
                 , lValueD2   -- IMM_AMOUNT_LC_C
                 , lValueC2   -- IMM_AMOUNT_LC_D
                 , 0   -- IMM_EXCHANGE_RATE
                 , 0   -- IMM_BASE_PRICE
                 , 0   -- IMM_AMOUNT_FC_C
                 , 0   -- IMM_AMOUNT_FC_D
                 , 0   -- IMM_AMOUNT_EUR_C
                 , 0   -- IMM_AMOUNT_EUR_D
                 , trunc(iMovementDate)   -- IMM_VALUE_DATE
                 , trunc(iMovementDate)   -- IMM_TRANSACTION_DATE
                 , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                 , lMoneyName   -- CURRENCY1
                 , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                 , lMoneyName   -- CURRENCY2
                 , iCdaAccountId   -- ACS_CDA_ACCOUNT_ID
                 , lCdaAccNumber   -- CDA_NUMBER
                 , iCpnAccountId   -- ACS_CPN_ACCOUNT_ID
                 , lCpnAccNumber   -- CPN_NUMBER
                 , iPfAccountId   -- ACS_PF_ACCOUNT_ID
                 , lPfAccNumber   -- PF_NUMBER
                 , iPjAccountId   -- ACS_PJ_ACCOUNT_ID
                 , lPjAccNumber   -- PJ_NUMBER
                 , ACS_FUNCTION.GetPeriodId(trunc(iMovementDate), '2')   -- ACS_PERIOD_ID
                 , lNoPeriod   -- PER_NO_PERIOD
                 , ioAccountInfo.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                 , ioAccountInfo.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                 , ACS_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(ioAccountInfo.DEF_HRM_PERSON)   -- HRM_PERSON_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE1   -- DIC_IMP_FREE1_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE2   -- DIC_IMP_FREE2_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE3   -- DIC_IMP_FREE3_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE4   -- DIC_IMP_FREE4_ID
                 , ioAccountInfo.DEF_DIC_IMP_FREE5   -- DIC_IMP_FREE5_ID
                 , ioAccountInfo.DEF_TEXT1   -- IMM_TEXT1
                 , ioAccountInfo.DEF_TEXT2   -- IMM_TEXT2
                 , ioAccountInfo.DEF_TEXT3   -- IMM_TEXT3
                 , ioAccountInfo.DEF_TEXT4   -- IMM_TEXT4
                 , ioAccountInfo.DEF_TEXT5   -- IMM_TEXT5
                 , to_number(ioAccountInfo.DEF_NUMBER1)   -- IMM_NUMBER
                 , to_number(ioAccountInfo.DEF_NUMBER2)   -- IMM_NUMBER2
                 , to_number(ioAccountInfo.DEF_NUMBER3)   -- IMM_NUMBER3
                 , to_number(ioAccountInfo.DEF_NUMBER4)   -- IMM_NUMBER4
                 , to_number(ioAccountInfo.DEF_NUMBER5)   -- IMM_NUMBER5
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );
    end if;

    if upper(PCS.PC_CONFIG.GetConfig('FIN_TEXT_RECOVERING') ) = 'TRUE' then
      -- lecture des textes selon  la config de reprise des textes
      ACI_LOGISTIC_DOCUMENT.getTextRecovering(null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , null
                                            , iGoodId
                                            , iRecordId
                                            , null
                                            , ioAccountInfo2.FAM_FIXED_ASSETS_ID
                                            , iThirdId
                                            , false
                                            , ltTextRecoveringRec
                                             );
    end if;

    -- si création d'une imputation financière
    if ibFinancialImputation = 1 then
      -- recherche de l'id de l'imputation
      select ACI_ID_SEQ.nextval
        into lMainImputationId
        from dual;

      -- création de l'imputation de contre-partie de l'interface comptable
      insert into ACI_FINANCIAL_IMPUTATION
                  (ACI_FINANCIAL_IMPUTATION_ID
                 , ACI_DOCUMENT_ID
                 , IMF_TYPE
                 , IMF_GENRE
                 , C_GENRE_TRANSACTION
                 , IMF_PRIMARY
                 , IMF_DESCRIPTION
                 , IMF_BASE_PRICE
                 , IMF_AMOUNT_LC_D
                 , IMF_AMOUNT_LC_C
                 , IMF_EXCHANGE_RATE
                 , IMF_AMOUNT_FC_D
                 , IMF_AMOUNT_FC_C
                 , IMF_VALUE_DATE
                 , IMF_TRANSACTION_DATE
                 , ACS_DIVISION_ACCOUNT_ID
                 , DIV_NUMBER
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY1
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY2
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACC_NUMBER
                 , ACS_PERIOD_ID
                 , PER_NO_PERIOD
                 , GCO_GOOD_ID
                 , GOO_MAJOR_REFERENCE
                 , PAC_PERSON_ID
                 , PER_KEY1
                 , PER_KEY2
                 , DOC_RECORD_ID
                 , RCO_NUMBER
                 , RCO_TITLE
                 , FAM_FIXED_ASSETS_ID
                 , FIX_NUMBER
                 , C_FAM_TRANSACTION_TYP
                 , HRM_PERSON_ID
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , IMF_TEXT1
                 , IMF_TEXT2
                 , IMF_TEXT3
                 , IMF_TEXT4
                 , IMF_TEXT5
                 , IMF_NUMBER
                 , IMF_NUMBER2
                 , IMF_NUMBER3
                 , IMF_NUMBER4
                 , IMF_NUMBER5
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (lMainImputationId   -- ACI_FINANCIAL_IMPUTATION_ID
                 , iDocumentId   -- ACI_DOCUMENT_ID
                 , 'MAN'   -- IMF_TYPE
                 , 'STD'   -- IMF_GENRE
                 , '1'   -- C_GENRE_TRANSACTION
                 , 0   -- IMF_PRIMARY
                 , iImpDescr   -- IMF_DESCRIPTION
                 , 0   -- IMF_BASE_PRICE
                 , lValueD2   -- IMF_AMOUNT_LC_D
                 , lValueC2   -- IMF_AMOUNT_LC_C
                 , 0   -- IMF_EXCHANGE_RATE
                 , 0   -- IMF_AMOUNT_FC_D
                 , 0   -- IMF_AMOUNT_FC_C
                 , trunc(iMovementDate)   -- IMF_VALUE_DATE
                 , trunc(iMovementDate)   -- IMF_TRANSACTION_DATE
                 , iDivisionAccountId2   -- ACS_DIVISION_ACCOUNT_ID
                 , lDivAccNumber2   -- DIV_NUMBER
                 , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                 , ACS_FUNCTION.GetLocalCurrencyName   -- CURRENCY1
                 , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                 , ACS_FUNCTION.GetLocalCurrencyName   -- CURRENCY2
                 , iFinancialAccountId2   -- ACS_FINANCIAL_ACCOUNT_ID
                 , lFinAccNumber2   -- ACC_NUMBER
                 , ACS_FUNCTION.GetPeriodId(trunc(iMovementDate), '2')   -- ACS_PERIOD_ID
                 , lNoPeriod   -- PER_NO_PERIOD
                 , iGoodId
                 , ltTextRecoveringRec.goo_major_reference
                 , iThirdId
                 , ltTextRecoveringRec.per_key1
                 , ltTextRecoveringRec.per_key2
                 , iRecordId
                 , ltTextRecoveringRec.rco_number
                 , ltTextRecoveringRec.rco_title
                 , ioAccountInfo2.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                 , ltTextRecoveringRec.fix_number
                 , ioAccountInfo2.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                 , ACS_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(ioAccountInfo2.DEF_HRM_PERSON)   -- HRM_PERSON_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE1   -- DIC_IMP_FREE1_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE2   -- DIC_IMP_FREE2_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE3   -- DIC_IMP_FREE3_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE4   -- DIC_IMP_FREE4_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE5   -- DIC_IMP_FREE5_ID
                 , ioAccountInfo2.DEF_TEXT1   -- IMF_TEXT1
                 , ioAccountInfo2.DEF_TEXT2   -- IMF_TEXT2
                 , ioAccountInfo2.DEF_TEXT3   -- IMF_TEXT3
                 , ioAccountInfo2.DEF_TEXT4   -- IMF_TEXT4
                 , ioAccountInfo2.DEF_TEXT5   -- IMF_TEXT5
                 , to_number(ioAccountInfo2.DEF_NUMBER1)   -- IMF_NUMBER
                 , to_number(ioAccountInfo2.DEF_NUMBER2)   -- IMF_NUMBER2
                 , to_number(ioAccountInfo2.DEF_NUMBER3)   -- IMF_NUMBER3
                 , to_number(ioAccountInfo2.DEF_NUMBER4)   -- IMF_NUMBER4
                 , to_number(ioAccountInfo2.DEF_NUMBER5)   -- IMF_NUMBER5
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );
    end if;

    -- imputation analytique de contre-partie
    if     ibAnalImputation = 1
       and (   iCpnAccountId2 is not null
            or iCdaAccountId2 is not null
            or iPfAccountId2 is not null
            or iPjAccountId2 is not null
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
                 , GCO_GOOD_ID
                 , GOO_MAJOR_REFERENCE
                 , PAC_PERSON_ID
                 , PER_KEY1
                 , PER_KEY2
                 , DOC_RECORD_ID
                 , RCO_NUMBER
                 , RCO_TITLE
                 , FAM_FIXED_ASSETS_ID
                 , FIX_NUMBER
                 , C_FAM_TRANSACTION_TYP
                 , HRM_PERSON_ID
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , IMM_TEXT1
                 , IMM_TEXT2
                 , IMM_TEXT3
                 , IMM_TEXT4
                 , IMM_TEXT5
                 , IMM_NUMBER
                 , IMM_NUMBER2
                 , IMM_NUMBER3
                 , IMM_NUMBER4
                 , IMM_NUMBER5
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aci_id_seq.nextval   -- ACI_MGM_IMPUTATION_ID
                 , iDocumentId   -- ACI_DOCUMENT_ID
                 , lMainImputationId   -- ACI_FINANCIAL_IMPUTATION_ID
                 , 'MAN'   -- IMM_TYPE
                 , 'STD'   -- IMM_GENRE
                 , 0   -- IMM_PRIMARY
                 , iImpDescr   -- IMM_DESCRIPTION
                 , lValueD2   -- IMM_AMOUNT_LC_D
                 , lValueC2   -- IMM_AMOUNT_LC_C
                 , 0   -- IMM_EXCHANGE_RATE
                 , 0   -- IMM_BASE_PRICE
                 , 0   -- IMM_AMOUNT_FC_D
                 , 0   -- IMM_AMOUNT_FC_C
                 , 0   -- IMM_AMOUNT_EUR_D
                 , 0   -- IMM_AMOUNT_EUR_C
                 , trunc(iMovementDate)   -- IMM_VALUE_DATE
                 , trunc(iMovementDate)   -- IMM_TRANSACTION_DATE
                 , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                 , lMoneyName   -- CURRENCY1
                 , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                 , lMoneyName   -- CURRENCY2
                 , iCdaAccountId2   -- ACS_CDA_ACCOUNT_ID
                 , lCdaAccNumber2   -- CDA_NUMBER
                 , iCpnAccountId2   -- ACS_CPN_ACCOUNT_ID
                 , lCpnAccNumber2   -- CPN_NUMBER
                 , iPfAccountId2   -- ACS_PF_ACCOUNT_ID
                 , lPfAccNumber2   -- PF_NUMBER
                 , iPjAccountId2   -- ACS_PJ_ACCOUNT_ID
                 , lPjAccNumber2   -- PJ_NUMBER
                 , ACS_FUNCTION.GetPeriodId(trunc(iMovementDate), '2')   -- ACS_PERIOD_ID
                 , lNoPeriod   -- PER_NO_PERIOD
                 , iGoodId
                 , ltTextRecoveringRec.goo_major_reference
                 , iThirdId
                 , ltTextRecoveringRec.per_key1
                 , ltTextRecoveringRec.per_key2
                 , iRecordId
                 , ltTextRecoveringRec.rco_number
                 , ltTextRecoveringRec.rco_title
                 , ioAccountInfo2.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                 , ltTextRecoveringRec.fix_number
                 , ioAccountInfo2.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                 , ACS_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(ioAccountInfo2.DEF_HRM_PERSON)   -- HRM_PERSON_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE1   -- DIC_IMP_FREE1_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE2   -- DIC_IMP_FREE2_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE3   -- DIC_IMP_FREE3_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE4   -- DIC_IMP_FREE4_ID
                 , ioAccountInfo2.DEF_DIC_IMP_FREE5   -- DIC_IMP_FREE5_ID
                 , ioAccountInfo2.DEF_TEXT1   -- IMM_TEXT1
                 , ioAccountInfo2.DEF_TEXT2   -- IMM_TEXT2
                 , ioAccountInfo2.DEF_TEXT3   -- IMM_TEXT3
                 , ioAccountInfo2.DEF_TEXT4   -- IMM_TEXT4
                 , ioAccountInfo2.DEF_TEXT5   -- IMM_TEXT5
                 , to_number(ioAccountInfo2.DEF_NUMBER1)   -- IMM_NUMBER
                 , to_number(ioAccountInfo2.DEF_NUMBER2)   -- IMM_NUMBER2
                 , to_number(ioAccountInfo2.DEF_NUMBER3)   -- IMM_NUMBER3
                 , to_number(ioAccountInfo2.DEF_NUMBER4)   -- IMM_NUMBER4
                 , to_number(ioAccountInfo2.DEF_NUMBER5)   -- IMM_NUMBER5
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );
    end if;

    ----
    -- Traitement des imputations d'écart d'achat éventuel.
    --
    lAcsGapFinancialAccountID  := null;
    lAccGapNumber              := null;
    lAcsGapCPNAccountID        := null;
    lAccGapCPNNumber           := null;

    if     (nvl(iGapPurchasePrice, 0) <> 0)
       and (   ibFinancialImputation = 1
            or ibAnalImputation = 1) then
      ----
      -- Détermine les montants et les comptes à imputer
      --
      -- Si écart défavorable sur mouvement d'entrée. Il faut créer une imputation au débit avec le montant d'écart sur
      -- le compte d'écart d'achat. Et il faut également créer une imputation contre-partie du même montant mais au
      -- crédit sur le compte pertes et profits.
      --
      -- Si écart défavorable sur mouvement de sortie. Il faut créer une imputation au crédit avec le montant d'écart sur
      -- le compte d'écart d'achat. Et il faut également créer une imputation contre-partie du même montant mais au
      -- débit sur le compte pertes et profits.
      --
      if (iGapPurchasePrice > 0) then
        if (ibInputMovement = 1) then   -- Mouvement d'entrée
          -- Données pour les imputations sur compte d'écart
          lGapValueD             := iGapPurchasePrice;
          lGapValueC             := 0;
          -- Données pour les imputations sur compte pertes et profits
          lAgaintsPartGapValueD  := 0;
          lAgaintsPartGapValueC  := iGapPurchasePrice;
        else   -- Mouvement de sortie
          -- Données pour les imputations sur compte d'écart
          lGapValueD             := 0;
          lGapValueC             := iGapPurchasePrice;
          -- Données pour les imputations sur compte pertes et profits
          lAgaintsPartGapValueD  := iGapPurchasePrice;
          lAgaintsPartGapValueC  := 0;
        end if;

        ----
        -- Détermine le compte d'écart d'achat défavorable à utiliser
        --
        -- Si la CPN d'écart est définie sur la CPN de l'imputation d'inventaire permanent
        --   reprendre la CPN d'écart définie.
        -- Sinon
        --   utiliser la CPN de l'imputation d'inventaire permanent pour l'imputation de l'écart.
        --
        begin
          select nvl(FIN_GAP.ACS_FINANCIAL_ACCOUNT_ID, FIN.ACS_FINANCIAL_ACCOUNT_ID) FIN_ID
               , nvl(ACC_GAP.ACC_NUMBER, ACC_FIN.ACC_NUMBER) FIN_ACCOUNT_NAME
               , nvl(FIN_GAP.ACS_CPN_ACCOUNT_ID, MGM.ACS_CPN_ACCOUNT_ID) CPN_ID
               , nvl(ACC_CPN.ACC_NUMBER, ACC_MGM.ACC_NUMBER) CPN_ACCOUNT_NAME
            into lAcsGapFinancialAccountID
               , lAccGapNumber
               , lAcsGapCPNAccountID
               , lAccGapCPNNumber
            from ACS_FINANCIAL_ACCOUNT FIN
               , ACS_FINANCIAL_ACCOUNT FIN_GAP
               , ACS_CPN_ACCOUNT MGM
               , ACS_CPN_VARIANCE ACV
               , ACS_ACCOUNT ACC_CPN
               , ACS_ACCOUNT ACC_GAP
               , ACS_ACCOUNT ACC_MGM
               , ACS_ACCOUNT ACC_FIN
           where FIN.ACS_FINANCIAL_ACCOUNT_ID = iFinancialAccountId2
             and ACC_FIN.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
             and MGM.ACS_CPN_ACCOUNT_ID = FIN.ACS_CPN_ACCOUNT_ID
             and ACC_MGM.ACS_ACCOUNT_ID = MGM.ACS_CPN_ACCOUNT_ID
             and ACV.ACS_CPN_VARIANCE_ID(+) = MGM.ACS_CPN_ACCOUNT_ID
             and FIN_GAP.ACS_CPN_ACCOUNT_ID(+) = ACV.ACS_CPN_DEBIT_VALUE_ID   -- Ecart défavorable
             and ACC_GAP.ACS_ACCOUNT_ID(+) = FIN_GAP.ACS_FINANCIAL_ACCOUNT_ID
             and ACC_CPN.ACS_ACCOUNT_ID(+) = FIN_GAP.ACS_CPN_ACCOUNT_ID;
        exception
          when no_data_found then
            lAcsGapFinancialAccountID  := null;
            lAccGapNumber              := null;
            lAcsGapCPNAccountID        := null;
            lAccGapCPNNumber           := null;
        end;
      else   -- (iGapPurchasePrice < 0)
        ----
        -- Si écart favorable sur mouvement d'entrée. Il faut créer une imputation au crédit avec le montant d'écart
        -- sur le compte d'écart d'achat. Et il faut également créer une imputation contre-partie du même montant mais
        -- au débit sur le compte pertes et profits.
        --
        -- Si écart favorable sur mouvement de sortie. Il faut créer une imputation au débit avec le montant d'écart
        -- sur le compte d'écart d'achat. Et il faut également créer une imputation contre-partie du même montant mais
        -- au crédit sur le compte pertes et profits.
        --
        if (ibInputMovement = 1) then   -- Mouvement d'entrée
          -- Données pour les imputations sur compte d'écart
          lGapValueD             := 0;
          lGapValueC             := iGapPurchasePrice * -1;
          -- Données pour les imputations sur compte pertes et profits
          lAgaintsPartGapValueD  := iGapPurchasePrice * -1;
          lAgaintsPartGapValueC  := 0;
        else   -- Mouvement de sortie
          -- Données pour les imputations sur compte d'écart
          lGapValueD             := iGapPurchasePrice * -1;
          lGapValueC             := 0;
          -- Données pour les imputations sur compte pertes et profits
          lAgaintsPartGapValueD  := 0;
          lAgaintsPartGapValueC  := iGapPurchasePrice * -1;
        end if;

        ----
        -- Détermine le compte d'écart d'achat favorable à utiliser
        --
        -- Si la CPN d'écart est définie sur la CPN de l'imputation d'inventaire permanent
        --   reprendre la CPN d'écart définie.
        -- Sinon
        --   utiliser la CPN de l'imputation d'inventaire permanent pour l'imputation de l'écart.
        --
        begin
          select nvl(FIN_GAP.ACS_FINANCIAL_ACCOUNT_ID, FIN.ACS_FINANCIAL_ACCOUNT_ID) FIN_ID
               , nvl(ACC_GAP.ACC_NUMBER, ACC_FIN.ACC_NUMBER) FIN_ACCOUNT_NAME
               , nvl(FIN_GAP.ACS_CPN_ACCOUNT_ID, MGM.ACS_CPN_ACCOUNT_ID) CPN_ID
               , nvl(ACC_CPN.ACC_NUMBER, ACC_MGM.ACC_NUMBER) CPN_ACCOUNT_NAME
            into lAcsGapFinancialAccountID
               , lAccGapNumber
               , lAcsGapCPNAccountID
               , lAccGapCPNNumber
            from ACS_FINANCIAL_ACCOUNT FIN
               , ACS_FINANCIAL_ACCOUNT FIN_GAP
               , ACS_CPN_ACCOUNT MGM
               , ACS_CPN_VARIANCE ACV
               , ACS_ACCOUNT ACC_CPN
               , ACS_ACCOUNT ACC_GAP
               , ACS_ACCOUNT ACC_MGM
               , ACS_ACCOUNT ACC_FIN
           where FIN.ACS_FINANCIAL_ACCOUNT_ID = iFinancialAccountId2
             and ACC_FIN.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
             and MGM.ACS_CPN_ACCOUNT_ID = FIN.ACS_CPN_ACCOUNT_ID
             and ACC_MGM.ACS_ACCOUNT_ID = MGM.ACS_CPN_ACCOUNT_ID
             and ACV.ACS_CPN_VARIANCE_ID(+) = MGM.ACS_CPN_ACCOUNT_ID
             and FIN_GAP.ACS_CPN_ACCOUNT_ID(+) = ACV.ACS_CPN_CREDIT_VALUE_ID   -- Ecart favorable
             and ACC_GAP.ACS_ACCOUNT_ID(+) = FIN_GAP.ACS_FINANCIAL_ACCOUNT_ID
             and ACC_CPN.ACS_ACCOUNT_ID(+) = FIN_GAP.ACS_CPN_ACCOUNT_ID;
        exception
          when no_data_found then
            lAcsGapFinancialAccountID  := null;
            lAccGapNumber              := null;
            lAcsGapCPNAccountID        := null;
            lAccGapCPNNumber           := null;
        end;
      end if;

      ----
      -- Construit la description de l'imputation d'écart selon les modèles ci-dessous :
      --
      --  Description = Description imputation d'origine || ' - ' || 'Ecart'
      --  Description = Description imputation d'origine || ' - ' || 'Ecart' || ' (extourne)'
      --
      lImfDescription  := PCS.PC_FUNCTIONS.TranslateWord('Ecart');

      if (nvl(ibExtourneMvt, 0) = 1) then
        lImfDescription  := lImfDescription || ' (' || PCS.PC_FUNCTIONS.TranslateWord('extourne') || ')';
      end if;

      lImfDescription  := iImpDescr || ' - ' || lImfDescription;

      -- si création d'une imputation financière et écart effectif
      if     ibFinancialImputation = 1
         and lAcsGapFinancialAccountID is not null then
        -- recherche de l'id de l'imputation
        select ACI_ID_SEQ.nextval
          into lMainImputationId
          from dual;

        -- création de l'imputation sur le compte d'écart d'achat
        insert into ACI_FINANCIAL_IMPUTATION
                    (ACI_FINANCIAL_IMPUTATION_ID
                   , ACI_DOCUMENT_ID
                   , IMF_TYPE
                   , IMF_GENRE
                   , C_GENRE_TRANSACTION
                   , IMF_PRIMARY
                   , IMF_DESCRIPTION
                   , IMF_BASE_PRICE
                   , IMF_AMOUNT_LC_D
                   , IMF_AMOUNT_LC_C
                   , IMF_EXCHANGE_RATE
                   , IMF_AMOUNT_FC_D
                   , IMF_AMOUNT_FC_C
                   , IMF_VALUE_DATE
                   , IMF_TRANSACTION_DATE
                   , ACS_DIVISION_ACCOUNT_ID
                   , DIV_NUMBER
                   , ACS_FINANCIAL_CURRENCY_ID
                   , CURRENCY1
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , CURRENCY2
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACC_NUMBER
                   , ACS_PERIOD_ID
                   , PER_NO_PERIOD
                   , GCO_GOOD_ID
                   , GOO_MAJOR_REFERENCE
                   , PAC_PERSON_ID
                   , PER_KEY1
                   , PER_KEY2
                   , DOC_RECORD_ID
                   , RCO_NUMBER
                   , RCO_TITLE
                   , FAM_FIXED_ASSETS_ID
                   , FIX_NUMBER
                   , C_FAM_TRANSACTION_TYP
                   , HRM_PERSON_ID
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , IMF_TEXT1
                   , IMF_TEXT2
                   , IMF_TEXT3
                   , IMF_TEXT4
                   , IMF_TEXT5
                   , IMF_NUMBER
                   , IMF_NUMBER2
                   , IMF_NUMBER3
                   , IMF_NUMBER4
                   , IMF_NUMBER5
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (lMainImputationId   -- ACI_FINANCIAL_IMPUTATION_ID
                   , iDocumentId   -- ACI_DOCUMENT_ID
                   , 'MAN'   -- IMF_TYPE
                   , 'STD'   -- IMF_GENRE
                   , '1'   -- C_GENRE_TRANSACTION
                   , 0   -- IMF_PRIMARY
                   , lImfDescription   -- IMF_DESCRIPTION
                   , 0   -- IMF_BASE_PRICE
                   , lGapValueD   -- IMF_AMOUNT_LC_D
                   , lGapValueC   -- IMF_AMOUNT_LC_C
                   , 0   -- IMF_EXCHANGE_RATE
                   , 0   -- IMF_AMOUNT_FC_D
                   , 0   -- IMF_AMOUNT_FC_C
                   , trunc(iMovementDate)   -- IMF_VALUE_DATE
                   , trunc(iMovementDate)   -- IMF_TRANSACTION_DATE
                   , iDivisionAccountId2   -- ACS_DIVISION_ACCOUNT_ID
                   , lDivAccNumber2   -- DIV_NUMBER
                   , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                   , ACS_FUNCTION.GetLocalCurrencyName   -- CURRENCY1
                   , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                   , ACS_FUNCTION.GetLocalCurrencyName   -- CURRENCY2
                   , lAcsGapFinancialAccountID   -- ACS_FINANCIAL_ACCOUNT_ID
                   , lAccGapNumber   -- ACC_NUMBER
                   , ACS_FUNCTION.GetPeriodId(trunc(iMovementDate), '2')   -- ACS_PERIOD_ID
                   , lNoPeriod   -- PER_NO_PERIOD
                   , iGoodId
                   , ltTextRecoveringRec.goo_major_reference
                   , iThirdId
                   , ltTextRecoveringRec.per_key1
                   , ltTextRecoveringRec.per_key2
                   , iRecordId
                   , ltTextRecoveringRec.rco_number
                   , ltTextRecoveringRec.rco_title
                   , ioAccountInfo2.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                   , ltTextRecoveringRec.fix_number
                   , ioAccountInfo2.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                   , ACS_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(ioAccountInfo2.DEF_HRM_PERSON)   -- HRM_PERSON_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE1   -- DIC_IMP_FREE1_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE2   -- DIC_IMP_FREE2_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE3   -- DIC_IMP_FREE3_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE4   -- DIC_IMP_FREE4_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE5   -- DIC_IMP_FREE5_ID
                   , ioAccountInfo2.DEF_TEXT1   -- IMF_TEXT1
                   , ioAccountInfo2.DEF_TEXT2   -- IMF_TEXT2
                   , ioAccountInfo2.DEF_TEXT3   -- IMF_TEXT3
                   , ioAccountInfo2.DEF_TEXT4   -- IMF_TEXT4
                   , ioAccountInfo2.DEF_TEXT5   -- IMF_TEXT5
                   , to_number(ioAccountInfo2.DEF_NUMBER1)   -- IMF_NUMBER
                   , to_number(ioAccountInfo2.DEF_NUMBER2)   -- IMF_NUMBER2
                   , to_number(ioAccountInfo2.DEF_NUMBER3)   -- IMF_NUMBER3
                   , to_number(ioAccountInfo2.DEF_NUMBER4)   -- IMF_NUMBER4
                   , to_number(ioAccountInfo2.DEF_NUMBER5)   -- IMF_NUMBER5
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    );

        -- recherche de l'id de l'imputation
        select ACI_ID_SEQ.nextval
          into lMainImputationId2
          from dual;

        -- création de l'imputation de contre partie de l'imputation d'écart d'achat sur le compte pertes et profits
        insert into ACI_FINANCIAL_IMPUTATION
                    (ACI_FINANCIAL_IMPUTATION_ID
                   , ACI_DOCUMENT_ID
                   , IMF_TYPE
                   , IMF_GENRE
                   , C_GENRE_TRANSACTION
                   , IMF_PRIMARY
                   , IMF_DESCRIPTION
                   , IMF_BASE_PRICE
                   , IMF_AMOUNT_LC_D
                   , IMF_AMOUNT_LC_C
                   , IMF_EXCHANGE_RATE
                   , IMF_AMOUNT_FC_D
                   , IMF_AMOUNT_FC_C
                   , IMF_VALUE_DATE
                   , IMF_TRANSACTION_DATE
                   , ACS_DIVISION_ACCOUNT_ID
                   , DIV_NUMBER
                   , ACS_FINANCIAL_CURRENCY_ID
                   , CURRENCY1
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , CURRENCY2
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACC_NUMBER
                   , ACS_PERIOD_ID
                   , PER_NO_PERIOD
                   , GCO_GOOD_ID
                   , GOO_MAJOR_REFERENCE
                   , PAC_PERSON_ID
                   , PER_KEY1
                   , PER_KEY2
                   , DOC_RECORD_ID
                   , RCO_NUMBER
                   , RCO_TITLE
                   , FAM_FIXED_ASSETS_ID
                   , FIX_NUMBER
                   , C_FAM_TRANSACTION_TYP
                   , HRM_PERSON_ID
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , IMF_TEXT1
                   , IMF_TEXT2
                   , IMF_TEXT3
                   , IMF_TEXT4
                   , IMF_TEXT5
                   , IMF_NUMBER
                   , IMF_NUMBER2
                   , IMF_NUMBER3
                   , IMF_NUMBER4
                   , IMF_NUMBER5
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (lMainImputationId2   -- ACI_FINANCIAL_IMPUTATION_ID
                   , iDocumentId   -- ACI_DOCUMENT_ID
                   , 'MAN'   -- IMF_TYPE
                   , 'STD'   -- IMF_GENRE
                   , '1'   -- C_GENRE_TRANSACTION
                   , 0   -- IMF_PRIMARY
                   , lImfDescription   -- IMF_DESCRIPTION
                   , 0   -- IMF_BASE_PRICE
                   , lAgaintsPartGapValueD   -- IMF_AMOUNT_LC_D
                   , lAgaintsPartGapValueC   -- IMF_AMOUNT_LC_C
                   , 0   -- IMF_EXCHANGE_RATE
                   , 0   -- IMF_AMOUNT_FC_D
                   , 0   -- IMF_AMOUNT_FC_C
                   , trunc(iMovementDate)   -- IMF_VALUE_DATE
                   , trunc(iMovementDate)   -- IMF_TRANSACTION_DATE
                   , iDivisionAccountId2   -- ACS_DIVISION_ACCOUNT_ID
                   , lDivAccNumber2   -- DIV_NUMBER
                   , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                   , ACS_FUNCTION.GetLocalCurrencyName   -- CURRENCY1
                   , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                   , ACS_FUNCTION.GetLocalCurrencyName   -- CURRENCY2
                   , iFinancialAccountId2   -- ACS_FINANCIAL_ACCOUNT_ID
                   , lFinAccNumber2   -- ACC_NUMBER
                   , ACS_FUNCTION.GetPeriodId(trunc(iMovementDate), '2')   -- ACS_PERIOD_ID
                   , lNoPeriod   -- PER_NO_PERIOD
                   , iGoodId
                   , ltTextRecoveringRec.goo_major_reference
                   , iThirdId
                   , ltTextRecoveringRec.per_key1
                   , ltTextRecoveringRec.per_key2
                   , iRecordId
                   , ltTextRecoveringRec.rco_number
                   , ltTextRecoveringRec.rco_title
                   , ioAccountInfo2.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                   , ltTextRecoveringRec.fix_number
                   , ioAccountInfo2.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                   , ACS_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(ioAccountInfo2.DEF_HRM_PERSON)   -- HRM_PERSON_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE1   -- DIC_IMP_FREE1_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE2   -- DIC_IMP_FREE2_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE3   -- DIC_IMP_FREE3_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE4   -- DIC_IMP_FREE4_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE5   -- DIC_IMP_FREE5_ID
                   , ioAccountInfo2.DEF_TEXT1   -- IMF_TEXT1
                   , ioAccountInfo2.DEF_TEXT2   -- IMF_TEXT2
                   , ioAccountInfo2.DEF_TEXT3   -- IMF_TEXT3
                   , ioAccountInfo2.DEF_TEXT4   -- IMF_TEXT4
                   , ioAccountInfo2.DEF_TEXT5   -- IMF_TEXT5
                   , to_number(ioAccountInfo2.DEF_NUMBER1)   -- IMF_NUMBER
                   , to_number(ioAccountInfo2.DEF_NUMBER2)   -- IMF_NUMBER2
                   , to_number(ioAccountInfo2.DEF_NUMBER3)   -- IMF_NUMBER3
                   , to_number(ioAccountInfo2.DEF_NUMBER4)   -- IMF_NUMBER4
                   , to_number(ioAccountInfo2.DEF_NUMBER5)   -- IMF_NUMBER5
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    );
      end if;

      -- si création d'une imputation analytique et écart effectif
      if     ibAnalImputation = 1
         and lAcsGapCPNAccountID is not null
         and (   iCpnAccountId2 is not null
              or iCdaAccountId2 is not null
              or iPfAccountId2 is not null
              or iPjAccountId2 is not null
             ) then
        -- création de l'imputation analytique sur le compte d'écart d'achat
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
                   , GCO_GOOD_ID
                   , GOO_MAJOR_REFERENCE
                   , PAC_PERSON_ID
                   , PER_KEY1
                   , PER_KEY2
                   , DOC_RECORD_ID
                   , RCO_NUMBER
                   , RCO_TITLE
                   , FAM_FIXED_ASSETS_ID
                   , FIX_NUMBER
                   , C_FAM_TRANSACTION_TYP
                   , HRM_PERSON_ID
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , IMM_TEXT1
                   , IMM_TEXT2
                   , IMM_TEXT3
                   , IMM_TEXT4
                   , IMM_TEXT5
                   , IMM_NUMBER
                   , IMM_NUMBER2
                   , IMM_NUMBER3
                   , IMM_NUMBER4
                   , IMM_NUMBER5
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (aci_id_seq.nextval   -- ACI_MGM_IMPUTATION_ID
                   , iDocumentId   -- ACI_DOCUMENT_ID
                   , lMainImputationId   -- ACI_FINANCIAL_IMPUTATION_ID
                   , 'MAN'   -- IMM_TYPE
                   , 'STD'   -- IMM_GENRE
                   , 0   -- IMM_PRIMARY
                   , lImfDescription   -- IMM_DESCRIPTION
                   , lGapValueD   -- IMM_AMOUNT_LC_D
                   , lGapValueC   -- IMM_AMOUNT_LC_C
                   , 0   -- IMM_EXCHANGE_RATE
                   , 0   -- IMM_BASE_PRICE
                   , 0   -- IMM_AMOUNT_FC_D
                   , 0   -- IMM_AMOUNT_FC_C
                   , 0   -- IMM_AMOUNT_EUR_D
                   , 0   -- IMM_AMOUNT_EUR_C
                   , trunc(iMovementDate)   -- IMM_VALUE_DATE
                   , trunc(iMovementDate)   -- IMM_TRANSACTION_DATE
                   , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                   , lMoneyName   -- CURRENCY1
                   , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                   , lMoneyName   -- CURRENCY2
                   , iCdaAccountId2   -- ACS_CDA_ACCOUNT_ID
                   , lCdaAccNumber2   -- CDA_NUMBER
                   , lAcsGapCPNAccountID   -- ACS_CPN_ACCOUNT_ID
                   , lAccGapCPNNumber   -- CPN_NUMBER
                   , iPfAccountId2   -- ACS_PF_ACCOUNT_ID
                   , lPfAccNumber2   -- PF_NUMBER
                   , iPjAccountId2   -- ACS_PJ_ACCOUNT_ID
                   , lPjAccNumber2   -- PJ_NUMBER
                   , ACS_FUNCTION.GetPeriodId(trunc(iMovementDate), '2')   -- ACS_PERIOD_ID
                   , lNoPeriod   -- PER_NO_PERIOD
                   , iGoodId
                   , ltTextRecoveringRec.goo_major_reference
                   , iThirdId
                   , ltTextRecoveringRec.per_key1
                   , ltTextRecoveringRec.per_key2
                   , iRecordId
                   , ltTextRecoveringRec.rco_number
                   , ltTextRecoveringRec.rco_title
                   , ioAccountInfo2.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                   , ltTextRecoveringRec.fix_number
                   , ioAccountInfo2.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                   , ACS_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(ioAccountInfo2.DEF_HRM_PERSON)   -- HRM_PERSON_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE1   -- DIC_IMP_FREE1_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE2   -- DIC_IMP_FREE2_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE3   -- DIC_IMP_FREE3_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE4   -- DIC_IMP_FREE4_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE5   -- DIC_IMP_FREE5_ID
                   , ioAccountInfo2.DEF_TEXT1   -- IMM_TEXT1
                   , ioAccountInfo2.DEF_TEXT2   -- IMM_TEXT2
                   , ioAccountInfo2.DEF_TEXT3   -- IMM_TEXT3
                   , ioAccountInfo2.DEF_TEXT4   -- IMM_TEXT4
                   , ioAccountInfo2.DEF_TEXT5   -- IMM_TEXT5
                   , to_number(ioAccountInfo2.DEF_NUMBER1)   -- IMM_NUMBER
                   , to_number(ioAccountInfo2.DEF_NUMBER2)   -- IMM_NUMBER2
                   , to_number(ioAccountInfo2.DEF_NUMBER3)   -- IMM_NUMBER3
                   , to_number(ioAccountInfo2.DEF_NUMBER4)   -- IMM_NUMBER4
                   , to_number(ioAccountInfo2.DEF_NUMBER5)   -- IMM_NUMBER5
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    );

        -- création de l'imputation de contre partie de l'imputation analytique d'écart d'achat sur le compte pertes et
        -- profits
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
                   , GCO_GOOD_ID
                   , GOO_MAJOR_REFERENCE
                   , PAC_PERSON_ID
                   , PER_KEY1
                   , PER_KEY2
                   , DOC_RECORD_ID
                   , RCO_NUMBER
                   , RCO_TITLE
                   , FAM_FIXED_ASSETS_ID
                   , FIX_NUMBER
                   , C_FAM_TRANSACTION_TYP
                   , HRM_PERSON_ID
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , IMM_TEXT1
                   , IMM_TEXT2
                   , IMM_TEXT3
                   , IMM_TEXT4
                   , IMM_TEXT5
                   , IMM_NUMBER
                   , IMM_NUMBER2
                   , IMM_NUMBER3
                   , IMM_NUMBER4
                   , IMM_NUMBER5
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (aci_id_seq.nextval   -- ACI_MGM_IMPUTATION_ID
                   , iDocumentId   -- ACI_DOCUMENT_ID
                   , lMainImputationId2   -- ACI_FINANCIAL_IMPUTATION_ID
                   , 'MAN'   -- IMM_TYPE
                   , 'STD'   -- IMM_GENRE
                   , 0   -- IMM_PRIMARY
                   , lImfDescription   -- IMM_DESCRIPTION
                   , lAgaintsPartGapValueD   -- IMM_AMOUNT_LC_D
                   , lAgaintsPartGapValueC   -- IMM_AMOUNT_LC_C
                   , 0   -- IMM_EXCHANGE_RATE
                   , 0   -- IMM_BASE_PRICE
                   , 0   -- IMM_AMOUNT_FC_D
                   , 0   -- IMM_AMOUNT_FC_C
                   , 0   -- IMM_AMOUNT_EUR_D
                   , 0   -- IMM_AMOUNT_EUR_C
                   , trunc(iMovementDate)   -- IMM_VALUE_DATE
                   , trunc(iMovementDate)   -- IMM_TRANSACTION_DATE
                   , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                   , lMoneyName   -- CURRENCY1
                   , ACS_FUNCTION.GetLocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                   , lMoneyName   -- CURRENCY2
                   , iCdaAccountId2   -- ACS_CDA_ACCOUNT_ID
                   , lCdaAccNumber2   -- CDA_NUMBER
                   , iCpnAccountId2   -- ACS_CPN_ACCOUNT_ID
                   , lCpnAccNumber2   -- CPN_NUMBER
                   , iPfAccountId2   -- ACS_PF_ACCOUNT_ID
                   , lPfAccNumber2   -- PF_NUMBER
                   , iPjAccountId2   -- ACS_PJ_ACCOUNT_ID
                   , lPjAccNumber2   -- PJ_NUMBER
                   , ACS_FUNCTION.GetPeriodId(trunc(iMovementDate), '2')   -- ACS_PERIOD_ID
                   , lNoPeriod   -- PER_NO_PERIOD
                   , iGoodId
                   , ltTextRecoveringRec.goo_major_reference
                   , iThirdId
                   , ltTextRecoveringRec.per_key1
                   , ltTextRecoveringRec.per_key2
                   , iRecordId
                   , ltTextRecoveringRec.rco_number
                   , ltTextRecoveringRec.rco_title
                   , ioAccountInfo2.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                   , ltTextRecoveringRec.fix_number
                   , ioAccountInfo2.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                   , ACS_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(ioAccountInfo2.DEF_HRM_PERSON)   -- HRM_PERSON_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE1   -- DIC_IMP_FREE1_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE2   -- DIC_IMP_FREE2_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE3   -- DIC_IMP_FREE3_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE4   -- DIC_IMP_FREE4_ID
                   , ioAccountInfo2.DEF_DIC_IMP_FREE5   -- DIC_IMP_FREE5_ID
                   , ioAccountInfo2.DEF_TEXT1   -- IMM_TEXT1
                   , ioAccountInfo2.DEF_TEXT2   -- IMM_TEXT2
                   , ioAccountInfo2.DEF_TEXT3   -- IMM_TEXT3
                   , ioAccountInfo2.DEF_TEXT4   -- IMM_TEXT4
                   , ioAccountInfo2.DEF_TEXT5   -- IMM_TEXT5
                   , to_number(ioAccountInfo2.DEF_NUMBER1)   -- IMM_NUMBER
                   , to_number(ioAccountInfo2.DEF_NUMBER2)   -- IMM_NUMBER2
                   , to_number(ioAccountInfo2.DEF_NUMBER3)   -- IMM_NUMBER3
                   , to_number(ioAccountInfo2.DEF_NUMBER4)   -- IMM_NUMBER4
                   , to_number(ioAccountInfo2.DEF_NUMBER5)   -- IMM_NUMBER5
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    );
      end if;
    end if;
  end pInterfaceImputations;

  /**
  * Description
  *   procedure principale a appeler depuis le trigger d'insertion des mouvements de stock
  *   elle appelle la procedure de creation d'entete et la procedure de creation des
  *   imputations
  **/
  procedure createInterfaceDocument(
    ioMovementRecord  in out FWK_TYP_STM_ENTITY.tStockMovement
  , ioAccountInfo     in out ACS_LIB_LOGISTIC_FINANCIAL.tAccountInfo
  , ioAccountInfo2    in out ACS_LIB_LOGISTIC_FINANCIAL.tAccountInfo
  , iGapPurchasePrice in     number default null
  )
  is
    lDocumentId             ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    lTransactionCatKey      ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type;
    lTransactionTypKey      ACJ_JOB_TYPE.TYP_KEY%type;
    lJobTypeSCatalogueId    ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID%type;
    lContinuousInventar     GCO_PRODUCT.PDT_CONTINUOUS_INVENTAR%type;
    lManagementMode         GCO_GOOD.C_MANAGEMENT_MODE%type;
    lMovementSign           STM_MOVEMENT_KIND.MOK_STANDARD_SIGN%type;
    lMovementCode           STM_MOVEMENT_KIND.C_MOVEMENT_CODE%type;
    lMovementType           STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lTypeCatalogue          ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
    lInputMovement          number(1);
    lFinancialImputation    number(1);
    lAnalImputation         number(1);
    lDocumentNumber         ACI_DOCUMENT.DOC_NUMBER%type;
    lManualDocumentNumber   ACI_DOCUMENT.DOC_NUMBER%type;
    lImputationDescr        ACI_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
    lAciFinancialLink       ACJ_JOB_TYPE.C_ACI_FINANCIAL_LINK%type;
    lCreateGapPurchasePrice number(1);
    lGapPurchasePrice       DOC_POSITION_DETAIL.PDE_GAP_PURCHASE_PRICE%type;
  begin
    -- Le traitement ne se fait que si on interface les mouvements de stock en finance
    -- et l'imputation financière du mouvement de stock est à false
    if     (upper(PCS.PC_CONFIG.GetConfig('STM_FINANCIAL_CHARGING') ) = 'TRUE')
       and (nvl(ioMovementRecord.SMO_FINANCIAL_CHARGING, 1) <> 0) then
      -- controle si le produit a une gestion d'inventaire permanente en finance
      -- et rechecrhe du mode de gestion du prix
      select nvl(PDT_CONTINUOUS_INVENTAR, 0)
           , C_MANAGEMENT_MODE
        into lContinuousInventar
           , lManagementMode
        from GCO_GOOD
           , GCO_PRODUCT
       where GCO_GOOD.GCO_GOOD_ID = ioMovementRecord.GCO_GOOD_ID
         and GCO_PRODUCT.GCO_GOOD_ID(+) = GCO_GOOD.GCO_GOOD_ID;

      -- Si gestion inventaire finance permanente on traite
      if lContinuousInventar = 1 then
        -- Recherche de l'ID de transaction du modèle et de la clef de transaction
        select max(C_ACI_FINANCIAL_LINK)
             , max(CAT_KEY)
             , max(TYP_KEY)
             , max(ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID)
             , max(MOK_STANDARD_SIGN)
             , decode(max(C_MOVEMENT_SORT), 'ENT', 1, 0)
             , max(MOK_FINANCIAL_IMPUTATION)
             , max(MOK_ANAL_IMPUTATION)
             , max(C_TYPE_CATALOGUE)
             , max(MOK_ABBREVIATION || ' ' || to_char(sysdate, 'DD.MM.YYYY HH24:MI') )
             , max(C_MOVEMENT_CODE)
             , max(C_MOVEMENT_TYPE)
          into lAciFinancialLink
             , lTransactionCatKey
             , lTransactiontypKey
             , lJobTypeSCatalogueId
             , lMovementSign
             , lInputMovement
             , lFinancialImputation
             , lAnalImputation
             , lTypeCatalogue
             , lManualDocumentNumber
             , lMovementCode
             , lMovementType
          from ACJ_CATALOGUE_DOCUMENT
             , ACJ_JOB_TYPE_S_CATALOGUE
             , ACJ_JOB_TYPE
             , STM_MOVEMENT_KIND
         where ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
           and STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID = ioMovementRecord.STM_MOVEMENT_KIND_ID
           and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID = STM_MOVEMENT_KIND.ACJ_JOB_TYPE_S_CATALOGUE_ID
           and ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID;

        -- traitement seulement si il y a gestion d'imputation financière
        if    lFinancialImputation = 1
           or lAnalImputation = 1 then
          -- Flag indiquant que le mouvement génère un document comptable
          ioMovementRecord.SMO_FINANCIAL_CHARGING  := 1;

          -- recherche de la descrition courte du bien
          select max(DES_SHORT_DESCRIPTION) || ' ' || max(GOO_MAJOR_REFERENCE)
            into lImputationDescr
            from GCO_GOOD
               , GCO_DESCRIPTION
           where GCO_GOOD.GCO_GOOD_ID = ioMovementRecord.GCO_GOOD_ID
             and GCO_DESCRIPTION.GCO_GOOD_ID(+) = GCO_GOOD.GCO_GOOD_ID
             and GCO_DESCRIPTION.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetCompLangId;

          if    lMovementCode in('003', '006', '009', '016')
             or (    lMovementCode in('012', '013')
                 and lMovementType = 'TRA') then
            lDocumentNumber  := lManualDocumentNumber;
          else
            lDocumentNumber  := substr(ioMovementRecord.SMO_WORDING, 1, 30);
          end if;

          -- Construction de la description des imputations
          lImputationDescr                         := lDocumentNumber || ' ' || nvl(lImputationDescr, '');
          -- Aucune création d'écart d'achat par défaut.
          lCreateGapPurchasePrice                  := 0;
          lGapPurchasePrice                        := iGapPurchasePrice;

          -- si le mode de gestion du prix est PRF et que la config indique que le mode de reprise
          -- du prix en finance est au PRF est au PRF, on utilise le PRF comme prix unitaire pour
          -- les écritures comptables
          -- Sinon, on valorise au prix du mouvement
          if     lManagementMode = '3'
             and (PCS.PC_CONFIG.GetConfig('STM_MVT_FINANCIAL_PRICE_MODE') = '0')
             and (lMovementCode <> '014') then
            -- prend le plus grand prix s'il y a plusieurs PRF par défaut valides à la date du mouvement
            select max(CPR_PRICE) * ioMovementRecord.SMO_MOVEMENT_QUANTITY
              into ioMovementRecord.SMO_FINANCIAL_PRICE
              from PTC_FIXED_COSTPRICE
             where GCO_GOOD_ID = ioMovementRecord.GCO_GOOD_ID
               and CPR_DEFAULT = 1
               and trunc(ioMovementRecord.SMO_MOVEMENT_DATE) between nvl(trunc(FCP_START_DATE)
                                                                       , to_date('01.01.1900', 'DD.MM.YYYY')
                                                                        )
                                                                 and nvl(trunc(FCP_END_DATE)
                                                                       , to_date('31.12.2999', 'DD.MM.YYYY')
                                                                        );

            -- La création d'une imputation pour un écart d'achat doit se faire uniquement dans le cas d'une gestion
            -- du bien au prix de revient fixe et avec la configuration qui force la valorisation avec le PRF et un
            -- écart effectif (différent de 0).
            if (nvl(iGapPurchasePrice, 0) <> 0) then
              lCreateGapPurchasePrice  := 1;
            end if;
          else
            ioMovementRecord.SMO_FINANCIAL_PRICE  := ioMovementRecord.SMO_MOVEMENT_PRICE;
          end if;

          if (lCreateGapPurchasePrice = 0) then
            lGapPurchasePrice  := null;
          end if;

          -- recherche de l'id du nouveau document
          select ACI_ID_SEQ.nextval
            into lDocumentId
            from dual;

          -- mise à jour de l'entête du document d'interface
          pInterfaceHeader(lDocumentId
                         , lDocumentNumber
                         , lTransactionCatKey
                         , lTransactionTypKey
                         , lJobTypeSCatalogueId
                         , ioMovementRecord.SMO_MOVEMENT_DATE
                         , ioMovementRecord.SMO_FINANCIAL_PRICE
                         , ioMovementRecord.STM_STOCK_MOVEMENT_ID
                          );
          -- mise à jour des imputations
          pInterfaceImputations(lDocumentId
                              , lImputationDescr
                              , ioMovementRecord.SMO_MOVEMENT_DATE
                              , ioMovementRecord.SMO_FINANCIAL_PRICE * lMovementSign
                              , ioMovementRecord.ACS_DIVISION_ACCOUNT_ID
                              , ioMovementRecord.ACS_FINANCIAL_ACCOUNT_ID
                              , ioMovementRecord.ACS_ACS_DIVISION_ACCOUNT_ID
                              , ioMovementRecord.ACS_ACS_FINANCIAL_ACCOUNT_ID
                              , ioMovementRecord.ACS_CPN_ACCOUNT_ID
                              , ioMovementRecord.ACS_ACS_CPN_ACCOUNT_ID
                              , ioMovementRecord.ACS_CDA_ACCOUNT_ID
                              , ioMovementRecord.ACS_ACS_CDA_ACCOUNT_ID
                              , ioMovementRecord.ACS_PF_ACCOUNT_ID
                              , ioMovementRecord.ACS_ACS_PF_ACCOUNT_ID
                              , ioMovementRecord.ACS_PJ_ACCOUNT_ID
                              , ioMovementRecord.ACS_ACS_PJ_ACCOUNT_ID
                              , ioMovementRecord.GCO_GOOD_ID
                              , ioMovementRecord.PAC_THIRD_ID
                              , ioMovementRecord.DOC_RECORD_ID
                              , lInputMovement
                              , lFinancialImputation
                              , lAnalImputation
                              , ioMovementRecord.SMO_EXTOURNE_MVT
                              , ioAccountInfo
                              , ioAccountInfo2
                              , lGapPurchasePrice
                               );

          -- Insertion du mouvement dans la liste des mouvements imputés
          insert into STM_CHARGED_MOVEMENT
                      (STM_CHARGED_MOVEMENT_ID
                     , STM_MOVEMENT_ID
                      )
               values (ACI_ID_SEQ.nextval
                     , ioMovementRecord.STM_STOCK_MOVEMENT_ID
                      );

          -- création des status du document
          insert into ACI_DOCUMENT_STATUS
                      (ACI_DOCUMENT_STATUS_ID
                     , ACI_DOCUMENT_ID
                     , C_ACI_FINANCIAL_LINK
                      )
               values (ACI_ID_SEQ.nextval
                     , lDocumentId
                     , lAciFinancialLink
                      );
        else
          -- ce mouvement de stock ne peut pas générer d'écriture financière
          ioMovementRecord.SMO_FINANCIAL_CHARGING  := 0;
        end if;
      else
        -- pas d'inventaire permanent, pas d'écriture financière
        ioMovementRecord.SMO_FINANCIAL_CHARGING  := 0;
      end if;
    else
      -- la config n'autorise pas l'intégration en finance
      ioMovementRecord.SMO_FINANCIAL_CHARGING  := 0;
    end if;
  end createInterfaceDocument;
end ACI_PRC_STOCK_MOVEMENT;
