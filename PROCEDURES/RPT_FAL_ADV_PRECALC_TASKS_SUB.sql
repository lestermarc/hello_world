--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ADV_PRECALC_TASKS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ADV_PRECALC_TASKS_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   procparam_0   IN       fal_adv_calc_options.cao_session_id%TYPE,
   procparam_1   IN       fal_adv_calc_options.fal_adv_calc_options_id%TYPE,
   procparam_2   IN       fal_adv_calc_good.gco_good_id%TYPE,
   procparam_3   IN       fal_adv_calc_good.gco_cpt_good_id%TYPE DEFAULT NULL
)
IS
/**
* Description - Used in report FAL_ADV_SIMPLE_PRECALCULATION, FAL_ADV_PRECALCULATION

* Proc：|dure stock：|e utilis：|e pour les rapports de pr：|-calculation avanc：|e
* Retourne la liste des op：|rations (et leurs d：|tails) li：|es au produit
* calcul：| si PROCPARAM_3 n'est pas d：|fini, ou au composant sp：|cifi：| par
* PROCPARAM_3.
* @author JCH 31 JAN 2008
* @lastupdate 25 Feb 2009
* @param aRefCursor  : Curseur pour le rapport Crystal
* @param PROCPARAM_0 : Session Oracle
* @param PROCPARAM_1 : Identifiant des options
* @param PROCPARAM_2 : Produit calcul：|
* @param PROCPARAM_3 : Composant
*/
BEGIN

   fal_adv_calc_print.adv_calc_tasks_rpt_pk (arefcursor       => arefcursor,
                                             asessionid       => procparam_0,
                                             aoptionsid       => procparam_1,
                                             acalcgoodid      => procparam_2,
                                             acptgoodid       => procparam_3
                                            );


END rpt_fal_adv_precalc_tasks_sub;
