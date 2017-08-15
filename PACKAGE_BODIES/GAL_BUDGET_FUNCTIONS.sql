--------------------------------------------------------
--  DDL for Package Body GAL_BUDGET_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_BUDGET_FUNCTIONS" 
is
  /**
  * procedure CreateBudgetTransfert
  * Description
  *   Transfert de budget entre 2 lignes de budget
  */
  procedure CreateBudgetTransfert(
    aSrcBudgetLineID   in GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type
  , aTgtBudgetLineID   in GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type
  , aQuantity          in GAL_BUDGET_LINE.BLI_BUDGET_QUANTITY%type
  , aPrice             in GAL_BUDGET_LINE.BLI_BUDGET_PRICE%type
  , aAmount            in GAL_BUDGET_LINE.BLI_BUDGET_AMOUNT%type
  , aComment           in GAL_BUDGET_LINE.BLI_COMMENT%type
  , aClosing           in integer default 0
  , aSrcCommitedQty    in GAL_BUDGET_LINE_TEMP.BLT_COMMITED_QUANTITY%type
  , aSrcCommitedAmount in GAL_BUDGET_LINE_TEMP.BLT_COMMITED_AMOUNT%type
  )
  is
    vSrcOld          GAL_BUDGET_LINE%rowtype;
    vTgtOld          GAL_BUDGET_LINE%rowtype;
    vSrcNew          GAL_BUDGET_LINE%rowtype;
    vTgtNew          GAL_BUDGET_LINE%rowtype;
    vTransfert       GAL_BUDGET_TRANSFERT%rowtype;
    -- Engagement
    vCommitedQty     GAL_SPENDING_CONSOLIDATED.GSP_COL1_QUANTITY%type;
    vCommitedAmount  GAL_SPENDING_CONSOLIDATED.GSP_COL1_AMOUNT%type;
    -- Reste à engager
    vRemainingAmount GAL_BUDGET_LINE.BLI_REMAINING_QUANTITY%type;
    vRemainingQty    GAL_BUDGET_LINE.BLI_REMAINING_AMOUNT%type;
    -- Engagé
    vHangSpendAmount GAL_BUDGET_LINE.BLI_HANGING_SPENDING_QUANTITY%type;
    vHangSpendQty    GAL_BUDGET_LINE.BLI_HANGING_SPENDING_AMOUNT%type;
    -- Estimation
    vLastEstimAmount GAL_BUDGET_LINE.BLI_LAST_ESTIMATION_QUANTITY%type;
    vLastEstimQty    GAL_BUDGET_LINE.BLI_LAST_ESTIMATION_AMOUNT%type;
  begin
    -- Sauvegarder les anciennes valeurs des lignes de budget source
    select *
      into vSrcOld
      from GAL_BUDGET_LINE
     where GAL_BUDGET_LINE_ID = aSrcBudgetLineID;

    -- Sauvegarder les anciennes valeurs des lignes de budget cible
    select *
      into vTgtOld
      from GAL_BUDGET_LINE
     where GAL_BUDGET_LINE_ID = aTgtBudgetLineID;

    -- Bouclement de période
    if aClosing = 1 then
      -- Bouclement de la ligne de budget source
      CloseBudgetLine(aBudgetLineID => aSrcBudgetLineID);

      -- Attention, le calcul du suivi financier a été lancé dans la méthode
      -- de préparation du bouclement (GAL_BUDGET_CLOSING.ExtractProjectLines)
      -- Màj de la ligne de budget cible

      -- Qté et montant engagé

      --      hmo 2.02.2011
--GetCommitedValues(vSrcOld.GAL_BUDGET_ID
--                      , vSrcOld.GAL_COST_CENTER_ID
--                      , vSrcOld.GAL_BUDGET_PERIOD_ID
--                      , vCommitedQty
--                      , vCommitedAmount
--                       );
      begin
        select nvl(GSP_COL1_AMOUNT, 0) + nvl(GSP_COL2_AMOUNT, 0) + nvl(GSP_COL3_AMOUNT, 0) + nvl(GSP_COL4_AMOUNT, 0) + nvl(GSP_COL5_AMOUNT, 0)
          into vCommitedAmount
          from gal_spending_consolidated
         where GAL_BUDGET_ID = vTgtOld.GAL_BUDGET_ID
           and GAL_COST_CENTER_ID = vTgtOld.GAL_COST_CENTER_ID
           and GAL_BUDGET_PERIOD_ID = vTgtOld.GAL_BUDGET_PERIOD_ID;
      exception
        when no_data_found then
          vCommitedAmount  := 0;
      end;

      begin
        select nvl(GSP_COL1_QUANTITY, 0) + nvl(GSP_COL2_QUANTITY, 0) + nvl(GSP_COL3_QUANTITY, 0) + nvl(GSP_COL4_QUANTITY, 0) + nvl(GSP_COL5_QUANTITY, 0)
          into vCommitedQty
          from gal_spending_consolidated
         where GAL_BUDGET_ID = vTgtOld.GAL_BUDGET_ID
           and GAL_COST_CENTER_ID = vTgtOld.GAL_COST_CENTER_ID
           and GAL_BUDGET_PERIOD_ID = vTgtOld.GAL_BUDGET_PERIOD_ID;
      exception
        when no_data_found then
          vCommitedQty  := 0;
      end;

      begin
        select nvl(GSP_REMAINING_AMOUNT, 0)
          into vRemainingAmount
          from gal_spending_consolidated
         where GAL_BUDGET_ID = vTgtOld.GAL_BUDGET_ID
           and GAL_COST_CENTER_ID = vTgtOld.GAL_COST_CENTER_ID
           and GAL_BUDGET_PERIOD_ID = vTgtOld.GAL_BUDGET_PERIOD_ID;
      exception
        when no_data_found then
          vRemainingAmount  := nvl(vTgtOld.BLI_BUDGET_AMOUNT, 0);
      end;

      -- Reste à engager
      vRemainingAmount  := vRemainingAmount + aAmount;

      select decode(vTgtOld.BLI_REMAINING_PRICE, 0, 0, round(vRemainingAmount / vTgtOld.BLI_REMAINING_PRICE, 2) )
        into vRemainingQty
        from dual;

      -- Engagé
      vHangSpendAmount  := vCommitedAmount + aSrcCommitedAmount;
      vHangSpendQty     := vCommitedQty + aSrcCommitedQty;
      -- Estimation
      vLastEstimAmount  := vRemainingAmount + vHangSpendAmount;
      vLastEstimQty     := vRemainingQty + vHangSpendQty;

      update GAL_BUDGET_LINE
         set BLI_REMAINING_QUANTITY = vRemainingQty
           , BLI_REMAINING_AMOUNT = vRemainingAmount
           , BLI_HANGING_SPENDING_QUANTITY = vHangSpendQty
           , BLI_HANGING_SPENDING_AMOUNT = vHangSpendAmount
           , BLI_LAST_ESTIMATION_QUANTITY = vLastEstimQty
           , BLI_LAST_ESTIMATION_AMOUNT = vLastEstimAmount
           , BLI_LAST_REMAINING_DATE = sysdate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where GAL_BUDGET_LINE_ID = aTgtBudgetLineID;
    else
      -- Transfert simple
      null;
    end if;

    -- Récuperer les nouvelles valeurs des lignes de budget source
    select *
      into vSrcNew
      from GAL_BUDGET_LINE
     where GAL_BUDGET_LINE_ID = aSrcBudgetLineID;

    -- Récuperer les nouvelles valeurs des lignes de budget cible
    select *
      into vTgtNew
      from GAL_BUDGET_LINE
     where GAL_BUDGET_LINE_ID = aTgtBudgetLineID;

    -- Init de l'id, date création, id création
    select INIT_ID_SEQ.nextval
         , sysdate
         , PCS.PC_I_LIB_SESSION.GetUserIni
      into vTransfert.GAL_BUDGET_TRANSFERT_ID
         , vTransfert.A_DATECRE
         , vTransfert.A_IDCRE
      from dual;

    -- Valeurs du transfert
    vTransfert.GBT_QUANTITY            := aQuantity;
    vTransfert.GBT_PRICE               := aPrice;
    vTransfert.GBT_AMOUNT              := aAmount;
    vTransfert.GBT_COMMENT             := aComment;
    -- Source
    vTransfert.GAL_S_BUDGET_LINE_ID    := vSrcOld.GAL_BUDGET_LINE_ID;
    vTransfert.GAL_S_COST_CENTER_ID    := vSrcOld.GAL_COST_CENTER_ID;
    vTransfert.GAL_S_BUDGET_PERIOD_ID  := vSrcOld.GAL_BUDGET_PERIOD_ID;
    vTransfert.GBT_S_WORDING           := vSrcOld.BLI_WORDING;
    vTransfert.GBT_S_QUANTITY1         := vSrcOld.BLI_BUDGET_QUANTITY;
    vTransfert.GBT_S_QUANTITY2         := vSrcNew.BLI_BUDGET_QUANTITY;
    vTransfert.GBT_S_PRICE1            := vSrcOld.BLI_BUDGET_PRICE;
    vTransfert.GBT_S_PRICE2            := vSrcNew.BLI_BUDGET_PRICE;
    vTransfert.GBT_S_AMOUNT1           := vSrcOld.BLI_BUDGET_AMOUNT;
    vTransfert.GBT_S_AMOUNT2           := vSrcNew.BLI_BUDGET_AMOUNT;
    -- Cible
    vTransfert.GAL_T_BUDGET_ID         := vTgtOld.GAL_BUDGET_ID;
    vTransfert.GAL_T_BUDGET_LINE_ID    := vTgtOld.GAL_BUDGET_LINE_ID;
    vTransfert.GAL_T_COST_CENTER_ID    := vTgtOld.GAL_COST_CENTER_ID;
    vTransfert.GAL_T_BUDGET_PERIOD_ID  := vTgtOld.GAL_BUDGET_PERIOD_ID;
    vTransfert.GBT_T_WORDING           := vTgtOld.BLI_WORDING;
    vTransfert.GBT_T_SEQUENCE          := vTgtOld.BLI_SEQUENCE;
    vTransfert.GBT_T_DESCRIPTION       := vTgtOld.BLI_DESCRIPTION;
    vTransfert.GBT_T_COMMENT           := vTgtOld.BLI_COMMENT;
    vTransfert.GBT_T_QUANTITY1         := vTgtOld.BLI_BUDGET_QUANTITY;
    vTransfert.GBT_T_QUANTITY2         := vTgtNew.BLI_BUDGET_QUANTITY;
    vTransfert.GBT_T_PRICE1            := vTgtOld.BLI_BUDGET_PRICE;
    vTransfert.GBT_T_PRICE2            := vTgtNew.BLI_BUDGET_PRICE;
    vTransfert.GBT_T_AMOUNT1           := vTgtOld.BLI_BUDGET_AMOUNT;
    vTransfert.GBT_T_AMOUNT2           := vTgtNew.BLI_BUDGET_AMOUNT;

    insert into GAL_BUDGET_TRANSFERT
         values vTransfert;
  end CreateBudgetTransfert;

  /**
  * procedure CloseBudgetLine
  * Description
  *   Bouclement d'une ligne de budget
  */
  procedure CloseBudgetLine(aBudgetLineID in GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type)
  is
    vBudgetID GAL_BUDGET.GAL_BUDGET_ID%type;
  begin
    -- Bouclement de la ligne de budget
    update    GAL_BUDGET_LINE
          set BLI_REMAINING_QUANTITY = 0
            , BLI_REMAINING_PRICE = 0
            , BLI_REMAINING_AMOUNT = 0
            , BLI_LAST_REMAINING_DATE = sysdate
            , BLI_LAST_ESTIMATION_QUANTITY = 0
            , BLI_LAST_ESTIMATION_AMOUNT = 0
            , BLI_CLOTURED = 1
            , A_DATEMOD = sysdate
            , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
        where GAL_BUDGET_LINE_ID = aBudgetLineID
    returning GAL_BUDGET_ID
         into vBudgetID;

    -- Màj de la date de la première et dernière période budgetaire
    GAL_BDG_PERIOD_FUNCTIONS.UpdateBudgetPeriodDates(aBudgetID => vBudgetID);
  end CloseBudgetLine;

  /**
  * procedure GetCommitedValues
  * Description
  *   Recherche la qté et montant engagé pour un code budget/nature analytique
  */
  procedure GetCommitedValues(
    aBudgetID       in     GAL_BUDGET.GAL_BUDGET_ID%type
  , aCostCenterID   in     GAL_COST_CENTER.GAL_COST_CENTER_ID%type
  , aBudgetPeriodID in     GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type
  , aCommitedQty    out    GAL_SPENDING_CONSOLIDATED.GSP_COL1_QUANTITY%type
  , aCommitedAmount out    GAL_SPENDING_CONSOLIDATED.GSP_COL1_AMOUNT%type
  )
  is
    type TGetCommitedValues is ref cursor;

    crGetCommitedValues TGetCommitedValues;
    vCfg                varchar2(30);
    vQtyColumns         varchar2(3000);
    vAmountColumns      varchar2(3000);
  begin
    -- Construire la cmd pour la recherche de la qté et montant engagé
    -- Si la cmd sql est vide ou changement de propriétaire du schèma
    if    (vSQLCommitedValues is null)
       or (vCompOwner <> PCS.PC_I_LIB_SESSION.GetCompanyOwner) then
      -- Stocker le propriétaire du schèma
      vCompOwner          := PCS.PC_I_LIB_SESSION.GetCompanyOwner;
      -- Somme des colonnes pour l'engagé
      vQtyColumns         := ' 0 ';
      vAmountColumns      := ' 0 ';
      -- Lecture de la config indiquant les champs indiv à tenir compte pour
      -- le calcul de la qté et du montant engagé
      vCfg                := PCS.PC_CONFIG.GetConfig('GAL_SPEND_COMMITED_COLUMNS');

      -- si la config est nulle, utiliser seulement les champs GSP_COL1_QUANTITY et GSP_COL1_AMOUNT
      if vCfg is null then
        vCfg  := '1';
      end if;

      -- Identifier les colonnes à aditionner pour obtenir l'engagé
      -- Qté  => GSP_COL1_QUANTITY .. GSP_COL5_QUANTITY
      -- Montant  => GSP_COL1_AMOUNT .. GSP_COL5_AMOUNT
      for tplColumns in (select column_value
                           from table(PCS.charListToTable(vCfg) ) ) loop
        vQtyColumns     := vQtyColumns || ' + nvl(GSP_COL' || tplColumns.column_value || '_QUANTITY, 0) ';
        vAmountColumns  := vAmountColumns || ' + nvl(GSP_COL' || tplColumns.column_value || '_AMOUNT, 0) ';
      end loop;

      -- cmd sql pour le calcul de l'engagé
      vSQLCommitedValues  :=
        'select ' ||
        vQtyColumns ||
        ' as BLT_COMMITED_QUANTITY ' ||
        chr(10) ||
        '     , ' ||
        vAmountColumns ||
        ' as BLT_COMMITED_AMOUNT   ' ||
        chr(10) ||
        '  from GAL_SPENDING_CONSOLIDATED                ' ||
        chr(10) ||
        ' where GAL_BUDGET_ID = :GAL_BUDGET_ID           ' ||
        chr(10) ||
        '   and GAL_COST_CENTER_ID = :GAL_COST_CENTER_ID ' ||
        chr(10) ||
        '   and GAL_BUDGET_PERIOD_ID = :GAL_BUDGET_PERIOD_ID ';
    end if;

    begin
      open crGetCommitedValues for vSQLCommitedValues using aBudgetID, aCostCenterID, aBudgetPeriodID;

      fetch crGetCommitedValues
       into aCommitedQty
          , aCommitedAmount;

      close crGetCommitedValues;
    exception
      when others then
        aCommitedQty     := 0;
        aCommitedAmount  := 0;
    end;
  end GetCommitedValues;
end GAL_BUDGET_FUNCTIONS;
