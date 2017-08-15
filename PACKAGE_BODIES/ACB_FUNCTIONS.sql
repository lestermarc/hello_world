--------------------------------------------------------
--  DDL for Package Body ACB_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACB_FUNCTIONS" 
is
---------------------
  function BudgetAmount(
    aACS_ACCOUNT_ID1       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_ACCOUNT_ID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aACB_BUDGET_VERSION_ID ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  )
    return ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type
  is
    FinAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CDAAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PFAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CPNAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    DivAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    BudAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    QtyAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PJAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Amount       ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type             default 0;
    YearId       ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    VersionId    ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type;
    vInit1       boolean;
    vInit2       boolean;

    --------
    function SetAccountsParameters(aACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
      return boolean
    is
      result boolean                      default true;
      SubSet ACS_SUB_SET.C_SUB_SET%type;
    begin
      if aACS_ACCOUNT_ID is not null then
        SubSet  := ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID);

        if SubSet = 'ACC' then
          FinAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'CDA' then
          CDAAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'COS' then
          PFAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'CPN' then
          CPNAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet in('DOP', 'DPA', 'DTO') then
          DivAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'PBU' then
          BudAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'QTU' then
          QtyAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'PRO' then
          PJAccountId  := aACS_ACCOUNT_ID;
        else
          result  := false;
        end if;
      end if;

      return result;
    end SetAccountsParameters;
  -----
  begin
    if aACB_BUDGET_VERSION_ID is null then
      if aACS_FINANCIAL_YEAR_ID is null then
        YearId  := ACS_FUNCTION.GetMaxNoExerciceId;
      else
        YearId  := aACS_FINANCIAL_YEAR_ID;
      end if;

      select max(ACB_BUDGET_VERSION_ID)
        into VersionId
        from ACB_BUDGET_VERSION VER
           , ACB_BUDGET BUD
       where BUD.ACS_FINANCIAL_YEAR_ID = YearId
         and BUD.ACB_BUDGET_ID = VER.ACB_BUDGET_ID
         and VER.VER_DEFAULT = 1;
    else
      VersionId  := aACB_BUDGET_VERSION_ID;
    end if;

    if VersionId is not null then
      vInit1  := SetAccountsParameters(aACS_ACCOUNT_ID1);
      vInit2  := SetAccountsParameters(aACS_ACCOUNT_ID2);

      if    vInit1
         or vInit2 then
        select sum(GLO_AMOUNT_D - GLO_AMOUNT_C)
          into Amount
          from ACB_GLOBAL_BUDGET
         where ACB_BUDGET_VERSION_ID = VersionId
           and ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
           and C_BUDGET_KIND = '1'
           and (   ACS_FINANCIAL_ACCOUNT_ID = FinAccountId
                or FinAccountId is null)
           and (   ACS_CDA_ACCOUNT_ID = CDAAccountId
                or CDAAccountId is null)
           and (   ACS_PF_ACCOUNT_ID = PFAccountId
                or PFAccountId is null)
           and (   ACS_CPN_ACCOUNT_ID = CPNAccountId
                or CPNAccountId is null)
           and (   ACS_DIVISION_ACCOUNT_ID = DivAccountId
                or DivAccountId is null)
           and (   ACS_BUDGET_ACCOUNT_ID = BudAccountId
                or BudAccountId is null)
           and (   ACS_QTY_UNIT_ID = QtyAccountId
                or QtyAccountId is null)
           and (   ACS_PJ_ACCOUNT_ID = PJAccountId
                or PJAccountId is null);

        if Amount is null then
          Amount  := 0;
        end if;
      end if;
    end if;

    return Amount;
  end BudgetAmount;

---------------------------
  function PeriodBudgetAmount(
    aACS_ACCOUNT_ID1       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_ACCOUNT_ID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aPER_NO_PERIOD1        ACS_PERIOD.PER_NO_PERIOD%type
  , aPER_NO_PERIOD2        ACS_PERIOD.PER_NO_PERIOD%type
  , aACB_BUDGET_VERSION_ID ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , aGetAmount             number
  ,   -- 1: Montant 0: Quantit�
    aACS_ACCOUNT_ID3       ACS_ACCOUNT.ACS_ACCOUNT_ID%type default null
  , aACS_ACCOUNT_ID4       ACS_ACCOUNT.ACS_ACCOUNT_ID%type default null
  )
    return ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type
  is
    FinAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CDAAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PFAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    CPNAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    DivAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    BudAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    QtyAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    PJAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Amount       ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type   default 0;
    Qty          ACB_GLOBAL_BUDGET.GLO_QTY_D%type      default 0;

    --------
    function SetAccountsParameters(aACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
      return boolean
    is
      result boolean                      default true;
      SubSet ACS_SUB_SET.C_SUB_SET%type;
    begin
      if aACS_ACCOUNT_ID is not null then
        SubSet  := ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID);

        if SubSet = 'ACC' then
          FinAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'CDA' then
          CDAAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'COS' then
          PFAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'CPN' then
          CPNAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet in('DOP', 'DPA', 'DTO') then
          DivAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'PBU' then
          BudAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'QTU' then
          QtyAccountId  := aACS_ACCOUNT_ID;
        elsif SubSet = 'PRO' then
          PJAccountId  := aACS_ACCOUNT_ID;
        else
          result  := false;
        end if;
      end if;

      return result;
    end SetAccountsParameters;
  -----
  begin
    if     SetAccountsParameters(aACS_ACCOUNT_ID1)
       and SetAccountsParameters(aACS_ACCOUNT_ID2)
       and SetAccountsParameters(aACS_ACCOUNT_ID3)
       and SetAccountsParameters(aACS_ACCOUNT_ID4) then
      begin
        select nvl(sum(PER_AMOUNT_D - PER_AMOUNT_C), 0)
             , nvl(sum(PER_QTY_D - PER_QTY_C), 0)
          into Amount
             , Qty
          from ACS_PERIOD PER
             , ACB_PERIOD_AMOUNT AMO
             , ACB_BUDGET BUD
             , ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
         where GLO.ACB_BUDGET_VERSION_ID = aACB_BUDGET_VERSION_ID
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID
           and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
           and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.PER_NO_PERIOD >= aPER_NO_PERIOD1
           and PER.PER_NO_PERIOD <= aPER_NO_PERIOD2
           and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
           and GLO.C_BUDGET_KIND = '1'
           and (   GLO.ACS_FINANCIAL_ACCOUNT_ID = FinAccountId
                or FinAccountId is null)
           and (   GLO.ACS_CDA_ACCOUNT_ID = CDAAccountId
                or CDAAccountId is null)
           and (   GLO.ACS_PF_ACCOUNT_ID = PFAccountId
                or PFAccountId is null)
           and (   GLO.ACS_CPN_ACCOUNT_ID = CPNAccountId
                or CPNAccountId is null)
           and (   GLO.ACS_DIVISION_ACCOUNT_ID = DivAccountId
                or DivAccountId is null)
           and (   GLO.ACS_BUDGET_ACCOUNT_ID = BudAccountId
                or BudAccountId is null)
           and (   GLO.ACS_QTY_UNIT_ID = QtyAccountId
                or QtyAccountId is null)
           and (   GLO.ACS_PJ_ACCOUNT_ID = PJAccountId
                or PJAccountId is null);
      exception
        when others then
          Amount  := 0;
          Qty     := 0;
      end;
    end if;

    if aGetAmount = 1 then
      return Amount;
    else
      return Qty;
    end if;
  end PeriodBudgetAmount;

  /**
  * function GetBudgetingAmount
  * @description
  *  Retourne le montant budg�tis� (1) sinon quantit� pour un compte donn� (pACS_SRC_ACCOUNT_ID)
  *  un budget choisi, et des options de filtrage possible.
  */
  function GetBudgetingAmount(
    pCSubSet               ACS_SUB_SET.C_SUB_SET%type
  , pACS_SRC_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_CPN_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_CDA_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_PF_ACCOUNT_ID     ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_PJ_ACCOUNT_ID     ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_QTY_UNIT_ID       ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type
  , pDOC_RECORD_ID         DOC_RECORD.DOC_RECORD_ID%type
  , pPER_NO_PERIOD_FROM    ACS_PERIOD.PER_NO_PERIOD%type
  , pPER_NO_PERIOD_TO      ACS_PERIOD.PER_NO_PERIOD%type
  , pACB_BUDGET_VERSION_ID ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , pGetAmount             number
  , pLevel                 number
  )
    return ACB_PERIOD_AMOUNT.PER_AMOUNT_D%type
  is
    vAmount ACB_PERIOD_AMOUNT.PER_AMOUNT_D%type   := 0;
  begin
    if pLevel > -1 then
      begin
        select case
                 when pGetAmount = 1 then nvl(sum(AMO.PER_AMOUNT_D - AMO.PER_AMOUNT_C), 0)
                 else nvl(sum(AMO.PER_QTY_D - AMO.PER_QTY_C), 0)
               end PER_AMOUNT
          into vAmount
          from table(ACR_FUNCTIONS.GetSubAccounts(pACS_SRC_ACCOUNT_ID, pLevel) ) SubAccounts
             , ACS_PERIOD PER
             , ACB_PERIOD_AMOUNT AMO
             , ACB_BUDGET BUD
             , ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
         where GLO.ACB_BUDGET_VERSION_ID = pACB_BUDGET_VERSION_ID
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID
           and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
           and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.PER_NO_PERIOD >= pPER_NO_PERIOD_FROM
           and PER.PER_NO_PERIOD <= pPER_NO_PERIOD_TO
           and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
           and GLO.C_BUDGET_KIND = '1'
           and decode(pCSubSet, 'CPN', GLO.ACS_CPN_ACCOUNT_ID, 'CDA', GLO.ACS_CDA_ACCOUNT_ID, 'COS', GLO.ACS_PF_ACCOUNT_ID, 'PRO', GLO.ACS_PJ_ACCOUNT_ID) =
                                                                                                                                        SubAccounts.column_value
           and (    (GLO.ACS_CPN_ACCOUNT_ID = pACS_CPN_ACCOUNT_ID)
                or (pACS_CPN_ACCOUNT_ID = 0) )
           and (    (GLO.ACS_CDA_ACCOUNT_ID = pACS_CDA_ACCOUNT_ID)
                or (pACS_CDA_ACCOUNT_ID = 0) )
           and (    (GLO.ACS_PF_ACCOUNT_ID = pACS_PF_ACCOUNT_ID)
                or (pACS_PF_ACCOUNT_ID = 0) )
           and (    (GLO.ACS_PJ_ACCOUNT_ID = pACS_PJ_ACCOUNT_ID)
                or (pACS_PJ_ACCOUNT_ID = 0) )
           and (    (GLO.ACS_QTY_UNIT_ID = pACS_QTY_UNIT_ID)
                or (pACS_QTY_UNIT_ID = 0) )
           and (    (GLO.DOC_RECORD_ID = pDOC_RECORD_ID)
                or (pDOC_RECORD_ID = 0) );
      exception
        when others then
          vAmount  := 0;
      end;
    else
      begin
        select case
                 when pGetAmount = 1 then nvl(sum(AMO.PER_AMOUNT_D - AMO.PER_AMOUNT_C), 0)
                 else nvl(sum(AMO.PER_QTY_D - AMO.PER_QTY_C), 0)
               end PER_AMOUNT
          into vAmount
          from ACS_PERIOD PER
             , ACB_PERIOD_AMOUNT AMO
             , ACB_BUDGET BUD
             , ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
         where GLO.ACB_BUDGET_VERSION_ID = pACB_BUDGET_VERSION_ID
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID
           and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
           and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.PER_NO_PERIOD >= pPER_NO_PERIOD_FROM
           and PER.PER_NO_PERIOD <= pPER_NO_PERIOD_TO
           and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
           and GLO.C_BUDGET_KIND = '1'
           and decode(pCSubSet, 'CPN', GLO.ACS_CPN_ACCOUNT_ID, 'CDA', GLO.ACS_CDA_ACCOUNT_ID, 'COS', GLO.ACS_PF_ACCOUNT_ID, 'PRO', GLO.ACS_PJ_ACCOUNT_ID) =
                                                                                                                                             pACS_SRC_ACCOUNT_ID
           and (    (GLO.ACS_CPN_ACCOUNT_ID = pACS_CPN_ACCOUNT_ID)
                or (pACS_CPN_ACCOUNT_ID = 0) )
           and (    (GLO.ACS_CDA_ACCOUNT_ID = pACS_CDA_ACCOUNT_ID)
                or (pACS_CDA_ACCOUNT_ID = 0) )
           and (    (GLO.ACS_PF_ACCOUNT_ID = pACS_PF_ACCOUNT_ID)
                or (pACS_PF_ACCOUNT_ID = 0) )
           and (    (GLO.ACS_PJ_ACCOUNT_ID = pACS_PJ_ACCOUNT_ID)
                or (pACS_PJ_ACCOUNT_ID = 0) )
           and (    (GLO.ACS_QTY_UNIT_ID = pACS_QTY_UNIT_ID)
                or (pACS_QTY_UNIT_ID = 0) )
           and (    (GLO.DOC_RECORD_ID = pDOC_RECORD_ID)
                or (pDOC_RECORD_ID = 0) );
      exception
        when others then
          vAmount  := 0;
      end;
    end if;

    return vAmount;
  end GetBudgetingAmount;

  /**
  * function GetBudgetingAmountList
  * Description
  *  Recherche du montant budg�tis� pour les comptes donn�s. Avec recherche dans les sous-comptes
  */
  function GetBudgetingAmountList(
    pCSubSet               ACS_SUB_SET.C_SUB_SET%type
  , pACS_CPN_ACCOUNT_ID    ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , pACS_CDA_ACCOUNT_ID    ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  , pACS_PF_ACCOUNT_ID     ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  , pACS_PJ_ACCOUNT_ID     ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type
  , pACS_QTY_UNIT_ID       ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type
  , pDOC_RECORD_ID         DOC_RECORD.DOC_RECORD_ID%type
  , pPER_NO_PERIOD_FROM    ACS_PERIOD.PER_NO_PERIOD%type
  , pPER_NO_PERIOD_TO      ACS_PERIOD.PER_NO_PERIOD%type
  , pACB_BUDGET_VERSION_ID ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , pGetAmount             number   -- 1: Montant 0: Quantit�
  , pLevel                 number
  )
    return ACB_PERIOD_AMOUNT.PER_AMOUNT_D%type
  is
    vAmount             ACB_PERIOD_AMOUNT.PER_AMOUNT_D%type   := 0;
    vACS_CPN_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vACS_CDA_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vACS_PF_ACCOUNT_ID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vACS_PJ_ACCOUNT_ID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    vACS_CPN_ACCOUNT_ID  := pACS_CPN_ACCOUNT_ID;
    vACS_CDA_ACCOUNT_ID  := pACS_CDA_ACCOUNT_ID;
    vACS_PF_ACCOUNT_ID   := pACS_PF_ACCOUNT_ID;
    vACS_PJ_ACCOUNT_ID   := pACS_PJ_ACCOUNT_ID;

    --Ne pas filtrer sur le compte pour lequel on cherche les montants budg�tis�s
    --Les filtres sont l� pour affiner le total du compte principal
    -- Ex: compte principal est un CPN: filtre possible sur CDA, PF, PJ
    if pCSubSet = 'CPN' then
      vACS_CPN_ACCOUNT_ID  := 0;
    elsif pCSubSet = 'CDA' then
      vACS_CDA_ACCOUNT_ID  := 0;
    elsif pCSubSet = 'COS' then
      vACS_PF_ACCOUNT_ID  := 0;
    elsif pCSubSet = 'PRO' then
      vACS_PJ_ACCOUNT_ID  := 0;
    end if;

    if pLevel > -1 then
      --Dans un noeud, il peut arriver qu'un compte soit parent d'un sous-compte et que les deux �l�ments existent dans ce  noeud.
      --Si tel est le cas, il ne faut pas que le montant budg�tis� soit pris une fois par l'�l�ment de l'arborescence et une autre fois en tant que sous-compte du parent.
      --Pour corriger ce probl�me, recherche de tous les comptes + sous-comptes du noeud s�lectionn� et calcul du budget sans rechercher les sous-comptes
      for tplAccount in (select SubAccounts.column_value ACS_ACCOUNT_ID
                           from table(ACR_FUNCTIONS.GetSubAccountsList(pLevel) ) SubAccounts) loop
        vAmount  :=
          vAmount +
          ACB_FUNCTIONS.GetBudgetingAmount
                                      (pCSubSet
                                     , tplAccount.ACS_ACCOUNT_ID
                                     , vACS_CPN_ACCOUNT_ID
                                     , vACS_CDA_ACCOUNT_ID
                                     , vACS_PF_ACCOUNT_ID
                                     , vACS_PJ_ACCOUNT_ID
                                     , pACS_QTY_UNIT_ID
                                     , pDOC_RECORD_ID
                                     , pPER_NO_PERIOD_FROM
                                     , pPER_NO_PERIOD_TO
                                     , pACB_BUDGET_VERSION_ID
                                     , pGetAmount   -- 1= montant, autre = quantit�
                                     , -1   -- forcer � -1 pour ne pas chercher les sous-comptes vu qu'ils sont d�j� inclus dans ACR_FUNCTIONS.GetSubAccountsList
                                      );
      end loop;
    else
      for tplAccount in (select LID_FREE_NUMBER_1 ACS_ACCOUNT_ID
                           from COM_LIST_ID_TEMP) loop
        vAmount  :=
          vAmount +
          ACB_FUNCTIONS.GetBudgetingAmount(pCSubSet
                                         , tplAccount.ACS_ACCOUNT_ID
                                         , vACS_CPN_ACCOUNT_ID
                                         , vACS_CDA_ACCOUNT_ID
                                         , vACS_PF_ACCOUNT_ID
                                         , vACS_PJ_ACCOUNT_ID
                                         , pACS_QTY_UNIT_ID
                                         , pDOC_RECORD_ID
                                         , pPER_NO_PERIOD_FROM
                                         , pPER_NO_PERIOD_TO
                                         , pACB_BUDGET_VERSION_ID
                                         , pGetAmount   -- 1= montant, autre = quantit�
                                         , pLevel   -- (-1)
                                          );
      end loop;
    end if;

    return vAmount;
  end GetBudgetingAmountList;

/**********************************************************************************************************************/
  function PeriodBudgetAmountByQty(
    pAccountId1      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pAccountId2      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pQtyUnitId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pStartPerNum     ACS_PERIOD.PER_NO_PERIOD%type
  , pEndPerNum       ACS_PERIOD.PER_NO_PERIOD%type
  , pBudgetVersionId ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , aGetAmount       number
  )
    return ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type
  is
    vFinAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCDAAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPFAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCPNAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vBudAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vQtyAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPJAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vAmount       ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type   default 0;
    vQty          ACB_GLOBAL_BUDGET.GLO_QTY_D%type      default 0;

    function SetAccountsParameters(pACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
      return boolean
    is
      result  boolean                      default true;
      vSubSet ACS_SUB_SET.C_SUB_SET%type;
    begin
      if pACS_ACCOUNT_ID is not null then
        vSubSet  := ACS_FUNCTION.GetSubSetOfAccount(pACS_ACCOUNT_ID);

        if vSubSet = 'ACC' then
          vFinAccountId  := pACS_ACCOUNT_ID;
        elsif vSubSet = 'CDA' then
          vCDAAccountId  := pACS_ACCOUNT_ID;
        elsif vSubSet = 'COS' then
          vPFAccountId  := pACS_ACCOUNT_ID;
        elsif vSubSet = 'CPN' then
          vCPNAccountId  := pACS_ACCOUNT_ID;
        elsif vSubSet in('DOP', 'DPA', 'DTO') then
          vDivAccountId  := pACS_ACCOUNT_ID;
        elsif vSubSet = 'PBU' then
          vBudAccountId  := pACS_ACCOUNT_ID;
        elsif vSubSet = 'QTU' then
          vQtyAccountId  := pACS_ACCOUNT_ID;
        elsif vSubSet = 'PRO' then
          vPJAccountId  := pACS_ACCOUNT_ID;
        else
          result  := false;
        end if;
      end if;

      return result;
    end SetAccountsParameters;
  begin
    /*D�finition des diff�rents comptes selon le sous-ensemble*/
    if     SetAccountsParameters(pAccountId1)
       and SetAccountsParameters(pAccountId2)
       and SetAccountsParameters(pQtyUnitId) then
      begin
        select nvl(sum(PER_AMOUNT_D - PER_AMOUNT_C), 0)
             , nvl(sum(PER_QTY_D - PER_QTY_C), 0)
          into vAmount
             , vQty
          from ACS_PERIOD PER
             , ACB_PERIOD_AMOUNT AMO
             , ACB_BUDGET BUD
             , ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
         where GLO.ACB_BUDGET_VERSION_ID = pBudgetVersionId
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID
           and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
           and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.PER_NO_PERIOD >= pStartPerNum
           and PER.PER_NO_PERIOD <= pEndPerNum
           and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
           and GLO.C_BUDGET_KIND = '1'
           and (    (GLO.ACS_FINANCIAL_ACCOUNT_ID = vFinAccountId)
                or (vFinAccountId is null) )
           and (    (GLO.ACS_CDA_ACCOUNT_ID = vCDAAccountId)
                or (vCDAAccountId is null) )
           and (    (GLO.ACS_PF_ACCOUNT_ID = vPFAccountId)
                or (vPFAccountId is null) )
           and (    (GLO.ACS_CPN_ACCOUNT_ID = vCPNAccountId)
                or (vCPNAccountId is null) )
           and (    (GLO.ACS_DIVISION_ACCOUNT_ID = vDivAccountId)
                or (vDivAccountId is null) )
           and (    (GLO.ACS_BUDGET_ACCOUNT_ID = vBudAccountId)
                or (vBudAccountId is null) )
           and (    (GLO.ACS_QTY_UNIT_ID = vQtyAccountId)
                or (    vQtyAccountId is null
                    and GLO.ACS_QTY_UNIT_ID is null) )
           and (    (GLO.ACS_PJ_ACCOUNT_ID = vPJAccountId)
                or (vPJAccountId is null) );
      exception
        when others then
          vAmount  := 0;
          vQty     := 0;
      end;
    end if;

    if aGetAmount = 1 then
      return vAmount;
    else
      return vQty;
    end if;
  end PeriodBudgetAmountByQty;

  /**
  * function BudgetAmountByRCO
  * Description  Calcul d'un total dans le budget selon le coupe compte - dossier
  */
  function BudgetAmountByRCO(
    pAccountId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pCSubSet         ACS_SUB_SET.C_SUB_SET%type
  , pDocRecordID     DOC_RECORD.DOC_RECORD_ID%type
  , pQtyUnitId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pStartPerNum     ACS_PERIOD.PER_NO_PERIOD%type
  , pEndPerNum       ACS_PERIOD.PER_NO_PERIOD%type
  , pBudgetVersionId ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , aGetAmount       number
  )   -- 1: Montant 0: Quantit�
    return ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type
  is
    vAmount ACB_PERIOD_AMOUNT.PER_AMOUNT_D%type;
  begin
    begin
      select case
               when aGetAmount = 1 then nvl(sum(AMO.PER_AMOUNT_D - AMO.PER_AMOUNT_C), 0)
               else nvl(sum(AMO.PER_QTY_D - AMO.PER_QTY_C), 0)
             end AMOUNT
        into vAmount
        from ACS_PERIOD PER
           , ACB_PERIOD_AMOUNT AMO
           , ACB_GLOBAL_BUDGET GLO
       where GLO.ACB_BUDGET_VERSION_ID = pBudgetVersionId
         and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
         and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and PER.PER_NO_PERIOD >= pStartPerNum
         and PER.PER_NO_PERIOD <= pEndPerNum
         and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
         and GLO.C_BUDGET_KIND = '1'
         and GLO.DOC_RECORD_ID = pDocRecordID
         and nvl(GLO.ACS_QTY_UNIT_ID, 0) = nvl2(pQtyUnitId, pQtyUnitId, nvl(GLO.ACS_QTY_UNIT_ID, 0) )
         and decode(pCSubSet, 'CPN', GLO.ACS_CPN_ACCOUNT_ID, 'CDA', GLO.ACS_CDA_ACCOUNT_ID, 'PF', GLO.ACS_PF_ACCOUNT_ID, 'PJ', GLO.ACS_PJ_ACCOUNT_ID) =
                                                                                                                                                      pAccountID;
    exception
      when others then
        vAmount  := 0;
    end;

    return vAmount;
  end BudgetAmountByRCO;

/**********************************************************************************************************************/
  procedure DuplicateBudget(
    pSourceBudgetId            ACB_BUDGET.ACB_BUDGET_ID%type   /*Budget source             */
  , pBudgetDescr               ACB_BUDGET.BUD_DESCR%type   /*Descr. budget cible       */
  , pBudgetYearId              ACB_BUDGET.ACS_FINANCIAL_YEAR_ID%type   /*Exercice budget cible     */
  , pOnlyDefault               number   /*Seul. version/defaut      */
  , pCopyBase                  number   /*Copie des d�tails de type 'Budget de base'       */
  , pCopyCorrection            number   /*Copie des d�tails de type 'Correction de Budget' */
  , pOnlyMatrix                number   /*Matrice avec/sans val     */
  , pDuplicateAllChain         number   /*Duplifier toute la cha�ne */
  , pDuplicatedBudgetId in out ACB_BUDGET.ACB_BUDGET_ID%type   /*Param�tre de retour       */
  )
  is
    /*Curseur de recheche des versions du budget resp. de la version / d�faut */
    cursor BudgetVersionToDuplicate(pSourceBudgetId ACB_BUDGET.ACB_BUDGET_ID%type, pOnlyDefault number)
    is
      select *
        from ACB_BUDGET_VERSION
       where ACB_BUDGET_ID = pSourceBudgetId
         and VER_DEFAULT = decode(pOnlyDefault, 1, 1, VER_DEFAULT);

    BudgetVersion        BudgetVersionToDuplicate%rowtype;   /*R�ceptionne les donn�es du curseur */
    vDuplicatedVersionId ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type;   /*R�ceptionne l'id de la version cr��e  uniquement utilis� dans cette proc pour passage de param�tre*/
    vDuplicatedBudgetId  ACB_BUDGET.ACB_BUDGET_ID%type;   /*R�ceptionne l'id du budget cr��    */
  begin
    begin
      /*R�ception d'un nouvel Id de Budget*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedBudgetId
        from dual;

      /* Cr�ation de l'enregistrement sur la base du budget � duplifier*/
      insert into ACB_BUDGET
                  (ACB_BUDGET_ID
                 , ACS_FINANCIAL_YEAR_ID
                 , BUD_DESCR
                 , BUD_COMMENT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedBudgetId   /* Budget             -> Nouvel Id                      */
             , pBudgetYearId   /* Exercice comptable -> Initialis� par param�tre       */
             , pBudgetDescr   /* Description budget -> Initialis� par param�tre       */
             , BUD_COMMENT   /* Commentaire budget -> repris depuis la version source*/
             , sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from ACB_BUDGET
         where ACB_BUDGET_ID = pSourceBudgetId;

      /*Duplification de toute la cha�ne parent- enfant */
      if pDuplicateAllChain = 1 then
        /*Parcours des versions du budget � duplifier*/
        /*Chaque version est duplifi�e et est rattach�e au budget cible*/
        open BudgetVersionToDuplicate(pSourceBudgetId, pOnlyDefault);

        fetch BudgetVersionToDuplicate
         into BudgetVersion;

        while BudgetVersionToDuplicate%found loop
          DuplicateBudgetVersion(vDuplicatedBudgetId
                               ,   /*Lien sur le budget                */
                                 BudgetVersion.ACB_BUDGET_VERSION_ID
                               ,   /*Version source                    */
                                 BudgetVersion.VER_NUMBER
                               ,   /*N� de version cible               */
                                 pCopyBase
                               ,   /*Copie des d�tails de type 'Budget de base'       */
                                 pCopyCorrection
                               ,   /*Copie des d�tails de type 'Correction de Budget' */
                                 pOnlyMatrix
                               ,   /*Matrice avec/ sans valeurs        */
                                 pDuplicateAllChain
                               ,   /*Duplification cha�ne parent-enfant*/
                                 vDuplicatedVersionId   /*Id version cr��e                  */
                                );

          fetch BudgetVersionToDuplicate
           into BudgetVersion;
        end loop;
      end if;
    exception
      when others then
        vDuplicatedBudgetId  := 0;
        raise;
    end;

    pDuplicatedBudgetId  := vDuplicatedBudgetId;   /*Assignation du param�tre de retour*/
  end DuplicateBudget;

/**********************************************************************************************************************/
  procedure DuplicateBudgetVersion(
    pBudgetId                   ACB_BUDGET.ACB_BUDGET_ID%type   /*Lien sur le budget                */
  , pSourceVersionId            ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type   /*Version source                    */
  , pVersionNumber              ACB_BUDGET_VERSION.VER_NUMBER%type   /*N� de version cible               */
  , pCopyBase                   number   /*Copie des d�tails de type 'Budget de base'       */
  , pCopyCorrection             number   /*Copie des d�tails de type 'Correction de Budget' */
  , pOnlyMatrix                 number   /*Matrice avec/ sans valeurs        */
  , pDuplicateAllChain          number   /*Duplifier toute la cha�ne         */
  , pDuplicatedVersionId in out ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type   /*Id version cr��e                  */
  )
  is
    /*Curseur de recherche des budgets globaux de type 1(Budget de base) ou 2 (Correction de budget arr�t�) selon la copie
      de la version donn�e*/
    cursor GlobalBudgetToDuplicate(pSourceVersionId ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type, pCopyBase number, pCopyCorrection number)
    is
      select *
        from ACB_GLOBAL_BUDGET
       where ACB_BUDGET_VERSION_ID = pSourceVersionId
         and (    (C_BUDGET_TYPE = decode(pCopyBase, 1, 1, -1) )
              or (C_BUDGET_TYPE = decode(pCopyCorrection, 1, 2, -1) ) );

    GlobalBudget         GlobalBudgetToDuplicate%rowtype;   /*R�ceptionne les donn�es du curseur  */
    vDuplicatedVersionId ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type;   /*R�ceptionne l'id de la version cr��e*/
  begin
    begin
      /*R�ception d'un nouvel Id de version Budget*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedVersionId
        from dual;

      /* Cr�ation de l'enregistrement sur la base de la version � duplifier*/
      insert into ACB_BUDGET_VERSION
                  (ACB_BUDGET_VERSION_ID
                 , ACB_BUDGET_ID
                 , C_BUDGET_STATUS
                 , VER_NUMBER
                 , VER_COMMENT
                 , VER_DEFAULT
                 , VER_CASH_FLOW
                 , VER_MULTI_CURRENCY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedVersionId   /* Version budget     -> Nouvel Id                      */
             , pBudgetId   /* Budget             -> initialis� par param�tre       */
             , '0'   /* Statut version     -> forc� � 0 (Version non arr�t�e)*/
             , pVersionNumber   /* Num�ro version     -> initialis� par param�tre       */
             , VER_COMMENT   /* Commentaire        -> repris depuis la version source*/
             , 0   /* Version par d�faut -> forc� � 0                      */
             , 0   /* Version tr�sorerie -> forc� � 0                      */
             , VER_MULTI_CURRENCY
             , sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from ACB_BUDGET_VERSION
         where ACB_BUDGET_VERSION_ID = pSourceVersionId;

      /*Duplification de toute la cha�ne parent- enfant */
      if pDuplicateAllChain = 1 then
        DuplicateVersionCurrency(pSourceVersionId, vDuplicatedVersionId);

        /*Parcours des versions du budget � duplifier*/
        /*Chaque version est duplifi�e et est rattach�e au budget cible*/
        open GlobalBudgetToDuplicate(pSourceVersionId, pCopyBase, pCopyCorrection);

        fetch GlobalBudgetToDuplicate
         into GlobalBudget;

        while GlobalBudgetToDuplicate%found loop
          /*Duplification du budget global de la version source*/
          DuplicateVersionGlobalBudget(vDuplicatedVersionId
                                     ,   /* Lien sur Version nouvellement cr�ee par duplification    */
                                       GlobalBudget.ACB_GLOBAL_BUDGET_ID
                                     ,   /*Budget global                                             */
                                       pOnlyMatrix   /*Reprise (1) ou non (0) des valeurs de la matrice de saisie*/
                                      );

          fetch GlobalBudgetToDuplicate
           into GlobalBudget;
        end loop;
      end if;
    exception
      when others then
        vDuplicatedVersionId  := 0;
        raise;
    end;

    pDuplicatedVersionId  := vDuplicatedVersionId;   /*Assignation du param�tre de retour */
  end DuplicateBudgetVersion;

/**********************************************************************************************************************/
  procedure DuplicateVersionGlobalBudget(
    pTargetVersionId      ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type   /* Lien sur la version */
  , pSourceGlobalBudgetId ACB_GLOBAL_BUDGET.ACB_GLOBAL_BUDGET_ID%type   /*Budget glob. source  */
  , pOnlyMatrix           number   /*Matrice avec/ sans valeurs */
  )
  is
    /*Curseur de recherche des r�partitions p�riodiques du budget global */
    cursor GlobalBudgetPeriodAmount(pSourceGlobalBudgetId ACB_GLOBAL_BUDGET.ACB_GLOBAL_BUDGET_ID%type)
    is
      select *
        from ACB_PERIOD_AMOUNT
       where ACB_GLOBAL_BUDGET_ID = pSourceGlobalBudgetId;

    VPeriodAmount             GlobalBudgetPeriodAmount%rowtype;   /*R�ceptionne les donn�es du curseur         */
    vDuplicatedGlobalBudgetId ACB_GLOBAL_BUDGET.ACB_GLOBAL_BUDGET_ID%type;   /*R�ceptionne l'id du budget global duplifi� */
  begin
    begin
      /*R�ception d'un nouvel Id de Budget global*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedGlobalBudgetId
        from dual;

      insert into ACB_GLOBAL_BUDGET
                  (A_DATECRE
                 , A_IDCRE
                 , ACB_BUDGET_VERSION_ID
                 , ACB_GLOBAL_BUDGET_ID
                 , ACS_BUDGET_ACCOUNT_ID
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
                 , ACS_QTY_UNIT_ID
                 , C_BUDGET_KIND
                 , C_BUDGET_TYPE
                 , DIC_UPDATE_REASON_ID
                 , DOC_RECORD_ID
                 , FAM_FIXED_ASSETS_ID
                 , GCO_GOOD_ID
                 , GLO_AMOUNT_C
                 , GLO_AMOUNT_D
                 , GLO_DESCR
                 , GLO_QTY_C
                 , GLO_QTY_D
                 , GLO_RATE
                 , GLO_ROUNDED_AMOUNT
                 , GLO_AMOUNT_FC_D
                 , GLO_AMOUNT_FC_C
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , HRM_PERSON_ID
                 , PAC_PERSON_ID
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
                  )
        select sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
             , pTargetVersionId   /* Budget version     -> Lien sur la version cible      */
             , vDuplicatedGlobalBudgetId   /* Budget global      -> nouvel id  de budget global    */
             , ACS_BUDGET_ACCOUNT_ID   /* Compte budg�taire  -> repris du budget global source */
             , ACS_CDA_ACCOUNT_ID   /* Compte CDA         -> repris du budget global source */
             , ACS_CPN_ACCOUNT_ID   /* Compte CPN         -> repris du budget global source */
             , ACS_DIVISION_ACCOUNT_ID   /* Compte division    -> repris du budget global source */
             , ACS_FINANCIAL_ACCOUNT_ID   /* Compte financier   -> repris du budget global source */
             , ACS_FINANCIAL_CURRENCY_ID   /* monnaie comptable  -> repris du budget global source */
             , ACS_PF_ACCOUNT_ID   /* Compte porteur     -> repris du budget global source */
             , ACS_PJ_ACCOUNT_ID   /* Compte projet      -> repris du budget global source */
             , ACS_QTY_UNIT_ID   /* quantit�s          -> repris du budget global source */
             , C_BUDGET_KIND   /* Genre de budget    -> repris du budget global source */
             , 1   /* Type de budget     -> Forc� � 1 (Budget de base)     */
             , DIC_UPDATE_REASON_ID   /* Raison             -> repris du budget global source */
             , DOC_RECORD_ID   /* Lien sur dossier   -> repris du budget global source */
             , FAM_FIXED_ASSETS_ID   /* Lien sur immob     -> repris du budget global source */
             , GCO_GOOD_ID   /* Lien sur bien      -> repris du budget global source */
             , decode(pOnlyMatrix, 1, 0, GLO_AMOUNT_C)   /* Montant cr�dit     -> mise � 0 si uniquement reprise de la matrice sinon valeurs source*/
             , decode(pOnlyMatrix, 1, 0, GLO_AMOUNT_D)   /* Montant d�bit      -> mise � 0 si uniquement reprise de la matrice sinon valeurs source*/
             , GLO_DESCR   /* Libell�            -> repris du budget global source */
             , decode(pOnlyMatrix, 1, 0, GLO_QTY_C)   /* Quantit� cr�dit    -> mise � 0 si uniquement reprise de la matrice sinon valeurs source*/
             , decode(pOnlyMatrix, 1, 0, GLO_QTY_D)   /* Quantit� d�bit     -> mise � 0 si uniquement reprise de la matrice sinon valeurs source*/
             , GLO_RATE   /* Cours              -> repris du budget global source */
             , GLO_ROUNDED_AMOUNT   /* Diviseur           -> repris du budget global source */
             , GLO_AMOUNT_FC_D
             , GLO_AMOUNT_FC_C
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , HRM_PERSON_ID   /* Lien sur HRM       -> repris du budget global source */
             , PAC_PERSON_ID   /* Lien sur personne  -> repris du budget global source */
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
          from ACB_GLOBAL_BUDGET
         where ACB_GLOBAL_BUDGET_ID = pSourceGlobalBudgetId;

      /*Si pas de reprise unique de la matrice de saisie i.e reprise totale => */
      /* => Duplification des montants des r�partitiions p�riodiques du budget global courant*/
      if pOnlyMatrix = 0 then
        /*Parcours des r�partitions p�riodique du budget global*/
        /*Chaque r�partition est duplifi�e et est rattach�e au budget global cible*/
        open GlobalBudgetPeriodAmount(pSourceGlobalBudgetId);

        fetch GlobalBudgetPeriodAmount
         into vPeriodAmount;

        while GlobalBudgetPeriodAmount%found loop
          /*Duplification de la r�partition p�riodique*/
          DuplicatePeriodAmount(vDuplicatedGlobalBudgetId,   /*Lien sur budget global nouvellement cr��  */
                                vPeriodAmount.ACB_PERIOD_AMOUNT_ID   /*R�partition p�riodique source             */
                                                                  );

          fetch GlobalBudgetPeriodAmount
           into vPeriodAmount;
        end loop;
      end if;
    exception
      when others then
        null;
    end;
  end DuplicateVersionGlobalBudget;

/**********************************************************************************************************************/
  procedure DuplicatePeriodAmount(
    pTargetGlobalBudgetId ACB_GLOBAL_BUDGET.ACB_GLOBAL_BUDGET_ID%type
  , pSourcePeriodAmount   ACB_PERIOD_AMOUNT.ACB_PERIOD_AMOUNT_ID%type
  )
  is
  begin
    begin
      insert into ACB_PERIOD_AMOUNT
                  (ACB_PERIOD_AMOUNT_ID
                 , ACB_GLOBAL_BUDGET_ID
                 , ACS_PERIOD_ID
                 , PER_AMOUNT_D
                 , PER_AMOUNT_C
                 , PER_QTY_D
                 , PER_QTY_C
                 , ACB_CURRENCY_ID
                 , PER_AMOUNT_FC_D
                 , PER_AMOUNT_FC_C
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   /*R�partition p�riodique  -> Nouvel id pour le record         */
             , pTargetGlobalBudgetId                                    /*Budget global           -> Lien sur le budget global cible  */
                                       /*P�riode                 -> Correspond au m�me num�ro de p�riode de l'exercice cible          */
             , PER.ACS_PERIOD_ID
             , AMO.PER_AMOUNT_D   /*Montant d�bit           -> Repris de la r�partition source  */
             , AMO.PER_AMOUNT_C   /*Montant cr�dit          -> Repris de la r�partition source  */
             , AMO.PER_QTY_D   /*Quantit� d�bit          -> Repris de la r�partition source  */
             , AMO.PER_QTY_C   /*Quantit� cr�dit         -> Repris de la r�partition source  */
             , (SELECT CURTGT.ACB_CURRENCY_ID
                  FROM ACB_CURRENCY CURSRC,
                       ACB_CURRENCY CURTGT,
                       ACB_GLOBAL_BUDGET GLO
                 WHERE CURSRC.ACB_CURRENCY_ID = AMO.ACB_CURRENCY_ID
                   AND CURSRC.ACS_FINANCIAL_CURRENCY_ID = CURTGT.ACS_FINANCIAL_CURRENCY_ID
                   AND GLO.ACB_GLOBAL_BUDGET_ID = pTargetGlobalBudgetId
                   AND CURTGT.ACB_BUDGET_VERSION_ID = GLO.ACB_BUDGET_VERSION_ID) ACB_CURRENCY_ID
             , AMO.PER_AMOUNT_FC_D
             , AMO.PER_AMOUNT_FC_C
             , sysdate   /*Date cr�ation           -> Date syst�me                     */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /*Id cr�ation             -> user                             */
          from ACB_PERIOD_AMOUNT AMO
             , ACS_PERIOD PER
         where AMO.ACB_PERIOD_AMOUNT_ID = pSourcePeriodAmount
           and PER.PER_NO_PERIOD = (select PER_NO_PERIOD
                                      from ACS_PERIOD
                                     where ACS_PERIOD_ID = AMO.ACS_PERIOD_ID)
           and PER.ACS_FINANCIAL_YEAR_ID =
                 (select BUD.ACS_FINANCIAL_YEAR_ID
                    from ACB_GLOBAL_BUDGET GLO
                       , ACB_BUDGET_VERSION VER
                       , ACB_BUDGET BUD
                   where GLO.ACB_GLOBAL_BUDGET_ID = pTargetGlobalBudgetId
                     and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
                     and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID);
    exception
      when others then
        null;
    end;
  end DuplicatePeriodAmount;

  /**
  * function PeriodBudgetAmountByRco
  * Description Retourne le montant budg�tis� pour le dossier, filtre sur les axes analytiques
  */
  function PeriodBudgetAmountByRco(
    pDOC_RECORD_ID         DOC_RECORD.DOC_RECORD_ID%type
  , pACS_CPN_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_CDA_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_PF_ACCOUNT_ID     ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_PJ_ACCOUNT_ID     ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pPER_NO_PERIOD1        ACS_PERIOD.PER_NO_PERIOD%type
  , pPER_NO_PERIOD2        ACS_PERIOD.PER_NO_PERIOD%type
  , pACB_BUDGET_VERSION_ID ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , pGetAmount             number
  , pLevelSubRCO           number default -1
  )
    return ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type
  is
    vAmount ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type   default 0;
    vLevel  number;
  begin
    begin
      vLevel  := pLevelSubRCO;

      if vLevel > 20 then
        vLevel  := 20;
      end if;

      if vLevel > -1 then
        select decode(pGetAmount, 1, nvl(sum(AMO.PER_AMOUNT_D - AMO.PER_AMOUNT_C), 0), 0, nvl(sum(AMO.PER_QTY_D - AMO.PER_QTY_C), 0), 0) AMOUNT
          into vAmount
          from table(ACR_FUNCTIONS.GetChildrenLinkedDocRecord(pDOC_RECORD_ID, vLevel) ) ChildrenDoc
             , ACS_PERIOD PER
             , ACB_PERIOD_AMOUNT AMO
             , ACB_BUDGET BUD
             , ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
         where GLO.ACB_BUDGET_VERSION_ID = pACB_BUDGET_VERSION_ID
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID
           and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
           and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.PER_NO_PERIOD >= pPER_NO_PERIOD1
           and PER.PER_NO_PERIOD <= pPER_NO_PERIOD2
           and GLO.DOC_RECORD_ID = ChildrenDoc.column_value
           and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
           and GLO.C_BUDGET_KIND = '1'
           and (   GLO.ACS_CPN_ACCOUNT_ID = pACS_CPN_ACCOUNT_ID
                or (pACS_CPN_ACCOUNT_ID = 0) )
           and (   GLO.ACS_CDA_ACCOUNT_ID = pACS_CDA_ACCOUNT_ID
                or (pACS_CDA_ACCOUNT_ID = 0) )
           and (   GLO.ACS_PF_ACCOUNT_ID = pACS_PF_ACCOUNT_ID
                or (pACS_PF_ACCOUNT_ID = 0) )
           and (   GLO.ACS_PJ_ACCOUNT_ID = pACS_PJ_ACCOUNT_ID
                or (pACS_PJ_ACCOUNT_ID = 0) );
      else
        select decode(pGetAmount, 1, nvl(sum(AMO.PER_AMOUNT_D - AMO.PER_AMOUNT_C), 0), 0, nvl(sum(AMO.PER_QTY_D - AMO.PER_QTY_C), 0), 0) AMOUNT
          into vAmount
          from ACS_PERIOD PER
             , ACB_PERIOD_AMOUNT AMO
             , ACB_BUDGET BUD
             , ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
         where GLO.ACB_BUDGET_VERSION_ID = pACB_BUDGET_VERSION_ID
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
           and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID
           and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
           and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.PER_NO_PERIOD >= pPER_NO_PERIOD1
           and PER.PER_NO_PERIOD <= pPER_NO_PERIOD2
           and GLO.DOC_RECORD_ID = pDOC_RECORD_ID
           and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
           and GLO.C_BUDGET_KIND = '1'
           and (   GLO.ACS_CPN_ACCOUNT_ID = pACS_CPN_ACCOUNT_ID
                or (pACS_CPN_ACCOUNT_ID = 0) )
           and (   GLO.ACS_CDA_ACCOUNT_ID = pACS_CDA_ACCOUNT_ID
                or (pACS_CDA_ACCOUNT_ID = 0) )
           and (   GLO.ACS_PF_ACCOUNT_ID = pACS_PF_ACCOUNT_ID
                or (pACS_PF_ACCOUNT_ID = 0) )
           and (   GLO.ACS_PJ_ACCOUNT_ID = pACS_PJ_ACCOUNT_ID
                or (pACS_PJ_ACCOUNT_ID = 0) );
      end if;
    exception
      when others then
        vAmount  := 0;
    end;

    return vAmount;
  end PeriodBudgetAmountByRco;

  /**
  * function PeriodBudgetAmountByRcoList
  * Description Retourne le montant budg�tis� pour les dossiers list�s, filtre sur les axes analytiques
  */
  function PeriodBudgetAmountByRcoList(
    pACS_CPN_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_CDA_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_PF_ACCOUNT_ID     ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_PJ_ACCOUNT_ID     ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pPER_NO_PERIOD1        ACS_PERIOD.PER_NO_PERIOD%type
  , pPER_NO_PERIOD2        ACS_PERIOD.PER_NO_PERIOD%type
  , pACB_BUDGET_VERSION_ID ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , pGetAmount             number
  , pLevelSubRCO           number default -1
  )
    return ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type
  is
    tblDocRecordID ID_TABLE_TYPE;
    vAmount        ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type   default 0;
  begin
    tblDocRecordID  := ID_TABLE_TYPE();

    if ACR_FUNCTIONS.FillInTbl(tblDocRecordID) then
      for cpt in tblDocRecordID.first .. tblDocRecordID.last loop
        vAmount  :=
          vAmount +
          ACB_FUNCTIONS.PeriodBudgetAmountByRco(tblDocRecordID(cpt)
                                              , pACS_CPN_ACCOUNT_ID
                                              , pACS_CDA_ACCOUNT_ID
                                              , pACS_PF_ACCOUNT_ID
                                              , pACS_PJ_ACCOUNT_ID
                                              , pPER_NO_PERIOD1
                                              , pPER_NO_PERIOD2
                                              , pACB_BUDGET_VERSION_ID
                                              , pGetAmount
                                              , pLevelSubRCO
                                               );
      end loop;
    end if;

    return vAmount;
  end;

  /**
  * function PeriodBudgetAmountByRCO_Qty
  * Description  Retourne le montant budg�tis� pour la parit� dossier - autre axe analytique
  */
  function PeriodBudgetAmountByRCO_Qty(
    pDocRecordID     DOC_RECORD.DOC_RECORD_ID%type
  , pCSubSet         ACS_SUB_SET.C_SUB_SET%type
  , pAccountId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pQtyUnitId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pStartPerNum     ACS_PERIOD.PER_NO_PERIOD%type
  , pEndPerNum       ACS_PERIOD.PER_NO_PERIOD%type
  , pBudgetVersionId ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , pGetAmount       number
  , pLevelSubRCO     number default -1
  )
    return ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type
  is
    vAmount ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type   default 0;
    vLevel  number;
  begin
    /*D�finition des diff�rents comptes selon le sous-ensemble*/
    if     (pAccountID is not null)
       and (pCSubSet is not null)
       and (    (pCSubSet = 'CPN')
            or (pCSubSet = 'CDA')
            or (pCSubSet = 'COS')
            or (pCSubSet = 'PRO') ) then
      begin
        vLevel  := pLevelSubRCO;

        if vLevel > 20 then
          vLevel  := 20;
        end if;

        if vLevel > -1 then
          select decode(pGetAmount, 1, nvl(sum(AMO.PER_AMOUNT_D - AMO.PER_AMOUNT_C), 0), 0, nvl(sum(AMO.PER_QTY_D - AMO.PER_QTY_C), 0), 0) AMOUNT
            into vAmount
            from table(ACR_FUNCTIONS.GetChildrenLinkedDocRecord(pDocRecordID, vLevel) ) ChildrenDoc
               , ACS_PERIOD PER
               , ACB_PERIOD_AMOUNT AMO
               , ACB_BUDGET BUD
               , ACB_BUDGET_VERSION VER
               , ACB_GLOBAL_BUDGET GLO
           where GLO.ACB_BUDGET_VERSION_ID = pBudgetVersionId
             and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
             and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID
             and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
             and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
             and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
             and PER.PER_NO_PERIOD >= pStartPerNum
             and PER.PER_NO_PERIOD <= pEndPerNum
             and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
             and GLO.C_BUDGET_KIND = '1'
             and GLO.DOC_RECORD_ID = ChildrenDoc.column_value
             and decode(pCSubSet, 'CPN', GLO.ACS_CPN_ACCOUNT_ID, 'CDA', GLO.ACS_CDA_ACCOUNT_ID, 'COS', GLO.ACS_PF_ACCOUNT_ID, 'PRO', GLO.ACS_PJ_ACCOUNT_ID) =
                                                                                                                                                      pAccountID
             and nvl(GLO.ACS_QTY_UNIT_ID, 0) = nvl(pQtyUnitId, 0);
        else
          select decode(pGetAmount, 1, nvl(sum(AMO.PER_AMOUNT_D - AMO.PER_AMOUNT_C), 0), 0, nvl(sum(AMO.PER_QTY_D - AMO.PER_QTY_C), 0), 0) AMOUNT
            into vAmount
            from ACS_PERIOD PER
               , ACB_PERIOD_AMOUNT AMO
               , ACB_BUDGET BUD
               , ACB_BUDGET_VERSION VER
               , ACB_GLOBAL_BUDGET GLO
           where GLO.ACB_BUDGET_VERSION_ID = pBudgetVersionId
             and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
             and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID
             and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
             and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
             and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
             and PER.PER_NO_PERIOD >= pStartPerNum
             and PER.PER_NO_PERIOD <= pEndPerNum
             and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
             and GLO.C_BUDGET_KIND = '1'
             and GLO.DOC_RECORD_ID = pDocRecordID
             and decode(pCSubSet, 'CPN', GLO.ACS_CPN_ACCOUNT_ID, 'CDA', GLO.ACS_CDA_ACCOUNT_ID, 'COS', GLO.ACS_PF_ACCOUNT_ID, 'PRO', GLO.ACS_PJ_ACCOUNT_ID) =
                                                                                                                                                      pAccountID
             and nvl(GLO.ACS_QTY_UNIT_ID, 0) = nvl(pQtyUnitId, 0);
        end if;
      exception
        when others then
          vAmount  := 0;
      end;
    end if;

    return vAmount;
  end PeriodBudgetAmountByRCO_Qty;

  /**
  * function PeriodBudgetAmountByRCO_QtyLst
  * Description  Retourne le montant budg�tis� pour la parit� dossier - autre axe analytique selon une liste de dossier
  */
  function PeriodBudgetAmountByRCO_QtyLst(
    pCSubSet         ACS_SUB_SET.C_SUB_SET%type
  , pAccountId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pQtyUnitId       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pStartPerNum     ACS_PERIOD.PER_NO_PERIOD%type
  , pEndPerNum       ACS_PERIOD.PER_NO_PERIOD%type
  , pBudgetVersionId ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , pGetAmount       number
  , pLevelSubRCO     number default -1
  )
    return ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type
  is
    vAmount        ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type   default 0;
    tblDocRecordID ID_TABLE_TYPE;
  begin
    tblDocRecordID  := ID_TABLE_TYPE();

    if ACR_FUNCTIONS.FillInTbl(tblDocRecordID) then
      for cpt in tblDocRecordID.first .. tblDocRecordID.last loop
        vAmount  :=
          vAmount +
          ACB_FUNCTIONS.PeriodBudgetAmountByRCO_Qty(tblDocRecordID(cpt)
                                                  , pCSubSet
                                                  , pAccountId
                                                  , pQtyUnitId
                                                  , pStartPerNum
                                                  , pEndPerNum
                                                  , pBudgetVersionId
                                                  , pGetAmount
                                                  , pLevelSubRCO
                                                   );
      end loop;
    end if;

    return vAmount;
  end PeriodBudgetAmountByRCO_QtyLst;

  /**
  * procedure InsertPlaningExercise
  * Description cr�ation des p�riodes couvertes par le sc�nario
  */
  procedure InsertPlaningExercise(
    pACB_SCENARIO_ID           ACB_SCENARIO.ACB_SCENARIO_ID%type
  , pACS_REF_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pACS_FIN_YEAR_BUDG_ID      ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pACB_BUDGET_VERSION_ID     ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , pACB_BUDGET_VERSION2_ID    ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , pIntervalBefore            number
  , pIntervalAfter             number
  )
  is
    type PropExerciseRec is record(
      vACB_BUDGET_VERSION_ID ACB_SCE_EXERCISE.ACB_BUDGET_VERSION_ID%type
    , vPYE_NO_EXERCISE       ACS_PLAN_YEAR.PYE_NO_EXERCISE%type
    , vPYE_START_DATE        ACS_PLAN_YEAR.PYE_START_DATE%type
    , vPYE_END_DATE          ACS_PLAN_YEAR.PYE_END_DATE%type
    );

    vRefExercise PropExerciseRec;
    vBudExercise PropExerciseRec;
  begin
    vRefExercise.vACB_BUDGET_VERSION_ID  := pACB_BUDGET_VERSION_ID;
    vBudExercise.vACB_BUDGET_VERSION_ID  := pACB_BUDGET_VERSION2_ID;

    select nvl(max(PYE.PYE_NO_EXERCISE), 0)
         , max(PYE_START_DATE)
         , max(PYE_END_DATE)
      into vRefExercise.vPYE_NO_EXERCISE
         , vRefExercise.vPYE_START_DATE
         , vRefExercise.vPYE_END_DATE
      from ACS_PLAN_YEAR PYE
     where PYE.PYE_NO_EXERCISE = (select FYE_NO_EXERCICE
                                    from ACS_FINANCIAL_YEAR
                                   where ACS_FINANCIAL_YEAR_ID = pACS_REF_FINANCIAL_YEAR_ID);

    select nvl(max(PYE.PYE_NO_EXERCISE), 0)
         , max(PYE_START_DATE)
         , max(PYE_END_DATE)
      into vBudExercise.vPYE_NO_EXERCISE
         , vBudExercise.vPYE_START_DATE
         , vBudExercise.vPYE_END_DATE
      from ACS_PLAN_YEAR PYE
     where PYE.PYE_NO_EXERCISE = (select FYE_NO_EXERCICE
                                    from ACS_FINANCIAL_YEAR
                                   where ACS_FINANCIAL_YEAR_ID = pACS_FIN_YEAR_BUDG_ID);

    if vRefExercise.vPYE_NO_EXERCISE > 0 then
      --Ajout des p�riodes de base (avant le budget)
      insert into ACB_SCE_EXERCISE
                  (ACB_SCE_EXERCISE_ID
                 , ACB_SCENARIO_ID
                 , PYE_NO_EXERCISE
                 , PYE_START_DATE
                 , PYE_END_DATE
                 , ACB_BUDGET_VERSION_ID
                 , C_COVER_EXERCISE
                 , A_DATECRE
                 , A_IDCRE
                  )
        (select INIT_ID_SEQ.nextval
              , pACB_SCENARIO_ID
              , FYE.FYE_NO_EXERCICE
              , FYE.FYE_START_DATE
              , FYE.FYE_END_DATE
              , null
              , '1'
              , sysdate
              , PCS.PC_I_LIB_SESSION.GetUserIni
           from
--                              table(GetFinExerciseWithInterval(pACS_REF_FINANCIAL_YEAR_ID, pIntervalBefore))BEF,
                (select ACS_FINANCIAL_YEAR_ID
                   from (select   YEA.ACS_FINANCIAL_YEAR_ID
                             from ACS_FINANCIAL_YEAR YEA
                            where YEA.FYE_END_DATE < (select FYE_START_DATE
                                                        from ACS_FINANCIAL_YEAR
                                                       where ACS_FINANCIAL_YEAR_ID = pACS_REF_FINANCIAL_YEAR_ID)
                         order by YEA.FYE_END_DATE desc)
                  where rownum <= abs(pIntervalBefore) ) BEF
              , ACS_FINANCIAL_YEAR FYE
          where BEF.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID);

      --Ajout de la p�riode de r�f�rence (budget)
      insert into ACB_SCE_EXERCISE
                  (ACB_SCE_EXERCISE_ID
                 , ACB_SCENARIO_ID
                 , PYE_NO_EXERCISE
                 , PYE_START_DATE
                 , PYE_END_DATE
                 , ACB_BUDGET_VERSION_ID
                 , C_COVER_EXERCISE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (INIT_ID_SEQ.nextval
                 , pACB_SCENARIO_ID
                 , vRefExercise.vPYE_NO_EXERCISE
                 , vRefExercise.vPYE_START_DATE
                 , vRefExercise.vPYE_END_DATE
                 , decode(vRefExercise.vACB_BUDGET_VERSION_ID, 0, null, vRefExercise.vACB_BUDGET_VERSION_ID)
                 , '2'
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      if vBudExercise.vPYE_NO_EXERCISE > 0 then
        --Ajout de l'exercice budg�tis� 2
        insert into ACB_SCE_EXERCISE
                    (ACB_SCE_EXERCISE_ID
                   , ACB_SCENARIO_ID
                   , PYE_NO_EXERCISE
                   , PYE_START_DATE
                   , PYE_END_DATE
                   , ACB_BUDGET_VERSION_ID
                   , C_COVER_EXERCISE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval
                   , pACB_SCENARIO_ID
                   , vBudExercise.vPYE_NO_EXERCISE
                   , vBudExercise.vPYE_START_DATE
                   , vBudExercise.vPYE_END_DATE
                   , decode(vBudExercise.vACB_BUDGET_VERSION_ID, 0, null, vBudExercise.vACB_BUDGET_VERSION_ID)
                   , '2'
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;

      --Ajout des p�riodes de planification (simulation)
      insert into ACB_SCE_EXERCISE
                  (ACB_SCE_EXERCISE_ID
                 , ACB_SCENARIO_ID
                 , PYE_NO_EXERCISE
                 , PYE_START_DATE
                 , PYE_END_DATE
                 , ACB_BUDGET_VERSION_ID
                 , C_COVER_EXERCISE
                 , A_DATECRE
                 , A_IDCRE
                  )
        (select INIT_ID_SEQ.nextval
              , pACB_SCENARIO_ID
              , PYE.PYE_NO_EXERCISE
              , PYE.PYE_START_DATE
              , PYE.PYE_END_DATE
              , null
              , '3'
              , sysdate
              , PCS.PC_I_LIB_SESSION.GetUserIni
           from
--                              table(GetPlanExerciseWithInterval(vPYE_NO_EXERCISE, pIntervalAfter))AFT,
                (select ACS_PLAN_YEAR_ID
                   from (select   PYE.ACS_PLAN_YEAR_ID
                             from ACS_PLAN_YEAR PYE
                            where PYE.PYE_START_DATE >
                                    (select PYE_END_DATE
                                       from ACS_PLAN_YEAR
                                      where PYE_NO_EXERCISE =
                                                          decode(vBudExercise.vPYE_NO_EXERCISE
                                                               , 0, vRefExercise.vPYE_NO_EXERCISE
                                                               , vBudExercise.vPYE_NO_EXERCISE
                                                                ) )
                         order by PYE.PYE_START_DATE asc)
                  where rownum <= pIntervalAfter) AFT
              , ACS_PLAN_YEAR PYE
          where AFT.ACS_PLAN_YEAR_ID = PYE.ACS_PLAN_YEAR_ID);
    end if;
  end InsertPlaningExercise;

  /**
  * function GetPlanExerciseWithInterval
  * Description Recherche de l'exercice, d�cal� de la valeur de l'interval selon un exercice de r�f�rence
  */
  function GetPlanExerciseWithInterval(pPYE_NO_EXERCISE ACS_PLAN_YEAR.PYE_NO_EXERCISE%type, pInterval number)
    return ID_TABLE_TYPE
  is
    vResult ID_TABLE_TYPE;
  begin
    if sign(pInterval) < 0 then
      select cast(multiset(select ACS_PLAN_YEAR_ID
                             from (select   PYE.ACS_PLAN_YEAR_ID
                                       from ACS_PLAN_YEAR PYE
                                      where PYE.PYE_END_DATE < (select PYE_START_DATE
                                                                  from ACS_PLAN_YEAR
                                                                 where PYE_NO_EXERCISE = pPYE_NO_EXERCISE)
                                   order by PYE.PYE_END_DATE desc)
                            where rownum <= abs(pInterval) ) as ID_TABLE_TYPE)
        into vResult
        from dual;
    else
      select cast(multiset(select ACS_PLAN_YEAR_ID
                             from (select   PYE.ACS_PLAN_YEAR_ID
                                       from ACS_PLAN_YEAR PYE
                                      where PYE.PYE_START_DATE > (select PYE_END_DATE
                                                                    from ACS_PLAN_YEAR
                                                                   where PYE_NO_EXERCISE = pPYE_NO_EXERCISE)
                                   order by PYE.PYE_START_DATE asc)
                            where rownum <= pInterval) as ID_TABLE_TYPE)
        into vResult
        from dual;
    end if;

    return vResult;
  end GetPlanExerciseWithInterval;

  /**
  * function GetFinExerciseWithInterval
  * Description Recherche de l'exercice, d�cal� de la valeur de l'interval selon un exercice de r�f�rence
  */
  function GetFinExerciseWithInterval(pACS_REF_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type, pInterval number)
    return ID_TABLE_TYPE
  is
    vResult ID_TABLE_TYPE;
  begin
    if sign(pInterval) < 0 then
      select cast(multiset(select ACS_FINANCIAL_YEAR_ID
                             from (select   YEA.ACS_FINANCIAL_YEAR_ID
                                       from ACS_FINANCIAL_YEAR YEA
                                      where YEA.FYE_END_DATE < (select FYE_START_DATE
                                                                  from ACS_FINANCIAL_YEAR
                                                                 where ACS_FINANCIAL_YEAR_ID = pACS_REF_FINANCIAL_YEAR_ID)
                                   order by YEA.FYE_END_DATE desc)
                            where rownum <= abs(pInterval) ) as ID_TABLE_TYPE
                 )
        into vResult
        from dual;
    else
      select cast(multiset(select ACS_FINANCIAL_YEAR_ID
                             from (select   YEA.ACS_FINANCIAL_YEAR_ID
                                       from ACS_FINANCIAL_YEAR YEA
                                      where YEA.FYE_START_DATE > (select FYE_END_DATE
                                                                    from ACS_FINANCIAL_YEAR
                                                                   where ACS_FINANCIAL_YEAR_ID = pACS_REF_FINANCIAL_YEAR_ID)
                                   order by YEA.FYE_START_DATE asc)
                            where rownum <= pInterval) as ID_TABLE_TYPE
                 )
        into vResult
        from dual;
    end if;

    return vResult;
  end GetFinExerciseWithInterval;

  /**
  * fonction ExistBudgetingAmount
  * Description Retourne 1 s'il existe des montants (ACB_SCE_AMOUNT) venant d'un �l�ment budg�taire pour la paire compte-division
  */
  function ExistBudgetingAmount(pACB_ELEMENT_ID ACB_SCE_AMOUNT.ACB_ELEMENT_ID%type)
    return number
  is
    vResult number(1);
  begin
    select nvl(max(1), 0)
      into vResult
      from ACB_SCE_AMOUNT SCM
     where SCM.ACB_ELEMENT_ID = pACB_ELEMENT_ID
       and (    (SCM.SCM_AMOUNT_ALL_LC_D <> 0)
            or (SCM.SCM_AMOUNT_ALL_LC_C <> 0) );

    return vResult;
  end;

  /**
  * fonction ImportPlaningAuto
  * Description  Cr�ation d'une version de budget depuis une planification
  */
  procedure ImportPlaningAuto(
    pACB_BUDGET_ID             ACB_BUDGET.ACB_BUDGET_ID%type
  , pACB_SCENARIO_ID           ACB_SCENARIO.ACB_SCENARIO_ID%type
  , pVER_NUMBER                ACB_BUDGET_VERSION.VER_NUMBER%type
  , pACB_BUDGET_VERSION_ID out ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  )
  is
    vACB_BUDGET_VERSION_ID     ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type           default 0;
    vACB_SCE_EXERCISE_ID       ACB_SCE_EXERCISE.ACB_SCE_EXERCISE_ID%type;
    vACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    pACB_BUDGET_VERSION_ID  := 0;

    -- Recherche de l'exercice de planification appartenant au scenario et � l'exercice du budget
    select nvl(max(SCE.ACB_SCE_EXERCISE_ID), 0)
      into vACB_SCE_EXERCISE_ID
      from ACB_SCE_EXERCISE SCE
     where SCE.ACB_SCENARIO_ID = pACB_SCENARIO_ID
       and SCE.PYE_NO_EXERCISE = (select max(YEA.FYE_NO_EXERCICE)
                                    from ACB_BUDGET BUD
                                       , ACS_FINANCIAL_YEAR YEA
                                   where BUD.ACB_BUDGET_ID = pACB_BUDGET_ID
                                     and BUD.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID);

    select nvl(max(ACS_FINANCIAL_CURRENCY_ID), 0)
      into vACS_FINANCIAL_CURRENCY_ID
      from ACS_FINANCIAL_CURRENCY
     where FIN_LOCAL_CURRENCY = '1';

    if vACB_SCE_EXERCISE_ID > 0 then
      select init_id_seq.nextval
        into vACB_BUDGET_VERSION_ID
        from dual;

      --Cr�ation d'une nouvelle version de budget
      insert into ACB_BUDGET_VERSION
                  (ACB_BUDGET_VERSION_ID
                 , ACB_BUDGET_ID
                 , C_BUDGET_STATUS
                 , VER_NUMBER
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vACB_BUDGET_VERSION_ID
                 , pACB_BUDGET_ID
                 , '0'
                 , pVER_NUMBER
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      --Recherche des donn�es dans ACB_SCE_AMOUNT de type El�ment budg�taire et planification
      --pour les ajouter dans la version de budget pr�c�demment cr��e
      insert into ACB_GLOBAL_BUDGET
                  (ACB_GLOBAL_BUDGET_ID
                 , ACB_BUDGET_VERSION_ID
                 , C_BUDGET_TYPE
                 , C_BUDGET_KIND
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , GLO_AMOUNT_D
                 , GLO_AMOUNT_C
                 , A_DATECRE
                 , A_IDCRE
                  )
        (select init_id_seq.nextval
              , vACB_BUDGET_VERSION_ID
              , '1'
              , '1'
              , vACS_FINANCIAL_CURRENCY_ID
              , vACS_FINANCIAL_CURRENCY_ID
              , ACS_FINANCIAL_ACCOUNT_ID
              , ACS_DIVISION_ACCOUNT_ID
              , SCM_AMOUNT_ALL_LC_D
              , SCM_AMOUNT_ALL_LC_C
              , sysdate
              , PCS.PC_I_LIB_SESSION.GetUserIni
           from (select   SCM.ACS_FINANCIAL_ACCOUNT_ID
                        , SCM.ACS_DIVISION_ACCOUNT_ID
                        , decode(sign(nvl(sum(nvl(SCM.SCM_AMOUNT_ALL_LC_D, 0) ), 0) - nvl(sum(nvl(SCM.SCM_AMOUNT_ALL_LC_C, 0) ), 0) )
                               , 1, nvl(sum(nvl(SCM.SCM_AMOUNT_ALL_LC_D, 0) ), 0) - nvl(sum(nvl(SCM.SCM_AMOUNT_ALL_LC_C, 0) ), 0)
                               , 0
                                ) SCM_AMOUNT_ALL_LC_D
                        , decode(sign(nvl(sum(nvl(SCM.SCM_AMOUNT_ALL_LC_D, 0) ), 0) - nvl(sum(nvl(SCM.SCM_AMOUNT_ALL_LC_C, 0) ), 0) )
                               , -1, abs(nvl(sum(nvl(SCM.SCM_AMOUNT_ALL_LC_D, 0) ), 0) - nvl(sum(nvl(SCM.SCM_AMOUNT_ALL_LC_C, 0) ), 0) )
                               , 0
                                ) SCM_AMOUNT_ALL_LC_C
                     from ACB_SCE_AMOUNT SCM
                        , ACS_FINANCIAL_ACCOUNT FIN
                    where SCM.ACB_SCE_EXERCISE_ID = vACB_SCE_EXERCISE_ID
                      and SCM.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                      and FIN.C_BALANCE_SHEET_PROFIT_LOSS = 'P'
                 group by SCM.ACS_FINANCIAL_ACCOUNT_ID
                        , SCM.ACS_DIVISION_ACCOUNT_ID) );

      GenerateVersionCurrency(vACB_BUDGET_VERSION_ID);

      --Passer le scenario � un statut 3 = repris
      update ACB_SCENARIO
         set C_ACB_SCENARIO_STATUS = '3'
       where ACB_SCENARIO_ID = pACB_SCENARIO_ID;

      pACB_BUDGET_VERSION_ID  := vACB_BUDGET_VERSION_ID;
    end if;
  end ImportPlaningAuto;

  /**
  * fonction GetBudAmount4ACRDiv
  * Description  retourne le montant d'un budget selon les comptes pr�sent dans une table temporaire
  */
  function GetBudAmount4ACRDiv(
    pACB_BUDGET_VERSION_ID    ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , pACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pPER_NO_PERIOD_FROM       ACS_PERIOD.PER_NO_PERIOD%type
  , pPER_NO_PERIOD_TO         ACS_PERIOD.PER_NO_PERIOD%type
  )
    return ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type
  is
    vAmount ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type;
  begin
    select nvl(sum(PER_AMOUNT_D - PER_AMOUNT_C), 0)
      into vAmount
      from ACS_PERIOD PER
         , ACB_PERIOD_AMOUNT AMO
         , ACB_BUDGET BUD
         , ACB_BUDGET_VERSION VER
         , ACB_GLOBAL_BUDGET GLO
     where GLO.ACB_BUDGET_VERSION_ID = pACB_BUDGET_VERSION_ID
       and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
       and VER.ACB_BUDGET_ID = BUD.ACB_BUDGET_ID
       and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
       and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
       and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and PER.PER_NO_PERIOD >= pPER_NO_PERIOD_FROM
       and PER.PER_NO_PERIOD <= pPER_NO_PERIOD_TO
       and GLO.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
       and GLO.C_BUDGET_KIND = '1'
       and (GLO.ACS_DIVISION_ACCOUNT_ID in(select TMP.LID_FREE_NUMBER_1
                                             from COM_LIST_ID_TEMP TMP
                                            where TMP.LID_CODE = 'MAIN_ID') )
       and (    (nvl(GLO.ACS_FINANCIAL_ACCOUNT_ID, 0) = pACS_FINANCIAL_ACCOUNT_ID)
            or (pACS_FINANCIAL_ACCOUNT_ID = 0) );

    return vAmount;
  exception
    when no_data_found then
      return 0;
  end GetBudAmount4ACRDiv;

  /**
  * Description  G�n�ration de la monnaie de base et des taux p�riodiques obligatoire par version
  */
  procedure GenerateVersionCurrency(in_AcbVersionId in ACB_CURRENCY.ACB_BUDGET_VERSION_ID%type)
  is
    lt_crud_def      FWK_I_TYP_DEFINITION.T_CRUD_DEF;
    ln_AcbCurrencyId ACB_CURRENCY.ACB_CURRENCY_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACB_ENTITY.gcAcbCurrency, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACB_BUDGET_VERSION_ID', in_AcbVersionId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'CUR_DEFAULT', 1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_FINANCIAL_CURRENCY_ID', ACS_FUNCTION.GETLOCALCURRENCYID);
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    ln_AcbCurrencyId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(lt_crud_def, 'ACB_CURRENCY_ID');
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
    GenerateCurrencyPeriodsRate(ln_AcbCurrencyId);
    SetPeriodRateAmounts(ln_AcbCurrencyId, 1);
  end GenerateVersionCurrency;

  /**
  * Description  G�n�ration des cours de devise p�riodiques selon les p�riodes
  *   de gestion rattach�es � l�exercice du budget et la devise donn�e.
  *   Les valeurs des cours sont par d�faut � 0.00000
  */
  procedure GenerateCurrencyPeriodsRate(in_AcbCurrencyId in ACB_CURRENCY.ACB_CURRENCY_ID%type)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACB_ENTITY.gcAcbPeriodRate, lt_crud_def);

    for tplPeriods in (select   PER.ACS_PERIOD_ID
                           from ACS_PERIOD PER
                              , ACB_CURRENCY CUR
                              , ACB_BUDGET_VERSION VER
                              , ACB_BUDGET BUD
                          where CUR.ACB_CURRENCY_ID = in_AcbCurrencyId
                            and VER.ACB_BUDGET_VERSION_ID = CUR.ACB_BUDGET_VERSION_ID
                            and BUD.ACB_BUDGET_ID = VER.ACB_BUDGET_ID
                            and PER.ACS_FINANCIAL_YEAR_ID = BUD.ACS_FINANCIAL_YEAR_ID
                            and PER.C_TYPE_PERIOD = '2'
                       order by PER.PER_NO_PERIOD asc) loop
      FWK_I_MGT_ENTITY.clear(lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACB_CURRENCY_ID', in_AcbCurrencyId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_PERIOD_ID', tplPeriods.ACS_PERIOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'PER_CURRENCY_RATE', 0);
      FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    end loop;

    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end GenerateCurrencyPeriodsRate;

  /**
  * Description  Mise � jour des taux p�riodiques non intialis�es (donc � 0.00) avec le montant donn�
  *              proc�dure appel�e lors de la premi�re saisie de taux suite � la cr�ation automatique
  *              des taux
  */
  procedure SetPeriodRateAmounts(in_AcbCurrencyId in ACB_CURRENCY.ACB_CURRENCY_ID%type, in_CurrencyRate in ACB_PERIOD_RATE.PER_CURRENCY_RATE%type)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    for tplPeriods in (select ACB_PERIOD_RATE_ID
                         from ACB_PERIOD_RATE
                        where ACB_CURRENCY_ID = in_AcbCurrencyId
                          and PER_CURRENCY_RATE = 0) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACB_ENTITY.gcAcbPeriodRate, lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACB_PERIOD_RATE_ID', tplPeriods.ACB_PERIOD_RATE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'PER_CURRENCY_RATE', in_CurrencyRate);
      FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
      FWK_I_MGT_ENTITY.Release(lt_crud_def);
    end loop;
  end SetPeriodRateAmounts;

  /**
  * Description  Mise � jour des montants en monnaie de base calcul� sur les taux de conversion de la monnaie
  *   �trang�re des p�riodes de la r�partition p�riodique de la version donn�e
  */
  procedure CalculateBaseAmounts(in_AcbBudgetVersionId in ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type)
  is
    /*Curseur de recheche des r�partitions p�riodiques de lignes de budget de la version donn�e
      avec les taux de conversion  */
    cursor cr_VersionCurrenciesPeriods(in_BudgetVersionId in ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type)
    is
      select   PER.*
             , PRA.PER_CURRENCY_RATE
             , (PER_AMOUNT_FC_D * PER_CURRENCY_RATE) LC_D
             , (PER_AMOUNT_FC_C * PER_CURRENCY_RATE) LC_C
          from ACB_PERIOD_AMOUNT PER
             , ACB_PERIOD_RATE PRA
             , ACB_CURRENCY CUR
         where CUR.ACB_BUDGET_VERSION_ID = in_BudgetVersionId
           and CUR.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GETLOCALCURRENCYID
           and PER.ACB_CURRENCY_ID = CUR.ACB_CURRENCY_ID
           and PRA.ACB_CURRENCY_ID = PER.ACB_CURRENCY_ID
           and PRA.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
      order by ACB_GLOBAL_BUDGET_ID
             , PER.ACS_PERIOD_ID;

    ln_CurrencyPeriod  cr_VersionCurrenciesPeriods%rowtype;
    lt_crud_def_Period FWK_I_TYP_DEFINITION.T_CRUD_DEF;
    lt_crud_def_Global FWK_I_TYP_DEFINITION.T_CRUD_DEF;
    ln_GlobalBudgetId  ACB_GLOBAL_BUDGET.ACB_GLOBAL_BUDGET_ID%type;
    ln_GlobalAmount_D  ACB_GLOBAL_BUDGET.GLO_AMOUNT_D%type;
    ln_GlobalAmount_C  ACB_GLOBAL_BUDGET.GLO_AMOUNT_C%type;
  begin
    ln_GlobalBudgetId  := 0.0;

    open cr_VersionCurrenciesPeriods(in_AcbBudgetVersionId);

    fetch cr_VersionCurrenciesPeriods
     into ln_CurrencyPeriod;

    while cr_VersionCurrenciesPeriods%found loop
      --R�initialisation des la somme des montants des p�riodes et
      --Mise � jour des montants globaux en cas de changement de ligne de budget global
      if ln_GlobalBudgetId <> ln_CurrencyPeriod.ACB_GLOBAL_BUDGET_ID then
        if ln_GlobalBudgetId <> 0.0 then
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACB_ENTITY.gcAcbGlobalBudget, lt_crud_def_Global);
          FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_Global, 'ACB_GLOBAL_BUDGET_ID', ln_GlobalBudgetId);
          FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_Global, 'GLO_AMOUNT_D', ln_GlobalAmount_D);
          FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_Global, 'GLO_AMOUNT_C', ln_GlobalAmount_C);
          FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def_Global);
          FWK_I_MGT_ENTITY.Release(lt_crud_def_Global);
        end if;

        ln_GlobalBudgetId  := ln_CurrencyPeriod.ACB_GLOBAL_BUDGET_ID;
        ln_GlobalAmount_D  := 0.0;
        ln_GlobalAmount_C  := 0.0;
      end if;

      --Tenue de la somme des r�partitions p�riodiques de la ligne de budget
      ln_GlobalAmount_D  := ln_GlobalAmount_D + ln_CurrencyPeriod.LC_D;
      ln_GlobalAmount_C  := ln_GlobalAmount_C + ln_CurrencyPeriod.LC_C;
      --Mise � jour des montants p�riodiques en monnaie de base
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACB_ENTITY.gcAcbPeriodAmount, lt_crud_def_Period);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_Period, 'ACB_PERIOD_AMOUNT_ID', ln_CurrencyPeriod.ACB_PERIOD_AMOUNT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_Period, 'PER_AMOUNT_D', ln_CurrencyPeriod.LC_D);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_Period, 'PER_AMOUNT_C', ln_CurrencyPeriod.LC_C);
      FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def_Period);
      FWK_I_MGT_ENTITY.Release(lt_crud_def_Period);

      fetch cr_VersionCurrenciesPeriods
       into ln_CurrencyPeriod;
    end loop;

    --Mise � jour des montants globaux de la derni�re position globale
    if ln_GlobalBudgetId <> 0.0 then
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACB_ENTITY.gcAcbGlobalBudget, lt_crud_def_Global);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_Global, 'ACB_GLOBAL_BUDGET_ID', ln_GlobalBudgetId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_Global, 'GLO_AMOUNT_D', ln_GlobalAmount_D);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_Global, 'GLO_AMOUNT_C', ln_GlobalAmount_C);
      FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def_Global);
      FWK_I_MGT_ENTITY.Release(lt_crud_def_Global);
    end if;
  end CalculateBaseAmounts;

  procedure DuplicateVersionCurrency(
    in_SourceBudgetVersionId in ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  , in_TargetBudgetVersionId in ACB_BUDGET_VERSION.ACB_BUDGET_VERSION_ID%type
  )
  is
    lt_crud_def_currency  FWK_I_TYP_DEFINITION.T_CRUD_DEF;
    lt_crud_def_rates     FWK_I_TYP_DEFINITION.T_CRUD_DEF;
    ln_SourceCurrencyId   ACB_CURRENCY.ACB_CURRENCY_ID%type;
    ln_TargetCurrencyId   ACB_CURRENCY.ACB_CURRENCY_ID%type;
    ln_TargetPeriodRateId ACB_PERIOD_RATE.ACB_PERIOD_RATE_ID%type;
  begin
    ln_SourceCurrencyId  := 0.0;
    ln_TargetCurrencyId  := 0.0;
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACB_ENTITY.gcAcbCurrency, lt_crud_def_currency);
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACB_ENTITY.gcAcbPeriodRate, lt_crud_def_rates);

    for tplCurrency in (select CUR.ACS_FINANCIAL_CURRENCY_ID
                             , CUR.CUR_DEFAULT
                             , ACB_CURRENCY_ID
                          from ACB_CURRENCY CUR
                         where CUR.ACB_BUDGET_VERSION_ID = in_SourceBudgetVersionId) loop
      FWK_I_MGT_ENTITY.clear(lt_crud_def_currency);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_currency, 'ACB_BUDGET_VERSION_ID', in_TargetBudgetVersionId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_currency, 'ACS_FINANCIAL_CURRENCY_ID', tplCurrency.ACS_FINANCIAL_CURRENCY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_currency, 'CUR_DEFAULT', tplCurrency.CUR_DEFAULT);
      FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def_currency);
      ln_SourceCurrencyId  := tplCurrency.ACB_CURRENCY_ID;
      ln_TargetCurrencyId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(lt_crud_def_currency, 'ACB_CURRENCY_ID');

      --Pour chaque devise ajout�e, cr�er les r�partitions p�riodiques selon le p�riodes de l'execice de la nouvelle version
      for tplPeriodsRate in (select PER.PER_NO_PERIOD
                                  , PER.ACS_PERIOD_ID
                                  , (select PRA.PER_CURRENCY_RATE
                                       from ACB_PERIOD_RATE PRA
                                          , ACS_PERIOD S_PER
                                      where PRA.ACB_CURRENCY_id = ln_SourceCurrencyId
                                        and S_PER.ACS_PERIOD_ID = PRA.ACS_PERIOD_ID
                                        and PER.PER_NO_PERIOD = S_PER.PER_NO_PERIOD) RATE
                               from ACS_PERIOD PER
                                  , ACS_FINANCIAL_YEAR YEA
                                  , ACB_BUDGET_VERSION VER
                                  , ACB_BUDGET BUD
                              where VER.ACB_BUDGET_VERSION_ID = in_TargetBudgetVersionId
                                and BUD.ACB_BUDGET_ID = VER.ACB_BUDGET_ID
                                and YEA.ACS_FINANCIAL_YEAR_ID = BUD.ACS_FINANCIAL_YEAR_ID
                                and PER.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
                                and PER.C_TYPE_PERIOD = '2') loop
        FWK_I_MGT_ENTITY.clear(lt_crud_def_rates);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_rates, 'ACB_CURRENCY_ID', ln_TargetCurrencyId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_rates, 'ACS_PERIOD_ID', tplPeriodsRate.ACS_PERIOD_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def_rates, 'PER_CURRENCY_RATE', tplPeriodsRate.RATE);
        FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def_rates);
      end loop;
    end loop;

    FWK_I_MGT_ENTITY.Release(lt_crud_def_currency);
    FWK_I_MGT_ENTITY.Release(lt_crud_def_rates);
  end DuplicateVersionCurrency;
end ACB_FUNCTIONS;
