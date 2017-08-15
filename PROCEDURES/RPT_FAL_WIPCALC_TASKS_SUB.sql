--------------------------------------------------------
--  DDL for Procedure RPT_FAL_WIPCALC_TASKS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_WIPCALC_TASKS_SUB" (
  arefcursor  in out crystal_cursor_types.dualcursortyp
, procparam_0 in     fal_adv_calc_options.cao_session_id%type
, procparam_1 in     fal_adv_calc_options.fal_adv_calc_options_id%type
, procparam_2 in     fal_adv_calc_good.gco_good_id%type
, procparam_3 in     fal_adv_calc_good.gco_cpt_good_id%type default null
)
is
/**
* Description Used for report FAL_WORKINPROGRESS_CALCULATION
* Stored procedure used for the advanced Calculate WIP report
* @Author VHA 22 Aug. 2012
* @lastupdate
* @param aRefCursor  : Curseur pour le rapport Crystal
* @param PROCPARAM_0 : Session Oracle
* @param PROCPARAM_1 : Identifiant des options
* @param PROCPARAM_2 : Produit calculé
* @param PROCPARAM_3 : Composant
*/
begin
  fal_adv_calc_print.adv_calc_tasks_rpt_pk(arefcursor    => arefcursor
                                         , asessionid    => procparam_0
                                         , aoptionsid    => procparam_1
                                         , acalcgoodid   => procparam_2
                                         , acptgoodid    => procparam_3
                                          );
end RPT_FAL_WIPCALC_TASKS_SUB;
