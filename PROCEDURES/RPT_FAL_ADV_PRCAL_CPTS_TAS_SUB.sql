--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ADV_PRCAL_CPTS_TAS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ADV_PRCAL_CPTS_TAS_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procparam_0      IN       fal_adv_calc_options.cao_session_id%TYPE,
   procparam_1      IN       fal_adv_calc_options.fal_adv_calc_options_id%TYPE,
   procparam_2      IN       fal_adv_calc_good.gco_good_id%TYPE,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
 /**
* Description Used for report FAL_ADV_PRECALCULATION
*   Proc：|dure stock：|e utilis：|e pour le rapport de pr：|-calculation avanc：|e
*   Retourne la liste des composants (et leurs d：|tails) li：|s au produit
*   calcul：|, ainsi que les op：|rations qui y sont li：|es (et leurs d：|tails).
* @Author MZHU 20 Mar. 2009
* @Lastupdate PYB 1 Sep. 2010
* @Version
* @Public
* @Param procparam_0: Session Id
* @Param procparam_1: Option Id
* @Param procparam_2: Good Id
*/
BEGIN
   OPEN arefcursor FOR
      SELECT   cag.goo_major_reference, cag.cag_level, cag.cag_nom_coef,
               cag.cag_quantity, cag.cag_mat_total, cag.cag_mat_section,
               cag.cag_mat_amount, cag.cag_mat_rate, cag.cag_mat_rate_amount,
               cak.cak_task_seq, cak.cak_task_ref, cak.cak_task_descr,
               cak.cak_time_section, cak.cak_adjusting_time,
               cak.cak_work_time, cak.cak_machine_cost, cak.cak_human_cost,
               gco_functions.getdescription
                                      (cag.gco_cpt_good_id,
                                       procuser_lanid,
                                       1,
                                       '01'
                                      ) goo_short_description
          FROM fal_adv_calc_good cag,
               fal_adv_calc_options cao,
               gco_good goo,
               fal_adv_calc_task cak
         WHERE cag.cag_session_id = procparam_0
           AND cag.fal_adv_calc_options_id = procparam_1
           AND cag.gco_good_id = procparam_2
           AND cao.fal_adv_calc_options_id = cag.fal_adv_calc_options_id
           AND goo.gco_good_id = cag.gco_cpt_good_id
           AND cak.cak_session_id(+) = procparam_0
           AND cak.fal_adv_calc_good_id(+) = cag.fal_adv_calc_good_id
      ORDER BY cag.fal_adv_calc_good_id,
               cak.cak_task_seq,
               cak.fal_adv_calc_task_id;
END rpt_fal_adv_prcal_cpts_tas_sub;
