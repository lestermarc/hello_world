--------------------------------------------------------
--  DDL for Package Body GAL_BUDGET_CLOSING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_BUDGET_CLOSING" 
is
  /**
  * procedure ExtractProjectLines
  * Description
  *   Insertion des lignes budgétaires dans la table temp pour l'affaire
  * @created NGV Oct. 2010
  * @lastUpdate
  * @public
  * @param  aProjectID : ID de l'affaire à traiter
  */
  procedure ExtractProjectLines(aProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
  is
    vCurrentPeriodID    GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type;
    vNextPeriodID       GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type;
    vCount              integer;
    vcfg                varchar2(30);
    v_instr             number(2);
    v_commited_amount   number(14,2);
    v_commited_quantity number(14,2);

  begin
    -- Effacer les données de la table temporaire
    delete from GAL_BUDGET_LINE_TEMP;

    -- Déterminer la période ouverte de l'affaire
    select max(GAL_BUDGET_PERIOD_ID)
      into vCurrentPeriodID
      from GAL_PROJECT
     where GAL_PROJECT_ID = aProjectID
       and PRJ_BUDGET_PERIOD = 1;

    if vCurrentPeriodID is not null then
      -- Rechercher l'id de la période suivante
      vNextPeriodID  := GAL_BDG_PERIOD_FUNCTIONS.GetNextPeriod(aPeriodID => vCurrentPeriodID, aDate => null);


      vcfg := pcs.pc_config.getconfig('GAL_SPEND_COMMITED_COLUMNS');

      if vcfg is null then
        vcfg  := '1';
      end if;

      -- Insertion de toutes les lignes de budget de la période ouverte en question
      insert into GAL_BUDGET_LINE_TEMP
                  (GAL_BUDGET_LINE_TEMP_ID
                 , GAL_PROJECT_ID
                 , GAL_BUDGET_ID
                 , GAL_COST_CENTER_ID
                 , GAL_BUDGET_LINE_ID
                 , GAL_NEXT_BUDGET_LINE_ID
                 , BLT_BUDGET_QUANTITY
                 , BLT_BUDGET_AMOUNT
                 , BLT_COMMITED_QUANTITY
                 , BLT_COMMITED_AMOUNT
                 , BLT_PRODUCED_QUANTITY
                 , BLT_PRODUCED_AMOUNT
                 , BLT_REMAINING_QUANTITY
                 , BLT_REMAINING_AMOUNT
                 , BLT_DEFER_QUANTITY
                 , BLT_DEFER_AMOUNT
                 , BLT_COMMENT
                 , BLT_OPEN_NEW_PERIOD
                  )
        select INIT_ID_SEQ.nextval as GAL_BUDGET_LINE_TEMP_ID
             , PRJ.GAL_PROJECT_ID
             , BLI.GAL_BUDGET_ID
             , BLI.GAL_COST_CENTER_ID
             , BLI.GAL_BUDGET_LINE_ID
             , (select max(BLI_NEXT.GAL_BUDGET_LINE_ID)
                  from GAL_BUDGET_LINE BLI_NEXT
                 where BLI_NEXT.GAL_BUDGET_ID = BLI.GAL_BUDGET_ID
                   and BLI_NEXT.GAL_COST_CENTER_ID = BLI.GAL_COST_CENTER_ID
                   and BLI_NEXT.GAL_BUDGET_PERIOD_ID = vNextPeriodID) GAL_NEXT_BUDGET_LINE_ID
             , nvl(BLI.BLI_BUDGET_QUANTITY, 0) as BLT_BUDGET_QUANTITY
             , nvl(BLI.BLI_BUDGET_AMOUNT, 0) as BLT_BUDGET_AMOUNT
             , 0 as BLT_COMMITED_QUANTITY
             , 0 as BLT_COMMITED_AMOUNT
             , 0 as BLT_PRODUCED_QUANTITY
             , 0 as BLT_PRODUCED_AMOUNT
             , nvl(BLI.BLI_REMAINING_QUANTITY, 0) as BLT_REMAINING_QUANTITY
             , nvl(BLI.BLI_REMAINING_AMOUNT, 0) as BLT_REMAINING_AMOUNT
             , nvl(BLI.BLI_REMAINING_QUANTITY, 0) as BLT_DEFER_QUANTITY
             , nvl(BLI.BLI_REMAINING_AMOUNT, 0) as BLT_DEFER_AMOUNT
             , null as BLT_COMMENT
             , 0 as BLT_OPEN_NEW_PERIOD
          from GAL_PROJECT PRJ
             , GAL_BUDGET BDG
             , GAL_BUDGET_LINE BLI
             , GAL_COST_CENTER GCC
         where PRJ.GAL_PROJECT_ID = aProjectID
           and PRJ.GAL_PROJECT_ID = BDG.GAL_PROJECT_ID
           and BDG.GAL_BUDGET_ID = BLI.GAL_BUDGET_ID
           and BLI.GAL_COST_CENTER_ID = GCC.GAL_COST_CENTER_ID
           and BLI.GAL_BUDGET_PERIOD_ID = PRJ.GAL_BUDGET_PERIOD_ID
           and BLI.BLI_CLOTURED = 0;

      -- Contrôler s'il y a des données dans la table temp avant de continuer le traitement
      select count(*)
        into vCount
        from GAL_BUDGET_LINE_TEMP;

      if vCount > 0 then
        -- Mettre "Créer période" à 1, s'il n'y a pas de ligne pour la période suivante
        update GAL_BUDGET_LINE_TEMP
           set BLT_OPEN_NEW_PERIOD = 1
         where GAL_NEXT_BUDGET_LINE_ID is null;

        -- Générer la structure budgétaire pour l'affaire en question
        GAL_PROJECT_CONSOLIDATION.GAL_SPENDING_GENERATE(aGalProjectId => aProjectID);

        for tplConsolidated in (select   GAL_BUDGET_ID
                                       , GAL_COST_CENTER_ID
                                       , nvl(GSP_COL1_QUANTITY, 0) as BLT_COL1_QUANTITY
                                       , nvl(GSP_COL1_AMOUNT, 0) as BLT_COL1_AMOUNT
                                       , nvl(GSP_COL2_QUANTITY, 0) as BLT_COL2_QUANTITY
                                       , nvl(GSP_COL2_AMOUNT, 0) as BLT_COL2_AMOUNT
                                       , nvl(GSP_COL3_QUANTITY, 0) as BLT_COL3_QUANTITY
                                       , nvl(GSP_COL3_AMOUNT, 0) as BLT_COL3_AMOUNT
                                       , nvl(GSP_COL4_QUANTITY, 0) as BLT_COL4_QUANTITY
                                       , nvl(GSP_COL4_AMOUNT, 0) as BLT_COL4_AMOUNT
                                       , nvl(GSP_COL5_QUANTITY, 0) as BLT_COL5_QUANTITY
                                       , nvl(GSP_COL5_AMOUNT, 0) as BLT_COL5_AMOUNT
                                       , nvl(GSP_REMAINING_AMOUNT, 0) as BLT_REMAINING_AMOUNT
                                       , nvl(GSP_REMAINING_QUANTITY, 0) as BLT_REMAINING_QUANTITY
                                        , nvl(GSP_REMAINING_AMOUNT, 0) as BLT_DEFER_AMOUNT
                                       , nvl(GSP_REMAINING_QUANTITY, 0) as BLT_DEFER_QUANTITY
                                    from GAL_SPENDING_CONSOLIDATED
                                   where GAL_PROJECT_ID = aProjectID
                                     and GAL_BUDGET_PERIOD_ID = vCurrentPeriodID
                                order by 1
                                       , 2) loop



         v_commited_amount   :=  tplConsolidated.BLT_COL1_AMOUNT;
         v_commited_quantity :=  tplConsolidated.BLT_COL1_QUANTITY;

         select instr(vcfg, '3')
          into v_instr
          from dual;
         if v_instr > 0 then
           v_commited_amount:=  v_commited_amount+ tplConsolidated.BLT_COL3_AMOUNT;
           v_commited_quantity:=   v_commited_quantity + tplConsolidated.BLT_COL3_QUANTITY;
         end if;
         select instr(vcfg, '4')
           into v_instr
           from dual;
         if v_instr > 0 then
           v_commited_amount:= v_commited_amount+ tplConsolidated.BLT_COL4_AMOUNT;
           v_commited_quantity:=  v_commited_quantity + tplConsolidated.BLT_COL4_QUANTITY;
         end if;
         select instr(vcfg, '5')
          into v_instr
          from dual;
          if v_instr > 0 then
            v_commited_amount:= v_commited_amount+ tplConsolidated.BLT_COL5_AMOUNT;
            v_commited_quantity:=  v_commited_quantity + tplConsolidated.BLT_COL5_QUANTITY;
         end if;

          update GAL_BUDGET_LINE_TEMP
             set BLT_COMMITED_QUANTITY =  v_commited_quantity
               , BLT_COMMITED_AMOUNT =  v_commited_amount
               , BLT_PRODUCED_QUANTITY = tplConsolidated.BLT_COL2_QUANTITY
               , BLT_PRODUCED_AMOUNT = tplConsolidated.BLT_COL2_AMOUNT
               , BLT_REMAINING_AMOUNT = tplConsolidated.BLT_REMAINING_AMOUNT
               , BLT_REMAINING_QUANTITY = tplConsolidated.BLT_REMAINING_QUANTITY
               , BLT_DEFER_AMOUNT = tplConsolidated.BLT_DEFER_AMOUNT
               , BLT_DEFER_QUANTITY = tplConsolidated.BLT_DEFER_QUANTITY
           where GAL_BUDGET_ID = tplConsolidated.GAL_BUDGET_ID
             and GAL_COST_CENTER_ID = tplConsolidated.GAL_COST_CENTER_ID;
        end loop;
      end if;
    end if;
  end ExtractProjectLines;

  /**
  * procedure CloseProjectPeriod
  * Description
  *   Bouclement d'une période budgétaire d'une affaire
  */
  procedure CloseProjectPeriod(aProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
  is
    vNextPeriodID GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type;
    vNewLineID    GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type;
  begin
    -- Rechercher l'id de la prochaine période (pour la création de lignes de budget)
    select GAL_BDG_PERIOD_FUNCTIONS.GetNextPeriod(GAL_BUDGET_PERIOD_ID, null)
      into vNextPeriodID
      from GAL_PROJECT
     where GAL_PROJECT_ID = aProjectID;


    for tplLines in (select   GAL_BUDGET_LINE_TEMP_ID
                            , GAL_PROJECT_ID
                            , GAL_BUDGET_ID
                            , GAL_COST_CENTER_ID
                            , GAL_BUDGET_LINE_ID
                            , GAL_NEXT_BUDGET_LINE_ID
                            , BLT_BUDGET_QUANTITY
                            , BLT_BUDGET_AMOUNT
                            , BLT_COMMITED_QUANTITY
                            , BLT_COMMITED_AMOUNT
                            , BLT_PRODUCED_QUANTITY
                            , BLT_PRODUCED_AMOUNT
                            , BLT_REMAINING_QUANTITY
                            , BLT_REMAINING_AMOUNT
                            , nvl(BLT_DEFER_AMOUNT, 0) BLT_DEFER_AMOUNT
                            , BLT_COMMENT
                            , BLT_OPEN_NEW_PERIOD
                         from GAL_BUDGET_LINE_TEMP
                     order by GAL_BUDGET_ID
                            , GAL_BUDGET_LINE_ID) loop
      vNewLineID  := null;



      -- Création de la ligne de budget pour la prochaine période si inexistante ET demandé
      if     (tplLines.GAL_NEXT_BUDGET_LINE_ID is null)
         and (tplLines.BLT_OPEN_NEW_PERIOD = 1) then
        -- Création de la ligne de budget par copie
        GAL_BDG_PERIOD_FUNCTIONS.DuplicateBudgetLine(aSrcBudgetLineID   => tplLines.GAL_BUDGET_LINE_ID
                                                   , aNewPeriodID       => vNextPeriodID
                                                   , aNewBudgetLineID   => vNewLineID
                                                    );
        -- Prochaine ligne de budget existe déjà
        else
        vNewLineID  := tplLines.GAL_NEXT_BUDGET_LINE_ID;
      end if;

      -- Bouclement de la période sans report !!pas possibe hmo 2.02.2011 si treste à engagger est 0 mais qiu'il y a des dépenses
      --if tplLines.BLT_DEFER_AMOUNT = 0 then
      --  GAL_BUDGET_FUNCTIONS.CloseBudgetLine(aBudgetLineID => tplLines.GAL_BUDGET_LINE_ID);
      --else
      -- Bouclement de la période avec report
      -- Création du transfert et de l'historique de transfert (en cas de report )
      -- dans ce cas, on ne veut pas créer de nouvelle période, alors on ne fait rien


      if vNewLineId is null then
        update gal_budget_line set bli_clotured  = 1 where gal_budget_line_id =   tplLines.GAL_BUDGET_LINE_ID;

      else
        GAL_BUDGET_FUNCTIONS.CreateBudgetTransfert(aSrcBudgetLineID   => tplLines.GAL_BUDGET_LINE_ID
                                                     , aTgtBudgetLineID   => vNewLineID
                                                     , aQuantity          => null
                                                     , aPrice             => null
                                                     , aAmount            => tplLines.BLT_DEFER_AMOUNT
                                                     , aComment           => tplLines.BLT_COMMENT
                                                     , aClosing           => 1
                                                     , aSrcCommitedQty => tplLines.BLT_COMMITED_QUANTITY
                                                     , aSrcCommitedAmount =>   tplLines.BLT_COMMITED_AMOUNT
                                                      );


      end if;
    end loop;

    -- Màj du champ de la période ouverte de l'affaire
    GAL_BDG_PERIOD_FUNCTIONS.UpdateProjectPeriod(aProjectID => aProjectID);
  end CloseProjectPeriod;
end GAL_BUDGET_CLOSING;
