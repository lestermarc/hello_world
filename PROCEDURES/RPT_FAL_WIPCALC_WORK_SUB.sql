--------------------------------------------------------
--  DDL for Procedure RPT_FAL_WIPCALC_WORK_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_WIPCALC_WORK_SUB" (
  arefcursor  in out crystal_cursor_types.dualcursortyp
, procparam_0 in     fal_adv_calc_options.cao_session_id%type
, procparam_1 in     fal_adv_calc_options.fal_adv_calc_options_id%type
, procparam_2 in     fal_adv_calc_good.gco_good_id%type
, procparam_3 in     fal_adv_calc_good.gco_cpt_good_id%type default null
, procparam_4 in     fal_adv_calc_work.c_basis_rubric%type
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
* @Param Parameter_1: Option Id
* @Param Parameter_2: Good Id
* @Param Parameter_4: Cpt Good Id
* @Param Parameter_5: C_basis_rubric
*/
begin
  fal_adv_calc_print.adv_calc_work_rpt_pk(arefcursor     => arefcursor
                                        , asessionid     => procparam_0
                                        , aoptionsid     => procparam_1
                                        , acalcgoodid    => procparam_2
                                        , acptgoodid     => procparam_3
                                        , abasisrubric   => procparam_4
                                         );
end RPT_FAL_WIPCALC_WORK_SUB;
