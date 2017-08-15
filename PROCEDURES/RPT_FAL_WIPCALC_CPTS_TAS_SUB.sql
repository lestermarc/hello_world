--------------------------------------------------------
--  DDL for Procedure RPT_FAL_WIPCALC_CPTS_TAS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_WIPCALC_CPTS_TAS_SUB" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, procparam_0    in     fal_adv_calc_options.cao_session_id%type
, procparam_1    in     fal_adv_calc_options.fal_adv_calc_options_id%type
, procparam_2    in     fal_adv_calc_good.gco_good_id%type
, procuser_lanid in     pcs.pc_lang.lanid%type
)
is
 /**
* Description Used for report FAL_WORKINPROGRESS_CALCULATION
* Stored procedure used for the advanced Calculate WIP report
* @Author VHA 22 Aug. 2012
* @Lastupdate
* @Version
* @Public
* @Param procparam_0: Session Id
* @Param procparam_1: Option Id
* @Param procparam_2: Good Id
*/
begin
  open arefcursor for
    select   cag.goo_major_reference
           , cag.cag_level
           , cag.cag_nom_coef
           , cag.cag_quantity
           , cag.cag_mat_total
           , cag.cag_mat_section
           , cag.cag_mat_amount
           , cag.cag_mat_rate
           , cag.cag_mat_rate_amount
           , cak.cak_task_seq
           , cak.cak_task_ref
           , cak.cak_task_descr
           , cak.cak_time_section
           , cak.cak_adjusting_time
           , cak.cak_work_time
           , cak.cak_machine_cost
           , cak.cak_human_cost
           , gco_functions.getdescription(cag.gco_cpt_good_id, procuser_lanid, 1, '01') goo_short_description
        from fal_adv_calc_good cag
           , fal_adv_calc_options cao
           , gco_good goo
           , fal_adv_calc_task cak
       where cag.cag_session_id = procparam_0
         and cag.fal_adv_calc_options_id = procparam_1
         and cag.gco_good_id = procparam_2
         and cao.fal_adv_calc_options_id = cag.fal_adv_calc_options_id
         and goo.gco_good_id = cag.gco_cpt_good_id
         and cak.cak_session_id(+) = procparam_0
         and cak.fal_adv_calc_good_id(+) = cag.fal_adv_calc_good_id
    order by cag.fal_adv_calc_good_id
           , cak.cak_task_seq
           , cak.fal_adv_calc_task_id;
end RPT_FAL_WIPCALC_CPTS_TAS_SUB;
