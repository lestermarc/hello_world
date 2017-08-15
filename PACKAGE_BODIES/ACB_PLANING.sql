--------------------------------------------------------
--  DDL for Package Body ACB_PLANING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACB_PLANING" 
is
  /**
  * procedure CreateAllPeriods
  * Description
  *  Vide la table des montants du scénario et appelle les différentes procédures de calculs
  * @lastUpdate
  * @public
  * @param pACB_SCENARION_ID
  */
  procedure CreateAllPeriods(pACB_SCENARIO_ID ACB_SCENARIO.ACB_SCENARIO_ID%type)
  is
  begin
    --Suppression de toutes les lignes correspondants au scenario
    delete from ACB_SCE_AMOUNT SCM
          where exists(
                     select ACB_SCE_EXERCISE_ID
                       from ACB_SCE_EXERCISE SEX
                      where SEX.ACB_SCENARIO_ID = pACB_SCENARIO_ID
                        and SCM.ACB_SCE_EXERCISE_ID = SEX.ACB_SCE_EXERCISE_ID);

    --Création des périodes de base (ACT_TOTAL_BY_PERIOD)
    CreateBasePeriods(pACB_SCENARIO_ID);
    /*
     Création des périodes budgétisées (ACB_BUDGET_VERSION + ACT_TOTAL_BY_PERIOD)
     Si le budget n'est pas renseigné (ACB_SCE_EXERCICE.ACB_BUDGET_VERSION_ID = null), cela signifie que l'on va chercher les montants effectivement réalisés.
     Dans ce cas:
       - reprendre les montants dans les cumuls
     ou alors prendre les montants :
       - dans les budgets (ACB_GLOBAL_BUDGET), uniquement les comptes PP
       - dans les cumuls (ACT_TOTAL_BY_PERIOD) le solde des comptes B pour l'exercice représentant les périodes budgétisées
       - ainsi que les montants fixes (C_ACB_BUDGETING_ELEMENT = '2')
    */
    CreateBudgetPeriods(pACB_SCENARIO_ID);
    --Création des éléments automatisés
    CreateAutomatismElements(pACB_SCENARIO_ID);
    --Création des positions du tableau 10
    CreateReportPosition(pACB_SCENARIO_ID);

    --Mise à jour des information de modifcation.
    update ACB_SCENARIO
       set A_DATEMOD = sysdate
         , a_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where ACB_SCENARIO_ID = pACB_SCENARIO_ID;
  end CreateAllPeriods;

  /**
  * procedure CreateBasePeriods
  * Description
  *  Reprend les montants de la table ACT_TOT_BY_PERIOD pour les périodes de base choisies
  */
  procedure CreateBasePeriods(pACB_SCENARIO_ID ACB_SCENARIO.ACB_SCENARIO_ID%type)
  is
    vC_AMOUNT_ORIGIN  ACB_SCE_AMOUNT.C_AMOUNT_ORIGIN%type;
    vC_COVER_EXERCISE ACB_SCE_EXERCISE.C_COVER_EXERCISE%type;
    vExistDivi        signtype;
  begin
    vC_AMOUNT_ORIGIN   := '8';   --Provenance des montants: effectif, déjà existant
    vC_COVER_EXERCISE  := '1';   --période réalisée
    vExistDIVI         := ACS_FUNCTION.ExistDIVI;

    --Ajout de toutes les lignes de cumul correspondantes aux périodes de base d'un scenario(C_COVER_EXERCISE = 1)
    for tblFinYearID in (select YEA.ACS_FINANCIAL_YEAR_ID
                              , SEX.ACB_SCE_EXERCISE_ID
                               , BSC.BSC_CUM_TYP_INT
                               , BSC.BSC_CUM_TYP_EXT
                               , BSC.BSC_CUM_TYP_PRE
                               , BSC.BSC_CUM_TYP_ENG
                           from ACS_FINANCIAL_YEAR YEA
                              , ACB_SCE_EXERCISE SEX
                               , ACB_SCENARIO BSC
                           where BSC.ACB_SCENARIO_ID = pACB_SCENARIO_ID
                            and SEX.ACB_SCENARIO_ID = BSC.ACB_SCENARIO_ID
                            and SEX.C_COVER_EXERCISE = vC_COVER_EXERCISE
                            and YEA.FYE_NO_EXERCICE = SEX.PYE_NO_EXERCISE) loop
      insert into ACB_SCE_AMOUNT
                  (ACB_SCE_AMOUNT_ID
                 , ACB_SCE_EXERCISE_ID
                 , C_AMOUNT_ORIGIN
                 , SCM_AMOUNT_ALL_LC_D
                 , SCM_AMOUNT_ALL_LC_C
                 , SCM_AMOUNT_LC_D
                 , SCM_AMOUNT_LC_C
                 , SCM_AMOUNT_DIFF_LC_D
                 , SCM_AMOUNT_DIFF_LC_C
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , SCM_MANUAL
                 , A_DATECRE
                 , A_IDCRE
                  )
        (select INIT_ID_SEQ.nextval
              , tblFinYearID.ACB_SCE_EXERCISE_ID
              , vC_AMOUNT_ORIGIN
              , decode(sign(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC), 1, TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC, 0)
              , decode(sign(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC), -1, abs(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC), 0)
              , decode(sign(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC), 1, TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC, 0)
              , decode(sign(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC), -1, abs(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC), 0)
              , 0
              , 0
              , TOT.ACS_FINANCIAL_ACCOUNT_ID
              , TOT.ACS_DIVISION_ACCOUNT_ID
              , 0
              , sysdate
              , PCS.PC_I_LIB_SESSION.GetUserIni
           from (select   nvl(sum(nvl(TOT.TOT_DEBIT_LC, 0) ), 0) TOT_DEBIT_LC
                        , nvl(sum(nvl(TOT.TOT_CREDIT_LC, 0) ), 0) TOT_CREDIT_LC
                        , TOT.ACS_FINANCIAL_ACCOUNT_ID
                        , TOT.ACS_DIVISION_ACCOUNT_ID
                     from ACT_TOTAL_BY_PERIOD TOT
                        , ACS_PERIOD PER
                    where PER.ACS_FINANCIAL_YEAR_ID = tblFinYearID.ACS_FINANCIAL_YEAR_ID
                      and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                        and (    (     (tblFinYearID.BSC_CUM_TYP_INT = 1)
                                  and (TOT.C_TYPE_CUMUL = 'INT') )
                             or (     (tblFinYearID.BSC_CUM_TYP_EXT = 1)
                                 and (TOT.C_TYPE_CUMUL = 'EXT') )
                             or (     (tblFinYearID.BSC_CUM_TYP_PRE = 1)
                                 and (TOT.C_TYPE_CUMUL = 'PRE') )
                             or (     (tblFinYearID.BSC_CUM_TYP_ENG = 1)
                                 and (TOT.C_TYPE_CUMUL = 'ENG') )
                            )
                      and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                      and (    (     (vExistDivi > 0)
                                and TOT.ACS_DIVISION_ACCOUNT_ID is not null)
                           or (     (vExistDivi < 1)
                               and TOT.ACS_DIVISION_ACCOUNT_ID is null)
                          )
                 group by TOT.ACS_FINANCIAL_ACCOUNT_ID
                        , TOT.ACS_DIVISION_ACCOUNT_ID) TOT);
    end loop;
  end CreateBasePeriods;

  /**
  * procedure CreateBudgetPeriods
  * Description
  *  Reprend les montants de la table ACB_GLOBAL_BUDGET (compte PP) pour la_version de budget choisie
  *  Ainsi que les montants de ACT_TOTAL_BY_PERIOD pour les comptes de type B
  */
  procedure CreateBudgetPeriods(pACB_SCENARIO_ID ACB_SCENARIO.ACB_SCENARIO_ID%type)
  is
    vExistDivi signtype;
  begin
    vExistDIVI  := ACS_FUNCTION.ExistDIVI;

    for tblExercise in (select   BUD.ACB_SCE_EXERCISE_ID
                               , YEA.ACS_FINANCIAL_YEAR_ID
                               , BUD.ACB_BUDGET_VERSION_ID
                               , BUD.PYE_NO_EXERCISE
                               , BSC.BSC_CUM_TYP_INT
                               , BSC.BSC_CUM_TYP_EXT
                               , BSC.BSC_CUM_TYP_PRE
                               , BSC.BSC_CUM_TYP_ENG
                            from ACB_SCE_EXERCISE BEF
                               , ACB_SCE_EXERCISE BUD
                               , ACS_FINANCIAL_YEAR YEA
                               , ACB_SCENARIO BSC
                           where BSC.ACB_SCENARIO_ID = pACB_SCENARIO_ID
                             and BUD.ACB_SCENARIO_ID = BSC.ACB_SCENARIO_ID
                             and BUD.ACB_SCENARIO_ID = BEF.ACB_SCENARIO_ID
                             and BUD.C_COVER_EXERCISE = '2'
                             and BEF.PYE_END_DATE = BUD.PYE_START_DATE - 1
                             and YEA.FYE_NO_EXERCICE = BEF.PYE_NO_EXERCISE
                        order by BUD.PYE_NO_EXERCISE) loop
      if tblExercise.ACB_BUDGET_VERSION_ID is not null then
        --Ajout de toutes les lignes de la version de budget choisie dans ACB_SCE_EXERCISE pour le type de période budgétisée (C_COVER_EXERCISE = 2)
        -- ainsi que les montants fixes
        insert into ACB_SCE_AMOUNT
                    (ACB_SCE_AMOUNT_ID
                   , ACB_SCE_EXERCISE_ID
                   , C_AMOUNT_ORIGIN
                   , SCM_AMOUNT_ALL_LC_D
                   , SCM_AMOUNT_ALL_LC_C
                   , SCM_AMOUNT_LC_D
                   , SCM_AMOUNT_LC_C
                   , SCM_AMOUNT_DIFF_LC_D
                   , SCM_AMOUNT_DIFF_LC_C
                   , ACB_ELEMENT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , SCM_MANUAL
                   , A_DATECRE
                   , A_IDCRE
                    )
          (select INIT_ID_SEQ.nextval
                , tblExercise.ACB_SCE_EXERCISE_ID
                , C_AMOUNT_ORIGIN
                , decode(sign(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), 1, GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C, 0)
                , decode(sign(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), -1, abs(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), 0)
                , decode(sign(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), 1, GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C, 0)
                , decode(sign(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), -1, abs(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), 0)
                , 0
                , 0
                , GLO.ACB_ELEMENT_ID
                , GLO.ACS_FINANCIAL_ACCOUNT_ID
                , GLO.ACS_DIVISION_ACCOUNT_ID
                , 0
                , sysdate
                , PCS.PC_I_LIB_SESSION.GetUserIni
             from (select   nvl(sum(nvl(GLO.GLO_AMOUNT_D, 0) ), 0) GLO_AMOUNT_D
                          , nvl(sum(nvl(GLO.GLO_AMOUNT_C, 0) ), 0) GLO_AMOUNT_C
                          , '9' C_AMOUNT_ORIGIN
                          , GLO.ACS_FINANCIAL_ACCOUNT_ID
                          , GLO.ACS_DIVISION_ACCOUNT_ID
                          , null ACB_ELEMENT_ID
                       from ACB_GLOBAL_BUDGET GLO
                          , ACB_SCE_EXERCISE SEX
                          , ACS_FINANCIAL_ACCOUNT FIN
                      where GLO.ACS_FINANCIAL_ACCOUNT_ID is not null
                        and GLO.ACB_BUDGET_VERSION_ID = SEX.ACB_BUDGET_VERSION_ID
                        and SEX.ACB_SCE_EXERCISE_ID = tblExercise.ACB_SCE_EXERCISE_ID
                        and GLO.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                        and (    (     (vExistDivi > 0)
                                  and GLO.ACS_DIVISION_ACCOUNT_ID is not null)
                             or (     (vExistDivi < 1)
                                 and GLO.ACS_DIVISION_ACCOUNT_ID is null)
                            )
                        and FIN.C_BALANCE_SHEET_PROFIT_LOSS = 'P'
                   group by GLO.ACS_FINANCIAL_ACCOUNT_ID
                          , GLO.ACS_DIVISION_ACCOUNT_ID
                   union all
                   select nvl(EDP.EDP_AMOUNT_LC_D, 0) GLO_AMOUNT_D
                        , nvl(EDP.EDP_AMOUNT_LC_C, 0) GLO_AMOUNT_C
                        , '2' C_AMOUNT_ORIGIN
                        , EPO.ACS_FINANCIAL_ACCOUNT_ID
                        , EPO.ACS_DIVISION_ACCOUNT_ID
                        , BLM.ACB_ELEMENT_ID
                     from ACB_SCE_EXERCISE SCE
                        , ACS_FINANCIAL_ACCOUNT FIN
                        , ACB_ELM_DIST_POSITION EDP
                        , ACB_ELM_POSITION EPO
                        , ACB_ELEMENT BLM
                    where BLM.C_ACB_BUDGETING_ELEMENT = '2'
                      and BLM.ACB_ELEMENT_ID = EPO.ACB_ELEMENT_ID
                      and EPO.ACB_ELM_POSITION_ID = EDP.ACB_ELM_POSITION_ID
                      and SCE.ACB_SCE_EXERCISE_ID = tblExercise.ACB_SCE_EXERCISE_ID
                      and SCE.PYE_NO_EXERCISE = EDP.PYE_NO_EXERCISE
                      and EPO.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                      and FIN.C_BALANCE_SHEET_PROFIT_LOSS = 'B') GLO);
      else
        -- Ajout de toutes les lignes réalisées venant des cumuls (ACT_TOTAL_BY_PERIOD) pour l'exercice (ACB_SCE_EXERCISE.PYE_NO_EXERCISE)
        -- ainsi que les montants fixes
        insert into ACB_SCE_AMOUNT
                    (ACB_SCE_AMOUNT_ID
                   , ACB_SCE_EXERCISE_ID
                   , C_AMOUNT_ORIGIN
                   , SCM_AMOUNT_ALL_LC_D
                   , SCM_AMOUNT_ALL_LC_C
                   , SCM_AMOUNT_LC_D
                   , SCM_AMOUNT_LC_C
                   , SCM_AMOUNT_DIFF_LC_D
                   , SCM_AMOUNT_DIFF_LC_C
                   , ACB_ELEMENT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , SCM_MANUAL
                   , A_DATECRE
                   , A_IDCRE
                    )
          (select INIT_ID_SEQ.nextval
                , tblExercise.ACB_SCE_EXERCISE_ID
                , C_AMOUNT_ORIGIN
                , decode(sign(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), 1, GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C, 0)
                , decode(sign(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), -1, abs(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), 0)
                , decode(sign(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), 1, GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C, 0)
                , decode(sign(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), -1, abs(GLO.GLO_AMOUNT_D - GLO.GLO_AMOUNT_C), 0)
                , 0
                , 0
                , GLO.ACB_ELEMENT_ID
                , GLO.ACS_FINANCIAL_ACCOUNT_ID
                , GLO.ACS_DIVISION_ACCOUNT_ID
                , 0
                , sysdate
                , PCS.PC_I_LIB_SESSION.GetUserIni
             from (select   nvl(sum(nvl(TOT.TOT_DEBIT_LC, 0) ), 0) GLO_AMOUNT_D
                          , nvl(sum(nvl(TOT.TOT_CREDIT_LC, 0) ), 0) GLO_AMOUNT_C
                          , '8' C_AMOUNT_ORIGIN
                          , TOT.ACS_FINANCIAL_ACCOUNT_ID
                          , TOT.ACS_DIVISION_ACCOUNT_ID
                          , null ACB_ELEMENT_ID
                       from ACT_TOTAL_BY_PERIOD TOT
                      where TOT.ACS_FINANCIAL_ACCOUNT_ID is not null
                        and (    (     (tblExercise.BSC_CUM_TYP_INT = 1)
                                  and (TOT.C_TYPE_CUMUL = 'INT') )
                             or (     (tblExercise.BSC_CUM_TYP_EXT = 1)
                                 and (TOT.C_TYPE_CUMUL = 'EXT') )
                             or (     (tblExercise.BSC_CUM_TYP_PRE = 1)
                                 and (TOT.C_TYPE_CUMUL = 'PRE') )
                             or (     (tblExercise.BSC_CUM_TYP_ENG = 1)
                                 and (TOT.C_TYPE_CUMUL = 'ENG') )
                            )
                        and exists(
                              select 1
                                from ACS_PERIOD PER
                               where PER.C_TYPE_PERIOD = '2'
                                 and exists(
                                       select 1
                                         from ACS_FINANCIAL_YEAR FYE
                                        where FYE.FYE_NO_EXERCICE = tblExercise.PYE_NO_EXERCISE
                                          and PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID)
                                 and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID)
                        and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                        and TOT.ACS_FINANCIAL_ACCOUNT_ID is not null
                        and (    (     (vExistDivi > 0)
                                  and TOT.ACS_DIVISION_ACCOUNT_ID is not null)
                             or (     (vExistDivi < 1)
                                 and TOT.ACS_DIVISION_ACCOUNT_ID is null)
                            )
                   group by TOT.ACS_FINANCIAL_ACCOUNT_ID
                          , TOT.ACS_DIVISION_ACCOUNT_ID) GLO);
      end if;
    end loop;
  end CreateBudgetPeriods;

  /**
  * procedure CreateBudgetingElements
  * Description
  *  Création des éléments budgétisés de type 2 ou 3, montants fixes ou investissements
  */
  procedure CreateBudgetingElements(
    pACB_SCE_EXERCISE_ID ACB_SCE_EXERCISE.ACB_SCE_EXERCISE_ID%type
  , pBudgetingElement    ACB_ELEMENT.C_ACB_BUDGETING_ELEMENT%type
  )
  is
  begin
    --Ajout des éléments budgétaires
    --Montants fixes => MAJ des colonnes AMOUNT_ALL + AMOUNT1
    --Investissement => MAJ de la colonne AMOUNT_ALL
    insert into ACB_SCE_AMOUNT
                (ACB_SCE_AMOUNT_ID
               , ACB_SCE_EXERCISE_ID
               , C_AMOUNT_ORIGIN
               , SCM_AMOUNT_ALL_LC_D
               , SCM_AMOUNT_ALL_LC_C
               , SCM_AMOUNT_LC_D
               , SCM_AMOUNT_LC_C
               , SCM_AMOUNT_DIFF_LC_D
               , SCM_AMOUNT_DIFF_LC_C
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACB_ELEMENT_ID
               , SCM_MANUAL
               , A_DATECRE
               , A_IDCRE
                )
      (select INIT_ID_SEQ.nextval
            , pACB_SCE_EXERCISE_ID
            , C_ACB_BUDGETING_ELEMENT
            , decode(sign(EDP_AMOUNT_LC_D - EDP_AMOUNT_LC_C), 1, EDP_AMOUNT_LC_D - EDP_AMOUNT_LC_C, 0)
            , decode(sign(EDP_AMOUNT_LC_D - EDP_AMOUNT_LC_C), -1, abs(EDP_AMOUNT_LC_D - EDP_AMOUNT_LC_C), 0)
            , decode(sign(EDP_AMOUNT1_LC_D - EDP_AMOUNT1_LC_C), 1, EDP_AMOUNT1_LC_D - EDP_AMOUNT1_LC_C, 0)
            , decode(sign(EDP_AMOUNT1_LC_D - EDP_AMOUNT1_LC_C), -1, abs(EDP_AMOUNT1_LC_D - EDP_AMOUNT1_LC_C), 0)
            , decode(C_ACB_BUDGETING_ELEMENT, 2, 0, decode(sign(DIFF_AMOUNT1), 1, DIFF_AMOUNT1, 0) )
            , decode(C_ACB_BUDGETING_ELEMENT, 2, 0, decode(sign(DIFF_AMOUNT1), -1, abs(DIFF_AMOUNT1), 0) )
            , ACS_FINANCIAL_ACCOUNT_ID
            , ACS_DIVISION_ACCOUNT_ID
            , ACB_ELEMENT_ID
            , 0
            , sysdate
            , PCS.PC_I_LIB_SESSION.GetUserIni
         from (select   BLM.C_ACB_BUDGETING_ELEMENT
                      , nvl(EDP.EDP_AMOUNT_LC_D, 0) EDP_AMOUNT_LC_D
                      , nvl(EDP.EDP_AMOUNT_LC_C, 0) EDP_AMOUNT_LC_C
                      , decode(BLM.C_ACB_BUDGETING_ELEMENT, '2', nvl(EDP.EDP_AMOUNT_LC_D, 0), 0) EDP_AMOUNT1_LC_D
                      , decode(BLM.C_ACB_BUDGETING_ELEMENT, '2', nvl(EDP.EDP_AMOUNT_LC_C, 0), 0) EDP_AMOUNT1_LC_C
                      , nvl(EDP.EDP_AMOUNT_LC_D, 0) - nvl(EDP.EDP_AMOUNT_LC_C, 0) DIFF_AMOUNT1
                      , EPO.ACS_FINANCIAL_ACCOUNT_ID
                      , EPO.ACS_DIVISION_ACCOUNT_ID
                      , BLM.ACB_ELEMENT_ID
                   from ACB_ELM_DIST_POSITION EDP
                      , ACB_ELM_POSITION EPO
                      , ACB_ELEMENT BLM
                  where BLM.ACB_ELEMENT_ID = EPO.ACB_ELEMENT_ID
                    and EPO.ACB_ELM_POSITION_ID = EDP.ACB_ELM_POSITION_ID
                    and EDP.PYE_NO_EXERCISE = (select PYE_NO_EXERCISE
                                                 from ACB_SCE_EXERCISE
                                                where ACB_SCE_EXERCISE_ID = pACB_SCE_EXERCISE_ID)
                    and BLM.C_ACB_ELEMENT_STATUS = '1'
                    and BLM.BLM_INIT = 0
                    and instr(pBudgetingElement, ',' || BLM.C_ACB_BUDGETING_ELEMENT || ',') > 0
               order by BLM.C_ACB_BUDGETING_ELEMENT
                      , BLM.BLM_DESCRIPTION) );
  end CreateBudgetingElements;

  /**
  * procedure DeleteSceAmount
  * Description
  *  suppression des montants lors des automatismes d'initialisation
  */
  procedure DeleteSceAmount(
    pACB_SCE_EXERCISE_ID      ACB_SCE_EXERCISE.ACB_SCE_EXERCISE_ID%type
  , pACS_FINANCIAL_ACCOUNT_ID ACB_SCE_AMOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pACS_DIVISION_ACCOUNT_ID  ACB_SCE_AMOUNT.ACS_DIVISION_ACCOUNT_ID%type
  )
  is
  begin
    delete from ACB_SCE_AMOUNT SCE
          where SCE.ACB_SCE_EXERCISE_ID = pACB_SCE_EXERCISE_ID
            and SCE.ACS_FINANCIAL_ACCOUNT_ID = pACS_FINANCIAL_ACCOUNT_ID
            and nvl(SCE.ACS_DIVISION_ACCOUNT_ID, 0) = pACS_DIVISION_ACCOUNT_ID;
  end;

  /**
  * procedure CreateBudgetingInitElements
  * Description
  *  Création des éléments budgétisés d'INITIALISATION de type 2 ou 3, montants fixes ou investissements
  */
  procedure CreateBudgetingInitElements(
    pACB_SCE_EXERCISE_ID ACB_SCE_EXERCISE.ACB_SCE_EXERCISE_ID%type
  , pBudgetingElement    ACB_ELEMENT.C_ACB_BUDGETING_ELEMENT%type
  )
  is
  begin
    --Ajout des éléments budgétaires d'initialisation
    --2 Montants fixes => MAJ des colonnes AMOUNT_ALL + AMOUNT1
    --3 Investissement => MAJ de la colonne AMOUNT_ALL
    for tblInitBudElements in (select   pACB_SCE_EXERCISE_ID ACB_SCE_EXERCISE_ID
                                      , BLM.C_ACB_BUDGETING_ELEMENT C_AMOUNT_ORIGIN
                                      , nvl(EDP.EDP_AMOUNT_LC_D, 0) - nvl(EDP.EDP_AMOUNT_LC_C, 0) SCM_AMOUNT_ALL
                                      , decode(BLM.C_ACB_BUDGETING_ELEMENT
                                             , '2', nvl(EDP.EDP_AMOUNT_LC_D, 0) - nvl(EDP.EDP_AMOUNT_LC_C, 0)
                                             , 0
                                              ) SCM_AMOUNT1
                                      , EPO.ACS_FINANCIAL_ACCOUNT_ID
                                      , nvl(EPO.ACS_DIVISION_ACCOUNT_ID, 0) ACS_DIVISION_ACCOUNT_ID
                                      , BLM.ACB_ELEMENT_ID
                                   from ACB_ELM_DIST_POSITION EDP
                                      , ACB_ELM_POSITION EPO
                                      , ACB_ELEMENT BLM
                                  where BLM.ACB_ELEMENT_ID = EPO.ACB_ELEMENT_ID
                                    and EPO.ACB_ELM_POSITION_ID = EDP.ACB_ELM_POSITION_ID
                                    and EDP.PYE_NO_EXERCISE = (select PYE_NO_EXERCISE
                                                                 from ACB_SCE_EXERCISE
                                                                where ACB_SCE_EXERCISE_ID = pACB_SCE_EXERCISE_ID)
                                    and BLM.C_ACB_ELEMENT_STATUS = '1'
                                    and BLM.BLM_INIT = 1
                                    and instr(pBudgetingElement, ',' || BLM.C_ACB_BUDGETING_ELEMENT || ',') > 0
                               order by BLM.C_ACB_BUDGETING_ELEMENT
                                      , BLM.BLM_DESCRIPTION) loop
      DeleteSceAmount(pACB_SCE_EXERCISE_ID        => tblInitBudElements.ACB_SCE_EXERCISE_ID
                    , pACS_FINANCIAL_ACCOUNT_ID   => tblInitBudElements.ACS_FINANCIAL_ACCOUNT_ID
                    , pACS_DIVISION_ACCOUNT_ID    => tblInitBudElements.ACS_DIVISION_ACCOUNT_ID
                     );

      insert into ACB_SCE_AMOUNT
                  (ACB_SCE_AMOUNT_ID
                 , ACB_SCE_EXERCISE_ID
                 , C_AMOUNT_ORIGIN
                 , SCM_AMOUNT_ALL_LC_D
                 , SCM_AMOUNT_ALL_LC_C
                 , SCM_AMOUNT_LC_D
                 , SCM_AMOUNT_LC_C
                 , SCM_AMOUNT_DIFF_LC_D
                 , SCM_AMOUNT_DIFF_LC_C
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACB_ELEMENT_ID
                 , SCM_MANUAL
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (INIT_ID_SEQ.nextval
                 , tblInitBudElements.ACB_SCE_EXERCISE_ID
                 , tblInitBudElements.C_AMOUNT_ORIGIN
                 , decode(sign(tblInitBudElements.SCM_AMOUNT_ALL), 1, tblInitBudElements.SCM_AMOUNT_ALL, 0)
                 , decode(sign(tblInitBudElements.SCM_AMOUNT_ALL), -1, abs(tblInitBudElements.SCM_AMOUNT_ALL), 0)
                 , decode(sign(tblInitBudElements.SCM_AMOUNT1), 1, tblInitBudElements.SCM_AMOUNT1, 0)
                 , decode(sign(tblInitBudElements.SCM_AMOUNT1), -1, abs(tblInitBudElements.SCM_AMOUNT1), 0)
                 , 0
                 , 0
                 , tblInitBudElements.ACS_FINANCIAL_ACCOUNT_ID
                 , decode(tblInitBudElements.ACS_DIVISION_ACCOUNT_ID
                        , 0, null
                        , tblInitBudElements.ACS_DIVISION_ACCOUNT_ID
                         )
                 , tblInitBudElements.ACB_ELEMENT_ID
                 , 0
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end CreateBudgetingInitElements;

  /**
  * procedure CreateAutomatismElements
  * Description
  *  Création des éléments d'automatisme
  */
  procedure CreateAutomatismElements(pACB_SCENARIO_ID ACB_SCENARIO.ACB_SCENARIO_ID%type)
  is
    vC_COVER_EXERCISE ACB_SCE_EXERCISE.C_COVER_EXERCISE%type;
  begin
    /*
      Traiter chaque période couverte en 1 fois
      a) d'abord tous les comptes sans cible
        -- appliquer tous les automatismes pour les paires concernées
        -- créer une ligne dans les montants ACB_SCE_AMOUNT
      b) puis les comptes avec cibles
        --
        --
    */
    vC_COVER_EXERCISE  := '3';

    --Pour chaque période planifiée, exécuter les opérations d'automatisme dans l'ordre des exercices et des séquences
    for tblExercise in (select   SEX.ACB_SCE_EXERCISE_ID
                            from ACB_SCE_EXERCISE SEX
                           where SEX.ACB_SCENARIO_ID = pACB_SCENARIO_ID
                             and SEX.C_COVER_EXERCISE = vC_COVER_EXERCISE
                        order by SEX.PYE_NO_EXERCISE) loop
      --Création des éléments d'initialisation de type 1, 4, pourcentage, paramètres (ACB_ELEMENT)
      CreateParameterElements(pACB_SCE_EXERCISE_ID   => tblExercise.ACB_SCE_EXERCISE_ID
                            , pBLM_INIT              => 1
                            , pBudgetingElement      => ',1,4,'
                             );
      --Création des éléments de type 1, pourcentage
      CreateParameterElements(pACB_SCE_EXERCISE_ID   => tblExercise.ACB_SCE_EXERCISE_ID
                            , pBLM_INIT              => 0
                            , pBudgetingElement      => ',1,'
                             );
      --Création des éléments budgétisés d'initialisation de type 2,3, montant fixe, investissement (ACB_ELEMENT)
      CreateBudgetingInitElements(pACB_SCE_EXERCISE_ID   => tblExercise.ACB_SCE_EXERCISE_ID
                                , pBudgetingElement      => ',2,3,');
      --Création des éléments budgétisés de type 2,3, montant fixe, investissement (ACB_ELEMENT)
      CreateBudgetingElements(pACB_SCE_EXERCISE_ID => tblExercise.ACB_SCE_EXERCISE_ID, pBudgetingElement => ',2,3,');
      --Création des éléments de type 4, paramètres
      CreateParameterElements(pACB_SCE_EXERCISE_ID   => tblExercise.ACB_SCE_EXERCISE_ID
                            , pBLM_INIT              => 0
                            , pBudgetingElement      => ',4,'
                             );
    end loop;
  end CreateAutomatismElements;

  /**
  * procedure CreateParameterElements
  * Description
  *  Création des éléments non initialisation de type 1 ou 4, pourcentages ou paramètres
  */
  procedure CreateParameterElements(
    pACB_SCE_EXERCISE_ID ACB_SCE_EXERCISE.ACB_SCE_EXERCISE_ID%type
  , pBLM_INIT            ACB_ELEMENT.BLM_INIT%type
  , pBudgetingElement    ACB_ELEMENT.C_ACB_BUDGETING_ELEMENT%type
  )
  is
    vValue ACB_PLANING_VALUES.PLV_value%type;
  begin
    for tblAllElements in (select   ERE.ACB_ELEMENT_REFERENCE_ID
                                  , nvl(ERE.ERE_VALUE, 0) ERE_VALUE
                                  , nvl(ERE.ACS_FINANCIAL_ACC_TARGET_ID, 0) ACS_FINANCIAL_ACC_TARGET_ID
                                  , nvl(ERE.ACS_DIVISION_ACC_TARGET_ID, 0) ACS_DIVISION_ACC_TARGET_ID
                               from ACB_ELEMENT_REFERENCE ERE
                                  , ACB_ELEMENT BLM
                              where BLM.ACB_ELEMENT_ID = ERE.ACB_ELEMENT_ID
                                and BLM.C_ACB_ELEMENT_STATUS = '1'
                                and BLM.BLM_INIT = pBLM_INIT
                                and instr(pBudgetingElement, ',' || BLM.C_ACB_BUDGETING_ELEMENT || ',') > 0
                           order by ERE_SEQUENCE asc) loop
      if GetPlaningValue(tblAllElements.ACB_ELEMENT_REFERENCE_ID, pACB_SCE_EXERCISE_ID, vValue) then
        if (    (tblAllElements.ACS_FINANCIAL_ACC_TARGET_ID > 0)
            or (tblAllElements.ACS_DIVISION_ACC_TARGET_ID > 0) ) then
          CalculateElementsReference(pACB_ELEMENT_REFERENCE_ID      => tblAllElements.ACB_ELEMENT_REFERENCE_ID
                                   , pPLV_VALUE                     => vValue
                                   , pACB_SCE_EXERCISE_ID           => pACB_SCE_EXERCISE_ID
                                   , pGroupAllAmounts               => true
                                   , pACS_FINANCIAL_ACC_TARGET_ID   => tblAllElements.ACS_FINANCIAL_ACC_TARGET_ID
                                   , pACS_DIVISION_ACC_TARGET_ID    => tblAllElements.ACS_DIVISION_ACC_TARGET_ID
                                    );
        else
          CalculateElementsReference(pACB_ELEMENT_REFERENCE_ID      => tblAllElements.ACB_ELEMENT_REFERENCE_ID
                                   , pPLV_VALUE                     => vValue
                                   , pACB_SCE_EXERCISE_ID           => pACB_SCE_EXERCISE_ID
                                   , pGroupAllAmounts               => false
                                   , pACS_FINANCIAL_ACC_TARGET_ID   => 0
                                   , pACS_DIVISION_ACC_TARGET_ID    => 0
                                    );
        end if;
      else
        --Pas de valeurs d'éléments prendre la valeur par défaut de l'élément de référence
        if (    (tblAllElements.ACS_FINANCIAL_ACC_TARGET_ID > 0)
            or (tblAllElements.ACS_DIVISION_ACC_TARGET_ID > 0) ) then
          CalculateElementsReference(pACB_ELEMENT_REFERENCE_ID      => tblAllElements.ACB_ELEMENT_REFERENCE_ID
                                   , pPLV_VALUE                     => tblAllElements.ERE_VALUE
                                   , pACB_SCE_EXERCISE_ID           => pACB_SCE_EXERCISE_ID
                                   , pGroupAllAmounts               => true
                                   , pACS_FINANCIAL_ACC_TARGET_ID   => tblAllElements.ACS_FINANCIAL_ACC_TARGET_ID
                                   , pACS_DIVISION_ACC_TARGET_ID    => tblAllElements.ACS_DIVISION_ACC_TARGET_ID
                                    );
        else
          CalculateElementsReference(pACB_ELEMENT_REFERENCE_ID      => tblAllElements.ACB_ELEMENT_REFERENCE_ID
                                   , pPLV_VALUE                     => tblAllElements.ERE_VALUE
                                   , pACB_SCE_EXERCISE_ID           => pACB_SCE_EXERCISE_ID
                                   , pGroupAllAmounts               => false
                                   , pACS_FINANCIAL_ACC_TARGET_ID   => 0
                                   , pACS_DIVISION_ACC_TARGET_ID    => 0
                                    );
        end if;
      end if;
    end loop;
  end;

  /**
  * function CalculateElementsReference
  * Description
  *  Calcul le nouveau montant selon tous les éléments de référence
  */
  procedure CalculateElementsReference(
    pACB_ELEMENT_REFERENCE_ID    ACB_ELEMENT_REFERENCE.ACB_ELEMENT_REFERENCE_ID%type
  , pPLV_VALUE                   ACB_PLANING_VALUES.PLV_value%type
  , pACB_SCE_EXERCISE_ID         ACB_SCE_EXERCISE.ACB_SCE_EXERCISE_ID%type
  , pGroupAllAmounts             boolean
  , pACS_FINANCIAL_ACC_TARGET_ID ACB_ELEMENT_REFERENCE.ACS_FINANCIAL_ACC_TARGET_ID%type
  , pACS_DIVISION_ACC_TARGET_ID  ACB_ELEMENT_REFERENCE.ACS_DIVISION_ACC_TARGET_ID%type
  )
  is
    type MinMaxNumberRec is record(
      vMinAccNumber ACS_ACCOUNT.ACC_NUMBER%type
    , vMaxAccNumber ACS_ACCOUNT.ACC_NUMBER%type
    , vMinDivNumber ACS_ACCOUNT.ACC_NUMBER%type
    , vMaxDivNumber ACS_ACCOUNT.ACC_NUMBER%type
    );

    vMinMaxElement           MinMaxNumberRec;
    vAmountAll               ACB_SCE_AMOUNT.SCM_AMOUNT_ALL_LC_D%type           default 0;
    vAmount1                 ACB_SCE_AMOUNT.SCM_AMOUNT_LC_D%type               default 0;
    vBLM_INIT                ACB_ELEMENT.BLM_INIT%type;
    vACB_ELEMENT_ID          ACB_ELEMENT.ACB_ELEMENT_ID%type                   default 0;
    vC_ACB_BUDGETING_ELEMENT ACB_ELEMENT.C_ACB_BUDGETING_ELEMENT%type;
    vC_ACB_CONDITION_TYPE    ACB_ELEMENT_REFERENCE.C_ACB_CONDITION_TYPE%type;
    vPrevExercise            signtype;
  begin
    --pGroupAllAmounts = False
    --1)Pour les automatismes sans cibles, par couple compte-division concerné par l'automatisme, calculer un montant regroupant toutes les lignes du couple.
    --2)Appliquer la valeur de l'automatisme sur le montant regroupé
    --3)Ajouter une ligne par couple

    --pGroupAllAmounts = True
    --1)Pour les automatismes avec cibles, calculer un montant regroupant tous les montants des comptes concernés par l'automatisme.
    --2)Appliquer la valeur de l'automatisme sur le montant regroupé
    --3)Ajouter une ligne pour la paire cible
      --Pour chaque automatisme trouvé, appliquer le traitement sur le montant de référence
    for tblElement in (select   ERE.C_ACB_ELEMENT_TYPE
                              , ERE.C_ACB_EXERCISE_AMOUNT
                              , ERE.C_ACB_CONDITION_TYPE
                              , ERE.ACB_ELEMENT_ID
                              , BLM.C_ACB_BUDGETING_ELEMENT
                              , BLM.BLM_INIT
                              , nvl(ERE.CLASSIFICATION_ID, 0) CLASSIFICATION_ID
                              , nvl(ERE.ACS_FINANCIAL_ACCOUNT_FROM_ID, 0) ACS_FINANCIAL_ACCOUNT_FROM_ID
                              , nvl(ERE.ACS_DIVISION_ACCOUNT_FROM_ID, 0) ACS_DIVISION_ACCOUNT_FROM_ID
                              , nvl(ERE.ACS_FINANCIAL_ACCOUNT_TO_ID, 0) ACS_FINANCIAL_ACCOUNT_TO_ID
                              , nvl(ERE.ACS_DIVISION_ACCOUNT_TO_ID, 0) ACS_DIVISION_ACCOUNT_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_1_FROM_ID, ' ') DIC_FIN_ACC_CODE_1_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_1_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_1_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_2_FROM_ID, ' ') DIC_FIN_ACC_CODE_2_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_2_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_2_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_3_FROM_ID, ' ') DIC_FIN_ACC_CODE_3_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_3_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_3_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_4_FROM_ID, ' ') DIC_FIN_ACC_CODE_4_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_4_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_4_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_5_FROM_ID, ' ') DIC_FIN_ACC_CODE_5_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_5_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_5_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_6_FROM_ID, ' ') DIC_FIN_ACC_CODE_6_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_6_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_6_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_7_FROM_ID, ' ') DIC_FIN_ACC_CODE_7_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_7_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_7_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_8_FROM_ID, ' ') DIC_FIN_ACC_CODE_8_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_8_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_8_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_9_FROM_ID, ' ') DIC_FIN_ACC_CODE_9_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_9_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_9_TO_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_10_FROM_ID, ' ') DIC_FIN_ACC_CODE_10_FROM_ID
                              , nvl(ERE.DIC_FIN_ACC_CODE_10_TO_ID, chr(255) ) DIC_FIN_ACC_CODE_10_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_1_FROM_ID, ' ') DIC_DIV_ACC_CODE_1_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_1_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_1_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_2_FROM_ID, ' ') DIC_DIV_ACC_CODE_2_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_2_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_2_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_3_FROM_ID, ' ') DIC_DIV_ACC_CODE_3_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_3_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_3_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_4_FROM_ID, ' ') DIC_DIV_ACC_CODE_4_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_4_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_4_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_5_FROM_ID, ' ') DIC_DIV_ACC_CODE_5_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_5_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_5_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_6_FROM_ID, ' ') DIC_DIV_ACC_CODE_6_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_6_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_6_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_7_FROM_ID, ' ') DIC_DIV_ACC_CODE_7_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_7_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_7_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_8_FROM_ID, ' ') DIC_DIV_ACC_CODE_8_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_8_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_8_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_9_FROM_ID, ' ') DIC_DIV_ACC_CODE_9_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_9_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_9_TO_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_10_FROM_ID, ' ') DIC_DIV_ACC_CODE_10_FROM_ID
                              , nvl(ERE.DIC_DIV_ACC_CODE_10_TO_ID, chr(255) ) DIC_DIV_ACC_CODE_10_TO_ID
                              , ERE.ACB_ELEMENT_REFERENCE_ID
                           from ACB_ELEMENT_REFERENCE ERE
                              , ACB_ELEMENT BLM
                          where ERE.ACB_ELEMENT_REFERENCE_ID = pACB_ELEMENT_REFERENCE_ID
                            and ERE.ACB_ELEMENT_ID = BLM.ACB_ELEMENT_ID
                       order by BLM.C_ACB_BUDGETING_ELEMENT) loop   -- 1 ou 4
      if (tblElement.C_ACB_EXERCISE_AMOUNT = '1') then
        vPrevExercise  := 1;
      else
        vPrevExercise  := 0;
      end if;

      if     pGroupAllAmounts
         and (vACB_ELEMENT_ID = 0) then
        vACB_ELEMENT_ID           := tblElement.ACB_ELEMENT_ID;
        vC_ACB_BUDGETING_ELEMENT  := tblElement.C_ACB_BUDGETING_ELEMENT;
        vC_ACB_CONDITION_TYPE     := tblElement.C_ACB_CONDITION_TYPE;
        vBLM_INIT                 := tblElement.BLM_INIT;
      end if;

      --Appliquer le traitement selon C_ACB_EXERCISE_AMOUNT + C_ACB_ELEMENT_REFERENCE sur les montants de référence
      if tblElement.C_ACB_ELEMENT_TYPE = '1' then   --De .. à
        --Recherche des numéros de l'élément de référence en lieu et place des IDs
        --MinACC
        select nvl(min(ACC.ACC_NUMBER), ' ')
          into vMinMaxElement.vMinAccNumber
          from ACS_ACCOUNT ACC
             , ACS_FINANCIAL_ACCOUNT FIN
         where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.ACS_FINANCIAL_ACCOUNT_ID =
                 decode(TblElement.ACS_FINANCIAL_ACCOUNT_FROM_ID
                      , 0, FIN.ACS_FINANCIAL_ACCOUNT_ID
                      , TblElement.ACS_FINANCIAL_ACCOUNT_FROM_ID
                       );

        --MaxACC
        select nvl(max(ACC.ACC_NUMBER), chr(255) )
          into vMinMaxElement.vMaxAccNumber
          from ACS_ACCOUNT ACC
             , ACS_FINANCIAL_ACCOUNT FIN
         where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.ACS_FINANCIAL_ACCOUNT_ID =
                 decode(TblElement.ACS_FINANCIAL_ACCOUNT_TO_ID
                      , 0, FIN.ACS_FINANCIAL_ACCOUNT_ID
                      , TblElement.ACS_FINANCIAL_ACCOUNT_TO_ID
                       );

        --MinDIV
        select nvl(min(ACC.ACC_NUMBER), ' ')
          into vMinMaxElement.vMinDivNumber
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where ACC.ACS_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
           and DIV.ACS_DIVISION_ACCOUNT_ID =
                 decode(TblElement.ACS_DIVISION_ACCOUNT_FROM_ID
                      , 0, DIV.ACS_DIVISION_ACCOUNT_ID
                      , TblElement.ACS_DIVISION_ACCOUNT_FROM_ID
                       );

        --MaxDIV
        select nvl(max(ACC.ACC_NUMBER), chr(255) )
          into vMinMaxElement.vMaxDivNumber
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where ACC.ACS_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
           and DIV.ACS_DIVISION_ACCOUNT_ID =
                 decode(TblElement.ACS_DIVISION_ACCOUNT_TO_ID
                      , 0, DIV.ACS_DIVISION_ACCOUNT_ID
                      , TblElement.ACS_DIVISION_ACCOUNT_TO_ID
                       );

        --Regroupe les montants selon les comptes défini dans l'élément d'automatisme
        --pour l'exercice en cours de traitement (C_ACB_EXERCISE_AMOUNT = '2') ou l'exercice précédent celui en cours de traitement (C_ACB_EXERCISE_AMOUNT = '1')
        for tblAmount in (select   nvl(sum(SCM.SCM_AMOUNT_ALL_LC_D), 0) - nvl(sum(SCM.SCM_AMOUNT_ALL_LC_C), 0)
                                                                                                             AMOUNT_ALL
                                 , nvl(sum(SCM.SCM_AMOUNT_LC_D), 0) - nvl(sum(SCM.SCM_AMOUNT_LC_C), 0) AMOUNT1
                                 , SCM.ACS_FINANCIAL_ACCOUNT_ID
                                 , nvl(SCM.ACS_DIVISION_ACCOUNT_ID, 0) ACS_DIVISION_ACCOUNT_ID
                              from ACB_SCE_AMOUNT SCM
                                 , ACS_FINANCIAL_ACCOUNT FIN
                                 , ACS_ACCOUNT FACC
                                 , ACS_DIVISION_ACCOUNT DIV
                                 , ACS_ACCOUNT DACC
                             where SCM.ACB_SCE_EXERCISE_ID =
                                     decode(vPrevExercise
                                          , 0, pACB_SCE_EXERCISE_ID
                                          , (select max(ACB_SCE_EXERCISE_ID)
                                               from ACB_SCE_EXERCISE
                                              where PYE_END_DATE + 1 =
                                                                      (select PYE_START_DATE
                                                                         from ACB_SCE_EXERCISE
                                                                        where ACB_SCE_EXERCISE_ID = pACB_SCE_EXERCISE_ID) )
                                           )
                               and SCM.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                               and FIN.ACS_FINANCIAL_ACCOUNT_ID = FACC.ACS_ACCOUNT_ID
                               and SCM.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID(+)
                               and DIV.ACS_DIVISION_ACCOUNT_ID = DACC.ACS_ACCOUNT_ID(+)
                               and FACC.ACC_NUMBER >= vMinMaxElement.vMinAccNumber
                               and FACC.ACC_NUMBER <= vMinMaxElement.vMaxAccNumber
                               and nvl(DACC.ACC_NUMBER, ' ') >= vMinMaxElement.vMinDivNumber
                               and nvl(DACC.ACC_NUMBER, ' ') <= vMinMaxElement.vMaxDivNumber
                               and nvl(FIN.DIC_FIN_ACC_CODE_1_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_1_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_1_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_1_TO_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_2_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_2_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_2_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_2_TO_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_3_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_3_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_3_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_3_TO_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_4_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_4_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_4_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_4_TO_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_5_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_5_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_5_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_5_TO_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_6_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_6_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_6_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_6_TO_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_7_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_7_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_7_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_7_TO_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_8_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_8_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_8_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_8_TO_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_9_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_9_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_9_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_9_TO_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_10_ID, ' ') >= tblElement.DIC_FIN_ACC_CODE_10_FROM_ID
                               and nvl(FIN.DIC_FIN_ACC_CODE_10_ID, ' ') <= tblElement.DIC_FIN_ACC_CODE_10_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_1_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_1_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_1_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_1_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_2_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_2_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_2_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_2_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_3_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_3_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_3_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_3_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_4_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_4_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_4_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_4_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_5_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_5_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_5_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_5_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_6_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_6_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_6_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_6_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_7_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_7_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_7_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_7_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_8_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_8_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_8_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_8_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_9_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_9_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_9_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_9_TO_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_10_ID, ' ') >= tblElement.DIC_DIV_ACC_CODE_10_FROM_ID
                               and nvl(DIV.DIC_DIV_ACC_CODE_10_ID, ' ') <= tblElement.DIC_DIV_ACC_CODE_10_TO_ID
                          group by SCM.ACS_FINANCIAL_ACCOUNT_ID
                                 , SCM.ACS_DIVISION_ACCOUNT_ID) loop
          --Ajoute le montant si pGroupAmounts = False sinon cumul des montants Débit et crédit dans vAmountD, vAmountC
          if pGroupAllAmounts then
            GroupSceAmounts(pAmountAll        => tblAmount.AMOUNT_ALL
                          , pAmount1          => tblAmount.AMOUNT1
                          , pCumulAmountAll   => vAmountAll
                          , pCumulAmount1     => vAmount1
                           );
          else
            if tblElement.BLM_INIT = 1 then
              DeleteSceAmount(pACB_SCE_EXERCISE_ID        => pACB_SCE_EXERCISE_ID
                            , pACS_FINANCIAL_ACCOUNT_ID   => tblAmount.ACS_FINANCIAL_ACCOUNT_ID
                            , pACS_DIVISION_ACCOUNT_ID    => tblAmount.ACS_DIVISION_ACCOUNT_ID
                             );
            end if;

            ManageSceAmounts(pAmountAll                  => tblAmount.AMOUNT_ALL
                           , pAmount1                    => tblAmount.AMOUNT1
                           , pC_ACB_BUDGETING_ELEMENT    => tblElement.C_ACB_BUDGETING_ELEMENT
                           , pC_ACB_CONDITION_TYPE       => tblElement.C_ACB_CONDITION_TYPE
                           , pPLV_VALUE                  => pPLV_VALUE
                           , pACB_SCE_EXERCISE_ID        => pACB_SCE_EXERCISE_ID
                           , pACS_FINANCIAL_ACCOUNT_ID   => tblAmount.ACS_FINANCIAL_ACCOUNT_ID
                           , pACS_DIVISION_ACCOUNT_ID    => tblAmount.ACS_DIVISION_ACCOUNT_ID
                           , pACB_ELEMENT_ID             => tblElement.ACB_ELEMENT_ID
                            );
          end if;
        end loop;
      elsif tblElement.C_ACB_ELEMENT_TYPE = '2' then   -- Sélection
        for tblAmount in (select   nvl(sum(SCM.SCM_AMOUNT_ALL_LC_D), 0) - nvl(sum(SCM.SCM_AMOUNT_ALL_LC_C), 0)
                                                                                                             AMOUNT_ALL
                                 , nvl(sum(SCM.SCM_AMOUNT_LC_D), 0) - nvl(sum(SCM.SCM_AMOUNT_LC_C), 0) AMOUNT1
                                 , SCM.ACS_FINANCIAL_ACCOUNT_ID
                                 , nvl(SCM.ACS_DIVISION_ACCOUNT_ID, 0) ACS_DIVISION_ACCOUNT_ID
                              from ACB_SCE_AMOUNT SCM
                             where SCM.ACB_SCE_EXERCISE_ID =
                                     decode(vPrevExercise
                                          , 0, pACB_SCE_EXERCISE_ID
                                          , (select max(ACB_SCE_EXERCISE_ID)
                                               from ACB_SCE_EXERCISE
                                              where PYE_END_DATE + 1 =
                                                                      (select PYE_START_DATE
                                                                         from ACB_SCE_EXERCISE
                                                                        where ACB_SCE_EXERCISE_ID = pACB_SCE_EXERCISE_ID) )
                                           )
                               and exists(
                                     select 1
                                       from ACB_DETAIL_REFERENCE ACC
                                      where ACC.ACB_ELEMENT_REFERENCE_ID = tblElement.ACB_ELEMENT_REFERENCE_ID
                                        and ACC.ACS_ACCOUNT_ID = SCM.ACS_FINANCIAL_ACCOUNT_ID
                                        and ACC.C_SUB_SET = 'ACC')
                               and exists(
                                     select 1
                                       from ACB_DETAIL_REFERENCE DIV
                                      where DIV.ACB_ELEMENT_REFERENCE_ID = tblElement.ACB_ELEMENT_REFERENCE_ID
                                        and DIV.ACS_ACCOUNT_ID = SCM.ACS_DIVISION_ACCOUNT_ID
                                        and DIV.C_SUB_SET in('DTO', 'DOP', 'DPA') )
                          group by SCM.ACS_FINANCIAL_ACCOUNT_ID
                                 , SCM.ACS_DIVISION_ACCOUNT_ID) loop
          --Ajoute le montant si pGroupAmounts = False sinon cumul des montants Débit et crédit dnas vAmountD, vAmountC
          if pGroupAllAmounts then
            GroupSceAmounts(pAmountAll        => tblAmount.AMOUNT_ALL
                          , pAmount1          => tblAmount.AMOUNT1
                          , pCumulAmountAll   => vAmountAll
                          , pCumulAmount1     => vAmount1
                           );
          else
            if tblElement.BLM_INIT = 1 then
              DeleteSceAmount(pACB_SCE_EXERCISE_ID        => pACB_SCE_EXERCISE_ID
                            , pACS_FINANCIAL_ACCOUNT_ID   => tblAmount.ACS_FINANCIAL_ACCOUNT_ID
                            , pACS_DIVISION_ACCOUNT_ID    => tblAmount.ACS_DIVISION_ACCOUNT_ID
                             );
            end if;

            ManageSceAmounts(pAmountAll                  => tblAmount.AMOUNT_ALL
                           , pAmount1                    => tblAmount.AMOUNT1
                           , pC_ACB_BUDGETING_ELEMENT    => tblElement.C_ACB_BUDGETING_ELEMENT
                           , pC_ACB_CONDITION_TYPE       => tblElement.C_ACB_CONDITION_TYPE
                           , pPLV_VALUE                  => pPLV_VALUE
                           , pACB_SCE_EXERCISE_ID        => pACB_SCE_EXERCISE_ID
                           , pACS_FINANCIAL_ACCOUNT_ID   => tblAmount.ACS_FINANCIAL_ACCOUNT_ID
                           , pACS_DIVISION_ACCOUNT_ID    => tblAmount.ACS_DIVISION_ACCOUNT_ID
                           , pACB_ELEMENT_ID             => tblElement.ACB_ELEMENT_ID
                            );
          end if;
        end loop;
      elsif tblElement.C_ACB_ELEMENT_TYPE = '3' then   --Classification
        --Produits croisés de la classif entre les comptes financiers, les divisions
        for tblAmount in (select   nvl(sum(SCM.SCM_AMOUNT_ALL_LC_D), 0) - nvl(sum(SCM.SCM_AMOUNT_ALL_LC_C), 0)
                                                                                                             AMOUNT_ALL
                                 , nvl(sum(SCM.SCM_AMOUNT_LC_D), 0) - nvl(sum(SCM.SCM_AMOUNT_LC_C), 0) AMOUNT1
                                 , SCM.ACS_FINANCIAL_ACCOUNT_ID
                                 , nvl(SCM.ACS_DIVISION_ACCOUNT_ID, 0) ACS_DIVISION_ACCOUNT_ID
                              from ACB_SCE_AMOUNT SCM
                             where SCM.ACB_SCE_EXERCISE_ID =
                                     decode(vPrevExercise
                                          , 0, pACB_SCE_EXERCISE_ID
                                          , (select max(ACB_SCE_EXERCISE_ID)
                                               from ACB_SCE_EXERCISE
                                              where PYE_END_DATE + 1 =
                                                                      (select PYE_START_DATE
                                                                         from ACB_SCE_EXERCISE
                                                                        where ACB_SCE_EXERCISE_ID = pACB_SCE_EXERCISE_ID) )
                                           )
                               and exists(
                                     select 1
                                       from CLASSIF_FLAT FLA
                                      where FLA.CLASSIFICATION_ID = tblElement.CLASSIFICATION_ID
                                        and FLA.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
                                        and (    (FLA.CLASSIF_LEAF_ID = SCM.ACS_FINANCIAL_ACCOUNT_ID)
                                             or (FLA.CLASSIF_LEAF_ID = SCM.ACS_DIVISION_ACCOUNT_ID)
                                            ) )
                          group by SCM.ACS_FINANCIAL_ACCOUNT_ID
                                 , SCM.ACS_DIVISION_ACCOUNT_ID) loop
          --Ajoute le montant si pGroupAmounts = False sinon cumul des montants Débit et crédit dans vAmountD, vAmountC
          if pGroupAllAmounts then
            GroupSceAmounts(pAmountAll        => tblAmount.AMOUNT_ALL
                          , pAmount1          => tblAmount.AMOUNT1
                          , pCumulAmountAll   => vAmountAll
                          , pCumulAmount1     => vAmount1
                           );
          else
            if tblElement.BLM_INIT = 1 then
              DeleteSceAmount(pACB_SCE_EXERCISE_ID        => pACB_SCE_EXERCISE_ID
                            , pACS_FINANCIAL_ACCOUNT_ID   => tblAmount.ACS_FINANCIAL_ACCOUNT_ID
                            , pACS_DIVISION_ACCOUNT_ID    => tblAmount.ACS_DIVISION_ACCOUNT_ID
                             );
            end if;

            ManageSceAmounts(pAmountAll                  => tblAmount.AMOUNT_ALL
                           , pAmount1                    => tblAmount.AMOUNT1
                           , pC_ACB_BUDGETING_ELEMENT    => tblElement.C_ACB_BUDGETING_ELEMENT
                           , pC_ACB_CONDITION_TYPE       => tblElement.C_ACB_CONDITION_TYPE
                           , pPLV_VALUE                  => pPLV_VALUE
                           , pACB_SCE_EXERCISE_ID        => pACB_SCE_EXERCISE_ID
                           , pACS_FINANCIAL_ACCOUNT_ID   => tblAmount.ACS_FINANCIAL_ACCOUNT_ID
                           , pACS_DIVISION_ACCOUNT_ID    => tblAmount.ACS_DIVISION_ACCOUNT_ID
                           , pACB_ELEMENT_ID             => tblElement.ACB_ELEMENT_ID
                            );
          end if;
        end loop;
      end if;
    end loop;

    --Automatisme avec cible => les montants sont regroupés et ajoutés en une seule ligne
    if pGroupAllAmounts then
--      if pPLV_VALUE <> 0 then
      if vBLM_INIT = 1 then
        DeleteSceAmount(pACB_SCE_EXERCISE_ID        => pACB_SCE_EXERCISE_ID
                      , pACS_FINANCIAL_ACCOUNT_ID   => pACS_FINANCIAL_ACC_TARGET_ID
                      , pACS_DIVISION_ACCOUNT_ID    => pACS_DIVISION_ACC_TARGET_ID
                       );
      end if;

      ManageSceAmounts(pAmountAll                  => vAmountAll
                     , pAmount1                    => vAmount1
                     , pC_ACB_BUDGETING_ELEMENT    => vC_ACB_BUDGETING_ELEMENT
                     , pC_ACB_CONDITION_TYPE       => vC_ACB_CONDITION_TYPE
                     , pPLV_VALUE                  => pPLV_VALUE
                     , pACB_SCE_EXERCISE_ID        => pACB_SCE_EXERCISE_ID
                     , pACS_FINANCIAL_ACCOUNT_ID   => pACS_FINANCIAL_ACC_TARGET_ID
                     , pACS_DIVISION_ACCOUNT_ID    => pACS_DIVISION_ACC_TARGET_ID
                     , pACB_ELEMENT_ID             => vACB_ELEMENT_ID
                      );
    end if;
  end CalculateElementsReference;

  /**
  * procedure GroupSceAmounts
  * Description
  *  Ajoute les montants dans pAmount* dans pCumulAmount*
  */
  procedure GroupSceAmounts(
    pAmountAll             ACB_SCE_AMOUNT.SCM_AMOUNT_ALL_LC_D%type
  , pAmount1               ACB_SCE_AMOUNT.SCM_AMOUNT_LC_D%type
  , pCumulAmountAll in out ACB_SCE_AMOUNT.SCM_AMOUNT_ALL_LC_D%type
  , pCumulAmount1   in out ACB_SCE_AMOUNT.SCM_AMOUNT_LC_D%type
  )
  is
  begin
    pCumulAmountAll  := pCumulAmountAll + pAmountAll;
    pCumulAmount1    := pCumulAmount1 + pAmount1;
  end;

  /**
  * procedure ManageSceAmounts
  * Description
  *  Calcul le nouveau montant et l'ajoute si pas de regroupement demandé
  */
  procedure ManageSceAmounts(
    pAmountAll                ACB_SCE_AMOUNT.SCM_AMOUNT_ALL_LC_D%type
  , pAmount1                  ACB_SCE_AMOUNT.SCM_AMOUNT_LC_D%type
  , pC_ACB_BUDGETING_ELEMENT  ACB_ELEMENT.C_ACB_BUDGETING_ELEMENT%type
  , pC_ACB_CONDITION_TYPE     ACB_ELEMENT_REFERENCE.C_ACB_CONDITION_TYPE%type
  , pPLV_VALUE                ACB_PLANING_VALUES.PLV_value%type
  , pACB_SCE_EXERCISE_ID      ACB_SCE_AMOUNT.ACB_SCE_EXERCISE_ID%type
  , pACS_FINANCIAL_ACCOUNT_ID ACB_SCE_AMOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pACS_DIVISION_ACCOUNT_ID  ACB_SCE_AMOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , pACB_ELEMENT_ID           ACB_SCE_AMOUNT.ACB_ELEMENT_ID%type
  )
  is
    vAmountAll ACB_SCE_AMOUNT.SCM_AMOUNT_ALL_LC_D%type   default 0;
    vAmount1   ACB_SCE_AMOUNT.SCM_AMOUNT_LC_D%type       default 0;
  begin
    if pPLV_VALUE <> 0 then
      vAmountAll  := pAmountAll;
      vAmount1    := pAmount1;

      if ApplyAutomatismValue(pPLV_VALUE              => pPLV_VALUE
                            , pC_ACB_CONDITION_TYPE   => pC_ACB_CONDITION_TYPE
                            , pAmountAll              => vAmountAll
                            , pAmount1                => vAmount1
                             ) then
        AddSceAmount(pACB_SCE_EXERCISE_ID        => pACB_SCE_EXERCISE_ID
                   , pACS_FINANCIAL_ACCOUNT_ID   => pACS_FINANCIAL_ACCOUNT_ID
                   , pACS_DIVISION_ACCOUNT_ID    => pACS_DIVISION_ACCOUNT_ID
                   , pACB_ELEMENT_ID             => pACB_ELEMENT_ID
                   , pC_AMOUNT_ORIGIN            => pC_ACB_BUDGETING_ELEMENT
                   , pSCM_COMMENT                => ''
                   , pSCM_MANUAL                 => 0
                   , pSCM_AMOUNT_ALL             => vAmountAll
                   , pSCM_AMOUNT                 => vAmount1
                    );
      end if;
    end if;
  end ManageSceAmounts;

  /**
  * function GetPlaningValue
  *  Retourne True s'il existe une valeur pour l'élément et l'exercice
  */
  function GetPlaningValue(
    pACB_ELEMENT_REFERENCE_ID     ACB_ELEMENT_REFERENCE.ACB_ELEMENT_REFERENCE_ID%type
  , pACB_SCE_EXERCISE_ID          ACB_SCE_EXERCISE.ACB_SCE_EXERCISE_ID%type
  , pPLV_VALUE                out ACB_PLANING_VALUES.PLV_value%type
  )
    return boolean
  is
    vResult signtype;
  begin
    --Retourne True même si la valeur trouvée = 0
    --Retourne False unqiuement si aucune valeur n'est trouvée pour l'élément et l'exercise. Cela permet de réinitialiser les automatismes
    begin
      select PLV_value
        into pPLV_VALUE
        from ACB_PLANING_VALUES PLV
       where PLV.ACB_ELEMENT_REFERENCE_ID = pACB_ELEMENT_REFERENCE_ID
         and PLV.PYE_NO_EXERCISE = (select PYE_NO_EXERCISE
                                      from ACB_SCE_EXERCISE
                                     where ACB_SCE_EXERCISE_ID = pACB_SCE_EXERCISE_ID);
    exception
      when no_data_found then
        pPLV_VALUE  := 0;
        return false;
    end;

    return true;
  end GetPlaningValue;

  /**
  * procedure ApplyAutomatismValue
  * Description
  *  Applique le type d'automatisme sur les montants pAmountAll, pAmount1
  */
  function ApplyAutomatismValue(
    pPLV_VALUE                   ACB_PLANING_VALUES.PLV_value%type
  , pC_ACB_CONDITION_TYPE        ACB_ELEMENT_REFERENCE.C_ACB_CONDITION_TYPE%type
  , pAmountAll            in out ACB_SCE_AMOUNT.SCM_AMOUNT_ALL_LC_D%type
  , pAmount1              in out ACB_SCE_AMOUNT.SCM_AMOUNT_LC_D%type
  )
    return boolean
  is
    vResultAll boolean default false;
    vResult1   boolean default false;
  begin
    if pPLV_VALUE <> 0 then
      if     (pAmountAll <> 0)
         and (    (pC_ACB_CONDITION_TYPE = 1)
              or (     (pAmountAll > 0)
                  and pC_ACB_CONDITION_TYPE = 2)
              or (     (pAmountAll < 0)
                  and pC_ACB_CONDITION_TYPE = 3)
             ) then
        pAmountAll  := (pAmountAll * pPLV_VALUE) / 100;
        vResultAll  := true;
      else
        pAmountAll  := 0;
      end if;

      if     (pAmount1 <> 0)
         and (    (pC_ACB_CONDITION_TYPE = 1)
              or (     (pAmount1 > 0)
                  and pC_ACB_CONDITION_TYPE = 2)
              or (     (pAmount1 < 0)
                  and pC_ACB_CONDITION_TYPE = 3)
             ) then
        pAmount1  := (pAmount1 * pPLV_VALUE) / 100;
        vResult1  := true;
      else
        pAmount1  := 0;
      end if;
    end if;

    return    vResultAll
           or vResult1;
  end ApplyAutomatismValue;

  /**
  * procedure AddSceAmount
  * Description
  *  Ajoute un montant
  */
  procedure AddSceAmount(
    pACB_SCE_EXERCISE_ID      ACB_SCE_AMOUNT.ACB_SCE_EXERCISE_ID%type
  , pACS_FINANCIAL_ACCOUNT_ID ACB_SCE_AMOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pACS_DIVISION_ACCOUNT_ID  ACB_SCE_AMOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , pACB_ELEMENT_ID           ACB_SCE_AMOUNT.ACB_ELEMENT_ID%type
  , pC_AMOUNT_ORIGIN          ACB_SCE_AMOUNT.C_AMOUNT_ORIGIN%type
  , pSCM_COMMENT              ACB_SCE_AMOUNT.SCM_COMMENT%type
  , pSCM_MANUAL               ACB_SCE_AMOUNT.SCM_MANUAL%type
  , pSCM_AMOUNT_ALL           ACB_SCE_AMOUNT.SCM_AMOUNT_ALL_LC_D%type
  , pSCM_AMOUNT               ACB_SCE_AMOUNT.SCM_AMOUNT_LC_D%type
  )
  is
  begin
    insert into ACB_SCE_AMOUNT
                (ACB_SCE_AMOUNT_ID
               , ACB_SCE_EXERCISE_ID
               , SCM_COMMENT
               , C_AMOUNT_ORIGIN
               , SCM_MANUAL
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACB_ELEMENT_ID
               , SCM_AMOUNT_ALL_LC_D
               , SCM_AMOUNT_ALL_LC_C
               , SCM_AMOUNT_LC_D
               , SCM_AMOUNT_LC_C
               , SCM_AMOUNT_DIFF_LC_D
               , SCM_AMOUNT_DIFF_LC_C
               , A_DATECRE
               , A_IDCRE
                )
         values (INIT_ID_SEQ.nextval
               , pACB_SCE_EXERCISE_ID
               , pSCM_COMMENT
               , pC_AMOUNT_ORIGIN
               , pSCM_MANUAL
               , decode(pACS_FINANCIAL_ACCOUNT_ID, 0, null, pACS_FINANCIAL_ACCOUNT_ID)
               , decode(pACS_DIVISION_ACCOUNT_ID, 0, null, pACS_DIVISION_ACCOUNT_ID)
               , decode(pACB_ELEMENT_ID, 0, null, pACB_ELEMENT_ID)
               , decode(sign(nvl(pSCM_AMOUNT_ALL, 0) ), 1, pSCM_AMOUNT_ALL, 0)
               , decode(sign(nvl(pSCM_AMOUNT_ALL, 0) ), -1, abs(pSCM_AMOUNT_ALL), 0)
               , decode(sign(nvl(pSCM_AMOUNT, 0) ), 1, pSCM_AMOUNT, 0)
               , decode(sign(nvl(pSCM_AMOUNT, 0) ), -1, abs(pSCM_AMOUNT), 0)
               , decode(sign(nvl(pSCM_AMOUNT_ALL, 0) - nvl(pSCM_AMOUNT, 0) )
                      , 1, nvl(pSCM_AMOUNT_ALL, 0) - nvl(pSCM_AMOUNT, 0)
                      , 0
                       )
               , decode(sign(nvl(pSCM_AMOUNT_ALL, 0) - nvl(pSCM_AMOUNT, 0) )
                      , -1, abs(nvl(pSCM_AMOUNT_ALL, 0) - nvl(pSCM_AMOUNT, 0) )
                      , 0
                       )
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end AddSceAmount;

  /**
  *   Création des positions report de type 10
  **/
  procedure CreateReportPosition(pScenarioId ACB_SCENARIO.ACB_SCENARIO_ID%type)
  is
    /*Curseur définissant la structure de la table de récption des cibles*/
    cursor cReportLine
    is
      select 0 ACB_SCENARIO_ID
           , 0 SCR_REPORT
           , 0 SCR_LINE
           , 0 SCR_AMOUNT_LC_1
           , 0 SCR_AMOUNT_LC_2
           , 0 SCR_AMOUNT_LC_3
           , 0 SCR_AMOUNT_LC_4
           , 0 SCR_AMOUNT_LC_5
           , 0 SCR_AMOUNT_LC_6
           , 0 SCR_AMOUNT_LC_7
        from dual;

    /*Structure table de réception des enregistrements */
    type TReportPosition is table of cReportLine%rowtype
      index by binary_integer;

    /*Variable de réception des positions du tableau */
    vReportPosition TReportPosition;
    vCounter        number;

    procedure DefineRatioLines(
      pReportType  ACB_SCE_REPORT.SCR_REPORT%type
    , pLineNumber  ACB_SCE_REPORT.SCR_LINE%type
    , pReportDescr ACB_SCE_REPORT.SCR_DESCRIPTION%type
    , pLines       varchar2
    , pPercent     number
    )
    is
      cursor LineAmountsCursor(pLineNumber ACB_SCE_REPORT.SCR_LINE%type)
      is
        select SCR_AMOUNT_LC_1
             , SCR_AMOUNT_LC_2
             , SCR_AMOUNT_LC_3
             , SCR_AMOUNT_LC_4
             , SCR_AMOUNT_LC_5
             , SCR_AMOUNT_LC_6
             , SCR_AMOUNT_LC_7
          from ACB_SCE_REPORT
         where ACB_SCENARIO_ID = pScenarioId
           and SCR_REPORT = pReportType
           and SCR_LINE = pLineNumber;

      vLineAmount LineAmountsCursor%rowtype;
      vAmount1    ACB_SCE_REPORT.SCR_AMOUNT_LC_1%type;
      vAmount2    ACB_SCE_REPORT.SCR_AMOUNT_LC_2%type;
      vAmount3    ACB_SCE_REPORT.SCR_AMOUNT_LC_3%type;
      vAmount4    ACB_SCE_REPORT.SCR_AMOUNT_LC_4%type;
      vAmount5    ACB_SCE_REPORT.SCR_AMOUNT_LC_5%type;
      vAmount6    ACB_SCE_REPORT.SCR_AMOUNT_LC_6%type;
      vAmount7    ACB_SCE_REPORT.SCR_AMOUNT_LC_7%type;
      vLines      varchar2(500);
      vCounter    number;
    begin
      vAmount1  := 0;
      vAmount2  := 0;
      vAmount3  := 0;
      vAmount4  := 0;
      vAmount5  := 0;
      vAmount6  := 0;
      vAmount7  := 0;
      vLines    := pLines;
      vCounter  := 1;

      while instr(vLines, ';') > 0 loop
        open LineAmountsCursor(substr(vLines, 1, instr(vLines, ';') - 1) );

        fetch LineAmountsCursor
         into vLineAmount;

        if vCounter = 1 then
          vAmount1  := vAmount1 + vLineAmount.SCR_AMOUNT_LC_1;
          vAmount2  := vAmount2 + vLineAmount.SCR_AMOUNT_LC_2;
          vAmount3  := vAmount3 + vLineAmount.SCR_AMOUNT_LC_3;
          vAmount4  := vAmount4 + vLineAmount.SCR_AMOUNT_LC_4;
          vAmount5  := vAmount5 + vLineAmount.SCR_AMOUNT_LC_5;
          vAmount6  := vAmount6 + vLineAmount.SCR_AMOUNT_LC_6;
          vAmount7  := vAmount7 + vLineAmount.SCR_AMOUNT_LC_7;
        else
          if vLineAmount.SCR_AMOUNT_LC_1 <> 0 then
            vAmount1  := vAmount1 / vLineAmount.SCR_AMOUNT_LC_1 * pPercent;
          else
            vAmount1  := 0;
          end if;

          if vLineAmount.SCR_AMOUNT_LC_2 <> 0 then
            vAmount2  := vAmount2 / vLineAmount.SCR_AMOUNT_LC_2 * pPercent;
          else
            vAmount2  := 0;
          end if;

          if vLineAmount.SCR_AMOUNT_LC_3 <> 0 then
            vAmount3  := vAmount3 / vLineAmount.SCR_AMOUNT_LC_3 * pPercent;
          else
            vAmount3  := 0;
          end if;

          if vLineAmount.SCR_AMOUNT_LC_4 <> 0 then
            vAmount4  := vAmount4 / vLineAmount.SCR_AMOUNT_LC_4 * pPercent;
          else
            vAmount4  := 0;
          end if;

          if vLineAmount.SCR_AMOUNT_LC_5 <> 0 then
            vAmount5  := vAmount5 / vLineAmount.SCR_AMOUNT_LC_5 * pPercent;
          else
            vAmount5  := 0;
          end if;

          if vLineAmount.SCR_AMOUNT_LC_6 <> 0 then
            vAmount6  := vAmount6 / vLineAmount.SCR_AMOUNT_LC_6 * pPercent;
          else
            vAmount6  := 0;
          end if;

          if vLineAmount.SCR_AMOUNT_LC_7 <> 0 then
            vAmount7  := vAmount7 / vLineAmount.SCR_AMOUNT_LC_7 * pPercent;
          else
            vAmount7  := 0;
          end if;
        end if;

        vLines    := substr(vLines, instr(vLines, ';') + 1, length(vLines) );
        vCounter  := vCounter + 1;

        close LineAmountsCursor;
      end loop;

      insert into ACB_SCE_REPORT
                  (ACB_SCE_REPORT_ID
                 , ACB_SCENARIO_ID
                 , SCR_REPORT
                 , SCR_LINE
                 , SCR_DESCRIPTION
                 , SCR_AMOUNT_LC_1
                 , SCR_AMOUNT_LC_2
                 , SCR_AMOUNT_LC_3
                 , SCR_AMOUNT_LC_4
                 , SCR_AMOUNT_LC_5
                 , SCR_AMOUNT_LC_6
                 , SCR_AMOUNT_LC_7
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , pScenarioId
                 , pReportType
                 , pLineNumber
                 , pReportDescr
                 , vAmount1
                 , vAmount2
                 , vAmount3
                 , vAmount4
                 , vAmount5
                 , vAmount6
                 , vAmount7
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end DefineRatioLines;

    procedure DefineSumLines(
      pReportType  ACB_SCE_REPORT.SCR_REPORT%type
    , pLineType    ACB_SCE_REPORT.SCR_REPORT%type
    , pLineNumber  ACB_SCE_REPORT.SCR_LINE%type
    , pReportDescr ACB_SCE_REPORT.SCR_DESCRIPTION%type
    , pAbs         number
    , pLines       varchar2
    , pSigns       varchar2
    )
    is
      cursor LineAbsAmountsCursor(pLNumber ACB_SCE_REPORT.SCR_LINE%type, pLineSign number)
      is
        select abs(SCR_AMOUNT_LC_1) * pLineSign SCR_AMOUNT_LC_1
             , abs(SCR_AMOUNT_LC_2) * pLineSign SCR_AMOUNT_LC_2
             , abs(SCR_AMOUNT_LC_3) * pLineSign SCR_AMOUNT_LC_3
             , abs(SCR_AMOUNT_LC_4) * pLineSign SCR_AMOUNT_LC_4
             , abs(SCR_AMOUNT_LC_5) * pLineSign SCR_AMOUNT_LC_5
             , abs(SCR_AMOUNT_LC_6) * pLineSign SCR_AMOUNT_LC_6
             , abs(SCR_AMOUNT_LC_7) * pLineSign SCR_AMOUNT_LC_7
          from ACB_SCE_REPORT
         where ACB_SCENARIO_ID = pScenarioId
           and SCR_REPORT = pReportType
           and SCR_LINE = pLNumber;

      cursor LineAmountsCursor(pLNumber ACB_SCE_REPORT.SCR_LINE%type, pLineSign number)
      is
        select SCR_AMOUNT_LC_1 * pLineSign SCR_AMOUNT_LC_1
             , SCR_AMOUNT_LC_2 * pLineSign SCR_AMOUNT_LC_2
             , SCR_AMOUNT_LC_3 * pLineSign SCR_AMOUNT_LC_3
             , SCR_AMOUNT_LC_4 * pLineSign SCR_AMOUNT_LC_4
             , SCR_AMOUNT_LC_5 * pLineSign SCR_AMOUNT_LC_5
             , SCR_AMOUNT_LC_6 * pLineSign SCR_AMOUNT_LC_6
             , SCR_AMOUNT_LC_7 * pLineSign SCR_AMOUNT_LC_7
          from ACB_SCE_REPORT
         where ACB_SCENARIO_ID = pScenarioId
           and SCR_REPORT = pReportType
           and SCR_LINE = pLNumber;

      vLineAmount LineAbsAmountsCursor%rowtype;
      vAmount1    ACB_SCE_REPORT.SCR_AMOUNT_LC_1%type;
      vAmount2    ACB_SCE_REPORT.SCR_AMOUNT_LC_2%type;
      vAmount3    ACB_SCE_REPORT.SCR_AMOUNT_LC_3%type;
      vAmount4    ACB_SCE_REPORT.SCR_AMOUNT_LC_4%type;
      vAmount5    ACB_SCE_REPORT.SCR_AMOUNT_LC_5%type;
      vAmount6    ACB_SCE_REPORT.SCR_AMOUNT_LC_6%type;
      vAmount7    ACB_SCE_REPORT.SCR_AMOUNT_LC_7%type;
      vLines      varchar2(500);
      vSigns      varchar2(500);
    begin
      vAmount1  := 0;
      vAmount2  := 0;
      vAmount3  := 0;
      vAmount4  := 0;
      vAmount5  := 0;
      vAmount6  := 0;
      vAmount7  := 0;
      vLines    := pLines;
      vSigns    := pSigns;

      while instr(vLines, ';') > 0 loop
        if pAbs = 1 then
          open LineAbsAmountsCursor(substr(vLines, 1, instr(vLines, ';') - 1)
                                  , to_number(substr(vSigns, 1, instr(vLines, ';') - 1) )
                                   );

          fetch LineAbsAmountsCursor
           into vLineAmount;
        else
          open LineAmountsCursor(substr(vLines, 1, instr(vLines, ';') - 1)
                               , to_number(substr(vSigns, 1, instr(vLines, ';') - 1) )
                                );

          fetch LineAmountsCursor
           into vLineAmount;
        end if;

        vAmount1  := vAmount1 + vLineAmount.SCR_AMOUNT_LC_1;
        vAmount2  := vAmount2 + vLineAmount.SCR_AMOUNT_LC_2;
        vAmount3  := vAmount3 + vLineAmount.SCR_AMOUNT_LC_3;
        vAmount4  := vAmount4 + vLineAmount.SCR_AMOUNT_LC_4;
        vAmount5  := vAmount5 + vLineAmount.SCR_AMOUNT_LC_5;
        vAmount6  := vAmount6 + vLineAmount.SCR_AMOUNT_LC_6;
        vAmount7  := vAmount7 + vLineAmount.SCR_AMOUNT_LC_7;
        vLines    := substr(vLines, instr(vLines, ';') + 1, length(vLines) );
        vSigns    := substr(vSigns, instr(vLines, ';') + 1, length(vSigns) );

        if pAbs = 1 then
          close LineAbsAmountsCursor;
        else
          close LineAmountsCursor;
        end if;
      end loop;

      insert into ACB_SCE_REPORT
                  (ACB_SCE_REPORT_ID
                 , ACB_SCENARIO_ID
                 , SCR_REPORT
                 , SCR_LINE
                 , SCR_DESCRIPTION
                 , SCR_AMOUNT_LC_1
                 , SCR_AMOUNT_LC_2
                 , SCR_AMOUNT_LC_3
                 , SCR_AMOUNT_LC_4
                 , SCR_AMOUNT_LC_5
                 , SCR_AMOUNT_LC_6
                 , SCR_AMOUNT_LC_7
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , pScenarioId
                 , pLineType
                 , pLineNumber
                 , pReportDescr
                 , vAmount1
                 , vAmount2
                 , vAmount3
                 , vAmount4
                 , vAmount5
                 , vAmount6
                 , vAmount7
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end DefineSumLines;

    procedure DefineLine(pReportType ACB_SCE_REPORT.SCR_REPORT%type, pLineNumber ACB_SCE_REPORT.SCR_LINE%type)
    is
      vDebRefField  PCS.PC_FLDSC.FLDNAME%type;
      vCreRefField  PCS.PC_FLDSC.FLDNAME%type;
      vReportDescr  ACB_SCE_REPORT.SCR_DESCRIPTION%type;
      vFinAccCode   varchar2(500);
      vSQLText      varchar2(10000);   --Commande SQL a exécuter
      vLinesSQLText varchar2(10000);   --Commande SQL des lignes
      vHeaderSQL    varchar2(10000);   --Commande SQL en-tête
      vVoidSQLText  varchar2(10000);   --Commde SQL ligne vide
      vSumSQLText   varchar2(10000);   --Commande SQL de sum de lignes existantes
    begin
      --Construction des commandes SQL générale
      vVoidSQLText   :=
        'select null ACB_SCENARIO_ID,' ||
        chr(13) ||
        '       null SCR_REPORT,     ' ||
        chr(13) ||
        '       null SCR_LINE,       ' ||
        chr(13) ||
        '       null SCR_AMOUNT_LC_1,' ||
        chr(13) ||
        '       null SCR_AMOUNT_LC_2,' ||
        chr(13) ||
        '       null SCR_AMOUNT_LC_3,' ||
        chr(13) ||
        '       null SCR_AMOUNT_LC_4,' ||
        chr(13) ||
        '       null SCR_AMOUNT_LC_5,' ||
        chr(13) ||
        '       null SCR_AMOUNT_LC_6,' ||
        chr(13) ||
        '       null SCR_AMOUNT_LC_7 ' ||
        chr(13) ||
        'from ACB_SCE_EXERCISE SCC   ' ||
        chr(13) ||
        'where SCC.ACB_SCENARIO_ID = [ACB_SCENARIO_ID]' ||
        chr(13) ||
        '  and SCC.ACB_BUDGET_VERSION_ID is not null';
      vHeaderSQL     :=
        'select null ACB_SCENARIO_ID, null SCR_REPORT, null SCR_LINE,' ||
        chr(13) ||
        '       MIN(SCC.PYE_NO_EXERCISE)-1 SCR_AMOUNT_LC_1, ' ||
        chr(13) ||
        '       MIN(SCC.PYE_NO_EXERCISE)   SCR_AMOUNT_LC_2, ' ||
        chr(13) ||
        '       MIN(SCC.PYE_NO_EXERCISE)+1 SCR_AMOUNT_LC_3, ' ||
        chr(13) ||
        '       MIN(SCC.PYE_NO_EXERCISE)+2 SCR_AMOUNT_LC_4, ' ||
        chr(13) ||
        '       MIN(SCC.PYE_NO_EXERCISE)+3 SCR_AMOUNT_LC_5, ' ||
        chr(13) ||
        '       MIN(SCC.PYE_NO_EXERCISE)+4 SCR_AMOUNT_LC_6, ' ||
        chr(13) ||
        '       MIN(SCC.PYE_NO_EXERCISE)+5 SCR_AMOUNT_LC_7  ' ||
        chr(13) ||
        'from ACB_SCE_EXERCISE SCC                          ' ||
        chr(13) ||
        'where SCC.ACB_SCENARIO_ID = [ACB_SCENARIO_ID]      ' ||
        chr(13) ||
        '  and SCC.ACB_BUDGET_VERSION_ID is not null';
      vLinesSQLText  :=
        'select ACB_SCENARIO_ID, SCR_REPORT, SCR_LINE,' ||
        chr(13) ||
        '       SUM(SCR_AMOUNT_LC_1) SCR_AMOUNT_LC_1, ' ||
        chr(13) ||
        '       SUM(SCR_AMOUNT_LC_2) SCR_AMOUNT_LC_2, ' ||
        chr(13) ||
        '       SUM(SCR_AMOUNT_LC_3) SCR_AMOUNT_LC_3, ' ||
        chr(13) ||
        '       SUM(SCR_AMOUNT_LC_4) SCR_AMOUNT_LC_4, ' ||
        chr(13) ||
        '       SUM(SCR_AMOUNT_LC_5) SCR_AMOUNT_LC_5, ' ||
        chr(13) ||
        '       SUM(SCR_AMOUNT_LC_6) SCR_AMOUNT_LC_6, ' ||
        chr(13) ||
        '       SUM(SCR_AMOUNT_LC_7) SCR_AMOUNT_LC_7  ' ||
        chr(13) ||
        'from (select BSC.ACB_SCENARIO_ID, [SCR_REPORT] SCR_REPORT , [LINENUMBER] SCR_LINE,  ' ||
        chr(13) ||
        '             case                                                        ' ||
        chr(13) ||
        '               when SCE.PYE_NO_EXERCISE = (SELECT MIN(SCC.PYE_NO_EXERCISE)-1 FROM ACB_SCE_EXERCISE SCC WHERE SCC.ACB_SCENARIO_ID = BSC.ACB_SCENARIO_ID AND SCC.ACB_BUDGET_VERSION_ID IS NOT NULL GROUP BY SCC.ACB_SCENARIO_ID) then ' ||
        chr(13) ||
        '                 sum(([DEBREFFIELD]-[CREREFFIELD]) * -1)                 ' ||
        chr(13) ||
        '               else 0                                                    ' ||
        chr(13) ||
        '             end SCR_AMOUNT_LC_1,                                        ' ||
        chr(13) ||
        '             case                                                        ' ||
        chr(13) ||
        '               when SCE.PYE_NO_EXERCISE = (SELECT MIN(SCC.PYE_NO_EXERCISE) FROM ACB_SCE_EXERCISE SCC WHERE SCC.ACB_SCENARIO_ID = BSC.ACB_SCENARIO_ID AND SCC.ACB_BUDGET_VERSION_ID IS NOT NULL GROUP BY SCC.ACB_SCENARIO_ID) then ' ||
        chr(13) ||
        '                 sum(([DEBREFFIELD]-[CREREFFIELD]) * -1)                 ' ||
        chr(13) ||
        '               else 0                                                    ' ||
        chr(13) ||
        '             end SCR_AMOUNT_LC_2,                                        ' ||
        chr(13) ||
        '             case                                                        ' ||
        chr(13) ||
        '               when SCE.PYE_NO_EXERCISE = (SELECT MIN(SCC.PYE_NO_EXERCISE)+1 FROM ACB_SCE_EXERCISE SCC WHERE SCC.ACB_SCENARIO_ID = BSC.ACB_SCENARIO_ID AND SCC.ACB_BUDGET_VERSION_ID IS NOT NULL GROUP BY SCC.ACB_SCENARIO_ID) then ' ||
        chr(13) ||
        '                 sum(([DEBREFFIELD]-[CREREFFIELD]) * -1)                 ' ||
        chr(13) ||
        '               else 0                                                    ' ||
        chr(13) ||
        '             end SCR_AMOUNT_LC_3,                                        ' ||
        chr(13) ||
        '             case                                                        ' ||
        chr(13) ||
        '               when SCE.PYE_NO_EXERCISE = (SELECT MIN(SCC.PYE_NO_EXERCISE)+2 FROM ACB_SCE_EXERCISE SCC WHERE SCC.ACB_SCENARIO_ID = BSC.ACB_SCENARIO_ID AND SCC.ACB_BUDGET_VERSION_ID IS NOT NULL GROUP BY SCC.ACB_SCENARIO_ID) then ' ||
        chr(13) ||
        '                 sum(([DEBREFFIELD]-[CREREFFIELD]) * -1)                 ' ||
        chr(13) ||
        '               else 0                                                    ' ||
        chr(13) ||
        '             end SCR_AMOUNT_LC_4,                                        ' ||
        chr(13) ||
        '             case                                                        ' ||
        chr(13) ||
        '               when SCE.PYE_NO_EXERCISE = (SELECT MIN(SCC.PYE_NO_EXERCISE)+3 FROM ACB_SCE_EXERCISE SCC WHERE SCC.ACB_SCENARIO_ID = BSC.ACB_SCENARIO_ID AND SCC.ACB_BUDGET_VERSION_ID IS NOT NULL GROUP BY SCC.ACB_SCENARIO_ID) then ' ||
        chr(13) ||
        '                 sum (([DEBREFFIELD]-[CREREFFIELD]) * -1)                ' ||
        chr(13) ||
        '               else 0                                                    ' ||
        chr(13) ||
        '             end SCR_AMOUNT_LC_5,                                        ' ||
        chr(13) ||
        '             case                                                        ' ||
        chr(13) ||
        '               when SCE.PYE_NO_EXERCISE = (SELECT MIN(SCC.PYE_NO_EXERCISE)+4 FROM ACB_SCE_EXERCISE SCC WHERE SCC.ACB_SCENARIO_ID = BSC.ACB_SCENARIO_ID AND SCC.ACB_BUDGET_VERSION_ID IS NOT NULL GROUP BY SCC.ACB_SCENARIO_ID) then ' ||
        chr(13) ||
        '                 sum(([DEBREFFIELD]-[CREREFFIELD]) * -1)                 ' ||
        chr(13) ||
        '               else 0                                                    ' ||
        chr(13) ||
        '             end SCR_AMOUNT_LC_6,                                        ' ||
        chr(13) ||
        '             case                                                        ' ||
        chr(13) ||
        '               when SCE.PYE_NO_EXERCISE = (SELECT MIN(SCC.PYE_NO_EXERCISE)+5 FROM ACB_SCE_EXERCISE SCC WHERE SCC.ACB_SCENARIO_ID = BSC.ACB_SCENARIO_ID AND SCC.ACB_BUDGET_VERSION_ID IS NOT NULL GROUP BY SCC.ACB_SCENARIO_ID) then ' ||
        chr(13) ||
        '                 sum (([DEBREFFIELD]-[CREREFFIELD]) * -1)                ' ||
        chr(13) ||
        '               else 0                                                    ' ||
        chr(13) ||
        '             end SCR_AMOUNT_LC_7                                         ' ||
        chr(13) ||
        '      from  ACS_FINANCIAL_ACCOUNT FIN,                                   ' ||
        chr(13) ||
        '            ACS_ACCOUNT ACC,                                             ' ||
        chr(13) ||
        '            ACB_SCE_AMOUNT SCM,                                          ' ||
        chr(13) ||
        '            ACB_SCE_EXERCISE SCE,                                        ' ||
        chr(13) ||
        '            ACB_SCENARIO BSC                                             ' ||
        chr(13) ||
        '      where  BSC.ACB_SCENARIO_ID = [ACB_SCENARIO_ID]                     ' ||
        chr(13) ||
        '         and BSC.ACB_SCENARIO_ID = SCE.ACB_SCENARIO_ID                   ' ||
        chr(13) ||
        '         and SCE.ACB_SCE_EXERCISE_ID = SCM.ACB_SCE_EXERCISE_ID           ' ||
        chr(13) ||
        '         and SCM.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID           ' ||
        chr(13) ||
        '         and SCM.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID ' ||
        chr(13) ||
        '         [FIN_ACC_CODE]                                                  ' ||
        chr(13) ||
        '         and FIN.DIC_FIN_ACC_CODE_10_ID = ''1''                          ' ||
        chr(13) ||
        '      group by BSC.ACB_SCENARIO_ID, SCE.PYE_NO_EXERCISE                  ' ||
        chr(13) ||
        '     ) group by ACB_SCENARIO_ID, SCR_REPORT, SCR_LINE';
      vReportDescr   := '';
      vReportPosition.delete;

      if pReportType = 0 then
        vSQLText      := vLinesSQLText;
        vDebRefField  := 'SCM_AMOUNT_ALL_LC_D';
        vCreRefField  := 'SCM_AMOUNT_ALL_LC_C';

        if pLineNumber = 10 then
          vReportDescr  := 'Excédent de revenus du compte de fonctionnement';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_1_ID in (''3'', ''4'') ';
        elsif(pLineNumber = 20) then
          vReportDescr  := 'Dépréciations harmonisées du patrimoine administratif';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_3_ID = ''331'' ';
        elsif(pLineNumber = 30) then
          vReportDescr  := 'Dépréciations complémentaires du patrimoine administratif';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_3_ID = ''332'' ';
        elsif(pLineNumber = 40) then
          vReportDescr  := 'Dépréciation du découvert du bilan';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_3_ID = ''333'' ';
        elsif(pLineNumber = 50) then
          vReportDescr  := 'Attributions aux financements spéciaux';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_2_ID = ''38'' ';
        elsif pLineNumber = 60 then
          vReportDescr  := 'Prélèvement sur les financements spéciaux';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_2_ID = ''48'' ';
        elsif pLineNumber = 70 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Autofinancement'
                       , 1
                       , '10;20;30;40;50;60;'
                       , '1 ;1 ;1 ;1 ;1 ;-1;'
                        );
        elsif(pLineNumber = 80) then
          vReportDescr  := 'Dépenses reportées au bilan';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_1_ID = ''5'' and FIN.DIC_FIN_ACC_CODE_3_ID <> ''590'' ';
        elsif pLineNumber = 90 then
          vReportDescr  := 'Recettes reportées au bilan';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_1_ID = ''6'' and FIN.DIC_FIN_ACC_CODE_3_ID <> ''690'' ';
        elsif pLineNumber = 100 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Investissement net', 1, '80;90;', '1 ;-1;');
        elsif pLineNumber = 110 then
          vSQLText  := '';
          DefineRatioLines(pReportType, pLineNumber, 'Degré autonfinancement', '70;100;', 100);
        elsif pLineNumber = 120 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Autofinancement', 1, '70;', '1 ;');
        elsif pLineNumber = 130 then
          vReportDescr  := 'Revenu du compte de fonctionnement';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_1_ID = ''4'' ';
        elsif pLineNumber = 140 then
          vReportDescr  := 'Subventions redistribuées';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_2_ID = ''47'' ';
        elsif pLineNumber = 150 then
          vReportDescr  := 'Prélèvement sur les financements spéciaux';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_2_ID = ''48'' ';
        elsif pLineNumber = 160 then
          vReportDescr  := 'Imputations internes';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_2_ID = ''49'' ';
        elsif pLineNumber = 170 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Revenus', 1, '130;140;150;160;', '1  ;-1 ;-1 ;-1 ;');
        elsif pLineNumber = 180 then
          vSQLText  := '';
          DefineRatioLines(pReportType, pLineNumber, 'Quotité d''autonfinancement', '120;170;', 100);
        elsif pLineNumber = 190 then
          vReportDescr  := 'Intérêts passifs';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_2_ID = ''32'' ';
        elsif pLineNumber = 200 then
          vReportDescr  := 'Revenu des biens';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_2_ID = ''42'' ';
        elsif pLineNumber = 210 then
          vReportDescr  := 'Gains comptables sur placements du patrimoine financier';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_3_ID = ''424'' ';
        elsif pLineNumber = 220 then
          vReportDescr  := 'Excédent de recettes du compte des investissements';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_3_ID = ''428'' ';
        elsif pLineNumber = 230 then
          vReportDescr  := 'Immeubles du patrimoine financier';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_8_ID = ''942'' ';
        elsif pLineNumber = 240 then
          vReportDescr  := 'Intérêts imputés';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_8_ID = ''942'' and FIN.DIC_FIN_ACC_CODE_3_ID = ''391''';
        elsif pLineNumber = 250 then
          vReportDescr  := 'Domaines';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_8_ID = ''943'' ';
        elsif pLineNumber = 260 then
          vReportDescr  := 'Intérêts imputés';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_8_ID = ''943'' and FIN.DIC_FIN_ACC_CODE_3_ID = ''391''';
        elsif pLineNumber = 270 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Intérêts nets'
                       , 1
                       , '190;200;210;220;230;240;250;260;'
                       , '1  ;-1 ;1  ;1  ;1  ;-1 ;1  ;-1 ;'
                        );
        elsif pLineNumber = 280 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Revenus', 1, '170;', '1  ;');
        elsif pLineNumber = 290 then
          vSQLText  := '';
          DefineRatioLines(pReportType, pLineNumber, 'Quotité de la charge des intérêts', '270;280;', 100);
        elsif pLineNumber = 300 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Intérêts passifs', 1, '190;', '1  ;');
        elsif pLineNumber = 310 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Dépréciations harmonisées du patrimoine administratif'
                       , 1
                       , '20;'
                       , '1  ;'
                        );
        elsif pLineNumber = 320 then
          vReportDescr  := 'Alimentation en eau,dépréciations dur la base de la valeur de remplacement';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_7_ID = ''70'' and FIN.DIC_FIN_ACC_CODE_3_ID = ''331''';
        elsif pLineNumber = 330 then
          vReportDescr  := 'Assainissement,dépréciations dur la base de la valeur de remplacement';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_7_ID = ''71'' and FIN.DIC_FIN_ACC_CODE_3_ID = ''331''';
        elsif pLineNumber = 340 then
          vReportDescr  := 'Alimentation en eau,attribution au FS "maintien de la valeur"';
          vFinAccCode   :=
            ' and FIN.DIC_FIN_ACC_CODE_7_ID = ''70'' and FIN.DIC_FIN_ACC_CODE_3_ID = ''380'' and SUBSTR(ACC.ACC_NUMBER,9,2) = ''02''';
        elsif pLineNumber = 350 then
          vReportDescr  := 'Assainissement,attribution au FS "maintien de la valeur"';
          vFinAccCode   :=
            ' and FIN.DIC_FIN_ACC_CODE_7_ID = ''71'' and FIN.DIC_FIN_ACC_CODE_3_ID = ''380'' and SUBSTR(ACC.ACC_NUMBER,9,2) = ''02''';
        elsif pLineNumber = 360 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Dépréciation du découvert du bilan', 1, '40;', '1  ;');
        elsif pLineNumber = 370 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Revenu des biens', 1, '200;', '1  ;');
        elsif pLineNumber = 380 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Gains comptables sur placements du patrimoine financier'
                       , 1
                       , '210;'
                       , '1  ;'
                        );
        elsif pLineNumber = 390 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Excédent de recettes du compte des investissements'
                       , 1
                       , '220;'
                       , '1  ;'
                        );
        elsif pLineNumber = 400 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Immeubles du patrimoine financier', 1, '230;', '1  ;');
        elsif pLineNumber = 410 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Intérêts imputés', 1, '240;', '1  ;');
        elsif pLineNumber = 420 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Domaines', 1, '250;', '1  ;');
        elsif pLineNumber = 430 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Intérêts imputés', 1, '260;', '1  ;');
        elsif pLineNumber = 440 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Charge financière'
                       , 1
                       , '300;310;320;330;340;350;360;370;380;390;400;410;420;430;'
                       , '1  ;1  ;-1 ;-1 ;1  ;1  ;1  ;-1 ;1  ;1  ;1  ;-1 ;1  ;-1 ;'
                        );
        elsif pLineNumber = 450 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Revenus', 1, '170;', '1  ;');
        elsif pLineNumber = 460 then
          vSQLText  := '';
          DefineRatioLines(pReportType, pLineNumber, 'Quotité de la charge financière', '440;450;', 100);
        elsif pLineNumber = 470 then
          vReportDescr  := 'Dettes à court terme';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_3_ID = ''201''';
        elsif pLineNumber = 480 then
          vReportDescr  := 'Dettes à moyen et long terme';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_3_ID = ''202''';
        elsif pLineNumber = 490 then
          vReportDescr  := 'Entités particulières';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_3_ID = ''203''';
        elsif pLineNumber = 500 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Dettes brutes', 1, '470;480;490;', '1  ;1  ;1  ;');
        elsif pLineNumber = 510 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Revenus', 1, '170;', '1  ;');
        elsif pLineNumber = 520 then
          vSQLText  := '';
          DefineRatioLines(pReportType, pLineNumber, 'Dette brute / revenu', '500;510;', 100);
        elsif pLineNumber = 530 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Investissement bruts', 1, '80;', '1 ;');
        elsif pLineNumber = 540 then
          vReportDescr  := 'Charges totales du compte de fonctionnement';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_1_ID = ''3''';
        elsif pLineNumber = 550 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Dépenses reportées au bilan', 1, '80;', '1 ;');
        elsif pLineNumber = 560 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Dépréciations harmonisées du patrimoine administratif'
                       , 1
                       , '20;'
                       , '1 ;'
                        );
        elsif pLineNumber = 570 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Dépréciations complémentaires du patrimoine administratif'
                       , 1
                       , '30;'
                       , '1 ;'
                        );
        elsif pLineNumber = 580 then
          vSQLText  := '';
          DefineSumLines(pReportType, pReportType, pLineNumber, 'Dépréciation du découvert du bilan', 1, '40;', '1 ;');
        elsif pLineNumber = 590 then
          vReportDescr  := 'Subventions redistribuées';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_2_ID = ''37''';
        elsif pLineNumber = 600 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Attributions aux financements spéciaux'
                       , 1
                       , '50;'
                       , '1 ;'
                        );
        elsif pLineNumber = 610 then
          vReportDescr  := 'Imputations internes';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_2_ID = ''39''';
        elsif pLineNumber = 620 then
          vSQLText  := '';
          DefineSumLines(pReportType
                       , pReportType
                       , pLineNumber
                       , 'Dépenses consolidées'
                       , 1
                       , '540;550;560;570;580;590;600;610;'
                       , '1  ;1  ;-1 ;-1 ;-1 ;-1 ;-1 ;-1 ;'
                        );
        elsif pLineNumber = 630 then
          vSQLText  := '';
          DefineRatioLines(pReportType, pLineNumber, 'Quotité inv.', '530;620;', 100);
        elsif pLineNumber = 640 then
          vDebRefField  := 'SCM_AMOUNT_LC_D';
          vCreRefField  := 'SCM_AMOUNT_LC_C';
          vReportDescr  := 'Total des revenus';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_1_ID = ''4''';
        elsif pLineNumber = 650 then
          vDebRefField  := 'SCM_AMOUNT_LC_D';
          vCreRefField  := 'SCM_AMOUNT_LC_C';
          vReportDescr  := 'Total des charges';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_1_ID = ''3''';
        elsif pLineNumber = 660 then
          vFinAccCode  :=
            ' and FIN.DIC_FIN_ACC_CODE_1_ID in (''5'', ''6'') and FIN.DIC_FIN_ACC_CODE_3_ID <> ''590''  and FIN.DIC_FIN_ACC_CODE_3_ID <> ''690'' ';
        else
          vSQLText  := '';
        end if;
      elsif pReportType = 10 then
        vSQLText      := vLinesSQLText;
        vDebRefField  := 'SCM_AMOUNT_LC_D';
        vCreRefField  := 'SCM_AMOUNT_LC_C';

        if pLineNumber = 0 then   -- Ligne d'en-tête
          vSQLText  := vHeaderSQL;
        elsif pLineNumber = 10 then
          vSQLText  := vVoidSQLText;
        elsif pLineNumber = 20 then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, '', 1, '640;', '1  ;');
        elsif pLineNumber = 30 then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, '', 1, '650;', '1  ;');
        elsif    (pLineNumber = 40)
              or (pLineNumber = 100) then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, '', 1, '640;650;', '1  ;-1 ;');
        elsif pLineNumber = 50 then
          vSQLText  := vVoidSQLText;
        elsif pLineNumber = 60 then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, '', 0, '660;', '-1  ;');
        elsif pLineNumber = 70 then
          vSQLText  := vVoidSQLText;
        elsif pLineNumber = 80 then
          vSQLText  := vVoidSQLText;
        elsif pLineNumber = 90 then
          vDebRefField  := 'SCM_AMOUNT_DIFF_LC_D';
          vCreRefField  := 'SCM_AMOUNT_DIFF_LC_C';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_1_ID in (''3'', ''4'')';
        elsif pLineNumber = 100 then
          vSQLText  := vVoidSQLText;
        elsif pLineNumber = 110 then
          vSQLText  := '';
          DefineSumLines(10, pReportType, pLineNumber, '', 0, '90 ;100;', '1  ;1  ;');
        elsif pLineNumber = 120 then
          vSQLText  := vVoidSQLText;
        elsif pLineNumber = 130 then
          vDebRefField  := 'SCM_AMOUNT_ALL_LC_D';
          vCreRefField  := 'SCM_AMOUNT_ALL_LC_C';
          vFinAccCode   := ' and FIN.DIC_FIN_ACC_CODE_4_ID in (''1390'', ''2390'')';
        elsif pLineNumber = 140 then
          vSQLText  := vVoidSQLText;
        elsif pLineNumber = 150 then
          vSQLText  := vVoidSQLText;
        elsif pLineNumber = 200 then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, 'Degré autofinancement', 1, '110;', '1  ;');
        elsif pLineNumber = 210 then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, 'Quotité autofinancement', 1, '180;', '1  ;');
        elsif pLineNumber = 220 then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, 'Quotité de la charge des intérêts', 1, '290;', '1  ;');
        elsif pLineNumber = 230 then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, 'Quotité de la charge financière', 1, '460;', '1  ;');
        elsif pLineNumber = 240 then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, 'Dette brute par rapport aux revenus', 1, '520;', '1  ;');
        elsif pLineNumber = 250 then
          vSQLText  := '';
          DefineSumLines(0, pReportType, pLineNumber, 'Quotité d''investissement', 1, '630;', '1  ;');
        else
          vSQLText  := '';
        end if;
      end if;

      if length(vSQLText) > 0 then
        --Remplacement des macros par leurs valeurs respectives
        vSQLText  := replace(vSQLText, '[ACB_SCENARIO_ID]', pScenarioId);
        vSQLText  := replace(vSQLText, '[SCR_REPORT]', pReportType);
        vSQLText  := replace(vSQLText, '[LINENUMBER]', pLineNumber);
        vSQLText  := replace(vSQLText, '[DEBREFFIELD]', vDebRefField);
        vSQLText  := replace(vSQLText, '[CREREFFIELD]', vCreRefField);
        vSQLText  := replace(vSQLText, '[FIN_ACC_CODE]', vFinAccCode);

        --Exécution de la commande et insertion dans la table
        begin
          execute immediate vSQLText
          bulk collect into vReportPosition;   --Ouverture des curseurs des comptes CPN

          if vReportPosition.count > 0 then
            for vCounter in vReportPosition.first .. vReportPosition.last loop
              insert into ACB_SCE_REPORT
                          (ACB_SCE_REPORT_ID
                         , ACB_SCENARIO_ID
                         , SCR_REPORT
                         , SCR_LINE
                         , SCR_DESCRIPTION
                         , SCR_AMOUNT_LC_1
                         , SCR_AMOUNT_LC_2
                         , SCR_AMOUNT_LC_3
                         , SCR_AMOUNT_LC_4
                         , SCR_AMOUNT_LC_5
                         , SCR_AMOUNT_LC_6
                         , SCR_AMOUNT_LC_7
                         , A_DATECRE
                         , A_IDCRE
                          )
                   values (init_id_seq.nextval
                         , pScenarioId
                         , pReportType
                         , pLineNumber
                         , vReportDescr
                         , vReportPosition(vCounter).SCR_AMOUNT_LC_1
                         , vReportPosition(vCounter).SCR_AMOUNT_LC_2
                         , vReportPosition(vCounter).SCR_AMOUNT_LC_3
                         , vReportPosition(vCounter).SCR_AMOUNT_LC_4
                         , vReportPosition(vCounter).SCR_AMOUNT_LC_5
                         , vReportPosition(vCounter).SCR_AMOUNT_LC_6
                         , vReportPosition(vCounter).SCR_AMOUNT_LC_7
                         , sysdate
                         , PCS.PC_I_LIB_SESSION.GetUserIni
                          );
            end loop;
          else
            insert into ACB_SCE_REPORT
                        (ACB_SCE_REPORT_ID
                       , ACB_SCENARIO_ID
                       , SCR_REPORT
                       , SCR_LINE
                       , SCR_DESCRIPTION
                       , SCR_AMOUNT_LC_1
                       , SCR_AMOUNT_LC_2
                       , SCR_AMOUNT_LC_3
                       , SCR_AMOUNT_LC_4
                       , SCR_AMOUNT_LC_5
                       , SCR_AMOUNT_LC_6
                       , SCR_AMOUNT_LC_7
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , pScenarioId
                       , pReportType
                       , pLineNumber
                       , vReportDescr
                       , 0
                       , 0
                       , 0
                       , 0
                       , 0
                       , 0
                       , 0
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          end if;
        exception
          when others then
            raise_application_error(-20001
                                  , chr(13) ||
                                    PCS.PC_FUNCTIONS.TRANSLATEWORD('NO_VALID_SQL') ||
                                    chr(13) ||
                                    pLineNumber ||
                                    chr(13) ||
                                    vSQLText ||
                                    chr(13)
                                   );
        end;
      end if;
    end DefineLine;
  begin
    --Suppression données existantes pour le scenario courant
    delete from ACB_SCE_REPORT
          where ACB_SCENARIO_ID = pScenarioId;

    --Positions techniques
    vCounter  := 0;

    while vCounter < 700 loop
      DefineLine(0, vCounter);
      vCounter  := vCounter + 10;
    end loop;

    vCounter  := 0;

    while vCounter < 300 loop
      DefineLine(10, vCounter);
      vCounter  := vCounter + 10;
    end loop;
  end CreateReportPosition;
end ACB_PLANING;
