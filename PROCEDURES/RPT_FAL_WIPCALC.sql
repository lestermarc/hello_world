--------------------------------------------------------
--  DDL for Procedure RPT_FAL_WIPCALC
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_WIPCALC" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, procparam_0    in     fal_adv_calc_options.cao_session_id%type
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
* @Param Parameter_0: Session Id
* @Param Procuser_Lanid: User Language
*/
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);

  open arefcursor for
    select   goo.goo_major_reference
           , gco_functions.getdescription(goo.gco_good_id, procuser_lanid, 2, '01') gco_short_description
           , cao.cao_calculation_structure
           , vals.*
           , rubr.*
           , ars.dic_fal_rate_descr_id
           , ars.c_basis_rubric
           , ars.c_rubric_type
           , com_functions.getdescodedescr('C_BASIS_RUBRIC', ars.c_basis_rubric, pcs.PC_I_LIB_SESSION.user_lang_id) c_basis_rubric_wording
           , com_functions.getdescodedescr('C_RUBRIC_TYPE', ars.c_rubric_type, pcs.PC_I_LIB_SESSION.user_lang_id) c_rubric_type_wording
        from fal_adv_calc_options cao
           , (select cag.fal_adv_calc_options_id
                   , cag.gco_good_id
                   , cag.gco_cpt_good_id
                   , nvl(cag.gco_cpt_good_id, cag.gco_good_id) gco_descr_good_id
                   , cav.cav_rubric_seq
                   , cav.cav_value
                   , cav.cav_unit_price
                   , cav.cav_std_unit_price
                from fal_adv_calc_good cag
                   , fal_adv_calc_struct_val cav
               where cag.cag_session_id = procparam_0
                 and cav.cav_session_id = procparam_0
                 and cav.fal_adv_calc_good_id = cag.fal_adv_calc_good_id
                 and cag.gco_cpt_good_id is null) vals
           , fal_adv_rate_struct ars
           , table(fal_adv_calc_print.fal_adv_calc_struct_table(procparam_0) ) rubr
           , gco_good goo
           , fal_lot lot
       where cao.cao_session_id = procparam_0
         and ars.fal_adv_struct_calc_id = cao.fal_adv_struct_calc_id
         and ars.fal_adv_rate_struct_id = rubr.fal_adv_rate_struct_id
         and vals.cav_rubric_seq = ars.ars_sequence
         and vals.fal_adv_calc_options_id = cao.fal_adv_calc_options_id
         and goo.gco_good_id = vals.gco_descr_good_id
         and lot.fal_lot_id(+) = cao.fal_lot_id
    order by goo.goo_major_reference
           , cao.fal_adv_calc_options_id
           , vals.gco_good_id
           , rubr.ars_order;
end RPT_FAL_WIPCALC;
