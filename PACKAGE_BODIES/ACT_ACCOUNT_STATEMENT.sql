--------------------------------------------------------
--  DDL for Package Body ACT_ACCOUNT_STATEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_ACCOUNT_STATEMENT" 
is
-----------------------------------------------------------------------------------------------------------------------
  /**
  *   Méthode de création de l'en-tête  de relevé
  **/
  procedure CreateStatementHeader(
    pAccountId             ACT_FIN_STATEMENT_HEADER.ACS_FINANCIAL_ACCOUNT_ID%type
  , pTransactionNumber     ACT_FIN_STATEMENT_HEADER.AFT_STATEMENT_IDENTIFIER%type
  , pAccountNumber         ACT_FIN_STATEMENT_HEADER.AFT_ACCOUNT_NUMBER%type
  , pStatementNumber       ACT_FIN_STATEMENT_HEADER.AFT_STATEMENT_NUMBER%type
  , pOpeningBalance        varchar2
  , pClosingBalance        varchar2
  , pHeaderId          out ACT_FIN_STATEMENT_HEADER.ACT_FIN_STATEMENT_HEADER_ID%type
  )
  is
    vCurrencyCode      PCS.PC_CURR.CURRENCY%type;
    vForeignCurrencyId PCS.PC_CURR.PC_CURR_ID%type;
    vIsForeignCurrency boolean;
    vAmount            ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_D%type;
    vOpeningDate       ACT_FIN_STATEMENT_HEADER.AFT_OPENING_BAL_DATE%type;
    vAmountOLCD        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_D%type;
    vAmountOLCC        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_C%type;
    vAmountOFCD        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_D%type;
    vAmountOFCC        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_C%type;
    vClosingDate       ACT_FIN_STATEMENT_HEADER.AFT_CLS_BAL_DATE%type;
    vAmountCLCD        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_D%type;
    vAmountCLCC        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_C%type;
    vAmountCFCD        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_D%type;
    vAmountCFCC        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_C%type;
  begin
    pHeaderId  := 0;

    if AlreadyAccounted(pAccountId, pTransactionNumber) = 0 then
      /** Initalisation des variables montants **/
      vAmountOLCD         := 0.0;
      vAmountOLCC         := 0.0;
      vAmountOFCD         := 0.0;
      vAmountOFCC         := 0.0;
      vAmountCLCD         := 0.0;
      vAmountCLCC         := 0.0;
      vAmountCFCD         := 0.0;
      vAmountCFCC         := 0.0;
      /** Réception et formatage de la date  d'ouverture **/
      vOpeningDate        := to_date(substr(pOpeningBalance, 2, 6), 'YYMMDD');
      /** Réceptiondu code de la monnaie **/
      vCurrencyCode       := substr(pOpeningBalance, 8, 3);
      /** Détermine si monnaie de base  ou étrangère **/
      vForeignCurrencyId  := GetCurrencyIdByCode(vCurrencyCode);
      vIsForeignCurrency  := LocalCurrencyId <> vForeignCurrencyId;
      /** Réceptiondu et formatage montant **/
      vAmount             := replace(substr(pOpeningBalance, 11, 15), ',', '.');

      /** Détermination du type de montant **/
      if substr(pOpeningBalance, 1, 1) = 'D' then
        if vIsForeignCurrency then
          vAmountOFCD  := vAmount;
        else
          vAmountOLCD  := vAmount;
        end if;
      else
        if vIsForeignCurrency then
          vAmountOFCC  := vAmount;
        else
          vAmountOLCC  := vAmount;
        end if;
      end if;

      /** Réception et formatage de la date  d'ouverture **/
      vClosingDate        := to_date(substr(pClosingBalance, 2, 6), 'YYMMDD');
      /** Réceptiondu et formatage montant de bouclement **/
      vAmount             := replace(substr(pClosingBalance, 11, 15), ',', '.');

      /** Détermination du type de montant de bouclement**/
      if substr(pClosingBalance, 1, 1) = 'D' then
        if vIsForeignCurrency then
          vAmountCFCD  := vAmount;
        else
          vAmountCLCD  := vAmount;
        end if;
      else
        if vIsForeignCurrency then
          vAmountCFCC  := vAmount;
        else
          vAmountCLCC  := vAmount;
        end if;
      end if;

      pHeaderId           :=
        InsertStatementHeader(pAccountId   -- ACS_FINANCIAL_ACCOUNT_ID
                            , vForeignCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                            , LocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                            , pTransactionNumber   -- AFT_STATEMENT_IDENTIFIER
                            , pAccountNumber   -- AFT_ACCOUNT_NUMBER
                            , pStatementNumber   -- AFT_STATEMENT_NUMBER
                            , vOpeningDate   -- AFT_OPENING_BAL_DATE
                            , vClosingDate   -- AFT_CLS_BAL_DATE
                            , ''   -- AFT_ADD_HEADER_DESCR
                            , vAmountOLCD   -- AFT_OPN_AMOUNT_LC_D
                            , vAmountOLCC   -- AFT_OPN_AMOUNT_LC_C
                            , vAmountOFCD   -- AFT_OPN_AMOUNT_FC_D
                            , vAmountOFCC   -- AFT_OPN_AMOUNT_FC_C
                            , vAmountCLCD   -- AFT_CLS_AMOUNT_LC_D
                            , vAmountCLCC   -- AFT_CLS_AMOUNT_LC_C
                            , vAmountCFCD   -- AFT_CLS_AMOUNT_FC_D
                            , vAmountCFCC   -- AFT_CLS_AMOUNT_FC_C
                             );
    end if;
  end CreateStatementHeader;

-----------------------------------------------------------------------------------------------------------------------
  /**
  *   Méthode de création des mouvements de relevé
  **/
  procedure CreateStatementMvts(
    pHeaderId    ACT_FIN_STATEMENT_HEADER.ACT_FIN_STATEMENT_HEADER_ID%type
  , pTransaction varchar2
  , pDetails     varchar2
  )
  is
    vCodePosition      integer;
    vOptionalPos       integer;
    vMvtType           varchar2(1);
    vIsForeignCurrency boolean;
    vForeignCurrencyId PCS.PC_CURR.PC_CURR_ID%type;
    vAccountId         ACT_FIN_STATEMENT_HEADER.ACS_FINANCIAL_ACCOUNT_ID%type;
    vValueDate         ACT_FIN_STAT_MOVEMENT.AFM_VALUE_DATE%type;
    vBookingDate       ACT_FIN_STAT_MOVEMENT.AFM_TRANSACTION_DATE%type;
    vAmount            ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_LC_D%type;
    vAmountLCD         ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_LC_D%type;
    vAmountLCC         ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_LC_C%type;
    vAmountFCD         ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_FC_D%type;
    vAmountFCC         ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_FC_C%type;
    vTransactionCode   ACT_FIN_STAT_MOVEMENT.AFM_TRANSACTION_CODE%type;
    vReference         ACT_FIN_STAT_MOVEMENT.AFM_REFERENCE%type;
    vBankReference     ACT_FIN_STAT_MOVEMENT.AFM_BANK_REFERENCE%type;
    vComplDescr        ACT_FIN_STAT_MOVEMENT.AFM_FURTHER_TRANS_DESCR%type;
    vPeriodId          ACT_FIN_STAT_MOVEMENT.ACS_PERIOD_ID%type;
    vFinYearId         ACT_FIN_STAT_MOVEMENT.ACS_FINANCIAL_YEAR_ID%type;
    vMovementId        ACT_FIN_STAT_MOVEMENT.ACT_FIN_STAT_MOVEMENT_ID%type;
  begin
    /** Initalisation des variables montants **/
    vOptionalPos        := 0;
    vAmountLCD          := 0.0;
    vAmountLCC          := 0.0;
    vAmountFCD          := 0.0;
    vAmountFCC          := 0.0;

    /** Réception de la monnaie et comptre de l'en-tête **/
    select ACS_FINANCIAL_CURRENCY_ID
         , ACS_FINANCIAL_ACCOUNT_ID
      into vForeignCurrencyId
         , vAccountId
      from ACT_FIN_STATEMENT_HEADER
     where ACT_FIN_STATEMENT_HEADER_ID = pHeaderId;

    /** Monnaie étrangère **/
    vIsForeignCurrency  := vForeignCurrencyId <> LocalCurrencyId;
    /** Réception et formatage de la date valeur **/
    vValueDate          := to_date(substr(pTransaction, 1, 6), 'YYMMDD');

    /** La date transaction est optionnelle **/
    if    (substr(pTransaction, 7, 1) between 'a' and 'z')
       or (substr(pTransaction, 7, 1) between 'A' and 'Z') then
      vBookingDate  := vValueDate;
    else
      /** Réception et formatage de la date transaction **/
      vBookingDate  := to_date(substr(pTransaction, 1, 2) || substr(pTransaction, 7, 4), 'YYMMDD');
      vOptionalPos  := 4;
    end if;

    /** Réception type de mouvement **/
    if substr(pTransaction, 7 + vOptionalPos, 1) in('c', 'C', 'd', 'D') then
      vMvtType      := substr(pTransaction, 7 + vOptionalPos, 1);
      vOptionalPos  := vOptionalPos + 1;
    elsif substr(pTransaction, 8 + vOptionalPos, 1) in('c', 'C', 'd', 'D') then
      vMvtType  := substr(pTransaction, 8 + vOptionalPos, 1);
    end if;

    /** Le code monnaie est optionnelle **/
    if    (substr(pTransaction, 7 + vOptionalPos, 1) between 'a' and 'z')
       or (substr(pTransaction, 7 + vOptionalPos, 1) between 'A' and 'Z') then
      vOptionalPos  := vOptionalPos + 1;
    end if;

    /** Réception et formatage montant **/
    vCodePosition       := 0;

    while not(    (substr(pTransaction, 7 + vOptionalPos + vCodePosition, 1) between 'a' and 'z')
              or (substr(pTransaction, 7 + vOptionalPos + vCodePosition, 1) between 'A' and 'Z')
             ) loop
      vCodePosition  := vCodePosition + 1;
    end loop;

    vAmount             := replace(substr(pTransaction, 7 + vOptionalPos, vCodePosition), ',', '.');

    /** Détermination du type de montant **/
    if vMvtType = 'D' then
      if vIsForeignCurrency then
        vAmountFCD  := vAmount;
      else
        vAmountLCD  := vAmount;
      end if;
    else
      if vIsForeignCurrency then
        vAmountFCC  := vAmount;
      else
        vAmountLCC  := vAmount;
      end if;
    end if;

    vTransactionCode    := substr(pTransaction, 7 + vOptionalPos + vCodePosition, 4);
    vCodePosition       := 7 + vOptionalPos + vCodePosition + 4;

    /** Détermination période et exercice selon date de transaction **/
    select ACS_PERIOD_ID
         , ACS_FINANCIAL_YEAR_ID
      into vPeriodId
         , vFinYearId
      from ACS_PERIOD
     where vBookingDate between PER_START_DATE and PER_END_DATE;

    /** Réception des champs référence et description **/
    select substr(pTransaction, vCodePosition, instr(pTransaction, '//') - vCodePosition)
         , substr(pTransaction
                , instr(pTransaction, '//') + 2
                , instr(pTransaction, 'CHR(13)') - instr(pTransaction, '//') - 2
                 )
         , replace(substr(pTransaction, instr(pTransaction, 'CHR(13)CHR(10)') + 14), 'CHR(13)CHR(10)', '')
      into vReference
         , vBankReference
         , vComplDescr
      from dual;

    vMovementId         :=
      InsertStatementMvts(pHeaderId   -- ACT_FIN_STATEMENT_HEADER_ID,
                        , vAccountId   -- ACS_FINANCIAL_ACCOUNT_ID
                        , vForeignCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                        , LocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                        , vPeriodId   -- ACS_PERIOD_ID
                        , vFinYearId   -- ACS_FINANCIAL_YEAR_ID
                        , vValueDate   -- AFM_VALUE_DATE
                        , vBookingDate   -- AFM_TRANSACTION_DATE
                        , vAmountLCD   -- AFM_AMOUNT_LC_D
                        , vAmountLCC   -- AFM_AMOUNT_LC_C
                        , vAmountFCD   -- AFM_AMOUNT_FC_D
                        , vAmountFCC   -- AFM_AMOUNT_FC_C
                        , vTransactionCode   -- AFM_TRANSACTION_CODE
                        , vReference   -- AFM_REFERENCE
                        , vBankReference   -- AFM_BANK_REFERENCE
                        , replace(pDetails, 'CHR(13)CHR(10)', '')   -- AFM_TRANS_DESCR
                        , vComplDescr   -- AFM_FURTHER_TRANS_DESCR
                         );
  end CreateStatementMvts;

-----------------------------------------------------------------------------------------------------------------------
  /**
  *   Méthode de création des mouvements de relevé
  **/
  procedure CreateStatementMvts_CFONB120(
    pHeaderId      ACT_FIN_STATEMENT_HEADER.ACT_FIN_STATEMENT_HEADER_ID%type
  , pMvtLine       varchar2
  , pMainMvtId     ACT_FIN_STAT_MOVEMENT.ACT_FIN_STAT_MOVEMENT_ID%type
  , pMvtId     out ACT_FIN_STAT_MOVEMENT.ACT_FIN_STAT_MOVEMENT_ID%type
  )
  is
    vIsForeignCurrency boolean;
    vForeignCurrencyId PCS.PC_CURR.PC_CURR_ID%type;
    vAccountId         ACT_FIN_STATEMENT_HEADER.ACS_FINANCIAL_ACCOUNT_ID%type;
    vValueDate         ACT_FIN_STAT_MOVEMENT.AFM_VALUE_DATE%type;
    vBookingDate       ACT_FIN_STAT_MOVEMENT.AFM_TRANSACTION_DATE%type;
    vAmount            ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_LC_D%type;
    vDecNumber         number(1);
    vAmountLCD         ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_LC_D%type;
    vAmountLCC         ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_LC_C%type;
    vAmountFCD         ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_FC_D%type;
    vAmountFCC         ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_FC_C%type;
    vTransactionCode   ACT_FIN_STAT_MOVEMENT.AFM_TRANSACTION_CODE%type;
    vReference         ACT_FIN_STAT_MOVEMENT.AFM_REFERENCE%type;
    vBankReference     ACT_FIN_STAT_MOVEMENT.AFM_BANK_REFERENCE%type;
    vTransDescr        ACT_FIN_STAT_MOVEMENT.AFM_TRANS_DESCR%type;
    vComplDescr        ACT_FIN_STAT_MOVEMENT.AFM_FURTHER_TRANS_DESCR%type;
    vPeriodId          ACT_FIN_STAT_MOVEMENT.ACS_PERIOD_ID%type;
    vFinYearId         ACT_FIN_STAT_MOVEMENT.ACS_FINANCIAL_YEAR_ID%type;
    vLastValueChar     varchar2(1);
    vLastValue         number(1);
    vSign              number(1);

    procedure GetAmountLastNumber(aAmountChar in varchar2, aLastValue out number, aSign out number)
    is
      vCString       varchar2(10) default('{ABCDEFGHI');
      vDString       varchar2(10) default('}JKLMNOPQR');
      vPosAmountChar number(1);
    begin
      aSign           := 1;
      vPosAmountChar  := instr(vCString, aAmountChar) - 1;

      if vPosAmountChar = -1 then
        vPosAmountChar  := instr(vdString, aAmountChar) - 1;
        aSign           := -1;

        if vPosAmountChar = -1 then
          vPosAmountChar  := 0;
          aSign           := 1;
        end if;
      end if;

      aLastValue      := vPosAmountChar;
    end GetAmountLastNumber;
  begin
    if pMainMvtId = 0 then
      /** Initalisation des variables montants **/
      vAmountLCD          := 0.0;
      vAmountLCC          := 0.0;
      vAmountFCD          := 0.0;
      vAmountFCC          := 0.0;

      /** Réception de la monnaie et compte de l'en-tête **/
      select ACS_FINANCIAL_CURRENCY_ID
           , ACS_FINANCIAL_ACCOUNT_ID
        into vForeignCurrencyId
           , vAccountId
        from ACT_FIN_STATEMENT_HEADER
       where ACT_FIN_STATEMENT_HEADER_ID = pHeaderId;

      /** Monnaie étrangère **/
      vIsForeignCurrency  := vForeignCurrencyId <> LocalCurrencyId;
      /** Réception et formatage de la date valeur **/
      vValueDate          := to_date(substr(pMvtLine, 41, 6), 'DDMMYY');
      /** Réception et formatage date transaction **/
      vBookingDate        := to_date(substr(pMvtLine, 33, 6), 'DDMMYY');
      vDecNumber          := substr(pMvtLine, 18, 1);
      /** Réception montant du mvt **/
      vLastValueChar      := substr(pMvtLine, 102, 1);
      GetAmountLastNumber(vLastValueChar, vLastValue, vSign);
      vAmount             := replace(substr(pMvtLine, 89, 14), vLastValueChar, vLastValue);
      vAmount             := vAmount /(10 ** vDecNumber);

      /** Détermination du type de montant **/
      if (vSign > 0) then   --Montant créditeur
        if vIsForeignCurrency then
          vAmountFCC  := vAmount;
        else
          vAmountLCC  := vAmount;
        end if;
      else
        if vIsForeignCurrency then
          vAmountFCD  := vAmount;
        else
          vAmountLCD  := vAmount;
        end if;
      end if;

      vTransactionCode    := substr(pMvtLine, 31, 2) || substr(pMvtLine, 39, 2);

      /** Détermination période et exercice selon date de transaction **/
      select ACS_PERIOD_ID
           , ACS_FINANCIAL_YEAR_ID
        into vPeriodId
           , vFinYearId
        from ACS_PERIOD
       where vBookingDate between PER_START_DATE and PER_END_DATE
         and C_TYPE_PERIOD = '2';

      /** Réception des champs référence et description **/
      select substr(pMvtLine, 80, 7)
           , substr(pMvtLine, 6, 4)
           , replace(replace(substr(pMvtLine, 47, 31), chr(13), ''), chr(10), '')
        into vReference
           , vBankReference
           , vTransDescr
        from dual;

      pMvtId              :=
        InsertStatementMvts(pHeaderId   -- ACT_FIN_STATEMENT_HEADER_ID,
                          , vAccountId   -- ACS_FINANCIAL_ACCOUNT_ID
                          , vForeignCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                          , LocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                          , vPeriodId   -- ACS_PERIOD_ID
                          , vFinYearId   -- ACS_FINANCIAL_YEAR_ID
                          , vValueDate   -- AFM_VALUE_DATE
                          , vBookingDate   -- AFM_TRANSACTION_DATE
                          , vAmountLCD   -- AFM_AMOUNT_LC_D
                          , vAmountLCC   -- AFM_AMOUNT_LC_C
                          , vAmountFCD   -- AFM_AMOUNT_FC_D
                          , vAmountFCC   -- AFM_AMOUNT_FC_C
                          , vTransactionCode   -- AFM_TRANSACTION_CODE
                          , vReference   -- AFM_REFERENCE
                          , vBankReference   -- AFM_BANK_REFERENCE
                          , vTransDescr   -- AFM_TRANS_DESCR
                          , vComplDescr   -- AFM_FURTHER_TRANS_DESCR
                           );
    else
      pMvtId  := pMainMvtId;

      select max(AFM_FURTHER_TRANS_DESCR)
        into vComplDescr
        from ACT_FIN_STAT_MOVEMENT
       where ACT_FIN_STAT_MOVEMENT_ID = pMainMvtId;

      if vComplDescr is null then
        vComplDescr  := substr(pMvtLine, 44, 73);
      else
        vComplDescr  := substr(vComplDescr || ' / ' || substr(pMvtLine, 44, 73), 1, 400);
      end if;

      update ACT_FIN_STAT_MOVEMENT
         set AFM_FURTHER_TRANS_DESCR = vComplDescr
       where ACT_FIN_STAT_MOVEMENT_ID = pMainMvtId;
    end if;
  end CreateStatementMvts_CFONB120;

-----------------------------------------------------------------------------------------------------------------------
  /**
  *   Méthode d'ajout d'en-tête de relevé avec tous les champs de la table passé en paramètres
  **/
  function InsertStatementHeader(
    pFinancialAccountId ACT_FIN_STATEMENT_HEADER.ACS_FINANCIAL_ACCOUNT_ID%type
  , pForeignCurrencyId  ACT_FIN_STATEMENT_HEADER.ACS_FINANCIAL_CURRENCY_ID%type
  , pLocalCurrencyId    ACT_FIN_STATEMENT_HEADER.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , pStamentIdentifier  ACT_FIN_STATEMENT_HEADER.AFT_STATEMENT_IDENTIFIER%type
  , pAccountNumber      ACT_FIN_STATEMENT_HEADER.AFT_ACCOUNT_NUMBER%type
  , pStatementNumber    ACT_FIN_STATEMENT_HEADER.AFT_STATEMENT_NUMBER%type
  , pOpeningDate        ACT_FIN_STATEMENT_HEADER.AFT_OPENING_BAL_DATE%type
  , pClosingDate        ACT_FIN_STATEMENT_HEADER.AFT_CLS_BAL_DATE%type
  , pHeaderDescription  ACT_FIN_STATEMENT_HEADER.AFT_ADD_HEADER_DESCR%type
  , pOpeningAmountLCD   ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_D%type
  , pOpeningAmountLCC   ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_C%type
  , pOpeningAmountFCD   ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_D%type
  , pOpeningAmountFCC   ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_C%type
  , pClosingAmountLCD   ACT_FIN_STATEMENT_HEADER.AFT_CLS_AMOUNT_LC_D%type
  , pClosingAmountLCC   ACT_FIN_STATEMENT_HEADER.AFT_CLS_AMOUNT_LC_C%type
  , pClosingAmountFCD   ACT_FIN_STATEMENT_HEADER.AFT_CLS_AMOUNT_FC_D%type
  , pClosingAmountFCC   ACT_FIN_STATEMENT_HEADER.AFT_CLS_AMOUNT_FC_C%type
  )
    return ACT_FIN_STATEMENT_HEADER.ACT_FIN_STATEMENT_HEADER_id%type
  is
    vHeaderId ACT_FIN_STATEMENT_HEADER.ACT_FIN_STATEMENT_HEADER_id%type;
  begin
    select init_id_seq.nextval
      into vHeaderId
      from dual;

    begin
      insert into ACT_FIN_STATEMENT_HEADER
                  (ACT_FIN_STATEMENT_HEADER_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , AFT_STATEMENT_IDENTIFIER
                 , AFT_ACCOUNT_NUMBER
                 , AFT_STATEMENT_NUMBER
                 , AFT_OPENING_BAL_DATE
                 , AFT_CLS_BAL_DATE
                 , AFT_ADD_HEADER_DESCR
                 , AFT_OPN_AMOUNT_LC_D
                 , AFT_OPN_AMOUNT_LC_C
                 , AFT_OPN_AMOUNT_FC_D
                 , AFT_OPN_AMOUNT_FC_C
                 , AFT_CLS_AMOUNT_LC_D
                 , AFT_CLS_AMOUNT_LC_C
                 , AFT_CLS_AMOUNT_FC_D
                 , AFT_CLS_AMOUNT_FC_C
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vHeaderId
                 , pFinancialAccountId
                 , pForeignCurrencyId
                 , pLocalCurrencyId
                 , pStamentIdentifier
                 , pAccountNumber
                 , decode(pStatementNumber, null, '0', pStatementNumber)
                 , pOpeningDate
                 , pClosingDate
                 , pHeaderDescription
                 , pOpeningAmountLCD
                 , pOpeningAmountLCC
                 , pOpeningAmountFCD
                 , pOpeningAmountFCC
                 , pClosingAmountLCD
                 , pClosingAmountLCC
                 , pClosingAmountFCD
                 , pClosingAmountFCC
                 , sysdate
                 , UserIni
                  );
    exception
      when others then
        vHeaderId  := null;
        raise;
    end;

    return vHeaderId;
  end InsertStatementHeader;

-----------------------------------------------------------------------------------------------------------------------
  /**
  *   Méthode d'ajout des mouvements de relevé
  **/
  function InsertStatementMvts(
    pHeaderId           ACT_FIN_STAT_MOVEMENT.ACT_FIN_STATEMENT_HEADER_ID%type
  , pFinancialAccountId ACT_FIN_STAT_MOVEMENT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pForeignCurrencyId  ACT_FIN_STAT_MOVEMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , pLocalCurrencyId    ACT_FIN_STAT_MOVEMENT.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , pPeriodId           ACT_FIN_STAT_MOVEMENT.ACS_PERIOD_ID%type
  , pFinancialYearId    ACT_FIN_STAT_MOVEMENT.ACS_FINANCIAL_YEAR_ID%type
  , pValueDate          ACT_FIN_STAT_MOVEMENT.AFM_VALUE_DATE%type
  , pTransactionDate    ACT_FIN_STAT_MOVEMENT.AFM_TRANSACTION_DATE%type
  , pAmountLCD          ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_LC_D%type
  , pAmountLCC          ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_LC_C%type
  , pAmountFCD          ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_FC_D%type
  , pAmountFCC          ACT_FIN_STAT_MOVEMENT.AFM_AMOUNT_FC_C%type
  , pTransactionCode    ACT_FIN_STAT_MOVEMENT.AFM_TRANSACTION_CODE%type
  , pReference          ACT_FIN_STAT_MOVEMENT.AFM_REFERENCE%type
  , pBankReference      ACT_FIN_STAT_MOVEMENT.AFM_BANK_REFERENCE%type
  , pDescription        ACT_FIN_STAT_MOVEMENT.AFM_TRANS_DESCR%type
  , pComplDescr         ACT_FIN_STAT_MOVEMENT.AFM_FURTHER_TRANS_DESCR%type
  )
    return ACT_FIN_STAT_MOVEMENT.ACT_FIN_STAT_MOVEMENT_ID%type
  is
    vMovementId ACT_FIN_STAT_MOVEMENT.ACT_FIN_STAT_MOVEMENT_ID%type;
  begin
    select init_id_seq.nextval
      into vMovementId
      from dual;

    insert into ACT_FIN_STAT_MOVEMENT
                (ACT_FIN_STAT_MOVEMENT_ID
               , ACT_FIN_STATEMENT_HEADER_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , ACS_PERIOD_ID
               , ACS_FINANCIAL_YEAR_ID
               , AFM_VALUE_DATE
               , AFM_TRANSACTION_DATE
               , AFM_AMOUNT_LC_D
               , AFM_AMOUNT_LC_C
               , AFM_AMOUNT_FC_D
               , AFM_AMOUNT_FC_C
               , AFM_TRANSACTION_CODE
               , AFM_REFERENCE
               , AFM_BANK_REFERENCE
               , AFM_TRANS_DESCR
               , AFM_FURTHER_TRANS_DESCR
               , A_DATECRE
               , A_IDCRE
                )
         values (vMovementId
               , pHeaderId
               , pFinancialAccountId
               , pForeignCurrencyId
               , pLocalCurrencyId
               , pPeriodId
               , pFinancialYearId
               , pValueDate
               , pTransactionDate
               , pAmountLCD
               , pAmountLCC
               , pAmountFCD
               , pAmountFCC
               , pTransactionCode
               , pReference
               , pBankReference
               , pDescription
               , pComplDescr
               , sysdate
               , UserIni
                );

    return vMovementId;
  end InsertStatementMvts;

-----------------------------------------------------------------------------------------------------------------------
  /**
  *   Méthode de recherche id monnaie par le code monnaie
  **/
  function GetCurrencyIdByCode(pCurrencyCode PCS.PC_CURR.CURRENCY%type)
    return PCS.PC_CURR.PC_CURR_ID%type
  is
    vCurrencyId PCS.PC_CURR.PC_CURR_ID%type;
  begin
    begin
      select FIN.ACS_FINANCIAL_CURRENCY_ID
        into vCurrencyId
        from ACS_FINANCIAL_CURRENCY FIN
           , PCS.PC_CURR CUR
       where CUR.CURRENCY = pCurrencyCode
         and FIN.PC_CURR_ID = CUR.PC_CURR_ID;
    exception
      when no_data_found then
        vCurrencyId  := 0;
    end;

    return vCurrencyId;
  end GetCurrencyIdByCode;

-----------------------------------------------------------------------------------------------------------------------
  /**
  *   Vérifie si la clé donnée existe déjà dans la base...
  **/
  function AlreadyAccounted(
    pFinancialAccountId  ACT_FIN_STATEMENT_HEADER.ACS_FINANCIAL_ACCOUNT_ID%type
  , pStatementIdentifier ACT_FIN_STATEMENT_HEADER.AFT_STATEMENT_IDENTIFIER%type
  )
    return number
  is
    vResult number(1);
  begin
    select decode(max(ACT_FIN_STATEMENT_HEADER_ID), null, 0, 1)
      into vResult
      from ACT_FIN_STATEMENT_HEADER
     where ACS_FINANCIAL_ACCOUNT_ID = pFinancialAccountId
       and AFT_STATEMENT_IDENTIFIER = pStatementIdentifier;

    return vResult;
  end AlreadyAccounted;

-----------------------------------------------------------------------------------------------------------------------
  /**
  *   Méthode de création de l'en-tête de relevé
  **/
  procedure CreateStatementHeader_CFONB120(
    pAccountId      ACT_FIN_STATEMENT_HEADER.ACS_FINANCIAL_ACCOUNT_ID%type
  , pHeaderLine     ACT_FIN_STATEMENT_HEADER.AFT_ADD_HEADER_DESCR%type
  , pFooterLine     ACT_FIN_STATEMENT_HEADER.AFT_ADD_HEADER_DESCR%type
  , pHeaderId   out ACT_FIN_STATEMENT_HEADER.ACT_FIN_STATEMENT_HEADER_ID%type
  )
  is
    vCurrencyCode      PCS.PC_CURR.CURRENCY%type;
    vForeignCurrencyId PCS.PC_CURR.PC_CURR_ID%type;
    vIsForeignCurrency boolean;
    vAmount            ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_D%type;
    vDecNumber         number(1);
    vAccountNumber     ACT_FIN_STATEMENT_HEADER.AFT_ACCOUNT_NUMBER%type;
    vOpeningDate       ACT_FIN_STATEMENT_HEADER.AFT_OPENING_BAL_DATE%type;
    vAmountOLCD        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_D%type;
    vAmountOLCC        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_C%type;
    vAmountOFCD        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_D%type;
    vAmountOFCC        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_C%type;
    vClosingDate       ACT_FIN_STATEMENT_HEADER.AFT_CLS_BAL_DATE%type;
    vAmountCLCD        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_D%type;
    vAmountCLCC        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_LC_C%type;
    vAmountCFCD        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_D%type;
    vAmountCFCC        ACT_FIN_STATEMENT_HEADER.AFT_OPN_AMOUNT_FC_C%type;
  begin
    pHeaderId  := 0;

    if AlreadyAccounted(pAccountId, to_date(substr(pFooterLine, 33, 6), 'DDMMYY') ) = 0 then
      /** Initalisation des variables montants **/
      vAmountOLCD         := 0.0;
      vAmountOLCC         := 0.0;
      vAmountOFCD         := 0.0;
      vAmountOFCC         := 0.0;
      vAmountCLCD         := 0.0;
      vAmountCLCC         := 0.0;
      vAmountCFCD         := 0.0;
      vAmountCFCC         := 0.0;
      /** Les chaînes de caractères reçues en paramètre n'incluent pas le "type" de la ligne...
      ...aussi un décalage de -2 position est nécessaire pour récupérer les zones nécessaires
      **/

      /** Réception et formatage de la date  d'ouverture **/
      vOpeningDate        := to_date(substr(pHeaderLine, 33, 6), 'DDMMYY');
      /** Réception et formatage de la date  de cloture **/
      vClosingDate        := to_date(substr(pFooterLine, 33, 6), 'DDMMYY');
      /** Réceptiondu code de la monnaie **/
      vCurrencyCode       := substr(pFooterLine, 15, 3);
      /** Détermine si monnaie de base  ou étrangère **/
      vForeignCurrencyId  := GetCurrencyIdByCode(vCurrencyCode);
      vIsForeignCurrency  := LocalCurrencyId <> vForeignCurrencyId;
      /** Réception du numéro de compte **/
      vAccountNumber      := substr(pFooterLine, 20, 11);
      vDecNumber          := substr(pHeaderLine, 18, 1);
      /** Réception montant ancien solde **/
      vAmount             := substr(pHeaderLine, 89, 13) /(10 ** vDecNumber);

      /** Détermination du type de montant **/
      if substr(pHeaderLine, 102, 1) in('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', '{') then   --Montant créditeur
        if vIsForeignCurrency then
          vAmountOFCC  := vAmount;
        else
          vAmountOLCC  := vAmount;
        end if;
      elsif substr(pHeaderLine, 102, 1) in('J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', '}') then   --Montant débiteur
        if vIsForeignCurrency then
          vAmountOFCD  := vAmount;
        else
          vAmountOLCD  := vAmount;
        end if;
      end if;

      vDecNumber          := substr(pFooterLine, 18, 1);
      /** Réception montant ancien solde **/
      vAmount             := substr(pFooterLine, 89, 13) /(10 ** vDecNumber);

      /** Détermination du type de montant **/
      if substr(pFooterLine, 102, 1) in('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', '{') then   --Montant créditeur
        if vIsForeignCurrency then
          vAmountCFCC  := vAmount;
        else
          vAmountCLCC  := vAmount;
        end if;
      elsif substr(pFooterLine, 102, 1) in('J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', '}') then   --Montant débiteur
        if vIsForeignCurrency then
          vAmountCFCD  := vAmount;
        else
          vAmountCLCD  := vAmount;
        end if;
      end if;

      pHeaderId           :=
        InsertStatementHeader(pAccountId   -- ACS_FINANCIAL_ACCOUNT_ID
                            , vForeignCurrencyId   -- ACS_FINANCIAL_CURRENCY_ID
                            , LocalCurrencyId   -- ACS_ACS_FINANCIAL_CURRENCY_ID
                            , vClosingDate   -- AFT_STATEMENT_IDENTIFIER
                            , vAccountNumber   -- AFT_ACCOUNT_NUMBER
                            , vClosingDate   -- AFT_STATEMENT_NUMBER
                            , vOpeningDate   -- AFT_OPENING_BAL_DATE
                            , vClosingDate   -- AFT_CLS_BAL_DATE
                            , null   -- AFT_ADD_HEADER_DESCR
                            , vAmountOLCD   -- AFT_OPN_AMOUNT_LC_D
                            , vAmountOLCC   -- AFT_OPN_AMOUNT_LC_C
                            , vAmountOFCD   -- AFT_OPN_AMOUNT_FC_D
                            , vAmountOFCC   -- AFT_OPN_AMOUNT_FC_C
                            , vAmountCLCD   -- AFT_CLS_AMOUNT_LC_D
                            , vAmountCLCC   -- AFT_CLS_AMOUNT_LC_C
                            , vAmountCFCD   -- AFT_CLS_AMOUNT_FC_D
                            , vAmountCFCC   -- AFT_CLS_AMOUNT_FC_C
                             );
    end if;
  end CreateStatementHeader_CFONB120;
-----------------------------------------------------------------------------------------------------------------------
begin
  UserIni          := PCS.PC_I_LIB_SESSION.GetUserIni;
  LocalCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
end ACT_ACCOUNT_STATEMENT;
