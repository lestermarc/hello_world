--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ADV_PRECALC_SUBCT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ADV_PRECALC_SUBCT_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   procparam_0   IN       fal_adv_calc_options.cao_session_id%TYPE,
   procparam_1   IN       fal_adv_calc_options.fal_adv_calc_options_id%TYPE,
   procparam_2   IN       fal_adv_calc_good.gco_good_id%TYPE,
   procparam_3   IN       fal_adv_calc_good.gco_cpt_good_id%TYPE DEFAULT NULL
)
IS
 /**
* Description Used for report FAL_ADV_PRECALCULATION
*   Proc：|dure stock：|e utilis：|e pour le rapport de pr：|-calculation avanc：|e
*   Retourne la d：|composition de la sous-traitance li：|e au produit calcul：| si
*   PROCPARAM_3 n'est pas d：|fini, ou au composant sp：|cifi：| par PROCPARAM_3.
* @Author MZHU 20 Mar. 2009
* @Lastupdate
* @Version
* @Public
* @Param Parameter_0: Session Id
* @Param Parameter_1: Option Id
* @Param Parameter_2: Good Id
* @Param Parameter_4: Cpt Good Id
*/
BEGIN
   fal_adv_calc_print.adv_calc_work_rpt_pk
                  (arefcursor        => arefcursor,
                   asessionid        => procparam_0,
                   aoptionsid        => procparam_1,
                   acalcgoodid       => procparam_2,
                   acptgoodid        => procparam_3,
                   abasisrubric      => fal_adv_calc_print.csubcontractbasisrubric
                  );
END rpt_fal_adv_precalc_subct_sub;
