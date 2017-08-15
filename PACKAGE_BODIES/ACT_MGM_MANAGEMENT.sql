--------------------------------------------------------
--  DDL for Package Body ACT_MGM_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_MGM_MANAGEMENT" 
is
  function ExistCDAAccInteracWithDate(aACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type, aDate date)
    return integer
  is
    result integer;
  begin
    select count(ACS_CDA_ACCOUNT_ID)
      into result
      from ACS_MGM_INTERACTION
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
       and ACS_CDA_ACCOUNT_ID is not null
       and aDate between nvl(MGM_VALID_SINCE, aDate) and nvl(MGM_VALID_TO, aDate)
       and rownum = 1;

    return result;
  end ExistCDAAccInteracWithDate;

  function ExistPFAccInteracWithDate(aACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type, aDate date)
    return integer
  is
    result integer;
  begin
    select count(ACS_PF_ACCOUNT_ID)
      into result
      from ACS_MGM_INTERACTION
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
       and ACS_PF_ACCOUNT_ID is not null
       and aDate between nvl(MGM_VALID_SINCE, aDate) and nvl(MGM_VALID_TO, aDate)
       and rownum = 1;

    return result;
  end ExistPFAccInteracWithDate;

  function ExistPJAccInteracWithDate(aACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type, aDate date)
    return integer
  is
    result integer;
  begin
    select count(ACS_PJ_ACCOUNT_ID)
      into result
      from ACS_MGM_INTERACTION
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
       and ACS_PJ_ACCOUNT_ID is not null
       and aDate between nvl(MGM_VALID_SINCE, aDate) and nvl(MGM_VALID_TO, aDate)
       and rownum = 1;

    return result;
  end ExistPJAccInteracWithDate;

  function IsCDAAccValidWithDate(
    aACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , aACS_CDA_ACCOUNT_ID ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  , aDate               date
  )
    return integer
  is
    result integer;
  begin
    select count(ACS_CDA_ACCOUNT_ID)
      into result
      from ACS_MGM_INTERACTION
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
       and ACS_CDA_ACCOUNT_ID = aACS_CDA_ACCOUNT_ID
       and aDate between nvl(MGM_VALID_SINCE, aDate) and nvl(MGM_VALID_TO, aDate);

    if result = 0 then
      --Si pas d'interaction -> OK
      if ExistCDAAccInteracWithDate(aACS_CPN_ACCOUNT_ID, aDate) = 0 then
        result  := 1;
      end if;
    end if;

    return result;
  end IsCDAAccValidWithDate;

  function IsPFAccValidWithDate(
    aACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT_ID  ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  , aDate               date
  )
    return integer
  is
    result integer;
  begin
    select count(ACS_PF_ACCOUNT_ID)
      into result
      from ACS_MGM_INTERACTION
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
       and ACS_PF_ACCOUNT_ID = aACS_PF_ACCOUNT_ID
       and aDate between nvl(MGM_VALID_SINCE, aDate) and nvl(MGM_VALID_TO, aDate);

    if result = 0 then
      --Si pas d'interaction -> OK
      if ExistPFAccInteracWithDate(aACS_CPN_ACCOUNT_ID, aDate) = 0 then
        result  := 1;
      end if;
    end if;

    return result;
  end IsPFAccValidWithDate;

  function IsPJAccValidWithDate(
    aACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , aACS_PJ_ACCOUNT_ID  ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type
  , aDate               date
  )
    return integer
  is
    result integer;
  begin
    select count(ACS_PJ_ACCOUNT_ID)
      into result
      from ACS_MGM_INTERACTION
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
       and ACS_PJ_ACCOUNT_ID = aACS_PJ_ACCOUNT_ID
       and aDate between nvl(MGM_VALID_SINCE, aDate) and nvl(MGM_VALID_TO, aDate);

    if result = 0 then
      --Si pas d'interaction -> OK
      if ExistPJAccInteracWithDate(aACS_CPN_ACCOUNT_ID, aDate) = 0 then
        result  := 1;
      end if;
    end if;

    return result;
  end IsPJAccValidWithDate;

  function GetCPNAccInteracWithDate(
    aACS_CPN_ACCOUNT_ID     ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , aDate                   date
  , aCPNLinkedAccounts  out CPNLinkedAccountsRecType
  )
    return boolean
  is
    result boolean;
  begin
    aCPNLinkedAccounts  := null;
    result              := false;

    for tpl_Interaction in (select ACS_CDA_ACCOUNT_ID
                                 , ACS_PF_ACCOUNT_ID
                                 , ACS_PJ_ACCOUNT_ID
                              from ACS_MGM_INTERACTION
                             where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID
                               and MGM_DEFAULT = 1
                               and aDate between nvl(MGM_VALID_SINCE, aDate) and nvl(MGM_VALID_TO, aDate) ) loop
      if tpl_Interaction.ACS_CDA_ACCOUNT_ID is not null then
        aCPNLinkedAccounts.CDAAccId  := tpl_Interaction.ACS_CDA_ACCOUNT_ID;
      elsif tpl_Interaction.ACS_PF_ACCOUNT_ID is not null then
        aCPNLinkedAccounts.PFAccId  := tpl_Interaction.ACS_PF_ACCOUNT_ID;
      elsif tpl_Interaction.ACS_PJ_ACCOUNT_ID is not null then
        aCPNLinkedAccounts.PJAccId  := tpl_Interaction.ACS_PJ_ACCOUNT_ID;
      end if;

      result  := true;
    end loop;

    return result;
  end GetCPNAccInteracWithDate;

  procedure GetDocRecordInterac(
    aDOC_RECORD_ID         DOC_RECORD.DOC_RECORD_ID%type
  , aCPNLinkedAccounts out CPNLinkedAccountsRecType
  )
  is
  begin
    begin
      select ACS_CDA_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
        into aCPNLinkedAccounts
        from DOC_RECORD
       where DOC_RECORD_ID = aDOC_RECORD_ID;
    exception
      when no_data_found then
        aCPNLinkedAccounts  := null;
    end;
  end GetDocRecordInterac;

  procedure GetCPNImputPermission(
    aACS_CPN_ACCOUNT_ID in     ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , aCPNImputPermission out    CPNImputPermissionRecType
  )
  is
  begin
    select C_CDA_IMPUTATION
         , C_PF_IMPUTATION
         , C_PJ_IMPUTATION
      into aCPNImputPermission
      from ACS_CPN_ACCOUNT
     where ACS_CPN_ACCOUNT_ID = aACS_CPN_ACCOUNT_ID;
  end GetCPNImputPermission;

  procedure CDAPFImputationSelection(
    aCPNImputPermission        CPNImputPermissionRecType
  , aACS_CDA_ACCOUNT_ID in out ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT_ID  in out ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  )
  is
  begin
    if     aACS_CDA_ACCOUNT_ID is not null
       and aCPNImputPermission.CDA = '3' then
      aACS_CDA_ACCOUNT_ID  := null;
    end if;

    if     aACS_PF_ACCOUNT_ID is not null
       and aCPNImputPermission.PF = '3' then
      aACS_PF_ACCOUNT_ID  := null;
    end if;

    if     aCPNImputPermission.CDA = '2'
       and aCPNImputPermission.PF = '2' then
      if aACS_CDA_ACCOUNT_ID is not null then
        aACS_PF_ACCOUNT_ID  := null;
      elsif aACS_PF_ACCOUNT_ID is not null then
        aACS_CDA_ACCOUNT_ID  := null;
      end if;
    end if;
  end CDAPFImputationSelection;

  function Initialize(
    aACS_CPN_ACCOUNT_ID     ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , aDate                   date
  , aValues             out CPNLinkedAccountsRecType
  )
    return boolean
  is
    vCPNImputPermission CPNImputPermissionRecType;
    result              boolean;
  begin
    GetCPNImputPermission(aACS_CPN_ACCOUNT_ID, vCPNImputPermission);
    result  := GetCPNAccInteracWithDate(aACS_CPN_ACCOUNT_ID, aDate, aValues);

    if vCPNImputPermission.CDA = '3' then
      aValues.CDAAccId  := null;
    end if;

    if vCPNImputPermission.PF = '3' then
      aValues.PFAccId  := null;
    end if;

    if vCPNImputPermission.PJ = '3' then
      aValues.PJAccId  := null;
    end if;

    CDAPFImputationSelection(vCPNImputPermission, aValues.CDAAccId, aValues.PFAccId);

    return result;
  end Initialize;

  function ReInitialize(
    aACS_CPN_ACCOUNT_ID        ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , aDate                      date
  , aOldValues          in out CPNLinkedAccountsRecType
  , aValues             out    CPNLinkedAccountsRecType
  )
    return boolean
  is
    TempValues          CPNLinkedAccountsRecType;
    vCPNImputPermission CPNImputPermissionRecType;
    result              boolean;
  begin
    TempValues  := aOldValues;
    GetCPNImputPermission(aACS_CPN_ACCOUNT_ID, vCPNImputPermission);

    if vCPNImputPermission.CDA = '3' then
      TempValues.CDAAccId  := null;
    end if;

    if vCPNImputPermission.PF = '3' then
      TempValues.PFAccId  := null;
    end if;

    if vCPNImputPermission.PJ = '3' then
      TempValues.PJAccId  := null;
    end if;

    if     TempValues.CDAAccId is not null
       and IsCDAAccValidWithDate(aACS_CPN_ACCOUNT_ID, TempValues.CDAAccId, aDate) = 0 then
      TempValues.CDAAccId  := null;
    end if;

    if     TempValues.PFAccId is not null
       and IsPFAccValidWithDate(aACS_CPN_ACCOUNT_ID, TempValues.PFAccId, aDate) = 0 then
      TempValues.PFAccId  := null;
    end if;

    if     TempValues.PJAccId is not null
       and IsPJAccValidWithDate(aACS_CPN_ACCOUNT_ID, TempValues.PJAccId, aDate) = 0 then
      TempValues.PJAccId  := null;
    end if;

    CDAPFImputationSelection(vCPNImputPermission, TempValues.CDAAccId, TempValues.PFAccId);

    result      := GetCPNAccInteracWithDate(aACS_CPN_ACCOUNT_ID, aDate, aValues);

    if vCPNImputPermission.CDA = '3' then
      aValues.CDAAccId  := null;
    end if;

    if vCPNImputPermission.PF = '3' then
      aValues.PFAccId  := null;
    end if;

    if vCPNImputPermission.PJ = '3' then
      aValues.PJAccId  := null;
    end if;

    if     TempValues.CDAAccId is null
       and aValues.CDAAccId is not null then
      if    vCPNImputPermission.CDA = '1'
         or (    vCPNImputPermission.CDA = '2'
             and vCPNImputPermission.PF = '2'
             and TempValues.PFAccId is null) then
        TempValues.CDAAccId  := aValues.CDAAccId;
      end if;
    end if;

    if     TempValues.PFAccId is null
       and aValues.PFAccId is not null then
      if    vCPNImputPermission.PF = '1'
         or (    vCPNImputPermission.PF = '2'
             and vCPNImputPermission.CDA = '2'
             and TempValues.CDAAccId is null) then
        TempValues.PFAccId  := aValues.PFAccId;
      end if;
    end if;

    if     TempValues.PJAccId is null
       and aValues.PJAccId is not null then
      if vCPNImputPermission.PJ = '1' then
        TempValues.PJAccId  := aValues.PJAccId;
      end if;
    end if;

    aValues     := TempValues;
    return result;
  end ReInitialize;

  -------------------------
  function CalcProportionMANImputation(aACT_FINANCIAL_IMPUTATION_ID   in     ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                                       atblProportionMANImput         in out tblProportionMANImputType) return boolean
  is
    cursor csrMgmImputation(fin_imput_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type) is
      select  ACT_MGM_IMPUTATION_ID
            , ACS_CPN_ACCOUNT_ID
            , ACS_CDA_ACCOUNT_ID
            , ACS_PF_ACCOUNT_ID
            , ACS_QTY_UNIT_ID
            , nvl(IMM_AMOUNT_LC_D, 0) IMM_AMOUNT_LC_D
            , nvl(IMM_AMOUNT_LC_C, 0) IMM_AMOUNT_LC_C
          from ACT_MGM_IMPUTATION
        where ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID = fin_imput_id
      order by greatest(abs(nvl(IMM_AMOUNT_LC_D, 0)), abs(nvl(IMM_AMOUNT_LC_C, 0)))
            , ACS_CPN_ACCOUNT_ID
            , ACS_CDA_ACCOUNT_ID
            , ACS_PF_ACCOUNT_ID
            , ACS_QTY_UNIT_ID;

    Pos integer := 1;
    TotAmount ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type := 0;
  begin
    for tplMgmImputation in csrMgmImputation(aACT_FINANCIAL_IMPUTATION_ID) loop

      atblProportionMANImput(Pos).ACT_MGM_IMPUTATION_ID := tplMgmImputation.ACT_MGM_IMPUTATION_ID;
      atblProportionMANImput(Pos).ACS_CPN_ACCOUNT_ID    := tplMgmImputation.ACS_CPN_ACCOUNT_ID;
      atblProportionMANImput(Pos).ACS_CDA_ACCOUNT_ID    := tplMgmImputation.ACS_CDA_ACCOUNT_ID;
      atblProportionMANImput(Pos).ACS_PF_ACCOUNT_ID     := tplMgmImputation.ACS_PF_ACCOUNT_ID;
      atblProportionMANImput(Pos).ACS_QTY_UNIT_ID       := tplMgmImputation.ACS_QTY_UNIT_ID;

      if tplMgmImputation.IMM_AMOUNT_LC_D != 0 then
        atblProportionMANImput(Pos).AMOUNT := tplMgmImputation.IMM_AMOUNT_LC_D;
        TotAmount := TotAmount + atblProportionMANImput(Pos).AMOUNT;
      else
        atblProportionMANImput(Pos).AMOUNT := tplMgmImputation.IMM_AMOUNT_LC_C;
        TotAmount := TotAmount + atblProportionMANImput(Pos).AMOUNT;
      end if;

      Pos := Pos + 1;
    end loop;

    --CALCUL DE LA TABLE DES PROPORTIONS
    for Pos in 1..atblProportionMANImput.Count loop
      atblProportionMANImput(Pos).RATIO := atblProportionMANImput(Pos).AMOUNT / TotAmount;
    end loop;

    return atblProportionMANImput.Count > 0;

  end CalcProportionMANImputation;

  -------------------------

  function CalcProportionMANDistribution(aACT_MGM_IMPUTATION_ID   in     ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type,
                                         atblProportionMANDist    in out tblProportionMANDistType) return boolean
  is
    cursor csrMgmDistribution(mgm_imput_id ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type) is
      select  ACS_PJ_ACCOUNT_ID
            , nvl(MGM_AMOUNT_LC_D, 0) MGM_AMOUNT_LC_D
            , nvl(MGM_AMOUNT_LC_C, 0) MGM_AMOUNT_LC_C
          from ACT_MGM_DISTRIBUTION
        where ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID = mgm_imput_id
      order by greatest(abs(nvl(MGM_AMOUNT_LC_D, 0)), abs(nvl(MGM_AMOUNT_LC_C, 0)))
            , ACS_PJ_ACCOUNT_ID;

    Pos integer := 1;
    TotAmount ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_D%type := 0;
  begin
    for tplMgmDistribution in csrMgmDistribution(aACT_MGM_IMPUTATION_ID) loop

      atblProportionMANDist(Pos).ACS_PJ_ACCOUNT_ID  := tplMgmDistribution.ACS_PJ_ACCOUNT_ID;

      if tplMgmDistribution.MGM_AMOUNT_LC_D != 0 then
        atblProportionMANDist(Pos).AMOUNT := tplMgmDistribution.MGM_AMOUNT_LC_D;
        TotAmount := TotAmount + atblProportionMANDist(Pos).AMOUNT;
      else
        atblProportionMANDist(Pos).AMOUNT := tplMgmDistribution.MGM_AMOUNT_LC_C;
        TotAmount := TotAmount + atblProportionMANDist(Pos).AMOUNT;
      end if;

      Pos := Pos + 1;
    end loop;

    --CALCUL DE LA TABLE DES PROPORTIONS
    for Pos in 1..atblProportionMANDist.Count loop
      atblProportionMANDist(Pos).RATIO := atblProportionMANDist(Pos).AMOUNT / TotAmount;
    end loop;

    return atblProportionMANDist.Count > 0;

  end CalcProportionMANDistribution;

end ACT_MGM_MANAGEMENT;
