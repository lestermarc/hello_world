--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ADV_PRECALC_SIMPLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ADV_PRECALC_SIMPLE" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procparam_0      IN       fal_adv_calc_options.cao_session_id%TYPE,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
* Description - Used in report FAL_ADV_SIMPLE_PRECALCULATION

* Procédure stockée utilisée pour les rapports simples (décomposition par
* composant du premier niveau) de pré-calculation avancée.
* @author JCH 31 JAN 2008
* @lastupdate VHA 27 Feb 2012
* @param aRefCursor     : Curseur pour le rapport Crystal
* @param PROCPARAM_0    : Session Oracle
* @param PROCUSER_LANID : Langue utilisateur pour initialisation de la session
*/
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);

   OPEN arefcursor FOR
      SELECT   goo.goo_major_reference,
               gco_functions.getdescription (goo.gco_good_id,
                                             procuser_lanid,
                                             2,
                                             '01'
                                            ) goo_description,
               goo_cpt.goo_major_reference goo_cpt_major_reference,
               gco_functions.getdescription
                                    (goo_cpt.gco_good_id,
                                     procuser_lanid,
                                     1,
                                     '01'
                                    ) goo_cpt_description,
               cao.cao_calculation_structure, cav.cav_rubric_seq,
               CASE
                  WHEN rubr_cag.cag_level = 0
                     THEN cav.cav_value
                  ELSE   NVL (cav.cav_value, 0)
               END cav_value,
               ars.dic_fal_rate_descr_id, rubr_cag.*,
               (SELECT COUNT (fal_adv_calc_task_id)
                  FROM fal_adv_calc_task cak,
                       fal_adv_calc_good cag
                 WHERE cak.cak_session_id = procparam_0
                   AND cag.cag_session_id = procparam_0
                   AND cak.fal_adv_calc_good_id = cag.fal_adv_calc_good_id
                   AND cag.gco_good_id = rubr_cag.gco_good_id
                   AND cag.gco_cpt_good_id = rubr_cag.gco_good_id)
                                                                  task_count,
               zvl
                  (CASE
                      WHEN rubr_cag.cag_level = 0
                         THEN (SELECT SUM (sub_caw.caw_work_amount)
                                 FROM fal_adv_calc_work sub_caw
                                WHERE sub_caw.fal_adv_calc_good_id =
                                                 rubr_cag.fal_adv_calc_good_id
                                  AND sub_caw.caw_decomposition_level = 0)
                      ELSE   NVL ((SELECT SUM (sub_caw.caw_work_amount)
                                     FROM fal_adv_calc_work sub_caw
                                    WHERE sub_caw.fal_adv_calc_good_id =
                                                 rubr_cag.fal_adv_calc_good_id
                                      AND sub_caw.caw_decomposition_level = 0),
                                  0
                                 )
                   END,
                   NULL
                  ) caw_work_amount
          FROM fal_adv_calc_options cao,
               fal_adv_rate_struct ars,
               (SELECT   ars.fal_adv_rate_struct_id,
                         ars.fal_adv_struct_calc_id, ars.ars_sequence,
                         cag.fal_adv_calc_options_id,
                         cag.fal_adv_calc_good_id, cag.gco_good_id,
                         cag.gco_cpt_good_id,
                         NVL (cag.gco_cpt_good_id,
                              cag.gco_good_id
                             ) gco_descr_good_id,
                         cag.cag_level, cag.cag_nom_coef, cag.cag_quantity,
                         CASE
                            WHEN cag.cag_level = 0
                               THEN cag.cag_mat_amount
                            ELSE   NVL (cag.cag_mat_amount, 0)
                         END cag_mat_amount
                FROM     fal_adv_rate_struct ars, fal_adv_calc_good cag
                   WHERE ars.ars_visible_level = 1
                     AND ars.fal_adv_struct_calc_id IN (
                                            SELECT fal_adv_struct_calc_id
                                              FROM fal_adv_calc_options
                                             WHERE cao_session_id =
                                                                   procparam_0)
                     AND (   ars.fal_adv_rate_struct_id NOT IN (
                                    SELECT DISTINCT fal_fal_adv_rate_struct_id
                                               FROM fal_adv_total_rate)
                          OR ars.ars_prf_level = 1
                         )
                     AND cag.cag_session_id = procparam_0
                ORDER BY ars.fal_adv_struct_calc_id, ars.ars_sequence) rubr_cag,
               fal_adv_calc_struct_val cav,
               gco_good goo,
               gco_good goo_cpt,
               fal_lot lot
         WHERE cao.cao_session_id = procparam_0
           AND cav.cav_session_id(+) = procparam_0
           AND ars.fal_adv_struct_calc_id = cao.fal_adv_struct_calc_id
           AND ars.fal_adv_rate_struct_id = rubr_cag.fal_adv_rate_struct_id
           AND rubr_cag.fal_adv_calc_options_id = cao.fal_adv_calc_options_id
           AND rubr_cag.gco_cpt_good_id IS NOT NULL
           AND goo.gco_good_id = rubr_cag.gco_good_id
           AND goo_cpt.gco_good_id = rubr_cag.gco_descr_good_id
           AND lot.fal_lot_id(+) = cao.fal_lot_id
           AND cav.fal_adv_calc_good_id(+) = rubr_cag.fal_adv_calc_good_id
           AND cav.cav_rubric_seq(+) = rubr_cag.ars_sequence
      ORDER BY goo.goo_major_reference,
               cao.fal_adv_calc_options_id,
               ars.ars_sequence DESC,
               rubr_cag.fal_adv_calc_good_id,
               rubr_cag.gco_good_id;
END rpt_fal_adv_precalc_simple;
