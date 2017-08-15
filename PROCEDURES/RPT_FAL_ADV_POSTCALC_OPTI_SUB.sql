--------------------------------------------------------
--  DDL for Procedure RPT_FAL_ADV_POSTCALC_OPTI_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_ADV_POSTCALC_OPTI_SUB" (
  arefcursor  in out crystal_cursor_types.dualcursortyp
, procparam_0 in     fal_adv_calc_options.cao_session_id%type
)
is
 /**
* Description - Used in report FAL_ADV_SIMPLE_POSTCALCULATION, FAL_ADV_POSTCALCULATION
* Stored procedure used for the advanced post calculation report
* @Author VHA 22 Aug. 2012
* @param aRefCursor  : Curseur pour le rapport Crystal
* @param PROCPARAM_0 : Session Oracle
*/
begin
  fal_adv_calc_print.adv_calc_options_rpt_pk(arefcursor => arefcursor, asessionid => procparam_0);
end RPT_FAL_ADV_POSTCALC_OPTI_SUB;
