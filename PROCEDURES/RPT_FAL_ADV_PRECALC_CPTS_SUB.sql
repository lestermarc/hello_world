--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ADV_PRECALC_CPTS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ADV_PRECALC_CPTS_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   procparam_0   IN       fal_adv_calc_options.cao_session_id%TYPE,
   procparam_1   IN       fal_adv_calc_options.fal_adv_calc_options_id%TYPE,
   procparam_2   IN       fal_adv_calc_good.gco_good_id%TYPE
)
IS
/**
* Description Used for report FAL_ADV_PRECALCULATION
*   Proc：|dure stock：|e utilis：|e pour le rapport de pr：|-calculation avanc：|e
*   Retourne la liste des composants (et leurs d：|tails) li：|s au produit
*   calcul：|.
* @Author MZHU 20 Mar. 2009
* @Lastupdate
* @Version
* @Public
* @Param Parameter_0: Session Id
* @Param Parameter_1: Option Id
* @Param Parameter_2: Good Id
*/
BEGIN
   fal_adv_calc_print.adv_calc_cpts_rpt_pk (arefcursor       => arefcursor,
                                            asessionid       => procparam_0,
                                            aoptionsid       => procparam_1,
                                            acalcgoodid      => procparam_2
                                           );
END rpt_fal_adv_precalc_cpts_sub;
