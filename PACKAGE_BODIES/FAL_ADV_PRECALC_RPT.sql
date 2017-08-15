--------------------------------------------------------
--  DDL for Package Body FAL_ADV_PRECALC_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ADV_PRECALC_RPT" 
is
  /**
   * procedure ADV_PRECALC_RPT_PK
   * Description
   *   Procédure stockée utilisée pour le rapport de pré-calculation avancée
   *   Retourne la liste des valeurs du résultat dans l'ordre de l'arborescence
   *   de la structure de calcul.
   */
  procedure ADV_PRECALC_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0    in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
  begin
    FAL_ADV_CALC_PRINT.ADV_CALC_RPT_PK(aRefCursor   => aRefCursor
                                     , aSessionId   => PROCPARAM_0
                                     , aUserLanId   => PROCUSER_LANID
                                      );
  end ADV_PRECALC_RPT_PK;

  /**
   * procedure ADV_PRECALC_OPTIONS_RPT_PK
   * Description
   *   Procédure stockée utilisée pour le rapport de pré-calculation avancée
   *   Retourne la valeur des options utilisées pour la calculation et
   *   communes à tous les produits.
   * @author JCH 31.01.2008
   * @param aRefCursor  : Curseur pour le rapport Crystal
   * @param PROCPARAM_0 : Session Oracle
   */
  procedure ADV_PRECALC_OPTIONS_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0 in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  )
  is
  begin
    FAL_ADV_CALC_PRINT.ADV_CALC_OPTIONS_RPT_PK(aRefCursor => aRefCursor, aSessionId => PROCPARAM_0);
  end ADV_PRECALC_OPTIONS_RPT_PK;

  /**
   * procedure ADV_PRECALC_CPTS_RPT_PK
   * Description
   *   Procédure stockée utilisée pour le rapport de pré-calculation avancée
   *   Retourne la liste des composants (et leurs détails) liés au produit
   *   calculé.
   */
  procedure ADV_PRECALC_CPTS_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0 in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , PROCPARAM_1 in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , PROCPARAM_2 in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  )
  is
  begin
    FAL_ADV_CALC_PRINT.ADV_CALC_CPTS_RPT_PK(aRefCursor    => aRefCursor
                                          , aSessionId    => PROCPARAM_0
                                          , aOptionsId    => PROCPARAM_1
                                          , aCalcGoodId   => PROCPARAM_2
                                           );
  end ADV_PRECALC_CPTS_RPT_PK;

  /**
   * procedure ADV_PRECALC_CPTS_TASKS_RPT_PK
   * Description
   *   Procédure stockée utilisée pour le rapport de pré-calculation avancée
   *   Retourne la liste des composants (et leurs détails) liés au produit
   *   calculé, ainsi que les opérations qui y sont liées (et leurs détails).
   */
  procedure ADV_PRECALC_CPTS_TASKS_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0 in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , PROCPARAM_1 in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , PROCPARAM_2 in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  )
  is
  begin
    FAL_ADV_CALC_PRINT.ADV_CALC_CPTS_TASKS_RPT_PK(aRefCursor    => aRefCursor
                                                , aSessionId    => PROCPARAM_0
                                                , aOptionsId    => PROCPARAM_1
                                                , aCalcGoodId   => PROCPARAM_2
                                                 );
  end ADV_PRECALC_CPTS_TASKS_RPT_PK;

  /**
   * procedure ADV_PRECALC_WORK_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports de pré-calculation avancée
   *   Retourne la décomposition du travail liée au produit calculé si PROCPARAM_3
   *   n'est pas défini, ou au composant spécifié par PROCPARAM_3.
   */
  procedure ADV_PRECALC_WORK_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0 in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , PROCPARAM_1 in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , PROCPARAM_2 in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  , PROCPARAM_3 in     FAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID%type default null
  , PROCPARAM_4 in     FAL_ADV_CALC_WORK.C_BASIS_RUBRIC%type
  )
  is
  begin
    FAL_ADV_CALC_PRINT.ADV_CALC_WORK_RPT_PK(aRefCursor     => aRefCursor
                                          , aSessionId     => PROCPARAM_0
                                          , aOptionsId     => PROCPARAM_1
                                          , aCalcGoodId    => PROCPARAM_2
                                          , aCptGoodId     => PROCPARAM_3
                                          , aBasisRubric   => PROCPARAM_4
                                           );
  end ADV_PRECALC_WORK_RPT_PK;

  /**
   * procedure ADV_PRECALC_SUBCT_RPT_PK
   * Description
   *   Procédure stockée utilisée pour le rapport de pré-calculation avancée
   *   Retourne la décomposition de la sous-traitance liée au produit calculé si
   *   PROCPARAM_3 n'est pas défini, ou au composant spécifié par PROCPARAM_3.
   */
  procedure ADV_PRECALC_SUBCT_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0 in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , PROCPARAM_1 in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , PROCPARAM_2 in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  , PROCPARAM_3 in     FAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID%type default null
  )
  is
  begin
    FAL_ADV_CALC_PRINT.ADV_CALC_WORK_RPT_PK(aRefCursor     => aRefCursor
                                          , aSessionId     => PROCPARAM_0
                                          , aOptionsId     => PROCPARAM_1
                                          , aCalcGoodId    => PROCPARAM_2
                                          , aCptGoodId     => PROCPARAM_3
                                          , aBasisRubric   => FAL_ADV_CALC_PRINT.cSubContractBasisRubric
                                           );
  end ADV_PRECALC_SUBCT_RPT_PK;

  /**
   * procedure TASKS_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports de pré-calculation avancée
   *   Retourne la liste des opérations (et leurs détails) liées au produit
   *   calculé si PROCPARAM_3 n'est pas défini, ou au composant spécifié par
   *   PROCPARAM_3.
   */
  procedure ADV_PRECALC_TASKS_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0 in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , PROCPARAM_1 in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , PROCPARAM_2 in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  , PROCPARAM_3 in     FAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID%type default null
  )
  is
  begin
    FAL_ADV_CALC_PRINT.ADV_CALC_TASKS_RPT_PK(aRefCursor    => aRefCursor
                                           , aSessionId    => PROCPARAM_0
                                           , aOptionsId    => PROCPARAM_1
                                           , aCalcGoodId   => PROCPARAM_2
                                           , aCptGoodId    => PROCPARAM_3
                                            );
  end ADV_PRECALC_TASKS_RPT_PK;

  /**
   * procedure ADV_PRECALC_PROD_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports de pré-calculation avancée
   *   Retourne la liste des opérations (et leurs détails : coûts, durée) liées
   *   au produit calculé.
   */
  procedure ADV_PRECALC_PROD_RPT_PK(
    aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0 in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , PROCPARAM_1 in     FAL_ADV_CALC_OPTIONS.FAL_ADV_CALC_OPTIONS_ID%type
  , PROCPARAM_2 in     FAL_ADV_CALC_GOOD.GCO_GOOD_ID%type
  )
  is
  begin
    FAL_ADV_CALC_PRINT.ADV_CALC_TASKS_RPT_PK(aRefCursor    => aRefCursor
                                           , aSessionId    => PROCPARAM_0
                                           , aOptionsId    => PROCPARAM_1
                                           , aCalcGoodId   => PROCPARAM_2
                                            );
  end ADV_PRECALC_PROD_RPT_PK;

  /**
   * procedure ADV_PRECALC_SIMPLE_RPT_PK
   * Description
   *   Procédure stockée utilisée pour les rapports simples (décomposition par
   *   composant du premier niveau) de pré-calculation avancée.
   * @author JCH 31.01.2008
   */
  procedure ADV_PRECALC_SIMPLE_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0    in     FAL_ADV_CALC_OPTIONS.CAO_SESSION_ID%type
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
  begin
    FAL_ADV_CALC_PRINT.ADV_CALC_SIMPLE_RPT_PK(aRefCursor   => aRefCursor
                                            , aSessionId   => PROCPARAM_0
                                            , aUserLanId   => PROCUSER_LANID
                                             );
  end ADV_PRECALC_SIMPLE_RPT_PK;
end FAL_ADV_PRECALC_RPT;
