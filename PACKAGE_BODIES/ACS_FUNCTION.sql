--------------------------------------------------------
--  DDL for Package Body ACS_FUNCTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_FUNCTION" 
is
  type ManagedPricesRecType is record(
    PCU_VAT_PRICE       boolean := true
  , PCU_INVOICE_PRICE   boolean := true
  , PCU_VALUATION_PRICE boolean := true
  , PCU_INVENTORY_PRICE boolean := true
  , PCU_CLOSING_PRICE   boolean := true
  , initialized         boolean := false
  );

  CACHED_MANAGEDPRICES   ManagedPricesRecType;
  vConstDivCode constant varchar2(20)         := 'ACS_AUTORIZED_DIV';

--La fonction GetAccountDescriptionSummary est appelée souvent, il est préférable de créer un cursor dans body
--pour ne pas devoir le créer lors de chaque appel de fonction
  cursor crDescrAccount(pACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
  is
    select DES_DESCRIPTION_SUMMARY
      from ACS_DESCRIPTION
     where ACS_ACCOUNT_ID = pACS_ACCOUNT_ID
       and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
       and rownum = 1;

  procedure InitManagedPrices
  is
    vConfig   PCS.PC_CBASE.CBACVALUE%type;
    vCurValue PCS.PC_CBASE.CBACVALUE%type;
    vIndex    integer;
    vPos      integer;

    procedure UpdateManagedPrices(aIndex integer, aValue boolean)
    is
    begin
      if aIndex = 1 then
        CACHED_MANAGEDPRICES.PCU_VAT_PRICE  := aValue;
      elsif aIndex = 2 then
        CACHED_MANAGEDPRICES.PCU_INVOICE_PRICE  := aValue;
      elsif aIndex = 3 then
        CACHED_MANAGEDPRICES.PCU_VALUATION_PRICE  := aValue;
      elsif aIndex = 4 then
        CACHED_MANAGEDPRICES.PCU_INVENTORY_PRICE  := aValue;
      elsif aIndex = 5 then
        CACHED_MANAGEDPRICES.PCU_CLOSING_PRICE  := aValue;
      end if;
    end;
  begin
    for vIndex in 1 .. 5 loop
      UpdateManagedPrices(vIndex, true);
    end loop;

    CACHED_MANAGEDPRICES.initialized  := true;
    vConfig                           := PCS.PC_CONFIG.GetConfig('ACS_EXCHANGE_RATE');

    if not vConfig is null then
      vIndex  := 0;
      vPos    := 0;

      while length(vConfig) > vPos loop
        if substr(vConfig, vPos, 1) = ',' then
          vIndex     := vIndex + 1;
          vCurValue  := trim(substr(vConfig, 1, vPos - 1) );
          vConfig    := substr(vConfig, vPos + 1);
          vPos       := 0;
        else
          vPos  := vPos + 1;
        end if;

        UpdateManagedPrices(vIndex, vCurValue != '0');
      end loop;

      if not trim(vConfig) is null then
        vIndex     := vIndex + 1;
        vCurValue  := trim(vConfig);
        UpdateManagedPrices(vIndex, vCurValue != '0');
      end if;
    end if;
  end InitManagedPrices;

  /**
  * Description
  *    Renvoie C_SUB_SET sur la base de l'ID du sous-ensemble
  */
  function GetSubSetOfSubSet(aACS_SUB_SET_ID ACS_SUB_SET.ACS_SUB_SET_ID%type)
    return ACS_SUB_SET.C_SUB_SET%type
  is
    SubSet ACS_SUB_SET.C_SUB_SET%type;
  begin
    select max(C_SUB_SET)
      into SubSet
      from ACS_SUB_SET
     where ACS_SUB_SET_ID = aACS_SUB_SET_ID;

    return SubSet;
  end GetSubSetOfSubSet;

  /**
  * Description
  *   Renvoie C_SUB_SET sur la base de l'ID d'un compte
  */
  function GetSubSetOfAccount(aACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
    return ACS_SUB_SET.C_SUB_SET%type
  is
    SubSet ACS_SUB_SET.C_SUB_SET%type;
  begin
    select max(C_SUB_SET)
      into SubSet
      from ACS_SUB_SET SUB
         , ACS_ACCOUNT ACC
     where SUB.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
       and ACC.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID;

    return SubSet;
  end GetSubSetOfAccount;

  /**
  * Description
  *   Renvoie ACS_SUB_SET_ID sur la base de l'ID d'un compte
  */
  function GetSubSetIdByAccount(pAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
    return ACS_SUB_SET.ACS_SUB_SET_ID%type
  is
    vSubSetId ACS_SUB_SET.ACS_SUB_SET_ID%type;
  begin
    begin
      select ACS_SUB_SET_ID
        into vSubSetId
        from ACS_ACCOUNT ACC
       where ACC.ACS_ACCOUNT_ID = pAccountId;
    exception
      when no_data_found then
        vSubSetId  := null;
    end;

    return vSubSetId;
  end GetSubSetIdByAccount;

---------------------------------------------------------------------------------------------------------------------
  function ExistDIVI
    return number
  is
    DivId  ACS_SUB_SET.ACS_SUB_SET_ID%type;
    result number;
  begin
    select max(ACS_SUB_SET_ID)
      into DivId
      from ACS_SUB_SET
     where C_TYPE_SUB_SET = 'DIVI';

    result  := 1;

    if DivId is null then
      result  := 0;
    end if;

    return result;
  end ExistDIVI;

  /**
  * Description
  *    Retourne un si il existe un sous ensemble du type donné
  */
  function ExistCSubSet(ivCSubSet ACS_SUB_SET.C_SUB_SET%type)
    return number
  is
    lnResult number;
  begin
    select case
             when max(ACS_SUB_SET_ID) is null then 0
             else 1
           end
      into lnResult
      from ACS_SUB_SET
     where C_SUB_SET = ivCSubSet;

    return lnResult;
  end ExistCSubSet;

  /**
  * Description
  *    Retourne l'Id de la division par défaut
  */
  function GetDefaultDivision
    return ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  is
    DivisionId ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
  begin
    select max(ACS_DIVISION_ACCOUNT_ID)
      into DivisionId
      from ACS_DIVISION_ACCOUNT
     where DIV_DEFAULT_ACCOUNT = 1;

    return DivisionId;
  end GetDefaultDivision;

  /**
  * Description
  *    Retourne l'Id de la première division
  */
  function GetFirstDivision
    return ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  is
    DivisionId ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
  begin
    select min(ACS_DIVISION_ACCOUNT_ID)
      into DivisionId
      from ACS_ACCOUNT
         , ACS_DIVISION_ACCOUNT
     where ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
       and ACC_NUMBER = (select min(ACC_NUMBER)
                           from ACS_ACCOUNT
                              , ACS_DIVISION_ACCOUNT
                          where ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID);

    return DivisionId;
  end GetFirstDivision;

  /**
  * Description
  *   Retourne l'Id de la division liée au compte financier
  */
  function GetDivisionOfFinAcc(aACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type)
    return ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  is
    DivisionId ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
  begin
    select max(ACS_DIVISION_ACCOUNT_ID)
      into DivisionId
      from ACS_INTERACTION
     where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
       and INT_PAIR_DEFAULT = 1;

    if DivisionId is null then
      select min(ACS_DIVISION_ACCOUNT_ID)
        into DivisionId
        from ACS_ACCOUNT
           , ACS_INTERACTION
       where ACS_INTERACTION.ACS_DIVISION_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
         and ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
         and ACS_ACCOUNT.ACC_NUMBER =
                           (select min(ACC_NUMBER)
                              from ACS_ACCOUNT
                                 , ACS_INTERACTION
                             where ACS_INTERACTION.ACS_DIVISION_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                               and ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID);
    end if;

    if DivisionId is null then
      DivisionId  := GetDefaultDivision;
    end if;

    if DivisionId is null then
      DivisionId  := GetFirstDivision;
    end if;

    return DivisionId;
  end GetDivisionOfFinAcc;

  /**
  * Description
  *    Test si une division est autorisée pour une date et un utilisateur donné
  */
  function IsDivisionAuthorized(
    aACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , aPC_USER_ID              PCS.PC_USER.PC_USER_ID%type default null
  , aDate                    date default null
  )
    return number
  is
    Cont       boolean                           := true;
    TestExists ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if     (aPC_USER_ID is not null)
       and (aPC_USER_ID != 0) then
      select max(AUTH.ACS_DIVISION_ACCOUNT_ID)
        into TestExists
        from ACS_AUTHORIZED_DIVISION_ACC AUTH
       where (   exists(select 0
                          from PCS.PC_USER_GROUP
                         where PC_USER_ID = aPC_USER_ID
                           and USE_GROUP_ID = AUTH.PC_USER_ID)
              or AUTH.PC_USER_ID = aPC_USER_ID);

      if TestExists is not null then
        select max(AUTH.ACS_DIVISION_ACCOUNT_ID)
          into TestExists
          from ACS_AUTHORIZED_DIVISION_ACC AUTH
         where AUTH.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID
           and (   exists(select 0
                            from PCS.PC_USER_GROUP
                           where PC_USER_ID = aPC_USER_ID
                             and USE_GROUP_ID = AUTH.PC_USER_ID)
                or AUTH.PC_USER_ID = aPC_USER_ID);

        Cont  := TestExists is not null;
      end if;
    end if;

    if     Cont
       and (aDate is not null) then
      select max(ACC.ACS_ACCOUNT_ID)
        into TestExists
        from ACS_ACCOUNT ACC
       where ACC.ACS_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID
         and ACC.ACC_BLOCKED = 0
         and (    (aDate between ACC.ACC_VALID_SINCE and ACC.ACC_VALID_TO)
              or (    ACC.ACC_VALID_TO is null
                  and ACC.ACC_VALID_SINCE is null)
              or (    ACC.ACC_VALID_SINCE is null
                  and aDate <= ACC.ACC_VALID_TO)
              or (    ACC.ACC_VALID_TO is null
                  and aDate >= ACC.ACC_VALID_SINCE)
             );

      Cont  :=(TestExists is not null);
    end if;

    if Cont then
      return 1;
    else
      return 0;
    end if;
  end IsDivisionAuthorized;

  /**
  * Description
  *    Retourne toutes les divisions autorisées pour une date et un utilisateur donné
  */
  function TableDivisionsAuthorized(aPC_USER_ID PCS.PC_USER.PC_USER_ID%type default null, aDate date default null)
    return ID_TABLE_TYPE
  is
    Cont       boolean                           := true;
    TestExists ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    result     ID_TABLE_TYPE;
  begin
    if     (aPC_USER_ID is not null)
       and (aPC_USER_ID != 0) then
      select max(AUTH.ACS_DIVISION_ACCOUNT_ID)
        into TestExists
        from ACS_AUTHORIZED_DIVISION_ACC AUTH
       where (   exists(select 0
                          from PCS.PC_USER_GROUP
                         where PC_USER_ID = aPC_USER_ID
                           and USE_GROUP_ID = AUTH.PC_USER_ID)
              or AUTH.PC_USER_ID = aPC_USER_ID);

      if TestExists is not null then
        if aDate is null then
          select cast(multiset(select AUTH.ACS_DIVISION_ACCOUNT_ID
                                 from ACS_ACCOUNT ACC
                                    , ACS_AUTHORIZED_DIVISION_ACC AUTH
                                where AUTH.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                  and (   exists(select 0
                                                   from PCS.PC_USER_GROUP
                                                  where PC_USER_ID = aPC_USER_ID
                                                    and USE_GROUP_ID = AUTH.PC_USER_ID)
                                       or AUTH.PC_USER_ID = aPC_USER_ID)
                              ) as ID_TABLE_TYPE
                     )
            into result
            from dual;

          Cont  := false;
        else
          select cast(multiset(select AUTH.ACS_DIVISION_ACCOUNT_ID
                                 from ACS_ACCOUNT ACC
                                    , ACS_AUTHORIZED_DIVISION_ACC AUTH
                                where AUTH.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                  and (   exists(select 0
                                                   from PCS.PC_USER_GROUP
                                                  where PC_USER_ID = aPC_USER_ID
                                                    and USE_GROUP_ID = AUTH.PC_USER_ID)
                                       or AUTH.PC_USER_ID = aPC_USER_ID)
                                  and ACC.ACC_BLOCKED = 0
                                  and (    (ADATE between ACC.ACC_VALID_SINCE and ACC.ACC_VALID_TO)
                                       or (    ACC.ACC_VALID_TO is null
                                           and ACC.ACC_VALID_SINCE is null)
                                       or (    ACC.ACC_VALID_SINCE is null
                                           and aDATE <= ACC.ACC_VALID_TO)
                                       or (    ACC.ACC_VALID_TO is null
                                           and aDATE >= ACC.ACC_VALID_SINCE)
                                      )
                              ) as ID_TABLE_TYPE
                     )
            into result
            from dual;

          Cont  := false;
        end if;
      end if;
    end if;

    if Cont then
      if aDate is null then
        select cast(multiset(select ACC.ACS_ACCOUNT_ID
                               from ACS_ACCOUNT ACC
                                  , ACS_DIVISION_ACCOUNT DIV
                              where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                and ACC.ACC_BLOCKED = 0) as ID_TABLE_TYPE)
          into result
          from dual;
      else
        select cast(multiset(select ACC.ACS_ACCOUNT_ID
                               from ACS_ACCOUNT ACC
                                  , ACS_DIVISION_ACCOUNT DIV
                              where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                and ACC.ACC_BLOCKED = 0
                                and (    (ADATE between ACC.ACC_VALID_SINCE and ACC.ACC_VALID_TO)
                                     or (    ACC.ACC_VALID_TO is null
                                         and ACC.ACC_VALID_SINCE is null)
                                     or (    ACC.ACC_VALID_SINCE is null
                                         and aDATE <= ACC.ACC_VALID_TO)
                                     or (    ACC.ACC_VALID_TO is null
                                         and aDATE >= ACC.ACC_VALID_SINCE)
                                    )
                            ) as ID_TABLE_TYPE
                   )
          into result
          from dual;
      end if;
    end if;

    return result;
  end TableDivisionsAuthorized;

  /**
  * Description
  *    Retourne toutes les divisions autorisées dans les formes d'impression pour un utilisateur donné
  */
  function TableAuthRptDivisions(aPC_USER_ID PCS.PC_USER.PC_USER_ID%type default null, lstdivisions varchar2 default null)
    return ID_TABLE_TYPE
  is
  begin
    return RPT_FUNCTIONS.TableAuthRptDivisions(aPC_USER_ID);
  end TableAuthRptDivisions;

  /**
  * Description
  *    Test si toutes les divisions d'un document sont autorisées pour une date et un utilisateur donné
  */
  function IsAllDivisionAuthorized4Doc(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type, aPC_USER_ID PCS.PC_USER.PC_USER_ID%type, aDate date default null)
    return number
  is
    cursor crDocDivisions(Document_id ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select distinct IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                 from ACT_FINANCIAL_IMPUTATION IMP
                where IMP.ACT_DOCUMENT_ID = Document_id;

    vl_ok number := 1;
  begin
    for tplDocDivisions in crDocDivisions(aACT_DOCUMENT_ID) loop
      select nvl(max(1), 0)
        into vl_ok
        from dual
       where tplDocDivisions.ACS_DIVISION_ACCOUNT_ID in(select *
                                                          from table(ACS_FUNCTION.TableDivisionsAuthorized(aPC_USER_ID, aDate) ) );

      exit when vl_ok = 0;
    end loop;

    return vl_ok;
  end IsAllDivisionAuthorized4Doc;

  /**
  * Description
  *    Retourne l'Id de la division pour un compte financier, à une date donnée
  */
  function GetDivisionOfAccount(
    aACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID  ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , aDate                     date
  , aPC_USER_ID               PCS.PC_USER.PC_USER_ID%type default null
  , aTryWithoutUser           number default 0
  , aTryFinallyMin            number default 1
  )
    return ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  is
    DivisionId       ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    ExistInteraction boolean;
  -----
  begin
    --Recherche existence interaction financière
    select max(ACS_DIVISION_ACCOUNT_ID)
      into DivisionId
      from ACS_INTERACTION
     where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    ExistInteraction  :=(DivisionId is not null);
    DivisionId        := null;

    if     (aACS_DIVISION_ACCOUNT_ID is not null)
       and (aACS_DIVISION_ACCOUNT_ID != 0) then
      if ExistInteraction then
        -- Recherche la division parmi les interactions du compte financier
        begin
          select ACS_DIVISION_ACCOUNT_ID
            into DivisionId
            from ACS_ACCOUNT ACC
               , ACS_INTERACTION int
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
             and ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID
             and (    (aDate between INT_VALID_SINCE and INT_VALID_TO)
                  or (    INT_VALID_TO is null
                      and INT_VALID_SINCE is null)
                  or (    INT_VALID_SINCE is null
                      and aDate <= INT_VALID_TO)
                  or (    INT_VALID_TO is null
                      and aDate >= INT_VALID_SINCE)
                 )
             and int.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
             and ACC.ACC_BLOCKED = 0
             and (    (aDate between ACC_VALID_SINCE and ACC_VALID_TO)
                  or (    ACC_VALID_TO is null
                      and ACC_VALID_SINCE is null)
                  or (    ACC_VALID_SINCE is null
                      and aDate <= ACC_VALID_TO)
                  or (    ACC_VALID_TO is null
                      and aDate >= ACC_VALID_SINCE)
                 )
             and int.ACS_DIVISION_ACCOUNT_ID in(select *
                                                  from table(ACS_FUNCTION.TableDivisionsAuthorized(aPC_USER_ID) ) );
        exception
          when no_data_found then
            DivisionId  := null;
        end;
      else
        -- Si pas d'interaction pour le compte financier, on teste la validité de la division passée en paramètre
        begin
          select ACS_ACCOUNT_ID
            into DivisionId
            from ACS_ACCOUNT
           where ACS_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID
             and ACC_BLOCKED = 0
             and (    (aDate between ACC_VALID_SINCE and ACC_VALID_TO)
                  or (    ACC_VALID_TO is null
                      and ACC_VALID_SINCE is null)
                  or (    ACC_VALID_SINCE is null
                      and aDate <= ACC_VALID_TO)
                  or (    ACC_VALID_TO is null
                      and aDate >= ACC_VALID_SINCE)
                 )
             and ACS_ACCOUNT_ID in(select *
                                     from table(ACS_FUNCTION.TableDivisionsAuthorized(aPC_USER_ID) ) );
        exception
          when no_data_found then
            DivisionId  := null;
        end;
      end if;
    end if;

    if     DivisionId is null
       and ExistInteraction then
      -- Recherche la division par défaut dans les interactions du compte financier
      begin
        select ACS_DIVISION_ACCOUNT_ID
          into DivisionId
          from ACS_ACCOUNT ACC
             , ACS_INTERACTION int
         where int.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
           and INT_PAIR_DEFAULT = 1
           and (    (aDate between INT_VALID_SINCE and INT_VALID_TO)
                or (    INT_VALID_TO is null
                    and INT_VALID_SINCE is null)
                or (    INT_VALID_SINCE is null
                    and aDate <= INT_VALID_TO)
                or (    INT_VALID_TO is null
                    and aDate >= INT_VALID_SINCE)
               )
           and int.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACC_BLOCKED = 0
           and (    (aDate between ACC_VALID_SINCE and ACC_VALID_TO)
                or (    ACC_VALID_TO is null
                    and ACC_VALID_SINCE is null)
                or (    ACC_VALID_SINCE is null
                    and aDate <= ACC_VALID_TO)
                or (    ACC_VALID_TO is null
                    and aDate >= ACC_VALID_SINCE)
               )
           and int.ACS_DIVISION_ACCOUNT_ID in(select *
                                                from table(ACS_FUNCTION.TableDivisionsAuthorized(aPC_USER_ID) ) );
      exception
        when no_data_found then
          DivisionId  := null;
        when too_many_rows then
          DivisionId  := null;
      end;
    end if;

    -- Recherche de la division par défaut valide
    if DivisionId is null then
      begin
        select ACS_DIVISION_ACCOUNT_ID
          into DivisionId
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV_DEFAULT_ACCOUNT = 1
           and DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC_BLOCKED = 0
           and (    (aDate between ACC_VALID_SINCE and ACC_VALID_TO)
                or (    ACC_VALID_TO is null
                    and ACC_VALID_SINCE is null)
                or (    ACC_VALID_SINCE is null
                    and aDate <= ACC_VALID_TO)
                or (    ACC_VALID_TO is null
                    and aDate >= ACC_VALID_SINCE)
               )
           and DIV.ACS_DIVISION_ACCOUNT_ID in(select *
                                                from table(ACS_FUNCTION.TableDivisionsAuthorized(aPC_USER_ID) ) );
      exception
        when no_data_found then
          DivisionId  := null;
        when too_many_rows then
          DivisionId  := null;
      end;

      if ExistInteraction then
        if DivisionId is not null then
          -- Test de la division par défaut parmi les interactions du compte financier
          begin
            select ACS_DIVISION_ACCOUNT_ID
              into DivisionId
              from ACS_INTERACTION
             where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
               and ACS_DIVISION_ACCOUNT_ID = DivisionId
               and (    (aDate between INT_VALID_SINCE and INT_VALID_TO)
                    or (    INT_VALID_TO is null
                        and INT_VALID_SINCE is null)
                    or (    INT_VALID_SINCE is null
                        and aDate <= INT_VALID_TO)
                    or (    INT_VALID_TO is null
                        and aDate >= INT_VALID_SINCE)
                   );
          exception
            when no_data_found then
              DivisionId  := null;
          end;
        end if;

        if     (DivisionId is null)
           and (aTryFinallyMin = 1) then
          -- Recherche de la plus petite division valide parmi les interactions du compte financier
          begin
            select ACS_DIVISION_ACCOUNT_ID
              into DivisionId
              from ACS_ACCOUNT ACC
                 , ACS_DIVISION_ACCOUNT DIV
             where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
               and ACC_NUMBER =
                     (select min(ACC_NUMBER)
                        from ACS_ACCOUNT ACC
                           , ACS_INTERACTION int
                       where int.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
                         and (    (aDate between INT_VALID_SINCE and INT_VALID_TO)
                              or (    INT_VALID_TO is null
                                  and INT_VALID_SINCE is null)
                              or (    INT_VALID_SINCE is null
                                  and aDate <= INT_VALID_TO)
                              or (    INT_VALID_TO is null
                                  and aDate >= INT_VALID_SINCE)
                             )
                         and int.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                         and ACC.ACC_BLOCKED = 0
                         and (    (aDate between ACC_VALID_SINCE and ACC_VALID_TO)
                              or (    ACC_VALID_TO is null
                                  and ACC_VALID_SINCE is null)
                              or (    ACC_VALID_SINCE is null
                                  and aDate <= ACC_VALID_TO)
                              or (    ACC_VALID_TO is null
                                  and aDate >= ACC_VALID_SINCE)
                             )
                         and int.ACS_DIVISION_ACCOUNT_ID in(select *
                                                              from table(ACS_FUNCTION.TableDivisionsAuthorized(aPC_USER_ID) ) ) );
          exception
            when no_data_found then
              DivisionId  := null;
          end;
        end if;
      end if;
    end if;

    -- Recherche de la plus petite division valide
    if     DivisionId is null
       and (not ExistInteraction)
       and (aTryFinallyMin = 1) then
      begin
        select ACS_DIVISION_ACCOUNT_ID
          into DivisionId
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC_NUMBER =
                 (select min(ACC_NUMBER)
                    from ACS_ACCOUNT ACC2
                       , ACS_DIVISION_ACCOUNT DIV2
                   where DIV2.ACS_DIVISION_ACCOUNT_ID = ACC2.ACS_ACCOUNT_ID
                     and ACC_BLOCKED = 0
                     and (    (aDate between ACC_VALID_SINCE and ACC_VALID_TO)
                          or (    ACC_VALID_TO is null
                              and ACC_VALID_SINCE is null)
                          or (    ACC_VALID_SINCE is null
                              and aDate <= ACC_VALID_TO)
                          or (    ACC_VALID_TO is null
                              and aDate >= ACC_VALID_SINCE)
                         )
                     and DIV2.ACS_DIVISION_ACCOUNT_ID in(select *
                                                           from table(ACS_FUNCTION.TableDivisionsAuthorized(aPC_USER_ID) ) ) );
      exception
        when no_data_found then
          DivisionId  := null;
      end;
    end if;

    if     (DivisionId is null)
       and (aPC_USER_ID is not null)
       and (aPC_USER_ID != 0)
       and (aTryWithoutUser != 0) then
      DivisionId  := GetDivisionOfAccount(aACS_FINANCIAL_ACCOUNT_ID, aACS_DIVISION_ACCOUNT_ID, aDate, null, 0, aTryFinallyMin);
    end if;

    return DivisionId;
  end GetDivisionOfAccount;

  /**
  * Description
  *    Renvoie l'ID de la monnaie Locale
  */
  function GetLocalCurrencyID
    return ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  is
    currency_id ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- recherche de l'id de la monnaie de base
    select max(ACS_FINANCIAL_CURRENCY_ID)
      into currency_id
      from ACS_FINANCIAL_CURRENCY
     where FIN_LOCAL_CURRENCY = 1;

    return currency_id;
  end GetLocalCurrencyID;

  /**
  * Description
  *    Renvoie le nom de la monnaie Locale
  */
  function GetLocalCurrencyName
    return varchar2
  is
    currency_name PCS.PC_CURR.CURRNAME%type;
  begin
    -- recherche de l'id de la monnaie de base
    select max(CURRENCY)
      into currency_name
      from ACS_FINANCIAL_CURRENCY
         , PCS.PC_CURR
     where FIN_LOCAL_CURRENCY = 1
       and PC_CURR.PC_CURR_ID = ACS_FINANCIAL_CURRENCY.PC_CURR_ID;

    return currency_name;
  end GetLocalCurrencyName;

  /**
  * Description
  *    Renvoie le nom de la monnaie Locale
  */
  function GetCurrencyName(currency_id in number)
    return varchar2
  is
    currency_name PCS.PC_CURR.CURRNAME%type;
  begin
    -- recherche de l'id de la monnaie de base
    select max(CURRENCY)
      into currency_name
      from ACS_FINANCIAL_CURRENCY
         , PCS.PC_CURR
     where ACS_FINANCIAL_CURRENCY_ID = currency_id
       and PC_CURR.PC_CURR_ID = ACS_FINANCIAL_CURRENCY.PC_CURR_ID;

    return currency_name;
  end GetCurrencyName;

  /**
  * Description
  *    Renvoie l'id d'une monnaie (ACS_FINANCIAL_CURRENCY) en fonction de son nom
  */
  function GetCurrencyId(iCurrency in PCS.PC_CURR.CURRNAME%type)
    return number
  is
    lCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- recherche de l'id de la monnaie de base
    select max(ACS_FINANCIAL_CURRENCY_ID)
      into lCurrencyId
      from ACS_FINANCIAL_CURRENCY
         , PCS.PC_CURR
     where CURRENCY = iCurrency
       and PC_CURR.PC_CURR_ID = ACS_FINANCIAL_CURRENCY.PC_CURR_ID;

    return lCurrencyId;
  end GetCurrencyId;

  /**
  * Description
  *   Renvoie l'id de la periode comptable correspondant a la date
  *   passee en parametre
  */
  function GetPeriodID(aDate in date, type_period in varchar2)
    return ACS_PERIOD.ACS_PERIOD_ID%type
  is
    idPeriod ACS_PERIOD.ACS_PERIOD_ID%type;
  begin
    -- Recherche de l'id de la periode qui correspond . la
    -- date et au type de p'riode pass's en paramStre.
    if type_period is null then
      select max(ACS_PERIOD_ID)
        into idPeriod
        from ACS_PERIOD
       where aDate between PER_START_DATE and PER_END_DATE;
    else
      select max(ACS_PERIOD_ID)
        into idPeriod
        from ACS_PERIOD
       where aDate between PER_START_DATE and PER_END_DATE
         and C_TYPE_PERIOD = type_period;
    end if;

    return idPeriod;
  end GetPeriodID;

  /**
  * Description
  *   Renvoie le numero de la periode comptable correspondant a la date
  *   passee en parametre
  */
  function GetPeriodNo(aDate in date, type_period in varchar2)
    return number
  is
    NoPeriod ACS_PERIOD.PER_NO_PERIOD%type;
  begin
    -- Recherche de l'id de la periode qui correspond a la
    -- date et au type de periode passe en parametre.
    if type_period is null then
      select max(PER_NO_PERIOD)
        into NoPeriod
        from ACS_PERIOD
       where aDate between PER_START_DATE and PER_END_DATE;
    else
      select max(PER_NO_PERIOD)
        into NoPeriod
        from ACS_PERIOD
       where aDate between PER_START_DATE and PER_END_DATE
         and C_TYPE_PERIOD = type_period;
    end if;

    return NoPeriod;
  end GetPeriodNo;

  /**
  * Description Renvoie le numero de la periode donnée
  **/
  function GetPerNumById(pPeriodId ACS_PERIOD.ACS_PERIOD_ID%type)
    return ACS_PERIOD.PER_NO_PERIOD%type
  is
    vPeriodNum ACS_PERIOD.PER_NO_PERIOD%type;
  begin
    select max(PER_NO_PERIOD)
      into vPeriodNum
      from ACS_PERIOD
     where ACS_PERIOD_ID = pPeriodId;

    return vPeriodNum;
  end GetPerNumById;

  /**
  * Description
  *   Renvoie le type de la période
  *   passee en parametre
  */
  function GetPeriodType(aPeriodId ACS_PERIOD.ACS_PERIOD_ID%type)
    return number
  is
    vType ACS_PERIOD.C_TYPE_PERIOD%type;
  begin
    select C_TYPE_PERIOD
      into vType
      from ACS_PERIOD
     where ACS_PERIOD_ID = aPeriodId;

    return vType;
  end GetPeriodType;

  /**
  * Description
  *   Renvoie l'id de l'annee financiere correspondant a la
  *   date passee en parametre
  */
  function GetFinancialYearID(aDate in date)
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
    idFinancialYear ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
  begin
    -- Recherche de l'id de l'annee comptable qui correspond a la
    -- date passee en parametre.
    select nvl(max(ACS_FINANCIAL_YEAR_ID), ACS_FUNCTION.GetMaxNoExerciceId)
      into idFinancialYear
      from ACS_FINANCIAL_YEAR
     where aDate between FYE_START_DATE and FYE_END_DATE;

    return idFinancialYear;
  end GetFinancialYearID;

  /**
  * Description
  *   Renvoie l'id de l'annee financiere comprenant la période
  *   passée en paramètre.
  */
  function GetFinYearByPeriod(aPeriodId number)
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
    result ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
  begin
    select ACS_FINANCIAL_YEAR_ID
      into result
      from ACS_PERIOD
     where ACS_PERIOD_ID = aPeriodId;

    return result;
  end GetFinYearByPeriod;

  /**
  * Description
  *   Renvoie le numero de l'annee financiere correspondant a la
  *   date passee en parametre
  */
  function GetFinancialYearNo(aDate in date)
    return number
  is
    NoFinancialYear ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;
  begin
    -- Recherche de l'id de l'annee comptable qui correspond a la
    -- date passee en parametre.
    select max(FYE_NO_EXERCICE)
      into NoFinancialYear
      from ACS_FINANCIAL_YEAR
     where aDate between FYE_START_DATE and FYE_END_DATE;

    return NoFinancialYear;
  end GetFinancialYearNo;

  /**
  * Description
  *   Renvoie la date début ou fin de l'exercice donné
  **/
  function GetFinancialYearDate(pExerciceId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type, pType number)
    return ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  is
    vDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
  begin
    select decode(pType, 0, FYE_START_DATE, 1, FYE_END_DATE)
      into vDate
      from ACS_FINANCIAL_YEAR
     where ACS_FINANCIAL_YEAR_ID = pExerciceId;

    return vDate;
  end GetFinancialYearDate;

  /**
  * Description
  *   Fonction permettant de faire un arrondi d'après un montant d'arrondi
  *   l'arrondi commercial se fait en passant 0.05 comme montant d'arrondi
  */
  function RoundNear(aValue in number, aRound in number, aMode in number default 0)
    return number
  is
    Divide1 number;
    Divide2 number;
    tmpVal  number;
  begin
    tmpVal  := round(aValue);

    if aRound > 0 then
      Divide1  := aValue / aRound;
      Divide2  := round(Divide1);

      if aMode = 0 then
        tmpVal  := Divide2 * aRound;
      else
        if aMode = -1 then
          if Divide2 - Divide1 <= 0 then
            tmpVal  := Divide2 * aRound;
          else
            tmpVal  := (Divide2 - 1) * aRound;
          end if;
        else
          if aMode = 1 then
            if Divide2 - Divide1 < 0 then
              tmpVal  := (Divide2 + 1) * aRound;
            else
              tmpVal  := Divide2 * aRound;
            end if;
          else
            tmpVal  := Divide2 * aRound;
          end if;
        end if;
      end if;
    end if;

    return tmpVal;
  end RoundNear;

  /**
  * Description
  *       Fonction permettant de faire un arrondi d'après le descodes C_ROUND_TYPE
   */
  function PcsRound(aValue in number, aRoundType in varchar2 default '0', aRoundAmount in number default 0)
    return number
  is
  begin
    -- pas d'arrondi
    if    aRoundType = '0'
       or aRoundType is null then
      return aValue;
    -- arrondi commercial
    elsif aRoundType = '1' then
      return RoundNear(aValue, 0.05);
    -- arrondi inférieur
    elsif aRoundType = '2' then
      return RoundNear(aValue, aRoundAmount, -1);
    -- arrondi au plus près
    elsif aRoundType = '3' then
      return RoundNear(aValue, aRoundAmount, 0);
    -- arrondi supérieur
    elsif aRoundType = '4' then
      return RoundNear(aValue, aRoundAmount, 1);
    end if;
  end PcsRound;

---------------------
  function SoldeAccount(FinYear_id number, FinAccount_id number)
    return number
  is
    Solde       number default 0;
    aFinYear_id number;

    cursor TotalByPeriod(FinYear_id number, FinAccount_id number)
    is
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC) SOLDE
        from ACT_TOTAL_BY_PERIOD
           , ACS_PERIOD
       where ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID = ACS_PERIOD.ACS_PERIOD_ID
         and ACT_TOTAL_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID is null
         and ACT_TOTAL_BY_PERIOD.ACS_AUXILIARY_ACCOUNT_ID is null
         and ACS_FINANCIAL_ACCOUNT_ID = FinAccount_id
         and ACS_FINANCIAL_YEAR_ID = FinYear_id;
  begin
    aFinYear_id  := FinYear_id;

    if aFinYear_id = 0 then
      aFinYear_id  := GetMaxNoExerciceId;
    end if;

    open TotalByPeriod(aFinYear_id, FinAccount_id);

    fetch TotalByPeriod
     into Solde;

    if Solde is null then
      Solde  := 0;
    end if;

    close TotalByPeriod;

    return Solde;
  end SoldeAccount;

------------------------
  function SoldeDivAccount(
    aACS_FINANCIAL_YEAR_ID    ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
    Solde             ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type           default 0;
    FinancialYearId   ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    DivisionAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;

    cursor TotalByPeriod(
      aACS_FINANCIAL_YEAR_ID    ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
    , aACS_FINANCIAL_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type
    , aACS_DIVISION_ACCOUNT_ID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type
    )
    is
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC) SOLDE
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
         and (    (    aACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null)
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
             );
  begin
    FinancialYearId    := aACS_FINANCIAL_YEAR_ID;

    if    FinancialYearId is null
       or FinancialYearId = 0 then
      FinancialYearId  := GetMaxNoExerciceId;
    end if;

    DivisionAccountId  := aACS_DIVISION_ACCOUNT_ID;

    if aACS_DIVISION_ACCOUNT_ID = 0 then
      DivisionAccountId  := null;
    end if;

    open TotalByPeriod(FinancialYearId, aACS_FINANCIAL_ACCOUNT_ID, DivisionAccountId);

    fetch TotalByPeriod
     into Solde;

    if Solde is null then
      Solde  := 0;
    end if;

    return Solde;

    close TotalByPeriod;
  end SoldeDivAccount;

  /**
  * Description
  *    Retourne le solde d'un compte auxiliaire dans le cadre d'un exercice comptable
  */
  function SoldeAuxAccount(
    aACS_FINANCIAL_YEAR_ID    ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
    Solde       ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    aFinYear_id ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
  begin
    aFinYear_id  := aACS_FINANCIAL_YEAR_ID;

    if aFinYear_id = 0 then
      aFinYear_id  := GetMaxNoExerciceId;
    end if;

    select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
      into Solde
      from ACT_TOTAL_BY_PERIOD TOT
         , ACS_PERIOD PER
     where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and TOT.ACS_DIVISION_ACCOUNT_ID is null
       and TOT.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
       and PER.ACS_FINANCIAL_YEAR_ID = aFinYear_id;

    if Solde is null then
      Solde  := 0;
    end if;

    return Solde;
  end SoldeAuxAccount;

  /**
  * Description
  *    Retourne le solde des comptes auxiliaires présent dans la table temporaire pour un exercice comptable
  */
  function SoldeAuxAccountTblTemp(
    aACS_FINANCIAL_YEAR_ID     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aC_SUB_SET                 ACS_SUB_SET.C_SUB_SET%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aC_TYPE_CUMUL1             ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aC_TYPE_CUMUL2             ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aC_TYPE_CUMUL3             ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aC_TYPE_CUMUL4             ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aRightsMgm                 number
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
    vSolde ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    vIsMB  signtype                                default 0;
    vCoeff signtype;
  begin
    if aACS_FINANCIAL_CURRENCY_ID = 0 then
      vIsMB  := 1;
    else
      select case
               when(aACS_FINANCIAL_CURRENCY_ID = ACS_FINANCIAL_CURRENCY_ID) then 1
               else 0
             end
        into vIsMB
        from ACS_FINANCIAL_CURRENCY
       where FIN_LOCAL_CURRENCY = 1;
    end if;

    if aC_SUB_SET = 'PAY' then
      vCoeff  := -1;
    else
      vCoeff  := 1;
    end if;

    if aRightsMgm > 0 then
      select case
               when vIsMB > 0 then sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
               else sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
             end * vCoeff
        into vSolde
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
           , COM_LIST_ID_TEMP TMP
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and nvl(TOT.ACS_DIVISION_ACCOUNT_ID, 0) in(select column_value
                                                      from table(ACS_FUNCTION.TableDivisionsAuthorized(PCS.PC_I_LIB_SESSION.GETUSERID, sysdate) ) )
         and (    (aACS_DIVISION_ACCOUNT_ID = 0)
              or (    aACS_DIVISION_ACCOUNT_ID > 0
                  and nvl(TOT.ACS_DIVISION_ACCOUNT_ID, 0) = aACS_DIVISION_ACCOUNT_ID) )
         and TOT.ACS_AUXILIARY_ACCOUNT_ID = TMP.LID_FREE_NUMBER_1
         and TMP.LID_CODE = 'MAIN_ID'
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and (   vIsMB = 1
              or TOT.ACS_ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID)
         and TOT.C_TYPE_CUMUL in(aC_TYPE_CUMUL1, aC_TYPE_CUMUL2, aC_TYPE_CUMUL3, aC_TYPE_CUMUL4);
    else
      select case
               when vIsMB > 0 then sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
               else sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
             end * vCoeff
        into vSolde
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
           , COM_LIST_ID_TEMP TMP
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and (    (    aACS_DIVISION_ACCOUNT_ID = 0
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null)
              or (    aACS_DIVISION_ACCOUNT_ID > 0
                  and nvl(TOT.ACS_DIVISION_ACCOUNT_ID, 0) = aACS_DIVISION_ACCOUNT_ID)
             )
         and TOT.ACS_AUXILIARY_ACCOUNT_ID = TMP.LID_FREE_NUMBER_1
         and TMP.LID_CODE = 'MAIN_ID'
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and (   vIsMB = 1
              or TOT.ACS_ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID)
         and TOT.C_TYPE_CUMUL in(aC_TYPE_CUMUL1, aC_TYPE_CUMUL2, aC_TYPE_CUMUL3, aC_TYPE_CUMUL4);
    end if;

    if vSolde is null then
      vSolde  := 0;
    end if;

    return vSolde;
  end SoldeAuxAccountTblTemp;

  /**
  * procedure InsertAutorizedDivsTblTemp
  * Description
  *    Ajoute dans la table temporaire les divisions autorisées par utilisateur,
  *      avec comme mot clé 'ACS_AUTORIZED_DIV' (vConstDivCode);
  */
  procedure InsertAutorizedDivsTblTemp(aRightsMgm in number)
  is
  begin
    if aRightsMgm > 0 then
      delete from COM_LIST_ID_TEMP
            where LID_CODE = vConstDivCode;

      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct column_value ACS_DIVISION_ACCOUNT_ID
                      , vConstDivCode
                   from table(ACS_FUNCTION.TableDivisionsAuthorized(PCS.PC_I_LIB_SESSION.GETUSERID, sysdate) );
    end if;
  end InsertAutorizedDivsTblTemp;

  /**
  * Description
  *    Retourne le solde des comptes auxiliaires présent dans la table temporaire pour une période
  */
  function SoldeAuxAccountPeriodTblTemp(
    aACS_PERIOD_ID             ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , aC_SUB_SET                 ACS_SUB_SET.C_SUB_SET%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aC_TYPE_CUMUL1             ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aC_TYPE_CUMUL2             ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aC_TYPE_CUMUL3             ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aC_TYPE_CUMUL4             ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aRightsMgm                 number
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
    vSolde ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    vIsMB  signtype                                default 0;
    vCoeff signtype;
  begin
    if aACS_FINANCIAL_CURRENCY_ID = 0 then
      vIsMB  := 1;
    else
      select case
               when(aACS_FINANCIAL_CURRENCY_ID = ACS_FINANCIAL_CURRENCY_ID) then 1
               else 0
             end
        into vIsMB
        from ACS_FINANCIAL_CURRENCY
       where FIN_LOCAL_CURRENCY = 1;
    end if;

    if aC_SUB_SET = 'PAY' then
      vCoeff  := -1;
    else
      vCoeff  := 1;
    end if;

    if aRightsMgm > 0 then
      --Question de performance: passer par une table temporaire pour la gestion des divisions par utilisateur
      select case
               when vIsMB > 0 then sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
               else sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
             end * vCoeff
        into vSolde
        from ACT_TOTAL_BY_PERIOD TOT
           , COM_LIST_ID_TEMP AUX
           , COM_LIST_ID_TEMP DIV
       where TOT.ACS_PERIOD_ID = aACS_PERIOD_ID
         and TOT.ACS_DIVISION_ACCOUNT_ID = DIV.COM_LIST_ID_TEMP_ID
         and DIV.LID_CODE = vConstDivCode
         and (    (aACS_DIVISION_ACCOUNT_ID = 0)
              or (    aACS_DIVISION_ACCOUNT_ID > 0
                  and nvl(TOT.ACS_DIVISION_ACCOUNT_ID, 0) = aACS_DIVISION_ACCOUNT_ID) )
         and TOT.ACS_AUXILIARY_ACCOUNT_ID = AUX.LID_FREE_NUMBER_1
         and AUX.LID_CODE = 'MAIN_ID'
         and (   vIsMB = 1
              or TOT.ACS_ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID)
         and TOT.C_TYPE_CUMUL in(aC_TYPE_CUMUL1, aC_TYPE_CUMUL2, aC_TYPE_CUMUL3, aC_TYPE_CUMUL4);
    else
      select case
               when vIsMB > 0 then sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
               else sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
             end * vCoeff
        into vSolde
        from ACT_TOTAL_BY_PERIOD TOT
           , COM_LIST_ID_TEMP TMP
       where TOT.ACS_PERIOD_ID = aACS_PERIOD_ID
         and (    (    aACS_DIVISION_ACCOUNT_ID = 0
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null)
              or (    aACS_DIVISION_ACCOUNT_ID > 0
                  and nvl(TOT.ACS_DIVISION_ACCOUNT_ID, 0) = aACS_DIVISION_ACCOUNT_ID)
             )
         and TOT.ACS_AUXILIARY_ACCOUNT_ID = TMP.LID_FREE_NUMBER_1
         and TMP.LID_CODE = 'MAIN_ID'
         and (   vIsMB = 1
              or TOT.ACS_ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID)
         and TOT.C_TYPE_CUMUL in(aC_TYPE_CUMUL1, aC_TYPE_CUMUL2, aC_TYPE_CUMUL3, aC_TYPE_CUMUL4);
    end if;

    if vSolde is null then
      vSolde  := 0;
    end if;

    return vSolde;
  end SoldeAuxAccountPeriodTblTemp;

  /**
  * Description
  *    Retourne le solde d'un compte financier ou auxiliaire, avec ou sans division,
  *    pour une période et un type de cumul donnés
  */
  function PeriodSoldeAmount(
    aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_PERIOD_ID             ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , aC_TYPE_CUMUL              ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aLC                        number
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
    FinancialYearId   ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    PerNumber         ACS_PERIOD.PER_NO_PERIOD%type;
    DivisionAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SubSet            ACS_SUB_SET.C_SUB_SET%type;
    Amount            ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountLC          ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountFC          ACT_TOTAL_BY_PERIOD.TOT_DEBIT_FC%type;
    AmountEUR         ACT_TOTAL_BY_PERIOD.TOT_DEBIT_EUR%type;
    CurrId            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;

    --------
    function GetPerNumber
      return ACS_PERIOD.PER_NO_PERIOD%type
    is
      Num ACS_PERIOD.PER_NO_PERIOD%type;
    begin
      if aACS_PERIOD_ID is null then
        FinancialYearId  := GetMaxNoExerciceId;

        select max(PER_NO_PERIOD)
          into Num
          from ACS_PERIOD
         where ACS_FINANCIAL_YEAR_ID = FinancialYearId;
      else
        begin
          select ACS_FINANCIAL_YEAR_ID
               , PER_NO_PERIOD
            into FinancialYearId
               , Num
            from ACS_PERIOD
           where ACS_PERIOD_ID = aACS_PERIOD_ID;
        exception
          when no_data_found then
            FinancialYearId  := null;
            Num              := null;
        end;
      end if;

      return Num;
    end;
  begin
    -- Initialisation  FinancialYearId et PerNumber
    PerNumber          := GetPerNumber;
    DivisionAccountId  := aACS_DIVISION_ACCOUNT_ID;

    if aACS_DIVISION_ACCOUNT_ID = 0 then
      DivisionAccountId  := null;
    end if;

    if aACS_FINANCIAL_CURRENCY_ID = 0 then
      CurrId  := null;
    else
      CurrId  := aACS_FINANCIAL_CURRENCY_ID;
    end if;

    SubSet             := ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID);

    if SubSet = 'ACC' then
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
           , sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
           , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = FinancialYearId
         and PER.PER_NO_PERIOD <= PerNumber
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
         and (    (    aACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null)
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
             )
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) );
    elsif SubSet in('REC', 'PAY') then
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
           , sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
           , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = FinancialYearId
         and PER.PER_NO_PERIOD <= PerNumber
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and (    (    aACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null)
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
             )
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) );
    end if;

    if aLC = 1 then   -- LC
      Amount  := AmountLC;
    elsif aLC = 0 then   -- FC
      Amount  := AmountFC;
    elsif aLC = 2 then   -- EURO
      Amount  := AmountEUR;
    end if;

    if Amount is null then
      Amount  := 0;
    end if;

    return Amount;
  end PeriodSoldeAmount;

  /**
  * Description
  *    Retourne le solde d'un compte financier ou auxiliaire, avec ou sans division,
  *    pour une période et un type de cumul donnés avec filtre selon Hedging
  */
  function PeriodSoldeAmountExpiries(
    aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_PERIOD_ID             ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , aC_TYPE_CUMUL              ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aLC                        number
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
    FinancialYearId   ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    PerNumber         ACS_PERIOD.PER_NO_PERIOD%type;
    DivisionAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SubSet            ACS_SUB_SET.C_SUB_SET%type;
    Amount            ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountLC          ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountFC          ACT_TOTAL_BY_PERIOD.TOT_DEBIT_FC%type;
    AmountEUR         ACT_TOTAL_BY_PERIOD.TOT_DEBIT_EUR%type;
    CurrId            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    endDate           ACS_PERIOD.PER_END_DATE%type;

    --------
    function GetPerNumber
      return ACS_PERIOD.PER_NO_PERIOD%type
    is
      Num ACS_PERIOD.PER_NO_PERIOD%type;
    begin
      if aACS_PERIOD_ID is null then
        FinancialYearId  := GetMaxNoExerciceId;

        select max(PER_NO_PERIOD)
          into Num
          from ACS_PERIOD
         where ACS_FINANCIAL_YEAR_ID = FinancialYearId;
      else
        begin
          select ACS_FINANCIAL_YEAR_ID
               , PER_NO_PERIOD
            into FinancialYearId
               , Num
            from ACS_PERIOD
           where ACS_PERIOD_ID = aACS_PERIOD_ID;
        exception
          when no_data_found then
            FinancialYearId  := null;
            Num              := null;
        end;
      end if;

      return Num;
    end;
  begin
    -- Initialisation  FinancialYearId et PerNumber
    PerNumber          := GetPerNumber;
    DivisionAccountId  := aACS_DIVISION_ACCOUNT_ID;

    if aACS_DIVISION_ACCOUNT_ID = 0 then
      DivisionAccountId  := null;
    end if;

    if aACS_FINANCIAL_CURRENCY_ID = 0 then
      CurrId  := null;
    else
      CurrId  := aACS_FINANCIAL_CURRENCY_ID;
    end if;

    SubSet             := ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID);

    select PER_END_DATE
      into endDate
      from ACS_PERIOD
     where ACS_FINANCIAL_YEAR_ID = FinancialYearId
       and PER_NO_PERIOD = PerNumber;

    ACT_FUNCTIONS.SETANALYSE_DATE(to_char(endDate, 'yyyymmdd') );

    select sum(EXP_AMOUNT_LC - DET_PAIED_LC)
         , sum(EXP_AMOUNT_FC - DET_PAIED_FC)
         , sum(EXP_AMOUNT_EUR - DET_PAIED_EUR)
      into AmountLC
         , AmountFC
         , AmountEUR
      from V_ACT_EXPIRIES EX
         , ACT_FINANCIAL_IMPUTATION FIN
         , ACT_DOCUMENT DOC
         --, ACJ_CATALOGUE_DOCUMENT CAT
         --, ACJ_SUB_SET_CAT  SUB
    ,      ACS_PERIOD PER
     where EX.ACT_PART_IMPUTATION_ID = FIN.ACT_PART_IMPUTATION_ID
       and FIN.IMF_TYPE = 'AUX'
       and FIN.ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
       and FIN.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and PER.PER_END_DATE <= endDate
       and EX.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
       and DOC.C_CURR_RATE_COVER_TYPE in('00', '04')
       and EX.C_TYPE_CUMUL = aC_TYPE_CUMUL
       --and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
       --and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
       --and SUB.C_SUB_SET = SubSet
       and (    (    aACS_DIVISION_ACCOUNT_ID is null
                 and FIN.IMF_ACS_DIVISION_ACCOUNT_ID is null)
            or (    aACS_DIVISION_ACCOUNT_ID is not null
                and FIN.IMF_ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
           )
       and (   CurrId is null
            or (    CurrId is not null
                and CurrId = FIN.ACS_FINANCIAL_CURRENCY_ID) );

    if aLC = 1 then   -- LC
      Amount  := AmountLC;
    elsif aLC = 0 then   -- FC
      Amount  := AmountFC;
    elsif aLC = 2 then   -- EURO
      Amount  := AmountEUR;
    end if;

    if Amount is null then
      Amount  := 0;
    end if;

    return Amount;
  end PeriodSoldeAmountExpiries;

  /**
  * Description
  *    Retourne le solde d'un compte financier ou auxiliaire, avec ou sans division,
  *    pour une période et un type de cumul donnés
  */
  function BalanceSoldeAmount(
    aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_PERIOD_ID_FROM        ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , aACS_PERIOD_ID_TO          ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type
  , aC_TYPE_CUMUL              ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aLC                        number
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
    FinancialYearId   ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    PerNumberFrom     ACS_PERIOD.PER_NO_PERIOD%type;
    PerNumberTo       ACS_PERIOD.PER_NO_PERIOD%type;
    DivisionAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    SubSet            ACS_SUB_SET.C_SUB_SET%type;
    Amount            ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountLC          ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountFC          ACT_TOTAL_BY_PERIOD.TOT_DEBIT_FC%type;
    AmountEUR         ACT_TOTAL_BY_PERIOD.TOT_DEBIT_EUR%type;
    CurrId            ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;

    --------
    procedure GetPerNumbers
    is
      FinancialYearIdFrom ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
      FinancialYearIdTo   ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    begin
      if aACS_PERIOD_ID_FROM is not null then
        begin
          select ACS_FINANCIAL_YEAR_ID
               , PER_NO_PERIOD
            into FinancialYearIdFrom
               , PerNumberFrom
            from ACS_PERIOD
           where ACS_PERIOD_ID = aACS_PERIOD_ID_FROM;
        exception
          when no_data_found then
            FinancialYearIdFrom  := null;
            PerNumberFrom        := null;
        end;
      end if;

      if aACS_PERIOD_ID_TO is not null then
        begin
          select ACS_FINANCIAL_YEAR_ID
               , PER_NO_PERIOD
            into FinancialYearIdTo
               , PerNumberTo
            from ACS_PERIOD
           where ACS_PERIOD_ID = aACS_PERIOD_ID_TO;
        exception
          when no_data_found then
            FinancialYearIdTo  := null;
            PerNumberTo        := null;
        end;
      end if;

      if FinancialYearIdFrom is not null then
        FinancialYearId  := FinancialYearIdFrom;
      elsif FinancialYearIdTo is not null then
        FinancialYearId  := FinancialYearIdTo;
      else
        FinancialYearId  := GetMaxNoExerciceId;
      end if;

      if     FinancialYearIdFrom is not null
         and FinancialYearIdFrom != FinancialYearId then
        PerNumberFrom  := null;
      elsif     FinancialYearIdTo is not null
            and FinancialYearIdTo != FinancialYearId then
        PerNumberTo  := null;
      end if;

      if PerNumberFrom is null then
        select min(PER_NO_PERIOD)
          into PerNumberFrom
          from ACS_PERIOD
         where ACS_FINANCIAL_YEAR_ID = FinancialYearId;
      end if;

      if PerNumberTo is null then
        select max(PER_NO_PERIOD)
          into PerNumberTo
          from ACS_PERIOD
         where ACS_FINANCIAL_YEAR_ID = FinancialYearId;
      end if;
    end;
  begin
    -- Initialisation  FinancialYearId et PerNumber
    GetPerNumbers;
    DivisionAccountId  := aACS_DIVISION_ACCOUNT_ID;

    if aACS_DIVISION_ACCOUNT_ID = 0 then
      DivisionAccountId  := null;
    end if;

    if aACS_FINANCIAL_CURRENCY_ID = 0 then
      CurrId  := null;
    else
      CurrId  := aACS_FINANCIAL_CURRENCY_ID;
    end if;

    SubSet             := ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID);

    if SubSet = 'ACC' then
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
           , sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
           , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER2
           , ACS_PERIOD PER1
       where TOT.ACS_PERIOD_ID = PER1.ACS_PERIOD_ID
         and TOT.ACS_PERIOD_ID = PER2.ACS_PERIOD_ID
         and TOT.ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER1.ACS_FINANCIAL_YEAR_ID = FinancialYearId
         and PER2.ACS_FINANCIAL_YEAR_ID = FinancialYearId
         and PER1.PER_NO_PERIOD >= PerNumberFrom
         and PER2.PER_NO_PERIOD <= PerNumberTo
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
         and (    (    aACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null)
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
             )
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) );
    elsif SubSet in('REC', 'PAY') then
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
           , sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
           , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER2
           , ACS_PERIOD PER1
       where TOT.ACS_PERIOD_ID = PER1.ACS_PERIOD_ID
         and TOT.ACS_PERIOD_ID = PER2.ACS_PERIOD_ID
         and TOT.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER1.ACS_FINANCIAL_YEAR_ID = FinancialYearId
         and PER2.ACS_FINANCIAL_YEAR_ID = FinancialYearId
         and PER1.PER_NO_PERIOD >= PerNumberFrom
         and PER2.PER_NO_PERIOD <= PerNumberTo
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and (    (    aACS_DIVISION_ACCOUNT_ID is null
                   and TOT.ACS_DIVISION_ACCOUNT_ID is null)
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
             )
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) );
    end if;

    if aLC = 1 then   -- LC
      Amount  := AmountLC;
    elsif aLC = 0 then   -- FC
      Amount  := AmountFC;
    elsif aLC = 2 then   -- EURO
      Amount  := AmountEUR;
    end if;

    if Amount is null then
      Amount  := 0;
    end if;

    return Amount;
  end BalanceSoldeAmount;

  /**
  * Description
  *    Retourne le report d'un compte pour un exercice et un type de cumul donnés
  */
  function ReportAmount(
    aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_YEAR_ID     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aC_TYPE_CUMUL              ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aLC                        number
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
    SubSet    ACS_SUB_SET.C_SUB_SET%type;
    Amount    ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountLC  ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountFC  ACT_TOTAL_BY_PERIOD.TOT_DEBIT_FC%type;
    AmountEUR ACT_TOTAL_BY_PERIOD.TOT_DEBIT_EUR%type;
    CurrId    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- Valeurs DCOD C_SUB_SET
    -- ACC: Comptes financiers
    -- REC: Comptes auxiliaires débiteurs - PAY: Comptes auxiliaires fournisseurs
    -- DOP/DPA/DTO: Divisions

    -- CPN: Charges par nature
    -- CDA: Centres d'analyse
    -- COS: Porteurs
    -- PRO: Projets
    -- QTU: Unités quantitatives

    -- PBU: Postes budgétaires
    -- VAT: Codes TVA
    if aACS_FINANCIAL_CURRENCY_ID = 0 then
      CurrId  := null;
    else
      CurrId  := aACS_FINANCIAL_CURRENCY_ID;
    end if;

    SubSet  := ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID);

    if SubSet = 'ACC' then
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
           , sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
           , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and TOT.C_TYPE_PERIOD = '1'
         and TOT.ACS_DIVISION_ACCOUNT_ID is null
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) );
    elsif SubSet in('REC', 'PAY') then
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
           , sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
           , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and TOT.C_TYPE_PERIOD = '1'
         and TOT.ACS_DIVISION_ACCOUNT_ID is null
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) );
    elsif SubSet in('DOP', 'DPA', 'DTO') then
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
           , sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
           , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and TOT.C_TYPE_PERIOD = '1'
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) );
    elsif SubSet = 'CPN' then
      select sum(MTO_DEBIT_LC - MTO_CREDIT_LC)
           , sum(MTO_DEBIT_FC - MTO_CREDIT_FC)
           , sum(MTO_DEBIT_EUR - MTO_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_MGM_TOT_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_CPN_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and PER.C_TYPE_PERIOD = '1'
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_FINANCIAL_CURRENCY_ID) );
    elsif SubSet = 'CDA' then
      select sum(MTO_DEBIT_LC - MTO_CREDIT_LC)
           , sum(MTO_DEBIT_FC - MTO_CREDIT_FC)
           , sum(MTO_DEBIT_EUR - MTO_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_MGM_TOT_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_CDA_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and PER.C_TYPE_PERIOD = '1'
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_FINANCIAL_CURRENCY_ID) );
    elsif SubSet = 'COS' then
      select sum(MTO_DEBIT_LC - MTO_CREDIT_LC)
           , sum(MTO_DEBIT_FC - MTO_CREDIT_FC)
           , sum(MTO_DEBIT_EUR - MTO_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_MGM_TOT_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_PF_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and PER.C_TYPE_PERIOD = '1'
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_FINANCIAL_CURRENCY_ID) );
    elsif SubSet = 'PRO' then
      select sum(MTO_DEBIT_LC - MTO_CREDIT_LC)
           , sum(MTO_DEBIT_FC - MTO_CREDIT_FC)
           , sum(MTO_DEBIT_EUR - MTO_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_MGM_TOT_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_PJ_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and PER.C_TYPE_PERIOD = '1'
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_FINANCIAL_CURRENCY_ID) );
    end if;

    if aLC = 1 then   -- LC
      Amount  := AmountLC;
    elsif aLC = 0 then   -- FC
      Amount  := AmountFC;
    elsif aLC = 2 then   -- EURO
      Amount  := AmountEUR;
    end if;

    if Amount is null then
      Amount  := 0;
    end if;

    return Amount;
  end ReportAmount;

-----------------------------
  function ReportDivisionAmount(
    aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_DIVISION_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_YEAR_ID     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aC_TYPE_CUMUL              ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
  , aLC                        number
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  )
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
    SubSet    ACS_SUB_SET.C_SUB_SET%type;
    Amount    ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountLC  ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    AmountFC  ACT_TOTAL_BY_PERIOD.TOT_DEBIT_FC%type;
    AmountEUR ACT_TOTAL_BY_PERIOD.TOT_DEBIT_EUR%type;
    CurrId    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    if aACS_FINANCIAL_CURRENCY_ID = 0 then
      CurrId  := null;
    else
      CurrId  := aACS_FINANCIAL_CURRENCY_ID;
    end if;

    SubSet  := ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID);

    if SubSet = 'ACC' then
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
           , sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
           , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and TOT.C_TYPE_PERIOD = '1'
         and (       aACS_DIVISION_ACCOUNT_ID is null
                 and TOT.ACS_DIVISION_ACCOUNT_ID is null
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
             )
         and (   aACS_DIVISION_ACCOUNT_ID is null
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID) )
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) );
    elsif SubSet in('REC', 'PAY') then
      select sum(TOT_DEBIT_LC - TOT_CREDIT_LC)
           , sum(TOT_DEBIT_FC - TOT_CREDIT_FC)
           , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR)
        into AmountLC
           , AmountFC
           , AmountEUR
        from ACT_TOTAL_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and TOT.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID
         and PER.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL = aC_TYPE_CUMUL
         and TOT.C_TYPE_PERIOD = '1'
         and (       aACS_DIVISION_ACCOUNT_ID is null
                 and TOT.ACS_DIVISION_ACCOUNT_ID is null
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID)
             )
         and (   aACS_DIVISION_ACCOUNT_ID is null
              or (    aACS_DIVISION_ACCOUNT_ID is not null
                  and TOT.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID) )
         and (   CurrId is null
              or (    CurrId is not null
                  and CurrId = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) );
    end if;

    if aLC = 1 then   -- LC
      Amount  := AmountLC;
    elsif aLC = 0 then   -- FC
      Amount  := AmountFC;
    elsif aLC = 2 then   -- EURO
      Amount  := AmountEUR;
    end if;

    if Amount is null then
      Amount  := 0;
    end if;

    return Amount;
  end ReportDivisionAmount;

-----------------
  function Modulo10(strNombre varchar2)
    return varchar2
  is
  begin
    return PCS.PC_MATH_FUNCTIONS.Modulo10(strNombre);
  end Modulo10;

-----------------
  function Modulo11(strNombre varchar2)
    return varchar2
  is
  begin
    return PCS.PC_MATH_FUNCTIONS.Modulo11(strNombre);
  end Modulo11;

-----------------
  function Modulo97(pAccount varchar2)
    return varchar2
  is
  begin
    return PCS.PC_MATH_FUNCTIONS.Modulo97(pAccount);
  end Modulo97;

---------------------
  procedure pGetBVRLastNumber(
    pBvrReferenceID   out ACS_BVR_REFERENCE.ACS_BVR_REFERENCE_ID%type
  , pLastNumber       out ACS_BVR_REFERENCE.BVR_LAST_NUMBER%type
  , pUpdateLastNumber     boolean default true
  )
  is
    pragma autonomous_transaction;
  begin
    begin
      select     ACS_BVR_REFERENCE_ID
               , BVR_STEP + nvl(BVR_LAST_NUMBER, 0)
            into pBvrReferenceID
               , pLastNumber
            from ACS_BVR_REFERENCE
      for update;
    exception
      when no_data_found then
        pBvrReferenceID  := null;
      when too_many_rows then
        pBvrReferenceID  := null;
        raise_application_error(-20000, 'TOO_MANY_ROWS IN ACS_BVR_REFERENCE: ' || sqlerrm);
    end;

    if     pUpdateLastNumber
       and (pBvrReferenceID is not null) then
      --Mise à jour du dernier numéro BVR utilisé
      update ACS_BVR_REFERENCE
         set BVR_LAST_NUMBER = pLastNumber;
    end if;

    commit;   -- autonomous transaction
  end pGetBVRLastNumber;

---------------------
  /**
  * function pSet_BVR_Ref_Comp
  * Description
  *  Retourne un numéro BVR à 27 positions
  * @lastUpdate
  * @public
  * @param pCTypeSupport: type de support 35,50,56
  * @param pCRefComposition: référence de composition 01,02,03,04,05,06,07,08,09
  * @param pTypeDoc: 1(DOC) ou 2 (ACT)
  * @param pDocID: identifiant document ACT ou DOC
  * @param pBankSBVR       No de SBVR Banque
  * @return Numéro BVR sur 27 positions
  */
  function pSet_BVR_Ref_Comp(
    pCTypeSupport    ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type
  , pCRefComposition ACS_PAYMENT_METHOD.C_REFERENCE_COMPOSITION%type
  , pTypeDoc         varchar2
  , pStrDocID        varchar2
  , pBankSBVR        ACS_PAYMENT_METHOD.PME_BANK_SBVR%type   -- Variable contenant le No de SBVR Banque (Pour les réf. BVR  à 27 positions)
  )
    return varchar2
  is
    vDocumentID         ACT_DOCUMENT.ACT_DOCUMENT_ID%type               default 0;
    vDocNumber          ACT_DOCUMENT.DOC_NUMBER%type;
    vParDocument        ACT_PART_IMPUTATION.PAR_DOCUMENT%type;
    vPerKey1            PAC_PERSON.PER_KEY1%type;
    vPerKey2            PAC_PERSON.PER_KEY2%type;
    vKey                varchar2(18);   --valeur selon descode
    vBankSBVR           ACS_PAYMENT_METHOD.PME_BANK_SBVR%type;   -- No d'adhérent auprès de la banque
    vSBVRNum            varchar2(8);   -- numéro unique SBVR
    vResult             varchar2(27);
    vLastNumber         ACS_BVR_REFERENCE.BVR_LAST_NUMBER%type;   --  Dernier No Utilisé
    vBvrReferenceID     ACS_BVR_REFERENCE.ACS_BVR_REFERENCE_ID%type;
    vAcsUsedReferenceID ACS_USED_REFERENCE.ACS_USED_REFERENCE_ID%type;
    vManyImputations    boolean                                         default false;
    vDualFields         boolean;
    vLengthKey          number;
    vLengthSBVRNum      number;
    vLengthDocNumber    integer;
    vCodeKey            varchar2(10);
    vLengthMaskKey      integer;

    /**
    * function FormatKey
    * Description
    *  Retourne un numéro épuré de toutes les valeurs différentes de 0 à 9 et de longueur définie
    **/
    function FormatKey(pKey varchar2, pKeyLength number, pKeyFill varchar2, trimleft boolean := false)
      return varchar2
    --  Caractères autorisés: 0123456789
    --  Remplir avec des '0' à gauche
    is
      strChkKey varchar2(18);
      vKey      varchar2(1);
      cpt       number(2);
    begin
      cpt        := 0;
      strChkKey  := '';

      if pKey is not null then
        for cpt in 1 .. length(pKey) loop
          vKey  := substr(pKey, cpt, 1);

          if vKey in('0', '1', '2', '3', '4', '5', '6', '7', '8', '9') then
            strChkKey  := strChkKey || vKey;
          end if;
        end loop;

        -- Tronquer le champ par la gauche
        if     trimleft
           and (length(strChkKey) > pKeyLength) then
          strChkKey  := substr(strChkKey, -pKeyLength);
        end if;

        return lpad(strChkKey, pKeyLength, pKeyFill);
      else
        return lpad('0', pKeyLength, pKeyFill);
      end if;
    end FormatKey;
  begin
/*
  Composition SBVR
  6 pos. pour le no d'adhérent auprès de la banque
  12 positions pour la valeur de la colonne indiquée par la méthode 01-05
  8 pos. pour le numéro unique attribué
  1 chiffre de contrôle

  Valeur du code:
    01 : ACT_DOCUMENT.ACT_DOCUMENT_ID / DOC_DOCUMENT.DOC_DOCUMENT_ID
    02 : ACT_DOCUMENT.DOC_NUMBER / DOC_DOCUMENT.DMT_NUMBER
    03 : ACT_PART_IMPUTATION.PAR_DOCUMENT / DOC_DOCUMENT.DMT_PARTNER_NUMBER
    04 : PAC_PERSON.PER_KEY1
    05 : PAC_PERSON.PER_KEY2
    06 : PAC_PERSON.PER_KEY1 || ACT_DOCUMENT.DOC_NUMBER / DOC_DOCUMENT.DMT_NUMBER
    07 : PAC_PERSON.PER_KEY1 || ACT_PART_IMPUTATION.PAR_DOCUMENT / DOC_DOCUMENT.DMT_PARTNER_NUMBER
    08 : PAC_PERSON.PER_KEY2 || ACT_DOCUMENT.DOC_NUMBER / DOC_DOCUMENT.DMT_NUMBER
    09 : PAC_PERSON.PER_KEY2 || ACT_PART_IMPUTATION.PAR_DOCUMENT / DOC_DOCUMENT.DMT_PARTNER_NUMBER

  Pour les valeurs 06,07,08,09: composition du résultat
  si adhérent existe (pBankSBVR):
    - 6 pos. pour le no d'adhérent auprès de la banque
    - 14 positions pour la valeur de la colonne indiquée par la méthode (KEY:6/NUMBER:8)
    - 6 pos. pour le numéro unique attribué
    - 1 chiffre de contrôle
    -----
     27

  si pas d'adhérent (pBankSBVR is null)
    - 0 pos. pour le no d'adhérent auprès de la banque
    - 18 positions pour la valeur de la colonne indiquée par la méthode (2x9)
    - 8 pos. pour le numéro unique attribué
    - 1 chiffre de contrôle
    -----
     27

**/
    vResult      := '';
    vDualFields  := pCRefComposition in('06', '07', '08', '09');

    if pTypeDoc = '2' then   -- Domaine ACT
      begin
        select PAR.ACT_DOCUMENT_ID
             , PAR.PAR_DOCUMENT
             , PER.PER_KEY1
             , PER.PER_KEY2
             , DOC.DOC_NUMBER
          into vDocumentID
             , vParDocument
             , vPerKey1
             , vPerKey2
             , vDocNumber
          from ACT_PART_IMPUTATION PAR
             , PAC_PERSON PER
             , ACT_DOCUMENT DOC
         where DOC.ACT_DOCUMENT_ID = to_number(pStrDocID)
           and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
           and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = PER.PAC_PERSON_ID;
      exception
        when no_data_found then
          vDocumentID   := 0;
          vDocNumber    := '';
          vParDocument  := '';
          vPerKey1      := '';
          vPerKey2      := '';
        when too_many_rows then
          vManyImputations  := true;
          vDocumentID       := 0;
          vDocNumber        := '';
          vParDocument      := '';
          vPerKey1          := '';
          vPerKey2          := '';
      end;
    else   -- Domaine DOC
      begin
        select DMT.DOC_DOCUMENT_ID
             , DMT.DMT_NUMBER
             , DMT.DMT_PARTNER_NUMBER
             , PER.PER_KEY1
             , PER.PER_KEY2
          into vDocumentID
             , vDocNumber
             , vParDocument
             , vPerKey1
             , vPerKey2
          from DOC_DOCUMENT DMT
             , PAC_PERSON PER
         where DMT.DOC_DOCUMENT_ID = to_number(pStrDocID)
           and DMT.PAC_THIRD_ACI_ID = PER.PAC_PERSON_ID(+);
      exception
        when no_data_found or too_many_rows then
          vDocumentID   := 0;
          vDocNumber    := '';
          vParDocument  := '';
          vPerKey1      := '';
          vPerKey2      := '';
      end;
    end if;

    --Recherche du prochain numéro BVR en autonmous transaction
    pGetBVRLastNumber(vBvrReferenceID, vLastNumber);

    if vBvrReferenceID is not null then
      vSBVRNum  := to_char(vLastNumber);

      if vDualFields then
        -- 6 premières positions: num adhérent ou si inexistant, répartir les 6 pos sur la clé (2*9) + numéro SBVR (8)
        if pBankSBVR is null then
          vLengthKey        := 18;
          vLengthSBVRNum    := 8;

          if pCRefComposition in('06', '07') then
            vCodeKey  := 'KEY1';
          else
            vCodeKey  := 'KEY2';
          end if;

          vLengthMaskKey    := 8;   --longeur max

          --Recherche longueur masque clé (max 8)
          begin
            select least(nvl(length(replace(PIC.PIC_PICTURE, '\', '') ), vLengthMaskKey), vLengthMaskKey)
              into vLengthMaskKey
              from PAC_KEY_FORMAT key
                 , ACS_PICTURE PIC
             where key.C_KEY_TYPE = vCodeKey
               and PIC.ACS_PICTURE_ID = key.ACS_PICTURE_ID;
          exception
            when no_data_found then
              null;
          end;

          vLengthDocNumber  := vLengthKey - vLengthMaskKey;
        else
          vLengthKey        := 14;
          vLengthDocNumber  := 8;
          vLengthSBVRNum    := 6;
          vBankSBVR         := rpad(pBankSBVR, 6, '0');
        end if;
      else
        vLengthSBVRNum  := 8;
        vLengthKey      := 12;

        -- 6 premières positions: num adhérent
        if pBankSBVR is null then
          vBankSBVR  := rpad('0', 6, '0');
        else
          vBankSBVR  := rpad(pBankSBVR, 6, '0');
        end if;
      end if;

      select ACS_USED_REFERENCE_SEQ.nextval
        into vAcsUsedReferenceID
        from dual;

      --Création de la clé selon le code
      if pCRefComposition = '01' then
        vKey  := FormatKey(to_char(vDocumentID), vLengthKey, '0');
      elsif pCRefComposition = '02' then
        vKey  := FormatKey(vDocNumber, vLengthKey, '0', true);
      elsif vManyImputations then   -- Générer la clé avec l'ID de la dernière référence utilisée lorsque plusieurs imputations d'existantes
        vKey  := FormatKey(vAcsUsedReferenceID, vLengthKey, '0');
      elsif pCRefComposition = '03' then
        vKey  := FormatKey(vParDocument, vLengthKey, '0', true);
      elsif pCRefComposition = '04' then
        vKey  := FormatKey(vPerKey1, vLengthKey, '0');
      elsif pCRefComposition = '05' then
        vKey  := FormatKey(vPerKey2, vLengthKey, '0');
      elsif pCRefComposition = '06' then
        vPerKey1    := FormatKey(vPerKey1, vLengthKey - vLengthDocNumber, '0');
        vDocNumber  := FormatKey(vDocNumber, vLengthDocNumber, '0', true);
        vKey        := vPerKey1 || vDocNumber;
      elsif pCRefComposition = '07' then
        vPerKey1      := FormatKey(vPerKey1, vLengthKey - vLengthDocNumber, '0');
        vParDocument  := FormatKey(vParDocument, vLengthDocNumber, '0', true);
        vKey          := vPerKey1 || vParDocument;
      elsif pCRefComposition = '08' then
        vPerKey2    := FormatKey(vPerKey2, vLengthKey - vLengthDocNumber, '0');
        vDocNumber  := FormatKey(vDocNumber, vLengthDocNumber, '0', true);
        vKey        := vPerKey2 || vDocNumber;
      elsif pCRefComposition = '09' then
        vPerKey2      := FormatKey(vPerKey2, vLengthKey - vLengthDocNumber, '0');
        vParDocument  := FormatKey(vParDocument, vLengthDocNumber, '0', true);
        vKey          := vPerKey2 || vParDocument;
      else
        vKey  := FormatKey('', vLengthKey, '0');
      end if;

      --Remplacer une clé ne contenant que des 0 par l'identifiant ACS_USED_REFERENCE_ID
      if vKey = lpad('0', 12, '0') then
        vKey  := FormatKey(vAcsUsedReferenceID, 12, '0');
      end if;

      -- Num adhérent (si existant) + clé + numéro unique PCS
      if vDualFields then
        if pBankSBVR is null then   --si null, l'espace qui lui était réservé est réparti entre la clé (+4) et le numéro SBVR (+2)
          vResult  := vKey || FormatKey(vSBVRNum, vLengthSBVRNum, '0', true);
        else
          vResult  := vBankSBVR || vKey || FormatKey(vSBVRNum, vLengthSBVRNum, '0', true);
        end if;
      else
        -- Num adhérent + clé + numéro unique PCS
        vResult  := vBankSBVR || vKey || FormatKey(vSBVRNum, vLengthSBVRNum, '0', true);
      end if;

      -- + 1 chiffre pour contrôle
      vResult   := vResult || ACS_FUNCTION.Modulo10(vResult);

      -- Ajout de la référence BVR utilisée
      insert into ACS_USED_REFERENCE
                  (ACS_USED_REFERENCE_ID
                 , ACS_BVR_REFERENCE_ID
                 , C_DOCUMENT
                 , URE_NUMBER
                 , URE_REF_BVR
                 , URE_DOCUMENT
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vAcsUsedReferenceID
                 , vBvrReferenceID
                 , pTypeDoc
                 , vLastNumber
                 , vResult
                 , pStrDocID
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni2
                  );
    end if;

    return vResult;
  end pSet_BVR_Ref_Comp;

  procedure Set_BVR_Ref(
    aACS_FIN_ACC_S_PAYMENT_ID        ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , strTypeDoc                       varchar2
  , strDocID                         varchar2
  , strResult                 in out varchar2
  )
  is
    strPmm_Bvr_Prefix  ACS_FIN_ACC_S_PAYMENT.PMM_BVR_PREFIX%type;   -- Variable contenant le préfixe
    strType_Support    ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type;   -- Variable contenant le type de support
    strRefComposition  ACS_PAYMENT_METHOD.C_REFERENCE_COMPOSITION%type;   --Composition du numéro BVR: 00 = standard 24 positions, 01->05 BVR avec 27 positions
    strZero            varchar2(100);   -- Variable contenant des 0 pour remplir les champs trop petits
    strBVR_Nr          varchar2(100);   -- Variable contenant le no unique généré par PCS
    strBank_SBVR       ACS_PAYMENT_METHOD.PME_BANK_SBVR%type;   -- Variable contenant le No de SBVR Banque (Pour les réf. BVR  à 27 positions)
    i                  number(2);   -- Compteur
    intTo              number(2);   -- Contient le nombre de position de la référence suivant le type de méthode utilisé
    intLength          number(2);
    intNumberUsed      ACS_BVR_REFERENCE.BVR_LAST_NUMBER%type;   --  Dernier No Utilisé
    intBvr_ReferenceID ACS_BVR_REFERENCE.ACS_BVR_REFERENCE_ID%type;   -- ID du record de la table ACS_BVR_REFERENCE_ID
  begin
    -- Requête pour la recherche du préfixe de paiement
    select lpad(nvl(PMM.PMM_BVR_PREFIX, '0'), 3, '0') PMM_BVR_PREFIX
         , PME.PME_BANK_SBVR
         , PME.C_TYPE_SUPPORT
         , nvl(PME.C_REFERENCE_COMPOSITION, '00') C_REFERENCE_COMPOSITION
      into strPmm_Bvr_Prefix
         , strBank_SBVR
         , strType_Support
         , strRefComposition
      from ACS_FIN_ACC_S_PAYMENT PMM
         , ACS_PAYMENT_METHOD PME
     where PMM.ACS_PAYMENT_METHOD_ID = PME.ACS_PAYMENT_METHOD_ID
       and PMM.ACS_FIN_ACC_S_PAYMENT_ID = aACS_FIN_ACC_S_PAYMENT_ID;

    if     strRefComposition is not null
       and strType_Support is not null
       and strType_Support in('35', '50', '51', '56')
       and strRefComposition in('01', '02', '03', '04', '05', '06', '07', '08', '09') then
      strResult           := pSet_BVR_Ref_Comp(strType_Support, strRefComposition, strTypeDoc, strDocID, strBank_SBVR);
      intBvr_ReferenceID  := null;
    else
      strResult  := '0000000000000000';

      if strType_Support is not null then
        -- Assignation du SBVR Banque si le type de support est = 35, 50 , ou 56
        if    (strType_Support = '35')
           or (strType_Support = '50')
           or (strType_Support = '51')
           or (strType_Support = '56') then
          -- Remplissage avec des 0 si la longueur du SBVR banque est < 8
          strZero       := '';

          if strBank_SBVR is null then
            intLength  := 0;
          else
            intLength  := length(strBank_SBVR);
          end if;

          for i in intLength .. 7 loop
            strZero  := strZero || '0';
          end loop;

          strBank_SBVR  := strBank_SBVR || strZero;
        else
          strBank_SBVR  := '';
        end if;

        --Recherche du prochain numéro BVR en autonmous transaction
        pGetBVRLastNumber(intBvr_ReferenceID
                        , intNumberUsed
                        ,    (strType_Support = '33')
                          or (strType_Support = '34')
                          or (strType_Support = '35')
                          or (strType_Support = '50')
                          or (strType_Support = '51')
                          or (strType_Support = '56')
                         );
      end if;

      if intBvr_ReferenceID is not null then
        strBVR_Nr  := to_char(intNumberUsed);
        strZero    := '';
        intTo      := 14;

        -- Test du type de support utilisé pour connaître le nombre de zéro à rajouter à la chaîne
        if    (strType_Support = '33')
           or (strType_Support = '34') then
          intTo  := 11;
        end if;

        -- Remplissage avec des 0 si la longueur du no de réf. est < la variable intTo
        intLength  := length(strBVR_Nr);

        if intLength is null then
          intLength  := 0;
        end if;

        for i in intLength .. intTo loop
          strZero  := strZero || '0';
        end loop;

        strBVR_Nr  := strZero || strBVR_Nr;

        -- Mise à jour du dernier No de référence Utilisé pour types de support 33, 34, 35, 50, 56
        if    (strType_Support = '33')
           or (strType_Support = '34')
           or (strType_Support = '35')
           or (strType_Support = '50')
           or (strType_Support = '51')
           or (strType_Support = '56') then
          --      dbms_OutPut.put_line('1: ' || to_char(intBvr_ReferenceID) || ', 2: ' || strTypeDoc || ', 3: ' || to_char(intNumberUsed) || ', 4: ' || strDocID);
          strResult  := strBank_SBVR || strPmm_Bvr_Prefix || strBVR_Nr;

          -- Ajout à la variable du chiffre-clé avec la méthode Modulo 10,
          --récursif pour le type 34, 35, 50, 56
          if    (strType_Support = '34')
             or (strType_Support = '35')
             or (strType_Support = '50')
             or (strType_Support = '51')
             or (strType_Support = '56') then
            strResult  := strResult || ACS_FUNCTION.Modulo10(strResult);
          end if;

          -- Requête pour la mise à jour des référence utilisées, seulement si le type de support est correct
          insert into ACS_USED_REFERENCE
                      (ACS_USED_REFERENCE_ID
                     , ACS_BVR_REFERENCE_ID
                     , C_DOCUMENT
                     , URE_NUMBER
                     , URE_DOCUMENT
                     , URE_REF_BVR
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (ACS_USED_REFERENCE_SEQ.nextval
                     , intBvr_ReferenceID
                     , strTypeDoc
                     , intNumberUsed
                     , strDocID
                     , strResult
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni2
                      );
        end if;
      end if;
    end if;
  --  dbms_OutPut.Put_Line(strResult);
  end Set_BVR_Ref;

----------------------------
  function Get_BVR_Coding_Line(
    aACS_FIN_ACC_S_PAYMENT_ID ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , strBVR_Ref                varchar2
  , AmountLC                  number
  , CurrencyLC                number
  , AmountFC                  number
  , CurrencyFC                number
  )
    return varchar2
  is
  begin
    return Get_BVR_Coding_Line(aACS_FIN_ACC_S_PAYMENT_ID
                             , strBVR_Ref
                             , AmountLC
                             , ACS_FUNCTION.GetCurrencyName(CurrencyLC)
                             , AmountFC
                             , ACS_FUNCTION.GetCurrencyName(CurrencyFC)
                              );
  end Get_BVR_Coding_Line;

----------------------------
  function Get_BVR_Coding_Line(
    aACS_FIN_ACC_S_PAYMENT_ID ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , strBVR_Ref                varchar2
  , AmountLC                  number
  , CurrencyLC                varchar2 default 'CHF'
  , AmountFC                  number default null
  , CurrencyFC                varchar2 default null
  )
    return varchar2
  is
    strAmount     varchar2(100);   -- Montant du BVR
    strBVR        varchar2(100);   -- No du BVR
    strZero       varchar2(100);   -- Variable pour compléter les champs avec des zéros
    intPayBack    number(1);   -- Flag de remboursement
    i             number(2);   -- Compteur
    strResult     varchar2(100);
    strProv       varchar2(100);
    vIsEuroAmount boolean;
    Amount        number(15, 2);
    vErrorResult  varchar2(100) := '000>0000000000000000+ 000000000>';
  -----
  begin
    -- Retourne le no BVR ainsi que le flag remboursement
    select max(ACS_PAYMENT_METHOD.PME_SBVR)
         , max(ACS_PAYMENT_METHOD.PME_BVR_PAYBACK)
      into strBVR
         , intPayBack
      from ACS_PAYMENT_METHOD
         , ACS_FIN_ACC_S_PAYMENT
     where ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID = aACS_FIN_ACC_S_PAYMENT_ID
       and ACS_FIN_ACC_S_PAYMENT.ACS_PAYMENT_METHOD_ID = ACS_PAYMENT_METHOD.ACS_PAYMENT_METHOD_ID;

    -- Les montants sont libellés en Euro si le numéro BVR commence par '03'
    vIsEuroAmount  := substr(strBVR, 1, 2) = '03';

    if vIsEuroAmount then
      if CurrencyLC = 'EUR' then
        Amount  := AmountLC;
      elsif CurrencyFC = 'EUR' then
        Amount  := AmountFC;
      else
        --Pas cohérent donc on retourne vide
        return vErrorResult;
      end if;
    else
      if CurrencyLC = 'CHF' then
        Amount  := AmountLC;
      elsif CurrencyFC = 'CHF' then
        Amount  := AmountFC;
      else
        --Pas cohérent donc on retourne vide
        return vErrorResult;
      end if;
    end if;

    -- Test si c'est un BVR+ que l'on va utiliser (sans montant)
    if Amount = 0 then
      -- Retourne 000>0000000000000000+ 000000000> si la réf BVR est incorrect ou si le No BVR est vide
      if    (strBVR is null)
         or (strBVR_Ref = '0000000000000000') then
        strResult  := vErrorResult;
      else
        if length(strBvr) = 5 then   -- N° de client BVR à 5 positions
          strResult  := '     ' || strBVR_Ref || '+ ' || strBVR || '>';
        elsif vIsEuroAmount then   -- BVR +
          strResult  := '319>' || strBVR_Ref || '+ ' || strBVR || '>';
        else
          strResult  := '042>' || strBVR_Ref || '+ ' || strBVR || '>';
        end if;
      end if;
    else
      -- Test sur la grandeur du montant, il doit être < 8,2
      if abs(Amount) > 99999999.99 then
        strResult  := vErrorResult;
      else
        if length(strBvr) = 5 then   -- N° de client BVR à 5 positions
          -- Formate le montant à deux décimales
          strAmount  := to_char(Amount, '0000000.00');
          -- Enlève le point des décimales
          strAmount  := replace(strAmount, '.');
          strAmount  := replace(strAmount, ' ');
          strAmount  := replace(strAmount, '-');
          strAmount  := replace(strAmount, ',');

          -- Ajout du type de BVR utilisé (BVR ou BVR-Rbt)
          if intPayBack = 0 then
            if vIsEuroAmount then
              strAmount  := '0021' || strAmount;
            else
              strAmount  := '0001' || strAmount;
            end if;
          else
            strAmount  := '0003' || strAmount;
          end if;

          strProv    := strAmount || strBVR_Ref || strBVR;
          strResult  := '<' || ACS_FUNCTION.Modulo11(strProv) || StrAmount || '> ' || strBVR_Ref || '+ ' || strBVR || '>';
        else   -- N° de client BVR à 9 positions
          -- Formate le montant à deux décimales
          strAmount  := to_char(Amount, '00000000.00');
          -- Enlève le point des décimales
          strAmount  := replace(strAmount, '.');
          strAmount  := replace(strAmount, ' ');
          strAmount  := replace(strAmount, '-');
          strAmount  := replace(strAmount, ',');

          -- Ajout du type de BVR utilisé (BVR ou BVR-Rbt)
          if intPayBack = 0 then
            if vIsEuroAmount then
              strAmount  := '21' || strAmount;
            else
              strAmount  := '01' || strAmount;
            end if;
          else
            strAmount  := '03' || strAmount;
          end if;

          -- Ajout du Modulo10 récursif pour le code avec le montant
          strAmount  := strAmount || ACS_FUNCTION.Modulo10(strAmount);

          -- Renvoie le résultat de la fonction
          -- Retourne 000>0000000000000000+ 000000000> si la réf BVR est incorrect ou si le No BVR est vide
          if    (strBVR is null)
             or (strBVR_Ref = '0000000000000000') then
            strResult  := vErrorResult;
          else
            strResult  := StrAmount || '>' || strBVR_Ref || '+ ' || strBVR || '>';
          end if;
        end if;
      end if;
    end if;

    return strResult;
  end Get_BVR_Coding_Line;

  /**
   * Description : décodage d'une ligne SBVR
  */
  function DecodeSBVRLine(aBVRLine in varchar2, aNumRef out varchar2, aNumAdh out varchar2, aAmount out varchar2, aClearing out varchar2, aNumAcc out varchar2)
    return signtype
  is
    strBlock1   varchar2(2000);
    strBlock2   varchar2(2000);
    strBlock3   varchar2(2000);
    strTmp      varchar2(2000);
    intPosition integer;
  begin
    aNumRef      := '';
    aNumAdh      := '';
    aAmount      := '';
    strBlock1    := '';
    strBlock2    := '';
    strBlock3    := '';
    --Suppression des espaces
    strTmp       := replace(aBVRLine, ' ', '');

    if length(strTmp) = 0 then
      return 0;
    end if;

    --Suppression du > final
    if instr(strTmp, '>', length(strTmp) ) > 0 then
      strTmp  := substr(strTmp, 1, length(strTmp) - 1);
    end if;

    intPosition  := instr(strTmp, '+');

    if intPosition = 0 then   --CCP ou Banque avec uniquement BC
      if length(strTmp) = 9 then
        if substr(strTmp, 1, 2) = '07' then
          aClearing  := substr(strTmp, 3, 5);   --Banque -> CB
        else
          strBlock1  := strTmp;
        end if;
      else
        return 0;
      end if;
    else   --Autres
      strBlock1    := substr(strTmp, intPosition + 1, length(strTmp) );
      strBlock2    := substr(strTmp, 1, intPosition - 1);
      intPosition  := instr(strBlock2, '>');

      if intPosition > 0 then   --pas Banque et BVR 5
        strBlock3  := substr(strBlock2, 1, intPosition - 1);
        strBlock2  := substr(strBlock2, intPosition + 1, length(strBlock2) );
      end if;

      if length(strBlock1) = 5 then   --BVR 5
        if length(strBlock2) = 15 then
          if strBlock3 <> '' then   --Avec montant
            if     (instr(strBlock3, '<', 1, 1) = 1)
               and (length(strBlock3) = 16) then
              aAmount  := substr(strBlock3, 8, 9);
            else
              return 0;
            end if;
          end if;
        else
          return 0;
        end if;
      elsif length(strBlock1) = 9 then   --BVR 9 ou banque
        if length(strBlock2) = 16 then   --BVR 16 pos
          if length(strBlock3) = 13 then   --Avec montant
            aAmount  := substr(strBlock3, 3, 10);
          elsif length(strBlock3) <> 3 then
            return 0;
          end if;
        elsif length(strBlock2) = 27 then   --BVR 27 pos ou banque
          if length(strBlock3) > 0 then
            if length(strBlock3) = 13 then   --Avec montant
              aAmount  := substr(strBlock3, 3, 10);
            elsif length(strBlock3) <> 3 then
              return 0;
            end if;
          else   --banque
            aClearing  := substr(strBlock1, 3, 5);
            aNumAcc    := substr(strBlock2, 11, 16);
            --On quitte de suite
            return 1;
          end if;
        else
          return 0;
        end if;
      else
        return 0;
      end if;
    end if;

    aNumAdh      := strBlock1;
    aNumRef      := strBlock2;
    return 1;
  end DecodeSBVRLine;

  /**
  * Description
  *   Renvoie l'id de l'année financiere précédente de celle envoyée
  */
  function GetPreviousFinancialYearID(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
    idFinancialYear ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
  begin
    begin
      select   A.ACS_FINANCIAL_YEAR_ID
          into idFinancialYear
          from ACS_FINANCIAL_YEAR A
             , ACS_FINANCIAL_YEAR B
         where   --A.FYE_NO_EXERCICE = B.FYE_NO_EXERCICE-1
               B.FYE_START_DATE = A.FYE_END_DATE + 1
           and B.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
      order by A.FYE_START_DATE asc
             , A.FYE_END_DATE asc
             , B.FYE_START_DATE asc
             , B.FYE_END_DATE;
    exception
      when no_data_found then
        idFinancialYear  := null;
    end;

    return idFinancialYear;
  end GetPreviousFinancialYearID;

  /**
  * Description
  *    Renvoie l'état de l'exercice qui précède l'exercice comptable passé en paramètre
  */
  function GetStatePreviousFinancialYear(aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    return ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type
  is
    State ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;
  begin
    begin
      select   A.C_STATE_FINANCIAL_YEAR
          into State
          from ACS_FINANCIAL_YEAR A
             , ACS_FINANCIAL_YEAR B
         where   --A.FYE_NO_EXERCICE = B.FYE_NO_EXERCICE - 1
               B.FYE_START_DATE = A.FYE_END_DATE + 1
           and B.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
      order by A.FYE_START_DATE asc
             , A.FYE_END_DATE asc
             , B.FYE_START_DATE asc
             , B.FYE_END_DATE;
    exception
      when no_data_found then
        State  := null;
    end;

    return State;
  end GetStatePreviousFinancialYear;

  /**
  * Description
  *  Renvoie la description d'un compte
  *  Ne renvoie qu'une ligne car il peut arriver, suivant les procédures de reprise de données,
  *  qu'un compte possède plusieurs fois la désignation pour la même langue.
  */
  function GetAccountDescriptionSummary(pACS_ACCOUNT_ID in ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
    return varchar2
  is
    vDescription ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type;
  begin
    --A des fins d'optimisation, il est préférable de travailler par cursor déclaré dans le body
    open crDescrAccount(pACS_ACCOUNT_ID);

    fetch crDescrAccount
     into vDescription;

    close crDescrAccount;

    return vDescription;
  end GetAccountDescriptionSummary;

  /**
  * Description
  *       Renvoie l'id du compte financier en fonction de son numéro
  */
  function GetFinancialAccountId(AccNumber in varchar2)
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    result ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if AccNumber is not null then
      select ACC.ACS_ACCOUNT_ID
        into result
        from ACS_ACCOUNT ACC
           , ACS_FINANCIAL_ACCOUNT FIN
       where ACC_NUMBER = AccNumber
         and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID;
    end if;

    return result;
  exception
    when others then
      return null;
  end GetFinancialAccountId;

  /**
  * Description
  *      Renvoie l'id du compte division en fonction de son numéro
  */
  function GetDivisionAccountId(AccNumber in varchar2)
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    result ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if AccNumber is not null then
      select ACC.ACS_ACCOUNT_ID
        into result
        from ACS_ACCOUNT ACC
           , ACS_Division_ACCOUNT FIN
       where ACC_NUMBER = AccNumber
         and ACC.ACS_ACCOUNT_ID = FIN.ACS_Division_ACCOUNT_ID;
    end if;

    return result;
  exception
    when others then
      return null;
  end GetDivisionAccountId;

  /**
  * Description
  *      Renvoie l'id du compte "Charge par nature" en fonction de son numéro
  */
  function GetCpnAccountId(AccNumber in varchar2)
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    result ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if AccNumber is not null then
      select ACC.ACS_ACCOUNT_ID
        into result
        from ACS_ACCOUNT ACC
           , ACS_Cpn_ACCOUNT FIN
       where ACC_NUMBER = AccNumber
         and ACC.ACS_ACCOUNT_ID = FIN.ACS_Cpn_ACCOUNT_ID;
    end if;

    return result;
  exception
    when others then
      return null;
  end GetCpnAccountId;

  /**
  * Description
  *      Renvoie l'id du compte "Charge par nature" lié à un compte financier
  */
  function GetCpnOfFinAcc(financial_account_id in number)
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    result ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if financial_account_id is not null then
      select ACS_CPN_ACCOUNT_ID
        into result
        from ACS_FINANCIAL_ACCOUNT FIN
       where ACS_FINANCIAL_ACCOUNT_ID = financial_account_id;
    end if;

    return result;
  exception
    when others then
      return null;
  end GetCpnOfFinAcc;

  /**
  * Description
  *       Renvoie l'id du compte "Centre d'analyse" en fonction de son numéro
  */
  function GetCdaAccountId(AccNumber in varchar2)
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    result ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if AccNumber is not null then
      select ACC.ACS_ACCOUNT_ID
        into result
        from ACS_ACCOUNT ACC
           , ACS_Cda_ACCOUNT FIN
       where ACC_NUMBER = AccNumber
         and ACC.ACS_ACCOUNT_ID = FIN.ACS_Cda_ACCOUNT_ID;
    end if;

    return result;
  exception
    when others then
      return null;
  end GetCdaAccountId;

  /**
  * Description
  *      Renvoie l'id du compte "Porteur de frais" en fonction de son numéro
  */
  function GetPfAccountId(AccNumber in varchar2)
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    result ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if AccNumber is not null then
      select ACC.ACS_ACCOUNT_ID
        into result
        from ACS_ACCOUNT ACC
           , ACS_Pf_ACCOUNT FIN
       where ACC_NUMBER = AccNumber
         and ACC.ACS_ACCOUNT_ID = FIN.ACS_Pf_ACCOUNT_ID;
    end if;

    return result;
  exception
    when others then
      return null;
  end GetPfAccountId;

  /**
  * Description
  *        Renvoie l'id du compte "Projet" en fonction de son numéro
  */
  function GetPjAccountId(AccNumber in varchar2)
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    result ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if AccNumber is not null then
      select ACC.ACS_ACCOUNT_ID
        into result
        from ACS_ACCOUNT ACC
           , ACS_Pj_ACCOUNT FIN
       where ACC_NUMBER = AccNumber
         and ACC.ACS_ACCOUNT_ID = FIN.ACS_Pj_ACCOUNT_ID;
    end if;

    return result;
  exception
    when others then
      return null;
  end GetPjAccountId;

  /**
  * Description
  *        Renvoie l'id du compte "Quantité" en fonction de son numéro
  */
  function GetQtyAccountId(AccNumber in varchar2)
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    vResult ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if AccNumber is not null then
      select ACC.ACS_ACCOUNT_ID
        into vResult
        from ACS_ACCOUNT ACC
           , ACS_QTY_UNIT QTY
       where ACC_NUMBER = AccNumber
         and QTY.ACS_QTY_UNIT_ID = ACC.ACS_ACCOUNT_ID;
    end if;

    return vResult;
  exception
    when others then
      return null;
  end;

  /**
  * Description
  *         Fonction qui effectue le déplacement de compte
  */
  function MovAccount(aAccount in varchar2, aOffset in varchar2)
    return varchar2
  is
  begin
    if aAccount is not null then
      if aOffset is not null then
        return lpad(to_char(to_number(aAccount) + nvl(to_number(aOffset), 0) ), greatest(length(aAccount), length(aOffset) ), '0');
      else
        return aAccount;
      end if;
    else
      return aOffset;
    end if;
  end MovAccount;

  /**
  * Description
  *    Procédure de modification des descriptifs du compte auxiliaire en cas de modification
  *    des infos de base PAC_PERSON, PAC_ADDRESS
  */
  procedure UpdatePersonAccountDescr(
    aPAC_PERSON_ID PAC_PERSON.PAC_PERSON_ID%type
  , aPER_NAME      PAC_PERSON.PER_NAME%type
  , aPER_FORENAME  PAC_PERSON.PER_FORENAME%type
  )
  is
    CUSTOMER_ACCOUNT_ID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
    SUPPLIER_ACCOUNT_ID PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    DESCRIPTION1        ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type;
    DESCRIPTION2        ACS_DESCRIPTION.DES_DESCRIPTION_LARGE%type;
  begin
    CUSTOMER_ACCOUNT_ID  := getAuxiliaryAccountId(aPAC_PERSON_ID, 1);
    SUPPLIER_ACCOUNT_ID  := getAuxiliaryAccountId(aPAC_PERSON_ID, 0);

    if    CUSTOMER_ACCOUNT_ID > 0
       or SUPPLIER_ACCOUNT_ID > 0 then
      GetPersonAccountDescr(aPAC_PERSON_ID, aPER_NAME, aPER_FORENAME, DESCRIPTION1, DESCRIPTION2);

      if CUSTOMER_ACCOUNT_ID > 0 then
        update ACS_DESCRIPTION
           set DES_DESCRIPTION_SUMMARY = DESCRIPTION1
             , DES_DESCRIPTION_LARGE = DESCRIPTION2
         where ACS_ACCOUNT_ID = CUSTOMER_ACCOUNT_ID;
      end if;

      if SUPPLIER_ACCOUNT_ID > 0 then
        update ACS_DESCRIPTION
           set DES_DESCRIPTION_SUMMARY = DESCRIPTION1
             , DES_DESCRIPTION_LARGE = DESCRIPTION2
         where ACS_ACCOUNT_ID = SUPPLIER_ACCOUNT_ID;
      end if;
    end if;
  end UpdatePersonAccountDescr;

  /**
  * Description
  *    Procédure de modification des descriptifs du compte auxiliaire en cas de modification
  *    des infos de base PAC_PERSON, PAC_ADDRESS
  **/
  procedure UpdateAddPersonAccountDescr(pPacPersonId PAC_PERSON.PAC_PERSON_ID%type, pZipCode PAC_ADDRESS.ADD_ZIPCODE%type, pCity PAC_ADDRESS.ADD_CITY%type)
  is
    vCustomerAccountId PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
    vSupplierAccountId PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
    vShortDescr        ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type;
    vLargeDescr        ACS_DESCRIPTION.DES_DESCRIPTION_LARGE%type;
  begin
    vCustomerAccountId  := GetAuxiliaryAccountId(pPacPersonId, 1);
    vSupplierAccountId  := GetAuxiliaryAccountId(pPacPersonId, 0);

    if    (vCustomerAccountId > 0)
       or (vSupplierAccountId > 0) then
      GetAddPersonAccountDescr(pPacPersonId, pZipCode, pCity, vShortDescr, vLargeDescr);

      if vCustomerAccountId > 0 then
        update ACS_DESCRIPTION
           set DES_DESCRIPTION_SUMMARY = vShortDescr
             , DES_DESCRIPTION_LARGE = vLargeDescr
         where ACS_ACCOUNT_ID = vCustomerAccountId;
      end if;

      if vSupplierAccountId > 0 then
        update ACS_DESCRIPTION
           set DES_DESCRIPTION_SUMMARY = vShortDescr
             , DES_DESCRIPTION_LARGE = vLargeDescr
         where ACS_ACCOUNT_ID = vSupplierAccountId;
      end if;
    end if;
  end UpdateAddPersonAccountDescr;

  /**
  * Description
  *    Retourne l'ID du compte auxiliaire client ou fournisseur
  */
  function getAuxiliaryAccountId(aPAC_PERSON_ID number, aCUSTOM number)
    return number
  is
    AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
  begin
    if aCUSTOM = 1 then
      select nvl(max(ACC.ACS_AUXILIARY_ACCOUNT_ID), 0)
        into AUXILIARY_ACCOUNT_ID
        from PAC_CUSTOM_PARTNER CUS
           , ACS_AUXILIARY_ACCOUNT ACC
       where CUS.PAC_CUSTOM_PARTNER_ID = aPAC_PERSON_ID
         and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_AUXILIARY_ACCOUNT_ID
         and ACC.C_TYPE_ACCOUNT = 'PRI';
    else
      select nvl(max(ACC.ACS_AUXILIARY_ACCOUNT_ID), 0)
        into AUXILIARY_ACCOUNT_ID
        from PAC_SUPPLIER_PARTNER SUP
           , ACS_AUXILIARY_ACCOUNT ACC
       where SUP.PAC_SUPPLIER_PARTNER_ID = aPAC_PERSON_ID
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_AUXILIARY_ACCOUNT_ID
         and ACC.C_TYPE_ACCOUNT = 'PRI';
    end if;

    return AUXILIARY_ACCOUNT_ID;
  end getAuxiliaryAccountId;

  /**
  * Description
  *    Ramène descriptions du compte
  */
  procedure GetPersonAccountDescr(
    pPersonId     in     PAC_PERSON.PAC_PERSON_ID%type
  , pPerName      in     PAC_PERSON.PER_NAME%type
  , pForeName     in     PAC_PERSON.PER_FORENAME%type
  , pSDescription out    ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type
  , pLDescription out    ACS_DESCRIPTION.DES_DESCRIPTION_LARGE%type
  )
  is
    vCity    PAC_ADDRESS.ADD_CITY%type;
    vZipCode PAC_ADDRESS.ADD_ZIPCODE%type;
  begin
    begin
      select nvl(max(ADD_ZIPCODE), '')
           , nvl(max(ADD_CITY), '')
        into vZipCode
           , vCity
        from PAC_ADDRESS
       where PAC_PERSON_ID = pPersonId
         and ADD_PRINCIPAL = 1;
    exception
      when no_data_found then
        select nvl(max(ADD_ZIPCODE), '')
             , nvl(max(ADD_CITY), '')
          into vZipCode
             , vCity
          from PAC_ADDRESS add
             , DIC_ADDRESS_TYPE DIC
         where DIC.DAD_DEFAULT = 1
           and add.DIC_ADDRESS_TYPE_ID = DIC.DIC_ADDRESS_TYPE_ID
           and add.PAC_PERSON_ID = pPersonId;
    end;

    if length(pPerName || ' ' || pForeName || ', ' || vZipCode || ' ' || vCity) <= 60 then
      if length(pForeName) > 0 then
        pSDescription  := pPerName || ' ' || pForeName || ', ' || vZipCode || ' ' || vCity;
      else
        pSDescription  := pPerName || ', ' || vZipCode || ' ' || vCity;
      end if;

      pLDescription  := '';
    else
      pSDescription  := substr(pPerName || ' ' || pForeName, 1, 60);
      pLDescription  := substr(vZipCode || ' ' || vCity, 1, 100);
    end if;
  end GetPersonAccountDescr;

  procedure GetAddPersonAccountDescr(
    pPersonId     in     PAC_PERSON.PAC_PERSON_ID%type
  , pZipCode      in     PAC_ADDRESS.ADD_ZIPCODE%type
  , pCity         in     PAC_ADDRESS.ADD_CITY%type
  , pSDescription out    ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type
  , pLDescription out    ACS_DESCRIPTION.DES_DESCRIPTION_LARGE%type
  )
  is
    vPerName  PAC_PERSON.PER_NAME%type;
    vForeName PAC_PERSON.PER_FORENAME%type;
  begin
    select PER_NAME
         , PER_FORENAME
      into vPerName
         , vForeName
      from PAC_PERSON
     where PAC_PERSON_ID = pPersonId;

    if length(vPerName || ' ' || vForeName || ', ' || pZipCode || ' ' || pCity) <= 60 then
      if length(vForeName) > 0 then
        pSDescription  := vPerName || ' ' || vForeName || ', ' || pZipCode || ' ' || pCity;
      else
        pSDescription  := vPerName || ', ' || pZipCode || ' ' || pCity;
      end if;

      pLDescription  := '';
    else
      pSDescription  := substr(vPerName || ' ' || vForeName, 1, 60);
      pLDescription  := substr(pZipCode || ' ' || pCity, 1, 100);
    end if;
  end GetAddPersonAccountDescr;

  /**
  * Description
  *     Recherche d'information sur le code TVA
  *       selon procedure Delphi TACS_TAX_CODE.GetTaxcode
  */
  procedure GetTaxCode(aTaxCodeId in number, aTaxeRate out number, aLiabledRate out number, aRoundAmount out number, aRoundType out varchar2, aDateRef in date)
  is
  begin
    select decode(ACS_TAX_CODE1_ID + ACS_TAX_CODE2_ID, null, nvl(VAT_RATE, TAX_RATE) )
         , decode(ACS_TAX_CODE1_ID + ACS_TAX_CODE2_ID, null, TAX_LIABLED_RATE)
         , decode(ACS_TAX_CODE1_ID + ACS_TAX_CODE2_ID, null, C_ROUND_TYPE)
         , decode(ACS_TAX_CODE1_ID + ACS_TAX_CODE2_ID, null, TAX_ROUNDED_AMOUNT)
      into aTaxeRate
         , aLiabledRate
         , aRoundType
         , aRoundAmount
      from ACS_TAX_CODE
         , ACS_VAT_RATE
     where ACS_TAX_CODE.ACS_TAX_CODE_ID = aTaxCodeID
       and ACS_TAX_CODE.ACS_TAX_CODE_ID = ACS_VAT_RATE.ACS_TAX_CODE_ID(+)
       and aDateRef between VAT_SINCE(+) and VAT_TO(+);
  exception
    when no_data_found then
      raise_application_error(-20077, 'PCS - Unexistant tax code');
  end GetTaxCode;

  /**
  * Description  Calcul du montant de TVA
  */
  function CalcVatAmount(
    aLiabledAmount      in number
  , aTaxCodeId          in number
  , aIE                 in varchar2
  , aDateRef            in date
  , aRound              in number
  , aCalcLiabledRate    in number default 1
  , aCalcDeductibleRate in number default 0
  )
    return number
  is
    vNetValueExcl      ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vNetValueIncl      ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vVatLiabledRate    ACS_TAX_CODE.TAX_LIABLED_RATE%type;
    vVatLiabledAmount  ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vVatRate           ACS_TAX_CODE.TAX_RATE%type;
    vVatTotalAmount    ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vVatDeductibleRate ACS_TAX_CODE.TAX_DEDUCTIBLE_RATE%type;
    vVatAmount         ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vTaxTransaction    ACS_ACCOUNT.ACC_INTEREST%type;
  begin
    if aTaxCodeId is not null then
      select nvl(ACC.ACC_INTEREST, 0)
        into vTaxTransaction
        from ACS_TAX_CODE TAX
           , ACS_ACCOUNT ACC
       where TAX.ACS_TAX_CODE_ID = aTaxCodeId
         and TAX.ACS_TAX_CODE_ID = ACC.ACS_ACCOUNT_ID;

      if vTaxTransaction = 0 then
        if aIE = 'I' then
          vNetValueIncl  := aLiabledAmount;
        else
          vNetValueExcl  := aLiabledAmount;
        end if;

        CalcVatAmount(aTaxCodeId        => aTaxCodeId
                    , aRefDate          => aDateRef
                    , aIncludedVat      => aIE
                    , aRoundAmount      => aRound
                    , aNetAmountExcl    => vNetValueExcl
                    , aNetAmountIncl    => vNetValueIncl
                    , aLiabledRate      => vVatLiabledRate
                    , aLiabledAmount    => vVatLiabledAmount
                    , aTaxeRate         => vVatRate
                    , aVatTotalAmount   => vVatTotalAmount
                    , aDeductibleRate   => vVatDeductibleRate
                    , aVatAmount        => vVatAmount
                     );

        if aCalcDeductibleRate = 0 then
          return vVatTotalAmount;
        else
          return vVatAmount;
        end if;
      else
        return 0;
      end if;
    end if;

    return 0;
  end CalcVatAmount;

  function CalcVatAmount(
    aNetAmount             ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant net HT
  , aTaxCodeId             ACS_TAX_CODE.ACS_TAX_CODE_ID%type   --Id code TVA
  , aIncludedVat           varchar2   --Indique si montant TTC (I) ou HT (E)
  , aVatRate               ACS_VAT_RATE.VAT_RATE%type   --Taux de TVA
  , aRoundAmount           number   --Indique si arrondi selon type d'arrondi du code (1) ou pas(0)
  , aCalcDeductibleRate in number default 0   --Indique si on demande le montant total ou décompté
  )
    return number
  is
    vRoundType      ACS_TAX_CODE.C_ROUND_TYPE%type;
    vRoundedAmount  ACS_TAX_CODE.TAX_ROUNDED_AMOUNT%type;
    vTaxTransaction ACS_ACCOUNT.ACC_INTEREST%type;
    vLiabledRate    ACS_TAX_CODE.TAX_LIABLED_RATE%type;
    vDeductibleRate ACS_TAX_CODE.TAX_DEDUCTIBLE_RATE%type;
    vTaxCode1Id     ACS_TAX_CODE.ACS_TAX_CODE1_ID%type;
    vTaxCode2Id     ACS_TAX_CODE.ACS_TAX_CODE2_ID%type;
    vVatAmount      ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vCoeff          number(1);
  begin
    vVatAmount  := 0;

    if aTaxCodeId is not null then
      begin
        select TAX.TAX_LIABLED_RATE
             , nvl(TAX.TAX_DEDUCTIBLE_RATE, 0)
             , decode(aRoundAmount, 1, TAX.C_ROUND_TYPE, 2, TAX.C_ROUND_TYPE_DOC, 3, TAX.C_ROUND_TYPE_DOC_FOO, '0')
             , decode(aRoundAmount, 1, TAX.TAX_ROUNDED_AMOUNT, 2, TAX.TAX_ROUNDED_AMOUNT_DOC, 3, TAX.TAX_ROUNDED_AMOUNT_DOC_FOO, TAX.TAX_ROUNDED_AMOUNT)
             , nvl(ACC.ACC_INTEREST, 0)
             , TAX.ACS_TAX_CODE1_ID
             , TAX.ACS_TAX_CODE2_ID
          into vLiabledRate
             , vDeductibleRate
             , vRoundType
             , vRoundedAmount
             , vTaxTransaction
             , vTaxCode1Id
             , vTaxCode2Id
          from ACS_TAX_CODE TAX
             , ACS_ACCOUNT ACC
         where TAX.ACS_TAX_CODE_ID = aTaxCodeId
           and ACC.ACS_ACCOUNT_ID(+) = TAX.ACS_TAX_CODE_ID;
      exception
        when no_data_found then
          raise_application_error(-20077, 'PCS - Unexistant tax code');
      end;

      -- Si c'est une taxe pure, vTaxTransaction = 1
      --  => vCoeff = 0   => montant HT = montant TTC = TVA
      -- sinon vTaxTransaction = 0
      --  => vCoeff = 1   => calcul classique
      vCoeff  := 1 - vTaxTransaction;

      /* Si le code TVA est un code d'auto-taxation (càd que les champs
         ACS_TAX_CODE.ACS_TAX_CODE1_ID et ACS_TAX_CODE.ACS_TAX_CODE2_ID sont
         différents de null), le montant de TVA et le montant de TVA décompté
         sont égaux à zéro. */
      if     (vTaxCode1Id is not null)
         and (vTaxCode2Id is not null) then
        vVatAmount  := 0;
      else
        -- Calcul du montant TVA
        if upper(aIncludedVat) = 'I' then
          vVatAmount  := (aNetAmount /(1 * vCoeff +(aVatRate / 100) ) ) *(vLiabledRate / 100) *(aVatRate / 100);
        else
          vVatAmount  := aNetAmount *(vLiabledRate / 100) *(aVatRate / 100);
        end if;

        if aCalcDeductibleRate = 1 then
          vVatAmount  := vVatAmount *(vDeductibleRate / 100);
        end if;

        case vRoundType
          when 1 then
            vVatAmount  := RoundNear(vVatAmount, 0.05, 0);
          when 2 then
            vVatAmount  := RoundNear(vVatAmount, vRoundedAmount, -1);
          when 3 then
            vVatAmount  := RoundNear(vVatAmount, vRoundedAmount, 0);
          when 4 then
            vVatAmount  := RoundNear(vVatAmount, vRoundedAmount, 1);
          else
            vVatAmount  := round(vVatAmount, 2);
        end case;
      end if;
    end if;

    return vVatAmount;
  end CalcVatAmount;

  procedure CalcVatAmount(
    aTaxCodeId            ACS_TAX_CODE.ACS_TAX_CODE_ID%type   --Id code TVA
  , aRefDate              ACS_VAT_RATE.VAT_SINCE%type   --Date de référence
  , aIncludedVat          varchar2   --Indique si montant TTC (I) ou HT (E)
  , aRoundAmount          number   --Indique si arrondi selon type d'arrondi du code (1) ou pas(0)
  , aNetAmountExcl in out ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant net HT
  , aNetAmountIncl in out ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant net TTC
  , aVatAmount     out    ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant TVA
  )
  is
    vVatLiabledRate    ACS_TAX_CODE.TAX_LIABLED_RATE%type;
    vVatLiabledAmount  ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vVatRate           ACS_TAX_CODE.TAX_RATE%type;
    vVatTotalAmount    ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vVatDeductibleRate ACS_TAX_CODE.TAX_DEDUCTIBLE_RATE%type;
  begin
    CalcVatAmount(aTaxCodeId        => aTaxCodeId
                , aRefDate          => aRefDate
                , aIncludedVat      => aIncludedVat
                , aRoundAmount      => aRoundAmount
                , aNetAmountExcl    => aNetAmountExcl
                , aNetAmountIncl    => aNetAmountIncl
                , aLiabledRate      => vVatLiabledRate
                , aLiabledAmount    => vVatLiabledAmount
                , aTaxeRate         => vVatRate
                , aVatTotalAmount   => vVatTotalAmount
                , aDeductibleRate   => vVatDeductibleRate
                , aVatAmount        => aVatAmount
                 );
  end CalcVatAmount;

  procedure CalcVatAmount(
    aTaxCodeId             ACS_TAX_CODE.ACS_TAX_CODE_ID%type   --Id code TVA
  , aRefDate               ACS_VAT_RATE.VAT_SINCE%type   --Date de référence
  , aIncludedVat           varchar2   --Indique si montant TTC (I) ou HT (E)
  , aRoundAmount           number   --Indique si arrondi selon type d'arrondi du code (1) ou pas(0)
  , aNetAmountExcl  in out ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant net HT
  , aNetAmountIncl  in out ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant net TTC
  , aVatTotalAmount out    ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant TVA
  , aVatAmount      out    ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant TVA
  )
  is
    vVatLiabledRate    ACS_TAX_CODE.TAX_LIABLED_RATE%type;
    vVatLiabledAmount  ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vVatRate           ACS_TAX_CODE.TAX_RATE%type;
    vVatDeductibleRate ACS_TAX_CODE.TAX_DEDUCTIBLE_RATE%type;
  begin
    CalcVatAmount(aTaxCodeId        => aTaxCodeId
                , aRefDate          => aRefDate
                , aIncludedVat      => aIncludedVat
                , aRoundAmount      => aRoundAmount
                , aNetAmountExcl    => aNetAmountExcl
                , aNetAmountIncl    => aNetAmountIncl
                , aLiabledRate      => vVatLiabledRate
                , aLiabledAmount    => vVatLiabledAmount
                , aTaxeRate         => vVatRate
                , aVatTotalAmount   => aVatTotalAmount
                , aDeductibleRate   => vVatDeductibleRate
                , aVatAmount        => aVatAmount
                 );
  end CalcVatAmount;

  procedure CalcVatAmount(
    aTaxCodeId             ACS_TAX_CODE.ACS_TAX_CODE_ID%type   --Id code TVA
  , aRefDate               ACS_VAT_RATE.VAT_SINCE%type   --Date de référence
  , aIncludedVat           varchar2   --Indique si montant TTC (I) ou HT (E)
  , aRoundAmount           number   --Indique si arrondi selon type d'arrondi du code (1) ou pas(0)
  , aNetAmountExcl  in out ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant net HT
  , aNetAmountIncl  in out ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant net TTC
  , aLiabledRate    out    ACS_TAX_CODE.TAX_LIABLED_RATE%type   --% CA soumis
  , aLiabledAmount  out    ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant soumis
  , aTaxeRate       out    ACS_TAX_CODE.TAX_RATE%type   --Taux
  , aVatTotalAmount out    ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant Total TVA
  , aDeductibleRate out    ACS_TAX_CODE.TAX_DEDUCTIBLE_RATE%type   --%TVA déductible
  , aVatAmount      out    ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type   --Montant TVA
  )
  is
    vRoundType      ACS_TAX_CODE.C_ROUND_TYPE%type;
    vRoundedAmount  ACS_TAX_CODE.TAX_ROUNDED_AMOUNT%type;
    vTaxCode1Id     ACS_TAX_CODE.ACS_TAX_CODE1_ID%type;
    vTaxCode2Id     ACS_TAX_CODE.ACS_TAX_CODE2_ID%type;
    vTaxTransaction ACS_ACCOUNT.ACC_INTEREST%type;
    vCoeff          number(1);
  begin
    aVatTotalAmount  := 0;
    aVatAmount       := 0;
    vCoeff           := 0;

    if aTaxCodeId is not null then
      begin
        select nvl(VAT.VAT_RATE, TAX.TAX_RATE)
             , TAX.TAX_LIABLED_RATE
             , nvl(TAX.TAX_DEDUCTIBLE_RATE, 0)
             , decode(aRoundAmount, 1, TAX.C_ROUND_TYPE, 2, TAX.C_ROUND_TYPE_DOC, 3, TAX.C_ROUND_TYPE_DOC_FOO, '0')
             , decode(aRoundAmount, 1, TAX.TAX_ROUNDED_AMOUNT, 2, TAX.TAX_ROUNDED_AMOUNT_DOC, 3, TAX.TAX_ROUNDED_AMOUNT_DOC_FOO, TAX.TAX_ROUNDED_AMOUNT)
             , nvl(ACC.ACC_INTEREST, 0)
             , TAX.ACS_TAX_CODE1_ID
             , TAX.ACS_TAX_CODE2_ID
          into aTaxeRate
             , aLiabledRate
             , aDeductibleRate
             , vRoundType
             , vRoundedAmount
             , vTaxTransaction
             , vTaxCode1Id
             , vTaxCode2Id
          from ACS_TAX_CODE TAX
             , ACS_VAT_RATE VAT
             , ACS_ACCOUNT ACC
         where TAX.ACS_TAX_CODE_ID = aTaxCodeId
           and ACC.ACS_ACCOUNT_ID(+) = TAX.ACS_TAX_CODE_ID
           and VAT.ACS_TAX_CODE_ID(+) = TAX.ACS_TAX_CODE_ID
           and aRefDate between VAT.VAT_SINCE(+) and VAT.VAT_TO(+);
      exception
        when no_data_found then
          raise_application_error(-20077, 'PCS - Unexistant tax code');
      end;

      -- Si c'est une taxe pure, vTaxTransaction = 1
      --  => vCoeff = 0   => montant HT = montant TTC = TVA
      -- sinon vTaxTransaction = 0
      --  => vCoeff = 1   => calcul classique
      vCoeff          := 1 - vTaxTransaction;

      -- Calcul logique des montants HT et TTC non utilisé pour des raisons
      -- historiques (utilisation du % soumis comme % déductible). Réactivé par la tâche DEVLOG-13646
      if upper(aIncludedVat) = 'I' then
        aNetAmountExcl  := aNetAmountIncl /(1 * vCoeff + (aLiabledRate / 100) *(aTaxeRate / 100) );
      --else
      --  aNetAmountIncl := aNetAmountExcl * (1 * vCoeff  + (aLiabledRate / 100) * (aTaxeRate / 100));
      end if;

/*
      -- Calcul "ProConcept" des montants HT et TTC. Plus utilisé depuis la modification DEVLOG-13646
      if upper(aIncludedVat) = 'I' then
        aNetAmountExcl  := aNetAmountIncl /(1 * vCoeff +(aTaxeRate / 100) );
      --else
      --  aNetAmountIncl := aNetAmountExcl * (1 * vCoeff + (aTaxeRate / 100));
      end if; */

      -- Calcul du montant soumis
      aLiabledAmount  := aNetAmountExcl *(aLiabledRate / 100);

      /* Si le code TVA est un code d'auto-taxation (càd que les champs
         ACS_TAX_CODE.ACS_TAX_CODE1_ID et ACS_TAX_CODE.ACS_TAX_CODE2_ID sont
         différents de null), le montant de TVA et le montant de TVA décompté
         sont égaux à zéro. */
      if     (vTaxCode1Id is not null)
         and (vTaxCode2Id is not null) then
        aVatTotalAmount  := 0;
        aVatAmount       := 0;
      else
        -- Calcul des montants TVA
        aVatTotalAmount  := aLiabledAmount *(aTaxeRate / 100);

        if aDeductibleRate = 100 then
          case vRoundType
            when 1 then
              aVatTotalAmount  := RoundNear(aVatTotalAmount, 0.05, 0);
            when 2 then
              aVatTotalAmount  := RoundNear(aVatTotalAmount, vRoundedAmount, -1);
            when 3 then
              aVatTotalAmount  := RoundNear(aVatTotalAmount, vRoundedAmount, 0);
            when 4 then
              aVatTotalAmount  := RoundNear(aVatTotalAmount, vRoundedAmount, 1);
            else
              aVatTotalAmount  := round(aVatTotalAmount, 2);
          end case;

          aVatAmount  := aVatTotalAmount;
        else
          aVatAmount  := aVatTotalAmount *(aDeductibleRate / 100);

          case vRoundType
            when 1 then
              aVatTotalAmount  := RoundNear(aVatTotalAmount, 0.05, 0);
              aVatAmount       := RoundNear(aVatAmount, 0.05, 0);
            when 2 then
              aVatTotalAmount  := RoundNear(aVatTotalAmount, vRoundedAmount, -1);
              aVatAmount       := RoundNear(aVatAmount, vRoundedAmount, -1);
            when 3 then
              aVatTotalAmount  := RoundNear(aVatTotalAmount, vRoundedAmount, 0);
              aVatAmount       := RoundNear(aVatAmount, vRoundedAmount, 0);
            when 4 then
              aVatTotalAmount  := RoundNear(aVatTotalAmount, vRoundedAmount, 1);
              aVatAmount       := RoundNear(aVatAmount, vRoundedAmount, 1);
            else
              aVatTotalAmount  := round(aVatTotalAmount, 2);
              aVatAmount       := round(aVatAmount, 2);
          end case;
        end if;
      end if;
    end if;

    -- Mise à jour du montant HT ou TTC
    if upper(aIncludedVat) = 'I' then
      aNetAmountExcl  := aNetAmountIncl - vCoeff * aVatTotalAmount;

      --
      -- Garantit un montant soumis identique au montant net exclu si le taux de soumission est de 100%.
      --
      -- Dans ce contexte, on peut donc admettre que montant net ht = montant soumis.
      -- Le montant TVA étant arrondi à 2 décimal dans tous les cas (précision du champ), il est possible
      -- que l'application du calcul montant ttc - montant TVA donne un résultat différent que le calcul du montant net ht initial :
      --
      --   << montant net ht = montant net ttc - montant TVA >>
      --
      --   peut être différent de
      --
      --   << montant net ht = montant net ttc /(1 * coeff + (taux de soumission / 100) * (taux TVA / 100) )) >>
      --
      if     (aLiabledRate = 100)
         and (aNetAmountExcl <> aLiabledAmount) then
        aLiabledAmount  := aNetAmountExcl;
      end if;
    else
      aNetAmountIncl  := aNetAmountExcl + vCoeff * aVatTotalAmount;
    end if;
  end CalcVatAmount;

  /**
  * Description
  *    Renvoie la montant de base du cour de change de l'EURO
  */
  function GetBasePriceEUR(aDate in date, aCurrency_id in number, aRateType in number default 1)
    return number
  is
    ExchangeRate       ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePrice          ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    BaseChange         number(1);
    FixedRateEUR_MB    number(1);
    FixedRateEUR_ME    number(1);
    RateExchangeEUR_MB ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    RateExchangeEUR_ME ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    Flag               number(1);
  begin
    -- Initialisation des paramètres par référence comme valeur par défaut }
    ExchangeRate  := 0;
    BasePrice     := 0;
    -- Recherche du cours et de l'unité de base }
    Flag          :=
      GetRateOfExchangeEUR(aCurrency_id
                         , aRateType
                         , aDate
                         , ExchangeRate
                         , BasePrice
                         , BaseChange
                         , RateExchangeEUR_ME
                         , FixedRateEUR_ME
                         , RateExchangeEUR_MB
                         , FixedRateEUR_MB
                          );

    if     (FixedRateEUR_ME = 1)
       and (FixedRateEUR_MB = 1) then
      BasePrice  := 0;
    end if;

    return BasePrice;
  end GetBasePriceEUR;

  /**
  * Description
  *    Renvoie le cour et le diviseur du change par rapport à la monnaie de base
  */
  procedure GetExchangeRate(aDate in date, aCurrency_id in number, aRateType in number default 1, aExchangeRate out number, aBasePrice out number)
  is
    cursor ex_rate(aCurrencyId number, aDate date, aRateType number)
    is
      select   decode(aRateType
                    , 1, PCU_DAYLY_PRICE
                    , 2, PCU_VALUATION_PRICE
                    , 3, PCU_INVENTORY_PRICE
                    , 4, PCU_CLOSING_PRICE
                    , 5, PCU_INVOICE_PRICE
                    , 6, PCU_VAT_PRICE
                    , 0
                     )
             , PCU_BASE_PRICE
          from ACS_PRICE_CURRENCY
         where ACS_AND_CURR_ID = gLocalCurrencyId
           and ACS_BETWEEN_CURR_ID = aCurrencyId
           and trunc(PCU_START_VALIDITY) <= trunc(aDate)
      order by PCU_START_VALIDITY desc;

    cursor ex_rate_inv(aCurrencyId number, aDate date, aRateType number)
    is
      select   PCU_BASE_PRICE /
               decode(aRateType
                    , 1, PCU_DAYLY_PRICE
                    , 2, PCU_VALUATION_PRICE
                    , 3, PCU_INVENTORY_PRICE
                    , 4, PCU_CLOSING_PRICE
                    , 5, PCU_INVOICE_PRICE
                    , 6, PCU_VAT_PRICE
                    , 0
                     )
             , 1
          from ACS_PRICE_CURRENCY
         where ACS_AND_CURR_ID = aCurrencyId
           and ACS_BETWEEN_CURR_ID = gLocalCurrencyId
           and trunc(PCU_START_VALIDITY) <= trunc(aDate)
      order by PCU_START_VALIDITY desc;
  begin
    -- Initialisation des paramètres par référence comme valeur par défaut }
    aExchangeRate  := 1;
    aBasePrice     := 1;

    if (aCurrency_id <> gLocalCurrencyId) then
      -- Recherche du cours et de l'unité de base }
      open ex_rate(aCurrency_Id, aDate, aRateType);

      fetch ex_rate
       into aExchangeRate
          , aBasePrice;

      if not ex_rate%found then
        open ex_rate_inv(aCurrency_Id, aDate, aRateType);

        fetch ex_rate_inv
         into aExchangeRate
            , aBasePrice;

        close ex_rate_inv;
      end if;

      close ex_rate;
    end if;
  end GetExchangeRate;

  /**
  * Description
  *    Renvoie le cour de change
  */
  function GetExchangeRate(aDate in date, aToCurrency_id in number, aRateType in number default 1)
    return number
  is
    result    ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type;
    basePrice ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type;
  begin
    GetExchangeRate(aDate, aToCurrency_id, aRateType, result, basePrice);
    return result;
  end GetExchangeRate;

  /**
  * Description
  *    Renvoie le diviseur du cour de change
  */
  function GetBasePrice(aDate in date, aToCurrency_id in number)
    return number
  is
    exchangeRate ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type;
    result       ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type;
  begin
    GetExchangeRate(aDate, aToCurrency_id, 1, exchangeRate, result);
    return result;
  end GetBasePrice;

  /**
  * Description
  *    Renvoie le cour du change en tenant compte de l'EURO
  */
  function GetExchangeRateEUR(aDate in date, aCurrency_id in number, aRateType in number default 1)
    return number
  is
    ExchangeRate       ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePrice          ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    BaseChange         number(1);
    FixedRateEUR_MB    number(1);
    FixedRateEUR_ME    number(1);
    RateExchangeEUR_MB ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    RateExchangeEUR_ME ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    Flag               number(1);
  begin
    -- Initialisation des paramètres par référence comme valeur par défaut }
    ExchangeRate  := 0;
    BasePrice     := 0;
    -- Recherche du cours et de l'unité de base }
    Flag          :=
      GetRateOfExchangeEUR(aCurrency_id
                         , aRateType
                         , aDate
                         , ExchangeRate
                         , BasePrice
                         , BaseChange
                         , RateExchangeEUR_ME
                         , FixedRateEUR_ME
                         , RateExchangeEUR_MB
                         , FixedRateEUR_MB
                          );

    if     (FixedRateEUR_ME = 1)
       and (FixedRateEUR_MB = 1) then
      ExchangeRate  := 0;
    else
      -- Si le cours est en monnaie étrangère, alors il faut le convertir en monnaie base }
      if BaseChange = 0 then
        ExchangeRate  :=( (BasePrice * BasePrice) / ExchangeRate);
      end if;
    end if;

    return ExchangeRate;
  end GetExchangeRateEUR;

  /**
  * Description
  *    Renvoie les infos sur le cour de change
  */
  function ExtractRate(aCurrency_id in number, aRateType in number, aDate in date, aExchangeRate out number, aBasePrice out number, aBaseChange out number)
    return number
  is
    cursor PriceCurrency(aFinCurrency_id number)
    is
      select   ACS_BETWEEN_CURR_ID
             , PCU_START_VALIDITY
             , PCU_BASE_PRICE
             , PCU_DAYLY_PRICE
             , PCU_VALUATION_PRICE
             , PCU_INVENTORY_PRICE
             , PCU_CLOSING_PRICE
             , PCU_INVOICE_PRICE
             , PCU_VAT_PRICE
          from ACS_PRICE_CURRENCY
             , ACS_FINANCIAL_CURRENCY
         where (   ACS_BETWEEN_CURR_ID = aFinCurrency_id
                or ACS_AND_CURR_ID = aFinCurrency_id)
           and ACS_FINANCIAL_CURRENCY_ID = aFinCurrency_id
           and PCU_START_VALIDITY <= aDate
           and FIN_LOCAL_CURRENCY = 0
      order by PCU_START_VALIDITY desc;

    PriceCurrency_tuple PriceCurrency%rowtype;
  begin
    aBaseChange  := 1;

    open PriceCurrency(aCurrency_id);

    fetch PriceCurrency
     into PriceCurrency_tuple;

    if PriceCurrency%found then
      -- Mode d'expression du cours -> exprimé en monnaie de base ou non }
      if aCurrency_id <> PriceCurrency_tuple.ACS_BETWEEN_CURR_ID then   -- Monnaie étrangère
        aBaseChange  := 0;
      end if;

      -- Assignation de l'unité de base }
      aBasePrice  := PriceCurrency_tuple.PCU_BASE_PRICE;

      -- Assignation du cours de change }
      if aRateType = 1 then
        aExchangeRate  := PriceCurrency_tuple.PCU_DAYLY_PRICE;
      elsif aRateType = 2 then
        aExchangeRate  := PriceCurrency_tuple.PCU_VALUATION_PRICE;
      elsif aRateType = 3 then
        aExchangeRate  := PriceCurrency_tuple.PCU_INVENTORY_PRICE;
      elsif aRateType = 4 then
        aExchangeRate  := PriceCurrency_tuple.PCU_CLOSING_PRICE;
      elsif aRateType = 5 then
        aExchangeRate  := PriceCurrency_tuple.PCU_INVOICE_PRICE;
      elsif aRateType = 6 then
        aExchangeRate  := PriceCurrency_tuple.PCU_VAT_PRICE;
      end if;

      if    (aExchangeRate is null)
         or (aExchangeRate = 0) then
        aExchangeRate  := PriceCurrency_tuple.PCU_DAYLY_PRICE;
      end if;

      close PriceCurrency;

      -- Assignation de la valeur de retour de la fonction }
      return 1;   -- Il existe au moins un cours
    else
      -- Monnaie de base }
      aBasePrice     := 0;
      aExchangeRate  := 0;

      close PriceCurrency;

      return 0;
    end if;
  end ExtractRate;

------------------------------------------
  function ExtractRateEUR(
    aCurrency_id     in     number
  , aRateType        in     number
  , aDate            in     date
  , aExchangeRate    out    number
  , aBasePrice       out    number
  , aBaseChange      out    number
  , aRateExchangeEUR in out number
  , aBasePriceEUR    out    number
  , aEuroChange      in out number
  )
    return number
  is
    cursor PriceCurrency(aFinCurrency_id number)
    is
      select   ACS_BETWEEN_CURR_ID
             , PCU_START_VALIDITY
             , PCU_BASE_PRICE
             , PCU_DAYLY_PRICE
             , PCU_VALUATION_PRICE
             , PCU_INVENTORY_PRICE
             , PCU_CLOSING_PRICE
             , PCU_INVOICE_PRICE
             , PCU_VAT_PRICE
             , FIN_EURO_FROM
             , FIN_EURO_RATE
          from ACS_PRICE_CURRENCY
             , ACS_FINANCIAL_CURRENCY
         where (   ACS_BETWEEN_CURR_ID = aFinCurrency_id
                or ACS_AND_CURR_ID = aFinCurrency_id)
           and ACS_FINANCIAL_CURRENCY_ID = aFinCurrency_id
           and PCU_START_VALIDITY <= aDate
           and FIN_LOCAL_CURRENCY = 0
      order by PCU_START_VALIDITY desc;

    PriceCurrency_tuple PriceCurrency%rowtype;
    FinEuroFrom         ACS_FINANCIAL_CURRENCY.FIN_EURO_FROM%type;
    Flag                number(1);
  begin
    aBaseChange       := 1;
    aEuroChange       := 0;
    aRateExchangeEUR  := null;
    aBasePriceEUR     := null;
    aBasePrice        := 0;
    aExchangeRate     := 0;

    open PriceCurrency(aCurrency_id);

    fetch PriceCurrency
     into PriceCurrency_tuple;

    if PriceCurrency%found then
      if     (PriceCurrency_tuple.FIN_EURO_FROM is not null)
         and (PriceCurrency_tuple.FIN_EURO_FROM <= aDate) then
        aRateExchangeEUR  := PriceCurrency_tuple.FIN_EURO_RATE;
        aBasePriceEUR     := 1;
        aEuroChange       := 1;
      else
        -- Mode d'expression du cours -> exprimé en monnaie de base ou non }
        if aCurrency_id <> PriceCurrency_tuple.ACS_BETWEEN_CURR_ID then   -- Monnaie étrangère
          aBaseChange  := 0;
        end if;

        -- Assignation de l'unité de base }
        aBasePrice  := PriceCurrency_tuple.PCU_BASE_PRICE;

        -- Assignation du cours de change }
        if aRateType = 1 then
          aExchangeRate  := PriceCurrency_tuple.PCU_DAYLY_PRICE;
        elsif aRateType = 2 then
          aExchangeRate  := PriceCurrency_tuple.PCU_VALUATION_PRICE;
        elsif aRateType = 3 then
          aExchangeRate  := PriceCurrency_tuple.PCU_INVENTORY_PRICE;
        elsif aRateType = 4 then
          aExchangeRate  := PriceCurrency_tuple.PCU_CLOSING_PRICE;
        elsif aRateType = 5 then
          aExchangeRate  := PriceCurrency_tuple.PCU_INVOICE_PRICE;
        elsif aRateType = 6 then
          aExchangeRate  := PriceCurrency_tuple.PCU_VAT_PRICE;
        end if;

        if    (aExchangeRate is null)
           or (aExchangeRate = 0) then
          aExchangeRate  := PriceCurrency_tuple.PCU_DAYLY_PRICE;
        end if;

        close PriceCurrency;

        -- Assignation de la valeur de retour de la fonction }
        return 1;   -- Il existe au moins un cours
      end if;
    else
      -- Recherche si subdivision Euro }
      select FIN_EURO_FROM
           , FIN_EURO_RATE
        into FinEuroFrom
           , aRateExchangeEUR
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aCurrency_id;

      if FinEuroFrom is not null then
        if FinEuroFrom <= aDate then
          aBasePriceEUR  := 1;
          aEuroChange    := 1;
        end if;
      else
        -- Aucun cours
        return 0;
      end if;
    end if;

    -- Recherche du cours Euro -> CHF
    if aEuroChange = 1 then
      Flag  := ExtractRate(GetEuroCurrency, aRateType, aDate, aExchangeRate, aBasePrice, aBaseChange);
    end if;

    close PriceCurrency;

    return 1;
  end ExtractRateEUR;

-----------------------------
  function GetRateOfExchangeEUR(
    aCurrencyID         in     number
  , aSortRate           in     number
  , aDate               in     date
  , aRateExchange       out    number
  , aBasePrice          out    number
  , aBaseChange         out    number
  , aRateExchangeEUR_ME out    number
  , aFixedRateEUR_ME    in out number
  , aRateExchangeEUR_MB out    number
  , aFixedRateEUR_MB    in out number
  , aLogistic           in     number default 0
  )
    return number
  is
    cursor PriceCurrency(cCurrencyId number, cBaseCurrId number, cDate date)
    is
      select   ACS_BETWEEN_CURR_ID
             , PCU_START_VALIDITY
             , PCU_BASE_PRICE
             , PCU_DAYLY_PRICE
             , PCU_VALUATION_PRICE
             , PCU_INVENTORY_PRICE
             , PCU_CLOSING_PRICE
             , PCU_INVOICE_PRICE
             , PCU_VAT_PRICE
          from ACS_PRICE_CURRENCY
             , ACS_FINANCIAL_CURRENCY
         where (    (    ACS_BETWEEN_CURR_ID = cCurrencyId
                     and ACS_AND_CURR_ID = cBaseCurrId)
                or (    ACS_BETWEEN_CURR_ID = cBaseCurrId
                    and ACS_AND_CURR_ID = cCurrencyId) )
           and ACS_FINANCIAL_CURRENCY_ID = cCurrencyId
           and PCU_START_VALIDITY <= cDate
           and FIN_LOCAL_CURRENCY = 0
      order by PCU_START_VALIDITY desc;

    PriceCurrency_tuple PriceCurrency%rowtype;

    function CheckManagedPrices(aSortRate number)
      return boolean
    is
    begin
      if not aSortRate = 1 then
        if not CACHED_MANAGEDPRICES.initialized then
          InitManagedPrices;
        end if;

        if aSortRate = 2 then
          return CACHED_MANAGEDPRICES.PCU_VALUATION_PRICE = true;
        elsif aSortRate = 3 then
          return CACHED_MANAGEDPRICES.PCU_INVENTORY_PRICE = true;
        elsif aSortRate = 4 then
          return CACHED_MANAGEDPRICES.PCU_CLOSING_PRICE = true;
        elsif aSortRate = 5 then
          return CACHED_MANAGEDPRICES.PCU_INVOICE_PRICE = true;
        elsif aSortRate = 6 then
          return CACHED_MANAGEDPRICES.PCU_VAT_PRICE = true;
        else
          return true;
        end if;
      end if;
    end;
  begin
    --{ Initialisation de la valeur de retour par défaut }
    aBaseChange       := 1;

    if aLogistic = 0 then
      aBasePrice           := 0;
      aRateExchange        := 0;
      aRateExchangeEUR_MB  := 0;
      aRateExchangeEUR_ME  := 0;
    else
      aBasePrice           := 1;
      aRateExchange        := 1;
      aRateExchangeEUR_MB  := 1;
      aRateExchangeEUR_ME  := 1;
    end if;

    aFixedRateEUR_ME  := 1;
    aFixedRateEUR_MB  := 1;

    begin
      select FIN_EURO_RATE
        into aRateExchangeEUR_MB
        from ACS_FINANCIAL_CURRENCY
       where FIN_LOCAL_CURRENCY = 1
         and FIN_EURO_FROM <= aDate;
    exception
      when no_data_found then
        aFixedRateEUR_MB  := 0;
    end;

    begin
      select FIN_EURO_RATE
        into aRateExchangeEUR_ME
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aCurrencyID
         and FIN_EURO_FROM <= aDate;
    exception
      when no_data_found then
        aFixedRateEUR_ME  := 0;
    end;

    if not(    (    aFixedRateEUR_MB = 1
                and aFixedRateEUR_ME = 1)
           or (     (aFixedRateEUR_MB = 1)
               and (aCurrencyID = GetEuroCurrency) ) ) then
      --{ Assignation de la valeur au paramètre }
      if aFixedRateEUR_MB = 1 then
        open PriceCurrency(aCurrencyID, GetEuroCurrency, aDate);
      elsif     (aFixedRateEUR_MB = 0)
            and (aFixedRateEUR_ME = 1) then
        open PriceCurrency(GetEuroCurrency, gLocalCurrencyId, aDate);
      elsif     (aFixedRateEUR_MB = 0)
            and (aFixedRateEUR_ME = 0) then
        open PriceCurrency(aCurrencyID, gLocalCurrencyId, aDate);
      end if;

      fetch PriceCurrency
       into PriceCurrency_tuple;

      if PriceCurrency%found then
        --{ Mode d'expression du cours -> exprimé en monnaie de base ou non }
        if    (PriceCurrency_tuple.ACS_BETWEEN_CURR_ID = gLocalCurrencyId)
           or (     (PriceCurrency_tuple.ACS_BETWEEN_CURR_ID = GetEuroCurrency)
               and (aFixedRateEUR_MB = 1) ) then   -- Monnaie de étrangère
          aBaseChange  := 0;
        end if;

        --{ Assignation de l'unité de base }
        aBasePrice  := PriceCurrency_tuple.PCU_BASE_PRICE;

        --{ Assignation du cours de change }
        if aSortRate = 1 then
          aRateExchange  := PriceCurrency_tuple.PCU_DAYLY_PRICE;
        elsif aSortRate = 2 then
          aRateExchange  := PriceCurrency_tuple.PCU_VALUATION_PRICE;
        elsif aSortRate = 3 then
          aRateExchange  := PriceCurrency_tuple.PCU_INVENTORY_PRICE;
        elsif aSortRate = 4 then
          aRateExchange  := PriceCurrency_tuple.PCU_CLOSING_PRICE;
        elsif aSortRate = 5 then
          aRateExchange  := PriceCurrency_tuple.PCU_INVOICE_PRICE;
        elsif aSortRate = 6 then
          aRateExchange  := PriceCurrency_tuple.PCU_VAT_PRICE;
        end if;

        if     aSortRate != 1
           and not CheckManagedPrices(aSortRate) then
          --Pas de gestion de ce cours selon config ACS_EXCHANGE_RATE
          aRateExchange  := 0;
        end if;

        if    (aRateExchange is null)
           or (aRateExchange = 0) then
          aRateExchange  := PriceCurrency_tuple.PCU_DAYLY_PRICE;
        end if;

        close PriceCurrency;

        --{ Assignation de la valeur de retour de la fonction }
        return 1;   -- Il existe au moins un cours
      else
        close PriceCurrency;

        --{ Assignation de la valeur de retour de la fonction }
        return 0;
      end if;
    else
      return 1;
    end if;
  end GetRateOfExchangeEUR;

  /**
  * Description
  *    conversion de montants dans des monnaies différentes
  */
  procedure ConvertAmount(
    aAmount        in     number
  , aFromFinCurrId in     number
  , aToFinCurrId   in     number
  , aDate          in     date
  , aExchangeRate  in     number
  , aBasePrice     in     number
  , aRound         in     number
  , aAmountEUR     in out number
  , aAmountConvert in out number
  , aRateType      in     number default 1
  )
  is
    ExchangeRateFound  number(1);
    BaseChange         number(1);
    FixedRateEUR_ME    number(1);
    FixedRateEUR_MB    number(1);
    RateExchange       ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type;
    BasePrice          ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type;
    RateExchangeEUR_MB ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    RateExchangeEUR_ME ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
  begin
    aAmountConvert  := aAmount;

    if aFromFinCurrId = GetEuroCurrency then
      aAmountEUR  := aAmount;
    else
      aAmountEUR  := 0;
    end if;

    if aFromFinCurrId <> aToFinCurrId then
      if aFromFinCurrId = gLocalCurrencyId then
        --{*** Conversion MB -> ME ***}
        ExchangeRateFound  :=
          GetRateOfExchangeEUR(aToFinCurrId
                             , aRateType
                             , aDate
                             , RateExchange
                             , BasePrice
                             , BaseChange
                             , RateExchangeEUR_ME
                             , FixedRateEUR_ME
                             , RateExchangeEUR_MB
                             , FixedRateEUR_MB
                              );

        if     (aExchangeRate <> 0)
           and (aBasePrice <> 0) then
          RateExchange  := aExchangeRate;
          BasePrice     := aBasePrice;
          BaseChange    := 1;
        end if;

        if FixedRateEUR_MB = 1 then
          aAmountEUR  := aAmount / RateExchangeEUR_MB;
        elsif    (FixedRateEUR_ME = 1)
              or (aToFinCurrId = GetEuroCurrency) then
          if BaseChange = 1 then
            aAmountEUR  := aAmount / RateExchange * BasePrice;
          else
            aAmountEUR  := aAmount * RateExchange / BasePrice;
          end if;
        end if;

        if aToFinCurrId = GetEuroCurrency then
          aAmountConvert  := aAmountEUR;
        elsif     (FixedRateEUR_ME = 0)
              and (FixedRateEUR_MB = 0) then
          if BaseChange = 1 then
            aAmountConvert  := aAmount / RateExchange * BasePrice;
          else
            aAmountConvert  := aAmount * RateExchange / BasePrice;
          end if;
        else
          if FixedRateEUR_ME = 1 then
            aAmountConvert  := aAmountEUR * RateExchangeEUR_ME;
          else
            if BaseChange = 1 then
              aAmountConvert  := aAmountEUR / RateExchange * BasePrice;
            else
              aAmountConvert  := aAmountEUR * RateExchange / BasePrice;
            end if;
          end if;
        end if;
      else
        --{*** Conversion ME -> MB ***}
        ExchangeRateFound  :=
          GetRateOfExchangeEUR(aFromFinCurrId
                             , aRateType
                             , aDate
                             , RateExchange
                             , BasePrice
                             , BaseChange
                             , RateExchangeEUR_ME
                             , FixedRateEUR_ME
                             , RateExchangeEUR_MB
                             , FixedRateEUR_MB
                              );

        if     (aExchangeRate <> 0)
           and (aBasePrice <> 0) then
          RateExchange  := aExchangeRate;
          BasePrice     := aBasePrice;
          BaseChange    := 1;
        end if;

        if FixedRateEUR_ME = 1 then
          aAmountEUR  := aAmount / RateExchangeEUR_ME;
        elsif    (FixedRateEUR_MB = 1)
              or (aToFinCurrId = GetEuroCurrency) then
          if BaseChange = 1 then
            aAmountEUR  := aAmount * RateExchange / BasePrice;
          else
            aAmountEUR  := aAmount / RateExchange * BasePrice;
          end if;
        end if;

        if aToFinCurrId = GetEuroCurrency then
          aAmountConvert  := aAmountEUR;
        elsif     (FixedRateEUR_ME = 0)
              and (FixedRateEUR_MB = 0) then
          if BaseChange = 1 then
            aAmountConvert  := aAmount * RateExchange / BasePrice;
          else
            aAmountConvert  := aAmount / RateExchange * BasePrice;
          end if;
        else
          if FixedRateEUR_MB = 1 then
            aAmountConvert  := aAmountEUR * RateExchangeEUR_MB;
          else
            if BaseChange = 1 then
              aAmountConvert  := aAmountEUR * RateExchange / BasePrice;
            else
              aAmountConvert  := aAmountEUR / RateExchange * BasePrice;
            end if;
          end if;
        end if;
      end if;
    elsif aFromFinCurrId = gLocalCurrencyId then
      ExchangeRateFound  :=
        GetRateOfExchangeEUR(aFromFinCurrId
                           , aRateType
                           , aDate
                           , RateExchange
                           , BasePrice
                           , BaseChange
                           , RateExchangeEUR_ME
                           , FixedRateEUR_ME
                           , RateExchangeEUR_MB
                           , FixedRateEUR_MB
                            );

      if FixedRateEUR_MB = 1 then
        aAmountEUR  := aAmount / RateExchangeEUR_MB;
      end if;
    end if;

    --{*** Arrondi selon table des monnaies ***}
    if aRound in(1, 2) then
      aAmountConvert  := RoundAmount(aAmountConvert, aToFinCurrId, aRound);
    end if;

    aAmountEUR      := RoundNear(aAmountEUR, CONST_RoundAmountEUR, CONST_RoundTypeEUR);
  exception
    when zero_divide then
      aAmountEUR      := 0;
      aAmountConvert  := 0;
  end ConvertAmount;

  /**
  * Description
  *   conversion de montants dans des monnaies différentes (sous forme de fonction pour utilisation dans vue)
  */
  function ConvertAmountForView(
    aAmount        in number
  , aFromFinCurrId in number
  , aToFinCurrId   in number
  , aDate          in date
  , aExchangeRate  in number
  , aBasePrice     in number
  , aRound         in number
  , aRateType      in number default 1
  )
    return number
  is
    AmountEUR     number(20, 6);
    AmountConvert number(20, 6);
  begin
    ConvertAmount(aAmount, aFromFinCurrId, aToFinCurrId, aDate, aExchangeRate, aBasePrice, aRound, AmountEUR, AmountConvert, aRateType);
    return AmountConvert;
  end ConvertAmountForView;

-----------------------------------------
  function ConvertAmountForViewCrystal(
    aAmount        in number
  , aFromFinCurrId in number
  , aToFinCurrId   in number
  , aDate          in varchar2
  , aExchangeRate  in number
  , aBasePrice     in number
  , aRound         in number
  , aRateType      in number default 1
  )
    return number
  is
    AmountEUR     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    AmountConvert ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
  begin
    ConvertAmount(aAmount, aFromFinCurrId, aToFinCurrId, to_date(aDate, 'DD.MM.YYYY'), aExchangeRate, aBasePrice, aRound, AmountEUR, AmountConvert, aRateType);
    return AmountConvert;
  end ConvertAmountForViewCrystal;

  /**
  * Description
  *   conversion de montants en Euro (sous forme de fonction pour utilisation dans vue)
  */
  function ConvertAmountEurForView(
    aAmount        in number
  , aFromFinCurrId in number
  , aToFinCurrId   in number
  , aDate          in date
  , aExchangeRate  in number
  , aBasePrice     in number
  , aRound         in number
  , aRateType      in number default 1
  )
    return number
  is
    AmountEUR     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    AmountConvert ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
  begin
    ConvertAmount(aAmount, aFromFinCurrId, aToFinCurrId, aDate, aExchangeRate, aBasePrice, aRound, AmountEUR, AmountConvert, aRateType);
    return AmountEUR;
  end ConvertAmountEurForView;

--------------------
  function RoundAmount(aAmount number, aACS_FINANCIAL_CURRENCY_ID number, aRoundTyp number default 1)
    return number   -- 1: Arrondi finannce 2: Arrondi logistique
  is
    RoundType  ACS_FINANCIAL_CURRENCY.C_ROUND_TYPE%type;
    RoundValue ACS_FINANCIAL_CURRENCY.FIN_ROUNDED_AMOUNT%type;
  begin
    begin
      select decode(aRoundTyp, 2, C_ROUND_TYPE_DOC, C_ROUND_TYPE)
           , decode(aRoundTyp, 2, FIN_ROUNDED_AMOUNT_DOC, FIN_ROUNDED_AMOUNT)
        into RoundType
           , RoundValue
        from ACS_FINANCIAL_CURRENCY CUR
       where CUR.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;
    exception
      when others then
        RoundType  := 0;
    end;

    if RoundType = '0' then
      return aAmount;   -- Pas d'arrondi
    elsif RoundType = '1' then
      return RoundNear(aAmount, 0.05, 0);   -- Arrondi commercial
    elsif RoundType = '2' then
      return RoundNear(aAmount, RoundValue, -1);   -- Arrondi inférieur
    elsif RoundType = '3' then
      return RoundNear(aAmount, RoundValue, 0);   -- Arrondi au plus près
    elsif RoundType = '4' then
      return RoundNear(aAmount, RoundValue, 1);   -- Arrondi supérieur
    else
      return aAmount;   -- Si type arrondi n'existe pas -> Arrondi 2 décim.
    end if;
  end RoundAmount;

  /**
  * Description
  *   retourne l'id de la monnaie Euro (ACS_FINANCIAL_CURRENCY)
  */
  function GetEuroCurrency
    return ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  is
    EuroCurrId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    select max(ACS_FINANCIAL_CURRENCY_ID)
      into EuroCurrId
      from ACS_FINANCIAL_CURRENCY CUR
         , PCS.PC_CURR PCU
     where CUR.PC_CURR_ID = PCU.PC_CURR_ID
       and PCU.CURRENCY = 'EUR';

    if EuroCurrId is null then
      return 0;
    else
      return EuroCurrId;
    end if;
  end GetEuroCurrency;

  /**
  * Description
  *    Renvoie l'ID de l'exercice le plus gand différent du status 'PLA'
  */
  function GetMaxNoExerciceId
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
    MaxNoExerciceId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
  begin
    select max(ACS_FINANCIAL_YEAR_ID)
      into MaxNoExerciceId
      from ACS_FINANCIAL_YEAR
     where FYE_NO_EXERCICE = (select max(FYE_NO_EXERCICE)
                                from ACS_FINANCIAL_YEAR
                               where C_STATE_FINANCIAL_YEAR <> 'PLA');

    if MaxNoExerciceId is null then
      return 0;
    else
      return MaxNoExerciceId;
    end if;
  end GetMaxNoExerciceId;

  /**
  * Description
  *    fonction permettant de connaître si un compte financier est tenu en ME
  */
  function isFinAccountInME(aACS_FINANCIAL_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
    return number
  is
    --  Paramètre de sortie :
    --    0 = pas tenu en ME
    --    1 = tenu en ME
    result number;
  begin
    select count(1)
      into result
      from ACS_FIN_ACCOUNT_S_FIN_CURR SFC
         , ACS_FINANCIAL_CURRENCY CUR
     where SFC.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
       and SFC.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
       and CUR.FIN_LOCAL_CURRENCY <> 1;

    if result > 0 then
      return 1;
    else
      return 0;
    end if;
  end isFinAccountInME;

  /**
  * Description
  *    Renvoie le plus petit numéro de compte CPN lié à une imput. financière
  */
  function GetCpnAccNumOfImputation(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
    return ACS_ACCOUNT.ACC_NUMBER%type
  is
    CpnAccNum ACS_ACCOUNT.ACC_NUMBER%type;
  begin
    select min(ACC_NUMBER)
      into CpnAccNum
      from ACS_ACCOUNT
         , ACT_MGM_IMPUTATION
     where ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID
       and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID;

    return CpnAccNum;
  end GetCpnAccNumOfImputation;

  /**
  * Description
  *   Renvoie la description du compte  auxiliaire
  */
  function GetPer_short_Name(aACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type)
    return ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type
  is
    result       ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type;
    CTypeAccount varchar2(10);
    Sub_Set      varchar2(10);
  begin
    -- RECHERCHE DU SOUS-ENSEMBLE
    Sub_Set  := ACS_FUNCTION.GetSubSetOfAccount(aACS_AUXILIARY_ACCOUNT_ID);

    if    (sub_set = 'REC')
       or (sub_set = 'PAY') then
      --recherche le type du compte auxiliaire
      select AUX.C_TYPE_ACCOUNT
        into CTypeAccount
        from ACS_AUXILIARY_ACCOUNT AUX
       where AUX.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID;

      if CTypeAccount = 'PRI' then
        if sub_set = 'REC' then
          select max(PAC.PER_SHORT_NAME)
            into result
            from PAC_PERSON PAC
               , PAC_CUSTOM_PARTNER PAR
           where PAR.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
             and PAR.PAC_CUSTOM_PARTNER_ID = PAC.PAC_PERSON_ID
             and PAR.C_PARTNER_CATEGORY = '1';
        else   --sub_set='PAY'
          select max(PAC.PER_SHORT_NAME)
            into result
            from PAC_PERSON PAC
               , PAC_SUPPLIER_PARTNER PAR
           where PAR.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
             and PAR.PAC_SUPPLIER_PARTNER_ID = PAC.PAC_PERSON_ID
             and PAR.C_PARTNER_CATEGORY = '1';
        end if;
      elsif CTypeAccount = 'PART' then
        result  := upper(GetAccountDescriptionSummary(aACS_AUXILIARY_ACCOUNT_ID) );
      elsif CTypeAccount = 'GRP' then
        if sub_set = 'REC' then
          select max(PAC.PER_SHORT_NAME)
            into result
            from PAC_PERSON PAC
               , PAC_CUSTOM_PARTNER PAR
           where PAR.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
             and PAR.PAC_CUSTOM_PARTNER_ID = PAC.PAC_PERSON_ID
             and PAR.C_PARTNER_CATEGORY = '2';
        else   --sub_set='PAY'
          select max(PAC.PER_SHORT_NAME)
            into result
            from PAC_PERSON PAC
               , PAC_SUPPLIER_PARTNER PAR
           where PAR.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
             and PAR.PAC_SUPPLIER_PARTNER_ID = PAC.PAC_PERSON_ID
             and PAR.C_PARTNER_CATEGORY = '2';
        end if;
      else   --Cas où un nv. Descode à été ajouté
        result  := '';
      end if;
    else   --le sub_set n'est pas de type auxiliaire!
      result  := '';
    end if;

    return result;
  end GetPer_short_Name;

  /**
  * Description
  *   Renvoie le nom du partenaire selon compte auxiliaire
  */
  function GetAuxAccOwnerName(pAuxiliaryAccId ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type)
    return PAC_PERSON.PER_NAME%type
  is
    vResult PAC_PERSON.PER_NAME%type;
    vSubSet ACS_SUB_SET.C_SUB_SET%type;
    vAccTyp ACS_AUXILIARY_ACCOUNT.C_TYPE_ACCOUNT%type;
  begin
    -- Recherche du sous-ensemble
    vSubSet  := ACS_FUNCTION.GetSubSetOfAccount(pAuxiliaryAccId);

    if    (vSubSet = 'REC')
       or (vSubSet = 'PAY') then
      --recherche le type du compte auxiliaire
      select AUX.C_TYPE_ACCOUNT
        into vAccTyp
        from ACS_AUXILIARY_ACCOUNT AUX
       where AUX.ACS_AUXILIARY_ACCOUNT_ID = pAuxiliaryAccId;

      if vAccTyp = 'PRI' then
        if vSubSet = 'REC' then
          select max(PER.PER_NAME)
            into vResult
            from PAC_PERSON PER
               , PAC_CUSTOM_PARTNER CUS
           where CUS.ACS_AUXILIARY_ACCOUNT_ID = pAuxiliaryAccId
             and PER.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
             and CUS.C_PARTNER_CATEGORY = '1';
        else
          select max(PER.PER_NAME)
            into vResult
            from PAC_PERSON PER
               , PAC_SUPPLIER_PARTNER SUP
           where SUP.ACS_AUXILIARY_ACCOUNT_ID = pAuxiliaryAccId
             and PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
             and SUP.C_PARTNER_CATEGORY = '1';
        end if;
      elsif vAccTyp = 'PART' then
        vResult  := upper(GetAccountDescriptionSummary(pAuxiliaryAccId) );
      elsif vAccTyp = 'GRP' then
        if vSubSet = 'REC' then
          select max(PER.PER_NAME)
            into vResult
            from PAC_PERSON PER
               , PAC_CUSTOM_PARTNER CUS
           where CUS.ACS_AUXILIARY_ACCOUNT_ID = pAuxiliaryAccId
             and PER.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
             and CUS.C_PARTNER_CATEGORY = '2';
        else
          select max(PER.PER_NAME)
            into vResult
            from PAC_PERSON PER
               , PAC_SUPPLIER_PARTNER SUP
           where SUP.ACS_AUXILIARY_ACCOUNT_ID = pAuxiliaryAccId
             and PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
             and SUP.C_PARTNER_CATEGORY = '2';
        end if;
      else
        vResult  := '';
      end if;
    else
      vResult  := '';
    end if;

    return vResult;
  end GetAuxAccOwnerName;

  /**
  * Description
  *   Contrôle si la monnaie est une monnaie IN de l'EURO
  */
  function IsFinCurrInEuro(aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type, aDate ACS_FINANCIAL_CURRENCY.FIN_EURO_FROM%type)
    return number
  is
    RateExchangeEUR ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    result          number(1);
  begin
    begin
      select FIN_EURO_RATE
        into RateExchangeEUR
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
         and FIN_EURO_FROM <= aDate;
    exception
      when no_data_found then
        result  := 0;
    end;

    if RateExchangeEUR is null then
      result  := 0;
    else
      result  := 1;
    end if;

    return result;
  end IsFinCurrInEuro;

------------------------------
  function CalcRateOfExchangeEUR(
    aAmountMB                  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aAmountME                  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aDate                      ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aBasePrice                 ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aRateType                  number default 1
  )
    return number
  is
    ExchangeRate       ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePrice          ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    BaseChange         number(1);
    FixedRateEUR_MB    number(1);
    FixedRateEUR_ME    number(1);
    RateExchangeEUR_MB ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    RateExchangeEUR_ME ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    Flag               number(1);
    AmountEUR          ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
  begin
    -- Recherche du cours et de l'unité de base }
    Flag  :=
      GetRateOfExchangeEUR(aACS_FINANCIAL_CURRENCY_ID
                         , aRateType
                         , aDate
                         , ExchangeRate
                         , BasePrice
                         , BaseChange
                         , RateExchangeEUR_ME
                         , FixedRateEUR_ME
                         , RateExchangeEUR_MB
                         , FixedRateEUR_MB
                          );

    if aBasePrice <> 0 then
      BasePrice   := aBasePrice;
      BaseChange  := 1;
    end if;

    if     (aACS_FINANCIAL_CURRENCY_ID = GetEuroCurrency)
       and (FixedRateEUR_MB = 1) then
      ExchangeRate  := 0;
    elsif     (FixedRateEUR_ME = 1)
          and (FixedRateEUR_MB = 1) then
      ExchangeRate  := 0;
    elsif     (aAmountMB != 0)
          and (aAmountME != 0) then
      if     (FixedRateEUR_ME = 0)
         and (FixedRateEUR_MB = 0) then
        if BaseChange = 1 then
          ExchangeRate  := aAmountMB * BasePrice / aAmountME;
        else
          ExchangeRate  := BasePrice * aAmountME / aAmountMB;
        end if;
      elsif     (FixedRateEUR_ME = 0)
            and (FixedRateEUR_MB = 1) then
        AmountEUR  := aAmountMB / RateExchangeEUR_MB;

        if BaseChange = 1 then
          ExchangeRate  := AmountEUR * BasePrice / aAmountME;
        else
          ExchangeRate  := BasePrice / aAmountME * AmountEUR;
        end if;
      elsif     (FixedRateEUR_ME = 1)
            and (FixedRateEUR_MB = 0) then
        AmountEUR  := aAmountME / RateExchangeEUR_ME;

        if BaseChange = 1 then
          ExchangeRate  := aAmountMB * BasePrice / AmountEUR;
        else
          ExchangeRate  := BasePrice * AmountEUR / aAmountMB;
        end if;
      end if;
    end if;

    return ExchangeRate;
  end CalcRateOfExchangeEUR;

  /**
  * Description
  *   Retourne le taux d'un Code TVA à une date donnée
  */
  function GetVatRate(aACS_TAX_CODE_ID ACS_TAX_CODE.ACS_TAX_CODE_ID%type, aDate varchar2)
    return ACS_TAX_CODE.TAX_RATE%type
  is
    TransactionDate date;
    TaxRate         ACS_TAX_CODE.TAX_RATE%type;
    VatRate         ACS_VAT_RATE.VAT_RATE%type;
    ResultRate      ACS_TAX_CODE.TAX_RATE%type;
  begin
    begin
      TransactionDate  := to_date(aDate, 'yyyymmdd');
    exception
      when others then
        TransactionDate  := null;
    end;

    select TAX_RATE
         , VAT_RATE
      into TaxRate
         , VatRate
      from ACS_VAT_RATE VAT
         , ACS_TAX_CODE TAX
     where TAX.ACS_TAX_CODE_ID = aACS_TAX_CODE_ID
       and TAX.ACS_TAX_CODE_ID = VAT.ACS_TAX_CODE_ID(+)
       and TransactionDate between VAT_SINCE(+) and VAT_TO(+);

    if VatRate is null then
      ResultRate  := TaxRate;
    else
      ResultRate  := VatRate;
    end if;

    return ResultRate;
  end GetVatRate;

  /**
  * Description
  *        Recherche de la description de la méthode de paiement
  */
  function GetPayMethDescr(pay_meth_id acs_description.acs_payment_method_id%type, lang_id acs_description.pc_lang_id%type)
    return varchar2
  is
    result acs_description.des_description_summary%type;
  begin
    select des_description_summary
      into result
      from acs_description
     where acs_payment_method_id = pay_meth_id
       and pc_lang_id + 0 = lang_id;

    return result;
  exception
    when no_data_found then
      return ' ';
  end GetPayMethDescr;

  /**
  * Description
  *       fonction retournant True si le compte est de type autotaxation
  */
  function IsSelfTax(aTaxCodeId in number, aTaxCode1Id out number, aTaxCode2Id out number)
    return boolean
  is
  begin
    -- Recherche des comptes d'auto-taxation
    select ACS_TAX_CODE1_ID
         , ACS_TAX_CODE2_ID
      into aTaxCode1Id
         , aTaxCode2Id
      from ACS_TAX_CODE
     where ACS_TAX_CODE_ID = aTaxCodeId;

    -- Si les deux comptes sont renseignés alors on a affaire à un compte d'auto-taxation
    return(    aTaxCode1Id is not null
           and aTaxCode2Id is not null);
  exception
    when no_data_found then
      -- Si aucun compte ne correspond à l'Id passé en paramètre, on renvoie False
      return false;
  end IsSelfTax;

  /**
  * Description
  *       fonction retournant True si le compte est de type TAXE PURE
  */
  function IsInterest(aTaxCodeId in number)
    return boolean
  is
    interest number(1);
  begin
    select ACC_INTEREST
      into interest
      from ACS_ACCOUNT
     where ACS_ACCOUNT_ID = aTaxCodeId;

    return(interest = 1);
  exception
    when no_data_found then
      -- Si aucun compte ne correspond à l'Id passé en paramètre, on renvoie False
      return false;
  end IsInterest;

  /**
  * Description
  *   revoie la monnaie d'un code taxe
  */
  function GetCurrencyOfVAT(aTaxCodeId in number)
    return ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  is
    CurrVAT ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    select ACS_FINANCIAL_CURRENCY_ID
      into CurrVAT
      from ACS_VAT_DET_ACCOUNT
         , ACS_TAX_CODE
     where ACS_TAX_CODE.ACS_VAT_DET_ACCOUNT_ID = ACS_VAT_DET_ACCOUNT.ACS_VAT_DET_ACCOUNT_ID
       and ACS_TAX_CODE.ACS_TAX_CODE_ID = aTaxCodeId;

    return CurrVAT;
  exception
    when no_data_found then
      return 0;
  end GetCurrencyOfVAT;

  function GetAccountNumber(aACS_ACCOUNT_ID in ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
    return ACS_ACCOUNT.ACC_NUMBER%type
  is
    result ACS_ACCOUNT.ACC_NUMBER%type;
  begin
    select ACC.ACC_NUMBER
      into result
      from ACS_ACCOUNT ACC
     where ACC.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID;

    return result;
  exception
    when others then
      return null;
  end GetAccountNumber;

  /**
  * Description
  *       Renvoie la description dans la langue utilisateur de la table ACS_DESCRIPTION selon l'id donné
  */
  function GetDescription(pIdName varchar2, pIdValue ACS_DESCRIPTION.ACS_DESCRIPTION_ID%type)
    return ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type
  is
    vResult ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type;
  begin
    begin
      if pIdName = 'ACS_ACCOUNT_ID' then
        select DES_DESCRIPTION_SUMMARY
          into vResult
          from ACS_DESCRIPTION
         where ACS_ACCOUNT_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_ACCOUNTING_ID' then
        select DES_DESCRIPTION_SUMMARY
          into vResult
          from ACS_DESCRIPTION
         where ACS_ACCOUNTING_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_SUB_SET_ID' then
        select DES_DESCRIPTION_SUMMARY
          into vResult
          from ACS_DESCRIPTION
         where ACS_SUB_SET_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_FINANCIAL_YEAR_ID' then
        select DES_DESCRIPTION_SUMMARY
          into vResult
          from ACS_DESCRIPTION
         where ACS_FINANCIAL_YEAR_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_PAYMENT_METHOD_ID' then
        select DES_DESCRIPTION_SUMMARY
          into vResult
          from ACS_DESCRIPTION
         where ACS_PAYMENT_METHOD_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_PICTURE_ID' then
        select DES_DESCRIPTION_SUMMARY
          into vResult
          from ACS_DESCRIPTION
         where ACS_PICTURE_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_VAT_DET_ACCOUNT_ID' then
        select DES_DESCRIPTION_SUMMARY
          into vResult
          from ACS_DESCRIPTION
         where ACS_VAT_DET_ACCOUNT_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_BVR_REFERENCE_ID' then
        select DES_DESCRIPTION_SUMMARY
          into vResult
          from ACS_DESCRIPTION
         where ACS_BVR_REFERENCE_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_PERIOD_ID' then
        select DES_DESCRIPTION_SUMMARY
          into vResult
          from ACS_DESCRIPTION
         where ACS_PERIOD_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      end if;
    exception
      when others then
        vResult  := '';
    end;

    return vResult;
  end GetDescription;

  /**
  * Description
  *       Renvoie la description longue dans la langue utilisateur de la table ACS_DESCRIPTION selon l'id donné
  */
  function GetLargeDescription(pIdName varchar2, pIdValue ACS_DESCRIPTION.ACS_DESCRIPTION_ID%type)
    return ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY%type
  is
    vResult ACS_DESCRIPTION.DES_DESCRIPTION_LARGE%type;
  begin
    begin
      if pIdName = 'ACS_ACCOUNT_ID' then
        select DES_DESCRIPTION_LARGE
          into vResult
          from ACS_DESCRIPTION
         where ACS_ACCOUNT_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_ACCOUNTING_ID' then
        select DES_DESCRIPTION_LARGE
          into vResult
          from ACS_DESCRIPTION
         where ACS_ACCOUNTING_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_SUB_SET_ID' then
        select DES_DESCRIPTION_LARGE
          into vResult
          from ACS_DESCRIPTION
         where ACS_SUB_SET_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_FINANCIAL_YEAR_ID' then
        select DES_DESCRIPTION_LARGE
          into vResult
          from ACS_DESCRIPTION
         where ACS_FINANCIAL_YEAR_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_PAYMENT_METHOD_ID' then
        select DES_DESCRIPTION_LARGE
          into vResult
          from ACS_DESCRIPTION
         where ACS_PAYMENT_METHOD_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_PICTURE_ID' then
        select DES_DESCRIPTION_LARGE
          into vResult
          from ACS_DESCRIPTION
         where ACS_PICTURE_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_VAT_DET_ACCOUNT_ID' then
        select DES_DESCRIPTION_LARGE
          into vResult
          from ACS_DESCRIPTION
         where ACS_VAT_DET_ACCOUNT_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_BVR_REFERENCE_ID' then
        select DES_DESCRIPTION_LARGE
          into vResult
          from ACS_DESCRIPTION
         where ACS_BVR_REFERENCE_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      elsif pIdName = 'ACS_PERIOD_ID' then
        select DES_DESCRIPTION_LARGE
          into vResult
          from ACS_DESCRIPTION
         where ACS_PERIOD_ID = pIdValue
           and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;
      end if;
    exception
      when others then
        vResult  := '';
    end;

    return vResult;
  end GetLargeDescription;

  /**
  * Description Recherche si le compte passé en paramètre 1 fait partie de la classification passée en paramètre 2
  */
  function IsFinAccInClassif(
    pACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_aCCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pCLASSIFICATION_ID        CLASSIF_FLAT.CLASSIFICATION_ID%type
  )
    return number
  is
    result number(1);
  begin
    select decode(nvl(max(CLASSIF_LEAF_ID), 0), 0, 0, 1)
      into result
      from CLASSIF_FLAT
     where CLASSIFICATION_ID = pCLASSIFICATION_ID
       and CLASSIF_LEAF_ID = pACS_FINANCIAL_ACCOUNT_ID;

    return result;
  end;

   /**
  * Description
  *    Test si une monnaie est autorisée pour une date donnée
  */
  function IsValidCurrency(
    aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aFIN_VALID_TO              ACS_FINANCIAL_CURRENCY.FIN_VALID_TO%type default sysdate
  )
    return number
  is
    vFIN_VALID_DATE ACS_FINANCIAL_CURRENCY.FIN_VALID_TO%type;
  begin
    vFIN_VALID_DATE  := null;

    select min(CUR.FIN_VALID_TO)
      into vFIN_VALID_DATE
      from ACS_FINANCIAL_CURRENCY CUR
     where CUR.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID;

    if vFIN_VALID_DATE is null then
      return 1;
    elsif trunc(vFIN_VALID_DATE) >= trunc(aFIN_VALID_TO) then
      return 1;
    else
      return 0;
    end if;
  end IsValidCurrency;

  /**
  * function AccDescr4Exercice
  * Description
  *   Recherche la description du compte pour l'exercice comptable
  */
  function AccDescr4Exercice(
    pACS_ACCOUNT_ID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pPC_LANG_ID            PCS.PC_LANG.PC_LANG_ID%type
  , pDescriptionType       number
  , pDate                  date
  , pACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type default 0
  )
    return ACS_ACCOUNT_DESCR_YEAR.ADY_DESCRIPTION_LARGE%type
  is
    vDescrID ACS_ACCOUNT_DESCR_YEAR.ACS_ACCOUNT_DESCR_YEAR_ID%type   default 0;
    vResult  ACS_ACCOUNT_DESCR_YEAR.ADY_DESCRIPTION_LARGE%type;
    vDate    ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
  begin
    /*
      Si l'ID exercice financier est renseigné,
       - remplacer la date passée en paramètre par la date de début de l'exercice renseigné
      Puis:
       - recherche de la description correspondant à la date
       - si pas trouvé, recherche de la première description précédant la date renseignée
      Si pas trouvé de descriptions ci-dessus, alors recherche dans la table ACS_DESCRIPTION
    */
    if pACS_FINANCIAL_YEAR_ID > 0 then
      --Recherche avec l'ID de l'exercice comptable sans tenir compte de la date
      select nvl(max(trunc(YEA.FYE_START_DATE) ), trunc(sysdate) )
        into vDate
        from ACS_FINANCIAL_YEAR YEA
       where YEA.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID;
    else
      vDate  := trunc(pDate);
    end if;

    --Recherche d'une description avec la date
    for tplDescription in (select   nvl(ADY.ACS_ACCOUNT_DESCR_YEAR_ID, 0) ACS_ACCOUNT_DESCR_YEAR_ID
                                  , decode(pDescriptionType, 1, ADY.ADY_DESCRIPTION_SUMMARY, 2, ADY.ADY_DESCRIPTION_LARGE, '') ADY_DESCRIPTION
                               from ACS_ACCOUNT_DESCR_YEAR ADY
                                  , ACS_FINANCIAL_YEAR YEA
                              where ADY.ACS_ACCOUNT_ID = pACS_ACCOUNT_ID
                                and ADY.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
                                and ADY.PC_LANG_ID = pPC_LANG_ID
                                and (    (    vDate >= YEA.FYE_START_DATE
                                          and vDate <= YEA.FYE_END_DATE)
                                     or (vDate >= YEA.FYE_END_DATE) )
                           order by FYE_NO_EXERCICE desc) loop
      vDescrID  := tplDescription.ACS_ACCOUNT_DESCR_YEAR_ID;
      vResult   := tplDescription.ADY_DESCRIPTION;
      exit;
    end loop;

    if vDescrID = 0 then
      select decode(pDescriptionType, 1, nvl(max(DES.DES_DESCRIPTION_SUMMARY), ''), 2, nvl(max(DES.DES_DESCRIPTION_LARGE), ''), '')
        into vResult
        from ACS_DESCRIPTION DES
           , ACS_ACCOUNT ACC
       where ACC.ACS_ACCOUNT_ID = pACS_ACCOUNT_ID
         and DES.ACS_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
         and DES.PC_LANG_ID = pPC_LANG_ID;
    end if;

    return vResult;
  end AccDescr4Exercice;

  /**
  * Description  Création des exercice de planification sur la base de l'exercice financier de référence
  *              dans l'intervalle donnée
  **/
  procedure FillPlanExercise(pStartYear ACS_PLAN_YEAR.PYE_NO_EXERCISE%type, pEndYear ACS_PLAN_YEAR.PYE_NO_EXERCISE%type)
  is
  begin
    ACS_I_PRC_FINANCIAL_YEAR.FillPlanExercise(pStartYear, pEndYear);
  end FillPlanExercise;

  /**
  * function MODULO_DINISO_7064
  * Description
  *   calcul du modulo selon norme DIN
  */
  function MODULO_DINISO_7064(pRefBvr in varchar2)
    return varchar2
  is
    cMod constant number(2)    := 10;
    vNextMod      number(2);
    vResult       number(2);
    vTmp          varchar2(12);
  begin
    /*
    chiffre départ = 10
    Lui ajouter le premier chiffre du numéro BVR
    Faire Modulo 10
    Faire * 2
    Faire modulo 11
    ce résultat sera utilisé comme référence pour le 2ème passage
    */
    vTmp     := lpad(pRefBvr, 12, 0);   --Garanti 12 caractères comptés depuis la gauche ou rempli avec des 0
    vResult  := 10;

    for vCpt in 1 .. length(vTmp) loop
      vresult  := (vResult + to_number(substr(vTmp, vCpt, 1) ) ) mod cMod;

      if vResult = 0 then
        vResult  := cMod;
      end if;

      vResult  := (vResult * 2) mod 11;
    end loop;

    vResult  := (11 - vResult) mod cMod;
    return vTmp || vResult;
  end MODULO_DINISO_7064;

  /**
  * function FinAccountBalanceDisplay
  * Description
  *   déterminer le type de compte (charge / produit, resp. au débit / au crédit) si flag C_BALANCE_DISPLAY non positionné sur 'C' ou 'D'
  *  valeur de retour: 'C' ou 'D'
  */
  function FinAccountBalanceDisplay(
    aACS_FINANCIAL_ACCOUNT_ID in ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_FINANCIAL_YEAR_ID    in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
    return varchar2
  is
    vResult             varchar2(1)                                     := '';
    vStartDate          ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
    vEndDate            ACS_FINANCIAL_YEAR.FYE_END_DATE%type;
    vAcbBudgetVersionID ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type;
    vAcsFinYearId       ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    vPeriodExercice     signtype;
  begin
    select C_BALANCE_DISPLAY
      into vResult
      from ACS_FINANCIAL_ACCOUNT
     where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    -- Retour direct du resultat si le compte est déjà paramétré 'C' ou 'D'
    if nvl(vResult, 'B') in('C', 'D') then
      return vResult;
    end if;

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- En cas de modification ci-dessous, modifier également la procédure FinAccountBalanceDispTblTemp
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- Il est possible de ne pas passer d'exercice -> prise en compte de l'exercice correspondant à sysdate
    if nvl(aACS_FINANCIAL_YEAR_ID, 0) > 0 then
      vAcsFinYearId  := aACS_FINANCIAL_YEAR_ID;
    else
      select ACS_FINANCIAL_YEAR_ID
        into vAcsFinYearId
        from ACS_FINANCIAL_YEAR
       where trunc(sysdate) between FYE_START_DATE and FYE_END_DATE;
    end if;

    /* Se baser sur le solde d'un budget pour déterminer si le compte est à considérer comme charge ou produit
         Solde du budget: < 0 -> 'C'
                        : > 0 -> 'D'
                        : = 0 -> recherche dans les cumuls
    */
    select case
             when sum(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C) < 0 then 'C'
             when sum(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C) > 0 then 'D'
             else 'B'
           end FIN_ACCOUNT_BALANCE_DISPLAY
      into vResult
      from ACB_BUDGET_VERSION VER
         , ACB_BUDGET BUD
         , ACB_GLOBAL_BUDGET GLO
     where BUD.ACB_BUDGET_ID = VER.ACB_BUDGET_ID
       and VER.VER_DEFAULT = 1
       and BUD.ACS_FINANCIAL_YEAR_ID = vAcsFinYearId
       and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
       and GLO.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    -- Montant <> 0
    if vResult in('C', 'D') then
      return vResult;
    end if;

    /* Rechercher dans les cumuls
         Si date fin exercice de l'exercice passé en paramètre <= sysdate: montant total (débit-crédit) des périodes de gestion (type 2) de l'exercice passé en paramètre
         Si date fin exercice de l'exercice passé en paramètre > sysdate: montant total (débit-crédit) des 12 dernières périodes (type 2) à partir de sysdate
    */
    select trunc(FYE_START_DATE)
         , trunc(FYE_END_DATE)
         , case
             when trunc(FYE_END_DATE) <= trunc(sysdate) then 1
             else 0
           end PERIOD_EXERCICE
      into vStartDate
         , vEndDate
         , vPeriodExercice
      from ACS_FINANCIAL_YEAR
     where ACS_FINANCIAL_YEAR_ID = vAcsFinYearId;

    if vPeriodExercice > 0 then   -- Prendre les périodes de l'exercice
      select case
               when sum(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC) < 0 then 'C'
               else 'D'
             end result
        into vResult
        from ACT_TOTAL_BY_PERIOD TOT
       where TOT.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
         and TOT.ACS_PERIOD_ID in(select ACS_PERIOD_ID
                                    from ACS_PERIOD
                                   where C_TYPE_PERIOD <> '3'
                                     and ACS_FINANCIAL_YEAR_ID = vAcsFinYearId)
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null;
    else   -- Rechercher le nombre de période composant un exercice et,
           -- à partir de ce total, calculer le montant sur le même nombre de période en amont de la date du jour
      select case
               when sum(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC) < 0 then 'C'
               else 'D'
             end result
        into vResult
        from ACT_TOTAL_BY_PERIOD TOT
       where TOT.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID
         and TOT.ACS_PERIOD_ID in(
               select ACS_PERIOD_ID
                 from (select   ACS_PERIOD_ID
                              , (select FYE_NO_EXERCICE
                                   from ACS_FINANCIAL_YEAR
                                  where ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID) FYE_NO_EXERCICE
                           from ACS_PERIOD PER
                          where PER.C_TYPE_PERIOD <> '3'
                            and PER.PER_END_DATE < trunc(sysdate)
                       order by FYE_NO_EXERCICE desc
                              , PER.PER_NO_PERIOD desc)
                where rownum <= (select count(1)   -- prendre en compte le total des périodes de saisie d'un exercice
                                   from ACS_PERIOD
                                  where ACS_FINANCIAL_YEAR_ID = vAcsFinYearId
                                    and C_TYPE_PERIOD <> '3') )
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null;
    end if;

    return vResult;
  end FinAccountBalanceDisplay;

  /**
  * function FinAccountBalanceDispTblTemp
  * Description
  *   idem FinAccountBalanceDisplay mais en prenant les comptes présents dans COM_LIST_ID_TEMP
  */
  function FinAccountBalanceDispTblTemp(aLID_CODE in COM_LIST_ID_TEMP.LID_CODE%type, aACS_FINANCIAL_YEAR_ID in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    return varchar2
  is
    vStartDate      ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
    vEndDate        ACS_FINANCIAL_YEAR.FYE_END_DATE%type;
    vAcsFinYearId   ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    vPeriodExercice signtype;
    vTotAccount     signtype;
    vResult         varchar2(1);
  begin
    -- Si plusieurs comptes sont à analyser, ne pas se baser sur le DECODE C_BALANCE_DISPLAY
    select case
             when count(1) <> 1 then 0
             else 1
           end
      into vTotAccount
      from COM_LIST_ID_TEMP TMP
     where TMP.LID_CODE = aLID_CODE
       and TMP.LID_FREE_NUMBER_1 is not null;

    if vTotAccount = 1 then
      select max(FIN.C_BALANCE_DISPLAY)
        into vResult
        from COM_LIST_ID_TEMP TMP
           , ACS_FINANCIAL_ACCOUNT FIN
       where TMP.LID_CODE = aLID_CODE
         and TMP.LID_FREE_NUMBER_1 is not null
         and FIN.ACS_FINANCIAL_ACCOUNT_ID = TMP.LID_FREE_NUMBER_1
         and FIN.C_BALANCE_DISPLAY in('C', 'D');

      if nvl(vResult, ' ') in('C', 'D') then
        return vResult;
      end if;
    end if;

    -- Il est possible de ne pas passer d'exercice -> prise en compte de l'exercice correspondant à sysdate
    if nvl(aACS_FINANCIAL_YEAR_ID, 0) > 0 then
      vAcsFinYearId  := aACS_FINANCIAL_YEAR_ID;
    else
      select ACS_FINANCIAL_YEAR_ID
        into vAcsFinYearId
        from ACS_FINANCIAL_YEAR
       where trunc(sysdate) between FYE_START_DATE and FYE_END_DATE;
    end if;

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- En cas de modification ci-dessous, modifier également la procédure FinAccountBalanceDisp
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    /* Se baser sur le solde d'un budget pour déterminer si le compte est à considérer comme charge ou produit
         Solde du budget: < 0 -> 'C'
                        : > 0 -> 'D'
                        : = 0 -> recherche dans les cumuls
    */
    select case
             when sum(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C) < 0 then 'C'
             when sum(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C) > 0 then 'D'
             else 'B'
           end FIN_ACCOUNT_BALANCE_DISPLAY
      into vResult
      from ACB_BUDGET_VERSION VER
         , ACB_BUDGET BUD
         , ACB_GLOBAL_BUDGET GLO
         , COM_LIST_ID_TEMP CHK
     where BUD.ACB_BUDGET_ID = VER.ACB_BUDGET_ID
       and VER.VER_DEFAULT = 1
       and BUD.ACS_FINANCIAL_YEAR_ID = vAcsFinYearId
       and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
       and GLO.ACS_FINANCIAL_ACCOUNT_ID = CHK.LID_FREE_NUMBER_1
       and CHK.LID_CODE = aLID_CODE;

    -- Montant <> 0
    if vResult in('C', 'D') then
      return vResult;
    end if;

    /* Rechercher dans les cumuls
         Si date fin exercice de l'exercice passé en paramètre <= sysdate: montant total (débit-crédit) des périodes de gestion (type 2) de l'exercice passé en paramètre
         Si date fin exercice de l'exercice passé en paramètre > sysdate: montant total (débit-crédit) des 12 dernières périodes (type 2) à partir de sysdate
    */
    select trunc(FYE_START_DATE)
         , trunc(FYE_END_DATE)
         , case
             when trunc(FYE_END_DATE) <= trunc(sysdate) then 1
             else 0
           end PERIOD_EXERCICE
      into vStartDate
         , vEndDate
         , vPeriodExercice
      from ACS_FINANCIAL_YEAR
     where ACS_FINANCIAL_YEAR_ID = vAcsFinYearId;

    if vPeriodExercice > 0 then   -- Prendre les périodes de l'exercice
      select case
               when sum(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC) < 0 then 'C'
               else 'D'
             end result
        into vResult
        from ACT_TOTAL_BY_PERIOD TOT
           , COM_LIST_ID_TEMP CHK
       where TOT.ACS_FINANCIAL_ACCOUNT_ID = CHK.LID_FREE_NUMBER_1
         and CHK.LID_CODE = aLID_CODE
         and TOT.ACS_PERIOD_ID in(select ACS_PERIOD_ID
                                    from ACS_PERIOD
                                   where C_TYPE_PERIOD <> '3'
                                     and ACS_FINANCIAL_YEAR_ID = vAcsFinYearId)
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null;
    else   -- Rechercher le nombre de période composant un exercice et,
           -- à partir de ce total, calculer le montant sur le même nombre de période en amont de la date du jour
      select case
               when sum(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC) < 0 then 'C'
               else 'D'
             end result
        into vResult
        from ACT_TOTAL_BY_PERIOD TOT
           , COM_LIST_ID_TEMP CHK
       where TOT.ACS_FINANCIAL_ACCOUNT_ID = CHK.LID_FREE_NUMBER_1
         and CHK.LID_CODE = aLID_CODE
         and TOT.ACS_PERIOD_ID in(
               select ACS_PERIOD_ID
                 from (select   ACS_PERIOD_ID
                              , (select FYE_NO_EXERCICE
                                   from ACS_FINANCIAL_YEAR
                                  where ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID) FYE_NO_EXERCICE
                           from ACS_PERIOD PER
                          where PER.C_TYPE_PERIOD <> '3'
                            and PER.PER_END_DATE < trunc(sysdate)
                       order by FYE_NO_EXERCICE desc
                              , PER.PER_NO_PERIOD desc)
                where rownum <= (select count(1)   -- prendre en compte le total des périodes de saisie d'un exercice
                                   from ACS_PERIOD
                                  where ACS_FINANCIAL_YEAR_ID = vAcsFinYearId
                                    and C_TYPE_PERIOD <> '3') )
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null;
    end if;

    return vResult;
  end FinAccountBalanceDispTblTemp;

  /**
  * function CCPToBVR
  * Description
  *   Conversion String Num. CCP en Num. adhérent ('25-12345-2' -> '250123452')
  */
  function CCPToBVR(aNumCCP in varchar2)
    return varchar2
  is
    Temp   varchar2(34);
    result varchar2(34);
  begin
    Temp  := aNumCCP;

    if instr(Temp, '-') <> 0 then
      result  := lpad(substr(Temp, 1, instr(Temp, '-') - 1), 2, '0');
      Temp    := substr(Temp, instr(Temp, '-') + 1);
      result  := result || lpad(substr(Temp, 1, instr(Temp, '-') - 1), 6, '0');
      Temp    := substr(Temp, instr(Temp, '-') + 1);
      result  := result || Temp;
    else
      result  := aNumCCP;
    end if;

    return result;
  end;

  /**
  * function VerifyNoBvr
  * Description
  *   Vérification de la saisie d'une référence bvr
  */
  function VerifyNoBvr(aRef in varchar2, aNoBvr in varchar2)
    return integer
  is
    strContr  varchar2(1);
    strContr1 varchar2(1);
    strNo     varchar2(30);
    strNBVR   varchar2(34);
  begin
    strNo  := nvl(trim(replace(replace(aRef, '-'), ' ') ), '');

    --Test is car diff de 0123456789
    if trim(translate(strNo, '0123456789', '          ') ) <> '' then
      return 0;
    end if;

    if     (strNo is not null)
       and (aNoBvr is not null) then
      strNBVR  := aNoBvr;

      if length(strNBVR) > 5 then
        strNBVR  := CCPtoBVR(strNBVR);
      end if;

      if length(trim(replace(strNBVR, '-') ) ) = 9 then
        if     (length(strNo) <> 16)
           and (length(strNo) <> 27) then
          return 0;
        end if;

        strContr1  := substr(strNo, length(strNo), 1);
        strNo      := substr(strNo, 1, length(strNo) - 1);
        strContr   := Modulo10(strNo);

        if strContr1 <> strContr then
          return 0;
        end if;
      else
        if length(strNo) <> 15 then
          return 0;
        end if;
      end if;
    else
      if     (strNo is not null)
         and (aNoBvr is null) then
        if     (length(strNo) <> 16)
           and (length(strNo) <> 27)
           and (length(strNo) <> 15) then
          return 0;
        end if;

        if length(strNo) <> 15 then
          strContr1  := substr(strNo, length(strNo), 1);
          strNo      := substr(strNo, 1, length(strNo) - 1);
          strContr   := Modulo10(strNo);

          if strContr1 <> strContr then
            return 0;
          end if;
        end if;
      end if;
    end if;

    return 1;
  end;

  /**
  * Description
  *    Récupère les informations concernant les méthodes d'arrondi du code TVA
  */
  procedure GetRoundInfo(
    iTaxCodeID      in     number
  , oFinRoundType   out    number
  , oFinRoundAmount out    number
  , oDocRoundType   out    number
  , oDocRoundAmount out    number
  , oFooRoundType   out    number
  , oFooRoundAmount out    number
  )
  is
  begin
    if iTaxCodeId is not null then
      begin
        select TAX.C_ROUND_TYPE
             , TAX.C_ROUND_TYPE_DOC
             , TAX.C_ROUND_TYPE_DOC_FOO
             , TAX.TAX_ROUNDED_AMOUNT
             , TAX.TAX_ROUNDED_AMOUNT_DOC
             , TAX.TAX_ROUNDED_AMOUNT_DOC_FOO
          into oFinRoundType
             , oDocRoundType
             , oFooRoundType
             , oFinRoundAmount
             , oDocRoundAmount
             , oFooRoundAmount
          from ACS_TAX_CODE TAX
         where TAX.ACS_TAX_CODE_ID = iTaxCodeId;
      exception
        when no_data_found then
          raise_application_error(-20077, 'PCS - Unexistant tax code');
      end;
    end if;
  end GetRoundInfo;
begin
  gLocalCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
end ACS_FUNCTION;
