--------------------------------------------------------
--  DDL for Package Body FAL_ADV_PRECALC_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ADV_PRECALC_RPT" 
is
  /**
   * procedure ADV_PRECALC_RPT_PK
   * Description
   *   Proc�dure stock�e utilis�e pour le rapport de pr�-calculation avanc�e
   *   Retourne la liste des valeurs du r�sultat dans l'ordre de l'arborescence
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
   *   Proc�dure stock�e utilis�e pour le rapport de pr�-calculation avanc�e
   *   Retourne la valeur des options utilis�es pour la calculation et
   *   communes � tous les produits.
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
   *   Proc�dure stock�e utilis�e pour le rapport de pr�-calculation avanc�e
   *   Retourne la liste des composants (et leurs d�tails) li�s au produit
   *   calcul�.
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
   *   Proc�dure stock�e utilis�e pour le rapport de pr�-calculation avanc�e
   *   Retourne la liste des composants (et leurs d�tails) li�s au produit
   *   calcul�, ainsi que les op�rations qui y sont li�es (et leurs d�tails).
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
   *   Proc�dure stock�e utilis�e pour les rapports de pr�-calculation avanc�e
   *   Retourne la d�composition du travail li�e au produit calcul� si PROCPARAM_3
   *   n'est pas d�fini, ou au composant sp�cifi� par PROCPARAM_3.
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
   *   Proc�dure stock�e utilis�e pour le rapport de pr�-calculation avanc�e
   *   Retourne la d�composition de la sous-traitance li�e au produit calcul� si
   *   PROCPARAM_3 n'est pas d�fini, ou au composant sp�cifi� par PROCPARAM_3.
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
   *   Proc�dure stock�e utilis�e pour les rapports de pr�-calculation avanc�e
   *   Retourne la liste des op�rations (et leurs d�tails) li�es au produit
   *   calcul� si PROCPARAM_3 n'est pas d�fini, ou au composant sp�cifi� par
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
   *   Proc�dure stock�e utilis�e pour les rapports de pr�-calculation avanc�e
   *   Retourne la liste des op�rations (et leurs d�tails : co�ts, dur�e) li�es
   *   au produit calcul�.
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
   *   Proc�dure stock�e utilis�e pour les rapports simples (d�composition par
   *   composant du premier niveau) de pr�-calculation avanc�e.
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
