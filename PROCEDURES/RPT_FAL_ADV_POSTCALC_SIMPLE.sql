--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ADV_POSTCALC_SIMPLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ADV_POSTCALC_SIMPLE" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, procparam_0    in     fal_adv_calc_options.cao_session_id%type
, procuser_lanid in     pcs.pc_lang.lanid%type
)
is
/**
* Description - Used in report FAL_ADV_SIMPLE_POSTCALCULATION
* Stored procedure used for the advanced post calculation report.
* @Author VHA 22 Aug. 2012
* @lastupdate
* @param aRefCursor     : Curseur pour le rapport Crystal
* @param PROCPARAM_0    : Session Oracle
* @param PROCUSER_LANID : Langue utilisateur pour initialisation de la session
*/
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);

  open arefcursor for
    select   goo.goo_major_reference
           , gco_functions.getdescription(goo.gco_good_id, procuser_lanid, 2, '01') goo_description
           , goo_cpt.goo_major_reference goo_cpt_major_reference
           , gco_functions.getdescription(goo_cpt.gco_good_id, procuser_lanid, 1, '01') goo_cpt_description
           , cao.cao_calculation_structure
           , cav.cav_rubric_seq
           , cav.cav_unit_price
           , cav.cav_std_unit_price
           , vals.cav_unit_price cav_unit_price_tot
           , vals.cav_std_unit_price cav_std_unit_price_tot
           , case
               when rubr_cag.cag_level = 0 then cav.cav_value
               else nvl(cav.cav_value, 0)
             end cav_value
           , ars.dic_fal_rate_descr_id
           , rubr_cag.*
           , (select count(fal_adv_calc_task_id)
                from fal_adv_calc_task cak
                   , fal_adv_calc_good cag
               where cak.cak_session_id = procparam_0
                 and cag.cag_session_id = procparam_0
                 and cak.fal_adv_calc_good_id = cag.fal_adv_calc_good_id
                 and cag.gco_good_id = rubr_cag.gco_good_id
                 and cag.gco_cpt_good_id = rubr_cag.gco_good_id) task_count
           , zvl(case
                   when rubr_cag.cag_level = 0 then (select sum(sub_caw.caw_work_amount)
                                                       from fal_adv_calc_work sub_caw
                                                      where sub_caw.fal_adv_calc_good_id = rubr_cag.fal_adv_calc_good_id
                                                        and sub_caw.caw_decomposition_level = 0)
                   else nvl( (select sum(sub_caw.caw_work_amount)
                                from fal_adv_calc_work sub_caw
                               where sub_caw.fal_adv_calc_good_id = rubr_cag.fal_adv_calc_good_id
                                 and sub_caw.caw_decomposition_level = 0), 0)
                 end
               , null
                ) caw_work_amount
        from fal_adv_calc_options cao
           , fal_adv_rate_struct ars
           , (select   ars.fal_adv_rate_struct_id
                     , ars.fal_adv_struct_calc_id
                     , ars.ars_sequence
                     , cag.fal_adv_calc_options_id
                     , cag.fal_adv_calc_good_id
                     , cag.gco_good_id
                     , cag.gco_cpt_good_id
                     , nvl(cag.gco_cpt_good_id, cag.gco_good_id) gco_descr_good_id
                     , cag.cag_level
                     , cag.cag_nom_coef
                     , cag.cag_quantity
                     , case
                         when cag.cag_level = 0 then cag.cag_mat_amount
                         else nvl(cag.cag_mat_amount, 0)
                       end cag_mat_amount
                  from fal_adv_rate_struct ars
                     , fal_adv_calc_good cag
                 where ars.ars_visible_level = 1
                   and ars.fal_adv_struct_calc_id in(select fal_adv_struct_calc_id
                                                       from fal_adv_calc_options
                                                      where cao_session_id = procparam_0)
                   and (   ars.fal_adv_rate_struct_id not in(select distinct fal_fal_adv_rate_struct_id
                                                                        from fal_adv_total_rate)
                        or ars.ars_prf_level = 1)
                   and cag.cag_session_id = procparam_0
              order by ars.fal_adv_struct_calc_id
                     , ars.ars_sequence) rubr_cag
           , fal_adv_calc_struct_val cav
           , (select cag.fal_adv_calc_options_id
                   , cag.gco_good_id
                   , cag.gco_cpt_good_id
                   , nvl(cag.gco_cpt_good_id, cag.gco_good_id) gco_descr_good_id
                   , cav.cav_rubric_seq
                   , cav.cav_unit_price
                   , cav.cav_std_unit_price
                from fal_adv_calc_good cag
                   , fal_adv_calc_struct_val cav
               where cag.cag_session_id = procparam_0
                 and cav.cav_session_id = procparam_0
                 and cav.fal_adv_calc_good_id = cag.fal_adv_calc_good_id
                 and cag.gco_cpt_good_id is null) vals
           , gco_good goo
           , gco_good goo_cpt
           , fal_lot lot
       where cao.cao_session_id = procparam_0
         and cav.cav_session_id(+) = procparam_0
         and ars.fal_adv_struct_calc_id = cao.fal_adv_struct_calc_id
         and ars.fal_adv_rate_struct_id = rubr_cag.fal_adv_rate_struct_id
         and rubr_cag.fal_adv_calc_options_id = cao.fal_adv_calc_options_id
         and rubr_cag.gco_cpt_good_id is not null
         and goo.gco_good_id = rubr_cag.gco_good_id
         and goo_cpt.gco_good_id = rubr_cag.gco_descr_good_id
         and lot.fal_lot_id(+) = cao.fal_lot_id
         and cav.fal_adv_calc_good_id(+) = rubr_cag.fal_adv_calc_good_id
         and cav.cav_rubric_seq(+) = rubr_cag.ars_sequence
         and vals.cav_rubric_seq = ars.ars_sequence
         and vals.fal_adv_calc_options_id = cao.fal_adv_calc_options_id
         and goo.gco_good_id = vals.gco_descr_good_id
    order by goo.goo_major_reference
           , cao.fal_adv_calc_options_id
           , ars.ars_sequence desc
           , rubr_cag.fal_adv_calc_good_id
           , rubr_cag.gco_good_id;
end RPT_FAL_ADV_POSTCALC_SIMPLE;
