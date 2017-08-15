--------------------------------------------------------
--  DDL for Package Body PAC_PARTNER_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_PARTNER_MANAGEMENT" 
is
  /**
  * Description
  *    Procédure de modification des descriptifs du compte auxiliaire en cas de modification
  *    des infos de base PAC_PERSON, PAC_ADDRESS
  */
  procedure UPDATE_ACCOUNT_DESCR(
    aPAC_PERSON_ID PAC_PERSON.PAC_PERSON_ID%type
  , aPER_NAME      PAC_PERSON.PER_NAME%type
  , aPER_FORENAME  PAC_PERSON.PER_FORENAME%type
  )
  is
  begin
    ACS_FUNCTION.UpdatePersonAccountDescr(aPAC_PERSON_ID, aPER_NAME, aPER_FORENAME);
  end UPDATE_ACCOUNT_DESCR;

  /**
  * Description
  *    Retourne l'ID du compte auxiliaire client ou fournisseur
  */
  function GET_AUXILIARY_ACCOUNT_ID(aPAC_PERSON_ID number, aCUSTOM number)
    return number
  is
    AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
  begin
    return ACS_FUNCTION.GetAuxiliaryAccountId(aPAC_PERSON_ID, aCUSTOM);
  end GET_AUXILIARY_ACCOUNT_ID;

  function ExistsCustomerAuxiliaryAccount(pPacCustomPartnerId PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
    return number
  is
    vResult ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
  begin
    select decode(nvl(max(ACS_AUXILIARY_ACCOUNT_ID), 0), 0, 0, 1)
      into vResult
      from PAC_CUSTOM_PARTNER
     where PAC_CUSTOM_PARTNER_ID = pPacCustomPartnerId;

    return vResult;
  end ExistsCustomerAuxiliaryAccount;

  function ExistsSupplierAuxiliaryAccount(pPacSupplierPartnerId PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type)
    return number
  is
    vResult ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
  begin
    select decode(nvl(max(ACS_AUXILIARY_ACCOUNT_ID), 0), 0, 0, 1)
      into vResult
      from PAC_SUPPLIER_PARTNER
     where PAC_SUPPLIER_PARTNER_ID = pPacSupplierPartnerId;

    return vResult;
  end ExistsSupplierAuxiliaryAccount;

  /**
  * Description
  *    Retourne le type d'adresse par défaut
  */
  function GET_ADDRESS_TYPE
    return varchar2
  is
  begin
    return PAC_FUNCTIONS.GET_ADDRESS_TYPE;
  end GET_ADDRESS_TYPE;

  /**
  * Description
  *    Ramène code postal et ville de l'adresse par défaut
  */
  procedure GET_ADDRESS_DATA(aPAC_PERSON_ID in number, aADD_ZIPCODE out varchar2, aADD_CITY out varchar2)
  is
    DEFAULT_ADDRESS_TYPE DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID%type;
    ZIPCODE              PAC_ADDRESS.ADD_ZIPCODE%type;
    CITY                 PAC_ADDRESS.ADD_CITY%type;
  begin
    DEFAULT_ADDRESS_TYPE  := GET_ADDRESS_TYPE;

    select nvl(max(ADD_ZIPCODE), '')
         , nvl(max(ADD_CITY), '')
      into ZIPCODE
         , CITY
      from PAC_ADDRESS
     where PAC_PERSON_ID = aPAC_PERSON_ID
       and DIC_ADDRESS_TYPE_ID = DEFAULT_ADDRESS_TYPE;

    aADD_ZIPCODE          := ZIPCODE;
    aADD_CITY             := CITY;
  end GET_ADDRESS_DATA;

  /**
  * Description
  *    Ramène Nom, Prénom, Localité de l'adresse par défaut
  */
  function GetNamesAndCity(aPAC_PERSON_ID PAC_PERSON.PAC_PERSON_ID%type)
    return varchar2
  is
  begin
    return PAC_FUNCTIONS.GetNamesAndCity(aPAC_PERSON_ID);
  end GetNamesAndCity;

  /**
  * Description
  *    Retour de l'adresse formatée selon macro défini pour le code pays de l'adresse
  *    et le pays d'exploitation
  */
  function FormatingAddress(
    pAddZipCode   PAC_ADDRESS.ADD_ZIPCODE%type
  , pAddCity      PAC_ADDRESS.ADD_CITY%type
  , pAddState     PAC_ADDRESS.ADD_STATE%type
  , pAddCounty    PAC_ADDRESS.ADD_COUNTY%type
  , pAddCountryId PAC_ADDRESS.PC_CNTRY_ID%type
  )
    return PAC_ADDRESS.ADD_FORMAT%type
  is
    /*Curseur de recherche des formats d'addresses*/
    /*0° Le format valide pour le pays référence(pAddCountry) et le pays d'exploitation (COMP_CNTRY_ID) */
    /*1° Le format par défaut pour le pays référence*/
    cursor AddressFormatCursor
    is
      select   '0' SORTFIELD
             , ADP.ADPMACRO
             , CNT.CNTNAME
             , CNT.CNTID
          from PCS.PC_ADPRT ADP
             , PCS.PC_CNTRY CNT
         where CNT.PC_CNTRY_ID = pAddCountryId
           and exists(
                 select 1
                   from PCS.PC_ADPRT_CNTRY ADC
                  where ADC.PC_CNTRY_ID = CNT.PC_CNTRY_ID
                    and ADC.PC_ADPRT_ID = ADP.PC_ADPRT_ID
                    and ADC.PC_BASIC_CNTRY_ID = PCS.PC_I_LIB_SESSION.GetCompCntryId)
      union
      select   '1' SORTFIELD
             , ADP.ADPMACRO
             , CNT.CNTNAME
             , CNT.CNTID
          from PCS.PC_ADPRT ADP
             , PCS.PC_CNTRY CNT
         where CNT.PC_CNTRY_ID = pAddCountryId
           and ADP.PC_ADPRT_ID = CNT.PC_ADPRT_ID
      order by SORTFIELD;

    AddressFormat AddressFormatCursor%rowtype;   /*Réceptionne les données du curseur des formats d'adresses*/
    strResult     PAC_ADDRESS.ADD_FORMAT%type;   /*Variable de retour de la fonction */
  begin
    strResult  := '';

    /*Réception du format d'adresse*/
    open AddressFormatCursor;

    fetch AddressFormatCursor
     into AddressFormat;

    if AddressFormatCursor%found then
      /*Assignation du champ mémo au résultat sous forme de string*/
      strResult  :=
        replace(replace(replace(replace(replace(replace(upper(AddressFormat.ADPMACRO), 'ZIP', '{ZIP}'), 'CITY'
                                              , '{CITY}')
                                      , 'STATE'
                                      , '{STATE}'
                                       )
                              , 'COUNTY'
                              , '{COUNTY}'
                               )
                      , 'CNTNAME'
                      , '{CNTNAME}'
                       )
              , 'CNTID'
              , '{CNTID}'
               );
      /*Remplacement des champs de la macro par leur valeurs respectives*/
      strResult  :=
        replace(replace(replace(replace(replace(replace(strResult, '{ZIP}', pAddZipCode), '{CITY}', pAddCity)
                                      , '{STATE}'
                                      , pAddState
                                       )
                              , '{COUNTY}'
                              , pAddCounty
                               )
                      , '{CNTNAME}'
                      , AddressFormat.CNTNAME
                       )
              , '{CNTID}'
              , AddressFormat.CNTID
               );
    end if;

    close AddressFormatCursor;

    return rtrim(ltrim(strResult) );
  end FormatingAddress;

  /**
  * Description
  *    Retourne la limite de crédit d'un partenaire, en fonction d'une date
  */
  procedure GetCreditLimit(
    aTypePartner           in     varchar2
  , aPAC_PERSON_ID         in     PAC_PERSON.PAC_PERSON_ID%type
  , aFINANCIAL_CURRENCY_ID in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aDate                  in     date
  , aGroupLimit            in     integer
  , aCRE_AMOUNT_LIMIT      in out PAC_CREDIT_LIMIT.CRE_AMOUNT_LIMIT%type
  , aC_LIMIT_TYPE          out    PAC_CREDIT_LIMIT.C_LIMIT_TYPE%type
  , aCRE_LIMIT_DATE        out    PAC_CREDIT_LIMIT.CRE_LIMIT_DATE%type
  )
  is
    ThirdID PAC_THIRD.PAC_THIRD_ID%type;
  begin
    begin
      -- Recherche la limite de crédit pour partenaire groupe
      if aGroupLimit = 1 then
        -- Clients
        if aTypePartner = 'C' then
          -- Recherche l'id du partenaire Groupe (Catégorie partenaire -> 2 = Groupe , 3 = Membre de groupe)
          select PAC_CUSTOM_PARTNER_ID
            into ThirdID
            from PAC_CUSTOM_PARTNER
           where C_PARTNER_CATEGORY = '2'
             and ACS_AUXILIARY_ACCOUNT_ID = (select ACS_AUXILIARY_ACCOUNT_ID
                                               from PAC_CUSTOM_PARTNER
                                              where PAC_CUSTOM_PARTNER_ID = aPAC_PERSON_ID);

          -- Recherche de la limite de crédit Client du Groupe
          select CRE_AMOUNT_LIMIT
               , C_LIMIT_TYPE
               , CRE_LIMIT_DATE
            into aCRE_AMOUNT_LIMIT
               , aC_LIMIT_TYPE
               , aCRE_LIMIT_DATE
            from PAC_CREDIT_LIMIT
           where PAC_CUSTOM_PARTNER_ID = ThirdID
             and ACS_FINANCIAL_CURRENCY_ID = aFINANCIAL_CURRENCY_ID
             and CRE_LIMIT_CREDIT_GRP = 1
             and C_VALID = 'VAL'
             and (   CRE_LIMIT_DATE >= aDate
                  or CRE_LIMIT_DATE is null);
        -- Fournisseurs
        elsif aTypePartner = 'S' then
          -- Recherche l'id du partenaire Groupe (Catégorie partenaire -> 2 = Groupe , 3 = Membre de groupe)
          select PAC_SUPPLIER_PARTNER_ID
            into ThirdID
            from PAC_SUPPLIER_PARTNER
           where C_PARTNER_CATEGORY = '2'
             and ACS_AUXILIARY_ACCOUNT_ID = (select ACS_AUXILIARY_ACCOUNT_ID
                                               from PAC_SUPPLIER_PARTNER
                                              where PAC_SUPPLIER_PARTNER_ID = aPAC_PERSON_ID);

          -- Recherche de la limite de crédit Fournisseur du Groupe
          select CRE_AMOUNT_LIMIT
               , C_LIMIT_TYPE
               , CRE_LIMIT_DATE
            into aCRE_AMOUNT_LIMIT
               , aC_LIMIT_TYPE
               , aCRE_LIMIT_DATE
            from PAC_CREDIT_LIMIT
           where PAC_SUPPLIER_PARTNER_ID = ThirdID
             and ACS_FINANCIAL_CURRENCY_ID = aFINANCIAL_CURRENCY_ID
             and CRE_LIMIT_CREDIT_GRP = 1
             and C_VALID = 'VAL'
             and (   CRE_LIMIT_DATE >= aDate
                  or CRE_LIMIT_DATE is null);
        end if;
      -- Recherche la limite de crédit pour partenaire individuel
      else
        -- Clients
        if aTypePartner = 'C' then
          -- Recherche de la limite de crédit Client individuel
          select CRE_AMOUNT_LIMIT
               , C_LIMIT_TYPE
               , CRE_LIMIT_DATE
            into aCRE_AMOUNT_LIMIT
               , aC_LIMIT_TYPE
               , aCRE_LIMIT_DATE
            from PAC_CREDIT_LIMIT
           where PAC_CUSTOM_PARTNER_ID = aPAC_PERSON_ID
             and ACS_FINANCIAL_CURRENCY_ID = aFINANCIAL_CURRENCY_ID
             and C_VALID = 'VAL'
             and CRE_LIMIT_CREDIT_GRP = 0
             and (   CRE_LIMIT_DATE >= aDate
                  or CRE_LIMIT_DATE is null);
        -- Fournisseurs
        elsif aTypePartner = 'S' then
          -- Recherche de la limite de crédit Fournisseur individuel
          select CRE_AMOUNT_LIMIT
               , C_LIMIT_TYPE
               , CRE_LIMIT_DATE
            into aCRE_AMOUNT_LIMIT
               , aC_LIMIT_TYPE
               , aCRE_LIMIT_DATE
            from PAC_CREDIT_LIMIT
           where PAC_SUPPLIER_PARTNER_ID = aPAC_PERSON_ID
             and ACS_FINANCIAL_CURRENCY_ID = aFINANCIAL_CURRENCY_ID
             and C_VALID = 'VAL'
             and CRE_LIMIT_CREDIT_GRP = 0
             and (   CRE_LIMIT_DATE >= aDate
                  or CRE_LIMIT_DATE is null);
        end if;
      end if;
    exception
      when no_data_found then
        aCRE_LIMIT_DATE  := null;
    end;

    -- Si la limite n'est pas en monnaie de base -> effectuer la conversion
    if     aCRE_AMOUNT_LIMIT is not null
       and aFINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyId then
      aCRE_AMOUNT_LIMIT  :=
        ACS_FUNCTION.ConvertAmountForView(aCRE_AMOUNT_LIMIT
                                        , aFINANCIAL_CURRENCY_ID
                                        , ACS_FUNCTION.GetLocalCurrencyId
                                        , aDate
                                        , 0
                                        ,   -- aExchangeRate
                                          0
                                        ,   -- aBasePrice
                                          1
                                         );
    end if;
  end GetCreditLimit;

  /**
  * Description
  *    Retourne la limite de crédit d'un partenaire, en fonction de la date système
  */
  function CreditLimit(aTypePartner varchar2, aPAC_PERSON_ID PAC_PERSON.PAC_PERSON_ID%type)
    return PAC_CREDIT_LIMIT.CRE_AMOUNT_LIMIT%type
  is
    CRE_AMOUNT_LIMIT      PAC_CREDIT_LIMIT.CRE_AMOUNT_LIMIT%type;
    FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    ExchangeRate          ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePrice             ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    BaseChange            number(1);
    Flag                  number(1);

    cursor C_CRE_AMOUNT_LIMIT
    is
      select CRE_AMOUNT_LIMIT
           , ACS_FINANCIAL_CURRENCY_ID
        from PAC_CREDIT_LIMIT
       where PAC_CUSTOM_PARTNER_ID = aPAC_PERSON_ID
         and C_VALID = 'VAL'
         and (   CRE_LIMIT_DATE >= sysdate
              or CRE_LIMIT_DATE is null);

    cursor S_CRE_AMOUNT_LIMIT
    is
      select CRE_AMOUNT_LIMIT
           , ACS_FINANCIAL_CURRENCY_ID
        from PAC_CREDIT_LIMIT
       where PAC_SUPPLIER_PARTNER_ID = aPAC_PERSON_ID
         and C_VALID = 'VAL'
         and (   CRE_LIMIT_DATE >= sysdate
              or CRE_LIMIT_DATE is null);
  begin
    begin
      if aTypePartner = 'C' then
        select CRE_AMOUNT_LIMIT
          into CRE_AMOUNT_LIMIT
          from PAC_CREDIT_LIMIT
         where PAC_CUSTOM_PARTNER_ID = aPAC_PERSON_ID
           and ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
           and C_VALID = 'VAL'
           and (   CRE_LIMIT_DATE >= sysdate
                or CRE_LIMIT_DATE is null);
      elsif aTypePartner = 'S' then
        select CRE_AMOUNT_LIMIT
          into CRE_AMOUNT_LIMIT
          from PAC_CREDIT_LIMIT
         where PAC_SUPPLIER_PARTNER_ID = aPAC_PERSON_ID
           and ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
           and C_VALID = 'VAL'
           and (   CRE_LIMIT_DATE >= sysdate
                or CRE_LIMIT_DATE is null);
      end if;
    exception
      when no_data_found then
        begin
          if aTypePartner = 'C' then
            open C_CRE_AMOUNT_LIMIT;

            fetch C_CRE_AMOUNT_LIMIT
             into CRE_AMOUNT_LIMIT
                , FINANCIAL_CURRENCY_ID;

            close C_CRE_AMOUNT_LIMIT;
          elsif aTypePartner = 'S' then
            open S_CRE_AMOUNT_LIMIT;

            fetch S_CRE_AMOUNT_LIMIT
             into CRE_AMOUNT_LIMIT
                , FINANCIAL_CURRENCY_ID;

            close S_CRE_AMOUNT_LIMIT;
          end if;

          if CRE_AMOUNT_LIMIT is not null then
            -- Flag  := ACS_FUNCTION.ExtractRate(FINANCIAL_CURRENCY_ID, 1, SYSDATE, ExchangeRate, BasePrice, BaseChange);
            -- CRE_AMOUNT_LIMIT := ACS_FUNCTION.RoundAmount(CRE_AMOUNT_LIMIT * ExchangeRate / BasePrice, FINANCIAL_CURRENCY_ID);
            CRE_AMOUNT_LIMIT  :=
              ACS_FUNCTION.ConvertAmountForView(CRE_AMOUNT_LIMIT
                                              , FINANCIAL_CURRENCY_ID
                                              , ACS_FUNCTION.GetLocalCurrencyId
                                              , sysdate
                                              , 0
                                              ,   -- aExchangeRate
                                                0
                                              ,   -- aBasePrice
                                                1
                                               );
          end if;
        exception
          when no_data_found then
            CRE_AMOUNT_LIMIT  := 0;
        end;
    end;

    return CRE_AMOUNT_LIMIT;
  end CreditLimit;

  /**
  * Description
  *    Ramène descriptions du compte
  */
  procedure GetAccountDescr(
    aPAC_PERSON_ID in     PAC_PERSON.PAC_PERSON_ID%type
  , aPER_NAME      in     PAC_PERSON.PER_NAME%type
  , aPER_FORENAME  in     PAC_PERSON.PER_FORENAME%type
  , aSUMMARY       out    ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type
  , aLARGE         out    ACS_DESCRIPTION.DES_DESCRIPTION_LARGE%type
  )
  is
  begin
    ACS_FUNCTION.getPersonAccountDescr(aPAC_PERSON_ID, aPER_NAME, aPER_FORENAME, aSUMMARY, aLARGE);
  end GetAccountDescr;

  /**
  * Description
  *    Création du compte auxiliaire d'un partenaire donné
  */
  procedure CreateAuxiliaryAccount(
    aPAC_THIRD_ID              in     PAC_THIRD.PAC_THIRD_ID%type
  , aACS_SUB_SET_ID            in     ACS_SUB_SET.ACS_SUB_SET_ID%type
  , aC_PARTNER_CATEGORY        in     PAC_CUSTOM_PARTNER.C_PARTNER_CATEGORY%type
  , aACS_FINANCIAL_CURRENCY_ID in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , pGroupAuxiliaryAccountId   in     ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type default null
  , aACS_AUXILIARY_ACCOUNT_ID  in out ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  )
  is
    cursor ActiveLanguage
    is
      select PC_LANG_ID
        from PCS.PC_LANG
       where LANUSED = 1;

    SubSetOk      number                                                  default 1;
    Ok            number                                                  default 1;
    SubSet        ACS_SUB_SET.C_SUB_SET%type;
    TypeNum       ACS_SUB_SET.C_TYPE_NUM_AUTO%type;
    Prefix        ACS_SUB_SET.SSE_PREFIX%type;
    Picture       ACS_PICTURE.PIC_PICTURE%type;
    AccountNumber ACS_ACCOUNT.ACC_NUMBER%type;
    name          PAC_PERSON.PER_NAME%type;
    ForeName      PAC_PERSON.PER_FORENAME%type;
    Key1          PAC_PERSON.PER_KEY1%type;
    Key2          PAC_PERSON.PER_KEY2%type;
    AccountId     ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
    TypeAccount   ACS_AUXILIARY_ACCOUNT.C_TYPE_ACCOUNT%type;
    InvoiceCollId ACS_AUXILIARY_ACCOUNT.ACS_INVOICE_COLL_ID%type;
    PrepCollId    ACS_AUXILIARY_ACCOUNT.ACS_PREP_COLL_ID%type;
    Description1  ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type;
    Description2  ACS_DESCRIPTION.DES_DESCRIPTION_LARGE%type;
    LangId        ACS_DESCRIPTION.PC_LANG_ID%type;
    DivisionId    ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    CurrencyId    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    UserIni       PCS.PC_USER.USE_INI%type;

    --------
    function GetAccNumber(
      aTypeNum       ACS_SUB_SET.C_TYPE_NUM_AUTO%type
    , aPrefix        ACS_SUB_SET.SSE_PREFIX%type
    , aPicture       ACS_PICTURE.PIC_PICTURE%type
    , aKey1          PAC_PERSON.PER_KEY1%type
    , aKey2          PAC_PERSON.PER_KEY2%type
    , aPAC_PERSON_ID PAC_PERSON.PAC_PERSON_ID%type
    )
      return ACS_ACCOUNT.ACC_NUMBER%type
    is
      AccountNumber ACS_ACCOUNT.ACC_NUMBER%type;
      Picture       ACS_PICTURE.PIC_PICTURE%type;
    begin
      Picture  := replace(aPicture, '\');

      if aTypeNum = 'KEY1' then
        AccountNumber  := aPrefix || aKey1;
      elsif aTypeNum = 'KEY2' then
        AccountNumber  := aPrefix || aKey2;
      elsif aTypeNum = 'ID' then
        AccountNumber  := aPrefix || lpad(to_char(aPAC_PERSON_ID), length(Picture) - length(aPrefix), '0');
      end if;

      return AccountNumber;
    end GetAccNumber;

    --------
    function GetDivisionId(aACS_FINANCIAL_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
      return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
    is
      DivisionId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    begin
      begin
        select ACS_DIVISION_ACCOUNT_ID
          into DivisionId
          from ACS_INTERACTION
         where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
           and INT_PAIR_DEFAULT = 1;
      exception
        when others then
          DivisionId  := ACS_FUNCTION.GetDefaultDivision;
      end;

      return DivisionId;
    end GetDivisionId;
  -----
  begin
    if aC_PARTNER_CATEGORY in('1', '2') then
      /* Compte auxiliaire non initialisé */
      if    (aACS_AUXILIARY_ACCOUNT_ID is null)
         or (aACS_AUXILIARY_ACCOUNT_ID = 0) then
        begin
          select SUB.C_SUB_SET
               , SUB.C_TYPE_NUM_AUTO
               , SUB.SSE_PREFIX
               , SUB.ACS_PROP_INVOICE_COLL_ID
               , SUB.ACS_PROP_PREP_COLL_ID
               , PIC.PIC_PICTURE
            into SubSet
               , TypeNum
               , Prefix
               , InvoiceCollId
               , PrepCollId
               , Picture
            from ACS_SUB_SET SUB
               , ACS_PICTURE PIC
           where SUB.ACS_PICTURE_ID = PIC.ACS_PICTURE_ID
             and SUB.ACS_SUB_SET_ID = aACS_SUB_SET_ID;

          if    InvoiceCollId is null
             or PrepCollId is null then
            SubSetOk  := 0;
          end if;
        exception
          when others then
            SubSetOk  := 0;
        end;

        if SubSetOk = 1 then
          begin
            select PER_NAME
                 , PER_FORENAME
                 , PER_KEY1
                 , PER_KEY2
              into name
                 , ForeName
                 , Key1
                 , Key2
              from PAC_PERSON
             where PAC_PERSON_ID = aPAC_THIRD_ID;
          exception
            when others then
              Ok  := 0;
          end;

          if Ok = 1 then
            if aC_PARTNER_CATEGORY = '1' then
              TypeAccount  := 'PRI';
            else
              TypeAccount  := 'GRP';
            end if;

            UserIni        := PCS.PC_I_LIB_SESSION.GetUserIni;
            AccountNumber  := GetAccNumber(TypeNum, Prefix, Picture, Key1, Key2, aPAC_THIRD_ID);

            if    (AccountNumber <> Prefix)
               or (AccountNumber is null)
               or (Prefix is null) then
              begin
                CurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
                DivisionId  := GetDivisionId(InvoiceCollId);
                GetAccountDescr(aPAC_THIRD_ID, name, ForeName, Description1, Description2);

                select INIT_ID_SEQ.nextval
                  into aACS_AUXILIARY_ACCOUNT_ID
                  from dual;

                begin
                  insert into ACS_ACCOUNT
                              (ACS_ACCOUNT_ID
                             , ACS_SUB_SET_ID
                             , C_VALID
                             , ACC_NUMBER
                             , ACC_DETAIL_PRINTING
                             , ACC_BLOCKED
                             , ACC_INTEREST
                             , A_DATECRE
                             , A_IDCRE
                              )
                       values (aACS_AUXILIARY_ACCOUNT_ID
                             , aACS_SUB_SET_ID
                             , 'VAL'
                             , AccountNumber
                             , 1
                             , 0
                             , 0
                             , sysdate
                             , UserIni
                              );
                exception
                  when dup_val_on_index then
                    select min(ACS_ACCOUNT_ID)
                      into aACS_AUXILIARY_ACCOUNT_ID
                      from ACS_ACCOUNT
                     where ACC_NUMBER = AccountNumber
                       and ACS_SUB_SET_ID = aACS_SUB_SET_ID
                       and C_VALID = 'VAL';
                end;

                begin
                  insert into ACS_AUXILIARY_ACCOUNT
                              (ACS_AUXILIARY_ACCOUNT_ID
                             , ACS_PREP_COLL_ID
                             , ACS_INVOICE_COLL_ID
                             , ACS_DIVISION_ACCOUNT_ID
                             , C_REPORT
                             , C_TYPE_ACCOUNT
                             , AUX_LETTERING
                             , C_REMINDER_FILTER
                             , A_DATECRE
                             , A_IDCRE
                              )
                       values (aACS_AUXILIARY_ACCOUNT_ID
                             , PrepCollId
                             , InvoiceCollId
                             , DivisionId
                             , 'DET'
                             , TypeAccount
                             , 1
                             , 0
                             , sysdate
                             , UserIni
                              );

                  -- Table ACS_AUX_ACCOUNT_S_FIN_CURR
                  insert into ACS_AUX_ACCOUNT_S_FIN_CURR
                              (ACS_AUXILIARY_ACCOUNT_ID
                             , ACS_FINANCIAL_CURRENCY_ID
                              )
                       values (aACS_AUXILIARY_ACCOUNT_ID
                             , CurrencyId
                              );

                  if     aACS_FINANCIAL_CURRENCY_ID is not null
                     and aACS_FINANCIAL_CURRENCY_ID <> CurrencyId then
                    insert into ACS_AUX_ACCOUNT_S_FIN_CURR
                                (ACS_AUXILIARY_ACCOUNT_ID
                               , ACS_FINANCIAL_CURRENCY_ID
                                )
                         values (aACS_AUXILIARY_ACCOUNT_ID
                               , aACS_FINANCIAL_CURRENCY_ID
                                );
                  end if;
                exception
                  when dup_val_on_index then
                    null;
                end;

                -- Table ACS_DESCRIPTION
                open ActiveLanguage;

                fetch ActiveLanguage
                 into LangId;

                while ActiveLanguage%found loop
                  begin
                    insert into ACS_DESCRIPTION
                                (ACS_DESCRIPTION_ID
                               , ACS_ACCOUNT_ID
                               , PC_LANG_ID
                               , DES_DESCRIPTION_SUMMARY
                               , DES_DESCRIPTION_LARGE
                               , A_DATECRE
                               , A_IDCRE
                                )
                         values (INIT_ID_SEQ.nextval
                               , aACS_AUXILIARY_ACCOUNT_ID
                               , LangId
                               , Description1
                               , Description2
                               , sysdate
                               , UserIni
                                );
                  exception
                    when dup_val_on_index then
                      null;
                  end;

                  fetch ActiveLanguage
                   into LangId;
                end loop;

                close ActiveLanguage;
              exception
                when others then
                  Ok                         := 0;
                  aACS_AUXILIARY_ACCOUNT_ID  := null;
              end;
            end if;
          end if;
        end if;
      else
        /*Liaison au sous-ensemble passé en paramètre*/
        update ACS_ACCOUNT
           set ACS_SUB_SET_ID = aACS_SUB_SET_ID
         where ACS_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID;
      end if;
    elsif aC_PARTNER_CATEGORY = '3' then
      /*Liaison au compte du groupe pour les membres*/
      if not pGroupAuxiliaryAccountId is null then
        aACS_AUXILIARY_ACCOUNT_ID  := pGroupAuxiliaryAccountId;
      end if;
    end if;
  end CreateAuxiliaryAccount;

-----------------------------
  procedure GetNumberMethodInfo(
    aPAC_EVENT_TYPE_ID    in     PAC_EVENT.PAC_EVENT_TYPE_ID%type
  , aEVE_DATE             in     PAC_EVENT.EVE_DATE%type
  , aPAC_NUMBER_METHOD_ID in out PAC_NUMBER_METHOD.PAC_NUMBER_METHOD_ID%type
  , aPNM_LAST_NUMBER      in out PAC_NUMBER_METHOD.PNM_LAST_NUMBER%type
  , aC_NUMBER_TYPE        in out ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type
  , aDNM_PREFIX           in out ACJ_NUMBER_METHOD.DNM_PREFIX%type
  , aDNM_SUFFIX           in out ACJ_NUMBER_METHOD.DNM_SUFFIX%type
  , aDNM_INCREMENT        in out ACJ_NUMBER_METHOD.DNM_INCREMENT%type
  , aDNM_FREE_MANAGEMENT  in out ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type
  , aPicPrefix            in out ACS_PICTURE.PIC_PICTURE%type
  , aPicNumber            in out ACS_PICTURE.PIC_PICTURE%type
  , aPicSuffix            in out ACS_PICTURE.PIC_PICTURE%type
  )
  is
  begin
    aPAC_NUMBER_METHOD_ID  := null;

    select min(PAC_NUMBER_METHOD_ID)
      into aPAC_NUMBER_METHOD_ID
      from PAC_NUMBER_APPLICATION APP
     where PAC_EVENT_TYPE_ID = aPAC_EVENT_TYPE_ID
       and (   NUA_SINCE <= aEVE_DATE
            or NUA_SINCE is null)
       and (   NUA_TO >= aEVE_DATE
            or NUA_TO is null);

    if aPAC_NUMBER_METHOD_ID is not null then
      select PNM_LAST_NUMBER
           , C_NUMBER_TYPE
           , DNM_PREFIX
           , DNM_SUFFIX
           , DNM_INCREMENT
           , DNM_FREE_MANAGEMENT
           , PIP.PIC_PICTURE
           , PIN.PIC_PICTURE
           , PIS.PIC_PICTURE
        into aPNM_LAST_NUMBER
           , aC_NUMBER_TYPE
           , aDNM_PREFIX
           , aDNM_SUFFIX
           , aDNM_INCREMENT
           , aDNM_FREE_MANAGEMENT
           , aPicPrefix
           , aPicNumber
           , aPicSuffix
        from ACS_PICTURE PIS
           , ACS_PICTURE PIN
           , ACS_PICTURE PIP
           , ACJ_NUMBER_METHOD ACJ
           , PAC_NUMBER_METHOD PAC
       where PAC_NUMBER_METHOD_ID = aPAC_NUMBER_METHOD_ID
         and PAC.ACJ_NUMBER_METHOD_ID = ACJ.ACJ_NUMBER_METHOD_ID
         and ACJ.ACS_PIC_PREFIX_ID = PIP.ACS_PICTURE_ID(+)
         and ACJ.ACS_PIC_NUMBER_ID = PIN.ACS_PICTURE_ID(+)
         and ACJ.ACS_PIC_SUFFIX_ID = PIS.ACS_PICTURE_ID(+);

      if aPNM_LAST_NUMBER is null then
        aPNM_LAST_NUMBER  := 0;
      end if;
    end if;
  end GetNumberMethodInfo;

------------------------
  procedure GetEventNumber(
    aPAC_EVENT_TYPE_ID in     PAC_EVENT.PAC_EVENT_TYPE_ID%type
  , aEVE_DATE          in     PAC_EVENT.EVE_DATE%type
  , aEVE_NUMBER        in out PAC_EVENT.EVE_NUMBER%type
  )
  is
    ACJMethodId    ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type;
    PACMethodId    PAC_NUMBER_METHOD.PAC_NUMBER_METHOD_ID%type;
    FreeNumberId   PAC_FREE_NUMBER.PAC_FREE_NUMBER_ID%type;
    LastNumber     PAC_NUMBER_METHOD.PNM_LAST_NUMBER%type;
    NumberType     ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type;
    Prefix         ACJ_NUMBER_METHOD.DNM_PREFIX%type;
    Suffix         ACJ_NUMBER_METHOD.DNM_SUFFIX%type;
    increment      ACJ_NUMBER_METHOD.DNM_INCREMENT%type;
    FreeManagement ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type;
    FreeNumber     PAC_FREE_NUMBER.PNU_NUMBER%type;
    PicPrefix      ACS_PICTURE.PIC_PICTURE%type;
    PicNumber      ACS_PICTURE.PIC_PICTURE%type;
    PicSuffix      ACS_PICTURE.PIC_PICTURE%type;

    cursor FreeNumberCursor(aPAC_NUMBER_METHOD_ID PAC_NUMBER_METHOD.PAC_NUMBER_METHOD_ID%type)
    is
      select PAC_FREE_NUMBER_ID
           , PNU_NUMBER
        from PAC_FREE_NUMBER
       where PAC_NUMBER_METHOD_ID = aPAC_NUMBER_METHOD_ID
         and PNU_NUMBER = (select min(PNU_NUMBER)
                             from PAC_FREE_NUMBER
                            where PAC_NUMBER_METHOD_ID = aPAC_NUMBER_METHOD_ID);
  -----
  begin
    aEVE_NUMBER  := null;
    GetNumberMethodInfo(aPAC_EVENT_TYPE_ID
                      , aEVE_DATE
                      , PACMethodId
                      , LastNumber
                      , NumberType
                      , Prefix
                      , Suffix
                      , increment
                      , FreeManagement
                      , PicPrefix
                      , PicNumber
                      , PicSuffix
                       );

    if PACMethodId is not null then
      -- Récupération d'un numéro libre
      if FreeManagement = 1 then
        open FreeNumberCursor(PACMethodId);

        fetch FreeNumberCursor
         into FreeNumberId
            , FreeNumber;

        close FreeNumberCursor;
      end if;

      aEVE_NUMBER  :=
        ACT_FUNCTIONS.DocNumber(null
                              ,   -- aACS_FINANCIAL_YEAR_ID
                                LastNumber
                              , NumberType
                              , Prefix
                              , Suffix
                              , increment
                              , FreeManagement
                              , FreeNumber
                              , PicPrefix
                              , PicNumber
                              , PicSuffix
                               );

      if aEVE_NUMBER is not null then
        if     FreeManagement = 1
           and FreeNumberId is not null then
          -- Elimination numéro libre réutilisé
          delete from PAC_FREE_NUMBER
                where PAC_FREE_NUMBER_ID = FreeNumberId;
        else
          -- Mise à jour dernier numéro utilisé
          update PAC_NUMBER_METHOD
             set PNM_LAST_NUMBER = LastNumber + increment
           where PAC_NUMBER_METHOD_ID = PACMethodId;
        end if;
      end if;
    end if;
  end GetEventNumber;

-----------------------
  function ReturnEventNum(
    aPAC_EVENT_TYPE_ID in PAC_EVENT.PAC_EVENT_TYPE_ID%type
  , aEVE_DATE          in PAC_EVENT.EVE_DATE%type
  )
    return PAC_EVENT.EVE_NUMBER%type
  is
    ACJMethodId    ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type;
    PACMethodId    PAC_NUMBER_METHOD.PAC_NUMBER_METHOD_ID%type;
    FreeNumberId   PAC_FREE_NUMBER.PAC_FREE_NUMBER_ID%type;
    aEVE_NUMBER    PAC_EVENT.EVE_NUMBER%type;
    LastNumber     PAC_NUMBER_METHOD.PNM_LAST_NUMBER%type;
    NumberType     ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type;
    Prefix         ACJ_NUMBER_METHOD.DNM_PREFIX%type;
    Suffix         ACJ_NUMBER_METHOD.DNM_SUFFIX%type;
    increment      ACJ_NUMBER_METHOD.DNM_INCREMENT%type;
    FreeManagement ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type;
    FreeNumber     PAC_FREE_NUMBER.PNU_NUMBER%type;
    PicPrefix      ACS_PICTURE.PIC_PICTURE%type;
    PicNumber      ACS_PICTURE.PIC_PICTURE%type;
    PicSuffix      ACS_PICTURE.PIC_PICTURE%type;
  -----
  begin
    aEVE_NUMBER  := null;
    GetNumberMethodInfo(aPAC_EVENT_TYPE_ID
                      , aEVE_DATE
                      , PACMethodId
                      , LastNumber
                      , NumberType
                      , Prefix
                      , Suffix
                      , increment
                      , FreeManagement
                      , PicPrefix
                      , PicNumber
                      , PicSuffix
                       );

    if PACMethodId is not null then
      aEVE_NUMBER  :=
        ACT_FUNCTIONS.DocNumber(null
                              ,   -- aACS_FINANCIAL_YEAR_ID
                                LastNumber
                              , NumberType
                              , Prefix
                              , Suffix
                              , increment
                              , 0
                              , ''
                              , PicPrefix
                              , PicNumber
                              , PicSuffix
                               );
    end if;

    return aEVE_NUMBER;
  end ReturnEventNum;

  procedure AddFreeNumber(
    aPAC_EVENT_TYPE_ID in PAC_EVENT.PAC_EVENT_TYPE_ID%type
  , aEVE_DATE          in PAC_EVENT.EVE_DATE%type
  , aEVE_NUMBER        in PAC_EVENT.EVE_NUMBER%type
  )
  is
    LastNumber     PAC_NUMBER_METHOD.PNM_LAST_NUMBER%type;
    PACMethodId    PAC_NUMBER_METHOD.PAC_NUMBER_METHOD_ID%type;
    NumberType     ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type;
    Prefix         ACJ_NUMBER_METHOD.DNM_PREFIX%type;
    Suffix         ACJ_NUMBER_METHOD.DNM_SUFFIX%type;
    increment      ACJ_NUMBER_METHOD.DNM_INCREMENT%type;
    FreeManagement ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type;
    PicPrefix      ACS_PICTURE.PIC_PICTURE%type;
    PicNumber      ACS_PICTURE.PIC_PICTURE%type;
    PicSuffix      ACS_PICTURE.PIC_PICTURE%type;
  begin
    GetNumberMethodInfo(aPAC_EVENT_TYPE_ID
                      , aEVE_DATE
                      , PACMethodId
                      , LastNumber
                      , NumberType
                      , Prefix
                      , Suffix
                      , increment
                      , FreeManagement
                      , PicPrefix
                      , PicNumber
                      , PicSuffix
                       );

    if PACMethodId is not null then
      if FreeManagement = 1 then
        begin
          LastNumber  := to_number(substr(aEVE_NUMBER, nvl(length(Prefix), 0) + 1, length(PicNumber) ) );
        exception
          when value_error then
            LastNumber  := 0;
        end;

        if LastNumber > 0 then
          begin
            insert into PAC_FREE_NUMBER
                        (PAC_FREE_NUMBER_ID
                       , PAC_NUMBER_METHOD_ID
                       , PNU_NUMBER
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , PACMethodId
                       , LastNumber
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          exception
            when dup_val_on_index then
              null;
          end;
        end if;
      end if;
    end if;
  end AddFreeNumber;

--------------------
  function GetCharCode(
    aTABNAME              PCS.PC_TABLE.TABNAME%type
  , aID                   PAC_CHAR_CODE.PAC_EVENT_ID%type
  , aDIC_CHAR_CODE_TYP_ID DIC_CHAR_CODE_TYP.DIC_CHAR_CODE_TYP_ID%type
  )
    return PAC_CHAR_CODE.CHA_CODE%type
  is
    Code PAC_CHAR_CODE.CHA_CODE%type   default null;
  begin
    begin
      if aTABNAME = 'PAC_PERSON' then
        select CHA_CODE
          into Code
          from PAC_CHAR_CODE
         where PAC_PERSON_ID = aID
           and DIC_CHAR_CODE_TYP_ID = aDIC_CHAR_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_EVENT' then
        select CHA_CODE
          into Code
          from PAC_CHAR_CODE
         where PAC_EVENT_ID = aID
           and DIC_CHAR_CODE_TYP_ID = aDIC_CHAR_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_PERSON_ASSOCIATION' then
        select CHA_CODE
          into Code
          from PAC_CHAR_CODE
         where PAC_PERSON_ASSOCIATION_ID = aID
           and DIC_CHAR_CODE_TYP_ID = aDIC_CHAR_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_SUPPLIER_PARTNER' then
        select CHA_CODE
          into Code
          from PAC_CHAR_CODE
         where PAC_SUPPLIER_PARTNER_ID = aID
           and DIC_CHAR_CODE_TYP_ID = aDIC_CHAR_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_CUSTOM_PARTNER' then
        select CHA_CODE
          into Code
          from PAC_CHAR_CODE
         where PAC_CUSTOM_PARTNER_ID = aID
           and DIC_CHAR_CODE_TYP_ID = aDIC_CHAR_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_REPRESENTATIVE' then
        select CHA_CODE
          into Code
          from PAC_CHAR_CODE
         where PAC_REPRESENTATIVE_ID = aID
           and DIC_CHAR_CODE_TYP_ID = aDIC_CHAR_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_SENDING_CONDITION' then
        select CHA_CODE
          into Code
          from PAC_CHAR_CODE
         where PAC_SENDING_CONDITION_ID = aID
           and DIC_CHAR_CODE_TYP_ID = aDIC_CHAR_CODE_TYP_ID;
      end if;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetCharCode;

-----------------------
  function GetBooleanCode(
    aTABNAME                 PCS.PC_TABLE.TABNAME%type
  , aID                      PAC_BOOLEAN_CODE.PAC_EVENT_ID%type
  , aDIC_BOOLEAN_CODE_TYP_ID DIC_BOOLEAN_CODE_TYP.DIC_BOOLEAN_CODE_TYP_ID%type
  )
    return PAC_BOOLEAN_CODE.BOO_CODE%type
  is
    Code PAC_BOOLEAN_CODE.BOO_CODE%type   default null;
  begin
    begin
      if aTABNAME = 'PAC_PERSON' then
        select BOO_CODE
          into Code
          from PAC_BOOLEAN_CODE
         where PAC_PERSON_ID = aID
           and DIC_BOOLEAN_CODE_TYP_ID = aDIC_BOOLEAN_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_EVENT' then
        select BOO_CODE
          into Code
          from PAC_BOOLEAN_CODE
         where PAC_EVENT_ID = aID
           and DIC_BOOLEAN_CODE_TYP_ID = aDIC_BOOLEAN_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_PERSON_ASSOCIATION' then
        select BOO_CODE
          into Code
          from PAC_BOOLEAN_CODE
         where PAC_PERSON_ASSOCIATION_ID = aID
           and DIC_BOOLEAN_CODE_TYP_ID = aDIC_BOOLEAN_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_SUPPLIER_PARTNER' then
        select BOO_CODE
          into Code
          from PAC_BOOLEAN_CODE
         where PAC_SUPPLIER_PARTNER_ID = aID
           and DIC_BOOLEAN_CODE_TYP_ID = aDIC_BOOLEAN_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_CUSTOM_PARTNER' then
        select BOO_CODE
          into Code
          from PAC_BOOLEAN_CODE
         where PAC_CUSTOM_PARTNER_ID = aID
           and DIC_BOOLEAN_CODE_TYP_ID = aDIC_BOOLEAN_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_REPRESENTATIVE' then
        select BOO_CODE
          into Code
          from PAC_BOOLEAN_CODE
         where PAC_REPRESENTATIVE_ID = aID
           and DIC_BOOLEAN_CODE_TYP_ID = aDIC_BOOLEAN_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_SENDING_CONDITION' then
        select BOO_CODE
          into Code
          from PAC_BOOLEAN_CODE
         where PAC_SENDING_CONDITION_ID = aID
           and DIC_BOOLEAN_CODE_TYP_ID = aDIC_BOOLEAN_CODE_TYP_ID;
      end if;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetBooleanCode;

----------------------
  function GetNumberCode(
    aTABNAME                PCS.PC_TABLE.TABNAME%type
  , aID                     PAC_NUMBER_CODE.PAC_EVENT_ID%type
  , aDIC_NUMBER_CODE_TYP_ID DIC_NUMBER_CODE_TYP.DIC_NUMBER_CODE_TYP_ID%type
  )
    return PAC_NUMBER_CODE.NUM_CODE%type
  is
    Code PAC_NUMBER_CODE.NUM_CODE%type   default null;
  begin
    begin
      if aTABNAME = 'PAC_PERSON' then
        select NUM_CODE
          into Code
          from PAC_NUMBER_CODE
         where PAC_PERSON_ID = aID
           and DIC_NUMBER_CODE_TYP_ID = aDIC_NUMBER_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_EVENT' then
        select NUM_CODE
          into Code
          from PAC_NUMBER_CODE
         where PAC_EVENT_ID = aID
           and DIC_NUMBER_CODE_TYP_ID = aDIC_NUMBER_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_PERSON_ASSOCIATION' then
        select NUM_CODE
          into Code
          from PAC_NUMBER_CODE
         where PAC_PERSON_ASSOCIATION_ID = aID
           and DIC_NUMBER_CODE_TYP_ID = aDIC_NUMBER_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_SUPPLIER_PARTNER' then
        select NUM_CODE
          into Code
          from PAC_NUMBER_CODE
         where PAC_SUPPLIER_PARTNER_ID = aID
           and DIC_NUMBER_CODE_TYP_ID = aDIC_NUMBER_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_CUSTOM_PARTNER' then
        select NUM_CODE
          into Code
          from PAC_NUMBER_CODE
         where PAC_CUSTOM_PARTNER_ID = aID
           and DIC_NUMBER_CODE_TYP_ID = aDIC_NUMBER_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_REPRESENTATIVE' then
        select NUM_CODE
          into Code
          from PAC_NUMBER_CODE
         where PAC_REPRESENTATIVE_ID = aID
           and DIC_NUMBER_CODE_TYP_ID = aDIC_NUMBER_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_SENDING_CONDITION' then
        select NUM_CODE
          into Code
          from PAC_NUMBER_CODE
         where PAC_SENDING_CONDITION_ID = aID
           and DIC_NUMBER_CODE_TYP_ID = aDIC_NUMBER_CODE_TYP_ID;
      end if;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetNumberCode;

--------------------
  function GetDATECode(
    aTABNAME              PCS.PC_TABLE.TABNAME%type
  , aID                   PAC_DATE_CODE.PAC_EVENT_ID%type
  , aDIC_DATE_CODE_TYP_ID DIC_DATE_CODE_TYP.DIC_DATE_CODE_TYP_ID%type
  )
    return TChardate
  is
    Code TChardate(8) default null;
  begin
    begin
      if aTABNAME = 'PAC_PERSON' then
        select to_char(DAT_CODE, 'yyyymmdd')
          into Code
          from PAC_DATE_CODE
         where PAC_PERSON_ID = aID
           and DIC_DATE_CODE_TYP_ID = aDIC_DATE_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_EVENT' then
        select to_char(DAT_CODE, 'yyyymmdd')
          into Code
          from PAC_DATE_CODE
         where PAC_EVENT_ID = aID
           and DIC_DATE_CODE_TYP_ID = aDIC_DATE_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_PERSON_ASSOCIATION' then
        select to_char(DAT_CODE, 'yyyymmdd')
          into Code
          from PAC_DATE_CODE
         where PAC_PERSON_ASSOCIATION_ID = aID
           and DIC_DATE_CODE_TYP_ID = aDIC_DATE_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_SUPPLIER_PARTNER' then
        select to_char(DAT_CODE, 'yyyymmdd')
          into Code
          from PAC_DATE_CODE
         where PAC_SUPPLIER_PARTNER_ID = aID
           and DIC_DATE_CODE_TYP_ID = aDIC_DATE_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_CUSTOM_PARTNER' then
        select to_char(DAT_CODE, 'yyyymmdd')
          into Code
          from PAC_DATE_CODE
         where PAC_CUSTOM_PARTNER_ID = aID
           and DIC_DATE_CODE_TYP_ID = aDIC_DATE_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_REPRESENTATIVE' then
        select to_char(DAT_CODE, 'yyyymmdd')
          into Code
          from PAC_DATE_CODE
         where PAC_REPRESENTATIVE_ID = aID
           and DIC_DATE_CODE_TYP_ID = aDIC_DATE_CODE_TYP_ID;
      elsif aTABNAME = 'PAC_SENDING_CONDITION' then
        select to_char(DAT_CODE, 'yyyymmdd')
          into Code
          from PAC_DATE_CODE
         where PAC_SENDING_CONDITION_ID = aID
           and DIC_DATE_CODE_TYP_ID = aDIC_DATE_CODE_TYP_ID;
      end if;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetDATECode;

----------------------------
  function IsLetteringRequired(aPAC_THIRD_ID PAC_THIRD.PAC_THIRD_ID%type, aTypePartner varchar2)
    return number
  is
    result number(1)  default 0;
    Cpt    number(12);
  begin
    begin
      if aTypePartner = 'C' then   -- Client
        select count(*)
          into Cpt
          from (select   exp.EXP_PAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER_ID
                       , nvl(sum(ACT_FUNCTIONS.GETAMOUNTOFEXPIRY(exp.ACT_EXPIRY_ID, 1) ), 0) -
                         nvl(sum(ACT_FUNCTIONS.TOTALPAYMENT(exp.ACT_EXPIRY_ID, 1) ), 0) EXP_AMOUNT_LC
                    from ACT_EXPIRY exp
                   where exp.EXP_CALC_NET = 1
                     and to_number(exp.C_STATUS_EXPIRY) + 0 = 0
                     and exp.EXP_AMOUNT_LC < 0
                     and exp.EXP_PAC_SUPPLIER_PARTNER_ID is null
                     and exp.EXP_PAC_CUSTOM_PARTNER_ID = aPAC_THIRD_ID
                group by exp.EXP_PAC_CUSTOM_PARTNER_ID) NEXP
             , (select   exp.EXP_PAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER_ID
                       , nvl(sum(ACT_FUNCTIONS.GETAMOUNTOFEXPIRY(exp.ACT_EXPIRY_ID, 1) ), 0) -
                         nvl(sum(ACT_FUNCTIONS.TOTALPAYMENT(exp.ACT_EXPIRY_ID, 1) ), 0) EXP_AMOUNT_LC
                    from ACT_EXPIRY exp
                   where exp.EXP_CALC_NET = 1
                     and to_number(exp.C_STATUS_EXPIRY) + 0 = 0
                     and exp.EXP_AMOUNT_LC >= 0
                     and exp.EXP_PAC_SUPPLIER_PARTNER_ID is null
                     and exp.EXP_PAC_CUSTOM_PARTNER_ID = aPAC_THIRD_ID
                group by exp.EXP_PAC_CUSTOM_PARTNER_ID) PEXP
             , PAC_CUSTOM_PARTNER CUS
         where NEXP.PAC_CUSTOM_PARTNER_ID(+) = CUS.PAC_CUSTOM_PARTNER_ID
           and PEXP.PAC_CUSTOM_PARTNER_ID(+) = CUS.PAC_CUSTOM_PARTNER_ID
           and nvl(NEXP.EXP_AMOUNT_LC, 0) < 0
           and nvl(PEXP.EXP_AMOUNT_LC, 0) <> 0
           and nvl(NEXP.EXP_AMOUNT_LC, 0) <= nvl(PEXP.EXP_AMOUNT_LC, 0)
           and CUS.PAC_CUSTOM_PARTNER_ID = aPAC_THIRD_ID;
      elsif aTypePartner = 'S' then   -- Fournisseur
        select count(*)
          into Cpt
          from (select   exp.EXP_PAC_SUPPLIER_PARTNER_ID PAC_SUPPLIER_PARTNER_ID
                       , nvl(sum(ACT_FUNCTIONS.GETAMOUNTOFEXPIRY(exp.ACT_EXPIRY_ID, 1) ), 0) -
                         nvl(sum(ACT_FUNCTIONS.TOTALPAYMENT(exp.ACT_EXPIRY_ID, 1) ), 0) EXP_AMOUNT_LC
                    from ACT_EXPIRY exp
                   where exp.EXP_CALC_NET = 1
                     and to_number(exp.C_STATUS_EXPIRY) + 0 = 0
                     and exp.EXP_AMOUNT_LC < 0
                     and exp.EXP_PAC_CUSTOM_PARTNER_ID is null
                     and exp.EXP_PAC_SUPPLIER_PARTNER_ID = aPAC_THIRD_ID
                group by exp.EXP_PAC_SUPPLIER_PARTNER_ID) NEXP
             , (select   exp.EXP_PAC_SUPPLIER_PARTNER_ID PAC_SUPPLIER_PARTNER_ID
                       , nvl(sum(ACT_FUNCTIONS.GETAMOUNTOFEXPIRY(exp.ACT_EXPIRY_ID, 1) ), 0) -
                         nvl(sum(ACT_FUNCTIONS.TOTALPAYMENT(exp.ACT_EXPIRY_ID, 1) ), 0) EXP_AMOUNT_LC
                    from ACT_EXPIRY exp
                   where exp.EXP_CALC_NET = 1
                     and to_number(exp.C_STATUS_EXPIRY) + 0 = 0
                     and exp.EXP_AMOUNT_LC >= 0
                     and exp.EXP_PAC_CUSTOM_PARTNER_ID is null
                     and exp.EXP_PAC_SUPPLIER_PARTNER_ID = aPAC_THIRD_ID
                group by exp.EXP_PAC_SUPPLIER_PARTNER_ID) PEXP
             , PAC_SUPPLIER_PARTNER SUP
         where NEXP.PAC_SUPPLIER_PARTNER_ID(+) = SUP.PAC_SUPPLIER_PARTNER_ID
           and PEXP.PAC_SUPPLIER_PARTNER_ID(+) = SUP.PAC_SUPPLIER_PARTNER_ID
           and nvl(NEXP.EXP_AMOUNT_LC, 0) < 0
           and nvl(PEXP.EXP_AMOUNT_LC, 0) <> 0
           and nvl(NEXP.EXP_AMOUNT_LC, 0) <= nvl(PEXP.EXP_AMOUNT_LC, 0)
           and SUP.PAC_SUPPLIER_PARTNER_ID = aPAC_THIRD_ID;
      end if;

      if Cpt > 0 then
        result  := 1;
      end if;
    exception
      when others then
        result  := 0;
    end;

    return result;
  end IsLetteringRequired;

------------------
  function ExtractKey(aPER_SHORT_NAME PAC_PERSON.PER_SHORT_NAME%type, aC_KEY_TYPE PAC_KEY_FORMAT.C_KEY_TYPE%type)
    return PAC_PERSON.PER_KEY1%type
  is
    Ok              boolean                                   default true;
    result          PAC_PERSON.PER_KEY1%type                  default '';
    NumerotationTyp PAC_KEY_FORMAT.C_NUMEROTATION_TYPE%type;
    Picture         ACS_PICTURE.PIC_PICTURE%type;

    --------
    function NumAuto(aPIC_PICTURE ACS_PICTURE.PIC_PICTURE%type, aC_KEY_TYPE PAC_KEY_FORMAT.C_KEY_TYPE%type)
      return PAC_PERSON.PER_KEY1%type
    is
      PersonKey  PAC_PERSON.PER_KEY1%type;
      Picture    ACS_PICTURE.PIC_PICTURE%type;
      KeyNumber  number(12);
      LenPicture number(2);

      --------
      function CheckPicture(aPIC_PICTURE ACS_PICTURE.PIC_PICTURE%type)
        return ACS_PICTURE.PIC_PICTURE%type
      is
        Picture ACS_PICTURE.PIC_PICTURE%type;
        i       number(3);
      begin
        i  := 1;

        while i <= length(aPIC_PICTURE) loop
          if substr(aPIC_PICTURE, i, 1) = '\' then
            i  := i + 1;
          end if;

          Picture  := Picture || substr(aPIC_PICTURE, i, 1);
          i        := i + 1;
        end loop;

        return Picture;
      end CheckPicture;

      --------
      function GetPicture(aPIC_PICTURE ACS_PICTURE.PIC_PICTURE%type)
        return ACS_PICTURE.PIC_PICTURE%type
      is
        Picture ACS_PICTURE.PIC_PICTURE%type;
        i       number(3);
      begin
        i  := 1;

        while i <= length(aPIC_PICTURE) loop
          if not(   substr(aPIC_PICTURE, i, 1) = '0'
                 or substr(aPIC_PICTURE, i, 1) = '9') then
            Picture  := Picture || substr(aPIC_PICTURE, i, 1);
          end if;

          i  := i + 1;
        end loop;

        return Picture;
      end GetPicture;
    -----
    begin
      if aC_KEY_TYPE = 'KEY1' then
        select PAC_PERSON_PER_KEY1_SEQ.NextVal
          into KeyNumber
          from dual;
      else
        select PAC_PERSON_PER_KEY2_SEQ.NextVal
          into KeyNumber
          from dual;
      end if;

      Picture     := CheckPicture(aPIC_PICTURE);
      LenPicture  := length(Picture);
      Picture     := GetPicture(Picture);
      result      := Picture || lpad(to_char(KeyNumber),(LenPicture - nvl(length(Picture), 0) ), '0');
      return result;
    end NumAuto;

    --------
    function NumAVS(
      aPER_SHORT_NAME PAC_PERSON.PER_SHORT_NAME%type
    , aPIC_PICTURE    ACS_PICTURE.PIC_PICTURE%type
    , aC_KEY_TYPE     PAC_KEY_FORMAT.C_KEY_TYPE%type
    )
      return PAC_PERSON.PER_KEY1%type
    is
      cPrefix       varchar2(3);
      nNumIncrement number(12);
    begin
      select nvl(to_char(max(AVS_NUMBER)), '000')
        into cPrefix
        from PCS.PC_TABAVS
       where AVS_NAME <= upper(rpad(aPER_SHORT_NAME, 10) );

      -- Attention: possibilité d'avoir des clés avec plusieurs longueurs: 502373 et 5020430.
      -- Dans ce cas, préfix = 502 et l'incrément le plus grand = 0430
      -- Prendre en compte également le fait que PER_KEY peut commencer avec des chiffres => absent de la table AVS
      -- Si pas de PER_KEY existant pour le prefix, commencer à 1
      -- nNumIncrement contiendra déjà l'increment (+1)
      if aC_KEY_TYPE = 'KEY1' then
        select nvl(max(to_number(substr(PER_KEY1, 4))) + 1, 1)
          into nNumIncrement
          from PAC_PERSON
         where substr(PER_KEY1, 1, 3) = cPrefix;
      else
        select nvl(max(to_number(substr(PER_KEY2, 4))) + 1, 1)
          into nNumIncrement
          from PAC_PERSON
         where substr(PER_KEY2, 1, 3) = cPrefix;
      end if;

      result := cPrefix || lpad(to_char(nNumIncrement), length(aPIC_PICTURE) - 3, '0');
      if Length(to_char(nNumIncrement)) > (length(aPIC_PICTURE) - 3) then
        -- valeur maximum atteinte, il faut changer PIC_PICTURE
        raise_application_error(-20001, 'New PER_'|| aC_KEY_TYPE || ' = ' || cPrefix || to_char(nNumIncrement) || '. Max increment = ' || to_char(nNumIncrement -1) || ' reached. Change the picture. (PAC_PARTNER_MANAGEMENT(function NumAVS))');
      end if;

      return result;
    end NumAVS;
  -----
  begin
    begin
      select C_NUMEROTATION_TYPE
           , PIC_PICTURE
        into NumerotationTyp
           , Picture
        from ACS_PICTURE PIC
           , PAC_KEY_FORMAT key
       where key.C_KEY_TYPE = aC_KEY_TYPE
         and key.ACS_PICTURE_ID = PIC.ACS_PICTURE_ID;
    exception
      when others then
        Ok  := false;
    end;

    if Ok then
      if NumerotationTyp = '2' then   -- Numérotation automatique
        result  := NumAuto(Picture, aC_KEY_TYPE);
      elsif NumerotationTyp = '3' then   -- Numérotation selon table AVS
        result  := NumAVS(aPER_SHORT_NAME, Picture, aC_KEY_TYPE);
      else
        result  := '';
      end if;
    end if;

    return result;
  end ExtractKey;

  /**
  * Description
  *    Fonction de recherche des 'communications' d'une personne / adresse
  */
  function GET_ADDRESS_COMMUNICATION(pPer_Adr_Id number, pIdType number, pComType number, pReturnComField number)
    return varchar2
  is
    vResult              varchar2(60);                          /* taille correspondant à la taille max des champs susceptibles d'être retournés*/
                                         /* 2 curseurs différent pour PAC_PERSON_ID et PAC_ADDRESS_ID pour éviter le fullscan sur PAC_COMMUNICATION*/

    cursor SearchComByPerson(pPer_Adr_Id number, pIdType number, pComType number, pReturnComField number)
    is
      select   max(nvl(COM.A_DATEMOD, COM.A_DATECRE) ) RECENT
             , decode(pReturnComField
                    , 1, COM_EXT_NUMBER
                    , 2, COM_INT_NUMBER
                    , 3, COM_AREA_CODE
                    , 4, COM_INTERNATIONAL_NUMBER
                    , ''
                     ) COMFIELD
          from DIC_COMMUNICATION_TYPE DIC
             , PAC_COMMUNICATION COM
         where COM.PAC_PERSON_ID = pPer_Adr_Id
           and DIC.DIC_COMMUNICATION_TYPE_ID = COM.DIC_COMMUNICATION_TYPE_ID
           and decode(pComType, 1, DCO_DEFAULT1, 2, DCO_DEFAULT2, 3, DCO_DEFAULT3, 4, DCO_EMAIL, 5, DCO_FAX) = 1
      group by decode(pReturnComField
                    , 1, COM_EXT_NUMBER
                    , 2, COM_INT_NUMBER
                    , 3, COM_AREA_CODE
                    , 4, COM_INTERNATIONAL_NUMBER
                    , ''
                     )
      order by RECENT desc;

    cursor SearchComByAddress(pPer_Adr_Id number, pIdType number, pComType number, pReturnComField number)
    is
      select   max(nvl(COM.A_DATEMOD, COM.A_DATECRE) ) RECENT
             , decode(pReturnComField
                    , 1, COM_EXT_NUMBER
                    , 2, COM_INT_NUMBER
                    , 3, COM_AREA_CODE
                    , 4, COM_INTERNATIONAL_NUMBER
                    , ''
                     ) COMFIELD
          from DIC_COMMUNICATION_TYPE DIC
             , PAC_COMMUNICATION COM
         where COM.PAC_ADDRESS_ID = pPer_Adr_Id
           and DIC.DIC_COMMUNICATION_TYPE_ID = COM.DIC_COMMUNICATION_TYPE_ID
           and decode(pComType, 1, DCO_DEFAULT1, 2, DCO_DEFAULT2, 3, DCO_DEFAULT3, 4, DCO_EMAIL, 5, DCO_FAX) = 1
      group by decode(pReturnComField
                    , 1, COM_EXT_NUMBER
                    , 2, COM_INT_NUMBER
                    , 3, COM_AREA_CODE
                    , 4, COM_INTERNATIONAL_NUMBER
                    , ''
                     )
      order by RECENT desc;

    PersonCommunication  SearchComByPerson%rowtype;
    AddressCommunication SearchComByAddress%rowtype;
  begin
    if pIdType = 1 then   /*Type d'id = PAC_PERSON_ID*/
      open SearchComByPerson(pPer_Adr_Id, pIdType, pComType, pReturnComField);

      fetch SearchComByPerson
       into PersonCommunication;

      if SearchComByPerson%found then
        vResult  := PersonCommunication.COMFIELD;
      end if;

      close SearchComByPerson;
    elsif pIdType = 2 then   /*Type d'id = PAC_ADDRESS_ID*/
      open SearchComByAddress(pPer_Adr_Id, pIdType, pComType, pReturnComField);

      fetch SearchComByAddress
       into AddressCommunication;

      if SearchComByAddress%found then
        vResult  := AddressCommunication.COMFIELD;
      end if;

      close SearchComByAddress;
    end if;

    return rtrim(ltrim(vResult) );
  end GET_ADDRESS_COMMUNICATION;

  /**
  * Description
  *    Fonction de recherche de l'association selon personne et contact
  */
  function GetAssociationId(pPersonId PAC_PERSON.PAC_PERSON_ID%type, pContactId PAC_PERSON.PAC_PERSON_ID%type)
    return PAC_PERSON_ASSOCIATION.PAC_PERSON_ASSOCIATION_ID%type
  is
    vAssociationId PAC_PERSON_ASSOCIATION.PAC_PERSON_ASSOCIATION_ID%type;
  begin
    begin
      select PAC_PERSON_ASSOCIATION_ID
        into vAssociationId
        from PAC_PERSON_ASSOCIATION
       where PAC_PERSON_ID = pPersonId
         and PAC_PAC_PERSON_ID = pContactId
         and rownum = 1;
    exception
      when no_data_found then
        vAssociationId  := null;
    end;

    return vAssociationId;
  end;

  /**
  * Description
  *    Fonction de recherche du contact en fonction de l'association
  */
  function GetContactId(pAssociationId PAC_PERSON_ASSOCIATION.PAC_PERSON_ASSOCIATION_ID%type)
    return PAC_PERSON_ASSOCIATION.PAC_PAC_PERSON_ID%type
  is
    vContactId PAC_PERSON_ASSOCIATION.PAC_PAC_PERSON_ID%type;
  begin
    select PAC_PAC_PERSON_ID
      into vContactId
      from PAC_PERSON_ASSOCIATION
     where PAC_PERSON_ASSOCIATION_ID = pAssociationId;

    return vContactId;
  exception
    when others then
      return null;
  end;

  /**
  * Description Recherche des ids des partners selon le sub set pour la MAJ du coefficient de payment
  */
  procedure InitFactorPayment(
    pSubSetId  ACS_SUB_SET.ACS_SUB_SET_ID%type
  , pDaysNbr   ACR_CF_DATE_WEIGHTING.CFW_DAYS_NUMBER%type
  , pChkAmount ACR_CF_DATE_WEIGHTING.CFW_INVOICE_AMOUNT%type
  )
  is
    cursor SearchCusPartnerID(pSubSetId number)
    is
      select CUS.PAC_CUSTOM_PARTNER_ID
        from PAC_CUSTOM_PARTNER CUS
           , ACS_AUXILIARY_ACCOUNT AUX
           , ACS_ACCOUNT ACC
       where ACC.ACS_SUB_SET_ID = pSubSetId
         and ACC.ACS_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
         and AUX.ACS_AUXILIARY_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID;

    cursor SearchSupPartnerID(pSubSetId number)
    is
      select SUP.PAC_SUPPLIER_PARTNER_ID
        from PAC_SUPPLIER_PARTNER SUP
           , ACS_AUXILIARY_ACCOUNT AUX
           , ACS_ACCOUNT ACC
       where ACC.ACS_SUB_SET_ID = pSubSetId
         and ACC.ACS_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
         and AUX.ACS_AUXILIARY_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID;

    CusPartnerID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
    SupPartnerID PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    SubSetTyp    ACS_SUB_SET.C_SUB_SET%type;
    vFactor      number;
  begin
    --Détermine si c'est un client ou un fournisseur
    SubSetTyp  := acs_function.GetSubSetOfSubSet(pSubSetId);

    if SubSetTyp = 'PAY' then
      --Recherche des IDs pour le fournisseur
      open SearchSupPartnerID(pSubSetId);

      fetch SearchSupPartnerID
       into SupPartnerID;

      while SearchSupPartnerID%found loop
        --Mise à jour du coefficient du fournisseur
        vFactor  := ACR_CASH_FLOW_MANAGEMENT.PartnerPaymentFactor(SupPartnerID, 'S', pDaysNbr, pChkAmount);

        begin
          UpdFactorPayment(SupPartnerID, vFactor, 'S');
        exception
          when others then
            --Il arrive que le coefficient soit plus grand que number 6,2, le forcer 999.99
            UpdFactorPayment(SupPartnerID, 999.99, 'S');
        end;

        fetch SearchSupPartnerID
         into SupPartnerID;
      end loop;

      close SearchSupPartnerID;
    elsif SubSetTyp = 'REC' then
      --Recherche des IDs pour le client
      open SearchCusPartnerID(pSubSetId);

      fetch SearchCusPartnerID
       into CusPartnerID;

      while SearchCusPartnerID%found loop
        --Mise à jour du coefficient du client
        vFactor  := ACR_CASH_FLOW_MANAGEMENT.PartnerPaymentFactor(CusPartnerID, 'C', pDaysNbr, pChkAmount);

        begin
          UpdFactorPayment(CusPartnerID, vFactor, 'C');
        exception
          when others then
            --Il arrive que le coefficient soit plus grand que number 6,2, le forcer 999.99
            UpdFactorPayment(CusPartnerID, 999.99, 'C');
        end;

        fetch SearchCusPartnerID
         into CusPartnerID;
      end loop;

      close SearchCusPartnerID;
    end if;
  end InitFactorPayment;

  /**
  * Description MAJ du calcul du coefficient
  */
  procedure UpdFactorPayment(
    pPartnerId  PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , pNewFactor  PAC_CUSTOM_PARTNER.CUS_PAYMENT_FACTOR%type
  , pPartnerTyp varchar2
  )
  is
  begin
    if pPartnerTyp = 'C' then
      update PAC_CUSTOM_PARTNER
         set CUS_PAYMENT_FACTOR = decode(pNewFactor, 0, 1, pNewFactor)
           , CUS_PAYMENT_FACTOR_DATE = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where PAC_CUSTOM_PARTNER_ID = pPartnerId;
    else
      update PAC_SUPPLIER_PARTNER
         set CRE_PAYMENT_FACTOR = decode(pNewFactor, 0, 1, pNewFactor)
           , CRE_PAYMENT_FACTOR_DATE = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where PAC_SUPPLIER_PARTNER_ID = pPartnerId;
    end if;
  end UpdFactorPayment;

  /**
  * Description Recherche du montant total ouvert d'un compte auxilaire / d'un partenaire
  */
  function GetSumOfExpiries(
    pAuxAccountId  ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , pLocalCurrency number
  , pPersonId      PAC_PERSON.PAC_PERSON_ID%type default null
  , pFinCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type default null
  , pForceInitAccounts integer default 0
  )
    return ACT_EXPIRY.EXP_AMOUNT_LC%type
  is
    vResult        ACT_EXPIRY.EXP_AMOUNT_LC%type;
    vLocalCurrency number(1);
    vFinCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vAccNumber     ACS_ACCOUNT.ACC_NUMBER%type;
  begin
    if    (pForceInitAccounts = 1)
       or (ACT_FUNCTIONS.ANALYSE_AUXILIARY1 is null)
       or (ACT_FUNCTIONS.ANALYSE_AUXILIARY2 is null) then
      select nvl(max(ACC_NUMBER), '0')
        into vAccNumber
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID = pAuxAccountId;

      ACT_FUNCTIONS.ANALYSE_AUXILIARY1  := vAccNumber;
      ACT_FUNCTIONS.ANALYSE_AUXILIARY2  := vAccNumber;
    end if;

    --initialisation de la monnaie + du choix MB/ME
    if pFinCurrencyId is null then
      --Recherche du montant
      if pPersonId is null then
        select nvl(sum(nvl(EXP_AMOUNT_LC, 0) ) - sum(nvl(DET_PAIED_LC, 0) ), 0)
          into vResult
          from V_ACT_EXPIRY_THIRD_STATUS
         where ACS_AUXILIARY_ACCOUNT_ID = pAuxAccountId;
      else
        select nvl(sum(nvl(EXP_AMOUNT_LC, 0) ) - sum(nvl(DET_PAIED_LC, 0) ), 0)
          into vResult
          from V_ACT_EXPIRY_THIRD_STATUS
         where ACS_AUXILIARY_ACCOUNT_ID = pAuxAccountId
           and PAC_PERSON_ID + 0 = pPersonId;
      end if;
    else
      if pFinCurrencyId = ACS_FUNCTION.GetLocalCurrencyID then
        vFinCurrencyId  := pFinCurrencyId;
        vLocalCurrency  := 1;
      else
        vFinCurrencyId  := pFinCurrencyId;
        vLocalCurrency  := pLocalCurrency;
      end if;

      --Recherche du montant
      if pPersonId is null then
        select nvl(decode(vLocalCurrency
                        , 1, sum(nvl(EXP_AMOUNT_LC, 0) ) - sum(nvl(DET_PAIED_LC, 0) )
                        , sum(nvl(EXP_AMOUNT_FC, 0) ) - sum(nvl(DET_PAIED_FC, 0) )
                         )
                 , 0
                  )
          into vResult
          from V_ACT_EXPIRY_THIRD_STATUS
         where ACS_AUXILIARY_ACCOUNT_ID = pAuxAccountId
           and ACS_FINANCIAL_CURRENCY_ID = vFinCurrencyId;
      else
        select nvl(decode(vLocalCurrency
                        , 1, sum(nvl(EXP_AMOUNT_LC, 0) ) - sum(nvl(DET_PAIED_LC, 0) )
                        , sum(nvl(EXP_AMOUNT_FC, 0) ) - sum(nvl(DET_PAIED_FC, 0) )
                         )
                 , 0
                  )
          into vResult
          from V_ACT_EXPIRY_THIRD_STATUS
         where ACS_AUXILIARY_ACCOUNT_ID = pAuxAccountId
           and PAC_PERSON_ID + 0 = pPersonId
           and ACS_FINANCIAL_CURRENCY_ID = vFinCurrencyId;
      end if;
    end if;

    return vResult;
  end GetSumOfExpiries;

  function GetCntryCode(pCntryId PAC_FINANCIAL_REFERENCE.PC_CNTRY_ID%type)
    return PCS.PC_CNTRY.CNTID%type
  is
    vResult PCS.PC_CNTRY.CNTID%type;
  begin
    select max(CNTID)
      into vResult
      from PCS.PC_CNTRY
     where PC_CNTRY_ID = pCntryId;

    return vResult;
  end GetCntryCode;

  /**
  * Description
  *  Fonction de contrôle de la validité d'un n° de compte selon le code international selon pays
  **/
  function CheckRefESNumber(pRefNumber varchar2)
    return integer
  is
    vResult        integer;
    vRefNumber     varchar2(20);
    vBankCode      varchar2(4);
    vBranchCode    varchar2(4);
    vBankCodeDigit varchar2(1);
    vAccountDigit  varchar2(1);
    vAccountNumber varchar2(10);
  begin
    vResult     := 0;
    vRefNumber  := trim(pRefNumber);

    if length(vRefNumber) = 20 then
      vBankCode       := substr(vRefNumber, 1, 4);   --Code banque
      vBranchCode     := substr(vRefNumber, 5, 4);   --Code succursale
      vBankCodeDigit  := substr(vRefNumber, 9, 1);   --Digit de contôle du code banque
      vAccountDigit   := substr(vRefNumber, 10, 1);   --Digit de contôle du compte
      vAccountNumber  := substr(vRefNumber, 11, 10);   --Numéro de compte

      --Test de l'égalité entre les digits de contôle donnés et calculés
      if     (GetRefESCheckDigit('00' || vBankCode || vBranchCode) = vBankCodeDigit)
         and (GetRefESCheckDigit(vAccountNumber) = vAccountDigit) then
        vResult  := 1;
      end if;
    end if;

    return vResult;
  end CheckRefESNumber;

  /**
  * Description
  *  Retour du nombre de contrôle des compte espagnole
  **/
  function GetRefESCheckDigit(pRefNumber varchar2)
    return integer
  is
    type TWeight is varray(10) of integer;

    vWeight    TWeight := TWeight(1, 2, 4, 8, 5, 10, 9, 7, 3, 6);
    vRefNumber number;
    vNumberSum number;
    vIndex     integer;
  begin
    vIndex      := 1;
    vNumberSum  := 0;

    while vIndex <= length(pRefNumber) loop
      vRefNumber  := 0;

      begin
        vRefNumber  := to_number(substr(pRefNumber, vIndex, 1) );
      exception
        when others then
          null;
      end;

      vNumberSum  := vNumberSum +(vWeight(vIndex) * vRefNumber);
      vIndex      := vIndex + 1;
    end loop;

    vNumberSum  := 11 - mod(vNumberSum, 11);
    return vNumberSum;
  end GetRefESCheckDigit;

  /**
  * Description
  *  Retour du nombre de contrôle selon gestion du type de référence 6  (international selon pays)
  **/
  function GetTyp6CheckDigit(pRefNumber varchar2, pCntryId PAC_FINANCIAL_REFERENCE.PC_CNTRY_ID%type)
    return integer
  is
  begin
    case GetCntryCode(pCntryId)
      when 'ES' then
        return GetRefESCheckDigit(pRefNumber);
      else
        return 2;
    end case;
  end GetTyp6CheckDigit;

  /**
  * Description
  *  Fonction de contrôle de la validité d'un n° de compte selon le code international selon pays
  **/
  function CheckTyp6Number(pRefNumber varchar2, pCntryId PAC_FINANCIAL_REFERENCE.PC_CNTRY_ID%type)
    return integer
  is
  begin
    case GetCntryCode(pCntryId)
      when 'ES' then
        return CheckRefESNumber(pRefNumber);
      else
        return 2;
    end case;
  end CheckTyp6Number;

  function HollerithCode(pAccountNumber varchar2)
    return varchar2
  is
    source     varchar2(26) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    translated varchar2(26) := '12345678912345678923456789';
  begin
    return translate(pAccountNumber, source, translated);
  end HollerithCode;

  function GetRIBCheckDigit(pRefNumber varchar2)
    return varchar2
  is
  begin
    return lpad(to_char(97 - mod(HollerithCode(upper(pRefNumber) ) * 100, 97) ), 2, '0');
  end GetRIBCheckDigit;

  function CheckRIBNumber(pRefNumber varchar2)
    return integer
  is
  begin
    if GetRIBCheckDigit(substr(pRefNumber, 1, length(pRefNumber) - 2) ) = substr(pRefNumber, -2) then
      return 1;
    else
      return 0;
    end if;
  end CheckRIBNumber;

  function CheckIBANNumber(pRefNumber varchar2)
    return integer
  is
    tmpRefNumber varchar2(100);   -- max 66
    c            integer;
    i            integer;
  begin
    -- Déplacement CP et CC à la fin
    tmpRefNumber  := substr(pRefNumber, 5) || substr(pRefNumber, 1, 4);
    i             := 1;

    while i <= length(tmpRefNumber) loop
      c  := ascii(substr(tmpRefNumber, i, 1) );

      if     c > 47
         and c < 58 then
        -- Numériques -> OK
        i  := i + 1;
      elsif     c > 64
            and c < 91 then
        -- Caractères A à Z -> transformation en nombre (10 à 35)
        tmpRefNumber  := substr(tmpRefNumber, 1, i - 1) || to_char(c - 55) || substr(tmpRefNumber, i + 1);
        i             := i + 2;
      else
        -- Caractère interdit -> IBAN faux
        return 0;
      end if;
    end loop;

    if mod(tmpRefNumber, 97) = 1 then
      return 1;
    else
      return 0;
    end if;
  end CheckIBANNumber;

  function CheckFinRefNumber(
    pRefNumber        in varchar2
  , pC_TYPE_REFERENCE in PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type
  , pCntryId          in PAC_FINANCIAL_REFERENCE.PC_CNTRY_ID%type
  )
    return integer
  is
  begin
    if pC_TYPE_REFERENCE = '4' then
      return CheckRIBNumber(pRefNumber);
    elsif pC_TYPE_REFERENCE = '5' then
      return CheckIBANNumber(pRefNumber);
    elsif pC_TYPE_REFERENCE = '6' then
      return CheckTyp6Number(pRefNumber, pCntryId);
    else
      return 2;   -- Type pas supporté
    end if;
  end CheckFinRefNumber;

  /**
  * Description
  *  Fonction de mise à jour du statut de la personne ou du partenaire client / fournisseur
  **/
  procedure SetPartnerStatus(
    pPacPersonId          PAC_PERSON.PAC_PERSON_ID%type
  , pPartnerType          varchar2
  , pPartnerStatus        PAC_PERSON.C_PARTNER_STATUS%type
  , pConfirmUpdate in out integer
  )
  is
    /*Curseur de recherche des partenaires clients et fournisseur*/
    cursor CustomerAndSupplierCursor
    is
      select decode(CUS.PAC_CUSTOM_PARTNER_ID, null, 0, 1) ISCUSTOMER
           , decode(SUP.PAC_SUPPLIER_PARTNER_ID, null, 0, 1) ISSUPPLIER
           , PER.C_PARTNER_STATUS
           , CUS.C_PARTNER_STATUS
           , SUP.C_PARTNER_STATUS
           , decode(pPartnerType, 'P', pPartnerStatus, PER.C_PARTNER_STATUS)
           , decode(pPartnerType, 'C', pPartnerStatus, CUS.C_PARTNER_STATUS)
           , decode(pPartnerType, 'S', pPartnerStatus, SUP.C_PARTNER_STATUS)
        from PAC_SUPPLIER_PARTNER SUP
           , PAC_CUSTOM_PARTNER CUS
           , PAC_PERSON PER
       where PER.PAC_PERSON_ID = pPacPersonId
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = PER.PAC_PERSON_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = PER.PAC_PERSON_ID;

    vSupplier       integer;
    vCustomer       integer;
    vPOldStatus     PAC_PERSON.C_PARTNER_STATUS%type;
    vCOldStatus     PAC_PERSON.C_PARTNER_STATUS%type;
    vSOldStatus     PAC_PERSON.C_PARTNER_STATUS%type;
    vPersonStatus   PAC_PERSON.C_PARTNER_STATUS%type;
    vCustomStatus   PAC_PERSON.C_PARTNER_STATUS%type;
    vSupplierStatus PAC_PERSON.C_PARTNER_STATUS%type;
    vResultStatus   PAC_PERSON.C_PARTNER_STATUS%type;
  begin
    /*Réception des données nécessaires dans les variables */
    open CustomerAndSupplierCursor;

    fetch CustomerAndSupplierCursor
     into vCustomer
        , vSupplier
        , vPOldStatus
        , vCOldStatus
        , vSOldStatus
        , vPersonStatus
        , vCustomStatus
        , vSupplierStatus;

    close CustomerAndSupplierCursor;

    if upper(pPartnerType) in('C', 'S') then   --Modification du statut client / fournisseur
      if     (vCustomer = 1)
         and (vSupplier = 1) then   --Si client et fournisseur
        if (vCustomStatus = vSupplierStatus) then   --Si 2 partenaires ont le même statut -> Statut commun
          vResultStatus  := vCustomStatus;
        elsif    (vCustomStatus = '1')
              or (vSupplierStatus = '1') then   --Si un des deux est à '1' -> '1'
          vResultStatus  := '1';
        else
          vResultStatus  := '2';   --Si aucun des deux n'est à '1' -> '2'
        end if;
      elsif(vCustomer = 1) then   --Si la personne est uniquement client ou fournisseur
        vResultStatus  := vCustomStatus;   --Statut de la personne = le statut client / fournisseur
      elsif(vSupplier = 1) then
        vResultStatus  := vSupplierStatus;
      end if;

      if pConfirmUpdate = 1 then
        update PAC_PERSON   --Mise à jour du statut de la personne
           set C_PARTNER_STATUS = vResultStatus
         where PAC_PERSON_ID = pPacPersonId;
      end if;

      if vPOldStatus <> vResultStatus then
        pConfirmUpdate  := 1;
      else
        pConfirmUpdate  := 0;
      end if;
    elsif upper(pPartnerType) = 'P' then   --Modification du statut personne
      if pConfirmUpdate = 1 then
        update PAC_CUSTOM_PARTNER   -- ===> Modification du statut du partenaire
           set C_PARTNER_STATUS = vPersonStatus   -- qui est égale à l'ancienne valeur du statut de la personne
         where PAC_CUSTOM_PARTNER_ID = pPacPersonId
           and C_PARTNER_STATUS = vPOldStatus;

        update PAC_SUPPLIER_PARTNER
           set C_PARTNER_STATUS = vPersonStatus
         where PAC_SUPPLIER_PARTNER_ID = pPacPersonId
           and C_PARTNER_STATUS = vPOldStatus;
      end if;

      if     (vPersonStatus <> vPOldStatus)
         and (    (     (vCustomer = 1)
                   and (vCustomStatus <> vPersonStatus) )
              or (     (vSupplier = 1)
                  and (vSupplierStatus <> vPersonStatus) )
             ) then
        pConfirmUpdate  := 1;
      else
        pConfirmUpdate  := 0;
      end if;
    end if;
  end SetPartnerStatus;

  function FormatAddress(aStrText in varchar2, aLine in number, aLength in number)
    return varchar2
  is
    type TtblLine is table of varchar2(4000)
      index by binary_integer;

    tblLine TtblLine;
    result  varchar2(4000);
    empty   integer;
    i       integer;
    cut     integer;
  begin
    -- Conversion TAB -> ESPACE
    result  := replace(aStrText, chr(9), ' ');
    -- Suppression chr(13)
    result  := replace(result, chr(13), chr(10) );
    -- Suppression double chr(10) (lignes vide)
    result  := replace(result, chr(10) || chr(10), chr(10) );

    -- Chargement d'une table contenant les lignes
    while tblLine.count <= aLine
     and result is not null loop
      if instr(result, chr(10) ) > 0 then
        tblLine(nvl(tblLine.last, 0) + 1) := trim(substr(result, 1, instr(result, chr(10), 1) - 1) );
        result                            := substr(result, instr(result, chr(10), 1) + 1);
      elsif result is not null then
        tblLine(nvl(tblLine.last, 0) + 1) := trim(result);
        result                            := null;
      end if;
    end loop;

    -- Nbre de ligne vide
    empty   := aLine - tblLine.count;
    result  := null;
    i       := tblLine.first;

    while i <= tblLine.last loop
      if     empty > 0
         and length(tblLine(i) ) > aLength then
        -- Si ligne trop grande et qu'il reste des lignes vide -> division de la ligne
        empty       := empty - 1;
        -- Recherche le point de coupure (expace ou virgule)
        cut         :=
          greatest(instr(tblLine(i), ' ', -(length(tblLine(i) ) - aLength) + 1)
                 , instr(tblLine(i), ',', -(length(tblLine(i) ) - aLength + 1) )
                  );

        -- Si le point de coupure et plus petit que la moitié de la ligne -> on prend la ligne entière
        if cut < aLength / 2 then
          cut  := aLength;
        end if;

        result      := result || rpad(substr(tblLine(i), 1, cut), aLength);
        tblLine(i)  := trim(substr(tblLine(i), cut + 1) );
      else
        result  := result || rpad(tblLine(i), aLength);
        i       := i + 1;
      end if;
    end loop;

    return rpad(nvl(result, ' '), aLine * aLength);
  end FormatAddress;
end;
