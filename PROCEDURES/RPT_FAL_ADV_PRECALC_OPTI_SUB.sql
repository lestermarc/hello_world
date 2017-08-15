--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ADV_PRECALC_OPTI_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ADV_PRECALC_OPTI_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   procparam_0   IN       fal_adv_calc_options.cao_session_id%TYPE
)
IS
 /**
* Description - Used in report FAL_ADV_SIMPLE_PRECALCULATION, FAL_ADV_PRECALCULATION
*   Proc：|dure stock：|e utilis：|e pour le rapport de pr：|-calculation avanc：|e
*   Retourne la valeur des options utilis：|es pour la calculation et
*   communes ：∴ tous les produits.
* @author JCH 31.01.2008
* @last update 20 Mar. 2009
* @param aRefCursor  : Curseur pour le rapport Crystal
* @param PROCPARAM_0 : Session Oracle
*/
BEGIN
   fal_adv_calc_print.adv_calc_options_rpt_pk (arefcursor      => arefcursor,
                                               asessionid      => procparam_0
                                              );
END rpt_fal_adv_precalc_opti_sub;
