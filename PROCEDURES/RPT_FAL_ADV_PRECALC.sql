--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ADV_PRECALC
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ADV_PRECALC" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procparam_0      IN       fal_adv_calc_options.cao_session_id%TYPE,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
 * Description Used for report FAL_ADV_PRECALCULATION
 *   Proc：|dure stock：|e utilis：|e pour le rapport de pr：|-calculation avanc：|e
 *   Retourne la liste des valeurs du r：|sultat dans l'ordre de l'arborescence
 *   de la structure de calcul.
 * @Created In Proconcept China
 * @Author MZHU 20 Mar. 2009
 * @Lastupdate AWU 31 Aug. 2009
 * @Version
 * @Public
 * @Param Parameter_0: Session Id
 * @Param Procuser_Lanid: User Language
 */
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);

   OPEN arefcursor FOR
      SELECT   goo.goo_major_reference,
               gco_functions.getdescription
                                      (goo.gco_good_id,
                                       procuser_lanid,
                                       2,
                                       '01'
                                      ) gco_short_description,
               cao.cao_calculation_structure, vals.*, rubr.*,
               ars.dic_fal_rate_descr_id, ars.c_basis_rubric,
               ars.c_rubric_type,
               com_functions.getdescodedescr
                     ('C_BASIS_RUBRIC',
                      ars.c_basis_rubric,
                      pcs.PC_I_LIB_SESSION.user_lang_id
                     ) c_basis_rubric_wording,
               com_functions.getdescodedescr
                      ('C_RUBRIC_TYPE',
                       ars.c_rubric_type,
                       pcs.PC_I_LIB_SESSION.user_lang_id
                      ) c_rubric_type_wording
          FROM fal_adv_calc_options cao,
               (SELECT cag.fal_adv_calc_options_id, cag.gco_good_id,
                       cag.gco_cpt_good_id,
                       NVL (cag.gco_cpt_good_id,
                            cag.gco_good_id
                           ) gco_descr_good_id,
                       cav.cav_rubric_seq, cav.cav_value, cav.cav_unit_price,
                       cav.cav_std_unit_price
                  FROM fal_adv_calc_good cag, fal_adv_calc_struct_val cav
                 WHERE cag.cag_session_id = procparam_0
                   AND cav.cav_session_id = procparam_0
                   AND cav.fal_adv_calc_good_id = cag.fal_adv_calc_good_id
                   AND cag.gco_cpt_good_id IS NULL) vals,
               fal_adv_rate_struct ars,
               TABLE
                    (fal_adv_calc_print.fal_adv_calc_struct_table (procparam_0)
                    ) rubr,
               gco_good goo,
               fal_lot lot
         WHERE cao.cao_session_id = procparam_0
           AND ars.fal_adv_struct_calc_id = cao.fal_adv_struct_calc_id
           AND ars.fal_adv_rate_struct_id = rubr.fal_adv_rate_struct_id
           AND vals.cav_rubric_seq = ars.ars_sequence
           AND vals.fal_adv_calc_options_id = cao.fal_adv_calc_options_id
           AND goo.gco_good_id = vals.gco_descr_good_id
           AND lot.fal_lot_id(+) = cao.fal_lot_id
      ORDER BY goo.goo_major_reference,
               cao.fal_adv_calc_options_id,
               vals.gco_good_id,
               rubr.ars_order;
END rpt_fal_adv_precalc;
